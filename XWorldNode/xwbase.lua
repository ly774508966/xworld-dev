
--[[
	linkernode�����̺���

1.	XWorldLinker����XWorldLogonͨ���˺�����ע����¼XWorld��Ȼ����յ�xid��tocken��XWorldCenter��IP�Ͷ˿ڣ�
	������xid��token���´δ򿪿���ֱ������XWorldCenter��
2.	ͨ��xid��token����XWorldCenter���õ���������������Ĭ�Ͻڵ�ip��ַ����¼Ĭ��XWorldLinker�ڵ㡣
3.	���ӽڵ�󣬻������ڵ����Դ�汾���뱾�ر���ģ�ver.ini���Ƚϣ���ͬ��ֱ�ӵ��ñ���xid·���µ�xwclient.lua���У�
	��ͬ��������Դ�б��ļ���filelist.txt��,�뱾�ر���Ľڵ���Դ�б��ļ��Ƚ������ÿһ���ļ����ļ�����md5���ֽڣ���
	����������κ�md5��ͬ������ɾ�ļ��������뵽��Դ��ȡ�б��������봫��ReqFile���ײ��˫�����������߳̽����ļ���д��
	������Դ����ɺ󣬰ѱ��ؽڵ���Դ�б��ļ�filelist�Ͱ汾�ļ�ver.ini���档

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

--lua����C�ײ�ص�
--1.ע��ص�������2.���ã�3.���ͷ�
local XWCCallbackFunc = {}
local incID = 100000;
linker = {};

xwbase = {}
local this = xwbase

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

--c�ײ�ص�����
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

function this.Init(initparam)--�ⲿ�����ַ�������
	if initparam ~= nil then
		print("XWLinker Init : "..initparam)
		this.linkerdata.initparam = initparam

		for k, v in string.gmatch(initparam, "([%w_]+)=([%w._:\\/]+)") do
			print("param:"..k.." | "..v.."\n")
			if k == "proxy" then
				setting.type = 4
			end
			--���������˺�����
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
			--�ӳ�����unity�ͻ���
			if k == "delayrun" then
				this.linkerdata.delayrun = v
				print("DelayRun="..this.linkerdata.delayrun.."\n")
			end
			if k == "logonmode" then
				setting.logonmode = v
			end
			--ִ��lua
			if k == "lua" then
				loadstring(v)
			end
		end

		--if initparam == "proxy" then
		--	setting.type = 4
		--end
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
	print("Create Linker Proxy :"..data.xid..", token="..data.token..", type="..setting.type.."\n")
	setting.linker_port = setting.linker_port + math.random(100)
	setting.proxyserver = nil -- ������ķ����ǲ�Ҫ�ٿ�����������
	--if setting.logonmode ~= nil then
	linker = xworld.linker(setting.linker_ip, setting.linker_port, setting.type, "")--setting.type
	
	if linker == nil then
		print("Create Base Linker Error!")
	end
	if setting.type >=2 then 
		setting.linker_ip = linker:GetOuterIP()--�ṩ�����ip��Ҫ�����������ip��ַ
	end
	print("OuterIP :"..setting.linker_ip.." : "..setting.linker_port.."\r\n");

	linker:SetDataPath(".")

	this.linkerdata.xid = data.xid
	this.linkerdata.nick_name = data.nick_name
	this.linkerdata.xcenter_ip = data.xcenter_ip
	this.linkerdata.xcenter_port = data.xcenter_port
	this.linkerdata.token = data.token
	print("token :"..data.token.."\r\n");
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
		setting.linker_ip = linker:GetOuterIP()--�ṩ�����ip��Ҫ�����������ip��ַ
	end
	print("OuterIP :"..setting.linker_ip.." : "..setting.linker_port.."\r\n");

	linker:SetDataPath(".")

	--�ڲ���¼��ʹ�ô洢�õ��˺����� --setting.logonmode
	linker:XWLogon(setting, XWCCallbackCreate(this.LogonCallback))
end

function this.ConnectXWorldLinkerBase(ip, port)
	if this.linkerdata.xworldlinker ~= nil then
		XWCCallbackDelete(this.linkerdata.xworldlinker)
	end
	this.linkerdata.xworldlinker = linker:Connect(ip, port)--�Զ�������Ϣ��id�ϵ�
	--����Ϣ���պ���
	XWCCallbackCreateByNetID(this.XWorldLinkerMsg, this.linkerdata.xworldlinker)
	return this.linkerdata.xworldlinker
end


function this.LogonCallback(data)--data.error data.errorstring
	if data.error == 0 then-- ok data.xid data.token data.nick_name   xworldcenterip
		--����XWorldCenter
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
			--�Ƿ�����
			this.linkerdata.ConnectCount = this.linkerdata.ConnectCount + 1
			if this.linkerdata.ConnectCount < 5 then
				linker:XWLogon(setting, XWCCallbackCreate(this.LogonCallback))
			end
		end
	end
end

function this.ReqXWorldProxy(ip, port)
	local proxy = this.ConnectXWorldLinkerBase(ip, port)
	--�������
	local error = linker:XWReqProxy(proxy, XWCCallbackCreate(this.XWorldLinkerProxyCallback))
end

function this.XWorldLinkerProxyCallback(data)
end

--���ķ�
function this.XWorldCenterCallback(data)
	print("XWorldCenter Callback !\n")
	if data.error == 0 then-- ok ������ķ�����
		print("Money:"..data.money.."\n")
		--[[
		data.money	data.point	data.xwp data.exp	data.level	data.id	data.defaultlinker_ip data.defaultlinker_port
		]]
		if  setting.type == 2 then -- ����ڵ� ����Բ��ü������ӳ�������
			--�����������˳���
			print("test: ".. setting.type)
			path = "xworld/"..this.linkerdata.xid.."/server/?.lua"  --/main.lua"
			print("Server Run Path: ".. path)
			package.path = ori_requirepath..";"..path
			this.module = xrequire("xwserver")
			if this.module ~= nil then
				print("xwserver.lua load ok!\r\n")
				this.module.Init()
			end
			if setting.proxyserver ~= nil then
				--��ʼ���������
				print("proxy server Init!\r\n")
				linker:ProxyInit(this.linkerdata.xcenter_ip,this.linkerdata.xcenter_port)
			end
			--�ӳٱ�������unity�ͻ���
			if this.linkerdata.delayrun ~= nil then
				local command = this.linkerdata.delayrun.." account="..setting.account.." password="..setting.password.." linkxid="..this.linkerdata.xid
				print("Run client�� "..command.."\n")
				--linkxid account password
				linker:SystemRun(command)
				this.linkerdata.delayrun = nil
			end
		else 
			if setting.type == 4 then--�������
				-- ����Ӧ����xwcenter�����ô���ڵ㣬�������������ֱ��д���Խڵ��ip�Ͷ˿�
				 --this.ReqXWorldProxy("127.0.0.1", 30711)
				 this.ReqXWorldProxy()
			end
			print("Linker Run Type: ".. setting.type)
		end
	else
		--error
		print("XWorldCenter Connect Failed: ".. setting.type)
		if data.errorstring ~= nil then
			print(data.errorstring)
			--�Ƿ�����
			this.linkerdata.ConnectCount = this.linkerdata.ConnectCount + 1
			if this.linkerdata.ConnectCount < 5 then
				linker:XWLogon(setting, XWCCallbackCreate(this.LogonCallback))
			end
		end
	end
end

--���ӵ�linker��Ϣ
function this.XWorldLinkerMsg(data)--c�д����table
	if data.msg >= 20000 and data.msg < 30000 then
		print("XWorldLinkerMsg( "..data.id..", "..data.msg..", "..data.json.." )\n")
		xrpc.MsgJsonCall(data.id, data.msg, data.json)
	end
end

function this.Update()
	linker:Update()--�ڲ��������ݴ���
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
