---@class Opt
local Opt = select(2, ...)

---@type AceLocale.Localizations, LUI.UIElements, AceDB-3.0
local L, module, db = Opt:GetLUIModule("UI Elements")
if not module or not module.registered then return end

local UIElements = Opt:CreateModuleOptions("UI Elements", module)

local managedFrameOptions = {
	ZoneObjectives = {
		name = "Zone Objectives Frame",
		desc = "Top-center zone objectives, battleground information and similar widgets.",
	},
	CaptureBar = {
		name = "Capture Bar / Below-Minimap Widgets",
		desc = "Capture progress and other widgets normally shown below the minimap.",
	},
	GroupLoot = {
		name = "Group Loot Container",
		desc = "Anchor used by group-loot rolls and related loot frames.",
	},
	TicketStatus = {
		name = "GM Ticket Status",
		desc = "Status frame displayed while a support ticket is active.",
	},
}

local function GenerateManagedFrameGroup(key, info)
	local frameDB = db[key]
	local function IsPositionUnmanaged() return not frameDB.ManagePosition end
	return Opt:InlineGroup({name = info.name, db = frameDB, args = {
		Description = Opt:Desc({name = info.desc}),
		ManagePosition = Opt:Toggle({name = "Manage This Frame's Position", width = "full"}),
		X = Opt:PositionX({disabled = IsPositionUnmanaged}),
		Y = Opt:PositionY({disabled = IsPositionUnmanaged}),
		Preview = Opt:Execute({
			name = "Toggle Position Preview",
			func = function() module:TogglePreview(key, info.name) end,
		}),
	}})
end

local function OpenBlizzardEditMode()
	if InCombatLockdown() then return end
	if not C_AddOns.IsAddOnLoaded("Blizzard_EditMode") then
		C_AddOns.LoadAddOn("Blizzard_EditMode")
	end
	if _G.EditModeManagerFrame then
		LibStub("AceConfigDialog-3.0"):Close("LUIOptions")
		ShowUIPanel(_G.EditModeManagerFrame)
	end
end

local function IsButtonCustomizationDisabled()
	return not module:IsEnabled() or not module.db.profile.DarkButtons
end

local function SetButtonOption(key, value)
	module.db.profile[key] = value
	module:RefreshDarkButtons()
end

UIElements.args = {
	Header = Opt:Header({name = "UI Elements"}),
	Description = Opt:Desc({name = "Customize button artwork and manage frames that Blizzard Edit Mode does not expose. Changes to protected frames are deferred until combat ends."}),
	Buttons = Opt:InlineGroup({name = "Button Appearance", args = {
		DarkButtons = {
			type = "toggle", order = 1, name = "Customize Buttons", width = "full",
			desc = "Choose button artwork for the Escape menu and other buttons separately. Protected action buttons keep their native artwork. Disabling restores Blizzard artwork. Changes made in combat apply when combat ends.",
			get = function() return module.db.profile.DarkButtons end,
			set = function(_, value) SetButtonOption("DarkButtons", value) end,
		},
		ButtonStyle = {
			type = "select", order = 2, name = "Other Buttons", width = "double",
			desc = "Choose Blizzard, Blizzard Dark, classic LUI or high-resolution LUI artwork for other supported buttons. Blizzard Dark uses the same style as the Escape menu option. Combine this with any Escape menu style.",
			values = {blizzard = "Blizzard", dark = "Blizzard Dark", classic = "LUI Classic", hd = "LUI HD"},
			sorting = {"blizzard", "dark", "classic", "hd"},
			get = function() return module.db.profile.ButtonStyle end,
			set = function(_, value) SetButtonOption("ButtonStyle", value) end,
			disabled = IsButtonCustomizationDisabled,
		},
		EscapeButtonStyle = {
			type = "select", order = 3, name = "Escape Menu Buttons", width = "double",
			desc = "Choose the artwork for Escape menu buttons independently: Blizzard, a dark version of Blizzard buttons, or rectangular LUI HD buttons. Button sizes and spacing stay the same.",
			values = {blizzard = "Blizzard", dark = "Blizzard Dark", hd = "LUI HD (Rectangular)"},
			sorting = {"blizzard", "dark", "hd"},
			get = function() return module.db.profile.EscapeButtonStyle end,
			set = function(_, value) SetButtonOption("EscapeButtonStyle", value) end,
			disabled = IsButtonCustomizationDisabled,
		},
	}}),
	Managed = Opt:Group({name = "LUI-Managed Frames", args = {}}),
	Blizzard = Opt:Group({name = "Blizzard Edit Mode", args = {
		Description = Opt:Desc({name = "Use Blizzard Edit Mode for the Objectives Tracker, Alternate Power/Encounter Bar, Durability Frame, Vehicle Seat Indicator and other native HUD systems."}),
		Open = Opt:Execute({name = "Open Blizzard Edit Mode", func = OpenBlizzardEditMode, disabled = InCombatLockdown}),
	}}),
}

for key, info in pairs(managedFrameOptions) do
	UIElements.args.Managed.args[key] = GenerateManagedFrameGroup(key, info)
end
