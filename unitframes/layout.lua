------------------------------------------------------------------------
--	oUF LUI Layout
--	Version 3.5.2
-- 	Date: 06/06/2011
--	DO NOT USE THIS LAYOUT WITHOUT LUI
------------------------------------------------------------------------

local _, ns = ...
local oUF = ns.oUF or oUF

local LSM = LibStub("LibSharedMedia-3.0")
local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local module = LUI:NewModule("oUF_Layout")

local db, colors, funcs

LUI_versions.ouf = 3520

local nameCache = {}

------------------------------------------------------------------------
--	Textures and Medias
------------------------------------------------------------------------

local mediaPath = [=[Interface\Addons\LUI\media\]=]

local floor = math.floor
local format = string.format

local normTex = mediaPath..[=[textures\statusbars\normTex]=]
local glowTex = mediaPath..[=[textures\statusbars\glowTex]=]
local highlightTex = mediaPath..[=[textures\statusbars\highlightTex]=]
local blankTex = mediaPath..[=[textures\statusbars\blank]=]

local aggroTex = mediaPath..[=[textures\aggro]=]
local buttonTex = mediaPath..[=[textures\buttonTex]=]

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

local _, class = UnitClass("player")
local standings = {"Hated", "Hostile", "Unfriendly", "Neutral", "Friendly", "Honored", "Revered", "Exalted"}
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
		BOTTOMRIGHT = {6788, false, true}, -- Weakened Soul
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

------------------------------------------------------------------------
--	Dont edit this if you dont know what you are doing!
------------------------------------------------------------------------

local GetDisplayPower = function(power, unit)
	local barType = UnitAlternatePowerInfo(unit)
	if power.displayAltPower and barType then
		return ALTERNATE_POWER_INDEX
	else
		return (UnitPowerType(unit))
	end
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
	UnitFrame_OnEnter(self)
	self.Highlight:Show()
end

local UnitFrame_OnLeave = function(self)
	UnitFrame_OnLeave(self)
	self.Highlight:Hide()
end

local menu = function(self)
	local unit = self.unit:gsub("(.)", string.upper, 1)
	if _G[unit.."FrameDropDown"] then
		ToggleDropDownMenu(1, nil, _G[unit.."FrameDropDown"], "cursor")
	elseif (self.unit:match("party")) then
		ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor")
	else
		FriendsDropDown.unit = self.unit
		FriendsDropDown.id = self.id
		FriendsDropDown.initialize = RaidFrameDropDown_Initialize
		ToggleDropDownMenu(1, nil, FriendsDropDown, "cursor")
	end
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
	local color = colors.class[pToken] or {0.5, 0.5, 0.5}

	if unit == "player" and entering == true then
		if db.oUF.Player.Health.Color == "By Class" then
			health:SetStatusBarColor(unpack(color))
		elseif db.oUF.Player.Health.Color == "Individual" then
			health:SetStatusBarColor(db.oUF.Player.Health.IndividualColor.r, db.oUF.Player.Health.IndividualColor.g, db.oUF.Player.Health.IndividualColor.b)
		else
			health:SetStatusBarColor(oUF.ColorGradient(min/max, unpack(colors.smooth)))
		end
	else
		if health.color == "By Class" then
			health:SetStatusBarColor(unpack(color))
		elseif health.color == "Individual" then
			health:SetStatusBarColor(health.colorIndividual.r, health.colorIndividual.g, health.colorIndividual.b)
		else
			health:SetStatusBarColor(oUF.ColorGradient(min/max, unpack(colors.smooth)))
		end
	end

	if health.colorTapping and UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) then health:SetStatusBarColor(unpack(colors.tapped)) end

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
		health.valueMissing:SetText()
	elseif UnitIsGhost(unit) then
		health:SetValue(0)
		health.value:SetText(health.value.ShowDead and "|cffD7BEA5<Ghost>|r" or "")
		health.valuePercent:SetText(health.valuePercent.ShowDead and "|cffD7BEA5<Ghost>|r" or "")
		health.valueMissing:SetText()
	elseif UnitIsDead(unit) then
		health:SetValue(0)
		health.value:SetText(health.value.ShowDead and "|cffD7BEA5<Dead>|r" or "")
		health.valuePercent:SetText(health.valuePercent.ShowDead and "|cffD7BEA5<Dead>|r" or "")
		health.valueMissing:SetText()
	else
		local healthPercent = string.format("%.1f", 100 * min / max).."%"

		if health.value.Enable == true then
			if min >= 1 then
				if health.value.ShowAlways == false and min == max then
					health.value:SetText()
				elseif health.value.Format == "Absolut" then
					health.value:SetFormattedText("%s/%s", min, max)
				elseif health.value.Format == "Absolut & Percent" then
					health.value:SetFormattedText("%s/%s | %s", min, max, healthPercent)
				elseif health.value.Format == "Absolut Short" then
					health.value:SetFormattedText("%s/%s", ShortValue(min), ShortValue(max))
				elseif health.value.Format == "Absolut Short & Percent" then
					health.value:SetFormattedText("%s/%s | %s", ShortValue(min),ShortValue(max), healthPercent)
				elseif health.value.Format == "Standard" then
					health.value:SetFormattedText("%s", min)
				elseif health.value.Format == "Standard Short" then
					health.value:SetFormattedText("%s", ShortValue(min))
				else
					health.value:SetFormattedText("%s", min)
				end

				if health.value.color == "By Class" then
					health.value:SetTextColor(unpack(color))
				elseif health.value.color == "Individual" then
					health.value:SetTextColor(health.value.colorIndividual.r, health.value.colorIndividual.g, health.value.colorIndividual.b)
				else
					health.value:SetTextColor(oUF.ColorGradient(min/max, unpack(colors.smooth)))
				end
			else
				health.value:SetText()
			end
		else
			health.value:SetText()
		end

		if health.valuePercent.Enable == true then
			if min ~= max or health.valuePercent.ShowAlways == true then
				health.valuePercent:SetText(healthPercent)
			else
				health.valuePercent:SetText()
			end

			if health.valuePercent.color == "By Class" then
				health.valuePercent:SetTextColor(unpack(color))
			elseif health.valuePercent.color == "Individual" then
				health.valuePercent:SetTextColor(health.valuePercent.colorIndividual.r, health.valuePercent.colorIndividual.g, health.valuePercent.colorIndividual.b)
			else
				health.valuePercent:SetTextColor(oUF.ColorGradient(min/max, unpack(colors.smooth)))
			end
		else
			health.valuePercent:SetText()
		end

		if health.valueMissing.Enable == true then
			local healthMissing = max-min

			if healthMissing > 0 or health.valueMissing.ShowAlways == true then
				if health.valueMissing.ShortValue == true then
					health.valueMissing:SetText("-"..ShortValue(healthMissing))
				else
					health.valueMissing:SetText("-"..healthMissing)
				end
			else
				health.valueMissing:SetText()
			end

			if health.valueMissing.color == "By Class" then
				health.valueMissing:SetTextColor(unpack(color))
			elseif health.valueMissing.color == "Individual" then
				health.valueMissing:SetTextColor(health.valueMissing.colorIndividual.r, health.valueMissing.colorIndividual.g, health.valueMissing.colorIndividual.b)
			else
				health.valueMissing:SetTextColor(oUF.ColorGradient(min/max, unpack(colors.smooth)))
			end
		else
			health.valueMissing:SetText()
		end
	end

	if UnitIsAFK(unit) then
		if health.value.ShowDead == true then
			if health.value:GetText() then
				if not strfind(health.value:GetText(), "AFK") then
					health.value:SetText("|cffffffff<AFK>|r "..health.value:GetText())
				end
			else
				health.value:SetText("|cffffffff<AFK>|r")
			end
		end

		if health.valuePercent.ShowDead == true then
			if health.valuePercent:GetText() then
				if not strfind(health.valuePercent:GetText(), "AFK") then
					health.valuePercent:SetText("|cffffffff<AFK>|r "..health.valuePercent:GetText())
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
	local color = colors.class[pToken] or {0.5, 0.5, 0.5}
	local color2 = colors.power[pType] or {0.5, 0.5, 0.5}
	local _, r, g, b = UnitAlternatePowerTextureInfo(unit, 2)

	if unit == "player" and entering == true then
		if db.oUF.Player.Power.Color == "By Class" then
			power:SetStatusBarColor(unpack(color))
		elseif db.oUF.Player.Power.Color == "Individual" then
			power:SetStatusBarColor(db.oUF.Player.Power.IndividualColor.r, db.oUF.Player.Power.IndividualColor.g, db.oUF.Player.Power.IndividualColor.b)
		else
			power:SetStatusBarColor(unpack(color2))
		end
	else
		if power.color == "By Class" then
			power:SetStatusBarColor(unpack(color))
		elseif power.color == "Individual" then
			power:SetStatusBarColor(power.colorIndividual.r, power.colorIndividual.g, power.colorIndividual.b)
		else
			if unit == unit:match("boss%d") and select(7, UnitAlternatePowerInfo(unit)) then
				power:SetStatusBarColor(r, g, b)
			else
				power:SetStatusBarColor(unpack(color2))
			end
		end
	end

	local r_, g_, b_ = power:GetStatusBarColor()
	local mu = power.bg.multiplier or 1

	if power.bg.invert == true then
		power.bg:SetVertexColor(r_+(1-r_)*mu, g_+(1-g_)*mu, b_+(1-b_)*mu)
	else
		power.bg:SetVertexColor(r_*mu, g_*mu, b_*mu)
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
		local powerPercent = string.format("%.1f", 100 * min / max).."%"

		if power.value.Enable == true then
			if (power.value.ShowFull == false and min == max) or (power.value.ShowEmpty == false and min == 0) then
				power.value:SetText()
			elseif power.value.Format == "Absolut" then
				power.value:SetFormattedText("%s/%s", min, max)
			elseif power.value.Format == "Absolut & Percent" then
				power.value:SetFormattedText("%s/%s | %s", min, max, powerPercent)
			elseif power.value.Format == "Absolut Short" then
				power.value:SetFormattedText("%s/%s", ShortValue(min), ShortValue(max))
			elseif power.value.Format == "Absolut Short & Percent" then
				power.value:SetFormattedText("%s/%s | %s", ShortValue(min), ShortValue(max), powerPercent)
			elseif power.value.Format == "Standard" then
				power.value:SetFormattedText("%s", min)
			elseif power.value.Format == "Standard Short" then
				power.value:SetFormattedText("%s", ShortValue(min))
			else
				power.value:SetFormattedText("%s", min)
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
				power.valuePercent:SetText(powerPercent)
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
				power.valueMissing:SetText("-"..ShortValue(powerMissing))
			else
				power.valueMissing:SetText("-"..powerMissing)
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
				self.Time:SetFormattedText("%.1f / %.1f |cffff0000-%.1f|r", duration, self.max, self.delay)
			else
				self.Time:SetFormattedText("%.1f |cffff0000-%.1f|r", duration, self.delay)
			end
		elseif self.casting then
			if self.Time.ShowMax == true then
				self.Time:SetFormattedText("%.1f / %.1f |cffff0000-%.1f|r", self.max - duration, self.max, self.delay)
			else
				self.Time:SetFormattedText("%.1f |cffff0000-%.1f|r", self.max - duration, self.delay)
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
	button.backdrop = CreateFrame("Frame", nil, button)
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

	button.remaining = SetFontString(button, LSM:Fetch("font", db.oUF.Settings.Auras.auratimer_font), db.oUF.Settings.Auras.auratimer_size, db.oUF.Settings.Auras.auratimer_flag)
	button.remaining:SetPoint("TOPLEFT", 1, -1)

	button.cd.noOCC = true
	button.cd.noCooldownCount = true

	button.overlay:Hide()

	button.auratype = button:CreateTexture(nil, "OVERLAY")
	button.auratype:SetTexture(buttonTex)
	button.auratype:SetPoint("TOPLEFT", button, "TOPLEFT", -2, 2)
	button.auratype:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
	button.auratype:SetTexCoord(0, 1, 0.02, 1)
end

local PostUpdateAura = function(icons, unit, icon, index, offset, filter, isDebuff, duration, timeLeft)
	local _, _, _, _, dtype, duration, expirationTime, unitCaster, _ = UnitAura(unit, index, icon.filter)
	if not (unitCaster == "player" or unitCaster == "pet" or unitCaster == "vehicle") then
		if icon.debuff then
			icon.icon:SetDesaturated(true)
		end
	end

	if icons.showAuraType and dtype then
		local color = DebuffTypeColor[dtype] or DebuffTypeColor.none
		icon.auratype:SetVertexColor(color.r, color.g, color.b)
	else
		if icon.debuff then
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
	if castbar.Colors.Individual == true then
		castbar:SetStatusBarColor(castbar.Colors.Bar.r, castbar.Colors.Bar.g, castbar.Colors.Bar.b, castbar.Colors.Bar.a)
		castbar.bg:SetVertexColor(castbar.Colors.Background.r, castbar.Colors.Background.g, castbar.Colors.Background.b, castbar.Colors.Background.a)
		castbar.Backdrop:SetBackdropBorderColor(castbar.Colors.Border.r, castbar.Colors.Border.g, castbar.Colors.Border.b, castbar.Colors.Border.a)
	else
		if unit == "target" or unit == "focus" or unit == "pet" then unit = "player" end
		local pClass, pToken = UnitClass(unit)
		local color = colors.class[pToken]
		
		castbar:SetStatusBarColor(color[1], color[2], color[3], 0.68)
		castbar.bg:SetVertexColor(0.15, 0.15, 0.15, 0.75)
		castbar.Backdrop:SetBackdropBorderColor(0, 0, 0, 0.7)
	end
	
	--if castbar.interrupt and UnitCanAttack("player", unit) and castbar.Colors.Shield.Enable then
	--	castbar:SetStatusBarColor(castbar.Colors.Shield.r, castbar.Colors.Shield.g, castbar.Colors.Shield.b, castbar.Colors.Shield.a)
	--end
end

local ThreatOverride = function(self, event, unit)
	if unit ~= self.unit then return end
	if unit == "vehicle" then unit = "player" end

	unit = unit or self.unit
	local status = UnitThreatSituation(unit)

	if(status and status > 0) then
		local r, g, b = GetThreatStatusColor(status)
		for i = 1, 8 do
			self.Threat[i]:SetVertexColor(r, g, b)
		end
		self.Threat:Show()
	else
		self.Threat:Hide()
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

local SoulShardsOverride = function(self, event, unit, powerType)
	if self.unit ~= unit or (powerType and powerType ~= "SOUL_SHARDS") then return end

	local num = UnitPower(unit, SPELL_POWER_SOUL_SHARDS)
	for i = 1, SHARD_BAR_NUM_SHARDS do
		if i <= num then
			self.SoulShards[i]:SetAlpha(1)
		else
			self.SoulShards[i]:SetAlpha(.4)
		end
	end
end

local HolyPowerOverride = function(self, event, unit, powerType)
	if self.unit ~= unit or (powerType and powerType ~= "HOLY_POWER") then return end

	local num = UnitPower(unit, SPELL_POWER_HOLY_POWER)
	for i = 1, MAX_HOLY_POWER do
		if i <= num then
			self.HolyPower[i]:SetAlpha(1)
		else
			self.HolyPower[i]:SetAlpha(.4)
		end
	end
end

local PostEclipseUpdate = function(self, unit)
	if self.ShowText then
		if GetEclipseDirection() == "sun" then
			self.LunarText:SetText(50+math.floor((UnitPower("player", SPELL_POWER_ECLIPSE)+1)/2))
			self.LunarText:SetTextColor(unpack(colors.eclipsebar["LunarBG"]))
			self.SolarText:SetText("Starfire!")
			self.SolarText:SetTextColor(unpack(colors.eclipsebar["LunarBG"]))
		elseif GetEclipseDirection() == "moon" then
			self.LunarText:SetText("Wrath!")
			self.LunarText:SetTextColor(unpack(colors.eclipsebar["SolarBG"]))
			self.SolarText:SetText(50-math.floor((UnitPower("player", SPELL_POWER_ECLIPSE)+1)/2))
			self.SolarText:SetTextColor(unpack(colors.eclipsebar["SolarBG"]))
		elseif self:IsShown() then
			self.LunarText:SetText(50+math.floor((UnitPower("player", SPELL_POWER_ECLIPSE)+1)/2))
			self.LunarText:SetTextColor(unpack(colors.eclipsebar["SolarBG"]))
			self.SolarText:SetText(50-math.floor((UnitPower("player", SPELL_POWER_ECLIPSE)+1)/2))
			self.SolarText:SetTextColor(unpack(colors.eclipsebar["LunarBG"]))
		end
	end
end

local EclipseBarBuff = function(self, unit)
	if GetEclipseDirection() == "sun" then
		self.LunarBar:SetAlpha(1)
		self.SolarBar:SetAlpha(0.7)
		self.LunarBar:SetStatusBarColor(unpack(colors.eclipsebar["Lunar"]))
		self.SolarBar:SetStatusBarColor(unpack(colors.eclipsebar["SolarBG"]))
	elseif GetEclipseDirection() == "moon" then
		self.SolarBar:SetAlpha(1)
		self.LunarBar:SetAlpha(0.7)
		self.LunarBar:SetStatusBarColor(unpack(colors.eclipsebar["LunarBG"]))
		self.SolarBar:SetStatusBarColor(unpack(colors.eclipsebar["Solar"]))
	elseif self:IsShown() then
		self.LunarBar:SetAlpha(1)
		self.SolarBar:SetAlpha(1)
		self.LunarBar:SetStatusBarColor(unpack(colors.eclipsebar["LunarBG"]))
		self.SolarBar:SetStatusBarColor(unpack(colors.eclipsebar["SolarBG"]))
	end
end

local PostUpdateAltPower = function(altpowerbar, min, cur, max)
	local pClass, pToken = UnitClass("player")
	local color = colors.class[pToken] or {0.5, 0.5, 0.5}

	local tex, r, g, b = UnitAlternatePowerTextureInfo("player", 2)

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
			local perc = string.format("%.1f", 100 * cur / max).."%"

			if altpowerbar.Text.ShowAlways == false and (cur == max or cur == min) then
				altpowerbar.Text:SetText()
			elseif altpowerbar.Text.Format == "Absolut" then
				altpowerbar.Text:SetFormattedText("%s/%s", cur, max)
			elseif altpowerbar.Text.Format == "Percent" then
				altpowerbar.Text:SetFormattedText("%s", perc)
			elseif altpowerbar.Text.Format == "Standard" then
				altpowerbar.Text:SetFormattedText("%s", cur)
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

local PostUpdateDruidMana = function(druidmana, unit, min, max)
	if druidmana.color == "By Class" then
		druidmana.ManaBar:SetStatusBarColor(unpack(LUI.oUF.colors.class["DRUID"]))
	elseif druidmana.color == "By Type" then
		druidmana.ManaBar:SetStatusBarColor(unpack(LUI.oUF.colors.power["MANA"]))
	else
		druidmana.ManaBar:SetStatusBarColor(oUF.ColorGradient(min/max, unpack(colors.smooth)))
	end

	local bg = druidmana.bg

	if bg then
		local mu = bg.multiplier or 1
		local r, g, b = druidmana.ManaBar:GetStatusBarColor()
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
			health.value:SetText(health.value.ShowDead and "|cffD7BEA5<Unseen>|r" or "")
			health.valuePercent:SetText(health.valuePercent.ShowDead and "|cffD7BEA5<Unseen>|r" or "")
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

local SwingOverrideText = function(bar, now)
	local text = bar.Text

	if not text then return end

	if text.Enable then
		local value = string.format("%.1f", bar.max - now)
		if text.Format == "Absolut" then
			text:SetFormattedText("%s/%s", string.format("%.1f", bar.max - now), string.format("%.1f", bar.max - bar.min))
		else
			text:SetFormattedText("%s", string.format("%.1f", bar.max - now))
		end
	else
		text:SetText("")
	end
end

local VengeanceOverrideText = function(bar, value)
	local text = bar.Text

	if not text then return end

	if text.Enable then
		if text.Format == "Absolut" then
			bar.Text:SetFormattedText("%s/%s", value, bar.max)
		else
			bar.Text:SetFormattedText("%s", value)
		end
	else
		text:SetText("")
	end
end

do
	local f = CreateFrame("Frame")

	f:RegisterEvent("UNIT_ENTERED_VEHICLE")
	f:RegisterEvent("UNIT_EXITED_VEHICLE")

	local delay = 0.5
	local OnUpdate = function(self, elapsed)
		if not oUF_LUI_pet then return end
		self.elapsed = (self.elapsed or delay) - elapsed
		if self.elapsed <= 0 then
			oUF_LUI_pet:PLAYER_ENTERING_WORLD()
			self:SetScript("OnUpdate", nil)
			if entering and oUF_LUI_pet.PostEnterVehicle then
				oUF_LUI_pet:PostEnterVehicle("enter")
			elseif not entering and oUF_LUI_pet.PostExitVehicle then
				oUF_LUI_pet:PostExitVehicle("exit")
			end
		end
	end

	f:SetScript("OnEvent", function(self, event, unit)
		if unit == "player" then
			if event == "UNIT_ENTERED_VEHICLE" then
				entering = true
			else
				entering = false
			end
			f.elapsed = delay
			f:SetScript("OnUpdate", OnUpdate)
		end
	end)
end

------------------------------------------------------------------------
--	Create/Style Funcs
--	They are stored in the LUI.oUF so the LUI options can easily
--	access them
------------------------------------------------------------------------

LUI.oUF.funcs = {
	Health = function(self, unit, oufdb)
		if not self.Health then
			self.Health = CreateFrame("StatusBar", nil, self)
			self.Health:SetFrameLevel(2)
			self.Health.bg = self.Health:CreateTexture(nil, "BORDER")
			self.Health.bg:SetAllPoints(self.Health)
		end

		self.Health:SetHeight(tonumber(oufdb.Health.Height))
		self.Health:SetWidth(tonumber(oufdb.Health.Width) * (self:GetWidth()/oufdb.Width)) -- needed for 25/40 man raid width downscaling!
		self.Health:SetStatusBarTexture(LSM:Fetch("statusbar", oufdb.Health.Texture))
		self.Health:ClearAllPoints()
		self.Health:SetPoint("TOPLEFT", self, "TOPLEFT", tonumber(oufdb.Health.X) * (self:GetWidth()/oufdb.Width), tonumber(oufdb.Health.Y)) -- needed for 25/40 man raid width downscaling!

		self.Health.bg:SetTexture(LSM:Fetch("statusbar", oufdb.Health.TextureBG))
		self.Health.bg:SetAlpha(oufdb.Health.BGAlpha)
		self.Health.bg.multiplier = oufdb.Health.BGMultiplier
		self.Health.bg.invert = oufdb.Health.BGInvert

		self.Health.colorTapping = (unit == "target") and oufdb.Health.Tapping or false
		self.Health.colorDisconnected = false
		self.Health.color = oufdb.Health.Color
		self.Health.colorIndividual = oufdb.Health.IndividualColor
		self.Health.Smooth = oufdb.Health.Smooth
		self.Health.colorReaction = false
		self.Health.frequentUpdates = false
	end,
	Power = function(self, unit, oufdb)
		if not self.Power then
			self.Power = CreateFrame("StatusBar", nil, self)
			self.Power:SetFrameLevel(2)
			self.Power.bg = self.Power:CreateTexture(nil, "BORDER")
			self.Power.bg:SetAllPoints(self.Power)
		end

		self.Power:SetHeight(tonumber(oufdb.Power.Height))
		self.Power:SetWidth(tonumber(oufdb.Power.Width) * (self:GetWidth()/oufdb.Width)) -- needed for 25/40 man raid width downscaling!
		self.Power:SetStatusBarTexture(LSM:Fetch("statusbar", oufdb.Power.Texture))
		self.Power:ClearAllPoints()
		self.Power:SetPoint("TOPLEFT", self, "TOPLEFT", tonumber(oufdb.Power.X) * (self:GetWidth()/oufdb.Width), tonumber(oufdb.Power.Y)) -- needed for 25/40 man raid width downscaling!

		self.Power.bg:SetTexture(LSM:Fetch("statusbar", oufdb.Power.TextureBG))
		self.Power.bg:SetAlpha(oufdb.Power.BGAlpha)
		self.Power.bg.multiplier = oufdb.Power.BGMultiplier
		self.Power.bg.invert = oufdb.Power.BGInvert

		self.Power.colorTapping = false
		self.Power.colorDisconnected = false
		self.Power.colorSmooth = false
		self.Power.color = oufdb.Power.Color
		self.Power.colorIndividual = oufdb.Power.IndividualColor
		self.Power.Smooth = oufdb.Power.Smooth
		self.Power.colorReaction = false
		self.Power.frequentUpdates = true
		self.Power.displayAltPower = unit == unit:match("boss%d")

		if oufdb.Power.Enable == true then
			self.Power:Show()
		else
			self.Power:Hide()
		end
	end,
	Full = function(self, unit, oufdb)
		if not self.Full then
			self.Full = CreateFrame("StatusBar", nil, self)
			self.Full:SetFrameLevel(2)
			self.Full:SetValue(100)
		end

		self.Full:SetHeight(tonumber(oufdb.Full.Height))
		self.Full:SetWidth(tonumber(oufdb.Full.Width) * (self:GetWidth()/oufdb.Width)) -- needed for 25/40 man raid width downscaling!
		self.Full:SetStatusBarTexture(LSM:Fetch("statusbar", oufdb.Full.Texture))
		self.Full:SetStatusBarColor(tonumber(oufdb.Full.Color.r), tonumber(oufdb.Full.Color.g), tonumber(oufdb.Full.Color.b), tonumber(oufdb.Full.Color.a))
		self.Full:ClearAllPoints()
		self.Full:SetPoint("TOPLEFT", self, "TOPLEFT", tonumber(oufdb.Full.X) * (self:GetWidth()/oufdb.Width), tonumber(oufdb.Full.Y)) -- needed for 25/40 man raid width downscaling!
		self.Full:SetAlpha(oufdb.Full.Alpha)

		if oufdb.Full.Enable == true then
			self.Full:Show()
		else
			self.Full:Hide()
		end
	end,
	FrameBackdrop = function(self, unit, oufdb)
		if not self.FrameBackdrop then self.FrameBackdrop = CreateFrame("Frame", nil, self) end

		self.FrameBackdrop:ClearAllPoints()
		self.FrameBackdrop:SetPoint("TOPLEFT", self, "TOPLEFT", tonumber(oufdb.Backdrop.Padding.Left), tonumber(oufdb.Backdrop.Padding.Top))
		self.FrameBackdrop:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", tonumber(oufdb.Backdrop.Padding.Right), tonumber(oufdb.Backdrop.Padding.Bottom))
		self.FrameBackdrop:SetFrameStrata("BACKGROUND")
		self.FrameBackdrop:SetFrameLevel(20)
		self.FrameBackdrop:SetBackdrop({
			bgFile = LSM:Fetch("background", oufdb.Backdrop.Texture),
			edgeFile = LSM:Fetch("border", oufdb.Border.EdgeFile),
			edgeSize = tonumber(oufdb.Border.EdgeSize),
			insets = {
				left = tonumber(oufdb.Border.Insets.Left),
				right = tonumber(oufdb.Border.Insets.Right),
				top = tonumber(oufdb.Border.Insets.Top),
				bottom = tonumber(oufdb.Border.Insets.Bottom)
			}
		})
		self.FrameBackdrop:SetBackdropColor(tonumber(oufdb.Backdrop.Color.r),tonumber(oufdb.Backdrop.Color.g),tonumber(oufdb.Backdrop.Color.b),tonumber(oufdb.Backdrop.Color.a))
		self.FrameBackdrop:SetBackdropBorderColor(tonumber(oufdb.Border.Color.r), tonumber(oufdb.Border.Color.g), tonumber(oufdb.Border.Color.b), tonumber(oufdb.Border.Color.a))
	end,

	--texts
	Info = function(self, unit, oufdb)
		if not self.Info then self.Info = SetFontString(self.Overlay, LSM:Fetch("font", oufdb.Texts.Name.Font), tonumber(oufdb.Texts.Name.Size), oufdb.Texts.Name.Outline) end
		self.Info:SetFont(LSM:Fetch("font", oufdb.Texts.Name.Font), tonumber(oufdb.Texts.Name.Size), oufdb.Texts.Name.Outline)
		self.Info:SetTextColor(oufdb.Texts.Name.IndividualColor.r, oufdb.Texts.Name.IndividualColor.g, oufdb.Texts.Name.IndividualColor.b)
		self.Info:ClearAllPoints()
		self.Info:SetPoint(oufdb.Texts.Name.Point, self, oufdb.Texts.Name.RelativePoint, tonumber(oufdb.Texts.Name.X), tonumber(oufdb.Texts.Name.Y))

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
			self.Info = SetFontString(self.Overlay, LSM:Fetch("font", oufdb.Texts.Name.Font), tonumber(oufdb.Texts.Name.Size), oufdb.Texts.Name.Outline)
			self.Info:SetPoint("CENTER", self, "CENTER", 0, 0)
		end
		self.Info:SetTextColor(oufdb.Texts.Name.IndividualColor.r, oufdb.Texts.Name.IndividualColor.g, oufdb.Texts.Name.IndividualColor.b)
		self.Info:SetFont(LSM:Fetch("font", oufdb.Texts.Name.Font), tonumber(oufdb.Texts.Name.Size), oufdb.Texts.Name.Outline)

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
		if not self.Health.value then self.Health.value = SetFontString(self.Overlay, LSM:Fetch("font", oufdb.Texts.Health.Font), tonumber(oufdb.Texts.Health.Size), oufdb.Texts.Health.Outline) end
		self.Health.value:SetFont(LSM:Fetch("font", oufdb.Texts.Health.Font), tonumber(oufdb.Texts.Health.Size), oufdb.Texts.Health.Outline)
		self.Health.value:ClearAllPoints()
		self.Health.value:SetPoint(oufdb.Texts.Health.Point, self, oufdb.Texts.Health.RelativePoint, tonumber(oufdb.Texts.Health.X), tonumber(oufdb.Texts.Health.Y))

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
		if not self.Health.valuePercent then self.Health.valuePercent = SetFontString(self.Overlay, LSM:Fetch("font", oufdb.Texts.HealthPercent.Font), tonumber(oufdb.Texts.HealthPercent.Size), oufdb.Texts.HealthPercent.Outline) end
		self.Health.valuePercent:SetFont(LSM:Fetch("font", oufdb.Texts.HealthPercent.Font), tonumber(oufdb.Texts.HealthPercent.Size), oufdb.Texts.HealthPercent.Outline)
		self.Health.valuePercent:ClearAllPoints()
		self.Health.valuePercent:SetPoint(oufdb.Texts.HealthPercent.Point, self, oufdb.Texts.HealthPercent.RelativePoint, tonumber(oufdb.Texts.HealthPercent.X), tonumber(oufdb.Texts.HealthPercent.Y))

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
		if not self.Health.valueMissing then self.Health.valueMissing = SetFontString(self.Overlay, LSM:Fetch("font", oufdb.Texts.HealthMissing.Font), tonumber(oufdb.Texts.HealthMissing.Size), oufdb.Texts.HealthMissing.Outline) end
		self.Health.valueMissing:SetFont(LSM:Fetch("font", oufdb.Texts.HealthMissing.Font), tonumber(oufdb.Texts.HealthMissing.Size), oufdb.Texts.HealthMissing.Outline)
		self.Health.valueMissing:ClearAllPoints()
		self.Health.valueMissing:SetPoint(oufdb.Texts.HealthMissing.Point, self, oufdb.Texts.HealthMissing.RelativePoint, tonumber(oufdb.Texts.HealthMissing.X), tonumber(oufdb.Texts.HealthMissing.Y))

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
		if not self.Power.value then self.Power.value = SetFontString(self.Overlay, LSM:Fetch("font", oufdb.Texts.Power.Font), tonumber(oufdb.Texts.Power.Size), oufdb.Texts.Power.Outline) end
		self.Power.value:SetFont(LSM:Fetch("font", oufdb.Texts.Power.Font), tonumber(oufdb.Texts.Power.Size), oufdb.Texts.Power.Outline)
		self.Power.value:ClearAllPoints()
		self.Power.value:SetPoint(oufdb.Texts.Power.Point, self, oufdb.Texts.Power.RelativePoint, tonumber(oufdb.Texts.Power.X), tonumber(oufdb.Texts.Power.Y))

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
		if not self.Power.valuePercent then self.Power.valuePercent = SetFontString(self.Overlay, LSM:Fetch("font", oufdb.Texts.PowerPercent.Font), tonumber(oufdb.Texts.PowerPercent.Size), oufdb.Texts.PowerPercent.Outline) end
		self.Power.valuePercent:SetFont(LSM:Fetch("font", oufdb.Texts.PowerPercent.Font), tonumber(oufdb.Texts.PowerPercent.Size), oufdb.Texts.PowerPercent.Outline)
		self.Power.valuePercent:ClearAllPoints()
		self.Power.valuePercent:SetPoint(oufdb.Texts.PowerPercent.Point, self, oufdb.Texts.PowerPercent.RelativePoint, tonumber(oufdb.Texts.PowerPercent.X), tonumber(oufdb.Texts.PowerPercent.Y))

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
		if not self.Power.valueMissing then self.Power.valueMissing = SetFontString(self.Overlay, LSM:Fetch("font", oufdb.Texts.PowerMissing.Font), tonumber(oufdb.Texts.PowerMissing.Size), oufdb.Texts.PowerMissing.Outline) end
		self.Power.valueMissing:SetFont(LSM:Fetch("font", oufdb.Texts.PowerMissing.Font), tonumber(oufdb.Texts.PowerMissing.Size), oufdb.Texts.PowerMissing.Outline)
		self.Power.valueMissing:ClearAllPoints()
		self.Power.valueMissing:SetPoint(oufdb.Texts.PowerMissing.Point, self, oufdb.Texts.PowerMissing.RelativePoint, tonumber(oufdb.Texts.PowerMissing.X), tonumber(oufdb.Texts.PowerMissing.Y))

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

	-- icons
	Leader = function(self, unit, oufdb)
		if not self.Leader then
			self.Leader = self.Overlay:CreateTexture(nil, "OVERLAY")
			self.Assistant = self.Overlay:CreateTexture(nil, "OVERLAY")
		end

		self.Leader:SetHeight(oufdb.Icons.Leader.Size)
		self.Leader:SetWidth(oufdb.Icons.Leader.Size)
		self.Leader:ClearAllPoints()
		self.Leader:SetPoint(oufdb.Icons.Leader.Point, self, oufdb.Icons.Leader.Point, tonumber(oufdb.Icons.Leader.X), tonumber(oufdb.Icons.Leader.Y))

		self.Assistant:SetHeight(oufdb.Icons.Leader.Size)
		self.Assistant:SetWidth(oufdb.Icons.Leader.Size)
		self.Assistant:ClearAllPoints()
		self.Assistant:SetPoint(oufdb.Icons.Leader.Point, self, oufdb.Icons.Leader.Point, tonumber(oufdb.Icons.Leader.X), tonumber(oufdb.Icons.Leader.Y))
	end,
	MasterLooter = function(self, unit, oufdb)
		if not self.MasterLooter then self.MasterLooter = self.Overlay:CreateTexture(nil, "OVERLAY") end

		self.MasterLooter:SetHeight(oufdb.Icons.Lootmaster.Size)
		self.MasterLooter:SetWidth(oufdb.Icons.Lootmaster.Size)
		self.MasterLooter:ClearAllPoints()
		self.MasterLooter:SetPoint(oufdb.Icons.Lootmaster.Point, self, oufdb.Icons.Lootmaster.Point, tonumber(oufdb.Icons.Lootmaster.X), tonumber(oufdb.Icons.Lootmaster.Y))
	end,
	RaidIcon = function(self, unit, oufdb)
		if not self.RaidIcon then
			self.RaidIcon = self.Overlay:CreateTexture(nil, "OVERLAY")
			self.RaidIcon:SetTexture("Interface\\AddOns\\LUI\\media\\textures\\icons\\raidicons.blp")
		end

		self.RaidIcon:SetHeight(oufdb.Icons.Raid.Size)
		self.RaidIcon:SetWidth(oufdb.Icons.Raid.Size)
		self.RaidIcon:ClearAllPoints()
		self.RaidIcon:SetPoint(oufdb.Icons.Raid.Point, self, oufdb.Icons.Raid.Point, tonumber(oufdb.Icons.Raid.X), tonumber(oufdb.Icons.Raid.Y))
	end,
	LFDRole = function(self, unit, oufdb)
		if not self.LFDRole then self.LFDRole = self.Overlay:CreateTexture(nil, "OVERLAY") end

		self.LFDRole:SetHeight(oufdb.Icons.Role.Size)
		self.LFDRole:SetWidth(oufdb.Icons.Role.Size)
		self.LFDRole:ClearAllPoints()
		self.LFDRole:SetPoint(oufdb.Icons.Role.Point, self, oufdb.Icons.Role.Point, tonumber(oufdb.Icons.Role.X), tonumber(oufdb.Icons.Role.Y))
	end,
	PvP = function(self, unit, oufdb)
		if not self.PvP then
			self.PvP = self.Overlay:CreateTexture(nil, "OVERLAY")
			if unit == "player" then
				self.PvP.Timer = SetFontString(self.Overlay, LSM:Fetch("font", oufdb.Texts.PvP.Font), oufdb.Texts.PvP.Size, oufdb.Texts.PvP.Outline)
				self.Health:HookScript("OnUpdate", function(_, elapsed)
					if UnitIsPVP(unit) and oufdb.Icons.PvP.Enable and oufdb.Texts.PvP.Enable then
						if (GetPVPTimer() == 301000 or GetPVPTimer() == -1) then
							if self.PvP.Timer:IsShown() then
								self.PvP.Timer:Hide()
							end
						else
							self.PvP.Timer:Show()
							local min = math.floor(GetPVPTimer()/1000/60)
							local sec = (math.floor(GetPVPTimer()/1000))-(min*60)
							if sec < 10 then sec = "0"..sec end
							self.PvP.Timer:SetText(min..":"..sec)
						end
					elseif self.PvP.Timer:IsShown() then
						self.PvP.Timer:Hide()
					end
				end)
			end
		end

		self.PvP:SetHeight(oufdb.Icons.PvP.Size)
		self.PvP:SetWidth(oufdb.Icons.PvP.Size)
		self.PvP:ClearAllPoints()
		self.PvP:SetPoint(oufdb.Icons.PvP.Point, self, oufdb.Icons.PvP.Point, tonumber(oufdb.Icons.PvP.X), tonumber(oufdb.Icons.PvP.Y))

		if self.PvP.Timer then
			self.PvP.Timer:SetFont(LSM:Fetch("font", oufdb.Texts.PvP.Font), oufdb.Texts.PvP.Size, oufdb.Texts.PvP.Outline)
			self.PvP.Timer:SetPoint("CENTER", self.PvP, "CENTER", tonumber(oufdb.Texts.PvP.X), tonumber(oufdb.Texts.PvP.Y))
			self.PvP.Timer:SetTextColor(oufdb.Texts.PvP.Color.r, oufdb.Texts.PvP.Color.g, oufdb.Texts.PvP.Color.b)

			if oufdb.Icons.PvP.Enable and oufdb.Texts.PvP.Enable then
				self.PvP.Timer:Show()
			else
				self.PvP.Timer:Hide()
			end
		end
	end,
	Resting = function(self, unit, oufdb)
		if not self.Resting then self.Resting = self.Overlay:CreateTexture(nil, "OVERLAY") end

		self.Resting:SetHeight(oufdb.Icons.Resting.Size)
		self.Resting:SetWidth(oufdb.Icons.Resting.Size)
		self.Resting:ClearAllPoints()
		self.Resting:SetPoint(oufdb.Icons.Resting.Point, self, oufdb.Icons.Resting.Point, tonumber(oufdb.Icons.Resting.X), tonumber(oufdb.Icons.Resting.Y))
	end,
	Combat = function(self, unit, oufdb)
		if not self.Combat then self.Combat = self.Overlay:CreateTexture(nil, "OVERLAY") end

		self.Combat:SetHeight(oufdb.Icons.Combat.Size)
		self.Combat:SetWidth(oufdb.Icons.Combat.Size)
		self.Combat:ClearAllPoints()
		self.Combat:SetPoint(oufdb.Icons.Combat.Point, self, oufdb.Icons.Combat.Point, tonumber(oufdb.Icons.Combat.X), tonumber(oufdb.Icons.Combat.Y))
	end,
	ReadyCheck = function(self, unit, oufdb)
		if not self.ReadyCheck then self.ReadyCheck = self.Overlay:CreateTexture(nil, "OVERLAY") end
		
		self.ReadyCheck:SetHeight(oufdb.Icons.ReadyCheck.Size)
		self.ReadyCheck:SetWidth(oufdb.Icons.ReadyCheck.Size)
		self.ReadyCheck:ClearAllPoints()
		self.ReadyCheck:SetPoint(oufdb.Icons.ReadyCheck.Point, self, oufdb.Icons.ReadyCheck.Point, tonumber(oufdb.Icons.ReadyCheck.X), tonumber(oufdb.Icons.ReadyCheck.Y))
	end,
	
	-- player specific
	Experience = function(self, unit, ouf_xp_rep)
		if not self.XP then
			self.XP = CreateFrame("Frame", nil, self)
			self.XP:SetFrameLevel(self:GetFrameLevel() + 2)
			self.XP:SetHeight(17)
			self.XP:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 2, -2)
			self.XP:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", -2, -2)

			self.Experience = CreateFrame("StatusBar",  nil, self.XP)
			self.Experience:SetStatusBarTexture(normTex)
			self.Experience:SetAllPoints(self.XP)

			self.Experience.Value = SetFontString(self.Experience, LSM:Fetch("font", ouf_xp_rep.Font), tonumber(ouf_xp_rep.FontSize), ouf_xp_rep.FontFlag)
			self.Experience.Value:SetAllPoints(self.XP)
			self.Experience.Value:SetFontObject(GameFontHighlight)

			self.Experience.Rested = CreateFrame("StatusBar", nil, self.Experience)
			self.Experience.Rested:SetAllPoints(self.XP)
			self.Experience.Rested:SetStatusBarTexture(normTex)

			self.Experience.bg = self.XP:CreateTexture(nil, "BACKGROUND")
			self.Experience.bg:SetAllPoints(self.XP)
			self.Experience.bg:SetTexture(normTex)

			self.Experience.Override = function(self, event, unit)
				if(self.unit ~= unit) then return end
				if unit == "vehicle" then unit = "player" end

				if UnitLevel(unit) == MAX_PLAYER_LEVEL then
					return self.Experience:Hide()
				else
					self.Experience:Show()
				end

				local min, max = UnitXP(unit), UnitXPMax(unit)

				self.Experience:SetMinMaxValues(0, max)
				self.Experience:SetValue(min)

				if self.Experience.Rested then
					local exhaustion = unit == "player" and GetXPExhaustion() or 0
					self.Experience.Rested:SetMinMaxValues(0, max)
					self.Experience.Rested:SetValue(math.min(min + exhaustion, max))
				end
			end

			local events = {"PLAYER_XP_UPDATE", "PLAYER_LEVEL_UP", "UPDATE_EXHAUSTION", "PLAYER_ENTERING_WORLD"}
			for i=1, #events do self.XP:RegisterEvent(events[i]) end
			self.XP:SetScript("OnEvent", function(_, event)
				local value, max = UnitXP("player"), UnitXPMax("player")
				self.Experience.Value:SetText(value.." / "..max.."  ("..math.floor(value / max * 100 + 0.5).."%)")
				if event == "PLAYER_ENTERING_WORLD" then self.XP:UnregisterEvent("PLAYER_ENTERING_WORLD") end
			end)

			local frameStrata = self.XP:GetFrameStrata()
			self.XP:SetScript("OnEnter", function()
				self.XP:SetAlpha(ouf_xp_rep.Experience.Alpha)

				-- Set frame strata to raise frame above health text.
				frameStrata = self.XP:GetFrameStrata()
				self.XP:SetFrameStrata("TOOLTIP")

				local level, value, max, rested = UnitLevel("player"), UnitXP("player"), UnitXPMax("player"), GetXPExhaustion()
				GameTooltip:SetOwner(self.XP, "ANCHOR_LEFT")
				GameTooltip:ClearLines()
				GameTooltip:AddLine("Level "..level)
				if (rested and rested > 0) then
					GameTooltip:AddLine("Rested: "..rested)
				end
				GameTooltip:AddLine("Remaining: "..max - value)
				GameTooltip:Show()
			end)

			self.XP:SetScript("OnLeave", function()
				if not ouf_xp_rep.Experience.AlwaysShow then
					self.XP:SetAlpha(0)
				end

				-- Reset frame strata back to normal level.
				self.XP:SetFrameStrata(frameStrata)
				GameTooltip:Hide()
			end)
			
			self.XP.Enable = true
		end

		self.Experience:SetStatusBarColor(ouf_xp_rep.Experience.FillColor.r, ouf_xp_rep.Experience.FillColor.g, ouf_xp_rep.Experience.FillColor.b, ouf_xp_rep.Experience.FillColor.a)

		self.Experience.Value:SetFont(LSM:Fetch("font", ouf_xp_rep.Font), tonumber(ouf_xp_rep.FontSize), ouf_xp_rep.FontFlag)
		self.Experience.Value:SetJustifyH(ouf_xp_rep.FontJustify)
		self.Experience.Value:SetTextColor(ouf_xp_rep.FontColor.r, ouf_xp_rep.FontColor.g, ouf_xp_rep.FontColor.b, ouf_xp_rep.FontColor.a)

		self.Experience.Rested:SetStatusBarColor(ouf_xp_rep.Experience.RestedColor.r, ouf_xp_rep.Experience.RestedColor.g, ouf_xp_rep.Experience.RestedColor.b, ouf_xp_rep.Experience.RestedColor.a)
		self.Experience.bg:SetVertexColor(ouf_xp_rep.Experience.BGColor.r, ouf_xp_rep.Experience.BGColor.g, ouf_xp_rep.Experience.BGColor.b, ouf_xp_rep.Experience.BGColor.a)

		if ouf_xp_rep.Experience.AlwaysShow then
			self.XP:SetAlpha(ouf_xp_rep.Experience.Alpha)
		else
			self.XP:SetAlpha(0)
		end

		if ouf_xp_rep.Experience.ShowValue then
			self.Experience.Value:Show()
		else
			self.Experience.Value:Hide()
		end
	end,
	Reputation = function(self, unit, ouf_xp_rep)
		if not self.Rep then
			self.Rep = CreateFrame("Frame", nil, self)
			self.Rep:SetFrameLevel(self:GetFrameLevel() + 2)
			self.Rep:SetHeight(17)
			self.Rep:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 2, -2)
			self.Rep:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", -2, -2)

			self.Reputation = CreateFrame("StatusBar", nil, self.Rep)
			self.Reputation:SetStatusBarTexture(normTex)
			self.Reputation:SetAllPoints(self.Rep)

			self.Reputation.Value = SetFontString(self.Reputation, LSM:Fetch("font", ouf_xp_rep.Font), tonumber(ouf_xp_rep.FontSize), ouf_xp_rep.FontFlag)
			self.Reputation.Value:SetAllPoints(self.Rep)
			self.Reputation.Value:SetFontObject(GameFontHighlight)

			self.Reputation.bg = self.Reputation:CreateTexture(nil, "BACKGROUND")
			self.Reputation.bg:SetAllPoints(self.Rep)
			self.Reputation.bg:SetTexture(normTex)

			local events = {"UPDATE_FACTION", "PLAYER_ENTERING_WORLD"}
			for i=1, #events do self.Rep:RegisterEvent(events[i]) end
			self.Rep:SetScript("OnEvent", function(_, event)
				if GetWatchedFactionInfo() then
					local _, _, min, max, value = GetWatchedFactionInfo()
					self.Reputation.Value:SetText(value - min.." / "..max - min.."  ("..math.floor(((value - min) / (max - min)) * 100 + 0.5).."%)")
				else
					self.Reputation.Value:SetText("")
				end
				if event == "PLAYER_ENTERING_WORLD" then self.Rep:UnregisterEvent("PLAYER_ENTERING_WORLD") end
			end)

			local frameStrata = self.Rep:GetFrameStrata()
			self.Rep:SetScript("OnEnter", function()
				self.Rep:SetAlpha(ouf_xp_rep.Reputation.Alpha)

				-- Set frame strata to raise frame above health text.
				frameStrata = self.Rep:GetFrameStrata()
				self.Rep:SetFrameStrata("TOOLTIP")

				GameTooltip:SetOwner(self.Rep, "ANCHOR_LEFT")
				GameTooltip:ClearLines()
				if GetWatchedFactionInfo() then
					local name, standing, min, max, value = GetWatchedFactionInfo()
					GameTooltip:AddLine(name..": "..standings[standing])
					GameTooltip:AddLine("Remaining: "..max - value)
				else
					GameTooltip:AddLine("You are not tracking any factions")
				end
				GameTooltip:Show()
			end)

			self.Rep:SetScript("OnLeave", function()
				if ouf_xp_rep.Reputation.AlwaysShow ~= true then
					self.Rep:SetAlpha(0)
				end

				-- Reset frame strata back to normal level.
				self.Rep:SetFrameStrata(frameStrata)
				GameTooltip:Hide()
			end)
			
			self.Rep.Enable = true
		end

		self.Reputation:SetStatusBarColor(ouf_xp_rep.Reputation.FillColor.r, ouf_xp_rep.Reputation.FillColor.g, ouf_xp_rep.Reputation.FillColor.b, ouf_xp_rep.Reputation.FillColor.a)

		self.Reputation.Value:SetFont(LSM:Fetch("font", ouf_xp_rep.Font), tonumber(ouf_xp_rep.FontSize), ouf_xp_rep.FontFlag)
		self.Reputation.Value:SetJustifyH(ouf_xp_rep.FontJustify)
		self.Reputation.Value:SetTextColor(ouf_xp_rep.FontColor.r, ouf_xp_rep.FontColor.g, ouf_xp_rep.FontColor.b, ouf_xp_rep.FontColor.a)

		self.Reputation.bg:SetVertexColor(ouf_xp_rep.Reputation.BGColor.r, ouf_xp_rep.Reputation.BGColor.g, ouf_xp_rep.Reputation.BGColor.b, ouf_xp_rep.Reputation.BGColor.a)

		if ouf_xp_rep.Reputation.AlwaysShow == true then
			self.Rep:SetAlpha(ouf_xp_rep.Reputation.Alpha)
		else
			self.Rep:SetAlpha(0)
		end

		if ouf_xp_rep.Reputation.ShowValue == true then
			self.Reputation.Value:Show()
		else
			self.Reputation.Value:Hide()
		end
	end,

	Swing = function(self, unit, oufdb)
		if not self.Swing then
			self.Swing = CreateFrame("Frame", nil, UIParent)
			self.Swing.Text = SetFontString(self.Swing, LSM:Fetch("font", oufdb.Swing.Text.Font), oufdb.Swing.Text.Size, oufdb.Swing.Text.Outline)
			self.Swing.TextMH = SetFontString(self.Swing, LSM:Fetch("font", oufdb.Swing.Text.Font), oufdb.Swing.Text.Size, oufdb.Swing.Text.Outline)
			self.Swing.TextOH = SetFontString(self.Swing, LSM:Fetch("font", oufdb.Swing.Text.Font), oufdb.Swing.Text.Size, oufdb.Swing.Text.Outline)

			self.Swing.TextMH:SetPoint("BOTTOM", self.Swing.Text, "CENTER", 0, 1)
			self.Swing.TextOH:SetPoint("TOP", self.Swing.Text, "CENTER", 0, -1)

			self.Swing.OverrideText = SwingOverrideText
		end

		self.Swing:SetWidth(tonumber(oufdb.Swing.Width))
		self.Swing:SetHeight(tonumber(oufdb.Swing.Height))
		self.Swing:ClearAllPoints()
		self.Swing:SetPoint("BOTTOM", UIParent, "BOTTOM", tonumber(oufdb.Swing.X), tonumber(oufdb.Swing.Y))

		self.Swing.texture = LSM:Fetch("statusbar", oufdb.Swing.Texture)
		self.Swing.textureBG = LSM:Fetch("statusbar", oufdb.Swing.TextureBG)

		local mu = oufdb.Swing.BGMultiplier
		if oufdb.Swing.Color == "By Class" then
			local color = colors.class[class]
			self.Swing.color = {color[1], color[2], color[3], 1}
			self.Swing.colorBG = {color[1]*mu, color[2]*mu, color[3]*mu, 1}
		else
			self.Swing.color = {oufdb.Swing.IndividualColor.r, oufdb.Swing.IndividualColor.g, oufdb.Swing.IndividualColor.b, 1}
			self.Swing.colorBG = {oufdb.Swing.IndividualColor.r*mu, oufdb.Swing.IndividualColor.g*mu, oufdb.Swing.IndividualColor.b*mu, 1}
		end

		if self.Swing.Twohand then
			self.Swing.Twohand:SetStatusBarTexture(LSM:Fetch("statusbar", oufdb.Swing.Texture))
			self.Swing.Twohand:SetStatusBarColor(unpack(self.Swing.color))
			self.Swing.Twohand.bg:SetTexture(LSM:Fetch("statusbar", oufdb.Swing.TextureBG))
			self.Swing.Twohand.bg:SetVertexColor(unpack(self.Swing.colorBG))
		end
		if self.Swing.Mainhand then
			self.Swing.Mainhand:SetStatusBarTexture(LSM:Fetch("statusbar", oufdb.Swing.Texture))
			self.Swing.Mainhand:SetStatusBarColor(unpack(self.Swing.color))
			self.Swing.Mainhand.bg:SetTexture(LSM:Fetch("statusbar", oufdb.Swing.TextureBG))
			self.Swing.Mainhand.bg:SetVertexColor(unpack(self.Swing.colorBG))
		end
		if self.Swing.Offhand then
			self.Swing.Offhand:SetStatusBarTexture(LSM:Fetch("statusbar", oufdb.Swing.Texture))
			self.Swing.Offhand:SetStatusBarColor(unpack(self.Swing.color))
			self.Swing.Offhand.bg:SetTexture(LSM:Fetch("statusbar", oufdb.Swing.TextureBG))
			self.Swing.Offhand.bg:SetVertexColor(unpack(self.Swing.colorBG))
		end

		self.Swing.Text:SetFont(LSM:Fetch("font", oufdb.Swing.Text.Font), oufdb.Swing.Text.Size, oufdb.Swing.Text.Outline)
		self.Swing.TextMH:SetFont(LSM:Fetch("font", oufdb.Swing.Text.Font), oufdb.Swing.Text.Size, oufdb.Swing.Text.Outline)
		self.Swing.TextOH:SetFont(LSM:Fetch("font", oufdb.Swing.Text.Font), oufdb.Swing.Text.Size, oufdb.Swing.Text.Outline)

		self.Swing.Text:ClearAllPoints()
		self.Swing.Text:SetPoint("CENTER", self.Swing, "CENTER", tonumber(oufdb.Swing.Text.X), tonumber(oufdb.Swing.Text.Y))

		if oufdb.Swing.Text.Color == "By Class" then
			local color = colors.class[class]
			self.Swing.Text:SetTextColor(color[1], color[2], color[3])
			self.Swing.TextMH:SetTextColor(color[1], color[2], color[3])
			self.Swing.TextOH:SetTextColor(color[1], color[2], color[3])
		else
			self.Swing.Text:SetTextColor(oufdb.Swing.Text.IndividualColor.r, oufdb.Swing.Text.IndividualColor.g, oufdb.Swing.Text.IndividualColor.b)
			self.Swing.TextMH:SetTextColor(oufdb.Swing.Text.IndividualColor.r, oufdb.Swing.Text.IndividualColor.g, oufdb.Swing.Text.IndividualColor.b)
			self.Swing.TextOH:SetTextColor(oufdb.Swing.Text.IndividualColor.r, oufdb.Swing.Text.IndividualColor.g, oufdb.Swing.Text.IndividualColor.b)
		end

		if oufdb.Swing.Text.Enable then
			self.Swing.Text:Show()
			self.Swing.TextMH:Show()
			self.Swing.TextOH:Show()
		else
			self.Swing.Text:Hide()
			self.Swing.TextMH:Hide()
			self.Swing.TextOH:Hide()
		end

		self.Swing.Text.Enable = oufdb.Swing.Text.Enable
		self.Swing.Text.Format = oufdb.Swing.Text.Format

		self.Swing.TextMH.Enable = oufdb.Swing.Text.Enable
		self.Swing.TextMH.Format = oufdb.Swing.Text.Format

		self.Swing.TextOH.Enable = oufdb.Swing.Text.Enable
		self.Swing.TextOH.Format = oufdb.Swing.Text.Format
	end,
	Vengeance = function(self, unit, oufdb)
		if not self.Vengeance then
			self.Vengeance = CreateFrame("StatusBar", nil, UIParent)
			self.Vengeance.bg = self.Vengeance:CreateTexture(nil, "BORDER")
			self.Vengeance.bg:SetAllPoints(self.Vengeance)

			self.Vengeance.Text = SetFontString(self.Vengeance, LSM:Fetch("font", oufdb.Vengeance.Text.Font), oufdb.Vengeance.Text.Size, oufdb.Vengeance.Text.Outline)
			self.Vengeance.OverrideText = VengeanceOverrideText
		end
		
		self.Vengeance.showInfight = true
		
		self.Vengeance:SetWidth(tonumber(oufdb.Vengeance.Width))
		self.Vengeance:SetHeight(tonumber(oufdb.Vengeance.Height))
		self.Vengeance:ClearAllPoints()
		self.Vengeance:SetPoint("BOTTOM", UIParent, "BOTTOM", tonumber(oufdb.Vengeance.X), tonumber(oufdb.Vengeance.Y))
		self.Vengeance:SetStatusBarTexture(LSM:Fetch("statusbar", oufdb.Vengeance.Texture))
		self.Vengeance.bg:SetTexture(LSM:Fetch("statusbar", oufdb.Vengeance.TextureBG))

		local mu = oufdb.Vengeance.BGMultiplier
		if oufdb.Vengeance.Color == "By Class" then
			local color = colors.class[class]
			self.Vengeance:SetStatusBarColor(color[1], color[2], color[3], 1)
			self.Vengeance.bg:SetVertexColor(color[1]*mu, color[2]*mu, color[3]*mu, 1)
		else
			self.Vengeance:SetStatusBarColor(oufdb.Vengeance.IndividualColor.r, oufdb.Vengeance.IndividualColor.g, oufdb.Vengeance.IndividualColor.b, 1)
			self.Vengeance.bg:SetVertexColor(oufdb.Vengeance.IndividualColor.r*mu, oufdb.Vengeance.IndividualColor.g*mu, oufdb.Vengeance.IndividualColor.b*mu, 1)
		end

		self.Vengeance.Text:SetFont(LSM:Fetch("font", oufdb.Vengeance.Text.Font), oufdb.Vengeance.Text.Size, oufdb.Vengeance.Text.Outline)
		self.Vengeance.Text:ClearAllPoints()
		self.Vengeance.Text:SetPoint("CENTER", self.Vengeance, "CENTER", tonumber(oufdb.Vengeance.Text.X), tonumber(oufdb.Vengeance.Text.Y))

		if oufdb.Vengeance.Text.Enable then
			self.Vengeance.Text:Show()
		else
			self.Vengeance.Text:Hide()
		end
	end,
	ThreatBar = function(self, unit, oufdb)
		if not self.ThreatBar then
			self.ThreatBar = CreateFrame("StatusBar", nil, UIParent)
			self.ThreatBar.bg = self.ThreatBar:CreateTexture(nil, "BORDER")
			self.ThreatBar.bg:SetAllPoints(self.ThreatBar)
			
			self.ThreatBar.Text = SetFontString(self.ThreatBar, LSM:Fetch("font", oufdb.ThreatBar.Text.Font), oufdb.ThreatBar.Text.Size, oufdb.ThreatBar.Text.Outline)
		end
		
		self.ThreatBar:SetWidth(tonumber(oufdb.ThreatBar.Width))
		self.ThreatBar:SetHeight(tonumber(oufdb.ThreatBar.Height))
		self.ThreatBar:ClearAllPoints()
		self.ThreatBar:SetPoint("BOTTOM", UIParent, "BOTTOM", tonumber(oufdb.ThreatBar.X), tonumber(oufdb.ThreatBar.Y))
		self.ThreatBar:SetStatusBarTexture(LSM:Fetch("statusbar", oufdb.ThreatBar.Texture))
		self.ThreatBar.bg:SetTexture(LSM:Fetch("statusbar", oufdb.ThreatBar.TextureBG))
		
		self.ThreatBar.BGMultiplier = oufdb.ThreatBar.BGMultiplier
		
		local mu = self.ThreatBar.BGMultiplier
		if oufdb.ThreatBar.Color == "By Class" then
			local color = colors.class[class]
			self.ThreatBar:SetStatusBarColor(color[1], color[2], color[3], 1)
			self.ThreatBar.bg:SetVertexColor(color[1]*mu, color[2]*mu, color[3]*mu, 1)
		elseif oufdb.ThreatBar.Color == "Individual" then
			self.ThreatBar:SetStatusBarColor(oufdb.ThreatBar.IndividualColor.r, oufdb.ThreatBar.IndividualColor.g, oufdb.ThreatBar.IndividualColor.b, 0.8)
			self.ThreatBar.bg:SetVertexColor(oufdb.ThreatBar.IndividualColor.r*mu, oufdb.ThreatBar.IndividualColor.g*mu, oufdb.ThreatBar.IndividualColor.b*mu, 1)
		end
		self.ThreatBar.colorGradient = (oufdb.ThreatBar.Color == "Gradient")
		self.ThreatBar.tankHide = oufdb.ThreatBar.TankHide
		
		self.ThreatBar.Text:SetFont(LSM:Fetch("font", oufdb.ThreatBar.Text.Font), oufdb.ThreatBar.Text.Size, oufdb.ThreatBar.Text.Outline)
		self.ThreatBar.Text:ClearAllPoints()
		self.ThreatBar.Text:SetPoint("CENTER", self.ThreatBar, "CENTER", tonumber(oufdb.ThreatBar.Text.X), tonumber(oufdb.ThreatBar.Text.Y))

		if oufdb.ThreatBar.Text.Enable then
			self.ThreatBar.Text:Show()
		else
			self.ThreatBar.Text:Hide()
		end
	end,
	TotemBar = function(self, unit, oufdb)
		if not self.TotemBar then
			self.TotemBar = CreateFrame("Frame", nil, self)
			self.TotemBar:SetFrameLevel(6)
			self.TotemBar.Destroy = true

			for i = 1, 4 do
				self.TotemBar[i] = CreateFrame("StatusBar", nil, self.TotemBar)
				self.TotemBar[i]:SetBackdrop(backdrop)
				self.TotemBar[i]:SetBackdropColor(0, 0, 0)
				self.TotemBar[i]:SetMinMaxValues(0, 1)

				self.TotemBar[i].bg = self.TotemBar[i]:CreateTexture(nil, "BORDER")
				self.TotemBar[i].bg:SetAllPoints(self.TotemBar[i])
				self.TotemBar[i].bg:SetTexture(normTex)
			end

			self.TotemBar.FrameBackdrop = CreateFrame("Frame", nil, self.TotemBar)
			self.TotemBar.FrameBackdrop:SetPoint("TOPLEFT", self.TotemBar, "TOPLEFT", -3.5, 3)
			self.TotemBar.FrameBackdrop:SetPoint("BOTTOMRIGHT", self.TotemBar, "BOTTOMRIGHT", 3.5, -3)
			self.TotemBar.FrameBackdrop:SetFrameStrata("BACKGROUND")
			self.TotemBar.FrameBackdrop:SetBackdrop({
				edgeFile = glowTex, edgeSize = 5,
				insets = {left = 3, right = 3, top = 3, bottom = 3}
			})
			self.TotemBar.FrameBackdrop:SetBackdropColor(0, 0, 0, 0)
			self.TotemBar.FrameBackdrop:SetBackdropBorderColor(0, 0, 0)
		end

		local x = oufdb.Totems.Lock and 0 or oufdb.Totems.X
		local y = oufdb.Totems.Lock and 0.5 or oufdb.Totems.Y

		self.TotemBar:SetHeight(oufdb.Totems.Height)
		self.TotemBar:SetWidth(oufdb.Totems.Width)
		self.TotemBar:ClearAllPoints()
		self.TotemBar:SetPoint("BOTTOMLEFT", self, "TOPLEFT", x, y)
		self.TotemBar.colors = colors.totembar
		
		local totemPoints = {2,0,1,3}
		
		for i = 1, 4 do
			self.TotemBar[i]:SetStatusBarTexture(LSM:Fetch("statusbar", oufdb.Totems.Texture))
			self.TotemBar[i]:SetHeight(oufdb.Totems.Height)
			self.TotemBar[i]:SetWidth((tonumber(oufdb.Totems.Width) -3*oufdb.Totems.Padding) / 4)

			self.TotemBar[i]:ClearAllPoints()
			if totemPoints[i] == 0 then
				self.TotemBar[i]:SetPoint("LEFT", self.TotemBar, "LEFT", 0, 0)
			else
				self.TotemBar[i]:SetPoint("LEFT", self.TotemBar[totemPoints[i]], "RIGHT", oufdb.Totems.Padding, 0)
			end
			
			self.TotemBar[i].bg.multiplier = tonumber(oufdb.Totems.Multiplier)
		end
	end,
	Runes = function(self, unit, oufdb)
		if not self.Runes then
			self.Runes = CreateFrame("Frame", nil, self)
			self.Runes:SetFrameLevel(6)

			for i = 1, 6 do
				self.Runes[i] = CreateFrame("StatusBar", nil, self.Runes)
				self.Runes[i]:SetBackdrop(backdrop)
				self.Runes[i]:SetBackdropColor(0.08, 0.08, 0.08)
			end

			self.Runes.FrameBackdrop = CreateFrame("Frame", nil, self.Runes)
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

		local x = oufdb.Runes.Lock and 0 or oufdb.Runes.X
		local y = oufdb.Runes.Lock and 0.5 or oufdb.Runes.Y

		self.Runes:SetHeight(oufdb.Runes.Height)
		self.Runes:SetWidth(oufdb.Runes.Width)
		self.Runes:ClearAllPoints()
		self.Runes:SetPoint("BOTTOMLEFT", self, "TOPLEFT", x, y)
		
		local runePoints = {0,1,6,3,2,5}
		
		for i = 1, 6 do
			self.Runes[i]:SetStatusBarTexture(LSM:Fetch("statusbar", oufdb.Runes.Texture))
			self.Runes[i]:SetStatusBarColor(unpack(colors.runes[math.floor((i+1)/2)]))
			self.Runes[i]:SetSize(((oufdb.Runes.Width - 5*oufdb.Runes.Padding) / 6), oufdb.Runes.Height)

			self.Runes[i]:ClearAllPoints()
			if runePoints[i] == 0 then
				self.Runes[i]:SetPoint("LEFT", self.Runes, "LEFT", 0, 0)
			else
				self.Runes[i]:SetPoint("LEFT", self.Runes[runePoints[i]], "RIGHT", oufdb.Runes.Padding, 0)
			end
		end
	end,
	HolyPower = function(self, unit, oufdb)
		if not self.HolyPower then
			self.HolyPower = CreateFrame("Frame", nil, self)
			self.HolyPower:SetFrameLevel(6)

			for i = 1, 3 do
				self.HolyPower[i] = CreateFrame("StatusBar", nil, self.HolyPower)
				self.HolyPower[i]:SetBackdrop(backdrop)
				self.HolyPower[i]:SetBackdropColor(0.08, 0.08, 0.08)
				self.HolyPower[i]:SetAlpha(.4)
			end

			self.HolyPower.FrameBackdrop = CreateFrame("Frame", nil, self.HolyPower)
			self.HolyPower.FrameBackdrop:SetPoint("TOPLEFT", self.HolyPower, "TOPLEFT", -3.5, 3)
			self.HolyPower.FrameBackdrop:SetPoint("BOTTOMRIGHT", self.HolyPower, "BOTTOMRIGHT", 3.5, -3)
			self.HolyPower.FrameBackdrop:SetFrameStrata("BACKGROUND")
			self.HolyPower.FrameBackdrop:SetBackdrop({
				edgeFile = glowTex, edgeSize = 5,
				insets = {left = 3, right = 3, top = 3, bottom = 3}
			})
			self.HolyPower.FrameBackdrop:SetBackdropColor(0, 0, 0, 0)
			self.HolyPower.FrameBackdrop:SetBackdropBorderColor(0, 0, 0)

			self.HolyPower.Override = HolyPowerOverride
		end

		local x = oufdb.HolyPower.Lock and 0 or oufdb.HolyPower.X
		local y = oufdb.HolyPower.Lock and 0.5 or oufdb.HolyPower.Y

		self.HolyPower:SetHeight(tonumber(oufdb.HolyPower.Height))
		self.HolyPower:SetWidth(tonumber(oufdb.HolyPower.Width))
		self.HolyPower:ClearAllPoints()
		self.HolyPower:SetPoint("BOTTOMLEFT", self, "TOPLEFT", x, y)

		for i = 1, 3 do
			self.HolyPower[i]:SetStatusBarTexture(LSM:Fetch("statusbar", oufdb.HolyPower.Texture))
			self.HolyPower[i]:SetStatusBarColor(unpack(colors.holypowerbar[i]))
			self.HolyPower[i]:SetSize(((oufdb.HolyPower.Width - 2*oufdb.HolyPower.Padding) / 3), oufdb.HolyPower.Height)

			self.HolyPower[i]:ClearAllPoints()
			if i == 1 then
				self.HolyPower[i]:SetPoint("LEFT", self.HolyPower, "LEFT", 0, 0)
			else
				self.HolyPower[i]:SetPoint("LEFT", self.HolyPower[i-1], "RIGHT", oufdb.HolyPower.Padding, 0)
			end
		end
	end,
	SoulShards = function(self, unit, oufdb)
		if not self.SoulShards then
			self.SoulShards = CreateFrame("Frame", nil, self)
			self.SoulShards:SetFrameLevel(6)

			for i = 1, 3 do
				self.SoulShards[i] = CreateFrame("StatusBar", nil, self.SoulShards)
				self.SoulShards[i]:SetBackdrop(backdrop)
				self.SoulShards[i]:SetBackdropColor(0.08, 0.08, 0.08)

				self.SoulShards[i]:SetAlpha(.4)
			end

			self.SoulShards.FrameBackdrop = CreateFrame("Frame", nil, self.SoulShards)
			self.SoulShards.FrameBackdrop:SetPoint("TOPLEFT", self.SoulShards, "TOPLEFT", -3.5, 3)
			self.SoulShards.FrameBackdrop:SetPoint("BOTTOMRIGHT", self.SoulShards, "BOTTOMRIGHT", 3.5, -3)
			self.SoulShards.FrameBackdrop:SetFrameStrata("BACKGROUND")
			self.SoulShards.FrameBackdrop:SetBackdrop({
				edgeFile = glowTex, edgeSize = 5,
				insets = {left = 3, right = 3, top = 3, bottom = 3}
			})
			self.SoulShards.FrameBackdrop:SetBackdropColor(0, 0, 0, 0)
			self.SoulShards.FrameBackdrop:SetBackdropBorderColor(0, 0, 0)

			self.SoulShards.Override = SoulShardsOverride
		end

		local x = oufdb.SoulShards.Lock and 0 or oufdb.SoulShards.X
		local y = oufdb.SoulShards.Lock and 0.5 or oufdb.SoulShards.Y

		self.SoulShards:SetHeight(tonumber(oufdb.SoulShards.Height))
		self.SoulShards:SetWidth(tonumber(oufdb.SoulShards.Width))
		self.SoulShards:ClearAllPoints()
		self.SoulShards:SetPoint("BOTTOMLEFT", self, "TOPLEFT", x, y)

		for i = 1, 3 do
			self.SoulShards[i]:SetStatusBarTexture(LSM:Fetch("statusbar", oufdb.SoulShards.Texture))
			self.SoulShards[i]:SetStatusBarColor(unpack(colors.soulshardbar[i]))
			self.SoulShards[i]:SetSize(((oufdb.SoulShards.Width - 2*oufdb.SoulShards.Padding) / 3), oufdb.SoulShards.Height)

			self.SoulShards[i]:ClearAllPoints()
			if i == 1 then
				self.SoulShards[i]:SetPoint("LEFT", self.SoulShards, "LEFT", 0, 0)
			else
				self.SoulShards[i]:SetPoint("LEFT", self.SoulShards[i-1], "RIGHT", oufdb.SoulShards.Padding, 0)
			end
		end
	end,
	EclipseBar = function(self, unit, oufdb)
		if not self.EclipseBar then
			self.EclipseBar = CreateFrame("Frame", nil, self)
			self.EclipseBar:SetFrameLevel(6)
			self.EclipseBar.ShowText = oufdb.Eclipse.Text.Enable
			self.EclipseBar.PostUnitAura = EclipseBarBuff
			self.EclipseBar.PostUpdatePower = PostEclipseUpdate
			self.EclipseBar.PostUpdateVisibility = function() LUI:GetModule("Forte"):SetPosForte() end

			self.EclipseBar.LunarBar = CreateFrame("StatusBar", nil, self.EclipseBar)
			self.EclipseBar.LunarBar:SetAllPoints(self.EclipseBar)

			self.EclipseBar.SolarBar = CreateFrame("StatusBar", nil, self.EclipseBar)
			self.EclipseBar.SolarBar:SetPoint("TOPLEFT", self.EclipseBar.LunarBar:GetStatusBarTexture(), "TOPRIGHT")
			self.EclipseBar.SolarBar:SetPoint("BOTTOMLEFT", self.EclipseBar.LunarBar:GetStatusBarTexture(), "BOTTOMRIGHT")

			self.EclipseBar.spark = self.EclipseBar:CreateTexture(nil, "OVERLAY")
			self.EclipseBar.spark:SetPoint("TOP", self.EclipseBar, "TOP")
			self.EclipseBar.spark:SetPoint("BOTTOM", self.EclipseBar, "BOTTOM")
			self.EclipseBar.spark:SetWidth(2)
			self.EclipseBar.spark:SetTexture(1,1,1,1)

			self.EclipseBar.FrameBackdrop = CreateFrame("Frame", nil, self.EclipseBar)
			self.EclipseBar.FrameBackdrop:SetPoint("TOPLEFT", self.EclipseBar, "TOPLEFT", -3.5, 3)
			self.EclipseBar.FrameBackdrop:SetPoint("BOTTOMRIGHT", self.EclipseBar, "BOTTOMRIGHT", 3.5, -3)
			self.EclipseBar.FrameBackdrop:SetFrameStrata("BACKGROUND")
			self.EclipseBar.FrameBackdrop:SetBackdrop({
				edgeFile = glowTex, edgeSize = 5,
				insets = {left = 3, right = 3, top = 3, bottom = 3}
			})
			self.EclipseBar.FrameBackdrop:SetBackdropColor(0, 0, 0, 1)
			self.EclipseBar.FrameBackdrop:SetBackdropBorderColor(0, 0, 0)

			self.EclipseBar.LunarText = SetFontString(self.EclipseBar.LunarBar, LSM:Fetch("font", oufdb.Eclipse.Text.Font), tonumber(oufdb.Eclipse.Text.Size), oufdb.Eclipse.Text.Outline)
			self.EclipseBar.SolarText = SetFontString(self.EclipseBar.SolarBar, LSM:Fetch("font", oufdb.Eclipse.Text.Font), tonumber(oufdb.Eclipse.Text.Size), oufdb.Eclipse.Text.Outline)
		end

		local x = oufdb.Eclipse.Lock and 0 or oufdb.Eclipse.X
		local y = oufdb.Eclipse.Lock and 0.5 or oufdb.Eclipse.Y

		self.EclipseBar:SetHeight(oufdb.Eclipse.Height)
		self.EclipseBar:SetWidth(oufdb.Eclipse.Width)
		self.EclipseBar:ClearAllPoints()
		self.EclipseBar:SetPoint("BOTTOMLEFT", self, "TOPLEFT", x, y)

		self.EclipseBar.LunarBar:SetStatusBarTexture(LSM:Fetch("statusbar", oufdb.Eclipse.Texture))
		self.EclipseBar.LunarBar:SetStatusBarColor(unpack(colors.eclipsebar["Lunar"]))

		self.EclipseBar.SolarBar:SetWidth(oufdb.Eclipse.Width)
		self.EclipseBar.SolarBar:SetStatusBarTexture(LSM:Fetch("statusbar", oufdb.Eclipse.Texture))
		self.EclipseBar.SolarBar:SetStatusBarColor(unpack(colors.eclipsebar["Solar"]))

		self.EclipseBar.LunarText:SetFont( LSM:Fetch("font", oufdb.Eclipse.Text.Font), tonumber(oufdb.Eclipse.Text.Size), oufdb.Eclipse.Text.Outline)
		self.EclipseBar.LunarText:ClearAllPoints()
		self.EclipseBar.LunarText:SetPoint("LEFT", self.EclipseBar, "LEFT", tonumber(oufdb.Eclipse.Text.X), tonumber(oufdb.Eclipse.Text.Y))

		self.EclipseBar.SolarText:SetFont(LSM:Fetch("font", oufdb.Eclipse.Text.Font), tonumber(oufdb.Eclipse.Text.Size), oufdb.Eclipse.Text.Outline)
		self.EclipseBar.SolarText:ClearAllPoints()
		self.EclipseBar.SolarText:SetPoint("RIGHT", self.EclipseBar, "RIGHT", -tonumber(oufdb.Eclipse.Text.X), tonumber(oufdb.Eclipse.Text.Y))

		if oufdb.Eclipse.Text.Enable == true then
			self.EclipseBar.LunarText:Show()
			self.EclipseBar.SolarText:Show()
		else
			self.EclipseBar.LunarText:Hide()
			self.EclipseBar.SolarText:Hide()
		end
	end,

	AltPowerBar = function(self, unit, oufdb)
		if not self.AltPowerBar then
			self.AltPowerBar = CreateFrame("StatusBar", nil, self)
			if unit == "pet" then self.AltPowerBar:SetParent(oUF_LUI_player) end
			
			self.AltPowerBar.bg = self.AltPowerBar:CreateTexture(nil, "BORDER")
			self.AltPowerBar.bg:SetAllPoints(self.AltPowerBar)
			
			self.AltPowerBar.SetPosition = function()
				if not db.oUF.Player.AltPower.OverPower then return end
				
				if oUF_LUI_player.AltPowerBar:IsShown() or (oUF_LUI_pet and oUF_LUI_pet.AltPowerBar and oUF_LUI_pet.AltPowerBar:IsShown()) then
					oUF_LUI_player.Power:SetHeight(tonumber(db.oUF.Player.Power.Height)/2 - 1)
					oUF_LUI_player.AltPowerBar:SetHeight(tonumber(db.oUF.Player.Power.Height)/2 - 1)
				else
					oUF_LUI_player.Power:SetHeight(tonumber(db.oUF.Player.Power.Height))
					oUF_LUI_player.AltPowerBar:SetHeight(tonumber(db.oUF.Player.AltPower.Height))
				end
			end

			self.AltPowerBar:SetScript("OnShow", function()
				self.AltPowerBar.SetPosition()
				self.AltPowerBar:ForceUpdate()
			end)
			self.AltPowerBar:SetScript("OnHide", self.AltPowerBar.SetPosition)

			self.AltPowerBar.Text = SetFontString(self.AltPowerBar, LSM:Fetch("font", db.oUF.Player.AltPower.Text.Font), db.oUF.Player.AltPower.Text.Size, db.oUF.Player.AltPower.Text.Outline)
		end

		self.AltPowerBar:ClearAllPoints()
		if unit == "player" then
			if db.oUF.Player.AltPower.OverPower then
				self.AltPowerBar:SetPoint("TOPLEFT", self.Power, "BOTTOMLEFT", 0, -2)
				self.AltPowerBar:SetPoint("TOPRIGHT", self.Power, "BOTTOMRIGHT", 0, -2)
			else
				self.AltPowerBar:SetPoint("TOPLEFT", self, "TOPLEFT", tonumber(db.oUF.Player.AltPower.X), tonumber(db.oUF.Player.AltPower.Y))
			end
		else
			self.AltPowerBar:SetPoint("TOPLEFT", oUF_LUI_player.AltPowerBar, "TOPLEFT", 0, 0)
			self.AltPowerBar:SetPoint("BOTTOMRIGHT", oUF_LUI_player.AltPowerBar, "BOTTOMRIGHT", 0, 0)
		end
		
		self.AltPowerBar:SetHeight(tonumber(db.oUF.Player.AltPower.Height))
		self.AltPowerBar:SetWidth(tonumber(db.oUF.Player.AltPower.Width))
		self.AltPowerBar:SetStatusBarTexture(LSM:Fetch("statusbar", db.oUF.Player.AltPower.Texture))

		self.AltPowerBar.bg:SetTexture(LSM:Fetch("statusbar", db.oUF.Player.AltPower.TextureBG))
		self.AltPowerBar.bg:SetAlpha(db.oUF.Player.AltPower.BGAlpha)
		self.AltPowerBar.bg.multiplier = db.oUF.Player.AltPower.BGMultiplier
		
		self.AltPowerBar.Smooth = db.oUF.Player.AltPower.Smooth
		self.AltPowerBar.color = db.oUF.Player.AltPower.Color
		self.AltPowerBar.colorIndividual = db.oUF.Player.AltPower.IndividualColor

		self.AltPowerBar.Text:SetFont(LSM:Fetch("font", db.oUF.Player.AltPower.Text.Font), db.oUF.Player.AltPower.Text.Size, db.oUF.Player.AltPower.Text.Outline)
		self.AltPowerBar.Text:ClearAllPoints()
		self.AltPowerBar.Text:SetPoint("CENTER", self.AltPowerBar, "CENTER", tonumber(db.oUF.Player.AltPower.Text.X), tonumber(db.oUF.Player.AltPower.Text.Y))

		self.AltPowerBar.Text.Enable = db.oUF.Player.AltPower.Text.Enable
		self.AltPowerBar.Text.Format = db.oUF.Player.AltPower.Text.Format
		self.AltPowerBar.Text.color = db.oUF.Player.AltPower.Text.Color
		self.AltPowerBar.Text.colorIndividual = db.oUF.Player.AltPower.Text.IndividualColor

		if db.oUF.Player.AltPower.Text.Enable then
			self.AltPowerBar.Text:Show()
		else
			self.AltPowerBar.Text:Hide()
		end

		self.AltPowerBar.PostUpdate = PostUpdateAltPower
		
		self.AltPowerBar.SetPosition()
	end,
	DruidMana = function(self, unit, oufdb)
		if not self.DruidMana then
			self.DruidMana = CreateFrame("Frame", nil, self)
			self.DruidMana:SetFrameLevel(self.Power:GetFrameLevel()-1)
			self.DruidMana:Hide()

			self.DruidMana.ManaBar = CreateFrame("StatusBar", nil, self.DruidMana)
			self.DruidMana.ManaBar:SetAllPoints(self.DruidMana)

			self.DruidMana.bg = self.DruidMana:CreateTexture(nil, "BORDER")
			self.DruidMana.bg:SetAllPoints(self.DruidMana)

			self.DruidMana.Smooth = oufdb.DruidMana.Smooth

			self.DruidMana.value = SetFontString(self.DruidMana.ManaBar, LSM:Fetch("font", oufdb.Texts.DruidMana.Font), oufdb.Texts.DruidMana.Size, oufdb.Texts.DruidMana.Outline)
			self:Tag(self.DruidMana.value, "[druidmana2]")

			self.DruidMana.SetPosition = function()
				if not oufdb.DruidMana.OverPower then return end
				
				if self.DruidMana:IsShown() then
					self.Power:SetHeight(tonumber(oufdb.Power.Height)/2 - 1)
					self.DruidMana:SetHeight(tonumber(oufdb.Power.Height)/2 - 1)
				else
					self.Power:SetHeight(tonumber(oufdb.Power.Height))
					self.DruidMana:SetHeight(tonumber(oufdb.DruidMana.Height))
				end
			end

			self.DruidMana:SetScript("OnShow", self.DruidMana.SetPosition)
			self.DruidMana:SetScript("OnHide", self.DruidMana.SetPosition)

			self.DruidMana.PostUpdatePower = PostUpdateDruidMana
		end

		self.DruidMana:ClearAllPoints()
		if oufdb.DruidMana.OverPower then
			self.DruidMana:SetPoint("TOPLEFT", self.Power, "BOTTOMLEFT", 0, -2)
			self.DruidMana:SetPoint("TOPRIGHT", self.Power, "BOTTOMRIGHT", 0, -2)
		else
			self.DruidMana:SetPoint("TOPLEFT", self, "TOPLEFT", tonumber(db.oUF.Player.DruidMana.X), tonumber(db.oUF.Player.DruidMana.Y))
		end
		
		self.DruidMana:SetHeight(tonumber(oufdb.DruidMana.Height))
		self.DruidMana:SetWidth(tonumber(oufdb.DruidMana.Width))
		self.DruidMana.ManaBar:SetStatusBarTexture(LSM:Fetch("statusbar", oufdb.DruidMana.Texture))

		self.DruidMana.value:SetFont(LSM:Fetch("font", oufdb.Texts.DruidMana.Font), oufdb.Texts.DruidMana.Size, oufdb.Texts.DruidMana.Outline)
		self.DruidMana.value:SetPoint("CENTER", self.DruidMana.ManaBar, "CENTER")

		if db.oUF.Player.Texts.DruidMana.Enable == true then
			self.DruidMana.value:Show()
		else
			self.DruidMana.value:Hide()
		end

		self.DruidMana.color = oufdb.DruidMana.Color

		self.DruidMana.bg:SetTexture(LSM:Fetch("statusbar", oufdb.DruidMana.TextureBG))
		self.DruidMana.bg:SetAlpha(oufdb.DruidMana.BGAlpha)
		self.DruidMana.bg.multiplier = oufdb.DruidMana.BGMultiplier

		if GetShapeshiftFormID() == CAT_FORM or GetShapeshiftFormID() == BEAR_FORM then self.DruidMana.SetPosition() end
	end,
	
	-- target specific
	CPoints = function(self, unit, oufdb)
		if not self.CPoints then
			self.CPoints = CreateFrame("Frame", nil, self)

			for i = 1, 5 do
				self.CPoints[i] = CreateFrame("StatusBar", nil, self.CPoints)
				self.CPoints[i]:SetBackdrop(backdrop)
				self.CPoints[i]:SetBackdropColor(0, 0, 0)
				self.CPoints[i]:SetMinMaxValues(0, 1)

				self.CPoints[i].bg = self.CPoints[i]:CreateTexture(nil, "BORDER")
				self.CPoints[i].bg:SetAllPoints(self.CPoints[i])
			end

			--self.CPoints[1]:SetScript("OnShow", function() LUI:GetModule("Forte"):SetPosForte() end)
			--self.CPoints[1]:SetScript("OnHide", function() LUI:GetModule("Forte"):SetPosForte() end)

			self.CPoints.FrameBackdrop = CreateFrame("Frame", nil, self.CPoints)
			self.CPoints.FrameBackdrop:SetPoint("TOPLEFT", self.CPoints, "TOPLEFT", -3, 3)
			self.CPoints.FrameBackdrop:SetPoint("BOTTOMRIGHT", self.CPoints, "BOTTOMRIGHT", 3, -3)
			self.CPoints.FrameBackdrop:SetFrameStrata("BACKGROUND")
			self.CPoints.FrameBackdrop:SetBackdrop({
				edgeFile = glowTex, edgeSize = 4,
				insets = {left = 3, right = 3, top = 3, bottom = 3}
			})
			self.CPoints.FrameBackdrop:SetBackdropColor(0, 0, 0, 0)
			self.CPoints.FrameBackdrop:SetBackdropBorderColor(0, 0, 0)

			self.CPoints.Override = CPointsOverride
		end

		self.CPoints:ClearAllPoints()
		self.CPoints:SetPoint("BOTTOMLEFT", self, "TOPLEFT", oufdb.ComboPoints.X, oufdb.ComboPoints.Y)
		self.CPoints:SetHeight(oufdb.ComboPoints.Height)
		self.CPoints:SetWidth(oufdb.ComboPoints.Width)
		self.CPoints.showAlways = oufdb.ComboPoints.ShowAlways

		for i = 1, 5 do
			self.CPoints[i]:ClearAllPoints()
			if i == 1 then
				self.CPoints[i]:SetPoint("LEFT", self.CPoints, "LEFT", 0, 0)
			else
				self.CPoints[i]:SetPoint("LEFT", self.CPoints[i-1], "RIGHT", 1, 0)
			end

			self.CPoints[i]:SetStatusBarTexture(LSM:Fetch("statusbar", oufdb.ComboPoints.Texture))
			self.CPoints[i]:SetStatusBarColor(unpack(colors.combopoints[i]))
			self.CPoints[i]:SetHeight(oufdb.ComboPoints.Height)
			self.CPoints[i]:SetWidth((tonumber(oufdb.ComboPoints.Width) -4*oufdb.ComboPoints.Padding) / 5)

			self.CPoints[i].bg:SetTexture(LSM:Fetch("statusbar", oufdb.ComboPoints.Texture))
			self.CPoints[i].bg.multiplier = tonumber(oufdb.ComboPoints.Multiplier)

			if oufdb.ComboPoints.BackgroundColor.Enable == true then
				self.CPoints[i].bg:SetVertexColor(oufdb.ComboPoints.BackgroundColor.r, oufdb.ComboPoints.BackgroundColor.g, oufdb.ComboPoints.BackgroundColor.b)
			else
				local mu = tonumber(oufdb.ComboPoints.Multiplier)
				local r, g, b = self.CPoints[i]:GetStatusBarColor()
				self.CPoints[i].bg:SetVertexColor(r*mu, g*mu, b*mu)
			end
		end
	end,

	-- raid specific
	SingleAuras = function(self, unit, oufdb)
		if not cornerAuras[class] then return end
		if not self.SingleAuras then self.SingleAuras = {} end

		for k, data in pairs(cornerAuras[class]) do
			local spellId, onlyPlayer, isDebuff = unpack(data)
			local spellName = GetSpellInfo(spellId)
			
			local x = k:find("RIGHT") and -tonumber(oufdb.CornerAura.Inset) or tonumber(oufdb.CornerAura.Inset)
			local y = k:find("TOP") and -tonumber(oufdb.CornerAura.Inset) or tonumber(oufdb.CornerAura.Inset)

			if not self.SingleAuras[k] then
				self.SingleAuras[k] = CreateFrame("Frame", nil, self)
				self.SingleAuras[k]:SetFrameLevel(7)
			end
			
			self.SingleAuras[k].spellName = spellName
			self.SingleAuras[k].onlyPlayer = onlyPlayer
			self.SingleAuras[k].isDebuff = isDebuff
			self.SingleAuras[k]:SetWidth(tonumber(oufdb.CornerAura.Size))
			self.SingleAuras[k]:SetHeight(tonumber(oufdb.CornerAura.Size))
			self.SingleAuras[k]:ClearAllPoints()
			self.SingleAuras[k]:SetPoint(k, self, k, x, y)
		end
	end,
	RaidDebuffs = function(self, unit, oufdb)
		if not self.RaidDebuffs then
			self.RaidDebuffs = CreateFrame("Frame", nil, self)
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

		self.RaidDebuffs:SetHeight(tonumber(oufdb.RaidDebuff.Size))
		self.RaidDebuffs:SetWidth(tonumber(oufdb.RaidDebuff.Size))
	end,

	-- others
	Portrait = function(self, unit, oufdb)
		if not self.Portrait then
			self.Portrait = CreateFrame("PlayerModel", nil, self)
			self.Portrait:SetFrameLevel(5)
			self.Portrait.Override = PortraitOverride
		end

		self.Portrait:SetHeight(tonumber(oufdb.Portrait.Height))
		self.Portrait:SetWidth(tonumber(oufdb.Portrait.Width) * (self:GetWidth()/oufdb.Width)) -- needed for 25/40 man raid width downscaling!
		self.Portrait:SetAlpha(oufdb.Portrait.Alpha)
		self.Portrait:ClearAllPoints()
		self.Portrait:SetPoint("TOPLEFT", self, "TOPLEFT", tonumber(oufdb.Portrait.X) * (self:GetWidth()/oufdb.Width), tonumber(oufdb.Portrait.Y)) -- needed for 25/40 man raid width downscaling!
	end,

	Buffs = function(self, unit, oufdb)
		if not self.Buffs then self.Buffs = CreateFrame("Frame", nil, self) end

		self.Buffs:SetHeight(tonumber(oufdb.Aura.buffs_size))
		self.Buffs:SetWidth(tonumber(oufdb.Width))
		self.Buffs.size = tonumber(oufdb.Aura.buffs_size)
		self.Buffs.spacing = tonumber(oufdb.Aura.buffs_spacing)
		self.Buffs.num = tonumber(oufdb.Aura.buffs_num)

		for i = 1, #self.Buffs do
			local button = self.Buffs[i]
			if button and button:IsShown() then
				button:SetWidth(tonumber(oufdb.Aura.buffs_size))
				button:SetHeight(tonumber(oufdb.Aura.buffs_size))
			elseif not button then
				break
			end
		end

		self.Buffs:ClearAllPoints()
		self.Buffs:SetPoint(oufdb.Aura.buffs_initialAnchor, self, oufdb.Aura.buffs_initialAnchor, tonumber(oufdb.Aura.buffsX), tonumber(oufdb.Aura.buffsY))
		self.Buffs.initialAnchor = oufdb.Aura.buffs_initialAnchor
		self.Buffs["growth-y"] = oufdb.Aura.buffs_growthY
		self.Buffs["growth-x"] = oufdb.Aura.buffs_growthX
		self.Buffs.onlyShowPlayer = oufdb.Aura.buffs_playeronly
		self.Buffs.includePet = oufdb.Aura.buffs_includepet
		self.Buffs.showStealableBuffs = (unit ~= "player" and (class == "MAGE" or class == "SHAMAN"))
		self.Buffs.showAuraType = oufdb.Aura.buffs_colorbytype
		self.Buffs.showAuratimer = oufdb.Aura.buffs_auratimer
		self.Buffs.disableCooldown = oufdb.Aura.buffs_disableCooldown
		self.Buffs.cooldownReverse = oufdb.Aura.buffs_cooldownReverse

		self.Buffs.PostCreateIcon = PostCreateAura
		self.Buffs.PostUpdateIcon = PostUpdateAura
		self.Buffs.CustomFilter = CustomFilter
	end,
	Debuffs = function(self, unit, oufdb)
		if not self.Debuffs then self.Debuffs = CreateFrame("Frame", nil, self) end

		self.Debuffs:SetHeight(tonumber(oufdb.Aura.debuffs_size))
		self.Debuffs:SetWidth(tonumber(oufdb.Width))
		self.Debuffs.size = tonumber(oufdb.Aura.debuffs_size)
		self.Debuffs.spacing = tonumber(oufdb.Aura.debuffs_spacing)
		self.Debuffs.num = tonumber(oufdb.Aura.debuffs_num)

		for i = 1, #self.Debuffs do
			local button = self.Debuffs[i]
			if button and button:IsShown() then
				button:SetWidth(tonumber(oufdb.Aura.debuffs_size))
				button:SetHeight(tonumber(oufdb.Aura.debuffs_size))
			elseif not button then
				break
			end
		end

		self.Debuffs:ClearAllPoints()
		self.Debuffs:SetPoint(oufdb.Aura.debuffs_initialAnchor, self, oufdb.Aura.debuffs_initialAnchor, tonumber(oufdb.Aura.debuffsX), tonumber(oufdb.Aura.debuffsY))
		self.Debuffs.initialAnchor = oufdb.Aura.debuffs_initialAnchor
		self.Debuffs["growth-y"] = oufdb.Aura.debuffs_growthY
		self.Debuffs["growth-x"] = oufdb.Aura.debuffs_growthX
		self.Debuffs.onlyShowPlayer = oufdb.Aura.debuffs_playeronly
		self.Debuffs.includePet = oufdb.Aura.debuffs_includepet
		self.Debuffs.showAuraType = oufdb.Aura.debuffs_colorbytype
		self.Debuffs.showAuratimer = oufdb.Aura.debuffs_auratimer
		self.Debuffs.disableCooldown = oufdb.Aura.debuffs_disableCooldown
		self.Debuffs.cooldownReverse = oufdb.Aura.debuffs_cooldownReverse

		self.Debuffs.PostCreateIcon = PostCreateAura
		self.Debuffs.PostUpdateIcon = PostUpdateAura
		self.Debuffs.CustomFilter = CustomFilter
	end,

	CombatFeedbackText = function(self, unit, oufdb)
		if not self.CombatFeedbackText then
			self.CombatFeedbackText = SetFontString(self.Health, LSM:Fetch("font", oufdb.Texts.Combat.Font), tonumber(oufdb.Texts.Combat.Size), oufdb.Texts.Combat.Outline)
		else
			self.CombatFeedbackText:SetFont(LSM:Fetch("font", oufdb.Texts.Combat.Font), tonumber(oufdb.Texts.Combat.Size), oufdb.Texts.Combat.Outline)
		end
		self.CombatFeedbackText:ClearAllPoints()
		self.CombatFeedbackText:SetPoint(oufdb.Texts.Combat.Point, self, oufdb.Texts.Combat.RelativePoint, tonumber(oufdb.Texts.Combat.X), tonumber(oufdb.Texts.Combat.Y))
		self.CombatFeedbackText.colors = colors.combattext

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
		if not self.Castbar then
			self.Castbar = CreateFrame("StatusBar", self:GetName().."_Castbar", self)
			self.Castbar:SetFrameLevel(6)

			self.Castbar.bg = self.Castbar:CreateTexture(nil, "BORDER")
			self.Castbar.bg:SetAllPoints(self.Castbar)

			self.Castbar.Backdrop = CreateFrame("Frame", nil, self)
			self.Castbar.Backdrop:SetPoint("TOPLEFT", self.Castbar, "TOPLEFT", -4, 3)
			self.Castbar.Backdrop:SetPoint("BOTTOMRIGHT", self.Castbar, "BOTTOMRIGHT", 3, -3.5)
			self.Castbar.Backdrop:SetParent(self.Castbar)

			self.Castbar.Time = SetFontString(self.Castbar, LSM:Fetch("font", oufdb.Castbar.Text.Time.Font), oufdb.Castbar.Text.Time.Size)
			self.Castbar.Time:SetJustifyH("RIGHT")
			self.Castbar.CustomTimeText = FormatCastbarTime
			self.Castbar.CustomDelayText = FormatCastbarTime

			self.Castbar.Text = SetFontString(self.Castbar, LSM:Fetch("font", oufdb.Castbar.Text.Name.Font), oufdb.Castbar.Text.Name.Size)
			
			if unit == "player" then
				self.Castbar.SafeZone = self.Castbar:CreateTexture(nil, "ARTWORK")
				self.Castbar.SafeZone:SetTexture(normTex)
			end

			if unit == "player" or unit == "target" or unit == "focus" or unit == "pet" then
				self.Castbar.Icon = self.Castbar:CreateTexture(nil, "ARTWORK")
				self.Castbar.Icon:SetHeight(28.5)
				self.Castbar.Icon:SetWidth(28.5)
				self.Castbar.Icon:SetTexCoord(0, 1, 0, 1)
				self.Castbar.Icon:SetPoint("LEFT", -41.5, 0)

				self.Castbar.IconOverlay = self.Castbar:CreateTexture(nil, "OVERLAY")
				self.Castbar.IconOverlay:SetPoint("TOPLEFT", self.Castbar.Icon, "TOPLEFT", -1.5, 1)
				self.Castbar.IconOverlay:SetPoint("BOTTOMRIGHT", self.Castbar.Icon, "BOTTOMRIGHT", 1, -1)
				self.Castbar.IconOverlay:SetTexture(buttonTex)
				self.Castbar.IconOverlay:SetVertexColor(1, 1, 1)

				self.Castbar.IconBackdrop = CreateFrame("Frame", nil, self.Castbar)
				self.Castbar.IconBackdrop:SetPoint("TOPLEFT", self.Castbar.Icon, "TOPLEFT", -4, 3)
				self.Castbar.IconBackdrop:SetPoint("BOTTOMRIGHT", self.Castbar.Icon, "BOTTOMRIGHT", 3, -3.5)
				self.Castbar.IconBackdrop:SetBackdrop({
					edgeFile = glowTex, edgeSize = 4,
					insets = {left = 3, right = 3, top = 3, bottom = 3}
				})
				self.Castbar.IconBackdrop:SetBackdropColor(0, 0, 0, 0)
				self.Castbar.IconBackdrop:SetBackdropBorderColor(0, 0, 0, 0.7)
			else
				self.Castbar.Icon = self.Castbar:CreateTexture(nil, "ARTWORK")
				self.Castbar.Icon:SetHeight(20)
				self.Castbar.Icon:SetWidth(20)
				self.Castbar.Icon:SetTexCoord(0, 1, 0, 1)
				if unit == unit:match("arena%d") then
					self.Castbar.Icon:SetPoint("RIGHT", 30, 0)
				else
					self.Castbar.Icon:SetPoint("LEFT", -30, 0)
				end

				self.Castbar.IconOverlay = self.Castbar:CreateTexture(nil, "OVERLAY")
				self.Castbar.IconOverlay:SetPoint("TOPLEFT", self.Castbar.Icon, "TOPLEFT", -1.5, 1)
				self.Castbar.IconOverlay:SetPoint("BOTTOMRIGHT", self.Castbar.Icon, "BOTTOMRIGHT", 1, -1)
				self.Castbar.IconOverlay:SetTexture(buttonTex)
				self.Castbar.IconOverlay:SetVertexColor(1, 1, 1)

				self.Castbar.IconBackdrop = CreateFrame("Frame", nil, self.Castbar)
				self.Castbar.IconBackdrop:SetPoint("TOPLEFT", self.Castbar.Icon, "TOPLEFT", -4, 3)
				self.Castbar.IconBackdrop:SetPoint("BOTTOMRIGHT", self.Castbar.Icon, "BOTTOMRIGHT", 3, -3.5)
				self.Castbar.IconBackdrop:SetBackdrop({
					edgeFile = glowTex, edgeSize = 4,
					insets = {left = 3, right = 3, top = 3, bottom = 3}
				})
				self.Castbar.IconBackdrop:SetBackdropColor(0, 0, 0, 0)
				self.Castbar.IconBackdrop:SetBackdropBorderColor(0, 0, 0, 0.7)
			end
		end
		
		self.Castbar:SetStatusBarTexture(LSM:Fetch("statusbar", oufdb.Castbar.Texture))
		self.Castbar:SetHeight(tonumber(oufdb.Castbar.Height))
		self.Castbar:SetWidth(tonumber(oufdb.Castbar.Width))
		
		self.Castbar:ClearAllPoints()
		if unit == "player" or unit == "target" then
			self.Castbar:SetPoint(oufdb.Castbar.Point, UIParent, oufdb.Castbar.Point, tonumber(oufdb.Castbar.X), tonumber(oufdb.Castbar.Y))
		elseif unit == "focus" or unit == "pet" then
			self.Castbar:SetPoint("TOP", self, "BOTTOM", tonumber(oufdb.Castbar.X), tonumber(oufdb.Castbar.Y))
		elseif unit == unit:match("arena%d") then
			self.Castbar:SetPoint("RIGHT", self, "LEFT", tonumber(oufdb.Castbar.X), tonumber(oufdb.Castbar.Y))
		else
			self.Castbar:SetPoint("LEFT", self, "RIGHT", tonumber(oufdb.Castbar.X), tonumber(oufdb.Castbar.Y))
		end
		
		self.Castbar.bg:SetTexture(LSM:Fetch("statusbar", oufdb.Castbar.TextureBG))
		
		self.Castbar.Backdrop:SetBackdrop({
			edgeFile = LSM:Fetch("border", oufdb.Castbar.Border.Texture),
			edgeSize = tonumber(oufdb.Castbar.Border.Thickness),
			insets = {
				left = tonumber(oufdb.Castbar.Border.Inset.left),
				right = tonumber(oufdb.Castbar.Border.Inset.right),
				top = tonumber(oufdb.Castbar.Border.Inset.top),
				bottom = tonumber(oufdb.Castbar.Border.Inset.bottom)
			}
		})
		self.Castbar.Backdrop:SetBackdropColor(0, 0, 0, 0)
		
		self.Castbar.Colors = {
			Individual = oufdb.Castbar.IndividualColor,
			Bar = oufdb.Castbar.Colors.Bar,
			Background = oufdb.Castbar.Colors.Background,
			Border = oufdb.Castbar.Colors.Border,
			Shield = oufdb.Castbar.Colors.Shield,
		}
		
		self.Castbar.PostCastStart = PostCastStart
		self.Castbar.PostChannelStart = PostCastStart
		
		self.Castbar.Time:SetFont(LSM:Fetch("font", oufdb.Castbar.Text.Time.Font), oufdb.Castbar.Text.Time.Size)
		self.Castbar.Time:ClearAllPoints()
		self.Castbar.Time:SetPoint("RIGHT", self.Castbar, "RIGHT", oufdb.Castbar.Text.Time.OffsetX, oufdb.Castbar.Text.Time.OffsetY)
		self.Castbar.Time:SetTextColor(oufdb.Castbar.Colors.Time.r, oufdb.Castbar.Colors.Time.g, oufdb.Castbar.Colors.Time.b)
		self.Castbar.Time.ShowMax = oufdb.Castbar.Text.Time.ShowMax
		
		if oufdb.Castbar.Text.Time.Enable == true then
			self.Castbar.Time:Show()
		else
			self.Castbar.Time:Hide()
		end
		
		self.Castbar.Text:SetFont(LSM:Fetch("font", oufdb.Castbar.Text.Name.Font), oufdb.Castbar.Text.Name.Size)
		self.Castbar.Text:ClearAllPoints()
		self.Castbar.Text:SetPoint("LEFT", self.Castbar, "LEFT", oufdb.Castbar.Text.Name.OffsetX, oufdb.Castbar.Text.Name.OffsetY)
		self.Castbar.Text:SetTextColor(oufdb.Castbar.Colors.Name.r, oufdb.Castbar.Colors.Name.r, oufdb.Castbar.Colors.Name.r)

		if oufdb.Castbar.Text.Name.Enable == true then
			self.Castbar.Text:Show()
		else
			self.Castbar.Text:Hide()
		end

		if unit == "player" then
			if oufdb.Castbar.Latency == true then
				self.Castbar.SafeZone:Show()
				if oufdb.Castbar.IndividualColor == true then
					self.Castbar.SafeZone:SetVertexColor(oufdb.Castbar.Colors.Latency.r,oufdb.Castbar.Colors.Latency.g,oufdb.Castbar.Colors.Latency.b,oufdb.Castbar.Colors.Latency.a)
				else
					self.Castbar.SafeZone:SetVertexColor(0.11,0.11,0.11,0.6)
				end
			else
				self.Castbar.SafeZone:Hide()
			end
		end

		if oufdb.Castbar.Icon then
			self.Castbar.Icon:Show()
			self.Castbar.IconOverlay:Show()
			self.Castbar.IconBackdrop:Show()
		else
			self.Castbar.Icon:Hide()
			self.Castbar.IconOverlay:Hide()
			self.Castbar.IconBackdrop:Hide()
		end
	end,

	AggroGlow = function(self, unit, oufdb)
		if self.Threat then return end

		self.Threat = CreateFrame("Frame", nil, self)
		self.Threat:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
		self.Threat:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
		self.Threat:SetFrameLevel(self.Health:GetFrameLevel() - 1)

		for i = 1, 8 do
			self.Threat[i] = self.Threat:CreateTexture(nil, "BACKGROUND")
			self.Threat[i]:SetTexture(aggroTex)
			self.Threat[i]:SetWidth(20)
			self.Threat[i]:SetHeight(20)
		end

		-- topleft corner
		self.Threat[1]:SetTexCoord(0, 1/3, 0, 1/3)
		self.Threat[1]:SetPoint("TOPLEFT", self.Threat, -8, 8)

		-- topright corner
		self.Threat[2]:SetTexCoord(2/3, 1, 0, 1/3)
		self.Threat[2]:SetPoint("TOPRIGHT", self.Threat, 8, 8)

		-- bottomleft corner
		self.Threat[3]:SetTexCoord(0, 1/3, 2/3, 1)
		self.Threat[3]:SetPoint("BOTTOMLEFT", self.Threat, -8, -8)

		-- bottomright corner
		self.Threat[4]:SetTexCoord(2/3, 1, 2/3, 1)
		self.Threat[4]:SetPoint("BOTTOMRIGHT", self.Threat, 8, -8)

		-- top edge
		self.Threat[5]:SetTexCoord(1/3, 2/3, 0, 1/3)
		self.Threat[5]:SetPoint("TOPLEFT", self.Threat[1], "TOPRIGHT")
		self.Threat[5]:SetPoint("TOPRIGHT", self.Threat[2], "TOPLEFT")

		-- bottom edge
		self.Threat[6]:SetTexCoord(1/3, 2/3, 2/3, 1)
		self.Threat[6]:SetPoint("BOTTOMLEFT", self.Threat[3], "BOTTOMRIGHT")
		self.Threat[6]:SetPoint("BOTTOMRIGHT", self.Threat[4], "BOTTOMLEFT")

		-- left edge
		self.Threat[7]:SetTexCoord(0, 1/3, 1/3, 2/3)
		self.Threat[7]:SetPoint("TOPLEFT", self.Threat[1], "BOTTOMLEFT")
		self.Threat[7]:SetPoint("BOTTOMLEFT", self.Threat[3], "TOPLEFT")

		-- right edge
		self.Threat[8]:SetTexCoord(2/3, 1, 1/3, 2/3)
		self.Threat[8]:SetPoint("TOPRIGHT", self.Threat[2], "BOTTOMRIGHT")
		self.Threat[8]:SetPoint("BOTTOMRIGHT", self.Threat[4], "TOPRIGHT")

		self.Threat.Override = ThreatOverride
	end,

	HealPrediction = function(self, unit, oufdb)
		if not self.HealPrediction then
			self.HealPrediction = {
				myBar = CreateFrame("StatusBar", nil, self.Health),
				otherBar = CreateFrame("StatusBar", nil, self.Health),
				maxOverflow = 1,
			}
		end

		self.HealPrediction.myBar:SetWidth(tonumber(oufdb.Health.Width) * (self:GetWidth()/oufdb.Width)) -- needed for 25/40 man raid width downscaling!
		self.HealPrediction.myBar:SetStatusBarTexture(LSM:Fetch("statusbar", oufdb.HealPrediction.Texture))
		self.HealPrediction.myBar:SetStatusBarColor(tonumber(oufdb.HealPrediction.MyColor.r), tonumber(oufdb.HealPrediction.MyColor.g), tonumber(oufdb.HealPrediction.MyColor.b), tonumber(oufdb.HealPrediction.MyColor.a))

		self.HealPrediction.otherBar:SetWidth(tonumber(oufdb.Health.Width) * (self:GetWidth()/oufdb.Width)) -- needed for 25/40 man raid width downscaling!
		self.HealPrediction.otherBar:SetStatusBarTexture(LSM:Fetch("statusbar", oufdb.HealPrediction.Texture))
		self.HealPrediction.otherBar:SetStatusBarColor(tonumber(oufdb.HealPrediction.OtherColor.r), tonumber(oufdb.HealPrediction.OtherColor.g), tonumber(oufdb.HealPrediction.OtherColor.b), tonumber(oufdb.HealPrediction.OtherColor.a))

		self.HealPrediction.myBar:ClearAllPoints()
		self.HealPrediction.myBar:SetPoint("TOPLEFT", self.Health:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
		self.HealPrediction.myBar:SetPoint("BOTTOMLEFT", self.Health:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)

		self.HealPrediction.otherBar:SetPoint("TOPLEFT", self.HealPrediction.myBar:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
		self.HealPrediction.otherBar:SetPoint("BOTTOMLEFT", self.HealPrediction.myBar:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
	end,

	V2Textures = function(self, unit, oufdb)
		if unit == "targettarget" and db.oUF.Settings.show_v2_textures then
			local Panel2 = CreateFrame("Frame", nil, self)
			Panel2:SetFrameLevel(19)
			Panel2:SetFrameStrata("BACKGROUND")
			Panel2:SetHeight(2)
			Panel2:SetWidth(60)
			Panel2:SetPoint("LEFT", self.Health, "LEFT", -50, -1)
			Panel2:SetScale(1)
			Panel2:SetBackdrop(backdrop2)
			Panel2:SetBackdropColor(0,0,0,1)
			Panel2:SetBackdropBorderColor(0.1,0.1,0.1,1)
			Panel2:Show()

			local Panel3 = CreateFrame("Frame", nil, Panel2)
			Panel3:SetFrameLevel(19)
			Panel3:SetFrameStrata("BACKGROUND")
			Panel3:SetHeight(50)
			Panel3:SetWidth(2)
			Panel3:SetPoint("LEFT", self.Health, "LEFT", -50, 23)
			Panel3:SetScale(1)
			Panel3:SetBackdrop(backdrop2)
			Panel3:SetBackdropColor(0,0,0,1)
			Panel3:SetBackdropBorderColor(0.1,0.1,0.1,1)
			Panel3:Show()

			local Panel4 = CreateFrame("Frame", nil, Panel2)
			Panel4:SetFrameLevel(19)
			Panel4:SetFrameStrata("BACKGROUND")
			Panel4:SetHeight(2)
			Panel4:SetWidth(60)
			Panel4:SetPoint("RIGHT", self.Health, "RIGHT", 50, -1)
			Panel4:SetScale(1)
			Panel4:SetBackdrop(backdrop2)
			Panel4:SetBackdropColor(0,0,0,1)
			Panel4:SetBackdropBorderColor(0.1,0.1,0.1,1)
			Panel4:Show()

			local Panel5 = CreateFrame("Frame", nil, Panel2)
			Panel5:SetFrameLevel(19)
			Panel5:SetFrameStrata("BACKGROUND")
			Panel5:SetHeight(6)
			Panel5:SetWidth(6)
			Panel5:SetPoint("RIGHT", self.Health, "RIGHT", 52, -1)
			Panel5:SetScale(1)
			Panel5:SetBackdrop(backdrop2)
			Panel5:SetBackdropColor(0,0,0,1)
			Panel5:SetBackdropBorderColor(0.1,0.1,0.1,1)
			Panel5:Show()

			self.V2Tex = Panel2
		elseif unit == "targettargettarget" and db.oUF.Settings.show_v2_textures then
			local Panel2 = CreateFrame("Frame", nil, self)
			Panel2:SetFrameLevel(19)
			Panel2:SetFrameStrata("BACKGROUND")
			Panel2:SetHeight(2)
			Panel2:SetWidth(60)
			Panel2:SetPoint("LEFT", self.Health, "LEFT", -50, -1)
			Panel2:SetScale(1)
			Panel2:SetBackdrop(backdrop2)
			Panel2:SetBackdropColor(0,0,0,1)
			Panel2:SetBackdropBorderColor(0.1,0.1,0.1,1)
			Panel2:Show()

			local Panel3 = CreateFrame("Frame", nil, Panel2)
			Panel3:SetFrameLevel(19)
			Panel3:SetFrameStrata("BACKGROUND")
			Panel3:SetHeight(35)
			Panel3:SetWidth(2)
			Panel3:SetPoint("LEFT", self.Health, "LEFT", -50, 16)
			Panel3:SetScale(1)
			Panel3:SetBackdrop(backdrop2)
			Panel3:SetBackdropColor(0,0,0,1)
			Panel3:SetBackdropBorderColor(0.1,0.1,0.1,1)
			Panel3:Show()

			local Panel4 = CreateFrame("Frame", nil, Panel2)
			Panel4:SetFrameLevel(19)
			Panel4:SetFrameStrata("BACKGROUND")
			Panel4:SetHeight(2)
			Panel4:SetWidth(60)
			Panel4:SetPoint("RIGHT", self.Health, "RIGHT", 50, -1)
			Panel4:SetScale(1)
			Panel4:SetBackdrop(backdrop2)
			Panel4:SetBackdropColor(0,0,0,1)
			Panel4:SetBackdropBorderColor(0.1,0.1,0.1,1)
			Panel4:Show()

			local Panel5 = CreateFrame("Frame", nil, Panel2)
			Panel5:SetFrameLevel(19)
			Panel5:SetFrameStrata("BACKGROUND")
			Panel5:SetHeight(6)
			Panel5:SetWidth(6)
			Panel5:SetPoint("RIGHT", self.Health, "RIGHT", 52, -1)
			Panel5:SetScale(1)
			Panel5:SetBackdrop(backdrop2)
			Panel5:SetBackdropColor(0,0,0,1)
			Panel5:SetBackdropBorderColor(0.1,0.1,0.1,1)
			Panel5:Show()

			local Panel6 = CreateFrame("Frame", nil, Panel2)
			Panel6:SetFrameLevel(19)
			Panel6:SetFrameStrata("BACKGROUND")
			Panel6:SetHeight(6)
			Panel6:SetWidth(6)
			Panel6:SetPoint("LEFT", self.Health, "LEFT", -52, 34)
			Panel6:SetScale(1)
			Panel6:SetBackdrop(backdrop2)
			Panel6:SetBackdropColor(0,0,0,1)
			Panel6:SetBackdropBorderColor(0.1,0.1,0.1,1)
			Panel6:Show()

			self.V2Tex = Panel2
		elseif unit == "focustarget" and db.oUF.Settings.show_v2_textures then
			local Panel2 = CreateFrame("Frame", nil, self)
			Panel2:SetFrameLevel(19)
			Panel2:SetFrameStrata("BACKGROUND")
			Panel2:SetHeight(2)
			Panel2:SetWidth(60)
			Panel2:SetPoint("LEFT", self.Health, "LEFT", -50, -1)
			Panel2:SetScale(1)
			Panel2:SetBackdrop(backdrop2)
			Panel2:SetBackdropColor(0,0,0,1)
			Panel2:SetBackdropBorderColor(0.1,0.1,0.1,1)
			Panel2:Show()

			local Panel3 = CreateFrame("Frame", nil, Panel2)
			Panel3:SetFrameLevel(19)
			Panel3:SetFrameStrata("BACKGROUND")
			Panel3:SetHeight(35)
			Panel3:SetWidth(2)
			Panel3:SetPoint("RIGHT", self.Health, "RIGHT", 50, 16)
			Panel3:SetScale(1)
			Panel3:SetBackdrop(backdrop2)
			Panel3:SetBackdropColor(0,0,0,1)
			Panel3:SetBackdropBorderColor(0.1,0.1,0.1,1)
			Panel3:Show()

			local Panel4 = CreateFrame("Frame", nil, Panel2)
			Panel4:SetFrameLevel(19)
			Panel4:SetFrameStrata("BACKGROUND")
			Panel4:SetHeight(2)
			Panel4:SetWidth(60)
			Panel4:SetPoint("RIGHT", self.Health, "RIGHT", 50, -1)
			Panel4:SetScale(1)
			Panel4:SetBackdrop(backdrop2)
			Panel4:SetBackdropColor(0,0,0,1)
			Panel4:SetBackdropBorderColor(0.1,0.1,0.1,1)
			Panel4:Show()

			local Panel5 = CreateFrame("Frame", nil, Panel2)
			Panel5:SetFrameLevel(19)
			Panel5:SetFrameStrata("BACKGROUND")
			Panel5:SetHeight(6)
			Panel5:SetWidth(6)
			Panel5:SetPoint("LEFT", self.Health, "LEFT", -52, -1)
			Panel5:SetScale(1)
			Panel5:SetBackdrop(backdrop2)
			Panel5:SetBackdropColor(0,0,0,1)
			Panel5:SetBackdropBorderColor(0.1,0.1,0.1,1)
			Panel5:Show()

			local Panel6 = CreateFrame("Frame", nil, Panel2)
			Panel6:SetFrameLevel(19)
			Panel6:SetFrameStrata("BACKGROUND")
			Panel6:SetHeight(6)
			Panel6:SetWidth(6)
			Panel6:SetPoint("RIGHT", self.Health, "RIGHT", 52, 34)
			Panel6:SetScale(1)
			Panel6:SetBackdrop(backdrop2)
			Panel6:SetBackdropColor(0,0,0,1)
			Panel6:SetBackdropBorderColor(0.1,0.1,0.1,1)
			Panel6:Show()

			self.V2Tex = Panel2
		elseif unit == "focus" and db.oUF.Settings.show_v2_textures then
			local Panel2 = CreateFrame("Frame", nil, self)
			Panel2:SetFrameLevel(19)
			Panel2:SetFrameStrata("BACKGROUND")
			Panel2:SetHeight(2)
			Panel2:SetWidth(60)
			Panel2:SetPoint("RIGHT", self.Health, "RIGHT", 50, -1)
			Panel2:SetScale(1)
			Panel2:SetBackdrop(backdrop2)
			Panel2:SetBackdropColor(0,0,0,1)
			Panel2:SetBackdropBorderColor(0.1,0.1,0.1,1)
			Panel2:Show()

			local Panel3 = CreateFrame("Frame", nil, Panel2)
			Panel3:SetFrameLevel(19)
			Panel3:SetFrameStrata("BACKGROUND")
			Panel3:SetHeight(50)
			Panel3:SetWidth(2)
			Panel3:SetPoint("RIGHT", self.Health, "RIGHT", 50, 23)
			Panel3:SetScale(1)
			Panel3:SetBackdrop(backdrop2)
			Panel3:SetBackdropColor(0,0,0,1)
			Panel3:SetBackdropBorderColor(0.1,0.1,0.1,1)
			Panel3:Show()

			local Panel4 = CreateFrame("Frame", nil, Panel2)
			Panel4:SetFrameLevel(19)
			Panel4:SetFrameStrata("BACKGROUND")
			Panel4:SetHeight(2)
			Panel4:SetWidth(50)
			Panel4:SetPoint("LEFT", self.Health, "LEFT", -50, -1)
			Panel4:SetScale(1)
			Panel4:SetBackdrop(backdrop2)
			Panel4:SetBackdropColor(0,0,0,1)
			Panel4:SetBackdropBorderColor(0.1,0.1,0.1,1)
			Panel4:Show()

			local Panel5 = CreateFrame("Frame", nil, Panel2)
			Panel5:SetFrameLevel(19)
			Panel5:SetFrameStrata("BACKGROUND")
			Panel5:SetHeight(6)
			Panel5:SetWidth(6)
			Panel5:SetPoint("LEFT", self.Health, "LEFT", -52, -1)
			Panel5:SetScale(1)
			Panel5:SetBackdrop(backdrop2)
			Panel5:SetBackdropColor(0,0,0,1)
			Panel5:SetBackdropBorderColor(0.1,0.1,0.1,1)
			Panel5:Show()

			self.V2Tex = Panel2
		elseif (unit == unit:match("arena%dtarget") and db.oUF.Settings.show_v2_arena_textures) or (unit == unit:match("boss%dtarget") and db.oUF.Settings.show_v2_boss_textures) then
			local Panel2 = CreateFrame("Frame", nil, self)
			Panel2:SetFrameLevel(19)
			Panel2:SetFrameStrata("BACKGROUND")
			Panel2:SetHeight(2)
			Panel2:SetWidth(60)
			Panel2:SetPoint("RIGHT", self.Health, "RIGHT", 40, -1)
			Panel2:SetScale(1)
			Panel2:SetBackdrop(backdrop2)
			Panel2:SetBackdropColor(0,0,0,1)
			Panel2:SetBackdropBorderColor(0.1,0.1,0.1,1)
			Panel2:Show()

			local Panel3 = CreateFrame("Frame", nil, Panel2)
			Panel3:SetFrameLevel(19)
			Panel3:SetFrameStrata("BACKGROUND")
			Panel3:SetHeight(50)
			Panel3:SetWidth(2)
			Panel3:SetPoint("RIGHT", self.Health, "RIGHT", 40, 23)
			Panel3:SetScale(1)
			Panel3:SetBackdrop(backdrop2)
			Panel3:SetBackdropColor(0,0,0,1)
			Panel3:SetBackdropBorderColor(0.1,0.1,0.1,1)
			Panel3:Show()

			local Panel4 = CreateFrame("Frame", nil, Panel2)
			Panel4:SetFrameLevel(19)
			Panel4:SetFrameStrata("BACKGROUND")
			Panel4:SetHeight(2)
			Panel4:SetWidth(60)
			Panel4:SetPoint("LEFT", self.Health, "LEFT", -40, -1)
			Panel4:SetScale(1)
			Panel4:SetBackdrop(backdrop2)
			Panel4:SetBackdropColor(0,0,0,1)
			Panel4:SetBackdropBorderColor(0.1,0.1,0.1,1)
			Panel4:Show()

			local Panel5 = CreateFrame("Frame", nil, Panel2)
			Panel5:SetFrameLevel(19)
			Panel5:SetFrameStrata("BACKGROUND")
			Panel5:SetHeight(6)
			Panel5:SetWidth(6)
			Panel5:SetPoint("LEFT", self.Health, "LEFT", -42, -1)
			Panel5:SetScale(1)
			Panel5:SetBackdrop(backdrop2)
			Panel5:SetBackdropColor(0,0,0,1)
			Panel5:SetBackdropBorderColor(0.1,0.1,0.1,1)
			Panel5:Show()

			self.V2Tex = Panel2
		elseif unit == "partytarget" and db.oUF.Settings.show_v2_party_textures then
			local Panel2 = CreateFrame("Frame", nil, self)
			Panel2:SetFrameLevel(19)
			Panel2:SetFrameStrata("BACKGROUND")
			Panel2:SetHeight(2)
			Panel2:SetWidth(60)
			Panel2:SetPoint("LEFT", self.Health, "LEFT", -40, -1)
			Panel2:SetScale(1)
			Panel2:SetBackdrop(backdrop2)
			Panel2:SetBackdropColor(0,0,0,1)
			Panel2:SetBackdropBorderColor(0.1,0.1,0.1,1)
			Panel2:Show()

			local Panel3 = CreateFrame("Frame", nil, Panel2)
			Panel3:SetFrameLevel(19)
			Panel3:SetFrameStrata("BACKGROUND")
			Panel3:SetHeight(50)
			Panel3:SetWidth(2)
			Panel3:SetPoint("LEFT", self.Health, "LEFT", -40, 23)
			Panel3:SetScale(1)
			Panel3:SetBackdrop(backdrop2)
			Panel3:SetBackdropColor(0,0,0,1)
			Panel3:SetBackdropBorderColor(0.1,0.1,0.1,1)
			Panel3:Show()

			local Panel4 = CreateFrame("Frame", nil, Panel2)
			Panel4:SetFrameLevel(19)
			Panel4:SetFrameStrata("BACKGROUND")
			Panel4:SetHeight(2)
			Panel4:SetWidth(60)
			Panel4:SetPoint("RIGHT", self.Health, "RIGHT", 40, -1)
			Panel4:SetScale(1)
			Panel4:SetBackdrop(backdrop2)
			Panel4:SetBackdropColor(0,0,0,1)
			Panel4:SetBackdropBorderColor(0.1,0.1,0.1,1)
			Panel4:Show()

			local Panel5 = CreateFrame("Frame", nil, Panel2)
			Panel5:SetFrameLevel(19)
			Panel5:SetFrameStrata("BACKGROUND")
			Panel5:SetHeight(6)
			Panel5:SetWidth(6)
			Panel5:SetPoint("RIGHT", self.Health, "RIGHT", 42, -1)
			Panel5:SetScale(1)
			Panel5:SetBackdrop(backdrop2)
			Panel5:SetBackdropColor(0,0,0,1)
			Panel5:SetBackdropBorderColor(0.1,0.1,0.1,1)
			Panel5:Show()

			self.V2Tex = Panel2
		end
	end
}
funcs = LUI.oUF.funcs

------------------------------------------------------------------------
--	oUF Colors
------------------------------------------------------------------------

LUI.oUF.colors = setmetatable({
	power = setmetatable({
		["POWER_TYPE_STEAM"] = {0.55, 0.57, 0.61},
		["POWER_TYPE_PYRITE"] = {0.60, 0.09, 0.17},
	}, {
		__index = function(t, k)
			return db.oUF.Colors.Power[k] or oUF.colors.power[k]
		end
	}),
	class = setmetatable({}, {
		__index = function(t, k)
			return db.oUF.Colors.Class[k] or oUF.colors.class[k]
		end
	}),
	leveldiff = setmetatable({}, {
		__index = function(t, k)
			local diffColor = GetQuestDifficultyColor(UnitLevel("target"))
			return db.oUF.Colors.LevelDiff[k] or {diffColor.r, diffColor.g, diffColor.b}
		end
	}),
	combattext = setmetatable({}, {
		__index = function(t, k)
			return db.oUF.Colors.CombatText[k]
		end
	}),
	combopoints = setmetatable({}, {
		__index = function(t, k)
			return db.oUF.Colors.ComboPoints[k] or oUF.colors.combopoints[k]
		end
	}),
	runes = setmetatable({}, {
		__index = function(t, k)
			return db.oUF.Colors.Runes[k] or oUF.colors.runes[k]
		end
	}),
	totembar = setmetatable({}, {
		__index = function(t, k)
			return db.oUF.Colors.TotemBar[k] or oUF.colors.totembar[k]
		end
	}),
	holypowerbar = setmetatable({}, {
		__index = function(t, k)
			return db.oUF.Colors.HolyPowerBar[k] or oUF.colors.holypowerbar[k]
		end
	}),
	soulshardbar = setmetatable({}, {
		__index = function(t, k)
			return db.oUF.Colors.SoulShardBar[k] or oUF.colors.soulshardbar[k]
		end
	}),
	eclipsebar = setmetatable({}, {
		__index = function(t, k)
			return db.oUF.Colors.EclipseBar[k]
		end
	}),
}, {
	__index = function(t, k)
		return db.oUF.Colors[k and (k:gsub("^%a", strupper)) or k] or oUF.colors[k]
	end
})
colors = LUI.oUF.colors

------------------------------------------------------------------------
--	Custom Tags
------------------------------------------------------------------------

-- frame for shortening the names for raidframes
local testframe = CreateFrame("Frame")
local teststring = testframe:CreateFontString(nil, "OVERLAY")

local function ShortenName(name)
	teststring:SetFont(LSM:Fetch("font", db.oUF.Raid.Texts.Name.Font), db.oUF.Raid.Texts.Name.Size, db.oUF.Raid.Texts.Name.Outline)
	teststring:SetText(name)

	if not nameCache[name] then nameCache[name] = {} end

	local shortname = name
	local maxwidth = tonumber(db.oUF.Raid.Width) * 0.9

	local l = name:len()
	while maxwidth < teststring:GetStringWidth() do
		shortname = shortname:sub(1, l)
		teststring:SetText(shortname)
		l = l - 1
	end

	nameCache[name][1] = shortname

	maxwidth = ((tonumber(db.oUF.Raid.Width) * 5 - tonumber(db.oUF.Raid.GroupPadding) * 3) / 8) * 0.9

	while maxwidth < teststring:GetStringWidth() do
		shortname = shortname:sub(1, l)
		teststring:SetText(shortname)
		l = l - 1
	end

	nameCache[name][2] = shortname
end

LUI.oUF.RecreateNameCache = function()
	for name, shortened in pairs(nameCache) do
		ShortenName(name)
	end
end

oUF.TagEvents["GetNameColor"] = "UNIT_HAPPINESS"
if (not oUF.Tags["GetNameColor"]) then
	oUF.Tags["GetNameColor"] = function(unit)
		local reaction = UnitReaction(unit, "player")
		local pClass, pToken = UnitClass(unit)
		local pClass2, pToken2 = UnitPowerType(unit)
		local color = colors.class[pToken]
		local color2 = colors.power[pToken2]
		local c = nil

		if (UnitIsPlayer(unit)) then
			if color then
				return string.format("|cff%02x%02x%02x", color[1] * 255, color[2] * 255, color[3] * 255)
			else
				if color2 then
					return string.format("|cff%02x%02x%02x", color2[1] * 255, color2[2] * 255, color2[3] * 255)
				else
					return string.format("|cff%02x%02x%02x", 0.8 * 255, 0.8 * 255, 0.8 * 255)
				end
			end
		else
			if color2 then
				return string.format("|cff%02x%02x%02x", color2[1] * 255, color2[2] * 255, color2[3] * 255)
			else
				if color then
					return string.format("|cff%02x%02x%02x", color[1] * 255, color[2] * 255, color[3] * 255)
				else
					return string.format("|cff%02x%02x%02x", 0.8 * 255, 0.8 * 255, 0.8 * 255)
				end
			end
		end
	end
end

oUF.TagEvents["DiffColor"] = "UNIT_LEVEL"
if (not oUF.Tags["DiffColor"]) then
	oUF.Tags["DiffColor"] = function(unit)
		local r, g, b
		local level = UnitLevel(unit)
		if (level < 1) then
			r, g, b = unpack(colors.leveldiff[1])
		else
			local DiffColor = level - UnitLevel("player")
			if (DiffColor >= 5) then
				r, g, b = unpack(colors.leveldiff[1])
			elseif (DiffColor >= 3) then
				r, g, b = unpack(colors.leveldiff[2])
			elseif (DiffColor >= -2) then
				r, g, b = unpack(colors.leveldiff[3])
			elseif (-DiffColor <= GetQuestGreenRange()) then
				r, g, b = unpack(colors.leveldiff[4])
			else
				r, g, b = unpack(colors.leveldiff[5])
			end
		end
		return string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
	end
end

oUF.TagEvents["level2"] = "UNIT_LEVEL"
if (not oUF.Tags["level2"]) then
	oUF.Tags["level2"] = function(unit)
		local l = UnitLevel(unit)
		return (l > 0) and l
	end
end

oUF.TagEvents["NameShort"] = "UNIT_NAME_UPDATE"
if (not oUF.Tags["NameShort"]) then
	oUF.Tags["NameShort"] = function(unit)
		local name = UnitName(unit)
		if name then
			if unit == "pet" and name == "Unknown" then
				return "Pet"
			else
				return utf8sub(name, 9, true)
			end
		end
	end
end

oUF.TagEvents["NameMedium"] = "UNIT_NAME_UPDATE"
if (not oUF.Tags["NameMedium"]) then
	oUF.Tags["NameMedium"] = function(unit)
		local name = UnitName(unit)
		if name then
			if unit == "pet" and name == "Unknown" then
				return "Pet"
			else
				return utf8sub(name, 18, true)
			end
		end
	end
end

oUF.TagEvents["NameLong"] = "UNIT_NAME_UPDATE"
if (not oUF.Tags["NameLong"]) then
	oUF.Tags["NameLong"] = function(unit)
		local name = UnitName(unit)
		if name then
			if unit == "pet" and name == "Unknown" then
				return "Pet"
			else
				return utf8sub(name, 36, true)
			end
		end
	end
end

oUF.TagEvents["RaidName25"] = "UNIT_NAME_UPDATE UNIT_HEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED"
if (not oUF.Tags["RaidName25"]) then
	oUF.Tags["RaidName25"] = function(unit, realunit)
		if db and db.oUF.Raid.Texts.Name.ShowDead then
			if not UnitIsConnected(unit) then
				return "|cffD7BEA5<Offline>|r"
			elseif UnitIsGhost(unit) then
				return "|cffD7BEA5<Ghost>|r"
			elseif UnitIsDead(unit) then
				return "|cffD7BEA5<Dead>|r"
			elseif UnitIsAFK(unit) then
				return "|cffD7BEA5<AFK>|r"
			end
		end
		local name = (unit == "vehicle" and UnitName(realunit or unit)) or UnitName(unit)
		if not nameCache[name] then ShortenName(name) end
		return nameCache[name][1]
	end
end

oUF.TagEvents["RaidName40"] = "UNIT_NAME_UPDATE UNIT_HEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED"
if (not oUF.Tags["RaidName40"]) then
	oUF.Tags["RaidName40"] = function(unit, realunit)
		if db and db.oUF.Raid.Texts.Name.ShowDead then
			if not UnitIsConnected(unit) then
				return "|cffD7BEA5<Offline>|r"
			elseif UnitIsGhost(unit) then
				return "|cffD7BEA5<Ghost>|r"
			elseif UnitIsDead(unit) then
				return "|cffD7BEA5<Dead>|r"
			elseif UnitIsAFK(unit) then
				return "|cffD7BEA5<AFK>|r"
			end
		end
		local name = (unit == "vehicle" and UnitName(realunit or unit)) or UnitName(unit)
		if not nameCache[name] then ShortenName(name) end
		return nameCache[name][2]
	end
end

oUF.TagEvents["druidmana2"] = "UNIT_POWER UNIT_MAXPOWER"
if (not oUF.Tags["druidmana2"]) then
	oUF.Tags["druidmana2"] = function(unit)
		if unit ~= "player" then return end

		if not db then return "" end

		local min, max = UnitPower("player", SPELL_POWER_MANA), UnitPowerMax("player", SPELL_POWER_MANA)
		local perc = min/max*100
		perc = format("%.1f", perc)
		perc = perc.."%"
		if db.oUF.Player.Texts.DruidMana.HideIfFullMana and min == max then return "" end

		local _, pType = UnitPowerType(unit)
		local pClass, pToken = UnitClass(unit)
		local color = colors.class[pToken]
		local color2 = colors.power[pType]

		local r, g, b, text

		if db.oUF.Player.Texts.DruidMana.Color == "" then
			r, g, b = color[1]*255,color[2]*255,color[3]*255
		elseif db.oUF.Player.Texts.DruidMana.Color == "" then
			r, g, b = color2[1]*255,color2[2]*255,color2[3]*255
		else
			r, g, b = db.oUF.Player.Texts.DruidMana.IndividualColor.r*255,db.oUF.Player.Texts.DruidMana.IndividualColor.g*255,db.oUF.Player.Texts.DruidMana.IndividualColor.b*255
		end

		if db.oUF.Player.Texts.DruidMana.Format == "Absolut" then
			text = format("%s/%s", min, max)
		elseif db.oUF.Player.Texts.DruidMana.Format == "Absolut & Percent" then
			text = format("%s/%s | %s", min, max, perc)
		elseif db.oUF.Player.Texts.DruidMana.Format == "Absolut Short" then
			text = format("%s/%s", ShortValue(min), ShortValue(max))
		elseif db.oUF.Player.Texts.DruidMana.Format == "Absolut Short & Percent" then
			text = format("%s/%s | %s", ShortValue(min), ShortValue(max), perc)
		elseif db.oUF.Player.Texts.DruidMana.Format == "Standard Short" then
			text = ShortValue(min)
		else
			text = min
		end

		return format("|cff%02x%02x%02x%s|r", r, g, b, text)
	end
end

------------------------------------------------------------------------
--	Custom Widget API
------------------------------------------------------------------------

local FormatName = function(self)
	if not self or not self.Info then return end

	local info = self.Info

	local name
	if info.Length == "Long" then
		name = "[NameLong]"
	elseif info.Length == "Short" then
		name = "[NameShort]"
	else
		name = "[NameMedium]"
	end

	if info.ColorNameByClass then name = "[GetNameColor]"..name.."|r" end

	local level = info.ColorLevelByDifficulty and "[DiffColor][level2]|r" or "[level2]"

	if info.ShowClassification then
		level = info.ShortClassification and level.."[shortclassification]" or level.."[classification]"
	end

	local race = "[race]"

	local class = info.ColorClassByClass and "[GetNameColor][smartclass]|r" or "[smartclass]"

	self:Tag(info, info.Format:gsub(" %+ ", " "):gsub("Name", name):gsub("Level", level):gsub("Race", race):gsub("Class", class))
	self:UpdateAllElements()
end
oUF:RegisterMetaFunction("FormatName", FormatName)

local FormatRaidName = function(self)
	if not self or not self.Info then return end

	local info = self.Info

	local index = self:GetParent():GetParent():GetName() == "oUF_LUI_raid_25" and 1 or 2
	local tag = self:GetParent():GetParent():GetName() == "oUF_LUI_raid_25" and "[RaidName25]" or "[RaidName40]"

	if info.ColorByClass then tag = "[GetNameColor]"..tag.."|r" end

	self:Tag(info, tag)
	self:UpdateAllElements()
end
oUF:RegisterMetaFunction("FormatRaidName", FormatRaidName)

------------------------------------------------------------------------
--	Style Func
------------------------------------------------------------------------

local SetStyle = function(self, unit, isSingle)
	local oufdb, ouf_xp_rep

	if unit == "player" or unit == "vehicle" then
		oufdb = db.oUF.Player
		ouf_xp_rep = db.oUF.XP_Rep
	elseif unit == "targettarget" then
		oufdb = db.oUF.ToT
	elseif unit == "targettargettarget" then
		oufdb = db.oUF.ToToT
	elseif unit == "target" then
		oufdb = db.oUF.Target
	elseif unit == "focustarget" then
		oufdb = db.oUF.FocusTarget
	elseif unit == "focus" then
		oufdb = db.oUF.Focus
	elseif unit == "pettarget" then
		oufdb = db.oUF.PetTarget
	elseif unit == "pet" then
		oufdb = db.oUF.Pet

	elseif unit == "party" then
		oufdb = db.oUF.Party
	elseif unit == "partytarget" then
		oufdb = db.oUF.PartyTarget
	elseif unit == "partypet" then
		oufdb = db.oUF.PartyPet

	elseif unit == "maintank" then
		oufdb = db.oUF.Maintank
	elseif unit == "maintanktarget" then
		oufdb = db.oUF.MaintankTarget
	elseif unit == "maintanktargettarget" then
		oufdb = db.oUF.MaintankToT

	elseif unit == unit:match("arena%d") then
		oufdb = db.oUF.Arena
	elseif unit == unit:match("arena%dtarget") then
		oufdb = db.oUF.ArenaTarget
	elseif unit == unit:match("arena%dpet") then
		oufdb = db.oUF.ArenaPet

	elseif unit == unit:match("boss%d") then
		oufdb = db.oUF.Boss
	elseif unit == unit:match("boss%dtarget") then
		oufdb = db.oUF.BossTarget

	elseif unit == "raid" then
		oufdb = db.oUF.Raid
	end

	self.menu = unit ~= "raid" and menu or nil
	self.colors = colors
	self:RegisterForClicks("AnyUp")

	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	self.MoveableFrames = ((isSingle and not unit:match("%d")) or unit == "party" or unit == "maintank" or unit == unit:match("%a+1"))

	self.SpellRange = true
	self.BarFade = false

	if isSingle then
		self:SetHeight(tonumber(oufdb.Height))
		self:SetWidth(tonumber(oufdb.Width))
	end

	------------------------------------------------------------------------
	--	Bars
	------------------------------------------------------------------------

	funcs.Health(self, unit, oufdb)
	funcs.Power(self, unit, oufdb)
	funcs.Full(self, unit, oufdb)
	funcs.FrameBackdrop(self, unit, oufdb)

	------------------------------------------------------------------------
	--	Texts
	------------------------------------------------------------------------

	-- creating a frame as anchor for icons, texts etc
	self.Overlay = CreateFrame("Frame", nil, self)
	self.Overlay:SetFrameLevel(8)
	self.Overlay:SetAllPoints(self.Health)
	
	if unit ~= "raid" then
		funcs.Info(self, unit, oufdb)
	else
		funcs.RaidInfo(self, unit, oufdb)
	end

	funcs.HealthValue(self, unit, oufdb)
	funcs.HealthPercent(self, unit, oufdb)
	funcs.HealthMissing(self, unit, oufdb)

	funcs.PowerValue(self, unit, oufdb)
	funcs.PowerPercent(self, unit, oufdb)
	funcs.PowerMissing(self, unit, oufdb)

	------------------------------------------------------------------------
	--	Icons
	------------------------------------------------------------------------

	if oufdb.Icons then
		if oufdb.Icons.Leader and oufdb.Icons.Leader.Enable then funcs.Leader(self, unit, oufdb) end
		if oufdb.Icons.Lootmaster and oufdb.Icons.Lootmaster.Enable then funcs.MasterLooter(self, unit, oufdb) end
		if oufdb.Icons.Raid and oufdb.Icons.Raid.Enable then funcs.RaidIcon(self, unit, oufdb) end
		if oufdb.Icons.Role and oufdb.Icons.Role.Enable then funcs.LFDRole(self, unit, oufdb) end
		if oufdb.Icons.PvP and oufdb.Icons.PvP.Enable then funcs.PvP(self, unit, oufdb) end
		if oufdb.Icons.Resting and oufdb.Icons.Resting.Enable then funcs.Resting(self, unit, oufdb) end
		if oufdb.Icons.Combat and oufdb.Icons.Combat.Enable then funcs.Combat(self, unit, oufdb) end
		if oufdb.Icons.ReadyCheck and oufdb.Icons.ReadyCheck.Enable then funcs.ReadyCheck(self, unit, oufdb) end
	end

	------------------------------------------------------------------------
	--	Player Specific Items
	------------------------------------------------------------------------

	if unit == "player" then
		if ouf_xp_rep.Experience.Enable then funcs.Experience(self, unit, ouf_xp_rep) end
		if ouf_xp_rep.Reputation.Enable then funcs.Reputation(self, unit, ouf_xp_rep) end

		if UnitLevel("player") == MAX_PLAYER_LEVEL then
			if self.XP then
				self.XP:Hide()
			end
			if self.Rep then
				self.Rep:SetScript("OnMouseUp", function(_, button)
					if button == "LeftButton" and GetWatchedFactionInfo() then
						local msgSent = false
						local name, standing, min, max, value = GetWatchedFactionInfo()
						for i=1, NUM_CHAT_WINDOWS do
							if _G["ChatFrame"..i.."EditBox"] then
								if _G["ChatFrame"..i.."EditBox"]:IsShown() then
									_G["ChatFrame"..i.."EditBox"]:Insert("Reputation with "..name..": "..value - min.." / "..max - min.." "..standings[standing].." ("..max - value.." remaining)")
									msgSent = true
									break
								end
							end
						end
						if msgSent == false then
							print("Reputation with "..name..": "..value - min.." / "..max - min.." "..standings[standing].." ("..max - value.." remaining)")
						end
					end
				end)
			end
		else
			if self.XP and self.Rep then
				self.Rep:Hide()
			end
			if self.XP then
				self.XP:SetScript("OnMouseUp", function(_, button)
					if button == "LeftButton" then
						local msgSent = false
						local level, value, max, rested = UnitLevel("player"), UnitXP("player"), UnitXPMax("player"), GetXPExhaustion()
						for i=1, NUM_CHAT_WINDOWS do
							if _G["ChatFrame"..i.."EditBox"] then
								if _G["ChatFrame"..i.."EditBox"]:IsShown() then
									if (rested and rested > 0) then
										_G["ChatFrame"..i.."EditBox"]:Insert("Experience into Level "..level..": "..value.." / "..max.." ("..max - value.." remaining), "..rested.." rested XP")
									else
										_G["ChatFrame"..i.."EditBox"]:Insert("Experience into Level "..level..": "..value.." / "..max.." ("..max - value.." remaining)")
									end
									msgSent = true
									break
								end
							end
						end
						if msgSent == false then
							if (rested and rested > 0) then
								print("Experience into Level "..level..": "..value.." / "..max.." ("..max - value.." remaining), "..rested.." rested XP")
							else
								print("Experience into Level "..level..": "..value.." / "..max.." ("..max - value.." remaining)")
							end
						end
					elseif button == "RightButton" and self.Rep and self.Rep.Enable then
						self.XP:Hide()
						self.Rep:Show()
					end
				end)
			end
			if self.Rep then
				self.Rep:SetScript("OnMouseUp", function(_, button)
					if button == "LeftButton" and GetWatchedFactionInfo() then
						local msgSent = false
						local name, standing, min, max, value = GetWatchedFactionInfo()
						for i=1, NUM_CHAT_WINDOWS do
							if _G["ChatFrame"..i.."EditBox"] then
								if _G["ChatFrame"..i.."EditBox"]:IsShown() then
									_G["ChatFrame"..i.."EditBox"]:Insert("Reputation with "..name..": "..value - min.." / "..max - min.." "..standings[standing].." ("..max - value.." remaining)")
									msgSent = true
									break
								end
							end
						end
						if msgSent == false then
							print("Reputation with "..name..": "..value - min.." / "..max - min.." "..standings[standing].." ("..max - value.." remaining)")
						end
					elseif button == "RightButton" and self.XP and self.XP.Enable and UnitLevel("player") ~= MAX_PLAYER_LEVEL then
						self.Rep:Hide()
						self.XP:Show()
					end
				end)
			end
		end

		if oufdb.Swing.Enable then funcs.Swing(self, unit, oufdb) end
		if class == "WARRIOR" then
			if oufdb.Vengeance.Enable then funcs.Vengeance(self, unit, oufdb) end
		elseif class == "DEATH KNIGHT" or class == "DEATHKNIGHT" then
			if oufdb.Vengeance.Enable then funcs.Vengeance(self, unit, oufdb) end
			if oufdb.Runes.Enable then funcs.Runes(self, unit, oufdb) end
		elseif class == "DRUID" then
			if oufdb.Vengeance.Enable then funcs.Vengeance(self, unit, oufdb) end
			if oufdb.Eclipse.Enable then funcs.EclipseBar(self, unit, oufdb) end
			if oufdb.DruidMana.Enable then funcs.DruidMana(self, unit, oufdb) end
		elseif class == "PALADIN" then
			if oufdb.Vengeance.Enable then funcs.Vengeance(self, unit, oufdb) end
			if oufdb.HolyPower.Enable then funcs.HolyPower(self, unit, oufdb) end
		elseif class == "SHAMAN" then
			if oufdb.Totems.Enable then funcs.TotemBar(self, unit, oufdb) end
		elseif class == "WARLOCK" then
			if oufdb.SoulShards.Enable then funcs.SoulShards(self, unit, oufdb) end
		end
		if oufdb.ThreatBar.Enable then funcs.ThreatBar(self, unit, oufdb) end
	end

	------------------------------------------------------------------------
	--	Target Specific Items
	------------------------------------------------------------------------

	if unit == "target" and oufdb.ComboPoints.Enable then funcs.CPoints(self, unit, oufdb) end

	------------------------------------------------------------------------
	--	Raid Specific Items
	------------------------------------------------------------------------

	if unit == "raid" then
		if oufdb.CornerAura.Enable then funcs.SingleAuras(self, unit, oufdb) end
		if oufdb.RaidDebuff.Enable then funcs.RaidDebuffs(self, unit, oufdb) end
	end

	------------------------------------------------------------------------
	--	Other
	------------------------------------------------------------------------

	if oufdb.Portrait.Enable then funcs.Portrait(self, unit, oufdb) end

	if unit == "player" or unit == "pet" then
		if db.oUF.Player.AltPower.Enable then funcs.AltPowerBar(self, unit, oufdb) end
	end

	if oufdb.Aura then
		if oufdb.Aura.buffs_enable then funcs.Buffs(self, unit, oufdb) end
		if oufdb.Aura.debuffs_enable then funcs.Debuffs(self, unit, oufdb) end
	end

	if oufdb.Texts.Combat then funcs.CombatFeedbackText(self, unit, oufdb) end
	if db.oUF.Settings.Castbars and oufdb.Castbar and oufdb.Castbar.Enable then funcs.Castbar(self, unit, oufdb) end
	if oufdb.Border.Aggro then funcs.AggroGlow(self, unit, oufdb) end
	if oufdb.HealPrediction and oufdb.HealPrediction.Enable then funcs.HealPrediction(self, unit, oufdb) end

	funcs.V2Textures(self, unit, oufdb)

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
				self:UpdateAllElements()
				self.elapsed = 0
			else
				self.elapsed = self.elapsed + elapsed
			end
		end)
	end

	local LUI_Fader = LUI:GetModule("Fader", true)
	if oufdb.Fader and oufdb.Fader.Enable and LUI_Fader then LUI_Fader:RegisterFrame(self, oUF.Fader) end
	
	if unit == "raid" or (unit == "party" and oufdb.RangeFade and LUI_Fader and oufdb.Fader and not oufdb.Fader.Enable) then
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

-- the spawn functions are in the module oUF, so we dont need to write all the code twice
-- "subframes" of groups, like party target are included within the party toggle
-- has to be OnEnable
function module:OnEnable()
	db = LUI.db.profile

	if db.oUF.Settings.Enable ~= true then
		LUI:GetModule("oUF"):SetBlizzardRaidFrames()
		return
	end
	
	-- remove with LUI v3.6 or something like that!
	if LUICONFIG.Versions.ouf ~= LUI_versions.ouf then	
		for _, oufdb in pairs(db.oUF) do
			if type(oufdb) == "table" and oufdb.Health then
				oufdb.Health.Y = oufdb.Health.Padding or oufdb.Health.Y
				oufdb.Health.Width = oufdb.Width
				
				oufdb.Power.Y = tostring(oufdb.Health.Y - oufdb.Health.Height + (oufdb.Power.Padding or -2))
				oufdb.Power.Width = oufdb.Width
				
				oufdb.Full.Y = tostring(oufdb.Health.Y - oufdb.Health.Height + (oufdb.Full.Padding or -2))
				oufdb.Full.Width = oufdb.Width
				
				if oufdb.AltPower then
					oufdb.AltPower.Y = tostring(oufdb.Power.Y - oufdb.Power.Height + (oufdb.AltPower.Padding or -2))
					oufdb.AltPower.Width = oufdb.Width
					
					oufdb.AltPower.Padding = nil
				end
				
				if oufdb.DruidMana then
					oufdb.DruidMana.Y = tostring(oufdb.Power.Y - oufdb.Power.Height + (oufdb.DruidMana.Padding or -2))
					oufdb.DruidMana.Width = oufdb.Width
					
					oufdb.DruidMana.Padding = nil
				end
				
				oufdb.Health.Padding = nil
				oufdb.Power.Padding = nil
				oufdb.Full.Padding = nil
			end
		end

		LUICONFIG.Versions.ouf = LUI_versions.ouf
	end
	
	-- hmm
	oUF.colors.smooth = LUI.oUF.colors.smooth or oUF.colors.smooth

	-- spawning
	local spawnList = {"Player", "Target", "Focus", "FocusTarget", "ToT", "ToToT", "Pet", "PetTarget", "Boss", "Party", "Maintank", "Arena", "Raid"}
	for _, unit in pairs(spawnList) do LUI:GetModule("oUF"):Toggle(unit) end
end
