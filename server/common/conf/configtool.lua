--配置文件的热更新

local skynet = require "skynet"
local cjson = require "cjson"
local sharedata = require "sharedata"
local skynet_core = require "skynet.core"
local lfs = require "lfs"
require 'debug'
---------------------------------------------------------------

local dgetinfo = debug.getinfo
local open_path = open_path

local init = true

local ConfigTool = class()

function ConfigTool:ctor()
    self.file_list = {} -- temp file list
    self.func_list = {} -- 调用shardData的上层函数作为key
    self.alter = {}    
end

--http://www.mamicode.com/info-detail-1791598.html
--getinfo(level, arg), level=（0:getinfo自身，1：调用getinfo的函数f1，2：调用f1的函数f2,...以此类推。f1, f2, ...也可能不是函数，而是在文件中直接调用getinfo）
function ConfigTool:shareData(share_name , data)
    print('load sharedata:'..share_name)
    if init then
        self.func_list[dgetinfo(2).func] = self.file_list
        self.file_list = {}
        sharedata.new(share_name, data)
    else
        -- print("____________111111__update__________",data)
        sharedata.update(share_name, data)
    end
end

function ConfigTool:begin( ... )
    self.file_list = {}
end

function ConfigTool:finish()
    init = false
    --热更新定时器
    local function hotLoad()
        while true do
            for share_fun,file_list in pairs(self.func_list) do
                for _, info in ipairs(file_list) do
                    if info[2] ~= getFileTime(info[1]) then
                        info[2] = getFileTime(info[1])
                        self.alter[share_fun] = true
                    end
                end
            end
            if next(self.alter) then
                for share_fun,_ in pairs(self.alter) do
                    share_fun()
                end
                self.alter = {}
            end
            --
            skynet.sleep(500)
        end
    end    
    skynet.fork(hotLoad)
end

--添加文件
function ConfigTool:addFile(file)    
    local data = loadLuaFile(file)    
    if data then    
        local info = {file, getFileTime(file)}
        table.insert(self.file_list,info)
        return data
    end
    return nil
end

----------------------------------------------------------------------



return ConfigTool