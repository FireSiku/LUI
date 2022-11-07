--[[
	This module handle experience bars of all sorts.
	By default it will serves as an experience bar under the action bars
	This main bar will split off in two if you are watching a reputation or honor.
	[Rep  <--] [-->   XP]

	Honor takes priority over faction reputations.
	If displaying Azerite is enabled, it becomes AP / XP.
	At max level, the XP bar is fully replaced by a rep/honor tracking bar. Hidden if not tracking either of them.
	
	Upcoming new feautre: Letting users create an additional customizable tracking bar.

	This file handles the handling of the bars, XP/Rep data handling should be in their own files.
]]

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, LUIAddon
local _, LUI = ...

---@class ExpBarModule : LUIModule
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
		ShowRested = false,
		ShowText = true,
		ShowAzerite = true,
		ShowGenesis = false,
		Precision = 2,
		TextX = -2,
		TextY = 0,
		Spacing = 10,
		ExpBarFill = "Gradient",
		ExpBarBg = "Minimalist",
		Colors = {
			Experience = { r = 0.6,  g = 0.6,  b = 1,    a = 1,   t = "Class", },
			Reputation = { r = 0.2,  g = 0.2,  b = 0.2,  a = 1,   t = "Class", },
			Azerite =    { r = 0.2,  g = 0.2,  b = 0.2,  a = 1,   t = "Class", },
			Honor =      { r = 0.18, g = 0.18, b = 0.18, a = 0.8, t = "Class", },
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
	module:UpdateMainBarVisibility()
end

function module:OnDisable()
	module.anchor:Hide()
end
