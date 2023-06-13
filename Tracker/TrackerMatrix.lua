local wirelessChannel = 20

local wirelessModem = peripheral.find("modem", function (n,o)
    return o.isWireless()
end)

local url = "wss://api.mcsynergy.nl/tracker/ws/server"

local tasklist = {}
local socket
local protocolHasBeenSend = false

local function sendMessageOverHTTP(message)
    local httpUrl = "https://api.mcsynergy.nl/tracker/message/new"
    local token = "[TOKEN_HERE]"
    local body = textutils.serialiseJSON({
        messageType=message.type,
        messageSource=message.source,
        content=message.content,
        metaData=message.metaData,
        identifier=message.identifier
    })
    local headers = {["Authorization"]=token}

    local successResponse, errorMsg, failingResponse = http.post(httpUrl, body, headers)
end

local function sendMessageOverWs(target, message)
    socket.send(
        textutils.serialiseJSON({
            type=1,
            target=target,
            arguments=message,
            invocationId="0"
        })+""
    )
end

local function validateMessage(message)
    return message.type and message.source and message.content and message.identifier
end

local function sendMessage(content, messageType, metaData)
    local message
    
    if metaData ~= nil then
        metaData = {
            metaData = metaData
        }
        
        message = {
            type = messageType,
            source = "Service",
            content = content,
            metaData = metaData,
            identifier = "Tracker"
        }
    else
        message = {
            type = messageType,
            source = "Service",
            content = content,
            metaData = nil,
            identifier = "Tracker"
        }
    end
    
    if validateMessage(message) then
        if socket and protocolHasBeenSend then
            sendMessageOverWs("NewMessage", message)
        elseif message.type ~= "Debug" then
            sendMessageOverHTTP(message)
        end
        
    else
        print("[WARNING] Invalid message: "..textutils.serialise(message), true)
    end
end


local function sendInfo(content, metaData)
    sendMessage(content, "Info", metaData)
end

local function sendWarning(content, metaData)
    sendMessage(content, "Warning", metaData)
end

local function sendError(content, metaData)
    sendMessage(content, "Error", metaData)
end

local function sendDebug(content, metaData)
    sendMessage(content, "Debug", metaData)
end

local printFunc = print
print = function (content, sendAsDebug)
    if sendAsDebug == nil then
        sendAsDebug = false
    end
    local linesWritten = printFunc(content)
    if sendAsDebug then
        sendDebug(content)
    end
    return linesWritten
end









local function sendProtocol()
    socket.send(
        textutils.serialiseJSON({
            protocol="json",
            version=1
        })+""
    )

    protocolHasBeenSend = true
end



local function checkModemConnections()
    if not wirelessModem.isOpen(wirelessChannel) then
        wirelessModem.open(wirelessChannel)
    end
end



local function executeCommands()
    while true do
        if #tasklist < 1 then
            os.pullEvent("task_added")
        end
        local message = tasklist[#tasklist]
        table.remove(tasklist, #tasklist)
        if message == nil then
            error("Message was nil for some reason")
        end
        sendDebug("Message send", message)
        if message.type == "MESSAGE" then
            sendMessageOverWs("NewMessage",message.content)
        elseif message.type == "COMPUTER" then
            sendMessageOverWs("NewComputer", message.content)
        elseif message.type == "LOCATION" then
            sendMessageOverWs("NewLocation",message.content)
        end
    end
end

local function connectToWebsocket()
    local token = "[TOKEN_HERE]"
    http.websocketAsync(url, {["Authorization"]=token})
    print("[STATUS] connecting to Server...", true)
end



local function openMessagesConnection()
    local timer_id
    
    connectToWebsocket()
    
    while true do
        checkModemConnections()
        local eventData = table.pack(os.pullEvent('modem_message', 'websocket_message', 'websocket_success', 'websocket_closed', 'websocket_failure', 'timer'))
        if eventData[1] == 'modem_message' and eventData[3] == wirelessChannel  then
            if socket and protocolHasBeenSend then
                table.insert(tasklist, 1, eventData[5])
            os.queueEvent("task_added")
            else
                sendWarning("Tried to send message while WS was inactive or protocol hasn't been send yet", {socket=socket, protocolHasBeenSend=protocolHasBeenSend, event=eventData})
            end
        elseif eventData[1] == "websocket_message" and eventData[2] == url then
            print(eventData[3])

        elseif eventData[1] == "websocket_success" and eventData[2] == url then
            print("[STATUS] Succesfully connected to Tracker Server", true)
            socket = eventData[3]
            sendProtocol()

        elseif eventData[1] == "websocket_closed" and eventData[2] == url then
            print("[STATUS] Connection with Tracker Server closed", true)
            socket = nil
            protocolHasBeenSend = false
            timer_id = os.startTimer(0.1)

        elseif eventData[1] == "websocket_failure" and eventData[2] == url then
            print("[ERROR] Connection with Tracker Server failed: "..eventData[3], true)
            if protocolHasBeenSend then
                sendWarning("WS connection failed", {taskList=tasklist})
            end
            socket = nil
            protocolHasBeenSend = false
            timer_id = os.startTimer(5)

        elseif eventData[1] == "timer" and eventData[2] == timer_id then
            connectToWebsocket()
            print("[STATUS] Connecting to Tracker Server...", true)
        end
    end
    
end

local function bind(f)
    return function()
        local success, err = pcall(f)
        if not success then
            if err == "Terminated" then
                sendDebug("Matrix has been manually terminated", {taskList=tasklist})
                error(err)
            else
                sendError(err, {taskList=tasklist})
                error(err)
            end
        end
    end
end


local function main()
    checkModemConnections()
    parallel.waitForAll(bind(openMessagesConnection), bind(executeCommands))

end

main()