local harvestInterval = 5

---Log info to file
---@param text string
---@return boolean
local function logInfo(text)
    local logFile = fs.open("logs.txt", "a")
    if type(text) ~= "string" then
        return false
    end
    print("[INFO]".. text)
    logFile.writeLine("[INFO]" .. text)
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
    print("[WARNING]".. text)
    logFile.writeLine("[WARNING]" .. text)
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
    print("[ERROR]".. text)
    logFile.writeLine("[ERROR]" .. text)
    logFile.close()
    if not doCrash then
        return true
    end
    error(text)
end

---Walk forward a specified amount of blocks
---@param count number
local function walkForward(count)
    for i = 1, count do
        local success = turtle.forward()
        if not success then
            local _, block = turtle.inspect()
            return false, block
        end
    end
    return true
end

---Walk up a specified amount of blocks
---@param count number
local function walkUp(count)
    for i = 1, count do
        local success = turtle.up()
        if not success then
            local _, block = turtle.inspectUp()
            return false, block
        end
    end
    return true
end

local function harvestRow()
    logInfo("Harvesting row")
    while true do
        local success, block = turtle.inspect()
        if success and block.name == "minecraft:pumpkin" then
            turtle.dig()
        elseif success and block.name == "minecraft:glass" then
            return true
        elseif success then
            error("Expected pumpkin, glass or air, got " .. block.name)
            return false
        end
        turtle.forward()
    end
end

local function turnToNextRowRight()
    logInfo("Turning to next row right")
    turtle.turnRight()

    --Check for unexpected blocks
    local success, block = turtle.inspect()
    if success and block.name == "minecraft:pumpkin" then
        turtle.dig()
    elseif success then
        logError("Expected pumpkin or air, got " .. block.name)
    end

    turtle.forward()
    turtle.turnRight()
end

local function turnToNextRowLeft()
    logInfo("Turning to next row left")
    turtle.turnLeft()
    local success = walkForward(4)
    if not success then logError("Failed to walk forward 4 blocks", true) end
    turtle.turnLeft()
end

local function harvestLayer()
    -- Harvest first row
    local success = harvestRow()
    if not success then logError("Failed to harvest first row", true) end

    -- Turn around
    turnToNextRowRight()

    -- Harvest second row
    success = harvestRow()
    if not success then logError("Failed to harvest second row", true) end

    -- Turn around
    turnToNextRowLeft()

    -- Harvest third row
    success = harvestRow()
    if not success then logError("Failed to harvest third row", true) end

    -- Turn around
    turnToNextRowRight()

    -- Harvest fourth row
    success = harvestRow()
    if not success then logError("Failed to harvest fourth row", true) end

    -- Walk back to layer start
    turtle.turnRight()
    walkForward(6)
    turtle.turnRight()
end


--- Walk to next layer
---@return boolean
local function walkToNextLayer()
    local success, block = walkUp(2)
    if not success and type(block) == "table" then
        return false
    elseif not success then
        logError("walkUp during movement to next layer failed without block above turtle", true)
    end
    return true
end

local function walkToStart()
    while true do
        if not turtle.down() then
            return
        end
    end
end

local function harvestModule()
    -- Setup
    logInfo("Harvesting module")
    local harvesting = true

    -- Harvest layers
    while harvesting do
        harvestLayer()
        harvesting = walkToNextLayer()
    end

    -- Walk to start
    walkToStart()
end

local function tempEmptyInventory()
    logInfo("Emptying inventory")
    turtle.turnLeft()
    turtle.forward()
    local success, block = turtle.inspectDown()
    if not success or block.name ~= "minecraft:chest" then
        logError("Expected chest, got " .. block.name, true)
    end

    for i = 1, 16 do
        local count = turtle.getItemCount(i)
        if count > 0 then
            turtle.select(i)
            if not turtle.dropDown() then
                logWarning("Failed to drop items in chest")
                return false
            end
        end
    end
    turtle.back()
    turtle.turnRight()
    return true
end

--- Check if turtle has enough fuel
---@param count number
local function fuelCheck(count)
    if turtle.getFuelLevel() < count then
        logWarning("Fuel level less then " .. count)
        return false
    end
    return true
end

local function checkIfReady()
    logInfo("Checking if ready")
    if not fuelCheck(1000) then
        logError("Not enough fuel", true)
    end
    return true
end

local function main()
    checkIfReady()
    while true do
        harvestModule()
        if not tempEmptyInventory() then
            logError("Chest is full", true)
        end
        sleep(harvestInterval)
    end
end

main()