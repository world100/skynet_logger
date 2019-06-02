--
-- Author:      name
-- DateTime:    2018-04-23 17:19:33
-- Description: 服务管理


require "skynet.manager"
local skynet = require "skynet"
-- local cluster = require "cluster"

local Objects = require "Objects"
local NodeMessage = require "NodeMessage"
local MessageDispatch = require "MessageDispatch"
local MessageHandler = require "manager_service.MessageHandler"

g_objects = Objects.new()

local function init()

	local node_message = NodeMessage.new()
	local message_dispatch = MessageDispatch.new()	
	local message_handler = MessageHandler.new(message_dispatch, node_message)

	g_objects:add(message_handler)
	g_objects:hotfix()
	skynet.dispatch("lua", message_dispatch:dispatch())		
end


---------------------------------------------------------
-- skynet
---------------------------------------------------------

skynet.start(function()

	init()

	skynet.register('.proxy')

	--集群节点
	-- local svr_id = skynet.getenv("svr_id")
	-- print("___svr_id__", svr_id)
	-- cluster.open(svr_id)	
	-- local svr_name = skynet.getenv("svr_name")
	-- print("#####################", svr_name)	
end)