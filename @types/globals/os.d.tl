
global record os
    pullEvent: function(filter: string): string, any...
    pullEventRaw: function(filter: string): string, any...
    sleep: function(timer: number)
    version: function(): string
    run: function(env: table, path: string, ...: any): boolean
    queueEvent: function(name: string, ...: any)
    startTimer: function(timer: number): number
    cancelTimer: function(token: number)
    setAlarm: function(time: number): number
    cancelAlarm: function(token: number)
    shutdown: function()
    reboot: function()
    getComputerID: function(): integer
    computerID: function(): integer
    getComputerLabel: function(): string|nil
    computerLabel: function(): string|nil
    setComputerLabel: function(label: string|nil)
    clock: function(): number
    time: function(locale: string|table|nil): any
    day: function(args: string): number
    epoch: function(args: string): number
    date: function(format: string, time: number): any
end