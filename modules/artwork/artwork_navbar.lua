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

function module:CreateNavBar()
	local topBackground = CreateFrame("Frame", "LUIArtwork_NavBarTopBackground", UIParent)
	topBackground:SetSize(1024, 1024)
	topBackground:SetFrameStrata("BACKGROUND")
	topBackground:SetPoint("TOP", UIParent, "TOP", 17, -18)
	SetFrameImage(topBackground, "top")
	topBackground:SetAlpha(ALPHA)

	local centerBackground = CreateFrame("Frame", "LUIArtwork_NavBarCenterBackground", UIParent)
	centerBackground:SetSize(1035, 1024)
	centerBackground:SetFrameStrata("BACKGROUND")
	centerBackground:SetPoint("TOP", UIParent, "TOP", 17, -18)
	SetFrameImage(centerBackground, "top_back_complete")
	centerBackground:SetAlpha(ALPHA)

	local topPanelTex = CreateFrame("Frame", "LUIArtwork_InfoPanel", UIParent)
	topPanelTex:SetSize(32, 32)
	topPanelTex:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 8)
	topPanelTex:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 8)
	topPanelTex:SetFrameStrata("BACKGROUND")
	topPanelTex.Texture = LUI:CreateFrameTexture(topPanelTex, INFOPANEL_TEXTURE)
	topPanelTex:Show()

	local leftBorder = CreateFrame("Frame", "LUIArtwork_LeftBorder", UIParent)
	leftBorder:SetSize(1024, 1024)
	leftBorder:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", -30, -31)
	leftBorder:SetFrameStrata("BACKGROUND")
	leftBorder.Texture = LUI:CreateFrameTexture(leftBorder, [[Interface\AddOns\LUI\media\templates\v3\info_left]])
	leftBorder.Texture:SetVertexColor(0, 0, 0, 0.9)
	leftBorder:Show()

	local leftBorderBack = CreateFrame("Frame", "LUIArtwork_LeftBorderBack", leftBorder)
	leftBorderBack:SetSize(1024, 1024)
	leftBorderBack:SetPoint("BOTTOMLEFT", leftBorder, "BOTTOMLEFT", 7, 8)
	leftBorderBack:SetFrameStrata("BACKGROUND")
	leftBorderBack.Texture = LUI:CreateFrameTexture(leftBorderBack, [[Interface\AddOns\LUI\media\templates\v3\info_left_back]])
	leftBorderBack:SetFrameLevel(leftBorder:GetFrameLevel() - 1)

	local rightBorder = CreateFrame("Frame", "LUIArtwork_RightBorder", UIParent)
	rightBorder:SetSize(1024, 1024)
	rightBorder:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 36, -31)
	rightBorder:SetFrameStrata("BACKGROUND")
	rightBorder.Texture = LUI:CreateFrameTexture(rightBorder, [[Interface\AddOns\LUI\media\templates\v3\info_right]])
	rightBorder.Texture:SetVertexColor(0, 0, 0, 0.9)
	rightBorder:Show()

	local rightBorderBack = CreateFrame("Frame", "LUIArtwork_RightBorderBack", rightBorder)
	rightBorderBack:SetSize(1024, 1024)
	rightBorderBack:SetPoint("BOTTOMRIGHT", rightBorder, "BOTTOMRIGHT", -7, 8)
	rightBorderBack:SetFrameStrata("BACKGROUND")
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
	local db = module.db.profile.LUITextures
	local isWide = (side == "left2" or side == "right2")


	local clicker = CreateFrame("Button", "LUIArtwork_NavBar"..side.."Clicker", UIParent, "SecureHandlerClickTemplate")
	clicker:SetSize(isWide and 70 or 63, 30)
	clicker:SetFrameStrata("LOW")
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
	clicker:SetScript("OnClick", function()
		local frame = _G[db[kind].Anchor]
		if frame and not frame:IsShown() then
			if kind == "Chat" and not (alphaOut:IsPlaying() or alphaIn:IsPlaying()) then
				module:SetChatVisible(true)
			end
			alphaIn:Play()
			module:AlphaIn(kind, self)
			db[kind].IsShown = true
		elseif frame and frame:IsShown() then
			if kind == "Chat" and not (alphaOut:IsPlaying() or alphaIn:IsPlaying()) then
				module:SetChatVisible(false)
			end
			alphaOut:Play()
			module:AlphaOut(kind, self)
			db[kind].IsShown = false
		end
		if module.SyncOrbState then module:SyncOrbState() end
	end)
	if kind ~= "Chat" then 
		SecureHandlerWrapScript(clicker, "PostClick", clicker, [[
			if not self:GetAttribute("secureEnabled") then return end
			local frame = self:GetFrameRef("frame")
			if not frame then return end
			local show = not frame:IsShown()
			if show then frame:Show() else frame:Hide() end
			local count = self:GetAttribute("additionalCount") or 0
			for i = 1, count do
				local additional = self:GetFrameRef("additional"..i)
				if additional then
					if show then additional:Show() else additional:Hide() end
				end
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
	if InCombatLockdown() then
		navBarRefreshFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end

	navBarRefreshFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")

	local db = module.db.profile.LUITextures
	local protectedFrames = {}
	local anyPanelShown = false
	module.NavBarCenter.Texture:SetVertexColor(self:RGBA("TopPanel"))
	module.TopPanel.Texture:SetVertexColor(self:RGBA("TopPanel"))
	module.TopPanel:Show()
	module.LeftBorderBack.Texture:SetVertexColor(self:RGBA("LeftBorderBack"))
	module.RightBorderBack.Texture:SetVertexColor(self:RGBA("LeftBorderBack"))

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
		local db = module.db.profile.LUITextures[kind]
		local r, g, b, a = self:RGBA("NavButtons")
		local anchor = _G[db.Anchor]
		local validAnchor = anchor and not (anchor.IsForbidden and anchor:IsForbidden())
		local shouldShow = db.AlwaysShow or db.IsShown
		db.IsShown = shouldShow
		anyPanelShown = anyPanelShown or shouldShow

		button.tex:SetVertexColor(r, g, b, a)
		button.hover:SetVertexColor(r, g, b, 0)
		button.tex:SetAlpha(shouldShow and ALPHA or 0)
		if showButtons then button:Show() else button:Hide() end

		if validAnchor and module:CanAlterFrame(anchor) then
			if shouldShow then
				anchor:SetAlpha(1)
				anchor:Show()
				if kind == "Chat" then module:SetChatVisible(true) end
			else
				anchor:SetAlpha(0)
				anchor:Hide()
			end

			for _, frameName in pairs(module:LoadAdditional(db.Additional)) do
				local frame = _G[frameName]
				if module:CanAlterFrame(frame) then
					frame:SetAlpha(shouldShow and 1 or 0)
					if shouldShow then frame:Show() else frame:Hide() end
				end
			end
		end
		
		-- If the anchor is a protected frame, we need to use the secure code path
		button:SetAttribute("secureEnabled", validAnchor and anchor:IsProtected() or false)
		button:SetAttribute("additionalCount", 0)
		if validAnchor and anchor:IsProtected() then
			button:SetFrameRef("frame", anchor)
			protectedFrames[#protectedFrames + 1] = anchor

			local additionalFrames = module:LoadAdditional(db.Additional)
			local count = 0
			for _, frameName in ipairs(additionalFrames) do
				local additional = _G[frameName]
				if additional and not (additional.IsForbidden and additional:IsForbidden()) then
					count = count + 1
					button:SetFrameRef("additional"..count, additional)
					if additional:IsProtected() then protectedFrames[#protectedFrames + 1] = additional end
				end
			end
			button:SetAttribute("additionalCount", count)
		end

	end

	if module.Orb then
		local orbClicker = module.Orb.Clicker
		orbClicker:SetAttribute("panelsOpen", anyPanelShown)
		orbClicker:SetAttribute("protectedCount", #protectedFrames)
		for index, frame in ipairs(protectedFrames) do
			orbClicker:SetFrameRef("protected"..index, frame)
		end
		module:SyncOrbState()
	end
end
