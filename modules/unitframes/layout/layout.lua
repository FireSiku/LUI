------------------------------------------------------------------------
--	oUF LUI Layout
--	Version 3.6.1
-- 	Date: 08/30/2011
--	DO NOT USE THIS LAYOUT WITHOUT LUI
------------------------------------------------------------------------

local addonname, LUI = ...
local module = LUI:GetModule("Unitframes")

local Media = LibStub("LibSharedMedia-3.0")
local oUF = LUI.oUF
local L = LUI.L
local db

local UnitHealth, UnitHealthMax, UnitPower, UnitPowerMax = _G.UnitHealth, _G.UnitHealthMax, _G.UnitPower, _G.UnitPowerMax
local UnitIsUnit, UnitExists, UnitIsGhost, UnitIsDead = _G.UnitIsUnit, _G.UnitExists, _G.UnitIsGhost, _G.UnitIsDead
local UnitName, UnitGUID, UnitIsPVP, UnitReaction = _G.UnitName, _G.UnitGUID, _G.UnitIsPVP, _G.UnitReaction
local UnitIsPlayer, UnitIsEnemy, UnitIsTapDenied = _G.UnitIsPlayer, _G.UnitIsEnemy, _G.UnitIsTapDenied
local GetSpellInfo, GetTalentInfo, GetTotemInfo = _G.GetSpellInfo, _G.GetTalentInfo, _G.GetTotemInfo
local UnitIsVisible, UnitIsConnected, UnitIsAFK = _G.UnitIsVisible, _G.UnitIsConnected, _G.UnitIsAFK
local GetThreatStatusColor, UnitThreatSituation = _G.GetThreatStatusColor, _G.UnitThreatSituation
local UnitPowerType, GetUnitPowerBarTextureInfo = _G.UnitPowerType, _G.GetUnitPowerBarTextureInfo
local UnitClass, UnitLevel, GetSpecialization = _G.UnitClass, _G.UnitLevel, _G.GetSpecialization
local UnitAura, UnitDebuff, DebuffTypeColor = _G.UnitAura, _G.UnitDebuff, _G.DebuffTypeColor
local SetPortraitTexture, UnitHasVehicleUI = _G.SetPortraitTexture, _G.UnitHasVehicleUI
local GetComboPoints, GetShapeshiftFormID = _G.GetComboPoints, _G.GetShapeshiftFormID
local UnitSpellHaste, UnitChannelInfo = _G.UnitSpellHaste, _G.UnitChannelInfo
local GetPVPTimer, GetGlyphSocketInfo =_G.GetPVPTimer, _G.GetGlyphSocketInfo
local format = string.format
local floor = math.floor

local ALT_MANA_BAR_PAIR_DISPLAY_INFO = _G.ALT_MANA_BAR_PAIR_DISPLAY_INFO
local ADDITIONAL_POWER_BAR_INDEX = _G.ADDITIONAL_POWER_BAR_INDEX
local GameFontHighlight = _G.GameFontHighlight
local NUM_CHAT_WINDOWS = _G.NUM_CHAT_WINDOWS
local MAX_PLAYER_LEVEL = _G.MAX_PLAYER_LEVEL
local MAX_COMBO_POINTS = _G.MAX_COMBO_POINTS
local MAX_TOTEMS = _G.MAX_TOTEMS

local standings = {"Hated", "Hostile", "Unfriendly", "Neutral", "Friendly", "Honored", "Revered", "Exalted"}

------------------------------------------------------------------------
--	Textures and Medias
------------------------------------------------------------------------

local mediaPath = [=[Interface\Addons\LUI\media\]=]

local highlightTex = [=[Interface\Addons\LUI\media\textures\statusbars\highlightTex]=]
local normTex = LUI.Media.normTex
local glowTex = LUI.Media.glowTex
local blankTex = LUI.Media.blank
local buttonTex = [=[Interface\Addons\LUI\media\textures\buttonTex]=]
local aggroTex = [=[Interface\Addons\LUI\media\textures\aggro]=]

module.backdrop = {
	bgFile = blankTex,
	insets = {top = -1, left = -1, bottom = -1, right = -1},
}

module.backdrop2 = {
	bgFile = blankTex,
	edgeFile = blankTex,
	tile = false, tileSize = 0, edgeSize = 1,
	insets = {top = -1, left = -1, bottom = -1, right = -1},
}

local font = [=[Interface\Addons\LUI\media\fonts\vibrocen.ttf]=]
local fontn = [=[Interface\Addons\LUI\media\fonts\KhmerUI.ttf]=]
local font2 = [=[Interface\Addons\LUI\media\Fonts\ARIALN.ttf]=]
local font3 = [=[Interface\Addons\LUI\media\fonts\Prototype.ttf]=]

local highlight = true

------------------------------------------------------------------------
--	Dont edit this if you dont know what you are doing!
------------------------------------------------------------------------

function module.SetFontString(parent, fontName, fontHeight, fontStyle)
	local fs = parent:CreateFontString(nil, "OVERLAY")
	fs:SetFont(fontName, fontHeight, fontStyle or "")
	fs:SetJustifyH("LEFT")
	fs:SetShadowColor(0, 0, 0)
	fs:SetShadowOffset(1.25, -1.25)
	return fs
end

function module.FormatTime(s)
	local day, hour, minute = 86400, 3600, 60
	if s >= day then
		return format("%dd", floor(s/day + 1)), s % day
	elseif s >= hour then
		return format("%dh", floor(s/hour + 1)), s % hour
	elseif s >= minute then
		if s <= minute * 1 then
			return format("%d:%02d", floor(s/60), s % minute), s - floor(s)
		end
		return format("%dm", floor(s/minute + 1)), s % minute
	end
	return format("%.1f", s), (s * 100 - floor(s * 100))/100
end

function module.ShortValue(value)
	if value >= 1e6 then
		return ("%.1fm"):format(value / 1e6):gsub("%.?0+([km])$", "%1")
	elseif value >= 1e3 or value <= -1e3 then
		return ("%.1fk"):format(value / 1e3):gsub("%.?0+([km])$", "%1")
	else
		return value
	end
end

local function ThreatOverride(self, event, unit)
	if unit ~= self.unit then return end
	if unit == "vehicle" then unit = "player" end

	unit = unit or self.unit
	local status = UnitThreatSituation(unit)

	if(status and status > 0) then
		local r, g, b = GetThreatStatusColor(status)
		for i = 1, 8 do
			self.ThreatIndicator[i]:SetVertexColor(r, g, b)
		end
		self.ThreatIndicator:Show()
	else
		self.ThreatIndicator:Hide()
	end
end

local function PortraitOverride(self, event, unit)
	if not unit or not UnitIsUnit(self.unit, unit) then return end

	local portrait = self.Portrait

	if(portrait:IsObjectType"Model") then
		local guid = UnitGUID(unit)
		if not UnitExists(unit) or not UnitIsConnected(unit) or not UnitIsVisible(unit) then
			portrait:SetModelScale(4.25)
			portrait:SetPosition(0, 0, -1.5)
			portrait:SetModel("Interface\\Buttons\\talktomequestionmark.mdx")
			portrait.guid = nil
		elseif(portrait.guid ~= guid or event == "UNIT_MODEL_CHANGED") then
			portrait:SetUnit(unit)
			portrait:SetCamera(portrait:GetModel() == "character\\worgen\\male\\worgenmale.m2" and 1 or 0)

			portrait.guid = guid
		else
			portrait:SetCamera(portrait:GetModel() == "character\\worgen\\male\\worgenmale.m2" and 1 or 0)
		end
	else
		SetPortraitTexture(portrait, unit)
	end

	local a = portrait:GetAlpha()
	portrait:SetAlpha(0)
	portrait:SetAlpha(a)
end

local function Reposition(V2Tex)
	local to = V2Tex.to
	local from = V2Tex.from

	local toL, toR = to:GetLeft(), to:GetRight()
	local toT, toB = to:GetTop(), to:GetBottom()
	local toCX, toCY = to:GetCenter()
	local toS = to:GetEffectiveScale()

	local fromL, fromR = from:GetLeft(), from:GetRight()
	local fromT, fromB = from:GetTop(), from:GetBottom()
	local fromCX, fromCY = from:GetCenter()
	local fromS = from:GetEffectiveScale()

	if not (toL and toR and toT and toB and toCX and toCY and toS and fromL and fromR and fromT and fromB and fromCX and fromCY and fromS) then return end

	toL, toR = toL * toS, toR * toS
	toT, toB = toT * toS, toB * toS
	toCX, toCY = toCX * toS, toCY * toS

	fromL, fromR = fromL * fromS, fromR * fromS
	--fromT, fromB = fromT * fromS, fromB * fromS
	fromCX, fromCY = fromCX * fromS, fromCY * fromS

	local magicValue = to:GetWidth() / 6

	V2Tex:ClearAllPoints()
	V2Tex.Vertical:ClearAllPoints()
	V2Tex.Horizontal:ClearAllPoints()
	V2Tex.Horizontal2:ClearAllPoints()
	V2Tex.Dot:ClearAllPoints()

	V2Tex:Show()
	V2Tex.Vertical:Show()
	V2Tex.Horizontal:Show()
	V2Tex.Horizontal2:Show()
	V2Tex.Dot:Show()

	if fromL > toR - magicValue then
		V2Tex.Dot:SetPoint("CENTER", V2Tex.Horizontal2, "RIGHT")

		V2Tex.Horizontal2:SetPoint("LEFT", from, "RIGHT")
		V2Tex.Horizontal2:SetWidth(fromL - toR + magicValue)

		if fromCY < toB then
			V2Tex.Vertical:SetPoint("TOPLEFT", V2Tex, "TOPLEFT")
			V2Tex.Vertical:SetPoint("BOTTOMLEFT", V2Tex, "BOTTOMLEFT")

			V2Tex.Horizontal:SetPoint("BOTTOMLEFT", V2Tex, "BOTTOMLEFT")
			V2Tex.Horizontal:SetPoint("BOTTOMRIGHT", V2Tex, "BOTTOMRIGHT")

			V2Tex:SetPoint("TOPLEFT", to, "BOTTOMRIGHT", -magicValue, 0)
			V2Tex:SetPoint("BOTTOMRIGHT", from, "LEFT", 0, -1)
		elseif fromCY > toT then
			V2Tex.Vertical:SetPoint("TOPLEFT", V2Tex, "TOPLEFT")
			V2Tex.Vertical:SetPoint("BOTTOMLEFT", V2Tex, "BOTTOMLEFT")

			V2Tex.Horizontal:SetPoint("TOPLEFT", V2Tex, "TOPLEFT")
			V2Tex.Horizontal:SetPoint("TOPRIGHT", V2Tex, "TOPRIGHT")

			V2Tex:SetPoint("BOTTOMLEFT", to, "TOPRIGHT", -magicValue, 0)
			V2Tex:SetPoint("TOPRIGHT", from, "LEFT", 0, 1)
		elseif fromCY > toCY then
			V2Tex.Vertical:Hide()

			V2Tex.Horizontal:SetPoint("TOPLEFT", V2Tex, "TOPLEFT")
			V2Tex.Horizontal:SetPoint("TOPRIGHT", V2Tex, "TOPRIGHT")

			V2Tex:SetPoint("TOPLEFT", to, "RIGHT", 0, 1)
			V2Tex:SetPoint("BOTTOMRIGHT", from, "LEFT", 0, -1)
		else
			V2Tex.Vertical:Hide()

			V2Tex.Horizontal:SetPoint("BOTTOMLEFT", V2Tex, "BOTTOMLEFT")
			V2Tex.Horizontal:SetPoint("BOTTOMRIGHT", V2Tex, "BOTTOMRIGHT")

			V2Tex:SetPoint("BOTTOMLEFT", to, "RIGHT", 0, -1)
			V2Tex:SetPoint("TOPRIGHT", from, "LEFT", 0, 1)
		end
	elseif toL > fromR - magicValue then
		V2Tex.Dot:SetPoint("CENTER", V2Tex.Horizontal2, "LEFT")

		V2Tex.Horizontal2:SetPoint("RIGHT", from, "LEFT")
		V2Tex.Horizontal2:SetWidth(toL - fromR + magicValue)

		if fromCY < toB then
			V2Tex.Vertical:SetPoint("TOPRIGHT", V2Tex, "TOPRIGHT")
			V2Tex.Vertical:SetPoint("BOTTOMRIGHT", V2Tex, "BOTTOMRIGHT")

			V2Tex.Horizontal:SetPoint("BOTTOMLEFT", V2Tex, "BOTTOMLEFT")
			V2Tex.Horizontal:SetPoint("BOTTOMRIGHT", V2Tex, "BOTTOMRIGHT")

			V2Tex:SetPoint("TOPRIGHT", to, "BOTTOMLEFT", magicValue, 0)
			V2Tex:SetPoint("BOTTOMLEFT", from, "RIGHT", 0, -1)
		elseif fromCY > toT then
			V2Tex.Vertical:SetPoint("TOPRIGHT", V2Tex, "TOPRIGHT")
			V2Tex.Vertical:SetPoint("BOTTOMRIGHT", V2Tex, "BOTTOMRIGHT")

			V2Tex.Horizontal:SetPoint("TOPLEFT", V2Tex, "TOPLEFT")
			V2Tex.Horizontal:SetPoint("TOPRIGHT", V2Tex, "TOPRIGHT")

			V2Tex:SetPoint("BOTTOMRIGHT", to, "TOPLEFT", magicValue, 0)
			V2Tex:SetPoint("TOPLEFT", from, "RIGHT", 0, 1)
		elseif fromCY > toCY then
			V2Tex.Vertical:Hide()

			V2Tex.Horizontal:SetPoint("TOPLEFT", V2Tex, "TOPLEFT")
			V2Tex.Horizontal:SetPoint("TOPRIGHT", V2Tex, "TOPRIGHT")

			V2Tex:SetPoint("TOPRIGHT", to, "LEFT", 0, 1)
			V2Tex:SetPoint("BOTTOMLEFT", from, "RIGHT", 0, -1)
		else
			V2Tex.Vertical:Hide()

			V2Tex.Horizontal:SetPoint("BOTTOMLEFT", V2Tex, "BOTTOMLEFT")
			V2Tex.Horizontal:SetPoint("BOTTOMRIGHT", V2Tex, "BOTTOMRIGHT")

			V2Tex:SetPoint("BOTTOMRIGHT", to, "LEFT", 0, -1)
			V2Tex:SetPoint("TOPLEFT", from, "RIGHT", 0, 1)
		end
	else
		V2Tex.Vertical:SetPoint("TOP", V2Tex, "TOP")
		V2Tex.Vertical:SetPoint("BOTTOM", V2Tex, "BOTTOM")

		V2Tex.Horizontal:Hide()
		V2Tex.Horizontal2:Hide()
		V2Tex.Dot:Hide()

		if toCX > fromCX then
			if toCY > fromCY then
				V2Tex:SetPoint("TOPRIGHT", to, "BOTTOM")
				V2Tex:SetPoint("BOTTOMLEFT", from, "TOP")
			else
				V2Tex:SetPoint("BOTTOMRIGHT", to, "TOP")
				V2Tex:SetPoint("TOPLEFT", from, "BOTTOM")
			end
		else
			if toCY > fromCY then
				V2Tex:SetPoint("TOPLEFT", to, "BOTTOM")
				V2Tex:SetPoint("BOTTOMRIGHT", from, "TOP")
			else
				V2Tex:SetPoint("BOTTOMLEFT", to, "TOP")
				V2Tex:SetPoint("TOPRIGHT", from, "BOTTOM")
			end
		end
	end

	if module:IsHooked(from, "Show") then module:Unhook(from, "Show") end
end

------------------------------------------------------------------------
--	Create/Style Funcs
--	They are stored in the module so the LUI options can easily
--	access them
------------------------------------------------------------------------

module.funcs = {

	FrameBackdrop = function(self, unit, oufdb)
		if not self.FrameBackdrop then self.FrameBackdrop = CreateFrame("Frame", nil, self, "BackdropTemplate") end

		self.FrameBackdrop:ClearAllPoints()
		self.FrameBackdrop:SetPoint("TOPLEFT", self, "TOPLEFT", oufdb.Backdrop.Padding.Left, oufdb.Backdrop.Padding.Top)
		self.FrameBackdrop:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", oufdb.Backdrop.Padding.Right, oufdb.Backdrop.Padding.Bottom)
		self.FrameBackdrop:SetFrameStrata("BACKGROUND")
		self.FrameBackdrop:SetBackdrop({
			bgFile = Media:Fetch("background", oufdb.Backdrop.Texture),
			edgeFile = Media:Fetch("border", oufdb.Border.EdgeFile),
			edgeSize = oufdb.Border.EdgeSize,
			insets = {
				left = oufdb.Border.Insets.Left,
				right = oufdb.Border.Insets.Right,
				top = oufdb.Border.Insets.Top,
				bottom = oufdb.Border.Insets.Bottom
			}
		})
		self.FrameBackdrop:SetBackdropColor(oufdb.Backdrop.Color.r, oufdb.Backdrop.Color.g, oufdb.Backdrop.Color.b, oufdb.Backdrop.Color.a)
		self.FrameBackdrop:SetBackdropBorderColor(oufdb.Border.Color.r, oufdb.Border.Color.g, oufdb.Border.Color.b, oufdb.Border.Color.a)
	end,

	--texts
	Info = function(self, unit, oufdb)
		if not self.Info then self.Info = module.SetFontString(self.Overlay, Media:Fetch("font", oufdb.NameText.Font), oufdb.NameText.Size, oufdb.NameText.Outline) end
		self.Info:SetFont(Media:Fetch("font", oufdb.NameText.Font), oufdb.NameText.Size, oufdb.NameText.Outline)
		self.Info:SetTextColor(oufdb.NameText.IndividualColor.r, oufdb.NameText.IndividualColor.g, oufdb.NameText.IndividualColor.b)
		self.Info:ClearAllPoints()
		self.Info:SetPoint(oufdb.NameText.Point, self, oufdb.NameText.RelativePoint, oufdb.NameText.X, oufdb.NameText.Y)

		if oufdb.NameText.Enable == true then
			self.Info:Show()
		else
			self.Info:Hide()
		end

		for k, v in pairs(oufdb.NameText) do
			self.Info[k] = v
		end
		self:FormatName()
	end,
	RaidInfo = function(self, unit, oufdb)
		if not self.Info then
			self.Info = module.SetFontString(self.Overlay, Media:Fetch("font", oufdb.NameText.Font), oufdb.NameText.Size, oufdb.NameText.Outline)
			self.Info:SetPoint("CENTER", self, "CENTER", 0, 0)
		end
		self.Info:SetTextColor(oufdb.NameText.IndividualColor.r, oufdb.NameText.IndividualColor.g, oufdb.NameText.IndividualColor.b)
		self.Info:SetFont(Media:Fetch("font", oufdb.NameText.Font), oufdb.NameText.Size, oufdb.NameText.Outline)

		if oufdb.NameText.Enable == true then
			self.Info:Show()
		else
			self.Info:Hide()
		end

		for k, v in pairs(oufdb.NameText) do
			self.Info[k] = v
		end

		self:FormatRaidName()
	end,

	-- Indicators
	LeaderIndicator = function(self, unit, oufdb)
		if not self.LeaderIndicator then
			self.LeaderIndicator = self.Overlay:CreateTexture(nil, "OVERLAY")
			self.AssistantIndicator = self.Overlay:CreateTexture(nil, "OVERLAY")
		end

		self.LeaderIndicator:SetHeight(oufdb.LeaderIndicator.Size)
		self.LeaderIndicator:SetWidth(oufdb.LeaderIndicator.Size)
		self.LeaderIndicator:ClearAllPoints()
		self.LeaderIndicator:SetPoint(oufdb.LeaderIndicator.Point, self, oufdb.LeaderIndicator.Point, oufdb.LeaderIndicator.X, oufdb.LeaderIndicator.Y)

		self.AssistantIndicator:SetHeight(oufdb.LeaderIndicator.Size)
		self.AssistantIndicator:SetWidth(oufdb.LeaderIndicator.Size)
		self.AssistantIndicator:ClearAllPoints()
		self.AssistantIndicator:SetPoint(oufdb.LeaderIndicator.Point, self, oufdb.LeaderIndicator.Point, oufdb.LeaderIndicator.X, oufdb.LeaderIndicator.Y)
	end,
	RaidTargetIndicator = function(self, unit, oufdb)
		if not self.RaidTargetIndicator then
			self.RaidTargetIndicator = self.Overlay:CreateTexture(nil, "OVERLAY")
			self.RaidTargetIndicator:SetTexture("Interface\\AddOns\\LUI\\media\\textures\\icons\\raidicons.blp")
		end

		self.RaidTargetIndicator:SetHeight(oufdb.RaidMarkerIndicator.Size)
		self.RaidTargetIndicator:SetWidth(oufdb.RaidMarkerIndicator.Size)
		self.RaidTargetIndicator:ClearAllPoints()
		self.RaidTargetIndicator:SetPoint(oufdb.RaidMarkerIndicator.Point, self, oufdb.RaidMarkerIndicator.Point, oufdb.RaidMarkerIndicator.X, oufdb.RaidMarkerIndicator.Y)
	end,
	GroupRoleIndicator = function(self, unit, oufdb)
		if not self.GroupRoleIndicator then self.GroupRoleIndicator = self.Overlay:CreateTexture(nil, "OVERLAY") end

		self.GroupRoleIndicator:SetHeight(oufdb.GroupRoleIndicator.Size)
		self.GroupRoleIndicator:SetWidth(oufdb.GroupRoleIndicator.Size)
		self.GroupRoleIndicator:ClearAllPoints()
		self.GroupRoleIndicator:SetPoint(oufdb.GroupRoleIndicator.Point, self, oufdb.GroupRoleIndicator.Point, oufdb.GroupRoleIndicator.X, oufdb.GroupRoleIndicator.Y)
	end,
	PvPIndicator = function(self, unit, oufdb)
		if not self.PvPIndicator then
			self.PvPIndicator = self.Overlay:CreateTexture(nil, "OVERLAY")
			if unit == "player" then
				self.PvPIndicator.Timer = module.SetFontString(self.Overlay, Media:Fetch("font", oufdb.PvPText.Font), oufdb.PvPText.Size, oufdb.PvPText.Outline)
				self.Health:HookScript("OnUpdate", function(_, elapsed)
					if UnitIsPVP(unit) and oufdb.PvPIndicator.Enable and oufdb.PvPText.Enable then
						if (GetPVPTimer() == 301000 or GetPVPTimer() == -1) then
							if self.PvPIndicator.Timer:IsShown() then
								self.PvPIndicator.Timer:Hide()
							end
						else
							self.PvPIndicator.Timer:Show()
							local min = math.floor(GetPVPTimer()/1000/60)
							local sec = (math.floor(GetPVPTimer()/1000))-(min*60)
							self.PvPIndicator.Timer:SetFormattedText("%d:%.2d", min, sec)
						end
					elseif self.PvPIndicator.Timer:IsShown() then
						self.PvPIndicator.Timer:Hide()
					end
				end)
			end
		end

		self.PvPIndicator:SetHeight(oufdb.PvPIndicator.Size)
		self.PvPIndicator:SetWidth(oufdb.PvPIndicator.Size)
		self.PvPIndicator:ClearAllPoints()
		self.PvPIndicator:SetPoint(oufdb.PvPIndicator.Point, self, oufdb.PvPIndicator.Point, oufdb.PvPIndicator.X, oufdb.PvPIndicator.Y)

		if self.PvPIndicator.Timer then
			self.PvPIndicator.Timer:SetFont(Media:Fetch("font", oufdb.PvPText.Font), oufdb.PvPText.Size, oufdb.PvPText.Outline)
			self.PvPIndicator.Timer:SetPoint("CENTER", self.PvPIndicator, "CENTER", oufdb.PvPText.X, oufdb.PvPText.Y)
			self.PvPIndicator.Timer:SetTextColor(oufdb.PvPText.Color.r, oufdb.PvPText.Color.g, oufdb.PvPText.Color.b)

			if oufdb.PvPIndicator.Enable and oufdb.PvPText.Enable then
				self.PvPIndicator.Timer:Show()
			else
				self.PvPIndicator.Timer:Hide()
			end
		end
	end,
	RestingIndicator = function(self, unit, oufdb)
		if not self.RestingIndicator then self.RestingIndicator = self.Overlay:CreateTexture(nil, "OVERLAY") end

		self.RestingIndicator:SetHeight(oufdb.RestingIndicator.Size)
		self.RestingIndicator:SetWidth(oufdb.RestingIndicator.Size)
		self.RestingIndicator:ClearAllPoints()
		self.RestingIndicator:SetPoint(oufdb.RestingIndicator.Point, self, oufdb.RestingIndicator.Point, oufdb.RestingIndicator.X, oufdb.RestingIndicator.Y)
	end,
	CombatIndicator = function(self, unit, oufdb)
		if not self.CombatIndicator then self.CombatIndicator = self.Overlay:CreateTexture(nil, "OVERLAY") end

		self.CombatIndicator:SetHeight(oufdb.CombatIndicator.Size)
		self.CombatIndicator:SetWidth(oufdb.CombatIndicator.Size)
		self.CombatIndicator:ClearAllPoints()
		self.CombatIndicator:SetPoint(oufdb.CombatIndicator.Point, self, oufdb.CombatIndicator.Point, oufdb.CombatIndicator.X, oufdb.CombatIndicator.Y)
	end,
	ReadyCheckIndicator = function(self, unit, oufdb)
		if not self.ReadyCheckIndicator then self.ReadyCheckIndicator = self.Overlay:CreateTexture(nil, "OVERLAY") end

		self.ReadyCheckIndicator:SetHeight(oufdb.ReadyCheckIndicator.Size)
		self.ReadyCheckIndicator:SetWidth(oufdb.ReadyCheckIndicator.Size)
		self.ReadyCheckIndicator:ClearAllPoints()
		self.ReadyCheckIndicator:SetPoint(oufdb.ReadyCheckIndicator.Point, self, oufdb.ReadyCheckIndicator.Point, oufdb.ReadyCheckIndicator.X, oufdb.ReadyCheckIndicator.Y)
	end,

	-- others
	Portrait = function(self, unit, oufdb)
		if not self.Portrait then
			self.Portrait = CreateFrame("PlayerModel", nil, self)
			self.Portrait:SetFrameLevel(5)
			--self.Portrait.Override = PortraitOverride
		end

		self.Portrait:SetHeight(oufdb.Portrait.Height)
		self.Portrait:SetWidth(oufdb.Portrait.Width * self:GetWidth() / oufdb.Width) -- needed for 25/40 man raid width downscaling!
		self.Portrait:SetAlpha(oufdb.Portrait.Alpha)
		self.Portrait:ClearAllPoints()
		self.Portrait:SetPoint("TOPLEFT", self, "TOPLEFT", oufdb.Portrait.X * self:GetWidth() / oufdb.Width, oufdb.Portrait.Y) -- needed for 25/40 man raid width downscaling!
	end,

	CombatFeedbackText = function(self, unit, oufdb)
		if not self.CombatFeedbackText then
			self.CombatFeedbackText = module.SetFontString(self.Health, Media:Fetch("font", oufdb.CombatFeedback.Font), oufdb.CombatFeedback.Size, oufdb.CombatFeedback.Outline)
		else
			self.CombatFeedbackText:SetFont(Media:Fetch("font", oufdb.CombatFeedback.Font), oufdb.CombatFeedback.Size, oufdb.CombatFeedback.Outline)
		end
		self.CombatFeedbackText:ClearAllPoints()
		self.CombatFeedbackText:SetPoint(oufdb.CombatFeedback.Point, self, oufdb.CombatFeedback.RelativePoint, oufdb.CombatFeedback.X, oufdb.CombatFeedback.Y)
		self.CombatFeedbackText.colors = module.colors.CombatText

		if oufdb.CombatFeedback.Enable == true then
			self.CombatFeedbackText.ignoreImmune = not oufdb.CombatFeedback.ShowImmune
			self.CombatFeedbackText.ignoreDamage = not oufdb.CombatFeedback.ShowDamage
			self.CombatFeedbackText.ignoreHeal = not oufdb.CombatFeedback.ShowHeal
			self.CombatFeedbackText.ignoreEnergize = not oufdb.CombatFeedback.ShowEnergize
			self.CombatFeedbackText.ignoreOther = not oufdb.CombatFeedback.ShowOther
		else
			self.CombatFeedbackText.ignoreImmune = true
			self.CombatFeedbackText.ignoreDamage = true
			self.CombatFeedbackText.ignoreHeal = true
			self.CombatFeedbackText.ignoreEnergize = true
			self.CombatFeedbackText.ignoreOther = true
			self.CombatFeedbackText:Hide()
		end
	end,

	AggroGlow = function(self, unit, oufdb)
		if self.ThreatIndicator then return end

		self.ThreatIndicator = CreateFrame("Frame", nil, self)
		self.ThreatIndicator:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
		self.ThreatIndicator:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
		self.ThreatIndicator:SetFrameLevel(self.Health:GetFrameLevel() - 1)

		for i = 1, 8 do
			self.ThreatIndicator[i] = self.ThreatIndicator:CreateTexture(nil, "BACKGROUND")
			self.ThreatIndicator[i]:SetTexture(aggroTex)
			self.ThreatIndicator[i]:SetWidth(20)
			self.ThreatIndicator[i]:SetHeight(20)
		end

		-- topleft corner
		self.ThreatIndicator[1]:SetTexCoord(0, 1/3, 0, 1/3)
		self.ThreatIndicator[1]:SetPoint("TOPLEFT", self.ThreatIndicator, -8, 8)

		-- topright corner
		self.ThreatIndicator[2]:SetTexCoord(2/3, 1, 0, 1/3)
		self.ThreatIndicator[2]:SetPoint("TOPRIGHT", self.ThreatIndicator, 8, 8)

		-- bottomleft corner
		self.ThreatIndicator[3]:SetTexCoord(0, 1/3, 2/3, 1)
		self.ThreatIndicator[3]:SetPoint("BOTTOMLEFT", self.ThreatIndicator, -8, -8)

		-- bottomright corner
		self.ThreatIndicator[4]:SetTexCoord(2/3, 1, 2/3, 1)
		self.ThreatIndicator[4]:SetPoint("BOTTOMRIGHT", self.ThreatIndicator, 8, -8)

		-- top edge
		self.ThreatIndicator[5]:SetTexCoord(1/3, 2/3, 0, 1/3)
		self.ThreatIndicator[5]:SetPoint("TOPLEFT", self.ThreatIndicator[1], "TOPRIGHT")
		self.ThreatIndicator[5]:SetPoint("TOPRIGHT", self.ThreatIndicator[2], "TOPLEFT")

		-- bottom edge
		self.ThreatIndicator[6]:SetTexCoord(1/3, 2/3, 2/3, 1)
		self.ThreatIndicator[6]:SetPoint("BOTTOMLEFT", self.ThreatIndicator[3], "BOTTOMRIGHT")
		self.ThreatIndicator[6]:SetPoint("BOTTOMRIGHT", self.ThreatIndicator[4], "BOTTOMLEFT")

		-- left edge
		self.ThreatIndicator[7]:SetTexCoord(0, 1/3, 1/3, 2/3)
		self.ThreatIndicator[7]:SetPoint("TOPLEFT", self.ThreatIndicator[1], "BOTTOMLEFT")
		self.ThreatIndicator[7]:SetPoint("BOTTOMLEFT", self.ThreatIndicator[3], "TOPLEFT")

		-- right edge
		self.ThreatIndicator[8]:SetTexCoord(2/3, 1, 1/3, 2/3)
		self.ThreatIndicator[8]:SetPoint("TOPRIGHT", self.ThreatIndicator[2], "BOTTOMRIGHT")
		self.ThreatIndicator[8]:SetPoint("BOTTOMRIGHT", self.ThreatIndicator[4], "TOPRIGHT")

		self.ThreatIndicator.Override = ThreatOverride
	end,
	
	V2Textures = function(from, to)
		if not from.V2Tex then
			local V2Tex = CreateFrame("Frame", nil, from)

			V2Tex.Horizontal = CreateFrame("Frame", nil, V2Tex, "BackdropTemplate")
			V2Tex.Horizontal:SetFrameLevel(19)
			V2Tex.Horizontal:SetFrameStrata("BACKGROUND")
			V2Tex.Horizontal:SetHeight(2)
			V2Tex.Horizontal:SetBackdrop(module.backdrop2)
			V2Tex.Horizontal:SetBackdropColor(0, 0, 0, 1)
			V2Tex.Horizontal:SetBackdropBorderColor(0.1, 0.1, 0.1, 1)
			V2Tex.Horizontal:Show()

			V2Tex.Vertical = CreateFrame("Frame", nil, V2Tex, "BackdropTemplate")
			V2Tex.Vertical:SetFrameLevel(19)
			V2Tex.Vertical:SetFrameStrata("BACKGROUND")
			V2Tex.Vertical:SetWidth(2)
			V2Tex.Vertical:SetBackdrop(module.backdrop2)
			V2Tex.Vertical:SetBackdropColor(0, 0, 0, 1)
			V2Tex.Vertical:SetBackdropBorderColor(0.1, 0.1, 0.1, 1)
			V2Tex.Vertical:Show()

			V2Tex.Horizontal2 = CreateFrame("Frame", nil, V2Tex, "BackdropTemplate")
			V2Tex.Horizontal2:SetFrameLevel(19)
			V2Tex.Horizontal2:SetFrameStrata("BACKGROUND")
			V2Tex.Horizontal2:SetHeight(2)
			V2Tex.Horizontal2:SetBackdrop(module.backdrop2)
			V2Tex.Horizontal2:SetBackdropColor(0, 0, 0, 1)
			V2Tex.Horizontal2:SetBackdropBorderColor(0.1, 0.1, 0.1, 1)
			V2Tex.Horizontal2:Show()

			V2Tex.Dot = CreateFrame("Frame", nil, V2Tex, "BackdropTemplate")
			V2Tex.Dot:SetFrameLevel(19)
			V2Tex.Dot:SetFrameStrata("BACKGROUND")
			V2Tex.Dot:SetHeight(6)
			V2Tex.Dot:SetWidth(6)
			V2Tex.Dot:SetBackdrop(module.backdrop2)
			V2Tex.Dot:SetBackdropColor(0, 0, 0, 1)
			V2Tex.Dot:SetBackdropBorderColor(0.1, 0.1, 0.1, 1)
			V2Tex.Dot:Show()

			-- needed for the options
			from.V2Tex = V2Tex
			to._V2Tex = V2Tex

			V2Tex.from = from
			V2Tex.to = to

			V2Tex.Reposition = Reposition

			module:SecureHook(from, "Show", function() V2Tex:Reposition() end)
		end

		from.V2Tex:Reposition()
	end,
}
