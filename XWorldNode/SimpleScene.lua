
--�����������߼������е�λ�����㶼������
require "Vector3"

local SSMainModule = {}

--[[
--��Ϣ����
local Msgs = {}

function SSMsgPush(ID, func)
	Msgs[ID] = func
end]]--
local this = SSMainModule

this._RoomUserList = {}

--��������
local SceneData = 
{
	_xMin = -16;
	_xMax = 353;
	_ZMin = -212;
	_ZMax = 156;
}

function SSMainModule.JoinRoom(nNetID, nUserID, sName)
--���뷿��
	--this._nRoomID = nRoomID;
	local user = tostring(nNetID);--nUserID ʹ������������Ϊkey���ַ�������ȷ�����ֵ�ģʽ
	--�ظ�����
	--if this._RuntimeState._RoomUserList[user] ~= nil then
	--	return
	--end

	--����һ��user����
	this._RoomUserList[user] = 
	{--speed FrameSync.Rand() % 80 - 40, FrameSync.Rand() % 80 - 40, 0
		_nID = nUserID,
		_vPos = Vector3.New(Helper.Rand()%40 - 20, 0 , Helper.Rand()%40 - 20)

		_Color = Helper.Rand()%256 *65535 + Helper.Rand()%256 *256 + Helper.Rand()%256;
		
		_vDest = Vector3.New(_fX,_fY,_fZ)
		_vSpeed = Vector3.New(0,0,0)
		_fSpeed = 0
		_bDest = false
		_Score = 0,		--����
		_sName = sName
	};
	
	--���ײ�һ��λ�����ݣ�Move��,�ײ��Զ�ͬ����Χ��λ
	XLinker.Move(nNetID, _fX, _fY, _fZ, _fX, _fY, _fZ );
	--������Χ������
end

function SSMainModule.LeaveRoom(nRoomID, nUserID)
	local user = tostring(nUserID);
	if this._RoomUserList[user] ~= nil then
		this._RoomUserList[user] = nil
	end
end

function SSMainModule.Init()
	
	print("Main Module Begin") 
	XLinker.SetSceneArea(SceneData._xMin, SceneData._xMax, SceneData._ZMin, SceneData._ZMax)
end

--ÿ33msһ��
function SSMainModule.Update()
	--����������߼�
	--�������е�λ���˶�
	for k,v in pairs(this._RoomUserList) do
		--����ÿ����ҵ�λ�ú��ƶ�
		local SrcPos = v._vPos.Clone()
		if _bDest == true then
			v._vPos = SrcPos + user._vSpeed * 0.033 --33ms
			XLinker.Move(nNetID, SrcPos.x, SrcPos.y, SrcPos.z, v._vPos.x, v._vPos.y, v._vPos.z );
			else
			vDir = v._vDest - v._vPos
			if vDir.SqrMagnitude() > 2 then 
				vDir.SetNormalize()
				v._vPos = SrcPos + vDir * 0.033 --33ms
				XLinker.Move(nNetID, SrcPos.x, SrcPos.y, SrcPos.z, v._vPos.x, v._vPos.y, v._vPos.z );
			end
		end
	end
end

function SSMainModule.OnMsg(ID, Msg, Data)
	local frame = Data:ReadInt();--֡�� Data��linkbuffer

	if protocol < 100 then
		--���з������������Ϣ
		SSMainModule.BaseMsg(protocol, buffer, frame);
	else
		MsgRPCCall.MsgCall(ID , Data, frame) 
	end
	--[[print("Recv Msg:"..ID)
	if	Msgs[ID] ~= nil then
		ret = Msgs[ID](ID, Msg, Data)
		return ret
	end
	return false]]--
end

function SSMainModule.BaseMsg(ID, Msg, Buffer)
	if Msg == Protocal.FSMSG_C2S_JIONROOM or Msg == Protocal.FSMSG_S2C_JIONROOM then 
		local nRoomID, nCount, nUserID, nReserve, sName;
		nRoomID = Buffer:ReadInt();
		nCount = Buffer:ReadInt();
		nUserID = Buffer:ReadInt();
		nReserve = Buffer:ReadInt();
		sName = Buffer:ReadString();
		--���뷿��
		this.JoinRoom(ID, nUserID, sName);
		local buf = NewMsgBuffer(Protocal.FSMSG_S2C_JIONROOM)
		buf:WriteInt(nRoomID)
		buf:WriteInt(nCount)
		buf:WriteInt(ID)--buf:WriteInt(nUserID)
		buf:WriteInt(nReserve)
		buf:WriteString(sName)
		local user = this._RoomUserList[ID];
		buf:WriteFloat(user._vPos.x)
		buf:WriteFloat(user._vPos.y)
		buf:WriteFloat(user._vPos.z)
		buf:WriteInt(user._Color)
		XLinker.SendAround(ID, buf)--���͸���Χ�û�����
		
	elseif Msg == Protocal.FSMSG_C2S_DISCONNECT then 
		local nRoomID, nUserID;
		nRoomID = Buffer:ReadInt();
		nUserID = Buffer:ReadInt();
		_MsgSendUser = nUserID;
		this.LeaveRoom(ID, nUserID);
		XLinker.Move(nNetID, 0, 0, 0, 0, 0, 0 );--�ײ�ɾ����������0
	--[[elseif Msg == Protocal.FSMSG_S2C_GETSTATUS then 
		local state = FrameSyncClass.GetSyncState();
		local buffer = ByteBuffer.New();
		--local nFrameID = buffer:ReadInt();
		local nCode = Buffer:ReadInt();
		local nUserID = Buffer:ReadInt();
		_MsgSendUser = nUserID;

		state.seed = FrameSync.seed;--��������ͬ��

		local bufferSend = NewMsgBuffer(Protocal.FSMSG_C2S_STATUS);
		--bufferSend:WriteShort(4000);--����С����4000�ֽ�
		--bufferSend:WriteShort(Protocal.FSMSG_C2S_STATUS);
		bufferSend:WriteInt(state._nFrame);
		bufferSend:WriteInt(nCode);
		bufferSend:WriteInt(nUserID);
		local Param = json.encode(state);
		bufferSend:WriteBuffer(Param);--���л���json�ַ�������
		networkMgr:SendMessage(bufferSend);--�ط����ͻ���֡״̬	
		]]--
	end
end

function SSMainModule.Hit(vector)
	--��������в���
	--FrameSyncGame.Hit(vector)
end


function SSMainModule.Quit()
	print("Main Module Quit") 
end

function SSMainModule.ControlSpeed(ID, Ctrl)
	--����ı��˶��ٶȣ��������� �ڷ������Ͼ����������ش˲����ظ��ͻ��� 
	local user = this._RoomUserList[ID];
	if Ctrl.UserID == user._nID then
		user._vSpeed.x = Ctrl.fXSpeed
		user._vSpeed.y = Ctrl.fYSpeed
		user._vSpeed.z = Ctrl.fZSpeed
		user._bDest = false
	end
	MsgRPCCall.RPCCall("FrameSyncGame.ControlSpeed", Ctrl);--����᷵�ؿͻ���ִ�пͻ��˵Ķ�Ӧ����,��һ��Ҫ���������ͬ����
end

function SSMainModule.MoveTo(ID, MoveData)
	--����ı��˶��ٶȣ��������� �ڷ������Ͼ����������ش˲����ظ��ͻ��� 
	local user = this._RoomUserList[ID];
	if MoveData.UserID == user._nID then
		user._vDest.x = MoveData.fXDest
		user._vDest.y = MoveData.fYDest
		user._vDest.z = MoveData.fZDest
		user._vSpeed.x = MoveData.fXSpeed
		user._vSpeed.y = MoveData.fYSpeed
		user._vSpeed.z = MoveData.fZSpeed
		user._bDest = MoveData.bDest
		--�ѵ�ǰλ��Ҳ�Ž�ȥ
		MoveData.fX = user._vPos.x
		MoveData.fY = user._vPos.y
		MoveData.fZ = user._vPos.z
		-- ��idΪ����id��ֻ�ܿ������˵���ʱID
		MoveData.UserID = ID
		MsgRPCCall.RPCCall("BallWorld.MoveTo", MoveData);--����᷵�ؿͻ���ִ�пͻ��˵Ķ�Ӧ����,��һ��Ҫ���������ͬ����
	end
end

function SSMainModule.GetUser(ID, UserData)
	local user = this._RoomUserList[UserData.ID];
	if user ~= nil then
		MsgRPCCall.RPCCall("BallWorld.GetUser", user);
	end
end


--�ѱ��������������ܹ�������������Ϊ�������ó�ʼ��
Manager.Push("SimpleModule", SSMainModule)

--ע��RPC����
MsgRPCCall.RPCRegister("SSMainModule.ControlSpeed");--�ͻ��˿���ִ���������
MsgRPCCall.RPCRegister("SSMainModule.MoveTo");
MsgRPCCall.RPCRegister("SSMainModule.GetUser");