 

 --[[
 同步：
	单位：服务端每三秒同步周围单位id列表；客户端比较本地列表，删掉不在的，添加进入的
	（底层管理，范围，位置）

	行为：客户端发行为指令；服务端（检查合法性，位置与可执行性）转发给周围角色；客户端执行行为（带位置）

	不同步纠正：收到服务端他人的行为，相差太远则纠正，服务器发给自己的强制纠正则恢复。
 ]]--

 --所有require都放此处
 require "helper"
 require "setting"

xworld = require("xworld_core")

 json = require "cjson"
 xrpc = require "XRPC"
 
 linker = nil

 --XLinker = Linker(_Linker) --c++层设进去的全局对象 ，不再使用c++版的linker
 --local socket = require("socket_core")


 local ori_require = require
 local ori_requirepath = package.path
 local xwmodule = {}

 function xrequire(module)
	xwmodule[module] = ori_require(module)
	return xwmodule[module]
 end

 function unrequire(module)
    package.loaded[module] = nil
	xwmodule[module] = nil
    --_G[m] = nil
end
 --强制替换掉
 require = xrequire

 --清理第三方加入的内容
 function require_clear()
	for k,v in pairs(xwmodule) do
		package.loaded[k] = nil
		xwmodule[k] = nil
	end
end
 
--require "MsgPRCCall"

--热更新模块
function reload_module(module_name)
    local old_module = package.loaded[module_name] or {}
    package.loaded[module_name] = nil
    require (module_name)

    local new_module = package.loaded[module_name]
    for k, v in pairs(new_module) do
        old_module[k] = v
    end

    package.loaded[module_name] = old_module
    return old_module
end

local logon_proto = 
{
	LOGON_MSG_REGITSER_ACCOUNT = 11,
	LOGON_MSG_SIGNIN_ACCOUNT = 12,
	LOGON_MSG_REGITSER_ACCOUNT_RESULT = 16,
	LOGON_MSG_SIGNIN_ACCOUNT_RESULT	= 17,
}

local xworld_proto = 
{
	XWORLD_MSG_SIGNIN	=	101,--xid token 连接		t_xworld_msg_signin
	XWORLD_MSG_GETDATA	=	105,--ask money and point num
	XWORLD_MSG_REQ_LINKER = 106, --link ip and port and token
	XWORLD_MSG_BUY		=	111,--buy something

	XWORLD_MSG_SIGNIN_RESULT	=	151,--result  base linker
	XWORLD_MSG_GETDATA_RESULT	=	155,--money and point
	XWORLD_MSG_REQ_LINKER_RESULT	= 156, --ip and port and token
	XWORLD_MSG_BUY_RESULT		=	161,--//
}

local linker_proto = 
{
	XWBASE_MSG_LINKER_ENTER			=	201, --第一步建立连接确认
	XWBASE_MSG_REQ_FILE				=	202,

	XWBASE_MSG_LINKER_ENTER_RESULT	=	211,
	XWBASE_MSG_REQ_FILE_RESULT		=	212, --文件获取结果
	XWBASE_MSG_ON_FILE_FINISH		=	213, --文件获取完成（写入完成）
}

xmain = {}
local this = xmain
Manager = {}
local runmodule = {}

function print(str)
	xmain.linker:Print(str)
end

function Manager.Push(name, module)
	runmodule[name] = module
	module.Init()
	print("Run Module:"..name)
	print("\r\n")
end
function Manager.Pop(name)
    if runmodule[name] ~= nil then
		runmodule[name].Quit()
	end
	runmodule[name] = nil
	print("Stop Module:"..name)
end

function XPrint(str)
	xmain.linker:Print(str)
end

function XGetLinkerData()
	return xmain.linkerdata
end

--添加主运行模块
 --require "simpleScene"
 --全局使用
 --XLinker = {}
function xmain.Init()
	--print("Hello, This is Xworld.\r\n") 
	
	--xmain.LinkerList = {}
	--XLinker.Quit();

	xmain.resupdate_time = 0
	xmain.linkerdata = {}
	xmain.linkerdata.reslist = {}
	xmain.linkerdata.needres = 0

	--自身创建成为创界节点Linker
	xmain.linker = xworld.linker(setting.linker_ip, setting.linker_port, setting.type, "")--"127.0.0.1", "21711", 1, "test_game.lua");
	if xmain.linker == nil then
		return;
	end
	linker = xmain.linker
	
	if setting.type >=2 then 
		setting.linker_ip = linker:GetOuterIP()--提供服务的ip需要获得最终外网ip地址
	end

	xmain.linker:Print("Self :"..setting.linker_ip.." : "..setting.linker_port.."\r\n");
	xmain.linker:SetDataPath(".")

	
	xmain.msg_buffer = xworld.linkerbuffer();
	--xmain.send_buffer = socket.linkerbuffer();
	--msgcount = xmain.linker:GetMessageCount()
	--xmain.linker:Print(msgcount)

	xmain.linkerdata.logonserver_ip = setting.logonserver_ip --"193.112.181.102"
	xmain.linkerdata.logonserver_port = setting.logonserver_port --"11666"
	xmain.linkerdata.accountname = setting.account --"udxreg9"
	xmain.linkerdata.password  = setting.password--"abcd99"
	--1. load xidtoken file "basedata.xw"
	if xmain.LoadBaseData("basedata.xw", xmain.linkerdata) ~= nil then -- 1.
		--1.1 连接中心服
		if xmain.ConnectXworldCenter() == nil then
			--1.2 重连登录服
			xmain.linker:Logon(xmain.linkerdata.logonserver_ip, xmain.linkerdata.logonserver_port, 1, xmain.linkerdata.accountname, xmain.linkerdata.password)--最后的密码可用md5
		end
	else
	--1.2 连接登录服
		xmain.linker:Print("Logon ......"..xmain.linkerdata.accountname.."\r\n")
		xmain.linker:Logon(xmain.linkerdata.logonserver_ip, xmain.linkerdata.logonserver_port, 1, xmain.linkerdata.accountname, xmain.linkerdata.password)--最后的密码可用md5
	--xmain.linker:Logon("127.0.0.1", "11666", 1, "udxreg4", "abcd99", "nickname1")
	end

end

function xmain.StartServer()
	if this.linkerdata.xid == nil then
		print("Server Start Failed :xid == nil")
		return 
	end 
	if setting.type >=2 then 
		--运行服务端
		path = "xworld/"..this.linkerdata.xid.."/server/?.lua"  --/main.lua"
		package.path = ori_requirepath..";"..path
		local module = xrequire("xwserver")
		if module ~= nil then
			print("xwserver.lua load ok!\r\n")
		end
		Manager.Push("xwserver", module)
	end
end

function xmain.LoadBaseData(filename, linkerdata)

	local f = io.open( filename, 'r')
	if f ~= nil then
		linkerdata.accountname = f:read()
		
		linkerdata.password = f:read()
		linkerdata.xid = f:read()
		linkerdata.xidbuffer = helper.hex2bin(linkerdata.xid)
		linkerdata.nick_name = f:read()
		linkerdata.xcenter_ip = f:read()
		local port = f:read()
		linkerdata.xcenter_port = tonumber(port)
		linkerdata.token = f:read()

		f:close()
		--xid token nickname
		xmain.linker:SetLinkerData(linkerdata.xidbuffer, linkerdata.token, linkerdata.nick_name)
		xmain.linker:Print("Self XID: "..linkerdata.xid.."\r\n")
		return 1
	else
		return nil
	end
end

function xmain.SaveBaseData(filename, linkerdata)
	local f = io.open( filename, 'w')
	if f ~= nil then
		f:write(linkerdata.accountname)
		f:write("\n")
		f:write(linkerdata.password)
		f:write("\n")
		f:write(linkerdata.xid)
		f:write("\n")
		f:write(linkerdata.nick_name)
		f:write("\n")
		f:write(linkerdata.xcenter_ip)
		f:write("\n")
		f:write(linkerdata.xcenter_port)
		f:write("\n")
		f:write(linkerdata.token)
		f:write("\n")
		f:close()
		xmain.linker:Print("SaveBaseData xid="..linkerdata.xid.."\r\n")
		return 1
	else
		return nil
	end
end

function xmain.ConnectXworldCenter()
	xmain.linkerdata.xworldcenter = xmain.linker:Connect(xmain.linkerdata.xcenter_ip, xmain.linkerdata.xcenter_port)
	xmain.linker:Print("Connect XWorldCenter :"..xmain.linkerdata.xworldcenter.."\r\n")
			
	--需要发送登录消息XWORLD_MSG_SIGNIN xid server_ip[16] server_port type tokenlen token[32] 
	if xmain.linkerdata.xworldcenter >=0 then--1.1.1
		local sendbuffer = xworld.linkerbuffer()
		sendbuffer:WriteShort(xworld_proto.XWORLD_MSG_SIGNIN)--第一个short一定是消息
		sendbuffer:WriteBuffer(xmain.linkerdata.xidbuffer, 16) --self xid
		sendbuffer:WriteBuffer(setting.linker_ip, 16)--强制填满16字节，对好协议位置  测试用"127.0.0.1" "192.168.0.149"
		sendbuffer:WriteShort(setting.linker_port)--测试用21711
		sendbuffer:WriteShort(setting.type)--type类型1 client 2:server 3:both
		sendbuffer:WriteBuffer(xmain.linkerdata.token, 32)--
		xmain.linker:Send(xmain.linkerdata.xworldcenter, sendbuffer)-- waiting XWORLD_MSG_SIGNIN_RESULT
		return xmain.linkerdata.xworldcenter
	else
		return nil
	end
end

function xmain.ConnectXworldLinker()
	xmain.linkerdata.xworldlinker = xmain.linker:Connect(xmain.linkerdata.defaultlinker_ip, xmain.linkerdata.defaultlinker_port)
	xmain.linker:Print("Connect XWorldLinker :"..xmain.linkerdata.xworldlinker.."\r\n")
	--需要发送进入节点消息XWBASE_MSG_LINKER_ENTER xid nick_name token
	if xmain.linkerdata.xworldlinker >=0 then--1.1.1
		local sendbuffer = xworld.linkerbuffer()
		sendbuffer:WriteShort(linker_proto.XWBASE_MSG_LINKER_ENTER)--第一个short一定是消息
		sendbuffer:WriteBuffer(xmain.linkerdata.xidbuffer, 16) --xid
		sendbuffer:WriteBuffer(xmain.linkerdata.nick_name, 16)--强制填满16字节，对好协议位置  测试用"127.0.0.1" "192.168.0.149"
		sendbuffer:WriteBuffer(xmain.linkerdata.token, 32)--
		xmain.linker:Send(xmain.linkerdata.xworldlinker, sendbuffer)
		return xmain.linkerdata.xworldlinker
	else
		return nil
	end
end

function xmain.CenterMsg(id, msg, buffer)
	local error
	if msg == logon_proto.LOGON_MSG_REGITSER_ACCOUNT_RESULT or msg == logon_proto.LOGON_MSG_SIGNIN_ACCOUNT_RESULT then
		--登录结果 --这个消息是登录服返回的
		error = buffer:ReadLong()
		if error == 0 then
			xmain.linkerdata.xidbuffer = buffer:ReadBuffer(16)--2进制串
			xmain.linkerdata.xid = helper.bin2hex(xmain.linkerdata.xidbuffer, 16)
			if xmain.linkerdata.xid == nil then
				xmain.linker:Print("xid==nil\r\n")
			else
				xmain.linker:Print("xid:"..xmain.linkerdata.xid.."\r\n")
			end

			xmain.linkerdata.nick_name = buffer:ReadString(16)--ReadBuffer(16) 最大16字节中的字符串
			xmain.linker:Print(xmain.linkerdata.nick_name.."\r\n")
			local ipbuffer = buffer:ReadBuffer(4)
			--xmain.linker:Print(ipbuffer, 4)
			xmain.linker:Print("\r\n")
			xmain.linker:Print("XWorld Center:\r\n")
			xmain.linkerdata.xcenter_ip = string.format("%d.%d.%d.%d",ipbuffer:sub(1):byte(),ipbuffer:sub(2):byte(),ipbuffer:sub(3):byte(),ipbuffer:sub(4):byte() )
			xmain.linker:Print("ip:"..xmain.linkerdata.xcenter_ip..":")
			
			xmain.linkerdata.xcenter_port = buffer:ReadShort()
			xmain.linker:Print("port:"..xmain.linkerdata.xcenter_port.."\r\n")
			buffer:ReadShort()--len
			xmain.linkerdata.token = buffer:ReadBuffer(32)--short (len) + string
			xmain.linker:Print("token:"..xmain.linkerdata.token.."\r\n")
			--保存登录信息
			xmain.SaveBaseData("basedata.xw", xmain.linkerdata)
			--连接xworld server
			xmain.ConnectXworldCenter()
			
		end
	end 
		
	if msg == xworld_proto.XWORLD_MSG_SIGNIN_RESULT then
		error = buffer:ReadLong()
		if error == 0 then
			xmain.linkerdata.money = buffer:ReadLong()
			xmain.linkerdata.point = buffer:ReadLong()
			xmain.linkerdata.xwp = buffer:ReadLong()
			xmain.linkerdata.exp = buffer:ReadLong()
			xmain.linkerdata.level = buffer:ReadLong()
			xmain.linkerdata.id  = buffer:ReadLong()
			xmain.linkerdata.defaultlinker_ip = buffer:ReadString(16)
			xmain.linkerdata.defaultlinker_port = buffer:ReadLong()
			xmain.linker:Print("Sign in:  money:"..xmain.linkerdata.money.." exp:"..xmain.linkerdata.exp.."\r\n")
			xmain.linker:Print("defaultserver:"..xmain.linkerdata.defaultlinker_ip..":"..xmain.linkerdata.defaultlinker_port.."\r\n")

			if  setting.type == 2 then -- 服务节点 则可以不用继续连接场景服了
				--开启自身服务端程序
				xmain.StartServer()
				return
			end
			--可连接默认Linker场景节点服了
			xmain.ConnectXworldLinker()
		else
			--token验证失败 ，重新登录
			xmain.linker:Print("Logon ......\r\n")
			xmain.linker:Logon(xmain.linkerdata.logonserver_ip, xmain.linkerdata.logonserver_port, 1, xmain.linkerdata.accountname, xmain.linkerdata.password)
		end
	end

	if msg == xworld_proto.XWORLD_MSG_GETDATA_RESULT then
		error = buffer:ReadLong()
		if error == 0 then
			xmain.linkerdata.money = buffer:ReadLong()
			xmain.linkerdata.point = buffer:ReadLong()
			xmain.linkerdata.xwp = buffer:ReadLong()
			xmain.linkerdata.exp = buffer:ReadLong()
			xmain.linkerdata.level = buffer:ReadLong()
			xmain.linker:Print("GetData:  money="..xmain.linkerdata.money.." exp="..xmain.linkerdata.exp.."\r\n")
			
		end
	end	
end

function xmain.ReqFile(netid, filepath, beginpos, endpos)
	local sendbuffer = xworld.linkerbuffer()
	local path = filepath  --xmain.linkerdata.linker_xid.."/"..setting.platform.."/filelist.txt"
	local namelen = #path
	sendbuffer:WriteShort(linker_proto.XWBASE_MSG_REQ_FILE)--第一个short一定是消息
	sendbuffer:WriteLong(beginpos) --file begin
	sendbuffer:WriteLong(endpos) --file end
	sendbuffer:WriteLong(namelen) --file end
	sendbuffer:WriteBuffer(path, namelen + 1)--强制填满16字节，对好协议位置  测试用"127.0.0.1" "192.168.0.149"
	--xmain.linker:Print("send req file msg:"..path.."\r\n")		
	xmain.linker:Send(netid, sendbuffer)
end

function xmain.LinkerMsg(id, msg, buffer)
	local error
	if msg == linker_proto.XWBASE_MSG_LINKER_ENTER_RESULT then--连接linker返回，进入资源同步或者运行阶段
		error = buffer:ReadLong()
		if error == 0 then
			xmain.linkerdata.linker_xidbuf = buffer:ReadBuffer(16)
			xmain.linkerdata.linker_xid = helper.bin2hex(xmain.linkerdata.linker_xidbuf, 16)
			local md5_uuid= buffer:ReadBuffer(16)
			xmain.linkerdata.res_md5 = helper.bin2hex(md5_uuid, 16)
			--读取xworld/xid/ver.txt
			local path = setting.datapath.."/xworld/"..xmain.linkerdata.linker_xid.."/ver.txt"
			xmain.linker:Print("Load Ver File: "..path.." MD5="..xmain.linkerdata.res_md5.."\r\n")
			xmain.linkerdata.needres = 0
			local needfilelist = 0
			local f = io.open( path, 'r')
			if f ~= nil then
				local line = f:read("*line")
				while line do
					for k, ver in string.gmatch(line, '(%w+)=(%w+)') do 
						if k == "MD5" then
							xmain.linker:Print("base MD5: "..ver.."\r\n")
							if ver ~= xmain.linkerdata.res_md5 then
								needfilelist = 1
							end
						end
					end
					line = f:read("*line")--next line
				end 
				f:close()
			else
				--无文件， 需要资源
				needfilelist = 1;
			end

			if needfilelist == 1 then -- 需要申请资源列表文件XWBASE_MSG_REQ_FILE  
				xmain.linkerdata.reslist = {}
				--加载原资源列表的MD5 
				--如果filelist_s.txt存在则应该使用此文件初始linkerdata.reslist
				path = setting.datapath.."/xworld/"..xmain.linkerdata.linker_xid.."/"..setting.platform.."/filelist_s.txt"
				local fres = io.open( path, 'r')
				if fres ~= nil then
					local line = fres:read("*line")
						while line do
							for k, md5, size, trans in string.gmatch(line, '(.+),(%w+),(%w+),(%w+)') do 
								xmain.linkerdata.reslist[k] = {md5, size, trans} -- 后一个为已完成
							end
							line = fres:read("*line")--next line
						end
					fres:close()
				else--使用filelist.txt
					path = setting.datapath.."/xworld/"..xmain.linkerdata.linker_xid.."/"..setting.platform.."/filelist.txt"
					xmain.linker:Print("req file:"..path.."\r\n")
					fres = io.open( path, 'r')
					if fres ~= nil then
						local line = fres:read("*line")
						while line do
							for k, md5, size in string.gmatch(line, '(.+),(%w+),(%w+)') do 
								xmain.linkerdata.reslist[k] = {md5, size, size} -- 后一个为已完成，老的都是完成的
							end
							line = fres:read("*line")--next line
						end
						fres:close()
					end
				end
				--写入临时更新文件列表，确定实际文件的写入情况

				--请求新资源列表文件
				xmain.ReqFile(xmain.linkerdata.xworldlinker, xmain.linkerdata.linker_xid.."/"..setting.platform.."/filelist.txt", 0, -1)
			else
			--直接加载默认入口lua
			--通知可以执行脚本程序了
				path = "xworld/"..xmain.linkerdata.linker_xid.."/"..setting.platform.."/lua/?.lua"  --/main.lua"
				package.path = ori_requirepath..";"..path
				--local module = xrequire("XWClient")

				--path = "xworld/"..xmain.linkerdata.linker_xid.."/"..setting.platform.."/lua/main"
				--xmain.linker:Print("do lua file : ".. path.."\r\n")
				--package.path = ori_requirepath..";"..path
				local module = xrequire("XWClient")
				Manager.Push("XWClient", module)
			end
		end
		
	end

	if msg == linker_proto.XWBASE_MSG_ON_FILE_FINISH then 
		error = buffer:ReadLong()
		local finishpos = buffer:ReadLong()
		local filenamelen = buffer:ReadLong()
		local filename = buffer:ReadString(filenamelen + 1)
		xmain.linker:Print("File Finish:"..filename.." ("..finishpos..")\r\n")
		
		local path = setting.datapath.."/xworld/"..xmain.linkerdata.linker_xid.."/"..setting.platform.."/filelist.txt"
		local f = string.find(filename, setting.platform.."/filelist.txt")
		local count =0
		if f ~= nil then
			--处理新的资源列表文件
			local freslist = io.open( path, 'r')
			
			if freslist ~= nil then
				xmain.linker:Print("open filelist:"..path.."\r\n")
				local line = freslist:read("*line")
				while line do
					for k, md5, size in string.gmatch(line, '(.+),(%w+),(%w+)') do --(.+)全字符串匹配 (%w+)数字或字母
						
						--xmain.linker:Print("filelist:"..k..md5..size.."\r\n")
						if xmain.linkerdata.reslist[k] ~= nil then
							if xmain.linkerdata.reslist[k][1] ~= md5 then -- md5不同的才需要变为等待传输
								xmain.linkerdata.reslist[k][1] = md5
								xmain.linkerdata.reslist[k][2] = size
								xmain.linkerdata.reslist[k][3] = -1 --还未开始获取
								count = count + 1
							else  
								xmain.linker:Print("filelist: reslist"..k.."\r\n")
							end
						else
							xmain.linkerdata.reslist[k] = {md5, size, -1}
							count = count + 1
						end
					end
					line = freslist:read("*line")--next line
				end
				freslist:close()
				
				xmain.linker:Print("File Update List Count:"..count.."\r\n")
			end
			--把资源处理情况写入临时文件
			path = setting.datapath.."/xworld/"..xmain.linkerdata.linker_xid.."/"..setting.platform.."/filelist_s.txt"
			local fres_state = io.open( path, 'w')
			
			if fres_state ~= nil then
				xmain.linker:Print("File Update state file:OK "..path.."\r\n")
				for k, v in pairs(xmain.linkerdata.reslist) do
					fres_state:write(k..","..v[1]..","..v[2]..","..v[3].."\n")--filepath, md5, size, writesize
				
				end

				fres_state:close()
			else
				xmain.linker:Print("File Update state file:Failed "..path.."\r\n")
			end
			
			xmain.linkerdata.needres = 1
		else -- other file finish
			local resline = xmain.linkerdata.reslist[filename]
			if resline == nil  then--尝试只获得platform后面的名称
				for w in string.gmatch(filename, setting.platform.."/(.+)") do
					resline = xmain.linkerdata.reslist[w]
					break
				end
			end

			if resline ~= nil then
				resline[3] = resline[2] --刷新资源更新列表
				--xmain.linker:Print("Reslist Finish: "..filename.."\r\n")
			else
				xmain.linker:Print("Reslist finish no line: "..filename.."\r\n")
			end
		end
		--
	end
end

function xmain.ResUpdate()
	-- body
	local count
	if  xmain.time - xmain.resupdate_time >= 3 then -- n秒1次
	
		xmain.resupdate_time = xmain.time
		if xmain.linkerdata.needres == 1  then
			--getcurtrans  count list
			local recvcount = 0
			local resline
			local trans_list = xmain.linker:GetFileTrans() -- v[1] filepath, v[2] filesize, v[3] already trans, v[4] 0:recv File, 1:send File
			for k, v in pairs(trans_list) do
				--xmain.linker:Print("File trans:"..v[1].." ("..v[3].."/"..v[2]..")"..v[4].."\r\n")
				if v[4] == 0 then
					resline = xmain.linkerdata.reslist[v[1]]
					if resline ~= nil then
						resline[3] = v[3] --刷新资源更新列表
					else
						xmain.linker:Print("Reslist no line:"..v[1].."\r\n")
					end
					recvcount = recvcount + 1
					xmain.linker:Print("File Recv:"..v[1].." ("..v[3].."/"..v[2]..")"..v[4].."\r\n")
				end
			end
			if recvcount < 2 then
				count = recvcount
				for k, v in pairs(xmain.linkerdata.reslist) do
					if count >= 2 then
						break
					end
					if v[2] ~= v[3] and v[3] ~= -1 then 
						xmain.linker:Print("File Recv Continue:"..k.." ("..v[3].."/"..v[2]..")".."\r\n")
						--xmain.ReqFile(xmain.linkerdata.xworldlinker, xmain.linkerdata.linker_xid.."/"..setting.platform.."/"..k, v[3], v[2])--断点续传
						count = count + 1
					else
						if v[3] == -1 then--已写入大小, -1为未开始
							xmain.linker:Print("File Recv Req:"..k.." ("..v[3].."/"..v[2]..")".."\r\n")
							xmain.ReqFile(xmain.linkerdata.xworldlinker, xmain.linkerdata.linker_xid.."/"..setting.platform.."/"..k, 0, -1)
							v[3] = 0
							count = count + 1
						end
					end
				end
			end
			--没有下载完，则应每n秒保存一下filelist_s.txt用以续传
			--...

			--判断是不是有没下载完的
			if count == 0 and recvcount == 0 then 
				--全部完成了， 写入filelist.txt文件 删掉(os.remove())filelist_s.txt文件 写入ver.txt
				local path = setting.datapath.."/xworld/"..xmain.linkerdata.linker_xid.."/"..setting.platform.."/filelist.txt"
				--处理新的资源列表文件
				local fres = io.open( path, 'w')
				if fres ~= nil then
					for k, v in pairs(xmain.linkerdata.reslist) do
						fres:write(k..","..v[1]..","..v[2].."\n")--name,md5,size
					end
					fres:close()
				end
				path = setting.datapath.."/xworld/"..xmain.linkerdata.linker_xid.."/"..setting.platform.."/filelist_s.txt"
				os.remove(path)--删掉(os.remove())filelist_s.txt文件
				path = setting.datapath.."/xworld/"..xmain.linkerdata.linker_xid.."/".."/ver.txt"
				local fver = io.open( path, 'w')--写入最新ver.txt
				if fver ~= nil then
					fver:write("[Init]\r\n")
					fver:write("MD5="..xmain.linkerdata.res_md5.."\r\n")
					fver:close()
				end
				xmain.linkerdata.needres = 0
				xmain.linkerdata.reslist = {}
				--通知可以执行脚本程序了
				path = "xworld/"..xmain.linkerdata.linker_xid.."/"..setting.platform.."/lua/?.lua"  --/main.lua"
				package.path = ori_requirepath..";"..path
				local module = xrequire("XWClient")
				Manager.Push("XWClient", module)
			end
		end
	end
end


--每33ms一次
function xmain.Update()
	
	xmain.time = os.time()--linker:GetCurTimeMS()/1000--

	for k, v in pairs(runmodule) do
		if v ~= this then
			if v.Update ~= xmain.Update then
				v.Update()
			else
				print("Error function circle!")
			end
		else
			print("Error module circle!")
		end
	end

	--资源更新
	xmain.ResUpdate()

	--Net
	local msgcount = 1
	local id, msg, buffer, luabuf
	local str

	while msgcount ~= 0 do
		msgcount = xmain.linker:GetMessageCount()
		if msgcount ~= 0 then
			buffer, id, msg = xmain.linker:GetMessage(xmain.msg_buffer)
			if id == 0 then 
				if msg == 0 then
					msgcount = 0
				 else--logon_server or center_server
					--luabuf = linkerbuffer(buffer)
					--xmain.linker:Print("Center msg id="..id.." MSG="..msg.."\r\n")
					xmain.CenterMsg(id, msg, xmain.msg_buffer)--logon msg
					--xmain.linker:Print(serialize(xmain.msg_buffer))
				 end
			else
				if msg >=100 and msg < 200 then
					xmain.CenterMsg(id, msg, xmain.msg_buffer)
				end
				if msg >=200 and msg < 300 then
					xmain.LinkerMsg(id, msg, xmain.msg_buffer)
				end
				--xmain.linker:Print("Linker Msg ID="..id.." MSG="..msg.."\r\n")
				--xmain.linker:Print(serialize(xmain.msg_buffer))
				if msg >= 20000 and msg < 30000 then
					--RPC Call
					xrpc.MsgCall(id, msg, this.msg_buffer) 
				end
				if msg < 3 then -- 0 断线， 1 accept ok  2 connect ok 
					if msg == 0 and id == this.linkerdata.xworldcenter then--此处需要重连XWorldCenter
						this.ConnectXworldCenter()
					else
						for k, v in pairs(runmodule) do
							v.LinkerState(id, msg)
						end
					end
				end
			end
		end
	end

end

function xmain.OnMsg(ID, Msg, Data)


end

function xmain.Link()
	--XLinker:Connect("491c5128813e837474512491c838813e", 32)
	--for i=1, 12 do
		--local n = XLinker:Connect("192.168.6.128", 19837)
		--table.insert(xmain.LinkerList, n)
		--xmain.LinkerList[i] = XLinker:Connect("192.168.6.128", 19837)
	--end
end

function xmain.GetUserData()
	local msgbuf = xworld.linkerbuffer();
	msgbuf:WriteShort(xworld_proto.XWORLD_MSG_GETDATA)
	msgbuf:WriteLong(0)-- type=0 Get all data 

	xmain.linker:Send(xmain.linkerdata.xworldcenter, msgbuf);
	xmain.linker:Print("Req UserData  center="..xmain.linkerdata.xworldcenter.." MSG="..xworld_proto.XWORLD_MSG_GETDATA.."\r\n")
end

function xmain.Send(str)
	--signin
	--xmain.linker:Logon("127.0.0.1", "11666", 1, account_name, password_md5, nick_name, invite_code)
	--xmain.linker:Logon("127.0.0.1", "11666", 1, "udxreg2", "abcd99")--

	--register
	xmain.linker:Logon("127.0.0.1", "11666", 0, "udxreg3", "abcd99", "hao", 1)
end

function xmain.Quit()
	for k, v in pairs(runmodule) do
		V.Quit()
	end
end
