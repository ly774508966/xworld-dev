 

 --[[
 ͬ����
	��λ�������ÿ����ͬ����Χ��λid�б��ͻ��˱Ƚϱ����б�ɾ�����ڵģ���ӽ����
	���ײ������Χ��λ�ã�

	��Ϊ���ͻ��˷���Ϊָ�����ˣ����Ϸ��ԣ�λ�����ִ���ԣ�ת������Χ��ɫ���ͻ���ִ����Ϊ����λ�ã�

	��ͬ���������յ���������˵���Ϊ�����̫Զ������������������Լ���ǿ�ƾ�����ָ���
 ]]--

 XLinker = Linker(_Linker) --c�����ȥ��ȫ�ֶ���

 
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

--���������ģ��
 require "simpleScene"


function SceneServer.Init()
	print("Hello, This is SceneServer Base.") 
	--XLinker.Quit();
end

--ÿ33msһ��
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
