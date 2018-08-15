--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: grid.lua
	Description: Grid Install Script
	Version....: 1.0
]]

local addonname, LUI = ...

LUI.Versions.grid = 3300

function LUI:InstallGrid()
	if not IsAddOnLoaded("Grid") then return end
	local ProfileName = UnitName("Player").." - "..GetRealmName()
	if LUI.db.global.luiconfig[ProfileName].Versions.grid == LUI.Versions.grid then return end

	local Grid = LibStub("AceAddon-3.0"):GetAddon("Grid")
	local GridStatus = Grid:GetModule("GridStatus")
	local GridLayout = Grid:GetModule("GridLayout")
	local GridFrame = Grid:GetModule("GridFrame")
	--local GridRange = Grid:GetModule("GridRange")
	local GridRoster = Grid:GetModule("GridRoster")
	local GridStatusHealth = Grid:GetModule("GridStatus"):GetModule("GridStatusHealth")
	local GridStatusRange = Grid:GetModule("GridStatus"):GetModule("GridStatusRange")
	local GridStatusAuras = Grid:GetModule("GridStatus"):GetModule("GridStatusAuras")

	Grid:EnableModule("GridStatus")
	Grid:EnableModule("GridLayout")
	Grid:EnableModule("GridFrame")

	local CharName = UnitName("player")
	local ServerName = GetRealmName()
	local ProfileName = CharName.." - "..ServerName

	if GridDB.profileKeys ~= nil then
		local GridOldProfile

		for i, v in pairs(GridDB.profileKeys) do
			if i == ProfileName then
				GridOldProfile = v
				break;
			end
		end

		if GridOldProfile ~= nil then
			GridDB.namespaces.GridStatusAuras.profiles[CharName] = GridDB.namespaces.GridStatusAuras.profiles[GridOldProfile]
		end
	end

	if GridDB.profileKeys[ProfileName] == nil then
		tinsert(GridDB.profileKeys,ProfileName)
		GridDB.profileKeys[ProfileName] = CharName
	elseif GridDB.profileKeys[ProfileName] ~= CharName then
		GridDB.profileKeys[ProfileName] = CharName
	end

	GridDB.profiles[CharName] = ""
	GridDB.profiles[CharName] = {}
	GridDB.namespaces.GridFrame.profiles[CharName] = ""
	GridDB.namespaces.GridFrame.profiles[CharName] = {}
	GridDB.namespaces.GridStatusRange.profiles[CharName] = ""
	GridDB.namespaces.GridStatusRange.profiles[CharName] = {}
	GridDB.namespaces.GridStatus.profiles[CharName] = ""
	GridDB.namespaces.GridStatus.profiles[CharName] = {}
	GridDB.namespaces.GridLayout.profiles[CharName] = ""
	GridDB.namespaces.GridLayout.profiles[CharName] = {}
	GridDB.namespaces.GridStatusHealth.profiles[CharName] = ""
	GridDB.namespaces.GridStatusHealth.profiles[CharName] = {}

	_G.GridProfileDefaults = {
		[CharName] = {
			["showText"] = false,
			["showIcon"] = false,
			["hidden"] = true,
			["minimap"] = {
				["hide"] = true,
			},
		},
	}

	for k,v in pairs(GridProfileDefaults) do
		GridDB.profiles[k] = v
	end

	_G.GridFrameDefaults = {
		[CharName] = {
			["fontSize"] = 12,
			["statusmap"] = {
				["text"] = {
					["alert_voice"] = false,
					["alert_heals"] = false,
					["unit_health"] = false,
					["unit_healthDeficit"] = false,
					["player_target"] = false,
				},
				["border"] = {
					["alert_aggro"] = false,
					["unit_name"] = false,
					["alert_lowHealth"] = false,
					["alert_lowMana"] = false,
					["unit_health"] = false,
				},
				["barcolor"] = {
					["player_target"] = false,
					["debuff_ghost"] = true,
					["unit_healthDeficit"] = false,
					["unit_name"] = false,
					["alert_offline"] = false,
					["alert_death"] = false,
					["alert_aggro"] = false,
				},
				["corner4"] = {
					["alter_aggro"] = true,
				},
				["healingBar"] = {
					["alert_heals"] = false,
					["unit_name"] = false,
					["unit_health"] = false,
				},
				["frameAlpha"] = {
					["alert_offline"] = false,
					["unit_health"] = false,
					["player_target"] = false,
					["unit_name"] = false,
					["alert_range_10"] = false,
					["alert_range_30"] = false,
					["alert_death"] = false,
					["alert_range_100"] = false,
				},
				["corner3"] = {
					["debuff_curse"] = false,
					["debuff_poison"] = false,
					["debuff_disease"] = false,
					["debuff_magic"] = false,
				},
				["icon"] = {
					["debuff_poison"] = false,
					["debuff_disease"] = false,
					["debuff_magic"] = false,
				},
				["bar"] = {
					["debuff_ghost"] = true,
				},
			},
			["showTooltip"] = "Always",
			["iconSize"] = 17,
			["enableBarColor"] = true,
			["textlength"] = 8,
			["texture"] = "Minimalist",
			["enableIconStackText"] = false,
			["frameHeight"] = 37,
			["font"] = "vibroceb",
			["orientation"] = "HORIZONTAL",
			["frameWidth"] = 82,
		},
	}

	for k,v in pairs(GridFrameDefaults) do
		GridDB.namespaces.GridFrame.profiles[k] = v
	end

	_G.GridStatusRangeDefaults = {
		[CharName] = {
			["alert_range_100"] = {
				["color"] = {
					["a"] = 0.1090909090909091,
					["b"] = 0,
					["g"] = 0,
					["r"] = 0,
				},
				["priority"] = 90,
				["enable"] = false,
				["text"] = "100 yards",
				["range"] = false,
				["desc"] = "More than 100 yards away",
			},
			["alert_range_10"] = {
				["color"] = {
					["a"] = 0.8181818181818181,
					["b"] = 0.3,
					["g"] = 0.2,
					["r"] = 0.1,
				},
				["priority"] = 81,
				["enable"] = false,
				["text"] = "10 yards",
				["range"] = false,
				["desc"] = "More than 10 yards away",
			},
			["alert_range_40"] = {
				["color"] = {
					["a"] = 0.2727272727272727,
					["b"] = 0.2,
					["g"] = 0.8,
					["r"] = 0.4,
				},
				["priority"] = 84,
				["enable"] = true,
				["text"] = "40 yards",
				["range"] = false,
				["desc"] = "More than 40 yards away",
			},
			["alert_range_28"] = {
				["color"] = {
					["a"] = 0.490909090909091,
					["b"] = 0.84,
					["g"] = 0.5600000000000001,
					["r"] = 0.28,
				},
				["priority"] = 83,
				["enable"] = false,
				["text"] = "28 yards",
				["range"] = false,
				["desc"] = "More than 28 yards away",
			},
			["alert_range_30"] = {
				["color"] = {
					["a"] = 0.4545454545454546,
					["b"] = 0.9,
					["g"] = 0.6,
					["r"] = 0.3,
				},
				["priority"] = 83,
				["enable"] = false,
				["text"] = "30 yards",
				["range"] = false,
				["desc"] = "More than 30 yards away",
			},
			["alert_range_38"] = {
				["color"] = {
					["a"] = 0.3090909090909091,
					["b"] = 0.14,
					["g"] = 0.76,
					["r"] = 0.38,
				},
				["priority"] = 84,
				["enable"] = false,
				["text"] = "38 yards",
				["range"] = false,
				["desc"] = "More than 38 yards away",
			},
		},
	}

	for k,v in pairs(GridStatusRangeDefaults) do
		GridDB.namespaces.GridStatusRange.profiles[k] = v
	end

	_G.GridStatusDefaults = {
		[CharName] = {
			["colors"] = {
				["PALADIN"] = {
					["b"] = 0.73,
					["g"] = 0.55,
					["r"] = 0.96,
				},
				["MAGE"] = {
					["b"] = 0.94,
					["g"] = 0.8,
					["r"] = 0.41,
				},
				["DRUID"] = {
					["b"] = 0.04,
					["g"] = 0.49,
					["r"] = 1,
				},
				["DEATHKNIGHT"] = {
					["b"] = 0.23,
					["g"] = 0.12,
					["r"] = 0.77,
				},
				["DEMONHUNTER"] = {
					["b"] = 0.79,
					["g"] = 0.19,
					["r"] = 0.64,
				},
				["ROGUE"] = {
					["b"] = 0.41,
					["g"] = 0.96,
					["r"] = 1,
				},
				["HUNTER"] = {
					["b"] = 0.45,
					["g"] = 0.83,
					["r"] = 0.67,
				},
				["PRIEST"] = {
					["b"] = 1,
					["g"] = 1,
					["r"] = 1,
				},
				["SHAMAN"] = {
					["b"] = 0.87,
					["g"] = 0.44,
					["r"] = 0,
				},
				["WARLOCK"] = {
					["b"] = 0.79,
					["g"] = 0.51,
					["r"] = 0.58,
				},
				["WARRIOR"] = {
					["b"] = 0.43,
					["g"] = 0.61,
					["r"] = 0.78,
				},
			},
		},
	}

	for k,v in pairs(GridStatusDefaults) do
		GridDB.namespaces.GridStatus.profiles[k] = v
	end

	_G.GridLayoutDefaults = {
		[CharName] = {
			["anchorRel"] = "TOPLEFT",
			["layouts"] = {
				["party"] = "By Group 25",
				["solo"] = "By Group 25",
				["arena"] = "By Group 25",
				["bg"] = "By Group 25",
				["raid"] = "By Group 25",
			},
			["borderColor"] = {
				["a"] = 0,
				["r"] = 0.2470588235294118,
				["g"] = 0.2470588235294118,
				["b"] = 0.2470588235294118,
			},
			["backgroundColor"] = {
				["a"] = 0,
				["r"] = 0.3294117647058824,
				["g"] = 0.3294117647058824,
				["b"] = 0.3294117647058824,
			},
			["FrameLock"] = true,
			["Spacing"] = 3,
			["layout"] = "By Group 25",
			["Padding"] = 0,
			["PosX"] = 939.721672815782,
			["PosY"] = -601.9189477952709,
		},
	}

	for k,v in pairs(GridLayoutDefaults) do
		GridDB.namespaces.GridLayout.profiles[k] = v
	end

	_G.GridStatusHealthDefaults = {
		[CharName] = {
			["unit_healthDeficit"] = {
				["threshold"] = 59,
				["useClassColors"] = false,
				["text"] = "TG",
				["icon"] = "Interface\\Icons\\Ability_Rogue_FeignDeath",
				["color"] = {
					["b"] = 0.5,
					["g"] = 0.5,
					["r"] = 0.5,
				},
				["priority"] = 99,
			},
			["alert_lowHealth"] = {
				["enable"] = false,
				["text"] = "Less HP",
			},
			["alert_death"] = {
				["priority"] = 99,
			},
			["unit_health"] = {
				["deadAsFullHealth"] = false,
				["color"] = {
					["b"] = 0.5019607843137255,
					["g"] = 0.5019607843137255,
					["r"] = 0.5019607843137255,
				},
				["priority"] = 99,
				["useClassColors"] = false,
			},
		},
	}

	for k,v in pairs(GridStatusHealthDefaults) do
		GridDB.namespaces.GridStatusHealth.profiles[k] = v
	end

	GridFrame.db.profile.showTooltip = true
	GridStatusHealth.db.profile.unit_health.useClassColors = false

	LUI.db.global.luiconfig[ProfileName].Versions.grid = LUI.Versions.grid
end
