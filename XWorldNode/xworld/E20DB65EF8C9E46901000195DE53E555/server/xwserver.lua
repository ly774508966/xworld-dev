--[[
	XWORLD
	XWServer
	xiewei
	����������нű�

	XLinker
	RPCRegister
	PRCCall

	--�ͻ���ֻ��Ҫ����������Ϊ
	--����˰Ѵ���Ϊ��֤������ת������Χ���ˣ�SendAround��
	--����˰ѳ���ai��λ��Ϊ��ת������Χ���ˣ�SendAround��
	
	--����˶���ͬ����3�룩��Χ��λid���ͻ��ˣ��ͻ���ȷ��id�Ƿ��¼���ģ��¼�������ʾ��ʱ������ģ�ͣ�����linker�Լ�����ʾ��ʽ�����ı�����
		Send(id, idlist)
		ͨ��idѯ�ʷ������Դ������Դ����ֱ�Ӽ��أ��������������룬��������Դ�Զ����أ��������Զ��л�ģ�͡�

	--�����������У�
		1.��ʼ��������̬��λ������ʱ�ƶ�
		2.�û����룬ͬ����λ��Ϣ
	
	linker����
	{ "GetOuterIP", }, //���������ip
	{ "Logon", }, //��¼�˺�
	{ "Connect",  },//���������ڵ� �����ķ�otherid = linkernode:connect
	{ "UpdateRes",  },//������Դ
	{ "GetFileTrans", },//����ļ�����״��
	{ "Send" ,  },//������Ϣ
	{ "SendAround" ,  },//��λ������user��npc����Ϊ���͸���Χ�û���user�� (int sceneid, int id, buffer )
	{ "SendSceneAll" ,  },//��λ������user��npc����Ϊ���͸�ȫ�����û���user��
	{ "SetSceneArea" ,  },//��ʼ��������С�ͷ��ͷ�Χ���������㷢����Ϊ (int sceneid, float fxmin, float fxmax, float fzmin, float fzmax, int aroundgrid)
	{ "SetSceneUser" ,  },//�����û����볡��  ��int sceneid, int id, int bEnter��
	{ "SetPos" ,  },//���õ�λ�ڳ�����λ��  (int sceneid, int id, float xDest, float yDest, float zDest)

	{ "GetAroundUnit" ,  },//�����Χ��λ������user��npc�� (int sceneid, int id) ��������
	{ "GetCurTimeMS", },//��õ�ǰʱ�䣬���Ⱥ���

	{ "Disconnect", },
	{ "Quit",  },
	{ "GetMessageCount",  },
	{ "GetMessage",  }, 
]]

--��õ�ǰ·��
local folderOfThisFile = (...):match("(.-)[^%.]+$")

xrequire(folderOfThisFile.."Vector3")
--local data = xrequire(folderOfThisFile.."data")
--...
local server_data = { scenename = "Default Server"}

server_data.actor_res = { "5e561dc7068a73ab000000017f000001/res_character_zombie_models.xwp/MaleZombie"} --xid / path  / res


XWServer = {}
local this = XWServer

this.UnitList = {}--ObjectList[id] = object; object= {name, res, type,pos}

local LinkerSceneID = 0  -- ������0-4�� ������ͬʱ��5������

function XWServer.LinkerState(id, state)--msg: 0 ���� 1 accept ok 2 connect ok
	print("LinkerState:"..id.." | state="..state.."\r\n")
	if state == 0 then
		--���ߴ���
		if this.UnitList[id] ~= nil then
			--�뿪�ײ�
			linker:SetPos(LinkerSceneID, id, 100001, 0, 0)--����һ������ �����ڱ߽� 1000���ϣ����ʾ�˳�����
			this.UnitList[id] = nil
		end
	end
end

function XWServer.Init()
	print(" new xworld XWServer Begin!(Default Server)\r\n")
	--��ʼ������
	--ѡ�õ�0��(LinkerSceneID = 0)������������� ��ͼ����Ϊ��0��0������256��256���� �����ᶯ̬����Ϊ20*20���򣬵�λ��ɼ���ΧΪ3�����򣨸�֪������Χ��СΪ5*5��
	this.SceneMin = Vector3.New(0, 0, 0)
	this.SceneMax = Vector3.New(256,0,256)
	linker:SetSceneArea(LinkerSceneID, this.SceneMin.x, this.SceneMax.x, this.SceneMin.z, this.SceneMax.z, 5)
	local UnitID = 0
	for i = 1 , 3 do 
		--��ʼ���ڳ�����λ��
		local UnitPos = Vector3.New(65+ math.random(-10,10), 1, 55+ math.random(-10,10))
		--��ʼ������1000000��npcר��id
		UnitID = 1000000+i
		this.UnitList[UnitID] = {id = UnitID, name = "npc"..UnitID, type = "npc", pos = UnitPos, res = server_data.actor_res[1], state = "idle", speed = 2, ActionTime = 0}
		--���õ�λ��λ�õ��ײ㣬��һ���Ǽ��뵽�ײ㳡����λ���������Ժ����κ��ƶ�����Ҫ����
		linker:SetPos(LinkerSceneID, UnitID, UnitPos.x, UnitPos.y, UnitPos.z)
	end
	this.LastTime = linker:GetCurTimeMS()--��õ�ǰ��ȷʱ��
	this.LastUpdateUnits = linker:GetCurTimeMS()--��õ�ǰ��ȷʱ��
end

local vTemp = Vector3.New(0,0,0)

function XWServer.Update()
	local CurTime = linker:GetCurTimeMS()--��õ�ǰ��ȷʱ�� ms����
	local DeltaTime_S = (this.LastTime - CurTime)/1000 --���֡��� ��
	this.LastTime = CurTime

	if LinkerSceneID ~= nil then
		return
	end 
	--�����û����ߣ�������Χ���λ����Դ�б�
	local bDest = false
	for k,v in pairs(this.UnitList) do
		--this.UnitList.Update() ?
		if v.state == "goto" then
			vTemp:set(v.vec.x, v.vec.y, v.vec.z)
			vTemp:Mul(DeltaTime_S)
			vTemp:Add(v.pos)
			--�ж��Ƿ񵽴�Ŀ�ĵ�
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
			-- λ������Ҫͬ����Χ�����
			if bDest == true then
				--�ָ�վ��״̬
				v.state = "idle"
				v.pos:set(v.dest.x, v.dest.y, v.dest.z)
				--����Ŀ�ĵ���Ҫ����һ����Ϊ
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
					--һ��ʱ������Χ�㲥�Լ�Ҫ�ƶ���ĳ����
					local data = {UnitID = k, x = v.dest.x, y = v.dest.y, z = v.dest.z}
					XRPC.RPCCallAround(LinkerSceneID, k, "XWClient.Move", data)
					--���ƶ��ĵ�λ��Ҫ�ж��Ƿ�ȡ��Χ����ĵ�λ���أ���Ҫ����һ��ʱ�������ȡ��һ�Σ�
					local ids = linker:GetAroundUnit(LinkerSceneID, k)
					data = {idlist = ids}
					XRPC.RPCCall(k, "XWClient.AroundUnitList", data)
				end 
			end
		end
	end

	--��ʱˢ�µ�λ����Χ��ɫ
	--if this.LastUpdateUnits - CurTime > 3000 then
		--this.LastUpdateUnits = CurTime
		--
	--end
end

function XWServer.Quit()
end

--client action


--�ͻ��˽��������
function XWServer.Enter(data)
	--�յ��ͻ��˵Ľ���
	print("user enter��"..data.name.." | NetId="..data.NetID.."\r\n" )
	--�û���Ҫ�������õ������û��б����������ȫ����Ϣ��   1Ϊ���룬0Ϊ�˳�
	linker:SetSceneUser(LinkerSceneID, data.NetID, 1)

	--�����ǳƺ�λ��
	local UnitPos = Vector3.New(55+ math.random(-5,5), 1, 45+ math.random(-5,5))
	this.UnitList[data.NetID] = {id = data.NetID, name = data.name, type = "user", pos = UnitPos, res = server_data.actor_res[1], state = "idle", speed = 2, ActionTime = 0}
	
	linker:SetPos(LinkerSceneID, data.NetID, UnitPos.x, UnitPos.y, UnitPos.z)

	--����id���ͻ��ˣ��ÿͻ���֪���Լ��Ķ������ĸ�
	local enterok = {id = data.NetID, name = data.name}
	XRPC.RPCCall(data.NetID, "XWClient.EnterConfirm", enterok)

	if server_data.actor_res == nil then--���û�ѡ������
		local res_choice = {size = #ActorRes, id = data.NetID, ResList = server_data.actor_res}
		XRPC.RPCCall(data.NetID, "XWClient.ChoiceActorRes", res_choice)
	end
	--�����Χ�ĵ�λ
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
	print("user GetUnitsData�� NetId="..data.NetID.."\r\n" )
	XRPC.RPCCall(data.NetID, "XWClient.UnitsData", UnitsData) 
end

--�ͻ�������
function XWServer.Move(data)
	--�յ��ͻ��˵��ƶ���Ϊ SendAround
	--�ж�������
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
		--������ٶ�
		User.vec:Sub(User.pos)
		User.vec:Normalize()
		User.vec:Mul(User.speed)
	end
	
	--���͸�������
	data.UnitID = data.NetID -- NetID�ڿͻ���ϵͳ���ܻ�ı�Ϊ����˵�����id��������������һ�²����߸��ͻ���

	this.UnitList[data.NetID].ActionTime = this.LastTime -- ��¼����ʱ��
	XRPC.RPCCallAround(LinkerSceneID, data.NetID, "XWClient.Move", data)--���͵� LinkerSceneID�ų��� �� data.NetID�û� ����Χ�û�
end

function XWServer.Rent(data)
	--�ͻ���Ҫ�������ط���
end

XRPC.RPCRegister("XWServer.Enter")
--XRPC.RPCRegister("XWServer.ChoiceActorRes")
XRPC.RPCRegister("XWServer.ChoiceActorResConfirm")
XRPC.RPCRegister("XWServer.GetUnitsData")
XRPC.RPCRegister("XWServer.Move")
XRPC.RPCRegister("XWServer.Rent")

return this