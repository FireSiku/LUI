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
	if not data then return end

	if not data.args then data.args = {} end
	if not data.childGroups then data.childGroups = "tab" end
	return data
end

---@param data LUIOption
function OptionMixin:InlineGroup(data)
	data = AddShared(data, "group")
	if not data then return end

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
	data = AddShared(data or {}, "description")
	if not data then return end
	
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
	if not data then return end

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
	if not data then return end

	data.dialogControl = "LSM30_Background"
	data.values = function() return LSM:HashTable("background") end
	return data
end

---@param data LUIOption
function OptionMixin:MediaBorder(data)
	data = AddShared(data, "select")
	if not data then return end

	data.dialogControl = "LSM30_Border"
	data.values = function() return LSM:HashTable("border") end
	return data
end

---@param data LUIOption
function OptionMixin:MediaStatusbar(data)
	data = AddShared(data, "select")
	if not data then return end

	data.dialogControl = "LSM30_Statusbar"
	data.values = function() return LSM:HashTable("statusbar") end
	return data
end

---@param data LUIOption
function OptionMixin:MediaSound(data)
	data = AddShared(data, "select")
	if not data then return end

	data.dialogControl = "LSM30_Sound"
	data.values = function() return LSM:HashTable("sound") end
	return data
end

---@param data LUIOption
function OptionMixin:MediaFont(data)
	data = AddShared(data, "select")
	if not data then return end

	data.dialogControl = "LSM30_Font"
	data.values = function() return LSM:HashTable("font") end
	return data
end

--- Special Execute for the control panel
---@param data LUIOption
function OptionMixin:EnableButton(data)
	data = AddShared(data, "execute")
	if not data then return end

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

local titleName = "LUI Options"
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
-- ##### Profile Import / Export ######################################################################################
-- ####################################################################################################################

local PROFILE_EXPORT_PREFIX = "!LUIProfile:1!"
local PROFILE_EXPORT_KIND = "LUI_PROFILE"
local PROFILE_EXPORT_FORMAT = 1
local MAX_PROFILE_STRING_LENGTH = 2000000

local profileExportText = ""
local profileImportName = ""
local profileImportText = ""

local PROFILE_RESOURCES = {
	Themes = "theme",
	Unitframes = "Layout",
}

local function TrimText(value)
	if type(value) ~= "string" then return "" end
	return value:match("^%s*(.-)%s*$") or ""
end

local function CopySerializable(value, seen, depth)
	local valueType = type(value)
	if valueType == "nil" or valueType == "boolean" or valueType == "number" or valueType == "string" then
		return value
	end
	if valueType ~= "table" then
		error("Unsupported value type: " .. valueType)
	end
	if depth > 100 then
		error("Profile data is nested too deeply")
	end
	if seen[value] then
		error("Profile data contains a recursive table")
	end

	seen[value] = true
	local copy = {}
	for key, childValue in pairs(value) do
		local keyType = type(key)
		if keyType ~= "boolean" and keyType ~= "number" and keyType ~= "string" then
			error("Unsupported profile key type: " .. keyType)
		end
		copy[key] = CopySerializable(childValue, seen, depth + 1)
	end
	seen[value] = nil
	return copy
end

local function CopyProfileData(value)
	return CopySerializable(value, {}, 0)
end

local function TablesMatch(first, second, compared)
	if type(first) ~= type(second) then return false end
	if type(first) ~= "table" then return first == second end

	compared = compared or {}
	if compared[first] == second then return true end
	compared[first] = second

	for key, value in pairs(first) do
		if not TablesMatch(value, second[key], compared) then return false end
	end
	for key in pairs(second) do
		if first[key] == nil then return false end
	end
	return true
end

local function CaptureProfileStorage(storage, profileName)
	local captured = {
		profile = CopyProfileData((storage.profiles and rawget(storage.profiles, profileName)) or {}),
	}

	if storage.namespaces then
		local namespaces
		for namespaceName, namespaceStorage in pairs(storage.namespaces) do
			if type(namespaceName) == "string" and type(namespaceStorage) == "table" then
				local child = CaptureProfileStorage(namespaceStorage, profileName)
				if next(child.profile) or child.namespaces then
					namespaces = namespaces or {}
					namespaces[namespaceName] = child
				end
			end
		end
		captured.namespaces = namespaces
	end

	return captured
end

local function ValidateCapturedStorage(storage, depth)
	if type(storage) ~= "table" or type(storage.profile) ~= "table" then
		return false
	end
	if depth > 30 then
		return false
	end
	if storage.namespaces ~= nil then
		if type(storage.namespaces) ~= "table" then
			return false
		end
		for namespaceName, child in pairs(storage.namespaces) do
			if type(namespaceName) ~= "string" or not ValidateCapturedStorage(child, depth + 1) then
				return false
			end
		end
	end
	return true
end

local function CaptureProfileResources(captured)
	local resources
	for moduleName, selectorKey in pairs(PROFILE_RESOURCES) do
		local namespace = captured.namespaces and captured.namespaces[moduleName]
		local resourceName = namespace and namespace.profile[selectorKey]
		local module = resourceName and LUI:GetModule(moduleName, true)
		local resource = module and module.db and module.db.global and rawget(module.db.global, resourceName)
		if type(resourceName) == "string" and resourceName ~= "" and type(resource) == "table" then
			resources = resources or {}
			resources[moduleName] = {
				name = resourceName,
				data = CopyProfileData(resource),
			}
		end
	end
	return resources
end

local function ValidateProfileResources(resources)
	if resources == nil then return true end
	if type(resources) ~= "table" then return false end
	for moduleName, resource in pairs(resources) do
		if not PROFILE_RESOURCES[moduleName]
			or type(resource) ~= "table"
			or type(resource.name) ~= "string"
			or resource.name == ""
			or type(resource.data) ~= "table" then
			return false
		end
	end
	return true
end

local function ImportProfileResources(captured, resources)
	if not resources then return end

	for moduleName, resource in pairs(resources) do
		local namespace = captured.namespaces and captured.namespaces[moduleName]
		local namespaceStorage = LUI.db.sv.namespaces and LUI.db.sv.namespaces[moduleName]
		if namespace and namespaceStorage then
			namespaceStorage.global = namespaceStorage.global or {}
			local resourceName = resource.name
			local existing = rawget(namespaceStorage.global, resourceName)

			if existing and not TablesMatch(existing, resource.data) then
				local baseName = resourceName .. " (Imported)"
				resourceName = baseName
				local suffix = 2
				local importedExisting = rawget(namespaceStorage.global, resourceName)
				while importedExisting and not TablesMatch(importedExisting, resource.data) do
					resourceName = format("%s %d", baseName, suffix)
					suffix = suffix + 1
					importedExisting = rawget(namespaceStorage.global, resourceName)
				end
			end

			namespaceStorage.global[resourceName] = CopyProfileData(resource.data)
			namespace.profile[PROFILE_RESOURCES[moduleName]] = resourceName
		end
	end
end

local function ClearStoredProfile(storage, profileName)
	if storage.profiles then
		storage.profiles[profileName] = nil
	end
	if storage.namespaces then
		for _, namespaceStorage in pairs(storage.namespaces) do
			if type(namespaceStorage) == "table" then
				ClearStoredProfile(namespaceStorage, profileName)
			end
		end
	end
end

local function StoreCapturedProfile(storage, profileName, captured)
	storage.profiles = storage.profiles or {}
	storage.profiles[profileName] = CopyProfileData(captured.profile)

	if captured.namespaces then
		storage.namespaces = storage.namespaces or {}
		for namespaceName, child in pairs(captured.namespaces) do
			storage.namespaces[namespaceName] = storage.namespaces[namespaceName] or {}
			StoreCapturedProfile(storage.namespaces[namespaceName], profileName, child)
		end
	end
end

local function ProfileExists(profileName)
	local profiles = LUI.db:GetProfiles()
	for _, existingName in ipairs(profiles) do
		if existingName == profileName then
			return true
		end
	end
	return false
end

local function GenerateProfileExport()
	local profileName = LUI.db:GetCurrentProfile()
	local captured = CaptureProfileStorage(LUI.db.sv, profileName)
	local payload = {
		kind = PROFILE_EXPORT_KIND,
		format = PROFILE_EXPORT_FORMAT,
		addonVersion = GetAddOnMetadata("LUI", "Version"),
		profileName = profileName,
		data = captured,
		resources = CaptureProfileResources(captured),
	}

	local ok, serialized = pcall(function()
		return LibStub("AceSerializer-3.0"):Serialize(payload)
	end)
	if not ok or type(serialized) ~= "string" then
		profileExportText = ""
		LUI:Print("Unable to export the current profile.")
		return
	end

	profileExportText = PROFILE_EXPORT_PREFIX .. serialized
	ACR:NotifyChange(optName)
end

local function ImportProfile()
	if _G.InCombatLockdown() then
		LUI:Print("Profiles cannot be imported while in combat.")
		return
	end

	local profileName = TrimText(profileImportName)
	local importText = TrimText(profileImportText)
	if profileName == "" or #profileName > 64 or profileName:find("[%c]") then
		LUI:Print("Enter a valid profile name with no more than 64 characters.")
		return
	end
	if importText == "" or #importText > MAX_PROFILE_STRING_LENGTH then
		LUI:Print("The profile import string is empty or too large.")
		return
	end
	if importText:sub(1, #PROFILE_EXPORT_PREFIX) ~= PROFILE_EXPORT_PREFIX then
		LUI:Print("This is not a valid LUI profile string.")
		return
	end

	local serialized = importText:sub(#PROFILE_EXPORT_PREFIX + 1)
	local callOK, valid, payload = pcall(function()
		return LibStub("AceSerializer-3.0"):Deserialize(serialized)
	end)
	if not callOK or not valid or type(payload) ~= "table"
		or payload.kind ~= PROFILE_EXPORT_KIND
		or payload.format ~= PROFILE_EXPORT_FORMAT
		or not ValidateCapturedStorage(payload.data, 0)
		or not ValidateProfileResources(payload.resources) then
		LUI:Print("The LUI profile string is invalid or damaged.")
		return
	end

	local copyOK, importedData, importedResources = pcall(function()
		return CopyProfileData(payload.data), CopyProfileData(payload.resources)
	end)
	if not copyOK then
		LUI:Print("The LUI profile contains unsupported data.")
		return
	end

	local currentProfile = LUI.db:GetCurrentProfile()
	ImportProfileResources(importedData, importedResources)
	ClearStoredProfile(LUI.db.sv, profileName)
	StoreCapturedProfile(LUI.db.sv, profileName, importedData)

	profileImportText = ""
	profileExportText = ""
	LUI:Printf("Profile '%s' imported successfully.", profileName)

	if profileName == currentProfile then
		_G.ReloadUI()
	else
		-- AceDB switches every registered module namespace as well. LUI's existing
		-- profile callback performs the required reload after the switch.
		LUI.db:SetProfile(profileName)
	end
end

local function CreateProfileTransferOptions()
	return {
		name = "Profile Import / Export",
		type = "group",
		inline = true,
		order = 90,
		args = {
			Description = {
				name = "Export the active LUI profile or import a shared profile. Module settings and their selected custom theme or unitframe layout are included; account-wide data such as gold totals is not exported.",
				type = "description",
				order = 1,
				width = "full",
			},
			GenerateExport = {
				name = "Generate Export String",
				desc = "Generate a shareable string from the currently active profile.",
				type = "execute",
				order = 2,
				func = GenerateProfileExport,
			},
			ExportString = {
				name = "Export String",
				desc = "Press Ctrl+A and Ctrl+C to copy the complete string.",
				type = "input",
				order = 3,
				width = "full",
				multiline = 8,
				get = function() return profileExportText end,
				set = function(_, value) profileExportText = value end,
			},
			ImportHeader = {
				name = "Import",
				type = "header",
				order = 4,
			},
			ImportName = {
				name = "Profile Name",
				desc = "The imported profile will be saved under this name.",
				type = "input",
				order = 5,
				width = "full",
				get = function() return profileImportName end,
				set = function(_, value) profileImportName = value end,
			},
			ImportString = {
				name = "Import String",
				desc = "Paste the complete LUI profile string here.",
				type = "input",
				order = 6,
				width = "full",
				multiline = 8,
				get = function() return profileImportText end,
				set = function(_, value) profileImportText = value end,
			},
			Import = {
				name = "Import Profile",
				desc = "Import the profile and switch to it.",
				type = "execute",
				order = 7,
				func = ImportProfile,
				disabled = function()
					return _G.InCombatLockdown() or TrimText(profileImportName) == "" or TrimText(profileImportText) == ""
				end,
				confirm = function()
					local profileName = TrimText(profileImportName)
					if ProfileExists(profileName) then
						return format("The profile '%s' already exists. Overwrite it?", profileName)
					end
					return false
				end,
			},
		},
	}
end

-- ####################################################################################################################
-- ##### Framework Functions ##########################################################################################
-- ####################################################################################################################

local optionsLoaded = false
function LUI:NewOpen(force, ...)
	if ACD.OpenFrames[optName] and not force then
		ACD:Close(optName)
	else
		-- Do not open options in combat unless already opened before.
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
	options.args.Profiles.args.LUIProfileTransfer = CreateProfileTransferOptions()
end
