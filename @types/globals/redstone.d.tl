global record redstone
    getSides: function(): string...
    setOutput: function(side: string, on: boolean)
    getOutput: function(side: string): boolean
    getInput: function(side: string): boolean
    setAnalogOutput: function(side: string, value: number) 
    setAnalogueOutput: function(side: string, value: number)
    getAnalogOutput: function(side: string): number
    getAnalogueOutput: function(side: string): number
    getAnalogInput: function(side: string): number
    getAnalogueInput: function(side: string): number
    setBundledOutput: function(side: string, output: number)
    getBundledInput: function(side: string): number
    testBundledInput: function(side: string, mask: number): boolean
end