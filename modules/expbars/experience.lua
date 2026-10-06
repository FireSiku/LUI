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
local GetXPExhaustion = _G.GetXPExhaustion
local GameTooltip = _G.GameTooltip
local min, max = math.min, math.max

-- ####################################################################################################################
-- ##### ExperienceDataProvider #######################################################################################
-- ####################################################################################################################

local ExperienceDataProvider = module:CreateBarDataProvider("Experience")

ExperienceDataProvider.BAR_EVENTS = {
    "PLAYER_XP_UPDATE",
    "UPDATE_EXHAUSTION",
    "PLAYER_UPDATE_RESTING",
}

function ExperienceDataProvider:ShouldBeVisible()
    return CanShowExperienceBar()
end

function ExperienceDataProvider:Update()
    local currentXP = UnitXP("player")
    local maxXP = UnitXPMax("player")

    self.barValue = currentXP
    self.barMax = maxXP

    local restedXP = GetXPExhaustion()
    self.restedXP = type(restedXP) == "number" and not issecretvalue(restedXP)
        and max(0, restedXP) or 0
    self:UpdateRestedDisplay()

    -- Refresh an open tooltip from events, without polling or accumulating lines.
    if module.db.profile.ShowTooltip and GameTooltip:GetOwner() == self and GameTooltip:IsShown() then
        self:ShowTooltip()
        self:AddRestedTooltip()
    end
end

function ExperienceDataProvider:UpdateRestedDisplay()
    if not self.restedTexture then
        -- Keep XP-specific artwork and tooltip handling in this provider.
        -- ARTWORK sits above the background and below the existing OVERLAY text.
        self.restedTexture = self:CreateTexture(nil, "ARTWORK", nil, 1)
        self.restedTexture:SetVertexColor(0.2, 0.6, 1, 0.6)
        self:HookScript("OnEnter", self.AddRestedTooltip)
    end

    local rested = self.restedTexture
    local current, maximum = self.barValue, self.barMax
    if issecretvalue(current) or issecretvalue(maximum) or maximum <= 0 or self.restedXP <= 0 then
        rested:Hide()
        return
    end

    -- Only the part that fits in this level is drawn; the tooltip retains the
    -- complete reserve, including rested XP extending into subsequent levels.
    local start = min(max(current, 0), maximum) / maximum
    local finish = min(max(current, 0) + self.restedXP, maximum) / maximum
    local width = self:GetWidth()
    if finish <= start or width <= 0 then
        rested:Hide()
        return
    end

    local texture = module:FetchStatusBar("ExpBarFill")
    if self.restedFillTexture ~= texture then
        rested:SetTexture(texture)
        self.restedFillTexture = texture
    end
    rested:ClearAllPoints()
    if self:GetReverseFill() then
        rested:SetPoint("TOPRIGHT", self, "TOPRIGHT", -start * width, 0)
        rested:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -start * width, 0)
        rested:SetTexCoord(1, 0, 0, 1)
    else
        rested:SetPoint("TOPLEFT", self, "TOPLEFT", start * width, 0)
        rested:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", start * width, 0)
        rested:SetTexCoord(0, 1, 0, 1)
    end
    rested:SetWidth((finish - start) * width)
    rested:Show()
end

function ExperienceDataProvider:AddRestedTooltip()
    if not module.db.profile.ShowTooltip or GameTooltip:GetOwner() ~= self or not GameTooltip:IsShown() then return end
    local maximum = self.barMax
    if issecretvalue(maximum) or maximum <= 0 then return end

    local rested = self.restedXP or 0
    local precision = module.db.profile.Precision or 2
    GameTooltip:AddDoubleLine("Rested XP",
        format("%s (%."..precision.."f%%)", BreakUpLargeNumbers(rested), rested / maximum * 100),
        0.2, 0.6, 1, 1, 1, 1)
    GameTooltip:Show()
end

function ExperienceDataProvider:GetDataText(style)
	if style == "None" then return "" end
	return style == "Full" and "Experience" or "XP"
end
