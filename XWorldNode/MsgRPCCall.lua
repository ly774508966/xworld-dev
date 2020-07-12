
local cjson = require "cjson"

json = cjson.new()

MsgRPCCall = {}

--伪随机数
Helper = {}
local seed = 49720718;
function Helper.SRand(new_seed)
	seed = new_seed % 0xffffffff;
end
function Helper.Rand()
	seed = math.ceil(seed * 128 + seed / 128) % 0xffffffff;--取整
	return seed
end

local MsgFuncIndex = {}
local strFuncMsgIndex = {}

function NewMsgBuffer(MsgID)
	local buf = LinkBuffer.new();
	--buf:WriteByte(174);-- 协议标识'0xAE'  改为底层做
	--buf:WriteShort(Size);--最大大小限制4000字节
	buf:WriteShort(MsgID);
	return buf
end

--操作行为方法 Function
function MsgRPCCall.RPCRegister(strFunction)
	--根据函数名称生成唯一ID
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
		--有相同的ID, 请改函数名
		print("Error! Have same ID, Please rename the Function : "..strFunction);
	end
end


function MsgRPCCall.RPCUnregister(Function)
	--根据函数名称生成唯一ID
	local strFunc = string.dump(Function)
	local ID = this.GetFuncID(strFunc)
	MsgFuncIndex[ID]  = nil
	strFuncMsgIndex[strFunc] = nil
end

function MsgRPCCall.RPCCall(strFunc ,  Param) --函数名字符串， 参数table
	if strFuncMsgIndex[strFunc] ~= nil then
		local buffer = NewMsgBuffer(strFuncMsgIndex[strFunc]);
		buffer:WriteInt(m_nCurFrame);--必需发出帧号，
		buffer:WriteInt(_UserID);--必须发出执行人，服务器会纠正这个执行人防修改
		local str = json.encode(Param);
		buffer:WriteBuffer(str);--序列化的json字符串参数
		--networkMgr:SendMessage(buffer);//ID
		XLinker.
	else
		print("Error! Can not find the function : "..strFunc);
	end	
end

function MsgRPCCall.MsgCall(ID ,  buffer, frame) 
	_MsgSendUser = buffer:ReadInt();--服务器会纠正这个执行人
	local jsonbuf = buffer:ReadBuffer();
	if MsgFuncIndex[ID] ~= nil then
		local Param = json.decode(jsonbuf);
		MsgFuncIndex[ID](ID, Param);
	end
end