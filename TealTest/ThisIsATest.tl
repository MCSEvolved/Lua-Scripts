--------------------------LIB--------------------------
require("Tracker.TrackerLib")
--------------------------END--------------------------

local function main()
    local counter = 0
    while true do 
        counter = counter + 1
        print("Hello world at: " .. os.clock())
        if counter == 100 then
            error("Error at: " .. os.clock())
        end
    end
end

InitTracker(main, 0)