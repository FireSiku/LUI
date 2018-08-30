--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: artwork.lua
	Description: Control the various art work around LUI
	Version....: 1.0
	Rev Date...: 04/06/2014 [dd/mm/yyyy]
	Author.....: Mule
	
]]

-- External references.
local addonname, LUI = ...
local module = LUI:Module("Art Work")
local Profiler = LUI.Profiler

-- Database and defaults shortcuts.
local db, dbd

Profiler.TraceScope(module, "ArtWork", "LUI")

module.defaults = {
	profile = {
		-- Orb option disable the entire panel. BlankOrb only affect textures.
		UpperArt = {
			Orb = false,
			Background = false,
			NaviBG = false,
		},
		LowerArt = {
			ThemeLine = false,
			BackGLine = false,
		},
	},
}

module.getter = "generic"
module.setter = "generic"

function module:LoadOptions()
	local options = {
		Title = self:NewHeader("Art Work", 1),
		UpperArt = self:NewGroup("Upper Art", 2, true, {
			Orb = self:NewToggle("Disable the Orb", "", 1, toggleArt),
			--Note = self:NewDesc("Be careful with this option as you will not have control over the textures provided by the panel buttons.", 2),
			NaviBG = self:NewToggle("Disable the Orb navigation background", "", 4, toggleArt),
			Background = self:NewToggle("Disable the themed background art", "", 7, toggleArt),
			--NewToggle(name, desc, order, func, width, disabled, hidden)
		}),
		LowerArt = self:NewGroup("Lower Art", 3, true, {
			ThemeLine = self:NewToggle("Disable the black foreground line", "", 1, toggleArt),
			BackGLine = self:NewToggle("Disable the themed background art", "", 4, toggleArt),
		}),
	}
	return options
end

function toggleArt(what)
	if not db.UpperArt.Orb or what == "enable" then
		LUI.Orb.Hover:Show()
		LUI.Orb.Ring2:Show()
		LUI.Orb.Ring4:Show()
		LUI.Orb.Cycle:Show()
		LUI.Orb.Ring7:Show()
		LUI.Orb.Galaxy1:Show()
		LUI.Orb.Galaxy2:Show()
		LUI.Orb.Galaxy3:Show()
		LUI.Orb.Fill:Show()
		LUI.Orb:EnableMouse(true)
		--LUI.Orb:Show()
	else
		LUI.Orb.Hover:Hide()
		LUI.Orb.Ring2:Hide()
		LUI.Orb.Ring4:Hide()
		LUI.Orb.Cycle:Hide()
		LUI.Orb.Ring7:Hide()
		LUI.Orb.Galaxy1:Hide()
		LUI.Orb.Galaxy2:Hide()
		LUI.Orb.Galaxy3:Hide()
		LUI.Orb.Fill:Hide()
		LUI.Orb:EnableMouse(false)
		--LUI.Orb:Hide()
	end
	if not db.UpperArt.Background or what == "enable" then
		LUI.Navi.Top2:Show()
		LUI.Info.Topleft:Show()
		LUI.Info.Topright:Show()
	else
		LUI.Navi.Top2:Hide()
		LUI.Info.Topleft:Hide()
		LUI.Info.Topright:Hide()
	end
	if not db.UpperArt.NaviBG or what == "enable" then
		LUI.Navi.Top:Show()
	else
		LUI.Navi.Top:Hide()
	end
	if not db.LowerArt.ThemeLine or what == "enable" then
		LUI.Info.Left.Panel:Show()
		LUI.Info.Right.Panel:Show()
	else
		LUI.Info.Left.Panel:Hide()
		LUI.Info.Right.Panel:Hide()
	end
	if not db.LowerArt.BackGLine or what == "enable" then
		LUI.Info.Left.BG:Show()
		LUI.Info.Right.BG:Show()
	else
		LUI.Info.Left.BG:Hide()
		LUI.Info.Right.BG:Hide()
	end
end

function module:OnInitialize()
	db, dbd = LUI:NewNamespace(self, true)
end

function module:OnEnable()
	toggleArt()
end

function module:OnDisable()
	toggleArt("enable")
end
