--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: cooldown.lua
	Description: Cooldown Timer Module
]]

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Cooldown: LUIModule, AceHook-3.0
local module = LUI:NewModule("Cooldown", "AceHook-3.0")
local Media = LibStub("LibSharedMedia-3.0")
local db --luacheck: ignore

-- ####################################################################################################################
-- ##### Default Settings #############################################################################################
-- ####################################################################################################################

module.defaults = {
	profile = {
		General = {
			MinDuration = 3,
			MinScale = 0.5,
			Precision = 1,
			Threshold = 8,
			MinToSec = 60,
			FilterWA = true,
			SupportAll = false,
		},
		Text = {
			Font = "vibroceb",
			Size = 20,
			Flag = "OUTLINE",
			XOffset = 2,
			YOffset = 0,
			Align = "CENTER",
		},
		Colors = {
			Day =       {r = 0.8, g = 0.8, b = 0.8},
			Hour =      {r = 0.8, g = 0.8, b = 1.0},
			Min =       {r = 1.0, g = 1.0, b = 1.0},
			Sec =       {r = 1.0, g = 1.0, b = 0.0},
			Threshold = {r = 1.0, g = 0.0, b = 0.0},
		},
	},
}

module.conflicts = "OmniCC;tullaCooldownCount"
module.enableButton = true

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function module:OnInitialize()
	LUI:RegisterModule(module)
end

function module:DBCallback(event, dbobj, profile)
	module:OnInitialize()

	module:Refresh()
end

function module:Refresh()
	module:UpdateVars()

	for i, timer in ipairs(module.timers) do
		if timer.enabled then
			timer.fontScale = nil -- force update
			if timer:Scale() then
				timer:Position()
			end
		end
	end
end

function module:OnEnable()
	LUI.Profiler.TraceScope(module, "Cooldown", "LUI", 2)
	module:UpdateVars()

	module.initTimer()

	-- Register frames handled by SetActionUIButton
	if _G.ActionBarButtonEventsFrame.frames then
		for i, frame in pairs(_G.ActionBarButtonEventsFrame.frames) do
			module:RegisterActionUIButton(frame)
		end
	end
	-- module:SecureHook(ActionBarButtonEventsFrameMixin, "RegisterFrame", "RegisterActionUIButton")
	module:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
end

function module:OnDisable()
	module:UnhookAll()
	module:UnregisterAllEvents()

	for i, timer in ipairs(module.timers) do
		if timer.enabled then
			timer:Stop()
		end
	end
end
