--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: artwork.lua
	Description: Control the various artwork around LUI.
	Version....: 1.0
	Rev Date...: 04/06/2014 [dd/mm/yyyy]
	Author.....: Mule
]]

-- External references.
local addonname, LUI = ...
local module = LUI:Module("Artwork")
local Profiler = LUI.Profiler

local db, dbd

Profiler.TraceScope(module, "Artwork", "LUI")

--	Defaults
module.defaults = {
	profile = {
		UpperArt = {
			Orb = true,
			Buttons = true,
			ButtonsBackground = true,
			CenterBackground = true,
			Background = true,
		},
		LowerArt = {
			BlackLine = true,
			ThemedLine = true,
		},
	},
}

module.getter = "generic"
module.setter = "generic"

function module:LoadOptions()
	local options = {
		Title = self:NewHeader("Artwork", 1),
		UpperArt = self:NewGroup("Upper Artwork", 2, true, {
			Orb = self:NewToggle("Show Orb", "When enabled the the central galaxy orb is shown.", 1, ToggleArt),
			Buttons = self:NewToggle("Show Buttons", "When enabled the central button functionality can be used to show or hide the chat, TPS, DPS and raid window.", 2, ToggleArt),
			ButtonsBackground = self:NewToggle("Show Buttons Background", "When enabled the central black button background is shown.", 3, ToggleArt),
			CenterBackground = self:NewToggle("Show Themed Center Background", "When enabled the themed central background is shown.", 4, ToggleArt),
			Background = self:NewToggle("Show Themed Background", "When enabled the top left and right-hand side themed background is shown.", 5, ToggleArt),
		}),
		LowerArt = self:NewGroup("Lower Artwork", 3, true, {
			BlackLine = self:NewToggle("Show Black Line", "Enable the bottom left and right black line.", 1, ToggleArt),
			ThemedLine = self:NewToggle("Show Themed Line", "Enable the bottom left and right themed line.", 2, ToggleArt),
		}),
	}
	return options
end

function ToggleArt(status)

	if db.UpperArt.Orb then
		LUI.Orb.Hover:Show()
		LUI.Orb.Ring2:Show()
		LUI.Orb.Ring4:Show()
		LUI.Orb.Ring7:Show()
		LUI.Orb.Cycle:Show()
		LUI.Orb.Galaxy1:Show()
		LUI.Orb.Galaxy2:Show()
		LUI.Orb.Galaxy3:Show()
		LUI.Orb.Fill:Show()
		LUI.Orb:EnableMouse(true)
	else
		LUI.Orb.Hover:Hide()
		LUI.Orb.Ring2:Hide()
		LUI.Orb.Ring4:Hide()
		LUI.Orb.Ring7:Hide()
		LUI.Orb.Cycle:Hide()
		LUI.Orb.Galaxy1:Hide()
		LUI.Orb.Galaxy2:Hide()
		LUI.Orb.Galaxy3:Hide()
		LUI.Orb.Fill:Hide()
		LUI.Orb:EnableMouse(false)
	end

	if db.UpperArt.Buttons then
		LUI.Navi.Chat:Show()
		LUI.Navi.Chat.Hover:Show()
		LUI.Navi.Chat.Clicker:Show()
		LUI.Navi.Tps:Show()
		LUI.Navi.Tps.Hover:Show()
		LUI.Navi.Tps.Clicker:Show()
		LUI.Navi.Dps:Show()
		LUI.Navi.Dps.Hover:Show()
		LUI.Navi.Dps.Clicker:Show()
		LUI.Navi.Raid:Show()
		LUI.Navi.Raid.Hover:Show()
		LUI.Navi.Raid.Clicker:Show()
	else
		LUI.Navi.Chat:Hide()
		LUI.Navi.Chat.Hover:Hide()
		LUI.Navi.Chat.Clicker:Hide()
		LUI.Navi.Tps:Hide()
		LUI.Navi.Tps.Hover:Hide()
		LUI.Navi.Tps.Clicker:Hide()
		LUI.Navi.Dps:Hide()
		LUI.Navi.Dps.Hover:Hide()
		LUI.Navi.Dps.Clicker:Hide()
		LUI.Navi.Raid:Hide()
		LUI.Navi.Raid.Hover:Hide()
		LUI.Navi.Raid.Clicker:Hide()
	end

	if db.UpperArt.ButtonsBackground then
		LUI.Navi.TopButtonBackground:Show()
	else
		LUI.Navi.TopButtonBackground:Hide()
	end

	if db.UpperArt.CenterBackground then
		if db.UpperArt.Background then
			LUI.Navi.CenterBackground:Show()
			LUI.Navi.CenterBackgroundAlternative:Hide()
		else
			LUI.Navi.CenterBackground:Hide()
			LUI.Navi.CenterBackgroundAlternative:Show()
		end
	else
		LUI.Navi.CenterBackground:Hide()
		LUI.Navi.CenterBackgroundAlternative:Hide()
	end

	if db.UpperArt.Background then
		if db.UpperArt.CenterBackground then
			LUI.Info.Topleft:Show()
			LUI.Info.Topright:Show()
			LUI.Info.TopleftAlternative:Hide()
			LUI.Info.ToprightAlternative:Hide()
		else
			LUI.Info.Topleft:Hide()
			LUI.Info.Topright:Hide()
			LUI.Info.TopleftAlternative:Show()
			LUI.Info.ToprightAlternative:Show()
		end
	else
		LUI.Info.Topleft:Hide()
		LUI.Info.Topright:Hide()
		LUI.Info.TopleftAlternative:Hide()
		LUI.Info.ToprightAlternative:Hide()
	end

	if db.LowerArt.BlackLine then
		LUI.Info.Left.Panel:Show()
		LUI.Info.Right.Panel:Show()
	else
		LUI.Info.Left.Panel:Hide()
		LUI.Info.Right.Panel:Hide()
	end

	if db.LowerArt.ThemedLine then
		LUI.Info.Left.BG:Show()
		LUI.Info.Right.BG:Show()
	else
		LUI.Info.Left.BG:Hide()
		LUI.Info.Right.BG:Hide()
	end

	if status == "disabled" then
		LUI.Orb.Hover:Hide()
		LUI.Orb.Ring2:Hide()
		LUI.Orb.Ring4:Hide()
		LUI.Orb.Ring7:Hide()
		LUI.Orb.Cycle:Hide()
		LUI.Orb.Galaxy1:Hide()
		LUI.Orb.Galaxy2:Hide()
		LUI.Orb.Galaxy3:Hide()
		LUI.Orb.Fill:Hide()
		LUI.Orb:EnableMouse(false)

		LUI.Navi.Chat:Hide()
		LUI.Navi.Chat.Hover:Hide()
		LUI.Navi.Chat.Clicker:Hide()
		LUI.Navi.Tps:Hide()
		LUI.Navi.Tps.Hover:Hide()
		LUI.Navi.Tps.Clicker:Hide()
		LUI.Navi.Dps:Hide()
		LUI.Navi.Dps.Hover:Hide()
		LUI.Navi.Dps.Clicker:Hide()
		LUI.Navi.Raid:Hide()
		LUI.Navi.Raid.Hover:Hide()
		LUI.Navi.Raid.Clicker:Hide()

		LUI.Navi.TopButtonBackground:Hide()

		LUI.Navi.CenterBackground:Hide()

		LUI.Info.Topleft:Hide()
		LUI.Info.Topright:Hide()

		LUI.Info.TopleftAlternative:Hide()
		LUI.Info.ToprightAlternative:Hide()

		LUI.Info.Left.Panel:Hide()
		LUI.Info.Right.Panel:Hide()

		LUI.Info.Left.BG:Show()
		LUI.Info.Right.BG:Show()

		LUI.Info.Left.BG:Hide()
		LUI.Info.Right.BG:Hide()
	end
end

function module:OnInitialize()
	db, dbd = LUI:NewNamespace(self, true)
end

function module:OnEnable()
	ToggleArt()
end

function module:OnDisable()
	ToggleArt("disabled")
end
