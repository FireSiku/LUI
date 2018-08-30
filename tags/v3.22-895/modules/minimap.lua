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
local module = LUI:Module("Minimap", "AceHook-3.0")
local Themes = LUI:Module("Themes")
local Media = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists

local db
local hooks_ = { }
local shouldntSetPoint = false
local numHookedCaptureFrames = 0
local fontflags = {'OUTLINE', 'THICKOUTLINE', 'MONOCHROME', 'NONE'}

function module:SetAdditionalFrames()
	if db.Minimap.Enable ~= true then return end
	self:SecureHook(DurabilityFrame, "SetPoint", "DurabilityFrame_SetPoint")
	self:SecureHook(VehicleSeatIndicator, "SetPoint", "VehicleSeatIndicator_SetPoint")
	self:SecureHook(ObjectiveTrackerFrame, "SetPoint", "ObjectiveTrackerFrame_SetPoint")
	self:SecureHook(UIWidgetTopCenterContainerFrame, "SetPoint", "WorldStateAlwaysUpFrame_SetPoint")
	self:SecureHook(TicketStatusFrame, "SetPoint", "TicketStatusFrame_SetPoint")
end

function module:SetPosition(frame)
	shouldntSetPoint = true
	if frame == "worldState" and db.Minimap.Frames.SetAlwaysUpFrame then
		UIWidgetTopCenterContainerFrame:ClearAllPoints()
		UIWidgetTopCenterContainerFrame:SetPoint("TOP", UIParent, "TOP", db.Minimap.Frames.AlwaysUpFrameX, db.Minimap.Frames.AlwaysUpFrameY)
	elseif frame == "vehicleSeats" and db.Minimap.Frames.SetVehicleSeatIndicator then
		VehicleSeatIndicator:ClearAllPoints()
		VehicleSeatIndicator:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", db.Minimap.Frames.VehicleSeatIndicatorX, db.Minimap.Frames.VehicleSeatIndicatorY)
	elseif frame == "durability" and db.Minimap.Frames.SetDurabilityFrame then
		DurabilityFrame:ClearAllPoints()
		DurabilityFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", db.Minimap.Frames.DurabilityFrameX, db.Minimap.Frames.DurabilityFrameY)
	elseif frame == "questWatch" and db.Minimap.Frames.SetObjectiveTrackerFrame then
		ObjectiveTrackerFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", db.Minimap.Frames.ObjectiveTrackerFrameX, db.Minimap.Frames.ObjectiveTrackerFrameY)
	elseif frame == "ticketStatus" and db.Minimap.Frames.SetTicket then
		TicketStatusFrame:ClearAllPoints()
		TicketStatusFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", db.Minimap.Frames.TicketX, db.Minimap.Frames.TicketY)
	--[[elseif frame == "capture" and db.Minimap.Frames.SetCapture then
		for i = 1, NUM_EXTENDED_UI_FRAMES do
			_G["WorldStateCaptureBar" .. i]:ClearAllPoints()
			_G["WorldStateCaptureBar" .. i]:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", db.Minimap.Frames.CaptureX, db.Minimap.Frames.CaptureY)
		end]]
	end

	shouldntSetPoint = false
end

function module:DurabilityFrame_SetPoint()
	if shouldntSetPoint then return end
	self:SetPosition('durability')
end

function module:ObjectiveTrackerFrame_SetPoint()
	if shouldntSetPoint then return end
	self:SetPosition('questWatch')
end

function module:VehicleSeatIndicator_SetPoint()
	if shouldntSetPoint then return end
	self:SetPosition('vehicleSeats')
end

function module:WorldStateAlwaysUpFrame_SetPoint()
	if shouldntSetPoint then return end
	self:SetPosition('worldState')
end

function module:WorldStateCaptureBar_SetPoint()
	if shouldntSetPoint then return end
	self:SetPosition('capture')
end

function module:TicketStatusFrame_SetPoint()
	if shouldntSetPoint then return end
	self:SetPosition('ticketStatus')
end

function module:WorldStateAlwaysUpFrame_Update()
	while numHookedCaptureFrames < NUM_EXTENDED_UI_FRAMES do
		numHookedCaptureFrames = numHookedCaptureFrames + 1

		self:SecureHook(_G["WorldStateCaptureBar" .. numHookedCaptureFrames], "SetPoint", "WorldStateCaptureBar_SetPoint")
		self:WorldStateCaptureBar_SetPoint()
	end
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
	self:SetPosition('durability')
	self:SetPosition('questWatch')
	self:SetPosition('vehicleSeats')
	self:SetPosition('worldState')
	self:SetPosition('capture')
	self:SetPosition('ticketStatus')

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
	GuildInstanceDifficulty:UnregisterAllEvents()
	GuildInstanceDifficulty.NewShow = MiniMapInstanceDifficulty.Show
	GuildInstanceDifficulty.Show = GuildInstanceDifficulty.Hide
	GuildInstanceDifficulty:Hide()

	MiniMapInstanceDifficulty.NewShow = MiniMapInstanceDifficulty.Show
	MiniMapInstanceDifficulty.Show = MiniMapInstanceDifficulty.Hide
	MiniMapInstanceDifficulty:Hide()

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
	QueueStatusMinimapButton:ClearAllPoints()
	QueueStatusMinimapButton:SetPoint(db.Minimap.Icon.BG, Minimap, LUI:Scale(3), 0)
	QueueStatusMinimapButtonBorder:Hide()

	-- Move Garrison icon
	GarrisonLandingPageMinimapButton:ClearAllPoints()
	GarrisonLandingPageMinimapButton:SetPoint(db.Minimap.Icon.Mail, Minimap, LUI:Scale(3), LUI:Scale(15))
	module:SecureHook("GarrisonLandingPageMinimapButton_UpdateIcon", function()
		GarrisonLandingPageMinimapButton:SetSize(32,32)
	end)

	MiniMapMailFrame:HookScript("OnShow", function()
		GarrisonLandingPageMinimapButton:SetPoint("BOTTOMLEFT", MiniMapMailFrame, "TOPLEFT", 0, LUI:Scale(-5))
	end)
	MiniMapMailFrame:HookScript("OnHide", function()
		GarrisonLandingPageMinimapButton:SetPoint(db.Minimap.Icon.Mail, Minimap, LUI:Scale(3), LUI:Scale(15))
	end)

	-- Move GM Ticket Status icon
	HelpOpenTicketButton:SetParent(Minimap)
	HelpOpenTicketButton:ClearAllPoints()
	HelpOpenTicketButton:SetPoint(db.Minimap.Icon.GMTicket, Minimap, LUI:Scale(3), LUI:Scale(3))

	local micro_r, micro_g, micro_b = unpack(Themes.db.profile.micromenu)
	HelpOpenTicketButtonTutorial:ClearAllPoints()
	HelpOpenTicketButtonTutorial:SetPoint("TOP", HelpOpenTicketButton, "BOTTOM", 0, -HelpOpenTicketButtonTutorialArrow:GetHeight())

	HelpOpenTicketButtonTutorialBg:SetGradientAlpha("VERTICAL", micro_r/4, micro_g/4, micro_b/4, 1, 0, 0, 0, 1)

	HelpOpenTicketButtonTutorialText:SetFont(Media:Fetch("font", "vibrocen"), 14, "NONE")

	HelpOpenTicketButtonTutorialArrow:ClearAllPoints()
	HelpOpenTicketButtonTutorialArrow:SetPoint("BOTTOM", HelpOpenTicketButtonTutorial, "TOP", 0, -6)

	HelpOpenTicketButtonTutorialGlow:SetTexCoord(0.40625000, 0.66015625, 0.82812500, 0.77343750)
	HelpOpenTicketButtonTutorialGlow:SetVertexColor(r, g, b, 0.5)
	HelpOpenTicketButtonTutorialGlow:ClearAllPoints()
	HelpOpenTicketButtonTutorialGlow:SetPoint("BOTTOM", HelpOpenTicketButtonTutorialArrow, "BOTTOM", 0, 0)

	HelpOpenTicketButtonTutorialArrow:SetTexCoord(0.78515625, 0.99218750, 0.58789063, 0.54687500)
	HelpOpenTicketButtonTutorialArrow:SetVertexColor(micro_r, micro_g, micro_b)

	HelpOpenTicketButtonTutorialGlowTopLeft:SetVertexColor(micro_r, micro_g, micro_b)
	HelpOpenTicketButtonTutorialGlowTopRight:SetVertexColor(micro_r, micro_g, micro_b)
	HelpOpenTicketButtonTutorialGlowBottomLeft:SetVertexColor(micro_r, micro_g, micro_b)
	HelpOpenTicketButtonTutorialGlowBottomRight:SetVertexColor(micro_r, micro_g, micro_b)

	HelpOpenTicketButtonTutorialGlowTop:SetVertexColor(micro_r, micro_g, micro_b)
	HelpOpenTicketButtonTutorialGlowBottom:SetVertexColor(micro_r, micro_g, micro_b)
	HelpOpenTicketButtonTutorialGlowLeft:SetVertexColor(micro_r, micro_g, micro_b)
	HelpOpenTicketButtonTutorialGlowRight:SetVertexColor(micro_r, micro_g, micro_b)

	-- greyscaled textures
	HelpOpenTicketButtonTutorialGlow:SetTexture("Interface\\AddOns\\LUI\\media\\TalentFrame-Parts")
	HelpOpenTicketButtonTutorialArrow:SetTexture("Interface\\AddOns\\LUI\\media\\TalentFrame-Parts")

	HelpOpenTicketButtonTutorialGlowTopLeft:SetTexture("Interface\\AddOns\\LUI\\media\\TalentFrame-Parts")
	HelpOpenTicketButtonTutorialGlowTopRight:SetTexture("Interface\\AddOns\\LUI\\media\\TalentFrame-Parts")
	HelpOpenTicketButtonTutorialGlowBottomLeft:SetTexture("Interface\\AddOns\\LUI\\media\\TalentFrame-Parts")
	HelpOpenTicketButtonTutorialGlowBottomRight:SetTexture("Interface\\AddOns\\LUI\\media\\TalentFrame-Parts")

	HelpOpenTicketButtonTutorialGlowTop:SetTexture("Interface\\AddOns\\LUI\\media\\TALENTFRAME-HORIZONTAL2")
	HelpOpenTicketButtonTutorialGlowBottom:SetTexture("Interface\\AddOns\\LUI\\media\\TALENTFRAME-HORIZONTAL2")
	HelpOpenTicketButtonTutorialGlowLeft:SetTexture("Interface\\AddOns\\LUI\\media\\TALENTFRAME-VERTICAL2")
	HelpOpenTicketButtonTutorialGlowRight:SetTexture("Interface\\AddOns\\LUI\\media\\TALENTFRAME-VERTICAL2")

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
		{text = CHARACTER_BUTTON,
		func = function() ToggleCharacter("PaperDollFrame") end},
		{text = SPELLBOOK_ABILITIES_BUTTON,
		func = function() ToggleFrame(SpellBookFrame) end},
		{text = TALENTS_BUTTON,
		func = function() ToggleTalentFrame() end},
		{text = ACHIEVEMENT_BUTTON,
		func = function() ToggleAchievementFrame() end},
		{text = QUESTLOG_BUTTON,
		func = function() ToggleFrame(QuestLogFrame) end},
		{text = SOCIAL_BUTTON,
		func = function() ToggleFriendsFrame(1) end},
		{text = PLAYER_V_PLAYER,
		func = function() ToggleFrame(PVPFrame) end},
		{text = ACHIEVEMENTS_GUILD_TAB,
		func = function() if IsInGuild() then if not GuildFrame then LoadAddOn("Blizzard_GuildUI") end GuildFrame_Toggle() end end},
		{text = LFG_TITLE,
		func = function() ToggleFrame(LFDParentFrame) end},
		{text = L_LFRAID,
		func = function() ToggleFrame(LFRParentFrame) end},
		{text = HELP_BUTTON,
		func = function() ToggleHelpFrame() end},
		{text = L_CALENDAR,
		func = function()
		if(not CalendarFrame) then LoadAddOn("Blizzard_Calendar") end
			Calendar_Toggle()
		end},
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

	-- reskin LFG dropdown
	--[[LFDSearchStatus:SetBackdrop({
	  bgFile = LUI.Media.blank,
	  edgeFile = LUI.Media.blank,
	  tile = false, tileSize = 0, edgeSize = mult,
	  insets = { left = 0, right = 0, top = 0, bottom = 0}
	})]]
	QueueStatusFrame:SetBackdropColor(.1,.1,.1,1)
	QueueStatusFrame:SetBackdropBorderColor(.6,.6,.6,1)

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

local emptyFunc = function() return end
function module:ToggleMissionReport()
	if C_Garrison.GetLandingPageGarrisonType() == 0 then return end
	if db.Minimap.General.MissionReport then
		GarrisonLandingPageMinimapButton.Show = nil
		GarrisonLandingPageMinimapButton:Show()
	else
		GarrisonLandingPageMinimapButton.Show = emptyFunc
		GarrisonLandingPageMinimapButton:Hide()
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
			VehicleSeatIndicatorY = "-225",
			DurabilityFrameX = "-20",
			DurabilityFrameY = "-220",
			ObjectiveTrackerFrameX = "-150",
			ObjectiveTrackerFrameY = "-300",
			CaptureX = "-5",
			CaptureY = "-205",
			TicketX = "-175",
			TicketY = "-70",
			SetAlwaysUpFrame = true,
			SetVehicleSeatIndicator = true,
			SetDurabilityFrame = true,
			SetObjectiveTrackerFrame = true,
			SetCapture = true,
			SetTicket = true,
		},
	},
}

module.conflicts = "SexyMap"

function module:LoadOptions()
	local options = {
		Minimap = {
			name = "Minimap",
			type = "group",
			disabled = function() return not db.Minimap.Enable end,
			childGroups = "tab",
			args = {
				MinimapSettings = {
					name = "Minimap",
					type = "group",
					order = 1,
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
					name = "Minimap Frames",
					type = "group",
					order = 3,
					disabled = function() return not db.Minimap.Enable end,
					args = {
						AlwaysUpFrame = {
							name = "AlwaysUpFrame",
							type = "group",
							disabled = function() return not db.Minimap.Enable end,
							order = 1,
							args = {
								header1 = {
									name = "Description",
									type = "header",
									order = 1,
								},
								AlwaysUpFrameText = {
									order = 2,
									width = "full",
									type = "description",
									name = "This Frame occurs in Battlegrounds, Thousendwinter and Instances. Example: Attempts left in Icecrown.",
								},
								spacer = {
									name = "",
									type = "description",
									width = "full",
									order = 3,
								},
								header2 = {
									name = "Position",
									type = "header",
									order = 4,
								},
								SetAlwaysUpFrame = {
									name = "Enabled",
									desc = "Enable LUI to set the position of the AlwaysUpFrame. \n\nNote:\n If you are using another addon that you believe to be moving this frame, disabling this may solve a conflict.",
									type = "toggle",
									width = "full",

									get = function() return db.Minimap.Frames.SetAlwaysUpFrame end,
									set = function()
										db.Minimap.Frames.SetAlwaysUpFrame = not db.Minimap.Frames.SetAlwaysUpFrame
										module:SetPosition("worldState")
									end,
									order = 5,
								},
								AlwaysUpFrameX = {
									name = "X Value",
									desc = "X Value for your AlwaysUpFrame.\n\nNote:\nPositive values = right\nNegative values = left\nDefault: "..LUI.defaults.profile.Minimap.Frames.AlwaysUpFrameX,
									type = "input",
									disabled = function() return not db.Minimap.Frames.SetAlwaysUpFrame end,
									get = function() return db.Minimap.Frames.AlwaysUpFrameX end,
									set = function(info, AlwaysUpFrameX)
												if AlwaysUpFrameX == nil or AlwaysUpFrameX == "" then
													AlwaysUpFrameX = "0"
												end
												db.Minimap.Frames.AlwaysUpFrameX = AlwaysUpFrameX
												module:SetPosition("worldState")
											end,
									order = 6,
								},
								AlwaysUpFrameY = {
									name = "Y Value",
									desc = "Y Value for your AlwaysUpFrame.\n\nNote:\nPositive values = up\nNegative values = down\nDefault: "..LUI.defaults.profile.Minimap.Frames.AlwaysUpFrameY,
									type = "input",
									disabled = function() return not db.Minimap.Frames.SetAlwaysUpFrame end,
									get = function() return db.Minimap.Frames.AlwaysUpFrameY end,
									set = function(info, AlwaysUpFrameY)
												if AlwaysUpFrameY == nil or AlwaysUpFrameY == "" then
													AlwaysUpFrameY = "0"
												end
												db.Minimap.Frames.AlwaysUpFrameY = AlwaysUpFrameY
												module:SetPosition("worldState")
											end,
									order = 7,
								},
							},
						},
						VehicleSeatIndicator = {
							name = "VehicleSeatIndicator",
							type = "group",
							disabled = function() return not db.Minimap.Enable end,
							order = 2,
							args = {
								header1 = {
									name = "Description",
									type = "header",
									order = 1,
								},
								VehicleSeatIndicatorText = {
									order = 2,
									width = "full",
									type = "description",
									name = "This Frame occurs in some special Mounts and Vehicles. Example: Traveler's Tundra Mammoth.",
								},
								spacer = {
									name = "",
									type = "description",
									width = "full",
									order = 3,
								},
								header2 = {
									name = "Position",
									type = "header",
									order = 4,
								},
								SetVehicleSeatIndicator = {
									name = "Enabled",
									desc = "Enable LUI to set the position of the VehicleSeatIndicator. \n\nNote:\n If you are using another addon that you believe to be moving this frame, disabling this may solve a conflict.",
									type = "toggle",
									width = "full",
									get = function() return db.Minimap.Frames.SetVehicleSeatIndicator end,
									set = function(_)
										db.Minimap.Frames.SetVehicleSeatIndicator = not db.Minimap.Frames.SetVehicleSeatIndicator
										module:SetPosition("vehicleSeats")
									end,
									order = 5,
								},
								VehicleSeatIndicatorX = {
									name = "X Value",
									desc = "X Value for your VehicleSeatIndicator.\n\nNote:\nPositive values = right\nNegative values = left\nDefault: "..LUI.defaults.profile.Minimap.Frames.VehicleSeatIndicatorX,
									type = "input",
									disabled = function() return not db.Minimap.Frames.SetVehicleSeatIndicator end,
									get = function() return db.Minimap.Frames.VehicleSeatIndicatorX end,
									set = function(_,VehicleSeatIndicatorX)
												if VehicleSeatIndicatorX == nil or VehicleSeatIndicatorX == "" then
													VehicleSeatIndicatorX = "0"
												end
												db.Minimap.Frames.VehicleSeatIndicatorX = VehicleSeatIndicatorX
												module:SetPosition("vehicleSeats")
											end,
									order = 6,
								},
								VehicleSeatIndicatorY = {
									name = "Y Value",
									desc = "Y Value for your VehicleSeatIndicator.\n\nNote:\nPositive values = up\nNegative values = down\nDefault: "..LUI.defaults.profile.Minimap.Frames.VehicleSeatIndicatorY,
									type = "input",
									disabled = function() return not db.Minimap.Frames.SetVehicleSeatIndicator end,
									get = function() return db.Minimap.Frames.VehicleSeatIndicatorY end,
									set = function(_,VehicleSeatIndicatorY)
												if VehicleSeatIndicatorY == nil or VehicleSeatIndicatorY == "" then
													VehicleSeatIndicatorY = "0"
												end
												db.Minimap.Frames.VehicleSeatIndicatorY = VehicleSeatIndicatorY
												module:SetPosition("vehicleSeats")
											end,
									order = 7,
								},
							},
						},
						DurabilityFrame = {
							name = "DurabilityFrame",
							type = "group",
							disabled = function() return not db.Minimap.Enable end,
							order = 3,
							args = {
								header1 = {
									name = "Description",
									type = "header",
									order = 1,
								},
								DurabilityFrameText = {
									order = 2,
									width = "full",
									type = "description",
									name = "This Frame occurs when your gear is broken. It shows the damaged equip.",
								},
								spacer = {
									name = "",
									type = "description",
									width = "full",
									order = 3,
								},
								header2 = {
									name = "Position",
									type = "header",
									order = 4,
								},
								SetDurabilityFrame = {
									name = "Enabled",
									desc = "Enable LUI to set the position of the DurabilityFrame. \n\nNote:\n If you are using another addon that you believe to be moving this frame, disabling this may solve a conflict.",
									type = "toggle",
									width = "full",
									get = function() return db.Minimap.Frames.SetDurabilityFrame end,
									set = function(_)
										db.Minimap.Frames.SetDurabilityFrame = not db.Minimap.Frames.SetDurabilityFrame
										module:SetPosition("durability")
									end,
									order = 5,
								},
								DurabilityFrameX = {
									name = "X Value",
									desc = "X Value for your DurabilityFrame.\n\nNote:\nPositive values = right\nNegative values = left\nDefault: "..LUI.defaults.profile.Minimap.Frames.DurabilityFrameX,
									type = "input",
									disabled = function() return not db.Minimap.Frames.SetDurabilityFrame end,
									get = function() return db.Minimap.Frames.DurabilityFrameX end,
									set = function(_,DurabilityFrameX)
												if DurabilityFrameX == nil or DurabilityFrameX == "" then
													DurabilityFrameX = "0"
												end
												db.Minimap.Frames.DurabilityFrameX = DurabilityFrameX
												module:SetPosition("durability")
											end,
									order = 6,
								},
								DurabilityFrameY = {
									name = "Y Value",
									desc = "Y Value for your DurabilityFrame.\n\nNote:\nPositive values = up\nNegative values = down\nDefault: "..LUI.defaults.profile.Minimap.Frames.DurabilityFrameY,
									type = "input",
									disabled = function() return not db.Minimap.Frames.SetDurabilityFrame end,
									get = function() return db.Minimap.Frames.DurabilityFrameY end,
									set = function(_,DurabilityFrameY)
												if DurabilityFrameY == nil or DurabilityFrameY == "" then
													DurabilityFrameY = "0"
												end
												db.Minimap.Frames.DurabilityFrameY = DurabilityFrameY
												module:SetPosition("durability")
											end,
									order = 7,
								},
							},
						},
						ObjectiveTrackerFrame = {
							name = "ObjectiveTrackerFrame",
							type = "group",
							disabled = function() return not db.Minimap.Enable end,
							order = 4,
							args = {
								header1 = {
									name = "Description",
									type = "header",
									order = 1,
								},
								ObjectiveTrackerFrameText = {
									order = 2,
									width = "full",
									type = "description",
									name = "This Frame occurs when tracking Quests and Achievements.",
								},
								spacer = {
									name = "",
									type = "description",
									width = "full",
									order = 3,
								},
								header2 = {
									name = "Position",
									type = "header",
									order = 4,
								},
								SetObjectiveTrackerFrame = {
									name = "Enabled",
									desc = "Enable LUI to set the position of the ObjectiveTrackerFrame. \n\nNote:\n If you are using another addon that you believe to be moving this frame, disabling this may solve a conflict.",
									type = "toggle",
									width = "full",
									get = function() return db.Minimap.Frames.SetObjectiveTrackerFrame end,
									set = function(_)
										db.Minimap.Frames.SetObjectiveTrackerFrame = not db.Minimap.Frames.SetObjectiveTrackerFrame
										module:SetPosition("questWatch")
									end,
									order = 5,
								},
								ObjectiveTrackerFrameX = {
									name = "X Value",
									desc = "X Value for your ObjectiveTrackerFrame.\n\nNote:\nPositive values = right\nNegative values = left\nDefault: "..LUI.defaults.profile.Minimap.Frames.ObjectiveTrackerFrameX,
									type = "input",
									disabled = function() return not db.Minimap.Frames.SetObjectiveTrackerFrame end,
									get = function() return db.Minimap.Frames.ObjectiveTrackerFrameX end,
									set = function(_,ObjectiveTrackerFrameX)
												if ObjectiveTrackerFrameX == nil or ObjectiveTrackerFrameX == "" then
													ObjectiveTrackerFrameX = "0"
												end
												db.Minimap.Frames.ObjectiveTrackerFrameX = ObjectiveTrackerFrameX
												module:SetPosition("questWatch")
											end,
									order = 6,
								},
								ObjectiveTrackerFrameY = {
									name = "Y Value",
									desc = "Y Value for your ObjectiveTrackerFrame.\n\nNote:\nPositive values = up\nNegative values = down\nDefault: "..LUI.defaults.profile.Minimap.Frames.ObjectiveTrackerFrameY,
									type = "input",
									disabled = function() return not db.Minimap.Frames.SetObjectiveTrackerFrame end,
									get = function() return db.Minimap.Frames.ObjectiveTrackerFrameY end,
									set = function(_,ObjectiveTrackerFrameY)
												if ObjectiveTrackerFrameY == nil or ObjectiveTrackerFrameY == "" then
													ObjectiveTrackerFrameY = "0"
												end
												db.Minimap.Frames.ObjectiveTrackerFrameY = ObjectiveTrackerFrameY
												module:SetPosition("questWatch")
											end,
									order = 7,
								},
							},
						},
						TicketStatus = {
							name = "Ticket Status",
							type = "group",
							disabled = function() return not db.Minimap.Enable end,
							order = 5,
							args = {
								header1 = {
									name = "Description",
									type = "header",
									order = 1,
								},
								ObjectiveTrackerFrameText = {
									order = 2,
									width = "full",
									type = "description",
									name = "This Frame occurs when waiting on a ticket response",
								},
								spacer1 = {
									name = "",
									type = "description",
									width = "full",
									order = 3,
								},
								header2 = {
									name = "Position",
									type = "header",
									order = 4,
								},
								SetTicket = {
									name = "Enabled",
									desc = "Enable LUI to set the position of the Ticket. \n\nNote:\n If you are using another addon that you believe to be moving this frame, disabling this may solve a conflict.",
									type = "toggle",
									width = "full",

									get = function() return db.Minimap.Frames.SetTicket end,
									set = function(_)
										db.Minimap.Frames.SetTicket = not db.Minimap.Frames.SetTicket
										module:SetPosition("ticketStatus")
									end,
									order = 5,
								},
								TicketX = {
									name = "X Value",
									desc = "X Value for your Ticket Status.\n\nNote:\nPositive values = right\nNegative values = left\nDefault: "..LUI.defaults.profile.Minimap.Frames.TicketX,
									type = "input",
									disabled = function() return not db.Minimap.Frames.SetTicket end,
									get = function() return db.Minimap.Frames.TicketX end,
									set = function(_,TicketX)
												if TicketX == nil or TicketX == "" then
													TicketX = "0"
												end
												db.Minimap.Frames.TicketX = TicketX
												module:SetPosition("ticketStatus")
											end,
									order = 6,
								},
								TicketY = {
									name = "Y Value",
									desc = "Y Value for your Ticket Status.\n\nNote:\nPositive values = up\nNegative values = down\nDefault: "..LUI.defaults.profile.Minimap.Frames.TicketY,
									type = "input",
									disabled = function() return not db.Minimap.Frames.SetTicket end,
									get = function() return db.Minimap.Frames.TicketY end,
									set = function(_,TicketY)
												if TicketY == nil or TicketY == "" then
													TicketY = "0"
												end
												db.Minimap.Frames.TicketY = TicketY
												module:SetPosition("ticketStatus")
											end,
									order = 7,
								},
								spacer2 = {
									order = 7,
									width = "full",
									type = "description",
									name = " "
								},
								ShowTicket = {
									order = 8,
									type = "execute",
									name = "Show/Hide",
									func = function()
										if TicketStatusFrame:IsShown() then
											TicketStatusFrame:Hide()
										else
											TicketStatusFrame:Show()
										end
									end,
								},
							},
						},
						CaptureBar = {
							name = "Capture Bar",
							type = "group",
							disabled = function() return not db.Minimap.Enable end,
							order = 6,
							args = {
								header1 = {
									name = "Description",
									type = "header",
									order = 1,
								},
								ObjectiveTrackerFrameText = {
									order = 2,
									width = "full",
									type = "description",
									name = "This Frame occurs when ... ??",
								},
								spacer = {
									name = "",
									type = "description",
									width = "full",
									order = 3,
								},
								header2 = {
									name = "Position",
									type = "header",
									order = 4,
								},
								SetCapture = {
									name = "Enabled",
									desc = "Enable LUI to set the position of the Capture. \n\nNote:\n If you are using another addon that you believe to be moving this frame, disabling this may solve a conflict.",
									type = "toggle",
									width = "full",

									get = function() return db.Minimap.Frames.SetCapture end,
									set = function(_)
										db.Minimap.Frames.SetCapture = not db.Minimap.Frames.SetCapture
										module:SetPosition("capture")
									end,
									order = 5,
								},
								CaptureX = {
									name = "X Value",
									desc = "X Value for your Capture Bar.\n\nNote:\nPositive values = right\nNegative values = left\nDefault: "..LUI.defaults.profile.Minimap.Frames.CaptureX,
									type = "input",
									disabled = function() return not db.Minimap.Frames.SetCapture end,
									get = function() return db.Minimap.Frames.CaptureX end,
									set = function(_,CaptureX)
												if CaptureX == nil or CaptureX == "" then
													CaptureX = "0"
												end
												db.Minimap.Frames.CaptureX = CaptureX
												module:SetPosition("capture")
											end,
									order = 6,
								},
								CaptureY = {
									name = "Y Value",
									desc = "Y Value for your Capture Bar.\n\nNote:\nPositive values = up\nNegative values = down\nDefault: "..LUI.defaults.profile.Minimap.Frames.CaptureY,
									type = "input",
									disabled = function() return not db.Minimap.Frames.SetCapture end,
									get = function() return db.Minimap.Frames.CaptureY end,
									set = function(_,CaptureY)
												if CaptureY == nil or CaptureY == "" then
													CaptureY = "0"
												end
												db.Minimap.Frames.CaptureY = CaptureY
												module:SetPosition("capture")
											end,
									order = 7,
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

	LUI:RegisterModule(self)
end

function module:OnEnable()
	if IsAddOnLoaded("SexyMap") then
		LUI:Printf("|cffFF0000%s could not be enabled because of a conflicting addon: SexyMap.", self:GetName())
		return
	end
	self:SetMinimap()
	self:SetAdditionalFrames()
	C_Timer.After(0.1, self.ToggleMissionReport)
end
