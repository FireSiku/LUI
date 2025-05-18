-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class Opt
local Opt = select(2, ...)

---@type AceLocale.Localizations, LUI.Minimap, AceDB-3.0
local L, module, db = Opt:GetLUIModule("Minimap")
if not module or not module.registered then return end

local Minimap = Opt:CreateModuleOptions("Minimap", module)
Minimap.get, Minimap.set = Opt.GetSet(db.General)

-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################


-- ####################################################################################################################
-- ##### Options Tables ###############################################################################################
-- ####################################################################################################################

Minimap.args = {
    Header = Opt:Header({name = _G.MINIMAP_LABEL}),
    AlwaysShowText = Opt:Toggle({name = L["Minimap_AlwaysShowText_Name"], desc = L["Minimap_AlwaysShowText_Desc"], width = "full"}),
    ShowTextures = Opt:Toggle({name = L["Minimap_ShowTextures_Name"], desc = L["Minimap_ShowTextures_Desc"], width = "full"}),
    --Spacer = Opt:Spacer(9, "full"),
    CoordPrecision = Opt:Slider({name = L["Minimap_CoordPrecision_Name"], desc = L["Minimap_CoordPrecision_Desc"], min = 0, max = 2, step = 1}),
	Header2 = Opt:Header({name = "Appearance"}),
	ColorType = Opt:ColorSelect({name = "Minimap Color", arg = "Minimap"}),
	Minimap = Opt:Color({name = "Individual Color", hasAlpha = true}),
	Text = Opt:FontMenu({name = "Text Font"}),
	    -- Position
    PositionHeader = Opt:Header({name = L["Position"]}),
    X = Opt:Input({name = L["API_XValue_Name"], desc = format(L["API_XValue_Desc"], _G.MINIMAP_LABEL), db = db.Position}),
    Y = Opt:Input({name = L["API_YValue_Name"], desc = format(L["API_YValue_Desc"], _G.MINIMAP_LABEL), db = db.Position}),
	Point = Opt:Select({name = L["Anchor"], values = LUI.Points, db = db.Position}),
	Scale = Opt:Slider({name = L["Minimap_Scale_Name"], desc = L["Minimap/;_Scale_Desc"], values = Opt.ScaleValues, db = db.Position}),
}

--[[
		Position = module:NewGroup(L["Position"], 3, nil, nil, {
			Position = module:NewPosition(L["Position"], 1, true, "SetMinimapSize"),
			Point = module:NewSelect({name = L["Anchor"], LUI.Points, nil, "SetMinimapSize"}),
			Scale = module:NewSlider({name = L["Minimap_Scale_Name"], desc = L["Minimap_Scale_Desc"], 0.5, 2.5, 0.25, true, "SetMinimapSize"}),
		}),
]]
