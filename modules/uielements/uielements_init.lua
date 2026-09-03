-- LUI-owned positioning for Blizzard frames that Edit Mode does not expose.

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.UIElements : LUIModule, AceHook-3.0, AceEvent-3.0
local module = LUI:NewModule("UI Elements", "AceHook-3.0", "AceEvent-3.0")
module.enableButton = true

module.defaults = {
	profile = {
		ZoneObjectives = {
			X = 300,
			Y = -35,
			ManagePosition = true,
		},
		CaptureBar = {
			X = -5,
			Y = -235,
			ManagePosition = false,
		},
		GroupLoot = {
			X = 0,
			Y = 120,
			ManagePosition = false,
		},
		TicketStatus = {
			X = -175,
			Y = -70,
			ManagePosition = false,
		},
	},
}

function module:OnInitialize()
	LUI:RegisterModule(module)
end

function module:OnEnable()
	module:RegisterEvent("ADDON_LOADED", "Refresh")
	module:RegisterEvent("PLAYER_ENTERING_WORLD", "Refresh")
	module:Refresh()
end

function module:OnDisable()
	module:UnregisterAllEvents()
	module:RestoreManagedFrames()
	module:HidePreviews()
	module:UnhookAll()
end
