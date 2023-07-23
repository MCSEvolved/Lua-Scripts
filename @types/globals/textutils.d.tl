local record Opts
    compact: boolean|nil
    allow_repetitions: boolean|nil
end

local record Options
    allow_repetitions: boolean|nil
    unicode_strings: boolean|nil
end

local record JSONOptions
    nbt_style: boolean|nil
    parse_null: boolean|nil
    parse_empty_array: boolean|nil
end

global record textutils
    slowWrite: function(text: string, rate: number|nil)
    slowPrint: function(sText: string, nRate: number|nil)
    formatTime: function(nTime: number, bTwentyFourHour: boolean|nil): string
    pagedPrint: function(text: string, free_lines: number|nil): number
    tabulate: function(...: {string})
    pagedTabulate: function(...: {string}|number)
    empty_json_array: table
    json_null: table
    serialize: function(t: any, opts: Opts): string
    serialise: function(t: any, opts: Opts): string
    unserialize: function(s: string): any
    unserialise: function(s: string): any
    serializeJSON: function(t: any, options: Options): string
    serialiseJSON: function(t: any, options: Options): string
    unserializeJSON: function(s: string, options: JSONOptions): any|nil, string|nil
    unserialiseJSON: function(s: string, options: JSONOptions): any|nil, string|nil
    urlEncode: function(str: string): string
    complete: function(sSearchText: string, tSearchTable: table|nil): {string}
end