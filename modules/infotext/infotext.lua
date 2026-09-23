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

local QueueDisplaySize
local UpdateDisplay
local pendingDisplaySizes = {}
local DISPLAY_SIZE_RETRY_DELAY = 0.5
local DISPLAY_SIZE_MAX_ATTEMPTS = 10
local pendingSecureRefresh = false

local function DeferSecureDisplay(frame)
	if frame.LUISecureClick and InCombatLockdown() then
		pendingSecureRefresh = true
		return true
	end
	return false
end

local function UpdateDisplaySize(frame)
	local width = frame.text:GetUnboundedStringWidth()
	local _, fontHeight = frame.text:GetFont()
	local text = frame.text:GetText()
	local ready = false
	if not issecretvalue(width) and not issecretvalue(fontHeight) and not issecretvalue(text) then
		ready = type(width) == "number" and width >= 0 and width < math.huge
			and type(fontHeight) == "number" and fontHeight > 0 and fontHeight < math.huge
			and (width > 1 or not text or text == "")
	end
	-- Keep the last valid layout until both font metrics are usable. Retry
	-- independently of LDB text changes, including temporarily secret metrics.
	if not ready then return false end
	local textHeight = math.max(1, math.ceil(fontHeight) + 2)

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

	return true
end

QueueDisplaySize = function(frame)
	if pendingDisplaySizes[frame] then return end
	pendingDisplaySizes[frame] = true
	local attempts = 0
	local function Retry()
		if not module:IsEnabled() or not frame.text then
			pendingDisplaySizes[frame] = nil
			return
		end
		attempts = attempts + 1
		local ok, ready = xpcall(function() return UpdateDisplay(frame, true) end, geterrorhandler())
		if ok and not ready and attempts < DISPLAY_SIZE_MAX_ATTEMPTS then
			C_Timer.After(DISPLAY_SIZE_RETRY_DELAY, Retry)
		else
			pendingDisplaySizes[frame] = nil
		end
	end
	C_Timer.After(DISPLAY_SIZE_RETRY_DELAY, Retry)
end

UpdateDisplay = function(frame, applyFont)
	-- Keep this display's text and protected hit rectangle together in combat.
	-- PLAYER_REGEN_ENABLED applies the latest text/settings, without polling.
	if DeferSecureDisplay(frame) then return true end
	if applyFont then
		local font = db.Fonts.Infotext
		frame.text:SetFont(Media:Fetch("font", font.Name), font.Size, font.Flag)
		if frame.element.RefreshDisplay then frame.element:RefreshDisplay() end
	end
	local text = frame.element.text
	if issecretvalue(text) then return false end
	if not text then text = frame.element.label end
	if issecretvalue(text) then return false end
	frame.text:SetText(text or frame.name)
	local ready = UpdateDisplaySize(frame)
	if not ready then QueueDisplaySize(frame) end
	return ready
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

local displayRefreshQueued = false
local function QueueDisplayRefresh()
	if displayRefreshQueued then return end
	displayRefreshQueued = true
	C_Timer.After(0, function()
		displayRefreshQueued = false
		if module:IsEnabled() then module:RefreshDisplays() end
	end)
end

local function OnDisplayEvent(_, event)
	if event == "PLAYER_REGEN_ENABLED" then
		if not pendingSecureRefresh then return end
		pendingSecureRefresh = false
		if module:IsEnabled() then
			module:RefreshDisplays()
		else
			module:HideSecureDisplays()
		end
	else
		QueueDisplayRefresh()
	end
end

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
	-- World entry can precede the end of the initial loading screen. Reapply
	-- the complete display layout on the next frame after either event.
	topAnchor:RegisterEvent("PLAYER_ENTERING_WORLD")
	topAnchor:RegisterEvent("LOADING_SCREEN_DISABLED")
	topAnchor:RegisterEvent("PLAYER_REGEN_ENABLED")
	topAnchor:SetScript("OnEvent", OnDisplayEvent)

	module:RegisterLDBCallback("LibDataBroker_DataObjectCreated", "LDBDataObjectCreated")

	-- Reconnect broker callbacks, then reconcile the displays in a stable order.
	for name, element in LDB:DataObjectIterator() do
		if elementFrames[name] and elementFrames[name].LUIInitialized then
			module:RegisterLDBCallback("LibDataBroker_AttributeChanged_"..name, "AttributeChanged")
		end
	end
	module:RefreshDisplays()
	QueueDisplayRefresh()
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
	if DeferSecureDisplay(frame) then return end
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

function module:IsSupportedObject(element)
	local kind = element.type
	return not issecretvalue(kind) and supportedTypes[kind] == true
end

local function ApplyDisplaySettings(frame)
	if DeferSecureDisplay(frame) then return end
	if frame.LUISecureClick then
		local target = _G[frame.element.secureClickTarget]
		if target and not target:IsForbidden() then
			frame:SetAttribute("clickbutton", target)
		else
			-- Never fall back to calling ToggleCharacter from insecure Lua.
			frame:SetAttribute("clickbutton", nil)
		end
	end
	local settings = db[frame.name]
	module:SetPosition(frame.name, frame)
	local color = settings.Color
	frame.text:SetTextColor(color.r, color.g, color.b, color.a)
	UpdateDisplay(frame, true)
	if settings.Enable then frame:Show() else frame:Hide() end
end

local function CreateDisplay(name, element)
	if not module:IsSupportedObject(element) then return end
	local frame = elementFrames[name]
	if frame and frame.LUIInitialized then return end
	-- Only explicitly opted-in built-in elements may create a protected display.
	local secureClick = elementStorage[name] == element and element.secureClickTarget
	if secureClick and InCombatLockdown() then
		pendingSecureRefresh = true
		return
	end

	-- Reuse partial frames when settings are refreshed or the module is enabled again.
	if not frame then
		-- A protected child would also protect the shared infotext anchor.
		-- Parent this display to UIParent so all other infotext stays unchanged.
		frame = CreateFrame("Button", GetDisplayFrameName(name),
			secureClick and UIParent or module.topAnchor,
			secureClick and "SecureActionButtonTemplate" or nil)
		if secureClick then
			frame.LUISecureClick = true
			frame:SetFrameStrata(module.topAnchor:GetFrameStrata())
			frame:SetAttribute("type", "click")
			frame:SetAttribute("useOnKeyDown", false)
		end
		frame:SetSize(1, 1)
		elementFrames[name] = frame
	end
	frame.name = name
	frame.element = element

	frame.text = frame.text or module:SetFontString(frame, frame:GetName().."Text", "Infotext", "OVERLAY", "LEFT", "MIDDLE")
	-- Let the text establish its natural width before sizing the button.
	frame.text:ClearAllPoints()
	frame.text:SetPoint("LEFT", frame, "LEFT")
	frame.text:SetWordWrap(false)
	local color = db[name].Color
	frame.text:SetTextColor(color.r, color.g, color.b, color.a)
	frame.text:SetShadowColor(0,0,0)
	frame.text:SetShadowOffset(1.25, -1.25)

	if frame.LUISecureClick then
		frame:RegisterForClicks("AnyUp", "AnyDown")
		-- Preserve SecureActionButtonTemplate's OnClick handler.
	else
		frame:RegisterForClicks("AnyUp")
		frame:SetScript("OnClick", module.OnClickHandler)
	end
	frame:SetScript("OnEnter", module.OnEnterHandler)
	frame:SetScript("OnLeave", module.OnLeaveHandler)

	--Do some element based stuff here
	if not frame.LUIOnCreateComplete then
		if elementStorage[name] then LUI:EmbedModule(element) end
		if element.OnCreate then element:OnCreate(frame) end
		frame.LUIOnCreateComplete = true
	end

	ApplyDisplaySettings(frame)

	--This allow me to unregister callbacks based on element instead of filtering using the global one.
	module:RegisterLDBCallback("LibDataBroker_AttributeChanged_"..name, "AttributeChanged")
	frame.LUIInitialized = true
end

local function RunDisplayOperation(name, operation)
	-- Keep the original error visible to WoW/BugGrabber without aborting other displays.
	local ok = xpcall(operation, geterrorhandler())
	if not ok then
		local frame = elementFrames[name]
		if frame and not frame.LUIInitialized and not DeferSecureDisplay(frame) then frame:Hide() end
	end
	return ok
end

-- This is used on the creation of any LDB object.
function module:DataObjectCreated(name, element)
	return RunDisplayOperation(name, function() CreateDisplay(name, element) end)
end

function module:LDBDataObjectCreated(_, name, element)
	self:DataObjectCreated(name, element)
end

function module:AttributeChanged(event_, name, attr, value, element_)
	local frame = elementFrames[name]
	if frame and (attr == "text" or attr == "label") then
		UpdateDisplay(frame)
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
	db[name].Enable = true
	local frame = elementFrames[name]
	if frame and not DeferSecureDisplay(frame) then frame:Show() end
end

function module:HideInfotext(name)
	db[name].Enable = false
	local frame = elementFrames[name]
	if frame and not DeferSecureDisplay(frame) then frame:Hide() end
end

function module:ToggleInfotext(name)
	local frame = elementFrames[name]
	if not frame then
		db[name].Enable = not db[name].Enable
		return
	end
	if frame.LUISecureClick then
		-- A second toggle during combat must cancel the queued first toggle.
		if db[name].Enable then module:HideInfotext(name) else module:ShowInfotext(name) end
		return
	end
	if frame:IsShown() then
		frame:Hide()
		db[name].Enable = false
	else
		frame:Show()
		db[name].Enable = true
	end
end

function module:HideSecureDisplays()
	for _, frame in pairs(elementFrames) do
		if frame.LUISecureClick and not DeferSecureDisplay(frame) then frame:Hide() end
	end
end

function module:RefreshDisplays(refreshElements)
	db = module.db.profile
	defaultPositions = 0
	local displayNames = {}
	for name, element in LDB:DataObjectIterator() do
		if module:IsSupportedObject(element) then displayNames[#displayNames + 1] = name end
	end
	table.sort(displayNames)
	for _, name in ipairs(displayNames) do
		local obj = elementFrames[name]
		if not obj or not obj.LUIInitialized then
			module:DataObjectCreated(name, LDB:GetDataObjectByName(name))
		else
			RunDisplayOperation(name, function()
				ApplyDisplaySettings(obj)
			end)
			if refreshElements and obj.element.RefreshSettings then
				RunDisplayOperation(name, function() obj.element:RefreshSettings() end)
			end
		end
	end
end

function module:Refresh()
	module:RefreshDisplays(true)
	if module.RefreshInfotips then module:RefreshInfotips() end
end
