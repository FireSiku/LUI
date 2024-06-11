-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################
---@class Opt
local Opt = select(2, ...)

---@type AceLocale.Localizations, LUI.Artwork, AceDB-3.0
local L, module, db = Opt:GetLUIModule("Artwork")
-- if not module or not module.registered then return end

local TEX_MODE_SELECT = {
	L["Panels_TexMode_LUI"],
	L["Panels_TexMode_CustomLUI"],
	L["Panels_TexMode_Custom"],
}

local PRESET_LUI_TEXTURES = {
	["left_border.tga"] = L["Panels_Tex_Border_Screen"],
	["left_border_back.tga"] = L["Panels_Tex_Border_ScreenBack"],
	["panel_solid.tga"] = L["Panels_Tex_Panel_Solid"] ,
	["panel_corner_fill.tga"] = L["Panels_Tex_Panel_Corner"],
	["panel_center_fill.tga"] = L["Panels_Tex_Panel_Center"],
	["panel_corner_border.tga"] = L["Panels_Tex_Border_Corner"],
	["panel_center_border.tga"] = L["Panels_Tex_Border_Center"],
	["bar_top.tga"] = L["Panels_Tex_Bar_Top"],
}

local nameInput

local Artwork = Opt:CreateModuleOptions("Artwork", module)
local CustomArgs, SidebarArgs

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
	CustomArgs[panelName] = nil
	Opt:RefreshOptionsPanel()
	module:ModPrint("Deleted panel:", panelName)
end

local function CreatePanelGroup(name)
	local texDB = db.Textures[name]
	local function textureGet(info)
		return texDB.Texture
	end
	local function textureSet(info, value)
		texDB.Texture = value
	end

	local group = Opt:Group({name = name, db = texDB, args = {
		Enabled = Opt:Toggle({name = "Enabled"}),
		TextureHeader = Opt:Header({name = L["Texture"]}),
		--ImageDesc = Opt:Desc({name = "", 2, nil, GetOptionImageTexture, desc = GetOptionTexCoords, 128}),
		TexMode = Opt:Select({name = L["Panels_Options_Category"], values = TEX_MODE_SELECT}),
		Texture = Opt:Input({name = L["Texture"], desc = L["Panels_Options_Texture_Desc"], hidden = IsTextureInputHidden}),
		TextureSelect = Opt:Select({name = L["Panels_Options_TextureSelect"], desc = L["Panels_Options_TextureSelect_Desc"],
			values = PRESET_LUI_TEXTURES, hidden = IsTextureSelectHidden, get = textureGet, set = textureSet}),
		LineBreakTex = Opt:Spacer(),
		Anchored = Opt:Toggle({name = L["Panels_Options_Anchored"], desc = L["Panels_Options_Anchored_Desc"], width = "normal"}),
		Parent = Opt:Input({name = L["Parent"], desc = L["Panels_Options_Parent_Desc"], disabled = IsAnchorParentDisabled}),
		LineBreakFlip = Opt:Spacer(),
		HorizontalFlip = Opt:Toggle({name = L["Panels_Options_HorizontalFlip"], desc = L["Panels_Options_HorizontalFlip_Desc"]}),
		VerticalFlip = Opt:Toggle({name = L["Panels_Options_VerticalFlip"], desc = L["Panels_Options_VerticalFlip_Desc"]}),
		CustomTexCoords = Opt:Toggle({name = L["Panels_Options_CustomTexCoords"], desc = L["Panels_Options_CustomTexCoords_Desc"], hidden = IsCustomTexCoordsHidden}),
		LineBreakCoord = Opt:Spacer(),
		Left = Opt:Input({name = L["Point_Left"], width = "half", hidden = IsTexCoordsHidden}),
		Right = Opt:Input({name = L["Point_Right"], width = "half", hidden = IsTexCoordsHidden}),
		Up = Opt:Input({name = L["Point_Up"], width = "half", hidden = IsTexCoordsHidden}),
		Down = Opt:Input({name = L["Point_Down"], width = "half", hidden = IsTexCoordsHidden}),
		SettingsHeader = Opt:Header({name = L["Settings"]}),
		Width = Opt:InputNumber({name = L["Width"]}),
		Height = Opt:InputNumber({name = L["Height"]}),
		X = Opt:InputNumber({name = "X"}),
		Y = Opt:InputNumber({name = "Y"}),
		LineBreak = Opt:Spacer(),
		--[(name)] = Opt:ColorMenu(L["Color"], 34, true, RefreshPanel),
		PosHeader = Opt:Header({name = L["Position"]}),
		Point = Opt:Select({name = L["Anchor"], values = LUI.Points}),
		RelativePoint = Opt:Select({name = L["Anchor"], values = LUI.Points}),
		LineBreak5 = Opt:Spacer({width = "full"}),
		DeletePanel = Opt:Execute({name = "Delete Panel", func = DeleteNewPanel})
	}})
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
	CustomArgs[nameInput] = CreatePanelGroup(nameInput)
	Opt:RefreshOptionsPanel()

	module:ModPrint("Created new panel:", nameInput)
end

function CreateSidebarOptions(name, barDB)
	return Opt:Group({name = name, db = barDB, args = {
		Header = Opt:Header({name = name}),
		Enable = Opt:Toggle({name = "Enabled"}),
		Scale = Opt:Slider({name = "Scale", desc = format("The scale of the sidebar. For best results, this should match the Pixel-To-UI factor.\n\nFor your resolution: %.f%%", PixelUtil.GetPixelToUIUnitFactor()*100), values = Opt.ScaleValues}),
		Spacer = Opt:Spacer(),
		Anchor = Opt:Input({name = "Anchor", desc = "Frame that will be anchored to the sidebar"}),
		---@TODO: Point will only be there for additional sidebars.
		--Point = Opt:Select({name = "Anchor Point that the sidebar will be tied to.", values = LUI.Points}),
	}})
end

-- ####################################################################################################################
-- ##### Options Table ################################################################################################
-- ####################################################################################################################

CustomArgs = {
	NewDesc = Opt:Desc({name = "    Add Custom Panels:", fontSize = "medium", width = "normal"}),
	NameInput = Opt:Input({name = "Panel Name", get = function() return nameInput or "" end, set = function(_, value) nameInput = value end}),
	NewPanel = Opt:Execute({name = "Create Panel", func = CreateNewPanel, disabled = IsNewPanelDisabled}),
}

SidebarArgs = {
	RightSidebar = CreateSidebarOptions("Right Sidebar", db.SideBars.Right),

}

Artwork.args = {
	Header = Opt:Header({name = "Artwork"}),
	Custom = Opt:Group({name = "Custom Panels", childGroups = "tree", args = CustomArgs}),
	Builtin = Opt:Group({name = "LUI Panels", childGroups = "tree", hidden = true}),
	SideBars = Opt:Group({name = "Side Bars", childGroups = "tab", args = SidebarArgs}),
}

for i = 1, #module.panelList do
	local name = module.panelList[i]
	CustomArgs[name] = CreatePanelGroup(name)
end
