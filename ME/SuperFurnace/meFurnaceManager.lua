local furnaces = {}

local inputBarrel
local inputBarrelName

local patternProvider
local patternProviderName

local fromStorage
local fromStorageName

local meBridge

local function pullFromStorage(to, toSlot, item)
    meBridge.exportItemToPeripheral({name=item.name, count=item.count}, fromStorageName)
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

local function findFurnaces()
    for key, value in pairs(peripheral.getNames()) do
        if value:find("furnace") then
            table.insert(furnaces, value)
        elseif value:find("smoker") then
            table.insert(furnaces, value)
        end
    end
    print(#furnaces.." Furnaces Found")
end

local function findPeripherals()
    inputBarrel = peripheral.find("minecraft:barrel")
    inputBarrelName = peripheral.getName(inputBarrel)

    patternProvider = peripheral.find("ae2:pattern_provider")
    patternProviderName = peripheral.getName(patternProvider)

    fromStorage = peripheral.find("minecraft:chest")
    fromStorageName = peripheral.getName(fromStorage)

    meBridge = peripheral.find("meBridge")
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




local function pushItemsToFurnaces()
    local furnaceIndex = 1
    while true do
        for i=1,inputBarrel.size() do
            local detail = inputBarrel.getItemDetail(i)
            while detail do
                local furnace = furnaces[furnaceIndex]
                print("PUSHING TO FURNACE "..furnaceIndex)
                inputBarrel.pushItems(furnace, i, 8, 1)
                if furnaceIndex < #furnaces then
                    furnaceIndex = furnaceIndex + 1
                else
                    furnaceIndex = 1
                end
                    
                detail = inputBarrel.getItemDetail(i)
            end
        end
    end
end



local function pullItemsFromFurnaces()
    while true do
        for _, furnace in pairs(furnaces) do
            local wrapped = peripheral.wrap(furnace)
            local detail = wrapped.getItemDetail(3)
            if detail then
                for i=1, 9 do
                    local amount = wrapped.pushItems(patternProviderName, 3, 64, i)
                    if amount >= detail.count then
                        break
                    end
                end
                
            end
        end
    end
end





local function main()
    findFurnaces()
    findPeripherals()
    parallel.waitForAll(pushFuelToFurnaces, pushItemsToFurnaces, pullItemsFromFurnaces)
end

main()