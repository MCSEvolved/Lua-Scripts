local record SlotInfo
    name: string
    count: integer
    nbt: string|nil
end

local record Inventory
    size: function(): integer
    list: function(): {SlotInfo|nil}
    getItemDetail: function(slot: integer): table|nil
    getItemLimit: function(slot: integer): number
    pushItems: function(toName: string, fromSlot: integer, limit: integer|nil, toSlot: integer|nil): integer
    pullItems: function(fromName: string, fromSlot: integer, limit: integer|nil, toSlot: integer|nil): integer
end


return Inventory