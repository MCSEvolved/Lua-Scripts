local CraftItem = require("@types.shared.CraftItem")

local record ItemResult
    name: string
    fingerprint: string|nil
    amount: number
    displayName: string
    isCraftable: boolean
    nbt: string|nil
    tabs: table
end

local record CraftingCPU
    storage: number
    coProcessor: number
    isBusy: boolean
end

local enum ECellType
    "item"
    "fluid"
end

local record CellResult
    item: string
    cellType: ECellType
    bytesPerType: integer
    totalBytes: integer
end

local record MEBridge
    craftItem: function(item: CraftItem, craftingCpu: string|nil): (boolean, string|nil)
    craftFluid: function(fluid: CraftItem, craftingCpu: string|nil): (boolean, string|nil)
    getItem: function(item: CraftItem): (ItemResult, string|nil)
    importItem: function(item: CraftItem, direction: string): (number, string|nil)
    exportItem: function(item: CraftItem, direction: string): (number, string|nil)
    importItemFromPeripheral: function(item: CraftItem, container: string): (number, string|nil)
    exportItemToPeripheral: function(item: CraftItem, container: string): (number, string|nil)
    getEnergyStorage: function(): (number, string|nil)
    getMaxEnergyStorage: function(): (number, string|nil)
    getEnergyUsage: function(): (number, string|nil)
    getCraftingCPUs: function(): ({CraftingCPU}, string|nil)
    isItemCrafting: function(item: CraftItem, craftingCpu: string|nil): (boolean, string|nil)
    isItemCraftable: function(item: CraftItem): (boolean, string|nil)
    listCraftableItems: function(): ({ItemResult}, string|nil)
    listCraftableFluids: function(): ({ItemResult}, string|nil)
    listItems: function(): ({ItemResult}, string|nil)
    listFluid: function(): ({ItemResult}, string|nil)
    listCells: function(): ({CellResult}, string|nil)
    getTotalItemStorage: function(): (integer, string|nil)
    getTotalFluidStorage: function(): (integer, string|nil)
    getUsedItemStorage: function(): (integer, string|nil)
    getUsedFluidStorage: function(): (integer, string|nil)
    getAvailableItemStorage: function(): (integer, string|nil)
    getAvailableFluidStorage: function(): (integer, string|nil)
end

return MEBridge