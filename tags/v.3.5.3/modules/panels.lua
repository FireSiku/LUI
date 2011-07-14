--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: panels.lua
	Description: Main Panels Module
	Version....: 1.1
	Rev Date...: 16/01/2011 [dd/mm/yyyy]
	
	Edits:
		v1.0: Loui
		v1.1: Zista
]] 

local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local LSM = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists
local LUIHook = LUI:GetModule("LUIHook")
local module = LUI:NewModule("Panels", "AceHook-3.0")

local db
local fdir = "Interface\\AddOns\\LUI\\media\\templates\\v3\\"

local frameBackgrounds = {'LEFT', 'RIGHT', 'NONE'}
local frameBackgrounds2 = {'LUI v3', 'NONE'}
local animations = {'AlphaSlide', 'None'}

local addonAnchors = {
	raid = {
		Grid = 'GridLayoutFrame',
		Grid2 = 'Grid2LayoutFrame',
		Healbot = 'HealBot_Action',
		Vuhdo = 'Vd1',
		oUF = 'oUF_LUI_raid',
		Blizzard = 'CompactRaidFrameContainer',
	},
	meter = {
		Recount = 'Recount_MainWindow',
		Omen = 'OmenAnchor',
		Skada = 'SkadaBarWindowSkada',
	}
}

function module:CheckPanels()
	local Frames = LUI:GetModule("Frames")

	if db.Frames.AlwaysShowChat == true and db.Frames.AlwaysShowTps == true and db.Frames.AlwaysShowDps == true and db.Frames.AlwaysShowRaid == true then
		isAllShown = true
		Frames:SetOrbCycleColor()
	else
		if db.Frames.IsChatShown == true and db.Frames.IsTpsShown == true and db.Frames.IsDpsShown == true and db.Frames.IsRaidShown == true then
			isAllShown = true
			Frames:SetOrbCycleColor()
		else
			isAllShown = false
			--LUI_OrbCycle:SetBackdropColor(0.25,0.25,0.25,0.7)
		end
	end
		
	if db.Frames.AlwaysShowMinimap == true or db.Frames.IsMinimapShown == true then
		Minimap:SetAlpha(1)
		Minimap:Show()
		db.Frames.IsMinimapShown = true
	else
		Minimap:SetAlpha(0)
		Minimap:Hide()
		db.Frames.IsMinimapShown = false
	end
		
	if db.Frames.AlwaysShowChat == true or db.Frames.IsChatShown == true then
		Frames:SetNaviAlpha("chat",1)
		
		ChatAlphaAnchor:SetAlpha(1)
		ChatFrame1:SetAlpha(1)
		ChatFrame2:SetAlpha(1)
		if db.Chat.SecondChatFrame == true then
			ChatAlphaAnchor2:SetAlpha(1)
		end
		db.Frames.IsChatShown = true
	else
		Frames:SetNaviAlpha("chat",0)

		ChatAlphaAnchor:SetAlpha(0)
		ChatFrame1:SetAlpha(1)
		ChatFrame2:SetAlpha(1)
		if db.Chat.SecondChatFrame == true then
			ChatAlphaAnchor2:SetAlpha(0)
		end
		db.Frames.IsChatShown = false
	end
		
	if db.Frames.AlwaysShowTps == true or db.Frames.IsTpsShown == true then
		if _G[db.Frames.Tps.Anchor] then 
			Frames:SetNaviAlpha("tps",1)
			
			_G[db.Frames.Tps.Anchor]:SetAlpha(1)
			_G[db.Frames.Tps.Anchor]:Show()
			
			db.Frames.IsTpsShown = true
		end
	else
		Frames:SetNaviAlpha("tps",0)

		if _G[db.Frames.Tps.Anchor] then 
			_G[db.Frames.Tps.Anchor]:SetAlpha(0)
			_G[db.Frames.Tps.Anchor]:Hide()
		end
		
		db.Frames.IsTpsShown = false
	end
		
	if db.Frames.AlwaysShowDps == true or db.Frames.IsDpsShown == true then
		if _G[db.Frames.Dps.Anchor] then 
			Frames:SetNaviAlpha("dps",1)
		
			_G[db.Frames.Dps.Anchor]:SetAlpha(1)
			_G[db.Frames.Dps.Anchor]:Show()
			
			db.Frames.IsDpsShown = true
		end
	else
		Frames:SetNaviAlpha("dps",0)
		
		if _G[db.Frames.Dps.Anchor] then 
			_G[db.Frames.Dps.Anchor]:SetAlpha(0)
			_G[db.Frames.Dps.Anchor]:Hide()
		end
		
		db.Frames.IsDpsShown = false
	end
		
	if db.Frames.AlwaysShowRaid == true or db.Frames.IsRaidShown == true then
		if _G[db.Frames.Raid.Anchor] then 
			Frames:SetNaviAlpha("raid",1)
		
			_G[db.Frames.Raid.Anchor]:SetAlpha(1)
			_G[db.Frames.Raid.Anchor]:Show()
			
			db.Frames.IsRaidShown = true
		end
	else
		Frames:SetNaviAlpha("raid",0)
		
		if _G[db.Frames.Raid.Anchor] then 
			_G[db.Frames.Raid.Anchor]:SetAlpha(0)
			_G[db.Frames.Raid.Anchor]:Hide()
		end
		
		db.Frames.IsRaidShown = false
	end
	
	if LUI:GetModule("Micromenu", true) then	
		if db.Frames.AlwaysShowMicroMenu == true or db.Frames.IsMicroMenuShown == true then
			MicroMenuButton:SetAlpha(1)
			MicroMenuButton:Show()
		else
			MicroMenuButton:SetAlpha(0)
			MicroMenuButton:Hide()
		end
	end
end

function module:LoadAdditional(str, debug)
	if str == nil or str == "" then return {} end
	
	local frames = {}
	
	if strfind(str, "%s") then
		local part1, part2
		while true do
			if strfind(str, "%s") == nil then break end
			part1, part2 = strsplit(" ", str, 2)
			str = part1..part2
		end
	end
	
	if strfind(str, ",") then
		local part1, part2
		while true do
			if strfind(str, ",") == nil then break end
			part1, part2 = strsplit(",", str, 2)
			if _G[part1] then
				table.insert(frames, part1)
			elseif debug then
				LUI:Print("Could not find frame named "..part1)
			end
			str = part2
		end
	end
	if str ~= nil and str ~= "" then
		if _G[str] then
			table.insert(frames, str)
		elseif debug then
			LUI:Print("Could not find frame named "..str)
		end
	end
	
	if debug then return end
	return frames
end

------------------------------------------------------
-- / Chat Panel / --
------------------------------------------------------

function module:SetChatBackground()
	local chatTex, chatBorderTex

	if db.Frames.Chat.FullTexture == true then
		if db.Frames.Chat.Background == "LEFT" then
			chatTex = fdir.."grid_full"
			chatBorderTex = fdir.."grid"
		else
			chatTex = fdir.."chat_full"
			chatBorderTex = fdir.."chat"
		end
	else
		if db.Frames.Chat.Background == "LEFT" then
			chatTex = fdir.."grid_half"
			chatBorderTex = fdir.."grid"
		else
			chatTex = fdir.."chat_half"
			chatBorderTex = fdir.."chat"
		end
	end

	ChatBG:SetBackdrop({bgFile=chatTex, edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=0, tileSize=0, edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
	ChatBG:SetBackdropColor(unpack(db.Colors.chat))
	ChatBG:SetBackdropBorderColor(0,0,0,0)
	ChatBG:SetPoint("TOPLEFT",ChatAlphaAnchor,"TOPLEFT",db.Frames.Chat.OffsetX,db.Frames.Chat.OffsetY)

	ChatBorder:SetBackdrop({bgFile=chatBorderTex, edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=0, tileSize=0, edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
	ChatBorder:SetBackdropColor(unpack(db.Colors.chatborder))
	ChatBorder:SetBackdropBorderColor(0,0,0,0)
	ChatBorder:SetPoint("TOPLEFT", ChatAlphaAnchor, "TOPLEFT", db.Frames.Chat.OffsetX, db.Frames.Chat.OffsetY)

	if db.Frames.Chat.Background == "NONE" then
		ChatBG:Hide()
		ChatBorder:Hide()
	else
		ChatBG:Show()
		ChatBorder:Show()
	end

	-- / 2nd Chat Panel / --

	if db.Frames.Chat.Chatframe2.FullTexture == true then
		if db.Frames.Chat.Chatframe2.Background == "LEFT" then
			chatTex = fdir.."grid_full"
			chatBorderTex = fdir.."grid"
		else
			chatTex = fdir.."chat_full"
			chatBorderTex = fdir.."chat"
		end
	else
		if db.Frames.Chat.Chatframe2.Background == "LEFT" then
			chatTex = fdir.."grid_half"
			chatBorderTex = fdir.."grid"
		else
			chatTex = fdir.."chat_half"
			chatBorderTex = fdir.."chat"
		end
	end

	Chat2BG:SetBackdrop({bgFile=chatTex, edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=0, tileSize=0, edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
	Chat2BG:SetBackdropColor(unpack(db.Colors.chat2))
	Chat2BG:SetBackdropBorderColor(0,0,0,0)
	Chat2BG:SetPoint("TOPLEFT",ChatAlphaAnchor2,"TOPLEFT",db.Frames.Chat.Chatframe2.OffsetX,db.Frames.Chat.Chatframe2.OffsetY)

	Chat2Border:SetBackdrop({bgFile=chatBorderTex, edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=0, tileSize=0, edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
	Chat2Border:SetBackdropColor(unpack(db.Colors.chat2border))
	Chat2Border:SetBackdropBorderColor(0,0,0,0)
	Chat2Border:SetPoint("TOPLEFT", ChatAlphaAnchor2, "TOPLEFT", db.Frames.Chat.Chatframe2.OffsetX, db.Frames.Chat.Chatframe2.OffsetY)

	if db.Frames.Chat.Chatframe2.Background == "NONE" or db.Chat.SecondChatFrame == false then
		Chat2BG:Hide()
		Chat2Border:Hide()
	else
		Chat2BG:Show()
		Chat2Border:Show()
	end
end

function module:CheckSecondChatFrame()
	if db.Chat.SecondChatFrame == true then
		ChatAlphaAnchor2:Show()

		if db.Frames.Chat.Chatframe2.Background == "NONE" then
			Chat2Border:Show()
			Chat2BG:Show()
		end
	else
		ChatAlphaAnchor2:Hide()
		Chat2Border:Hide()
		Chat2BG:Hide()
	end
end

function module:SetSecondChatAnchor()
	if LUI:GetModule("Chat", true) then
		ChatAlphaAnchor2:ClearAllPoints()
		ChatAlphaAnchor2:SetPoint("TOPLEFT", _G[db.Chat.SecondChatAnchor], "TOPLEFT", -10, 8)
	end
end

function module:SetChat()
	local ChatAlphaAnchor = CreateFrame("Frame", "ChatAlphaAnchor", UIParent)
	ChatAlphaAnchor:SetWidth(30)
	ChatAlphaAnchor:SetHeight(30)
	ChatAlphaAnchor:SetFrameStrata("BACKGROUND")
	ChatAlphaAnchor:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile =  "Interface/Tooltips/UI-Tooltip-Border",
		edgeSize= 15,
		insets = { left = 3, right = 3, top = 3, bottom = 3 }
	})
	ChatAlphaAnchor:SetPoint("TOPLEFT", ChatFrame1, "TOPLEFT", -3, 8)
	ChatAlphaAnchor:SetBackdropColor(0,0,0,0)
	ChatAlphaAnchor:SetBackdropBorderColor(0,0,0,0)
	ChatAlphaAnchor:SetAlpha(1)
	ChatAlphaAnchor:Show()

	local ChatAlphaAnchor2 = CreateFrame("Frame", "ChatAlphaAnchor2", UIParent)
	ChatAlphaAnchor2:SetWidth(30)
	ChatAlphaAnchor2:SetHeight(30)
	ChatAlphaAnchor2:SetFrameStrata("BACKGROUND")
	ChatAlphaAnchor2:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile =  "Interface/Tooltips/UI-Tooltip-Border",
		edgeSize= 15,
		insets = { left = 3, right = 3, top = 3, bottom = 3 }
	})
	ChatAlphaAnchor2:SetPoint("TOPLEFT", db.Chat.SecondChatAnchor, "TOPLEFT", -10, 8)
	ChatAlphaAnchor2:SetBackdropColor(0,0,0,0)
	ChatAlphaAnchor2:SetBackdropBorderColor(0,0,0,0)
	ChatAlphaAnchor2:SetAlpha(1)
	ChatAlphaAnchor2:Hide()

	local ChatBG = CreateFrame("FRAME","ChatBG",ChatAlphaAnchor)
	ChatBG:SetWidth(LUI:Scale(597))
	ChatBG:SetHeight(LUI:Scale(570))
	ChatBG:SetFrameStrata("BACKGROUND")
	ChatBG:SetFrameLevel(0)
	ChatBG:SetAlpha(1)
	ChatBG:Show()

	local ChatBorder = CreateFrame("FRAME","ChatBorder",ChatAlphaAnchor)
	ChatBorder:SetWidth(LUI:Scale(597))
	ChatBorder:SetHeight(LUI:Scale(570))
	ChatBorder:SetFrameStrata("BACKGROUND")
	ChatBorder:SetFrameLevel(0)
	ChatBorder:SetAlpha(1)
	ChatBorder:Show()

	local Chat2BG = CreateFrame("FRAME","Chat2BG",ChatAlphaAnchor)
	Chat2BG:SetWidth(LUI:Scale(565))
	Chat2BG:SetHeight(LUI:Scale(570))
	Chat2BG:SetFrameStrata("BACKGROUND")
	Chat2BG:SetFrameLevel(0)
	Chat2BG:SetAlpha(1)
	Chat2BG:Show()

	local Chat2Border = CreateFrame("FRAME","Chat2Border",ChatAlphaAnchor)
	Chat2Border:SetWidth(LUI:Scale(565))
	Chat2Border:SetHeight(LUI:Scale(570))
	Chat2Border:SetFrameStrata("BACKGROUND")
	Chat2Border:SetFrameLevel(0)
	Chat2Border:SetAlpha(1)
	Chat2Border:Show()

	self:SetChatBackground()
	self:SetSecondChatAnchor()
	self:CheckSecondChatFrame()

	local chattimerout,chattimerin = 0,0
	local alpha_timer = 0.5

	local ChatAlphaOut = CreateFrame("Frame", "ChatAlphaOut", UIParent)
	ChatAlphaOut:Hide()

	ChatAlphaOut:SetScript("OnUpdate", function(self, elapsed)
		chattimerout = chattimerout + elapsed
		if chattimerout < alpha_timer then
			local alpha = 1 - chattimerout / alpha_timer
			ChatAlphaAnchor:SetAlpha(alpha)
			if db.Chat.SecondChatFrame == true then
				ChatAlphaAnchor2:SetAlpha(alpha)
			end
		else
			ChatAlphaAnchor:SetAlpha(0)
			ChatAlphaAnchor:Hide()
			if db.Chat.SecondChatFrame == true then
				ChatAlphaAnchor2:SetAlpha(0)
				ChatAlphaAnchor2:Hide()
			end
			chattimerout = 0
			self:Hide()
		end
	end)

	local ChatAlphaIn = CreateFrame("Frame", "ChatAlphaIn", UIParent)
	ChatAlphaIn:Hide()

	ChatAlphaIn:SetScript("OnUpdate", function(self, elapsed)
		chattimerin = chattimerin + elapsed
		if db.Chat.SecondChatFrame == true then
			ChatAlphaAnchor2:Show()
		end
		ChatAlphaAnchor:Show()
		if chattimerin < alpha_timer then
			local alpha = chattimerin / alpha_timer
			if db.Chat.SecondChatFrame == true then
				ChatAlphaAnchor2:SetAlpha(alpha)
			end
			ChatAlphaAnchor:SetAlpha(alpha)
		else
			if db.Chat.SecondChatFrame == true then
				ChatAlphaAnchor2:SetAlpha(1)
			end
			ChatAlphaAnchor:SetAlpha(1)
			chattimerin = 0
			self:Hide()
		end
	end)
end

------------------------------------------------------
-- / TPS Panel / --
------------------------------------------------------

function module:SetOmenAggroBarColor()
	local r,g,b = unpack(db.Frames.Tps.AggroBarColor)
	Omen.db.profile.Bar.AggroBarColor.r = r
	Omen.db.profile.Bar.AggroBarColor.g = g
	Omen.db.profile.Bar.AggroBarColor.b = b
	Omen:UpdateBars()
end

function module:SetTpsBackground()
	if not _G[db.Frames.Tps.Anchor] then
		LUI:Print("Could not find frame named "..db.Frames.Tps.Anchor.." (Tps).")
		return
	end
	
	local tpsTex
	
	if db.Frames.Tps.FullTexture == true then
		tpsTex = fdir.."omen_full"
	else
		tpsTex = fdir.."omen_half"
	end

	TpsFrameBG:SetBackdrop({bgFile=tpsTex, edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=0, tileSize=0, edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
	TpsFrameBG:SetBackdropColor(unpack(db.Colors.tps))
	TpsFrameBG:SetBackdropBorderColor(0,0,0,0)
	TpsFrameBG:ClearAllPoints()
	TpsFrameBG:SetPoint("TOPLEFT", _G[db.Frames.Tps.Anchor], "TOPLEFT", tonumber(db.Frames.Tps.OffsetX), tonumber(db.Frames.Tps.OffsetY))
	TpsFrameBG:SetParent(_G[db.Frames.Tps.Anchor])

	TpsFrameBorder:SetBackdrop({bgFile=fdir.."omen", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=0, tileSize=0, edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
	TpsFrameBorder:SetBackdropColor(unpack(db.Colors.tpsborder))
	TpsFrameBorder:SetBackdropBorderColor(0,0,0,0)
	TpsFrameBorder:ClearAllPoints()
	TpsFrameBorder:SetPoint("TOPLEFT", _G[db.Frames.Tps.Anchor], "TOPLEFT", tonumber(db.Frames.Tps.OffsetX), tonumber(db.Frames.Tps.OffsetY))
	TpsFrameBorder:SetParent(_G[db.Frames.Tps.Anchor])

	if db.Frames.Tps.Background == "NONE" then
		TpsFrameBG:Hide()
		TpsFrameBorder:Hide()
	else
		TpsFrameBG:Show()
		TpsFrameBorder:Show()
	end
end

function module:SetTps()
	local TpsFrameBG = CreateFrame("FRAME", "TpsFrameBG", UIParent)
	TpsFrameBG:SetWidth(LUI:Scale(237))
	TpsFrameBG:SetHeight(LUI:Scale(285))
	TpsFrameBG:SetFrameStrata("BACKGROUND")
	TpsFrameBG:SetFrameLevel(0)
	TpsFrameBG:SetAlpha(1)
	TpsFrameBG:Show()

	local TpsFrameBorder = CreateFrame("FRAME", "TpsFrameBorder", UIParent)
	TpsFrameBorder:SetWidth(LUI:Scale(237))
	TpsFrameBorder:SetHeight(LUI:Scale(285))
	TpsFrameBorder:SetFrameStrata("BACKGROUND")
	TpsFrameBorder:SetFrameLevel(0)
	TpsFrameBorder:SetAlpha(1)
	TpsFrameBorder:Show()

	local omentimerout,omentimerin = 0,0
	local alpha_timer = 0.5

	local OmenAlphaOut = CreateFrame("Frame", "OmenAlphaOut", UIParent)
	OmenAlphaOut:Hide()

	OmenAlphaOut:SetScript("OnUpdate", function(self, elapsed)
		omentimerout = omentimerout + elapsed
		if omentimerout < alpha_timer then
			local alpha = 1 - omentimerout / alpha_timer

			if _G[db.Frames.Tps.Anchor] then
				_G[db.Frames.Tps.Anchor]:SetAlpha(alpha)
				for _, frame in pairs(module:LoadAdditional(db.Frames.Tps.Additional)) do
					if _G[frame] then
						_G[frame]:SetAlpha(alpha)
					end
				end
			end
		else
			if _G[db.Frames.Tps.Anchor] then
				_G[db.Frames.Tps.Anchor]:SetAlpha(0)
				_G[db.Frames.Tps.Anchor]:Hide()
				for _, frame in pairs(module:LoadAdditional(db.Frames.Tps.Additional)) do
					if _G[frame] then
						_G[frame]:SetAlpha(0)
						_G[frame]:Hide()
					end
				end
			end

			omentimerout = 0
			self:Hide()
		end
	end)

	local OmenAlphaIn = CreateFrame("Frame", "OmenAlphaIn", UIParent)
	OmenAlphaIn:Hide()

	OmenAlphaIn:SetScript("OnUpdate", function(self, elapsed)
		omentimerin = omentimerin + elapsed
		if omentimerin < alpha_timer then
			local alpha = omentimerin / alpha_timer

			if _G[db.Frames.Tps.Anchor] then
				_G[db.Frames.Tps.Anchor]:SetAlpha(alpha)
				for _, frame in pairs(module:LoadAdditional(db.Frames.Tps.Additional)) do
					if _G[frame] then
						_G[frame]:SetAlpha(alpha)
					end
				end
			end
		else
			if _G[db.Frames.Tps.Anchor] then
				_G[db.Frames.Tps.Anchor]:SetAlpha(1)
				for _, frame in pairs(module:LoadAdditional(db.Frames.Tps.Additional)) do
					if _G[frame] then
						_G[frame]:SetAlpha(1)
					end
				end
			end

			omentimerin = 0
			self:Hide()
		end
	end)

	local CreateTps = CreateFrame("Frame", nil, UIParent)

	CreateTps:RegisterEvent("PLAYER_ENTERING_WORLD")
	CreateTps:SetScript("OnEvent", function(self)
		if _G[db.Frames.Tps.Anchor] then
			module:SetTpsBackground()
			CreateTps:UnregisterEvent("PLAYER_ENTERING_WORLD")
		end
	end)

	if IsAddOnLoaded("Omen") or IsAddOnLoaded("Omen3") then
		self:SetOmenAggroBarColor()
	end
end

------------------------------------------------------
-- / DPS Panel / --
------------------------------------------------------

function module:SetDpsBackground()
	if not _G[db.Frames.Dps.Anchor] then
		LUI:Print("Could not find frame named "..db.Frames.Dps.Anchor.." (Dps).")
		return
	end
	
	local dpsTex
	
	if db.Frames.Dps.FullTexture == true then
		dpsTex = fdir.."omen_full"
	else
		dpsTex = fdir.."omen_half"
	end

	DpsFrameBG:SetBackdrop({bgFile=dpsTex, edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=0, tileSize=0, edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
	DpsFrameBG:SetBackdropColor(unpack(db.Colors.dps))
	DpsFrameBG:SetBackdropBorderColor(0,0,0,0)
	DpsFrameBG:ClearAllPoints()
	DpsFrameBG:SetPoint("TOPLEFT", _G[db.Frames.Dps.Anchor], "TOPLEFT", tonumber(db.Frames.Dps.OffsetX), tonumber(db.Frames.Dps.OffsetY))
	DpsFrameBG:SetParent(_G[db.Frames.Dps.Anchor])

	DpsFrameBorder:SetBackdrop({bgFile=fdir.."omen", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=0, tileSize=0, edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
	DpsFrameBorder:SetBackdropColor(unpack(db.Colors.dpsborder))
	DpsFrameBorder:SetBackdropBorderColor(0,0,0,0)
	DpsFrameBorder:ClearAllPoints()
	DpsFrameBorder:SetPoint("TOPLEFT", _G[db.Frames.Dps.Anchor], "TOPLEFT", tonumber(db.Frames.Dps.OffsetX), tonumber(db.Frames.Dps.OffsetY))
	DpsFrameBorder:SetParent(_G[db.Frames.Dps.Anchor])

	if db.Frames.Dps.Background == "NONE" then
		DpsFrameBG:Hide()
		DpsFrameBorder:Hide()
	else
		DpsFrameBG:Show()
		DpsFrameBorder:Show()
	end
end

function module:SetDps()
	local DpsFrameBG = CreateFrame("FRAME", "DpsFrameBG", _G[db.Frames.Dps.Anchor])
	DpsFrameBG:SetWidth(LUI:Scale(237))
	DpsFrameBG:SetHeight(LUI:Scale(287))
	DpsFrameBG:SetFrameStrata("BACKGROUND")
	DpsFrameBG:SetFrameLevel(0)
	DpsFrameBG:SetAlpha(1)
	DpsFrameBG:Show()

	local DpsFrameBorder = CreateFrame("FRAME", "DpsFrameBorder", _G[db.Frames.Dps.Anchor])
	DpsFrameBorder:SetWidth(LUI:Scale(237))
	DpsFrameBorder:SetHeight(LUI:Scale(287))
	DpsFrameBorder:SetFrameStrata("BACKGROUND")
	DpsFrameBorder:SetFrameLevel(0)
	DpsFrameBorder:SetAlpha(1)
	DpsFrameBorder:Show()

	local recounttimerout, recounttimerin = 0,0
	local alpha_timer = 0.5

	local RecountAlphaOut = CreateFrame("Frame", "RecountAlphaOut", UIParent)
	RecountAlphaOut:Hide()

	RecountAlphaOut:SetScript("OnUpdate", function(self, elapsed)
		recounttimerout = recounttimerout + elapsed
		if recounttimerout < alpha_timer then
			local alpha = 1 - recounttimerout / alpha_timer

			if _G[db.Frames.Dps.Anchor] then
				 _G[db.Frames.Dps.Anchor]:SetAlpha(alpha)
				for _, frame in pairs(module:LoadAdditional(db.Frames.Dps.Additional)) do
					if _G[frame] then
						_G[frame]:SetAlpha(alpha)
					end
				end
			end
		else
			if _G[db.Frames.Dps.Anchor] then
				 _G[db.Frames.Dps.Anchor]:SetAlpha(0)
				 _G[db.Frames.Dps.Anchor]:Hide()
				for _, frame in pairs(module:LoadAdditional(db.Frames.Dps.Additional)) do
					if _G[frame] then
						 _G[frame]:SetAlpha(0)
						 _G[frame]:Hide()
					end
				end
			end

			recounttimerout = 0
			self:Hide()
		end
	end)

	local RecountAlphaIn = CreateFrame("Frame", "RecountAlphaIn", UIParent)
	RecountAlphaIn:Hide()

	RecountAlphaIn:SetScript("OnUpdate", function(self, elapsed)
		recounttimerin = recounttimerin + elapsed
		if recounttimerin < alpha_timer then
			local alpha = recounttimerin / alpha_timer

			if _G[db.Frames.Dps.Anchor] then
				_G[db.Frames.Dps.Anchor]:SetAlpha(alpha)
				for _, frame in pairs(module:LoadAdditional(db.Frames.Dps.Additional)) do
					if _G[frame] then
						_G[frame]:SetAlpha(alpha)
					end
				end
			end
		else
			if _G[db.Frames.Dps.Anchor] then
				_G[db.Frames.Dps.Anchor]:SetAlpha(1)
				for _, frame in pairs(module:LoadAdditional(db.Frames.Dps.Additional)) do
					if _G[frame] then
						_G[frame]:SetAlpha(1)
					end
				end
			end

			recounttimerin = 0
			self:Hide()
		end
	end)

	local CreateDps = CreateFrame("Frame", nil, UIParent)

	CreateDps:RegisterEvent("PLAYER_ENTERING_WORLD")
	CreateDps:SetScript("OnEvent", function(self)
		if _G[db.Frames.Dps.Anchor] then
			module:SetDpsBackground()
			CreateDps:UnregisterEvent("PLAYER_ENTERING_WORLD")
		end
	end)
end

------------------------------------------------------
-- / Raid Panel / --
------------------------------------------------------

function module:SetRaidBackground()
	if not _G[db.Frames.Raid.Anchor] then
		LUI:Print("Could not find frame named "..db.Frames.Raid.Anchor.." (Raid).")
		return
	end
	
	local raidTex, raidBorderTex

	if db.Frames.Raid.FullTexture == true then
		if db.Frames.Raid.Background == "LEFT" then
			raidTex = fdir.."grid_full"
			raidBorderTex = fdir.."grid"
		else
			raidTex = fdir.."chat_full"
			raidBorderTex = fdir.."chat"
		end
	else
		if db.Frames.Raid.Background == "LEFT" then
			raidTex = fdir.."grid_half"
			raidBorderTex = fdir.."grid"
		else
			raidTex = fdir.."chat_half"
			raidBorderTex = fdir.."chat"
		end
	end

	RaidFrameBG:SetBackdrop({bgFile=raidTex, edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=0, tileSize=0, edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
	RaidFrameBG:SetBackdropColor(unpack(db.Colors.raid))
	RaidFrameBG:SetBackdropBorderColor(0,0,0,0)
	RaidFrameBG:ClearAllPoints()
	RaidFrameBG:SetPoint("TOPLEFT", _G[db.Frames.Raid.Anchor], "TOPLEFT", tonumber(db.Frames.Raid.OffsetX), tonumber(db.Frames.Raid.OffsetY))
	RaidFrameBG:SetParent(_G[db.Frames.Raid.Anchor])

	RaidFrameBorder:SetBackdrop({bgFile=raidBorderTex, edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=0, tileSize=0, edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
	RaidFrameBorder:SetBackdropColor(unpack(db.Colors.raidborder))
	RaidFrameBorder:SetBackdropBorderColor(0,0,0,0)
	RaidFrameBorder:ClearAllPoints()
	RaidFrameBorder:SetPoint("TOPLEFT", _G[db.Frames.Raid.Anchor], "TOPLEFT", tonumber(db.Frames.Raid.OffsetX), tonumber(db.Frames.Raid.OffsetY))
	RaidFrameBorder:SetParent(_G[db.Frames.Raid.Anchor])

	if db.Frames.Raid.Background == "NONE" then
		RaidFrameBG:Hide()
		RaidFrameBorder:Hide()
	else
		RaidFrameBG:Show()
		RaidFrameBorder:Show()
	end
end

function module:SetRaid()
	local RaidFrameBG = CreateFrame("FRAME", "RaidFrameBG", _G[db.Frames.Raid.Anchor])
	RaidFrameBG:SetWidth(LUI:Scale(576))
	RaidFrameBG:SetHeight(LUI:Scale(576))
	RaidFrameBG:SetFrameStrata("BACKGROUND")
	RaidFrameBG:SetFrameLevel(0)
	RaidFrameBG:SetAlpha(1)
	RaidFrameBG:Show()

	local RaidFrameBorder = CreateFrame("FRAME", "RaidFrameBorder", _G[db.Frames.Raid.Anchor])
	RaidFrameBorder:SetWidth(LUI:Scale(576))
	RaidFrameBorder:SetHeight(LUI:Scale(576))
	RaidFrameBorder:SetFrameStrata("BACKGROUND")
	RaidFrameBorder:SetFrameLevel(0)
	RaidFrameBorder:SetAlpha(1)
	RaidFrameBorder:Show()

	local gridtimerout, gridtimerin = 0,0
	local alpha_timer = 0.5

	local GridAlphaOut = CreateFrame("Frame", "GridAlphaOut", UIParent)
	GridAlphaOut:Hide()

	GridAlphaOut:SetScript("OnUpdate", function(self, elapsed)
		gridtimerout = gridtimerout + elapsed
		if gridtimerout < alpha_timer then
			local alpha = 1 - gridtimerout / alpha_timer
			if _G[db.Frames.Raid.Anchor] then
				_G[db.Frames.Raid.Anchor]:SetAlpha(alpha)
				for _, frame in pairs(module:LoadAdditional(db.Frames.Raid.Additional)) do
					if _G[frame] then
						_G[frame]:SetAlpha(alpha)
					end
				end
			end
		else
			if _G[db.Frames.Raid.Anchor] then
				_G[db.Frames.Raid.Anchor]:SetAlpha(0)
				_G[db.Frames.Raid.Anchor]:Hide()
				for _, frame in pairs(module:LoadAdditional(db.Frames.Raid.Additional)) do
					if _G[frame] then
						_G[frame]:SetAlpha(0)
						_G[frame]:Hide()
					end
				end
			end
			gridtimerout = 0
			self:Hide()
		end
	end)

	local GridAlphaIn = CreateFrame("Frame", "GridAlphaIn", UIParent)
	GridAlphaIn:Hide()

	GridAlphaIn:SetScript("OnUpdate", function(self, elapsed)
		gridtimerin = gridtimerin + elapsed
		if gridtimerin < alpha_timer then
			local alpha = gridtimerin / alpha_timer
			if _G[db.Frames.Raid.Anchor] then
				_G[db.Frames.Raid.Anchor]:SetAlpha(alpha)
				for _, frame in pairs(module:LoadAdditional(db.Frames.Raid.Additional)) do
					if _G[frame] then
						_G[frame]:SetAlpha(alpha)
					end
				end
			end
		else
			if _G[db.Frames.Raid.Anchor] then
				_G[db.Frames.Raid.Anchor]:SetAlpha(1)
				for _, frame in pairs(module:LoadAdditional(db.Frames.Raid.Additional)) do
					if _G[frame] then
						_G[frame]:SetAlpha(1)
					end
				end
			end
			gridtimerin = 0
			self:Hide()
		end
	end)

	local CreateGrid = CreateFrame("Frame", nil, UIParent)

	CreateGrid:RegisterEvent("PLAYER_ENTERING_WORLD")
	CreateGrid:SetScript("OnEvent", function(self)
		if _G[db.Frames.Raid.Anchor] then
			module:SetRaidBackground()
			CreateGrid:UnregisterEvent("PLAYER_ENTERING_WORLD")
		end
	end)
end

-- special hack for boss/arena unitframes
local Blizz_UnitAnchor = CreateFrame("Frame")
Blizz_UnitAnchor:SetWidth(200)
Blizz_UnitAnchor:SetHeight(350)

function LUIHook:OnEnable()
	for i = 1, MAX_BOSS_FRAMES do
		_G["Boss"..i.."TargetFrame"]:ClearAllPoints()
		_G["Boss"..i.."TargetFrame"]:SetParent(Blizz_UnitAnchor)
		_G["Boss"..i.."TargetFrame"]:SetPoint("TOP", i == 1 and Blizz_UnitAnchor or _G["Boss"..(i-1).."TargetFrame"], i == 1 and "TOP" or "BOTTOM")
		_G["Boss"..i.."TargetFrame"].SetPoint = function() end
	end
end

function module:SetPanels()
	self:SetChat()
	self:SetTps()
	self:SetDps()
	self:SetRaid()
end

local defaults = {
	Frames = {
		AlwaysShowMinimap = true,
		AlwaysShowChat = false,
		AlwaysShowTps = false,
		AlwaysShowDps = false,
		AlwaysShowRaid = false,
		AlwaysShowMicroMenu = true,
		IsMinimapShown = false,
		IsMicroMenuShown = false,
		IsChatShown = false,
		IsTpsShown = false,
		IsDpsShown = false,
		IsRaidShown = false,
		Dps = {
			X = "-452",
			Y = "8",
			FullTexture = false,
			Background = "LUI v3",
			Anchor = "Recount_MainWindow",
			Additional = "",
			Animation = "AlphaSlide",
			OffsetX = "-15",
			OffsetY = "-13",
		},
		Tps = {
			X = "428.6",
			Y = "26.5",
			FullTexture = false,
			Animation = "AlphaSlide",
			Background = "LUI v3",
			Anchor = "OmenAnchor",
			Additional = "",
			ThemeAggroBarColor = true,
			AggroBarColor = { 0.5, 0.5, 0.5 },
			OffsetX = "-15",
			OffsetY = "16",
		},
		Raid = {
			X = "436",
			Y = "225",
			FullTexture = false,
			Animation = "AlphaSlide",
			Background = "LEFT",
			Anchor = "GridLayoutFrame",
			Additional = "",
			OffsetX = "-20",
			OffsetY = "9",
		},
		Chat = {
			Animation = "AlphaSlide",
			FullTexture = false,
			Background = "RIGHT",
			OffsetX = "-17",
			OffsetY = "10",
			Chatframe2 = {
				FullTexture = false,
				Background = "LEFT",
				OffsetX = "-17",
				OffsetY = "10",
			}
		},
	},
}

function module:LoadOptions()
	local options = {
		Frames = {
			name = "Frames",
			type = "group",
			order = 3,
			childGroups = "tab",
			args = {
				Tps = {
					name = "TPS",
					type = "group",
					desc = "TPS Frame Options",
					order = 1,
					args = {
						header1 = {
							name = "Threat Panel",
							type = "header",
							order = 1,
						},
						Addon = {
							name = "Addon",
							type = "group",
							order = 2,
							guiInline = true,
							args = {
								Intro = {
									order = 1,
									width = "full",
									type = "description",
									name = "Which ThreatMeter-Addon do you prefer?\nChoose one or type in the MainAnchor manually.",
								},
								spacer = {
									order = 2,
									width = "full",
									type = "description",
									name = " "
								},
								FrameModifierDesc = {
									order = 3,
									width = "full",
									type = "description",
									name = "Use the LUI Frame Identifier to search for the Parent Frame of your ThreatMeterAddon.\n\nOr use the Blizzard Debug Tool: Type /framestack"
								},
								LUIFrameIdentifier = {
									order = 4,
									type = "execute",
									name = "LUI Frame Identifier",
									func = function()
										LUI_Frame_Identifier:Show()
									end,
								},
								spacer2 = {
									order = 5,
									width = "full",
									type = "description",
									name = ""
								},
								ChooseAddon = {
									name = "Addon",
									desc = "Choose your TPS Meter Addon\n\nDefault: Omen",
									type = "select",
									values = function()
											local tpsAddons = {}
											for k, v in pairs(addonAnchors.meter) do
												table.insert(tpsAddons, k)
											end
											return tpsAddons
										end,
									get = function()
											local tpsAddon = ""
											local tpsAddons = {}
											
											for k, v in pairs(addonAnchors.meter) do
												if db.Frames.Tps.Anchor == v then
													tpsAddon = tostring(k)
												end
												table.insert(tpsAddons, k)
											end
											
											for k, v in pairs(tpsAddons) do
												if tpsAddon == v then
													return k
												end
											end
										end,
									set = function(self, ChooseAddon)
											local tpsLoop = 1
											for k, v in pairs(addonAnchors.meter) do
												if tostring(tpsLoop) == tostring(ChooseAddon) then
													db.Frames.Tps.Anchor = v
												end		
												tpsLoop = tpsLoop + 1
											end
											module:SetTpsBackground()
										end,
									order = 6,
								},
								AddonAnchor = {
									name = "Anchor",
									desc = "Type in your TpsMeter Anchorpoint manually.",
									type = "input",
									get = function() return db.Frames.Tps.Anchor end,
									set = function(self,AddonAnchor)
												if AddonAnchor ~= nil and AddonAnchor ~= "" then
													db.Frames.Tps.Anchor = AddonAnchor
													module:SetTpsBackground()
												else
													LUI:Print("You typed in an invalid Value!")
												end
											end,
									order = 7,
								},
								AdditionalFrames = {
									name = "Additional Frames",
									desc = "Type in any additional frame names (separated by commas)\nthat you would like to show/hide with the LUI TPSFrame.",
									type = "input",
									width = "double",
									get = function() return db.Frames.Tps.Additional end,
									set = function(self, AdditionalFrames)
											db.Frames.Tps.Additional = AdditionalFrames
											module:LoadAdditional(db.Frames.Tps.Additional, true)
										end,
									order = 8,
								},
							},
						},
						Position = {
							name = "Position",
							type = "group",
							order = 3,
							guiInline = true,
							args = {
								TpsX = {
									name = "X Value",
									desc = "X Value for your TPS Panel.\n\nNote:\nPositive values = right\nNegativ values = left\nDefault: "..LUI.defaults.profile.Frames.Tps.X,
									type = "input",
									get = function() return db.Frames.Tps.X end,
									set = function(self,TpsX)
												if TpsX == nil or TpsX == "" then
													TpsX = "0"
												end
												db.Frames.Tps.X = TpsX
											end,
									order = 1,
								},
								TpsY = {
									name = "Y Value",
									desc = "Y Value for your TPS Panel.\n\nNote:\nPositive values = up\nNegativ values = down\nDefault: "..LUI.defaults.profile.Frames.Tps.Y,
									type = "input",
									get = function() return db.Frames.Tps.Y end,
									set = function(self,TpsY)
												if TpsY == nil or TpsY == "" then
													TpsY = "0"
												end
												db.Frames.Tps.Y = TpsY
											end,
									order = 2,
								},
							},
						},
						AggroBarColor = {
							name = "AggroBar Color",
							type = "group",
							order = 4,
							disabled = function() 
								if IsAddOnLoaded("Omen") or IsAddOnLoaded("Omen3") then
									return false
								else
									return true
								end
							end,
							guiInline = true,
							args = {
								AggroBarColorDesc = {
									name = "This Feature is only available if you are using Omen3 Threatmeter.",
									type = "description",
									order = 1,
								},
								empty = {
									name = "   ",
									type = "description",
									order = 2,
								},
								ThemeAggroBarColor = {
									name = "Use Theme Color",
									desc = "Whether you want to use your Theme Color as AggroBar Color or not.\n",
									type = "toggle",
									width = "full",
									get = function() return db.Frames.Tps.ThemeAggroBarColor end,
									set = function(self,ThemeAggroBarColor)
											db.Frames.Tps.ThemeAggroBarColor = not db.Frames.Tps.ThemeAggroBarColor
											if ThemeAggroBarColor then
												Omen.db.profile.Bar.AggroBarColor.r = 0.592156862745098
												Omen.db.profile.Bar.AggroBarColor.g = 0.592156862745098
												Omen.db.profile.Bar.AggroBarColor.b = 0.592156862745098
											end
										end,
									order = 3,
								},
								AggroBarColor = {
									name = "AggroBar Color",
									desc = "Choose an individual AggroBar Color.",
									type = "color",
									width = "full",
									disabled = function() return db.Frames.Tps.ThemeAggroBarColor end,
									hasAlpha = false,
									get = function() return unpack(db.Frames.Tps.AggroBarColor) end,
									set = function(_,r,g,b)
											db.Frames.Tps.AggroBarColor = {r,g,b}
											module:SetOmenAggroBarColor()
										end,
									order = 4,
								},
							},
						},
						Background = {
							name = "Background",
							type = "group",
							order = 5,
							guiInline = true,
							args = {
								TpsTexture = {
									name = "Background Texture",
									desc = "Choose the Background Texture for Tps Panel\n\nDefault: "..LUI.defaults.profile.Frames.Tps.Background,
									type = "select",
									values = frameBackgrounds2,
									get = function()
											for k, v in pairs(frameBackgrounds2) do
												if db.Frames.Tps.Background == v then
													return k
												end
											end
										end,
									set = function(self, TpsTexture)
											db.Frames.Tps.Background = frameBackgrounds2[TpsTexture]
											local Panels = LUI:GetModule("Panels")
											Panels:SetTpsBackground()
										end,
									order = 1,
								},
								UseFullTexture = {
									name = "Use FullTexture",
									desc = "Wether you want to use gradient or nonAlpha Frame Textures",
									type = "toggle",
									get = function() return db.Frames.Tps.FullTexture end,
									set = function(self, UseFullTexture)
											db.Frames.Tps.FullTexture = not db.Frames.Tps.FullTexture
											local Panels = LUI:GetModule("Panels")
											Panels:SetTpsBackground()
										end,
									order = 2,
								},
								TpsBGOffsetX = {
									name = "X Offset",
									desc = "X Offset for your Tps Panel in Relation to your ThreatMeterAddon.\n\nNote:\nPositive values = right\nNegativ values = left\nDefault: "..LUI.defaults.profile.Frames.Tps.OffsetX,
									type = "input",
									get = function() return db.Frames.Tps.OffsetX end,
									set = function(self,TpsBGOffsetX)
											if TpsBGOffsetX == nil or TpsBGOffsetX == "" then
												TpsBGOffsetX = db.Frames.Tps.OffsetX
												print("Please try again...")
											end
											db.Frames.Tps.OffsetX = TpsBGOffsetX
											local Panels = LUI:GetModule("Panels")
											Panels:SetTpsBackground()
										end,
									order = 3,
								},
								TpsBGOffsetY = {
									name = "Y Offset",
									desc = "Y Offset for your Tps Panel in Relation to your ThreatMeterAddon.\n\nNote:\nPositive values = up\nNegativ values = down\nDefault: "..LUI.defaults.profile.Frames.Tps.OffsetY,
									type = "input",
									get = function() return db.Frames.Tps.OffsetY end,
									set = function(self,TpsBGOffsetY)
											if TpsBGOffsetY == nil or TpsBGOffsetY == "" then
												TpsBGOffsetY = db.Frames.Tps.OffsetY
												print("Please try again...")
											end
											db.Frames.Tps.OffsetY = TpsBGOffsetY
											local Panels = LUI:GetModule("Panels")
											Panels:SetTpsBackground()
										end,
									order = 4,
								},
								TpsBG = {
									name = "BG Color",
									desc = "Choose any Color for your Tps Panel",
									type = "color",
									hasAlpha = true,
									get = function() return unpack(db.Colors.tps) end,
									set = function(_,r,g,b,a)
											db.Colors.tps = {r,g,b,a}
											local Panels = LUI:GetModule("Panels")
											Panels:SetTpsBackground()
										end,
									order = 5,
								},
								TpsBorder = {
									name = "Border Color",
									desc = "Choose any Bordercolor for your Tps Panel",
									type = "color",
									hasAlpha = true,
									get = function() return unpack(db.Colors.tpsborder) end,
									set = function(_,r,g,b,a)
											db.Colors.tpsborder = {r,g,b,a}
											local Panels = LUI:GetModule("Panels")
											Panels:SetTpsBackground()
										end,
									order = 6,
								},
							},
						},
						Animation = {
							name = "Animation",
							type = "group",
							order = 6,
							guiInline = true,
							args = {
								SetAnimation = {
									name = "Choose Animation",
									desc = "Choose the Animation for opening/closing your TPS Panel\n\nDefault: "..LUI.defaults.profile.Frames.Tps.Animation,
									type = "select",
									values = animations,
									get = function()
											for k, v in pairs(animations) do
												if db.Frames.Tps.Animation == v then
													return k
												end
											end
										end,
									set = function(self, SetAnimation)
											db.Frames.Tps.Animation = animations[SetAnimation]
										end,
									order = 1,
								},
							},
						},
					},
				},
				Dps = {
					name = "DPS",
					type = "group",
					order = 2,
					args = {
						header1 = {
							name = "DPS Panel",
							type = "header",
							order = 1,
						},
						Addon = {
							name = "Addon",
							type = "group",
							order = 2,
							guiInline = true,
							args = {
								Intro = {
									order = 1,
									width = "full",
									type = "description",
									name = "Which DpsMeter-Addon do you prefer?\nChoose one or type in the MainAnchor manually.",
								},
								spacer = {
									order = 2,
									width = "full",
									type = "description",
									name = " "
								},
								FrameModifierDesc = {
									order = 3,
									width = "full",
									type = "description",
									name = "Use the LUI Frame Identifier to search for the Parent Frame of your DpsMeterAddon.\n\nOr use the Blizzard Debug Tool: Type /framestack"
								},
								LUIFrameIdentifier = {
									order = 4,
									type = "execute",
									name = "LUI Frame Identifier",
									func = function()
										LUI_Frame_Identifier:Show()
									end,
								},
								spacer2 = {
									order = 5,
									width = "full",
									type = "description",
									name = ""
								},
								ChooseAddon = {
									name = "Addon",
									desc = "Choose your DPS Meter Addon\n\nDefault: Recount",
									type = "select",
									values = function()
											local dpsAddons = {}
											for k, v in pairs(addonAnchors.meter) do
												table.insert(dpsAddons, k)
											end
											return dpsAddons
										end,
									get = function()
											local dpsAddon = ""
											local dpsAddons = {}
											
											for k, v in pairs(addonAnchors.meter) do
												if db.Frames.Dps.Anchor == v then
													dpsAddon = tostring(k)
												end
												table.insert(dpsAddons, k)
											end
											
											for k, v in pairs(dpsAddons) do
												if dpsAddon == v then
													return k
												end
											end
										end,
									set = function(self, ChooseAddon)
											local dpsLoop = 1
											for k, v in pairs(addonAnchors.meter) do
												if tostring(dpsLoop) == tostring(ChooseAddon) then
													db.Frames.Dps.Anchor = v
												end		
												dpsLoop = dpsLoop + 1
											end
											module:SetDpsBackground()
										end,
									order = 6,
								},
								AddonAnchor = {
									name = "Anchor",
									desc = "Type in your DpsMeter Anchorpoint manually.",
									type = "input",
									get = function() return db.Frames.Dps.Anchor end,
									set = function(self,AddonAnchor)
												if AddonAnchor ~= nil and AddonAnchor ~= "" then
													db.Frames.Dps.Anchor = AddonAnchor
													module:SetDpsBackground()
												else
													print("You typed in an invalid Value!")
												end
											end,
									order = 7,
								},
								AdditionalFrames = {
									name = "Additional Frames",
									desc = "Type in any additional frame names (separated by commas)\nthat you would like to show/hide with the LUI DPSFrame.",
									type = "input",
									width = "double",
									get = function() return db.Frames.Dps.Additional end,
									set = function(self, AdditionalFrames)
											db.Frames.Dps.Additional = AdditionalFrames
											module:LoadAdditional(db.Frames.Dps.Additional, true)
										end,
									order = 8,
								},
							},
						},
						Position = {
							name = "Position",
							type = "group",
							order = 3,
							guiInline = true,
							args = {
								DpsX = {
									name = "X Value",
									desc = "X Value for your Dps Panel.\n\nNote:\nPositive values = right\nNegativ values = left\nDefault: "..LUI.defaults.profile.Frames.Dps.X,
									type = "input",
									get = function() return db.Frames.Dps.X end,
									set = function(self,DpsX)
												if DpsX == nil or DpsX == "" then
													DpsX = "0"
												end
												db.Frames.Dps.X = DpsX
											end,
									order = 2,
								},
								DpsY = {
									name = "Y Value",
									desc = "Y Value for your Dps Panel.\n\nNote:\nPositive values = up\nNegativ values = down\nDefault: "..LUI.defaults.profile.Frames.Dps.Y,
									type = "input",
									get = function() return db.Frames.Dps.Y end,
									set = function(self,DpsY)
												if DpsY == nil or DpsY == "" then
													DpsY = "0"
												end
												db.Frames.Dps.Y = DpsY
											end,
									order = 3,
								},
							},
						},
						Background = {
							name = "Background",
							type = "group",
							order = 4,
							guiInline = true,
							args = {
								DpsTexture = {
									name = "Background Texture",
									desc = "Choose the Background Texture for Dps Panel\n\nDefault: "..LUI.defaults.profile.Frames.Dps.Background,
									type = "select",
									values = frameBackgrounds2,
									get = function()
											for k, v in pairs(frameBackgrounds2) do
												if db.Frames.Dps.Background == v then
													return k
												end
											end
										end,
									set = function(self, DpsTexture)
											db.Frames.Dps.Background = frameBackgrounds2[DpsTexture]
											local Panels = LUI:GetModule("Panels")
											Panels:SetDpsBackground()
										end,
									order = 1,
								},
								UseFullTexture = {
									name = "Use FullTexture",
									desc = "Wether you want to use gradient or nonAlpha Frame Textures",
									type = "toggle",
									get = function() return db.Frames.Dps.FullTexture end,
									set = function(self, UseFullTexture)
											db.Frames.Dps.FullTexture = not db.Frames.Dps.FullTexture
											local Panels = LUI:GetModule("Panels")
											Panels:SetDpsBackground()
										end,
									order = 2,
								},
								DpsBGOffsetX = {
									name = "X Offset",
									desc = "X Offset for your Dps Panel in Relation to your DpsAddon.\n\nNote:\nPositive values = right\nNegativ values = left\nDefault: "..LUI.defaults.profile.Frames.Dps.OffsetX,
									type = "input",
									get = function() return db.Frames.Dps.OffsetX end,
									set = function(self,DpsBGOffsetX)
											if DpsBGOffsetX == nil or DpsBGOffsetX == "" then
												DpsBGOffsetX = db.Frames.Dps.OffsetX
												print("Please try again...")
											end
											db.Frames.Dps.OffsetX = DpsBGOffsetX
											local Panels = LUI:GetModule("Panels")
											Panels:SetDpsBackground()
										end,
									order = 3,
								},
								DpsBGOffsetY = {
									name = "Y Offset",
									desc = "Y Offset for your Dps Panel in Relation to your DpsAddon.\n\nNote:\nPositive values = up\nNegativ values = down\nDefault: "..LUI.defaults.profile.Frames.Dps.OffsetY,
									type = "input",
									get = function() return db.Frames.Dps.OffsetY end,
									set = function(self,DpsBGOffsetY)
											if DpsBGOffsetY == nil or DpsBGOffsetY == "" then
												DpsBGOffsetY = db.Frames.Dps.OffsetY
												print("Please try again...")
											end
											db.Frames.Dps.OffsetY = DpsBGOffsetY
											local Panels = LUI:GetModule("Panels")
											Panels:SetDpsBackground()
										end,
									order = 4,
								},
								DpsBG = {
									name = "BG Color",
									desc = "Choose any Color for your Dps Panel",
									type = "color",
									hasAlpha = true,
									get = function() return unpack(db.Colors.dps) end,
									set = function(_,r,g,b,a)
											db.Colors.dps = {r,g,b,a}
											local Panels = LUI:GetModule("Panels")
											Panels:SetDpsBackground()
										end,
									order = 5,
								},
								DpsBorder = {
									name = "Border Color",
									desc = "Choose any Bordercolor for your Dps Panel",
									type = "color",
									hasAlpha = true,
									get = function() return unpack(db.Colors.dpsborder) end,
									set = function(_,r,g,b,a)
											db.Colors.dpsborder = {r,g,b,a}
											local Panels = LUI:GetModule("Panels")
											Panels:SetDpsBackground()
										end,
									order = 6,
								},
							},
						},
						Animation = {
							name = "Animation",
							type = "group",
							order = 5,
							guiInline = true,
							args = {
								SetAnimation = {
									name = "Choose Animation",
									desc = "Choose the Animation for opening/closing your DPS Panel\n\nDefault: "..LUI.defaults.profile.Frames.Dps.Animation,
									type = "select",
									values = animations,
									get = function()
											for k, v in pairs(animations) do
												if db.Frames.Dps.Animation == v then
													return k
												end
											end
										end,
									set = function(self, SetAnimation)
											db.Frames.Dps.Animation = animations[SetAnimation]
										end,
									order = 1,
								},
							},
						},
					},
				},
				Raidframes = {
					name = "Raid",
					type = "group",
					order = 3,
					args = {
						header1 = {
							name = "Raid Panel",
							type = "header",
							order = 1,
						},
						Addon = {
							name = "Addon",
							type = "group",
							order = 2,
							guiInline = true,
							args = {
								Intro = {
									order = 1,
									width = "full",
									type = "description",
									name = "Which Raidframe-Addon do you prefer?\nChoose one or type in the MainAnchor manually.",
								},
								spacer = {
									order = 2,
									width = "full",
									type = "description",
									name = " "
								},
								FrameModifierDesc = {
									order = 3,
									width = "full",
									type = "description",
									name = "Use the LUI Frame Identifier to search for the Parent Frame of your RaidAddon.\n\nOr use the Blizzard Debug Tool: Type /framestack"
								},
								LUIFrameIdentifier = {
									order = 4,
									type = "execute",
									name = "LUI Frame Identifier",
									func = function()
										LUI_Frame_Identifier:Show()
									end,
								},
								spacer2 = {
									order = 5,
									width = "full",
									type = "description",
									name = ""
								},
								ChooseAddon = {
									name = "Addon",
									desc = "Choose your Raidframe Addon\n\nDefault: Grid",
									type = "select",
									values = function()
											local raidAddons = {}
											for k, v in pairs(addonAnchors.raid) do
												table.insert(raidAddons, k)
											end
											return raidAddons
										end,
									get = function()
											local raidAddon = ""
											local raidAddons = {}
											
											for k, v in pairs(addonAnchors.raid) do
												if db.Frames.Raid.Anchor == v then
													raidAddon = tostring(k)
												end
												table.insert(raidAddons, k)
											end
											
											for k, v in pairs(raidAddons) do
												if raidAddon == v then
													return k
												end
											end
										end,
									set = function(self, ChooseAddon)
											local raidLoop = 1
											for k, v in pairs(addonAnchors.raid) do
												if tostring(raidLoop) == tostring(ChooseAddon) then
													db.Frames.Raid.Anchor = v
												end
												raidLoop = raidLoop + 1
											end
											db.oUF.Raid.Enable = (db.Frames.Raid.Anchor == addonAnchors.raid.oUF)
											module:SetRaidBackground()
										end,
									order = 6,
								},
								AddonAnchor = {
									name = "Anchor",
									desc = "Type in your RaidFrame Anchorpoint manually.",
									type = "input",
									get = function() return db.Frames.Raid.Anchor end,
									set = function(self,AddonAnchor)
											if AddonAnchor ~= nil and AddonAnchor ~= "" then
												db.Frames.Raid.Anchor = AddonAnchor
												module:SetRaidBackground()
											else
												print("You typed in an invalid Value!")
											end
										end,
									order = 7,
								},
								AdditionalFrames = {
									name = "Additional Frames",
									desc = "Type in any additional frame names (separated by commas)\nthat you would like to show/hide with the LUI RaidFrame.",
									type = "input",
									width = "double",
									get = function() return db.Frames.Raid.Additional end,
									set = function(self, AdditionalFrames)
											db.Frames.Raid.Additional = AdditionalFrames
											module:LoadAdditional(db.Frames.Raid.Additional, true)
										end,
									order = 8,
								},
							},
						},
						Position = {
							name = "Position",
							type = "group",
							order = 3,
							guiInline = true,
							args = {
								RaidX = {
									name = "X Value",
									desc = "X Value for your Raid Panel.\n\nNote:\nPositive values = right\nNegativ values = left\nDefault: "..LUI.defaults.profile.Frames.Raid.X,
									type = "input",
									get = function() return db.Frames.Raid.X end,
									set = function(self,RaidX)
												if RaidX == nil or RaidX == "" then
													RaidX = "0"
												end
												db.Frames.Raid.X = RaidX
											end,
									order = 1,
								},
								RaidY = {
									name = "Y Value",
									desc = "Y Value for your Raid Panel.\n\nNote:\nPositive values = up\nNegativ values = down\nDefault: "..LUI.defaults.profile.Frames.Raid.Y,
									type = "input",
									get = function() return db.Frames.Raid.Y end,
									set = function(self,RaidX)
												if RaidX == nil or RaidX == "" then
													RaidX = "0"
												end
												db.Frames.Raid.Y = RaidX
											end,
									order = 2,
								},
							},
						},
						Background = {
							name = "Background",
							type = "group",
							order = 4,
							guiInline = true,
							args = {
								RaidTexture = {
									name = "Background Texture",
									desc = "Choose the Background Texture for Raid Panel\n\nDefault: "..LUI.defaults.profile.Frames.Raid.Background,
									type = "select",
									values = frameBackgrounds,
									get = function()
											for k, v in pairs(frameBackgrounds) do
												if db.Frames.Raid.Background == v then
													return k
												end
											end
										end,
									set = function(self, RaidTexture)
											db.Frames.Raid.Background = frameBackgrounds[RaidTexture]
											local Panels = LUI:GetModule("Panels")
											Panels:SetRaidBackground()
										end,
									order = 1,
								},
								UseFullTexture = {
									name = "Use FullTexture",
									desc = "Wether you want to use gradient or nonAlpha Frame Textures",
									type = "toggle",
									get = function() return db.Frames.Raid.FullTexture end,
									set = function(self, UseFullTexture)
											db.Frames.Raid.FullTexture = not db.Frames.Raid.FullTexture
											local Panels = LUI:GetModule("Panels")
											Panels:SetRaidBackground()
										end,
									order = 2,
								},
								RaidBGOffsetX = {
									name = "X Offset",
									desc = "X Offset for your Raid Panel in Relation to your RaidFrame.\n\nNote:\nPositive values = right\nNegativ values = left\nDefault: "..LUI.defaults.profile.Frames.Raid.OffsetX,
									type = "input",
									get = function() return db.Frames.Raid.OffsetX end,
									set = function(self,RaidBGOffsetX)
											if RaidBGOffsetX == nil or RaidBGOffsetX == "" then
												RaidBGOffsetX = db.Frames.Raid.OffsetX
												print("Please try again...")
											end
											db.Frames.Raid.OffsetX = RaidBGOffsetX
											local Panels = LUI:GetModule("Panels")
											Panels:SetRaidBackground()
										end,
									order = 3,
								},
								RaidBGOffsetY = {
									name = "Y Offset",
									desc = "Y Offset for your Raid Panel in Relation to your RaidFrame.\n\nNote:\nPositive values = up\nNegativ values = down\nDefault: "..LUI.defaults.profile.Frames.Raid.OffsetY,
									type = "input",
									get = function() return db.Frames.Raid.OffsetY end,
									set = function(self,RaidBGOffsetY)
											if RaidBGOffsetY == nil or RaidBGOffsetY == "" then
												RaidBGOffsetY = db.Frames.Raid.OffsetY
												print("Please try again...")
											end
											db.Frames.Raid.OffsetY = RaidBGOffsetY
											local Panels = LUI:GetModule("Panels")
											Panels:SetRaidBackground()
										end,
									order = 4,
								},
								RaidBG = {
									name = "BG Color",
									desc = "Choose any Color for your Raid Panel",
									type = "color",
									hasAlpha = true,
									get = function() return unpack(db.Colors.raid) end,
									set = function(_,r,g,b,a)
											db.Colors.raid = {r,g,b,a}
											local Panels = LUI:GetModule("Panels")
											Panels:SetRaidBackground()
										end,
									order = 5,
								},
								RaidBorder = {
									name = "Border Color",
									desc = "Choose any Bordercolor for your Raid Panel",
									type = "color",
									hasAlpha = true,
									get = function() return unpack(db.Colors.raidborder) end,
									set = function(_,r,g,b,a)
											db.Colors.raidborder = {r,g,b,a}
											local Panels = LUI:GetModule("Panels")
											Panels:SetRaidBackground()
										end,
									order = 6,
								},
							},
						},
						Animation = {
							name = "Animation",
							type = "group",
							order = 5,
							guiInline = true,
							args = {
								SetAnimation = {
									name = "Choose Animation",
									desc = "Choose the Animation for opening/closing your Raid Panel\n\nDefault: "..LUI.defaults.profile.Frames.Raid.Animation,
									type = "select",
									values = animations,
									get = function()
											for k, v in pairs(animations) do
												if db.Frames.Raid.Animation == v then
													return k
												end
											end
										end,
									set = function(self, SetAnimation)
											db.Frames.Raid.Animation = animations[SetAnimation]
										end,
									order = 1,
								},
							},
						},
					},
				},
				Chat = {
					name = "Chat",
					type = "group",
					order = 8,
					args = {
						header1 = {
							name = "Chat Panel",
							type = "header",
							order = 1,
						},
						Background = {
							name = "Background",
							type = "group",
							order = 2,
							guiInline = true,
							args = {
								ChatTexture = {
									name = "Background Texture",
									desc = "Choose the Background Texture for Chat Panel\n\nDefault: "..LUI.defaults.profile.Frames.Chat.Background,
									type = "select",
									values = frameBackgrounds,
									get = function()
											for k, v in pairs(frameBackgrounds) do
												if db.Frames.Chat.Background == v then
													return k
												end
											end
										end,
									set = function(self, ChatTexture)
											db.Frames.Chat.Background = frameBackgrounds[ChatTexture]
											local Panels = LUI:GetModule("Panels")
											Panels:SetChatBackground()
										end,
									order = 1,
								},
								UseFullTexture = {
									name = "Use FullTexture",
									desc = "Wether you want to use gradient or nonAlpha Frame Textures",
									type = "toggle",
									get = function() return db.Frames.Chat.FullTexture end,
									set = function(self, UseFullTexture)
											db.Frames.Chat.FullTexture = not db.Frames.Chat.FullTexture
											local Panels = LUI:GetModule("Panels")
											Panels:SetChatBackground()
										end,
									order = 2,
								},
								ChatBGOffsetX = {
									name = "X Offset",
									desc = "X Offset for your Chat Panel in Relation to your ChatFrame.\n\nNote:\nPositive values = right\nNegativ values = left\nDefault: "..LUI.defaults.profile.Frames.Chat.OffsetX,
									type = "input",
									get = function() return db.Frames.Chat.OffsetX end,
									set = function(self,ChatBGOffsetX)
											if ChatBGOffsetX == nil or ChatBGOffsetX == "" then
												ChatBGOffsetX = db.Frames.Chat.OffsetX
												print("Please try again...")
											end
											db.Frames.Chat.OffsetX = ChatBGOffsetX
											local Panels = LUI:GetModule("Panels")
											Panels:SetChatBackground()
										end,
									order = 3,
								},
								ChatBGOffsetY = {
									name = "Y Offset",
									desc = "Y Offset for your Chat Panel in Relation to your ChatFrame.\n\nNote:\nPositive values = up\nNegativ values = down\nDefault: "..LUI.defaults.profile.Frames.Chat.OffsetY,
									type = "input",
									get = function() return db.Frames.Chat.OffsetY end,
									set = function(self,ChatBGOffsetY)
											if ChatBGOffsetY == nil or ChatBGOffsetY == "" then
												ChatBGOffsetY = db.Frames.Chat.OffsetY
												print("Please try again...")
											end
											db.Frames.Chat.OffsetY = ChatBGOffsetY
											local Panels = LUI:GetModule("Panels")
											Panels:SetChatBackground()
										end,
									order = 4,
								},
								ChatBG = {
									name = "BG Color",
									desc = "Choose any Color for your Chat Panel",
									type = "color",
									hasAlpha = true,
									get = function() return unpack(db.Colors.chat) end,
									set = function(_,r,g,b,a)
											db.Colors.chat = {r,g,b,a}
											local Panels = LUI:GetModule("Panels")
											Panels:SetChatBackground()
										end,
									order = 5,
								},
								ChatBorder = {
									name = "Border Color",
									desc = "Choose any Bordercolor for your Chat Panel",
									type = "color",
									hasAlpha = true,
									get = function() return unpack(db.Colors.chatborder) end,
									set = function(_,r,g,b,a)
											db.Colors.chatborder = {r,g,b,a}
											local Panels = LUI:GetModule("Panels")
											Panels:SetChatBackground()
										end,
									order = 6,
								},
							},
						},
						Animation = {
							name = "Animation",
							type = "group",
							order = 3,
							guiInline = true,
							args = {
								SetAnimation = {
									name = "Choose Animation",
									desc = "Choose the Animation for opening/closing your Chat Panel\n\nDefault: "..LUI.defaults.profile.Frames.Chat.Animation,
									type = "select",
									values = animations,
									get = function()
											for k, v in pairs(animations) do
												if db.Frames.Chat.Animation == v then
													return k
												end
											end
										end,
									set = function(self, SetAnimation)
											db.Frames.Chat.Animation = animations[SetAnimation]
										end,
									order = 1,
								},
							},
						},
						Background2 = {
							name = "2nd ChatFrame Background",
							type = "group",
							order = 4,
							disabled = function() return not db.Chat.SecondChatFrame end,
							guiInline = true,
							args = {
								ChatTexture = {
									name = "Background Texture",
									desc = "Choose the Background Texture for 2nd Chat Panel\n\nDefault: "..LUI.defaults.profile.Frames.Chat.Chatframe2.Background,
									type = "select",
									values = frameBackgrounds,
									get = function()
											for k, v in pairs(frameBackgrounds) do
												if db.Frames.Chat.Chatframe2.Background == v then
													return k
												end
											end
										end,
									set = function(self, ChatTexture)
											db.Frames.Chat.Chatframe2.Background = frameBackgrounds[ChatTexture]
											local Panels = LUI:GetModule("Panels")
											Panels:SetChatBackground()
										end,
									order = 1,
								},
								UseFullTexture = {
									name = "Use FullTexture",
									desc = "Wether you want to use gradient or nonAlpha Frame Textures",
									type = "toggle",
									get = function() return db.Frames.Chat.Chatframe2.FullTexture end,
									set = function(self, UseFullTexture)
											db.Frames.Chat.Chatframe2.FullTexture = not db.Frames.Chat.Chatframe2.FullTexture
											local Panels = LUI:GetModule("Panels")
											Panels:SetChatBackground()
										end,
									order = 2,
								},
								ChatBGOffsetX = {
									name = "X Offset",
									desc = "X Offset for your 2nd Chat Panel in Relation to your 2nd ChatFrame.\n\nNote:\nPositive values = right\nNegativ values = left\nDefault: "..LUI.defaults.profile.Frames.Chat.Chatframe2.OffsetX,
									type = "input",
									get = function() return db.Frames.Chat.Chatframe2.OffsetX end,
									set = function(self,ChatBGOffsetX)
											if ChatBGOffsetX == nil or ChatBGOffsetX == "" then
												ChatBGOffsetX = db.Frames.Chat.Chatframe2.OffsetX
												print("Please try again...")
											end
											db.Frames.Chat.Chatframe2.OffsetX = ChatBGOffsetX
											local Panels = LUI:GetModule("Panels")
											Panels:SetChatBackground()
										end,
									order = 3,
								},
								ChatBGOffsetY = {
									name = "Y Offset",
									desc = "Y Offset for your 2nd Chat Panel in Relation to your 2nd ChatFrame.\n\nNote:\nPositive values = up\nNegativ values = down\nDefault: "..LUI.defaults.profile.Frames.Chat.Chatframe2.OffsetY,
									type = "input",
									get = function() return db.Frames.Chat.Chatframe2.OffsetY end,
									set = function(self,ChatBGOffsetY)
											if ChatBGOffsetY == nil or ChatBGOffsetY == "" then
												ChatBGOffsetY = db.Frames.Chat.Chatframe2.OffsetY
												print("Please try again...")
											end
											db.Frames.Chat.Chatframe2.OffsetY = ChatBGOffsetY
											local Panels = LUI:GetModule("Panels")
											Panels:SetChatBackground()
										end,
									order = 4,
								},
								ChatBG = {
									name = "BG Color",
									desc = "Choose any Color for your 2nd Chat Panel",
									type = "color",
									hasAlpha = true,
									get = function() return unpack(db.Colors.chat2) end,
									set = function(_,r,g,b,a)
											db.Colors.chat2 = {r,g,b,a}
											local Panels = LUI:GetModule("Panels")
											Panels:SetChatBackground()
										end,
									order = 5,
								},
								ChatBorder = {
									name = "Border Color",
									desc = "Choose any Bordercolor for your 2nd Chat Panel",
									type = "color",
									hasAlpha = true,
									get = function() return unpack(db.Colors.chat2border) end,
									set = function(_,r,g,b,a)
											db.Colors.chat2border = {r,g,b,a}
											local Panels = LUI:GetModule("Panels")
											Panels:SetChatBackground()
										end,
									order = 6,
								},
							},
						},
					},
				},
			},
		},
	}

	return options
end

function module:OnInitialize()
	LUI:MergeDefaults(LUI.db.defaults.profile, defaults)
	LUI:RefreshDefaults()
	LUI:Refresh()
	
	self.db = LUI.db.profile
	db = self.db
	
	LUI:RegisterOptions(self) -- Change to a for loop with a RegisterFrame call for each frame (make options menu a template for each frame to pull from)
end

function module:OnEnable()
	self:SetPanels()
	
	local LUI_CheckPanels = CreateFrame("Frame", nil, UIParent)
	
	LUI_CheckPanels:RegisterEvent("PLAYER_ENTERING_WORLD")
	LUI_CheckPanels:SetScript("OnEvent", function(self, event, addon)
		module:CheckPanels()
		LUI_CheckPanels:UnregisterAllEvents()
	end)
end

function module:OnDisable()
end