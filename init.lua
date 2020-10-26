require "config"

-- init prison
local prison = ngx.shared.prison
-- make prison global
_G.Prison = prison

-- init ip whitelist
local iputils = require("iputils")
ipwhitelist = iputils.parse_cidrs(ip_whitelist)
_G.IPWhitelist = ipwhitelist

-- init rules
local ngxrules = ngx.shared.rules
for k,v in pairs(ban_rules) do
    ngxrules:set(k,v)
end
