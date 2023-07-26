local type instruments = enum
    "harp"
    "basedrum"
    "snare"
    "hat"
    "bass"
    "flute"
    "bell"
    "guitar"
    "chime"
    "xylophone"
    "iron_xylophone"
    "cow_bell"
    "didgeridoo"
    "bit"
    "banjo"
    "pling"
end

local record Speaker
    playNote: function(instrument: instruments, volume: number|nil, pitch: number|nil): boolean
    playSound: function(name: string, volume: number|nil, pitch: number|nil): boolean
    playAudio: function(audio: {number}, volume: number|nil): boolean
    stop: function()
end


return Speaker