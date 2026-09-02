-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class Opt
local Opt = select(2, ...)

---@type AceLocale.Localizations, LUI.Minimap, AceDB-3.0
local L, module, db = Opt:GetLUIModule("Minimap")
if not module or not module.registered then return end

local Minimap = Opt:CreateModuleOptions("Minimap", module)
Minimap.disabled = function(info) return InCombatLockdown() or Opt.IsModDisabled(info) end
Minimap.get, Minimap.set = Opt.GetSet(db.General)

local function IndividualColorDisabled(colorName)
	return function() return db.Colors[colorName].t ~= "Individual" end
end

local function ResetIconPosition(iconName, x, y, scale)
	return function()
		local iconDB = db.Icons[iconName]
		iconDB.X, iconDB.Y, iconDB.Scale = x, y, scale
		module:PositionMinimapIcons()
	end
end

-- ####################################################################################################################
-- ##### Options Tables ###############################################################################################
-- ####################################################################################################################

Minimap.args = {
    Header = Opt:Header({name = _G.MINIMAP_LABEL}),
    AlwaysShowText = Opt:Toggle({name = L["Minimap_AlwaysShowText_Name"], desc = L["Minimap_AlwaysShowText_Desc"], width = "full"}),
    ShowTextures = Opt:Toggle({name = L["Minimap_ShowTextures_Name"], desc = L["Minimap_ShowTextures_Desc"], width = "full"}),
    CoordPrecision = Opt:Slider({name = L["Minimap_CoordPrecision_Name"], desc = L["Minimap_CoordPrecision_Desc"], min = 0, max = 2, step = 1}),
	Header2 = Opt:Header({name = "Appearance"}),
	ColorType = Opt:ColorSelect({name = "Minimap Color", arg = "Minimap"}),
	Minimap = Opt:Color({name = "Individual Color", hasAlpha = true, disabled = IndividualColorDisabled("Minimap")}),
	TextColor = Opt:InlineGroup({name = "Text Color", args = {
		TextType = Opt:ColorSelect({name = "Text Color", arg = "Text"}),
		Text = Opt:Color({name = "Individual Text Color", hasAlpha = false, disabled = IndividualColorDisabled("Text"), db = db.Colors}),
	}}),
	TextFont = Opt:FontMenu({name = "Text Font", customFontLocation = "Text"}),
	    -- Position
    PositionHeader = Opt:Header({name = L["Position"]}),
    X = Opt:PositionX({db = db.Position}),
    Y = Opt:PositionY({db = db.Position}),
	Point = Opt:Select({name = L["Anchor"], values = LUI.Points, db = db.Position}),
	Scale = Opt:Slider({name = L["Minimap_Scale_Name"], desc = L["Minimap_Scale_Desc"], values = Opt.ScaleValues, db = db.Position}),
	IconPositions = Opt:InlineGroup({name = "Minimap Icons", args = {
		Description = Opt:Desc({name = "Move and resize Blizzard-owned icons displayed inside the LUI minimap."}),
		Expansion = Opt:InlineGroup({name = "Omnium Tome / Expansion Button", db = db.Icons.Expansion, args = {
			X = Opt:PositionX(),
			Y = Opt:PositionY(),
			Scale = Opt:Slider({name = "Size", values = Opt.ScaleValues}),
			Reset = Opt:Execute({name = "Reset Position and Size", func = ResetIconPosition("Expansion", -2, 2, 0.75)}),
		}}),
		Notifications = Opt:InlineGroup({name = "Mail and Notification Icons", db = db.Icons.Notifications, args = {
			X = Opt:PositionX(),
			Y = Opt:PositionY(),
			Scale = Opt:Slider({name = "Size", values = Opt.ScaleValues}),
			Reset = Opt:Execute({name = "Reset Position and Size", func = ResetIconPosition("Notifications", 2, 2, 1)}),
		}}),
	}}),
}
