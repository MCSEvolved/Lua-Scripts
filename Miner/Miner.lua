local MINER_CHANNEL = 30
local peripheralSlot = 16
local modem = peripheral.wrap("right")

--N = nz, E = px, S = pz, W = nx
local NORTH, EAST, SOUTH, WEST = 0,1,2,3

local currentFacing = NORTH

local pathFacing = NORTH
local pathStartingPosition = {x=0, y=0, z=0}
local pathReturnPoint = {x=0, y=0, z=0}

local oresToSearchFor = {
    "minecraft:diamond_ore",
    "minecraft:deepslate_diamond_ore",
    "bigreactors:yellorite_ore"
}

if modem == nil then
    error("modem not found")
end

modem.open(MINER_CHANNEL)

local function dock()
    modem.transmit(MINER_CHANNEL,MINER_CHANNEL, {action="request docking"})
    local _, _, _, _, message = os.pullEvent("modem_message")
    while message.action == "docking granted" do
        _, _, _, _, message = os.pullEvent("modem_message")
    end


    local _, startY, _ = gps.locate()
    local currentY = startY

    while currentY < message.targetY do
        if turtle.inspectUp() then
            turtle.digUp()
        end
        while not turtle.up() do
            turtle.digUp()
        end
        currentY = currentY + 1
    end

    local inventory = {}
    for i = 1, 15 do
        inventory[i] = turtle.getItemDetail(i)
    end

    modem.transmit(MINER_CHANNEL, MINER_CHANNEL, {action="ready to dock", inventory=inventory})

    while message.action == "ready to refuel" do
        _, _, _, _, message = os.pullEvent("modem_message")
    end

    for i = 1, 15 do
        turtle.select(i)
        turtle.refuel()
        if turtle.getFuelLevel() == turtle.getFuelLimit() then
            break
        end
    end

    modem.transmit(MINER_CHANNEL, MINER_CHANNEL, {action="refuel done"})

    while message.action == "docking done" do
        _, _, _, _, message = os.pullEvent("modem_message")
    end

    while currentY > startY do
        if turtle.inspectDown() then
            turtle.digDown()
        end
        turtle.down()
    end

end

local function emptyInventory()
    for i = 1, 15 do
        local item = turtle.getItemDetail(i)
        if item.name ~= "minecraft:diamond" and item.name ~= "bigreactors:yellorite_ore" then
            turtle.select(i)
            if not turtle.dropDown() then
                if not turtle.dropUp() then
                    if not turtle.drop() then
                        error("failed to drop items")
                    end
                end
            end
        end
    end

    for i=15, 1, -1 do
        local item = turtle.getItemDetail(i)
        if item then
            turtle.select(i)
            for j=1, 15 do
                local slot = turtle.getItemDetail(j)
                if not slot or slot.name == item.name then
                    turtle.transferTo(j)
                    if turtle.getItemCount(i) == 0 then
                        break
                    end
                end
            end
        end
    end

    if turtle.getItemCount(15) > 0 then
        dock()
    end
    turtle.select(1)
end

local function walk(direction)
    local digFunction = turtle.dig
    local moveFunction = turtle.forward
    local detectFunction = turtle.detect

    if direction == "up" then
        digFunction = turtle.digUp
        moveFunction = turtle.up
        detectFunction = turtle.detectUp
    elseif direction == "down" then
        digFunction = turtle.digDown
        moveFunction = turtle.down
        detectFunction = turtle.detectDown
    elseif direction ~= "forward" then
        error("cannot walk in direction: " .. tostring(direction))
    end

    local x,y,z = gps.locate()

    if detectFunction() then
        digFunction()
    end

    local didWalk, err = moveFunction()
    while not didWalk and err == "Movement obstructed" do
        digFunction()
        didWalk, err = moveFunction()
    end

    if not didWalk then
        error("failed to walk, " .. tostring(err))
    end

    modem.transmit(MINER_CHANNEL, MINER_CHANNEL, {action="walk", location={x=x,y=y,z=z}})

    if turtle.getItemCount(16) > 0 then
        emptyInventory()
    end
end

local function turn(direction)
    if direction == "left" then
        turtle.turnLeft()
    elseif direction == "right" then
        turtle.turnRight()
        currentFacing = math.fmod(currentFacing+1, 4)
    else
        error("unknown direction to turn to: " .. tostring(direction))
    end

    modem.transmit(MINER_CHANNEL, MINER_CHANNEL, {action="turn", direction=direction})
end

local function turnTo(direction)
    if math.fmod(currentFacing + 1, 4) == direction then
        turn("right")
    elseif math.fmod(direction + 1, 4) == currentFacing then
        turn("left")
    elseif currentFacing ~= direction then
        turn("left")
        turn("left")
    end
end

local function walkTo(ore)
    local startX, startY, startZ = gps.locate()
    local dx = ore.x - startX
    local dy = ore.y - startY
    local dz = ore.z - startZ

    if dy < 0 then
        for _ = 1, math.abs(dy) do walk("down") end
    else
        for _ = 1, dy do walk("up") end
    end

    if dx < 0 then
        turnTo(WEST)
    elseif dx > 0 then
        turnTo(EAST)
    end

    for _ = 1, math.abs(dx) do walk("forward") end

    if dz < 0 then
        turnTo(WEST)
    elseif dz > 0 then
        turnTo(EAST)
    end

    for _ = 1, math.abs(dz) do walk("forward") end
end

local function determinePath()
    if turtle.getItemDetail(peripheralSlot).name == "advancedperipherals:geo_scanner" then
        turtle.equipLeft(16)
    end

    local scan = peripheral.wrap("left").scan(8)

    -- filter out the ores
    local ores = {}
    for i = 1, #scan do
        for _, oreToSearchFor in pairs(oresToSearchFor) do
            if scan[i].name == oreToSearchFor then
                table.insert(ores, scan[i])
                break
            end
        end
    end

    local function getDistance(pos, ore)
        return math.abs(pos.x-ore.x) + math.abs(pos.y-ore.y) + math.abs(pos.z-ore.z)
    end

    local pos = {x=0, y=0, z=0}
    for i = 1, #ores do
        local closestDistance = getDistance(pos, ores[i])
        local closestIndex = i
        for j = i+1, #ores do
            local distance = getDistance(pos, ores[j])
            if distance < closestDistance then
                closestDistance = distance
                closestIndex = j
            end
        end
        local swapOre = ores[i]
        ores[i] = ores[closestIndex]
        ores[closestIndex] = swapOre
        pos.x = ores[i].x
        pos.y = ores[i].y
        pos.z = ores[i].z
    end

    local turtleX, turtleY, turtleZ = gps.locate()
    for i = 1, #ores do
        ores[i].x = ores[i].x + turtleX
        ores[i].y = ores[i].y + turtleY
        ores[i].z = ores[i].z + turtleZ
    end

    return ores
end

local function walkPath(path)
    for _, ore in pairs(path) do
        walkTo(ore)
    end
end

local function main()
    while true do
        if pathFacing == NORTH then
            pathReturnPoint.z = pathReturnPoint.z - 16
        elseif pathFacing == SOUTH then
            pathReturnPoint.z = pathReturnPoint.z + 16
        elseif pathFacing == WEST then
            pathReturnPoint.x = pathReturnPoint.x - 16
        else
            pathReturnPoint.x = pathReturnPoint.x + 16
        end
        walkTo(pathReturnPoint)
        local path = determinePath()
        walkPath(path)
        if turtle.getFuelLevel() < 5000 then
            dock()
        end
    end
end

local function initCurrentFacing()
    local startX, _, startZ = gps.locate()
    walk('forward')
    local newX, _, newZ = gps.locate()
    if newX < startX then
        currentFacing = WEST
    elseif newX > startX then
        currentFacing = EAST
    elseif newZ < startZ then
        currentFacing = NORTH
    else
        currentFacing = SOUTH
    end
end

local function initPathConfig()
    local x,y,z = gps.locate()
    local file = fs.open('pathconfig', 'r')
    if not file then
        pathStartingPosition.x=x
        pathStartingPosition.y=y
        pathStartingPosition.z=z

        pathFacing = currentFacing
        local writeFile = fs.open('pathconfig', 'w')
        writeFile.write(textutils.serialise({pathStartingPosition=pathStartingPosition, pathFacing=pathFacing}))
        writeFile.close()
    else
        local config = textutils.unserialise(file.readAll())
        pathStartingPosition = config.pathStartingPosition
        pathFacing = config.pathFacing
    end

    pathReturnPoint.y = pathStartingPosition.y
    if pathFacing == NORTH or pathFacing == SOUTH then
        pathReturnPoint.x = pathStartingPosition.x
        pathReturnPoint.z = z
    else
        pathReturnPoint.x = x
        pathReturnPoint.z = pathReturnPoint.z
    end
end

local function init()
    --set currentFacing
    initCurrentFacing()
    --set pathFacing
    --set pathStartingPosition
    initPathConfig()

    walkTo(pathReturnPoint)
    local path = determinePath()
    walkPath(path)
end

init()
main()
