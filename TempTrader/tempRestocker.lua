local tradingInterface = peripheral.find("trading_interface")

local function initialize()
    if not tradingInterface then
        error("No trading interface found")
        return false
    end
end

local function main()
    while true do
        tradingInterface.restock()
        sleep(0.01)
    end
end

initialize()
main()