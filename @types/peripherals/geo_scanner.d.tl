local record BlockProperties
    name: string
    tags: {string}
    x: number
    y: number
    z: number
end

local record GeoScanner
    getFuelLevel: function(): number
    getFuelMaxLevel: function(): number
    cost: function(radius: number): number
    scan: function(radius: number): ({BlockProperties} | nil, string)
    getScanCooldown: function()
    chunkAnalyze: function()
end

return GeoScanner