--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: fader.lua
	Description: This module can handle fading of frames registered with it.
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
			Turning off force global settings from the global fader menu.

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

-- External references.
local addonname, LUI = ...
local Fader = LUI:Module("Fader", "AceEvent-3.0", "AceHook-3.0", "AceTimer-3.0")
local Media = LibStub("LibSharedMedia-3.0")
local Profiler = LUI.Profiler
local widgetLists = AceGUIWidgetLSMlists

-- Database and defaults shortcuts.
local db, dbd

-- Fader local variables.
-- RegisteredFrames[frame] = frameSettings. (e.i. RegisteredFrames = { oUF_LUI_player = db.oUF.Player.Fader, oUF_LUI_target = db.oUF.Target.Fader, etc })
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

-- Fader:RegisterFrame(frame, settings[, specialHover])
--[[
	Notes.....: registers a given frame to the fader logic.
	Parameters:
		frame: Frame to be registered to the fader.
		settings: Settings for the frame.
		specialHover: Adds special mouse hover script setups for frames with children.
]]
function Fader:RegisterFrame(frame, settings, specialHover)
	-- Check frame is a usable objects.
	if type(frame) ~= "table"  then return end

	-- Apply settings
	if not settings then settings = db.GlobalSettings end
	local usedSettings
	if db.ForceGlobalSettings then
		usedSettings = db.GlobalSettings
	else
		usedSettings = (settings.UseGlobalSettings and db.GlobalSettings) or settings
	end

	-- Check if registered frames table exists.
	if not self.RegisteredFrames then
		self.RegisteredFrames = {}
		self.RegisteredFrames[frame] = usedSettings
		self.RegisteredFrameTotal = 1
		if db.Enable then self:EventsRegister() end
	else
		-- Check if frame is already registered.
		if self.RegisteredFrames[frame] then
			-- Update frame's settings.
			self.RegisteredFrames[frame] = usedSettings
		else
			-- Register frame and settings.
			self.RegisteredFrames[frame] = usedSettings
			self.RegisteredFrameTotal = self.RegisteredFrameTotal + 1
		end
	end

	-- Create indexer for special frames.
	frame.FaderSpecialHover = specialHover

	-- Check fader is enabled.
	if not db.Enable then return end

	-- Create fader table.
	frame.Fader = frame.Fader or {}
	frame.Fader.PreAlpha = frame.Fader.PreAlpha or frame:GetAlpha()

	-- Attach mouseover scripts to frame.
	self:AttachHoverScript(frame)

	-- Run fader
	self:FadeHandler(frame)
end

-- Fader:UnregisterFrame(frame)
--[[
	Notes.....: Unregisters a given frame from the fader logic.
	Parameters:
		frame: Frame to be unregistered from the fader.
]]
function Fader:UnregisterFrame(frame)
	-- Check frame is a usable object.
	if type(frame) ~= "table" then return end

	-- Check if registered frames table exists.
	if not self.RegisteredFrames then return end

	-- Check if frame is registered.
	if not self.RegisteredFrames[frame] then return end

	-- Remove frame.
	self.RegisteredFrames[frame] = nil
	self.RegisteredFrameTotal = self.RegisteredFrameTotal - 1

	-- Remove hooks.
	self:RemoveHoverScript(frame)

	-- Remove indexer for special frames.
	frame.FaderSpecialHover = nil

	-- Reset alpha.
	frame:SetAlpha((frame.Fader and frame.Fader.PreAlpha) or 1)

	-- If currently fading, stop fading.
	if frame.Fader and frame.Fader.fading then
		self:StopFading(frame)
	end

	-- Remove variables.
	frame.Fader = nil

	-- Check if there are any registered frames left.
	if self.RegisteredFrameTotal == 0 then
		self.RegisteredFrames = nil
		self:EventsUnregister()
	end
end

------------------------------------------------------
-- / Fader Mouse Hover Scripts / --
------------------------------------------------------

-- Fader.Hover_OnEnter(frame)
--[[
	Notes.....: Fades the frame when the mouse enters the frame.
]]
function Fader.Hover_OnEnter(frame)
	-- Set mouse hover.
	frame.Fader.mouseHover = true

	-- Check if already fading in.
	if frame.Fader.fading and frame.Fader.endAlpha >= Fader.RegisteredFrames[frame].HoverAlpha then return end

	-- Cancel any fading.
	Fader:StopFading(frame)

	-- Check if fade is required.
	if frame:GetAlpha() >= Fader.RegisteredFrames[frame].HoverAlpha then return end

	-- Fade in frame.
	Fader:FadeFrame(frame, Fader.RegisteredFrames[frame].HoverAlpha)
end

-- Fader.Hover_OnLeave(frame)
--[[
	Notes.....: Fades out the frame when the mouse leaves the frame.
]]
function Fader.Hover_OnLeave(frame)
	-- Set mouse hover.
	frame.Fader.mouseHover = false

	-- Check if already fading out.
	if frame.Fader.fading and not frame.Fader.fadingIn then return end

	-- Fade out frame.
	Fader:FadeFrame(frame,	Fader.RegisteredFrames[frame].OutAlpha,
							Fader.RegisteredFrames[frame].OutTime,
							Fader.RegisteredFrames[frame].OutDelay)
	Fader:FadeHandler(frame)
end

--[=[
-- Fader.SpecialHover_OnEnter(frame) -- not being used
--[[
	Notes.....: Fades the frame when the mouse enters the frame or any child of the frame.
]]
function Fader.SpecialHover_OnEnter(frame)
	frame = frame.Fader and frame or frame:GetParent()

	if not frame.Fader.mouseHover then
		Fader.Hover_OnEnter(frame)
	end
end

-- Fader.SpecialHover_OnLeave(frame) -- not being used
--[[
	Notes.....: Fades out the frame when the mouse leaves the frame or any child of the frame.
]]
function Fader.SpecialHover_OnLeave(frame)
	frame = frame.Fader and frame or frame:GetParent()

	if not frame:IsMouseOver() then
		Fader.Hover_OnLeave(frame)
	end
end
--]=]

-- Fader:CheckMouseHover()
--[[
	Notes.....: Checks special frames to see if the mouseover of that frame has changed.
]]
function Fader:CheckMouseHover()
	for frame, mouseHover in pairs(self.specialHoverFrames) do
		local isMouseOver = frame:IsMouseOver()
		if isMouseOver ~= mouseHover then
			self.specialHoverFrames[frame] = isMouseOver
			if isMouseOver then
				self.Hover_OnEnter(frame)
			else
				self.Hover_OnLeave(frame)
			end
		end
	end
end

-- Fader:AttachHoverScript(frame)
--[[
	Notes.....: Registers a mouseover script to a given frame if needed.
	Parameters:
		frame: Frame to be given hover scripts.
]]
function Fader:AttachHoverScript(frame)
	-- Check settings.
	if not self.RegisteredFrames[frame].Hover then
		-- Unhook if scripts are hooked.
		self:RemoveHoverScript(frame)
		return
	end

	-- Check is special scripts are needed.
	if frame.FaderSpecialHover then
		return self:AttachSpecialHoverScript(frame)
	end

	-- Hook scripts.
	if not self:IsHooked(frame, "OnEnter") then self:SecureHookScript(frame, "OnEnter", Fader.Hover_OnEnter) end
	if not self:IsHooked(frame, "OnLeave") then self:SecureHookScript(frame, "OnLeave", Fader.Hover_OnLeave) end

	-- Run leave script.
	frame:GetScript("OnLeave")(frame)
end

-- Fader:AttachSpecialHoverScript(frame)
--[[
	Notes.....: Registers a mouseover script to a given frame that has children if needed.
	Parameters:
		frame: Frame to be given hover scripts.
]]
function Fader:AttachSpecialHoverScript(frame)
	-- Create timer and specialHoverFrames table if they doesn't exist.
	if not self.timerHandle then
		self.specialHoverFrames = {}
		self.timerHandle = self:ScheduleRepeatingTimer("CheckMouseHover", 0.1)
	end

	if not self.specialHoverFrames[frame] then
		self.specialHoverFrames[frame] = false
	end
end

-- Fader:RemoveHoverScript(frame)
--[[
	Notes.....: Unregisters the mouseover script from the given frame.
	Parameters:
		frame: Frame to remove hover scripts from.
]]
function Fader:RemoveHoverScript(frame)
	if self.specialHoverFrames and (self.specialHoverFrames[frame] ~= nil) then
		self.specialHoverFrames[frame] = nil
		if not next(self.specialHoverFrames) then
			self:CancelTimer(self.timerHandle)
			self.timerHandle = nil
		end
	else
		-- Unhook scripts
		self:Unhook(frame, "OnEnter")
		self:Unhook(frame, "OnLeave")
	end
end

--	Fader:CreateHoverScripts(frame[, inAlpha[, outAlpha[, fadeTime[, fadeDelay[, children]]]]])
--[[
	Notes.....: Creates mousehover scripts for a frame that does not need other fader features.
	Parameters:
		frame: The frame to create hover scripts for.
		inAlpha: The alpha to be set when the frame is being hovered over.
		outAlpha: The alpha to be set when the frame is not being hovered over.
		fadeTime: The time period to fade out over.
		fadeDelay: The time period before fading out.
		children: To attach scripts to child frames; much like SpecialHoverScripts.
]]
function Fader:CreateHoverScript(frame, inAlpha, outAlpha, fadeTime, fadeDelay, children)
	-- Check frame is a usable objects.
	if type(frame) ~= "table"  then return end

	-- Set defaults.
	inAlpha = inAlpha or 1

	-- Create upvalues.
	local mouseHover = false

	-- Create Fader table for frame if it doesn't exist.
	frame.Fader = frame.Fader or {}
	frame.FaderHoverScript = true

	-- Create OnEnter/OnLeave functions.
	local function OnEnter()
		-- Check if mouseHover is already detected.
		if mouseHover then return end

		-- Set mouse hover.
		mouseHover = true

		-- Check if already fading in.
		if frame.Fader.fading and frame.Fader.endAlpha >= inAlpha then return end

		-- Cancel any fading.
		self:StopFading(frame)

		-- Check if fade is required.
		if frame:GetAlpha() >= inAlpha then return end

		-- Fade in frame.
		self:FadeFrame(frame, inAlpha)
	end

	local function OnLeave()
		-- Check if mouse is over.
		if frame:IsMouseOver() then return end

		-- Set mouse hover.
		mouseHover = false

		-- Check if already fading out.
		if frame.Fader.fading and not frame.Fader.fadingIn then return end

		-- Fade out frame.
		self:FadeFrame(frame, outAlpha, fadeTime, fadeDelay)
	end

	if not children then
		-- Hook scripts.
		if not self:IsHooked(frame, "OnEnter") then self:SecureHookScript(frame, "OnEnter", OnEnter) end
		if not self:IsHooked(frame, "OnLeave") then self:SecureHookScript(frame, "OnLeave", OnLeave) end
	else
		local function CheckMouseHover()
			if not frame:IsVisible() then return end

			local isMouseOver = frame:IsMouseOver()
			if isMouseOver ~= mouseHover then
				if isMouseOver then
					OnEnter()
				else
					OnLeave()
				end
			end
		end

		-- Create AceTimer.
		frame.Fader.timerHandle = self:ScheduleRepeatingTimer(CheckMouseHover, 0.1)
	end
end

--	Fader:DeleteHoverScript(frame[, children])
--[[
	Notes.....: Deletes mousehover scripts for a frame that has had hover scripts created for it.
	Parameters:
		frame: The frame to delete hover scripts from.
		children: To delete scripts from child frames; much like SpecialHoverScripts.
]]
function Fader:DeleteHoverScript(frame, children)
	-- Check frame is a usable objects.
	if type(frame) ~= "table"  then return end

	if not children then
		-- Unhook scripts.
		self:Unhook(frame, "OnEnter")
		self:Unhook(frame, "OnLeave")
	else
		if frame.Fader then
			self:CancelTimer(frame.Fader.timerHandle, true)
			frame.Fader.timerHandle = nil
		end
	end

	-- Clean up variables.
	frame.Fader = nil
	frame.FaderHoverScript = nil
end

------------------------------------------------------
-- / Fade / Event Handlers / --
------------------------------------------------------

-- Fader:EventsRegister()
--[[
	Notes.....: Register all the event triggers for the fader.
]]
function Fader:EventsRegister()
	-- Register event triggers
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "EventHandler")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "EventHandler")
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "EventHandler")
	self:RegisterEvent("UNIT_HEALTH", "UnitEventHandler")
	self:RegisterEvent("UNIT_POWER_UPDATE", "UnitEventHandler")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", "UnitEventHandler")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", "UnitEventHandler")
	self:RegisterEvent("UNIT_SPELLCAST_START", "UnitEventHandler")
	self:RegisterEvent("UNIT_SPELLCAST_STOP", "UnitEventHandler")
end

-- Fader:EventsUnregister()
--[[
	Notes.....: Unregister all the event triggers for the fader.
]]
function Fader:EventsUnregister()
	-- Unregister event triggers
	self:UnregisterEvent("PLAYER_REGEN_DISABLED")
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:UnregisterEvent("PLAYER_TARGET_CHANGED")
	self:UnregisterEvent("UNIT_HEALTH")
	self:UnregisterEvent("UNIT_POWER_UPDATE")
	self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
	self:UnregisterEvent("UNIT_SPELLCAST_START")
	self:UnregisterEvent("UNIT_SPELLCAST_STOP")
end

-- Fader:EventHandler()
--[[
	Notes.....: Handles a passed event, checks frame fade triggers.
]]
function Fader:EventHandler(event)
	-- Collect info on states.
	if event == "PLAYER_REGEN_DISABLED" then
		self.Status.combat = true
	elseif event == "PLAYER_REGEN_ENABLED" then
		self.Status.combat = false
	elseif event == "PLAYER_TARGET_CHANGED" then
		self.Status.targeting = UnitExists("target")
	end

	-- And now the expensive bit
	for frame in pairs(self.RegisteredFrames) do
		self:FadeHandler(frame)
	end
end

-- Fader:UnitEventHandler(eventname, unit)
--[[
	Notes.....: Handles a passed event that recieves a unit parameter and checks if it is the player unit.
	Parameters:
		eventname: Name of the event passed.
		unit: arg1, or unitid for UNIT_* events.
]]
function Fader:UnitEventHandler(event, unit)
	-- Check unit for player only.
	if unit ~= "player" then return end

	-- Collect info on states.
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

	-- And now the expensive bit.
	for frame in pairs(self.RegisteredFrames) do
		self:FadeHandler(frame)
	end
end

-- Fader:FadeHandler(frame)
--[[
	Notes.....: Handles fading of a frame using the options of that frame.
]]
function Fader:FadeHandler(frame)
	if frame.Fader.mouseHover then return end

	-- Local variables.
	local fadeIn = false

	-- Check states vs. settings.
	if self.Status.targeting and self.RegisteredFrames[frame].Targeting then
		fadeIn = true
	elseif self.Status.combat and self.RegisteredFrames[frame].Combat then
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

	-- Fade according to results.
	self:FadeOnEvent(frame, fadeIn)
end

-- Fader:FadeOnEvent(frame[, fadeIn])
--[[
	Notes.....: Fades a frame dependant on events.
	Parameters:
		frame: The frame to fade.
		fadeIn: If the frame is fading in.
]]
function Fader:FadeOnEvent(frame, fadeIn)
	if fadeIn then
		-- Check if already fading in.
		if frame.Fader.fading and frame.Fader.fadingIn then return end

		-- Check if fade is required.
		if frame:GetAlpha() >= self.RegisteredFrames[frame].InAlpha then self:StopFading(frame) return end

		-- Set to fade in.
		self:FadeFrame(frame, self.RegisteredFrames[frame].InAlpha)
	else
		-- Check if frame is fadingIn or for mouse hover.
		if frame.Fader.mouseHover or (frame.Fader.fading and not frame.Fader.fadingIn) then return end

		-- Check if fade is required.
		if frame:GetAlpha() <= self.RegisteredFrames[frame].OutAlpha then return end

		-- Set to fade out.
		self:FadeFrame(frame,	self.RegisteredFrames[frame].OutAlpha,
								self.RegisteredFrames[frame].OutTime,
								self.RegisteredFrames[frame].OutDelay)
	end
end

------------------------------------------------------
-- / Frame Fader / --
------------------------------------------------------

-- Fader.Fade_OnUpdate(self, elapsed)
--[[
	Notes.....: Fades running frames over time.
]]
function Fader.Fader_OnUpdate(self, elapsed)
	-- Check fader throttle.
	self.Throttle = self.Throttle + elapsed
	if self.Throttle < 0.05 then return end
	elapsed = self.Throttle
	self.Throttle = 0

	-- Check if there are frames to fade.
	if #Fader.Fading == 0 then self:SetScript("OnUpdate", nil) return end

	-- Loop through frames and fade.
	for i, frame in ipairs(Fader.Fading) do
		-- Manage delay before fading.
		if frame.Fader.fadeDelay > 0 then
			frame.Fader.fadeDelay = frame.Fader.fadeDelay - elapsed
		else
			-- Manage fading.
			frame.Fader.timeElapsed = frame.Fader.timeElapsed + elapsed
			if frame.Fader.timeElapsed < frame.Fader.fadeTime then
				frame:SetAlpha(frame.Fader.startAlpha + (frame.Fader.deltaAlpha * frame.Fader.timeElapsed / frame.Fader.fadeTime))
			else
				-- Cleanup
				frame:SetAlpha(frame.Fader.endAlpha)
				Fader:StopFading(frame)
			end
		end
	end
end

-- Fader:FadeFrame(frame[, endalpha[, fadetime[, fadedelay])
--[[
	Notes.....: Takes a frame and fades it with the given parameters.
	Parameters:
		frame: Frame to fade.
		endAlpha: Alpha value to fade to.
		fadeTime: Time (seconds) to fade over.
		fadeDelay: Delay (seconds) before fading.
		callBack: Function to call upon finishing the fade.
]]
function Fader:FadeFrame(frame, endAlpha, fadeTime, fadeDelay, callBack)
	-- Check frame is a usable object.
	if type(frame) ~= "table" then return end

	-- Check if fading is needed.
	if frame:GetAlpha() == (endAlpha or 0) then
		-- Stop fading.
		self:StopFading(frame)
		return
	end

	-- Setup fader settings.
	-- Settings equal optional parameters or defaults.
	frame.Fader = frame.Fader or {}
	frame.Fader.startAlpha = (not frame:IsShown() and 0) or frame:GetAlpha()
	frame.Fader.endAlpha = endAlpha or 0
	frame.Fader.deltaAlpha = frame.Fader.endAlpha - frame.Fader.startAlpha
	frame.Fader.fadingIn = frame.Fader.endAlpha > frame.Fader.startAlpha
	frame.Fader.fadeTime = fadeTime or 0.2
	frame.Fader.timeElapsed = 0
	frame.Fader.fadeDelay = fadeDelay or 0
	frame.Fader.callBack = (type(callBack) == "function" and callBack) or nil

	-- Start fading frame.
	self:StartFading(frame)
end

-- Fader:StartFading(frame)
--[[
	Notes.....: Adds a frame to the fading table.
]]
function Fader:StartFading(frame)
	-- Check frame isn't already fading.
	if frame.Fader.fading then return end

	-- Check if OnUpdate script needs to be applied.
	if #self.Fading == 0 then
		self.Fader:SetScript("OnUpdate", self.Fader_OnUpdate)
		self.Fader.Throttle = 0
	end

	-- Add frame to fading table.
	frame.Fader.fading = true
	tinsert(self.Fading, frame)
end

-- Fader:StopFading(frame)
--[[
	Notes.....: Removes a frame to the fading table.
]]
function Fader:StopFading(frame)
	-- Find and remove frame.
	for i, v in ipairs(self.Fading) do
		if v == frame then
			frame.Fader.fading = false
			tremove(self.Fading, i)

			if frame.Fader.callBack then
				frame.Fader.callBack()
				frame.Fader.callBack = nil
			end

			if not frame.FaderHoverScript and not self.RegisteredFrames[frame] then frame.Fader = nil end
			return
		end
	end
end


---[[	PROFILER
-- Add Fader functions to the profiler.
Profiler.TraceScope(Fader, "Fader", "LUI")
--]]


------------------------------------------------------
-- / Module Settings / --
------------------------------------------------------

function Fader:CreateFaderOptions(object, objectDB, objectDBdefaults, specialHover)
	local frame
	if type(object) == "table" and not object.GetParent then
		frame = {}

		local numObjects = 0
		for k, f in pairs(object) do
			frame[k] = f
			numObjects = numObjects + 1
		end

		-- Check there are frames to be used.
		if numObjects == 0 then return end
	else
		frame = object
	end

	-- Check frame is an usable object.
	if (type(frame) ~= "table") and (type(frame) ~= "string") then return end

	-- Shortcut database values.
	local odb = objectDB
	local odbD = objectDBdefaults

	-- Create ApplySettings function.
	local ApplySettings
	if type(frame) == "table" and not frame.GetParent then
		-- Check if objects are for oUF_Party.
		local oUF_Party
		for _, f in pairs(frame) do
			if type(f) == "string" then
				if _G[f] and strfind(_G[f]:GetName(), "oUF_LUI_party") then
					oUF_Party = LUI:Module("oUF_Party")
					break
				end
			else
				if strfind(f:GetName(), "oUF_LUI_party") then
					oUF_Party = LUI:Module("oUF_Party")
					break
				end
			end
		end

		ApplySettings = function()
			if odb.Enable then
				-- Disable Range Fader for Party
				if oUF_Party then oUF_Party:ToggleRangeFade(false) end

				for _, f in pairs(frame) do
					if type(f) == "string" then
						if _G[f] then Fader:RegisterFrame(_G[f], odb, specialHover) end
					else
						Fader:RegisterFrame(f, odb, specialHover)
					end
				end
			else
				for _, f in pairs(frame) do
					if type(f) == "string" then
						if _G[f] then Fader:UnregisterFrame(_G[f]) end
					else
						Fader:UnregisterFrame(f)
					end
				end

				-- Set Range Fader for Party to correct state
				if oUF_Party then oUF_Party:ToggleRangeFade() end
			end
		end
	else
		ApplySettings = function()
			if odb.Enable then
				if type(frame) == "string" then
					if _G[frame] then Fader:RegisterFrame(_G[frame], odb, specialHover) end
				else
					Fader:RegisterFrame(frame, odb, specialHover)
				end
			else
				if type(frame) == "string" then
					if _G[frame] then Fader:UnregisterFrame(_G[frame]) end
				else
					Fader:UnregisterFrame(frame)
				end
			end
		end
	end

	local FaderOptions = {
		Enable = LUI:NewToggle("Enable Fader", nil, 1, odb, "Enable", odbD, ApplySettings),
		UseGlobalSettings = LUI:NewToggle("Use Global Settings", nil, 2, odb, "UseGlobalSettings", odbD, ApplySettings, nil, function() return (not odb.Enable) end),
		ForcingGlobal = LUI:NewDesc("|cffff0000Global settings are being forced.|r", 3, nil, nil, function() return not db.ForceGlobalSettings end),
		Options = {
			name = "",
			type = "group",
			guiInline = true,
			disabled = function() return (not odb.Enable) or odb.UseGlobalSettings or db.ForceGlobalSettings end,
			order = 4,
			args = {
				FadeInHeader = LUI:NewHeader("Fade In", 2),
				Casting = LUI:NewToggle("Casting", nil, 3, odb, "Casting", odbD, ApplySettings, "normal"),
				InCombat = LUI:NewToggle("In Combat", nil, 4, odb, "Combat", odbD, ApplySettings, "normal"),
				Health = LUI:NewToggle("Health Is Low", nil, 5, odb, "Health", odbD, ApplySettings, "normal"),
				Power = LUI:NewToggle("Power Is Low", nil, 6, odb, "Power", odbD, ApplySettings, "normal"),
				Targeting = LUI:NewToggle("Targeting", nil, 7, odb, "Targeting", odbD, ApplySettings, "full"),

				Settings = LUI:NewHeader("Settings", 8),
				InAlpha = LUI:NewSlider("In Alpha", "Set the alpha of the frame while not faded.", 9, odb, "InAlpha", odbD, 0, 1, 0.05, ApplySettings, "normal", nil, nil, true),
				OutAlpha = LUI:NewSlider("Out Alpha", "Set the alpha of the frame while faded.", 10, odb, "OutAlpha", odbD, 0, 1, 0.05, ApplySettings, "normal", nil, nil, true),
				OutTime = LUI:NewSlider("Fade Time", "Set the time it takes to fade out.", 11, odb, "OutTime", odbD, 0, 5, 0.05, ApplySettings, "normal"),
				OutDelay = LUI:NewSlider("Fade Delay", "Set the delay time before the frame fades out.", 12, odb, "OutDelay", odbD, 0, 5, 0.05, ApplySettings, "normal"),
				HealthClip = LUI:NewSlider("Health Trigger", "Set the percent at which health is considered low.", 13, odb, "HealthClip", odbD, 0, 1, 0.05, ApplySettings, "normal", nil, nil, true),
				PowerClip = LUI:NewSlider("Power Trigger", "Set the percent at which power is considered low.", 14, odb, "PowerClip", odbD, 0, 1, 0.05, ApplySettings, "normal", nil, nil, true),

				Hover = LUI:NewHeader("Mouse Hover", 15),
				HoverEnable = LUI:NewToggle("Fade On Mouse Hover", nil, 16, odb, "Hover", odbD, ApplySettings, "normal"),
				HoverAlpha = LUI:NewSlider("Hover Alpha", "Set the alpha of the frame while the mouse is hovering over it.", 17, odb, "HoverAlpha", odbD, 0, 1, 0.05, ApplySettings, "normal", nil, nil, true),
			},
		},
	}

	return FaderOptions
end

-- Default variables
Fader.defaults = {
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

function Fader:LoadOptions()
	local ApplySettings = function()
		if not Fader.RegisteredFrames then return end
		if db.ForceGlobalSettings then
			-- Re-apply settings to frames.
			for frame in pairs(Fader.RegisteredFrames) do
				Fader:RegisterFrame(frame, nil, frame.FaderSpecialHover)
			end
		else
			-- Re-apply settings to frames.
			for frame, settings in pairs(Fader.RegisteredFrames) do
				Fader:RegisterFrame(frame, settings, frame.FaderSpecialHover)
			end
		end
	end

	-- db quick locals
	local gs = db.GlobalSettings
	local gsD = dbd.GlobalSettings

	local options = {
		Header = LUI:NewHeader("Fader", 1),
		Settings = {
			name = "Settings",
			type = "group",
			order = 2,
			args = {
				ForceGlobalSettings = LUI:NewToggle("Force Global Settings", nil, 1, db, "ForceGlobalSettings", dbd,
					function()
						if not Fader.RegisteredFrames then return end
						if db.ForceGlobalSettings then
							-- Re-apply settings to frames.
							for frame in pairs(Fader.RegisteredFrames) do
								Fader:RegisterFrame(frame, nil, frame.FaderSpecialHover)
							end
						else
							-- Need to reload to gather frames personal settings.
							StaticPopup_Show("RELOAD_UI")
						end
					end),
				Line = LUI:NewHeader("", 2),
			},
		},
		GlobalSettings = {
			name = "Global Settings",
			type = "group",
			order = 3,
			args = {
				FadeInHeader = LUI:NewHeader("Fade In", 1),
				Casting = LUI:NewToggle("While Casting", nil, 2, gs, "Casting", gsD, ApplySettings, "normal"),
				InCombat = LUI:NewToggle("While In Combat", nil, 3, gs, "Combat", gsD, ApplySettings, "normal"),
				Health = LUI:NewToggle("While Health Is Low", nil, 4, gs, "Health", gsD, ApplySettings, "normal"),
				Power = LUI:NewToggle("While Power Is Low", nil, 5, gs, "Power", gsD, ApplySettings, "normal"),
				Targeting = LUI:NewToggle("While Targeting", nil, 6, gs, "Targeting", gsD, ApplySettings, "full"),

				Settings = LUI:NewHeader("Settings", 7),
				InAlpha = LUI:NewSlider("In Alpha", "Set the alpha of the frame while not faded.", 8, gs, "InAlpha", gsD, 0, 1, 0.05, ApplySettings, "normal", nil, nil, true),
				OutAlpha = LUI:NewSlider("Out Alpha", "Set the alpha of the frame while faded.", 9, gs, "OutAlpha", gsD, 0, 1, 0.05, ApplySettings, "normal", nil, nil, true),
				OutTime = LUI:NewSlider("Fade Time", "Set the time it takes to fade out.", 10, gs, "OutTime", gsD, 0, 5, 0.05, ApplySettings, "normal"),
				OutDelay = LUI:NewSlider("Fade Delay", "Set the delay time before the frame fades out.", 11, gs, "OutDelay", gsD, 0, 5, 0.05, ApplySettings, "normal"),
				HealthClip = LUI:NewSlider("Health Trigger", "Set the percent at which health is considered low.", 12, gs, "HealthClip", gsD, 0, 1, 0.05, ApplySettings, "normal", nil, nil, true),
				PowerClip = LUI:NewSlider("Power Trigger", "Set the percent at which power is considered low.", 13, gs, "PowerClip", gsD, 0, 1, 0.05, ApplySettings, "normal", nil, nil, true),

				Hover = LUI:NewHeader("Mouse Hover", 14),
				HoverEnable = LUI:NewToggle("Fade On Mouse Hover", nil, 15, gs, "Hover", gsD, ApplySettings, "normal"),
				HoverAlpha = LUI:NewSlider("Hover Alpha", "Set the alpha of the frame while the mouse is hovering over it.", 16, gs, "HoverAlpha", gsD, 0, 1, 0.05, ApplySettings, "normal", nil, nil, true),
			},
		},
	}
	return options
end

function Fader:OnInitialize()
	db, dbd = LUI:NewNamespace(self, true)
end

function Fader:OnEnable()
	-- Check if events need to be registered
	if self.RegisteredFrames then
		self:EventsRegister()

		-- Enable fader on registered frames.
		for frame in pairs(self.RegisteredFrames) do
			-- Create fader table.
			frame.Fader = frame.Fader or {}
			frame.Fader.PreAlpha = frame.Fader.PreAlpha or frame:GetAlpha()

			-- Attach mouseover scripts to frame.
			self:AttachHoverScript(frame)

			-- Run fader
			self:FadeHandler(frame)
		end
	end
end

function Fader:OnDisable()
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
