local record Vector
    add: function(o: Vector): Vector
    sub: function(o: Vector): Vector
    mul: function(m: number): Vector
    div: function(m: number): Vector
    unm: function(): Vector
    dot: function(o: vector): Vector
    cross: function(o: Vector): Vector
    length: function(): number
    normalize: function(): Vector
    round: function(tolerance: number|nil): Vector
    tostring: function(): string
    equals: function(other: Vector): boolean
end

global record vector
    new: function(x: number, y: number, z: number): Vector
end