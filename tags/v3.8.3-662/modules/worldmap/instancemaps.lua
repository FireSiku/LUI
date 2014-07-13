--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: instancemaps.lua
	Description: WorldMap Instance Maps Module
]]

-- External references.
local addonname, LUI = ...
local WorldMap = LUI:Module("WorldMap")
local module = WorldMap:Module("InstanceMaps", "AceHook-3.0")
local internalversion = select(2, GetBuildInfo())

local L = LUI.L

--------------------------------------------------
-- Local Variables
--------------------------------------------------

local zoomOverride

local continent, continentId, zoneId

local continents = {
	names = {
		L["Classic Instances"],
		L["Classic Raids"],
		L["BC Instances"],
		L["BC Raids"],
		L["Wrath Instances"],
		L["Wrath Raids"],
		L["Cataclysm Instances"],
		L["Cataclysm Raids"],
		L["Pandaria Instances"],
		L["Pandaria Raids"],
--		"Pandaria Scenarios",
		L["Battlegrounds"],
	},
	tags = {
		"instances-classic",
		"raids-classic",
		"instances-bc",
		"raids-bc",
		"instances-wrath",
		"raids-wrath",
		"instances-cataclysm",
		"raids-cataclysm",
		"instances-pandaria",
		"raids-pandaria",
--		"scenarios-pandaria",
		"bgs-all",
	},
}

local zoneList = {names = {}, data = {}}
do
	-- http://www.wowwiki.com/API_SetMapByID and GetMapNameByID(id)
	local instanceMaps = {
		instances = {
			classic = {
				["Ragefire Chasm"] = 680,
				["Zul'Farrak"] = 686,
				["The Temple of Atal'Hakkar"] = 687,
				["Blackfathom Deeps"] = 688,
				["The Stockade"] = 690,
				["Gnomeregan"] = 691,
				["Uldaman"] = 692,
				["Dire Maul"] = 699,
				["Blackrock Depths"] = 704,
				["Blackrock Spire"] = 721,
				["Wailing Caverns"] = 749,
				["Maraudon"] = 750,
				["The Deadmines"] = 756,
				["Razorfen Downs"] = 760,
				["Razorfen Kraul"] = 761,
				["Scarlet Halls"] = 871,
				["Scarlet Monastery"] = 874,
				["Scholomance"] = 898,
				["Shadowfang Keep"] = 764,
				["Stratholme"] = 765,
			},
			bc = {
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
				["Magisters' Terrace"] = 798,
			},
			wrath = {
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
				["Trial of the Champion"] = 542,
				["The Forge of Souls"] = 601,
				["Pit of Saron"] = 602,
				["Halls of Reflection"] = 603,
			},
			cataclysm = {
				["Lost City of the Tol'vir"] = 747,
				["Blackrock Caverns"] = 753,
				["The Deadmines"] = 756,
				["Grim Batol"] = 757,
				["Halls of Origination"] = 759,
				["Shadowfang Keep"] = 764,
				["Throne of the Tides"] = 767,
				["The Stonecore"] = 768,
				["The Vortex Pinnacle"] = 769,
				["Zul'Aman"] = 781,
				["Zul'Gurub"] = 793,
				["Well of Eternity"] = 816,
				["Hour of Twilight"] = 819,
				["End Time"] = 820,
			},
			pandaria = {
				["Temple of the Jade Serpent"] = 867,
				["Stormstout Brewery"] = 876,
				["Mogu'Shan Palace"] = 885,
				["Shado-pan Monastery"] = 877,
				["Gate of the Setting Sun"] = 875,
				["Siege of Niuzao Temple"] = 887,
				["Scarlet Halls"] = 871,
				["Scarlet Monastery"] = 874,
				["Scholomance"] = 898,
			},
		},
		raids = {
			classic = {
				["Molten Core"] = 696,
				["Blackwing Lair"] = 755,
				["Ruins of Ahn'Qiraj"] = 717,
				["Ahn'Qiraj"] = 766,
			},
			bc = {
				["Hyjal Summit"] = 775,
				["Gruul's Lair"] = 776,
				["Magtheridon's Lair"] = 779,
				["Serpentshrine Cavern"] = 780,
				["The Eye"] = 782,
				["Sunwell Plateau"] = 789,
				["Black Temple"] = 796,
				["Karazhan"] = 799,
			},
			wrath = {
				["The Eye of Eternity"] = 527,
				["Ulduar"] = 529,
				["The Obsidian Sanctum"] = 531,
				["Vault of Archavon"] = 532,
				["Naxxramas"] = 535,
				["Trial of the Crusader"] = 543,
				["Icecrown Citadel"] = 604,
				["The Ruby Sanctum"] = 609,
				["Onyxia's Lair"] = 718,
			},
			cataclysm = {
				["Baradin Hold"] = 752,
				["Blackwing Descent"] = 754,
				["The Bastion of Twilight"] = 758,
				["Throne of the Four Winds"] = 773,
				["Firelands"] = 800,
				["Dragon Soul"] = 824,
			},
			pandaria = {
				["Terrace of Endless Spring"] = 886,
				["Mogu'shan Vaults"] = 896,
				["Heart of Fear"] = 897,
				["Throne of Thunder"] = 930,
			}
		},
--[[		scenarios = {
			pandaria = {
				["A Brewing Storm"] = 878,
				["A Little Patience"] = 912,
				["Arena of Annihilation"] = 899,
				["Assault on Zan'vess"] = 883,
				["Battle on the High Seas"] = 940,
				["Blood in the Snow"] = 939,
				["Brewmoon Festival"] = 884,
				["Crypt of Forgotten Kings"] = 900,
				["Dagger in the Dark"] = 914,
				["Dark Heart of Pandaria"] = 937,
				["Domination Point (H)"] = 920,
				["Greenstone Village"] = 880,
				["Lion's Landing (A)"] = 911,
				["The Secrets of Ragefire"] = 938,
				["Theramore's Fall (A)"] = 906,
				["Theramore's Fall (H)"] = 851,
				["Unga Ingoo"] = 882,
			},
		},]]--
		bgs = {
			all = {
				["Alterac Valley"] = 401,
				["Warsong Gulch"] = 443,
				["Arathi Basin"] = 461,
				["Eye of the Storm"] = 482,
				["Strand of the Ancients"] = 512,
				["Isle of Conquest"] = 540,
				["Twin Peaks"] = 626,
				["The Battle for Gilneas"] = 736,
				["Temple of Kotmogu"] = 856,
				["Silvershard Mines"] = 860,
			},
		},
	}
	
	for zoneType, expansions in pairs(instanceMaps) do
		for expansion, zones in pairs(expansions) do
			local data = {}
			local key = ("%s-%s"):format(zoneType, expansion)
			
			zoneList.names[key], zoneList.data[key] = {}, {}
			for name, id in pairs(zones) do
				--tinsert(zoneList.names[key], LBZ[name])
				--data[LBZ[name]] = id
				tinsert(zoneList.names[key], GetMapNameByID(id))
				data[GetMapNameByID(id)] = id
			end
			table.sort(zoneList.names[key])
			for i, name in ipairs(zoneList.names[key]) do
				zoneList.data[key][i] = data[name]
			end
		end
	end
end

--------------------------------------------------
-- Local Functions
--------------------------------------------------

local function continentButton_OnClick(frame)
	UIDropDownMenu_SetSelectedID(WorldMapContinentDropDown, frame:GetID())
	continent = frame.arg1
	continentId = frame:GetID()
	
	zoomOverride = true
	SetMapZoom(-1)
end

local function zoneButton_OnClick(frame)
	UIDropDownMenu_SetSelectedID(WorldMapZoneDropDown, frame:GetID())
	zoneId = frame:GetID()
	SetMapByID(zoneList.data[continent][zoneId])
end

local function loadZones()
	local info = UIDropDownMenu_CreateInfo()
	for i, zone in ipairs(zoneList.names[continent]) do
		info.text = zone
		info.func = zoneButton_OnClick
		info.checked = nil
		UIDropDownMenu_AddButton(info)
	end
end

--------------------------------------------------
-- Hook Functions
--------------------------------------------------

function module:WorldMapFrame_LoadContinents()
	local info = UIDropDownMenu_CreateInfo()
	for i, tag in ipairs(continents.tags) do
		info.text = continents.names[i]
		info.func = continentButton_OnClick
		info.checked = nil
		info.arg1 = tag
		UIDropDownMenu_AddButton(info)
	end
end

function module:WorldMapContinentsDropDown_Update()
	if continent then
		UIDropDownMenu_SetSelectedID(WorldMapContinentDropDown, continentId)
	end
end

function module:WorldMapZoneDropDown_Initialize()
	if continent then
		UIDropDownMenu_Initialize(WorldMapZoneDropDown, loadZones)
	else
		self.hooks.WorldMapZoneDropDown_Initialize()
	end
end

function module:WorldMapZoneDropDown_Update()
	if zoneId then
		UIDropDownMenu_SetSelectedID(WorldMapZoneDropDown, zoneId)
	end
end

function module:SetMapZoom()
	if zoomOverride then
		zoomOverride = nil
		return
	end
	
	continent, continentId, zoneId = nil, nil, nil
	
	if WorldMapFrame:IsShown() then
		WorldMapContinentsDropDown_Update()
		WorldMapZoneDropDown_Update()
	end
end

function module:ZoomOut()
	if continent and GetCurrentMapAreaID() ~= zoneList.data[continent][zoneId] then
		self:SetMapZoom()
	end
end

function module:EncounterJournal_AddMapButtons()
	if select(4, EJ_GetMapEncounter(1)) then
		if tonumber(internalversion) < 16965 then -- if true, it's live WoW and not the PTR
			WorldMapShowDigSites:Hide()
		end
		LUI_WorldMap_ShowBossesCheckButton:Show()
	else
		if tonumber(internalversion) < 16965 then -- if true, it's live WoW and not the PTR
			WorldMapShowDigSites:Show()
		end
		LUI_WorldMap_ShowBossesCheckButton:Hide()
	end
end

--------------------------------------------------
-- Module Functions
--------------------------------------------------

function module:OnEnable()
	self:SecureHook("WorldMapFrame_LoadContinents")
	self:SecureHook("WorldMapContinentsDropDown_Update")
	
	self:RawHook("WorldMapZoneDropDown_Initialize", true)
	self:SecureHook("WorldMapZoneDropDown_Update")
	
	self:SecureHook("SetMapZoom")
	self:SecureHook("SetMapToCurrentZone", "SetMapZoom")
	self:SecureHook("ZoomOut")

	WorldMapShowDropDown.Show = LUI.dummy

	self:SecureHook("EncounterJournal_AddMapButtons")
end

function module:OnDisable()
	self:UnhookAll()
	continent, continentId, zoneId = nil, nil, nil
	WorldMapContinentsDropDown_Update()
	WorldMapZoneDropDown_Update()

	WorldMapShowDropDown.Show = nil
	if select(4, EJ_GetMapEncounter(1)) then
		WorldMapShowDropDown:Show()
	end
end