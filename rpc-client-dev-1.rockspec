package = "rpc-client"
version = "dev-1"
source = {
   url = "git://github.com/aliyun/lua-rpc-client.git"
}
description = {
   summary = "This is a Client that used by Alibaba Cloud RPC OpenAPI.",
   detailed = "This is a Client that used by Alibaba Cloud RPC OpenAPI.",
   homepage = "https://github.com/aliyun/lua-rpc-client",
   license = "Apache License 2.0"
}
build = {
   type = "builtin",
   modules = {
      rpc = "lib/rpc.lua"
   }
}

dependencies = {
   "lua >= 5.1";
	"sha1 >= 0.6.0-1";
   "dkjson >= 2.5-2";
}
