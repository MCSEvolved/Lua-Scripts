require("Tracker.OldTrackerLib")
require("libraries.lib")

local function main()
    -- while true do
    --     SetReturningStatus()
    --     turtle.forward()
    --     sleep(5)
    --     turtle.back()
    --     SetWaitingStatus()
    --     sleep(5)
        
    --     --SendWarning("ITS WORKING", {key=2, test="hallo", data="metadata"})
    -- end

    SendError("This is a test notification")

end

InitTracker(main, 0)
