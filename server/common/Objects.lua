--
-- Author:      name
-- DateTime:    2018-04-27 10:59:15
-- Description: 所有对象的管理,热更

local lfs = require "lfs"
local skynet = require "skynet"
local codecache = require "skynet.codecache"

local Objects = class("Objects")

function Objects:ctor()

	self.file_times = {}	--文件最后一次改动的时间 
	self.file_postfix = ".lua" --后缀
	self.objects = {}
end

function Objects:add(object)
	--一个类可能对应很多个对象
	local class_name = object.getName()
	self.objects[class_name] = self.objects[class_name] or {}
	table.insert(self.objects[class_name],object)
end


function Objects:getObjectByName(name)
	return self.objects[name]
end

function Objects:addFile(path)
	local fileList = dir_list(path)	--目录下列表
	-- print("___fileList__",fileList)
	for k,v in pairs(fileList) do 
		if getFileSuffix(v) == self.file_postfix and v~="Objects.lua" then
			self.file_times[path..v] = lfs.attributes(path..v,"change")
		end
		-- if isFolderExist(path..v) then 
		local mode = lfs.attributes(path..v,"mode") 
		if mode == "directory" then --是文件夹
			self:addFile(path..v.."/")
		end
	end	
end

--替换已加载的模块
function Objects:replaceModule(moduleName,tbPath)
	-- print("#########replaceModule########",moduleName)
	local name = moduleName
	local hasModule = false
	if not package.loaded[moduleName] then 
		print("__没有此模块,加上前缀路径看有没有此模块被加载__",moduleName)			
		for i=#tbPath-1, 1 , -1 do --加上前缀路径看有没有此模块被加载
			name = tbPath[i].."."..name				
			if package.loaded[name] then 
				print("有已加载文件__",name)
				hasModule = true
				moduleName = name
				break
			end
		end 
		if not hasModule then 
			return 
		end
	end
	--清除缓存
	codecache.clear()			
	package.loaded[moduleName] = nil --
	-- package.preload[moduleName] = nil
	local old_module = require(moduleName)
	local objects = self:getObjectByName(old_module.getName()) or {}
	-- print("##################",old_module.__cname,new_module,old_module)
	
    for k,v in pairs(old_module) do			    	
        old_module[k] = v
        for i,object in pairs(objects) do 
	        object[k] = v
	    end
    end
    for i,object in pairs(objects) do 
        if object.register and type(object.register)=="function" then --重新注册回调函数
        	object:register()
        end
    end	    

	package.loaded[moduleName] = old_module
	-- package.preload[moduleName] = old_module				
end

--folder 服务所在文件夹
function Objects:hotfix()
	--[[
		1 起动一个定时器，检查文件是否发生变动
		2.检查是否存在对象，进行类方法更新
		4 
	--]]
	-- package.path = "../inject/?.lua;"..package.path
	-- print("_____package.path__",package.path)

	local serverPath = skynet.getenv("pro_path").."/" --进程所在目录	
	local fileName	
	local moduleName 
	self:addFile(serverPath)

	--检查文件是否改变动
	local function loop()
		while true do 
			skynet.sleep(200)
			local fileChangeTime = 0
			for k,v in pairs(self.file_times) do 
				fileChangeTime = lfs.attributes(k,"change") or 0	
				if fileChangeTime > v then	--时间发生变动				
					-- fileName = get_file_name(k)
					-- print("_________fileName_change___",k,fileName)
					local tb = string.split(k,"/")
					fileName = getFileName(k)					
					self.file_times[k] = fileChangeTime
					moduleName = fileName
					self:replaceModule(moduleName,tb)--在模块中已存在的进行热					
				end
			end
		end
	end
	skynet.fork(loop)

end

return Objects