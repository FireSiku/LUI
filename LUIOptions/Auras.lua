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
    Header = Opt:Header(L["Auras"], 1),
	General = Opt:Group("General Settings", nil, 2, nil, nil, nil, Opt.GetSet(db.General)),
	NameText = Opt:Group("Name Text Settings", nil, 5, nil, nil, nil, Opt.GetSet(db.Text.Name)),
	Colors = Opt:Group("Bar Colors", nil, 4, nil, nil, nil, Opt.GetSet(db.Colors)),
}

local GeneralTab = {
	Width = Opt:InputNumber("Width", "Choose the Width for the Auras.", 1),
	Height = Opt:InputNumber("Height", "Choose the Height for the Auras.", 2),
	empty1 = Opt:Desc(" ", 3),
	X = Opt:InputNumber("X Value", "Choose the X Value for the Auras.", 4),
	Y = Opt:InputNumber("Y Value", "Choose the Y Value for the Auras.", 5),
	empty2 = Opt:Desc(" ", 6),
	Texture = Opt:MediaStatusbar("Texture", "Choose the Auras Texture.", 7),
	TextureBG = Opt:MediaStatusbar("Background Texture", "Choose the Auras Background Texture.", 8),
	BarGap = Opt:Slider("Spacing", "Select the Spacing between mirror bars when shown.", 9, {min = 0, max = 40, step = 1}),
	ArchyBar = Opt:Toggle("Archaeology Progress Bar", "Integrate the Archaeology Progress bar", 10, nil, "full"),
}

local ColorTab = {
	FatigueBar = Opt:Color("Fatigue Bar", "Fatigue Bar", 1),
	BreathBar = Opt:Color("Breath Bar", "Breath Bar", 2),
	FeignBar = Opt:Color("Feign Death Bar", "Feign Death Bar", 3),
	Bar = Opt:Color("Other Bar", "Other Aurass", 4),
	ArchyBar = Opt:Color("Archaeology Progress Bar", "Archaeology Progress Bar", 5),
	Background = Opt:Color("Background", "Auras Background", 6),
}

local NameText = {
	Font = Opt:MediaFont("Font", "Choose the Font for the Mirror Name Text.", 2),
	Color = Opt:Color("Name", "Mirror Name", 4, false, nil, nil, nil, Opt.ColorGetSet(db.Text.Name)),
	Size = Opt:Slider("Size", "Choose the Font Size for the Mirror Name Text.", 3, {min = 6, max = 40, step = 1}),
	empty2 = Opt:Desc(" ", 5),
	OffsetX = Opt:InputNumber("X Value", "Choose the X Value for the Mirror Name Text.", 6),
	OffsetY = Opt:InputNumber("Y Value", "Choose the Y Value for the Mirror Name Text.", 7),
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