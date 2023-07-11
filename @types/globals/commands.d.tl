local record AsyncCommands
    exec: function(command: string): number
    list: function(subCommand: string): number
    getBlockPosition: function(): number
    getBlockInfos: function(minX: integer, minY: integer, minZ: integer, maxX: integer, maxY: integer, maxZ: integer, dimension: string|nil): number 
    getBlockInfo: function(x: integer, y: integer, z: integer): number 
end

local record Commands
    exec: function(command: string): boolean, {string}, number|nil 
    execAsync: function(command: string): number
    list: function(subCommand: string): {string} 
    getBlockPosition: function(): integer, integer, integer
    getBlockInfos: function(minX: integer, minY: integer, minZ: integer, maxX: integer, maxY: integer, maxZ: integer, dimension: string|nil): {table} 
    getBlockInfo: function(x: integer, y: integer, z: integer): table 
    native: Commands
    async: AsyncCommands
end

return Commands