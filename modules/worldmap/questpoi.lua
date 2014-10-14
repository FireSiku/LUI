--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: questpoi.lua
	Description: WorldMap Quest POI Module
]]

-- External references.
local addonname, LUI = ...
local WorldMap = LUI:Module("WorldMap")
local module = WorldMap:Module("QuestPOI", "AceHook-3.0")
local internalversion = select(2, GetBuildInfo())

local L = LUI.L
local db, dbd, char

--------------------------------------------------
-- Local Variables
--------------------------------------------------

local questObj

local questObjTexts = {
	[0] = L["Hide Completely"],
	[1] = L["Only Show Markers"],
	[2] = L["Show Markers & Panels"],
}

local worldObjTexts = {
	[0] = "Toggle Dig Sites",
	[1] = "Toggle Battle Pet Masters",
}

local WORLDMAP_POI_MIN_X = 12
local WORLDMAP_POI_MIN_Y = -12
local WORLDMAP_POI_MAX_X -- changes based on current scale, see WorldMapFrame_SetPOIMaxBounds
local WORLDMAP_POI_MAX_Y -- changes based on current scale, see WorldMapFrame_SetPOIMaxBounds

--------------------------------------------------
-- Local Functions
--------------------------------------------------

local function questObjDropDownUpdate()
	UIDropDownMenu_SetSelectedValue(questObj, char.QuestObjectives)
	UIDropDownMenu_SetText(questObj, questObjTexts[char.QuestObjectives])
end

local function questObjDropDownOnClick(button)
	char.QuestObjectives = button.value
	questObjDropDownUpdate()

	SetCVar("questPOI", button.value and "1" or "0")
	QuestMapFrame_UpdateAll();

	--WatchFrame_GetCurrentMapQuests()
	--WatchFrame_Update()
	--WorldMapFrame_DisplayQuests()
	WorldMapFrame_UpdateMap()
end

local function questObjDropDownInit()
	local info = UIDropDownMenu_CreateInfo()
	local value = char.QuestObjectives

	for i=0, 2 do
		info.value = i
		info.text = questObjTexts[i]
		info.func = questObjDropDownOnClick
		if ( value == i ) then
			info.checked = 1
			UIDropDownMenu_SetText(questObj, info.text)
		else
			info.checked = nil
		end
		UIDropDownMenu_AddButton(info)
	end
end

local function questObjVisibilityUpdate()
	if char.miniMap then
		questObj:Hide()
		if tonumber(internalversion) < 18716 then -- if true, it's live WoW and not the PTR
			-- do nothing for now
		end
	else
		questObj:Show()
		if tonumber(internalversion) < 18716 then -- if true, it's live WoW and not the PTR
			WorldMapShowDropDown:Hide()
			WorldMapTrackQuest:Hide()
		else
			-- do nothing for now
		end
	end
end

--------------------------------------------------
-- Hook Functions
--------------------------------------------------

local function WM_QuestShowObjectives_OnClick(self)
	char.QuestObjectives = self:GetChecked() and 2 or 0
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

function module:WorldMapFrame_DisplayQuests(selectQuestId)
	if WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE or not (WatchFrame.showObjectives and WorldMapFrame.numQuests > 0) then return end

	if char.QuestObjectives == 2 then
		WorldMapFrame_SetQuestMapView()

		WorldMapBlobFrame:SetScale(WORLDMAP_QUESTLIST_SIZE)
	else
		WorldMapFrame_SetFullMapView()

		WorldMapBlobFrame:SetScale(WORLDMAP_FULLMAP_SIZE)
	end

	WorldMapBlobFrame.xRatio = nil -- force hit recalculations

	WorldMapFrame_SetPOIMaxBounds()
	WorldMapFrame_UpdateQuests()
	-- try to select previously selected quest
	WorldMapFrame_SelectQuestById(selectQuestId or WORLDMAP_SETTINGS.selectedQuestId)
end

function module:WorldMapFrame_SelectQuestFrame(...)
	local old_size = WORLDMAP_SETTINGS.size
	if char.QuestObjectives ~= 2 then
		WORLDMAP_SETTINGS.size = WORLDMAP_WINDOWED_SIZE
	end

	self.hooks.WorldMapFrame_SelectQuestFrame(...)

	WORLDMAP_SETTINGS.size = old_size
end

function module:WorldMapFrame_SetPOIMaxBounds()
	WORLDMAP_POI_MAX_Y = WorldMapDetailFrame:GetHeight() * -WORLDMAP_SETTINGS.size + 12;
	WORLDMAP_POI_MAX_X = WorldMapDetailFrame:GetWidth() * WORLDMAP_SETTINGS.size + 12;
end

--------------------------------------------------
-- Module Functions
--------------------------------------------------

WorldMap.defaults.char.QuestObjectives = 2
WorldMap.defaults.profile.General.POIScale = 1

function module:Refresh()
	if tonumber(internalversion) < 16965 then -- if true, it's live WoW and not the PTR
		WorldMapQuestShowObjectives:SetChecked(char.QuestObjectives ~= 0)
		WorldMapQuestShowObjectives_Toggle()
	end
	--WorldMapFrame_DisplayQuests()

	if not questObj then return end
	questObjVisibilityUpdate()
end

function module:OnInitialize()
	db, dbd = LUI:Namespace(WorldMap)
	char = WorldMap.db.char
end

module.DBCallback = module.OnInitialize

function module:OnEnable()
	-- HideQuest Objectives CheckBox and replace it with a DropDown
	if tonumber(internalversion) < 18716 then -- if true, it's live WoW and not the PTR
	else
		-- do nothing for now
	end
	if not questObj then
		questObj = CreateFrame("Frame", "LUI_WorldMap_QuestObjectivesDropDown", WorldMapFrame, "UIDropDownMenuTemplate")
		questObj:SetPoint("BOTTOMRIGHT", WorldMapFrame.BorderFrame, "BOTTOMRIGHT", -5, -2)
		_G[questObj:GetName().."Button"]:HookScript("OnClick", WorldMap.DropdownScaleFix)

		local label = questObj:CreateFontString(questObj:GetName().."_Label", "OVERLAY", "GameFontNormalSmall")
		label:SetText(L["Quest Objectives"])
		label:SetPoint("RIGHT", questObj, "LEFT", 5, 3)

		-- Init DropDown
		UIDropDownMenu_Initialize(questObj, questObjDropDownInit)
		UIDropDownMenu_SetWidth(questObj, 150)
	end
	questObjDropDownUpdate()

	--self:SecureHook("WorldMapFrame_DisplayQuestPOI")
	--self:SecureHook("WorldMapFrame_DisplayQuests")
	--self:RawHook("WorldMapFrame_SelectQuestFrame", true)
	--self:SecureHook("WorldMapFrame_SetPOIMaxBounds")
	--WorldMapFrame_SetPOIMaxBounds()

	self:SecureHook("EncounterJournal_AddMapButtons", questObjVisibilityUpdate)

	self:Refresh()
end

function module:OnDisable()
	self:UnhookAll()
	self:UnhookAll()

	questObj:Hide()
end