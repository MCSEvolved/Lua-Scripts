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
    setPaletteColour: function(index: integer, R: number, G: number, B: number)
    setPaletteColour: function(index: integer, color: integer)
    setPaletteColor: function(index: integer, R: number, G: number, B: number)
    setPaletteColor: function(index: integer, color: integer)
    getPaletteColour: function(colour: integer): number, number, number
    getPaletteColor: function(color: integer): number, number, number
end


return Monitor