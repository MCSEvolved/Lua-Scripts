local modem = peripheral.find("modem", function (_, o)
    return o.isWireless()
 end)
local channel = 443
local url = "https://api.mcsynergy.nl/minecraft-token/generate"
local timeout = 20
local password

local function getToken()
    http.request({url=url, method="GET", headers={["Authorization"]=password}, timeout=timeout})
end

local function sendToken(token)
    print("[INFO] Sending token")
    modem.transmit(channel, channel, {token=token.readAll()})
end

local function sendError(error)
    modem.transmit(channel, channel, {error=error})
end

local function listenForEvents()
    while true do
        local eventData = table.pack(os.pullEvent())
        if eventData[1] == "modem_message" and eventData[5] == "REQUEST_TOKEN" then
            getToken()
        elseif eventData[1] == "http_success" and eventData[2] == url then
            sendToken(eventData[3])
        elseif eventData[1] == "http_failure" and eventData[2] == url then
            print("[ERROR] Failed to get token")
            print(eventData[3])
            if eventData[4] ~= nil then
                print(eventData[4].readAll())
            end
            sendError(eventData[3])
        end
        
    end
end

local function openModemConnection()
    modem.open(channel)
    if modem.isOpen(channel) == false then
        error("Couldn't open channel "..channel)
    end
    print("Listening on "..channel)
end

local function readPassword()
    local file = fs.open("/certificate.txt", "r")
    password = file.readLine()
    if password == nil then
        error("Couldn't find password in /certificate.txt")
    end
    file.close()
end

local function main()
    readPassword()
    openModemConnection()
    listenForEvents()
end

main()