

setting = 
{
	--logon 
	logonserver_ip = "193.112.181.102", --www.xworld.link  ��¼���ᷢxworldcenter����ip��������
	logonserver_port = "11666",
	account = "test01",--E20DB65EF8C9E46901000195DE53E555
	password = "098765", --��������Ϊmd5Ҳ����
	nick_name = "xworld001",

	--self --�˴�Ϊ�������ip�趨
	type		= 2, --1:clientlinker  2:serverlinker
	linker_ip	= "193.112.181.102", --�����������ַ��Ϊ���롰IP ReplyServer����IP"193.112.181.102"��ͨ����������ʵ����ip�����type<2��˲�����Ч  "127.0.0.1",
	linker_port = "30618", --�������ã�����ͻ����
	--run			= "game.lua",--"framesync_room.lua"  "world_scene.lua"

}

