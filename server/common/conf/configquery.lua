-- 配置内容缓存在服务里

local sharedata = require "sharedata"

local config = {}
local buff = {}

local config_mt = {
    __index = function(t, k)
        local cfg = buff[k] --sharedata.update 后 buff[k]会跟变
        if cfg == nil then            
            cfg = sharedata.query(k)
            buff[k] = cfg
        end
        return cfg        
    end
}
setmetatable(config, config_mt)



return config