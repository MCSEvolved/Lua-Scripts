local harvestInterval = 5
local modem = peripheral.find("modem")
local running = true

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

---move forward a specified amount of blocks
---@param count number
local function moveForward(count)
    for i = 1, count do
        local success = turtle.forward()
        if not success then
            local _, block = turtle.inspect()
            return false, block
        end
    end
    return true
end

---move up a specified amount of blocks
---@param count number
local function moveUp(count)
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
            logError("Expected pumpkin, glass or air, got " .. block.name)
            return false
        end
        turtle.forward()
    end
end

local function turnToNextRowRight()
    logInfo("Turning to next row right")
    turtle.turnRight()

    -- Log warning if turtle can't move forward after mining pumpkin
    local doLogWarning = false
    while not turtle.forward() do
        local success, block = turtle.inspect()
        if success and block.name == "minecraft:pumpkin" then
            turtle.dig()
        elseif success then
            logError("Expected pumpkin or air, got " .. block.name)
        end
        if doLogWarning then
            logWarning("Failed to move forward, trying again")
        end
        doLogWarning = true
    end
    turtle.turnRight()
end

local function turnToNextRowLeft()
    logInfo("Turning to next row left")
    turtle.turnLeft()
    local success = moveForward(4)
    if not success then logError("Failed to move forward 4 blocks", true) end
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

    -- move back to layer start
    logInfo("moving back to layer start")
    turtle.turnRight()
    moveForward(6)
    turtle.turnRight()
end

--- move to next layer
---@return boolean
local function moveToNextLayer()
    logInfo("moving to next layer")
    local success, block = moveUp(2)
    if not success and type(block) == "table" then
        return false
    elseif not success then
        logError("moveUp during movement to next layer failed without block above turtle", true)
    end
    return true
end

local function moveToStart()
    logInfo("moving to start")
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
        harvesting = moveToNextLayer()
    end

    -- move to start
    moveToStart()
end

local function emptyInventory()
    logInfo("Emptying inventory")
    turtle.turnLeft()
    turtle.forward()
    local success, block = turtle.inspectDown()
    if not success or block.name ~= "minecraft:barrel" then
        logError("Expected barrel, got " .. block.name, true)
    end

    for i = 1, 16 do
        local count = turtle.getItemCount(i)
        if count > 0 then
            turtle.select(i)
            if not turtle.dropDown() then
                logWarning("Failed to drop items in barrel")
                return false
            end
        end
    end
    turtle.back()
    turtle.turnRight()
    return true
end

local function refuel()
    if turtle.getFuelLevel() > (64*80) then
        logInfo("Fuel level: OK")
        return true
    end

    logInfo("Fuel level too low, refueling...")
    local success, block = turtle.inspectDown()
    if not success or block.name ~= "minecraft:barrel" then
        logError("Expected barrel, got " .. block.name, true)
    end

    turtle.suckDown()
    turtle.refuel()

    if turtle.getFuelLevel() < (64*80) then
        logInfo("Fuel level still low")
        return true
    else
        logInfo("Fuel level: OK")
        return true
    end
end

local function checkInventoryEmpty()
    for i = 1, 16 do
        if turtle.getItemCount(i) > 0 then
            return false
        end
    end
    return true
end

local function listenForShutdownMessage()
    modem.open(20)
    while true do
        local _, _, _, _, message = os.pullEvent("modem_message")
        if type(message) == "table" and message.sender == "MANAGER" and message.data == "STOP_NEXT_ROUND" then
            logInfo("Received shutdown message")
            running = false
            return
        end
        logInfo("Received unknown message")
    end
end

--- check if turtle is in starting position
---@return boolean
---@return string
local function checkIfInStartingPosition()
    logInfo("Checking if turtle is in starting position")

    -- Check if block under is barrel
    local success, block = turtle.inspectDown()
    if not success or block.name ~= "minecraft:barrel" then
        return false, "BLOCK DOWN NOT BARREL"
    end

    -- find glass block wall
    for i = 1, 4, 1 do
        success, block = turtle.inspect()
        if success and block.name == "minecraft:glass" then
            break
        end
        turtle.turnRight()
    end
    if not success or block.name ~= "minecraft:glass" then
        return false, "GLASS WALL NOT FOUND"
    end

    -- Check if block right is air
    turtle.turnLeft()
    success, block = turtle.inspect()
    if success then
        -- Turn back to front
        turtle.turnRight()
        turtle.turnRight()
        return false, "BLOCK RIGHT NOT AIR"
    end

    -- Check if block in front is pumpkin or air
    turtle.turnLeft()
    success, block = turtle.inspect()
    if not success or block.name ~= "minecraft:pumpkin" then
        return false, "BLOCK FRONT NOT PUMPKIN OR AIR"
    end

    -- Check if block left is air
    turtle.turnLeft()
    success, block = turtle.inspect()
    if success then
        -- Turn back to front
        turtle.turnRight()
        return false, "BLOCK LEFT NOT AIR"
    end

    -- Turn back to front
    turtle.turnRight()

    -- Return true if blocks arround are correct
    return true, "OK"
end

--- try to walk back to start
---@return boolean
---@return string
local function tryWalkBackToStart()
    logInfo("Trying to walk back to start")

    -- Check if block under is barrel and try to walk back to start if on top of output barrel
    local success, block = turtle.inspectDown()
    if success and block.name == "minecraft:barrel" then
        for i = 1, 4 do
            success, block = turtle.inspect()
            if success and (block.name == "minecraft:pumpkin_stem" or block.name == "minecraft:attached_pumpkin_stem") then
                break;
            end
            turtle.turnRight()
        end

        turtle.turnRight()
        turtle.forward()
        turtle.turnLeft()
        return checkIfInStartingPosition()
    end

    -- Check if block under is dirt or grass and try to walk back to glass wall with walking space (front of module)
    if success and (block.name == "minecraft:dirt" or block.name == "minecraft:grass_block") then
        if not harvestRow() then
            logError("Failed to harvest row while trying to find route to start", true)
            return false, "FAILED TO WALK BACK TO START"
        end
        success, block = turtle.inspect()
        if not success or block.name ~= "minecraft:glass" then
            return false, "FAILED TO WALK BACK TO START"
        end
        success, block = turtle.inspectDown()
        if success and block.name == "minecraft:dirt" or block.name == "minecraft:grass_block" then
            turnToNextRowRight()
            if not harvestRow() then
                logError("Failed to harvest row while trying to find route to start", true)
                return false, "FAILED TO WALK BACK TO START"
            end
        elseif success then
            return false, "FAILED TO WALK BACK TO START"
        end
    end

    -- Check if turtle is in walking space at the front of the module, from there, walk towards the starting position
    success, block = turtle.inspectDown()
    if not success then
        -- find glass block wall
        for i = 1, 4, 1 do
            success, block = turtle.inspect()
            if success and block.name == "minecraft:glass" then
                break
            end
            turtle.turnRight()
        end
        if not success or block.name ~= "minecraft:glass" then
            return false, "FAILED TO WALK BACK TO START"
        end

        -- Walk towards the corner (above the output barrel)
        turtle.turnRight()
        while turtle.forward() do end

        -- Go back one block (above the starting position)
        turtle.back()

        -- Turn to face the starting position
        turtle.turnRight()

        -- Walk down towards the starting position
        moveToStart()
        return checkIfInStartingPosition()
    end

    return false, "FAILED TO WALK BACK TO START"
end

local function initialize()
    logInfo("Initializing")

    if type(modem) ~= "table" then
        logError("No modem found", true)
    end

    local isInStartingPosition = checkIfInStartingPosition()
    if isInStartingPosition then
        wipeLogs()
    else
        local success, message = tryWalkBackToStart()
        if not success then
            logError("Failed to walk back to start: " .. message, true)
        end
        logInfo("Found way back to starting position")
    end
end

local function main()
    initialize()
    while running do
        if not emptyInventory() then
            logError("Chest is full", true)
        end
        refuel()
        if not checkInventoryEmpty() then
            logError("Inventory not empty", true)
        end
        harvestModule()
        sleep(harvestInterval)
    end
end

parallel.waitForAll(main, listenForShutdownMessage)