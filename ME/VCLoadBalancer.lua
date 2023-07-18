require("Tracker.TrackerLib")

local meBridge = peripheral.find("meBridge")
local energyDetector = peripheral.find("energyDetector")
local monitor = peripheral.find("monitor")
local vibrationChambers = {}
local meIsOnline = true
local amountHeadroom = 1
local isReplenishing = false
local hasSendError = false
local burnTime = 11

local function findVibrationChambers()
    for key, value in pairs(peripheral.getNames()) do
        if value:find("ae2:vibration_chamber") then
            table.insert(vibrationChambers, value)
        end
    end
    print(#vibrationChambers.." VibrationChambers Found")
end

local function getReactorGeneration()
    local reactorGeneration = energyDetector.getTransferRate()
    return reactorGeneration
end

local function getPowerDemand()
    local usage, err = meBridge.getEnergyUsage()
    if usage == nil or usage == 0 then
        if meIsOnline then
            print("ME Offline")
        end
        meIsOnline = false
        
        return 0
    end
    meIsOnline = true
    usage = usage*2
    return usage
end

local function calculateAmountVC()
    local reactorGeneration = getReactorGeneration()
    local powerDemand = getPowerDemand()
    local requiredPower = powerDemand - reactorGeneration
    if requiredPower < 0 then
        requiredPower = 0
    end

    local amountVC = requiredPower/80
    if amountVC > #vibrationChambers then
        return #vibrationChambers
    end
    return amountVC
end

local function getStorageAmounts()
    local max, maxErr = meBridge.getMaxEnergyStorage()
    local curr, currErr = meBridge.getEnergyStorage()
    if max == nil or curr == nil or max == 0 then
        if meIsOnline then
            print("ME Offline")
        end
        meIsOnline = false
        return 0, 0
    end
    max = max*2
    curr = curr*2
    meIsOnline = true

    return curr, max
end

local function needsReplenishing()
    local max, maxErr = meBridge.getMaxEnergyStorage()
    local curr, currErr = meBridge.getEnergyStorage()
    if max == nil or curr == nil or max == 0 then
        if meIsOnline then
            print("ME Offline")
        end
        meIsOnline = false
        return false
    end
    max = max*2
    curr = curr*2
    meIsOnline = true

    local requiredPercentage = 100 - ((curr/max) * 100)
    if requiredPercentage > 90 and not hasSendError then
        SendError("Energy storage is below 10%", vibrationChambers)
        hasSendError = true
    end
    if requiredPercentage > 10 then
        isReplenishing = true
        return isReplenishing
    end
    isReplenishing = false
    return isReplenishing
end

local function pullFromStorage(amount, inventory)
    local amount, error = meBridge.exportItemToPeripheral({name="minecraft:charcoal", count=1}, inventory)
    if amount == nil or amount == 0 then
        if meIsOnline then
            print("ME Offline")
        end
        meIsOnline = false
        return
    end
    meIsOnline = true
end

local function pushToVC(requiredAmountVC, needsReplenishing)
    local amountVC = math.ceil(requiredAmountVC) + amountHeadroom
    if needsReplenishing then
        amountVC = #vibrationChambers
    end
    for i=1, amountVC, 1 do
        if i > #vibrationChambers then
            return
        end
        pullFromStorage(1, vibrationChambers[i])
    end
end

local function areVCsEmpty()
    for i=1, #vibrationChambers do
        local vibrationChamber = peripheral.wrap(vibrationChambers[i])
        local item = vibrationChamber.getItemDetail(1)
        if item ~= nil then
            return false
        end
    end
    return true
end

local function waitForEmpty()
    while true do
        if areVCsEmpty() then
            return
        end
        os.sleep(0.01)
    end
    
end

local function writeLineToMonitor(message)
    monitor.clearLine()
    monitor.write(message)
    local x, y = monitor.getCursorPos()
    monitor.setCursorPos(1, y+1)
end

local function updateMonitor()
    while true do

        local powerDemand = math.floor(getPowerDemand()+0.5)
        local reactorGeneration = math.floor(getReactorGeneration()+0.5)

        local activeVCs = calculateAmountVC() + amountHeadroom
        if isReplenishing then
            activeVCs = #vibrationChambers
        end
        local curr, max = getStorageAmounts()
        curr = curr/1000000
        max = max/1000000

        monitor.setCursorPos(1, 1)
        writeLineToMonitor("[ME Usage]")
        writeLineToMonitor(powerDemand.." RF/t")
        writeLineToMonitor("----------")

        writeLineToMonitor("[Reactor Generation]")
        writeLineToMonitor(reactorGeneration.." RF/t")
        writeLineToMonitor("----------")
        
        if activeVCs >= #vibrationChambers then
            monitor.setTextColor(colors.red)
        elseif activeVCs > (#vibrationChambers*0.75) then
            monitor.setTextColor(colors.orange)
        else
            monitor.setTextColor(colors.green)
        end
        writeLineToMonitor("[approx. Coal Usage]")
        monitor.setTextColor(colors.white)
        writeLineToMonitor((math.ceil((activeVCs*5.4))).." Coal/min - "..math.ceil((activeVCs)).."/"..#vibrationChambers.." Chambers")
        writeLineToMonitor("----------")

        
        
        if isReplenishing then
            monitor.setTextColor(colors.orange)
        else
            monitor.setTextColor(colors.green)
        end
        writeLineToMonitor("[Energy Storage]")
        monitor.setTextColor(colors.white)
        writeLineToMonitor((math.ceil(curr*100)/100).." MRF / "..(math.ceil(max*100)/100).." MRF")
        writeLineToMonitor("+"..(math.ceil((activeVCs - calculateAmountVC())*80)).." RF/t")
        os.sleep(0.5)
    end
end

local function balanceVC()
    findVibrationChambers()
    while true do
        pushToVC(calculateAmountVC(), needsReplenishing())
        waitForEmpty()
    end
end


local function main()
    parallel.waitForAll(balanceVC, updateMonitor)
end


InitTracker(main, 9)