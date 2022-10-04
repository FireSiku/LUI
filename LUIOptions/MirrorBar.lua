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
    Header = Opt:Header(L["Mirror Bar"], 1),
	General = Opt:Group("General Settings", nil, 2, nil, nil, nil, Opt.GetSet(db.General)),
	Border = Opt:Group("Border", nil, 3, nil, nil, nil, Opt.GetSet(db.Border)),
	Colors = Opt:Group("Bar Colors", nil, 4, nil, nil, nil, Opt.GetSet(db.Colors)),
	NameText = Opt:Group("Name Text Settings", nil, 5, nil, nil, nil, Opt.GetSet(db.Text.Name)),
	TimeText = Opt:Group("Time Text Settings", nil, 5, nil, nil, nil, Opt.GetSet(db.Text.Time)),
}

local GeneralTab = {
	Width = Opt:InputNumber("Width", "Choose the Width for the Mirror Bar.", 1),
	Height = Opt:InputNumber("Height", "Choose the Height for the Mirror Bar.", 2),
	empty1 = Opt:Desc(" ", 3),
	X = Opt:InputNumber("X Value", "Choose the X Value for the Mirror Bar.", 4),
	Y = Opt:InputNumber("Y Value", "Choose the Y Value for the Mirror Bar.", 5),
	empty2 = Opt:Desc(" ", 6),
	Texture = Opt:MediaStatusbar("Texture", "Choose the Mirror Bar Texture.", 7),
	TextureBG = Opt:MediaStatusbar("Background Texture", "Choose the MirrorBar Background Texture.", 8),
	BarGap = Opt:Slider("Spacing", "Select the Spacing between mirror bars when shown.", 9, {min = 0, max = 40, step = 1}),
	ArchyBar = Opt:Toggle("Archaeology Progress Bar", "Integrate the Archaeology Progress bar", 10, nil, "full"),
}

local ColorTab = {
	FatigueBar = Opt:Color("Fatigue Bar", "Fatigue Bar", 1),
	BreathBar = Opt:Color("Breath Bar", "Breath Bar", 2),
	FeignBar = Opt:Color("Feign Death Bar", "Feign Death Bar", 3),
	Bar = Opt:Color("Other Bar", "Other Mirror Bars", 4),
	ArchyBar = Opt:Color("Archaeology Progress Bar", "Archaeology Progress Bar", 5),
	Background = Opt:Color("Background", "MirrorBar Background", 6),
}

local NameText = {
	Font = Opt:MediaFont("Font", "Choose the Font for the Mirror Name Text.", 2),
	Color = Opt:Color("Name", "Mirror Name", 4, false, nil, nil, nil, Opt.ColorGetSet(db.Text.Name)),
	Size = Opt:Slider("Size", "Choose the Font Size for the Mirror Name Text.", 3, {min = 6, max = 40, step = 1}),
	empty2 = Opt:Desc(" ", 5),
	OffsetX = Opt:InputNumber("X Value", "Choose the X Value for the Mirror Name Text.", 6),
	OffsetY = Opt:InputNumber("Y Value", "Choose the Y Value for the Mirror Name Text.", 7),
}

local TimeText = {
	Font = Opt:MediaFont("Font", "Choose the Font for the Mirror Time Text.", 2),
	Color = Opt:Color("Time", "Mirror Time", 4, false, nil, nil, nil, Opt.ColorGetSet(db.Text.Time)),
	Size = Opt:Slider("Size", "Choose the Font Size for the Mirror Time Text.", 3, {min = 6, max = 40, step = 1}),
	empty2 = Opt:Desc(" ", 5),
	OffsetX = Opt:InputNumber("X Value", "Choose the X Value for the Mirror Time Text.", 6),
	OffsetY = Opt:InputNumber("Y Value", "Choose the Y Value for the Mirror Time Text.", 7),
}

local BorderTab = {
	Texture = Opt:MediaBorder("Border Texture", "Choose the Border Texture.", 1),
	Color = Opt:Color("Border", "Border", 2, nil, nil, nil, Opt.ColorGetSet(db.Border)),
	Thickness = Opt:InputNumber("Border Thickness", "Value for your Castbar Border Thickness.", 3),
	empty2 = Opt:Desc(" ", 4),
	Inset = Opt:InlineGroup("Insets", nil, 5, nil, nil, nil, Opt.GetSet(db.Border.Inset))
}

local BorderInsets = {
	left = Opt:InputNumber("Left", "Value for the left Border Inset.", 1, nil, "half"),
	right = Opt:InputNumber("Right", "Value for the right Border Inset.", 2, nil, "half"),
	top = Opt:InputNumber("Top", "Value for the top Border Inset.", 3, nil, "half"),
	bottom = Opt:InputNumber("Bottom", "Value for the bottom Border Inset.", 4, nil, "half"),
}

Opt.options.args.MirrorBar.args = MirrorBar

--- Link the groups together.
MirrorBar.General.args = GeneralTab
MirrorBar.Colors.args = ColorTab
MirrorBar.NameText.args = NameText
MirrorBar.TimeText.args = TimeText
MirrorBar.Border.args = BorderTab
BorderTab.Inset.args = BorderInsets

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