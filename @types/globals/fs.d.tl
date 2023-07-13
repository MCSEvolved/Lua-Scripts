local EMode = require("@types.shared.Mode")
local EWhence = require("@types.shared.Whence")

local record FileHandle
    read: nil|function(count: integer|nil): nil|integer|string
    readLine: nil|function(withTrailing: boolean|nil): string|nil
    readAll: nil|function(): string|nil
    
    write: nil|function(text: string|integer)
    writeLine: nil|function(text: string)
    flush: nil|function()

    seek: nil|function(whence: EWhence|nil, offset: integer|nil): (nil, string)|integer

    close: function()
end

local record Options 
    include_files: boolean|nil
    include_dirs: boolean|nil
end

local record Attributes
    size: integer
    isDir: boolean
    isReadOnly: boolean
    created: number
    modified: number
end

local record Fs
    complete: function(path: string, location: string, include_files: boolean|nil|Options, include_dirs: boolean|nil): {string}
    find: function(path: string): {string}
    isDriveRoot: function(path: string): boolean
    list: function(path: string): {string}
    combine: function(path: string, ...:{string}): string
    getName: function(path: string): string
    getDir: function(path: string): string
    getSize: function(path: string): integer
    exists: function(path: string): boolean
    isDir: function(path: string): boolean
    isReadOnly: function(path: string): boolean
    makeDir: function(path: string)
    move: function(path: string, dest: string) 
    copy: function(path: string, dest: string)
    delete: function(path: string)
    open: function(path: string, mode: EMode): (nil, string)|FileHandle
    getDrive: function(path: string): string|nil
    getFreeSpace: function(path: string): integer
    getCapacity: function(path: string): integer|nil
    attributes: function(path: string): Attributes
end

return Fs