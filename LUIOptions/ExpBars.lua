-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class Opt
local Opt = select(2, ...)

---@type AceLocale.Localizations, LUI.ExperienceBars, AceDB-3.0
local L, module = Opt:GetLUIModule("Experience Bars")
if not module or not module.registered then return end

-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################

local function GetDB()
	return module.db.profile
end

local function GetValue(info)
	local value = GetDB()[info[#info]]
	if info.type == "input" then
		return value == nil and "" or tostring(value)
	elseif info.type == "range" then
		return tonumber(value)
	end
	return value
end

local function SetValue(info, value)
	if info.type == "input" or info.type == "range" then
		value = tonumber(value)
		if value == nil then return end
	end
	GetDB()[info[#info]] = value
	if module.Refresh then module:Refresh() end
end

local function IsTextDisabled()
	return not GetDB().ShowText
end

local function AbsTextHidden()
	local db = GetDB()
	return not db.ShowText or not db.ShowCurrent
end

local function IsSpacingDisabled()
	local db = GetDB()
	return not db.SplitTracker or db.SeparateTrackerBars
end

local function IsSeparateBarsDisabled()
	return not GetDB().SplitTracker
end

local function IsSecondarySettingsDisabled()
	local db = GetDB()
	return not db.SplitTracker or not db.SeparateTrackerBars
end

local function FontGet(info)
	local font = GetDB().Fonts.Text
	return font[info[#info]]
end

local function FontSet(info, value)
	local font = GetDB().Fonts.Text
	font[info[#info]] = value
	if module.Refresh then module:Refresh() end
end

-- ####################################################################################################################
-- ##### Options Table ################################################################################################
-- ####################################################################################################################

local ExpBars = Opt:CreateModuleOptions("Experience Bars", module)
-- CreateModuleOptions inherits generic get/set functions from the profile table that
-- exists when LUIOptions loads. Override them here so the page always uses the active
-- Experience Bars profile after profile changes, copies and resets.
ExpBars.get = GetValue
ExpBars.set = SetValue

local TRACKER_LABEL_VALUES = {
	None = "None",
	Short = "Short",
	Full = "Full",
}

local colorMenuOptions = {}

ExpBars.args = {
	Header = Opt:Header({name = L["ExpBar_Name"]}),
	SplitTracker = Opt:Toggle({
		name = L["ExpBar_Options_SplitTracker"],
		desc = "Show a second active tracker when one is available.",
		width = "double",
	}),
	SeparateTrackerBars = Opt:Toggle({
		name = "Separate tracked bars",
		desc = "Give the second tracker its own position and width instead of splitting the main bar in half.",
		width = "double",
		disabled = IsSeparateBarsDisabled,
	}),
	Spacing = Opt:Slider({
		name = L["Spacing"],
		desc = L["ExpBar_Options_Spacing_Desc"],
		min = 0,
		max = 20,
		step = 1,
		disabled = IsSpacingDisabled,
	}),
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

	PrimaryHeader = Opt:Header({name = "Primary Bar"}),
	Width = Opt:InputNumber({name = "Width"}),
	Height = Opt:InputNumber({name = "Height"}),
	Lock = Opt:Toggle({name = "Lock Bars", desc = "Unlock to drag the primary bar and, when separated, the secondary bar."}),
	X = Opt:PositionX(),
	Y = Opt:PositionY(),
	Point = Opt:Select({name = L["Anchor"], values = LUI.Points}),
	RelativePoint = Opt:Select({name = L["Relative Anchor"].." (UIParent)", values = LUI.Points}),

	SecondaryHeader = Opt:Header({name = "Secondary Bar"}),
	SecondaryWidth = Opt:InputNumber({name = "Width", disabled = IsSecondarySettingsDisabled}),
	SecondaryX = Opt:PositionX({disabled = IsSecondarySettingsDisabled}),
	SecondaryY = Opt:PositionY({disabled = IsSecondarySettingsDisabled}),
	SecondaryPoint = Opt:Select({name = L["Anchor"], values = LUI.Points, disabled = IsSecondarySettingsDisabled}),
	SecondaryRelativePoint = Opt:Select({name = L["Relative Anchor"].." (UIParent)", values = LUI.Points, disabled = IsSecondarySettingsDisabled}),

	TextPositionHeader = Opt:Header({name = "Text Settings"}),
	TextX = Opt:OffsetX({disabled = IsTextDisabled}),
	TextY = Opt:OffsetY({disabled = IsTextDisabled}),
	TextFont = Opt:InlineGroup({name = "Font", disabled = IsTextDisabled, get = FontGet, set = FontSet, args = {
		Name = Opt:MediaFont({name = "Font"}),
		Size = Opt:Slider({name = "Size", min = 6, max = 40, step = 1}),
		Flag = Opt:Select({name = "Outline", values = LUI.FontFlags}),
	}}),
	ShowText = Opt:Toggle({name = L["ExpBar_Options_ShowText"]}),
	TrackerLabel = Opt:Select({
		name = "Tracker Label",
		desc = "Choose how the tracked progress type is named on the bar.",
		values = TRACKER_LABEL_VALUES,
		sorting = {"None", "Short", "Full"},
		disabled = IsTextDisabled,
	}),
	ShowTooltip = Opt:Toggle({name = "Show Tooltip", desc = "Show the tracker name and full progress when hovering over a bar."}),
	ShowPercent = Opt:Toggle({name = L["Show Percent"], disabled = IsTextDisabled}),
	Precision = Opt:Slider({name = L["Precision"], min = 0, max = 3, softMax = 2, step = 1, disabled = IsTextDisabled}),
	Spacer3 = Opt:Spacer({}),
	ShowCurrent = Opt:Toggle({name = L["Show Current"], disabled = IsTextDisabled}),
	ShowMax = Opt:Toggle({name = L["Show Max"], disabled = AbsTextHidden}),
	ShortNumbers = Opt:Toggle({name = L["Short Numbers"], disabled = AbsTextHidden}),
}

Mixin(ExpBars.args, colorMenuOptions)
