--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: recount.lua
	Description: Recount Install Script
	Version....: 1.0
]] 

local addonname, LUI = ...

LUI.Versions.recount = 3300

local _, class = UnitClass("player")
local Media = LibStub("LibSharedMedia-3.0")

local function RecountSetColor(Branch,Name,cr,cg,cb,ca)
	local c = {r=cr, g=cg, b=cb, a=ca,} 
	Recount.Colors:SetColor(Branch, Name, c)
end

function LUI:InstallRecount()
	if not IsAddOnLoaded("Recount") then return end
	local ProfileName = UnitName("Player").." - "..GetRealmName()
	if LUI.db.global.luiconfig[ProfileName].Versions.recount == LUI.Versions.recount then return end
	
	Recount.db.profile.GraphWindowY = 0
	Recount.db.profile.MainWindow.Buttons.CloseButton = false
	Recount.db.profile.MainWindow.Buttons.LeftButton = false
	Recount.db.profile.MainWindow.Buttons.ResetButton = false
	Recount.db.profile.MainWindow.Buttons.ConfigButton = false
	Recount.db.profile.MainWindow.Buttons.FileButton = false
	Recount.db.profile.MainWindow.Buttons.RightButton = false
	Recount.db.profile.MainWindow.Buttons.ReportButton = false
	Recount.db.profile.MainWindow.ShowScrollbar = false
	Recount.db.profile.MainWindow.Position.y = -421
	Recount.db.profile.MainWindow.Position.x = 333
	Recount.db.profile.MainWindow.Position.w = 197
	Recount.db.profile.MainWindow.Position.h = 245
	Recount.db.profile.MainWindow.RowHeight = 27
	Recount.db.profile.MainWindow.BarText.NumFormat = 3
	Recount.db.profile.MainWindow.BarText.Percent = false
	Recount.db.profile.ConfirmDeleteInstance = false
	Recount.db.profile.ReportLines = 4
	Recount.db.profile.SegmentBosses = true
	
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
	Recount.db.profile.DetailWindowY = 143
	Recount.db.profile.ConfirmDeleteGroup = false
	Recount.db.profile.DetailWindowX = 281
	Recount.db.profile.GraphWindowX = 0

	Recount.db.profile.Filters.Show.Pet = true
	Recount.db.profile.Filters.Show.Ungrouped = false
	Recount.db.profile.Filters.Data.Boss = false
	Recount.db.profile.Filters.Data.Unknown = false
	Recount.db.profile.Filters.TrackDeaths.Self = false
	Recount.db.profile.Filters.TrackDeaths.Pet = false
	Recount.db.profile.Filters.TrackDeaths.Boss = false
	Recount.db.profile.Filters.TrackDeaths.Grouped = false

	Recount.db.profile.BarTexture = "Minimalist"
	Recount.db.profile.CurDataSet = "CurrentFightData"
	Recount.db.profile.Font = "Arial Narrow"
	Recount.db.profile.BarTextColorSwap = false
	Recount.db.profile.ConfirmDeleteRaid = false
	
	Recount:LockWindows(false)
	Recount.MainWindow:SetResizable(true)
	Recount.db.profile.MainWindowHeight = 245
	Recount.db.profile.MainWindowWidth = 197
	Recount:SetBarTextures(Recount.db.profile.BarTexture)
	Recount:RestoreMainWindowPosition(Recount.db.profile.MainWindow.Position.x,Recount.db.profile.MainWindow.Position.y,Recount.db.profile.MainWindow.Position.w,Recount.db.profile.MainWindow.Position.h)
	Recount:ResizeMainWindow()
	Recount:FullRefreshMainWindow()
	Recount:SetupMainWindowButtons()
	Recount.profilechange = true
	Recount:CloseAllRealtimeWindows()
	Recount.Colors:UpdateAllColors()
	Recount.profilechange = nil
	Recount:SetStrataAndClamp()
	Recount.db.profile.Locked = true
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

	-- Create Recount font hack functions.
	function self:FontSizeFix(string)
		local Font, Height, Flags = string:GetFont()
		string:SetFont(Media:Fetch("font",  LUI.db.profile.Recount.Font), LUI.db.profile.Recount.FontSize, Flags)
	end

	function self:Hack()
		-- Check if hack is enabled.
		if not LUI.db.profile.Recount.FontHack then return end

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
		LUI.db.profile.Recount.FontHack = not LUI.db.profile.Recount.FontHack

		-- Hack or UnHack accordingly.
		if LUI.db.profile.Recount.FontHack then
			self:Hack()
		else
			self:UnHack()
		end
	end

	-- Apply Recount font hack.
	self:Hack()
end)
