local _M = {}
function _M.get_user_ip()
    local uip 
    local xff = ngx.var.http_x_forwarded_for
    if xff ~= nil then
        uip = string.gsub(xff, ",.*", "")
        return uip
    end
    if uip == nil then
        local xri = ngx.var.http_x_real_ip
        if xri ~= nil then
            uip = string.gsub(xri, ",.*", "")
            return uip
        end
    end
    if uip == nil then
        uip = ngx.var.remote_addr
        return uip
    end
    return "unknown"
end

function _M.is_uip_in_whitelist(uip)
    local iputils = require("iputils")
    return iputils.ip_in_cidrs(uip, IPWhitelist)
end

function _M.split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

function _M.trim(s)
   return s:match'^%s*(.*%S)' or ''
end
return _M
