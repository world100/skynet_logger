--
-- @Author:      name
-- @DateTime:    2018-04-20 21:48:12
-- @Description: 服务器节点配置读取

local skynet = require "skynet"
local cluster = require "cluster"
local config = require "configquery"

skynet.start(function()
	skynet.uniqueservice("confcenter")

	
	--集群管理服务
	local cluster_manager = skynet.uniqueservice("cluster_service")
	skynet.call(cluster_manager, "lua", "start")	
	
	--主服务
	local manager = skynet.uniqueservice(true,"manager_service")
	skynet.call(manager, "lua", "start")
	
    skynet.exit()
end)

