local chest = peripheral.find("minecraft:chest")


local function getGrinders()
    local grinders = {}
    for k, name in pairs(peripheral.getNames()) do
        if peripheral.getType(name) == "grinder" then
            table.insert(grinders, peripheral.wrap(name))
        end
    end
    return grinders
end

local function pushSwordToGrinder(slot)
    local grinders = getGrinders()
    for k, grinder in pairs(grinders) do
        if not grinder.hasSword() then
            -- slot -1 because the grinder starts counting at 0
            grinder.pushSword(peripheral.getName(chest), slot - 1)
        end
    end
end

local function checkSwords()
    print("Checking swords")
    local grinders = getGrinders()
    for k, grinder in pairs(grinders) do
        grinder.pullSword(peripheral.getName(chest))
    end
    for k, item in pairs(chest.list()) do
        item = chest.getItemDetail(k)
        if item and (item.damage / item.maxDamage < 0.9) then
            print("Trying to push sword to grinder (slot " .. k .. ")")
            pushSwordToGrinder(k)
        else
            print(item.damage / item.maxDamage)
            print("Sword stays in chest (slot " .. k .. ")")
        end
    end
end

local function main()
    local grinders = getGrinders()
    while true do
        for i = 1, 10 do
            for k, grinder in pairs(grinders) do
                grinder.attack()
                sleep(1)
            end
        end
        checkSwords()
    end
end

local function initialize()
    print("Initializing")
    if not chest then
        error("No chest found")
        return false
    end
    local grinders = getGrinders()
    print("Found " .. #grinders .. " grinders")

    -- Count grinders with swords
    local swordCount = 0
    for k, grinder in pairs(grinders) do
        if grinder.hasSword() then
            swordCount = swordCount + 1
        else
            print("Grinder " .. peripheral.getName(grinder) .. " has no sword")
        end
    end
    print("Found " .. swordCount .. " grinders with swords")
end

initialize()
main()