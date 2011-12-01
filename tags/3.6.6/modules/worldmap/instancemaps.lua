--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: instancemaps.lua
	Description: WorldMap Instance Maps Module
]]

-- External references.
local addonname, LUI = ...
local WorldMap = LUI:Module("WorldMap")
local module = WorldMap:Module("InstanceMaps", "AceHook-3.0")

local L = LUI.L

--------------------------------------------------
-- Local Variables
--------------------------------------------------

local zoomOverride

local LBZ = LibStub("LibBabble-Zone-3.0"):GetLookupTable()

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
		"bgs-all",
	},
}

local zoneList = {names = {}, data = {}}
do
	-- http://www.wowwiki.com/API_SetMapByID and GetMapNameByID(id)
	local instanceMaps = {
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
	
	for zoneType, expansions in pairs(instanceMaps) do
		for expansion, zones in pairs(expansions) do
			local data = {}
			local key = ("%s-%s"):format(zoneType, expansion)
			
			zoneList.names[key], zoneList.data[key] = {}, {}
			for name, id in pairs(zones) do
				tinsert(zoneList.names[key], LBZ[name])
				data[LBZ[name]] = id
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
end

function module:OnDisable()
	self:UnhookAll()
	continent, continentId, zoneId = nil, nil, nil
	WorldMapContinentsDropDown_Update()
	WorldMapZoneDropDown_Update()
end