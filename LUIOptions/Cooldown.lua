-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class Opt
local Opt = select(2, ...)

---@type AceLocale.Localizations, LUI.Cooldown, AceDB-3.0
local L, module, db = Opt:GetLUIModule("Cooldown")
--if not module or not module.registered then return end

local Cooldown = Opt:CreateModuleOptions("Cooldown", module)

-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################
local alignTable = {
	LEFT = "Left",
	CENTER = "Center",
	RIGHT = "Right",
}

-- ####################################################################################################################
-- ##### Options Table ################################################################################################
-- ####################################################################################################################

Cooldown.args = {
	General = Opt:Group({name = "General Settings", db = db.General, args = {
		Threshold = Opt:InputNumber({name = "Cooldown Threshold", desc = "The time at which your coodown text is colored differnetly and begins using specified precision."}),
		MinDuration = Opt:InputNumber({name = "Minimum Duration", desc = "The lowest cooldown duration that timers will be shown for."}),
		Precision = Opt:Slider({name = "Cooldown Precision", desc = "How many decimal places will be shown once time is within the cooldown threshold.", min = 0, max = 2, step = 1}),
		MinScale = Opt:Slider({name = "Minimum Scale", desc = "The smallest size of icons that timers will be shown for.", min = 0, max = 2, step = 0.1}),
		MinToSec = Opt:Slider({name = "Minute to Seconds", desc = "The time at which your cooldown is shown in seconds instead of minutes.", min = 60, max = 300, step = 60}),
		FilterWA = Opt:Toggle({name = "Filter WeakAuras", desc = "Prevent the cooldown module from interacting with WeakAuras to prevent conflict."}),
		SupportAll = Opt:Toggle({name = "Support All Cooldown Types", desc = "Show cooldown timers for everything that contains cooldown progress.\n\nNote: Blizzard will sometime use cooldown values to display alternate forms of progress, enabling this could add an unwanted timer on them."}),
	}}),
	Text = Opt:Group({name = "Text Settings", db = db.Text, args = {
		Font = Opt:MediaFont({name = "Font", desc = "Select the font to be used by cooldown's texts."}),
		Size = Opt:Slider({name = "Font Size", desc = "Select the font size to be used by cooldown's texts.", min = 6, max = 32, step = 1}),
		Flag = Opt:Select({name = "Font Outline", desc = "Select the font outline to be used by cooldown's texts.", values = LUI.FontFlags}),
		Offsets = Opt:Header({name = "Text Position"}),
		XOffset = Opt:InputNumber({name = "X Offset", desc = "Horizontal offset to be applied to the cooldown's texts."}),
		YOffset = Opt:InputNumber({name = "Y Offset", desc = "Vertical offset to be applied to the cooldown's texts."}),
		Align = Opt:Select({name = "Alignment", desc = "Alignment to be applied to the cooldown's texts", values = alignTable})
	}}),
	Colors = Opt:Group({name = "Colors", db = db.Colors, args = {
		Threshold = Opt:Color({name = "Threshold", desc = "The color of cooldown's text under the threshold.", hasAlpha = false}),
		Sec = Opt:Color({name = "Seconds", desc = "The color of cooldown's text when representing seconds.", hasAlpha = false}),
		Min = Opt:Color({name = "Minutes", desc = "The color of cooldown's text when representing minutes.", hasAlpha = false}),
		Hour = Opt:Color({name = "Hours", desc = "The color of cooldown's text when representing hours.", hasAlpha = false}),
		Day = Opt:Color({name = "Days", desc = "The color of cooldown's text when representing days.", hasAlpha = false}),
	}}),
}

-- ####################################################################################################################
-- ##### Old Options ###############################################################################################
-- ####################################################################################################################
--[[ 
	
function module:LoadOptions()
	local func = "Refresh"
	
	local alignTable = {
		LEFT = "Left",
		CENTER = "Center",
		RIGHT = "Right",
	}
	
	local options = {
		General = Opt:Group("General Settings", 1, {
			Threshold = Opt:InputNumber({name = "Cooldown Threshold", desc = "The time at which your coodown text is colored differnetly and begins using specified precision."}),
			MinDuration = Opt:InputNumber({name = "Minimum Duration", desc = "The lowest cooldown duration that timers will be shown for."}),
			Precision = Opt:Slider({name = "Cooldown Precision", desc = "How many decimal places will be shown once time is within the cooldown threshold.", 0, 2, 1}),
			MinScale = Opt:Slider({name = "Minimum Scale", desc = "The smallest size of icons that timers will be shown for.", 0, 2, 0.1}),
			MinToSec = Opt:Slider({name = "Minute to Seconds", desc = "The time at which your cooldown is shown in seconds instead of minutes.", 60, 300, 60}),
			FilterWA = Opt:Toggle({name = "Filter WeakAuras", desc = "Prevent the cooldown module from interacting with WeakAuras to prevent conflict."}),
			SupportAll = Opt:Toggle({name = "Support All Cooldown Types", "Show cooldown timers for everything that contains cooldown progress.\n\nNote: Blizzard will sometime use cooldown values to display alternate forms of progress, desc = enabling this could add an unwanted timer on them."}),
		}),
		Text = Opt:Group("Text Settings", 2, {
			Font = Opt:Select({name = "Font", desc = "Select the font to be used by cooldown's texts.", AceGUIWidgetLSMlists.font, "LSM30_Font"}),
			Size = Opt:Slider({name = "Font Size", desc = "Select the font size to be used by cooldown's texts.", 6, 32, 1}),
			Flag = Opt:Select({name = "Font Outline", desc = "Select the font outline to be used by cooldown's texts.", LUI.FontFlags, false}),
			Offsets = Opt:Header("Text Position", 4),
			XOffset = Opt:InputNumber({name = "X Offset", desc = "Horizontal offset to be applied to the cooldown's texts."}),
			YOffset = Opt:InputNumber({name = "Y Offset", desc = "Vertical offset to be applied to the cooldown's texts."}),
			Align = Opt:Select("Alignment", "Alignment to be applied to the cooldown's texts", 7, alignTable, false, func)
		}),
		Colors = Opt:Group("Colors", 3, {
			Threshold = Opt:ColorNoAlpha({name = "Threshold", desc = "The color of cooldown's text under the threshold."}),
			Sec = Opt:ColorNoAlpha({name = "Seconds", desc = "The color of cooldown's text when representing seconds."}),
			Min = Opt:ColorNoAlpha({name = "Minutes", desc = "The color of cooldown's text when representing minutes."}),
			Hour = Opt:ColorNoAlpha({name = "Hours", desc = "The color of cooldown's text when representing hours."}),
			Day = Opt:ColorNoAlpha({name = "Days", desc = "The color of cooldown's text when representing days."}),
		}),
	}
	return options
end

]]
