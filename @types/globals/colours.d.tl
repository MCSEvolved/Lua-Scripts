global record colours
    white: integer
    orange: integer
    magenta: integer
    lightBlue: integer
    yellow: integer
    lime: integer
    pink: integer
    grey: integer
    lightGrey: integer
    cyan: integer
    purple: integer
    blue: integer
    brown: integer
    green: integer
    red: integer
    black: integer
    combine: function(...: integer): integer
    subtract: function(color: integer, ...: {integer}): integer
    test: function(colorSet: integer, colorToTest: integer): boolean
    packRGB: function(r: number, g: number, b: number): integer
    unpackRGB: function(hex: integer): number, number, number
    toBlit: function(color: integer): string
    fromBlit: function(hex: string): integer
end