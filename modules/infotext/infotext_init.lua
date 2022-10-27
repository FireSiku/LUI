--[[
	Module.....: Minimap
	Description: Replace the default minimap.
]]
-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, LUIAddon
local _, LUI = ...

---@class InfotextModule : LUIModule
local module = LUI:NewModule("Infotext", "AceHook-3.0")

-- ####################################################################################################################
-- ##### Default Settings #############################################################################################
-- ####################################################################################################################

module.defaults = {
	profile = {
		['**'] = {
			Enable = true,
			Y = 0,
			X = 0,
			InfoPanel = {
				Horizontal = "Left",
				Vertical = "Top",
			},
			Color = { r = 1, g = 1, b = 1, a = 1, },
			Font = "vibroceb",
			FontSize = 12,
			Outline = "",
		},
		General = {
			AllowY = false,
		},
		Colors = {
			Title  = { r = 0.4, g = 0.8, b = 1  , },
			Hint   = { r = 0  , g = 1  , b = 0  , },
			Status = { r = 0.7, g = 0.7, b = 0.7, },
			
			Panels = { r = 0.12, g = 0.58,  b = 0.89, a = 0.5, t = "Class", },
		},
		Fonts = {
			Infotext = { Name = "NotoSans-SCB", Size = 12, Flag = "OUTLINE", },
			Infotip =  { Name = "NotoSans-SCB", Size = 12, Flag = "",        },
		},
		-- Settings from each elements:
		Bags = {
			X = 150,
		},
		Clock = {
			X = 1660,
			instanceDifficulty = true,
			showSavedRaids = true,
			showWorldBosses = true,
			LocalTime = true,
			Time24 = false,
		},
		Currency = {
			Enable = false,
			X = 180,
			Display = 0,
			DisplayLimit = 40,
		},
		DualSpec = {
			X = 1000,
			Y = -800,
			lootSpec = true,
			ShowSpentPoints = true,
			InfoPanel = {
				Vertical = "Bottom",
			},
		},
		Durability = {
			X = 300,
		},
		FPS = {
			X = 450,
			MSValue = "Both",
		},
		Friends = {
			X = 1350,
			showTotal = false,
			hideApp = true,
			Colors = {
				Broadcast       = { r = 1,    g = 0.8,  b = 0,    },
				Note            = { r = 0.14, g = 0.76, b = 0.15, },
				Zone            = { r = 1,    g = 1,    b = 0,    },
				GameText        = { r = 1,    g = 0.77, b = 0,    },
				FriendBroadcast = { r = 0.8,  g = 0.3,  b = 0.2,  },
			},
			ShowTotal = false,
			ShowHints = true,
			ShowNotes = true,
		},
		Gold = {
			X = 15,
			showRealm = false,
			useBlizzard = false,
			showCopper = false,
			coloredSymbols = false,
		},
		Guild = {
			X = 1250,
			showTotal = false,
			hideRealm = true,
			hideNotes = false,
			Colors = {
				MOTD =        { r = 1,    g = 0.8,  b = 0,    },
				Note =        { r = 0.14, g = 0.76, b = 0.15, },
				OfficerNote = { r = 1,    g = 0.56, b = 0.25, },
				Rank =        { r = 0.1,  g = 0.9,  b = 1,    },
				Zone =        { r = 1,    g = 1,    b = 0,    },
			},
		},
		Instance = {
			Enable = false,
			X = 60,
			InfoPanel = {
				Vertical = "Bottom",
			},
		},
		Memory = {
			X = 600,
		},
		MoveSpeed = {
			X = -590,
			InfoPanel = {
				Horizontal = "Right",
				Vertical = "Top",
			},
		},
		WeaponInfo = {
			Enable = false,
			X = -350,
			InfoPanel = {
				Horizontal = "Right",
				Vertical = "Bottom",
			},
		},
		EquipmentSets = {
			Enable = false,
			Text = "Equipped Set: ",
			X = -225,
			InfoPanel = {
				Horizontal = "Right",
				Vertical = "Bottom",
			},
		},
		LootSpec = {
			Enable = false,
			Text = "Loot Spec: ",
			X = -75,
			InfoPanel = {
				Horizontal = "Right",
				Vertical = "Bottom",
			},
		},
		Mail = {
			Enable = false,
			NewIndic = " *",
			X = 275,
			Y = 0,
		},
	},
	--Keeps tracks of characters on current realm
	realm = {
		Gold = {
			Alliance = {},
			Horde = {},
		 	Neutral = {},
		}
	},
	--Keep tracks of server totals
	global = {
		Gold = {
			Alliance = {},
			Horde = {},
		}
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
end

function module:OnDisable()
	module.topAnchor:Hide()
	module.bottomAnchor:Hide()
end