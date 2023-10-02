-- This is the grinder from the more peripherals mod

local record Grinder
    attack: function(): boolean, string | nil

    --The first boolean should not be returned, it is a bug in the mod
    hasSword: function(): boolean, boolean
    pushSword: function(inventoryName: string, inventorySlot: number): boolean, string | nil
    pullSword: function(inventoryName: string): boolean, string | nil
end

return Grinder