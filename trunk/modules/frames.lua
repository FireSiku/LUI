--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: frames.lua
	Description: Frames Module
	Version....: 1.1
	Rev Date...: 13/03/2012 [dd/mm/yyyy]

	Edits:
		v1.0: Loui
		v1.1: Zista
		v1.2: Thaly
]]

-- ####################################################################################################################
-- ##### External references ##########################################################################################
-- ####################################################################################################################
local addonname, LUI = ...
local module = LUI:Module("Frames")
local Panels = LUI:Module("Panels")
local Themes = LUI:Module("Themes")
local Media = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists

local db
local fdir = "Interface\\AddOns\\LUI\\media\\templates\\v3\\"

LUI.Navi = {}
LUI.Info = {}

function module:SetOrbColors()
	local orb = Themes.db.profile.orb
	LUI.Orb.Fill:SetVertexColor(unpack(orb))
	LUI.Orb.Galaxy1.t:SetVertexColor(unpack(orb))
	LUI.Orb.Galaxy2.t:SetVertexColor(unpack(orb))
	LUI.Orb.Galaxy3.t:SetVertexColor(unpack(orb))
end

function module:SetOrbCycleColor()
	LUI.Orb.Cycle:SetBackdropColor(unpack(Themes.db.profile.orb_cycle))
end

function module:SetOrbHoverColor()
	LUI.Orb.Hover:SetBackdropColor(unpack(Themes.db.profile.orb_hover))
end

function module:SetBottomInfoColors()
	LUI.Info.Left.BG:SetBackdropColor(unpack(Themes.db.profile.color_bottom))
	LUI.Info.Right.BG:SetBackdropColor(unpack(Themes.db.profile.color_bottom))
end

function module:SetTopInfoColors()
	LUI.Info.Topleft.BG:SetBackdropColor(unpack(Themes.db.profile.color_top))
	LUI.Info.Topright.BG:SetBackdropColor(unpack(Themes.db.profile.color_top))
	LUI.Navi.Top2:SetBackdropColor(unpack(Themes.db.profile.color_top))
end

function module:SetNavigationColors()
	LUI.Navi.Chat:SetBackdropColor(unpack(Themes.db.profile.navi))
	LUI.Navi.Tps:SetBackdropColor(unpack(Themes.db.profile.navi))
	LUI.Navi.Dps:SetBackdropColor(unpack(Themes.db.profile.navi))
	LUI.Navi.Raid:SetBackdropColor(unpack(Themes.db.profile.navi))
end

function module:SetNavigationHoverColors()
	LUI.Navi.Chat.Hover:SetBackdropColor(unpack(Themes.db.profile.navi_hover))
	LUI.Navi.Tps.Hover:SetBackdropColor(unpack(Themes.db.profile.navi_hover))
	LUI.Navi.Dps.Hover:SetBackdropColor(unpack(Themes.db.profile.navi_hover))
	LUI.Navi.Raid.Hover:SetBackdropColor(unpack(Themes.db.profile.navi_hover))
end

function module:SetNaviAlpha(frame, value)
	LUI.Navi[frame]:SetAlpha(value)
end

function module:SetColors()
	self:SetNavigationHoverColors()
	self:SetNavigationColors()
	self:SetTopInfoColors()
	self:SetBottomInfoColors()
	self:SetOrbCycleColor()
	self:SetOrbHoverColor()
	self:SetOrbColors()
end

local isAllShown = false
function module:IsAllShown(bool)
	if bool ~= nil then isAllShown = bool end
	return isAllShown
end

function module:SetFrames()
	local CreateMeAGalaxy = function(f, x, y, size, alpha, dur, tex, r, g, b)
		local h = CreateFrame("Frame", nil, f)
		h:SetHeight(size)
		h:SetWidth(size)
		h:SetPoint("CENTER", x, y - 10)
		h:SetAlpha(alpha)
		h:SetFrameLevel(5)

		local t = h:CreateTexture()
		t:SetAllPoints(h)
		t.path = "Interface\\AddOns\\LUI\\media\\textures\\orb\\"..tex
		t:SetTexture(t.path)
		t:SetBlendMode("ADD")
		t:SetVertexColor(r, g, b)
		h.t = t

		h.ag = h:CreateAnimationGroup()

		h.ag.a1 = h.ag:CreateAnimation("Rotation")
		h.ag.a1:SetDegrees(360)
		h.ag.a1:SetDuration(dur)

		h.total = 0
		h:SetScript("OnUpdate", function(self, elapsed)
			self.total = self.total + elapsed
			if self.total >= 1 then
				h.ag:Play()
			end
		end)

		return h
	end

	local navi = Themes.db.profile.navi
	local navi_hover = Themes.db.profile.navi_hover
	local orb_hover = Themes.db.profile.orb_hover
	local color_bottom = Themes.db.profile.color_bottom
	local color_top = Themes.db.profile.color_top
	local orb = Themes.db.profile.orb
	local orb_cycle = Themes.db.profile.orb_cycle

-- ####################################################################################################################
-- ##### ORB & TOP PANEL ##############################################################################################
-- ####################################################################################################################

	local MainAnchor = LUI:CreateMeAFrame("Frame", nil, UIParent, 100, 100, 1, "BACKGROUND", 1, "TOP", UIParent, "TOP", 17, 15, 1)

	LUI.Orb = CreateFrame("Button", nil, MainAnchor)
	LUI.Orb:SetFrameStrata("BACKGROUND")
	LUI.Orb:SetFrameLevel(4)
	LUI.Orb:SetWidth(55)
	LUI.Orb:SetHeight(55)
	LUI.Orb:SetPoint("CENTER", -17, 0)

	LUI.Orb:SetScript("OnEnter", function(self) self.AlphaIn:Show() end)
	LUI.Orb:SetScript("OnLeave", function(self) self.AlphaOut:Show() end)

	LUI.Orb.Fill = LUI.Orb:CreateTexture(nil, "ARTWORK")
	LUI.Orb.Fill.path = "Interface\\AddOns\\LUI\\media\\textures\\orb\\orb_filling8"
	LUI.Orb.Fill:SetTexture(LUI.Orb.Fill.path)
	LUI.Orb.Fill:SetPoint("BOTTOM", LUI.Orb, "BOTTOM", 0, 0)
	LUI.Orb.Fill:SetWidth(LUI.Orb:GetWidth())
	LUI.Orb.Fill:SetHeight(LUI.Orb:GetHeight())
	LUI.Orb.Fill:SetVertexColor(unpack(orb))

	LUI.Orb.Galaxy1 = CreateMeAGalaxy(LUI.Orb, 0, 13, 40, 0.9, 35, "galaxy2", orb[1], orb[2], orb[3])
	LUI.Orb.Galaxy2 = CreateMeAGalaxy(LUI.Orb, 0, 10, 65, 0, 45, "galaxy", orb[1], orb[2], orb[3])
	LUI.Orb.Galaxy3 = CreateMeAGalaxy(LUI.Orb, -5, 10, 53, 0.9, 18, "galaxy3", orb[1], orb[2], orb[3])

	LUI.Orb.AlphaIn = CreateFrame("Frame", nil, UIParent)
	LUI.Orb.AlphaIn:Hide()
	LUI.Orb.AlphaIn.timer = 0
	LUI.Orb.AlphaIn:SetScript("OnUpdate", function(self, elapsed)
		self.timer = self.timer + elapsed
		if self.timer < .3 then
			LUI.Orb.Hover:SetAlpha(self.timer / .3)
		else
			LUI.Orb.Hover:SetAlpha(1)
			self.timer = 0
			self:Hide()
		end
	end)

	LUI.Orb.AlphaOut = CreateFrame("Frame", nil, UIParent)
	LUI.Orb.AlphaOut:Hide()
	LUI.Orb.AlphaOut.timer = 0
	LUI.Orb.AlphaOut:SetScript("OnUpdate", function(self, elapsed)
		self.timer = self.timer + elapsed
		if self.timer < .3 then
			LUI.Orb.Hover:SetAlpha(1 - self.timer / .3)
		else
			LUI.Orb.Hover:SetAlpha(0)
			self.timer = 0
			self:Hide()
		end
	end)

	local function SetFrameBackdrop(frame, fileName)
		if not frame then LUI:Print("frame not found:", fileName) end
		frame.Backdrop = {
			bgFile = fdir..fileName,
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			edgeSize = 1,
			insets = {left = 0, right = 0, top = 0, bottom = 0}
		}
		frame:SetBackdrop(frame.Backdrop)
		frame:SetBackdropBorderColor(0,0,0,0)
	end

	LUI.Navi.Top = LUI:CreateMeAFrame("Frame", nil, UIParent, 1024, 1024, 1, "BACKGROUND", 1, "TOP", UIParent, "TOP", 17, 8, 1)
	SetFrameBackdrop(LUI.Navi.Top, "top")
	LUI.Navi.Top:Show()

	LUI.Navi.Top2 = LUI:CreateMeAFrame("Frame", nil, UIParent, 1035, 1024, 1, "BACKGROUND", 0, "TOP", UIParent, "TOP", 17, 5, 1)
	SetFrameBackdrop(LUI.Navi.Top2, "top_back")
	LUI.Navi.Top2:SetBackdropColor(unpack(color_top))
	LUI.Navi.Top2:Show()

	LUI.Orb.Hover = LUI:CreateMeAFrame("Frame", nil, LUI.Orb, 68, 68, 1, "LOW", 0, "CENTER", LUI.Orb, "CENTER", 1, 0, 0)
	SetFrameBackdrop(LUI.Orb.Hover, "ring_inner")
	LUI.Orb.Hover:SetBackdropColor(unpack(orb_hover))
	LUI.Orb.Hover:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Orb.Hover:Show()

	LUI.Orb.Ring2 = LUI:CreateMeAFrame("Frame", nil, LUI.Orb, 103, 103, 1, "LOW", 1, "CENTER", LUI.Orb, "CENTER", 0, -1, 1)
	SetFrameBackdrop(LUI.Orb.Ring2, "ring")
	LUI.Orb.Ring2:SetBackdropColor(0.25, 0.25, 0.25, 1)
	LUI.Orb.Ring2:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Orb.Ring2:Show()

	--[[
	LUI.Orb.Ring3 = LUI:CreateMeAFrame("FRAME", nil, LUI.Orb, 107, 107, 1, "LOW", 2, "CENTER", LUI.Orb, "CENTER", 1, 1, 1)
	LUI.Orb.Ring3:SetBackdrop({
		bgFile = fdir.."ring_inner",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.Orb.Ring3:SetBackdropColor(0.25, 0.25, 0.25, 0.7)
	LUI.Orb.Ring3:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Orb.Ring3:Show()
	]]

	LUI.Orb.Ring4 = LUI:CreateMeAFrame("Frame", nil, LUI.Orb, 115, 115, 1, "LOW", 1, "CENTER", LUI.Orb, "CENTER", 0, -1, 1)
	SetFrameBackdrop(LUI.Orb.Ring4, "ring_inner2")
	LUI.Orb.Ring4:Show()

	--[[
	LUI.Orb.Ring5 = LUI:CreateMeAFrame("Frame", nil, LUI.Orb, 118, 118, 1, "LOW", 2, "CENTER", LUI.Orb, "CENTER", 0, -1, 1)
	LUI.Orb.Ring5:SetBackdrop({
		bgFile = fdir.."ring_inner3",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.Orb.Ring5:SetBackdropColor(0.25, 0.25, 0.25, 0.7)
	LUI.Orb.Ring5:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Orb.Ring5:Show()
	]]

	LUI.Orb.Cycle = LUI:CreateMeAFrame("Frame", nil, LUI.Orb, 115, 115, 1, "LOW", 0, "CENTER", LUI.Orb, "CENTER", 0, -1, 1)
	SetFrameBackdrop(LUI.Orb.Cycle, "ring_inner4")
	LUI.Orb.Cycle:SetBackdropColor(0.25, 0.25, 0.25, 0.7)
	LUI.Orb.Cycle:Show()

	LUI.Orb.Ring7 = LUI:CreateMeAFrame("Frame", nil, LUI.Orb, 77, 75, 1, "LOW", 3, "CENTER", LUI.Orb, "CENTER", 1, -1, 1)
	SetFrameBackdrop(LUI.Orb.Ring7, "ring")
	LUI.Orb.Ring7:Show()

	LUI.Orb:RegisterForClicks("AnyUp")
	LUI.Orb:SetScript("OnClick", function(self)
		-- Commented out to try and fix Orb issues when not all frames are in use
		--isAllShown = (Panels.db.profile.Chat.IsShown and Panels.db.profile.Tps.IsShown and Panels.db.profile.Dps.IsShown and Panels.db.profile.Raid.IsShown)

		if not isAllShown then
			isAllShown = true

			LUI.Orb.Cycle:SetBackdropColor(unpack(orb_cycle))

			for _, k in pairs({"Chat", "Tps", "Dps", "Raid"}) do
				local v = LUI.Navi[k]
				if v:GetAlpha() == 0 then
					local a = k == "Chat" and "ChatAlphaAnchor" or Panels.db.profile[k].Anchor

					if _G[a] then
						v.AlphaIn:Show()
						Panels:AlphaIn(k)
					end
				end
			end

			--if db.Chat.SecondChatFrame then ChatAlphaAnchor2:Show() end
		else
			isAllShown = false

			LUI.Orb.Cycle:SetBackdropColor(0.25, 0.25, 0.25, 0.7)

			for _, k in pairs({"Chat", "Tps", "Dps", "Raid"}) do
				local v = LUI.Navi[k]
				if v:GetAlpha() == 1 then
					local a = k == "Chat" and "ChatAlphaAnchor" or Panels.db.profile[k].Anchor

					if _G[a] then
						v.AlphaOut:Show()
						Panels:AlphaOut(k)
					end
				end
			end
		end
	end)

-- ####################################################################################################################
-- ##### CHAT BUTTON ##################################################################################################
-- ####################################################################################################################

	LUI.Navi.Chat = LUI:CreateMeAFrame("Frame", nil, LUI.Orb, 126, 120, 1, "LOW", 1, "LEFT", LUI.Orb, "LEFT", -176, 73, 0)
	LUI.Navi.Chat:SetBackdrop({
		bgFile = fdir.."button_left2",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.Navi.Chat:SetBackdropColor(unpack(navi))
	LUI.Navi.Chat:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Navi.Chat:Show()

	LUI.Navi.Chat.Hover = LUI:CreateMeAFrame("Frame", nil, LUI.Orb, 124, 120, 1, "LOW", 1, "LEFT", LUI.Orb, "LEFT", -176, 73, 0)
	LUI.Navi.Chat.Hover:SetBackdrop({
		bgFile = fdir.."button_left2_hover",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.Navi.Chat.Hover:SetBackdropColor(unpack(navi_hover))
	LUI.Navi.Chat.Hover:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Navi.Chat.Hover:Show()

	LUI.Navi.Chat.Clicker = CreateFrame("Button", nil, LUI.Navi.Chat)
	LUI.Navi.Chat.Clicker:SetWidth(70)
	LUI.Navi.Chat.Clicker:SetHeight(30)
	LUI.Navi.Chat.Clicker:SetScale(1)
	LUI.Navi.Chat.Clicker:SetFrameStrata("LOW")
	LUI.Navi.Chat.Clicker:SetFrameLevel(2)
	LUI.Navi.Chat.Clicker:SetPoint("CENTER", LUI.Navi.Chat, "CENTER", -5, -42)
	LUI.Navi.Chat.Clicker:SetAlpha(0)

	LUI.Navi.Chat.Clicker:RegisterForClicks("AnyUp")
	LUI.Navi.Chat.Clicker:SetScript("OnEnter", function(self) LUI.Navi.Chat.Hover:SetAlpha(1) end)
	LUI.Navi.Chat.Clicker:SetScript("OnLeave", function(self) LUI.Navi.Chat.Hover:SetAlpha(0) end)
	LUI.Navi.Chat.Clicker:SetScript("OnClick", function(self)
		if LUI.Navi.Chat:GetAlpha() == 0 then
			LUI.Navi.Chat.AlphaIn:Show()
			Panels:AlphaIn("Chat")
			Panels.db.profile.Chat.IsShown = true
			LUI:SetChatVisible(true)
		else
			LUI.Navi.Chat.AlphaOut:Show()
			Panels:AlphaOut("Chat")
			Panels.db.profile.Chat.IsShown = false
			LUI:SetChatVisible(true)
			--LUI:SetChatVisible(false)
		end
	end)

-- ####################################################################################################################
-- ##### TPS BUTTON ###################################################################################################
-- ####################################################################################################################

	LUI.Navi.Tps = LUI:CreateMeAFrame("Frame", nil, LUI.Orb, 63, 67, 1, "LOW", 1, "LEFT", LUI.Orb, "LEFT", -74, 42, 0)
	LUI.Navi.Tps:SetBackdrop({
		bgFile = fdir.."button_left1",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.Navi.Tps:SetBackdropColor(unpack(navi))
	LUI.Navi.Tps:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Navi.Tps:Show()

	LUI.Navi.Tps.Hover = LUI:CreateMeAFrame("Frame", nil, LUI.Orb, 63, 60, 1, "LOW", 1, "LEFT", LUI.Orb, "LEFT", -74, 40, 0)
	LUI.Navi.Tps.Hover:SetBackdrop({
		bgFile = fdir.."button_left1_hover",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.Navi.Tps.Hover:SetBackdropColor(unpack(navi_hover))
	LUI.Navi.Tps.Hover:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Navi.Tps.Hover:Show()

	LUI.Navi.Tps.Clicker = CreateFrame("Button", nil, LUI.Navi.Tps)
	LUI.Navi.Tps.Clicker:SetWidth(63)
	LUI.Navi.Tps.Clicker:SetHeight(30)
	LUI.Navi.Tps.Clicker:SetScale(1)
	LUI.Navi.Tps.Clicker:SetFrameStrata("LOW")
	LUI.Navi.Tps.Clicker:SetFrameLevel(2)
	LUI.Navi.Tps.Clicker:SetPoint("CENTER", LUI.Navi.Tps, "CENTER", 0, -12)
	LUI.Navi.Tps.Clicker:SetAlpha(0)

	LUI.Navi.Tps.Clicker:RegisterForClicks("AnyUp")
	LUI.Navi.Tps.Clicker:SetScript("OnEnter", function(self) LUI.Navi.Tps.Hover:SetAlpha(1) end)
	LUI.Navi.Tps.Clicker:SetScript("OnLeave", function(self) LUI.Navi.Tps.Hover:SetAlpha(0) end)
	LUI.Navi.Tps.Clicker:SetScript("OnClick", function(self)
		if _G[Panels.db.profile.Tps.Anchor] then
			if LUI.Navi.Tps:GetAlpha() == 0 then
				LUI.Navi.Tps.AlphaIn:Show()
				Panels:AlphaIn("Tps")
				Panels.db.profile.Tps.IsShown = true
			else
				LUI.Navi.Tps.AlphaOut:Show()
				Panels:AlphaOut("Tps")
				Panels.db.profile.Tps.IsShown = false
			end
		end
	end)

-- ####################################################################################################################
-- ##### DPS BUTTON ###################################################################################################
-- ####################################################################################################################

	LUI.Navi.Dps = LUI:CreateMeAFrame("Frame", nil, LUI.Orb, 63, 67, 1, "LOW", 1, "RIGHT", LUI.Orb, "RIGHT", 77, 45, 0)
	LUI.Navi.Dps:SetBackdrop({
		bgFile = fdir.."button_right1",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.Navi.Dps:SetBackdropColor(unpack(navi))
	LUI.Navi.Dps:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Navi.Dps:Show()

	LUI.Navi.Dps.Hover = LUI:CreateMeAFrame("Frame", nil, LUI.Orb, 63, 60, 1, "LOW", 1, "RIGHT", LUI.Orb, "RIGHT", 77, 43, 0)
	LUI.Navi.Dps.Hover:SetBackdrop({
		bgFile = fdir.."button_right1_hover",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.Navi.Dps.Hover:SetBackdropColor(unpack(navi_hover))
	LUI.Navi.Dps.Hover:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Navi.Dps.Hover:Show()

	LUI.Navi.Dps.Clicker = CreateFrame("Button", nil, LUI.Navi.Dps)
	LUI.Navi.Dps.Clicker:SetWidth(63)
	LUI.Navi.Dps.Clicker:SetHeight(30)
	LUI.Navi.Dps.Clicker:SetScale(1)
	LUI.Navi.Dps.Clicker:SetFrameStrata("LOW")
	LUI.Navi.Dps.Clicker:SetFrameLevel(2)
	LUI.Navi.Dps.Clicker:SetPoint("CENTER", LUI.Navi.Dps, "CENTER", 0, -12)
	LUI.Navi.Dps.Clicker:SetAlpha(0)

	LUI.Navi.Dps.Clicker:RegisterForClicks("AnyUp")
	LUI.Navi.Dps.Clicker:SetScript("OnEnter", function(self) LUI.Navi.Dps.Hover:SetAlpha(1) end)
	LUI.Navi.Dps.Clicker:SetScript("OnLeave", function(self) LUI.Navi.Dps.Hover:SetAlpha(0) end)
	LUI.Navi.Dps.Clicker:SetScript("OnClick", function(self)
		if _G[Panels.db.profile.Dps.Anchor] then
			if LUI.Navi.Dps:GetAlpha() == 0 then
				LUI.Navi.Dps.AlphaIn:Show()
				Panels:AlphaIn("Dps")
				Panels.db.profile.Dps.IsShown = true
			else
				LUI.Navi.Dps.AlphaOut:Show()
				Panels:AlphaOut("Dps")
				Panels.db.profile.Dps.IsShown = false
			end
		end
	end)

-- ####################################################################################################################
-- ##### RAID BUTTON ##################################################################################################
-- ####################################################################################################################

	LUI.Navi.Raid = LUI:CreateMeAFrame("Frame", nil, LUI.Orb, 126, 120, 1, "LOW", 1, "RIGHT", LUI.Orb, "RIGHT", 184, 71, 0)
	LUI.Navi.Raid:SetBackdrop({
		bgFile = fdir.."button_right2",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.Navi.Raid:SetBackdropColor(unpack(navi))
	LUI.Navi.Raid:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Navi.Raid:Show()

	LUI.Navi.Raid.Hover = LUI:CreateMeAFrame("Frame", nil, LUI.Orb, 124, 120, 1, "LOW", 1, "RIGHT", LUI.Orb, "RIGHT", 182, 71, 0)
	LUI.Navi.Raid.Hover:SetBackdrop({
		bgFile = fdir.."button_right2_hover",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.Navi.Raid.Hover:SetBackdropColor(unpack(navi_hover))
	LUI.Navi.Raid.Hover:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Navi.Raid.Hover:Show()

	LUI.Navi.Raid.Clicker = CreateFrame("Button", nil, LUI.Navi.Raid)
	LUI.Navi.Raid.Clicker:SetWidth(78)
	LUI.Navi.Raid.Clicker:SetHeight(30)
	LUI.Navi.Raid.Clicker:SetScale(1)
	LUI.Navi.Raid.Clicker:SetFrameStrata("LOW")
	LUI.Navi.Raid.Clicker:SetFrameLevel(2)
	LUI.Navi.Raid.Clicker:SetPoint("CENTER", LUI.Navi.Raid, "CENTER", 0, -42)
	LUI.Navi.Raid.Clicker:SetAlpha(0)

	LUI.Navi.Raid.Clicker:RegisterForClicks("AnyUp")
	LUI.Navi.Raid.Clicker:SetScript("OnEnter", function(self) LUI.Navi.Raid.Hover:SetAlpha(1) end)
	LUI.Navi.Raid.Clicker:SetScript("OnLeave", function(self) LUI.Navi.Raid.Hover:SetAlpha(0) end)
	LUI.Navi.Raid.Clicker:SetScript("OnClick", function(self)
		if _G[Panels.db.profile.Raid.Anchor] then
			if LUI.Navi.Raid:GetAlpha() == 0 then
				LUI.Navi.Raid.AlphaIn:Show()
				Panels:AlphaIn("Raid")
				Panels.db.profile.Raid.IsShown = true
			else
				LUI.Navi.Raid.AlphaOut:Show()
				Panels:AlphaOut("Raid")
				Panels.db.profile.Raid.IsShown = false
			end
		end
	end)

-- ####################################################################################################################
-- ##### INFO PANEL LEFT ##############################################################################################
-- ####################################################################################################################

	LUI.Info.Left = LUI:CreateMeAFrame("Frame", nil, UIParent, 25, 25, 1, "BACKGROUND", 0, "BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0, 1)

	LUI.Info.Left.Panel = LUI:CreateMeAFrame("FRAME", nil, LUI.Info.Left, 1024, 1024, 1, "BACKGROUND", 1, "BOTTOMLEFT", LUI.Info.Left, "BOTTOMLEFT", -30, -31, 1)
	LUI.Info.Left.Panel:SetBackdrop({
		bgFile = fdir.."info_left",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.Info.Left.Panel:SetBackdropColor(0, 0, 0, 0.9)
	LUI.Info.Left.Panel:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Info.Left.Panel:Show()

	LUI.Info.Left.BG = LUI:CreateMeAFrame("FRAME", nil, LUI.Info.Left, 1024, 1024, 1, "BACKGROUND", 0, "BOTTOMLEFT", LUI.Info.Left, "BOTTOMLEFT", -23, -23, 1)
	LUI.Info.Left.BG:SetBackdrop({
		bgFile = fdir.."info_left_back",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.Info.Left.BG:SetBackdropColor(unpack(color_bottom))
	LUI.Info.Left.BG:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Info.Left.BG:Show()

-- ####################################################################################################################
-- ##### INFO PANEL RIGHT #############################################################################################
-- ####################################################################################################################

	LUI.Info.Right = LUI:CreateMeAFrame("Frame", nil, UIParent, 25, 25, 1, "BACKGROUND", 0, "BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0, 1)

	LUI.Info.Right.Panel = LUI:CreateMeAFrame("FRAME", nil, LUI.Info.Right, 1024, 1024, 1, "BACKGROUND", 1, "BOTTOMRIGHT", LUI.Info.Right, "BOTTOMRIGHT", 36, -31, 1)
	LUI.Info.Right.Panel:SetBackdrop({
		bgFile = fdir.."info_right",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.Info.Right.Panel:SetBackdropColor(0, 0, 0, 0.9)
	LUI.Info.Right.Panel:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Info.Right.Panel:Show()

	LUI.Info.Right.BG = LUI:CreateMeAFrame("FRAME", nil, LUI.Info.Right, 1024, 1024, 1, "BACKGROUND", 0, "BOTTOMRIGHT", LUI.Info.Right, "BOTTOMRIGHT", 29, -23, 1)
	LUI.Info.Right.BG:SetBackdrop({
		bgFile = fdir.."info_right_back",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.Info.Right.BG:SetBackdropColor(unpack(color_bottom))
	LUI.Info.Right.BG:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Info.Right.BG:Show()

-- ####################################################################################################################
-- ##### INFO PANEL TOPLEFT ###########################################################################################
-- ####################################################################################################################

	LUI.Info.Topleft = LUI:CreateMeAFrame("Frame", nil, UIParent, 25, 25, 1, "BACKGROUND", 0, "CENTER", LUI.Orb, "CENTER", -212, 30, 1)

	LUI.Info.Topleft.BG = LUI:CreateMeAFrame("FRAME", nil, LUI.Info.Topleft, 1012, 1024, 1, "BACKGROUND", 0, "TOPRIGHT", LUI.Info.Topleft, "TOPRIGHT", 9, 11, 1)
	LUI.Info.Topleft.BG:SetBackdrop({
		bgFile = fdir.."info_top_left2",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.Info.Topleft.BG:SetBackdropColor(unpack(color_top))
	LUI.Info.Topleft.BG:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Info.Topleft.BG:Show()

-- ####################################################################################################################
-- ##### INFO PANEL TOPRIGHT ##########################################################################################
-- ####################################################################################################################

	LUI.Info.Topright = LUI:CreateMeAFrame("Frame", nil, UIParent, 25, 25, 1, "BACKGROUND", 0, "CENTER", LUI.Orb, "CENTER", 209, 30, 1)

	LUI.Info.Topright.BG = LUI:CreateMeAFrame("FRAME", nil, LUI.Info.Topright, 1015, 1024, 1, "BACKGROUND", 0, "TOPLEFT", LUI.Info.Topright, "TOPLEFT", -9, 11, 1)
	LUI.Info.Topright.BG:SetBackdrop({
		bgFile = fdir.."info_top_right2",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.Info.Topright.BG:SetBackdropColor(unpack(color_top))
	LUI.Info.Topright.BG:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Info.Topright.BG:Show()

-- ####################################################################################################################
-- ##### SCRIPTS ######################################################################################################
-- ####################################################################################################################

	local alphain = function(self, elapsed)
		self.timer = self.timer + elapsed
		if self.timer < .4 then
			LUI.Navi[self.kind]:SetAlpha(self.timer / .4)
		else
			LUI.Navi[self.kind]:SetAlpha(1)
			self.timer = 0
			self:Hide()
		end
	end
	local alphaout = function(self, elapsed)
		self.timer = self.timer + elapsed
		if self.timer < .4 then
			LUI.Navi[self.kind]:SetAlpha(1 - self.timer / .4)
		else
			LUI.Navi[self.kind]:SetAlpha(0)
			self.timer = 0
			self:Hide()
		end
	end

	for _, k in pairs({"Chat", "Tps", "Dps", "Raid"}) do
		local v = LUI.Navi[k]

		v.AlphaIn = CreateFrame("Frame", nil, UIParent)
		v.AlphaIn:Hide()
		v.AlphaIn.timer = 0
		v.AlphaIn.kind = k
		v.AlphaIn:SetScript("OnUpdate", alphain)

		v.AlphaOut = CreateFrame("Frame", nil, UIParent)
		v.AlphaOut:Hide()
		v.AlphaOut.timer = 0
		v.AlphaOut.kind = k
		v.AlphaOut:SetScript("OnUpdate", alphaout)
	end
end

function module:OnInitialize()
	-- kill when chat module is rewritten!
	self.db = LUI.db.profile
	db = self.db
end

function module:OnEnable()
	self:SetFrames()
end
