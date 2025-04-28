-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Artwork : LUIModule
local module = LUI:GetModule("Artwork")

local TEX_DIR = [[Interface\AddOns\LUI\media\templates\v4\]]
local OLD_DIR = [[Interface\AddOns\LUI\media\templates\v3\]]
local ANIM_DURATION = 0.5
local ALPHA = 0.75

-- constants
local INFOPANEL_TEXTURE = "Interface\\AddOns\\LUI\\media\\textures\\infopanel"

---@type table<string, Frame|BackdropTemplate>
local _navButtons = {}

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################
local function SetFrameBackdrop(frame, fileName)
	if not frame then LUI:Print("frame not found:", fileName) end
	frame:SetBackdrop({
		bgFile = OLD_DIR..fileName, edgeSize = 1,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	})
	frame:SetBackdropBorderColor(0,0,0,0)
end

function module:CreateNavBar()
	local topBackground = CreateFrame("Frame", "LUIArtwork_NavBarTopBackground", UIParent, "BackdropTemplate")
	topBackground:SetSize(1024, 1024)
	topBackground:SetFrameStrata("BACKGROUND")
	topBackground:SetPoint("TOP", UIParent, "TOP", 17, -18)
	SetFrameBackdrop(topBackground, "top")
	topBackground:SetAlpha(ALPHA)

	local centerBackground = CreateFrame("Frame", "LUIArtwork_NavBarCenterBackground", UIParent, "BackdropTemplate")
	centerBackground:SetSize(1035, 1024)
	centerBackground:SetFrameStrata("BACKGROUND")
	centerBackground:SetPoint("TOP", UIParent, "TOP", 17, -18)
	SetFrameBackdrop(centerBackground, "top_back_complete")
	--SetFrameBackdrop(centerBackground, "top_back")
	centerBackground:SetAlpha(ALPHA)

	local topPanelTex = CreateFrame("Frame", "LUIArtwork_InfoPanel", UIParent, "BackdropTemplate")
	topPanelTex:SetSize(32, 32)
	topPanelTex:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 8)
	topPanelTex:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 8)
	topPanelTex:SetFrameStrata("BACKGROUND")
	topPanelTex:SetBackdrop({
		bgFile = INFOPANEL_TEXTURE, edgeSize = 1,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	})
	topPanelTex:SetBackdropBorderColor(0, 0, 0, 0)
	topPanelTex:Show()

	-- Bottom corner Textures, since they require Backdrop for now.
	local leftBorder = CreateFrame("Frame", "LUIArtwork_LeftBorder", UIParent, "BackdropTemplate")
	leftBorder:SetSize(1024, 1024)
	leftBorder:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", -30, -31)
	leftBorder:SetFrameStrata("BACKGROUND")
	leftBorder:SetBackdrop({
		bgFile =[[Interface\AddOns\LUI\media\templates\v3\info_left]],
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
	})
	leftBorder:SetBackdropColor(0, 0, 0, 0.9)
	leftBorder:SetBackdropBorderColor(0, 0, 0, 0)
	leftBorder:Show()

	local leftBorderBack = CreateFrame("Frame", "LUIArtwork_LeftBorderBack", leftBorder, "BackdropTemplate")
	leftBorderBack:SetSize(1024, 1024)
	leftBorderBack:SetPoint("BOTTOMLEFT", leftBorder, "BOTTOMLEFT", 7, 8)
	leftBorderBack:SetFrameStrata("BACKGROUND")
	leftBorderBack:SetBackdrop({
		bgFile =[[Interface\AddOns\LUI\media\templates\v3\info_left_back]],
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
	})
	leftBorderBack:SetBackdropBorderColor(0, 0, 0, 0)
	leftBorderBack:SetFrameLevel(leftBorder:GetFrameLevel() - 1)

	-- Bottom corner Textures, since they require Backdrop for now.
	local rightBorder = CreateFrame("Frame", "LUIArtwork_LeftBorder", UIParent, "BackdropTemplate")
	rightBorder:SetSize(1024, 1024)
	rightBorder:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 36, -31)
	rightBorder:SetFrameStrata("BACKGROUND")
	rightBorder:SetBackdrop({
		bgFile =[[Interface\AddOns\LUI\media\templates\v3\info_right]],
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
	})
	rightBorder:SetBackdropColor(0, 0, 0, 0.9)
	rightBorder:SetBackdropBorderColor(0, 0, 0, 0)
	rightBorder:Show()

	local rightBorderBack = CreateFrame("Frame", "LUIArtwork_LeftBorderBack", rightBorder, "BackdropTemplate")
	rightBorderBack:SetSize(1024, 1024)
	rightBorderBack:SetPoint("BOTTOMRIGHT", rightBorder, "BOTTOMRIGHT", -7, 8)
	rightBorderBack:SetFrameStrata("BACKGROUND")
	rightBorderBack:SetBackdrop({
		bgFile =[[Interface\AddOns\LUI\media\templates\v3\info_right_back]],
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
	})
	rightBorderBack:SetBackdropBorderColor(0, 0, 0, 0)
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
	end)
	if kind ~= "Chat" then 
		SecureHandlerWrapScript(clicker, "PostClick", clicker, [[
			local frame = self:GetFrameRef("frame")
			if frame and not frame:IsShown() then
				self:GetFrameRef("frame"):Show()
				if self:GetFrameRef("additional1") then self:GetFrameRef("additional1"):Show() end
				if self:GetFrameRef("additional2") then self:GetFrameRef("additional2"):Show() end
				if self:GetFrameRef("additional3") then self:GetFrameRef("additional3"):Show() end
			elseif frame then
				self:GetFrameRef("frame"):Hide()
				if self:GetFrameRef("additional1") then self:GetFrameRef("additional1"):Hide() end
				if self:GetFrameRef("additional2") then self:GetFrameRef("additional2"):Hide() end
				if self:GetFrameRef("additional3") then self:GetFrameRef("additional3"):Hide() end
			end
		]])
	end

	clicker.tex = tex
	clicker.hover = hover
	_navButtons[kind] = clicker
end

function module:RefreshNavBar()
	local db = module.db.profile.LUITextures
	module.NavBarCenter:SetBackdropColor(self:RGBA("TopPanel"))
	module.TopPanel:SetBackdropColor(self:RGBA("TopPanel"))
	module.LeftBorderBack:SetBackdropColor(self:RGBA("LeftBorderBack"))
	module.RightBorderBack:SetBackdropColor(self:RGBA("LeftBorderBack"))

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
	for kind, button in pairs(_navButtons) do
		local db = module.db.profile.LUITextures[kind]
		local r, g, b, a = self:RGBA("NavButtons")
		button.tex:SetVertexColor(r, g, b, a)
		button.hover:SetVertexColor(r, g, b, 0)
		if showButtons then button:Show() else button:Hide() end

		if not db.IsShown then button.tex:SetAlpha(0) end
		
		-- If the anchor is a protected frame, we need to use the secure code path
		if _G[db.Anchor] and _G[db.Anchor]:IsProtected() then
			button:SetFrameRef("frame", _G[db.Anchor])

			if _G[db.Additional] and _G[db.Additional] ~= "" then
				local additionalFrames = module:LoadAdditional(db.Additional)
				if _G[additionalFrames[1]] then button:SetFrameRef("additional1", _G[additionalFrames[1]]) end
				if _G[additionalFrames[2]] then button:SetFrameRef("additional2", _G[additionalFrames[2]]) end
				if _G[additionalFrames[3]] then button:SetFrameRef("additional3", _G[additionalFrames[3]]) end
			end
		end

	end
end
