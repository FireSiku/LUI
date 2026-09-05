-- Loot Spec Infotext

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Infotext
local module = LUI:GetModule("Infotext")
local element = module:NewElement("LootSpec", "AceEvent-3.0")

local GetSpecializationInfoByID = _G.GetSpecializationInfoByID
local GetSpecializationInfo = C_SpecializationInfo.GetSpecializationInfo
local GetLootSpecialization = _G.GetLootSpecialization
local GetSpecialization = C_SpecializationInfo.GetSpecialization

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

function element:SetLootSpec()
	local db = module.db.profile.LootSpec
	local lootSpec = GetLootSpecialization()
	local currentSpec = GetSpecialization()
	local specName
	if lootSpec == 0 and currentSpec then
		_, specName = GetSpecializationInfo(currentSpec)
	elseif lootSpec > 0 then
		_, specName = GetSpecializationInfoByID(lootSpec)
	end
	element.text = string.format("%s%s", db.Text, specName or _G.UNKNOWN)
end

element.RefreshSettings = element.SetLootSpec

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function element:OnCreate()
	element:RegisterEvent("PLAYER_LOOT_SPEC_UPDATED", "SetLootSpec")
	element:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", "SetLootSpec")
	element:RegisterEvent("PLAYER_ENTERING_WORLD", "SetLootSpec")
	element:SetLootSpec()
end
