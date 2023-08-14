-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, Opt
local optName, Opt = ...
local L, module, db = Opt:GetLUIModule("Artwork")
if not module or not module.registered then return end

local TEX_MODE_SELECT = {
	L["Panels_TexMode_LUI"],
	L["Panels_TexMode_CustomLUI"],
	L["Panels_TexMode_Custom"],
}

local PRESET_LUI_TEXTURES = {
	["left_border.tga"] = L["Panels_Tex_Border_Screen"],
	["left_border_back.tga"] = L["Panels_Tex_Border_ScreenBack"],
	["panel_solid.tga"] = L["Panels_Tex_Panel_Solid"] ,
	["panel_corner.tga"] = L["Panels_Tex_Panel_Corner"],
	["panel_center.tga"] = L["Panels_Tex_Panel_Center"],
	["panel_corner_border.tga"] = L["Panels_Tex_Border_Corner"],
	["panel_center_border.tga"] = L["Panels_Tex_Border_Center"],
	["bar_top.tga"] = L["Panels_Tex_Bar_Top"],
}

local nameInput

-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################

-- info[#info-1] inside an PanelOptionGroup returns the texture's name, setPanels[name] returns the frame
local function IsAnchorParentDisabled(info) return not db.Textures[info[#info-1]].Anchored end
local function IsTexCoordsHidden(info) return not db.Textures[info[#info-1]].CustomTexCoords end
local function IsTextureInputHidden(info) return db.Textures[info[#info-1]].TexMode == 1 end
local function IsTextureSelectHidden(info) return db.Textures[info[#info-1]].TexMode ~= 1 end
-- local function GetOptionTexCoords(info) return setPanels[info[#info-1]]:GetTexCoord() end
-- local function GetOptionImageTexture(info) return setPanels[info[#info-1]]:GetTexture() end
-- local function RefreshPanel(info) return setPanels[info[#info-1]]:Refresh() end

-- LUI preset textures have their tex coords provided.
local function IsCustomTexCoordsHidden(info)
	return PRESET_LUI_TEXTURES[db.Textures[info[#info-1]].Texture]
end

local function DeleteNewPanel(info)
	local panelName = info[#info-1]
	tDeleteItem(module.panelList, panelName)
	_G["LUIPanel_"..panelName]:Hide()

	db.Textures[panelName] = nil
	db.Colors[panelName] = nil
	-- Get the parent node and remove panel options.
	Opt.options.args.Artwork.args.Custom.args[panelName] = nil
	Opt:RefreshOptionsPanel()
	module:ModPrint("Deleted panel:", panelName)
end

local function CreatePanelGroup(name)
	local texDB = db.Textures[name]
	local group = Opt:Group(name, nil, 10, nil, nil, nil, Opt.GetSet(texDB))
	group.args = {
		TextureHeader = Opt:Header(L["Texture"], 1),
		--ImageDesc = Opt:Desc({name = "", 2, nil, GetOptionImageTexture, desc = GetOptionTexCoords, 128}),
		TexMode = Opt:Select({name = L["Panels_Options_Category"], TEX_MODE_SELECT}),
		Texture = Opt:Input({name = L["Texture"], desc = L["Panels_Options_Texture_Desc"], nil, nil, nil, IsTextureInputHidden}),
		TextureSelect = Opt:Select(L["Panels_Options_TextureSelect"], L["Panels_Options_TextureSelect_Desc"], 4, PRESET_LUI_TEXTURES, nil, nil, IsTextureSelectHidden,
			function(info) return texDB.Texture end, function(info, value) texDB.Texture = value end),
		LineBreakTex = Opt:Spacer(10),
		Anchored = Opt:Toggle({name = L["Panels_Options_Anchored"], desc = L["Panels_Options_Anchored_Desc"], nil, "normal"}),
		Parent = Opt:Input({name = L["Parent"], desc = L["Panels_Options_Parent_Desc"], nil, nil, IsAnchorParentDisabled}),
		LineBreakFlip = Opt:Spacer(13),
		HorizontalFlip = Opt:Toggle({name = L["Panels_Options_HorizontalFlip"], desc = L["Panels_Options_HorizontalFlip_Desc"]}),
		VerticalFlip = Opt:Toggle({name = L["Panels_Options_VerticalFlip"], desc = L["Panels_Options_VerticalFlip_Desc"]}),
		CustomTexCoords = Opt:Toggle({name = L["Panels_Options_CustomTexCoords"], desc = L["Panels_Options_CustomTexCoords_Desc"], nil, nil, nil, IsCustomTexCoordsHidden}),
		LineBreakCoord = Opt:Spacer(17),
		Left = Opt:Input({name = L["Point_Left"], nil, "half", nil, IsTexCoordsHidden}),
		Right = Opt:Input({name = L["Point_Right"], nil, "half", nil, IsTexCoordsHidden}),
		Up = Opt:Input({name = L["Point_Up"], nil, "half", nil, IsTexCoordsHidden}),
		Down = Opt:Input({name = L["Point_Down"], nil, "half", nil, IsTexCoordsHidden}),
		SettingsHeader = Opt:Header(L["Settings"], 30),
		Width = Opt:InputNumber({name = L["Width"], desc = nil}),
		Height = Opt:InputNumber({name = L["Height"], desc = nil}),
		X = Opt:InputNumber({name = "X", desc = nil}),
		Y = Opt:InputNumber({name = "Y", desc = nil}),
		LineBreak = Opt:Spacer(33),
		--[(name)] = Opt:ColorMenu(L["Color"], 34, true, RefreshPanel),
		PosHeader = Opt:Header(L["Position"], 40),
		Point = Opt:Select({name = L["Anchor"], LUI.Points}),
		RelativePoint = Opt:Select({name = L["Anchor"], LUI.Points}),
		LineBreak5 = Opt:Spacer(50, "full"),
		DeletePanel = Opt:Execute("Delete Panel", nil, 52, DeleteNewPanel)
	}
	return group
end

local function IsNewPanelDisabled(info)
	if not nameInput or nameInput:trim() == "" then return true end
	if tContains(module.panelList, nameInput) then return true end
end

local function CreateNewPanel(info)
	local panelDB = db.Textures[nameInput]
	--Set the order so that, in theory, order values do not overlap.
	panelDB.Order = #module.panelList+1
	table.insert(module.panelList, nameInput)

	-- Create and show the new panel
	module:CreateNewPanel(nameInput, panelDB)

	-- Update options
	Opt.options.args.Artwork.args.Custom.args[nameInput] = CreatePanelGroup(nameInput)
	Opt:RefreshOptionsPanel()

	module:ModPrint("Created new panel:", nameInput)
end

-- ####################################################################################################################
-- ##### Options Table ################################################################################################
-- ####################################################################################################################

Opt.options.args.Artwork = Opt:Group("Artwork", nil, nil, "tab", nil, nil, Opt.GetSet(db))
Opt.options.args.Artwork.handler = module
local Artwork = {
	Header = Opt:Header({name = "Artwork"}),
	Custom = Opt:Group({name = "Custom Panels", childGroups = "tree", args = {
		NewDesc = Opt:Desc({name = "    Add Custom Panels:", fontSize = "medium", width = "normal"}),
		NameInput = Opt:Input({name = "Panel Name", get = function() return nameInput or "" end, set = function(_, value) nameInput = value end}),
		NewPanel = Opt:Execute({name = "Create Panel", func = CreateNewPanel, disabled = IsNewPanelDisabled}),
	}}),
	Builtin = Opt:Group({name = "LUI Panels", childGroups = "tree", hidden = true}),
}

for i = 1, #module.panelList do
	local name = module.panelList[i]
	Artwork.Custom.args[name] = CreatePanelGroup(name)
end

Opt.options.args.Artwork.args = Artwork
