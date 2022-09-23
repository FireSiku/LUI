-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, Opt
local optName, Opt = ...
local L, module, db = Opt:GetLUIModule("Micromenu")
if not module or not module.registered then return end


-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################

local dropDirections = {
    LEFT = L["Point_Left"],
    RIGHT = L["Point_Right"],
}
local colorGet, colorSet = Opt.ColorGetSet(db.Colors)

-- ####################################################################################################################
-- ##### Options Tables ###############################################################################################
-- ####################################################################################################################

Opt.options.args.Micromenu = Opt:Group("Micromenu", nil, nil, "tab", Opt.IsModDisableda1, nil, Opt.GetSet(db))
Opt.options.args.Micromenu.handler = module

local Micromenu = {
    -- General
    Header = Opt:Header(L["Micro_Name"], 1),
	Spacing = Opt:Slider(L["Spacing"], L["MicroOptions_Spacing_Desc"], 2, { min = -10, max = 10, step = 1}),
	
    -- Buttons
    ButtonsHeader = Opt:Header(L["Buttons"], 3),
	HidePlayer = Opt:Toggle(L["MicroOptions_Player"], nil, 4),
	HideSpellbook = Opt:Toggle(L["MicroOptions_Spellbook"], nil, 5),
	HideTalents = Opt:Toggle(L["MicroOptions_Talents"], nil, 6),
	HideAchievements = Opt:Toggle(L["MicroOptions_Achievements"], nil, 7),
	HideQuests = Opt:Toggle(L["MicroOptions_Quests"], nil, 8),
	HideGuild = Opt:Toggle(L["MicroOptions_Guild"], nil, 9),
	HideLFG = Opt:Toggle(L["MicroOptions_LFG"], nil, 10),
	HideEJ = Opt:Toggle(L["MicroOptions_EJ"], nil, 11),
	HideCollections = Opt:Toggle(L["MicroOptions_Collections"], nil, 12),
	HideStore = Opt:Toggle(L["MicroOptions_Store"], nil, 13),
	HideBags = Opt:Toggle(L["MicroOptions_Bags"], nil, 14),
	HideSettings = Opt:Toggle(L["MicroOptions_Settings"], nil, 15),

    -- Position
    PositionHeader = Opt:Header(L["Position"], 16),
    X = Opt:Input(L["API_XValue_Name"], format(L["API_XValue_Desc"], L["Micro_Name"]), 17),
    Y = Opt:Input(L["API_YValue_Name"], format(L["API_YValue_Desc"], L["Micro_Name"]), 18),
	Point = Opt:Select(L["Anchor"], nil,  19, LUI.Points),
	Direction = Opt:Select(L["MicroOptions_Direction_Name"], L["MicroOptions_Direction_Desc"], 20, dropDirections),

    -- Colors
	ColorHeader = Opt:Header(L["Colors"], 21),
    Micromenu = Opt:Color(L["Micro_Name"], nil, 22, true, nil, nil, nil, colorGet, colorSet),
    Background = Opt:Color(L["Background"], nil, 23, true, nil, nil, nil, colorGet, colorSet),
}

Opt.options.args.Micromenu.args = Micromenu