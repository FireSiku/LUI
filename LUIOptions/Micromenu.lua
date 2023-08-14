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

-- ####################################################################################################################
-- ##### Options Tables ###############################################################################################
-- ####################################################################################################################

Opt.options.args.Micromenu = Opt:Group("Micromenu", nil, nil, "tab", Opt.IsModDisabled, nil, Opt.GetSet(db))
Opt.options.args.Micromenu.handler = module

local Micromenu = {
    -- General
    Header = Opt:Header({name = L["Micro_Name"]}),
	Spacing = Opt:Slider({name = L["Spacing"], desc = L["MicroOptions_Spacing_Desc"], min = -10, max = 10, step = 1}),
	
    -- Buttons
    ButtonsHeader = Opt:Header({name = L["Hide Buttons"]}),
	HidePlayer = Opt:Toggle({name = L["MicroOptions_Player"]}),
	HideSpellbook = Opt:Toggle({name = L["MicroOptions_Spellbook"]}),
	HideTalents = Opt:Toggle({name = L["MicroOptions_Talents"]}),
	HideAchievements = Opt:Toggle({name = L["MicroOptions_Achievements"]}),
	HideQuests = Opt:Toggle({name = L["MicroOptions_Quests"]}),
	HideGuild = Opt:Toggle({name = L["MicroOptions_Guild"]}),
	HideLFG = Opt:Toggle({name = L["MicroOptions_LFG"]}),
	HideEJ = Opt:Toggle({name = L["MicroOptions_EJ"]}),
	HideCollections = Opt:Toggle({name = L["MicroOptions_Collections"]}),
	HideStore = Opt:Toggle({name = L["MicroOptions_Store"]}),
	HideBags = Opt:Toggle({name = L["MicroOptions_Bags"]}),
	HideSettings = Opt:Toggle({name = L["MicroOptions_Settings"]}),

    -- Position
    PositionHeader = Opt:Header({name = L["Position"]}),
    X = Opt:Input({name = L["API_XValue_Name"], desc = format(L["API_XValue_Desc"], L["Micro_Name"])}),
    Y = Opt:Input({name = L["API_YValue_Name"], desc = format(L["API_YValue_Desc"], L["Micro_Name"])}),
	Point = Opt:Select({name = L["Anchor"], values = LUI.Points}),
	Direction = Opt:Select({name = L["MicroOptions_Direction_Name"], desc = L["MicroOptions_Direction_Desc"], values = dropDirections}),

    -- Colors
	ColorHeader = Opt:Header({name = L["Colors"]}),
    Micromenu = Opt:Color({name = L["Micro_Name"], hasAlpha = true}),
    Background = Opt:Color({name = L["Background"], hasAlpha = true}),
}

Opt.options.args.Micromenu.args = Micromenu
