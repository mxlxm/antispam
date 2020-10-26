-- all timeout unit: ms
redis = {
    host = "127.0.0.1",
    port = 6379,
    connectTimeout = 100,
    sendTimtout = 200,
    readTimeout = 500,
    poolsize = 100,
    idleTimtout = 60000,
    mode = "pipeline",
}

ip_whitelist = {
    "127.0.0.1",
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/24",
}

ttl = 60 -- seconds to validate

-- rule key must have defined rule func in antispam.lua
ban_rules = {
    -- up to 50req/60s per user_ip
    ["get_user_ip"] = 50,
    -- up to 10req/60s per user_ip+uri
    ["get_user_ip..ngx.var.uri"] = 10,
    -- up to 10req/60s per user_token from header
    ["ngx.var.http_user_token"] = 10,
}
