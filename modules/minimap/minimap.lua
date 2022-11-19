--[[
	Module.....: Minimap
	Description: Replace the default minimap.
]]
-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################
-- luacheck: globals LUIMinimapZone LUIMinimapCoord LUIMinimapBorder

---@type string, LUIAddon
local _, LUI = ...
local L = LUI.L

---@type MinimapModule
local module = LUI:GetModule("Minimap")
local db

-- Locals and Constants
local GetMinimapZoneText = _G.GetMinimapZoneText
local ToggleDropDownMenu = _G.ToggleDropDownMenu
local TrackingFrame = _G.MinimapCluster.Tracking
local MailFrame = _G.MinimapCluster.MailFrame
local MINIMAP_LABEL = _G.MINIMAP_LABEL
local Minimap = _G.Minimap

local MAIL_ICON_TEXTURE = "Interface\\AddOns\\LUI\\modules\\minimap\\mail.tga"
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
local defaultGarrisonState = false
local minimapShape = "ROUND"  -- Shape of the minimap, used for GetMinimapShape() community api.
local oldDefault = {}         -- Keep information on default minimap

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

--- Community API to know minimap shape. For others mods with a minimap button.
function GetMinimapShape() return minimapShape end

local minimapFrames = {
	"MinimapCluster",          --Minimap Original Parent, contains ZoneText, MailFrame, Tracking, InstanceDifficulties
	--"MinimapBackdrop",           --Borders, contains Garrison button however.
	"TimeManagerClockButton",  --Clock
	"GameTimeFrame",           --Calendar
	"MinimapCompassTexture"		-- Dragonflight Minimap Frame
}

function module:HideDefaultMinimap()
	-- Hide Several Frames surrounding minimap, after taking note of their state
	for _, frameName in pairs(minimapFrames) do
		local frame = _G[frameName]
		if frame then
			oldDefault[frameName] = frame:IsShown()
			LUI:Kill(frame)
		end
	end

	--Change Minimap's Parent:
	oldDefault.scale = Minimap:GetScale()
	oldDefault.parent = Minimap:GetParent()
	Minimap:SetParent(UIParent)

	--Reparent Mail and Tracking
	MailFrame:SetParent(Minimap)
	--TrackingFrame:SetParent(Minimap)
	
	--Turn the Minimap into a square
	Minimap:SetMaskTexture(MINIMAP_SQUARE_TEXTURE_MASK)
	minimapShape = "SQUARE"

	-- Change textures around, keep old textures around.
	LUI:Kill(Minimap.ZoomHitArea)
	LUI:Kill(Minimap.ZoomIn)
	LUI:Kill(Minimap.ZoomOut)

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

	-- Show several frames based on their previous state
	for _, frameName in pairs(minimapFrames) do
		local frame = _G[frameName]
		if frame then
			LUI:Unkill(frame)
			if oldDefault[frameName] then
				frame:Show()
			end
		end
	end
	LUI:Unkill(Minimap.ZoomHitArea)
	LUI:Unkill(Minimap.ZoomIn)
	LUI:Unkill(Minimap.ZoomOut)

	--Revert Minimap Parent
	Minimap:SetParent(oldDefault.parent)
	Minimap:SetScale(oldDefault.scale)

	--Turn the Minimap back into a circle
	Minimap:EnableMouseWheel(false)
	Minimap:SetMaskTexture(MINIMAP_ROUND_TEXTURE_MASK)
	minimapShape = "ROUND"

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

---@TODO: Re-evaluate these Garrison functions.

-- ####################################################################################################################
-- ##### Module Setup #################################################################################################
-- ####################################################################################################################

function module:SetMinimap()
	db = module.db.profile
	module:HideDefaultMinimap()

	--Enable Scroll Zooming
	Minimap:EnableMouseWheel(true)
	--The default minimap does not have mousewheel scrolling.
	Minimap:SetScript("OnMouseWheel", function(self, delta)
		if module:IsEnabled() then
			if delta > 0 then
				Minimap.ZoomIn:Click()
			elseif delta < 0 then
				Minimap.ZoomOut:Click()
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
		minimapZoneText:SetText(GetMinimapZoneText() or "")
	end)

	-- Add an offset to the Garrison/Covenant button so it does not cover the coordinates
	local expansionButton = _G.ExpansionLandingPageMinimapButton
	-- local expPoint, expParent, expRelativePoint, expOffsetX, expOffsetY = expansionButton:GetPoint(1)
	-- expansionButton:ClearAllPoints()
	-- expansionButton:SetPoint(expPoint, expParent, expRelativePoint, expOffsetX, expOffsetY + 20)

	-- -- Move the Mail
	MailFrame:ClearAllPoints()
	MailFrame:SetPoint("BOTTOMLEFT", expansionButton, "TOPLEFT", 15, 0)

	-- Set Coord Text
	local minimapCoord = CreateFrame("Frame", "LUIMinimapCoord", Minimap)
	minimapCoord:SetSize(40, 20)
	minimapCoord:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", -5, 5)

	local minimapCoordText = module:SetFontString(minimapCoord, "LUIMinimapCoordText", "Text", "Overlay", "RIGHT", "MIDDLE")
	minimapCoordText:SetPoint("RIGHT", -1, 0)
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
	Minimap:HookScript("OnEnter",function()
		if module:IsEnabled() then
			LUIMinimapZone:Show()
			LUIMinimapCoord:Show()
		end
	end)
	Minimap:HookScript("OnLeave",function()
		if not db.General.AlwaysShowText then
			LUIMinimapZone:Hide()
			LUIMinimapCoord:Hide()
		end
	end)

	Minimap:SetScript("OnMouseUp", function(self, button)
		--Right Click shows the Tracking dropdown, only if module is enabled.
		if button == "RightButton" and module:IsEnabled() then
			ToggleDropDownMenu(1, nil, TrackingFrame.DropDown, self);
		else Minimap:OnClick(self)
		end
	end)

	--Create other frames around the minimap
	module:SetMinimapFrames()

	if LUI.IsRetail then
		self:SecureHook(_G.MawBuffsBelowMinimapFrameMixin, "OnShow", function() self:SetPosition('MawBuffs') end)
	end

	--Prevent these initialization functions from running again.
	function module:SetMinimap()
		module:SetMinimapPosition()
		module:SetMinimapAgain()
	end
end

--If module is disabled and re-enabled, call this instead to prevent re-initializing everything
function module:SetMinimapAgain()
	Minimap:EnableMouseWheel(true)
	module:HideDefaultMinimap()
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
	local borderEdgeSize = 5
	local borderBackdrop = {
		bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile=LUI.Media.glowTex,
		tile=0, tileSize=0, edgeSize=borderEdgeSize,
		insets={left=0, right=0, top=0, bottom=0}
	}

	local r, g, b, a = module:RGBA("Minimap")
	local texOffX = { -7, 7, 7, -7, -10, 10, 10, -10 }
	local texOffY = { -7, -7, 7, 7, -10, -10, 10, 10 }
	local texPoint = { "BOTTOMLEFT", "BOTTOMRIGHT", "TOPRIGHT", "TOPLEFT" }

	--Create Border
	local minimapBorder = CreateFrame("Frame", "LUIMinimapBorder", Minimap, "BackdropTemplate")
	local borderSize = Minimap:GetSize() * (1 + borderEdgeSize/100)
	minimapBorder:SetSize(borderSize, borderSize)
	minimapBorder:SetFrameStrata("BACKGROUND")
	minimapBorder:SetPoint("CENTER", Minimap, "CENTER", 0, 0)
	minimapBorder:SetBackdrop(borderBackdrop)
	minimapBorder:SetBackdropColor(0,0,0,0)
	minimapBorder:SetBackdropBorderColor(0,0,0,1) -- 0,0,0,1 in v3

	--Create Corner Textures (Tex1-Tex4)
	local textureBackdrop = {
		bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile=LUI.Media.glowTex,
		tile=0, tileSize=0, edgeSize=5,
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

	for i = 5, 8 do
		local minimapTex = CreateFrame("Frame", "LUIMinimapTexture"..i, Minimap, "BackdropTemplate")
		minimapTex:SetSize(56,56)
		minimapTex:SetFrameStrata("BACKGROUND")
		minimapTex:SetPoint(texPoint[i-4], Minimap, texPoint[i-4], texOffX[i], texOffY[i])
		minimapTex:SetFrameLevel(minimapTex:GetFrameLevel()-1)
		minimapTex:SetBackdrop(textureBackdrop)
		minimapTex:SetBackdropColor(0,0,0,0)
		minimapTex:SetBackdropBorderColor(0,0,0,1)
	end
end

function module:SetMinimapSize()
	LUI:RegisterConfig(Minimap, db.Position)
	LUI:RestorePosition(Minimap)
end

function module:SetMinimapPosition()
	LUI:RestorePosition(Minimap)
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

function module:Refresh()
	module:ToggleMinimapText()
	module:RefreshFontString(_G.LUIMinimapCoordText, "Text")
	module:RefreshFontString(_G.LUIMinimapZoneText, "Text")
	module:ToggleMinimapTextures()
	module:SetMinimapPosition()
	module:RefreshColors()
end

function module:RefreshColors()
	local r, g, b, a = module:RGBA("Minimap")
	for i = 1, 4 do
		_G["LUIMinimapTexture"..i]:SetBackdropBorderColor(r,g,b,a)
	end
end
