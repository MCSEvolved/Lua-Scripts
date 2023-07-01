local tradingInterfaceNames = {}
local inputChest = peripheral.wrap("minecraft:barrel_63")
local outputChest = peripheral.wrap("minecraft:barrel_64")

--- Log an info message
---@param text string
---@return boolean
local function logInfo(text)
    local logFile = fs.open("logs.txt", "a")
    if type(text) == nil then
        return false
    end
    term.setTextColor(colors.white)
    print("[INFO] ".. text)
    return true
end

--- Log a warning message
---@param text string
---@return boolean
local function logWarning(text)
    local logFile = fs.open("logs.txt", "a")
    if type(text) == nil then
        return false
    end
    term.setTextColor(colors.yellow)
    print("[WARNING] ".. text)
    return true
end

--- Log an error message and optionally crash the program
---@param text string
---@param doCrash boolean | nil
---@return boolean
local function logError(text, doCrash)
    local logFile = fs.open("logs.txt", "a")
    if type(text) == nil then
        return false
    end
    term.setTextColor(colors.red)
    print("[ERROR] ".. text)
    if not doCrash then
        return true
    end
    error(text)
end

--- Find all trading interfaces
---@return string[]
local function findTradingInterfaces()
    local names = peripheral.getNames()
    for key, name in pairs(names) do
        if peripheral.getType(name) == "trading_interface" then
            table.insert(tradingInterfaceNames, name)
        end
    end
    return tradingInterfaceNames
end

---- Get all villagers
---@return string[]
---@return integer
local function getVillagers()
    local count = 0
    local tradingInterfacesWithVillagers = {}
    for key, interfaceName in pairs(tradingInterfaceNames) do
        local tradingInterface = peripheral.wrap(interfaceName)
        if not tradingInterface then
            logWarning("Could not find trading interface with name " .. interfaceName)
        end
        local success = pcall(tradingInterface.getProfession)
        if success then
            count = count + 1
            table.insert(tradingInterfacesWithVillagers, interfaceName)
        end
    end
    return tradingInterfacesWithVillagers, count
end


--- Find a trade by result item name
---@param resultItemName string
---@return boolean
---@return integer | nil
---@return integer | nil
---@return integer | nil
local function findTrade(resultItemName)
    for interfaceKey, tradingInterfaceName in pairs(tradingInterfaceNames) do
        local tradingInterface = peripheral.wrap(tradingInterfaceName)
        if not tradingInterface then
            logWarning("Could not find trading interface with name " .. tradingInterfaceName)
            return false
        end
        local trades = tradingInterface.getTrades()
        for tradeID, trade in pairs(trades) do
            for itemName, item in pairs(trade.result) do
                if itemName == resultItemName then
                    return true, interfaceKey, tradeID, item.count
                end
            end
        end
    end
    return false
end

--- Handle user inputting
---@return boolean
---@return string | nil
---@return integer | nil
local function handleUserInputting()
    while true do
        print("What item do you want to trade?")
        print("Example: minecraft:redstone")
        local itemName = read()
        if itemName == "minecraft:emerald" then
            logWarning("You can't trade emeralds as a result item")
            return false
        end

        if type(itemName) ~= "string" then
            logWarning("Invalid item name")
            return false
        end

        print("How many of that item do you want to trade?")
        local itemAmount = tonumber(read())
        if type(itemAmount) ~= "number" then
            logWarning("Invalid item amount")
            return false
        end
        return true, itemName, itemAmount
    end
end


--- Wait for user input
---@return string
---@return integer
local function waitForUserInput()
    while true do
        local success, itemName, itemAmount = handleUserInputting()
        if success and type(itemName) == "string" and type(itemAmount) == "number" then
            return itemName, itemAmount
        end
    end
end

--- Trade items
---@param tradingInterfaceName string
---@param tradeID integer
---@param itemAmount integer
---@param countPerTrade integer
local function depcreatedTradeItem(tradingInterfaceName, tradeID, itemAmount, countPerTrade)
    logInfo("Trading " .. itemAmount .. " items")
    local amountOfTrades = math.ceil(itemAmount / countPerTrade)
    local tradingInterface = peripheral.wrap(tradingInterfaceName)
    if not tradingInterface then
        logError("Failed to wrap trading interface: " .. tradingInterfaceName, true)
    end
    for i = 1, amountOfTrades do
        if not tradingInterface.trade(peripheral.getName(inputChest), peripheral.getName(outputChest), tradeID) then return false end
    end
    return true
end

local function getCompleteTradesList()
    logInfo("Constructing complete trades list")
    local completeTradesList = {}
    for key, tradingInterfaceName in pairs(tradingInterfaceNames) do
        local tradingInterface = peripheral.wrap(tradingInterfaceName)
        if not tradingInterface then
            logWarning("Could not find trading interface with name " .. tradingInterfaceName)
            return false
        end
        local trades = tradingInterface.getTrades()
        for tradeID, trade in pairs(trades) do
            trade["TradingInterfaceName"] = tradingInterfaceName
            trade["TradeID"] = tradeID
            trade["VillagerProfession"] = tradingInterface.getProfession()
            table.insert(completeTradesList, trade)
        end
    end
    return completeTradesList
end

local function initialize()
    logInfo("Initializing")

    if not inputChest then
        logError("No input chest found", true)
    end
    if not outputChest then
        logError("No output chest found", true)
    end
    tradingInterfaceNames = findTradingInterfaces()
    if #tradingInterfaceNames == 0 then
        logError("No trading interfaces found", true)
    end
    logInfo("Found " .. #tradingInterfaceNames .. " trading interfaces")
    local villagerCount
    tradingInterfaceNames, villagerCount = getVillagers()
    logInfo("Found " .. villagerCount .. " villagers")
end


local function restock()
    for key, tradingInterfaceName in pairs(tradingInterfaceNames) do
        local tradingInterface = peripheral.wrap(tradingInterfaceName)
        if not tradingInterface then
            logWarning("Could not find trading interface with name " .. tradingInterfaceName)
            return false
        end
        tradingInterface.restock()
    end
end

--- Create websocket connection
---@return boolean
---@return table | nil
local function createWebsocketConnection()
    logInfo("Requesting websocket connection...")
    local ws, error = http.websocket("ws://local.vincent.mcsynergy.nl:7190/hubs/minecraft")
    if not ws or error then
        logError("Failed to create websocket connection: " .. error, true)
        return false, nil
    end
    logInfo("Websocket connected successfully!")
    return true, ws
end

local function handleHttpSuccessEvent(sentURL)
    local event, url, handle
    repeat
        event, url, handle = os.pullEvent("http_success")
    until url == sentURL

    logInfo("Received response from " .. url)
    logInfo("Response code: " .. handle.getResponseCode())
    local responseMessage = handle.readAll()
    handle.close()
    if responseMessage ~= "" and type(responseMessage) == "string" then
        logInfo("Response: " .. responseMessage)
    end
end

local function handleHttpFailureEvent(sentURL)
    local event, url, error, handle
    repeat
        event, url, error, handle= os.pullEvent("http_failure")
    until url == sentURL

    logError("Request to " .. url .. " failed: " .. error)
    if handle then
        logInfo("Failing response code: " .. handle.getResponseCode())
        logInfo("Failing response: " .. handle.readAll())
        handle.close()
    end
end

local function sendTradesListToServer(completeTradesList)
    local url = "http://local.vincent.mcsynergy.nl:7190/set-trades"

    logInfo("Sending trades list to server")
    http.request({
        url = url,
        method = "POST",
        headers = {
            ["Content-Type"] = "application/json"
        },
        body = textutils.serialiseJSON(completeTradesList)
    })

    local function httpSuccessWrapper()
        handleHttpSuccessEvent(url)
    end

    local function httpFailureWrapper()
        handleHttpFailureEvent(url)
    end

    logInfo("Waiting for response from server...")
    parallel.waitForAny(httpSuccessWrapper, httpFailureWrapper)
    return true
end

local function testws()
    local success, ws = createWebsocketConnection()
    while success and type(ws) == "table" do
        logInfo("Waiting for message from server...")
        local data = textutils.unserialiseJSON(ws.receive())
        textutils.pagedTabulate(data)
        print(data)
    end
end

local function validateTradeOperation(tradeOperation)
    logInfo("Validating trade operation")

    if type(tradeOperation) ~= "table" then
        logWarning("type of tradeOperation is not table")
        return false, "type of tradeOperation is not table"
    end

    if type(tradeOperation["Trade"] ~= "table") then
        logWarning("type of tradeOperation.Trade is not table")
        return false, "type of tradeOperation.Trade is not table"
    end

    if type(tradeOperation["Trade"]["Location"] ~= "table") then
        logWarning("type of tradeOperation.Trade.Location is not table")
        return false, "type of tradeOperation.Trade.Location is not table"
    end

    if type(tradeOperation["Trade"]["Location"]["TradingInterfaceName"] ~= "string") then
        logWarning("type of tradeOperation.Trade.Location.TradingInterfaceName is not string")
        return false, "type of tradeOperation.Trade.Location.TradingInterfaceName is not string"
    end

    if type(tradeOperation["Trade"]["Location"]["TradeID"] ~= "number") then
        logWarning("type of tradeOperation.Trade.Location.TradeID is not number")
        return false, "type of tradeOperation.Trade.Location.TradeID is not number"
    end

    if type(tradeOperation["AmountOfTrades"] ~= "number") then
        logWarning("type of tradeOperation.AmountOfTrades is not number")
        return false, "type of tradeOperation.AmountOfTrades is not number"
    end

    return true, "Trade operation is valid"
end

local function completeTradeOperation(tradeOperation)
    local success, message = validateTradeOperation(tradeOperation)

    if not success then
        return false, message
    end

    local tradingInterfaceName = tradeOperation["Trade"]["Location"]["TradingInterfaceName"]
    local tradeID = tradeOperation["Trade"]["Location"]["TradeID"]
    local amountOfTrades = tradeOperation["AmountOfTrades"]







end

local function main()
    while true do
        local itemName, itemAmount = waitForUserInput()
        local success, interfaceKey, tradeID, countPerTrade = findTrade(itemName)
        if not success or type(tradeID) ~= "number" or type(countPerTrade) ~= "number" then
            logInfo("No trade found for " .. itemName)
        else
            logInfo("Found trade for " .. itemName)
            local tradeSuccess = depcreatedTradeItem(tradingInterfaceNames[interfaceKey], tradeID, itemAmount, countPerTrade)
            if not tradeSuccess then
                logError("Failed complete trade...")
            end
        end
    end
end

initialize()
-- local completeTradesList = getCompleteTradesList()
-- sendTradesListToServer(completeTradesList)
main()
completeTradeOperation({})

--createWebsocketConnection()
