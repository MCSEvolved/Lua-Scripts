local record CompletionInfo
    fnComplete: function
end

global record shell
    execute: function(command: string, ...: {string}): boolean
    run: function(...: string): boolean
    exit: function()
    dir: function(): string
    setDir: function(dir: string)
    path: function(): string
    setPath: function(path: string)
    resolve: function(path: string)
    resolveProgram: function(program: string): string|nil
    programs: function(include_hidden: boolean|nil): {string}
    complete: function(sLine: string): {string}|nil
    completeProgram: function(program: string): {string}
    setCompletionFunction: function(program: string, complete: function(shell: table, index: number, argument: string, previous: {string}): ({string}|nil))
    getCompletionInfo: function(): {string:CompletionInfo}
    getRunningProgram: function(): string
    setAlias: function(command: string, program: string)
    clearAlias: function(command: string)
    aliases: function(): {string:string}
    openTab: function(...: string)
    switchTab: function(id: number)
end