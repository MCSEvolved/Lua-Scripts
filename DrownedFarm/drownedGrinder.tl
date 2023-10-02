---------------------TYPES---------------------
local Grinder = require("@types.peripherals.grinder")
local Inventory = require("@types.peripherals.inventory")
--------------------END TYPES------------------
require("Tracker.TrackerLib")

local chest: Inventory = peripheral.find("minecraft:chest") as Inventory


local function getGrinders(): {Grinder}
    local grinders: {Grinder} = {}
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "grinder" then
            table.insert(grinders, peripheral.wrap(name) as Grinder)
        end
    end
    return grinders
end

local function pushSwordToGrinder(slot: number): boolean
    SendDebug("Pushing sword from slot " .. slot .. " to grinder")
    local grinders = getGrinders()
    for _, grinder in ipairs(grinders) do
        local _, hasSword = grinder.hasSword()
        if not hasSword then
            -- slot -1 because the grinder starts counting at 0
            grinder.pushSword(peripheral.getName(chest), slot - 1)
            return true
        end
    end
    return false
end

local function checkSword(item: table | nil): boolean
    if item is nil then return false end
    if type(item.name) ~= "string" then return false end
    local itemName = item.name as string
    if not itemName:find("sword") then
        SendInfo("Found item that is not a sword: " .. itemName)
        return false
    end
    if type(item.damage) ~= "number" then return false end
    if type(item.maxDamage) ~= "number" then return false end
    if item.damage as number / item.maxDamage as number < 0.9 then
        SendDebug("Found sword with low damage, pushing to grinder")
        return true
    else
        SendDebug("Found sword with high damage, not pushing to grinder")
    end
end

-- Check the health of the swords 
local function checkSwords()
    SendDebug("Checking swords")
    local grinders = getGrinders()
    for _, grinder in ipairs(grinders) do
        grinder.pullSword(peripheral.getName(chest))
    end

    local allGrindersFull = false
    for k, _ in pairs(chest.list()) do
        local item = chest.getItemDetail(k)
        if checkSword(item) then
            allGrindersFull = pushSwordToGrinder(k)
            if allGrindersFull then
                SendDebug("All grinders are full, stopping sword check")
                return
            end
        end
        SendDebug("Slot " .. k)
    end
    if not allGrindersFull then
        SendError("Out of swords, stopping grinder")
    end
end

local function initialize()
    SendInfo("Initializing grinder")
    if not chest then
        error("No chest found")
        return
    end
    local grinders = getGrinders()
    SendDebug("Found " .. #grinders .. " grinders")

    -- Count grinders with swords
    local swordCount = 0
    for _, grinder in ipairs(grinders) do
        local _, hasSword = grinder.hasSword()
        if hasSword then
            swordCount = swordCount + 1
        else
            SendDebug("Grinder " .. peripheral.getName(grinder) .. " has no sword at initialization")
        end
    end
    SendDebug("Found " .. swordCount .. " grinders with swords")
    SendInfo("Initialization complete")
end

local function main()
    initialize()
    checkSwords()
    local grinders = getGrinders()
    while true do
        for _ = 1, 100 do
            for _, grinder in ipairs(grinders) do
                grinder.attack()
                os.sleep(1)
            end
        end
        checkSwords()
    end
end

InitTracker(main, 11);