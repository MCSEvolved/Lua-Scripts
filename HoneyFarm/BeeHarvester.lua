local outputBarrelName = "minecraft:barrel_68"
local outputBarrel

local toolBarrelName = "minecraft:barrel_67"
local toolBarrel

local beehives = {}

local function findBeehives()
    for _, p in pairs(peripheral.getNames()) do
        if p:find("beehive_interface") then
            table.insert(beehives, p)
        end
    end
    print(#beehives.." Beehives Found")
end

local function wrapBarrels()
    outputBarrel = peripheral.wrap(outputBarrelName)
    toolBarrel = peripheral.wrap(toolBarrelName)
end

local function hasBottles()
    for i=1, toolBarrel.size() do
        local item = toolBarrel.getItemDetail(i)
        if item and item.name == "minecraft:glass_bottle" then
            return true
        end
        sleep(0.01)
    end
    return false
end

local function harvestBeehives()
    local bottled = true
    while true do
        for i=1, #beehives do
            local beehive = peripheral.wrap(beehives[i])
            local LvlSuc6, amount = beehive.getHoneyLevel()
            if LvlSuc6 and amount > 4 then
                if bottled then
                    bottled = hasBottles()
                end
                if bottled then
                    print("Collecting honey from "..peripheral.getName(beehive))
                else
                    print("Collecting honeycomb from "..peripheral.getName(beehive))
                end
                
                local collectSuc6, err = beehive.collectHoney(toolBarrelName, outputBarrelName, bottled)
                if not collectSuc6 then
                    print(err)
                    --SendError(err)
                end
                bottled = not bottled
            end
            print(peripheral.getName(beehive).." - "..amount)
            os.sleep(0.01)
        end
        print("----------------")
        os.sleep(2)
    end
end

local function main()
    findBeehives()
    wrapBarrels()
    harvestBeehives()
end

main()