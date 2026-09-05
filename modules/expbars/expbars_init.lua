--[[
	This module initializes LUI's experience, reputation, honor, Heart of
	Azeroth and house-favor tracking bars. Shared bar behavior is in
	`expbars.lua`; each tracker keeps its own data-provider file.
]]

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.ExperienceBars : LUIModule, AceHook-3.0
local module = LUI:NewModule("Experience Bars", "AceHook-3.0")

local mainBarsCreated = false
-- ####################################################################################################################
-- ##### Default Settings #############################################################################################
-- ####################################################################################################################

module.defaults = {
	profile = {
		Width = 475,
		Height = 12,
		X = 0,
		Y = 6,
		Point = "BOTTOM",
		RelativePoint = "BOTTOM",
		SplitTracker = true,
		ShowText = true,
		ShowAzerite = true,
		Precision = 2,
		TextX = -2,
		TextY = 0,
		Spacing = 10,
		ShowCurrent = false,
		ShowMax = false,
		ShowPercent = true,
		ShortNumbers = true,
		ExpBarFill = "LUI_Gradient",
		ExpBarBg = "LUI_Minimalist",
		BackgroundMultiplier = 0.4,
		Colors = {
			Experience = { r = 0.6,  g = 0.6,  b = 1,    a = 1,   t = "Class", },
			Reputation = { r = 0.2,  g = 0.2,  b = 0.2,  a = 1,   t = "Class", },
			Azerite =    { r = 0.2,  g = 0.2,  b = 0.2,  a = 1,   t = "Class", },
			Honor =      { r = 0.18, g = 0.18, b = 0.18, a = 0.8, t = "Class", },
			HouseFavor = { r = 0.85, g = 0.55, b = 0.15, a = 1,   t = "Class", },
		},
		Fonts = {
			Text = { Name = "NotoSans-SCB", Size = 14, Flag = "" },
		},
	},
}

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

module.enableButton = true

function module:OnInitialize()
	LUI:RegisterModule(module)
end

function module:OnEnable()
	if not mainBarsCreated then
		mainBarsCreated = module:SetMainBar()
	end
	module:SetEventHandling(true)
	module.anchor:Show()
	module:UpdateMainBarVisibility()
end

function module:OnDisable()
	module:SetEventHandling(false)
	if module.anchor then module.anchor:Hide() end
end
