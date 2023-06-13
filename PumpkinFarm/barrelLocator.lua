---Get the names of the barrels that are used to output the pumpkins.
---@return table
---@return integer
local function getOutputBarrelNames()
    local outputBarrelNames = {}
    local slotToCheck = 1
    local ouputBarrelsFound = 0
    for key, peripheralName in pairs(peripheral.getNames()) do
        if (peripheral.getType(peripheralName) == "minecraft:barrel") then
            local barrel = peripheral.wrap(peripheralName)
            local item = barrel.getItemDetail(slotToCheck)
            if (item and item.name == "minecraft:pumpkin") then
                table.insert(outputBarrelNames, peripheralName)
                ouputBarrelsFound = ouputBarrelsFound + 1
                print("Found ".. ouputBarrelsFound .." output barrels")
            end
        end
    end
    return outputBarrelNames, ouputBarrelsFound
end

---Get the names of the barrels that are used to input the fuel.
---@return table
---@return integer
local function getFuelBarrelNames()
    local fuelBarrelNames = {}
    local slotToCheck = 1
    local fuelBarrelsFound = 0
    for key, peripheralName in pairs(peripheral.getNames()) do
        if (peripheral.getType(peripheralName) == "minecraft:barrel") then
            local barrel = peripheral.wrap(peripheralName)
            local item = barrel.getItemDetail(slotToCheck)
            if (item and item.name == "minecraft:charcoal") then
                table.insert(fuelBarrelNames, peripheralName)
                fuelBarrelsFound = fuelBarrelsFound + 1
                print("Found ".. fuelBarrelsFound .." fuel barrels")
            end
        end
    end
    return fuelBarrelNames, fuelBarrelsFound
end

---Write the names of the barrels to seperate files.
---@param outputBarrelNames table
---@param fuelBarrelNames table
local function writeBarrelNamesToFile(outputBarrelNames, fuelBarrelNames)
    local file = fs.open("outputBarrelNames.txt", "w")
    for key, barrelName in pairs(outputBarrelNames) do
        print(barrelName)
        file.writeLine(barrelName)
    end
    file.close()

    local file = fs.open("fuelBarrelNames.txt", "w")
    for key, barrelName in pairs(fuelBarrelNames) do
        print(barrelName)
        file.writeLine(barrelName)
    end
    file.close()
end

local outputBarrels, outputBarrelsFound = getOutputBarrelNames()

local fuelBarrels, fuelBarrelsFound = getFuelBarrelNames()

writeBarrelNamesToFile(outputBarrels, fuelBarrels)
print("Saved ".. outputBarrelsFound .." output barrels and ".. fuelBarrelsFound .." fuel barrels to files.")