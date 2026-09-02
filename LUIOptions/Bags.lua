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

local function GenerateBagsOptions()
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
			PositionHeader = Opt:Header({name = L["Position"]}),
			X = Opt:PositionX(),
			Y = Opt:PositionY(),
			Spacer4 = Opt:Spacer({}),
			ItemQuality = Opt:Toggle({name = "Show Item Quality", desc = "Colors item borders by their quality", width = "full"}),
		ShowNew = Opt:Toggle({name = "Show New Item Animation", desc = "Highlights items marked as 'new'", width = "full"}),
		ShowQuest = Opt:Toggle({name = "Show Quest Items", desc = "Highlights items that are part of a quest", width = "full"}),
		ShowOverlay = Opt:Toggle({name = "Show Item Overlay", desc = "Display the overlay used for various types of items like Cosmetics and Crafting Quality.", width = "full"}),
		ItemLevel = Opt:Toggle({name = "Show Item Level", desc = "Add Item Levels indicators for equipment", width = "full"}),
	}
	return options
end

local function IndividualColorDisabled(colorName)
	return function() return db.Colors[colorName].t ~= "Individual" end
end

local function ColorOptions(name, colorName)
	return {
		[colorName.."Type"] = Opt:ColorSelect({name = name.." Color", arg = colorName}),
		[colorName] = Opt:Color({name = name.." Individual Color", hasAlpha = true, disabled = IndividualColorDisabled(colorName), db = db.Colors}),
	}
end

Bags.args = {
	Header = Opt:Header({name = L["Bags_Name"]}),
	Backpack = Opt:Group({name = L["Backpack Options"], db = db.Bags, args = GenerateBagsOptions()}),
	Appearance = Opt:Group({name = L["Textures"], args = {
		BackgroundTex = Opt:MediaBackground({name = L["Background"], db = db.Textures}),
		BorderTex = Opt:MediaBorder({name = L["Border"], db = db.Textures}),
		BorderSize = Opt:Slider({name = L["Thickness"], min = 1, max = 32, step = 1, db = db.Textures}),
		BagFont = Opt:FontMenu({name = "Bag Text", customFontLocation = "Bags"}),
		StackFont = Opt:FontMenu({name = "Item Count and Level", customFontLocation = "Stack"}),
		Search = Opt:InlineGroup({name = "Search", args = ColorOptions("Search", "Search")}),
		Background = Opt:InlineGroup({name = L["Background"], args = ColorOptions(L["Background"], "Background")}),
		Border = Opt:InlineGroup({name = L["Border"], args = ColorOptions(L["Border"], "Border")}),
		ItemBackground = Opt:InlineGroup({name = "Item Background", args = ColorOptions("Item Background", "ItemBackground")}),
		Professions = Opt:InlineGroup({name = "Profession Bag Slots", args = ColorOptions("Profession Bag Slots", "Professions")}),
		BagText = Opt:InlineGroup({name = "Bag Text", args = ColorOptions("Bag Text", "Bags")}),
		StackText = Opt:InlineGroup({name = "Item Count and Level", args = ColorOptions("Item Count and Level", "Stack")}),
	}}),
}
