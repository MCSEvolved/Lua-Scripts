local Peripheral_Type = require("@types.peripherals.peripheralTypes")

local record Peripheral_Instance

end

local record Peripheral
    getNames: function(): {string}
    isPresent: function(name: string): boolean
    getType: function(peripheral: string|Peripheral_Instance): nil|Peripheral_Type...
    hasType: function(peripheral: string|Peripheral_Instance, peripheral_type: Peripheral_Type): boolean|nil
    getMethods: function(name: string): {string}|nil
    getName: function(peripheral: Peripheral_Instance): string
    call: function(name: string, method: string, ...: {any}): any...
    wrap: function(name: string): Peripheral_Instance|nil
    find: function(ty: string, filter: function(name: string, wrapped: Peripheral_Instance): boolean): nil|Peripheral_Instance...
end

return Peripheral