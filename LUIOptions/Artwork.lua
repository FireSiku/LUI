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
	["info_text.tga"] = L["Panels_Tex_Info_Bar"],
	["bar_bottom.tga"] = L["Panels_Tex_Bottom_Bar"],
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
		--ImageDesc = Opt:Desc("", 2, nil, GetOptionImageTexture, GetOptionTexCoords, 256, 128),
		TexMode = Opt:Select(L["Panels_Options_Category"], nil, 3, TEX_MODE_SELECT),
		Texture = Opt:Input(L["Texture"], L["Panels_Options_Texture_Desc"], 4, nil, nil, nil, IsTextureInputHidden),
		TextureSelect = Opt:Select(L["Panels_Options_TextureSelect"], L["Panels_Options_TextureSelect_Desc"], 4, PRESET_LUI_TEXTURES, nil, nil, IsTextureSelectHidden,
			function(info) return texDB.Texture end, function(info, value) texDB.Texture = value end),
		LineBreakTex = Opt:Spacer(10),
		Anchored = Opt:Toggle(L["Panels_Options_Anchored"], L["Panels_Options_Anchored_Desc"], 11, nil, "normal"),
		Parent = Opt:Input(L["Parent"], L["Panels_Options_Parent_Desc"], 12, nil, nil, IsAnchorParentDisabled),
		LineBreakFlip = Opt:Spacer(13),
		HorizontalFlip = Opt:Toggle(L["Panels_Options_HorizontalFlip"], L["Panels_Options_HorizontalFlip_Desc"], 14),
		VerticalFlip = Opt:Toggle(L["Panels_Options_VerticalFlip"], L["Panels_Options_VerticalFlip_Desc"], 15),
		CustomTexCoords = Opt:Toggle(L["Panels_Options_CustomTexCoords"], L["Panels_Options_CustomTexCoords_Desc"], 16, nil, nil, nil, IsCustomTexCoordsHidden),
		LineBreakCoord = Opt:Spacer(17),
		Left = Opt:Input(L["Point_Left"], nil, 18, nil, "half", nil, IsTexCoordsHidden),
		Right = Opt:Input(L["Point_Right"], nil, 19, nil, "half", nil, IsTexCoordsHidden),
		Up = Opt:Input(L["Point_Up"], nil, 20, nil, "half", nil, IsTexCoordsHidden),
		Down = Opt:Input(L["Point_Down"], nil, 21, nil, "half", nil, IsTexCoordsHidden),
		SettingsHeader = Opt:Header(L["Settings"], 30),
		Width = Opt:InputNumber(L["Width"], nil, 31),
		Height = Opt:InputNumber(L["Height"], nil, 32),
		X = Opt:InputNumber("X", nil, 31),
		Y = Opt:InputNumber("Y", nil, 32),
		FrameLevel = Opt:Slider("Frame Level", nil, 33, {min = 0, max = 1000, step = 1}),
		Strata = Opt:Select("Frame Strata", nil, 34, LUI.Strata),
		LineBreak = Opt:Spacer(35),
		--[(name)] = Opt:ColorMenu(L["Color"], 34, true, RefreshPanel),
		PosHeader = Opt:Header(L["Position"], 40),
		Point = Opt:Select(L["Anchor"], nil, 41, LUI.Points),
		RelativePoint = Opt:Select(L["Anchor"], nil, 42, LUI.Points),
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
	Header = Opt:Header("Artwork", 1),
	Custom = Opt:Group("Custom Panels", nil, 2, "tree"),
	Buttons = Opt:Group("Buttons", nil, 3),
	Builtin = Opt:Group("LUI Panels", nil, 4, "tree", nil, true),
}

Artwork.Custom.args.NewDesc = Opt:Desc("    Add Custom Panels:", 1, "medium", nil, nil, nil, nil, "normal")
Artwork.Custom.args.NameInput = Opt:Input("Panel Name", nil, 2, nil, nil, nil, nil, nil, function() return nameInput or "" end, function(_, value) nameInput = value end)
Artwork.Custom.args.NewPanel = Opt:Execute("Create Panel", nil, 3, CreateNewPanel, nil, IsNewPanelDisabled)
for i = 1, #module.panelList do
	local name = module.panelList[i]
	Artwork.Custom.args[name] = CreatePanelGroup(name)
end

local buttonsList = {"place_holder"}

for i = 1, #buttonsList do
	local name = buttonsList[i]
	Artwork.Buttons.args[name] = CreatePanelGroup(name)
end


Opt.options.args.Artwork.args = Artwork
