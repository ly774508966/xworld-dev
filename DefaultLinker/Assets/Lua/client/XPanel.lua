
--local folderOfThisFile = (...):match("(.-)[^%.]+$")

XPanel = {}
local this = XPanel

--RegUI(name, ui, abname, resname, xpos, ypos, zpos)
UIMgr.RegUI("XPanel", this, 'res_ui_linkerlist.xwp', 'XPanel', 0, 0, 100)

local panel;
local prompt;
local transform;
local gameObject;

function this.Init()
	local abpath = Game.GetResFullPath('res_ui_linkerlist.xwp')
	resMgr:LoadPrefab(abpath, { 'XPanel' }, this.OnCreate);
end

function this.OnCreate(objs)
	print("Load XPanel UI Success")
	gameObject = newObject(objs[0]);
	transform = gameObject.transform;
	this.UIParent = GameObject.FindWithTag("GuiCamera");--固定名称
	--print("this.UIParent  ="..this.UIParent.name );
	transform:SetParent(this.UIParent.transform);--this.tr
	this.OK = gameObject.Find("OK");
	this.Back = gameObject.Find("Back");
	-- 在cs里面特意注册了这个特殊类型，否则不能用
	LuaHelper.AddComponent(gameObject, 'LuaBehaviour');--luahelper增加特殊类型支持
	prompt = transform:GetComponent('LuaBehaviour');

	transform.localScale = Vector3.one;
    transform.localPosition = Vector3.New(0,0,60);

	this.IDInput = transform:Find('Input'):GetComponent('InputField');
	
	prompt:AddClick(this.OK, this.OnClick);
	prompt:AddClick(this.Back, this.OnClickBack);
end

function this.OnClick(go)
	--go.name
	print("click OK : "..go.name.."\n")
end

function this.OnClickBack(go)
	--go.name
	print("click Back : "..go.name.."\n")
end

function this.SetData(data)
	--设置proxy列表参数
	this.data = data
	if this.bshow ~= nil then
		  this.refresh()
	end
end



--刷新界面
function this.refresh()
	local button
	local text
	
	local count = 1
	if gameObject ~= nil then
		UIMgr.RegClickFunc(this, "OK", this.OnClick)
	end
end

function this.Show(bshow)
	if this.bshow == nil then
			--第一次打开
			--this.Init()
			this.bshow = true
			this.refresh()
	
	else
		--
		if this.bshow == true then
			--隐藏界面
			this.bshow = false
			--..
		end
	end
end

return this