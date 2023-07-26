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

return {DockingGrantedMessage, ActionMessage, InventoryMessage}