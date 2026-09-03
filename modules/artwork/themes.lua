--[[
	Name........: Themes
	Description.: Built-in and user-defined LUI color themes
]]

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Themes : LUIModule, AceSerializer-3.0
local module = LUI:NewModule("Themes", "LUIDevAPI", "AceSerializer-3.0")
local ACR = LibStub("AceConfigRegistry-3.0")

local db, dbd
local StaticPopup_Hide = _G.StaticPopup_Hide
local tContains = _G.tContains
local strupper = string.upper
local strlen = string.len

--------------------------------------------------
-- / Local Variables / --
--------------------------------------------------

local ClassArray = {"Death Knight", "Demon Hunter", "Druid", "Evoker", "Hunter", "Mage", "Monk", "Paladin", "Priest", "Rogue", "Shaman", "Warlock", "Warrior"}

local MODERN_COLOR_MAP = {
	color_top = {"TopPanel"},
	color_bottom = {"LeftBorderBack", "RightBorderBack"},
	chat = {"Chat"},
	chatborder = {"ChatBorder"},
	tps = {"Tps"},
	tpsborder = {"TpsBorder"},
	dps = {"Dps"},
	dpsborder = {"DpsBorder"},
	raid = {"Raid"},
	raidborder = {"RaidBorder"},
	bar = {"ActionBarTopTexture"},
	sidebar = {"SidebarLeft", "SidebarRight"},
	navi = {"NavButtons"},
	orb = {"Orb"},
}

local MODERN_MODULE_COLOR_MAP = {
	{module = "Micromenu", color = "Micromenu", theme = "micromenu", fallback = "navi"},
	{module = "Micromenu", color = "Background", theme = "micromenu_background", fallback = "chat"},
	{module = "Minimap", color = "Minimap", theme = "minimap", fallback = "navi"},
	{module = "Bags", color = "Background", theme = "bags", fallback = "chat"},
	{module = "Bags", color = "Border", theme = "bagsborder", fallback = "chatborder"},
	{module = "Bags", color = "Search", theme = "bagssearch", fallback = "navi"},
}

local function CopyArrayToColor(source, target)
	if type(source) ~= "table" or type(target) ~= "table"
		or type(source[1]) ~= "number" or type(source[2]) ~= "number" or type(source[3]) ~= "number" then return end
	target.r, target.g, target.b = source[1], source[2], source[3]
	target.a = source[4] or target.a or 1
	target.t = "Individual"
end

local function CopyColorToArray(source)
	if not source then return end
	return {source.r, source.g, source.b, source.a}
end

local function CopyTheme(theme)
	local copy = {}
	for key, value in pairs(theme) do
		if type(key) == "string" and type(value) == "table" then
			copy[key] = {unpack(value)}
		end
	end
	return copy
end

local function ValidateImportedTheme(data)
	if type(data) ~= "table" then return end
	local validated, hasModernColor = {}, false
	for key, value in pairs(data) do
		if type(key) ~= "string" or type(value) ~= "table"
			or type(value[1]) ~= "number" or type(value[2]) ~= "number" or type(value[3]) ~= "number"
			or (value[4] ~= nil and type(value[4]) ~= "number") then
			return
		end
		validated[key] = {
			math.max(0, math.min(1, value[1])),
			math.max(0, math.min(1, value[2])),
			math.max(0, math.min(1, value[3])),
			value[4] and math.max(0, math.min(1, value[4])) or nil,
		}
		if MODERN_COLOR_MAP[key] or key == "editbox" then hasModernColor = true end
	end
	return hasModernColor and validated or nil
end

function module:ValidateImportedTheme(data)
	return ValidateImportedTheme(data)
end

function module:ApplyModernTheme()
	local artwork = LUI:GetModule("Artwork", true)
	if artwork and artwork.db then
		for themeKey, colorKeys in pairs(MODERN_COLOR_MAP) do
			for _, colorKey in ipairs(colorKeys) do
				CopyArrayToColor(db[themeKey], artwork.db.profile.Colors[colorKey])
			end
		end
		if artwork:IsEnabled() then artwork:Refresh() end
	end

	local chat = LUI:GetModule("Chat", true)
	local editBox = chat and chat:GetModule("EditBox", true)
	if editBox and editBox.db and db.editbox then
		CopyArrayToColor(db.editbox, editBox.db.profile.Background.Color)
		if editBox:IsEnabled() then editBox:Refresh() end
	end

	for _, mapping in ipairs(MODERN_MODULE_COLOR_MAP) do
		local target = LUI:GetModule(mapping.module, true)
		local colors = target and target.db and target.db.profile.Colors
		if colors and colors[mapping.color] then
			CopyArrayToColor(db[mapping.theme] or db[mapping.fallback], colors[mapping.color])
		end
	end
end

function module:CaptureModernTheme()
	local artwork = LUI:GetModule("Artwork", true)
	if artwork and artwork.db then
		for themeKey, colorKeys in pairs(MODERN_COLOR_MAP) do
			db[themeKey] = CopyColorToArray(artwork.db.profile.Colors[colorKeys[1]]) or db[themeKey]
		end
	end

	local chat = LUI:GetModule("Chat", true)
	local editBox = chat and chat:GetModule("EditBox", true)
	if editBox and editBox.db then
		db.editbox = CopyColorToArray(editBox.db.profile.Background.Color)
	end

	for _, mapping in ipairs(MODERN_MODULE_COLOR_MAP) do
		local target = LUI:GetModule(mapping.module, true)
		local colors = target and target.db and target.db.profile.Colors
		if colors and colors[mapping.color] then
			db[mapping.theme] = CopyColorToArray(colors[mapping.color])
		end
	end
end

--------------------------------------------------
-- / Color Functions / --
--------------------------------------------------

function module:ApplyTheme()
	self:ApplyModernTheme()
	for name, targetModule in LUI:IterateModules() do
		self:Refresh_Colors(name, targetModule)
	end
end

function module:Refresh_Colors(name, targetModule) -- (name [, targetModule])
	targetModule = targetModule or LUI:GetModule(name)

	if targetModule and targetModule:IsEnabled() then
		if targetModule.SetColors then targetModule:SetColors() end
		if targetModule.RefreshColors then targetModule:RefreshColors() end
	end
end

--------------------------------------------------
-- / Theme Functions / --
--------------------------------------------------

function module:CheckTheme()
	local theme = db.global[db.theme] and db.theme

	if not theme then
		local class = LUI.playerClass
		if LUI.DEATHKNIGHT then
			class = "Death Knight"
		elseif LUI.DEMONHUNTER then
			class = "Demon Hunter"
		end

		-- get class theme name
		db.theme = gsub(class, "(%a)([%w_']*)", function(first, rest) return strupper(first)..strlower(rest) end)

		module:LoadTheme()
	else
		for k, v in pairs(db.global[theme]) do
			if type(v) == "table" and not db[k] then
				db[k] = {unpack(v)}
			end
		end
	end
end

function module:LoadTheme(theme)
	theme = theme or db.theme
	local themeData = db.global[theme]
	if type(themeData) ~= "table" then return end

	-- Older built-in and imported themes do not contain the newer module color
	-- keys. Clear values left by the previous theme so their declared fallback
	-- colors are used instead of stale data.
	for _, mapping in ipairs(MODERN_MODULE_COLOR_MAP) do
		db[mapping.theme] = nil
	end
	for k, v in pairs(themeData) do
		if type(v) == "table" then db[k] = {unpack(v)} end
	end
end

function module:SaveTheme(theme)
	-- check if the theme name is valid
	if type(theme) ~= "string" or theme:trim() == "" then return end
	theme = theme:trim()
	-- check if theme name already exists
	if db.global[theme] and not db.global[theme].deleted then
		return StaticPopup_Show("LUI_THEMES_ALREADY_EXISTS")
	end

	self:CaptureModernTheme()

	-- create the new theme
	db.global[theme] = CopyTheme(db.profile)

	-- set the new theme to be the active one
	db.theme = theme
	-- update the options menu
	ACR:NotifyChange("LUIOptions")
end

function module:DeleteTheme(theme)
	-- Use the active theme when no explicit name was supplied.
	if theme == nil or theme == "" then theme = db.theme end
	if type(theme) ~= "string" or theme == "" or not db.global[theme] then return end

	-- check if theme is a class theme (can't be deleted)
	if tContains(ClassArray, theme) then
		return LUI:Print("CLASS THEMES CAN NOT BE DELETED!!!")
	end

	-- remove theme from table (and stop defaults from repopulating)
	if dbd.global[theme] then
		db.global[theme].deleted = true
	else
		db.global[theme] = nil
	end
	-- set theme to default
	db.theme = ""
	module:CheckTheme()
	module:ApplyTheme()
	-- update the options menu
	ACR:NotifyChange("LUIOptions")
end

function module:ImportThemeName(name)
	-- check if the theme name is valid
	if type(name) ~= "string" or name:trim() == "" then return end
	name = name:trim()
	-- check if theme name already exists
	if db.global[name] and not db.global[name].deleted then
		return StaticPopup_Show("LUI_THEMES_ALREADY_EXISTS")
	end

	-- show import data popup
	local dialog = StaticPopup_Show("LUI_THEMES_IMPORT_DATA")
	-- hand off theme name
	if dialog then dialog.data = name end
end

function module:ImportThemeData(str, name)
	-- check if str has valid data
	if type(str) ~= "string" or str == "" then return end
	-- check if the theme name is valid
	if type(name) ~= "string" or name:trim() == "" then
		return LUI:Print("Invalid Theme Name")
	end
	name = name:trim()
	-- check if theme name already exists
	if db.global[name] and not db.global[name].deleted then
		return StaticPopup_Show("LUI_THEMES_ALREADY_EXISTS")
	end

	-- decrypt import data
	local valid, data = self:Deserialize(str)
	-- check if import data was valid
	data = valid and ValidateImportedTheme(data) or nil
	if not data then
		return LUI:Print("Error importing theme!")
	end

	-- import data into themes table
	db.global[name] = data
	-- set new theme as the active one
	db.theme = name
	module:LoadTheme(name)
	module:ApplyTheme()
	LUI:Print("Successfully imported "..name.." theme!")
	-- update the options menu
	ACR:NotifyChange("LUIOptions")
end

function module:ExportTheme(theme)
	-- Use the active theme when no explicit name was supplied.
	if theme == nil or theme == "" then theme = db.theme end
	-- check if theme exists
	if not db.global[theme] then return StaticPopup_Hide("LUI_THEMES_EXPORT") end

	-- encrypt data for export
	local data = self:Serialize(db.global[theme])
	if not data then return end
	-- breakdown the data into multiple lines (100 chars length each, add a space) for easier posting
	local breakDown
	for i = 1, math.ceil(strlen(data)/100) do
		local part = (strsub(data, (((i-1)*100)+1), (i*100))).." "
		breakDown = (breakDown and breakDown or "")..part
	end
	-- hand the data over to the static popup
	return breakDown
end

--------------------------------------------------
-- / Sorted Table of Themes (for option menu) / --
--------------------------------------------------

function module.ThemeArray() -- no self in this function
	local LUIThemeArray = {}
	local TempThemeArray = {}

	for themeName, theme in pairs(db.global) do
		if theme and not theme.deleted then -- check for false
			table.insert((tContains(ClassArray, themeName) and LUIThemeArray or TempThemeArray), themeName)
		end
	end
	table.sort(LUIThemeArray)
	table.sort(TempThemeArray)

	if #TempThemeArray > 0 then
		table.insert(LUIThemeArray, "")
		for _, themeName in ipairs(TempThemeArray) do
			table.insert(LUIThemeArray, themeName)
		end
	end

	return LUIThemeArray
end

--------------------------------------------------
-- / Static Popups / --
--------------------------------------------------

local function setStaticPopups()
	StaticPopupDialogs["LUI_THEMES_ALREADY_EXISTS"] = {
		preferredIndex = 3,
		text = "That theme already exists.\nPlease choose another name.",
		button1 = "OK",
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		enterClicksFirstButton = true,
	}

	StaticPopupDialogs["LUI_THEMES_SAVE"] = {
		preferredIndex = 3,
		text = 'Enter the name for your new theme',
		button1 = "Save Theme",
		button2 = "Cancel",
		hasEditBox = 1,
		editBoxWidth = 150,
		maxLetters = 20,
		OnAccept = function(self)
			self:Hide()
			module:SaveTheme(self.editBox:GetText())
		end,
		EditBoxOnEnterPressed = function(self)
			self:GetParent():Hide()
			module:SaveTheme(self:GetText())
		end,
		EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}

	StaticPopupDialogs["LUI_THEMES_DELETE"] = {
		preferredIndex = 3,
		text = 'Are you sure you want to delete the current theme?',
		button1 = "Yes",
		button2 = "No",
		OnAccept = function(self) module:DeleteTheme() end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}

	StaticPopupDialogs["LUI_THEMES_IMPORT"] = {
		preferredIndex = 3,
		text = 'Enter a name for your new theme',
		button1 = "Continue",
		button2 = "Cancel",
		hasEditBox = 1,
		editBoxWidth = 150,
		maxLetters = 20,
		OnAccept = function(self)
			self:Hide()
			module:ImportThemeName(self.editBox:GetText())
		end,
		EditBoxOnEnterPressed = function(self)
			self:GetParent():Hide()
			module:ImportThemeName(self:GetText())
		end,
		EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}

	StaticPopupDialogs["LUI_THEMES_IMPORT_DATA"] = {
		preferredIndex = 3,
		text = "Paste (Ctrl + v) the new theme string here:",
		button1 = "Import Theme",
		button2 = "Cancel",
		hasEditBox = 1,
		editBoxWidth = 500,
		maxLetters = 2000,
		OnAccept = function(self, data)
			module:ImportThemeData(self.editBox:GetText(), data)
		end,
		EditBoxOnEnterPressed = function(self, data)
			self:GetParent():Hide()
			module:ImportThemeData(self:GetText(), data)
		end,
		EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}

	StaticPopupDialogs["LUI_THEMES_EXPORT"] = {
		preferredIndex = 3,
		text = "Copy (Ctrl + c) the following to share it with others:",
		button1 = "Close",
		hasEditBox = 1,
		editBoxWidth = 500,
		maxLetters = 2000,
		OnShow = function(self)
			self.editBox:SetText(module:ExportTheme())
			self.editBox:SetFocus()
			self.editBox:HighlightText()
		end,
		EditBoxOnEnterPressed = function(self) self:GetParent():Hide() end,
		EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}

	StaticPopupDialogs["LUI_THEMES_RESET"] = {
		preferredIndex = 3,
		text = "Are you sure you want to reset all your themes?",
		button1 = "Yes",
		button2 = "No",
		OnAccept = function(self)
			local function copyDefaults(tar, src)
				if type(tar) ~= "table" then tar = {} end

				for k, v in pairs(src) do
					if type(v) == "table" then
						tar[k] = copyDefaults(tar[k], v)
					else
						tar[k] = v
					end
				end

				return tar
			end

			wipe(db.global)
			db.global = copyDefaults(db.global, dbd.global)
			db.theme = ""
			module:CheckTheme()
			module:ApplyTheme()
			ACR:NotifyChange("LUIOptions")
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
end

--------------------------------------------------
-- / Module Functions / --
--------------------------------------------------

module.defaults = {
	profile = {
		theme = "",
	},
	global = {
		-- Class Themes
		["Death Knight"] = {
			color_top = {0.80, 0.1, 0.1, 0.5},
			color_bottom = {0.80, 0.1, 0.1, 0.5},
			chat = {0.80, 0.1, 0.1, 0.4},
			chatborder = {0.80, 0.1, 0.1, 0.4},
			chat2 = {0.80, 0.1, 0.1, 0.4},
			chat2border = {0.80, 0.1, 0.1, 0.4},
			editbox = {0.80, 0.1, 0.1, 0.4},
			tps = {0.80, 0.1, 0.1, 0.4},
			tpsborder = {0.80, 0.1, 0.1, 0.4},
			dps = {0.80, 0.1, 0.1, 0.4},
			dpsborder = {0.80, 0.1, 0.1, 0.4},
			raid = {0.80, 0.1, 0.1, 0.4},
			raidborder = {0.80, 0.1, 0.1, 0.4},
			bar = {0.80, 0.1, 0.1, 0.8},
			bar2 = {0.80, 0.1, 0.1, 0.6},
			sidebar = {0.80, 0.1, 0.1, 0.4},
			navi = {0.80, 0.1, 0.1, 0.6},
			navi_hover = {0.80, 0.1, 0.1, 0.4},
			orb = {0.80, 0.1, 0.1},
			orb_cycle = {0.80, 0.1, 0.1, 0.4},
			orb_hover = {0.80, 0.1, 0.1, 0.4},
		},
		["Demon Hunter"] = {
			color_top = {0.64, 0.19, 0.79, 0.5},
			color_bottom = {0.64, 0.19, 0.79, 0.5},
			chat = {0.64, 0.19, 0.79, 0.4},
			chatborder = {0.64, 0.19, 0.79, 0.4},
			chat2 = {0.64, 0.19, 0.79, 0.4},
			chat2border = {0.64, 0.19, 0.79, 0.4},
			editbox = {0.64, 0.19, 0.79, 0.4},
			tps = {0.64, 0.19, 0.79, 0.4},
			tpsborder = {0.64, 0.19, 0.79, 0.4},
			dps = {0.64, 0.19, 0.79, 0.4},
			dpsborder = {0.64, 0.19, 0.79, 0.4},
			raid = {0.64, 0.19, 0.79, 0.4},
			raidborder = {0.64, 0.19, 0.79, 0.4},
			bar = {0.64, 0.19, 0.79, 0.8},
			bar2 = {0.64, 0.19, 0.79, 0.6},
			sidebar = {0.64, 0.19, 0.79, 0.4},
			navi = {0.64, 0.19, 0.79, 0.6},
			navi_hover = {0.64, 0.19, 0.79, 0.4},
			orb = {0.64, 0.19, 0.79},
			orb_cycle = {0.64, 0.19, 0.79, 0.4},
			orb_hover = {0.64, 0.19, 0.79, 0.4},
		},
		["Druid"] = {
			color_top = {1, 0.44, 0.15, 0.5},
			color_bottom = {1, 0.44, 0.15, 0.5},
			chat = {1, 0.44, 0.15, 0.4},
			chatborder = {1, 0.44, 0.15, 0.4},
			chat2 = {1, 0.44, 0.15, 0.4},
			chat2border = {1, 0.44, 0.15, 0.4},
			editbox = {1, 0.44, 0.15, 0.4},
			tps = {1, 0.44, 0.15, 0.4},
			tpsborder = {1, 0.44, 0.15, 0.4},
			dps = {1, 0.44, 0.15, 0.4},
			dpsborder = {1, 0.44, 0.15, 0.4},
			raid = {1, 0.44, 0.15, 0.4},
			raidborder = {1, 0.44, 0.15, 0.4},
			bar = {1, 0.44, 0.15, 0.7},
			bar2 = {1, 0.44, 0.15, 0.6},
			sidebar = {1, 0.44, 0.15, 0.5},
			navi = {1, 0.44, 0.15, 0.6},
			navi_hover = {1, 0.44, 0.15, 0.4},
			orb = {1, 0.44, 0.15},
			orb_cycle = {1, 0.44, 0.15, 0.4},
			orb_hover = {1, 0.44, 0.15, 0.4},
		},
		["Hunter"] = {
			color_top = {0.22, 0.91, 0.18, 0.5},
			color_bottom = {0.22, 0.91, 0.18, 0.5},
			chat = {0.22, 0.91, 0.18, 0.4},
			chatborder = {0.22, 0.91, 0.18, 0.4},
			chat2 = {0.22, 0.91, 0.18, 0.4},
			chat2border = {0.22, 0.91, 0.18, 0.4},
			editbox = {0.22, 0.91, 0.18, 0.4},
			tps = {0.22, 0.91, 0.18, 0.4},
			tpsborder = {0.22, 0.91, 0.18, 0.4},
			dps = {0.22, 0.91, 0.18, 0.4},
			dpsborder = {0.22, 0.91, 0.18, 0.4},
			raid = {0.22, 0.91, 0.18, 0.4},
			raidborder = {0.22, 0.91, 0.18, 0.4},
			bar = {0.22, 0.91, 0.18, 0.7},
			bar2 = {0.22, 0.91, 0.18, 0.6},
			sidebar = {0.22, 0.91, 0.18, 0.4},
			navi = {0.22, 0.91, 0.18, 0.6},
			navi_hover = {0.22, 0.91, 0.18, 0.4},
			orb = {0.22, 0.91, 0.18},
			orb_cycle = {0.22, 0.91, 0.18, 0.4},
			orb_hover = {0.22, 0.91, 0.18, 0.4},
		},
		["Evoker"] = {
			color_top = {0.2, 0.58, 0.5, 0.5},
			color_bottom = {0.2, 0.58, 0.5, 0.5},
			chat = {0.2, 0.58, 0.5, 0.4},
			chatborder = {0.2, 0.58, 0.5, 0.4},
			chat2 = {0.2, 0.58, 0.5, 0.4},
			chat2border = {0.2, 0.58, 0.5, 0.4},
			editbox = {0.2, 0.58, 0.5, 0.4},
			tps = {0.2, 0.58, 0.5, 0.4},
			tpsborder = {0.2, 0.58, 0.5, 0.4},
			dps = {0.2, 0.58, 0.5, 0.4},
			dpsborder = {0.2, 0.58, 0.5, 0.4},
			raid = {0.2, 0.58, 0.5, 0.4},
			raidborder = {0.2, 0.58, 0.5, 0.4},
			bar = {0.2, 0.58, 0.5, 0.8},
			bar2 = {0.2, 0.58, 0.5, 0.6},
			sidebar = {0.2, 0.58, 0.5, 0.4},
			navi = {0.2, 0.58, 0.5,  0.6},
			navi_hover = {0.2, 0.58, 0.5, 0.4},
			orb = {0.2, 0.58, 0.5,},
			orb_cycle = {0.2, 0.58, 0.5, 0.4},
			orb_hover = {0.2, 0.58, 0.5, 0.4},
		},
		["Mage"] = {
			color_top = {0.12, 0.58, 0.89, 0.5},
			color_bottom = {0.12, 0.58, 0.89, 0.5},
			chat = {0.12, 0.58, 0.89, 0.4},
			chatborder = {0.12, 0.58, 0.89, 0.4},
			chat2 = {0.12, 0.58, 0.89, 0.4},
			chat2border = {0.12, 0.58, 0.89, 0.4},
			editbox = {0.12, 0.58, 0.89, 0.4},
			tps = {0.12, 0.58, 0.89, 0.4},
			tpsborder = {0.12, 0.58, 0.89, 0.4},
			dps = {0.12, 0.58, 0.89, 0.4},
			dpsborder = {0.12, 0.58, 0.89, 0.4},
			raid = {0.12, 0.58, 0.89, 0.4},
			raidborder = {0.12, 0.58, 0.89, 0.4},
			bar = {0.12, 0.58, 0.89, 0.8},
			bar2 = {0.12, 0.58, 0.89, 0.6},
			sidebar = {0.12, 0.58, 0.89, 0.4},
			navi = {0.12, 0.58, 0.89, 0.6},
			navi_hover = {0.12, 0.58, 0.89, 0.4},
			orb = {0.12, 0.58, 0.89},
			orb_cycle = {0.12, 0.58, 0.89, 0.4},
			orb_hover = {0.12, 0.58, 0.89, 0.4},
		},
		["Paladin"] = {
			color_top = {0.96, 0.21, 0.73, 0.5},
			color_bottom = {0.96, 0.21, 0.73, 0.5},
			chat = {0.96, 0.21, 0.73, 0.4},
			chatborder = {0.96, 0.21, 0.73, 0.4},
			chat2 = {0.96, 0.21, 0.73, 0.4},
			chat2border = {0.96, 0.21, 0.73, 0.4},
			editbox = {0.96, 0.21, 0.73, 0.4},
			tps = {0.96, 0.21, 0.73, 0.4},
			tpsborder = {0.96, 0.21, 0.73, 0.4},
			dps = {0.96, 0.21, 0.73, 0.4},
			dpsborder = {0.96, 0.21, 0.73, 0.4},
			raid = {0.96, 0.21, 0.73, 0.4},
			raidborder = {0.96, 0.21, 0.73, 0.4},
			bar = {0.96, 0.21, 0.73, 0.7},
			bar2 = {0.96, 0.21, 0.73, 0.6},
			sidebar = {0.96, 0.21, 0.73, 0.4},
			navi = {0.96, 0.21, 0.73, 0.6},
			navi_hover = {0.96, 0.21, 0.73, 0.4},
			orb = {0.96, 0.21, 0.73},
			orb_cycle = {0.96, 0.21, 0.73, 0.4},
			orb_hover = {0.96, 0.21, 0.73, 0.4},
		},
		["Priest"] = {
			color_top = {0.9, 0.9, 0.9, 0.5},
			color_bottom = {0.9, 0.9, 0.9, 0.5},
			chat = {0.9, 0.9, 0.9, 0.4},
			chatborder = {0.9, 0.9, 0.9, 0.4},
			chat2 = {0.9, 0.9, 0.9, 0.4},
			chat2border = {0.9, 0.9, 0.9, 0.4},
			editbox = {0.9, 0.9, 0.9, 0.4},
			tps = {0.9, 0.9, 0.9, 0.4},
			tpsborder = {0.9, 0.9, 0.9, 0.4},
			dps = {0.9, 0.9, 0.9, 0.4},
			dpsborder = {0.9, 0.9, 0.9, 0.4},
			raid = {0.9, 0.9, 0.9, 0.4},
			raidborder = {0.9, 0.9, 0.9, 0.4},
			bar = {0.9, 0.9, 0.9, 0.7},
			bar2 = {0.9, 0.9, 0.9, 0.6},
			sidebar = {0.9, 0.9, 0.9, 0.4},
			navi = {0.9, 0.9, 0.9, 0.6},
			navi_hover = {0.9, 0.9, 0.9, 0.4},
			orb = {0.9, 0.9, 0.9},
			orb_cycle = {0.9, 0.9, 0.9, 0.4},
			orb_hover = {0.9, 0.9, 0.9, 0.4},
		},
		["Rogue"] = {
			color_top = {0.95, 0.86, 0.16, 0.5},
			color_bottom = {0.95, 0.86, 0.16, 0.5},
			chat = {0.95, 0.86, 0.16, 0.4},
			chatborder = {0.95, 0.86, 0.16, 0.4},
			chat2 = {0.95, 0.86, 0.16, 0.4},
			chat2border = {0.95, 0.86, 0.16, 0.4},
			editbox = {0.95, 0.86, 0.16, 0.4},
			tps = {0.95, 0.86, 0.16, 0.4},
			tpsborder = {0.95, 0.86, 0.16, 0.4},
			dps = {0.95, 0.86, 0.16, 0.4},
			dpsborder = {0.95, 0.86, 0.16, 0.4},
			raid = {0.95, 0.86, 0.16, 0.4},
			raidborder = {0.95, 0.86, 0.16, 0.4},
			bar = {0.95, 0.86, 0.16, 0.7},
			bar2 = {0.95, 0.86, 0.16, 0.5},
			sidebar = {0.95, 0.86, 0.16, 0.4},
			navi = {0.95, 0.86, 0.16, 0.6},
			navi_hover = {0.95, 0.86, 0.16, 0.4},
			orb = {0.95, 0.86, 0.16},
			orb_cycle = {0.95, 0.86, 0.16, 0.4},
			orb_hover = {0.95, 0.86, 0.16, 0.4},
		},
		["Shaman"] = {
			color_top = {0.04, 0.39, 0.98, 0.5},
			color_bottom = {0.04, 0.39, 0.98, 0.5},
			chat = {0.04, 0.39, 0.98, 0.4},
			chatborder = {0.04, 0.39, 0.98, 0.4},
			chat2 = {0.04, 0.39, 0.98, 0.4},
			chat2border = {0.04, 0.39, 0.98, 0.4},
			editbox = {0.04, 0.39, 0.98, 0.4},
			tps = {0.04, 0.39, 0.98, 0.4},
			tpsborder = {0.04, 0.39, 0.98, 0.4},
			dps = {0.04, 0.39, 0.98, 0.4},
			dpsborder = {0.04, 0.39, 0.98, 0.4},
			raid = {0.04, 0.39, 0.98, 0.4},
			raidborder = {0.04, 0.39, 0.98, 0.4},
			bar = {0.04, 0.39, 0.98, 0.7},
			bar2 = {0.04, 0.39, 0.98, 0.6},
			sidebar = {0.04, 0.39, 0.98, 0.4},
			navi = {0.04, 0.39, 0.98, 0.6},
			navi_hover = {0.04, 0.39, 0.98, 0.4},
			orb = {0.04, 0.39, 0.98},
			orb_cycle = {0.04, 0.39, 0.98, 0.4},
			orb_hover = {0.04, 0.39, 0.98, 0.4},
		},
		["Warlock"] = {
			color_top = {0.57, 0.22, 1, 0.5},
			color_bottom = {0.57, 0.22, 1, 0.5},
			chat = {0.57, 0.22, 1, 0.4},
			chatborder = {0.57, 0.22, 1, 0.4},
			chat2 = {0.57, 0.22, 1, 0.4},
			chat2border = {0.57, 0.22, 1, 0.4},
			editbox = {0.57, 0.22, 1, 0.4},
			tps = {0.57, 0.22, 1, 0.4},
			tpsborder = {0.57, 0.22, 1, 0.4},
			dps = {0.57, 0.22, 1, 0.4},
			dpsborder = {0.57, 0.22, 1, 0.4},
			raid = {0.57, 0.22, 1, 0.4},
			raidborder = {0.57, 0.22, 1, 0.4},
			bar = {0.57, 0.22, 1, 0.7},
			bar2 = {0.57, 0.22, 1, 0.5},
			sidebar = {0.57, 0.22, 1, 0.4},
			navi = {0.57, 0.22, 1, 0.6},
			navi_hover = {0.57, 0.22, 1, 0.4},
			orb = {0.57, 0.22, 1},
			orb_cycle = {0.57, 0.22, 1, 0.4},
			orb_hover = {0.57, 0.22, 1, 0.4},
		},
		["Warrior"] = {
			color_top = {1, 0.78, 0.55, 0.55},
			color_bottom = {1, 0.78, 0.55, 0.55},
			chat = {1, 0.78, 0.55, 0.4},
			chatborder = {1, 0.78, 0.55, 0.4},
			chat2 = {1, 0.78, 0.55, 0.4},
			chat2border = {1, 0.78, 0.55, 0.4},
			editbox = {1, 0.78, 0.55, 0.4},
			tps = {1, 0.78, 0.55, 0.4},
			tpsborder = {1, 0.78, 0.55, 0.4},
			dps = {1, 0.78, 0.55, 0.4},
			dpsborder = {1, 0.78, 0.55, 0.4},
			raid = {1, 0.78, 0.55, 0.4},
			raidborder = {1, 0.78, 0.55, 0.4},
			bar = {1, 0.78, 0.55, 0.7},
			bar2 = {1, 0.78, 0.55, 0.6},
			sidebar = {1, 0.78, 0.55, 0.5},
			navi = {1, 0.78, 0.55, 0.6},
			navi_hover = {1, 0.78, 0.55, 0.4},
			orb = {1, 0.78, 0.55},
			orb_cycle = {1, 0.78, 0.55, 0.4},
			orb_hover = {1, 0.78, 0.55, 0.4},
		},
		["Monk"] = {
			color_top = {0.33, 0.6, 0.62, 0.65},
			color_bottom = {0.33, 0.6, 0.62, 0.65},
			chat = {0.11, 0.67, 0.63, 0.4},
			chatborder = {0.11, 0.67, 0.63, 0.4},
			chat2 = {0.11, 0.67, 0.63, 0.4},
			chat2border = {0.11, 0.67, 0.63, 0.4},
			editbox = {0.11, 0.67, 0.63, 0.4},
			tps = {0.11, 0.67, 0.63, 0.4},
			tpsborder = {0.11, 0.67, 0.63, 0.4},
			dps = {0.11, 0.67, 0.63, 0.4},
			dpsborder = {0.11, 0.67, 0.63, 0.4},
			raid = {0.11, 0.67, 0.63, 0.4},
			raidborder = {0.11, 0.67, 0.63, 0.4},
			bar = {0.11, 0.67, 0.63, 0.7},
			bar2 = {0.11, 0.67, 0.63, 0.6},
			sidebar = {0.2, 0.6, 0.6, 0.5},
			navi = {0.38, 0.75, 0, 0.76},
			navi_hover = {0.43, 0.8, 0.82, 0.65},
			orb = {0.28, 0.8, 0.76},
			orb_cycle = {0.33, 0.6, 0.62, 0.65},
			orb_hover = {0.33, 0.6, 0.62, 0.65},
		},
		-- Additional Themes
		["Absinth"] = {
			color_top = {0.63, 0.6, 0.62, 0.65},
			color_bottom = {0.63, 0.6, 0.62, 0.65},
			chat = {0.11, 0.67, 0.13, 0.4},
			chatborder = {0.11, 0.67, 0.13, 0.4},
			chat2 = {0.11, 0.67, 0.13, 0.4},
			chat2border = {0.11, 0.67, 0.13, 0.4},
			editbox = {0.11, 0.67, 0.13, 0.4},
			tps = {0.11, 0.67, 0.13, 0.4},
			tpsborder = {0.11, 0.67, 0.13, 0.4},
			dps = {0.11, 0.67, 0.13, 0.4},
			dpsborder = {0.11, 0.67, 0.13, 0.4},
			raid = {0.11, 0.67, 0.13, 0.4},
			raidborder = {0.11, 0.67, 0.13, 0.4},
			bar = {0, 0, 0, 0.7},
			bar2 = {0, 0, 0, 0.6},
			sidebar = {0.6, 0.6, 0.6, 0.5},
			navi = {0.38, 0.85, 0, 0.26},
			navi_hover = {0.63, 0.6, 0.62, 0.65},
			orb = {0.28, 0.8, 0.36},
			orb_cycle = {0.63, 0.6, 0.62, 0.65},
			orb_hover = {0.63, 0.6, 0.62, 0.65},
		},
		["Bloodprince"] = {
			color_top = {0.75, 0.25, 0.20, 0.6},
			color_bottom = {0.75, 0.25, 0.20, 0.6},
			chat = {0, 0, 0, 0.45},
			chatborder = {0, 0, 0, 0.45},
			chat2 = {0, 0, 0, 0.45},
			chat2border = {0, 0, 0, 0.45},
			editbox = {0, 0, 0, 0.45},
			tps = {0, 0, 0, 0.45},
			tpsborder = {0, 0, 0, 0.45},
			dps = {0, 0, 0, 0.45},
			dpsborder = {0, 0, 0, 0.45},
			raid = {0, 0, 0, 0.45},
			raidborder = {0, 0, 0, 0.45},
			bar = {0, 0, 0, 0.7},
			bar2 = {0, 0, 0, 0.6},
			sidebar = {0.75, 0.25, 0.20, 0.5},
			navi = {0.3, 0.05, 0.02, 1},
			navi_hover = {0.75, 0.25, 0.20, 0.6},
			orb = {0.71, 0.33, 0.27},
			orb_cycle = {0.75, 0.25, 0.20, 0.6},
			orb_hover = {0.75, 0.25, 0.20, 0.6},
		},
		["Deep Freeze"] = {
			color_top = {0.28, 0.52, 0.85, 0.65},
			color_bottom = {0.28, 0.52, 0.85, 0.65},
			chat = {0.28, 0.52, 0.85, 0.46},
			chatborder = {0.28, 0.52, 0.85, 0.46},
			chat2 = {0.28, 0.52, 0.85, 0.46},
			chat2border = {0.28, 0.52, 0.85, 0.46},
			editbox = {0.28, 0.52, 0.85, 0.46},
			tps = {0.28, 0.52, 0.85, 0.46},
			tpsborder = {0.28, 0.52, 0.85, 0.46},
			dps = {0.28, 0.52, 0.85, 0.46},
			dpsborder = {0.28, 0.52, 0.85, 0.46},
			raid = {0.28, 0.52, 0.85, 0.46},
			raidborder = {0.28, 0.52, 0.85, 0.46},
			bar = {0.33, 0.61, 1, 0.7},
			bar2 = {0.33, 0.61, 1, 0.5},
			sidebar = {0.28, 0.52, 0.85, 0.55},
			navi = {0.28, 0.52, 0.85, 0.63},
			navi_hover = {0.28, 0.52, 0.85, 0.65},
			orb = {0.44, 0.60, 0.80},
			orb_cycle = {0.28, 0.52, 0.85, 0.65},
			orb_hover = {0.28, 0.52, 0.85, 0.65},
		},
		["Demonic Pact"] = {
			color_top = {0.55, 0.38, 0.85, 0.55},
			color_bottom = {0.55, 0.38, 0.85, 0.55},
			chat = {1, 1, 1, 0.27},
			chatborder = {1, 1, 1, 0.27},
			chat2 = {1, 1, 1, 0.27},
			chat2border = {1, 1, 1, 0.27},
			editbox = {1, 1, 1, 0.27},
			tps = {1, 1, 1, 0.27},
			tpsborder = {1, 1, 1, 0.27},
			dps = {1, 1, 1, 0.27},
			dpsborder = {1, 1, 1, 0.27},
			raid = {1, 1, 1, 0.27},
			raidborder = {1, 1, 1, 0.27},
			bar = {0.53, 0.48, 0.9, 0.8},
			bar2 = {0.53, 0.48, 0.9, 0.7},
			sidebar = {0.53, 0.48, 0.9, 0.5},
			navi = {0.45, 0.32, 0.83, 0.26},
			navi_hover = {0.55, 0.38, 0.85, 0.45},
			orb = {0.29, 0.25, 0.31},
			orb_cycle = {0.55, 0.38, 0.85, 0.45},
			orb_hover = {0.55, 0.38, 0.85, 0.45},
		},
		["Goldenboy"] = {
			color_top = {0.85, 0.58, 0.33, 0.73},
			color_bottom = {0.85, 0.58, 0.33, 0.73},
			chat = {0, 0, 0, 0.45},
			chatborder = {0, 0, 0, 0.45},
			chat2 = {0, 0, 0, 0.45},
			chat2border = {0, 0, 0, 0.45},
			editbox = {0, 0, 0, 0.45},
			tps = {0, 0, 0, 0.45},
			tpsborder = {0, 0, 0, 0.45},
			dps = {0, 0, 0, 0.45},
			dpsborder = {0, 0, 0, 0.45},
			raid = {0, 0, 0, 0.45},
			raidborder = {0, 0, 0, 0.45},
			bar = {0.85, 0.58, 0.33, 0.75},
			bar2 = {0.85, 0.58, 0.33, 0.65},
			sidebar = {0.85, 0.58, 0.33, 0.5},
			navi = {0.02, 0.02, 0.02, 1},
			navi_hover = {0.85, 0.58, 0.33, 0.73},
			orb = {0.85, 0.58, 0.33},
			orb_cycle = {0.85, 0.58, 0.33, 0.73},
			orb_hover = {0.85, 0.58, 0.33, 0.73},
		},
		["Orangemarmalade"] = {
			color_top = {1, 0.43, 0, 0.55},
			color_bottom = {1, 0.43, 0, 0.55},
			chat = {0, 0, 0, 0.83},
			chatborder = {0, 0, 0, 0.86},
			chat2 = {0, 0, 0, 0.83},
			chat2border = {0, 0, 0, 0.86},
			editbox = {0, 0, 0, 0.5},
			tps = {0, 0, 0, 0.83},
			tpsborder = {0, 0, 0, 0.86},
			dps = {0, 0, 0, 0.83},
			dpsborder = {0, 0, 0, 0.86},
			raid = {0, 0, 0, 0.83},
			raidborder = {0, 0, 0, 0.86},
			bar = {1, 0.48, 0, 0.81},
			bar2 = {1, 0.48, 0, 0.81},
			sidebar = {1, 0.48, 0, 0.5},
			navi = {0.72, 0.75, 0.72, 0.38},
			navi_hover = {1, 0.43, 0, 0.4},
			orb = {0.8, 0.38, 0.05},
			orb_cycle = {1, 0.43, 0, 0.4},
			orb_hover = {1, 0.43, 0, 0.4},
		},
	},
}

function module:OnInitialize()
	db, dbd = LUI:NewNamespace(self)
	setStaticPopups()

	-- Migrate profiles created before Themes used its own namespace.
	if LUI.db.profile.Colors then
		for k, v in pairs(LUI.db.profile.Colors) do
			db[k] = v
		end
		LUI.db.profile.Colors = nil
	end

	self:CheckTheme()
end

function module:OnEnable()
	LUI.Profiler.TraceScope(module, "Themes", "LUI", 2)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
		self:ApplyTheme()
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	end)
end
