
--[[
	主运行脚本
	从此脚本出发

	XLinker
	RPCRegister
	PRCCall
]]
--所有用到的文件都统一此处获得，为了总的清理，使用xrequire
--获得当前路径
local folderOfThisFile = (...):match("(.-)[^%.]+$")

local data = xrequire(folderOfThisFile.."data")

--global: UIMgr
local uimgr = xrequire(folderOfThisFile.."UI")

local ChoiceActor = xrequire(folderOfThisFile.."ChoiceActor")

local UILinkerList = xrequire(folderOfThisFile.."LinkerList")
local UILinkerList = xrequire(folderOfThisFile.."ProxyList")
local UILinkerList = xrequire(folderOfThisFile.."XPanel")
--...

XWClient = {}
local this = XWClient
this.SelfID = 0
this.UnitList = {}
this.LoadProcess = {}


local ServerNetID = 0
function XWClient.Init()
	print("xworld XWClient Init!("..data.worldname..")")
	
	this.linkerdata = XGetLinkerData();
	ServerNetID = this.linkerdata.xworldlinker
	
	--resMgr:LoadPrefab(Game.GetResFullPath('scene'), { 'scene' }, this.LoadSceneFinish);--外部资源都使用全路径
	--整合一个切换场景的方法
	Game.ChangeScene('scene.xwp', this.LoadSceneEnd)
	--coroutine.start(XWClient.CoFuncLoadScene)
end


function XWClient.LoadSceneEnd()
	local mainCam = GameObject.FindWithTag("MainCamera");
	local tr = mainCam.transform
	print("mainCam  ="..mainCam.name.." | Pos = "..tr.position.x..","..tr.position.y..","..tr.position.z );
	
	--local UICam = GameObject.FindWithTag("GuiCamera");

	--连接场景数据
	local data = {}
	local linkerdata = XGetLinkerData();
	data.name = linkerdata.nick_name;
	data.actor_res = linkerdata.actor_res --资源链接路径，一般是xid/actor/xxxx.xwp,开始应该没有
	XRPC.RPCCall(ServerNetID, "XWServer.Enter", data)
	print("Enter Server")
end

--同时只能有一个加载
function XWClient.LoadUnitRes(respath)--respath : xid / reletivepath / resname      或者 respath = {xid, reletivepath, resname}?
	-- 重组路径 --respath 需要中间插入 平台 "pc" "android" "ios"
	--local npos = 33--xid 32个字节 --string.find(respath, "/")
	--local xid = string.sub(respath, 0, 32) 
	--local npos2 = string.find(respath, ".xwp/" )
	--local resname = string.sub(respath, npos2 + 5, string.len(respath)) 
	--local reletivepath = string.sub(respath, 34, npos2 + 3) --无/
	--local abfullpath = Game.GetResRealPath(xid, reletivepath)--Application.dataPath.."/xworld/"..xid..this.linkerdata.platform..reletivepath

	--print("Load AB:"..respath)
	--resMgr:LoadPrefab(abfullpath, { resname }, this.LoadUnitResFinish);
	resMgr:LoadResource(respath, this.LoadUnitResFinish )
	--this.LoadingRes = respath
end

function XWClient.LoadUnitResFinish(objs)
	local gameObject = newObject(objs[0]);--resname
	if gameObject == nil then
		print("Load Res Error : "..this.Loading)
		return 
	end
	local tr = gameObject.transform;
	local user = this.UnitList[this.LoadProcess[this.Loading].id]
	user.tr = tr
	--获得Animation
	user.anim = tr:GetComponent('Animation');
	user.anim:Play("idle");
	--user.tr:position(Vector3.New(user.pos.x, user.pos.y, user.pos.z))
	tr.position = Vector3.New(user.pos.x, user.pos.y, user.pos.z)
	local vPos = user.tr.position
	print("User Pos: "..vPos.x..","..vPos.y..","..vPos.z)
	
	this.LoadProcess[this.Loading] = nil
	for k,v in pairs(this.LoadProcess) do 
		if v.loading == false then 
			v.loading = true
			this.Loading = k
			print("LoadUserRes "..v.res)
			this.LoadUnitRes(v.res) -- 开始进入下一个加载
			return 
		end
	end
end



function XWClient.LoadSceneFinish()
	print("Scene Load Finish!")
	
	--SceneManager.LoadSceneAsync("scene")
	
end

function XWClient.Update()
end

--
--function XWClient.OnMsg(id, msg, buffer)
--end

function XWClient.Quit()
	--释放
end

function XWClient.ChoiceResult( ActorRes )
	local linkerdata = XGetLinkerData();
	linkerdata.ActorRes = ActorRes
	local data = {actorres = ActorRes}
	print("Choice Actor Res:"..ActorRes)
	XRPC.RPCCall(ServerNetID, "XWServer.ChoiceActorResConfirm", data)
	--加载
end

function XWClient.ChoiceActorRes(ActorResChoice)
	print("XWClient.ChoiceActorRes")
	--打开界面
	--for i = 1, ActorResChoice.size then
	--	ActorResChoice.ActorRes[i]
	--end
	--ChoiceActor.SetData(ActorResChoice, this.ChoiceResult)
	--ChoiceActor.Init()
	--分析列表
end

function XWClient.EnterConfirm(SelfData)
	this.SelfID	= SelfData.id
	print("XWClient.EnterConfirm")
	
end

function XWClient.AroundUnitList(UnitList)
	--周围动态单位id
	local reqList = {idlist = {}}
	print("XWClient.AroundUnitList:"..#UnitList.idlist)
	for k, v in ipairs(UnitList.idlist) do
		if this.UnitList[k] == nil then
			table.insert(reqList.idlist, v)
		end
		print("Unit:"..v)
	end
	XRPC.RPCCall(ServerNetID, "XWServer.GetUnitsData", reqList)
end

function XWClient.UnitsData(Units)
	--返回周围单位的详细数据
	print("UnitsData:"..#Units.UnitList)
	--printTable(Units.UnitList)
	for k, v in pairs(Units.UnitList) do
		if this.UnitList[v.id] == nil then
			this.UnitList[v.id] = v
			--加载模型资源等
			table.insert(this.LoadProcess, {loading = false, id = v.id, res = v.res})
			--if this.LoadProcess[v.res]  == nil then
			--	print("LoadProcess add:"..v.id.." | res".. v.res)
			--	this.LoadProcess[v.res] = {loading = false, id = v.id}
			--end
		end
	end
	for k,v in pairs(this.LoadProcess) do 
		if v.loading == false then 
			v.loading = true
			this.Loading = k
			this.LoadUnitRes(v.res) -- 开始进入第一个加载
			print("LoadUserRes "..v.res)
			return 
		end
	end
end

function XWClient.LinkerList(data)
	print("Linkerlist:")--..#data.proxylist
	local UIProxy = UIMgr.OpenUI("UIProxyList")
	UIProxy.SetData(data)
	UIProxy.Show(true)

	--XPanel.Init()
	
	--local UIXPanel = UIMgr.OpenUI("XPanel")
	--UIXPanel.Show(true)
end

function XWClient.Hit()
	--鼠标点击
	if Input.GetMouseButtonDown(0) then
		local ray = this.mainCamera:ScreenPointToRay(Input.mousePosition);
		--local hit = RaycastHit.New();
		local bhit, hit = UnityEngine.Physics.Raycast(ray, nil)
		if bhit then
			print("hit pos: "..hit.point.x..","..hit.point.y..","..hit.point.z)
		else
			print("Hit Error")
		end
	end
end

function XWClient.Move(data)

end

function XWClient.Rent(data)

end


XRPC.RPCRegister("XWClient.EnterConfirm")
XRPC.RPCRegister("XWClient.ChoiceActorRes")--选择外表资源 传输多个路径，如果是defaultscene，应该资源已经存在，如果不存在则要求下载

XRPC.RPCRegister("XWClient.AroundUnitList")
XRPC.RPCRegister("XWClient.UnitsData")

XRPC.RPCRegister("XWClient.LinkerList")

XRPC.RPCRegister("XWClient.Move")
XRPC.RPCRegister("XWClient.Rent")

return this