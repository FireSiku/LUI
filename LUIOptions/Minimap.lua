-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, Opt
local optName, Opt = ...
local L, module, db = Opt:GetLUIModule("Minimap")
if not module or not module.registered then return end


-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################

local colorGet, colorSet = Opt.ColorGetSet(db.Colors)

-- ####################################################################################################################
-- ##### Options Tables ###############################################################################################
-- ####################################################################################################################

Opt.options.args.Minimap = Opt:Group("Minimap", nil, nil, "tab", Opt.IsModDisabled, nil, Opt.GetSet(db))
Opt.options.args.Minimap.handler = module

local Minimap = {
    Header = Opt:Header(_G.MINIMAP_LABEL, 1),
    AlwaysShowText = Opt:Toggle(L["Minimap_AlwaysShowText_Name"], L["Minimap_AlwaysShowText_Desc"], 2, nil, "full"),
    ShowTextures = Opt:Toggle(L["Minimap_ShowTextures_Name"], L["Minimap_ShowTextures_Desc"], 3, nil, "full"),
    --Spacer = Opt:Spacer(9, "full"),
    MinimapColorType = Opt:Select("Minimap Color", nil, 10, LUI.ColorTypes, nil, nil, nil, function(info) return db.Colors.Minimap.t end, function(info, value) db.Colors.Minimap.t = value end),
	Minimap = Opt:Color("Individual Color", nil, 11, true, nil, nil, nil, colorGet, colorSet),
	CoordPrecision = Opt:Slider(L["Minimap_CoordPrecision_Name"], L["Minimap_CoordPrecision_Desc"], 12, {min = 0, max = 2, step = 1}),
	Header2 = Opt:Header("Appearance", 13),
	Text = Opt:FontMenu("Text Font", nil,  14)
}

Opt.options.args.Minimap.args = Minimap
--[[
		Position = module:NewGroup(L["Position"], 3, nil, nil, {
			Position = module:NewPosition(L["Position"], 1, true, "SetMinimapSize"),
			Point = module:NewSelect(L["Anchor"], nil, 2, LUI.Points, nil, "SetMinimapSize"),
			Scale = module:NewSlider(L["Minimap_Scale_Name"], L["Minimap_Scale_Desc"], 5, 0.5, 2.5, 0.25, true, "SetMinimapSize"),
		}),
]]