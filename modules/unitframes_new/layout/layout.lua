------------------------------------------------------------------------
--	oUF LUI Layout
--	Version 3.6.1
-- 	Date: 08/30/2011
--	DO NOT USE THIS LAYOUT WITHOUT LUI
------------------------------------------------------------------------

local addonname, LUI = ...
local module = LUI:GetModule("Unitframes")
local Fader = LUI:GetModule("Fader")

local Media = LibStub("LibSharedMedia-3.0")
local Blizzard = LUI.Blizzard
local oUF = LUI.oUF
local L = LUI.L
local db

local UnitHealth, UnitHealthMax, UnitPower, UnitPowerMax = _G.UnitHealth, _G.UnitHealthMax, _G.UnitPower, _G.UnitPowerMax
local UnitIsUnit, UnitExists, UnitIsGhost, UnitIsDead = _G.UnitIsUnit, _G.UnitExists, _G.UnitIsGhost, _G.UnitIsDead
local UnitName, UnitGUID, UnitIsPVP, UnitReaction = _G.UnitName, _G.UnitGUID, _G.UnitIsPVP, _G.UnitReaction
local UnitIsPlayer, UnitIsEnemy, UnitIsTapDenied = _G.UnitIsPlayer, _G.UnitIsEnemy, _G.UnitIsTapDenied
local GetSpellInfo, GetTalentInfo, GetTotemInfo = _G.GetSpellInfo, _G.GetTalentInfo, _G.GetTotemInfo
local UnitIsVisible, UnitIsConnected, UnitIsAFK = _G.UnitIsVisible, _G.UnitIsConnected, _G.UnitIsAFK
local GetThreatStatusColor, UnitThreatSituation = _G.GetThreatStatusColor, _G.UnitThreatSituation
local UnitPowerType, GetUnitPowerBarTextureInfo = _G.UnitPowerType, _G.GetUnitPowerBarTextureInfo
local UnitClass, UnitLevel, GetSpecialization = _G.UnitClass, _G.UnitLevel, _G.GetSpecialization
local UnitAura, UnitDebuff, DebuffTypeColor = _G.UnitAura, _G.UnitDebuff, _G.DebuffTypeColor
local SetPortraitTexture, UnitHasVehicleUI = _G.SetPortraitTexture, _G.UnitHasVehicleUI
local GetComboPoints, GetShapeshiftFormID = _G.GetComboPoints, _G.GetShapeshiftFormID
local UnitSpellHaste, UnitChannelInfo = _G.UnitSpellHaste, _G.UnitChannelInfo
local GetPVPTimer, GetGlyphSocketInfo =_G.GetPVPTimer, _G.GetGlyphSocketInfo
local format = string.format
local floor = math.floor

local ALT_MANA_BAR_PAIR_DISPLAY_INFO = _G.ALT_MANA_BAR_PAIR_DISPLAY_INFO
local ADDITIONAL_POWER_BAR_INDEX = _G.ADDITIONAL_POWER_BAR_INDEX
local GameFontHighlight = _G.GameFontHighlight
local NUM_CHAT_WINDOWS = _G.NUM_CHAT_WINDOWS
local MAX_PLAYER_LEVEL = _G.MAX_PLAYER_LEVEL
local MAX_COMBO_POINTS = _G.MAX_COMBO_POINTS
local MAX_TOTEMS = _G.MAX_TOTEMS

local standings = {"Hated", "Hostile", "Unfriendly", "Neutral", "Friendly", "Honored", "Revered", "Exalted"}

------------------------------------------------------------------------
--	Textures and Medias
------------------------------------------------------------------------

local mediaPath = [=[Interface\Addons\LUI\media\]=]

local highlightTex = mediaPath..[=[textures\statusbars\highlightTex]=]
local normTex = mediaPath..[=[textures\statusbars\normTex]=]
local glowTex = mediaPath..[=[textures\statusbars\glowTex]=]
local blankTex = mediaPath..[=[textures\statusbars\blank]=]
local buttonTex = mediaPath..[=[textures\buttonTex]=]
local aggroTex = mediaPath..[=[textures\aggro]=]

local backdrop = {
	bgFile = blankTex,
	insets = {top = -1, left = -1, bottom = -1, right = -1},
}

local backdrop2 = {
	bgFile = blankTex,
	edgeFile = blankTex,
	tile = false, tileSize = 0, edgeSize = 1,
	insets = {top = -1, left = -1, bottom = -1, right = -1},
}

local font = mediaPath..[=[fonts\vibrocen.ttf]=]
local fontn = mediaPath..[=[fonts\KhmerUI.ttf]=]
local font2 = mediaPath..[=[Fonts\ARIALN.ttf]=]
local font3 = mediaPath..[=[fonts\Prototype.ttf]=]

local highlight = true
local entering

local cornerAuras = {
	WARRIOR = {
		TOPLEFT = {50720, true},
	},
	PRIEST = {
		TOPLEFT = {139, true}, -- Renew
		TOPRIGHT = {17}, -- Power Word: Shield
		BOTTOMLEFT = {33076}, -- Prayer of Mending
		BOTTOMRIGHT = {194384, true}, -- Atonement
	},
	DRUID = {
		TOPLEFT = {8936, true}, -- Regrowth
		TOPRIGHT = {94447}, -- Lifebloom
		BOTTOMLEFT = {774, true}, -- Rejuvenation
		BOTTOMRIGHT = {48438, true}, -- Wild Growth
	},
	MAGE = {
		TOPLEFT = {54646}, -- Focus Magic
	},
	MONK = {
		TOPLEFT = {115151, true} -- Renewing Mist
	},
	PALADIN = {
		TOPLEFT = {25771, false, true}, -- Forbearance
	},
	SHAMAN = {
		TOPLEFT = {61295, true}, -- Riptide
		TOPRIGHT = {974}, -- Earth Shield
	},
	WARLOCK = {
		TOPLEFT = {80398}, -- Dark Intent
	},
}

local channelingTicks -- base time between ticks
do
	local classChannels = {
	}

	channelingTicks = {
		["First Aid"] = 1 -- Bandages
	}
	if classChannels[LUI.playerClass] then
		for k, v in pairs(classChannels[LUI.playerClass]) do
			channelingTicks[k] = v
		end
	end
	wipe(classChannels)
end

------------------------------------------------------------------------
--	Dont edit this if you dont know what you are doing!
------------------------------------------------------------------------

local GetDisplayPower = function(power, unit)
		return (UnitPowerType(unit))
end

local SetFontString = function(parent, fontName, fontHeight, fontStyle)
	local fs = parent:CreateFontString(nil, "OVERLAY")
	fs:SetFont(fontName, fontHeight, fontStyle)
	fs:SetJustifyH("LEFT")
	fs:SetShadowColor(0, 0, 0)
	fs:SetShadowOffset(1.25, -1.25)
	return fs
end

local FormatTime = function(s)
	local day, hour, minute = 86400, 3600, 60
	if s >= day then
		return format("%dd", floor(s/day + 1)), s % day
	elseif s >= hour then
		return format("%dh", floor(s/hour + 1)), s % hour
	elseif s >= minute then
		if s <= minute * 1 then
			return format("%d:%02d", floor(s/60), s % minute), s - floor(s)
		end
		return format("%dm", floor(s/minute + 1)), s % minute
	end
	return format("%.1f", s), (s * 100 - floor(s * 100))/100
end

local ShortValue = function(value)
	if value >= 1e6 then
		return ("%.1fm"):format(value / 1e6):gsub("%.?0+([km])$", "%1")
	elseif value >= 1e3 or value <= -1e3 then
		return ("%.1fk"):format(value / 1e3):gsub("%.?0+([km])$", "%1")
	else
		return value
	end
end

local utf8sub = function(string, i, dots)
	local bytes = string:len()
	if bytes <= i then
		return string
	else
		local len, pos = 0, 1
		while pos <= bytes do
			len = len + 1
			local c = string:byte(pos)
			if (c > 0 and c <= 127) then
				pos = pos + 1
			elseif (c >= 192 and c <= 223) then
				pos = pos + 2
			elseif (c >= 224 and c <= 239) then
				pos = pos + 3
			elseif (c >= 240 and c <= 247) then
				pos = pos + 4
			end
			if (len == i) then break end
		end

		if len == i and pos <= bytes then
			return string:sub(1, pos - 1)..(dots and "..." or "")
		else
			return string
		end
	end
end

local UnitFrame_OnEnter = function(self)
	_G.UnitFrame_OnEnter(self)
	self.Highlight:Show()
end

local UnitFrame_OnLeave = function(self)
	_G.UnitFrame_OnLeave(self)
	self.Highlight:Hide()
end

local OverrideHealth = function(self, event, unit, powerType)
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

	if unit == "player" and entering == true then
		if module.db.player.Bars.Health.Color == "By Class" then
			health:SetStatusBarColor(unpack(color))
		elseif module.db.player.Bars.Health.Color == "Individual" then
			local indColor = module.db.player.Bars.Health.IndividualColor
			health:SetStatusBarColor(indColor.r, indColor.g, indColor.b)
		else
			health:SetStatusBarColor(oUF.ColorGradient(min, max, module.colors.smooth()))
		end
	else
		if health.color == "By Class" then
			if UnitIsPlayer(unit) then
				health:SetStatusBarColor(unpack(color))
			else
				local reaction = UnitReaction("player", unit)
				if reaction and reaction < 4 then
					health:SetStatusBarColor(unpack(module.db.Colors.Misc["Hostile"]))
				elseif reaction and reaction == 4 then
					health:SetStatusBarColor(unpack(module.db.Colors.Misc["Neutral"]))
				else
					health:SetStatusBarColor(unpack(module.db.Colors.Misc["Friendly"]))
				end
			end
		elseif health.color == "Individual" then
			health:SetStatusBarColor(health.colorIndividual.r, health.colorIndividual.g, health.colorIndividual.b)
		else
			health:SetStatusBarColor(oUF.ColorGradient(min, max, module.colors.smooth()))
		end
	end

	if health.colorTapping and UnitIsTapDenied and UnitIsTapDenied(unit) then health:SetStatusBarColor(unpack(module.db.Colors.Misc["Tapped"])) end

	local r_, g_, b_ = health:GetStatusBarColor()
	local mu = health.bg.multiplier or 1

	if health.bg.invert == true then
		health.bg:SetVertexColor(r_+(1-r_)*mu, g_+(1-g_)*mu, b_+(1-b_)*mu)
	else
		health.bg:SetVertexColor(r_*mu, g_*mu, b_*mu)
	end

	if not UnitIsConnected(unit) then
		health:SetValue(0)
		health.value:SetText(health.value.ShowDead and "|cffD7BEA5<Offline>|r")
		health.valuePercent:SetText(health.valuePercent.ShowDead and "|cffD7BEA5<Offline>|r")
		health.valueMissing:SetText()
	elseif UnitIsGhost(unit) then
		health:SetValue(0)
		health.value:SetText(health.value.ShowDead and "|cffD7BEA5<Ghost>|r")
		health.valuePercent:SetText(health.valuePercent.ShowDead and "|cffD7BEA5<Ghost>|r")
		health.valueMissing:SetText()
	elseif UnitIsDead(unit) then
		health:SetValue(0)
		health.value:SetText(health.value.ShowDead and "|cffD7BEA5<Dead>|r")
		health.valuePercent:SetText(health.valuePercent.ShowDead and "|cffD7BEA5<Dead>|r")
		health.valueMissing:SetText()
	else
		local healthPercent = 100 * (min / max)

		-- Check if name should only be displayed when health is full.
		if self.Info.OnlyWhenFull and min ~= max then
			-- Just set to nil, as name tags are updated when ever anything happens? Inefficient but works for us here.
			self.Info:SetText()
		end

		if health.value.Enable == true then
			if min >= 1 then
				if health.value.ShowAlways == false and min == max then
					health.value:SetText()
				elseif health.value.Format == "Absolut" then
					health.value:SetFormattedText("%s/%s", min, max)
				elseif health.value.Format == "Absolut & Percent" then
					health.value:SetFormattedText("%s/%s | %.1f%%", min, max, healthPercent)
				elseif health.value.Format == "Absolut Short" then
					health.value:SetFormattedText("%s/%s", ShortValue(min), ShortValue(max))
				elseif health.value.Format == "Absolut Short & Percent" then
					health.value:SetFormattedText("%s/%s | %.1f%%", ShortValue(min),ShortValue(max), healthPercent)
				elseif health.value.Format == "Standard" then
					health.value:SetFormattedText("%s", min)
				elseif health.value.Format == "Standard & Percent" then
					health.value:SetFormattedText("%s | %.1f%%", min, healthPercent)
				elseif health.value.Format == "Standard Short" then
					health.value:SetFormattedText("%s", ShortValue(min))
				elseif health.value.Format == "Standard Short & Percent" then
					health.value:SetFormattedText("%s | %.1f%%", ShortValue(min), healthPercent)
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
				health.value:SetText()
			end
		else
			health.value:SetText()
		end

		if health.valuePercent.Enable == true then
			if min ~= max or health.valuePercent.ShowAlways == true then
				health.valuePercent:SetFormattedText("%.1f%%", healthPercent)
			else
				health.valuePercent:SetText()
			end

			if health.valuePercent.color == "By Class" then
				health.valuePercent:SetTextColor(unpack(color))
			elseif health.valuePercent.color == "Individual" then
				health.valuePercent:SetTextColor(health.valuePercent.colorIndividual.r, health.valuePercent.colorIndividual.g, health.valuePercent.colorIndividual.b)
			else
				health.valuePercent:SetTextColor(oUF.ColorGradient(min, max, module.colors.smooth()))
			end
		else
			health.valuePercent:SetText()
		end

		if health.valueMissing.Enable == true then
			local healthMissing = max-min

			if healthMissing > 0 or health.valueMissing.ShowAlways == true then
				if health.valueMissing.ShortValue == true then
					health.valueMissing:SetFormattedText("-%s", ShortValue(healthMissing))
				else
					health.valueMissing:SetFormattedText("-%s", healthMissing)
				end
			else
				health.valueMissing:SetText()
			end

			if health.valueMissing.color == "By Class" then
				health.valueMissing:SetTextColor(unpack(color))
			elseif health.valueMissing.color == "Individual" then
				health.valueMissing:SetTextColor(health.valueMissing.colorIndividual.r, health.valueMissing.colorIndividual.g, health.valueMissing.colorIndividual.b)
			else
				health.valueMissing:SetTextColor(oUF.ColorGradient(min, max, module.colors.smooth()))
			end
		else
			health.valueMissing:SetText()
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

local OverridePower = function(self, event, unit)
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

	if unit == "player" and entering == true then
		if module.db.player.Bars.Power.Color == "By Class" then
			power:SetStatusBarColor(unpack(color))
		elseif module.db.player.Bars.Power.Color == "Individual" then
			power:SetStatusBarColor(module.db.player.Bars.Power.IndividualColor.r, module.db.player.Bars.Power.IndividualColor.g, module.db.player.Bars.Power.IndividualColor.b)
		else
			power:SetStatusBarColor(unpack(color2))
		end
	else
		if power.color == "By Class" then
			power:SetStatusBarColor(unpack(color))
		elseif power.color == "Individual" then
			power:SetStatusBarColor(power.colorIndividual.r, power.colorIndividual.g, power.colorIndividual.b)
		-- elseif unit == unit:match("boss%d") and select(7, UnitAlternatePowerInfo(unit)) then
		-- 	power:SetStatusBarColor(r, g, b)
		else
			power:SetStatusBarColor(unpack(color2))
		end
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
		power.valueMissing:SetText()
		power.valuePercent:SetText()
		power.value:SetText()
	elseif UnitIsGhost(unit) then
		power:SetValue(0)
		power.valueMissing:SetText()
		power.valuePercent:SetText()
		power.value:SetText()
	elseif UnitIsDead(unit) then
		power:SetValue(0)
		power.valueMissing:SetText()
		power.valuePercent:SetText()
		power.value:SetText()
	else
		local powerPercent = max == 0 and 0 or 100 * (min / max)

		if power.value.Enable == true then
			if (power.value.ShowFull == false and min == max) or (power.value.ShowEmpty == false and min == 0) then
				power.value:SetText()
			elseif power.value.Format == "Absolut" then
				power.value:SetFormattedText("%d/%d", min, max)
			elseif power.value.Format == "Absolut & Percent" then
				power.value:SetFormattedText("%d/%d | %.1f%%", min, max, powerPercent)
			elseif power.value.Format == "Absolut Short" then
				power.value:SetFormattedText("%s/%s", ShortValue(min), ShortValue(max))
			elseif power.value.Format == "Absolut Short & Percent" then
				power.value:SetFormattedText("%s/%s | %.1f%%", ShortValue(min), ShortValue(max), powerPercent)
			elseif power.value.Format == "Standard" then
				power.value:SetFormattedText("%d", min)
			elseif power.value.Format == "Standard & Percent" then
				power.value:SetFormattedText("%d | %.1f%%", min, powerPercent)
			elseif power.value.Format == "Standard Short" then
				power.value:SetFormattedText("%s", ShortValue(min))
			elseif power.value.Format == "Standard Short" then
				power.value:SetFormattedText("%s | %.1f%%", ShortValue(min), powerPercent)
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
			power.value:SetText()
		end

		if power.valuePercent.Enable == true then
			if (power.valuePercent.ShowFull == false and min == max) or (power.valuePercent.ShowEmpty == false and min == 0) then
				power.valuePercent:SetText()
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
			power.valuePercent:SetText()
		end

		if power.valueMissing.Enable == true then
			local powerMissing = max-min

			if (power.valueMissing.ShowFull == false and min == max) or (power.valueMissing.ShowEmpty == false and min == 0) then
				power.valueMissing:SetText()
			elseif power.valueMissing.ShortValue == true then
				power.valueMissing:SetFormattedText("-%s", ShortValue(powerMissing))
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
			power.valueMissing:SetText()
		end
	end
end

local FormatCastbarTime = function(self, duration)
	if self.delay ~= 0 then
		if self.channeling then
			if self.Time.ShowMax == true then
				self.Time:SetFormattedText("%.1f / %.1f |cffff0000%.1f|r", duration, self.max, -self.delay)
			else
				self.Time:SetFormattedText("%.1f |cffff0000%.1f|r", duration, -self.delay)
			end
		elseif self.casting then
			if self.Time.ShowMax == true then
				self.Time:SetFormattedText("%.1f / %.1f |cffff0000%.1f|r", self.max - duration, self.max, -self.delay)
			else
				self.Time:SetFormattedText("%.1f |cffff0000%.1f|r", self.max - duration, -self.delay)
			end
		end
	else
		if self.channeling then
			if self.Time.ShowMax == true then
				self.Time:SetFormattedText("%.1f / %.1f", duration, self.max)
			else
				self.Time:SetFormattedText("%.1f", duration)
			end
		elseif self.casting then
			if self.Time.ShowMax == true then
				self.Time:SetFormattedText("%.1f / %.1f", self.max - duration, self.max)
			else
				self.Time:SetFormattedText("%.1f", self.max - duration)
			end
		end
	end
end

local CreateAuraTimer = function(self,elapsed)
	if self.timeLeft then
		self.elapsed = (self.elapsed or 0) + elapsed
		if self.elapsed >= 0.1 then
			if not self.first then
				self.timeLeft = self.timeLeft - self.elapsed
			else
				self.timeLeft = self.timeLeft - GetTime()
				self.first = false
			end
			if self.timeLeft > 0 then
				self.remaining:SetText(FormatTime(self.timeLeft))
				self.remaining:SetTextColor(1, 1, 1)
			else
				self.remaining:Hide()
				self:SetScript("OnUpdate", nil)
			end
			self.elapsed = 0
		end
	end
end

local PostCreateAura = function(element, button)
	button.backdrop = CreateFrame("Frame", nil, button, "BackdropTemplate")
	button.backdrop:SetPoint("TOPLEFT", button, "TOPLEFT", -3.5, 3)
	button.backdrop:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 4, -3.5)
	button.backdrop:SetFrameStrata("BACKGROUND")
	button.backdrop:SetBackdrop({
		edgeFile = glowTex, edgeSize = 5,
		insets = {left = 3, right = 3, top = 3, bottom = 3}
	})
	button.backdrop:SetBackdropColor(0, 0, 0, 0)
	button.backdrop:SetBackdropBorderColor(0, 0, 0)
	button.count:SetPoint("BOTTOMRIGHT", -1, 2)
	button.count:SetJustifyH("RIGHT")
	button.count:SetFont(font3, 16, "OUTLINE")
	button.count:SetTextColor(0.84, 0.75, 0.65)

	button.remaining = SetFontString(button, Media:Fetch("font", module.db.Settings.AuratimerFont), module.db.Settings.AuratimerSize, module.db.Settings.AuratimerFlag)
	button.remaining:SetPoint("TOPLEFT", 1, -1)

	button.cd.noCooldownCount = true

	button.overlay:Hide()

	button.auratype = button:CreateTexture(nil, "OVERLAY")
	button.auratype:SetTexture(buttonTex)
	button.auratype:SetPoint("TOPLEFT", button, "TOPLEFT", -2, 2)
	button.auratype:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
	button.auratype:SetTexCoord(0, 1, 0.02, 1)
end

local PostUpdateAura = function(icons, unit, icon, index, offset)
	local _, _, _, dtype, duration, expirationTime, unitCaster, _ = UnitAura(unit, index, icon.filter)
	if icon.isDebuff then
		if unitCaster == "player" or unitCaster == "pet" or unitCaster == "vehicle" then
			icon.icon:SetDesaturated()
		else
			icon.icon:SetDesaturated(icons.fadeOthers)
		end
	end

	if icons.showAuraType and dtype then
		local color = DebuffTypeColor[dtype] or DebuffTypeColor.none
		icon.auratype:SetVertexColor(color.r, color.g, color.b)
	else
		if icon.isDebuff then
			icon.auratype:SetVertexColor(0.69, 0.31, 0.31)
		else
			icon.auratype:SetVertexColor(1, 1, 1)
		end
	end

	if icons.disableCooldown or (not duration) or duration <= 0 then
		icon.cd:Hide()
	else
		icon.cd:Show()
	end

	icon.cd:SetReverse(icons.cooldownReverse)

	if duration and duration > 0 then
		if icons.showAuratimer then
			icon.remaining:Show()
		else
			icon.remaining:Hide()
		end
	else
		icon.remaining:Hide()
	end

	icon.duration = duration
	icon.timeLeft = expirationTime
	icon.first = true
	icon:SetScript("OnUpdate", CreateAuraTimer)
end

local CustomFilter = function(icons, unit, icon, name, rank, texture, count, dtype, duration, timeLeft, caster)
	local isPlayer, isPet

	if caster == "player" or caster == "vehicle" then isPlayer = true end
	if caster == "pet" then isPet = true end

	if icons.onlyShowPlayer and (isPlayer or (isPet and icons.includePet)) or (not icons.onlyShowPlayer and name) then
		icon.isPlayer = isPlayer
		icon.isPet = isPet
		icon.owner = caster
		return true
	end
end

local PostCastStart = function(castbar, unit, name)
	local unitname, _ = UnitName(unit)
	if castbar.Colors.Individual == true then
		castbar:SetStatusBarColor(castbar.Colors.Bar.r, castbar.Colors.Bar.g, castbar.Colors.Bar.b, castbar.Colors.Bar.a)
		castbar.bg:SetVertexColor(castbar.Colors.Background.r, castbar.Colors.Background.g, castbar.Colors.Background.b, castbar.Colors.Background.a)
		castbar.Backdrop:SetBackdropBorderColor(castbar.Colors.Border.r, castbar.Colors.Border.g, castbar.Colors.Border.b, castbar.Colors.Border.a)
	else
		if unit == "focus" or unit == "pet" then unit = "player" end
		local pClass, pToken = UnitClass(unit)
		local color = module.colors.class[pToken]

		castbar:SetStatusBarColor(color[1], color[2], color[3], 0.68)
		castbar.bg:SetVertexColor(0.15, 0.15, 0.15, 0.75)
		castbar.Backdrop:SetBackdropBorderColor(0, 0, 0, 0.7)
	end
	if castbar.notInterruptible and castbar.Shielded.Enable and UnitIsEnemy("player", unit) then
		if castbar.Shielded.IndividualColor then
			castbar:SetStatusBarColor(castbar.Shielded.BarColor.r, castbar.Shielded.BarColor.g, castbar.Shielded.BarColor.b, castbar.Shielded.BarColor.a)
		end
		if castbar.Shielded.IndividualBorder then
			castbar.Backdrop:SetBackdrop({
				edgeFile = Media:Fetch("border", castbar.Shielded.Texture),
				edgeSize = castbar.Shielded.Thick,
				insets = {
					left = castbar.Shielded.Inset.L,
					right = castbar.Shielded.Inset.R,
					top = castbar.Shielded.Inset.T,
					bottom = castbar.Shielded.Inset.B,
				},
			})
			castbar.Backdrop:SetBackdropBorderColor(castbar.Shielded.Color.r, castbar.Shielded.Color.g, castbar.Shielded.Color.b, castbar.Shielded.Color.a)
		end
		if castbar.Shielded.Text then
			castbar.Text:SetText(format("%s ** Shielded **", tostring(name)))
		end
	end
end

local PostChannelStart = function(castbar, unit, name)
	local _, _, _, _, startTime, endTime = UnitChannelInfo(unit)
	if castbar.channeling then
		if channelingTicks[name] then
			local tickspeed = channelingTicks[name] / (1 + (UnitSpellHaste(unit) / 100))
			local numticks = floor((castbar.max / tickspeed) + 0.5) - 1
			for i = 1, numticks do
				local tick = castbar:GetTick(i)
				tick.ticktime = tickspeed * i
				tick.delay = 0
				tick:Update()
			end
			castbar.tickspeed = tickspeed
			castbar.numticks = numticks
		else
			castbar:HideTicks()
		end
	end

	PostCastStart(castbar, unit, name)
end

local PostChannelUpdate = function(castbar, unit, name)
	if not castbar.numticks then return end

	local _, _, _, _, startTime, endTime = UnitChannelInfo(unit)

	if castbar.delay < 0 then
		castbar.numticks = castbar.numticks + 1

		for i = 1, castbar.numticks do
			local tick = castbar:GetTick(i)
			tick.ticktime = castbar.tickspeed * i
			tick.delay = 0
			tick:Update()
		end

		castbar.delay = 0
		return
	end

	local _duration = castbar.duration + castbar.delay
	for i = 1, castbar.numticks do
		local tick = castbar:GetTick(i)
		if tick.ticktime < _duration then
			tick.delay = castbar.delay
			tick:Update()
		else
			break
		end
	end
end

local ThreatOverride = function(self, event, unit)
	if unit ~= self.unit then return end
	if unit == "vehicle" then unit = "player" end

	unit = unit or self.unit
	local status = UnitThreatSituation(unit)

	if(status and status > 0) then
		local r, g, b = GetThreatStatusColor(status)
		for i = 1, 8 do
			self.ThreatIndicator[i]:SetVertexColor(r, g, b)
		end
		self.ThreatIndicator:Show()
	else
		self.ThreatIndicator:Hide()
	end
end

local CPointsOverride = function(self, event, unit)
	if unit == "pet" then return end

	local cp
	if UnitExists("vehicle") then
		cp = GetComboPoints("vehicle", "target")
	else
		cp = GetComboPoints("player", "target")
	end

	local cpoints = self.CPoints
	if cp == 0 and not cpoints.showAlways then
		return cpoints:Hide()
	elseif not cpoints:IsShown() then
		cpoints:Show()
	end

	for i = 1, MAX_COMBO_POINTS do
		if i <= cp then
			cpoints[i]:SetValue(1)
		else
			cpoints[i]:SetValue(0)
		end
	end
end

local WarlockBarOverride = function(self, event, unit, powerType)
	local specNum = GetSpecialization()
	local spec = self.WarlockBar.SpecInfo[specNum]
	if not spec then return end
	if self.unit ~= unit or (powerType and powerType ~= spec.powerType) then return end
	local num = UnitPower(unit, spec.unitPower)
	local text = ""
	--Affliction
	if specNum == 1 then
		for i = 1, self.WarlockBar.Amount do
			self.WarlockBar[i]:SetValue(spec.maxValue)
			if i <= num then self.WarlockBar[i]:SetAlpha(1)
			else self.WarlockBar[i]:SetAlpha(.4)
			end
		end
	--Demonology
	elseif specNum == 2 then
		text = num
		self.WarlockBar[1]:SetAlpha(1)
		self.WarlockBar[1]:SetValue(num)
	--Destruction
	elseif specNum == 3 then
		local power = UnitPower(unit, spec.unitPower, true)
		for i = 1, self.WarlockBar.Amount do
			local numOver = power - (i-1)*10
			if i <= num then
				self.WarlockBar[i]:SetAlpha(1)
				self.WarlockBar[i]:SetValue(spec.maxValue)
			elseif numOver > 0 then
				self.WarlockBar[i]:SetAlpha(.6)
				self.WarlockBar[i]:SetValue(numOver)
			else
				self.WarlockBar[i]:SetAlpha(.6)
				self.WarlockBar[i]:SetValue(0)
			end
		end
	end
	if self.WarlockBar.ShowText then
		self.WarlockBar.Text:SetText(text)
	end
end

local ArcaneChargesOverride = function(self, event, unit, powerType)
	if self.unit ~= unit then return end

	local _, _, _, num = UnitDebuff(unit, GetSpellInfo(36032)) -- Arcane Charges
	if not num then num = 0 end
	for i = 1, self.ArcaneCharges.Charges do
		if i <= num then
			self.ArcaneCharges[i]:SetAlpha(1)
		else
			self.ArcaneCharges[i]:SetAlpha(.4)
		end
	end
end

local HolyPowerOverride = function(self, event, unit, powerType)
	if self.unit ~= unit or (powerType and powerType ~= "HOLY_POWER") then return end

	 local num = UnitPower(unit, Enum.PowerType.HolyPower)
	 for i = 1, self.HolyPower.Powers do
		 if i <= num then
			 self.HolyPower[i]:SetAlpha(1)
		 else
			 self.HolyPower[i]:SetAlpha(.4)
		 end
	 end
end

local function TotemsUpdate(self, elapsed)
	self.total = elapsed + (self.total or 0)
	if self.total >= 0.02 then
		self.total = 0
		local haveTotem, name, startTime, duration, totemIcon = GetTotemInfo(self.slot)
		if (((GetTime() - startTime) == 0) or ( duration == 0 )) then
			self:SetValue(0)
		else
			self:SetValue(1 - ((GetTime() - startTime) / duration))
		end
	end
end

local TotemsOverride = function(self, event, slot)
	if slot > MAX_TOTEMS then return end

	local totem = self.Totems[slot]

	local haveTotem, name, startTime, duration, totemIcon = GetTotemInfo(slot)

	local color = module.colors.totems[slot]
	totem:SetStatusBarColor(unpack(color))
	totem:SetValue(0)

	-- Multipliers
	if (totem.bg.multiplier) then
		local mu = totem.bg.multiplier
		local r, g, b = totem:GetStatusBarColor()
		r, g, b = r*mu, g*mu, b*mu
		totem.bg:SetVertexColor(r, g, b)
	end

	if(haveTotem) then
		
		if totem.Name then
			totem.Name:SetText(name)
		end
		if(duration >= 0) then
			totem:SetValue(1 - ((GetTime() - startTime) / duration))
			-- Status bar update
			totem:SetScript("OnUpdate", TotemsUpdate)
		else
			-- There's no need to update because it doesn't have any duration
			totem:SetScript("OnUpdate",nil)
			totem:SetValue(0)
		end
		if totemIcon then
			totem.icon:SetTexture(totemIcon)
		end
	else
		-- No totem = no time 
		if totem.Name then
			totem.Name:SetText(" ")
		end
		totem:SetValue(0)
	end

	for i = 1, MAX_TOTEMS do
		local currTotem = self.Totems[i]
		if GetTotemInfo(i) then
			currTotem:Show()
		else
			currTotem:Hide()
		end
	end

end

local ChiOverride = function(self, event, unit, powerType)
	if self.unit ~= unit or (powerType and powerType ~= "CHI") then return end

	 local num = UnitPower(unit, Enum.PowerType.Chi)
	 for i = 1, self.Chi.Force do
		 if i <= num then
			 self.Chi[i]:SetAlpha(1)
		 else
			 self.Chi[i]:SetAlpha(.4)
		 end
	 end
end

local AdditionalPowerOverride = function(self, event, unit)
	if not unit or not UnitIsUnit(self.unit, unit) then return end
	local _, class = UnitClass(unit)
	local additionalpower = self.AdditionalPower

	local form = GetShapeshiftFormID()
	if self.AdditionalPower.ShouldEnable(unit) then
		additionalpower:Show()
	else
		return additionalpower:Hide()
	end

	local cur, max = UnitPower('player', Enum.PowerType.Mana), UnitPowerMax('player', Enum.PowerType.Mana)

	additionalpower:SetMinMaxValues(0, max)
	additionalpower:SetValue(cur)

	local r, g, b
	if(additionalpower.colorClass and UnitIsPlayer(unit)) then
		r, g, b = unpack(module.colors.class[class])
	elseif(additionalpower.colorSmooth) then
		r, g, b = oUF.ColorGradient(cur, max, module.colors.smooth())
	else
		r, g, b = unpack(module.colors.power['MANA'])
	end
	if(b) then
		additionalpower:SetStatusBarColor(r, g, b)

		local bg = additionalpower.bg
		if(bg) then
			local mu = bg.multiplier or 1
			bg:SetVertexColor(r * mu, g * mu, b * mu)
		end
	end

	if(additionalpower.PostUpdatePower) then
		return additionalpower:PostUpdatePower(unit, cur, max)
	end
end

local PostUpdateAlternativePower = function(altpowerbar, unit, cur, min, max)
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
				altpowerbar.Text:SetText()
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
			altpowerbar.Text:SetText()
		end
	end
end

local PostUpdateAdditionalPower = function(additionalpower, unit, cur, max)
	local _, class = UnitClass(unit)
	if additionalpower.color == "By Class" then
		additionalpower:SetStatusBarColor(unpack(module.colors.class[class]))
	elseif additionalpower.color == "By Type" then
		additionalpower:SetStatusBarColor(unpack(module.colors.power.MANA))
	else
		additionalpower:SetStatusBarColor(oUF.ColorGradient(cur, max, module.colors.smooth()))
	end

	local bg = additionalpower.bg

	if bg then
		local mu = bg.multiplier or 1
		local r, g, b = additionalpower:GetStatusBarColor()
		bg:SetVertexColor(r * mu, g * mu, b * mu)
	end
end

local ArenaEnemyUnseen = function(self, event, unit, state)
	if unit ~= self.unit then return end

	if state == "unseen" then
		self.Health.Override = function(health)
			health:SetValue(0)
			health:SetStatusBarColor(0.5, 0.5, 0.5, 1)
			health.bg:SetVertexColor(0.5, 0.5, 0.5, 1)
			health.value:SetText(health.value.ShowDead and "|cffD7BEA5<Unseen>|r")
			health.valuePercent:SetText(health.valuePercent.ShowDead and "|cffD7BEA5<Unseen>|r")
			health.valueMissing:SetText()
		end
		self.Power.Override = function(power)
			power:SetValue(0)
			power:SetStatusBarColor(0.5, 0.5, 0.5, 1)
			power.bg:SetVertexColor(0.5, 0.5, 0.5, 1)
			power.value:SetText()
			power.valuePercent:SetText()
			power.valueMissing:SetText()
		end

		self.Hide = self.Show
		self:Show()
	else
		self.Health.Override = OverrideHealth
		self.Power.Override = OverridePower

		self.Hide = self.Hide_
	end

	self.Health:ForceUpdate()
	self.Power:ForceUpdate()
end

local PortraitOverride = function(self, event, unit)
	if not unit or not UnitIsUnit(self.unit, unit) then return end

	local portrait = self.Portrait

	if(portrait:IsObjectType"Model") then
		local guid = UnitGUID(unit)
		if not UnitExists(unit) or not UnitIsConnected(unit) or not UnitIsVisible(unit) then
			portrait:SetModelScale(4.25)
			portrait:SetPosition(0, 0, -1.5)
			portrait:SetModel("Interface\\Buttons\\talktomequestionmark.mdx")
			portrait.guid = nil
		elseif(portrait.guid ~= guid or event == "UNIT_MODEL_CHANGED") then
			portrait:SetUnit(unit)
			portrait:SetCamera(portrait:GetModel() == "character\\worgen\\male\\worgenmale.m2" and 1 or 0)

			portrait.guid = guid
		else
			portrait:SetCamera(portrait:GetModel() == "character\\worgen\\male\\worgenmale.m2" and 1 or 0)
		end
	else
		SetPortraitTexture(portrait, unit)
	end

	local a = portrait:GetAlpha()
	portrait:SetAlpha(0)
	portrait:SetAlpha(a)
end

local Reposition = function(V2Tex)
	local to = V2Tex.to
	local from = V2Tex.from

	local toL, toR = to:GetLeft(), to:GetRight()
	local toT, toB = to:GetTop(), to:GetBottom()
	local toCX, toCY = to:GetCenter()
	local toS = to:GetEffectiveScale()

	local fromL, fromR = from:GetLeft(), from:GetRight()
	local fromT, fromB = from:GetTop(), from:GetBottom()
	local fromCX, fromCY = from:GetCenter()
	local fromS = from:GetEffectiveScale()

	if not (toL and toR and toT and toB and toCX and toCY and toS and fromL and fromR and fromT and fromB and fromCX and fromCY and fromS) then return end

	toL, toR = toL * toS, toR * toS
	toT, toB = toT * toS, toB * toS
	toCX, toCY = toCX * toS, toCY * toS

	fromL, fromR = fromL * fromS, fromR * fromS
	--fromT, fromB = fromT * fromS, fromB * fromS
	fromCX, fromCY = fromCX * fromS, fromCY * fromS

	local magicValue = to:GetWidth() / 6

	V2Tex:ClearAllPoints()
	V2Tex.Vertical:ClearAllPoints()
	V2Tex.Horizontal:ClearAllPoints()
	V2Tex.Horizontal2:ClearAllPoints()
	V2Tex.Dot:ClearAllPoints()

	V2Tex:Show()
	V2Tex.Vertical:Show()
	V2Tex.Horizontal:Show()
	V2Tex.Horizontal2:Show()
	V2Tex.Dot:Show()

	if fromL > toR - magicValue then
		V2Tex.Dot:SetPoint("CENTER", V2Tex.Horizontal2, "RIGHT")

		V2Tex.Horizontal2:SetPoint("LEFT", from, "RIGHT")
		V2Tex.Horizontal2:SetWidth(fromL - toR + magicValue)

		if fromCY < toB then
			V2Tex.Vertical:SetPoint("TOPLEFT", V2Tex, "TOPLEFT")
			V2Tex.Vertical:SetPoint("BOTTOMLEFT", V2Tex, "BOTTOMLEFT")

			V2Tex.Horizontal:SetPoint("BOTTOMLEFT", V2Tex, "BOTTOMLEFT")
			V2Tex.Horizontal:SetPoint("BOTTOMRIGHT", V2Tex, "BOTTOMRIGHT")

			V2Tex:SetPoint("TOPLEFT", to, "BOTTOMRIGHT", -magicValue, 0)
			V2Tex:SetPoint("BOTTOMRIGHT", from, "LEFT", 0, -1)
		elseif fromCY > toT then
			V2Tex.Vertical:SetPoint("TOPLEFT", V2Tex, "TOPLEFT")
			V2Tex.Vertical:SetPoint("BOTTOMLEFT", V2Tex, "BOTTOMLEFT")

			V2Tex.Horizontal:SetPoint("TOPLEFT", V2Tex, "TOPLEFT")
			V2Tex.Horizontal:SetPoint("TOPRIGHT", V2Tex, "TOPRIGHT")

			V2Tex:SetPoint("BOTTOMLEFT", to, "TOPRIGHT", -magicValue, 0)
			V2Tex:SetPoint("TOPRIGHT", from, "LEFT", 0, 1)
		elseif fromCY > toCY then
			V2Tex.Vertical:Hide()

			V2Tex.Horizontal:SetPoint("TOPLEFT", V2Tex, "TOPLEFT")
			V2Tex.Horizontal:SetPoint("TOPRIGHT", V2Tex, "TOPRIGHT")

			V2Tex:SetPoint("TOPLEFT", to, "RIGHT", 0, 1)
			V2Tex:SetPoint("BOTTOMRIGHT", from, "LEFT", 0, -1)
		else
			V2Tex.Vertical:Hide()

			V2Tex.Horizontal:SetPoint("BOTTOMLEFT", V2Tex, "BOTTOMLEFT")
			V2Tex.Horizontal:SetPoint("BOTTOMRIGHT", V2Tex, "BOTTOMRIGHT")

			V2Tex:SetPoint("BOTTOMLEFT", to, "RIGHT", 0, -1)
			V2Tex:SetPoint("TOPRIGHT", from, "LEFT", 0, 1)
		end
	elseif toL > fromR - magicValue then
		V2Tex.Dot:SetPoint("CENTER", V2Tex.Horizontal2, "LEFT")

		V2Tex.Horizontal2:SetPoint("RIGHT", from, "LEFT")
		V2Tex.Horizontal2:SetWidth(toL - fromR + magicValue)

		if fromCY < toB then
			V2Tex.Vertical:SetPoint("TOPRIGHT", V2Tex, "TOPRIGHT")
			V2Tex.Vertical:SetPoint("BOTTOMRIGHT", V2Tex, "BOTTOMRIGHT")

			V2Tex.Horizontal:SetPoint("BOTTOMLEFT", V2Tex, "BOTTOMLEFT")
			V2Tex.Horizontal:SetPoint("BOTTOMRIGHT", V2Tex, "BOTTOMRIGHT")

			V2Tex:SetPoint("TOPRIGHT", to, "BOTTOMLEFT", magicValue, 0)
			V2Tex:SetPoint("BOTTOMLEFT", from, "RIGHT", 0, -1)
		elseif fromCY > toT then
			V2Tex.Vertical:SetPoint("TOPRIGHT", V2Tex, "TOPRIGHT")
			V2Tex.Vertical:SetPoint("BOTTOMRIGHT", V2Tex, "BOTTOMRIGHT")

			V2Tex.Horizontal:SetPoint("TOPLEFT", V2Tex, "TOPLEFT")
			V2Tex.Horizontal:SetPoint("TOPRIGHT", V2Tex, "TOPRIGHT")

			V2Tex:SetPoint("BOTTOMRIGHT", to, "TOPLEFT", magicValue, 0)
			V2Tex:SetPoint("TOPLEFT", from, "RIGHT", 0, 1)
		elseif fromCY > toCY then
			V2Tex.Vertical:Hide()

			V2Tex.Horizontal:SetPoint("TOPLEFT", V2Tex, "TOPLEFT")
			V2Tex.Horizontal:SetPoint("TOPRIGHT", V2Tex, "TOPRIGHT")

			V2Tex:SetPoint("TOPRIGHT", to, "LEFT", 0, 1)
			V2Tex:SetPoint("BOTTOMLEFT", from, "RIGHT", 0, -1)
		else
			V2Tex.Vertical:Hide()

			V2Tex.Horizontal:SetPoint("BOTTOMLEFT", V2Tex, "BOTTOMLEFT")
			V2Tex.Horizontal:SetPoint("BOTTOMRIGHT", V2Tex, "BOTTOMRIGHT")

			V2Tex:SetPoint("BOTTOMRIGHT", to, "LEFT", 0, -1)
			V2Tex:SetPoint("TOPLEFT", from, "RIGHT", 0, 1)
		end
	else
		V2Tex.Vertical:SetPoint("TOP", V2Tex, "TOP")
		V2Tex.Vertical:SetPoint("BOTTOM", V2Tex, "BOTTOM")

		V2Tex.Horizontal:Hide()
		V2Tex.Horizontal2:Hide()
		V2Tex.Dot:Hide()

		if toCX > fromCX then
			if toCY > fromCY then
				V2Tex:SetPoint("TOPRIGHT", to, "BOTTOM")
				V2Tex:SetPoint("BOTTOMLEFT", from, "TOP")
			else
				V2Tex:SetPoint("BOTTOMRIGHT", to, "TOP")
				V2Tex:SetPoint("TOPLEFT", from, "BOTTOM")
			end
		else
			if toCY > fromCY then
				V2Tex:SetPoint("TOPLEFT", to, "BOTTOM")
				V2Tex:SetPoint("BOTTOMRIGHT", from, "TOP")
			else
				V2Tex:SetPoint("BOTTOMLEFT", to, "TOP")
				V2Tex:SetPoint("TOPRIGHT", from, "BOTTOM")
			end
		end
	end

	if module:IsHooked(from, "Show") then module:Unhook(from, "Show") end
end

------------------------------------------------------------------------
--	Create/Style Funcs
--	They are stored in the module so the LUI options can easily
--	access them
------------------------------------------------------------------------

module.funcs = {
	Health = function(self, unit, oufdb)
		if not self.Health then
			self.Health = CreateFrame("StatusBar", nil, self)
			self.Health:SetFrameLevel(2)
			self.Health.bg = self.Health:CreateTexture(nil, "BORDER")
			self.Health.bg:SetAllPoints(self.Health)
		end

		self.Health:SetHeight(oufdb.Bars.Health.Height)
		self.Health:SetWidth(oufdb.Bars.Health.Width * self:GetWidth() / oufdb.Width) -- needed for 25/40 man raid width downscaling!
		self.Health:SetStatusBarTexture(Media:Fetch("statusbar", oufdb.Bars.Health.Texture))
		self.Health:ClearAllPoints()
		self.Health:SetPoint("TOPLEFT", self, "TOPLEFT", oufdb.Bars.Health.X * self:GetWidth() / oufdb.Width, oufdb.Bars.Health.Y) -- needed for 25/40 man raid width downscaling!

		self.Health.bg:SetTexture(Media:Fetch("statusbar", oufdb.Bars.Health.TextureBG))
		self.Health.bg:SetAlpha(oufdb.Bars.Health.BGAlpha)
		self.Health.bg.multiplier = oufdb.Bars.Health.BGMultiplier
		self.Health.bg.invert = oufdb.Bars.Health.BGInvert

		self.Health.colorTapping = (unit == "target") and oufdb.Bars.Health.Tapping or false
		self.Health.colorDisconnected = false
		self.Health.color = oufdb.Bars.Health.Color
		self.Health.colorIndividual = oufdb.Bars.Health.IndividualColor
		self.Health.Smooth = oufdb.Bars.Health.Smooth
		self.Health.colorReaction = false
		self.Health.frequentUpdates = true
	end,
	Power = function(self, unit, oufdb)
		if not self.Power then
			self.Power = CreateFrame("StatusBar", nil, self)
			self.Power:SetFrameLevel(2)
			self.Power.bg = self.Power:CreateTexture(nil, "BORDER")
			self.Power.bg:SetAllPoints(self.Power)
		end

		self.Power:SetHeight(oufdb.Bars.Power.Height)
		self.Power:SetWidth(oufdb.Bars.Power.Width * self:GetWidth() / oufdb.Width) -- needed for 25/40 man raid width downscaling!
		self.Power:SetStatusBarTexture(Media:Fetch("statusbar", oufdb.Bars.Power.Texture))
		self.Power:ClearAllPoints()
		self.Power:SetPoint("TOPLEFT", self, "TOPLEFT", oufdb.Bars.Power.X * self:GetWidth() / oufdb.Width, oufdb.Bars.Power.Y) -- needed for 25/40 man raid width downscaling!

		self.Power.bg:SetTexture(Media:Fetch("statusbar", oufdb.Bars.Power.TextureBG))
		self.Power.bg:SetAlpha(oufdb.Bars.Power.BGAlpha)
		self.Power.bg.multiplier = oufdb.Bars.Power.BGMultiplier
		self.Power.bg.invert = oufdb.Bars.Power.BGInvert

		self.Power.colorTapping = false
		self.Power.colorDisconnected = false
		self.Power.colorSmooth = false
		self.Power.color = oufdb.Bars.Power.Color
		self.Power.colorIndividual = oufdb.Bars.Power.IndividualColor
		self.Power.Smooth = oufdb.Bars.Power.Smooth
		self.Power.colorReaction = false
		self.Power.frequentUpdates = true
		self.Power.displayAlternativePower = unit == unit:match("boss%d")

		if oufdb.Bars.Power.Enable == true then
			self.Power:Show()
		else
			self.Power:Hide()
		end
	end,
	FrameBackdrop = function(self, unit, oufdb)
		if not self.FrameBackdrop then self.FrameBackdrop = CreateFrame("Frame", nil, self, "BackdropTemplate") end

		self.FrameBackdrop:ClearAllPoints()
		self.FrameBackdrop:SetPoint("TOPLEFT", self, "TOPLEFT", oufdb.Backdrop.Padding.Left, oufdb.Backdrop.Padding.Top)
		self.FrameBackdrop:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", oufdb.Backdrop.Padding.Right, oufdb.Backdrop.Padding.Bottom)
		self.FrameBackdrop:SetFrameStrata("BACKGROUND")
		self.FrameBackdrop:SetBackdrop({
			bgFile = Media:Fetch("background", oufdb.Backdrop.Texture),
			edgeFile = Media:Fetch("border", oufdb.Border.EdgeFile),
			edgeSize = oufdb.Border.EdgeSize,
			insets = {
				left = oufdb.Border.Insets.Left,
				right = oufdb.Border.Insets.Right,
				top = oufdb.Border.Insets.Top,
				bottom = oufdb.Border.Insets.Bottom
			}
		})
		self.FrameBackdrop:SetBackdropColor(oufdb.Backdrop.Color.r, oufdb.Backdrop.Color.g, oufdb.Backdrop.Color.b, oufdb.Backdrop.Color.a)
		self.FrameBackdrop:SetBackdropBorderColor(oufdb.Border.Color.r, oufdb.Border.Color.g, oufdb.Border.Color.b, oufdb.Border.Color.a)
	end,

	--texts
	Info = function(self, unit, oufdb)
		if not self.Info then self.Info = SetFontString(self.Overlay, Media:Fetch("font", oufdb.Texts.Name.Font), oufdb.Texts.Name.Size, oufdb.Texts.Name.Outline) end
		self.Info:SetFont(Media:Fetch("font", oufdb.Texts.Name.Font), oufdb.Texts.Name.Size, oufdb.Texts.Name.Outline)
		self.Info:SetTextColor(oufdb.Texts.Name.IndividualColor.r, oufdb.Texts.Name.IndividualColor.g, oufdb.Texts.Name.IndividualColor.b)
		self.Info:ClearAllPoints()
		self.Info:SetPoint(oufdb.Texts.Name.Point, self, oufdb.Texts.Name.RelativePoint, oufdb.Texts.Name.X, oufdb.Texts.Name.Y)

		if oufdb.Texts.Name.Enable == true then
			self.Info:Show()
		else
			self.Info:Hide()
		end

		for k, v in pairs(oufdb.Texts.Name) do
			self.Info[k] = v
		end
		self:FormatName()
	end,
	RaidInfo = function(self, unit, oufdb)
		if not self.Info then
			self.Info = SetFontString(self.Overlay, Media:Fetch("font", oufdb.Texts.Name.Font), oufdb.Texts.Name.Size, oufdb.Texts.Name.Outline)
			self.Info:SetPoint("CENTER", self, "CENTER", 0, 0)
		end
		self.Info:SetTextColor(oufdb.Texts.Name.IndividualColor.r, oufdb.Texts.Name.IndividualColor.g, oufdb.Texts.Name.IndividualColor.b)
		self.Info:SetFont(Media:Fetch("font", oufdb.Texts.Name.Font), oufdb.Texts.Name.Size, oufdb.Texts.Name.Outline)

		if oufdb.Texts.Name.Enable == true then
			self.Info:Show()
		else
			self.Info:Hide()
		end

		for k, v in pairs(oufdb.Texts.Name) do
			self.Info[k] = v
		end

		self:FormatRaidName()
	end,

	HealthValue = function(self, unit, oufdb)
		if not self.Health.value then self.Health.value = SetFontString(self.Overlay, Media:Fetch("font", oufdb.Texts.Health.Font), oufdb.Texts.Health.Size, oufdb.Texts.Health.Outline) end
		self.Health.value:SetFont(Media:Fetch("font", oufdb.Texts.Health.Font), oufdb.Texts.Health.Size, oufdb.Texts.Health.Outline)
		self.Health.value:ClearAllPoints()
		self.Health.value:SetPoint(oufdb.Texts.Health.Point, self, oufdb.Texts.Health.RelativePoint, oufdb.Texts.Health.X, oufdb.Texts.Health.Y)

		if oufdb.Texts.Health.Enable == true then
			self.Health.value:Show()
		else
			self.Health.value:Hide()
		end

		self.Health.value.Enable = oufdb.Texts.Health.Enable
		self.Health.value.ShowAlways = oufdb.Texts.Health.ShowAlways
		self.Health.value.ShowDead = oufdb.Texts.Health.ShowDead
		self.Health.value.Format = oufdb.Texts.Health.Format
		self.Health.value.color = oufdb.Texts.Health.Color
		self.Health.value.colorIndividual = oufdb.Texts.Health.IndividualColor
	end,
	HealthPercent = function(self, unit, oufdb)
		if not self.Health.valuePercent then self.Health.valuePercent = SetFontString(self.Overlay, Media:Fetch("font", oufdb.Texts.HealthPercent.Font), oufdb.Texts.HealthPercent.Size, oufdb.Texts.HealthPercent.Outline) end
		self.Health.valuePercent:SetFont(Media:Fetch("font", oufdb.Texts.HealthPercent.Font), oufdb.Texts.HealthPercent.Size, oufdb.Texts.HealthPercent.Outline)
		self.Health.valuePercent:ClearAllPoints()
		self.Health.valuePercent:SetPoint(oufdb.Texts.HealthPercent.Point, self, oufdb.Texts.HealthPercent.RelativePoint, oufdb.Texts.HealthPercent.X, oufdb.Texts.HealthPercent.Y)

		if oufdb.Texts.HealthPercent.Enable == true then
			self.Health.valuePercent:Show()
		else
			self.Health.valuePercent:Hide()
		end

		self.Health.valuePercent.Enable = oufdb.Texts.HealthPercent.Enable
		self.Health.valuePercent.ShowAlways = oufdb.Texts.HealthPercent.ShowAlways
		self.Health.valuePercent.ShowDead = oufdb.Texts.HealthPercent.ShowDead
		self.Health.valuePercent.color = oufdb.Texts.HealthPercent.Color
		self.Health.valuePercent.colorIndividual = oufdb.Texts.HealthPercent.IndividualColor
	end,
	HealthMissing = function(self, unit, oufdb)
		if not self.Health.valueMissing then self.Health.valueMissing = SetFontString(self.Overlay, Media:Fetch("font", oufdb.Texts.HealthMissing.Font), oufdb.Texts.HealthMissing.Size, oufdb.Texts.HealthMissing.Outline) end
		self.Health.valueMissing:SetFont(Media:Fetch("font", oufdb.Texts.HealthMissing.Font), oufdb.Texts.HealthMissing.Size, oufdb.Texts.HealthMissing.Outline)
		self.Health.valueMissing:ClearAllPoints()
		self.Health.valueMissing:SetPoint(oufdb.Texts.HealthMissing.Point, self, oufdb.Texts.HealthMissing.RelativePoint, oufdb.Texts.HealthMissing.X, oufdb.Texts.HealthMissing.Y)

		if oufdb.Texts.HealthMissing.Enable == true then
			self.Health.valueMissing:Show()
		else
			self.Health.valueMissing:Hide()
		end

		self.Health.valueMissing.Enable = oufdb.Texts.HealthMissing.Enable
		self.Health.valueMissing.ShowAlways = oufdb.Texts.HealthMissing.ShowAlways
		self.Health.valueMissing.ShortValue = oufdb.Texts.HealthMissing.ShortValue
		self.Health.valueMissing.color = oufdb.Texts.HealthMissing.Color
		self.Health.valueMissing.colorIndividual = oufdb.Texts.HealthMissing.IndividualColor
	end,

	PowerValue = function(self, unit, oufdb)
		if not self.Power.value then self.Power.value = SetFontString(self.Overlay, Media:Fetch("font", oufdb.Texts.Power.Font), oufdb.Texts.Power.Size, oufdb.Texts.Power.Outline) end
		self.Power.value:SetFont(Media:Fetch("font", oufdb.Texts.Power.Font), oufdb.Texts.Power.Size, oufdb.Texts.Power.Outline)
		self.Power.value:ClearAllPoints()
		self.Power.value:SetPoint(oufdb.Texts.Power.Point, self, oufdb.Texts.Power.RelativePoint, oufdb.Texts.Power.X, oufdb.Texts.Power.Y)

		if oufdb.Texts.Power.Enable == true then
			self.Power.value:Show()
		else
			self.Power.value:Hide()
		end

		self.Power.value.Enable = oufdb.Texts.Power.Enable
		self.Power.value.ShowFull = oufdb.Texts.Power.ShowFull
		self.Power.value.ShowEmpty = oufdb.Texts.Power.ShowEmpty
		self.Power.value.Format = oufdb.Texts.Power.Format
		self.Power.value.color = oufdb.Texts.Power.Color
		self.Power.value.colorIndividual = oufdb.Texts.Power.IndividualColor
	end,
	PowerPercent = function(self, unit, oufdb)
		if not self.Power.valuePercent then self.Power.valuePercent = SetFontString(self.Overlay, Media:Fetch("font", oufdb.Texts.PowerPercent.Font), oufdb.Texts.PowerPercent.Size, oufdb.Texts.PowerPercent.Outline) end
		self.Power.valuePercent:SetFont(Media:Fetch("font", oufdb.Texts.PowerPercent.Font), oufdb.Texts.PowerPercent.Size, oufdb.Texts.PowerPercent.Outline)
		self.Power.valuePercent:ClearAllPoints()
		self.Power.valuePercent:SetPoint(oufdb.Texts.PowerPercent.Point, self, oufdb.Texts.PowerPercent.RelativePoint, oufdb.Texts.PowerPercent.X, oufdb.Texts.PowerPercent.Y)

		if oufdb.Texts.PowerPercent.Enable == true then
			self.Power.valuePercent:Show()
		else
			self.Power.valuePercent:Hide()
		end

		self.Power.valuePercent.Enable = oufdb.Texts.PowerPercent.Enable
		self.Power.valuePercent.ShowFull = oufdb.Texts.PowerPercent.ShowFull
		self.Power.valuePercent.ShowEmpty = oufdb.Texts.PowerPercent.ShowEmpty
		self.Power.valuePercent.color = oufdb.Texts.PowerPercent.Color
		self.Power.valuePercent.colorIndividual = oufdb.Texts.PowerPercent.IndividualColor
	end,
	PowerMissing = function(self, unit, oufdb)
		if not self.Power.valueMissing then self.Power.valueMissing = SetFontString(self.Overlay, Media:Fetch("font", oufdb.Texts.PowerMissing.Font), oufdb.Texts.PowerMissing.Size, oufdb.Texts.PowerMissing.Outline) end
		self.Power.valueMissing:SetFont(Media:Fetch("font", oufdb.Texts.PowerMissing.Font), oufdb.Texts.PowerMissing.Size, oufdb.Texts.PowerMissing.Outline)
		self.Power.valueMissing:ClearAllPoints()
		self.Power.valueMissing:SetPoint(oufdb.Texts.PowerMissing.Point, self, oufdb.Texts.PowerMissing.RelativePoint, oufdb.Texts.PowerMissing.X, oufdb.Texts.PowerMissing.Y)

		if oufdb.Texts.PowerMissing.Enable == true then
			self.Power.valueMissing:Show()
		else
			self.Power.valueMissing:Hide()
		end

		self.Power.valueMissing.Enable = oufdb.Texts.PowerMissing.Enable
		self.Power.valueMissing.ShowFull = oufdb.Texts.PowerMissing.ShowFull
		self.Power.valueMissing.ShowEmpty = oufdb.Texts.PowerMissing.ShowEmpty
		self.Power.valueMissing.ShortValue = oufdb.Texts.PowerMissing.ShortValue
		self.Power.valueMissing.color = oufdb.Texts.PowerMissing.Color
		self.Power.valueMissing.colorIndividual = oufdb.Texts.PowerMissing.IndividualColor
	end,

	-- Indicators
	LeaderIndicator = function(self, unit, oufdb)
		if not self.LeaderIndicator then
			self.LeaderIndicator = self.Overlay:CreateTexture(nil, "OVERLAY")
			self.AssistantIndicator = self.Overlay:CreateTexture(nil, "OVERLAY")
		end

		self.LeaderIndicator:SetHeight(oufdb.Indicators.Leader.Size)
		self.LeaderIndicator:SetWidth(oufdb.Indicators.Leader.Size)
		self.LeaderIndicator:ClearAllPoints()
		self.LeaderIndicator:SetPoint(oufdb.Indicators.Leader.Point, self, oufdb.Indicators.Leader.Point, oufdb.Indicators.Leader.X, oufdb.Indicators.Leader.Y)

		self.AssistantIndicator:SetHeight(oufdb.Indicators.Leader.Size)
		self.AssistantIndicator:SetWidth(oufdb.Indicators.Leader.Size)
		self.AssistantIndicator:ClearAllPoints()
		self.AssistantIndicator:SetPoint(oufdb.Indicators.Leader.Point, self, oufdb.Indicators.Leader.Point, oufdb.Indicators.Leader.X, oufdb.Indicators.Leader.Y)
	end,
	RaidTargetIndicator = function(self, unit, oufdb)
		if not self.RaidTargetIndicator then
			self.RaidTargetIndicator = self.Overlay:CreateTexture(nil, "OVERLAY")
			self.RaidTargetIndicator:SetTexture("Interface\\AddOns\\LUI\\media\\textures\\icons\\raidicons.blp")
		end

		self.RaidTargetIndicator:SetHeight(oufdb.Indicators.Raid.Size)
		self.RaidTargetIndicator:SetWidth(oufdb.Indicators.Raid.Size)
		self.RaidTargetIndicator:ClearAllPoints()
		self.RaidTargetIndicator:SetPoint(oufdb.Indicators.Raid.Point, self, oufdb.Indicators.Raid.Point, oufdb.Indicators.Raid.X, oufdb.Indicators.Raid.Y)
	end,
	GroupRoleIndicator = function(self, unit, oufdb)
		if not self.GroupRoleIndicator then self.GroupRoleIndicator = self.Overlay:CreateTexture(nil, "OVERLAY") end

		self.GroupRoleIndicator:SetHeight(oufdb.Indicators.Role.Size)
		self.GroupRoleIndicator:SetWidth(oufdb.Indicators.Role.Size)
		self.GroupRoleIndicator:ClearAllPoints()
		self.GroupRoleIndicator:SetPoint(oufdb.Indicators.Role.Point, self, oufdb.Indicators.Role.Point, oufdb.Indicators.Role.X, oufdb.Indicators.Role.Y)
	end,
	PvPIndicator = function(self, unit, oufdb)
		if not self.PvPIndicator then
			self.PvPIndicator = self.Overlay:CreateTexture(nil, "OVERLAY")
			if unit == "player" then
				self.PvPIndicator.Timer = SetFontString(self.Overlay, Media:Fetch("font", oufdb.Texts.PvP.Font), oufdb.Texts.PvP.Size, oufdb.Texts.PvP.Outline)
				self.Health:HookScript("OnUpdate", function(_, elapsed)
					if UnitIsPVP(unit) and oufdb.Indicators.PvP.Enable and oufdb.Texts.PvP.Enable then
						if (GetPVPTimer() == 301000 or GetPVPTimer() == -1) then
							if self.PvPIndicator.Timer:IsShown() then
								self.PvPIndicator.Timer:Hide()
							end
						else
							self.PvPIndicator.Timer:Show()
							local min = math.floor(GetPVPTimer()/1000/60)
							local sec = (math.floor(GetPVPTimer()/1000))-(min*60)
							self.PvPIndicator.Timer:SetFormattedText("%d:%.2d", min, sec)
						end
					elseif self.PvPIndicator.Timer:IsShown() then
						self.PvPIndicator.Timer:Hide()
					end
				end)
			end
		end

		self.PvPIndicator:SetHeight(oufdb.Indicators.PvP.Size)
		self.PvPIndicator:SetWidth(oufdb.Indicators.PvP.Size)
		self.PvPIndicator:ClearAllPoints()
		self.PvPIndicator:SetPoint(oufdb.Indicators.PvP.Point, self, oufdb.Indicators.PvP.Point, oufdb.Indicators.PvP.X, oufdb.Indicators.PvP.Y)

		if self.PvPIndicator.Timer then
			self.PvPIndicator.Timer:SetFont(Media:Fetch("font", oufdb.Texts.PvP.Font), oufdb.Texts.PvP.Size, oufdb.Texts.PvP.Outline)
			self.PvPIndicator.Timer:SetPoint("CENTER", self.PvPIndicator, "CENTER", oufdb.Texts.PvP.X, oufdb.Texts.PvP.Y)
			self.PvPIndicator.Timer:SetTextColor(oufdb.Texts.PvP.Color.r, oufdb.Texts.PvP.Color.g, oufdb.Texts.PvP.Color.b)

			if oufdb.Indicators.PvP.Enable and oufdb.Texts.PvP.Enable then
				self.PvPIndicator.Timer:Show()
			else
				self.PvPIndicator.Timer:Hide()
			end
		end
	end,
	RestingIndicator = function(self, unit, oufdb)
		if not self.RestingIndicator then self.RestingIndicator = self.Overlay:CreateTexture(nil, "OVERLAY") end

		self.RestingIndicator:SetHeight(oufdb.Indicators.Resting.Size)
		self.RestingIndicator:SetWidth(oufdb.Indicators.Resting.Size)
		self.RestingIndicator:ClearAllPoints()
		self.RestingIndicator:SetPoint(oufdb.Indicators.Resting.Point, self, oufdb.Indicators.Resting.Point, oufdb.Indicators.Resting.X, oufdb.Indicators.Resting.Y)
	end,
	CombatIndicator = function(self, unit, oufdb)
		if not self.CombatIndicator then self.CombatIndicator = self.Overlay:CreateTexture(nil, "OVERLAY") end

		self.CombatIndicator:SetHeight(oufdb.Indicators.Combat.Size)
		self.CombatIndicator:SetWidth(oufdb.Indicators.Combat.Size)
		self.CombatIndicator:ClearAllPoints()
		self.CombatIndicator:SetPoint(oufdb.Indicators.Combat.Point, self, oufdb.Indicators.Combat.Point, oufdb.Indicators.Combat.X, oufdb.Indicators.Combat.Y)
	end,
	ReadyCheckIndicator = function(self, unit, oufdb)
		if not self.ReadyCheckIndicator then self.ReadyCheckIndicator = self.Overlay:CreateTexture(nil, "OVERLAY") end

		self.ReadyCheckIndicator:SetHeight(oufdb.Indicators.ReadyCheck.Size)
		self.ReadyCheckIndicator:SetWidth(oufdb.Indicators.ReadyCheck.Size)
		self.ReadyCheckIndicator:ClearAllPoints()
		self.ReadyCheckIndicator:SetPoint(oufdb.Indicators.ReadyCheck.Point, self, oufdb.Indicators.ReadyCheck.Point, oufdb.Indicators.ReadyCheck.X, oufdb.Indicators.ReadyCheck.Y)
	end,

	Runes = function(self, unit, oufdb)
		if not self.Runes then
			self.Runes = CreateFrame("Frame", nil, self)
			self.Runes:SetFrameLevel(6)
				
			for i = 1, 6 do
				self.Runes[i] = CreateFrame("StatusBar", nil, self.Runes, "BackdropTemplate")
				self.Runes[i]:SetBackdrop(backdrop)
				self.Runes[i]:SetBackdropColor(0.08, 0.08, 0.08)
				self.Runes[i]:RegisterEvent("RUNE_POWER_UPDATE")

			end

			self.Runes.FrameBackdrop = CreateFrame("Frame", nil, self.Runes, "BackdropTemplate")
			self.Runes.FrameBackdrop:SetPoint("TOPLEFT", self.Runes, "TOPLEFT", -3.5, 3)
			self.Runes.FrameBackdrop:SetPoint("BOTTOMRIGHT", self.Runes, "BOTTOMRIGHT", 3.5, -3)
			self.Runes.FrameBackdrop:SetFrameStrata("BACKGROUND")
			self.Runes.FrameBackdrop:SetBackdrop({
				edgeFile = glowTex, edgeSize = 5,
				insets = {left = 3, right = 3, top = 3, bottom = 3}
			})
			self.Runes.FrameBackdrop:SetBackdropColor(0, 0, 0, 0)
			self.Runes.FrameBackdrop:SetBackdropBorderColor(0, 0, 0)
		end

		local x = oufdb.Bars.Runes.Lock and 0 or oufdb.Bars.Runes.X
		local y = oufdb.Bars.Runes.Lock and 0.5 or oufdb.Bars.Runes.Y

		self.Runes:SetHeight(oufdb.Bars.Runes.Height)
		self.Runes:SetWidth(oufdb.Bars.Runes.Width)
		self.Runes:ClearAllPoints()
		self.Runes:SetPoint("BOTTOMLEFT", self, "TOPLEFT", x, y)

		for i = 1, 6 do
			local runeType = (_G.GetRuneType) and _G.GetRuneType(i) or 1
			self.Runes[i]:SetStatusBarTexture(Media:Fetch("statusbar", oufdb.Bars.Runes.Texture))
			self.Runes[i]:SetStatusBarColor(unpack(module.colors.runes[runeType]))
			self.Runes[i]:SetSize(((oufdb.Bars.Runes.Width - 5 * oufdb.Bars.Runes.Padding) / 6), oufdb.Bars.Runes.Height)

			self.Runes[i]:ClearAllPoints()
			local runePoints = {0, 1, 6, 3, 2, 5}
			if runePoints[i] == 0 then
				self.Runes[i]:SetPoint("LEFT", self.Runes, "LEFT", 0, 0)
			else
				self.Runes[i]:SetPoint("LEFT", self.Runes[runePoints[i]], "RIGHT", oufdb.Bars.Runes.Padding, 0)
			end
		end
	end,

	Totems = function(self, unit, oufdb)
		if not self.Totems then
			self.Totems = CreateFrame("Frame", nil, self)
			self.Totems:SetFrameLevel(6)

			for i = 1, MAX_TOTEMS do
				local bar = CreateFrame("StatusBar", nil, self.Totems, "BackdropTemplate")
				bar:SetBackdrop(backdrop)
				bar:SetBackdropColor(0, 0, 0)
				bar:SetMinMaxValues(0, 1)
				bar.slot = i

				bar.bg = bar:CreateTexture(nil, "BORDER")
				bar.bg:SetAllPoints(bar)
				bar.bg:SetTexture(normTex)

				bar.icon = bar:CreateTexture(nil, "OVERLAY")
				bar.icon:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT")
				bar.icon:SetSize(oufdb.Bars.Totems.Height * oufdb.Bars.Totems.IconScale, oufdb.Bars.Totems.Height * oufdb.Bars.Totems.IconScale)

				local btn = CreateFrame("Button", nil, bar, "SecureActionButtonTemplate")
				btn:RegisterForClicks("AnyUp")
				btn:SetAllPoints(bar)
				btn:SetAttribute("unit", "player")
				btn:SetAttribute("type", "destroytotem")
				btn:SetAttribute("totem-slot", i)

				self.Totems[i] = bar
				self.Totems[i].btn = btn
			end
			
			
			self.Totems.FrameBackdrop = CreateFrame("Frame", nil, self.Totems, "BackdropTemplate")
			self.Totems.FrameBackdrop:SetPoint("TOPLEFT", self.Totems, "TOPLEFT", -3.5, 3)
			self.Totems.FrameBackdrop:SetPoint("BOTTOMRIGHT", self.Totems, "BOTTOMRIGHT", 3.5, -3)
			self.Totems.FrameBackdrop:SetFrameStrata("BACKGROUND")
			self.Totems.FrameBackdrop:SetBackdrop({
				edgeFile = glowTex, edgeSize = 5,
				insets = {left = 3, right = 3, top = 3, bottom = 3}
			})
			self.Totems.FrameBackdrop:SetBackdropColor(0, 0, 0, 0)
			self.Totems.FrameBackdrop:SetBackdropBorderColor(0, 0, 0)

			self.Totems.Override = TotemsOverride
		end

		local x = oufdb.Bars.Totems.Lock and 0 or oufdb.Bars.Totems.X
		local y = oufdb.Bars.Totems.Lock and 0.5 or oufdb.Bars.Totems.Y

		self.Totems:ClearAllPoints()
		self.Totems:SetSize(oufdb.Bars.Totems.Width, oufdb.Bars.Totems.Height)
		self.Totems:SetPoint("BOTTOMLEFT", self, "TOPLEFT", x, y)

		local totemPoints = {0, 1, 2, 3}

		for i = 1, MAX_TOTEMS do
			local bar = self.Totems[i]
			bar:SetStatusBarTexture(Media:Fetch("statusbar", oufdb.Bars.Totems.Texture))
			bar:SetHeight(oufdb.Bars.Totems.Height)
			bar:SetWidth((oufdb.Bars.Totems.Width - 3 * oufdb.Bars.Totems.Padding) / 4)
			bar.icon:SetSize(oufdb.Bars.Totems.Height * oufdb.Bars.Totems.IconScale, oufdb.Bars.Totems.Height * oufdb.Bars.Totems.IconScale)

			bar:ClearAllPoints()
			if totemPoints[i] == 0 then
				bar:SetPoint("LEFT", self.Totems, "LEFT", 0, 0)
			else
				bar:SetPoint("LEFT", self.Totems[totemPoints[i]], "RIGHT", oufdb.Bars.Totems.Padding, 0)
			end

			bar.bg.multiplier = oufdb.Bars.Totems.Multiplier
		end
	end,
	ClassPower = function(self, unit, oufdb)
		local BASE_COUNT = {
			MAGE = 4,
			MONK = 5,
			PALADIN = 5,
			ROGUE = 5,
			WARLOCK = 5,
			DRUID = 5,
		}
		-- The maximum of a ressource a given class can have
		local MAX_COUNT = {
			MAGE = 4,
			MONK = 6,
			PALADIN = 5,
			ROGUE = 6,
			WARLOCK = 5,
			DRUID = 5,
		}
		local r, g, b
		if LUI.MONK then r, g, b = unpack(module.colors.chibar[1])
		elseif LUI.PALADIN then r, g, b = unpack(module.colors.holypowerbar[1])
		elseif LUI.MAGE then r, g, b = unpack(module.colors.arcanechargesbar[1])
		elseif LUI.WARLOCK then r, g, b = unpack(module.colors.warlockbar.Shard1)
		elseif LUI.ROGUE then r, g, b = unpack(module.colors.combopoints[1])
		elseif LUI.DRUID then r, g, b = unpack(module.colors.combopoints[1])
		end
		
		if not self.ClassPower then
			self.ClassPower = CreateFrame("Frame", nil, self, "BackdropTemplate")
			self.ClassPower:SetFrameLevel(6)
			self.ClassPower:SetFrameStrata("BACKGROUND")
			self.ClassPower:SetBackdrop({
				bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			})
			self.ClassPower:SetBackdropColor(r * 0.4, g * 0.4, b * 0.4)
			self.ClassPower.Count = BASE_COUNT[LUI.playerClass]
			self.ClassPower.MaxCount = MAX_COUNT[LUI.playerClass]

			for i = 1, MAX_COUNT[LUI.playerClass] do -- Always create frames for the max possible
				self.ClassPower[i] = self.ClassPower:CreateTexture(nil, "ARTWORK")
			end
		end

		local x = oufdb.Bars.ClassPower.Lock and 0 or oufdb.Bars.ClassPower.X
		local y = oufdb.Bars.ClassPower.Lock and 0.5 or oufdb.Bars.ClassPower.Y

		self.ClassPower:SetHeight(oufdb.Bars.ClassPower.Height)
		self.ClassPower:SetWidth(oufdb.Bars.ClassPower.Width)
		self.ClassPower:ClearAllPoints()
		self.ClassPower:SetPoint("BOTTOMLEFT", self, "TOPLEFT", x, y)
	
		local function checkPowers(event, level)
			local pLevel = (event == "UNIT_LEVEL") and tonumber(level) or UnitLevel("player")
			local count = BASE_COUNT[LUI.playerClass]
			if LUI.MONK then
				if select(4, GetTalentInfo(3, 1, 1)) then
					count = count + 1
				end
			elseif LUI.ROGUE then
				--Check for Strategem, increase CPoints to 6.
				if select(4, GetTalentInfo(3, 2, 1)) then
					count = 6
				end
			end
			self.ClassPower.Count = count

			for i = 1, MAX_COUNT[LUI.playerClass] do
				if oufdb.Bars.ClassPower.Texture == "Empty" then
					self.ClassPower[i]:SetColorTexture(r, g, b)
				else
					self.ClassPower[i]:SetTexture(Media:Fetch("statusbar", oufdb.Bars.ClassPower.Texture))
					self.ClassPower[i]:SetDesaturated(true)
					self.ClassPower[i]:SetVertexColor(r, g, b)
				end
				self.ClassPower[i]:SetSize(((oufdb.Bars.ClassPower.Width - 2*oufdb.Bars.ClassPower.Padding) / self.ClassPower.Count), oufdb.Bars.ClassPower.Height)
				self.ClassPower[i]:ClearAllPoints()
				if i == 1 then
					self.ClassPower[i]:SetPoint("LEFT", self.ClassPower, "LEFT", 0, 0)
				else
					self.ClassPower[i]:SetPoint("LEFT", self.ClassPower[i-1], "RIGHT", oufdb.Bars.ClassPower.Padding, 0)
				end
				--LUI:Print("ClassIcon["..i.."] Is Shown")
				--self.ClassPower[i]:Show()
				if i > self.ClassPower.Count then
					self.ClassPower[i]:Hide()
				end
			end
		end
		checkPowers()

		module:RegisterEvent("UNIT_LEVEL", checkPowers)
		module:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", checkPowers)
		module:RegisterEvent("PLAYER_TALENT_UPDATE", checkPowers)
		self.ClassPower.UpdateTexture = checkPowers
	end,
	AlternativePower = function(self, unit, oufdb)
		if not self.AlternativePower then
			self.AlternativePower = CreateFrame("StatusBar", nil, self)
			if unit == "pet" then self.AlternativePower:SetParent(oUF_LUI_player) end

			self.AlternativePower.bg = self.AlternativePower:CreateTexture(nil, "BORDER")
			self.AlternativePower.bg:SetAllPoints(self.AlternativePower)

			self.AlternativePower.SetPosition = function()
				if not module.db.player.Bars.AlternativePower.OverPower then return end

				if oUF_LUI_player.AlternativePower:IsShown() or (oUF_LUI_pet and oUF_LUI_pet.AlternativePower and oUF_LUI_pet.AlternativePower:IsShown()) then
					oUF_LUI_player.Power:SetHeight(module.db.player.Bars.Power.Height/2 - 1)
					oUF_LUI_player.AlternativePower:SetHeight(module.db.player.Bars.Power.Height/2 - 1)
				else
					oUF_LUI_player.Power:SetHeight(module.db.player.Bars.Power.Height)
					oUF_LUI_player.AlternativePower:SetHeight(module.db.player.Bars.AlternativePower.Height)
				end
			end

			self.AlternativePower:SetScript("OnShow", function()
				self.AlternativePower.SetPosition()
				self.AlternativePower:ForceUpdate()
			end)
			self.AlternativePower:SetScript("OnHide", self.AlternativePower.SetPosition)

			self.AlternativePower.Text = SetFontString(self.AlternativePower, Media:Fetch("font", module.db.player.Texts.AlternativePower.Font), module.db.player.Texts.AlternativePower.Size, module.db.player.Texts.AlternativePower.Outline)
		end

		self.AlternativePower:ClearAllPoints()
		if unit == "player" then
			if module.db.player.Bars.AlternativePower.OverPower then
				self.AlternativePower:SetPoint("TOPLEFT", self.Power, "BOTTOMLEFT", 0, -2)
				self.AlternativePower:SetPoint("TOPRIGHT", self.Power, "BOTTOMRIGHT", 0, -2)
			else
				self.AlternativePower:SetPoint("TOPLEFT", self, "TOPLEFT", module.db.player.Bars.AlternativePower.X, module.db.player.Bars.AlternativePower.Y)
			end
		else
			self.AlternativePower:SetPoint("TOPLEFT", oUF_LUI_player.AlternativePower, "TOPLEFT", 0, 0)
			self.AlternativePower:SetPoint("BOTTOMRIGHT", oUF_LUI_player.AlternativePower, "BOTTOMRIGHT", 0, 0)
		end

		self.AlternativePower:SetHeight(module.db.player.Bars.AlternativePower.Height)
		self.AlternativePower:SetWidth(module.db.player.Bars.AlternativePower.Width)
		self.AlternativePower:SetStatusBarTexture(Media:Fetch("statusbar", module.db.player.Bars.AlternativePower.Texture))

		self.AlternativePower.bg:SetTexture(Media:Fetch("statusbar", module.db.player.Bars.AlternativePower.TextureBG))
		self.AlternativePower.bg:SetAlpha(module.db.player.Bars.AlternativePower.BGAlpha)
		self.AlternativePower.bg.multiplier = module.db.player.Bars.AlternativePower.BGMultiplier

		self.AlternativePower.Smooth = module.db.player.Bars.AlternativePower.Smooth
		self.AlternativePower.color = module.db.player.Bars.AlternativePower.Color
		self.AlternativePower.colorIndividual = module.db.player.Bars.AlternativePower.IndividualColor
		
		self.AlternativePower.Text:SetFont(Media:Fetch("font", module.db.player.Texts.AlternativePower.Font), module.db.player.Texts.AlternativePower.Size, module.db.player.Texts.AlternativePower.Outline)
		self.AlternativePower.Text:ClearAllPoints()
		self.AlternativePower.Text:SetPoint("CENTER", self.AlternativePower, "CENTER", module.db.player.Texts.AlternativePower.X, module.db.player.Texts.AlternativePower.Y)

		self.AlternativePower.Text.Enable = module.db.player.Texts.AlternativePower.Enable
		self.AlternativePower.Text.Format = module.db.player.Texts.AlternativePower.Format
		self.AlternativePower.Text.color = module.db.player.Texts.AlternativePower.Color
		self.AlternativePower.Text.colorIndividual = module.db.player.Texts.AlternativePower.IndividualColor

		if module.db.player.Texts.AlternativePower.Enable then
			self.AlternativePower.Text:Show()
		else
			self.AlternativePower.Text:Hide()
		end

		self.AlternativePower.PostUpdate = PostUpdateAlternativePower

		self.AlternativePower.SetPosition()
	end,
	AdditionalPower = function(self, unit, oufdb)
		if not self.AdditionalPower then
			local AdditionalPower = CreateFrame("StatusBar", nil, self)

			local bg = AdditionalPower:CreateTexture(nil, "BACKGROUND")
			bg:SetAllPoints(AdditionalPower)
			
			self.AdditionalPower = AdditionalPower
			self.AdditionalPower.bg = bg

			self.AdditionalPower.Smooth = oufdb.Bars.AdditionalPower.Smooth

			self.AdditionalPower.value = SetFontString(self.AdditionalPower, Media:Fetch("font", oufdb.Texts.AdditionalPower.Font), oufdb.Texts.AdditionalPower.Size, oufdb.Texts.AdditionalPower.Outline)
			self:Tag(self.AdditionalPower.value, "[additionalpower2]")
			
			self.AdditionalPower.ShouldEnable = function(unit)
				local shouldEnable = false
				local _, playerClass = UnitClass(unit)
				if(not UnitHasVehicleUI('player')) then
					if(UnitPowerMax(unit, ADDITIONAL_POWER_BAR_INDEX) ~= 0) then
						if LUI.IsRetail and (ALT_MANA_BAR_PAIR_DISPLAY_INFO[playerClass]) then
							local powerType = UnitPowerType(unit)
							shouldEnable = ALT_MANA_BAR_PAIR_DISPLAY_INFO[playerClass][powerType]
						end
					end
				end
				return shouldEnable
			end
			
			self.AdditionalPower.SetPosition = function()
				if not oufdb.Bars.AdditionalPower.OverPower then return self.Power:SetHeight(oufdb.Bars.Power.Height) end

				if self.AdditionalPower:IsShown() then
					self.Power:SetHeight(oufdb.Bars.Power.Height/2 - 1)
					self.AdditionalPower:SetHeight(oufdb.Bars.AdditionalPower.Height/2 - 1)
				else
					self.Power:SetHeight(oufdb.Bars.Power.Height)
					self.AdditionalPower:SetHeight(oufdb.Bars.AdditionalPower.Height)
				end
			end

			self.AdditionalPower:SetScript("OnShow", self.AdditionalPower.SetPosition)
			self.AdditionalPower:SetScript("OnHide", self.AdditionalPower.SetPosition)

			self.AdditionalPower.PostUpdatePower = PostUpdateAdditionalPower
			self.AdditionalPower.Override = AdditionalPowerOverride
		end

		self.AdditionalPower:ClearAllPoints()
		if oufdb.Bars.AdditionalPower.OverPower then
			self.AdditionalPower:SetPoint("TOPLEFT", self.Power, "BOTTOMLEFT", 0, -2)
			self.AdditionalPower:SetPoint("TOPRIGHT", self.Power, "BOTTOMRIGHT", 0, -2)
		else
			self.Power:SetHeight(oufdb.Bars.Power.Height)
			self.AdditionalPower:SetPoint("TOPLEFT", self, "TOPLEFT", module.db.player.Bars.AdditionalPower.X, module.db.player.Bars.AdditionalPower.Y)
		end

		self.AdditionalPower:SetHeight(oufdb.Bars.AdditionalPower.Height)
		self.AdditionalPower:SetWidth(oufdb.Bars.AdditionalPower.Width)
		self.AdditionalPower:SetStatusBarTexture(Media:Fetch("statusbar", oufdb.Bars.AdditionalPower.Texture))

		self.AdditionalPower.value:SetFont(Media:Fetch("font", oufdb.Texts.AdditionalPower.Font), oufdb.Texts.AdditionalPower.Size, oufdb.Texts.AdditionalPower.Outline)
		self.AdditionalPower.value:SetPoint("CENTER", self.AdditionalPower, "CENTER")

		if oufdb.Texts.AdditionalPower.Enable == true then
			self.AdditionalPower.value:Show()
		else
			self.AdditionalPower.value:Hide()
		end

		self.AdditionalPower.color = oufdb.Bars.AdditionalPower.Color

		self.AdditionalPower.bg:SetTexture(Media:Fetch("statusbar", oufdb.Bars.AdditionalPower.TextureBG))
		self.AdditionalPower.bg:SetAlpha(oufdb.Bars.AdditionalPower.BGAlpha)
		self.AdditionalPower.bg.multiplier = oufdb.Bars.AdditionalPower.BGMultiplier

		if self.AdditionalPower.ShouldEnable(unit) then self.AdditionalPower.SetPosition() end
		if module.db.player.Bars.AdditionalPower.Enable then
			self.AdditionalPower:Show()
		else
			self.AdditionalPower:Hide()
		end
	end,

	-- raid specific
	SingleAuras = function(self, unit, oufdb)
		if not cornerAuras[LUI.playerClass] then return end
		if not self.SingleAuras then self.SingleAuras = {} end

		for k, data in pairs(cornerAuras[LUI.playerClass]) do
			local spellId, onlyPlayer, isDebuff = unpack(data)
			local spellName = GetSpellInfo(spellId)

			local x = k:find("RIGHT") and - oufdb.CornerAura.Inset or oufdb.CornerAura.Inset
			local y = k:find("TOP") and - oufdb.CornerAura.Inset or oufdb.CornerAura.Inset

			if not self.SingleAuras[k] then
				self.SingleAuras[k] = CreateFrame("Frame", nil, self)
				self.SingleAuras[k]:SetFrameLevel(7)
			end

			self.SingleAuras[k].spellName = spellName
			self.SingleAuras[k].onlyPlayer = onlyPlayer
			self.SingleAuras[k].isDebuff = isDebuff
			self.SingleAuras[k]:SetWidth(oufdb.CornerAura.Size)
			self.SingleAuras[k]:SetHeight(oufdb.CornerAura.Size)
			self.SingleAuras[k]:ClearAllPoints()
			self.SingleAuras[k]:SetPoint(k, self, k, x, y)
		end
	end,
	RaidDebuffs = function(self, unit, oufdb)
		if not self.RaidDebuffs then
			self.RaidDebuffs = CreateFrame("Frame", nil, self, "BackdropTemplate")
			self.RaidDebuffs:SetPoint("CENTER", self, "CENTER", 0, 0)
			self.RaidDebuffs:SetFrameLevel(7)

			self.RaidDebuffs:SetBackdrop({
				bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
				insets = {top = -1, left = -1, bottom = -1, right = -1},
			})

			self.RaidDebuffs.icon = self.RaidDebuffs:CreateTexture(nil, "OVERLAY")
			self.RaidDebuffs.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
			self.RaidDebuffs.icon:SetAllPoints(self.RaidDebuffs)

			self.RaidDebuffs.cd = CreateFrame("Cooldown", nil, self.RaidDebuffs)
			self.RaidDebuffs.cd:SetAllPoints(self.RaidDebuffs)
		end

		self.RaidDebuffs:SetHeight(oufdb.RaidDebuff.Size)
		self.RaidDebuffs:SetWidth(oufdb.RaidDebuff.Size)
	end,

	-- others
	Portrait = function(self, unit, oufdb)
		if not self.Portrait then
			self.Portrait = CreateFrame("PlayerModel", nil, self)
			self.Portrait:SetFrameLevel(5)
			--self.Portrait.Override = PortraitOverride
		end

		self.Portrait:SetHeight(oufdb.Portrait.Height)
		self.Portrait:SetWidth(oufdb.Portrait.Width * self:GetWidth() / oufdb.Width) -- needed for 25/40 man raid width downscaling!
		self.Portrait:SetAlpha(oufdb.Portrait.Alpha)
		self.Portrait:ClearAllPoints()
		self.Portrait:SetPoint("TOPLEFT", self, "TOPLEFT", oufdb.Portrait.X * self:GetWidth() / oufdb.Width, oufdb.Portrait.Y) -- needed for 25/40 man raid width downscaling!
	end,

	Buffs = function(self, unit, oufdb)
		if not self.Buffs then self.Buffs = CreateFrame("Frame", nil, self) end

		self.Buffs:SetHeight(oufdb.Aura.Buffs.Size)
		self.Buffs:SetWidth(oufdb.Width)
		self.Buffs.size = oufdb.Aura.Buffs.Size
		self.Buffs.spacing = oufdb.Aura.Buffs.Spacing
		self.Buffs.num = oufdb.Aura.Buffs.Num

		for i = 1, #self.Buffs do
			local button = self.Buffs[i]
			if button and button:IsShown() then
				button:SetWidth(oufdb.Aura.Buffs.Size)
				button:SetHeight(oufdb.Aura.Buffs.Size)
			elseif not button then
				break
			end
		end

		self.Buffs:ClearAllPoints()
		self.Buffs:SetPoint(oufdb.Aura.Buffs.InitialAnchor, self, oufdb.Aura.Buffs.InitialAnchor, oufdb.Aura.Buffs.X, oufdb.Aura.Buffs.Y)
		self.Buffs.initialAnchor = oufdb.Aura.Buffs.InitialAnchor
		self.Buffs["growth-y"] = oufdb.Aura.Buffs.GrowthY
		self.Buffs["growth-x"] = oufdb.Aura.Buffs.GrowthX
		self.Buffs.onlyShowPlayer = oufdb.Aura.Buffs.PlayerOnly
		self.Buffs.includePet = oufdb.Aura.Buffs.IncludePet
		self.Buffs.showStealableBuffs = (unit ~= "player" and (LUI.MAGE or LUI.SHAMAN))
		self.Buffs.showAuraType = oufdb.Aura.Buffs.ColorByType
		self.Buffs.showAuratimer = oufdb.Aura.Buffs.AuraTimer
		self.Buffs.disableCooldown = oufdb.Aura.Buffs.DisableCooldown
		self.Buffs.cooldownReverse = oufdb.Aura.Buffs.CooldownReverse

		self.Buffs.PostCreateIcon = PostCreateAura
		self.Buffs.PostUpdateIcon = PostUpdateAura
		self.Buffs.CustomFilter = CustomFilter
		if not self.Buffs.createdIcons then self.Buffs.createdIcons = 0 end
		if not self.Buffs.anchoredIcons then self.Buffs.anchoredIcons = 0 end
	end,
	Debuffs = function(self, unit, oufdb)
		if not self.Debuffs then self.Debuffs = CreateFrame("Frame", nil, self) end

		self.Debuffs:SetHeight(oufdb.Aura.Debuffs.Size)
		self.Debuffs:SetWidth(oufdb.Width)
		self.Debuffs.size = oufdb.Aura.Debuffs.Size
		self.Debuffs.spacing = oufdb.Aura.Debuffs.Spacing
		self.Debuffs.num = oufdb.Aura.Debuffs.Num

		for i = 1, #self.Debuffs do
			local button = self.Debuffs[i]
			if button and button:IsShown() then
				button:SetWidth(oufdb.Aura.Debuffs.Size)
				button:SetHeight(oufdb.Aura.Debuffs.Size)
			elseif not button then
				break
			end
		end

		self.Debuffs:ClearAllPoints()
		self.Debuffs:SetPoint(oufdb.Aura.Debuffs.InitialAnchor, self, oufdb.Aura.Debuffs.InitialAnchor, oufdb.Aura.Debuffs.X, oufdb.Aura.Debuffs.Y)
		self.Debuffs.initialAnchor = oufdb.Aura.Debuffs.InitialAnchor
		self.Debuffs["growth-y"] = oufdb.Aura.Debuffs.GrowthY
		self.Debuffs["growth-x"] = oufdb.Aura.Debuffs.GrowthX
		self.Debuffs.onlyShowPlayer = oufdb.Aura.Debuffs.PlayerOnly
		self.Debuffs.includePet = oufdb.Aura.Debuffs.IncludePet
		self.Debuffs.fadeOthers = oufdb.Aura.Debuffs.FadeOthers
		self.Debuffs.showStealableBuffs = (unit ~= "player" and (LUI.MAGE or LUI.SHAMAN))
		self.Debuffs.showAuraType = oufdb.Aura.Debuffs.ColorByType
		self.Debuffs.showAuratimer = oufdb.Aura.Debuffs.AuraTimer
		self.Debuffs.disableCooldown = oufdb.Aura.Debuffs.DisableCooldown
		self.Debuffs.cooldownReverse = oufdb.Aura.Debuffs.CooldownReverse

		self.Debuffs.PostCreateIcon = PostCreateAura
		self.Debuffs.PostUpdateIcon = PostUpdateAura
		self.Debuffs.CustomFilter = CustomFilter
		if not self.Debuffs.createdIcons then self.Debuffs.createdIcons = 0 end
		if not self.Debuffs.anchoredIcons then self.Debuffs.anchoredIcons = 0 end
	end,

	CombatFeedbackText = function(self, unit, oufdb)
		if not self.CombatFeedbackText then
			self.CombatFeedbackText = SetFontString(self.Health, Media:Fetch("font", oufdb.Texts.Combat.Font), oufdb.Texts.Combat.Size, oufdb.Texts.Combat.Outline)
		else
			self.CombatFeedbackText:SetFont(Media:Fetch("font", oufdb.Texts.Combat.Font), oufdb.Texts.Combat.Size, oufdb.Texts.Combat.Outline)
		end
		self.CombatFeedbackText:ClearAllPoints()
		self.CombatFeedbackText:SetPoint(oufdb.Texts.Combat.Point, self, oufdb.Texts.Combat.RelativePoint, oufdb.Texts.Combat.X, oufdb.Texts.Combat.Y)
		self.CombatFeedbackText.colors = module.colors.combattext

		if oufdb.Texts.Combat.Enable == true then
			self.CombatFeedbackText.ignoreImmune = not oufdb.Texts.Combat.ShowImmune
			self.CombatFeedbackText.ignoreDamage = not oufdb.Texts.Combat.ShowDamage
			self.CombatFeedbackText.ignoreHeal = not oufdb.Texts.Combat.ShowHeal
			self.CombatFeedbackText.ignoreEnergize = not oufdb.Texts.Combat.ShowEnergize
			self.CombatFeedbackText.ignoreOther = not oufdb.Texts.Combat.ShowOther
		else
			self.CombatFeedbackText.ignoreImmune = true
			self.CombatFeedbackText.ignoreDamage = true
			self.CombatFeedbackText.ignoreHeal = true
			self.CombatFeedbackText.ignoreEnergize = true
			self.CombatFeedbackText.ignoreOther = true
			self.CombatFeedbackText:Hide()
		end
	end,

	Castbar = function(self, unit, oufdb)
		local castbar = self.Castbar
		if not castbar then
			self.Castbar = CreateFrame("StatusBar", self:GetName().."_Castbar", self)
			castbar = self.Castbar
			castbar:SetFrameLevel(6)

			castbar.bg = castbar:CreateTexture(nil, "BORDER")
			castbar.bg:SetAllPoints(castbar)

			castbar.Backdrop = CreateFrame("Frame", nil, self, "BackdropTemplate")
			castbar.Backdrop:SetPoint("TOPLEFT", castbar, "TOPLEFT", -4, 3)
			castbar.Backdrop:SetPoint("BOTTOMRIGHT", castbar, "BOTTOMRIGHT", 3, -3.5)
			castbar.Backdrop:SetParent(castbar)

			castbar.Time = SetFontString(castbar, Media:Fetch("font", oufdb.Castbar.Text.Time.Font), oufdb.Castbar.Text.Time.Size)
			castbar.Time:SetJustifyH("RIGHT")
			castbar.CustomTimeText = FormatCastbarTime
			castbar.CustomDelayText = FormatCastbarTime

			castbar.Text = SetFontString(castbar, Media:Fetch("font", oufdb.Castbar.Text.Name.Font), oufdb.Castbar.Text.Name.Size)

			castbar.PostCastStart = PostCastStart
			castbar.PostChannelStart = PostCastStart

			if unit == "player" then
				castbar.SafeZone = castbar:CreateTexture(nil, "ARTWORK")
				castbar.SafeZone:SetTexture(normTex)

				if channelingTicks then -- make sure player is a class that has a channeled spell
					local ticks = {}
					local function updateTick(self)
						local ticktime = self.ticktime - self.delay
						if ticktime > 0 and ticktime < castbar.max then
							self:SetPoint("CENTER", castbar, "LEFT", ticktime / castbar.max * castbar:GetWidth(), 0)
							self:Show()
						else
							self:Hide()
							self.ticktime = 0
							self.delay = 0
						end
					end

					castbar.GetTick = function(self, i)
						local tick = ticks[i]
						if not tick then
							tick = self:CreateTexture(nil, "OVERLAY")
							ticks[i] = tick
							tick:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
							tick:SetVertexColor(1, 1, 1, 0.8)
							tick:SetBlendMode("ADD")
							tick:SetWidth(15)
							tick.Update = updateTick
						end
						tick:SetHeight(self:GetHeight() * 1.8)
						return tick
					end
					castbar.HideTicks = function(self)
						for i, tick in ipairs(ticks) do
							tick:Hide()
							tick.ticktime = 0
							tick.delay = 0
						end
					end

					castbar.PostChannelStart = PostChannelStart
					castbar.PostChannelUpdate = PostChannelUpdate
					castbar.PostChannelStop = castbar.HideTicks
				end
			end

			castbar.Icon = castbar:CreateTexture(nil, "ARTWORK")
			castbar.Icon:SetTexCoord(0, 1, 0, 1)
			if unit == "player" or unit == "target" or unit == "focus" or unit == "pet" then
				castbar.Icon:SetHeight(28.5)
				castbar.Icon:SetWidth(28.5)
				castbar.Icon:SetPoint("LEFT", -41.5, 0)
			else
				castbar.Icon = castbar:CreateTexture(nil, "ARTWORK")
				castbar.Icon:SetHeight(20)
				castbar.Icon:SetWidth(20)
				if unit == unit:match("arena%d") then
					castbar.Icon:SetPoint("RIGHT", 30, 0)
				else
					castbar.Icon:SetPoint("LEFT", -30, 0)
				end
			end

			castbar.IconOverlay = castbar:CreateTexture(nil, "OVERLAY")
			castbar.IconOverlay:SetPoint("TOPLEFT", castbar.Icon, "TOPLEFT", -1.5, 1)
			castbar.IconOverlay:SetPoint("BOTTOMRIGHT", castbar.Icon, "BOTTOMRIGHT", 1, -1)
			castbar.IconOverlay:SetTexture(buttonTex)
			castbar.IconOverlay:SetVertexColor(1, 1, 1)

			castbar.IconBackdrop = CreateFrame("Frame", nil, castbar, "BackdropTemplate")
			castbar.IconBackdrop:SetPoint("TOPLEFT", castbar.Icon, "TOPLEFT", -4, 3)
			castbar.IconBackdrop:SetPoint("BOTTOMRIGHT", castbar.Icon, "BOTTOMRIGHT", 3, -3.5)
			castbar.IconBackdrop:SetBackdrop({
				edgeFile = glowTex, edgeSize = 4,
				insets = {left = 3, right = 3, top = 3, bottom = 3}
			})
			castbar.IconBackdrop:SetBackdropColor(0, 0, 0, 0)
			castbar.IconBackdrop:SetBackdropBorderColor(0, 0, 0, 0.7)
		end

		castbar:SetStatusBarTexture(Media:Fetch("statusbar", oufdb.Castbar.General.Texture))
		castbar:SetHeight(oufdb.Castbar.General.Height)
		castbar:SetWidth(oufdb.Castbar.General.Width)
		castbar:ClearAllPoints()
		if unit == "player" or unit == "target" then
			castbar:SetPoint(oufdb.Castbar.General.Point, UIParent, oufdb.Castbar.General.Point, oufdb.Castbar.General.X, oufdb.Castbar.General.Y)
		elseif unit == "focus" or unit == "pet" then
			castbar:SetPoint("TOP", self, "BOTTOM", oufdb.Castbar.General.X, oufdb.Castbar.General.Y)
		elseif unit == unit:match("arena%d") then
			castbar:SetPoint("RIGHT", self, "LEFT", oufdb.Castbar.General.X, oufdb.Castbar.General.Y)
		else
			castbar:SetPoint("LEFT", self, "RIGHT", oufdb.Castbar.General.X, oufdb.Castbar.General.Y)
		end

		castbar.bg:SetTexture(Media:Fetch("statusbar", oufdb.Castbar.General.TextureBG))

		castbar.Backdrop:SetBackdrop({
			edgeFile = Media:Fetch("border", oufdb.Castbar.Border.Texture),
			edgeSize = oufdb.Castbar.Border.Thickness,
			insets = {
				left = oufdb.Castbar.Border.Inset.left,
				right = oufdb.Castbar.Border.Inset.right,
				top = oufdb.Castbar.Border.Inset.top,
				bottom = oufdb.Castbar.Border.Inset.bottom
			}
		})
		castbar.Backdrop:SetBackdropColor(0, 0, 0, 0)

		castbar.Colors = {
			Individual = oufdb.Castbar.General.IndividualColor,
			Bar = oufdb.Castbar.Colors.Bar,
			Background = oufdb.Castbar.Colors.Background,
			Border = oufdb.Castbar.Colors.Border,
		}
		castbar.Shielded = {
			Enable = oufdb.Castbar.General.Shield,
			IndividualColor = oufdb.Castbar.Shield.IndividualColor,
			BarColor = oufdb.Castbar.Shield.BarColor,
			IndividualBorder = oufdb.Castbar.Shield.IndividualBorder,
			--Text = oufdb.Castbar.Shield.Text,
			Color = oufdb.Castbar.Shield.Color,
			Texture = oufdb.Castbar.Shield.Texture,
			Thick = oufdb.Castbar.Shield.Thickness,
			Inset = {
				L = oufdb.Castbar.Shield.Inset.left,
				R = oufdb.Castbar.Shield.Inset.right,
				T = oufdb.Castbar.Shield.Inset.top,
				B = oufdb.Castbar.Shield.Inset.bottom,
			},
		}
		castbar.Time:SetFont(Media:Fetch("font", oufdb.Castbar.Text.Time.Font), oufdb.Castbar.Text.Time.Size)
		castbar.Time:ClearAllPoints()
		castbar.Time:SetPoint("RIGHT", castbar, "RIGHT", oufdb.Castbar.Text.Time.OffsetX, oufdb.Castbar.Text.Time.OffsetY)
		castbar.Time:SetTextColor(oufdb.Castbar.Colors.Time.r, oufdb.Castbar.Colors.Time.g, oufdb.Castbar.Colors.Time.b)
		castbar.Time.ShowMax = oufdb.Castbar.Text.Time.ShowMax

		if oufdb.Castbar.Text.Time.Enable == true then
			castbar.Time:Show()
		else
			castbar.Time:Hide()
		end

		castbar.Text:SetFont(Media:Fetch("font", oufdb.Castbar.Text.Name.Font), oufdb.Castbar.Text.Name.Size)
		castbar.Text:ClearAllPoints()
		castbar.Text:SetPoint("LEFT", castbar, "LEFT", oufdb.Castbar.Text.Name.OffsetX, oufdb.Castbar.Text.Name.OffsetY)
		castbar.Text:SetTextColor(oufdb.Castbar.Colors.Name.r, oufdb.Castbar.Colors.Name.r, oufdb.Castbar.Colors.Name.r)

		if oufdb.Castbar.Text.Name.Enable == true then
			castbar.Text:Show()
		else
			castbar.Text:Hide()
		end

		if unit == "player" then
			if oufdb.Castbar.General.Latency == true then
				castbar.SafeZone:Show()
				if oufdb.Castbar.General.IndividualColor == true then
					castbar.SafeZone:SetVertexColor(oufdb.Castbar.Colors.Latency.r,oufdb.Castbar.Colors.Latency.g,oufdb.Castbar.Colors.Latency.b,oufdb.Castbar.Colors.Latency.a)
				else
					castbar.SafeZone:SetVertexColor(0.11,0.11,0.11,0.6)
				end
			else
				castbar.SafeZone:Hide()
			end
		end

		if oufdb.Castbar.General.Icon then
			castbar.Icon:Show()
			castbar.IconOverlay:Show()
			castbar.IconBackdrop:Show()
		else
			castbar.Icon:Hide()
			castbar.IconOverlay:Hide()
			castbar.IconBackdrop:Hide()
		end
	end,

	AggroGlow = function(self, unit, oufdb)
		if self.ThreatIndicator then return end

		self.ThreatIndicator = CreateFrame("Frame", nil, self)
		self.ThreatIndicator:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
		self.ThreatIndicator:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
		self.ThreatIndicator:SetFrameLevel(self.Health:GetFrameLevel() - 1)

		for i = 1, 8 do
			self.ThreatIndicator[i] = self.ThreatIndicator:CreateTexture(nil, "BACKGROUND")
			self.ThreatIndicator[i]:SetTexture(aggroTex)
			self.ThreatIndicator[i]:SetWidth(20)
			self.ThreatIndicator[i]:SetHeight(20)
		end

		-- topleft corner
		self.ThreatIndicator[1]:SetTexCoord(0, 1/3, 0, 1/3)
		self.ThreatIndicator[1]:SetPoint("TOPLEFT", self.ThreatIndicator, -8, 8)

		-- topright corner
		self.ThreatIndicator[2]:SetTexCoord(2/3, 1, 0, 1/3)
		self.ThreatIndicator[2]:SetPoint("TOPRIGHT", self.ThreatIndicator, 8, 8)

		-- bottomleft corner
		self.ThreatIndicator[3]:SetTexCoord(0, 1/3, 2/3, 1)
		self.ThreatIndicator[3]:SetPoint("BOTTOMLEFT", self.ThreatIndicator, -8, -8)

		-- bottomright corner
		self.ThreatIndicator[4]:SetTexCoord(2/3, 1, 2/3, 1)
		self.ThreatIndicator[4]:SetPoint("BOTTOMRIGHT", self.ThreatIndicator, 8, -8)

		-- top edge
		self.ThreatIndicator[5]:SetTexCoord(1/3, 2/3, 0, 1/3)
		self.ThreatIndicator[5]:SetPoint("TOPLEFT", self.ThreatIndicator[1], "TOPRIGHT")
		self.ThreatIndicator[5]:SetPoint("TOPRIGHT", self.ThreatIndicator[2], "TOPLEFT")

		-- bottom edge
		self.ThreatIndicator[6]:SetTexCoord(1/3, 2/3, 2/3, 1)
		self.ThreatIndicator[6]:SetPoint("BOTTOMLEFT", self.ThreatIndicator[3], "BOTTOMRIGHT")
		self.ThreatIndicator[6]:SetPoint("BOTTOMRIGHT", self.ThreatIndicator[4], "BOTTOMLEFT")

		-- left edge
		self.ThreatIndicator[7]:SetTexCoord(0, 1/3, 1/3, 2/3)
		self.ThreatIndicator[7]:SetPoint("TOPLEFT", self.ThreatIndicator[1], "BOTTOMLEFT")
		self.ThreatIndicator[7]:SetPoint("BOTTOMLEFT", self.ThreatIndicator[3], "TOPLEFT")

		-- right edge
		self.ThreatIndicator[8]:SetTexCoord(2/3, 1, 1/3, 2/3)
		self.ThreatIndicator[8]:SetPoint("TOPRIGHT", self.ThreatIndicator[2], "BOTTOMRIGHT")
		self.ThreatIndicator[8]:SetPoint("BOTTOMRIGHT", self.ThreatIndicator[4], "TOPRIGHT")

		self.ThreatIndicator.Override = ThreatOverride
	end,

	HealthPrediction = function(self, unit, oufdb)
		if not self.HealthPrediction then
			self.HealthPrediction = {
				myBar = CreateFrame("StatusBar", nil, self.Health),
				otherBar = CreateFrame("StatusBar", nil, self.Health),
				maxOverflow = 1,
			}
		end

		self.HealthPrediction.myBar:SetWidth(oufdb.Bars.Health.Width * self:GetWidth() / oufdb.Width) -- needed for 25/40 man raid width downscaling!
		self.HealthPrediction.myBar:SetStatusBarTexture(Media:Fetch("statusbar", oufdb.Bars.HealthPrediction.Texture))
		self.HealthPrediction.myBar:SetStatusBarColor(oufdb.Bars.HealthPrediction.MyColor.r, oufdb.Bars.HealthPrediction.MyColor.g, oufdb.Bars.HealthPrediction.MyColor.b, oufdb.Bars.HealthPrediction.MyColor.a)

		self.HealthPrediction.otherBar:SetWidth(oufdb.Bars.Health.Width * self:GetWidth() / oufdb.Width) -- needed for 25/40 man raid width downscaling!
		self.HealthPrediction.otherBar:SetStatusBarTexture(Media:Fetch("statusbar", oufdb.Bars.HealthPrediction.Texture))
		self.HealthPrediction.otherBar:SetStatusBarColor(oufdb.Bars.HealthPrediction.OtherColor.r, oufdb.Bars.HealthPrediction.OtherColor.g, oufdb.Bars.HealthPrediction.OtherColor.b, oufdb.Bars.HealthPrediction.OtherColor.a)

		self.HealthPrediction.myBar:ClearAllPoints()
		self.HealthPrediction.myBar:SetPoint("TOPLEFT", self.Health:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
		self.HealthPrediction.myBar:SetPoint("BOTTOMLEFT", self.Health:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)

		self.HealthPrediction.otherBar:SetPoint("TOPLEFT", self.HealthPrediction.myBar:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
		self.HealthPrediction.otherBar:SetPoint("BOTTOMLEFT", self.HealthPrediction.myBar:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
	end,

	TotalAbsorb = function(self, unit, oufdb)
		if not self.TotalAbsorb then
			self.TotalAbsorb = CreateFrame('StatusBar', nil, self.Health)
		end

		self.TotalAbsorb.maxOverflow = 1
		
		self.TotalAbsorb:SetWidth(oufdb.Bars.Health.Width * self:GetWidth() / oufdb.Width) -- needed for 25/40 man raid width downscaling!
		self.TotalAbsorb:SetStatusBarTexture(Media:Fetch("statusbar", oufdb.Bars.TotalAbsorb.Texture))
		self.TotalAbsorb:SetStatusBarColor(oufdb.Bars.TotalAbsorb.MyColor.r, oufdb.Bars.TotalAbsorb.MyColor.g, oufdb.Bars.TotalAbsorb.MyColor.b, oufdb.Bars.TotalAbsorb.MyColor.a)

		self.TotalAbsorb:ClearAllPoints()
		self.TotalAbsorb:SetPoint("TOPLEFT", self.Health:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
		self.TotalAbsorb:SetPoint("BOTTOMLEFT", self.Health:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)

		--self.TotalAbsorb.Override = TotalAbsorbOverride
	end,
	
	V2Textures = function(from, to)
		if not from.V2Tex then
			local V2Tex = CreateFrame("Frame", nil, from)

			V2Tex.Horizontal = CreateFrame("Frame", nil, V2Tex, "BackdropTemplate")
			V2Tex.Horizontal:SetFrameLevel(19)
			V2Tex.Horizontal:SetFrameStrata("BACKGROUND")
			V2Tex.Horizontal:SetHeight(2)
			V2Tex.Horizontal:SetBackdrop(backdrop2)
			V2Tex.Horizontal:SetBackdropColor(0, 0, 0, 1)
			V2Tex.Horizontal:SetBackdropBorderColor(0.1, 0.1, 0.1, 1)
			V2Tex.Horizontal:Show()

			V2Tex.Vertical = CreateFrame("Frame", nil, V2Tex, "BackdropTemplate")
			V2Tex.Vertical:SetFrameLevel(19)
			V2Tex.Vertical:SetFrameStrata("BACKGROUND")
			V2Tex.Vertical:SetWidth(2)
			V2Tex.Vertical:SetBackdrop(backdrop2)
			V2Tex.Vertical:SetBackdropColor(0, 0, 0, 1)
			V2Tex.Vertical:SetBackdropBorderColor(0.1, 0.1, 0.1, 1)
			V2Tex.Vertical:Show()

			V2Tex.Horizontal2 = CreateFrame("Frame", nil, V2Tex, "BackdropTemplate")
			V2Tex.Horizontal2:SetFrameLevel(19)
			V2Tex.Horizontal2:SetFrameStrata("BACKGROUND")
			V2Tex.Horizontal2:SetHeight(2)
			V2Tex.Horizontal2:SetBackdrop(backdrop2)
			V2Tex.Horizontal2:SetBackdropColor(0, 0, 0, 1)
			V2Tex.Horizontal2:SetBackdropBorderColor(0.1, 0.1, 0.1, 1)
			V2Tex.Horizontal2:Show()

			V2Tex.Dot = CreateFrame("Frame", nil, V2Tex, "BackdropTemplate")
			V2Tex.Dot:SetFrameLevel(19)
			V2Tex.Dot:SetFrameStrata("BACKGROUND")
			V2Tex.Dot:SetHeight(6)
			V2Tex.Dot:SetWidth(6)
			V2Tex.Dot:SetBackdrop(backdrop2)
			V2Tex.Dot:SetBackdropColor(0, 0, 0, 1)
			V2Tex.Dot:SetBackdropBorderColor(0.1, 0.1, 0.1, 1)
			V2Tex.Dot:Show()

			-- needed for the options
			from.V2Tex = V2Tex
			to._V2Tex = V2Tex

			V2Tex.from = from
			V2Tex.to = to

			V2Tex.Reposition = Reposition

			module:SecureHook(from, "Show", function() V2Tex:Reposition() end)
		end

		from.V2Tex:Reposition()
	end,
}

------------------------------------------------------------------------
--	Style Func
------------------------------------------------------------------------

local SetStyle = function(self, unit, isSingle)
	local oufdb

	if unit == "vehicle" then
		oufdb = module.db.player
	elseif unit == unit:match("arena%d") then
		oufdb = module.db.arena
	elseif unit == unit:match("arena%dtarget") then
		oufdb = module.db.arenatarget
	elseif unit == unit:match("arena%dpet") then
		oufdb = module.db.arenapet

	elseif unit == unit:match("boss%d") then
		oufdb = module.db.boss
	elseif unit == unit:match("boss%dtarget") then
		oufdb = module.db.bosstarget
	
	else
		oufdb = module.db[unit]
	end


	self.colors = module.colors
	self:RegisterForClicks("AnyUp")

	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	self.MoveableFrames = ((isSingle and not unit:match("%d")) or unit == "party" or unit == "maintank" or unit == unit:match("%a+1"))

	self.SpellRange = true
	self.BarFade = false

	if isSingle then
		self:SetHeight(oufdb.Height)
		self:SetWidth(oufdb.Width)
	end

	------------------------------------------------------------------------
	--	Bars
	------------------------------------------------------------------------

	module.funcs.Health(self, unit, oufdb)
	module.funcs.Power(self, unit, oufdb)
	module.funcs.FrameBackdrop(self, unit, oufdb)

	if oufdb.Bars.HealthPrediction and oufdb.Bars.HealthPrediction.Enable then module.funcs.HealthPrediction(self, unit, oufdb) end
	if oufdb.Bars.TotalAbsorb and oufdb.Bars.TotalAbsorb.Enable then module.funcs.TotalAbsorb(self, unit, oufdb) end

	------------------------------------------------------------------------
	--	Texts
	------------------------------------------------------------------------

	-- creating a frame as anchor for icons, texts etc
	self.Overlay = CreateFrame("Frame", nil, self)
	self.Overlay:SetFrameLevel(8)
	self.Overlay:SetAllPoints(self.Health)

	if unit ~= "raid" then
		module.funcs.Info(self, unit, oufdb)
	else
		module.funcs.RaidInfo(self, unit, oufdb)
	end

	if unit == "party" then
		local sanityBar = _G[format("PartyMemberFrame%dPowerBarAlt", string.sub(self:GetName(), -1))]
		if sanityBar then
			sanityBar:ClearAllPoints()
			sanityBar:SetPoint("LEFT", self, "RIGHT", 25, 0)
			sanityBar:SetParent(self)
		end
	end

	module.funcs.HealthValue(self, unit, oufdb)
	module.funcs.HealthPercent(self, unit, oufdb)
	module.funcs.HealthMissing(self, unit, oufdb)

	module.funcs.PowerValue(self, unit, oufdb)
	module.funcs.PowerPercent(self, unit, oufdb)
	module.funcs.PowerMissing(self, unit, oufdb)

	------------------------------------------------------------------------
	--	Indicators
	------------------------------------------------------------------------

	if oufdb.Indicators then
		if oufdb.Indicators.Leader and oufdb.Indicators.Leader.Enable then module.funcs.LeaderIndicator(self, unit, oufdb) end
		if oufdb.Indicators.Raid and oufdb.Indicators.Raid.Enable then module.funcs.RaidTargetIndicator(self, unit, oufdb) end
		if oufdb.Indicators.Role and oufdb.Indicators.Role.Enable then module.funcs.GroupRoleIndicator(self, unit, oufdb) end
		if oufdb.Indicators.PvP and oufdb.Indicators.PvP.Enable then module.funcs.PvPIndicator(self, unit, oufdb) end
		if oufdb.Indicators.Resting and oufdb.Indicators.Resting.Enable then module.funcs.RestingIndicator(self, unit, oufdb) end
		if oufdb.Indicators.Combat and oufdb.Indicators.Combat.Enable then module.funcs.CombatIndicator(self, unit, oufdb) end
		if oufdb.Indicators.ReadyCheck and oufdb.Indicators.ReadyCheck.Enable then module.funcs.ReadyCheckIndicator(self, unit, oufdb) end
	end

	------------------------------------------------------------------------
	--	Player Specific Items
	------------------------------------------------------------------------

	if unit == "player" then
		
		if LUI.DEATHKNIGHT then
			if oufdb.Bars.Runes.Enable then
				module.funcs.Runes(self, unit, oufdb)
				Blizzard:Hide("runebar")
			end
		elseif LUI.DRUID then
			if oufdb.Bars.AdditionalPower.Enable then module.funcs.AdditionalPower(self, unit, oufdb) end
			if oufdb.Bars.ClassPower.Enable then module.funcs.ClassPower(self, unit, oufdb) end
		elseif LUI.PALADIN or LUI.MONK or LUI.ROGUE or LUI.WARLOCK then
			if oufdb.Bars.ClassPower.Enable then module.funcs.ClassPower(self, unit, oufdb) end
		elseif LUI.SHAMAN then
			if oufdb.Bars.AdditionalPower.Enable then module.funcs.AdditionalPower(self, unit, oufdb) end
			if oufdb.Bars.Totems.Enable then module.funcs.Totems(self, unit, oufdb) end
		elseif LUI.MAGE then
			--if oufdb.Bars.ClassPower.Enable then module.funcs.ClassPower(self, unit, oufdb) end
		elseif LUI.PRIEST then
			if oufdb.Bars.AdditionalPower.Enable then module.funcs.AdditionalPower(self, unit, oufdb) end
		end
	end
	
	------------------------------------------------------------------------
	--	Raid Specific Items
	------------------------------------------------------------------------

	if unit == "raid" then
		if oufdb.CornerAura.Enable then module.funcs.SingleAuras(self, unit, oufdb) end
		if oufdb.RaidDebuff.Enable then module.funcs.RaidDebuffs(self, unit, oufdb) end
	end
	
	------------------------------------------------------------------------
	--	Other
	------------------------------------------------------------------------
	
	if oufdb.Portrait.Enable then module.funcs.Portrait(self, unit, oufdb) end

	if unit == "player" or unit == "pet" then
		if module.db.player.Bars.AlternativePower.Enable then module.funcs.AlternativePower(self, unit, oufdb) end
	end

	if oufdb.Aura then
		if oufdb.Aura.Buffs.Enable then module.funcs.Buffs(self, unit, oufdb) end
		if oufdb.Aura.Debuffs.Enable then module.funcs.Debuffs(self, unit, oufdb) end
	end

	if oufdb.Texts.Combat then module.funcs.CombatFeedbackText(self, unit, oufdb) end
	if module.db.Settings.Castbars and oufdb.Castbar and oufdb.Castbar.General.Enable then
		module.funcs.Castbar(self, unit, oufdb)
		if unit == "player" then
			Blizzard:Hide("castbar")
		end
	end
	if oufdb.Border.Aggro then module.funcs.AggroGlow(self, unit, oufdb) end

	if unit == "targettarget" and module.db.Settings.ShowV2Textures then
		module.funcs.V2Textures(self, oUF_LUI_target)
	elseif unit == "targettargettarget" and module.db.Settings.ShowV2Textures then
		module.funcs.V2Textures(self, oUF_LUI_targettarget)
	elseif unit == "focustarget" and module.db.Settings.ShowV2Textures then
		module.funcs.V2Textures(self, oUF_LUI_focus)
	elseif unit == "focus" and module.db.Settings.ShowV2Textures then
		module.funcs.V2Textures(self, oUF_LUI_player)
	elseif (unit == unit:match("arena%dtarget") and module.db.Settings.ShowV2ArenaTextures) or (unit == unit:match("boss%dtarget") and module.db.Settings.ShowV2BossTextures) then
		module.funcs.V2Textures(self, _G["oUF_LUI_"..unit:match("%a+%d")])
	elseif unit == "partytarget" and module.db.Settings.ShowV2PartyTextures then
		module.funcs.V2Textures(self, self:GetParent())
	end

	self.Highlight = self.Health:CreateTexture(nil, "OVERLAY")
	self.Highlight:SetAllPoints(self)
	self.Highlight:SetTexture(highlightTex)
	self.Highlight:SetVertexColor(1,1,1,.1)
	self.Highlight:SetBlendMode("ADD")
	self.Highlight:Hide()

	--if unit == unit:match("arena%d") then
	--self.Hide_ = self.Hide
	--self:RegisterEvent("ARENA_OPPONENT_UPDATE", ArenaEnemyUnseen)
	--end

	self:RegisterEvent("PLAYER_FLAGS_CHANGED", function(self) self.Health:ForceUpdate() end)
	if unit == "player" then self:RegisterEvent("PLAYER_ENTERING_WORLD", function(self) self.Health:ForceUpdate() end) end
	if unit == "pet" then
		self.elapsed = 0
		self:SetScript("OnUpdate", function(self, elapsed)
			if self.elapsed > 2.5 then
				self:UpdateAllElements('refreshUnit')
				self.elapsed = 0
			else
				self.elapsed = self.elapsed + elapsed
			end
		end)
	end

	if oufdb.Fader and oufdb.Fader.Enable then Fader:RegisterFrame(self, oUF.Fader) end

	if unit == "raid" or (unit == "party" and oufdb.RangeFade and oufdb.Fader and not oufdb.Fader.Enable) then
		self.Range = {
			insideAlpha = 1,
			outsideAlpha = 0.5
		}
	end
	self.Health.Override = OverrideHealth
	self.Power.Override = OverridePower

	self.__unit = unit

	if oufdb.Enable == false then self:Disable() end

	return self
end

oUF:RegisterStyle("LUI", SetStyle)
