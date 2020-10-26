## antispam

ngx.shared.dict based access control.
use redis to share data with each others.

### usage 
---

```nginx
http {
    lua_shared_dict prison 500m;
    lua_shared_dict rules 10m;

    lua_package_path '/path/to/antispam/?.lua;;';
    init_by_lua_file /path/to/antispam/init.lua;    

    ...

    server {
        access_by_lua_file /path/to/antispam/antispam.lua;

        ...

        location ~* /antimanage/(ban|delete|purge) {
            allow 10.0.0.0/8;
            deny all;
            content_by_lua_file /path/to/antispam/$1.lua;
        }
    }
}
```

### config
---

see config.lua

### rules
---

* add rule in config.lua
* add rule func in antispam.lua

### manual control
---

* ban
```bash
curl http://0:80/antimanage/ban?key=xxxx&ttl=500
```
> key required, ip/token/ip+uri ...   
> ttl optional, seconds to ban

* delelte
```bash
curl http://0:80/antimanage/delete?key=xxxx
```
> key required,ip/token/ip+uri ...

* purge
```bash
curl http://0:80/antimanage/purge
```
