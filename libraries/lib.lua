AUTHCHANNEL = 443

---Returns a success boolean and a Firebase Access Token when successful and an error when not
---@return boolean success
---@return string
---@param withBearer boolean|nil
function GetAuthToken(withBearer)
    local modem = peripheral.find("modem", function (_, o)
        return o.isWireless()
     end)

     if withBearer == nil then
        withBearer = false
     end
  
     modem.open(AUTHCHANNEL)

     while true do
        modem.transmit(AUTHCHANNEL, AUTHCHANNEL, "REQUEST_TOKEN")
        local _,_,channel,_,response = os.pullEvent("modem_message")
        if channel == AUTHCHANNEL and response.token then
            modem.close(AUTHCHANNEL)
            if withBearer then
                return true, "bearer "..response.token
            end
           return true, response.token
        elseif channel == AUTHCHANNEL and response.error then
            modem.close(AUTHCHANNEL)
            return false, response.error
        end
     end
end