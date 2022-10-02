-- This module creates a menu containing all the raid markers, world pillars and other raid/party commands
--- @TODO: Fully use Secure Handlers to allow for it to be used in combat..

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, LUIAddon
local _, LUI = ...
local L = LUI.L

---@class FaderModule : LUIModule
local module = LUI:NewModule("Fader", "LUIDevAPI", "AceHook-3.0", "AceTimer-3.0")

-- ####################################################################################################################
-- ##### Default Settings #############################################################################################
-- ####################################################################################################################

module.defaults = {
	profile = {
		Enable = true,
		ForceGlobalSettings = true,
		GlobalSettings = {
			Casting = true,
			Combat = true,
			Enable = true,
			Health = true,
			HealthClip = 1.0,
			Hover = true,
			HoverAlpha = 0.75,
			InAlpha = 1.0,
			OutAlpha = 0.1,
			OutDelay = 0.0,
			OutTime = 1.5,
			Power = true,
			PowerClip = 0.9,
			Targeting = true,
			UseGlobalSettings = true,
		},
	}
}

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function module:OnInitialize()
	LUI:NewNamespace(self, true)
	LUI:RegisterModule(module, true)
end

function module:OnEnable()
	module:SetFader()
end

function module:OnDisable()
	-- Check if events need to be un-registered
	if self.RegisteredFrames then
		self:EventsUnregister()

		-- Disable fader on registered frames.
		for frame in pairs(self.RegisteredFrames) do
			-- If currently fading, stop fading.
			if frame.Fader.fading then
				self:StopFading(frame)
			end

			-- Remove hover scripts
			self:RemoveHoverScript(frame)

			-- Reset alpha.
			frame:SetAlpha((frame.Fader and frame.Fader.PreAlpha) or 1)

			-- Remove variables.
			frame.Fader = nil
		end
	end
end
