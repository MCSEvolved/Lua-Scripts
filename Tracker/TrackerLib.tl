--------TYPES-------------------------------------------
local Modem = require("@types.peripherals.modem")
local Coordinates = require("@types.shared.Location")
local tealTypes = require("Tracker.@types.types")
local Message = tealTypes[1]
local MessageType = tealTypes[2]
local MessageSource = tealTypes[3]
local Information = tealTypes[4]
local ComputerDevice = tealTypes[5]
local TrackerMessageType = tealTypes[6]
local Location = tealTypes[7]
local Dimension = tealTypes[8]
local Command = tealTypes[9]
local CommandAction = tealTypes[10]
-------END----------------------------------------------



local isTurtle: boolean = false
local crashedState: boolean = false

local function getWirelessModem(): Modem|nil
    if turtle then
        local left = peripheral.wrap("left") as Modem
        if peripheral.getType(left) == "modem" then
            if left.isWireless() then
                return left
            end
        end
    
        local right = peripheral.wrap("right") as Modem
        if peripheral.getType(right) == "modem" then
            if right.isWireless() then
                return right
            end
        end
    else
        return peripheral.find("modem", function(_n: string, o: Modem): boolean
        return o.isWireless()
    end) as Modem
    end
    
end
local wirelessModem: Modem = getWirelessModem()

local function getDeviceType(): ComputerDevice
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

local isEnabled: boolean = false
local x, y, z, facing: integer, integer, integer, integer = nil, nil, nil, nil
local rotationDefined: boolean = false
local dimension: Dimension = "Unknown"

local computerId: integer = os.getComputerID()
local label: string = "NO_LABEL"
local device: ComputerDevice = getDeviceType()
local status: string = "Online"
local systemId: integer = 0
local wirelessChannel: integer = 40
local commandsChannel: integer = 41



local function sendOverWireless(messageType: TrackerMessageType, content: any)
    if not wirelessModem.isOpen(wirelessChannel) then
        wirelessModem.open(wirelessChannel)
    end
    wirelessModem.transmit(wirelessChannel, wirelessChannel, {type=messageType, content=content})
end

local function validateMessage(message: Message): boolean
    return message.messageType ~= nil and message.messageSource ~= nil and message.content ~= nil and message.sourceId ~= nil
end

local function sendMessage(content: string, messageType: MessageType, metaData: any|nil)
    if not wirelessModem.isOpen(wirelessChannel) then
        wirelessModem.open(wirelessChannel)
    end
    local message, source: Message, MessageSource
    if isTurtle then
        source = "Turtle"
    elseif pocket then
        source = "Pocket"
    else
        source = "Computer"
    end

    if metaData ~= nil then
        metaData = {
            metadata = metaData
        }
        
        message = {
            messageType = messageType,
            messageSource = source,
            content = content,
            metadata = metaData,
            sourceId = tostring(computerId)
        }
    else
        message = {
            messageType = messageType,
            messageSource = source,
            content = content,
            metadata = {},
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
    local fuelLevel: number
    local fuelLimit: number
    if isTurtle then
        fuelLevel = turtle.getFuelLevel()
        fuelLimit = turtle.getFuelLimit()
    end
    local information: Information = {
        id = computerId,
        label = computerLabel,
        systemId = systemId,
        status = status,
        device = device,
        fuelLevel = fuelLevel,
        fuelLimit = fuelLimit,
        hasModem = wirelessModem ~= nil
    }
    --wirelessModem.transmit(wirelessChannel, wirelessChannel, information)
    sendOverWireless("COMPUTER", information)
end

---Send a Info Message, use these for occasional informative messages
---@param content string
---@param metaData any | nil
---@param printToTerminal boolean | nil
global function SendInfo(content: string, metaData: any|nil, printToTerminal: boolean)
    if printToTerminal == nil then
        printToTerminal = true
    end
    if printToTerminal then
        term.setTextColor(colors.green)
        print("[INFO] "..content)
        term.setTextColor(colors.white)
    end
    sendMessage(content, "Info", metaData)
end
---Send a Warning Message, use these to warn the user
---@param content string
---@param metaData any | nil
---@param printToTerminal boolean | nil
global function SendWarning(content: string, metaData: any|nil, printToTerminal: boolean)
    if printToTerminal == nil then
        printToTerminal = true
    end
    if printToTerminal then
        term.setTextColor(colors.yellow)
        print("[WARNING] "..content)
        term.setTextColor(colors.white)
    end
    sendMessage(content, "Warning", metaData)
end
---Send a Error Message, use these if something is seriously wrong, is automatically fired when error occurres
---@param content string
---@param metaData any | nil
---@param printToTerminal boolean | nil
global function SendError(content: string, metaData: any|nil, printToTerminal: boolean)
    if printToTerminal == nil then
        printToTerminal = true
    end
    if printToTerminal then
        term.setTextColor(colors.red)
        print("[ERROR] "..content)
        term.setTextColor(colors.white)
    end
    sendMessage(content, "Error", metaData)
end
---Send a Debug Message, use these for spam, debug and other high frequency messages.
---@param content string
---@param metaData any | nil
---@param printToTerminal boolean | nil
global function SendDebug(content: string, metaData: any|nil, printToTerminal: boolean)
    if printToTerminal == nil then
        printToTerminal = true
    end
    if printToTerminal then
        term.setTextColor(colors.gray)
        print("[DEBUG] "..content)
        term.setTextColor(colors.white)
    end
    sendMessage(content, "Debug", metaData)
end

---Send a OutOfFuel Message, use these for when a turtle needs the player to refuel
---@param metaData any | nil
global function SendOutOfFuel(metaData: any|nil)
    sendMessage("Turtle is out of fuel", "OutOfFuel", metaData)
end

local function changeStatus(_status: string)
    status = _status
    SendDebug("[Status] Changed to: "..status, nil, false)
    sendInfo()
end

---Set status to 'Done'
global function SetDoneStatus()
    changeStatus("Done")
end
---Set status to 'Farming'
global function SetFarmingStatus()
    changeStatus("Farming")
end
---Set status to 'Waiting'
global function SetWaitingStatus()
    changeStatus("Waiting")
end
---Set status to 'Error'
global function SetErrorStatus()
    changeStatus("Error")
end
---Set status to 'Refueling'
global function SetRefuelingStatus()
    changeStatus("Refueling")
end
---Set status to 'Need Player'
global function SetNeedPlayerStatus()
    changeStatus("Need Player")
end
---Set status to 'Manually Terminated'
global function SetManuallyTerminatedStatus()
    changeStatus("Manually Terminated")
end
---Set status to 'Returning'
global function SetReturningStatus()
    changeStatus("Returning")
end
---Set status to 'Emptying'
global function SetEmptyingStatus()
    changeStatus("Emptying")
end
---Set status to 'Stopped'
global function SetStoppedStatus()
    changeStatus("Stopped")
end
---Set status to 'Rebooting'
global function SetRebootingStatus()
    changeStatus("Rebooting")
end
---Set status to 'Initializing'
global function SetInitializingStatus()
    changeStatus("Initializing")
end
---Set a custom status, please capitalize the first letter of each word
---@param customStatus string
global function SetCustomStatus(customStatus: string)
    changeStatus(customStatus)
end
local function sendLocation()
    if isTurtle then
        local location: Location = {
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
    turtle.turnRight = function (): boolean, string|nil
        local success, msg: boolean, string|nil = turtleTurnRight()
        if success and rotationDefined then
            facing = facing + 1
            if facing == 5 then
                facing = 1
            end
        end
        return success, msg
    end

    local turtleTurnLeft = turtle.turnLeft
    turtle.turnLeft = function (): boolean, string|nil
        local success, msg = turtleTurnLeft()
        if success and rotationDefined then
            facing = facing - 1
            if facing == 0 then
                facing = 4
            end
        end
        return success, msg
    end

    local turtleForward = turtle.forward
    turtle.forward = function (): boolean, string|nil
        local success, msg = turtleForward()
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
        return success, msg
    end


    local turtleBack= turtle.back
    turtle.back = function (): boolean, string|nil
        local success, msg = turtleBack()
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
        return success, msg
    end


    local turtleUp= turtle.up
    turtle.up = function (): boolean, string|nil
        local success, msg = turtleUp()
        if success then
            y = y + 1
        end
        sendLocation()
        return success, msg
    end



    local turtleDown= turtle.down
    turtle.down = function (): boolean, string|nil
        local success, msg = turtleDown()
        if success then
            y = y - 1
        end
        sendLocation()
        return success, msg
    end
end


local function listenForCommands()
    while true do
        local _, _, channel, _replyChannel, modemMessage, _ = os.pullEvent("modem_message")
        if channel == commandsChannel then
            local commandAction: CommandAction = modemMessage as CommandAction
            if commandAction.computerId and commandAction.computerId == os.getComputerID() and commandAction.command then
                SendDebug("Received command "..commandAction.command, commandAction)
                if commandAction.command == "STOP" then
                    if crashedState then
                        SendDebug("Turtle is already in crashed state, ignoring this STOP command")
                    else
                        SendDebug("Received STOP command, entering crashed state")
                        error("TRACKER_STOP")
                    end
                elseif commandAction.command == "REBOOT" then
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
    local _x, _y, _z = gps.locate()
    x = _x as integer
    y = _y as integer
    z = _z as integer
    SendDebug("Starting location", {x=x, y=y, z=z})
    sendLocation()
end


local function initComputerInfo(_systemId: integer|nil)
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
        print("[ERROR] No Wireless Modem detected, tracker won't work without it.")
        error("Missing Wireless Modem")
    end
end



local function bind(f: function): function
    return function()
        local success, err = pcall(f)
        if not success then
            sendLocation()
            sendInfo()
            if string.find(err as string, "Terminated") then
                SetManuallyTerminatedStatus()
                SendDebug("Turtle has been manually terminated")
                error(err)
            elseif string.find(err as string, "TRACKER_STOP") then
                crashedState = true
                SetStoppedStatus()
                SendDebug("Turtle has been stopped")
            elseif string.find(err as string, "TRACKER_REBOOT")  then
                SetRebootingStatus()
                SendDebug("Turtle is rebooting")
                os.reboot()
            else
                SendError(err as string)
                SetErrorStatus()
            end
        end
    end
end

local function enterCrashedState()
    parallel.waitForAny(bind(listenForCommands), bind(initInfo))
end


global function InitTracker(main: function, _systemId: integer|nil)
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


