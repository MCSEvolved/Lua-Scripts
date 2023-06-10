local function findWirelessModem()
    return peripheral.find("modem", function (n,o)
        return o.isWireless()
    end)
end


local function arrayContainsElement (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true, index
        end
    end

    return false
end

local function getAllTurtles()
    local list = {}
    for key, value in pairs(peripheral.getNames()) do
        if value:find("turtle") then
            table.insert(list, value)
        end
    end
    return list
end

local bufferChestWood
local bufferChestWoodName = "minecraft:chest_13"

local bufferTurtleDump
local bufferTurtleDumpName = "minecraft:barrel_1"

local wirelessChannel = 10

local wirelessModem = findWirelessModem()
local meBridge = peripheral.find("meBridge")

local turtles = {}

local tasklist = {}

local function getMeBridge()
    meBridge = peripheral.find("meBridge")
    if meBridge then
        return meBridge
    else
        print("ME OFFLINE, WAITING...")
        while meBridge == nil do
            meBridge = peripheral.find("meBridge")
            os.sleep(1)
        end
        return meBridge
    end
end



local function getNameOfTurtleById(id)
    turtles = getAllTurtles()
    for i=1, #turtles do
        local t = turtles[i]
        local tWrap = peripheral.wrap(t)
        if tWrap and tWrap.getID() == id then
            return t
        end
    end
    error("DOESNT EXIST")
end

local function sendOverWireless(type, data)
    if not wirelessModem.isOpen(wirelessChannel) then
        wirelessModem.open(wirelessChannel)
    end
    local message = {
        type = type,
        origin = "MANAGER",
        data = data
    }
    print("[SENT] "..message.type.." TO "..message.data)
    wirelessModem.transmit(wirelessChannel, wirelessChannel, message)
end

local function emptyInventoryOfTurtle(turtleId)
    print("EMPTYING INVENTORY OF "..turtleId)
    for i = 1, 16, 1 do
        bufferTurtleDump.pullItems(getNameOfTurtleById(turtleId), i)
        local item = bufferTurtleDump.getItemDetail(1)
        if item and item.name == "minecraft:spruce_log" then
            print(i.." TO WOOD")
            if bufferChestWood.pullItems(bufferTurtleDumpName, 1) < item.count then
                print("Buffer Chest is full")
                return false
            end
        else
            if item then
                print(i.." TO ME")
                local amountPulled = getMeBridge().importItemFromPeripheral({name=item.name, count=item.count}, bufferTurtleDumpName)
                -- if  amountPulled < item.count then
                --     print("error2")
                --     return false
                -- end
            end
        end
    end
    return true
end

local function giveFuel(turtleId, amount)
    print("GIVING FUEL TO "..turtleId)
    --emptyInventoryOfTurtle(turtleId)
    local amountPulled = getMeBridge().exportItemToPeripheral({name="minecraft:charcoal", count=amount}, getNameOfTurtleById(turtleId))
    if amountPulled ~= nil then
        if amountPulled  < amount then
            return false
        else
            return true
        end
    else 
        return false
    end
end


local function giveSaplings(turtleId)
    print("GIVING SAPLINGS TO "..turtleId)
    emptyInventoryOfTurtle(turtleId)
    local amountPulled = getMeBridge().exportItemToPeripheral({name="minecraft:spruce_sapling", count=24}, getNameOfTurtleById(turtleId))
    if amountPulled ~= nil then
        if amountPulled  < 24 then
            return 
        else
            return true
        end
    else
        return false
    end
    
end

local function startTurtle(turtleId)
    sendOverWireless("START_RUN", turtleId)
end

local function executeCommands()
    while true do
        if #tasklist < 1 then
            os.pullEvent("task_added")
        end
        local message = tasklist[#tasklist]
        table.remove(tasklist, #tasklist)
        print("[COMMAND] "..message.type.. " FROM: "..message.origin)
        if message == nil then
            error("Message was nil for some reason")
        end
        if message.type == "REQUEST_FUEL" then
            giveFuel(message.origin, message.data)
            print("DONE FUEL "..message.origin)
        elseif message.type == "EMPTY_INVENTORY" then
            emptyInventoryOfTurtle(message.origin)
            print("DONE INVENTORY "..message.origin)
        elseif message.type == "REQUEST_SAPLINGS" then
            giveSaplings(message.origin)
            print("DONE SAPLINGS "..message.origin)
        elseif message.type == "STANDBY" then
            startTurtle(message.origin)
        end
    end
end

local function listenOnWireless()
    while true do
        local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
        print("[RECEIVED] "..message.type.." FROM: "..message.origin)
        if message.type == "REQUEST_FUEL" then
            table.insert(tasklist, 1, message)
            os.queueEvent("task_added")
        elseif message.type == "EMPTY_INVENTORY" then
            table.insert(tasklist, 1, message)
            os.queueEvent("task_added")
        elseif message.type == "REQUEST_SAPLINGS" then
            table.insert(tasklist, 1, message)
            os.queueEvent("task_added")
        elseif message.type == "STANDBY" then
            table.insert(tasklist, 1, message)
            os.queueEvent("task_added")
        end
        sendOverWireless("TASK_RECEIVED", message.origin)
    end
end

local function initComs()
    wirelessModem.open(wirelessChannel)
    if not wirelessModem.isOpen(wirelessChannel) then
        error("Couldn't Establish Wireless Connection")
    end

    parallel.waitForAll(listenOnWireless, executeCommands)
end

local function initPeripherals()
    bufferChestWood = peripheral.wrap(bufferChestWoodName)
    bufferTurtleDump = peripheral.wrap(bufferTurtleDumpName)
    turtles = getAllTurtles()
end

local function main()
    initPeripherals()
    initComs()
end

main()