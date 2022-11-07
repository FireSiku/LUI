--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: tags.lua
	Description: oUF Tags
]]

local addonname, LUI = ...
local module = LUI:GetModule("Unitframes")
local oUF = LUI.oUF

local Media = LibStub("LibSharedMedia-3.0")

local UnitIsConnected, UnitIsGhost, UnitIsDead, UnitIsAFK = _G.UnitIsConnected, _G.UnitIsGhost, _G.UnitIsDead, _G.UnitIsAFK
local UnitPower, UnitPowerMax, UnitPowerType = _G.UnitPower, _G.UnitPowerMax, _G.UnitPowerType
local UnitClass, UnitLevel, UnitReaction = _G.UnitClass, _G.UnitLevel, _G.UnitReaction
local UnitQuestTrivialLevelRange = _G.UnitQuestTrivialLevelRange
local UnitIsPlayer, UnitName = _G.UnitIsPlayer, _G.UnitName

--- Classic Compatibility
-- This updates our local copy, does not conflict with other addons.
if not LUI.IsRetail then
	UnitQuestTrivialLevelRange = _G.GetQuestGreenRange
end

local nameCache = {}

local TagMethods = oUF.Tags.Methods
local TagEvents = oUF.Tags.Events

function module.ShortValue(value)
	if value >= 1e6 then
		return ("%.1fm"):format(value / 1e6):gsub("%.?0+([km])$", "%1")
	elseif value >= 1e3 or value <= -1e3 then
		return ("%.1fk"):format(value / 1e3):gsub("%.?0+([km])$", "%1")
	else
		return value
	end
end

local function utf8sub(string, i, dots)
	local bytes = string:len()
	if bytes <= i then
		return string
	else
		local len, pos = 0, 1
		while pos <= bytes do
			len = len + 1
			local c = string:byte(pos)
			if c > 0 and c <= 127 then
				pos = pos + 1
			elseif c >= 192 and c <= 223 then
				pos = pos + 2
			elseif c >= 224 and c <= 239 then
				pos = pos + 3
			elseif c >= 240 and c <= 247 then
				pos = pos + 4
			end
			if len == i then break end
		end

		if len == i and pos <= bytes then
			return string:sub(1, pos - 1)..(dots and "..." or "")
		else
			return string
		end
	end
end

local testframe = CreateFrame("Frame")
local teststring = testframe:CreateFontString(nil, "OVERLAY")

local function ShortenName(name)
	teststring:SetFont(Media:Fetch("font", module.db.profile.raid.NameText.Font), module.db.profile.raid.NameText.Size, module.db.profile.raid.NameText.Outline)
	teststring:SetText(name)

	if not nameCache[name] then nameCache[name] = {} end

	local shortname = name
	local maxwidth = module.db.profile.raid.Width * 0.9

	local l = name:len()
	while maxwidth < teststring:GetStringWidth() do
		shortname = shortname:sub(1, l)
		teststring:SetText(shortname)
		l = l - 1
	end

	nameCache[name][1] = shortname

	maxwidth = ((module.db.profile.raid.Width * 5 - module.db.profile.raid.GroupPadding * 3) / 8) * 0.9

	while maxwidth < teststring:GetStringWidth() do
		shortname = shortname:sub(1, l)
		teststring:SetText(shortname)
		l = l - 1
	end

	nameCache[name][2] = shortname
end

function module.RecreateNameCache()
	for name, shortened in pairs(nameCache) do
		ShortenName(name)
	end
end

--TagEvents["GetNameColor"] = "UNIT_HAPPINESS"
function TagMethods.GetNameColor(unit)
	local reaction = UnitReaction(unit, "player")
	local pClass, pToken = UnitClass(unit)
	local pClass2, pToken2 = UnitPowerType(unit)
	local color = module.colors.class[pToken]
	local color2 = module.colors.power[pToken2]
	
	if UnitIsPlayer(unit) then
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

TagEvents["DiffColor"] = "UNIT_LEVEL"
function TagMethods.DiffColor(unit)
	local r, g, b
	local level = UnitLevel(unit)
	if level < 1 then
		r, g, b = unpack(module.colors.leveldiff[1])
	else
		local difference = level - UnitLevel("player")
		if difference >= 5 then
			r, g, b = unpack(module.colors.leveldiff[1])
		elseif difference >= 3 then
			r, g, b = unpack(module.colors.leveldiff[2])
		elseif difference >= -2 then
			r, g, b = unpack(module.colors.leveldiff[3])
		elseif -difference <= UnitQuestTrivialLevelRange("player") then
			r, g, b = unpack(module.colors.leveldiff[4])
		else
			r, g, b = unpack(module.colors.leveldiff[5])
		end
	end
	return string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
end

TagEvents["NameShort"] = "UNIT_NAME_UPDATE"
function TagMethods.NameShort(unit)
	local name = UnitName(unit)
	if name then
		if unit == "pet" and name == "Unknown" then
			return "Pet"
		else
			return utf8sub(name, 9, true)
		end
	end
end

TagEvents["NameMedium"] = "UNIT_NAME_UPDATE"
function TagMethods.NameMedium(unit)
	local name = UnitName(unit)
	if name then
		if unit == "pet" and name == "Unknown" then
			return "Pet"
		else
			return utf8sub(name, 18, true)
		end
	end
end

TagEvents["NameLong"] = "UNIT_NAME_UPDATE"
function TagMethods.NameLong(unit)
	local name = UnitName(unit)
	if name then
		if unit == "pet" and name == "Unknown" then
			return "Pet"
		else
			return utf8sub(name, 36, true)
		end
	end
end

TagEvents["RaidName25"] = "UNIT_NAME_UPDATE UNIT_HEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED"
function TagMethods.RaidName25(unit, relativeUnit)
	if module.db.profile and module.db.profile.raid.NameText.ShowDead then
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
	local name = unit == "vehicle" and UnitName(relativeUnit or unit) or UnitName(unit)
	if not nameCache[name] then ShortenName(name) end
	return nameCache[name][1]
end

TagEvents["RaidName40"] = "UNIT_NAME_UPDATE UNIT_HEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED"
function TagMethods.RaidName40(unit, relativeUnit)
	if module.db.profile and module.db.profile.raid.NameText.ShowDead then
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
	local name = unit == "vehicle" and UnitName(relativeUnit or unit) or UnitName(unit)
	if not nameCache[name] then ShortenName(name) end
	return nameCache[name][2]
end

TagEvents["additionalpower2"] = "UNIT_POWER_UPDATE UNIT_MAXPOWER"
function TagMethods.additionalpower2(unit)
	if unit ~= "player" then return end

	if not module.db.profile then return "" end
	local db = module.db.profile.player.AdditionalPowerText

	local min, max = UnitPower("player", Enum.PowerType.Mana), UnitPowerMax("player", Enum.PowerType.Mana)
	if db.HideIfFullMana and min == max then return "" end
	local perc = min / max * 100

	local _, pType = UnitPowerType(unit)
	local pClass, pToken = UnitClass(unit)
	local color = module.colors.class[pToken]
	local color2 = module.colors.power[pType]

	local r, g, b, text

	if db.Color == "" then
		r, g, b = color[1]*255,color[2]*255,color[3]*255
	elseif db.Color == "" then
		r, g, b = color2[1]*255,color2[2]*255,color2[3]*255
	else
		r, g, b = db.IndividualColor.r*255, db.IndividualColor.g*255, db.IndividualColor.b*255
	end

	if db.Format == "Absolut" then
		text = format("%d/%d", min, max)
	elseif db.Format == "Absolut & Percent" then
		text = format("%d/%d | %.1f", min, max, perc)
	elseif db.Format == "Absolut Short" then
		text = format("%s/%s", module.ShortValue(min), module.ShortValue(max))
	elseif db.Format == "Absolut Short & Percent" then
		text = format("%s/%s | %.1f", module.ShortValue(min), module.ShortValue(max), perc)
	elseif db.Format == "Standard" then
		text = min
	elseif db.Format == "Standard & Percent" then
		text = format("%s | %.1f%%", min, perc)
	elseif db.Format == "Standard Short" then
		text = module.ShortValue(min)
	elseif db.Format == "Standard Short & Percent" then
		text = format("%s | %.1f%%", module.ShortValue(min), perc)
	else
		text = min
	end

	return format("|cff%02x%02x%02x%s|r", r, g, b, text)
end
