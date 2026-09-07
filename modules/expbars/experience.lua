-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.ExperienceBars
local module = LUI:GetModule("Experience Bars")

local CanShowExperienceBar = GameRulesUtil.CanShowExperienceBar
local UnitXPMax = _G.UnitXPMax
local UnitXP = _G.UnitXP

-- ####################################################################################################################
-- ##### ExperienceDataProvider #######################################################################################
-- ####################################################################################################################

local ExperienceDataProvider = module:CreateBarDataProvider("Experience")

ExperienceDataProvider.BAR_EVENTS = {
    "PLAYER_XP_UPDATE",
}

function ExperienceDataProvider:ShouldBeVisible()
    return CanShowExperienceBar()
end

function ExperienceDataProvider:Update()
	local currentXP = UnitXP("player")
    local maxXP = UnitXPMax("player")

    self.barValue = currentXP
    self.barMax = maxXP
end

function ExperienceDataProvider:GetDataText(style)
	if style == "None" then return "" end
	return style == "Full" and "Experience" or "XP"
end
