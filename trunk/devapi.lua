--[[
	Name........: DevAPI
	Description.: Developer's API for LUI Module Options
	Dependencies: LUI, LibStub, AceAddon, AceConfigRegistry-3.0, AceEvent-3.0, LibSharedMedia-3.0
]]

local MAJOR, MINOR = "LUIDevAPI", 2 -- increase manually when changes are made
local devapi = LibStub:NewLibrary(MAJOR, MINOR)

if not devapi then return end

local ACR = LibStub("AceConfigRegistry-3.0")
local AceEvent = LibStub("AceEvent-3.0")
local Media = LibStub("LibSharedMedia-3.0")

devapi.embeds = devapi.embeds or {}

local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local addonname = LUI:GetName()
local argcheck = LUI.argcheck

--localized API for efficency
local type, pairs, unpack, setmetatable, tinsert = type, pairs, unpack, setmetatable, tinsert
local tostring, tonumber = tostring, tonumber
local floor = floor

--for NewPosSliders
local UI_Scale_Update = {}

--function metatables
local descfuncs = setmetatable({
	["nil"] = function(self, desc, specialdefault)
		return nil
	end,
	["function"] = function(self, desc, specialdefault)
		if specialdefault then
			return function(info, ...)
				return desc(info, ...).."\n\nDefault: "..specialdefault(info, ...)
			end
		else
			return function(info)
				return desc(info).."\n\nDefault: "..self:GetDefaultVal(info)
			end
		end
	end,
	["string"] = function(self, desc, specialdefault)
		if specialdefault then
			return function(info, ...)
				return desc.."\n\nDefault: "..specialdefault(info, ...)
			end
		else
			return function(info)
				return desc.."\n\nDefault: "..self:GetDefaultVal(info)
			end
		end
	end,
}, {
	__call = function(t, self, func, desc, specialdefault)
		argcheck(t, "typeof", "table")
		argcheck(self, "typeof", "table")
		argcheck(desc, "typeof", "string;function;nil")
		argcheck(specialdefault, "typeof", "function;nil")
		
		if func == false then
			return desc
		else
			return t[type(desc)](self, desc, specialdefault)
		end
	end,
})
local getfuncs = setmetatable({
	["boolean"] = function(self, func, specialget)
		return nil
	end,
	["nil"] = function(self, func, specialget)
		return specialget or function(info)
			return self:GetDBVar(info)
		end
	end,
}, {
	__index = function(t, k) -- standard (nil)
		return t["nil"]
	end,
	__call = function(t, self, func, specialget)
		argcheck(t, "typeof", "table")
		argcheck(self, "typeof", "table")
		argcheck(func, "typeof", "string;function;boolean;nil")
		argcheck(specialget, "typeof", "function;nil")
		
		return t[type(func)](self, func, specialget)
	end
})
local setfuncs = setmetatable({
	["string"] = function(self, func, specialset) -- methodname
		argcheck(func, "isin", self)
		
		if specialset then
			return function(info, ...)
				specialset(info, ...)
				self[func](self, info, ...)
			end
		else
			return function(info, value)
				self:SetDBVar(info, value)
				self[func](self, info, value)
			end
		end
	end,
	["function"] = function(self, func, specialset)
		if specialset then
			return function(info, ...)
				specialset(info, ...)
				func(info, ...)
			end
		else
			return function(info, value)
				self:SetDBVar(info, value)
				func(info, value)
			end
		end
	end,
	["boolean"] = function(self, func, specialset)
		return nil
	end,
	["nil"] = function(self, func, specialset)
		return specialset or function(info, value)
			self:SetDBVar(info, value)
		end
	end,
}, {
	__index = function(t, k) -- standard (nil)
		return t["nil"]
	end,
	__call = function(t, self, func, specialset)
		argcheck(t, "typeof", "table")
		argcheck(self, "typeof", "table")
		argcheck(func, "typeof", "string;function;boolean;nil")
		argcheck(specialset, "typeof", "function;nil")
		
		return t[type(func)](self, func, specialset)
	end
})

local valuesMT = {
	__call = function(t, get)
		if get ~= nil then
			for k, v in pairs(t) do
				if v == get then
					return k
				end
			end
		end
		
		return t
	end
}

--local functions
local function getColor(t)
	argcheck(t, "typeof", "table")
	
	if t.r then
		return t.r, t.g, t.b, t.a
	else
		return unpack(t)
	end
end
local function setColor(t, ...)
	argcheck(t, "typeof", "table")
	
	if t.r then
		t.r, t.g, t.b = ...
		if t.a then t.a = select(4, ...) end
	else
		t[1], t[2], t[3] = ...
		if t[4] then t[4] = select(4, ...) end
	end
end

local getWidthValues, getHeightValues
do
	local function round(number) -- round to nearest 10s
		return (number > 0 and ceil or floor)(number/10) * 10
	end
	
	local regexp = "(%a)([%w_']*)" -- (first letter of each word)(rest of each word)
	
	local function titleCase(first, rest)
		return first:upper()..rest:lower()
	end
	
	getWidthValues = function(frame)
		argcheck(frame, "typeof", "frame")
		
		local point, parent, rpoint = frame:GetPoint()
		if not (point and parent and rpoint) then return 0, 0 end
		
		local width = frame:GetWidth()
		local scale = 1 -- frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
		
		point, rpoint = point:upper(), rpoint:upper()
		
		local base = parent["Get"..(rpoint:match("LEFT") or rpoint:match("RIGHT") or "CENTER"):gsub(regexp, titleCase)](parent)
		
		local smin = -base/scale
		local smax = (UIParent:GetWidth() - base)/scale
		
		if point:find("LEFT") then
			smin = smin - width
		elseif point:find("RIGHT") then
			smax = smax + width
		else -- CENTER
			smin = smin - (width/2)
			smax = smax + (width/2)
		end
		
		return round(smin), round(smax)
	end
	
	getHeightValues = function(frame)
		argcheck(frame, "typeof", "frame")
		
		local point, parent, rpoint = frame:GetPoint()
		if not (point and parent and rpoint) then return 0, 0 end
		
		local height = frame:GetHeight()
		local scale = 1 -- frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
		
		point, rpoint = point:upper(), rpoint:upper()
		
		local base = select(-1, parent["Get"..(rpoint:match("TOP") or rpoint:match("BOTTOM") or "CENTER"):gsub(regexp, titleCase)](parent)) -- GetCenter returns x, y
		
		local smin = -base/scale
		local smax = (UIParent:GetHeight() - base)/scale
		
		if point:find("BOTTOM") then
			smin = smin - height
		elseif point:find("TOP") then
			smax = smax + height
		else
			smin = smin - (height/2)
			smax = smax + (height/2)
		end
		
		return round(smin), round(smax)
	end
end

--Local command to handle the type/name/order states of all option wrappers.

local function SetVals(stype, sname, sorder)
	argcheck(stype, "typeof", "string")
	argcheck(sname, "typeof", "string;function;nil")
	argcheck(sorder, "typeof", "number;string;function;nil")
	
	local t = {type = stype, order = sorder, name = sname}
	return t
end

--Local command to handle the width/disable/hidden states of all option wrappers.

local function SetState(t, width, disabled, hidden)
	argcheck(t, "typeof", "table")
	argcheck(width, "typeof", "string;nil")
	argcheck(disabled, "typeof", "string;function;boolean;nil")
	argcheck(hidden, "typeof", "string;function;boolean;nil")
	
	t.width = width
	t.disabled = disabled
	t.hidden = hidden
end

--Local command that validates if it's a number or not.
local function IsNumber(info, num)
	if not (num and tonumber(num)) then
		return "Please input a number."
	end
	return true
end

local function GetParentInfo(info)
	argcheck(info, "typeof", "table")
	
	local parentinfo = info.options.args
	for i=1, #info-1 do
		parentinfo = parentinfo[info[i]].args
	end
	return parentinfo
end

--Dummy option, used to create more.
local function ShadowOption()
	local t = {type = "description", order = 500}
	
	SetState(t, nil, true, true)
	return t
end

----------------------------------------------
--											--
-- 		Embeded New Option Functions		--
--											--
----------------------------------------------

--[[ args:
	name (string|function) - Display name for the option
	desc (string|function) - description for the option (or nil for a self-describing name)
		- the default value of the option will be added to the description (see func)
	order (number|methodname|function) - relative position of item (default = 100, 0=first, -1=last)
	func (methodname|function|boolean) - function to call with set
		- (methodname|function) - function to call after value has been set
		- (boolean) - no get/set functions; value: whether or or not to show the default value in the description
		- nil - standard get/set functions; show default value in description
	width (string) - "double", "half", "full", "normal"
		- "double", "half" - increase/decrease the size of the option
		- "full" - make the option the full width of the window (or section of the window the option is in)
		- "normal" - use the default widget width defined for the implementation (useful to overwrite widgets the default to "full")
	disabled (methodname|function|boolean) - disabled but visible
	hidden (methodname|function|boolean) - hidden (but usable if you can get to it, i.e. via commandline)
--]]



-- devapi:NewGroup(name, order [, childGroups] [, get [, set]] [, guiInline [, disabled [, hidden]]], args)
--[[
	childGroups (string) - layout for groups inside this group (optional)
	get (methodname|function|string) - get function for all options in this group that don't have thier own get function (optional)
		- "skip" or "nil" (string) can be used to set get function to nil for the group
		- "generic" (string) can be used for a general get function that will traverse the db via the info table
	set (methodname|function|string) - set function for all options in this group that don't have thier own set function (optional, get required)
		- "skip" or "nil" (string) can be used to set set function as nil for the group
		- "generic" (string) can be used for a general set function that will traverse the db via the info table
	guiInline (boolean) - if group should show inline with the other options or be a new tab, section, etc. (optional)
	disabled (methodname|function|boolean) - disabled function (optional, guiInline required)
	hidden (methodname|function|boolean) - hidden function (optional, disabled required)
	args (table) - subtable with more items/groups in it
--]]
function devapi:NewGroup(name, order, ...)
	local t = SetVals("group", name, order)
	
	local hidden, disabled
	
	local args, i = {...}, 1
	while i <= #args do
		if type(args[i]) == "table" then -- args
			t.args = args[i]
			break
		elseif i == 1 and type(args[i]) == "string" and (args[i] == "tree" or args[i] == "tab" or args[i] == "select")  then -- childGroups
			t.childGroups = args[i]
			i = i + 1
		elseif i < 3 and (type(args[i]) == "function" or type(args[i]) == "string") then -- get/set
			-- get
			if type(args[i]) == "function" or self[args[i]] then -- function/methodname
				t.get = args[i]
			elseif args[i] ~= "skip" and args[i] ~= "nil" then -- generic
				t.get = getfuncs["nil"](self)
			end
			i = i + 1
			
			-- set
			if type(args[i]) == "function" or type(args[i]) == "string" then
				if type(args[i]) == "function" or self[args[i]] then -- function/methodname
					t.set = args[i]
				elseif args[i] ~= "skip" and args[i] ~= "nil" then -- generic
					t.set = setfuncs["nil"](self)
				end
				i = i + 1
			end
		else -- guiInline, disabled, hidden
			t.guiInline = args[i]
			i = i + 1
			if type(args[i]) ~= "table" then
				disabled = args[i]
				i = i + 1
				if type(args[i]) ~= "table" then
					hidden = args[i]
					i = i + 1
				end
			end
		end
	end
	
	t.handler = self
	
	SetState(t, nil, disabled, hidden)
	return t
end

--[[
--]]
function devapi:NewHeader(name, order, width, disabled, hidden)
	local t = SetVals("header", name, order)
	SetState(t, width, disabled, hidden)
	return t
end

--[[
--]]
function devapi:NewDesc(name, order, width, disabled, hidden)
	local t = SetVals("description", name, order)
	SetState(t, width or "full", disabled, hidden)
	return t
end

--[[
--]]
function devapi:NewToggle(name, desc, order, func, width, disabled, hidden)
	local t = SetVals("toggle", name, order)
	t.desc = descfuncs(self, func, desc or "Whether or not to "..name..".", function(info) return self:GetDefaultVal(info) and "Enabled" or "Disabled" end)
	t.get = getfuncs(self, func)
	t.set = setfuncs(self, func)
	
	SetState(t, width or "full", disabled, hidden)
	return t
end

--[[
	func (methodname|function)
		- same as above except boolean will not work
--]]
function devapi:NewEnable(name, desc, order, func, width, disabled, hidden)
	local t = SetVals("toggle", name, order)
	t.desc = descfuncs(self, func, desc or "Whether or not to "..name..".", function(info) return (self.defaultState == nil or self.defaultState) and "Enabled" or "Disabled" end)
	t.get = getfuncs(self, func, function(info) return self:IsEnabled() end)
	t.set = setfuncs(self, func, function(info, value) self:Toggle(value) end)

	SetState(t, width or "full", disabled, hidden)
	return t
end

--[[
	values (table|function|true) - [key]=value pair table to choose from
		- key is the value passed to "set"
		- value is the string displayed
		- only use true (boolean) if using a dcontrol (will use corresponding LibSharedMedia HashTable)
	dcontrol (string|false) - AceGUI-3.0 dialog control to use
		- false (boolean) - no dialog control; use normal style functions instead of values[value] style functions
		- (nil) - no dialog control; values[value] style functions
--]]
function devapi:NewSelect(name, desc, order, values, dcontrol, func, width, disabled, hidden)
	argcheck(values, "typeof", "table;function;boolean")

	if values == true then values = Media:HashTable(strlower(strsub(dcontrol, 7))) end
	if type(values) == "table" then setmetatable(values, valuesMT) end
	
	local t = SetVals("select", name, order)
	t.values = values
	t.desc = descfuncs(self, func, desc, dcontrol and function(info) return self:GetDefaultVal(info) end or nil)
	t.get = getfuncs(self, func, dcontrol == nil and function(info)
		local val = self:GetDBVar(info)
		for k, v in pairs(values()) do
			if v == val then
				return k
			end
		end
	end or nil)
	t.set = setfuncs(self, func, dcontrol == nil and function(info, value) self:SetDBVar(info, values()[value]) end or nil)
	
	if dcontrol then t.dialogControl = dcontrol end
	
	SetState(t, width, disabled, hidden)
	return t
end

--[[
	values (table|function) = [key]=value pair table to choose from
		- key is the value passed to "set"
		- value is the string displayed
--]]
function devapi:NewMultiSelect(name, desc, order, values, func, width, disabled, hidden)
	argcheck(values, "typeof", "table;function")
	
	if type(values) == "table" then setmetatable(values, valuesMT) end
	
	local t = SetVals("multiselect", name, order)
	t.values = values
	t.desc = descfuncs(self, func, desc, function(info)
		local default, defaults = "", self:GetDefaultVal(info)
		for k, v in pairs(defaults) do
			default = default.."\n"..values()[k]..": "..(v and "Enabled" or "Disabled")
		end
		return default
	end)
	t.get = getfuncs(self, func, function(info, key) return self:GetDBVar(info)[key] end)
	t.set = setfuncs(self, func, function(info, key, value) self:GetDBVar(info)[key] = value end)
	
	SetState(t, width, disabled, hidden)
	return t
end

--[[
	func (methodname|function) - function to execute
	confirm (methodname|function|boolean|string) - show confirmation prompt before firing func
		- (methodname|function) function that returns string to display (see string) or boolean (see boolean)
		- (boolean) if true: prompt message = "name - desc"; if false: skip prompt
		- (string) prompt message
--]]
function devapi:NewExecute(name, desc, order, func, confirm, width, disabled, hidden)
	argcheck(func, "typeof", "string;function;nil")
	argcheck(confirm, "typeof", "string;function;boolean;nil")
	
	local t = SetVals("execute", name, order)
	t.desc = desc
	t.func = func
	if type(confirm) == "string" and not self[confirm] then
		t.confirm = true
		t.confirmText = confirm
	else
		t.confirm = confirm
	end
	
	SetState(t, width, disabled, hidden)
	return t
end

--[[
--]]
function devapi:NewInput(name, desc, order, func, width, disabled, hidden)
	local t = SetVals("input", name, order)
	t.desc = descfuncs(self, func, desc)
	t.get = getfuncs(self, func, function(info) return tostring(self:GetDBVar(info)) end)
	t.set = setfuncs(self, func)

	SetState(t, width, disabled, hidden)
	return t
end

--[[
	iformat (string) - formatstring to pass to format function
		- (nil) defaults to "%.1f" (number truncated to tenth of a diget)
--]]
function devapi:NewInputNumber(name, desc, order, func, width, disabled, hidden, iformat)
	argcheck(iformat, "typeof", "string;nil")
	
	iformat = iformat or "%.1f"
	
	local t = SetVals("input", name, order)
	t.desc = descfuncs(self, func, desc, function(info) return iformat:format(self:GetDefaultVal(info)) end)
	t.validate = IsNumber
	t.get = getfuncs(self, func, function(info) return iformat:format(self:GetDBVar(info)) end)
	t.set = setfuncs(self, func, function(info, value) self:SetDBVar(info, tonumber(iformat:format(value):match("[-]?%d+[%.[%d]*]?"))) end) -- strip number from formatted string

	SetState(t, width, disabled, hidden)
	return t
end

--[[
	smin (number) - min value (defaults to 1)
	smax (number) - max value (defaults to 100)
	step (number) - step value: "smaller than this will break the code" (defaults to 1)
	isPercent (boolean) - represent e.g. 1.0 as 100%, etc.
--]]
function devapi:NewSlider(name, desc, order, smin, smax, step, func, isPercent, width, disabled, hidden)
	argcheck(smin, "typeof", "number;nil")
	argcheck(smax, "typeof", "number;nil")
	argcheck(step, "typeof", "number;nil")
	argcheck(isPercent, "typeof", "boolean;nil")
	
	local t = SetVals("range", name, order)
	t.desc = descfuncs(self, func, desc, isPercent and function(info) return (format("%d%%", self:GetDefaultVal(info)*100)) end or nil)
	if isPercent then
		t.min, t.max, t.step = smin or 0, smax or 1, step or 0.01
		t.bigStep = step or 0.05
	else
		t.min, t.max, t.step = smin or 1, smax or 100, step or 1
	end
	t.isPercent = isPercent
	t.get = getfuncs(self, func)
	t.set = setfuncs(self, func)
	
	SetState(t, width, disabled, hidden)
	return t
end

--[[
	header (string|boolean) - create header for position options
		- (string) - text displayed in the header
		- true (boolean) - name will be used for header text
		- false (boolean) - no header
--]]
function devapi:NewPosition(name, order, header, func, width, disabled, hidden)
	argcheck(header, "typeof", "string;boolean;nil")
	
	if header == true then header = name end
	
	local t = ShadowOption()
	t.name = function(info)
		local ParentInfo = GetParentInfo(info)
		if header then ParentInfo[info[#info].."Header"] = self:NewHeader(header, order, nil, disabled, hidden) end
		ParentInfo[info[#info].."X"] = self:NewInputNumber("X Value", "Horizontal value for the "..name, order+0.1, func, width, disabled, hidden)
		ParentInfo[info[#info].."Y"] = self:NewInputNumber("Y Value", "Vertical value for the "..name, order+0.2, func, width, disabled, hidden)
		
		t = nil
		ACR:NotifyChange(addonname)
	end
	return t
end

--[[
	devapi:NewPosSliders(...) - create sliders for a frame's position that will update if the frame's anchor or the UI Scale changes
	
	header (string|boolean) - create header for position options
		- (string) - text displayed in the header
		- true (boolean) - name will be used for header text
		- false (boolean) - no header
	frame (string|object|function) - frame to get min/max settings for
		- (string) - frame name (recommended incase frame doesn't exist)
		- (object) - frame itself (only use if frame will always exist)
		- (function) - a function that returns a frame reference or frame name
--]]
function devapi:NewPosSliders(name, order, header, frame, func, width, disabled, hidden)
	argcheck(header, "typeof", "string;boolean;nil")
	argcheck(frame, "typeof", "string;frame;function")
	
	AceEvent.RegisterEvent(devapi, "UI_SCALE_CHANGED", "UpdatePositionOptions", false)
	self.UpdatePositionOptions = devapi.UpdatePositionOptions
	
	if header == true then header = name end
	
	local x = self:NewSlider("Horizontal Position", "Horizontal position for the "..name, order+0.1, nil, nil, 0.1, func, false, width, disabled, hidden)
	local y = self:NewSlider("Vertical Position", "Vertical position for the "..name, order+0.2, nil, nil, 0.1, func, false, width, disabled, hidden)
	x.bigStep = 10
	y.bigStep = 10
	x.set = setfuncs(self, func, function(info, value)
		self:SetDBVar(info, value)
		if func then return end
		
		local f = type(frame) == "function" and frame() or frame
		if type(f) == "string" then
			f = _G[f]
		end
		if not f then return end
		
		local point, parent, rpoint, x, y = f:GetPoint()
		f:SetPoint(point, parent, rpoint, value, y)
	end)
	y.set = setfuncs(self, func, function(info, value)
		self:SetDBVar(info, value)
		if func then return end
		
		local f = type(frame) == "function" and frame() or frame
		if type(f) == "string" then
			f = _G[f]
		end
		if not f then return end
		
		local point, parent, rpoint, x, y = f:GetPoint()
		f:SetPoint(point, parent, rpoint, x, value)
	end)
	
	local t = ShadowOption()
	t.name = function(info)
		t.name = ""
		t = nil
		
		local ParentInfo = GetParentInfo(info)
		if header then ParentInfo[info[#info].."Header"] = self:NewHeader(header, order, nil, disabled, hidden) end
		ParentInfo[info[#info].."X"] = x
		ParentInfo[info[#info].."Y"] = y
		
		UI_Scale_Update[frame] = {x, y}
		self:UpdatePositionOptions(frame)
	end
	return t
end

--[[
--]]
function devapi:NewColor(name, desc, order, func, width, disabled, hidden)
	local t = SetVals("color", name.." Color", order)
	t.desc = descfuncs(self, func, "Choose a color for the "..(desc or name)..".", function(info)
		local r, g, b, a = getColor(self:GetDefaultVal(info))
		return "\nR: "..r.."\nG: "..g.."\nB: "..b.."\nA: "..a
	end)
	t.get = getfuncs(self, func, function(info) return getColor(self:GetDBVar(info))  end)
	t.set = setfuncs(self, func, function(info, ...) setColor(self:GetDBVar(info), ...) end)
	
	t.hasAlpha = true
	
	SetState(t, width, disabled, hidden)
	return t
end

--[[
--]]
function devapi:NewColorNoAlpha(name, desc, order, func, width, disabled, hidden)
	local t = SetVals("color", name.." Color", order)
	t.desc = descfuncs(self, func, "Choose a color for the "..(desc or name)..".", function(info)
		local r, g, b = getColor(self:GetDefaultVal(info))
		return "\nR: "..r.."\nG: "..g.."\nB: "..b
	end)
	t.get = getfuncs(self, func, function(info) local r, g, b = getColor(self:GetDBVar(info)); return r, g, b end)
	t.set = setfuncs(self, func, function(info, r, g, b) setColor(self:GetDBVar(info), r, g, b) end)
	
	t.hasAlpha = false
	
	SetState(t, width, disabled, hidden)
	return t
end

--STILL EXPERIMENTAL
--function devapi:NewFontOptions(name, desc, order, func, width, disabled, hidden)
--	local t = {}
--	t.type, t.order, t.name = "group", order, name
--	t.args = {}
--
--	local fontdesc = function(info)
--		local fonttype = info[#info]
--		if (info[#info] ~= "Font") then fonttype = "Font "..fonttype
--		return "Choose a "..fonttype.." to be used for the "..desc..".\n\nDefault: "..self.db.defaults.profile.Fonts[info[#info-1]][info[#info]]
--	end
--
--	t.args["Size"] = self:NewSlider("Size", "", 1, 1, 40, 1, true, width, disabled, hidden)
--	t.args["Size"].desc = function(info)
--		return "Choose a Font Size to be used for the "..desc..".\n\nDefault: "..self.db.defaults.profile.Fonts[info[#info-1]][info[#info]]
--	end
--
--	--Not using NewColor due to changes in info lookup
--	local color = {}
--	color.type, color.name, color.order, color.hasAlpha = "color", "Color", 2, true
--	color.desc = function(info)
--		local default = self.db.defaults.profile.Fonts[info[#info-1]][info[#info]]
--		return "Choose a Font Color to be used for the "..desc..".\n\nDefault:\nR: "..default.r.."\nG: "..default.g.."\nB: "..default.b.."\nA: "..default.a
--	end
--	color.get = function(info)
--		local c = self.db.profile.Fonts[info[#info-1]][info[#info]]
--		return c.r, c.g, c.b, c.a
--	end
--	color.set = function(info, r, g, b, a)
--		local c = self.db.profile.Fonts[info[#info-1]][info[#info]]
--		return c.r, c.g, c.b, c.a = r, g, b, a
--		if func and type(func) == "function" then func(info, r, g, b, a) end
--	end
--	SetState(color, width, disabled, hidden)
--	t.args["Color"] = color
--
--	t.args["Font"] = self:NewSelect("Font", "", 3, Media:HashTable("font"), "LSM30_Font", true, width, disabled, hidden)
--	t.args["Font"].desc = function(info)
--		return "Choose a Font to be used for the "..desc..".\n\nDefault: "..self.db.defaults.profile.Fonts[info[#info-1]][info[#info]]
--	end
--
--	-- Not using NewSelect due to changes in info lookup
--	local fontflags = {"NONE", "OUTLINE", "THICKOUTLINE", "MONOCHROME"}
--	local flag = {}
--	flag.type, flag.name, flag.order, flag.values = "select", "Flag", 4, fontflags
--	flag.desc = function(info)
--		return "Choose a Font Flag to be used for the "..desc..".\n\nDefault: "..self.db.defaults.profile.Fonts[info[#info-1]][info[#info]]
--	end
--	flag.get = function(info)
--		for k, v in pairs(fontflags) do
--			if self.db.profile.Fonts[info[#info-1]][info[#info]] == v then
--				return k
--			end
--		end
--	end
--	flag.set = function(info, value)
--		local opt = self.db.profile.Fonts[info[#info-1]
--		opt[info[#info] = fontflags[value]
--		if func then func(info, value) end
--	end
--
--	t.args["Flag"] = flag
--
--	t.get = function(info) return self.db.profile.Fonts[info[#info-1]][info[#info]] end
--	t.set = function(info, value)
--		local opt = self.db.profile.Fonts[info[#info-1]]
--		opt[info[#info]] = value
--		if func then func(info, value) end
--	end
--	SetState(t, width, disabled, hidden)
--	return t
--end

--[[
	This function is embeded in any target that calls the ..:NewPosSliders() function.
	
	You can call it no args to update all position options or with the same object you handed to ..:NewPosSliders() to update that set of position options
]]
function devapi:UpdatePositionOptions(specific) -- specific - update specific options
	argcheck(specific, "typeof", "boolean;string;frame;function;nil")
	
	local t = specific and UI_Scale_Update[specific] and {[specific] = true} or UI_Scale_Update
	for frame in pairs(t) do
		local f
		if type(frame) == "function" then
			f = frame()
		else
			f = frame
		end
		if type(f) == "string" then
			f = _G[f]
		end
		
		if f then
			local x, y = unpack(UI_Scale_Update[frame])
			
			x.softMin, x.softMax = getWidthValues(f)
			y.softMin, y.softMax = getHeightValues(f)
			
			x.min, x.max = -10000, 10000
			y.min, y.max = -10000, 10000
		end
	end
	
	ACR:NotifyChange(addonname)
end


-- functions to embed
local mixins = {
	"NewGroup", "NewHeader", "NewDesc",
	"NewToggle", "NewEnable", "NewExecute",
	"NewSelect", "NewMultiSelect",
	"NewInput", "NewInputNumber",
	"NewSlider", "NewPosition", "NewPosSliders",
	"NewColor", "NewColorNoAlpha",
	"NewFontOptions",
	--Internal
	
}

-- Embeds devapi into the target object making the functions from the mixins list available on target:..
--     target - target object to embed devapi in
function devapi:Embed(target)
	for k, v in pairs(mixins) do
		target[v] = self[v]
	end
	self.embeds[target] = true
	return target
end

-- upgrade old embeds
for target in pairs(devapi.embeds) do
	devapi:Embed(target)
end


-- OLD API DOWN HERE.


--[[
---------------------------------
-- ///// OPTION WRAPPERS ///// --
---------------------------------

-- Most of ace wrappers uses the same kind of args, here's a short (and pretty pointless) description of all of them.
		
	#name - string - Name for the option. This is normally the one that appears in the Option Panel.
	#desc - string - A Description for the option. This is what would appear in the tooltip. The Default: note at the bottom of tooltips is added automatically.
	#order - number - A number where it would be placed in the Ace config
	#dbt - table - the db table for the option. Do not add the option itself.
	#option - string - the db option (the rightmost one) for the option. I have to split the rightmost or else Lua will interpret the option as a constant value instead of a table entry.
	#default - table - the default db table for the option. LUI.defaults.profiles...  Again, don't add the rightmost entry, #option will be used there.
	#func - function - additional commands you may want to call when you finish setting the option.
	#width - string - set the width for the ace option. Nil to be regular sized unless noted otherwise.
	#disabled - func/bool - Gives a function or a boolean to determine if the item should be enabled or disabled. ONLY a function can have dynamic disabling.
	#hidden - func/bool - Gives a function or a boolean to determine if the item should be visible or hidden. ONLY a function can have dynamic hiding.
	
	These commands returns a table to be embedded in the options.
--]]

---- Toggle and Toggle Templates.
-- #Desc - If nil, it will use the syntax of "Whether or not to " followed by the #name option.
-- #Width - For toggles, this defaults to Full. You may specify "normal" to revert that.
function LUI:NewToggle(name, desc, order, dbt, option, default, func, width, disabled, hidden)
	local t = {}
	t.type, t.name, t.order = "toggle", name, order
	t.desc = desc or "Whether or not to "..name..".\n\nDefault: "..(default[option] and "Enabled" or "Disabled")
	t.get = function() return dbt[option] end
	if func then
		t.set = function(info, toggle)
			dbt[option] = not dbt[option]
			func(info, toggle)
		end
	else
		t.set = function(info, toggle)
			dbt[option] = not dbt[option]
		end
	end
	width = width or "full"
	SetState(t, width, disabled, hidden)
	return t
end

function LUI:NewEnable(name, order, dbt, width, disabled, hidden)
	local t = {}

	t.order = order or 1
	t.type, t.name = "toggle", "Enable"
	t.desc = "Enables LUI's "..name.." module."
	t.get = function() return dbt.Enable end
	t.set = function() dbt.Enable = not dbt.Enable end

	SetState(t, width, disabled, hidden)
	return t
end

---- Header
function LUI:NewHeader(name, order, width, disabled, hidden)
	local t = {}
--	tcreate = tcreate + 1
	t.type ,t.order, t.name = "header", order, name

	SetState(t, width, disabled, hidden)
	return t
end

function LUI:NewDesc(desc, order, width, disabled, hidden)
	local t = {}
	--tcreate = tcreate + 1
	t.type, t.order, t.name = "description", order, desc
	width = width or "full"
	SetState(t, width, disabled, hidden)
	return t
end

function LUI:NewEmpty(order, width, disabled, hidden)
	return LUI:NewDesc(" ", order, width, disabled, hidden)
end

---- Slider and Slider Templates.
-- #isPercent - boolean, added after w/d/h, this will display the value as a percentage (1 being 100%)
-- #min, #max, #step - numbers, Those are to display the slider values, they default to a range of 1-100, by step of 1.
function LUI:NewSlider(name, desc, order, dbt, option, default, smin, smax, step, func, width, disabled, hidden, isPercent)
	local t = {}
	--tcreate = tcreate + 1
	t.type, t.order, t.name = "range", order, name
	t.desc = desc.."\n\nDefault: "..default[option]
	t.min, t.max, t.step = smin or 1, smax or 100, step or 1
	if isPercent then t.isPercent = true end
	t.get = function() return dbt[option] end
	t.set = function(info, size)
		dbt[option] = size
		if func then func(info, size) end
	end

	SetState(t, width, disabled, hidden)
	return t
end

-- Slider Template that can be used generally for scales. Values will be shown in percentages, and range from 50% to 250%. Going by steps of 5%.
-- #name will be appended by "Size". The #desc is automatically filled , tooltip will be "Select the size of the" followed by the #name.
function LUI:NewScale(name, order, dbt, option, default, func, width, disabled, hidden)
	local tname, tdesc = name.." Size", "Select the size of the "..name:lower().."."
	local tmin, tmax, tstep = 0.5, 2.5, 0.05
	return LUI:NewSlider(tname, tdesc, order, dbt, option, default, tmin, tmax, tstep, func, width, disabled, hidden, true)
end

---- Color
-- There is no #option because #dbt requires a color table, which must have the r, g, b, a values.
-- "Color" will be appended at the end of #name.
-- #desc only needs to be the description of what the color will change itself, a "Choose a color for the" will be automatically added.
function LUI:NewColor(name, desc, order, dbt, default, func, width, disabled, hidden)
	local t = {}
	--tcreate = tcreate + 1
	desc = desc or name
	t.name = name.." Color"
	t.type, t.order, t.hasAlpha = "color", order, true
	t.desc = "Choose a color for the "..desc.."\n\nDefault:\nR: "..default.r.."\nG: "..default.g.."\nB: "..default.b.."\nA: "..default.a
	t.get = function() return dbt.r, dbt.g, dbt.b, dbt.a end

	t.set = function(info, r, g, b, a)
		dbt.r, dbt.g, dbt.b, dbt.a = r, g, b, a
		if func then func(info, r, g, b, a) end
	end

	SetState(t, width, disabled, hidden)
	return t
end

----Color without Alpha
--basically the same as Color, only without Alpha value
function LUI:NewColorNoAlpha(name, desc, order, dbt, default, func, width, disabled, hidden)
	local t = {}
	--tcreate = tcreate + 1
	desc = desc or name
	t.name = name.." Color"
	t.type, t.order, t.hasAlpha = "color", order, false
	t.desc = "Choose a color for the "..desc.."\n\nDefault:\nR: "..default.r.."\nG: "..default.g.."\nB: "..default.b
	t.get = function() return dbt.r, dbt.g, dbt.b end

	t.set = function(info, r, g, b)
		dbt.r, dbt.g, dbt.b = r, g, b
		if func then func(info, r, g, b) end
	end

	SetState(t, width, disabled, hidden)
	return t
end

---- Input and Input Templates
function LUI:NewInput(name, desc, order, dbt, option, default, func, width, disabled, hidden)
	local t = {}
	--tcreate = tcreate + 1
	t.type, t.order = "input", order
	t.name, t.desc = name, desc.."\n\nDefault: "..default[option]
	t.get = function() return dbt[option] end
	t.set = function(info, str)
		dbt[option] = str
		if func then func(info, str) end
	end

	SetState(t, width, disabled, hidden)
	return t
end

--Same thing as an input, except it requires a number.
-- It will always uses the %.1f format unless specified otherwise. This means that it will display only one floating point.
--   This was done because when you use drag commands for example, it gives  you an insane amount of floating points, which are truncated by %.1f.
function LUI:NewInputNumber(name, desc, order, dbt, option, default, func, width, disabled, hidden, iformat)
	local t = {}
--	tcreate = tcreate + 1
	t.type, t.order = "input", order
	t.name, t.desc = name, desc.."\n\nDefault: "..default[option]
	t.validate = IsNumber
	t.get = function()
		if not iformat then return format("%.1f",dbt[option])
		else return format(iformat,dbt[option]) end
	end
	t.set = function(info, num)
		dbt[option] = num
		if func then func(info, num) end
	end
	
	SetState(t, width, disabled, hidden)
	return t
end

--#name for PosX/Y and OffsetX/Y refers to what is going to be changed and displayed in the tooltip.
--The External name will always be "X (or Y) Value" for Position, and "X (or Y) Offset" for the Offset calls.
--The tooltip is automatically filled with "X/Y Value for your", as well as the notes about positive and negative values.
function LUI:NewPosX(name, order, dbt, option, default, func, width, disabled, hidden)
	local tname, tdesc = "X Value", "X Value for your "..name..".\n\nNote:\nPositive Values = right\nNegative Values = left"
	return LUI:NewInputNumber(tname, tdesc, order, dbt, option.."X", default, func, width, disabled, hidden)
end
function LUI:NewPosY(name, order, dbt, option, default, func, width, disabled, hidden)
	local tname, tdesc = "Y Value", "Y Value for your "..name..".\n\nNote:\nPositive Values = up\nNegative Values = down"
	return LUI:NewInputNumber(tname, tdesc, order, dbt, option.."Y", default, func, width, disabled, hidden)
end
function LUI:NewOffsetX(name, order, dbt, option, default, func, width, disabled, hidden)
	local tname, tdesc = "X Offset", "Set the X Offset for your "..name..".\n\nNote:\nPositive Values = right\nNegative Values = left"
	return LUI:NewInputNumber(tname, tdesc, order, dbt, option.."X", default, func, width, disabled, hidden)
end
function LUI:NewOffsetY(name, order, dbt, option, default, func, width, disabled, hidden)
	local tname, tdesc = "Y Offset", "Set the Y Offset for your "..name..".\n\nNote:\nPositive Values = up\nNegative Values = down"
	return LUI:NewInputNumber(tname, tdesc, order, dbt, option.."Y", default, func, width, disabled, hidden)
end

--#name for Height/Width/Padding refers to what is going to be changed and displayed in the tooltip.
--#option: defaults to Height/Width/Padding
function LUI:NewHeight(name, order, dbt, option, default, func, width, disabled, hidden)
	local tname, tdesc = "Height", "Set the Height for your "..name.."."
	local toption = option or "Height"
	return LUI:NewInputNumber(tname, tdesc, order, dbt, toption, default, func, width, disabled, hidden)
end
function LUI:NewWidth(name, order, dbt, option, default, func, width, disabled, hidden)
	local tname, tdesc = "Width", "Set the Width for your "..name.."."
	local toption = option or "Width"
	return LUI:NewInputNumber(tname, tdesc, order, dbt, toption, default, func, width, disabled, hidden)
end

--#name: example: "Healthbar & Powerbar"
function LUI:NewPadding(name, order, dbt, option, default, func, width, disabled, hidden)
	local tname, tdesc = "Padding", "Set the Padding between "..name.."."
	local toption = option or "Padding"
	return LUI:NewInputNumber(tname, tdesc, order, dbt, toption, default, func, width, disabled, hidden)
end

----Select: Creates a dropdown list
--values: table of values choosable
--dcontrol: dialogControl, for example "LSM30_Statusbar"
--special kinds of selects
--the kind of get and set options are determined if theres a dcontrol attribute
function LUI:NewSelect(name, desc, order, values, dcontrol, dbt, option, default, func, width, disabled, hidden)
	local t = {}
	--tcreate = tcreate + 1
	local get, set
	if dcontrol then
		get = function() return dbt[option] end
		set = function(info, select)
			dbt[option] = select
			if func then func(info, select) end
		end
	else
		get = function()
			for k, v in pairs(values) do
				if dbt[option] == v then
					return k
				end
			end
		end
		set = function(info, select)
			dbt[option] = values[select]
			if func then func(info, select) end
		end
	end
	
	t.type, t.order, t.values = "select", order, values
	if dcontrol then t.dialogControl = dcontrol end
	t.name, t.desc = name, desc.."\n\nDefault: "..default[option]
	t.get = get
	t.set = set
	
	SetState(t, width, disabled, hidden)
	return t
end

----Execute: creates a clickable button!
function LUI:NewExecute(name, desc, order, func, width, disabled, hidden)
	local t = {}
	--tcreate = tcreate + 1
	t.name, t.desc, t.order = name, desc, order
	t.func = func
	t.type = "execute"
	
	SetState(t, width, disabled, hidden)
	return t
end


-- SOME FONT BASIC FUNCTIONS AS AN OUTLINE FOR NOW.
-- These will need to be changed an adopted when we find a style we like and a good way to manage.
-- Stuff like passing the font object into these functions for dynamic changes would be nice; however with this complexity everything would need to be references rather than valued.
-- It may be necessary to change database storage of font data so we can reliabiliy reference locations we don't really know exist.
-- I.e. DataBase.Object.Font.[setting] rather than db.Object.Size, db.Object.Font etc.

-- Creates a font flag selector.
function LUI:NewFontFlags(name, order, dbt, defaults, func, width, disabled, hidden)
	local tname = "Font Flag"
	local desc = "Select the font flag to use with your "..name.."'s font."
	local values = { "OUTLINE", "THICKOUTLINE", "MONOCHROME", "NONE" }
	return LUI:NewSelect(tname, desc, order, values, nil, dbt, "Outline", defaults, func, width, disabled, hidden)
end

-- Creates a font selector.
function LUI:NewFontSelect(name, order, dbt, defaults, func, width, disabled, hidden)
	local tname = "Font"
	local desc = "Select the font to use for "..name.."."
	return LUI:NewSelect(tname, desc, order, Media:HashTable("font"), "LSM30_Font", dbt, "Font", defaults, func, width, disabled, hidden)
end

-- Creates a font size slider.
-- name: Name of object that the font size is for.
function LUI:NewFontSize(name, order, dbt, defaults, func, width, disabled, hidden)
	local tname = "Font Size"
	local desc = "Select the font size for "..name.."."
	return LUI:NewSlider(tname, desc, order, dbt, "Size", defaults, 1, 40, 1, func, width, disabled, hidden, false)
end

---- Font: Creates combined font options.	-- Currently gone for GUI Inline option style. This ofcourse can be changed as needed. But this is the easiest way without passing and editing options tables directly.
-- name: Name of object font options are being created for.
-- order: Order for where the options will appear.
function LUI:NewFont(name, order, dbt, defaults, func, disabled, hidden, width)
	local t = {}
	--tcreate = tcreate + 1
	t.name, t.type, t.order, t.guiInline = "Font Settings", "group", order, true
	t.args = {
		FontSize = LUI:NewFontSize(name, 1, dbt, defaults),
		FontColor = LUI:NewColor("Font", name.."'s font.", 2, dbt.Color, defaults.Color),
		FontSelect = LUI:NewFontSelect(name, 3, dbt, defaults),
		FontFlags = LUI:NewFontFlags(name, 4, dbt, defaults),
	}

	SetState(t, width, disabled, hidden)
	return t
end

-------------------------------------
-- ///// END OPTION WRAPPERS ///// --
-------------------------------------
