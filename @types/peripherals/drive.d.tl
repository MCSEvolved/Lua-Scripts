local record Drive
    isDiskPresent: function(): boolean
    getDiskLabel: function(): string|nil
    setDiskLabel: function(label: string|nil)
    hasData: function(): boolean
    getMountedPath: function():string|nil
    hasAudio: function(): boolean
    getAudioTitle: function(): string|nil|boolean
    playAudio: function()
    stopAudio: function()
    ejectDisk: function()
    getDiskID: function(): integer|nil
end


return Drive