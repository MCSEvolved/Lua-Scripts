local detector = peripheral.find("playerDetector")
local doorRIHall = peripheral.wrap("redstoneIntegrator_0")
local doorRIRoom = peripheral.wrap("redstoneIntegrator_2")
local allowedPlayers = {"crazyvinvin", "josian2004", "CtrlAnimJesse", "pizzabakkercarst", "panini8117"}
local monitor = peripheral.find("monitor")
local range = {x=4, y=2, z=3}

local function unlockAll()
    print("Unlocking doors")
    doorRIHall.setOutput("left", false)
    doorRIRoom.setOutput("left", false)
end

local function lockAll()
    print("Locking doors")
    doorRIHall.setOutput("left", true)
    doorRIRoom.setOutput("left", true)
end

local function waitForAllowedPlayerToEnterRange()
    print("Waiting for allowed player to enter range")
    while true do
        local playerList = detector.getPlayersInCubic(range.x, range.y, range.z)
        for _, player in pairs(playerList) do
            print("Found player " .. player)
            for _, allowedPlayer in pairs(allowedPlayers) do
                if player == allowedPlayer then
                    print("Player " .. player .. " is allowed")
                    return true, player
                else
                    print("Player " .. player .. " is not allowed")
                end
            end
        end
        sleep(0.01)
    end
end

local function waitForAllowedPlayersToExitRange()
    print("Waiting for allowed players to exit range")
    while true do
        local allowedPlayerInRange
        local playerList = detector.getPlayersInCubic(range.x, range.y, range.z)
        for _, player in pairs(playerList) do
            for _, allowedPlayer in pairs(allowedPlayers) do
                if player == allowedPlayer then
                    allowedPlayerInRange = true
                end
            end
        end
        if not allowedPlayerInRange then
            print("No allowed players in range")
            return true
        end
        sleep(0.01)
    end
end

local function initialize()
    if not detector then
        error("Could not find player detector")
    end
    if not doorRIHall then
        error("Could not find door hall redstone integrator")
    end
    if not doorRIRoom then
        error("Could not find door room redstone integrator")
    end
    if not monitor then
        error("Could not find monitor")
    end
    lockAll()
    monitor.clear()
end

local function showWelcome(player)
    monitor.clear()
    monitor.setTextColor(3)
    monitor.setCursorPos(1, 1)
    monitor.write("Welcome")
    monitor.setCursorPos(1, 2)
    monitor.write(player .. "!")
end

local function main()
    while true do
        local _, player = waitForAllowedPlayerToEnterRange()

        showWelcome(player)
        unlockAll()
        sleep(1)
        waitForAllowedPlayersToExitRange()
        monitor.clear()
        lockAll()
    end
end

initialize()
main()