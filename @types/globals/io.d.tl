local EMode = require("@types.shared.Mode")
local EWhence = require("@types.shared.Whence")

local enum EFormat
    "l"
    "L"
    "a"
end

local record Handle
    close: function()
    flush: function()
    lines: function(...:{EFormat}|nil): nil|function(): string
    read: function(...:{EFormat}|nil): string|nil
    seek: function(whence: EWhence|nil, offset: integer|nil): integer
    write: function(...:{string|number}): (nil, string)|Handle
end

local enum EHandleType
    "file"
    "closed file"
end

local record IO
    stdin: Handle
    stdout: Handle
    stderr: Handle
    close: function(file: Handle|nil)
    flush: function()
    input: function(file: Handle|string|nil): Handle
    lines: function(filename: string|nil, ...:{EFormat}|nil): nil|function(): string
    open: function(filename: string, mode: EMode): (nil, string)|Handle
    output: function(file: Handle|string|nil): Handle
    read: function(...:{string}|nil): string|nil
    type: function(obj: any): EHandleType|nil
    write: function(...:{string}|nil)
end

return IO