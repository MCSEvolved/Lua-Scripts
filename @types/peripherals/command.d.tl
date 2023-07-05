local record Command
    getCommand: function(): string
    setCommand: function(command: string)
    runCommand: function(): boolean, string|nil
end


return Command