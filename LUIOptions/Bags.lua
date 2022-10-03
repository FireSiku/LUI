-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, Opt
local optName, Opt = ...
local L, module, db = Opt:GetLUIModule("Bags")
if not module or not module.registered then return end

-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################


-- ####################################################################################################################
-- ##### Options Table ################################################################################################
-- ####################################################################################################################

Opt.options.args.Bags = Opt:Group("Bags", nil, nil, "tab", true, nil, Opt.GetSet(db))
Opt.options.args.Bags.handler = module
local Bags = {

}

Opt.options.args.Bags.args = Bags


--[[
function module:LoadOptions()
	local options = {
		Header = module:NewHeader(L["Bags_Name"], 1),
		Settings = module:NewRootGroup(L["Settings"], 2, nil, nil, {
			--TODO: Add option-based functions.
			Lock = module:NewToggle(L["Bags_Lock_Name"], L["Bags_Lock_Desc"], 1),
			ItemQuality = module:NewToggle(L["Bags_ShowItemQuality_Name"], L["Bags_ShowItemQuality_Desc"], 2, "Refresh"),
			ShowNew = module:NewToggle(L["Bags_ShowNewItemAnim_Name"], L["Bags_ShowNewItemAnim_Desc"], 3, "Refresh"),
			ShowQuest = module:NewToggle(L["Bags_ShowQuestHighlights_Name"], L["Bags_ShowQuestHighlights_Desc"], 4, "Refresh"),
			Header1 = module:NewHeader("",5),
			RowSize = module:NewSlider(L["Bags_ItemsPerRow_Name"], L["Bags_ItemsPerRow_Desc"], 6, 8, 32, 1, nil,  "Refresh"),
			Scale = module:NewSlider(L["Scale"], L["Bags_Scale_Desc"], 7, 0.5, 2, 0.05, true, "Refresh"),
			Padding = module:NewSlider(L["Padding"], L["Bags_Padding_Desc"], 8, 4, 24, 1, nil, "Refresh"),
			Spacing = module:NewSlider(L["Spacing"], L["Bags_Spacing_Desc"], 9, 1, 15, 1, nil, "Refresh"),

		}),
		Textures = module:NewGroup(L["Textures"], 3, nil, nil, {
			BackgroundHeader = module:NewHeader(L["Background"], 1),
			BackgroundTex = module:NewTexBackground(L["Bags_BackgroundTex_Name"], L["BackgroundDesc"], 2, "Refresh", "double"),
			LineBreak = module:NewLineBreak(3),
			Background = module:NewColorMenu(L["Background"], 4, false, "RefreshColors"),
			ItemBackground = module:NewColorMenu(L["Bags_ItemBackground_Name"], 5, false, "RefreshColors"),
			Border = module:NewHeader(L["Border"], 6),
			BorderTex = module:NewTexBorder(L["Bags_BorderTex_Name"], L["BorderDesc"], 7, "Refresh", "double"),
			--BorderSize = module:NewSlider(L["Tooltip_BorderSize_Name"], L["Tooltip_BorderSize_Desc"], 7, 1, 30, 1, nil, "Refresh", "double"),
		}),
	}
	return options
end
]]
