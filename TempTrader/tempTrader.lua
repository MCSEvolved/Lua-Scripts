local inputChestName = "minecraft:chest_1"
local outputChestName = "minecraft:chest_0"
local sortingChestName = "minecraft:chest_2"

local itemNameList = {
    ["minecraft:carrot"] = "item.minecraft.carrot", 
    ["minecraft:potato"] = "item.minecraft.potato", 
    ["minecraft:pumpkin"] = "block.minecraft.pumpkin", 
    ["minecraft:melon"] = "block.minecraft.melon"
}

local tradingInterface = peripheral.wrap("trading_interface_0")
local sortingChest = peripheral.wrap(sortingChestName)
local inputChest = peripheral.wrap(inputChestName)
local outputChest = peripheral.wrap(outputChestName)

local trades = {}

local function initialize()
    if not tradingInterface then
        error("No trading interface found")
        return false
    end
    if not inputChest then
        error("No input chest found")
        return false
    end
    if not outputChest then
        error("No output chest found")
        return false
    end
    trades = tradingInterface.getTrades()
end

local function getTradeIndex(inputItemName)
    for i = 1, #trades do
        for k in pairs(trades[i].costA) do
            if k == itemNameList[inputItemName] then
                return i
            end
        end
    end
    return nil
end

local function runTrades()
    local items = inputChest.list()
    if not items then return false end
    local traded = false
    for slot, item in pairs(items) do
        local tradeIndex = getTradeIndex(item.name)
        if tradeIndex then
            while tradingInterface.trade(inputChestName, outputChestName, tradeIndex) do
                traded = true
            end
        end
    end
    return traded
end

local function sortItems()
    local items = inputChest.list()
    for slot in pairs(items) do
        inputChest.pushItems(sortingChestName, slot)
    end

    local itemsInSortingChest = sortingChest.list()
    for slotInSortingChest in pairs(itemsInSortingChest) do
        inputChest.pullItems(sortingChestName, slotInSortingChest)
    end
end

local function main()
    while true do
        if #inputChest.list() < 1 then
            sleep(1)
        else
            if runTrades() then
                sortItems()
            else
                sleep(1)
            end
        end
    end
end

local function test()
    print(getTradeIndex("minecraft:carrot"))
end

initialize()
main()