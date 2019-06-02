--
-- @Author:			
-- @DateTime:	2018-03-30 23:05:48
-- @Description: 消息协议的解析

local skynet = require "skynet"
local log = require "Logger"
local cjson = require "cjson"
local MessageMap = require "MessageMap"
local protobuf --= require "protobuf" 



--消息打包类
local MessagePack = class("MessagePack")


function MessagePack:ctor()


	self.message_map = MessageMap.new()

end


return MessagePack
