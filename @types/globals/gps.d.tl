local record GPS
    CHANNEL_GPS: integer
    locate: function(timeout: integer|nil, debug: boolean|nil): (number, number, number)|nil
end

return GPS