-- This provides Infotext with a clickable multi-column frame, mainly used for Guild/Friends.

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Infotext
local module = LUI:GetModule("Infotext")

local Media = LibStub("LibSharedMedia-3.0")
local element = {}

-- local copies
local unpack, pairs = unpack, pairs
local floor, max, min = math.floor, math.max, math.min

-- constants
local CLASS_ICONS_TEXTURE = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"
local INFOTIP_MAXLINE_CUTOFF = 4
local INFOTIP_MIN_WIDTH = 90
local BUTTON_HEIGHT = 15
local SLIDER_WIDTH = 16
local ICON_SIZE = 13

local GAP = 10

-- locals
local infotipStorage = {}

-- ####################################################################################################################
-- ##### Infotip: Line Mixin ##########################################################################################
-- ####################################################################################################################

local LineMixin = {}
local InfotipMixin = {}

function LineMixin:AddTexture(anchor, offsetX)
	local tex = self:CreateTexture()
	tex:SetWidth(ICON_SIZE)
	tex:SetHeight(ICON_SIZE)
	tex:SetPoint("LEFT", anchor or self, anchor and "RIGHT" or "LEFT", offsetX, 0)
	return tex
end

function LineMixin:SetClassIcon(tex, class)
	if not tex then return end
	if not class or not _G.CLASS_ICON_TCOORDS[class] then
		tex:SetTexture(nil)
		return
	end
	tex:SetTexture(CLASS_ICONS_TEXTURE)
	local offset, left, right, bottom, top = 0.025, unpack(_G.CLASS_ICON_TCOORDS[class])
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
	sepTex:SetPoint("LEFT", 0, 0)
	sepTex:SetPoint("RIGHT", 0, 0)
	sepTex:SetHeight(8)
	if anchor then sep:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT") end
	return sep
end

function InfotipMixin:GetSliderOffset()
	if not self.hasSlider or not self.slider then return 1 end
	local minValue, maxValue = self.slider:GetMinMaxValues()
	return floor(min(maxValue, max(minValue, self.slider:GetValue())) + 0.5)
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
			local maxValue = 1 + topValue - self.maxLines
			self.slider:SetMinMaxValues(1, maxValue)
			self.slider.updating = true
			self.slider:SetValue(min(maxValue, max(1, self.slider:GetValue())))
			self.slider.updating = nil
			self.slider:Show()
			self.hasSlider = true
		else
			self.slider:Hide()
			self.hasSlider = false
		end
	end
end

function InfotipMixin:EnsureSlider()
	if not self.slider then
		self.slider = element:AddSlider(self)
	end
	return self.slider
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
	local infotip = line:GetParent()
	local highlight = infotip.highlight

	highlight:ClearAllPoints()
	highlight:SetAllPoints(line)
	highlight:Show()
end

function element.OnLineLeave(line)
	local infotip = line:GetParent()
	local highlight = infotip.highlight

	highlight:ClearAllPoints()
	highlight:Hide()

	if not infotip:IsMouseOver() then
		infotip:Hide()
	end
end

function module:EnforceMinWidth(infotip, value)
	if value < infotip.minWidth then
		infotip:SetWidth(infotip.minWidth)
	end
end

function module:AnchorInfotip(infotip)
	local parent = infotip.infotext:GetFrame()
	local point = module.db.profile[infotip.infotext:GetName()].Point or "TOP"

	-- Always leave exactly one owner-relative anchor behind.  The tooltip
	-- NineSlice only decorates the frame; it must never become part of the
	-- positioning chain.
	infotip:ClearAllPoints()
	if point:find("BOTTOM", 1, true) then
		infotip:SetPoint("BOTTOM", parent, "TOP", 0, 0)
	else
		infotip:SetPoint("TOP", parent, "BOTTOM", 0, 0)
	end
end

function module:SetBoundedInfotipSize(infotip, width, height)
	-- Keep the complete NineSlice inside UIParent at every scale and resolution.
	local maxWidth = max(INFOTIP_MIN_WIDTH, UIParent:GetWidth() - GAP * 2)
	local maxHeight = max(BUTTON_HEIGHT, UIParent:GetHeight() - GAP * 2)
	infotip:SetWidth(min(width, maxWidth))
	infotip:SetHeight(min(height, maxHeight))
end

function module:ApplyInfotipBackdrop(frame, name)
	local settings = module.db.profile[name] and module.db.profile[name].Background
	local color = settings and settings.Color
	local border = settings and settings.Border
	local textureName = settings and settings.Texture or "Blizzard Tooltip"
	local borderTextureName = settings and settings.BorderTexture or "Blizzard Tooltip"
	local texture = Media:Fetch("background", textureName, true)
	local borderTexture = Media:Fetch("border", borderTextureName, true)
	local useColorFill = textureName == "None" or not texture or texture == ""
	local useNativeBorder = borderTextureName == "Blizzard Tooltip" or not borderTexture or borderTexture == ""

	-- Friends and Guild use Blizzard's current tooltip NineSlice for their
	-- boundary.  Keep the configurable LUI texture as the center only; tinting
	-- the legacy UI-Tooltip-Border white produced the bright rectangular outline
	-- and no longer matched TooltipBorderedFrameTemplate on Retail.
	if frame.NineSlice and NineSliceUtil then
		NineSliceUtil.ApplyLayoutByName(frame.NineSlice, "TooltipDefaultLayout")
		NineSliceUtil.DisableSharpening(frame.NineSlice)
		frame.NineSlice:SetShown(useNativeBorder)
		if useNativeBorder then
			frame.NineSlice:SetBorderColor(
				border and border.r or 1,
				border and border.g or 1,
				border and border.b or 1,
				border and border.a or 1)
		end
		if frame.NineSlice.Center then
			frame.NineSlice.Center:Hide()
		end
	end

	LUI:ApplyFrameBackdrop(frame, {
		bgFile = useColorFill and [[Interface\Buttons\WHITE8X8]] or texture,
		edgeFile = not useNativeBorder and borderTexture or nil,
		edgeSize = 16,
		tile = not useColorFill,
		tileSize = 16,
		insets = {left = 4, right = 4, top = 4, bottom = 4},
	})
	if useColorFill then
		LUI:SetFrameBackgroundColor(frame,
			color and color.r or 0,
			color and color.g or 0,
			color and color.b or 0,
			color and color.a or 0.8)
	else
		-- Display selected SharedMedia textures with their original colors.
		LUI:SetFrameBackgroundColor(frame, 1, 1, 1, 1)
	end
	if not useNativeBorder then
		LUI:SetFrameBorderColor(frame,
			border and border.r or 1,
			border and border.g or 1,
			border and border.b or 1,
			border and border.a or 1)
	end
end

function element:AddSlider(newtip)
	local slider = CreateFrame("Slider", nil, newtip)
	slider:SetWidth(SLIDER_WIDTH)
	slider:SetOrientation("VERTICAL")
	slider:SetThumbTexture([[Interface\Buttons\UI-SliderBar-Button-Vertical]])
	LUI:ApplyFrameBackdrop(slider, {
		bgFile = [[Interface\Buttons\UI-SliderBar-Background]],
		edgeFile = [[Interface\Buttons\UI-SliderBar-Border]],
		edgeSize = 8, tile = true, tileSize = 8,
		insets = {left=3, right=3, top=6, bottom=6}
	})
	slider:SetValueStep(1)
	local infotext = newtip.infotext
	slider:SetScript("OnValueChanged", function(self, value_)
		if not self.updating and newtip:IsMouseOver() and infotext.OnSliderUpdate then
			infotext:OnSliderUpdate()
		end
	end)
	return slider
end

function module:NewInfotip(infotext)
	local name = infotext:GetName()
	local parent = infotext:GetFrame()
	local parentName = parent:GetName()

	-- The display frame already has a sanitized, unique global name. LDB object
	-- names themselves may contain spaces or punctuation that are invalid here.
	local newtip = CreateFrame("Frame", parentName and (parentName.."Infotip") or nil, parent, "TooltipBorderedFrameTemplate")
	infotipStorage[name] = newtip
	newtip.infotext = infotext
	for k, v in pairs(InfotipMixin) do
		newtip[k] = v
	end

	--Set Properties
	newtip:EnableMouse(true)
	newtip:SetFrameStrata("TOOLTIP")
	newtip:SetClampedToScreen(true)
	-- A friend or guild row must never be rendered outside the NineSlice
	-- boundary, even while its anchors are rebuilt during a slider update.
	newtip:SetClipsChildren(true)
	module:ApplyInfotipBackdrop(newtip, name)

	module:AnchorInfotip(newtip)

	-- Give every Infotip its own highlight texture.
	newtip.highlight = newtip:CreateTexture()
	newtip.highlight:SetTexture([[Interface\QuestFrame\UI-QuestTitleHighlight]])
	newtip.highlight:SetBlendMode("ADD")
	newtip.highlight:Hide()

	-- Only one Infotip may be visible at a time.
	newtip:HookScript("OnShow", function(self)
		for _, otherTip in pairs(infotipStorage) do
			if otherTip ~= self and otherTip:IsShown() then
				otherTip:Hide()
			end
		end
	end)

	newtip:HookScript("OnHide", function(self)
		self.highlight:Hide()
	end)

	--Trigger the element's OnLeave when you leave the infotip
	newtip:SetScript("OnLeave", infotext.OnLeave)

	-- Enforce Infotip minimum width.
	newtip.minWidth = INFOTIP_MIN_WIDTH
	module:SecureHook(newtip, "SetWidth", "EnforceMinWidth")

	-- Initialize some values
	newtip.maxHeight = 0
	newtip.maxWidth = INFOTIP_MIN_WIDTH

	-- Calculate Infotip highest numbers of possible lines.
	newtip.maxLines = max(1,
		floor((UIParent:GetHeight() - GAP * 2) / BUTTON_HEIGHT - INFOTIP_MAXLINE_CUTOFF))
	newtip.totalLines = 0

	return newtip
end

local function RefreshFrameFonts(frame, font)
	for _, region in ipairs({frame:GetRegions()}) do
		if region:IsObjectType("FontString") then
			region:SetFont(Media:Fetch("font", font.Name), font.Size, font.Flag)
		end
	end
	for _, child in ipairs({frame:GetChildren()}) do
		RefreshFrameFonts(child, font)
	end
end

function module:RefreshInfotips()
	local font = module.db.profile.Fonts.Infotip
	for _, infotip in pairs(infotipStorage) do
		module:AnchorInfotip(infotip)
		RefreshFrameFonts(infotip, font)
		module:ApplyInfotipBackdrop(infotip, infotip.infotext:GetName())
	end
end

function module:HideInfotips()
	for _, infotip in pairs(infotipStorage) do
		infotip:Hide()
	end
end
