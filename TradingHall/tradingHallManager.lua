local tradingInterfaceNames = {}
local inputChest = peripheral.wrap("minecraft:barrel_63")
local outputChest = peripheral.wrap("minecraft:barrel_64")
local mebridgeName = "meBridge_12"

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
        if tradingInterface.getProfession() then
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
        local success, trades = tradingInterface.getTrades()
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
local function deprecatedTradeItem(tradingInterfaceName, tradeID, itemAmount, countPerTrade)
    logInfo("Trading " .. itemAmount .. " items")
    local amountOfTrades = math.ceil(itemAmount / countPerTrade)
    local tradingInterface = peripheral.wrap(tradingInterfaceName)
    if not tradingInterface then
        logError("Failed to wrap trading interface: " .. tradingInterfaceName, true)
    end
    for i = 1, amountOfTrades do
        local success, error = tradingInterface.trade(peripheral.getName(inputChest), peripheral.getName(outputChest), tradeID)
        if not success then
            logError("Failed to trade: " .. error, true)
        end
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
            _, trade["VillagerProfession"] = tradingInterface.getProfession()
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

    if not peripheral.wrap(mebridgeName) then
        logError("No ME bridge found", true)
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

    if type(tradeOperation["Trade"]["CostA"]["Item"]["Name"]) ~= "string" then
        logWarning("type of tradeOperation.CostA.Item.Name is not string")
        return false, "type of tradeOperation.CostA.Item.Name is not string"
    end

    if type(tradeOperation["Trade"]["CostB"]["Item"]["Name"]) ~= "string" then
        logWarning("type of tradeOperation.CostB.Item.Name is not string")
        return false, "type of tradeOperation.CostB.Item.Name is not string"
    end

    if type(tradeOperation["Trade"]["CostA"]["Amount"] ~= "number") then
        logWarning("type of tradeOperation.CostA.Amount is not number")
        return false, "type of tradeOperation.CostA.Amount is not number"
    end

    if type(tradeOperation["Trade"]["CostB"]["Amount"] ~= "number") then
        logWarning("type of tradeOperation.CostB.Amount is not number")
        return false, "type of tradeOperation.CostB.Amount is not number"
    end

    return true, "Trade operation is valid"
end

--- Get the ME bridge, waits until it's online if not found
---@return table
local function getMEBridge()
    local loggedMeBridgeOffline = false
    while true do
        local mebridge = peripheral.wrap(mebridgeName)
        if type(mebridge) == "table" then
            return mebridge
        end
        if not loggedMeBridgeOffline then
            logWarning("Waiting for mebridge to come online...")
            loggedMeBridgeOffline = true
        end
        sleep(1)
    end
end

--- Push item to ME, max 64
---@param itemName string
---@param fromInventoryName string
local function pushItemToME(itemName, fromInventoryName)
    getMEBridge().importItemFromPeripheral({name=itemName}, fromInventoryName)
end

--- Pull item from ME, max 64
---@param itemName string @name of the item to pull
---@param toInventoryName string  @name of the inventory to pull the item to
---@param amount number @amount of items to pull, max 64
local function pullItemFromME(itemName, toInventoryName, amount)
    getMEBridge().exportItemToPeripheral({name=itemName, count=amount}, toInventoryName)
end

local function emptyOutputChest()
    logInfo("Emptying output chest")
    local items = outputChest.list()
    for key, item in pairs(items) do
        local amountPushed = pushItemToME(item.name, peripheral.getName(outputChest))
        if amountPushed < item.count then
            return false
        end
    end
    return true
end

local function emptyInputChest()
    logInfo("Emptying input chest")
    local items = inputChest.list()
    for key, item in pairs(items) do
        local amountPushed = pushItemToME(item.name, peripheral.getName(inputChest))
        if amountPushed < item.count then
            return false
        end
    end
    return true
end

local function pushToInputChest(itemName, amount)
    logInfo("Pushing " .. amount .. " " .. itemName .. " to input chest")
    local amountToPush = amount
    while amountToPush > 64 do
        local amountPushed = pullItemFromME(itemName, peripheral.getName(inputChest))
        if amountPushed == 0 then return false, amount - amountToPush end
        amountToPush = amountToPush - amountPushed
    end
    return true
end

local function handleProvideInputChestWithTradeCost(cost, fillMaxHalfChestSize)
    local itemName = cost["Item"]["Name"]
    local amount = cost["Amount"]
    if fillMaxHalfChestSize and amount > 13 * 64 then
        amount = 13 * 64
    end
    local success, amountPushed = pushToInputChest(itemName, amount)
    return success, amountPushed
end

--- Provide the input chest with the cost of the trade.
--- It provides as much as needed or as much as the chest can handle, 
--- when a costB exists it fills half the chest with costA and half with costB
local function provideInputChestWithTradeCost(tradeOperation)
    local costB = tradeOperation["Trade"]["CostB"]

    -- If there is no costB or costB is air, only provide costA
    if not costB or costB["Item"]["Name"] == "minecraft:air" then
        handleProvideInputChestWithTradeCost(tradeOperation["Trade"]["CostA"])
        return
    end

    -- If there is a costB, provide both costA and costB, but only fill half the chest with either
    handleProvideInputChestWithTradeCost(tradeOperation["Trade"]["CostA"], true)
    handleProvideInputChestWithTradeCost(tradeOperation["Trade"]["CostB"], true)
end

--- Do some trades
---@param tradingInterface table
---@param tradeID number
---@param amountOfTrades number
---@return boolean, number, string @success, amountOfTradesDone, errorMessage
local function trade(tradingInterface, tradeID, amountOfTrades)
    logInfo("Trading " .. amountOfTrades .. " times with trade ID " .. tradeID)
    local tradesDone = 0
    for i = 1, amountOfTrades do
        local success, error = tradingInterface.trade(tradeID)
        if not success then
            logWarning("Failed to trade: " .. error)
            return false, tradesDone, error
        end
        tradesDone = tradesDone + 1
    end
    return true, tradesDone, "Trading completed"
end

local function handleTradeOperation(tradeOperation)
    local isValid, validationError = validateTradeOperation(tradeOperation)

    if not isValid then
        return false, validationError
    end

    local tradingInterfaceName = tradeOperation["Trade"]["Location"]["TradingInterfaceName"]
    local tradeID = tradeOperation["Trade"]["Location"]["TradeID"]
    local amountOfTrades = tradeOperation["AmountOfTrades"]

    local tradingInterface = peripheral.wrap(tradingInterfaceName)
    if not tradingInterface then
        logError("Could not find trading interface with name " .. tradingInterfaceName)
        return false, "Could not find trading interface with name " .. tradingInterfaceName
    end

    while true do
        -- clear the chests
        if not emptyInputChest() then
            logError("Could not empty input chest", true)
            return false, "Could not empty input chest"
        end
        if not emptyOutputChest() then
            logError("Could not empty output chest", true)
            return false, "Could not empty output chest"
        end

        -- provide the input chest with the cost of the trade
        provideInputChestWithTradeCost(tradeOperation)

        -- trade as much as possible or needed
        local success, amountOfTradesDone, error = trade(tradingInterface, tradeID, amountOfTrades)
        -- Would be nice to know what the error was while trading, but when there is something wrong with the input, there is no error message. 
        -- So there is nothing to validate against yet. I'll add this to the trading interface later if I have time. 

        -- return if done
        if success then return true end
        amountOfTrades = amountOfTrades - amountOfTradesDone
    end
end

local function main()
    while true do
        local itemName, itemAmount = waitForUserInput()
        local success, interfaceKey, tradeID, countPerTrade = findTrade(itemName)
        if not success or type(tradeID) ~= "number" or type(countPerTrade) ~= "number" then
            logInfo("No trade found for " .. itemName)
        else
            logInfo("Found trade for " .. itemName)
            local tradeSuccess = deprecatedTradeItem(tradingInterfaceNames[interfaceKey], tradeID, itemAmount, countPerTrade)
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
--handleTradeOperation({})

--createWebsocketConnection()