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

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

function element:SetLootSpec()
    local db = module.db.profile
    local lootspec = GetLootSpecialization()
        if lootspec == 0 then
            local curspec = GetSpecialization()
            _, name, _, _, role = GetSpecializationInfo(curspec)
        else
            _, name, _, _, role = GetSpecializationInfoByID(lootspec)
        end
        element.text = string.format((db.LootSpec.Text).." "..role)
end

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function element:OnCreate()
    element:RegisterEvent("PLAYER_LOOT_SPEC_UPDATED", "SetLootSpec")
    element:RegisterEvent("PLAYER_TALENT_UPDATE", "SetLootSpec")
	element:SetLootSpec()
end
