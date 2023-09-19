local record Computer
    turnOn: function()
    shutdown: function()
    reboot: function()
    getID: function(): integer
    isOn: function(): boolean
    getLabel: function(): string|nil
end


return Computer