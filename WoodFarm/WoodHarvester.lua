local function findWirelessModem()
    return peripheral.find("modem", function (n,o)
        return o.isWireless()
    end)
end

local wirelessChannel = 10

local wirelessModem = findWirelessModem()

local function isInventoryEmpty()
    for i=1, 16 do
        local item = turtle.getItemDetail(i)
            if item  then
                return false
            end
    end
    return true
end

local function sendOverWireless(type, data)
    local message = {
        type = type,
        origin = os.getComputerID(),
        data = data
    }
    --print("SEND: "..textutils.serialise(message))

    wirelessModem.transmit(wirelessChannel, wirelessChannel, message)
end

local function waitForFuel()
    while true do
        for i=1, 16 do
            local item = turtle.getItemDetail(i)
            if item and item.name == "minecraft:charcoal" then
                return
            end
        end 
        os.sleep(0.01)
    end
end

local function refuel()
    local amountCharcoal = math.floor((turtle.getFuelLimit() - turtle.getFuelLevel())/80)
    while amountCharcoal > 0 do
        print(amountCharcoal)
        if amountCharcoal > 64 then
            amountCharcoal = 64
        end
        sendOverWireless("REQUEST_FUEL", amountCharcoal)  
        waitForFuel()      
        for i=1, 16, 1 do
            local item = turtle.getItemDetail(i)
            if item then
                turtle.select(i)
                turtle.refuel()
                print(turtle.getFuelLevel())
            end
        end
        amountCharcoal = math.floor((turtle.getFuelLimit() - turtle.getFuelLevel())/80)
    end

    return

end

local function selectItem(itemName)
    for i = 1, 16 do  
        local foundItem = turtle.getItemDetail(i)
        if foundItem and foundItem.name == itemName and foundItem.count > 3 then
            turtle.select(i)
            return
        end
    end
    error("Not Enough Saplings Left")
end

local function emptyInventory()
    sendOverWireless("EMPTY_INVENTORY")
    while not isInventoryEmpty() do
        os.sleep(0.01)
    end
end

local function getSaplings()
    sendOverWireless("REQUEST_SAPLINGS")
    local amountSaplings = 0
    while true do
        for i=1, 16 do
            local item = turtle.getItemDetail(i)
            os.sleep(0.01)
            if item and item.name == "minecraft:spruce_sapling" then
                amountSaplings = amountSaplings + item.count
                if amountSaplings > 23 then
                    --sendOverWireless("ACTION_DONE", nil)
                    amountSaplings = 0
                    print("DONE SAPLINGS")
                    return
                end
            end
        end
    end
end

local function returnHome()
    turtle.back()
    turtle.down()
    turtle.down()
    turtle.down()
    turtle.turnLeft()
    turtle.turnLeft()
    while true do
        if turtle.forward() == false then
            local success, block = turtle.inspect()
            if success and block.name == "minecraft:spruce_leaves" then
                turtle.dig()
            elseif success and block.name == "computercraft:wired_modem_full" then
                turtle.turnLeft()
                turtle.turnLeft()
                return
            else
                error("Turtle is obstructed when going home")
            end
        end
    end
end

local function goToStart()
    turtle.forward()
    turtle.up()
    turtle.up()
    turtle.up()
end

local function plantNewTree()
    selectItem("minecraft:spruce_sapling")
    turtle.back()
    turtle.suckDown()
    turtle.placeDown()
    turtle.back()
    turtle.suckDown()
    turtle.placeDown()
    turtle.turnLeft()
    turtle.forward()
    turtle.suckDown()
    turtle.placeDown()
    turtle.turnRight()
    turtle.forward()
    turtle.suckDown()
    turtle.placeDown()
    turtle.turnRight()
    turtle.forward()
    turtle.turnLeft()

end

local function harvestTree()
    turtle.digDown()
    turtle.down()
    turtle.dig()
    turtle.forward()
    while true do
        local success, block = turtle.inspect()
        if (success and block.name ~= "minecraft:spruce_log") or success == false then
            break
        end
        turtle.dig()
        turtle.digUp()
        turtle.up()
    end

    turtle.dig()
    turtle.forward()
    turtle.turnLeft()
    turtle.dig()
    turtle.forward()
    turtle.turnLeft()

    while true do
        turtle.dig()
        local success, block = turtle.inspectDown()
        if success and (block.name == "minecraft:podzol" or block.name == "minecraft:dirt" or block.name == "minecraft:grass_block") then
            break
        end
        turtle.digDown()
        turtle.down()
    end
    turtle.turnLeft()
    turtle.forward()
    turtle.turnLeft()
    turtle.dig()
    turtle.forward()
    turtle.digUp()
    turtle.up()
end

local function farmRoutine()
    goToStart()
    while true do
        if turtle.forward() == false then
            local success, block = turtle.inspect()
            if success and block.name == "minecraft:spruce_log" then
                harvestTree()
                plantNewTree()
            elseif success and block.name == "minecraft:spruce_leaves" then
                turtle.dig()
            else
                return
            end
        end
    end
end

local function listenForStartMessage()
    sendOverWireless("STANDBY", nil)
    while true do
        local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
        if channel == wirelessChannel then
            if message.type == "START_RUN" and message.data == os.getComputerID() then
                print("START RUN RECEIVED")
                farmRoutine()
                return
            end
        end
        
    end
end

local function isAtStart()
    turtle.turnLeft()
    turtle.turnLeft()
    local success, block = turtle.inspect()
        turtle.turnLeft()
        turtle.turnLeft()
    return success and block.name == "computercraft:wired_modem_full"
end

local function initComs()
    wirelessModem.open(wirelessChannel)
    if not wirelessModem.isOpen(wirelessChannel) then
        error("Couldn't Establish Wireless Connection")
    end
end

local function main()
    initComs()
    if isAtStart() then
        while true do
            emptyInventory()
            refuel()
            getSaplings()
            listenForStartMessage()
            returnHome()
            emptyInventory()
        end
    else
        error("Not at starting positition on start-up")
    end
end

main()