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

--local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local L = LUI.L

local OPTION_PANEL_WIDTH = 930
local OPTION_PANEL_HEIGHT = 660

-- Avoid extraneous Libstub calls
Opt.LUI = LUI
Opt.ACR = ACR

local RoundToSignificantDigits = _G.RoundToSignificantDigits
local GetAddOnMetadata = C_AddOns.GetAddOnMetadata

---@class OptionMixin
local OptionMixin = {}

-- Increase with each option call.
local nextOrder = 1

---@class LUIOption : AceConfig.OptionsTable
---@field db? table @ The database table to use for this option's get/set functions.
---@field onlyIf? boolean @ SHould be written as a condition. If false, the option will not be added to the table.
local LUIOptionMeta = {}

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

--- Getter/Setter for debugging purposes
local function debugGetSet(db)

	local function debugGet(info, test)
		local value = db[info[#info]]
		if info.type == "input" then return tostring(value) end
		LUI:Print("Get", info[#info], value, type(value), test)
		if type(value) == "table" then LUI:PrintTable(value) end
		LUI:PrintTable(info)
		return value
	end

	local function debugSet(info, value)
		if tonumber(value) then
			value = tonumber(value)
		end
		LUI:Print("Set", info[#info], value, type(value))
		db[info[#info]] = value
		if info.handler.Refresh then
			info.handler:Refresh()
		end
	end

	return debugGet, debugSet
end

--- Process data coming from Option API and turn it into a proper AceOption table with auto-incrementing order.
---@param data LUIOption
---@param optionType string @ AceConfigType
---@return LUIOption
local function AddShared(data, optionType)
	-- No need to process data if it fails the conditional, clear it otherwise
	if data.onlyIf == false then return end
	data.onlyIf = nil

	-- Handle generic AceOptions properties
	data.type = optionType
	if not data.order then data.order = nextOrder end

	-- Provides a quick way to debug options
	if data.debug then
		data.get, data.get = debugGetSet(data.debug)
		data.debug = nil
	end

	-- If db is provided, generate get/set functions accordingly
	if data.db then
		if data.type == "color" then
			data.get, data.set = OptionMixin.ColorGetSet(data.db)
		else
			data.get, data.set = OptionMixin.GetSet(data.db)
		end
		data.db = nil
	end
	nextOrder = nextOrder + 1
	return data
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
	local get = function(info, key)
		local value = db[info[#info]]
		if info.type == "multiselect" then return value[key] end
		if info.type == "input" then return tostring(value) end
		return value
	end

	local set = function(info, value, state)
		if tonumber(value) then
			value = tonumber(value)
		end
		if info.type == "multiselect" then
			db[info[#info]][value] = state
		else
			db[info[#info]] = value
		end
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
function OptionMixin.ColorGetSet(db)
	local get = function(info)
		local c = db[info[#info]]
		return c.r, c.g, c.b, c.a
	end
	
	local set = function(info, r, g, b, a)
		local c = db[info[#info]]
		c.r, c.g, c.b = RoundToSignificantDigits(r, 2), RoundToSignificantDigits(g, 2), RoundToSignificantDigits(b, 2)
		if info.option.hasAlpha then c.a = RoundToSignificantDigits(a, 2) end
		if info.handler.RefreshColors then 
			info.handler:RefreshColors()
		elseif info.handler.Refresh then
			info.handler:Refresh()
		end
	end
		
	return get, set
end

--- Default color getter if one is not provided. Will pull color from db.Colors
---@param info InfoTable
---@return number R, number G, number B, number A
local function defaultColorGet(info)
	assert(type(info.handler.db.profile.Colors) == "table", info[#info]..": Could not find 'Colors' table for handler "..info.handler:GetName())
	local c = info.handler.db.profile.Colors[info[#info]]
	return c.r, c.g, c.b, c.a
end

--- Default color getter if one is not provided. Will pull color from db.Colors
---@param info InfoTable
local function defaultColorSet(info, r, g, b, a)
	local c = info.handler.db.profile.Colors[info[#info]]
	c.r, c.g, c.b = RoundToSignificantDigits(r, 2), RoundToSignificantDigits(g, 2), RoundToSignificantDigits(b, 2)
	if info.option.hasAlpha then c.a = RoundToSignificantDigits(a, 2) end
	if info.handler.RefreshColors then 
		info.handler:RefreshColors()
	elseif info.handler.Refresh then
		info.handler:Refresh()
	end
end

-- ####################################################################################################################
-- ##### Options: Helper Functions ####################################################################################
-- ####################################################################################################################

---@param data LUIOption
function OptionMixin:Group(data)
	data = AddShared(data, "group")
	if not data.args then data.args = {} end
	if not data.childGroups then data.childGroups = "tab" end
	return data
end

---@param data LUIOption
function OptionMixin:InlineGroup(data)
	data = AddShared(data, "group")
	data.inline = true
	if not data.args then data.args = {} end
	return data
end

---@param data LUIOption
function OptionMixin:Header(data)
	data = AddShared(data, "header")
	return data
end

---@param data LUIOption
function OptionMixin:Color(data)
	data = AddShared(data, "color")
	if data and not data.get then
		data.get = defaultColorGet
		data.set = defaultColorSet
	end
	return data
end

---@param data? LUIOption
function OptionMixin:Spacer(data)
	if not data then data = {} end
	data = AddShared(data, "description")
	data.name = ""
	return data
end

---@param data LUIOption
function OptionMixin:Desc(data)
	data = AddShared(data, "description")
	return data
end

---@param data LUIOption
function OptionMixin:Toggle(data)
	data = AddShared(data, "toggle")
	return data
end

---@param data LUIOption
function OptionMixin:Execute(data)
	data = AddShared(data, "execute")
	return data
end

---@param data LUIOption
function OptionMixin:Input(data)
	data = AddShared(data, "input")
	return data
end

---@param data LUIOption
function OptionMixin:InputNumber(data)
	data = AddShared(data, "input")
	data.validate = self.IsNumber
	return data
end

---@param data LUIOption
function OptionMixin:Slider(data)
	data = AddShared(data, "range")
	-- Range doesnt support the values field, but this let us easily do reusable slider settings.
	if data and data.values then
		for key, value in pairs(data.values) do
			data[key] = value
		end
		data.values = nil
	end
	return data
end

---@param data LUIOption
function OptionMixin:Select(data)
	data = AddShared(data, "select")
	return data
end

---@param data LUIOption
function OptionMixin:MultiSelect(data)
	data = AddShared(data, "multiselect")
	return data
end

---@param data LUIOption
function OptionMixin:MediaBackground(data)
	data = AddShared(data, "select")
	data.dialogControl = "LSM30_Background"
	data.values = function() return LSM:HashTable("background") end
	return data
end

---@param data LUIOption
function OptionMixin:MediaBorder(data)
	data = AddShared(data, "select")
	data.dialogControl = "LSM30_Border"
	data.values = function() return LSM:HashTable("border") end
	return data
end

---@param data LUIOption
function OptionMixin:MediaStatusbar(data)
	data = AddShared(data, "select")
	data.dialogControl = "LSM30_Statusbar"
	data.values = function() return LSM:HashTable("statusbar") end
	return data
end

---@param data LUIOption
function OptionMixin:MediaSound(data)
	data = AddShared(data, "select")
	data.dialogControl = "LSM30_Sound"
	data.values = function() return LSM:HashTable("sound") end
	return data
end

---@param data LUIOption
function OptionMixin:MediaFont(data)
	data = AddShared(data, "select")
	data.dialogControl = "LSM30_Font"
	data.values = function() return LSM:HashTable("font") end
	return data
end

--- Special Execute for the control panel
---@param data LUIOption
function OptionMixin:EnableButton(data)
	data = AddShared(data, "execute")

	-- Store info in locals to create closures.
	local name = data.name
	local enableFunc = data.enableFunc
	data.enableFunc = nil
	data.name = function()
		return format("%s: %s", name, (enableFunc() and L["API_BtnEnabled"] or L["API_BtnDisabled"]))
	end

	return data
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
---@param data LUIOption
function OptionMixin:FontMenu(data)
	data = AddShared(data, "group")
	data.inline = true
	data.args = {
		Size = Opt:Slider({name = "Size", values = sizeValues, get = FontMenuGetter, set = FontMenuSetter, arg = data.customFontLocation}),
		Name = Opt:MediaFont({name = "Font", get = FontMenuGetter, set = FontMenuSetter, arg = data.customFontLocation}),
		Flag = Opt:Select({name = "Outline", values = LUI.FontFlags, get = FontMenuGetter, set = FontMenuSetter, arg = data.customFontLocation}),
	}
	return data
end

-- ####################################################################################################################
-- ##### Option Templates: Color Menu #################################################################################
-- ####################################################################################################################
-- ColorType = Opt:Select({name = "Panel Color", values = LUI.ColorTypes,
-- get = function(info) return db.Colors[name].t end, --getter
-- set = function(info, value) db.Colors[name].t = value; module:Refresh() end}), --setter

local defaultColorSelectGet = function(info)
	local db = info.handler.db.profile.Colors
	if not info.arg then error("ColorSelect missing 'arg' option to specify the color for " .. info.handler:GetName() .. "'s " .. info[#info]); return end
	local c = db[info.arg]
	return c.t
end

local defaultColorSelectSet = function(info, value)
	local db = info.handler.db.profile.Colors
	db[info.arg].t = value
	if info.handler.RefreshColors then
		info.handler:RefreshColors()
	elseif info.handler.Refresh then
		info.handler:Refresh()
	end
end

function OptionMixin:ColorSelect(data)
	data = AddShared(data, "select")
	data.values = LUI.ColorTypes
	if data and not data.get then
		data.get = defaultColorSelectGet
		data.set = defaultColorSelectSet
	end
	return data
end

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
---@return LUIOption
function OptionMixin:ColorMenu(parent, color, desc, order, disabled)
	-- TODO: Show Alpha Slider when using Theme/Class Colors.
	local hiddenFunc = function(info)
		local db = info.handler.db.profile.Colors
		
		local c = (type(color) == "string" and db[color] or color.db)
		if info.type == "color" then
			return c.t ~= "Individual"
		elseif info.type == "range" then
			return c.t == "Individual"
		end
	end

	if type(color) == "table" then
		AddShared(color, "select")
		local name = color.name
		color.name = name.." Color"
		color.values = LUI.ColorTypes
		color.get, color.set = ColorMenuGetter, ColorMenuSetter
		parent[name.."Picker"] = self:Color({name = "Color", desc = color.desc, disabled = color.disabled, hidden = hiddenFunc, get = ColorMenuGetter, set = ColorMenuSetter, hasAlpha = true})
		parent[name.."Slider"] = self:Slider({name = "Opacity", desc = color.desc, disabled = color.disabled, hidden = hiddenFunc, get = ColorMenuGetter, set = ColorMenuSetter, values = self.PercentValues})
		parent[name.."Break"] = self:Spacer({width = "full"})
		ACR:NotifyChange(optName)
		return color
	end

	local t = self:Select(color.." Color", desc, order, LUI.ColorTypes, nil, disabled, nil, ColorMenuGetter, ColorMenuSetter)
	parent[color.."Picker"] = self:Color("Color", desc, order+0.1, true, nil, disabled, hiddenFunc, ColorMenuGetter, ColorMenuSetter)
	parent[color.."Slider"] = self:Slider("Opacity", desc, order+0.1, self.PercentValues, nil, disabled, hiddenFunc, ColorMenuGetter, ColorMenuSetter)
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

--- Set up a module's options table.
---@param name string @ Name of the module. Will display result of L["Module_"..name] in the options.
---@param module LUIModule
---@return LUIOption
function Opt:CreateModuleOptions(name, module, hidden)
    local options = self:Group({name = name, childGroups = "tab", disabled = Opt.IsModDisabled, hidden = hidden, db = module.db.profile})
    Opt.options.args[name] = options -- Add it to the overall options table
    options.handler = module
    return options
end

function Opt:OnEnable()
	LibStub("AceConfig-3.0"):RegisterOptionsTable(optName, options)
	ACD:SetDefaultSize(optName, OPTION_PANEL_WIDTH, OPTION_PANEL_HEIGHT)
	options.args.Profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(LUI.db)
	options.args.Profiles.order = 4
end
