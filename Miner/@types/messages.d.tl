local record DockingGrantedMessage
    action: string
    targetY: number
end

local record ActionMessage
    action: string
end

return {DockingGrantedMessage, ActionMessage}