local record FluidStorage
    tanks: function(): {table|nil}
    pushFluid: function(toName: string, limit: number|nil, fluidName: string|nil): number
    pullFluid: function(fromName: string, limit: number|nil, fluidName: string|nil): number
end


return FluidStorage