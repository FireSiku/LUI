-- WeaponSpeed Infotext

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)
local L = LUI.L

---@class LUI.Infotext
local module = LUI:GetModule("Infotext")
local element = module:NewElement("WeaponSpeed")

-- ####################################################################################################################
-- ##### Default Settings #############################################################################################
-- ####################################################################################################################

-- element.defaults = {
--     profile = {
--     }
-- }
-- module:MergeDefaults(element.defaults, "WeaponSpeed")

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

function module:SetWeaponSpeed()
    local f = CreateFrame("Frame")
    f:SetScript("OnEvent", function()
        local mspeed, ospeed = UnitAttackSpeed("player")
        element.text = format("AS: %.2fs", tonumber(mspeed))
        if ospeed ~= nil and ospeed ~= 0 then
            element.text = format("AS: %.2fs / %.2fs", tonumber(mspeed), tonumber(ospeed))
        end

    end)
    f:RegisterEvent("UNIT_ATTACK_SPEED")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    -- f:RegisterEvent("EQUIPMENT_SWAP_FINISHED")
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
    module:SetWeaponSpeed()
end
