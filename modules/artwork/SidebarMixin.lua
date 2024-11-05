---@class LUIAddon
local LUI = select(2, ...)

local module = LUI:GetModule("Artwork")

---@class SidebarMixin : Frame
---@field db SidebarDBOptions # The options 
---@field name string # The name of the sidebar
---@field side string # The side of the screen the sidebar is on
---@field OpenAnim SimpleAnimGroup
---@field CloseAnim SimpleAnimGroup
---@field Sbar SimpleTexture # The outer sidebar texture
---@field BtnAnchor Button # The anchor for the drawer button
---@field Drawer SimpleTexture # The drawer texture
---@field DrawerButton SimpleTexture # The drawer button texture
---@field DrawerHover SimpleTexture # The drawer hover texture
local SidebarMixin = {}

-- Sidebar Registry
---@type table<string, SidebarMixin>
local _sidebars = {}

local BUTTON_OFFSET = 85
local ANIM_DURATION = 0.5

-- ####################################################################################################################
-- ##### Mixin Functions ##############################################################################################
-- ####################################################################################################################

function SidebarMixin:Open()
	if not self.OpenAnim:IsPlaying() then
		-- Open Instantly if the option is set or we are in combat.
		-- Additionally, if called while already open, force it without playing the animation.
		if self.db.OpenInstant or InCombatLockdown() or self:IsOpen() then
			self.Drawer:SetAlpha(1)
			self.BtnAnchorOpen:Show()
			self.BtnAnchor:Hide()
			local anchoredFrame = _G[self.db.Anchor]
			if anchoredFrame then anchoredFrame:Show() end
		else
			self.OpenAnim:Play()
		end
		self.db.IsOpen = true
	end
end

function SidebarMixin:Close()
	if not self.CloseAnim:IsPlaying() then
		-- Close Instantly if the option is set or we are in combat.
		-- Additionally, if called while already closed, force it without playing the animation.
		if self.db.OpenInstant or InCombatLockdown() or not self:IsOpen() then
			self.Drawer:SetAlpha(0)
			self.BtnAnchorOpen:Hide()
			self.BtnAnchor:Show()
			local anchoredFrame = _G[self.db.Anchor]
			if anchoredFrame then anchoredFrame:Hide() end
		else
			self.CloseAnim:Play()
		end
		self.db.IsOpen = false
	end
end

function SidebarMixin:IsOpen()
	return self.db.IsOpen
end

function SidebarMixin:Toggle()
	if self:IsOpen() then
		self:Close()
	else
		self:Open()
	end
end

function SidebarMixin:SecureToggle(showAnchor)
	return "local showAnchor = "..tostring(showAnchor)..[=[
		local anchoredFrame = self:GetFrameRef("anchor")
		local otherFrame = self:GetFrameRef("otherFrame")
		if not PlayerInCombat() then return end
		
		if showAnchor then
			anchoredFrame:Show()
		else
			anchoredFrame:Hide()
		end

		otherFrame:Show()
		self:Hide()
	]=]
end

--- Refresh the sidebar's settings and position
function SidebarMixin:Refresh()
	local r, g, b, a = module:RGBA("SidebarRight")

	LUI:RegisterConfig(self, self.db)
	LUI:RestorePosition(self)
	self:Show()

	self.Sbar:SetVertexColor(r, g, b, 1)
	self.Drawer:SetVertexColor(r, g, b, 1)
	self.DrawerButton:SetVertexColor(r, g, b, 1)
	self.DrawerButtonOpen:SetVertexColor(r, g, b, 1)

	if self.db.Enable then
		self:Show()
		-- If Sidebar is shown, make sure it is in the right state.
		if self:IsOpen() then
			self:Open()
		else
			self:Close()
		end
	else
		self:Hide()
	end

	if _G[self.db.Anchor] then
		self.BtnAnchor:SetFrameRef("anchor", _G[self.db.Anchor])
		self.BtnAnchorOpen:SetFrameRef("anchor", _G[self.db.Anchor])
	end

	if self.db.AutoPosition then
		self:AutoAdjust()
	end
end

-- ####################################################################################################################
-- ##### Sidebar Adjust Logics ########################################################################################
-- ####################################################################################################################

function SidebarMixin:AutoAdjust()
	if C_AddOns.IsAddOnLoaded("Bartender4") then
		self:BT4Adjust()
	end
end

function SidebarMixin:BT4Adjust()
	if not C_AddOns.IsAddOnLoaded("Bartender4") or not (strsub(self.db.Anchor,1, 3) == "BT4") then return end
	local _, num = strsplit("r", self.db.Anchor)
	local barOpt = Bartender4.db:GetNamespace("ActionBars").profile.actionbars[tonumber(num)]
	local point, parent, relativePoint, x, y = self:GetPoint()
	local texLeft, texBottom, texWidth, texHeight = self:GetRect()
	local drawLeft, drawBottom, drawWidth, drawHeight = self.Drawer:GetRect()

	--- For both the Tex and Drawer sizes, we need to account for the UI Scale, then reapply the frame scale to get proper values
	local barScale = self:GetEffectiveScale()
	local uiScale = UIParent:GetScale()

	-- X is the leftmost point of the sidebar artwork. The nature of the drawer artwork means adjustments are needed.
	-- The proper offset is equal to 62.5% of the width of the drawer texture.
	local texOffset = (self.side == "Right") and texWidth or 0
	local barX = (x - texOffset - drawWidth*0.625) /uiScale * barScale
	
	-- Y is the halfway point, so we have to add half the height of the drawer to the y position.
	-- Then we can adjust based on a fixed offset based on the top of the drawer texture.
	local barY = (y + drawHeight*0.41) / uiScale * barScale

	-- LUI:Print(format("BT4Adjust(%d) Normal: texWidth: %.2f, drawWidth: %.2f, drawHeight: %.2f, x: %.2f, y: %.2f", num, texWidth, drawWidth, drawHeight, x, y))
	-- LUI:Print(format("Reccommended Position: BarX: %.2f, BarY: %.2f", barX, barY))
	
	-- Update Bartender settings.
	barOpt.enabled = self.db.Enable
	barOpt.buttons = 12
	barOpt.rows = 6
	barOpt.alpha = 1
	barOpt.position.x = barX
	barOpt.position.y = barY
	barOpt.position.point = (self.side == "Right") and "RIGHT" or "LEFT"
	barOpt.position.scale = barScale
	Bartender4:UpdateModuleConfigs()
end

module.SidebarMixin = SidebarMixin

-- ####################################################################################################################
-- ##### Sidebar Factory ##############################################################################################
-- ####################################################################################################################\

--- Create a new Sidebar
---@param name string # Name of the sidebar
---@param side string # Which side of the screen it will hook to
---@return SidebarMixin
function module:CreateNewSideBar(name, side)
	if _sidebars[name] then return _sidebars[name] end

	---@type SidebarMixin
	local sidebar = CreateFrame("Frame", "LUISidebar"..name, UIParent)

	local isRight = (side == "Right")
	local other = isRight and "LEFT" or "RIGHT"

	local sidedb = module.db.profile.SideBars[name]
	local sbarName = "LUISidebar"..name

	-- Create the anchor frame
	sidebar:SetSize(57, 365)
	sidebar:SetScale(sidedb.Scale)
	sidebar:Show()

	-- Create the main bar texture
	local sbar = sidebar:CreateTexture(sbarName.."Sbar", "BACKGROUND")
	sbar:SetSize(57, 365)
	sbar:SetPoint(other, sidebar, other, 0, 0)
	sbar:SetTexture("Interface\\AddOns\\LUI\\media\\templates\\v4\\sidebar_base")
	sbar:SetTexCoord(LUI:GetCoordAtlas("sidebar_base"))
	sbar:Show()

	-- Button Anchor
	local btnAnchor = CreateFrame("Button", sbarName.."ButtonAnchor", sidebar, "SecureHandlerClickTemplate")
	btnAnchor:SetSize(22, 245)
	btnAnchor:SetPoint(other, sidebar, other, -10, 0)
	btnAnchor:Show()

	-- Button Anchor
	local btnAnchorOpen = CreateFrame("Button", sbarName.."ButtonAnchorOpen", sidebar, "SecureHandlerClickTemplate")
	btnAnchorOpen:SetSize(22, 245)
	btnAnchorOpen:SetPoint(other, sidebar, other, -10 - BUTTON_OFFSET, 0)
	btnAnchorOpen:Hide()
	
	local drawer = sidebar:CreateTexture(sbarName.."Drawer", "BACKGROUND")
	drawer:SetSize(100, 247)
	drawer:SetTexture("Interface\\AddOns\\LUI\\media\\templates\\v4\\sidebar_drawer")
	drawer:SetTexCoord(LUI:GetCoordAtlas("sidebar_drawer"))
	drawer:SetPoint(other, btnAnchorOpen, other, 10, 0)
	drawer:SetAlpha(0)

	local drawerButton = btnAnchor:CreateTexture(sbarName.."DrawerButton", "BACKGROUND")
	drawerButton:SetTexture("Interface\\AddOns\\LUI\\media\\templates\\v4\\sidebar_button")
	drawerButton:SetTexCoord(LUI:GetCoordAtlas("sidebar_button"))
	-- drawerButton:SetPoint(other, btnAnchor, other, 0, 0)
	drawerButton:SetAllPoints(btnAnchor)
	drawerButton:Show()

	local drawerButtonOpen = btnAnchorOpen:CreateTexture(sbarName.."DrawerButton", "BACKGROUND")
	drawerButtonOpen:SetTexture("Interface\\AddOns\\LUI\\media\\templates\\v4\\sidebar_button")
	drawerButtonOpen:SetTexCoord(LUI:GetCoordAtlas("sidebar_button"))
	-- drawerButton:SetPoint(other, btnAnchor, other, 0, 0)
	drawerButtonOpen:SetAllPoints(btnAnchorOpen)
	drawerButtonOpen:Show()

	-- Set the hover animations, variables are localized to prevent unnecessary calls. 
	local h1, h2, h3, h4 = LUI:GetCoordAtlas("sidebar_button_hover")
	local h5, h6, h7, h8 = LUI:GetCoordAtlas("sidebar_button")
	btnAnchor:SetScript("OnEnter", function()
		drawerButton:SetTexture("Interface\\AddOns\\LUI\\media\\templates\\v4\\sidebar_button_hover")
		drawerButton:SetTexCoord(h1, h2, h3, h4)
	end)
	btnAnchor:SetScript("OnLeave", function()
		drawerButton:SetTexture("Interface\\AddOns\\LUI\\media\\templates\\v4\\sidebar_button")
		drawerButton:SetTexCoord(h5, h6, h7, h8)
	end)
	btnAnchorOpen:SetScript("OnEnter", function()
		drawerButtonOpen:SetTexture("Interface\\AddOns\\LUI\\media\\templates\\v4\\sidebar_button_hover")
		drawerButtonOpen:SetTexCoord(h1, h2, h3, h4)
	end)
	btnAnchorOpen:SetScript("OnLeave", function()
		drawerButtonOpen:SetTexture("Interface\\AddOns\\LUI\\media\\templates\\v4\\sidebar_button")
		drawerButtonOpen:SetTexCoord(h5, h6, h7, h8)
	end)

	-- Animations
	local drawerAlphaIn = drawer:CreateAnimationGroup()
	local a1 = drawerAlphaIn:CreateAnimation("Alpha")
	a1:SetFromAlpha(0)
	a1:SetToAlpha(1)
	a1:SetDuration(ANIM_DURATION/2)
	a1:SetStartDelay(ANIM_DURATION/2)
	drawerAlphaIn:SetScript("OnFinished", function() drawer:SetAlpha(1) end)

	local drawOpen = btnAnchor:CreateAnimationGroup()
	local a3 = drawOpen:CreateAnimation("Translation")
	a3:SetOffset(-BUTTON_OFFSET, 0)
	a3:SetDuration(ANIM_DURATION)
	drawOpen:SetScript("OnPlay", function() drawerAlphaIn:Play() end)
	drawOpen:SetScript("OnFinished", function()
		if not InCombatLockdown() then
			btnAnchorOpen:Show()
			btnAnchor:Hide()
			local anchoredFrame = _G[sidebar.db.Anchor]
			if anchoredFrame then 
				anchoredFrame:Show()
			end
		end
	end)

	local drawerAlphaOut = drawer:CreateAnimationGroup()
	local a2 = drawerAlphaOut:CreateAnimation("Alpha")
	a2:SetFromAlpha(1)
	a2:SetToAlpha(0)
	a2:SetDuration(ANIM_DURATION)
	drawerAlphaOut:SetScript("OnFinished", function() drawer:SetAlpha(0) end)
	
	local drawClose = btnAnchorOpen:CreateAnimationGroup()
	local a4 = drawClose:CreateAnimation("Translation")
	a4:SetOffset(BUTTON_OFFSET, 0)
	a4:SetDuration(ANIM_DURATION)
	a4:SetStartDelay(ANIM_DURATION/4)
	drawClose:SetScript("OnPlay", function()
		drawerAlphaOut:Play()
		if not InCombatLockdown() then
			local anchoredFrame = _G[sidebar.db.Anchor]
			if anchoredFrame then
				anchoredFrame:Hide()
			end
		end
	end)
	drawClose:SetScript("OnFinished", function()
		if not InCombatLockdown() then
			btnAnchorOpen:Hide()
			btnAnchor:Show()
		end
	end)

	sidebar.OpenAnim = drawOpen
	sidebar.CloseAnim = drawClose

	-- Config
	sidebar:EnableMouse(true)
	Mixin(sidebar, module.SidebarMixin)

	btnAnchor:SetScript("OnClick", function() sidebar:Toggle() end)
	SecureHandlerWrapScript(btnAnchor, "PostClick", btnAnchor, sidebar:SecureToggle(true))
	btnAnchor:RegisterForClicks("AnyUp")
	
	btnAnchor:SetFrameRef("otherFrame", btnAnchorOpen)

	btnAnchorOpen:SetScript("OnClick", function() sidebar:Toggle() end)
	SecureHandlerWrapScript(btnAnchorOpen, "PostClick", btnAnchorOpen, sidebar:SecureToggle(false))
	btnAnchorOpen:RegisterForClicks("AnyUp")
	btnAnchorOpen:SetFrameRef("otherFrame", btnAnchor)

	sidebar.name = name
	sidebar.db = sidedb
	sidebar.side = side

	-- Attach Frames
	sidebar.Sbar = sbar
	sidebar.Drawer = drawer
	sidebar.BtnAnchor = btnAnchor
	sidebar.BtnAnchorOpen = btnAnchorOpen
	sidebar.DrawerButton = drawerButton
	sidebar.DrawerButtonOpen = drawerButtonOpen

	_sidebars[name] = sidebar
	sidebar:Refresh()
	
	return sidebar
end

--- Iterate over all sidebars
---@return  fun(table: table<K, V>, index?: K):K, V
function module:IterateSidebars()
	return pairs(_sidebars)
end
