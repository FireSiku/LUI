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


-- ####################################################################################################################
-- ##### Options Tables ###############################################################################################
-- ####################################################################################################################

Opt.options.args.Minimap = Opt:Group("Minimap", nil, nil, "tab", Opt.IsModDisabled, nil, Opt.GetSet(db.General))
Opt.options.args.Minimap.handler = module

local Minimap = {
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

Opt.options.args.Minimap.args = Minimap
--[[
		Position = module:NewGroup(L["Position"], 3, nil, nil, {
			Position = module:NewPosition(L["Position"], 1, true, "SetMinimapSize"),
			Point = module:NewSelect({name = L["Anchor"], LUI.Points, nil, "SetMinimapSize"}),
			Scale = module:NewSlider({name = L["Minimap_Scale_Name"], desc = L["Minimap_Scale_Desc"], 0.5, 2.5, 0.25, true, "SetMinimapSize"}),
		}),
]]
