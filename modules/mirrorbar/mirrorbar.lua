-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.MirrorBar: LUIModule
local module = LUI:NewModule("Mirror Bar", "LUIDevAPI")
module.enableButton = true
local db

local Media = LibStub("LibSharedMedia-3.0")

local GetMirrorTimerInfo = _G.GetMirrorTimerInfo
local GetMirrorTimerProgress = _G.GetMirrorTimerProgress
local CanScanResearchSite = _G.CanScanResearchSite
local format = string.format
local floor = math.floor

local MIRRORTIMER_NUMTIMERS = 3 -- MirrorTimer.lua -> numMirrorTimerTypes

local BLIZZARD_MIRROR_EVENTS = {
	"PLAYER_ENTERING_WORLD",
	"MIRROR_TIMER_START",
	"MIRROR_TIMER_STOP",
	"MIRROR_TIMER_PAUSE",
}

-- ####################################################################################################################
-- ##### Default Settings #############################################################################################
-- ####################################################################################################################

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
			Bar = { r = 0.13, g = 0.59, b = 1, a = 0.7, },
			FatigueBar = { r = 1, g = 1, b = 0.5, a = 0.7, },
			BreathBar = { r = 0, g = 0.6, b = 1, a = 0.7, },
			FeignBar = { r = 0.92, g = 0.63, b = 0, a = 0.7, },
			ArchyBar = { r = 1, g = .3, b = .4, a = 0.7, },
			Background = { r = 0.15, g = 0.15, b = 0.15, a = 0.67, },
		},
		Text = {
			Name = { Font = "NotoSans-SCB", Size = 13, OffsetX = 5, OffsetY = 1, Color = { r = 0.9, g = 0.9, b = 0.9, } },
			Time = { Font = "NotoSans-SCB", Size = 13, OffsetX = -5, OffsetY = 1, Color = { r = 0.9, g = 0.9, b = 0.9, } },
		},
		Border = {
			Texture = "glow",
			Thickness = 4,
			Color = { r = 0.9, g = 0.9, b = 0.9, a = 0.65, },
			Inset = { left = 2, right = 2, top = 2, bottom = 2, },
		},
	},
}

local function formatTime(time)
	local hour = floor(time / 3600)
	local min = floor(time / 60) % 60
	local sec = floor(time % 60)

	if hour > 0 then
		return format("%d:%02d:%02d", hour, min, sec)
	elseif min > 0 then
		return format("%d:%02d", min, sec)
	else
		return format("%02d", sec)
	end
end

local function GetBarColorKey(timer)
	if timer == "FEIGNDEATH" then
		return "FeignBar"
	elseif timer == "BREATH" then
		return "BreathBar"
	elseif timer == "FATIGUE" then
		return "FatigueBar"
	elseif timer == "ARCHY" then
		return "ArchyBar"
	end
	return "Bar"
end

local function OnUpdate(self)
	if self.paused then return end

	if self.timer == "ARCHY" then
		if not CanScanResearchSite() then
			if _G.ArcheologyDigsiteProgressBar then
				_G.ArcheologyDigsiteProgressBar.shouldShow = false
			end
			self:SetScript("OnUpdate", nil)
			self.timer = nil
			self:Hide()
		elseif self.Time then
			self.Time:SetText(format("%s / %s", tostring(self.value), tostring(self.maxvalue)))
		end
	else
		local progress = GetMirrorTimerProgress(self.timer)
		if not progress then return end
		local time = progress / 1000
		time = time < 0 and 0 or time > self.maxvalue and self.maxvalue or time
		self:SetValue(time)
		if self.Time then
			self.Time:SetText(formatTime(time))
		end
	end
end

local function UpdateBar(self, index, timer, value, maxvalue, scale, paused, label)
	local bar = self.MirrorBar[index]
	bar.timer = timer
	bar.paused = paused > 0

	if timer == "ARCHY" then
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
	end

	local color = db.Colors[GetBarColorKey(timer)]
	bar:SetStatusBarColor(color.r, color.g, color.b, color.a)
	bar:SetMinMaxValues(0, bar.maxvalue)
	bar:SetValue(bar.value)
	bar:SetScript("OnUpdate", OnUpdate)
	bar:Show()
end

local function MIRROR_TIMER_START(self, event, timer, value, maxvalue, scale, paused, label)
	local available
	for i = 1, MIRRORTIMER_NUMTIMERS do
		if self.MirrorBar[i].timer == timer then
			available = i
			break
		elseif not self.MirrorBar[i]:IsShown() then
			available = available or i
		end
	end

	if available then
		UpdateBar(self, available, timer, value, maxvalue, scale, paused, label)
	end
end

local function MIRROR_TIMER_STOP(self, event, timer)
	for i = 1, MIRRORTIMER_NUMTIMERS do
		if self.MirrorBar[i].timer == timer then
			self.MirrorBar[i].timer = nil
			self.MirrorBar[i].paused = nil
			self.MirrorBar[i]:SetScript("OnUpdate", nil)
			self.MirrorBar[i]:Hide()
		end
	end
end

local function MIRROR_TIMER_PAUSE(self, event, timer, paused)
	for i = 1, MIRRORTIMER_NUMTIMERS do
		if self.MirrorBar[i].timer == timer then
			self.MirrorBar[i].paused = paused > 0
			break
		end
	end
end

local function SURVEY_CAST(self, event, numFindsCompleted, totalFinds)
	if _G.ArcheologyDigsiteProgressBar then
		_G.ArcheologyDigsiteProgressBar.shouldShow = true
	end
	MIRROR_TIMER_START(self, event, "ARCHY", numFindsCompleted, totalFinds, nil, 0, "Archaeology Progress")
end

local function SURVEY_COMPLETE(self, event, numFindsCompleted, totalFinds)
	if numFindsCompleted == totalFinds then
		MIRROR_TIMER_STOP(self, event, "ARCHY")
	else
		MIRROR_TIMER_START(self, event, "ARCHY", numFindsCompleted, totalFinds, nil, 0, "Archaeology Progress")
	end
end

local function DIGSITE_COMPLETE(self, event, researchFieldID)
	MIRROR_TIMER_STOP(self, event, "ARCHY")
	if _G.ArcheologyDigsiteProgressBar then
		_G.ArcheologyDigsiteProgressBar.shouldShow = false
	end
	if _G.DigsiteCompleteAlertSystem and _G.GetArchaeologyRaceInfoByID then
		_G.DigsiteCompleteAlertSystem:AddAlert(_G.GetArchaeologyRaceInfoByID(researchFieldID))
	end
end

local function RestoreArchaeologyBar()
	local archaeologyBar = _G.ArcheologyDigsiteProgressBar
	if not archaeologyBar then return end

	LUI:Unkill(archaeologyBar)
	archaeologyBar:RegisterEvent("ARCHAEOLOGY_SURVEY_CAST")
	archaeologyBar:UnregisterEvent("ARCHAEOLOGY_FIND_COMPLETE")
	archaeologyBar:UnregisterEvent("ARTIFACT_DIGSITE_COMPLETE")
	if archaeologyBar.UpdateShownState then
		archaeologyBar:UpdateShownState()
	end
end

function module:ToggleArchy()
	if not self:IsEnabled() then return end

	local archaeologyBar = _G.ArcheologyDigsiteProgressBar
	if db.General.ArchyBar then
		if not archaeologyBar then return end
		LUI:Kill(archaeologyBar)
		archaeologyBar:UnregisterEvent('ARCHAEOLOGY_SURVEY_CAST')
		archaeologyBar:UnregisterEvent('ARCHAEOLOGY_FIND_COMPLETE')
		archaeologyBar:UnregisterEvent('ARTIFACT_DIGSITE_COMPLETE')
		self:RegisterEvent('ARCHAEOLOGY_SURVEY_CAST', SURVEY_CAST, self)
		self:RegisterEvent('ARCHAEOLOGY_FIND_COMPLETE', SURVEY_COMPLETE, self)
		self:RegisterEvent('ARTIFACT_DIGSITE_COMPLETE', DIGSITE_COMPLETE, self)
	else
		MIRROR_TIMER_STOP(self, "ARCHAEOLOGY_FIND_COMPLETE", "ARCHY")
		self:UnregisterEvent('ARCHAEOLOGY_SURVEY_CAST', SURVEY_CAST)
		self:UnregisterEvent('ARCHAEOLOGY_FIND_COMPLETE', SURVEY_COMPLETE)
		self:UnregisterEvent('ARTIFACT_DIGSITE_COMPLETE', DIGSITE_COMPLETE)
		RestoreArchaeologyBar()
	end
end

local function DisableBlizzardMirrorTimers()
	local container = _G.MirrorTimerContainer
	if not container then return end

	for i = 1, #BLIZZARD_MIRROR_EVENTS do
		container:UnregisterEvent(BLIZZARD_MIRROR_EVENTS[i])
	end

	if container.activeTimers and container.ClearTimer then
		local active = {}
		for timer in pairs(container.activeTimers) do
			active[#active + 1] = timer
		end
		for i = 1, #active do
			container:ClearTimer(active[i])
		end
	end
end

local function RestoreBlizzardMirrorTimers()
	local container = _G.MirrorTimerContainer
	if not container then return end

	for i = 1, #BLIZZARD_MIRROR_EVENTS do
		container:RegisterEvent(BLIZZARD_MIRROR_EVENTS[i])
	end
	if container.OnEvent then
		container:OnEvent("PLAYER_ENTERING_WORLD")
	end
end

local function LoadActiveMirrorTimers(self)
	for i = 1, MIRRORTIMER_NUMTIMERS do
		local timer, value, maxvalue, scale, paused, label = GetMirrorTimerInfo(i)
		if timer and timer ~= "UNKNOWN" then
			MIRROR_TIMER_START(self, "PLAYER_ENTERING_WORLD", timer, value, maxvalue, scale, paused, label)
		end
	end
end

function module:Refresh(...)
	for i = 1, MIRRORTIMER_NUMTIMERS do
		self.MirrorBar[i]:ClearAllPoints()
		if i == 1 then
			self.MirrorBar[i]:SetPoint('TOP', UIParent, db.General.X, db.General.Y)
		else
			self.MirrorBar[i]:SetPoint('TOP', self.MirrorBar[i-1], 'BOTTOM', 0, -db.General.BarGap)
		end
		self.MirrorBar[i]:SetHeight(db.General.Height)
		self.MirrorBar[i]:SetWidth(db.General.Width)
		self.MirrorBar[i]:SetStatusBarTexture(Media:Fetch("statusbar", db.General.Texture))
		local barname = GetBarColorKey(self.MirrorBar[i].timer)
		local color = db.Colors[barname]
		self.MirrorBar[i]:SetStatusBarColor(color.r, color.g, color.b, color.a)
		self.MirrorBar[i].bg:SetTexture(Media:Fetch("statusbar", db.General.TextureBG))
		self.MirrorBar[i].bg:SetVertexColor(db.Colors.Background.r,db.Colors.Background.g,db.Colors.Background.b, db.Colors.Background.a)
		LUI:ApplyFrameBackdrop(self.MirrorBar[i].Backdrop, {
			edgeFile = Media:Fetch("border", db.Border.Texture),
			edgeSize = db.Border.Thickness,
			insets = {
				left = db.Border.Inset.left,
				right = db.Border.Inset.right,
				top = db.Border.Inset.top,
				bottom = db.Border.Inset.bottom,
			}
		})
		LUI:SetFrameBorderColor(self.MirrorBar[i].Backdrop, db.Border.Color.r, db.Border.Color.g, db.Border.Color.b, db.Border.Color.a)
		self.MirrorBar[i].Text:SetFont(Media:Fetch("font", db.Text.Name.Font), db.Text.Name.Size, 'OUTLINE')
		self.MirrorBar[i].Text:SetTextColor(db.Text.Name.Color.r, db.Text.Name.Color.g, db.Text.Name.Color.b)
		self.MirrorBar[i].Text:ClearAllPoints()
		self.MirrorBar[i].Text:SetPoint('CENTER', self.MirrorBar[i], db.Text.Name.OffsetX, db.Text.Name.OffsetY)
		self.MirrorBar[i].Time:SetFont(Media:Fetch("font", db.Text.Time.Font), db.Text.Time.Size, 'OUTLINE')
		self.MirrorBar[i].Time:SetTextColor(db.Text.Time.Color.r, db.Text.Time.Color.g, db.Text.Time.Color.b)
		self.MirrorBar[i].Time:ClearAllPoints()
		self.MirrorBar[i].Time:SetPoint('RIGHT', self.MirrorBar[i], db.Text.Time.OffsetX, db.Text.Time.OffsetY)
	end
end

function module:CreateMirrorbars()
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
	self:Refresh()
end

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################
function module:OnInitialize()
	db = LUI:NewNamespace(self, true)
	LUI:RegisterModule(self, true)
end

function module:OnEnable()
	DisableBlizzardMirrorTimers()
	module:CreateMirrorbars()
	for i = 1, MIRRORTIMER_NUMTIMERS do
		self.MirrorBar[i]:Hide()
	end

	self:RegisterEvent('MIRROR_TIMER_START', MIRROR_TIMER_START, self)
	self:RegisterEvent('MIRROR_TIMER_STOP', MIRROR_TIMER_STOP, self)
	self:RegisterEvent('MIRROR_TIMER_PAUSE', MIRROR_TIMER_PAUSE, self)
	LoadActiveMirrorTimers(self)
	if db.General.ArchyBar then self:ToggleArchy() end
end

function module:OnDisable()
	self:UnregisterEvent('MIRROR_TIMER_START', MIRROR_TIMER_START)
	self:UnregisterEvent('MIRROR_TIMER_STOP', MIRROR_TIMER_STOP)
	self:UnregisterEvent('MIRROR_TIMER_PAUSE', MIRROR_TIMER_PAUSE)

	RestoreArchaeologyBar()

	for i = 1, MIRRORTIMER_NUMTIMERS do
		local bar = self.MirrorBar and self.MirrorBar[i]
		if bar then
			bar.timer = nil
			bar.paused = nil
			bar:SetScript("OnUpdate", nil)
			bar:Hide()
		end
	end
	self:UnregisterEvent('ARCHAEOLOGY_SURVEY_CAST', SURVEY_CAST)
	self:UnregisterEvent('ARCHAEOLOGY_FIND_COMPLETE', SURVEY_COMPLETE)
	self:UnregisterEvent('ARTIFACT_DIGSITE_COMPLETE', DIGSITE_COMPLETE)
	RestoreBlizzardMirrorTimers()
end
