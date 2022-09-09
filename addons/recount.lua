--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: recount.lua
	Description: Recount Install Script
	Version....: 1.0
]]

local addonname, LUI = ...

LUI.Versions.recount = 3300

local IsAddOnLoaded = _G.IsAddOnLoaded
local GetRealmName = _G.GetRealmName
local UnitName = _G.UnitName

local _, class = _G.UnitClass("player")
local Media = LibStub("LibSharedMedia-3.0")

local function RecountSetColor(Branch,Name,cr,cg,cb,ca)
	local c = {r=cr, g=cg, b=cb, a=ca,}
	_G.Recount.Colors:SetColor(Branch, Name, c)
end

function LUI:InstallRecount()
	if not IsAddOnLoaded("Recount") then return end
	local ProfileName = UnitName("Player").." - "..GetRealmName()
	if LUI.db.global.luiconfig[ProfileName].Versions.recount == LUI.Versions.recount then return end
	local Recount = _G.Recount
	local RecountDB = Recount.db.profile

	RecountDB.GraphWindowY = 0
	RecountDB.MainWindow.Buttons.CloseButton = false
	RecountDB.MainWindow.Buttons.LeftButton = false
	RecountDB.MainWindow.Buttons.ResetButton = false
	RecountDB.MainWindow.Buttons.ConfigButton = false
	RecountDB.MainWindow.Buttons.FileButton = false
	RecountDB.MainWindow.Buttons.RightButton = false
	RecountDB.MainWindow.Buttons.ReportButton = false
	RecountDB.MainWindow.ShowScrollbar = false
	RecountDB.MainWindow.Position.y = -421
	RecountDB.MainWindow.Position.x = 333
	RecountDB.MainWindow.Position.w = 197
	RecountDB.MainWindow.Position.h = 245
	RecountDB.MainWindow.RowHeight = 27
	RecountDB.MainWindow.BarText.NumFormat = 3
	RecountDB.MainWindow.BarText.Percent = false
	RecountDB.ConfirmDeleteInstance = false
	RecountDB.ReportLines = 4
	RecountDB.SegmentBosses = true
	
	RecountSetColor("Other Windows","Background",0,0,0)
	RecountSetColor("Other Windows","Title",0.298,0.305,0.298)
	RecountSetColor("Window","Background",0,0,0,0)
	RecountSetColor("Window","Title",0.133,0.133,0.133,0)
	RecountSetColor("Window","Title Text",0.133,0.133,0.133,0)
	RecountSetColor("Bar","Bar Text",0.776,0.776,0.776,1)
	RecountSetColor("Bar","Total Bar",0.776,0.776,0.776,1)
	
	local classList = {"HUNTER", "WARRIOR", "PALADIN", "MAGE", "PRIEST", "ROGUE", "WARLOCK", "DRUID", "SHAMAN", "DEATHKNIGHT", "MONK", "DEMONHUNTER", "PET", "MOB"}
	for i=1, #classList do
		if class==classList[i] then
			RecountSetColor("Class", classList[i], 0.592, 0.592, 0.592, 1)
		else
			RecountSetColor("Class", classList[i], 0.368, 0.368, 0.368, 1)
		end
	end
	RecountDB.DetailWindowY = 143
	RecountDB.ConfirmDeleteGroup = false
	RecountDB.DetailWindowX = 281
	RecountDB.GraphWindowX = 0
	
	RecountDB.Filters.Show.Pet = true
	RecountDB.Filters.Show.Ungrouped = false
	RecountDB.Filters.Data.Boss = false
	RecountDB.Filters.Data.Unknown = false
	RecountDB.Filters.TrackDeaths.Self = false
	RecountDB.Filters.TrackDeaths.Pet = false
	RecountDB.Filters.TrackDeaths.Boss = false
	RecountDB.Filters.TrackDeaths.Grouped = false
	
	RecountDB.BarTexture = "Minimalist"
	RecountDB.CurDataSet = "CurrentFightData"
	RecountDB.Font = "Arial Narrow"
	RecountDB.BarTextColorSwap = false
	RecountDB.ConfirmDeleteRaid = false
	
	Recount:LockWindows(false)
	Recount.MainWindow:SetResizable(true)
	RecountDB.MainWindowHeight = 245
	RecountDB.MainWindowWidth = 197
	Recount:SetBarTextures(RecountDB.BarTexture)
	Recount:RestoreMainWindowPosition(RecountDB.MainWindow.Position.x,RecountDB.MainWindow.Position.y,RecountDB.MainWindow.Position.w,RecountDB.MainWindow.Position.h)
	Recount:ResizeMainWindow()
	Recount:FullRefreshMainWindow()
	Recount:SetupMainWindowButtons()
	Recount.profilechange = true
	Recount:CloseAllRealtimeWindows()
	Recount.Colors:UpdateAllColors()
	Recount.profilechange = nil
	Recount:SetStrataAndClamp()
	RecountDB.Locked = true
	Recount:LockWindows(true)
	
	LUI.db.global.luiconfig[ProfileName].Versions.recount = LUI.Versions.recount
end

-- Recount font fix without having to edit recount files.
LUI.RecountFontHack = CreateFrame("frame", "RecountFontHack")
local frame = LUI.RecountFontHack
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(self)
	-- Unregister event/script and clean up.
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:SetScript("OnEvent", nil)

	-- Check if Recount is installed.
	if not IsAddOnLoaded("Recount") then return end
	local Recount = _G.Recount
	local LUIDB = LUI.db.profile.Recount

	-- Create Recount font hack functions.
	function self:FontSizeFix(string)
		local Font, Height, Flags = string:GetFont()
		string:SetFont(Media:Fetch("font",  LUIDB.Font), LUIDB.FontSize, Flags)
	end

	function self:Hack()
		-- Check if hack is enabled.
		if not LUIDB.FontHack then return end

		-- Check if hack hasn't already been done.
		if self.Hacked then return end

		-- Apply hack.
		self.old = Recount.BarsChanged
		function Recount:BarsChanged()
			frame.old(self)

			for k, v in pairs(self.MainWindow.Rows) do
				frame:FontSizeFix(v.LeftText)
				frame:FontSizeFix(v.RightText)
			end

			self:ResizeMainWindow()
		end
	
		-- Finished hack.
		self.Hacked = true
		Recount:BarsChanged()
	end

	function self:UnHack()
		-- Check to make sure hack has been done.
		if not self.Hacked then return end

		-- Reverse the hack.
		Recount.BarsChanged = self.old
		self.old = nil
		self.Hacked = nil
		Recount:BarsChanged()
	end

	function self:Toggle()
		-- Toggle database setting
		LUIDB.FontHack = not LUIDB.FontHack

		-- Hack or UnHack accordingly.
		if LUIDB.FontHack then
			self:Hack()
		else
			self:UnHack()
		end
	end

	-- Apply Recount font hack.
	self:Hack()
end)
