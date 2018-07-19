--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: mirrorbar.lua
	Description: Customization of the Mirror Bar
	Version....: 1.0
	Rev Date...: 06/11/2012 [dd/mm/yyyy]
	LUI Version: Mule
]]

------------------------------------------------------------------------
-- External references.
------------------------------------------------------------------------
local addonname, LUI = ...
local module = LUI:Module("Mirror Bar", "AceEvent-3.0")
local Profiler = LUI.Profiler
local Media = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists

------------------------------------------------------------------------
-- Database and defaults shortcuts.
------------------------------------------------------------------------
local db, dbd
local floor = math.floor
local format = string.format
local PAUSED

LUI.Versions.mirrorbar = 1.0
Profiler.TraceScope(module, "Mirror Bar", "LUI")

------------------------------------------------------------------------
--	Defaults
------------------------------------------------------------------------
module.defaults = {
	profile = {
		General = {
			Width = 250,
			Height = 20,
			X = 0,
			Y = -75,
			Texture = "LUI_Gradient",
			TextureBG = "LUI_Minimalist",
			BarGap = 5,
			ArchyBar = false,
		},
		Colors = {
			Bar = {
				r = 0.13,
				g = 0.59,
				b = 1,
				a = 0.7,
			},
			FatigueBar = {
				r = 1,
				g = 1,
				b = 0.5,
				a = 0.7,
			},
			BreathBar = {
				r = 0,
				g = 0.6,
				b = 1,
				a = 0.7,
			},
			FeignBar = {
				r = 0.92,
				g = 0.63,
				b = 0,
				a = 0.7,
			},
			ArchyBar = {
				r = 1,
				g = .3,
				b = .4,
				a = 0.7,
			},
			Background = {
				r = 0.15,
				g = 0.15,
				b = 0.15,
				a = 0.67,
			},
		},
		Text = {
			Name = {
				Font = "neuropol",
				Size = 13,
				OffsetX = 5,
				OffsetY = 1,
				Color = {
					r = 0.9,
					g = 0.9,
					b = 0.9,
				},
			},
			Time = {
				Font = "neuropol",
				Size = 13,
				OffsetX = -5,
				OffsetY = 1,
				Color = {
					r = 0.9,
					g = 0.9,
					b = 0.9,
				},
			},
		},
		Border = {
			Texture = "glow",
			Thickness = 4,
			Color = {
				r = 0.9,
				g = 0.9,
				b = 0.9,
				a = 0.65,
			},
			Inset = {
				left = 2,
				right = 2,
				top = 2,
				bottom = 2,
			},
		},
	},
}

------------------------------------------------------------------------
-- Options
------------------------------------------------------------------------
module.optionsName = "Mirror Bar"
module.getter = "generic"
module.setter = "Refresh"

function module:LoadOptions()
	local applyMirrorbar = function() self:Refresh() end
	local applyArchybar = function() self:ToggleArchy() end

	local options = {
		Title = self:NewHeader("Mirror Bar", 1),
		General = self:NewGroup("General Settings", 2, {
			Width = self:NewInputNumber("Width", "Choose the Width for the Mirror Bar.", 1, applyMirrorbar, nil),
			Height = self:NewInputNumber("Height", "Choose the Height for the Mirror Bar.", 2, applyMirrorbar, nil),
			X = self:NewInputNumber("X Value", "Choose the X Value for the Mirror Bar.", 3, applyMirrorbar, nil),
			Y = self:NewInputNumber("Y Value", "Choose the Y Value for the Mirror Bar.", 4, applyMirrorbar, nil),
			empty2 = self:NewDesc(" ", 5),
			Texture = self:NewSelect("Texture", "Choose the Mirror Bar Texture.", 6, widgetLists.statusbar, "LSM30_Statusbar", applyMirrorbar, nil),
			TextureBG = self:NewSelect("Background Texture", "Choose the MirrorBar Background Texture.", 7, widgetLists.statusbar, "LSM30_Statusbar", applyMirrorbar, nil),
			BarGap = self:NewSlider("Spacing", "Select the Spacing between mirror bars when shown.", 8, 0, 40, 1, applyMirrorbar, nil, nil),
			ArchyBar = self:NewToggle("Archaeology Progress Bar", "Integrate the Archaeology Progress bar", 9, applyArchybar),
		}),
		Colors = self:NewGroup("Bar Colors", 4, nil, {
			FatigueBar = self:NewColor("Fatigue Bar", "Fatigue Bar", 1, applyMirrorbar),
			BreathBar = self:NewColor("Breath Bar", "Breath Bar", 2, applyMirrorbar),
			FeignBar = self:NewColor("Feign Death Bar", "Feign Death Bar", 3, applyMirrorbar),
			Bar = self:NewColor("Other Bar", "Other Mirror Bars", 4, applyMirrorbar),
			ArchyBar = self:NewColor("Archaeology Progress Bar", "Archaeology Progress Bar", 5, applyMirrorbar),
			Background = self:NewColor("Background", "MirrorBar Background", 6, applyMirrorbar),
		}),
		Text = self:NewGroup("Text Settings", 5, nil, {
			Name = self:NewGroup("Name", 1, true, {
				Font = self:NewSelect("Font", "Choose the Font for the Mirror Name Text.", 2, widgetLists.font, "LSM30_Font", applyMirrorbar, nil),
				Color = self:NewColorNoAlpha("Name", "Mirror Name", 3, applyMirrorbar, nil),
				Size = self:NewSlider("Size", "Choose the Font Size for the Mirror Name Text.", 4, 1, 40, 1, applyMirrorbar, nil, nil),
				empty2 = self:NewDesc(" ", 5),
				OffsetX = self:NewInputNumber("X Value", "Choose the X Value for the Mirror Name Text.", 6, applyMirrorbar, nil),
				OffsetY = self:NewInputNumber("Y Value", "Choose the Y Value for the Mirror Name Text.", 7, applyMirrorbar, nil),
			}),
			Time = self:NewGroup("Time Settings", 2, true, {
				Font = self:NewSelect("Font", "Choose the Font for the Mirror Time Text.", 2, widgetLists.font, "LSM30_Font", applyMirrorbar, nil),
				Color = self:NewColorNoAlpha("Time", "Mirror Time", 3, applyMirrorbar, nil),
				Size = self:NewSlider("Size", "Choose the Font Size for the Mirror Time Text.", 4, 1, 40, 1, applyMirrorbar, nil, nil),
				empty2 = self:NewDesc(" ", 5),
				OffsetX = self:NewInputNumber("X Value", "Choose the X Value for the Mirror Time Text.", 6, applyMirrorbar, nil),
				OffsetY = self:NewInputNumber("Y Value", "Choose the Y Value for the Mirror Time Text.", 7, applyMirrorbar, nil),
			})
		}),
		Border = self:NewGroup("Border", 3, {
			Texture = self:NewSelect("Border Texture", "Choose the Border Texture.", 1, widgetLists.border, "LSM30_Border", applyMirrorbar),
			Color = self:NewColor("Border", "Border", 2, applyMirrorbar),
			Thickness = self:NewInputNumber("Border Thickness", "Value for your Castbar Border Thickness.", 3, applyMirrorbar),
			empty2 = self:NewDesc(" ", 4),
			Inset = self:NewGroup("Insets", 5, true, {
				left = self:NewInputNumber("Left", "Value for the left Border Inset.", 1, applyMirrorbar, "half"),
				right = self:NewInputNumber("Right", "Value for the right Border Inset.", 2, applyMirrorbar, "half"),
				top = self:NewInputNumber("Top", "Value for the top Border Inset.", 3, applyMirrorbar, "half"),
				bottom = self:NewInputNumber("Bottom", "Value for the bottom Border Inset.", 4, applyMirrorbar, "half"),
			}),
		}),
	}
	return options
end

------------------------------------------------------------------------
-- Functions
------------------------------------------------------------------------
local function formatTime(time)
	local hour = floor(time/3600)
	local min = floor(time/60)
	local sec = time%60

	if hour > 0 then
		return format('%d:%02d:%02d', hour, min, sec)
	elseif min > 0 then
		return format('%d:%02d', min, sec)
	else
		return format('%02d', sec)
	end
end

local function OnUpdate(self, elps)
	if PAUSED then return end

	if self.timer == "ARCHY" then
		if ( not CanScanResearchSite() ) then
			self:SetScript('OnUpdate', nil)
			self.timer = nil
			self:Hide()
		else
			local time = string.format("%s / %s", tostring(self.value), tostring(self.maxvalue))
			if self.Time then
				self.Time:SetText(time)
			end
		end
	else
		local time = GetMirrorTimerProgress(self.timer) / 1000
		time = (time < 0) and 0 or (time > self.maxvalue) and self.maxvalue or time
		self:SetValue(time)
		if self.Time then
			self.Time:SetText(formatTime(time))
		end
	end
end

local function UpdateBar(self, timers, timer, value, maxvalue, scale, paused, label)
	PAUSED = paused > 0
	local barname
	local bar = self.MirrorBar[timers]
	bar.timer = timer
	if bar.timer == "ARCHY" then
		bar.value = value
		bar.maxvalue = maxvalue
	else
		bar.value = value / 1000
		bar.maxvalue = maxvalue / 1000
	end
	bar.scale = scale
	bar.label = label
	if bar.Text then
		bar.Text:SetText(label)
		if label then
			if label == "Feign Death" then
				barname = "FeignBar"
			elseif label == "Breath" or label == "Fatigue" then
				barname = label.."Bar"
			elseif label == "Archaeology Progress" then
				barname = "ArchyBar"
			else
				barname = "Bar"
			end
		else
			barname = "Bar"
		end
	end
	local c = db.Colors[barname]
	bar:SetStatusBarColor(c.r, c.g, c.b, c.a)

	bar:SetMinMaxValues(0, maxvalue/1000)
	bar:SetValue(value/1000)

	bar:SetScript('OnUpdate', OnUpdate)
	bar:Show()
end

local function MIRROR_TIMER_START(self, event, timer, value, maxvalue, scale, paused, label)
	local timers
	for i = 1, MIRRORTIMER_NUMTIMERS do
		if self.MirrorBar[i].timer == timer then
			timers = i
			break
		elseif not self.MirrorBar[i]:IsShown() then
			timers = timers or i
		end
	end
	UpdateBar(self, timers, timer, value, maxvalue, scale, paused, label)
end

local function MIRROR_TIMER_STOP(self, event, timer)
	for i = 1, MIRRORTIMER_NUMTIMERS do
		if self.MirrorBar[i].timer == timer then
			self.MirrorBar[i].timer = nil
			self.MirrorBar[i]:Hide()
		end
	end
end

local function MIRROR_TIMER_PAUSE(self, event, paused)
	PAUSED = paused > 0
end

local function SURVEY_CAST(self, event, ...)
	local numFindsCompleted, totalFinds = ...;
	MIRROR_TIMER_START(self, "ARCHAEOLOGY_SURVEY_CAST", "ARCHY", numFindsCompleted, totalFinds, nil, 0, "Archaeology Progress")
end

local function SURVEY_COMPLETE(self, event, ...)
	local numFindsCompleted, totalFinds = ...;
	if numFindsCompleted == totalFinds then
		MIRROR_TIMER_STOP(self, "ARCHAEOLOGY_FIND_COMPLETE", "ARCHY")
	end
end

function module:ToggleArchy(...)
	if db.General.ArchyBar then
		if not ArcheologyDigsiteProgressBar then
			LoadAddOn("Blizzard_ArchaeologyUI")
		end
		self:RegisterEvent('ARCHAEOLOGY_SURVEY_CAST', SURVEY_CAST, self)
		self:RegisterEvent('ARCHAEOLOGY_FIND_COMPLETE', SURVEY_COMPLETE, self)
		UIParent:UnregisterEvent'ARCHAEOLOGY_SURVEY_CAST'
		if ArcheologyDigsiteProgressBar then
			ArcheologyDigsiteProgressBar:Hide()
			ArcheologyDigsiteProgressBar._Show = ArcheologyDigsiteProgressBar.Show
			ArcheologyDigsiteProgressBar.Show = ArcheologyDigsiteProgressBar.Hide
		end
	else
		MIRROR_TIMER_STOP(self, "ARCHAEOLOGY_FIND_COMPLETE", "ARCHY")
		self:UnregisterEvent('ARCHAEOLOGY_SURVEY_CAST', SURVEY_CAST)
		self:UnregisterEvent('ARCHAEOLOGY_FIND_COMPLETE', SURVEY_COMPLETE)
		UIParent:RegisterAllEvents'ARCHAEOLOGY_SURVEY_CAST'
		if ArcheologyDigsiteProgressBar then
			ArcheologyDigsiteProgressBar.Show = ArcheologyDigsiteProgressBar._Show
			ArcheologyDigsiteProgressBar._Show = nil
		end
	end
end

function module:Refresh(...)
	for i = 1, MIRRORTIMER_NUMTIMERS do
		if i == 1 then
			self.MirrorBar[i]:SetPoint('TOP', UIParent, db.General.X, db.General.Y)
		else
			self.MirrorBar[i]:SetPoint('TOP', self.MirrorBar[i-1], 'BOTTOM', 0, -db.General.BarGap)
		end
		self.MirrorBar[i]:SetHeight(db.General.Height)
		self.MirrorBar[i]:SetWidth(db.General.Width)
		self.MirrorBar[i]:SetStatusBarTexture(Media:Fetch("statusbar", db.General.Texture))
		local label = self.MirrorBar[i].Text:GetText()
		if label then
			if label == "Feign Death" then
				barname = "FeignBar"
			elseif label == "Breath" or label == "Fatigue" then
				barname = label.."Bar"
			elseif label == "Archaeology Progress" then
				barname = "ArchyBar"
			else
				barname = "Bar"
			end
		else
			barname = "Bar"
		end
		self.MirrorBar[i]:SetStatusBarColor(db.Colors[barname].r, db.Colors[barname].g, db.Colors[barname].b, db.Colors[barname].a)
		self.MirrorBar[i].bg:SetTexture(Media:Fetch("statusbar", db.General.TextureBG))
		self.MirrorBar[i].bg:SetVertexColor(db.Colors.Background.r,db.Colors.Background.g,db.Colors.Background.b, db.Colors.Background.a)
		self.MirrorBar[i].Backdrop:SetBackdrop({
			edgeFile = Media:Fetch("border", db.Border.Texture),
			edgeSize = db.Border.Thickness,
			insets = {
				left = db.Border.Inset.left,
				right = db.Border.Inset.right,
				top = db.Border.Inset.top,
				bottom = db.Border.Inset.bottom,
			}
		})
		self.MirrorBar[i].Backdrop:SetBackdropBorderColor(db.Border.Color.r, db.Border.Color.g, db.Border.Color.b,db.Border.Color.a)
		self.MirrorBar[i].Text:SetFont(Media:Fetch("font", db.Text.Name.Font), db.Text.Name.Size, 'OUTLINE')
		self.MirrorBar[i].Text:SetTextColor(db.Text.Name.Color.r, db.Text.Name.Color.g, db.Text.Name.Color.b)
		self.MirrorBar[i].Text:SetPoint('CENTER', self.MirrorBar[i], db.Text.Name.OffsetX, db.Text.Name.OffsetY)
		self.MirrorBar[i].Time:SetFont(Media:Fetch("font", db.Text.Time.Font), db.Text.Time.Size, 'OUTLINE')
		self.MirrorBar[i].Time:SetTextColor(db.Text.Time.Color.r, db.Text.Time.Color.g, db.Text.Time.Color.b)
		self.MirrorBar[i].Time:SetPoint('RIGHT', self.MirrorBar[i], db.Text.Time.OffsetX, db.Text.Time.OffsetY)
	end
end

function module:CreateMirrorbars(self)
	local mirrorbar = self.MirrorBar
	if not mirrorbar then
		self.MirrorBar = {}
		for i = 1, MIRRORTIMER_NUMTIMERS do
			self.MirrorBar[i] = CreateFrame('StatusBar', nil, UIParent)
			self.MirrorBar[i].Text = self.MirrorBar[i]:CreateFontString(nil, 'OVERLAY')
			self.MirrorBar[i].Time = self.MirrorBar[i]:CreateFontString(nil, 'OVERLAY')
			self.MirrorBar[i].bg = self.MirrorBar[i]:CreateTexture(nil, 'BORDER')
			self.MirrorBar[i].bg:SetAllPoints(self.MirrorBar[i])
			self.MirrorBar[i].Backdrop = CreateFrame("Frame", nil, self.MirrorBar[i])
			self.MirrorBar[i].Backdrop:SetPoint("TOPLEFT", self.MirrorBar[i], "TOPLEFT", -4, 3)
			self.MirrorBar[i].Backdrop:SetPoint("BOTTOMRIGHT", self.MirrorBar[i], "BOTTOMRIGHT", 3, -3.5)
			self.MirrorBar[i].Backdrop:SetParent(self.MirrorBar[i])
		end
	end
	for i = 1, MIRRORTIMER_NUMTIMERS do
		if i == 1 then
			self.MirrorBar[i]:SetPoint('TOP', UIParent, db.General.X, db.General.Y)
		else
			self.MirrorBar[i]:SetPoint('TOP', self.MirrorBar[i-1], 'BOTTOM', 0, -db.General.BarGap)
		end
		self.MirrorBar[i]:SetHeight(db.General.Height)
		self.MirrorBar[i]:SetWidth(db.General.Width)
		self.MirrorBar[i]:SetStatusBarTexture(Media:Fetch("statusbar", db.General.Texture))
		self.MirrorBar[i]:SetStatusBarColor(db.Colors.Bar.r, db.Colors.Bar.g, db.Colors.Bar.b, db.Colors.Bar.a)
		self.MirrorBar[i].bg:SetTexture(Media:Fetch("statusbar", db.General.TextureBG))
		self.MirrorBar[i].bg:SetVertexColor(db.Colors.Background.r,db.Colors.Background.g,db.Colors.Background.b, db.Colors.Background.a)
		self.MirrorBar[i].Backdrop:SetBackdrop({
			edgeFile = Media:Fetch("border", db.Border.Texture),
			edgeSize = db.Border.Thickness,
			insets = {
				left = db.Border.Inset.left,
				right = db.Border.Inset.right,
				top = db.Border.Inset.top,
				bottom = db.Border.Inset.bottom,
			}
		})
		self.MirrorBar[i].Backdrop:SetBackdropBorderColor(db.Border.Color.r, db.Border.Color.g, db.Border.Color.b,db.Border.Color.a)
		self.MirrorBar[i].Text:SetFont(Media:Fetch("font", db.Text.Name.Font), db.Text.Name.Size, 'OUTLINE')
		self.MirrorBar[i].Text:SetTextColor(db.Text.Name.Color.r, db.Text.Name.Color.g, db.Text.Name.Color.b)
		self.MirrorBar[i].Text:SetPoint('CENTER', self.MirrorBar[i], db.Text.Name.OffsetX, db.Text.Name.OffsetY)
		self.MirrorBar[i].Time:SetFont(Media:Fetch("font", db.Text.Time.Font), db.Text.Time.Size, 'OUTLINE')
		self.MirrorBar[i].Time:SetTextColor(db.Text.Time.Color.r, db.Text.Time.Color.g, db.Text.Time.Color.b)
		self.MirrorBar[i].Time:SetPoint('RIGHT', self.MirrorBar[i], db.Text.Time.OffsetX, db.Text.Time.OffsetY)
	end
end

------------------------------------------------------------------------
-- Module Initialization
------------------------------------------------------------------------
function module:OnInitialize()
	db, dbd = LUI:NewNamespace(self, true)
	local ProfileName = UnitName("player").." - "..GetRealmName()

	if LUI.db.global.luiconfig[ProfileName].Versions.mirrorbar ~= LUI.Versions.mirrorbar then
		db:ResetProfile()
		LUI.db.global.luiconfig[ProfileName].Versions.mirrorbar = LUI.Versions.mirrorbar
	end
end

function module:OnEnable()
	for i = 1, MIRRORTIMER_NUMTIMERS do
		local f = _G['MirrorTimer'..i]
		f:UnregisterAllEvents()
	end
	UIParent:UnregisterEvent'MIRROR_TIMER_START'
	module:CreateMirrorbars(self)
	for i = 1, MIRRORTIMER_NUMTIMERS do
		self.MirrorBar[i]:Hide()
	end

	self:RegisterEvent('MIRROR_TIMER_START', MIRROR_TIMER_START, self)
	self:RegisterEvent('MIRROR_TIMER_STOP', MIRROR_TIMER_STOP, self)
	self:RegisterEvent('MIRROR_TIMER_PAUSE', MIRROR_TIMER_PAUSE, self)
	-- Archaeology Update
	if db.General.ArchyBar then
		if not ArcheologyDigsiteProgressBar then
			LoadAddOn("Blizzard_ArchaeologyUI")
		end
		if ArcheologyDigsiteProgressBar then
			ArcheologyDigsiteProgressBar:Hide()
			ArcheologyDigsiteProgressBar._Show = ArcheologyDigsiteProgressBar.Show
			ArcheologyDigsiteProgressBar.Show = ArcheologyDigsiteProgressBar.Hide
		end
		UIParent:UnregisterEvent'ARCHAEOLOGY_SURVEY_CAST'
		self:RegisterEvent('ARCHAEOLOGY_SURVEY_CAST', SURVEY_CAST, self)
		self:RegisterEvent('ARCHAEOLOGY_FIND_COMPLETE', SURVEY_COMPLETE, self)
	end
end

function module:OnDisable()
	for i = 1, MIRRORTIMER_NUMTIMERS do
		local f = _G['MirrorTimer'..i]
		f:Hide()
		f:RegisterAllEvents'MIRROR_TIMER_PAUSE'
		f:RegisterAllEvents'MIRROR_TIMER_STOP'
		f:RegisterAllEvents'PLAYER_ENTERING_WORLD'
	end
	UIParent:RegisterEvent'MIRROR_TIMER_START'

	self:UnregisterEvent('MIRROR_TIMER_START', MIRROR_TIMER_START)
	self:UnregisterEvent('MIRROR_TIMER_STOP', MIRROR_TIMER_STOP)
	self:UnregisterEvent('MIRROR_TIMER_PAUSE', MIRROR_TIMER_PAUSE)
	-- Archaeology Update
	UIParent:RegisterAllEvents'ARCHAEOLOGY_SURVEY_CAST'
	if ArcheologyDigsiteProgressBar and ArcheologyDigsiteProgressBar._Show then
		ArcheologyDigsiteProgressBar.Show = ArcheologyDigsiteProgressBar._Show
		ArcheologyDigsiteProgressBar._Show = nil
	end
	MIRROR_TIMER_STOP(self, "ARCHAEOLOGY_FIND_COMPLETE", "ARCHY")
	self:UnregisterEvent('ARCHAEOLOGY_SURVEY_CAST', SURVEY_CAST)
	self:UnregisterEvent('ARCHAEOLOGY_FIND_COMPLETE', SURVEY_COMPLETE)
end
