--- Colors api contains all the generic api related to colors, that modules can use to easily access or do stuff.
-- This also includes the Colors section of the LUI Options.

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, LUIAddon
local _, LUI = ...
local L = LUI.L

---@class ColorModule : LUIModule
local module = LUI:NewModule("Colors")

local db

local GetQuestDifficultyColor = _G.GetQuestDifficultyColor
local UnitReaction = _G.UnitReaction

-- constants
local SANCTUARY = _G.SANCTUARY_TERRITORY:sub(2, -2)  -- Removed parenthesis.
local FACTION_ALLIANCE = _G.FACTION_ALLIANCE
local FACTION_HORDE = _G.FACTION_HORDE
local MISCELLANEOUS = _G.MISCELLANEOUS
local COLORS = _G.COLORS

local STANDING_HATED      = _G.FACTION_STANDING_LABEL1
local STANDING_HOSTILE    = _G.FACTION_STANDING_LABEL2
local STANDING_UNFRIENDLY = _G.FACTION_STANDING_LABEL3
local STANDING_NEUTRAL    = _G.FACTION_STANDING_LABEL4
local STANDING_FRIENDLY   = _G.FACTION_STANDING_LABEL5
local STANDING_HONORED    = _G.FACTION_STANDING_LABEL6
local STANDING_REVERED    = _G.FACTION_STANDING_LABEL7
local STANDING_EXALTED    = _G.FACTION_STANDING_LABEL8

-- ####################################################################################################################
-- ##### Default Settings #############################################################################################
-- ####################################################################################################################

module.defaults = {
	profile = {
		Advanced = {
			BackgroundMultiplier = 0.4,
		},
		Colors = {
			-- Class Colors
			DEATHKNIGHT = { r = 0.8,  g = 0.1,  b = 0.1,  },
			DRUID =       { r = 1,    g = 0.44, b = 0.15, },
			HUNTER =      { r = 0.22, g = 0.91, b = 0.18, },
			MAGE =        { r = 0.12, g = 0.58, b = 0.89, },
			MONK =        { r = 0.00, g = 1.00, b = 0.59, },
			PALADIN =     { r = 0.96, g = 0.21, b = 0.73, },
			PRIEST =      { r = 0.9,  g = 0.9,  b = 0.9,  },
			ROGUE =       { r = 0.95, g = 0.86, b = 0.16, },
			SHAMAN =      { r = 0.04, g = 0.39, b = 0.98, },
			WARLOCK =     { r = 0.57, g = 0.22, b = 1,    },
			WARRIOR =     { r = 1,    g = 0.78, b = 0.55, },
			DEMONHUNTER = { r = 0.65, g = 0.2,  b = 0.8   },

			-- Faction Colors
			Alliance  = { r = 0,   g = 0.6, b = 1,   },
			Horde     = { r = 1,   g = 0.3, b = 0.3, },
			Neutral   = { r = 0.9, g = 0.7, b = 0,   },
			Sanctuary = { r = 0,   g = 1,   b = 1,   },

			-- Reaction Colors
			Standing1 = { r = 1,   g = 0.3, b = 0.3, }, -- Hated
			Standing2 = { r = 0.9, g = 0.2, b = 0,   }, -- Hostile
			Standing3 = { r = 1,   g = 0.3, b = 0.3, }, -- Unfriendly
			Standing4 = { r = 0.9, g = 0.7, b = 0,   }, -- Neutral
			Standing5 = { r = 0,   g = 0.6, b = 0.1, }, -- Friendly
			Standing6 = { r = 0,   g = 0.6, b = 0.1, }, -- Honored
			Standing7 = { r = 0,   g = 0.6, b = 0.1, }, -- Revered
			Standing8 = { r = 0,   g = 0.6, b = 0.1, }, -- Exalted

			-- Resources
			MANA           = { r = 0.12, g = 0.58, b = 0.89, },
			RAGE           = { r = 0.69, g = 0.31, b = 0.31, },
			FOCUS          = { r = 0.65, g = 0.63, b = 0.35, },
			ENERGY         = { r = 0.95, g = 0.86, b = 0.16, },
			RUNIC_POWER    = { r = 0   , g = 0.82, b = 1   , },
			RUNES          = { r = 0.55, g = 0.57, b = 0.61, },
			FUEL           = { r = 0   , g = 0.55, b = 0.5 , },
			COMBO_POINTS   = { r = 0.95, g = 0.86, b = 0.16, },
			ARCANE_CHARGES = { r = 0.12, g = 0.58, b = 0.89, },
			HOLY_POWER     = { r = 0.9 , g = 0.88, b = 0.06, },
			SOUL_SHARDS    = { r = 0.57, g = 0.22, b = 1   , },
			CHI            = { r = 0   , g = 1   , b = 0.59, },
			STAGGER_LOW    = { r = 052 , g = 1   , b = 0.52, },
			STAGGER_MED    = { r = 1   , g = 0.97, b = 0.72, },
			STAGGER_HIGH   = { r = 1   , g = 0.42, b = 0.42, },
			LUNAR_POWER    = { r = 0.3 , g = 0.52, b = 0.9 , },
			MAELSTROM      = { r = 0.04, g = 0.39, b = 0.98, },
			PAIN           = { r = 1   , g = 0.61, b = 0   , },
			INSANITY       = { r = 0.4 , g = 0   , b = 0.8 , },
			FURY           = { r = 0.79, g = 0.26, b = 0.99, },

			--Gradient
			Good =   { r = 0,   g = 1,   b = 0,   },
			Medium = { r = 1,   g = 1,   b = 0,   },
			Bad =    { r = 0.8, g = 0.3, b = 0.2, },

			--TODO: Level Differences. (NYI)
			DiffSkull = { r = 0.69, g = 0.31, b = 0.31, }, -- Target Level >= 5
			DiffHard =  { r = 0.71, g = 0.43, b = 0.27, }, -- Target Level >= 3
			DiffEqual = { r = 0.84, g = 0.75, b = 0.65, }, -- Target Level <> 2
			DiffEasy =  { r = 0.33, g = 0.59, b = 0.33, }, -- Target Level GreenQuestRange
			DiffLow =   { r = 0.55, g = 0.57, b = 0.61, }, -- Low Level Target
		},
	},
}

-- ####################################################################################################################
-- ##### Local Functions ##############################################################################################
-- ####################################################################################################################

--- Return r, g, b for any color stored by the color api.  
--- If the color doesn't exists, return nil
---@param colorName string
---@return number R, number G, number B
local function GetColorRGB(colorName)
	local color = db.Colors[colorName]
	if color then
		return color.r, color.g, color.b
	end
end

-- ####################################################################################################################
-- ##### Simple API ###################################################################################################
-- ####################################################################################################################

--- Return a Multiplier for RGB values to use for darker background colors.
---@return number mult
function LUI:GetBGMultiplier()
	return db.Advanced.BackgroundMultiplier
end

--- Utility function for other modules to fetch a color stored in Color module.
---@return number R, number G, number B
function LUI:GetFallbackRGB(colorName)
	return GetColorRGB(colorName)
end

--- Convenience wrapper for "Good" color.
---@return number R, number G, number B
function LUI:PositiveColor()
	return GetColorRGB("Good")
end

--- Convenience wrapper for "Bad" color.
---@return number R, number G, number B
function LUI:NegativeColor()
	return GetColorRGB("Bad")
end

-- ####################################################################################################################
-- ##### Specialized API ##############################################################################################
-- ####################################################################################################################
-- Most of these functions will return a r, g, b value for a specific purpose, and fallback to white as needed.

--- Return r, g, b for given class.
---@param class ClassToken
---@return number R, number G, number B
function LUI:GetClassColor(class)
	local r, g, b = GetColorRGB(class)
	if r and g and b then
		return r, g, b
	else
		return 1, 1, 1
	end
end

--- Return r, g, b for given faction
---@param faction string
---@return number R, number G, number B
function LUI:GetFactionColor(faction)
	local r, g, b = GetColorRGB(faction)
	if r and g and b then
		return r, g, b
	else
		return 1, 1, 1
	end
end

--- Return r, g, b based on reaction of unit towards another unit.
---@param unit UnitId
---@param otherUnit UnitId? @ Assume "player" if missing
---@return number R, number G, number B
function LUI:GetReactionColor(unit, otherUnit)
	local reaction = UnitReaction(unit, otherUnit or "player")
	local colorName = format("Standing%d", reaction)

	local r, g, b = GetColorRGB(colorName)
	if r and g and b then
		return r, g, b
	else
		return 1, 1, 1
	end
end

--- Return r, g, b based on level difference.
---@param level number
---@return number R, number G, number B
function LUI:GetDifficultyColor(level)
	local color = GetQuestDifficultyColor(level)
	return color.r, color.g, color.b
	
end

-- ####################################################################################################################
-- ##### Gradient Color API ###########################################################################################
-- ####################################################################################################################

--- Based on Wowpedia's ColorGradient. Use our three gradient colors to make a color based on a percentage
---@param perc number @ Percentage of the mix between the three colors defined as gradient.
---@return number R, number G, number B
function LUI:RGBGradient(perc)
	if perc >= 1 then
		return LUI:PositiveColor()
	elseif perc <= 0 then
		return LUI:NegativeColor()
	end

	local segment, relperc = math.modf(perc * 2)
	local r1, r2, g1, g2, b1, b2
	if segment == 0 then
		r1, g1, b1 = GetColorRGB("Bad")
		r2, g2, b2 = GetColorRGB("Medium")
	elseif segment == 1 then
		r1, g1, b1 = GetColorRGB("Medium")
		r2, g2, b2 = GetColorRGB("Good")
	end

	local r = r1 + (r2 - r1) * relperc
	local g = g1 + (g2 - g1) * relperc
	local b = b1 + (b2 - b1) * relperc
	return r, g, b
end

---Wrapper for ColorGradient's that inverse the percent given.
---@param perc number @ Percentage of the mix between the three colors defined as gradient.
---@return number R, number G, number B
function LUI:InverseGradient(perc)
	return LUI:RGBGradient(1 - perc)
end

-- ####################################################################################################################
-- ##### Color Callback API ###########################################################################################
-- ####################################################################################################################
---@TODO: Possibly have a full callback system for API, otherwise we will just have more copies of this function.
-- Provide callbacks for modules to use when colors are changed.

local multiplierCallback = {}
local colorCallback = {}

--Register a function that will be called back by the Options API when someone change BG Multiplier.
---@param id any @ Unique identifier for the callback. If it already exists, do nothing.
---@param func function @ Function to be called back when event occurs.
function LUI:AddBGMultiplierCallback(id, func)
	if multiplierCallback[id] then return end
	multiplierCallback[id] = func
end

--- Register a function that will be called back by the Options API when someone change class/theme colors.  
---@param id any @ Unique identifier for the callback. If it already exists, do nothing.
---@param func function @ Function to be called back when event occurs.
function LUI:AddColorCallback(id, func)
	if colorCallback[id] then return end
	colorCallback[id] = func
end

-- ####################################################################################################################
-- ##### Module Refresh ###############################################################################################
-- ####################################################################################################################

function module:RefreshClassColors()
	--Nothing happens currently, as we don't alter class colors.

	--Call back functions that needs to know
	for id_, func in pairs(colorCallback) do func() end
end

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function module:OnInitialize()
	LUI:RegisterModule(module)
	db = module.db.profile
end

function module:OnEnable()
end
