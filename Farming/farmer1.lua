local lastHarvest = ""
local currentRow = 1
local isFarming = true


local function selectItem(item)
    local itemToSelect = item
    if item == "minecraft:wheat" then
        itemToSelect = "minecraft:wheat_seeds"
    end
    for i = 1, 16 do  
        local foundItem = turtle.getItemDetail(i)
        if item and item.name == itemToSelect then
            turtle.select(i)
            return
        end
    end
    error("Couldnt plant " + item)
end


local function plant()
    if lastHarvest ~= "" then
        selectItem(lastHarvest)
        turtle.placeDown()
    end
end

local function harvest()
    local succes, block = turtle.inspectDown()
    if succes and block.state.age == 7 then
        turtle.digDown()
        lastHarvest = block.name
    else
        lastHarvest = ""
    end
    
end

local function returnToStart()
    turtle.turnRight()
    turtle.turnRight()
    while true do
        if !turtle.forward() then
            local succes, block = turtle.inspect()
            local succesDown, blockDown = turtle.inspectDown()
            if succes and block.name == "minecraft:oak_log" then
                turtle.turnRight()
                turtle.forward()
                turtle.turnLeft()
                turtle.turnLeft()
                return
            elseif succesDown and blockDown.name == "minecraft:chest" then
                turtle.turnLeft()
                turtle.turnLeft()
                return
            else
                turtle.turnRight()
            end
        end
    end
end

local function turnToNextRow()
    if currentRow % 2 == 1 then
        turtle.turnLeft()
        if !turtle.forward() then
            returnToStart()
        end
        turtle.turnLeft()
    elseif currentRow % 2 == 0 then
        turtle.turnRight()
        if !turtle.forward() then
            returnToStart()
        end
        turtle.turnRight()
    end

    currentRow = currentRow + 1
end

local function startFarming()
    while isFarming do
        if !turtle.forward() then
            turnToNextRow()
        end
        harvest()
        plant()
    end
end



local function dropItems()
    local succes, block = turtle.inspectDown()
    if succes and block.name == "minecraft:chest" then
        for i = 1, 16 do
            local selectedItem = turtle.getItemDetail(i)
            if selectedItem ~= nil then
                turtle.select(i)
                turtle.drop()
            end
        end
    else
        error("No Chest found")
    end
end




local function main()
    startFarming()
    dropItems()
    --sleep(300)
end


main()