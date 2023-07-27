local record GetRequest
    url: string
    headers: {string: string}|nil
    binary: boolean|nil
    method: string|nil
    redirect: boolean|nil
    timeout: number|nil
end

local record PostRequest
    url: string
    body: string
    headers: {string: string}|nil
    binary: boolean|nil
    method: string|nil
    redirect: boolean|nil
    timeout: number|nil
end

local record Response
    getResponseCode: function(): number, string
    getResponseHeaders: function(): {string: string}
end

global record http
    get: function(url: string|GetRequest, headers: {string: string}|nil, binary: boolean|nil): (nil, string, Response|nil)|Response
    post: function(url: string|PostRequest, body: string|nil, headers: {string:string}|nil, binary: boolean|nil): (nil, string, Response|nil)|Response
    request: function()
    checkURLAsync: function()
    checkURL: function()
    websocketAsync: function()
    websocket: function()
end