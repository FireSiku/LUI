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

local PRESET_BAR_ANCHORS = {
	BT4Bar1 = "BT4 Bar1 (Bar 1)",
	BT4Bar2 = "BT4 Bar2 (Bonus Action Bar)",
	BT4Bar3 = "BT4 Bar3 (Bar 4)",
	BT4Bar4 = "BT4 Bar4 (Bar 5)",
	BT4Bar5 = "BT4 Bar5 (Bar 3)",
	BT4Bar6 = "BT4 Bar6 (Bar 2)",
	BT4Bar7 = "BT4 Bar7 (Class Bar 1)",
	BT4Bar8 = "BT4 Bar8 (Class Bar 2)",
	BT4Bar9 = "BT4 Bar9 (Class Bar 3)",
	BT4Bar10 = "BT4 Bar10 (Class Bar 4)",
	BT4Bar13 = "BT4 Bar13 (Bar 6)",
	BT4Bar14 = "BT4 Bar14 (Bar 7)",
	BT4Bar15 = "BT4 Bar15 (Bar 8)",
	["Dominos Bar1"] = "Dominos Bar 1",
	["Dominos Bar2"] = "Dominos Bar 2",
	["Dominos Bar3"] = "Dominos Bar 3",
	["Dominos Bar4"] = "Dominos Bar 4",
	["Dominos Bar5"] = "Dominos Bar 5",
	["Dominos Bar6"] = "Dominos Bar 6",
	["Dominos Bar7"] = "Dominos Bar 7",
	["Dominos Bar8"] = "Dominos Bar 8",
	["Dominos Bar9"] = "Dominos Bar 9",
	["Dominos Bar10"] = "Dominos Bar10",
}

local PRESET_RAID_ANCHORS = {
	Plexus = "PlexusLayoutFrame",
	Grid2 = "Grid2LayoutFrame",
	Healbot = "f1_HealBot_Action",
	Vuhdo = "Vd1",
	oUF = "oUF_LUI_raid",
	Blizzard = "CompactRaidFrameContainer",
}
local PRESET_METER_ANCHORS = {
	Recount = "Recount_MainWindow",
	Omen = "OmenAnchor",
	Skada = "SkadaBarWindowSkada",
	Details = "DetailsBaseFrame1",
	Details_2nd = "DetailsBaseFrame2",
}

local nameInput

local Artwork = Opt:CreateModuleOptions("Artwork", module)
local CustomArgs, SidebarArgs = {}, {}

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

local function CreatePanelGroup(name, isNative)
	local texDB = isNative and db.LUITextures[name] or db.Textures[name]
	local function textureGet(info)
		return texDB.Texture
	end
	local function textureSet(info, value)
		texDB.Texture = value
		module:Refresh()
	end

	local group = Opt:Group({name = name, db = texDB, args = {
		Enabled = Opt:Toggle({name = "Enabled"}),
		TextureHeader = Opt:Header({name = L["Texture"]}),
		--ImageDesc = Opt:Desc({name = "", 2, nil, GetOptionImageTexture, desc = GetOptionTexCoords, 128}),
		TexMode = Opt:Select({name = L["Panels_Options_Category"], values = TEX_MODE_SELECT, disabled = isNative}),
		Texture = Opt:Input({name = L["Texture"], desc = L["Panels_Options_Texture_Desc"], hidden = IsTextureInputHidden, onlyIf = (not isNative)}),
		TextureSelect = Opt:Select({name = L["Panels_Options_TextureSelect"], desc = L["Panels_Options_TextureSelect_Desc"],
			values = PRESET_LUI_TEXTURES, hidden = IsTextureSelectHidden, get = textureGet, set = textureSet, disabled = isNative}),
		LineBreakTex = Opt:Spacer({}),
		Anchored = Opt:Toggle({name = L["Panels_Options_Anchored"], desc = L["Panels_Options_Anchored_Desc"], width = "normal"}),
		Parent = Opt:Input({name = L["Parent"], desc = L["Panels_Options_Parent_Desc"], disabled = IsAnchorParentDisabled}),
		-- ColorType = Opt:Select({name = "Panel Color", values = LUI.ColorTypes,
		-- 	get = function(info) return db.Colors[name].t end, --getter
		-- 	set = function(info, value) db.Colors[name].t = value; module:Refresh() end}), --setter
		ColorType = Opt:ColorSelect({name = "Panel Color", arg = name}),
		[(name)] = Opt:Color({name = "Individual Color", hasAlpha = true}),
		LineBreakFlip = Opt:Spacer({}),
		HorizontalFlip = Opt:Toggle({name = L["Panels_Options_HorizontalFlip"], desc = L["Panels_Options_HorizontalFlip_Desc"]}),
		VerticalFlip = Opt:Toggle({name = L["Panels_Options_VerticalFlip"], desc = L["Panels_Options_VerticalFlip_Desc"]}),
		CustomTexCoords = Opt:Toggle({onlyIf = (not isNative), name = L["Panels_Options_CustomTexCoords"], desc = L["Panels_Options_CustomTexCoords_Desc"], hidden = IsCustomTexCoordsHidden}),
		LineBreakCoord = Opt:Spacer({}),
		Left = Opt:Input({name = L["Point_Left"], width = "half", hidden = IsTexCoordsHidden}),
		Right = Opt:Input({name = L["Point_Right"], width = "half", hidden = IsTexCoordsHidden}),
		Up = Opt:Input({name = L["Point_Up"], width = "half", hidden = IsTexCoordsHidden}),
		Down = Opt:Input({name = L["Point_Down"], width = "half", hidden = IsTexCoordsHidden}),
		SettingsHeader = Opt:Header({name = L["Settings"]}),
		Width = Opt:InputNumber({name = L["Width"]}),
		Height = Opt:InputNumber({name = L["Height"]}),
		X = Opt:InputNumber({name = "X"}),
		Y = Opt:InputNumber({name = "Y"}),
		LineBreak = Opt:Spacer({}),
		--[(name)] = Opt:ColorMenu(L["Color"], 34, true, RefreshPanel),
		PosHeader = Opt:Header({name = L["Position"]}),
		Point = Opt:Select({name = L["Anchor"], values = LUI.Points}),
		RelativePoint = Opt:Select({name = L["Anchor"], values = LUI.Points}),
		LineBreak5 = Opt:Spacer({width = "full"}),
		DeletePanel = Opt:Execute({name = "Delete Panel", func = DeleteNewPanel, onlyIf = (not isNative)})
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

--- Create the options for the Sidebar.
---@param name string
---@param bar SidebarMixin
---@param barDB SidebarDBOptions
---@return LUIOption
local function CreateSidebarOptions(name, bar, barDB)
	local function IsSideBarDisabled() return not barDB.Enable end
	
	local function presetDropdownGet(info)
		return barDB.Anchor
	end

	local function presetDropdownSet(info, value)
		if barDB.Anchor == value then return end
		barDB.AutoPosition = false
		barDB.Anchor = value
	end

	local function autoAdjustFunc()
		bar:AutoAdjust()
	end

	local dbName = "Sidebar"..string.gsub(name, " Sidebar", "")
	local barColorDB = module.db.profile.Colors[dbName]

	return Opt:Group({name = name, db = barDB, arg = bar, args = {
		Header = Opt:Header({name = name}),
		Enable = Opt:Toggle({name = "Enabled"}),
		OpenInstant = Opt:Toggle({name = "Open Instantly", desc = "If enabled, there will be no delay or animation when opening or closing the sidebar.\n\nNote: During combat, the sidebar always open instantly.", disabled = IsSideBarDisabled}),
		Spacer = Opt:Spacer({}),
		Scale = Opt:Slider({name = "Scale", desc = format("The scale of the sidebar. For best results, this should match the Pixel-To-UI factor.\n\nFor your resolution: %.f%%", PixelUtil.GetPixelToUIUnitFactor()*100), values = Opt.ScaleValues, disabled = IsSideBarDisabled}),
		Y = Opt:InputNumber({name = "Y Offset", desc = "Vertical position of the sidebar.", disabled = IsSideBarDisabled}),
		SpacerAnchor = Opt:Spacer({}),
		Intro = Opt:Desc({name = "\nWhich Bar do you want to use for this Sidebar?\nChoose one or type in the frame to be anchored manually.\n\nMake sure your Bar is set to 6 buttons/2 columns and isn't used for another Sidebar.", disabled = IsSideBarDisabled}),
		AnchorPreset = Opt:Select({name = "Bar Preset", values = PRESET_BAR_ANCHORS, get = presetDropdownGet, set = presetDropdownSet, disabled = IsSideBarDisabled}),
		Anchor = Opt:Input({name = "Anchor", desc = "Frame that will be anchored to the sidebar", disabled = IsSideBarDisabled}),
		SpacerAdjust = Opt:Spacer({}),
		AutoAdjust = Opt:Execute({name = "Auto-Adjust Position", desc = "If you recently changed the bar anchor, make sure to move the previous bar outside of the Sidebar to prevent overlaps.", func = autoAdjustFunc, disabled = IsSideBarDisabled}),
		AutoPosition = Opt:Toggle({name = "Auto-Position", desc = "If enabled, LUI will automatically position the sidebar anchor. This option automatically turns off if you change the anchor to avoid errors.", disabled = IsSideBarDisabled}),
		SpacerColor = Opt:Spacer({}),
		ColorType = Opt:ColorSelect({name = "Sidebar Texture Color", arg = dbName}),
		[(dbName)] = Opt:Color({name = "Individual Color", hasAlpha = true}),
		---@TODO: Point will only be there for additional sidebars.
		--Point = Opt:Select({name = "Anchor Point that the sidebar will be tied to.", values = LUI.Points}),
	}})
end

local function CreateMainPanelOptions(kind)
	local isNotChat = kind ~= "Chat"
	local function presetDropdownGet(info)
		return db.LUITextures[kind].Anchor
	end

	local function presetDropdownSet(info, value)
		db.LUITextures[kind].Anchor = value
		if value == "DetailsBaseFrame1" then
			db.LUITextures[kind].Additional = "DetailsRowFrame1"
		elseif value == "DetailsBaseFrame2" then
			db.LUITextures[kind].Additional = "DetailsRowFrame2"
		else
			db.LUITextures[kind].Additional = ""
		end
	end

	return Opt:Group({name = kind, db = db.LUITextures[kind], args = {
		Header = Opt:Header({name = kind}),
		addon = Opt:Desc({onlyIf = isNotChat, name = "Which "..kind.." Addon do you prefer?\nChoose one or type in the Anchor manually.\n"}),
		AnchorPreset = Opt:Select({onlyIf = isNotChat, name = "Bar Preset", values = (kind == "Raid") and PRESET_RAID_ANCHORS or PRESET_METER_ANCHORS, get = presetDropdownGet, set = presetDropdownSet}),
		Anchor = Opt:Input({onlyIf = isNotChat, name = "Anchor", desc = "Type in your "..kind.." Anchor manually."}),
		FrameIdentifierDesc = Opt:Desc({onlyIf = isNotChat, name = "Use the LUI Frame Identifier to search for the Parent Frame of your "..kind.." Addon.\nYou can also use the Blizzard Debug Tool: Type /framestack"}),
		FrameIdentifier = Opt:Execute({onlyIf = isNotChat, name = "LUI Frame Identifier", desc = "Click to show the LUI Frame Identifier", func = function() _G.LUI_Frame_Identifier:Show() end }),
		Additional = Opt:Input({onlyIf = isNotChat, name = "Additional Frames", desc = "Type in any additional Frames (seperated by commas), that you would like to show/hide."}),
		Spacer1 = Opt:Spacer({}),
		OffsetX = Opt:InputNumber({name = "Offset X", desc = "Choose the X Offset for your "..kind.." Frame to it's Anchor."}),
		OffsetY = Opt:InputNumber({name = "Offset Y", desc = "Choose the Y Offset for your "..kind.." Frame to it's Anchor."}),
		Spacer2 = Opt:Spacer({}),
		Direction = Opt:Select({name = "Direction", values = LUI.Directions}),
		Animation = Opt:Toggle({name = "Fade Animation", desc = "Enable a fade animation when showing or hiding the panel. Protected frames such as raid frames do not support this setting.", disabled = (kind == "raid")}),
		Spacer3 = Opt:Spacer({}),
		Width = Opt:InputNumber({name = "Width", desc = "Choose the Width for your "..kind.." Panel."}),
		Height = Opt:InputNumber({name = "Height", desc = "Choose the Height for your "..kind.." Panel."}),
		Spacer4 = Opt:Spacer({}),
		BGColorType = Opt:ColorSelect({name = "BG Color", desc = "Choose the Color for your "..kind.." Panel Background.", arg = kind}),
		[(kind)] = Opt:Color({name = "Individual Color", hasAlpha = true}),
		Spacer5 = Opt:Spacer({}),
		BorderColorType = Opt:ColorSelect({name = "Border Color", desc = "Choose the Color for your "..kind.." Panel Border.", arg = kind.."Border"}),
		[(kind.."Border")] = Opt:Color({name = "Individual Color", hasAlpha = true}),
	}})
end

-- ####################################################################################################################
-- ##### Options Table ################################################################################################
-- ####################################################################################################################

local BuiltinArgs = {
	NavBar = Opt:Group({name = "Navigation", db = db.LUITextures.NavBar, args = {
		OrbHeader = Opt:Header({name = "Orb"}),
		ShowOrb = Opt:Toggle({name = "Show Orb", desc = "When enabled the the central galaxy orb is shown.", width = "full"}),
		LostGalaxy = Opt:Toggle({name = "Show Lost Galaxy", desc = "When enabled, the orb has an extra texture to make it look brighter.", width = "full"}),
		NavHeader = Opt:Header({name = "NavBar"}),
		ShowButtons = Opt:Toggle({name = "Show Buttons", desc = "When enabled the central button functionality can be used to show or hide the chat, TPS, DPS and raid window.", width = "full"}),
		TopBackground = Opt:Toggle({name = "Show Buttons Background", desc = "When enabled the central black button background is shown.", width = "full"}),
		CenterBackground = Opt:Toggle({name = "Show Themed Center Background", desc = "When enabled the themed central background is shown.", width = "full"}),
		--Background = Opt:Toggle({name = "Show Themed Background", desc = "When enabled the top left and right-hand side themed background is shown.", width = "full"}),
		LineHeader = Opt:Header({name = "Bottom Lines"}),
		BlackLines = Opt:Toggle({name = "Show Black Lines", desc = "Enable the bottom left and right black line.", width = "full"}),
		ThemedLines = Opt:Toggle({name = "Show Themed Lines", desc = "Enable the bottom left and right themed line.", width = "full"}),
	}}),
	Chat = CreateMainPanelOptions("Chat"),
	Tps = CreateMainPanelOptions("Tps"),
	Dps = CreateMainPanelOptions("Dps"),
	Raid = CreateMainPanelOptions("Raid"),
	ActionBarTopTexture = CreatePanelGroup("ActionBarTopTexture", true),
}

CustomArgs = {
	NewDesc = Opt:Desc({name = "    Add Custom Panels:", fontSize = "medium", width = "normal"}),
	NameInput = Opt:Input({name = "Panel Name", get = function() return nameInput or "" end, set = function(_, value) nameInput = value end}),
	NewPanel = Opt:Execute({name = "Create Panel", func = CreateNewPanel, disabled = IsNewPanelDisabled}),
}

for name, sidebar in module:IterateSidebars() do
	BuiltinArgs[name] = CreateSidebarOptions(name.." Sidebar", sidebar, db.SideBars[name])
end

Artwork.args = {
	Header = Opt:Header({name = "Artwork"}),
	Builtin = Opt:Group({name = "LUI Panels", childGroups = "tab", args = BuiltinArgs}),
	Custom = Opt:Group({name = "Custom Panels", childGroups = "tab", args = CustomArgs}),
}

for i = 1, #module.panelList do
	local name = module.panelList[i]
	CustomArgs[name] = CreatePanelGroup(name)
end
