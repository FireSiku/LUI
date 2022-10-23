-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, Opt
local optName, Opt = ...
local L, module, db = Opt:GetLUIModule("Cooldown")
if not module or not module.registered then return end

-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################


-- ####################################################################################################################
-- ##### Options Tables ###############################################################################################
-- ####################################################################################################################

Opt.options.args.Cooldown = Opt:Group("Cooldown", nil, nil, "tab", Opt.IsModDisabled, nil, Opt.GetSet(db))
Opt.options.args.Cooldown.handler = module

local Cooldown = {
    -- General
    Header = Opt:Header(L["Cooldown"], 1),
	General = Opt:Group("General Settings", nil, 2, nil, nil, nil, Opt.GetSet(db.General)),
	NameText = Opt:Group("Name Text Settings", nil, 5, nil, nil, nil, Opt.GetSet(db.Text.Name)),
	Colors = Opt:Group("Bar Colors", nil, 4, nil, nil, nil, Opt.GetSet(db.Colors)),
}

local GeneralTab = {
	Width = Opt:InputNumber("Width", "Choose the Width for the Cooldown.", 1),
	Height = Opt:InputNumber("Height", "Choose the Height for the Cooldown.", 2),
	empty1 = Opt:Desc(" ", 3),
	X = Opt:InputNumber("X Value", "Choose the X Value for the Cooldown.", 4),
	Y = Opt:InputNumber("Y Value", "Choose the Y Value for the Cooldown.", 5),
	empty2 = Opt:Desc(" ", 6),
	Texture = Opt:MediaStatusbar("Texture", "Choose the Cooldown Texture.", 7),
	TextureBG = Opt:MediaStatusbar("Background Texture", "Choose the Cooldown Background Texture.", 8),
	BarGap = Opt:Slider("Spacing", "Select the Spacing between mirror bars when shown.", 9, {min = 0, max = 40, step = 1}),
	ArchyBar = Opt:Toggle("Archaeology Progress Bar", "Integrate the Archaeology Progress bar", 10, nil, "full"),
}

local ColorTab = {
	FatigueBar = Opt:Color("Fatigue Bar", "Fatigue Bar", 1),
	BreathBar = Opt:Color("Breath Bar", "Breath Bar", 2),
	FeignBar = Opt:Color("Feign Death Bar", "Feign Death Bar", 3),
	Bar = Opt:Color("Other Bar", "Other Cooldowns", 4),
	ArchyBar = Opt:Color("Archaeology Progress Bar", "Archaeology Progress Bar", 5),
	Background = Opt:Color("Background", "Cooldown Background", 6),
}

local NameText = {
	Font = Opt:MediaFont("Font", "Choose the Font for the Mirror Name Text.", 2),
	Color = Opt:Color("Name", "Mirror Name", 4, false, nil, nil, nil, Opt.ColorGetSet(db.Text.Name)),
	Size = Opt:Slider("Size", "Choose the Font Size for the Mirror Name Text.", 3, {min = 6, max = 40, step = 1}),
	empty2 = Opt:Desc(" ", 5),
	OffsetX = Opt:InputNumber("X Value", "Choose the X Value for the Mirror Name Text.", 6),
	OffsetY = Opt:InputNumber("Y Value", "Choose the Y Value for the Mirror Name Text.", 7),
}

Opt.options.args.Cooldown.args = Cooldown

--- Link the groups together.
Cooldown.General.args = GeneralTab
Cooldown.Colors.args = ColorTab
Cooldown.NameText.args = NameText

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
			Threshold = self:NewInputNumber("Cooldown Threshold", "The time at which your coodown text is colored differnetly and begins using specified precision.", 1, func),
			MinDuration = self:NewInputNumber("Minimum Duration", "The lowest cooldown duration that timers will be shown for.", 2, func),
			Precision = self:NewSlider("Cooldown Precision", "How many decimal places will be shown once time is within the cooldown threshold.", 3, 0, 2, 1, func),
			MinScale = self:NewSlider("Minimum Scale", "The smallest size of icons that timers will be shown for.", 4, 0, 2, 0.1, func),
			MinToSec = self:NewSlider("Minute to Seconds", "The time at which your cooldown is shown in seconds instead of minutes.", 4, 60, 300, 60, func),
			FilterWA = self:NewToggle("Filter WeakAuras", "Prevent the cooldown module from interacting with WeakAuras to prevent conflict.", 5),
			SupportAll = self:NewToggle("Support All Cooldown Types", "Show cooldown timers for everything that contains cooldown progress.\n\nNote: Blizzard will sometime use cooldown values to display alternate forms of progress, enabling this could add an unwanted timer on them.", 6),
		}),
		Text = self:NewGroup("Text Settings", 2, {
			Font = self:NewSelect("Font", "Select the font to be used by cooldown's texts.", 1, AceGUIWidgetLSMlists.font, "LSM30_Font", func),
			Size = self:NewSlider("Font Size", "Select the font size to be used by cooldown's texts.", 2, 6, 32, 1, func),
			Flag = self:NewSelect("Font Outline", "Select the font outline to be used by cooldown's texts.", 3, LUI.FontFlags, false, func),
			Offsets = self:NewHeader("Text Position", 4),
			XOffset = self:NewInputNumber("X Offset", "Horizontal offset to be applied to the cooldown's texts.", 5, func),
			YOffset = self:NewInputNumber("Y Offset", "Vertical offset to be applied to the cooldown's texts.", 6, func),
			Align = self:NewSelect("Alignment", "Alignment to be applied to the cooldown's texts", 7, alignTable, false, func)
		}),
		Colors = self:NewGroup("Colors", 3, {
			Threshold = self:NewColorNoAlpha("Threshold", "The color of cooldown's text under the threshold.", 1, func),
			Sec = self:NewColorNoAlpha("Seconds", "The color of cooldown's text when representing seconds.", 2, func),
			Min = self:NewColorNoAlpha("Minutes", "The color of cooldown's text when representing minutes.", 3, func),
			Hour = self:NewColorNoAlpha("Hours", "The color of cooldown's text when representing hours.", 4, func),
			Day = self:NewColorNoAlpha("Days", "The color of cooldown's text when representing days.", 5, func),
		}),
	}
	return options
end

]]