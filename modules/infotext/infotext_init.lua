--[[
	Module.....: Infotext
	Description: Display LibDataBroker data sources and LUI status information.
]]
-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)
local L = LUI.L

---@class LUI.Infotext: LUIModule, AceHook-3.0
local module = LUI:NewModule("Infotext", "AceHook-3.0")

-- ####################################################################################################################
-- ##### Default Settings #############################################################################################
-- ####################################################################################################################

module.defaults = {
	profile = {
		TopBarTextAnchor = "TOP",
		TopBarOffsetX = 0,
		TopBarOffsetY = 0,
		['**'] = {
			Enable = true,
			Y = 0,
			X = 0,
			Point = "TOPLEFT",
			Color = { r = 1, g = 1, b = 1, a = 1, },
		},
		Colors = {
			Title  = { r = 0.4, g = 0.8, b = 1  , },
			Hint   = { r = 0  , g = 1  , b = 0  , },
			Status = { r = 0.7, g = 0.7, b = 0.7, },
			GameText =    { r = 1,    g = 0.77, b = 0,    },
			Rank =        { r = 0.1,  g = 0.9,  b = 1,    },
			Zone =        { r = 1,    g = 1,    b = 0,    },
			MOTD =        { r = 1,    g = 0.8,  b = 0,    },
			Note =        { r = 0.14, g = 0.76, b = 0.15, },
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
		},
		Currency = {
			Enable = false,
			Y = 5,
			X = 180,
			Point = "BOTTOMLEFT",
			DisplayLimit = 40,
		},
		Dualspec = {
			Enable = true,
			Y = 5,
			X = -300,
			Point = "BOTTOMRIGHT",
			lootSpec = true,
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
			ShowHints = true,
			ShowNotes = true,
			Background = {
				Texture = "Blizzard Dialog Background Dark",
				Color = { r = 0, g = 0, b = 0, a = 0.8, },
				BorderTexture = "Blizzard Tooltip",
				Border = { r = 0.3, g = 0.3, b = 0.3, a = 1, },
			},
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
			Background = {
				Texture = "Blizzard Dialog Background Dark",
				Color = { r = 0, g = 0, b = 0, a = 0.8, },
				BorderTexture = "Blizzard Tooltip",
				Border = { r = 0.3, g = 0.3, b = 0.3, a = 1, },
			},
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
			Enable = true,
			Y = 0,
			X = -575,
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
	LUI:AddColorCallback("Infotext", function()
		if module:IsEnabled() and module.Refresh then module:Refresh() end
	end)
end

function module:OnEnable()
	module:SetInfoPanels()
end

function module:OnDisable()
	if module.UnregisterAllLDBCallbacks then module:UnregisterAllLDBCallbacks() end
	if module.HideInfotips then module:HideInfotips() end
	module.topAnchor:Hide()
end
