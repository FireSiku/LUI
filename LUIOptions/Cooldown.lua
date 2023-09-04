-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class Opt
local Opt = select(2, ...)

---@type AceLocale.Localizations, LUI.Cooldown, AceDB-3.0
local L, module, db = Opt:GetLUIModule("Cooldown")
if not module or not module.registered then return end

local Cooldown = Opt:CreateModuleOptions("Cooldown", module)

-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################


-- ####################################################################################################################
-- ##### Options Table ################################################################################################
-- ####################################################################################################################

Cooldown.args = {
    -- General
    Header = Opt:Header({name = L["Cooldown"]}),
	General = Opt:Group({name = "General Settings", db = db.General, args =  {
		Width = Opt:InputNumber({name = "Width", desc = "Choose the Width for the Cooldown."}),
		Height = Opt:InputNumber({name = "Height", desc = "Choose the Height for the Cooldown."}),
		empty1 = Opt:Desc({name = " "}),
		X = Opt:InputNumber({name = "X Value", desc = "Choose the X Value for the Cooldown."}),
		Y = Opt:InputNumber({name = "Y Value", desc = "Choose the Y Value for the Cooldown."}),
		empty2 = Opt:Desc({name = " "}),
		Texture = Opt:MediaStatusbar({name = "Texture", desc = "Choose the Cooldown Texture."}),
		TextureBG = Opt:MediaStatusbar({name = "Background Texture", desc = "Choose the Cooldown Background Texture."}),
		BarGap = Opt:Slider({name = "Spacing", desc = "Select the Spacing between mirror bars when shown.", min = 0, max = 40, step = 1}),
		ArchyBar = Opt:Toggle({name = "Archaeology Progress Bar", desc = "Integrate the Archaeology Progress bar", width = "full"}),
	}}),
	NameText = Opt:Group({name = "Name Text Settings", db = db.Text.Name, args = {
		Font = Opt:MediaFont({name = "Font", desc = "Choose the Font for the Mirror Name Text."}),
		Color = Opt:Color({name = "Name", desc = "Mirror Name", hasAlpha = false, db = db.Text.Name}),
		Size = Opt:Slider({name = "Size", desc = "Choose the Font Size for the Mirror Name Text.", min = 6, max = 40, step = 1}),
		empty2 = Opt:Desc({name = " "}),
		OffsetX = Opt:InputNumber({name = "X Value", desc = "Choose the X Value for the Mirror Name Text."}),
		OffsetY = Opt:InputNumber({name = "Y Value", desc = "Choose the Y Value for the Mirror Name Text."}),
	}}),
	Colors = Opt:Group({name = "Bar Colors", db = db.Colors, args = {
		FatigueBar = Opt:Color({name = "Fatigue Bar", desc = "Fatigue Bar"}),
		BreathBar = Opt:Color({name = "Breath Bar", desc = "Breath Bar"}),
		FeignBar = Opt:Color({name = "Feign Death Bar", desc = "Feign Death Bar"}),
		Bar = Opt:Color({name = "Other Bar", desc = "Other Cooldowns"}),
		ArchyBar = Opt:Color({name = "Archaeology Progress Bar", desc = "Archaeology Progress Bar"}),
		Background = Opt:Color({name = "Background", desc = "Cooldown Background"}),
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
		General = self:NewGroup("General Settings", 1, {
			Threshold = self:NewInputNumber({name = "Cooldown Threshold", desc = "The time at which your coodown text is colored differnetly and begins using specified precision.", func}),
			MinDuration = self:NewInputNumber({name = "Minimum Duration", desc = "The lowest cooldown duration that timers will be shown for.", func}),
			Precision = self:NewSlider({name = "Cooldown Precision", desc = "How many decimal places will be shown once time is within the cooldown threshold.", 0, 2, 1, func}),
			MinScale = self:NewSlider({name = "Minimum Scale", desc = "The smallest size of icons that timers will be shown for.", 0, 2, 0.1, func}),
			MinToSec = self:NewSlider({name = "Minute to Seconds", desc = "The time at which your cooldown is shown in seconds instead of minutes.", 60, 300, 60, func}),
			FilterWA = self:NewToggle({name = "Filter WeakAuras", desc = "Prevent the cooldown module from interacting with WeakAuras to prevent conflict."}),
			SupportAll = self:NewToggle({name = "Support All Cooldown Types", "Show cooldown timers for everything that contains cooldown progress.\n\nNote: Blizzard will sometime use cooldown values to display alternate forms of progress, desc = enabling this could add an unwanted timer on them."}),
		}),
		Text = self:NewGroup("Text Settings", 2, {
			Font = self:NewSelect({name = "Font", desc = "Select the font to be used by cooldown's texts.", AceGUIWidgetLSMlists.font, "LSM30_Font", func}),
			Size = self:NewSlider({name = "Font Size", desc = "Select the font size to be used by cooldown's texts.", 6, 32, 1, func}),
			Flag = self:NewSelect({name = "Font Outline", desc = "Select the font outline to be used by cooldown's texts.", LUI.FontFlags, false, func}),
			Offsets = self:NewHeader("Text Position", 4),
			XOffset = self:NewInputNumber({name = "X Offset", desc = "Horizontal offset to be applied to the cooldown's texts.", func}),
			YOffset = self:NewInputNumber({name = "Y Offset", desc = "Vertical offset to be applied to the cooldown's texts.", func}),
			Align = self:NewSelect("Alignment", "Alignment to be applied to the cooldown's texts", 7, alignTable, false, func)
		}),
		Colors = self:NewGroup("Colors", 3, {
			Threshold = self:NewColorNoAlpha({name = "Threshold", desc = "The color of cooldown's text under the threshold.", func}),
			Sec = self:NewColorNoAlpha({name = "Seconds", desc = "The color of cooldown's text when representing seconds.", func}),
			Min = self:NewColorNoAlpha({name = "Minutes", desc = "The color of cooldown's text when representing minutes.", func}),
			Hour = self:NewColorNoAlpha({name = "Hours", desc = "The color of cooldown's text when representing hours.", func}),
			Day = self:NewColorNoAlpha({name = "Days", desc = "The color of cooldown's text when representing days.", func}),
		}),
	}
	return options
end

]]
