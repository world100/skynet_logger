--
-- Author:      name
-- DateTime:    2018-04-27 10:59:15
-- Description: 节点间消息转发，服务间消息转发


local skynet = require "skynet"
local log = require "Logger"
local cluster = require "cluster"
local config = require "configquery"
local MessagePack = require "MessagePack"
local wsnetpack = require "websocketnetpack"
local netpack = require "netpack"
local socket = require "socket"

local NodeMessage = class("NodeMessage")

---------------------------------------------------------
-- private
---------------------------------------------------------
function NodeMessage:ctor()
	self.message_pack = MessagePack.new() --消息编码
	self.node_server_list = {} --Node节点列表
end

--如果要发送pb消息给客户端要初始化pb
function NodeMessage:initProto(pbc_env)
	self.message_pack:initProto(pbc_env)
end

--
function NodeMessage:getMessagePack()
	return self.message_pack
end

--客户端消息解包
function NodeMessage:unpackClient(...)
	return self.message_pack:unpackClient(...)
end

--发送消息给客户端
--contype 连接的类型socket websocket
function NodeMessage:sendClient(fd, contype, message_name, body)
	-- print("________________sendClient__",fd, contype, main_id, sub_id, body)
	--NET_MSG_HEADER(24) + NET_MSG_ROUTER(28) + NET_MSG_COMMOND(12) + PB
    print("________send___",message_name)    
	local str = self.message_pack:packClientByName(message_name, body)
	self:writePackage(fd,contype,str)

end

--写入socket
function NodeMessage:writePackage( fd, contype, msg )
	local tmpmsg, sz
	if contype == "websocket" then
		tmpmsg, sz = wsnetpack.pack(msg)
	elseif contype == "socket" then
		tmpmsg, sz = netpack.pack(msg)	
	else
		tmpmsg, sz = netpack.pack(msg)
	end
	if not tmpmsg or not sz then 
		log.error('writePackage error__tmpmsg=nil or sz=nil')
		return false
	end
	local ok,err = pcall(socket.write, fd, tmpmsg, sz)
	if not ok then
		log.error('writePackage faild:'..err)
		return false
	end
	return true
end


---------------------------------------------------------
-- 不同进程服务间发送消息
---------------------------------------------------------
--异步发送消息请求 node:节点名, address服务名, cmd消息名
function NodeMessage:sendNode( node, address, cmd, ... )
	-- print("############", node, address, cmd, ... )
	local ok, result = x_pcall(cluster.send, node, address, cmd, ...)
	if not ok then
		log.error('##############NodeMessage.send faild:',result)
	end
	return result
end

--同步发送消息请求
function NodeMessage:callNode( node, address, cmd, ... )	
	-- print("________callNode ___",node, address, cmd)
	local ok,result = pcall(cluster.call, node, address, cmd, ...)	
	if not ok then
		log.error("############NodeMessage.call cmd:"..cmd.." faild:", result,node, address, cmd, ...)
		return false
	end
	return result
end

--异步发送到指定节点的.proxy服务
function NodeMessage:sendNodeProxy(node, cmd, ...)
	self:sendNode(node,'.proxy',cmd,...)
end

--同步发送到指定节点的.proxy服务
function NodeMessage:callNodeProxy(node, cmd, ...)
	return self:callNode(node,'.proxy',cmd,...)
end

--注册消息
function NodeMessage:sendNodeMessage(node, cmd, ...)
	self:sendNodeProxy(node,'node_message', cmd,...)
end
--
function NodeMessage:callNodeMessage(node, cmd, ...)
	return self:callNodeProxy(node,'node_message', cmd,...)
end



---------------------------------------------------------
-- 同进程服务间发送消息
---------------------------------------------------------
--同步给全局服务发消息
function NodeMessage:callService(servicename,cmd,...)
	-- print("____servicename,",servicename)
	return skynet.call(servicename,'lua',cmd,...)
end
--异步给全局服务发消息
function NodeMessage:sendService(servicename,cmd,...)
	skynet.send(servicename,'lua',cmd,...)
end

--异步发送到指定节点的.proxy服务
function NodeMessage:sendProxy(cmd, ...)
	self:sendService('.proxy',cmd,...)
end
--同步发送到指定节点的.proxy服务
function NodeMessage:callProxy(cmd, ...)
	return self:callService('.proxy',cmd,...)
end


---------------------------------------------------------
-- 同db进程服务间发送消息
---------------------------------------------------------
function NodeMessage:sendDbProxy(cmd, ...)

	self:sendNode("dbserver_1",'.proxy',cmd,...)
end
function NodeMessage:callDbProxy(cmd, ...)

	return self:callNode("dbserver_1",'.proxy',cmd,...)
end
--直接操作redis
function NodeMessage:callDbRedis(cmd, ...)
	return self:callDbProxy('executeRedis',cmd,...)
end
--直接操作mysql
function NodeMessage:callDbMySql(cmd, ...)
	return self:callDbProxy('executeMySql',cmd,...)
end

return NodeMessage