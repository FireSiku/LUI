local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local db = LUI.db.profile

local units = {
	player = "Player",
	target = "Target",
	targettarget = "ToT",
	targettargettarget = "ToToT",
	focus = "Focus",
	focustarget = "FocusTarget",
	pet = "Pet",
	pettarget = "PetTarget",
	party = "Party",
	partypet = "PartyPet",
	partytarget = "PartyTarget",
	raid = "Maintank",
	raidtarget = "MaintankTarget",
	raidtargettarget = "MaintankToT",
	boss1 = "Boss",
	boss2 = "Boss",
	boss3 = "Boss",
	boss4 = "Boss",
}

local switch = function(n, ...)
	for k,v in pairs({...}) do
		if v[1] == n or v[1] == nil then
			return (type(v[2]) == "function") and v[2]() or v[2]
		end
	end
end

local case = function(n,f)
	return {n,f}
end

local default = function(f)
	return {nil,f}
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
	if (bytes <= i) then
		return string
	else
		local len, pos = 0, 1
		while(pos <= bytes) do
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

		if (len == i and pos <= bytes) then
			return string:sub(1, pos - 1)..(dots and "..." or "")
		else
			return string
		end
	end
end

------------------------------------------------------------------------
--	Colors
------------------------------------------------------------------------

local colors = oUF_LUI.colors

------------------------------------------------------------------------
--	Tags & TagEvents
------------------------------------------------------------------------

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

oUF.TagEvents["druidmana2"] = "UNIT_POWER UNIT_MAXPOWER"
if (not oUF.Tags["druidmana2"]) then
	oUF.Tags["druidmana2"] = function(unit)
		if unit ~= "player" then return end
		
		local min, max = UnitPower("player", SPELL_POWER_MANA), UnitPowerMax("player", SPELL_POWER_MANA)
		local perc = min/max*100
		perc = format("%.1f", perc)
		perc = perc.."%"
		if db.oUF.Player.Texts.DruidMana.HideIfFullMana and min == max then return "" end
		
		local _, pType = UnitPowerType(unit)
		local pClass, pToken = UnitClass(unit)
		local color = colors.class[pToken]
		local color2 = colors.power[pType]
		
		local final = switch(db.oUF.Player.Texts.DruidMana.Format,
			case("Absolut", format("%s/%s",min,max)),
			case("Absolut & Percent", format("%s/%s | %s",min,max,perc)),
			case("Absolut Short", format("%s/%s",ShortValue(min),ShortValue(max))),
			case("Absolut Short & Percent", format("%s/%s | %s",ShortValue(min),ShortValue(max),perc)),
			case("Standard", min),
			case("Standard Short", ShortValue(min)),
			default(min)
		)
		
		final = switch(db.oUF.Player.Texts.DruidMana.Color,
			case("By Class", format("|cff%02x%02x%02x%s|r",color[1]*255,color[2]*255,color[3]*255,final)),
			case("By Type", format("|cff%02x%02x%02x%s|r",color2[1]*255,color2[2]*255,color2[3]*255,final)),
			case("Individual", format("|cff%02x%02x%02x%s|r",db.oUF.Player.Texts.DruidMana.IndividualColor.r*255,db.oUF.Player.Texts.DruidMana.IndividualColor.g*255,db.oUF.Player.Texts.DruidMana.IndividualColor.b*255,final))
		)
		
		return final
	end
end

local FormatName = function(self)
	if not self or not self.Info then return end
	
	local unit = self.unit
	local info = self.Info
	
	local name = switch(info.Length,
		case("Long", "[NameLong]"),
		case("Short", "[NameShort]"),
		default("[NameMedium]")
	)
	
	if info.ColorNameByClass then
		name = "[GetNameColor]"..name.."|r"
	end
	
	local level = switch(info.ColorLevelByDifficulty,
		case(false, "[level2]"),
		default("[DiffColor][level2]|r")
	)
	
	if info.ShowClassification then
		level = switch(info.ShortClassification,
			case(true, level.."[shortclassification]"),
			default(level.."[classification]")
		)
	end
	
	local race = "[race]"
	
	local class = switch(info.ColorClassByClass,
		case(true, "[GetNameColor][smartclass]|r"),
		default("[smartclass]")
	)
	
	self:Tag(info, info.Format:gsub(" %+ ", " "):gsub("Name", name):gsub("Level", level):gsub("Race", race):gsub("Class", class))
	self:UpdateAllElements()
end

oUF:RegisterMetaFunction("FormatName", FormatName)