--- Core is responsible for handling modules and installation process.

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

local optName, Opt = ...


---@class Opt: OptionMixin
Opt = LibStub("AceAddon-3.0"):NewAddon(Opt, optName, "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local ACR = LibStub("AceConfigRegistry-3.0")

--local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI4")
local L = LUI.L

local OPTION_PANEL_WIDTH = 930
local OPTION_PANEL_HEIGHT = 660

-- Avoid extraneous Libstub calls
Opt.LUI = LUI
Opt.ACR = ACR

local RoundToSignificantDigits = _G.RoundToSignificantDigits

---@class OptionMixin
local OptionMixin = {}

-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################
--- Note: info[#info] returns the name of the current option

--- Fetch the option's parent table
---@param info InfoTable
---@return table
local function GetParentTable(info)
	local parentTable = info.options.args
	for i=1, #info-1 do
		parentTable = parentTable[info[i]].args
	end
	return parentTable
end

--- Add a confirmation dialog to an option before changing the value. Behavior determined by `confirm` param.
---- boolean: Prompt for confirmation using "name - desc"
---- string: Prompt for confirmation with the provided string as confirmation text.
---- function: Provide a function that either return a string (prompt display with text), true (same as above) or false to skip the confirmation.
---@param option AceOption
---@param confirm boolean|string|function
function OptionMixin.AddConfirm(option, confirm)
	if confirm then
		local confirmType = type(confirm)
		if confirmType == "boolean" then
			option.confirm = true
		elseif confirmType == "string" then
			option.confirm = true
			option.confirmText = confirm
		elseif confirmType == "function" then
			option.confirm = confirm
		end
	end
end

---Check if module is disabled
---@param info InfoTable
function OptionMixin.IsModDisabled(info)
	if info.handler and info.handler.IsEnabled then
		return not info.handler:IsEnabled()
	else
		return false
	end
end

--- AceOptions validate that num is a number.
--- @param info InfoTable
--- @param num any
--- @return boolean|string
function OptionMixin.IsNumber(info, num)
	if not num or not tonumber(num) then
		return L["API_InputNumber"]
	end
	return true
end

--- Force AceOptions to refresh the option panel.
function OptionMixin:RefreshOptionsPanel()
	ACR:NotifyChange(optName)
end

-- Common Slider Values
OptionMixin.ScaleValues = {softMin = 0.5, softMax = 2, bigStep = 0.05, min = 0.25, max = 4, step = 0.01, isPercent = true}
OptionMixin.PercentValues = {min = 0, max = 1, step = 0.01, bigStep = 0.05, isPercent = true}

-- ####################################################################################################################
-- ##### Options: Generators ##########################################################################################
-- ####################################################################################################################
--- Generate Get/Set functions based on a database table.
---@param db AceDB-3.0
---@return function Get, function Set
function OptionMixin.GetSet(db)
	assert(type(db) == "table", "OptionMixin.GetSet argument #1 expected table, got "..type(db))
	local get = function(info)
		local value = db[info[#info]]
		if info.type == "input" then return tostring(value) end
		return value
	end

	local set = function(info, value)
		if tonumber(value) then
			value = tonumber(value)
		end
		db[info[#info]] = value
		if info.handler.Refresh then
			info.handler:Refresh()
		end
	end
	
	return get, set
end

--- Generate Get/Set functions for color options based on a database table.
--- Additionally, if handler is defined, will attempt to call RefreshColors if it exists.
---@param db AceDB-3.0
---@return function Get, function Set
function Opt.ColorGetSet(db)
	local get = function(info)
		local c = db[info[#info]]
		return c.r, c.g, c.b, c.a
	end
	
	local set = function(info, r, g, b, a)
		local c = db[info[#info]]
		c.r, c.g, c.b = RoundToSignificantDigits(r, 2), RoundToSignificantDigits(g, 2), RoundToSignificantDigits(b, 2)
		if info.option.hasAlpha then c.a = RoundToSignificantDigits(a, 2) end
		if info.handler.RefreshColors then info.handler:RefreshColors() end
	end
		
	return get, set
end

--- Default color getter if one is not provided. Will pull color from db.Colors
---@param info InfoTable
---@return number R, number G, number B, number A
local function defaultColorGet(info)
	local c = info.handler.db.profile.Colors[info[#info]]
	return c.r, c.g, c.b, c.a
end

--- Default color getter if one is not provided. Will pull color from db.Colors
---@param info InfoTable
local function defaultColorSet(info, r, g, b, a)
	local c = info.handler.db.profile.Colors[info[#info]]
	c.r, c.g, c.b = RoundToSignificantDigits(r, 2), RoundToSignificantDigits(g, 2), RoundToSignificantDigits(b, 2)
	if info.option.hasAlpha then c.a = RoundToSignificantDigits(a, 2) end
	if info.handler.RefreshColors then info.handler:RefreshColors() end
end

-- ####################################################################################################################
-- ##### Options: Helper Functions ####################################################################################
-- ####################################################################################################################

---@param name string|function
---@param desc? string|function
---@param order? number
---@param childGroups? string|"tree"|"tab"|"select"
---@param disabled? boolean|function
---@param hidden? boolean|function
---@param get? function
---@param set? function
---@return AceOptionGroup
function OptionMixin:Group(name, desc, order, childGroups, disabled, hidden, get, set)
	return { type = "group", childGroups = childGroups, name = name, desc = desc, order = order, disabled = disabled, hidden = hidden, get = get, set = set, args = {} }
end

---@param name string|function
---@param desc? string|function
---@param order number
---@param childGroups? string|"tree"|"tab"|"select"
---@param disabled? boolean|function
---@param hidden? boolean|function
---@param get? function
---@param set? function
---@return AceOptionGroup
function OptionMixin:InlineGroup(name, desc, order, childGroups, disabled, hidden, get, set)
	return { type = "group", childGroups = childGroups, name = name, desc = desc, order = order, disabled = disabled, hidden = hidden, get = get, set = set, inline = true, args = {} }
end

---@param name string|function
---@param order number
---@param hidden? boolean|function
---@return AceOptionHeader
function OptionMixin:Header(name, order, hidden)
	return { type = "header", name = name, order = order, hidden = hidden }
end

---@param name string|function
---@param desc? string|function
---@param order number
---@param alpha? boolean
---@param width? string|"normal"|"half"|"double"|"full"
---@param disabled? boolean|function
---@param hidden? boolean|function
---@param get? function
---@param set? function
---@return AceOptionColor
function OptionMixin:Color(name, desc, order, alpha, width, disabled, hidden, get, set)
	if not get then
		get = defaultColorGet
		set = defaultColorSet
	end
	return { type = "color", name = name, desc = desc, order = order, hasAlpha = alpha, width = width, disabled = disabled, hidden = hidden, get = get, set = set }
end

---@param order number
---@param width? string|"normal"|"half"|"double"|"full"
---@return AceOptionDesc
function OptionMixin:Spacer(order, width)
	return { name = "", type = "description", order = order, width = width }
end

---@param name string|function
---@param order number
---@param fontSize? string|"small"|"medium"|"large"
---@param image? string|function
---@param imageCoords? table|function|methodname
---@param imageWidth? number
---@param imageHeight? number
---@param width? string|"normal"|"half"|"double"|"full"
---@param hidden? boolean|function
---@return AceOptionDesc
function OptionMixin:Desc(name, order, fontSize, image, imageCoords, imageWidth, imageHeight, width, hidden)
	return { type = "description", name = name, order = order, fontSize = fontSize, image = image, imageCoords = imageCoords, imageWidth = imageWidth, imageHeight = imageHeight, width = width, hidden = hidden }
end

---@param name string|function
---@param desc? string|function
---@param order number
---@param tristate? boolean
---@param width? string|"normal"|"half"|"double"|"full"
---@param disabled? boolean|function
---@param hidden? boolean|function
---@param get? function
---@param set? function
---@return AceOptionToggle
function OptionMixin:Toggle(name, desc, order, tristate, width, disabled, hidden, get, set)
	return { type = "toggle", name = name, desc = desc, order = order, tristate = tristate, width = width, disabled = disabled, hidden = hidden, get = get, set = set }
end

---@param name string|function
---@param desc? string|function
---@param order number
---@param func function
---@param width? string|"normal"|"half"|"double"|"full"
---@param disabled? boolean|function
---@param hidden? boolean|function
---@return AceOptionExecute
function OptionMixin:Execute(name, desc, order, func, width, disabled, hidden)
	return { type = "execute", name = name, desc = desc, order = order, func = func, width = width, disabled = disabled, hidden = hidden }
end

---@param name string|function
---@param desc? string|function
---@param order number
---@param multiline? boolean|number
---@param width? string|"normal"|"half"|"double"|"full"
---@param disabled? boolean|function
---@param hidden? boolean|function
---@param validate? boolean
---@param get? function
---@param set? function
---@return AceOptionInput
function OptionMixin:Input(name, desc, order, multiline, width, disabled, hidden, validate, get, set)
	return { type = "input", name = name, desc = desc, order = order, multiline = multiline, width = width, disabled = disabled, hidden = hidden, validate = validate, get = get, set = set }
end

---@param name string|function
---@param desc? string|function
---@param order number
---@param multiline? boolean|number
---@param width? string|"normal"|"half"|"double"|"full"
---@param disabled? boolean|function
---@param hidden? boolean|function
---@param get? function
---@param set? function
---@return AceOptionInput
function OptionMixin:InputNumber(name, desc, order, multiline, width, disabled, hidden, get, set)
	return { type = "input", name = name, desc = desc, order = order, multiline = multiline, width = width, disabled = disabled, hidden = hidden, validate = Opt.IsNumber, get = get, set = set }
end

---@param name string|function
---@param desc? string|function
---@param order number
---@param values table @ `{ smin, smax, min, max, step, bigStep, isPercent }`
---@param width? string|"normal"|"half"|"double"|"full"
---@param disabled? boolean|function
---@param hidden? boolean|function
---@param get? function
---@param set? function
---@return AceOptionRange
function OptionMixin:Slider(name, desc, order, values, width, disabled, hidden, get, set)
	local t = { type = "range", name = name, desc = desc, order = order, width = width, disabled = disabled, hidden = hidden, get = get, set = set }
	for key, value in pairs(values) do
		t[key] = value
	end

	return t
end

---@param name string|function
---@param desc? string|function
---@param order number
---@param values table|function @ is a key-value table where Key is what will be saved and Value is what is being displayed to the user.
---@param width? string|"normal"|"half"|"double"|"full"-
---@param disabled? boolean|function
---@param hidden? boolean|function
---@param get? function
---@param set? function
---@return AceOptionSelect
function OptionMixin:Select(name, desc, order, values, width, disabled, hidden, get, set)
	return { type = "select", name = name, desc = desc, order = order, values = values, width = width, disabled = disabled, hidden = hidden, get = get, set = set }
end

---@param name string|function
---@param desc? string|function
---@param order number
---@param values table|function|"[key]=value table"|"Key is passed to Set, Value is text displayed"
---@param width? string|"normal"|"half"|"double"|"full"
---@param disabled? boolean|function
---@param hidden? boolean|function
---@param get? function
---@param set? function
---@return AceOptionMultiselect
function OptionMixin:MultiSelect(name, desc, order, values, width, disabled, hidden, get, set)
	return { type = "multiselect", name = name, desc = desc, order = order, values = values, width = width, disabled = disabled, hidden = hidden, get = get, set = set }
end

---@param name string|function
---@param desc? string|function
---@param order number
---@param width? string|"normal"|"half"|"double"|"full"
---@param disabled? boolean|function
---@param hidden? boolean|function
---@param get? function
---@param set? function
---@return AceOptionSelect
function OptionMixin:MediaBackground(name, desc, order, width, disabled, hidden, get, set)
	return { type = "select", dialogControl = "LSM30_Background", name = name, desc = desc, order = order, width = width, disabled = disabled, hidden = hidden, get = get, set = set, values = function() return LSM:HashTable("background") end }
end

---@param name string|function
---@param desc? string|function
---@param order number
---@param width? string|"normal"|"half"|"double"|"full"
---@param disabled? boolean|function
---@param hidden? boolean|function
---@param get? function
---@param set? function
---@return AceOptionSelect
function OptionMixin:MediaBorder(name, desc, order, width, disabled, hidden, get, set)
	return { type = "select", dialogControl = "LSM30_Border", name = name, desc = desc, order = order, width = width, disabled = disabled, hidden = hidden, get = get, set = set, values = function() return LSM:HashTable("border") end }
end

---@param name string|function
---@param desc? string|function
---@param order number
---@param width? string|"normal"|"half"|"double"|"full"
---@param disabled? boolean|function
---@param hidden? boolean|function
---@param get? function
---@param set? function
---@return AceOptionSelect
function OptionMixin:MediaStatusbar(name, desc, order, width, disabled, hidden, get, set)
	return { type = "select", dialogControl = "LSM30_Statusbar", name = name, desc = desc, order = order, width = width, disabled = disabled, hidden = hidden, get = get, set = set, values = function() return LSM:HashTable("statusbar") end }
end

---@param name string|function
---@param desc? string|function
---@param order number
---@param width? string|"normal"|"half"|"double"|"full"
---@param disabled? boolean|function
---@param hidden? boolean|function
---@param get? function
---@param set? function
---@return AceOptionSelect
function OptionMixin:MediaSound(name, desc, order, width, disabled, hidden, get, set)
	return { type = "select", dialogControl = "LSM30_Sound", name = name, desc = desc, order = order, width = width, disabled = disabled, hidden = hidden, get = get, set = set, values = function() return LSM:HashTable("sound") end }
end

---@param name string|function
---@param desc? string|function
---@param order number
---@param width? string|"normal"|"half"|"double"|"full"
---@param disabled? boolean|function
---@param hidden? boolean|function
---@param get? function
---@param set? function
---@return AceOptionSelect
function OptionMixin:MediaFont(name, desc, order, width, disabled, hidden, get, set)
	return { type = "select", dialogControl = "LSM30_Font", name = name, desc = desc, order = order, width = width, disabled = disabled, hidden = hidden, get = get, set = set, values = function() return LSM:HashTable("font") end }
end

--- Special Execute for the control panel
---@param name string
---@param desc? string|function
---@param order number
---@param enableFunc function @ Function to determine whether the target is enabled or disabled
---@param func function @ Function to call when button is clicked
---@param hidden? boolean|function
---@return AceOptionExecute
function OptionMixin:EnableButton(name, desc, order, enableFunc, func, hidden)
	local nameFunc = function()
		return format("%s: %s", name, (enableFunc() and L["API_BtnEnabled"] or L["API_BtnDisabled"]))
	end
	return self:Execute(nameFunc, desc, order, func, nil, nil, hidden)
end

-- ####################################################################################################################
-- ##### Option Templates: Font Menu ##################################################################################
-- ####################################################################################################################

local function FontMenuGetter(info)
	local db = info.handler.db.profile.Fonts
	local font = info[#info-1]
	local prop = info[#info]
	
	return db[font][prop]
end

local function FontMenuSetter(info, value)
	local db = info.handler.db.profile.Fonts
	local font = info[#info-1]
	local prop = info[#info]
	
	--for k, v in pairs(info) do LUI:Print(k, v) end
	db[font][prop] = value
	if info.handler.Refresh then
		info.handler:Refresh()
	end
end

local sizeValues = {min = 4, max = 72, step = 1, softMin = 8, softMax = 36}

--- Create an inline group containing font settings.
---@param name string
---@param desc? string|function
---@param order number
---@param disabled? boolean|function
---@param hidden? boolean|function
---@param customFontLocation table @ table reference where the font settings (Size/Name/Flag) are being saved
---@return AceOptionGroup
function OptionMixin:FontMenu(name, desc, order, disabled, hidden, customFontLocation)
	local group = Opt:Group(name, desc, order, nil, disabled, hidden)
	group.args.Size = Opt:Slider("Size", nil, 1, sizeValues, nil, disabled, hidden, FontMenuGetter, FontMenuSetter)
	group.args.Name = Opt:MediaFont("Font", nil, 2, nil, disabled, hidden, FontMenuGetter, FontMenuSetter)
	group.args.Flag = Opt:Select("Outline", nil, 3, LUI.FontFlags, nil, disabled, hidden, FontMenuGetter, FontMenuSetter)
	group.inline = true
	if customFontLocation then
		group.args.Size.arg = customFontLocation
		group.args.Name.arg = customFontLocation
		group.args.Flag.arg = customFontLocation
	end
	return group
end

-- ####################################################################################################################
-- ##### Option Templates: Color Menu #################################################################################
-- ####################################################################################################################

local function ColorMenuGetter(info)
	local db = info.handler.db.profile.Colors
	local c = db[string.sub(info.option.name,0, -7)]
	if info.type == "color" then
		return c.r, c.g, c.b, c.a
	elseif info.type == "select" then
		return c.t
	elseif info.type == "range" then
		return c.a
	end
end

local function ColorMenuSetter(info, value, g, b, a)
	local db = info.handler.db.profile.Colors
	local c = db[string.sub(info.option.name,0, -7)]
	if info.type == "color" then
		c.r, c.g = RoundToSignificantDigits(value, 2), RoundToSignificantDigits(g, 2)
		c.b, c.a = RoundToSignificantDigits(b, 2), RoundToSignificantDigits(a, 2)
	elseif info.type == "select" then
		LUI:Print("ct value")
		c.t = value
	elseif info.type == "range" then
		c.a = value
	end
	if info.handler.RefreshColors then
		info.handler.RefreshColors()
	end
end

--- Generate a Color / Dropdown combo, the dropdown selection determines the color bypass. (Theme, Class, Spec, etc)
---@param parent AceOption
---@param color string
---@param desc? string
---@param order number
---@param disabled? boolean|function
---@return AceOptionSelect
function OptionMixin:ColorMenu(parent, color, desc, order, disabled)
	-- TODO: Show Alpha Slider when using Theme/Class Colors.

	local hiddenFunc = function(info)
		local db = info.handler.db.profile.Colors
		
		local c = db[color]
		if info.type == "color" then
			return c.t ~= "Individual"
		elseif info.type == "range" then
			return c.t == "Individual"
		end
	end

	local t = self:Select(color.." Color", desc, order, LUI.ColorTypes, nil, disabled, nil, ColorMenuGetter, ColorMenuSetter)
	parent[color.."Picker"] = self:Color("Color", desc, order+0.1, true, nil, disabled, hiddenFunc, ColorMenuGetter, ColorMenuSetter)
	parent[color.."Slider"] = self:Slider("Opacity", desc, order+0.1, Opt.PercentValues, nil, disabled, hiddenFunc, ColorMenuGetter, ColorMenuSetter)
	parent[color.."Break"] = self:Spacer(order+0.2, "full")
	ACR:NotifyChange(optName)
	return t
end
-- ####################################################################################################################
-- ##### Options Tables ###############################################################################################
-- ####################################################################################################################
Mixin(Opt, OptionMixin)

local titleName = "New LUI Options"
do
    local version, alpha, git = strsplit("-", LUI.curseVersion)
	-- Break up the version string to avoid the curse packager converting it.
	if LUI.curseVersion == "@project".."-version@" then
		titleName = format("%s %s (Dev)", titleName, GetAddOnMetadata("LUI", "Version"))
	elseif not version or not alpha then
		titleName = format("%s %s (Release)", titleName, GetAddOnMetadata("LUI", "Version"))
    else
        titleName = format("%s %s (Alpha %s)", titleName, version, alpha)
    end
end

local options = {
	name = titleName,
	type = "group",
	get = "getter",
	set = "setter",
	handler = LUI,
	args = {
		Space = {
			name = "",
			order = 5,
			type = "group",
			disabled = true,
			args = {},
		},
		Modules = {
			name = L["Core_ModuleMenu"],
			order = 6,
			type = "group",
			disabled = true,
			args = {},
		},
	},
}
Opt.options = options

-- ####################################################################################################################
-- ##### Framework Functions ##########################################################################################
-- ####################################################################################################################

local optionsLoaded = false
function LUI:NewOpen(force, ...)
	if ACD.OpenFrames[optName] and not force then
		ACD:Close(optName)
	else
		-- Do not open options in combat unless already opened before.
		-- TODO: Find a better way to word the arning.
		if _G.InCombatLockdown() and not optionsLoaded then
			LUI:Print(L["Core_OpenOptionsFail"])
		else
			ACD:Open(optName, nil, ...)
			optionsLoaded = true
		end
	end
end

--- Utility function to avoid having too much boilerplate.
---@param name string @ Name of the LUI module to pull
---@return table @ Localizataion Table
---@return LUIModule @ Module Object
---@return table @ DB Profile table for the given module
function Opt:GetLUIModule(name)
	local module = LUI:GetModule(name, true) --[[@as LUIModule]]
	local db
	if module and module.db then
		db = module.db.profile
	end
	return L, module, db
end

function Opt:OnEnable()
	LibStub("AceConfig-3.0"):RegisterOptionsTable(optName, options)
	ACD:SetDefaultSize(optName, OPTION_PANEL_WIDTH, OPTION_PANEL_HEIGHT)
	options.args.Profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(LUI.db)
	options.args.Profiles.order = 4
end
