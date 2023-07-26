turtle.select(1)
for i = 1, 1000 do
    turtle.digUp()
    turtle.digDown()
    turtle.dig()
    turtle.forward()

    if turtle.getItemCount(16) ~= 0 then
        for i = 1, 16 do
            local detail = turtle.getItemDetail(i)
            if detail.name ~= "minecraft:diamond" and detail.name ~= "bigreactors:yellorite_ore" then
                turtle.select(i)
                turtle.dropDown()
            end
        end
        turtle.select(1)
    end
end