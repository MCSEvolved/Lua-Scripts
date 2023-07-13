local record MultiShell
    getFocus: function(): number
    setFocus: function(n: number): boolean
    getTitle: function(n: number): string|nil
    setTitle: function(n: number, title: string)
    getCurrent: function(): number
    launch: function(tProgramEnv: table, sProgramEnv: string, ...:{any}): number
    getCount: function(): number
end

return MultiShell