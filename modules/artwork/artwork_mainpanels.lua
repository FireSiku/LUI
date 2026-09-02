-- Chat, threat, damage and raid panels controlled by the navigation bar.

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Artwork : LUIModule
local module = LUI:GetModule("Artwork")

local OLD_DIR = [[Interface\AddOns\LUI\media\templates\v3\]]

-- constants
local INFOPANEL_TEXTURE = "Interface\\AddOns\\LUI\\media\\textures\\infopanel"

local db

---@type table<string, Frame>
local _mainPanels = {}

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

-- Texture coordinates matching the four supported panel directions.
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

local function RotateTexture(self, degrees)
	local r = rotationCoords[degrees]
	self:SetTexCoord(r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8])
end

function module:SetChatVisible(setVisible)
	for _, chatFrameName in ipairs(_G.CHAT_FRAMES) do
		for _, suffix in ipairs{"", "Tab"} do
			local f = _G[chatFrameName..suffix]
			if f then
				if setVisible then
					if f.LUIArtworkChatHidden then
						f.LUIArtworkChatHidden = nil
						if f.LUIArtworkWasShown then f:Show() end
						f.LUIArtworkWasShown = nil
					end
				elseif not f.LUIArtworkChatHidden then
					f.LUIArtworkWasShown = f:IsShown()
					f.LUIArtworkChatHidden = true
					f:Hide()
				end
			end
		end
	end
end

function module:LoadAdditional(str)
	if not str or str:trim() == "" then return {} end

	local frames = {}

	-- Strip whitespace.
	str = str:gsub("%s+", "")

	if strfind(str, ",") then
		local list = {strsplit(",", str)}
		for _, name in ipairs(list) do
			if _G[name] then table.insert(frames, name) end
		end
	else
		if _G[str] then table.insert(frames, str) end
	end

	return frames
end

function module:CanAlterFrame(frame)
	if not frame then return false end
	if frame.IsForbidden and frame:IsForbidden() then return false end
	if not (frame:IsProtected() and _G.InCombatLockdown()) then
		return true
	end
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
		f.c:SetTexture(OLD_DIR.."panelbg1.tga")
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
		f.c:SetTexture(OLD_DIR.."panelbg2.tga")
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
		f.c:SetTexture(OLD_DIR.."panelbg2.tga")
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
		f.c:SetTexture(OLD_DIR.."panelbg2.tga")
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
		f.c:SetTexture(OLD_DIR.."panelbg2.tga")
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
		f.c:SetTexture(OLD_DIR.."panelbg3.tga")
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
		f.c:SetTexture(OLD_DIR.."panelbg3.tga")
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
		f.c:SetTexture(OLD_DIR.."panelbg3.tga")
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
		f.c:SetTexture(OLD_DIR.."panelbg3.tga")
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
	local f = CreateFrame("Frame", "LUIArtwork_MainPanel"..kind, UIParent)

	f.c = f:CreateTexture(nil, "BACKGROUND")
	f.c:SetPoint("TOPLEFT", f, "TOPLEFT")
	f.c:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT")

	f.tl = f:CreateTexture(nil, "BACKGROUND")
	f.tl:SetWidth(bordersize)
	f.tl:SetHeight(bordersize)
	f.tl:SetPoint("BOTTOMRIGHT", f, "TOPLEFT", -padding, padding)
	f.tl:SetTexture(OLD_DIR.."panelcorner.tga")
	RotateTexture(f.tl, 0)

	f.tr = f:CreateTexture(nil, "BACKGROUND")
	f.tr:SetWidth(bordersize)
	f.tr:SetHeight(bordersize)
	f.tr:SetPoint("BOTTOMLEFT", f, "TOPRIGHT", padding, padding)
	f.tr:SetTexture(OLD_DIR.."panelcorner.tga")
	RotateTexture(f.tr, 270)

	f.bl = f:CreateTexture(nil, "BACKGROUND")
	f.bl:SetWidth(bordersize)
	f.bl:SetHeight(bordersize)
	f.bl:SetPoint("TOPRIGHT", f, "BOTTOMLEFT", -padding, -padding)
	f.bl:SetTexture(OLD_DIR.."panelcorner.tga")
	RotateTexture(f.bl, 90)

	f.br = f:CreateTexture(nil, "BACKGROUND")
	f.br:SetWidth(bordersize)
	f.br:SetHeight(bordersize)
	f.br:SetPoint("TOPLEFT", f, "BOTTOMRIGHT", padding, -padding)
	f.br:SetTexture(OLD_DIR.."panelcorner.tga")
	RotateTexture(f.br, 180)

	f.l = f:CreateTexture(nil, "BACKGROUND")
	f.l:SetWidth(bordersize)
	f.l:SetPoint("TOPRIGHT", f, "TOPLEFT", -padding, padding)
	f.l:SetPoint("BOTTOMRIGHT", f, "BOTTOMLEFT", padding, -padding)
	f.l:SetTexture(OLD_DIR.."panelborder.tga")
	RotateTexture(f.l, 90)

	f.r = f:CreateTexture(nil, "BACKGROUND")
	f.r:SetWidth(bordersize)
	f.r:SetPoint("TOPLEFT", f, "TOPRIGHT", padding, padding)
	f.r:SetPoint("BOTTOMLEFT", f, "BOTTOMRIGHT", padding, -padding)
	f.r:SetTexture(OLD_DIR.."panelborder.tga")
	RotateTexture(f.r, 270)

	f.t = f:CreateTexture(nil, "BACKGROUND")
	f.t:SetHeight(bordersize)
	f.t:SetPoint("BOTTOMLEFT", f, "TOPLEFT", -padding, padding)
	f.t:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", padding, padding)
	f.t:SetTexture(OLD_DIR.."panelborder.tga")
	RotateTexture(f.t, 0)

	f.b = f:CreateTexture(nil, "BACKGROUND")
	f.b:SetHeight(bordersize)
	f.b:SetPoint("TOPLEFT", f, "BOTTOMLEFT", -padding, -padding)
	f.b:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", padding, -padding)
	f.b:SetTexture(OLD_DIR.."panelborder.tga")
	RotateTexture(f.b, 180)

	f.Set = Set

	return f
end

function module:AlphaIn(kind, button)
	if not _mainPanels[kind] then return end
	db[kind].IsShown = true
	local frame = _G[_mainPanels[kind].frame]

	if module:CanAlterFrame(frame) then
		frame:Show()

		for _, f in pairs(module:LoadAdditional(db[kind].Additional)) do
			if module:CanAlterFrame(_G[f]) then _G[f]:Show() end
		end
		
		if db[kind].Animation then
			_mainPanels[kind].AlphaIn:Show()
		else
			frame:SetAlpha(1)
			for _, f in pairs(module:LoadAdditional(db[kind].Additional)) do
				if module:CanAlterFrame(_G[f]) then _G[f]:SetAlpha(1) end
			end
		end
	end
end

function module:AlphaOut(kind, button)
	if not _mainPanels[kind] then return end
	db[kind].IsShown = false
	local frame = _G[_mainPanels[kind].frame]

	if module:CanAlterFrame(frame) then
		if db[kind].Animation then
			_mainPanels[kind].AlphaOut:Show()

		else
			_G[_mainPanels[kind].frame]:SetAlpha(0)
			_G[_mainPanels[kind].frame]:Hide()

			for _, f in pairs(module:LoadAdditional(db[kind].Additional)) do
				if module:CanAlterFrame(_G[f]) then
					_G[f]:SetAlpha(0)
					_G[f]:Hide()
				end
			end
		end
	end
end

function module:CreateBackground(kind)
	if _mainPanels[kind] then return end

	local frame
	if kind == "Chat" then
		db[kind].Anchor = "ChatAlphaAnchor"
	end
	frame = db[kind].Anchor

	_mainPanels[kind] = CreateBackground(kind)

	_mainPanels[kind].timerout = 0
	_mainPanels[kind].timerin = 0
	_mainPanels[kind].alphatimer = .5

	_mainPanels[kind].frame = frame

	_mainPanels[kind].AlphaOut = CreateFrame("Frame", nil, UIParent)
	_mainPanels[kind].AlphaOut:Hide()
	_mainPanels[kind].AlphaOut.timerout = 0
	_mainPanels[kind].AlphaOut:SetScript("OnUpdate", function(self, elapsed)
		self.timerout = self.timerout + elapsed
		local target = _G[_mainPanels[kind].frame]

		if self.timerout < .5 then
			local alpha = 1 - self.timerout / .5

			if module:CanAlterFrame(target) then
				target:SetAlpha(alpha)
				for _, f in pairs(module:LoadAdditional(db[kind].Additional)) do
					if module:CanAlterFrame(_G[f]) then _G[f]:SetAlpha(alpha) end
				end
			end
		else
			if module:CanAlterFrame(target) then
				target:SetAlpha(0)
				target:Hide()
				for _, f in pairs(module:LoadAdditional(db[kind].Additional)) do
					if module:CanAlterFrame(_G[f]) then
						_G[f]:SetAlpha(0)
						_G[f]:Hide()
					end
				end
			end

			self.timerout = 0
			self:Hide()
		end
	end)

	_mainPanels[kind].AlphaIn = CreateFrame("Frame", nil, UIParent)
	_mainPanels[kind].AlphaIn:Hide()
	_mainPanels[kind].AlphaIn.timerin = 0
	_mainPanels[kind].AlphaIn:SetScript("OnUpdate", function(self, elapsed)
		self.timerin = self.timerin + elapsed
		local target = _G[_mainPanels[kind].frame]

		if self.timerin < .5 then
			local alpha = self.timerin / .5

			if module:CanAlterFrame(target) then
				target:SetAlpha(alpha)
				for _, f in pairs(module:LoadAdditional(db[kind].Additional)) do
					if module:CanAlterFrame(_G[f]) then _G[f]:SetAlpha(alpha) end
				end
			end
		else
			if module:CanAlterFrame(target) then
				target:SetAlpha(1)
				for _, f in pairs(module:LoadAdditional(db[kind].Additional)) do
					if module:CanAlterFrame(_G[f]) then _G[f]:SetAlpha(1) end
				end
			end

			self.timerin = 0
			self:Hide()
		end
	end)

	local f = CreateFrame("Frame", nil, UIParent)

	f:RegisterEvent("PLAYER_ENTERING_WORLD")
	f:SetScript("OnEvent", function(self)
		module:ApplyBackground(kind)
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	end)
end

function module:ApplyBackground(kind)
	local data = db[kind]
	local frame, frameName
	if kind == "Chat" then
		frameName = "ChatAlphaAnchor"
		frame = ChatAlphaAnchor
		frame:Raise() -- Fix for Panel being above chat frame
	else
		frameName = data.Anchor
		frame = _G[frameName]
	end
	_mainPanels[kind].frame = frameName

	if not frame or (frame.IsForbidden and frame:IsForbidden()) then
		_mainPanels[kind]:Hide()
		return
	end
	if frame:IsProtected() and InCombatLockdown() then
		_mainPanels[kind]:Hide()
		self:RefreshMainPanels()
		return
	end

	local rc, gc, bc, ac = module:RGBA(kind)
	local r, g, b, a = module:RGBA(kind.."Border")
	
	if data.Direction == "CENTER" then data.Direction = "SOLID" end
	_mainPanels[kind]:Set(data.Direction, frame, data.Width, data.Height, 1, r, g, b, a, rc, gc, bc, ac)
	_mainPanels[kind]:ClearAllPoints()
	_mainPanels[kind]:SetPoint("TOPLEFT", frame, "TOPLEFT", data.OffsetX, data.OffsetY)
	_mainPanels[kind]:Show()
end

function module:setMainPanels()
	db = module.db.profile.LUITextures

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

function module:RefreshMainPanels()
	if InCombatLockdown() then
		if not module.mainPanelRefreshFrame then
			module.mainPanelRefreshFrame = CreateFrame("Frame")
			module.mainPanelRefreshFrame:SetScript("OnEvent", function(self)
				self:UnregisterEvent("PLAYER_REGEN_ENABLED")
				module:RefreshMainPanels()
			end)
		end
		module.mainPanelRefreshFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end
	if module.mainPanelRefreshFrame then
		module.mainPanelRefreshFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
	end
	self:ApplyBackground("Chat")
	self:ApplyBackground("Tps")
	self:ApplyBackground("Dps")
	self:ApplyBackground("Raid")
end

function module:IterateMainPanels()
	return pairs(_mainPanels)
end
