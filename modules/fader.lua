--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: fader.lua
	Description: This module can handle fading of frames registered with it.
	Version....: 2.0
	Rev Date...: 17/06/2010 [dd/mm/yyyy]

	Edits:
		v2.0: Hix
]]

------------------------------------------------------
-- / Notes / --
------------------------------------------------------
--[[	
	events:
		There are a lot of events registered I know. Sadly these are the ones
		i found most suitable with the least spam (or controllable) while still
		capturing all possible triggers and situations where the fader will be
		needed to operate. If you can find more please post them in the according
		thread on the forums for this module.
			
	settings changes:
		When the user makes changes in the options screen, some changes may not take
		effect till a reloadui. A list of known ones will be here.
		List:
			Hover Scripts,
			
	settings:
		Settings are now passed into the fader when registering a frame. RegisteredFrames now
		holds reference tables for the settings of each frame. The intent is that along with a frame
		db.oUF.<frame>.FaderSettings database would be passed with the frame during registering.
		
	more settings:
		I dunno if i should add more settings. If we wanted we could add tons more
		for which a lot of the EventHandler logic would need updated but that shouldn't
		be so bad. Extra settings like individual alpha/time/delay settings for each
		event types.
]]

------------------------------------------------------
-- / Changes / --
------------------------------------------------------
--[[
	2.0:
		1)	Updated so usable with new framework.
		2)	No longer hooks OnUpdate scripts. Instead the module has its own frame which runs an OnUpdate script.
		
	1.0 (b):
		1)	Changed the way registered frames are store. Now stored like follows:
				frame = framesettings.
			To keep track of number of frames I added variable Fader.RegisteredFrameTotal 
		2)	Update all logic and code for above changes (BIG CHANGE)
		3)	Re-ordered fade logic to try against most likely first:
				targeting, combat, power, health, casting

	1.0 (a):
		1)	Added remove hover script method.
		2)	Added loops to OnEnable/OnDisable to attach/remove hover scripts
			from registered frames.
		3)	frame.Fade tables are now created upon register of frames. They are
			also removed upon unregistered. This removes a step from relevant logic
			tests by allowing methods to assume the frame will have a table.
		4)	Added power returns to Collect_States() function.
		5)	Changed health/power return information to this format:
				returns false if state is normal (not a trigger)
				returns the percent of health/power.
				power is in the format: 1(100%) equals full, 0(0%) equals empty
		7)	Added second EventHandler function (UnitEventHandler) to specifily
			handle events that recieve unit parameters. This way to speed up
			normal events, removing undeed checks.
		6)	Updated logic for above changes.				
]]

local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local LSM = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists
local Fader = LUI:NewModule("Fader", "AceEvent-3.0", "AceHook-3.0")

-- Fader local variables.
-- RegisteredFrames[frame] = frameSettings. (e.i. RegisteredFrames = { oUF_LUI_player = db.oUF.Player.Fader, oUF_LUI_target = db.oUF.Target.Fader, etc })
local db
Fader.Fading = {}
Fader.Fader = CreateFrame("frame", "LUI_Fader", UIParent)
Fader.Fader.Throttle = 0
Fader.RegisteredFrames = nil
Fader.RegisteredFrameTotal = 0
Fader.Status = {
	casting = false,
	combat = false,
	health = false,
	power = false,	
	targeting = false,
}

------------------------------------------------------
-- / Fader Utilities / --
------------------------------------------------------

--[[
	Function..: Hover_OnEnter(self)
	Notes.....: fades the frame when the mouse enters the frame
]]
local Hover_OnEnter = function(self)
	-- set mouse hover.
	self.Fader.mouseHover = true

	-- check if already fading in.
	if self.Fader.fading and self.Fader.endAlpha > Fader.RegisteredFrames[self].HoverAlpha then return end
		
	-- cancel any fading.
	Fader:StopFading(self)

	-- check if fade is required.
	if self:GetAlpha() >= Fader.RegisteredFrames[self].HoverAlpha then return end

	-- fade in frame.
	Fader:FadeFrame(self, Fader.RegisteredFrames[self].HoverAlpha)
end

--[[
	Function..: Hover_OnLeave(self)
	Notes.....: fades out the frame when the mouse leaves the frame
]]
local Hover_OnLeave = function(self)
	-- set mouse hover.
	self.Fader.mouseHover = false

	-- check if already fading out.
	if self.Fader.fading and not self.Fader.fadingIn then return end
	
	-- fade out frame.
	Fader:FadeFrame(self,	Fader.RegisteredFrames[self].OutAlpha,
							Fader.RegisteredFrames[self].OutTime,
							Fader.RegisteredFrames[self].OutDelay)
	Fader:FadeHandler(self)
end

--[[
	Function..: AttachHoverScript(frame)
	Notes.....: registers a mouseover script to a given frame if needed
	Parameters:
		frame: frame to be given hover scripts
]]
function Fader:AttachHoverScript(frame)
	-- check settings.
	if not self.RegisteredFrames[frame].Hover then
		-- unhook if scripts are hooked.
		self:RemoveHoverScript(frame)
		return
	end
	
	-- hook scripts.
	if not self:IsHooked(frame, "OnEnter") then self:SecureHookScript(frame, "OnEnter", Hover_OnEnter) end
	if not self:IsHooked(frame, "OnLeave") then self:SecureHookScript(frame, "OnLeave", Hover_OnLeave) end

	-- run leave script.
	frame:GetScript("OnLeave")(frame)
end

--[[
	Function..: RemoveHoverScript(frame)
	Notes.....: un-registers the mouseover script from the given frame
	Parameters:
		frame: frame to remove hover scripts from
]]
function Fader:RemoveHoverScript(frame)
	-- unhook scripts
	self:Unhook(frame, "OnEnter")		
	self:Unhook(frame, "OnLeave")	
end

--[[
	Function..: RegisterFrame(frame, settings)
	Notes.....: registers a given frame to the fader logic
	Parameters:
		frame: frame to be registered to the fader
		settings: settings for the frame
]]
function Fader:RegisterFrame(frame, settings)
	-- check fader is enabled.
	if not db.Fader.Enable then return end
	
	-- check frame is a usable objects.
	if not frame then return end
	
	-- apply settings
	if not settings then settings = db.Fader.GlobalSettings end	
	local usedSettings
	if db.Fader.ForceGlobalSettings then
		usedSettings = db.Fader.GlobalSettings
	else
		usedSettings = (settings.UseGlobalSettings and db.Fader.GlobalSettings) or settings
	end
	
	-- check if registered frames table exists.
	if not self.RegisteredFrames then
		self.RegisteredFrames = {}
		self.RegisteredFrames[frame] = usedSettings
		self.RegisteredFrameTotal = 1
		self:EventsRegister()
	else
		-- check if frame is already registered.
		if self.RegisteredFrames[frame] then 
			-- update frame's settings.
			self.RegisteredFrames[frame] = usedSettings
		else
			-- register frame and settings.
			self.RegisteredFrames[frame] = usedSettings
			self.RegisteredFrameTotal = self.RegisteredFrameTotal + 1
		end
	end
	
	-- create fader table.
	frame.Fader = frame.fader or {}
	frame.Fader.PreAlpha = frame.Fader.PreAlpha or frame:GetAlpha()
	
	-- attach mouseover scripts to frame.
	self:AttachHoverScript(frame)
	
	-- run fader
	self:FadeHandler(frame)
end

--[[
	Function..: UnregisterFrame(frame)
	Notes.....: un-registers a given frame from the fader logic
	Parameters:
		frame: frame to be un-registered from the fader
]]
function Fader:UnregisterFrame(frame)
	-- check frame is a usable object.
	if not frame then return end
	
	-- check if registered frames table exists.
	if not self.RegisteredFrames then return end

	-- check if frame is registered.
	if not self.RegisteredFrames[frame] then return end

	-- remove frame.
	self.RegisteredFrames[frame] = nil
	self.RegisteredFrameTotal = self.RegisteredFrameTotal - 1

	-- remove hooks.
	self:RemoveHoverScript(frame)
				
	-- reset alpha.
	frame:SetAlpha((frame.Fader and frame.Fader.PreAlpha) or 1)

	-- if currently fading, stop fading.
	if frame.Fader.fading then
		self:StopFading(frame)
	end

	-- remove variables.
	frame.Fader = nil
	
	-- check if there are any registered frames left.
	if self.RegisteredFrameTotal == 0 then
		self.RegisteredFrames = nil
		self:EventsUnregister()
	end
end

------------------------------------------------------
-- / Fade / Event Handlers / --
------------------------------------------------------

--[[
	Function..: EventsRegister()
	Notes.....: register all the event triggers for the fader
]]
function Fader:EventsRegister()
	-- register event triggers
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "EventHandler")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "EventHandler")
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "EventHandler")
	self:RegisterEvent("UNIT_HEALTH", "UnitEventHandler")
	self:RegisterEvent("UNIT_POWER", "UnitEventHandler")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", "UnitEventHandler")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", "UnitEventHandler")
	self:RegisterEvent("UNIT_SPELLCAST_START", "UnitEventHandler")
	self:RegisterEvent("UNIT_SPELLCAST_STOP", "UnitEventHandler")
end

--[[
	Function..: EventsUnregister()
	Notes.....: un-register all the event triggers for the fader
]]
function Fader:EventsUnregister()
	-- unregister event triggers
	self:UnregisterEvent("PLAYER_REGEN_DISABLED")
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:UnregisterEvent("PLAYER_TARGET_CHANGED")
	self:UnregisterEvent("UNIT_HEALTH")
	self:UnregisterEvent("UNIT_POWER")
	self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
	self:UnregisterEvent("UNIT_SPELLCAST_START")
	self:UnregisterEvent("UNIT_SPELLCAST_STOP")
end

--[[
	Function..: EventHandler()
	Notes.....: handles a passed event, checks frame fade triggers
]]
function Fader:EventHandler(event)
	-- collect info on states.
	if event == "PLAYER_REGEN_DISABLED" then
		self.Status.combat = true
	elseif event == "PLAYER_REGEN_ENABLED" then
		self.Status.combat = false
	elseif event == "PLAYER_TARGET_CHANGED" then
		self.Status.targeting = UnitExists("target")
	end
	
	-- and now the expensive bit
	for frame in pairs(self.RegisteredFrames) do
		self:FadeHandler(frame)
	end
end

--[[
	Function..: UnitEventHandler(eventname, unit)
	Notes.....: handles a passed event that recieves a unit parameter and checks if it is the player unit
	Parameters:
		eventname: name of the event passed
		unit: arg1, or unitid for UNIT_* events
]]
function Fader:UnitEventHandler(event, unit)
	-- check unit for player only.
	if unit ~= "player" then return end
	
	-- collect info on states.
	if event == "UNIT_HEALTH" then
		local curHealth, maxHeatlh = UnitHealth("player"), UnitHealthMax("player")
		self.Status.health = (curHealth < maxHeatlh) and (curHealth / maxHeatlh)
	elseif event == "UNIT_POWER" then
		local powerType, curPower, maxPower = UnitPowerType("player"), UnitPower("player"), UnitPowerMax("player")
		if (powerType == 0) or (powerType == 3) then
			self.Status.power = (curPower < maxPower) and (curPower / maxPower)
		elseif (powerType == 1) or (powerType == 6) then
			self.Status.power = (curPower > 0) and ((maxPower - curPower) / maxPower)
		end
	else
		-- Check for casting states.
		self.Status.casting = (UnitCastingInfo("player") ~= nil) or (UnitChannelInfo("player") ~= nil)
	end
	
	-- and now the expensive bit.
	for frame in pairs(self.RegisteredFrames) do
		self:FadeHandler(frame)
	end
end

--[[
	Function..: FadeHandler(frame)
	Notes.....: handles fading of a frame using the options of that frame
]]
function Fader:FadeHandler(frame)
	if frame.Fader.mouseHover then return end

	-- local variables.
	local fadeIn = false
	
	-- check states vs. settings.
	if self.Status.targeting and self.RegisteredFrames[frame].Targeting then
		fadeIn = true
	elseif self.Status.inCombat and self.RegisteredFrames[frame].Combat then
		fadeIn = true
	elseif self.Status.power and self.RegisteredFrames[frame].Power
		and (self.Status.power < self.RegisteredFrames[frame].PowerClip) then
		fadeIn = true
	elseif self.Status.health and self.RegisteredFrames[frame].Health
		and (self.Status.health < self.RegisteredFrames[frame].HealthClip) then
		fadeIn = true
	elseif self.Status.casting and self.RegisteredFrames[frame].Casting then
		fadeIn = true
	end
	
	-- fade according to results.
	self:FadeOnEvent(frame, fadeIn)
end

--[[
	Function..: FadeOnEvent(frame[, fadeIn])
	Notes.....: fades a frame dependant on events
	Parameters:
		frame: the frame to fade
		fadeIn: if the frame is fading in
]]
function Fader:FadeOnEvent(frame, fadeIn)
	if fadeIn then
		-- check if already fading in.
		if frame.Fader.fading and frame.Fader.fadingIn then return end

		-- check if fade is required.
		if frame:GetAlpha() >= self.RegisteredFrames[frame].InAlpha then self:StopFading(frame) return end

		-- set to fade in.
		self:FadeFrame(frame, self.RegisteredFrames[frame].InAlpha)
	else
		-- check if frame is fadingIn or for mouse hover.
		if frame.Fader.mouseHover or (frame.Fader.fading and not frame.Fader.fadingIn) then return end

		-- check if fade is required.
		if frame:GetAlpha() <= self.RegisteredFrames[frame].OutAlpha then return end
		
		-- set to fade out.
		self:FadeFrame(frame,	self.RegisteredFrames[frame].OutAlpha,
								self.RegisteredFrames[frame].OutTime,
								self.RegisteredFrames[frame].OutDelay)
	end
end

------------------------------------------------------
-- / Frame Fader / --
------------------------------------------------------

--[[
	Function..: Fade_OnUpdate(self, elapsed)
	Notes.....: fades the frame over time
]]
function Fader.Fader_OnUpdate(self, elapsed)
	-- check fader throttle.
	self.Throttle = self.Throttle + elapsed
	if self.Throttle < 0.05 then return end
	elapsed = self.Throttle
	self.Throttle = 0
	
	-- check if there are frames to fade.
	if #Fader.Fading == 0 then self:SetScript("OnUpdate", nil) end

	-- loop through frames and fade.
	for i, frame in ipairs(Fader.Fading) do
		-- manage delay before fading.
		if frame.Fader.fadeDelay > 0 then
			frame.Fader.fadeDelay = frame.Fader.fadeDelay - elapsed
		else	
			-- manage fading.
			frame.Fader.timeElapsed = frame.Fader.timeElapsed + elapsed
			if frame.Fader.timeElapsed < frame.Fader.fadeTime then
				frame:SetAlpha(frame.Fader.startAlpha + (frame.Fader.deltaAlpha * frame.Fader.timeElapsed / frame.Fader.fadeTime))
			else
				-- cleanup
				frame:SetAlpha(frame.Fader.endAlpha)
				if frame.Fader.endAlpha == 0 then frame:Hide() end
				Fader:StopFading(frame)
			end
		end
	end
end

--[[
	Function..: FadeFrame(frame, endalpha, fadetime, fadedelay)
	Notes.....: takes a frame and fades it with the given parameters
	Parameters:
		frame: frame to fade
		endalpha: alpha value to fade to
		fadetime: time (seconds) to fade over
		fadedelay: delay (seconds) before fading
]]
function Fader:FadeFrame(frame, endAlpha, fadeTime, fadeDelay)
	-- check frame is a usable object.
	if not frame then return end
	
	-- check if fading is needed.
	if frame:GetAlpha() == (endAlpha or 0) then
		-- stop fading.
		self:StopFading(frame)
		return
	end
	
	-- check if frame needs to be shown.
	if not frame:IsVisible() then
		-- set alpha to zero to avoid sudden flash of frame.
		frame:SetAlpha(0)
		frame:Show() 
	end
	
	-- setup fader settings.
	-- settings equal optional parameters or defaults.
	frame.Fader = frame.Fader or {}
	frame.Fader.startAlpha = frame:GetAlpha()
	frame.Fader.endAlpha = endAlpha or 0
	frame.Fader.deltaAlpha = frame.Fader.endAlpha - frame.Fader.startAlpha
	frame.Fader.fadingIn = frame.Fader.endAlpha > frame.Fader.startAlpha
	frame.Fader.fadeTime = fadeTime or 0.2
	frame.Fader.timeElapsed = 0
	frame.Fader.fadeDelay = fadeDelay or 0

	-- start fading frame.
	self:StartFading(frame)
end

--[[
	Function..: StartFading(frame)
	Notes.....: adds a frame to the fading table.
]]
function Fader:StartFading(frame)
	-- check frame isn't already fading.
	if frame.Fader.fading then return end

	-- check if OnUpdate script needs to be applied.
	if #self.Fading == 0 then
		self.Fader:SetScript("OnUpdate", self.Fader_OnUpdate)
		self.Fader.Throttle = 0
	end

	-- add frame to fading table.
	frame.Fader.fading = true
	tinsert(self.Fading, frame)
end

--[[
	Function..: StopFading(frame)
	Notes.....: removes a frame to the fading table.
]]
function Fader:StopFading(frame)
	-- find and remove frame.
	for i, v in ipairs(self.Fading) do
		if v == frame then
			frame.Fader.fading = false
			tremove(self.Fading, i)
			break
		end
	end
end

------------------------------------------------------
-- / Module Settings / --
------------------------------------------------------

function Fader:CreateFaderGroupOptions(objectPrefix, objectSuffix, objectCount, objectDB, objectDBdefaults)
	local frames = {}
	
	for i = 1, objectCount do
		frames[i] = _G[objectPrefix..i..objectSuffix]
	end
	
	-- Shortcut database values.
	local odb = objectDB
	local odbD = objectDBdefaults
	
	local ApplySettings = function()
		if odb.Enable then
			for k, v in pairs(frames) do Fader:RegisterFrame(v, odb) end
		else
			for k, v in pairs(frames) do Fader:UnregisterFrame(v) end
		end
	end
	
	local FaderOptions = {
		Enable = LUI:NewToggle("Enable Fader", nil, 1, odb, "Enable", nil, ApplySettings),
		UseGlobalSettings = LUI:NewToggle("Use Global Settings", nil, 2, odb, "UseGlobalSettings", nil, ApplySettings, nil, function() return (not odb.Enable) end),
		ForcingGlobal = {
			order = 3,
			width = "full",
			type = "description",
			name = "|cffff0000Global settings are being forced.|r",
			hidden = function() return not db.Fader.ForceGlobalSettings end,
		},
		Options = {
			name = "",
			type = "group",
			guiInline = true,
			disabled = function() return (not odb.Enable) or odb.UseGlobalSettings or db.Fader.ForceGlobalSettings end,
			order = 4,
			args = {
				FadeInHeader = LUI:NewHeader("Fade In", 2),
				Casting = LUI:NewToggle("Casting", nil, 3, odb, "Casting", nil, ApplySettings, "normal"),
				InCombat = LUI:NewToggle("In Combat", nil, 4, odb, "Combat", nil, ApplySettings, "normal"),
				Health = LUI:NewToggle("Health Is Low", nil, 5, odb, "Health", nil, ApplySettings, "normal"),
				Power = LUI:NewToggle("Power Is Low", nil, 6, odb, "Power", nil, ApplySettings, "normal"),
				Targeting = LUI:NewToggle("Targeting", nil, 7, odb, "Targeting", nil, ApplySettings, "full"),
				
				Settings = LUI:NewHeader("Settings", 8),
				InAlpha = LUI:NewSlider("In Alpha", "Set the alpha of the frame while not faded.", 9, odb, "InAlpha", odbD, 0, 1, 0.05, ApplySettings, "normal", nil, nil, true),
				OutAlpha = LUI:NewSlider("Out Alpha", "Set the alpha of the frame while faded.", 10, odb, "OutAlpha", odbD, 0, 1, 0.05, ApplySettings, "normal", nil, nil, true),
				OutTime = LUI:NewSlider("Fade Time", "Set the time it takes to fade out.", 11, odb, "OutTime", odbD, 0, 5, 0.05, ApplySettings, "normal"),
				OutDelay = LUI:NewSlider("Fade Delay", "Set the delay time before the frame fades out.", 12, odb, "OutDelay", odbD, 0, 5, 0.05, ApplySettings, "normal"),
				HealthClip = LUI:NewSlider("Health Trigger", "Set the percent at which health is considered low.", 13, odb, "HealthClip", odbD, 0, 1, 0.05, ApplySettings, "normal", nil, nil, true),
				PowerClip = LUI:NewSlider("Power Trigger", "Set the percent at which power is considered low.", 14, odb, "PowerClip", odbD, 0, 1, 0.05, ApplySettings, "normal", nil, nil, true),
				
				Hover = LUI:NewHeader("Mouse Hover", 15),
				HoverEnable = LUI:NewToggle("Fade On Mouse Hover", nil, 16, odb, "Hover", nil, ApplySettings, "normal"),
				HoverAlpha = LUI:NewSlider("Hover Alpha", "Set the alpha of the frame while the mouse is hovering over it.", 17, odb, "HoverAlpha", odbD, 0, 1, 0.05, ApplySettings, "normal", nil, nil, true),
			},
		},
	}
	
	return FaderOptions
end

function Fader:CreateFaderOptions(object, objectDB, objectDBdefaults)
	local frame
	if type(object) == "string" then
		frame = _G[object]
	else
		frame = object
	end
	
	-- Check frame is usable.
	if not frame then return end
	
	-- Shortcut database values.
	local odb = objectDB
	local odbD = objectDBdefaults
		
	local ApplySettings = function()
		if odb.Enable then
			Fader:RegisterFrame(frame, odb)
		else
			Fader:UnregisterFrame(frame)
		end
	end
	
	local FaderOptions = {
		Enable = LUI:NewToggle("Enable Fader", nil, 1, odb, "Enable", nil, ApplySettings),
		UseGlobalSettings = LUI:NewToggle("Use Global Settings", nil, 2, odb, "UseGlobalSettings", nil, ApplySettings, nil, function() return (not odb.Enable) end),
		ForcingGlobal = {
			order = 3,
			width = "full",
			type = "description",
			name = "|cffff0000Global settings are being forced.|r",
			hidden = function() return not db.Fader.ForceGlobalSettings end,
		},
		Options = {
			name = "",
			type = "group",
			guiInline = true,
			disabled = function() return (not odb.Enable) or odb.UseGlobalSettings or db.Fader.ForceGlobalSettings end,
			order = 4,
			args = {
				FadeInHeader = LUI:NewHeader("Fade In", 2),
				Casting = LUI:NewToggle("Casting", nil, 3, odb, "Casting", nil, ApplySettings, "normal"),
				InCombat = LUI:NewToggle("In Combat", nil, 4, odb, "Combat", nil, ApplySettings, "normal"),
				Health = LUI:NewToggle("Health Is Low", nil, 5, odb, "Health", nil, ApplySettings, "normal"),
				Power = LUI:NewToggle("Power Is Low", nil, 6, odb, "Power", nil, ApplySettings, "normal"),
				Targeting = LUI:NewToggle("Targeting", nil, 7, odb, "Targeting", nil, ApplySettings, "full"),
				
				Settings = LUI:NewHeader("Settings", 8),
				InAlpha = LUI:NewSlider("In Alpha", "Set the alpha of the frame while not faded.", 9, odb, "InAlpha", odbD, 0, 1, 0.05, ApplySettings, "normal", nil, nil, true),
				OutAlpha = LUI:NewSlider("Out Alpha", "Set the alpha of the frame while faded.", 10, odb, "OutAlpha", odbD, 0, 1, 0.05, ApplySettings, "normal", nil, nil, true),
				OutTime = LUI:NewSlider("Fade Time", "Set the time it takes to fade out.", 11, odb, "OutTime", odbD, 0, 5, 0.05, ApplySettings, "normal"),
				OutDelay = LUI:NewSlider("Fade Delay", "Set the delay time before the frame fades out.", 12, odb, "OutDelay", odbD, 0, 5, 0.05, ApplySettings, "normal"),
				HealthClip = LUI:NewSlider("Health Trigger", "Set the percent at which health is considered low.", 13, odb, "HealthClip", odbD, 0, 1, 0.05, ApplySettings, "normal", nil, nil, true),
				PowerClip = LUI:NewSlider("Power Trigger", "Set the percent at which power is considered low.", 14, odb, "PowerClip", odbD, 0, 1, 0.05, ApplySettings, "normal", nil, nil, true),
				
				Hover = LUI:NewHeader("Mouse Hover", 15),
				HoverEnable = LUI:NewToggle("Fade On Mouse Hover", nil, 16, odb, "Hover", nil, ApplySettings, "normal"),
				HoverAlpha = LUI:NewSlider("Hover Alpha", "Set the alpha of the frame while the mouse is hovering over it.", 17, odb, "HoverAlpha", odbD, 0, 1, 0.05, ApplySettings, "normal", nil, nil, true),
			},
		},
	}
	
	return FaderOptions
end

-- default variables
local defaults = {
	Fader = {
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

function Fader:LoadOptions()
	local ApplySettings = function()
		if not Fader.RegisteredFrames then return end
		if db.Fader.ForceGlobalSettings then
			-- Re-apply settings to frames.
			for frame in pairs(Fader.RegisteredFrames) do
				Fader:RegisterFrame(frame)
			end
		else
			-- Re-apply settings to frames.
			for frame, settings in pairs(Fader.RegisteredFrames) do
				Fader:RegisterFrame(frame, settings)
			end																		
		end
	end
	
	-- db quick locals
	local gs = db.Fader.GlobalSettings
	local gsD = LUI.defaults.profile.Fader.GlobalSettings
	
	local options = {
		Fader = {
			name = "Fader",
			type = "group",
			childGroups = "tab",
			order = 70,
			disabled = function() return not db.Fader.Enable end,
			args = {
				Header = LUI:NewHeader("Fader", 1),
				Settings = {
					name = "Settings",
					type = "group",
					order = 2,
					args = {
						Enable = LUI:NewEnable("Fader", 1, db.Fader),
						ForceGlobalSettings = LUI:NewToggle("Force Global Settings", nil, 2, db.Fader, "ForceGlobalSettings", nil,
							function()
								if not Fader.RegisteredFrames then return end
								if db.Fader.ForceGlobalSettings then
									-- Re-apply settings to frames.
									for frame in pairs(Fader.RegisteredFrames) do
										Fader:RegisterFrame(frame)
									end
								else
									-- Need to reload to gather frames personal settings.
									StaticPopup_Show("RELOAD_UI")																		
								end
							end),
						Line = LUI:NewHeader("", 3),
					},					
				},
				GlobalSettings = {
					name = "Global Settings",
					type = "group",
					order = 3,
					args = {
						FadeInHeader = LUI:NewHeader("Fade In", 1),
						Casting = LUI:NewToggle("While Casting", nil, 2, gs, "Casting", nil, ApplySettings, "normal"),
						InCombat = LUI:NewToggle("While In Combat", nil, 3, gs, "Combat", nil, ApplySettings, "normal"),
						Health = LUI:NewToggle("While Health Is Low", nil, 4, gs, "Health", nil, ApplySettings, "normal"),
						Power = LUI:NewToggle("While Power Is Low", nil, 5, gs, "Power", nil, ApplySettings, "normal"),
						Targeting = LUI:NewToggle("While Targeting", nil, 6, gs, "Targeting", nil, ApplySettings, "full"),
						
						Settings = LUI:NewHeader("Settings", 7),
						InAlpha = LUI:NewSlider("In Alpha", "Set the alpha of the frame while not faded.", 8, gs, "InAlpha", gsD, 0, 1, 0.05, ApplySettings, "normal", nil, nil, true),
						OutAlpha = LUI:NewSlider("Out Alpha", "Set the alpha of the frame while faded.", 9, gs, "OutAlpha", gsD, 0, 1, 0.05, ApplySettings, "normal", nil, nil, true),
						OutTime = LUI:NewSlider("Fade Time", "Set the time it takes to fade out.", 10, gs, "OutTime", gsD, 0, 5, 0.05, ApplySettings, "normal"),
						OutDelay = LUI:NewSlider("Fade Delay", "Set the delay time before the frame fades out.", 11, gs, "OutDelay", gsD, 0, 5, 0.05, ApplySettings, "normal"),
						HealthClip = LUI:NewSlider("Health Trigger", "Set the percent at which health is considered low.", 12, gs, "HealthClip", gsD, 0, 1, 0.05, ApplySettings, "normal", nil, nil, true),
						PowerClip = LUI:NewSlider("Power Trigger", "Set the percent at which power is considered low.", 13, gs, "PowerClip", gsD, 0, 1, 0.05, ApplySettings, "normal", nil, nil, true),
						
						Hover = LUI:NewHeader("Mouse Hover", 14),
						HoverEnable = LUI:NewToggle("Fade On Mouse Hover", nil, 15, gs, "Hover", nil, ApplySettings, "normal"),
						HoverAlpha = LUI:NewSlider("Hover Alpha", "Set the alpha of the frame while the mouse is hovering over it.", 16, gs, "HoverAlpha", gsD, 0, 1, 0.05, ApplySettings, "normal", nil, nil, true),																								
					},
				},
			},
		},
	}
	return options
end

function Fader:OnInitialize()
	LUI:MergeDefaults(LUI.db.defaults.profile, defaults)
	LUI:RefreshDefaults()
	LUI:Refresh()
	
	self.db = LUI.db.profile
	db = self.db
	
	LUI:RegisterModule(self)
end

function Fader:OnEnable()
	-- check if enabled.
	if not db.Fader.Enable then return end
	
	-- check if events need to be registered
	if self.RegisteredFrames then
		self:EventsRegister()
		
		-- apply hover scripts
		for frame in pairs(self.RegisteredFrames) do
			self:AttachHoverScript(frame)
		end
	end
end

function Fader:OnDisable()
	-- check if events need to be un-registered
	if self.RegisteredFrames then
		self:EventsUnregister()
		
		-- remove hover scripts
		for frame in pairs(self.RegisteredFrames) do
			self:RemoveHoverScript(frame)
		end
	end
end