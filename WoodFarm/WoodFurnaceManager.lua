local bufferChestWood
local bufferChestWoodName = "minecraft:chest_13"

local tempInventory
local tempInventoryName = "minecraft:barrel_0"

local meBridge = peripheral.find("meBridge")

local furnaces = {}

local function findFurnaces()
    for key, value in pairs(peripheral.getNames()) do
        if value:find("furnace") then
            table.insert(furnaces, value)
        end
    end
    print(#furnaces.." Furnaces Found")
end

local function pushToStorage(from, fromSlot, item)
    tempInventory.pullItems(from, fromSlot)
    meBridge.importItemFromPeripheral({name=item.name, count=item.count}, tempInventoryName)
end

local function pullFromStorage(to, toSlot, item)
    meBridge.exportItemToPeripheral({name=item.name, count=item.count}, tempInventoryName)
    for i = 1, tempInventory.size() do
        if tempInventory.getItemDetail(i) and tempInventory.getItemDetail(i).name == item.name then
            local amountPushed = tempInventory.pushItems(to, i, item.count, toSlot)
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
                print(furnaceIndex)
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
                pushToStorage(furnace, 3, detail)
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

local function main()
    findFurnaces()
    tempInventory = peripheral.wrap(tempInventoryName)
    bufferChestWood = peripheral.wrap(bufferChestWoodName)
    parallel.waitForAll(pushWoodToFurnaces, pushFuelToFurnaces, pullCharcoalFromFurnaces)
end

main()