--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: meta.lua
	Description: oUF Meta Functions
]]

local addonname, LUI = ...
local module = LUI:GetModule("Unitframes")
local Media = LibStub("LibSharedMedia-3.0")
local oUF = LUI.oUF

local UnitName = _G.UnitName
local UnitClass = _G.UnitClass
local UnitIsEnemy = _G.UnitIsEnemy
local UnitChannelInfo = _G.UnitChannelInfo
local UnitSpellHaste = _G.UnitSpellHaste


local channelingTicks -- base time between ticks
do
	local classChannels = {
	}

	channelingTicks = {
		["First Aid"] = 1 -- Bandages
	}
	if classChannels[LUI.playerClass] then
		for k, v in pairs(classChannels[LUI.playerClass]) do
			channelingTicks[k] = v
		end
	end
	wipe(classChannels)
end

local function FormatCastbarTime(self, duration)
	if self.delay ~= 0 then
		if self.channeling then
			if self.Time.ShowMax == true then
				self.Time:SetFormattedText("%.1f / %.1f |cffff0000%.1f|r", duration, self.max, -self.delay)
			else
				self.Time:SetFormattedText("%.1f |cffff0000%.1f|r", duration, -self.delay)
			end
		elseif self.casting then
			if self.Time.ShowMax == true then
				self.Time:SetFormattedText("%.1f / %.1f |cffff0000%.1f|r", self.max - duration, self.max, -self.delay)
			else
				self.Time:SetFormattedText("%.1f |cffff0000%.1f|r", self.max - duration, -self.delay)
			end
		end
	else
		if self.channeling then
			if self.Time.ShowMax == true then
				self.Time:SetFormattedText("%.1f / %.1f", duration, self.max)
			else
				self.Time:SetFormattedText("%.1f", duration)
			end
		elseif self.casting then
			if self.Time.ShowMax == true then
				self.Time:SetFormattedText("%.1f / %.1f", self.max - duration, self.max)
			else
				self.Time:SetFormattedText("%.1f", self.max - duration)
			end
		end
	end
end

-- ####################################################################################################################
-- ##### Unitframe Elements: Cast Bars ################################################################################
-- ####################################################################################################################

--- Castbar callback after a cast starts
---@param element ufCastbar
---@param unit UnitId
---@param name string @ name of the spell being cast
local function PostCastStart(castbar, unit, name)
	local unitname, _ = UnitName(unit)
	if castbar.Colors.Individual == true then
		castbar:SetStatusBarColor(castbar.Colors.Bar.r, castbar.Colors.Bar.g, castbar.Colors.Bar.b, castbar.Colors.Bar.a)
		castbar.bg:SetVertexColor(castbar.Colors.Background.r, castbar.Colors.Background.g, castbar.Colors.Background.b, castbar.Colors.Background.a)
		castbar.Backdrop:SetBackdropBorderColor(castbar.Colors.Border.r, castbar.Colors.Border.g, castbar.Colors.Border.b, castbar.Colors.Border.a)
	else
		if unit == "pet" then unit = "player" end
		local pClass, pToken = UnitClass(unit)
		local color = module.colors.class[pToken]

		castbar:SetStatusBarColor(color[1], color[2], color[3], 0.68)
		castbar.bg:SetVertexColor(0.15, 0.15, 0.15, 0.75)
		castbar.Backdrop:SetBackdropBorderColor(0, 0, 0, 0.7)
	end
	if castbar.notInterruptible and castbar.Shielded.Enable and UnitIsEnemy("player", unit) then
		if castbar.Shielded.IndividualColor then
			castbar:SetStatusBarColor(castbar.Shielded.BarColor.r, castbar.Shielded.BarColor.g, castbar.Shielded.BarColor.b, castbar.Shielded.BarColor.a)
		end
		if castbar.Shielded.IndividualBorder then
			castbar.Backdrop:SetBackdrop({
				edgeFile = Media:Fetch("border", castbar.Shielded.Texture),
				edgeSize = castbar.Shielded.Thick,
				insets = {
					left = castbar.Shielded.Inset.L,
					right = castbar.Shielded.Inset.R,
					top = castbar.Shielded.Inset.T,
					bottom = castbar.Shielded.Inset.B,
				},
			})
			castbar.Backdrop:SetBackdropBorderColor(castbar.Shielded.Color.r, castbar.Shielded.Color.g, castbar.Shielded.Color.b, castbar.Shielded.Color.a)
		end
		if castbar.Shielded.Text then
			castbar.Text:SetText(format("%s ** Shielded **", tostring(name)))
		end
	end
end

--- Castbar callback after a cast starts
---@param element ufCastbar
---@param unit UnitId
---@param name string @ name of the spell being cast
local function PostChannelStart(castbar, unit, name)
	local _, _, _, _, startTime, endTime = UnitChannelInfo(unit)
	if castbar.channeling then
		if channelingTicks[name] then
			local tickspeed = channelingTicks[name] / (1 + (UnitSpellHaste(unit) / 100))
			local numticks = floor((castbar.max / tickspeed) + 0.5) - 1
			for i = 1, numticks do
				local tick = castbar:GetTick(i)
				tick.ticktime = tickspeed * i
				tick.delay = 0
				tick:Update()
			end
			castbar.tickspeed = tickspeed
			castbar.numticks = numticks
		else
			castbar:HideTicks()
		end
	end

	PostCastStart(castbar, unit, name)
end

--- Castbar callback after a cast starts
---@param element ufCastbar
---@param unit UnitId
---@param name string @ name of the spell being cast
local function PostChannelUpdate(castbar, unit, name)
	if not castbar.numticks then return end

	local _, _, _, _, startTime, endTime = UnitChannelInfo(unit)

	if castbar.delay < 0 then
		castbar.numticks = castbar.numticks + 1

		for i = 1, castbar.numticks do
			local tick = castbar:GetTick(i)
			tick.ticktime = castbar.tickspeed * i
			tick.delay = 0
			tick:Update()
		end

		castbar.delay = 0
		return
	end

	local _duration = castbar.duration + castbar.delay
	for i = 1, castbar.numticks do
		local tick = castbar:GetTick(i)
		if tick.ticktime < _duration then
			tick.delay = castbar.delay
			tick:Update()
		else
			break
		end
	end
end

local ticks = {}
local function updateTick(self)
	local ticktime = self.ticktime - self.delay
	if ticktime > 0 and ticktime < self.max then
		self:SetPoint("CENTER", self, "LEFT", ticktime / self.max * self:GetWidth(), 0)
		self:Show()
	else
		self:Hide()
		self.ticktime = 0
		self.delay = 0
	end
end

local function GetTick(self, i)
	local tick = ticks[i]
	if not tick then
		tick = self:CreateTexture(nil, "OVERLAY")
		ticks[i] = tick
		tick:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
		tick:SetVertexColor(1, 1, 1, 0.8)
		tick:SetBlendMode("ADD")
		tick:SetWidth(15)
		tick.Update = updateTick
	end
	tick:SetHeight(self:GetHeight() * 1.8)
	return tick
end
local function HideTicks(self)
	for i, tick in ipairs(ticks) do
		tick:Hide()
		tick.ticktime = 0
		tick.delay = 0
	end
end

local function Castbar(self, unit, oufdb)
	-- Castbars are not supported for *target units as they do not have any event-driven updates.
	if unit:match(".+target$") then return end

	local castbar = self.Castbar
	if not castbar then
		self.Castbar = CreateFrame("StatusBar", self:GetName().."_Castbar", self)
		castbar = self.Castbar
		castbar:SetFrameLevel(6)

		castbar.bg = castbar:CreateTexture(nil, "BORDER")
		castbar.bg:SetAllPoints(castbar)

		castbar.Backdrop = CreateFrame("Frame", nil, self, "BackdropTemplate")
		castbar.Backdrop:SetPoint("TOPLEFT", castbar, "TOPLEFT", -4, 3)
		castbar.Backdrop:SetPoint("BOTTOMRIGHT", castbar, "BOTTOMRIGHT", 3, -3.5)
		castbar.Backdrop:SetParent(castbar)

		castbar.Time = module.SetFontString(castbar, Media:Fetch("font", oufdb.Castbar.TimeText.Font), oufdb.Castbar.TimeText.Size)
		castbar.Time:SetJustifyH("RIGHT")
		castbar.CustomTimeText = FormatCastbarTime
		castbar.CustomDelayText = FormatCastbarTime

		castbar.Text = module.SetFontString(castbar, Media:Fetch("font", oufdb.Castbar.NameText.Font), oufdb.Castbar.NameText.Size)

		castbar.PostCastStart = PostCastStart
		castbar.PostChannelStart = PostCastStart

		if unit == "player" then
			castbar.SafeZone = castbar:CreateTexture(nil, "ARTWORK")
			castbar.SafeZone:SetTexture(LUI.Media.normTex)

			if channelingTicks then -- make sure player is a class that has a channeled spell

				castbar.GetTick = GetTick
				castbar.HideTicks = HideTicks

				castbar.PostChannelStart = PostChannelStart
				castbar.PostChannelUpdate = PostChannelUpdate
				castbar.PostChannelStop = castbar.HideTicks
			end
		end

		castbar.Icon = castbar:CreateTexture(nil, "ARTWORK")
		castbar.Icon:SetTexCoord(0, 1, 0, 1)
		if unit == "player" or unit == "target" or unit == "focus" or unit == "pet" then
			castbar.Icon:SetHeight(28.5)
			castbar.Icon:SetWidth(28.5)
			castbar.Icon:SetPoint("LEFT", -41.5, 0)
		else
			castbar.Icon = castbar:CreateTexture(nil, "ARTWORK")
			castbar.Icon:SetHeight(20)
			castbar.Icon:SetWidth(20)
			if unit == unit:match("arena%d") then
				castbar.Icon:SetPoint("RIGHT", 30, 0)
			else
				castbar.Icon:SetPoint("LEFT", -30, 0)
			end
		end

		castbar.IconOverlay = castbar:CreateTexture(nil, "OVERLAY")
		castbar.IconOverlay:SetPoint("TOPLEFT", castbar.Icon, "TOPLEFT", -1.5, 1)
		castbar.IconOverlay:SetPoint("BOTTOMRIGHT", castbar.Icon, "BOTTOMRIGHT", 1, -1)
		castbar.IconOverlay:SetTexture(module.buttonTex)
		castbar.IconOverlay:SetVertexColor(1, 1, 1)

		castbar.IconBackdrop = CreateFrame("Frame", nil, castbar, "BackdropTemplate")
		castbar.IconBackdrop:SetPoint("TOPLEFT", castbar.Icon, "TOPLEFT", -4, 3)
		castbar.IconBackdrop:SetPoint("BOTTOMRIGHT", castbar.Icon, "BOTTOMRIGHT", 3, -3.5)
		castbar.IconBackdrop:SetBackdrop({
			edgeFile = LUI.Media.glowTex, edgeSize = 4,
			insets = {left = 3, right = 3, top = 3, bottom = 3}
		})
		castbar.IconBackdrop:SetBackdropColor(0, 0, 0, 0)
		castbar.IconBackdrop:SetBackdropBorderColor(0, 0, 0, 0.7)
	end

	castbar:SetStatusBarTexture(Media:Fetch("statusbar", oufdb.Castbar.General.Texture))
	castbar:SetHeight(oufdb.Castbar.General.Height)
	castbar:SetWidth(oufdb.Castbar.General.Width)
	castbar:ClearAllPoints()
	if unit == "player" or unit == "target" then
		castbar:SetPoint(oufdb.Castbar.General.Point, UIParent, oufdb.Castbar.General.Point, oufdb.Castbar.General.X, oufdb.Castbar.General.Y)
	elseif unit == "focus" or unit == "pet" then
		castbar:SetPoint("TOP", self, "BOTTOM", oufdb.Castbar.General.X, oufdb.Castbar.General.Y)
	elseif unit == unit:match("arena%d") then
		castbar:SetPoint("RIGHT", self, "LEFT", oufdb.Castbar.General.X, oufdb.Castbar.General.Y)
	else
		castbar:SetPoint("LEFT", self, "RIGHT", oufdb.Castbar.General.X, oufdb.Castbar.General.Y)
	end

	castbar.bg:SetTexture(Media:Fetch("statusbar", oufdb.Castbar.General.TextureBG))

	castbar.Backdrop:SetBackdrop({
		edgeFile = Media:Fetch("border", oufdb.Castbar.Border.Texture),
		edgeSize = oufdb.Castbar.Border.Thickness,
		insets = {
			left = oufdb.Castbar.Border.Inset.left,
			right = oufdb.Castbar.Border.Inset.right,
			top = oufdb.Castbar.Border.Inset.top,
			bottom = oufdb.Castbar.Border.Inset.bottom
		}
	})
	castbar.Backdrop:SetBackdropColor(0, 0, 0, 0)

	castbar.Colors = {
		Individual = oufdb.Castbar.General.IndividualColor,
		Bar = oufdb.Castbar.Colors.Bar,
		Background = oufdb.Castbar.Colors.Background,
		Border = oufdb.Castbar.Colors.Border,
	}
	castbar.Shielded = {
		Enable = oufdb.Castbar.General.Shield,
		IndividualColor = oufdb.Castbar.Shield.IndividualColor,
		BarColor = oufdb.Castbar.Shield.BarColor,
		IndividualBorder = oufdb.Castbar.Shield.IndividualBorder,
		--Text = oufdb.Castbar.Shield.Text,
		Color = oufdb.Castbar.Shield.Color,
		Texture = oufdb.Castbar.Shield.Texture,
		Thick = oufdb.Castbar.Shield.Thickness,
		Inset = {
			L = oufdb.Castbar.Shield.Inset.left,
			R = oufdb.Castbar.Shield.Inset.right,
			T = oufdb.Castbar.Shield.Inset.top,
			B = oufdb.Castbar.Shield.Inset.bottom,
		},
	}
	castbar.Time:SetFont(Media:Fetch("font", oufdb.Castbar.TimeText.Font), oufdb.Castbar.TimeText.Size)
	castbar.Time:ClearAllPoints()
	castbar.Time:SetPoint("RIGHT", castbar, "RIGHT", oufdb.Castbar.TimeText.OffsetX, oufdb.Castbar.TimeText.OffsetY)
	castbar.Time:SetTextColor(oufdb.Castbar.Colors.Time.r, oufdb.Castbar.Colors.Time.g, oufdb.Castbar.Colors.Time.b)
	castbar.Time.ShowMax = oufdb.Castbar.TimeText.ShowMax

	if oufdb.Castbar.TimeText.Enable == true then
		castbar.Time:Show()
	else
		castbar.Time:Hide()
	end

	castbar.Text:SetFont(Media:Fetch("font", oufdb.Castbar.NameText.Font), oufdb.Castbar.NameText.Size)
	castbar.Text:ClearAllPoints()
	castbar.Text:SetPoint("LEFT", castbar, "LEFT", oufdb.Castbar.NameText.OffsetX, oufdb.Castbar.NameText.OffsetY)
	castbar.Text:SetTextColor(oufdb.Castbar.Colors.Name.r, oufdb.Castbar.Colors.Name.r, oufdb.Castbar.Colors.Name.r)

	if oufdb.Castbar.NameText.Enable == true then
		castbar.Text:Show()
	else
		castbar.Text:Hide()
	end

	if unit == "player" then
		-- HACK: Disable Latency until properly re-implemented
		if oufdb.Castbar.General.Latency == true and false then
			castbar.SafeZone:Show()
			if oufdb.Castbar.General.IndividualColor == true then
				castbar.SafeZone:SetVertexColor(oufdb.Castbar.Colors.Latency.r,oufdb.Castbar.Colors.Latency.g,oufdb.Castbar.Colors.Latency.b,oufdb.Castbar.Colors.Latency.a)
			else
				castbar.SafeZone:SetVertexColor(0.11,0.11,0.11,0.6)
			end
		else
			castbar.SafeZone:Hide()
		end
	end

	if oufdb.Castbar.General.Icon then
		castbar.Icon:Show()
		castbar.IconOverlay:Show()
		castbar.IconBackdrop:Show()
	else
		castbar.Icon:Hide()
		castbar.IconOverlay:Hide()
		castbar.IconBackdrop:Hide()
	end
end

-- ####################################################################################################################
-- ##### Unitframe Elements: Wrap up ##################################################################################
-- ####################################################################################################################

module.funcs.Castbar = Castbar
