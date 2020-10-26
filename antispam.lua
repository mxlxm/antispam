local utils = require "utils"
-- whitelist check first
local uip = utils.get_user_ip()
if utils.is_uip_in_whitelist(uip) then
    -- continue to the real handler
    ngx.exit(ngx.OK)
end

-- not in whitelist
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

-- provide two redis mode
-- use pipeline for less redis key blocking
-- use transaction for more precise rate control 
local redisMode = {
    ["pipeline"] = function(key, ttl)
        r:init_pipeline(2)
        r:incr(key)
        r:expire(key,ttl)
        local ans, err = r:commit_pipeline()
        if not ans then
            ngx.log(ngx.ERR, "redis pipeline failed to commit: ", err)
        end
    end,
    ["transaction"] = function(key, ttl)
        local ok, err = r:multi()
        if not ok then
            ngx.log(ngx.ERR, "redis failed to run multi: ", err)
        end
        r:incr(key)
        r:expire(key,ttl)
        local ans, err = r:exec()
        if not ans then
            ngx.log(ngx.ERR, "redis transaction failed to exec: ", err)
        end
    end,
}

-- redis communication
local function redisCheck(key, threshold)
    local resp, err = r:get(key)
    if not resp then
        ngx.log(ngx.ERR, "get from redis failed: ", err, "key: ", key)
        return false
    end
    if not tonumber(resp) then
        resp = 0
    end
    if resp ~= ngx.null then
        -- keep all nginx instance shm synced
        Prison:set(key,resp+1,ttl)
    end
    if resp == ngx.null or tonumber(resp) < threshold then
        redisMode[redis.mode](key,ttl)
        return false
    end
    if tonumber(resp) >= threshold then
        ngx.log(ngx.ERR, "hit from redis: ", key, " count: ", resp)
        return true
    end
end

-- check local shm first 
-- drilldown to redis if not found or less than threshold
local function prisonCheck(key, threshold) 
    local value = Prison:get(key)
    if value == nil then
        Prison:incr(key, 1, 0, ttl)
        return redisCheck(key, threshold)
    end
    if tonumber(value) >= threshold then
        Prison:incr(key, 1, value, ttl)
        ngx.log(ngx.ERR, "hit from local shm: ", key, " count: ", value)
        return true
    end
    if tonumber(value) < threshold then
        Prison:incr(key, 1, value, ttl)
        return redisCheck(key, threshold)
    end
end

-- build rule func table 
-- use this key to take control
local rulefuncs = {
    ["get_user_ip"] = function(threshold)
        return prisonCheck(utils.get_user_ip(),threshold)        
    end,
    ["get_user_ip..ngx.var.uri"] = function(threshold)
        return prisonCheck(utils.get_user_ip()..ngx.var.uri,threshold)
    end,
    ["ngx.var.http_user_token"] = function(threshold)
        local token = ngx.var.http_user_token
        if not token or token == ngx.null then
            return false
        end
        return prisonCheck(ngx.var.http_user_token,threshold)
    end,
}

-- iterator all rules
local rules = ngx.shared.rules
local keys = rules:get_keys()
for _,key in pairs(keys) do 
    -- get rule func
    local func = rulefuncs[key]
    if func then
        -- exec rule func
        local banned = func(rules:get(key))
        if banned then
            r:set_keepalive(redis.idleTimeout, redis.poolsize)
            return ngx.exit(ngx.HTTP_FORBIDDEN)
        end
    else
        ngx.log(ngx.ERR, "undefined ban func: ", key)
    end
end
r:set_keepalive(redis.idleTimeout, redis.poolsize)
