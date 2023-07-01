local modem = nil
local monitor = peripheral.find("monitor")


local function findWirelessModem()
    local names  = peripheral.getNames()
    for i = 1, #names do
        if peripheral.getType(names[i]) == "modem" and peripheral.call(names[i], "isWireless") then
            return peripheral.wrap(names[i])
        end
    end
end

local function initialize()
    modem = findWirelessModem()
    if not modem then
        error("Could not find wireless modem")
    end

    if not monitor then
        error("Could not find monitor")
    end
end

local function visualiseData(productionData)
    monitor.clear()
    for i = 1, #productionData do
        monitor.setCursorPos(1, i)
        monitor.write(productionData[i].time .. " : " ..  productionData[i].produced .. " E")
    end
end

local function listenForData()
    modem.open(20)
    while true do
        local event, modemSide, senderChannel, replyChannel, message, senderDistance = os.pullEvent("modem_message")
        if type(message) == "table" and message.sender == "MANAGER" and message.type == "PRODUCTION_DATA" then
            return message.data
        end
    end
end

local function main()
    local productionDataList = {}
    while true do
        local productionData = listenForData()
        table.insert(productionDataList, productionData)
        if #productionDataList > 5 then
            table.remove(productionDataList, 1)
        end
        visualiseData(productionDataList)
    end
end

initialize()
main()