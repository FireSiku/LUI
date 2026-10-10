-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class Opt
local Opt = select(2, ...)

---@type AceLocale.Localizations, LUI.Bags, AceDB-3.0
local L, module = Opt:GetLUIModule("Bags")
if not module or not module.registered then return end

local Bags = Opt:CreateModuleOptions("Bags", module)

local function GetSectionValue(section)
	return function(info)
		local db = module.db.profile[section]
		local value = db and db[info[#info]]
		if info.type == "input" then
			return value == nil and "" or tostring(value)
		elseif info.type == "range" then
			return tonumber(value)
		end
		return value
	end
end

local function SetSectionValue(section)
	return function(info, value)
		local db = module.db.profile[section]
		if not db then return end
		if info.type == "input" or info.type == "range" then
			value = tonumber(value)
			if value == nil then return end
		end
		db[info[#info]] = value
		if module.Refresh then module:Refresh() end
	end
end

local GetBagValue = GetSectionValue("Bags")
local SetBagValue = SetSectionValue("Bags")
local GetTextureValue = GetSectionValue("Textures")

local function IsItemBorderColorDisabled()
	local db = module.db and module.db.profile and module.db.profile.Bags
	return db and db.ItemQuality
end

local function SetTextureValue(info, value)
	local db = module.db.profile.Textures
	if not db then return end
	if info.type == "range" then
		value = tonumber(value)
		if value == nil then return end
		local key = info[#info]
		if key == "ItemBorderSize" then
			value = math.min(6, math.max(1, value))
		elseif key == "BorderSize" then
			value = math.min(32, math.max(1, value))
		end
	end
	db[info[#info]] = value

	-- SharedMedia is resolved and the LUI bag skin is reapplied in one refresh.
	if module.Refresh then module:Refresh() end
end

-- ####################################################################################################################
-- ##### Options Table ################################################################################################
-- ####################################################################################################################

local function GenerateBagsOptions()
	return {
		RowSize = Opt:Slider({name = "Items Per Row", desc = "Select how many items will be displayed per row.", min = 1, max = 32, step = 1}),
		Spacer = Opt:Spacer({}),
		Padding = Opt:Slider({name = "Padding", desc = "Distance between the frame edge and the items.", min = 0, max = 32, step = 1}),
		Spacing = Opt:Slider({name = "Spacing", desc = "Distance between items.", min = 0, max = 32, step = 1}),
		Scale = Opt:Slider({name = "Scale", desc = "Overall size of the container frame.", min = 0.5, max = 2, step = 0.1}),
		Spacer2 = Opt:Spacer({}),
		Lock = Opt:Toggle({name = "Lock Frame", desc = "Lock the frame in place."}),
		BagBar = Opt:Toggle({name = "Show Bag Bar", desc = "Show the bag bar."}),
        ShowKeyringButton = Opt:Toggle({
            name = "Show Keyring Button",
            desc = "Show the native keyring shortcut beside Clean Bags. Blizzard's keyring visibility setting must also be enabled.",
            hidden = function() return not Opt.LUI:HasClientFeature("Keyring") end,
            width = "full",
        }),
		BagNewline = Opt:Toggle({name = "Newline After Bags", desc = "Start a new row for each bag."}),
        ReverseCleanUp = Opt:Toggle({
            name = "Fill Bags from Bottom",
            desc = "Clean Bags fills toward the bottom of the LUI bag window. Slots within each bag are displayed in reverse order so partly filled bags meet the full bags below. Disable to fill from the top. Changing this option also cleans up your bags. Reagent bag restrictions and bag filters still apply.",
            width = "full",
            get = function() return module:GetFillBagsFromBottom() end,
            set = function(_, value)
                module:SetFillBagsFromBottom(value)
            end,
        }),
		Spacer3 = Opt:Spacer({}),
		PositionHeader = Opt:Header({name = L["Position"]}),
		X = Opt:PositionX(),
		Y = Opt:PositionY(),
		Spacer4 = Opt:Spacer({}),
		ItemQuality = Opt:Toggle({name = "Show Item Quality", desc = "Color items and equipped bags in the bag bar by quality, including gray for poor and white for common items. Empty item slots have no border. Item Border Color is disabled while this is enabled; empty bag sockets and utility buttons use Bag Border Color.", width = "full"}),
		ShowNew = Opt:Toggle({name = "Show New Item Animation", desc = "Highlight items marked as new.", width = "full"}),
		ShowQuest = Opt:Toggle({name = "Show Quest Items", desc = "Highlight items that are part of a quest.", width = "full"}),
		ShowOverlay = Opt:Toggle({name = "Show Item Overlay", desc = "Display Blizzard item overlays such as cosmetics and crafting quality.", width = "full"}),
		ItemLevel = Opt:Toggle({name = "Show Item Level", desc = "Show item levels on equippable items.", width = "full"}),
	}
end

local function ColorOptions(name, colorName, disabled, desc)
	local options = {}
	options[colorName.."Type"] = Opt:ColorMenu(options, {name = name, arg = colorName, disabled = disabled, desc = desc})
	return options
end


Bags.args = {
	Header = Opt:Header({name = L["Bags_Name"]}),
	Backpack = Opt:Group({name = L["Backpack Options"], get = GetBagValue, set = SetBagValue, args = GenerateBagsOptions()}),
    Bank = Opt:Group({name = "Bank Options", hidden = Opt.LUI.IsForever, get = GetSectionValue("Bank"), set = SetSectionValue("Bank"), args = {
        Enabled = Opt:Toggle({name = "Use LUI Bank", desc = "Use LUI backgrounds, borders and a row-based item grid for the character and Warband bank. Blizzard's bank tabs, item actions, access restrictions and confirmation dialogs remain active.", width = "full"}),
        Description = Opt:Desc({name = "The bank shares the Textures page and Show Item Quality setting with your bags. Open a banker to preview changes. Disable Use LUI Bank to restore Blizzard's appearance."}),
        Layout = Opt:InlineGroup({name = "Bank Layout", disabled = function() return not module.db.profile.Bank.Enabled end, args = {
            FillFromBottom = Opt:Toggle({name = "Fill Bank from Bottom", desc = "Display bank slots from bottom-right to top-left, so Clean Bank fills toward the bottom of each tab. Disable to fill from the top. Independent of the bag sorting option.", width = "full"}),
            RowSize = Opt:Slider({name = "Items Per Row", desc = "Number of bank slots per row.", min = 8, max = 20, step = 1}),
            Spacing = Opt:Slider({name = "Spacing", desc = "Distance between bank slots.", min = 0, max = 12, step = 1}),
            ColumnGroupSpacing = Opt:Slider({name = "Column Group Spacing", desc = "Extra space after every two bank columns. Set to 0 for a uniform grid or 11 for Blizzard's additional gap between column pairs.", min = 0, max = 24, step = 1}),
            Scale = Opt:Slider({name = "Scale", desc = "Overall size of the bank frame.", min = .5, max = 1.5, step = .1}),
        }}),
    }}),
	Appearance = Opt:Group({name = L["Textures"], args = {
		BackgroundTex = Opt:MediaBackground({
			name = "Background Texture",
			desc = "Changes the background artwork used by the bag frame and toolbars.",
			get = GetTextureValue, set = SetTextureValue,
		}),
		BorderTex = Opt:MediaBorder({
			name = "Bag Border Texture",
			desc = "Changes the SharedMedia border texture used by the outer bag frame and the toolbars above it.",
			get = GetTextureValue, set = SetTextureValue,
		}),
		BorderSize = Opt:Slider({
			name = "Bag Border Thickness", desc = "Changes the outer border thickness of the bag frame and toolbars without resizing their backgrounds. The bundled Stripped textures use the visible border width.",
			min = 1, max = 32, step = 1, get = GetTextureValue, set = SetTextureValue,
		}),
		ItemBorderTex = Opt:MediaBorder({
			name = "Item Border Texture",
			desc = "Changes the SharedMedia border texture used by item and toolbar slots.",
			get = GetTextureValue, set = SetTextureValue,
		}),
		ItemBorderSize = Opt:Slider({
			name = "Item Border Thickness", desc = "Changes the border thickness used by item and toolbar slots.",
			min = 1, max = 6, step = 1, get = GetTextureValue, set = SetTextureValue,
		}),
		BagFont = Opt:FontMenu({name = "Bag Text", customFontLocation = "Bags"}),
		StackFont = Opt:FontMenu({name = "Item Count and Level", customFontLocation = "Stack"}),
		Search = Opt:InlineGroup({name = "Search", args = ColorOptions("Search", "Search")}),
		Background = Opt:InlineGroup({name = L["Background"], args = ColorOptions(L["Background"], "Background", nil, "Used as the fill when no background texture is selected. With a texture selected, only this color setting's opacity is used and the artwork itself is not tinted.")}),
		Border = Opt:InlineGroup({name = "Bag Border", args = ColorOptions("Bag Border", "Border")}),
		ItemBorder = Opt:InlineGroup({name = "Item Border", args = ColorOptions("Item Border", "ItemBorder", IsItemBorderColorDisabled)}),
		ItemBackground = Opt:InlineGroup({name = "Item Background", args = ColorOptions("Item Background", "ItemBackground", nil, "Colors the slot backplate underneath item icons, similar to a Masque button backdrop. This does not change the item border color.")}),
		Professions = Opt:InlineGroup({name = "Profession Bag Slots", args = ColorOptions("Profession Bag Slots", "Professions")}),
		BagText = Opt:InlineGroup({name = "Bag Text", args = ColorOptions("Bag Text", "Bags")}),
		StackText = Opt:InlineGroup({name = "Item Count and Level", args = ColorOptions("Item Count and Level", "Stack")}),
	}}),
}
