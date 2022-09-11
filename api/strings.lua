--- Strings API mostly contains LUI methods, but moved to their own file for clarity.
-- This api module deal mostly in storing huge string table and functions that convert a string (or to a string)

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

local _, LUI = ...
local L = LUI.L

--constants
-- luacheck: globals LOCALIZED_CLASS_NAMES_FEMALE LOCALIZED_CLASS_NAMES_MALE MALE FEMALE

local LOCALIZED_CLASS_NAMES_FEMALE = LOCALIZED_CLASS_NAMES_FEMALE
local LOCALIZED_CLASS_NAMES_MALE = LOCALIZED_CLASS_NAMES_MALE

-- Default fonts used for specialized character sets. Currently here for documentation purposes.
-- TODO: Whenever a FontString may potentially get those characters, use an api call to detect those.
--           We could then detect those and replace the font with the correct font to keep support.
-- local UNIT_NAME_FONT_KOREAN = UNIT_NAME_FONT_KOREAN      -- Korean font
-- local UNIT_NAME_FONT_CHINESE = UNIT_NAME_FONT_CHINESE    -- Chinese/Japanese Font
-- local UNIT_NAME_FONT_CYRILLIC = UNIT_NAME_FONT_CYRILLIC  -- Russian Font

-- ####################################################################################################################
-- ##### StringUtils: EmmyLua #########################################################################################
-- ####################################################################################################################

---@alias DBScope
---| "profile"
---| "global"
---| "char"
---| "realm"
---| "class"
---| "race"
---| "faction"
---| "factionrealm"

---@alias ClassToken
---| "DEATHKNIGHT"
---| "DEMONHUNTER"
---| "DRUID"
---| "HUNTER"
---| "MAGE"
---| "MONK"
---| "PALADIN"
---| "PRIEST"
---| "ROGUE"
---| "SHAMAN"
---| "WARLOCK"
---| "WARRIOR"

-- ####################################################################################################################
-- ##### StringUtils: Classes #########################################################################################
-- ####################################################################################################################

---@type table<string, ClassToken>
local localClassNames
--- Returns a locale-independent class token from a localized class name.
---@param className string @ locale-dependent class name
---@return ClassToken classToken locale-indepent class token
function LUI:GetTokenFromClassName(className)
	if not localClassNames then
		localClassNames = {}
		for class, localized in pairs(LOCALIZED_CLASS_NAMES_MALE) do
			localClassNames[localized] = class
		end
		for class, localized in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do
			localClassNames[localized] = class
		end
	end
	return localClassNames[className]
end

-- ####################################################################################################################
-- ##### StringUtils: Constant Tables #################################################################################
-- ####################################################################################################################

---@enum DBScope
LUI.DB_TYPES = {
	"profile",
	"global",
	"char",
	"realm",
	"class",
	"race",
	"faction",
	"factionrealm",
}

LUI.REACTION_NAMES = {
	"Hated",      -- 1
	"Hostile",    -- 2
	"Unfriendly", -- 3
	"Neutral",    -- 4
	"Friendly",   -- 5
	"Honored",    -- 6
	"Revered",    -- 7
	"Exalted",    -- 8
}

LUI.GENDERS = {
	_G.UNKNOWN,	-- 1
	_G.MALE,	-- 2
	_G.FEMALE,	-- 3
}

-- As found in the Colors module.
LUI.PowerTypeNames = {
	"MANA",
	"RAGE",
	"FOCUS",
	"ENERGY",
	"COMBO_POINTS",
	"RUNES",
	"RUNIC_POWER",
	"SOUL_SHARDS",
	"LUNAR_POWER",
	"HOLY_POWER",
	"MAELSTROM",
	"CHI",
	"INSANITY",
	"ARCANE_CHARGES",
	"FURY",
	"PAIN",
	"FUEL",
}

-- Should not be translated. Meant to be used as locale-independent keys
LUI.OppositeOf = {
	-- Sides
	TOP = "BOTTOM",
	BOTTOM = "TOP",
	LEFT = "RIGHT",
	RIGHT = "LEFT",
	-- Corners
	TOPLEFT = "BOTTOMRIGHT",
	TOPRIGHT = "BOTTOMLEFT",
	BOTTOMLEFT = "TOPRIGHT",
	BOTTOMRIGHT = "TOPLEFT",
}

-- ####################################################################################################################
-- ##### StringUtils: Localized Tables ################################################################################
-- ####################################################################################################################
--[[
LUI.FontFlags = {
	NONE = L["Flag_None"],
	OUTLINE = L["Flag_Outline"],
	THICKOUTLINE = L["Flag_ThickOutline"],
	MONOCHROME = L["Flag_Monochrome"],
}

LUI.Points = {
	CENTER = L["Point_Center"],
	TOP = L["Point_Top"],
	BOTTOM = L["Point_Bottom"],
	LEFT = L["Point_Left"],
	RIGHT = L["Point_Right"],
	TOPLEFT = L["Point_TopLeft"],
	TOPRIGHT = L["Point_TopRight"],
	BOTTOMLEFT = L["Point_BottomLeft"],
	BOTTOMRIGHT = L["Point_BottomRight"],
}

LUI.Corners = {
	TOPLEFT = L["Point_TopLeft"],
	TOPRIGHT = L["Point_TopRight"],
	BOTTOMLEFT = L["Point_BottomLeft"],
	BOTTOMRIGHT = L["Point_BottomRight"],
}
LUI.Sides = {
	TOP = L["Point_Top"],
	BOTTOM = L["Point_Bottom"],
	LEFT = L["Point_Left"],
	RIGHT = L["Point_Right"],
}
LUI.Directions = {
	UP = L["Point_Up"],
	DOWN = L["Point_Down"],
	LEFT = L["Point_Left"],
	RIGHT = L["Point_Right"],
}

LUI.ColorTypes = {
	Individual = L["Color_Individual"],
	Theme = L["Color_Theme"],
	Class = L["Color_Class"],
}
]]