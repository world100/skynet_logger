--
-- @Author:      qinxugao
-- @DateTime:    2019-06-02 23:05:48
-- @Description: 消息的处理

local skynet = require "skynet"
local log = require "Logger"
local config = require "configquery"


local MessageHandler = class("MessageHandler")

---------------------------------------------------------
-- Private
---------------------------------------------------------
function MessageHandler:ctor(message_dispatch, node_message)

	self.svr_id = skynet.getenv("svr_id") --节点名
	self.svr_name = skynet.getenv("svr_name") --节点名	
	self.proto_file = skynet.getenv("proto_config") --proto文件路径	

	self.message_dispatch = message_dispatch	
	self.node_message = node_message

	--修改start中输出定时更新输出
	skynet.fork(function ( ... )
		while true do 
			skynet.sleep(1000)
			self:start()			
		end
	end)

	self:register()
end

--注册本服务里的消息
function MessageHandler:register()

	self.message_dispatch:registerSelf('start', handler(self,self.start))

end


---------------------------------------------------------
-- CMD
---------------------------------------------------------
function MessageHandler:start()

	log.debug("__1113_logger__test___",{1234,"xcsfa","test11",1231.223},13241,"测试")
	log.error("__322_logger__test___",{1234,"eeeee","test11",1231.223},13241,"测试")
end


return MessageHandler