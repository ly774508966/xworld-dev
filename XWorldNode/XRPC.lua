

--[[
	XWORLD
	XRPC  
	xiewei
	远程方法调用，方便服务端客户端之间信息交换
]]


function NewMsgBuffer(MsgID)
	--local buf = ByteBuffer.New();
	local sendbuffer = xworld.linkerbuffer()
	--buf:WriteShort(MsgID);
	sendbuffer:WriteShort(MsgID)
	return sendbuffer
end




XRPC = {};
local this = XRPC;
local XRPCClass = nil;

this.XRPC_INTERVAL = 33

MsgFuncIndex = {}
strFuncMsgIndex = {}

m_nCurFrame = 0
local _UserID = 0

XRPC.ID = 0

function XRPC.RegisterClass(Class)
    XRPCClass = Class
end
function XRPC.UnregisterClass()
    if XRPCClass ~= nil then
		XRPCClass = nil
	end
end

--设置远程的linker网络ID
function XRPC.SetRemoteLinkerNetID(netid)
	XRPC.NetID = netid
end


function XRPC.GetFuncID(strFunc)
	local id = 0;
	for i=1, #strFunc do
		id = id + string.byte(strFunc,i)
	end
	id = id % 10000
	id = id + 20000
	return id
end 


function string.split(input, delimiter, to_type)
	if type(to_type) ~= "function" then
		to_type = tostring
	end
	
	input = tostring(input)
	delimiter = tostring(delimiter)
	if (delimiter=='') then return false end
	local pos,arr,cell = 0, {}, nil
	-- for each divider found
	for st,sp in function() return string.find(input, delimiter, pos, true) end do
		cell = to_type(string.sub(input, pos, st - 1))
		if cell then
			table.insert(arr, cell)
		end
		pos = sp + 1
	end
	
	table.insert(arr, to_type(string.sub(input, pos)) )
	return arr
end

--操作行为方法 Function
function XRPC.RPCRegister(strFunction)
	--根据函数名称生成唯一ID
	--local strFunc = string.dump(Function)
	local splitFunc = string.split(strFunction, '.');
	local len = string.len;
	local root = _G;
	for k, v in ipairs(splitFunc) do
		ret = root[v]
		root = ret
	end
	
	if root == nil or root == _G then
		print("Error! Can't not Find Function: "..strFunction);
	end
	
	local ID = this.GetFuncID(strFunction)
	if MsgFuncIndex[ID] == nil then
		MsgFuncIndex[ID] = root
		strFuncMsgIndex[strFunction] = ID
		print("Func Reg:"..strFunction..ID.."\r\n")
	else
		--有相同的ID, 请改函数名
		print("Error! Have same ID, Please rename the Function : "..strFunction);
		--还是覆盖
		MsgFuncIndex[ID] = root
		strFuncMsgIndex[strFunction] = ID
	end
end


function XRPC.RPCUnregister(Function)
	--根据函数名称生成唯一ID
	local strFunc = string.dump(Function)
	local ID = this.GetFuncID(strFunc)
	MsgFuncIndex[ID]  = nil
	strFuncMsgIndex[strFunc] = nil
end


function XRPC.RPCCall(NetID, strFunc ,  Param) --函数名字符串， 参数table
	if strFuncMsgIndex[strFunc] == nil then 
		strFuncMsgIndex[strFunc] = this.GetFuncID(strFunc)
	end
	
	print("RPCCall : "..strFuncMsgIndex[strFunc].."\n");
	--if strFuncMsgIndex[strFunc] ~= nil then
		local buffer = NewMsgBuffer(strFuncMsgIndex[strFunc]);
		local str = json.encode(Param);
		buffer:WriteBuffer(str);--序列化的json字符串参数
		linker:Send(NetID, buffer)
	--else
	--	print("Error! Can not find the function : "..strFunc);
	--end	
end

function XRPC.RPCCallAround(SceneID, NetID, strFunc ,  Param)
	
	if strFuncMsgIndex[strFunc] == nil then 
		strFuncMsgIndex[strFunc] = this.GetFuncID(strFunc)
	end
	
	local buffer = NewMsgBuffer(strFuncMsgIndex[strFunc]);
	local str = json.encode(Param);
	buffer:WriteBuffer(str);--序列化的json字符串参数
	linker:SendAround(SceneID, NetID, buffer)
	
end

function XRPC.MsgCall(NetID, MsgID,  buffer) 
	local jsonbuf = buffer:ReadBuffer();
	print("XRPC.MsgCall: "..MsgID.."\r\n");
	if MsgFuncIndex[MsgID] ~= nil then
		local Param = json.decode(jsonbuf);
		Param.NetID = NetID
		MsgFuncIndex[MsgID](Param);
	else
		print("MsgCall Error: "..MsgID.."\r\n");	
	end
end

function XRPC.MsgJsonCall(NetID, MsgID,  jsonbuf)
	--print("MsgJsonCall: "..MsgID.."\n")
	if MsgFuncIndex[MsgID] ~= nil then
		local Param = json.decode(jsonbuf);
		Param.NetID = NetID
		MsgFuncIndex[MsgID](Param);
		print("MsgCall: "..MsgID.."\n")
	else
		print("MsgCall Error: "..MsgID.."\r\n");	
	end
end

return XRPC