--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: themes.lua
	Description: Themes Module
	Version....: 1.4
	Rev Date...: 24/07/2011 [dd/mm/yyyy]

	Edits:
		v1.0: Loui
		v1.2: Zista
		v1.3: Zista
		v1.4: Zista
]]

-- External references.
local addonname, LUI = ...
local module = LUI:Module("Themes", "AceSerializer-3.0")
local Media = LibStub("LibSharedMedia-3.0")
local ACR = LibStub("AceConfigRegistry-3.0")

local db, dbd

--------------------------------------------------
-- / Local Variables / --
--------------------------------------------------

local ClassArray = {"Death Knight", "Demon Hunter", "Druid", "Hunter", "Mage", "Monk", "Paladin", "Priest", "Rogue", "Shaman", "Warlock", "Warrior"}

--------------------------------------------------
-- / Color Functions / --
--------------------------------------------------

function module:ApplyTheme()
	for name, targetModule in LUI:IterateModules() do
		self:Refresh_Colors(name, targetModule)
	end
end

function module:Refresh_Colors(name, targetModule) -- (name [, targetModule])
	targetModule = targetModule or LUI:Module(name, true)

	if targetModule and targetModule:IsEnabled() and targetModule.SetColors then
		targetModule:SetColors()
	end
end

--------------------------------------------------
-- / Theme Functions / --
--------------------------------------------------

function module:CheckTheme()
	local theme = db.global[db.theme] and db.theme

	if not theme then
		local _, class = UnitClass("player")
		if class == "DEATHKNIGHT" then
			class = "Death Knight"
		elseif class == "DEMONHUNTER" then
			class = "Demon Hunter"
		end

		-- get class theme name
		db.theme = gsub(class, "(%a)([%w_']*)", function(first, rest) return strupper(first)..strlower(rest) end)

		module:LoadTheme()
	else
		for k, v in pairs(db.global[theme]) do
			if not db[k] then
				db[k] = {unpack(v)}
			end
		end
	end
end

function module:LoadTheme(theme)
	theme = theme or db.theme

	for k, v in pairs(db.global[theme]) do
		db[k] = {unpack(v)}
	end
end

function module:SaveTheme(theme)
	-- check if the theme name is valid
	if type(theme) ~= "string" or theme == "" then return end
	-- check if theme name already exists
	if db.global[theme] and not db.global[theme].deleted then
		return StaticPopup_Show("LUI_THEMES_ALREADY_EXISTS")
	end

	-- create the new theme
	db.global[theme] = {}
	for k, v in pairs(db.profile) do
		db.global[theme][k] = v
	end
	-- clear the theme value (its in the db but shouldn't be in the theme's table)
	db.global[theme].theme = nil

	-- set the new theme to be the active one
	db.theme = theme
	-- update the options menu
	ACR:NotifyChange("LUI")
end

function module:DeleteTheme(theme)
	-- check if the theme name is valid (esle use current theme)
	if theme == nil or theme == "" then theme = db.theme end

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
	ACR:NotifyChange("LUI")
end

function module:ImportThemeName(name)
	-- check if the theme name is valid
	if type(name) ~= "string" or name == "" then return end
	-- check if theme name already exists
	if db.global[name] and not db.global[name].deleted then
		return StaticPopup_Show("LUI_THEMES_ALREADY_EXISTS")
	end

	-- show import data popup
	local dialog = StaticPopup_Show("LUI_THEMES_IMPORT_DATA")
	-- hand off theme name
	dialog.data = name
end

function module:ImportThemeData(str, name)
	-- check if str has valid data
	if type(str) ~= "string" or str == "" then return end
	-- check if the theme name is valid
	if type(name) ~= "string" or name == "" then
		return LUI:Print("Invalid Theme Name")
	end
	-- check if theme name already exists
	if db.global[name] and not db.global[name].deleted then
		return StaticPopup_Show("LUI_THEMES_ALREADY_EXISTS")
	end

	-- decrypt import data
	local valid, data = self:Deserialize(str)
	-- check if import data was valid
	if not valid then
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
	ACR:NotifyChange("LUI")
end

function module:ExportTheme(theme)
	-- check if the theme name is valid (esle use current theme)
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
		for _, themeName in pairs(TempThemeArray) do
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
		EditBoxOnExitPressed = function(self) self:GetParent():Hide() end,
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
			ACR:NotifyChange("LUI")
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
end

--------------------------------------------------
-- / Module Functions / --
--------------------------------------------------

module.optionsName = "Colors"
module.order = 2
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
			minimap = {0.80, 0.1, 0.1, 1},
			micromenu = {0.80, 0.1, 0.1},
			micromenu_bg = {0.7, 0, 0, 0.8},
			micromenu_bg2 = {0.1, 0.1, 0.1, 0.8},
			micromenu_btn = {0.80, 0.1, 0.1, 0.8},
			micromenu_btn_hover = {0.80, 0.1, 0.1, 0.8},
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
			minimap = {0.64, 0.19, 0.79, 1},
			micromenu = {0.64, 0.19, 0.79},
			micromenu_bg = {0.48, 0.13, 0.62, 0.8},
			micromenu_bg2 = {0.1, 0.1, 0.1, 0.8},
			micromenu_btn = {0.64, 0.19, 0.79, 0.8},
			micromenu_btn_hover = {0.64, 0.19, 0.79, 0.8},
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
			minimap = {1, 0.44, 0.15, 1},
			micromenu = {1, 0.44, 0.15},
			micromenu_bg = {1, 0.44, 0.15, 0.8},
			micromenu_bg2 = {0, 0, 0, 0.7},
			micromenu_btn = {1, 0.44, 0.15, 0.8},
			micromenu_btn_hover = {1, 0.44, 0.15, 0.8},
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
			minimap = {0.22, 0.91, 0.18, 1},
			micromenu = {0.22, 0.91, 0.18},
			micromenu_bg = {0, 0.61, 0, 0.8},
			micromenu_bg2 = {0, 0, 0, 0.7},
			micromenu_btn = {0.22, 0.91, 0.18, 0.8},
			micromenu_btn_hover = {0.22, 0.91, 0.18, 0.8},
			navi = {0.22, 0.91, 0.18, 0.6},
			navi_hover = {0.22, 0.91, 0.18, 0.4},
			orb = {0.22, 0.91, 0.18},
			orb_cycle = {0.22, 0.91, 0.18, 0.4},
			orb_hover = {0.22, 0.91, 0.18, 0.4},
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
			minimap = {0.12, 0.58, 0.89, 1},
			micromenu = {0.12, 0.58, 0.89},
			micromenu_bg = {0, 0.22, 0.47, 1},
			micromenu_bg2 = {0.12, 0.12, 0.12, 0.6},
			micromenu_btn = {0.12, 0.58, 0.89, 0.8},
			micromenu_btn_hover = {0.12, 0.58, 0.89, 0.8},
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
			minimap = {0.96, 0.21, 0.73, 1},
			micromenu = {0.96, 0.21, 0.73},
			micromenu_bg = {0.66, 0, 0.43, 0.8},
			micromenu_bg2 = {0, 0, 0, 0.7},
			micromenu_btn = {0.96, 0.21, 0.73, 0.8},
			micromenu_btn_hover = {0.96, 0.21, 0.73, 0.8},
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
			minimap = {0.9, 0.9, 0.9, 1},
			micromenu = {0.9, 0.9, 0.9},
			micromenu_bg = {0.6, 0.6, 0.6, 0.8},
			micromenu_bg2 = {0, 0, 0, 0.7},
			micromenu_btn = {0.9, 0.9, 0.9, 0.8},
			micromenu_btn_hover = {0.9, 0.9, 0.9, 0.8},
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
			minimap = {0.95, 0.86, 0.16, 1},
			micromenu = {0.95, 0.86, 0.16},
			micromenu_bg = {0.65, 0.56, 0, 0.8},
			micromenu_bg2 = {0, 0, 0, 1},
			micromenu_btn = {0.95, 0.86, 0.16, 0.8},
			micromenu_btn_hover = {0.95, 0.86, 0.16, 0.8},
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
			minimap = {0.04, 0.39, 0.98, 1},
			micromenu = {0.04, 0.39, 0.98},
			micromenu_bg = {0, 0.09, 0.68, 0.8},
			micromenu_bg2 = {0, 0, 0, 0.8},
			micromenu_btn = {0.04, 0.39, 0.98, 0.8},
			micromenu_btn_hover = {0.04, 0.39, 0.98, 0.8},
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
			minimap = {0.57, 0.22, 1, 1},
			micromenu = {0.57, 0.22, 1},
			micromenu_bg = {0.27, 0, 0.7, 0.8},
			micromenu_bg2 = {0, 0, 0, 0.7},
			micromenu_btn = {0.57, 0.22, 1, 0.8},
			micromenu_btn_hover = {0.57, 0.22, 1, 0.8},
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
			minimap = {1, 0.78, 0.55, 1},
			micromenu = {1, 0.78, 0.55},
			micromenu_bg = {0.7, 0.48, 0.25, 0.8},
			micromenu_bg2 = {0, 0, 0, 0.7},
			micromenu_btn = {1, 0.78, 0.55, 0.8},
			micromenu_btn_hover = {1, 0.78, 0.55, 0.8},
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
			minimap = {0.23, 0.6, 0.63, 1},
			micromenu = {0.4, 0.9, 0.9},
			micromenu_bg = {0.3, 0.6, 0.6, 0.8},
			micromenu_bg2 = {0, 0, 0, 0.7},
			micromenu_btn = {0.23, 0.6, 0.62, 0.8},
			micromenu_btn_hover = {0.23, 0.6, 0.62, 0.8},
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
			minimap = {0.43, 1, 0.43, 1},
			micromenu = {0.9, 0.9, 0.9},
			micromenu_bg = {0.6, 0.6, 0.6, 0.8},
			micromenu_bg2 = {0, 0, 0, 0.7},
			micromenu_btn = {0.63, 0.6, 0.62, 0.8},
			micromenu_btn_hover = {0.63, 0.6, 0.62, 0.8},
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
			minimap = {0.4, 0, 0, 0.7},
			micromenu = {0.7, 0.16, 0.12},
			micromenu_bg = {0.4, 0, 0, 0.8},
			micromenu_bg2 = {0, 0, 0, 0.7},
			micromenu_btn = {0.75, 0.25, 0.20, 0.8},
			micromenu_btn_hover = {0.75, 0.25, 0.20, 0.8},
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
			minimap = {0.33, 0.61, 1, 1},
			micromenu = {0.45, 0.71, 0.98},
			micromenu_bg = {0.15, 0.41, 0.68, 0.8},
			micromenu_bg2 = {0, 0, 0, 0.7},
			micromenu_btn = {0.28, 0.52, 0.85, 0.8},
			micromenu_btn_hover = {0.28, 0.52, 0.85, 0.8},
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
			minimap = {0.71, 0.66, 0.85, 1},
			micromenu = {0.76, 0.72, 1},
			micromenu_bg = {0.46, 0.42, 0.7, 0.8},
			micromenu_bg2 = {0, 0, 0, 0.7},
			micromenu_btn = {0.55, 0.38, 0.85, 0.8},
			micromenu_btn_hover = {0.55, 0.38, 0.85, 0.8},
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
			minimap = {0.85, 0.58, 0.33, 0.2},
			micromenu = {0.85, 0.58, 0.33},
			micromenu_bg = {0.85, 0.58, 0.33, 0.8},
			micromenu_bg2 = {0, 0, 0, 0.7},
			micromenu_btn = {0.85, 0.58, 0.33, 0.8},
			micromenu_btn_hover = {0.85, 0.58, 0.33, 0.8},
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
			minimap = {0.85, 0.35, 0, 0.58},
			micromenu = {1, 0.54, 0.32},
			micromenu_bg = {0.7, 0.24, 0.02, 0.8},
			micromenu_bg2 = {0, 0, 0, 0.7},
			micromenu_btn = {1, 0.43, 0, 0.8},
			micromenu_btn_hover = {1, 0.43, 0, 0.8},
			navi = {0.72, 0.75, 0.72, 0.38},
			navi_hover = {1, 0.43, 0, 0.4},
			orb = {0.8, 0.38, 0.05},
			orb_cycle = {1, 0.43, 0, 0.4},
			orb_hover = {1, 0.43, 0, 0.4},
		},
	},
}

function module:LoadOptions()
	setStaticPopups()

	-- disabled functions
	local function minimapDisabled()
		local Minimap = LUI:Module("Minimap", true)
		return not (Minimap and Minimap:IsEnabled())
	end
	local function chatDisabled()
		local Chat = LUI:Module("Chat", true)
		return not (Chat and Chat:IsEnabled())
	end

	local disabledFuncs = {}
	local function createDisabled(toCheck)
		if not disabledFuncs[toCheck] then
			disabledFuncs[toCheck] = function()
				return not LUI:Module(toCheck, true)
			end
		end

		return disabledFuncs[toCheck]
	end

	-- get/set functions
	local function getValue(info)
		return db[info[#info]]
	end
	local function setValue(info, val)
		db[info[#info]] = val
	end

	local function getColor(info)
		return unpack(db[info[#info]])
	end
	local function setColor(info, r, g, b, a)
		db[info[#info]] = {r, g, b, a}
	end

	local function setColorMicromenu(...)
		setColor(...)
		self:Refresh_Colors("Micromenu")
		self:Refresh_Colors("RaidMenu")
	end

	local setColorFuncs = {}
	local function createSetColor(toRefresh)
		if not setColorFuncs[toRefresh] then
			setColorFuncs[toRefresh] = function(...)
				setColor(...)
				self:Refresh_Colors(toRefresh)
			end
		end

		return setColorFuncs[toRefresh]
	end

	local options = {
		Theme = {
			name = "Theme",
			type = "group",
			order = 1,
			args = {
				SetTheme = {
					name = "Theme",
					desc = "Choose any Theme you prefer Most.",
					type = "select",
					values = self.ThemeArray,
					get = function()
						for k, v in pairs(self.ThemeArray()) do
							if v == db.theme then
								return k
							end
						end
					end,
					set = function(info, val)
						local themeArray = self.ThemeArray()
						if themeArray[val] ~= "" then
							db.theme = themeArray[val]
						end

						self:LoadTheme()
						self:ApplyTheme()
					end,
					order = 1,
				},
				empty = {
					name = " \n ",
					width = "full",
					type = "description",
					order = 2,
				},
				SaveTheme = {
					name = "Save Theme",
					desc = "Save your current color selection as a new theme.",
					type = "execute",
					func = function() StaticPopup_Show("LUI_THEMES_SAVE") end,
					order = 3,
				},
				DeleteTheme = {
					name = "Delete Theme",
					desc = "Delete the active theme.",
					type = "execute",
					func = function() StaticPopup_Show("LUI_THEMES_DELETE") end,
					order = 4,
				},
				empty2 = {
					name = " \n",
					width = "full",
					type = "description",
					order = 5,
				},
				ImportTheme = {
					name = "Import Theme",
					desc = "Import a new Theme into LUI",
					type = "execute",
					func = function() StaticPopup_Show("LUI_THEMES_IMPORT") end,
					order = 6,
				},
				ExportTheme = {
					name = "Export Theme",
					desc = "Export your current theme so you can share it with others.",
					type = "execute",
					func = function() StaticPopup_Show("LUI_THEMES_EXPORT") end,
					order = 7,
				},
				empty3 = {
					name = " \n",
					width = "full",
					type = "description",
					order = 8,
				},
				ResetThemes = {
					name = "Reset Themes",
					desc = "Reset all themes back to defaults",
					type = "execute",
					func = function() StaticPopup_Show("LUI_THEMES_RESET") end,
					order = 9,
				},
			},
		},
		Frames = {
			name = "Frames",
			type = "group",
			disabled = createDisabled("Frames"),
			order = 2,
			args = {
				color_top = {
					name = "Top Texture Color",
					desc = "Choose any Color for your Top Texture",
					type = "color",
					width = "full",
					hasAlpha = true,
					get = getColor,
					set = createSetColor("Frames"),
					order = 1,
				},
				color_bottom = {
					name = "Bottom Texture Color",
					desc = "Choose any Color for your Bottom Texture",
					type = "color",
					width = "full",
					hasAlpha = true,
					get = getColor,
					set = createSetColor("Frames"),
					order = 2,
				},
				minimap = {
					name = "Minimap Color",
					desc = "Choose any Color for your Minimap",
					type = "color",
					width = "full",
					disabled = minimapDisabled,
					hasAlpha = true,
					get = getColor,
					set = createSetColor("Minimap"),
					order = 3,
				},
			},
		},
		Panels = {
			name = "Panels",
			type = "group",
			disabled = createDisabled("Panels"),
			order = 3,
			args = {
				chat = {
					name = "Chatframe Color",
					desc = "Choose any Color for your Chat Panel",
					type = "color",
					width = "full",
					hasAlpha = true,
					get = getColor,
					set = createSetColor("Panels"),
					order = 1,
				},
				chatborder = {
					name = "Chatframe Bordercolor",
					desc = "Choose any Bordercolor for your Chat Panel",
					type = "color",
					width = "full",
					hasAlpha = true,
					get = getColor,
					set = createSetColor("Panels"),
					order = 2,
				},
				chat2 = {
					name = "2nd Chatframe Color",
					desc = "Choose any Color for your 2nd Chat Panel",
					type = "color",
					width = "full",
					hasAlpha = true,
					get = getColor,
					set = createSetColor("Panels"),
					order = 3,
				},
				chat2border = {
					name = "2nd Chatframe Bordercolor",
					desc = "Choose any Bordercolor for your 2nd Chat Panel",
					type = "color",
					width = "full",
					hasAlpha = true,
					get = getColor,
					set = createSetColor("Panels"),
					order = 4,
				},
				tps = {
					name = "Tps Color",
					desc = "Choose any Color for your Threat Panel",
					type = "color",
					width = "full",
					hasAlpha = true,
					get = getColor,
					set = createSetColor("Panels"),
					order = 5,
				},
				tpsborder = {
					name = "Tps Bordercolor",
					desc = "Choose any Bordercolor for your Threat Panel",
					type = "color",
					width = "full",
					hasAlpha = true,
					get = getColor,
					set = createSetColor("Panels"),
					order = 6,
				},
				dps = {
					name = "Dps Color",
					desc = "Choose any Color for your Dps Panel",
					type = "color",
					width = "full",
					hasAlpha = true,
					get = getColor,
					set = createSetColor("Panels"),
					order = 7,
				},
				dpsborder = {
					name = "Dps Bordercolor",
					desc = "Choose any Bordercolor for your Dps Panel",
					type = "color",
					width = "full",
					hasAlpha = true,
					get = getColor,
					set = createSetColor("Panels"),
					order = 8,
				},
				raid = {
					name = "Raid Color",
					desc = "Choose any Color for your Raid Panel",
					type = "color",
					width = "full",
					hasAlpha = true,
					get = getColor,
					set = createSetColor("Panels"),
					order = 9,
				},
				raidborder = {
					name = "Raid Panel Bordercolor",
					desc = "Choose any Bordercolor for your Raid Panel",
					type = "color",
					width = "full",
					hasAlpha = true,
					get = getColor,
					set = createSetColor("Panels"),
					order = 10,
				},
			},
		},
		Bars = {
			name = "Bars",
			type = "group",
			disabled = createDisabled("Bars"),
			order = 4,
			args = {
				bar = {
					name = "Top Bar Texture Color",
					desc = "Choose any Color for your Top Bar Texture",
					type = "color",
					width = "full",
					hasAlpha = true,
					get = getColor,
					set = createSetColor("Bars"),
					order = 1,
				},
				bar2 = {
					name = "Bottom Bar Texture Color",
					desc = "Choose any Color for your Bottom Bar Texture",
					type = "color",
					width = "full",
					hasAlpha = true,
					get = getColor,
					set = createSetColor("Bars"),
					order = 2,
				},
				sidebar = {
					name = "Sidebar Color",
					desc = "Choose any Color for your Sidebar",
					type = "color",
					width = "full",
					hasAlpha = true,
					get = getColor,
					set = createSetColor("Bars"),
					order = 3,
				},
			},
		},
		Navigation = {
			name = "Navigation",
			type = "group",
			disabled = createDisabled("Frames"),
			order = 5,
			args = {
				navi = {
					name = "Top Navigation Button Color",
					desc = "Choose any Color for Top Navigation Buttons",
					type = "color",
					width = "full",
					hasAlpha = true,
					get = getColor,
					set = createSetColor("Frames"),
					order = 1,
				},
				navi_hover = {
					name = "Top Navigation Button Hover Color",
					desc = "Choose any Color for Top Navigation Buttons Hover Effect",
					type = "color",
					width = "full",
					hasAlpha = true,
					get = getColor,
					set = createSetColor("Frames"),
					order = 2,
				},
				orb = {
					name = "Orb Color",
					desc = "Choose any Color for your Orb",
					type = "color",
					width = "full",
					hasAlpha = true,
					get = getColor,
					set = createSetColor("Frames"),
					order = 3,
				},
				orb_cycle = {
					name = "Orb Background Color",
					desc = "Choose any Color for your Orb Background Texture",
					type = "color",
					width = "full",
					hasAlpha = true,
					get = getColor,
					set = createSetColor("Frames"),
					order = 4,
				},
				orb_hover = {
					name = "Orb Hover Color",
					desc = "Choose any Color for your Orb Hover Effect",
					type = "color",
					width = "full",
					hasAlpha = true,
					get = getColor,
					set = createSetColor("Frames"),
					order = 5,
				},
			},
		},
		MicroMenu = {
			name = "MicroMenu",
			type = "group",
			disabled = createDisabled("Micromenu"),
			order = 6,
			args = {
				micromenu = {
					name = "MicroMenu Color",
					desc = "Choose any MicroMenu Color",
					type = "color",
					width = "full",
					hasAlpha = false,
					get = getColor,
					set = setColorMicromenu,
					order = 1,
				},
				micromenu_bg = {
					name = "MicroMenu BG Color",
					desc = "Choose any MicroMenu Background Color.",
					type = "color",
					width = "full",
					hasAlpha = true,
					get = getColor,
					set = setColorMicromenu,
					order = 2,
				},
				micromenu_bg2 = {
					name = "MicroMenu 2nd BG Color",
					desc = "Choose any Second MicroMenu Background Color.",
					type = "color",
					width = "full",
					hasAlpha = true,
					get = getColor,
					set = setColorMicromenu,
					order = 3,
				},
				micromenu_btn = {
					name = "MicroMenu Button Color",
					desc = "Choose any Color for your Micromenu Buttons",
					type = "color",
					width = "full",
					hasAlpha = true,
					get = getColor,
					set = setColorMicromenu,
					order = 4,
				},
				micromenu_btn_hover = {
					name = "MicroMenu Button Hover Color",
					desc = "Choose any Color for your Micromenu Button Hover Effect",
					type = "color",
					width = "full",
					hasAlpha = true,
					get = getColor,
					set = setColorMicromenu,
					order = 5,
				},
			},
		},
		Misc = {
			name = "Misc",
			type = "group",
			order = 7,
			args = {
				editbox = {
					name = "Chat Editbox Color",
					desc = "Choose any Chat Editbox Color.",
					type = "color",
					width = "full",
					disabled = chatDisabled,
					hasAlpha = true,
					get = getColor,
					set = createSetColor("Chat"),
					order = 1,
				},
			},
		},
	}

	return options
end

function module:OnInitialize()
	db, dbd = LUI:NewNamespace(self)

	-- for transition to namespace
	if LUI.db.profile.Colors then
		for k, v in pairs(LUI.db.profile.Colors) do
			db[k] = v
		end
		LUI.db.profile.Colors = nil
	end

	if type(_G.LUI_Themes) == "table" then
		for k, v in pairs(_G.LUI_Themes) do
			if not db.global[k] then
				db.global[k] = v
			end
		end
		_G.LUI_Themes = nil
	end

	self:CheckTheme()
end
