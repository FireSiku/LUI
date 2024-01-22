-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class Opt
local Opt = select(2, ...)

---@type AceLocale.Localizations, LUI.ExperienceBars, AceDB-3.0
local L, module, db = Opt:GetLUIModule("Experience Bars")
if not module or not module.registered then return end

-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################


-- ####################################################################################################################
-- ##### Options Table ################################################################################################
-- ####################################################################################################################

local ExpBars = Opt:CreateModuleOptions("Experience Bars", module)

local function IsTextDisabled() return not db.ShowText end

ExpBars.args = {
    Header = Opt:Header({name = L["ExpBar_Name"]}),
    SplitTracker = Opt:Toggle({name = L["ExpBar_Options_SplitTracker"], width = "double"}),
    Spacing = Opt:Slider({name = L["Spacing"], desc = L["ExpBar_Options_Spacing_Desc"], min = 0, max = 20, step = 1}),
    
    ShowAzerite = Opt:Toggle({name = "Show Azerite XP when Heart of Azeroth is equipped.", width = "full"}),
	PositionHeader = Opt:Header({name = L["Position"]}),
	-- Position = Opt:Position({name = L["ExpBar_Name"]}),
	Point = Opt:Select({name = L["Anchor"], values = LUI.Points}),
	RelativePoint = Opt:Select({name = L["Relative Anchor"].." (UIParent)", values = LUI.Points}),
	Spacer1 = Opt:Spacer({}),
    X = Opt:Input({name = "X Value", width = "half"}),
    Y = Opt:Input({name = "Y Value", width = "half"}),
    TextPositionHeader = Opt:Header({name = L["ExpBar_Options_TextPosition"]}),
	ShowText = Opt:Toggle({name = L["ExpBar_Options_ShowText"]}),
	Precision = Opt:Slider({name = L["Precision"], min = 0, max = 3, softMax = 2, step = 1, disabled = IsTextDisabled}),
    Spacer2 = Opt:Spacer({}),
    TextX = Opt:Input({name = "Text Offset Horizontal", disabled = IsTextDisabled}),
    TextY = Opt:Input({name = "Text Offset Vertical", disabled = IsTextDisabled}),
    --Text = Opt:Position({name = L["ExpBar_Options_Text"], nil, "Refresh"}),
    AppHeader = Opt:Header({name = "Appearances"}),
    Experience = Opt:Color({name = L["ExpBar_Mode_Experience"], hasAlpha = false}),
    ExpBarFill = Opt:MediaStatusbar({name = L["ExpBar_Options_Fill"]}),
    -- Reputation = Opt:Color({name = L["ExpBar_Mode_Reputation"], hasAlpha = false}),
    -- Azerite = Opt:Color({name = L["ExpBar_Mode_Artifact"], hasAlpha = false}),
    -- Honor = Opt:Color({name = L["ExpBar_Mode_Honor"], hasAlpha = false}),
}
