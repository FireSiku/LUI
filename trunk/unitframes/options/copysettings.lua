--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: copysettings.lua
	Description: oUF CopySettings Module
	Version....: 1.0
	Notes......: This module contains the functions and options for the settings copy functions.
]]

local _, ns = ...
local oUF = ns.oUF or oUF

local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local module = LUI:NewModule("oUF_CopySettings")
local Fader = LUI:GetModule("Fader", true)

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

local iconNamesList = {
	PvP = {"PvP"},
	Combat = {"Combat"},
	Resting = {"Resting"},
	Lootmaster = {"MasterLooter"},
	Leader = {"Leader", "Assistant"},
	Role = {"LFDRole"},
	Raid = {"RaidIcon"},
}

local function ApplySettings(unit)
	local ufNames = ufNamesList[unit]
	
	LUI:GetModule("oUF"):Toggle(unit)
	
	if db.oUF[unit].Enable == false then return end
	
	for _, framename in pairs(ufNames) do
		local frame = _G[framename]
		
		if frame then
			frame:SetWidth(tonumber(db.oUF[unit].Width))
			frame:SetHeight(tonumber(db.oUF[unit].Height))
			
			-- bars
			LUI.oUF.funcs.Health(frame, frame.__unit, db.oUF[unit])
			LUI.oUF.funcs.Power(frame, frame.__unit, db.oUF[unit])
			LUI.oUF.funcs.Full(frame, frame.__unit, db.oUF[unit])
			LUI.oUF.funcs.FrameBackdrop(frame, frame.__unit, db.oUF[unit])
			
			-- texts
			LUI.oUF.funcs.Info(frame, frame.__unit, db.oUF[unit])
			
			LUI.oUF.funcs.HealthValue(frame, frame.__unit, db.oUF[unit])
			LUI.oUF.funcs.HealthPercent(frame, frame.__unit, db.oUF[unit])
			LUI.oUF.funcs.HealthMissing(frame, frame.__unit, db.oUF[unit])
			
			LUI.oUF.funcs.PowerValue(frame, frame.__unit, db.oUF[unit])
			LUI.oUF.funcs.PowerPercent(frame, frame.__unit, db.oUF[unit])
			LUI.oUF.funcs.PowerMissing(frame, frame.__unit, db.oUF[unit])
			
			-- icons
			if db.oUF[unit].Icons then
				for key, icons in pairs(iconNamesList) do
					if db.oUF[unit].Icons[key] then
						if db.oUF[unit].Icons[key].Enable then
							LUI.oUF.funcs[icons[1]](frame, frame.__unit, db.oUF[unit])
							frame:EnableElement(icons[1])
							if icons[2] then frame:EnableElement(icons[2]) end
						else
							if frame[icons[1]] then
								for _, icon in pairs(icons) do
									frame:DisableElement(icon)
								end
							end
						end
					end
				end
			end
			
			-- player specific
			if unit == "Player" then
				-- exp/rep
				LUI.oUF.funcs.Experience(frame, frame.__unit, db.oUF.XP_Rep)
				LUI.oUF.funcs.Reputation(frame, frame.__unit, db.oUF.XP_Rep)
				
				if db.oUF.XP_Rep.Experience.Enable then
					frame.Experience:Show()
					if frame.Reputation then frame.Reputation:Hide() end
				else
					frame.Experience:Hide()
					if frame.Reputation then frame.Reputation:Show() end
				end
				
				-- swing
				LUI.oUF.funcs.Swing(frame, frame.__unit, db.oUF.Player)
				if db.oUF[unit].Swing.Enable then
					frame:EnableElement("Swing")
				else
					frame:DisableElement("Swing")
					frame.Swing:Hide()
				end
				
				-- vengeance
				if class == "WARRIOR" or class == "PALADIN" or class == "DRUID" or class == "DEATHKNIGHT" or class == "DEATH KNIGHT" then
					LUI.oUF.funcs.Vengeance(frame, frame.__unit, db.oUF.Player)
					if db.oUF[unit].Vengeance.Enable then
						frame:EnableElement("Vengeance")
					else
						frame:DisableElement("Vengeance")
						frame.Vengeance:Hide()
					end
				end
				
				-- totems
				if class == "SHAMAN" then
					LUI.oUF.funcs.TotemBar(frame, frame.__unit, db.oUF.Player)
					if db.oUF[unit].Totems.Enable then
						frame:EnableElement("TotemBar")
					else
						frame:DisableElement("TotemBar")
						frame.TotemBar:Hide()
					end
				end
				
				-- runes
				if class == "DEATHKNIGHT" or class == "DEATH KNIGHT" then
					LUI.oUF.funcs.Runes(frame, frame.__unit, db.oUF.Player)
					if db.oUF[unit].Runes.Enable then
						frame:EnableElement("Runes")
					else
						frame:DisableElement("Runes")
						frame.Runes:Hide()
					end
				end
				
				-- holy power
				if class == "PALADIN" then
					LUI.oUF.funcs.HolyPower(frame, frame.__unit, db.oUF.Player)
					if db.oUF[unit].HolyPower.Enable then
						frame:EnableElement("HolyPower")
					else
						frame:DisableElement("HolyPower")
						frame.HolyPower:Hide()
					end
				end
				
				-- soul shards
				if class == "WARLOCK" then
					LUI.oUF.funcs.SoulShards(frame, frame.__unit, db.oUF.Player)
					if db.oUF[unit].SoulShards.Enable then
						frame:EnableElement("SoulShards")
					else
						frame:DisableElement("SoulShards")
						frame.SoulShards:Hide()
					end
				end
				
				-- druid eclipse
				if class == "DRUID" then
					LUI.oUF.funcs.EclipseBar(frame, frame.__unit, db.oUF.Player)
					if db.oUF[unit].Eclipse.Enable then
						frame:EnableElement("EclipseBar")
					else
						frame:DisableElement("EclipseBar")
						frame.EclipseBar:Hide()
					end
				end
				
				-- druid mana bar
				if class == "DRUID" then
					LUI.oUF.funcs.DruidMana(frame, frame.__unit, db.oUF.Player)
					if db.oUF[unit].DruidMana.Enable then
						frame:EnableElement("DruidMana")
					else
						frame:DisableElement("DruidMana")
						frame.DruidMana.SetPosition()
					end
				end
			end
			
			-- target specific
			if unit == "Target" then
				LUI.oUF.funcs.CPoints(frame, frame.__unit, db.oUF.Target)
				if db.oUF.Target.ComboPoints.Enable then
					frame:EnableElement("CPoints")
				else
					frame:DisableElement("CPoints")
					frame.CPoints:Hide()
				end
			end
			
			-- portrait
			if db.oUF[unit].Portrait and db.oUF[unit].Portrait.Enable then
				LUI.oUF.funcs.Portrait(frame, frame.__unit, db.oUF[unit])
				frame:EnableElement("Portrait")
			else
				if frame.Portrait then frame:DisableElement("Portrait") end
			end
			
			-- alt power
			if unit == "Player" or unit == "Pet" then
				if db.oUF.Player.AltPower.Enable then
					LUI.oUF.funcs.AltPowerBar(frame, frame.__unit, db.oUF[unit])
					frame:EnableElement("AltPowerBar")
					frame.AltPowerBar.SetPosition()
				else
					if frame.AltPowerBar then
						frame:DisableElement("AltPowerBar")
						frame.AltPowerBar.SetPosition()
					end
				end
			end
			
			-- auras
			if db.oUF[unit].Auras then
				if db.oUF[unit].Auras.buffs_enable then
					LUI.oUF.funcs.Buffs(frame, frame.__unit, db.oUF[unit])
				else
					if frame.Buffs then frame.Buffs:Hide() end
				end
				
				if db.oUF[unit].Auras.debuffs_enable then
					LUI.oUF.funcs.Debuffs(frame, frame.__unit, db.oUF[unit])
				else
					if frame.Debuffs then Frame.Debuffs:Hide() end
				end
				
				if db.oUF[unit].Auras.buffs_enable or db.oUF[unit].Auras.debuffs_enable then
					frame:EnableElement("Auras")
				else
					frame:DisableElement("Auras")
				end
			end
			
			-- combat feedback text
			if db.oUF[unit].Texts.Combat then LUI.oUF.funcs.CombatFeedbackText(frame, frame.__unit, db.oUF[unit]) end
			
			-- castbar
			if db.oUF.Settings.Castbars and db.oUF[unit].Castbar then
				if db.oUF[unit].Castbar.Enable then
					LUI.oUF.funcs.Castbar(frame, frame.__unit, db.oUF[unit])
					frame:EnableElement("Castbar")
				else
					frame:DisableElement("Castbar")
				end
			end
			
			-- aggro glow
			if db.oUF[unit].Border.Aggro then
				LUI.oUF.funcs.AggroGlow(frame, frame.__unit, db.oUF[unit])
				frame:EnableElement("Threat")
			else
				frame:DisableElement("Threat")
			end
			
			-- heal prediction
			if db.oUF[unit].HealPrediction then
				if db.oUF[unit].HealPrediction.Enable then
					LUI.oUF.funcs.HealPrediction(frame, frame.__unit, db.oUF[unit])
					frame:EnableElement("HealPrediction")
				else
					frame:DisableElement("HealPrediction")
				end
			end
			
			if frame.V2Tex then frame.V2Tex:Reposition() end
			if frame._V2Tex then frame._V2Tex:Reposition() end
			
			-- fader
			if db.oUF[unit].Fader then
				if db.oUF[unit].Fader.Enable then
					LUI:GetModule("Fader", true):RegisterFrame(frame, db.oUF[unit].Fader)
				else
					LUI:GetModule("Fader", true):UnregisterFrame(frame)
				end
			end
			
			frame:UpdateAllElements()
		end
	end
	
	if unit == "Player" or unit == "Target" then LUI:GetModule("Forte"):SetPosForte() end
end

local function CopySettings(srcTable, dstTable, withSizes, withPosition)
	if type(srcTable) ~= "table" then return end
	if type(dstTable) ~= "table" then return end
	
	for k, v in pairs(srcTable) do
		if dstTable[k] ~= nil then
			if type(srcTable[k]) == "table" then
				CopySettings(srcTable[k], dstTable[k], withSizes, withPosition)
			elseif srcTable[k] ~= nil and dstTable[k] ~= nil then
				if k == "Height" or k == "Width" then
					if withSizes then dstTable[k] = srcTable[k] end
				elseif k == "Point" or k == "RelativePoint" or k == "X" or k == "Y" then
					if withPosition then dstTable[k] = srcTable[k] end
				else
					dstTable[k] = srcTable[k]
				end
			end
		end
	end
end

local CopyFuncs = {
	Castbar = function(srcUnit, dstUnit, withSizes, withPosition)
		CopySettings(db.oUF[srcUnit].Aura, db.oUF[dstUnit].Aura, withSizes, withPosition)
	end,
	
	Aura = function(srcUnit, dstUnit, withSizes, withPosition)
		CopySettings(db.oUF[srcUnit].Castbar, db.oUF[dstUnit].Castbar, withSizes, withPosition)
	end,
	
	Bars = function(srcUnit, dstUnit, withSizes, withPosition)
		CopySettings(db.oUF[srcUnit].Health, db.oUF[dstUnit].Health, withSizes, withPosition)
		CopySettings(db.oUF[srcUnit].Power, db.oUF[dstUnit].Power, withSizes, withPosition)
		CopySettings(db.oUF[srcUnit].Full, db.oUF[dstUnit].Full, withSizes, withPosition)
		CopySettings(db.oUF[srcUnit].HealPrediction, db.oUF[dstUnit].HealPrediction, withSizes, withPosition)
	end,
	
	Icons = function(srcUnit, dstUnit, withSizes, withPosition)
		CopySettings(db.oUF[srcUnit].Icons, db.oUF[dstUnit].Icons, withSizes, withPosition)
	end,
	
	Background = function(srcUnit, dstUnit, withSizes, withPosition)
		CopySettings(db.oUF[srcUnit].Backdrop, db.oUF[dstUnit].Backdrop, withSizes, withPosition)
		CopySettings(db.oUF[srcUnit].Border, db.oUF[dstUnit].Border, withSizes, withPosition)
	end,
	
	Texts = function(srcUnit, dstUnit, withSizes, withPosition)
		CopySettings(db.oUF[srcUnit].Texts, db.oUF[dstUnit].Texts, withSizes, withPosition)
	end,
	
	Portrait = function(srcUnit, dstUnit, withSizes, withPosition)
		CopySettings(db.oUF[srcUnit].Portrait, db.oUF[dstUnit].Portrait, withSizes, withPosition)
	end,
	
	Fader = function(srcUnit, dstUnit, withSizes, withPosition)
		CopySettings(db.oUF[srcUnit].Fader, db.oUF[dstUnit].Fader, withSizes, withPosition)
	end,
	
	All = function(srcUnit, dstUnit, withSizes, withPosition)
		CopySettings(db.oUF[srcUnit], db.oUF[dstUnit], withSizes, withPosition)
	end
}

local settings = {
	toCopy = "All",
	srcUnit = "Player",
	dstUnit = "Target",
	withSizes = false,
	withPosition = false
}
	
StaticPopupDialogs["COPY_SETTINGS"] = {
	text = "Are you sure you want to copy the Settings?",
	button1 = "Yes",
	button2 = "No",
	OnAccept = function(self)
			CopyFuncs[settings.toCopy](settings.srcUnit, settings.dstUnit, settings.withSizes, settings.withPosition)
			ApplySettings(settings.dstUnit)
		end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}
	
function module:CreateCopySettings(unit, order)
	if unit == "Raid" then return nil end
	
	local oufdb = db.oUF[unit]
	local ufNames = ufNamesList[unit]
	
	local options = {
		name = "Copy Settings",
		type = "group",
		disabled = function() return (oufdb.Enable ~= nil and not oufdb.Enable or false) end,
		order = order,
		args = {
			desc = LUI:NewDesc("This is the Unitframe copysettings page. Here you can choose which settings you want to copy from this or to this unitframe.", 1, "full"),
			empty = LUI:NewEmpty(2),
			Paste = LUI:NewExecute("Paste Settings", "Paste the chosen Settings.", 3, function() settings.dstUnit = unit; StaticPopup_Show("COPY_SETTINGS") end, nil, function() return (settings.toCopy == nil) end),
			empty = LUI:NewEmpty(4),
			Sizes = LUI:NewToggle("Include Sizes", "Whether you want to include Sizes in the Copy/Paste or not. This option is global for all frames.", 5, settings, "withSizes", nil, function() return end),
			Position = LUI:NewToggle("Include Positions", "Whether you want to include Positions in the Copy/Paste or not. This option is global for all frames.", 6, settings, "withPosition", nil, function() return end),
			empty = LUI:NewEmpty(7),
			Castbar = oufdb.Castbar and LUI:NewExecute("Copy Castbar", "Move the Castbar Settings of this Unitframe into the temporary storage.", 8, function() settings.toCopy = "Castbar"; settings.srcUnit = unit end) or nil,
			Aura = oufdb.Aura and LUI:NewExecute("Copy Aura", "Move the Aura Settings of this Unitframe into the temporary storage.", 9, function() settings.toCopy = "Aura"; settings.srcUnit = unit end) or nil,
			Bars = LUI:NewExecute("Copy Bars", "Move the Bar Settings of this Unitframe into the temporary storage.", 10, function() settings.toCopy = "Bars"; settings.srcUnit = unit end),
			Icons = oufdb.Icons and LUI:NewExecute("Copy Icons", "Move the Icon Settings of this Unitframe into the temporary storage.", 11, function() settings.toCopy = "Icons"; settings.srcUnit = unit end) or nil,
			Background = LUI:NewExecute("Copy Background", "Move the Background Settings of this Unitframe into the temporary storage.", 12, function() settings.toCopy = "Background"; settings.srcUnit = unit end),
			Texts = oufdb.Texts and LUI:NewExecute("Copy Texts", "Move the Text Settings of this Unitframe into the temporary storage.", 13, function() settings.toCopy = "Texts"; settings.srcUnit = unit end) or nil,
			Portrait = LUI:NewExecute("Copy Portrait", "Move the Portrait Settings of this Unitframe into the temporary storage.", 14, function() settings.toCopy = "Portrait"; settings.srcUnit = unit end),
			Fader = oufdb.Fader and LUI:NewExecute("Copy Fader", "Move the Fader Settings of this Unitframe into the temporary storage.", 15, function() settings.toCopy = "Fader"; settings.srcUnit = unit end) or nil,
			All = LUI:NewExecute("Copy All", "Move all Settings of this Unitframe into the temporary storage.", 16, function() settings.toCopy = "All"; settings.srcUnit = unit end),
		},
	}
	
	return options
end

function module:OnInitialize()	
	self.db = LUI.db.profile
	db = self.db
end
