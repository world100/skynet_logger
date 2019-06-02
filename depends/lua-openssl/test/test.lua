local openssl = require'openssl'
EXPORT_ASSERT_TO_GLOBALS = true
require'luaunit'

openssl.rand_load()
v = {openssl.version(true)}
print(openssl.version())

dofile('0.engine.lua')
dofile('0.misc.lua')
dofile('0.tcp.lua')
dofile('1.asn1.lua')
dofile('2.asn1.lua')
dofile('1.x509_name.lua')
dofile('1.x509_extension.lua')
dofile('1.x509_attr.lua')
dofile('2.digest.lua')
dofile('2.hmac.lua')
dofile('3.cipher.lua')
dofile('4.pkey.lua')
dofile('5.x509_req.lua')
dofile('5.x509_crl.lua')
dofile('5.x509.lua')
dofile('5.ts.lua')
dofile('6.pkcs7.lua')
dofile('7.pkcs12.lua')
dofile('8.ssl_options.lua')
dofile('8.ssl.lua')
dofile('rsa.lua')
dofile('ec.lua')

--LuaUnit.verbosity = 0
LuaUnit.run()
print(openssl.error(true))
collectgarbage()

