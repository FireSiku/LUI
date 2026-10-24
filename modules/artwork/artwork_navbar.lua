-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Artwork : LUIModule
local module = LUI:GetModule("Artwork")

local OLD_DIR = [[Interface\AddOns\LUI\media\templates\v3\]]
local ANIM_DURATION = 0.5
local ALPHA = 0.75

-- constants
local INFOPANEL_TEXTURE = "Interface\\AddOns\\LUI\\media\\textures\\infopanel"

---@type table<string, Button>
local _navButtons = {}
-- Show at Login initializes each profile once; refreshes preserve later clicks.
local initializedProfiles = setmetatable({}, {__mode = "k"})

-- Refreshing the navigation bar can show, hide, or modify protected frames.
-- Defer the refresh until combat has ended.
local navBarRefreshFrame = CreateFrame("Frame")
navBarRefreshFrame:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_REGEN_ENABLED" then
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
		module:RefreshNavBar()
	end
end)

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################
local function SetFrameImage(frame, fileName)
	local texture = LUI:CreateFrameTexture(frame, OLD_DIR..fileName)
	frame.Texture = texture
	return texture
end

function module:SetPanelIndicator(texture, shown, animate)
	-- A previous fade must not finish after the next click or a refresh.
	texture.alphaIn:Stop()
	texture.alphaOut:Stop()
	if animate then
		if shown then texture.alphaIn:Play() else texture.alphaOut:Play() end
	else
		texture:SetAlpha(shown and ALPHA or 0)
	end
end

function module:SetMainPanelShown(kind, shown)
	if not self:IsEnabled() then return end
	local button = _navButtons[kind]
	local frame = self:GetMainPanelVisibilityFrame(kind)
	if not button or not frame or (frame.IsForbidden and frame:IsForbidden()) then return end

	-- Chat visibility is independent of the decorative button animation.
	if kind == "Chat" then self:SetChatVisible(shown) end
	self:SetPanelIndicator(button.tex, shown, true)
	if shown then self:AlphaIn(kind) else self:AlphaOut(kind) end
	if not InCombatLockdown() then button:SetAttribute("panelShown", shown) end
end

function module:CreateNavBar()
	local topBackground = CreateFrame("Frame", "LUIArtwork_NavBarTopBackground", UIParent)
	topBackground:SetSize(1024, 1024)
	topBackground:SetFrameStrata("LOW")
	topBackground:SetPoint("TOP", UIParent, "TOP", 17, -18)
	SetFrameImage(topBackground, "top")
	topBackground:SetAlpha(ALPHA)

	local centerBackground = CreateFrame("Frame", "LUIArtwork_NavBarCenterBackground", UIParent)
	centerBackground:SetSize(1035, 1024)
	centerBackground:SetFrameStrata("LOW")
	centerBackground:SetPoint("TOP", UIParent, "TOP", 17, -18)
	SetFrameImage(centerBackground, "top_back_complete")
	centerBackground:SetAlpha(ALPHA)

	local topPanelTex = CreateFrame("Frame", "LUIArtwork_InfoPanel", UIParent)
	topPanelTex:SetSize(32, 32)
	topPanelTex:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 8)
	topPanelTex:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 8)
	topPanelTex:SetFrameStrata("LOW")
	topPanelTex.Texture = LUI:CreateFrameTexture(topPanelTex, INFOPANEL_TEXTURE)
	topPanelTex:Show()

	local leftBorder = CreateFrame("Frame", "LUIArtwork_LeftBorder", UIParent)
	leftBorder:SetSize(1024, 1024)
	leftBorder:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", -30, -31)
	leftBorder:SetFrameStrata("LOW")
	leftBorder.Texture = LUI:CreateFrameTexture(leftBorder, [[Interface\AddOns\LUI\media\templates\v3\info_left]])
	leftBorder.Texture:SetVertexColor(0, 0, 0, 0.9)
	leftBorder:Show()

	local leftBorderBack = CreateFrame("Frame", "LUIArtwork_LeftBorderBack", leftBorder)
	leftBorderBack:SetSize(1024, 1024)
	leftBorderBack:SetPoint("BOTTOMLEFT", leftBorder, "BOTTOMLEFT", 7, 8)
	leftBorderBack:SetFrameStrata("LOW")
	leftBorderBack.Texture = LUI:CreateFrameTexture(leftBorderBack, [[Interface\AddOns\LUI\media\templates\v3\info_left_back]])
	leftBorderBack:SetFrameLevel(leftBorder:GetFrameLevel() - 1)

	local rightBorder = CreateFrame("Frame", "LUIArtwork_RightBorder", UIParent)
	rightBorder:SetSize(1024, 1024)
	rightBorder:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 36, -31)
	rightBorder:SetFrameStrata("LOW")
	rightBorder.Texture = LUI:CreateFrameTexture(rightBorder, [[Interface\AddOns\LUI\media\templates\v3\info_right]])
	rightBorder.Texture:SetVertexColor(0, 0, 0, 0.9)
	rightBorder:Show()

	local rightBorderBack = CreateFrame("Frame", "LUIArtwork_RightBorderBack", rightBorder)
	rightBorderBack:SetSize(1024, 1024)
	rightBorderBack:SetPoint("BOTTOMRIGHT", rightBorder, "BOTTOMRIGHT", -7, 8)
	rightBorderBack:SetFrameStrata("LOW")
	rightBorderBack.Texture = LUI:CreateFrameTexture(rightBorderBack, [[Interface\AddOns\LUI\media\templates\v3\info_right_back]])
	rightBorderBack:SetFrameLevel(rightBorder:GetFrameLevel() - 1)

	topBackground:SetFrameLevel(centerBackground:GetFrameLevel() + 1)
	module.NavBar = topBackground
	module.NavBarCenter = centerBackground
	module.TopPanel = topPanelTex
	module.LeftBorder = leftBorder
	module.LeftBorderBack = leftBorderBack
	module.RightBorder = rightBorder
	module.RightBorderBack = rightBorderBack

	module:CreateNavButton("Chat", "left2", -164, -7)
	module:CreateNavButton("Tps", "left1", -88, -7)
	module:CreateNavButton("Dps", "right1", 58, -7)
	module:CreateNavButton("Raid", "right2", 135, -7)

	C_Timer.After(0.1, function() module:RefreshNavBar() end)
end

--- Create the NavBar buttons.
---@param side "left2"|"left1"|"right1"|"right2"
function module:CreateNavButton(kind, side, x, y)
	local isWide = (side == "left2" or side == "right2")


	local clicker = CreateFrame("Button", "LUIArtwork_NavBar"..side.."Clicker", UIParent, "SecureHandlerClickTemplate")
	clicker:SetSize(isWide and 70 or 63, 30)
	clicker:SetFrameStrata("LOW")
	clicker:SetFrameLevel(module.NavBar:GetFrameLevel() + 2)
	clicker:SetPoint("TOP", module.NavBar, "TOP", x, y)
	clicker:SetAlpha(1)

	local tex = clicker:CreateTexture(nil, "ARTWORK")
	tex:SetPoint("TOP", module.NavBar, "TOP", x, y)
	tex:SetTexture(OLD_DIR.."button_"..side)
	tex:SetTexCoord(LUI:GetCoordAtlas("nav_button_"..side))

	-- Animations
	local alphaIn = tex:CreateAnimationGroup()
	local a1 = alphaIn:CreateAnimation("Alpha")
	a1:SetFromAlpha(0)
	a1:SetToAlpha(ALPHA)
	a1:SetDuration(ANIM_DURATION)
	alphaIn:SetScript("OnFinished", function() tex:SetAlpha(ALPHA) end)

	local alphaOut = tex:CreateAnimationGroup()
	local a2 = alphaOut:CreateAnimation("Alpha")
	a2:SetFromAlpha(ALPHA)
	a2:SetToAlpha(0)
	a2:SetDuration(ANIM_DURATION)
	alphaOut:SetScript("OnFinished", function() tex:SetAlpha(0) end)

	-- Hover animation
	local hover = clicker:CreateTexture(nil, "ARTWORK")
	hover:SetPoint("TOP", module.NavBar, "TOP", x, y)
	hover:SetTexture(OLD_DIR.."button_"..side.."_hover")
	hover:SetTexCoord(LUI:GetCoordAtlas("nav_button_"..side))
	hover:SetAlpha(0)

	if isWide then
		tex:SetSize(74, 25)
		hover:SetSize(74, 25)
	else
		tex:SetSize(60, 24)
		hover:SetSize(60, 24)
	end
	clicker:RegisterForClicks("AnyUp")
	clicker:SetScript("OnEnter", function() hover:SetAlpha(ALPHA) end)
	clicker:SetScript("OnLeave", function() hover:SetAlpha(0) end)
	local function OnClick()
		if not module:IsEnabled() then return end
		local shown = module.db.profile.LUITextures[kind].IsShown
		if InCombatLockdown() and not LUI.IsForever then
			shown = clicker:GetAttribute("panelShown")
		end
		module:SetMainPanelShown(kind, not shown)
		module:SyncOrbState()
	end
	clicker:SetScript("OnClick", LUI.IsForever and LUI.OutOfCombatWrapper(OnClick) or OnClick)
	if not LUI.IsForever then
		SecureHandlerWrapScript(clicker, "PostClick", clicker, [[
			if not PlayerInCombat() then return end
			if not self:GetAttribute("panelEnabled") then return end
			local show = not self:GetAttribute("panelShown")
			self:SetAttribute("panelShown", show)
			local count = self:GetAttribute("protectedCount") or 0
			for i = 1, count do
				local frame = self:GetFrameRef("protected"..i)
				if frame then
					if show then frame:Show() else frame:Hide() end
				end
			end
			local orb = self:GetFrameRef("orb")
			if orb then
				local anyShown = false
				for i = 1, orb:GetAttribute("buttonCount") or 0 do
					local button = orb:GetFrameRef("button"..i)
					if button and button:GetAttribute("panelEnabled") and button:GetAttribute("panelShown") then
						anyShown = true
						break
					end
				end
				orb:SetAttribute("panelsOpen", anyShown)
			end
		]])
	end

	clicker.tex = tex
	clicker.hover = hover
	clicker.tex.alphaIn = alphaIn
	clicker.tex.alphaOut = alphaOut
	_navButtons[kind] = clicker
end

function module:IterateNavButtons()
	return pairs(_navButtons)
end

function module:RefreshNavBar()
	if not module:IsEnabled() or not module.NavBar then return end
	if InCombatLockdown() then
		navBarRefreshFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end

	navBarRefreshFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")

	local db = module.db.profile.LUITextures
	local initialize = not initializedProfiles[db]
	local orbClicker = module.Orb and module.Orb.Clicker
	local buttonCount = 0
	module.NavBarCenter.Texture:SetVertexColor(self:RGBA("TopPanel"))
	module.TopPanel.Texture:SetVertexColor(self:RGBA("TopPanel"))
	module.TopPanel:Show()
	module.LeftBorderBack.Texture:SetVertexColor(self:RGBA("LeftBorderBack"))
	module.RightBorderBack.Texture:SetVertexColor(self:RGBA("RightBorderBack"))

	if db.NavBar.TopBackground then
		module.NavBar:Show()
	else
		module.NavBar:Hide()
	end

	if db.NavBar.CenterBackground then
		module.NavBarCenter:Show()
	else
		module.NavBarCenter:Hide()
	end

	if db.NavBar.BlackLines then
		module.LeftBorder:Show()
		module.RightBorder:Show()
	else
		module.LeftBorder:Hide()
		module.RightBorder:Hide()
	end

	if db.NavBar.ThemedLines then
		module.LeftBorderBack:Show()
		module.RightBorderBack:Show()
	else
		module.LeftBorderBack:Hide()
		module.RightBorderBack:Hide()
	end
	local showButtons = db.NavBar.ShowButtons
	for kind, button in module:IterateNavButtons() do
		module:StopPanelAnimations(kind)
		local db = module.db.profile.LUITextures[kind]
		local r, g, b, a = self:RGBA("NavButtons")
		local anchor = module:GetMainPanelVisibilityFrame(kind)
		local validAnchor = anchor and not (anchor.IsForbidden and anchor:IsForbidden())
		local shouldShow = db.IsShown or (initialize and db.AlwaysShow) or false
		db.IsShown = shouldShow

		button.tex:SetVertexColor(r, g, b, a)
		button.hover:SetVertexColor(r, g, b, 0)
		module:SetPanelIndicator(button.tex, validAnchor and shouldShow, false)
		if showButtons then button:Show() else button:Hide() end

		if validAnchor and module:CanAlterFrame(anchor) then
			if shouldShow then
				anchor:SetAlpha(1)
				anchor:Show()
				if kind == "Chat" then module:SetChatVisible(true) end
			else
				anchor:Hide()
				anchor:SetAlpha(1)
			end

			for _, frameName in pairs(module:LoadAdditional(db.Additional)) do
				local frame = _G[frameName]
				if module:CanAlterFrame(frame) then
					if shouldShow then frame:Show() else frame:Hide() end
					frame:SetAlpha(1)
				end
			end
		end
		
		-- Every button shares its requested state with the orb. Collect protected
		-- additional frames even when the main anchor itself is unprotected.
		button:SetAttribute("panelEnabled", not not validAnchor)
		button:SetAttribute("panelShown", validAnchor and shouldShow or false)
		local count = 0
		if validAnchor then
			if anchor:IsProtected() then
				count = count + 1
				button:SetFrameRef("protected"..count, anchor)
			end
			for _, frameName in ipairs(module:LoadAdditional(db.Additional)) do
				local additional = _G[frameName]
				if additional and not (additional.IsForbidden and additional:IsForbidden()) and additional:IsProtected() then
					count = count + 1
					button:SetFrameRef("protected"..count, additional)
				end
			end
		end
		button:SetAttribute("protectedCount", count)
		if orbClicker then
			button:SetFrameRef("orb", orbClicker)
			buttonCount = buttonCount + 1
			orbClicker:SetFrameRef("button"..buttonCount, button)
		end
	end
	initializedProfiles[db] = true

	if orbClicker then
		orbClicker:SetAttribute("buttonCount", buttonCount)
		module:SyncOrbState()
	end
end
