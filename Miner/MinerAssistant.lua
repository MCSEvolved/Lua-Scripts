local MINER_CHANEL = 30

local function selectItem(item)
    for i = 1, 16 do
        local slot = turtle.getItemDetail(i)
        if slot and slot.name == item then
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

    while peripheral.wrap("top").getUsedItemStorage() == 0 do
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
    local charger = peripheral.wrap("front")
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

    local modem = peripheral.find("modem")
    modem.transmit(MINER_CHANEL, MINER_CHANEL, {action="docking granted"})
end

local function emptyMiner()
    local message = {}
    while message.action == "ready to dock" do
        _, _, _, _, message = os.pullEvent("modem_message")
    end

    local me = peripheral.wrap("top")

    for _, item in pairs(message.inventory) do
        if item then
            local amountImported = me.importItemFromPeripheral({name=item.name, amount=item.count}, "bottom")
            while amountImported == 0 do
                os.sleep(1)
                amountImported = me.importItemFromPeripheral({name=item.name, amount=item.count}, "bottom")
            end
        end
    end
end

local function refuel()
    local me = peripheral.wrap("top")

    local itemsPushed = 1
    while itemsPushed > 0 do
        itemsPushed = me.exportItemFromPeripheral({name="minecraft:charcoal", amount=64}, "bottom")
    end

    local modem = peripheral.find("modem")
    modem.transmit(MINER_CHANEL, MINER_CHANEL, {action="ready to refuel"})

    local message = {}
    while message.action == "refuel done" do
        _, _, _, _, message = os.pullEvent("modem_message")
    end

    itemsPushed = 1
    while itemsPushed > 0 do
        itemsPushed = me.importItemFromPeripheral({name="minecraft:charcoal", amount=64}, "bottom")
    end

    for i = 1, 16 do if turtle.getItemCount(i) == 0 then turtle.select(i) end end
    while turtle.getFuelLevel() < turtle.getFuelLimit() do
        me.exportItemFromPeripheral({name="minecraft:charcoal", amount=64}, "bottom")
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