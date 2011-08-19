--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: infotext.lua
	Description: Provides LUI infotext panels and stat building api.
]]


--[[
NOTES:
	This is obviously still underconstruction. I just wanted to commit it so we can discuss ideas,
	and generally improve the modular nature of the infotext modules. And also to have it backed up. :>

	You'll notice several Debate: comments throughout the code, feel free to comment in your opinions,
	or forward them on the dev forums.

	-- Tasks
	Last: Updating stat api for LDB use.
	Next: Create options and option wrappers for stats.
	Future: Upgrading stats for new infotext.
]]

-- External references.
local addonname, LUI = ...
local InfoText = LUI:Module("InfoText", "AceHook-3.0")
local LDB = LibStub:GetLibrary("LibDataBroker-1.1")

-- Database and defaults shortcuts.
local db, dbd

-- Local variables.
InfoText.Panels = {}
InfoText.Stats = {}
InfoText.LDB = {}

------------------------------------------------------
-- / LOCALISED FUNCTIONS / --
------------------------------------------------------

local CreateFrame, InCombatLockdown, strfind, strupper = CreateFrame, InCombatLockdown, strfind, strupper

------------------------------------------------------
-- / STAT API / --
------------------------------------------------------

-- Metatables.
InfoText.StatMetatable = {
	__index = function(self, k)
		return self.__LDB[k]
	end,
	__newindex = function(self, k, v)
		if self.__LDB[k] ~= nil then
			self.__LDB[k] = v
		end
	end,
}

-- Creation functions.
function InfoText:CreateStat(stat)
	-- Check stat exists.
	if not stat then return end

	-- Check if stat has already been created.
	if stat.__LDB then return end

	-- Check if stat is enabled.
	if not stat.db[stat.name].Enabled then end

	-- Create LDB object.
	stat.__LDB = LDB:NewDataObject("LUI_Stat_"..stat.name, {type = "data source", text = stat.name, icon = false})

	-- Create usable frame.
	stat.stat = CreateFrame("Frame", "LUI_Stat_"..stat.name)
	
	-- Setup metatable links.
	stat = setmetatable(stat, InfoText.StatMetatable)

	local mt = getmetatable(stat.stat)
	stat.stat = setmetatable(stat.stat, {
		__index = function(self, k)
			if stat[k] then
				return stat[k]
			else
				return mt[k]
			end
		end,
		__newindex = function(self, k, v)
			if stat[k] ~= nil then
				stat[k] = v
			end
		end,
	}

	-- Call stat's OnCreate function.
	stat:OnCreate()

	-- Set stat's Enable function.
	stat.Enable = InfoText.StatOnEnable
end

function InfoText:EnableStat(stat)
	-- Check stat has been created.
	self:CreateStat(stat)

	-- Enable stat.
	stat:Enable()

	-- Check if stat is being displayed by panels.
	if db.UseDisplay and self.LDB[stat.name] then
		self.LDB[stat.name]:Show()
	end
end
	
function InfoText:DisableStat(stat)
	-- Check stat has been created.
	if not stat or not stat.stat then return end

	-- Hide stat to disable scripts.
	stat.stat:Hide()

	-- Stop event handler.
	stat.stat:SetScript("OnEvent", nil)

	-- Set LDB info.
	stat.__LDB.icon = false
	stat.__LDB.text = ""

	-- Check if stat is being displayed by panels.
	if self.LDB[stat.name] then
		self.LDB[stat.name]:Hide()
	end
end

function InfoText:NewStat(name)
	-- Check if stat table already exists.
	if self.Stats[name] then return self.Stats[name] end

	-- Create new stat table.
	self.Stats[name] = {
		name = name,
	}

	return self.Stats[name]	
end

function InfoText:StatOnEnable()
	-- Shortcuts.
	local f = self.stat
	local ldb = self.__LDB

	-- Update LDB fields.
	InfoText:UpdateLDBFields(stat)

	-- Register assigned events and handlers.
	if f.Events then
		for i = 1, #f.Events do
			f:RegisterEvent(f.Events[i])
		end
		f:SetScript("OnEvent", f.OnEvent or function(self, event, ...) self[event](self, ...) end)
	end

	-- Register LDB OnClick script.
	if f.OnClick then
		ldb.OnClick = function(self, button)
			f:OnClick(button)
		end
	end

	-- Register LDB tooltip scripts.
	ldb.OnEnter = f.OnEnter
	ldb.OnLeave = f.OnLeave
	ldb.OnTooltipShow = f.OnTooltipShow
	ldb.tooltip = f.tooltip

	-- Register OnUpdate script. (Debate: I'm not force running the OnUpdate script; stats should be in an initial state where they can wait until the first update interval. Be it just setting an initial text state [which is done my default].)
	if f.OnUpdate then
		f.dt = 0
		f:SetScript("OnUpdate", f.OnUpdate)
	end

	-- Call stat's OnEnable function.
	if f.OnEnable then f.OnEnable() end

	-- Show stat.
	f:Show()
end

-- Accessor functions.
function InfoText:UpdateLDBFields(stat)
	local ldb = stat.__LDB
	ldb.infoPanel = stat.db[stat.name].InfoPanel.Panel
	ldb.infoPanelX = stat.db[stat.name].InfoPanel.X
	ldb.infoPanelY = stat.db[stat.name].InfoPanel.Y
end


------------------------------------------------------
-- / PANEL & LDB FUNCTIONS / --
------------------------------------------------------

-- Panel functions.
function InfoText:CreateInfoPanels()
	local function CreatePanel(name, x, y)
		local uname = strupper(name)
		return LUI:CreateMeAFrame("Frame", "LUI_InfoPanel_"..name, UIParent, 1, 1, 1, "HIGH", 0, uname, UIParent, uname, x, y, 1)
	end

	-- Create the info panels.
	local panel = "BottomLeft"
	InfoText.Panels[panel] = InfoText.Panels[panel] or CreatePanel(panel, 0, 4)
	InfoText.Panels[panel]:Show()

	panel = "BottomRight"
	InfoText.Panels[panel] = InfoText.Panels[panel] or CreatePanel(panel, 0, 4)
	InfoText.Panels[panel]:Show()

	panel = "TopLeft"
	InfoText.Panels[panel] = InfoText.Panels[panel] or CreatePanel(panel, 0, -1)
	InfoText.Panels[panel]:Show()

	panel = "TopRight"
	InfoText.Panels[panel] = InfoText.Panels[panel] or CreatePanel(panel, 0, -1)
	InfoText.Panels[panel]:Show()

	-- Register LDB support.
	LDB.RegisterCallback(self, "LibDataBroker_DataObjectCreated", nil, self)
	LDB.RegisterCallback(self, "LibDataBroker_AttributeChanged__icon", nil, self)
	LDB.RegisterCallback(self, "LibDataBroker_AttributeChanged__infoPanel", nil, self)
	LDB.RegisterCallback(self, "LibDataBroker_AttributeChanged__infoPanelX", nil, self)
	LDB.RegisterCallback(self, "LibDataBroker_AttributeChanged__infoPanelY", nil, self)
	LDB.RegisterCallback(self, "LibDataBroker_AttributeChanged__text", nil, self)
end

function InfoText:HideInfoPanels()
	-- Hide infopanels.
	for n, panel in pairs(self.Panels) do
		panel:Hide()
	end

	-- Hide LDB frames to stop scripts.
	for n, ldb in paris(self.LDB) do
		ldb:Hide()
	end

	-- Unregister LDB support.
	LDB.UnregisterCallback(self, "LibDataBroker_DataObjectCreated")
	LDB.UnregisterCallback(self, "LibDataBroker_AttributeChanged__icon")
	LDB.UnregisterCallback(self, "LibDataBroker_AttributeChanged__infoPanel")
	LDB.UnregisterCallback(self, "LibDataBroker_AttributeChanged__infoPanelX")
	LDB.UnregisterCallback(self, "LibDataBroker_AttributeChanged__infoPanelY")
	LDB.UnregisterCallback(self, "LibDataBroker_AttributeChanged__text")
end

-- Accessor functions.
function InfoText:LDBSetInfoPanel(name, panel, x, y)
	-- Check for dataobject.
	local object = self.LDB[name]
	if not object then return end

	-- Set object fields.
	object.dataobject.infoPanel = panel or object.dataobject.infoPanel
	object.dataobject.infoPanelX = x or object.dataobject.infoPanelX
	object.dataobject.infoPanelY = y or object.dataobject.infoPanelY
end

-- Tooltip functions.
function InfoText:IsTooltipLocked()
	return InCombatLockdown() and db.CombatLock
end

function InfoText:LDBEnterTooltip()
	-- Embeded functionality.

	-- Check if tooltip is available.
	if InfoText:IsTooltipLocked() then return end

	if self.dataobject.tooltip then
		local f = self.dataobject.tooltip

		-- Position custom tooltip.
		local anchor = (strfind(self.dataobject.infoPanel, "Top") and "BOTTOM") or "TOP"
		f:ClearAllPoints()
		f:SetPoint((anchor == "TOP" and "BOTTOM") or "TOP", self, anchor)

		-- Show custom tooltip.
		f:Show()
	elseif self.dataobject.OnEnter then
		-- Call dataobject's OnEnter.
		self.dataobject.OnEnter(self)
	elseif self.dataobject.OnTooltipShow then
		-- Position game tooltip.
		local anchor =  (strfind(self.dataobject.infoPanel, "Top") and "ANCHOR_BOTTOM") or "ANCHOR_TOP"
		GameTooltip:SetOwner(self, anchor)
		GameTooltip:ClearLines()

		-- Populate tooltip.
		InfoText:TooltipHeader(self.dataobject.label or self.name)
		self.dataobject.OnTooltipShow(GameToolTip)

		-- Show game tooltip.
		GameTooltip:Show()
	end
end

function InfoText:LDBLeaveTooltip()
	-- Embeded functionality.
	if self.dataobject.tooltip then
		-- Hide custom tooltip.
		self.dataobject.tooltip:Hide()
	elseif self.dataobject.OnLeave then
		-- Call dataobject's OnLeave.
		self.dataobject:OnLeave()
	elseif self.dataobject.OnTooltipShow then
		-- Hide game tooltip.
		GameTooltip:Hide()
	end
end

function InfoText:TooltipHeader(name)
	-- Add tooltip header.
	GameTooltip:AddLine(name, 0.4, 0.78, 1)
	GameTooltip:AddLine(" ")
end

-- LDB callback functions.
--[[
	TODO:
		- On dataobject creation, imbeded panel position options into the infotext options.
		- Make stats moveable around panels via dragging; maybe ctrl+left mouse drag.
]]
local lastX = -15
function InfoText:LibDataBroker_DataObjectCreated(_, name, dataobject)
	-- Check if dataobject is already registered.
	if self.LDB[name] then
		-- Update dataobject reference.
		self.LDB[name].dataobject = dataobject
		self.LDB[name].text:SetText(dataobject.text)
		return
	end

	-- Create dataobject LUI fields.
	dataobject.infoPanel = dataobject.infoPanel or "BottomRight"
	dataobject.infoPanelX = dataobject.infoPanelX or lastX
	dataobject.infoPanelY = dataobject infoPanelY or 0
	dataobject.text = (dataobject.text ~= "" and dataobject.text) or dataobject.label or name
	
	local panel, anchor = self.Panels[dataobject.infoPanel], strupper(dataobject.infoPanel)

	-- Create frame for new dataobject.
	self.LDB[name] = CreateFrame("Frame", "LUI_LDB_"..name,  panel)

	-- Create reference for frame to dataobject.
	self.LDB[name].dataobject = dataobject
	self.LDB[name].name = name

	-- Create object's text.
	local object = self.LDB[name]
	object.text = object:CreateFontString(object:GetName()..": Text", "OVERLAY")
	object.text:SetJustifyH("LEFT")
	object.text:SetShadowColor(0, 0, 0)
	object.text:SetShadowOffset(1.24, -1.24)
	object.text:Show()

	-- Create object's icon.
	if dataobject.icon then
		self:LibDataBroker_AttributeChanged__icon(_, name)
	end

	-- Set LDB panel position.
	self:LDBSetInfoPanel(name)
	if dataobject.infoPanelX == lastX then
		lastX = object.text:GetLeft() - 90
	end

	-- Set LDB scripts.
	object:EnableMouse(true)
	object:SetScript("OnEnter", InfoText.LDBEnterTooltip)
	object:SetScript("OnLeave", InfoText.LDBLeaveTooltip)
	object:SetScript("OnMouseUp", dataobject.OnClick or nil)

	-- Force a text and panel position update.
	self:LibDataBroker_AttributeChanged__infoPanel(_, name)
	self:LibDataBroker_AttributeChanged__text(_, name)
end

function InfoText:LibDataBroker_AttributeChanged__icon(_, name)
	-- Check dataobject exists.
	local object = self.LDB[name]
	if not object then return end

	-- Check dataobjects icon has been created.
	if not object.icon then
		-- Check new icon is needed.
		if not object.dataobject.icon then return end

		-- Create icon.
		object.icon = CreateFrame("Button", object:GetName()..": Icon", object)
		object.icon:SetPoint("RIGHT", object.text, "LEFT", -2, 0)
		object.icon:SetWidth(15)
		object.icon:SetHeight(15)
	end

	-- Check if icon has been removed.
	if not object.dataobject.icon then
		object.icon:Hide()
		return
	end

	-- Update dataobjects icon.
	object.icon:SetBackdrop({
			bgFile = object.dataobject.icon,
			edgeFile = nil,
			title = false,
			edgeSize = 0,
			insets = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0,
			},
		})
	object.icon:Show()
end

function InfoText:LibDataBroker_AttributeChanged__infoPanel(_, name)
	-- Check dataobject exists.
	local object = self.LDB[name]
	if not object then return end

	-- Update dataobjects panel position.
	local anchor, panel = strupper(object.dataobject.infoPanel), self.Panels[object.dataobject.infoPanel]

	-- Set text position.
	object.text:ClearAllPoints()
	object.text:SetPoint(anchor, panel, anchor, object.dataobject.infoPanelX, object.dataobject.infoPanelY)

	-- Set LDB's parent and position.
	object:SetParent(object.dataobject.infoPanel)
	object:ClearAllPoints()
	object:SetAllPoints(object.text)	
end

InfoText.LibDataBroker_AttributeChanged__infoPanelX = InfoText.LibDataBroker_AttributeChanged__infoPanel
InfoText.LibDataBroker_AttributeChanged__infoPanelY = InfoText.LibDataBroker_AttributeChanged__infoPanel

function InfoText:LibDataBroker_AttributeChanged__text(_, name)
	-- Check dataobject exists.
	local object = self.LDB[name]
	if not object then return end

	-- Update dataobjects text.
	object.text:SetText(object.dataobject.text)
end


------------------------------------------------------
-- / MODULE FUNCTIONS / --
------------------------------------------------------

InfoText.defaults = {
	profile = {
		Enable = true,
		CombatLock = false,
		UseDisplay = true,
	},
}

function InfoText:OnEnable()
	if db.UseDisplay then
		-- Create info panels.
		self:CreateInfoPanels()
	else
		-- Hide info panels.
		self:HideInfoPanels()
	end

	-- Create stats.
	for name, stat in pairs(self.Stats) do
		self:CreateStat(stat)

		-- Enable stat.
		stat:Enable()
	end
end

function InfoText:OnDisable()
	-- Hide info panels.
	self:HideInfoPanels()

	-- Disable all stats.
	for name, stat in pairs(self.Stats) do
		self:DisableStat(stat)
	end
end

function InfoText:OnInitialize()
	--[[
	-- Run through registered stats and merge defaults database into self.defaults

	for name, statTable in pairs(self.Stats) do
		if statTable.defaults then
			self.defaults = MergeDefaults(self.defaults, { profile = { [name] = statTable.defaults, }, })
		end
	end
	]]

	-- Create database namespace.
	db, dbd = LUI:NewNamespace(self, true)

	--[[
	-- Run through resgistered stats linking database references and calling OnInitialize().

	for name, statTable in pairs(self.Stats) do
		statTable.db, statTable.defaults = db, dbd
		if statTable.OnInitialize then statTable:OnInitialize() end
	end
	]]
end