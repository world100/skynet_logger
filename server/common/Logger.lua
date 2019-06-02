-- 发送记录到日记服务器
-- Logger.lua
-- 
-- 

local skynet = require "skynet"
local cluster 

local Logger = { _version = "0.1.0" }

local svr_id = tonumber(skynet.getenv("svr_id")) --服务器id
local svr_name = skynet.getenv("svr_name") --服务器类型
local cluster_name = svr_name.."_"..svr_id
Logger.logfile = skynet.getenv("logger_file")
Logger.level = skynet.getenv("logger_level") or "trace"
Logger.level = 'debug'

--不同级别对应的文件
local modes = {    
    { name = "debug", file = Logger.logfile.."debug.log"},
    { name = "info", file = Logger.logfile.."info.log"},
    { name = "warn",  file = Logger.logfile.."warn.log"},
    { name = "error", file = Logger.logfile.."error.log"},
    { name = "fatal", file = Logger.logfile.."fatal.log"},
}

local levels = {}
for i, v in ipairs(modes) do
    levels[v.name] = i
end

local function x_pcall(f, ...)
    return xpcall(f, debug.traceback, ...)
end

function Logger.sendData(name, ...)
    local level = levels[name]
    local filePath = Logger.logfile
    -- 日记级别设置
    if level < levels[Logger.level] then
        return 
    end
    local message_list = { ... }
    local msg_num = #message_list    
    local message_str
    if msg_num == 1 then
        message_str = tostring(message_list[1])
    elseif msg_num > 1 then
        local temp = {}
        for i=1, msg_num do
            local v = message_list[i]
            table.insert(temp, tostring(v))
            table.insert(temp, ' ')
        end
        message_str = table.concat(temp)
    else
        return
    end
    local info = debug.getinfo(2, "Sl") --调用此函数的信息
    local lineinfo = info.short_src .. ":" .. info.currentline
    local str = string.format("%s[:%08x][%s][%s][%s] %s\n",cluster_name, skynet.self(), name, os.date("%Y-%m-%d %X"), lineinfo, message_str)
    skynet.error(str)
    if not cluster then 
       cluster = require "cluster"
    end
    local ok, result = x_pcall(cluster.send,'loggerserver_1','.proxy',name,filePath,str)
    if not ok then
        skynet.error("##########__Logger.lua__发送记录失败_",message_str)
    end
end

function Logger.debug(...)
    Logger.sendData("debug", ...)
end
function Logger.info(...)
    Logger.sendData("info", ...)
end
function Logger.warn(...)
    Logger.sendData("warn", ...)
end
function Logger.error(...)
    Logger.sendData("error", ...)
end
function Logger.fatal(...)
    Logger.sendData("fatal", ...)
end

return Logger