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

r:flushall()
r:set_keepalive(redis.idleTimeout, redis.poolsize)
Prison:flush_all()
ngx.say("done")
return ngx.exit(ngx.OK)
