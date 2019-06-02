--
-- @Author:      
-- @DateTime:    2019-03-30 23:05:48
-- @Description: 消息映射

local config = require "configquery"
local log = require "Logger"

local MessageMap = class("MessageMap")


function MessageMap:ctor( ... )
	self.message_map = {}
end

function MessageMap:init()
	self.message_map = config.message_map
	self.message_name_map = config.message_name_map	
end

function MessageMap:isHasMainCmd(main_id)
	if not main_id then 
		print("______main_id__不能为空___",main_id)
		return false
	end
	if self.message_map[main_id] then
		return true
	end
	log.debug("___________________没有此主命令Id__",main_id)
	return false
end

--返回消息结构
function MessageMap:getValue(main_id,sub_id)
	if not self:isHasMainCmd(main_id) then return end 
	return self.message_map[main_id][sub_id]
end

function MessageMap:getMessageName(main_id,sub_id)
	if not self:isHasMainCmd(main_id) then return end 
	if self.message_map[main_id][sub_id] then 
		return self.message_map[main_id][sub_id]
	end
	return nil
end

-- function MessageMap:getCallback(main_id,sub_id)
-- 	if not self:isHasMainCmd(main_id) then return end 
-- 	if self.message_map[main_id][sub_id] then 
-- 		return "" .. main_id .. sub_id
-- 	end
-- 	return nil
-- end

function MessageMap:getMessageId( message_name )
	-- print("_______self.message_name_map___",self.message_name_map)
	return self.message_name_map[message_name]
end


return MessageMap