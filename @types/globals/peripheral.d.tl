local Peripheral_Type = require("@types.shared.peripheralTypes")

global record peripheral
    getNames: function(): {string}
    isPresent: function(name: string): boolean
    getType: function<T>(peripheral: string|T): nil|Peripheral_Type...
    hasType: function<T>(peripheral: string|T, peripheral_type: Peripheral_Type): boolean|nil
    getMethods: function(name: string): {string}|nil
    getName: function<T>(peripheral: T): string
    call: function(name: string, method: string, ...: {any}): any...
    wrap: function<T>(name: string): T|nil
    find: function<T>(ty: string, filter: function(name: string, wrapped: T): (boolean)): nil|T...
end