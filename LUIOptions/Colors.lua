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
    Header = Opt:Header({name = COLORS}),
    Class = Opt:Group({name = L["Colors_Classes"]}),
    Factions = Opt:Group({name = L["Colors_Factions"]}),
    Misc = Opt:Group({name = MISCELLANEOUS}),
}

--luacheck: push ignore
Colors.Class.args = {
    ClassHeader = Opt:Header({name = L["Colors_Classes"]}),
    DEATHKNIGHT = Opt:Color({name = classL["DEATHKNIGHT"]}),
    DEMONHUNTER = Opt:Color({name = classL["DEMONHUNTER"]}),
    EVOKER      = Opt:Color({name = classL["EVOKER"]}),
    DRUID       = Opt:Color({name = classL["DRUID"]}),
    HUNTER      = Opt:Color({name = classL["HUNTER"]}),
    MAGE        = Opt:Color({name = classL["MAGE"]}),
    MONK        = Opt:Color({name = classL["MONK"]}),
    PALADIN     = Opt:Color({name = classL["PALADIN"]}),
    PRIEST      = Opt:Color({name = classL["PRIEST"]}),
    ROGUE       = Opt:Color({name = classL["ROGUE"]}),
    SHAMAN      = Opt:Color({name = classL["SHAMAN"]}),
    WARLOCK     = Opt:Color({name = classL["WARLOCK"]}),
    WARRIOR     = Opt:Color({name = classL["WARRIOR"]}),
    --Note: Blizzard seems to be shifting toward using POWER_TYPE_* but havent converted all of them to it yet.
    PrimaryHeader = Opt:Header({name = L["Color_Primary"]}),
    MANA        = Opt:Color({name = POWER_TYPE_MANA}),
    RAGE        = Opt:Color({name = POWER_TYPE_RED_POWER}),
    FOCUS       = Opt:Color({name = POWER_TYPE_FOCUS}),
    ENERGY      = Opt:Color({name = POWER_TYPE_ENERGY}),
    RUNIC_POWER = Opt:Color({name = RUNIC_POWER}),
    FURY        = Opt:Color({name = POWER_TYPE_FURY}),
    INSANITY    = Opt:Color({name = POWER_TYPE_INSANITY}),
    MAELSTROM   = Opt:Color({name = POWER_TYPE_MAELSTROM}),
    PAIN        = Opt:Color({name = POWER_TYPE_PAIN}),
    LUNAR_POWER = Opt:Color({name = POWER_TYPE_LUNAR_POWER}),
    
    SecondaryHeader = Opt:Header({name = L["Color_Secondary"]}),
	COMBO_POINTS   = Opt:Color({name = POWER_TYPE_COMBO_POINTS}),
	ARCANE_CHARGES = Opt:Color({name = POWER_TYPE_ARCANE_CHARGES}),
	HOLY_POWER     = Opt:Color({name = HOLY_POWER}),
	SOUL_SHARDS    = Opt:Color({name = SOUL_SHARDS_POWER}),
	CHI            = Opt:Color({name = CHI_POWER}),
	RUNES          = Opt:Color({name = RUNES}),
}

Colors.Factions.args = {
    Alliance  = Opt:Color({name = FACTION_ALLIANCE}),
    Horde     = Opt:Color({name = FACTION_HORDE}),
    Sanctuary = Opt:Color({name = SANCTUARY}),
    Break     = Opt:Spacer({width = "full"}),
    Kyrian =    Opt:Color({name = L["Kyrian"]}),
    Necrolord = Opt:Color({name = L["Necrolord"]}),
    NightFae =  Opt:Color({name = L["NightFae"]}),
    Venthyr =   Opt:Color({name = L["Venthyr"]}),
 
    LabelHeader = Opt:Header({name = L["Faction Labels"]}),
    Standing1 = Opt:Color({name = STANDING_HATED}),
    Standing2 = Opt:Color({name = STANDING_HOSTILE}),
    Standing3 = Opt:Color({name = STANDING_UNFRIENDLY}),
    Standing4 = Opt:Color({name = STANDING_NEUTRAL}),
    Standing5 = Opt:Color({name = STANDING_FRIENDLY}),
    Standing6 = Opt:Color({name = STANDING_HONORED}),
    Standing7 = Opt:Color({name = STANDING_REVERED}),
    Standing8 = Opt:Color({name = STANDING_EXALTED}),
}
-- luacheck: pop

Colors.Misc.args = {
    GradientHeader = Opt:Header({name = L["Colors_Gradients"]}),
	Good = Opt:Color({name = L["Colors_Good"]}),
	Medium = Opt:Color({name = L["Colors_Medium"]}),
	Bad = Opt:Color({name = L["Colors_Bad"]}),
	-- Need much better names for these.
	LevelHeader = Opt:Header({name = L["Color_Levels"]}),
	DiffSkull = Opt:Color({name = L["Color_DiffSkull"],  width = "full"}),
	DiffHard = Opt:Color({name = L["Color_DiffHard"],  width = "full"}),
	DiffEqual = Opt:Color({name = L["Color_DiffEqual"],  width = "full"}),
	DiffEasy = Opt:Color({name = L["Color_DiffEasy"], width = "full"}),
	DiffLow = Opt:Color({name = L["Color_DiffLow"], width = "full"}),
}

Opt.options.args.Colors.args = Colors

--[[
			Advanced = module:NewAdvancedGroup({
				BGMult = module:NewSlider({name = "Background Color Multiplier", 0.05, 1, 0.05, true, "Refresh"}),
				ResetColors = module:NewExecute("Reset Colors", nil, 1, function() module.db:ResetProfile() end)
			}),
		}
	return options
end
]]
