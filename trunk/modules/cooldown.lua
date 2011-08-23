--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: cooldown.lua
	Description: Actionbar Cooldown Module
]] 

-- External references.
local addonname, LUI = ...
local module = LUI:Module("Cooldown", "AceHook-3.0")
local Media = LibStub("LibSharedMedia-3.0")

-- Database and defaults shortcuts.
local db, dbd

-- Local variables.
local Timer

function module:SetCooldowns()
	-- Localized functions.
	local floor, format, GetTime, insert, min, wipe = math.floor, string.format, GetTime, table.insert, math.min, wipe
	local function round(x) return floor(x + 0.5) end

	-- Local variables.
	local DAY, HOUR, MINUTE = 86400, 3600, 60
	local ICON_SIZE = 36

	-- Create a timer object.
	if not Timer then
		Timer = {}
		Timer.__mt = {
			__index = function(self, k)
				if Timer[k] then
					return Timer[k]
				elseif self.__old then
					return self.__old.__index[k]
				end
			end,
		}
		
		-- Timer variables.
		Timer.FontScale = {}	-- For memoizing.
		Timer.Stack = {}
		Timer.Timers = {}
		
		-- Timer formats.
		Timer.TimeFormat = {
			Days = {format = "%dd", color = db.Colors.Day, division = DAY, update = false},
			Hours = {format = "%dh", color = db.Colors.Hour, division = HOUR, update = false},
			Minutes = {format = "%dm", color = db.Colors.Min, division = MINUTE, update = false},
			Seconds = {format = "%d", color = db.Colors.Sec, division = 1, update = 1},
			Threshold = {format = false, color = db.Colors.Threshold, division = 1, update = false},
			Update = function(x, v) x = x - v return x > 0 and x or 1 end,
		}
		Timer.TimeFormat = setmetatable(Timer.TimeFormat, {
			__call = function(self, seconds)
				if seconds < db.General.Threshold + 0.5 then
					self.Threshold.format = "%."..db.General.Precision.."f"
					self.Threshold.update = db.General.Precision * 0.05
					return self.Threshold
				elseif seconds > DAY then
					self.Days.update = self.Update(seconds, DAY)
					return self.Days
				elseif seconds > HOUR then
					self.Hours.update = self.Update(seconds, HOUR)
					return self.Hours
				elseif seconds > MINUTE then
					self.Minutes.update = self.Update(seconds, MINUTE)
					return self.Minutes
				else
					return self.Seconds
				end
			end,
		})
		
		-- Timer methods.
		function Timer:Assign(frame, start, duration)
			-- Check if enabled.
			if not db.Enable then return end -- shouldn't be needed since we unhooked the SetCooldown functions in OnDisable
			
			-- Check duration.
			if duration < db.General.MinDuration then return end

			-- Check if frame already has a timer.
			if frame.Timer then return end

			-- Check if frame is visible.
			if not frame:IsVisible() then return end

			-- Get font scale.
			local width = round(frame:GetWidth())
			if not self.FontScale[width] then
				local scale = width / ICON_SIZE
				self.FontScale[width] = scale > db.General.MinScale and scale * db.Text.Size
			end

			-- Don't assign timers to frames that are too small.
			if not self.FontScale[width] then return end

			-- Get a timer.
			local timer = self:Collect()

			-- Assign timer to frame.
			frame.Timer = timer
			timer.Frame = frame

			-- Set all points.
			timer:SetAllPoints(frame)

			-- Set parent to frame.
			timer:SetParent(frame)

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
				timer:Hide()
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
			timer.duration = 0
			timer.fontScale = 0
			timer.nextUpdate = 0
			timer.start = 0
		
			-- Set scripts.
			timer:SetScript("OnSizeChanged", timer.OnSizeChanged)
			timer:SetScript("OnHide", timer.Stop)

			-- Add timer to timer list.
			self.Timers[#self.Timers + 1] = timer

			-- Return timer.
			return timer
		end

		function Timer:OnSizeChanged(width, height)
			if not self.Frame then return end

			-- Get font scale.
			width = round(width)
			if not self.FontScale[width] then
				local scale = width / ICON_SIZE
				self.FontScale[width] = scale > db.General.MinScale and scale * db.Text.Size
			end

			-- Check font scale.
			if self.fontScale == self.FontScale[width] then return end
			
			-- Set new font scale.
			self.fontScale = self.FontScale[width]

			-- Check if new scale is big enough.
			if self.fontScale then
				-- Set new font scale.
				self.text:SetFont(Media:Fetch("font", db.Text.Font), self.fontScale, db.Text.Flag)
			else
				-- Stop timer.
				self:Hide()
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
				self:Hide()
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
			self.start = start
			self.duration = duration
			self.nextUpdate = 0

			-- Start timer.
			self:SetScript("OnUpdate", self.OnUpdate)
			self:Show()
		end

		function Timer:Stop()
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
			-- Get format info.
			local info = self.TimeFormat(timeLeft)
			
			-- Set text.
			self.text:SetFormattedText(info.format, timeLeft / info.division)
			
			-- Set text colour.
			self.text:SetTextColor(info.color.r, info.color.g, info.color.b)

			-- Set next update interval.
			self.nextUpdate = info.update
		end
	end

	-- Hook the SetCooldown metamethod of all cooldown frames.
	-- ActionButton1Cooldown is used here since its likely to always exist.
	-- And I'd rather not create my own cooldown frame to preserve a tiny bit of memory.
	self:SecureHook(getmetatable(ActionButton1Cooldown).__index, "SetCooldown", function(self, start, duration)
		-- Skip frames that don't want a timer.
		if self.noOCC then return end

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
			--Threshold = self:NewSlider("Cooldown Threshold", "The time at which your cooldown text is colored differently and begins using specified precision.", 1, 0, 30, 1, self.Refresh),
			Threshold = self:NewInputNumber("Cooldown Threshold", "The time at which your coodown text is colored differnetly and begins using specified precision.", 1, self.Refresh),
			--MinDuration = self:NewSlider("Minimum Duration", "The lowest cooldown duration that timers will be shown for.", 2, 0, 60, 0.5),
			MinDuration = self:NewInputNumber("Minimum Duration", "The lowest cooldown duration that timers will be shown for.", 2),
			Precision = self:NewSlider("Cooldown Precision", "How many decimal places will be shown once time is within the cooldown threshold.", 3, 0, 3, 1, self.Refresh),
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