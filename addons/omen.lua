--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: omen.lua
	Description: Omen Install Script
	Version....: 1.0
]]

local addonname, LUI = ...

LUI.Versions.omen = 3300
local IsAddOnLoaded = _G.IsAddOnLoaded
local GetRealmName = _G.GetRealmName
local UnitName = _G.UnitName

function LUI:InstallOmen()
	if (not IsAddOnLoaded("Omen")) and (not IsAddOnLoaded("Omen3")) then return end
	local ProfileName = UnitName("Player").." - "..GetRealmName()
	if LUI.db.global.luiconfig[ProfileName].Versions.omen == LUI.Versions.omen then return end
	local OmenDB = _G.Omen.db.profile

	OmenDB.Shown = true
	OmenDB.VGrip1 = 155.3166898740382
	OmenDB.VGrip2 = 155.3166898740382
	OmenDB.Locked = true
	OmenDB.Background.EdgeSize = 9
	OmenDB.Background.BorderTexture = "None"
	OmenDB.Background.Color.a = 0
	OmenDB.Background.Color.r = 0
	OmenDB.Background.Color.g = 0
	OmenDB.Background.Color.b = 0
	OmenDB.Background.BorderColor.a = 0
	OmenDB.Background.BorderColor.r = 0
	OmenDB.Background.BorderColor.g = 0
	OmenDB.Background.BorderColor.b = 0
	OmenDB.Background.Texture = "Solid"
	OmenDB.MinimapIcon.hide = true
	OmenDB.ShowWith.UseShowWith = false
	OmenDB.ShowWith.PVP = true
	OmenDB.ShowWith.Alone = true
	OmenDB.ShowWith.Resting = true
	OmenDB.ShowWith.HideWhileResting = false
	OmenDB.ShowWith.HideInPVP = false
	OmenDB.Warnings.Sound = false
	OmenDB.TitleBar.ShowTitleBar = false
	OmenDB.TitleBar.FontSize = 12
	OmenDB.TitleBar.Height = 18
	OmenDB.Bar.FontSize = 13
	OmenDB.Bar.FontColor.r = 0.7764705882352941
	OmenDB.Bar.FontColor.g = 0.7764705882352941
	OmenDB.Bar.FontColor.b = 0.7764705882352941
	OmenDB.Bar.ShowHeadings = false
	OmenDB.Bar.ShowValue = false
	OmenDB.Bar.UseClassColors = false
	OmenDB.Bar.Spacing = 1
	OmenDB.Bar.MyBarColor.r = 0.592156862745098
	OmenDB.Bar.MyBarColor.g = 0.592156862745098
	OmenDB.Bar.MyBarColor.b = 0.592156862745098
	OmenDB.Bar.Texture = "Minimalist"
	OmenDB.Bar.ShowTPS = false
	OmenDB.Bar.AggroBarColor.r = 0.592156862745098
	OmenDB.Bar.AggroBarColor.g = 0.592156862745098
	OmenDB.Bar.AggroBarColor.b = 0.592156862745098
	OmenDB.Bar.BarColor.a = 0.8900000005960465
	OmenDB.Bar.BarColor.r = 0.3686274509803922
	OmenDB.Bar.BarColor.g = 0.3686274509803922
	OmenDB.Bar.BarColor.b = 0.3686274509803922
	OmenDB.Bar.Font = "vibrocen"
	OmenDB.Bar.Height = 25
	OmenDB.Bar.FadeBarColor.r = 0.4666666666666667
	OmenDB.Bar.FadeBarColor.g = 0.4666666666666667
	OmenDB.Bar.FadeBarColor.b = 0.4666666666666667
	OmenDB.Bar.UseMyBarColor = true
	OmenDB.PositionX = LUI:Scale(478.61)
	OmenDB.PositionY = LUI:Scale(225.01)
	OmenDB.PositionW = 198.8860415275098
	OmenDB.PositionH = 196.9849329984127
	
	LUI.db.global.luiconfig[ProfileName].Versions.omen = LUI.Versions.omen
end
