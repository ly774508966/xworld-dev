

setting = 
{
	--logon 
	logonserver_ip = "193.112.181.102", --www.xworld.link  登录完后会发xworldcenter服的ip回来连接
	logonserver_port = "11666",
	account = "test01",--E20DB65EF8C9E46901000195DE53E555
	password = "098765", --密码设置为md5也可以
	nick_name = "xworld001",

	--self --此处为自身服务ip设定
	type		= 2, --1:clientlinker  2:serverlinker
	linker_ip	= "193.112.181.102", --如果是内网地址改为填入“IP ReplyServer”的IP"193.112.181.102"，通过这个获得真实公网ip，如果type<2则此参数无效  "127.0.0.1",
	linker_port = "30618", --随意设置，不冲突就行
	--run			= "game.lua",--"framesync_room.lua"  "world_scene.lua"

}

