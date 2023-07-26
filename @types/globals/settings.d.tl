local record Options
    description: string|nil
    default: any
    type: string|nil
end

global record settings
    define: function(name: string, options: Options|nil)
    undefine: function(name: string)
    set: function(name: string, value: any)
    get: function(name: string, default: any): any
    getDetails: function(name: string): Options
    unset: function(name: string)
    clear: function()
    getNames: function(): string...
    load: function(sPath: string|nil): boolean
    save: function(sPath: string|nil): boolean
end