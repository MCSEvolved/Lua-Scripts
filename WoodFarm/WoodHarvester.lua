-- local function findWirelessModem()
--     return peripheral.find("modem", function (n,o)
--         return o.isWireless()
--     end)
-- end

local function findWirelessModem()
    local left = peripheral.wrap("left")
    if peripheral.getType(left) == "modem" then
        if left.isWireless() then
            return left
        end
    end

    local right = peripheral.wrap("right")
    if peripheral.getType(right) == "modem" then
        if right.isWireless() then
            return right
        end
    end
    
    error("Couldnt find modem")
end

local wirelessChannel = 10

local wirelessModem = findWirelessModem()

local function waitForEmptyInventory()
    while true do
        local foundItem = false
        for i=1, 16 do
            local item = turtle.getItemDetail(i)
                if item then
                    foundItem = true
                end
        end
        if not foundItem then
            return
        end
        os.sleep(0.01)
    end
    
end

local function waitForResponse()
    local timer_id = os.startTimer(5)
    print("WAITING FOR RESPONSE")
    while true do
        local event, side, channel, replyChannel, message, distance = os.pullEvent()
        if event == "modem_message" then
            if channel == wirelessChannel then
                if message.type == "TASK_RECEIVED" and message.data == os.getComputerID() then
                    print("MANAGER RECEIVED TASK")
                    return true
                end
            end
        elseif event == "timer" and side == timer_id then
            print("MANAGER NOT RESPONDING")
            return false
        end
        
    end
end




local function sendOverWireless(type, data)
    while true do
        local message = {
            type = type,
            origin = os.getComputerID(),
            data = data
        }
        print("SEND: "..textutils.serialise(message))
        wirelessModem.transmit(wirelessChannel, wirelessChannel, message)
        if waitForResponse() then
            return
        end
    end
end

local function retryMessageIfNoCompletion(type, data)
    local timer_id = os.startTimer(5)
    while true do
        local event, id = os.pullEvent("timer")
        if id == timer_id then
            sendOverWireless(type, data)
            timer_id = os.startTimer(10)
        end
    end
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
    print(amountCharcoal)
    os.sleep(5)
    if amountCharcoal > 64 then
        while amountCharcoal > 64 do
            print(amountCharcoal)
            if amountCharcoal > 64 then
                amountCharcoal = 64
            end
            sendOverWireless("REQUEST_FUEL", amountCharcoal)
            parallel.waitForAny(waitForFuel, function ()
                retryMessageIfNoCompletion("REQUEST_FUEL", amountCharcoal)
            end)
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
    parallel.waitForAny(waitForEmptyInventory, function ()
        retryMessageIfNoCompletion("EMPTY_INVENTORY")
    end)
end

local function waitForSaplings()
    local amountSaplings = 0
    while true do
        for i=1, 16 do
            local item = turtle.getItemDetail(i)
            os.sleep(0.01)
            if item and item.name == "minecraft:spruce_sapling" then
                amountSaplings = amountSaplings + item.count
                if amountSaplings > 23 then
                    amountSaplings = 0
                    return
                end
            end
        end
    end
end

local function getSaplings()
    sendOverWireless("REQUEST_SAPLINGS")
    parallel.waitForAny(waitForSaplings, function ()
        retryMessageIfNoCompletion("REQUEST_SAPLINGS")
    end)
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
    local isAtStart = success and block.name == "computercraft:wired_modem_full"
    return isAtStart
end

local function initComs()
    wirelessModem.open(wirelessChannel)
    if not wirelessModem.isOpen(wirelessChannel) then
        error("Couldn't Establish Wireless Connection")
    end
    print(wirelessModem.isOpen(wirelessChannel))
end

local function main()
    initComs()
    if isAtStart() then
        print("Is at start")
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