local EEvent = require("@types.shared.Event")

global record os
    pullEvent: function(filter: EEvent): EEvent, any...
    pullEventRaw: function(filter: EEvent): EEvent, any...
    sleep: function(timer: number)
    version: function(): string
    run: function(env: table, path: string, ...: any): boolean
    queueEvent: function(name: EEvent, ...: any)
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