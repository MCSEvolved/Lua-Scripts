local tradingInterface = peripheral.find("trading_interface")
local correctBooksFound = 0
local trade = {
    cost = {
        name = "item.minecraft.emerald",
        count = 11,
    },
    name = "item.minecraft.enchanted_book",
    enchant = "enchantment.minecraft.sweeping 3",
}

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

local function getCost(_trade)
    local cost = {}
    for itemName, v in pairs(_trade.costA) do
        cost.count = v.count
    end
    return cost.count
end

local function checkCost(_tradeCost, shouldCost)
    if type(_tradeCost) ~= "table" then
        return false
    end
    for itemName, v in pairs(_tradeCost) do
        if itemName == shouldCost.name and v.count <= shouldCost.count then
            return true, v.count
        end
    end
    return false
end

--- @param _trade table
local function findTrade(_trade)
    local cycles = 0
    while true do
        local trades = tradingInterface.getTrades()
        for i = 1, #trades do
            for itemName, info in pairs(trades[i].result) do
                if itemName == _trade.name and info.enchants[1] == _trade.enchant then
                    printOnNextLine("Found " .. itemName .. " with enchant " .. info.enchants[1])
                    print("Price: " .. getCost(trades[i]))
                    correctBooksFound = correctBooksFound + 1
                    print("Correct books found: " .. correctBooksFound)
                    if (checkCost(trades[i].costA, _trade.cost)) then
                        printOnNextLine("Found trade")
                        return true, i
                    end
                end
            end
        end
        tradingInterface.cycleTrades()
        cycles = cycles + 1
        if cycles > 30000 then
            error("not found within 30000 cycles")
        end
        printOnSameLine("Cycle: " .. cycles)
        --sleep(0.01)
    end
end

initialize()
findTrade(trade)