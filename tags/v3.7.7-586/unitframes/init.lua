--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: init.lua
	Description: oUF Module Initialisation
]]

local addonname, LUI = ...
local module = LUI:Module("Unitframes", "AceHook-3.0", "AceEvent-3.0")
local Forte = LUI:Module("Forte")

local Blizzard = LUI.Blizzard

local unitsSpawn = {"Player", "Target", "Focus", "FocusTarget", "ToT", "ToToT", "Pet", "PetTarget", "Boss", "Party", "Maintank", "Arena", "Raid"}

local units = {"Player", "Target", "ToT", "ToToT", "Focus", "FocusTarget", "Pet", "PetTarget", "Party", "PartyTarget", "PartyPet", "Boss", "BossTarget", "Maintank", "MaintankTarget", "MaintankToT", "Arena", "ArenaTarget", "ArenaPet", "Raid"}

LUI.Versions.ouf = 3600

do
	module.framelist = {
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

	local Prefix = {
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
	local Suffix = {
		PartyTarget = "target",
		PartyPet = "pet",
		MaintankTarget = "target",
		MaintankToT = "targettarget",
	}
	local Count = {
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
	for k, v in pairs(module.framelist) do
		if Count[k] then
			for i = 1, Count[k] do
				module.framelist[k][i] = Prefix[k]..i..(Suffix[k] or "")
			end
		end
	end

	for i = 1, 5 do
		for j = 1, 5 do
			table.insert(module.framelist.Raid, "oUF_LUI_raid_25_"..i.."UnitButton"..j)
		end
	end

	for i = 1, 8 do
		for j = 1, 5 do
			table.insert(module.framelist.Raid, "oUF_LUI_raid_40_"..i.."UnitButton"..j)
		end
	end
end

module.childGroups = "tree"
module.defaults = {
	profile = {
		Enable = true,
	}
}

function module:LoadOptions()
	local options = {
		header = self:NewHeader("Unit Frames", 1),
		Settings = self:CreateSettings(2),
		Colors = self:CreateColorOptions(3),
		Layout = self:CreateImportExportOptions(4),
		XP_Rep = self:CreateXpRepOptions(5),
	}

	for index, unit in pairs(units) do
		options[unit] = self:CreateUnitOptions(unit, index)
	end

	return options
end

function module:Refresh()
	for _, unit in pairs(unitsSpawn) do
		self.ToggleUnit(unit)
		self.ApplySettings(unit)
	end

	Forte:SetPosForte()
end

function module:OnInitialize()
	LUI:NewNamespace(self, true)

	-- look for old namespace and convert
	if _G.LUI_Layouts then
		module.db.global = _G.LUI_Layouts
		_G.LUI_Layouts = nil
	end

	if LUI.db.profile.oUF then
		local MoveOver
		function MoveOver(data, prior, stackstring)
			if type(data) ~= "table" then return end
			if type(prior) ~= "table" then return end
			for k, v in pairs(prior) do
				if type(prior[k]) == "table" and type(data[k]) == "table" then
					MoveOver(data[k], prior[k], stackstring.."."..k)
				elseif prior[k] ~= nil and data[k] ~= nil then
					if type(data[k]) == "number" then
						data[k] = tonumber(prior[k])
					else
						data[k] = prior[k]
					end
				else
					print("Lost Data: "..stackstring.."."..k.." = "..type(data[k])..","..type(prior[k]))
					print(prior[k])
					print(data[k])
				end
			end
		end

		local Bars = {"Health", "Power", "Full", "DruidMana", "Totems", "Runes", "HolyPower", "WarlockBar", "Eclipse", "AltPower", "HealPrediction", "ComboPoints", "ShadowOrbs", "ArcaneCharges"}

		local checkauras = {
			Enable = "_enable",
			X = "X",
			Y = "Y",
			InitialAnchor = "_initialAnchor",
			GrowthX = "_growthX",
			GrowthY = "_growthY",
			Size = "_size",
			Spacing = "_spacing",
			Num = "_num",
			ColorByType = "_colorbytype",
			PlayerOnly = "_playeronly",
			IncludePet = "_includepet",
			AuraTimer = "_auratimer",
			DisableCooldown = "_disableCooldown",
			CooldownReverse = "_cooldownReverse",
		}

		for key, data in pairs(LUI.db.profile.oUF) do
			if type(data) == "table" and data.Health then
				data.Bars = {}

				for _, v in pairs(Bars) do
					if data[v] then
						data.Bars[v] = data[v]
						data[v] = nil
					end
				end

				for k, v in pairs(data.Bars) do
					if v.Text then
						data.Texts[k] = data.Bars[k].Text
						data.Bars[k].Text = nil
					end
				end

				if data.Bars.Full and data.Bars.Full.Color then
					data.Bars.Full.IndividualColor = data.Bars.Full.Color
					data.Bars.Full.Color = nil
				end

				if data.Aura then
					for _, type in pairs({"Buffs", "Debuffs"}) do
						data.Aura[type] = {}
						for k, v in pairs(checkauras) do
							if data.Aura[strlower(type)..v] ~= nil then
								data.Aura[type][k] = data.Aura[strlower(type)..v]
								data.Aura[strlower(type)..v] = nil
							end
						end
					end
				end

				if data.Castbar then
					for k, v in pairs(data.Castbar) do
						data.Castbar.General = {}
						if type(v) ~= "table" then
							data.Castbar.General[k] = data.Castbar[k]
							data.Castbar[k] = nil
						end
					end

					if data.Castbar.Colors and data.Castbar.Colors.Shield and data.Castbar.Colors.Shield.Enable ~= nil then
						data.Castbar.General.Shield = data.Castbar.Colors.Shield.Enable
						data.Castbar.Colors.Shield.Enable = nil
					end
				end
			end
		end

		for _, unit in pairs({"Player", "Target", "ToT", "ToToT", "Focus", "FocusTarget", "Pet", "PetTarget", "Party", "PartyTarget", "PartyPet", "Boss", "BossTarget", "Maintank", "MaintankTarget", "MaintankToT", "Arena", "ArenaTarget", "ArenaPet", "Raid"}) do
			MoveOver(module.db.profile[unit], LUI.db.profile.oUF[unit], "module.db.profile."..unit)
		end

		LUI.db.profile.oUF = nil
	end
end

function module:OnEnable()
	for _, unit in pairs(unitsSpawn) do module.ToggleUnit(unit) end

	Forte:SetPosForte()
end

function module:OnDisable()
	for _, unit in pairs(unitsSpawn) do module.ToggleUnit(unit, false) end

	if module.db.Settings.HideBlizzRaid then
		Blizzard:Hide("raid")
	end
end

