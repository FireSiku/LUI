--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: meta.lua
	Description: oUF Meta Functions
]]

local addonname, LUI = ...
local module = LUI:GetModule("Unitframes")
local Media = LibStub("LibSharedMedia-3.0")
local oUF = LUI.oUF

local GetUnitPowerBarTextureInfo = _G.GetUnitPowerBarTextureInfo
local UnitIsTapDenied = _G.UnitIsTapDenied
local UnitIsConnected = _G.UnitIsConnected
local UnitPowerType = _G.UnitPowerType
local UnitHealthMax = _G.UnitHealthMax
local UnitPowerMax = _G.UnitPowerMax
local UnitIsPlayer = _G.UnitIsPlayer
local UnitReaction = _G.UnitReaction
local UnitIsGhost = _G.UnitIsGhost
local UnitIsDead = _G.UnitIsDead
local UnitHealth = _G.UnitHealth
local UnitPower = _G.UnitPower
local UnitIsAFK = _G.UnitIsAFK
local UnitClass = _G.UnitClass

-- ####################################################################################################################
-- ##### Unitframe Elements: Health Bar ###############################################################################
-- ####################################################################################################################

local function OverrideHealth(self, event, unit, powerType)
	if self.unit ~= unit then return end
	local health = self.Health

	local min = UnitHealth(unit)
	local max = UnitHealthMax(unit)
	local disconnected = not UnitIsConnected(unit)
	if min > max then min = max end

	health:SetMinMaxValues(0, max)

	health:SetValue(disconnected and max or min)

	health.disconnected = disconnected

	local _, pToken = UnitClass(unit)
	local color = module.colors.class[pToken] or {0.5, 0.5, 0.5}

	if health.color == "By Class" then
		if UnitIsPlayer(unit) then
			health:SetStatusBarColor(unpack(color))
		else
			local reaction = UnitReaction("player", unit)
			if reaction and reaction < 4 then
				health:SetStatusBarColor(unpack(module.db.profile.Colors.Misc["Hostile"]))
			elseif reaction and reaction == 4 then
				health:SetStatusBarColor(unpack(module.db.profile.Colors.Misc["Neutral"]))
			else
				health:SetStatusBarColor(unpack(module.db.profile.Colors.Misc["Friendly"]))
			end
		end
	elseif health.color == "Individual" then
		health:SetStatusBarColor(health.colorIndividual.r, health.colorIndividual.g, health.colorIndividual.b)
	else
		health:SetStatusBarColor(oUF.ColorGradient(min, max, module.colors.smooth()))
	end

	if health.colorTapping and UnitIsTapDenied and UnitIsTapDenied(unit) then health:SetStatusBarColor(unpack(module.db.profile.Colors.Misc["Tapped"])) end

	local r_, g_, b_ = health:GetStatusBarColor()
	local mu = health.bg.multiplier or 1

	if health.bg.invert == true then
		health.bg:SetVertexColor(r_+(1-r_)*mu, g_+(1-g_)*mu, b_+(1-b_)*mu)
	else
		health.bg:SetVertexColor(r_*mu, g_*mu, b_*mu)
	end

	if not UnitIsConnected(unit) then
		health:SetValue(0)
		health.value:SetText(health.value.ShowDead and "|cffD7BEA5<Offline>|r" or "")
		health.valuePercent:SetText(health.valuePercent.ShowDead and "|cffD7BEA5<Offline>|r" or "")
		health.valueMissing:SetText("")
	elseif UnitIsGhost(unit) then
		health:SetValue(0)
		health.value:SetText(health.value.ShowDead and "|cffD7BEA5<Ghost>|r" or "")
		health.valuePercent:SetText(health.valuePercent.ShowDead and "|cffD7BEA5<Ghost>|r" or "")
		health.valueMissing:SetText("")
	elseif UnitIsDead(unit) then
		health:SetValue(0)
		health.value:SetText(health.value.ShowDead and "|cffD7BEA5<Dead>|r" or "")
		health.valuePercent:SetText(health.valuePercent.ShowDead and "|cffD7BEA5<Dead>|r" or "")
		health.valueMissing:SetText("")
	else
		local healthPercent = 100 * (min / max)

		-- Check if name should only be displayed when health is full.
		if self.Info.OnlyWhenFull and min ~= max then
			-- Just set to nil, as name tags are updated when ever anything happens? Inefficient but works for us here.
			self.Info:SetText("")
		end

		if health.value.Enable == true then
			if min >= 1 then
				if health.value.ShowAlways == false and min == max then
					health.value:SetText("")
				elseif health.value.Format == "Absolut" then
					health.value:SetFormattedText("%s/%s", min, max)
				elseif health.value.Format == "Absolut & Percent" then
					health.value:SetFormattedText("%s/%s | %.1f%%", min, max, healthPercent)
				elseif health.value.Format == "Absolut Short" then
					health.value:SetFormattedText("%s/%s", module.ShortValue(min), module.ShortValue(max))
				elseif health.value.Format == "Absolut Short & Percent" then
					health.value:SetFormattedText("%s/%s | %.1f%%", module.ShortValue(min),module.ShortValue(max), healthPercent)
				elseif health.value.Format == "Standard" then
					health.value:SetFormattedText("%s", min)
				elseif health.value.Format == "Standard & Percent" then
					health.value:SetFormattedText("%s | %.1f%%", min, healthPercent)
				elseif health.value.Format == "Standard Short" then
					health.value:SetFormattedText("%s", module.ShortValue(min))
				elseif health.value.Format == "Standard Short & Percent" then
					health.value:SetFormattedText("%s | %.1f%%", module.ShortValue(min), healthPercent)
				else
					health.value:SetFormattedText("%s", min)
				end

				if health.value.color == "By Class" then
					health.value:SetTextColor(unpack(color))
				elseif health.value.color == "Individual" then
					health.value:SetTextColor(health.value.colorIndividual.r, health.value.colorIndividual.g, health.value.colorIndividual.b)
				else
					health.value:SetTextColor(oUF.ColorGradient(min, max, module.colors.smooth()))
				end
			else
				health.value:SetText("")
			end
		else
			health.value:SetText("")
		end

		if health.valuePercent.Enable == true then
			if min ~= max or health.valuePercent.ShowAlways == true then
				health.valuePercent:SetFormattedText("%.1f%%", healthPercent)
			else
				health.valuePercent:SetText("")
			end

			if health.valuePercent.color == "By Class" then
				health.valuePercent:SetTextColor(unpack(color))
			elseif health.valuePercent.color == "Individual" then
				health.valuePercent:SetTextColor(health.valuePercent.colorIndividual.r, health.valuePercent.colorIndividual.g, health.valuePercent.colorIndividual.b)
			else
				health.valuePercent:SetTextColor(oUF.ColorGradient(min, max, module.colors.smooth()))
			end
		else
			health.valuePercent:SetText("")
		end

		if health.valueMissing.Enable == true then
			local healthMissing = max-min

			if healthMissing > 0 or health.valueMissing.ShowAlways == true then
				if health.valueMissing.ShortValue == true then
					health.valueMissing:SetFormattedText("-%s", module.ShortValue(healthMissing))
				else
					health.valueMissing:SetFormattedText("-%s", healthMissing)
				end
			else
				health.valueMissing:SetText("")
			end

			if health.valueMissing.color == "By Class" then
				health.valueMissing:SetTextColor(unpack(color))
			elseif health.valueMissing.color == "Individual" then
				health.valueMissing:SetTextColor(health.valueMissing.colorIndividual.r, health.valueMissing.colorIndividual.g, health.valueMissing.colorIndividual.b)
			else
				health.valueMissing:SetTextColor(oUF.ColorGradient(min, max, module.colors.smooth()))
			end
		else
			health.valueMissing:SetText("")
		end
	end

	if UnitIsAFK(unit) then
		if health.value.ShowDead == true then
			if health.value:GetText() then
				if not strfind(health.value:GetText(), "AFK") then
					health.value:SetFormattedText("|cffffffff<AFK>|r %s", health.value:GetText())
				end
			else
				health.value:SetText("|cffffffff<AFK>|r")
			end
		end

		if health.valuePercent.ShowDead == true then
			if health.valuePercent:GetText() then
				if not strfind(health.valuePercent:GetText(), "AFK") then
					health.valuePercent:SetFormattedText("|cffffffff<AFK>|r %s", health.valuePercent:GetText())
				end
			else
				health.valuePercent:SetText("|cffffffff<AFK>|r")
			end
		end
	end
end

local function Health(self, unit, oufdb)
	if not self.Health then
		self.Health = CreateFrame("StatusBar", nil, self)
		self.Health:SetFrameLevel(2)
		self.Health.bg = self.Health:CreateTexture(nil, "BORDER")
		self.Health.bg:SetAllPoints(self.Health)
	end

	self.Health:SetHeight(oufdb.HealthBar.Height)
	if not oufdb.HealthBar.Width then LUI:Print(unit, oufdb.HealthBar.Width, oufdb.Width) end
	self.Health:SetWidth(oufdb.HealthBar.Width * self:GetWidth() / oufdb.Width) -- needed for 25/40 man raid width downscaling!
	self.Health:SetStatusBarTexture(Media:Fetch("statusbar", oufdb.HealthBar.Texture))
	self.Health:ClearAllPoints()
	self.Health:SetPoint("TOPLEFT", self, "TOPLEFT", oufdb.HealthBar.X * self:GetWidth() / oufdb.Width, oufdb.HealthBar.Y) -- needed for 25/40 man raid width downscaling!

	self.Health.bg:SetTexture(Media:Fetch("statusbar", oufdb.HealthBar.TextureBG))
	self.Health.bg:SetAlpha(oufdb.HealthBar.BGAlpha)
	self.Health.bg.multiplier = oufdb.HealthBar.BGMultiplier
	self.Health.bg.invert = oufdb.HealthBar.BGInvert

	self.Health.colorTapping = (unit == "target") and oufdb.HealthBar.Tapping or false
	self.Health.colorDisconnected = false
	self.Health.color = oufdb.HealthBar.Color
	self.Health.colorIndividual = oufdb.HealthBar.IndividualColor
	self.Health.Smooth = oufdb.HealthBar.Smooth
	self.Health.colorReaction = false
	self.Health.frequentUpdates = true

	self.Health.Override = OverrideHealth
end

-- ####################################################################################################################
-- ##### Unitframe Elements: Health Texts #############################################################################
-- ####################################################################################################################

local function HealthValue(self, unit, oufdb)
	if not self.Health.value then self.Health.value = module.SetFontString(self.Overlay, Media:Fetch("font", oufdb.HealthText.Font), oufdb.HealthText.Size, oufdb.HealthText.Outline) end
	self.Health.value:SetFont(Media:Fetch("font", oufdb.HealthText.Font), oufdb.HealthText.Size, oufdb.HealthText.Outline)
	self.Health.value:ClearAllPoints()
	self.Health.value:SetPoint(oufdb.HealthText.Point, self, oufdb.HealthText.RelativePoint, oufdb.HealthText.X, oufdb.HealthText.Y)

	if oufdb.HealthText.Enable == true then
		self.Health.value:Show()
	else
		self.Health.value:Hide()
	end

	self.Health.value.Enable = oufdb.HealthText.Enable
	self.Health.value.ShowAlways = oufdb.HealthText.ShowAlways
	self.Health.value.ShowDead = oufdb.HealthText.ShowDead
	self.Health.value.Format = oufdb.HealthText.Format
	self.Health.value.color = oufdb.HealthText.Color
	self.Health.value.colorIndividual = oufdb.HealthText.IndividualColor
end


local function HealthPercent(self, unit, oufdb)
	if not self.Health.valuePercent then self.Health.valuePercent = module.SetFontString(self.Overlay, Media:Fetch("font", oufdb.HealthPercentText.Font), oufdb.HealthPercentText.Size, oufdb.HealthPercentText.Outline) end
	self.Health.valuePercent:SetFont(Media:Fetch("font", oufdb.HealthPercentText.Font), oufdb.HealthPercentText.Size, oufdb.HealthPercentText.Outline)
	self.Health.valuePercent:ClearAllPoints()
	self.Health.valuePercent:SetPoint(oufdb.HealthPercentText.Point, self, oufdb.HealthPercentText.RelativePoint, oufdb.HealthPercentText.X, oufdb.HealthPercentText.Y)

	if oufdb.HealthPercentText.Enable == true then
		self.Health.valuePercent:Show()
	else
		self.Health.valuePercent:Hide()
	end

	self.Health.valuePercent.Enable = oufdb.HealthPercentText.Enable
	self.Health.valuePercent.ShowAlways = oufdb.HealthPercentText.ShowAlways
	self.Health.valuePercent.ShowDead = oufdb.HealthPercentText.ShowDead
	self.Health.valuePercent.color = oufdb.HealthPercentText.Color
	self.Health.valuePercent.colorIndividual = oufdb.HealthPercentText.IndividualColor
end

local function HealthMissing(self, unit, oufdb)
	if not self.Health.valueMissing then self.Health.valueMissing = module.SetFontString(self.Overlay, Media:Fetch("font", oufdb.HealthMissingText.Font), oufdb.HealthMissingText.Size, oufdb.HealthMissingText.Outline) end
	self.Health.valueMissing:SetFont(Media:Fetch("font", oufdb.HealthMissingText.Font), oufdb.HealthMissingText.Size, oufdb.HealthMissingText.Outline)
	self.Health.valueMissing:ClearAllPoints()
	self.Health.valueMissing:SetPoint(oufdb.HealthMissingText.Point, self, oufdb.HealthMissingText.RelativePoint, oufdb.HealthMissingText.X, oufdb.HealthMissingText.Y)

	if oufdb.HealthMissingText.Enable == true then
		self.Health.valueMissing:Show()
	else
		self.Health.valueMissing:Hide()
	end

	self.Health.valueMissing.Enable = oufdb.HealthMissingText.Enable
	self.Health.valueMissing.ShowAlways = oufdb.HealthMissingText.ShowAlways
	self.Health.valueMissing.ShortValue = oufdb.HealthMissingText.ShortValue
	self.Health.valueMissing.color = oufdb.HealthMissingText.Color
	self.Health.valueMissing.colorIndividual = oufdb.HealthMissingText.IndividualColor
end

-- ####################################################################################################################
-- ##### Unitframe Elements: Absorb Bar ###############################################################################
-- ####################################################################################################################

local function TotalAbsorb(self, unit, oufdb)
	if not self.TotalAbsorb then
		self.TotalAbsorb = CreateFrame('StatusBar', nil, self.Health)
	end

	self.TotalAbsorb.maxOverflow = 1
	
	self.TotalAbsorb:SetWidth(oufdb.HealthBar.Width * self:GetWidth() / oufdb.Width) -- needed for 25/40 man raid width downscaling!
	self.TotalAbsorb:SetStatusBarTexture(Media:Fetch("statusbar", oufdb.TotalAbsorbBar.Texture))
	self.TotalAbsorb:SetStatusBarColor(oufdb.TotalAbsorbBar.MyColor.r, oufdb.TotalAbsorbBar.MyColor.g, oufdb.TotalAbsorbBar.MyColor.b, oufdb.TotalAbsorbBar.MyColor.a)

	self.TotalAbsorb:ClearAllPoints()
	self.TotalAbsorb:SetPoint("TOPLEFT", self.Health:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
	self.TotalAbsorb:SetPoint("BOTTOMLEFT", self.Health:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)

	--self.TotalAbsorb.Override = TotalAbsorbOverride
end

-- ####################################################################################################################
-- ##### Unitframe Elements: Power Bar ################################################################################
-- ####################################################################################################################
local function GetDisplayPower(power, unit)
	return (UnitPowerType(unit))
end

local function OverridePower(self, event, unit)
	if self.unit ~= unit then return end
	local power = self.Power

	local displayType = GetDisplayPower(power, unit)
	local min = UnitPower(unit, displayType)
	local max = UnitPowerMax(unit, displayType)
	local disconnected = not UnitIsConnected(unit)
	if min > max then min = max end

	power:SetMinMaxValues(0, max)

	power:SetValue(disconnected and max or min)

	power.disconnected = disconnected

	local _, pType = UnitPowerType(unit)
	local pClass, pToken = UnitClass(unit)
	local color = module.colors.class[pToken] or {0.5, 0.5, 0.5}
	local color2 = module.colors.power[pType] or {0.5, 0.5, 0.5}
	-- local _, r, g, b = UnitAlternatePowerTextureInfo(unit, 2)

	if power.color == "By Class" then
		power:SetStatusBarColor(unpack(color))
	elseif power.color == "Individual" then
		power:SetStatusBarColor(power.colorIndividual.r, power.colorIndividual.g, power.colorIndividual.b)
	-- elseif unit == unit:match("boss%d") and select(7, UnitAlternatePowerInfo(unit)) then
	-- 	power:SetStatusBarColor(r, g, b)
	else
		power:SetStatusBarColor(unpack(color2))
	end

	local r, g, b = power:GetStatusBarColor()
	local mu = power.bg.multiplier or 1

	if power.bg.invert == true then
		power.bg:SetVertexColor((1-r)*mu, (1-g)*mu, (1-b)*mu)
	else
		power.bg:SetVertexColor(r*mu, g*mu, b*mu)
	end

	if not UnitIsConnected(unit) then
		power:SetValue(0)
		power.valueMissing:SetText("")
		power.valuePercent:SetText("")
		power.value:SetText("")
	elseif UnitIsGhost(unit) then
		power:SetValue(0)
		power.valueMissing:SetText("")
		power.valuePercent:SetText("")
		power.value:SetText("")
	elseif UnitIsDead(unit) then
		power:SetValue(0)
		power.valueMissing:SetText("")
		power.valuePercent:SetText("")
		power.value:SetText("")
	else
		local powerPercent = max == 0 and 0 or 100 * (min / max)

		if power.value.Enable == true then
			if (power.value.ShowFull == false and min == max) or (power.value.ShowEmpty == false and min == 0) then
				power.value:SetText("")
			elseif power.value.Format == "Absolut" then
				power.value:SetFormattedText("%d/%d", min, max)
			elseif power.value.Format == "Absolut & Percent" then
				power.value:SetFormattedText("%d/%d | %.1f%%", min, max, powerPercent)
			elseif power.value.Format == "Absolut Short" then
				power.value:SetFormattedText("%s/%s", module.ShortValue(min), module.ShortValue(max))
			elseif power.value.Format == "Absolut Short & Percent" then
				power.value:SetFormattedText("%s/%s | %.1f%%", module.ShortValue(min), module.ShortValue(max), powerPercent)
			elseif power.value.Format == "Standard" then
				power.value:SetFormattedText("%d", min)
			elseif power.value.Format == "Standard & Percent" then
				power.value:SetFormattedText("%d | %.1f%%", min, powerPercent)
			elseif power.value.Format == "Standard Short" then
				power.value:SetFormattedText("%s", module.ShortValue(min))
			elseif power.value.Format == "Standard Short" then
				power.value:SetFormattedText("%s | %.1f%%", module.ShortValue(min), powerPercent)
			else
				power.value:SetFormattedText("%d", min)
			end

			if power.value.color == "By Class" then
				power.value:SetTextColor(unpack(color))
			elseif power.value.color == "Individual" then
				power.value:SetTextColor(power.value.colorIndividual.r, power.value.colorIndividual.g, power.value.colorIndividual.b)
			else
				power.value:SetTextColor(unpack(color2))
			end
		else
			power.value:SetText("")
		end

		if power.valuePercent.Enable == true then
			if (power.valuePercent.ShowFull == false and min == max) or (power.valuePercent.ShowEmpty == false and min == 0) then
				power.valuePercent:SetText("")
			else
				power.valuePercent:SetFormattedText("%.1f%%", powerPercent)
			end

			if power.valuePercent.color == "By Class" then
				power.valuePercent:SetTextColor(unpack(color))
			elseif power.valuePercent.color == "Individual" then
				power.valuePercent:SetTextColor(power.valuePercent.colorIndividual.r, power.valuePercent.colorIndividual.g, power.valuePercent.colorIndividual.b)
			else
				power.valuePercent:SetTextColor(unpack(color2))
			end
		else
			power.valuePercent:SetText("")
		end

		if power.valueMissing.Enable == true then
			local powerMissing = max-min

			if (power.valueMissing.ShowFull == false and min == max) or (power.valueMissing.ShowEmpty == false and min == 0) then
				power.valueMissing:SetText("")
			elseif power.valueMissing.ShortValue == true then
				power.valueMissing:SetFormattedText("-%s", module.ShortValue(powerMissing))
			else
				power.valueMissing:SetFormattedText("-%d", powerMissing)
			end

			if power.valueMissing.color == "By Class" then
				power.valueMissing:SetTextColor(unpack(color))
			elseif power.valueMissing.color == "Individual" then
				power.valueMissing:SetTextColor(power.valueMissing.colorIndividual.r, power.valueMissing.colorIndividual.g, power.valueMissing.colorIndividual.b)
			else
				power.valueMissing:SetTextColor(unpack(color2))
			end
		else
			power.valueMissing:SetText("")
		end
	end
end

local function Power(self, unit, oufdb)
	if not self.Power then
		self.Power = CreateFrame("StatusBar", nil, self)
		self.Power:SetFrameLevel(2)
		self.Power.bg = self.Power:CreateTexture(nil, "BORDER")
		self.Power.bg:SetAllPoints(self.Power)
	end

	self.Power:SetHeight(oufdb.PowerBar.Height)
	self.Power:SetWidth(oufdb.PowerBar.Width * self:GetWidth() / oufdb.Width) -- needed for 25/40 man raid width downscaling!
	self.Power:SetStatusBarTexture(Media:Fetch("statusbar", oufdb.PowerBar.Texture))
	self.Power:ClearAllPoints()
	self.Power:SetPoint("TOPLEFT", self, "TOPLEFT", oufdb.PowerBar.X * self:GetWidth() / oufdb.Width, oufdb.PowerBar.Y) -- needed for 25/40 man raid width downscaling!

	self.Power.bg:SetTexture(Media:Fetch("statusbar", oufdb.PowerBar.TextureBG))
	self.Power.bg:SetAlpha(oufdb.PowerBar.BGAlpha)
	self.Power.bg.multiplier = oufdb.PowerBar.BGMultiplier
	self.Power.bg.invert = oufdb.PowerBar.BGInvert

	self.Power.colorTapping = false
	self.Power.colorDisconnected = false
	self.Power.colorSmooth = false
	self.Power.color = oufdb.PowerBar.Color
	self.Power.colorIndividual = oufdb.PowerBar.IndividualColor
	self.Power.Smooth = oufdb.PowerBar.Smooth
	self.Power.colorReaction = false
	self.Power.frequentUpdates = true

	if oufdb.PowerBar.Enable == true then
		self.Power:Show()
	else
		self.Power:Hide()
	end

	self.Power.Override = OverridePower
end

-- ####################################################################################################################
-- ##### Unitframe Elements: Power Texts ##############################################################################
-- ####################################################################################################################


local function PowerValue(self, unit, oufdb)
	if not self.Power.value then self.Power.value = module.SetFontString(self.Overlay, Media:Fetch("font", oufdb.PowerText.Font), oufdb.PowerText.Size, oufdb.PowerText.Outline) end
	self.Power.value:SetFont(Media:Fetch("font", oufdb.PowerText.Font), oufdb.PowerText.Size, oufdb.PowerText.Outline)
	self.Power.value:ClearAllPoints()
	self.Power.value:SetPoint(oufdb.PowerText.Point, self, oufdb.PowerText.RelativePoint, oufdb.PowerText.X, oufdb.PowerText.Y)

	if oufdb.PowerText.Enable == true then
		self.Power.value:Show()
	else
		self.Power.value:Hide()
	end

	self.Power.value.Enable = oufdb.PowerText.Enable
	self.Power.value.ShowFull = oufdb.PowerText.ShowFull
	self.Power.value.ShowEmpty = oufdb.PowerText.ShowEmpty
	self.Power.value.Format = oufdb.PowerText.Format
	self.Power.value.color = oufdb.PowerText.Color
	self.Power.value.colorIndividual = oufdb.PowerText.IndividualColor
end

local function PowerPercent(self, unit, oufdb)
	if not self.Power.valuePercent then self.Power.valuePercent = module.SetFontString(self.Overlay, Media:Fetch("font", oufdb.PowerPercentText.Font), oufdb.PowerPercentText.Size, oufdb.PowerPercentText.Outline) end
	self.Power.valuePercent:SetFont(Media:Fetch("font", oufdb.PowerPercentText.Font), oufdb.PowerPercentText.Size, oufdb.PowerPercentText.Outline)
	self.Power.valuePercent:ClearAllPoints()
	self.Power.valuePercent:SetPoint(oufdb.PowerPercentText.Point, self, oufdb.PowerPercentText.RelativePoint, oufdb.PowerPercentText.X, oufdb.PowerPercentText.Y)

	if oufdb.PowerPercentText.Enable == true then
		self.Power.valuePercent:Show()
	else
		self.Power.valuePercent:Hide()
	end

	self.Power.valuePercent.Enable = oufdb.PowerPercentText.Enable
	self.Power.valuePercent.ShowFull = oufdb.PowerPercentText.ShowFull
	self.Power.valuePercent.ShowEmpty = oufdb.PowerPercentText.ShowEmpty
	self.Power.valuePercent.color = oufdb.PowerPercentText.Color
	self.Power.valuePercent.colorIndividual = oufdb.PowerPercentText.IndividualColor
end

local function PowerMissing(self, unit, oufdb)
	if not self.Power.valueMissing then self.Power.valueMissing = module.SetFontString(self.Overlay, Media:Fetch("font", oufdb.PowerMissingText.Font), oufdb.PowerMissingText.Size, oufdb.PowerMissingText.Outline) end
	self.Power.valueMissing:SetFont(Media:Fetch("font", oufdb.PowerMissingText.Font), oufdb.PowerMissingText.Size, oufdb.PowerMissingText.Outline)
	self.Power.valueMissing:ClearAllPoints()
	self.Power.valueMissing:SetPoint(oufdb.PowerMissingText.Point, self, oufdb.PowerMissingText.RelativePoint, oufdb.PowerMissingText.X, oufdb.PowerMissingText.Y)

	if oufdb.PowerMissingText.Enable == true then
		self.Power.valueMissing:Show()
	else
		self.Power.valueMissing:Hide()
	end

	self.Power.valueMissing.Enable = oufdb.PowerMissingText.Enable
	self.Power.valueMissing.ShowFull = oufdb.PowerMissingText.ShowFull
	self.Power.valueMissing.ShowEmpty = oufdb.PowerMissingText.ShowEmpty
	self.Power.valueMissing.ShortValue = oufdb.PowerMissingText.ShortValue
	self.Power.valueMissing.color = oufdb.PowerMissingText.Color
	self.Power.valueMissing.colorIndividual = oufdb.PowerMissingText.IndividualColor
end

-- ####################################################################################################################
-- ##### Unitframe Elements: Alternative Power Bar ####################################################################
-- ####################################################################################################################

local function PostUpdateAlternativePower(altpowerbar, unit, cur, min, max)
	local color = module.colors.class[LUI.playerClass] or {0.5, 0.5, 0.5}

	local tex, r, g, b = GetUnitPowerBarTextureInfo("player", 3)

	if not tex then return end

	if altpowerbar.color == "By Class" then
		altpowerbar:SetStatusBarColor(unpack(color))
	elseif altpowerbar.color == "Individual" then
		altpowerbar:SetStatusBarColor(altpowerbar.colorIndividual.r, altpowerbar.colorIndividual.g, altpowerbar.colorIndividual.b)
	else
		altpowerbar:SetStatusBarColor(r, g, b)
	end

	local r_, g_, b_ = altpowerbar:GetStatusBarColor()
	local mu = altpowerbar.bg.multiplier or 1
	altpowerbar.bg:SetVertexColor(r_*mu, g_*mu, b_*mu)

	if altpowerbar.Text then
		if altpowerbar.Text.Enable then
			if altpowerbar.Text.ShowAlways == false and (cur == max or cur == min) then
				altpowerbar.Text:SetText("")
			elseif altpowerbar.Text.Format == "Absolut" then
				altpowerbar.Text:SetFormattedText("%d/%d", cur, max)
			elseif altpowerbar.Text.Format == "Percent" then
				altpowerbar.Text:SetFormattedText("%.1f%%", 100 * (cur / max))
			elseif altpowerbar.Text.Format == "Standard" then
				altpowerbar.Text:SetFormattedText("%d", cur)
			end

			if altpowerbar.Text.color == "By Class" then
				altpowerbar.Text:SetTextColor(unpack(color))
			elseif altpowerbar.Text.color == "Individual" then
				altpowerbar.Text:SetTextColor(altpowerbar.Text.colorIndividual.r, altpowerbar.Text.colorIndividual.g, altpowerbar.Text.colorIndividual.b)
			else
				altpowerbar.Text:SetTextColor(r, g, b)
			end

		else
			altpowerbar.Text:SetText("")
		end
	end
end

local function AlternativePower(self, unit, oufdb)
	if not self.AlternativePower then
		self.AlternativePower = CreateFrame("StatusBar", nil, self)
		if unit == "pet" then self.AlternativePower:SetParent(oUF_LUI_player) end

		self.AlternativePower.bg = self.AlternativePower:CreateTexture(nil, "BORDER")
		self.AlternativePower.bg:SetAllPoints(self.AlternativePower)

		self.AlternativePower.SetPosition = function()
			if not module.db.profile.player.AlternativePowerBar.OverPower then return end

			if oUF_LUI_player.AlternativePower:IsShown() or (oUF_LUI_pet and oUF_LUI_pet.AlternativePower and oUF_LUI_pet.AlternativePower:IsShown()) then
				oUF_LUI_player.Power:SetHeight(module.db.profile.player.PowerBar.Height/2 - 1)
				oUF_LUI_player.AlternativePower:SetHeight(module.db.profile.player.PowerBar.Height/2 - 1)
			else
				oUF_LUI_player.Power:SetHeight(module.db.profile.player.PowerBar.Height)
				oUF_LUI_player.AlternativePower:SetHeight(module.db.profile.player.AlternativePowerBar.Height)
			end
		end

		self.AlternativePower:SetScript("OnShow", function()
			self.AlternativePower.SetPosition()
			self.AlternativePower:ForceUpdate()
		end)
		self.AlternativePower:SetScript("OnHide", self.AlternativePower.SetPosition)

		self.AlternativePower.Text = module.SetFontString(self.AlternativePower, Media:Fetch("font", module.db.profile.player.AlternativePowerText.Font), module.db.profile.player.AlternativePowerText.Size, module.db.profile.player.AlternativePowerText.Outline)
	end

	self.AlternativePower:ClearAllPoints()
	if unit == "player" then
		if module.db.profile.player.AlternativePowerBar.OverPower then
			self.AlternativePower:SetPoint("TOPLEFT", self.Power, "BOTTOMLEFT", 0, -2)
			self.AlternativePower:SetPoint("TOPRIGHT", self.Power, "BOTTOMRIGHT", 0, -2)
		else
			self.AlternativePower:SetPoint("TOPLEFT", self, "TOPLEFT", module.db.profile.player.AlternativePowerBar.X, module.db.profile.player.AlternativePowerBar.Y)
		end
	else
		self.AlternativePower:SetPoint("TOPLEFT", oUF_LUI_player.AlternativePower, "TOPLEFT", 0, 0)
		self.AlternativePower:SetPoint("BOTTOMRIGHT", oUF_LUI_player.AlternativePower, "BOTTOMRIGHT", 0, 0)
	end

	self.AlternativePower:SetHeight(module.db.profile.player.AlternativePowerBar.Height)
	self.AlternativePower:SetWidth(module.db.profile.player.AlternativePowerBar.Width)
	self.AlternativePower:SetStatusBarTexture(Media:Fetch("statusbar", module.db.profile.player.AlternativePowerBar.Texture))

	self.AlternativePower.bg:SetTexture(Media:Fetch("statusbar", module.db.profile.player.AlternativePowerBar.TextureBG))
	self.AlternativePower.bg:SetAlpha(module.db.profile.player.AlternativePowerBar.BGAlpha)
	self.AlternativePower.bg.multiplier = module.db.profile.player.AlternativePowerBar.BGMultiplier

	self.AlternativePower.Smooth = module.db.profile.player.AlternativePowerBar.Smooth
	self.AlternativePower.color = module.db.profile.player.AlternativePowerBar.Color
	self.AlternativePower.colorIndividual = module.db.profile.player.AlternativePowerBar.IndividualColor
	
	self.AlternativePower.Text:SetFont(Media:Fetch("font", module.db.profile.player.AlternativePowerText.Font), module.db.profile.player.AlternativePowerText.Size, module.db.profile.player.AlternativePowerText.Outline)
	self.AlternativePower.Text:ClearAllPoints()
	self.AlternativePower.Text:SetPoint("CENTER", self.AlternativePower, "CENTER", module.db.profile.player.AlternativePowerText.X, module.db.profile.player.AlternativePowerText.Y)

	self.AlternativePower.Text.Enable = module.db.profile.player.AlternativePowerText.Enable
	self.AlternativePower.Text.Format = module.db.profile.player.AlternativePowerText.Format
	self.AlternativePower.Text.color = module.db.profile.player.AlternativePowerText.Color
	self.AlternativePower.Text.colorIndividual = module.db.profile.player.AlternativePowerText.IndividualColor

	if module.db.profile.player.AlternativePowerText.Enable then
		self.AlternativePower.Text:Show()
	else
		self.AlternativePower.Text:Hide()
	end

	self.AlternativePower.PostUpdate = PostUpdateAlternativePower

	self.AlternativePower.SetPosition()
end

-- ####################################################################################################################
-- ##### Unitframe Elements: Prediction Bars ##########################################################################
-- ####################################################################################################################

-- ####################################################################################################################
-- ##### Unitframe Elements: Wrap up ##################################################################################
-- ####################################################################################################################

module.funcs.Health = Health
module.funcs.HealthValue = HealthValue
module.funcs.HealthPercent = HealthPercent
module.funcs.HealthMissing = HealthMissing
module.funcs.TotalAbsorb = TotalAbsorb

module.funcs.Power = Power
module.funcs.PowerValue = PowerValue
module.funcs.PowerPercent = PowerPercent
module.funcs.PowerMissing = PowerMissing

module.funcs.AlternativePower = AlternativePower
