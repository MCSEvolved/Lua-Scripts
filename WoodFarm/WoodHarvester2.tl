require("Tracker.TrackerLib")

local Modem = require("@types.peripherals.modem")

local record Message
    type: string
    data: any
    origin: string|number
end

local function findWirelessModem(): Modem
    local left: Modem = peripheral.wrap("left") as Modem
    if peripheral.getType(left) == "modem" then
        if left.isWireless() then
            return left
        end
    end

    local right: Modem = peripheral.wrap("right") as Modem
    if peripheral.getType(right) == "modem" then
        if right.isWireless() then
            return right
        end
    end
    
    SendError("Couldnt find modem")
end

local wirelessChannel: integer = 10

local wirelessModem:Modem = findWirelessModem()

local tasklist: {Message} = {}

local isFarming: boolean = false

local function digUp()
    local _, block = turtle.inspectUp()
    if not block is string and (block.name ~= "minecraft:spruce_log" and block.name ~= "minecraft:spruce_leaves") then
        SendError("Tried to dig "..block.name as string .." while it was expecting leaves or logs", block)
    end
    turtle.digUp()
end

local function digDown()
    local _, block = turtle.inspectDown()
    if not block is string and (block.name ~= "minecraft:spruce_log" and block.name ~= "minecraft:spruce_leaves") then
        SendError("Tried to dig "..block.name as string .." while it was expecting leaves or logs", block)
    end
    turtle.digDown()
end

local function dig()
    local _, block = turtle.inspect()
    if not block is string and (block.name ~= "minecraft:spruce_log" and block.name ~= "minecraft:spruce_leaves") then
        SendError("Tried to dig "..block.name as string .." while it was expecting leaves or logs", block)
    end
    turtle.dig()
end

local function goForward(amount: number)
    if amount == nil then
        amount = 1
    end
    for i=1, amount do
        if turtle.forward() == false then
            SendDebug("Block in the way, digging...")
            dig()
            if turtle.forward() == false then
                SendError("Can't move even when I removed the block", {block = turtle.inspect()})
            end
        end
    end
end

local function goBack(amount: number)
    if amount == nil then
        amount = 1
    end
    for i=1, amount do
        if turtle.back() == false then
            SendDebug("Block in the way, digging...")
            turtle.turnLeft()
            turtle.turnLeft()
            dig()
            turtle.turnLeft()
            turtle.turnLeft()
            if turtle.back() == false then
                SendError("Can't move even when I removed the block")
            end
        end
    end
end

local function goUp(amount: number)
    if amount == nil then
        amount = 1
    end
    for i=1, amount do
        if turtle.up() == false then
            SendDebug("Block in the way, digging...")
            digUp()
            if turtle.up() == false then
                SendError("Can't move even when I removed the block", {blockUp = turtle.inspectUp()})
            end
        end
    end
end

local function goDown(amount: number)
    if amount == nil then
        amount = 1
    end
    for i=1, amount do
        if turtle.down() == false then
            SendDebug("Block in the way, digging...", true)
            digDown()
            if turtle.down() == false then
                SendError("Can't move even when I removed the block", {blockDown = turtle.inspectDown()})
            end
        end
    end
end

local function sendOverWireless(type: string, data: any)
    local message: Message = {
        type = type,
        origin = os.getComputerID(),
        data = data
    }
    SendDebug("SEND: "..message.type, message)
    wirelessModem.transmit(wirelessChannel, wirelessChannel, message as table)
end

local function selectItem(itemName: string)
    for i = 1, 16 do  
        local foundItem = turtle.getItemDetail(i)
        if not foundItem is nil and foundItem.name == itemName and foundItem.count as number > 3 then
            turtle.select(i)
            return
        end
    end
    SendError("Couldnt find saplings or not atleast four")
end

local function checkIfEnoughSaplings(): boolean
    local amount: number = 0
    for i = 1, 16 do  
        local foundItem = turtle.getItemDetail(i)
        if not foundItem is nil and foundItem.name == "minecraft:spruce_sapling" then
            amount = amount + foundItem.count as number
        end
        if amount > 23 then
            SendDebug("Found "..amount as string.." saplings", foundItem)
            return true
        end
    end
    return false
end

local function plantNewTree()
    SendDebug("Planting tree")
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
    SendDebug("Done planting tree")

end

local function harvestTree()
    digDown()
    goDown()
    dig()
    goForward()
    SendDebug("Start harvesting tree")
    while true do
        local success, block = turtle.inspect()
        if (not block is string and block.name ~= "minecraft:spruce_log") or success == false then
            break
        end
        dig()
        digUp()
        goUp()
    end
    SendDebug("Reached top, switching sides")

    dig()
    goForward()
    turtle.turnLeft()
    dig()
    goForward()
    turtle.turnLeft()

    SendDebug("Start harvesting next side")
    while true do
        dig()
        local _, block = turtle.inspectDown()
        if not block is string and (block.name == "minecraft:podzol" or block.name == "minecraft:dirt" or block.name == "minecraft:grass_block") then
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
    SendDebug("Done with tree")
end

local function farmRoutine()
    local treesHarvested: number = 0
    SetFarmingStatus()
    while true do
        local success, block = turtle.inspect()
        if not block is string and block.name == "minecraft:spruce_log" then
            treesHarvested = treesHarvested + 1
            SendDebug("Starting on tree "..treesHarvested)
            harvestTree()
            plantNewTree()
        elseif not block is string and block.name == "minecraft:spruce_leaves" then
            dig()
        elseif success then
            return
        else
            goForward()
        end
    end
end

local function returnHome()
    SendDebug("Returing back home")
    SetReturningStatus()
    local blocksWalked = 0
    goBack()
    goDown(3)
    turtle.turnLeft()
    turtle.turnLeft()
    while true do
        local _, block = turtle.inspect()
        if not block is string and block.name == "computercraft:wired_modem_full" then
            SendDebug("Found modem")
            turtle.turnLeft()
            turtle.turnLeft()
            return
        else
            goForward()
            blocksWalked = blocksWalked + 1
        end

        if blocksWalked > 70 then
            SendError("Walked more than 70 blocks to get back")
        end
    end
end

local function refuelTurtle()
    SetRefuelingStatus()
    turtle.select(1)
    SendDebug("Refueling", {fuelLevel = turtle.getFuelLevel()})
    turtle.refuel()
    SetDoneStatus()
end


local function startRun()
    isFarming = true
    if not checkIfEnoughSaplings() then
        SendError("Tried to start run without saplings")
    end
    goForward()
    goUp(3)

    farmRoutine()
    returnHome()
    sendOverWireless("DONE")
    isFarming = false
    SetWaitingStatus()
end

local function resetLocationToStart(): boolean
    SetReturningStatus()
    local harvestFase: string
    local sucUp, blockUp = turtle.inspectUp()
    if not sucUp then
        goUp()
        sucUp, blockUp = turtle.inspect()
    end
    if not blockUp is string and blockUp.name == "minecraft:spruce_log" then
        harvestFase = "HARVEST_1"
    end

    if harvestFase == nil then
        goDown()
        local sucDown, blockDown = turtle.inspectDown()
        if not blockDown is string then
            SendDebug(blockDown.name as string)
        end
        if not sucDown then
            goDown()
            sucDown, blockDown = turtle.inspectDown()
            if not blockDown is string then
                SendDebug(blockDown.name as string)
            end
        end
        if not blockDown is string and blockDown.name == "minecraft:spruce_log" then
            harvestFase = "HARVEST_2"
        end
    end

    if harvestFase == nil then
        local amountDown = 1
        while true do
            local sucDown, blockDown = turtle.inspectDown()
            if not blockDown is string then
                SendDebug(blockDown.name as string)
            end
            if not blockDown is string then
                if blockDown.name == "minecraft:spruce_sapling" then
                    return false
                elseif blockDown.name == "minecraft:podzol" or blockDown.name == "minecraft:dirt" or blockDown.name == "minecraft:grass_block" then
                    return false
                elseif blockDown.name == "minecraft:spruce_slab" or blockDown.name == "minecraft:spruce_fence_gate" or blockDown.name == "minecraft:spruce_planks" or blockDown.name == "minecraft:water" then
                    SendDebug(amountDown as string)
                    if amountDown < 3 then
                        harvestFase = "MOVING_BACK"
                        break
                    else
                        harvestFase = "MOVING"
                        break
                    end
                else
                    SendDebug("Didnt find right block", blockDown)
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
            if (not block is string and block.name ~= "minecraft:spruce_log") or success == false then
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
            local _, block = turtle.inspectDown()
            if not block is string and (block.name == "minecraft:podzol" or block.name == "minecraft:dirt" or block.name == "minecraft:grass_block") then
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
            local _, block = turtle.inspectDown()
            if not block is string and (block.name == "minecraft:podzol" or block.name == "minecraft:dirt" or block.name == "minecraft:grass_block") then
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
        local _, block = turtle.inspect()
        if not block is string then
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


local function goToStart(): boolean
    for i=1, 4 do
        local _, block = turtle.inspect()
        if not block is string and block.name == "computercraft:wired_modem_full" then
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
        local message: Message = tasklist[#tasklist]
        table.remove(tasklist, #tasklist)
        if message ~= nil then
            SendDebug("[COMMAND] "..message.type.. " FROM: "..message.origin as string, message)
            if message.type == "REFUEL" then
                refuelTurtle()
            elseif message.type == "START_RUN" then
                startRun()
            end
        else
            SendWarning("Tried to execute an empty command (nil exception)")
        end
        
    end
end

local function listenForCommands()
    while true do
        local event, side, channel, replyChannel, _message, distance = os.pullEvent("modem_message")
        local message: Message = _message as Message
        if message.data and message.data == os.getComputerID() then
            SendDebug("[RECEIVED] "..message.type.." FROM: "..message.origin as string, message)
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
                SendDebug("[RECEIVED] "..message.type.." FROM: "..message.origin as string, message)
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
        SendError("Couldn't Establish Wireless Connection")
    end
end

local function main()
    initComs()
    if goToStart() == false then
        SendError("Couldn't get to the start")
    end
    sendOverWireless("ONLINE", isFarming)
    parallel.waitForAll(listenForCommands, executeCommands)
end

InitTracker(main, 2)