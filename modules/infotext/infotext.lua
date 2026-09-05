-- This module provides a LibDataBroker display for LUI and third-party data
-- objects, owns LUI's built-in infotext displays and exposes the Ace module
-- helpers used by its elements.

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)
local L = LUI.L

---@class LUI.Infotext
local module = LUI:GetModule("Infotext")

local LDB = LibStub:GetLibrary("LibDataBroker-1.1")
local Media = LibStub("LibSharedMedia-3.0")
module.RegisterLDBCallback = LDB.RegisterCallback
module.UnregisterAllLDBCallbacks = LDB.UnregisterAllCallbacks
module.LDB = LDB
local db

local select, pairs = select, pairs

-- local variables
local elementFrames = {} -- Holds all the LDB frames.
local elementStorage = {} -- Will hold the infotext's elements for iteration.
local InfoMixin = {} -- Prototype for element functions.

-- Icon-only launchers fall back to their label or object name.
local supportedTypes = {
	["data source"] = true,
	["launcher"] = true,
}

local defaultPositions = 0
local frameNameCounts = {}
local TOP_BAR_VISIBLE_HEIGHT = 24
local TOP_BAR_TEXT_POINTS = {
	TOP = "TOPLEFT",
	MIDDLE = "LEFT",
	BOTTOM = "BOTTOMLEFT",
}

local function GetDisplayFrameName(name)
	local base = "LUIInfo_" .. tostring(name):gsub("[^%w_]", "_")
	local count = (frameNameCounts[base] or 0) + 1
	frameNameCounts[base] = count
	return count == 1 and base or (base .. "_" .. count)
end

local function UpdateDisplaySize(frame)
	local width = frame.text:GetUnboundedStringWidth()
	local _, fontHeight = frame.text:GetFont()
	if issecretvalue(width) or issecretvalue(fontHeight) then return end
	local textHeight = math.max(1, math.ceil(fontHeight or 1) + 2)

	-- LUIArtwork_InfoPanel is 32 units high and starts 8 units above the
	-- screen, leaving a 24-unit visible top bar. Anchor the FontString itself
	-- instead of relying on vertical justification; this applies the setting
	-- consistently to every top-bar display.
	local point = frame:GetPoint()
	local topAnchored = type(point) == "string" and point:find("TOP", 1, true)
	local minimumHeight = topAnchored and TOP_BAR_VISIBLE_HEIGHT or 1
	local frameWidth = math.max(1, math.ceil(width))
	frame:SetSize(frameWidth, math.max(minimumHeight, textHeight))

	frame.text:ClearAllPoints()
	frame.text:SetSize(frameWidth, textHeight)
	frame.text:SetJustifyV("MIDDLE")
	if topAnchored then
		local textPoint = TOP_BAR_TEXT_POINTS[db.TopBarTextAnchor] or TOP_BAR_TEXT_POINTS.TOP
		frame.text:SetPoint(textPoint, frame, textPoint)
	else
		frame.text:SetPoint("LEFT", frame, "LEFT")
	end
end

-- ####################################################################################################################
-- ##### InfoMixin ####################################################################################################
-- ####################################################################################################################

function InfoMixin:GetName()
	return LDB:GetNameByDataObject(self)
end

function InfoMixin:GetFrame()
	return elementFrames[self:GetName()]
end

function InfoMixin:TooltipHeader(headerName, handleGT)
	if handleGT then
		GameTooltip:SetOwner(self:GetFrame(), "ANCHOR_BOTTOM")
		GameTooltip:ClearLines()
	end
	--Make sure the header ends with a colon
	if headerName:sub(-1) ~= ":" then
		headerName = headerName..":"
	end
	GameTooltip:AddLine(headerName, module:RGB("Title"))
	GameTooltip:AddLine(" ")
end

function InfoMixin:AddHint(...)
	local r, g, b = module:RGB("Hint")
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(L["Info_Hint"], r, g, b)
	for i=1, select("#", ...) do
		GameTooltip:AddLine(select(i, ...), r, g, b)
	end
end

function InfoMixin:AddUpdate(func, delay)
	local frame = self:GetFrame()
	frame.time = 0
	--Check if func is a methodname or function reference
	local method = type(func) == "string" and true or false
	--Set up the update script
	frame:SetScript("OnUpdate", function(frame, elapsed)
		frame.time = frame.time + elapsed
		if frame.time > delay then
			frame.time = 0
			if method then
				self[func](self)
			else
				func()
			end
		end
	end)
end

function InfoMixin:ResetUpdateTimer()
	local frame = self:GetFrame()
	frame.time = 0
end

function InfoMixin:UpdateTooltip()
	local frame = self:GetFrame()
	if frame:IsMouseOver() and GameTooltip:GetOwner() == frame then
		-- Re-update the tooltip by faking an OnEnter event.
		-- OnEvent's bool should be false if the mouse was already inside the frame
		module.OnEnterHandler(frame, false)
	end
end

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################-

function module:SetInfoPanels()
	db = module.db.profile

	local topAnchor = _G.LUIInfotextAnchor
	if not topAnchor then
		topAnchor = CreateFrame("Frame", "LUIInfotextAnchor", UIParent)
		topAnchor:SetSize(1, 1)
		topAnchor:SetFrameStrata("HIGH")
		topAnchor:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, -1)
	end
	topAnchor:Show()
	module.topAnchor = topAnchor

	-- Make sure all objects created before the callback gets properly initialized.
	for name, element in LDB:DataObjectIterator() do
		if not elementFrames[name] then
			self:DataObjectCreated(name, element)
		else
			module:RegisterLDBCallback("LibDataBroker_AttributeChanged_"..name, "AttributeChanged")
		end
	end

	module:RegisterLDBCallback("LibDataBroker_DataObjectCreated", "LDBDataObjectCreated")
end

function module:NewElement(name, ...)
	local element = LDB:NewDataObject(name, {type = "data source", text = name})
	for k, v in pairs(InfoMixin) do
		element[k] = v
	end
	-- Add Embeddable Ace Libraries.
	for i=1, select("#", ...) do
		LibStub(select(i, ...)):Embed(element)
	end
	elementStorage[name] = element
	return element
end

function module:GetElement(name)
	return elementStorage[name]
end

function module:IterateElements()
	return pairs(elementStorage)
end

-- Iterate the display frames created for built-in and third-party LDB objects.
function module:IterateDisplays()
	return pairs(elementFrames)
end

function module:IsPositionSet(name)
	return elementStorage[name] ~= nil or db[name].X ~= 0 or db[name].Y ~= 0 or db[name].Point ~= "TOPLEFT"
end

function module:SetPosition(name, frame)
	frame:ClearAllPoints()
	if module:IsPositionSet(name) then
		local point = db[name].Point
		local x = tonumber(db[name].X) or 0
		local y = tonumber(db[name].Y) or 0
		if type(point) == "string" and point:find("TOP", 1, true) then
			x = x + (tonumber(db.TopBarOffsetX) or 0)
			y = y + (tonumber(db.TopBarOffsetY) or 0)
		end
		frame:SetPoint(point, UIParent, point, x, y)
	else
		defaultPositions = defaultPositions + 1
		local defaultX = -25 + (50 * defaultPositions)
		frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", defaultX, 5)
	end
end
-- ####################################################################################################################
-- ##### LDB Handling #################################################################################################
-- ####################################################################################################################

--This is used on the creation of any LDB Object
function module:DataObjectCreated(name, element)
	if not supportedTypes[element.type] then return end
	if elementFrames[name] then return end

	local frame = CreateFrame("Button", GetDisplayFrameName(name), module.topAnchor)
	elementFrames[name] = frame
	frame.name = name
	frame.element = element

	frame.text = module:SetFontString(frame, frame:GetName().."Text", "Infotext", "OVERLAY", "LEFT", "MIDDLE")
	frame.text:SetAllPoints(frame)
	local color = db[name].Color
	frame.text:SetTextColor(color.r, color.g, color.b, color.a)
	frame.text:SetShadowColor(0,0,0)
	frame.text:SetShadowOffset(1.25, -1.25)

	frame:RegisterForClicks("AnyUp")
	frame:SetScript("OnClick", module.OnClickHandler)
	frame:SetScript("OnEnter", module.OnEnterHandler)
	frame:SetScript("OnLeave", module.OnLeaveHandler)

	--Do some element based stuff here
	if elementStorage[name] then LUI:EmbedModule(element) end
	if element.OnCreate then element:OnCreate(frame) end

	module:SetPosition(name, frame)

	local displayText = element.text or element.label or name
	if not issecretvalue(displayText) then frame.text:SetText(displayText) end
	UpdateDisplaySize(frame)
	if db[name].Enable then
		frame:Show()
	else
		frame:Hide()
	end

	--This allow me to unregister callbacks based on element instead of filtering using the global one.
	module:RegisterLDBCallback("LibDataBroker_AttributeChanged_"..name, "AttributeChanged")
end

function module:LDBDataObjectCreated(_, name, element)
	self:DataObjectCreated(name, element)
end

function module:AttributeChanged(event_, name, attr, value, element_)
	local frame = elementFrames[name]
	if frame and (attr == "text" or attr == "label") then
		local displayText = frame.element.text or frame.element.label or name
		if issecretvalue(displayText) then return end
		frame.text:SetText(displayText)
		UpdateDisplaySize(frame)
	end
end

-- ####################################################################################################################
-- ##### LDB: Event Handlers ##########################################################################################
-- ####################################################################################################################

function module.OnClickHandler(self, ...)
	local element = self.element
	if element.OnClick then element.OnClick(self, ...) end
end

function module.OnEnterHandler(self, ...)
	local element = self.element
	if element.OnEnter then
		element.OnEnter(self, ...)
	elseif element.OnTooltipShow then
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		GameTooltip:ClearLines()
		element.OnTooltipShow(GameTooltip)
		GameTooltip:Show()
	end
end

function module.OnLeaveHandler(self, ...)
	local element = self.element
	if element.OnLeave then
		element.OnLeave(self, ...)
	elseif element.OnTooltipShow then
		GameTooltip:Hide()
	end
end

-- ####################################################################################################################
-- ##### Toggle Functions #############################################################################################
-- ####################################################################################################################

function module:IsInfotextEnabled(name)
	return db[name].Enable
end

function module:ShowInfotext(name)
	elementFrames[name]:Show()
	db[name].Enable = true
end

function module:HideInfotext(name)
	elementFrames[name]:Hide()
	db[name].Enable = false
end

function module:ToggleInfotext(name)
	local frame = elementFrames[name]
	if frame:IsShown() then
		frame:Hide()
		db[name].Enable = false
	else
		frame:Show()
		db[name].Enable = true
	end
end

function module:Refresh()
	defaultPositions = 0
	local displayNames = {}
	for name in module:IterateDisplays() do
		displayNames[#displayNames + 1] = name
	end
	table.sort(displayNames)
	for _, name in ipairs(displayNames) do
		local obj = elementFrames[name]
		module:SetPosition(name, obj)
		local color = db[name].Color
		obj.text:SetTextColor(color.r, color.g, color.b, color.a)
		local font = db.Fonts.Infotext
		obj.text:SetFont(Media:Fetch("font", font.Name), font.Size, font.Flag)
		UpdateDisplaySize(obj)
		if obj.element.RefreshSettings then obj.element:RefreshSettings() end
		if db[name].Enable then
			obj:Show()
		else
			obj:Hide()
		end
	end
	if module.RefreshInfotips then module:RefreshInfotips() end
end
