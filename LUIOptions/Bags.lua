-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class Opt
local Opt = select(2, ...)

---@type AceLocale.Localizations, LUI.Bags, AceDB-3.0
local L, module, db = Opt:GetLUIModule("Bags")
if not module or not module.registered then return end

local Bags = Opt:CreateModuleOptions("Bags", module)

-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################


-- ####################################################################################################################
-- ##### Options Table ################################################################################################
-- ####################################################################################################################

local function GenerateBagsOptions(kind)
	local options = {
		RowSize = Opt:Slider({name = "Items Per Row", desc = "Select how many items will be displayed per rows.", min = 1, max = 32, step = 1}),
		Spacer = Opt:Spacer({}),
		Padding = Opt:Slider({name = "Padding", desc = "Distance between the frame's edge and the items.", min = 0, max = 32, step = 1 }),
		Spacing = Opt:Slider({name = "Spacing", desc = "Distance between items.", min = 0, max = 32, step = 1}),
		Scale = Opt:Slider({name = "Scale", desc = "Overall size of the container frame", min = 0.5, max = 2, step = 0.1}),
		Spacer2 = Opt:Spacer({}),
		Lock = Opt:Toggle({name = "Lock Frame", desc = "Lock the frame in place"}),
		BagBar = Opt:Toggle({name = "Show Bag Bar", desc = "Show the Bags bar"}),
		BagNewline = Opt:Toggle({name = "Newline After Bags", desc = "Starts a new row for each bag."}),
		Spacer3 = Opt:Spacer({}),
		ItemQuality = Opt:Toggle({name = "Show Item Quality", desc = "Colors item borders by their quality", width = "full"}),
		ShowNew = Opt:Toggle({name = "Show New Item Animation", desc = "Highlights items marked as 'new'", width = "full"}),
		ShowQuest = Opt:Toggle({name = "Show Quest Items", desc = "Highlights items that are part of a quest", width = "full"}),
		ShowOverlay = Opt:Toggle({name = "Show Item Overlay", desc = "Display the overlay used for various types of items like Cosmetics and Crafting Quality.", width = "full"}),
		ItemLevel = Opt:Toggle({name = "Show Item Level", desc = "Add Item Levels indicators for equipment", width = "full"}),
	}
	return options
end

local Settings = {
}

local Textures = {
}

Bags.args = {
	Header = Opt:Header({name = L["Bags_Name"]}),
	Settings = Opt:Group({name = L["General Settings"], hidden = true, db = db, args = Settings}),
	Backpack = Opt:Group({name = L["Backpack Options"], db = db.Bags, args = GenerateBagsOptions("Backpack")}),
	Bank = Opt:Group({name = L["Bank Options"], db = db.Bank, args = GenerateBagsOptions("Bank")}),
	Reagents = Opt:Group({name = L["Reagents Options"], hidden = true, db = db.Reagent, args = GenerateBagsOptions("Reagents")}),
	Textures = Opt:Group({name = L["Textures"], hidden = true, db = db.Textures, args = Textures}),
}

--[[
	local options = {
		RowSize = Opt:Slider({name = "Items Per Row", desc = "Select how many items will be displayed per rows.", min = 1, max = 32, step = 1 }),
		Spacer = Opt:Spacer(3),
		Padding = Opt:Slider({name = "Padding", desc = "Distance between the frame's edge and the items.", { min = 0, max = 32, step = 1 }}),
		Spacing = Opt:Slider({name = "Spacing", desc = "Distance between items.", { min = 0, max = 32, step = 1 }}),
		Scale = Opt:Slider({name = "Scale", desc = "Overall size of the container frame", { min = 0.5, max = 2, step = 0.1 }}),
		Spacer2 = Opt:Spacer(7),
		Lock = Opt:Toggle("Lock Frame",  "Lock the frame in place", 8),
		BagBar = Opt:Toggle({name = "Show Bag Bar", desc = "Show the Bags bar"}),
		BagNewline = Opt:Toggle({name = "Newline After Bags", desc = "Starts a new row for each bag."}),
		Spacer3 = Opt:Spacer(11),
		ItemQuality = Opt:Toggle({name = "Show Item Quality", desc = "Colors item borders by their quality", width = "full"}),
		ShowNew = Opt:Toggle({name = "Show New Item Animation", desc = "Highlights items marked as 'new'", width = "full"}),
		ShowQuest = Opt:Toggle({name = "Show Quest Items", desc = "Highlights items that are part of a quest", width = "full"}),
		ShowOverlay = Opt:Toggle({name = "Show Item Overlay", desc = "Display the overlay used for various types of items like Cosmetics and Crafting Quality.", width = "full"}),
		ItemLevel = Opt:Toggle({name = "Show Item Level", desc = "Add Item Levels indicators for equipment", width = "full"}),
	}
]]

--[[
module.defaults = {
	profile = {
		--Container Settings
		Lock = false,
		RowSize = 16,
		Padding = 8,
		Spacing = 4,
		Scale = 1,
		ShowBagBar = true,
		ShowItemQuality = true,
		BagNewline = false,
		ShowNew = false,
		ShowQuest = true,
		BackgroundTexture = "Blizzard Tooltip",
		BorderTexture = "Stripped_medium",
		BorderSize = 5,
		Bags = {
			RowSize = 16,
			Padding = 8,
			Spacing = 4,
			Scale = 1,
			BagBar = true,
			ItemQuality = true,
			BagNewline = false,
			ShowNew = false,
			ShowQuest = true,
			ShowOverlay = true,
			BackgroundTexture = "Blizzard Tooltip",
			BorderTexture = "Stripped_medium",
			BorderSize = 5,
			X = 0,
			Y = 0,
		},
		Bank = {
			Lock = false,
			RowSize = 16,
			Padding = 8,
			Spacing = 4,
			Scale = 1,
			BagBar = true,
			ItemQuality = true,
			BagNewline = false,
			ShowNew = false,
			ShowQuest = true,
			ShowOverlay = true,
			BackgroundTexture = "Blizzard Tooltip",
			BorderTexture = "Stripped_medium",
			BorderSize = 5,
			X = 0,
			Y = 0,
		},
		Textures = {
			BackgroundTex = "Blizzard Tooltip",
			BorderTex = "Stripped_medium",
			BorderSize = 5,
		},
		-- Fonts and Colors
		Fonts = {
			Bags = { Name = "NotoSans-SCB", Size = 12, Flag = "OUTLINE", },
			Stack = { Name = "NotoSans-SCB", Size = 12, Flag = "OUTLINE", },
		},
		Colors = {
			Search =         { r = 0.6,  g = 0.6,  b = 1,    a = 1,   t = "Class",      },
			Border =         { r = 0.2,  g = 0.2,  b = 0.2,  a = 1,   t = "Individual", },
			Background =     { r = 0.18, g = 0.18, b = 0.18, a = 0.8, t = "Class",      },
			ItemBackground = { r = 0.18, g = 0.18, b = 0.18, a = 0.8, t = "Individual", },
			Professions = { r = 0.1, g = 0.5, b = 0.2, },
			Bags =        { r = 1,   g = 1,   b = 1,   },
			--TODO: Add support for FrameBorder and FrameBackground
			--FrameBackground = { r = 0.09, g = 0.09, b = 0.09, a = 0.8, t = "Individual", },
		},
	},
}


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
