global record term
    nativePaletteColour: function(colour: integer): number, number, number
    nativePaletteColor: function(colour: integer): number, number, number
    write: function(text: string)
    scroll: function(y: integer)
    getCursorPos: function(): integer, integer
    setCursorPos: function(x: integer, y: integer)
    getCursorBlink: function(): boolean
    setCursorBlink: function(blink: boolean)
    getSize: function(): number, number
    clear: function()
    clearLine: function()
    getTextColour: function(): integer
    getTextColor: function(): integer
    setTextColour: function(colour: integer)
    setTextColor: function(color: integer)
    getBackgroundColour: function(): integer
    getBackgroundColor: function(): integer
    setBackgroundColour: function(): integer
    setBackgroundColor: function(): integer
    isColour: function(): boolean
    isColor: function(): boolean
    blit: function(text: string, textColor: string, backgroundColor: string)
    setPaletteColour: function(index: integer, R: number, G: number, B: number)
    setPaletteColour: function(index: integer, color: integer)
    setPaletteColor: function(index: integer, R: number, G: number, B: number)
    setPaletteColor: function(index: integer, color: integer)
    getPaletteColour: function(colour: integer): number, number, number
    getPaletteColor: function(color: integer): number, number, number
    redirect: function(target: any): any
    current: term
    native: term
end