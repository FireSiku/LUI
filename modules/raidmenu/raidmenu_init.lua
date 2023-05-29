-- This module creates a menu containing all the raid markers, world pillars and other raid/party commands
--- @TODO: Fully use Secure Handlers to allow for it to be used in combat..

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.RaidMenu : LUIModule
local module = LUI:NewModule("RaidMenu")

-- ####################################################################################################################
-- ##### Default Settings #############################################################################################
-- ####################################################################################################################

module.defaults = {
	profile = {
		Enable = true,
		Compact = true,
		Spacing = 5,
		OverlapPrevention = "Offset",
		Offset = -30,
		X_Offset = 0,
		Opacity = 100,
		Scale = 1,
		ToggleRaidIcon = true,
		ShowToolTips = false,
		AutoHide = false,
	},
}

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function module:OnInitialize()
	LUI:NewNamespace(self, nil, true)
	LUI:RegisterModule(module, true)

	LUI:GetModule("Panels"):RegisterFrame(self)
end

function module:OnEnable()
	self:SetRaidMenu()
end
