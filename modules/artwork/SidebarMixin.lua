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
local ANIM_DURATION = 0.4

-- ####################################################################################################################
-- ##### Mixin Functions ##############################################################################################
-- ####################################################################################################################

--- Get the parent frame of the panel.
---@return Frame parent
function SidebarMixin:GetAnchor()
	--TODO: Add support for LibWindow for proper texture scaling when not anchored.
	if self.db.Anchored then
		return _G[self.db.Parent]
	else
		return UIParent
	end
end

function SidebarMixin:AddBarToDrawer()
end

function SidebarMixin:RemoveBarFromDrawer()
end

function SidebarMixin:Open()
	if self:IsOpen() then return end
	if not self.OpenAnim:IsPlaying() then
		self.OpenAnim:Play()
		self.db.IsOpen = true
	end
end

function SidebarMixin:Close()
	if not self:IsOpen() then return end
	if not self.CloseAnim:IsPlaying() then
		self.CloseAnim:Play()
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
	local r, g, b, a = module:RGBA("MAGE")

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
			self.OpenAnim:Play()
		else
			self.CloseAnim:Play()
		end
	else
		self:Hide()
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
	local _, _, texWidth, texHeight = self:GetRect()
	local _, _, drawWidth, drawHeight = self.Drawer:GetRect()
	
	-- X is the leftmost point of the sidebar artwork. The nature of the drawer artwork means adjustments are needed.
	-- The proper offset to remove 60% of the width of the drawer texture.
	local texOffset = self.side == "RIGHT" and texWidth or 0
	local barX = x - texOffset - drawWidth*0.6
	
	-- Y is the halfway point, so we have to add half the height of the drawer to the y position.
	-- Then we can adjust based on a fixed offset based on the top of the drawer texture.
	local barY = y + drawHeight*0.4

	barOpt.enabled = self.db.Enable
	for k, v in pairs({}) do
		barOpt[k] = v
	end
	barOpt.position.scale = self.db.Scale
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
	local sidebar = CreateFrame("Frame", "LUISidebar"..name)

	local other = "LEFT"

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
	a1:SetDuration(ANIM_DURATION)
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
	--btnAnchor:SetAttribute("_onclick", sidebar:SecureToggle(true))
	btnAnchor:RegisterForClicks("AnyUp")
	btnAnchor:SetFrameRef("anchor", _G[sidedb.Anchor])
	btnAnchor:SetFrameRef("otherFrame", btnAnchorOpen)

	btnAnchorOpen:SetScript("OnClick", function() sidebar:Toggle() end)
	SecureHandlerWrapScript(btnAnchorOpen, "PostClick", btnAnchorOpen, sidebar:SecureToggle(false))
	--btnAnchorOpen:SetAttribute("_onclick", sidebar:SecureToggle(false))
	btnAnchorOpen:RegisterForClicks("AnyUp")
	btnAnchorOpen:SetFrameRef("anchor", _G[sidedb.Anchor])
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