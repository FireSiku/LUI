--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: infotext.lua
	Description: Provides LUI infotext panels and stat building api.
	Version....: 2.0
	Rev Date...: 05/08/2011 [dd/mm/yyyy]
]]


--[[
NOTES:
	This is obviously still underconstruction. I just wanted to commit it so we can discuss ideas,
	and generally improve the modular nature of the infotext modules. And also to have it backed up. :>

	You'll notice several Debate: comments throughout the code, feel free to comment in your opinions,
	or forward them on the dev forums.

	-- Tasks
	Last: Creating default merge and :Create/:Enable/:Intitialise calls. [Create shells].
	Next: Creating options, option merging and option wrappers.
	Future: Embeding LDB support into panels.
	Debate: Making each stat created via the stat api a LDB, or keeping our stats for our own.

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
local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local InfoText = LUI:NewModule("InfoText", "AceHook-3.0")

-- Database and defaults shortcuts.
local db, dbd

-- Local variables.
InfoText.Panels = {}
InfoText.Stats = {}

------------------------------------------------------
-- / LOCALISED FUNCTIONS / --
------------------------------------------------------

local CreateFrame, strfind, InCombatLockdown = CreateFrame, strfind, InCombatLockdown

------------------------------------------------------
-- / STAT API / --
------------------------------------------------------

-- Creation functions.
function InfoText:CreateInfoPanels()
	local function CreatePanel(name, x, y)
		--[[
			This is where LDB support should be imbeded into each panel.
		]]
		local uname = strupper(name)
		return LUI:CreateMeAFrame("Frame", "LUI_InfoPanel_"..name, UIParent, 1, 1, 1, "HIGH", 0, uname, UIParent, uname, x, y, 1)
	end

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
end

function InfoText:CreateStat(statTable)
	-- Check stat table exists.
	if not statTable then return end

	-- Check if statTable's stat has already been created.
	if statTable.stat then return end

	-- Check if stat is enabled.
	if not statTable.db[statTable.name].Enabled then end

	-- Create stat.
	statTable.stat = CreateFrame("Frame", "LUI_Info_"..statTable.name, self:GetInfoPanel(statTable))
	local stat = statTable.stat

	-- Create db and name references.
	stat.db = statTable.db
	stat.name = statTable.name

	-- Enable mouse actions.
	stat:EnableMouse(true)

	-- Create stat's Enable function.
	function stat:Enable()
		-- Register assigned events and handlers.
		if self.Events then
			for i = 1, #self.Events do
				self:RegisterEvent(self.Events[i])
			end
			self:SetScript("OnEvent", self.OnEvent or function(self, event, ...) self[event](self, ...) end)
		end

		-- Register OnClick script. (Debate: OnMouseDown vs. OnMouseUp)
		if self.OnClick then
			self:SetScript("OnMouseDown", self.OnClick)
		end

		-- Register OnEnter/OnLeave scripts.
		if self.OnEnter then
			-- Create embeded tooltip functions.
			self.Enter = InfoText.CreateTooltip
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
function InfoText:CreateTooltip()
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
-- / MODULE FUNCTIONS / --
------------------------------------------------------

InfoText.defaults = {
	profile = {
		Enable = true,
		CombatLock = false,
	},
}

function InfoText:OnInitialize()
	--[[
		Run through registered stats and merge defaults database into self.defaults

		for name, statTable in pairs(self.Stats) do
			self.defaults = MergeDefaults(self.defaults, { profile = { [name] = statTable.defaults, }, })
		end
	]]

	-- Create database namespace.
	db, dbd = LUI:NewNamespace(self, true)

	--[[
		Run through resgistered stats and call OnInitialize().

		for name, statTable in pairs(self.Stats) do
			statTable:OnInitialize(db, dbd)
		end
	]]
end

function InfoText:OnEnable()
	--[[
		- Call CreateStat for each registered stat.
		- Then call Enable.
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