--[[
	XWORLD
	XWServer
	xiewei
	主服务端运行脚本

	XLinker
	RPCRegister
	PRCCall

	--客户端只需要发出操作行为
	--服务端把此行为验证合理化，转发给周围的人（SendAround）
	--服务端把场景ai单位行为，转发给周围的人（SendAround）
	
	--服务端定期同步（3秒）周围单位id给客户端，客户端确定id是否新加入的，新加入则显示临时加载中模型（或者linker自己的显示方式，如文本），
		Send(id, idlist)
		通过id询问服务端资源名，资源有则直接加载，无则向服务端申请，传输完资源自动加载，加载完自动切换模型。

	--基本场景运行：
		1.初始化几个动态单位，不定时移动
		2.用户进入，同步单位信息
	
	linker方法
	{ "GetOuterIP", }, //获得自身公网ip
	{ "Logon", }, //登录账号
	{ "Connect",  },//连接其他节点 或中心服otherid = linkernode:connect
	{ "UpdateRes",  },//更新资源
	{ "GetFileTrans", },//获得文件传输状况
	{ "Send" ,  },//发送信息
	{ "SendAround" ,  },//单位（可以user和npc）行为发送给周围用户（user） (int sceneid, int id, buffer )
	{ "SendSceneAll" ,  },//单位（可以user和npc）行为发送给全场景用户（user）
	{ "SetSceneArea" ,  },//初始化场景大小和发送范围，用来计算发送行为 (int sceneid, float fxmin, float fxmax, float fzmin, float fzmax, int aroundgrid)
	{ "SetSceneUser" ,  },//设置用户进入场景  （int sceneid, int id, int bEnter）
	{ "SetPos" ,  },//设置单位在场景的位置  (int sceneid, int id, float xDest, float yDest, float zDest)

	{ "GetAroundUnit" ,  },//获得周围单位（可以user和npc） (int sceneid, int id) 返回数组
	{ "GetCurTimeMS", },//获得当前时间，精度毫秒

	{ "Disconnect", },
	{ "Quit",  },
	{ "GetMessageCount",  },
	{ "GetMessage",  }, 
]]

--获得当前路径
local folderOfThisFile = (...):match("(.-)[^%.]+$")

xrequire(folderOfThisFile.."Vector3")
--local data = xrequire(folderOfThisFile.."data")
--...
local server_data = { scenename = "Default Server"}

server_data.actor_res = { "5e561dc7068a73ab000000017f000001/res_character_zombie_models.xwp/MaleZombie"} --xid / path  / res


XWServer = {}
local this = XWServer

this.UnitList = {}--ObjectList[id] = object; object= {name, res, type,pos}

local LinkerSceneID = 0  -- 可设置0-4， 最大可以同时有5个场景

function XWServer.LinkerState(id, state)--msg: 0 断线 1 accept ok 2 connect ok
	print("LinkerState:"..id.." | state="..state.."\r\n")
	if state == 0 then
		--断线处理
		if this.UnitList[id] ~= nil then
			--离开底层
			linker:SetPos(LinkerSceneID, id, 100001, 0, 0)--设置一个大数 ，大于边界 1000以上，则表示退出场景
			this.UnitList[id] = nil
		end
	end
end

function XWServer.Init()
	print(" new xworld XWServer Begin!(Default Server)\r\n")
	--初始化世界
	--选用第0号(LinkerSceneID = 0)场景管理关联， 地图区域为（0，0），（256，256）， 场景会动态划分为20*20区域，单位间可见范围为3格区域（感知搜索范围大小为5*5）
	this.SceneMin = Vector3.New(0, 0, 0)
	this.SceneMax = Vector3.New(256,0,256)
	linker:SetSceneArea(LinkerSceneID, this.SceneMin.x, this.SceneMax.x, this.SceneMin.z, this.SceneMax.z, 5)
	local UnitID = 0
	for i = 1 , 3 do 
		--初始化在场景的位置
		local UnitPos = Vector3.New(65+ math.random(-10,10), 1, 55+ math.random(-10,10))
		--初始化超过1000000的npc专用id
		UnitID = 1000000+i
		this.UnitList[UnitID] = {id = UnitID, name = "npc"..UnitID, type = "npc", pos = UnitPos, res = server_data.actor_res[1], state = "idle", speed = 2, ActionTime = 0}
		--设置单位的位置到底层，第一次是加入到底层场景单位交互管理，以后有任何移动都需要设置
		linker:SetPos(LinkerSceneID, UnitID, UnitPos.x, UnitPos.y, UnitPos.z)
	end
	this.LastTime = linker:GetCurTimeMS()--获得当前精确时间
	this.LastUpdateUnits = linker:GetCurTimeMS()--获得当前精确时间
end

local vTemp = Vector3.New(0,0,0)

function XWServer.Update()
	local CurTime = linker:GetCurTimeMS()--获得当前精确时间 ms毫秒
	local DeltaTime_S = (this.LastTime - CurTime)/1000 --获得帧间隔 秒
	this.LastTime = CurTime

	if LinkerSceneID ~= nil then
		return
	end 
	--根据用户行走，给予周围活动单位的资源列表
	local bDest = false
	for k,v in pairs(this.UnitList) do
		--this.UnitList.Update() ?
		if v.state == "goto" then
			vTemp:set(v.vec.x, v.vec.y, v.vec.z)
			vTemp:Mul(DeltaTime_S)
			vTemp:Add(v.pos)
			--判定是否到达目的地
			bDest = false
			if fabs(v.dest.x - v.pos.x) > 0.000001 then
				if (v.dest.x - v.pos.x) * (v.dest.x - vTemp.x) < 0 then
					bDest = true
				end
			else
				if (v.dest.z - v.pos.z) * (v.dest.z - vTemp.z) < 0 then
					bDest = true
				end
			end
			linker:SetPos(LinkerSceneID, k, v.pos.x, v.pos.y, v.pos..z)
			-- 位移了需要同步周围的情况
			if bDest == true then
				--恢复站立状态
				v.state = "idle"
				v.pos:set(v.dest.x, v.dest.y, v.dest.z)
				--到达目的地需要发送一次行为
				local data = {UnitID = k, x = v.dest.x, y = v.dest.y, z = v.dest.z}
				XRPC.RPCCallAround(LinkerSceneID, k, "XWClient.Move", data)
				
				local ids = linker:GetAroundUnit(LinkerSceneID, k)
				data = {idlist = ids}
				XRPC.RPCCall(k, "XWClient.AroundUnitList", data)
				v.ActionTime = CurTime
			else
				v.pos:set(v.vTemp.x, v.vTemp.y, v.vTemp.z)
				if  v.ActionTime - CurTime > 2000 then
					v.ActionTime = CurTime
					--一定时长向周围广播自己要移动到某个点
					local data = {UnitID = k, x = v.dest.x, y = v.dest.y, z = v.dest.z}
					XRPC.RPCCallAround(LinkerSceneID, k, "XWClient.Move", data)
					--有移动的单位需要判定是否取周围区域的单位返回（需要大于一定时长间隔才取下一次）
					local ids = linker:GetAroundUnit(LinkerSceneID, k)
					data = {idlist = ids}
					XRPC.RPCCall(k, "XWClient.AroundUnitList", data)
				end 
			end
		end
	end

	--定时刷新单位给周围角色
	--if this.LastUpdateUnits - CurTime > 3000 then
		--this.LastUpdateUnits = CurTime
		--
	--end
end

function XWServer.Quit()
end

--client action


--客户端进入此世界
function XWServer.Enter(data)
	--收到客户端的进入
	print("user enter："..data.name.." | NetId="..data.NetID.."\r\n" )
	--用户需要单独设置到场景用户列表里，用来发送全场消息，   1为进入，0为退出
	linker:SetSceneUser(LinkerSceneID, data.NetID, 1)

	--设置昵称和位置
	local UnitPos = Vector3.New(55+ math.random(-5,5), 1, 45+ math.random(-5,5))
	this.UnitList[data.NetID] = {id = data.NetID, name = data.name, type = "user", pos = UnitPos, res = server_data.actor_res[1], state = "idle", speed = 2, ActionTime = 0}
	
	linker:SetPos(LinkerSceneID, data.NetID, UnitPos.x, UnitPos.y, UnitPos.z)

	--返回id给客户端，让客户端知道自己的对象是哪个
	local enterok = {id = data.NetID, name = data.name}
	XRPC.RPCCall(data.NetID, "XWClient.EnterConfirm", enterok)

	if server_data.actor_res == nil then--让用户选择形象
		local res_choice = {size = #ActorRes, id = data.NetID, ResList = server_data.actor_res}
		XRPC.RPCCall(data.NetID, "XWClient.ChoiceActorRes", res_choice)
	end
	--获得周围的单位
	local ids = linker:GetAroundUnit(LinkerSceneID, data.NetID)
	msgdata = {idlist = ids}
	print("id size: "..#ids.."\r\n")
	for k, v in ipairs(ids) do
		print("id ="..k..","..v.."\r\n")
	end
	XRPC.RPCCall(data.NetID, "XWClient.AroundUnitList", msgdata)
end

function XWServer.ChoiceActorResConfirm(data)
	this.UnitList[data.NetID].res = data.actorres
end

function XWServer.GetUnitsData(data)

	local UnitsData = {UnitList = {}}
	for k, v in pairs(data.idlist) do
		--UnitsData.UnitList[v] = this.UnitList[v]
		table.insert(UnitsData.UnitList, this.UnitList[v])
	end
	print("user GetUnitsData： NetId="..data.NetID.."\r\n" )
	XRPC.RPCCall(data.NetID, "XWClient.UnitsData", UnitsData) 
end

--客户端行走
function XWServer.Move(data)
	--收到客户端的移动行为 SendAround
	--判定合理性
	if data.x < this.SceneMin.x or data.x > this.SceneMax.x or data.z < this.SceneMin.z or data.z > this.SceneMax.z then
		return
	end

	local User = this.UnitList[data.NetID]
	if User~= nil then
		User.state = "goto"
		if User.dest == nil then
			User.dest = Vector3.New(data.x, data.y, data.z)
			User.vec  = Vector3.New(data.x, data.y, data.z)
		else
			User.dest:set(data.x, data.y, data.z)
			User.vec:set(data.x, data.y, data.z)
		end
		--计算出速度
		User.vec:Sub(User.pos)
		User.vec:Normalize()
		User.vec:Mul(User.speed)
	end
	
	--发送给其他端
	data.UnitID = data.NetID -- NetID在客户端系统可能会改变为服务端的连接id，所以这里设置一下操作者给客户端

	this.UnitList[data.NetID].ActionTime = this.LastTime -- 记录操作时间
	XRPC.RPCCallAround(LinkerSceneID, data.NetID, "XWClient.Move", data)--发送到 LinkerSceneID号场景 的 data.NetID用户 的周围用户
end

function XWServer.Rent(data)
	--客户端要租赁土地房屋
end

XRPC.RPCRegister("XWServer.Enter")
--XRPC.RPCRegister("XWServer.ChoiceActorRes")
XRPC.RPCRegister("XWServer.ChoiceActorResConfirm")
XRPC.RPCRegister("XWServer.GetUnitsData")
XRPC.RPCRegister("XWServer.Move")
XRPC.RPCRegister("XWServer.Rent")

return this