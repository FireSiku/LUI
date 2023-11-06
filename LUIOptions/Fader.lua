-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class Opt
local Opt = select(2, ...)

---@type AceLocale.Localizations, LUI.Fader, AceDB-3.0
local L, module, db = Opt:GetLUIModule("Fader")
if not module or not module.registered then return end

local Fader = Opt:CreateModuleOptions("Fader", module)
Fader.get, Fader.set = Opt.GetSet(db.GlobalSettings)

-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################

local function ApplySettings()
	if not module.RegisteredFrames then return end
	-- Re-apply settings to frames.
	for frame, settings in pairs(module.RegisteredFrames) do
		---@TODO: Refactor how global settings are enforcedd, as passing nil does not convey it properly.
		local appliedSettings = (not db.ForceGlobalSettings) and settings or nil
		module:RegisterFrame(frame, appliedSettings, frame.FaderSpecialHover)
	end
end

function module:ImportFaderSettings(name, order, get, set)
    local group = Opt:Group({name = name, get = get, db = set, args = {
		FadeInHeader = Opt:Header({name = "Fade In"}),
		Casting = Opt:Toggle({name = "While Casting"}),
		InCombat = Opt:Toggle({name = "While In Combat"}),
		Health = Opt:Toggle({name = "While Health Is Low"}),
		Power = Opt:Toggle({name = "While Power Is Low"}),
		Targeting = Opt:Toggle({name = "While Targeting"}),

		Settings = Opt:Header({name = "Settings"}),
		InAlpha = Opt:Slider({name = "In Alpha", desc = "Set the alpha of the frame while not faded.", values = Opt.PercentValues}),
		OutAlpha = Opt:Slider({name = "Out Alpha", desc = "Set the alpha of the frame while faded.", values = Opt.PercentValues}),
		OutTime = Opt:Slider({name = "Fade Time", desc = "Set the time it takes to fade out.", values = Opt.PercentValues}),
		OutDelay = Opt:Slider({name = "Fade Delay", desc = "Set the delay time before the frame fades out.", values = Opt.PercentValues}),
		HealthClip = Opt:Slider({name = "Health Trigger", desc = "Set the percent at which health is considered low.", values = Opt.PercentValues}),
		PowerClip = Opt:Slider({name = "Power Trigger", desc = "Set the percent at which power is considered low.", values = Opt.PercentValues}),

		Hover = Opt:Header({name = "Mouse Hover"}),
		HoverEnable = Opt:Toggle({name = "Fade On Mouse Hover"}),
		HoverAlpha = Opt:Slider({name = "Hover Alpha", desc = "Set the alpha of the frame while the mouse is hovering over it.", values = Opt.PercentValues}),
    }})

    return group
end

-- ####################################################################################################################
-- ##### Options Tables ###############################################################################################
-- ####################################################################################################################

Fader.args = module:ImportFaderSettings("Fader").args
Fader.args.ModuleHeader = Opt:Header({"Fader"})
Fader.args.ForceGlobalSettings = Opt:Toggle({name = "Force These Global Settings:", width = "double", db = db})
