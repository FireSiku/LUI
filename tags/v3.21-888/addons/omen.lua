--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: omen.lua
	Description: Omen Install Script
	Version....: 1.0
]] 

local addonname, LUI = ...

LUI.Versions.omen = 3300

function LUI:InstallOmen()
	if (not IsAddOnLoaded("Omen")) and (not IsAddOnLoaded("Omen3")) then return end
	local ProfileName = UnitName("Player").." - "..GetRealmName()
	if LUI.db.global.luiconfig[ProfileName].Versions.omen == LUI.Versions.omen then return end
	
	Omen.db.profile.Shown = true
	Omen.db.profile.VGrip1 = 155.3166898740382
	Omen.db.profile.VGrip2 = 155.3166898740382
	Omen.db.profile.Locked = true
	Omen.db.profile.Background.EdgeSize = 9
	Omen.db.profile.Background.BorderTexture = "None"
	Omen.db.profile.Background.Color.a = 0
	Omen.db.profile.Background.Color.r = 0
	Omen.db.profile.Background.Color.g = 0
	Omen.db.profile.Background.Color.b = 0
	Omen.db.profile.Background.BorderColor.a = 0
	Omen.db.profile.Background.BorderColor.r = 0
	Omen.db.profile.Background.BorderColor.g = 0
	Omen.db.profile.Background.BorderColor.b = 0
	Omen.db.profile.Background.Texture = "Solid"
	Omen.db.profile.MinimapIcon.hide = true
	Omen.db.profile.ShowWith.UseShowWith = false
	Omen.db.profile.ShowWith.PVP = true
	Omen.db.profile.ShowWith.Alone = true
	Omen.db.profile.ShowWith.Resting = true
	Omen.db.profile.ShowWith.HideWhileResting = false
	Omen.db.profile.ShowWith.HideInPVP = false
	Omen.db.profile.Warnings.Sound = false
	Omen.db.profile.TitleBar.ShowTitleBar = false
	Omen.db.profile.TitleBar.FontSize = 12
	Omen.db.profile.TitleBar.Height = 18
	Omen.db.profile.Bar.FontSize = 13
	Omen.db.profile.Bar.FontColor.r = 0.7764705882352941
	Omen.db.profile.Bar.FontColor.g = 0.7764705882352941
	Omen.db.profile.Bar.FontColor.b = 0.7764705882352941
	Omen.db.profile.Bar.ShowHeadings = false
	Omen.db.profile.Bar.ShowValue = false
	Omen.db.profile.Bar.UseClassColors = false
	Omen.db.profile.Bar.Spacing = 1
	Omen.db.profile.Bar.MyBarColor.r = 0.592156862745098
	Omen.db.profile.Bar.MyBarColor.g = 0.592156862745098
	Omen.db.profile.Bar.MyBarColor.b = 0.592156862745098
	Omen.db.profile.Bar.Texture = "Minimalist"
	Omen.db.profile.Bar.ShowTPS = false
	Omen.db.profile.Bar.AggroBarColor.r = 0.592156862745098
	Omen.db.profile.Bar.AggroBarColor.g = 0.592156862745098
	Omen.db.profile.Bar.AggroBarColor.b = 0.592156862745098
	Omen.db.profile.Bar.BarColor.a = 0.8900000005960465
	Omen.db.profile.Bar.BarColor.r = 0.3686274509803922
	Omen.db.profile.Bar.BarColor.g = 0.3686274509803922
	Omen.db.profile.Bar.BarColor.b = 0.3686274509803922
	Omen.db.profile.Bar.Font = "vibrocen"
	Omen.db.profile.Bar.Height = 25
	Omen.db.profile.Bar.FadeBarColor.r = 0.4666666666666667
	Omen.db.profile.Bar.FadeBarColor.g = 0.4666666666666667
	Omen.db.profile.Bar.FadeBarColor.b = 0.4666666666666667
	Omen.db.profile.Bar.UseMyBarColor = true
	Omen.db.profile.PositionX = 428.618218069226
	Omen.db.profile.PositionY = 224.0147437441533
	Omen.db.profile.PositionW = 198.8860415275098
	Omen.db.profile.PositionH = 196.9849329984127
	
	LUI.db.global.luiconfig[ProfileName].Versions.omen = LUI.Versions.omen
end
