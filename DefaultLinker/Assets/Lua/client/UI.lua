
--[[
	ui管理器
	1.注册RegUI("name", uiclass, abname, resname) 
	2.打开与关闭ui OpenUI("name")  CloseUI("name") IsOpened("name") HideUI("name", true)
	3.获得ui类 GetUI("name")

	4.通过object名称获得对象与注册事件   RegClick(ui, "ButtonName", func)   UIObj = GetUIObject(ui, "UIObjName", "InputField")
]]

UIMgr = {}
local this = UIMgr

local UIList = {}

local CurUI = {}

function this.RegUI(name, ui, abname, resname, xpos, ypos, zpos)
	ui.xw_abName = abname
	ui.xw_resName = resname
	ui.xw_isLoaded = false
	ui.xw_isHide = true
	ui.xw_abpath = Game.GetResFullPath(abname)
	ui.xw_xpos = xpos
	ui.xw_ypos = ypos
	if zpos ~= nil then
		ui.xw_zpos = zpos
	else
		ui.xw_zpos = 100
	end
	UIList[name] = ui
end

function this.GetUI(name)
	return UIList[name]
end

function this.OpenUI(name, callbackfunc)
	CurUI = UIList[name]
	if CurUI == nil then
		print("unregister ui: "..name)
		return
	end
	if CurUI.xw_isLoaded == false then
		CurUI.xw_func = callbackfunc
		resMgr:LoadPrefab(CurUI.xw_abpath, { CurUI.xw_resName }, this.OnLoaded);
	else
		
		callbackfunc(CurUI.xw_uiobj)
	end
	return CurUI
end

function this.OnLoaded(objs)
	CurUI.xw_uiobj = newObject(objs[0]);
	CurUI.transform = CurUI.xw_uiobj.transform;
	local UIParent = GameObject.FindWithTag("GuiCamera");--固定名称
	--print("UIParent  ="..UIParent.name );
	CurUI.transform:SetParent(UIParent.transform);
	LuaHelper.AddComponent(CurUI.xw_uiobj, 'LuaBehaviour');--luahelper增加特殊类型支持 这个组件能传递ugui事件消息
	CurUI.xw_behavior = CurUI.transform:GetComponent('LuaBehaviour');

	CurUI.transform.localScale = Vector3.one;
    CurUI.transform.localPosition = Vector3.New(CurUI.xw_xpos,CurUI.xw_ypos,CurUI.xw_zpos);

	CurUI.xw_isLoaded = true
	if CurUI.OnCreate ~= nil then
		CurUI.OnCreate(CurUI.xw_uiobj)
	end
	if CurUI.callbackfunc ~= nil then
		CurUI.callbackfunc(CurUI.xw_uiobj)
	end
end

function this.CloseUI(name)
end

function this.HideUI(name, bhide)
end

function this.RegClickFunc(ui, buttonname, func)
	if ui.xw_uiobj ~= nil then
		print("xw_uiobj OK")
	else
		print("xw_uiobj nil")
	end
	local button = ui.xw_uiobj.Find(buttonname);
	if button ~= nil then
		print("add button click event : "..buttonname)
		ui.xw_behavior:AddClick(button, func);
	else
		print("No button ："..buttonname)
	end
end

function this.GetUIObject(ui, uiobjname, typename)
	local obj = ui.transform:Find(uiobjname):GetComponent(typename)
	return obj
end

return this