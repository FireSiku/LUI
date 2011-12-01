--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: cooldown.lua
	Description: Actionbar Cooldown Module
]] 

-- External references.
local addonname, LUI = ...
local module = LUI:Module("Cooldown", "AceHook-3.0")
local Media = LibStub("LibSharedMedia-3.0")
local Profiler = LUI.Profiler

-- Database and defaults shortcuts.
local db, dbd

-- Local variables.
local Cooldown
local Timer

function module:SetCooldowns()
	-- Localized functions.
	local ceil, floor, format, GetTime, insert, min, type, wipe = math.ceil, math.floor, string.format, GetTime, table.insert, math.min, type, wipe
	local function round(x) return floor(x + 0.5) end

	-- Create a cooldown frame.
	Cooldown = Cooldown or CreateFrame("Cooldown", "LUI_Cooldown")

	-- Local variables.
	local DAY, HOUR, MINUTE = 86400, 3600, 60
	local ICON_SIZE = 1 / 36
	local metatable = getmetatable(Cooldown)
	local precision = nil
	local xOffset, yOffset = db.Text.XOffset, db.Text.YOffset
	local minDuration, minScale = db.General.MinDuration, db.General.MinScale
	local textSize = db.Text.Size

	-- Create a timer object.
	if not Timer then
		Timer = {}
		
		-- Timer variables.
		Timer.FontScale = setmetatable({}, {
			__index = function(self, width)
				local scale = width * ICON_SIZE
				self[width] = scale > minScale and scale * textSize
				return self[width]
			end
		})
		Timer.Stack = {}
		Timer.Timers = {}
		
		-- Timer formats.
		Timer.TimeFormat = {
			-- Using factors (1 / Division) because multiplication is faster than division.
			Days = {format = "%dd", color = db.Colors.Day, factor = 1 / DAY},
			Hours = {format = "%dh", color = db.Colors.Hour, factor = 1 / HOUR},
			Minutes = {format = "%dm", color = db.Colors.Min, factor = 1 / MINUTE},
			Seconds = {format = "%d", color = db.Colors.Sec, factor = 1},
			Threshold = {format = false, color = db.Colors.Threshold, factor = 1},
			Precision = {
				[0] = {format = "%d", precision = 1},
				[1] = {format = "%.1f", precision = 0.1},
				[2] = {format = "%.2f", precision = 0.01},
			},
			Get = function(self, seconds)
				if seconds < db.General.Threshold then
					return self.Threshold, seconds % precision
				elseif seconds > DAY then
					return self.Days, seconds % DAY
				elseif seconds > HOUR then
					return self.Hours, seconds % HOUR
				elseif seconds > MINUTE then
					return self.Minutes, seconds % MINUTE
				else
					return self.Seconds, seconds % 1
				end
			end,
		}

		-- Set initial threshold and precison values.
		precision = Timer.TimeFormat.Precision[db.General.Precision]
		Timer.TimeFormat.Threshold.format, precision = precision.format, precision.precision
		
		-- Timer methods.
		function Timer:Assign(start, duration)
			-- Check if frame already has a timer.
			if self.Timer then
				-- Update timers in the case of durations be ing shortened by speical events.
				if duration ~= self.Timer.duration or start ~= self.Timer.start then
					if duration < minDuration or not self:IsVisible() then
						self:Stop()
					else
						self.Timer.start = start
						self.Timer.duration = duration
						self.Timer.nextUpdate = 0
					end					
				end
				return
			end

			-- Check if frame is visible.
			if not self:IsVisible() then return end
			
			-- Check duration.
			if duration < minDuration then return end
			
			-- Don't assign timers to frames that are too small.
			if not self.FontScale[round(self:GetWidth())] then return end

			-- Don't assign timers to frames with OnHide or OnUpdate scripts.
			if self:GetScript("OnHide") or self:GetScript("OnUpdate") then return end

			-- Assign timer to frame.
			self:Collect()

			-- Set parent to frame.
			self.Timer:SetParent(self)

			-- Set all points.
			self.Timer:SetPoint("CENTER", self, "CENTER", xOffset, yOffset)

			-- Check font scale.
			self:OnSizeChanged()

			-- Start timer.
			self:Start(start, duration)
		end
		
		function Timer:Collect()
			-- Collect an inactive timer or create a new one.
			if #self.Stack > 0 then
				-- Pop a timer from the stack.
				self.Timer, self.Stack[#self.Stack] = self.Stack[#self.Stack], nil
				self.Timer.Frame = self
			else
				-- Create a new timer.
				self:New()
			end
		end

		function Timer:Disable()
			-- Stop all timers.
			for index, timer in pairs(self.Timers) do
				if timer.Frame then
					timer.Frame:Stop()
				end
			end
		end

		function Timer:New()
			-- Create a timer inheriting the Timer object.
			local timer = Cooldown:CreateFontString("LUI_Cooldown_Timer"..(#self.Timers + 1), "OVERLAY")
			timer:Hide()

			-- Setup font string.
			timer:SetJustifyH("CENTER")
			timer:SetShadowColor(0, 0, 0, 0.5)
			timer:SetShadowOffset(2, -2)

			-- Set timer settings.
			timer.enabled = false
			timer.duration = 0
			timer.fontScale = 0
			timer.nextUpdate = 0
			timer.start = 0
			timer.r = 1
			timer.g = 1
			timer.b = 1
		
			-- Add timer to timer list.
			self.Timers[#self.Timers + 1] = timer

			-- Assign timer.
			self.Timer = timer
			timer.Frame = self
		end

		function Timer:OnSizeChanged()
			-- Get font scale.
			local scale = self.FontScale[round(self:GetWidth())]

			-- Check font scale.
			if self.Timer.fontScale == scale then return end
			
			-- Set new font scale.
			self.Timer.fontScale = scale

			-- Check if new scale is big enough.
			if self.Timer.fontScale then
				-- Set new font scale.
				self.Timer:SetFont(Media:Fetch("font", db.Text.Font), self.Timer.fontScale, db.Text.Flag)
			else
				-- Stop timer.
				self:Stop()
			end
		end

		function Timer:OnUpdate(elapsed)
			self.Timer.nextUpdate = self.Timer.nextUpdate - elapsed
			
			-- Throttle update.
			if self.Timer.nextUpdate > 0 then return end

			-- Update timer
			local timeLeft = self.Timer.duration - (GetTime() - self.Timer.start)
			if timeLeft > 0 then
				-- Update text.
				self:Update(timeLeft)
			else
				-- Stop timer if finished.
				self:Stop()
			end
		end

		function Timer:Refresh()
			-- Update local settings.
			precision = Timer.TimeFormat.Precision[db.General.Precision]
			Timer.TimeFormat.Threshold.format, precision = precision.format, precision.precision
			xOffset, yOffset = db.Text.XOffset, db.Text.YOffset
			minDuration, minScale = db.General.MinDuration, db.General.MinScale
			textSize = db.Text.Size

			-- Reset font scale memoizing results.
			wipe(self.FontScale)

			-- Update timer's font settings.
			for index, timer in pairs(self.Timers) do
				-- Reset font scale.
				timer.fontScale = 0

				-- Get font scale.
				if timer.Frame then
					timer.Frame:OnSizeChanged()

					-- Set new offsets.
					timer:SetPoint("CENTER", timer.Frame, "CENTER", xOffset, yOffset)
				end

				-- Set next update.
				timer.nextUpdate = 0
			end
		end

		function Timer:Start(start, duration)
			-- Set timer variables.
			self.Timer.enabled = true
			self.Timer.duration = duration
			self.Timer.nextUpdate = 0
			self.Timer.start = start

			-- Start timer.
			self:SetScript("OnHide", self.Stop)
			self:SetScript("OnUpdate", self.OnUpdate)
			self.Timer:Show()
		end

		function Timer:Stop()
			if not self.Timer.enabled then return end

			-- Disable timer.
			self.Timer.enabled = false

			-- Stop timer.
			self:SetScript("OnUpdate", nil)
			self:SetScript("OnHide", nil)
			self.Timer:Hide()

			-- Unassign from frame.
			self.Timer:SetParent(Cooldown)			
			self.Timer.Frame = nil

			-- Push timer on to the stack.
			self.Timer, self.Stack[#self.Stack + 1] = nil, self.Timer
		end

		function Timer:Update(timeLeft)
			-- Get format info and next update interval.
			local info; info, self.Timer.nextUpdate = self.TimeFormat:Get(timeLeft)
			
			-- Set text.
			timeLeft = info.factor == 1 and timeLeft or ceil(timeLeft * info.factor)
			self.Timer:SetFormattedText(info.format, timeLeft)
			
			-- Set text colour.
			if info.color.r ~= self.Timer.r or info.color.g ~= self.Timer.g or info.color.b ~= self.Timer.b then
				self.Timer.r, self.Timer.g, self.Timer.b = info.color.r, info.color.g, info.color.b
				self.Timer:SetTextColor(info.color.r, info.color.g, info.color.b)
			end
		end

		---[[	PROFILER
		-- Add timer functions to profiler.
		Profiler.TraceScope(Timer, "Timer", "LUI.Cooldown", nil, 2)
		--]]

		-- Copy Timer methods into the Cooldown metatable.
		for k, v in pairs(Timer) do metatable.__index[k] = v end
	end
	
	-- Hook the SetCooldown metamethod of all Cooldown frames.
	self:SecureHook(metatable.__index, "SetCooldown", function(self, start, duration)
		-- Skip frames that don't want a timer.
		if self.noLUITimer then return end

		-- Assign a timer.
		self:Assign(start, duration)
	end)
end

-- Default variables.
module.defaults = {
	profile = {
		Enable = true,
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
module.conflicts = "OmniCC"

function module:LoadOptions()
	local widgetLists = AceGUIWidgetLSMlists
	local fontflags = {}
	for k, v in pairs({"OUTLINE", "THICKOUTLINE", "MONOCHROME", "NONE"}) do
		fontflags[v] = v
	end

	local options = {
		General = self:NewGroup("General Settings", 1, {
			Threshold = self:NewInputNumber("Cooldown Threshold", "The time at which your coodown text is colored differnetly and begins using specified precision.", 1, self.Refresh),
			MinDuration = self:NewInputNumber("Minimum Duration", "The lowest cooldown duration that timers will be shown for.", 2, self.Refresh),
			Precision = self:NewSlider("Cooldown Precision", "How many decimal places will be shown once time is within the cooldown threshold.", 3, 0, 2, 1, self.Refresh),
			MinScale = self:NewSlider("Minimum Scale", "The smallest size of icons that timers will be shown for.", 4, 0, 2, 0.1, self.Refresh),
		}),
		Text = self:NewGroup("Text Settings", 2, {
			Font = self:NewSelect("Font", "Select the font to be used by cooldown's texts.", 1, widgetLists.font, "LSM30_Font", self.Refresh),
			Size = self:NewSlider("Font Size", "Select the font size to be used by cooldown's texts.", 2, 6, 32, 1, self.Refresh),
			Flag = self:NewSelect("Font Outline", "Select the font outline to be used by cooldown's texts.", 3, fontflags, false, self.Refresh),
			Offsets = self:NewHeader("Text Position Offsets", 4),
			XOffset = self:NewInputNumber("X Offset", "Horizontal offset to be applied to the cooldown's texts.", 5, self.Refresh),
			YOffset = self:NewInputNumber("Y Offset", "Vertical offset to be applied to the cooldown's texts.", 6, self.Refresh),
		}),
		Colors = self:NewGroup("Colors", 3, {
			Threshold = self:NewColorNoAlpha("Threshold", "The color of cooldown's text under the threshold.", 1, self.Refresh),
			Sec = self:NewColorNoAlpha("Seconds", "The color of cooldown's text when representing seconds.", 2, self.Refresh),
			Min = self:NewColorNoAlpha("Minutes", "The color of cooldown's text when representing minutes.", 3, self.Refresh),
			Hour = self:NewColorNoAlpha("Hours", "The color of cooldown's text when representing hours.", 4, self.Refresh),
			Day = self:NewColorNoAlpha("Days", "The color of cooldown's text when representing days.", 5, self.Refresh),
		}),
	}
	return options
end

function module:OnEnable()
	self:SetCooldowns()
end

function module:OnDisable()
	if not Timer then return end
	
	-- Unhook the SetCooldown metamethod of all cooldown frames.
	self:UnhookAll()
	
	-- Stop timers.
	Timer:Disable()
end

function module:OnInitialize()
	db, dbd = LUI:NewNamespace(self, true)
end

function module:Refresh()
	if not Timer then return end

	-- Refresh Timers.
	Timer:Refresh()
end