------------------------TYPES------------------------
local Inventory = require("@types.peripherals.inventory")
------------------------LIB------------------------
require("Tracker.TrackerLib")
------------------------VARIABLES------------------------
local harvestInterval = 5 -- seconds
local modem = peripheral.find("modem")
------------------------END------------------------


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
    SendDebug("Harvesting row")
    while true do
        local _, block = turtle.inspect()
        if not block is string and block.name == "minecraft:pumpkin" then
            turtle.dig()
        elseif not block is string and block.name == "minecraft:glass" then
            return true
        elseif not block is string then
            SendWarning("Expected pumpkin, glass or air, got " .. block.name as string)
            return false
        end
        turtle.forward()
    end
end

local function turnToNextRowRight()
    SendDebug("Turning to next row right")
    turtle.turnRight()

    -- Log info if turtle can't move forward after mining pumpkin
    local doLogWarning = false
    while not turtle.forward() do
        local _, block = turtle.inspect()
        if not block is string and block.name == "minecraft:pumpkin" then
            turtle.dig()
        elseif not block is string then
            SendWarning("Expected pumpkin or air, got " .. block.name as string)
        end

        -- Don't log info first time
        if doLogWarning then
            SendInfo("Failed to move forward, trying again")
        end
        doLogWarning = true
    end
    turtle.turnRight()
end

local function turnToNextRowLeft()
    SendDebug("Turning to next row left")
    turtle.turnLeft()
    local success = moveForward(4)
    if not success then error("Failed to move forward 4 blocks") end
    turtle.turnLeft()
end

local function harvestLayer()
    -- Harvest first row
    local success = harvestRow()
    if not success then error("Failed to harvest first row") end

    -- Turn around
    turnToNextRowRight()

    -- Harvest second row
    success = harvestRow()
    if not success then error("Failed to harvest second row") end

    -- Turn around
    turnToNextRowLeft()

    -- Harvest third row
    success = harvestRow()
    if not success then error("Failed to harvest third row") end

    -- Turn around
    turnToNextRowRight()

    -- Harvest fourth row
    success = harvestRow()
    if not success then error("Failed to harvest fourth row") end

    -- move back to layer start
    SendDebug("moving back to layer start")
    turtle.turnRight()
    moveForward(6)
    turtle.turnRight()
end

--- move to next layer
---@return boolean
local function moveToNextLayer(): boolean
    SendDebug("moving to next layer")
    local success, block = moveUp(2)
    if not success and type(block) == "table" then
        return false
    elseif not success then
        error("moveUp during movement to next layer failed without block above turtle")
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
    SendDebug("moving to start")
    while true do
        if not turtle.down() then
            return
        end
    end
end

local function harvestModule()
    -- Setup
    SetFarmingStatus()
    SendDebug("Harvesting module")
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
    SetEmptyingStatus()
    SendDebug("Dropping pumpkins in output")
    local _, block = turtle.inspect()
    if block is string or block.name ~= "minecraft:glass" then
        turtle.turnLeft()
        turtle.forward()
    end

    local _, newBlock = turtle.inspectDown()
    if newBlock is string then
        error("Expected barrel, got " .. "unknown (probably air)")
        return false
    end

    if newBlock.name ~= "minecraft:barrel" then
        error("Expected barrel, got " .. newBlock.name as string)
        return false
    end

    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        if not item is nil and item.name == "minecraft:pumpkin" then
            turtle.select(i)
            if not turtle.dropDown() then
                SendInfo("Failed to drop items in barrel")
                return false
            end
            if turtle.getItemCount(i) > 0 then
                SendInfo("Failed to drop all items from slot in barrel")
                return false
            end
        elseif not item is nil then
            SendWarning("Found item in inventory: " .. item.name as string)
        end
    end
    turtle.back()
    turtle.turnRight()
    return true
end

local function refuel(): boolean
    SetRefuelingStatus()
    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        if not item is nil and item.name == "minecraft:charcoal" then
            turtle.select(i)
            turtle.refuel()
        end
    end

    if turtle.getFuelLevel() > (64*80) then
        SendDebug("Fuel level: OK")
        return true
    end

    SendDebug("Fuel level too low, refueling...")
    local _, newBlock = turtle.inspectDown()
    if newBlock is string then
        error("Expected barrel while refueling, got " .. "unknown (probably air)")
        return false
    end

    if newBlock.name ~= "minecraft:barrel" then
        error("Expected barrel while refueling, got " .. newBlock.name as string)
        return false
    end

    turtle.suckDown()

    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        if not item is nil and item.name == "minecraft:charcoal" then
            turtle.select(i)
            turtle.refuel()
        end
    end

    if turtle.getFuelLevel() < (64*80) then
        error("Fuel level too low, no fuel found.")
        return false
    else
        SendDebug("Fuel level: OK")
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
    SendDebug("Checking if turtle is in starting position")

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
        SendInfo("Trying to walk back to start", {Coordinates={x=x, y=y, z=z}})
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
                error("Failed to harvest row while trying to find route to start")
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
                error("Failed to harvest row while trying to find route to start")
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
    SendInfo("Waiting for barrel to be empty")

    while true do
        local _, block = turtle.inspectDown()
        if block is string or block.name ~= "minecraft:barrel" then
            error("Expected barrel below turtle while waiting for it to be empty")
        end
        local barrel = peripheral.wrap("bottom") as Inventory
        for i = 1, 27 do
            local item = barrel.getItemDetail(i)
            if item is nil then
                return true
            elseif item.maxCount as number > item.count as number then
                return true
            end
        end
        os.sleep(1)
    end
end

local function initialize()
    SendInfo("Initializing")

    if type(modem) ~= "table" then
        SendError("No modem found", {Peripherals=peripheral.getNames()})
        error()
    end

    local isInStartingPosition = checkIfInStartingPosition()
    if not isInStartingPosition then
        local success, message = tryWalkBackToStart()
        if not success then
            error("Failed to walk back to start: " .. message)
        else
            SendDebug("Found way back to starting position")
        end
    end
    SendInfo("Initialization complete")
end

local function waitForNextHarvest()
    SetWaitingStatus()
    SendDebug("Waiting for next harvest")
    os.sleep(harvestInterval)
end

local function main()
    initialize()
    while true do
        while not dropPumpkinsInOutput() do
            waitForBarrelToHaveSpace()
        end
        refuel()
        if not checkInventoryEmpty() then
            error("Inventory not empty")
            error()
        end
        harvestModule()
        waitForNextHarvest()
    end
end

InitTracker(main, 3)