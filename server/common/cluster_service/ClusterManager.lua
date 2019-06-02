--
-- @Author:      name
-- @DateTime:    2018-03-30 23:05:48
-- @Description: 节点内消息的处理
require "skynet.manager"
local skynet = require "skynet"
local log = require "Logger"
-- local crypt = require "crypt"
local cluster = require "cluster"
local config = require "configquery"

local ClusterManager = class("ClusterManager")

---------------------------------------------------------
-- Private
---------------------------------------------------------
function ClusterManager:ctor(message_dispatch, node_message)

	self.message_dispatch = message_dispatch	
	self.node_message = node_message
	self.need_connect = nil --需要连接到别的服务器
	self.cluster_list = {} --集群列表
	self.heartbeat_delay = 500 --心跳时间
	self.reconnect_delay = 600 --重连时间
	self.hotfix_num = 0 --集群列表热更标记
	self.cluster_name = nil

	-- skynet.fork(function()
	-- 	while true do 
	-- 		skynet.sleep(1500)
	-- 		print("______config__",config.game_setting)
	-- 		self:onClusterReload()
	-- 		break
	-- 	end
	-- end)
	self:register()
end

--注册本服务里的消息
function ClusterManager:register()

	self.message_dispatch:registerSelf('start',handler(self,self.start))
	self.message_dispatch:registerSelf('cluster_connect',handler(self,self.onConnect))
	self.message_dispatch:registerSelf('cluster_heartbeat',handler(self,self.onHeartBeat))
	self.message_dispatch:registerSelf('cluster_reload',handler(self,self.onClusterReload))
	
	
end

function ClusterManager:connect(server_info)
	local function connectFunc(v)
		local res =  self.node_message:callNode(v.cluster_name, 'cluster_mgr', 'cluster_connect', v)
		if res then 
			print("___连接成功__",v.cluster_name)
			v.online = 1
			--写入redis
		    self.node_message:callDbRedis("hmset", { "server_list:server_id:" .. v.server_id, v})			
			self:heartbeat(v)
		else
			print("___连接失败__",v.cluster_name)
		end		
		return res
	end		
	--skynet.fork启动一个协程，skynet.lua 里有一个协程池
	skynet.fork(connectFunc,server_info)

end

function ClusterManager:disconnect(server_info)
	local hotfix_num = self.hotfix_num 
	--写入redis
    self.node_message:callDbRedis("hmset", { "server_list:server_id:" .. server_info.server_id, server_info})	
    -- 定时尝去连接
    local function func()
    	while true do     		
    		skynet.sleep(600)
    		if hotfix_num ~= self.hotfix_num then --集群列表需要更新
    			break
    		end
    		local info = self.node_message:callDbRedis("hgetall", { "server_list:server_id:" .. server_info.server_id})
    		if tonumber(info.disable)==0 then 
    			break
    		end
    		if tonumber(info.online)==0 then 
    			self:connect(info)
    		else
    			break
    		end
    	end
    end
    skynet.fork(func,server_info)
end

function ClusterManager:heartbeat(server_info)
	local hotfix_num = self.hotfix_num 	
	local function func(v)
		while true do 
    		if hotfix_num ~= self.hotfix_num then --集群列表需要更新
    			break
    		end			
			local res =  self.node_message:callNode(v.cluster_name, 'cluster_mgr', 'cluster_heartbeat', v)
			if res then 
				-- print("___心跳发送成功__",self.cluster_name, v.cluster_name)
			else
				--断线了
				v.online = 0				
				self:disconnect(v)
				break
			end		
			skynet.sleep(self.heartbeat_delay)
		end
	end	
	skynet.fork(func,server_info)

end

function ClusterManager:loadCluster(need_connect)

	self.hotfix_num = self.hotfix_num + 1
	local setting = config.setting_cfg
	local svr_id = tonumber(skynet.getenv("svr_id")) --服务器名
	local svr_name = skynet.getenv("svr_name") --服务器类型

	self.cluster_name = svr_name.."_"..svr_id
	local cluster_name_list = {} --集群配置表
	local index = 1
	self.cluster_list = {}
	for server_type, server_list in pairs(setting) do 		
		for k, v in pairs(server_list) do 			 
			local cluster_name = server_type.."_"..k
			cluster_name_list[cluster_name] = v.cluster			
			if self.cluster_name ~= cluster_name then 
				v.cluster_name = cluster_name
				self.cluster_list[index] = v				
				index = index + 1
			end			
		end
	end	
	-- print("____cluster_name_list__",cluster_name_list)
	--集群表加载
	cluster.reload(cluster_name_list)
	if need_connect then 
		for k,server_info in pairs(self.cluster_list) do 	
			self.node_message:callDbRedis("hmset", { "server_list:server_id:" .. server_info.server_id, server_info})
			if server_info.disable == 0 then 		
				self:connect(server_info)
			end
		end				
	end
end
---------------------------------------------------------
-- CMD
---------------------------------------------------------
function ClusterManager:start(need_connect)

	local setting = config.setting_cfg
	local svr_id = tonumber(skynet.getenv("svr_id")) --服务器名
	local svr_name = skynet.getenv("svr_name") --服务器类型
	local svr_info = setting[svr_name][svr_id] --自已的服务信息
	local cluster_name = svr_name.."_"..svr_id
	-- print("____cluster_name",svr_info)
	--加载集群列表
	self:loadCluster()
	cluster.open(cluster_name)
	--skynet控制台
	skynet.uniqueservice("debug_console",svr_info.debug_port)

	print("#####################",svr_name, cluster_name)

	if need_connect then 
		self.need_connect = need_connect
		for k, server_info in pairs(self.cluster_list) do 	
			self.node_message:callDbRedis("hmset", { "server_list:server_id:" .. server_info.server_id, server_info})
			if server_info.disable == 0 then 		
				self:connect(server_info)
			end
		end
	end
end

--收到连接
function ClusterManager:onConnect(data)
	-- print("______onConnect___",data)
	return true
end

--收到心跳包
function ClusterManager:onHeartBeat(data)
	-- print("______onHeartBeat___",data)
	return true
end

-- 更新集群列表
function ClusterManager:onClusterReload(data)
	-- print("______onReloadCluster___",data)
	self:loadCluster(self.need_connect)	
	return true
end


return ClusterManager