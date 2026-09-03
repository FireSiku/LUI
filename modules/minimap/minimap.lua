--[[
	Module.....: Minimap
	Description: Replace the default minimap.
]]
-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################
-- luacheck: globals LUIMinimapZone LUIMinimapCoord LUIMinimapBorder

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Minimap
local module = LUI:GetModule("Minimap")
local db

-- Locals and Constants
local GetMinimapZoneText = _G.GetMinimapZoneText
local TrackingButton = _G.MinimapCluster.Tracking.Button
local IndicatorFrame = _G.MinimapCluster.IndicatorFrame
local ExpansionButton = _G.ExpansionLandingPageMinimapButton
local Minimap = _G.Minimap
local InCombatLockdown = _G.InCombatLockdown

local MINIMAP_SQUARE_TEXTURE_MASK = "Interface\\ChatFrame\\ChatFrameBackground"
local MINIMAP_ROUND_TEXTURE_MASK = "Textures\\MinimapMask"
local COORD_FORMAT_LIST = {
		[0] = "%d, %d",
		[1] = "%.1f, %.1f",
		[2] = "%.2f, %.2f",
}

local minimapShape = "ROUND"  -- Shape of the minimap, used for GetMinimapShape() community api.
local originalGetMinimapShape = _G.GetMinimapShape
local function GetLuiMinimapShape() return minimapShape end
local oldDefault = {}         -- Keep information on default minimap
local pendingAction
local trackingMenu
local trackingAnchor = AnchorUtil.CreateAnchor("TOPRIGHT", Minimap, "TOPLEFT", -10, 8)

local combatQueue = CreateFrame("Frame")
combatQueue:Hide()
combatQueue:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:Hide()

	local action = pendingAction
	pendingAction = nil
	if action == "restore" or not module:IsEnabled() then
		module:RestoreDefaultMinimap(true)
	elseif action == "refresh" then
		module:Refresh(true)
	else
		module:SetMinimap(true)
	end
end)

local function QueueAfterCombat(action)
	if action ~= "refresh" or not pendingAction then
		pendingAction = action
	end
	combatQueue:RegisterEvent("PLAYER_REGEN_ENABLED")
	combatQueue:Show()
end

local function CapturePoints(frame)
	local points = {}
	for i = 1, frame:GetNumPoints() do
		points[i] = {frame:GetPoint(i)}
	end
	return points
end

local function RestorePoints(frame, points)
	frame:ClearAllPoints()
	for _, point in ipairs(points or {}) do
		frame:SetPoint(unpack(point))
	end
end

function module:PositionMinimapIcons()
	if not db or not db.Icons then return end
	if ExpansionButton then
		ExpansionButton:ClearAllPoints()
		ExpansionButton:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", db.Icons.Expansion.X, db.Icons.Expansion.Y)
		ExpansionButton:SetScale(db.Icons.Expansion.Scale)
	end

	IndicatorFrame:ClearAllPoints()
	IndicatorFrame:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", db.Icons.Notifications.X, db.Icons.Notifications.Y)
	IndicatorFrame:SetScale(db.Icons.Notifications.Scale)
end

local function SetupMinimapIconHooks()
	if not ExpansionButton or module.expansionButtonHooked then return end
	module.expansionButtonHooked = true

	hooksecurefunc(ExpansionButton, "SetLandingPageIconOffset", function()
		if module:IsEnabled() then module:PositionMinimapIcons() end
	end)
	ExpansionButton:HookScript("OnShow", function()
		if module:IsEnabled() then module:PositionMinimapIcons() end
	end)
end

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

local minimapFrames = {
	"MinimapCluster",          --Minimap Original Parent, contains ZoneText, MailFrame, Tracking, InstanceDifficulties
	"TimeManagerClockButton",  --Clock
	"GameTimeFrame",           --Calendar
	"MinimapCompassTexture"		-- Dragonflight Minimap Frame
}

function module:HideDefaultMinimap()
	-- Hide Several Frames surrounding minimap, after taking note of their state
	for _, frameName in ipairs(minimapFrames) do
		local frame = _G[frameName]
		if frame then
			oldDefault[frameName] = frame:IsShown()
			LUI:Kill(frame)
		end
	end

	--Change Minimap's Parent:
	oldDefault.scale = Minimap:GetScale()
	oldDefault.parent = Minimap:GetParent()
	oldDefault.mouseWheelEnabled = Minimap:IsMouseWheelEnabled()
	oldDefault.onMouseWheel = Minimap:GetScript("OnMouseWheel")
	oldDefault.onMouseUp = Minimap:GetScript("OnMouseUp")
	oldDefault.indicatorParent = IndicatorFrame:GetParent()
	oldDefault.indicatorPoints = CapturePoints(IndicatorFrame)
	oldDefault.indicatorScale = IndicatorFrame:GetScale()
	if ExpansionButton then
		oldDefault.expansionParent = ExpansionButton:GetParent()
		oldDefault.expansionPoints = CapturePoints(ExpansionButton)
		oldDefault.expansionScale = ExpansionButton:GetScale()
	end
	Minimap:SetParent(UIParent)

	-- Keep Blizzard's notification icons visible on LUI's minimap.
	IndicatorFrame:SetParent(Minimap)
	if ExpansionButton then ExpansionButton:SetParent(Minimap) end
	
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

function module:RestoreDefaultMinimap(ignoreCombat)
	if not ignoreCombat and InCombatLockdown() then
		QueueAfterCombat("restore")
		return
	end
	if not oldDefault.parent then return end

	-- Show several frames based on their previous state
	for _, frameName in ipairs(minimapFrames) do
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
	Minimap:SetScript("OnMouseWheel", oldDefault.onMouseWheel)
	Minimap:SetScript("OnMouseUp", oldDefault.onMouseUp)
	IndicatorFrame:SetParent(oldDefault.indicatorParent)
	RestorePoints(IndicatorFrame, oldDefault.indicatorPoints)
	IndicatorFrame:SetScale(oldDefault.indicatorScale or 1)
	if ExpansionButton and oldDefault.expansionParent then
		ExpansionButton:SetParent(oldDefault.expansionParent)
		RestorePoints(ExpansionButton, oldDefault.expansionPoints)
		ExpansionButton:SetScale(oldDefault.expansionScale or 1)
	end
	if trackingMenu then
		trackingMenu:Close()
		trackingMenu = nil
	end

	--Turn the Minimap back into a circle
	Minimap:EnableMouseWheel(oldDefault.mouseWheelEnabled == true)
	Minimap:SetMaskTexture(MINIMAP_ROUND_TEXTURE_MASK)
	minimapShape = "ROUND"
	if _G.GetMinimapShape == GetLuiMinimapShape then
		_G.GetMinimapShape = originalGetMinimapShape
	end

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

-- ####################################################################################################################
-- ##### Module Setup #################################################################################################
-- ####################################################################################################################

function module:SetMinimap(ignoreCombat)
	if not ignoreCombat and InCombatLockdown() then
		QueueAfterCombat("setup")
		return
	end
	db = module.db.profile
	if _G.GetMinimapShape ~= GetLuiMinimapShape then
		originalGetMinimapShape = _G.GetMinimapShape
	end
	_G.GetMinimapShape = GetLuiMinimapShape
	module:HideDefaultMinimap()
	module:SetMinimapScripts()
	SetupMinimapIconHooks()

	module:SetMinimapSize()
	module:SetMinimapPosition()

	--Make sure not to create the frames more than once.
	-- Set Zone Text
	local minimapZone = CreateFrame("Frame", "LUIMinimapZone", Minimap)
	minimapZone:SetSize(0, 20)
	minimapZone:SetPoint("TOPLEFT", Minimap, 2, -2)
	minimapZone:SetPoint("TOPRIGHT", Minimap, -2, -2)

	local minimapZoneText = module:SetFontString(minimapZone, "LUIMinimapZoneText", "Text", "Overlay", "CENTER", "MIDDLE")
	minimapZoneText:SetPoint("CENTER", 0, 0)
	minimapZoneText:SetHeight(db.Fonts.Text.Size)
	minimapZoneText:SetWidth(minimapZone:GetWidth()-6)

	local function UpdateZoneText()
		minimapZoneText:SetText(GetMinimapZoneText() or "")
	end
	minimapZone:RegisterEvent("PLAYER_ENTERING_WORLD")
	minimapZone:RegisterEvent("ZONE_CHANGED")
	minimapZone:RegisterEvent("ZONE_CHANGED_INDOORS")
	minimapZone:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	minimapZone:SetScript("OnEvent", UpdateZoneText)
	UpdateZoneText()

	module:PositionMinimapIcons()

	-- Set Coord Text
	local minimapCoord = CreateFrame("Frame", "LUIMinimapCoord", Minimap)
	minimapCoord:SetSize(40, 20)
	minimapCoord:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", -5, 5)

	local minimapCoordText = module:SetFontString(minimapCoord, "LUIMinimapCoordText", "Text", "Overlay", "RIGHT", "MIDDLE")
	minimapCoordText:SetPoint("RIGHT", -1, 0)
	minimapCoordText:SetText("00,00")

	local elapsedSinceUpdate = 0
	minimapCoord:SetScript("OnUpdate", function(self, elapsed)
		elapsedSinceUpdate = elapsedSinceUpdate + elapsed
		if elapsedSinceUpdate < 0.1 then return end
		elapsedSinceUpdate = 0

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

	--Create other frames around the minimap
	module:SetMinimapFrames()
	module:ToggleMinimapTextures()

	--Prevent these initialization functions from running again.
	function module:SetMinimap(ignoreCombat)
		if not ignoreCombat and InCombatLockdown() then
			QueueAfterCombat("setup")
			return
		end
		module:SetMinimapPosition()
		module:SetMinimapAgain()
	end
end

--If module is disabled and re-enabled, call this instead to prevent re-initializing everything
function module:SetMinimapAgain()
	module:HideDefaultMinimap()
	module:SetMinimapScripts()
	module:PositionMinimapIcons()
	module:ToggleMinimapText()
	module:ToggleMinimapTextures()

	-- SetParent aligns child strata with the parent, so restore the decorative background strata.
	LUIMinimapBorder:SetFrameStrata("BACKGROUND")
	for i = 1, 8 do
		_G["LUIMinimapTexture"..i]:SetFrameStrata("BACKGROUND")
	end
end

function module:ToggleTrackingMenu()
	if trackingMenu then
		trackingMenu:Close()
		return
	end

	TrackingButton:GenerateMenu()
	local menuDescription = TrackingButton:GetMenuDescription()
	if not menuDescription then return end

	trackingMenu = Menu.GetManager():OpenMenu(Minimap, menuDescription, trackingAnchor)
	if trackingMenu then
		TrackingButton.menu = trackingMenu
		TrackingButton:OnMenuOpened(trackingMenu)
		trackingMenu:SetClosedCallback(function(menu, closeReason)
			trackingMenu = nil
			TrackingButton.menu = nil
			TrackingButton:OnMenuClosed(menu, closeReason)
		end)
	end
end

function module:SetMinimapScripts()
	Minimap:EnableMouseWheel(true)
	Minimap:SetScript("OnMouseWheel", function(self, delta)
		if module:IsEnabled() then self:OnMouseWheel(delta) end
	end)
	Minimap:SetScript("OnMouseUp", function(self, button)
		if button == "RightButton" and module:IsEnabled() then
			module:ToggleTrackingMenu()
		else
			self:OnClick()
		end
	end)
end

--Set Frames surrounding the minimap.
function module:SetMinimapFrames()
	--Setting up values
	local borderEdgeSize = 5
	local borderBackdrop = {
		edgeFile=LUI.Media.glowTex,
		tile=false, edgeSize=borderEdgeSize,
		insets={left=0, right=0, top=0, bottom=0}
	}

	local r, g, b, a = module:RGBA("Minimap")
	local texOffX = { -7, 7, 7, -7, -10, 10, 10, -10 }
	local texOffY = { -7, -7, 7, 7, -10, -10, 10, 10 }
	local texPoint = { "BOTTOMLEFT", "BOTTOMRIGHT", "TOPRIGHT", "TOPLEFT" }

	--Create Border
	local minimapBorder = CreateFrame("Frame", "LUIMinimapBorder", Minimap)
	local borderSize = Minimap:GetSize() * (1 + borderEdgeSize/100)
	minimapBorder:SetSize(borderSize, borderSize)
	minimapBorder:SetFrameStrata("BACKGROUND")
	minimapBorder:SetPoint("CENTER", Minimap, "CENTER", 0, 0)
	LUI:ApplyFrameBackdrop(minimapBorder, borderBackdrop)
	LUI:SetFrameBorderColor(minimapBorder, 0, 0, 0, 1)

	--Create Corner Textures (Tex1-Tex4)
	local textureBackdrop = {
		edgeFile=LUI.Media.glowTex,
		tile=false, edgeSize=5,
		insets={left=3, right=3, top=3, bottom=3}
	}
	for i = 1, 4 do
		local minimapTex = CreateFrame("Frame", "LUIMinimapTexture"..i, Minimap)
		minimapTex:SetSize(50,50)
		minimapTex:SetFrameStrata("BACKGROUND")
		minimapTex:SetPoint(texPoint[i], Minimap, texPoint[i], texOffX[i], texOffY[i])
		LUI:ApplyFrameBackdrop(minimapTex, textureBackdrop)
		LUI:SetFrameBorderColor(minimapTex, r, g, b, a)
	end

	for i = 5, 8 do
		local minimapTex = CreateFrame("Frame", "LUIMinimapTexture"..i, Minimap)
		minimapTex:SetSize(56,56)
		minimapTex:SetFrameStrata("BACKGROUND")
		minimapTex:SetPoint(texPoint[i-4], Minimap, texPoint[i-4], texOffX[i], texOffY[i])
		minimapTex:SetFrameLevel(minimapTex:GetFrameLevel()-1)
		LUI:ApplyFrameBackdrop(minimapTex, textureBackdrop)
		LUI:SetFrameBorderColor(minimapTex, 0, 0, 0, 1)
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

function module:Refresh(ignoreCombat)
	if not ignoreCombat and InCombatLockdown() then
		QueueAfterCombat("refresh")
		return
	end
	if not _G.LUIMinimapZone then return end
	module:ToggleMinimapText()
	module:RefreshFontString(_G.LUIMinimapCoordText, "Text")
	module:RefreshFontString(_G.LUIMinimapZoneText, "Text")
	_G.LUIMinimapZoneText:SetHeight(db.Fonts.Text.Size)
	module:ToggleMinimapTextures()
	module:SetMinimapPosition()
	module:PositionMinimapIcons()
	module:RefreshColors()
end

function module:RefreshColors()
	if not _G.LUIMinimapTexture1 then return end
	local r, g, b, a = module:RGBA("Minimap")
	for i = 1, 4 do
		LUI:SetFrameBorderColor(_G["LUIMinimapTexture"..i], r, g, b, a)
	end
	for i = 5, 8 do
		LUI:SetFrameBorderColor(_G["LUIMinimapTexture"..i], r * 0.2, g * 0.2, b * 0.2, a)
	end
	LUI:SetFrameBorderColor(_G.LUIMinimapBorder, r * 0.1, g * 0.1, b * 0.1, a)
end
