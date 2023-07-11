local record Disk
    isPresent: function(name: string): boolean
    getLabel: function(name: string): string|nil
    setLabel: function(name: string, label: string)
    hasData: function(name: string): boolean
    getMountPath: function(name: string): string|nil
    hasAudio: function(name: string): boolean
    getAudioTitle: function(name: string): string|boolean|nil
    playAudio: function(name: string)
    stopAudio: function(name: string)
    eject: function(name: string)
    getID: function(name: string): string|nil
end

return Disk