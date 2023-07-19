require("Tracker.TrackerLib")

local automata

local function checkForBucket()
    while true do
        turtle.select(1)
        local item = turtle.getItemDetail(1)
        if item and (item.name == "minecraft:bucket" or item.name == "minecraft:water_bucket") and item.count == 1 then
            return
        end
        print("Make sure that there is 1 (water) bucket in slot 1", true)
        if item == nil then
            SendError("Didn't find an item in slot 1")
        end
        if item and (item.name ~= "minecraft:bucket" and item.name ~= "minecraft:water_bucket") then
            SendError("Didn't find a bucket in slot 1", item)
        end
        if item and (item.name == "minecraft:bucket" or item.name == "minecraft:water_bucket") and item.count > 1 then
            SendError("Found more than 1 bucket in slot 1", item)
        end

        os.pullEvent("turtle_inventory")
    end
end

local function suckWater()
    checkForBucket()
    local item = turtle.getItemDetail(1)
    if item and item.name == "minecraft:bucket" then
        SendDebug("Trying to suck water")
        turtle.place()
        local itemAfter = turtle.getItemDetail(1)
        if itemAfter and itemAfter.name ~= "minecraft:water_bucket" then
            error("Unable to suck water")
        end
    else
        SendDebug("Bucket was still filled", item)
    end
end

local function placeWaterInTank()
    checkForBucket()
    while automata.getOperationCooldown("useOnBlock") > 0 do
        os.sleep(0.5)
    end
    local item = turtle.getItemDetail(1)
    if item and item.name == "minecraft:water_bucket" then
        SendDebug("Trying to place water in tank")
        local succ, err = automata.useOnBlock()
        if succ == nil then
            error(err)
        end
    else
        SendDebug("Bucket was not yet filled", item)
    end
end

local function wrapPeripherals()
    automata = peripheral.find("weakAutomata")
    if automata == nil then
        error("Unable to find 'weakAutomata'")
    end
    SendDebug("Found 'weakAutomata'")
end



local function checkForTank()
    local succ, block = turtle.inspect()
    if succ and block.name == "ae2:sky_stone_tank" then
        return
    end

    error("There isn't a Sky Stone Tank in front of the turtle")
end

local function checkForFuelBarrel()
    local succ, block = turtle.inspectDown()
    if succ and block.name == "minecraft:barrel" then
        return
    end

    error("There isn't a barrel below the turtle")
end

local function checkFuel()
    if turtle.getFuelLevel() > 10000 then
        return
    else
        SendDebug("Fuel level below 10000, refueling", turtle.getFuelLevel())
        while turtle.getFuelLevel() < 10000 do
            turtle.suckDown(64)
            for i = 1, 16, 1 do
                local item = turtle.getItemDetail(i)
                if item and item.name == "minecraft:charcoal" then
                    turtle.select(i)
                    turtle.refuel(64)
                end
            end
            
            os.sleep(0.01)
        end
        turtle.select(1)
    end
end

local function routine()
    while true do
        checkFuel()
        suckWater()
        placeWaterInTank()
        os.sleep(4)
    end
    
end

local function main()
    wrapPeripherals()
    checkForBucket()
    checkForTank()
    checkForFuelBarrel()
    checkFuel()
    routine()
end

InitTracker(main, 10)