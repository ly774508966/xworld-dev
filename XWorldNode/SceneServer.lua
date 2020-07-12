 

 --[[
 同步：
	单位：服务端每三秒同步周围单位id列表；客户端比较本地列表，删掉不在的，添加进入的
	（底层管理，范围，位置）

	行为：客户端发行为指令；服务端（检查合法性，位置与可执行性）转发给周围角色；客户端执行行为（带位置）

	不同步纠正：收到服务端他人的行为，相差太远则纠正，服务器发给自己的强制纠正则恢复。
 ]]--

 XLinker = Linker(_Linker) --c层设进去的全局对象

 
 require "MsgPRCCall"

SceneServer = {}

Manager = {}
local module = {}

function Manager.Push(name, module)
	module[name] = module
	module.Init();
end
function Manager.Pop(name)
    if module[name] ~= nil then
		module[name].Quit()
	end
	module[name] = nil
end

--添加主运行模块
 require "simpleScene"


function SceneServer.Init()
	print("Hello, This is SceneServer Base.") 
	--XLinker.Quit();
end

--每33ms一次
function SceneServer.Update()
	for k, v in ipairs(module) do
		V.Update()
	end
end

function SceneServer.OnMsg(ID, Msg, Data)

	for k, v in ipairs(module) do
		if V.OnMsg(ID, Msg, Data) == true  then
			break
		end
	end	
end


function SceneServer.Quit()
	for k, v in ipairs(module) do
		V.Quit()
	end
end
