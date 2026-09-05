-- This module creates a menu containing all the raid markers, world pillars and other raid/party commands

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
		MatchMicromenuBackground = true,
		BackgroundColor = {r = 0.05, g = 0.05, b = 0.05, a = 1},
		Scale = 1,
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
end

function module:OnEnable()
	self:SetRaidMenu()
end

function module:OnDisable()
	self:HideRaidMenu()
end
