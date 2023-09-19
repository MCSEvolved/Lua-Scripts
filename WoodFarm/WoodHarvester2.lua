require("Tracker.OldTrackerLib")

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

local tasklist = {}

local isFarming = false

local function digUp()
    local succes, block = turtle.inspectUp()
    if succes and (block.name ~= "minecraft:spruce_log" and block.name ~= "minecraft:spruce_leaves") then
        error("Tried to dig "..block.name .." while it was expecting leaves or logs")
    end
    turtle.digUp()
end

local function digDown()
    local succes, block = turtle.inspectDown()
    if succes and (block.name ~= "minecraft:spruce_log" and block.name ~= "minecraft:spruce_leaves") then
        error("Tried to dig "..block.name .." while it was expecting leaves or logs")
    end
    turtle.digDown()
end

local function dig()
    local succes, block = turtle.inspect()
    if succes and (block.name ~= "minecraft:spruce_log" and block.name ~= "minecraft:spruce_leaves") then
        error("Tried to dig "..block.name .." while it was expecting leaves or logs")
    end
    turtle.dig()
end

local function goForward(amount)
    if amount == nil then
        amount = 1
    end
    for i=1, amount do
        if turtle.forward() == false then
            print("Block in the way, digging...", true)
            dig()
            if turtle.forward() == false then
                error("Can't move even when I removed the block")
            end
        end
    end
end

local function goBack(amount)
    if amount == nil then
        amount = 1
    end
    for i=1, amount do
        if turtle.back() == false then
            print("Block in the way, digging...", true)
            turtle.turnLeft()
            turtle.turnLeft()
            dig()
            turtle.turnLeft()
            turtle.turnLeft()
            if turtle.back() == false then
                error("Can't move even when I removed the block")
            end
        end
    end
end

local function goUp(amount)
    if amount == nil then
        amount = 1
    end
    for i=1, amount do
        if turtle.up() == false then
            print("Block in the way, digging...", true)
            digUp()
            if turtle.up() == false then
                error("Can't move even when I removed the block")
            end
        end
    end
end

local function goDown(amount)
    if amount == nil then
        amount = 1
    end
    for i=1, amount do
        if turtle.down() == false then
            print("Block in the way, digging...", true)
            digDown()
            if turtle.down() == false then
                error("Can't move even when I removed the block")
            end
        end
    end
end

local function sendOverWireless(type, data)
    local message = {
        type = type,
        origin = os.getComputerID(),
        data = data
    }
    print("SEND: "..textutils.serialise(message), true)
    wirelessModem.transmit(wirelessChannel, wirelessChannel, message)
end

local function selectItem(itemName)
    for i = 1, 16 do  
        local foundItem = turtle.getItemDetail(i)
        if foundItem and foundItem.name == itemName and foundItem.count > 3 then
            turtle.select(i)
            return
        end
    end
    error("Couldnt find saplings or not atleast four")
end

local function checkIfEnoughSaplings()
    local amount = 0
    for i = 1, 16 do  
        local foundItem = turtle.getItemDetail(i)
        if foundItem and foundItem.name == "minecraft:spruce_sapling" then
            amount = amount + foundItem.count
        end
        if amount > 23 then
            return true
        end
    end
    return false
end

local function plantNewTree()
    selectItem("minecraft:spruce_sapling")
    goBack()
    turtle.suckDown()
    turtle.placeDown()
    goBack()
    turtle.suckDown()
    turtle.placeDown()
    turtle.turnLeft()
    goForward()
    turtle.suckDown()
    turtle.placeDown()
    turtle.turnRight()
    goForward()
    turtle.suckDown()
    turtle.placeDown()
    turtle.turnRight()
    goForward()
    turtle.turnLeft()

end

local function harvestTree()
    digDown()
    goDown()
    dig()
    goForward()
    while true do
        local success, block = turtle.inspect()
        if (success and block.name ~= "minecraft:spruce_log") or success == false then
            break
        end
        dig()
        digUp()
        goUp()
    end

    dig()
    goForward()
    turtle.turnLeft()
    dig()
    goForward()
    turtle.turnLeft()

    while true do
        dig()
        local success, block = turtle.inspectDown()
        if success and (block.name == "minecraft:podzol" or block.name == "minecraft:dirt" or block.name == "minecraft:grass_block") then
            break
        end
        digDown()
        goDown()
    end
    turtle.turnLeft()
    goForward()
    turtle.turnLeft()
    dig()
    goForward()
    digUp()
    goUp()
end

local function farmRoutine()
    SetFarmingStatus()
    while true do
        local success, block = turtle.inspect()
        if success and block.name == "minecraft:spruce_log" then
            harvestTree()
            plantNewTree()
        elseif success and block.name == "minecraft:spruce_leaves" then
            dig()
        elseif success then
            return
        else
            goForward()
        end
    end
end

local function returnHome()
    SetReturningStatus()
    local blocksWalked = 0
    goBack()
    goDown(3)
    turtle.turnLeft()
    turtle.turnLeft()
    while true do
        local success, block = turtle.inspect()
        if success and block.name == "computercraft:wired_modem_full" then
            turtle.turnLeft()
            turtle.turnLeft()
            return
        else
            goForward()
            blocksWalked = blocksWalked + 1
        end

        if blocksWalked > 70 then
            error("Walked more than 70 blocks to get back")
        end
    end
end

local function refuelTurtle()
    SetRefuelingStatus()
    turtle.select(1)
    print("REFUEL", true)
    turtle.refuel()
    SetDoneStatus()
end


local function startRun()
    SetFarmingStatus()
    isFarming = true
    if not checkIfEnoughSaplings() then
        error("Tried to start run without saplings")
    end
    goForward()
    goUp(3)

    farmRoutine()
    returnHome()
    sendOverWireless("DONE")
    isFarming = false
    SetWaitingStatus()
end

local function resetLocationToStart()
    SetReturningStatus()
    local harvestFase
    local sucUp, blockUp = turtle.inspectUp()
    if not sucUp then
        goUp()
        sucUp, blockUp = turtle.inspect()
    end
    if sucUp and blockUp.name == "minecraft:spruce_log" then
        harvestFase = "HARVEST_1"
    end

    if harvestFase == nil then
        goDown()
        local sucDown, blockDown = turtle.inspectDown()
        print(blockDown.name)
        if not sucDown then
            goDown()
            sucDown, blockDown = turtle.inspectDown()
            print(blockDown.name)
        end
        if sucDown and blockDown.name == "minecraft:spruce_log" then
            harvestFase = "HARVEST_2"
        end
    end

    if harvestFase == nil then
        local amountDown = 1
        while true do
            local sucDown, blockDown = turtle.inspectDown()
            print(blockDown.name)
            if sucDown then
                if blockDown.name == "minecraft:spruce_sapling" then
                    return false
                elseif blockDown.name == "minecraft:podzol" or blockDown.name == "minecraft:dirt" or blockDown.name == "minecraft:grass_block" then
                    return false
                elseif blockDown.name == "minecraft:spruce_slab" or blockDown.name == "minecraft:spruce_fence_gate" or blockDown.name == "minecraft:spruce_planks" or blockDown.name == "minecraft:water" then
                    print(amountDown)
                    if amountDown < 3 then
                        harvestFase = "MOVING_BACK"
                        break
                    else
                        harvestFase = "MOVING"
                        break
                    end
                else
                    print("didnt find right block", true)
                    return false
                end
            else
                goDown()
                amountDown = amountDown + 1
            end
        end
    end

    SendDebug(harvestFase)

    if harvestFase == "HARVEST_1" then
        dig()
        digUp()
        goUp()
        while true do
            local success, block = turtle.inspect()
            if (success and block.name ~= "minecraft:spruce_log") or success == false then
                break
            end
            dig()
            digUp()
            goUp()
        end

        dig()
        goForward()
        turtle.turnLeft()
        dig()
        goForward()
        turtle.turnLeft()

        while true do
            dig()
            local success, block = turtle.inspectDown()
            if success and (block.name == "minecraft:podzol" or block.name == "minecraft:dirt" or block.name == "minecraft:grass_block") then
                break
            end
            digDown()
            goDown()
        end
        turtle.turnLeft()
        goForward()
        turtle.turnLeft()
        dig()
        goForward()
        digUp()
        goUp()

        plantNewTree()
        goForward()
        goDown(3)
        turtle.turnLeft()
        turtle.turnLeft()
    elseif harvestFase == "HARVEST_2" then
        dig()
        digDown()
        goDown()
        while true do
            dig()
            local success, block = turtle.inspectDown()
            if success and (block.name == "minecraft:podzol" or block.name == "minecraft:dirt" or block.name == "minecraft:grass_block") then
                break
            end
            digDown()
            goDown()
        end
        turtle.turnLeft()
        goForward()
        turtle.turnLeft()
        dig()
        goForward()
        digUp()
        goUp()

        plantNewTree()
        goForward()
        goDown(3)
        turtle.turnLeft()
        turtle.turnLeft()
    elseif harvestFase == "MOVING" then
        turtle.turnLeft()
        turtle.turnLeft()
    elseif harvestFase == "MOVING_BACK" then
        os.sleep(0.001)
    else
        return false
    end


    while true do
        local succes, block = turtle.inspect()
        if succes then
            for i=1, 3 do
                if block.name == "computercraft:wired_modem_full" then
                    turtle.turnLeft()
                    turtle.turnLeft()
                    return true
                end
                goUp()
                turtle.forward()
            end
            return false
        end
        goForward()
    end

    
   return false
end


local function goToStart()
    for i=1, 4 do
        local success, block = turtle.inspect()
        if success and block.name == "computercraft:wired_modem_full" then
            turtle.turnLeft()
            turtle.turnLeft()
            return true
        end
        turtle.turnLeft()
    end

    SendInfo("Not at starting position, returning...")

    -- big return script
    return resetLocationToStart()
end




local function executeCommands()
    while true do
        if #tasklist < 1 then
            os.pullEvent("task_added")
        end
        local message = tasklist[#tasklist]
        table.remove(tasklist, #tasklist)
        if message ~= nil then
            print("[COMMAND] "..message.type.. " FROM: "..message.origin, true)
            if message.type == "REFUEL" then
                refuelTurtle()
            elseif message.type == "START_RUN" then
                startRun()
            end
        else
            SendWarning("[WARNING] Tried to execute an empty command (nil exception)")
        end
        
    end
end

local function listenForCommands()
    while true do
        local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
        if message.data and message.data == os.getComputerID() then
            print("[RECEIVED] "..message.type.." FROM: "..message.origin, true)
            if message.type == "START_RUN" then
                if not isFarming then
                    table.insert(tasklist, 1, message)
                    os.queueEvent("task_added")
                end
            elseif message.type == "REFUEL" then
                table.insert(tasklist, 1, message)
                os.queueEvent("task_added")
            end
        else
            if message.type == "IS_ONLINE" then
                print("[RECEIVED] "..message.type.." FROM: "..message.origin, true)
                sendOverWireless("ONLINE", isFarming)
            elseif message.type == "REBOOT" then
                os.reboot()
            end
        end
    end
end


local function initComs()
    wirelessModem.open(wirelessChannel)
    if not wirelessModem.isOpen(wirelessChannel) then
        error("Couldn't Establish Wireless Connection")
    end
end

local function main()
    initComs()
    if goToStart() == false then
        error("Couldn't get to the start")
    end
    sendOverWireless("ONLINE", isFarming)
    parallel.waitForAll(listenForCommands, executeCommands)
end

InitTracker(main, 2)