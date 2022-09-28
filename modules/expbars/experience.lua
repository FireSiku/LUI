-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

local _, LUI = ...
local module = LUI:GetModule("Experience Bars")
local L = LUI.L

local IsPlayerAtEffectiveMaxLevel = _G.IsPlayerAtEffectiveMaxLevel
local IsXPUserDisabled = _G.IsXPUserDisabled
local UnitXPMax = _G.UnitXPMax
local UnitXP = _G.UnitXP

-- ####################################################################################################################
-- ##### ExperienceDataProvider #############################################################################################
-- ####################################################################################################################

local ExperienceDataProvider = module:CreateBarDataProvider("Experience")

ExperienceDataProvider.BAR_EVENTS = {
    "PLAYER_XP_UPDATE",
}

function ExperienceDataProvider:ShouldBeVisible()
    if IsXPUserDisabled() then
        return false
    end

    return not IsPlayerAtEffectiveMaxLevel()
end

function ExperienceDataProvider:Update()
	local currentXP = UnitXP("player")
    local maxXP = UnitXPMax("player")

    self.barValue = currentXP
    self.barMax = maxXP
end

function ExperienceDataProvider:GetDataText()
	return "XP"
end