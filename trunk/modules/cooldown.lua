--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: cooldown.lua
	Description: Actionbar Cooldown Module
	Version....: 1.2
	Rev Date...: 06/11/2010 [dd/mm/yyyy]
	
	Edits:
		v1.0: Loui
		v1.1: Hix
		v1.2: Hix
	
	An edited lightweight OmniCC for LUI
    A featureless, 'pure' version of OmniCC.
    This version should work on absolutely everything, but I've removed pretty much all of the options
]] 

local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local LSM = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists
local LUIHook = LUI:GetModule("LUIHook")
local module = LUI:NewModule("Cooldown", "AceHook-3.0")

local db
local fontflags = {'OUTLINE', 'THICKOUTLINE', 'MONOCHROME', 'NONE'}
local hooks = { }

function module:SetCooldowns()
	if db.Cooldown.Enable ~= true then return end
	
	-- Is this omniCC variable needed?
	OmniCC = true --hack to work around detection from other addons for OmniCC
	local COLORS = {
		DAY = "",
		HOUR = "",
		MIN = "",
		SEC = "",
		THRESHOLD = "",
	}
	local UPDATE = nil	--used to provide a way to update created timers.
	local DAY, HOUR, MINUTE = 86400, 3600, 60 --used for formatting text
	local DAYISH, HOURISH, MINUTEISH = 3600 * 23.5, 60 * 59.5, 59.5 --used for formatting text at transition points
	local HALFDAYISH, HALFHOURISH, HALFMINUTEISH = DAY/2 + 0.5, HOUR/2 + 0.5, MINUTE/2 + 0.5 --used for calculating next update times

	--local bindings!
	local format = string.format
	local floor = math.floor
	local min = math.min
	local round = function(x) return floor(x + 0.5) end
	local GetTime = GetTime
	
	--updates created timers
	function module:UpdateCooldowns()
		UPDATE = GetTime()
	end
	--updates colours
	function module:UpdateColors()
		COLORS.DAY = format("|cff%02x%02x%02x", db.Cooldown.Text.Colors.Day.r * 255, db.Cooldown.Text.Colors.Day.g * 255, db.Cooldown.Text.Colors.Day.b * 255)
		COLORS.HOUR = format("|cff%02x%02x%02x", db.Cooldown.Text.Colors.Hour.r * 255, db.Cooldown.Text.Colors.Hour.g * 255, db.Cooldown.Text.Colors.Hour.b * 255)
		COLORS.MIN = format("|cff%02x%02x%02x", db.Cooldown.Text.Colors.Min.r * 255, db.Cooldown.Text.Colors.Min.g * 255, db.Cooldown.Text.Colors.Min.b * 255)
		COLORS.SEC = format("|cff%02x%02x%02x", db.Cooldown.Text.Colors.Sec.r * 255, db.Cooldown.Text.Colors.Sec.g * 255, db.Cooldown.Text.Colors.Sec.b * 255)
		COLORS.THRESHOLD = format("|cff%02x%02x%02x", db.Cooldown.Text.Colors.Threshold.r * 255, db.Cooldown.Text.Colors.Threshold.g * 255, db.Cooldown.Text.Colors.Threshold.b * 255)
		module:UpdateCooldowns()
	end
	--run function
	module:UpdateColors()

	--returns both what text to display, and how long until the next update
	local function getTimeText(s)
		-- format text as seconds with decimal at threshold or below
		if s < db.Cooldown.Threshold + 0.5 then
			return format("%s%.1f|r", COLORS.THRESHOLD, s), s - format("%.1f", s)
		--format text as seconds when at 90 seconds or below
		elseif s < MINUTEISH then
			local seconds = round(s)
			return format('%s%d|r', COLORS.SEC, seconds), s - (seconds - 0.51)
		--format text as minutes when below an hour
		elseif s < HOURISH then
			local minutes = round(s/MINUTE)
			return format('%s%dm|r', COLORS.MIN, minutes), minutes > 1 and (s - (minutes*MINUTE - HALFMINUTEISH)) or (s - MINUTEISH)
		--format text as hours when below a day
		elseif s < DAYISH then
			local hours = round(s/HOUR)
			return format('%s%dh|r', COLORS.HOUR, hours), hours > 1 and (s - (hours*HOUR - HALFHOURISH)) or (s - HOURISH)
		--format text as days
		else
			local days = round(s/DAY)
			return format('%s%dd|r', COLORS.DAY, days), days > 1 and (s - (days*DAY - HALFDAYISH)) or (s - DAYISH)
		end
	end

	--stops the timer
	local function Timer_Stop(self)
		self.enabled = nil
		self:Hide()
	end

	--forces the given timer to update on the next frame
	local function Timer_ForceUpdate(self)
		self.nextUpdate = 0
		self:Show()
	end

	--adjust font size whenever the timer's parent size changes
	--hide if it gets too tiny
	local function Timer_OnSizeChanged(self, width, height)
		local fontScale = round(width) / db.Cooldown.IconSize
		if fontScale == self.fontScale then
			return
		end

		self.fontScale = fontScale
		if fontScale < db.Cooldown.MinScale then
			self:Hide()
		else
			self.text:SetFont(LSM:Fetch("font", db.Cooldown.Text.Font), self.fontScale * db.Cooldown.Text.Size, db.Cooldown.Text.Flag)
			self.text:SetShadowColor(0, 0, 0, 0.5)
			self.text:SetShadowOffset(2, -2)
			if self.enabled then
				Timer_ForceUpdate(self)
			end
		end
	end

	--update timer text, if it needs to be
	--hide the timer if done
	local function Timer_OnUpdate(self, elapsed)
		if self.nextUpdate > 0 then
			self.nextUpdate = self.nextUpdate - elapsed
		else
			local remain = self.duration - (GetTime() - self.start)
			if round(remain) > 0 then
				local time, nextUpdate = getTimeText(remain)
				self.text:SetText(time)
				self.nextUpdate = nextUpdate
			else
				Timer_Stop(self)
			end
		end
	end

	--returns a new timer object
	local function Timer_Create(self)
		if not self.timer then
			--a frame to watch for OnSizeChanged events
			--needed since OnSizeChanged has funny triggering if the frame with the handler is not shown
			local scaler = CreateFrame("Frame", nil, self)
			scaler:SetAllPoints(self)

			local timer = CreateFrame("Frame", nil, scaler)
			timer:Hide()
			timer:SetAllPoints(scaler)

			local text = timer:CreateFontString(nil, "OVERLAY")
			text:SetJustifyH("CENTER")
			
			-- link children
			self.timer = timer
			self.timer.scaler = scaler
			self.timer.text = text
			-- set scripts
			self.timer:SetScript("OnUpdate", Timer_OnUpdate)
			self.timer.scaler:SetScript('OnSizeChanged', function(s, ...) Timer_OnSizeChanged(self.timer, ...) end)
		end

		-- set font settings
		self.timer.text:SetPoint("CENTER", LUI:Scale(db.Cooldown.Text.XOffset), LUI:Scale(db.Cooldown.Text.YOffset))
		
		-- run SizeChange
		self.timer.fontScale = 0
		Timer_OnSizeChanged(self.timer, self.timer.scaler:GetSize())

		self.timer.update = UPDATE
		return self.timer
	end

	--hook the SetCooldown method of all cooldown frames
	--ActionButton1Cooldown is used here since its likely to always exist 
	--and I'd rather not create my own cooldown frame to preserve a tiny bit of memory
	hooksecurefunc(getmetatable(ActionButton1Cooldown).__index, 'SetCooldown', function(self, start, duration)
		if self.noOCC then return end
		--start timer
		if start > 0 and duration > db.Cooldown.MinDuration then
			local timer = ((self.timer and self.timer.update == UPDATE) and self.timer) or Timer_Create(self)
			timer.start = start
			timer.duration = duration
			timer.enabled = true
			timer.nextUpdate = 0
			if timer.fontScale >= db.Cooldown.MinScale then timer:Show() end
		--stop timer
		else
			local timer = self.timer
			if timer then
				Timer_Stop(timer)
			end
		end
	end)
end

local defaults = {
	Cooldown = {
		Enable = true,
		Threshold = 8,
		Text = {
			Font = "vibroceb",
			Size = 20,
			Flag = "OUTLINE",
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
			XOffset = 2,
			YOffset = 0,
		},
		MinScale = 0.5,
		MinDuration = 3,
		IconSize = 36,
	},
}

function module:LoadOptions()
	local options = {
		Cooldown = {
			name = "Cooldown",
			type = "group",
			childGroups = "tab",
			disabled = function() return not db.Cooldown.Enable end,
			args = {
				Header = {
					name = "Cooldown",
					type = "header",
					order = 1,
				},
				Description = {
					name = "|cff3399ffNotice:|r\n- Some changes will not take effect until your next cooldown is activated.",
					type = "description",
					width = "full",
					order = 2,
				},
				Settings = {
					name = "Settings",
					type = "group",
					order = 3,
					args = {
						Enable = {
							name = "Enable",
							desc = "Enable LUI Cooldowns.\n",
							type = "toggle",
							width = "full",
							order = 1,
							get = function() return db.Cooldown.Enable end,
							set = function()
									db.Cooldown.Enable = not db.Cooldown.Enable
									StaticPopup_Show("RELOAD_UI")
								end,
						},
						Threshold = {
							name = "Cooldown Threshold",
							desc = "The time at which your Cooldown's text is coloured differently.\n\nDefault: "..LUI.defaults.profile.Cooldown.Threshold,
							type = "input",
							order = 2,
							get = function() return tostring(db.Cooldown.Threshold) end,
							set = function(self, threshold)
									if (threshold == nil) or (threshold == "") then
										threshold = "0"
									end
									
									db.Cooldown.Threshold = tonumber(threshold)
									module:UpdateCooldowns()
								end,
						},
						MinDuration = {
							name = "Minimum Duration\n",
							desc = "The smallest duration of Cooldown to be watched.\n\nDefault: "..LUI.defaults.profile.Cooldown.MinDuration,
							type = "input",
							order = 3,
							get = function() return tostring(db.Cooldown.MinDuration) end,
							set = function(self, duration)
									if (duration == nil) or (duration == "") then
										duration = "0"
									end
									
									db.Cooldown.MinDuration = tonumber(duration)
									module:UpdateCooldowns()
								end,
						},
						MinScale = {
							name = "Minimum Scale",
							desc = "The smallest size of icons for Cooldowns to effect.\n\nDefault: "..LUI.defaults.profile.Cooldown.MinScale,
							type = "input",
							order = 4,
							get = function() return tostring(db.Cooldown.MinScale) end,
							set = function(self, scale)
									if (scale == nil) or (scale == "") then
										scale = "0"
									end
									
									db.Cooldown.MinScale = tonumber(scale)
									module:UpdateCooldowns()
								end,
						},
					},					
				},
				TextSettings = {
					name = "Text",
					type = "group",
					order = 4,
					args = {
						Font = {
							name = "Font",
							desc = "Choose a Font to be used by Cooldowns.\n\nDefault: "..LUI.defaults.profile.Cooldown.Text.Font,
							type = "select",
							dialogControl = "LSM30_Font",
							values = widgetLists.font,
							order = 1,
							get = function() return db.Cooldown.Text.Font end,
							set = function(self, font)
									db.Cooldown.Text.Font = font
									module:UpdateCooldowns()
								end,
						},
						Size = {
							name = "Size",
							desc = "Choose a Font Size to be used by Cooldowns.\n\nDefault: "..LUI.defaults.profile.Cooldown.Text.Size,
							type = "range",
							order = 2,
							min = 6,
							max = 50,
							step = 1,
							get = function() return db.Cooldown.Text.Size end,
							set = function(self, size)
									db.Cooldown.Text.Size = size
									module:UpdateCooldowns()
								end,
						},
						Flag = {
							name = "Outline",
							desc = "Choose a Font Flag to be used by Cooldowns.\n\nDefault: "..LUI.defaults.profile.Cooldown.Text.Flag,
							type = "select",
							values = fontflags,
							order = 3,
							get = function()
									for k, v in pairs(fontflags) do
										if db.Cooldown.Text.Flag == v then
											return k
										end
									end
								end,
							set = function(self, flag)
									db.Cooldown.Text.Flag = fontflags[flag]
									module:UpdateCooldowns()
								end,
						},
						Colors = {
							name = "Colors",
							type = "group",
							guiInline = true,
							order = 4,
							args = {
								Threshold = {
									name = "Threshold",
									desc = "Choose an individual color for the Threshold.\n\nDefaults:\nr = "..LUI.defaults.profile.Cooldown.Text.Colors.Threshold.r.."\ng = "..LUI.defaults.profile.Cooldown.Text.Colors.Threshold.g.."\nb = "..LUI.defaults.profile.Cooldown.Text.Colors.Threshold.b,
									type = "color",
									order = 1,
									hasAlpha = false,
									get = function() return db.Cooldown.Text.Colors.Threshold.r, db.Cooldown.Text.Colors.Threshold.g, db.Cooldown.Text.Colors.Threshold.b end,
									set = function(self, r, g, b)
											db.Cooldown.Text.Colors.Threshold.r = r
											db.Cooldown.Text.Colors.Threshold.g = g
											db.Cooldown.Text.Colors.Threshold.b = b
											
											module:UpdateColors()
										end,									
								},
								Seconds = {
									name = "Seconds",
									desc = "Choose an individual color for Seconds.\n\nDefaults:\nr = "..LUI.defaults.profile.Cooldown.Text.Colors.Sec.r.."\ng = "..LUI.defaults.profile.Cooldown.Text.Colors.Sec.g.."\nb = "..LUI.defaults.profile.Cooldown.Text.Colors.Sec.b,
									type = "color",
									order = 2,
									hasAlpha = false,
									get = function() return db.Cooldown.Text.Colors.Sec.r, db.Cooldown.Text.Colors.Sec.g, db.Cooldown.Text.Colors.Sec.b end,
									set = function(self, r, g, b)
											db.Cooldown.Text.Colors.Sec.r = r
											db.Cooldown.Text.Colors.Sec.g = g
											db.Cooldown.Text.Colors.Sec.b = b
											
											module:UpdateColors()
										end,									
								},
								Minutes = {
									name = "Minutes",
									desc = "Choose an individual color for Minutes.\n\nDefaults:\nr = "..LUI.defaults.profile.Cooldown.Text.Colors.Min.r.."\ng = "..LUI.defaults.profile.Cooldown.Text.Colors.Min.g.."\nb = "..LUI.defaults.profile.Cooldown.Text.Colors.Min.b,
									type = "color",
									order = 3,
									hasAlpha = false,
									get = function() return db.Cooldown.Text.Colors.Min.r, db.Cooldown.Text.Colors.Min.g, db.Cooldown.Text.Colors.Min.b end,
									set = function(self, r, g, b)
											db.Cooldown.Text.Colors.Min.r = r
											db.Cooldown.Text.Colors.Min.g = g
											db.Cooldown.Text.Colors.Min.b = b
											
											module:UpdateColors()
										end,									
								},
								Hours = {
									name = "Hours",
									desc = "Choose an individual color for Hours.\n\nDefaults:\nr = "..LUI.defaults.profile.Cooldown.Text.Colors.Hour.r.."\ng = "..LUI.defaults.profile.Cooldown.Text.Colors.Hour.g.."\nb = "..LUI.defaults.profile.Cooldown.Text.Colors.Hour.b,
									type = "color",
									order = 4,
									hasAlpha = false,
									get = function() return db.Cooldown.Text.Colors.Hour.r, db.Cooldown.Text.Colors.Hour.g, db.Cooldown.Text.Colors.Hour.b end,
									set = function(self, r, g, b)
											db.Cooldown.Text.Colors.Hour.r = r
											db.Cooldown.Text.Colors.Hour.g = g
											db.Cooldown.Text.Colors.Hour.b = b
											
											module:UpdateColors()
										end,									
								},
								Days = {
									name = "Days",
									desc = "Choose an individual color for Days.\n\nDefaults:\nr = "..LUI.defaults.profile.Cooldown.Text.Colors.Day.r.."\ng = "..LUI.defaults.profile.Cooldown.Text.Colors.Day.g.."\nb = "..LUI.defaults.profile.Cooldown.Text.Colors.Day.b,
									type = "color",
									order = 5,
									hasAlpha = false,
									get = function() return db.Cooldown.Text.Colors.Day.r, db.Cooldown.Text.Colors.Day.g, db.Cooldown.Text.Colors.Day.b end,
									set = function(self, r, g, b)
											db.Cooldown.Text.Colors.Day.r = r
											db.Cooldown.Text.Colors.Day.g = g
											db.Cooldown.Text.Colors.Day.b = b
											
											module:UpdateColors()
										end,									
								},					
							},
						},
						Offset = {
							name = "Offset",
							type = "group",
							guiInline = true,
							order = 5,
							args = {
								XOffset = {
									name = "X Offset",
									desc = "Set the X Offset of your Cooldowns' Text.\n\nNotes:\nPositive values = right\nNegitive values = left\nDefault: "..LUI.defaults.profile.Cooldown.Text.XOffset,
									type = "input",
									width = "half",
									order = 1,
									get = function() return tostring(db.Cooldown.Text.XOffset) end,
									set = function(self, x)
											if (x == nil) or (x == "") then
												x = "0"
											end
											
											db.Cooldown.Text.XOffset = tonumber(x)
											module:UpdateCooldowns()
										end,
								},
								YOffset = {
									name = "Y Offset",
									desc = "Set the Y Offset of your Cooldowns' Text.\n\nNotes:\nPositive values = up\nNegitive values = down\nDefault: "..LUI.defaults.profile.Cooldown.Text.YOffset,
									type = "input",
									width = "half",
									order = 2,
									get = function() return tostring(db.Cooldown.Text.YOffset) end,
									set = function(self, y)
											if (y == nil) or (y == "") then
												y = "0"
											end
											
											db.Cooldown.Text.YOffset = tonumber(y)
											module:UpdateCooldowns()
										end,
								},
							},						
						},
					},					
				},
			},
		},
	}
	return options
end

function module:OnInitialize()
	LUI:MergeDefaults(LUI.db.defaults.profile, defaults)
	LUI:RefreshDefaults()
	LUI:Refresh()
	
	self.db = LUI.db.profile
	db = self.db
	
	LUI:RegisterModule(self)
end

function module:OnEnable()
	self:SetCooldowns()
end

function module:OnDisable()
	LUI:ClearFrames()
end