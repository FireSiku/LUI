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
local module = LUI:Module("Panels", "AceHook-3.0", "AceEvent-3.0")
local Frames = LUI:Module("Frames")
local Themes = LUI:Module("Themes")
local Media_ = LibStub("LibSharedMedia-3.0")

local db, dbd_
local frameBackgrounds_ = {"LEFT", "RIGHT", "NONE"}
local frameBackgrounds2_ = {"LUI v3", "NONE"}
local animations = {"AlphaSlide", "None"}
local directions = {"SOLID", "TOPLEFT", "TOP", "TOPRIGHT", "RIGHT", "BOTTOMRIGHT", "BOTTOM", "BOTTOMLEFT", "LEFT"}

local fdir = "Interface\\AddOns\\LUI\\media\\templates\\v3\\"

LUI.Versions.panels = 1.2

local backgrounds = {}

local addonAnchors = {
	raid = {
		Grid = "GridLayoutFrame",
		Grid2 = "Grid2LayoutFrame",
		Healbot = "HealBot_Action",
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

function module:CheckPanels()
	if db.Chat.AlwaysShow and db.Tps.AlwaysShow and db.Dps.AlwaysShow and db.Raid.AlwaysShow then
		Frames:IsAllShown(true)
		Frames:SetOrbCycleColor()
	elseif db.Chat.IsShown and db.Tps.IsShown and db.Dps.IsShown and db.Raid.IsShown then
		Frames:IsAllShown(true)
		Frames:SetOrbCycleColor()
	else
		Frames:IsAllShown(false)
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
		Frames:SetNaviAlpha("Chat", 1)

		ChatAlphaAnchor:SetAlpha(1)
		--if LUI.db.profile.Chat.SecondChatFrame then ChatAlphaAnchor2:SetAlpha(1) end

		db.Chat.IsShown = true
		LUI:SetChatVisible(true)
	else
		Frames:SetNaviAlpha("Chat", 0)

		ChatAlphaAnchor:SetAlpha(0)
		--if LUI.db.profile.Chat.SecondChatFrame then ChatAlphaAnchor2:SetAlpha(0) end

		db.Chat.IsShown = false
		--LUI:SetChatVisible(false)
		LUI:SetChatVisible(true)
	end


	if (db.Tps.AlwaysShow or db.Tps.IsShown) and _G[db.Tps.Anchor] then
		Frames:SetNaviAlpha("Tps", 1)

		_G[db.Tps.Anchor]:SetAlpha(1)
		_G[db.Tps.Anchor]:Show()
		for _, f in pairs(self:LoadAdditional(db.Tps.Additional)) do
			_G[f]:SetAlpha(1)
			_G[f]:Show()
		end

		db.Tps.IsShown = true
	else
		Frames:SetNaviAlpha("Tps", 0)

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
		Frames:SetNaviAlpha("Dps", 1)

		_G[db.Dps.Anchor]:SetAlpha(1)
		_G[db.Dps.Anchor]:Show()
		for _, f in pairs(self:LoadAdditional(db.Dps.Additional)) do
			_G[f]:SetAlpha(1)
			_G[f]:Show()
		end

		db.Dps.IsShown = true
	else
		Frames:SetNaviAlpha("Dps", 0)

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
		Frames:SetNaviAlpha("Raid", 1)

		_G[db.Raid.Anchor]:SetAlpha(1)
		_G[db.Raid.Anchor]:Show()
		for _, f in pairs(self:LoadAdditional(db.Raid.Additional)) do
			_G[f]:SetAlpha(1)
			_G[f]:Show()
		end

		db.Raid.IsShown = true
	else
		Frames:SetNaviAlpha("Raid", 0)

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

	if LUI:Module("Micromenu", true) then
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
	if str == nil or str == "" then return {} end

	local frames = {}

	if strfind(str, "%s") then
		local part1, part2
		while true do
			if strfind(str, "%s") == nil then break end
			part1, part2 = strsplit(" ", str, 2)
			str = part1..part2
		end
	end

	if strfind(str, ",") then
		local part1, part2
		while true do
			if strfind(str, ",") == nil then break end
			part1, part2 = strsplit(",", str, 2)
			if _G[part1] then
				table.insert(frames, part1)
			elseif debug then
		
			end
			str = part2
		end
	end
	if str ~= nil and str ~= "" then
		if _G[str] then
			table.insert(frames, str)
		elseif debug then
	
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


function RotateTexture(self, degrees)
	local r = rotationCoords[degrees]
	self:SetTexCoord(r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8])
end

local Set = function(f, d, p, w, h, s, r, g, b, a, rc, gc, bc, ac)
	f:SetParent(p)
	f:SetWidth(w)
	f:SetHeight(h)
	f:SetScale(s)

	if d == "SOLID" then
		f.c:SetTexture(fdir.."panelbg1.tga")
		f.c:SetVertexColor(rc, gc, bc, ac)
		RotateTexture(f.c, 0)

		f.tl:SetVertexColor(r, g, b, a)
		f.tr:SetVertexColor(r, g, b, a)
		f.bl:SetVertexColor(r, g, b, a)
		f.br:SetVertexColor(r, g, b, a)

		f.t:SetGradientAlpha("HORIZONTAL", r, g, b, a, r, g, b, a)
		f.b:SetGradientAlpha("HORIZONTAL", r, g, b, a, r, g, b, a)
		f.l:SetGradientAlpha("VERTICAL", r, g, b, a, r, g, b, a)
		f.r:SetGradientAlpha("VERTICAL", r, g, b, a, r, g, b, a)
	elseif d == "LEFT" then
		f.c:SetTexture(fdir.."panelbg2.tga")
		f.c:SetVertexColor(rc, gc, bc, ac)
		RotateTexture(f.c, 90)

		f.tl:SetVertexColor(r, g, b, a)
		f.tr:SetVertexColor(r, g, b, 0)
		f.bl:SetVertexColor(r, g, b, a)
		f.br:SetVertexColor(r, g, b, 0)

		f.t:SetGradientAlpha("HORIZONTAL", r, g, b, a, r, g, b, 0)
		f.b:SetGradientAlpha("HORIZONTAL", r, g, b, a, r, g, b, 0)
		f.l:SetGradientAlpha("VERTICAL", r, g, b, a, r, g, b, a)
		f.r:SetGradientAlpha("VERTICAL", r, g, b, 0, r, g, b, 0)
	elseif d == "TOP" then
		f.c:SetTexture(fdir.."panelbg2.tga")
		f.c:SetVertexColor(rc, gc, bc, ac)
		RotateTexture(f.c, 0)

		f.tl:SetVertexColor(r, g, b, a)
		f.tr:SetVertexColor(r, g, b, a)
		f.bl:SetVertexColor(r, g, b, 0)
		f.br:SetVertexColor(r, g, b, 0)

		f.t:SetGradientAlpha("HORIZONTAL", r, g, b, a, r, g, b, a)
		f.b:SetGradientAlpha("HORIZONTAL", r, g, b, 0, r, g, b, 0)
		f.l:SetGradientAlpha("VERTICAL", r, g, b, 0, r, g, b, a)
		f.r:SetGradientAlpha("VERTICAL", r, g, b, 0, r, g, b, a)
	elseif d == "RIGHT" then
		f.c:SetTexture(fdir.."panelbg2.tga")
		f.c:SetVertexColor(rc, gc, bc, ac)
		RotateTexture(f.c, 270)

		f.tl:SetVertexColor(r, g, b, 0)
		f.tr:SetVertexColor(r, g, b, a)
		f.bl:SetVertexColor(r, g, b, 0)
		f.br:SetVertexColor(r, g, b, a)

		f.t:SetGradientAlpha("HORIZONTAL", r, g, b, 0, r, g, b, a)
		f.b:SetGradientAlpha("HORIZONTAL", r, g, b, 0, r, g, b, a)
		f.l:SetGradientAlpha("VERTICAL", r, g, b, 0, r, g, b, 0)
		f.r:SetGradientAlpha("VERTICAL", r, g, b, a, r, g, b, a)
	elseif d == "BOTTOM" then
		f.c:SetTexture(fdir.."panelbg2.tga")
		f.c:SetVertexColor(rc, gc, bc, ac)
		RotateTexture(f.c, 180)

		f.tl:SetVertexColor(r, g, b, 0)
		f.tr:SetVertexColor(r, g, b, 0)
		f.bl:SetVertexColor(r, g, b, a)
		f.br:SetVertexColor(r, g, b, a)

		f.t:SetGradientAlpha("HORIZONTAL", r, g, b, 0, r, g, b, 0)
		f.b:SetGradientAlpha("HORIZONTAL", r, g, b, a, r, g, b, a)
		f.l:SetGradientAlpha("VERTICAL", r, g, b, a, r, g, b, 0)
		f.r:SetGradientAlpha("VERTICAL", r, g, b, a, r, g, b, 0)
	elseif d == "TOPLEFT" then
		f.c:SetTexture(fdir.."panelbg3.tga")
		f.c:SetVertexColor(rc, gc, bc, ac)
		RotateTexture(f.c, 0)

		f.tl:SetVertexColor(r, g, b, a)
		f.tr:SetVertexColor(r, g, b, 0)
		f.bl:SetVertexColor(r, g, b, 0)
		f.br:SetVertexColor(r, g, b, 0)

		f.t:SetGradientAlpha("HORIZONTAL", r, g, b, a, r, g, b, 0)
		f.b:SetGradientAlpha("HORIZONTAL", r, g, b, 0, r, g, b, 0)
		f.l:SetGradientAlpha("VERTICAL", r, g, b, 0, r, g, b, a)
		f.r:SetGradientAlpha("VERTICAL", r, g, b, 0, r, g, b, 0)
	elseif d == "TOPRIGHT" then
		f.c:SetTexture(fdir.."panelbg3.tga")
		f.c:SetVertexColor(rc, gc, bc, ac)
		RotateTexture(f.c, 270)

		f.tl:SetVertexColor(r, g, b, 0)
		f.tr:SetVertexColor(r, g, b, a)
		f.bl:SetVertexColor(r, g, b, 0)
		f.br:SetVertexColor(r, g, b, 0)

		f.t:SetGradientAlpha("HORIZONTAL", r, g, b, 0, r, g, b, a)
		f.b:SetGradientAlpha("HORIZONTAL", r, g, b, 0, r, g, b, 0)
		f.l:SetGradientAlpha("VERTICAL", r, g, b, 0, r, g, b, 0)
		f.r:SetGradientAlpha("VERTICAL", r, g, b, 0, r, g, b, a)
	elseif d == "BOTTOMRIGHT" then
		f.c:SetTexture(fdir.."panelbg3.tga")
		f.c:SetVertexColor(rc, gc, bc, ac)
		RotateTexture(f.c, 180)

		f.tl:SetVertexColor(r, g, b, 0)
		f.tr:SetVertexColor(r, g, b, 0)
		f.bl:SetVertexColor(r, g, b, 0)
		f.br:SetVertexColor(r, g, b, a)

		f.t:SetGradientAlpha("HORIZONTAL", r, g, b, 0, r, g, b, 0)
		f.b:SetGradientAlpha("HORIZONTAL", r, g, b, 0, r, g, b, a)
		f.l:SetGradientAlpha("VERTICAL", r, g, b, 0, r, g, b, 0)
		f.r:SetGradientAlpha("VERTICAL", r, g, b, a, r, g, b, 0)
	elseif d == "BOTTOMLEFT" then
		f.c:SetTexture(fdir.."panelbg3.tga")
		f.c:SetVertexColor(rc, gc, bc, ac)
		RotateTexture(f.c, 90)

		f.tl:SetVertexColor(r, g, b, 0)
		f.tr:SetVertexColor(r, g, b, 0)
		f.bl:SetVertexColor(r, g, b, a)
		f.br:SetVertexColor(r, g, b, 0)

		f.t:SetGradientAlpha("HORIZONTAL", r, g, b, 0, r, g, b, 0)
		f.b:SetGradientAlpha("HORIZONTAL", r, g, b, a, r, g, b, 0)
		f.l:SetGradientAlpha("VERTICAL", r, g, b, a, r, g, b, 0)
		f.r:SetGradientAlpha("VERTICAL", r, g, b, 0, r, g, b, 0)
	end

end

local bordersize = 9
local padding = 0
local CreateBackground = function(kind)
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

	_G[backgrounds[kind].frame]:Show()
	--if kind == "Chat" and LUI.db.profile.Chat.SecondChatFrame then ChatAlphaAnchor2:Show() end
	for _, f in pairs(self:LoadAdditional(db[kind].Additional)) do _G[f]:Show() end

	if db[kind].Animation == "AlphaSlide" then
		backgrounds[kind].AlphaIn:Show()

		--[[if kind == "Chat" and LUI.db.profile.Chat.SecondChatFrame then
			backgrounds.Chat2.AlphaIn:Show()
		end]]
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

	else
		_G[backgrounds[kind].frame]:SetAlpha(0)
		_G[backgrounds[kind].frame]:Hide()

		for _, f in pairs(Panels:LoadAdditional(db[kind].Additional)) do
			_G[f]:SetAlpha(0)
			_G[f]:Hide()
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

			if _G[frame] then
				_G[frame]:SetAlpha(alpha)
				for _, f in pairs(module:LoadAdditional(db[kind].Additional)) do
					_G[f]:SetAlpha(alpha)
				end
			end
		else
			if _G[frame] then
				_G[frame]:SetAlpha(0)
				_G[frame]:Hide()
				for _, f in pairs(module:LoadAdditional(db[kind].Additional)) do
					_G[f]:SetAlpha(0)
					_G[f]:Hide()
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

			if _G[frame] then
				_G[frame]:SetAlpha(alpha)
				for _, f in pairs(module:LoadAdditional(db[kind].Additional)) do
					_G[f]:SetAlpha(alpha)
				end
			end
		else
			if _G[frame] then
				_G[frame]:SetAlpha(1)
				for _, f in pairs(module:LoadAdditional(db[kind].Additional)) do
					_G[f]:SetAlpha(1)
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

	local rc, gc, bc, ac = unpack(Themes.db.profile[strlower(kind)])
	local r, g, b, a = unpack(Themes.db.profile[strlower(kind.."border")])

	-- temporary for CENTER -> SOLID change
	if data.Direction == "CENTER" then data.Direction = "SOLID" end
	backgrounds[kind]:Set(data.Direction, frame, data.Width, data.Height, 1, r, g, b, a, rc, gc, bc, ac)
	backgrounds[kind]:ClearAllPoints()
	backgrounds[kind]:SetPoint("TOPLEFT", frame, "TOPLEFT", db[kind].OffsetX, db[kind].OffsetY)
	backgrounds[kind]:Show()
end

function module:SetPanels()
	local ChatAlphaAnchor = CreateFrame("Frame", "ChatAlphaAnchor", UIParent)
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
module.SetColors = function() module:Refresh() end

function module:LoadOptions()
	local dryCall = function() self:Refresh() end
	local UIRL = function() StaticPopup_Show("RELOAD_UI") end

	local CreateOptionsPart = function(tag, order)
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
			FrameIdentifier = isNotChat and self:NewExecute("LUI Frame Identifier", "Click to show the LUI Frame Identifier", 6, function() LUI_Frame_Identifier:Show() end) or nil,
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
				get = function() return unpack(Themes.db.profile[strlower(tag)]) end,
				set = function(_, r, g, b, a)
					Themes.db.profile[strlower(tag)] = {r, g, b, a}
					module:Refresh()
				end,
				order = 17,
			},
			BorderColor = {
				name = "Border Color",
				desc = "Choose the Color for your "..tag.." Panel Border.",
				type = "color",
				hasAlpha = true,
				get = function() return unpack(Themes.db.profile[strlower(tag).."border"]) end,
				set = function(_, r, g, b, a)
					Themes.db.profile[strlower(tag).."border"] = {r, g, b, a}
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

function module:OnInitialize()
	db, dbd = LUI:NewNamespace(self)

	if LUI.db.profile.Frames then
		LUI.db.profile.Frames = nil
	end
end

function module:OnEnable()
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
end
