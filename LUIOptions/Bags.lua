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
