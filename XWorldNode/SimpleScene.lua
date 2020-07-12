
--场景服务器逻辑，所有单位的运算都在这里
require "Vector3"

local SSMainModule = {}

--[[
--消息管理
local Msgs = {}

function SSMsgPush(ID, func)
	Msgs[ID] = func
end]]--
local this = SSMainModule

this._RoomUserList = {}

--场地数据
local SceneData = 
{
	_xMin = -16;
	_xMax = 353;
	_ZMin = -212;
	_ZMax = 156;
}

function SSMainModule.JoinRoom(nNetID, nUserID, sName)
--加入房间
	--this._nRoomID = nRoomID;
	local user = tostring(nNetID);--nUserID 使用网络连接作为key，字符串可以确保是字典模式
	--重复加入
	--if this._RuntimeState._RoomUserList[user] ~= nil then
	--	return
	--end

	--创建一个user数据
	this._RoomUserList[user] = 
	{--speed FrameSync.Rand() % 80 - 40, FrameSync.Rand() % 80 - 40, 0
		_nID = nUserID,
		_vPos = Vector3.New(Helper.Rand()%40 - 20, 0 , Helper.Rand()%40 - 20)

		_Color = Helper.Rand()%256 *65535 + Helper.Rand()%256 *256 + Helper.Rand()%256;
		
		_vDest = Vector3.New(_fX,_fY,_fZ)
		_vSpeed = Vector3.New(0,0,0)
		_fSpeed = 0
		_bDest = false
		_Score = 0,		--分数
		_sName = sName
	};
	
	--给底层一个位置数据（Move）,底层自动同步周围单位
	XLinker.Move(nNetID, _fX, _fY, _fZ, _fX, _fY, _fZ );
	--返回周围人数据
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

--每33ms一次
function SSMainModule.Update()
	--服务端运行逻辑
	--运行所有单位的运动
	for k,v in pairs(this._RoomUserList) do
		--遍历每个玩家的位置和移动
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
	local frame = Data:ReadInt();--帧号 Data是linkbuffer

	if protocol < 100 then
		--固有房间基本处理消息
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
		--加入房间
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
		XLinker.SendAround(ID, buf)--发送给周围用户加入
		
	elseif Msg == Protocal.FSMSG_C2S_DISCONNECT then 
		local nRoomID, nUserID;
		nRoomID = Buffer:ReadInt();
		nUserID = Buffer:ReadInt();
		_MsgSendUser = nUserID;
		this.LeaveRoom(ID, nUserID);
		XLinker.Move(nNetID, 0, 0, 0, 0, 0, 0 );--底层删掉，填六个0
	--[[elseif Msg == Protocal.FSMSG_S2C_GETSTATUS then 
		local state = FrameSyncClass.GetSyncState();
		local buffer = ByteBuffer.New();
		--local nFrameID = buffer:ReadInt();
		local nCode = Buffer:ReadInt();
		local nUserID = Buffer:ReadInt();
		_MsgSendUser = nUserID;

		state.seed = FrameSync.seed;--添加随机数同步

		local bufferSend = NewMsgBuffer(Protocal.FSMSG_C2S_STATUS);
		--bufferSend:WriteShort(4000);--最大大小限制4000字节
		--bufferSend:WriteShort(Protocal.FSMSG_C2S_STATUS);
		bufferSend:WriteInt(state._nFrame);
		bufferSend:WriteInt(nCode);
		bufferSend:WriteInt(nUserID);
		local Param = json.encode(state);
		bufferSend:WriteBuffer(Param);--序列化的json字符串参数
		networkMgr:SendMessage(bufferSend);--回发给客户度帧状态	
		]]--
	end
end

function SSMainModule.Hit(vector)
	--服务端运行操作
	--FrameSyncGame.Hit(vector)
end


function SSMainModule.Quit()
	print("Main Module Quit") 
end

function SSMainModule.ControlSpeed(ID, Ctrl)
	--让球改变运动速度（包含方向） 在服务器上经过处理并返回此操作回给客户端 
	local user = this._RoomUserList[ID];
	if Ctrl.UserID == user._nID then
		user._vSpeed.x = Ctrl.fXSpeed
		user._vSpeed.y = Ctrl.fYSpeed
		user._vSpeed.z = Ctrl.fZSpeed
		user._bDest = false
	end
	MsgRPCCall.RPCCall("FrameSyncGame.ControlSpeed", Ctrl);--这里会返回客户端执行客户端的对应函数,不一定要跟服务端相同名字
end

function SSMainModule.MoveTo(ID, MoveData)
	--让球改变运动速度（包含方向） 在服务器上经过处理并返回此操作回给客户端 
	local user = this._RoomUserList[ID];
	if MoveData.UserID == user._nID then
		user._vDest.x = MoveData.fXDest
		user._vDest.y = MoveData.fYDest
		user._vDest.z = MoveData.fZDest
		user._vSpeed.x = MoveData.fXSpeed
		user._vSpeed.y = MoveData.fYSpeed
		user._vSpeed.z = MoveData.fZSpeed
		user._bDest = MoveData.bDest
		--把当前位置也放进去
		MoveData.fX = user._vPos.x
		MoveData.fY = user._vPos.y
		MoveData.fZ = user._vPos.z
		-- 改id为网络id，只能看到别人的临时ID
		MoveData.UserID = ID
		MsgRPCCall.RPCCall("BallWorld.MoveTo", MoveData);--这里会返回客户端执行客户端的对应函数,不一定要跟服务端相同名字
	end
end

function SSMainModule.GetUser(ID, UserData)
	local user = this._RoomUserList[UserData.ID];
	if user ~= nil then
		MsgRPCCall.RPCCall("BallWorld.GetUser", user);
	end
end


--把本场景管理类入总管理类里，放最后，因为里面会调用初始化
Manager.Push("SimpleModule", SSMainModule)

--注册RPC函数
MsgRPCCall.RPCRegister("SSMainModule.ControlSpeed");--客户端可以执行这个函数
MsgRPCCall.RPCRegister("SSMainModule.MoveTo");
MsgRPCCall.RPCRegister("SSMainModule.GetUser");