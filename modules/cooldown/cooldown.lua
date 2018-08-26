--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: cooldown.lua
	Description: Cooldown Timer Module
]]

-- External references.
local addonname, LUI = ...
local module = LUI:Module("Cooldown", "AceEvent-3.0", "AceHook-3.0")
local Media = LibStub("LibSharedMedia-3.0")
local Profiler = LUI.Profiler

-- Database and defaults shortcuts.
local db, dbd

-- Localized API
local floor, format, tinsert, tremove = math.floor, string.format, table.insert, table.remove
local pairs, ipairs, next, wipe, GetTime = pairs, ipairs, next, wipe, GetTime

--------------------------------------------------
-- Local Variables
--------------------------------------------------

local timers = {}
local activeUICooldowns = {}

--------------------------------------------------
-- Hook Functions
--------------------------------------------------

local function actionUIButtonCD_OnShow(self)
	activeUICooldowns[self] = self:GetParent()
end

local function actionUIButtonCD_OnHide(self)
	activeUICooldowns[self] = nil
end

--------------------------------------------------
-- Cooldown Functions
--------------------------------------------------

local initTimer
do
	local day, hour, minute = 86400, 3600, 60
	local iconSize = 36
	local precision, threshold, minDuration, minToSec

	local cache = {}

	local colors = {}

	local timeFormats = {
		[day] = "%.0fd",
		[hour] = "%.0fh",
		[minute] = "%.0fm",
		[1] = "%.0f",
	}

	local fontScale = setmetatable({}, {
		__index = function(t, width)
			local scale = width / iconSize
			t[width] = scale > db.General.MinScale and scale * db.Text.Size

			return t[width]
		end
	})

	function module:UpdateVars()
		precision = 1 / 10^(db.General.Precision)
		threshold = db.General.Threshold
		minDuration = db.General.MinDuration
		minToSec = db.General.MinToSec

		wipe(fontScale)

		timeFormats[true] = format("%%.%df", db.General.Precision) -- threshold

		colors[day] = db.Colors.Day
		colors[hour] = db.Colors.Hour
		colors[minute] = db.Colors.Min
		colors[1] = db.Colors.Sec
		colors[true] = db.Colors.Threshold
	end


	local function round(num)
		return floor(num + 0.5)
	end


	local Timer = {}

	function Timer:Start(start, duration)
		self.start, self.duration, self.enabled = start, duration, true

		if not self:Scale() or not self:Update() then return end

		self:Show()
	end

	function Timer:Stop()
		self:Hide()

		self.enabled = nil
		self.cd.timer = nil
		self.fontScale = nil -- force update of fontsize on next use

		tinsert(cache, self)
	end

	function Timer:Update()
		local remaining = self.duration - (GetTime() - self.start)

		if remaining > 0 then
			self:FormatTime(remaining)
			return true
		end

		self:Stop()
	end

	function Timer:ShouldUpdate(start, duration)
		if start ~= self.start or duration ~= self.duration then
			if duration < minDuration or not self:IsVisible() then
				self:Stop()
				return
			end
		end

		return true
	end

	function Timer:OnUpdate(elapsed)
		self.nextUpdate = self.nextUpdate - elapsed

		if self.nextUpdate > 0 then return end

		self:Update()
	end

	function Timer:FormatTime(seconds)
		local factor
		if seconds < threshold then
			factor = true

			self.nextUpdate = precision
			self.text:SetFormattedText(timeFormats[factor], seconds)
		else
			factor = seconds < minToSec and 1 or seconds < hour and minute or seconds < day and hour or day

			self.nextUpdate = seconds % factor
			self.text:SetFormattedText(timeFormats[factor], seconds / factor)
		end

		if self.color ~= colors[factor] then
			self.color = colors[factor]
			self.text:SetTextColor(unpack(self.color))
		end
	end

	function Timer:Scale()
		local scale = fontScale[round(self.cd:GetWidth())]

		if self.fontScale ~= scale then
			self.fontScale = scale

			if not scale then
				self:Stop()
				return
			end

			self.text:SetFont(Media:Fetch("font", db.Text.Font), scale, db.Text.Flag)
		end

		return true
	end

	function Timer:Position()
		self:SetAllPoints()
		self.text:SetPoint(db.Text.Align, db.Text.XOffset, db.Text.YOffset)
	end


	local function getTimer(cd)
		local timer = tremove(cache)

		if timer then
			timer:SetParent(cd)
		else
			timer = setmetatable(CreateFrame("Frame", nil, cd, "LUI_Cooldown_Template"), Timer)
			timer:SetScript("OnUpdate", timer.OnUpdate)
			tinsert(timers, timer)
		end

		timer.cd = cd
		cd.timer = timer

		return timer
	end

	function module:AssignTimer(cd, start, duration)
		if cd.IsForbidden and cd:IsForbidden() then return end
		if cd.NextRewardLevel then return end -- Dont show cooldown on honor level.
		if cd.noCooldownCount then return end

		if cd.timer then
			if cd.timer:ShouldUpdate(start, duration) then
				cd.timer.start, cd.timer.duration = start, duration
				cd.timer:Update()
			end
		elseif duration >= minDuration and cd:IsVisible() and fontScale[round(cd:GetWidth())] then
			getTimer(cd):Start(start, duration)
		end
	end

	initTimer = function()
		if not Timer.__index then
			local timerFuncs = Timer

			Timer = {__index = CreateFrame("Frame")}

			for k, v in pairs(timerFuncs) do
				Timer.__index[k] = v
			end
		end

		module:SecureHook(getmetatable(ActionButton1Cooldown).__index, "SetCooldown", "AssignTimer")
	end
end


function module:RegisterActionUIButton(frame)
	local cd = frame.cooldown
	if not module:IsHooked(cd, "OnShow") then
		module:SecureHookScript(cd, "OnShow", actionUIButtonCD_OnShow)
		module:SecureHookScript(cd, "OnHide", actionUIButtonCD_OnHide)
	end
end


--------------------------------------------------
-- Event Functions
--------------------------------------------------


function module:ACTIONBAR_UPDATE_COOLDOWN()
	for cd, button in pairs(activeUICooldowns) do
		module:AssignTimer(cd, GetActionCooldown(button.action))
	end
end


--------------------------------------------------
-- Module Functions
--------------------------------------------------


module.defaults = {
	profile = {
		General = {
			MinDuration = 3,
			MinScale = 0.5,
			Precision = 1,
			Threshold = 8,
			MinToSec = 60,
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
			Day = {0.8, 0.8, 0.8},
			Hour = {0.8, 0.8, 1.0},
			Min = {1.0, 1.0, 1.0},
			Sec = {1.0, 1.0, 0.0},
			Threshold = {1.0, 0.0, 0.0},
		},
	},
}

module.conflicts = "OmniCC;tullaCooldownCount"

function module:LoadOptions()
	local func = "Refresh"
	
	local alignTable = {
		LEFT = "Left",
		CENTER = "Center",
		RIGHT = "Right",
	}
	
	local options = {
		General = self:NewGroup("General Settings", 1, {
			Threshold = self:NewInputNumber("Cooldown Threshold", "The time at which your coodown text is colored differnetly and begins using specified precision.", 1, func),
			MinDuration = self:NewInputNumber("Minimum Duration", "The lowest cooldown duration that timers will be shown for.", 2, func),
			Precision = self:NewSlider("Cooldown Precision", "How many decimal places will be shown once time is within the cooldown threshold.", 3, 0, 2, 1, func),
			MinScale = self:NewSlider("Minimum Scale", "The smallest size of icons that timers will be shown for.", 4, 0, 2, 0.1, func),
			MinToSec = self:NewSlider("Minute to Seconds", "The time at which your cooldown is shown in seconds instead of minutes.", 4, 60, 300, 60, func),
		}),
		Text = self:NewGroup("Text Settings", 2, {
			Font = self:NewSelect("Font", "Select the font to be used by cooldown's texts.", 1, AceGUIWidgetLSMlists.font, "LSM30_Font", func),
			Size = self:NewSlider("Font Size", "Select the font size to be used by cooldown's texts.", 2, 6, 32, 1, func),
			Flag = self:NewSelect("Font Outline", "Select the font outline to be used by cooldown's texts.", 3, LUI.FontFlags, false, func),
			Offsets = self:NewHeader("Text Position", 4),
			XOffset = self:NewInputNumber("X Offset", "Horizontal offset to be applied to the cooldown's texts.", 5, func),
			YOffset = self:NewInputNumber("Y Offset", "Vertical offset to be applied to the cooldown's texts.", 6, func),
			Align = self:NewSelect("Alignment", "Alignment to be applied to the cooldown's texts", 7, alignTable, false, func)
		}),
		Colors = self:NewGroup("Colors", 3, {
			Threshold = self:NewColorNoAlpha("Threshold", "The color of cooldown's text under the threshold.", 1, func),
			Sec = self:NewColorNoAlpha("Seconds", "The color of cooldown's text when representing seconds.", 2, func),
			Min = self:NewColorNoAlpha("Minutes", "The color of cooldown's text when representing minutes.", 3, func),
			Hour = self:NewColorNoAlpha("Hours", "The color of cooldown's text when representing hours.", 4, func),
			Day = self:NewColorNoAlpha("Days", "The color of cooldown's text when representing days.", 5, func),
		}),
	}
	return options
end

function module:Refresh()
	module:UpdateVars()

	for i, timer in ipairs(timers) do
		if timer.enabled then
			timer.fontScale = nil -- force update
			if timer:Scale() then
				timer:Position()
			end
		end
	end
end

function module:DBCallback(event, dbobj, profile)
	module:OnInitialize()

	module:Refresh()
end

function module:OnInitialize()
	db, dbd = LUI:Namespace(self, true)
end

function module:OnEnable()
	module:UpdateVars()

	initTimer()

	-- Register frames handled by SetActionUIButton
	if ActionBarButtonEventsFrame.frames then
		for i, frame in pairs(ActionBarButtonEventsFrame.frames) do
			module:RegisterActionUIButton(frame)
		end
	end
	module:SecureHook("ActionBarButtonEventsFrame_RegisterFrame", "RegisterActionUIButton")
	module:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
end

function module:OnDisable()
	module:UnhookAll()
	module:UnregisterAllEvents()

	for i, timer in ipairs(timers) do
		if timer.enabled then
			timer:Stop()
		end
	end
end
