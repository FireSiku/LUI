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
local DRAWER_BAR_OFFSET = 0.625
local LEFT_BAR_FINE_TUNE = 0.07

local function IsDominosAnchor(frameName, frame)
	return type(frameName) == "string"
		and frameName:match("^DominosFrame%d+$") ~= nil
		and frame
		and type(frame.ShowFrame) == "function"
		and type(frame.HideFrame) == "function"
end

local function SetAnchoredFrameShown(frameName, shown)
	local frame = frameName and _G[frameName]
	if not frame or (frame.IsForbidden and frame:IsForbidden()) then return end

	if IsDominosAnchor(frameName, frame) then
		frame[shown and "ShowFrame" or "HideFrame"](frame)
	elseif shown then
		frame:Show()
	else
		frame:Hide()
	end
end

local function RestoreAnchoredFrame(self, frameName, onlyIfDisabled)
	if onlyIfDisabled and self.db.Enable and self.db.Anchor == frameName then return end
	SetAnchoredFrameShown(frameName, true)
end

local RestoreAnchoredFrameOutOfCombat = LUI.OutOfCombatWrapper(RestoreAnchoredFrame)

-- ####################################################################################################################
-- ##### Mixin Functions ##############################################################################################
-- ####################################################################################################################

function SidebarMixin:Open()
	if not self.OpenAnim:IsPlaying() then
		-- Open Instantly if the option is set or we are in combat.
		-- Additionally, if called while already open, force it without playing the animation.
		if self.db.OpenInstant or InCombatLockdown() or self:IsOpen() then
			self.Drawer:SetAlpha(1)
			-- Protected anchored action-bar frames are toggled by the secure
			-- PostClick wrapper while in combat.
			if not InCombatLockdown() then
				self.BtnAnchorOpen:Show()
				self.BtnAnchor:Hide()
				SetAnchoredFrameShown(self.db.Anchor, true)
			end
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
			-- Protected anchored action-bar frames are toggled by the secure
			-- PostClick wrapper while in combat.
			if not InCombatLockdown() then
				self.BtnAnchorOpen:Hide()
				self.BtnAnchor:Show()
				SetAnchoredFrameShown(self.db.Anchor, false)
			end
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
			if not PlayerInCombat() or not self:GetAttribute("secureEnabled") then return end
			local usesStateHidden = self:GetAttribute("anchorUsesStateHidden")
			
			if anchoredFrame and usesStateHidden then
				if showAnchor then
					anchoredFrame:SetAttribute("state-hidden", nil)
				else
					anchoredFrame:SetAttribute("state-hidden", true)
				end
			elseif anchoredFrame and showAnchor then
				anchoredFrame:Show()
			elseif anchoredFrame then
				anchoredFrame:Hide()
		end

		if otherFrame then otherFrame:Show() end
		self:Hide()
	]=]
end

--- Refresh the sidebar's settings and position
function SidebarMixin:Refresh()
	local r, g, b = module:RGBA("Sidebar"..self.side)
	local previousAnchor = self.activeAnchor
	if previousAnchor and previousAnchor ~= self.db.Anchor then
		RestoreAnchoredFrameOutOfCombat(self, previousAnchor)
	end
	self.activeAnchor = self.db.Anchor

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
		self.OpenAnim:Stop()
		self.CloseAnim:Stop()
		self.Drawer:SetAlpha(0)
		RestoreAnchoredFrameOutOfCombat(self, self.db.Anchor, true)
		self:Hide()
	end

	if not InCombatLockdown() then
		local anchor = _G[self.db.Anchor]
		local validAnchor = anchor and not (anchor.IsForbidden and anchor:IsForbidden())
		self.BtnAnchor:SetAttribute("secureEnabled", validAnchor and true or false)
		self.BtnAnchorOpen:SetAttribute("secureEnabled", validAnchor and true or false)
		local usesStateHidden = IsDominosAnchor(self.db.Anchor, anchor)
		self.BtnAnchor:SetAttribute("anchorUsesStateHidden", usesStateHidden and true or false)
		self.BtnAnchorOpen:SetAttribute("anchorUsesStateHidden", usesStateHidden and true or false)
		if validAnchor then
			self.BtnAnchor:SetFrameRef("anchor", anchor)
			self.BtnAnchorOpen:SetFrameRef("anchor", anchor)
		end
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

local function ApplyBT4Adjust(self)
	if not C_AddOns.IsAddOnLoaded("Bartender4") or type(self.db.Anchor) ~= "string"
		or strsub(self.db.Anchor, 1, 3) ~= "BT4" then return end
	local bartender = _G.Bartender4
	if not bartender or not bartender.db or type(bartender.UpdateModuleConfigs) ~= "function" then return end
	local actionBars = bartender.db:GetNamespace("ActionBars", true)
	local _, num = strsplit("r", self.db.Anchor)
	local barOpt = actionBars and actionBars.profile and actionBars.profile.actionbars[tonumber(num)]
	if not barOpt then return end
	local _, _, _, x, y = self:GetPoint()
	local _, _, texWidth = self:GetRect()
	local _, _, drawWidth, drawHeight = self.Drawer:GetRect()

	--- For both the Tex and Drawer sizes, we need to account for the UI Scale, then reapply the frame scale to get proper values
	local barScale = self:GetEffectiveScale()
	local uiScale = UIParent:GetScale()

	-- X is the leftmost point of the sidebar artwork. The nature of the drawer artwork means adjustments are needed.
	-- The proper offset is equal to 62.5% of the width of the drawer texture.
	local barX
	if self.side == "Right" then
		barX = x - texWidth - drawWidth * DRAWER_BAR_OFFSET
	else
		-- The LEFT point already uses the sidebar's outer left edge as its
		-- origin. The small extra offset centers Bartender inside the
		-- asymmetric left drawer without changing the working right side.
		barX = x + drawWidth * (DRAWER_BAR_OFFSET + LEFT_BAR_FINE_TUNE)
	end
	barX = barX / uiScale * barScale
	
	-- Y is the halfway point, so we have to add half the height of the drawer to the y position.
	-- Then we can adjust based on a fixed offset based on the top of the drawer texture.
	local barY = (y + drawHeight*0.41) / uiScale * barScale

	
	-- Update Bartender settings.
	barOpt.enabled = self.db.Enable
	barOpt.buttons = 12
	barOpt.rows = 6
	barOpt.alpha = 1
	barOpt.position.x = barX
	barOpt.position.y = barY
	barOpt.position.point = (self.side == "Right") and "RIGHT" or "LEFT"
	barOpt.position.scale = barScale
	bartender:UpdateModuleConfigs()
end

-- Bartender rebuilds secure action-button state from UpdateModuleConfigs.
-- Never invoke it during combat; apply the latest sidebar values on leaving.
SidebarMixin.BT4Adjust = LUI.OutOfCombatWrapper(ApplyBT4Adjust)

module.SidebarMixin = SidebarMixin

-- ####################################################################################################################
-- ##### Sidebar Factory ##############################################################################################
-- ####################################################################################################################

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
	local direction = isRight and -1 or 1
	local innerOffset = isRight and -10 or 10
	local drawerOffset = isRight and 10 or -10

	local function SetSidebarTexCoord(texture, atlas)
		local left, right, top, bottom = LUI:GetCoordAtlas(atlas)
		if isRight then
			texture:SetTexCoord(left, right, top, bottom)
		else
			texture:SetTexCoord(right, left, top, bottom)
		end
	end

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
	SetSidebarTexCoord(sbar, "sidebar_base")
	sbar:Show()

	-- Button Anchor
	local btnAnchor = CreateFrame("Button", sbarName.."ButtonAnchor", sidebar, "SecureHandlerClickTemplate")
	btnAnchor:SetSize(22, 245)
	btnAnchor:SetPoint(other, sidebar, other, innerOffset, 0)
	btnAnchor:SetFrameLevel(sidebar:GetFrameLevel() + 10)
	btnAnchor:Show()

	-- Button Anchor
	local btnAnchorOpen = CreateFrame("Button", sbarName.."ButtonAnchorOpen", sidebar, "SecureHandlerClickTemplate")
	btnAnchorOpen:SetSize(22, 245)
	btnAnchorOpen:SetFrameLevel(sidebar:GetFrameLevel() + 10)
	btnAnchorOpen:SetPoint(other, sidebar, other, innerOffset + direction * BUTTON_OFFSET, 0)
	btnAnchorOpen:Hide()
	
	local drawer = sidebar:CreateTexture(sbarName.."Drawer", "BACKGROUND")
	drawer:SetSize(100, 247)
	drawer:SetTexture("Interface\\AddOns\\LUI\\media\\templates\\v4\\sidebar_drawer")
	SetSidebarTexCoord(drawer, "sidebar_drawer")
	drawer:SetPoint(other, btnAnchorOpen, other, drawerOffset, 0)
	drawer:SetAlpha(0)

	local drawerButton = btnAnchor:CreateTexture(sbarName.."DrawerButton", "BACKGROUND")
	drawerButton:SetTexture("Interface\\AddOns\\LUI\\media\\templates\\v4\\sidebar_button")
	SetSidebarTexCoord(drawerButton, "sidebar_button")
	drawerButton:SetAllPoints(btnAnchor)
	drawerButton:Show()

	local drawerButtonOpen = btnAnchorOpen:CreateTexture(sbarName.."DrawerButton", "BACKGROUND")
	drawerButtonOpen:SetTexture("Interface\\AddOns\\LUI\\media\\templates\\v4\\sidebar_button")
	SetSidebarTexCoord(drawerButtonOpen, "sidebar_button")
	drawerButtonOpen:SetAllPoints(btnAnchorOpen)
	drawerButtonOpen:Show()

	-- Set the hover animations, variables are localized to prevent unnecessary calls. 
	local h1, h2, h3, h4 = LUI:GetCoordAtlas("sidebar_button_hover")
	local h5, h6, h7, h8 = LUI:GetCoordAtlas("sidebar_button")
	if not isRight then
		h1, h2 = h2, h1
		h5, h6 = h6, h5
	end
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
	a3:SetOffset(direction * BUTTON_OFFSET, 0)
	a3:SetDuration(ANIM_DURATION)
	drawOpen:SetScript("OnPlay", function() drawerAlphaIn:Play() end)
	drawOpen:SetScript("OnFinished", function()
		if not InCombatLockdown() then
			btnAnchorOpen:Show()
			btnAnchor:Hide()
			SetAnchoredFrameShown(sidebar.db.Anchor, true)
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
	a4:SetOffset(-direction * BUTTON_OFFSET, 0)
	a4:SetDuration(ANIM_DURATION)
	a4:SetStartDelay(ANIM_DURATION/4)
	drawClose:SetScript("OnPlay", function()
		drawerAlphaOut:Play()
		if not InCombatLockdown() then
			SetAnchoredFrameShown(sidebar.db.Anchor, false)
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
