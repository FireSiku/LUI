--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: worldmap.lua
	Description: WorldMap Module
]]

-- External references.
local addonname, LUI = ...
local module = LUI:Module("WorldMap", "AceHook-3.0", "AceEvent-3.0")
local FogClear = module:Module("FogClear")
local Coords = module:Module("Coords")
local Fader = LUI:Module("Fader")
local Media = LibStub("LibSharedMedia-3.0")
local internalversion = select(2, GetBuildInfo())

local LibWindow = LibStub("LibWindow-1.1")

local L = LUI.L
local db, dbd, char

--------------------------------------------------
-- Local Variables
--------------------------------------------------

local WorldMapFrame = _G.WorldMapFrame

local currentZone

local elementsHidden, elementHider
local elementsToHide = {
	WorldMapFrameCloseButton,
	WorldMapFrameSizeUpButton,
	WorldMapTrackQuest,
	WorldMapShowDigSites,
	WorldMapQuestShowObjectives,
}
module.elementsToHide = elementsToHide

--------------------------------------------------
-- Local Functions
--------------------------------------------------

local function hasOverlays()
	if FogClear:IsEnabled() then
		return FogClear:HasOverlays()
	else
		return GetNumMapOverlays() > 0
	end
end

local function setMapBorder(disabling)
	if char.miniMap and db.Mini.HideBorder and not disabling then
		WorldMapFrameTitle:Hide()
		WorldMapFrameMiniBorderLeft:Hide()
		WorldMapFrameMiniBorderRight:Hide()
		
		module:RegisterEvent("WORLD_MAP_UPDATE")
		module:WORLD_MAP_UPDATE()
		
		elementHider = elementHider or CreateFrame("Frame")
		elementHider:Hide()
		
		if not module:IsHooked(WorldMapFrame, "OnUpdate") then
			module:HookScript(WorldMapFrame, "OnUpdate", "UpdateMapElements")
		end
		module:UpdateMapElements()
	else
		WorldMapFrameTitle:Show()
		if char.miniMap then
			WorldMapFrameMiniBorderLeft:Show()
			WorldMapFrameMiniBorderRight:Show()
		end
		
		module:UnregisterEvent("WORLD_MAP_UPDATE")
		module:WORLD_MAP_UPDATE(disabling)
		
		module:Unhook(WorldMapFrame, "OnUpdate")
		module:UpdateMapElements(disabling)
	end
end

--------------------------------------------------
-- Hook Functions
--------------------------------------------------

local function onDragStart()
	if WORLDMAP_SETTINGS.selectedQuest then
		WorldMapBlobFrame:DrawBlob(WORLDMAP_SETTINGS.selectedQuest.questId, false)
	end
end

local function onDragStop()
	WorldMapBlobFrame_CalculateHitTranslations()
	if WORLDMAP_SETTINGS.selectedQuest and not WORLDMAP_SETTINGS.selectedQuest.completed then
		WorldMapBlobFrame:DrawBlob(WORLDMAP_SETTINGS.selectedQuest.questId, true)
	end
end

function module.DropdownScaleFix(self)
	DropDownList1:SetScale(self:GetEffectiveScale())
end

local function WM_Tooltip_OnShow(self)
	self:SetFrameStrata("TOOLTIP")
end

--------------------------------------------------
-- Event Functions
--------------------------------------------------

function module:ZONE_CHANGED_NEW_AREA() -- Set Map to current zone when changing zones if player isn't looking at another zone.
	if not WorldMapFrame:IsShown() then return end

	if currentZone == GetCurrentMapAreaID() or ((GetCurrentMapZone() > 0 and GetPlayerMapPosition("player")) ~= 0) then
		SetMapToCurrentZone()
		currentZone = GetCurrentMapAreaID()
	end
end

do -- PLAYER_REGEN_DISABLED, PLAYER_REGEN_ENABLED
	local blobWasVisible, blobNewScale
	local archBlobWasVisible, archBlobNewScale
	
	local blobHideFunc = function() blobWasVisible = nil end
	local blobShowFunc = function() blobWasVisible = true end
	local blobScaleFunc = function(self, scale) blobNewScale = scale end
	local archBlobHideFunc = function() archBlobWasVisible = nil end
	local archBlobShowFunc = function() archBlobWasVisible = true end
	local archBlobScaleFunc = function(self, scale) archBlobNewScale = scale end
	
	function module:PLAYER_REGEN_DISABLED()
		blobWasVisible = WorldMapBlobFrame:IsShown()
		WorldMapBlobFrame:SetParent(nil)
		WorldMapBlobFrame:ClearAllPoints()
		-- dummy position, off screen, so calculations don't go boom
		WorldMapBlobFrame:SetPoint("TOP", UIParent, "BOTTOM")
		WorldMapBlobFrame:Hide()
		WorldMapBlobFrame.Hide = blobHideFunc
		WorldMapBlobFrame.Show = blobShowFunc
		WorldMapBlobFrame.SetScale = blobScaleFunc
		
		archBlobWasVisible = WorldMapArchaeologyDigSites:IsShown()
		WorldMapArchaeologyDigSites:SetParent(nil)
		WorldMapArchaeologyDigSites:ClearAllPoints()
		-- dummy position, off screen, so calculations don't go boom
		WorldMapArchaeologyDigSites:SetPoint("TOP", UIParent, "BOTTOM")
		WorldMapArchaeologyDigSites:Hide()
		WorldMapArchaeologyDigSites.Hide = archBlobHideFunc
		WorldMapArchaeologyDigSites.Show = archBlobShowFunc
		WorldMapArchaeologyDigSites.SetScale = archBlobScaleFunc
	end
	
	function module:PLAYER_REGEN_ENABLED()
		WorldMapBlobFrame:SetParent(WorldMapFrame)
		WorldMapBlobFrame:ClearAllPoints()
		WorldMapBlobFrame:SetPoint("TOPLEFT", WorldMapDetailFrame)
		WorldMapBlobFrame.Hide = nil
		WorldMapBlobFrame.Show = nil
		WorldMapBlobFrame.SetScale = nil
		if blobWasVisible then
			WorldMapBlobFrame:Show()
			WorldMapBlobFrame_CalculateHitTranslations()
			if WorldMapQuestScrollChildFrame.selected and not WorldMapQuestScrollChildFrame.selected.completed then
				WorldMapBlobFrame:DrawBlob(WorldMapQuestScrollChildFrame.selected.questId, true)
			end
		end
		if blobNewScale then
			WorldMapBlobFrame:SetScale(blobNewScale)
			WorldMapBlobFrame.xRatio = nil -- force hit recalculations
			blobNewScale = nil
		end

		WorldMapArchaeologyDigSites:SetParent(WorldMapFrame)
		WorldMapArchaeologyDigSites:ClearAllPoints()
		WorldMapArchaeologyDigSites:SetPoint("TOPLEFT", WorldMapDetailFrame)
		WorldMapArchaeologyDigSites:SetPoint("BOTTOMRIGHT", WorldMapDetailFrame)
		WorldMapArchaeologyDigSites.Hide = nil
		WorldMapArchaeologyDigSites.Show = nil
		WorldMapArchaeologyDigSites.SetScale = nil
		if archBlobWasVisible then
			WorldMapArchaeologyDigSites:Show()
		end
		if archBlobNewScale then
			WorldMapArchaeologyDigSites:SetScale(archBlobNewScale)
			WorldMapArchaeologyDigSites.xRatio = nil -- force hit recalculations
			archBlobNewScale = nil
		end
		
		if WorldMapQuestScrollChildFrame.selected then
			WorldMapBlobFrame:DrawBlob(WorldMapQuestScrollChildFrame.selected.questId, false)
		end
	end
end

function module:WORLD_MAP_UPDATE(disabling) -- updates detail tiles
	if char.miniMap and db.Mini.HideBorder and GetCurrentMapZone() > 0 and hasOverlays() and disabling ~= true then
		for i=1, GetNumberOfDetailTiles() do
			_G["WorldMapDetailTile"..i]:Hide()
		end
	else
		for i=1, GetNumberOfDetailTiles() do
			_G["WorldMapDetailTile"..i]:Show()
		end
	end
end

--------------------------------------------------
-- World Map Functions
--------------------------------------------------

function module:GetMapSize()
	return (char.miniMap and "Mini" or "Big")
end

function module:UpdateMapElements(disabling)
	local mouseOver = disabling == true or not char.miniMap or WorldMapFrame:IsMouseOver()
	if elementsHidden and (mouseOver or not db.Mini.HideBorder) then
		elementsHidden = nil
		
		for _, frame in pairs(elementsToHide) do
			frame:SetParent(WorldMapFrame)
		end
	elseif not elementsHidden and not mouseOver and db.Mini.HideBorder then
		elementsHidden = true
		
		for _, frame in pairs(elementsToHide) do
			frame:SetParent(elementHider)
		end
	end
end

local function WM_OnShow(frame)
	frame:SetFrameStrata(db.General.Strata)

	LibWindow.RestorePosition(WorldMapFrame)

	currentZone = GetCurrentMapAreaID()
end

local function WM_ToggleSizeUp()
	-- adjust main frame
	WorldMapFrame:SetParent(UIParent)
	WorldMapFrame:SetWidth(1024)
	WorldMapFrame:SetHeight(768)
	SetUIPanelAttribute(WorldMapFrame, "allowOtherPanels", true)
	WorldMapFrame:EnableKeyboard(false)
	-- adjust map frames
	WorldMapShowDigSites:ClearAllPoints()
	WorldMapShowDigSites:SetPoint("LEFT", WorldMapTrackQuestText, "RIGHT", 50, 0)
	BlackoutWorld:Hide()
	-- floor dropdown
	WorldMapLevelDropDown:ClearAllPoints()
	WorldMapLevelDropDown:SetPoint("TOPRIGHT", WorldMapPositioningGuide, "TOPRIGHT", -50, -35)

	char.miniMap = false
	module:Refresh()
end

local function WM_ToggleSizeDown()
	-- adjust main frame
	WorldMapFrame:SetWidth(623)
	WorldMapFrame:SetHeight(437)
	WorldMapFrame:SetMovable(true)
	WorldMapFrame:EnableMouse(true)
	-- adjust map frames
	WorldMapShowDigSites:ClearAllPoints()
	WorldMapShowDigSites:SetPoint("LEFT", WorldMapTrackQuestText, "RIGHT", 25, 0)
	-- hide big window elements
	WorldMapTitleButton:Hide()
	-- floor dropdown
	WorldMapLevelDropDown:ClearAllPoints()
	WorldMapLevelDropDown:SetPoint("TOPLEFT", WorldMapDetailFrame, "TOPLEFT", -19, 3)

	char.miniMap = true
	module:Refresh()
end

local SetSpecialFrameProperties
do
	local panelRemoved, specialFrame = false, false
	
	SetSpecialFrameProperties = function(disabling)
		if db.General.KeepBehavior or disabling then
			if panelRemoved or disabling then
				HideUIPanel(WorldMapFrame)
				UISpecialFrames.LUI_WorldMap = nil
				UIPanelWindows.WorldMapFrame = {area = "full", pushable = 0, xoffset = -16, yoffset = 12, whileDead = 1}
				module:UnregisterEvent("PLAYER_REGEN_DISABLED")
				module:UnregisterEvent("PLAYER_REGEN_ENABLED")
				if InCombatLockdown() then
					module:PLAYER_REGEN_ENABLED()
				end
				panelRemoved = false
				specialFrame = false
			end
			SetUIPanelAttribute(WorldMapFrame, "area", disabling and "left" or "center")
		else
			if not panelRemoved then
				HideUIPanel(WorldMapFrame)
				SetUIPanelAttribute(WorldMapFrame, "area", nil)
				SetUIPanelAttribute(WorldMapFrame, "defined", nil)
				UIPanelWindows["WorldMapFrame"] = nil
				module:RegisterEvent("PLAYER_REGEN_DISABLED")
				module:RegisterEvent("PLAYER_REGEN_ENABLED")
				panelRemoved = true
			end
			
			if db.General.CloseOnEsc then
				if not specialFrame then
					HideUIPanel(WorldMapFrame)
					UISpecialFrames.LUI_WorldMap = "WorldMapFrame"
					specialFrame = true
				end
			elseif specialFrame then
				HideUIPanel(WorldMapFrame)
				UISpecialFrames.LUI_WorldMap = nil
				specialFrame = false
			end
		end
	end
end

function module:SetMap()
	WorldMap_ToggleSizeUp()

	local visible = WorldMapFrame:IsVisible()
	if visible then
		HideUIPanel(WorldMapFrame)
	end
	
	self:SecureHookScript(WorldMapFrame, "OnShow", WM_OnShow)
	self:SecureHook("WorldMap_ToggleSizeUp", WM_ToggleSizeUp)
	self:SecureHook("WorldMap_ToggleSizeDown", WM_ToggleSizeDown)
	
	self:SecureHookScript(WorldMapContinentDropDownButton, "OnClick", self.DropdownScaleFix)
	self:SecureHookScript(WorldMapZoneDropDownButton, "OnClick", self.DropdownScaleFix)
	self:SecureHookScript(WorldMapZoneMinimapDropDownButton, "OnClick", self.DropdownScaleFix)
	self:SecureHookScript(WorldMapLevelDropDownButton, "OnClick", self.DropdownScaleFix)
	
	LibWindow.MakeDraggable(WorldMapFrame)
	WorldMapFrame:SetClampedToScreen(false)
	self:SecureHookScript(WorldMapFrame, "OnDragStart", onDragStart)
	self:SecureHookScript(WorldMapFrame, "OnDragStop", onDragStop)
	
	self:SecureHookScript(WorldMapTooltip, "OnShow", WM_Tooltip_OnShow)
	
	if char.miniMap then
		WorldMap_ToggleSizeDown()
	else
		WM_ToggleSizeUp()
	end
	
	if visible then
		ShowUIPanel(WorldMapFrame)
	end
end

--------------------------------------------------
-- Module Functions
--------------------------------------------------

module.defaults = {
	char = {
		miniMap = false,
	},
	profile = {
		General = {
			--Font = "Arial Narrow",
			--FontSize = 18,
			--FontFlag = "NONE",
			Strata = "HIGH",
			ArrowScale = 1,
			KeepBehavior = false,
			CloseOnEsc = true,
			UpdateZone = true,
			MouseHover = false,
		},
		Big = {
			x = 0,
			y = 0,
			point = "CENTER",
			scale = 1,
			Alpha = 1,
		},
		Mini = {
			x = 0,
			y = 0,
			point = "CENTER",
			scale = 1,
			Alpha = 0.9,
			HideBorder = false,
		}
	},
}

module.conflicts = "Mapster"

module.optionsName = "World Map"
module.getter = "generic"
module.setter = "Refresh"

function module:LoadOptions()
	local function behaviorKept()
		return db.General.KeepBehavior
	end
	
	local function createMapOptions(size, order)
		local mini = size == "Mini"
		local desc = mini and "minimized" or "big"
		
		local option = self:NewGroup(size.." World Map", order, {
			Alpha = self:NewSlider("Alpha", "The transparency of the "..desc.." map.", 1, 0, 1, 0.01, true, true),
			scale = self:NewSlider("Scale", "Scale of the "..desc.." map.", 2, 0.1, 2, 0.01, true, true),
			HideBorder = mini and self:NewToggle("Hide Border", "hide the borders of the "..desc.." map", 3, true) or nil,
		})
		
		return option
	end
	
	local options = {
		General = self:NewGroup("General Settings", 1, {
			ArrowScale = self:NewSlider("PlayerArrow Scale", "Adjust the size of the Player Arrow on the Map for better visibility.", 1, 0.5, 2, 0.01, true, true),
			POIScale = self:NewSlider("POI Scale", "Scale of the POI Icons on the Map.", 2, 0.1, 2, 0.01, true, true),
			KeepBehavior = self:NewToggle("Keep Panel Behavior", "Whether or not to maintain Blizzard's panel behavior:\nHide when other panels are shown\nClose on Esc", 5, true, "normal"),
			CloseOnEsc = self:NewToggle("Close on Esc", "Whether or not the World Map should close when pressing the Esc key.", 6, true, "normal", behaviorKept),
			UpdateZone = self:NewToggle("Auto Change Zone", "Whether or not the zone should automaticaly be changed when you move into that zone.\nNote: This will only take effect if you are veiwing the zone you just left.", 7, true, "normal"),
			MouseHover = self:NewToggle("Enable Fading", "Fade out the map when you move the mouse out of its frame.", 8, true, "normal"),
		}),
		Big = createMapOptions("Fullsize", 2),
		Mini = createMapOptions("Mini", 3),
		Coords = Coords:LoadOptions(),
		FogClear = FogClear:LoadOptions(),
	}
	
	return options
end

function module:Refresh(info, value)
	if type(info) == "table" then
		self:SetDBVar(info, value)
	end
	
	if db.General.UpdateZone then
		self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	else
		self:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
	end
	
	if tonumber(internalversion) < 16547 then -- if true, it's live WoW and not the PTR
		PlayerArrowFrame:SetModelScale(db.General.ArrowScale)
		PlayerArrowEffectFrame:SetModelScale(db.General.ArrowScale)
--	else
--		WorldMapPlayerLower:SetModelScale(db.General.ArrowScale)
--		WorldMapPlayerUpper:SetModelScale(db.General.ArrowScale)
	end
	
	LibWindow.RestorePosition(WorldMapFrame)
	
	setMapBorder()
	
	SetSpecialFrameProperties()
	
	-- set mouse hover scripts
	if db.General.MouseHover then
		Fader:CreateHoverScript(WorldMapFrame, db[self:GetMapSize()].Alpha, db[self:GetMapSize()].Alpha * 0.1, 0.5, nil, true)
	else
		Fader:DeleteHoverScript(WorldMapFrame, true)
		WorldMapFrame:SetAlpha(db[self:GetMapSize()].Alpha)
	end
	
	for name, module in self:IterateModules() do
		if module.Refresh and module:IsEnabled() then
			module:Refresh()
		end
	end
end

function module:DBCallback(event, dbobj, profile)
	db, dbd = LUI:Namespace(self)

	for name, module in self:IterateModules() do
		if module.DBCallback then
			module:DBCallback()
		end

		if db.modules[name] ~= nil and db.modules[name] ~= module:IsEnabled() then
			module:Toggle()
		end
	end

	if self:IsEnabled() then
		self:Refresh()
	end
end

function module:OnInitialize()
	db, dbd = LUI:Namespace(self, true)
	char = self.db.char

	local disabled = not self.enabledState
	for name, module in self:IterateModules() do
		---[[	PROFILER
		-- Add WorldMap module functions to the profiler.
		LUI.Profiler.TraceScope(module, name, "LUI.WorldMap")
		--]]
		
		if disabled then
			module:SetEnabledState(false)
		elseif db[name] then
			module:SetEnabledState(db[name].Enable)
		end
	end
	
	local db_ = setmetatable({}, {
		__index = function(t, k)
			return db[self:GetMapSize()][k]
		end,
		__newindex = function(t, k, v)
			if not self:IsEnabled() then return end
			db[self:GetMapSize()][k] = v
		end,
	})
	
	LibWindow.RegisterConfig(WorldMapFrame, db_)
end

function module:OnEnable()
	self:SetMap()
	
	for name, module in self:IterateModules() do
		if db.modules[name] ~= false then
			module:Enable()
		end
	end
end

function module:OnDisable()
	local visible = WorldMapFrame:IsVisible()
	if visible then
		HideUIPanel(WorldMapFrame)
	end

	self:UnregisterAllEvents()
	self:UnhookAll()
	
	WorldMapFrame:SetMovable(false)
	WorldMapFrame:RegisterForDrag(nil)
	WorldMapFrame:SetClampedToScreen(true)
	WorldMapFrame:SetClampRectInsets(0, 0, 0, -60)
	
	PlayerArrowFrame:SetModelScale(1)
	PlayerArrowEffectFrame:SetModelScale(1)
	WorldMapFrame:SetScale(1)
	WorldMapFrame:SetAlpha(1)
	
	setMapBorder(true)
	
	SetSpecialFrameProperties(true)
	
	WorldMap_ToggleSizeUp()
	
	WorldMapShowDigSites:ClearAllPoints()
	WorldMapShowDigSites:GetScript("OnLoad")(WorldMapShowDigSites)
	
	if char.miniMap then
		WorldMap_ToggleSizeDown()
		if visible then
			ShowUIPanel(WorldMapFrame)
		end
	end
end

---[[	PROFILER
-- Add WorldMap module functions to the profiler.
LUI.Profiler.TraceScope(module, "WorldMap", "LUI")
--]]