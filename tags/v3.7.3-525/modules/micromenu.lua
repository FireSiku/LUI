--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: LUI_MM.lua
	Description: Micromenu Module
	Version....: 1.5
	Rev Date...: 14/03/2012
	
	Edits:
		v1.0: Loui
		v1.1: Loui/Thaly
		v1.2: Thaly
		v1.3: Thaly
		v1.4: Xus
		v1.5: Thaly
]]

-- External references.
local addonname, LUI = ...
local module = LUI:Module("Micromenu", "AceEvent-3.0")
local Themes = LUI:Module("Themes")
local Panels = LUI:Module("Panels")
local RaidMenu = LUI:Module("RaidMenu")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local Media = LibStub("LibSharedMedia-3.0")

local db, dbd
local version = 1.5

local fdir = "Interface\\AddOns\\LUI\\media\\templates\\v3\\"

LUI.MicroMenu = {Buttons = {}}

local _, class = UnitClass("player")

function module:SetMicroMenuPosition()
	LUI.MicroMenu.Anchor:ClearAllPoints()
	LUI.MicroMenu.Anchor:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", db.NaviX, db.NaviY)

	LUI.MicroMenu.Button:ClearAllPoints()
	LUI.MicroMenu.Button:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", db.X, db.Y)
end

function module:SetColors()
	local r, g, b = unpack(Themes.db.profile.micromenu)
	local rb, gb, bb, ab = unpack(Themes.db.profile.micromenu_btn)
	local rc, gc, bc, ac = unpack(Themes.db.profile.micromenu_bg)
	local rd, gd, bd, ad = unpack(Themes.db.profile.micromenu_bg2)

	LUI.MicroMenu.Anchor:SetBackdropColor(rb, gb, bb, ab)
	LUI.MicroMenu.ButtonRight:SetBackdropColor(rb, gb, bb, ab)
	LUI.MicroMenu.ButtonLeft:SetBackdropColor(rb, gb, bb, ab)

	LUI.MicroMenu.Button:SetBackdropColor(rc, gc, bc, ac)
	LUI.MicroMenu.Button.BG:SetBackdropColor(rd, gd, bd, ad)

	LUI.MicroMenu.Buttons.Bags:SetBackdropColor(r, g, b, 1)
	LUI.MicroMenu.Buttons.Settings:SetBackdropColor(r, g, b, 1)
	LUI.MicroMenu.Buttons.GM:SetBackdropColor(r, g, b, 1)
	LUI.MicroMenu.Buttons.Pets:SetBackdropColor(r, g, b, 1)
	LUI.MicroMenu.Buttons.LFG:SetBackdropColor(r, g, b, 1)
	LUI.MicroMenu.Buttons.Journal:SetBackdropColor(r, g, b, 1)
	LUI.MicroMenu.Buttons.PVP:SetBackdropColor(r, g, b, 1)
	LUI.MicroMenu.Buttons.Guild:SetBackdropColor(r, g, b, 1)
	LUI.MicroMenu.Buttons.Quests:SetBackdropColor(r, g, b, 1)
	LUI.MicroMenu.Buttons.AC:SetBackdropColor(r, g, b, 1)
	LUI.MicroMenu.Buttons.Talents:SetBackdropColor(r, g, b, 1)
	LUI.MicroMenu.Buttons.Spellbook:SetBackdropColor(r, g, b, 1)
	LUI.MicroMenu.Buttons.Player:SetBackdropColor(r, g, b, 1)

	-- talent alert frame
	TalentMicroButtonAlertBg:SetGradientAlpha("VERTICAL", r/4, g/4, b/4, 1, 0, 0, 0, 1)

	TalentMicroButtonAlertGlow:SetVertexColor(r, g, b, 0.5)

	--TalentMicroButtonAlertArrowArrow:SetVertexColor(r, g, b)

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
	local micro_r, micro_g, micro_b = unpack(Themes.db.profile.micromenu)

	LUI.MicroMenu.Anchor = LUI:CreateMeAFrame("Frame", nil, UIParent, 128, 128, 1, "HIGH", 2, "TOPRIGHT", UIParent, "TOPRIGHT", -150, 6, 1)
	LUI.MicroMenu.Anchor:SetBackdrop({
		bgFile = fdir..(Panels.db.profile.MicroMenu.AlwaysShow and "micro_anchor3" or "micro_anchor"),
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0},
	})
	LUI.MicroMenu.Anchor:SetBackdropColor(unpack(Themes.db.profile.micromenu_btn))
	LUI.MicroMenu.Anchor:SetBackdropBorderColor(0, 0, 0, 0)

	LUI.MicroMenu.Button = LUI:CreateMeAFrame("Frame", nil, UIParent, 590, 512, 1, "BACKGROUND", 1, "TOPRIGHT", UIParent, "TOPRIGHT", 0, -1, 1)
	LUI.MicroMenu.Button:SetBackdrop({
		bgFile = fdir.."micro_button",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.MicroMenu.Button:SetBackdropColor(unpack(Themes.db.profile.micromenu_bg))
	LUI.MicroMenu.Button:SetBackdropBorderColor(0, 0, 0, 0)

	LUI.MicroMenu.Button.BG = LUI:CreateMeAFrame("Frame", nil, LUI.MicroMenu.Button, 590, 512, 1, "BACKGROUND", 0, "TOPRIGHT", LUI.MicroMenu.Button, "TOPRIGHT", 0, 0, 1)
	LUI.MicroMenu.Button.BG:SetBackdrop({
		bgFile = fdir.."micro_button_bg",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.MicroMenu.Button.BG:SetBackdropColor(unpack(Themes.db.profile.micromenu_bg2))
	LUI.MicroMenu.Button.BG:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.MicroMenu.Button.BG:SetFrameStrata("BACKGROUND")

	LUI.MicroMenu.Clicker = LUI:CreateMeAFrame("Button", nil, LUI.MicroMenu.Anchor, 85, 22, 1, "HIGH", 2, "TOP", LUI.MicroMenu.Anchor, "TOP", 0, 0, 1)
	LUI.MicroMenu.Clicker:RegisterForClicks("AnyUp")

	LUI.MicroMenu.Clicker:SetScript("OnClick", function(self)
		if RaidMenu.db.profile.Enable then
			RaidMenu:OverlapPrevention("MM")
		end
		if Panels.db.profile.MicroMenu.IsShown then
			LUI.MicroMenu.AlphaOut:Show()
			Panels.db.profile.MicroMenu.IsShown = false

			LUI.MicroMenu.Anchor:SetBackdrop({
				bgFile = fdir..(GetMouseFocus() == LUI.MicroMenu.Clicker and "micro_anchor2" or "micro_anchor"),
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = false, tileSize = 0, edgeSize = 1,
				insets = {left = 0, right = 0, top = 0, bottom = 0}
			})
			LUI.MicroMenu.Anchor:SetBackdropColor(unpack(Themes.db.profile.micromenu_btn_hover))
			LUI.MicroMenu.Anchor:SetBackdropBorderColor(0, 0, 0, 0)
		else
			LUI.MicroMenu.AlphaIn:Show()
			Panels.db.profile.MicroMenu.IsShown = true

			LUI.MicroMenu.Anchor:SetBackdrop({
				bgFile = fdir..(GetMouseFocus() == LUI.MicroMenu.Clicker and "micro_anchor4" or "micro_anchor3"),
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = false, tileSize = 0, edgeSize = 1,
				insets = {left = 0, right = 0, top = 0, bottom = 0}
			})
			LUI.MicroMenu.Anchor:SetBackdropColor(unpack(Themes.db.profile.micromenu_btn_hover))
			LUI.MicroMenu.Anchor:SetBackdropBorderColor(0, 0, 0, 0)
		end
	end)

	LUI.MicroMenu.Clicker:SetScript("OnEnter", function(self)
		if Panels.db.profile.MicroMenu.IsShown then
			LUI.MicroMenu.Anchor:SetBackdrop({
				bgFile = fdir.."micro_anchor4",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = false, tileSize = 0, edgeSize = 1,
				insets = {left = 0, right = 0, top = 0, bottom = 0}
			})
			LUI.MicroMenu.Anchor:SetBackdropColor(unpack(Themes.db.profile.micromenu_btn_hover))
			LUI.MicroMenu.Anchor:SetBackdropBorderColor(0, 0, 0, 0)
		else
			LUI.MicroMenu.Anchor:SetBackdrop({
				bgFile = fdir.."micro_anchor2",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = false, tileSize = 0, edgeSize = 1,
				insets = {left = 0, right = 0, top = 0, bottom = 0}
			})
			LUI.MicroMenu.Anchor:SetBackdropColor(unpack(Themes.db.profile.micromenu_btn_hover))
			LUI.MicroMenu.Anchor:SetBackdropBorderColor(0, 0, 0, 0)
		end
	end)

	LUI.MicroMenu.Clicker:SetScript("OnLeave", function(self)
		if Panels.db.profile.MicroMenu.IsShown then
			LUI.MicroMenu.Anchor:SetBackdrop({
				bgFile = fdir.."micro_anchor3",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = false, tileSize = 0, edgeSize = 1,
				insets = {left = 0, right = 0, top = 0, bottom = 0}
			})
			LUI.MicroMenu.Anchor:SetBackdropColor(unpack(Themes.db.profile.micromenu_btn))
			LUI.MicroMenu.Anchor:SetBackdropBorderColor(0, 0, 0, 0)
		else
			LUI.MicroMenu.Anchor:SetBackdrop({
				bgFile = fdir.."micro_anchor",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = false, tileSize = 0, edgeSize = 1,
				insets = {left = 0, right = 0, top = 0, bottom = 0}
			})
			LUI.MicroMenu.Anchor:SetBackdropColor(unpack(Themes.db.profile.micromenu_btn))
			LUI.MicroMenu.Anchor:SetBackdropBorderColor(0, 0, 0, 0)
		end
	end)

	LUI.MicroMenu.ButtonRight = LUI:CreateMeAFrame("Frame", nil, LUI.MicroMenu.Anchor, 128, 128, 1, "HIGH", 1, "RIGHT", LUI.MicroMenu.Anchor, "RIGHT", 47, -3, 1)
	LUI.MicroMenu.ButtonRight:SetBackdrop({
		bgFile = fdir.."mm_button_right",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.MicroMenu.ButtonRight:SetBackdropColor(unpack(Themes.db.profile.micromenu_btn))
	LUI.MicroMenu.ButtonRight:SetBackdropBorderColor(0, 0, 0, 0)

	LUI.MicroMenu.ButtonRight.Clicker = LUI:CreateMeAFrame("Button", nil, LUI.MicroMenu.ButtonRight, 40, 12, 1, "HIGH", 2, "TOP", LUI.MicroMenu.ButtonRight, "TOP", 22, -5, 1)
	LUI.MicroMenu.ButtonRight.Clicker:RegisterForClicks("AnyUp")

	LUI.MicroMenu.ButtonRight.Clicker:SetScript("OnClick", function(self, button)
		if button == "RightButton" then
			ToggleFrame(WorldMapFrame)
		else
			if Minimap:GetAlpha() == 0 then
				MinimapAlphaIn:Show()
				Panels.db.profile.Minimap.IsShown = true
			else
				MinimapAlphaOut:Show()
				Panels.db.profile.Minimap.IsShown = false
			end
		end
	end)

	LUI.MicroMenu.ButtonRight.Clicker:SetScript("OnEnter", function(self)
		LUI.MicroMenu.ButtonRight:SetBackdrop({
			bgFile = fdir.."mm_button_right_hover",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = false, tileSize = 0, edgeSize = 1,
			insets = {left = 0, right = 0, top = 0, bottom = 0}
		})
		LUI.MicroMenu.ButtonRight:SetBackdropColor(unpack(Themes.db.profile.micromenu_btn_hover))
		LUI.MicroMenu.ButtonRight:SetBackdropBorderColor(0, 0, 0, 0)
	end)

	LUI.MicroMenu.ButtonRight.Clicker:SetScript("OnLeave", function(self)
		LUI.MicroMenu.ButtonRight:SetBackdrop({
			bgFile = fdir.."mm_button_right",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = false, tileSize = 0, edgeSize = 1,
			insets = {left = 0, right = 0, top = 0, bottom = 0}
		})
		LUI.MicroMenu.ButtonRight:SetBackdropColor(unpack(Themes.db.profile.micromenu_btn))
		LUI.MicroMenu.ButtonRight:SetBackdropBorderColor(0, 0, 0, 0)
	end)

	LUI.MicroMenu.ButtonLeft = LUI:CreateMeAFrame("Frame", nil, LUI.MicroMenu.Anchor, 128, 128, 1, "HIGH", 1, "LEFT", LUI.MicroMenu.Anchor, "LEFT", -47, -3, 1)
	LUI.MicroMenu.ButtonLeft:SetBackdrop({
		bgFile = fdir.."mm_button_left",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.MicroMenu.ButtonLeft:SetBackdropColor(unpack(Themes.db.profile.micromenu_btn))
	LUI.MicroMenu.ButtonLeft:SetBackdropBorderColor(0, 0, 0, 0)

	LUI.MicroMenu.ButtonLeft.Clicker = LUI:CreateMeAFrame("Button", nil, LUI.MicroMenu.ButtonLeft, 40, 12, 1, "HIGH", 2, "TOP", LUI.MicroMenu.ButtonLeft, "TOP", -22, -5, 1)
	LUI.MicroMenu.ButtonLeft.Clicker:RegisterForClicks("AnyUp")

	LUI.MicroMenu.ButtonLeft.Clicker:SetScript("OnClick", function(self, button)
			RaidMenu:OverlapPrevention("RM", "toggle")
	end)

	LUI.MicroMenu.ButtonLeft.Clicker:SetScript("OnEnter", function(self)
		LUI.MicroMenu.ButtonLeft:SetBackdrop({
			bgFile = fdir.."mm_button_left_hover",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = false, tileSize = 0, edgeSize = 1,
			insets = {left = 0, right = 0, top = 0, bottom = 0}
		})
		LUI.MicroMenu.ButtonLeft:SetBackdropColor(unpack(Themes.db.profile.micromenu_btn_hover))
		LUI.MicroMenu.ButtonLeft:SetBackdropBorderColor(0, 0, 0, 0)
	end)

	LUI.MicroMenu.ButtonLeft.Clicker:SetScript("OnLeave", function(self)
		LUI.MicroMenu.ButtonLeft:SetBackdrop({
			bgFile = fdir.."mm_button_left",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = false, tileSize = 0, edgeSize = 1,
			insets = {left = 0, right = 0, top = 0, bottom = 0}
		})
		LUI.MicroMenu.ButtonLeft:SetBackdropColor(unpack(Themes.db.profile.micromenu_btn))
		LUI.MicroMenu.ButtonLeft:SetBackdropBorderColor(0, 0, 0, 0)
	end)

	LUI.MicroMenu.AlphaOut = CreateFrame("Frame", nil, UIParent)
	LUI.MicroMenu.AlphaOut:Hide()
	LUI.MicroMenu.AlphaOut.timer = 0
	LUI.MicroMenu.AlphaOut:SetScript("OnUpdate", function(self, elapsed)
		self.timer = self.timer + elapsed
		if self.timer < .5 then
			LUI.MicroMenu.Button:SetAlpha(1 - self.timer / .5)
		else
			LUI.MicroMenu.Button:SetAlpha(0)
			LUI.MicroMenu.Button:Hide()
			self.timer = 0
			self:Hide()
		end
	end)

	LUI.MicroMenu.AlphaIn = CreateFrame("Frame", nil, UIParent)
	LUI.MicroMenu.AlphaIn:Hide()
	LUI.MicroMenu.AlphaIn.timer = 0
	LUI.MicroMenu.AlphaIn:SetScript("OnUpdate", function(self, elapsed)
		LUI.MicroMenu.Button:Show()
		self.timer = self.timer + elapsed
		if self.timer < .5 then
			LUI.MicroMenu.Button:SetAlpha(self.timer / .5)
		else
			LUI.MicroMenu.Button:SetAlpha(1)
			self.timer = 0
			self:Hide()
		end
	end)

	--------------------------------------
	-- MICRO MENU
	--------------------------------------

	local bagsFrame
	local getBagsFrame = function()
		if LUI:Module("Bags").db.profile.Enable then
			bagsFrame = LUIBags
		elseif IsAddOnLoaded("Stuffing") then
			bagsFrame = StuffingFrameBags
		elseif IsAddOnLoaded("Bagnon") then
			bagsFrame = BagnonFrameinventory
		elseif IsAddOnLoaded("ArkInventory") then
			bagsFrame = ARKINV_Frame1
		elseif IsAddOnLoaded("OneBag") then
			bagsFrame = OneBagFrame
		else
			bagsFrame = nil
		end
	end
	getBagsFrame()

	LUI.MicroMenu.Buttons.Bags = LUI:CreateMeAFrame("Frame", nil, LUI.MicroMenu.Button, 64, 64, 1, "BACKGROUND", 3, "TOPRIGHT", LUI.MicroMenu.Button, "TOPRIGHT", 0, 0, 1)
	LUI.MicroMenu.Buttons.Bags:SetBackdrop({
		bgFile = fdir.."micro_bags",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false, tileSize = 0,
		edgeSize = 1, insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.MicroMenu.Buttons.Bags:SetBackdropColor(micro_r, micro_g, micro_b, 1)
	LUI.MicroMenu.Buttons.Bags:SetBackdropBorderColor(0, 0, 0, 0)

	LUI.MicroMenu.Buttons.Bags.Clicker = LUI:CreateMeAFrame("Button", nil, LUI.MicroMenu.Buttons.Bags, 42, 25, 1, "BACKGROUND", 2, "CENTER", LUI.MicroMenu.Buttons.Bags, "CENTER", -8, 0, 1)
	LUI.MicroMenu.Buttons.Bags.Clicker:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.MicroMenu.Buttons.Bags.Clicker:SetBackdropColor(0, 0, 0, 1)
	LUI.MicroMenu.Buttons.Bags.Clicker:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.MicroMenu.Buttons.Bags.Clicker:SetAlpha(0)

	LUI.MicroMenu.Buttons.Bags.Clicker:SetScript("OnEnter", function(self)
		self:SetAlpha(1)
		self.State = true
		GameTooltip:SetOwner(self, "ANCHOR_NONE ", 40, -90)
		GameTooltip:SetText("Bags")
		GameTooltip:AddLine("Show/Hide your Bags", 1, 1, 1)
		GameTooltip:Show()
	end)

	LUI.MicroMenu.Buttons.Bags.Clicker:SetScript("OnLeave", function(self)
		getBagsFrame()
		if bagsFrame and not bagsFrame:IsShown() then
			self:SetAlpha(0)
		end
		self.State = nil
		GameTooltip:Hide()
	end)

	LUI.MicroMenu.Buttons.Bags.Clicker:SetScript("OnClick", function(self)
		ToggleBackpack()
	end)

	LUI.MicroMenu.Buttons.Bags.Clicker:SetScript("OnUpdate", function(self)
		if (bagsFrame and bagsFrame:IsShown()) or self.State then
			self:SetAlpha(1)
		else
			self:SetAlpha(0)
		end
	end)

	LUI.MicroMenu.Buttons.Settings = LUI:CreateMeAFrame("Frame", nil, LUI.MicroMenu.Buttons.Bags, 64, 64, 1, "BACKGROUND", 3, "LEFT", LUI.MicroMenu.Buttons.Bags, "LEFT", -48, 0, 1)
	LUI.MicroMenu.Buttons.Settings:SetBackdrop({
		bgFile = fdir.."micro_settings",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.MicroMenu.Buttons.Settings:SetBackdropColor(micro_r, micro_g, micro_b, 1)
	LUI.MicroMenu.Buttons.Settings:SetBackdropBorderColor(0, 0, 0, 0)

	LUI.MicroMenu.Buttons.Settings.Clicker = LUI:CreateMeAFrame("Button", nil, LUI.MicroMenu.Buttons.Settings, 30, 25, 1, "BACKGROUND", 2, "CENTER", LUI.MicroMenu.Buttons.Settings, "CENTER", -2, 0, 1)
	LUI.MicroMenu.Buttons.Settings.Clicker:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.MicroMenu.Buttons.Settings.Clicker:SetBackdropColor(0, 0, 0, 1)
	LUI.MicroMenu.Buttons.Settings.Clicker:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.MicroMenu.Buttons.Settings.Clicker:SetAlpha(0)

	LUI.MicroMenu.Buttons.Settings.Clicker:RegisterForClicks("AnyUp")

	LUI.MicroMenu.Buttons.Settings.Clicker:SetScript("OnEnter", function(self)
		self:SetAlpha(1)
		self.State = true
		GameTooltip:SetOwner(self, "ANCHOR_NONE " ,40, -90)
		GameTooltip:SetText("Options")
		GameTooltip:AddLine("Left Click: LUI Option Panel", 1,1,1)
		GameTooltip:AddLine("Right Click: WoW Option Panel", 1,1,1)
		GameTooltip:Show()
	end)

	LUI.MicroMenu.Buttons.Settings.Clicker:SetScript("OnLeave", function(self)
		self:SetAlpha(0)
		self.State = nil
		GameTooltip:Hide()
	end)

	LUI.MicroMenu.Buttons.Settings.Clicker:SetScript("OnClick", function(self, button)
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

	LUI.MicroMenu.Buttons.Settings.Clicker:SetScript("OnUpdate", function(self)
		if self.State then return end
		if GameMenuFrame:IsShown() or AceConfigDialog.OpenFrames.LUI or self.State then
			self:SetAlpha(1)
		else
			self:SetAlpha(0)
		end
	end)

	LUI.MicroMenu.Buttons.GM = LUI:CreateMeAFrame("Frame", nil, LUI.MicroMenu.Buttons.Settings, 64, 64, 1, "BACKGROUND", 3, "LEFT", LUI.MicroMenu.Buttons.Settings, "LEFT", -33, 0, 1)
	LUI.MicroMenu.Buttons.GM:SetBackdrop({
		bgFile = fdir.."micro_gm",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.MicroMenu.Buttons.GM:SetBackdropColor(micro_r, micro_g, micro_b, 1)
	LUI.MicroMenu.Buttons.GM:SetBackdropBorderColor(0, 0, 0, 0)

	LUI.MicroMenu.Buttons.GM.Clicker = LUI:CreateMeAFrame("Button", nil, LUI.MicroMenu.Buttons.GM, 30, 25, 1, "BACKGROUND", 2, "CENTER", LUI.MicroMenu.Buttons.GM, "CENTER", -2, 0, 1)
	LUI.MicroMenu.Buttons.GM.Clicker:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.MicroMenu.Buttons.GM.Clicker:SetBackdropColor(0, 0, 0, 1)
	LUI.MicroMenu.Buttons.GM.Clicker:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.MicroMenu.Buttons.GM.Clicker:SetAlpha(0)

	LUI.MicroMenu.Buttons.GM.Clicker:SetScript("OnEnter", function(self)
		self:SetAlpha(1)
		self.State = true
		GameTooltip:SetOwner(self, "ANCHOR_NONE " ,40, -90)
		GameTooltip:SetText("Help Request")
		GameTooltip:AddLine("Show/Hide the Help Request Frame", 1, 1, 1)
		GameTooltip:Show()
	end)

	LUI.MicroMenu.Buttons.GM.Clicker:SetScript("OnLeave", function(self)
		if not HelpFrame:IsShown() then
			self:SetAlpha(0)
		end
		self.State = nil
		GameTooltip:Hide()
	end)

	LUI.MicroMenu.Buttons.GM.Clicker:SetScript("OnClick", function(self)
		ToggleHelpFrame()
	end)

	HelpFrame:HookScript("OnShow", function(self)
		LUI.MicroMenu.Buttons.GM.Clicker:SetAlpha(1)
	end)

	HelpFrame:HookScript("OnHide", function(self)
		if not LUI.MicroMenu.Buttons.GM.Clicker.State then
			LUI.MicroMenu.Buttons.GM.Clicker:SetAlpha(0)
		end
	end)

	LUI.MicroMenu.Buttons.Pets = LUI:CreateMeAFrame("Frame", nil, LUI.MicroMenu.Buttons.GM, 64, 64, 1, "BACKGROUND", 3, "LEFT", LUI.MicroMenu.Buttons.GM, "LEFT", -33, 0, 1)
	LUI.MicroMenu.Buttons.Pets:SetBackdrop({
		bgFile = fdir.."micro_pets",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.MicroMenu.Buttons.Pets:SetBackdropColor(micro_r, micro_g, micro_b, 1)
	LUI.MicroMenu.Buttons.Pets:SetBackdropBorderColor(0, 0, 0, 0)

	LUI.MicroMenu.Buttons.Pets.Clicker = LUI:CreateMeAFrame("Button", nil, LUI.MicroMenu.Buttons.Pets, 30, 25, 1, "BACKGROUND", 2, "CENTER", LUI.MicroMenu.Buttons.Pets, "CENTER", -2, 0, 1)
	LUI.MicroMenu.Buttons.Pets.Clicker:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.MicroMenu.Buttons.Pets.Clicker:SetBackdropColor(0, 0, 0, 1)
	LUI.MicroMenu.Buttons.Pets.Clicker:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.MicroMenu.Buttons.Pets.Clicker:SetAlpha(0)

	LUI.MicroMenu.Buttons.Pets.Clicker:SetScript("OnEnter", function(self)
		self:SetAlpha(1)
		self.State = true
		GameTooltip:SetOwner(self, "ANCHOR_NONE " ,40, -90)
		GameTooltip:SetText("Mounts and Pets")
		GameTooltip:AddLine("Show/Hide your Mounts & Pets", 1, 1, 1)
		GameTooltip:Show()
	end)

	LUI.MicroMenu.Buttons.Pets.Clicker:SetScript("OnLeave", function(self)
		if not HelpFrame:IsShown() then
			self:SetAlpha(0)
		end
		self.State = nil
		GameTooltip:Hide()
	end)

	LUI.MicroMenu.Buttons.Pets.Clicker:SetScript("OnClick", function(self)
		TogglePetJournal()
	end)
	
	module:RegisterEvent("ADDON_LOADED", function(event)
		if event and not IsAddOnLoaded("Blizzard_PetJournal") then return end
		if event then module:UnregisterEvent(event) end

		PetJournalParent:HookScript("OnShow", function(self)
			LUI.MicroMenu.Buttons.Pets.Clicker:SetAlpha(1)
		end)

		PetJournalParent:HookScript("OnHide", function(self)
			if not LUI.MicroMenu.Buttons.Pets.Clicker.State then
				LUI.MicroMenu.Buttons.Pets.Clicker:SetAlpha(0)
			end
		end)
	end)

	LUI.MicroMenu.Buttons.LFG = LUI:CreateMeAFrame("Frame", nil, LUI.MicroMenu.Buttons.Pets, 64, 64, 1, "BACKGROUND", 3, "LEFT", LUI.MicroMenu.Buttons.Pets, "LEFT", -33, 0, 1)
	LUI.MicroMenu.Buttons.LFG:SetBackdrop({
		bgFile = fdir.."micro_lfg",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.MicroMenu.Buttons.LFG:SetBackdropColor(micro_r, micro_g, micro_b, 1)
	LUI.MicroMenu.Buttons.LFG:SetBackdropBorderColor(0, 0, 0, 0)

	LUI.MicroMenu.Buttons.LFG.Clicker = LUI:CreateMeAFrame("Button", nil, LUI.MicroMenu.Buttons.LFG, 30, 25, 1, "BACKGROUND", 2, "CENTER", LUI.MicroMenu.Buttons.LFG, "CENTER", -2, 0, 1)
	LUI.MicroMenu.Buttons.LFG.Clicker:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.MicroMenu.Buttons.LFG.Clicker:SetBackdropColor(0, 0, 0, 1)
	LUI.MicroMenu.Buttons.LFG.Clicker:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.MicroMenu.Buttons.LFG.Clicker:SetAlpha(0)

	LUI.MicroMenu.Buttons.LFG.Clicker:RegisterForClicks("AnyUp")

	LUI.MicroMenu.Buttons.LFG.Clicker:SetScript("OnEnter", function(self)
		self:SetAlpha(1)
		self.State = true
		GameTooltip:SetOwner(self, "ANCHOR_NONE ", 40, -90)
		GameTooltip:SetText("Dungeon Finder")
		GameTooltip:AddLine("Show/Hide Dungeon Finder", 1, 1, 1)
		if UnitLevel("player") < 15 then
			GameTooltip:AddLine("Available with Level 15", 1, 0, 0)
		end
		GameTooltip:Show()
	end)

	LUI.MicroMenu.Buttons.LFG.Clicker:SetScript("OnLeave", function(self)
		if not LFDParentFrame:IsShown() and not RaidParentFrame:IsShown() then
			self:SetAlpha(0)
		end
		self.State = false
		GameTooltip:Hide()
	end)

	LUI.MicroMenu.Buttons.LFG.Clicker:SetScript("OnClick", function(self, button)
		if UnitLevel("player") >= 15 then
				ToggleLFDParentFrame()
		end
	end)

	LFDParentFrame:HookScript("OnShow", function(self)
		LUI.MicroMenu.Buttons.LFG.Clicker:SetAlpha(1)
	end)

	LFDParentFrame:HookScript("OnHide", function(self)
		if not LUI.MicroMenu.Buttons.LFG.Clicker.State and not RaidParentFrame:IsShown() then
			LUI.MicroMenu.Buttons.LFG.Clicker:SetAlpha(0)
		end
	end)

	RaidParentFrame:HookScript("OnShow", function(self)
		LUI.MicroMenu.Buttons.LFG.Clicker:SetAlpha(1)
	end)

	RaidParentFrame:HookScript("OnHide", function(self)
		if not LUI.MicroMenu.Buttons.LFG.Clicker.State and not LFDParentFrame:IsShown() then
			LUI.MicroMenu.Buttons.LFG.Clicker:SetAlpha(0)
		end
	end)

	LUI.MicroMenu.Buttons.Journal = LUI:CreateMeAFrame("Frame", nil, LUI.MicroMenu.Buttons.LFG, 64, 64, 1, "BACKGROUND", 3, "LEFT", LUI.MicroMenu.Buttons.LFG, "LEFT", -33, 0, 1)
	LUI.MicroMenu.Buttons.Journal:SetBackdrop({
		bgFile = fdir.."micro_encounter",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.MicroMenu.Buttons.Journal:SetBackdropColor(micro_r, micro_g, micro_b, 1)
	LUI.MicroMenu.Buttons.Journal:SetBackdropBorderColor(0, 0, 0, 0)

	LUI.MicroMenu.Buttons.Journal.Clicker = LUI:CreateMeAFrame("Button", nil, LUI.MicroMenu.Buttons.Journal, 30, 25, 1, "BACKGROUND", 2, "CENTER", LUI.MicroMenu.Buttons.Journal, "CENTER", -2, 0, 1)
	LUI.MicroMenu.Buttons.Journal.Clicker:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.MicroMenu.Buttons.Journal.Clicker:SetBackdropColor(0, 0, 0, 1)
	LUI.MicroMenu.Buttons.Journal.Clicker:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.MicroMenu.Buttons.Journal.Clicker:SetAlpha(0)

	LUI.MicroMenu.Buttons.Journal.Clicker:SetScript("OnEnter", function(self)
		self:SetAlpha(1)
		self.State = true
		GameTooltip:SetOwner(self, "ANCHOR_NONE ", 40, -90)
		GameTooltip:SetText("Encounter Journal")
		GameTooltip:AddLine("Dungeon & Encounter Journal", 1, 1, 1)
		GameTooltip:Show()
	end)

	LUI.MicroMenu.Buttons.Journal.Clicker:SetScript("OnLeave", function(self)
		if not EncounterJournal or not EncounterJournal:IsShown() then
			self:SetAlpha(0)
		end
		self.State = nil
		GameTooltip:Hide()
	end)

	LUI.MicroMenu.Buttons.Journal.Clicker:SetScript("OnClick", function(self)
		if EncounterJournal then
			if EncounterJournal:IsShown() then
				HideUIPanel(EncounterJournal)
			else
				ShowUIPanel(EncounterJournal)
			end
		else
			LoadAddOn("Blizzard_EncounterJournal")
			ShowUIPanel(EncounterJournal)
			self:SetAlpha(1)
		end
	end)

	module:RegisterEvent("ADDON_LOADED", function(event)
		if event and not IsAddOnLoaded("Blizzard_EncounterJournal") then return end
		if event then module:UnregisterEvent(event) end

		EncounterJournal:HookScript("OnShow", function(self)
			LUI.MicroMenu.Buttons.Journal.Clicker:SetAlpha(1)
		end)
		EncounterJournal:HookScript("OnHide", function(self)
			if not LUI.MicroMenu.Buttons.Journal.Clicker.State then
				LUI.MicroMenu.Buttons.Journal.Clicker:SetAlpha(0)
			end
		end)
	end)

	LUI.MicroMenu.Buttons.PVP = LUI:CreateMeAFrame("Frame", nil, LUI.MicroMenu.Buttons.Journal, 64, 64, 1, "BACKGROUND", 3, "LEFT", LUI.MicroMenu.Buttons.Journal, "LEFT", -33, 0, 1)
	LUI.MicroMenu.Buttons.PVP:SetBackdrop({
		bgFile = fdir.."micro_pvp",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.MicroMenu.Buttons.PVP:SetBackdropColor(micro_r, micro_g, micro_b, 1)
	LUI.MicroMenu.Buttons.PVP:SetBackdropBorderColor(0, 0, 0, 0)

	LUI.MicroMenu.Buttons.PVP.Clicker = LUI:CreateMeAFrame("Button", nil, LUI.MicroMenu.Buttons.PVP, 30, 25, 1, "BACKGROUND", 2, "CENTER", LUI.MicroMenu.Buttons.PVP, "CENTER", -2, 0, 1)
	LUI.MicroMenu.Buttons.PVP.Clicker:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.MicroMenu.Buttons.PVP.Clicker:SetBackdropColor(0, 0, 0, 1)
	LUI.MicroMenu.Buttons.PVP.Clicker:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.MicroMenu.Buttons.PVP.Clicker:SetAlpha(0)

	LUI.MicroMenu.Buttons.PVP.Clicker:SetScript("OnEnter", function(self)
		self:SetAlpha(1)
		self.State = true
		GameTooltip:SetOwner(self, "ANCHOR_NONE ", 40, -90)
		GameTooltip:SetText("PvP")
		GameTooltip:AddLine("Arena/Battlegrounds...", 1, 1, 1)
		if UnitLevel("player") < 10 then
			GameTooltip:AddLine("Available with Level 10", 1, 0, 0)
		end
		GameTooltip:Show()
	end)

	LUI.MicroMenu.Buttons.PVP.Clicker:SetScript("OnLeave", function(self)
		if not PVPFrame:IsShown() then
			self:SetAlpha(0)
		end
		self.State = nil
		GameTooltip:Hide()
	end)

	LUI.MicroMenu.Buttons.PVP.Clicker:SetScript("OnClick", function(self)
		if UnitLevel("player") >= 10 then
			if PVPFrame:IsShown() then
				HideUIPanel(PVPFrame)
			else
				ShowUIPanel(PVPFrame)
			end
		end
	end)

	PVPFrame:HookScript("OnShow", function(self)
		LUI.MicroMenu.Buttons.PVP.Clicker:SetAlpha(1)
	end)

	PVPFrame:HookScript("OnHide", function(self)
		if not LUI.MicroMenu.Buttons.PVP.Clicker.State then
			LUI.MicroMenu.Buttons.PVP.Clicker:SetAlpha(0)
		end
	end)

	LUI.MicroMenu.Buttons.Guild = LUI:CreateMeAFrame("Frame",nil,LUI.MicroMenu.Buttons.PVP,64,64,1,"BACKGROUND",3,"LEFT",LUI.MicroMenu.Buttons.PVP,"LEFT",-33,0, 1)
	LUI.MicroMenu.Buttons.Guild:SetBackdrop({
		bgFile = fdir.."micro_guild",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.MicroMenu.Buttons.Guild:SetBackdropColor(micro_r, micro_g, micro_b, 1)
	LUI.MicroMenu.Buttons.Guild:SetBackdropBorderColor(0, 0, 0, 0)

	LUI.MicroMenu.Buttons.Guild.Clicker = LUI:CreateMeAFrame("Button", nil, LUI.MicroMenu.Buttons.Guild, 30, 25, 1, "BACKGROUND", 2, "CENTER", LUI.MicroMenu.Buttons.Guild, "CENTER", -2, 0, 1)
	LUI.MicroMenu.Buttons.Guild.Clicker:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.MicroMenu.Buttons.Guild.Clicker:SetBackdropColor(0, 0, 0, 1)
	LUI.MicroMenu.Buttons.Guild.Clicker:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.MicroMenu.Buttons.Guild.Clicker:SetAlpha(0)

	LUI.MicroMenu.Buttons.Guild.Clicker:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	LUI.MicroMenu.Buttons.Guild.Clicker:SetScript("OnEnter", function(self)
		self:SetAlpha(1)
		self.State = true
		GameTooltip:SetOwner(LUI.MicroMenu.Buttons.Guild.Clicker, "ANCHOR_NONE ", 40, -90)
		GameTooltip:SetText("Guild/Friends")
		GameTooltip:AddLine("Left Click: Guild Frame", 1, 1, 1)
		GameTooltip:AddLine("Right Click: Friends Frame", 1, 1, 1)
		GameTooltip:Show()
	end)

	LUI.MicroMenu.Buttons.Guild.Clicker:SetScript("OnLeave", function(self)
		if not FriendsFrame:IsShown() and not GuildFrame:IsShown() then
			self:SetAlpha(0)
		end
		self.State = nil
		GameTooltip:Hide()
	end)

	LUI.MicroMenu.Buttons.Guild.Clicker:SetScript("OnClick", function(self, button)
		if button == "RightButton" then
			if FriendsFrame:IsShown() then
				HideUIPanel(FriendsFrame)
			else
				ShowUIPanel(FriendsFrame)
			end
		else
			if GuildFrame:IsShown() or LookingForGuildFrame:IsShown() then
				if IsInGuild() then HideUIPanel(GuildFrame) else HideUIPanel(LookingForGuildFrame) end
			else
				if IsInGuild() then ShowUIPanel(GuildFrame) else ShowUIPanel(LookingForGuildFrame) end
			end
		end
	end)

	FriendsFrame:HookScript("OnShow", function(self)
		LUI.MicroMenu.Buttons.Guild.Clicker:SetAlpha(1)
	end)

	FriendsFrame:HookScript("OnHide", function(self)
		if not GuildFrame:IsShown() and not LUI.MicroMenu.Buttons.Guild.Clicker.State then
			LUI.MicroMenu.Buttons.Guild.Clicker:SetAlpha(0)
		end
	end)

	if not GuildFrame then LoadAddOn("Blizzard_GuildUI") end
	if not LookingForGuildFrame then LoadAddOn("Blizzard_LookingForGuildUI") end

	GuildFrame:HookScript("OnShow", function(self)
		LUI.MicroMenu.Buttons.Guild.Clicker:SetAlpha(1)
	end)

	GuildFrame:HookScript("OnHide", function(self)
		if not FriendsFrame:IsShown() and not LookingForGuildFrame:IsShown() and not LUI.MicroMenu.Buttons.Guild.Clicker.State then
			LUI.MicroMenu.Buttons.Guild.Clicker:SetAlpha(0)
		end
	end)

	LookingForGuildFrame:HookScript("OnShow", function(self)
		LUI.MicroMenu.Buttons.Guild.Clicker:SetAlpha(1)
	end)

	LookingForGuildFrame:HookScript("OnHide", function(self)
		if not FriendsFrame:IsShown() and not GuildFrame:IsShown() and not LUI.MicroMenu.Buttons.Guild.Clicker.State then
			LUI.MicroMenu.Buttons.Guild.Clicker:SetAlpha(0)
		end
	end)

	LUI.MicroMenu.Buttons.Quests = LUI:CreateMeAFrame("Frame", nil, LUI.MicroMenu.Buttons.Guild, 64, 64, 1, "BACKGROUND", 3, "LEFT", LUI.MicroMenu.Buttons.Guild, "LEFT", -33, 0, 1)
	LUI.MicroMenu.Buttons.Quests:SetBackdrop({
		bgFile = fdir.."micro_quests",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.MicroMenu.Buttons.Quests:SetBackdropColor(micro_r, micro_g, micro_b, 1)
	LUI.MicroMenu.Buttons.Quests:SetBackdropBorderColor(0, 0, 0, 0)

	LUI.MicroMenu.Buttons.Quests.Clicker = LUI:CreateMeAFrame("Button", nil, LUI.MicroMenu.Buttons.Quests, 30, 25, 1, "BACKGROUND", 2, "CENTER", LUI.MicroMenu.Buttons.Quests, "CENTER", -2, 0, 1)
	LUI.MicroMenu.Buttons.Quests.Clicker:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.MicroMenu.Buttons.Quests.Clicker:SetBackdropColor(0, 0, 0, 1)
	LUI.MicroMenu.Buttons.Quests.Clicker:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.MicroMenu.Buttons.Quests.Clicker:SetAlpha(0)

	LUI.MicroMenu.Buttons.Quests.Clicker:SetScript("OnEnter", function(self)
		self:SetAlpha(1)
		self.State = true
		GameTooltip:SetOwner(self, "ANCHOR_NONE ", 40, -90)
		GameTooltip:SetText("Quest Log")
		GameTooltip:AddLine("Show/Hide your Quest Log", 1, 1, 1)
		GameTooltip:Show()
	end)

	LUI.MicroMenu.Buttons.Quests.Clicker:SetScript("OnLeave", function(self)
		if not QuestLogFrame:IsShown() then
			self:SetAlpha(0)
		end
		self.State = nil
		GameTooltip:Hide()
	end)

	LUI.MicroMenu.Buttons.Quests.Clicker:SetScript("OnClick", function(self)
		if QuestLogFrame:IsShown() then
			HideUIPanel(QuestLogFrame)
		else
			ShowUIPanel(QuestLogFrame)
		end
	end)

	QuestLogFrame:HookScript("OnShow", function(self)
		LUI.MicroMenu.Buttons.Quests.Clicker:SetAlpha(1)
	end)

	QuestLogFrame:HookScript("OnHide", function(self)
		if not LUI.MicroMenu.Buttons.Quests.Clicker.State then
			LUI.MicroMenu.Buttons.Quests.Clicker:SetAlpha(0)
		end
	end)

	LUI.MicroMenu.Buttons.AC = LUI:CreateMeAFrame("Frame", nil, LUI.MicroMenu.Buttons.Quests, 64, 64, 1, "BACKGROUND", 3, "LEFT", LUI.MicroMenu.Buttons.Quests, "LEFT", -33, 0, 1)
	LUI.MicroMenu.Buttons.AC:SetBackdrop({
		bgFile = fdir.."micro_achievements",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.MicroMenu.Buttons.AC:SetBackdropColor(micro_r, micro_g, micro_b, 1)
	LUI.MicroMenu.Buttons.AC:SetBackdropBorderColor(0, 0, 0, 0)

	LUI.MicroMenu.Buttons.AC.Clicker = LUI:CreateMeAFrame("Button", nil, LUI.MicroMenu.Buttons.AC, 30, 25, 1, "BACKGROUND", 2, "CENTER", LUI.MicroMenu.Buttons.AC, "CENTER", -2, 0, 1)
	LUI.MicroMenu.Buttons.AC.Clicker:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.MicroMenu.Buttons.AC.Clicker:SetBackdropColor(0, 0, 0, 1)
	LUI.MicroMenu.Buttons.AC.Clicker:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.MicroMenu.Buttons.AC.Clicker:SetAlpha(0)

	LUI.MicroMenu.Buttons.AC.Clicker:SetScript("OnEnter", function(self)
		self:SetAlpha(1)
		self.State = true
		GameTooltip:SetOwner(self, "ANCHOR_NONE ", 40, -90)
		GameTooltip:SetText("Achievements")
		GameTooltip:AddLine("Show/Hide your Achievements", 1, 1, 1)
		GameTooltip:Show()
	end)

	LUI.MicroMenu.Buttons.AC.Clicker:SetScript("OnLeave", function(self)
		self:SetAlpha(0)
		self.State = nil
		GameTooltip:Hide()
	end)

	LUI.MicroMenu.Buttons.AC.Clicker:SetScript("OnClick", function(self)
		ToggleAchievementFrame()
	end)

	LUI.MicroMenu.Buttons.AC.Clicker:SetScript("OnUpdate", function(self)
		if IsAddOnLoaded("Blizzard_AchievementUI") then
			if not LUI.MicroMenu.Buttons.AC.Clicker.State and AchievementFrame:IsShown() then
				LUI.MicroMenu.Buttons.AC.Clicker:SetAlpha(1)
			else
				LUI.MicroMenu.Buttons.AC.Clicker:SetAlpha(0)
			end
		end
	end)

	LUI.MicroMenu.Buttons.Talents = LUI:CreateMeAFrame("Frame", nil, LUI.MicroMenu.Buttons.AC, 64, 64, 1, "BACKGROUND", 3, "LEFT", LUI.MicroMenu.Buttons.AC, "LEFT", -33, 0, 1)
	LUI.MicroMenu.Buttons.Talents:SetBackdrop({
		bgFile = fdir.."micro_talents",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.MicroMenu.Buttons.Talents:SetBackdropColor(micro_r, micro_g, micro_b, 1)
	LUI.MicroMenu.Buttons.Talents:SetBackdropBorderColor(0, 0, 0, 0)

	LUI.MicroMenu.Buttons.Talents.Clicker = LUI:CreateMeAFrame("Button", nil, LUI.MicroMenu.Buttons.Talents, 30, 25, 1, "BACKGROUND", 2, "CENTER", LUI.MicroMenu.Buttons.Talents, "CENTER", -2, 0, 1)
	LUI.MicroMenu.Buttons.Talents.Clicker:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.MicroMenu.Buttons.Talents.Clicker:SetBackdropColor(0, 0, 0, 1)
	LUI.MicroMenu.Buttons.Talents.Clicker:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.MicroMenu.Buttons.Talents.Clicker:SetAlpha(0)

	LUI.MicroMenu.Buttons.Talents.Clicker:SetScript("OnEnter", function(self)
		self:SetAlpha(1)
		self.State = true
		GameTooltip:SetOwner(self, "ANCHOR_NONE ", 40, -90)
		GameTooltip:SetText("Talents")
		GameTooltip:AddLine("Show/Hide your Talent Frame", 1, 1, 1)
		if UnitLevel("player") < 10 then
			GameTooltip:AddLine("Available with Level 10", 1, 0, 0)
		end
		GameTooltip:Show()
	end)

	LUI.MicroMenu.Buttons.Talents.Clicker:SetScript("OnLeave", function(self)
		if not PlayerTalentFrame:IsShown() then
			self:SetAlpha(0)
		end
		self.State = nil
		GameTooltip:Hide()
	end)

	LUI.MicroMenu.Buttons.Talents.Clicker:SetScript("OnClick", function(self)
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
		LUI.MicroMenu.Buttons.Talents.Clicker:SetAlpha(1)
	end)

	PlayerTalentFrame:HookScript("OnHide", function(self)
		if not LUI.MicroMenu.Buttons.Talents.Clicker.State then
			LUI.MicroMenu.Buttons.Talents.Clicker:SetAlpha(0)
		end
	end)

	LUI.MicroMenu.Buttons.Spellbook = LUI:CreateMeAFrame("Frame", nil, LUI.MicroMenu.Buttons.Talents, 64, 64, 1, "BACKGROUND", 3, "LEFT", LUI.MicroMenu.Buttons.Talents, "LEFT", -33, 0, 1)
	LUI.MicroMenu.Buttons.Spellbook:SetBackdrop({
		bgFile = fdir.."micro_spellbook",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.MicroMenu.Buttons.Spellbook:SetBackdropColor(micro_r, micro_g, micro_b, 1)
	LUI.MicroMenu.Buttons.Spellbook:SetBackdropBorderColor(0, 0, 0, 0)

	LUI.MicroMenu.Buttons.Spellbook.Clicker = LUI:CreateMeAFrame("Button", nil, LUI.MicroMenu.Buttons.Spellbook, 30, 25, 1, "BACKGROUND", 2, "CENTER", LUI.MicroMenu.Buttons.Spellbook, "CENTER", -2, 0, 1)
	LUI.MicroMenu.Buttons.Spellbook.Clicker:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.MicroMenu.Buttons.Spellbook.Clicker:SetBackdropColor(0, 0, 0, 1)
	LUI.MicroMenu.Buttons.Spellbook.Clicker:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.MicroMenu.Buttons.Spellbook.Clicker:SetAlpha(0)

	LUI.MicroMenu.Buttons.Spellbook.Clicker:SetScript("OnEnter", function(self)
		self:SetAlpha(1)
		self.State = true
		GameTooltip:SetOwner(self, "ANCHOR_NONE ", 40, -90)
		GameTooltip:SetText("Spellbook & Abilities")
		GameTooltip:AddLine("Show/Hide your Spellbook", 1, 1, 1)
		GameTooltip:Show()
	end)

	LUI.MicroMenu.Buttons.Spellbook.Clicker:SetScript("OnLeave", function(self)
		if not SpellBookFrame:IsShown() then
			self:SetAlpha(0)
		end
		self.State = nil
		GameTooltip:Hide()
	end)

	LUI.MicroMenu.Buttons.Spellbook.Clicker:SetScript("OnClick", function(self)
		if InCombatLockdown() then return end
		if SpellBookFrame:IsShown() then
			HideUIPanel(SpellBookFrame)
		else
			ShowUIPanel(SpellBookFrame)
		end
	end)

	SpellBookFrame:HookScript("OnShow", function(self)
		LUI.MicroMenu.Buttons.Spellbook.Clicker:SetAlpha(1)
	end)

	SpellBookFrame:HookScript("OnHide", function(self)
		if not LUI.MicroMenu.Buttons.Spellbook.Clicker.State then
			LUI.MicroMenu.Buttons.Spellbook.Clicker:SetAlpha(0)
		end
	end)

	LUI.MicroMenu.Buttons.Player = LUI:CreateMeAFrame("Frame", nil, LUI.MicroMenu.Buttons.Spellbook, 64, 64, 1, "BACKGROUND", 3, "LEFT", LUI.MicroMenu.Buttons.Spellbook, "LEFT", -32, 0, 1)
	LUI.MicroMenu.Buttons.Player:SetBackdrop({
		bgFile = fdir.."micro_player",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.MicroMenu.Buttons.Player:SetBackdropColor(micro_r, micro_g, micro_b, 1)
	LUI.MicroMenu.Buttons.Player:SetBackdropBorderColor(0, 0, 0, 0)

	LUI.MicroMenu.Buttons.Player.Clicker = LUI:CreateMeAFrame("Button", nil, LUI.MicroMenu.Buttons.Player, 42, 25, 1, "BACKGROUND", 2, "CENTER", LUI.MicroMenu.Buttons.Player, "CENTER", -8, 0, 1)
	LUI.MicroMenu.Buttons.Player.Clicker:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.MicroMenu.Buttons.Player.Clicker:SetBackdropColor(0, 0, 0, 1)
	LUI.MicroMenu.Buttons.Player.Clicker:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.MicroMenu.Buttons.Player.Clicker:SetAlpha(0)

	LUI.MicroMenu.Buttons.Player.Clicker:SetScript("OnEnter", function(self)
		self:SetAlpha(1)
		self.State = true
		GameTooltip:SetOwner(self, "ANCHOR_NONE ",40,-90)
		GameTooltip:SetText("Character Info")
		GameTooltip:AddLine("Show/Hide your Character Pane", 1, 1, 1)
		GameTooltip:Show()
	end)

	LUI.MicroMenu.Buttons.Player.Clicker:SetScript("OnLeave", function(self)
		if not CharacterFrame:IsShown() then
			self:SetAlpha(0)
		end
		self.State = nil
		GameTooltip:Hide()
	end)

	LUI.MicroMenu.Buttons.Player.Clicker:SetScript("OnClick", function(self)
		if CharacterFrame:IsShown() then
			HideUIPanel(CharacterFrame)
		else
			ShowUIPanel(CharacterFrame)
		end
	end)

	CharacterFrame:HookScript("OnShow", function(self)
		LUI.MicroMenu.Buttons.Player.Clicker:SetAlpha(1)
	end)

	CharacterFrame:HookScript("OnHide", function(self)
		if not LUI.MicroMenu.Buttons.Player.Clicker.State then
			LUI.MicroMenu.Buttons.Player.Clicker:SetAlpha(0)
		end
	end)

	self:SetMicroMenuPosition()

	-- little hack for the questframe
	local point, relframe, relpoint, x, y = QuestLogFrame:GetPoint()
	QuestLogFrame:ClearAllPoints()
	QuestLogFrame:SetPoint(point, relframe, relpoint, x, -105)

	-- talent alert frame
	if UnitLevel("player") < 10 then 
		TalentMicroButtonAlert:Hide() 
		LUI.MicroMenu.Buttons.Talents:RegisterEvent("PLAYER_LEVEL_UP")
	end
	LUI.MicroMenu.Buttons.Talents:SetScript("OnEvent", function(event) 
			if UnitLevel("player")+1 < 10 then TalentMicroButtonAlert:Hide() 
			else 
				TalentMicroButtonAlert:Show()
				LUI.MicroMenu.Buttons.Talents:UnregisterEvent("PLAYER_LEVEL_UP")
			end
	end)

	TalentMicroButtonAlert:ClearAllPoints()
	TalentMicroButtonAlert:SetPoint("TOP", LUI.MicroMenu.Buttons.Talents, "BOTTOM")

	TalentMicroButtonAlertBg:SetGradientAlpha("VERTICAL", micro_r/4, micro_g/4, micro_b/4, 1, 0, 0, 0, 1)

--	TalentMicroButtonAlertText:SetFont(Media:Fetch("font", "vibrocen"), 14, "NONE")

	TalentMicroButtonAlertArrow:ClearAllPoints()
	TalentMicroButtonAlertArrow:SetPoint("BOTTOM", TalentMicroButtonAlert, "TOP", 0, -6)

	TalentMicroButtonAlertGlow:SetTexCoord(0.40625000, 0.66015625, 0.82812500, 0.77343750)
	TalentMicroButtonAlertGlow:SetVertexColor(r, g, b, 0.5)
	TalentMicroButtonAlertGlow:ClearAllPoints()
	TalentMicroButtonAlertGlow:SetPoint("BOTTOM", TalentMicroButtonAlertArrow, "BOTTOM", 0, 0)

	-- TalentMicroButtonAlertArrowArrow:SetTexCoord(0.78515625, 0.99218750, 0.58789063, 0.54687500)
	-- TalentMicroButtonAlertArrowArrow:SetVertexColor(micro_r, micro_g, micro_b)

	-- TalentMicroButtonAlertGlowTopLeft:SetVertexColor(micro_r, micro_g, micro_b)
	-- TalentMicroButtonAlertGlowTopRight:SetVertexColor(micro_r, micro_g, micro_b)
	-- TalentMicroButtonAlertGlowBottomLeft:SetVertexColor(micro_r, micro_g, micro_b)
	-- TalentMicroButtonAlertGlowBottomRight:SetVertexColor(micro_r, micro_g, micro_b)

	-- TalentMicroButtonAlertGlowTop:SetVertexColor(micro_r, micro_g, micro_b)
	-- TalentMicroButtonAlertGlowBottom:SetVertexColor(micro_r, micro_g, micro_b)
	-- TalentMicroButtonAlertGlowLeft:SetVertexColor(micro_r, micro_g, micro_b)
	-- TalentMicroButtonAlertGlowRight:SetVertexColor(micro_r, micro_g, micro_b)

	-- greyscaled textures
	TalentMicroButtonAlertGlow:SetTexture("Interface\\AddOns\\LUI\\media\\TalentFrame-Parts")
	-- TalentMicroButtonAlertArrowArrow:SetTexture("Interface\\AddOns\\LUI\\media\\TalentFrame-Parts")

	-- TalentMicroButtonAlertGlowTopLeft:SetTexture("Interface\\AddOns\\LUI\\media\\TalentFrame-Parts")
	-- TalentMicroButtonAlertGlowTopRight:SetTexture("Interface\\AddOns\\LUI\\media\\TalentFrame-Parts")
	-- TalentMicroButtonAlertGlowBottomLeft:SetTexture("Interface\\AddOns\\LUI\\media\\TalentFrame-Parts")
	-- TalentMicroButtonAlertGlowBottomRight:SetTexture("Interface\\AddOns\\LUI\\media\\TalentFrame-Parts")

	-- TalentMicroButtonAlertGlowTop:SetTexture("Interface\\AddOns\\LUI\\media\\TALENTFRAME-HORIZONTAL2")
	-- TalentMicroButtonAlertGlowBottom:SetTexture("Interface\\AddOns\\LUI\\media\\TALENTFRAME-HORIZONTAL2")
	-- TalentMicroButtonAlertGlowLeft:SetTexture("Interface\\AddOns\\LUI\\media\\TALENTFRAME-VERTICAL2")
	-- TalentMicroButtonAlertGlowRight:SetTexture("Interface\\AddOns\\LUI\\media\\TALENTFRAME-VERTICAL2")

end

module.defaults = {
	profile = {
		X = 0,
		Y = -1,
		NaviX = -150,
		NaviY = 6,
	}
}

function module:LoadFrameOptions()
	local options = {
		name = "MicroMenu",
		type = "group",
		order = 6,
		args = {
			MicroMenuPosition = {
				name = "Micro Menu",
				type = "group",
				order = 1,
				guiInline = true,
				args = {
					MMX = {
						name = "X Value",
						desc = "X Value for your Micro Menu.\n\nNote:\nPositive values = right\nNegativ values = left\nDefault: "..dbd.profile.X,
						type = "input",
						get = function() return tostring(db.X) end,
						set = function(self,MMX)
							if MMX == nil or MMX == "" then
								MMX = 0
							end
							db.X = tonumber(MMX)

							module:SetMicroMenuPosition()
						end,
						order = 1,
					},
					MMY = {
						name = "Y Value",
						desc = "Y Value for your Micro Menu.\n\nNote:\nPositive values = up\nNegativ values = down\nDefault: "..dbd.profile.Y,
						type = "input",
						get = function() return tostring(db.Y) end,
						set = function(self,MMY)
							if MMY == nil or MMY == "" then
								MMY = 0
							end
							db.Y = tonumber(MMY)

							module:SetMicroMenuPosition()
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
						desc = "X Value for your Micro Menu Navigation Panel.\n\nNote:\nPositive values = right\nNegativ values = left\nDefault: "..dbd.profile.NaviX,
						type = "input",
						get = function() return tostring(db.NaviX) end,
						set = function(self,MMNaviX)
							if MMNaviX == nil or MMNaviX == "" then
								MMNaviX = 0
							end
							db.NaviX = tonumber(MMNaviX)

							module:SetMicroMenuPosition()
						end,
						order = 1,
					},
					MMNaviY = {
						name = "Y Value",
						desc = "Y Value for your Micro Menu Navigation Panel.\n\nNote:\nPositive values = up\nNegativ values = down\nDefault: "..dbd.profile.NaviY,
						type = "input",
						get = function() return tostring(db.NaviY) end,
						set = function(self,MMNaviY)
							if MMNaviY == nil or MMNaviY == "" then
								MMNaviY = 0
							end
							db.NaviY = tonumber(MMNaviY)

							module:SetMicroMenuPosition()
						end,
						order = 2,
					},
				},
			},
		},
	}

	return options
end

function module:OnInitialize()
	db, dbd = LUI:NewNamespace(self, nil, version)

	LUI:Module("Panels"):RegisterFrame(self)
end

function module:OnEnable()
	self:SetMicroMenu()
end
