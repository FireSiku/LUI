-- This provides Infotext with a clickable multi-column frame, mainly used for Guild/Friends.

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, LUIAddon
local _, LUI = ...
local L = LUI.L

---@type InfotextModule
local module = LUI:GetModule("Infotext")

---@type TooltipModule
local modTooltip = LUI:GetModule("Tooltip")
local element = {}

-- local copies
local unpack, pairs = unpack, pairs

-- constants
local CLASS_ICONS_TEXTURE = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"
local INFOTIP_MAXLINE_CUTOFF = 4
local INFOTIP_MIN_WIDTH = 90
local BUTTON_HEIGHT = 15
local SLIDER_WIDTH = 16
local ICON_SIZE = 13

--Find better name for these constants
local GAP = 10

-- locals
local infotipStorage = {}
local highlight

-- ####################################################################################################################
-- ##### Infotip: Line Mixin ##########################################################################################
-- ####################################################################################################################

local LineMixin = {}
local InfotipMixin = {}

-- What's the need for anchor already?
function LineMixin:AddTexture(anchor, offsetX)
	local tex = self:CreateTexture()
	tex:SetWidth(ICON_SIZE)
	tex:SetHeight(ICON_SIZE)
	tex:SetPoint("LEFT", anchor or self, anchor and "RIGHT" or "LEFT", offsetX, 0)
	return tex
end

function LineMixin:SetClassIcon(tex, class)
	tex:SetTexture(CLASS_ICONS_TEXTURE)
	local offset, left, right, bottom, top = 0.025, unpack(CLASS_ICON_TCOORDS[class])
	tex:SetTexCoord(left+offset, right-offset, bottom+offset, top-offset)
end

function LineMixin:AddFontString(justify, anchor, offsetX, r, g, b)
	--If anchor is a number, shift anchor and offset to be RGB
	if type(anchor) == "number" then
		r, g, b = anchor, offsetX, r
		anchor = nil
		offsetX = nil
	end
	local fs = module:SetFontString(self, nil, "Infotip", "OVERLAY", justify)
	if anchor then fs:SetPoint("LEFT", anchor, "RIGHT", offsetX or GAP, 0) end
	if r and g and b then fs:SetTextColor(r, g, b) end
	fs:SetShadowOffset(1, -1)
	return fs
end

function LineMixin:AddHighlight()
	self:SetScript("OnEnter", element.OnLineEnter)
end

function LineMixin:ResetHeight()
	self:SetHeight(BUTTON_HEIGHT)
end

-- ####################################################################################################################
-- ##### Infotip: Infotip Mixin #######################################################################################
-- ####################################################################################################################

function InfotipMixin:NewLine()
	local lineName = format("%sLine%d",self:GetName(),self.totalLines + 1)
	local newline = CreateFrame("Button", lineName, self)
	for k, v in pairs(LineMixin) do
		newline[k] = v
	end
	newline:SetHeight(BUTTON_HEIGHT)

	newline:EnableMouseWheel(true)
	newline:RegisterForClicks("AnyUp")
	newline:SetScript("OnLeave", element.OnLineLeave)
	newline:SetScript("OnMouseWheel", element.OnLineScroll)

	newline:SetPoint("LEFT")
	newline:SetPoint("RIGHT")

	-- increase line count
	self.totalLines = self.totalLines + 1
	if self.totalLines > self.maxLines and not self.slider then
		self.slider = element:AddSlider(self)
	end

	return newline
end

function InfotipMixin:AddSeparator(anchor)
	local sep = self:NewLine()
	local sepTex = sep:CreateTexture()
	sepTex:SetTexture("Interface\\FriendsFrame\\UI-FriendsFrame-OnlineDivider")
	sepTex:SetPoint("LEFT")
	sepTex:SetPoint("RIGHT")
	if anchor then sep:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT") end
	return sep
end

function InfotipMixin:GetSliderOffset()
	return (self.hasSlider) and self.slider:GetValue() or 1
end

function InfotipMixin:UpdateTooltip()
	local frame = self.infotext:GetFrame()
	if frame:IsMouseOver() or self:IsMouseOver() then
		-- Re-update the tooltip by faking an OnEnter event.
		-- OnEvent's bool should be false if the mouse was already inside the frame
		module.OnEnterHandler(frame, false)
	end
end

function InfotipMixin:UpdateSlider(topValue)
	if self.slider then
		if topValue > self.maxLines then
			self.slider:SetMinMaxValues(1, 1 + topValue - self.maxLines)
			self.slider:Show()
			self.hasSlider = true
		else
			self.slider:Hide()
			self.hasSlider = false
		end
	end
end

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

function element.OnLineScroll(line, delta)
	local infotip = line:GetParent()
	if infotip.hasSlider then
		infotip.slider:SetValue(infotip:GetSliderOffset() - delta)
	end
end

function element.OnLineEnter(line)
	highlight:ClearAllPoints()
	highlight:SetAllPoints(line)
	highlight:Show()
end

function element.OnLineLeave(line)
	highlight:ClearAllPoints()
	highlight:Hide()
	local infotip = line:GetParent()
	if not infotip:IsMouseOver() then infotip:Hide() end
end

-- To revisit later, originally wanted a customizable minWidth. (default 300 to match V3 layout)
-- Right now its a strict minimum width to prevent frame from breaking.
function module:EnforceMinWidth(infotip, value)
	if value < infotip.minWidth then
		infotip:SetWidth(infotip.minWidth)
	end
end

function element:AddSlider(newtip)
	local slider = CreateFrame("Slider", nil, newtip)
	slider:SetWidth(SLIDER_WIDTH)
	slider:SetThumbTexture([[Interface\Buttons\UI-SliderBar-Button-Horizontal]])
	slider:SetBackdrop({
		bgFile = [[Interface\Buttons\UI-SliderBar-Background]],
		edgeFile = [[Interface\Buttons\UI-SliderBar-Border]],
		edgeSize = 8, tile = true, tileSize = 8,
		insets = {left=3, right=3, top=6, bottom=6}
	})
	slider:SetValueStep(1)
	local infotext = newtip.infotext
	slider:SetScript("OnValueChanged", function(self, value_)
		if newtip:IsMouseOver() and infotext.OnSliderUpdate then
			infotext:OnSliderUpdate()
		end
	end)
	return slider
end

function element:ApplyBackdropColors()
	local isModded = (modTooltip and modTooltip:IsEnabled()) and true or false
	local colorDB = (isModded) and modTooltip.db.profile.Colors
	for _, infotip in pairs(infotipStorage) do
		if isModded then
			infotip:SetBackdropColor(colorDB.Background.r, colorDB.Background.g, colorDB.Background.b)
			infotip:SetBackdropBorderColor(colorDB.Border.r, colorDB.Border.g, colorDB.Border.b)
		else
			infotip:SetBackdropColor(GameTooltip:GetBackdropColor())
			infotip:SetBackdropBorderColor(GameTooltip:GetBackdropBorderColor())
		end
	end
end

function module:NewInfotip(infotext)
	-- Hook relevant functions from the tooltip module to maintain tooltip look if it hasnt been done yet.
	
	if not module:IsHooked(modTooltip, "OnEnable") then
		module:SecureHook(modTooltip, "UpdateBackdropColors", element.ApplyBackdropColors)
		module:SecureHook(modTooltip, "OnEnable",  element.ApplyBackdropColors)
		module:SecureHook(modTooltip, "OnDisable", element.ApplyBackdropColors)
	end

	local name = infotext:GetName()
	local parent = infotext:GetFrame()

	local newtip = CreateFrame("Frame",format("LUIInfo_%sInfotip", name), parent, "BackdropTemplate")
	infotipStorage[name] = newtip
	newtip.infotext = infotext
	for k, v in pairs(InfotipMixin) do
		newtip[k] = v
	end

	--Set Properties
	newtip:EnableMouse(true)
	newtip:SetFrameStrata("TOOLTIP")
	newtip:SetClampedToScreen(true)

	--TODO: Add support for bottom panel infotexts.
	newtip:SetPoint("TOP", parent, "BOTTOM")

	-- Make frame looks like a tooltip.
	newtip:SetBackdrop(GameTooltip:GetBackdrop())
	element:ApplyBackdropColors()
	--Trigger the element's OnLeave when you leave the infotip
	newtip:SetScript("OnLeave", infotext.OnLeave)

	-- Load highlight texture
	highlight = newtip:CreateTexture()
	highlight:SetTexture([[Interface\QuestFrame\UI-QuestTitleHighlight]])
	highlight:SetBlendMode("ADD")

	-- Enforce Infotip minimum width.
	newtip.minWidth = INFOTIP_MIN_WIDTH
	module:SecureHook(newtip, "SetWidth", "EnforceMinWidth")

	-- Initialize some values
	newtip.maxHeight = 0
	newtip.maxWidth = INFOTIP_MIN_WIDTH

	-- Calculate Infotip highest numbers of possible lines.
	newtip.maxLines = floor((UIParent:GetHeight() - GAP * 2) / BUTTON_HEIGHT - INFOTIP_MAXLINE_CUTOFF)
	newtip.totalLines = 0

	return newtip
end
