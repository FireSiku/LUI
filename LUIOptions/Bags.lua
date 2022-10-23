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
	NEW DESIGN?
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

OLD BAGS:

function module:LoadOptions()
	local function BagOpt()
		module:ReloadLayout("Bags")
		if db.CopyBags then module:CopyBags() end
	end
	local function BankOpt()
		module:ReloadLayout("Bank")
	end
	local function ReagentOpt()
		module:ReloadLayout("Reagents")
	end
	local function DisabledCopy()
		return db.Bank.CopyBags
	end
	local function ReloadBoth()
		module:ReloadLayout("Bags")
		module:ReloadLayout("Bank")
	end

	local options = {
		Bags = {
			name = "Bags",
			type = "group",
			order = 3,
			args = {
				Cols = LUI:NewSlider("Items Per Row", "Select how many items will be displayed per rows in your Bags.",
					2, db.Bags, "Cols", dbd.Bags, 4, 32, 1, BagOpt),
				Lock = LUI:NewToggle("Lock Frames", "Lock the Bags, Bank and Reagents frames in place", 3, db, "Lock", dbd,nil,"normal"),
				hideSort = LUI:NewToggle("Hide Sort Button", "Hide the Stack & Sort button from the bags window", 4, db, "hideSort", dbd, CheckSortButton, "normal"),
				Header = LUI:NewHeader("", 5),
				Padding = LUI:NewSlider("Bag Padding", "This sets the space between the background border and the adjacent items.",
					6, db.Bags, "Padding", dbd.Bags, 4, 24, 1, BagOpt),
				Spacing = LUI:NewSlider("Bag Spacing", "This sets the distance between items.",
					7, db.Bags, "Spacing", dbd.Bags, 1, 15, 1, BagOpt),
				Scale = LUI:NewScale("Bags Frame",8, db.Bags, "Scale", dbd.Bags, BagOpt),
				BagScale = LUI:NewScale("Bags BagBar",9, db.Bags, "BagScale", dbd.Bags, BagOpt),
				BagFrame = LUI:NewToggle("Show Bag Bar", nil, 10, db.Bags, "BagFrame", dbd.Bags, BagOpt),
				ItemQuality = LUI:NewToggle("Show Item Quality", nil, 11, db.Bags, "ItemQuality", dbd.Bags, ReloadBoth),
				ShowNew = LUI:NewToggle("Show New Item Animation", nil, 12, db.Bags, "ShowNew", dbd.Bags, ReloadBoth),
				ShowQuest = LUI:NewToggle("Show Quest Highlights", nil, 13, db.Bags, "ShowQuest", dbd.Bags, ReloadBoth),
				ShowOverlay = (LUI.IsRetail) and LUI:NewToggle("Show Overlays", nil, 14, db.Bags, "ShowOverlay", dbd.Bags, ReloadBoth) or nil,
			},
		},
		Bank = {
			name = "Bank",
			type = "group",
			order = 4,
			args = {
				CopyBags = LUI:NewToggle("Copy Bags", "Make the Bank and Reagents frames copy the bags options.", 1, db.Bank, "CopyBags", dbd.Bank,
					function()
						module:CheckBagsCopy()
						if db.Bank.CopyBags then module:CopyBags() end
					end, "normal"),
				Cols = LUI:NewSlider("Items Per Row", "Select how many items will be displayed per rows in your Bags.", 2,
					db.Bank, "Cols", dbd.Bank, 4, 32, 1, BankOpt),
				Header = LUI:NewHeader("", 3),
				Padding = LUI:NewSlider("Bank Padding", "This sets the space between the background border and the adjacent items.", 4,
					db.Bank, "Padding", dbd.Bank, 4, 24, 1, BankOpt, nil, DisabledCopy),
				Spacing = LUI:NewSlider("Bank Spacing", "This sets the distance between items.", 5,
					db.Bank, "Spacing", dbd.Bank, 1, 15, 1, BankOpt, nil, DisabledCopy),
				Scale = LUI:NewScale("Bank Frame",6, db.Bank, "Scale", dbd.Bank, BankOpt, nil, DisabledCopy),
				BagScale = LUI:NewScale("Bank BagBar",7, db.Bank, "BagScale", dbd.Bank, BankOpt, nil, DisabledCopy),
				BagFrame = LUI:NewToggle("Show Bag Bar", nil, 8, db.Bank, "BagFrame", dbd.Bank, BankOpt, nil, DisabledCopy),
			},
		},
		Reagents = LUI.IsRetail and {
			name = "Reagents",
			type = "group",
			order = 5,
			args = {
					Cols = LUI:NewSlider("Items Per Row", "Select how many items will be displayed per rows in your Bags.", 2,
					db.Reagents, "Cols", dbd.Reagents, 4, 32, 1, ReagentOpt),
				Header = LUI:NewHeader("", 3),
				Padding = LUI:NewSlider("Reagents Padding", "This sets the space between the background border and the adjacent items.", 4,
					db.Reagents, "Padding", dbd.Reagents, 4, 24, 1, ReagentOpt, nil, DisabledCopy),
				Spacing = LUI:NewSlider("Reagents Spacing", "This sets the distance between items.", 5,
					db.Reagents, "Spacing", dbd.Reagents, 1, 15, 1, ReagentOpt, nil, DisabledCopy),
				Scale = LUI:NewScale("Reagents Frame",6, db.Reagents, "Scale", dbd.Reagents, ReagentOpt, nil, DisabledCopy),
			},
		} or nil,
		Colors = {
			name = "Colors",
			type = "group",
			order = 6,
			args = {
				Background = module:NewColor("Background", "Bags Background", 1, ReloadBoth),
				Border = module:NewColor("Border", "Bags Border", 2, ReloadBoth),
				Professions = module:NewColor("Profession", "Profession Bags Borders", 3, ReloadBoth),
				BlackFrameBG = module:NewToggle("Black Frame Background", "This will force the Bags' Frame background to always be black.", 5, ReloadBoth),
			},
		},
		--Reminder for where to had new categories
	}

	return options
end
]]
