
--local folderOfThisFile = (...):match("(.-)[^%.]+$")

local UILinkerList = {}
local this = UILinkerList

--RegUI(name, ui, abname, resname, xpos, ypos, zpos)
UIMgr.RegUI("UILinkerList", this, 'res_ui_linkerlist.xwp', 'ProxyList', 0, 0, 100)

local panel;
local prompt;
local transform;
local gameObject;

function this.Init()
	
end

function this.OnCreate(obj)
	print("Load LinkerList UI Success")
	
	--resMgr:LoadPrefab(this.url, { 'PromptItem' }, this.InitUIData);--ѡ�ťԤ��
end

function this.InitData(objs)
	this.UIProxyList = {}
	for i = 1, 10 do -- Ԥ��10��λ��
		local go = newObject(objs[0]);
		go.name = i --���
		go.transform:SetParent(parent);
		go.transform.localScale = Vector3.one;
		go.transform.localPosition = Vector3.zero;
        prompt:AddClick(go, this.OnItemClick);
		this.UIProxyList[i] = go
	end
end

function this.OnItemClick(go)
	--go.name ����ѡ������
	print("click item : "..go.name.."\n")
end

function this.SetData(data)
	--����proxy�б����
	this.data = data
	if this.bshow ~= nil then
		  this.refresh()
	end
end

--ˢ�½���
function this.refresh()

	if this.data ~= nil then
		local temp
		for k,v in pairs(this.data) do -- k: xid  v: desc
			temp = k.." : \n"..v
		end
	end
end

function this.Show(bshow)
	if bshow == true then
		if this.bshow == nil then
			--��һ�δ�
			this.Init()
			this.bshow = true
			this.refresh()
		else
		end
	else
		--
		if this.bshow == true then
			--���ؽ���

			this.bshow = false
		end
	end
end

return this