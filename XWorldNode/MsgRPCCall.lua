
local cjson = require "cjson"

json = cjson.new()

MsgRPCCall = {}

--α�����
Helper = {}
local seed = 49720718;
function Helper.SRand(new_seed)
	seed = new_seed % 0xffffffff;
end
function Helper.Rand()
	seed = math.ceil(seed * 128 + seed / 128) % 0xffffffff;--ȡ��
	return seed
end

local MsgFuncIndex = {}
local strFuncMsgIndex = {}

function NewMsgBuffer(MsgID)
	local buf = LinkBuffer.new();
	--buf:WriteByte(174);-- Э���ʶ'0xAE'  ��Ϊ�ײ���
	--buf:WriteShort(Size);--����С����4000�ֽ�
	buf:WriteShort(MsgID);
	return buf
end

--������Ϊ���� Function
function MsgRPCCall.RPCRegister(strFunction)
	--���ݺ�����������ΨһID
	--local strFunc = string.dump(Function)
	local splitFunc = string.split(strFunction, '.');
	local len = string.len;
	local root = _G;
	for k, v in ipairs(splitFunc) do
		ret = root[v]
		root = ret
	end
	
	if root == nil then
		print("Error! Can't not Find Function: "..strFunction);
	end
	
	local ID = this.GetFuncID(strFunction)
	if MsgFuncIndex[ID] == nil then
		MsgFuncIndex[ID] = root
		strFuncMsgIndex[strFunction] = ID
	else
		--����ͬ��ID, ��ĺ�����
		print("Error! Have same ID, Please rename the Function : "..strFunction);
	end
end


function MsgRPCCall.RPCUnregister(Function)
	--���ݺ�����������ΨһID
	local strFunc = string.dump(Function)
	local ID = this.GetFuncID(strFunc)
	MsgFuncIndex[ID]  = nil
	strFuncMsgIndex[strFunc] = nil
end

function MsgRPCCall.RPCCall(strFunc ,  Param) --�������ַ����� ����table
	if strFuncMsgIndex[strFunc] ~= nil then
		local buffer = NewMsgBuffer(strFuncMsgIndex[strFunc]);
		buffer:WriteInt(m_nCurFrame);--���跢��֡�ţ�
		buffer:WriteInt(_UserID);--���뷢��ִ���ˣ���������������ִ���˷��޸�
		local str = json.encode(Param);
		buffer:WriteBuffer(str);--���л���json�ַ�������
		--networkMgr:SendMessage(buffer);//ID
		XLinker.
	else
		print("Error! Can not find the function : "..strFunc);
	end	
end

function MsgRPCCall.MsgCall(ID ,  buffer, frame) 
	_MsgSendUser = buffer:ReadInt();--��������������ִ����
	local jsonbuf = buffer:ReadBuffer();
	if MsgFuncIndex[ID] ~= nil then
		local Param = json.decode(jsonbuf);
		MsgFuncIndex[ID](ID, Param);
	end
end