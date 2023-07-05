local type side = enum 
    "left"
    "right"
end

local record Turtle
    craft: function(limit: integer|nil): boolean, string|nil
    forward: function() : boolean, string|nil
    back: function() : boolean, string|nil
    up: function() : boolean, string|nil
    down: function() : boolean, string|nil
    turnLeft: function() : boolean, string|nil
    turnRight: function() : boolean, string|nil
    dig: function(side: side|nil) : boolean, string|nil
    digUp: function(side: side|nil) : boolean, string|nil
    digDown: function(side: side|nil) : boolean, string|nil
    place: function(text: string|nil) : boolean, string|nil
    placeUp: function(text: string|nil) : boolean, string|nil
    placeDown: function(text: string|nil) : boolean, string|nil
    drop: function(count: integer|nil) : boolean, string|nil
    dropUp: function(count: integer|nil) : boolean, string|nil
    dropDown: function(count: integer|nil) : boolean, string|nil
    select: function(slot: integer): boolean
    getItemCount: function(slot: integer|nil): integer
    getItemSpace: function(slot: integer|nil): integer
    detect: function(): boolean
    detectUp: function(): boolean
    detectDown: function(): boolean
    compare: function(): boolean
    compareUp: function(): boolean
    compareDown: function(): boolean
    attack: function(side: side|nil): boolean, string|nil
    attackUp: function(side: side|nil): boolean, string|nil
    attackDown: function(side: side|nil): boolean, string|nil
    suck: function(count: integer|nil): boolean, string|nil
    suckUp: function(count: integer|nil): boolean, string|nil
    suckDown: function(count: integer|nil): boolean, string|nil
    getFuelLevel: function(): number
    refuel: function(count: integer|nil): boolean, string|nil
    compareTo: function(slot: integer): boolean
    transferTo: function(slot: integer, count: integer|nil): boolean
    getSelectedSlot: function(): number
    getFuelLimit: function(): number
    equipLeft: function(): boolean, string|nil
    equipRight: function(): boolean, string|nil
    inspect: function(): boolean, table|string
    inspectUp: function(): boolean, table|string
    inspectDown: function(): boolean, table|string
    getItemDetail: function(slot: integer|nil, detailed: boolean|nil): table|nil
end

return Turtle