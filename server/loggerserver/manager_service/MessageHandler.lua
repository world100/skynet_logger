--
-- @Author:      name
-- @DateTime:    2018-03-30 23:05:48
-- @Description: 节点内消息的处理
-- log文件按进程名按天生成
local skynet = require "skynet"

local getPathByString = getPathByString
local getFileName = getFileName
local getFileSuffix = getFileSuffix
local getPathByString = getPathByString
local getDate = getDate

local maxsize = 10 *1024*1024 --文件最大M
local MessageHandler = class("MessageHandler")

---------------------------------------------------------
-- Private
---------------------------------------------------------
function MessageHandler:ctor(message_dispatch, node_message)

	self.message_dispatch = message_dispatch	
	self.node_message = node_message
	self:register()
	self.fp_list = {} --文件句柄
	self.log_list = {} --log消息
	
end

--注册本服务里的消息
function MessageHandler:register()

	self.message_dispatch:registerSelf('start',handler(self,self.start))
	self.message_dispatch:registerSelf('debug',handler(self,self.debug))
	self.message_dispatch:registerSelf('error',handler(self,self.error))
end




--打开一个文件， 但不关闭
function MessageHandler:openFile(filepath,mode)
    -- r  是只读方式打开， 不能写入。
    -- w 只写方式打开，不能读取。
    -- a 末尾追加。
    -- r+  以读写方式打开，保留原有数据。这个模式是自由度最高的。
    -- w+ 以读写方式打开，删除原有数据。就是打开后文件是空文件。
    -- a+ 以读写方式打开，保留原有数据，只能在文件末尾添加，不能在文件中间改写数据。
    if not mode then mode = "a+" end
    local fd = io.open(filepath,mode)
    if fd then
        return fd
    end
    local index = string.find(filepath,'%/',1)
    if not index then
        return
    end
    
    local path = getPathByString(filepath)
    skynet.error('-------创建日记文件夹------',path)
    os.execute("mkdir -p "..path)
    local fd = io.open(filepath,mode)
    if fd then
        return fd
    end
end

--保存到文件
function MessageHandler:saveData(data)
	local file_name = data[1]..getDate()..".log"
	local msg = data[2]
	local fp

    if file_name and msg then
        local tb = self.fp_list[file_name]
        if not tb then   
        	fp = self:openFile(file_name, "a")
        	self.fp_list[file_name] = {fp=fp, time=os.time()}
        else
        	fp = tb.fp
        end
        if fp then
			fp:write(msg)
			fp:flush()
			local file_size = fp:seek("end")
			if file_size >= maxsize then
				--分割文件			
				local hour = os.date("%H_%M_%S",os.time())	
				local rename = "_"..hour			
				fp:close()
				self.fp_list[file_name] = nil
				local path = getPathByString(file_name)
				path = path..getFileName(file_name) .. rename .. getFileSuffix(file_name)				
				os.rename(file_name, path)
			end						
		end      	
    end
end

--关闭一天前的文件句柄
function MessageHandler:closeFileHandle()
	local cur_time = os.time()
	for k,v in pairs(self.fp_list) do 
		if v.time < cur_time - 24*60*60 then 
			v.fp:close()
			self.fp_list[k] = nil
		end
	end
end
---------------------------------------------------------
-- CMD
---------------------------------------------------------
function MessageHandler:start()

	local function loopFunc()
		while true do		
			if self.log_list[1] then
				self:saveData(self.log_list[1])
				table.remove(self.log_list,1)
			end
			self:closeFileHandle()
			skynet.sleep(30)--
		end
	end
	skynet.fork(loopFunc)

end

function MessageHandler:debug(name, msg)
	table.insert(self.log_list,{name,msg})
end

function MessageHandler:info(name, msg)
	
end

function MessageHandler:warning(name, msg)
	
end

function MessageHandler:error(name, msg)	
	table.insert(self.log_list,{name,msg})
end

function MessageHandler:fatal(name, msg)
	
end




return MessageHandler