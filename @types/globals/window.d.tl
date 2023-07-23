local record Window
    write: function(sText: string)
    blit: function(sText: string, sTextColor: string, sBackgroudColor: string)
    clear: function()
    clearLine: function()
    getCursorPos: function(): integer, integer
    setCursorPos: function(x: integer, y: integer)
    getCursorBlink: function(): boolean
    setCursorBlink: function(blink: boolean)
    isColor: function(): boolean
    isColour: function(): boolean
    setTextColor: function(color: integer)
    setTextColour: function(colour: integer)
    setPaletteColour: function(colour: integer)
    setPaletteColor: function(color: integer)
    getPaletteColour: function(): integer
    getPaletteColor: function(): integer
    setBackgroundColor: function(color: integer)
    setBackgroundColour: function(colour: integer)
    getSize: function(): integer, integer
    scroll: function(y: integer)
    getTextColor: function(): integer
    getTextColour: function(): integer
    getBackgroundColor: function(): integer
    getBackgroundColour: function(): integer
    getLine: function(y: integer): string, string, string
    setVisible: function(visible: boolean)
    isVisible: function(): boolean
    redraw: function()
    restoreCursor: function()
    getPosition: function(): integer, integer
    reposition: function(new_x: integer, new_y: integer, new_width: integer|nil, new_height: integer|nil, new_parent: any)
end

global record window
    create: function(parent: any, nX: integer, nY:integer, nWidth:integer, nHeight:integer, bStartVisible: boolean|nil): Window
end