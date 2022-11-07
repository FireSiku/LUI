--[[
	Module.....: Minimap
	Description: Replace the default minimap.
]]
-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, LUIAddon
local _, LUI = ...
local L = LUI.L

---@class MinimapModule : LUIModule
local module = LUI:NewModule("Minimap", "AceHook-3.0")

module.enableButton = true

-- ####################################################################################################################
-- ##### Default Settings #############################################################################################
-- ####################################################################################################################

module.defaults = {
	profile = {
		General = {
			Scale = 1,
			CoordPrecision = 1,
			AlwaysShowText = true,
			HideMissingCoord = true,
			ShowTextures = true,
			FontSize = 12,
			MissionReport = true,
		},
		Position = {
			X = -24,
			Y = -72,
			--RelativePoint = "TOPRIGHT",
			Point = "TOPRIGHT",
			Locked = false,
			Scale = 1,
		},
		Icons = {
			Mail = "BOTTOMLEFT",
			BG = "BOTTOMRIGHT",
			LFG = "TOPRIGHT",
			GMTicket = "TOPLEFT",
		},
		Fonts = {
			Text = { Name = "NotoSans-SCB", Size = 12, Flag = "OUTLINE", },
		},
		Colors = {
			Minimap = { r = 0.21, g = 0.22, b = 0.23, a = 1, t = "Class", },
			Text =    { r = 1, g = 1, b = 1, a = 1, t = "Individual", },
		},
	},
}

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function module:OnInitialize()
	LUI:RegisterModule(module)
end

function module:OnEnable()
	module:SetMinimap()
end

function module:OnDisable()
	module:RestoreDefaultMinimap()
end
