require("Tracker.TrackerLib")

local function main()
    print("running main")
    SendInfo("Message from frontend tracker test!")
    local cornersDone = 0
    while true do
        turtle.forward()
        turtle.turnRight()
        cornersDone = cornersDone + 1
        if cornersDone >= 4 then
            cornersDone = 0
            SendDebug("Completed circle")
        end
    end
end

InitTracker(main, 0)