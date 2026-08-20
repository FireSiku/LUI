-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class Opt
local Opt = select(2, ...)

---@type AceLocale.Localizations, LUI.MirrorBar, AceDB-3.0
local L, module, db = Opt:GetLUIModule("Mirror Bar")
if not module or not module.registered then return end

local MirrorBar = Opt:CreateModuleOptions("Mirror Bar", module)

-- ####################################################################################################################
-- ##### Options Tables ###############################################################################################
-- ####################################################################################################################

MirrorBar.args = {
    Header = Opt:Header({name = L["Mirror Bar"]}),
	General = Opt:Group({name = "General Settings", db = db.General, args = {
		Width = Opt:InputNumber({name = "Width", desc = "Choose the Width for the Mirror Bar."}),
		Height = Opt:InputNumber({name = "Height", desc = "Choose the Height for the Mirror Bar."}),
		empty1 = Opt:Spacer(),
		X = Opt:InputNumber({name = "X Value", desc = "Choose the X Value for the Mirror Bar."}),
		Y = Opt:InputNumber({name = "Y Value", desc = "Choose the Y Value for the Mirror Bar."}),
		empty2 = Opt:Spacer(),
		Texture = Opt:MediaStatusbar({name = "Texture", desc = "Choose the Mirror Bar Texture."}),
		TextureBG = Opt:MediaStatusbar({name = "Background Texture", desc = "Choose the MirrorBar Background Texture."}),
		BarGap = Opt:Slider({name = "Spacing", desc = "Select the Spacing between mirror bars when shown.", min = 0, max = 40, step = 1}),
		ArchyBar = Opt:Toggle({name = "Archaeology Progress Bar", desc = "Integrate the Archaeology Progress bar", width = "full"}),
	}}),
	Border = Opt:Group({name = "Border", db = db.Border, args = {
		Texture = Opt:MediaBorder({name = "Border Texture", desc = "Choose the Border Texture."}),
		Color = Opt:Color({name = "Border", desc = "Border", hasAlpha = false, db = db.Border}),
		Thickness = Opt:InputNumber({name = "Border Thickness", desc = "Value for your Castbar Border Thickness."}),
		empty2 = Opt:Spacer(),
		Inset = Opt:InlineGroup({name = "Insets", db = db.Border.Inset, args = {
			left = Opt:InputNumber({name = "Left", desc = "Value for the left Border Inset.", width = "half"}),
			right = Opt:InputNumber({name = "Right", desc = "Value for the right Border Inset.", width = "half"}),
			top = Opt:InputNumber({name = "Top", desc = "Value for the top Border Inset.", width = "half"}),
			bottom = Opt:InputNumber({name = "Bottom", desc = "Value for the bottom Border Inset.", width = "half"}),
		}})
	}}),
	Colors = Opt:Group({name = "Bar Colors", db = db.Colors, args = {
		FatigueBar = Opt:Color({name = "Fatigue Bar", desc = "Fatigue Bar"}),
		BreathBar = Opt:Color({name = "Breath Bar", desc = "Breath Bar"}),
		FeignBar = Opt:Color({name = "Feign Death Bar", desc = "Feign Death Bar"}),
		Bar = Opt:Color({name = "Other Bar", desc = "Other Mirror Bars"}),
		ArchyBar = Opt:Color({name = "Archaeology Progress Bar", desc = "Archaeology Progress Bar"}),
		Background = Opt:Color({name = "Background", desc = "MirrorBar Background"}),
	}}),
	NameText = Opt:Group({name = "Name Text Settings", db = db.Text.Name, args = {
		Font = Opt:MediaFont({name = "Font", desc = "Choose the Font for the Mirror Name Text."}),
		Color = Opt:Color({name = "Name", desc = "Mirror Name", hasAlpha = false, db = db.Text.Name}),
		Size = Opt:Slider({name = "Size", desc = "Choose the Font Size for the Mirror Name Text.", min = 6, max = 40, step = 1}),
		empty2 = Opt:Spacer(),
		OffsetX = Opt:InputNumber({name = "X Value", desc = "Choose the X Value for the Mirror Name Text."}),
		OffsetY = Opt:InputNumber({name = "Y Value", desc = "Choose the Y Value for the Mirror Name Text."}),
	}}),
	TimeText = Opt:Group({name = "Time Text Settings", db = db.Text.Time, args = {
		Font = Opt:MediaFont({name = "Font", desc = "Choose the Font for the Mirror Time Text."}),
		Color = Opt:Color({name = "Time", desc = "Mirror Time", hasAlpha = false, db = db.Text.Time}),
		Size = Opt:Slider({name = "Size", desc = "Choose the Font Size for the Mirror Time Text.", min = 6, max = 40, step = 1}),
		empty2 = Opt:Spacer(),
		OffsetX = Opt:InputNumber({name = "X Value", desc = "Choose the X Value for the Mirror Time Text."}),
		OffsetY = Opt:InputNumber({name = "Y Value", desc = "Choose the Y Value for the Mirror Time Text."}),
	}}),
}
