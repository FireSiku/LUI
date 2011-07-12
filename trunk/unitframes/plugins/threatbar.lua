
-- oUF Threatbar written for LUI v3

local _, ns = ...
local oUF = ns.oUF or oUF

local aggrocolors = {
	0, 1, 0,
	1, 1, 0,
	1, 0, 0
}

local Update = function(bar)
	local self = bar.__owner
	
	if bar.tankHide and self.Vengeance and self.Vengeance.isTank then
		bar:SetAlpha(0)
		return
	end
	
	if not UnitAffectingCombat("target") or not UnitCanAttack("player", "target") then
		bar:SetAlpha(0)
		return
	end
	
	bar:SetAlpha(1)
	
	local hasaggro, _, threat, rawthreat = UnitDetailedThreatSituation("player", "target")
	
	if not threat then return end
	if not rawthreat then return end
	
	if hasaggro then -- tanking
		bar:SetMinMaxValues(0, 100)
		bar.helper:SetMinMaxValues(0, 100)
		bar:SetValue(100)
	elseif rawthreat / threat < 1.2 then -- melee
		bar:SetMinMaxValues(0, 110)
		bar.helper:SetMinMaxValues(0, 110)
		bar:SetValue(rawthreat)
	else -- range
		bar:SetMinMaxValues(0, 130)
		bar.helper:SetMinMaxValues(0, 130)
		bar:SetValue(rawthreat)
	end
	
	if bar.colorGradient then
		local r, g, b = oUF.ColorGradient(threat/100, unpack(aggrocolors))
		local mu = bar.BGMultiplier or 0
		bar:SetStatusBarColor(r, g, b)
		if bar.bg then bar.bg:SetVertexColor(r * mu, g * mu, b * mu) end
	end
end

local Show = function(self) self.ThreatBar:Show() end

local Hide = function(self) self.ThreatBar:Hide() end

local Enable = function(self, unit)
	local bar = self.ThreatBar
	
	if unit ~= "player" then return end
	
	if bar then
		bar.__owner = self
		
		bar:Hide()
		
		if not bar.indicator then
			bar.helper = CreateFrame("StatusBar", nil, bar)
			bar.helper:SetAllPoints(bar)
			bar.helper:SetFrameLevel(bar:GetFrameLevel() - 1)
			bar.helper:SetMinMaxValues(0, 100)
			bar.helper:SetValue(100)
			bar.helper:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
			
			bar.indicator = bar:CreateTexture(nil, "OVERLAY")
			bar.indicator:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
			bar.indicator:SetVertexColor(1, 1, 1, 1)
			bar.indicator:SetBlendMode("ADD")
			bar.indicator:SetHeight(bar:GetHeight()*4)
			bar.indicator:SetWidth(bar:GetHeight()*2)
			bar.indicator:SetPoint("CENTER", bar.helper:GetStatusBarTexture(), "RIGHT", 0, 0)
		end
		
		self:RegisterEvent("PLAYER_REGEN_DISABLED", Show)
		self:RegisterEvent("PLAYER_REGEN_ENABLED", Hide)
		
		bar:SetScript("OnUpdate", Update)
	end
end

local Disable = function(self)
	local bar = self.ThreatBar
	
	if bar then
		bar:SetScript("OnUpdate", nil)
		
		self:UnregisterEvent("PLAYER_REGEN_DISABLED", Show)
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", Hide)
		
		bar:Hide()
		bar.helper:Hide()
		bar.indicator:Hide()
	end
end

oUF:AddElement("ThreatBar", nil, Enable, Disable)
