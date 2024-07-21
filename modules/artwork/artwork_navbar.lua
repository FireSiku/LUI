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
local ALPHA = 0.7

---@type table<string, SidebarMixin>
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
	topBackground:SetPoint("TOP", UIParent, "TOP", 17, -16)
	SetFrameBackdrop(topBackground, "top")
	topBackground:SetAlpha(ALPHA)

	local centerBackground = CreateFrame("Frame", "LUIArtwork_NavBarCenterBackground", UIParent, "BackdropTemplate")
	centerBackground:SetSize(1035, 1024)
	centerBackground:SetFrameStrata("BACKGROUND")
	centerBackground:SetPoint("TOP", UIParent, "TOP", 17, -17)
	SetFrameBackdrop(centerBackground, "top_back_complete")
	--SetFrameBackdrop(centerBackground, "top_back")
	centerBackground:SetAlpha(ALPHA)

	topBackground:SetFrameLevel(centerBackground:GetFrameLevel() + 1)
	module.NavBar = topBackground
	module.NavBarCenter = centerBackground

	module:CreateNavButton("Chat", "left2", -164, -7)
	module:CreateNavButton("Tps", "left1", -88, -7)
	module:CreateNavButton("Dps", "right1", 58, -7)
	module:CreateNavButton("Raid", "right2", 135, -7)

	module:RefreshNavBar()
end

--- Create the NavBar buttons.
---@param side "left2"|"left1"|"right1"|"right2"
function module:CreateNavButton(kind, side, x, y)
	local db = module.db.profile.LUITextures
	local isWide = (side == "left2" or side == "right2")


	local clicker = CreateFrame("Button", "LUIArtwork_NavBar"..side.."Clicker", UIParent)
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
		---@TODO: Make these SecureActions
		if tex:GetAlpha() == 0 and not alphaIn:IsPlaying() then
			db[kind].IsShown = true
			alphaIn:Play()
		elseif not alphaOut:IsPlaying() then
			db[kind].IsShown = false
			alphaOut:Play()
		end
	end)
	
	clicker.tex = tex
	clicker.hover = hover
	_navButtons[kind] = clicker
end

function module:RefreshNavBar()
	local r, g, b = LUI:GetClassColor(LUI.playerClass)
	module.NavBarCenter:SetBackdropColor(r, g, b)

	for kind, button in pairs(_navButtons) do
		local db = module.db.profile.LUITextures[kind]
		if db.IsShown then
			button.tex:SetAlpha(ALPHA)
		else
			button.tex:SetAlpha(0)
		end

		button.tex:SetVertexColor(r, g, b)
		button.hover:SetVertexColor(r, g, b)
	end
end
