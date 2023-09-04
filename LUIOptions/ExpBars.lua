-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class Opt
local Opt = select(2, ...)

---@type AceLocale.Localizations, LUI.ExperienceBars, AceDB-3.0
local L, module, db = Opt:GetLUIModule("ExpBars")
if not module or not module.registered then return end

-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################


-- ####################################################################################################################
-- ##### Options Table ################################################################################################
-- ####################################################################################################################

local ExpBars = Opt:CreateModuleOptions("ExpBars", module)

ExpBars.args = {
    Header = Opt:Header({name = L["ExpBar_Name"]}),
    ShowAzerite = Opt:Toggle({name = "Show Azerite XP"}),
			
	-- PositionHeader = Opt:Header({name = L["Position"]}),
	-- Position = Opt:Position({name = L["ExpBar_Name"], true, "Refresh"}),
	-- Point = Opt:Select({name = L["Anchor"], LUI.Points, nil, "Refresh"}),
	-- RelativePoint = Opt:Select({name = L["Relative Anchor"], LUI.Points, nil, "Refresh"}),
	--Spacing = Opt:Slider({name = L["Spacing"], desc = L["ExpBar_Options_Spacing_Desc"], {0, 20, 1}, false, "Refresh"}),
    TextPositionHeader = Opt:Header({name = L["ExpBar_Options_TextPosition"]}),
	ShowText = Opt:Toggle({name = L["ExpBar_Options_ShowText"]}),
	Precision = Opt:Slider({name = L["Precision"], min = 0, max = 3, softMax = 2, step = 1}),
    Spacer = Opt:Spacer(24, "full"),
    --Text = Opt:Position({name = L["ExpBar_Options_Text"], nil, "Refresh"}),
    AppHeader = Opt:Header({name = "Appearances"}),
    Experience = Opt:Color({name = L["ExpBar_Mode_Experience"], hasAlpha = false}),
    Reputation = Opt:Color({name = L["ExpBar_Mode_Reputation"], hasAlpha = false}),
    Azerite = Opt:Color({name = L["ExpBar_Mode_Artifact"], hasAlpha = false}),
    Honor = Opt:Color({name = L["ExpBar_Mode_Honor"], hasAlpha = false}),
}
