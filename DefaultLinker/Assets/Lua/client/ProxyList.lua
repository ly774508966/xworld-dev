
--local folderOfThisFile = (...):match("(.-)[^%.]+$")

local UILinkerList = {}
local this = UILinkerList

--RegUI(name, ui, abname, resname, xpos, ypos, zpos)
UIMgr.RegUI("UIProxyList", this, 'res_ui_linkerlist.xwp', 'ProxyList', 0, 0, 100)


local data = {}

local panel;
local prompt;
local transform;
local gameObject;

function this.OnCreate(obj)
	print("Load ProxyList UI Success")
	gameObject = obj

	this.OK = gameObject.Find("OK");
	this.refresh()
	
	--UIMgr.RegClickFunc(this, buttonname, OnItemClick)
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

function this.OnClick(go)
	--go.name ����ѡ���xid
	print("click item : "..go.name.."\n")
	EnterLinker(go.name)
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
	local button
	local text
	
	local count = 1
	if this.data ~= nil and gameObject ~= nil then
		local temp
		local bttext
		local button
		local buttonname
		if this.xw_uiobj ~= nil then
			print("xw_uiobj OK")
		else
			print("xw_uiobj nil")
		end
		UIMgr.RegClickFunc(this, "OK", this.OnClick)
		for k,v in pairs(this.data.proxylist) do -- k: xid  v: desc
			buttonname = "PanelTop/Panel/Item"..count.."/Button" --
			button = gameObject.Find(buttonname);
			print(buttonname.." | "..k.."\n")
			--printTable(v)
			temp = v.nickname.." "..v.xid.." endtime="..v.endtime
			if button ~= nil then--Ŀǰֻ��10������̬��ɾ��δ��
				button.name = v.xid
				--bto = button.transform:GetComponent('Button')
				--bttext = bto:GetComponent('Text')
				bttext = button.transform:Find("Text")
				if bttext ~= nil then
					bttext:GetComponent('Text').text = temp
					print("button text:"..temp)
				else
					print("No Text")
				end
				--text.Text = temp
				UIMgr.RegClickFunc(this, button.name, this.OnClick)
			end
			count = count + 1
		end
	end
end

function this.Show(bshow)
	if this.bshow == nil then
			--��һ�δ�
			--this.Init()
			this.bshow = true
			this.refresh()
	
	else
		--
		if this.bshow == true then
			--���ؽ���
			this.bshow = false
			--..
		end
	end
end

return this