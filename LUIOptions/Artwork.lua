-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################
---@class Opt
local Opt = select(2, ...)

---@type AceLocale.Localizations, LUI.Artwork, AceDB-3.0
local L, module, db = Opt:GetLUIModule("Artwork")

local PRESET_BAR_ANCHORS = {
	MainMenuBar = "Blizzard Action Bar 1 (Main)",
	MultiBarBottomLeft = "Blizzard Action Bar 2 (Bottom Left)",
	MultiBarBottomRight = "Blizzard Action Bar 3 (Bottom Right)",
	MultiBarRight = "Blizzard Action Bar 4 (Right)",
	MultiBarLeft = "Blizzard Action Bar 5 (Left)",
	MultiBar5 = "Blizzard Action Bar 6",
	MultiBar6 = "Blizzard Action Bar 7",
	MultiBar7 = "Blizzard Action Bar 8",
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
	DominosFrame1 = "Dominos Bar 1",
	DominosFrame2 = "Dominos Bar 2",
	DominosFrame3 = "Dominos Bar 3",
	DominosFrame4 = "Dominos Bar 4",
	DominosFrame5 = "Dominos Bar 5",
	DominosFrame6 = "Dominos Bar 6",
	DominosFrame7 = "Dominos Bar 7",
	DominosFrame8 = "Dominos Bar 8",
	DominosFrame9 = "Dominos Bar 9",
	DominosFrame10 = "Dominos Bar 10",
}

local PRESET_RAID_ANCHORS = {
	PlexusLayoutFrame = "Plexus",
	Grid2LayoutFrame = "Grid2",
	f1_HealBot_Action = "Healbot",
	Vd1 = "Vuhdo",
	oUF_LUI_raid = "LUI oUF",
	CompactRaidFrameContainer = "Blizzard Raid Frames",
}
local PRESET_METER_ANCHORS = {
	DetailsBaseFrame1 = "Details - Window 1",
	DetailsBaseFrame2 = "Details - Window 2",
	DamageMeterSessionWindow1 = "Blizzard Damage Meter - Window 1",
	DamageMeterSessionWindow2 = "Blizzard Damage Meter - Window 2",
}

local PRESET_ADDITIONAL_FRAMES = {
	DetailsBaseFrame1 = "DetailsRowFrame1",
	DetailsBaseFrame2 = "DetailsRowFrame2",
}

local Artwork = Opt:CreateModuleOptions("Artwork", module)
local themes = LUI:GetModule("Themes")

-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################

local function CreatePanelGroup(name)
	local texDB = db.LUITextures[name]
	local function IsAnchorParentDisabled() return not texDB.Anchored end

	local group = Opt:Group({name = name, db = texDB, args = {
		Enabled = Opt:Toggle({name = "Enabled"}),
		Anchored = Opt:Toggle({name = L["Panels_Options_Anchored"], desc = L["Panels_Options_Anchored_Desc"], width = "normal"}),
		Parent = Opt:Input({name = L["Parent"], desc = L["Panels_Options_Parent_Desc"], disabled = IsAnchorParentDisabled}),
		ColorType = Opt:ColorSelect({name = "Panel Color", arg = name}),
		[(name)] = Opt:Color({name = "Individual Color", hasAlpha = true}),
		LineBreakFlip = Opt:Spacer({}),
		HorizontalFlip = Opt:Toggle({name = L["Panels_Options_HorizontalFlip"], desc = L["Panels_Options_HorizontalFlip_Desc"]}),
		VerticalFlip = Opt:Toggle({name = L["Panels_Options_VerticalFlip"], desc = L["Panels_Options_VerticalFlip_Desc"]}),
		SettingsHeader = Opt:Header({name = L["Settings"]}),
		Width = Opt:InputNumber({name = L["Width"]}),
		Height = Opt:InputNumber({name = L["Height"]}),
		X = Opt:PositionX(),
		Y = Opt:PositionY(),
		LineBreak = Opt:Spacer({}),
		PosHeader = Opt:Header({name = L["Position"]}),
		Point = Opt:Select({name = L["Anchor"], values = LUI.Points}),
		RelativePoint = Opt:Select({name = L["Anchor"], values = LUI.Points}),
	}})

	return group
end

local function GetActiveTheme()
	local active = themes.db.profile.theme
	for index, name in ipairs(themes.ThemeArray()) do
		if name == active then return index end
	end
end

local function SetActiveTheme(_, index)
	local name = themes.ThemeArray()[index]
	if not name or name == "" then return end
	themes.db.profile.theme = name
	themes:LoadTheme(name)
	themes:ApplyTheme()
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
		module:Refresh()
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
		X = Opt:PositionX({disabled = IsSideBarDisabled}),
		Y = Opt:PositionY({desc = "Move the sidebar down with negative values or up with positive values. You can also enter an exact number below the slider.", disabled = IsSideBarDisabled}),
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
	}})
end

local function CreateMainPanelOptions(kind, displayName)
	displayName = displayName or kind
	local isNotChat = kind ~= "Chat"
	local function presetDropdownGet(info)
		return db.LUITextures[kind].Anchor
	end

	local function presetDropdownSet(info, value)
		db.LUITextures[kind].Anchor = value
		db.LUITextures[kind].Additional = PRESET_ADDITIONAL_FRAMES[value] or ""
		module:Refresh()
	end

	return Opt:Group({name = displayName, db = db.LUITextures[kind], args = {
		Header = Opt:Header({name = displayName}),
		addon = Opt:Desc({onlyIf = isNotChat, name = "Choose a preset or enter the frame name to attach to this panel.\n"}),
		AnchorPreset = Opt:Select({onlyIf = isNotChat, name = "Bar Preset", values = (kind == "Raid") and PRESET_RAID_ANCHORS or PRESET_METER_ANCHORS, get = presetDropdownGet, set = presetDropdownSet}),
		Anchor = Opt:Input({onlyIf = isNotChat, name = "Anchor", desc = "Enter the anchor frame manually."}),
		FrameIdentifierDesc = Opt:Desc({onlyIf = isNotChat, name = "Use the LUI Frame Identifier to find a frame name. You can also use Blizzard's /framestack command."}),
		FrameIdentifier = Opt:Execute({onlyIf = isNotChat, name = "LUI Frame Identifier", desc = "Click to show the LUI Frame Identifier", func = function() _G.LUI_Frame_Identifier:Show() end }),
		Additional = Opt:Input({onlyIf = isNotChat, name = "Additional Frames", desc = "Type in any additional Frames (seperated by commas), that you would like to show/hide."}),
		Spacer1 = Opt:Spacer({}),
		AlwaysShow = Opt:Toggle({name = "Show at Login", desc = "Show this panel and its anchored frame when entering the world.", width = "full"}),
		OffsetX = Opt:OffsetX(),
		OffsetY = Opt:OffsetY(),
		Spacer2 = Opt:Spacer({}),
		Direction = Opt:Select({name = "Direction", values = LUI.Points}),
		Animation = Opt:Toggle({name = "Fade Animation", desc = "Enable a fade animation when showing or hiding the panel. Protected frames such as raid frames do not support this setting.", disabled = (kind == "Raid")}),
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
		ShowOrb = Opt:Toggle({name = "Show Orb", desc = "Show the central galaxy orb.", width = "full"}),
		LostGalaxy = Opt:Toggle({name = "Show Lost Galaxy", desc = "When enabled, the orb has an extra texture to make it look brighter.", width = "full"}),
		OrbColorType = Opt:ColorSelect({name = "Orb Color", arg = "Orb"}),
		Orb = Opt:Color({name = "Individual Color", hasAlpha = true}),
		NavHeader = Opt:Header({name = "NavBar"}),
		ShowButtons = Opt:Toggle({name = "Show Buttons", desc = "When enabled the central button functionality can be used to show or hide the chat, TPS, DPS and raid window.", width = "full"}),
		TopBackground = Opt:Toggle({name = "Show Buttons Background", desc = "When enabled the central black button background is shown.", width = "full"}),
		CenterBackground = Opt:Toggle({name = "Show Themed Center Background", desc = "When enabled the themed central background is shown.", width = "full"}),
		PanelColorType = Opt:ColorSelect({name = "Top Panel Color", arg = "TopPanel"}),
		TopPanel = Opt:Color({name = "Individual Color", hasAlpha = true}),
		Spacer = Opt:Spacer({}),
		NavColorType = Opt:ColorSelect({name = "Buttons Color", arg = "NavButtons"}),
		NavButtons = Opt:Color({name = "Individual Color", hasAlpha = true}),
		LineHeader = Opt:Header({name = "Bottom Lines"}),
		BlackLines = Opt:Toggle({name = "Show Black Lines", desc = "Enable the bottom left and right black line.", width = "full"}),
		ThemedLines = Opt:Toggle({name = "Show Themed Lines", desc = "Enable the bottom left and right themed line.", width = "full"}),
		LineColorType = Opt:ColorSelect({name = "Themed Lines Color", arg = "LeftBorderBack"}),
		LeftBorderBack = Opt:Color({name = "Individual Color", hasAlpha = true}),
	}}),
	Chat = CreateMainPanelOptions("Chat"),
	Tps = CreateMainPanelOptions("Tps", "Meter Panel 2"),
	Dps = CreateMainPanelOptions("Dps", "Meter Panel 1"),
	Raid = CreateMainPanelOptions("Raid"),
	ActionBarTopTexture = CreatePanelGroup("ActionBarTopTexture"),
}

for name, sidebar in module:IterateSidebars() do
	BuiltinArgs[name] = CreateSidebarOptions(name.." Sidebar", sidebar, db.SideBars[name])
end

Artwork.args = {
	Header = Opt:Header({name = "Artwork"}),
	Themes = Opt:Group({name = "Themes", args = {
		Active = Opt:Select({name = "Theme", desc = "Apply a built-in or saved color theme to the active artwork components.", values = themes.ThemeArray, get = GetActiveTheme, set = SetActiveTheme}),
		Save = Opt:Execute({name = "Save Current Theme", desc = "Save the current artwork colors as a reusable theme.", func = function() StaticPopup_Show("LUI_THEMES_SAVE") end}),
		Delete = Opt:Execute({name = "Delete Active Theme", func = function() StaticPopup_Show("LUI_THEMES_DELETE") end}),
		Import = Opt:Execute({name = "Import Theme", func = function() StaticPopup_Show("LUI_THEMES_IMPORT") end}),
		Export = Opt:Execute({name = "Export Theme", func = function() StaticPopup_Show("LUI_THEMES_EXPORT") end}),
		Reset = Opt:Execute({name = "Reset Themes", func = function() StaticPopup_Show("LUI_THEMES_RESET") end}),
	}}),
	Builtin = Opt:Group({name = "LUI Panels", childGroups = "tab", args = BuiltinArgs}),
}
