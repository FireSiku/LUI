--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: init.lua
	Description: oUF Module Initialisation
]]

local addonname, LUI = ...
local module = LUI:Module("Unitframes", "AceHook-3.0", "AceEvent-3.0")

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
end

function module:OnInitialize()
	LUI:NewNamespace(self, true)
end

function module:OnEnable()
	for _, unit in pairs(unitsSpawn) do module.ToggleUnit(unit) end
end

function module:OnDisable()
	for _, unit in pairs(unitsSpawn) do module.ToggleUnit(unit, false) end

	if module.db.Settings.HideBlizzRaid then
		Blizzard:Hide("raid")
	end
end

