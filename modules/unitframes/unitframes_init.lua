--[[
	Module.....: Minimap
	Description: Replace the default unitframes 
]]
-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Unitframes : LUIModule, AceHook-3.0, AceSerializer-3.0
local module = LUI:NewModule("Unitframes", "AceHook-3.0", "AceSerializer-3.0")
module.enableButton = true

module.unitsSpawn = {"player", "target", "focus", "focustarget", "targettarget", "targettargettarget", "pet", "pettarget", "boss", "party", "maintank", "arena", "raid"}

module.units = {"player", "target", "targettarget", "targettargettarget", "focus", "focustarget", "pet", "pettarget", "party", "partytarget", "partypet", "boss", "bosstarget", "maintank", "maintanktarget", "maintanktargettarget", "arena", "arenatarget", "arenapet", "raid"}

module.framelist = {
	player = {"oUF_LUI_player"},
	target = {"oUF_LUI_target"},
	targettarget = {"oUF_LUI_targettarget"},
	targettargettarget = {"oUF_LUI_targettargettarget"},
	focus = {"oUF_LUI_focus"},
	focustarget = {"oUF_LUI_focustarget"},
	pet = {"oUF_LUI_pet"},
	pettarget = {"oUF_LUI_pettarget"},
	party = {},
	partytarget = {},
	partypet = {},
	boss = {},
	bosstarget ={},
	maintank = {},
	maintanktarget = {},
	maintanktargettarget = {},
	arena = {},
	arenatarget = {},
	arenapet = {},
	raid = {},
}

local NameFormats = {
	party = "oUF_LUI_partyUnitButton%d",
	partytarget = "oUF_LUI_partyUnitButton%dtarget",
	partypet = "oUF_LUI_partyUnitButton%dpet",
	boss = "oUF_LUI_boss%d",
	bosstarget = "oUF_LUI_bosstarget%d",
	maintank = "oUF_LUI_maintankUnitButton%d",
	maintanktarget = "oUF_LUI_maintankUnitButton%dtarget",
	maintanktargettarget = "oUF_LUI_maintankUnitButton%dtargettarget",
	arena = "oUF_LUI_arena%d",
	arenatarget = "oUF_LUI_arenatarget%d",
	arenapet = "oUF_LUI_arenapet%d",
}

local Count = {
	party = 5,
	partytarget = 5,
	partypet = 5,
	boss = _G.MAX_BOSS_FRAMES or 5,
	bosstarget = _G.MAX_BOSS_FRAMES or 5,
	maintank = 4,
	maintanktarget = 4,
	maintanktargettarget = 4,
	arena = 5,
	arenatarget = 5,
	arenapet = 5,
}

-- adding group frames
for k, v in pairs(Count) do
	for i = 1, v do
		module.framelist[k][i] = string.format(NameFormats[k], i)
	end
end

for i = 1, 5 do
	for j = 1, 5 do
		table.insert(module.framelist.raid, "oUF_LUI_raid_25_"..i.."UnitButton"..j)
	end
end

for i = 1, 8 do
	for j = 1, 5 do
		table.insert(module.framelist.raid, "oUF_LUI_raid_40_"..i.."UnitButton"..j)
	end
end

-- ####################################################################################################################
-- ##### Default Settings #############################################################################################
-- ####################################################################################################################

module.childGroups = "tree"
module.defaults = { profile = {} }

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function module:Refresh()
	for _, unit in pairs(module.unitsSpawn) do
		self.ToggleUnit(unit)
	end

	-- Child frames (party target/pet, boss target, arena target/pet and the
	-- maintank chains) are spawned through their parent but have independent
	-- option pages and databases. Apply every unit database after the parents
	-- have created/enabled their children.
	for _, unit in pairs(module.units) do self.ApplySettings(unit) end

	if self.RefreshUnitframePreview then self:RefreshUnitframePreview() end
end

function module:OnInitialize()
	LUI:RegisterModule(module)
end

function module:OnEnable()
	LUI.Profiler.TraceScope(module, "Unitframes", "LUI", 2)
	for _, unit in pairs(module.unitsSpawn) do module.ToggleUnit(unit) end
end

function module:OnDisable()
	if self.StopUnitframePreview then self:StopUnitframePreview(true) end
	for _, unit in pairs(module.unitsSpawn) do module.ToggleUnit(unit, false) end
end
