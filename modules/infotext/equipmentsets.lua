-- EquipmentSets Infotext

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, LUIAddon
local _, LUI= ...
local L = LUI.L

---@type InfotextModule
local module = LUI:GetModule("Infotext")
local element = module:NewElement("EquipmentSets")

-- ####################################################################################################################
-- ##### Default Settings #############################################################################################
-- ####################################################################################################################

-- element.defaults = {
--     profile = {
--     }
-- }
-- module:MergeDefaults(element.defaults, "EquipmentSets")

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

function module:SetEquipmentSets(setID)
    local f = CreateFrame("Frame")
    f:SetScript("OnEvent", function(self, event, addon, ...)
        local db = module.db.profile.EquipmentSets
        for set = 1, C_EquipmentSet.GetNumEquipmentSets() do
            local name, setID, isEquipped = C_EquipmentSet.GetEquipmentSetInfo(set - 1)
            if (event=="EQUIPMENT_SWAP_FINISHED") then
                local setID = select(1,...)
                local name = C_EquipmentSet.GetEquipmentSetInfo(setID)
                element.text = format(db.Text..name)
                db.SetName = (db.Text..name)            -- saves variable for next world load
            elseif (event=="PLAYER_ENTERING_WORLD") and db.SetName ~= "" then
                element.text = format(db.SetName or "Equipped Set:")
            else
                element.text = format("No Equipped Set")
            end
        end
    end)
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("EQUIPMENT_SWAP_FINISHED", SetEquipmentSets)
end

-- ####################################################################################################################
-- ##### Infotext Display #############################################################################################
-- ####################################################################################################################

-- function element.OnTooltipShow(GameTooltip)
-- end

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function element:OnCreate()
    element.text = format("Equipped Set:")
    module:SetEquipmentSets()
end
