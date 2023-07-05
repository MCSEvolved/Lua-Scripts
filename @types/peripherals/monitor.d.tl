local record Monitor
    setTextScale: function(scale: number)
    getTextScale: function(): number
    write: function(text: string)
    scroll: function(y: integer)
    getCursorPos: function(): integer, integer
    setCursorPos: function(x: integer, y: integer)
    getCursorBlink: function(): boolean
    setCursorBlink: function(blink: boolean)
    getSize: function(): integer, integer
    clear: function()
    clearLine: function()
    getTextColour: function(): integer
    getTextColor: function(): integer
    setTextColour: function(colour: integer)
    setTextColor: function(color: integer)
    getBackgroundColour: function(): integer
    getBackgroundColor: function(): integer
    setBackgroundColour: function(colour: integer)
    setBackgroundColor: function(color: integer)
    isColour: function(): boolean
    isColor: function(): boolean
    blit: function(text: string, textColor: string, backgroundColor: string)
    setPaletteColour: function(index: integer, colorOrR: integer|number, G: number|nil, B: number|nil)
    setPaletteColor: function(index: integer, colorOrR: integer|number, G: number|nil, B: number|nil)
    getPaletteColour: function(colour: integer): number, number, number
    getPaletteColor: function(color: integer): number, number, number
end


return Monitor