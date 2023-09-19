require("Tracker.TrackerLib")

local Modem = require("@types.peripherals.modem")
local Computer = require("@types.peripherals.computer")
local Inventory = require("@types.peripherals.inventory")
local MEBridge = require("@types.peripherals.me_bridge")
local Monitor = require("@types.peripherals.monitor")

local bufferChestWood: Inventory
local bufferChestWoodName = "minecraft:chest_29"

local toStorage: Inventory
local toStorageName = "minecraft:barrel_44"

local fromStorage: Inventory
local fromStorageName = "minecraft:barrel_43"

local production = 0
local monitor: Monitor = peripheral.find("monitor")


local furnaces: {string} = {}

local function findFurnaces()
    for _, value in ipairs(peripheral.getNames()) do
        if value:find("furnace") then
            table.insert(furnaces, value)
        end
    end
    SendInfo(#furnaces.." Furnaces Found")
end

local function pushToStorage(from: string, fromSlot: integer)
    production = production + toStorage.pullItems(from, fromSlot)
end

local function getMeBridge(): MEBridge
    local meBridge = peripheral.find("meBridge") as MEBridge
    if meBridge then
        return meBridge
    else
        SendInfo("ME OFFLINE, WAITING...")
        while meBridge == nil do
            os.sleep(0.01)
        end
        return meBridge
    end
end

local function pullFromStorage(to: string, toSlot: integer, item: {any:any})
    getMeBridge().exportItemToPeripheral({name=item.name as string, count=item.count as number}, fromStorageName)
    for i = 1, fromStorage.size() do
        local detail = fromStorage.getItemDetail(i)
        if not detail is nil and detail.name == item.name then
            local amountPushed: number = fromStorage.pushItems(to, i, item.count as integer, toSlot)
            if amountPushed < item.count as number then
                item.count = item.count as number - amountPushed
            else
                return
            end
        end
    end
    
end

local function pushWoodToFurnaces()
    local furnaceIndex = 1
    while true do
        for i=1,bufferChestWood.size() do
            local detail = bufferChestWood.getItemDetail(i)
            while not detail is nil and detail.name == "minecraft:spruce_log" do
                local furnace = furnaces[furnaceIndex]
                print("PUSHING TO FURNACE "..furnaceIndex)
                bufferChestWood.pushItems(furnace, i, 8, 1)
                if furnaceIndex < #furnaces then
                    furnaceIndex = furnaceIndex + 1
                else
                    furnaceIndex = 1
                end
                    
                detail = bufferChestWood.getItemDetail(i)
            end
        end
    end
end

local function pullCharcoalFromFurnaces()
    while true do
        for _, furnace in ipairs(furnaces) do
            local furnacePeripheral = peripheral.wrap(furnace) as Inventory
            local detail = furnacePeripheral.getItemDetail(3)
            if detail then
                pushToStorage(furnace, 3)
            end
        end
    end
end

local function pushFuelToFurnaces()
    while true do
        for _, furnace in ipairs(furnaces) do
            local furnacePeripheral = peripheral.wrap(furnace) as Inventory
            local detail = furnacePeripheral.getItemDetail(2)
            if detail is nil then
                pullFromStorage(furnace, 2, {name="minecraft:charcoal", count=64})
            else
                local amountNeeded = 64 - detail.count as number
                if amountNeeded > 0 then
                    pullFromStorage(furnace, 2, {name="minecraft:charcoal", count=amountNeeded})
                end
            end
        end
    end
end

local function writeLineToMonitor(message: string)
    monitor.clearLine()
    monitor.write(message)
    local x, y = monitor.getCursorPos()
    monitor.setCursorPos(1, y+1)
end

local function updateMonitor()
    while true do
        monitor.setCursorPos(1, 1)
        writeLineToMonitor(production as string)
        writeLineToMonitor("Coal/min")
        SendDebug("Production of last minute: "..production)
        production = 0
        os.sleep(60)
    end
end

local function initInventories()
    toStorage = peripheral.wrap(toStorageName)
    fromStorage = peripheral.wrap(fromStorageName)

    bufferChestWood = peripheral.wrap(bufferChestWoodName)
end

local function main()
    findFurnaces()
    initInventories()
    parallel.waitForAll(pushWoodToFurnaces, pushFuelToFurnaces, pullCharcoalFromFurnaces, updateMonitor)
end

InitTracker(main, 2)