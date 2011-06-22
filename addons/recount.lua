--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: recount.lua
	Description: Recount Install Script
	Version....: 1.0
]] 

local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local _, class = UnitClass("player")

function LUI:InstallRecount()
	if not IsAddOnLoaded("Recount") then return end
	if LUICONFIG.Versions.recount == LUI_versions.recount then return end
	
	Recount.db.profile.GraphWindowY = 0
	Recount.db.profile.MainWindow.Buttons.CloseButton = false
	Recount.db.profile.MainWindow.Buttons.LeftButton = false
	Recount.db.profile.MainWindow.Buttons.ResetButton = false
	Recount.db.profile.MainWindow.Buttons.ConfigButton = false
	Recount.db.profile.MainWindow.Buttons.FileButton = false
	Recount.db.profile.MainWindow.Buttons.RightButton = false
	Recount.db.profile.MainWindow.Buttons.ReportButton = false
	Recount.db.profile.MainWindow.ShowScrollbar = false
	Recount.db.profile.MainWindow.Position.y = -421.097536516879
	Recount.db.profile.MainWindow.Position.x = 332.9999067269808
	Recount.db.profile.MainWindow.Position.w = 197
	Recount.db.profile.MainWindow.Position.h = 245
	Recount.db.profile.MainWindow.RowHeight = 27
	Recount.db.profile.MainWindow.BarText.NumFormat = 3
	Recount.db.profile.MainWindow.BarText.Percent = false
	Recount.db.profile.ConfirmDeleteInstance = false
	Recount.db.profile.ReportLines = 4
	Recount.db.profile.SegmentBosses = true
	
	local function RecountSetColor(Branch,Name,r,g,b,a)
		Recount.db.profile.Colors[Branch][Name].r=r
		Recount.db.profile.Colors[Branch][Name].g=g
		Recount.db.profile.Colors[Branch][Name].b=b
		Recount.db.profile.Colors[Branch][Name].a=a
	end
	
	RecountSetColor("Other Windows","Background",0,0,0)
	RecountSetColor("Other Windows","Title",0.2980392156862745,0.3058823529411765,0.2980392156862745)
	RecountSetColor("Window","Background",0,0,0,0)
	RecountSetColor("Window","Title",0.1333333333333333,0.1333333333333333,0.1333333333333333,0)
	RecountSetColor("Window","Title Text",0.1333333333333333,0.1333333333333333,0.1333333333333333,0)
	RecountSetColor("Bar","Bar Text",0.7764705882352941,0.7764705882352941,0.7764705882352941,1)
	RecountSetColor("Bar","Total Bar",0.7764705882352941,0.7764705882352941,0.7764705882352941,1)
	
	local function RecountSetClassColor(ctype,self)
		if(self==1) then
			Recount.db.profile.Colors.Class[ctype].r = 0.592156862745098
			Recount.db.profile.Colors.Class[ctype].g = 0.592156862745098
			Recount.db.profile.Colors.Class[ctype].b = 0.592156862745098
			Recount.db.profile.Colors.Class[ctype].a = 1
		else
			Recount.db.profile.Colors.Class[ctype].r = 0.3686274509803922
			Recount.db.profile.Colors.Class[ctype].g = 0.3686274509803922
			Recount.db.profile.Colors.Class[ctype].b = 0.3686274509803922
			Recount.db.profile.Colors.Class[ctype].a = 0.8900000005960465
		end
	end
	
	RecountSetClassColor("HUNTER")
	RecountSetClassColor("WARRIOR")
	RecountSetClassColor("PALADIN")
	RecountSetClassColor("MAGE")
	RecountSetClassColor("PRIEST")
	RecountSetClassColor("ROGUE")
	RecountSetClassColor("WARLOCK")
	RecountSetClassColor("PET")
	RecountSetClassColor("MOB")
	RecountSetClassColor("DRUID")
	RecountSetClassColor("SHAMAN")
	RecountSetClassColor("DEATHKNIGHT")
	
	if class == "WARRIOR" then
		RecountSetClassColor("WARRIOR",1)
	elseif class == "PRIEST" then
		RecountSetClassColor("PRIEST",1)
	elseif class == "DRUID" then
		RecountSetClassColor("DRUID",1)
	elseif class == "HUNTER" then 
		RecountSetClassColor("HUNTER",1)
	elseif class == "MAGE" then
		RecountSetClassColor("MAGE",1)
	elseif class == "PALADIN" then
		RecountSetClassColor("PALADIN",1)
	elseif class == "SHAMAN" then
		RecountSetClassColor("SHAMAN",1)
	elseif class == "WARLOCK" then
		RecountSetClassColor("WARLOCK",1)
	elseif class == "ROGUE" then
		RecountSetClassColor("ROGUE",1)
	elseif class== "DEATHKNIGHT" then
		RecountSetClassColor("DEATHKNIGHT",1)
	end
	
	Recount.db.profile.DetailWindowY = 143.0000041470295
	Recount.db.profile.ConfirmDeleteGroup = false
	Recount.db.profile.DetailWindowX = 281.0000099106976
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
	Recount.db.profile.BarTextColorSwap = false
	Recount.db.profile.Font = "vibrocen"
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
	
	LUICONFIG.Versions.recount = LUI_versions.recount
end

-- Recount font fix without having to edit recount files.
LUI.RecountFontHack = CreateFrame("frame", "RecountFontHack")
local frame = LUI.RecountFontHack
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

function frame:Hack()
	-- Unregister event.
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")

	-- Check if hack is enabled.
	if not LUI.db.profile.General.RecountFontHack then return end

	-- Check if Recount is installed.
	if not IsAddOnLoaded("Recount") then return end

	-- Check if hack hasn't already been done.
	if self.Hacked then return end

	local function mod(str)
		local f, h, fl = str:GetFont()
		str:SetFont(f, 13, fl)
	end

	-- Apply hack.
	self.old = Recount.BarsChanged
	function Recount:BarsChanged()
		frame.old(self)

		for k, v in pairs(Recount.MainWindow.Rows) do
			mod(v.LeftText)
			mod(v.RightText)
		end
	end
	
	-- Finished hack.
	self.Hacked = true
	Recount:BarsChanged()	
end

function frame:UnHack()
	-- Check to make sure hack has been done.
	if not self.Hacked then return end

	-- Check if Recount is installed.
	if not IsAddOnLoaded("Recount") then return end

	-- Reverse the hack.
	Recount.BarsChanged = self.old
	self.old = nil
	self.Hacked = nil
	Recount:BarsChanged()
end

function frame:Toggle()
	-- Toggle database setting
	LUI.db.profile.General.RecountFontHack = not LUI.db.profile.General.RecountFontHack

	-- Hack or UnHack accordingly.
	if LUI.db.profile.General.RecountFontHack then
		self:Hack()
	else
		self:UnHack()
	end
end

frame:SetScript("OnEvent", frame.Hack)