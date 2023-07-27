--------TYPES-------------------------------------------
local CraftItem = require("@types.shared.CraftItem")
local MEBridge = require("@types.peripherals.me_bridge")
local EnergyStorage = require("@types.peripherals.energy_storage")
local Modem = require("@types.peripherals.modem")
local messages = require("Miner.@types.messages")
local ActionMessage = messages[2]
local InventoryMessage = messages[3]
---------END--------------------------------------------


local MINER_CHANEL = 30

local function selectItem(item: string)
    for i = 1, 16 do
        local slot = turtle.getItemDetail(i)
        if not slot is nil and slot.name == item then
            turtle.select(i)
            return
        end
    end
end

local function buildRing()
    selectItem("ae2:quantum_ring")
    turtle.place()
    turtle.turnLeft()
    turtle.turnLeft()
    turtle.place()
    turtle.down()
    turtle.placeUp()
    turtle.place()
    turtle.turnLeft()
    turtle.turnLeft()
    turtle.place()
    turtle.down()
    turtle.place()
    turtle.turnLeft()
    selectItem("ae2:fluix_glass_cable")
    turtle.place()
    turtle.turnLeft()
    selectItem("ae2:quantum_ring")
    turtle.place()
    selectItem("ae2:quantum_link")
    turtle.placeUp()
    selectItem("ae2:quantum_entangled_singularity")
    turtle.dropUp()
    turtle.down()
    selectItem("ae2:quantum_ring")
    turtle.turnRight()
    selectItem("ae2:fluix_glass_cable")
    turtle.place()
    selectItem("ae2:quantum_ring")
    turtle.placeUp()
    turtle.down()
    selectItem("advancedperipherals:me_bridge")
    turtle.placeUp()
    selectItem("ae2:dense_energy_cell")
    turtle.place()

    local meBridge = peripheral.wrap("top") as MEBridge
    while meBridge.getUsedItemStorage() == 0 do
        os.sleep(1)
    end

    selectItem("minecraft:diamond_pickaxe")
    turtle.equipLeft()
    turtle.dig()
    selectItem("computercraft:ender_modem")
    turtle.equipLeft()
    selectItem("ae2:charger")
    turtle.place()
    selectItem("ae2:dense_energy_cell")
    turtle.drop()
end

local function breakRing()
    local charger = peripheral.wrap("front") as EnergyStorage
    while charger.getEnergy() < charger.getEnergyCapacity() do
        os.sleep(1)
    end
    selectItem("minecraft:diamond_pickaxe")
    turtle.equipLeft()
    turtle.dig()
    turtle.digUp()
    turtle.up()
    turtle.dig()
    turtle.digUp()
    turtle.up()
    turtle.dig()
    turtle.turnLeft()
    turtle.dig()
    turtle.turnLeft()
    turtle.turnLeft()
    turtle.dig()
    turtle.digUp()
    turtle.up()
    turtle.dig()
    turtle.turnLeft()
    turtle.turnLeft()
    turtle.dig()
    turtle.digUp()
    turtle.up()
    turtle.dig()
    turtle.turnLeft()
    turtle.turnLeft()
    turtle.dig()
    selectItem("computercraft:ender_modem")
    turtle.equipLeft()

    local modem = peripheral.find("modem") as Modem
    modem.transmit(MINER_CHANEL, MINER_CHANEL, {action="docking granted"})
end

local function emptyMiner()
    local message: any
    while not message is InventoryMessage or message.action ~= "ready to dock" do
        local _: any
        _, _, _, _, message = os.pullEvent("modem_message")
    end

    if not message is InventoryMessage then return end

    local me = peripheral.wrap("top") as MEBridge

    for _, item in ipairs(message.inventory) do
        if item then
            if item is CraftItem then
                local amountImported = me.importItemFromPeripheral({name=item.name, count=item.count}, "bottom")
                while amountImported == 0 do
                    os.sleep(1)
                    amountImported = me.importItemFromPeripheral({name=item.name, count=item.count}, "bottom")
                end
            end
        end
    end
end

local function refuel()
    local me = peripheral.wrap("top") as MEBridge

    local itemsPushed = 1.0
    while itemsPushed > 0 do
        itemsPushed = me.exportItemToPeripheral({name="minecraft:charcoal", count=64}, "bottom")
    end

    local modem = peripheral.find("modem") as Modem
    modem.transmit(MINER_CHANEL, MINER_CHANEL, {action="ready to refuel"})

    local message: any
    while not message is ActionMessage or message.action ~= "refuel done" do
        local _: any
        _, _, _, _, message = os.pullEvent("modem_message")
    end

    itemsPushed = 1
    while itemsPushed > 0 do
        itemsPushed = me.importItemFromPeripheral({name="minecraft:charcoal", count=64}, "bottom")
    end

    for i = 1, 16 do if turtle.getItemCount(i) == 0 then turtle.select(i) end end
    while turtle.getFuelLevel() < turtle.getFuelLimit() do
        me.exportItemToPeripheral({name="minecraft:charcoal", count=64}, "bottom")
        turtle.suckDown()
        turtle.refuel()
    end
end

local function dock()
    buildRing()
    -- emptyMiner()
    -- refuel()
    breakRing()
end

dock()