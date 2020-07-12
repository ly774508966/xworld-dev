
--[[
	�����нű�
	�Ӵ˽ű�����

	XLinker
	RPCRegister
	PRCCall
]]
--�����õ����ļ���ͳһ�˴���ã�Ϊ���ܵ�����ʹ��xrequire
--��õ�ǰ·��
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
	
	--resMgr:LoadPrefab(Game.GetResFullPath('scene'), { 'scene' }, this.LoadSceneFinish);--�ⲿ��Դ��ʹ��ȫ·��
	--����һ���л������ķ���
	Game.ChangeScene('scene.xwp', this.LoadSceneEnd)
	--coroutine.start(XWClient.CoFuncLoadScene)
end


function XWClient.LoadSceneEnd()
	local mainCam = GameObject.FindWithTag("MainCamera");
	local tr = mainCam.transform
	print("mainCam  ="..mainCam.name.." | Pos = "..tr.position.x..","..tr.position.y..","..tr.position.z );
	
	--local UICam = GameObject.FindWithTag("GuiCamera");

	--���ӳ�������
	local data = {}
	local linkerdata = XGetLinkerData();
	data.name = linkerdata.nick_name;
	data.actor_res = linkerdata.actor_res --��Դ����·����һ����xid/actor/xxxx.xwp,��ʼӦ��û��
	XRPC.RPCCall(ServerNetID, "XWServer.Enter", data)
	print("Enter Server")
end

--ͬʱֻ����һ������
function XWClient.LoadUnitRes(respath)--respath : xid / reletivepath / resname      ���� respath = {xid, reletivepath, resname}?
	-- ����·�� --respath ��Ҫ�м���� ƽ̨ "pc" "android" "ios"
	--local npos = 33--xid 32���ֽ� --string.find(respath, "/")
	--local xid = string.sub(respath, 0, 32) 
	--local npos2 = string.find(respath, ".xwp/" )
	--local resname = string.sub(respath, npos2 + 5, string.len(respath)) 
	--local reletivepath = string.sub(respath, 34, npos2 + 3) --��/
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
	--���Animation
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
			this.LoadUnitRes(v.res) -- ��ʼ������һ������
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
	--�ͷ�
end

function XWClient.ChoiceResult( ActorRes )
	local linkerdata = XGetLinkerData();
	linkerdata.ActorRes = ActorRes
	local data = {actorres = ActorRes}
	print("Choice Actor Res:"..ActorRes)
	XRPC.RPCCall(ServerNetID, "XWServer.ChoiceActorResConfirm", data)
	--����
end

function XWClient.ChoiceActorRes(ActorResChoice)
	print("XWClient.ChoiceActorRes")
	--�򿪽���
	--for i = 1, ActorResChoice.size then
	--	ActorResChoice.ActorRes[i]
	--end
	--ChoiceActor.SetData(ActorResChoice, this.ChoiceResult)
	--ChoiceActor.Init()
	--�����б�
end

function XWClient.EnterConfirm(SelfData)
	this.SelfID	= SelfData.id
	print("XWClient.EnterConfirm")
	
end

function XWClient.AroundUnitList(UnitList)
	--��Χ��̬��λid
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
	--������Χ��λ����ϸ����
	print("UnitsData:"..#Units.UnitList)
	--printTable(Units.UnitList)
	for k, v in pairs(Units.UnitList) do
		if this.UnitList[v.id] == nil then
			this.UnitList[v.id] = v
			--����ģ����Դ��
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
			this.LoadUnitRes(v.res) -- ��ʼ�����һ������
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
	--�����
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
XRPC.RPCRegister("XWClient.ChoiceActorRes")--ѡ�������Դ ������·���������defaultscene��Ӧ����Դ�Ѿ����ڣ������������Ҫ������

XRPC.RPCRegister("XWClient.AroundUnitList")
XRPC.RPCRegister("XWClient.UnitsData")

XRPC.RPCRegister("XWClient.LinkerList")

XRPC.RPCRegister("XWClient.Move")
XRPC.RPCRegister("XWClient.Rent")

return this