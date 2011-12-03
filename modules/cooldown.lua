--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: cooldown.lua
	Description: Actionbar Cooldown Module
]] 

-- External references.
local addonname, LUI = ...
local module = LUI:Module("Cooldown", "AceEvent-3.0", "AceHook-3.0")
local Media = LibStub("LibSharedMedia-3.0")
local Profiler = LUI.Profiler

-- Database and defaults shortcuts.
local db, dbd

-- Localized API
local ceil, floor, min, format = math.ceil, math.floor, math.min, string.format
local pairs, ipairs, tinsert, tremove, next, wipe = pairs, ipairs, table.insert, table.remove, next, wipe
local GetTime = GetTime

--------------------------------------------------
-- Local Variables
--------------------------------------------------

local day, hour, minute = 86400, 3600, 60
local iconSize = 1 / 36
local precision, threshold, minDuration

local timers, cache = {}, {}
local activeUICooldowns = {}

local fontScale = setmetatable({}, {
	__index = function(t, width)
		local scale = width * iconSize
		t[width] = scale > db.General.MinScale and scale * db.Text.Size

		return t[width]
	end
})

--------------------------------------------------
-- Local Functions
--------------------------------------------------

local function round(num)
	return floor(num + 0.5)
end

local formatTime, setPrecision
do
	local timeFormats = {
		Day = "%.0fd",
		Hour = "%.0fh",
		Min = "%.0fm",
		Sec = "%.0f",
	}

	local precisions = {
		[0] = 1,
		[1] = 0.1,
		[2] = 0.01,
	}

	setPrecision = function()
		timeFormats.Threshold = format("%%.%df", db.General.Precision)
		precision = precisions[db.General.Precision]
		threshold = db.General.Threshold
		minDuration = db.General.MinDuration
	end

	formatTime = function(seconds)
		if seconds < threshold then
			return timeFormats.Threshold, seconds, precision, db.Colors.Threshold
		elseif seconds > day then
			return timeFormats.Day, seconds / day, seconds % day, db.Colors.Day
		elseif seconds > hour then
			return timeFormats.Hour, seconds / hour, seconds % hour, db.Colors.Hour
		elseif seconds > minute then
			return timeFormats.Min, seconds / minute, seconds % minute, db.Colors.Min
		else
			return timeFormats.Sec, seconds, seconds % 1, db.Colors.Sec
		end
	end
end

local getTimer
do
	local function updater_OnFinished(self)
		module.UpdateTimer(self.timer)
	end

	getTimer = function(cd)
		local timer = tremove(cache)

		if not timer then
			timer = CreateFrame("Frame")
			timer:Hide()

			local updater = timer:CreateAnimationGroup()
			updater.timer = timer
			updater:SetLooping("NONE")
			updater:SetScript("OnFinished", updater_OnFinished)

			local animation = updater:CreateAnimation("Animation")
			animation:SetOrder(1)

			timer.updater = updater

			local text = timer:CreateFontString(nil, "OVERLAY")

			text:SetJustifyH("CENTER")
			text:SetShadowColor(0, 0, 0, 0.5)
			text:SetShadowOffset(2, -2)

			timer.text = text

			tinsert(timers, timer)
		end

		timer.cd = cd

		timer:SetParent(cd)
		timer:SetFrameStrata(cd:GetFrameStrata())
		timer:SetFrameLevel(cd:GetFrameLevel() + 10)

		module.PositionTimer(timer)

		cd.timer = timer
		return timer
	end
end

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

function module.SetNextUpdate(self, nextUpdate)
	self.updater:GetAnimations():SetDuration(nextUpdate)
	if self.updater:IsPlaying() then
		self.updater:Stop()
	end
	self.updater:Play()
end

function module.UpdateTimer(self)
	local remaining = self.duration - (GetTime() - self.start)
	
	if remaining > 0 then
		local formatStr, time, nextUpdate, color = formatTime(remaining)
		self.text:SetFormattedText(formatStr, time)
		module.SetNextUpdate(self, nextUpdate)

		if self.r ~= color.r or self.g ~= color.g or self.b ~= color.b then
			self.r, self.g, self.b = color.r, color.g, color.b
			self.text:SetTextColor(color.r, color.g, color.b)
		end
	else
		module.StopTimer(self)
	end
end

function module.RefreshTimer(self)
	local scale = fontScale[round(self.cd:GetWidth())]

	if self.fontScale ~= scale then
		self.fontScale = scale

		if not scale then return end
		
		self.text:SetFont(Media:Fetch("font", db.Text.Font), self.fontScale, db.Text.Flag)
	end

	return true
end

function module.PositionTimer(self)
	self:SetAllPoints()
	self.text:SetPoint("CENTER", db.Text.XOffset, db.Text.YOffset)
end

function module.StartTimer(self, start, duration)
	self.start = start
	self.duration = duration
	self.enabled = true

	if module.RefreshTimer(self) then
		module.UpdateTimer(self)
		self:Show()
	else
		module.StopTimer(self)
	end
end

function module.StopTimer(self)
	self.enabled = nil
	if self.updater:IsPlaying() then
		self.updater:Stop()
	end
	self:Hide()

	self.cd.timer = nil

	tinsert(cache, self)
end

function module:AssignTimer(cd, start, duration)
	if cd.noCooldownCount then return end

	if not cd.timer and (duration < minDuration or not cd:IsVisible() or not fontScale[round(cd:GetWidth())]) then return end

	module.StartTimer(cd.timer or getTimer(cd), start, duration)
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
		local start, duration = GetActionCooldown(button.action)

		if not cd.timer or cd.timer.start ~= start or cd.timer.duration ~= duration then
			module:AssignTimer(cd, start, duration)
		end
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
		},
		Text = {
			Font = "vibroceb",
			Size = 20,
			Flag = "OUTLINE",			
			XOffset = 2,
			YOffset = 0,
		},
		Colors = {
			Day = {
				r = 0.8,
				g = 0.8,
				b = 0.8,
			},
			Hour = {
				r = 0.8,
				g = 0.8,
				b = 1.0,
			},
			Min = {
				r = 1.0,
				g = 1.0,
				b = 1.0,
			},
			Sec = {
				r = 1.0,
				g = 1.0,
				b = 0.0,
			},
			Threshold = {
				r = 1.0,
				g = 0.0,
				b = 0.0,				
			},
		},
	},
}

module.conflicts = "OmniCC;tullaCooldownCount"
module.getter = "generic"
module.setter = "Refresh"

function module:LoadOptions()
	local options = {
		General = self:NewGroup("General Settings", 1, {
			Threshold = self:NewInputNumber("Cooldown Threshold", "The time at which your coodown text is colored differnetly and begins using specified precision.", 1),
			MinDuration = self:NewInputNumber("Minimum Duration", "The lowest cooldown duration that timers will be shown for.", 2),
			Precision = self:NewSlider("Cooldown Precision", "How many decimal places will be shown once time is within the cooldown threshold.", 3, 0, 2, 1),
			MinScale = self:NewSlider("Minimum Scale", "The smallest size of icons that timers will be shown for.", 4, 0, 2, 0.1),
		}),
		Text = self:NewGroup("Text Settings", 2, {
			Font = self:NewSelect("Font", "Select the font to be used by cooldown's texts.", 1, AceGUIWidgetLSMlists.font, "LSM30_Font"),
			Size = self:NewSlider("Font Size", "Select the font size to be used by cooldown's texts.", 2, 6, 32, 1),
			Flag = self:NewSelect("Font Outline", "Select the font outline to be used by cooldown's texts.", 3, LUI.FontFlags),
			Offsets = self:NewHeader("Text Position Offsets", 4),
			XOffset = self:NewInputNumber("X Offset", "Horizontal offset to be applied to the cooldown's texts.", 5),
			YOffset = self:NewInputNumber("Y Offset", "Vertical offset to be applied to the cooldown's texts.", 6),
		}),
		Colors = self:NewGroup("Colors", 3, {
			Threshold = self:NewColorNoAlpha("Threshold", "The color of cooldown's text under the threshold.", 1),
			Sec = self:NewColorNoAlpha("Seconds", "The color of cooldown's text when representing seconds.", 2),
			Min = self:NewColorNoAlpha("Minutes", "The color of cooldown's text when representing minutes.", 3),
			Hour = self:NewColorNoAlpha("Hours", "The color of cooldown's text when representing hours.", 4),
			Day = self:NewColorNoAlpha("Days", "The color of cooldown's text when representing days.", 5),
		}),
	}
	return options
end

function module:Refresh(info, value)
	if type(info) == "table" then
		module:SetDBVar(info, value)
	end

	setPrecision()

	for i, timer in ipairs(timers) do
		if timer.enabled then
			module.RefreshTimer(timer)
			module.PositionTimer(timer)
		end
	end
end

function module:OnInitialize()
	db, dbd = LUI:Namespace(self, true)
end

module.DBCallback = module.OnInitialize

function module:OnEnable()
	setPrecision()

	-- Hook the SetCooldown metamethod of all Cooldown frames.
	module:SecureHook(getmetatable(ActionButton1Cooldown).__index, "SetCooldown", "AssignTimer")

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
	module:UnregisterAllEvnets()

	for i, timer in ipairs(timers) do
		if timer.enabled then
			module.StopTimer(timer)
		end
	end
end