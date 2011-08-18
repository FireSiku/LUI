--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: frames.lua
	Description: Frames Module
	Version....: 1.1
	Rev Date...: 16/01/2011 [dd/mm/yyyy]
	
	Edits:
		v1.0: Loui
		v1.1: Zista
]] 

-- External references.
local addonname, LUI = ...
local module = LUI:Module("Frames")
local Panels = LUI:Module("Panels")
local Themes = LUI:Module("Themes")
local Orb = LUI:Module("Orb")
local Media = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists

local db
local fdir = "Interface\\AddOns\\LUI\\media\\templates\\v3\\"

function module:SetOrbCycleColor()
	local orb_cycle = Themes.db.profile.orb_cycle
	LUI_OrbCycle:SetBackdropColor(unpack(orb_cycle))
end

function module:SetOrbHoverColor()
	local orb_hover = Themes.db.profile.orb_hover
	LUI_OrbHover:SetBackdropColor(unpack(orb_hover))
end

function module:SetBottomInfoColors()
	local color_bottom = Themes.db.profile.color_bottom
	finfo_back:SetBackdropColor(unpack(color_bottom))
	finfo2_back:SetBackdropColor(unpack(color_bottom))
end

function module:SetTopInfoColors()
	local color_top = Themes.db.profile.color_top
	finfo3_back:SetBackdropColor(unpack(color_top))
	finfo4_back:SetBackdropColor(unpack(color_top))
	top_frame2:SetBackdropColor(unpack(color_top))
end

function module:SetNavigationColors()
	local navi = Themes.db.profile.navi
	LUI_Navi_Button1:SetBackdropColor(unpack(navi))
	LUI_Navi_Button2:SetBackdropColor(unpack(navi))
	LUI_Navi_Button3:SetBackdropColor(unpack(navi))
	LUI_Navi_Button4:SetBackdropColor(unpack(navi))
end

function module:SetNavigationHoverColors()
	local navi_hover = Themes.db.profile.navi_hover
	LUI_Navi_Button1_hover:SetBackdropColor(unpack(navi_hover))
	LUI_Navi_Button2_hover:SetBackdropColor(unpack(navi_hover))
	LUI_Navi_Button3_hover:SetBackdropColor(unpack(navi_hover))
	LUI_Navi_Button4_hover:SetBackdropColor(unpack(navi_hover))
end

function module:SetNaviAlpha(frame, value)
	value = tonumber(value)
	
	if frame == "chat" then
		LUI_Navi_Button1:SetAlpha(value)
	elseif frame == "tps" then
		LUI_Navi_Button2:SetAlpha(value)
	elseif frame == "dps" then
		LUI_Navi_Button3:SetAlpha(value)
	elseif frame == "raid" then
		LUI_Navi_Button4:SetAlpha(value)
	end
end

function module:SetColors()
	self:SetNavigationHoverColors()
	self:SetNavigationColors()
	self:SetTopInfoColors()
	self:SetBottomInfoColors()
	self:SetOrbCycleColor()
	self:SetOrbHoverColor()
end

function module:SetFrames()
	local navi = Themes.db.profile.navi
	local navi_hover = Themes.db.profile.navi_hover
	local orb_hover = Themes.db.profile.orb_hover
	local color_bottom = Themes.db.profile.color_bottom
	local color_top = Themes.db.profile.color_top
	local orb_cycle = Themes.db.profile.orb_cycle
	
	local navi_anchor = LUI:CreateMeAFrame("FRAME","navi_anchor",UIParent,100,100,1,"BACKGROUND",1,"TOP",UIParent,"TOP",17,15,1)
	Orb:CreateMeAnOrb("LUI_Orb",55,navi_anchor,"CENTER",-17,0,1,"orb_filling8",0)

	local top_frame = LUI:CreateMeAFrame("FRAME","top_frame",UIParent,1024,1024,1,"BACKGROUND",1,"TOP",UIParent,"TOP",17,8,1)
	top_frame:SetBackdrop({
		bgFile=fdir.."top", 
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		tile=0, tileSize=0, edgeSize=1, 
		insets={left=0, right=0, top=0, bottom=0}
	})
	top_frame:SetBackdropBorderColor(0,0,0,0)
	top_frame:Show()
	
	local top_frame2 = LUI:CreateMeAFrame("FRAME","top_frame2",UIParent,1035,1024,1,"BACKGROUND",0,"TOP",UIParent,"TOP",17,5,1)
	top_frame2:SetBackdrop({
		bgFile=fdir.."top_back", 
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		tile=0, tileSize=0, edgeSize=1, 
		insets={left=0, right=0, top=0, bottom=0}
	})
	top_frame2:SetBackdropColor(unpack(color_top))
	top_frame2:SetBackdropBorderColor(0,0,0,0)
	top_frame2:Show()
	
	LUI_OrbHover = LUI:CreateMeAFrame("FRAME","orb_ring",LUI_Orb,68,68,1,"LOW",0,"CENTER",LUI_Orb,"CENTER",1,0,0)
	LUI_OrbHover:SetBackdrop({
		bgFile=fdir.."ring_inner", 
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		tile=0, tileSize=0, edgeSize=1, 
		insets={left=0, right=0, top=0, bottom=0}
	})
	LUI_OrbHover:SetBackdropColor(unpack(orb_hover))
	LUI_OrbHover:SetBackdropBorderColor(0,0,0,0)
	LUI_OrbHover:Show()
	
	local ring2 = LUI:CreateMeAFrame("FRAME","orb_ring2",LUI_Orb,103,103,1,"LOW",1,"CENTER",LUI_Orb,"CENTER",0,-1,1)
	ring2:SetBackdrop({
		bgFile=fdir.."ring", 
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		tile=0, tileSize=0, edgeSize=1, 
		insets={left=0, right=0, top=0, bottom=0}
	})
	ring2:SetBackdropColor(0.25,0.25,0.25,1)
	ring2:SetBackdropBorderColor(0,0,0,0)
	ring2:Show()
	
	local ring3 = LUI:CreateMeAFrame("FRAME","orb_ring3",LUI_Orb,107,107,1,"LOW",2,"CENTER",LUI_Orb,"CENTER",1,1,1)
	ring3:SetBackdrop({
		bgFile=fdir.."ring_inner", 
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		tile=0, tileSize=0, edgeSize=1, 
		insets={left=-0, right=0, top=0, bottom=0}
	})
	ring3:SetBackdropColor(0.25,0.25,0.25,0.7)
	ring3:SetBackdropBorderColor(0,0,0,0)
	ring3:Hide()
	
	local ring4 = LUI:CreateMeAFrame("FRAME","orb_ring4",LUI_Orb,115,115,1,"LOW",1,"CENTER",LUI_Orb,"CENTER",0,-1,1)
	ring4:SetBackdrop({
		bgFile=fdir.."ring_inner2", 
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		tile=0, tileSize=0, edgeSize=1, 
		insets={left=0, right=0, top=0, bottom=0}
	})
	ring4:SetBackdropBorderColor(0,0,0,0)
	ring4:Show()
	
	local ring5 = LUI:CreateMeAFrame("FRAME","orb_ring5",LUI_Orb,118,118,1,"LOW",2,"CENTER",LUI_Orb,"CENTER",0,-1,1)
	ring5:SetBackdrop({
		bgFile=fdir.."ring_inner3", 
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		tile=0, tileSize=0, edgeSize=1, 
		insets={left=0, right=0, top=0, bottom=0}
	})
	ring5:SetBackdropColor(0.25,0.25,0.25,0.7)
	ring5:SetBackdropBorderColor(0,0,0,0)
	ring5:Hide()
	
	LUI_OrbCycle = LUI:CreateMeAFrame("FRAME","orb_LUI_OrbCycle",LUI_Orb,115,115,1,"LOW",0,"CENTER",LUI_Orb,"CENTER",0,-1,1)
	LUI_OrbCycle:SetBackdrop({
		bgFile=fdir.."ring_inner4", 
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		tile=0, tileSize=0, edgeSize=1, 
		insets={left=0, right=0, top=0, bottom=0}
	})
	LUI_OrbCycle:SetBackdropColor(0.25,0.25,0.25,0.7)
	LUI_OrbCycle:SetBackdropBorderColor(0,0,0,0)
	LUI_OrbCycle:Show()
	
	local ring7 = LUI:CreateMeAFrame("FRAME","orb_ring7",LUI_Orb,77,75,1,"LOW",3,"CENTER",LUI_Orb,"CENTER",1,-1,1)
	ring7:SetBackdrop({
		bgFile=fdir.."ring", 
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		tile=0, tileSize=0, edgeSize=1, 
		insets={left=0, right=0, top=0, bottom=0}
	})
	ring7:SetBackdropBorderColor(0,0,0,0)
	ring7:Show()
	
	LUI_Navi_Button1 = LUI:CreateMeAFrame("FRAME","menu_button_chat",LUI_Orb,126,120,1,"LOW",1,"LEFT",LUI_Orb,"LEFT",-176,73,0)
	LUI_Navi_Button1:SetBackdrop({
		bgFile=fdir.."button_left2", 
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		tile=0, tileSize=0, edgeSize=1,
		insets={left=-0, right=0, top=0, bottom=0}
	})
	LUI_Navi_Button1:SetBackdropColor(unpack(navi))
	LUI_Navi_Button1:SetBackdropBorderColor(0,0,0,0)
	LUI_Navi_Button1:Show()
	
	LUI_Navi_Button1_hover = LUI:CreateMeAFrame("FRAME","menu_button_chat_hover",LUI_Orb,124,120,1,"LOW",1,"LEFT",LUI_Orb,"LEFT",-176,73,0)
	LUI_Navi_Button1_hover:SetBackdrop({
		bgFile=fdir.."button_left2_hover", 
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		tile=0, tileSize=0, edgeSize=1, 
		insets={left=-0, right=0, top=0, bottom=0}
	})
	LUI_Navi_Button1_hover:SetBackdropColor(unpack(navi_hover))
	LUI_Navi_Button1_hover:SetBackdropBorderColor(0,0,0,0)
	LUI_Navi_Button1_hover:Show()

	local LUI_Navi_Button1_frame = CreateFrame("Button","menu_button_chat_frame", menu_button_chat)
	LUI_Navi_Button1_frame:SetWidth(70)
	LUI_Navi_Button1_frame:SetHeight(30)
	LUI_Navi_Button1_frame:SetScale(1)
	LUI_Navi_Button1_frame:SetFrameStrata("LOW")
	LUI_Navi_Button1_frame:SetFrameLevel(2)
	LUI_Navi_Button1_frame:SetPoint("CENTER",menu_button_chat,"CENTER",-5,-42)
	LUI_Navi_Button1_frame:SetAlpha(0)

	LUI_Navi_Button2 = LUI:CreateMeAFrame("FRAME","menu_button_omen",LUI_Orb,63,67,1,"LOW",1,"LEFT",LUI_Orb,"LEFT",-74,42,0)
	LUI_Navi_Button2:SetBackdrop({
		bgFile=fdir.."button_left1", 
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		tile=0, tileSize=0, edgeSize=1, 
		insets={left=-0, right=0, top=0, bottom=0}
	})
	LUI_Navi_Button2:SetBackdropColor(unpack(navi))
	LUI_Navi_Button2:SetBackdropBorderColor(0,0,0,0)
	LUI_Navi_Button2:Show()
	
	LUI_Navi_Button2_hover = LUI:CreateMeAFrame("FRAME","menu_button_omen_hover",LUI_Orb,63,60,1,"LOW",1,"LEFT",LUI_Orb,"LEFT",-74,40,0)
	LUI_Navi_Button2_hover:SetBackdrop({
		bgFile=fdir.."button_left1_hover", 
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		tile=0, tileSize=0, edgeSize=1, 
		insets={left=-0, right=0, top=0, bottom=0}
	})
	LUI_Navi_Button2_hover:SetBackdropColor(unpack(navi_hover))
	LUI_Navi_Button2_hover:SetBackdropBorderColor(0,0,0,0)
	LUI_Navi_Button2_hover:Show()
	
	local LUI_Navi_Button2_frame = CreateFrame("Button","menu_button_omen_frame", menu_button_omen)
	LUI_Navi_Button2_frame:SetWidth(63)
	LUI_Navi_Button2_frame:SetHeight(30)
	LUI_Navi_Button2_frame:SetScale(1)
	LUI_Navi_Button2_frame:SetFrameStrata("LOW")
	LUI_Navi_Button2_frame:SetFrameLevel(2)
	LUI_Navi_Button2_frame:SetPoint("CENTER",menu_button_omen,"CENTER",0,-12)
	LUI_Navi_Button2_frame:SetAlpha(0)
	
	LUI_Navi_Button3 = LUI:CreateMeAFrame("FRAME","menu_button_recount",LUI_Orb,63,67,1,"LOW",1,"RIGHT",LUI_Orb,"RIGHT",77,45,0)
	LUI_Navi_Button3:SetBackdrop({
		bgFile=fdir.."button_right1", 
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		tile=0, tileSize=0, edgeSize=1, 
		insets={left=-0, right=0, top=0, bottom=0}
	})
	LUI_Navi_Button3:SetBackdropColor(unpack(navi))
	LUI_Navi_Button3:SetBackdropBorderColor(0,0,0,0)
	LUI_Navi_Button3:Show()
	
	LUI_Navi_Button3_hover = LUI:CreateMeAFrame("FRAME","menu_button_recount_hover",LUI_Orb,63,60,1,"LOW",1,"RIGHT",LUI_Orb,"RIGHT",77,43,0)
	LUI_Navi_Button3_hover:SetBackdrop({
		bgFile=fdir.."button_right1_hover", 
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		tile=0, tileSize=0, edgeSize=1, 
		insets={left=-0, right=0, top=0, bottom=0}
	})
	LUI_Navi_Button3_hover:SetBackdropColor(unpack(navi_hover))
	LUI_Navi_Button3_hover:SetBackdropBorderColor(0,0,0,0)
	LUI_Navi_Button3_hover:Show()
	
	local LUI_Navi_Button3_frame = CreateFrame("Button","menu_button_recount_frame", menu_button_recount)
	LUI_Navi_Button3_frame:SetWidth(63)
	LUI_Navi_Button3_frame:SetHeight(30)
	LUI_Navi_Button3_frame:SetScale(1)
	LUI_Navi_Button3_frame:SetFrameStrata("LOW")
	LUI_Navi_Button3_frame:SetFrameLevel(2)
	LUI_Navi_Button3_frame:SetPoint("CENTER",menu_button_recount,"CENTER",0,-12)
	LUI_Navi_Button3_frame:SetAlpha(0)
	
	LUI_Navi_Button4 = LUI:CreateMeAFrame("FRAME","menu_button_grid",LUI_Orb,126,120,1,"LOW",1,"RIGHT",LUI_Orb,"RIGHT",184,71,0)
	LUI_Navi_Button4:SetBackdrop({
		bgFile=fdir.."button_right2", 
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		tile=0, tileSize=0, edgeSize=1, 
		insets={left=-0, right=0, top=0, bottom=0}
	})
	LUI_Navi_Button4:SetBackdropColor(unpack(navi))
	LUI_Navi_Button4:SetBackdropBorderColor(0,0,0,0)
	LUI_Navi_Button4:Show()
	
	LUI_Navi_Button4_hover = LUI:CreateMeAFrame("FRAME","menu_button_grid_hover",LUI_Orb,124,120,1,"LOW",1,"RIGHT",LUI_Orb,"RIGHT",182,71,0)
	LUI_Navi_Button4_hover:SetBackdrop({
		bgFile=fdir.."button_right2_hover", 
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		tile=0, tileSize=0, edgeSize=1, 
		insets={left=-0, right=0, top=0, bottom=0}
	})
	LUI_Navi_Button4_hover:SetBackdropColor(unpack(navi_hover))
	LUI_Navi_Button4_hover:SetBackdropBorderColor(0,0,0,0)
	LUI_Navi_Button4_hover:Show()

	local LUI_Navi_Button4_frame = CreateFrame("Button","menu_button_grid_frame", menu_button_grid)
	LUI_Navi_Button4_frame:SetWidth(78)
	LUI_Navi_Button4_frame:SetHeight(30)
	LUI_Navi_Button4_frame:SetScale(1)
	LUI_Navi_Button4_frame:SetFrameStrata("LOW")
	LUI_Navi_Button4_frame:SetFrameLevel(2)
	LUI_Navi_Button4_frame:SetPoint("CENTER",menu_button_grid,"CENTER",0,-42)
	LUI_Navi_Button4_frame:SetAlpha(0)
	
	local orbtimerout, orbtimerin = 0,0
	local orb_timer = 0.3
	
	local OrbAlphaIn = CreateFrame("Frame", "OrbAlphaIn", UIParent)
	OrbAlphaIn:Hide()
	OrbAlphaIn:SetScript("OnUpdate", function(self,elapsed)
		orbtimerin = orbtimerin + elapsed
		if orbtimerin < orb_timer then
			local alpha = orbtimerin / orb_timer 
			LUI_OrbHover:SetAlpha(alpha)
		else
			LUI_OrbHover:SetAlpha(1)
			orbtimerin = 0
			self:Hide()
		end
	end)

	local OrbAlphaOut = CreateFrame("Frame", "OrbAlphaOut", UIParent)
	OrbAlphaOut:Hide()
	OrbAlphaOut:SetScript("OnUpdate", function(self,elapsed)
		orbtimerout = orbtimerout + elapsed
		if orbtimerout < orb_timer then
			local alpha = 1 - orbtimerout / orb_timer
			LUI_OrbHover:SetAlpha(alpha)
		else
			LUI_OrbHover:SetAlpha(0)
			orbtimerout = 0
			self:Hide()
		end
	end)
	
	LUI_Navi_Button1_frame:RegisterForClicks("AnyUp")
	LUI_Navi_Button1_frame:SetScript("OnClick", function(self)
		if LUI_Navi_Button1:GetAlpha() == 0 then
			ChatButtonAlphaIn:Show()
			if db.Chat.SecondChatFrame == true then
				ChatAlphaAnchor2:Show()
			end
			ChatAlphaAnchor:Show()
			if db.Frames.Chat.Animation == "AlphaSlide" then
				ChatAlphaIn:Show()
			else
				ChatAlphaAnchor:SetAlpha(1)
				if db.Chat.SecondChatFrame == true then
					ChatAlphaAnchor2:SetAlpha(1)
				end
			end
			
			db.Frames.IsChatShown = true
		else
			ChatButtonAlphaOut:Show()
			
			if db.Frames.Chat.Animation == "AlphaSlide" then
				ChatAlphaOut:Show()
			else
				ChatAlphaAnchor:SetAlpha(0)
				ChatAlphaAnchor:Hide()
				if db.Chat.SecondChatFrame == true then
					ChatAlphaAnchor2:SetAlpha(0)
					ChatAlphaAnchor2:Hide()
				end
			end
			
			db.Frames.IsChatShown = false
		end
	end)
	
	LUI_Navi_Button1_frame:SetScript("OnEnter", function(self)
		LUI_Navi_Button1_hover:SetAlpha(1)
	end)
	
	LUI_Navi_Button1_frame:SetScript("OnLeave", function(self)
		LUI_Navi_Button1_hover:SetAlpha(0)
	end)
	
	LUI_Navi_Button2_frame:RegisterForClicks("AnyUp")
	LUI_Navi_Button2_frame:SetScript("OnClick", function(self)
		if _G[db.Frames.Tps.Anchor] then 
			if LUI_Navi_Button2:GetAlpha() == 0 then
				OmenButtonAlphaIn:Show()
				
				_G[db.Frames.Tps.Anchor]:Show()
				
				for _, frame in pairs(Panels:LoadAdditional(db.Frames.Tps.Additional)) do
					_G[frame]:Show()
				end
				
				if db.Frames.Tps.Animation == "AlphaSlide" then
					OmenAlphaIn:Show()
				else
					_G[db.Frames.Tps.Anchor]:SetAlpha(1)
					
					for _, frame in pairs(Panels:LoadAdditional(db.Frames.Tps.Additional)) do
						_G[frame]:SetAlpha(1)
					end
				end
				
				db.Frames.IsTpsShown = true
			else
				OmenButtonAlphaOut:Show()
				
				if db.Frames.Tps.Animation == "AlphaSlide" then
					OmenAlphaOut:Show()
				else
					_G[db.Frames.Tps.Anchor]:SetAlpha(0)
					_G[db.Frames.Tps.Anchor]:Hide()
					
					for _, frame in pairs(Panels:LoadAdditional(db.Frames.Tps.Additional)) do
						_G[frame]:SetAlpha(0)
						_G[frame]:Hide()
					end
				end
				
				db.Frames.IsTpsShown = false
			end
		end
	end)
	
	LUI_Navi_Button2_frame:SetScript("OnEnter", function(self)
		LUI_Navi_Button2_hover:SetAlpha(1)
	end)
	
	LUI_Navi_Button2_frame:SetScript("OnLeave", function(self)
		LUI_Navi_Button2_hover:SetAlpha(0)
	end)
	
	LUI_Navi_Button3_frame:RegisterForClicks("AnyUp")
	LUI_Navi_Button3_frame:SetScript("OnClick", function(self)
		if _G[db.Frames.Dps.Anchor] then 
			if LUI_Navi_Button3:GetAlpha() == 0 then
				DPSButtonAlphaIn:Show()
				
				_G[db.Frames.Dps.Anchor]:Show()
				
				for _, frame in pairs(Panels:LoadAdditional(db.Frames.Dps.Additional)) do
					_G[frame]:Show()
				end
				
				if db.Frames.Dps.Animation == "AlphaSlide" then
					RecountAlphaIn:Show()
				else
					_G[db.Frames.Dps.Anchor]:SetAlpha(1)
					
					for _, frame in pairs(Panels:LoadAdditional(db.Frames.Dps.Additional)) do
						_G[frame]:SetAlpha(1)
					end
				end
				
				db.Frames.IsDpsShown = true
			else
				DPSButtonAlphaOut:Show()
				
				if db.Frames.Dps.Animation == "AlphaSlide" then
					RecountAlphaOut:Show()
				else
					_G[db.Frames.Dps.Anchor]:SetAlpha(0)
					_G[db.Frames.Dps.Anchor]:Hide()
					
					for _, frame in pairs(Panels:LoadAdditional(db.Frames.Dps.Additional)) do
						_G[frame]:SetAlpha(0)
						_G[frame]:Hide()
					end
				end
				
				db.Frames.IsDpsShown = false
			end
		end
	end)
	
	LUI_Navi_Button3_frame:SetScript("OnEnter", function(self)
		LUI_Navi_Button3_hover:SetAlpha(1)
	end)
	
	LUI_Navi_Button3_frame:SetScript("OnLeave", function(self)
		LUI_Navi_Button3_hover:SetAlpha(0)
	end)
	
	LUI_Navi_Button4_frame:RegisterForClicks("AnyUp")
	LUI_Navi_Button4_frame:SetScript("OnClick", function(self)
		if _G[db.Frames.Raid.Anchor] then 
			if LUI_Navi_Button4:GetAlpha() == 0 then
				GridButtonAlphaIn:Show()
				
				_G[db.Frames.Raid.Anchor]:Show()
				
				for _, frame in pairs(Panels:LoadAdditional(db.Frames.Raid.Additional)) do
					_G[frame]:Show()
				end
				
				if db.Frames.Raid.Animation == "AlphaSlide" then
					GridAlphaIn:Show()
				else
					_G[db.Frames.Raid.Anchor]:SetAlpha(1)
					
					for _, frame in pairs(Panels:LoadAdditional(db.Frames.Raid.Additional)) do
					_G[frame]:SetAlpha(1)
					end
				end
				
				db.Frames.IsRaidShown = true
			else
				GridButtonAlphaOut:Show()
				
				if db.Frames.Raid.Animation == "AlphaSlide" then
					GridAlphaOut:Show()
				else
					_G[db.Frames.Raid.Anchor]:SetAlpha(0)
					_G[db.Frames.Raid.Anchor]:Hide()
					
					for _, frame in pairs(Panels:LoadAdditional(db.Frames.Raid.Additional)) do
						_G[frame]:SetAlpha(0)
						_G[frame]:Hide()
					end
				end
				
				db.Frames.IsRaidShown = false
			end
		end
	end)
	
	LUI_Navi_Button4_frame:SetScript("OnEnter", function(self)
		LUI_Navi_Button4_hover:SetAlpha(1)
	end)
	
	LUI_Navi_Button4_frame:SetScript("OnLeave", function(self)
		LUI_Navi_Button4_hover:SetAlpha(0)
	end)
	
	------------------------------------------------------
	-- / INFO PANEL LEFT / --
	------------------------------------------------------

	local finfo_anchor = LUI:CreateMeAFrame("FRAME","finfo_anchor",UIParent,25,25,1,"BACKGROUND",0,"BOTTOMLEFT",UIParent,"BOTTOMLEFT",0,0,1)
	finfo_anchor:SetBackdrop({
		bgFile="Interface\\Tooltips\\UI-Tooltip-Background", 
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		tile=0, tileSize=0, edgeSize=1, 
		insets={left=0, right=0, top=0, bottom=0}
	})
	finfo_anchor:SetBackdropColor(0,0,0,0)
	finfo_anchor:SetBackdropBorderColor(0,0,0,0)
	finfo_anchor:Show()
	
	local finfo = LUI:CreateMeAFrame("FRAME","finfo",finfo_anchor,1024,1024,1,"BACKGROUND",1,"BOTTOMLEFT",finfo_anchor,"BOTTOMLEFT",-30,-31,1)
	finfo:SetBackdrop({
		bgFile=fdir.."info_left", 
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		tile=0, tileSize=0, edgeSize=1, 
		insets={left=0, right=0, top=0, bottom=0}
	})
	finfo:SetBackdropColor(0,0,0,0.9)
	finfo:SetBackdropBorderColor(0,0,0,0)
	finfo:Show()
	
	local finfo_back = LUI:CreateMeAFrame("FRAME","finfo_back",finfo_anchor,1024,1024,1,"BACKGROUND",0,"BOTTOMLEFT",finfo_anchor,"BOTTOMLEFT",-23,-23,1)
	finfo_back:SetBackdrop({
		bgFile=fdir.."info_left_back", 
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		tile=0, tileSize=0, edgeSize=1, 
		insets={left=0, right=0, top=0, bottom=0}
	})
	finfo_back:SetBackdropColor(unpack(color_bottom))
	finfo_back:SetBackdropBorderColor(0,0,0,0)
	finfo_back:Show()

	------------------------------------------------------
	-- / INFO PANEL RIGHT / --
	------------------------------------------------------

	local finfo2_anchor = LUI:CreateMeAFrame("FRAME","finfo2_anchor",UIParent,25,25,1,"BACKGROUND",0,"BOTTOMRIGHT",UIParent,"BOTTOMRIGHT",0,0,1)
	finfo2_anchor:SetBackdrop({
		bgFile="Interface\\Tooltips\\UI-Tooltip-Background", 
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		tile=0, tileSize=0, edgeSize=1, 
		insets={left=0, right=0, top=0, bottom=0}
	})
	finfo2_anchor:SetBackdropColor(0,0,0,0)
	finfo2_anchor:SetBackdropBorderColor(0,0,0,0)
	finfo2_anchor:Show() 
	
	local finfo2 = LUI:CreateMeAFrame("FRAME","finfo2",finfo2_anchor,1024,1024,1,"BACKGROUND",1,"BOTTOMRIGHT",finfo2_anchor,"BOTTOMRIGHT",36,-31,1)
	finfo2:SetBackdrop({
		bgFile=fdir.."info_right", 
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		tile=0, tileSize=0, edgeSize=1, 
		insets={left=0, right=0, top=0, bottom=0}
	})
	finfo2:SetBackdropColor(0,0,0,0.9)
	finfo2:SetBackdropBorderColor(0,0,0,0)
	finfo2:Show()
	
	local finfo2_back = LUI:CreateMeAFrame("FRAME","finfo2_back",finfo2_anchor,1024,1024,1,"BACKGROUND",0,"BOTTOMRIGHT",finfo2_anchor,"BOTTOMRIGHT",29,-23,1)
	finfo2_back:SetBackdrop({
		bgFile=fdir.."info_right_back", 
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		tile=0, tileSize=0, edgeSize=1, 
		insets={left=0, right=0, top=0, bottom=0}
	})
	finfo2_back:SetBackdropColor(unpack(color_bottom))
	finfo2_back:SetBackdropBorderColor(0,0,0,0)
	finfo2_back:Show()

	------------------------------------------------------
	-- / INFO PANEL TOPLEFT / --
	------------------------------------------------------

	local finfo3_anchor = LUI:CreateMeAFrame("FRAME","finfo3_anchor",UIParent,25,25,1,"BACKGROUND",0,"CENTER",LUI_Orb,"CENTER",-212,30,1)
	finfo3_anchor:SetBackdrop({
		bgFile="Interface\\Tooltips\\UI-Tooltip-Background", 
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		tile=0, tileSize=0, edgeSize=1, 
		insets={left=0, right=0, top=0, bottom=0}
	})
	finfo3_anchor:SetBackdropColor(0,0,0,0)
	finfo3_anchor:SetBackdropBorderColor(0,0,0,0)
	finfo3_anchor:Show() 
	
	local finfo3 = LUI:CreateMeAFrame("FRAME","finfo3",finfo3_anchor,1024,1024,1,"BACKGROUND",1,"TOPLEFT",finfo3_anchor,"TOPLEFT",400,17,1)
	finfo3:SetBackdrop({
		bgFile=fdir.."info_top_right", 
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		tile=0, tileSize=0, edgeSize=1, 
		insets={left=0, right=0, top=0, bottom=0}
	})
	finfo3:SetBackdropBorderColor(0,0,0,0)
	finfo3:Hide()
	
	local finfo3_back = LUI:CreateMeAFrame("FRAME","finfo3_back",finfo3_anchor,1012,1024,1,"BACKGROUND",0,"TOPRIGHT",finfo3_anchor,"TOPRIGHT",9,11,1)
	finfo3_back:SetBackdrop({
		bgFile=fdir.."info_top_left2", 
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		tile=0, tileSize=0, edgeSize=1, 
		insets={left=0, right=0, top=0, bottom=0}
	})
	finfo3_back:SetBackdropColor(unpack(color_top))
	finfo3_back:SetBackdropBorderColor(0,0,0,0)
	finfo3_back:Show()
	
	------------------------------------------------------
	-- / INFO PANEL TOPRIGHT / --
	------------------------------------------------------
	
	local finfo4_anchor = LUI:CreateMeAFrame("FRAME","finfo4_anchor",UIParent,25,25,1,"BACKGROUND",0,"CENTER",LUI_Orb,"CENTER",209,30,1)
	finfo4_anchor:SetBackdrop({
		bgFile="Interface\\Tooltips\\UI-Tooltip-Background", 
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		tile=0, tileSize=0, edgeSize=1, 
		insets={left=0, right=0, top=0, bottom=0}
	})
	finfo4_anchor:SetBackdropColor(0,0,0,0)
	finfo4_anchor:SetBackdropBorderColor(0,0,0,0)
	finfo4_anchor:Show() 
	
	local finfo4 = LUI:CreateMeAFrame("FRAME","finfo4",finfo4_anchor,1024,1024,1,"BACKGROUND",1,"TOPLEFT",finfo4_anchor,"TOPLEFT",400,17,1)
	finfo4:SetBackdrop({
		bgFile=fdir.."info_top_right", 
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		tile=0, tileSize=0, edgeSize=1, 
		insets={left=0, right=0, top=0, bottom=0}
	})
	finfo4:SetBackdropBorderColor(0,0,0,0)
	finfo4:Hide()
	
	local finfo4_back = LUI:CreateMeAFrame("FRAME","finfo4_back",finfo4_anchor,1017,1024,1,"BACKGROUND",0,"TOPLEFT",finfo4_anchor,"TOPLEFT",-9,11,1)
	finfo4_back:SetBackdrop({
		bgFile=fdir.."info_top_right2", 
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		tile=0, tileSize=0, edgeSize=1, 
		insets={left=0, right=0, top=0, bottom=0}
	})
	finfo4_back:SetBackdropColor(unpack(color_top))
	finfo4_back:SetBackdropBorderColor(0,0,0,0)
	finfo4_back:Show()
  
	local chatbuttontimerout, chatbuttontimerin = 0,0
	local omenbuttontimerout, omenbuttontimerin = 0,0
	local dpsbuttontimerout, dpsbuttontimerin = 0,0
	local gridbuttontimerout, gridbuttontimerin = 0,0
	local button_timer = 0.4
	
	local ChatButtonAlphaIn = CreateFrame("Frame", "ChatButtonAlphaIn", UIParent)
	ChatButtonAlphaIn:Hide()
	ChatButtonAlphaIn:SetScript("OnUpdate", function(self,elapsed)
		chatbuttontimerin = chatbuttontimerin + elapsed
		if chatbuttontimerin < button_timer then
			local alpha = chatbuttontimerin / button_timer 
			LUI_Navi_Button1:SetAlpha(alpha)
		else
			LUI_Navi_Button1:SetAlpha(1)
			chatbuttontimerin = 0
			self:Hide()
		end
	end)
	
	local ChatButtonAlphaOut = CreateFrame("Frame", "ChatButtonAlphaOut", UIParent)
	ChatButtonAlphaOut:Hide()
	ChatButtonAlphaOut:SetScript("OnUpdate", function(self,elapsed)
		chatbuttontimerout = chatbuttontimerout + elapsed
		if chatbuttontimerout < button_timer then
			local alpha = 1 - chatbuttontimerout / button_timer
			LUI_Navi_Button1:SetAlpha(alpha)
		else
			LUI_Navi_Button1:SetAlpha(0)
			chatbuttontimerout = 0
			self:Hide()
		end
	end)
	
	local OmenButtonAlphaIn = CreateFrame("Frame", "OmenButtonAlphaIn", UIParent)
	OmenButtonAlphaIn:Hide()
	OmenButtonAlphaIn:SetScript("OnUpdate", function(self,elapsed)
		omenbuttontimerin = omenbuttontimerin + elapsed
		if omenbuttontimerin < button_timer then
			local alpha = omenbuttontimerin / button_timer 
			LUI_Navi_Button2:SetAlpha(alpha)
		else
			LUI_Navi_Button2:SetAlpha(1)
			omenbuttontimerin = 0
			self:Hide()
		end
	end)
	
	local OmenButtonAlphaOut = CreateFrame("Frame", "OmenButtonAlphaOut", UIParent)
	OmenButtonAlphaOut:Hide()
	OmenButtonAlphaOut:SetScript("OnUpdate", function(self,elapsed)
		omenbuttontimerout = omenbuttontimerout + elapsed
		if omenbuttontimerout < button_timer then
			local alpha = 1 - omenbuttontimerout / button_timer
			LUI_Navi_Button2:SetAlpha(alpha)
		else
			LUI_Navi_Button2:SetAlpha(0)
			omenbuttontimerout = 0
			self:Hide()
		end
	end)
	
	local DPSButtonAlphaIn = CreateFrame("Frame", "DPSButtonAlphaIn", UIParent)
	DPSButtonAlphaIn:Hide()
	DPSButtonAlphaIn:SetScript("OnUpdate", function(self,elapsed)
		dpsbuttontimerin = dpsbuttontimerin + elapsed
		if dpsbuttontimerin < button_timer then
			local alpha = dpsbuttontimerin / button_timer 
			LUI_Navi_Button3:SetAlpha(alpha)
		else
			LUI_Navi_Button3:SetAlpha(1)
			dpsbuttontimerin = 0
			self:Hide()
		end
	end)
	
	local DPSButtonAlphaOut = CreateFrame("Frame", "DPSButtonAlphaOut", UIParent)
	DPSButtonAlphaOut:Hide()
	DPSButtonAlphaOut:SetScript("OnUpdate", function(self,elapsed)
		dpsbuttontimerout = dpsbuttontimerout + elapsed
		if dpsbuttontimerout < button_timer then
			local alpha = 1 - dpsbuttontimerout / button_timer
			LUI_Navi_Button3:SetAlpha(alpha)
		else
			LUI_Navi_Button3:SetAlpha(0)
			dpsbuttontimerout = 0
			self:Hide()
		end
	end)
	
	local GridButtonAlphaIn = CreateFrame("Frame", "GridButtonAlphaIn", UIParent)
	GridButtonAlphaIn:Hide()
	GridButtonAlphaIn:SetScript("OnUpdate", function(self,elapsed)
		gridbuttontimerin = gridbuttontimerin + elapsed
		if gridbuttontimerin < button_timer then
			local alpha = gridbuttontimerin / button_timer 
			LUI_Navi_Button4:SetAlpha(alpha)
		else
			LUI_Navi_Button4:SetAlpha(1)
			gridbuttontimerin = 0
			self:Hide()
		end
	end)
	
	local GridButtonAlphaOut = CreateFrame("Frame", "GridButtonAlphaOut", UIParent)
	GridButtonAlphaOut:Hide()
	GridButtonAlphaOut:SetScript("OnUpdate", function(self,elapsed)
		gridbuttontimerout = gridbuttontimerout + elapsed
		if gridbuttontimerout < button_timer then
			local alpha = 1 - gridbuttontimerout / button_timer
			LUI_Navi_Button4:SetAlpha(alpha)
		else
			LUI_Navi_Button4:SetAlpha(0)
			gridbuttontimerout = 0
			self:Hide()
		end
	end)
	
	LUI_Orb:RegisterForClicks("AnyUp")
	LUI_Orb:SetScript("OnClick", function(self)
		if db.Frames.IsChatShown == true and db.Frames.IsTpsShown == true and db.Frames.IsDpsShown == true and db.Frames.IsRaidShown == true then
			isAllShown = true
		else
			isAllShown = false
		end
		
		if not isAllShown then
			isAllShown = true
			
			LUI_OrbCycle:SetBackdropColor(unpack(orb_cycle))
			
			if LUI_Navi_Button1:GetAlpha() == 0 then
				ChatButtonAlphaIn:Show()
				
				if db.Chat.SecondChatFrame == true then
					ChatAlphaAnchor2:Show()
				end
				
				ChatAlphaAnchor:Show()
				
				if db.Frames.Chat.Animation == "AlphaSlide" then
					ChatAlphaIn:Show()
				else
					ChatAlphaAnchor:SetAlpha(1)
					if db.Chat.SecondChatFrame == true then
						ChatAlphaAnchor2:SetAlpha(1)
					end
				end
				
				db.Frames.IsChatShown = true
			end
			
			if LUI_Navi_Button2:GetAlpha() == 0 then
				if _G[db.Frames.Tps.Anchor] then
					OmenButtonAlphaIn:Show()
					
					_G[db.Frames.Tps.Anchor]:Show()
					
					for _, frame in pairs(Panels:LoadAdditional(db.Frames.Tps.Additional)) do
						_G[frame]:Show()
					end
				
					if db.Frames.Tps.Animation == "AlphaSlide" then
						OmenAlphaIn:Show()
					else
						_G[db.Frames.Tps.Anchor]:SetAlpha(1)
						
						for _, frame in pairs(Panels:LoadAdditional(db.Frames.Tps.Additional)) do
							_G[frame]:SetAlpha(1)
						end
					end
				end
				db.Frames.IsTpsShown = true
			end
			
			if LUI_Navi_Button3:GetAlpha() == 0 then
				if _G[db.Frames.Dps.Anchor] then
					DPSButtonAlphaIn:Show()
					
					_G[db.Frames.Dps.Anchor]:Show()
					
					for _, frame in pairs(Panels:LoadAdditional(db.Frames.Dps.Additional)) do
						_G[frame]:Show()
					end
					
					if db.Frames.Dps.Animation == "AlphaSlide" then
						RecountAlphaIn:Show()
					else
						_G[db.Frames.Dps.Anchor]:SetAlpha(1)
						
						for _, frame in pairs(Panels:LoadAdditional(db.Frames.Dps.Additional)) do
							_G[frame]:SetAlpha(1)
						end
					end
				end
				db.Frames.IsDpsShown = true
			end
			
			if LUI_Navi_Button4:GetAlpha() == 0 then
				if _G[db.Frames.Raid.Anchor] then 
					GridButtonAlphaIn:Show()
					
					_G[db.Frames.Raid.Anchor]:Show()
					
					for _, frame in pairs(Panels:LoadAdditional(db.Frames.Raid.Additional)) do
						_G[frame]:Show()
					end
					
					if db.Frames.Raid.Animation == "AlphaSlide" then
						GridAlphaIn:Show()
					else
						_G[db.Frames.Raid.Anchor]:SetAlpha(1)
						
						for _, frame in pairs(Panels:LoadAdditional(db.Frames.Raid.Additional)) do
							_G[frame]:SetAlpha(1)
						end
					end
				end
				db.Frames.IsRaidShown = true
			end
		else
			isAllShown = false
			LUI_OrbCycle:SetBackdropColor(0.25,0.25,0.25,0.7)

			if LUI_Navi_Button1:GetAlpha() == 1 then
				ChatButtonAlphaOut:Show()

				if db.Frames.Chat.Animation == "AlphaSlide" then
					ChatAlphaOut:Show()
				else
					ChatAlphaAnchor:SetAlpha(0)
					ChatAlphaAnchor:Hide()
					if db.Chat.SecondChatFrame == true then
						ChatAlphaAnchor2:SetAlpha(0)
						ChatAlphaAnchor2:Hide()
					end
				end
				db.Frames.IsChatShown = false
			end
			
			if LUI_Navi_Button2:GetAlpha() == 1 then
				if _G[db.Frames.Tps.Anchor] then 
					OmenButtonAlphaOut:Show()

					if db.Frames.Tps.Animation == "AlphaSlide" then
						OmenAlphaOut:Show()
					else
						_G[db.Frames.Tps.Anchor]:SetAlpha(0)
						_G[db.Frames.Tps.Anchor]:Hide()
						
						for _, frame in pairs(Panels:LoadAdditional(db.Frames.Tps.Additional)) do
							_G[frame]:SetAlpha(0)
							_G[frame]:Hide()
						end
					end
				end
				db.Frames.IsTpsShown = false
			end
			
			if LUI_Navi_Button3:GetAlpha() == 1 then
				if _G[db.Frames.Dps.Anchor] then 
					DPSButtonAlphaOut:Show()
					
					if db.Frames.Dps.Animation == "AlphaSlide" then
						RecountAlphaOut:Show()
					else
						_G[db.Frames.Dps.Anchor]:SetAlpha(0)
						_G[db.Frames.Dps.Anchor]:Hide()
						
						for _, frame in pairs(Panels:LoadAdditional(db.Frames.Dps.Additional)) do
							_G[frame]:SetAlpha(0)
							_G[frame]:Hide()
						end
					end
				end
				db.Frames.IsDpsShown = false
			end
			
			if LUI_Navi_Button4:GetAlpha() == 1 then
				if _G[db.Frames.Raid.Anchor] then 
					GridButtonAlphaOut:Show()
					
					if db.Frames.Raid.Animation == "AlphaSlide" then
						GridAlphaOut:Show()
					else
						_G[db.Frames.Raid.Anchor]:SetAlpha(0)
						_G[db.Frames.Raid.Anchor]:Hide()
						
						for _, frame in pairs(Panels:LoadAdditional(db.Frames.Raid.Additional)) do
							_G[frame]:SetAlpha(0)
							_G[frame]:Hide()
						end
					end
				end
				db.Frames.IsRaidShown = false
			end
		end
	end)
end

function module:OnInitialize()
	self.db = LUI.db.profile
	db = self.db
end

function module:OnEnable()
	self:SetFrames()
end

function module:OnDisable()
end