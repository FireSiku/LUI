--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: panels.lua
	Description: Main Panels Module
	Version....: 1.2
	Rev Date...: 13/03/2012 [dd/mm/yyyy]

	Edits:
		v1.0: Loui
		v1.1: Zista
		v1.2: Thaly
]]

-- External references.
local _, LUI = ...
local module = LUI:NewModule("Panels", "LUIDevAPI", "AceHook-3.0", "AceEvent-3.0")
local ThemesDB

local db, dbd --luacheck:ignore
local frameBackgrounds_ = {"LEFT", "RIGHT", "NONE"}
local frameBackgrounds2_ = {"LUI v3", "NONE"}
local animations = {"AlphaSlide", "None"}
local directions = {"SOLID", "TOPLEFT", "TOP", "TOPRIGHT", "RIGHT", "BOTTOMRIGHT", "BOTTOM", "BOTTOMLEFT", "LEFT"}
local fdir = "Interface\\AddOns\\LUI\\media\\templates\\v3\\"

local NUM_CHAT_WINDOWS = _G.NUM_CHAT_WINDOWS
local ChatFrame1 = _G.ChatFrame1
local Minimap = _G.Minimap

LUI.Versions.panels = 1.2
local ChatAlphaAnchor

local directory = "Interface\\AddOns\\LUI\\media\\templates\\v3\\"

LUI.Navi = {}
LUI.Info = {}

local backgrounds = {}
local addonAnchors = {
	raid = {
		Plexus = "PlexusLayoutFrame",
		Grid2 = "Grid2LayoutFrame",
		Healbot = "f1_HealBot_Action",
		Vuhdo = "Vd1",
		oUF = "oUF_LUI_raid",
		Blizzard = "CompactRaidFrameContainer",
	},
	meter = {
		Recount = "Recount_MainWindow",
		Omen = "OmenAnchor",
		Skada = "SkadaBarWindowSkada",
		Details = "DetailsBaseFrame1",
		Details_2nd = "DetailsBaseFrame2",
	}
}

local isAllShown = false
function module:IsAllShown(bool)
	if bool ~= nil then isAllShown = bool end
	return isAllShown
end

function module:CheckPanels()
	if db.Chat.AlwaysShow and db.Tps.AlwaysShow and db.Dps.AlwaysShow and db.Raid.AlwaysShow then
		module:IsAllShown(true)
		module:SetOrbCycleColor()
	elseif db.Chat.IsShown and db.Tps.IsShown and db.Dps.IsShown and db.Raid.IsShown then
		module:IsAllShown(true)
		module:SetOrbCycleColor()
	else
		module:IsAllShown(false)
	end

	if db.Minimap.AlwaysShow or db.Minimap.IsShown then
		Minimap:SetAlpha(1)
		Minimap:Show()
		db.Minimap.IsShown = true
	else
		Minimap:SetAlpha(0)
		Minimap:Hide()
		db.Minimap.IsShown = false
	end

	for i=1,NUM_CHAT_WINDOWS do
		for _,v in pairs{"","Tab"}do
			local f=_G["ChatFrame"..i..v]
			f.ORShow = f.Show --Give every chat frame an ORiginalShow function to allow overwriting of Show later on
		end
	end

	if db.Chat.AlwaysShow or db.Chat.IsShown then
		module:SetNaviAlpha("Chat", 1)

		ChatAlphaAnchor:SetAlpha(1)
		--if LUI.db.profile.Chat.SecondChatFrame then ChatAlphaAnchor2:SetAlpha(1) end

		db.Chat.IsShown = true
		LUI:SetChatVisible(true)
	else
		module:SetNaviAlpha("Chat", 0)

		ChatAlphaAnchor:SetAlpha(0)
		--if LUI.db.profile.Chat.SecondChatFrame then ChatAlphaAnchor2:SetAlpha(0) end

		db.Chat.IsShown = false
		--LUI:SetChatVisible(false)
		LUI:SetChatVisible(true)
	end


	if (db.Tps.AlwaysShow or db.Tps.IsShown) and _G[db.Tps.Anchor] then
		module:SetNaviAlpha("Tps", 1)

		_G[db.Tps.Anchor]:SetAlpha(1)
		_G[db.Tps.Anchor]:Show()
		for _, f in pairs(self:LoadAdditional(db.Tps.Additional)) do
			_G[f]:SetAlpha(1)
			_G[f]:Show()
		end

		db.Tps.IsShown = true
	else
		module:SetNaviAlpha("Tps", 0)

		if _G[db.Tps.Anchor] then
			_G[db.Tps.Anchor]:SetAlpha(0)
			_G[db.Tps.Anchor]:Hide()
			for _, f in pairs(self:LoadAdditional(db.Tps.Additional)) do
				_G[f]:SetAlpha(0)
				_G[f]:Hide()
			end
		end
		

		db.Tps.IsShown = false
	end

	if (db.Dps.AlwaysShow or db.Dps.IsShown) and _G[db.Dps.Anchor] then
		module:SetNaviAlpha("Dps", 1)

		_G[db.Dps.Anchor]:SetAlpha(1)
		_G[db.Dps.Anchor]:Show()
		for _, f in pairs(self:LoadAdditional(db.Dps.Additional)) do
			_G[f]:SetAlpha(1)
			_G[f]:Show()
		end

		db.Dps.IsShown = true
	else
		module:SetNaviAlpha("Dps", 0)

		if _G[db.Dps.Anchor] then
			_G[db.Dps.Anchor]:SetAlpha(0)
			_G[db.Dps.Anchor]:Hide()
			for _, f in pairs(self:LoadAdditional(db.Dps.Additional)) do
				_G[f]:SetAlpha(0)
				_G[f]:Hide()
			end
		end

		db.Dps.IsShown = false
	end

	if (db.Raid.AlwaysShow or db.Raid.IsShown) and _G[db.Raid.Anchor] then
		module:SetNaviAlpha("Raid", 1)

		_G[db.Raid.Anchor]:SetAlpha(1)
		_G[db.Raid.Anchor]:Show()
		for _, f in pairs(self:LoadAdditional(db.Raid.Additional)) do
			_G[f]:SetAlpha(1)
			_G[f]:Show()
		end

		db.Raid.IsShown = true
	else
		module:SetNaviAlpha("Raid", 0)

		if _G[db.Raid.Anchor] then
			_G[db.Raid.Anchor]:SetAlpha(0)
			_G[db.Raid.Anchor]:Hide()
			for _, f in pairs(self:LoadAdditional(db.Raid.Additional)) do
				_G[f]:SetAlpha(0)
				_G[f]:Hide()
			end
		end

		db.Raid.IsShown = false
	end

	if LUI:GetModule("Micromenu", true) and LUI.MicroMenu then
		if db.MicroMenu.AlwaysShow or db.MicroMenu.IsShown then
			LUI.MicroMenu.Button:SetAlpha(1)
			LUI.MicroMenu.Button:Show()
		else
			LUI.MicroMenu.Button:SetAlpha(0)
			LUI.MicroMenu.Button:Hide()
		end
	end
end

function LUI:SetChatVisible(setVisible)
	for i=1,NUM_CHAT_WINDOWS do
		for _,v in pairs{"","Tab"}do
			local f=_G["ChatFrame"..i..v]
			if setVisible then
				f.Show = f.ORShow
			else
				f.v=f:IsVisible()
				f.Show = f.Hide
			end
			if f.v then
				f:Show()
			end
		end
	end
end

function module:LoadAdditional(str, debug)
	if not str or str:trim() == "" then return {} end

	local frames = {}

	if strfind(str, "%s") then
		local part1, part2
		while strfind(str, "%s")  do
			part1, part2 = strsplit(" ", str, 2)
			str = part1..part2
		end
	end

	if strfind(str, ",") then
		local part1, part2
		while strfind(str, ",") do
			part1, part2 = strsplit(",", str, 2)
			if _G[part1] then
				table.insert(frames, part1)
			end
			str = part2
		end
	end
	if str and str:trim() ~= "" then
		if _G[str] then
			table.insert(frames, str)
		end
	end

	if debug then return end
	return frames
end

-- Black voodoo magic used for compatibility for a deprecated function
local rotationCoords = {
	[0] = {
		-0.20710676908493, -- [1]
		-0.20710676908493, -- [2]
		-0.20710676908493, -- [3]
		1.20710682868958, -- [4]
		1.20710682868958, -- [5]
		-0.20710676908493, -- [6]
		1.20710682868958, -- [7]
		1.20710682868958, -- [8]
	},
	[90] = {
		1.20710682868958, -- [4]
		-0.20710682868958, -- [6]
		-0.20710682868958, -- [6]
		-0.20710676908493, -- [6]
		1.20710682868958, -- [4]
		1.20710682868958, -- [4]
		-0.20710676908493, -- [6]
		1.20710682868958, -- [4]
	},
	[180] = {
		1.20710682868958, -- [4]
		1.20710682868958, -- [4]
		1.20710682868958, -- [4]
		-0.20710676908493, -- [6]
		-0.20710676908493, -- [6]
		1.20710682868958, -- [4]
		-0.20710676908493, -- [6]
		-0.20710682868958, -- [6]
	},
	[270] = {
		-0.20710670948029, -- [1]
		1.20710682868958, -- [4]
		1.20710682868958, -- [4]
		1.2071067094803, -- [4]
		-0.20710682868958, -- [6]
		-0.20710670948029, -- [6]
		1.2071067094803, -- [7]
		-0.20710682868958, -- [6]
	},
}

function LUI:CanAlterFrame(frame)
	if not (frame:IsProtected() and _G.InCombatLockdown()) then
		return true
	end
end

local function RotateTexture(self, degrees)
	local r = rotationCoords[degrees]
	self:SetTexCoord(r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8])
end

local function Set(f, d, p, w, h, s, r, g, b, a, rc, gc, bc, ac)
	f:SetParent(p)
	f:SetWidth(w)
	f:SetHeight(h)
	f:SetScale(s)
	f:SetFrameStrata("BACKGROUND")

	f.c:SetVertexColor(rc, gc, bc, ac)

	local color = CreateColor(r, g, b, a)
	local colorNoAlpha = CreateColor(r, g, b, 0)

	if d == "SOLID" then
		f.c:SetTexture(fdir.."panelbg1.tga")
		RotateTexture(f.c, 0)

		f.tl:SetVertexColor(r, g, b, a)
		f.tr:SetVertexColor(r, g, b, a)
		f.bl:SetVertexColor(r, g, b, a)
		f.br:SetVertexColor(r, g, b, a)

		f.t:SetGradient("HORIZONTAL", color, color)
		f.b:SetGradient("HORIZONTAL", color, color)
		f.l:SetGradient("VERTICAL", color, color)
		f.r:SetGradient("VERTICAL", color, color)
	elseif d == "LEFT" then
		f.c:SetTexture(fdir.."panelbg2.tga")
		RotateTexture(f.c, 90)

		f.tl:SetVertexColor(r, g, b, a)
		f.tr:SetVertexColor(r, g, b, 0)
		f.bl:SetVertexColor(r, g, b, a)
		f.br:SetVertexColor(r, g, b, 0)

		f.t:SetGradient("HORIZONTAL", color, colorNoAlpha)
		f.b:SetGradient("HORIZONTAL", color, colorNoAlpha)
		f.l:SetGradient("VERTICAL", color, color)
		f.r:SetGradient("VERTICAL", colorNoAlpha, colorNoAlpha)
	elseif d == "TOP" then
		f.c:SetTexture(fdir.."panelbg2.tga")
		RotateTexture(f.c, 0)

		f.tl:SetVertexColor(r, g, b, a)
		f.tr:SetVertexColor(r, g, b, a)
		f.bl:SetVertexColor(r, g, b, 0)
		f.br:SetVertexColor(r, g, b, 0)

		f.t:SetGradient("HORIZONTAL", color, color)
		f.b:SetGradient("HORIZONTAL", colorNoAlpha, colorNoAlpha)
		f.l:SetGradient("VERTICAL", colorNoAlpha, color)
		f.r:SetGradient("VERTICAL", colorNoAlpha, color)
	elseif d == "RIGHT" then
		f.c:SetTexture(fdir.."panelbg2.tga")
		RotateTexture(f.c, 270)

		f.tl:SetVertexColor(r, g, b, 0)
		f.tr:SetVertexColor(r, g, b, a)
		f.bl:SetVertexColor(r, g, b, 0)
		f.br:SetVertexColor(r, g, b, a)

		f.t:SetGradient("HORIZONTAL", colorNoAlpha, color)
		f.b:SetGradient("HORIZONTAL", colorNoAlpha, color)
		f.l:SetGradient("VERTICAL", colorNoAlpha, colorNoAlpha)
		f.r:SetGradient("VERTICAL", color, color)
	elseif d == "BOTTOM" then
		f.c:SetTexture(fdir.."panelbg2.tga")
		RotateTexture(f.c, 180)

		f.tl:SetVertexColor(r, g, b, 0)
		f.tr:SetVertexColor(r, g, b, 0)
		f.bl:SetVertexColor(r, g, b, a)
		f.br:SetVertexColor(r, g, b, a)

		f.t:SetGradient("HORIZONTAL", colorNoAlpha, colorNoAlpha)
		f.b:SetGradient("HORIZONTAL", color, color)
		f.l:SetGradient("VERTICAL", color, colorNoAlpha)
		f.r:SetGradient("VERTICAL", color, colorNoAlpha)
	elseif d == "TOPLEFT" then
		f.c:SetTexture(fdir.."panelbg3.tga")
		RotateTexture(f.c, 0)

		f.tl:SetVertexColor(r, g, b, a)
		f.tr:SetVertexColor(r, g, b, 0)
		f.bl:SetVertexColor(r, g, b, 0)
		f.br:SetVertexColor(r, g, b, 0)

		f.t:SetGradient("HORIZONTAL", color, colorNoAlpha)
		f.b:SetGradient("HORIZONTAL", colorNoAlpha, colorNoAlpha)
		f.l:SetGradient("VERTICAL", colorNoAlpha, color)
		f.r:SetGradient("VERTICAL", colorNoAlpha, colorNoAlpha)
	elseif d == "TOPRIGHT" then
		f.c:SetTexture(fdir.."panelbg3.tga")
		RotateTexture(f.c, 270)

		f.tl:SetVertexColor(r, g, b, 0)
		f.tr:SetVertexColor(r, g, b, a)
		f.bl:SetVertexColor(r, g, b, 0)
		f.br:SetVertexColor(r, g, b, 0)

		f.t:SetGradient("HORIZONTAL", colorNoAlpha, color)
		f.b:SetGradient("HORIZONTAL", colorNoAlpha, colorNoAlpha)
		f.l:SetGradient("VERTICAL", colorNoAlpha, colorNoAlpha)
		f.r:SetGradient("VERTICAL", colorNoAlpha, color)
	elseif d == "BOTTOMRIGHT" then
		f.c:SetTexture(fdir.."panelbg3.tga")
		RotateTexture(f.c, 180)

		f.tl:SetVertexColor(r, g, b, 0)
		f.tr:SetVertexColor(r, g, b, 0)
		f.bl:SetVertexColor(r, g, b, 0)
		f.br:SetVertexColor(r, g, b, a)

		f.t:SetGradient("HORIZONTAL", colorNoAlpha, colorNoAlpha)
		f.b:SetGradient("HORIZONTAL", colorNoAlpha, color)
		f.l:SetGradient("VERTICAL", colorNoAlpha, colorNoAlpha)
		f.r:SetGradient("VERTICAL", color, colorNoAlpha)
	elseif d == "BOTTOMLEFT" then
		f.c:SetTexture(fdir.."panelbg3.tga")
		RotateTexture(f.c, 90)

		f.tl:SetVertexColor(r, g, b, 0)
		f.tr:SetVertexColor(r, g, b, 0)
		f.bl:SetVertexColor(r, g, b, a)
		f.br:SetVertexColor(r, g, b, 0)

		f.t:SetGradient("HORIZONTAL", colorNoAlpha, colorNoAlpha)
		f.b:SetGradient("HORIZONTAL", color, colorNoAlpha)
		f.l:SetGradient("VERTICAL", color, colorNoAlpha)
		f.r:SetGradient("VERTICAL", colorNoAlpha, colorNoAlpha)
	end

end

local bordersize = 9
local padding = 0
local function CreateBackground(kind)
	local f = CreateFrame("Frame", "LUIPanel_"..kind, UIParent)

	f.c = f:CreateTexture(nil, "BACKGROUND")
	f.c:SetPoint("TOPLEFT", f, "TOPLEFT")
	f.c:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT")

	f.tl = f:CreateTexture(nil, "BACKGROUND")
	f.tl:SetWidth(bordersize)
	f.tl:SetHeight(bordersize)
	f.tl:SetPoint("BOTTOMRIGHT", f, "TOPLEFT", -padding, padding)
	f.tl:SetTexture(fdir.."panelcorner.tga")
	RotateTexture(f.tl, 0)

	f.tr = f:CreateTexture(nil, "BACKGROUND")
	f.tr:SetWidth(bordersize)
	f.tr:SetHeight(bordersize)
	f.tr:SetPoint("BOTTOMLEFT", f, "TOPRIGHT", padding, padding)
	f.tr:SetTexture(fdir.."panelcorner.tga")
	RotateTexture(f.tr, 270)

	f.bl = f:CreateTexture(nil, "BACKGROUND")
	f.bl:SetWidth(bordersize)
	f.bl:SetHeight(bordersize)
	f.bl:SetPoint("TOPRIGHT", f, "BOTTOMLEFT", -padding, -padding)
	f.bl:SetTexture(fdir.."panelcorner.tga")
	RotateTexture(f.bl, 90)

	f.br = f:CreateTexture(nil, "BACKGROUND")
	f.br:SetWidth(bordersize)
	f.br:SetHeight(bordersize)
	f.br:SetPoint("TOPLEFT", f, "BOTTOMRIGHT", padding, -padding)
	f.br:SetTexture(fdir.."panelcorner.tga")
	RotateTexture(f.br, 180)

	f.l = f:CreateTexture(nil, "BACKGROUND")
	f.l:SetWidth(bordersize)
	f.l:SetPoint("TOPRIGHT", f, "TOPLEFT", -padding, padding)
	f.l:SetPoint("BOTTOMRIGHT", f, "BOTTOMLEFT", padding, -padding)
	f.l:SetTexture(fdir.."panelborder.tga")
	RotateTexture(f.l, 90)

	f.r = f:CreateTexture(nil, "BACKGROUND")
	f.r:SetWidth(bordersize)
	f.r:SetPoint("TOPLEFT", f, "TOPRIGHT", padding, padding)
	f.r:SetPoint("BOTTOMLEFT", f, "BOTTOMRIGHT", padding, -padding)
	f.r:SetTexture(fdir.."panelborder.tga")
	RotateTexture(f.r, 270)

	f.t = f:CreateTexture(nil, "BACKGROUND")
	f.t:SetHeight(bordersize)
	f.t:SetPoint("BOTTOMLEFT", f, "TOPLEFT", -padding, padding)
	f.t:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", padding, padding)
	f.t:SetTexture(fdir.."panelborder.tga")
	RotateTexture(f.t, 0)

	f.b = f:CreateTexture(nil, "BACKGROUND")
	f.b:SetHeight(bordersize)
	f.b:SetPoint("TOPLEFT", f, "BOTTOMLEFT", -padding, -padding)
	f.b:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", padding, -padding)
	f.b:SetTexture(fdir.."panelborder.tga")
	RotateTexture(f.b, 180)

	f.Set = Set

	return f
end

function module:AlphaIn(kind)
	if not backgrounds[kind] then return end
	db[kind].IsShown = true

	if LUI:CanAlterFrame(_G[backgrounds[kind].frame]) then
		_G[backgrounds[kind].frame]:Show()

		for _, f in pairs(module:LoadAdditional(db[kind].Additional)) do
			if LUI:CanAlterFrame(_G[f]) then _G[f]:Show() end
		end
	end
	
	if db[kind].Animation == "AlphaSlide" then
		backgrounds[kind].AlphaIn:Show()
	else
		_G[backgrounds[kind].frame]:SetAlpha(1)

		for _, f in pairs(module:LoadAdditional(db[kind].Additional)) do _G[f]:SetAlpha(1) end
	end
end

function module:AlphaOut(kind)
	if not backgrounds[kind] then return end
	db[kind].IsShown = false

	if db[kind].Animation == "AlphaSlide" then
		backgrounds[kind].AlphaOut:Show()

	elseif LUI:CanAlterFrame(_G[backgrounds[kind].frame]) then
		_G[backgrounds[kind].frame]:SetAlpha(0)
		_G[backgrounds[kind].frame]:Hide()

		for _, f in pairs(module:LoadAdditional(db[kind].Additional)) do
			if LUI:CanAlterFrame(_G[f]) then
				_G[f]:SetAlpha(0)
				_G[f]:Hide()
			end
		end
	end
end

function module:CreateBackground(kind)
	if backgrounds[kind] then return end

	local frame
	if kind == "Chat" then
		frame = "ChatAlphaAnchor"
	else
		frame = db[kind].Anchor
	end

	backgrounds[kind] = CreateBackground(kind)

	backgrounds[kind].timerout = 0
	backgrounds[kind].timerin = 0
	backgrounds[kind].alphatimer = .5

	backgrounds[kind].frame = frame

	backgrounds[kind].AlphaOut = CreateFrame("Frame", nil, UIParent)
	backgrounds[kind].AlphaOut:Hide()
	backgrounds[kind].AlphaOut.timerout = 0
	backgrounds[kind].AlphaOut:SetScript("OnUpdate", function(self, elapsed)
		self.timerout = self.timerout + elapsed

		if self.timerout < .5 then
			local alpha = 1 - self.timerout / .5

			if _G[frame] and LUI:CanAlterFrame(_G[frame]) then
				_G[frame]:SetAlpha(alpha)
				for _, f in pairs(module:LoadAdditional(db[kind].Additional)) do
					if LUI:CanAlterFrame(_G[f]) then _G[f]:SetAlpha(alpha) end
				end
			end
		else
			if _G[frame] and LUI:CanAlterFrame(_G[frame]) then
				_G[frame]:SetAlpha(0)
				_G[frame]:Hide()
				for _, f in pairs(module:LoadAdditional(db[kind].Additional)) do
					if LUI:CanAlterFrame(_G[f]) then
						_G[f]:SetAlpha(0)
						_G[f]:Hide()
					end
				end
			end

			self.timerout = 0
			self:Hide()
		end
	end)

	backgrounds[kind].AlphaIn = CreateFrame("Frame", nil, UIParent)
	backgrounds[kind].AlphaIn:Hide()
	backgrounds[kind].AlphaIn.timerin = 0
	backgrounds[kind].AlphaIn:SetScript("OnUpdate", function(self, elapsed)
		self.timerin = self.timerin + elapsed

		if self.timerin < .5 then
			local alpha = self.timerin / .5

			if _G[frame] and LUI:CanAlterFrame(_G[frame]) then
				_G[frame]:SetAlpha(alpha)
				for _, f in pairs(module:LoadAdditional(db[kind].Additional)) do
					if LUI:CanAlterFrame(_G[f]) then _G[f]:SetAlpha(alpha) end
				end
			end
		else
			if _G[frame] and LUI:CanAlterFrame(_G[frame]) then
				_G[frame]:SetAlpha(1)
				for _, f in pairs(module:LoadAdditional(db[kind].Additional)) do
					if LUI:CanAlterFrame(_G[f]) then _G[f]:SetAlpha(1) end
				end
			end

			self.timerin = 0
			self:Hide()
		end
	end)

	local f = CreateFrame("Frame", nil, UIParent)

	f:RegisterEvent("PLAYER_ENTERING_WORLD")
	f:SetScript("OnEvent", function(self)
		if frame then
			module:ApplyBackground(kind)
			f:UnregisterEvent("PLAYER_ENTERING_WORLD")
		end
	end)
end

function module:ApplyBackground(kind)
	local data = db[kind]
	local frame
	if kind == "Chat" then
		frame = ChatAlphaAnchor
		frame:Raise() -- Fix for Panel being above chat frame
	else
		frame = _G[db[kind].Anchor]
	end

	if not frame then
		
		backgrounds[kind]:Hide()
		return
	end

	local rc, gc, bc, ac = unpack(ThemesDB[strlower(kind)])
	local r, g, b, a = unpack(ThemesDB[strlower(kind.."border")])

	-- temporary for CENTER -> SOLID change
	if data.Direction == "CENTER" then data.Direction = "SOLID" end
	backgrounds[kind]:Set(data.Direction, frame, data.Width, data.Height, 1, r, g, b, a, rc, gc, bc, ac)
	backgrounds[kind]:ClearAllPoints()
	backgrounds[kind]:SetPoint("TOPLEFT", frame, "TOPLEFT", db[kind].OffsetX, db[kind].OffsetY)
	backgrounds[kind]:Show()
end

function module:SetPanels()
	ChatAlphaAnchor = CreateFrame("Frame", "ChatAlphaAnchor", UIParent)
	ChatAlphaAnchor:SetWidth(30)
	ChatAlphaAnchor:SetHeight(30)
	ChatAlphaAnchor:SetFrameStrata("BACKGROUND")
	ChatAlphaAnchor:SetFrameLevel(0)
	ChatAlphaAnchor:SetPoint("TOPLEFT", ChatFrame1, "TOPLEFT", -3, 8)
	ChatAlphaAnchor:SetAlpha(1)
	ChatAlphaAnchor:Show()

	self:CreateBackground("Chat")
	self:CreateBackground("Tps")
	self:CreateBackground("Dps")
	self:CreateBackground("Raid")
end

function module:SetOrbColors()
	local orb = ThemesDB.orb
	local r, g, b, a = unpack(orb)
	LUI.Orb.Fill:SetVertexColor(r, g, b, a)
	LUI.Orb.Galaxy1.t:SetVertexColor(r, g, b, a)
	LUI.Orb.Galaxy2.t:SetVertexColor(r, g, b, a)
	LUI.Orb.Galaxy3.t:SetVertexColor(r, g, b, a)
end

function module:SetOrbCycleColor()
	LUI.Orb.Cycle:SetBackdropColor(unpack(ThemesDB.orb_cycle))
end

function module:SetOrbHoverColor()
	LUI.Orb.Hover:SetBackdropColor(unpack(ThemesDB.orb_hover))
end

function module:SetBottomInfoColors()
	local r, g, b, a = unpack(ThemesDB.color_bottom)
	LUI.Info.Left.BG:SetBackdropColor(r, g, b, a)
	LUI.Info.Right.BG:SetBackdropColor(r, g, b, a)
end

function module:SetTopInfoColors()
	local r, g, b, a = unpack(ThemesDB.color_top)
	LUI.Info.Topleft.BG:SetBackdropColor(r, g, b, a)
	LUI.Info.Topright.BG:SetBackdropColor(r, g, b, a)
	LUI.Navi.CenterBackground:SetBackdropColor(r, g, b, a)
	LUI.Navi.CenterBackgroundAlternative:SetBackdropColor(r, g, b, a)
end

function module:SetNavigationColors()
	local r, g, b, a = unpack(ThemesDB.navi)
	LUI.Navi.Chat:SetBackdropColor(r, g, b, a)
	LUI.Navi.Tps:SetBackdropColor(r, g, b, a)
	LUI.Navi.Dps:SetBackdropColor(r, g, b, a)
	LUI.Navi.Raid:SetBackdropColor(r, g, b, a)
end

function module:SetNavigationHoverColors()
	local r, g, b, a = unpack(ThemesDB.navi_hover)
	LUI.Navi.Chat.Hover:SetBackdropColor(r, g, b, a)
	LUI.Navi.Tps.Hover:SetBackdropColor(r, g, b, a)
	LUI.Navi.Dps.Hover:SetBackdropColor(r, g, b, a)
	LUI.Navi.Raid.Hover:SetBackdropColor(r, g, b, a)
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

	self:Refresh()
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

	local navi = ThemesDB.navi
	local navi_hover = ThemesDB.navi_hover
	local orb_hover = ThemesDB.orb_hover
	local color_bottom = ThemesDB.color_bottom
	local color_top = ThemesDB.color_top
	local orb = ThemesDB.orb
	local orb_cycle = ThemesDB.orb_cycle

-- Orb and top panel.
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
			bgFile = directory..fileName,
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			edgeSize = 1,
			insets = {left = 0, right = 0, top = 0, bottom = 0}
		}
		frame:SetBackdrop(frame.Backdrop)
		frame:SetBackdropBorderColor(0,0,0,0)
	end

	LUI.Navi.TopButtonBackground = LUI:CreateMeAFrame("Frame", nil, UIParent, 1024, 1024, 1, "BACKGROUND", 1, "TOP", UIParent, "TOP", 17, -16, 1)
	SetFrameBackdrop(LUI.Navi.TopButtonBackground, "top")
	LUI.Navi.TopButtonBackground:Show()

	LUI.Navi.CenterBackground = LUI:CreateMeAFrame("Frame", nil, UIParent, 1035, 1024, 1, "BACKGROUND", 0, "TOP", UIParent, "TOP", 17, -17, 1)
	SetFrameBackdrop(LUI.Navi.CenterBackground, "top_back")
	LUI.Navi.CenterBackground:SetBackdropColor(unpack(color_top))
	LUI.Navi.CenterBackground:Show()

	LUI.Navi.CenterBackgroundAlternative = LUI:CreateMeAFrame("Frame", nil, UIParent, 1035, 1024, 1, "BACKGROUND", 0, "TOP", UIParent, "TOP", 17, -17, 1)
	SetFrameBackdrop(LUI.Navi.CenterBackgroundAlternative, "top_back_complete")
	LUI.Navi.CenterBackgroundAlternative:SetBackdropColor(unpack(color_top))
	LUI.Navi.CenterBackgroundAlternative:Hide()

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

	LUI.Orb.Ring4 = LUI:CreateMeAFrame("Frame", nil, LUI.Orb, 115, 115, 1, "LOW", 1, "CENTER", LUI.Orb, "CENTER", 0, -1, 1)
	SetFrameBackdrop(LUI.Orb.Ring4, "ring_inner2")
	LUI.Orb.Ring4:Show()

	LUI.Orb.Ring7 = LUI:CreateMeAFrame("Frame", nil, LUI.Orb, 77, 75, 1, "LOW", 3, "CENTER", LUI.Orb, "CENTER", 1, -1, 1)
	SetFrameBackdrop(LUI.Orb.Ring7, "ring")
	LUI.Orb.Ring7:Show()

	LUI.Orb.Cycle = LUI:CreateMeAFrame("Frame", nil, LUI.Orb, 115, 115, 1, "LOW", 0, "CENTER", LUI.Orb, "CENTER", 0, -1, 1)
	SetFrameBackdrop(LUI.Orb.Cycle, "ring_inner4")
	LUI.Orb.Cycle:SetBackdropColor(0.25, 0.25, 0.25, 0.7)
	LUI.Orb.Cycle:Show()

	LUI.Orb:RegisterForClicks("AnyUp")
	LUI.Orb:SetScript("OnClick", function(self)

		if not isAllShown then
			isAllShown = true

			LUI.Orb.Cycle:SetBackdropColor(unpack(orb_cycle))

			for _, k in pairs({"Chat", "Tps", "Dps", "Raid"}) do
				local v = LUI.Navi[k]
				if v:GetAlpha() == 0 then
					local a = k == "Chat" and "ChatAlphaAnchor" or db[k].Anchor

					if _G[a] then
						v.AlphaIn:Show()
						module:AlphaIn(k)
					end
				end
			end
		else
			isAllShown = false

			LUI.Orb.Cycle:SetBackdropColor(0.25, 0.25, 0.25, 0.7)

			for _, k in pairs({"Chat", "Tps", "Dps", "Raid"}) do
				local v = LUI.Navi[k]
				if v:GetAlpha() == 1 then
					local a = k == "Chat" and "ChatAlphaAnchor" or db[k].Anchor

					if _G[a] then
						v.AlphaOut:Show()
						module:AlphaOut(k)
					end
				end
			end
		end
	end)

-- Chat button.
	LUI.Navi.Chat = LUI:CreateMeAFrame("Frame", nil, LUI.Orb, 126, 120, 1, "LOW", 1, "LEFT", LUI.Orb, "LEFT", -176, 49, 0)
	LUI.Navi.Chat:SetBackdrop({
		bgFile = directory.."button_left2",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.Navi.Chat:SetBackdropColor(unpack(navi))
	LUI.Navi.Chat:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Navi.Chat:Show()

	LUI.Navi.Chat.Hover = LUI:CreateMeAFrame("Frame", nil, LUI.Orb, 124, 120, 1, "LOW", 1, "LEFT", LUI.Orb, "LEFT", -176, 49, 0)
	LUI.Navi.Chat.Hover:SetBackdrop({
		bgFile = directory.."button_left2_hover",
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
			module:AlphaIn("Chat")
			db.Chat.IsShown = true
			LUI:SetChatVisible(true)
		else
			LUI.Navi.Chat.AlphaOut:Show()
			module:AlphaOut("Chat")
			db.Chat.IsShown = false
			LUI:SetChatVisible(true)
		end
	end)

-- TPS button.
	LUI.Navi.Tps = LUI:CreateMeAFrame("Frame", nil, LUI.Orb, 63, 67, 1, "LOW", 1, "LEFT", LUI.Orb, "LEFT", -74, 18, 0)
	LUI.Navi.Tps:SetBackdrop({
		bgFile = directory.."button_left1",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.Navi.Tps:SetBackdropColor(unpack(navi))
	LUI.Navi.Tps:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Navi.Tps:Show()

	LUI.Navi.Tps.Hover = LUI:CreateMeAFrame("Frame", nil, LUI.Orb, 63, 60, 1, "LOW", 1, "LEFT", LUI.Orb, "LEFT", -74, 16, 0)
	LUI.Navi.Tps.Hover:SetBackdrop({
		bgFile = directory.."button_left1_hover",
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
		if _G[db.Tps.Anchor] and LUI:CanAlterFrame(_G[db.Tps.Anchor]) then
			if LUI.Navi.Tps:GetAlpha() == 0 then
				LUI.Navi.Tps.AlphaIn:Show()
				module:AlphaIn("Tps")
				db.Tps.IsShown = true
			else
				LUI.Navi.Tps.AlphaOut:Show()
				module:AlphaOut("Tps")
				db.Tps.IsShown = false
			end
		end
	end)

-- DPS button.
	LUI.Navi.Dps = LUI:CreateMeAFrame("Frame", nil, LUI.Orb, 63, 67, 1, "LOW", 1, "RIGHT", LUI.Orb, "RIGHT", 77, 21, 0)
	LUI.Navi.Dps:SetBackdrop({
		bgFile = directory.."button_right1",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.Navi.Dps:SetBackdropColor(unpack(navi))
	LUI.Navi.Dps:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Navi.Dps:Show()

	LUI.Navi.Dps.Hover = LUI:CreateMeAFrame("Frame", nil, LUI.Orb, 63, 60, 1, "LOW", 1, "RIGHT", LUI.Orb, "RIGHT", 77, 19, 0)
	LUI.Navi.Dps.Hover:SetBackdrop({
		bgFile = directory.."button_right1_hover",
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
		if _G[db.Dps.Anchor] and LUI:CanAlterFrame(_G[db.Dps.Anchor]) then
			if LUI.Navi.Dps:GetAlpha() == 0 then
				LUI.Navi.Dps.AlphaIn:Show()
				module:AlphaIn("Dps")
				db.Dps.IsShown = true
			else
				LUI.Navi.Dps.AlphaOut:Show()
				module:AlphaOut("Dps")
				db.Dps.IsShown = false
			end
		end
	end)


-- Raid button.
	LUI.Navi.Raid = LUI:CreateMeAFrame("Frame", nil, LUI.Orb, 126, 120, 1, "LOW", 1, "RIGHT", LUI.Orb, "RIGHT", 184, 47, 0)
	LUI.Navi.Raid:SetBackdrop({
		bgFile = directory.."button_right2",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.Navi.Raid:SetBackdropColor(unpack(navi))
	LUI.Navi.Raid:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Navi.Raid:Show()

	LUI.Navi.Raid.Hover = LUI:CreateMeAFrame("Frame", nil, LUI.Orb, 124, 120, 1, "LOW", 1, "RIGHT", LUI.Orb, "RIGHT", 182, 47, 0)
	LUI.Navi.Raid.Hover:SetBackdrop({
		bgFile = directory.."button_right2_hover",
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
		if _G[db.Raid.Anchor] and LUI:CanAlterFrame(_G[db.Raid.Anchor]) then
			if LUI.Navi.Raid:GetAlpha() == 0 then
				LUI.Navi.Raid.AlphaIn:Show()
				module:AlphaIn("Raid")
				db.Raid.IsShown = true
			else
				LUI.Navi.Raid.AlphaOut:Show()
				module:AlphaOut("Raid")
				db.Raid.IsShown = false
			end
		end
	end)

-- Info panel bottom left.
	LUI.Info.Left = LUI:CreateMeAFrame("Frame", nil, UIParent, 25, 25, 1, "BACKGROUND", 0, "BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0, 1)

	LUI.Info.Left.Panel = LUI:CreateMeAFrame("FRAME", nil, LUI.Info.Left, 1024, 1024, 1, "BACKGROUND", 1, "BOTTOMLEFT", LUI.Info.Left, "BOTTOMLEFT", -30, -31, 1)
	LUI.Info.Left.Panel:SetBackdrop({
		bgFile = directory.."info_left",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.Info.Left.Panel:SetBackdropColor(0, 0, 0, 0.9)
	LUI.Info.Left.Panel:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Info.Left.Panel:Show()

	LUI.Info.Left.BG = LUI:CreateMeAFrame("FRAME", nil, LUI.Info.Left, 1024, 1024, 1, "BACKGROUND", 0, "BOTTOMLEFT", LUI.Info.Left, "BOTTOMLEFT", -23, -23, 1)
	LUI.Info.Left.BG:SetBackdrop({
		bgFile = directory.."info_left_back",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.Info.Left.BG:SetBackdropColor(unpack(color_bottom))
	LUI.Info.Left.BG:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Info.Left.BG:Show()

-- Info panel bottom right.
	LUI.Info.Right = LUI:CreateMeAFrame("Frame", nil, UIParent, 25, 25, 1, "BACKGROUND", 0, "BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0, 1)

	LUI.Info.Right.Panel = LUI:CreateMeAFrame("FRAME", nil, LUI.Info.Right, 1024, 1024, 1, "BACKGROUND", 1, "BOTTOMRIGHT", LUI.Info.Right, "BOTTOMRIGHT", 36, -31, 1)
	LUI.Info.Right.Panel:SetBackdrop({
		bgFile = directory.."info_right",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.Info.Right.Panel:SetBackdropColor(0, 0, 0, 0.9)
	LUI.Info.Right.Panel:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Info.Right.Panel:Show()

	LUI.Info.Right.BG = LUI:CreateMeAFrame("FRAME", nil, LUI.Info.Right, 1024, 1024, 1, "BACKGROUND", 0, "BOTTOMRIGHT", LUI.Info.Right, "BOTTOMRIGHT", 29, -23, 1)
	LUI.Info.Right.BG:SetBackdrop({
		bgFile = directory.."info_right_back",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.Info.Right.BG:SetBackdropColor(unpack(color_bottom))
	LUI.Info.Right.BG:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Info.Right.BG:Show()

-- Info panel top left.
	LUI.Info.Topleft = LUI:CreateMeAFrame("Frame", nil, UIParent, 25, 25, 1, "BACKGROUND", 0, "CENTER", LUI.Orb, "CENTER", -212, 30, 1)

	LUI.Info.Topleft.BG = LUI:CreateMeAFrame("FRAME", nil, LUI.Info.Topleft, 1012, 1024, 1, "BACKGROUND", 0, "TOPRIGHT", LUI.Info.Topleft, "TOPRIGHT", 9, 11, 1)
	LUI.Info.Topleft.BG:SetBackdrop({
		bgFile = directory.."info_top_left2",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.Info.Topleft.BG:SetBackdropColor(unpack(color_top))
	LUI.Info.Topleft.BG:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Info.Topleft.BG:Show()


-- Info panel top right.
	LUI.Info.Topright = LUI:CreateMeAFrame("Frame", nil, UIParent, 25, 25, 1, "BACKGROUND", 0, "CENTER", LUI.Orb, "CENTER", 209, 30, 1)

	LUI.Info.Topright.BG = LUI:CreateMeAFrame("FRAME", nil, LUI.Info.Topright, 1015, 1024, 1, "BACKGROUND", 0, "TOPLEFT", LUI.Info.Topright, "TOPLEFT", -9, 11, 1)
	LUI.Info.Topright.BG:SetBackdrop({
		bgFile = directory.."info_top_right2",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.Info.Topright.BG:SetBackdropColor(unpack(color_top))
	LUI.Info.Topright.BG:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Info.Topright.BG:Show()

-- Info panel top left alternative.
	LUI.Info.TopleftAlternative = LUI:CreateMeAFrame("Frame", nil, UIParent, 25, 25, 1, "BACKGROUND", 0, "CENTER", LUI.Orb, "CENTER", -212, 30, 1)

	LUI.Info.TopleftAlternative.BG = LUI:CreateMeAFrame("FRAME", nil, LUI.Info.TopleftAlternative, 1012, 1024, 1, "BACKGROUND", 0, "TOPRIGHT", LUI.Info.TopleftAlternative, "TOPRIGHT", 9, 11, 1)
	LUI.Info.TopleftAlternative.BG:SetBackdrop({
		bgFile = directory.."info_top_complete",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.Info.TopleftAlternative.BG:SetBackdropColor(unpack(color_top))
	LUI.Info.TopleftAlternative.BG:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Info.TopleftAlternative.BG:Show()


-- Info panel top right alternative.
	LUI.Info.ToprightAlternative = LUI:CreateMeAFrame("Frame", nil, UIParent, 25, 25, 1, "BACKGROUND", 0, "CENTER", LUI.Orb, "CENTER", 209, 30, 1)

	LUI.Info.ToprightAlternative.BG = LUI:CreateMeAFrame("FRAME", nil, LUI.Info.ToprightAlternative, 1015, 1024, 1, "BACKGROUND", 0, "TOPLEFT", LUI.Info.ToprightAlternative, "TOPLEFT", -169, 11, 1)
	LUI.Info.ToprightAlternative.BG:SetBackdrop({
		bgFile = directory.."info_top_complete",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.Info.ToprightAlternative.BG:SetBackdropColor(unpack(color_top))
	LUI.Info.ToprightAlternative.BG:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Info.ToprightAlternative.BG:Show()

-- Scripts.
	local function alphain(self, elapsed)
		self.timer = self.timer + elapsed
		if self.timer < .4 then
			LUI.Navi[self.kind]:SetAlpha(self.timer / .4)
		else
			LUI.Navi[self.kind]:SetAlpha(1)
			self.timer = 0
			self:Hide()
		end
	end
	local function alphaout(self, elapsed)
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


module.defaults = {
	profile = {
		Enable = true,
		Minimap = {
			AlwaysShow = true,
			IsShown = false
		},
		MicroMenu = {
			AlwaysShow = true,
			IsShown = false
		},
		Chat = {
			OffsetX = 0,
			OffsetY = 0,
			AlwaysShow = false,
			IsShown = false,
			Direction = "TOPRIGHT",
			Animation = "AlphaSlide",
			Width = 429,
			Height = 181
		},
		Tps = {
			OffsetX = 0,
			OffsetY = 0,
			Anchor = "OmenAnchor",
			Additional = "",
			AlwaysShow = false,
			IsShown = false,
			Direction = "TOP",
			Animation = "AlphaSlide",
			Width = 193,
			Height = 181
		},
		Dps = {
			OffsetX = 0,
			OffsetY = -30,
			Anchor = "Recount_MainWindow",
			Additional = "",
			AlwaysShow = false,
			IsShown = false,
			Direction = "TOP",
			Animation = "AlphaSlide",
			Width = 193,
			Height = 181
		},
		Raid = {
			OffsetX = 0,
			OffsetY = 0,
			Anchor = "oUF_LUI_raid",
			Additional = "",
			AlwaysShow = false,
			IsShown = false,
			Direction = "TOPLEFT",
			Animation = "AlphaSlide",
			Width = 409,
			Height = 181
		}
	}
}

module.optionsName = "Frames"
module.getter = "generic"
module.setter = "Refresh"
module.order = 3

local otherFrames = {}
function module:RegisterFrame(newmodule)
	table.insert(otherFrames, newmodule)
end

function module:Refresh(...)
	local info, value = ...
	if type(info) == "table" then
		db[info[#info-1]][info[#info]] = value
	end

	self:ApplyBackground("Chat")
	self:ApplyBackground("Tps")
	self:ApplyBackground("Dps")
	self:ApplyBackground("Raid")
end

function module:LoadOptions()
	local function dryCall() self:Refresh() end
	local function UIRL() StaticPopup_Show("RELOAD_UI") end

	local function CreateOptionsPart(tag, order)
		local isNotChat = tag ~= "Chat" --not string.find(tag, "Chat")

		local options = self:NewGroup(tag, order, {
			header = self:NewHeader(tag.." Panel", 1),
			addon = isNotChat and self:NewDesc("Which "..tag.." Addon do you prefer?\nChoose one or type in the Anchor manually.\n", 2) or nil,
			AnchorDropdown = isNotChat and { -- old way, needs rework?
				name = "Addon",
				desc = "Choose your "..tag.." Addon.\n\nDefault: "..module.defaults.profile[tag].Anchor,
				type = "select",
				values = function()
					local t = tag == "Raid" and addonAnchors.raid or addonAnchors.meter
					local list = {}

					for k, v in pairs(t) do
						tinsert(list, k)
					end

					return list
				end,
				get = function()
					local addon
					local t = tag == "Raid" and addonAnchors.raid or addonAnchors.meter
					local list = {}

					for k, v in pairs(t) do
						if db[tag].Anchor == v then
							addon = k
						end
						tinsert(list, k)
					end

					for k, v in pairs(list) do
						if addon == v then return k end
					end
				end,
				set = function(_, choose)
					local i = 1
					local t = tag == "Raid" and addonAnchors.raid or addonAnchors.meter

					for k, v in pairs(t) do
						if i == choose then
							db[tag].Anchor = v
							if v == "DetailsBaseFrame1" then
								db[tag].Additional = "DetailsRowFrame1"
							elseif v == "DetailsBaseFrame2" then
								db[tag].Additional = "DetailsRowFrame2"
							else
								db[tag].Additional = ""
							end
						end
						i = i + 1
					end

					UIRL()
				end,
				order = 3,
			} or nil,
			Anchor = isNotChat and self:NewInput("Anchor", "Type in your "..tag.." Anchor manually.", 4, UIRL) or nil,
			FrameIdentifierDesc = isNotChat and self:NewDesc("Use the LUI Frame Identifier to search for the Parent Frame of your "..tag.." Addon.\nYou can also use the Blizzard Debug Tool: Type /framestack", 5) or nil,
			FrameIdentifier = isNotChat and self:NewExecute("LUI Frame Identifier", "Click to show the LUI Frame Identifier", 6, function() _G.LUI_Frame_Identifier:Show() end) or nil,
			Additional = isNotChat and self:NewInput("Additional Frames", "Type in any additional Frames (seperated by commas), that you would like to show/hide.", 7, function() module:LoadAdditional(db[tag].Additional, true) end) or nil,
			empty1 = isNotChat and self:NewDesc(" ", 8) or nil,
			OffsetX = self:NewInputNumber("Offset X", "Choose the X Offset for your "..tag.." Frame to it's Anchor.", 9, dryCall),
			OffsetY = self:NewInputNumber("Offset Y", "Choose the Y Offset for your "..tag.." Frame to it's Anchor.", 10, dryCall),
			empty2 = self:NewDesc(" ", 11),
			Direction = self:NewSelect("Direction", "Choose the Direction for your "..tag.." Panel.", 12, directions, nil, dryCall),
			Animation = --[[isPrimary and]] self:NewSelect("Animation", "Choose the Animation for your "..tag.." Panel.", 13, animations, nil, dryCall) --[[or nil]],
			Width = self:NewInputNumber("Width", "Choose the Width for your "..tag.." Panel.", 14, dryCall),
			Height = self:NewInputNumber("Height", "Choose the Height for your "..tag.." Panel.", 15, dryCall),
			empty3 = self:NewDesc(" ", 16),
			BGColor = {
				name = "BG Color",
				desc = "Choose the Color for your "..tag.." Panel Background.",
				type = "color",
				hasAlpha = true,
				get = function() return unpack(ThemesDB[strlower(tag)]) end,
				set = function(_, r, g, b, a)
					ThemesDB[strlower(tag)] = {r, g, b, a}
					module:Refresh()
				end,
				order = 17,
			},
			BorderColor = {
				name = "Border Color",
				desc = "Choose the Color for your "..tag.." Panel Border.",
				type = "color",
				hasAlpha = true,
				get = function() return unpack(ThemesDB[strlower(tag).."border"]) end,
				set = function(_, r, g, b, a)
					ThemesDB[strlower(tag).."border"] = {r, g, b, a}
					module:Refresh()
				end,
				order = 18,
			},
		})

		if tag == "Chat2" then options.disabled = function() return not LUI.db.profile.Chat.SecondChatFrame end end

		return options
	end

	local options = {
		Chat = CreateOptionsPart("Chat", 1),
		--Chat2 = CreateOptionsPart("Chat2", 2),
		Tps = CreateOptionsPart("Tps", 3),
		Dps = CreateOptionsPart("Dps", 4),
		Raid = CreateOptionsPart("Raid", 5),
	}

	for _, newmodule in pairs(otherFrames) do
		options[newmodule:GetName()] = type(newmodule.LoadFrameOptions) == "function" and newmodule:LoadFrameOptions() or newmodule.LoadFrameOptions
	end

	return options
end

function module:AdjustTopPanel()
	local Infotext = LUI:GetModule("Infotext", true)
	if Infotext and Infotext:IsEnabled() then
		LUI.Navi.TopButtonBackground:SetPoint("TOP", UIParent, "TOP", 17, -16)
		LUI.Navi.CenterBackground:SetPoint("TOP", UIParent, "TOP", 17, -17)
		LUI.Navi.CenterBackgroundAlternative:SetPoint("TOP", UIParent, "TOP", 17, -17)
		LUI.Navi.Chat:SetPoint("LEFT", LUI.Orb, "LEFT", -176, 49)
		LUI.Navi.Tps:SetPoint("LEFT", LUI.Orb, "LEFT", -74,  18)
		LUI.Navi.Dps:SetPoint("RIGHT", LUI.Orb, "RIGHT", 77,  21)
		LUI.Navi.Raid:SetPoint("RIGHT", LUI.Orb, "RIGHT", 184, 47)
		LUI.Navi.Chat.Hover:SetPoint("LEFT", LUI.Orb, "LEFT", -176, 49)
		LUI.Navi.Tps.Hover:SetPoint("LEFT", LUI.Orb, "LEFT", -74,  16)
		LUI.Navi.Dps.Hover:SetPoint("RIGHT", LUI.Orb, "RIGHT", 77,  19)
		LUI.Navi.Raid.Hover:SetPoint("RIGHT", LUI.Orb, "RIGHT", 184, 47)
	else
		LUI.Navi.TopButtonBackground:SetPoint("TOP", UIParent, "TOP", 17, 8)
		LUI.Navi.CenterBackground:SetPoint("TOP", UIParent, "TOP", 17, 5)
		LUI.Navi.CenterBackgroundAlternative:SetPoint("TOP", UIParent, "TOP", 17, 5)
		LUI.Navi.Chat:SetPoint("LEFT", LUI.Orb, "LEFT", -176, 73)
		LUI.Navi.Tps:SetPoint("LEFT", LUI.Orb, "LEFT", -74,  42)
		LUI.Navi.Dps:SetPoint("RIGHT", LUI.Orb, "RIGHT", 77,  45)
		LUI.Navi.Raid:SetPoint("RIGHT", LUI.Orb, "RIGHT", 184, 71)
		LUI.Navi.Chat.Hover:SetPoint("LEFT", LUI.Orb, "LEFT", -176, 73)
		LUI.Navi.Tps.Hover:SetPoint("LEFT", LUI.Orb, "LEFT", -74,  40)
		LUI.Navi.Dps.Hover:SetPoint("RIGHT", LUI.Orb, "RIGHT", 77,  43)
		LUI.Navi.Raid.Hover:SetPoint("RIGHT", LUI.Orb, "RIGHT", 184, 71)
	end
end

function module:OnInitialize()
	db, dbd = LUI:NewNamespace(self)

	if LUI.db.profile.Frames then
		LUI.db.profile.Frames = nil
	end
end

function module:OnEnable()
	LUI.Profiler.TraceScope(module, "Panels", "LUI", 2)
	ThemesDB = LUI:GetModule("Themes").db.profile

	if db.MicroMenu.AlwaysShow then db.MicroMenu.IsShown = true end

	self:SetPanels()

	self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
		self:CheckPanels()
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	end)

	-- Update Details users that dont have the AdditionalFrame yet
	if db.Dps.Anchor == "DetailsBaseFrame1" and db.Dps.Additional == "" then
		db.Dps.Additional = "DetailsRowFrame1"
	end

	self:SetFrames()
	module:AdjustTopPanel()
end
