--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: micromenu.lua
	Description: Micromenu Module
	Version....: 1.3
	Rev Date...: 17/11/2010
	
	Edits:
		v1.0: Loui
		v1.1: Loui/Thaly
		v1.2: Thaly
		v1.3: Thaly
		...b: Thaly
]] 

local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local module = LUI:NewModule("Micromenu")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local RaidMenu

local db
local fdir = "Interface\\AddOns\\LUI\\media\\templates\\v3\\"

local _, class = UnitClass("player")

function module:SetMicroMenuPosition()
	MicroMenuAnchor:ClearAllPoints()
	MicroMenuAnchor:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",db.Frames.Micromenu.NaviX,db.Frames.Micromenu.NaviY)
	
	MicroMenuButton:ClearAllPoints()
	MicroMenuButton:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",db.Frames.Micromenu.X,db.Frames.Micromenu.Y)
end

function module:SetColors()
	local r, g, b = unpack(db.Colors.micromenu)
	local rc, gc, bc, ac = unpack(db.Colors.micromenu_bg)
	local rd, gd, bd, ad = unpack(db.Colors.micromenu_bg2)
	local rb, gb, bb, ab = unpack(db.Colors.micromenu_btn)
	
	MicroMenuAnchor:SetBackdropColor(rb, gb, bb, ab)
	MicroMenu_ButtonRight:SetBackdropColor(rb, gb, bb, ab)
	MicroMenu_ButtonLeft:SetBackdropColor(rb, gb, bb, ab)
	
	MicroMenuButton:SetBackdropColor(rc, gc, bc, ac)
	MicroMenuButtonBG:SetBackdropColor(rd, gd, bd, ad)
	
	MicroMenuButton_Bags:SetBackdropColor(r,g,b,1)
	MicroMenuButton_Settings:SetBackdropColor(r,g,b,1)
	MicroMenuButton_GM:SetBackdropColor(r,g,b,1)
	MicroMenuButton_LFG:SetBackdropColor(r,g,b,1)
	MicroMenuButton_PVP:SetBackdropColor(r,g,b,1)
	MicroMenuButton_Guild:SetBackdropColor(r,g,b,1)
	MicroMenuButton_Quests:SetBackdropColor(r,g,b,1)
	MicroMenuButton_AC:SetBackdropColor(r,g,b,1)
	MicroMenuButton_Talents:SetBackdropColor(r,g,b,1)
	MicroMenuButton_Spellbook:SetBackdropColor(r,g,b,1)
	MicroMenuButton_Player:SetBackdropColor(r,g,b,1)
	
	-- talent alert frame
	TalentMicroButtonAlertBg:SetGradientAlpha("VERTICAL", r/4, g/4, b/4, 1, 0, 0, 0, 1)
	
	TalentMicroButtonAlertArrowGlow:SetVertexColor(r, g, b, 0.5)
	
	TalentMicroButtonAlertArrowArrow:SetVertexColor(r, g, b)
	
	TalentMicroButtonAlertGlowTopLeft:SetVertexColor(r, g, b)
	TalentMicroButtonAlertGlowTopRight:SetVertexColor(r, g, b)
	TalentMicroButtonAlertGlowBottomLeft:SetVertexColor(r, g, b)
	TalentMicroButtonAlertGlowBottomRight:SetVertexColor(r, g, b)
	
	TalentMicroButtonAlertGlowTop:SetVertexColor(r, g, b)
	TalentMicroButtonAlertGlowBottom:SetVertexColor(r, g, b)
	TalentMicroButtonAlertGlowLeft:SetVertexColor(r, g, b)
	TalentMicroButtonAlertGlowRight:SetVertexColor(r, g, b)
	
end

function module:SetMicroMenu()
	local micro_r, micro_g, micro_b = unpack(db.Colors.micromenu)
	
	local MicroMenuAnchor = LUI:CreateMeAFrame("FRAME","MicroMenuAnchor",UIParent,128,128,1,"HIGH",2,"TOPRIGHT",UIParent,"TOPRIGHT",-150,6,1)
	MicroMenuAnchor:SetBackdrop({bgFile = fdir.."micro_anchor",
				  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
				  tile=false, tileSize = 0, edgeSize = 1,
				  insets = { left = 0, right = 0, top = 0, bottom = 0}});
	MicroMenuAnchor:SetBackdropColor(unpack(db.Colors.micromenu_btn))
	MicroMenuAnchor:SetBackdropBorderColor(0,0,0,0)
	MicroMenuAnchor:SetAlpha(1)
	MicroMenuAnchor:Show()
	
	if db.Frames.IsMicroMenuShown == true then
		MicroMenuAnchor:SetBackdrop({bgFile = fdir.."micro_anchor3",
			  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
			  tile=false, tileSize = 0, edgeSize = 1,
			  insets = { left = 0, right = 0, top = 0, bottom = 0}});
		MicroMenuAnchor:SetBackdropColor(unpack(db.Colors.micromenu_btn))
		MicroMenuAnchor:SetBackdropBorderColor(0,0,0,0)	
	end
	
	local MicroMenu_ButtonRight = LUI:CreateMeAFrame("FRAME","MicroMenu_ButtonRight",MicroMenuAnchor,128,128,1,"HIGH",1,"RIGHT",MicroMenuAnchor,"RIGHT",47,-3,1)
	MicroMenu_ButtonRight:SetBackdrop({bgFile = fdir.."mm_button_right",
				  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
				  tile=false, tileSize = 0, edgeSize = 1,
				  insets = { left = 0, right = 0, top = 0, bottom = 0}});
	MicroMenu_ButtonRight:SetBackdropColor(unpack(db.Colors.micromenu_btn))
	MicroMenu_ButtonRight:SetBackdropBorderColor(0,0,0,0)
	MicroMenu_ButtonRight:SetAlpha(1)
	MicroMenu_ButtonRight:Show()
	
	local MicroMenu_ButtonLeft = LUI:CreateMeAFrame("FRAME","MicroMenu_ButtonLeft",MicroMenuAnchor,128,128,1,"HIGH",1,"LEFT",MicroMenuAnchor,"LEFT",-47,-3,1)
	MicroMenu_ButtonLeft:SetBackdrop({bgFile = fdir.."mm_button_left",
				  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
				  tile=false, tileSize = 0, edgeSize = 1,
				  insets = { left = 0, right = 0, top = 0, bottom = 0}});
	MicroMenu_ButtonLeft:SetBackdropColor(unpack(db.Colors.micromenu_btn))
	MicroMenu_ButtonLeft:SetBackdropBorderColor(0,0,0,0)
	MicroMenu_ButtonLeft:SetAlpha(1)
	MicroMenu_ButtonLeft:Show()
	
	local MicroMenu_Clicker = LUI:CreateMeAFrame("BUTTON","MicroMenu_Clicker",MicroMenuAnchor,85,22,1,"HIGH",2,"TOP",MicroMenuAnchor,"TOP",0,0,1)
	MicroMenu_Clicker:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
				  tile=false, tileSize = 0, edgeSize = 1,
				  insets = { left = 0, right = 0, top = 0, bottom = 0}});
	MicroMenu_Clicker:SetBackdropColor(0,0,0,0)
	MicroMenu_Clicker:SetBackdropBorderColor(0,0,0,0)
	MicroMenu_Clicker:SetAlpha(1)
	MicroMenu_Clicker:Show()
	
	local MicroMenu_ButtonRight_Clicker = LUI:CreateMeAFrame("BUTTON","MicroMenu_ButtonRight_Clicker",MicroMenu_ButtonRight,40,12,1,"HIGH",2,"TOP",MicroMenu_ButtonRight,"TOP",22,-5,1)
	MicroMenu_ButtonRight_Clicker:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
				  tile=false, tileSize = 0, edgeSize = 1,
				  insets = { left = 0, right = 0, top = 0, bottom = 0}});
	MicroMenu_ButtonRight_Clicker:SetBackdropColor(0,0,0,0)
	MicroMenu_ButtonRight_Clicker:SetBackdropBorderColor(0,0,0,0)
	MicroMenu_ButtonRight_Clicker:SetAlpha(1)
	MicroMenu_ButtonRight_Clicker:Show()
	
	local MicroMenu_ButtonLeft_Clicker = LUI:CreateMeAFrame("BUTTON","MicroMenu_ButtonLeft_Clicker",MicroMenu_ButtonLeft,40,12,1,"HIGH",2,"TOP",MicroMenu_ButtonLeft,"TOP",-22,-5,1)
	MicroMenu_ButtonLeft_Clicker:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
				  tile=false, tileSize = 0, edgeSize = 1,
				  insets = { left = 0, right = 0, top = 0, bottom = 0}});
	MicroMenu_ButtonLeft_Clicker:SetBackdropColor(0,0,0,0)
	MicroMenu_ButtonLeft_Clicker:SetBackdropBorderColor(0,0,0,0)
	MicroMenu_ButtonLeft_Clicker:SetAlpha(1)
	MicroMenu_ButtonLeft_Clicker:Hide()
	
	local MicroMenuButton = LUI:CreateMeAFrame("FRAME","MicroMenuButton",UIParent,512,512,1,"BACKGROUND",1,"TOPRIGHT",UIParent,"TOPRIGHT",0,-1,1)
	MicroMenuButton:SetBackdrop({bgFile = fdir.."micro_button",
				  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
				  tile=false, tileSize = 0, edgeSize = 1,
				  insets = { left = 0, right = 0, top = 0, bottom = 0}});
	MicroMenuButton:SetBackdropColor(db.Colors.micromenu_bg[1], db.Colors.micromenu_bg[2], db.Colors.micromenu_bg[3],db.Colors.micromenu_bg[4])
	MicroMenuButton:SetBackdropBorderColor(0,0,0,0)
	MicroMenuButton:SetAlpha(1)
	MicroMenuButton:Show()
	
	MicroMenu_ButtonRight_Clicker:RegisterForClicks("AnyUp")
	MicroMenu_ButtonRight_Clicker:SetScript("OnClick", function(self)
		if Minimap:GetAlpha() == 0 then
			MinimapAlphaIn:Show()
			db.Frames.IsMinimapShown = true
		else
			MinimapAlphaOut:Show()
			db.Frames.IsMinimapShown = false
		end
	end)
	
	MicroMenu_ButtonRight_Clicker:SetScript("OnEnter", function(self)
		MicroMenu_ButtonRight:SetBackdrop({bgFile = fdir.."mm_button_right_hover",
					  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
					  tile=false, tileSize = 0, edgeSize = 1,
					  insets = { left = 0, right = 0, top = 0, bottom = 0}});
		MicroMenu_ButtonRight:SetBackdropColor(unpack(db.Colors.micromenu_btn_hover))
		MicroMenu_ButtonRight:SetBackdropBorderColor(0,0,0,0)
	end)
	
	MicroMenu_ButtonRight_Clicker:SetScript("OnLeave", function(self)
		MicroMenu_ButtonRight:SetBackdrop({bgFile = fdir.."mm_button_right",
					  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
					  tile=false, tileSize = 0, edgeSize = 1,
					  insets = { left = 0, right = 0, top = 0, bottom = 0}});
		MicroMenu_ButtonRight:SetBackdropColor(unpack(db.Colors.micromenu_btn))
		MicroMenu_ButtonRight:SetBackdropBorderColor(0,0,0,0)
	end)
	
	MicroMenu_ButtonLeft_Clicker:Show()
	
	MicroMenu_ButtonLeft_Clicker:RegisterForClicks("AnyUp")
	MicroMenu_ButtonLeft_Clicker:SetScript("OnClick", function(self,button)
		if (class == "PALADIN") and (IsAddOnLoaded("PallyPower")) and ((button == "RightButton") or (not LUI:GetModule("RaidMenu", true) or not db.RaidMenu.Enable)) then
			if PallyPowerFrame:IsShown() then
				PallyPowerFrame:Hide()
				PallyPowerFrame:SetAlpha(0)
			else
				PallyPowerFrame:Show()
				PallyPowerFrame:SetAlpha(1)
			end
		else
			RaidMenu:OverlapPrevention("RM", "toggle")
		end
	end)
	
	MicroMenu_ButtonLeft_Clicker:SetScript("OnEnter", function(self)
		MicroMenu_ButtonLeft:SetBackdrop({bgFile = fdir.."mm_button_left_hover",
					  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
					  tile=false, tileSize = 0, edgeSize = 1,
					  insets = { left = 0, right = 0, top = 0, bottom = 0}});
		MicroMenu_ButtonLeft:SetBackdropColor(unpack(db.Colors.micromenu_btn_hover))
		MicroMenu_ButtonLeft:SetBackdropBorderColor(0,0,0,0)
	end)
	
	MicroMenu_ButtonLeft_Clicker:SetScript("OnLeave", function(self)
		MicroMenu_ButtonLeft:SetBackdrop({bgFile = fdir.."mm_button_left",
					  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
					  tile=false, tileSize = 0, edgeSize = 1,
					  insets = { left = 0, right = 0, top = 0, bottom = 0}});
		MicroMenu_ButtonLeft:SetBackdropColor(unpack(db.Colors.micromenu_btn))
		MicroMenu_ButtonLeft:SetBackdropBorderColor(0,0,0,0)
	end)

	local mm_timerout, mm_timerin = 0,0
	local mm_alpha_timer = 0.5
	
	local MMAlphaOut = CreateFrame("Frame", "MMAlphaOut", UIParent)
	MMAlphaOut:Hide()
	
	MMAlphaOut:SetScript("OnUpdate", function(self,elapsed)
		mm_timerout = mm_timerout + elapsed
		if mm_timerout < mm_alpha_timer then
			local alpha = 1 - mm_timerout / mm_alpha_timer 
			MicroMenuButton:SetAlpha(alpha)
		else
			MicroMenuButton:SetAlpha(0)
			MicroMenuButton:Hide()
			mm_timerout = 0
			self:Hide()
		end
	end)
	
	local MMAlphaIn = CreateFrame("Frame", "MMAlphaIn", UIParent)
	MMAlphaIn:Hide()
	
	MMAlphaIn:SetScript("OnUpdate", function(self,elapsed)
		MicroMenuButton:Show()
		mm_timerin = mm_timerin + elapsed
		if mm_timerin < mm_alpha_timer then
			local alpha = mm_timerin / mm_alpha_timer 
			MicroMenuButton:SetAlpha(alpha)
		else
			MicroMenuButton:SetAlpha(1)
			mm_timerin = 0
			self:Hide()
		end
	end)
	
	MicroMenu_Clicker:SetScript("OnClick", function(self)
		if LUI:GetModule("RaidMenu", true) and db.RaidMenu.Enable then
			RaidMenu:OverlapPrevention("MM")
		end
		if db.Frames.IsMicroMenuShown == true then
			MMAlphaOut:Show()
			db.Frames.IsMicroMenuShown = false
			
			MicroMenuAnchor:SetBackdrop({bgFile = fdir.."micro_anchor",
				  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
				  tile=false, tileSize = 0, edgeSize = 1,
				  insets = { left = 0, right = 0, top = 0, bottom = 0}});
			MicroMenuAnchor:SetBackdropColor(unpack(db.Colors.micromenu_btn_hover))
			MicroMenuAnchor:SetBackdropBorderColor(0,0,0,0)	
		else
			MMAlphaIn:Show()
			db.Frames.IsMicroMenuShown = true
			
			MicroMenuAnchor:SetBackdrop({bgFile = fdir.."micro_anchor3",
				  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
				  tile=false, tileSize = 0, edgeSize = 1,
				  insets = { left = 0, right = 0, top = 0, bottom = 0}});
			MicroMenuAnchor:SetBackdropColor(unpack(db.Colors.micromenu_btn_hover))
			MicroMenuAnchor:SetBackdropBorderColor(0,0,0,0)	
		end
	end)
	
	MicroMenu_Clicker:SetScript("OnEnter", function(self)
		if db.Frames.IsMicroMenuShown == true then
			MicroMenuAnchor:SetBackdrop({bgFile = fdir.."micro_anchor4",
				  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
				  tile=false, tileSize = 0, edgeSize = 1,
				  insets = { left = 0, right = 0, top = 0, bottom = 0}});
			MicroMenuAnchor:SetBackdropColor(unpack(db.Colors.micromenu_btn_hover))
			MicroMenuAnchor:SetBackdropBorderColor(0,0,0,0)	
		else
			MicroMenuAnchor:SetBackdrop({bgFile = fdir.."micro_anchor2",
				  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
				  tile=false, tileSize = 0, edgeSize = 1,
				  insets = { left = 0, right = 0, top = 0, bottom = 0}});
			MicroMenuAnchor:SetBackdropColor(unpack(db.Colors.micromenu_btn_hover))
			MicroMenuAnchor:SetBackdropBorderColor(0,0,0,0)	
		end
	end)
		
	MicroMenu_Clicker:SetScript("OnLeave", function(self)
		if db.Frames.IsMicroMenuShown == true then
			MicroMenuAnchor:SetBackdrop({bgFile = fdir.."micro_anchor3",
				  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
				  tile=false, tileSize = 0, edgeSize = 1,
				  insets = { left = 0, right = 0, top = 0, bottom = 0}});
			MicroMenuAnchor:SetBackdropColor(unpack(db.Colors.micromenu_btn))
			MicroMenuAnchor:SetBackdropBorderColor(0,0,0,0)	
		else
			MicroMenuAnchor:SetBackdrop({bgFile = fdir.."micro_anchor",
				  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
				  tile=false, tileSize = 0, edgeSize = 1,
				  insets = { left = 0, right = 0, top = 0, bottom = 0}});
			MicroMenuAnchor:SetBackdropColor(unpack(db.Colors.micromenu_btn))
			MicroMenuAnchor:SetBackdropBorderColor(0,0,0,0)	
		end
	end)
	
	local MicroMenuButtonBG = LUI:CreateMeAFrame("FRAME","MicroMenuButtonBG",MicroMenuButton,510,512,1,"BACKGROUND",0,"TOPRIGHT",MicroMenuButton,"TOPRIGHT",0,0,1)
	MicroMenuButtonBG:SetBackdrop({bgFile = fdir.."micro_button_bg",
				  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
				  tile=false, tileSize = 0, edgeSize = 1,
				  insets = { left = 0, right = 0, top = 0, bottom = 0}});
	MicroMenuButtonBG:SetBackdropColor(unpack(db.Colors.micromenu_bg2))
	MicroMenuButtonBG:SetBackdropBorderColor(0,0,0,0)
	MicroMenuButtonBG:SetFrameStrata("BACKGROUND")
	MicroMenuButtonBG:Show()
	
	--------------------------------------
	-- MICRO MENU
	--------------------------------------
	
	local bagsFrame
	
	local function getBagsFrame()
		if db.Bags.Enable == true then
			bagsFrame = _G["LUIBags"]
		else
			if IsAddOnLoaded("Stuffing") then
				bagsFrame = _G["StuffingFrameBags"]
			elseif IsAddOnLoaded("Bagnon") then
				bagsFrame = _G["BagnonFrameinventory"]
			elseif IsAddOnLoaded("ArkInventory") then
				bagsFrame = _G["ARKINV_Frame1"]
			elseif IsAddOnLoaded("OneBag") then
				bagsFrame = _G["OneBagFrame"]
			else
				bagsFrame = nil
			end
		end
	end
	getBagsFrame()
	
	local MicroMenuButton_Bags = LUI:CreateMeAFrame("FRAME","MicroMenuButton_Bags",MicroMenuButton,64,64,1,"BACKGROUND",3,"TOPRIGHT",MicroMenuButton,"TOPRIGHT",0,0,1)
	MicroMenuButton_Bags:SetBackdrop({bgFile = fdir.."micro_bags",
				  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
				  tile=false, tileSize = 0, edgeSize = 1,
				  insets = { left = 0, right = 0, top = 0, bottom = 0}});
	--MicroMenuButton_Bags:SetBackdropColor(0.6,0.9,1,1)
	MicroMenuButton_Bags:SetBackdropColor(micro_r, micro_g, micro_b,1)
	MicroMenuButton_Bags:SetBackdropBorderColor(0,0,0,0)
	MicroMenuButton_Bags:SetAlpha(1)
	MicroMenuButton_Bags:Show()
	
	local MicroMenuButton_Bags_Clicker = LUI:CreateMeAFrame("BUTTON","MicroMenuButton_Bags_Clicker",MicroMenuButton_Bags,42,25,1,"BACKGROUND",2,"CENTER",MicroMenuButton_Bags,"CENTER",-8,0,1)
	MicroMenuButton_Bags_Clicker:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
				  tile=false, tileSize = 0, edgeSize = 1,
				  insets = { left = 0, right = 0, top = 0, bottom = 0}});
	MicroMenuButton_Bags_Clicker:SetBackdropColor(0,0,0,1)
	MicroMenuButton_Bags_Clicker:SetBackdropBorderColor(0,0,0,0)
	MicroMenuButton_Bags_Clicker:SetFrameStrata("BACKGROUND")
	MicroMenuButton_Bags_Clicker:SetFrameLevel(2)
	MicroMenuButton_Bags_Clicker:SetAlpha(0)
	MicroMenuButton_Bags_Clicker:Show()
	
	local MicroMenuButton_Bags_Clicker_State = false
	
	MicroMenuButton_Bags_Clicker:SetScript("OnEnter", function(self)
		MicroMenuButton_Bags_Clicker:SetAlpha(1)
		MicroMenuButton_Bags_Clicker_State = true
		GameTooltip:SetOwner(MicroMenuButton_Bags_Clicker, "ANCHOR_NONE ",40,-90)
		GameTooltip:SetText("Bags")
		GameTooltip:AddLine("Show/Hide your Bags", 1, 1, 1)
		GameTooltip:Show()
	end)
		
	MicroMenuButton_Bags_Clicker:SetScript("OnLeave", function(self)
		getBagsFrame()
		if bagsFrame and not bagsFrame:IsShown() then
			MicroMenuButton_Bags_Clicker:SetAlpha(0)
		end
		MicroMenuButton_Bags_Clicker_State = false
		GameTooltip:Hide()
	end)
	
	MicroMenuButton_Bags_Clicker:SetScript("OnClick", function(self)
		ToggleBackpack()
	end)
	
	-- other way is little bit bugging
	MicroMenuButton_Bags_Clicker:SetScript("OnUpdate", function(self)
		if bagsFrame then
			if bagsFrame:IsShown() or MicroMenuButton_Bags_Clicker_State == true then
				MicroMenuButton_Bags_Clicker:SetAlpha(1)
			else
				MicroMenuButton_Bags_Clicker:SetAlpha(0)
			end
		else
			MicroMenuButton_Bags_Clicker:SetAlpha(0)
		end
	end)
				
	--[[
	if bagsFrame then
		bagsFrame:HookScript("OnShow", function(self)
			MicroMenuButton_Bags_Clicker:SetAlpha(1)
		end)
		
		bagsFrame:HookScript("OnHide", function(self)
			if MicroMenuButton_Bags_Clicker_State == false then
				MicroMenuButton_Bags_Clicker:SetAlpha(0)
			end
		end)
	end
	]]
	
	local MicroMenuButton_Settings = LUI:CreateMeAFrame("FRAME","MicroMenuButton_Settings",MicroMenuButton_Bags,64,64,1,"BACKGROUND",3,"LEFT",MicroMenuButton_Bags,"LEFT",-48,0,1)
	MicroMenuButton_Settings:SetBackdrop({bgFile = fdir.."micro_settings",
				  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
				  tile=false, tileSize = 0, edgeSize = 1,
				  insets = { left = 0, right = 0, top = 0, bottom = 0}});
	--MicroMenuButton_Settings:SetBackdropColor(0.6,0.9,1,1)
	MicroMenuButton_Settings:SetBackdropColor(micro_r, micro_g, micro_b,1)
	MicroMenuButton_Settings:SetBackdropBorderColor(0,0,0,0)
	MicroMenuButton_Settings:SetAlpha(1)
	MicroMenuButton_Settings:Show()
	
	local MicroMenuButton_Settings_Clicker = LUI:CreateMeAFrame("BUTTON","MicroMenuButton_Settings_Clicker",MicroMenuButton_Settings,30,25,1,"BACKGROUND",2,"CENTER",MicroMenuButton_Settings,"CENTER",-2,0,1)
	MicroMenuButton_Settings_Clicker:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
				  tile=false, tileSize = 0, edgeSize = 1,
				  insets = { left = 0, right = 0, top = 0, bottom = 0}});
	MicroMenuButton_Settings_Clicker:SetBackdropColor(0,0,0,1)
	MicroMenuButton_Settings_Clicker:SetBackdropBorderColor(0,0,0,0)
	MicroMenuButton_Settings_Clicker:SetFrameStrata("BACKGROUND")
	MicroMenuButton_Settings_Clicker:SetFrameLevel(2)
	MicroMenuButton_Settings_Clicker:SetAlpha(0)
	MicroMenuButton_Settings_Clicker:Show()
	
	MicroMenuButton_Settings_Clicker:RegisterForClicks("LeftButtonUp", "RightButtonUp");

	local MicroMenuButton_Settings_Clicker_State = false
	
	MicroMenuButton_Settings_Clicker:SetScript("OnEnter", function(self)
		MicroMenuButton_Settings_Clicker:SetAlpha(1)
		MicroMenuButton_Settings_Clicker_State = true
		GameTooltip:SetOwner(MicroMenuButton_Settings_Clicker, "ANCHOR_NONE ",40,-90)
		GameTooltip:SetText("LUI Options")
		GameTooltip:AddLine("Left Click: LUI Option Panel", 1,1,1)
		GameTooltip:AddLine("Right Click: WoW Option Panel", 1,1,1)
		GameTooltip:Show()
	end)

	MicroMenuButton_Settings_Clicker:SetScript("OnLeave", function(self)
		MicroMenuButton_Settings_Clicker:SetAlpha(0)
		MicroMenuButton_Settings_Clicker_State = false
		GameTooltip:Hide()
	end)
	
	MicroMenuButton_Settings_Clicker:SetScript("OnClick", function(self, button)
		if button == "RightButton" then
			if GameMenuFrame:IsShown() then
				HideUIPanel(GameMenuFrame)
			else
				ShowUIPanel(GameMenuFrame)
			end
		else
			LUI:Open()
		end
	end)
	
	MicroMenuButton_Settings_Clicker:SetScript("OnUpdate", function(self)
		if MicroMenuButton_Settings_Clicker_State == false then
			if GameMenuFrame:IsShown() or AceConfigDialog.OpenFrames.LUI then
				MicroMenuButton_Settings_Clicker:SetAlpha(1)
			else
				MicroMenuButton_Settings_Clicker:SetAlpha(0)
			end
		end
	end)
	
	local MicroMenuButton_GM = LUI:CreateMeAFrame("FRAME","MicroMenuButton_GM",MicroMenuButton_Settings,64,64,1,"BACKGROUND",3,"LEFT",MicroMenuButton_Settings,"LEFT",-33,0,1)
	MicroMenuButton_GM:SetBackdrop({bgFile = fdir.."micro_gm",
				  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
				  tile=false, tileSize = 0, edgeSize = 1,
				  insets = { left = 0, right = 0, top = 0, bottom = 0}});
	--MicroMenuButton_GM:SetBackdropColor(0.6,0.9,1,1)
	MicroMenuButton_GM:SetBackdropColor(micro_r, micro_g, micro_b,1)
	MicroMenuButton_GM:SetBackdropBorderColor(0,0,0,0)
	MicroMenuButton_GM:SetAlpha(1)
	MicroMenuButton_GM:Show()
	
	local MicroMenuButton_GM_Clicker = LUI:CreateMeAFrame("BUTTON","MicroMenuButton_GM_Clicker",MicroMenuButton_GM,30,25,1,"BACKGROUND",2,"CENTER",MicroMenuButton_GM,"CENTER",-2,0,1)
	MicroMenuButton_GM_Clicker:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
				  tile=false, tileSize = 0, edgeSize = 1,
				  insets = { left = 0, right = 0, top = 0, bottom = 0}});
	MicroMenuButton_GM_Clicker:SetBackdropColor(0,0,0,1)
	MicroMenuButton_GM_Clicker:SetBackdropBorderColor(0,0,0,0)
	MicroMenuButton_GM_Clicker:SetFrameStrata("BACKGROUND")
	MicroMenuButton_GM_Clicker:SetFrameLevel(2)
	MicroMenuButton_GM_Clicker:SetAlpha(0)
	MicroMenuButton_GM_Clicker:Show()
	
	local MicroMenuButton_GM_Clicker_State = false
	
	MicroMenuButton_GM_Clicker:SetScript("OnEnter", function(self)
		MicroMenuButton_GM_Clicker:SetAlpha(1)
		MicroMenuButton_GM_Clicker_State = true
		GameTooltip:SetOwner(MicroMenuButton_GM_Clicker, "ANCHOR_NONE ",40,-90)
		GameTooltip:SetText("Help Request")
		GameTooltip:AddLine("Show/Hide the Help Request Frame", 1, 1, 1)
		GameTooltip:Show()
	end)
		
	MicroMenuButton_GM_Clicker:SetScript("OnLeave", function(self)
		if not HelpFrame:IsShown() then
			MicroMenuButton_GM_Clicker:SetAlpha(0)
		end
		MicroMenuButton_GM_Clicker_State = false
		GameTooltip:Hide()
	end)
	
	MicroMenuButton_GM_Clicker:SetScript("OnClick", function(self)
		ToggleHelpFrame()
	end)
	
	HelpFrame:HookScript("OnShow", function(self)
		MicroMenuButton_GM_Clicker:SetAlpha(1)
	end)
	
	HelpFrame:HookScript("OnHide", function(self)
		if MicroMenuButton_GM_Clicker_State == false then
			MicroMenuButton_GM_Clicker:SetAlpha(0)
		end
	end)
	
	local MicroMenuButton_LFG = LUI:CreateMeAFrame("FRAME","MicroMenuButton_LFG",MicroMenuButton_GM,64,64,1,"BACKGROUND",3,"LEFT",MicroMenuButton_GM,"LEFT",-33,0,1)
	MicroMenuButton_LFG:SetBackdrop({bgFile = fdir.."micro_lfg",
				  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
				  tile=false, tileSize = 0, edgeSize = 1,
				  insets = { left = 0, right = 0, top = 0, bottom = 0}});
	--MicroMenuButton_LFG:SetBackdropColor(0.6,0.9,1,1)
	MicroMenuButton_LFG:SetBackdropColor(micro_r, micro_g, micro_b,1)
	MicroMenuButton_LFG:SetBackdropBorderColor(0,0,0,0)
	MicroMenuButton_LFG:SetAlpha(1)
	MicroMenuButton_LFG:Show()
	
	local MicroMenuButton_LFG_Clicker = LUI:CreateMeAFrame("BUTTON","MicroMenuButton_LFG_Clicker",MicroMenuButton_LFG,30,25,1,"BACKGROUND",2,"CENTER",MicroMenuButton_LFG,"CENTER",-2,0,1)
	MicroMenuButton_LFG_Clicker:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
				  tile=false, tileSize = 0, edgeSize = 1,
				  insets = { left = 0, right = 0, top = 0, bottom = 0}});
	MicroMenuButton_LFG_Clicker:SetBackdropColor(0,0,0,1)
	MicroMenuButton_LFG_Clicker:SetBackdropBorderColor(0,0,0,0)
	MicroMenuButton_LFG_Clicker:SetFrameStrata("BACKGROUND")
	MicroMenuButton_LFG_Clicker:SetFrameLevel(2)
	MicroMenuButton_LFG_Clicker:SetAlpha(0)
	MicroMenuButton_LFG_Clicker:Show()
	
	local MicroMenuButton_LFG_Clicker_State = false
	
	MicroMenuButton_LFG_Clicker:SetScript("OnEnter", function(self)
		MicroMenuButton_LFG_Clicker:SetAlpha(1)
		MicroMenuButton_LFG_Clicker_State = true
		GameTooltip:SetOwner(MicroMenuButton_LFG_Clicker, "ANCHOR_NONE ",40,-90)
		GameTooltip:SetText("Dungeon Finder")
		GameTooltip:AddLine("Dungeons/Instances...", 1, 1, 1)
		if UnitLevel("player") < 15 then
			GameTooltip:AddLine("Available with Level 15", 1, 0, 0)
		end
		GameTooltip:Show()
	end)
		
	MicroMenuButton_LFG_Clicker:SetScript("OnLeave", function(self)
		if not LFDParentFrame:IsShown() then
			MicroMenuButton_LFG_Clicker:SetAlpha(0)
		end
		MicroMenuButton_LFG_Clicker_State = false
		GameTooltip:Hide()
	end)
	
	MicroMenuButton_LFG_Clicker:SetScript("OnClick", function(self)
		if UnitLevel("player") >= 15 then
			if LFDParentFrame:IsShown() then
				HideUIPanel(LFDParentFrame)
			else
				ShowUIPanel(LFDParentFrame)
			end
		end
	end)
	
	LFDParentFrame:HookScript("OnShow", function(self)
		MicroMenuButton_LFG_Clicker:SetAlpha(1)
	end)
	
	LFDParentFrame:HookScript("OnHide", function(self)
		if MicroMenuButton_LFG_Clicker_State == false then
			MicroMenuButton_LFG_Clicker:SetAlpha(0)
		end
	end)
	
	local MicroMenuButton_PVP = LUI:CreateMeAFrame("FRAME","MicroMenuButton_PVP",MicroMenuButton_LFG,64,64,1,"BACKGROUND",3,"LEFT",MicroMenuButton_LFG,"LEFT",-33,0,1)
	MicroMenuButton_PVP:SetBackdrop({bgFile = fdir.."micro_pvp",
				  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
				  tile=false, tileSize = 0, edgeSize = 1,
				  insets = { left = 0, right = 0, top = 0, bottom = 0}});
	--MicroMenuButton_PVP:SetBackdropColor(0.6,0.9,1,1)
	MicroMenuButton_PVP:SetBackdropColor(micro_r, micro_g, micro_b,1)
	MicroMenuButton_PVP:SetBackdropBorderColor(0,0,0,0)
	MicroMenuButton_PVP:SetAlpha(1)
	MicroMenuButton_PVP:Show()
	
	local MicroMenuButton_PVP_Clicker = LUI:CreateMeAFrame("BUTTON","MicroMenuButton_PVP_Clicker",MicroMenuButton_PVP,30,25,1,"BACKGROUND",2,"CENTER",MicroMenuButton_PVP,"CENTER",-2,0,1)
	MicroMenuButton_PVP_Clicker:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
				  tile=false, tileSize = 0, edgeSize = 1,
				  insets = { left = 0, right = 0, top = 0, bottom = 0}});
	MicroMenuButton_PVP_Clicker:SetBackdropColor(0,0,0,1)
	MicroMenuButton_PVP_Clicker:SetBackdropBorderColor(0,0,0,0)
	MicroMenuButton_PVP_Clicker:SetFrameStrata("BACKGROUND")
	MicroMenuButton_PVP_Clicker:SetFrameLevel(2)
	MicroMenuButton_PVP_Clicker:SetAlpha(0)
	MicroMenuButton_PVP_Clicker:Show()
	
	local MicroMenuButton_PVP_Clicker_State = false
	
	MicroMenuButton_PVP_Clicker:SetScript("OnEnter", function(self)
		MicroMenuButton_PVP_Clicker:SetAlpha(1)
		MicroMenuButton_PVP_Clicker_State = true
		GameTooltip:SetOwner(MicroMenuButton_PVP_Clicker, "ANCHOR_NONE ",40,-90)
		GameTooltip:SetText("PvP")
		GameTooltip:AddLine("Arena/Battlegrounds...", 1, 1, 1)
		if UnitLevel("player") < 10 then
			GameTooltip:AddLine("Available with Level 10", 1, 0, 0)
		end
		GameTooltip:Show()
	end)
		
	MicroMenuButton_PVP_Clicker:SetScript("OnLeave", function(self)
		if not PVPFrame:IsShown() then
			MicroMenuButton_PVP_Clicker:SetAlpha(0)
		end
		MicroMenuButton_PVP_Clicker_State = false
		GameTooltip:Hide()
	end)
	
	MicroMenuButton_PVP_Clicker:SetScript("OnClick", function(self)
		if UnitLevel("player") >= 10 then
			if PVPFrame:IsShown() then
				HideUIPanel(PVPFrame)
			else
				ShowUIPanel(PVPFrame)
			end
		end
	end)
	
	PVPFrame:HookScript("OnShow", function(self)
		MicroMenuButton_PVP_Clicker:SetAlpha(1)
	end)
	
	PVPFrame:HookScript("OnHide", function(self)
		if MicroMenuButton_PVP_Clicker_State == false then
			MicroMenuButton_PVP_Clicker:SetAlpha(0)
		end
	end)
	
	local MicroMenuButton_Guild = LUI:CreateMeAFrame("FRAME","MicroMenuButton_Guild",MicroMenuButton_PVP,64,64,1,"BACKGROUND",3,"LEFT",MicroMenuButton_PVP,"LEFT",-33,0,1)
	MicroMenuButton_Guild:SetBackdrop({bgFile = fdir.."micro_guild",
				  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
				  tile=false, tileSize = 0, edgeSize = 1,
				  insets = { left = 0, right = 0, top = 0, bottom = 0}});
	--MicroMenuButton_Guild:SetBackdropColor(0.6,0.9,1,1)
	MicroMenuButton_Guild:SetBackdropColor(micro_r, micro_g, micro_b,1)
	MicroMenuButton_Guild:SetBackdropBorderColor(0,0,0,0)
	MicroMenuButton_Guild:SetAlpha(1)
	MicroMenuButton_Guild:Show()
	
	local MicroMenuButton_Guild_Clicker = LUI:CreateMeAFrame("BUTTON","MicroMenuButton_Guild_Clicker",MicroMenuButton_Guild,30,25,1,"BACKGROUND",2,"CENTER",MicroMenuButton_Guild,"CENTER",-2,0,1)
	MicroMenuButton_Guild_Clicker:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
				  tile=false, tileSize = 0, edgeSize = 1,
				  insets = { left = 0, right = 0, top = 0, bottom = 0}});
	MicroMenuButton_Guild_Clicker:SetBackdropColor(0,0,0,1)
	MicroMenuButton_Guild_Clicker:SetBackdropBorderColor(0,0,0,0)
	MicroMenuButton_Guild_Clicker:SetFrameStrata("BACKGROUND")
	MicroMenuButton_Guild_Clicker:SetFrameLevel(2)
	MicroMenuButton_Guild_Clicker:SetAlpha(0)
	MicroMenuButton_Guild_Clicker:Show()
	
	local MicroMenuButton_Guild_Clicker_State = false
	
	MicroMenuButton_Guild_Clicker:RegisterForClicks("LeftButtonUp", "RightButtonUp");
	
	MicroMenuButton_Guild_Clicker:SetScript("OnEnter", function(self)
		MicroMenuButton_Guild_Clicker:SetAlpha(1)
		MicroMenuButton_Guild_Clicker_State = true
		GameTooltip:SetOwner(MicroMenuButton_Guild_Clicker, "ANCHOR_NONE ",40,-90)
		GameTooltip:SetText("Guild/Friends")
		GameTooltip:AddLine("Left Click: Guild Frame", 1, 1, 1)
		GameTooltip:AddLine("Right Click: Friends Frame", 1, 1, 1)
		GameTooltip:Show()
	end)
		
	MicroMenuButton_Guild_Clicker:SetScript("OnLeave", function(self)
		if not FriendsFrame:IsShown() and not GuildFrame:IsShown() then
			MicroMenuButton_Guild_Clicker:SetAlpha(0)
		end
		MicroMenuButton_Guild_Clicker_State = false
		GameTooltip:Hide()
	end)
	
	MicroMenuButton_Guild_Clicker:SetScript("OnClick", function(self, button)
		if button == "RightButton" then
			if FriendsFrame:IsShown() then
				HideUIPanel(FriendsFrame)
			else
				ShowUIPanel(FriendsFrame)
			end
		else
			if GuildFrame:IsShown() then
				HideUIPanel(GuildFrame)
			else
				if IsInGuild() then ShowUIPanel(GuildFrame) end
			end
		end
	end)
	
	FriendsFrame:HookScript("OnShow", function(self)
		MicroMenuButton_Guild_Clicker:SetAlpha(1)
	end)
	
	FriendsFrame:HookScript("OnHide", function(self)
		if not GuildFrame:IsShown() and MicroMenuButton_Guild_Clicker_State == false then
			MicroMenuButton_Guild_Clicker:SetAlpha(0)
		end
	end)
	
	if not GuildFrame then LoadAddOn("Blizzard_GuildUI") end
	
	GuildFrame:HookScript("OnShow", function(self)
		MicroMenuButton_Guild_Clicker:SetAlpha(1)
	end)
	
	GuildFrame:HookScript("OnHide", function(self)
		if not FriendsFrame:IsShown() and MicroMenuButton_Guild_Clicker_State == false then
			MicroMenuButton_Guild_Clicker:SetAlpha(0)
		end
	end)
	
	local MicroMenuButton_Quests = LUI:CreateMeAFrame("FRAME","MicroMenuButton_Quests",MicroMenuButton_Guild,64,64,1,"BACKGROUND",3,"LEFT",MicroMenuButton_Guild,"LEFT",-33,0,1)
	MicroMenuButton_Quests:SetBackdrop({bgFile = fdir.."micro_quests",
				  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
				  tile=false, tileSize = 0, edgeSize = 1,
				  insets = { left = 0, right = 0, top = 0, bottom = 0}});
	--MicroMenuButton_Quests:SetBackdropColor(0.6,0.9,1,1)
	MicroMenuButton_Quests:SetBackdropColor(micro_r, micro_g, micro_b,1)
	MicroMenuButton_Quests:SetBackdropBorderColor(0,0,0,0)
	MicroMenuButton_Quests:SetAlpha(1)
	MicroMenuButton_Quests:Show()
	
	local MicroMenuButton_Quests_Clicker = LUI:CreateMeAFrame("BUTTON","MicroMenuButton_Quests_Clicker",MicroMenuButton_Quests,30,25,1,"BACKGROUND",2,"CENTER",MicroMenuButton_Quests,"CENTER",-2,0,1)
	MicroMenuButton_Quests_Clicker:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
				  tile=false, tileSize = 0, edgeSize = 1,
				  insets = { left = 0, right = 0, top = 0, bottom = 0}});
	MicroMenuButton_Quests_Clicker:SetBackdropColor(0,0,0,1)
	MicroMenuButton_Quests_Clicker:SetBackdropBorderColor(0,0,0,0)
	MicroMenuButton_Quests_Clicker:SetFrameStrata("BACKGROUND")
	MicroMenuButton_Quests_Clicker:SetFrameLevel(2)
	MicroMenuButton_Quests_Clicker:SetAlpha(0)
	MicroMenuButton_Quests_Clicker:Show()
	
	local MicroMenuButton_Quests_Clicker_State = false
	
	MicroMenuButton_Quests_Clicker:SetScript("OnEnter", function(self)
		MicroMenuButton_Quests_Clicker:SetAlpha(1)
		MicroMenuButton_Quests_Clicker_State = true
		GameTooltip:SetOwner(MicroMenuButton_Quests_Clicker, "ANCHOR_NONE ",40,-90)
		GameTooltip:SetText("Quest Log")
		GameTooltip:AddLine("Show/Hide your Quest Log", 1, 1, 1)
		GameTooltip:Show()
	end)
		
	MicroMenuButton_Quests_Clicker:SetScript("OnLeave", function(self)
		if not QuestLogFrame:IsShown() then
			MicroMenuButton_Quests_Clicker:SetAlpha(0)
		end
		MicroMenuButton_Quests_Clicker_State = false
		GameTooltip:Hide()
	end)
	
	MicroMenuButton_Quests_Clicker:SetScript("OnClick", function(self)
		if QuestLogFrame:IsShown() then
			HideUIPanel(QuestLogFrame)
		else
			ShowUIPanel(QuestLogFrame)
		end
	end)
	
	QuestLogFrame:HookScript("OnShow", function(self)
		MicroMenuButton_Quests_Clicker:SetAlpha(1)
	end)
	
	QuestLogFrame:HookScript("OnHide", function(self)
		if MicroMenuButton_Quests_Clicker_State == false then
			MicroMenuButton_Quests_Clicker:SetAlpha(0)
		end
	end)
	
	local MicroMenuButton_AC = LUI:CreateMeAFrame("FRAME","MicroMenuButton_AC",MicroMenuButton_Quests,64,64,1,"BACKGROUND",3,"LEFT",MicroMenuButton_Quests,"LEFT",-33,0,1)
	MicroMenuButton_AC:SetBackdrop({bgFile = fdir.."micro_achievements",
				  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
				  tile=false, tileSize = 0, edgeSize = 1,
				  insets = { left = 0, right = 0, top = 0, bottom = 0}});
	--MicroMenuButton_AC:SetBackdropColor(0.6,0.9,1,1)
	MicroMenuButton_AC:SetBackdropColor(micro_r, micro_g, micro_b,1)
	MicroMenuButton_AC:SetBackdropBorderColor(0,0,0,0)
	MicroMenuButton_AC:SetAlpha(1)
	MicroMenuButton_AC:Show()
	
	local MicroMenuButton_AC_Clicker = LUI:CreateMeAFrame("BUTTON","MicroMenuButton_AC_Clicker",MicroMenuButton_AC,30,25,1,"BACKGROUND",2,"CENTER",MicroMenuButton_AC,"CENTER",-2,0,1)
	MicroMenuButton_AC_Clicker:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
				  tile=false, tileSize = 0, edgeSize = 1,
				  insets = { left = 0, right = 0, top = 0, bottom = 0}});
	MicroMenuButton_AC_Clicker:SetBackdropColor(0,0,0,1)
	MicroMenuButton_AC_Clicker:SetBackdropBorderColor(0,0,0,0)
	MicroMenuButton_AC_Clicker:SetFrameStrata("BACKGROUND")
	MicroMenuButton_AC_Clicker:SetFrameLevel(2)
	MicroMenuButton_AC_Clicker:SetAlpha(0)
	MicroMenuButton_AC_Clicker:Show()
	
	local MicroMenuButton_AC_Clicker_State = false
	
	MicroMenuButton_AC_Clicker:SetScript("OnEnter", function(self)
		MicroMenuButton_AC_Clicker:SetAlpha(1)
		MicroMenuButton_AC_Clicker_State = true
		GameTooltip:SetOwner(MicroMenuButton_AC_Clicker, "ANCHOR_NONE ",40,-90)
		GameTooltip:SetText("Achievements")
		GameTooltip:AddLine("Show/Hide your Achievements", 1, 1, 1)
		GameTooltip:Show()
	end)
		
	MicroMenuButton_AC_Clicker:SetScript("OnLeave", function(self)
		MicroMenuButton_AC_Clicker:SetAlpha(0)
		MicroMenuButton_AC_Clicker_State = false
		GameTooltip:Hide()
	end)
	
	MicroMenuButton_AC_Clicker:SetScript("OnClick", function(self)
		ToggleAchievementFrame()
	end)
	
	MicroMenuButton_AC_Clicker:SetScript("OnUpdate", function(self)
		if IsAddOnLoaded("Blizzard_AchievementUI") then
			if MicroMenuButton_AC_Clicker_State == false then
				if AchievementFrame:IsShown() then
					MicroMenuButton_AC_Clicker:SetAlpha(1)
				else
					MicroMenuButton_AC_Clicker:SetAlpha(0)
				end
			end
		end
	end)
	
	local MicroMenuButton_Talents = LUI:CreateMeAFrame("FRAME","MicroMenuButton_Talents",MicroMenuButton_AC,64,64,1,"BACKGROUND",3,"LEFT",MicroMenuButton_AC,"LEFT",-33,0,1)
	MicroMenuButton_Talents:SetBackdrop({bgFile = fdir.."micro_talents",
				  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
				  tile=false, tileSize = 0, edgeSize = 1,
				  insets = { left = 0, right = 0, top = 0, bottom = 0}});
	--MicroMenuButton_Talents:SetBackdropColor(0.6,0.9,1,1)
	MicroMenuButton_Talents:SetBackdropColor(micro_r, micro_g, micro_b,1)
	MicroMenuButton_Talents:SetBackdropBorderColor(0,0,0,0)
	MicroMenuButton_Talents:SetAlpha(1)
	MicroMenuButton_Talents:Show()
	
	local MicroMenuButton_Talents_Clicker = LUI:CreateMeAFrame("BUTTON","MicroMenuButton_Talents_Clicker",MicroMenuButton_Talents,30,25,1,"BACKGROUND",2,"CENTER",MicroMenuButton_Talents,"CENTER",-2,0,1)
	MicroMenuButton_Talents_Clicker:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
				  tile=false, tileSize = 0, edgeSize = 1,
				  insets = { left = 0, right = 0, top = 0, bottom = 0}});
	MicroMenuButton_Talents_Clicker:SetBackdropColor(0,0,0,1)
	MicroMenuButton_Talents_Clicker:SetBackdropBorderColor(0,0,0,0)
	MicroMenuButton_Talents_Clicker:SetFrameStrata("BACKGROUND")
	MicroMenuButton_Talents_Clicker:SetFrameLevel(2)
	MicroMenuButton_Talents_Clicker:SetAlpha(0)
	MicroMenuButton_Talents_Clicker:Show()
	
	local MicroMenuButton_Talents_Clicker_State = false
	
	MicroMenuButton_Talents_Clicker:SetScript("OnEnter", function(self)
		MicroMenuButton_Talents_Clicker:SetAlpha(1)
		MicroMenuButton_Talents_Clicker_State = true
		GameTooltip:SetOwner(MicroMenuButton_Talents_Clicker, "ANCHOR_NONE ",40,-90)
		GameTooltip:SetText("Talents")
		GameTooltip:AddLine("Show/Hide your Talent Frame", 1, 1, 1)
		if UnitLevel("player") < 10 then
			GameTooltip:AddLine("Available with Level 10", 1, 0, 0)
		end
		GameTooltip:Show()
	end)
		
	MicroMenuButton_Talents_Clicker:SetScript("OnLeave", function(self)
		if not PlayerTalentFrame:IsShown() then
			MicroMenuButton_Talents_Clicker:SetAlpha(0)
		end
		MicroMenuButton_Talents_Clicker_State = false
		GameTooltip:Hide()
	end)
	
	MicroMenuButton_Talents_Clicker:SetScript("OnClick", function(self)
		if UnitLevel("player") >= 10 then
			if PlayerTalentFrame:IsShown() then
				HideUIPanel(PlayerTalentFrame)
			else
				ShowUIPanel(PlayerTalentFrame)
			end
		end
	end)
	
	if not PlayerTalentFrame then
		LoadAddOn("Blizzard_TalentUI")
		-- Fix for Events firing before TalentFrame is fully loaded (aka: blizz fail with patch 4.0.6)
		ShowUIPanel(PlayerTalentFrame)
		HideUIPanel(PlayerTalentFrame)
	end
	
	PlayerTalentFrame:HookScript("OnShow", function(self)
		MicroMenuButton_Talents_Clicker:SetAlpha(1)
	end)
	
	PlayerTalentFrame:HookScript("OnHide", function(self)
		if MicroMenuButton_Talents_Clicker_State == false then
			MicroMenuButton_Talents_Clicker:SetAlpha(0)
		end
	end)
	
	local MicroMenuButton_Spellbook = LUI:CreateMeAFrame("FRAME","MicroMenuButton_Spellbook",MicroMenuButton_Talents,64,64,1,"BACKGROUND",3,"LEFT",MicroMenuButton_Talents,"LEFT",-33,0,1)
	MicroMenuButton_Spellbook:SetBackdrop({bgFile = fdir.."micro_spellbook",
				  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
				  tile=false, tileSize = 0, edgeSize = 1,
				  insets = { left = 0, right = 0, top = 0, bottom = 0}});
	--MicroMenuButton_Spellbook:SetBackdropColor(0.6,0.9,1,1)
	MicroMenuButton_Spellbook:SetBackdropColor(micro_r, micro_g, micro_b,1)
	MicroMenuButton_Spellbook:SetBackdropBorderColor(0,0,0,0)
	MicroMenuButton_Spellbook:SetAlpha(1)
	MicroMenuButton_Spellbook:Show()
	
	local MicroMenuButton_Spellbook_Clicker = LUI:CreateMeAFrame("BUTTON","MicroMenuButton_Spellbook_Clicker",MicroMenuButton_Spellbook,30,25,1,"BACKGROUND",2,"CENTER",MicroMenuButton_Spellbook,"CENTER",-2,0,1)
	MicroMenuButton_Spellbook_Clicker:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
				  tile=false, tileSize = 0, edgeSize = 1,
				  insets = { left = 0, right = 0, top = 0, bottom = 0}});
	MicroMenuButton_Spellbook_Clicker:SetBackdropColor(0,0,0,1)
	MicroMenuButton_Spellbook_Clicker:SetBackdropBorderColor(0,0,0,0)
	MicroMenuButton_Spellbook_Clicker:SetFrameStrata("BACKGROUND")
	MicroMenuButton_Spellbook_Clicker:SetFrameLevel(2)
	MicroMenuButton_Spellbook_Clicker:SetAlpha(0)
	MicroMenuButton_Spellbook_Clicker:Show()
	
	local MicroMenuButton_Spellbook_Clicker_State = false
	
	MicroMenuButton_Spellbook_Clicker:SetScript("OnEnter", function(self)
		MicroMenuButton_Spellbook_Clicker:SetAlpha(1)
		MicroMenuButton_Spellbook_Clicker_State = true
		GameTooltip:SetOwner(MicroMenuButton_Spellbook_Clicker, "ANCHOR_NONE ",40,-90)
		GameTooltip:SetText("Spellbook & Abilities")
		GameTooltip:AddLine("Show/Hide your Spellbook", 1, 1, 1)
		GameTooltip:Show()
	end)
		
	MicroMenuButton_Spellbook_Clicker:SetScript("OnLeave", function(self)
		if not SpellBookFrame:IsShown() then
			MicroMenuButton_Spellbook_Clicker:SetAlpha(0)
		end
		MicroMenuButton_Spellbook_Clicker_State = false
		GameTooltip:Hide()
	end)
	
	MicroMenuButton_Spellbook_Clicker:SetScript("OnClick", function(self)
		if InCombatLockdown() then return end
		if SpellBookFrame:IsShown() then
			HideUIPanel(SpellBookFrame)
		else
			ShowUIPanel(SpellBookFrame)
		end
	end)
	
	SpellBookFrame:HookScript("OnShow", function(self)
		MicroMenuButton_Spellbook_Clicker:SetAlpha(1)
	end)
	
	SpellBookFrame:HookScript("OnHide", function(self)
		if MicroMenuButton_Spellbook_Clicker_State == false then
			MicroMenuButton_Spellbook_Clicker:SetAlpha(0)
		end
	end)
	
	local MicroMenuButton_Player = LUI:CreateMeAFrame("FRAME","MicroMenuButton_Player",MicroMenuButton_Spellbook,64,64,1,"BACKGROUND",3,"LEFT",MicroMenuButton_Spellbook,"LEFT",-33,0,1)
	MicroMenuButton_Player:SetBackdrop({bgFile = fdir.."micro_player",
				  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
				  tile=false, tileSize = 0, edgeSize = 1,
				  insets = { left = 0, right = 0, top = 0, bottom = 0}});
	--MicroMenuButton_Player:SetBackdropColor(0.6,0.9,1,1)
	MicroMenuButton_Player:SetBackdropColor(micro_r, micro_g, micro_b,1)
	MicroMenuButton_Player:SetBackdropBorderColor(0,0,0,0)
	MicroMenuButton_Player:SetAlpha(1)
	MicroMenuButton_Player:Show()
	
	local MicroMenuButton_Player_Clicker = LUI:CreateMeAFrame("BUTTON","MicroMenuButton_Player_Clicker",MicroMenuButton_Player,42,25,1,"BACKGROUND",2,"CENTER",MicroMenuButton_Player,"CENTER",-8,0,1)
	MicroMenuButton_Player_Clicker:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				  edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',
				  tile=false, tileSize = 0, edgeSize = 1,
				  insets = { left = 0, right = 0, top = 0, bottom = 0}});
	MicroMenuButton_Player_Clicker:SetBackdropColor(0,0,0,1)
	MicroMenuButton_Player_Clicker:SetBackdropBorderColor(0,0,0,0)
	MicroMenuButton_Player_Clicker:SetFrameStrata("BACKGROUND")
	MicroMenuButton_Player_Clicker:SetFrameLevel(2)
	MicroMenuButton_Player_Clicker:SetAlpha(0)
	MicroMenuButton_Player_Clicker:Show()
	
	local MicroMenuButton_Player_Clicker_State = false
	
	MicroMenuButton_Player_Clicker:SetScript("OnEnter", function(self)
		MicroMenuButton_Player_Clicker:SetAlpha(1)
		MicroMenuButton_Player_Clicker_State = true
		GameTooltip:SetOwner(MicroMenuButton_Player_Clicker, "ANCHOR_NONE ",40,-90)
		GameTooltip:SetText("Character Info")
		GameTooltip:AddLine("Show/Hide your Character Pane", 1, 1, 1)
		GameTooltip:Show()
	end)
		
	MicroMenuButton_Player_Clicker:SetScript("OnLeave", function(self)
		if not CharacterFrame:IsShown() then
			MicroMenuButton_Player_Clicker:SetAlpha(0)
		end
		MicroMenuButton_Player_Clicker_State = false
		GameTooltip:Hide()
	end)
	
	MicroMenuButton_Player_Clicker:SetScript("OnClick", function(self)
		if CharacterFrame:IsShown() then
			HideUIPanel(CharacterFrame)
		else
			ShowUIPanel(CharacterFrame)
		end
	end)
	
	CharacterFrame:HookScript("OnShow", function(self)
		MicroMenuButton_Player_Clicker:SetAlpha(1)
	end)
	
	CharacterFrame:HookScript("OnHide", function(self)
		if MicroMenuButton_Player_Clicker_State == false then
			MicroMenuButton_Player_Clicker:SetAlpha(0)
		end
	end)
	
	self:SetMicroMenuPosition()
	
	-- little hack for the questframe
	local point, relframe, relpoint, x, y = QuestLogFrame:GetPoint()
	QuestLogFrame:ClearAllPoints()
	QuestLogFrame:SetPoint(point, relframe, relpoint, x, -105)
	
	-- talent alert frame
	TalentMicroButtonAlert:ClearAllPoints()
	TalentMicroButtonAlert:SetPoint("TOP", MicroMenuButton_Talents, "BOTTOM")
	
	TalentMicroButtonAlertBg:SetGradientAlpha("VERTICAL", micro_r/4, micro_g/4, micro_b/4, 1, 0, 0, 0, 1)
	
	TalentMicroButtonAlertText:SetFont(LSM:Fetch("font", "vibrocen"), 14, "NONE")
	
	TalentMicroButtonAlertArrow:ClearAllPoints()
	TalentMicroButtonAlertArrow:SetPoint("BOTTOM", TalentMicroButtonAlert, "TOP", 0, -6)
	
	TalentMicroButtonAlertArrowGlow:SetTexCoord(0.40625000, 0.66015625, 0.82812500, 0.77343750)
	TalentMicroButtonAlertArrowGlow:SetVertexColor(r, g, b, 0.5)
	TalentMicroButtonAlertArrowGlow:ClearAllPoints()
	TalentMicroButtonAlertArrowGlow:SetPoint("BOTTOM", TalentMicroButtonAlertArrow, "BOTTOM", 0, 0)
	
	TalentMicroButtonAlertArrowArrow:SetTexCoord(0.78515625, 0.99218750, 0.58789063, 0.54687500)
	TalentMicroButtonAlertArrowArrow:SetVertexColor(micro_r, micro_g, micro_b)
	
	TalentMicroButtonAlertGlowTopLeft:SetVertexColor(micro_r, micro_g, micro_b)
	TalentMicroButtonAlertGlowTopRight:SetVertexColor(micro_r, micro_g, micro_b)
	TalentMicroButtonAlertGlowBottomLeft:SetVertexColor(micro_r, micro_g, micro_b)
	TalentMicroButtonAlertGlowBottomRight:SetVertexColor(micro_r, micro_g, micro_b)
	
	TalentMicroButtonAlertGlowTop:SetVertexColor(micro_r, micro_g, micro_b)
	TalentMicroButtonAlertGlowBottom:SetVertexColor(micro_r, micro_g, micro_b)
	TalentMicroButtonAlertGlowLeft:SetVertexColor(micro_r, micro_g, micro_b)
	TalentMicroButtonAlertGlowRight:SetVertexColor(micro_r, micro_g, micro_b)
end

local defaults = {
	Micromenu = {
		X = "0",
		Y = "-1",
		NaviX = "-150",
		NaviY = "6",
	}
}

function module:LoadOptions()
	local options = {
		Micromenu = {
			name = "MicroMenu",
			type = "group",
			order = 9,
			args = {
				MicroMenuPosition = {
					name = "Micro Menu",
					type = "group",
					order = 1,
					guiInline = true,
					args = {
						MMX = {
							name = "X Value",
							desc = "X Value for your MicroMenu.\n\nNote:\nPositive values = right\nNegativ values = left\nDefault: "..LUI.defaults.profile.Frames.Micromenu.X,
							type = "input",
							get = function() return db.Frames.Micromenu.X end,
							set = function(self,MMX)
									if MMX == nil or MMX == "" then
										MMX = "0"
									end
									db.Frames.Micromenu.X = MMX
									
									local Micromenu = LUI:GetModule("Micromenu")
									Micromenu:SetMicroMenuPosition()
								end,
							order = 1,
						},
						MMY = {
							name = "Y Value",
							desc = "Y Value for your MicroMenu.\n\nNote:\nPositive values = up\nNegativ values = down\nDefault: "..LUI.defaults.profile.Frames.Micromenu.Y,
							type = "input",
							get = function() return db.Frames.Micromenu.Y end,
							set = function(self,MMY)
									if MMY == nil or MMY == "" then
										MMY = "0"
									end
									db.Frames.Micromenu.Y = MMY
									
									local Micromenu = LUI:GetModule("Micromenu")
									Micromenu:SetMicroMenuPosition()
								end,
							order = 2,
						},
					},
				},
				MicroMenuNaviPosition = {
					name = "Micro Menu Navigation",
					type = "group",
					order = 2,
					guiInline = true,
					args = {
						MMNaviX = {
							name = "X Value",
							desc = "X Value for your MicroMenu Navigation Panel.\n\nNote:\nPositive values = right\nNegativ values = left\nDefault: "..LUI.defaults.profile.Frames.Micromenu.NaviX,
							type = "input",
							get = function() return db.Frames.Micromenu.NaviX end,
							set = function(self,MMNaviX)
									if MMNaviX == nil or MMNaviX == "" then
										MMNaviX = "0"
									end
									db.Frames.Micromenu.NaviX = MMNaviX
									
									local Micromenu = LUI:GetModule("Micromenu")
									Micromenu:SetMicroMenuPosition()
								end,
							order = 1,
						},
						MMNaviY = {
							name = "Y Value",
							desc = "Y Value for your MicroMenu Navigation Panel.\n\nNote:\nPositive values = up\nNegativ values = down\nDefault: "..LUI.defaults.profile.Frames.Micromenu.NaviY,
							type = "input",
							get = function() return db.Frames.Micromenu.NaviY end,
							set = function(self,MMNaviY)
									if MMNaviY == nil or MMNaviY == "" then
										MMNaviY = "0"
									end
									db.Frames.Micromenu.NaviY = MMNaviY
									
									local Micromenu = LUI:GetModule("Micromenu")
									Micromenu:SetMicroMenuPosition()
								end,
							order = 2,
						},
					},
				},
			},
		},
	}
	
	return options
end

function module:OnInitialize()
	LUI:MergeDefaults(LUI.db.defaults.profile.Frames, defaults)
	LUI:RefreshDefaults()
	LUI:Refresh()
	
	self.db = LUI.db.profile
	db = self.db
	
	LUI:RegisterFrame(self) -- Look into how to code after changing frame and panels
end

function module:OnEnable()	
	RaidMenu = LUI:GetModule("RaidMenu", true)
	self:SetMicroMenu()
end

function module:OnDisable()
end