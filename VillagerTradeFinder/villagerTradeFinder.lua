local tradingInterface = peripheral.find("trading_interface")
local correctBooksFound = 0
local lowestCost = nil

-- local trade = {
--     cost = {
--         name = "minecraft:emerald",
--         count = 20,
--     },
--     name = "minecraft:book",
--     enchants = {
--         ["enchantment.minecraft.feather_falling"] = 4,
--     }
-- }

local EnchantName = "enchantment.minecraft.unbreaking"
local EnchantLevel = 3

local function initialize()
    if not tradingInterface then
        error("No trading interface found")
        return false
    end
end

local function printOnSameLine(text)
    local x , y = term.getCursorPos()
    term.setCursorPos(1, y)
    term.clearLine()
    term.write(text)
end

local function printOnNextLine(text)
    print()
    print(text)
end

local function findTrade()
    local cycleCount = 0
    while true do
        local trades = tradingInterface.getTrades()
        for tradeID, v in pairs(trades) do
            for itemName, info in pairs(v.result) do
                for enchantName, enchantLevel in pairs(info.enchants) do
                    if enchantName == EnchantName and enchantLevel == EnchantLevel then
                        printOnNextLine("Found trade!")
                        return true
                    end
                end
            end
            cycleCount = cycleCount + 1
            printOnSameLine("cycles: " .. cycleCount)
        end
        tradingInterface.cycleTrades()
    end
end


initialize()
tradingInterface.cycleTrades()
findTrade()