-- This module handle various UI Elements by LUI or Blizzard.
-- It's an umbrella module to consolidate the many, many little UI changes that LUI does
--	that do not need a full module for themselves.

-- ####################################################################################################################
-- ##### Setup and Defaults ###########################################################################################
-- ####################################################################################################################

local _, LUI = ...
local module = LUI:NewModule("UI Elements", "AceHook-3.0")

module.defaults = {
	profile = {
		ObjectiveTracker = {
			OffsetX = -150,
			OffsetY = -300,
			HeaderColor = true,
			ManagePosition = true,
		},
		OrderHallCommandBar = {
			HideFrame = true,
		},
		DurabilityFrame = {
			X = -90,
			Y = 0,
			ManagePosition = false,
			HideFrame = false,
		},

		AlwaysUpFrame = {
			X = 300,
			Y = -35,
			ManagePosition = true,
			HideFrame = false,
		},
		VehicleSeatIndicator = {
			X = -10,
			Y = -260,
			ManagePosition = true,
			HideFrame = false,
		},
		CaptureBar = {
			X = -5,
			Y = -235,
			ManagePosition = true,
			HideFrame = false,
		},
		TicketStatus = {
			X = -175,
			Y = -70,
			ManagePosition = true,
			HideFrame = false,
		},
		PlayerPowerBarAlt = {
			X = 0,
			Y = 160,
			ManagePosition = false,
			HideFrame = false,
		},
		GroupLootContainer = {
			X = 0,
			Y = 120,
			ManagePosition = false,
			HideFrame = false,
		},
		MawBuffs = {
			X = -180,
			Y = -70,
			ManagePosition = true,
			HideFrame = false,
		}
	},
}

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function module:OnInitialize()
	LUI:RegisterModule(module)
end

function module:OnEnable()
	module:SetUIElements()
end

function module:OnDisable()
end
