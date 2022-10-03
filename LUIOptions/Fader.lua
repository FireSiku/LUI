-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, Opt
local optName, Opt = ...
local L, module, db = Opt:GetLUIModule("Fader")
if not module or not module.registered then return end


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
    local group = Opt:Group(name, nil, order, nil, nil, nil, get, set)
    group.args = {
		FadeInHeader = Opt:Header("Fade In", 11),
		Casting = Opt:Toggle("While Casting", nil, 12),
		InCombat = Opt:Toggle("While In Combat", nil, 13),
		Health = Opt:Toggle("While Health Is Low", nil, 14),
		Power = Opt:Toggle("While Power Is Low", nil, 15),
		Targeting = Opt:Toggle("While Targeting", nil, 16),

		Settings = Opt:Header("Settings", 21),
		InAlpha = Opt:Slider("In Alpha", "Set the alpha of the frame while not faded.", 22, Opt.PercentValues),
		OutAlpha = Opt:Slider("Out Alpha", "Set the alpha of the frame while faded.", 23, Opt.PercentValues),
		OutTime = Opt:Slider("Fade Time", "Set the time it takes to fade out.", 24, Opt.PercentValues),
		OutDelay = Opt:Slider("Fade Delay", "Set the delay time before the frame fades out.", 25, Opt.PercentValues),
		HealthClip = Opt:Slider("Health Trigger", "Set the percent at which health is considered low.", 26, Opt.PercentValues),
		PowerClip = Opt:Slider("Power Trigger", "Set the percent at which power is considered low.", 28, Opt.PercentValues),

		Hover = Opt:Header("Mouse Hover", 31),
		HoverEnable = Opt:Toggle("Fade On Mouse Hover", nil, 32),
		HoverAlpha = Opt:Slider("Hover Alpha", "Set the alpha of the frame while the mouse is hovering over it.", 33, Opt.PercentValues),
    }

    return group
end

-- ####################################################################################################################
-- ##### Options Tables ###############################################################################################
-- ####################################################################################################################

Opt.options.args.Fader = Opt:Group("Fader", nil, nil, "tab", Opt.IsModDisabled, nil, Opt.GetSet(db.GlobalSettings))
Opt.options.args.Fader.handler = module

local Fader = module:ImportFaderSettings("Fader").args
Fader.ModuleHeader = Opt:Header("Fader", 1)
Fader.ForceGlobalSettings = Opt:Toggle("Force These Global Settings:", nil, 2, nil, "double", nil, nil, Opt.GetSet(db))

Opt.options.args.Fader.args = Fader