--[[
	Module.....: Minimap
	Description: Replace the default minimap.
]]
-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)
local L = LUI.L

---@class LUI.Minimap : LUIModule, AceHook-3.0
local module = LUI:NewModule("Minimap", "AceHook-3.0")

module.enableButton = true

-- ####################################################################################################################
-- ##### Default Settings #############################################################################################
-- ####################################################################################################################

module.defaults = {
	profile = {
		General = {
			CoordPrecision = 1,
			AlwaysShowText = true,
			ShowTextures = true,
			FontSize = 12,
		},
		Position = {
			X = -24,
			Y = -72,
			--RelativePoint = "TOPRIGHT",
			Point = "TOPRIGHT",
			Locked = false,
			Scale = 1,
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
