require "config"

-- init redis client
local r = (require "resty.redis"):new()
r:set_timeouts(redis.connectTimeout,redis.sendTimeout,redis.readTimeout)
local ok, err = r:connect(redis.host, redis.port)
if not ok then
    ngx.log(ngx.ERR, "connect to redis failed: " .. err)
    -- continue use local shm
end

-- redis auth if present
if redis.pass ~= nil then
    local resp, err = r:auth(redis.pass)
    if not resp then
        ngx.log(ngx.ERR, "redis auth failed:" .. err)
    end
end

local key = ngx.var.arg_key
if not key then
    return ngx.exit(ngx.HTTP_BAD_REQUEST)
end
r:del(key)
r:set_keepalive(redis.idleTimeout, redis.poolsize)
Prison:delete(key)
ngx.say("done")
return ngx.exit(ngx.OK)
