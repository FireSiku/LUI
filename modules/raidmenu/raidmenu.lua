-- This module creates a menu containing all the raid markers, world pillars and other raid/party commands

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.RaidMenu
local module = LUI:GetModule("RaidMenu")
local db

local Micromenu = LUI:GetModule("Micromenu", true) --[[@as LUI.Micromenu]]
local Media = LibStub("LibSharedMedia-3.0")

local InCombatLockdown = _G.InCombatLockdown
local InitiateRolePoll = _G.InitiateRolePoll
local IsInRaid = _G.IsInRaid
local IsInGroup = _G.IsInGroup
local HasLFGRestrictions = _G.HasLFGRestrictions
local UnitInBattleground = _G.UnitInBattleground
local UnitIsGroupAssistant = _G.UnitIsGroupAssistant
local UnitIsGroupLeader = _G.UnitIsGroupLeader
local issecretvalue = _G.issecretvalue or function() return false end
local C_PartyInfo = _G.C_PartyInfo
local SecureActionButton_ShouldUseOnKeyDown = _G.SecureActionButton_ShouldUseOnKeyDown

-- Frame placeholders
local RaidMenu_Header, RaidMenu_Parent, RaidMenu_Border, RaidMenu_BG, RaidMenu
local SkullRaidIcon, CrossRaidIcon, SquareRaidIcon, MoonRaidIcon, TriangleRaidIcon
local DiamondRaidIcon, CircleRaidIcon, StarRaidIcon, ClearRaidIcon
local BlueWorldMarker, GreenWorldMarker, PurpleWorldMarker, RedWorldMarker, YellowWorldMarker
local OrangeWorldMarker, SilverWorldMarker, WhiteWorldMarker, ClearWorldMarkers
local ConvertRaid, RoleChecker, ReadyChecker
local pendingAction
local menuShown = false
local fade, slide
local animationFrame

local combatQueue = CreateFrame("Frame")
combatQueue:Hide()
combatQueue:SetScript("OnEvent", function(self)
	if InCombatLockdown() then return end
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:Hide()

	local action = pendingAction
	pendingAction = nil
	if action == "hide" or not module:IsEnabled() or not db or not db.Enable then
		module:HideRaidMenu()
	elseif action == "setup" then
		module:SetRaidMenu()
	elseif action == "refresh" then
		module:Refresh()
	end
end)

local function QueueAfterCombat(action)
	-- A later enable/disable request supersedes a mere settings refresh.
	if action ~= "refresh" or not pendingAction then
		pendingAction = action
	end
	combatQueue:RegisterEvent("PLAYER_REGEN_ENABLED")
	combatQueue:Show()
end

local RAIDMENU_NORMAL_TEXTURE = "Interface\\AddOns\\LUI\\media\\templates\\v3\\RaidMenu"
local RAIDMENU_BG_TEXTURE = "Interface\\AddOns\\LUI\\media\\templates\\v3\\RaidMenu_BG"
local RAIDMENU_BORDER_TEXTURE = "Interface\\AddOns\\LUI\\media\\templates\\v3\\RaidMenu_Border"
local RAID_MARKER_ICON_TEXTURE = "Interface\\AddOns\\LUI\\media\\textures\\icons\\raidicons.blp"
local Y_normal, Y_compact = 107, 101
local X_normal, X_compact = 0, -50
local WorldMarkerTexCoords = {
	[1] = {0.25, 0.5, 0.25, 0.5}, -- Square
	[2] = {0.75, 1, 0, 0.25},     -- Triangle
	[3] = {0.5, 0.75, 0, 0.25},   -- Diamond
	[4] = {0.5, 0.75, 0.25, 0.5}, -- Cross
	[5] = {0, 0.25, 0, 0.25},     -- Star
	[6] = {0.25, 0.5, 0, 0.25},   -- Circle
	[7] = {0, 0.25, 0.25, 0.5},   -- Moon
	[8] = {0.75, 1, 0.25, 0.5},   -- Skull
}

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

local function AutoHideRaidMenu(self, button, down)
	if down == SecureActionButton_ShouldUseOnKeyDown(self) and db.AutoHide and not InCombatLockdown() then
		module:CloseRaidMenu()
	end
end

local function ConfigureRaidTargetButton(frame, marker)
	frame:SetMouseClickEnabled(true)
	frame:RegisterForClicks("AnyUp", "AnyDown")
	frame:SetAttribute("type1", "raidtarget")
	frame:SetAttribute("type2", "raidtarget")
	frame:SetAttribute("unit", "target")
	frame:SetAttribute("marker1", marker)
	frame:SetAttribute("marker2", marker)
	frame:SetAttribute("action1", marker == 0 and "clear" or "set")
	frame:SetAttribute("action2", "clear")
	frame:SetScript("PostClick", AutoHideRaidMenu)
end

local function ConfigureWorldMarkerButton(frame, marker)
	frame:SetMouseClickEnabled(true)
	frame:RegisterForClicks("AnyUp", "AnyDown")
	frame:SetAttribute("type1", "worldmarker")
	frame:SetAttribute("type2", "worldmarker")
	frame:SetAttribute("marker1", marker)
	frame:SetAttribute("marker2", marker)
	if marker then
		frame:SetAttribute("action1", "set")
		frame:SetAttribute("action2", "clear")
	else
		frame:SetAttribute("action1", "clear")
		frame:SetAttribute("action2", "clear")
	end
	frame:SetScript("PostClick", AutoHideRaidMenu)
end

local function UpdateConvertButton()
	local convertToRaid = not IsInRaid()
	ConvertRaid:SetText(convertToRaid and "Convert to Raid" or "Convert to Party")
	local allowed = C_PartyInfo.AllowedToDoPartyConversion(convertToRaid)
	if issecretvalue(allowed) then allowed = false end
	ConvertRaid:SetEnabled(not InCombatLockdown() and allowed)
end

local function UpdateGroupButtons()
	UpdateConvertButton()

	local isLeader = UnitIsGroupLeader("player")
	local isAssistant = UnitIsGroupAssistant("player")
	local inBattleground = UnitInBattleground("player")
	if issecretvalue(isLeader) then isLeader = false end
	if issecretvalue(isAssistant) then isAssistant = false end
	if issecretvalue(inBattleground) then inBattleground = true end
	local canManageGroup = (isLeader or isAssistant) and IsInGroup()
	local outOfCombat = not InCombatLockdown()
	ReadyChecker:SetEnabled(outOfCombat and canManageGroup)
	RoleChecker:SetEnabled(outOfCombat and canManageGroup and not HasLFGRestrictions() and not inBattleground)
end

-- One worker owns each transition. Rapid clicks change the destination,
-- rather than starting competing fade/slide scripts on a protected parent.
local function StopAnimations()
	fade, slide = nil, nil
	if animationFrame then animationFrame:Hide() end
end

local function MenuPosition()
	local x, y = X_compact, Y_normal
	if db.Compact then
		x, y = X_compact + db.Spacing / 2, Y_compact + db.Spacing / 2
	end
	if db.OverlapPrevention == "Offset" and Micromenu.background:IsShown() then
		x, y = x + db.X_Offset, y + db.Offset
	end
	return x / db.Scale + 17, y / db.Scale + 17
end

local function PositionMenu()
	local x, y = MenuPosition()
	RaidMenu_Parent:ClearAllPoints()
	RaidMenu_Parent:SetPoint("TOPRIGHT", Micromenu.buttonLeft, "BOTTOMRIGHT", x, y)
end

local function FadeMenu(shown)
	menuShown = shown
	local from = RaidMenu_Parent:IsShown() and RaidMenu_Parent:GetAlpha() or 0
	local target = shown and db.Opacity / 100 or 0
	fade = {from = from, target = target, elapsed = 0}
	if shown then
		RaidMenu_Parent:SetAlpha(from)
		RaidMenu_Parent:Show()
	end
	animationFrame:Show()
end

function module:CloseRaidMenu()
	if not RaidMenu_Parent or InCombatLockdown() then return end
	FadeMenu(false)
end

local function SlideMenu()
	local _, _, _, x, y = RaidMenu_Parent:GetPoint(1)
	local targetX, targetY = MenuPosition()
	if not menuShown or not x or not y then
		slide = nil
		PositionMenu()
		return
	end
	slide = {x = x, y = y, targetX = targetX, targetY = targetY, elapsed = 0}
	animationFrame:Show()
end

function module:OverlapPrevention(frame, action)
	db = module.db.profile
	if not module:IsEnabled() or not db.Enable or not Micromenu
		or not Micromenu:IsEnabled() or not RaidMenu then return end
	if InCombatLockdown() then
		-- A native visibility update may arrive during combat. Reconcile its
		-- position later; a blocked user click does not change the open state.
		if frame == "MM" then QueueAfterCombat("refresh") end
		return
	end

	if frame == "RM" and action == "toggle" then
		if not menuShown then
			if db.OverlapPrevention == "AutoHide" and Micromenu.background:IsShown() then
				Micromenu.clickerMiddle:Click()
			end
			slide = nil
			PositionMenu()
		end
		FadeMenu(not menuShown)
	elseif frame == "MM" then
		if db.OverlapPrevention == "AutoHide" and Micromenu.background:IsShown() then
			if menuShown then FadeMenu(false) end
		else
			SlideMenu()
		end
	elseif action == "slide" then
		SlideMenu()
	elseif action == "position" then
		slide = nil
		PositionMenu()
	end
end

local function FormatMarker(frame, x, y, r, g, b, id, t1, t2, t3, t4)
	if not frame then return end
	local width, height
	if db.Compact then
		width, height = 24, 24
	else
		width, height = 32, 32
	end
	frame:SetSize(width, height)
	frame:SetScale(1)
	frame:SetFrameStrata("HIGH")
	frame:SetFrameLevel(4)
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", RaidMenu_Parent, "TOPLEFT", x, y)
	frame:SetAlpha(0.6)

	if string.find(frame:GetName(), "WorldMarker") then
		local texture = _G[frame:GetName().."MarkerTex"]
		if not texture then
			texture = frame:CreateTexture(frame:GetName().."MarkerTex", "BACKGROUND")
		end
		texture:SetPoint("TOPLEFT", frame,"TOPLEFT",0,0)
		texture:SetSize(width, height)
		texture:SetTexture("Interface\\Buttons\\UI-Quickslot")
		texture:SetTexCoord(0.15, 0.85, 0.15, 0.85)
		if frame:GetName() == "ClearWorldMarkers" then
			texture:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
			texture:SetTexCoord(0, 1, 0, 1)
		else
			local textureColor = _G[frame:GetName().."TextureColor"]
			if not textureColor then
				textureColor = frame:CreateTexture(frame:GetName().."TextureColor", "BORDER")
			end
			textureColor:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4)
			textureColor:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
			textureColor:SetColorTexture(r, g, b)

			local iconTexture = _G[frame:GetName().."IconTex"]
			if not iconTexture then
				iconTexture = frame:CreateTexture(frame:GetName().."IconTex", "ARTWORK")
			end
			local texCoords = WorldMarkerTexCoords[id]
			iconTexture:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4)
			iconTexture:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
			iconTexture:SetTexture(RAID_MARKER_ICON_TEXTURE)
			iconTexture:SetTexCoord(texCoords[1], texCoords[2], texCoords[3], texCoords[4])
		end

	elseif string.find(frame:GetName(), "RaidIcon") then
		frame:SetID(id)
		local texture = _G[frame:GetName().."MarkerTex"]
		if not texture then
			texture = frame:CreateTexture(frame:GetName().."MarkerTex")
		end
		texture:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
		texture:SetSize(width - 4, height - 4)
		if frame:GetName() == "ClearRaidIcon" then
			texture:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
		else
			texture:SetTexture(RAID_MARKER_ICON_TEXTURE)
		end
		texture:SetTexCoord(t1, t2, t3, t4)

	else
		frame:RegisterForClicks("AnyUp")
		if db.Compact then
			width = 100 + (db.Spacing * 3)
		else
			width = 120
		end
		frame:SetSize(width, LUI:Scale(20))
		frame:SetAlpha(1)
	end
end

local function SizeRaidMenu(compact)
	if not compact then compact = db.Compact end
	if compact then
		local x_spacing = db.Spacing
		local y_spacing = -db.Spacing
		local frameWidth =  190 + db.Spacing * 6
		local frameHeight = 210 + db.Spacing * 6
		RaidMenu_Parent:SetSize(frameWidth, frameHeight)
		RaidMenu_BG:SetSize(frameWidth, frameHeight)
		RaidMenu:SetSize(frameWidth, frameHeight)
		RaidMenu_Border:SetSize(frameWidth, frameHeight)
		RaidMenu_Header:Hide()

		-- Raid Icons
		FormatMarker(SkullRaidIcon,     15,                   -75  + y_spacing * 2,  0,   0,   0,   8, 0.75, 1,    0.25, 0.5)
		FormatMarker(CrossRaidIcon,     15,                   -100 + y_spacing * 3,  0,   0,   0,   7, 0.5,  0.75, 0.25, 0.5)
		FormatMarker(SquareRaidIcon,    15,                   -125 + y_spacing * 4,  0,   0,   0,   6, 0.25, 0.5,  0.25, 0.5)
		FormatMarker(MoonRaidIcon,      15,                   -150 + y_spacing * 5,  0,   0,   0,   5, 0,    0.25, 0.25, 0.5)
		FormatMarker(TriangleRaidIcon,  40   + x_spacing,     -75  + y_spacing * 2,  0,   0,   0,   4, 0.75, 1,    0,    0.25)
		FormatMarker(DiamondRaidIcon,   40   + x_spacing,     -100 + y_spacing * 3,  0,   0,   0,   3, 0.5,  0.75, 0,    0.25)
		FormatMarker(CircleRaidIcon,    40   + x_spacing,     -125 + y_spacing * 4,  0,   0,   0,   2, 0.25, 0.5,  0,    0.25)
		FormatMarker(StarRaidIcon,      40   + x_spacing,     -150 + y_spacing * 5,  0,   0,   0,   1, 0,    0.25, 0,    0.25)
		FormatMarker(ClearRaidIcon,     27.5 + x_spacing / 2, -175 + y_spacing * 6,  0,   0,   0,   0, 0,    1,    0,    1)
		-- Markers
		FormatMarker(BlueWorldMarker,   30,                   -25,                   0,   0.4, 0.9, 1) -- 0.00, 0.44, 0.87
		FormatMarker(GreenWorldMarker,  55  + x_spacing,      -25,                   0.1, 1,   0,   2) -- 0.12, 1.00, 0.00
		FormatMarker(PurpleWorldMarker, 80  + x_spacing * 2,  -25,                   0.6, 0.2, 0.9, 3) -- 0.64, 0.21, 0.93
		FormatMarker(RedWorldMarker,    105 + x_spacing * 3,  -25,                   1,   0.1, 0.1, 4) -- 1.00, 0.13, 0.13
		FormatMarker(YellowWorldMarker, 30,                   -50   + y_spacing,     1,   1,   0,   5) -- 1.00, 1.00, 0.00
		FormatMarker(OrangeWorldMarker, 55  + x_spacing,      -50   + y_spacing,     1,   0.5, 0.2, 6) -- 1.00, 0.50, 0.25
		FormatMarker(SilverWorldMarker, 80  + x_spacing * 2,  -50   + y_spacing,     0.7, 0.7, 0.7, 7) -- 0.67, 0.67, 0.67
		FormatMarker(WhiteWorldMarker,  105 + x_spacing * 3,  -50   + y_spacing,     1,   1,   1,   8) -- 1.00, 1.00, 1.00
		FormatMarker(ClearWorldMarkers, 130 + x_spacing * 4,  -37.5 + y_spacing / 2, 0,   0,   0)
		-- Buttons
		FormatMarker(ReadyChecker,      65 + x_spacing * 2,   -75   + y_spacing * 2)
		FormatMarker(RoleChecker,       65 + x_spacing * 2,   -100  + y_spacing * 3)
		FormatMarker(ConvertRaid,       65 + x_spacing * 2,   -125  + y_spacing * 4)

	else
		local frameWidth = 256
		local frameHeight = 291
		RaidMenu_Parent:SetSize(frameWidth, frameHeight)
		RaidMenu_BG:SetSize(frameWidth, frameHeight)
		RaidMenu:SetSize(frameWidth, frameHeight)
		RaidMenu_Border:SetSize(frameWidth, frameHeight)
		RaidMenu_Header:Show()
		FormatMarker(SkullRaidIcon,     20,  -50,  0,   0,   0,   8, 0.75, 1,    0.25, 0.5)
		FormatMarker(CrossRaidIcon,     20,  -90,  0,   0,   0,   7, 0.5,  0.75, 0.25, 0.5)
		FormatMarker(SquareRaidIcon,    20,  -130, 0,   0,   0,   6, 0.25, 0.5,  0.25, 0.5)
		FormatMarker(MoonRaidIcon,      20,  -170, 0,   0,   0,   5, 0,    0.25, 0.25, 0.5)
		FormatMarker(TriangleRaidIcon,  60,  -50,  0,   0,   0,   4, 0.75, 1,    0,    0.25)
		FormatMarker(DiamondRaidIcon,   60,  -90,  0,   0,   0,   3, 0.5,  0.75, 0,    0.25)
		FormatMarker(CircleRaidIcon,    60,  -130, 0,   0,   0,   2, 0.25, 0.5,  0,    0.25)
		FormatMarker(StarRaidIcon,      60,  -170, 0,   0,   0,   1, 0,    0.25, 0,    0.25)
		FormatMarker(ClearRaidIcon,     40,  -210, 0,   0,   0,   0, 0,    1,    0,    1)
		FormatMarker(BlueWorldMarker,   110, -175, 0,   0.4, 0.9, 1)
		FormatMarker(GreenWorldMarker,  145, -175, 0.1, 1,   0,   2)
		FormatMarker(PurpleWorldMarker, 180, -175, 0.6, 0.2, 0.9, 3)
		FormatMarker(RedWorldMarker,    110, -210, 1,   0.1, 0.1, 4)
		FormatMarker(YellowWorldMarker, 145, -210, 1,   1,   0,   5)
		FormatMarker(OrangeWorldMarker, 180, -210, 1,   0.5, 0.2, 6)
		FormatMarker(SilverWorldMarker, 110, -245, 0.7, 0.7, 0.7, 7)
		FormatMarker(WhiteWorldMarker,  145, -245, 1,   1,   1,   8)
		FormatMarker(ClearWorldMarkers, 180, -245, 0,   0,   0)
		FormatMarker(ReadyChecker,      105, -50)
		FormatMarker(RoleChecker,       105, -75)
		FormatMarker(ConvertRaid,       105, -100)
	end
end

function module:SetColors()
	if not db.Enable or not Micromenu or not RaidMenu_Parent then return end
	local r, g, b
	if db.MatchMicromenuBackground then
		r, g, b = Micromenu:RGB("Background")
	else
		local color = db.BackgroundColor
		r, g, b = color.r, color.g, color.b
	end
	RaidMenu_BG.Texture:SetVertexColor(r, g, b)
	RaidMenu.Texture:SetVertexColor(r, g, b)
	RaidMenu_Border.Texture:SetVertexColor(Micromenu:RGB("Micromenu"))
end

function module:SetRaidMenu()
	db = module.db.profile

	if not module:IsEnabled() or not db.Enable or not Micromenu or not Micromenu:IsEnabled() or not Micromenu.buttonLeft then return end
	if InCombatLockdown() then
		QueueAfterCombat("setup")
		return
	end
	if RaidMenu_Parent then
		UpdateGroupButtons()
		module:Refresh()
		return
	end

	-- Create frames for Raid Menu
	RaidMenu_Parent = LUI:CreateMeAFrame("Frame", "RaidMenu_Parent", Micromenu.buttonLeft, 256, 256, 1, "HIGH", 0, "TOPRIGHT", Micromenu.buttonLeft, "BOTTOMRIGHT", X_normal, ((Y_normal / db.Scale) + 17), 1)
	if Micromenu.background:IsShown() and db.OverlapPrevention == "Offset" then
		RaidMenu_Parent:SetPoint("TOPRIGHT", Micromenu.buttonLeft, "BOTTOMRIGHT", X_normal, (((Y_normal + db.Offset) / db.Scale) + 17))
	else
		RaidMenu_Parent:SetPoint("TOPRIGHT", Micromenu.buttonLeft, "BOTTOMRIGHT", X_normal, ((Y_normal / db.Scale) + 17))
	end
	RaidMenu_Parent:SetScale(db.Scale)
	RaidMenu_Parent:Hide()

	RaidMenu_BG = LUI:CreateMeAFrame("Frame", "RaidMenu_BG", RaidMenu_Parent, 256, 256, 1, "HIGH", 1, "TOPRIGHT", RaidMenu_Parent, "TOPRIGHT", 0, 0, 1)
	RaidMenu_BG.Texture = LUI:CreateFrameTexture(RaidMenu_BG, RAIDMENU_BG_TEXTURE)
	RaidMenu_BG.Texture:SetVertexColor(Micromenu:RGB("Background"))

	RaidMenu = LUI:CreateMeAFrame("Frame", "RaidMenu", RaidMenu_Parent, 256, 256, 1, "HIGH", 2, "TOPRIGHT", RaidMenu_Parent, "TOPRIGHT", 0, 0, 1)
	RaidMenu:SetMouseClickEnabled(true)
	RaidMenu.Texture = LUI:CreateFrameTexture(RaidMenu, RAIDMENU_NORMAL_TEXTURE)
	RaidMenu.Texture:SetVertexColor(Micromenu:RGB("Background"))

	-- With the micromenu collapsed, this panel overlaps its own toggle.
	-- Keep the small click target above the panel and its level-4 buttons.
	Micromenu.clickerLeft:SetFrameStrata("HIGH")
	Micromenu.clickerLeft:SetFrameLevel(5)

	local micro_r, micro_g, micro_b = Micromenu:RGB("Micromenu")
	RaidMenu_Border = LUI:CreateMeAFrame("Frame", "RaidMenu_Border", RaidMenu_Parent, 256, 256, 1, "HIGH", 3, "TOPRIGHT", RaidMenu_Parent, "TOPRIGHT", 2, 1, 1)
	RaidMenu_Border.Texture = LUI:CreateFrameTexture(RaidMenu_Border, RAIDMENU_BORDER_TEXTURE)
	RaidMenu_Border.Texture:SetVertexColor(micro_r, micro_g, micro_b, 1)

	local Infotext = LUI:GetModule("Infotext", true)
	local font = Infotext and Infotext.db.profile.Fonts.Infotext or {Name = "vibroceb", Size = 12, Flag = ""}
	local color = Infotext and Infotext.db.profile.Clock.Color or {r = 1, g = 1, b = 1, a = 1}
	RaidMenu_Header = RaidMenu:CreateFontString("RaidMenu_Header", "OVERLAY")
	RaidMenu_Header:SetFont(Media:Fetch("font", font.Name), LUI:Scale(20), "THICKOUTLINE")
	RaidMenu_Header:SetPoint("TOP", RaidMenu, "TOP", -5, -25)
	RaidMenu_Header:SetTextColor(color.r, color.g, color.b, color.a)
	RaidMenu_Header:SetText("LUI Raid Menu")

	-- Create buttons for Raid Menu
	SkullRaidIcon = CreateFrame("Button", "SkullRaidIcon", RaidMenu, "LUISecureMarkerTemplate")
	CrossRaidIcon = CreateFrame("Button", "CrossRaidIcon", RaidMenu, "LUISecureMarkerTemplate")
	SquareRaidIcon = CreateFrame("Button", "SquareRaidIcon", RaidMenu, "LUISecureMarkerTemplate")
	MoonRaidIcon = CreateFrame("Button", "MoonRaidIcon", RaidMenu, "LUISecureMarkerTemplate")
	TriangleRaidIcon = CreateFrame("Button", "TriangleRaidIcon", RaidMenu, "LUISecureMarkerTemplate")
	DiamondRaidIcon = CreateFrame("Button", "DiamondRaidIcon", RaidMenu, "LUISecureMarkerTemplate")
	CircleRaidIcon = CreateFrame("Button", "CircleRaidIcon", RaidMenu, "LUISecureMarkerTemplate")
	StarRaidIcon = CreateFrame("Button", "StarRaidIcon", RaidMenu, "LUISecureMarkerTemplate")
	ClearRaidIcon = CreateFrame("Button", "ClearRaidIcon", RaidMenu, "LUISecureMarkerTemplate")
	BlueWorldMarker = CreateFrame("Button", "BlueWorldMarker", RaidMenu, "LUISecureMarkerTemplate")
	GreenWorldMarker = CreateFrame("Button", "GreenWorldMarker", RaidMenu, "LUISecureMarkerTemplate")
	PurpleWorldMarker = CreateFrame("Button", "PurpleWorldMarker", RaidMenu, "LUISecureMarkerTemplate")
	RedWorldMarker = CreateFrame("Button", "RedWorldMarker", RaidMenu, "LUISecureMarkerTemplate")
	YellowWorldMarker = CreateFrame("Button", "YellowWorldMarker", RaidMenu, "LUISecureMarkerTemplate")
	WhiteWorldMarker = CreateFrame("Button", "WhiteWorldMarker", RaidMenu, "LUISecureMarkerTemplate")
	OrangeWorldMarker = CreateFrame("Button", "OrangeWorldMarker", RaidMenu, "LUISecureMarkerTemplate")
	SilverWorldMarker = CreateFrame("Button", "SilverWorldMarker", RaidMenu, "LUISecureMarkerTemplate")
	ClearWorldMarkers = CreateFrame("Button", "ClearWorldMarkers", RaidMenu, "LUISecureMarkerTemplate")

	ConfigureRaidTargetButton(SkullRaidIcon, 8)
	ConfigureRaidTargetButton(CrossRaidIcon, 7)
	ConfigureRaidTargetButton(SquareRaidIcon, 6)
	ConfigureRaidTargetButton(MoonRaidIcon, 5)
	ConfigureRaidTargetButton(TriangleRaidIcon, 4)
	ConfigureRaidTargetButton(DiamondRaidIcon, 3)
	ConfigureRaidTargetButton(CircleRaidIcon, 2)
	ConfigureRaidTargetButton(StarRaidIcon, 1)
	ConfigureRaidTargetButton(ClearRaidIcon, 0)
	ConfigureWorldMarkerButton(BlueWorldMarker, 1)
	ConfigureWorldMarkerButton(GreenWorldMarker, 2)
	ConfigureWorldMarkerButton(PurpleWorldMarker, 3)
	ConfigureWorldMarkerButton(RedWorldMarker, 4)
	ConfigureWorldMarkerButton(YellowWorldMarker, 5)
	ConfigureWorldMarkerButton(OrangeWorldMarker, 6)
	ConfigureWorldMarkerButton(SilverWorldMarker, 7)
	ConfigureWorldMarkerButton(WhiteWorldMarker, 8)
	ConfigureWorldMarkerButton(ClearWorldMarkers)

	ConvertRaid = CreateFrame("Button", "ConvertRaid", RaidMenu, "UIPanelButtonTemplate")
	local monitoredEvents = {
		"GROUP_ROSTER_UPDATE",
		"PARTY_LEADER_CHANGED",
		"PARTY_LFG_RESTRICTED",
		"PLAYER_ENTERING_WORLD",
		"PLAYER_REGEN_DISABLED",
		"PLAYER_REGEN_ENABLED",
	}
	for i = 1, #monitoredEvents do
		ConvertRaid:RegisterEvent(monitoredEvents[i])
	end
	ConvertRaid:SetScript("OnEvent", UpdateGroupButtons)

	ConvertRaid:SetScript("OnEnter", function(self)
		if db.ShowToolTips then
			GameTooltip:SetOwner(ConvertRaid, "ANCHOR_BOTTOMLEFT")
			GameTooltip:SetClampedToScreen(true)
			GameTooltip:ClearLines()
			if IsInRaid() then
				GameTooltip:SetText("Convert to Party")
				GameTooltip:AddLine("Convert your Raid Group into a 5 man party", 204/255,204/255, 204/255, 1)
				GameTooltip:AddLine("Only works with raid groups of 5 or less members!", 204/255, 204/255, 204/255, 1)
			else
				GameTooltip:SetText("Convert to Raid")
				GameTooltip:AddLine("Convert your party into a Raid Group", 204/255, 204/255, 204/255, 1)
			end
			GameTooltip:Show()
		end
	end)
	ConvertRaid:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	ConvertRaid:SetScript("OnClick", function(self)
		if InCombatLockdown() then return end
		UpdateGroupButtons()
		if not self:IsEnabled() then return end
		if IsInRaid() then
			C_PartyInfo.ConvertToParty()
		else
			C_PartyInfo.ConvertToRaid()
		end
		if db.AutoHide then
			module:CloseRaidMenu()
		end
	end)

	RoleChecker = CreateFrame("BUTTON", "RoleChecker", RaidMenu, "UIPanelButtonTemplate")
	RoleChecker:SetText("Role Check")
	RoleChecker:SetScript("OnEnter", function(self)
		if db.ShowToolTips then
			GameTooltip:SetOwner(RoleChecker, "ANCHOR_BOTTOMLEFT")
			GameTooltip:SetClampedToScreen(true)
			GameTooltip:ClearLines()
			GameTooltip:SetText("Role Check")
			GameTooltip:AddLine("Perform a Role Check", 204/255, 204/255, 204/255, 1)
			GameTooltip:Show()
		end
	end)
	RoleChecker:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	RoleChecker:SetScript("OnClick", function(self)
		if InCombatLockdown() then return end
		UpdateGroupButtons()
		if not self:IsEnabled() then return end
		InitiateRolePoll()
		if db.AutoHide then
			module:CloseRaidMenu()
		end
	end)

	ReadyChecker = CreateFrame("Button", "ReadyChecker", RaidMenu, "UIPanelButtonTemplate")
	ReadyChecker:SetText("Ready Check")
	ReadyChecker:SetScript("OnEnter", function(self)
		if db.ShowToolTips then
			GameTooltip:SetOwner(ReadyChecker, "ANCHOR_BOTTOMLEFT")
			GameTooltip:SetClampedToScreen(true)
			GameTooltip:ClearLines()
			GameTooltip:SetText("Ready Check")
			GameTooltip:AddLine("Perform a Ready Check", 204/255, 204/255, 204/255, 1)
			GameTooltip:Show()
		end
	end)
	ReadyChecker:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	ReadyChecker:SetScript("OnClick", function(self)
		if InCombatLockdown() then return end
		UpdateGroupButtons()
		if not self:IsEnabled() then return end
		C_PartyInfo.DoReadyCheck()
		if db.AutoHide then
			module:CloseRaidMenu()
		end
	end)
	UpdateGroupButtons()

	animationFrame = CreateFrame("Frame", nil, UIParent)
	animationFrame:Hide()
	animationFrame:SetScript("OnUpdate", function(self, elapsed)
		-- Combat can begin between a click and any later animation tick.
		-- Pause geometry/visibility changes, then settle the latest requested
		-- state once combat ends. Alpha is cosmetic: keep the paused parent
		-- visible so an interrupted fade cannot leave an invisible click blocker.
		if InCombatLockdown() then
			RaidMenu_Parent:SetAlpha(db.Opacity / 100)
			self:Hide()
			QueueAfterCombat("refresh")
			return
		end
		if fade then
			fade.elapsed = math.min(.5, fade.elapsed + elapsed)
			local progress = fade.elapsed / .5
			RaidMenu_Parent:SetAlpha(fade.from + (fade.target - fade.from) * progress)
			if progress == 1 then
				if not menuShown then RaidMenu_Parent:Hide() end
				fade = nil
			end
		end
		if slide then
			slide.elapsed = math.min(.5, slide.elapsed + elapsed)
			local progress = slide.elapsed / .5
			RaidMenu_Parent:SetPoint("TOPRIGHT", Micromenu.buttonLeft, "BOTTOMRIGHT",
				slide.x + (slide.targetX - slide.x) * progress,
				slide.y + (slide.targetY - slide.y) * progress)
			if progress == 1 then slide = nil end
		end
		if not fade and not slide then self:Hide() end
	end)

	-- Follow actual visibility changes instead of guessing the next state.
	Micromenu.background:HookScript("OnShow", function() module:OverlapPrevention("MM") end)
	Micromenu.background:HookScript("OnHide", function() module:OverlapPrevention("MM") end)
	module:Refresh()
end

function module:Refresh()
	db = module.db.profile
	if not RaidMenu_Parent then return end
	if InCombatLockdown() then
		QueueAfterCombat("refresh")
		return
	end
	if not module:IsEnabled() or not db.Enable or not Micromenu:IsEnabled() then
		module:HideRaidMenu()
		return
	end
	StopAnimations()
	SizeRaidMenu()
	RaidMenu_Parent:SetScale(db.Scale)
	PositionMenu()
	if db.OverlapPrevention == "AutoHide" and Micromenu.background:IsShown() then
		menuShown = false
	end
	RaidMenu_Parent:SetAlpha(menuShown and db.Opacity / 100 or 0)
	RaidMenu_Parent:SetShown(menuShown)
	module:SetColors()
end

function module:SetRaidMenuEnabled(enabled)
	db = module.db.profile
	db.Enable = enabled
	if InCombatLockdown() then
		QueueAfterCombat(enabled and "setup" or "hide")
		return
	end
	if enabled then
		module:SetRaidMenu()
	else
		module:HideRaidMenu()
	end
end

function module:HideRaidMenu()
	menuShown = false
	StopAnimations()
	if not RaidMenu_Parent then return end
	if InCombatLockdown() then
		RaidMenu_Parent:SetAlpha(db.Opacity / 100)
		QueueAfterCombat("hide")
		return
	end
	RaidMenu_Parent:Hide()
	RaidMenu_Parent:SetAlpha(0)
end
