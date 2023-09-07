--------TYPES-------------------------------------------
local CraftItem = require("@types.shared.CraftItem")
local MEBridge = require("@types.peripherals.me_bridge")
local EnergyStorage = require("@types.peripherals.energy_storage")
local Modem = require("@types.peripherals.modem")
local messages = require("Miner.@types.messages")
local ActionMessage = messages[2]
local InventoryMessage = messages[3]
local MovementMessage = messages[4]
---------END--------------------------------------------


local MINER_CHANNEL = 30

local function fail(msg: string, additionalData: any)
    local modem = peripheral.find("modem") as Modem
    modem.transmit(MINER_CHANNEL, MINER_CHANNEL, {action="error", error=msg})
    error(msg .. '\n' .. textutils.serialise(additionalData))
end

local function setInitData(data: string)
    local file = io.open("initData", 'w')
    if not file is nil then
        local _, err = file:write(data)
        if err then fail("Failed to write initData", err) end
    else
        fail("Failed to open initData")
    end
end

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
    peripheral.call("left", "open", MINER_CHANNEL)
    selectItem("ae2:charger")
    turtle.place()
    selectItem("ae2:dense_energy_cell")
    turtle.drop()

    local modem = peripheral.find("modem") as Modem
    modem.transmit(MINER_CHANNEL, MINER_CHANNEL, {action="docking granted"})
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
    peripheral.call("left", "open", MINER_CHANNEL)

    local modem = peripheral.find("modem") as Modem
    modem.transmit(MINER_CHANNEL, MINER_CHANNEL, {action="docking done"})
end

local function emptyMiner()
    local message: InventoryMessage
    while true do
        local _, _, _, _, messageTmp = os.pullEvent("modem_message")
        if messageTmp is InventoryMessage and messageTmp.action == "ready to dock" then
            message = messageTmp
            break
        end
    end

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
    modem.transmit(MINER_CHANNEL, MINER_CHANNEL, {action="ready to refuel"})

    local message: ActionMessage
    while true do
        local _, _, _, _, messageTmp = os.pullEvent("modem_message")
        if messageTmp is ActionMessage and messageTmp.action == "refuel done" then
            message = messageTmp
            break
        end
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
    setInitData("docking start")
    buildRing()
    emptyMiner()
    refuel()
    setInitData("docking end")
    breakRing()
end

local function main()
    local message: MovementMessage
    while true do
        local _, _, _, _, messageTmp = os.pullEvent("modem_message")
        if messageTmp is ActionMessage and (messageTmp.action == "request docking") then dock()
        elseif messageTmp is MovementMessage and (messageTmp.action == "move" or messageTmp.action == "turn") then
            message = messageTmp
            break
        end
    end

    if message.action == "turn" then
        if message.direction == "left" then turtle.turnLeft()
        elseif message.direction == "right" then turtle.turnRight()
        else fail("invalid direction", message.direction) end
    elseif message.action == "move" then
        if message.direction == "forward" then turtle.forward()
        elseif message.direction == "back" then turtle.back()
        else fail("invalid direction", message.direction) end
    end

    -- perform a check to see if the turtle locations are still synced
    local x, _, z = gps.locate()
    if x ~= message.location.x or z ~= message.location.z then
        fail("Position mismatch", message.location)
    end
end

local function resetDocking()
    local modem = peripheral.find("modem") as Modem
    modem.transmit(MINER_CHANNEL, MINER_CHANNEL, {action="reset docking"})

    selectItem("minecraft:diamond_pickaxe")
    turtle.equipLeft()

    for y = 0, 5 do
        for turn = 1, 4 do
            turtle.dig()
            turtle.turnLeft()
        end
        local count = 0
        for i = 1, 16 do
            local detail = turtle.getItemDetail(i)
            if not detail is nil and detail.name == "ae2:quantum_ring" then
                count = count + detail.count as integer
            end
        end
        if count == 8 then break
        else turtle.up() end
    end

    selectItem("computercraft:ender_modem")
    turtle.equipLeft()
    peripheral.call("left", "open", MINER_CHANNEL)
end

local function init()
    local file = io.open("initData", 'r')
    if not file is nil then
        local status = file:read()
        if status == "following" then
            local modem = peripheral.find("modem") as Modem
            modem.transmit(MINER_CHANNEL, MINER_CHANNEL, {action="start follow"})
        elseif status == "docking start" then
            resetDocking()
            dock()
        elseif status == "docking end" then
            resetDocking()
            local modem = peripheral.find("modem") as Modem
            modem.transmit(MINER_CHANNEL, MINER_CHANNEL, {action="docking done"})
        else fail("Invalid initData") end
    else
        fail("Failed to open initData")
    end
end

local function waitForFailure()
    while true do
        local _,_,_,_, message = os.pullEvent("modem_message")
        if message is ActionMessage and message.action == "error" then
            print("Miner failed")
            break
        end
    end
end

parallel.waitForAny(waitForFailure, function()
    init()
    while true do
        main()
    end
end)


