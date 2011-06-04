--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: general.lua
	Description: oUF General Module
	Version....: 1.0
	Notes......: This module contains all of the defaults and options that are contained within all of the UnitFrames.
]] 

local _, ns = ...
local oUF = ns.oUF or oUF

local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local module = LUI:NewModule("oUF_General")
local Forte
local LSM = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists

local db

local units = {"Player", "Target", "ToT", "ToToT", "Focus", "FocusTarget", "Pet", "PetTarget", "Party", "PartyTarget", "PartyPet", "Boss", "BossTarget", "Maintank", "MaintankTarget", "MaintankToT", "Arena", "ArenaTarget", "ArenaPet", "Raid"}

local ufNamesList = {
	Player = {"oUF_LUI_player"},
	Target = {"oUF_LUI_target"},
	ToT = {"oUF_LUI_targettarget"},
	ToToT = {"oUF_LUI_targettargettarget"},
	Focus = {"oUF_LUI_focus"},
	FocusTarget = {"oUF_LUI_focustarget"},
	Pet = {"oUF_LUI_pet"},
	PetTarget = {"oUF_LUI_pettarget"},
	Party = {},
	PartyTarget = {},
	PartyPet = {},
	Boss = {},
	BossTarget ={},
	Maintank = {},
	MaintankTarget = {},
	MaintankToT = {},
	Arena = {},
	ArenaTarget = {},
	ArenaPet = {},
	Raid = {},
}

do
	local ufNamesPrefix = {
		Party = "oUF_LUI_partyUnitButton",
		PartyTarget = "oUF_LUI_partyUnitButton",
		PartyPet = "oUF_LUI_partyUnitButton",
		Boss = "oUF_LUI_boss",
		BossTarget = "oUF_LUI_bosstarget",
		Maintank = "oUF_LUI_maintankUnitButton",
		MaintankTarget = "oUF_LUI_maintankUnitButton",
		MaintankToT = "oUF_LUI_maintankUnitButton",
		Arena = "oUF_LUI_arena",
		ArenaTarget = "oUF_LUI_arenatarget",
		ArenaPet = "oUF_LUI_arenapet",
	}
	local ufNamesSuffix = {
		PartyTarget = "target",
		PartyPet = "pet",
		MaintankTarget = "target",
		MaintankToT = "targettarget",
	}
	local ufNamesCount = {
		Party = 5,
		PartyTarget = 5,
		PartyPet = 5,
		Boss = 4,
		BossTarget = 4,
		Maintank = 3,
		MaintankTarget = 3,
		MaintankToT = 3,
		Arena = 5,
		ArenaTarget = 5,
		ArenaPet = 5,
	}

	-- adding group frames
	for k, v in pairs(ufNamesList) do
		if ufNamesCount[k] then
			local prefix = ufNamesPrefix[k]
			local suffix = ufNamesSuffix[k] or ""
			for i = 1, ufNamesCount[k] do
				ufNamesList[k][i] = prefix..i..suffix
			end
		end
	end
	
	for i = 1, 5 do
		for j = 1, 5 do
			table.insert(ufNamesList.Raid, "oUF_LUI_raid_25_"..i.."UnitButton"..j)
		end
	end
	
	for i = 1, 8 do
		for j = 1, 5 do
			table.insert(ufNamesList.Raid, "oUF_LUI_raid_40_"..i.."UnitButton"..j)
		end
	end
end

-- needed for moving frames and some other things
local ufMover = {
	Party = "oUF_LUI_party",
	Boss = "oUF_LUI_boss",
	Maintank = "oUF_LUI_maintank",
	Arena = "oUF_LUI_arena",
	Player = "oUF_LUI_player",
	Target = "oUF_LUI_target",
	ToT = "oUF_LUI_targettarget",
	ToToT = "oUF_LUI_targettargettarget",
	Focus = "oUF_LUI_focus",
	FocusTarget = "oUF_LUI_focustarget",
	Pet = "oUF_LUI_pet",
	PetTarget = "oUF_LUI_pettarget",
	Raid = "oUF_LUI_raid",
}

local barColors = {
	Health = {"By Class", "Gradient", "Individual"},
	Power = {"By Class", "By Type", "Individual"}
}

local iconNamesList = {
	PvP = {"PvP"},
	Combat = {"Combat"},
	Resting = {"Resting"},
	Lootmaster = {"MasterLooter"},
	Leader = {"Leader", "Assistant"},
	Role = {"LFDRole"},
	Raid = {"RaidIcon"},
}

local positions = {"TOP", "TOPRIGHT", "TOPLEFT","BOTTOM", "BOTTOMRIGHT", "BOTTOMLEFT","RIGHT", "LEFT", "CENTER"}
local fontflags = {'OUTLINE', 'THICKOUTLINE', 'MONOCHROME', 'NONE'}
local justifications = {'LEFT', 'CENTER', 'RIGHT'}
local valueFormat = {'Absolut', 'Absolut & Percent', 'Absolut Short', 'Absolut Short & Percent', 'Standard', 'Standard Short'}
local nameFormat = {'Name', 'Name + Level', 'Name + Level + Class', 'Name + Level + Race + Class', 'Level + Name', 'Level + Name + Class', 'Level + Class + Name', 'Level + Name + Race + Class', 'Level + Race + Class + Name'}
local nameLenghts = {'Short', 'Medium', 'Long'}
local growthY = {"UP", "DOWN"}
local growthX = {"LEFT", "RIGHT"}
local _, class = UnitClass("player")

------------------------------------------------------------------------
--	Heal Prediction Option Constructor
------------------------------------------------------------------------

function module:CreateHealPredictionOptions(unit)
	local hpdefaults = LUI.defaults.profile.oUF[unit].HealPrediction
	local hpdb = db.oUF[unit].HealPrediction
	local ufNames = ufNamesList[unit]
	
	local ToggleFunc = function(Enable)
		for _, frame in pairs(ufNames) do
			if _G[frame] then
				if not _G[frame].HealPrediction then LUI.oUF.funcs.HealPrediction(_G[frame], _G[frame].__unit, db.oUF[unit]) end
				if Enable then
					_G[frame]:EnableElement("HealPrediction")
				else
					_G[frame]:DisableElement("HealPrediction")
				end
				_G[frame]:UpdateAllElements()
			end
		end
	end
	
	local ApplySettings = function()
		for _, frame in pairs(ufNames) do
			if _G[frame] then
				LUI.oUF.funcs.HealPrediction(_G[frame], _G[frame].__unit, db.oUF[unit])
				_G[frame]:UpdateAllElements()
			end
		end
	end
	
	local options = {
		name = "Heal Prediction",
		type = "group",
		guiInline = true,
		order = 5,
		args = {
			Enable = LUI:NewToggle("Enable", "Whether you want to show predicted Heals on "..unit.." or not.", 1, hpdb, "Enable", hpdefaults, ToggleFunc),
			empty = LUI:NewEmpty(2),
			MyColor = LUI:NewColor("My", "Heal Prediction Bar", 3, hpdb.MyColor, hpdefaults.MyColor, ApplySettings, "normal", function() return not hpdb.Enable end),
			OtherColor = LUI:NewColor("Other", "Heal Prediction Bar", 4, hpdb.OtherColor, hpdefaults.OtherColor, ApplySettings, "normal", function() return not hpdb.Enable end),
			empty2 = LUI:NewEmpty(5),
			Texture = LUI:NewSelect("Texture", "Choose your Heal Prediction Texture.", 6, widgetLists.statusbar, "LSM30_Statusbar", hpdb, "Texture", hpdefaults, ApplySettings, "normal", function() return not hpdb.Enable end),
		},
	}
	
	return options
end

------------------------------------------------------------------------
--	Bar Option Constructor
------------------------------------------------------------------------

-- barType: "Health", "Power", "Full"
function module:CreateBarOptions(unit, order, barType)
	local bardefaults = LUI.defaults.profile.oUF[unit][barType]
	local bardb = db.oUF[unit][barType]
	local ufNames = ufNamesList[unit]
	
	local ApplySettings = function()
		for _, frame in pairs(ufNames) do
			if _G[frame] then
				LUI.oUF.funcs[barType](_G[frame], _G[frame].__unit, db.oUF[unit])
				_G[frame]:UpdateAllElements()
			end
		end
	end
	
	local ToggleSmooth = function(Smooth)
		for _, frame in pairs(ufNames) do
			if Smooth then
				if _G[frame] then _G[frame]:SmoothBar(_G[frame][barType]) end
			else
				if _G[frame] then _G[frame][barType].SetValue = _G[frame][barType].SetValue_ end
			end
		end
	end
	
	local options = {
		name = barType,
		type = "group",
		order = order,
		args = {
			Enable = (barType ~= "Health") and LUI:NewToggle("Enable", "Whether you want to show "..barType.."bar or not.", 1, bardb, "Enable", bardefaults, ApplySettings) or nil,
			General = {
				name = "Settings",
				type = "group",
				disabled = function() return (bardb.Enable ~= nil and not bardb.Enable or false) end,
				guiInline = true,
				order = 2,
				args = {
					Height = LUI:NewHeight(unit.." "..barType.."bar", 1, bardb, nil, bardefaults, ApplySettings),
					Padding = (barType == "Health") and LUI:NewPadding(barType.." bar and the Unitframe", 2, bardb, nil, bardefaults, ApplySettings) or LUI:NewPadding(barType.."bar and Healthbar", 2, bardb, nil, bardefaults, ApplySettings),
					Smooth = (barType ~= "Full") and LUI:NewToggle("Enable Smooth Bar Animation", "Whether you want to use Smooth Animations or not.", 3, bardb, "Smooth", bardefaults, ToggleSmooth) or nil,
					Color = (barType == "Full") and LUI:NewColorNoAlpha(barType.."bar ", nil, 4, bardb.Color, bardefaults.Color, ApplySettings) or nil,
					Texture = (barType == "Full") and LUI:NewSelect("Texture", "Choose the "..barType.."bar Texture.", 5, widgetLists.statusbar, "LSM30_Statusbar", bardb, "Texture", bardefaults, ApplySettings) or nil,
				},
			},
			Colors = (barType ~= "Full") and {
				name = "Colors",
				type = "group",
				disabled = function() return (bardb.Enable ~= nil and not bardb.Enable or false) end,
				guiInline = true,
				order = 3,
				args = {
					ColorType = LUI:NewSelect("Color", "Choose the Color Option for the "..barType.."bar", 1, barColors[barType], nil, bardb, "Color", bardefaults, ApplySettings),
					empty = LUI:NewEmpty(2),
					IndividualColor = LUI:NewColorNoAlpha(barType.."bar", unit.." "..barType.."bar", 3, bardb.IndividualColor, bardefaults.IndividualColor, ApplySettings, "full", function() return (bardb.Color ~= "Individual") end),
				},
			} or nil,
			Textures = (barType ~= "Full") and {
				name = "Texture Settings",
				type = "group",
				disabled = function() return (bardb.Enable ~= nil and not bardb.Enable or false) end,
				guiInline = true,
				order = 4,
				args = {
					Texture = LUI:NewSelect("Texture", "Choose the "..barType.." Texture.", 1, widgetLists.statusbar, "LSM30_Statusbar", bardb, "Texture", bardefaults, ApplySettings),
					TextureBG = LUI:NewSelect("Background Texture", "Choose the "..barType.." Background Texture.", 2, widgetLists.statusbar, "LSM30_Statusbar", bardb, "TextureBG", bardefaults, ApplySettings),
					BGAlpha = LUI:NewSlider("Background Alpha", "Choose the Alpha Value for the "..barType.." Background.", 3, bardb, "BGAlpha", bardefaults, 0, 1, 0.05, ApplySettings, "normal"),
					BGMultiplier = LUI:NewSlider("Background Multiplier", "Choose the Multiplier which will be used to generate the Background Color.", 4, bardb, "BGMultiplier", bardefaults, 0, 1, 0.05, ApplySettings),
					BGInvert = LUI:NewToggle("Invert BG Color", "Whether you want to invert the Background Color or not.", 5, bardb, "BGInvert", bardefaults, ApplySettings),
				},
			} or nil,
			HealPrediction = (barType == "Health" and db.oUF[unit].HealPrediction) and module:CreateHealPredictionOptions(unit) or nil,
		},
	}
	
	return options
end

------------------------------------------------------------------------
--	Text Option Constructor
------------------------------------------------------------------------
	
-- parentName: "Health", "Power"
-- textType: "Value", "Percent", "Missing"
function module:CreateTextOptions(unit, order, parentName, textType)
	local textFunc = parentName..textType
	if textType == "Value" then textType = "" end
	local textdefaults = LUI.defaults.profile.oUF[unit]["Texts"][parentName..textType]
	local textdb = db.oUF[unit]["Texts"][parentName..textType]
	local ufNames = ufNamesList[unit]
	local textName = parentName..textType
	
	local ApplySettings = function()
		for _, frame in pairs(ufNames) do
			if _G[frame] then
				LUI.oUF.funcs[textFunc](_G[frame], _G[frame].__unit, db.oUF[unit])
				_G[frame]:UpdateAllElements()
			end
		end
	end
	
	local options = {
		name = textName,
		type = "group",
		order = order,
		args = {
			Enable = LUI:NewToggle("Enable", "Whether you want to show "..textName.." Value or not.", 1, textdb, "Enable", textdefaults, ApplySettings),
			FontSettings = {
				name = "Font Settings",
				type = "group",
				disabled = function() return not textdb.Enable end,
				guiInline = true,
				order = 2,
				args = {
					FontSize = LUI:NewSlider("Size", "Choose the "..unit.." "..textName.." Fontsize.", 1, textdb, "Size", textdefaults, 1, 40, 1, ApplySettings),
					empty = LUI:NewEmpty(2),
					Font = LUI:NewSelect("Font", "Choose the Font for "..unit.." "..textName, 3, widgetLists.font, "LSM30_Font", textdb, "Font", textdefaults, ApplySettings),
					FontFlag = LUI:NewSelect("Font Flag", "Choose the Font Flag for "..unit.." "..textName, 4, fontflags, nil, textdb, "Outline", textdefaults, ApplySettings),
					XValue = LUI:NewPosX(unit.." "..textName, 5, textdb, "", textdefaults, ApplySettings),
					YValue = LUI:NewPosY(unit.." "..textName, 6, textdb, "", textdefaults, ApplySettings),
					Point = LUI:NewSelect("Point", "Choose the Point for your "..unit.." "..textName, 7, positions, nil, textdb, "Point", textdefaults, ApplySettings),
					RelativePoint = LUI:NewSelect("Relative Point", "Choose the Relative Point for your "..unit.." "..textName, 8, positions, nil, textdb, "RelativePoint", textdefaults, ApplySettings),
				},
			},
			Settings = {
				name = "Settings",
				type = "group",
				disabled = function() return not textdb.Enable end,
				guiInline = true,
				order = 3,
				args = {
					Format = (textType == "") and LUI:NewSelect("Format", "Choose the Format for the "..unit.." "..textName, 1, valueFormat, nil, textdb, "Format", textdefaults, ApplySettings) or nil,
					empty = (textType == "") and LUI:NewEmpty(2) or nil,
					ShowAlways = (parentName == "Health") and LUI:NewToggle("Show Always", "Always show "..unit.." "..textName.." or just if the Unit has no MaxHP", 3, textdb, "ShowAlways", textdefaults, ApplySettings, "normal") or nil,
					ShowFull = (parentName == "Power") and LUI:NewToggle("Show Full", "Whether show "..unit.." "..textName.." when full or not.", 4, textdb, "ShowFull", textdefaults, ApplySettings, "normal") or nil,
					ShowEmpty = (parentName == "Power") and LUI:NewToggle("Show Empty", "Whether show "..unit.." "..textName.." when empty or not.", 5, textdb, "ShowEmpty", textdefaults, ApplySettings, "normal") or nil,
					ShowDead = (parentName == "Health" and textType ~= "Missing") and LUI:NewToggle("Show Dead/AFK/Disconnected", "Whether you want to switch the "..textName.." Value to Dead/AFK/Disconnected or not.", 6, textdb, "ShowDead", textdefaults, ApplySettings, "full") or nil,
				},
			},
			Colors = {
				name = "Color Settings",
				type = "group",
				disabled = function() return not textdb.Enable end,
				guiInline = true,
				order = 4,
				args = {
					ColorType = LUI:NewSelect("Color", "Choose the Color Option for the "..textType.." Value", 1, barColors[parentName], nil, textdb, "Color", textdefaults, ApplySettings),
					IndividualColor = LUI:NewColorNoAlpha(textType, textType.." Value", 2, textdb.IndividualColor, textdefaults.IndividualColor, ApplySettings, "full", function() return (textdb.Color ~= "Individual") end),
				},
			},
		},
	}
	
	return options
end

------------------------------------------------------------------------
--	Icon Option Constructor
------------------------------------------------------------------------
	
-- iconType: "PvP", "Combat", "Resting", "Lootmaster", "Leader", "Role", "Raid"
function module:CreateIconOptions(unit, order, iconType)
	local icondefaults = LUI.defaults.profile.oUF[unit]["Icons"][iconType]
	local icondb = db.oUF[unit]["Icons"][iconType]
	local ufNames = ufNamesList[unit]
	local iconNames = iconNamesList[iconType]
	
	local ToggleFunc = function(self, Enable)
		for _, frame in pairs(ufNames) do
			if _G[frame] then
				if not _G[frame][iconNames[1]] then LUI.oUF.funcs[iconNames[1]](_G[frame], _G[frame].__unit, db.oUF[unit]) end
				for _, icon in pairs(iconNames) do
					if Enable then
						_G[frame]:EnableElement(icon)
						_G[frame]:UpdateAllElements()
					else
						_G[frame]:DisableElement(icon)
						_G[frame][icon]:Hide()
					end
				end
			end
		end
	end
	
	local ApplySettings = function()
		for _, frame in pairs(ufNames) do
			if _G[frame] then LUI.oUF.funcs[iconNames[1]](_G[frame], _G[frame].__unit, db.oUF[unit]) end
		end
	end
	
	local ShowHideFunc = function()
		for _, frame in pairs(ufNames) do
			if _G[frame] and _G[frame][iconNames[1]] then
				if _G[frame][iconNames[1]]:IsShown() then _G[frame][iconNames[1]]:Hide() else _G[frame][iconNames[1]]:Show() end
			end
		end
	end
	
	local options = {
		name = iconType,
		type = "group",
		order = order,
		args = {
			Enable = LUI:NewToggle("Enable", "Whether you want to show the "..iconType.." Icon or not.", 1, icondb, "Enable", icondefaults, ToggleFunc),
			XValue = LUI:NewOffsetX(iconType.." Icon", 2, icondb, "", icondefaults, ApplySettings, nil, function() return not icondb.Enable end),
			YValue = LUI:NewOffsetY(iconType.." Icon", 3, icondb, "", icondefaults, ApplySettings, nil, function() return not icondb.Enable end),
			Point = LUI:NewSelect("Position", "Choose the Position for your "..iconType.." Icon.", 4, positions, nil, icondb, "Point", icondefaults, ApplySettings, nil, function() return not icondb.Enable end),
			Size = LUI:NewSlider("Size", "Choose the Size for your "..iconType.." Icon.", 5, icondb, "Size", icondefaults, 5, 60, 1, ApplySettings, nil, function() return not icondb.Enable end),
			Toggle = LUI:NewExecute("Show/Hide", "Toggles the "..iconType.." Icon.", 6, ShowHideFunc, nil, function() return not icondb.Enable end),
		},
	}
	
	return options
end

------------------------------------------------------------------------
--	Aura Option Constructor
------------------------------------------------------------------------
	
function module:CreateAuraOptions(unit, order, isDebuff)
	local auradb = db.oUF[unit].Aura
	local auradefaults = LUI.defaults.profile.oUF[unit].Aura
	local ufNames = ufNamesList[unit]
	local prefix = isDebuff and "debuffs" or "buffs"
	local element = isDebuff and "Debuffs" or "Buffs"
	
	local ToggleFunc = function(self, Enable)
		for _, frame in pairs(ufNames) do
			if _G[frame] then
				if not _G[frame][element] then LUI.oUF.funcs[element](_G[frame], _G[frame].__unit, db.oUF[unit]) end
				if Enable == true then
					_G[frame]:EnableElement("Aura")
					_G[frame][element]:Show()
				else
					if auradb.debuffs_enable == false and auradb.buffs_enable == false then
						_G[frame]:DisableElement("Aura")
					end
					_G[frame][element]:Hide()
				end
				_G[frame]:UpdateAllElements()
			end
		end
	end
	
	local ApplySettings = function()
		for _, frame in pairs(ufNames) do
			if _G[frame] then LUI.oUF.funcs[element](_G[frame], _G[frame].__unit, db.oUF[unit]) end
		end
	end
	
	local AurasDisabled = function() return not auradb[prefix.."_enable"] end
	local PetIncludeDisabled = function() return not (auradb[prefix.."_enable"] and auradb[prefix.."_playeronly"]) end
	local CooldownDisabled = function() return not auradb[prefix.."_enable"] or auradb[prefix.."_disableCooldown"] end 
	
	local options = {
		name = element,
		type = "group",
		order = order,
		args = {
			Enable = LUI:NewToggle("Enable "..unit.." "..element, "Whether you want to show "..unit.." "..element.." or not.", 1, auradb, prefix.."_enable", auradefaults, ToggleFunc),
			Auratimer = LUI:NewToggle("Enable Auratimer", "Whether you want to show Auratimers or not.", 2, auradb, prefix.."_auratimer", auradefaults, ApplySettings, nil, AurasDisabled),
			PlayerOnly = LUI:NewToggle("Player "..element.." Only", "Whether you want to show only the "..element.." on "..unit.." or not.", 3, auradb, prefix.."_playeronly", auradefaults, ApplySettings, "normal", AurasDisabled),
			IncludePet = LUI:NewToggle("Include Pet "..element, "Whether you want to include Pet "..element.." or not.", 4, auradb, prefix.."_includepet", auradefaults, ApplySettings, "normal", PetIncludeDisabled),
			ColorByType = LUI:NewToggle("Color by Type", "Whether you want to color "..unit.." "..element.." by Type or not.", 5, auradb, prefix.."_colorbytype", auradefaults, ApplySettings, nil, AurasDisabled),
			Cooldown = LUI:NewToggle("Hide Cooldown Spiral", "Whether wou want to disable the cooldown spiral effect or not.", 6, auradb, prefix.."_disableCooldown", auradefaults, ApplySettings, "normal", AurasDisabled),
			CooldownReverse = LUI:NewToggle("Reverse Cooldown Effect", "Whether you want to reverse the cooldown spiral effect or not.", 7, auradb, prefix.."_cooldownReverse", auradefaults, ApplySettings, "normal", CooldownDisabled),
			Num = LUI:NewInputNumber("Amount", "Amount of the "..unit.." "..element, 8, auradb, prefix.."_num", auradefaults, ApplySettings, nil, AurasDisabled),
			empty = LUI:NewEmpty(9),
			Size = LUI:NewInputNumber("Size", "Size of the "..unit.." "..element, 10, auradb, prefix.."_size", auradefaults, ApplySettings, nil, AurasDisabled),
			Spacing = LUI:NewInputNumber("Spacing", "Spacing between the "..unit.." "..element, 11, auradb, prefix.."_spacing", auradefaults, ApplySettings, nil, AurasDisabled),
			X = LUI:NewPosX(unit.." "..element, 12, auradb, prefix, auradefaults, ApplySettings, nil, AurasDisabled),
			Y = LUI:NewPosY(unit.." "..element, 13, auradb, prefix, auradefaults, ApplySettings, nil, AurasDisabled),
			GrowthX = LUI:NewSelect("Growth X", "Choose the Growth X direction for the "..unit.." "..element, 14, growthX, nil, auradb, prefix.."_growthX", auradefaults, ApplySettings, nil, AurasDisabled),
			GrowthY = LUI:NewSelect("Growth Y", "Choose the Growth Y direction for the "..unit.." "..element, 15, growthY, nil, auradb, prefix.."_growthY", auradefaults, ApplySettings, nil, AurasDisabled),
			Anchor = LUI:NewSelect("Initial Anchor", "Choose the initial Anchor for the "..unit.." "..element, 16, positions, nil, auradb, prefix.."_initialAnchor", auradefaults, ApplySettings, nil, AurasDisabled),
		},
	}
	
	return options
end

------------------------------------------------------------------------
--	General Options
------------------------------------------------------------------------
	
function module:CreateOptions(index, unit)
	local oufdefaults = LUI.defaults.profile.oUF[unit]
	local oufdb = db.oUF[unit]
	local ufNames = ufNamesList[unit]
	
	local ToggleFunc = function() LUI:GetModule("oUF"):Toggle(unit) end
	
	local disabledFunc = function()
		if not db.oUF.Settings.Enable then return true end
		
		if unit == "MaintankToT" then
			return not (db.oUF.MaintankTarget.Enable and db.oUF.Maintank.Enable)
		elseif unit == "MaintankTarget" then
			return not db.oUF.Maintank.Enable
		elseif unit == "PartyTarget" or unit == "PartyPet" then
			return not db.oUF.Party.Enable
		elseif unit == "ArenaTarget" or unit == "ArenaPet" then
			return not db.oUF.Arena.Enable
		else
			return false
		end
	end
	
	local disabledFunc2 = function() return (oufdb.Enable ~= nil and not oufdb.Enable or false) end
	
	local ToggleBlizz
	if unit == "Arena" then
		ToggleBlizz = function(self, Enable)
			if Enable == true then
				SetCVar("showArenaEnemyFrames", 1)
				LUI:GetModule("oUF"):EnableBlizzard("arena")
			else
				SetCVar("showArenaEnemyFrames", 0)
				oUF:DisableBlizzard("party")
			end
		end
	elseif unit == "Boss" then
		ToggleBlizz = function(self, Enable)
			if Enable == true then
				LUI:GetModule("oUF"):EnableBlizzard("boss")
			else
				for i = 1, MAX_BOSS_FRAMES do
					local boss = _G["Boss"..i.."TargetFrame"]
					boss.Show = function() end
					boss:Hide()
					boss:UnregisterAllEvents()
				end
			end
		end
	elseif unit == "Party" then
		ToggleBlizz = function(self, Enable)
			if Enable == true then
				LUI:GetModule("oUF"):EnableBlizzard("party")
			else
				oUF:DisableBlizzard("party")
			end
		end
	end
	
	local ChangePadding
	if unit == "Party" then
		ChangePadding = function() oUF_LUI_party:SetAttribute("yOffset", - tonumber(oufdb.Padding)) end
	elseif unit == "Maintank" then
		ChangePadding = function() oUF_LUI_maintank:SetAttribute("yOffset", - tonumber(oufdb.Padding)) end
	elseif unit == "Raid" then
		ChangePadding = function()
			for i = 1, 5 do
				_G["oUF_LUI_raid_25_"..i]:SetAttribute("yOffset", - tonumber(oufdb.Padding))
			end
			for i = 1, 8 do
				_G["oUF_LUI_raid_40_"..i]:SetAttribute("yOffset", - tonumber(oufdb.Padding))
			end
		end
	else
		ChangePadding = function()
			local parent = _G[ufNames[1]]
			for i = 2, ufNamesCount[unit] do
				local f = _G[ufNames[i]]
				if f and parent then
					f:ClearAllPoints()
					f:SetPoint("TOP", parent, "BOTTOM", 0, - tonumber(oufdb.Padding))
					parent = f
				end
			end
			parent:GetParent():GetScript("OnEvent")(parent:GetParent())
		end
	end
	
	local SetPosition
	if ufMover[unit] then
		SetPosition = function()
			if _G[ufMover[unit]] then
				local _, Anchor = _G[ufMover[unit]]:GetPoint(1)
				_G[ufMover[unit]]:ClearAllPoints()
				_G[ufMover[unit]]:SetPoint(oufdb.Point or "CENTER", Anchor, oufdb.Point or "CENTER", tonumber(oufdb.X), tonumber(oufdb.Y))
			end
		end
	else
		-- "child" frames like arenatargets, partytargets etc
		SetPosition = function()
			for _, frame in pairs(ufNames) do
				if _G[frame] then
					local _, Anchor = _G[frame]:GetPoint(1)
					_G[frame]:ClearAllPoints()
					_G[frame]:SetPoint(oufdb.Point, Anchor, oufdb.RelativePoint, tonumber(oufdb.X), tonumber(oufdb.Y))
				end
			end
		end
	end
	
	local ApplyHeightWidth = function()
		for _, frame in pairs(ufNames) do
			if _G[frame] then
				_G[frame]:SetHeight(tonumber(oufdb.Height))
				if unit == "Raid" and frame:find("oUF_LUI_raid_40") then
					_G[frame]:SetWidth((5 * tonumber(db.oUF.Raid.Height) - 3 * tonumber(db.oUF.Raid.GroupPadding)) / 8)
				else
					_G[frame]:SetWidth(tonumber(oufdb.Width))
				end
				if oufdb.Aura then
					if oufdb.Aura.buffs_enable then _G[frame].Buffs:SetWidth(tonumber(oufdb.Width)) end
					if oufdb.Aura.debuffs_enable then _G[frame].Debuffs:SetWidth(tonumber(oufdb.Width)) end
				end
			end
		end
		if unit == "Player" or unit == "Target" or unit == "Focus" then Forte:SetPosForte() end
		if unit == "Party" then
			oUF_LUI_party:SetAttribute("oUF-initialConfigFunction", [[
				local unit = ...
				if unit == "party" then
					self:SetHeight(]]..db.oUF.Party.Height..[[)
					self:SetWidth(]]..db.oUF.Party.Width..[[)
				elseif unit == "partytarget" then
					self:SetHeight(]]..db.oUF.PartyTarget.Height..[[)
					self:SetWidth(]]..db.oUF.PartyTarget.Width..[[)
					self:SetPoint("]]..db.oUF.PartyTarget.Point..[[", self:GetParent(), "]]..db.oUF.PartyTarget.RelativePoint..[[", ]]..db.oUF.PartyTarget.X..[[, ]]..db.oUF.PartyTarget.Y..[[)
				elseif unit == "partypet" then
					self:SetHeight(]]..db.oUF.PartyPet.Height..[[)
					self:SetWidth(]]..db.oUF.PartyPet.Width..[[)
					self:SetPoint("]]..db.oUF.PartyPet.Point..[[", self:GetParent(), "]]..db.oUF.PartyPet.RelativePoint..[[", ]]..db.oUF.PartyPet.X..[[, ]]..db.oUF.PartyPet.Y..[[)
				end
			]])
		elseif unit == "Maintank" then
			oUF_LUI_maintank:SetAttribute("oUF-initialConfigFunction", [[
				local unit = ...
				if unit == "raidtargettarget" then
					self:SetHeight(]]..db.oUF.MaintankToT.Height..[[)
					self:SetWidth(]]..db.oUF.MaintankToT.Width..[[)
					self:SetPoint("]]..db.oUF.MaintankToT.Point..[[", self:GetParent(), "]]..db.oUF.MaintankToT.RelativePoint..[[", ]]..db.oUF.MaintankToT.X..[[, ]]..db.oUF.MaintankToT.Y..[[)
				elseif unit == "raidtarget" then
					self:SetHeight(]]..db.oUF.MaintankTarget.Height..[[)
					self:SetWidth(]]..db.oUF.MaintankTarget.Width..[[)
					self:SetPoint("]]..db.oUF.MaintankTarget.Point..[[", self:GetParent(), "]]..db.oUF.MaintankTarget.RelativePoint..[[", ]]..db.oUF.MaintankTarget.X..[[, ]]..db.oUF.MaintankTarget.Y..[[)
				elseif unit == "raid" then
					self:SetHeight(]]..db.oUF.Maintank.Height..[[)
					self:SetWidth(]]..db.oUF.Maintank.Width..[[)
				end
			]])
		elseif unit == "Arena" then
			oUF_LUI_arena:GetScript("OnEvent")(oUF_LUI_arena)
		elseif unit == "Boss" then
			oUF_LUI_boss.UpdateBossFrame()
		elseif unit == "Raid" then
			local width40 = (5 * tonumber(db.oUF.Raid.Height) - 3 * tonumber(db.oUF.Raid.GroupPadding)) / 8
			
			for i = 1, 5 do
				_G["oUF_LUI_raid_25_"..i]:SetAttribute("initialConfigFunction", [[
					self:SetHeight(]]..db.oUF.Raid.Height..[[)
					self:SetWidth(]]..db.oUF.Raid.Width..[[)
				]])
				for j = 1, 5 do
					if _G["oUF_LUI_raid_25_"..i.."UnitButton"..j] then
						_G["oUF_LUI_raid_25_"..i.."UnitButton"..j]:SetHeight(tonumber(db.oUF.Raid.Height))
						_G["oUF_LUI_raid_25_"..i.."UnitButton"..j]:SetWidth(tonumber(db.oUF.Raid.Width))
					end
				end
			end
			for i = 1, 8 do
				_G["oUF_LUI_raid_40_"..i]:SetAttribute("initialConfigFunction", [[
					self:SetHeight(]]..db.oUF.Raid.Height..[[)
					self:SetWidth(]]..width40..[[)
				]])
				for j = 1, 5 do
					if _G["oUF_LUI_raid_40_"..i.."UnitButton"..j] then
						_G["oUF_LUI_raid_40_"..i.."UnitButton"..j]:SetHeight(tonumber(db.oUF.Raid.Height))
						_G["oUF_LUI_raid_40_"..i.."UnitButton"..j]:SetWidth(width40)
					end
				end
			end
		end
	end
	
	local ApplySettings = function()
		for _, frame in pairs(ufNames) do
			if _G[frame] then LUI.oUF.funcs.FrameBackdrop(_G[frame], _G[frame].__unit, db.oUF[unit]) end
		end
	end
	
	local ApplyInfoText = function()
		for _, frame in pairs(ufNames) do
			if _G[frame] then LUI.oUF.funcs.Info(_G[frame], _G[frame].__unit, db.oUF[unit]) end
		end
	end
	
	local ApplyCombatFeedback = function()
		for _, frame in pairs(ufNames) do
			if _G[frame] then LUI.oUF.funcs.CombatFeedbackText(_G[frame], _G[frame].__unit, db.oUF[unit]) end
		end
	end
	
	local DisabledCBText = function(text) return not oufdb.Castbar.Text[text].Enable end
	
	local ToggleCastbar = function(self, Enable)
		for _, frame in pairs(ufNames) do
			if _G[frame] then
				if not _G[frame].Castbar then LUI.oUF.funcs.Castbar(_G[frame], _G[frame].__unit, db.oUF[unit]) end
				if Enable == true then
					_G[frame]:EnableElement("Castbar")
				else
					_G[frame]:DisableElement("Castbar")
					_G[frame].Castbar:Hide()
				end
				_G[frame]:UpdateAllElements()
			end
		end
	end
	
	local ApplyCastbar = function()
		for _, frame in pairs(ufNames) do
			if _G[frame] then
				LUI.oUF.funcs.Castbar(_G[frame], _G[frame].__unit, db.oUF[unit])
				_G[frame]:UpdateAllElements()
			end
		end
	end
	
	local TestCastbar = function()
		if _G[ufNames[1]]:IsShown() then
			for _, frame in pairs(ufNames) do
				if _G[frame] and _G[frame].Castbar then
					_G[frame].Castbar.max = 60
					_G[frame].Castbar.duration = 0
					_G[frame].Castbar.delay = 0
					_G[frame].Castbar:SetMinMaxValues(0, 60)
					_G[frame].Castbar.casting = true
					_G[frame].Castbar.Text:SetText("Dummy Castbar")
					_G[frame].Castbar:Show()
				end
			end
		else
			LUI:Print("The "..unit.." Frame must be shown for the dummy castbar to work.")
		end
	end
	
	local DisabledPortrait = function() return not oufdb.Portrait.Enable end
	
	local TogglePortrait = function(self, Enable)
		for _, frame in pairs(ufNames) do
			if _G[frame] then
				if not _G[frame].Portrait then LUI.oUF.funcs.Portrait(_G[frame], _G[frame].__unit, db.oUF[unit]) end
				if Enable == true then
					_G[frame]:EnableElement("Portrait")
					_G[frame].Portrait:Show()
				else
					_G[frame].Portrait:Hide()
					_G[frame]:DisableElement("Portrait")
				end
				_G[frame]:UpdateAllElements()
			end
		end
	end
	
	local ApplyPortrait = function()
		for _, frame in pairs(ufNames) do
			if _G[frame] then LUI.oUF.funcs.Portrait(_G[frame], _G[frame].__unit, db.oUF[unit]) end
		end
	end
	
	local options = {
		name = unit,
		type = "group",
		order = index*2+10,
		disabled = disabledFunc,
		childGroups = "tab",
		args = {
			header = LUI:NewHeader(unit, 1),
			General = {
				name = "General",
				type = "group",
				order = 2,
				childGroups = "tab",
				args = {
					General = {
						name = "General",
						type = "group",
						order = 1,
						args = {
							Enable = (unit ~= "Player" and unit ~= "Target") and LUI:NewToggle("Enable", "Whether you want to use "..unit.." Frame or not.", 1, oufdb, "Enable", oufdefaults, ToggleFunc) or nil,
							UseBlizzard = (unit == "Party" or unit == "Boss" or unit == "Arena") and LUI:NewToggle("Use Blizzard "..unit.." Frames", "Whether you want to use Blizzard "..unit.." Frames or not.", 2, oufdb, "UseBlizzard", oufdefaults, ToggleBlizz, nil, function() return oufdb.Enable end) or nil,
							header = (unit == "Party" or unit == "Boss" or unit == "Arena" or unit == "Maintank") and LUI:NewHeader("General", 6) or nil,
							Padding = (unit == "Party" or unit == "Boss" or unit == "Arena" or unit == "Maintank") and LUI:NewInputNumber("Padding", "Choose the Padding between your "..unit.." Frames.", 7, oufdb, "Padding", oufdefaults, ChangePadding, nil, disabledFunc2) or nil,
							header2 = LUI:NewHeader("Frame Position", 8),
							XValue = LUI:NewPosX(unit.." Frame", 9, oufdb, "", oufdefaults, SetPosition, nil, disabledFunc2),
							YValue = LUI:NewPosY(unit.." Frame", 10, oufdb, "", oufdefaults, SetPosition, nil, disabledFunc2),
							Point = (not ufMover[unit] or unit == "Boss" or unit == "Party" or unit == "Maintank" or unit == "Arena" or unit == "Raid") and LUI:NewSelect("Point", "Choose the Point for your "..unit.." Frames.", 11, positions, nil, oufdb, "Point", oufdefaults, SetPosition, nil, disabledFunc2) or nil,
							RelativePoint = (not ufMover[unit]) and LUI:NewSelect("Relative Point", "Choose the Relative Point for your "..unit.." Frames.", 12, positions, nil, oufdb, "RelativePoint", oufdefaults, SetPosition, nil, disabledFunc2) or nil,
							header3 = LUI:NewHeader("Frame Height/Width", 13),
							Height = LUI:NewHeight(unit.." Frame", 14, oufdb, nil, oufdefaults, ApplyHeightWidth, nil, disabledFunc2),
							Width = LUI:NewWidth(unit.." Frame", 15, oufdb, nil, oufdefaults, ApplyHeightWidth, nil, disabledFunc2),
						},
					},
					Appearance = {
						name = "Appearance",
						type = "group",
						disabled = function() return (oufdb.Enable ~= nil and not oufdb.Enable or false) end,
						order = 2,
						args = {
							header = LUI:NewHeader("Backdrop Colors", 1),
							BackdropColor = LUI:NewColor("Backdrop", nil, 2, oufdb.Backdrop.Color, oufdefaults.Backdrop.Color, ApplySettings),
							BackdropBorderColor = LUI:NewColor("Border", nil, 3, oufdb.Border.Color, oufdefaults.Border.Color, ApplySettings),
							AggroGlow = (unit == "Player" or unit == "Target" or unit == "Focus" or unit == "Pet" or unit == "Maintank" or unit == "Party" or unit == "PartyPet" or unit == "Raid") and {
								name = "Aggro Glow",
								desc = "Whether you want the border color to change if the unit has aggro or not.",
								type = "toggle",
								get = function() return oufdb.Border.Aggro end,
								set = function(_, Enable)
										oufdb.Border.Aggro = Enable
										
										for _, frame in pairs(ufNames) do
											if _G[frame] then
												if not _G[frame].Threat then LUI.oUF.funcs.AggroGlow(_G[frame], _G[frame].__unit, db.oUF[unit]) end
												if Enable then
													_G[frame]:EnableElement("Threat")
												else
													_G[frame]:DisableElement("Threat")
													_G[frame].Threat:Hide()
												end
												_G[frame]:UpdateAllElements()
											end
										end
									end,
								order = 4,
							} or nil,
							header2 = LUI:NewHeader("Backdrop Settings", 5),
							BackdropTexture = LUI:NewSelect("Backdrop Texture", "Choose the Backdrop Texture.", 6, widgetLists.background, "LSM30_Background", oufdb.Backdrop, "Texture", oufdefaults.Backdrop, ApplySettings),
							BorderTexture = LUI:NewSelect("Border Texture", "Choose the Border Texture.", 7, widgetLists.border, "LSM30_Border", oufdb.Border, "EdgeFile", oufdefaults.Border, ApplySettings),
							BorderSize = LUI:NewSlider("Edge Size", "Choose the Edge Size for the Frame Border.", 8, oufdb.Border, "EdgeSize", oufdefaults.Border, 1, 50, 1, ApplySettings),
							header3 = LUI:NewHeader("Backdrop Padding", 9),
							PaddingLeft = LUI:NewInputNumber("Left", "Value for the left Backdrop Padding.", 10, oufdb.Backdrop.Padding, "Left", oufdefaults.Backdrop.Padding, ApplySettings, "half"),
							PaddingRight = LUI:NewInputNumber("Right", "Value for the right Backdrop Padding.", 11, oufdb.Backdrop.Padding, "Right", oufdefaults.Backdrop.Padding, ApplySettings, "half"),
							PaddingTop = LUI:NewInputNumber("Top", "Value for the top Backdrop Padding.", 12, oufdb.Backdrop.Padding, "Top", oufdefaults.Backdrop.Padding, ApplySettings, "half"),
							PaddingBottom = LUI:NewInputNumber("Bottom", "Value for the bottom Backdrop Padding.", 13, oufdb.Backdrop.Padding, "Bottom", oufdefaults.Backdrop.Padding, ApplySettings, "half"),
							header3 = LUI:NewHeader("Border Insets", 14),
							InsetLeft = LUI:NewInputNumber("Left", "Value for the left Border Inset.", 15, oufdb.Border.Insets, "Left", oufdefaults.Border.Insets, ApplySettings, "half"),
							InsetRight = LUI:NewInputNumber("Right", "Value for the right Border Inset.", 16, oufdb.Border.Insets, "Right", oufdefaults.Border.Insets, ApplySettings, "half"),
							InsetTop = LUI:NewInputNumber("Top", "Value for the Top Border Inset.", 17, oufdb.Border.Insets, "Top", oufdefaults.Border.Insets, ApplySettings, "half"),
							InsetBottom = LUI:NewInputNumber("Bottom", "Value for the bottom Border Inset.", 18, oufdb.Border.Insets, "Bottom", oufdefaults.Border.Insets, ApplySettings, "half"),
						},
					},
					AlphaFader = oufdb.Fader and {
						name = "Fader",
						type = "group",
						disabled = function()
								if unit == "Player" or unit == "Target" then
									return not db.Fader.Enable
								else
									return not oufdb.Enable or not db.Fader.Enable
								end
							end,
						order = 8,
						args = (LUI:GetModule("Fader", true) and LUI:GetModule("Fader", true):CreateFaderOptions(ufNames, oufdb.Fader, oufdefaults.Fader)) or {
							empty = {
								order = 1,
								width = "full",
								type = "description",
								name = "\nFader not found.",
							},
						},
					} or nil,
					CopySettings = LUI:GetModule("oUF_CopySettings") and LUI:GetModule("oUF_CopySettings"):CreateCopySettings(unit, 9) or nil,
				},
			},
			Bars = {
				name = "Bars",
				type = "group",
				childGroups = "tab",
				disabled = function() return (oufdb.Enable ~= nil and not oufdb.Enable or false) end,
				order = 3,
				args = {
					Health = module:CreateBarOptions(unit, 1, "Health"),
					Power = module:CreateBarOptions(unit, 2, "Power"),
					Full = module:CreateBarOptions(unit, 3, "Full"),
				},
			},
			Texts = {
				name = "Texts",
				type = "group",
				disabled = function() return (oufdb.Enable ~= nil and not oufdb.Enable or false) end,
				childGroups = "tab",
				order = 4,
				args = {
					Name = unit ~= "Raid" and {
						name = "Name",
						type = "group",
						order = 1,
						args = {
							Enable = LUI:NewToggle("Enable", "Whether you want to show the "..unit.." Name or not.", 1, oufdb.Texts.Name, "Enable", oufdefaults.Texts.Name, ApplyInfoText),
							FontSettings = {
								name = "Font Settings",
								type = "group",
								disabled = function() return not oufdb.Texts.Name.Enable end,
								guiInline = true,
								order = 2,
								args = {
									FontSize = LUI:NewSlider("Size", "Choose the "..unit.." Name Fontsize.", 1, oufdb.Texts.Name, "Size", oufdefaults.Texts.Name, 1, 40, 1, ApplyInfoText),
									empty = LUI:NewEmpty(2),
									Font = LUI:NewSelect("Font", "Choose the Font for "..unit.." Name.", 3, widgetLists.font, "LSM30_Font", oufdb.Texts.Name, "Font", oufdefaults.Texts.Name, ApplyInfoText),
									FontFlag = LUI:NewSelect("Font Flag", "Choose the Font Flag for "..unit.." Name.", 4, fontflags, nil, oufdb.Texts.Name, "Outline", oufdefaults.Texts.Name, ApplyInfoText),
									NameX = LUI:NewPosX(unit.." Name", 5, oufdb.Texts.Name, "", oufdefaults.Texts.Name, ApplyInfoText),
									NameY = LUI:NewPosY(unit.." Name", 6, oufdb.Texts.Name, "", oufdefaults.Texts.Name, ApplyInfoText),
									Point = LUI:NewSelect("Point", "Choose the Point for the "..unit.." Name.", 7, positions, nil, oufdb.Texts.Name, "Point", oufdefaults.Texts.Name, ApplyInfoText),
									RelativePoint = LUI:NewSelect("Relative Point", "Choose the Relative Point for the "..unit.." Name.", 8, positions, nil, oufdb.Texts.Name, "RelativePoint", oufdefaults.Texts.Name, ApplyInfoText),
								},
							},
							Settings = {
								name = "Settings",
								type = "group",
								disabled = function() return not oufdb.Texts.Name.Enable end,
								guiInline = true,
								order = 3,
								args = {
									Format = LUI:NewSelect("Format", "Choose the Format for your "..unit.." Name.", 1, nameFormat, nil, oufdb.Texts.Name, "Format", oufdefaults.Texts.Name, ApplyInfoText),
									Length = LUI:NewSelect("Length", "Choose the Length of your "..unit.." Name.", 2, nameLenghts, nil, oufdb.Texts.Name, "Length", oufdefaults.Texts.Name, ApplyInfoText),
									empty = LUI:NewEmpty(3),
									ColorNameByClass = LUI:NewToggle("Color Name by Class", "Whether you want to color the "..unit.." Name by Class or not.", 4, oufdb.Texts.Name, "ColorNameByClass", oufdefaults.Texts.Name, ApplyInfoText, "normal"),
									ColorClassByClass = LUI:NewToggle("Color Class by Class", "Whether you want to color the "..unit.." Class by Class or not.", 5, oufdb.Texts.Name, "ColorClassByClass", oufdefaults.Texts.Name, ApplyInfoText, "normal"),
									ColorLevelByDifficulty = LUI:NewToggle("Color Level by Difficulty", "Whether you want to color the Level by Difficulty or not.", 6, oufdb.Texts.Name, "ColorLevelByDifficulty", oufdefaults.Texts.Name, ApplyInfoText, "normal"),
									ShowClassification = LUI:NewToggle("Show Classifications", "Whether you want to show Classifications like Elite, Boss or not.", 7, oufdb.Texts.Name, "ShowClassification", oufdefaults.Texts.Name, ApplyInfoText, "normal"),
									ShortClassification = LUI:NewToggle("Short Classifications", "Whether you want to show short Classifications or not.", 8, oufdb.Texts.Name, "ShortClassification", oufdefaults.Texts.Name, ApplyInfoText),
									empty2 = LUI:NewEmpty(9),
									Color = LUI:NewColorNoAlpha("", "Name Text", 10, oufdb.Texts.Name.IndividualColor, oufdefaults.Texts.Name.IndividualColor, ApplyInfoText),
								},
							},
						},
					} or nil,
					Health = module:CreateTextOptions(unit, 2, "Health", "Value"),
					Power = module:CreateTextOptions(unit, 3, "Power", "Value"),
					HealthPercent = module:CreateTextOptions(unit, 4, "Health", "Percent"),
					PowerPercent = module:CreateTextOptions(unit, 5, "Power", "Percent"),
					HealthMissing = module:CreateTextOptions(unit, 6, "Health", "Missing"),
					PowerMissing = module:CreateTextOptions(unit, 7, "Power", "Missing"),
					CombatText = (unit == "Player" or unit == "Target" or unit == "Focus" or unit == "Pet" or unit == "ToT") and {
						name = "Combat",
						type = "group",
						order = 8,
						args = {
							Enable = LUI:NewToggle("Enable", "Whether you want to show Combat Text on the "..unit.." Frame or not.", 1, oufdb.Texts.Combat, "Enable", oufdefaults.Texts.Combat, ApplyCombatFeedback),
							FontSettings = {
								name = "Font Settings",
								type = "group",
								disabled = function() return not oufdb.Texts.Combat.Enable end,
								guiInline = true,
								order = 2,
								args = {
									FontSize = LUI:NewSlider("Size", "Choose the Combat Text Fontsize.", 1, oufdb.Texts.Combat, "Size", oufdefaults.Texts.Combat, 1, 40, 1, ApplyComatFeedback),
									empty = LUI:NewEmpty(2),
									Font = LUI:NewSelect("Font", "Choose the Combat Text Font.", 3, widgetLists.font, "LSM30_Font", oufdb.Texts.Combat, "Font", oufdefaults.Texts.Combat, ApplyCombatFeedback),
									FontFlag = LUI:NewSelect("Font Flag", "Choose the Combat Text Font Flag.", 4, fontflags, nil, oufdb.Texts.Combat, "Outline", oufdefaults.Texts.Combat, ApplyCombatFeedback),
									XValue = LUI:NewPosX("Combat Text", 5, oufdb.Texts.Combat, "", oufdefaults.Texts.Combat, ApplyCombatFeedback),
									YValue = LUI:NewPosY("Combat Text", 6, oufdb.Texts.Combat, "", oufdefaults.Texts.Combat, ApplyCombatFeedback),
									Point = LUI:NewSelect("Point", "Choose the Point for your "..unit.." Combat Text.", 7, positions, nil, oufdb.Texts.Combat, "Point", oufdefaults.Texts.Combat, ApplyCombatFeedback),
									RelativePoint = LUI:NewSelect("RelativePoint", "Choose the Relative Point for your "..unit.." Combat Text", 8, positions, nil, oufdb.Texts.Combat, "RelativePoint", oufdefaults.Texts.Combat, ApplyCombatFeedback),
								},
							},
						},
					} or nil,
				},
			},
			Castbar = (oufdb.Castbar) and {
				name = "Castbar",
				type = "group",
				disabled = function() return (oufdb.Enable ~= nil and not (oufdb.Enable and db.oUF.Settings.Castbars) or not db.oUF.Settings.Castbars) end,
				order = 4,
				childGroups = "tab",
				args = {
					header = LUI:NewHeader(unit.." Castbar", 1),
					General = {
						name = "General",
						type = "group",
						order = 2,
						args = {
							CastbarEnable = LUI:NewToggle("Enable", "Whether you want to show your "..unit.." Castbar or not.", 1, oufdb.Castbar, "Enable", oufdefaults.Castbar, ToggleCastbar),
							CastbarSize = {
								name = "Size/Position",
								type = "group",
								guiInline = true,
								disabled = function() return not oufdb.Castbar.Enable end,
								order = 2,
								args = {
									CastbarHeight = LUI:NewHeight("Castbar", 1, oufdb.Castbar, nil, oufdefaults.Castbar, ApplyCastbar),
									CastbarWidth = LUI:NewWidth("Castbar", 2, oufdb.Castbar, nil, oufdefaults.Castbar, ApplyCastbar),
									CastbarX = LUI:NewPosX("Castbar", 3, oufdb.Castbar, "", oufdefaults.Castbar, ApplyCastbar),
									CastbarY = LUI:NewPosY("Castbar", 4, oufdb.Castbar, "", oufdefaults.Castbar, ApplyCastbar),
								},
							},
							CastbarToggle = LUI:NewExecute("Show Dummy Castbar", "Show a Dummy Castbar for testing and positioning", 3, TestCastbar),
						},
					},
					CastbarColors = {
						name = "Colors",
						type = "group",
						disabled = function() return not oufdb.Castbar.Enable end,
						order = 3,
						args = {
							Colors = {
								name = "Castbar Colors",
								type = "group",
								guiInline = true,
								order = 1,
								args = {
									CBColorEnable = LUI:NewToggle("Individual Castbar Color", "Whether you want an individual Castbar Color or not.", 1, oufdb.Castbar, "IndividualColor", oufdefaults.Castbar, ApplyCastbar),
									CBColor = LUI:NewColor("Castbar", nil, 2, oufdb.Castbar.Colors.Bar, oufdefaults.Castbar.Colors.Bar, ApplyCastbar, nil, function() return not oufdb.Castbar.IndividualColor end),
									CBBGColor = LUI:NewColor("Castbar BG", nil, 3, oufdb.Castbar.Colors.Background, oufdefaults.Castbar.Colors.Background, ApplyCastbar, nil, function() return not oufdb.Castbar.IndividualColor end),
									CBBorderColor = LUI:NewColor("Castbar Border", nil, 5, oufdb.Castbar.Colors.Border, oufdefaults.Castbar.Colors.Border, ApplyCastbar, nil, function() return not oufdb.Castbar.IndividualColor end),
									empty = LUI:NewEmpty(6),
									CBNameColor = LUI:NewColorNoAlpha("Castbar Name Text", nil, 7, oufdb.Castbar.Colors.Name, oufdefaults.Castbar.Colors.Name, ApplyCastbar, nil, function() return not oufdb.Castbar.Text.Name.Enable end),
									CBTimeColor = LUI:NewColorNoAlpha("Castbar Time Text", nil, 8, oufdb.Castbar.Colors.Time, oufdefaults.Castbar.Colors.Time, ApplyCastbar, nil, function() return not oufdb.Castbar.Text.Time.Enable end),
								},
							},
							Textures = {
								name = "Castbar Textures",
								type = "group",
								guiInline = true,
								order = 2,
								args = {
									CBTexture = LUI:NewSelect("Bar Texture", "Choose the Castbar Texture.", 1, widgetLists.statusbar, "LSM30_Statusbar", oufdb.Castbar, "Texture", oufdefaults.Castbar, ApplyCastbar),
									CBTextureBG = LUI:NewSelect("Background Texture", "Choose the Castbar Background Texture.", 2, widgetLists.statusbar, "LSM30_Statusbar", oufdb.Castbar, "TextureBG", oufdefaults.Castbar, ApplyCastbar),
								},
							},
						},
					},
					CastbarTexts = {
						name = "Texts",
						type = "group",
						disabled = function() return not oufdb.Castbar.Enable end,
						order = 4,
						args = {
							header1 = LUI:NewHeader("Name Text", 1, "full"),
							CastbarName = LUI:NewToggle("Show Name Text", "Whether you want to show the Castbar Name Text or not.", 2, oufdb.Castbar.Text.Name, "Enable", oufdefaults.Castbar.Text.Name, ApplyCastbar),
							CastbarNameFont = LUI:NewSelect("Name Font", "Choose the Font for the Castbar Name Text.", 3, widgetLists.font, "LSM30_Font", oufdb.Castbar.Text.Name, "Font", oufdefaults.Castbar.Text.Name, ApplyCastbar, nil, DisabledCBText("Name")),
							CastbarNameFontsize = LUI:NewSlider("Size", "Choose the Castbar Name Text Fontsize.", 4, oufdb.Castbar.Text.Name, "Size", oufdefaults.Castbar.Text.Name, 10, 40, 1, ApplyCastbar, nil, DisabledCBText("Name")),
							CastbarNameOffsetX = LUI:NewOffsetX("Castbar Name Text", 5, oufdb.Castbar.Text.Name, "Offset", oufdefaults.Castbar.Text.Name, ApplyCastbar, nil, DisabledCBText("Name")),
							CastbarNameOffsetY = LUI:NewOffsetY("Castbar Name Text", 6, oufdb.Castbar.Text.Name, "Offset", oufdefaults.Castbar.Text.Name, ApplyCastbar, nil, DisabledCBText("Name")),
							header2 = LUI:NewHeader("Time Text", 7, "full"),
							CastbarTime = LUI:NewToggle("Show Time Text", "Whether you want to show the Castbar Time Text or not.", 8, oufdb.Castbar.Text.Time, "Enable", oufdefaults.Castbar.Text.Time, ApplyCastbar),
							CastbarTimeMax = LUI:NewToggle("Show Cast Time", "Whether you want to show the Castbar Cast Time or not.", 9, oufdb.Castbar.Text.Time, "ShowMax", oufdefaults.Castbar.Text.Time, ApplyCastbar, nil, DisabledCBText("Time")),
							CastbarTimeFont = LUI:NewSelect("Time Font", "Choose the Font for the Castbar Time Text.", 10, widgetLists.font, "LSM30_Font", oufdb.Castbar.Text.Time, "Font", oufdefaults.Castbar.Text.Name, ApplyCastbar, nil, function() return not oufdb.Castbar.Text.Time.Enable end),
							CastbarTimeFontsize = LUI:NewSlider("Size", "Choose the Castbar Time Text Fontsize.", 11, oufdb.Castbar.Text.Time, "Size", oufdefaults.Castbar.Text.Time, 10, 40, 1, ApplyCastbar, nil, DisabledCBText("Time")),
							CastbarTimeOffsetX = LUI:NewOffsetX("Castbar Time Text", 12, oufdb.Castbar.Text.Time, "Offset", oufdefaults.Castbar.Text.Time, ApplyCastbar, nil, DisabledCBText("Time")),
							CastbarTimeOffsetY = LUI:NewOffsetY("Castbar Time Text", 12, oufdb.Castbar.Text.Time, "Offset", oufdefaults.Castbar.Text.Time, ApplyCastbar, nil, DisabledCBText("Time")),
						},
					},
					CastbarBorder = {
						name = "Castbar Border",
						type = "group",
						disabled = function() return not oufdb.Castbar.Enable end,
						order = 5,
						args = {
							CBBorder = LUI:NewSelect("Border Texture", "Choose the Border Texture.", 1, widgetLists.border, "LSM30_Border", oufdb.Castbar.Border, "Texture", oufdefaults.Castbar.Border, ApplyCastbar),
							CBBorderThickness = LUI:NewInputNumber("Edge Size", "Value for your Castbar Border Edge Size", 2, oufdb.Castbar.Border, "Thickness", oufdefaults.Castbar.Border, ApplyCastbar, "half"),
							empty = LUI:NewEmpty(3),
							CBBorderInsetLeft = LUI:NewInputNumber("Left", "Value for the left Border Inset.", 4, oufdb.Castbar.Border.Inset, "left", oufdefaults.Castbar.Border.Inset, ApplyCastbar, "half"),
							CBBorderInsetRight = LUI:NewInputNumber("Right", "Value for the right Border Inset.", 5, oufdb.Castbar.Border.Inset, "right", oufdefaults.Castbar.Border.Inset, ApplyCastbar, "half"),
							CBBorderInsetTop = LUI:NewInputNumber("Top", "Value for the top Border Inset.", 6, oufdb.Castbar.Border.Inset, "top", oufdefaults.Castbar.Border.Inset, ApplyCastbar, "half"),
							CBBorderInsetBottom = LUI:NewInputNumber("Bottom", "Value for the bottom Border Inset.", 7, oufdb.Castbar.Border.Inset, "bottom", oufdefaults.Castbar.Border.Inset, ApplyCastbar, "half"),
						},
					},
				},
			} or nil,
			Aura = (oufdb.Aura) and {
				name = "Aura",
				type = "group",
				disabled = function() return (oufdb.Enable ~= nil and not oufdb.Enable or false) end,
				childGroups = "tab",
				order = 6,
				args = {
					header = LUI:NewHeader(unit.." Auras", 1),
					Buffs = module:CreateAuraOptions(unit, 2, false),
					Debuffs = module:CreateAuraOptions(unit, 3, true),
				},
			} or nil,
			Portrait = {
				name = "Portrait",
				type = "group",
				disabled = function() return (oufdb.Enable ~= nil and not oufdb.Enable or false) end,
				order = 7,
				args = {
					Enable = LUI:NewToggle("Enable", "Whether you want to show the Portrait or not.", 1, oufdb.Portrait, "Enable", oufdefaults.Portrait, TogglePortrait),
					Width = LUI:NewWidth("Portrait", 2, oufdb.Portrait, nil, oufdefaults.Portrait, ApplyPortrait, nil, DisabledPortrait),
					Height = LUI:NewHeight("Portrait", 3, oufdb.Portrait, nil, oufdefaults.Portrait, ApplyPortrait, nil, DisabledPortrait),
					X = LUI:NewPosX("Portrait", 4, oufdb.Portrait, "", oufdefaults.Portrait, ApplyPortrait, nil, DisabledPortrait),
					Y = LUI:NewPosY("Portrait", 5, oufdb.Portrait, "", oufdefaults.Portrait, ApplyPortrait, nil, DisabledPortrait),
					Alpha = LUI:NewSlider("Alpha", "Choose the Alpha for your Portrait.", 6, oufdb.Portrait, "Alpha", oufdefaults.Portrait, 0, 1, 0.05, ApplyPortrait, nil, DisabledPortrait),
				},
			},
			Icons = (oufdb.Icons) and {
				name = "Icons",
				type = "group",
				disabled = function() return (oufdb.Enable ~= nil and not oufdb.Enable or false) end,
				order = 8,
				childGroups = "tab",
				args = {
					Lootmaster = (unit ~= "Boss" and unit ~= "PartyPet" and unit ~= "PartyTarget" and unit ~= "MaintankTarget" and unit ~= "MaintankToT") and module:CreateIconOptions(unit, 1, "Lootmaster") or nil,
					Leader = (unit ~= "Boss" and unit ~= "PartyPet" and unit ~= "PartyTarget" and unit ~= "MaintankTarget" and unit ~= "MaintankToT") and module:CreateIconOptions(unit, 2, "Leader") or nil,
					LFDRole = (unit ~= "Boss" and unit ~= "PartyPet" and unit ~= "PartyTarget" and unit ~= "MaintankTarget" and unit ~= "MaintankToT") and module:CreateIconOptions(unit, 3, "Role") or nil,
					Raid = module:CreateIconOptions(unit, 4, "Raid"),
					PvP = (unit ~= "Boss" and unit ~= "PartyPet" and unit ~= "PartyTarget" and unit ~= "MaintankTarget" and unit ~= "MaintankToT" and unit ~= "Raid") and module:CreateIconOptions(unit, 5, "PvP") or nil,
				},
			} or nil,
		},
	}
	
	return options
end

function module:LoadOptions()
	local options = {}
	
	for index, unit in pairs(units) do
		options[unit] = module:CreateOptions(index, unit)
	end
	
	return options
end

function module:OnInitialize()	
	self.db = LUI.db.profile
	db = self.db
	
	Forte = LUI:GetModule("Forte")
	
	LUI:RegisterUnitFrame(self)
end
