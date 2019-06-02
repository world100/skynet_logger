--
-- Author:      name
-- DateTime:    2018-04-23 17:19:33
-- Description: 服务管理


require "skynet.manager"
local skynet = require "skynet"
local cluster = require "cluster"

local Objects = require "Objects"
local MessageDispatch = require "MessageDispatch"
local NodeMessage = require "NodeMessage"
local ClusterManager = require "ClusterManager"

g_objects = Objects.new()

local function init()

	local message_dispatch = MessageDispatch.new()	
	local node_message = NodeMessage.new()
	local cluster_manager = ClusterManager.new(message_dispatch, node_message)
	
	g_objects:add(cluster_manager, "cluster_manager")	
	-- g_objects:hotfix()

	skynet.dispatch("lua", message_dispatch:dispatch())		
end


---------------------------------------------------------
-- skynet
---------------------------------------------------------

skynet.start(function()

	init()

	skynet.register('cluster_mgr')


end)