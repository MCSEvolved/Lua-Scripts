------------------------TYPES------------------------
local Inventory = require("@types.peripherals.inventory")
------------------------END------------------------

local harvestInterval = 5
local modem = peripheral.find("modem")
--local running = true

local function logInfo(message: string)
    print("[INFO] " .. message)
end

local function logWarning(message: string)
    print("[WARNING] " .. message)
end

local function logError(message: string, reboot: boolean)
    print("[ERROR] " .. message)
    if reboot then
        os.reboot()
    end
end


---move forward a specified amount of blocks
---@param count number
local function moveForward(count: number): boolean, {string: any} | string
    for _ = 1, count do
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
local function moveUp(count: number): boolean, {string: any} | string
    for _ = 1, count do
        local success = turtle.up()
        if not success then
            local _, block = turtle.inspectUp()
            return false, block
        end
    end
    return true
end

local function harvestRow(): boolean
    logInfo("Harvesting row")
    while true do
        local _, block = turtle.inspect()
        if not block is string and block.name == "minecraft:pumpkin" then
            turtle.dig()
        elseif not block is string and block.name == "minecraft:glass" then
            return true
        elseif not block is string then
            logWarning("Expected pumpkin, glass or air, got " .. block.name as string)
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
        local _, block = turtle.inspect()
        if not block is string and block.name == "minecraft:pumpkin" then
            turtle.dig()
        elseif not block is string then
            logError("Expected pumpkin or air, got " .. block.name as string)
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
local function moveToNextLayer(): boolean
    logInfo("moving to next layer")
    local success, block = moveUp(2)
    if not success and type(block) == "table" then
        return false
    elseif not success then
        logError("moveUp during movement to next layer failed without block above turtle", true)
    end
    return true
end

local function findGlassWall(): boolean
    for _ = 1, 4, 1 do
        local _, block = turtle.inspect()
        if not block is string and block.name == "minecraft:glass" then
            return true
        end
        turtle.turnRight()
    end
    return false
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

local function dropPumpkinsInOutput(): boolean
    logInfo("Dropping pumpkins in output")
    local _, block = turtle.inspect()
    if block is string or block.name ~= "minecraft:glass" then
        turtle.turnLeft()
        turtle.forward()
    end

    local _, newBlock = turtle.inspectDown()
    if newBlock is string then
        logError("Expected barrel, got " .. "unknown (probably air)", true)
        return false
    end

    if newBlock.name ~= "minecraft:barrel" then
        logError("Expected barrel, got " .. newBlock.name as string, true)
        return false
    end

    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        if item is table and item.name == "minecraft:pumpkin" then
            turtle.select(i)
            if not turtle.dropDown() then
                logWarning("Failed to drop items in barrel")
                return false
            end
            if turtle.getItemCount(i) > 0 then
                logWarning("Failed to drop all items from slot in barrel")
                return false
            end
        elseif item is table then
            logWarning("Found item item in inventory: " .. item.name as string)
        end
    end
    turtle.back()
    turtle.turnRight()
    return true
end

local function refuel(): boolean
    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        if item is table and item.name == "minecraft:charcoal" then
            turtle.select(i)
            turtle.refuel()
        end
    end

    if turtle.getFuelLevel() > (64*80) then
        logInfo("Fuel level: OK")
        return true
    end

    logInfo("Fuel level too low, refueling...")
    local _, newBlock = turtle.inspectDown()
    if newBlock is string then
        logError("Expected barrel, got " .. "unknown (probably air)", true)
        return false
    end

    if newBlock.name ~= "minecraft:barrel" then
        logError("Expected barrel, got " .. newBlock.name as string, true)
        return false
    end

    turtle.suckDown()

    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        if item is table and item.name == "minecraft:charcoal" then
            turtle.select(i)
            turtle.refuel()
        end
    end

    if turtle.getFuelLevel() < (64*80) then
        logError("Fuel level too low, no fuel found.", true)
        return false
    else
        logInfo("Fuel level: OK")
        return true
    end
end

local function checkInventoryEmpty(): boolean
    for i = 1, 16 do
        if turtle.getItemCount(i) > 0 then
            return false
        end
    end
    return true
end

local function checkIfInStartingPosition(): boolean, string
    logInfo("Checking if turtle is in starting position")

    -- Check if block under is barrel
    local success, block = turtle.inspectDown()
    if block is string or block.name ~= "minecraft:barrel" then
        return false, "BLOCK DOWN NOT BARREL"
    end

    -- find glass block wall
    if not findGlassWall() then
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
    if not block is string and block.name ~= "minecraft:pumpkin" then
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

    -- Return true if blocks around are correct
    return true, "OK"
end

--- try to walk back to start
---@return boolean
---@return string
local function tryWalkBackToStart(): boolean, string
    local x, y, z = gps.locate()
    if x == nil or y == nil or z == nil then
        logInfo("Trying to walk back to start")
    else
        logInfo("Trying to walk back to start" .. " x:" .. x .. " y:" .. y .. " z:" .. z)
    end

    -- Check if block under is barrel and try to walk back to start if on top of output barrel
    local success, block = turtle.inspectDown()
    if not block is string and block.name == "minecraft:barrel" then
        for _ = 1, 4 do
            success, block = turtle.inspect()
            if not block is string and (block.name == "minecraft:pumpkin_stem" or block.name == "minecraft:attached_pumpkin_stem") then
                turtle.turnRight()
                turtle.forward()
                turtle.turnLeft()
                break;
            end
        end

        return checkIfInStartingPosition()
    end

    -- Check if block under is dirt or grass and try to walk back to glass wall with walking space (front of module)
    if not block is string and (block.name == "minecraft:dirt" or block.name == "minecraft:grass_block") then
        if not harvestRow() then
            if findGlassWall() then
                turtle.turnRight()
                turtle.back()
            else
                logError("Failed to harvest row while trying to find route to start", true)
                return false, "FAILED TO WALK BACK TO START"
            end
        end
        if not findGlassWall() then
            return false, "FAILED TO WALK BACK TO START"
        end
        success, block = turtle.inspectDown()
        if not block is string and (block.name == "minecraft:dirt" or block.name == "minecraft:grass_block") then
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
    if block is string or (block.name ~= "minecraft:dirt" and block.name ~= "minecraft:grass_block") then
        -- find glass block wall
        if not findGlassWall() then
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

local function waitForBarrelToHaveSpace(): boolean
    logInfo("Waiting for barrel to be empty")

    while true do
        local _, block = turtle.inspectDown()
        if block is string or block.name ~= "minecraft:barrel" then
            logError("Expected barrel below turtle while waiting for it to be empty", true)
        end
        local barrel = peripheral.wrap("bottom") as Inventory
        for i = 1, 27 do
            local item = barrel.getItemDetail(i)
            if item is table and item.maxCount as number > item.count as number then
                return true
            end
        end
    end
end

local function initialize()
    logInfo("Initializing")

    if type(modem) ~= "table" then
        logError("No modem found", true)
    end

    local isInStartingPosition = checkIfInStartingPosition()
    if not isInStartingPosition then
        local success, message = tryWalkBackToStart()
        if not success then
            logError("Failed to walk back to start: " .. message, true)
        else
            logInfo("Found way back to starting position")
        end
    end
end

local function main()
    initialize()
    while true do
        while not dropPumpkinsInOutput() do
            waitForBarrelToHaveSpace()
        end
        refuel()
        if not checkInventoryEmpty() then
            logError("Inventory not empty", true)
        end
        harvestModule()
        os.sleep(harvestInterval)
    end
end