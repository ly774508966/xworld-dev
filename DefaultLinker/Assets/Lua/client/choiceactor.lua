

local ChoiceActor = {}
local this = ChoiceActor;

local panel;
local prompt;
local transform;
local gameObject;

function ChoiceActor.Init()
	url = Game.GetResFullPath('res_ui_choiceres.xwp') --原路径 res/ui/choiceres.xwp
	resMgr:LoadPrefab(url, { 'ChoiceActorRes' }, this.OnCreate);
end

function ChoiceActor.SetData(reslist, func)
	this.reslist = reslist.ResList
	this.func = func
end

function ChoiceActor.OnCreate(objs)
	print("Load ChoiceActorRes Success")
	gameObject = newObject(objs[0]);
	transform = gameObject.transform;
	this.UIParent = GameObject.FindWithTag("GuiCamera");--固定名称
	print("this.UIParent  ="..this.UIParent.name );
	transform:SetParent(this.UIParent.transform);--this.tr
	this.OK = gameObject.Find("Button");
	LuaHelper.AddComponent(gameObject, 'LuaBehaviour');--luahelper增加特殊类型支持
	prompt = transform:GetComponent('LuaBehaviour');

	transform.localScale = Vector3.one;
    transform.localPosition = Vector3.New(0,0,100);

	this.gridParent = transform:Find('ScrollView/Grid');
	
	prompt:AddClick(this.OK, this.OnClick);
	resMgr:LoadPrefab('prompt', { 'PromptItem' }, this.InitGrid);--临时先用着选项按钮图标
end

function ChoiceActor.InitGrid(objs)
	local parent = this.gridParent;
	for k, v in pairs(this.reslist) do
		local go = newObject(objs[0]);
		go.name = v --'Item'..tostring(i);
		go.transform:SetParent(parent);
		go.transform.localScale = Vector3.one;
		go.transform.localPosition = Vector3.zero;
        prompt:AddClick(go, this.OnItemClick);
	end
end

function ChoiceActor.OnItemClick(go)
	this.ChoiceRes = go.name
end

function ChoiceActor.OnClick(go)
	this.func(this.ChoiceRes)
end

return ChoiceActor