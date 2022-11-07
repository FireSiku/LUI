-- This module handle various Infotext by LUI or other addons.
-- It's job is to provide a LDB Display for any addon that wishes to have one and our own displays too.
-- This module also serves as both an access to LDB and access to Ace features for its elements.

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, LUIAddon
local _, LUI = ...
local L = LUI.L

---@type InfotextModule
local module = LUI:GetModule("Infotext")

local LDB = LibStub:GetLibrary("LibDataBroker-1.1")
module.RegisterLDBCallback = LDB.RegisterCallback
module.LDB = LDB
local db

local select, pairs = select, pairs

-- constants
local INFOPANEL_TEXTURE = "Interface\\AddOns\\LUI\\media\\textures\\infopanel"

-- local variables
local elementFrames = {} -- Holds all the LDB frames.
local elementStorage = {} -- Will hold the infotext's elements for iteration.
local InfoMixin = {} -- Prototype for element functions.

--TODO: Improve Support
--Unsupported data fields: value, suffix, label, icon, tooltip
local supportedTypes = {
	["data source"] = true,
	["launcher"] = true,
}

--[[ Infotext left:
function module:SetDualSpec()  -- Need Icon setup
function module:SetGuild()     -- Need Clickable Tootlips (Infotip)
function module:SetFriends()   -- Need Clickable Tooltips (Infotip)
--]]

local defaultPositions = 0

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
	--TODO: Change anchor to support more choices later on.
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

function module:GetAnchor(position)
	return _G[format("LUIInfotext_%sAnchor", position:lower())]
end

function module:SetInfoPanels()
	db = module.db.profile

	local topAnchor = module:GetAnchor("top")
	local bottomAnchor = module:GetAnchor("bottom")
	if not topAnchor then
		topAnchor = CreateFrame("Frame", "LUIInfotext_topAnchor", UIParent)
		topAnchor:SetSize(1, 1)
		topAnchor:SetFrameStrata("HIGH")
		topAnchor:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, -1)

		local topPanelTex = CreateFrame("Frame", "LUIInfotext_topPanel", topAnchor, "BackdropTemplate")
		topPanelTex:SetSize(32, 32)
		topPanelTex:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 8)
		topPanelTex:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 8)
		topPanelTex:SetFrameStrata("BACKGROUND")
		topPanelTex:SetBackdrop({
			bgFile = INFOPANEL_TEXTURE,
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			edgeSize = 1,
			insets = {left = 0, right = 0, top = 0, bottom = 0}
		})
		topPanelTex:SetBackdropColor(module:RGBA("Panels"))
		topPanelTex:SetBackdropBorderColor(0, 0, 0, 0)
		topPanelTex:Show()
	end
	if not bottomAnchor then
		bottomAnchor = CreateFrame("FRAME", "LUIInfotext_bottomAnchor", UIParent)
		bottomAnchor:SetSize(1, 1)
		bottomAnchor:SetFrameStrata("HIGH")
		bottomAnchor:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 4)
	end
	topAnchor:Show()
	bottomAnchor:Show()
	module.topAnchor = topAnchor
	module.bottomAnchor = bottomAnchor

	-- Make sure all objects created before the callback gets properly initialized.
	for name, element in LDB:DataObjectIterator() do
		if not elementFrames[name] then
			self:DataObjectCreated(name, element)
		end
	end

	module:RegisterLDBCallback("LibDataBroker_DataObjectCreated", "DataObjectCreated")
end

-- TODO: Change elemnent style to be more akin to data providers? (which is what they are)
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

--Override the module iterator
function module:IterateModules()
	return pairs(elementFrames)
end

function module:IsPositionSet(name)
	return (db[name].X ~= 0) and true or false
end

function module:SetPosition(name, frame)
	if module:IsPositionSet(name) then
		frame.text:SetPoint(db[name].Point, UIParent, db[name].Point, db[name].X, db[name].Y)
	else
		local anchor = module:GetAnchor("bottom")
		defaultPositions = defaultPositions + 1
		local defaultX = -25 + (50 * defaultPositions)
		frame.text:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", defaultX, 5)
	end
end
-- ####################################################################################################################
-- ##### LDB Handling #################################################################################################
-- ####################################################################################################################

--This is used on the creation of any LDB Object
function module:DataObjectCreated(name, element)
	--LUI:Print("Object Created:", name, "("..element.type..")",not supportedTypes[element.type] and "(unsupported)" or "")
	if not supportedTypes[element.type] then return end

	local topAnchor = module:GetAnchor("top")
	local frame = CreateFrame("Button", "LUIInfo_"..name, topAnchor)
	elementFrames[name] = frame
	frame.name = name
	frame.element = element

	frame.text = module:SetFontString(frame, frame:GetName().."Text", "Infotext", "OVERLAY", "LEFT")
	frame.text:SetTextColor(1,1,1)
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
	-- module:SetLDBPosition(name, frame)

	frame:SetAllPoints(frame.text)

	frame.text:SetText(element.text)
	if db[name].Enable then
		frame:Show()
	else
		frame:Hide()
	end

	--This allow me to unregister callbacks based on element instead of filtering using the global one.
	module:RegisterLDBCallback("LibDataBroker_AttributeChanged_"..name, "AttributeChanged")
end

function module:AttributeChanged(event_, name, attr, value, element_)
	local frame = elementFrames[name]
	if attr == "text" then
		frame.text:SetText(value)
	end
	--if not ph[name] then LUI:Print("Attribute Changed:", name, attr, "("..value..")") end
end

-- ####################################################################################################################
-- ##### LDB: Event Handlers ##########################################################################################
-- ####################################################################################################################

function module.OnClickHandler(self, ...)
	local element = self.element
	if element.OnClick then element.OnClick(self, ...) end
end

function module.OnEnterHandler(self, ...)
	--TODO: Have a way to not show them in combat.
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
    for name, obj in module:IterateModules() do
        module:SetPosition(name, obj)
        if db[name].Enable then
            obj:Show()
        else
            obj:Hide()
        end
    end
end
