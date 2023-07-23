
global record rednet
    CHANNEL_BROADCAST: integer
    CHANNEL_REPEAT: integer
    MAX_ID_CHANNELS: integer
    open: function(modem: string)
    close: function(modem: string|nil)
    isOpen: function(modem: string|nil)
    send: function(recipient: number, message: any, protocol: string|nil)
    broadcast: function(message: string, protocol: string|nil)
    receive: function(protocol_filter: string|nil, timeout: number|nil): number|nil, any|nil, string|nil
    host: function(protocol: string, hostname: string)
    unhost: function(protocol: string)
    lookup: function(protocol: string, hostname: string|nil): number...
    run: function()
end