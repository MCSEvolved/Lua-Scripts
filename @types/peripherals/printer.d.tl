local record Printer
    write: function(text: string)
    getCursorPos: function(): integer, integer
    setCursorPos: function(x: integer, y: integer)
    getPageSize: function(): integer, integer
    newPage: function(): boolean
    endPage: function(): boolean
    setPageTitle: function(title: string|nil)
    getInkLevel: function(): number
    getPaperLevel: function(): integer
end


return Printer