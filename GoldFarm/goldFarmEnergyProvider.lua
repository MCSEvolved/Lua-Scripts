local function findChest()
    print("Finding chest")
    for i = 1, 4 do
        local success, block = turtle.inspect()
        if success and block.name == "minecraft:chest" then
            return true
        end
        turtle.turnRight()
    end
    return false
end

local function selectEnergyCell()
    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        if item and item.name == "ae2:dense_energy_cell" then
            turtle.select(i)
            return true
        end
    end
    return false
end

local function waitForEnergyCellToBeEmpty()
    print("Waiting for energy cell to be empty")
    while true do
        local success, block = turtle.inspect()
        if not success or not block.name == "ae2:dense_energy_cell" then
            error("Expected energy cell, got " .. block.name)
        end

        if block.state.fullness == 0 then
            return true
        end

        sleep(5)
    end
end

local function getFullEnergyCell()
    print("Getting full energy cell")
    turtle.up()
    if not findChest() then
        error("No chest found")
        return false
    end

    turtle.suck(1)
    if not selectEnergyCell() then
        error("Out of energy cells")
        return false
    end

    return true
end

local function dropOldEnergyCell()
    print("Dropping old energy cell")
    if not selectEnergyCell() then
        return false
    end
    turtle.down()
    if not findChest() then
        error("No chest found")
        return false
    end
    local success, block = turtle.inspect()
    if not success or block.name ~= "minecraft:chest" then
        error("No chest found after find chest returned true")
        return false
    end

    turtle.drop()
    return true
end

local function faceAwayFromChest()
    print("Facing away from chest")
    for i = 1, 4 do
        local success, block = turtle.inspect()
        if success and block.name == "minecraft:chest" then
            turtle.turnRight()
            turtle.turnRight()
            return true
        else
            turtle.turnRight()
        end
    end
    error("No chest found")
    return false
end

local function placeNewEnergyCellTop()
    print("Placing new energy cell on top")
    turtle.up()
    faceAwayFromChest()
    turtle.place()
end

local function placeNewEnergyCellBottom()
    print("Placing new energy cell on bottom")
    turtle.down()
    faceAwayFromChest()
    turtle.place()
end

local function isEnergyCellInFront()
    local success, block = turtle.inspect()
    if not success then
        return false
    end
    return block.name == "ae2:dense_energy_cell"
end

local function initialize()
    print("Initializing")
    while turtle.down() do end

    if not findChest() then
        error("No chest found next to turtle (bottom)")
        return false
    end

    turtle.up()

    if not findChest() then
        error("No chest found next to turtle (top)")
        return false
    end
end

local function main()
    print("Running main")
    while true do
        -- Place new energy cell on top if needed
        faceAwayFromChest()
        if not isEnergyCellInFront() then
            getFullEnergyCell()
            placeNewEnergyCellTop()
        end

        -- Go down and place new energy cell on bottom if needed
        turtle.down()
        if not isEnergyCellInFront() then
            getFullEnergyCell()
            placeNewEnergyCellBottom()
        end

        waitForEnergyCellToBeEmpty()
        turtle.dig()

        dropOldEnergyCell()
        getFullEnergyCell()

        placeNewEnergyCellBottom()

        turtle.up()
        waitForEnergyCellToBeEmpty()
        turtle.dig()

        dropOldEnergyCell()
        turtle.up()
    end
end


initialize()
main()
