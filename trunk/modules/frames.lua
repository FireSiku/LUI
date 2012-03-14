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

-- External references.
local addonname, LUI = ...
local module = LUI:Module("Frames")
local Panels = LUI:Module("Panels")
local Themes = LUI:Module("Themes")
local Media = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists

local db
local fdir = "Interface\\AddOns\\LUI\\media\\templates\\v3\\"

local LUI_Navi = {}
local LUI_Info = {}
local LUI_Orb

function module:SetOrbColors()
	local orb = Themes.db.profile.orb
	LUI_Orb.Fill:SetVertexColor(unpack(orb))
	LUI_Orb.Galaxy1.t:SetVertexColor(unpack(orb))
	LUI_Orb.Galaxy2.t:SetVertexColor(unpack(orb))
	LUI_Orb.Galaxy3.t:SetVertexColor(unpack(orb))
end

function module:SetOrbCycleColor()
	LUI_Orb.Cycle:SetBackdropColor(unpack(Themes.db.profile.orb_cycle))
end

function module:SetOrbHoverColor()
	LUI_Orb.Hover:SetBackdropColor(unpack(Themes.db.profile.orb_hover))
end

function module:SetBottomInfoColors()
	LUI_Info.Left.BG:SetBackdropColor(unpack(Themes.db.profile.color_bottom))
	LUI_Info.Right.BG:SetBackdropColor(unpack(Themes.db.profile.color_bottom))
end

function module:SetTopInfoColors()
	LUI_Info.Topleft.BG:SetBackdropColor(unpack(Themes.db.profile.color_top))
	LUI_Info.Topright.BG:SetBackdropColor(unpack(Themes.db.profile.color_top))
	LUI_Info.Top2:SetBackdropColor(unpack(Themes.db.profile.color_top))
end

function module:SetNavigationColors()
	LUI_Navi.Chat.Hover:SetBackdropColor(unpack(Themes.db.profile.navi_hover))
	LUI_Navi.Tps.Hover:SetBackdropColor(unpack(Themes.db.profile.navi_hover))
	LUI_Navi.Dps.Hover:SetBackdropColor(unpack(Themes.db.profile.navi_hover))
	LUI_Navi.Raid.Hover:SetBackdropColor(unpack(Themes.db.profile.navi_hover))
end

function module:SetNavigationHoverColors()
	for _, v in pairs(LUI_Navi) do
		v.Hover:SetBackdropColor(unpack(Themes.db.profile.navi_hover))
	end
end

function module:SetNaviAlpha(frame, value)
	LUI_Navi[frame]:SetAlpha(value)
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
	local function CreateMeAGalaxy(f, x, y, size, alpha, dur, tex, r, g, b)
		local h = CreateFrame("Frame", nil, f)
		h:SetHeight(size)
		h:SetWidth(size)
		h:SetPoint("CENTER", x, y - 10)
		h:SetAlpha(alpha)
		h:SetFrameLevel(5)

		local t = h:CreateTexture()
		t:SetAllPoints(h)
		t:SetTexture("Interface\\AddOns\\LUI\\media\\textures\\orb\\"..tex)
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
	
	------------------------------------------------------
	-- / ORB & TOP PANEL / --
	------------------------------------------------------
	
	local MainAnchor = LUI:CreateMeAFrame("Frame", nil, UIParent, 100, 100, 1, "BACKGROUND", 1, "TOP", UIParent, "TOP", 17, 15, 1)
	
	LUI_Orb = CreateFrame("Button", nil, MainAnchor)
	LUI_Orb:SetFrameStrata("BACKGROUND")
	LUI_Orb:SetFrameLevel(4)
	LUI_Orb:SetWidth(55)
	LUI_Orb:SetHeight(55)
	LUI_Orb:SetPoint("CENTER", -17, 0)
	
	LUI_Orb:SetScript("OnEnter", function(self) self.AlphaIn:Show() end)
	LUI_Orb:SetScript("OnLeave", function(self) self.AlphaOut:Show() end)
	
	LUI_Orb.Fill = LUI_Orb:CreateTexture(nil, "ARTWORK")
	LUI_Orb.Fill:SetTexture("Interface\\AddOns\\LUI\\media\\textures\\orb\\orb_filling8")
	LUI_Orb.Fill:SetPoint("BOTTOM", LUI_Orb, "BOTTOM", 0, 0)
	LUI_Orb.Fill:SetWidth(LUI_Orb:GetWidth())
	LUI_Orb.Fill:SetHeight(LUI_Orb:GetHeight())
	LUI_Orb.Fill:SetVertexColor(unpack(orb))
	
	LUI_Orb.Galaxy1 = CreateMeAGalaxy(LUI_Orb, 0, 13, 40, 0.9, 35, "galaxy2", orb[1], orb[2], orb[3])
	LUI_Orb.Galaxy2 = CreateMeAGalaxy(LUI_Orb, 0, 10, 65, 0.9, 45, "galaxy", orb[1], orb[2], orb[3])
	LUI_Orb.Galaxy3 = CreateMeAGalaxy(LUI_Orb, -5, 10, 53, 0.9, 18, "galaxy3", orb[1], orb[2], orb[3])
	
	LUI_Orb.AlphaIn = CreateFrame("Frame", nil, UIParent)
	LUI_Orb.AlphaIn:Hide()
	LUI_Orb.AlphaIn.timer = 0
	LUI_Orb.AlphaIn:SetScript("OnUpdate", function(self, elapsed)
		self.timer = self.timer + elapsed
		if self.timer < .3 then
			LUI_Orb.Hover:SetAlpha(self.timer / .3)
		else
			LUI_Orb.Hover:SetAlpha(1)
			self.timer = 0
			self:Hide()
		end
	end)

	LUI_Orb.AlphaOut = CreateFrame("Frame", nil, UIParent)
	LUI_Orb.AlphaOut:Hide()
	LUI_Orb.AlphaOut.timer = 0
	LUI_Orb.AlphaOut:SetScript("OnUpdate", function(self, elapsed)
		self.timer = self.timer + elapsed
		if self.timer < .3 then
			LUI_Orb.Hover:SetAlpha(1 - self.timer / .3)
		else
			LUI_Orb.Hover:SetAlpha(0)
			self.timer = 0
			self:Hide()
		end
	end)
	
	LUI_Navi.Top = LUI:CreateMeAFrame("Frame", nil, UIParent, 1024, 1024, 1, "BACKGROUND", 1, "TOP", UIParent, "TOP", 17, 8, 1)
	LUI_Navi.Top:SetBackdrop({
		bgFile = fdir.."top", 
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
		tile = 0, tileSize = 0, edgeSize = 1, 
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI_Navi.Top:SetBackdropBorderColor(0, 0, 0, 0)
	LUI_Navi.Top:Show()
	
	LUI_Navi.Top2 = LUI:CreateMeAFrame("Frame", nil, UIParent, 1035, 1024, 1, "BACKGROUND", 0, "TOP", UIParent, "TOP", 17, 5, 1)
	LUI_Navi.Top2:SetBackdrop({
		bgFile = fdir.."top_back", 
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
		tile = 0, tileSize = 0, edgeSize = 1, 
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI_Navi.Top2:SetBackdropColor(unpack(color_top))
	LUI_Navi.Top2:SetBackdropBorderColor(0, 0, 0, 0)
	LUI_Navi.Top2:Show()
	
	LUI_Orb.Hover = LUI:CreateMeAFrame("Frame", nil, LUI_Orb, 68, 68, 1, "LOW", 0, "CENTER", LUI_Orb, "CENTER", 1, 0, 0)
	LUI_Orb.Hover:SetBackdrop({
		bgFile = fdir.."ring_inner", 
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
		tile = 0, tileSize = 0, edgeSize = 1, 
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI_Orb.Hover:SetBackdropColor(unpack(orb_hover))
	LUI_Orb.Hover:SetBackdropBorderColor(0, 0, 0, 0)
	LUI_Orb.Hover:Show()
	
	LUI_Orb.Ring2 = LUI:CreateMeAFrame("Frame", nil, LUI_Orb, 103, 103, 1, "LOW", 1, "CENTER", LUI_Orb, "CENTER", 0, -1, 1)
	LUI_Orb.Ring2:SetBackdrop({
		bgFile = fdir.."ring", 
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
		tile = 0, tileSize = 0, edgeSize = 1, 
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI_Orb.Ring2:SetBackdropColor(0.25, 0.25, 0.25, 1)
	LUI_Orb.Ring2:SetBackdropBorderColor(0, 0, 0, 0)
	LUI_Orb.Ring2:Show()
	
	--[[
	LUI_Orb.Ring3 = LUI:CreateMeAFrame("FRAME", nil, LUI_Orb, 107, 107, 1, "LOW", 2, "CENTER", LUI_Orb, "CENTER", 1, 1, 1)
	LUI_Orb.Ring3:SetBackdrop({
		bgFile = fdir.."ring_inner", 
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
		tile = 0, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI_Orb.Ring3:SetBackdropColor(0.25, 0.25, 0.25, 0.7)
	LUI_Orb.Ring3:SetBackdropBorderColor(0, 0, 0, 0)
	LUI_Orb.Ring3:Show()
	]]
	
	LUI_Orb.Ring4 = LUI:CreateMeAFrame("Frame", nil, LUI_Orb, 115, 115, 1, "LOW", 1, "CENTER", LUI_Orb, "CENTER", 0, -1, 1)
	LUI_Orb.Ring4:SetBackdrop({
		bgFile = fdir.."ring_inner2", 
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
		tile = 0, tileSize = 0, edgeSize = 1, 
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI_Orb.Ring4:SetBackdropBorderColor(0, 0, 0, 0)
	LUI_Orb.Ring4:Show()
	
	--[[
	LUI_Orb.Ring5 = LUI:CreateMeAFrame("FRAME", nil, LUI_Orb, 118, 118, 1, "LOW", 2, "CENTER", LUI_Orb, "CENTER", 0, -1, 1)
	LUI_Orb.Ring5:SetBackdrop({
		bgFile = fdir.."ring_inner3", 
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
		tile = 0, tileSize = 0, edgeSize = 1, 
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI_Orb.Ring5:SetBackdropColor(0.25, 0.25, 0.25, 0.7)
	LUI_Orb.Ring5:SetBackdropBorderColor(0, 0, 0, 0)
	LUI_Orb.Ring5:Show()
	]]
	
	LUI_Orb.Cycle = LUI:CreateMeAFrame("Frame", nil, LUI_Orb, 115, 115, 1, "LOW", 0, "CENTER", LUI_Orb, "CENTER", 0, -1, 1)
	LUI_Orb.Cycle:SetBackdrop({
		bgFile = fdir.."ring_inner4", 
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
		tile = 0, tileSize = 0, edgeSize = 1, 
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI_Orb.Cycle:SetBackdropColor(0.25, 0.25, 0.25, 0.7)
	LUI_Orb.Cycle:SetBackdropBorderColor(0, 0, 0, 0)
	LUI_Orb.Cycle:Show()
	
	LUI_Orb.Ring7 = LUI:CreateMeAFrame("Frame", nil, LUI_Orb, 77, 75, 1, "LOW", 3, "CENTER", LUI_Orb, "CENTER", 1, -1, 1)
	LUI_Orb.Ring7:SetBackdrop({
		bgFile = fdir.."ring", 
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = 0, tileSize = 0, edgeSize = 1, 
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI_Orb.Ring7:SetBackdropBorderColor(0, 0, 0, 0)
	LUI_Orb.Ring7:Show()
	
	LUI_Orb:RegisterForClicks("AnyUp")
	LUI_Orb:SetScript("OnClick", function(self)
		isAllShown = (Panels.db.profile.Chat.IsShown and Panels.db.profile.Tps.IsShown and Panels.db.profile.Dps.IsShown and Panels.db.profile.Raid.IsShown)
		
		if not isAllShown then
			isAllShown = true
			
			LUI_Orb.Cycle:SetBackdropColor(unpack(orb_cycle))
			
			for _, k in pairs({"Chat", "Tps", "Dps", "Raid"}) do
				local v = LUI_Navi[k]
				if v:GetAlpha() == 0 then
					local a = k == "Chat" and "ChatAlphaAnchor" or Panels.db.profile[k].Anchor
					
					if _G[a] then
						v.AlphaIn:Show()
						Panels:AlphaIn(k)
					end
				end
			end
			
			if db.Chat.SecondChatFrame then ChatAlphaAnchor2:Show() end
		else
			isAllShown = false
			
			LUI_Orb.Cycle:SetBackdropColor(0.25, 0.25, 0.25, 0.7)
			
			for _, k in pairs({"Chat", "Tps", "Dps", "Raid"}) do
				local v = LUI_Navi[k]
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
	
	------------------------------------------------------
	-- / CHAT BUTTON / --
	------------------------------------------------------
	
	LUI_Navi.Chat = LUI:CreateMeAFrame("Frame", nil, LUI_Orb, 126, 120, 1, "LOW", 1, "LEFT", LUI_Orb, "LEFT", -176, 73, 0)
	LUI_Navi.Chat:SetBackdrop({
		bgFile = fdir.."button_left2", 
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
		tile = 0, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI_Navi.Chat:SetBackdropColor(unpack(navi))
	LUI_Navi.Chat:SetBackdropBorderColor(0, 0, 0, 0)
	LUI_Navi.Chat:Show()
	
	LUI_Navi.Chat.Hover = LUI:CreateMeAFrame("Frame", nil, LUI_Orb, 124, 120, 1, "LOW", 1, "LEFT", LUI_Orb, "LEFT", -176, 73, 0)
	LUI_Navi.Chat.Hover:SetBackdrop({
		bgFile = fdir.."button_left2_hover", 
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
		tile = 0, tileSize = 0, edgeSize = 1, 
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI_Navi.Chat.Hover:SetBackdropColor(unpack(navi_hover))
	LUI_Navi.Chat.Hover:SetBackdropBorderColor(0, 0, 0, 0)
	LUI_Navi.Chat.Hover:Show()
	
	LUI_Navi.Chat.Clicker = CreateFrame("Button", nil, LUI_Navi.Chat)
	LUI_Navi.Chat.Clicker:SetWidth(70)
	LUI_Navi.Chat.Clicker:SetHeight(30)
	LUI_Navi.Chat.Clicker:SetScale(1)
	LUI_Navi.Chat.Clicker:SetFrameStrata("LOW")
	LUI_Navi.Chat.Clicker:SetFrameLevel(2)
	LUI_Navi.Chat.Clicker:SetPoint("CENTER", LUI_Navi.Chat, "CENTER", -5, -42)
	LUI_Navi.Chat.Clicker:SetAlpha(0)
	
	LUI_Navi.Chat.Clicker:RegisterForClicks("AnyUp")
	LUI_Navi.Chat.Clicker:SetScript("OnEnter", function(self) LUI_Navi.Chat.Hover:SetAlpha(1) end)
	LUI_Navi.Chat.Clicker:SetScript("OnLeave", function(self) LUI_Navi.Chat.Hover:SetAlpha(0) end)
	LUI_Navi.Chat.Clicker:SetScript("OnClick", function(self)
		if LUI_Navi.Chat:GetAlpha() == 0 then
			LUI_Navi.Chat.AlphaIn:Show()
			
			Panels:AlphaIn("Chat")
			
			Panels.db.profile.Chat.IsShown = true
		else
			LUI_Navi.Chat.AlphaOut:Show()
			
			Panels:AlphaOut("Chat")
			
			Panels.db.profile.Chat.IsShown = false
		end
	end)
	
	------------------------------------------------------
	-- / TPS BUTTON / --
	------------------------------------------------------
	
	LUI_Navi.Tps = LUI:CreateMeAFrame("Frame", nil, LUI_Orb, 63, 67, 1, "LOW", 1, "LEFT", LUI_Orb, "LEFT", -74, 42, 0)
	LUI_Navi.Tps:SetBackdrop({
		bgFile = fdir.."button_left1", 
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
		tile = 0, tileSize = 0, edgeSize = 1, 
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI_Navi.Tps:SetBackdropColor(unpack(navi))
	LUI_Navi.Tps:SetBackdropBorderColor(0, 0, 0, 0)
	LUI_Navi.Tps:Show()
	
	LUI_Navi.Tps.Hover = LUI:CreateMeAFrame("Frame", nil, LUI_Orb, 63, 60, 1, "LOW", 1, "LEFT", LUI_Orb, "LEFT", -74, 40, 0)
	LUI_Navi.Tps.Hover:SetBackdrop({
		bgFile = fdir.."button_left1_hover", 
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
		tile = 0, tileSize = 0, edgeSize = 1, 
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI_Navi.Tps.Hover:SetBackdropColor(unpack(navi_hover))
	LUI_Navi.Tps.Hover:SetBackdropBorderColor(0, 0, 0, 0)
	LUI_Navi.Tps.Hover:Show()
	
	LUI_Navi.Tps.Clicker = CreateFrame("Button", nil, LUI_Navi.Tps)
	LUI_Navi.Tps.Clicker:SetWidth(63)
	LUI_Navi.Tps.Clicker:SetHeight(30)
	LUI_Navi.Tps.Clicker:SetScale(1)
	LUI_Navi.Tps.Clicker:SetFrameStrata("LOW")
	LUI_Navi.Tps.Clicker:SetFrameLevel(2)
	LUI_Navi.Tps.Clicker:SetPoint("CENTER", LUI_Navi.Tps, "CENTER", 0, -12)
	LUI_Navi.Tps.Clicker:SetAlpha(0)
	
	LUI_Navi.Tps.Clicker:RegisterForClicks("AnyUp")
	LUI_Navi.Tps.Clicker:SetScript("OnEnter", function(self) LUI_Navi.Tps.Hover:SetAlpha(1) end)
	LUI_Navi.Tps.Clicker:SetScript("OnLeave", function(self) LUI_Navi.Tps.Hover:SetAlpha(0) end)
	LUI_Navi.Tps.Clicker:SetScript("OnClick", function(self)
		if _G[Panels.db.profile.Tps.Anchor] then 
			if LUI_Navi.Tps:GetAlpha() == 0 then
				LUI_Navi.Tps.AlphaIn:Show()
				
				Panels:AlphaIn("Tps")
				
				Panels.db.profile.Tps.IsShown = true
			else
				LUI_Navi.Tps.AlphaOut:Show()
				
				Panels:AlphaOut("Tps")
				
				Panels.db.profile.Tps.IsShown = false
			end
		end
	end)
	
	------------------------------------------------------
	-- / DPS BUTTON / --
	------------------------------------------------------
	
	LUI_Navi.Dps = LUI:CreateMeAFrame("Frame", nil, LUI_Orb, 63, 67, 1, "LOW", 1, "RIGHT", LUI_Orb, "RIGHT", 77, 45, 0)
	LUI_Navi.Dps:SetBackdrop({
		bgFile = fdir.."button_right1", 
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
		tile = 0, tileSize = 0, edgeSize = 1, 
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI_Navi.Dps:SetBackdropColor(unpack(navi))
	LUI_Navi.Dps:SetBackdropBorderColor(0, 0, 0, 0)
	LUI_Navi.Dps:Show()
	
	LUI_Navi.Dps.Hover = LUI:CreateMeAFrame("Frame", nil, LUI_Orb, 63, 60, 1, "LOW", 1, "RIGHT", LUI_Orb, "RIGHT", 77, 43, 0)
	LUI_Navi.Dps.Hover:SetBackdrop({
		bgFile = fdir.."button_right1_hover", 
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
		tile = 0, tileSize = 0, edgeSize = 1, 
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI_Navi.Dps.Hover:SetBackdropColor(unpack(navi_hover))
	LUI_Navi.Dps.Hover:SetBackdropBorderColor(0, 0, 0, 0)
	LUI_Navi.Dps.Hover:Show()
	
	LUI_Navi.Dps.Clicker = CreateFrame("Button", nil, LUI_Navi.Dps)
	LUI_Navi.Dps.Clicker:SetWidth(63)
	LUI_Navi.Dps.Clicker:SetHeight(30)
	LUI_Navi.Dps.Clicker:SetScale(1)
	LUI_Navi.Dps.Clicker:SetFrameStrata("LOW")
	LUI_Navi.Dps.Clicker:SetFrameLevel(2)
	LUI_Navi.Dps.Clicker:SetPoint("CENTER", LUI_Navi.Dps, "CENTER", 0, -12)
	LUI_Navi.Dps.Clicker:SetAlpha(0)
	
	LUI_Navi.Dps.Clicker:RegisterForClicks("AnyUp")
	LUI_Navi.Dps.Clicker:SetScript("OnEnter", function(self) LUI_Navi.Dps.Hover:SetAlpha(1) end)
	LUI_Navi.Dps.Clicker:SetScript("OnLeave", function(self) LUI_Navi.Dps.Hover:SetAlpha(0) end)
	LUI_Navi.Dps.Clicker:SetScript("OnClick", function(self)
		if _G[Panels.db.profile.Dps.Anchor] then 
			if LUI_Navi.Dps:GetAlpha() == 0 then
				LUI_Navi.Dps.AlphaIn:Show()
				
				Panels:AlphaIn("Dps")
				
				Panels.db.profile.Dps.IsShown = true
			else
				LUI_Navi.Dps.AlphaOut:Show()
				
				Panels:AlphaOut("Dps")
				
				Panels.db.profile.Dps.IsShown = false
			end
		end
	end)
	
	------------------------------------------------------
	-- / RAID BUTTON / --
	------------------------------------------------------
	
	LUI_Navi.Raid = LUI:CreateMeAFrame("Frame", nil, LUI_Orb, 126, 120, 1, "LOW", 1, "RIGHT", LUI_Orb, "RIGHT", 184, 71, 0)
	LUI_Navi.Raid:SetBackdrop({
		bgFile = fdir.."button_right2", 
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
		tile = 0, tileSize = 0, edgeSize = 1, 
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI_Navi.Raid:SetBackdropColor(unpack(navi))
	LUI_Navi.Raid:SetBackdropBorderColor(0, 0, 0, 0)
	LUI_Navi.Raid:Show()
	
	LUI_Navi.Raid.Hover = LUI:CreateMeAFrame("Frame", nil, LUI_Orb, 124, 120, 1, "LOW", 1, "RIGHT", LUI_Orb, "RIGHT", 182, 71, 0)
	LUI_Navi.Raid.Hover:SetBackdrop({
		bgFile = fdir.."button_right2_hover", 
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
		tile = 0, tileSize = 0, edgeSize = 1, 
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI_Navi.Raid.Hover:SetBackdropColor(unpack(navi_hover))
	LUI_Navi.Raid.Hover:SetBackdropBorderColor(0, 0, 0, 0)
	LUI_Navi.Raid.Hover:Show()

	LUI_Navi.Raid.Clicker = CreateFrame("Button", nil, LUI_Navi.Raid)
	LUI_Navi.Raid.Clicker:SetWidth(78)
	LUI_Navi.Raid.Clicker:SetHeight(30)
	LUI_Navi.Raid.Clicker:SetScale(1)
	LUI_Navi.Raid.Clicker:SetFrameStrata("LOW")
	LUI_Navi.Raid.Clicker:SetFrameLevel(2)
	LUI_Navi.Raid.Clicker:SetPoint("CENTER", LUI_Navi.Raid, "CENTER", 0, -42)
	LUI_Navi.Raid.Clicker:SetAlpha(0)
	
	LUI_Navi.Raid.Clicker:RegisterForClicks("AnyUp")
	LUI_Navi.Raid.Clicker:SetScript("OnEnter", function(self) LUI_Navi.Raid.Hover:SetAlpha(1) end)
	LUI_Navi.Raid.Clicker:SetScript("OnLeave", function(self) LUI_Navi.Raid.Hover:SetAlpha(0) end)
	LUI_Navi.Raid.Clicker:SetScript("OnClick", function(self)
		if _G[Panels.db.profile.Raid.Anchor] then 
			if LUI_Navi.Raid:GetAlpha() == 0 then
				LUI_Navi.Raid.AlphaIn:Show()
				
				Panels:AlphaIn("Raid")
				
				Panels.db.profile.Raid.IsShown = true
			else
				LUI_Navi.Raid.AlphaOut:Show()
				
				Panels:AlphaOut("Raid")
				
				Panels.db.profile.Raid.IsShown = false
			end
		end
	end)
	
	------------------------------------------------------
	-- / INFO PANEL LEFT / --
	------------------------------------------------------
	
	LUI_Info.Left = LUI:CreateMeAFrame("Frame", nil, UIParent, 25, 25, 1, "BACKGROUND", 0, "BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0, 1)
	
	LUI_Info.Left.Panel = LUI:CreateMeAFrame("FRAME", nil, LUI_Info.Left, 1024, 1024, 1, "BACKGROUND", 1, "BOTTOMLEFT", LUI_Info.Left, "BOTTOMLEFT", -30, -31, 1)
	LUI_Info.Left.Panel:SetBackdrop({
		bgFile = fdir.."info_left", 
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
		tile = 0, tileSize = 0, edgeSize = 1, 
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI_Info.Left.Panel:SetBackdropColor(0, 0, 0, 0.9)
	LUI_Info.Left.Panel:SetBackdropBorderColor(0, 0, 0, 0)
	LUI_Info.Left.Panel:Show()
	
	LUI_Info.Left.BG = LUI:CreateMeAFrame("FRAME", nil, LUI_Info.Left, 1024, 1024, 1, "BACKGROUND", 0, "BOTTOMLEFT", LUI_Info.Left, "BOTTOMLEFT", -23, -23, 1)
	LUI_Info.Left.BG:SetBackdrop({
		bgFile = fdir.."info_left_back", 
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
		tile = 0, tileSize = 0, edgeSize = 1, 
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI_Info.Left.BG:SetBackdropColor(unpack(color_bottom))
	LUI_Info.Left.BG:SetBackdropBorderColor(0, 0, 0, 0)
	LUI_Info.Left.BG:Show()
	
	------------------------------------------------------
	-- / INFO PANEL RIGHT / --
	------------------------------------------------------
	
	LUI_Info.Right = LUI:CreateMeAFrame("Frame", nil, UIParent, 25, 25, 1, "BACKGROUND", 0, "BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0, 1)
	
	LUI_Info.Right.Panel = LUI:CreateMeAFrame("FRAME", nil, LUI_Info.Right, 1024, 1024, 1, "BACKGROUND", 1, "BOTTOMRIGHT", LUI_Info.Right, "BOTTOMRIGHT", 36, -31, 1)
	LUI_Info.Right.Panel:SetBackdrop({
		bgFile = fdir.."info_right", 
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
		tile = 0, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI_Info.Right.Panel:SetBackdropColor(0, 0, 0, 0.9)
	LUI_Info.Right.Panel:SetBackdropBorderColor(0, 0, 0, 0)
	LUI_Info.Right.Panel:Show()
	
	LUI_Info.Right.BG = LUI:CreateMeAFrame("FRAME", nil, LUI_Info.Right, 1024, 1024, 1, "BACKGROUND", 0, "BOTTOMRIGHT", LUI_Info.Right, "BOTTOMRIGHT", 29, -23, 1)
	LUI_Info.Right.BG:SetBackdrop({
		bgFile = fdir.."info_right_back", 
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
		tile = 0, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI_Info.Right.BG:SetBackdropColor(unpack(color_bottom))
	LUI_Info.Right.BG:SetBackdropBorderColor(0, 0, 0, 0)
	LUI_Info.Right.BG:Show()
	
	------------------------------------------------------
	-- / INFO PANEL TOPLEFT / --
	------------------------------------------------------

	LUI_Info.Topleft = LUI:CreateMeAFrame("Frame", nil, UIParent, 25, 25, 1, "BACKGROUND", 0, "CENTER", LUI_Orb, "CENTER", -212, 30, 1)
	
	LUI_Info.Topleft.BG = LUI:CreateMeAFrame("FRAME", nil, LUI_Info.Topleft, 1012, 1024, 1, "BACKGROUND", 0, "TOPRIGHT", LUI_Info.Topleft, "TOPRIGHT", 9, 11, 1)
	LUI_Info.Topleft.BG:SetBackdrop({
		bgFile = fdir.."info_top_left2", 
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
		tile = 0, tileSize = 0, edgeSize = 1, 
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI_Info.Topleft.BG:SetBackdropColor(unpack(color_top))
	LUI_Info.Topleft.BG:SetBackdropBorderColor(0, 0, 0, 0)
	LUI_Info.Topleft.BG:Show()
	
	------------------------------------------------------
	-- / INFO PANEL TOPRIGHT / --
	------------------------------------------------------
	
	LUI_Info.Topright = LUI:CreateMeAFrame("Frame", nil, UIParent, 25, 25, 1, "BACKGROUND", 0, "CENTER", LUI_Orb, "CENTER", 209, 30, 1)
	
	LUI_Info.Topright.BG = LUI:CreateMeAFrame("FRAME", nil, LUI_Info.Topright, 1015, 1024, 1, "BACKGROUND", 0, "TOPLEFT", LUI_Info.Topright, "TOPLEFT", -9, 11, 1)
	LUI_Info.Topright.BG:SetBackdrop({
		bgFile = fdir.."info_top_right2", 
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
		tile = 0, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI_Info.Topright.BG:SetBackdropColor(unpack(color_top))
	LUI_Info.Topright.BG:SetBackdropBorderColor(0, 0, 0, 0)
	LUI_Info.Topright.BG:Show()
	
	------------------------------------------------------
	-- / SCRIPTS / --
	------------------------------------------------------
	
	local alphain = function(self, elapsed)
		self.timer = self.timer + elapsed
		if self.timer < .4 then
			LUI_Navi[self.kind]:SetAlpha(self.timer / .4)
		else
			LUI_Navi[self.kind]:SetAlpha(1)
			self.timer = 0
			self:Hide()
		end
	end
	local alphaout = function(self, elapsed)
		self.timer = self.timer + elapsed
		if self.timer < .4 then
			LUI_Navi[self.kind]:SetAlpha(1 - self.timer / .4)
		else
			LUI_Navi[self.kind]:SetAlpha(0)
			self.timer = 0
			self:Hide()
		end
	end
	
	for _, k in pairs({"Chat", "Tps", "Dps", "Raid"}) do
		local v = LUI_Navi[k]
		
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
	self.db = LUI.db.profile
	db = self.db
end

function module:OnEnable()
	self:SetFrames()
end

function module:OnDisable()
end