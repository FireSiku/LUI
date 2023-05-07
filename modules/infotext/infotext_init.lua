--[[
	Module.....: Minimap
	Description: Replace the default minimap.
]]
-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, LUIAddon
local _, LUI = ...
local L = LUI.L

---@class InfotextModule : LUIModule
local module = LUI:NewModule("Infotext", "AceHook-3.0")
local Panels = LUI:GetModule("Panels", true)

-- ####################################################################################################################
-- ##### Default Settings #############################################################################################
-- ####################################################################################################################

module.defaults = {
	profile = {
		['**'] = {
			Enable = true,
			Y = 0,
			X = 0,
			Point = "TOPLEFT",
			Color = { r = 1, g = 1, b = 1, a = 1, },
			Font = "vibroceb",
			FontSize = 12,
			Outline = "",
		},
		General = {
			AllowY = true,
		},
		Colors = {
			Title  = { r = 0.4, g = 0.8, b = 1  , },
			Hint   = { r = 0  , g = 1  , b = 0  , },
			Status = { r = 0.7, g = 0.7, b = 0.7, },
			Panels = { r = 0.12, g = 0.58,  b = 0.89, a = 0.5, t = "Class", },
			GameText =    { r = 1,    g = 0.77, b = 0,    },
			Rank =        { r = 0.1,  g = 0.9,  b = 1,    },
			Zone =        { r = 1,    g = 1,    b = 0,    },
			MOTD =        { r = 1,    g = 0.8,  b = 0,    },
			Note =        { r = 0.14, g = 0.76, b = 0.15, },
			OfficerNote = { r = 1,    g = 0.56, b = 0.25, },
			Broadcast =   { r = 1,    g = 0.8,  b = 0,    },
			FriendBroadcast = { r = 0.8,  g = 0.3,  b = 0.2,  },
		},
		Fonts = {
			Infotext = { Name = "NotoSans-SCB", Size = 12, Flag = "OUTLINE", },
			Infotip =  { Name = "NotoSans-SCB", Size = 12, Flag = "",        },
		},
		-- Settings from each elements:
		Bags = {
			Enable = true,
			Y = 0,
			X = 150,
			Point = "TOPLEFT",
		},
		Clock = {
			Enable = true,
			Y = 0,
			X = -25,
			Point = "TOPRIGHT",
			instanceDifficulty = true,
			showSavedRaids = true,
			showWorldBosses = true,
			LocalTime = true,
			Time24 = false,
		},
		Currency = {
			Enable = false,
			Y = 5,
			X = 180,
			Point = "BOTTOMLEFT",
			Display = 0,
			DisplayLimit = 40,
		},
		Dualspec = {
			Enable = true,
			Y = 5,
			X = -300,
			Point = "BOTTOMRIGHT",
			lootSpec = true,
			ShowSpentPoints = true,
		},
		Durability = {
			Enable = true,
			Y = 0,
			X = 400,
			Point = "TOPLEFT",
		},
		EquipmentSets = {
			Enable = false,
			Text = "Equipped Set: ",
			SetName = "",
			Y = 5,
			X = -25,
			Point = "BOTTOMRIGHT",
		},
		FPS = {
			Enable = true,
			Y = 0,
			X = 550,
			Point = "TOPLEFT",
			MSValue = "Both",
		},
		Friends = {
			Enable = true,
			Y = 0,
			X = -350,
			Point = "TOPRIGHT",
			showTotal = false,
			hideApp = true,
			ShowTotal = false,
			ShowHints = true,
			ShowNotes = true,
		},
		Gold = {
			Enable = true,
			Y = 0,
			X = 15,
			Point = "TOPLEFT",
			showRealm = false,
			useBlizzard = false,
			showCopper = false,
			coloredSymbols = false,
			ShowConnected = true,
		},
		Guild = {
			Enable = true,
			Y = 0,
			X = -475,
			Point = "TOPRIGHT",
			showTotal = false,
			hideRealm = true,
			hideNotes = false,
		},
		Instance = {
			Enable = true,
			Y = 5,
			X = 325,
			Point = "BOTTOMLEFT",
		},
		LootSpec = {
			Enable = false,
			Text = "Loot Spec: ",
			Y = 5,
			X = -145,
			Point = "BOTTOMRIGHT",
		},
		Mail = {
			Enable = true,
			NewIndic = " *",
			Y = 0,
			X = 275,
			Point = "TOPLEFT",
		},
		Memory = {
			Enable = true,
			Y = 0,
			X = 700,
			Point = "TOPLEFT",
		},
		MoveSpeed = {
			Enable = false,
			Y = 0,
			X = -575,
			Point = "TOPRIGHT",
		},
		WeaponSpeed = {
			Enable = false,
			Y = 0,
			X = -670,
			Point = "TOPRIGHT",
		},
	},
	--Keep tracks of server totals
	global = {
		Gold = {
			Alliance = {},
			Horde = {},
		},
		ConnectedRealms = {},
	},
}

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

module.enableButton = true

function module:OnInitialize()
	LUI:RegisterModule(module)
	
end

function module:OnEnable()
	module:SetInfoPanels()
	if Panels and Panels:IsEnabled() then
		Panels:AdjustTopPanel()
	end
end

function module:OnDisable()
	module.topAnchor:Hide()
	module.bottomAnchor:Hide()
	if Panels and Panels:IsEnabled() then
		Panels:AdjustTopPanel()
	end
end
