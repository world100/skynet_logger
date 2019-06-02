local socket = require("socket")
local ssl    = require("ssl")

local params01 = {
  mode = "server",
  protocol = "tlsv1",
  key = "../certs/serverAkey.pem",
  certificate = "../certs/serverA.pem",
  cafile = "../certs/rootA.pem",
  verify = "none",
  options = "all",
  ciphers = "ALL:!ADH:@STRENGTH",
}

local params02 = {
  mode = "server",
  protocol = "tlsv1",
  key = "../certs/serverBkey.pem",
  certificate = "../certs/serverB.pem",
  cafile = "../certs/rootB.pem",
  verify = "none",
  options = "all",
  ciphers = "ALL:!ADH:@STRENGTH",
}

--
local ctx01 = ssl.newcontext(params01)
local ctx02 = ssl.newcontext(params02)

--
local server = socket.tcp()
server:setoption('reuseaddr', true)
server:bind("127.0.0.1", 8888)
server:listen()
local conn = server:accept()
--

-- Default context (when client does not send a name) is ctx01
conn = ssl.wrap(conn, ctx01)

-- Configure the name map
conn:sni({
  ["servera.br"]  = ctx01,
  ["serveraa.br"] = ctx02,
})

assert(conn:dohandshake())
--
conn:send("one line\n")
conn:close()
