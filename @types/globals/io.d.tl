local record Handle
    close: function(handle: Handle): (boolean|nil, string|nil)
    flush: function(handle: Handle)
    lines: function(handle: Handle, ...: string|nil): (function(): (string)|nil)
    read: function(handle: Handle, ...: string|nil): (string|nil)
    seek: function(handle: Handle, whence: string|nil, offset: number|nil): number
    write: function(handle: Handle, ...: string|number): (Handle|nil, string|nil)
end

global record io
    stdin: Handle
    stdout: Handle
    stderr: Handle
    close: function(file: Handle)
    flush: function()
    input: function(file: Handle|string): Handle
    lines: function(filename: string|nil, ...: string): (function(): (string)|nil)
    open: function(filename: string, mode: string): (Handle|nil, string|nil)
    output: function(file: Handle|string): Handle
    read: function(...: string|nil): (string|nil)
    type: function(obj: Handle|any): (string|nil)
    write: function(...: string)
end