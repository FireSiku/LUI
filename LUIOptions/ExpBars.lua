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
local function AbsTextHidden() return not db.ShowText or not db.ShowCurrent end

local colorMenuOptions = {}

ExpBars.args = {
    Header = Opt:Header({name = L["ExpBar_Name"]}),
    SplitTracker = Opt:Toggle({name = L["ExpBar_Options_SplitTracker"], width = "double"}),
    Spacing = Opt:Slider({name = L["Spacing"], desc = L["ExpBar_Options_Spacing_Desc"], min = 0, max = 20, step = 1}),
    ShowAzerite = Opt:Toggle({name = "Show Azerite XP when Heart of Azeroth is equipped.", width = "full"}),
    AppHeader = Opt:Header({name = "Appearances"}),
    ExperienceType = Opt:ColorMenu(colorMenuOptions, {name = L["ExpBar_Mode_Experience"], arg = "Experience"}),
    ReputationType = Opt:ColorMenu(colorMenuOptions, {name = "Reputation", arg = "Reputation"}),
    HonorType = Opt:ColorMenu(colorMenuOptions, {name = "Honor", arg = "Honor"}),
    AzeriteType = Opt:ColorMenu(colorMenuOptions, {name = "Azerite", arg = "Azerite"}),
    HouseFavorType = Opt:ColorMenu(colorMenuOptions, {name = "House Favor", arg = "HouseFavor"}),
    ExpBarFill = Opt:MediaStatusbar({name = L["ExpBar_Options_Fill"]}),
    ExpBarBg = Opt:MediaStatusbar({name = "Background Texture"}),
	BackgroundMultiplier = Opt:Slider({name = "Background Darkness", min = 0, max = 1, step = 0.01, isPercent = true}),
    Spacer1 = Opt:Spacer({}),
	Width = Opt:InputNumber({name = "Width"}),
	Height = Opt:InputNumber({name = "Height"}),
	PositionHeader = Opt:Header({name = L["Position"]}),
	X = Opt:PositionX(),
	Y = Opt:PositionY(),
	Point = Opt:Select({name = L["Anchor"], values = LUI.Points}),
	RelativePoint = Opt:Select({name = L["Relative Anchor"].." (UIParent)", values = LUI.Points}),
    Spacer2 = Opt:Spacer({}),
	TextX = Opt:OffsetX({disabled = IsTextDisabled}),
	TextY = Opt:OffsetY({disabled = IsTextDisabled}),
    TextPositionHeader = Opt:Header({name = "Text Settings"}),
	TextFont = Opt:InlineGroup({name = "Font", db = db.Fonts.Text, disabled = IsTextDisabled, args = {
		Name = Opt:MediaFont({name = "Font"}),
		Size = Opt:Slider({name = "Size", min = 6, max = 40, step = 1}),
		Flag = Opt:Select({name = "Outline", values = LUI.FontFlags}),
	}}),
	ShowText = Opt:Toggle({name = L["ExpBar_Options_ShowText"]}),
    ShowPercent = Opt:Toggle({name = L["Show Percent"], disabled = IsTextDisabled}),
	Precision = Opt:Slider({name = L["Precision"], min = 0, max = 3, softMax = 2, step = 1, disabled = IsTextDisabled}),
    Spacer3 = Opt:Spacer({}),
    ShowCurrent = Opt:Toggle({name = L["Show Current"], disabled = IsTextDisabled}),
    ShowMax = Opt:Toggle({name = L["Show Max"], disabled = AbsTextHidden}),
	ShortNumbers = Opt:Toggle({name = L["Short Numbers"] , disabled = AbsTextHidden}),
}

Mixin(ExpBars.args, colorMenuOptions)
