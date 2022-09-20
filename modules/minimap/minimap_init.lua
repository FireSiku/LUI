--[[
	Module.....: Minimap
	Description: Replace the default minimap.
]]
-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

local _, LUI = ...
local module = LUI:NewModule("Minimap", "AceHook-3.0")

-- ####################################################################################################################
-- ##### Default Settings #############################################################################################
-- ####################################################################################################################

module.defaults = {
	profile = {
		General = {
			Scale = 1,
			CoordPrecision = 1,
			AlwaysShowText = false,
			HideMissingCoord = true,
			ShowTextures = true,
			FontSize = 12,
			MissionReport = true,
		},
		Position = {
			X = -24,
			Y = -80,
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
		},
	},
}

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function module:OnInitialize()
	LUI:RegisterModule(module, true)
end

function module:OnEnable()
	module:SetMinimap()
end

function module:OnDisable()
	module:RestoreDefaultMinimap()
end