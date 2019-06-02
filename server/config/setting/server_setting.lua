--进程端口相关配置
-- loggerserver    = "0.0.0.0:10001"
-- zoneserver      = "0.0.0.0:11001"
-- gateserver_1    = "0.0.0.0:12001"
-- hallserver_1    = "0.0.0.0:13001"
-- dbserver_1      = "0.0.0.0:14001"
-- gameserver_1    = "0.0.0.0:15001"
-- nodeserver_1    = "0.0.0.0:16001"


return {

    loggerserver = {
        {
            server_id = 1,
            cluster = "0.0.0.0:10001",
            cluster_name = "loggerserver_1",
            debug_port = 10101,
            online = 1,
            disable = 0,
            version = 1,
            ip = "127.0.0.1",
            port = 10001,
            max_client = 1000,
        }
    },
 
    dbserver = {
        {
            server_id = 2,
            cluster = "0.0.0.0:14001",
            cluster_name = "dbserver_1",
            debug_port = 14101,
            online = 1,
            disable = 0,
            version = 1,
            ip = "127.0.0.1",
            port = 14001,
            max_client = 1000,            
        },     
    },
   
    -- zoneserver = {
    --     disable = 0,
    --     ip = "127.0.0.1",
    --     port = 11101,
    --     debug_port = 11102,   
    --     maxclient = 12010,
    --     zone_size = 4,
    -- },

    gateserver = {
        {  
            server_id = 3,
            cluster = "0.0.0.0:12001",
            cluster_name = "gateserver_1",            
            online = 1,
            disable = 0,
            version = 1,
            ip = "127.0.0.1",
            port = 12001,
            debug_port = 12103,             
            gate_size = 3, --服务的个数 
            max_client = 1000, 
        },
        {     
            server_id = 4,
            cluster = "0.0.0.0:12002",
            cluster_name = "gateserver_2",            
            online = 1,
            disable = 0,
            version = 1,
            ip = "127.0.0.1",
            port = 12002,
            debug_port = 12203,             
            gate_size = 1, --服务的个数 
            max_client = 1000,              
        },
    },

    -- hallserver = {
    --     hallserver = {
    --         debug_port = 13101,
    --     },     
    -- },


    -- gameserver = {
    --      {            
    --         server_id = 3,
    --         cluster = "0.0.0.0:15001",
    --         cluster_name = "gameserver_1",
    --         debug_port = 15101,
    --         online = 1,
    --         disable = 1,
    --         version = 1,
    --         ip = "127.0.0.1",
    --         port = 15001,
    --         max_client = 1000,            
    --     },     
    -- },

    zoneserver = {
        {
            server_id = 5,
            cluster = "0.0.0.0:16001",
            cluster_name = "zoneserver_1",
            debug_port = 16101,
            online = 1,
            disable = 0,
            version = 1,
            ip = "127.0.0.1",
            port = 16001,
            max_client = 1001,            
        },     
    },

    loginserver = {
        {
            server_id = 6,
            cluster = "0.0.0.0:17001",
            cluster_name = "loginserver_1",
            debug_port = 17101,
            online = 1,
            disable = 0,
            version = 1,
            ip = "127.0.0.1",
            port = 17001,
            max_client = 1001,

            -- cluster = "0.0.0.0:17001",
            -- disable = 0,
            -- ip = "127.0.0.1",
            -- port = 17101,   --socket端口
            -- port_ws = 17102, --websocket端口
            -- debug_port = 17103, 
            -- maxclient = 10000,
            -- gate_size = 1, --服务的个数        
        },     
    },

    -- robotserver = {
    --     {
    --         cluster = "0.0.0.0:18001",
    --         debug_port = 18101,
    --     },     
    -- },
}

