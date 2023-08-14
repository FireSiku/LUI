-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, Opt
local optName, Opt = ...
local L, module, db = Opt:GetLUIModule("Auras")
if not module or not module.registered then return end

-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################


-- ####################################################################################################################
-- ##### Options Tables ###############################################################################################
-- ####################################################################################################################

Opt.options.args.Auras = Opt:Group("Auras", nil, nil, "tab", Opt.IsModDisabled, nil, Opt.GetSet(db))
Opt.options.args.Auras.handler = module

local Auras = {
    -- General
    Header = Opt:Header({name = L["Auras"]}),
	General = Opt:Group({name = "General Settings", db = db.General}),
	NameText = Opt:Group({name = "Name Text Settings", db = db.Text.Name}),
	Colors = Opt:Group({name = "Bar Colors", db = db.Colors}),
}

local GeneralTab = {
	Width = Opt:InputNumber({name = "Width", desc = "Choose the Width for the Auras."}),
	Height = Opt:InputNumber({name = "Height", desc = "Choose the Height for the Auras."}),
	empty1 = Opt:Desc({name = " "}),
	X = Opt:InputNumber({name = "X Value", desc = "Choose the X Value for the Auras."}),
	Y = Opt:InputNumber({name = "Y Value", desc = "Choose the Y Value for the Auras."}),
	empty2 = Opt:Desc({name = " "}),
	Texture = Opt:MediaStatusbar({name = "Texture", desc = "Choose the Auras Texture."}),
	TextureBG = Opt:MediaStatusbar({name = "Background Texture", desc = "Choose the Auras Background Texture."}),
	BarGap = Opt:Slider({name = "Spacing", desc = "Select the Spacing between mirror bars when shown.", min = 0, max = 40, step = 1}),
	ArchyBar = Opt:Toggle({name = "Archaeology Progress Bar", desc = "Integrate the Archaeology Progress bar", width = "full"}),
}

local ColorTab = {
	FatigueBar = Opt:Color({name = "Fatigue Bar", desc = "Fatigue Bar"}),
	BreathBar = Opt:Color({name = "Breath Bar", desc = "Breath Bar"}),
	FeignBar = Opt:Color({name = "Feign Death Bar", desc = "Feign Death Bar"}),
	Bar = Opt:Color({name = "Other Bar", desc = "Other Aurass"}),
	ArchyBar = Opt:Color({name = "Archaeology Progress Bar", desc = "Archaeology Progress Bar"}),
	Background = Opt:Color({name = "Background", desc = "Auras Background"}),
}

local NameText = {
	Font = Opt:MediaFont({name = "Font", desc = "Choose the Font for the Mirror Name Text."}),
	Color = Opt:Color({name = "Name", desc = "Mirror Name", hasAlpha = false, Opt.ColorGetSet(db.Text.Name)}),
	Size = Opt:Slider({name = "Size", desc = "Choose the Font Size for the Mirror Name Text.", min = 6, max = 40, step = 1}),
	empty2 = Opt:Desc({name = " "}),
	OffsetX = Opt:InputNumber({name = "X Value", desc = "Choose the X Value for the Mirror Name Text."}),
	OffsetY = Opt:InputNumber({name = "Y Value", desc = "Choose the Y Value for the Mirror Name Text."}),
}

Opt.options.args.Auras.args = Auras

--- Link the groups together.
Auras.General.args = GeneralTab
Auras.Colors.args = ColorTab
Auras.NameText.args = NameText

-- ####################################################################################################################
-- ##### Old Options ###############################################################################################
-- ####################################################################################################################
--[[ 
	
function module:LoadOptions()
	local function refresh(info)
		headers[info[2] ]:Configure()
	end

	local function CreateTextOptions(auraType, kind, order)
		local options = self:NewGroup(kind, order, true, {
			Font = self:NewSelect(L["Font"], L["Choose a font"], 1, true, "LSM30_Font", refresh),
			Flag = self:NewSelect(L["Flag"], L["Choose a font flag"], 2, LUI.FontFlags, false, refresh),
			Size = self:NewSlider(L["Size"], L["Choose a fontsize"], 3, 1, 40, 1, true),
			Color = self:NewColorNoAlpha(format("%s %s", auraType, kind), nil, 4, refresh),
		})

		return options
	end

	local function CreateAuraOptions(auraType, order)
		local options = self:NewGroup(auraType, order, false, _G.InCombatLockdown, {
			header = self:NewHeader(format(L["%s Options"], auraType), 1),
			Size = self:NewSlider(L["Size"], format(L["Choose the Size for your %s"], auraType), 2, 15, 65, 1, true),
			Anchor = self:NewSelect(L["Anchor"], format(L["Choose the corner to anchor your %s to"], auraType), 3, LUI.Corners, false, refresh),
			X = self:NewInputNumber(L["Horizontal Position"], format(L["Adjust the horizontal position"], auraType), 4, refresh),
			Y = self:NewInputNumber(L["Vertical Position"], format(L["Adjust the vertical position"], auraType), 5, refresh),
			NumRows = self:NewSlider(L["Number of rows"], format(L["Choose the maximum number of rows for your %s"], auraType), 6, 1, 10, 1, true),
			AurasPerRow = self:NewSlider(L["Number per row"], format(L["Choose the maximum number of %s for each row"], auraType), 7, 1, 40, 1, true),
			HorizontalSpacing = self:NewInputNumber(L["Spacing"], format(L["Choose the amount of space between each of your %s"], auraType), 8, refresh),
			VerticalSpacing = self:NewInputNumber(L["Row Spacing"], format(L["Choose the amount of space between each row of your %s"], auraType), 9, refresh),
			Consolidate = auraType == L["Buffs"] and self:NewToggle(format(L["Consolidate %s"], auraType), format(L["Choose whether you want to consolidate your %s or not"], auraType), 10, true) or nil,
			SortMethod = self:NewSelect(L["Sorting Order"], format(L["Choose the sorting order for your %s"], auraType), 11, sortOrders, false, refresh),
			ReverseSort = self:NewToggle(L["Reverse Sorting"], L["Choose whether you want to reverse the sorting order or not"], 12, true, "normal"),
			Count = CreateTextOptions(auraType, L["Count"], 13),
			Duration = CreateTextOptions(auraType, L["Duration"], 14),
		})

		return options
	end

	local options = {
		Buffs = CreateAuraOptions(L["Buffs"], 1),
		Debuffs = CreateAuraOptions(L["Debuffs"], 2),
	}

	return options
end

]]
