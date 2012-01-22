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
	Future: Upgrading stats for new infotext.
			Add label to LDB's to save string.formats; lots of string memory going to be used because of the way LDB's work.
	TODO:
		- Make stats moveable around panels via dragging; maybe ctrl+left mouse drag.

]]


-- External references.
local addonname, LUI = ...
local LDB = LibStub:GetLibrary("LibDataBroker-1.1")
local Media = LibStub("LibSharedMedia-3.0")
local module = LUI:Module("InfoText")

-- Database and defaults shortcuts.
local db, dbd

-- Local variables.
module.Panels = {}
module.Stats = {}
module.LDB = {}

------------------------------------------------------
-- / LOCALISED FUNCTIONS / --
------------------------------------------------------

local CreateFrame, InCombatLockdown, strfind, strupper = CreateFrame, InCombatLockdown, strfind, strupper

------------------------------------------------------
-- / STAT API / --
------------------------------------------------------

-- Creation functions.
function module:CreateStat(stat)
	-- Check stat exists.
	if not stat then return end

	-- Check if stat has already been created.
	if stat.__LDB then return end

	-- Check if stat is enabled.
	if not stat.db.profile.Enable then return end

	-- Create LDB object.
	stat.__LDB = LDB:NewDataObject("LUI_Stat_"..stat.name, {
		icon = false,
		infoPanel = stat.db.profile.InfoPanel.InfoPanel,
		infoPanelX = stat.db.profile.InfoPanel.X,
		infoPanelY = stat.db.profile.InfoPanel.Y,
		label = "LUI: "..stat.name,
		text = stat.name,
		type = "data source",
	})

	-- Create usable frame.
	stat.stat = CreateFrame("Frame", "LUI_Stat_"..stat.name)
	
	-- Setup LDB links.
	stat.stat.__LDB = stat.__LDB
	stat.stat.Text = function(self, text)
		self.__LDB.text = text
	end

	-- Call stat's OnCreate function.
	stat:OnCreate()

	-- Set stat's Enable function.
	stat.Enable = module.StatOnEnable
end

function module:DisableStat(stat)
	-- Check stat has been created.
	if not stat or not stat.stat then return end

	-- Hide stat to disable scripts.
	stat.stat:Hide()

	-- Stop event handlers.
	stat.stat:SetScript("OnEvent", nil)
	stat.stat:SetScript("OnUpdate", nil)

	-- Set LDB info.
	stat.__LDB.icon = false
	stat.__LDB.text = ""

	-- Check if stat is being displayed by panels.
	if self.LDB[stat.name] then
		self.LDB[stat.name]:Hide()
	end
end

function module:NewStat(name)
	-- Check if stat table already exists.
	if self.Stats[name] then return self.Stats[name] end

	-- Create new stat table.
	self.Stats[name] = {
		name = name,
	}

	return self.Stats[name]	
end

function module:StatOnEnable()
	-- Embeded functionality.

	-- Shortcuts.
	local stat = self.stat
	local ldb = self.__LDB

	-- Register assigned events and handlers.
	if stat.Events then
		stat:SetScript("OnEvent", stat.OnEvent or function(self, event, ...) self[event](self, ...) end)

		for i = 1, #stat.Events do
			stat:RegisterEvent(stat.Events[i])
		end
	end

	-- Register LDB scripts.
	ldb.OnClick = stat.OnClick
	ldb.OnEnter = stat.OnEnter
	ldb.OnLeave = stat.OnLeave
	ldb.OnTooltipShow = function(tooltip, LUI)
		if not LUI then
			-- Add stat header when using third-party LDB display.
			tooltip:AddLine(ldb.label, 0.4, 0.78, 1)
			tooltip:AddLine(" ")
		end

		stat.OnTooltipShow(tooltip)
	end
	ldb.tooltip = stat.tooltip

	-- Register OnUpdate script. (Debate: I'm not force running the OnUpdate script; stats should be in an initial state where they can wait until the first update interval. Be it just setting an initial text state [which is done my default].)
	if stat.OnUpdate then
		stat.dt = 0
		stat:SetScript("OnUpdate", stat.OnUpdate)
	end

	-- Call stat's OnEnable function.
	if stat.OnEnable then stat:OnEnable() end

	-- Show stat.
	stat:Show()
end

-- Accessor functions.
function module:UpdateLDBFields(stat)
	local ldb, db = stat.__LDB, stat.db.profile.InfoPanel
	ldb.infoPanel = db.InfoPanel
	ldb.infoPanelX = db.X
	ldb.infoPanelY = db.Y
end


------------------------------------------------------
-- / PANEL & LDB FUNCTIONS / --
------------------------------------------------------

-- Panel functions.
function module:CreateInfoPanels()
	local function CreatePanel(name, x, y)
		local uname = strupper(name)
		return LUI:CreateMeAFrame("Frame", "LUI_InfoPanel_"..name, UIParent, 1, 1, 1, "HIGH", 0, uname, UIParent, uname, x, y, 1)
	end

	-- Create the info panels.
	local panel = "BottomLeft"
	module.Panels[panel] = module.Panels[panel] or CreatePanel(panel, 0, 4)
	module.Panels[panel]:Show()

	panel = "BottomRight"
	module.Panels[panel] = module.Panels[panel] or CreatePanel(panel, 0, 4)
	module.Panels[panel]:Show()

	panel = "TopLeft"
	module.Panels[panel] = module.Panels[panel] or CreatePanel(panel, 0, -1)
	module.Panels[panel]:Show()

	panel = "TopRight"
	module.Panels[panel] = module.Panels[panel] or CreatePanel(panel, 0, -1)
	module.Panels[panel]:Show()

	-- Register LDB support.
	LDB.RegisterCallback(self, "LibDataBroker_DataObjectCreated", nil, self)
	LDB.RegisterCallback(self, "LibDataBroker_AttributeChanged__icon", nil, self)
	LDB.RegisterCallback(self, "LibDataBroker_AttributeChanged__infoPanel", nil, self)
	LDB.RegisterCallback(self, "LibDataBroker_AttributeChanged__infoPanelX", nil, self)
	LDB.RegisterCallback(self, "LibDataBroker_AttributeChanged__infoPanelY", nil, self)
	LDB.RegisterCallback(self, "LibDataBroker_AttributeChanged__text", nil, self)

	for name, ldb in pairs(self.LDB) do
		if strfind(name, "LUI_Stat") or db.General.NonLUIStats then
			ldb:Show()
		else
			ldb:Hide()
		end
	end

	-- Check for LDB's that were created before the addon.
	if not db.General.NonLUIStats then return end

	for name, dataobject in LDB:DataObjectIterator() do
		self:LibDataBroker_DataObjectCreated(_,_, name, dataobject)
	end
end

function module:HideInfoPanels()
	-- Hide infopanels.
	for n, panel in pairs(self.Panels) do
		panel:Hide()
	end

	-- Hide LDB frames to stop scripts.
	for n, ldb in pairs(self.LDB) do
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
function module:LDBSetInfoPanel(name, panel, x, y)
	-- Check for dataobject.
	local object = self.LDB[name]
	if not object then return end

	-- Set object fields.
	object.dataobject.infoPanel = panel or object.dataobject.infoPanel
	object.dataobject.infoPanelX = x or object.dataobject.infoPanelX
	object.dataobject.infoPanelY = y or object.dataobject.infoPanelY
end

-- Tooltip functions.
function module:IsTooltipLocked()
	return db.General.CombatLock and InCombatLockdown()
end

function module:LDBEnterTooltip()
	-- Embeded functionality.

	-- Check if tooltip is available.
	if module:IsTooltipLocked() then return end

	if self.dataobject.tooltip then
		local tooltip = self.dataobject.tooltip

		-- Position custom tooltip.
		local anchor = (strfind(self.dataobject.infoPanel, "Top") and "BOTTOM") or "TOP"
		tooltip:ClearAllPoints()
		tooltip:SetPoint((anchor == "TOP" and "BOTTOM") or "TOP", self, anchor)

		-- Show custom tooltip.
		tooltip:Show()
	elseif self.dataobject.OnEnter then
		-- Call dataobject's OnEnter.
		self.dataobject.OnEnter(self)
	elseif self.dataobject.OnTooltipShow then
		-- Position game tooltip.
		local anchor =  (strfind(self.dataobject.infoPanel, "Top") and "ANCHOR_BOTTOM") or "ANCHOR_TOP"
		GameTooltip:SetOwner(self, anchor)
		GameTooltip:ClearLines()

		-- Populate tooltip.
		module:TooltipHeader(self.dataobject.label or self.name)
		self.dataobject.OnTooltipShow(GameTooltip, true)

		-- Show game tooltip.
		GameTooltip:Show()
	end
end

function module:LDBLeaveTooltip()
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

function module:TooltipHeader(name)
	-- Add tooltip header.
	GameTooltip:AddLine(name, 0.4, 0.78, 1)
	GameTooltip:AddLine(" ")
end

-- LDB callback functions.
function module:LibDataBroker_DataObjectCreated(_,_, name, dataobject)
	-- Check if dataobject exists.
	if not dataobject then return end

	-- Check if dataobject is already registered.
	if self.LDB[name] then
		-- Update dataobject reference.
		self.LDB[name].dataobject = dataobject

		-- Check if LUI is displaying non LUI stats.
		if not db.General.NonLUIStats then 
			return self.LDB[name]:Hide()
		end

		self:LibDataBroker_AttributeChanged__icon(_,_, name)
		self:LibDataBroker_AttributeChanged__infoPanel(_,_, name)
		self:LibDataBroker_AttributeChanged__text(_,_, name)
		return self.LDB[name]:Show()
	end

	-- Create LDB database.	
	if not strfind(name, "LUI_Stat") then
		-- Check if LUI is displaying non LUI stats.
		if not db.General.NonLUIStats then return end

		if not db.LDB[name] then
			-- Create new database entry.
			db.LDB[name] = {
				Enable = true,
				InfoPanel = {
					InfoPanel = "BottomRight",
					X = -90,
					Y = 0,
				},
			}
		end

		-- Check if dataobject is disabled.
		if not db.LDB[name].Enable then return end

		-- Update dataobject LUI fields.
		local db = db.LDB[name].InfoPanel
		dataobject.infoPanel = dataobject.infoPanel or db.InfoPanel
		dataobject.infoPanelX = dataobject.infoPanelX or db.X
		dataobject.infoPanelY = dataobject.infoPanelY or db.Y
	end

	-- Create dataobject LUI fields.
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
	object.text:SetFont(Media:Fetch("font", db.General.Font.Font), db.General.Font.Size, db.General.Font.Flag)
	object.text:SetJustifyH("LEFT")
	object.text:SetShadowColor(0, 0, 0)
	object.text:SetShadowOffset(1.24, -1.24)
	object.text:SetTextColor(db.General.Font.Color.r, db.General.Font.Color.g, db.General.Font.Color.b, db.General.Font.Color.a)
	object.text:Show()

	-- Create object's icon.
	if dataobject.icon then
		self:LibDataBroker_AttributeChanged__icon(_,_, name)
	end

	-- Set LDB scripts.
	object:EnableMouse(true)
	object:SetScript("OnEnter", module.LDBEnterTooltip)
	object:SetScript("OnLeave", module.LDBLeaveTooltip)
	object:SetScript("OnMouseUp", function(self, button) self.dataobject:OnClick(button) end)

	-- Force a text and panel position update.
	self:LibDataBroker_AttributeChanged__infoPanel(_,_, name)
	self:LibDataBroker_AttributeChanged__text(_,_, name)
end

function module:LibDataBroker_AttributeChanged__icon(_,_, name)
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
		return object.icon:Hide()
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

function module:LibDataBroker_AttributeChanged__infoPanel(_,_, name)
	-- Check dataobject exists.
	local object = self.LDB[name]
	if not object then return end

	-- Update LDB database.
	if not strfind(name, "LUI_Stat") then
		local db = db.LDB[name].InfoPanel
		db.InfoPanel = object.dataobject.infoPanel
		db.X = object.dataobject.infoPanelX
		db.Y = object.dataobject.infoPanelY
	end

	-- Update dataobjects panel position.
	local anchor, panel = strupper(object.dataobject.infoPanel), self.Panels[object.dataobject.infoPanel]

	-- Set text position.
	object.text:ClearAllPoints()
	object.text:SetPoint(anchor, panel, anchor, object.dataobject.infoPanelX, object.dataobject.infoPanelY)

	-- Set LDB's parent and position.
	object:SetParent(self.Panels[object.dataobject.infoPanel])
	object:ClearAllPoints()
	object:SetAllPoints(object.text)	
end

module.LibDataBroker_AttributeChanged__infoPanelX = module.LibDataBroker_AttributeChanged__infoPanel
module.LibDataBroker_AttributeChanged__infoPanelY = module.LibDataBroker_AttributeChanged__infoPanel

function module:LibDataBroker_AttributeChanged__text(_,_, name)
	-- Check dataobject exists.
	local object = self.LDB[name]
	if not object then return end

	-- Update dataobjects text.
	object.text:SetText(object.dataobject.text)
end


------------------------------------------------------
-- / MODULE FUNCTIONS / --
------------------------------------------------------

module.defaults = {
	profile = {
		General = {
			Enable = true,
			CombatLock = false,
			Font = {
				Color = {
					r = 1.0,
					g = 1.0,
					b = 1.0,
					a = 1.0,			
				},
				Font = "vibroceb",
				Flag = "NONE",
				Size = 12,
			},
			NonLUIStats = true,
			UseDisplay = true,
		},
		LDB = {
			["*"] = {
				Enable = true,
				InfoPanel = {
					InfoPanel = "BottomRight",
					X = 0,
					Y = 0,		
				},
			},
		},
	},
}
module.childGroups = "select"
module.optionsName = "Info Text"

function module:LoadOptions()
	local fontChange = function()
		for _, object in pairs(self.LDB) do
			object.text:SetFont(Media:Fetch("font", db.General.Font.Font), db.General.Font.Size, db.General.Font.Flag)
			object.text:SetTextColor(db.General.Font.Color.r, db.General.Font.Color.g, db.General.Font.Color.b, db.General.Font.Color.a)
		end
	end

	local infoPanels = function()
		local t = {}

		for k, v in pairs(self.Panels) do
			t[k] = k
		end

		return t
	end

	local statShowChange = function()
		for name, object in pairs(self.LDB) do
			if not strfind(name, "LUI_Stat") then
				if db.General.NonLUIStats then
					object:Show()
				else
					object:Hide()
				end
			end
		end
	end

	local nonLUILDBUpdate = function(name)
		if db.LDB[name].Enable then
			if self.LDB[name] then
				local ldb_db = db.LDB[name].InfoPanel
				self:LDBSetInfoPanel(name, ldb_db.InfoPanel, ldb_db.X, ldb_db.Y)
			end

			self:LibDataBroker_DataObjectCreated(_,_, name, LDB:GetDataObjectByName(name))
		else
			if self.LDB[name] then
				self.LDB[name]:Hide()
			end
		end
	end

	local nonLUIStats = function()		
		local options = {
			Header = self:NewHeader("Non LUI Stats", 0),
		}

		for name, data in pairs(db.LDB) do
			-- Create options for Non LUI Stat.
			local update = function() nonLUILDBUpdate(name) end
			options[name] = self:NewGroup(name, 1, false, {
				Header = self:NewHeader(name, 0),
				Enable = self:NewToggle("Show", "Whether or not to show "..name.." on LUI's display.", 1, update),
				InfoPanel = self:NewGroup("Info Panel", 2, true, {
					InfoPanel = self:NewSelect("Panel", "Select the info panel that "..name.." will be anchored too.", 0, infoPanels(), nil, update),
					X = self:NewSlider("X Offset", "Select the X offset for "..name, 1, -1000, 1000, 1, update),
					Y = self:NewSlider("Y Offset", "Select the Y offset for "..name, 2, -1000, 1000, 1, update),
				}),
			})
		end

		return options
	end

	local options = {
		General = self:NewGroup("General", 0, {
			Header = self:NewHeader("General Settings", 0),
			CombatLock = self:NewToggle("Combat Lock", "Whether or not tooltips from LDB's will be shown in combat.", 1),
			NonLUIStats = self:NewToggle("Non LUI Stats", "Whether or not LUI's display will show non LUI stats.", 2, statShowChange),
			UseDisplay = self:NewToggle("Use Display", "Whether or not to use LUI's LDB display. This will allow you to use a third party LDB display addon, but still use LUI's stats.", 3, function() self:OnEnable() end),
			Font = self:NewGroup("Font Settings", 4, true, {
				Font = self:NewSelect("Font", "Select the font to be used by LUI's display texts.", 0, AceGUIWidgetLSMlists.font, "LSM30_Font", fontChange),
				Size = self:NewSlider("Font Size", "Select the font size to be used by LUI's display texts.", 1, 6, 32, 1, fontChange),
				Flag = self:NewSelect("Font Outline", "Select the font outline to be used by LUI's display texts.", 2, LUI.FontFlags, nil, fontChange),
				Empty = self:NewDesc(" ", 3),
				Color = self:NewColor("Display Text", nil, 4, fontChange),
			}),
		}),
		Stats = self:NewGroup("LUI Stats", 1, "tree", nonLUIStats()),
		LDB = self:NewGroup("Non LUI Stats", 2, "tree", nonLUIStats()),
	}

	return options
end

function module:OnEnable()
	if db.General.UseDisplay then
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

function module:OnDisable()
	-- Hide info panels.
	self:HideInfoPanels()

	-- Disable all stats.
	for name, stat in pairs(self.Stats) do
		self:DisableStat(stat)
	end
end

function module:OnInitialize()
	-- Create database namespace.
	db, dbd = LUI:Namespace(self, true)

	-- Run through resgistered stats linking database references and calling OnInitialize().
	for name, statTable in pairs(self.Stats) do
		statTable.db = LUI.db:RegisterNamespace("LUI_Stat_"..name, statTable.defaults)
		if statTable.OnInitialize then statTable:OnInitialize() end
	end
end