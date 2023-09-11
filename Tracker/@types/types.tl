local Coordinates = require("@types.shared.Location")


local record Message
    messageType: MessageType
    messageSource: MessageSource
    content: string
    metadata: any|nil
    sourceId: string
end

local enum TrackerMessageType 
    "MESSAGE"
    "COMPUTER"
    "COMMAND"
    "LOCATION"
end

local enum MessageType
    "Info"
    "Warning"
    "Error"
    "Debug"
    "OutOfFuel"
end

local enum MessageSource
    "Computer"
    "Pocket"
    "Turtle"
end

local record Information
    id: integer
    label: string
    systemId: integer
    status: string
    device: ComputerDevice
    fuelLevel: number
    fuelLimit: number
    hasModem: boolean
end

local enum ComputerDevice
    "Turtle"
    "Advanced_Turtle"
    "Computer"
    "Advanced_Computer"
    "Pocket_Computer"
    "Advanced_Pocket_Computer"

end

local record Location
    computerId: integer
    coordinates: Coordinates
    dimension: Dimension
end

local enum Dimension
    "Overworld"
    "Nether"
    "End"
    "Unknown"
end

local record CommandAction
    computerId: integer
    command: Command
end

local enum Command
    "STOP"
    "REBOOT"
end


return {Message, MessageType, MessageSource, Information, ComputerDevice, TrackerMessageType, Location, Dimension, Command, CommandAction}