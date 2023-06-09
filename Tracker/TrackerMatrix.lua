require("libraries.lib")

local wirelessChannel = 40

local wirelessModem = peripheral.find("modem", function (n,o)
    return o.isWireless()
end)

-- local wsUrl = "ws://josian.nl:8000/tracker/ws/server"
-- local httpUrl = "http://josian.nl:8000/tracker"

local wsUrl = "wss://api.mcsynergy.nl/tracker/ws/server"
local httpUrl = "https://api.mcsynergy.nl/tracker"

local tasklist = {}
local socket
local protocolHasBeenSend = false
local savedToken

local function getToken(refresh)
    if refresh == nil then
        refresh = false
    end

    if refresh or savedToken == nil then
        local success, response = GetAuthToken(true)
        if success then
            savedToken = response
        else
            print("[ERROR] "..response)
        end
    end
    
    return savedToken
end

local function sendMessageOverHTTP(message)
    local url = httpUrl.."/message/new"
    local token = getToken()
    local body = textutils.serialiseJSON(message)
    local headers = {["Authorization"]=token, ["Content-Type"]="application/json"}

    local response, err, failResponse = http.post(url, body, headers)
    if failResponse and failResponse.getResponseCode() == 401 then
        getToken(true)
        sleep(1)
        sendMessageOverHTTP(message)
    elseif failResponse then
        --print()
        print(failResponse.getResponseCode()..failResponse.readAll())
    end
end

local function sendMessageOverWs(target, message)
    if socket and protocolHasBeenSend then
        local arguments = textutils.serialiseJSON(message)
        -- local final = textutils.serialiseJSON({
        --     type=1,
        --     target=target,
        --     arguments=arguments,
        --     invocationId="0"
        -- })..""
        -- print(final)

        local final = "{\"type\":1,\"target\":\""..target.."\",\"arguments\":["..arguments.."],\"invocationId\":\"0\"}"..""
        --print(arguments)
        socket.send(final)
        return true
    else
        return false
    end
end


local function validateMessage(message)
    return message.type and message.source and message.content and message.sourceId
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
            sourceId = "Tracker"
        }
    else
        message = {
            type = messageType,
            source = "Service",
            content = content,
            metaData = {},
            sourceId = "Tracker"
        }
    end
    
    if validateMessage(message) then
        if sendMessageOverWs("NewMessage",message) == false then
            sendMessageOverHTTP(message)
        end
        
    else
        print("[WARNING] Invalid message: "..textutils.serialise(message), true)
    end
end


local function sendInfo(content, metaData)
    print("[INFO] "..content, false)
    sendMessage(content, "Info", metaData)
end

local function sendWarning(content, metaData)
    print("[WARNING] "..content, false)
    sendMessage(content, "Warning", metaData)
end

local function sendError(content, metaData)
    print("[ERROR] "..content, false)
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
    print("Sending Protocol", false)
    local protocol = textutils.serialiseJSON({
        protocol="json",
        version=1
    })..""
    print(protocol, false)
    socket.send(
        protocol
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
        if #tasklist > 1 then
            local message = tasklist[#tasklist]
            
            if message == nil then
                print("Message is nil", true)
            else
                if message.type == "MESSAGE" then
                    if sendMessageOverWs("NewMessage",message.content) == false then
                        sendMessageOverHTTP(message.content)
                    end
                elseif message.type == "COMPUTER" then
                    sendMessageOverWs("NewComputer", message.content)
                elseif message.type == "LOCATION" then
                    sendMessageOverWs("NewLocation",message.content)
                end
                table.remove(tasklist, #tasklist)
            end
            
        end
        sleep(0.01)
    end
end

local function connectToWebsocket()
    local token = getToken()
    http.websocketAsync(wsUrl, {["Authorization"]=token})
    print("[STATUS] connecting to Server...", false)
end



local function openMessagesConnection()
    local timer_id
    
    connectToWebsocket()
    
    while true do
        checkModemConnections()
        local eventData = table.pack(os.pullEvent())
        if eventData[1] == 'modem_message' and eventData[3] == wirelessChannel  then
            table.insert(tasklist, 1, eventData[5])            
        elseif eventData[1] == "websocket_message" and eventData[2] == wsUrl then
            print(eventData[3])

        elseif eventData[1] == "websocket_success" and eventData[2] == wsUrl then
            print("[STATUS] Succesfully connected to Tracker Server", true)
            socket = eventData[3]
            sendProtocol()

        elseif eventData[1] == "websocket_closed" and eventData[2] == wsUrl then
            socket = nil
            --sendInfo("Connection with Tracker Server closed")
            print("Connection with Tracker Server closed", true)
            protocolHasBeenSend = false
            timer_id = os.startTimer(1)

        elseif eventData[1] == "websocket_failure" and eventData[2] == wsUrl then
            socket = nil
            print("[ERROR] Connection with Tracker Server failed: "..eventData[3], true)
            if protocolHasBeenSend then
                --sendWarning("WS connection failed", {taskList=tasklist})
            end
            
            protocolHasBeenSend = false
            timer_id = os.startTimer(5)

        elseif eventData[1] == "timer" and eventData[2] == timer_id then
            connectToWebsocket()
            print("[STATUS] Connecting to Tracker Server...", false)

        elseif eventData[1] == "http_failure" and eventData[2] == httpUrl.."/message/new" then
            print(eventData[3])
            if eventData[4].getResponseCode() == 401 then
                getToken(true)
            end
        end
    end
    
end

local function bind(f)
    return function()
        local success, err = pcall(f)
        if not success then
            if err == "Terminated" then
                --sendDebug("Matrix has been manually terminated", {taskList=tasklist})
                error(err)
            else
                --sendError(err, {taskList=tasklist})
                error(err)
            end
        end
    end
end


local function main()
    checkModemConnections()
    getToken(true)
    parallel.waitForAll(bind(openMessagesConnection), bind(executeCommands))

end

main()