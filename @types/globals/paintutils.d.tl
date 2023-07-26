global record paintutils
    parseImage: function(image: string): table
    loadImage: function(path: string): table|nil
    drawPixel: function(xPos: number, yPos: number, color: integer)
    drawLine: function(startX: number, startY: number, endX: number, endY: number, color: integer)
    drawBox: function(startX: number, startY: number, endX: number, endY: number, color: integer)
    drawFilledBox: function(startX: number, startY: number, endX: number, endY: number, color: integer)
    drawImage: function(image: table, xPos: number, yPos: number)
end