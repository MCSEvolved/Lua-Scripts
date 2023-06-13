local bufferChestWood
local bufferChestWoodName = "minecraft:chest_13"

local toStorage
local toStorageName = "minecraft:barrel_0"

local fromStorage
local fromStorageName = "minecraft:barrel_2"

local production = 0
local monitor = peripheral.find("monitor")


local furnaces = {}

local function findFurnaces()
    for key, value in pairs(peripheral.getNames()) do
        if value:find("furnace") then
            table.insert(furnaces, value)
        end
    end
    print(#furnaces.." Furnaces Found")
end

local function pushToStorage(from, fromSlot)
    production = production + toStorage.pullItems(from, fromSlot)
end

local function getMeBridge()
    local meBridge = peripheral.find("meBridge")
    if meBridge then
        return meBridge
    else
        print("ME OFFLINE, WAITING...")
        while meBridge == nil do
            os.sleep(0.01)
        end
        return meBridge
    end
end

local function pullFromStorage(to, toSlot, item)
    getMeBridge().exportItemToPeripheral({name=item.name, count=item.count}, fromStorageName)
    for i = 1, fromStorage.size() do
        local detail = fromStorage.getItemDetail(i)
        if detail and detail.name == item.name then
            local amountPushed = fromStorage.pushItems(to, i, item.count, toSlot)
            if amountPushed < item.count then
                item.count = item.count - amountPushed
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
            while detail and detail.name == "minecraft:spruce_log" do
                local furnace = furnaces[furnaceIndex]
                print("PUSHING TO FURNACE "..furnaceIndex)
                if bufferChestWood.pushItems(furnace, i, 64, 1) < 10 then
                    if furnaceIndex < #furnaces then
                        furnaceIndex = furnaceIndex + 1
                    else
                        furnaceIndex = 1
                    end
                    
                end
                detail = bufferChestWood.getItemDetail(i)
            end
        end
    end
end

local function pullCharcoalFromFurnaces()
    while true do
        for key, furnace in pairs(furnaces) do
            local detail = peripheral.wrap(furnace).getItemDetail(3)
            if detail then
                pushToStorage(furnace, 3)
            end
        end
    end
end

local function pushFuelToFurnaces()
    while true do
        for key, furnace in pairs(furnaces) do
            local detail = peripheral.wrap(furnace).getItemDetail(2)
            if not detail then
                pullFromStorage(furnace, 2, {name="minecraft:charcoal", count=64})
            else
                local amountNeeded = 64 - detail.count
                if amountNeeded > 0 then
                    pullFromStorage(furnace, 2, {name="minecraft:charcoal", count=amountNeeded})
                end
            end
        end
    end
end

local function writeLineToMonitor(message)
    monitor.clearLine()
    monitor.write(message)
    local x, y = monitor.getCursorPos()
    monitor.setCursorPos(1, y+1)
end

local function updateMonitor()
    while true do
        monitor.setCursorPos(1, 1)
        writeLineToMonitor(production)
        writeLineToMonitor("Coal/min")
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

main()