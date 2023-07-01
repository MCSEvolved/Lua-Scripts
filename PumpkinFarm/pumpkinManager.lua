local me = peripheral.find("meBridge")
local emeraldOutputBarrelName = "minecraft:barrel_61"
local tradingInterface = peripheral.find("trading_interface")
local modem = nil
local fuelBarrelNames = {}
local outputBarrelNames = {}

local emeraldsProduced = 0

---Log info to file
---@param text string
---@return boolean
local function logInfo(text)
    local logFile = fs.open("logs.txt", "a")
    if type(text) ~= "string" then
        return false
    end
    term.setTextColor(colors.white)
    print("[INFO] ".. text)
    logFile.writeLine("[INFO] " .. text)
    logFile.close()
    return true
end

---Log warning to file
---@param text string
---@return boolean
local function logWarning(text)
    local logFile = fs.open("logs.txt", "a")
    if type(text) ~= "string" then
        return false
    end
    term.setTextColor(colors.yellow)
    print("[WARNING] ".. text)
    logFile.writeLine("[WARNING] " .. text)
    logFile.close()
    return true
end

---Log error to file
---@param text string
---@param doCrash boolean | nil
---@return boolean
local function logError(text, doCrash)
    local logFile = fs.open("logs.txt", "a")
    if type(text) ~= "string" then
        return false
    end
    term.setTextColor(colors.red)
    print("[ERROR] ".. text)
    logFile.writeLine("[ERROR] " .. text)
    logFile.close()
    if not doCrash then
        return true
    end
    error(text)
end

local function findWirelessModem()
    local names  = peripheral.getNames()
    for i = 1, #names do
        if peripheral.getType(names[i]) == "modem" and peripheral.call(names[i], "isWireless") then
            return peripheral.wrap(names[i])
        end
    end
end

local function wipeLogs()
    logInfo("Wiping logs")
    fs.delete("logs.txt")
end

local function setOutputBarrelNames()
    for line in io.lines("outputBarrelNames.txt") do
        table.insert(outputBarrelNames, line)
    end
end

local function setFuelBarrelNames()
    for line in io.lines("fuelBarrelNames.txt") do
        table.insert(fuelBarrelNames, line)
    end
end

local function initialize()
    wipeLogs()

    modem = findWirelessModem()

    if not modem then
        logError("Could not find wireless modem", true)
    end

    if not me then
        logError("Could not find ME bridge", true)
    end

    if not peripheral.wrap(emeraldOutputBarrelName) then
        logError("Could not find emerald output barrel", true)
    end

    if not tradingInterface then
        logError("Could not find trading interface", true)
    end

    setFuelBarrelNames()
    setOutputBarrelNames()
    logInfo("Found ".. #fuelBarrelNames .." fuel barrels and ".. #outputBarrelNames .." output barrels")
    logInfo("Initialized")
end

local function handleMEBridgeError(error)
    if error == "NOT_CONNECTED" then
        logWarning("ME not connected, likely due to rebooting")
        sleep(10)
    else
        logError("ME bridge error: ".. error, true)
    end
end

---Push an item to the ME storage, returns if it was successful or not and the amount pushed
---@param item table {name: string, [count: integer]}
---@param containerName string
---@return boolean, integer
local function pushToStorage(item, containerName)
    local count, error = me.importItemFromPeripheral(item, containerName)
    if not error then
        return count > 0, count
    end
    handleMEBridgeError(error)
    return false, 0
end

local function pullFromStorage(item, containerName)
    local count, error = me.exportItemToPeripheral(item, containerName)
    if not error then
        return count > 0, count
    end
    handleMEBridgeError(error)
    return false, 0
end

local function pushEmeraldsToMEStorage()
    logInfo("Pushing emeralds to ME storage")
    while pushToStorage({name = "minecraft:emerald"}, emeraldOutputBarrelName) do end
end

local function tradePumpkinsToEmeralds(outputBarrelName)
    local tradeID = 3

    local tradeSuccess = true
    local function tradeWrapper()
        tradeSuccess = tradingInterface.trade(outputBarrelName, emeraldOutputBarrelName, tradeID)
        if tradeSuccess then
            emeraldsProduced = emeraldsProduced + 1
        end
    end

    while true do
        local success, error = pcall(tradeWrapper)
        if not tradeSuccess then return true end
        if not success and type(error) == "string" and string.find(error, "destination inventory full") then
            pushEmeraldsToMEStorage()
        elseif not success then
            logError("Error while trading: ".. error, true)
        end
        logInfo("Traded ".. outputBarrelName)
        sleep(0.1)
    end
end

local function tradeOutputBarrels()
    logInfo("Trading output barrels")
    for i = 1, #outputBarrelNames do
        tradePumpkinsToEmeralds(outputBarrelNames[i])
    end
end

local function fillFuelBarrels()
    logInfo("Filling fuel barrels")
    for i = 1, #fuelBarrelNames do
        while pullFromStorage({name="minecraft:charcoal"}, fuelBarrelNames[i]) do end
    end
end

-- Print pumpkins produced every 60 minutes
local function reportData()
    while true do
        sleep(3600)
        logInfo("Reporting production data")
        local transmissionData = {sender="MANAGER", type="PRODUCTION_DATA", data = { time = textutils.formatTime(os.time("local")), produced = emeraldsProduced }}
        modem.transmit(20, 20, transmissionData)
        emeraldsProduced = 0 -- Reset emeralds produced
    end
end

local function main()
    logInfo("Running main")
    while true do
        pushEmeraldsToMEStorage()
        tradeOutputBarrels()
        fillFuelBarrels()
        logInfo("Sleeping for 10 seconds")
        sleep(10)
    end
end

initialize()
parallel.waitForAll(main, reportData)