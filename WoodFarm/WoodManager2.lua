require("Tracker.TrackerLib")

local function findWirelessModem()
    return peripheral.find("modem", function (n,o)
        return o.isWireless()
    end)
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

local function getNameOfTurtleById(id)
    local turtles = getAllTurtles()
    for i=1, #turtles do
        local t = turtles[i]
        local tWrap = peripheral.wrap(t)
        if tWrap and tWrap.getID() == id then
            return t
        end
    end
    error("DOESNT EXIST")
end

local bufferChestWood
local bufferChestWoodName = "minecraft:chest_30"

local bufferTurtleDump
local bufferTurtleDumpName = "minecraft:barrel_42"

local wirelessChannel = 10

local wirelessModem = findWirelessModem()
local meBridge = peripheral.find("meBridge")

local workingTurtles = {}

local tasklist = {}

local function sendOverWireless(type, data)
    if not wirelessModem.isOpen(wirelessChannel) then
        wirelessModem.open(wirelessChannel)
    end
    local message = {
        type = type,
        origin = "MANAGER",
        data = data
    }
    wirelessModem.transmit(wirelessChannel, wirelessChannel, message)
end

local function isTurtleInList(list, turtle)
    for index, foundTurtle in ipairs(list) do
        if foundTurtle == turtle then
            return true, index
        end
    end

    return false, -1
end

local function removeTurtleFromList(list, turtleId)
    local succes, index = isTurtleInList(list, turtleId)
    if succes == true then
        table.remove(workingTurtles, index)
    end
end


local function toStorage(inventory, itemName, count)
    while true do
        local amount, err = meBridge.importItemFromPeripheral({name=itemName, count=count}, inventory)
        if amount ~= nil and err == nil then
            return amount
        end
        os.sleep(1)
    end
end

local function fromStorage(inventory, itemName, count)
    while true do
        local amount, err = meBridge.exportItemToPeripheral({name=itemName, count=count}, inventory)
        if amount ~= nil and err == nil then
            if amount >= count then
                return amount
            else
                count = count - amount
            end
            
        end
        os.sleep(1)
    end
end

local function emptyInventoryOfTurtle(turtleId)
    print("EMPTYING INVENTORY OF "..turtleId, true)
    for i = 1, 16 do
        bufferTurtleDump.pullItems(getNameOfTurtleById(turtleId), i)
        local item = bufferTurtleDump.getItemDetail(1)
        if item and item.name == "minecraft:spruce_log" then
            print(i.." TO WOOD")
            if bufferChestWood.pullItems(bufferTurtleDumpName, 1) < item.count then
                SendWarning("Buffer Chest is full")
                toStorage(bufferTurtleDumpName, item.name, 64)
            end
        else
            if item then
                print(i.." TO ME")
                toStorage(bufferTurtleDumpName, item.name, 64)
            end
        end
    end
    return true
end

local function giveFuel(turtleId)
    print("GIVING FUEL TO "..turtleId, true)
    fromStorage(getNameOfTurtleById(turtleId), "minecraft:charcoal", 64)
    os.sleep(1)
    sendOverWireless("REFUEL", turtleId)
    os.sleep(1)
    emptyInventoryOfTurtle(turtleId)
end

local function giveSaplings(turtleId)
    print("GIVING SAPLINGS TO "..turtleId, true)
    fromStorage(getNameOfTurtleById(turtleId), "minecraft:spruce_sapling", 24)
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
        if message ~= nil then
            print("[COMMAND] "..message.type.. " FROM: "..message.origin, true)
            if message.type == "START_TURTLE" then
                if not isTurtleInList(workingTurtles, message.origin) then
                    table.insert(workingTurtles, message.origin)
                    emptyInventoryOfTurtle(message.origin)
                    giveFuel(message.origin)
                    giveSaplings(message.origin)
                    startTurtle(message.origin)
                end
                
            elseif message.type == "IS_ONLINE" then
                if message.data == false then
                    removeTurtleFromList(workingTurtles, message.origin)
                    table.insert(tasklist, 1, {type="START_TURTLE", origin=message.origin})
                    os.queueEvent("task_added")
                else
                    table.insert(workingTurtles, message.origin)
                end
            end
        end
    end
end

local function listenOnWireless()
    while true do
        local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
        if channel == wirelessChannel then
            print("[RECEIVED] "..message.type.." FROM: "..message.origin, true)
            if message.type == "DONE" then
                removeTurtleFromList(workingTurtles, message.origin)
                table.insert(tasklist, 1, {type="START_TURTLE", origin=message.origin})
                os.queueEvent("task_added")
            elseif message.type == "ONLINE" then
                table.insert(tasklist, 1, {type="IS_ONLINE", origin=message.origin, data=message.data})
                os.queueEvent("task_added")
            end
        end
        
    end
end

local function sendIsOnline()
    sendOverWireless("IS_ONLINE")
end


local function initComs()
    wirelessModem.open(wirelessChannel)
    if not wirelessModem.isOpen(wirelessChannel) then
        error("Couldn't Establish Wireless Connection")
    end
end


local function initPeripherals()
    bufferChestWood = peripheral.wrap(bufferChestWoodName)
    bufferTurtleDump = peripheral.wrap(bufferTurtleDumpName)
end

local function main()
    initPeripherals()
    initComs()
    parallel.waitForAll(listenOnWireless, executeCommands, sendIsOnline)
end

InitTracker(main, 2)