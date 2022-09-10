--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: minimap.lua
	Description: Minimap Module
	Version....: 1.1
	Rev Date...: 02/01/2011

	Edits:
		v1.0: Loui
		v1.1: Zista
		v1.2: Darkruler
		v1.2b: Thaly
]]

-- External references.
local _, LUI = ...
local module = LUI:Module("Minimap", "AceHook-3.0", "AceEvent-3.0")
local Themes = LUI:Module("Themes")
local Media = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists

local db
local shouldntSetPoint = false
local fontflags = {'OUTLINE', 'THICKOUTLINE', 'MONOCHROME', 'NONE'}
local defaultGarrisonState = false

function module:SetAdditionalFrames()
	if db.Minimap.Enable ~= true then return end
	self:SecureHook(DurabilityFrame, "SetPoint", "DurabilityFrame_SetPoint")
	if (LUI.IsRetail) then
		self:SecureHook(VehicleSeatIndicator, "SetPoint", "VehicleSeatIndicator_SetPoint")
		self:SecureHook(ObjectiveTrackerFrame, "SetPoint", "ObjectiveTrackerFrame_SetPoint")
		self:SecureHook(UIWidgetTopCenterContainerFrame, "SetPoint", "AlwaysUpFrame_SetPoint")
		self:SecureHook(TicketStatusFrame, "SetPoint", "TicketStatus_SetPoint")
		self:SecureHook(UIWidgetBelowMinimapContainerFrame, "SetPoint", "CaptureBar_SetPoint")
		self:SecureHook(PlayerPowerBarAlt, "SetPoint", "PlayerPowerBarAlt_SetPoint")
		self:SecureHook(GroupLootContainer, "SetPoint", "GroupLootContainer_SetPoint")
		self:SecureHook(MawBuffsBelowMinimapFrame, "SetPoint", "MawBuffs_SetPoint")
	end
end

function module:SetPosition(frame)
	shouldntSetPoint = true
	if frame == "AlwaysUpFrame" and db.Minimap.Frames.SetAlwaysUpFrame then
		UIWidgetTopCenterContainerFrame:ClearAllPoints()
		UIWidgetTopCenterContainerFrame:SetPoint("TOP", UIParent, "TOP", db.Minimap.Frames.AlwaysUpFrameX, db.Minimap.Frames.AlwaysUpFrameY)
	elseif (LUI.IsRetail) and frame == "VehicleSeatIndicator" and db.Minimap.Frames.SetVehicleSeatIndicator then
		VehicleSeatIndicator:ClearAllPoints()
		VehicleSeatIndicator:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", db.Minimap.Frames.VehicleSeatIndicatorX, db.Minimap.Frames.VehicleSeatIndicatorY)
	elseif frame == "DurabilityFrame" and db.Minimap.Frames.SetDurabilityFrame then
		DurabilityFrame:ClearAllPoints()
		DurabilityFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", db.Minimap.Frames.DurabilityFrameX, db.Minimap.Frames.DurabilityFrameY)
	elseif (LUI.IsRetail) and frame == "ObjectiveTrackerFrame" and db.Minimap.Frames.SetObjectiveTrackerFrame then
		--ObjectiveTrackerFrame:ClearAllPoints() -- Cause a lot of odd behaviors with the quest tracker.
		ObjectiveTrackerFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", db.Minimap.Frames.ObjectiveTrackerFrameX, db.Minimap.Frames.ObjectiveTrackerFrameY)
	elseif frame == "TicketStatus" and db.Minimap.Frames.SetTicketStatus then
		TicketStatusFrame:ClearAllPoints()
		TicketStatusFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", db.Minimap.Frames.TicketStatusX, db.Minimap.Frames.TicketStatusY)
	elseif frame == "CaptureBar" and db.Minimap.Frames.SetCaptureBar then
		UIWidgetBelowMinimapContainerFrame:ClearAllPoints()
		UIWidgetBelowMinimapContainerFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", db.Minimap.Frames.CaptureBarX, db.Minimap.Frames.CaptureBarY)
	elseif frame == "PlayerPowerBarAlt" and db.Minimap.Frames.SetPlayerPowerBarAlt then
		PlayerPowerBarAlt:ClearAllPoints()
		PlayerPowerBarAlt:SetPoint("BOTTOM", UIParent, "BOTTOM", db.Minimap.Frames.PlayerPowerBarAltX, db.Minimap.Frames.PlayerPowerBarAltY)
	elseif frame == "GroupLootContainer" and db.Minimap.Frames.SetGroupLootContainer then
		GroupLootContainer:ClearAllPoints()
		GroupLootContainer:SetPoint("BOTTOM", UIParent, "BOTTOM", db.Minimap.Frames.GroupLootContainerX, db.Minimap.Frames.GroupLootContainerY)
	elseif frame == "MawBuffs" and db.Minimap.Frames.SetMawBuffs then
		MawBuffsBelowMinimapFrame:ClearAllPoints()
		MawBuffsBelowMinimapFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", db.Minimap.Frames.MawBuffsX, db.Minimap.Frames.MawBuffsY)
	end

	shouldntSetPoint = false
end

function module:DurabilityFrame_SetPoint()
	if shouldntSetPoint then return end
	self:SetPosition('DurabilityFrame')
end

function module:ObjectiveTrackerFrame_SetPoint()
	if shouldntSetPoint then return end
	self:SetPosition('ObjectiveTrackerFrame')
end

function module:VehicleSeatIndicator_SetPoint()
	if shouldntSetPoint then return end
	self:SetPosition('VehicleSeatIndicator')
end

function module:AlwaysUpFrame_SetPoint()
	if shouldntSetPoint then return end
	self:SetPosition('AlwaysUpFrame')
end

function module:CaptureBar_SetPoint()
	if shouldntSetPoint then return end
	self:SetPosition('CaptureBar')
end

function module:GroupLootContainer_SetPoint()
	if shouldntSetPoint then return end
	self:SetPosition('GroupLootContainer')
end

function module:PlayerPowerBarAlt_SetPoint()
	if shouldntSetPoint then return end
	self:SetPosition('PlayerPowerBarAlt')
end

function module:TicketStatus_SetPoint()
	if shouldntSetPoint then return end
	self:SetPosition('TicketStatus')
end

function module:MawBuffs_SetPoint()
	if shouldntSetPoint then return end
	self:SetPosition('MawBuffs')
end

function module:SetColors()
	local minimap_r, minimap_g, minimap_b, minimap_a = unpack(Themes.db.profile.minimap)

	fminimap_texture1:SetBackdropBorderColor(minimap_r,minimap_g,minimap_b,minimap_a)
	fminimap_texture3:SetBackdropBorderColor(minimap_r,minimap_g,minimap_b,minimap_a)
	fminimap_texture5:SetBackdropBorderColor(minimap_r,minimap_g,minimap_b,minimap_a)
	fminimap_texture7:SetBackdropBorderColor(minimap_r,minimap_g,minimap_b,minimap_a)
end

function module:SetMinimapFrames()
	local glowTex = LUI.Media.glowTex
	local minimap_r, minimap_g, minimap_b, minimap_a = unpack(Themes.db.profile.minimap)

	local fminimap_border = LUI:CreateMeAFrame("FRAME","fminimap_border",Minimap,143,143,1,"BACKGROUND",2,"CENTER",Minimap,"CENTER",0,0,1)
	fminimap_border:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile=glowTex, tile=0, tileSize=0, edgeSize=7, insets={left=0, right=0, top=0, bottom=0}})
	fminimap_border:SetBackdropColor(color_r,color_g,color_b,0)
	fminimap_border:SetBackdropBorderColor(0,0,0,1)

	local fminimap_texture1 = LUI:CreateMeAFrame("FRAME","fminimap_texture1",Minimap,50,50,1,"BACKGROUND",1,"BOTTOMLEFT",Minimap,"BOTTOMLEFT",-7,-7,1)
	fminimap_texture1:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile=glowTex, tile=0, tileSize=0, edgeSize=4, insets={left=3, right=3, top=3, bottom=3}})
	fminimap_texture1:SetBackdropColor(minimap_r,minimap_g,minimap_b,0)
	fminimap_texture1:SetBackdropBorderColor(minimap_r,minimap_g,minimap_b,minimap_a)

	local fminimap_texture2 = LUI:CreateMeAFrame("FRAME","fminimap_texture2",Minimap,56,56,1,"BACKGROUND",0,"BOTTOMLEFT",Minimap,"BOTTOMLEFT",-10,-10,1)
	fminimap_texture2:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile=glowTex, tile=0, tileSize=0, edgeSize=6, insets={left=3, right=3, top=3, bottom=3}})
	fminimap_texture2:SetBackdropColor(color_r,color_g,color_b,0)
	fminimap_texture2:SetBackdropBorderColor(0,0,0,1)

	local fminimap_texture3 = LUI:CreateMeAFrame("FRAME","fminimap_texture3",Minimap,50,50,1,"BACKGROUND",1,"BOTTOMRIGHT",Minimap,"BOTTOMRIGHT",7,-7,1)
	fminimap_texture3:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile=glowTex, tile=0, tileSize=0, edgeSize=4, insets={left=3, right=3, top=3, bottom=3}})
	fminimap_texture3:SetBackdropColor(minimap_r,minimap_g,minimap_b,0)
	fminimap_texture3:SetBackdropBorderColor(minimap_r,minimap_g,minimap_b,minimap_a)

	local fminimap_texture4 = LUI:CreateMeAFrame("FRAME","fminimap_texture4",Minimap,56,56,1,"BACKGROUND",0,"BOTTOMRIGHT",Minimap,"BOTTOMRIGHT",10,-10,1)
	fminimap_texture4:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile=glowTex, tile=0, tileSize=0, edgeSize=6, insets={left=3, right=3, top=3, bottom=3}})
	fminimap_texture4:SetBackdropColor(color_r,color_g,color_b,0)
	fminimap_texture4:SetBackdropBorderColor(0,0,0,1)

	local fminimap_texture5 = LUI:CreateMeAFrame("FRAME","fminimap_texture5",Minimap,50,50,1,"BACKGROUND",1,"TOPRIGHT",Minimap,"TOPRIGHT",7,7,1)
	fminimap_texture5:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile=glowTex, tile=0, tileSize=0, edgeSize=4, insets={left=3, right=3, top=3, bottom=3}})
	fminimap_texture5:SetBackdropColor(minimap_r,minimap_g,minimap_b,0)
	fminimap_texture5:SetBackdropBorderColor(minimap_r,minimap_g,minimap_b,minimap_a)

	local fminimap_texture6 = LUI:CreateMeAFrame("FRAME","fminimap_texture6",Minimap,56,56,1,"BACKGROUND",0,"TOPRIGHT",Minimap,"TOPRIGHT",10,10,1)
	fminimap_texture6:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile=glowTex, tile=0, tileSize=0, edgeSize=6, insets={left=3, right=3, top=3, bottom=3}})
	fminimap_texture6:SetBackdropColor(color_r,color_g,color_b,0)
	fminimap_texture6:SetBackdropBorderColor(0,0,0,1)

	local fminimap_texture7 = LUI:CreateMeAFrame("FRAME","fminimap_texture7",Minimap,50,50,1,"BACKGROUND",1,"TOPLEFT",Minimap,"TOPLEFT",-7,7,1)
	fminimap_texture7:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile=glowTex, tile=0, tileSize=0, edgeSize=4, insets={left=3, right=3, top=3, bottom=3}})
	fminimap_texture7:SetBackdropColor(minimap_r,minimap_g,minimap_b,0)
	fminimap_texture7:SetBackdropBorderColor(minimap_r,minimap_g,minimap_b,minimap_a)

	local fminimap_texture8 = LUI:CreateMeAFrame("FRAME","fminimap_texture8",Minimap,56,56,1,"BACKGROUND",0,"TOPLEFT",Minimap,"TOPLEFT",-10,10,1)
	fminimap_texture8:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile=glowTex, tile=0, tileSize=0, edgeSize=6, insets={left=3, right=3, top=3, bottom=3}})
	fminimap_texture8:SetBackdropColor(color_r,color_g,color_b,0)
	fminimap_texture8:SetBackdropBorderColor(0,0,0,1)

	for i=1, 8, 1 do
		if _G["fminimap_texture"..i] ~= nil then
			if db.Minimap.General.ShowTextures == true then
				_G["fminimap_texture"..i]:Show()
			else
				_G["fminimap_texture"..i]:Hide()
			end
		end
	end

	local minimaptimerout, minimaptimerin = 0,0
	local minimap_timer = 0.3

	local MinimapAlphaIn = CreateFrame( "Frame", "MinimapAlphaIn", UIParent)
	MinimapAlphaIn:Hide()
	MinimapAlphaIn:SetScript("OnUpdate", function(self, elapsed)
		minimaptimerin = minimaptimerin + elapsed
		Minimap:Show()
		if minimaptimerin < minimap_timer then
			local alpha = minimaptimerin / minimap_timer
			Minimap:SetAlpha(alpha)
		else
			Minimap:SetAlpha(1)
			minimaptimerin = 0
			self:Hide()
		end
	end)

	local MinimapAlphaOut = CreateFrame( "Frame", "MinimapAlphaOut", UIParent)
	MinimapAlphaOut:Hide()
	MinimapAlphaOut:SetScript("OnUpdate", function(self, elapsed)
		minimaptimerout = minimaptimerout + elapsed
		if minimaptimerout < minimap_timer then
			local alpha = 1 - minimaptimerout / minimap_timer
			Minimap:SetAlpha(alpha)
		else
			Minimap:SetAlpha(0)
			Minimap:Hide()
			minimaptimerout = 0
			self:Hide()
		end
	end)
end

function module:SetMinimapPosition()
	Minimap:ClearAllPoints()
	Minimap:SetPoint(db.Minimap.General.Position.Point, UIParent, db.Minimap.General.Position.RelativePoint, db.Minimap.General.Position.X, db.Minimap.General.Position.Y)
end

function module:SetMinimapSize()
	local zoom = Minimap:GetZoom()
	local size = db.Minimap.General.Size * 135
	Minimap:SetSize(LUI:Scale(size), LUI:Scale(size))
	fminimap_border:SetSize(LUI:Scale(size+8), LUI:Scale(size+8))
	-- change then reset zoom to make the minimap fill the display area
	Minimap:SetZoom(zoom == 0 and 1 or zoom-1)
	Minimap:SetZoom(zoom)
end

function module:SetMinimap()
	if db.Minimap.Enable ~= true then return end

	self:SetMinimapFrames()
	self:SetMinimapPosition()
	self:SetMinimapSize()
	self:SetPosition('DurabilityFrame')
	self:SetPosition('ObjectiveTrackerFrame')
	self:SetPosition('VehicleSeatIndicator')
	self:SetPosition('AlwaysUpFrame')
	self:SetPosition('CaptureBar')
	self:SetPosition('TicketStatus')

	local FONT = Media:Fetch("font", db.Minimap.Font.Font)

	--------------------------------------------------------------------
	-- MINIMAP SETTINGS
	--------------------------------------------------------------------

	-- Hide Border
	MinimapBorder:Hide()
	MinimapBorderTop:Hide()

	-- Hide Zoom Buttons
	MinimapZoomIn:Hide()
	MinimapZoomOut:Hide()

	-- GuildInstanceDifficulty
	if (LUI.IsRetail) then
		GuildInstanceDifficulty:UnregisterAllEvents()
		GuildInstanceDifficulty.NewShow = MiniMapInstanceDifficulty.Show
		GuildInstanceDifficulty.Show = GuildInstanceDifficulty.Hide
		GuildInstanceDifficulty:Hide()
	end
	-- MiniMapInstanceDifficulty
	MiniMapInstanceDifficulty.NewShow = MiniMapInstanceDifficulty.Show
	MiniMapInstanceDifficulty.Show = MiniMapInstanceDifficulty.Hide
	MiniMapInstanceDifficulty:Hide()

	-- MiniMapChallengeMode
	if (LUI.IsRetail) then
		MiniMapChallengeMode.NewShow = MiniMapChallengeMode.Show
		MiniMapChallengeMode.Show = MiniMapChallengeMode.Hide
		MiniMapChallengeMode:Hide()
	end
	-- Hide Voice Chat Frame
	--MiniMapVoiceChatFrame:Hide()

	-- Hide North texture at top
	MinimapNorthTag:SetTexture(nil)

	-- Hide Zone Frame
	MinimapZoneTextButton:Hide()

	-- Hide Clock
	TimeManagerClockButton:Hide()
	LUI:Kill(TimeManagerClockButton)

	-- Hide Tracking Button
	MiniMapTracking:Hide()

	-- Hide Calendar Button
	GameTimeFrame:Hide()

	-- Move Mail icon
	MiniMapMailFrame:ClearAllPoints()
	MiniMapMailFrame:SetPoint(db.Minimap.Icon.Mail, Minimap, LUI:Scale(3), LUI:Scale(6))
	MiniMapMailBorder:Hide()
	MiniMapMailIcon:SetTexture(LUI.Media.mail)

	-- Move battleground icon
	if (LUI.IsRetail) then
		QueueStatusMinimapButton:ClearAllPoints()
		QueueStatusMinimapButton:SetPoint(db.Minimap.Icon.BG, Minimap, LUI:Scale(3), 0)
		QueueStatusMinimapButtonBorder:Hide()
	end
	-- Move Garrison icon
	if (LUI.IsRetail) then
		module:SecureHook("GarrisonLandingPageMinimapButton_UpdateIcon", function()
			GarrisonLandingPageMinimapButton:SetSize(32,32)
			GarrisonLandingPageMinimapButton:ClearAllPoints()
			if MiniMapMailFrame:IsShown() then
				GarrisonLandingPageMinimapButton:SetPoint("BOTTOMLEFT", MiniMapMailFrame, "TOPLEFT", 0, LUI:Scale(-5))
			else
				GarrisonLandingPageMinimapButton:SetPoint(db.Minimap.Icon.Mail, Minimap, LUI:Scale(3), LUI:Scale(15))
			end
		end)
	end

	MiniMapMailFrame:HookScript("OnShow", function()
		GarrisonLandingPageMinimapButton:ClearAllPoints()
		GarrisonLandingPageMinimapButton:SetPoint("BOTTOMLEFT", MiniMapMailFrame, "TOPLEFT", 0, LUI:Scale(-5))
	end)
	MiniMapMailFrame:HookScript("OnHide", function()
		GarrisonLandingPageMinimapButton:ClearAllPoints()
		GarrisonLandingPageMinimapButton:SetPoint(db.Minimap.Icon.Mail, Minimap, LUI:Scale(3), LUI:Scale(15))
	end)

	-- Hide world map button
	MiniMapWorldMapButton:Hide()

	-- shitty 3.3 flag to move
	MiniMapInstanceDifficulty:ClearAllPoints()
	MiniMapInstanceDifficulty:SetParent(Minimap)
	MiniMapInstanceDifficulty:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)

	local function UpdateLFG()
		QueueStatusMinimapButton:ClearAllPoints()
		QueueStatusMinimapButton:SetPoint(db.Minimap.Icon.LFG, Minimap, db.Minimap.Icon.LFG, LUI:Scale(2), LUI:Scale(1))
		QueueStatusMinimapButtonBorder:Hide()
	end
	hooksecurefunc("EyeTemplate_OnUpdate", UpdateLFG)

	-- Enable mouse scrolling
	Minimap:EnableMouseWheel(true)
	Minimap:SetScript("OnMouseWheel", function(self, d)
		if IsShiftKeyDown() then
			db.Minimap.General.Size = db.Minimap.General.Size + ((d > 0 and 0.25) or (d < 0 and -0.25) or 0)
			if db.Minimap.General.Size > 2.5 then
				db.Minimap.General.Size = 2.5
			elseif db.Minimap.General.Size < 0.5 then
				db.Minimap.General.Size = 0.5
			end

			module:SetMinimapSize()
		else
			if d > 0 then
				_G.MinimapZoomIn:Click()
			elseif d < 0 then
				_G.MinimapZoomOut:Click()
			end
		end
	end)

	----------------------------------------------------------------------------------------
	-- Right click menu
	----------------------------------------------------------------------------------------

	local menuFrame = CreateFrame( "Frame", "MinimapRightClickMenu", UIParent, "UIDropDownMenuTemplate")
	local menuList = {
		{text = CHARACTER_BUTTON, 			func = function() ToggleCharacter("PaperDollFrame") end},
		{text = SPELLBOOK_ABILITIES_BUTTON, func = function() ToggleFrame(SpellBookFrame) end},
		{text = TALENTS_BUTTON, 			func = function() ToggleTalentFrame() end},
		{text = ACHIEVEMENT_BUTTON, 		func = function() ToggleAchievementFrame() end},
		{text = QUESTLOG_BUTTON, 			func = function() ToggleFrame(QuestLogFrame) end},
		{text = SOCIAL_BUTTON, 				func = function() ToggleFriendsFrame(1) end},
		{text = PLAYER_V_PLAYER, 			func = function() ToggleFrame(PVPFrame) end},
		{text = ACHIEVEMENTS_GUILD_TAB, 	func = function() if IsInGuild() then if not GuildFrame then LoadAddOn("Blizzard_GuildUI") end GuildFrame_Toggle() end end},
		{text = LFG_TITLE, 					func = function() ToggleFrame(LFDParentFrame) end},
		{text = L_LFRAID, 					func = function() ToggleFrame(LFRParentFrame) end},
		{text = HELP_BUTTON, 				func = function() ToggleHelpFrame() end},
		{text = L_CALENDAR, 				func = function() if(not CalendarFrame) then LoadAddOn("Blizzard_Calendar") end Calendar_Toggle() end},
	}

	Minimap:SetScript("OnMouseUp", function(self, btn)
		if btn == "RightButton" then
			ToggleDropDownMenu(1, nil, MiniMapTrackingDropDown, self)
		elseif btn == "MiddleButton" then
			EasyMenu(menuList, menuFrame, "cursor", 0, 0, "MENU", 2)
		else
			Minimap_OnClick(self)
		end
	end)


	-- Set Square Map Mask
	Minimap:SetMaskTexture('Interface\\ChatFrame\\ChatFrameBackground')

	-- For others mods with a minimap button, set minimap buttons position in square mode.
	--noinspection GlobalCreationOutsideO
	function GetMinimapShape() return "SQUARE" end

	----------------------------------------------------------------------------------------
	-- Animation Coords and Current Zone. Awesome feature by AlleyKat.
	----------------------------------------------------------------------------------------

	--Style Zone and Coord panels
	local m_zone = CreateFrame( "Frame","m_zone",Minimap)
	LUI:CreatePanel(m_zone, 0, 20, "TOPLEFT", Minimap, "TOPLEFT",LUI:Scale(2),LUI:Scale(-2))
	m_zone:SetFrameLevel(5)
	m_zone:SetFrameStrata("LOW")
	m_zone:SetPoint("TOPRIGHT",Minimap,-2,-2)
	m_zone:Hide()

	local m_zone_text = m_zone:CreateFontString("m_zone_text","Overlay")
	m_zone_text:SetFont(FONT,db.Minimap.Font.FontSize,db.Minimap.Font.FontFlag)
	m_zone_text:SetPoint("Center",0,0)
	m_zone_text:SetJustifyH("CENTER")
	m_zone_text:SetJustifyV("MIDDLE")
	m_zone_text:SetHeight(LUI:Scale(db.Minimap.Font.FontSize))
	m_zone_text:SetWidth(m_zone:GetWidth()-6)

	local m_coord = CreateFrame( "Frame","m_coord",Minimap)
	LUI:CreatePanel(m_coord, 40, 20, "BOTTOMLEFT", Minimap, "BOTTOMLEFT",LUI:Scale(2),LUI:Scale(2))
	m_coord:SetFrameStrata("MEDIUM")
	m_coord:Hide()

	local m_coord_text = m_coord:CreateFontString("m_coord_text","Overlay")
	m_coord_text:SetFont(FONT,db.Minimap.Font.FontSize,db.Minimap.Font.FontFlag)
	m_coord_text:SetPoint("Center",LUI:Scale(-1),0)
	m_coord_text:SetJustifyH("CENTER")
	m_coord_text:SetJustifyV("MIDDLE")
	m_coord_text:SetText("00,00")

	if db.Minimap.General.AlwaysShowText then
		m_zone:Show()
		if db.Minimap.General.ShowCoord then
			m_coord:Show()
		end
	end

	m_coord:SetScript("OnUpdate", function()
		local uiMap = C_Map.GetBestMapForUnit("player")
		if uiMap then
			local position = C_Map.GetPlayerMapPosition(uiMap, "player")
			if position then
				local x, y = position:GetXY()
				if x and y then
					x = math.floor(100 * x)
					y = math.floor(100 * y)
					m_coord_text:SetFormattedText("%.2d, %.2d", x, y)
					--LUI:Print("valid Coords:", m_coord_text:GetText())
					return
				end
			end
		end
		m_coord_text:SetText("")
	end)

	m_zone:SetScript("OnUpdate", function()
		local pvp = GetZonePVPInfo()
		m_zone_text:SetText(GetMinimapZoneText())
		if pvp == "friendly" then
			m_zone_text:SetTextColor(0.1, 1.0, 0.1)
		elseif pvp == "sanctuary" then
			m_zone_text:SetTextColor(0.41, 0.8, 0.94)
		elseif pvp == "arena" or pvp == "hostile" then
			m_zone_text:SetTextColor(1.0, 0.1, 0.1)
		elseif pvp == "contested" then
			m_zone_text:SetTextColor(1.0, 0.7, 0.0)
		else
			m_zone_text:SetTextColor(1.0, 1.0, 1.0)
		end
	end)

	-- Set Scripts and etc.
	Minimap:SetScript("OnEnter",function()
		m_zone:Show()
		if db.Minimap.General.ShowCoord then
			m_coord:Show()
		end
	end)

	Minimap:SetScript("OnLeave",function()
		if not db.Minimap.General.AlwaysShowText then
			m_zone:Hide()
			m_coord:Hide()
		end
	end)

	Minimap:RegisterForDrag('LeftButton')
	Minimap:SetMovable(true)
	Minimap:SetScript('OnDragStop', function() if(db.Minimap.General.Position.UnLocked) then
			Minimap:StopMovingOrSizing()
			self:GetMinimapPosition()
		end
	end)
	Minimap:SetScript('OnDragStart', function() if(db.Minimap.General.Position.UnLocked) then Minimap:StartMoving() end end)
	MinimapCluster:EnableMouse(false)
end

function module:GetMinimapPosition()

	local point, _, relativePoint, xOfs, yOfs = Minimap:GetPoint()
	db.Minimap.General.Position.RelativePoint = relativePoint
	db.Minimap.General.Position.Point = point
	db.Minimap.General.Position.X = xOfs
	db.Minimap.General.Position.Y = yOfs
end

function module:ToggleMissionReport()
	local button = GarrisonLandingPageMinimapButton
	if button:IsShown() and not defaultGarrisonState then
		button:Hide()
		return
	elseif not defaultGarrisonState then
		return
	end
	if db.Minimap.General.MissionReport then
		button.Show = nil
		button:Show()
	else
		button.Show = button.Hide
		button:Hide()
	end
end

local defaults = {
	Minimap = {
		Enable = true,
		General = {
			AlwaysShowText = false,
			Position = {
				X = "-24",
				Y = "-80",
				RelativePoint = "TOPRIGHT",
				Point = "TOPRIGHT",
				UnLocked = false,
			},
			Size = 1,
			ShowTextures = true,
			ShowBorder = true,
			ShowCoord = true,
			MissionReport = true,
		},
		Font = {
			Font = "vibroceb",
			FontSize = 12,
			FontFlag = "NONE",
		},
		Icon = {
			Mail = "BOTTOMLEFT", -- LFG and MAIL icon positions changed for better visibilty of the Tooltip
			BG = "BOTTOMRIGHT",
			LFG = "TOPRIGHT", -- LFG and MAIL icon positions changed for better visibilty of the Tooltip
			GMTicket = "TOPLEFT",
		},
		Frames = {
			AlwaysUpFrameX = "300",
			AlwaysUpFrameY = "-35",
			VehicleSeatIndicatorX = "-10",
			VehicleSeatIndicatorY = "-260",
			DurabilityFrameX = "-20",
			DurabilityFrameY = "-260",
			ObjectiveTrackerFrameX = "-150",
			ObjectiveTrackerFrameY = "-300",
			CaptureBarX = "-5",
			CaptureBarY = "-235",
			TicketStatusX = "-175",
			TicketStatusY = "-70",
			PlayerPowerBarAltX = "0",
			PlayerPowerBarAltY = "160",
			GroupLootContainerX = "0",
			GroupLootContainerY = "120",
			MawBuffsX = "-180",
			MawBuffsY = "-70",
			SetAlwaysUpFrame = true,
			SetVehicleSeatIndicator = true,
			SetDurabilityFrame = true,
			SetObjectiveTrackerFrame = true,
			SetCaptureBar = true,
			SetTicketStatus = true,
			SetPlayerPowerBarAlt = false,
			SetGroupLootContainer = false,
			SetMawBuffs = true,
		},
	},
}

module.conflicts = "SexyMap"

function module:LoadOptions()

	-- Template Function to ease up maintenance
	local function createTemplate(frameName, orderNum, friendlyName, frameDesc, extraTables)
		local frameSet = "Set"..frameName
		local frameX = frameName.."X"
		local frameY = frameName.."Y"
		local frameDB = db.Minimap.Frames
		local optionTemplate = {
			name = friendlyName, type = "group", order = orderNum,
			disabled = function() return not db.Minimap.Enable end,
			args = {
				header1             = { name = "Description", type = "header",      order = 1, },
				[frameName.."Text"] = { name = frameDesc,     type = "description", order = 2, width = "full", },
				spacer              = { name = "",            type = "description", order = 3, width = "full", },
				header2             = { name = "Position",    type = "header",      order = 4, },
				[frameSet] = {
					name = "Enabled", type = "toggle", order = 5, width = "full",
					desc = "Enable LUI to set the position of the "..frameName..". \n\nNote:\n If you are using another addon that you believe to be moving this frame, disabling this may solve a conflict.",
					get = function() return frameDB[frameSet] end,
					set = function(_)
						frameDB[frameSet] = not frameDB[frameSet]
						module:SetPosition(frameName)
					end,
				},
				[frameName.."X"] = {
					name = "X Value", type = "input", order = 6,
					desc = "X Value for your "..frameName..".\n\nNote:\nPositive values = right\nNegative values = left\nDefault: "..LUI.defaults.profile.Minimap.Frames[frameX],
					disabled = function() return not frameDB[frameSet] end,
					get = function() return frameDB[frameX] end,
					set = function(_,value)
						if value == nil or value == "" then
							value = "0"
						end
						frameDB[frameX] = value
						module:SetPosition(frameName)
					end,
				},
				[frameName.."Y"] = {
					name = "Y Value", type = "input", order = 7,
					desc = "Y Value for your "..frameName..".\n\nNote:\nPositive values = up\nNegative values = down\nDefault: "..LUI.defaults.profile.Minimap.Frames[frameY],
					disabled = function() return not frameDB[frameSet] end,
					get = function() return frameDB[frameY] end,
					set = function(_,value)
						if value == nil or value == "" then
							value = "0"
						end
						frameDB[frameY] = value
						module:SetPosition(frameName)
					end,
				},
			},
		}

		if extraTables then
			for k, v in pairs(extraTables) do
				optionTemplate.args[k] = v
			end
		end
		return optionTemplate
	end

	local options = {
		Minimap = {
			name = "Minimap",
			type = "group",
			disabled = function() return not db.Minimap.Enable end,
			childGroups = "tab",
			args = {
				GeneralSettings = {
					name = "General",
					order = 1,
					type = "group",
					args = {
						ShowTextures = {
							name = "Show Minimap Textures",
							desc = "Whether you want to show the Minimap Textures or not.\n",
							disabled = function() return not db.Minimap.Enable end,
							type = "toggle",
							width = "full",
							get = function() return db.Minimap.General.ShowTextures end,
							set = function(info, ShowTextures)
										db.Minimap.General.ShowTextures = not db.Minimap.General.ShowTextures
										for i=1, 8, 1 do
											if _G["fminimap_texture"..i] ~= nil then
												if db.Minimap.General.ShowTextures == true then
													_G["fminimap_texture"..i]:Show()
												else
													_G["fminimap_texture"..i]:Hide()
												end
											end
										end
									end,
							order = 1,
						},
						ShowBorder = {
							name = "Show Minimap Border",
							desc = "Whether you want to show the Minimap Border or not.\n",
							disabled = function() return not db.Minimap.Enable end,
							type = "toggle",
							width = "full",
							get = function() return db.Minimap.General.ShowBorder end,
							set = function(info, ShowBorder)
										db.Minimap.General.ShowBorder = not db.Minimap.General.ShowBorder
										if fminimap_border ~= nil then
											if db.Minimap.General.ShowBorder == true then
												fminimap_border:Show()
											else
												fminimap_border:Hide()
											end
										end
									end,
							order = 2,
						},
						AlwaysShow = {
							name = "Always show Minimap text",
							desc = "Whether or not the Minimap Location and Coords text to always be shown.\n",
							disabled = function() return not db.Minimap.Enable end,
							type = "toggle",
							width = "full",
							get = function() return db.Minimap.General.AlwaysShowText end,
							set = function(_)
								db.Minimap.General.AlwaysShowText = not db.Minimap.General.AlwaysShowText
								if db.Minimap.General.AlwaysShowText then
									m_zone:Show()
									if db.Minimap.General.ShowCoord then
										m_coord:Show()
									end
								else
									m_zone:Hide()
									m_coord:Hide()
								end
							end,
							order = 3,
						},
						ShowCoord = {
							name = "Show Coordinates",
							desc = "Whether or not the Minimap Coordinates.\n",
							disabled = function() return not db.Minimap.Enable end,
							type = "toggle",
							width = "full",
							get = function() return db.Minimap.General.ShowCoord end,
							set = function(_)
								db.Minimap.General.ShowCoord = not db.Minimap.General.ShowCoord
								m_coord:Hide()
								if db.Minimap.General.AlwaysShowText then
									if db.Minimap.General.ShowCoord then
										m_coord:Show()
									end
								end
							end,
							order = 4,
						},
						MissionReport = {
							name = "Show Mission Report Button",
							desc = "Whether or not the Mission Report in the corner of the minimap.\n\n The button will be in a 'dead' corner of the minimap in which Blizzard will never spawn icons or other information.",
							disabled = function() return not db.Minimap.Enable end,
							type = "toggle",
							width = "full",
							get = function() return db.Minimap.General.MissionReport end,
							set = function(_)
								db.Minimap.General.MissionReport = not db.Minimap.General.MissionReport
								module:ToggleMissionReport()
							end,
							order = 4.5,
						},
						header1 = {
							name = "Position",
							type = "header",
							order = 5,
						},
						PosX = {
							name = "X Value",
							desc = "X Value for your Minimap.\n\nNote:\nPositive values = right\nNegative values = left\nDefault: "..LUI.defaults.profile.Minimap.General.Position.X,
							type = "input",
							get = function() return tostring(db.Minimap.General.Position.X) end,
							set = function(_,PosX)
									if PosX == nil or PosX == "" then
										PosX = "-24"
									end
									db.Minimap.General.Position.X = tonumber(PosX)
									module:SetMinimapPosition()
								end,
							order = 6,
						},
						PosY = {
							name = "Y Value",
							desc = "Y Value for your Minimap.\n\nNote:\nPositive values = up\nNegative values = down\nDefault: "..LUI.defaults.profile.Minimap.General.Position.Y,
							type = "input",
							get = function() return tostring(db.Minimap.General.Position.Y) end,
							set = function(_,PosY)
									if PosY == nil or PosY == "" then
										PosY = "-80"
									end
									db.Minimap.General.Position.Y = tonumber(PosY)
									module:SetMinimapPosition()
								end,
							order = 7,
						},
						Restore = LUI:NewExecute("Restore Default Position", "Restores Default Minimap Position", 8, function()
							db.Minimap.General.Position.RelativePoint = LUI.defaults.profile.Minimap.General.Position.RelativePoint
							db.Minimap.General.Position.Point = LUI.defaults.profile.Minimap.General.Position.Point
							db.Minimap.General.Position.X = LUI.defaults.profile.Minimap.General.Position.X
							db.Minimap.General.Position.Y = LUI.defaults.profile.Minimap.General.Position.Y
							module:SetMinimapPosition()
						end),
						Unlocked = {
							name = "Locked",
							desc = "Weather or not the Minimap is locked or not.\n",
							disabled = function() return not db.Minimap.Enable end,
							type = "toggle",
							width = "full",
							get = function() return not db.Minimap.General.Position.UnLocked end,
							set = function(_)
								db.Minimap.General.Position.UnLocked = not db.Minimap.General.Position.UnLocked
							end,
							order = 9,
						},
						header2 = {
							name = "Size",
							type = "header",
							order = 10,
						},
						Size = {
							name = "Size",
							type = "range",
							min = 0.5,
							max = 2.5,
							step = 0.25,
							isPercent = true,
							width = "double",
							desc = "Size for your Minimap.",
							get = function() return db.Minimap.General.Size end,
							set = function(_,Size)
									if Size == nil or Size == "" then
										Size = LUI.defaults.profile.Minimap.General.Size
									end
									db.Minimap.General.Size = Size
									module:SetMinimapSize()
								end,
							order = 11,
						},
					},
				},
				FontSettings = {
					name = "Font",
					type = "group",
					order = 2,
					args = {
						Font = {
							name = "Font",
							desc = "Choose the Font for your Minimap Location and Coords!\n\nDefault: "..LUI.defaults.profile.Minimap.Font.Font,
							disabled = function() return not db.Minimap.Enable end,
							type = "select",
							dialogControl = "LSM30_Font",
							values = widgetLists.font,
							get = function() return db.Minimap.Font.Font end,
							set = function(info, Font)
								db.Minimap.Font.Font = Font
								m_zone_text:SetFont(Media:Fetch("font", db.Minimap.Font.Font), db.Minimap.Font.FontSize, db.Minimap.Font.FontFlag)
								m_coord_text:SetFont(Media:Fetch("font", db.Minimap.Font.Font), db.Minimap.Font.FontSize, db.Minimap.Font.FontFlag)
							end,
							order = 1,
						},
						FontFlag = {
							name = "Font Flag",
							desc = "Choose the Font Flag for your Minimap text.\nDefault: "..LUI.defaults.profile.Minimap.Font.FontFlag,
							disabled = function() return not db.Minimap.Enable end,
							type = "select",
							values = fontflags,
							get = function()
								for k, v in pairs(fontflags) do
									if db.Minimap.Font.FontFlag == v then
										return k
									end
								end
							end,
							set = function(info, FontFlag)
								db.Minimap.Font.FontFlag = fontflags[FontFlag]
								m_zone_text:SetFont(Media:Fetch("font", db.Minimap.Font.Font), db.Minimap.Font.FontSize, db.Minimap.Font.FontFlag)
								m_coord_text:SetFont(Media:Fetch("font", db.Minimap.Font.Font), db.Minimap.Font.FontSize, db.Minimap.Font.FontFlag)
							end,
							order = 2,
						},
						FontSize = {
							name = "Font Size",
							desc = "Choose your Minimap Font Size!\n Default: "..LUI.defaults.profile.Minimap.Font.FontSize,
							disabled = function() return not db.Minimap.Enable end,
							type = "range",
							min = 1,
							max = 40,
							step = 1,
							width = "double",
							get = function() return db.Minimap.Font.FontSize end,
							set = function(info, FontSize)
								db.Minimap.Font.FontSize = FontSize
								m_zone_text:SetFont(Media:Fetch("font", db.Minimap.Font.Font), db.Minimap.Font.FontSize, db.Minimap.Font.FontFlag)
								m_coord_text:SetFont(Media:Fetch("font", db.Minimap.Font.Font), db.Minimap.Font.FontSize, db.Minimap.Font.FontFlag)
							end,
							order = 3,
						},
					},
				},
			},
		},
		MinimapFrames = {
			name = "UI Elements",
			type = "group",
			childGroups = "tab",
			disabled = function() return not db.Minimap.Enable end,
			args = {
				ObjectiveTrackerFrame = createTemplate("ObjectiveTrackerFrame", 1, "Objectives Tracker",
					"This Frame occurs when tracking Quests and Achievements."
				),
				PlayerPowerBarAlt = createTemplate("PlayerPowerBarAlt", 2, "Alternate Power Bar",
					"This Frame is the special bar that appears during certain fights or events. Example: Sanity bar during Visions."
				),
				GroupLootContainer = createTemplate("GroupLootContainer", 3, "Group Loot Container",
					"This Frame is the anchor point for many Loot-based frames such as the Need/Greed and Bonus Roll frames."
				),
				AlwaysUpFrame = createTemplate("AlwaysUpFrame", 4, "Zone Objectives Frame",
					"This Frame occurs in Battlegrounds, Instances and Zone Objectives. Example: Attempts left in Icecrown."
				),
				CaptureBar = createTemplate("CaptureBar", 5, "Capture Bar",
					"This Frame occurs when trying to capture a pvp objective."
				),
				VehicleSeatIndicator = createTemplate("VehicleSeatIndicator", 6, "Vehicle Seat Indicator",
					"This Frame occurs in some special Mounts and Vehicles. Example: Traveler's Tundra Mammoth."
				),
				DurabilityFrame = createTemplate("DurabilityFrame", 7, "Durability Frame",
					"This Frame occurs when your gear is damaged or broken."
				),
				MawBuffs = createTemplate("MawBuffs", 7, "Sanctum Anima Powers",
					"This Frame is shown in certain parts of the Sanctum of Domination."
				),
				TicketStatus = createTemplate("TicketStatus", 8, "GM Ticket Status",
					"This Frame occurs when waiting on a ticket response", {
					spacer2 = { name = "", type = "description", order = 8, width = "full", },
					ShowTicket = {
						name = "Show/Hide", type = "execute", order = 9,
						func = function()
							if TicketStatusFrame:IsShown() then
								TicketStatusFrame:Hide()
							else
								TicketStatusFrame:Show()
							end
						end,
					}
				}),
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

	LUI:RegisterModule(self)
end

function module:GARRISON_HIDE_LANDING_PAGE()
	defaultGarrisonState = false
end

function module:GARRISON_SHOW_LANDING_PAGE()
	defaultGarrisonState = true
end

function module:OnEnable()
	if IsAddOnLoaded("SexyMap") then
		LUI:Printf("|cffFF0000%s could not be enabled because of a conflicting addon: SexyMap.", self:GetName())
		return
	end
	self:SetMinimap()
	self:SetAdditionalFrames()
	if LUI.IsRetail then
		self:RegisterEvent("GARRISON_HIDE_LANDING_PAGE")
		self:RegisterEvent("GARRISON_SHOW_LANDING_PAGE")
		C_Timer.After(0.25, self.ToggleMissionReport)
		self:SecureHook(MawBuffsBelowMinimapFrameMixin, "OnShow", function() self:SetPosition('MawBuffs') end)
	end
end
