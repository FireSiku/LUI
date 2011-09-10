--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: importexport.lua
	Description: oUF Import/Export Module
	Version....: 1.0
	Notes......: This module contains the functions and options for the import/export functions.
]]

local addonname, LUI = ...
local module = LUI:Module("oUF_ImportExport", "AceSerializer-3.0")
local oUFmodule = LUI:Module("oUF")
local Fader = LUI:Module("Fader")
local Forte = LUI:Module("Forte")
local ACR = LibStub("AceConfigRegistry-3.0")

local db

local importLayoutName

local layouts = {}

local _, class = UnitClass("player")

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

-- needed for secure copying of data, NO reference, ALL values!
local function CopyData(source, destination)
	for k, v in pairs(source) do
		if type(v) == "table" then
			if not destination[k] then destination[k] = {} end
			CopyData(source[k], destination[k])
		elseif k ~= "layout" then -- so the db.oUF.layout will not be copied
			destination[k] = source[k]
		end
	end
end

local function IsEmptyTable(data)
	if type(data) ~= "table" then return end
	for k, v in pairs(data) do
		return false
	end
	return true
end

local function CleanupData(data, default)
	if type(data) ~= "table" then return end
	for k, v in pairs(data) do
		if type(v) == "table" then
			if default[k] then
				CleanupData(data[k], default[k])
				if IsEmptyTable(data[k]) then data[k] = nil end
			else
				data[k] = nil
			end
		else
			if default[k] == data[k] or default[k] == nil then data[k] = nil end
		end
	end
end

local function ApplySettings(unit)
	local ufNames = ufNamesList[unit]
	
	oUFmodule:Toggle(unit)
	
	if db.oUF[unit].Enable == false then return end
	
	for _, framename in pairs(ufNames) do
		local frame = _G[framename]
		
		if frame then
			frame:SetWidth(tonumber(db.oUF[unit].Width))
			frame:SetHeight(tonumber(db.oUF[unit].Height))
			
			-- bars
			LUI.oUF_LUI.funcs.Health(frame, frame.__unit, db.oUF[unit])
			LUI.oUF_LUI.funcs.Power(frame, frame.__unit, db.oUF[unit])
			LUI.oUF_LUI.funcs.Full(frame, frame.__unit, db.oUF[unit])
			LUI.oUF_LUI.funcs.FrameBackdrop(frame, frame.__unit, db.oUF[unit])
			
			-- texts
			if unit == "Raid" then
				LUI.oUF_LUI.funcs.RaidInfo(frame, frame.__unit, db.oUF[unit])
			else
				LUI.oUF_LUI.funcs.Info(frame, frame.__unit, db.oUF[unit])
			end
			
			LUI.oUF_LUI.funcs.HealthValue(frame, frame.__unit, db.oUF[unit])
			LUI.oUF_LUI.funcs.HealthPercent(frame, frame.__unit, db.oUF[unit])
			LUI.oUF_LUI.funcs.HealthMissing(frame, frame.__unit, db.oUF[unit])
			
			LUI.oUF_LUI.funcs.PowerValue(frame, frame.__unit, db.oUF[unit])
			LUI.oUF_LUI.funcs.PowerPercent(frame, frame.__unit, db.oUF[unit])
			LUI.oUF_LUI.funcs.PowerMissing(frame, frame.__unit, db.oUF[unit])
			
			-- icons
			if db.oUF[unit].Icons then
				for key, icons in pairs(iconNamesList) do
					if db.oUF[unit].Icons[key] then
						if db.oUF[unit].Icons[key].Enable then
							LUI.oUF_LUI.funcs[icons[1]](frame, frame.__unit, db.oUF[unit])
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
				LUI.oUF_LUI.funcs.Experience(frame, frame.__unit, db.oUF.XP_Rep)
				LUI.oUF_LUI.funcs.Reputation(frame, frame.__unit, db.oUF.XP_Rep)
				
				if db.oUF.XP_Rep.Experience.Enable then
					frame.Experience:Show()
					if frame.Reputation then frame.Reputation:Hide() end
				else
					frame.Experience:Hide()
					if frame.Reputation then frame.Reputation:Show() end
				end
				
				-- swing
				LUI.oUF_LUI.funcs.Swing(frame, frame.__unit, db.oUF.Player)
				if db.oUF[unit].Swing.Enable then
					frame:EnableElement("Swing")
				else
					frame:DisableElement("Swing")
					frame.Swing:Hide()
				end
				
				-- vengeance
				if class == "WARRIOR" or class == "PALADIN" or class == "DRUID" or class == "DEATHKNIGHT" or class == "DEATH KNIGHT" then
					LUI.oUF_LUI.funcs.Vengeance(frame, frame.__unit, db.oUF.Player)
					if db.oUF[unit].Vengeance.Enable then
						frame:EnableElement("Vengeance")
					else
						frame:DisableElement("Vengeance")
						frame.Vengeance:Hide()
					end
				end
				
				-- totems
				if class == "SHAMAN" then
					LUI.oUF_LUI.funcs.TotemBar(frame, frame.__unit, db.oUF.Player)
					if db.oUF[unit].Totems.Enable then
						frame:EnableElement("TotemBar")
					else
						frame:DisableElement("TotemBar")
						frame.TotemBar:Hide()
					end
				end
				
				-- runes
				if class == "DEATHKNIGHT" or class == "DEATH KNIGHT" then
					LUI.oUF_LUI.funcs.Runes(frame, frame.__unit, db.oUF.Player)
					if db.oUF[unit].Runes.Enable then
						frame:EnableElement("Runes")
					else
						frame:DisableElement("Runes")
						frame.Runes:Hide()
					end
				end
				
				-- holy power
				if class == "PALADIN" then
					LUI.oUF_LUI.funcs.HolyPower(frame, frame.__unit, db.oUF.Player)
					if db.oUF[unit].HolyPower.Enable then
						frame:EnableElement("HolyPower")
					else
						frame:DisableElement("HolyPower")
						frame.HolyPower:Hide()
					end
				end
				
				-- soul shards
				if class == "WARLOCK" then
					LUI.oUF_LUI.funcs.SoulShards(frame, frame.__unit, db.oUF.Player)
					if db.oUF[unit].SoulShards.Enable then
						frame:EnableElement("SoulShards")
					else
						frame:DisableElement("SoulShards")
						frame.SoulShards:Hide()
					end
				end
				
				-- druid eclipse
				if class == "DRUID" then
					LUI.oUF_LUI.funcs.EclipseBar(frame, frame.__unit, db.oUF.Player)
					if db.oUF[unit].Eclipse.Enable then
						frame:EnableElement("EclipseBar")
					else
						frame:DisableElement("EclipseBar")
						frame.EclipseBar:Hide()
					end
				end
				
				-- druid mana bar
				if class == "DRUID" then
					LUI.oUF_LUI.funcs.DruidMana(frame, frame.__unit, db.oUF.Player)
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
				LUI.oUF_LUI.funcs.CPoints(frame, frame.__unit, db.oUF.Target)
				if db.oUF.Target.ComboPoints.Enable then
					frame:EnableElement("CPoints")
				else
					frame:DisableElement("CPoints")
					frame.CPoints:Hide()
				end
			end
			
			-- portrait
			if db.oUF[unit].Portrait and db.oUF[unit].Portrait.Enable then
				LUI.oUF_LUI.funcs.Portrait(frame, frame.__unit, db.oUF[unit])
				frame:EnableElement("Portrait")
				frame.Portrait:Show()
			else
				if frame.Portrait then
					frame:DisableElement("Portrait")
					frame.Portrait:Hide()
				end
			end
			
			-- alt power
			if unit == "Player" or unit == "Pet" then
				if db.oUF.Player.AltPower.Enable then
					LUI.oUF_LUI.funcs.AltPowerBar(frame, frame.__unit, db.oUF[unit])
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
					LUI.oUF_LUI.funcs.Buffs(frame, frame.__unit, db.oUF[unit])
				else
					if frame.Buffs then frame.Buffs:Hide() end
				end
				
				if db.oUF[unit].Auras.debuffs_enable then
					LUI.oUF_LUI.funcs.Debuffs(frame, frame.__unit, db.oUF[unit])
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
			if db.oUF[unit].Texts.Combat then LUI.oUF_LUI.funcs.CombatFeedbackText(frame, frame.__unit, db.oUF[unit]) end
			
			-- castbar
			if db.oUF.Settings.Castbars and db.oUF[unit].Castbar then
				if db.oUF[unit].Castbar.Enable then
					LUI.oUF_LUI.funcs.Castbar(frame, frame.__unit, db.oUF[unit])
					frame:EnableElement("Castbar")
				else
					frame:DisableElement("Castbar")
				end
			end
			
			-- aggro glow
			if db.oUF[unit].Border.Aggro then
				LUI.oUF_LUI.funcs.AggroGlow(frame, frame.__unit, db.oUF[unit])
				frame:EnableElement("Threat")
			else
				frame:DisableElement("Threat")
			end
			
			-- heal prediction
			if db.oUF[unit].HealPrediction then
				if db.oUF[unit].HealPrediction.Enable then
					LUI.oUF_LUI.funcs.HealPrediction(frame, frame.__unit, db.oUF[unit])
					frame:EnableElement("HealPrediction")
				else
					frame:DisableElement("HealPrediction")
				end
			end
			
			if unit == "ToT" or unit == "ToToT" or unit == "FocusTarget" or unit == "Focus" then
				if not frame.V2Tex then
					if unit == "ToT" then
						LUI.oUF_LUI.funcs.V2Textures(frame, oUF_LUI_target)
					elseif unit == "ToToT" then
						LUI.oUF_LUI.funcs.V2Textures(frame, oUF_LUI_targettarget)
					elseif unit == "FocusTarget" then
						LUI.oUF_LUI.funcs.V2Textures(frame, oUF_LUI_focus)
					elseif unit == "Focus" then
						LUI.oUF_LUI.funcs.V2Textures(frame, oUF_LUI_player)
					end
				end
				frame.V2Tex:Reposition()
				if db.oUF.Settings.show_v2_textures then frame.V2Tex:Show() else frame.V2Tex:Hide() end
			elseif unit == "PartyTarget" then
				if not frame.V2Tex then LUI.oUF_LUI.funcs.V2Textures(frame, _G["oUF_LUI_partyUnitButton"..frame:GetName():match("%d")]) end
				frame.V2Tex:Reposition()
				if db.oUF.Settings.show_v2_party_textures then frame.V2Tex:Show() else frame.V2Tex:Hide() end
			elseif unit == "ArenaTarget" then
				if not frame.V2Tex then LUI.oUF_LUI.funcs.V2Textures(frame, _G["oUF_LUI_arena"..frame:GetName():match("%d")]) end
				frame.V2Tex:Reposition()
				if db.oUF.Settings.show_v2_arena_textures then frame.V2Tex:Show() else frame.V2Tex:Hide() end
			elseif unit == "BossTarget" then
				if not frame.V2Tex then LUI.oUF_LUI.funcs.V2Textures(frame, _G["oUF_LUI_boss"..frame:GetName():match("%d")]) end
				frame.V2Tex:Reposition()
				if db.oUF.Settings.show_v2_boss_textures then frame.V2Tex:Show() else frame.V2Tex:Hide() end
			end
			
			-- fader
			if db.oUF[unit].Fader then
				if db.oUF[unit].Fader.Enable then
					Fader:RegisterFrame(frame, db.oUF[unit].Fader)
				else
					Fader:UnregisterFrame(frame)
				end
			end
			
			frame:UpdateAllElements()
		end
	end
end

function module:LoadLayout(layout)
	CopyData(LUI.defaults.profile.oUF, db.oUF)
	CopyData(LUI_Layouts[layout], db.oUF)
	
	for _, unit in pairs(units) do
		oUFmodule:Toggle(unit)
		ApplySettings(unit)
	end
	
	Forte:SetPosForte()
end

function module:CheckLayout()
	local layout
	for k, v in pairs(LUI_Layouts) do
		if db.oUF.layout == k then
			layout = k
		end
	end
	
	if not layout then
		layout = "LUI"
		db.oUF.layout = "LUI"
	end
end

function module:SaveLayout(layout)
	if layout == "" or layout == nil then return end
	if LUI_Layouts[layout] ~= nil then StaticPopup_Show("ALREADY_A_LAYOUT") return end
	
	LUI_Layouts[layout] = {}
	
	CopyData(db.oUF, LUI_Layouts[layout])
	CleanupData(LUI_Layouts[layout], LUI.defaults.profile.oUF)
	LUI_Layouts[layout].version = LUI.Versions.lui
	db.oUF.layout = layout
	ACR:NotifyChange("LUI")
end

function module:DeleteLayout(layout)
	if layout == "" or layout == nil then layout = db.oUF.layout end
	
	if layout == "LUI" then
		LUI:Print("THIS LAYOUT CAN NOT BE DELETED!!!")
		return
	end
	
	LUI_Layouts[layout] = nil
	db.oUF.layout = nil
	module:CheckLayout()
	module:LoadLayout(db.oUF.layout)
	ACR:NotifyChange("LUI")
end

function module:ImportLayoutName(name)
	if name == nil or name == "" then return end
	if LUI_Layouts[name] ~= nil then StaticPopup_Show("ALREADY_A_LAYOUT") return end
	importLayoutName = name
	StaticPopup_Show("IMPORT_LAYOUT_DATA")
end

function module:ImportLayoutData(str, name)
	if str == nil or str == "" then return end
	if name == nil or name == "" then
		if importLayoutName ~= nil then
			name = importLayoutName
		else
			LUI:Print("Invalid Layout Name")
		end
	end
	importLayoutName = nil
	if LUI_Layouts[name] ~= nil then StaticPopup_Show("ALREADY_A_LAYOUT") return end
	
	local valid, data = self:Deserialize(str)
	if not valid then
		LUI:Print("Error importing layout!")
		return
	end
	
	LUI_Layouts[name] = data
	CleanupData(LUI_Layouts[name], LUI.defaults.profile.oUF)
	
	if LUI_Layouts[name].version ~= LUI.Versions.lui then
		LUI:Print("This Layout was exported with a different version of LUI!")
	end
	
	db.oUF.layout = name
	module:LoadLayout(name)
	LUI:Print("Successfully imported "..name.." layout!")
	ACR:NotifyChange("LUI")
end

function module:ExportLayout(layout)
	if layout == "" or layout == nil then layout = db.oUF.layout end
	if LUI_Layouts[layout] == nil then return end
	
	local data = self:Serialize(LUI_Layouts[layout])
	if data == nil then return end
	local breakDown
	for i = 1, math.ceil(strlen(data)/100) do
		local part = (strsub(data, (((i-1)*100)+1), (i*100))).." "
		breakDown = (breakDown and breakDown or "")..part
	end
	return breakDown
end

function module:StaticPopups()
	StaticPopupDialogs["ALREADY_A_LAYOUT"] = {
		text = "That layout already exists.\nPlease choose another name.",
		button1 = "OK",
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		enterClicksFirstButton = true,
	}
	
	StaticPopupDialogs["SAVE_LAYOUT"] = {
		text = 'Enter the name for your new layout',
		button1 = "Save Layout",
		button2 = "Cancel",
		hasEditBox = 1,
		editBoxWidth = 150,
		maxLetters = 20,
		OnAccept = function(self)
				self:Hide()
				module:SaveLayout(self.editBox:GetText())
			end,
		EditBoxOnEnterPressed = function(self)
				self:GetParent():Hide()
				module:SaveLayout(self:GetText())
			end,
		EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
	
	StaticPopupDialogs["DELETE_LAYOUT"] = {
		text = 'Are you sure you want to delete the current layout?',
		button1 = "Yes",
		button2 = "No",
		OnAccept = function(self) module:DeleteLayout() end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
	
	StaticPopupDialogs["IMPORT_LAYOUT"] = {
		text = 'Enter a name for your new layout',
		button1 = "Continue",
		button2 = "Cancel",
		hasEditBox = 1,
		editBoxWidth = 150,
		maxLetters = 20,
		OnAccept = function(self)
				self:Hide()
				module:ImportLayoutName(self.editBox:GetText())
			end,
		EditBoxOnEnterPressed = function(self)
				self:GetParent():Hide()
				module:ImportLayoutName(self:GetText())
			end,
		EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
	
	StaticPopupDialogs["IMPORT_LAYOUT_DATA"] = {
		text = "Paste the new layout string here:",
		button1 = "Import Layout",
		button2 = "Cancel",
		hasEditBox = 1,
		editBoxWidth = 500,
		maxLetters = 100000,
		OnAccept = function(self)
				module:ImportLayoutData(self.editBox:GetText())
			end,
		EditBoxOnEnterPressed = function(self)
				self:GetParent():Hide()
				module:ImportLayoutData(self:GetText())
			end,
		EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
	
	StaticPopupDialogs["EXPORT_LAYOUT"] = {
		text = "Copy the following to share it with others:",
		button1 = "Close",
		hasEditBox = 1,
		editBoxWidth = 500,
		maxLetters = 100000,
		OnShow = function(self)
				self.editBox:SetText(module:ExportLayout())
				self.editBox:SetFocus()
				self.editBox:HighlightText()
			end,
		EditBoxOnEnterPressed = function(self) self:GetParent():Hide() end,
		EditBoxOnExitPressed = function(self) self:GetParent():Hide() end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
	
	StaticPopupDialogs["RESET_LAYOUTS"] = {
		text = "Are you sure you want to reset all your layouts?",
		button1 = "Yes",
		button2 = "No",
		OnAccept = function(self)
				LUI_Layouts = nil
				LUI_Layouts = layouts
				
				for k, v in pairs(layouts) do
					CleanupData(LUI_Layouts[k], LUI.defaults.profile.oUF)
				end
				
				if LUI_Layouts[db.oUF.layout] == nil then db.oUF.layout = "LUI" end
				module:CheckLayout()
				module:LoadLayout(db.oUF.layout)
				ACR:NotifyChange("LUI")
			end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
end

function module:LayoutArray()
	local LayoutArray = {}
	
	for t in pairs(LUI_Layouts) do
		table.insert(LayoutArray, t)
	end
	table.sort(LayoutArray)
	
	return LayoutArray
end

local defaults = {
	oUF = {
		layout = "LUI"
	}
}

function module:LoadOptions()
	local options = {
		Layout = {
			name = "Layout",
			type = "group",
			order = 2,
			childGroups = "tab",
			args = {
				Layout = {
					name = "Layout",
					type = "group",
					order = 1,
					args = {
						desc = LUI:NewDesc("This is the Layout import/export page. Here you can import and export oUF Layouts as you like.\nAttention! Sometimes importing a layout causes some lag, espacially if the layout differs strongly from the default LUI layout.", 1, "full"),
						empty = LUI:NewEmpty(2),
						SetLayout = {
							name = "Layout",
							desc = "Choose any Layout you prefer Most.",
							type = "select",
							values = function()
								local LayoutArray = module:LayoutArray()
								return LayoutArray
							end,
							get = function() 
								local LayoutArray = module:LayoutArray()
								
								for k, v in pairs(LayoutArray) do
									if tostring(v) == tostring(db.oUF.layout) then
										return k
									end
								end
							end,
							set = function(self, SetLayout)
								local LayoutArray = module:LayoutArray()
								
								for k, v in pairs(LayoutArray) do
									if k == SetLayout then
										if v ~= "" then
											db.oUF.layout = tostring(v)
											
											module:LoadLayout(db.oUF.layout)
										end
									end
								end
							end,
							order = 3,
						},
						empty = LUI:NewEmpty(4),
						SaveLayout = LUI:NewExecute("Save Layout", "Save your current unitframe settings as a new layout.", 5, function() StaticPopup_Show("SAVE_LAYOUT") end),
						DeleteLayout = LUI:NewExecute("Delete Layout", "Delete the active layout.", 6, function() StaticPopup_Show("DELETE_LAYOUT") end),
						empty2 = LUI:NewEmpty(7),
						ImportLayout = LUI:NewExecute("Import Layout", "Import a new layout into LUI", 8, function() StaticPopup_Show("IMPORT_LAYOUT") end),
						ExportLayout = LUI:NewExecute("Export Layout", "Export the current layout so you can share it with others.", 7, function() StaticPopup_Show("EXPORT_LAYOUT") end),
						empty3 = LUI:NewEmpty(9),
						ResetLayouts = LUI:NewExecute("Reset Layouts", "Reset all layouts back to defaults", 10, function() StaticPopup_Show("RESET_LAYOUTS") end),
					},
				},
			},
		},
	}

	return options
end

function module:OnInitialize()
	LUI:MergeDefaults(LUI.db.defaults.profile, defaults)
	LUI:RefreshDefaults()
	LUI:Refresh()

	self.db = LUI.db.profile
	db = self.db
	
	if LUICONFIG.Versions.layout ~= LUI.Versions.lui or not LUI_Layouts then
		LUI_Layouts = LUI_Layouts or {}
		
		layouts.LUI = {}
		
		for k, v in pairs(layouts) do
			LUI_Layouts[k] = nil
			LUI_Layouts[k] = v
			CleanupData(LUI_Layouts[k], LUI.defaults.profile.oUF)
			
			LUI_Layouts[k].version = LUI.Versions.lui
		end
		
		LUICONFIG.Versions.layout = LUI.Versions.lui
	end
	
	self:CheckLayout()
	self:StaticPopups()
	
	LUI:RegisterUnitFrame(self)
end
