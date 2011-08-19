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
	Last: Creating LDB display support foundations.
	Next: Updating stats and stat api for LDB use.

	--
	Debate: I think the table.Created vairable should be ditched. There shouldn't
	be an occourance where the stat should have its :OnCreate method called more
	than once. To apply updates, stats should enforce/create an OnRefresh function
	which will handle the individual requirements possible upon a option change.

	Argument: Upon Enable/Disable of module or stat, we will need to know if we
	have to create each stat (cause they may have previously have been disabled
	and therefore not already created).
	Counter: statTable.stat should be enough veryify a created stat (see CreateStat
	function).

	--
	Test: Test weither or not :Hide() a frame also disables OnEvent/script functions
	similarly to how OnUpdate srcipts are halted.

	Result: OnEvent still works., various On<Script> functions may persist.
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

-- Creation functions.
function InfoText:CreateStat(statTable)
	-- Check stat table exists.
	if not statTable then return end

	-- Check if statTable's stat has already been created.
	if statTable.stat then return end

	-- Check if stat is enabled.
	if not statTable.db[statTable.name].Enabled then end

	-- Create stat.
	statTable.stat = CreateFrame("Frame", "LUI_Stat_"..statTable.name, self:GetInfoPanel(statTable))
	local stat = statTable.stat

	-- Create db and name references.
	stat.db = statTable.db
	stat.name = statTable.name

	-- Enable mouse actions.
	stat:EnableMouse(true)

	-- Create stat's Enable function.
	stat.Enable = self.StatOnEnable

	-- Create stat's text.
	self:CreateText(statTable)

	-- Call stat table's OnCreate function.
	statTable:OnCreate()
end

function InfoText:CreateText(statTable)
	-- Check stat table exists.
	if not statTable then return end

	-- Check if stat table already has a text.
	if statTable.text then return statTable.text end

	-- Create stat's text.
	statTable.text = statTable.stat:CreateFontString(statTable.stat:GetName()..": Text", "OVERLAY")
	statTable.text:SetJustifyH("LEFT")
	statTable.text:SetShadowColor(0, 0, 0)
	statTable.text:SetShadowOffset(1.24, -1.24)
	statTable.text:SetText(statTable.name)

	-- Create stat.text shortcut.
	statTable.stat.text = statTable.text

	-- Set text's info panel.
	self:SetInfoPanel(statTable)
end

function InfoText:NewStat(name)
	-- Check if stat table already exists.
	if self.Stats[name] then return self.Stats[name] end

	-- Create new stat table.
	self.Stats[name] = {
		Created = false,
		name = name,
	}

	return self.Stats[name]	
end

function InfoText:StatOnEnable()
	-- Embeded functionality.
	-- Usage of this function makes self the object calling the function.
	-- In this case: self == statTable.stat.

	-- Register assigned events and handlers.
	if self.Events then
		for i = 1, #self.Events do
			self:RegisterEvent(self.Events[i])
		end
		self:SetScript("OnEvent", self.OnEvent or function(self, event, ...) self[event](self, ...) end)
	end

	-- Register OnClick script. (Debate: OnMouseDown vs. OnMouseUp)
	if self.OnClick then
		self:SetScript("OnMouseUp", self.OnClick)
	end

	-- Register OnEnter/OnLeave scripts.
	if self.OnEnter then
		-- Create embeded tooltip functions.
		self.Enter = InfoText.EnterTooltip
		self.Leave = InfoText.LeaveTooltip
		self.UpdateTooltip = InfoText.UpdateTooltip
		self:SetScript("OnEnter", self.Enter)
		self:SetScript("OnLeave", self.Leave)
	end

	-- Register OnUpdate script. (Debate: I'm not force running the OnUpdate script; stats should be in an initial state where they can wait until the first update interval. Be it just setting an initial text state [which is done my default].)
	if self.OnUpdate then
		self.dt = 0
		self:SetScript("OnUpdate", self.OnUpdate)
	end

	-- Call stat's OnEnable function.
	if self.OnEnable then self.OnEnable() end
end

-- Accessor functions.
function InfoText:GetInfoPanel(statTable)
	-- Check statTable exists.
	if not statTable then return end

	-- Return panel to anchor stat to.
	local panel = statTable.db[statTable.name].InfoPanel
	if self.Panels[panel] then
		return self.Panels[panel]
	end
end

function InfoText:SetInfoPanel(statTable)
	-- Check statTable exists.
	if not statTable then return end
	
	-- Check statTable's text exists.
	if not statTable.text then return end

	-- Stat table database shortcut.
	local db = statTable.db[statTable.name]

	-- Get panel.
	local panel = self.Panels[db.InfoPanel]

	-- Check panel exists.
	if not panel then return end

	-- Get anchor.
	local anchor = strupper(db.InfoPanel)

	-- Set text position.
	statTable.text:ClearAllPoints()
	statTable.text:SetPoint(anchor, panel, anchor, db.X, db.Y)

	-- Set stat's parent and position.
	statTable.stat:SetParent(panel)
	statTable.stat:ClearAllPoints()
	statTable.stat:SetAllPoints(statTable.text)
end

-- Tooltip functions.
function InfoText:EnterTooltip()
	-- Embeded functionality.
	-- Usage of this function makes self the object calling the function.
	-- In this case: self == statTable.stat.

	-- Check if tooltip is usable.
	if not InfoText:IsTooltipAvailable() then return end

	-- Clear current tooltip.
	GameTooltip:ClearLines()

	-- Set tooltips owner to the stat.
	local anchor = (strfind(self.db[self.name].InfoPanel, "Top") and "ANCHOR_BOTTOM") or "ANCHOR_TOP"
	GameTooltip:SetOwner(self, anchor)

	-- Add tooltip header.
	GameTooltip:AddLine(self.name, 0.4, 0.78, 1)
	GameTooltip:AddLine(" ")

	-- Call the custom :OnEnter.
	self:OnEnter()

	-- Show the tooltip.
	GameTooltip:Show()
end

function InfoText:LeaveTooltip()
	-- Embeded functionality.
	-- Usage of this function makes self the object calling the function.
	-- In this case: self == statTable.stat.

	-- Call the custom :OnLeave.
	if self.OnLeave then self:OnLeave() end

	-- Hide tooltip.
	GameTooltip:Hide()
end

function InfoText:IsTooltipAvailable()
	return not (InCombatLockdown() and db.CombatLock)
end

function InfoText:UpdateTooltip()
	-- Embeded functionality.
	-- Usage of this function makes self the object calling the function.
	-- In this case: self == statTable.stat.

	if self:IsMouseOver() and GametTooltip:GetOwner() == self then
		-- Debate: If stat.OnEnter doesn't exist, don't call UpdateTooltip()... lol.
		self:Enter()
	end
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

	-- Unregister LDB support.
	LDB.UnregisterCallback(self, "LibDataBroker_DataObjectCreated")
	LDB.UnregisterCallback(self, "LibDataBroker_AttributeChanged__icon")
	LDB.UnregisterCallback(self, "LibDataBroker_AttributeChanged__infoPanel")
	LDB.UnregisterCallback(self, "LibDataBroker_AttributeChanged__infoPanelX")
	LDB.UnregisterCallback(self, "LibDataBroker_AttributeChanged__infoPanelY")
	LDB.UnregisterCallback(self, "LibDataBroker_AttributeChanged__text")
end

-- Accessor functions.
function InfoText:SetLDBInfoPanel(name, panel, x, y)
	-- Check for dataobject.
	local object = self.LDB[name]
	if not object then return end

	-- Set object fields.
	object.dataobject.infoPanel = panel or object.dataobject.infoPanel
	object.dataobject.infoPanelX = x or object.dataobject.infoPanelX
	object.dataobject.infoPanelY = y or object.dataobject.infoPanelY
end

-- Tooltip functions.
function InfoText:LDBEnterTooltip()
	-- Embeded functionality.
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

-- LDB functions.
local lastX = -15
function InfoText:LibDataBroker_DataObjectCreated(_, name, dataobject)
	-- Check dataobject is already registered.
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

	-- Create object's icon.
	if dataobject.icon then
		object.icon = CreateFrame("Button", object:GetName()..": Icon", object)
		object.icon:SetPoint("RIGHT", object.text, "LEFT", -2, 0)
		object.icon:SetWidth(15)
		object.icon:SetHeight(15)
		object.icon:SetBackdrop({
			bgFile = dataobject.icon,
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
	end

	-- Set LDB panel position.
	self:SetLDBInfoPanel(name)
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

function InfoText:OnEnable()
	if db.UseDisplay then
		-- Create info panels.
		self:CreateInfoPanels()
	else
		-- Hide info panels.
		self:HideInfoPanels()
	end

	--[[
		-- Call CreateStat for each registered stat.
		-- Then call Enable.
	]]

	for name, statTable in pairs(self.Stats) do
		-- Create stat.
		self:CreateStat(statTable)

		-- Enable stat.
		-- This should probably be a call to an EnableStat(statTable) function like we have in datatext.lua. That way we can enable/disable 
		-- individual stats properly from options.
		if stat.Enable then stat:Enable() end
	end
end