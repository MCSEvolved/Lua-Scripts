global record gps
    CHANNEL_GPS: integer
    locate: function(timeout: integer|nil, debug: boolean|nil): number|nil, number|nil, number|nil
end