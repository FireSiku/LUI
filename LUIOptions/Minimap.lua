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
	MinimapColorType = Opt:Select({name = "Minimap Color", values = LUI.ColorTypes,
		get = function(info) return db.Colors.Minimap.t end, --getter
		set = function(info, value) db.Colors.Minimap.t = value; module:RefreshColors() end}), --setter
	Minimap = Opt:Color({name = "Individual Color", hasAlpha = true}),
	
	Header2 = Opt:Header({name = "Appearance"}),
	Text = Opt:FontMenu({name = "Text Font"})
}

--[[
		Position = module:NewGroup(L["Position"], 3, nil, nil, {
			Position = module:NewPosition(L["Position"], 1, true, "SetMinimapSize"),
			Point = module:NewSelect({name = L["Anchor"], LUI.Points, nil, "SetMinimapSize"}),
			Scale = module:NewSlider({name = L["Minimap_Scale_Name"], desc = L["Minimap_Scale_Desc"], 0.5, 2.5, 0.25, true, "SetMinimapSize"}),
		}),
]]
