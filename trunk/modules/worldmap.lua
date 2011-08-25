--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: worldmap.lua
	Description: Worldmap Module
]] 

-- External references.
local addonname, LUI = ...
local module = LUI:Module("WorldMap", "AceHook-3.0", "AceEvent-3.0")
local Media = LibStub("LibSharedMedia-3.0")
local LibWindow = LibStub("LibWindow-1.1")
local widgetLists = AceGUIWidgetLSMlists
local Fader = LUI:Module("Fader")

local LBZ = LibStub("LibBabble-Zone-3.0"):GetLookupTable()
local ZoneLoc = {names = {}, data = {}}

local L = LUI.L
local db, dbd

--------------------------------------------------
-- Local Variables
--------------------------------------------------

local questObjTexts = {
	[0] = L["Hide Completely"],
	[1] = L["Only Show Markers"],
	[2] = L["Show Markers & Panels"],
}

-- http://www.wowwiki.com/API_SetMapByID and GetMapNameByID(id)
local instanceMaps = {
	cities = {
		all = {
			-- Alliance
			["Stormwind City"] = 301,
			["Ironforge"] = 341,
			["Darnassus"] = 381,
			["The Exodar"] = 471,
			-- Horde
			["Orgrimmar"] = 321,
			["Thunder Bluff"] = 362,
			["Undercity"] = 382,
			["Silvermoon City"] = 480,
			-- Sanctuaries
			["Shattrath City"] = 481,
			["Dalaran"] = 504,
		},
	},
	instances = {
		classic = {
			-- 1.1.0
			["Ragefire Chasm"] = 680,
			["Zul'Farrak"] = 686,
			["The Temple of Atal'Hakkar"] = 687,
			["Blackfathom Deeps"] = 688,
			["The Stockade"] = 690,
			["Gnomeregan"] = 691,
			["Uldaman"] = 692,
			["Blackrock Depths"] = 704,
			["Blackrock Spire"] = 721,
			["Wailing Caverns"] = 749,
			["The Deadmines"] = 756,
			["Razorfen Downs"] = 760,
			["Razorfen Kraul"] = 761,
			["Scarlet Monastery"] = 762,
			["Scholomance"] = 763,
			["Shadowfang Keep"] = 764,
			["Stratholme"] = 765,
			-- 1.2.0
			["Maraudon"] = 750,
			-- 1.3.0
			["Dire Maul"] = 699,
		},
		bc = {
			-- 2.0.1
			["The Shattered Halls"] = 710,
			["Auchenai Crypts"] = 722,
			["Sethekk Halls"] = 723,
			["Shadow Labyrinth"] = 724,
			["The Blood Furnace"] = 725,
			["The Underbog"] = 726,
			["The Steamvault"] = 727,
			["The Slave Pens"] = 728,
			["The Botanica"] = 729,
			["The Mechanar"] = 730,
			["The Arcatraz"] = 731,
			["Mana-Tombs"] = 732,
			["The Black Morass"] = 733,
			["Old Hillsbrad Foothills"] = 734,
			["Hellfire Ramparts"] = 797,
			-- 2.4.0
			["Magisters' Terrace"] = 798,
		},
		wrath = {
			-- 3.0.2
			["The Nexus"] = 520,
			["The Culling of Stratholme"] = 521,
			["Ahn'kahet: The Old Kingdom"] = 522,
			["Utgarde Keep"] = 523,
			["Utgarde Pinnacle"] = 524,
			["Halls of Lightning"] = 525,
			["Halls of Stone"] = 526,
			["The Oculus"] = 528,
			["Gundrak"] = 530,
			["Azjol-Nerub"] = 533,
			["Drak'Tharon Keep"] = 534,
			["The Violet Hold"] = 536,
			-- 3.2.0
			["Trial of the Champion"] = 542,
			-- 3.3.0
			["The Forge of Souls"] = 601,
			["Pit of Saron"] = 602,
			["Halls of Reflection"] = 603,
		},
		cataclysm = {
			-- 4.0.3
			["Lost City of the Tol'vir"] = 747,
			["Blackrock Caverns"] = 753,
			["The Deadmines"] = 756,
			["Grim Batol"] = 757,
			["Halls of Origination"] = 759,
			["Shadowfang Keep"] = 764,
			["Throne of the Tides"] = 767,
			["The Stonecore"] = 768,
			["The Vortex Pinnacle"] = 769,
			-- 4.1.0
			["Zul'Aman"] = 781,
			["Zul'Gurub"] = 793,
		},
	},
	raids = {
		classic = {
			-- 1.1.0
			["Molten Core"] = 696,
			-- 1.6.0
			["Blackwing Lair"] = 755,
			-- 1.9.0
			["Ruins of Ahn'Qiraj"] = 717,
			["Ahn'Qiraj"] = 766,
		},
		bc = {
			-- 2.0.3
			["Hyjal Summit"] = 775,
			["Gruul's Lair"] = 776,
			["Magtheridon's Lair"] = 779,
			["Serpentshrine Cavern"] = 780,
			["Tempest Keep"] = 782,
			["Karazhan"] = 799,
			-- 2.1
			["Black Temple"] = 796,
			-- 2.4
			["Sunwell Plateau"] = 789,
		},
		wrath = {
			-- 3.0.2
			["The Eye of Eternity"] = 527,
			["The Obsidian Sanctum"] = 531,
			["Vault of Archavon"] = 532,
			["Naxxramas"] = 535,
			-- 3.1.0
			["Ulduar"] = 529,
			-- 3.2.0
			["Trial of the Crusader"] = 543,
			-- 3.2.2
			["Onyxia's Lair"] = 718,
			-- 3.3.0
			["Icecrown Citadel"] = 604,
			-- 3.3.5
			["The Ruby Sanctum"] = 609,
		},
		cataclysm = {
			-- 4.0.3
			["Baradin Hold"] = 752,
			["Blackwing Descent"] = 754,
			["The Bastion of Twilight"] = 758,
			["Throne of the Four Winds"] = 773,
			-- 4.2
			["Firelands"] = 800,
		},
	},
	bgs = {
		all = {
			-- 1.5.0
			["Alterac Valley"] = 401,
			["Warsong Gulch"] = 443,
			-- 1.7.0
			["Arathi Basin"] = 461,
			-- 2.0.1
			["Eye of the Storm"] = 482,
			-- 3.0.2
			["Strand of the Ancients"] = 512,
			-- 3.2.0
			["Isle of Conquest"] = 540,
			-- 4.0.3
			["Twin Peaks"] = 626,
			["The Battle for Gilneas"] = 736,
		},
	},
}

local defaultZoneCache = setmetatable({}, {__index = function(t, k)
	rawset(t, k, {GetMapZones(k)})
	return t[k]
end})

local WorldMapFrame = WorldMapFrame

local realZone
local zoomOverride

local coordstemplate = "%%s: %%.%df, %%.%df"
local coordsformat

local WORLDMAP_POI_MIN_X = 12
local WORLDMAP_POI_MIN_Y = -12
local WORLDMAP_POI_MAX_X     -- changes based on current scale, see WorldMapFrame_SetPOIMaxBounds
local WORLDMAP_POI_MAX_Y     -- changes based on current scale, see WorldMapFrame_SetPOIMaxBounds

local blobWasVisible, blobNewScale
local archBlobWasVisible, archBlobNewScale

--------------------------------------------------
-- Local Functions
--------------------------------------------------

local blobHideFunc = function() blobWasVisible = nil end
local blobShowFunc = function() blobWasVisible = true end
local blobScaleFunc = function(self, scale) blobNewScale = scale end
local archBlobHideFunc = function() archBlobWasVisible = nil end
local archBlobShowFunc = function() archBlobWasVisible = true end
local archBlobScaleFunc = function(self, scale) archBlobNewScale = scale end

local function mapSize()
	return (module.miniMap and "Mini" or "Big")
end

local function hasOverlays()
	return GetNumMapOverlays() > 0
end

local function getZoneId()
	return (GetCurrentMapZone() + GetCurrentMapContinent() * 100)
end

local function getMouse()
	local left, top = WorldMapDetailFrame:GetLeft(), WorldMapDetailFrame:GetTop()
	local width, height = WorldMapDetailFrame:GetWidth(), WorldMapDetailFrame:GetHeight()
	local scale = WorldMapDetailFrame:GetEffectiveScale()

	local x, y = GetCursorPosition()
	local cx = (x/scale - left) / width
	local cy = (top - y/scale) / height

	if cx < 0 or cx > 1 or cy < 0 or cy > 1 then
		return
	end

	return cx, cy
end

local function questObjDropDownUpdate()
	UIDropDownMenu_SetSelectedValue(LUIMapQuestObjectivesDropDown, db.QuestObjectives)
	UIDropDownMenu_SetText(LUIMapQuestObjectivesDropDown,questObjTexts[db.QuestObjectives])
end

local function questObjDropDownOnClick(button)
	UIDropDownMenu_SetSelectedValue(LUIMapQuestObjectivesDropDown, button.value)
	db.QuestObjectives = button.value
	module:RefreshQuestObjectivesDisplay()
end

local function questObjDropDownInit()
	local info = UIDropDownMenu_CreateInfo()
	local value = db.QuestObjectives

	for i=0, 2 do
		info.value = i
		info.text = questObjTexts[i]
		info.func = questObjDropDownOnClick
		if ( value == i ) then
			info.checked = 1
			UIDropDownMenu_SetText(LUIMapQuestObjectivesDropDown, info.text)
		else
			info.checked = nil
		end
		UIDropDownMenu_AddButton(info)
	end
end

local function getZoneData()
	return ZoneLoc.data[module.mapCont][module.mapZone]
end

local function continentButton_OnClick(frame)
	UIDropDownMenu_SetSelectedID(WorldMapContinentDropDown, frame:GetID())
	module.mapCont = frame.arg1
	module.mapContId = frame:GetID()
	zoomOverride = true
	SetMapZoom(-1)
	zoomOverride = nil
end

local function zoneButton_OnClick(frame)
	UIDropDownMenu_SetSelectedID(WorldMapZoneDropDown, frame:GetID())
	module.mapZone = frame:GetID()
	SetMapByID(getZoneData())
end

local function loadCustomZones(data)
	local info = UIDropDownMenu_CreateInfo()
	for i=1, #data do
		info.text = data[i]
		info.func = zoneButton_OnClick
		info.checked = nil
		UIDropDownMenu_AddButton(info)
	end
end

local function loadDefaultZones(data)
	local info = UIDropDownMenu_CreateInfo()
		for i=1, #data do
			info.text = data[i]
			info.func = WorldMapZoneButton_OnClick
			info.checked = nil
			UIDropDownMenu_AddButton(info)
		end
end

--------------------------------------------------
-- Hook Functions
--------------------------------------------------

local function questObjButtonOnClick(button)
	module.hooks[button].OnClick(button)
	db.QuestObjectives = button:GetChecked() and 2 or 0
	questObjDropDownUpdate()
end

function module:WorldMapFrame_DisplayQuestPOI(questFrame, isComplete)
	-- Recalculate Position to adjust for Scale
	local _, posX, posY = QuestPOIGetIconInfo(questFrame.questId)
	if posX and posY then
		local POIscale = WORLDMAP_SETTINGS.size
		posX = posX * WorldMapDetailFrame:GetWidth() * POIscale
		posY = -posY * WorldMapDetailFrame:GetHeight() * POIscale

		-- keep outlying POIs within map borders
		if ( posY > WORLDMAP_POI_MIN_Y ) then
			posY = WORLDMAP_POI_MIN_Y
		elseif ( posY < WORLDMAP_POI_MAX_Y ) then
			posY = WORLDMAP_POI_MAX_Y
		end
		if ( posX < WORLDMAP_POI_MIN_X ) then
			posX = WORLDMAP_POI_MIN_X
		elseif ( posX > WORLDMAP_POI_MAX_X ) then
			posX = WORLDMAP_POI_MAX_X
		end
		questFrame.poiIcon:SetPoint("CENTER", "WorldMapPOIFrame", "TOPLEFT", posX / db.General.POIScale, posY / db.General.POIScale)
		questFrame.poiIcon:SetScale(db.General.POIScale)
	end
end

function module:WorldMapFrame_DisplayQuests()
	if WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE then return end
	if db.QuestObjectives == 0 or not (WatchFrame.showObjectives and WorldMapFrame.numQuests > 0) then
		WorldMapArchaeologyDigSites:SetScale(WORLDMAP_FULLMAP_SIZE)
		WorldMapArchaeologyDigSites.xRatio = nil		-- force hit recalculations
	else
		if db.QuestObjectives == 1 then
			WorldMapFrame_SetFullMapView()
			
			WorldMapBlobFrame:SetScale(WORLDMAP_FULLMAP_SIZE)
			WorldMapBlobFrame.xRatio = nil		-- force hit recalculations
			WorldMapArchaeologyDigSites:SetScale(WORLDMAP_FULLMAP_SIZE)
			WorldMapArchaeologyDigSites.xRatio = nil		-- force hit recalculations
			WorldMapFrame_SetPOIMaxBounds()
			WorldMapFrame_UpdateQuests()
		elseif db.QuestObjectives == 2 then
			WorldMapFrame_SetQuestMapView()
			
			WorldMapBlobFrame:SetScale(WORLDMAP_QUESTLIST_SIZE)
			WorldMapBlobFrame.xRatio = nil		-- force hit recalculations
			WorldMapArchaeologyDigSites:SetScale(WORLDMAP_QUESTLIST_SIZE)
			WorldMapArchaeologyDigSites.xRatio = nil		-- force hit recalculations
			WorldMapFrame_SetPOIMaxBounds()
			WorldMapFrame_UpdateQuests()
		end
	end
end

function module:WorldMapFrame_SelectQuestFrame(...)
	local old_size = WORLDMAP_SETTINGS.size
	if db.QuestObjectives ~= 2 then
		WORLDMAP_SETTINGS.size = WORLDMAP_WINDOWED_SIZE
	end
	self.hooks.WorldMapFrame_SelectQuestFrame(...)
	WORLDMAP_SETTINGS.size = old_size
end

function module:WorldMapFrame_SetPOIMaxBounds()
	WORLDMAP_POI_MAX_Y = WorldMapDetailFrame:GetHeight() * -WORLDMAP_SETTINGS.size + 12;
	WORLDMAP_POI_MAX_X = WorldMapDetailFrame:GetWidth() * WORLDMAP_SETTINGS.size + 12;
end
	
function module:UpdateMapElements()
	local mouseOver = WorldMapFrame:IsMouseOver()
	if self.elementsHidden and (mouseOver or not db.Enable or not db[mapSize()].HideBorder) then
		self.elementsHidden = nil
		(self.miniMap and WorldMapFrameSizeUpButton or WorldMapFrameSizeDownButton):Show()
		WorldMapFrameCloseButton:Show()
		--WorldMapQuestShowObjectives:Show()
		for _, frame in pairs(self.elementsToHide) do
			frame:Show()
		end
	elseif not self.elementsHidden and not mouseOver and db.Enable and db[mapSize()].HideBorder then
		self.elementsHidden = true
		WorldMapFrameSizeUpButton:Hide()
		WorldMapFrameSizeDownButton:Hide()
		WorldMapFrameCloseButton:Hide()
		--WorldMapQuestShowObjectives:Hide()
		for _, frame in pairs(self.elementsToHide) do
			frame:Hide()
		end
	end
	-- process elements that show/hide themself
	if self.elementsHidden then
		WorldMapLevelDropDown:Hide()
	else
		local levels = GetNumDungeonMapLevels()
		if levels and levels > 0 then
			WorldMapLevelDropDown:Show()
		end
	end
end

function module:WorldMapContinentsDropDown_Update()
	if self.mapCont then
		UIDropDownMenu_SetSelectedID(WorldMapContinentDropDown, self.mapContId)
	end
end

function module:WorldMapFrame_LoadContinents()
	local info = UIDropDownMenu_CreateInfo()
	info.text =  L["Major Cities"]
	info.func = continentButton_OnClick
	info.checked = nil
	info.arg1 = "cities-all"
	UIDropDownMenu_AddButton(info)
	
	info.text =  L["Classic Instances"]
	info.func = continentButton_OnClick
	info.checked = nil
	info.arg1 = "instances-classic"
	UIDropDownMenu_AddButton(info)

	info.text =  L["Classic Raids"]
	info.func = continentButton_OnClick
	info.checked = nil
	info.arg1 = "raids-classic"
	UIDropDownMenu_AddButton(info)
	
	info.text =  L["BC Instances"]
	info.func = continentButton_OnClick
	info.checked = nil
	info.arg1 = "instances-bc"
	UIDropDownMenu_AddButton(info)

	info.text =  L["BC Raids"]
	info.func = continentButton_OnClick
	info.checked = nil
	info.arg1 = "raids-bc"
	UIDropDownMenu_AddButton(info)

	info.text =  L["Wrath Instances"]
	info.func = continentButton_OnClick
	info.checked = nil
	info.arg1 = "instances-wrath"
	UIDropDownMenu_AddButton(info)

	info.text =  L["Wrath Raids"]
	info.func = continentButton_OnClick
	info.checked = nil
	info.arg1 = "raids-wrath"
	UIDropDownMenu_AddButton(info)

	info.text =  L["Cataclysm Instances"]
	info.func = continentButton_OnClick
	info.checked = nil
	info.arg1 = "instances-cataclysm"
	UIDropDownMenu_AddButton(info)

	info.text =  L["Cataclysm Raids"]
	info.func = continentButton_OnClick
	info.checked = nil
	info.arg1 = "raids-cataclysm"
	UIDropDownMenu_AddButton(info)

	info.text =  L["Battlegrounds"]
	info.func = continentButton_OnClick
	info.checked = nil
	info.arg1 = "bgs-all"
	UIDropDownMenu_AddButton(info)
end

function module:WorldMapZoneDropDown_Update()
	if self.mapZone then
		UIDropDownMenu_SetSelectedID(WorldMapZoneDropDown, self.mapZone)
	end
end

function module:WorldMapZoneDropDown_Initialize()
	if self.mapCont then
		loadCustomZones(ZoneLoc.names[self.mapCont])
	else
		loadDefaultZones(defaultZoneCache[GetCurrentMapContinent()])
	end
end

function module:SetMapZoom()
	if not zoomOverride then
		self.mapCont, self.mapContId, self.mapZone = nil, nil, nil
	end
end

--------------------------------------------------
-- Script Functions
--------------------------------------------------

local function wmfOnShow(frame)
	module:SetStrata()
	module:SetScale()
	realZone = getZoneId()
	if BattlefieldMinimap and not module:IsHooked(BattlefieldMinimap, "OnUpdate") then
		module:RawHookScript(BattlefieldMinimap, "OnUpdate", LUI.dummy, true)
	end

	if WORLDMAP_SETTINGS.selectedQuest then
		WorldMapFrame_SelectQuestFrame(WORLDMAP_SETTINGS.selectedQuest)
	end
end

local function wmfOnHide(frame)
	SetMapToCurrentZone()
	if BattlefieldMinimap then
		module:Unhook(BattlefieldMinimap, "OnUpdate")
	end
end

local function wmsdsOnShow(frame)
	if db[mapSize()].HideBorder or not select(3, GetProfessions()) then 
		frame:Hide()
	end
end

local function coordsOnUpdate()
	local cx, cy = getMouse()
	local px, py = GetPlayerMapPosition("player")

	if cx then
		WorldMapFrame.coords.cursor:SetFormattedText(coordsformat, L["Cursor"], 100 * cx, 100 * cy)
	else
		WorldMapFrame.coords.cursor:SetText("")
	end

	if px == 0 then
		WorldMapFrame.coords.player:SetText("")
	else
		WorldMapFrame.coords.player:SetFormattedText(coordsformat, L["Player"], 100 * px, 100 * py)
	end
end

local function dropdownScaleFix(self)
	local point, parent, rpoint, x, y = DropDownList1:GetPoint()
	local uiScale = 1
	local uiParentScale = UIParent:GetScale()
	if GetCVar("useUIScale") == "1" then
		uiScale = tonumber(GetCVar("uiScale"))
		if uiParentScale < uiScale then
			uiScale = uiParentScale
		end
	else
		uiScale = uiParentScale
	end
	local scale = uiScale * db[mapSize()].scale
	DropDownList1:SetScale(scale)
	DropDownList1:SetPoint(point, parent, rpoint, x/scale, y/scale)
end

function module:ShowBlobs()
	WorldMapBlobFrame_CalculateHitTranslations()
	if WORLDMAP_SETTINGS.selectedQuest and not WORLDMAP_SETTINGS.selectedQuest.completed then
		WorldMapBlobFrame:DrawBlob(WORLDMAP_SETTINGS.selectedQuest.questId, true)
	end
end

function module:HideBlobs()
	if WORLDMAP_SETTINGS.selectedQuest then
		WorldMapBlobFrame:DrawBlob(WORLDMAP_SETTINGS.selectedQuest.questId, false)
	end
end

--------------------------------------------------
-- World Map Functions
--------------------------------------------------

function module:SetStrata()
	WorldMapFrame:SetFrameStrata(db.General.Strata)
end

function module:SetAlpha(alpha)
	WorldMapFrame:SetAlpha(alpha or db[mapSize()].Alpha)
end

function module:SetArrow(scale)
	PlayerArrowFrame:SetModelScale(scale or db.General.ArrowScale)
	PlayerArrowEffectFrame:SetModelScale(scale or db.General.ArrowScale)
end

function module:SetHoverScripts()
	if db.General.MouseHover then
		-- Create mouse hover scripts, include children recursively.
		Fader:CreateHoverScript(WorldMapFrame, db[mapSize()].Alpha, db[mapSize()].Alpha * 0.1, 0.5, nil, true)
	else
		-- Delete mouse hover scripts.
		Fader:DeleteHoverScript(WorldMapFrame, true)	
	end
end

function module:SetScale(scale)
	WorldMapFrame:SetFrameScale(scale or db[mapSize()].scale) -- LibWindow
end

function module:SetPosition()
	WorldMapFrame:RestorePosition() -- LibWindow
end

function module:SizeUp()
	WORLDMAP_SETTINGS.size = WORLDMAP_QUESTLIST_SIZE
	-- adjust main frame
	WorldMapFrame:SetWidth(1024)
	WorldMapFrame:SetHeight(768)
	-- adjust map frames
	WorldMapPositioningGuide:ClearAllPoints()
	WorldMapPositioningGuide:SetPoint("CENTER")
	WorldMapDetailFrame:SetScale(WORLDMAP_QUESTLIST_SIZE)
	WorldMapDetailFrame:SetPoint("TOPLEFT", WorldMapPositioningGuide, "TOP", -726, -99)
	WorldMapButton:SetScale(WORLDMAP_QUESTLIST_SIZE)
	WorldMapFrameAreaFrame:SetScale(WORLDMAP_QUESTLIST_SIZE)
	WorldMapBlobFrame:SetScale(WORLDMAP_QUESTLIST_SIZE)
	WorldMapBlobFrame.xRatio = nil		-- force hit recalculations
	WorldMapArchaeologyDigSites:SetScale(WORLDMAP_FULLMAP_SIZE)
	WorldMapArchaeologyDigSites.xRatio = nil		-- force hit recalculations
	WorldMapShowDigSites:SetPoint("LEFT", WorldMapTrackQuestText, "RIGHT", 25, 0)
	-- show big window elements
	WorldMapZoneMinimapDropDown:Show()
	WorldMapZoomOutButton:Show()
	WorldMapZoneDropDown:Show()
	WorldMapContinentDropDown:Show()
	WorldMapQuestScrollFrame:Show()
	WorldMapQuestDetailScrollFrame:Show()
	WorldMapQuestRewardScrollFrame:Show()
	WorldMapFrameSizeDownButton:Show()
	-- hide small window elements
	WorldMapFrameMiniBorderLeft:Hide()
	WorldMapFrameMiniBorderRight:Hide()
	WorldMapFrameSizeUpButton:Hide()
	-- floor dropdown
	WorldMapLevelDropDown:ClearAllPoints()
	WorldMapLevelDropDown:SetPoint("TOPRIGHT", WorldMapPositioningGuide, "TOPRIGHT", -50, -35)
	WorldMapLevelDropDown.header:Show()
	-- tiny adjustments
	WorldMapFrameCloseButton:SetPoint("TOPRIGHT", WorldMapPositioningGuide, 4, 4)
	WorldMapFrameSizeDownButton:SetPoint("TOPRIGHT", WorldMapPositioningGuide, -16, 4)
	WorldMapFrameTitle:ClearAllPoints()
	WorldMapFrameTitle:SetPoint("CENTER", 0, 372)

	WorldMapFrame_SetPOIMaxBounds()
	self:WorldMapFrame_DisplayQuests()
end

function module:SizeDown()
	WORLDMAP_SETTINGS.size = WORLDMAP_WINDOWED_SIZE
	-- adjust main frame
	WorldMapFrame:SetWidth(623)
	WorldMapFrame:SetHeight(437)
	-- adjust map frames
	WorldMapPositioningGuide:ClearAllPoints()
	WorldMapPositioningGuide:SetAllPoints()
	WorldMapDetailFrame:SetScale(WORLDMAP_WINDOWED_SIZE)
	WorldMapButton:SetScale(WORLDMAP_WINDOWED_SIZE)
	WorldMapFrameAreaFrame:SetScale(WORLDMAP_WINDOWED_SIZE)
	WorldMapBlobFrame:SetScale(WORLDMAP_WINDOWED_SIZE)
	WorldMapBlobFrame.xRatio = nil		-- force hit recalculations
	WorldMapArchaeologyDigSites:SetScale(WORLDMAP_WINDOWED_SIZE)
	WorldMapArchaeologyDigSites.xRatio = nil		-- force hit recalculations
	WorldMapFrameMiniBorderLeft:SetPoint("TOPLEFT", 10, -14)
	WorldMapDetailFrame:SetPoint("TOPLEFT", 37, -66)
	WorldMapShowDigSites:SetPoint("LEFT", WorldMapTrackQuestText, "RIGHT", 10, 0)
	-- hide big window elements
	WorldMapZoneMinimapDropDown:Hide()
	WorldMapZoomOutButton:Hide()
	WorldMapZoneDropDown:Hide()
	WorldMapContinentDropDown:Hide()
	WorldMapLevelDropDown:Hide()
	WorldMapLevelUpButton:Hide()
	WorldMapLevelDownButton:Hide()
	WorldMapQuestScrollFrame:Hide()
	WorldMapQuestDetailScrollFrame:Hide()
	WorldMapQuestRewardScrollFrame:Hide()
	WorldMapFrameSizeDownButton:Hide()
	-- show small window elements
	WorldMapFrameMiniBorderLeft:Show()
	WorldMapFrameMiniBorderRight:Show()
	WorldMapFrameSizeUpButton:Show()
	-- floor dropdown
	WorldMapLevelDropDown:ClearAllPoints()
	WorldMapLevelDropDown:SetPoint("TOPLEFT", WorldMapDetailFrame, "TOPLEFT", -19, 3)
	WorldMapLevelDropDown:SetFrameLevel(WORLDMAP_POI_FRAMELEVEL + 2)
	WorldMapLevelDropDown.header:Hide()
	-- tiny adjustments
	WorldMapFrameCloseButton:SetPoint("TOPRIGHT", WorldMapFrameMiniBorderRight, "TOPRIGHT", -44, 5)
	WorldMapFrameSizeDownButton:SetPoint("TOPRIGHT", WorldMapFrameMiniBorderRight, "TOPRIGHT", -66, 5)
	WorldMapFrameTitle:ClearAllPoints()
	WorldMapFrameTitle:SetPoint("TOP", WorldMapDetailFrame, 0, 20)

	WorldMapFrame_SetPOIMaxBounds()
end

function module:ToggleMapSize()
	self.miniMap = not self.miniMap
	db.miniMap = self.miniMap
	ToggleFrame(WorldMapFrame)
	self[self.miniMap and "SizeDown" or "SizeUp"](self)
	self:SetAlpha()
	self:SetPosition()

	self:UpdateBorderVisibility()
	
	self:SetCoords()

	ToggleFrame(WorldMapFrame)
	WorldMapFrame_UpdateQuests()
end

function module:UpdateBorderVisibility()
	if db.Enable and db[mapSize()].HideBorder then
		self.bordersVisible = false
		if self.miniMap then
			WorldMapFrameMiniBorderLeft:Hide()
			WorldMapFrameMiniBorderRight:Hide()
			WorldMapQuestShowObjectives:Hide()
		else
			-- TODO
		end
		WorldMapTrackQuest:SetParent(self.UIHider)
		WorldMapFrameTitle:Hide()
		self:RegisterEvent("WORLD_MAP_UPDATE")
		self:WORLD_MAP_UPDATE()
		if not self:IsHooked(WorldMapFrame, "OnUpdate") then
			self:HookScript(WorldMapFrame, "OnUpdate", "UpdateMapElements")
		end
		self:UpdateMapElements()
	else
		self.bordersVisible = true
		if self.miniMap then
			WorldMapFrameMiniBorderLeft:Show()
			WorldMapFrameMiniBorderRight:Show()
			WorldMapQuestShowObjectives:Show()
			WorldMapQuestShowObjectives_AdjustPosition()
			WorldMapTrackQuest:SetParent(WorldMapFrame)
			WorldMapTrackQuest:SetPoint("BOTTOMLEFT", WorldMapDetailFrame, "BOTTOMLEFT", 2, -26)
			LUIMapQuestObjectivesDropDown:Hide()
		else
			WorldMapQuestShowObjectives:Hide()
			WorldMapTrackQuest:SetPoint("BOTTOMLEFT", WorldMapPositioningGuide, "BOTTOMLEFT", 16, 4)
			LUIMapQuestObjectivesDropDown:Show()
		end
		WorldMapShowDigSites:Show()
		WorldMapFrameTitle:Show()
		self:UnregisterEvent("WORLD_MAP_UPDATE")
		self:WORLD_MAP_UPDATE()
		self:Unhook(WorldMapFrame, "OnUpdate")
		self:UpdateMapElements()
	end
end

function module:RefreshQuestObjectivesDisplay()
	WorldMapQuestShowObjectives:SetChecked(db.QuestObjectives ~= 0)
	self.hooks[WorldMapQuestShowObjectives].OnClick(WorldMapQuestShowObjectives)
end

function module:SetCoords()
	local coords = WorldMapFrame.coords
	if not coords then
		coords = CreateFrame("Frame", "LUIMapCoordsrame", WorldMapFrame)
		
		coords.cursor = coords:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		coords.player = coords:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		
		coords:SetScript("OnUpdate", coordsOnUpdate)
		
		WorldMapFrame.coords = coords
	end
	
	if self.miniMap then
		coords.cursor:SetPoint("BOTTOMLEFT", WorldMapPositioningGuide, "BOTTOM", 25, -2)
		coords.player:SetPoint("BOTTOMRIGHT", WorldMapPositioningGuide, "BOTTOM", 10, -2)
	else
		coords.cursor:SetPoint("BOTTOMLEFT", WorldMapPositioningGuide, "BOTTOM", 50, 10)
		coords.player:SetPoint("BOTTOMRIGHT", WorldMapPositioningGuide, "BOTTOM", -50, 10)
	end
	
	
	if db.General.CoordEnable and self.bordersVisible ~= false then
		coords:Show()
	else
		coords:Hide()
	end
end

function module:SetMap()
	local advanced, mini = GetCVarBool("advancedWorldMap"), GetCVarBool("miniWorldMap")
	SetCVar("miniWorldMap", nil)
	SetCVar("advancedWorldMap", nil)
	InterfaceOptionsObjectivesPanelAdvancedWorldMap:Disable()
	InterfaceOptionsObjectivesPanelAdvancedWorldMapText:SetTextColor(0.5,0.5,0.5)
	-- restore map to its vanilla state
	if mini then
		WorldMap_ToggleSizeUp()
	end
	if advanced then
		WorldMapFrame_ToggleAdvanced()
	end
	
	self.UIHider = self.UIHider or CreateFrame("Frame")
	self.UIHider:Hide()
	
	local vis = WorldMapFrame:IsVisible()
	if vis then
		HideUIPanel(WorldMapFrame)
	end
	
	SetUIPanelAttribute(WorldMapFrame, "area", "center")
	SetUIPanelAttribute(WorldMapFrame, "allowOtherPanels", true)
	
	WorldMapFrame:EnableMouse(true)
	WorldMapFrame:EnableKeyboard(false)
	
	self:SecureHookScript(WorldMapFrame, "OnShow", wmfOnShow)
	self:SecureHookScript(WorldMapFrame, "OnHide", wmfOnHide)
	BlackoutWorld:Hide()
	WorldMapTitleButton:Hide()

	-- Set mouse hover scripts.
	self:SetHoverScripts()

	WorldMapFrame:MakeDraggable() -- LibWindow
	self:SecureHookScript(WorldMapFrame, "OnDragStart", "HideBlobs")
	self:SecureHookScript(WorldMapFrame, "OnDragStop", "ShowBlobs")

	WorldMapFrame:SetParent(UIParent)
	--WorldMapFrame:SetToplevel(true)
	WorldMapFrame:SetWidth(1024)
	WorldMapFrame:SetHeight(768)
	WorldMapFrame:SetClampedToScreen(false)

	self:SecureHookScript(WorldMapContinentDropDownButton, "OnClick", dropdownScaleFix)
	self:SecureHookScript(WorldMapZoneDropDownButton, "OnClick", dropdownScaleFix)
	self:SecureHookScript(WorldMapZoneMinimapDropDownButton, "OnClick", dropdownScaleFix)

	self:RawHookScript(WorldMapFrameSizeDownButton, "OnClick", "ToggleMapSize", true)
	self:RawHookScript(WorldMapFrameSizeUpButton, "OnClick", "ToggleMapSize", true)
	self:RawHook("WorldMapFrame_ToggleWindowSize", "ToggleMapSize", true)

	-- Hide Quest Objectives CheckBox and replace it with a DropDown
	self:RawHookScript(WorldMapQuestShowObjectives, "OnClick", questObjButtonOnClick, true)
	WorldMapQuestShowObjectives:SetChecked(db.QuestObjectives ~= 0)
	WorldMapQuestShowObjectives_Toggle()
	WorldMapQuestShowObjectives:Hide()
	local questObj = LUIMapQuestObjectivesDropDown
	if not questObj then
		questObj = CreateFrame("Frame", "LUIMapQuestObjectivesDropDown", WorldMapFrame, "UIDropDownMenuTemplate")
		questObj:SetPoint("BOTTOMRIGHT", "WorldMapPositioningGuide", "BOTTOMRIGHT", -5, -2)
	end
	questObj:Show()
	
	WorldMapShowDigSites:ClearAllPoints()
	WorldMapShowDigSites:SetPoint("LEFT", WorldMapTrackQuestText, "RIGHT", 25, 0)
	self:SecureHookScript(WorldMapShowDigSites, "OnShow", wmsdsOnShow)

	local text = LUIMapQuestObjectivesDropDownLabel
	if not text then
		text = questObj:CreateFontString(questObj:GetName().."Label", "OVERLAY", "GameFontNormalSmall")
		text:SetText(L["Quest Objectives"])
		text:SetPoint("RIGHT", questObj, "LEFT", 5, 3)
		-- Init DropDown
		UIDropDownMenu_Initialize(questObj, questObjDropDownInit)
		UIDropDownMenu_SetWidth(questObj, 150)
	end
	questObjDropDownUpdate()

	realZone = getZoneId()
	self:SecureHook(WorldMapTooltip, "Show", function(self)
		self:SetFrameStrata("TOOLTIP")
	end)
	
	self.miniMap = db.miniMap
	if self.miniMap then
		self:SizeDown()
	end
	
	self:Refresh()

	self:SecureHook("WorldMapFrame_DisplayQuestPOI")
	self:SecureHook("WorldMapFrame_DisplayQuests")
	self:RawHook("WorldMapFrame_SelectQuestFrame", true)
	self:SecureHook("WorldMapFrame_SetPOIMaxBounds")
	self:SecureHook("WorldMapLevelDropDown_Update", "UpdateMapElements")
	WorldMapFrame_SetPOIMaxBounds()
	
	-- instance zones
	self:SecureHook("WorldMapContinentsDropDown_Update")
	self:SecureHook("WorldMapFrame_LoadContinents")
	self:SecureHook("WorldMapZoneDropDown_Update")
	self:RawHook("WorldMapZoneDropDown_Initialize", true)
	self:SecureHook("SetMapZoom")
	self:SecureHook("SetMapToCurrentZone", "SetMapZoom")

	if vis then
		ShowUIPanel(WorldMapFrame)
	end
end

--------------------------------------------------
-- Event Functions
--------------------------------------------------

function module:WORLD_MAP_UPDATE() -- updates detail tiles
	if db.Enable and db[mapSize()].HideBorder and GetCurrentMapZone() > 0 and hasOverlays() then
		for i=1, GetNumberOfDetailTiles() do
			_G["WorldMapDetailTile"..i]:Hide()
		end
	else
		for i=1, GetNumberOfDetailTiles() do
			_G["WorldMapDetailTile"..i]:Show()
		end
	end
end

function module:ZONE_CHANGED_NEW_AREA()
	local curZone = getZoneId()
	if realZone == curZone or ((curZone % 100) > 0 and (GetPlayerMapPosition("player")) ~= 0) then
		SetMapToCurrentZone()
		realZone = getZoneId()
	end
end

function module:PLAYER_REGEN_DISABLED()
	blobWasVisible = WorldMapBlobFrame:IsShown()
	blobNewScale = nil
	WorldMapBlobFrame:SetParent(nil)
	WorldMapBlobFrame:ClearAllPoints()
	-- dummy position, off screen, so calculations don't go boom
	WorldMapBlobFrame:SetPoint("TOP", UIParent, "BOTTOM")
	WorldMapBlobFrame:Hide()
	WorldMapBlobFrame.Hide = blobHideFunc
	WorldMapBlobFrame.Show = blobShowFunc
	WorldMapBlobFrame.SetScale = blobScaleFunc

	archBlobWasVisible = WorldMapArchaeologyDigSites:IsShown()
	archBlobNewScale = nil
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
		WorldMapBlobFrame.xRatio = nil
		blobNewScale = nil
	end

	WorldMapArchaeologyDigSites:SetParent(WorldMapFrame)
	WorldMapArchaeologyDigSites:ClearAllPoints()
	WorldMapArchaeologyDigSites:SetPoint("TOPLEFT", WorldMapDetailFrame)
	WorldMapArchaeologyDigSites.Hide = nil
	WorldMapArchaeologyDigSites.Show = nil
	WorldMapArchaeologyDigSites.SetScale = nil
	if archBlobWasVisible then
		WorldMapArchaeologyDigSites:Show()
	end
	if archBlobNewScale then
		WorldMapArchaeologyDigSites:SetScale(archBlobNewScale)
		WorldMapArchaeologyDigSites.xRatio = nil
		archBlobNewScale = nil
	end

	if WorldMapQuestScrollChildFrame.selected then
		WorldMapBlobFrame:DrawBlob(WorldMapQuestScrollChildFrame.selected.questId, false)
	end
end

--------------------------------------------------
-- Defaults
--------------------------------------------------

module.defaults = {
	profile = {
		Enable = true,
		miniMap = false,
		QuestObjectives = 2,
		General = {
			--Font = "Arial Narrow",
			--FontSize = 18,
			--FontFlag = "NONE",
			Strata = "HIGH",
			ArrowScale = 0.88,
			POIScale = 0.8,
			CoordEnable = true,
			CoordAccuracy = 1,
			MouseHover = false,
		},
		Big = {
			x = 0,
			y = 0,
			point = "CENTER",
			scale = 1,
			Alpha = 1,
			HideBorder = false,
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

--------------------------------------------------
-- Module Functions
--------------------------------------------------

module.conflicts = "Mapster"

module.optionsName = "World Map"
module.getter = "generic"
module.setter = "Refresh"

function module:LoadOptions()
	local function coordsDisabled()
		return not db.General.CoordEnable
	end
	
	local function createMapOptions(size, order)
		local mini = size == "Mini"
		local desc = mini and "minimized" or "big"
		
		local option = self:NewGroup(size.." World Map", order, {
			Alpha = self:NewSlider("Alpha", "The transparency of the "..desc.." map.", 1, 0, 1, 0.01, true, true),
			scale = self:NewSlider("Scale", "Scale of the "..desc.." map.", 2, 0.1, 2, 0.01, true, true),
			HideBorder = self:NewToggle("Hide Border", "hide the borders of the "..desc.." map", 3, true),
		})
		
		return option
	end
	
	local options = {
		General = self:NewGroup("General Settings", 1, {
			ArrowScale = self:NewSlider("PlayerArrow Scale", "Adjust the size of the Player Arrow on the Map for better visibility.", 1, 0.5, 2, 0.01, true, true),
			POIScale = self:NewSlider("POI Scale", "Scale of the POI Icons on the Map.", 2, 0.1, 2, 0.01, true, true),
			CoordEnable = self:NewToggle("Enable Coordinates", nil, 3, true, "normal"),
			CoordAccuracy = self:NewSlider("Coordinate Accuracy", "Adjust the number of decimal places the coordinates are accurate to.", 4, 0, 2, 1, true, false, nil, coordDisabled),
			MouseHover = self:NewToggle("Enable Fading", "Fade out the map when you move the mouse out of its frame.", 5, true, "normal"),
		}),
		Big = createMapOptions("Fullsize", 2),
		Mini = createMapOptions("Mini", 3),
	}
	
	options.Big.args.HideBorder.disabled = true
	
	return options
end

function module:Refresh(...)
	local info, value = ...
	if type(info) == "table" then -- set option function
		db[info[#info-1]][info[#info]] = value
	end
	
	if db.miniMap ~= self.miniMap then
		self:ToggleMapSize()
	end
	
	coordsformat = coordstemplate:format(db.General.CoordAccuracy, db.General.CoordAccuracy)
	
	self:SetCoords()
	
	self:SetStrata()
	self:SetAlpha()
	self:SetArrow()
	self:SetPosition()
	self:SetHoverScripts()
	
	self:UpdateBorderVisibility()
	WorldMapFrame_DisplayQuests()
end

function module:OnInitialize()
	db, dbd = LUI:NewNamespace(self, true)
	
	for zonetype, v in pairs(instanceMaps) do
		for expansion, v2 in pairs(v) do
			local data = {}
			local key = ("%s-%s"):format(zonetype, expansion)
			
			ZoneLoc.names[key], ZoneLoc.data[key] = {}, {}
			for name, id in pairs(v2) do
				tinsert(ZoneLoc.names[key], LBZ[name])
				data[LBZ[name]] = id
			end
			table.sort(ZoneLoc.names[key])
			for i, name in ipairs(ZoneLoc.names[key]) do
				ZoneLoc.data[key][i] = data[name]
			end
		end
	end
	
	self.elementsToHide = {}
end

function module:OnEnable()
	if not self.LibWindow then
		local db_ = setmetatable({}, {
			__index = function(t, k)
				return db[mapSize()][k]
			end,
			__newindex = function(t, k, v)
				if not db.Enable then return end
				db[mapSize()][k] = v
			end,
		})
		
		LibWindow:Embed(WorldMapFrame):RegisterConfig(db_) -- LibWindow
		self.LibWindow = true
	end
	
	self:SetMap()
	
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
end

function module:OnDisable()
	local vis = WorldMapFrame:IsVisible()
	if vis then
		HideUIPanel(WorldMapFrame)
	end
	
	self:UnregisterAllEvents()
	self:UnhookAll()
	
	self:SetMapZoom()
	WorldMapContinentsDropDown_Update()
	WorldMapZoneDropDown_Update()
	
	self:SecureHook("WorldMapFrame_DisplayQuestPOI", function(questFrame) questFrame.poiIcon:SetScale(1) end)
	WorldMapFrame_DisplayQuests()
	self:Unhook("WorldMapFrame_DisplayQuestPOI")
	
	WorldMapFrame.coords:Hide()
	
	self:UpdateMapElements()
	self:WORLD_MAP_UPDATE()
	self:SetArrow(1)
	self:SetScale(1)
	self:SetAlpha(1)
	
	if InCombatLockdown() then
		self:PLAYER_REGEN_ENABLED()
	end
	
	if self.miniMap then
		self:SizeUp()
	end
	
	WorldMapFrame:SetMovable(false)
	WorldMapFrame:RegisterForDrag(nil)
	WorldMapFrame:SetClampedToScreen(true)
	WorldMapFrame:SetClampRectInsets(0, 0, 0, -60)
	
	WorldMapQuestShowObjectives:Show()
	LUIMapQuestObjectivesDropDown:Hide()
	
	WorldMapShowDigSites:ClearAllPoints()
	WorldMapShowDigSites:GetScript("OnLoad")(WorldMapShowDigSites)
	
	InterfaceOptionsObjectivesPanelAdvancedWorldMap:Enable()
	
	if InCombatLockdown() then
		self:PLAYER_REGEN_ENABLED()
	end
	
	WorldMap_ToggleSizeUp()
	
	if self.miniMap then
		WorldMap_ToggleSizeDown()
		if vis then
			ShowUIPanel(WorldMapFrame)
		end
	end
end