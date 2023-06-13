local me = peripheral.find("meBridge")
local emeraldOutputBarrelName = "minecraft:barrel_39"
local tradingInterface = peripheral.find("trading_interface")
local fuelBarrelNames = {}
local outputBarrelNames = {}

---Log info to file
---@param text string
---@return boolean
local function logInfo(text)
    local logFile = fs.open("logs.txt", "a")
    if type(text) ~= "string" then
        return false
    end
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
    print("[ERROR] ".. text)
    logFile.writeLine("[ERROR] " .. text)
    logFile.close()
    if not doCrash then
        return true
    end
    error(text)
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


local function tradeOutputBarrels()
    logInfo("Trading output barrels")
    local tradeID = 3
    for i = 1, #outputBarrelNames do
        while tradingInterface.trade(outputBarrelNames[i], emeraldOutputBarrelName, tradeID) do
            local file = fs.open("tradeCount.txt", "r")
            if file then
                local count = file.read()
                file.close()
                count = count + 1
                file = fs.open("tradeCount.txt", "w")
                file.flush()
                file.write(count)
                file.close()
            end
        end
    end
end

local function fillFuelBarrels()
    logInfo("Filling fuel barrels")
    for i = 1, #fuelBarrelNames do
        while pullFromStorage({name="minecraft:charcoal"}, fuelBarrelNames[i]) do end
    end
end

local function main()
    logInfo("Running main")
    while true do
        tradeOutputBarrels()
        pushEmeraldsToMEStorage()
        fillFuelBarrels()
    end
end

initialize()
main()