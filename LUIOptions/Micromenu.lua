-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class Opt
local Opt = select(2, ...)

---@type AceLocale.Localizations, LUI.Micromenu, AceDB-3.0
local L, module, db = Opt:GetLUIModule("Micromenu")
if not module or not module.registered then return end

local Micromenu = Opt:CreateModuleOptions("Micromenu", module)
Micromenu.disabled = function(info) return InCombatLockdown() or Opt.IsModDisabled(info) end

local raidMenuModule = LUI:GetModule("RaidMenu", true)
local raidMenuDB = raidMenuModule and raidMenuModule.db and raidMenuModule.db.profile

-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################

local dropDirections = {
    LEFT = L["Point_Left"],
    RIGHT = L["Point_Right"],
}

local function IsBackgroundColorDisabled()
	return db.ColorMatch
end

local raidMenuOverlapMethods = {
	AutoHide = L["AutoHide"],
	Offset = L["Offset"],
}

local function IsRaidMenuUsingAutoHide()
	return raidMenuDB and raidMenuDB.OverlapPrevention == "AutoHide"
end

local function AreRaidMenuSettingsDisabled()
	return not raidMenuDB or not raidMenuDB.Enable or InCombatLockdown()
end

local function IsRaidMenuBackgroundColorDisabled()
	return raidMenuDB.MatchMicromenuBackground
end

local function SetRaidMenuEnabled(_, value)
	raidMenuModule:SetRaidMenuEnabled(value)
end

-- ####################################################################################################################
-- ##### Options Tables ###############################################################################################
-- ####################################################################################################################

local colorMenuOptions = {}

Micromenu.args = {
    -- General
	Header = Opt:Header({name = L["Micro_Name"]}),
	AlwaysShow = Opt:Toggle({name = "Always Show at Login", desc = "Open the micromenu whenever you enter the world.", width = "full"}),
	Spacing = Opt:Slider({name = L["Spacing"], desc = L["MicroOptions_Spacing_Desc"], min = -10, max = 10, step = 1}),
	
    -- Buttons
    ButtonsHeader = Opt:Header({name = L["Hide Buttons"]}),
	HidePlayer = Opt:Toggle({name = L["MicroOptions_Player"]}),
	HideSpellbook = Opt:Toggle({name = L["MicroOptions_Spellbook"]}),
	HideTalents = Opt:Toggle({name = L["MicroOptions_Talents"]}),
	HideAchievements = Opt:Toggle({name = L["MicroOptions_Achievements"]}),
	HideQuests = Opt:Toggle({name = L["MicroOptions_Quests"]}),
	HideGuild = Opt:Toggle({name = L["MicroOptions_Guild"]}),
	HideHousing = Opt:Toggle({name = _G.HOUSING_MICRO_BUTTON or "Housing"}),
	HideLFG = Opt:Toggle({name = L["MicroOptions_LFG"]}),
	HideEJ = Opt:Toggle({name = L["MicroOptions_EJ"]}),
	HideCollections = Opt:Toggle({name = L["MicroOptions_Collections"]}),
	HideStore = Opt:Toggle({name = L["MicroOptions_Store"]}),
	HideBags = Opt:Toggle({name = L["MicroOptions_Bags"]}),
	HideSettings = Opt:Toggle({name = L["MicroOptions_Settings"]}),

    -- Position
    PositionHeader = Opt:Header({name = L["Position"]}),
    X = Opt:PositionX(),
    Y = Opt:PositionY(),
	Point = Opt:Select({name = L["Anchor"], values = LUI.Points}),
	Direction = Opt:Select({name = L["MicroOptions_Direction_Name"], desc = L["MicroOptions_Direction_Desc"], values = dropDirections}),

	-- Colors
	ColorHeader = Opt:Header({name = L["Colors"]}),
	ColorMatch = Opt:Toggle({name = "Match Background to Buttons", desc = "Use the button color for the micromenu background."}),
	ColorType = Opt:ColorMenu(colorMenuOptions, {name = L["Micro_Name"], arg = "Micromenu"}),
	BGColorType = Opt:ColorMenu(colorMenuOptions, {name = L["Background"], arg = "Background", disabled = IsBackgroundColorDisabled}),
}

Mixin(Micromenu.args, colorMenuOptions)

-- Keep the long micromenu page and the raid-menu page as separate scrollable
-- tabs. Mixing a large set of controls with a child group makes AceConfig give
-- the child tab the remaining height without scrolling the controls above it.
local micromenuSettings = Micromenu.args
Micromenu.args = {
	Settings = Opt:Group({name = L["Micro_Name"], args = micromenuSettings}),
}

if raidMenuModule and raidMenuDB then
	Micromenu.args.RaidMenu = Opt:Group({
		name = L["Raid Menu"],
		handler = raidMenuModule,
		db = raidMenuDB,
		args = {
			Header = Opt:Header({name = L["Raid Menu"]}),
			Enable = Opt:Toggle({
				name = "Enable Raid Menu",
				desc = "Show the raid tools attached to the left micromenu button.",
				get = function() return raidMenuDB.Enable end,
				set = SetRaidMenuEnabled,
				disabled = function() return InCombatLockdown() end,
				width = "full",
			}),
			Settings = Opt:InlineGroup({name = "Settings", disabled = AreRaidMenuSettingsDisabled, args = {
				Compact = Opt:Toggle({name = L["Compact Raid Menu"], desc = L["Use compact version of the Raid Menu"]}),
				Spacing = Opt:Slider({name = L["Spacing"], desc = "Spacing between raid-menu buttons.", min = 0, max = 10, step = 1, disabled = function() return not raidMenuDB.Compact end}),
				Scale = Opt:Slider({name = L["Scale"], desc = "Scale of the raid menu.", values = Opt.ScaleValues}),
				Spacer1 = Opt:Spacer(),
				OverlapPrevention = Opt:Select({
					name = L["Micromenu Overlap Prevention"],
					values = raidMenuOverlapMethods,
					desc = "Auto-Hide closes one menu when the other opens. Offset moves the raid menu while the micromenu is visible.",
				}),
				X_Offset = Opt:OffsetX({min = -200, max = 200, softMin = -200, softMax = 200, disabled = IsRaidMenuUsingAutoHide}),
				Offset = Opt:OffsetY({min = -200, max = 200, softMin = -200, softMax = 200, disabled = IsRaidMenuUsingAutoHide}),
				Spacer2 = Opt:Spacer(),
				Opacity = Opt:Slider({name = L["Opacity"], desc = "Opacity of the raid menu.", min = 20, max = 100, step = 10}),
				MatchMicromenuBackground = Opt:Toggle({name = "Match Micromenu Background", desc = "Use the micromenu background color for the raid menu.", width = "full"}),
				BackgroundColor = Opt:Color({name = "Background Color", desc = "Choose a separate raid-menu background color to improve icon contrast.", hasAlpha = false, db = raidMenuDB, disabled = IsRaidMenuBackgroundColorDisabled}),
				AutoHide = Opt:Toggle({name = L["Auto-Hide Raid Menu"], desc = "Hide the raid menu after using one of its actions.", width = "full"}),
				ShowToolTips = Opt:Toggle({name = L["Show Tooltips"], desc = "Show descriptions for the raid-menu tools.", width = "full"}),
			}}),
		},
	})
end
