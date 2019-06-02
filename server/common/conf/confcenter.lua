--
-- Author:      name
-- DateTime:    2018-04-21 15:27:55
-- Description: 服务间共享配置数据

local skynet = require "skynet"
local ConfigTool = require "configtool"
---------------------

---------------------

local config_tool = ConfigTool.new()
--配置文件路径
local config_path = skynet.getenv("config_root")	


--服务器配置
local function loadServerSetting( )
	local data = config_tool:addFile(config_path.."setting/server_setting.lua")
	config_tool:shareData("setting_cfg", data)
end

--游戏配置
local function loadGameSetting( ... )
	local data = config_tool:addFile(config_path.."setting/game_setting.lua")
	config_tool:shareData("game_setting", data)	
end


--服务开始
skynet.start(function()
	config_tool:begin()
	loadServerSetting()
	loadGameSetting()

	config_tool:finish()
end)