local EPeripheral = require("@types.shared.peripheralTypes")

local record Modem
    open: function(channel: integer)
    isOpen: function(channel: integer): boolean
    close: function(channel: integer)
    closeAll: function()
    transmit: function(channel: integer, replyChannel: integer, payload: table)
    isWireless: function(): boolean
    getNamesRemote: function(): {string}
    isPresentRemote: function(name: string): boolean
    getTypeRemote: function(name: string): string|nil
    hasTypeRemote: function(name: string, type: EPeripheral): boolean|nil
    getMethodsRemote: function(name: string): {string}| nil
    callRemote: function(remoteName: string, method: string, ...: any): any...
    getNameLocal: function(): string|nil
end


return Modem