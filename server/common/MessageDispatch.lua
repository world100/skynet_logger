--
-- @Author:      
-- @DateTime:    2018-03-30 23:05:48
-- @Description: 消息的派发

local skynet = require "skynet"
local log = require "Logger"
local md5 = require "md5"
local cjson = require "cjson"
local queue = require "skynet.queue"
local NodeMessage = require "NodeMessage"

-- local AssertEx = AssertEx

local MessageDispatch = class("MessageDispatch")
---------------------------------------------------------
-- Private
---------------------------------------------------------
function MessageDispatch:ctor()
	self.self_msg_callback = nil
	self.node_msg_callback = nil
	self.client_msg_callback = nil --除登录消息外的消息都派发到这个回调
	self.tb_self_msg = {} --本服务要监听的消息
	self.tb_node_msg = {} --节点消息
	self.tb_client_msg = {} --客户端消息
	self.tb_must_msg = {}   --必要消息(放开)
	self.mqueue = queue()
	self.node_message = NodeMessage.new()
end

-- 注册本服务消息
function MessageDispatch:register(message_type, callback)
	if message_type == "client" then
		self.client_msg_callback = callback
	elseif message_type == "node" then
		self.node_msg_callback = callback
	else
		self.self_msg_callback = callback
	end
end

--注册本服务里的消息
function MessageDispatch:registerSelf(msg_name, callback)
	if not callback or type(callback) ~= 'function' then 
		log.error("注册的函数回调不对___", msg_name)
		return
	end
	self.tb_self_msg[msg_name] = callback
end

--注册节点消息
function MessageDispatch:registerNode(msg_name, node_name)
	if not self.tb_node_msg[msg_name] then 
		self.tb_node_msg[msg_name] = {}
	end
	table.insert(self.tb_node_msg[msg_name], node_name)
end

--注册客户端消息
function MessageDispatch:registerClient(msg_name, callback)
	if not callback or type(callback) ~= 'function' then 
		log.error("注册的函数回调不对___", msg_name)
		return
	end	
	self.tb_client_msg[msg_name] = callback
end

--注册必要消息
function MessageDispatch:registerMust(msg_name, callback)
	self.tb_must_msg[msg_name] = callback
end

--消息进行队列化
function MessageDispatch:queueMessage(session, source, cmd, ...)		
	local func = handler(self, self.dispatchMessage)
	local result = self.mqueue(func,session, source, cmd, ...)
	
	return result
end	

--消息派发
function MessageDispatch:dispatchMessage(session, source, cmd, ... )
	-- print("####dispatchMessage#######",session,source, cmd, ...)
	local func = self.tb_self_msg[cmd] -- gate是否有handler
	if not func and not self.self_msg_callback then 
		-- print("__self.tb_self_msg__",self.tb_self_msg)
		log.error("####### cmd "..cmd .." not found at manager_service ")
		return
	end

	if cmd == "socket" then 
		if func then			
			skynet.retpack(xx_pcall(func, source, ...))	
		else 
			skynet.retpack(xx_pcall(self.self_msg_callback, source, ...))	
		end
		return
	end
	
	if func then
		-- xx_pcall(func, ...)
		skynet.retpack(xx_pcall(func, ...))
	else
		skynet.retpack(xx_pcall(self.self_msg_callback, ...))
	end
end

--消息派发
function MessageDispatch:dispatchSelfMessage(session, source, cmd, ... )
	-- print("####dispatchSelfMessage######",source, cmd, ...)
	local func = self.tb_self_msg[cmd] -- gate是否有handler
	if not func and not self.self_msg_callback then 
		log.error("####### cmd "..cmd .." not found at manager_service ")
		return
	end

	if cmd == "socket" then 
		if func then			
			skynet.retpack(xx_pcall(func, source, ...))	
		else 
			skynet.retpack(xx_pcall(self.self_msg_callback, source, ...))	
		end
		return
	end
	
	if func then
		skynet.retpack(xx_pcall(func, ...))
	else
		skynet.retpack(xx_pcall(self.self_msg_callback, ...))
	end
end

--消息派发
function MessageDispatch:dispatchNodeMessage(cmd, ... )
	print("####dispatchNodeMessage#######",cmd, ...)
	local node_list = self.tb_node_msg[cmd] 
	if not node_list then 
		log.debug("####### cmd "..cmd .." not found at manager_service ")
		return
	end

	if node_list then
		local res
		for _, node in pairs(node_list) do
			res = self.node_message:callNodeProxy(node, cmd, ...)
			if res and next(res) then --1条消息只能有一个node消息处理返回
				break 
			end 
		end
		return res
	end

	print("________发送node消息失败______",cmd,...)
end

--客户端消息派发
function MessageDispatch:dispatchClientMessage(session, ... )

	print("####dispatchClientMessage#######",session, ...)
	local packet = ...
	if not packet then 
		log.debug("____packet body is invalid___", session)
		--把用户踢下线		
		-- skynet.send('.proxy', 'lua', 'kick_user', fd)	
		return 
	end

	-- local command = packet.command
	-- if not command then
	-- 	log.debug("____packet body is invalid command ___", fd, address)
	-- 	--把用户踢下线		
	-- 	-- skynet.send('.proxy', 'lua', 'kick_user',fd)
	-- 	return 
	-- end

	local message_name = packet.message_name
	local message_body = packet.message_body
	if not message_name then
		log.debug("__错误__没有此消息名___", session, message_name)
		--把用户踢下线				
		self.node_message:sendProxy("kick_user", session.session_id)
		return 
	end

	-- print("___self.tb_client_msg__",self.tb_client_msg[message_name])
	local func = self.tb_client_msg[message_name]
	local status, result	
	if func then
		status, result = x_pcall(func, session.session_id, message_body)
	else
		-- 先传到manager_service中再传到别的node
		result = self.node_message:callProxy("message_to_node", message_name, message_body)
	end
	-- print("_____result___",result)
	if result and next(result) then 
		return result
	end
	-- if not status then
		log.error("####### this is call error:", tostring(result or ''))
	-- end
end

--需要排队的消息
function MessageDispatch:dispatchQueue()
	return handler(self, self.queueMessage)
end

function MessageDispatch:dispatch(type)
	if type == "client" then
		return handler(self, self.dispatchClientMessage)
	elseif type == "node" then
		return handler(self, self.dispatchNodeMessage)
	elseif type == "self" then
		return handler(self, self.dispatchSelfMessage)
	else
		return handler(self, self.dispatchMessage)
	end
end


return MessageDispatch