------------------------------------------------------------------------
--	oUF LUI Layout
--	Version 3.6.1
-- 	Date: 08/30/2011
--	DO NOT USE THIS LAYOUT WITHOUT LUI
------------------------------------------------------------------------

local addonname, LUI = ...
local module = LUI:Module("Unitframes")
local Forte = LUI:Module("Forte")
local Fader = LUI:Module("Fader")

local L = LUI.L
local Blizzard = LUI.Blizzard

local oUF = LUI.oUF

local Media = LibStub("LibSharedMedia-3.0")

local db, colors

------------------------------------------------------------------------
--	Textures and Medias
------------------------------------------------------------------------

local mediaPath = [=[Interface\Addons\LUI\media\]=]

local floor = math.floor
local format = string.format
local GetGlyphSocketInfo = GetGlyphSocketInfo 


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

local channelingTicks -- base time between ticks
do
	local classChannels = {
		DRUID = {
			[GetSpellInfo(740)] = 2, -- Tranquility
			[GetSpellInfo(16914)] = 1, -- Hurricane
		},
		MAGE = {
			[GetSpellInfo(10)] = 1, -- Blizzard
			[GetSpellInfo(12051)] = 2, -- Evocation
			-- [GetSpellInfo(5143)] = 0.75, -- Arcane Missiles			located below do to talents affecting time between ticks
		},
		PRIEST = {
			[GetSpellInfo(15407)] = 1, -- Mind Flay
			[GetSpellInfo(48045)] = 1, -- Mind Sear
			[GetSpellInfo(64843)] = 2, -- Divine Hymn
			[GetSpellInfo(64901)] = 2, -- Hymn of Hope
			[GetSpellInfo(47540)] = 1, -- Penance
		},
		SHAMAN = {
			[GetSpellInfo(61882)] = 1, -- Earthquake
		},
		WARLOCK = {
			[GetSpellInfo(1120)] = 3, -- Drain Soul
			[GetSpellInfo(689)] = 1, -- Drain Life
			[GetSpellInfo(755)] = 1, -- Health Funnel
--			[GetSpellInfo(79268)] = 1, -- Soul Harvest
			[GetSpellInfo(5740)] = 2, -- Rain of Fire
			[GetSpellInfo(1949)] = 1, -- Hellfire
		},
	}

	channelingTicks = {
		["First Aid"] = 1 -- Bandages
	}
	if classChannels[class] then
		for k, v in pairs(classChannels[class]) do
			channelingTicks[k] = v
		end
	end
	wipe(classChannels)

	-- if class == "MAGE" then
		-- local arcaneMissiles = GetSpellInfo(5143)
-- 
		-- local function talentUpdate()
			-- local rank = select(5, GetTalentInfo(1, 10)) -- Missile Barrage talent
			-- channelingTicks[arcaneMissiles] = rank == 0 and 0.75 or (0.7 - (rank / 10))
		-- end
-- 
		-- module:RegisterEvent("PLAYER_TALENT_UPDATE", talentUpdate)
		-- talentUpdate()
	-- end
end

local menu
do
	local removeMenuOptions = {
		SET_FOCUS = "LUI_SET_FOCUS",
		CLEAR_FOCUS = "LUI_CLEAR_FOCUS",
		LOCK_FOCUS_FRAME = true,
		UNLOCK_FOCUS_FRAME = true,
	}

	local insertMenuOptions = {
		SELF = {
			"LUI_ROLE_CHECK",
			"LUI_READY_CHECK",
		},
	}

	UnitPopupButtons["LUI_SET_FOCUS"] = {
		text = L["Type %s to Set Focus"]:format(SLASH_FOCUS1),
		tooltipText = L["Blizzard does not support right-click focus"],
		dist = 0,
	}
	UnitPopupButtons["LUI_CLEAR_FOCUS"] = {
		text = L["Type %s to Clear Focus"]:format(SLASH_CLEARFOCUS1),
		tooltipText = L["Blizzard does not support right-click focus"],
		dist = 0,
	}
	UnitPopupButtons["LUI_ROLE_CHECK"] = {
		text = ROLE_POLL,
		tooltipText = L["Initiate a role check"],
		dist = 0,
	}
	UnitPopupButtons["LUI_READY_CHECK"] = {
		text = READY_CHECK,
		tooltipText = L["Initiate a ready check"],
		dist = 0,
	}

	hooksecurefunc("UnitPopup_OnClick", function(self)
		local button = self.value
		if button == "LUI_ROLE_CHECK" then
			InitiateRolePoll()
		elseif button == "LUI_READY_CHECK" then
			DoReadyCheck()
		end
	end)

	hooksecurefunc("UnitPopup_HideButtons", function()
		local dropdownMenu = UIDROPDOWNMENU_INIT_MENU
		local inParty, inRaid, inBG, isLeader, isAssist = GetNumSubgroupMembers() > 0, GetNumGroupMembers() > 0, UnitInBattleground("player"), UnitIsGroupLeader("unit" or "player name"), UnitIsGroupAssistant("unit" or "player name")
		if inRaid then
			inParty = true
		end

		for i, v in ipairs(UnitPopupMenus[UIDROPDOWNMENU_MENU_VALUE] or UnitPopupMenus[dropdownMenu.which]) do
			if v == "LUI_ROLE_CHECK" or v == "LUI_READY_CHECK" then
				if (not isLeader and not isAssist) or inBG or (not inParty and not inRaid) then
					UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][i] = 0
				end
			end
		end
	end)

	local dropdown = CreateFrame("Frame", "LUI_UnitFrame_DropDown", UIParent, "UIDropDownMenuTemplate")
	UnitPopupFrames[#UnitPopupFrames+1] = "LUI_UnitFrame_DropDown"

	local function getMenuUnit(unit)
		if unit == "focus" then return "FOCUS" end

		if UnitIsUnit(unit, "player") then return "SELF" end

		if UnitIsUnit(unit, "vehicle") then return "VEHICLE" end

		if UnitIsUnit(unit, "pet") then return "PET" end

		if not UnitIsPlayer(unit) then return "TARGET" end

		local id = UnitInRaid(unit)
		if id then
			return "RAID_PLAYER", id
		end

		if UnitInParty(unit) then
			return "PARTY"
		end

		return "PLAYER"
	end

	local unitDropDownMenus = {}
	local function getUnitDropDownMenu(unit)
		local menu = unitDropDownMenus[unit]
		if menu then return menu end

		if not UnitPopupMenus then
			unitDropDownMenus[unit] = unit
			return unit
		end

		local data = UnitPopupMenus[unit]
		if not data then
			unitDropDownMenus[unit] = unit
			return unit
		end

		local found = false
		for _, v in pairs(data) do
			if removeMenuOptions[v] then
				found = true
				break
			end
		end

		local insert = insertMenuOptions[unit]

		if not found and not insert then -- nothing to add or remove
			unitDropDownMenus[unit] = unit
			return unit
		end

		local newData = {}
		for _, v in ipairs(data) do
			local blacklisted = removeMenuOptions[v]
			if not blacklisted then
				if insert and v == "CANCEL" then
					for _, extra in ipairs(insert) do
						tinsert(newData, extra)
					end
				end
				tinsert(newData, v)
			elseif blacklisted ~= true then
				tinsert(newData, blacklisted)
			end
		end

		local newMenuName = "LUI_" .. unit
		UnitPopupMenus[newMenuName] = newData
		unitDropDownMenus[unit] = newMenuName
		return newMenuName
	end

	local dropdown_unit
	UIDropDownMenu_Initialize(dropdown, function(frame)
		if not dropdown_unit then return end

		local unit, id = getMenuUnit(dropdown_unit)
		if unit then
			local menu = getUnitDropDownMenu(unit)
			UnitPopup_ShowMenu(frame, menu, dropdown_unit, nil, id)
		end
	end, "MENU")

	menu = function(self, unit)
		dropdown_unit = unit
		ToggleDropDownMenu(1, nil, dropdown, "cursor")
	end
end

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
--[[
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
]]
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
		if module.db.Player.Bars.Health.Color == "By Class" then
			health:SetStatusBarColor(unpack(color))
		elseif module.db.Player.Bars.Health.Color == "Individual" then
			health:SetStatusBarColor(module.db.Player.Bars.Health.IndividualColor.r, module.db.Player.Bars.Health.IndividualColor.g, module.db.Player.Bars.Health.IndividualColor.b)
		else
			health:SetStatusBarColor(oUF.ColorGradient(min/max, module.colors.smooth()))
		end
	else
		if health.color == "By Class" then
			health:SetStatusBarColor(unpack(color))
		elseif health.color == "Individual" then
			health:SetStatusBarColor(health.colorIndividual.r, health.colorIndividual.g, health.colorIndividual.b)
		else
			health:SetStatusBarColor(oUF.ColorGradient(min/max, module.colors.smooth()))
		end
	end

	if health.colorTapping and UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) then health:SetStatusBarColor(unpack(module.db.Colors.Misc["Tapped"])) end

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
					health.value:SetFormattedText("%d/%d", min, max)
				elseif health.value.Format == "Absolut & Percent" then
					health.value:SetFormattedText("%d/%d | %.1f%%", min, max, healthPercent)
				elseif health.value.Format == "Absolut Short" then
					health.value:SetFormattedText("%s/%s", ShortValue(min), ShortValue(max))
				elseif health.value.Format == "Absolut Short & Percent" then
					health.value:SetFormattedText("%s/%s | %.1f%%", ShortValue(min),ShortValue(max), healthPercent)
				elseif health.value.Format == "Standard" then
					health.value:SetFormattedText("%d", min)
				elseif health.value.Format == "Standard & Percent" then
					health.value:SetFormattedText("%d | %.1f%%", min, healthPercent)
				elseif health.value.Format == "Standard Short" then
					health.value:SetFormattedText("%s", ShortValue(min))
				elseif health.value.Format == "Standard Short & Percent" then
					health.value:SetFormattedText("%s | %.1f%%", ShortValue(min), healthPercent)
				else
					health.value:SetFormattedText("%d", min)
				end

				if health.value.color == "By Class" then
					health.value:SetTextColor(unpack(color))
				elseif health.value.color == "Individual" then
					health.value:SetTextColor(health.value.colorIndividual.r, health.value.colorIndividual.g, health.value.colorIndividual.b)
				else
					health.value:SetTextColor(oUF.ColorGradient(min/max, module.colors.smooth()))
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
				health.valuePercent:SetTextColor(oUF.ColorGradient(min/max, module.colors.smooth()))
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
					health.valueMissing:SetFormattedText("-%d", healthMissing)
				end
			else
				health.valueMissing:SetText()
			end

			if health.valueMissing.color == "By Class" then
				health.valueMissing:SetTextColor(unpack(color))
			elseif health.valueMissing.color == "Individual" then
				health.valueMissing:SetTextColor(health.valueMissing.colorIndividual.r, health.valueMissing.colorIndividual.g, health.valueMissing.colorIndividual.b)
			else
				health.valueMissing:SetTextColor(oUF.ColorGradient(min/max, module.colors.smooth()))
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
	local _, r, g, b = UnitAlternatePowerTextureInfo(unit, 2)

	if unit == "player" and entering == true then
		if module.db.Player.Bars.Power.Color == "By Class" then
			power:SetStatusBarColor(unpack(color))
		elseif module.db.Player.Bars.Power.Color == "Individual" then
			power:SetStatusBarColor(module.db.Player.Bars.Power.IndividualColor.r, module.db.Player.Bars.Power.IndividualColor.g, module.db.Player.Bars.Power.IndividualColor.b)
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

local PostUpdateAura = function(icons, unit, icon, index, offset, filter, isDebuff, duration, timeLeft)
	local _, _, _, _, dtype, duration, expirationTime, unitCaster, _ = UnitAura(unit, index, icon.filter)
	if not (unitCaster == "player" or unitCaster == "pet" or unitCaster == "vehicle") then
		if icon.debuff then
			icon.icon:SetDesaturated(icons.fadeOthers)
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
		if unit == "focus" or unit == "pet" then unit = "player" end
		local pClass, pToken = UnitClass(unit)
		local color = module.colors.class[pToken]

		castbar:SetStatusBarColor(color[1], color[2], color[3], 0.68)
		castbar.bg:SetVertexColor(0.15, 0.15, 0.15, 0.75)
		castbar.Backdrop:SetBackdropBorderColor(0, 0, 0, 0.7)
	end

	if castbar.interrupt and UnitCanAttack("player", unit) and castbar.Colors.ShieldEnable then
		castbar:SetStatusBarColor(castbar.Colors.Shield.r, castbar.Colors.Shield.g, castbar.Colors.Shield.b, castbar.Colors.Shield.a)
		if castbar.Shield then
			castbar.IconOverlay:Hide()
			castbar.Shield:Show()
		end
	else
		castbar.IconOverlay:Show()
		castbar.Shield:Hide()
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

local ShadowOrbsOverride = function(self, event, unit, powerType)
	if self.unit ~= unit or (powerType and powerType ~= "SHADOW_ORBS") then return end

	local num = UnitPower(unit, SPELL_POWER_SHADOW_ORBS)

	for i = 1, 3 do
		if i <= num then
			self.ShadowOrbs[i]:SetAlpha(1)
		else
			self.ShadowOrbs[i]:SetAlpha(.4)
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

	 local num = UnitPower(unit, SPELL_POWER_HOLY_POWER)
	 for i = 1, self.HolyPower.Powers do
		 if i <= num then
			 self.HolyPower[i]:SetAlpha(1)
		 else
			 self.HolyPower[i]:SetAlpha(.4)
		 end
	 end
end

local ChiOverride = function(self, event, unit, powerType)
	if self.unit ~= unit or (powerType and powerType ~= "LIGHT_FORCE") then return end

	 local num = UnitPower(unit, SPELL_POWER_LIGHT_FORCE)
	 for i = 1, self.Chi.Force do
		 if i <= num then
			 self.Chi[i]:SetAlpha(1)
		 else
			 self.Chi[i]:SetAlpha(.4)
		 end
	 end
end

local PostEclipseUpdate = function(self, unit)
	if self.ShowText then
		if GetEclipseDirection() == "sun" then
			self.LunarText:SetText(50+math.floor((UnitPower("player", SPELL_POWER_ECLIPSE)+1)/2))
			self.LunarText:SetTextColor(unpack(module.colors.eclipsebar.LunarBG))
			self.SolarText:SetText("Starfire!")
			self.SolarText:SetTextColor(unpack(module.colors.eclipsebar.LunarBG))
		elseif GetEclipseDirection() == "moon" then
			self.LunarText:SetText("Wrath!")
			self.LunarText:SetTextColor(unpack(module.colors.eclipsebar.SolarBG))
			self.SolarText:SetText(50-math.floor((UnitPower("player", SPELL_POWER_ECLIPSE)+1)/2))
			self.SolarText:SetTextColor(unpack(module.colors.eclipsebar.SolarBG))
		elseif self:IsShown() then
			self.LunarText:SetText(50+math.floor((UnitPower("player", SPELL_POWER_ECLIPSE)+1)/2))
			self.LunarText:SetTextColor(unpack(module.colors.eclipsebar.SolarBG))
			self.SolarText:SetText(50-math.floor((UnitPower("player", SPELL_POWER_ECLIPSE)+1)/2))
			self.SolarText:SetTextColor(unpack(module.colors.eclipsebar.LunarBG))
		end
	end
end

local EclipseBarBuff = function(self, unit)
	if GetEclipseDirection() == "sun" then
		self.LunarBar:SetAlpha(1)
		self.SolarBar:SetAlpha(0.7)
		self.LunarBar:SetStatusBarColor(unpack(module.colors.eclipsebar.Lunar))
		self.SolarBar:SetStatusBarColor(unpack(module.colors.eclipsebar.SolarBG))
	elseif GetEclipseDirection() == "moon" then
		self.SolarBar:SetAlpha(1)
		self.LunarBar:SetAlpha(0.7)
		self.LunarBar:SetStatusBarColor(unpack(module.colors.eclipsebar.LunarBG))
		self.SolarBar:SetStatusBarColor(unpack(module.colors.eclipsebar.Solar))
	elseif self:IsShown() then
		self.LunarBar:SetAlpha(1)
		self.SolarBar:SetAlpha(1)
		self.LunarBar:SetStatusBarColor(unpack(module.colors.eclipsebar.LunarBG))
		self.SolarBar:SetStatusBarColor(unpack(module.colors.eclipsebar.SolarBG))
	end
end

local PostUpdateAltPower = function(altpowerbar, min, cur, max)
	local pClass, pToken = UnitClass("player")
	local color = module.colors.class[pToken] or {0.5, 0.5, 0.5}

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

local PostUpdateDruidMana = function(druidmana, unit, min, max)
	if druidmana.color == "By Class" then
		druidmana.ManaBar:SetStatusBarColor(unpack(module.colors.class.DRUID))
	elseif druidmana.color == "By Type" then
		druidmana.ManaBar:SetStatusBarColor(unpack(module.colors.power.MANA))
	else
		druidmana.ManaBar:SetStatusBarColor(oUF.ColorGradient(min/max, module.colors.smooth()))
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
	fromT, fromB = fromT * fromS, fromB * fromS
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
		self.Health.frequentUpdates = false
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
		self.Power.displayAltPower = unit == unit:match("boss%d")

		if oufdb.Bars.Power.Enable == true then
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

		self.Full:SetHeight(oufdb.Bars.Full.Height)
		self.Full:SetWidth(oufdb.Bars.Full.Width * self:GetWidth() / oufdb.Width) -- needed for 25/40 man raid width downscaling!
		self.Full:SetStatusBarTexture(Media:Fetch("statusbar", oufdb.Bars.Full.Texture))
		self.Full:SetStatusBarColor(oufdb.Bars.Full.IndividualColor.r, oufdb.Bars.Full.IndividualColor.g, oufdb.Bars.Full.IndividualColor.b, oufdb.Bars.Full.IndividualColor.a)
		self.Full:ClearAllPoints()
		self.Full:SetPoint("TOPLEFT", self, "TOPLEFT", oufdb.Bars.Full.X * self:GetWidth() / oufdb.Width, oufdb.Bars.Full.Y) -- needed for 25/40 man raid width downscaling!
		self.Full:SetAlpha(oufdb.Bars.Full.Alpha)

		if oufdb.Bars.Full.Enable == true then
			self.Full:Show()
		else
			self.Full:Hide()
		end
	end,
	FrameBackdrop = function(self, unit, oufdb)
		if not self.FrameBackdrop then self.FrameBackdrop = CreateFrame("Frame", nil, self) end

		self.FrameBackdrop:ClearAllPoints()
		self.FrameBackdrop:SetPoint("TOPLEFT", self, "TOPLEFT", oufdb.Backdrop.Padding.Left, oufdb.Backdrop.Padding.Top)
		self.FrameBackdrop:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", oufdb.Backdrop.Padding.Right, oufdb.Backdrop.Padding.Bottom)
		self.FrameBackdrop:SetFrameStrata("BACKGROUND")
		self.FrameBackdrop:SetFrameLevel(20)
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

	-- icons
	Leader = function(self, unit, oufdb)
		if not self.Leader then
			self.Leader = self.Overlay:CreateTexture(nil, "OVERLAY")
			self.Assistant = self.Overlay:CreateTexture(nil, "OVERLAY")
		end

		self.Leader:SetHeight(oufdb.Icons.Leader.Size)
		self.Leader:SetWidth(oufdb.Icons.Leader.Size)
		self.Leader:ClearAllPoints()
		self.Leader:SetPoint(oufdb.Icons.Leader.Point, self, oufdb.Icons.Leader.Point, oufdb.Icons.Leader.X, oufdb.Icons.Leader.Y)

		self.Assistant:SetHeight(oufdb.Icons.Leader.Size)
		self.Assistant:SetWidth(oufdb.Icons.Leader.Size)
		self.Assistant:ClearAllPoints()
		self.Assistant:SetPoint(oufdb.Icons.Leader.Point, self, oufdb.Icons.Leader.Point, oufdb.Icons.Leader.X, oufdb.Icons.Leader.Y)
	end,
	MasterLooter = function(self, unit, oufdb)
		if not self.MasterLooter then self.MasterLooter = self.Overlay:CreateTexture(nil, "OVERLAY") end

		self.MasterLooter:SetHeight(oufdb.Icons.Lootmaster.Size)
		self.MasterLooter:SetWidth(oufdb.Icons.Lootmaster.Size)
		self.MasterLooter:ClearAllPoints()
		self.MasterLooter:SetPoint(oufdb.Icons.Lootmaster.Point, self, oufdb.Icons.Lootmaster.Point, oufdb.Icons.Lootmaster.X, oufdb.Icons.Lootmaster.Y)
	end,
	RaidIcon = function(self, unit, oufdb)
		if not self.RaidIcon then
			self.RaidIcon = self.Overlay:CreateTexture(nil, "OVERLAY")
			self.RaidIcon:SetTexture("Interface\\AddOns\\LUI\\media\\textures\\icons\\raidicons.blp")
		end

		self.RaidIcon:SetHeight(oufdb.Icons.Raid.Size)
		self.RaidIcon:SetWidth(oufdb.Icons.Raid.Size)
		self.RaidIcon:ClearAllPoints()
		self.RaidIcon:SetPoint(oufdb.Icons.Raid.Point, self, oufdb.Icons.Raid.Point, oufdb.Icons.Raid.X, oufdb.Icons.Raid.Y)
	end,
	LFDRole = function(self, unit, oufdb)
		if not self.LFDRole then self.LFDRole = self.Overlay:CreateTexture(nil, "OVERLAY") end

		self.LFDRole:SetHeight(oufdb.Icons.Role.Size)
		self.LFDRole:SetWidth(oufdb.Icons.Role.Size)
		self.LFDRole:ClearAllPoints()
		self.LFDRole:SetPoint(oufdb.Icons.Role.Point, self, oufdb.Icons.Role.Point, oufdb.Icons.Role.X, oufdb.Icons.Role.Y)
	end,
	PvP = function(self, unit, oufdb)
		if not self.PvP then
			self.PvP = self.Overlay:CreateTexture(nil, "OVERLAY")
			if unit == "player" then
				self.PvP.Timer = SetFontString(self.Overlay, Media:Fetch("font", oufdb.Texts.PvP.Font), oufdb.Texts.PvP.Size, oufdb.Texts.PvP.Outline)
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
							self.PvP.Timer:SetFormattedText("%d:%.2d", min, sec)
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
		self.PvP:SetPoint(oufdb.Icons.PvP.Point, self, oufdb.Icons.PvP.Point, oufdb.Icons.PvP.X, oufdb.Icons.PvP.Y)

		if self.PvP.Timer then
			self.PvP.Timer:SetFont(Media:Fetch("font", oufdb.Texts.PvP.Font), oufdb.Texts.PvP.Size, oufdb.Texts.PvP.Outline)
			self.PvP.Timer:SetPoint("CENTER", self.PvP, "CENTER", oufdb.Texts.PvP.X, oufdb.Texts.PvP.Y)
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
		self.Resting:SetPoint(oufdb.Icons.Resting.Point, self, oufdb.Icons.Resting.Point, oufdb.Icons.Resting.X, oufdb.Icons.Resting.Y)
	end,
	Combat = function(self, unit, oufdb)
		if not self.Combat then self.Combat = self.Overlay:CreateTexture(nil, "OVERLAY") end

		self.Combat:SetHeight(oufdb.Icons.Combat.Size)
		self.Combat:SetWidth(oufdb.Icons.Combat.Size)
		self.Combat:ClearAllPoints()
		self.Combat:SetPoint(oufdb.Icons.Combat.Point, self, oufdb.Icons.Combat.Point, oufdb.Icons.Combat.X, oufdb.Icons.Combat.Y)
	end,
	ReadyCheck = function(self, unit, oufdb)
		if not self.ReadyCheck then self.ReadyCheck = self.Overlay:CreateTexture(nil, "OVERLAY") end

		self.ReadyCheck:SetHeight(oufdb.Icons.ReadyCheck.Size)
		self.ReadyCheck:SetWidth(oufdb.Icons.ReadyCheck.Size)
		self.ReadyCheck:ClearAllPoints()
		self.ReadyCheck:SetPoint(oufdb.Icons.ReadyCheck.Point, self, oufdb.Icons.ReadyCheck.Point, oufdb.Icons.ReadyCheck.X, oufdb.Icons.ReadyCheck.Y)
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

			self.Experience.Value = SetFontString(self.Experience, Media:Fetch("font", ouf_xp_rep.General.Font), ouf_xp_rep.General.FontSize, ouf_xp_rep.General.FontFlag)
			self.Experience.Value:SetAllPoints(self.XP)
			self.Experience.Value:SetFontObject(GameFontHighlight)

			self.Experience.Rested = CreateFrame("StatusBar", nil, self.Experience)
			self.Experience.Rested:SetAllPoints(self.XP)
			self.Experience.Rested:SetStatusBarTexture(normTex)

			self.Experience.bg = self.XP:CreateTexture(nil, "BACKGROUND")
			self.Experience.bg:SetAllPoints(self.XP)
			self.Experience.bg:SetTexture(normTex)

			self.Experience.Override = function(_, event, unit)
				if(self.unit ~= unit) then return end
				if unit == "vehicle" then unit = "player" end

				local value, max = UnitXP(unit), UnitXPMax(unit)

				self.Experience:SetMinMaxValues(0, max)
				self.Experience:SetValue(value)

				local exhaustion = unit == "player" and GetXPExhaustion() or 0
				self.Experience.Rested:SetMinMaxValues(0, max)
				self.Experience.Rested:SetValue(math.min(value + exhaustion, max))

				self.Experience.Value:SetFormattedText("%d / %d (%d%%)", value, max, math.floor((value / max) * 100 + 0.5))
			end

			if UnitLevel("player") == MAX_PLAYER_LEVEL then
				self.XP:Hide()
			else
				self.XP:RegisterEvent("PLAYER_LEVEL_UP")
				self.XP:SetScript("OnEvent", function(_, event, level)
					if level == MAX_PLAYER_LEVEL then
						self.XP:Hide()
						if self.Rep and ouf_xp_rep.Reputation.Enable then
							self.Rep:Show()
						end
					end
				end)
			end

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

			self.XP:SetScript("OnMouseUp", function(_, button)
				if button == "LeftButton" then
					local level, value, max, rested = UnitLevel("player"), UnitXP("player"), UnitXPMax("player"), GetXPExhaustion()
					local msg = "Experience into Level "..level..": "..value.." / "..max.." ("..max - value.." remaining)"..((rested and rested > 0) and (", "..rested.." rested XP") or "")
					for i=1, NUM_CHAT_WINDOWS do
						local editbox = _G["ChatFrame"..i.."EditBox"]
						if editbox and editbox:IsShown() then
							editbox:Insert(msg)
							return
						end
					end
					print(msg)
				elseif button == "RightButton" and self.Rep and self.Rep.Enable then
					self.XP:Hide()
					self.Rep:Show()
				end
			end)

			self.XP.Enable = true
		end

		self.Experience:SetStatusBarColor(ouf_xp_rep.Experience.FillColor.r, ouf_xp_rep.Experience.FillColor.g, ouf_xp_rep.Experience.FillColor.b, ouf_xp_rep.Experience.FillColor.a)

		self.Experience.Value:SetFont(Media:Fetch("font", ouf_xp_rep.General.Font), ouf_xp_rep.General.FontSize, ouf_xp_rep.General.FontFlag)
		self.Experience.Value:SetJustifyH(ouf_xp_rep.General.FontJustify)
		self.Experience.Value:SetTextColor(ouf_xp_rep.General.FontColor.r, ouf_xp_rep.General.FontColor.g, ouf_xp_rep.General.FontColor.b, ouf_xp_rep.General.FontColor.a)

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

			self.Reputation.Value = SetFontString(self.Reputation, Media:Fetch("font", ouf_xp_rep.General.Font), ouf_xp_rep.General.FontSize, ouf_xp_rep.General.FontFlag)
			self.Reputation.Value:SetAllPoints(self.Rep)
			self.Reputation.Value:SetFontObject(GameFontHighlight)

			self.Reputation.bg = self.Reputation:CreateTexture(nil, "BACKGROUND")
			self.Reputation.bg:SetAllPoints(self.Rep)
			self.Reputation.bg:SetTexture(normTex)

			self.Reputation.Override = function()
				local name, standing, min, max, value = GetWatchedFactionInfo()
				if name then
					self.Reputation:SetMinMaxValues(min, max)
					self.Reputation:SetValue(value)

					self.Reputation.Value:SetFormattedText("%d / %d (%d%%)", value - min, max - min, math.floor(((value - min) / (max - min)) * 100 + 0.5))
				else
					self.Reputation:SetMinMaxValues(0, 100)
					self.Reputation:SetValue(0)

					self.Reputation.Value:SetText()
				end
			end

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

			self.Rep:SetScript("OnMouseUp", function(_, button)
				if button == "LeftButton" then
					local name, standing, min, max, value = GetWatchedFactionInfo()
					if not name then return end

					local msg = "Reputation with "..name..": "..value - min.." / "..max - min.." "..standings[standing].." ("..max - value.." remaining)"
					for i=1, NUM_CHAT_WINDOWS do
						local editbox = _G["ChatFrame"..i.."EditBox"]
						if editbox and editbox:IsShown() then
							editbox:Insert(msg)
							return
						end
					end
					print(msg)
				elseif button == "RightButton" and self.XP and self.XP.Enable and UnitLevel("player") ~= MAX_PLAYER_LEVEL then
					self.Rep:Hide()
					self.XP:Show()
				end
			end)

			self.Rep.Enable = true
		end

		self.Reputation:SetStatusBarColor(ouf_xp_rep.Reputation.FillColor.r, ouf_xp_rep.Reputation.FillColor.g, ouf_xp_rep.Reputation.FillColor.b, ouf_xp_rep.Reputation.FillColor.a)

		self.Reputation.Value:SetFont(Media:Fetch("font", ouf_xp_rep.General.Font), ouf_xp_rep.General.FontSize, ouf_xp_rep.General.FontFlag)
		self.Reputation.Value:SetJustifyH(ouf_xp_rep.General.FontJustify)
		self.Reputation.Value:SetTextColor(ouf_xp_rep.General.FontColor.r, ouf_xp_rep.General.FontColor.g, ouf_xp_rep.General.FontColor.b, ouf_xp_rep.General.FontColor.a)

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

		local x = oufdb.Bars.Totems.Lock and 0 or oufdb.Bars.Totems.X
		local y = oufdb.Bars.Totems.Lock and 0.5 or oufdb.Bars.Totems.Y

		self.TotemBar:SetHeight(oufdb.Bars.Totems.Height)
		self.TotemBar:SetWidth(oufdb.Bars.Totems.Width)
		self.TotemBar:ClearAllPoints()
		self.TotemBar:SetPoint("BOTTOMLEFT", self, "TOPLEFT", x, y)
		self.TotemBar.colors = module.colors.totembar

		local totemPoints = {2, 0, 1, 3}

		for i = 1, 4 do
			self.TotemBar[i]:SetStatusBarTexture(Media:Fetch("statusbar", oufdb.Bars.Totems.Texture))
			self.TotemBar[i]:SetHeight(oufdb.Bars.Totems.Height)
			self.TotemBar[i]:SetWidth((oufdb.Bars.Totems.Width - 3 * oufdb.Bars.Totems.Padding) / 4)

			self.TotemBar[i]:ClearAllPoints()
			if totemPoints[i] == 0 then
				self.TotemBar[i]:SetPoint("LEFT", self.TotemBar, "LEFT", 0, 0)
			else
				self.TotemBar[i]:SetPoint("LEFT", self.TotemBar[totemPoints[i]], "RIGHT", oufdb.Bars.Totems.Padding, 0)
			end

			self.TotemBar[i].bg.multiplier = oufdb.Bars.Totems.Multiplier
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

		local x = oufdb.Bars.Runes.Lock and 0 or oufdb.Bars.Runes.X
		local y = oufdb.Bars.Runes.Lock and 0.5 or oufdb.Bars.Runes.Y

		self.Runes:SetHeight(oufdb.Bars.Runes.Height)
		self.Runes:SetWidth(oufdb.Bars.Runes.Width)
		self.Runes:ClearAllPoints()
		self.Runes:SetPoint("BOTTOMLEFT", self, "TOPLEFT", x, y)

		local runePoints = {0, 1, 6, 3, 2, 5}

		for i = 1, 6 do
			self.Runes[i]:SetStatusBarTexture(Media:Fetch("statusbar", oufdb.Bars.Runes.Texture))
			self.Runes[i]:SetStatusBarColor(unpack(module.colors.runes[math.floor((i+1)/2)]))
			self.Runes[i]:SetSize(((oufdb.Bars.Runes.Width - 5 * oufdb.Bars.Runes.Padding) / 6), oufdb.Bars.Runes.Height)

			self.Runes[i]:ClearAllPoints()
			if runePoints[i] == 0 then
				self.Runes[i]:SetPoint("LEFT", self.Runes, "LEFT", 0, 0)
			else
				self.Runes[i]:SetPoint("LEFT", self.Runes[runePoints[i]], "RIGHT", oufdb.Bars.Runes.Padding, 0)
			end
		end
	end,
	HolyPower = function(self, unit, oufdb)
		if not self.HolyPower then
			self.HolyPower = CreateFrame("Frame", nil, self)
			self.HolyPower:SetFrameLevel(6)
			self.HolyPower.Powers = 3

			for i = 1, 5 do -- Always create frames for the max possible
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

		local x = oufdb.Bars.HolyPower.Lock and 0 or oufdb.Bars.HolyPower.X
		local y = oufdb.Bars.HolyPower.Lock and 0.5 or oufdb.Bars.HolyPower.Y

		self.HolyPower:SetHeight(oufdb.Bars.HolyPower.Height)
		self.HolyPower:SetWidth(oufdb.Bars.HolyPower.Width)
		self.HolyPower:ClearAllPoints()
		self.HolyPower:SetPoint("BOTTOMLEFT", self, "TOPLEFT", x, y)
	
		local function checkPowers(event, level)
			local pLevel = (event == "UNIT_LEVEL") and tonumber(level) or UnitLevel("player")
			if pLevel >= 85 then 
				self.HolyPower.Powers = 5
				module:UnregisterEvent("UNIT_LEVEL")
			else self.HolyPower.Powers = 3
			end

			for i = 1, 5 do
				self.HolyPower[i]:SetStatusBarTexture(Media:Fetch("statusbar", oufdb.Bars.HolyPower.Texture))
				self.HolyPower[i]:SetStatusBarColor(unpack(module.colors.holypowerbar[i]))
				self.HolyPower[i]:SetSize(((oufdb.Bars.HolyPower.Width - 2*oufdb.Bars.HolyPower.Padding) / self.HolyPower.Powers), oufdb.Bars.HolyPower.Height)

				self.HolyPower[i]:ClearAllPoints()
				if i == 1 then
					self.HolyPower[i]:SetPoint("LEFT", self.HolyPower, "LEFT", 0, 0)
				else
					self.HolyPower[i]:SetPoint("LEFT", self.HolyPower[i-1], "RIGHT", oufdb.Bars.HolyPower.Padding, 0)
				end
				self.HolyPower[i]:Show()
				if i > self.HolyPower.Powers then
					self.HolyPower[i]:Hide()
				end
			end
		end
		checkPowers()

		module:RegisterEvent("UNIT_LEVEL", checkPowers)
	end,
	
	Chi = function(self, unit, oufdb)
		if not self.Chi then
			self.Chi = CreateFrame("Frame", nil, self)
			self.Chi:SetFrameLevel(6)
			self.Chi.Force = 4

			for i = 1, 5 do -- Always create frames for the max possible
				self.Chi[i] = CreateFrame("StatusBar", nil, self.Chi)
				self.Chi[i]:SetBackdrop(backdrop)
				self.Chi[i]:SetBackdropColor(0.08, 0.08, 0.08)
				self.Chi[i]:SetAlpha(.4)
			end

			self.Chi.FrameBackdrop = CreateFrame("Frame", nil, self.Chi)
			self.Chi.FrameBackdrop:SetPoint("TOPLEFT", self.Chi, "TOPLEFT", -3.5, 3)
			self.Chi.FrameBackdrop:SetPoint("BOTTOMRIGHT", self.Chi, "BOTTOMRIGHT", 3.5, -3)
			self.Chi.FrameBackdrop:SetFrameStrata("BACKGROUND")
			self.Chi.FrameBackdrop:SetBackdrop({
				edgeFile = glowTex, edgeSize = 5,
				insets = {left = 3, right = 3, top = 3, bottom = 3}
			})
			self.Chi.FrameBackdrop:SetBackdropColor(0, 0, 0, 0)
			self.Chi.FrameBackdrop:SetBackdropBorderColor(0, 0, 0)

			self.Chi.Override = ChiOverride
		end

		local x = oufdb.Bars.Chi.Lock and 0 or oufdb.Bars.Chi.X
		local y = oufdb.Bars.Chi.Lock and 0.5 or oufdb.Bars.Chi.Y

		self.Chi:SetHeight(oufdb.Bars.Chi.Height)
		self.Chi:SetWidth(oufdb.Bars.Chi.Width)
		self.Chi:ClearAllPoints()
		self.Chi:SetPoint("BOTTOMLEFT", self, "TOPLEFT", x, y)
	
		local function checkChi(event)
			local ascension = select(5, GetTalentInfo(8)) -- Ascension
			if ascension then 
				self.Chi.Force = 5
			else self.Chi.Force = 4
			end

			for i = 1, 5 do
				self.Chi[i]:SetStatusBarTexture(Media:Fetch("statusbar", oufdb.Bars.Chi.Texture))
				self.Chi[i]:SetStatusBarColor(unpack(module.colors.chibar[i]))
				self.Chi[i]:SetSize(((oufdb.Bars.Chi.Width - 2*oufdb.Bars.Chi.Padding) / self.Chi.Force), oufdb.Bars.Chi.Height)

				self.Chi[i]:ClearAllPoints()
				if i == 1 then
					self.Chi[i]:SetPoint("LEFT", self.Chi, "LEFT", 0, 0)
				else
					self.Chi[i]:SetPoint("LEFT", self.Chi[i-1], "RIGHT", oufdb.Bars.Chi.Padding, 0)
				end
				self.Chi[i]:Show()
				if i > self.Chi.Force then
					self.Chi[i]:Hide()
				end
			end
		end
		checkChi()

		module:RegisterEvent("PLAYER_TALENT_UPDATE", checkChi)
	end,

	WarlockBar = function(self, unit, oufdb)
	
		if not self.WarlockBar then
			self.WarlockBar = CreateFrame("Frame", nil, self)
			self.WarlockBar:SetFrameLevel(6)
			
			self.WarlockBar.SpecInfo = {
				{ maxValue = 1, Amount = 3, AmountGlyph = 4, glyph = 63302, powerType = "SOUL_SHARDS", unitPower = SPELL_POWER_SOUL_SHARDS, }, -- Affliction
				{ maxValue = 1000, Amount = 1, powerType = "DEMONIC_FURY", unitPower = SPELL_POWER_DEMONIC_FURY, }, -- Demonology
				{ maxValue = 10, Amount = 3, AmountGlyph = 4, glyph = 63304, powerType = "BURNING_EMBERS", unitPower = SPELL_POWER_BURNING_EMBERS, }, -- Destruction
			}
			self.WarlockBar.SpecInfo[1].BarColors = { "Shard1", "Shard2", "Shard3", "Shard4" }
			self.WarlockBar.SpecInfo[2].BarColors = { "Fury", "Fury", "Fury", "Fury" } -- Four time just to not have to add an additional check
			self.WarlockBar.SpecInfo[3].BarColors = { "Ember1", "Ember2", "Ember3", "Ember4" }

			for i = 1, 4 do -- Create the max so we dont have to worry about it later.
				self.WarlockBar[i] = CreateFrame("StatusBar", nil, self.WarlockBar)
				self.WarlockBar[i]:SetBackdrop(backdrop)
				self.WarlockBar[i]:SetMinMaxValues(0,0)
				self.WarlockBar[i]:SetBackdropColor(0.08, 0.08, 0.08)

				self.WarlockBar[i]:SetAlpha(.4)
				
			end

			self.WarlockBar.Text = SetFontString(self.WarlockBar[1], Media:Fetch("font", oufdb.Texts.WarlockBar.Font), oufdb.Texts.WarlockBar.Size, oufdb.Texts.WarlockBar.Outline)
			self.WarlockBar.FrameBackdrop = CreateFrame("Frame", nil, self.WarlockBar)
			self.WarlockBar.FrameBackdrop:SetPoint("TOPLEFT", self.WarlockBar, "TOPLEFT", -3.5, 3)
			self.WarlockBar.FrameBackdrop:SetPoint("BOTTOMRIGHT", self.WarlockBar, "BOTTOMRIGHT", 3.5, -3)
			self.WarlockBar.FrameBackdrop:SetFrameStrata("BACKGROUND")
			self.WarlockBar.FrameBackdrop:SetBackdrop({
				edgeFile = glowTex, edgeSize = 5,
				insets = {left = 3, right = 3, top = 3, bottom = 3}
			})
			self.WarlockBar.FrameBackdrop:SetBackdropColor(0, 0, 0, 0)
			self.WarlockBar.FrameBackdrop:SetBackdropBorderColor(0, 0, 0)

			self.WarlockBar.Override = WarlockBarOverride
		end

		local x = oufdb.Bars.WarlockBar.Lock and 0 or oufdb.Bars.WarlockBar.X
		local y = oufdb.Bars.WarlockBar.Lock and 0.5 or oufdb.Bars.WarlockBar.Y

		self.WarlockBar:SetHeight(oufdb.Bars.WarlockBar.Height)
		self.WarlockBar:SetWidth(oufdb.Bars.WarlockBar.Width)
		self.WarlockBar:ClearAllPoints()
		self.WarlockBar:SetPoint("BOTTOMLEFT", self, "TOPLEFT", x, y)
		local function checkBar(event)

			local spec = self.WarlockBar.SpecInfo[GetSpecialization()]
			if not spec then
				self.WarlockBar:Hide()
				return
			else
				if oufdb.Bars.WarlockBar.Enable then
					self.WarlockBar:Show()
				end
			end
			self.WarlockBar.Amount = spec.Amount

			if spec.glyph then
				local glyphFound = false
				for i=1, 6 do
					local _, _, _, glyphSpell = GetGlyphSocketInfo(i)
					if glyphSpell == spec.glyph then
						glyphFound = true
						if self.WarlockBar then self.WarlockBar.Amount = spec.AmountGlyph end
					end
				end
				if self.WarlockBar and not glyphFound then self.WarlockBar.Amount = spec.Amount end
			end
			for i = 1, 4 do
				self.WarlockBar[i]:SetMinMaxValues(0,spec.maxValue)
				self.WarlockBar[i]:SetStatusBarTexture(Media:Fetch("statusbar", oufdb.Bars.WarlockBar.Texture))
				self.WarlockBar[i]:SetStatusBarColor(unpack(module.colors.WarlockBar[spec.BarColors[i]])) 
				self.WarlockBar[i]:SetSize(((oufdb.Bars.WarlockBar.Width - 2*oufdb.Bars.WarlockBar.Padding) / self.WarlockBar.Amount), oufdb.Bars.WarlockBar.Height)
				
				self.WarlockBar[i]:ClearAllPoints()
				self.WarlockBar[i]:Show()
				if i == 1 then
					self.WarlockBar[i]:SetPoint("LEFT", self.WarlockBar, "LEFT", 0, 0)
				else
					self.WarlockBar[i]:SetPoint("LEFT", self.WarlockBar[i-1], "RIGHT", oufdb.Bars.WarlockBar.Padding, 0)
				end
				if i > self.WarlockBar.Amount then 
					self.WarlockBar[i]:Hide() 
				end
			end
			self.WarlockBar.Text:SetFont(Media:Fetch("font", oufdb.Texts.WarlockBar.Font), oufdb.Texts.WarlockBar.Size, oufdb.Texts.WarlockBar.Outline)
			self.WarlockBar.Text:ClearAllPoints()
			self.WarlockBar.Text:SetPoint("LEFT", self.WarlockBar, "LEFT", oufdb.Texts.WarlockBar.X, oufdb.Texts.WarlockBar.Y)
			self.WarlockBar.ShowText = oufdb.Texts.WarlockBar.Enable
			if oufdb.Texts.WarlockBar.Enable == true then
				self.WarlockBar.Text:Show()
			else
				self.WarlockBar.Text:Hide()
			end
			WarlockBarOverride(self, "event", unit, spec.powerType)
		end
		checkBar()
		module:RegisterEvent("GLYPH_ADDED", checkBar)
		module:RegisterEvent("GLYPH_REMOVED", checkBar)
		module:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", checkBar)
	end,
	ArcaneCharges = function(self, unit, oufdb)
	
		if not self.ArcaneCharges then
			self.ArcaneCharges = CreateFrame("Frame", nil, self)
			self.ArcaneCharges:SetFrameLevel(6)

			self.ArcaneCharges.Charges = 6
			self.ArcaneCharges.Refresh = false

			for i = 1, self.ArcaneCharges.Charges do
				self.ArcaneCharges[i] = CreateFrame("StatusBar", nil, self.ArcaneCharges)
				self.ArcaneCharges[i]:SetBackdrop(backdrop)
				self.ArcaneCharges[i]:SetMinMaxValues(0,0)
				self.ArcaneCharges[i]:SetBackdropColor(0.08, 0.08, 0.08)

				self.ArcaneCharges[i]:SetAlpha(.4)
			end

			self.ArcaneCharges.FrameBackdrop = CreateFrame("Frame", nil, self.ArcaneCharges)
			self.ArcaneCharges.FrameBackdrop:SetPoint("TOPLEFT", self.ArcaneCharges, "TOPLEFT", -3.5, 3)
			self.ArcaneCharges.FrameBackdrop:SetPoint("BOTTOMRIGHT", self.ArcaneCharges, "BOTTOMRIGHT", 3.5, -3)
			self.ArcaneCharges.FrameBackdrop:SetFrameStrata("BACKGROUND")
			self.ArcaneCharges.FrameBackdrop:SetBackdrop({
				edgeFile = glowTex, edgeSize = 5,
				insets = {left = 3, right = 3, top = 3, bottom = 3}
			})
			self.ArcaneCharges.FrameBackdrop:SetBackdropColor(0, 0, 0, 0)
			self.ArcaneCharges.FrameBackdrop:SetBackdropBorderColor(0, 0, 0)

			self.ArcaneCharges.Override = ArcaneChargesOverride
		end

		local x = oufdb.Bars.ArcaneCharges.Lock and 0 or oufdb.Bars.ArcaneCharges.X
		local y = oufdb.Bars.ArcaneCharges.Lock and 0.5 or oufdb.Bars.ArcaneCharges.Y

		self.ArcaneCharges:SetHeight(oufdb.Bars.ArcaneCharges.Height)
		self.ArcaneCharges:SetWidth(oufdb.Bars.ArcaneCharges.Width)
		self.ArcaneCharges:ClearAllPoints()
		self.ArcaneCharges:SetPoint("BOTTOMLEFT", self, "TOPLEFT", x, y)
		
		for i = 1, self.ArcaneCharges.Charges do
			self.ArcaneCharges[i]:SetStatusBarTexture(Media:Fetch("statusbar", oufdb.Bars.ArcaneCharges.Texture))
			self.ArcaneCharges[i]:SetStatusBarColor(unpack(module.colors.arcanechargesbar[i]))
			self.ArcaneCharges[i]:SetSize(((oufdb.Bars.ArcaneCharges.Width - 2*oufdb.Bars.ArcaneCharges.Padding) / self.ArcaneCharges.Charges), oufdb.Bars.ArcaneCharges.Height)

			self.ArcaneCharges[i]:ClearAllPoints()
			self.ArcaneCharges[i]:Show()
			if i == 1 then
				self.ArcaneCharges[i]:SetPoint("LEFT", self.ArcaneCharges, "LEFT", 0, 0)
			else
				self.ArcaneCharges[i]:SetPoint("LEFT", self.ArcaneCharges[i-1], "RIGHT", oufdb.Bars.ArcaneCharges.Padding, 0)
			end
		end
			
		local function checkSpec(event)
			if GetSpecialization() == 1 then self.ArcaneCharges:Show()
			else self.ArcaneCharges:Hide()
			end
		end
		checkSpec()
		module:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", checkSpec)
	end,

	ShadowOrbs = function(self, unit, oufdb)
		if not self.ShadowOrbs then
			self.ShadowOrbs = CreateFrame("Frame", nil, self)
			self.ShadowOrbs:SetFrameLevel(6)

			self.ShadowOrbs.Orbs = 0

			for i = 1, 3 do -- Only 3 shadow orbs.
				self.ShadowOrbs[i] = CreateFrame("StatusBar", nil, self.ShadowOrbs)
				self.ShadowOrbs[i]:SetBackdrop(backdrop)
				self.ShadowOrbs[i]:SetBackdropColor(0.08, 0.08, 0.08)

				self.ShadowOrbs[i]:SetAlpha(.4)
			end

			self.ShadowOrbs.FrameBackdrop = CreateFrame("Frame", nil, self.ShadowOrbs)
			self.ShadowOrbs.FrameBackdrop:SetPoint("TOPLEFT", self.ShadowOrbs, "TOPLEFT", -3.5, 3)
			self.ShadowOrbs.FrameBackdrop:SetPoint("BOTTOMRIGHT", self.ShadowOrbs, "BOTTOMRIGHT", 3.5, -3)
			self.ShadowOrbs.FrameBackdrop:SetFrameStrata("BACKGROUND")
			self.ShadowOrbs.FrameBackdrop:SetBackdrop({
				edgeFile = glowTex, edgeSize = 5,
				insets = {left = 3, right = 3, top = 3, bottom = 3}
			})
			self.ShadowOrbs.FrameBackdrop:SetBackdropColor(0, 0, 0, 0)
			self.ShadowOrbs.FrameBackdrop:SetBackdropBorderColor(0, 0, 0)

			self.ShadowOrbs.Override = ShadowOrbsOverride
		end

		local x = oufdb.Bars.ShadowOrbs.Lock and 0 or oufdb.Bars.ShadowOrbs.X
		local y = oufdb.Bars.ShadowOrbs.Lock and 0.5 or oufdb.Bars.ShadowOrbs.Y

		self.ShadowOrbs:SetHeight(oufdb.Bars.ShadowOrbs.Height)
		self.ShadowOrbs:SetWidth(oufdb.Bars.ShadowOrbs.Width)
		self.ShadowOrbs:ClearAllPoints()
		self.ShadowOrbs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", x, y)
		
		local function checkOrbs(event)
			local pLevel = (event == "UNIT_LEVEL") and tonumber(level) or UnitLevel("player")
			if GetSpecialization() == 3 then
				if pLevel >= 21 then 
					self.ShadowOrbs.Orbs = 3
					module:UnregisterEvent("UNIT_LEVEL")
				else self.ShadowOrbs.Orbs = 0
				end
			else self.ShadowOrbs.Orbs = 0
			end
			
			for i = 1, 3 do
				self.ShadowOrbs[i]:SetStatusBarTexture(Media:Fetch("statusbar", oufdb.Bars.ShadowOrbs.Texture))
				self.ShadowOrbs[i]:SetStatusBarColor(unpack(module.colors.shadoworbsbar[i]))
				self.ShadowOrbs[i]:SetSize(((oufdb.Bars.ShadowOrbs.Width - 2*oufdb.Bars.ShadowOrbs.Padding) / 3), oufdb.Bars.ShadowOrbs.Height)

				self.ShadowOrbs[i]:ClearAllPoints()
				self.ShadowOrbs[i]:Show()
				if i == 1 then
					self.ShadowOrbs[i]:SetPoint("LEFT", self.ShadowOrbs, "LEFT", 0, 0)
				else
					self.ShadowOrbs[i]:SetPoint("LEFT", self.ShadowOrbs[i-1], "RIGHT", oufdb.Bars.ShadowOrbs.Padding, 0)
				end

				if self.ShadowOrbs.Orbs == 0 then
					self.ShadowOrbs:Hide()
				else self.ShadowOrbs:Show()
				end
			end
			
		end
		checkOrbs()
		module:RegisterEvent("UNIT_LEVEL", checkOrbs)
		module:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", checkOrbs)
	end,
	
	EclipseBar = function(self, unit, oufdb)
		if not self.EclipseBar then
			self.EclipseBar = CreateFrame("Frame", nil, self)
			self.EclipseBar:SetFrameLevel(6)
			self.EclipseBar.PostUnitAura = EclipseBarBuff
			self.EclipseBar.PostUpdatePower = PostEclipseUpdate

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

			if Forte then
				self.EclipseBar.PostUpdateVisibility = function() if self:GetLeft() then Forte:SetPosForte() end end
			end

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

			self.EclipseBar.LunarText = SetFontString(self.EclipseBar.LunarBar, Media:Fetch("font", oufdb.Texts.Eclipse.Font), oufdb.Texts.Eclipse.Size, oufdb.Texts.Eclipse.Outline)
			self.EclipseBar.SolarText = SetFontString(self.EclipseBar.SolarBar, Media:Fetch("font", oufdb.Texts.Eclipse.Font), oufdb.Texts.Eclipse.Size, oufdb.Texts.Eclipse.Outline)
		end

		local x = oufdb.Bars.Eclipse.Lock and 0 or oufdb.Bars.Eclipse.X
		local y = oufdb.Bars.Eclipse.Lock and 0.5 or oufdb.Bars.Eclipse.Y

		self.EclipseBar:SetHeight(oufdb.Bars.Eclipse.Height)
		self.EclipseBar:SetWidth(oufdb.Bars.Eclipse.Width)
		self.EclipseBar:ClearAllPoints()
		self.EclipseBar:SetPoint("BOTTOMLEFT", self, "TOPLEFT", x, y)

		self.EclipseBar.LunarBar:SetStatusBarTexture(Media:Fetch("statusbar", oufdb.Bars.Eclipse.Texture))
		self.EclipseBar.LunarBar:SetStatusBarColor(unpack(module.colors.eclipsebar.Lunar))

		self.EclipseBar.SolarBar:SetWidth(oufdb.Bars.Eclipse.Width)
		self.EclipseBar.SolarBar:SetStatusBarTexture(Media:Fetch("statusbar", oufdb.Bars.Eclipse.Texture))
		self.EclipseBar.SolarBar:SetStatusBarColor(unpack(module.colors.eclipsebar.Solar))

		self.EclipseBar.LunarText:SetFont(Media:Fetch("font", oufdb.Texts.Eclipse.Font), oufdb.Texts.Eclipse.Size, oufdb.Texts.Eclipse.Outline)
		self.EclipseBar.LunarText:ClearAllPoints()
		self.EclipseBar.LunarText:SetPoint("LEFT", self.EclipseBar, "LEFT", oufdb.Texts.Eclipse.X, oufdb.Texts.Eclipse.Y)

		self.EclipseBar.SolarText:SetFont(Media:Fetch("font", oufdb.Texts.Eclipse.Font), oufdb.Texts.Eclipse.Size, oufdb.Texts.Eclipse.Outline)
		self.EclipseBar.SolarText:ClearAllPoints()
		self.EclipseBar.SolarText:SetPoint("RIGHT", self.EclipseBar, "RIGHT", - oufdb.Texts.Eclipse.X, oufdb.Texts.Eclipse.Y)
		
		self.EclipseBar.ShowText = oufdb.Texts.Eclipse.Enable
		if oufdb.Texts.Eclipse.Enable == true then
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
				if not module.db.Player.Bars.AltPower.OverPower then return end

				if oUF_LUI_player.AltPowerBar:IsShown() or (oUF_LUI_pet and oUF_LUI_pet.AltPowerBar and oUF_LUI_pet.AltPowerBar:IsShown()) then
					oUF_LUI_player.Power:SetHeight(module.db.Player.Bars.Power.Height/2 - 1)
					oUF_LUI_player.AltPowerBar:SetHeight(module.db.Player.Bars.Power.Height/2 - 1)
				else
					oUF_LUI_player.Power:SetHeight(module.db.Player.Bars.Power.Height)
					oUF_LUI_player.AltPowerBar:SetHeight(module.db.Player.Bars.AltPower.Height)
				end
			end

			self.AltPowerBar:SetScript("OnShow", function()
				self.AltPowerBar.SetPosition()
				self.AltPowerBar:ForceUpdate()
			end)
			self.AltPowerBar:SetScript("OnHide", self.AltPowerBar.SetPosition)

			self.AltPowerBar.Text = SetFontString(self.AltPowerBar, Media:Fetch("font", module.db.Player.Texts.AltPower.Font), module.db.Player.Texts.AltPower.Size, module.db.Player.Texts.AltPower.Outline)
		end

		self.AltPowerBar:ClearAllPoints()
		if unit == "player" then
			if module.db.Player.Bars.AltPower.OverPower then
				self.AltPowerBar:SetPoint("TOPLEFT", self.Power, "BOTTOMLEFT", 0, -2)
				self.AltPowerBar:SetPoint("TOPRIGHT", self.Power, "BOTTOMRIGHT", 0, -2)
			else
				self.AltPowerBar:SetPoint("TOPLEFT", self, "TOPLEFT", module.db.Player.Bars.AltPower.X, module.db.Player.Bars.AltPower.Y)
			end
		else
			self.AltPowerBar:SetPoint("TOPLEFT", oUF_LUI_player.AltPowerBar, "TOPLEFT", 0, 0)
			self.AltPowerBar:SetPoint("BOTTOMRIGHT", oUF_LUI_player.AltPowerBar, "BOTTOMRIGHT", 0, 0)
		end

		self.AltPowerBar:SetHeight(module.db.Player.Bars.AltPower.Height)
		self.AltPowerBar:SetWidth(module.db.Player.Bars.AltPower.Width)
		self.AltPowerBar:SetStatusBarTexture(Media:Fetch("statusbar", module.db.Player.Bars.AltPower.Texture))

		self.AltPowerBar.bg:SetTexture(Media:Fetch("statusbar", module.db.Player.Bars.AltPower.TextureBG))
		self.AltPowerBar.bg:SetAlpha(module.db.Player.Bars.AltPower.BGAlpha)
		self.AltPowerBar.bg.multiplier = module.db.Player.Bars.AltPower.BGMultiplier

		self.AltPowerBar.Smooth = module.db.Player.Bars.AltPower.Smooth
		self.AltPowerBar.color = module.db.Player.Bars.AltPower.Color
		self.AltPowerBar.colorIndividual = module.db.Player.Bars.AltPower.IndividualColor
		
		self.AltPowerBar.Text:SetFont(Media:Fetch("font", module.db.Player.Texts.AltPower.Font), module.db.Player.Texts.AltPower.Size, module.db.Player.Texts.AltPower.Outline)
		self.AltPowerBar.Text:ClearAllPoints()
		self.AltPowerBar.Text:SetPoint("CENTER", self.AltPowerBar, "CENTER", module.db.Player.Texts.AltPower.X, module.db.Player.Texts.AltPower.Y)

		self.AltPowerBar.Text.Enable = module.db.Player.Texts.AltPower.Enable
		self.AltPowerBar.Text.Format = module.db.Player.Texts.AltPower.Format
		self.AltPowerBar.Text.color = module.db.Player.Texts.AltPower.Color
		self.AltPowerBar.Text.colorIndividual = module.db.Player.Texts.AltPower.IndividualColor

		if module.db.Player.Texts.AltPower.Enable then
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

			self.DruidMana.Smooth = oufdb.Bars.DruidMana.Smooth

			self.DruidMana.value = SetFontString(self.DruidMana.ManaBar, Media:Fetch("font", oufdb.Texts.DruidMana.Font), oufdb.Texts.DruidMana.Size, oufdb.Texts.DruidMana.Outline)
			self:Tag(self.DruidMana.value, "[druidmana2]")

			self.DruidMana.SetPosition = function()
				if not oufdb.Bars.DruidMana.OverPower then return end

				if self.DruidMana:IsShown() then
					self.Power:SetHeight(oufdb.Bars.Power.Height/2 - 1)
					self.DruidMana:SetHeight(oufdb.Bars.DruidMana.Height/2 - 1)
				else
					self.Power:SetHeight(oufdb.Bars.Power.Height)
					self.DruidMana:SetHeight(oufdb.Bars.DruidMana.Height)
				end
			end

			self.DruidMana:SetScript("OnShow", self.DruidMana.SetPosition)
			self.DruidMana:SetScript("OnHide", self.DruidMana.SetPosition)

			self.DruidMana.PostUpdatePower = PostUpdateDruidMana
		end

		self.DruidMana:ClearAllPoints()
		if oufdb.Bars.DruidMana.OverPower then
			self.DruidMana:SetPoint("TOPLEFT", self.Power, "BOTTOMLEFT", 0, -2)
			self.DruidMana:SetPoint("TOPRIGHT", self.Power, "BOTTOMRIGHT", 0, -2)
		else
			self.Power:SetHeight(oufdb.Bars.Power.Height)
			self.DruidMana:SetPoint("TOPLEFT", self, "TOPLEFT", module.db.Player.Bars.DruidMana.X, module.db.Player.Bars.DruidMana.Y)
		end

		self.DruidMana:SetHeight(oufdb.Bars.DruidMana.Height)
		self.DruidMana:SetWidth(oufdb.Bars.DruidMana.Width)
		self.DruidMana.ManaBar:SetStatusBarTexture(Media:Fetch("statusbar", oufdb.Bars.DruidMana.Texture))

		self.DruidMana.value:SetFont(Media:Fetch("font", oufdb.Texts.DruidMana.Font), oufdb.Texts.DruidMana.Size, oufdb.Texts.DruidMana.Outline)
		self.DruidMana.value:SetPoint("CENTER", self.DruidMana.ManaBar, "CENTER")

		if oufdb.Texts.DruidMana.Enable == true then
			self.DruidMana.value:Show()
		else
			self.DruidMana.value:Hide()
		end

		self.DruidMana.color = oufdb.Bars.DruidMana.Color

		self.DruidMana.bg:SetTexture(Media:Fetch("statusbar", oufdb.Bars.DruidMana.TextureBG))
		self.DruidMana.bg:SetAlpha(oufdb.Bars.DruidMana.BGAlpha)
		self.DruidMana.bg.multiplier = oufdb.Bars.DruidMana.BGMultiplier

		if GetShapeshiftFormID() == CAT_FORM or GetShapeshiftFormID() == BEAR_FORM then self.DruidMana.SetPosition() end
	end,

	-- target specific
	CPoints = function(self, unit, oufdb)
		if not self.CPoints then
			self.CPoints = CreateFrame("Frame", nil, self)
			self.CPoints:SetFrameLevel(6)

			for i = 1, 5 do
				self.CPoints[i] = CreateFrame("StatusBar", nil, self.CPoints)
				self.CPoints[i]:SetBackdrop(backdrop)
				self.CPoints[i]:SetBackdropColor(0, 0, 0)
				self.CPoints[i]:SetMinMaxValues(0, 1)

				self.CPoints[i].bg = self.CPoints[i]:CreateTexture(nil, "BORDER")
				self.CPoints[i].bg:SetAllPoints(self.CPoints[i])
			end

			-- if Forte then
			-- self.CPoints[1]:SetScript("OnShow", function() Forte:SetPosForte() end)
			-- self.CPoints[1]:SetScript("OnHide", function() Forte:SetPosForte() end)
			-- end

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
		self.CPoints:SetPoint("BOTTOMLEFT", self, "TOPLEFT", oufdb.Bars.ComboPoints.X, oufdb.Bars.ComboPoints.Y)
		self.CPoints:SetHeight(oufdb.Bars.ComboPoints.Height)
		self.CPoints:SetWidth(oufdb.Bars.ComboPoints.Width)
		self.CPoints.showAlways = oufdb.Bars.ComboPoints.ShowAlways

		for i = 1, 5 do
			self.CPoints[i]:ClearAllPoints()
			if i == 1 then
				self.CPoints[i]:SetPoint("LEFT", self.CPoints, "LEFT", 0, 0)
			else
				self.CPoints[i]:SetPoint("LEFT", self.CPoints[i-1], "RIGHT", 1, 0)
			end

			self.CPoints[i]:SetStatusBarTexture(Media:Fetch("statusbar", oufdb.Bars.ComboPoints.Texture))
			self.CPoints[i]:SetStatusBarColor(unpack(module.colors.combopoints[i]))
			self.CPoints[i]:SetHeight(oufdb.Bars.ComboPoints.Height)
			self.CPoints[i]:SetWidth((oufdb.Bars.ComboPoints.Width - 4 * oufdb.Bars.ComboPoints.Padding) / 5)

			self.CPoints[i].bg:SetTexture(Media:Fetch("statusbar", oufdb.Bars.ComboPoints.Texture))
			self.CPoints[i].bg.multiplier = oufdb.Bars.ComboPoints.Multiplier

			if oufdb.Bars.ComboPoints.IndividualBGColor == true then
				self.CPoints[i].bg:SetVertexColor(oufdb.Bars.ComboPoints.BackgroundColor.r, oufdb.Bars.ComboPoints.BackgroundColor.g, oufdb.Bars.ComboPoints.BackgroundColor.b)
			else
				local mu = oufdb.Bars.ComboPoints.Multiplier
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

		self.RaidDebuffs:SetHeight(oufdb.RaidDebuff.Size)
		self.RaidDebuffs:SetWidth(oufdb.RaidDebuff.Size)
	end,

	-- others
	Portrait = function(self, unit, oufdb)
		if not self.Portrait then
			self.Portrait = CreateFrame("PlayerModel", nil, self)
			self.Portrait:SetFrameLevel(5)
			self.Portrait.Override = PortraitOverride
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
		self.Buffs.showStealableBuffs = (unit ~= "player" and (class == "MAGE" or class == "SHAMAN"))
		self.Buffs.showAuraType = oufdb.Aura.Buffs.ColorByType
		self.Buffs.showAuratimer = oufdb.Aura.Buffs.AuraTimer
		self.Buffs.disableCooldown = oufdb.Aura.Buffs.DisableCooldown
		self.Buffs.cooldownReverse = oufdb.Aura.Buffs.CooldownReverse

		self.Buffs.PostCreateIcon = PostCreateAura
		self.Buffs.PostUpdateIcon = PostUpdateAura
		self.Buffs.CustomFilter = CustomFilter
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
		self.Debuffs.showStealableBuffs = (unit ~= "player" and (class == "MAGE" or class == "SHAMAN"))
		self.Debuffs.showAuraType = oufdb.Aura.Debuffs.ColorByType
		self.Debuffs.showAuratimer = oufdb.Aura.Debuffs.AuraTimer
		self.Debuffs.disableCooldown = oufdb.Aura.Debuffs.DisableCooldown
		self.Debuffs.cooldownReverse = oufdb.Aura.Debuffs.CooldownReverse

		self.Debuffs.PostCreateIcon = PostCreateAura
		self.Debuffs.PostUpdateIcon = PostUpdateAura
		self.Debuffs.CustomFilter = CustomFilter
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

			castbar.Backdrop = CreateFrame("Frame", nil, self)
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

			if unit == "player" or unit == "target" or unit == "focus" or unit == "pet" then
				castbar.Icon = castbar:CreateTexture(nil, "ARTWORK")
				castbar.Icon:SetHeight(28.5)
				castbar.Icon:SetWidth(28.5)
				castbar.Icon:SetTexCoord(0, 1, 0, 1)
				castbar.Icon:SetPoint("LEFT", -41.5, 0)

				castbar.IconOverlay = castbar:CreateTexture(nil, "OVERLAY")
				castbar.IconOverlay:SetPoint("TOPLEFT", castbar.Icon, "TOPLEFT", -1.5, 1)
				castbar.IconOverlay:SetPoint("BOTTOMRIGHT", castbar.Icon, "BOTTOMRIGHT", 1, -1)
				castbar.IconOverlay:SetTexture(buttonTex)
				castbar.IconOverlay:SetVertexColor(1, 1, 1)

				castbar.IconBackdrop = CreateFrame("Frame", nil, castbar)
				castbar.IconBackdrop:SetPoint("TOPLEFT", castbar.Icon, "TOPLEFT", -4, 3)
				castbar.IconBackdrop:SetPoint("BOTTOMRIGHT", castbar.Icon, "BOTTOMRIGHT", 3, -3.5)
				castbar.IconBackdrop:SetBackdrop({
					edgeFile = glowTex, edgeSize = 4,
					insets = {left = 3, right = 3, top = 3, bottom = 3}
				})
				castbar.IconBackdrop:SetBackdropColor(0, 0, 0, 0)
				castbar.IconBackdrop:SetBackdropBorderColor(0, 0, 0, 0.7)

				castbar.Shield = castbar:CreateTexture(nil, "OVERLAY")
				castbar.Shield:SetPoint("TOPLEFT", castbar.Icon, "TOPLEFT", -15, 30)
				castbar.Shield:SetPoint("BOTTOMRIGHT", castbar.Icon, "BOTTOMRIGHT", 45, -30)
				castbar.Shield:SetTexture("Interface\\CastingBar\\UI-CastingBar-Arena-Shield")
				castbar.Shield:SetVertexColor(1, 1, 1)
			else
				castbar.Icon = castbar:CreateTexture(nil, "ARTWORK")
				castbar.Icon:SetHeight(20)
				castbar.Icon:SetWidth(20)
				castbar.Icon:SetTexCoord(0, 1, 0, 1)
				if unit == unit:match("arena%d") then
					castbar.Icon:SetPoint("RIGHT", 30, 0)
				else
					castbar.Icon:SetPoint("LEFT", -30, 0)
				end

				castbar.IconOverlay = castbar:CreateTexture(nil, "OVERLAY")
				castbar.IconOverlay:SetPoint("TOPLEFT", castbar.Icon, "TOPLEFT", -1.5, 1)
				castbar.IconOverlay:SetPoint("BOTTOMRIGHT", castbar.Icon, "BOTTOMRIGHT", 1, -1)
				castbar.IconOverlay:SetTexture(buttonTex)
				castbar.IconOverlay:SetVertexColor(1, 1, 1)

				castbar.IconBackdrop = CreateFrame("Frame", nil, castbar)
				castbar.IconBackdrop:SetPoint("TOPLEFT", castbar.Icon, "TOPLEFT", -4, 3)
				castbar.IconBackdrop:SetPoint("BOTTOMRIGHT", castbar.Icon, "BOTTOMRIGHT", 3, -3.5)
				castbar.IconBackdrop:SetBackdrop({
					edgeFile = glowTex, edgeSize = 4,
					insets = {left = 3, right = 3, top = 3, bottom = 3}
				})
				castbar.IconBackdrop:SetBackdropColor(0, 0, 0, 0)
				castbar.IconBackdrop:SetBackdropBorderColor(0, 0, 0, 0.7)
			end
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
			ShieldEnable = oufdb.Castbar.General.Shield,
			Bar = oufdb.Castbar.Colors.Bar,
			Background = oufdb.Castbar.Colors.Background,
			Border = oufdb.Castbar.Colors.Border,
			Shield = oufdb.Castbar.Colors.Shield,
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

		self.HealPrediction.myBar:SetWidth(oufdb.Bars.Health.Width * self:GetWidth() / oufdb.Width) -- needed for 25/40 man raid width downscaling!
		self.HealPrediction.myBar:SetStatusBarTexture(Media:Fetch("statusbar", oufdb.Bars.HealPrediction.Texture))
		self.HealPrediction.myBar:SetStatusBarColor(oufdb.Bars.HealPrediction.MyColor.r, oufdb.Bars.HealPrediction.MyColor.g, oufdb.Bars.HealPrediction.MyColor.b, oufdb.Bars.HealPrediction.MyColor.a)

		self.HealPrediction.otherBar:SetWidth(oufdb.Bars.Health.Width * self:GetWidth() / oufdb.Width) -- needed for 25/40 man raid width downscaling!
		self.HealPrediction.otherBar:SetStatusBarTexture(Media:Fetch("statusbar", oufdb.Bars.HealPrediction.Texture))
		self.HealPrediction.otherBar:SetStatusBarColor(oufdb.Bars.HealPrediction.OtherColor.r, oufdb.Bars.HealPrediction.OtherColor.g, oufdb.Bars.HealPrediction.OtherColor.b, oufdb.Bars.HealPrediction.OtherColor.a)

		self.HealPrediction.myBar:ClearAllPoints()
		self.HealPrediction.myBar:SetPoint("TOPLEFT", self.Health:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
		self.HealPrediction.myBar:SetPoint("BOTTOMLEFT", self.Health:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)

		self.HealPrediction.otherBar:SetPoint("TOPLEFT", self.HealPrediction.myBar:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
		self.HealPrediction.otherBar:SetPoint("BOTTOMLEFT", self.HealPrediction.myBar:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
	end,

	V2Textures = function(from, to)
		if not from.V2Tex then
			local V2Tex = CreateFrame("Frame", nil, from)

			V2Tex.Horizontal = CreateFrame("Frame", nil, V2Tex)
			V2Tex.Horizontal:SetFrameLevel(19)
			V2Tex.Horizontal:SetFrameStrata("BACKGROUND")
			V2Tex.Horizontal:SetHeight(2)
			V2Tex.Horizontal:SetBackdrop(backdrop2)
			V2Tex.Horizontal:SetBackdropColor(0, 0, 0, 1)
			V2Tex.Horizontal:SetBackdropBorderColor(0.1, 0.1, 0.1, 1)
			V2Tex.Horizontal:Show()

			V2Tex.Vertical = CreateFrame("Frame", nil, V2Tex)
			V2Tex.Vertical:SetFrameLevel(19)
			V2Tex.Vertical:SetFrameStrata("BACKGROUND")
			V2Tex.Vertical:SetWidth(2)
			V2Tex.Vertical:SetBackdrop(backdrop2)
			V2Tex.Vertical:SetBackdropColor(0, 0, 0, 1)
			V2Tex.Vertical:SetBackdropBorderColor(0.1, 0.1, 0.1, 1)
			V2Tex.Vertical:Show()

			V2Tex.Horizontal2 = CreateFrame("Frame", nil, V2Tex)
			V2Tex.Horizontal2:SetFrameLevel(19)
			V2Tex.Horizontal2:SetFrameStrata("BACKGROUND")
			V2Tex.Horizontal2:SetHeight(2)
			V2Tex.Horizontal2:SetBackdrop(backdrop2)
			V2Tex.Horizontal2:SetBackdropColor(0, 0, 0, 1)
			V2Tex.Horizontal2:SetBackdropBorderColor(0.1, 0.1, 0.1, 1)
			V2Tex.Horizontal2:Show()

			V2Tex.Dot = CreateFrame("Frame", nil, V2Tex)
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
	local oufdb, ouf_xp_rep

	if unit == "player" or unit == "vehicle" then
		oufdb = module.db.Player
		ouf_xp_rep = module.db.XP_Rep
	elseif unit == "targettarget" then
		oufdb = module.db.ToT
	elseif unit == "targettargettarget" then
		oufdb = module.db.ToToT
	elseif unit == "target" then
		oufdb = module.db.Target
	elseif unit == "focustarget" then
		oufdb = module.db.FocusTarget
	elseif unit == "focus" then
		oufdb = module.db.Focus
	elseif unit == "pettarget" then
		oufdb = module.db.PetTarget
	elseif unit == "pet" then
		oufdb = module.db.Pet

	elseif unit == "party" then
		oufdb = module.db.Party
	elseif unit == "partytarget" then
		oufdb = module.db.PartyTarget
	elseif unit == "partypet" then
		oufdb = module.db.PartyPet

	elseif unit == "maintank" then
		oufdb = module.db.Maintank
	elseif unit == "maintanktarget" then
		oufdb = module.db.MaintankTarget
	elseif unit == "maintanktargettarget" then
		oufdb = module.db.MaintankToT

	elseif unit == unit:match("arena%d") then
		oufdb = module.db.Arena
	elseif unit == unit:match("arena%dtarget") then
		oufdb = module.db.ArenaTarget
	elseif unit == unit:match("arena%dpet") then
		oufdb = module.db.ArenaPet

	elseif unit == unit:match("boss%d") then
		oufdb = module.db.Boss
	elseif unit == unit:match("boss%dtarget") then
		oufdb = module.db.BossTarget

	elseif unit == "raid" then
		oufdb = module.db.Raid
	end

	self.menu = unit ~= "raid" and menu or nil
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
	module.funcs.Full(self, unit, oufdb)
	module.funcs.FrameBackdrop(self, unit, oufdb)

	if oufdb.Bars.HealPrediction and oufdb.Bars.HealPrediction.Enable then module.funcs.HealPrediction(self, unit, oufdb) end

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

	module.funcs.HealthValue(self, unit, oufdb)
	module.funcs.HealthPercent(self, unit, oufdb)
	module.funcs.HealthMissing(self, unit, oufdb)

	module.funcs.PowerValue(self, unit, oufdb)
	module.funcs.PowerPercent(self, unit, oufdb)
	module.funcs.PowerMissing(self, unit, oufdb)

	------------------------------------------------------------------------
	--	Icons
	------------------------------------------------------------------------

	if oufdb.Icons then
		if oufdb.Icons.Leader and oufdb.Icons.Leader.Enable then module.funcs.Leader(self, unit, oufdb) end
		if oufdb.Icons.Lootmaster and oufdb.Icons.Lootmaster.Enable then module.funcs.MasterLooter(self, unit, oufdb) end
		if oufdb.Icons.Raid and oufdb.Icons.Raid.Enable then module.funcs.RaidIcon(self, unit, oufdb) end
		if oufdb.Icons.Role and oufdb.Icons.Role.Enable then module.funcs.LFDRole(self, unit, oufdb) end
		if oufdb.Icons.PvP and oufdb.Icons.PvP.Enable then module.funcs.PvP(self, unit, oufdb) end
		if oufdb.Icons.Resting and oufdb.Icons.Resting.Enable then module.funcs.Resting(self, unit, oufdb) end
		if oufdb.Icons.Combat and oufdb.Icons.Combat.Enable then module.funcs.Combat(self, unit, oufdb) end
		if oufdb.Icons.ReadyCheck and oufdb.Icons.ReadyCheck.Enable then module.funcs.ReadyCheck(self, unit, oufdb) end
	end

	------------------------------------------------------------------------
	--	Player Specific Items
	------------------------------------------------------------------------

	if unit == "player" then
		if ouf_xp_rep.Experience.Enable then module.funcs.Experience(self, unit, ouf_xp_rep) end
		if ouf_xp_rep.Reputation.Enable then module.funcs.Reputation(self, unit, ouf_xp_rep) end

		if class == "DEATH KNIGHT" or class == "DEATHKNIGHT" then
			if oufdb.Bars.Runes.Enable then
				module.funcs.Runes(self, unit, oufdb)
				Blizzard:Hide("runebar")
			end
		elseif class == "DRUID" then
			if oufdb.Bars.Eclipse.Enable then module.funcs.EclipseBar(self, unit, oufdb) end
			if oufdb.Bars.DruidMana.Enable then module.funcs.DruidMana(self, unit, oufdb) end
		elseif class == "PALADIN" then
			if oufdb.Bars.HolyPower.Enable then module.funcs.HolyPower(self, unit, oufdb) end
		elseif class == "MONK" then
			if oufdb.Bars.Chi.Enable then module.funcs.Chi(self, unit, oufdb) end
		elseif class == "SHAMAN" then
			if oufdb.Bars.Totems.Enable then module.funcs.TotemBar(self, unit, oufdb) end
		elseif class == "MAGE" then
			if oufdb.Bars.ArcaneCharges.Enable then module.funcs.ArcaneCharges(self, unit, oufdb) end
		elseif class == "WARLOCK" then
			if oufdb.Bars.WarlockBar.Enable then module.funcs.WarlockBar(self, unit, oufdb) end
		elseif class == "PRIEST" then
			if oufdb.Bars.ShadowOrbs.Enable then module.funcs.ShadowOrbs(self, unit, oufdb) end
		end
	end

	------------------------------------------------------------------------
	--	Target Specific Items
	------------------------------------------------------------------------

	if unit == "target" and oufdb.Bars.ComboPoints.Enable then module.funcs.CPoints(self, unit, oufdb) end

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
		if module.db.Player.Bars.AltPower.Enable then module.funcs.AltPowerBar(self, unit, oufdb) end
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
				self:UpdateAllElements()
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
