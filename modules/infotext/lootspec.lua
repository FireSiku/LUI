-- Loot Spec Infotext

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, LUIAddon
local _, LUI = ...
local L = LUI.L

---@type InfotextModule
local module = LUI:GetModule("Infotext")
local element = module:NewElement("LootSpec", "AceEvent-3.0")

local GetSpecializationInfoByID = _G.GetSpecializationInfoByID
local GetSpecializationInfo = _G.GetSpecializationInfo
local GetLootSpecialization = _G.GetLootSpecialization
local GetSpecialization = _G.GetSpecialization

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

function element:SetLootSpec()
    local db = module.db.profile
    local lootspec = GetLootSpecialization()
    local curspec = GetSpecialization()
    local role
        if lootspec == 0 then
            _, _, _, _, role = GetSpecializationInfo(curspec)
        else
            _, _, _, _, role = GetSpecializationInfoByID(lootspec)
        end
        element.text = string.format("%s %s", db.LootSpec.Text, role or "UNKNOWN")
end

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function element:OnCreate()
    element:RegisterEvent("PLAYER_LOOT_SPEC_UPDATED", "SetLootSpec")
    element:RegisterEvent("PLAYER_TALENT_UPDATE", "SetLootSpec")
	element:SetLootSpec()
end
