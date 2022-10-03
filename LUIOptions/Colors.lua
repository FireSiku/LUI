-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, Opt
local optName, Opt = ...
local L, module, db = Opt:GetLUIModule("Colors")

local GetNumClasses = _G.GetNumClasses
local GetClassInfo = _G.GetClassInfo

-- constants
local SANCTUARY = _G.SANCTUARY_TERRITORY:sub(2, -2)  -- Remove parenthesis.
local FACTION_ALLIANCE = _G.FACTION_ALLIANCE
local FACTION_HORDE = _G.FACTION_HORDE
local MISCELLANEOUS = _G.MISCELLANEOUS
local COLORS = _G.COLORS

local POWER_TYPE_COMBO_POINTS = _G.COMBAT_TEXT_SHOW_COMBO_POINTS_TEXT
local STANDING_HATED      = _G.FACTION_STANDING_LABEL1
local STANDING_HOSTILE    = _G.FACTION_STANDING_LABEL2
local STANDING_UNFRIENDLY = _G.FACTION_STANDING_LABEL3
local STANDING_NEUTRAL    = _G.FACTION_STANDING_LABEL4
local STANDING_FRIENDLY   = _G.FACTION_STANDING_LABEL5
local STANDING_HONORED    = _G.FACTION_STANDING_LABEL6
local STANDING_REVERED    = _G.FACTION_STANDING_LABEL7
local STANDING_EXALTED    = _G.FACTION_STANDING_LABEL8

-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################
--May be moved to the API if we need to. List of localizedclass by englishClass

local classL = {}
for i = 1, GetNumClasses() do
    local localizedClass, englishClass = GetClassInfo(i)
    classL[englishClass] = localizedClass
end

-- ####################################################################################################################
-- ##### Options Tables ###############################################################################################
-- ####################################################################################################################

Opt.options.args.Colors = Opt:Group("Colors", nil, 2, "tab", nil, nil, Opt.ColorGetSet(db.Colors))
Opt.options.args.Colors.handler = module
local Colors = {
    Header = Opt:Header(COLORS, 1),
    Class = Opt:Group(L["Colors_Classes"], nil, 3),
    Factions = Opt:Group(L["Colors_Factions"], nil, 4),
    Misc = Opt:Group(MISCELLANEOUS, nil, 5),
}

--luacheck: push ignore
Colors.Class.args = {
    ClassHeader = Opt:Header(L["Colors_Classes"], 2),
    DEATHKNIGHT = Opt:Color(classL["DEATHKNIGHT"], nil, 2),
    DEMONHUNTER = Opt:Color(classL["DEMONHUNTER"], nil, 3),
    DRUID       = Opt:Color(classL["DRUID"],       nil, 4),
    HUNTER      = Opt:Color(classL["HUNTER"],      nil, 5),
    MAGE        = Opt:Color(classL["MAGE"],        nil, 6),
    MONK        = Opt:Color(classL["MONK"],        nil, 7),
    PALADIN     = Opt:Color(classL["PALADIN"],     nil, 8),
    PRIEST      = Opt:Color(classL["PRIEST"],      nil, 9),
    ROGUE       = Opt:Color(classL["ROGUE"],       nil, 10),
    SHAMAN      = Opt:Color(classL["SHAMAN"],      nil, 11),
    WARLOCK     = Opt:Color(classL["WARLOCK"],     nil, 12),
    WARRIOR     = Opt:Color(classL["WARRIOR"],     nil, 13),
    --Note: Blizzard seems to be shifting toward using POWER_TYPE_* but havent converted all of them to it yet.
    PrimaryHeader = Opt:Header(L["Color_Primary"], 21),
    MANA        = Opt:Color(POWER_TYPE_MANA,        nil, 22),
    RAGE        = Opt:Color(POWER_TYPE_RED_POWER,   nil, 23),
    FOCUS       = Opt:Color(POWER_TYPE_FOCUS,       nil, 24),
    ENERGY      = Opt:Color(POWER_TYPE_ENERGY,      nil, 25),
    RUNIC_POWER = Opt:Color(RUNIC_POWER,            nil, 26),
    FURY        = Opt:Color(POWER_TYPE_FURY,        nil, 27),
    INSANITY    = Opt:Color(POWER_TYPE_INSANITY,    nil, 28),
    MAELSTROM   = Opt:Color(POWER_TYPE_MAELSTROM,   nil, 29),
    PAIN        = Opt:Color(POWER_TYPE_PAIN,        nil, 30),
    LUNAR_POWER = Opt:Color(POWER_TYPE_LUNAR_POWER, nil, 31),
    
    SecondaryHeader = Opt:Header(L["Color_Secondary"], 40),
	COMBO_POINTS   = Opt:Color(POWER_TYPE_COMBO_POINTS,   nil, 41),
	ARCANE_CHARGES = Opt:Color(POWER_TYPE_ARCANE_CHARGES, nil, 42),
	HOLY_POWER     = Opt:Color(HOLY_POWER,                nil, 43),
	SOUL_SHARDS    = Opt:Color(SOUL_SHARDS_POWER,         nil, 44),
	CHI            = Opt:Color(CHI_POWER,                 nil, 45),
	RUNES          = Opt:Color(RUNES,                     nil, 46),
}

Colors.Factions.args = {
    Alliance  = Opt:Color(FACTION_ALLIANCE,    nil, 1),
    Horde     = Opt:Color(FACTION_HORDE,       nil, 2),
    Sanctuary = Opt:Color(SANCTUARY,           nil, 3),
    Break     = Opt:Spacer(4, "full"),
    Standing1 = Opt:Color(STANDING_HATED,      nil, 5),
    Standing2 = Opt:Color(STANDING_HOSTILE,    nil, 6),
    Standing3 = Opt:Color(STANDING_UNFRIENDLY, nil, 7),
    Standing4 = Opt:Color(STANDING_NEUTRAL,    nil, 8),
    Standing5 = Opt:Color(STANDING_FRIENDLY,   nil, 9),
    Standing6 = Opt:Color(STANDING_HONORED,    nil, 10),
    Standing7 = Opt:Color(STANDING_REVERED,    nil, 11),
    Standing8 = Opt:Color(STANDING_EXALTED,    nil, 12),
}
-- luacheck: pop

Colors.Misc.args = {
    GradientHeader = Opt:Header(L["Colors_Gradients"], 1),
	Good = Opt:Color(L["Colors_Good"],     nil, 2),
	Medium = Opt:Color(L["Colors_Medium"], nil, 3),
	Bad = Opt:Color(L["Colors_Bad"],       nil, 4),
	-- Need much better names for these.
	LevelHeader = Opt:Header(L["Color_Levels"], 5),
	DiffSkull = Opt:Color(L["Color_DiffSkull"],  nil, 6, nil, "full"),
	DiffHard = Opt:Color(L["Color_DiffHard"],  nil, 7, nil, "full"),
	DiffEqual = Opt:Color(L["Color_DiffEqual"],  nil, 8, nil, "full"),
	DiffEasy = Opt:Color(L["Color_DiffEasy"], nil,  9, nil, "full"),
	DiffLow = Opt:Color(L["Color_DiffLow"], nil,  10, nil, "full"),
}

Opt.options.args.Colors.args = Colors

--[[
			Advanced = module:NewAdvancedGroup({
				BGMult = module:NewSlider("Background Color Multiplier", nil, 4, 0.05, 1, 0.05, true, "Refresh"),
				ResetColors = module:NewExecute("Reset Colors", nil, 1, function() module.db:ResetProfile() end)
			}),
		}
	return options
end
]]