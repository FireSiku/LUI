-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, Opt
local optName, Opt = ...
local L, module, db = Opt:GetLUIModule("ExpBars")
if not module or not module.registered then return end

-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################

local colorGet, colorSet = Opt.ColorGetSet(db.Colors)

-- ####################################################################################################################
-- ##### Options Tables ###############################################################################################
-- ####################################################################################################################

Opt.options.args.ExpBars = Opt:Group("Experience Bars", nil, nil, "tab",  Opt.IsModDisabled, nil, Opt.GetSet(db))
Opt.options.args.ExpBars.handler = module

local ExpBars = {
    Header = Opt:Header(L["ExpBar_Name"], 1),
    ShowAzerite = Opt:Toggle("Show Azerite XP", nil, 2),
			
	-- PositionHeader = Opt:Header(L["Position"], 10),
	-- Position = Opt:Position(L["ExpBar_Name"], 11, true, "Refresh"),
	-- Point = Opt:Select(L["Anchor"], nil, 12, LUI.Points, nil, "Refresh"),
	-- RelativePoint = Opt:Select(L["Relative Anchor"], nil, 13, LUI.Points, nil, "Refresh"),
	--Spacing = Opt:Slider(L["Spacing"], L["ExpBar_Options_Spacing_Desc"], 14, {0, 20, 1}, false, "Refresh"),
    TextPositionHeader = Opt:Header(L["ExpBar_Options_TextPosition"], 20),
	ShowText = Opt:Toggle(L["ExpBar_Options_ShowText"] , nil, 21),
	Precision = Opt:Slider(L["Precision"], nil, 22, {min = 0, max = 3, softMax = 2, step = 1}),
    Spacer = Opt:Spacer(24, "full"),
    --Text = Opt:Position(L["ExpBar_Options_Text"], 24, nil, "Refresh"),
    AppHeader = Opt:Header("Appearances", 30),
    Experience = Opt:Color(L["ExpBar_Mode_Experience"], nil, 31, false, nil, nil, nil, colorGet, colorSet),
    Reputation = Opt:Color(L["ExpBar_Mode_Reputation"], nil, 32, false, nil, nil, nil, colorGet, colorSet),
    Azerite = Opt:Color(L["ExpBar_Mode_Artifact"], nil, 33, false, nil, nil, nil, colorGet, colorSet),
    Honor = Opt:Color(L["ExpBar_Mode_Honor"], nil, 34, false, nil, nil, nil, colorGet, colorSet),
}

Opt.options.args.ExpBars.args = ExpBars