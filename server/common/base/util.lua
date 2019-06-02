-- 
-- Author:      name
-- DateTime:    2018-04-24 15:25:18
-- Description: 一些工具函数

local skynet = require "skynet"
local lfs = require "lfs"
local cjson = require "cjson"
local httpc
local math = math
local random = math.random

-- --redis取得的数据转为table
-- function redis_to_table(t, fields)
--     assert(type(t) == "table", "make_pairs_table t is not table")
--     local data = {}
--     if not fields then
--         for i=1, #t, 2 do
--             data[t[i]] = t[i+1]
--         end
--     else
--         for i=1, #t do
--             data[fields[i]] = t[i]
--         end
--     end
--     return data
-- end

-- function send_redis(args, uid)
--     local cmd = assert(args[1])
--     args[1] = uid
--     skynet.send("redis_service", "lua", cmd, table.unpack(args))
-- end
-- function call_redis(args, uid)
--     local cmd = assert(args[1])
--     args[1] = uid
--     local tb = skynet.call("redis_service", "lua", cmd, table.unpack(args))
--     tb = redis_to_table(tb)
--     return tb
-- end

--从数组中随机取一个
function rand_array(arr, rate, filter_call)
    rate = rate or "rate" --概率
    local sum = 0
    local exclude = {}
    for k,v in ipairs(arr) do
        local rm
        if filter_call then 
            rm = not filter_call(k,v)
            exclude[k] = rm
        end
        if not rm then
            sum = sum + v[rate]
        end
    end
    local last = 0
    local r = random(sum) -- return 1 ~ sum
    for k,v in ipairs(arr) do
        if not exclude[k] then
            if r > last and r <= (last + v[rate])
                then
                return k,v
            end
            last = last + v[rate]
        end
    end
end

function rand_array_p(arr,rate)
    rate = rate or "rate"
    local sum = 0
    for k,v in pairs(arr) do
        sum = sum + v[rate]
    end
    local last = 0
    local r = random(sum) -- return 1 ~ sum
    for k,v in pairs(arr) do
        if r > last and r <= (last + v[rate])
            then
            return k,v
        end
        last = last + v[rate]
    end
end


--文件是否存在
function file_exist(filePath)
    local f,err = io.open(filePath)
    if f then
        io.close(f)
        return true 
    end
    return false
end

function now()
    return os.time()
end

--- 拷贝列表
local function _table_clone(source)
    if type(source) == "table" then
        local result = {}
        for k, v in pairs(source) do
            result[k] = _table_clone(v)
        end
        return result
    else
        return source
    end
end
table_clone = _table_clone

--连接table
function concat_tb(tb1, tb2)
    for _, v in pairs(tb2) do
        table.insert(tb1, v)
    end
end

--连接数组
function concat_array(tb1, tb2)
    for _, v in ipairs(tb2) do
        table.insert(tb1, v)
    end
end

--table转数组
function dic_toarray(tb)
    local list = {}
    for k,v in pairs(tb) do
        table.insert(list,v)
    end
    return list
end

--table
function arr_toset( tb , set)
	local set = set or {}
	for k,v in ipairs(tb or {}) do
		set[v] = true
	end
	return set
end

--合并table
function merge_table(tb1,tb2)
    if tb2.delete or tb1.delete then
        for k,v in pairs(tb1) do
            tb1[k] = nil
        end
    end

    for k,v in pairs(tb2) do
        tb1[k] = v
    end
end

--打乱数组
function mix_array( arr )
    local sz = #arr
    for i = 1 , sz do
        local r = random(i, sz)
        local t = arr[i]
        arr[i] = arr[r]
        arr[r] = t
    end
end

--分割字符串
function string_split(inputstr, ...)
    local seps = {...}
    local sep = table.remove(seps,1)

    if sep == nil then
        return inputstr
    end
    local result={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(result,str)
    end
    if seps and next(seps) then
        for k,v in pairs(result) do
            result[k] = string_split(v,table.unpack(seps))
        end
    end

    return result
end

function hash_string( str , max)
    if not max or max <=0 then max = 10000 end
    local h = 0
    local v = 1
    local ch = 0
    for i=1, #str do
        ch = str:byte(i)
        h = h + ch
        v = v * ch
    end
    return (h + v) % max
end

----file
--取文件名(带后缀)
function getFileNames(str)
    return str:match("^.+/(.+)$")
end

--取文件名(不带后缀)
function getFileName(str)
    local strName = getFileNames(str)    
    return strName:match("(.+)%.")
end

--取文件路径
function getPathByString(str)
    return str:match("^.+%/")
end

--取文件后缀
function getFileSuffix(str)
    return str:match("^.+(%..+)$")
end


--目录下文件列表
function dir_list( path, ext )
    local file_list = {}
    open_dir(path, ext, function(file_name)
        table.insert(file_list, file_name)
    end)
    return file_list
end


--判断文件夹是否存在
function isFolderExist(folderPath)
    return os.execute("cd "..folderPath)
end

--创建文件夹
function createFolder(folderPath)
    os.execute("mkdir "..folderPath)
end

--取table的长度
function g_table_length(tb)
    local length = 0
    for _,_ in pairs(tb) do
        length = length + 1
    end
    return length
end

function check_string( str, len )
	return string.sub(str, 1, len)
end

--key不连续的table的排序
function sort_table(tb,small_first)
    local arr= {}
    local tb_res = {}
    for k,v in pairs(tb) do 
        table.insert(arr,{k=k,v=v})
    end
    if #arr == 0 then 
        return {}
    end
    --快速排序
    function quickSort(array) 
       local left = 1
       local right = #array
       local function sort(l,r)
           --结束
           if(l >= r) then return end              
           local v = array[l].v
           local k = array[l].k
           local i = l
           local j = r
           while i < j do
               while(i < j and v < array[j].v) do --从右到左, 大的放在基数key 的右边,找到一个小于key的放到左边去
                   j=j-1
               end
               if(i < j) then 
                   array[i].v = array[j].v
                   array[i].k = array[j].k
                   i=i+1
               end
               while(i < j and v > array[i].v) do--在基数的左边找到一个大于key的数把它放到右边
                   i=i+1
               end
               if(i < j) then
                   array[j].v = array[i].v
                   array[j].k = array[i].k
                   j=j-1
               end
           end
           array[i].v = v
           array[i].k = k
           sort(l,i-1)
           sort(i+1,r)
       end
       sort(left,right)
       return array
    end 
    local arr_res = quickSort(arr)
    if not small_first then --从大到小
        for i=#arr_res,1,-1 do 
            local v = arr_res[i]
            --print(v.k,v.v)
            tb_res[v.k] = v.v
        end     
    else
        for k,v in pairs(arr_res) do 
            --print(v.k,v.v)
            tb_res[v.k] = v.v
        end
    end
    return tb_res
end

--排列
function getPermutation(tb)
    local tbRes = {}
    local function permute(a,k)
        local len = #a
        if(len == k) then
            local b = {}
            for i,j in pairs(a) do
                 b[i] = j
             end
            table.insert(tbRes,b)
        else
            for i=k, len do
                a[i], a[k] = a[k], a[i]
                permute(a,k+1)
                a[i], a[k] = a[k], a[i]
            end
        end
    end
    permute(tb,1)
    return tbRes
end

--组合
function getCombination(tb,n)
    -- 从长度为m的数组中选n个元素的组合 https://www.cnblogs.com/ksir16/p/8041457.html
    local len = #tb
    if n > len then
        return {}
    end    
    local meta = {}
    -- init meta data
    for i=1, len do
        if i <= n then
            table.insert(meta, 1)
        else
            table.insert(meta, 0)
        end
    end
    local result = {}
    -- 记录一次组合
    local tmp = {}
    for i=1, len do
        if meta[i] == 1 then
            table.insert(tmp, tb[i])
        end
    end
    table.insert(result, tmp)
    while true do
        -- 前面连续的0
        local zero_count = 0
        for i=1, len-n do
            if meta[i] == 0 then
                zero_count = zero_count + 1
            else
                break
            end
        end
        -- 前m-n位都是0，说明处理结束
        if zero_count == len-n then
            break
        end
        local idx
        for j=1, len-1 do
            -- 10 交换为 01
            if meta[j]==1 and meta[j+1] == 0 then
                meta[j], meta[j+1] = meta[j+1], meta[j]
                idx = j
                break
            end
        end
        -- 将idx左边所有的1移到最左边
        local k = idx-1
        local count = 0
        while count <= k do
            for i=k, 2, -1 do
                if meta[i] == 1 then
                    meta[i], meta[i-1] = meta[i-1], meta[i]
                end
            end
            count = count + 1
        end
        -- 记录一次组合
        local tmp = {}
        for i=1, len do
            if meta[i] == 1 then
                table.insert(tmp, tb[i])
            end
        end
        table.insert(result, tmp)
    end
    return result
end

--牌局id生成
function getRoundId(roomid)
    return os.date("%Y%m%d%H%M%S", os.time()) .. (roomid or 0)
end

--取当前本地ip
function getLocalIp()
    local cmd = io.popen "ip addr"
    local str = cmd:read "*a"
    local ip
    io.close(cmd)
    local fun = function(a)
        local str = string.sub(a,1,string.find(a,'/')-1)
        print(str)
        if str~= '127.0.0.1' and not ip then 
            ip = str
            return
        end        
    end
    str=string.gsub(str,'%d*%.%d*%.%d*%.%d*/',fun)    
    print("__________________ip:",ip)
    return ip
end

--url解码
function decodeURI(s)
    s = string.gsub(s, '%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
    return s
end
--url编码
function encodeURI(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

--http透传
function httpPass(url,content,callback)
    if not httpc then 
        httpc = require "http.httpc"
        httpc.timeout = 3000
    end
    print("url_______:",url..content)
    local respheader = {}
    local status, body = httpc.get(url, content,respheader)
    callback(status,body)
end

--复制文件
function copyfile(source,destination)
    print("___copyfile___",source,destination)
    local sourcefile = io.open(source, "r")
    local destinationfile = io.open(destination, "w")
    if not destinationfile then
        return
    end
    destinationfile:write(sourcefile:read("*all"))
    sourcefile:close()
    destinationfile:close()
end 

--latidue 纬度
--lng1 经度
function getJWDistance(lat1,lng1,lat2,lng2)
    local EARTH_RADIUS = 6378.137
    local radLat1 = math.rad(lat1)
    local radLat2 = math.rad(lat2)
    local a = radLat1 - radLat2
    local b = math.rad(lng1) - math.rad(lng2)
    local s = 2 * math.asin(math.sqrt(math.pow(math.sin(a/2),2) + 
    math.cos(radLat1)*math.cos(radLat2)*math.pow(math.sin(b/2),2)))
    s = s * EARTH_RADIUS*1000
    return s -- 单位米
end

--2016-08-23 10:41:02转时间截
function stringTotime( date )
    local Y = string.sub(date,1,4)
    local M = string.sub(date,6,7)
    local D = string.sub(date,9,10)
    local H = string.sub(date,12,13)
    local MM = string.sub(date,15,16)
    local SS = string.sub(date,18,19)
    local dt1 = os.time{year=Y,month=M,day=D,hour=H,min=MM,sec=SS}
    return dt1
end
--时间截转日期
--local date = "" .. os.date("%Y-%m-%d %H:%M:%S", 1489549082)
function getDate()
    return os.date("%Y-%m-%d",os.time())
end
function getHour()
    return os.date("%H:%M:%S",os.time())
end

--打开指定后缀的文件
function open_path(path, ext, callback)
    local dir = path
    local attr = assert(lfs.attributes(dir))
    if attr.mode == 'directory' then
        for f in lfs.dir(dir) do
            if f ~= '.' and f ~= '..' then
                local f_ext = getFileSuffix(f)
                if  f_ext == ext then
                    local f_full = dir .. "/" .. f
                    local fd = io.open(f_full, "r")
                    if fd then
                        fd:close()
                        pcall(callback, fd)                        
                        -- file_montior(f_full)
                    end
                end
            end
        end
    end
end

--打开目录
function open_dir(path, ext, callback)
    local dir = path
    local attr = assert(lfs.attributes(dir))
    if attr.mode == 'directory' then
        for f in lfs.dir(dir) do
            if f ~= '.' and f ~= '..' then
                local f_ext = getFileSuffix(f)
                if not ext or f_ext == ext then
                    pcall(callback,f)
                end
            end
        end
    end
end

--- cjson序列化会出现NULL值, 可以通过cjson.null比较
function jsonNull(obj, null_v)
    if obj and type(obj) == "table" then
        for k, v in pairs(obj) do
            if v == cjson.null or v == "null" then
                obj[k] = null_v
            elseif type(v) == "table" then
                jsonNull(v, null_v)
            end
        end
    end
    return obj
end

function readFile(path)
    local fstr = nil
    local fd = io.open(path, "r")
    if fd then
        fstr = fd:read("*a")
        fd:close()
    end
    return fstr
end

function unpack_array(array)
    local result = {}
    for _, v in pairs(array) do
        result[tostring(v)] = v
    end
    return result
end

function readLines(f, callback)
    local fd = io.open(f, "r")
    if fd then
        for line in fd:lines() do
            pcall(callback, line)
        end
        fd:close()
    end
end

function readAllLines(f, callback)
    local fd = io.open(f, "r")
    if fd then
        local all_lines = fd:read("*all")
        pcall(callback, all_lines)
        fd:close()
    end
end

--加载json文件
function loadJsonFile(path)
    local fd = io.open(path, "r")
    if fd then
        local all_lines = fd:read("*all")
        local ok, result = pcall(cjson.decode, all_lines)
        if not ok then
            print('load json path faild:'..path..' err:'..tostring(result))
        elseif result then
            return jsonNull(result, '')
        end
        return nil        
    end
end

--加载lua文件
function loadLuaFile(path)
    -- print("_______load_lua_file___",path)
    local fd = io.open(path, "r")
    if fd then
        local source = fd:read("*all")
        fd:close()
        local func, err = load(source, "@"..path, "bt")        
        if not func then
            print("__1__load_lua_file__error",path)
            return 
        end
        local ok, data = pcall(func)
        if not ok then
            print("__2__load_lua_file__error",path)
            return 
        end
        -- file_montior(path)
        return data        
    end
end

--取文件的修改时间
function getFileTime(file)
    return lfs.attributes(file,"change") or 0
end

--4舍5入 
--digit:位数
function rounding(num, digit)
    digit = digit or 1
    num = num / digit
    return (num > 0 and math.floor(num + 0.5) or math.ceil(num - 0.5)) * digit
end
