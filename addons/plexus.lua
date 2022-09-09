--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: plexus.lua
	Description: Plexus Install Script
	Version....: 1.0
]]

local addonname, LUI = ...

LUI.Versions.plexus = 3300

local IsAddOnLoaded = _G.IsAddOnLoaded
local GetRealmName = _G.GetRealmName
local UnitName = _G.UnitName

function LUI:InstallPlexus()
	if not IsAddOnLoaded("Plexus") then return end
	local CharName = UnitName("Player")
	local ProfileName = CharName.." - "..GetRealmName()
	if LUI.db.global.luiconfig[ProfileName].Versions.plexus == LUI.Versions.plexus then return end
	
	local Plexus = LibStub("AceAddon-3.0"):GetAddon("Plexus")
	local PlexusStatus = Plexus:GetModule("PlexusStatus")
	local PlexusLayout = Plexus:GetModule("PlexusLayout")
	local PlexusFrame = Plexus:GetModule("PlexusFrame")
	--local PlexusRange = Plexus:GetModule("PlexusRange")
	local PlexusRoster = Plexus:GetModule("PlexusRoster")
	local PlexusStatusHealth = Plexus:GetModule("PlexusStatus"):GetModule("PlexusStatusHealth")
	local PlexusStatusRange = Plexus:GetModule("PlexusStatus"):GetModule("PlexusStatusRange")
	local PlexusStatusAuras = Plexus:GetModule("PlexusStatus"):GetModule("PlexusStatusAuras")
	local PlexusDB = _G.PlexusDB

	Plexus:EnableModule("PlexusStatus")
	Plexus:EnableModule("PlexusLayout")
	Plexus:EnableModule("PlexusFrame")

	if PlexusDB.profileKeys ~= nil then
		local PlexusOldProfile

		for i, v in pairs(PlexusDB.profileKeys) do
			if i == ProfileName then
				PlexusOldProfile = v
				break;
			end
		end

		if PlexusOldProfile ~= nil then
			PlexusDB.namespaces.PlexusStatusAuras.profiles[CharName] = PlexusDB.namespaces.PlexusStatusAuras.profiles[PlexusOldProfile]
		end
	end

	if PlexusDB.profileKeys[ProfileName] == nil then
		tinsert(PlexusDB.profileKeys,ProfileName)
		PlexusDB.profileKeys[ProfileName] = CharName
	elseif PlexusDB.profileKeys[ProfileName] ~= CharName then
		PlexusDB.profileKeys[ProfileName] = CharName
	end

	PlexusDB.profiles[CharName] = ""
	PlexusDB.profiles[CharName] = {}
	PlexusDB.namespaces.PlexusFrame.profiles[CharName] = ""
	PlexusDB.namespaces.PlexusFrame.profiles[CharName] = {}
	PlexusDB.namespaces.PlexusStatusRange.profiles[CharName] = ""
	PlexusDB.namespaces.PlexusStatusRange.profiles[CharName] = {}
	PlexusDB.namespaces.PlexusStatus.profiles[CharName] = ""
	PlexusDB.namespaces.PlexusStatus.profiles[CharName] = {}
	PlexusDB.namespaces.PlexusLayout.profiles[CharName] = ""
	PlexusDB.namespaces.PlexusLayout.profiles[CharName] = {}
	PlexusDB.namespaces.PlexusStatusHealth.profiles[CharName] = ""
	PlexusDB.namespaces.PlexusStatusHealth.profiles[CharName] = {}

	_G.PlexusProfileDefaults = {
		[CharName] = {
			["showText"] = false,
			["showIcon"] = false,
			["hidden"] = true,
			["minimap"] = {
				["hide"] = true,
			},
		},
	}

	for k,v in pairs(_G.PlexusProfileDefaults) do
		PlexusDB.profiles[k] = v
	end

	_G.PlexusFrameDefaults = {
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

	for k,v in pairs(_G.PlexusFrameDefaults) do
		PlexusDB.namespaces.PlexusFrame.profiles[k] = v
	end

	_G.PlexusStatusRangeDefaults = {
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

	for k,v in pairs(_G.PlexusStatusRangeDefaults) do
		PlexusDB.namespaces.PlexusStatusRange.profiles[k] = v
	end

	_G.PlexusStatusDefaults = {
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

	for k,v in pairs(_G.PlexusStatusDefaults) do
		PlexusDB.namespaces.PlexusStatus.profiles[k] = v
	end

	_G.PlexusLayoutDefaults = {
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

	for k,v in pairs(_G.PlexusLayoutDefaults) do
		PlexusDB.namespaces.PlexusLayout.profiles[k] = v
	end

	_G.PlexusStatusHealthDefaults = {
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

	for k,v in pairs(_G.PlexusStatusHealthDefaults) do
		PlexusDB.namespaces.PlexusStatusHealth.profiles[k] = v
	end

	PlexusFrame.db.profile.showTooltip = true
	PlexusStatusHealth.db.profile.unit_health.useClassColors = false

	LUI.db.global.luiconfig[ProfileName].Versions.plexus = LUI.Versions.plexus
end
