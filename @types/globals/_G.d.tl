global record _G
    sleep: function(time: number)
    write: function(text: string): integer
    print: function(...: string): integer
    printError: function(...: string)
    read: function(replaceChar: string|nil, history: table|nil, completeFn: function(partial: string): ({string}) | nil, default: string|nil): string
    _HOST: string
    _CC_DEFAULT_SETTINGS: string
end