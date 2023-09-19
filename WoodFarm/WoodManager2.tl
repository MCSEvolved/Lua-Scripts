require("Tracker.TrackerLib")

local Modem = require("@types.peripherals.modem")
local Computer = require("@types.peripherals.computer")
local Inventory = require("@types.peripherals.inventory")
local MEBridge = require("@types.peripherals.me_bridge")

local record Message
    type: string
    data: any|nil
    origin: string|number
end



local function findWirelessModem(): Modem
    return peripheral.find("modem", function(_n: string, o: Modem): boolean
        return o.isWireless()
    end) as Modem
end

local function getAllTurtles(): {string}
    local list = {}
    for _, value in ipairs(peripheral.getNames()) do
        if value:find("turtle") then
            table.insert(list, value)
        end
    end
    return list
end

local function getNameOfTurtleById(id: number): string
    local turtles = getAllTurtles()
    for i=1, #turtles do
        local t = turtles[i]
        local tWrap: Computer = peripheral.wrap(t) as Computer
        if not tWrap is nil and tWrap.getID() == id then
            return t
        end
    end
    SendError("Tried to find turtle but couldnt find it", {found=turtle, lookingFor=id})
end

local bufferChestWood: Inventory
local bufferChestWoodName: string = "minecraft:chest_30"

local bufferTurtleDump: Inventory
local bufferTurtleDumpName: string = "minecraft:barrel_42"

local wirelessChannel: integer = 10

local wirelessModem: Modem = findWirelessModem()
local meBridge: MEBridge = peripheral.find("meBridge")

local workingTurtles = {}

local tasklist = {Message}

local function sendOverWireless(_type: string, data: any)
    if not wirelessModem.isOpen(wirelessChannel) then
        wirelessModem.open(wirelessChannel)
    end
    local message: Message = {
        type = _type,
        origin = "MANAGER",
        data = data
    }
    wirelessModem.transmit(wirelessChannel, wirelessChannel, message as table)
end

local function isTurtleInList(list: {number}, _turtle: number): boolean, number
    for index, foundTurtle in ipairs(list) do
        if foundTurtle == _turtle then
            return true, index
        end
    end

    return false, -1
end

local function removeTurtleFromList(list: {number}, turtleId: number)
    local succes, index = isTurtleInList(list, turtleId)
    if succes == true then
        table.remove(workingTurtles, index)
    end
end


local function toStorage(inventory: string, itemName: string, count: number): nil|number
    while true do
        local amount, err = meBridge.importItemFromPeripheral({name=itemName, count=count}, inventory)
        if amount ~= nil and err == nil then
            return amount
        end
        os.sleep(1)
    end
end

local function fromStorage(inventory: string, itemName: string, count: number): nil|number
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

local function emptyInventoryOfTurtle(turtleId: number): boolean
    SendDebug("EMPTYING INVENTORY OF "..turtleId)
    for i = 1, 16 do
        bufferTurtleDump.pullItems(getNameOfTurtleById(turtleId), i)
        local item = bufferTurtleDump.getItemDetail(1)
        if not item is nil and item.name == "minecraft:spruce_log" then
            print(i.." TO WOOD")
            if bufferChestWood.pullItems(bufferTurtleDumpName, 1) < item.count as number then
                SendWarning("Buffer Chest is full")
                toStorage(bufferTurtleDumpName, item.name as string, 64)
            end
        else
            if not item is nil then
                print(i.." TO ME")
                toStorage(bufferTurtleDumpName, item.name as string, 64)
            end
        end
    end
    return true
end

local function giveFuel(turtleId: number)
    SendDebug("GIVING FUEL TO "..turtleId)
    fromStorage(getNameOfTurtleById(turtleId), "minecraft:charcoal", 64)
    os.sleep(1)
    sendOverWireless("REFUEL", turtleId)
    os.sleep(1)
    emptyInventoryOfTurtle(turtleId)
end

local function giveSaplings(turtleId: number)
    SendDebug("GIVING SAPLINGS TO "..turtleId)
    fromStorage(getNameOfTurtleById(turtleId), "minecraft:spruce_sapling", 24)
end

local function startTurtle(turtleId: number)
    sendOverWireless("START_RUN", turtleId)
end

local function executeCommands()
    while true do
        if #tasklist < 1 then
            os.pullEvent("task_added")
        end
        local message: Message = tasklist[#tasklist]
        table.remove(tasklist, #tasklist)
        if not message is nil and message ~= {} then
            if message.origin == nil then
                SendWarning("Received message from unkown origin", message)
            else
                SendDebug("[COMMAND] "..message.type.. " FROM: "..message.origin as string, message)
            end
            if message.type == "START_TURTLE" then
                if not isTurtleInList(workingTurtles, message.origin as number) then
                    table.insert(workingTurtles, message.origin)
                    emptyInventoryOfTurtle(message.origin as number)
                    giveFuel(message.origin as number)
                    giveSaplings(message.origin as number)
                    startTurtle(message.origin as number)
                end
                
            elseif message.type == "IS_ONLINE" then
                if message.data == false then
                    removeTurtleFromList(workingTurtles, message.origin as number)
                    table.insert(tasklist, 1, {type="START_TURTLE", origin=message.origin} as Message)
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
        local _event, _side, channel, _replyChannel, _message, _distance = os.pullEvent("modem_message")
        if channel == wirelessChannel then
            local message: Message = _message as Message
            SendDebug("[RECEIVED] "..message.type.." FROM: "..message.origin as string, message)
            if message.type == "DONE" then
                removeTurtleFromList(workingTurtles, message.origin as number)
                table.insert(tasklist, 1, {type="START_TURTLE", origin=message.origin} as Message)
                os.queueEvent("task_added")
            elseif message.type == "ONLINE" then
                table.insert(tasklist, 1, {type="IS_ONLINE", origin=message.origin, data=message.data} as Message)
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
        SendError("Couldn't Establish Wireless Connection", wirelessModem)
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