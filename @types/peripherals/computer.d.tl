local record Computer
    turnOn: function()
    shutdown: function()
    reboot: function()
    getId: function(): integer
    isOn: function(): boolean
    getLabel: function(): string|nil
end


return Computer