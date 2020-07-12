
--[[
	linkernode的流程函数

1.	XWorldLinker连接XWorldLogon通过账号密码注册或登录XWorld，然后接收到xid和tocken和XWorldCenter的IP和端口，
	并保存xid和token，下次打开可以直接连接XWorldCenter。
2.	通过xid和token连接XWorldCenter，得到基础核心数据与默认节点ip地址，登录默认XWorldLinker节点。
3.	连接节点后，会检查进入节点的资源版本号与本地保存的（ver.ini）比较，相同则，直接调用本地xid路径下的xwclient.lua运行；
	不同则请求资源列表文件（filelist.txt）,与本地保存的节点资源列表文件比较里面的每一行文件（文件名，md5，字节），
	如果里面有任何md5不同，或增删文件，都列入到资源获取列表里，逐个申请传输ReqFile，底层会双方建立独立线程进行文件读写。
	所有资源都完成后，把本地节点资源列表文件filelist和版本文件ver.ini保存。

]]
xworld = require("xworld_core")

 json = require "cjson"
 xrpc = require "XRPC"
 require "setting"

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

--lua函数C底层回调
--1.注册回调函数；2.调用；3.自释放
local XWCCallbackFunc = {}
local incID = 100000;
linker = {};

xwreqproxy = {}
local this = xwreqproxy

this.linkerdata = {}

function XWCCallbackCreate(func, always)
	incID = incID + 1
	if always == nil or always == 0 then
		XWCCallbackFunc[incID+10000000] = func
		--print("Reg CallBack: "..incID.."+10000000\n")
		return incID+10000000
	else
		XWCCallbackFunc[incID] = func
		--print("Reg CallBack: "..incID.."\n")
		return incID
	end
end

function XWCCallbackCreateByNetID(func, netid)
	XWCCallbackFunc[netid] = func
end

function XWCCallbackDelete(id)
	XWCCallbackFunc[id] = nil
end

--c底层回调函数
function XWCCallback(tParam)
	--print("CallBack: "..tParam.funcid)
	if tParam.msg ~= nil and tParam.msg >= 20000 and tParam.msg < 30000 then
		print("CallBack: "..tParam.msg)
		this.XWorldLinkerMsg(tParam)
		return 
	end
	local func = XWCCallbackFunc[tParam.funcid]
	if func ~= nil then
		func(tParam)
		if tParam.funcid > 10000000 then
			XWCCallbackFunc[tParam.funcid] = nil
		end
	end
end

function this.Init(initparam)--外部传入字符串参数
	if initparam ~= nil then
		print("XWLinker Init : "..initparam)
		this.linkerdata.initparam = initparam

		for k, v in string.gmatch(initparam, "([%w_]+)=([%w._:\\/]+)") do
			print("param:"..k.." | "..v.."\n")
			if k == "proxy" then
				this.linkerdata.reqlinkerxid = v
				setting.type = 4
			end
			--参数填入账号密码
			if k == "account" then 
				setting.account = v
			end
			if k == "password" then 
				setting.password = v
			end
			if k == "linker_ip" then 
				setting.linker_ip = v
				print(setting.linker_ip.."\n")
			end
			if k == "type" then
				if type(v) == "number" then
					setting.type = v
				else
					setting.type = tonumber(v)
				end
			end
			--延迟运行unity客户端
			if k == "delayrun" then
				this.linkerdata.delayrun = v
				print("DelayRun="..this.linkerdata.delayrun.."\n")
			end
			if k == "logonmode" then
				setting.logonmode = v
			end
			--执行lua
			if k == "lua" then
				loadstring(v)
			end
		end

	else
		print("XWLinker Init!")
	end
	if setting.logonmode == nil then
		setting.logonmode = "1"
	end
	this.linkerdata.ConnectCount = 0
	this.StartServer(setting)
end

function this.InitProxy(data)--data : xid token xcenter_ip xcenter_port nick_name linker_port
	print("Create Linker Proxy :"..data.xid.."\n")
	setting.linker_port = setting.linker_port + math.random(100)
	--if setting.logonmode ~= nil then
	linker = xworld.linker(setting.linker_ip, setting.linker_port, setting.type, "")--setting.type
	
	if linker == nil then
		print("Create Base Linker Error!")
	end
	if setting.type >=2 then 
		setting.linker_ip = linker:GetOuterIP()--提供服务的ip需要获得最终外网ip地址
	end
	print("OuterIP :"..setting.linker_ip.." : "..setting.linker_port.."\r\n");

	linker:SetDataPath(".")

	this.linkerdata.xid = data.xid
	this.linkerdata.nick_name = data.nick_name
	this.linkerdata.xcenter_ip = data.xcenter_ip
	this.linkerdata.xcenter_port = data.xcenter_port
	this.linkerdata.token = data.token
	
	linker:XWCenterConnect(data.xcenter_ip, data.xcenter_port, data.xid, data.token, XWCCallbackCreate(this.XWorldCenterCallback))
end

function this.StartServer(setting)
	--logon
	print("Create Linker ......")
	linker = xworld.linker(setting.linker_ip, setting.linker_port, setting.type, "")
	if linker == nil then
		print("Create Base Linker Error!")
	end
	if setting.type >=2 then 
		setting.linker_ip = linker:GetOuterIP()--提供服务的ip需要获得最终外网ip地址
	end
	print("OuterIP :"..setting.linker_ip.." : "..setting.linker_port.."\r\n");

	linker:SetDataPath(".")

	--内部登录或使用存储好的账号密码 --setting.logonmode
	linker:XWLogon(setting, XWCCallbackCreate(this.LogonCallback))
end

function this.ConnectXWorldLinkerBase(ip, port)
	if this.linkerdata.xworldlinker ~= nil then
		XWCCallbackDelete(this.linkerdata.xworldlinker)
	end
	this.linkerdata.xworldlinker = linker:Connect(ip, port)--自动返回消息到id上的
	--绑定消息接收函数
	XWCCallbackCreateByNetID(this.XWorldLinkerMsg, this.linkerdata.xworldlinker)
	return this.linkerdata.xworldlinker
end


function this.LogonCallback(data)--data.error data.errorstring
	if data.error == 0 then-- ok data.xid data.token data.nick_name   xworldcenterip
		--连接XWorldCenter
		print("Logon OK ! xid: "..data.xid.." | "..data.token.."\n")
		this.linkerdata.xid = data.xid
		this.linkerdata.nick_name = data.nick_name
		this.linkerdata.xcenter_ip = data.xcenter_ip
		this.linkerdata.xcenter_port = data.xcenter_port
		this.linkerdata.token = data.token
		linker:XWCenterConnect(data.xcenter_ip, data.xcenter_port, data.xid, data.token, XWCCallbackCreate(this.XWorldCenterCallback))
	else
		--error
		if data.errorstring ~= nil then
			print(data.errorstring)
			--是否重连
			this.linkerdata.ConnectCount = this.linkerdata.ConnectCount + 1
			if this.linkerdata.ConnectCount < 5 then
				linker:XWLogon(setting, XWCCallbackCreate(this.LogonCallback))
			end
		end
	end
end

--[[function this.ReqLinker(xidstring)
	local xidbuffer = helper.hex2bin(xidstring)
	local sendbuffer = xworld.linkerbuffer()
	sendbuffer:WriteShort(xworld_proto.XWORLD_MSG_REQ_LINKER)
	sendbuffer:WriteBuffer(xidbuffer, 16)
	linker:Send(this.linkerdata.xworldcenter, sendbuffer)
end]]

function this.ReqXWorldProxy(ip, port)
	local proxy = this.ConnectXWorldLinkerBase(ip, port)
	--请求代理
	local error = linker:XWReqProxy(proxy, XWCCallbackCreate(this.XWorldLinkerProxyCallback))
end

function this.XWorldLinkerProxyCallback(data)
end

--中心服
function this.XWorldCenterCallback(data)
	print("XWorldCenter Callback !\n")
	if data.error == 0 then-- ok 获得中心服数据
		print("Money:"..data.money.."\n")
		--[[
		data.money	data.point	data.xwp data.exp	data.level	data.id	data.defaultlinker_ip data.defaultlinker_port
		]]
		if  setting.type == 2 then -- 服务节点 则可以不用继续连接场景服了
			--开启自身服务端程序
			print("test: ".. setting.type)
			path = "xworld/"..this.linkerdata.xid.."/server/?.lua"  --/main.lua"
			print("Server Run Path: ".. path)
			package.path = ori_requirepath..";"..path
			this.module = xrequire("xwserver")
			if this.module ~= nil then
				print("xwserver.lua load ok!\r\n")
				this.module.Init()
			end
			--延迟本地运行unity客户端
			if this.linkerdata.delayrun ~= nil then
				local command = this.linkerdata.delayrun.." account="..setting.account.." password="..setting.password.." linkxid="..this.linkerdata.xid
				print("Run client： "..command.."\n")
				--linkxid account password
				linker:SystemRun(command)
				this.linkerdata.delayrun = nil
			end
		else 
			if setting.type == 4 then--请求代理
				-- 本来应该向xwcenter请求获得代理节点
				-- this.ReqXWorldProxy("127.0.0.1", 30711)
				if this.linkerdata.reqlinkerxid ~= nil then 
					print("req linker "..this.linkerdata.reqlinkerxid.."\n")
					linker:XWReqProxy(this.linkerdata.reqlinkerxid)
				end
			end
			print("Linker Run Type: ".. setting.type)
		end
	else
		--error
		print("XWorldCenter Connect Failed: ".. setting.type)
		if data.errorstring ~= nil then
			print(data.errorstring)
			--是否重连
			this.linkerdata.ConnectCount = this.linkerdata.ConnectCount + 1
			if this.linkerdata.ConnectCount < 5 then
				linker:XWLogon(setting, XWCCallbackCreate(this.LogonCallback))
			end
		end
	end
end

--连接的linker消息
function this.XWorldLinkerMsg(data)--c中传入的table
	
	if data.msg >= 20000 and data.msg < 30000 then
		print("XWorldLinkerMsg( "..data.id..", "..data.msg..", "..data.json.." )\n")
		xrpc.MsgJsonCall(data.id, data.msg, data.json)
	end
	if data.msg >=100 and data.msg < 200 then
		if data.msg == XWORLD_MSG_REQ_LINKER_RESULT then
			error = buffer:ReadLong()
			if error == 0 then
				this.linkerdata.linker_ip = buffer:ReadString(16)
				this.linkerdata.linker_port = buffer:ReadLong()
				this.linkerdata.linker_token = buffer:ReadBuffer(32)
				--this.EnterLinker(this.linkerdata.linker_ip, this.linkerdata.linker_port)
				if this.linkerdata.reqlinkerxid ~= nil then
					print("Proxy Linker: "..this.linkerdata.reqlinkerxid.." | "..this.linkerdata.linker_ip.." : "..this.linkerdata.linker_port)
				end
				this.ReqXWorldProxy(this.linkerdata.linker_ip, this.linkerdata.linker_port)
			else
				if this.linkerdata.reqlinkerxid ~= nil then
					print("Request XID Linker Error : "..this.linkerdata.reqlinkerxid.." | Error code: "..error)
				end
			end
		end
	end
end

function this.Update()
 	--if linker ~= nil then
		linker:Update()--内部网络数据处理
	--end
	if this.module ~= nil then
		this.module.Update()
	end
end

function this.CreateNewNode(setting)
	--linker:CreateNewNode(setting,  XWCCallbackCreate(NewNodeCallback))
end

--[[
--sample
function LogonCallback(data)//data.error data.errorstring

end
logon(tData, XWCCallbackCreate(LogonCallback))

logon(tData, XWCCallbackCreate(
	function () 
		print("callback") 
	end))
	]]
