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
local Timer

function module:SetCooldowns()
	-- Localized functions.
	local ceil, floor, format, GetTime, insert, min, type, wipe = math.ceil, math.floor, string.format, GetTime, table.insert, math.min, type, wipe
	local function round(x) return floor(x + 0.5) end

	-- Local variables.
	local DAY, HOUR, MINUTE = 86400, 3600, 60
	local ICON_SIZE = 1 / 36

	-- Create a timer object.
	if not Timer then
		Timer = {}
		Timer.__mt = {
			__index = function(self, k)
				if Timer[k] then
					return Timer[k]
				elseif self.__old then
					local __type = type(self.__old.__index)
					if __type == "function" then
						return self.__old.__index(self, k)
					elseif __type == "table" then
						return self.__old.__index[k]
					end
				end
			end,
		}
		
		-- Timer variables.
		Timer.FontScale = setmetatable({}, {
			__index = function(self, width)
				local scale = width * ICON_SIZE
				self[width] = scale > db.General.MinScale and scale * db.Text.Size
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
		}
		Timer.TimeFormat = setmetatable(Timer.TimeFormat, {
			__call = function(self, seconds)
				if seconds < db.General.Threshold then
					local precision = self.Precision[db.General.Precision]
					self.Threshold.format = precision.format
					return self.Threshold, seconds % precision.precision
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
		})
		
		-- Timer methods.
		function Timer:Assign(frame, start, duration)
			-- Check if frame already has a timer.
			if frame.Timer then
				if duration < db.General.MinDuration or not frame:IsVisible() then
					frame.Timer:Stop()
				end
				return
			end

			-- Check if frame is visible.
			if not frame:IsVisible() then return end
			
			-- Check duration.
			if duration < db.General.MinDuration then return end
			
			-- Don't assign timers to frames that are too small.
			if not self.FontScale[round(frame:GetWidth())] then return end

			-- Get a timer.
			local timer = self:Collect()

			-- Assign timer to frame.
			frame.Timer = timer
			timer.Frame = frame

			-- Set parent to frame.
			timer:SetParent(frame)

			-- Set all points.
			timer:SetAllPoints(frame)

			-- Check font scale.
			timer:OnSizeChanged(frame:GetSize())

			-- Start timer.
			timer:Start(start, duration)
		end
		
		function Timer:Collect()
			-- Collect an inactive timer or create a new one.
			if #self.Stack > 0 then
				-- Pop a timer from the stack.
				local timer; timer, self.Stack[#self.Stack] = self.Stack[#self.Stack], nil
				return timer
			else
				-- Create a new timer.
				return self:New()
			end
		end

		function Timer:Disable()
			-- Stop all timers.
			for index, timer in pairs(self.Timers) do
				timer:Stop()
			end
		end

		function Timer:New()
			-- Create a timer inheriting the Timer object.
			local timer = CreateFrame("Frame", "LUI_Cooldown_Timer"..(#self.Timers + 1))
			timer.__old = getmetatable(timer)
			timer = setmetatable(timer, self.__mt)
			timer:Hide()

			-- Create font string.
			timer.text = timer:CreateFontString(nil, "OVERLAY")
			timer.text:SetJustifyH("CENTER")
			timer.text:SetShadowColor(0, 0, 0, 0.5)
			timer.text:SetShadowOffset(2, -2)
			timer.text:SetPoint("CENTER", db.Text.XOffset, db.Text.YOffset)

			-- Set timer settings.
			timer.enabled = false
			timer.duration = 0
			timer.fontScale = 0
			timer.nextUpdate = 0
			timer.start = 0
			timer.text.r = 1
			timer.text.g = 1
			timer.text.b = 1
		
			-- Set scripts.
			timer:SetScript("OnHide", self.Stop)

			-- Add timer to timer list.
			self.Timers[#self.Timers + 1] = timer

			-- Return timer.
			return timer
		end

		function Timer:OnSizeChanged(width, height)
			if not self.Frame then return end

			-- Get font scale.
			local scale = self.FontScale[round(width)]

			-- Check font scale.
			if self.fontScale == scale then return end
			
			-- Set new font scale.
			self.fontScale = scale

			-- Check if new scale is big enough.
			if self.fontScale then
				-- Set new font scale.
				self.text:SetFont(Media:Fetch("font", db.Text.Font), self.fontScale, db.Text.Flag)
			else
				-- Stop timer.
				self:Stop()
			end
		end

		function Timer:OnUpdate(elapsed)
			self.nextUpdate = self.nextUpdate - elapsed
			
			-- Throttle update.
			if self.nextUpdate > 0 then return end

			-- Update timer
			local timeLeft = self.duration - (GetTime() - self.start)
			if timeLeft > 0 then
				-- Update text.
				self:Update(timeLeft)
			else
				-- Stop timer if finished.
				self:Stop()
			end
		end

		function Timer:Refresh()
			-- Reset font scale memoizing results.
			wipe(self.FontScale)

			-- Update timer's font settings.
			for index, timer in pairs(self.Timers) do
				-- Reset font scale.
				timer.fontScale = 0

				-- Get font scale.
				if timer.Frame then
					timer:OnSizeChanged(timer.Frame:GetSize())
				end

				-- Set new offsets.
				timer.text:SetPoint("CENTER", db.Text.XOffset, db.Text.YOffset)

				-- Set next update.
				timer.nextUpdate = 0
			end
		end

		function Timer:Start(start, duration)
			-- Set timer variables.
			self.enabled = true
			self.duration = duration
			self.nextUpdate = 0
			self.start = start

			-- Start timer.
			self:SetScript("OnUpdate", self.OnUpdate)
			self:Show()
		end

		function Timer:Stop()
			if not self.enabled then return end

			-- Disable timer.
			self.enabled = false

			-- Stop timer.
			self:SetScript("OnUpdate", nil)
			self:Hide()

			-- Unassign from frame.
			self:SetParent(nil)
			if self.Frame then
				self.Frame.Timer = nil
				self.Frame = nil
			end

			-- Push timer on to the stack.
			self.Stack[#self.Stack + 1] = self
		end

		function Timer:Update(timeLeft)
			-- Get format info and next update interval.
			local info; info, self.nextUpdate = self.TimeFormat(timeLeft)
			
			-- Set text.
			timeLeft = info.factor == 1 and timeLeft or ceil(timeLeft * info.factor)
			self.text:SetFormattedText(info.format, timeLeft)
			
			-- Set text colour.
			if info.color.r ~= self.text.r or info.color.g ~= self.text.g or info.color.b ~= self.text.b then
				self.text.r, self.text.g, self.text.b = info.color.r, info.color.g, info.color.b
				self.text:SetTextColor(info.color.r, info.color.g, info.color.b)
			end
		end

		---[[	PROFILER
		-- Add timer functions to profiler.
		Profiler.TraceScope(Timer, "Timer", "LUI.Cooldown", nil, 1)
		Profiler.TraceScope(getmetatable(Timer.TimeFormat), "TimeFormat", "LUI.Cooldown.Timer")
		--]]
	end

	-- Hook the SetCooldown metamethod of all cooldown frames.
	-- ActionButton1Cooldown is used here since its likely to always exist.
	-- And I'd rather not create my own cooldown frame to preserve a tiny bit of memory.
	self:SecureHook(getmetatable(ActionButton1Cooldown).__index, "SetCooldown", function(self, start, duration)
		-- Skip frames that don't want a timer.
		if self.noLUITimer then return end

		-- Assign a timer.
		Timer:Assign(self, start, duration)
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

function module:LoadOptions()
	local widgetLists = AceGUIWidgetLSMlists
	local fontflags = {}
	for k, v in pairs({"OUTLINE", "THICKOUTLINE", "MONOCHROME", "NONE"}) do
		fontflags[v] = v
	end

	local options = {
		General = self:NewGroup("General Settings", 1, {
			Threshold = self:NewInputNumber("Cooldown Threshold", "The time at which your coodown text is colored differnetly and begins using specified precision.", 1, self.Refresh),
			MinDuration = self:NewInputNumber("Minimum Duration", "The lowest cooldown duration that timers will be shown for.", 2),
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