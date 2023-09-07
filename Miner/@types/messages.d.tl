local Location = require("@types.shared.Location")

local record DockingGrantedMessage
    action: string
    targetY: number
end

local record ActionMessage
    action: string
end

local record InventoryMessage
    action: string
    inventory: {{string: any}}
end

local record MovementMessage
    action: string
    direction: string
    location: Location
end

return {DockingGrantedMessage, ActionMessage, InventoryMessage, MovementMessage}