local function placeWater()
    while true do
        if not turtle.forward() then return end
        if not turtle.forward() then return end
        turtle.placeDown()
        turtle.back()
        turtle.placeDown()
        if not turtle.forward() then return end
    end
end

placeWater()
turtle.placeDown()
turtle.back()
turtle.placeDown()
