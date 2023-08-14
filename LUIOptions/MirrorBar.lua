-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, Opt
local optName, Opt = ...
local L, module, db = Opt:GetLUIModule("Mirror Bar")
if not module or not module.registered then return end

-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################


-- ####################################################################################################################
-- ##### Options Tables ###############################################################################################
-- ####################################################################################################################

Opt.options.args.MirrorBar = Opt:Group("Mirror Bar", nil, nil, "tab", Opt.IsModDisabled, nil, Opt.GetSet(db))
Opt.options.args.MirrorBar.handler = module

local MirrorBar = {
    -- General
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

Opt.options.args.MirrorBar.args = MirrorBar


-- ####################################################################################################################
-- ##### Old Options ###############################################################################################
-- ####################################################################################################################

--- Note: New Option calls will automatically call self:Refresh when changed.
--- The part where we defined a function to be called in the Setter is not needed anymore and was dropped. 

-- function module:LoadOptions()
-- 	local applyMirrorbar = function() self:Refresh() end
-- 	local applyArchybar = function() self:ToggleArchy() end

-- 	local options = {
-- 		Title = self:NewHeader("Mirror Bar", 1),
-- 		General = self:NewGroup("General Settings", 2, {
-- 			Width = self:NewInputNumber("Width", "Choose the Width for the Mirror Bar.", 1, applyMirrorbar, nil),
-- 			Height = self:NewInputNumber("Height", "Choose the Height for the Mirror Bar.", 2, applyMirrorbar, nil),
-- 			X = self:NewInputNumber("X Value", "Choose the X Value for the Mirror Bar.", 3, applyMirrorbar, nil),
-- 			Y = self:NewInputNumber("Y Value", "Choose the Y Value for the Mirror Bar.", 4, applyMirrorbar, nil),
-- 			empty2 = self:NewDesc(" ", 5),
-- 			Texture = self:NewSelect("Texture", "Choose the Mirror Bar Texture.", 6, widgetLists.statusbar, "LSM30_Statusbar", applyMirrorbar, nil),
-- 			TextureBG = self:NewSelect("Background Texture", "Choose the MirrorBar Background Texture.", 7, widgetLists.statusbar, "LSM30_Statusbar", applyMirrorbar, nil),
-- 			BarGap = self:NewSlider("Spacing", "Select the Spacing between mirror bars when shown.", 8, 0, 40, 1, applyMirrorbar, nil, nil),
-- 			ArchyBar = self:NewToggle("Archaeology Progress Bar", "Integrate the Archaeology Progress bar", 9, applyArchybar),
-- 		}),
-- 		Colors = self:NewGroup("Bar Colors", 4, nil, {
-- 			FatigueBar = self:NewColor("Fatigue Bar", "Fatigue Bar", 1, applyMirrorbar),
-- 			BreathBar = self:NewColor("Breath Bar", "Breath Bar", 2, applyMirrorbar),
-- 			FeignBar = self:NewColor("Feign Death Bar", "Feign Death Bar", 3, applyMirrorbar),
-- 			Bar = self:NewColor("Other Bar", "Other Mirror Bars", 4, applyMirrorbar),
-- 			ArchyBar = self:NewColor("Archaeology Progress Bar", "Archaeology Progress Bar", 5(?:, nil)+\), applyMirrorbar),
-- 			Background = self:NewColor("Background", "MirrorBar Background", 6, applyMirrorbar),
-- 		}),
-- 		Text = self:NewGroup("Text Settings", 5, nil, {
-- 			Name = self:NewGroup("Name", 1, true, {
-- 				Font = self:NewSelect("Font", "Choose the Font for the Mirror Name Text.", 2, widgetLists.font, "LSM30_Font", applyMirrorbar, nil),
-- 				Color = self:NewColorNoAlpha("Name", "Mirror Name", 3, applyMirrorbar, nil),
-- 				Size = self:NewSlider("Size", "Choose the Font Size for the Mirror Name Text.", 4, 1, 40, 1, applyMirrorbar, nil, nil),
-- 				empty2 = self:NewDesc(" ", 5),
-- 				OffsetX = self:NewInputNumber("X Value", "Choose the X Value for the Mirror Name Text.", 6, applyMirrorbar, nil),
-- 				OffsetY = self:NewInputNumber("Y Value", "Choose the Y Value for the Mirror Name Text.", 7, applyMirrorbar, nil),
-- 			}),
-- 			Time = self:NewGroup("Time Settings", 2, true, {
-- 				Font = self:NewSelect("Font", "Choose the Font for the Mirror Time Text.", 2, widgetLists.font, "LSM30_Font", applyMirrorbar, nil),
-- 				Color = self:NewColorNoAlpha("Time", "Mirror Time", 3, applyMirrorbar, nil),
-- 				Size = self:NewSlider("Size", "Choose the Font Size for the Mirror Time Text.", 4, 1, 40, 1, applyMirrorbar, nil, nil),
-- 				empty2 = self:NewDesc(" ", 5),
-- 				OffsetX = self:NewInputNumber("X Value", "Choose the X Value for the Mirror Time Text.", 6, applyMirrorbar, nil),
-- 				OffsetY = self:NewInputNumber("Y Value", "Choose the Y Value for the Mirror Time Text.", 7, applyMirrorbar, nil),
-- 			})
-- 		}),
-- 		Border = self:NewGroup("Border", 3, {
-- 			Texture = self:NewSelect("Border Texture", "Choose the Border Texture.", 1, widgetLists.border, "LSM30_Border", applyMirrorbar),
-- 			Color = self:NewColor("Border", "Border", 2, applyMirrorbar),
-- 			Thickness = self:NewInputNumber("Border Thickness", "Value for your Castbar Border Thickness.", 3, applyMirrorbar),
-- 			empty2 = self:NewDesc(" ", 4),
-- 			Inset = self:NewGroup("Insets", 5, true, {
-- 				left = self:NewInputNumber("Left", "Value for the left Border Inset.", 1, applyMirrorbar, "half"),
-- 				right = self:NewInputNumber("Right", "Value for the right Border Inset.", 2, applyMirrorbar, "half"),
-- 				top = self:NewInputNumber("Top", "Value for the top Border Inset.", 3, applyMirrorbar, "half"),
-- 				bottom = self:NewInputNumber("Bottom", "Value for the bottom Border Inset.", 4, applyMirrorbar, "half"),
-- 			}),
-- 		}),
-- 	}
-- 	return options
-- end
