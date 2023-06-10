local currentRow = 1

local function selectDeepslate()
    while true do
        for i=1, 16 do
            local item = turtle.getItemDetail(i)
            if item and item.name == "minecraft:polished_deepslate" then
                turtle.select(i)
                return
            end
        end
        os.sleep(1)
    end
end

local function emptyEverythingButDeepslate()
    for i=1, 16 do
        local item = turtle.getItemDetail(i)
        if item and item.name ~= "minecraft:polished_deepslate" then
            turtle.select(i)
            turtle.dropDown()
        end
    end
end

local function walkBack()
    if turtle.back() == false then
        turtle.turnLeft()
        turtle.turnLeft()
        local success, block = turtle.inspect()
        if success and block.name == "minecraft:polished_deepslate" then
            error("Tried to dig deepslate")
        end
        turtle.dig()
        turtle.turnLeft()
        turtle.turnLeft()
        emptyEverythingButDeepslate()
        turtle.back()
    end
end

local function placeDeepslate()
    selectDeepslate()
    turtle.place()
end

local function turnToNextRow()
    if currentRow % 2 == 1 then
        turtle.turnRight()
        walkBack()
        placeDeepslate()
        turtle.turnRight()
    else
        turtle.turnLeft()
        walkBack()
        placeDeepslate()
        turtle.turnLeft()
    end
    currentRow = currentRow + 1
end

local function buildRoofRow()
    for i=1, 80 do
        walkBack()
        placeDeepslate()
    end
end



local function main()
    for i=1, 80 do
        buildRoofRow()
        turnToNextRow()
    end
end

main()