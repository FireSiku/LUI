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

local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local module = LUI:NewModule("Themes")
local LSM = LibStub("LibSharedMedia-3.0")
local ACR = LibStub("AceConfigRegistry-3.0")

local version = 1.4
local db

--------------------------------------------------
-- / Local Variables / --
--------------------------------------------------

local importThemeName

local ClassArray = {"Death Knight", "Druid", "Hunter", "Mage", "Paladin", "Priest", "Rogue", "Shaman", "Warlock", "Warrior"}

local colorSets = {
	"color_top",
	"color_bottom",
	"chat",
	"chatborder",
	"chat2",
	"chat2border",
	"editbox",
	"tps",
	"tpsborder",
	"dps",
	"dpsborder",
	"raid",
	"raidborder",
	"bar",
	"bar2",
	"sidebar",
	"minimap",
	"micromenu",
	"micromenu_bg",
	"micromenu_bg2",
	"micromenu_btn",
	"micromenu_btn_hover",
	"navi",
	"navi_hover",
	"orb",
	"orb_cycle",
	"orb_hover",
}

local themes = {
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
}

--------------------------------------------------
-- / Color Functions / --
--------------------------------------------------

function module:ApplyTheme()
	for name, targetModule in LUI:IterateModules() do
		self:Refresh_Colors(name, targetModule)
	end
end

function module:Refresh_Colors(name, targetModule) -- (name [, targetModule])
	targetModule = targetModule or LUI:GetModule(name, true)
	
	if targetModule and targetModule:IsEnabled() then
		if self["Refresh_"..name] then
			self["Refresh_"..name](self)
		elseif targetModule.SetColors then
			targetModule:SetColors()
		end
	end
end

function module:Refresh_Forte() -- disabled for now (forces lui color even if disabled)
	-- if LUI:GetModule("Panels", true) then
		-- local Forte = LUI:GetModule("Forte", true)
		-- if Forte and Forte.db.profile.Enable then
			-- Forte:SetColors()
		-- end
	-- end
end

function module:Refresh_Panels()
	local Panels = LUI:GetModule("Panels")
	Panels:SetChatBackground()
	Panels:SetTpsBackground()
	Panels:SetDpsBackground()
	Panels:SetRaidBackground()
end

function module:Refresh_Frames()
	local Frames = LUI:GetModule("Frames")
	Frames:SetNavigationHoverColors()
	Frames:SetNavigationColors()
	Frames:SetTopInfoColors()
	Frames:SetBottomInfoColors()
	Frames:SetOrbCycleColor()
	Frames:SetOrbHoverColor()
end

function module:Refresh_Orb()
	LUI:GetModule("Orb"):SetOrbColor()
end

function module:Refresh_Bars()
	local Bars = LUI:GetModule("Bars")
	Bars:SetSidebarColors()
	Bars:SetBarColors()
end

--------------------------------------------------
-- / Theme Functions / --
--------------------------------------------------

function module:CheckTheme()
	local theme = LUI_Themes[db.profile.theme] and db.profile.theme
	
	if not theme then
		local _, class = UnitClass("player")
		if class == "DEATHKNIGHT" then
			class = "Death Knight"
		end
		
		-- get class theme name
		local function classTheme(first, rest)
			return strupper(first)..strlower(rest)
		end
		db.profile.theme = gsub(class, "(%a)([%w_']*)", classTheme)
		
		module:LoadTheme()
	else
		for _, v in pairs(colorSets) do
			if not db.profile[v] then
				db.profile[v] = LUI_Themes[db.profile.theme][v]
			end
		end
	end
end

function module:LoadTheme(theme) --
	theme = theme or db.profile.theme

	if LUI_Themes[theme].color_top then
		db.profile.color_top = {unpack(LUI_Themes[theme].color_top)}
	end
	
	if LUI_Themes[theme].color_bottom then
		db.profile.color_bottom = {unpack(LUI_Themes[theme].color_bottom)}
	end
	
	if LUI_Themes[theme].chat then
		db.profile.chat = {unpack(LUI_Themes[theme].chat)}
	end
	
	if LUI_Themes[theme].chatborder then
		db.profile.chatborder = {unpack(LUI_Themes[theme].chatborder)}
	end
	
	if LUI_Themes[theme].chat2 then
		db.profile.chat2 = {unpack(LUI_Themes[theme].chat2)}
	end
	
	if LUI_Themes[theme].chat2border then
		db.profile.chat2border = {unpack(LUI_Themes[theme].chat2border)}
	end
	
	if LUI_Themes[theme].editbox then
		db.profile.editbox = {unpack(LUI_Themes[theme].editbox)}
	end
	
	if LUI_Themes[theme].tps then
		db.profile.tps = {unpack(LUI_Themes[theme].tps)}
	end
	
	if LUI_Themes[theme].tpsborder then
		db.profile.tpsborder = {unpack(LUI_Themes[theme].tpsborder)}
	end
	
	if LUI_Themes[theme].dps then
		db.profile.dps = {unpack(LUI_Themes[theme].dps)}
	end
	
	if LUI_Themes[theme].dpsborder then
		db.profile.dpsborder = {unpack(LUI_Themes[theme].dpsborder)}
	end
	
	if LUI_Themes[theme].raid then
		db.profile.raid = {unpack(LUI_Themes[theme].raid)}
	end
	
	if LUI_Themes[theme].raidborder then
		db.profile.raidborder = {unpack(LUI_Themes[theme].raidborder)}
	end
	
	if LUI_Themes[theme].bar then
		db.profile.bar = {unpack(LUI_Themes[theme].bar)}
	end
	
	if LUI_Themes[theme].bar2 then
		db.profile.bar2 = {unpack(LUI_Themes[theme].bar2)}
	end
	
	if LUI_Themes[theme].sidebar then
		db.profile.sidebar = {unpack(LUI_Themes[theme].sidebar)}
	end
	
	if LUI_Themes[theme].minimap then
		db.profile.minimap = {unpack(LUI_Themes[theme].minimap)}
	end
	
	if LUI_Themes[theme].micromenu then
		db.profile.micromenu = {unpack(LUI_Themes[theme].micromenu)}
	end
	
	if LUI_Themes[theme].micromenu_bg then
		db.profile.micromenu_bg = {unpack(LUI_Themes[theme].micromenu_bg)}
	end
	
	if LUI_Themes[theme].micromenu_bg2 then
		db.profile.micromenu_bg2 = {unpack(LUI_Themes[theme].micromenu_bg2)}
	end
	
	if LUI_Themes[theme].micromenu_btn then
		db.profile.micromenu_btn = {unpack(LUI_Themes[theme].micromenu_btn)}
	end

	if LUI_Themes[theme].micromenu_btn_hover then
		db.profile.micromenu_btn_hover = {unpack(LUI_Themes[theme].micromenu_btn_hover)}
	end
	
	if LUI_Themes[theme].navi then
		db.profile.navi = {unpack(LUI_Themes[theme].navi)}
	end
	
	if LUI_Themes[theme].navi_hover then
		db.profile.navi_hover = {unpack(LUI_Themes[theme].navi_hover)}
	end
	
	if LUI_Themes[theme].orb then
		db.profile.orb = {unpack(LUI_Themes[theme].orb)}
	end
	
	if LUI_Themes[theme].orb_cycle then
		db.profile.orb_cycle = {unpack(LUI_Themes[theme].orb_cycle)}
	end
	
	if LUI_Themes[theme].orb_hover then	
		db.profile.orb_hover = {unpack(LUI_Themes[theme].orb_hover)}
	end
end

function module:SaveTheme(theme) --
	if theme == "" or theme == nil then return end
	if LUI_Themes[theme] ~= nil then StaticPopup_Show("LUI_THEMES_ALREADY_EXISTS") return end
	
	LUI_Themes[theme] = {
		color_top = {unpack(db.profile.color_top)},
		color_bottom = {unpack(db.profile.color_bottom)},
		chat = {unpack(db.profile.chat)},
		chatborder = {unpack(db.profile.chatborder)},
		chat2 = {unpack(db.profile.chat2)},
		chat2border = {unpack(db.profile.chat2border)},
		editbox = {unpack(db.profile.editbox)},
		tps = {unpack(db.profile.tps)},
		tpsborder = {unpack(db.profile.tpsborder)},
		dps = {unpack(db.profile.dps)},
		dpsborder = {unpack(db.profile.dpsborder)},
		raid = {unpack(db.profile.raid)},
		raidborder = {unpack(db.profile.raidborder)},
		bar = {unpack(db.profile.bar)},
		bar2 = {unpack(db.profile.bar2)},
		sidebar = {unpack(db.profile.sidebar)},
		minimap = {unpack(db.profile.minimap)},
		micromenu = {unpack(db.profile.micromenu)},
		micromenu_bg = {unpack(db.profile.micromenu_bg)},
		micromenu_bg2 = {unpack(db.profile.micromenu_bg2)},
		micromenu_btn = {unpack(db.profile.micromenu_btn)},
		micromenu_btn_hover = {unpack(db.profile.micromenu_btn_hover)},
		navi = {unpack(db.profile.navi)},
		navi_hover = {unpack(db.profile.navi_hover)},
		orb = {unpack(db.profile.orb)},
		orb_cycle = {unpack(db.profile.orb_cycle)},
		orb_hover = {unpack(db.profile.orb_hover)},
	}
	db.profile.theme = theme
	ACR:NotifyChange("LUI")
end

function module:DeleteTheme(theme) --
	if theme == "" or theme == nil then theme = db.profile.theme end
	
	for k, v in pairs(ClassArray) do
		if theme == v then
			LUI:Print("CLASS THEMES CAN NOT BE DELETED!!!")
			return
		end
	end
	
	LUI_Themes[theme] = nil
	db.profile.theme = ""
	module:CheckTheme()
	module:ApplyTheme()
	ACR:NotifyChange("LUI")
end

function module:ImportThemeName(name) --
	if name == nil or name == "" then return end
	if LUI_Themes[name] ~= nil then StaticPopup_Show("LUI_THEMES_ALREADY_EXISTS") return end
	importThemeName = name
	StaticPopup_Show("LUI_THEMES_IMPORT_DATA")
end

function module:ImportThemeData(str, name) --
	if str == nil or str == "" then return end
	if name == nil or name == "" then
		if importThemeName ~= nil then
			name = importThemeName
		else
			LUI:Print("Invalid Theme Name")
		end
	end
	importThemeName = nil
	if LUI_Themes[name] ~= nil then StaticPopup_Show("LUI_THEMES_ALREADY_EXISTS") return end
	
	local valid, data = LUI:Deserialize(str)
	if not valid then
		LUI:Print("Error importing theme!")
		return
	end
	LUI_Themes[name] = data
	db.profile.theme = name
	module:LoadTheme(name)
	module:ApplyTheme()
	LUI:Print("Successfully imported "..name.." theme!")
	ACR:NotifyChange("LUI")
end

function module:ExportTheme(theme) --
	if theme == "" or theme == nil then theme = db.profile.theme end
	if LUI_Themes[theme] == nil then return end
	
	local data = LUI:Serialize(LUI_Themes[theme])
	if data == nil then return end
	local breakDown
	for i = 1, math.ceil(strlen(data)/100) do
		local part = (strsub(data, (((i-1)*100)+1), (i*100))).." "
		breakDown = (breakDown and breakDown or "")..part
	end
	return breakDown
end

--------------------------------------------------
-- / Sorted Table of Themes (for option menu) / --
--------------------------------------------------

function module.ThemeArray() -- no self in this function
	local LUIThemeArray = {}
	local TempThemeArray = {}
	
	for themeName in pairs(LUI_Themes) do
		table.insert((tContains(ClassArray, themeName) and LUIThemeArray or TempThemeArray), themeName)
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
		text = "That theme already exists.\nPlease choose another name.",
		button1 = "OK",
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		enterClicksFirstButton = true,
	}
	
	StaticPopupDialogs["LUI_THEMES_SAVE"] = {
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
		text = 'Are you sure you want to delete the current theme?',
		button1 = "Yes",
		button2 = "No",
		OnAccept = function(self) module:DeleteTheme() end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
	
	StaticPopupDialogs["LUI_THEMES_IMPORT"] = {
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
		text = "Paste (Ctrl + v) the new theme string here:",
		button1 = "Import Theme",
		button2 = "Cancel",
		hasEditBox = 1,
		editBoxWidth = 500,
		maxLetters = 2000,
		OnAccept = function(self)
				module:ImportThemeData(self.editBox:GetText())
			end,
		EditBoxOnEnterPressed = function(self)
				self:GetParent():Hide()
				module:ImportThemeData(self:GetText())
			end,
		EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
	
	StaticPopupDialogs["LUI_THEMES_EXPORT"] = {
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
		text = "Are you sure you want to reset all your themes?",
		button1 = "Yes",
		button2 = "No",
		OnAccept = function(self)
				wipe(LUI_Themes)
				LUI_Themes = themes
				if LUI_Themes[db.profile.theme] == nil then db.profile.theme = "" end
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
}

function module:LoadOptions()
	setStaticPopups()
	
	-- disabled functions
	local function minimapDisabled()
		local Minimap = LUI:GetModule("Minimap", true)
		return not (Minimap and Minimap:IsEnabled())
	end
	local function chatDisabled()
		local Chat = LUI:GetModule("Chat", true)
		return not (Chat and Chat:IsEnabled())
	end
	
	local disabledFuncs = {}
	local function createDisabled(toCheck)
		if not disabledFuncs[toCheck] then
			disabledFuncs[toCheck] = function()
				return not LUI:GetModule(toCheck, true)
			end
		end
		
		return disabledFuncs[toCheck]
	end
	
	-- get/set functions
	local function getValue(info)
		return db.profile[info[#info]]
	end
	local function setValue(info, val)
		db.profile[info[#info]] = val
	end
	
	local function getColor(info)
		return unpack(db.profile[info[#info]])
	end
	local function setColor(info, r, g, b, a)
		db.profile[info[#info]] = {r, g, b, a}
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
							if v == db.profile.theme then
								return k
							end
						end
					end,
					set = function(info, val)
						local themeArray = self.ThemeArray()
						if themeArray[val] ~= "" then
							db.profile.theme = themeArray[val]
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
					name = "Top Textur Color",
					desc = "Choose any Color for your Top Textur",
					type = "color",
					width = "full",
					hasAlpha = true,
					get = getColor,
					set = createSetColor("Frames"),
					order = 1,
				},
				color_bottom = {
					name = "Bottom Textur Color",
					desc = "Choose any Color for your Bottom Textur",
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
					disabled = createDisabled("Orb"),
					hasAlpha = true,
					get = getColor,
					set = createSetColor("Orb"),
					order = 3,
				},
				orb_cycle = {
					name = "Orb Background Color",
					desc = "Choose any Color for your Orb Background Textur",
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
	db = LUI:NewNamespace(self)
	
	-- for transition to namespace
	if LUI.db.profile.Colors then
		for k, v in pairs(LUI.db.profile.Colors) do
			db.profile[k] = v
		end
		LUI.db.profile.Colors = nil
	end
	
	LUI_Themes = LUI_Themes or {}
	if LUICONFIG.Versions.theme ~= version then -- rewrite the predefined themes saved in LUI_Themes
		for k, v in pairs(themes) do
			LUI_Themes[k] = v
		end

		LUICONFIG.Versions.theme = version
	end
	
	self:CheckTheme()
end