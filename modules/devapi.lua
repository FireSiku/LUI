--[[
   Project....: LUI NextGenWoWUserInterface
   File.......: Devapi.lua
   Description: Developper's API for LUI Modules
   Version....: 0.1
   Rev Date...: 19/01/11
   
]]

local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local LSM = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists
local LUIHook = LUI:GetModule("LUIHook")
local module = LUI:NewModule("DevAPI", "AceHook-3.0", "AceEvent-3.0")

local db

--localized API for effiency
local tolower = string.lower
local tostring = tostring
local tonumber = tonumber

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

--Local command that validates if it's a number or not.
local function IsNumber(info, num)
	if num == nil or num:trim() == "" then
		return "Please input a number."
	end
	if not tonumber(num) then
		return "Please input a number."
	end
	return true
end

--Local command to handle the width/disable/hidden states of all option wrappers. 
-- The SetState sometimes receive parameters because of how Lua passes tables through functions, which sometimes "Spillover".
-- That is why it's important that every single parameter has a type requirement. Otherwise bad stuff happens. 
local function SetState(t, width, disabled, hidden)
	if width and type(width) == "string" then t.width = width end
	if disabled and type(disabled) == "boolean" then t.disabled = disabled end
	if disabled and type(disabled) == "function" then t.disabled = function() return disabled() end end
	if hidden and type(hidden) == "boolean" then t.hidden = hidden end
	if hidden and type(hidden) == "function" then t.hidden = function() return hidden() end end
end

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

	t.type ,t.order, t.name = "header", order, name

	SetState(t, width, disabled, hidden)
	return t
end

function LUI:NewDesc(desc, order, width, disabled, hidden)
	local t = {}
	
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
	local tname, tdesc = name.." Size", "Select the size of the "..tolower(name).."."
	local tmin, tmax, tstep = 0.5, 2.5, 0.05
	return LUI:NewSlider(tname, tdesc, order, dbt, option, default, tmin, tmax, tstep, func, width, disabled, hidden, true)
end

---- Color
-- There is no #option because #dbt requires a color table, which must have the r, g, b, a values. 
-- "Color" will be appended at the end of #name. 
-- #desc only needs to be the description of what the color will change itself, a "Choose a color for the" will be automatically added.
function LUI:NewColor(name, desc, order, dbt, default, func, width, disabled, hidden)
	local t = {}

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
	return LUI:NewSelect(tname, desc, order, widgetLists.font, "LSM30_Font", dbt, "Font", defaults, func, width, disabled, hidden)
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



--Not having options doesnt means we might not use the database to store things. 
--[[  To Uncomment when we actually use it.
local defaults = {
}

function module:OnInitialize()
   LUI:MergeDefaults(LUI.db.defaults.profile, defaults)
   LUI:RefreshDefaults()
   LUI:Refresh()
   
   self.db = LUI.db.profile
   db = self.db

end

function module:OnEnable()

end --]]