local isTurtle = false
local function getWirelessModem()
    if turtle then
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
    else
        return peripheral.find("modem", function (n,o)
            return o.isWireless()
        end)
    end
    
end
local wirelessModem = getWirelessModem()

local function getDeviceType()
    if turtle then
        isTurtle = true
        if term.isColor() then
            return "Advanced_Turtle"
        else
            return "Turtle"
        end
    elseif pocket then
        isTurtle = false
        if term.isColor() then
            return "Advanced_Pocket_Computer"
        else
            return "Pocket_Computer"
        end
    else
        isTurtle = false
        if term.isColor() then
            return "Advanced_Computer"
        else
            return "Computer"
        end
    end
end

local isEnabled = false
local x, y, z, facing = nil, nil, nil, nil
local rotationDefined = false
local dimension = "Unknown"

local computerId = os.getComputerID()
local label = "NO_LABEL"
local device = getDeviceType()
local status = "Online"
local systemId = 0
local wirelessChannel = 40
local commandsChannel = 41



local printFunc = print
---Print a message to the screen, ability to send message as a Debug Message to the tracker
---@param content string
---@param sendAsDebug boolean | nil
print = function (content, sendAsDebug)
    if sendAsDebug == nil then
        sendAsDebug = false
    end
    local linesWritten = printFunc(content)
    if sendAsDebug then
        SendDebug(content, nil, false)
    end
    return linesWritten
end

local function sendOverWireless(type, content)
    if not wirelessModem.isOpen(wirelessChannel) then
        wirelessModem.open(wirelessChannel)
    end
    wirelessModem.transmit(wirelessChannel, wirelessChannel, {type=type, content=content})
end

local function validateMessage(message)
    return message.type and message.source and message.content and message.sourceId
end

local function sendMessage(content, messageType, metaData)
    if not wirelessModem.isOpen(wirelessChannel) then
        wirelessModem.open(wirelessChannel)
    end
    local message, source
    if isTurtle then
        source = "Turtle"
    elseif pocket then
        source = "Pocket"
    else
        source = "Computer"
    end

    if metaData ~= nil then
        metaData = {
            metaData = metaData
        }
        
        message = {
            type = messageType,
            source = source,
            content = content,
            metaData = metaData,
            sourceId = tostring(computerId)
        }
    else
        message = {
            type = messageType,
            source = source,
            content = content,
            metaData = {},
            sourceId = tostring(computerId)
        }
    end
    
    if validateMessage(message) then
        --wirelessModem.transmit(wirelessChannel,wirelessChannel,message)
        sendOverWireless("MESSAGE", message)
    else
        print("[WARNING] Invalid message: "..textutils.serialise(message))
    end
end

local function sendInfo()
    local computerLabel = os.getComputerLabel()
    --local peripherals = peripheral.getNames()
    local fuelLevel
    local fuelLimit
    if isTurtle then
        fuelLevel = turtle.getFuelLevel()
        fuelLimit = turtle.getFuelLimit()
    end
    local information = {
        Id = computerId,
        Label = computerLabel,
        SystemId = systemId,
        Status = status,
        Device = device,
        FuelLevel = fuelLevel,
        FuelLimit = fuelLimit,
        HasModem = wirelessModem ~= nil
    }
    --wirelessModem.transmit(wirelessChannel, wirelessChannel, information)
    sendOverWireless("COMPUTER", information)
end

---Send a Info Message, use these for occasional informative messages
---@param content string
---@param metaData any | nil
---@param printToTerminal boolean | nil
function SendInfo(content, metaData, printToTerminal)
    if printToTerminal == nil then
        printToTerminal = true
    end
    if printToTerminal then
        print("[INFO] "..content, false)
    end
    sendMessage(content, "Info", metaData)
end
---Send a Warning Message, use these to warn the user
---@param content string
---@param metaData any | nil
---@param printToTerminal boolean | nil
function SendWarning(content, metaData, printToTerminal)
    if printToTerminal == nil then
        printToTerminal = true
    end
    if printToTerminal then
        print("[WARNING] "..content, false)
    end
    sendMessage(content, "Warning", metaData)
end
---Send a Error Message, use these if something is seriously wrong, is automatically fired when error occurres
---@param content string
---@param metaData any | nil
---@param printToTerminal boolean | nil
function SendError(content, metaData, printToTerminal)
    if printToTerminal == nil then
        printToTerminal = true
    end
    if printToTerminal then
        print("[ERROR] "..content, false)
    end
    sendMessage(content, "Error", metaData)
end
---Send a Debug Message, use these for spam, debug and other high frequency messages. is automatically fired when print() is used
---@param content string
---@param metaData any | nil
---@param printToTerminal boolean | nil
function SendDebug(content, metaData, printToTerminal)
    if printToTerminal == nil then
        printToTerminal = true
    end
    if printToTerminal then
        print("[DEBUG] "..content, false)
    end
    sendMessage(content, "Debug", metaData)
end

---Send a OutOfFuel Message, use these for when a turtle needs the player to refuel
---@param metaData any | nil
function SendOutOfFuel(metaData)
    sendMessage("Turtle is out of fuel", "OutOfFuel", metaData)
end

local function changeStatus(_status)
    status = _status
    SendDebug("[Status] Changed to: "..status, nil, false)
    sendInfo()
end

---Set status to 'Done'
function SetDoneStatus()
    changeStatus("Done")
end
---Set status to 'Farming'
function SetFarmingStatus()
    changeStatus("Farming")
end
---Set status to 'Waiting'
function SetWaitingStatus()
    changeStatus("Waiting")
end
---Set status to 'Error'
function SetErrorStatus()
    changeStatus("Error")
end
---Set status to 'Refueling'
function SetRefuelingStatus()
    changeStatus("Refueling")
end
---Set status to 'Need Player'
function SetNeedPlayerStatus()
    changeStatus("Need Player")
end
---Set status to 'Manually Terminated'
function SetManuallyTerminatedStatus()
    changeStatus("Manually Terminated")
end
---Set status to 'Returning'
function SetReturningStatus()
    changeStatus("Returning")
end
---Set status to 'Emptying'
function SetEmptyingStatus()
    changeStatus("Emptying")
end
---Set status to 'Stopped'
function SetStoppedStatus()
    changeStatus("Stopped")
end
---Set status to 'Rebooting'
function SetRebootingStatus()
    changeStatus("Rebooting")
end
---Set a custom status, please capitalize the first letter of each word
---@param customStatus string
function SetCustomStatus(customStatus)
    changeStatus(customStatus)
end
local test = 0
local function sendLocation()
    local location = {
        computerId = computerId,
        coordinates = {
            x = x,
            y = y,
            z = z,
        },
        dimension = dimension
    }
    sendOverWireless("LOCATION", location)
end

local function defineRotation()
    if isEnabled then
        local newX, _, newZ = gps.locate()
        local difX = x - newX
        local difZ = z - newZ
        if difX == -1 then
            facing = 2
        elseif difX == 1 then
            facing = 4
        elseif difZ == -1 then
            facing = 3
        elseif difZ == 1 then
            facing = 1
        else
            error("Can't define Rotation")
        end
        rotationDefined = true
    end
    
end

if isTurtle then

    local turtleTurnRight = turtle.turnRight
    turtle.turnRight = function ()
        local success = turtleTurnRight()
        if success and rotationDefined then
            facing = facing + 1
            if facing == 5 then
                facing = 1
            end
        end
        return success
    end

    local turtleTurnLeft = turtle.turnLeft
    turtle.turnLeft = function ()
        local success = turtleTurnLeft()
        if success and rotationDefined then
            facing = facing - 1
            if facing == 0 then
                facing = 4
            end
        end
        return success
    end

    local turtleForward = turtle.forward
    turtle.forward = function ()
        local success = turtleForward()
        if success and not rotationDefined then
            defineRotation()
        end
        if success and rotationDefined then
            if facing == 1 then
                z = z - 1
            elseif facing == 2 then
                x = x + 1
            elseif facing == 3 then
                z = z + 1
            elseif facing == 4 then
                x = x - 1
            else
                error("Don't know what direction turtle is facing")
            end
        end
        sendLocation()
        return success
    end


    local turtleBack= turtle.back
    turtle.back = function ()
        local success = turtleBack()
        if success and not rotationDefined then
            defineRotation()
        end
        if success and rotationDefined then
            if facing == 1 then
                z = z + 1
            elseif facing == 2 then
                x = x - 1
            elseif facing == 3 then
                z = z - 1
            elseif facing == 4 then
                x = x + 1
            else
                error("Don't know what direction turtle is facing")
            end
        end
        sendLocation()
        return success
    end


    local turtleUp= turtle.up
    turtle.up = function ()
        local success = turtleUp()
        if success then
            y = y + 1
        end
        sendLocation()
        return success
    end



    local turtleDown= turtle.down
    turtle.down = function ()
        local success = turtleDown()
        if success then
            y = y - 1
        end
        sendLocation()
        return success
    end
end


local function listenForCommands()
    while true do
        local _, _, channel, replyChannel, message, _ = os.pullEvent("modem_message")
        if channel == commandsChannel then
            print(textutils.serialise(message))
            if message.computerId and message.computerId == os.getComputerID() and message.command then
                print("Received command "..message.command, true)
                if message.command == "STOP" then
                    error("TRACKER_STOP")
                elseif message.command == "REBOOT" then
                    error("TRACKER_REBOOT")
                end
            end
        end
    end
end




local function initInfo()
    while true do
        sendInfo()
        os.sleep(1)
    end
end



local function initLocation()
    x, y, z = gps.locate()
    SendDebug("Starting location", {x=x, y=y, z=z})
    sendLocation()
end


local function initComputerInfo(_systemId)
    label = os.getComputerLabel()
    device = getDeviceType()
    if _systemId ~= nil then
        systemId = _systemId
    end
end

local function initModemCommunication()
    if wirelessModem then
        wirelessModem.open(wirelessChannel)
        wirelessModem.open(commandsChannel)
        SendDebug("Wireless channel opened on channel: "..wirelessChannel.." & "..commandsChannel)
    else
        print("[ERROR] No Wireless Modem detected, tracker won't work without it.", true)
        error("Missing Wireless Modem")
    end
end



local function bind(f)
    return function()
        local success, err = pcall(f)
        if not success then
            sendLocation()
            sendInfo()
            if string.find(err, "Terminated") then
                SetManuallyTerminatedStatus()
                SendDebug("Turtle has been manually terminated")
                error(err)
            elseif string.find(err, "TRACKER_STOP") then
                SetStoppedStatus()
                SendDebug("Turtle has been stopped")
            elseif string.find(err, "TRACKER_REBOOT")  then
                SetRebootingStatus()
                SendDebug("Turtle is rebooting")
                os.reboot()
            else
                SendError(err)
                SetErrorStatus()
            end
        end
    end
end

local function enterCrashedState()
    parallel.waitForAny(bind(listenForCommands), bind(initInfo))
end


function InitTracker(main, _systemId)
    isEnabled = true
    initComputerInfo(_systemId)
    initModemCommunication()
    if isTurtle then
        initLocation()
    end

    SendDebug("Turtle has started up and is online")
    parallel.waitForAny(bind(main), bind(initInfo), bind(listenForCommands))
    enterCrashedState()
end


