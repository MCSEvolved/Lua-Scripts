local record Help
    path: function(): string
    setPath: function(newPath: string)
    lookup: function(topic: string): string|nil
    topics: function(): {string}
    completeTopic: function(prefix: string): {string}
end

return Help