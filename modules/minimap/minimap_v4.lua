--[[
	Module.....: Minimap
	Description: Replace the default minimap.
]]
-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

local _, LUI = ...
local module = LUI:NewModule("Minimap")
local L = LUI.L
local db

-- luacheck: globals MinimapZoomIn MinimapZoomOut GarrisonLandingPageMinimapButton MiniMapTrackingDropDown
-- luacheck: globals LUIMinimapZone LUIMinimapCoord LUIMinimapBorder Minimap_OnClick

-- Constants

local MINIMAP_LABEL = MINIMAP_LABEL
local MAIL_ICON_TEXTURE = "Interface\\AddOns\\LUI4\\media\\mail.tga"
local MINIMAP_SQUARE_TEXTURE_MASK = "Interface\\ChatFrame\\ChatFrameBackground"
local MINIMAP_ROUND_TEXTURE_MASK = "Textures\\MinimapMask"
local ICON_LOCATION = {
		Mail = "BOTTOMLEFT",
		BG = "BOTTOMRIGHT",
		LFG = "TOPRIGHT",
		GMTicket = "TOPLEFT",
}
local COORD_FORMAT_LIST = {
		[0] = "%d, %d",
		[1] = "%.1f, %.1f",
		[2] = "%.2f, %.2f",
}

-- local variables
--local MINIMAP_SIZE = 140      -- Base size for the minimap, based on default minimap.

local minimapShape = "ROUND"  -- Shape of the minimap, used for GetMinimapShape() community api.
local oldDefault = {}         -- Keep information on default minimap

-- ####################################################################################################################
-- ##### Default Settings #############################################################################################
-- ####################################################################################################################

module.defaults = {
	profile = {
		General = {
			Scale = 1,
			CoordPrecision = 1,
			AlwaysShowText = false,
			HideMissingCoord = true,
			ShowTextures = true,
			FontSize = 12,
		},
		Position = {
			X = -24,
			Y = -80,
			--RelativePoint = "TOPRIGHT",
			Point = "TOPRIGHT",
			Locked = false,
			Scale = 1,
		},
		Fonts = {
			Text = { Name = "NotoSans-SCB", Size = 12, Flag = "OUTLINE", },
		},
		Colors = {
			Minimap = { r = 0.21, g = 0.22, b = 0.23, a = 1, t = "Class", },
		},
	},
}

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

-- For others mods with a minimap button, community API to know minimap shape.
function GetMinimapShape() return minimapShape end

-- luacheck: push ignore

function module:HideDefaultMinimap()
	-- Hide Several Frames surrounding minimap
	MinimapCluster:Hide()          --Minimap Original Parent, contains ZoneText, InstanceDifficulties
	MinimapBorder:Hide()           --Borders
	MinimapZoomIn:Hide()           --Zoom
	MinimapZoomOut:Hide()
	MiniMapWorldMapButton:Hide()   --World Map
	TimeManagerClockButton:Hide()  --Clock
	MiniMapTracking:Hide()         --Tracking
	GameTimeFrame:Hide()           --Calendar

	--Change Minimap's Parent:
	oldDefault.scale = Minimap:GetScale()
	oldDefault.parent = Minimap:GetParent()
	Minimap:SetParent(UIParent)

	--Turn the Minimap into a square
	Minimap:SetMaskTexture(MINIMAP_SQUARE_TEXTURE_MASK)
	minimapShape = "SQUARE"

	-- Change textures around, keep old textures around.
	oldDefault.NorthTag = MinimapNorthTag:GetTexture()
	MinimapNorthTag:SetTexture(nil)	--North Arrow

	-- Move Mail icon
	MiniMapMailFrame:ClearAllPoints()
	MiniMapMailFrame:SetPoint(ICON_LOCATION.Mail, Minimap, 3, 8)
	MiniMapMailBorder:Hide()
	oldDefault.Mail = MiniMapMailIcon:GetTexture()
	MiniMapMailIcon:SetTexture(MAIL_ICON_TEXTURE)

	--Size and Position

	local point, relativeTo, relativePoint, xOff, yOff = Minimap:GetPoint(1)
	oldDefault.point = point
	oldDefault.relativeTo = relativeTo
	oldDefault.relativePoint = relativePoint
	oldDefault.X = xOff
	oldDefault.Y = yOff
	oldDefault.width = Minimap:GetWidth()
	oldDefault.height = Minimap:GetHeight()

end

function module:RestoreDefaultMinimap()

	-- Show Several Frames surrounding minimap
	MinimapCluster:Show()          --Minimap Original Parent
	MinimapBorder:Show()           --Border
	MinimapZoomIn:Show()           --Zoom
	MinimapZoomOut:Show()
	MiniMapWorldMapButton:Show()   --World Map
	TimeManagerClockButton:Show()  --Clock
	MiniMapTracking:Show()         --Tracking
	GameTimeFrame:Show()           --Calendar
	MinimapNorthTag:SetTexture(oldDefault.NorthTag)	--North Arrow

	--Revert Minimap Parent
	Minimap:SetParent(oldDefault.parent)
	Minimap:SetScale(oldDefault.scale)

	--Turn the Minimap back into a circle
	Minimap:EnableMouseWheel(false)
	Minimap:SetMaskTexture(MINIMAP_ROUND_TEXTURE_MASK)
	minimapShape = "ROUND"

	-- Move Mail icon
	--MiniMapMailFrame:ClearAllPoints()
	MiniMapMailBorder:Show()
	MiniMapMailIcon:SetTexture(oldDefault.Mail)

	--Remove module centric frames
	LUIMinimapZone:Hide()
	LUIMinimapCoord:Hide()
	LUIMinimapBorder:Hide()
	for i = 1, 8 do
		_G["LUIMinimapTexture"..i]:Hide()
	end

	--Reset Position and Size
	Minimap:ClearAllPoints()
	Minimap:SetPoint(oldDefault.point, oldDefault.relativeTo, oldDefault.relativePoint, oldDefault.X, oldDefault.Y)
	Minimap:SetSize(oldDefault.width, oldDefault.height)
end
-- luacheck: pop

-- ####################################################################################################################
-- ##### Module Setup #################################################################################################
-- ####################################################################################################################

function module:SetMinimap()

	--Enable Scroll Zooming
	Minimap:EnableMouseWheel(true)
	--The default minimap does not have mousewheel scrolling.
	Minimap:SetScript("OnMouseWheel", function(self, delta)
		if module:IsEnabled() then
			if delta > 0 then
				MinimapZoomIn:Click()
			elseif delta < 0 then
				MinimapZoomOut:Click()
			end
		end
	end)

	module:SetMinimapSize()
	module:SetMinimapPosition()

	--Make sure not to create the frames more than once.
	-- Set Zone Text
	local minimapZone = CreateFrame("Frame", "LUIMinimapZone", Minimap)
	minimapZone:SetSize(0, 20)
	minimapZone:SetPoint("TOPLEFT", Minimap, 2, -2)
	minimapZone:SetPoint("TOPRIGHT",Minimap, -2. -2)

	local minimapZoneText = module:SetFontString(minimapZone, "LUIMinimapZoneText", "Text", "Overlay", "CENTER", "MIDDLE")
	minimapZoneText:SetPoint("CENTER", 0, 0)
	minimapZoneText:SetHeight(db.Fonts.Text.Size)
	minimapZoneText:SetWidth(minimapZone:GetWidth()-6)	--Why 6?

	--Add pvp coloring later. Make customizable.
	minimapZone:SetScript("OnUpdate", function(self)
		minimapZoneText:SetText(GetMinimapZoneText())
	end)

	-- Set Coord Text
	local minimapCoord = CreateFrame("Frame", "LUIMinimapCoord", Minimap)
	minimapCoord:SetSize(40, 20)
	minimapCoord:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 4, 2)

	local minimapCoordText = module:SetFontString(minimapCoord, "LUIMinimapCoordText", "Text", "Overlay", "LEFT", "MIDDLE")
	minimapCoordText:SetPoint("LEFT", -1, 0)
	minimapCoordText:SetText("00,00")

	minimapCoord:SetScript("OnUpdate", function(self)
		local uiMap = C_Map.GetBestMapForUnit("player")
		if uiMap then
			local position = C_Map.GetPlayerMapPosition(uiMap, "player")
			-- Inside dungeons, the call can fail and x and y will be nil
			if position then
				local x, y = position:GetXY()
				if x and y then
					return minimapCoordText:SetFormattedText(COORD_FORMAT_LIST[db.General.CoordPrecision], x * 100, y * 100)
				end
			end
		end
		-- Fallback if values aren't found.
		minimapCoordText:SetText("")
	end)

	module:ToggleMinimapText()	-- Refresh the Show/Hide for those two.

	--Script to add text when you mouseover the minimap
	Minimap:SetScript("OnEnter",function()
		if module:IsEnabled() then
			LUIMinimapZone:Show()
			LUIMinimapCoord:Show()
		end
	end)
	Minimap:SetScript("OnLeave",function()
		if not db.General.AlwaysShowText then
			LUIMinimapZone:Hide()
			LUIMinimapCoord:Hide()
		end
	end)

	Minimap:SetScript("OnMouseUp", function(self, button)
		--Right Click shows the Tracking dropdown, only if module is enabled.
		if button == "RightButton" and module:IsEnabled() then
			ToggleDropDownMenu(1, nil, MiniMapTrackingDropDown, self)
		else Minimap_OnClick(self)
		end
	end)

	--Create other frames around the minimap
	module:SetMinimapFrames()


	--Prevent these initialization functions from running again.
	function module:SetMinimap()
		module:SetMinimapPosition()
		module:SetMinimapAgain()
	end
end

--If module is disabled and re-enabled, call this instead to prevent re-initializing everything
function module:SetMinimapAgain()
	Minimap:EnableMouseWheel(true)
	module:ToggleMinimapText()
	module:ToggleMinimapTextures()

	--When you call SetParent, all children strata are equal to the parent. This puts the textures back in the backgroun.
	LUIMinimapBorder:SetFrameStrata("BACKGROUND")
	for i = 1, 8 do
		_G["LUIMinimapTexture"..i]:SetFrameStrata("BACKGROUND")
	end
end

--Set Frames surrounding the minimap.
function module:SetMinimapFrames()
	--Setting up values
	local borderBackdrop = {
		bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile="Interface\\AddOns\\LUI4\\media\\borders\\glow.tga",
		tile=0, tileSize=0, edgeSize=7,
		insets={left=0, right=0, top=0, bottom=0}
	}

	local r, g, b, a = module:RGBA("Minimap")
	local texOffX = { -7, 7, 7, -7, -10, 10, 10, -10 }
	local texOffY = { -7, -7, 7, 7, -10, -10, 10, 10 }
	local texPoint = { "BOTTOMLEFT", "BOTTOMRIGHT", "TOPRIGHT", "TOPLEFT" }

	--Create Border
	local minimapBorder = CreateFrame("Frame", "LUIMinimapBorder", Minimap, "BackdropTemplate")
	minimapBorder:SetSize(143,143)
	minimapBorder:SetFrameStrata("BACKGROUND")
	minimapBorder:SetPoint("CENTER", Minimap, "CENTER", 0, 0)
	minimapBorder:SetBackdrop(borderBackdrop)
	minimapBorder:SetBackdropColor(0,0,0,0)
	minimapBorder:SetBackdropBorderColor(0,0,0,1) -- 0,0,0,1 in v3

	--Create Corner Textures (Tex1-Tex4)
	local textureBackdrop = {
		bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile="Interface\\AddOns\\LUI4\\media\\borders\\glow.tga",
		tile=0, tileSize=0, edgeSize=6,
		insets={left=3, right=3, top=3, bottom=3}
	}
	for i = 1, 4 do
		local minimapTex = CreateFrame("Frame", "LUIMinimapTexture"..i, Minimap, "BackdropTemplate")
		minimapTex:SetSize(50,50)
		minimapTex:SetFrameStrata("BACKGROUND")
		minimapTex:SetPoint(texPoint[i], Minimap, texPoint[i], texOffX[i], texOffY[i])
		minimapTex:SetBackdrop(textureBackdrop)
		minimapTex:SetBackdropColor(0,0,0,0)
		minimapTex:SetBackdropBorderColor(r,g,b,a)
	end

	--Create Shadow Textures (Tex1-Tex4)
	local shadowBackdrop = {
		bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile="Interface\\AddOns\\LUI4\\media\\borders\\glow.tga",
		tile=0, tileSize=0, edgeSize=4,
		insets={left=3, right=3, top=3, bottom=3}
	}
	for i = 5, 8 do
		local minimapTex = CreateFrame("Frame", "LUIMinimapTexture"..i, Minimap, "BackdropTemplate")
		minimapTex:SetSize(56,56)
		minimapTex:SetFrameStrata("BACKGROUND")
		minimapTex:SetPoint(texPoint[i-4], Minimap, texPoint[i-4], texOffX[i], texOffY[i])
		minimapTex:SetFrameLevel(minimapTex:GetFrameLevel()-1)
		minimapTex:SetBackdrop(shadowBackdrop)
		minimapTex:SetBackdropColor(0,0,0,0)
		minimapTex:SetBackdropBorderColor(0,0,0,1)
	end

	-- Move Garrison icon
	GarrisonLandingPageMinimapButton:ClearAllPoints();
	GarrisonLandingPageMinimapButton:SetSize(32,32);
	GarrisonLandingPageMinimapButton:SetPoint(ICON_LOCATION.Mail, Minimap, 3, 12)

	MiniMapMailFrame:HookScript("OnShow", function(self)
		GarrisonLandingPageMinimapButton:SetPoint("BOTTOMLEFT", MiniMapMailFrame, "TOPLEFT", 0, -4)
	end)
	MiniMapMailFrame:HookScript("OnHide", function(self)
		GarrisonLandingPageMinimapButton:SetPoint(ICON_LOCATION.Mail, Minimap, 3, 12)
	end)
end

function module:SetMinimapSize()
	LUI:RegisterConfig(Minimap, db.Position)
	LUI:RestorePosition(Minimap)
end

function module:SetMinimapPosition()
	LUI:RestorePosition(Minimap)
end

function module:SetColors()
	local r, g, b, a = module:RGBA("Minimap")
	for i = 1, 4 do
		_G["LUIMinimapTexture"..i]:SetBackdropBorderColor(r,g,b,a)
	end
end

function module:ToggleMinimapText()
	if db.General.AlwaysShowText then
		LUIMinimapZone:Show()
		LUIMinimapCoord:Show()
	else
		LUIMinimapZone:Hide()
		LUIMinimapCoord:Hide()
	end
end

function module:ToggleMinimapTextures()
	if db.General.ShowTextures then
		LUIMinimapBorder:Show()
		for i = 1, 8 do
			_G["LUIMinimapTexture"..i]:Show()
		end
	else
		LUIMinimapBorder:Hide()
		for i = 1, 8 do
			_G["LUIMinimapTexture"..i]:Hide()
		end
	end
end

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function module:OnInitialize()
	LUI:RegisterModule(module, true)
	db = module.db.profile
end

function module:OnEnable()
	module:HideDefaultMinimap()
	module:SetMinimap()
end

function module:OnDisable()
	module:RestoreDefaultMinimap()
end
