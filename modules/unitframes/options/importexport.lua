--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: importexport.lua
	Description: oUF Import/Export
]]

local addonname, LUI = ...
local module = LUI:GetModule("Unitframes")
local Fader = LUI:GetModule("Fader")
local ACR = LibStub("AceConfigRegistry-3.0")

local importLayoutName

local layouts = setmetatable({
	LUI = {},
	Shandrela = {
		boss = {
			Portrait = {
				Height = 30,
				Enable = true,
				Alpha = 0.15,
				Width = 170,
			},
			Aura = {
				Debuffs = {
					Enable = false,
				},
				Buffs = {
					Num = 4,
					DisableCooldown = true,
					ColorByType = true,
					Y = 0,
					X = -35,
					InitialAnchor = "LEFT",
					Enable = true,
					GrowthX = "LEFT",
				},
			},
			Point = "RIGHT",
			Backdrop = {
				Texture = "Solid",
			},
			Width = 170,
			Y = 65,
			X = -150,
			RaidMarkerIndicator = {
				Y = 6,
				Size = 35,
			},
			Height = 42,
			Padding = 50,
			HealthBar = {
				TextureBG = "Empty",
				Width = 170,
				Height = 30,
				IndividualColor = {
					b = 0.4,
					g = 0.4,
					r = 0.4,
				},
				BGMultiplier = 0,
				Texture = "RenaitreMinion",
			},
			PowerBar = {
				TextureBG = "Otravi",
				Color = "By Type",
				Enable = true,
				Width = 170,
				Y = -32,
				Texture = "Otravi",
			},
			HealthPercentText = {
				Outline = "OUTLINE",
				Color = "By Class",
				Y = 5,
				Font = "vibroceb",
				Enable = true,
				IndividualColor = {
					b = 1,
					g = 1,
					r = 1,
				},
				Size = 16,
			},
			NameText = {
				Outline = "OUTLINE",
				ColorNameByClass = true,
				Y = -20,
				Length = "Medium",
				Size = 19,
			},
		},
		partypet = {
			Enable = false,
		},
		focus = {
			Portrait = {
				Height = 24,
				Enable = true,
				Alpha = 0.15,
				Width = 200,
			},
			Castbar = {
				General = {
					Texture = "RenaitreMinion",
				},
			},
			Backdrop = {
				Texture = "Solid",
			},
			Y = -270,
			X = -435,
			Aura = {
				Debuffs = {
					Num = 8,
					DisableCooldown = true,
					ColorByType = true,
					Y = -28.5,
					X = 0.5,
					InitialAnchor = "TOPLEFT",
					Enable = true,
					Size = 18,
				},
			},
			HealthBar = {
				TextureBG = "Empty",
				Color = "Individual",
				IndividualColor = {
					b = 0.4,
					g = 0.4,
					r = 0.4,
				},
				BGMultiplier = 0,
				Texture = "RenaitreMinion",
			},
			RaidMarkerIndicator = {
				Size = 30,
			},
			HealthPercentText = {
				Outline = "OUTLINE",
				Font = "vibroceb",
				Color = "By Class",
				Size = 12,
			},
			NameText = {
				Outline = "OUTLINE",
				ColorNameByClass = true,
				Font = "vibroceb",
				Size = 12,
			},
			CombatFeedback = {
				Size = 20,
				Font = "vibrocen",
				Outline = "OUTLINE",
			},
		},
		target = {
			Portrait = {
				Height = 30,
				Enable = true,
				Alpha = 0.15,
				Width = 250,
			},
			Castbar = {
				General = {
					Texture = "RenaitreMinion",
				},
			},
			Backdrop = {
				Texture = "Solid",
			},
			Y = -220,
			X = 200,
			Aura = {
				Debuffs = {
					Enable = false,
				},
				Buffs = {
					Num = 5,
					DisableCooldown = true,
					ColorByType = true,
					Y = 10,
					X = 28,
					InitialAnchor = "TOPRIGHT",
					Size = 24,
				},
			},
			Height = 42,
			HealthBar = {
				TextureBG = "Empty",
				Tapping = true,
				IndividualColor = {
					b = 0.4,
					g = 0.4,
					r = 0.4,
				},
				BGMultiplier = 0,
				Texture = "RenaitreMinion",
			},
			PowerBar = {
				TextureBG = "Otravi",
				Texture = "Otravi",
			},
			HealthPredictionBar = {
				Enable = true,
			},
			ClassPowerBar = {
				Y = -4,
				X = 25,
				Width = 200,
				Height = 8,
				Multiplier = 0,
				BackgroundColor = {
					Enable = false,
				},
				Texture = "Otravi",
			},
			GroupRoleIndicator ={
				Y = 6,
				X = -6,
				Point = "RIGHT",
				Size = 15,
			},
			RaidMarkerIndicator = {
				Y = 6,
				Size = 35,
			},
			LeaderIndicator = {
				Y = 7,
				X = 5,
				Point = "LEFT",
				Size = 15,
			},
			NameText = {
				ColorLevelByDifficulty = false,
				Font = "neuropol",
				ShortClassification = true,
			},
			PowerText = {
				Y = -47,
				ShowEmpty = false,
				Size = 20,
			},
			HealthText = {
				Y = -27,
				Size = 24,
			},
			HealthPercentText = {
				Outline = "OUTLINE",
				Y = 5,
				Color = "By Class",
				Font = "vibroceb",
			},
			CombatFeedback = {
				Size = 20,
				Font = "vibrocen",
				Outline = "OUTLINE",
			},
		},
		targettarget = {
			Portrait = {
				Height = 24,
				Enable = true,
				Alpha = 0.15,
				Width = 200,
			},
			Backdrop = {
				Texture = "Solid",
			},
			Y = -270,
			Aura = {
				Debuffs = {
					Num = 8,
					GrowthY = "DOWN",
					DisableCooldown = true,
					ColorByType = true,
					Y = -28.5,
					Enable = true,
					Size = 18,
				},
			},
			HealthBar = {
				TextureBG = "Empty",
				Color = "Individual",
				IndividualColor = {
					b = 0.4,
					g = 0.4,
					r = 0.4,
				},
				BGMultiplier = 0,
				Texture = "RenaitreMinion",
			},
			RaidMarkerIndicator = {
				Size = 30,
			},
			HealthPercentText = {
				Outline = "OUTLINE",
				Font = "vibroceb",
				Color = "By Class",
				Size = 12,
			},
			NamText = {
				Outline = "OUTLINE",
				ColorNameByClass = true,
				Font = "vibroceb",
				Size = 12,
			},
			CombatFeedback = {
				Size = 20,
				Font = "vibrocen",
				Outline = "OUTLINE",
			},
		},
		focustarget = {
			Backdrop = {
				Texture = "Solid",
			},
		},
		bosstarget = {
			Enable = true,
			Backdrop = {
				Texture = "Solid",
			},
			HealthBar = {
				TextureBG = "Empty",
				Color = "Individual",
				IndividualColor = {
					b = 0.4,
					g = 0.4,
					r = 0.4,
				},
				BGMultiplier = 0,
				Texture = "RenaitreMinion",
			},
			Portrait = {
				Height = 24,
				Enable = true,
				Alpha = 0.15,
				Width = 130,
			},
			NameText = {
				Outline = "OUTLINE",
				ColorNameByClass = true,
				Y = 0,
				Font = "vibroceb",
				Size = 12,
			},
			Castbar = {
				General = {
					Enable = false,
				},
			},
		},
		partytarget = {
			RaidMarkerIndicator = {
				Size = 30,
			},
			Backdrop = {
				Texture = "Solid",
			},
			HealthBar = {
				TextureBG = "Empty",
				Color = "Individual",
				IndividualColor = {
					b = 0.4,
					g = 0.4,
					r = 0.4,
				},
				BGMultiplier = 0,
				Texture = "RenaitreMinion",
			},
			Portrait = {
				Height = 24,
				Enable = true,
				Alpha = 0.15,
				Width = 130,
			},
			NameText = {
				Outline = "OUTLINE",
				ColorNameByClass = true,
				Y = 0,
				Font = "vibroceb",
				Size = 12,
			},
		},
		pet = {
			Portrait = {
				Height = 30,
				Enable = true,
				Alpha = 0.15,
				Width = 130,
			},
			Backdrop = {
				Texture = "Solid",
			},
			Y = -220,
			Height = 42,
				HealthPredictionBar = {
					Enable = true,
				},
				HealthBar = {
					TextureBG = "Empty",
					IndividualColor = {
						b = 0.4,
						g = 0.4,
						r = 0.4,
					},
					BGMultiplier = 0,
					Texture = "RenaitreMinion",
				},
				PowerBar = {
					TextureBG = "Otravi",
					Texture = "Otravi",
				},
			Border = {
				Aggro = true,
			},
				HealthPercentText = {
					Outline = "OUTLINE",
					Y = 5,
					Color = "By Class",
					Font = "vibroceb",
				},
				NameText = {
					Enable = false,
				},
				CombatText = {
					Size = 20,
					Font = "vibrocen",
					Outline = "OUTLINE",
				},
		},
		raid = {
			Backdrop = {
				Texture = "Solid",
			},
				RaidMarkerIndicator = {
					Enable = true,
					Size = 20,
				},
			Portrait = {
				Alpha = 0.15,
			},
				HealthPredictionBar = {
					Enable = true,
				},
				HealthBar = {
					TextureBG = "Empty",
					IndividualColor = {
						b = 0.4,
						g = 0.4,
						r = 0.4,
					},
					BGMultiplier = 0,
					Texture = "RenaitreMinion",
				},
				PowerBar = {
					TextureBG = "Otravi",
					Texture = "Otravi",
				},
		},
		arenapet = {
			Enable = false,
		},
		player = {
				GroupRoleIndicator ={
					Y = 6,
					X = -6,
					Point = "RIGHT",
					Size = 15,
				},
				RaidMarkerIndicator = {
					Y = 6,
					Size = 35,
				},
				LeaderIndicator = {
					Y = 7,
					X = 5,
					Point = "LEFT",
					Size = 15,
				},
			Portrait = {
				Height = 30,
				Enable = true,
				Alpha = 0.15,
				Width = 250,
			},
			Castbar = {
				General = {
					Texture = "RenaitreMinion",
				},
			},
			Backdrop = {
				Texture = "Solid",
			},
			Y = -220,
			Height = 42,
				PowerBar = {
					TextureBG = "Otravi",
					Texture = "Otravi",
				},
				HealthPredictionBar = {
					Enable = true,
				},
				AdditionalPowerBar = {
					OverPower = false,
					TextureBG = "Otravi",
					Texture = "Otravi",
				},
				AlternativePowerBar = {
					OverPower = true,
					TextureBG = "Otravi",
					Texture = "Otravi",
				},
				HealthBar = {
					TextureBG = "Empty",
					IndividualColor = {
						b = 0.4,
						g = 0.4,
						r = 0.4,
					},
					BGMultiplier = 0,
					Texture = "RenaitreMinion",
				},
				RunesBar = {
					Y = -4,
					X = 25,
					Lock = false,
					Texture = "Otravi",
					Width = 200,
				},
				TotemsBar = {
					X = 25,
					Y = -4,
					Width = 200,
					Lock = false,
					Texture = "Otravi",
					Multiplier = 0,
				},
				ClassPowerBar = {
					X = 25,
					Y = -4,
					Width = 200,
					Lock = false,
					Texture = "Otravi",
				},
			Border = {
				Aggro = true,
			},
				PowerText = {
					Y = -48,
					ShowEmpty = false,
					Size = 20,
				},
				AdditionalPowerText = {
					Enable = false,
				},
				HealthText = {
					Y = -27,
					Size = 24,
				},
				HealthPercentText = {
					Outline = "OUTLINE",
					Y = 5,
					Color = "By Class",
					Font = "vibroceb",
				},
				CombatFeedback = {
					Size = 20,
					Font = "vibrocen",
					Outline = "OUTLINE",
				},
		},
		arena = {
			Aura = {
				Debuffs = {
					Num = 4,
					DisableCooldown = true,
					Y = 0,
					X = -35,
					IncludePet = true,
					InitialAnchor = "LEFT",
					GrowthX = "LEFT",
				},
			},
			Backdrop = {
				Texture = "Solid",
			},
			Y = 65,
			X = -150,
			Portrait = {
				Height = 30,
				Enable = true,
				Alpha = 0.15,
				Width = 170,
			},
			Height = 42,
				HealthBar = {
					TextureBG = "Empty",
					IndividualColor = {
						b = 0.4,
						g = 0.4,
						r = 0.4,
					},
					BGMultiplier = 0,
					Texture = "RenaitreMinion",
				},
				PowerBar = {
					TextureBG = "Otravi",
					Texture = "Otravi",
				},
				HealthPercentText = {
					Outline = "OUTLINE",
					Y = 5,
					Color = "By Class",
					Font = "vibroceb",
				},
			Castbar = {
				General = {
					Enable = false,
				},
			},
		},
		arenatarget = {
			Backdrop = {
				Texture = "Solid",
			},
				HealthBar = {
					TextureBG = "Empty",
					Color = "Individual",
					IndividualColor = {
						b = 0.4,
						g = 0.4,
						r = 0.4,
					},
					BGMultiplier = 0,
			},
			Portrait = {
				Height = 24,
				Enable = true,
				Alpha = 0.15,
				Width = 130,
			},
				NameText = {
					Outline = "OUTLINE",
					ColorNameByClass = true,
					Y = 0,
					Font = "vibroceb",
					Size = 12,
				},
		},
		Maintank = {
			Enable = false,
		},
		pettarget = {
			Enable = false,
		},
		party = {
			ShowPlayer = true,
			Border = {
				Aggro = true,
			},
			Aura = {
				Debuffs = {
					Num = 4,
					Y = 0,
					DisableCooldown = true,
				},
				Buffs = {
					Num = 4,
					PlayerOnly = true,
					Y = 34,
					Size = 20,
					DisableCooldown = true,
				},
			},
			Backdrop = {
				Texture = "Solid",
			},
			Y = 65,
			X = 150,
			Portrait = {
				Height = 30,
				Enable = true,
				Alpha = 0.15,
				Width = 170,
			},
			Height = 42,
				HealthPredictionBar = {
					Enable = true,
				},
				HealthBar = {
					TextureBG = "Empty",
					IndividualColor = {
						b = 0.4,
						g = 0.4,
						r = 0.4,
					},
					BGMultiplier = 0,
					Texture = "RenaitreMinion",
				},
				PowerBar = {
					TextureBG = "Otravi",
					Texture = "Otravi",
				},
				GroupRoleIndicator ={
					Y = 6,
					X = -6,
					Point = "RIGHT",
					Size = 15,
				},
				RaidMarkerIndicator = {
					Y = 6,
					Size = 35,
				},
				LeaderIndicator = {
					Y = 7,
					X = 5,
					Point = "LEFT",
					Size = 15,
				},
				HealthPercentText = {
					Outline = "OUTLINE",
					Y = 5,
					Color = "By Class",
					Font = "vibroceb",
				},
			Castbar = {
				General = {
					Enable = false,
				},
			},
		},
	},
	Yunai = {
		pettarget = {
			Y = 267.2,
			X = 313.6,
			Point = "BOTTOMLEFT",
			Fader = {
				Enable = true,
			},
		},
		pet = {
			Y = 40.5,
			X = -443.6,
			Point = "BOTTOM",
			Scale = 0.8,
			Fader = {
				Enable = true,
			},
		},
		party = {
			Enable = false,
		},
		player = {
			Point = "BOTTOM",
			Castbar = {
				General = {
					Latency = false,
				},
			},
			Scale = 0.75,
				PvPIndicator = {
					Enable = true,
			},
			Y = 40.5,
			Fader = {
				Enable = true,
			},
			Aura = {
				Buffs = {
					DisableCooldown = true,
					ColorByType = true,
				},
			},
			Portrait = {
				Alpha = 0.6,
			},
				AlternativePowerBar = {
					Enable = false,
				},
			X = -291.1,
				PowerPercentText = {
					Enable = true,
					ShowFull = true,
					ShowEmpty = true,
				},
				NameText = {
					Y = 50,
					X = -50,
					Size = 12,
				},
				PowerText = {
					Enable = false,
				},
				HealthPercentText = {
					ShowAlways = true,
				},
				HealthText = {
					Enable = false,
					ShowDead = true,
					Size = 20,
				},
				HealthMissingText = {
					Y = 20,
					ShowAlways = true,
					Enable = true,
				},
				PowerMissingText = {
					Enable = true,
					ShowFull = true,
					ShowEmpty = true,
				},
		},
		boss = {
			Y = -280,
			X = -16.2,
			Portrait = {
				Height = 25,
				X = 50,
				Alpha = 0.3,
				Enable = true,
			},
				HealthBar = {
					IndividualColor = {
						b = 1,
						g = 1,
						r = 1,
					},
				},
				PowerBar = {
					Enable = true,
					Height = 2,
				},
				NameText = {
					X = -100,
				},
		},
		Settings = {
			show_v2_party_textures = false,
			show_v2_arena_textures = false,
			Castbars = false,
			show_v2_textures = false,
		},
		focus = {
			Portrait = {
				Height = 30,
				X = 55,
				Alpha = 0.75,
			},
			Scale = 0.8,
			Y = 1,
			X = -57.5,
			Aura = {
				Buffs = {
					DisableCooldown = true,
					ColorByType = true,
					Y = -37,
					AuraTimer = true,
				},
			},
				PowerBar = {
					Color = "Individual",
					IndividualColor = {
						b = 1,
						g = 1,
						r = 1,
					},
					Height = 6,
					Enable = true,
				},
			Point = "RIGHT",
				HealthPercentText = {
					ShowDead = true,
					ShowAlways = true,
				},
		},
		target = {
			Portrait = {
				Alpha = 0.6,
				X = 140,
			},
			Castbar = {
				General = {
				},
			},
			Scale = 0.75,
				PvPIndicator = {
					Enable = true,
			},
			Y = 41.7,
			X = 291.1,
			Fader = {
				Enable = true,
			},
			Aura = {
				Debuffs = {
					Enable = false,
					DisableCooldown = true,
					ColorByType = true,
					GrowthX = "RIGHT",
					AuraTimer = true,
				},
				Buffs = {
					Y = 55,
					Num = 8,
					X = -225,
					InitialAnchor = "BOTTOMRIGHT",
					DisableCooldown = true,
					ColorByType = true,
					Enable = false,
					AuraTimer = true,
				},
			},
				HealthBar = {
					Tapping = true,
				},
			Point = "BOTTOM",
				PowerPercentText = {
					Y = -16,
					ShowEmpty = true,
					Enable = true,
					IndividualColor = {
						b = 1,
						g = 1,
						r = 1,
					},
					ShowFull = true,
					Size = 14,
				},
				NameText = {
					Outline = "OUTLINE",
					X = -250,
					ShortClassification = true,
					Length = "Long",
					Y = -50,
					Size = 20,
				},
				PowerText = {
					Enable = false,
				},
				HealthText = {
					Enable = false,
				},
				HealthPercentText = {
					ShowAlways = true,
				},
				HealthMissingText = {
					Y = 5,
					X = -200,
					Enable = true,
					ShowAlways = true,
					IndividualColor = {
						b = 1,
						g = 1,
						r = 1,
					},
					Size = 15,
				},
				PowerMissingText = {
					Y = -15,
					X = -200,
					ShowEmpty = true,
					Enable = true,
					IndividualColor = {
						b = 1,
						g = 1,
						r = 1,
					},
					ShowFull = true,
					Size = 13,
				},
		},
		raid = {
			Enable = false,
		},
		arena = {
			Enable = false,
		},
		targettarget = {
			Enable = false,
		},
	},
	Hix = {
		pettarget = {
			Enable = false,
		},
		raid = {
				HealthBar = {
					Color = "Gradient",
				},
				ReadyCheckIndicator = {
					Y = 2,
					Point = "RIGHT",
				},
				RaidMarkerIndicator = {
					Y = 5,
					Enable = true,
					Point = "TOP",
					Size = 14,
				},
		},
		arena = {
			Enable = false,
		},
		player = {
			Portrait = {
				Enable = true,
				Alpha = 0.1,
				Width = 250,
			},
			Castbar = {
				General = {
				},
			},
			Scale = 0.85,
			Border = {
				Aggro = true,
			},
			Y = -210,
			X = -300,
			Fader = {
				Enable = true,
			},
			Aura = {
				Debuffs = {
					Y = 60,
					GrowthY = "UP",
					PlayerOnly = true,
					Enable = true,
					ColorByType = true,
					IncludePet = true,
					AuraTimer = true,
				},
			},
				HealthPredictionBar = {
					Enable = true,
				},
				GroupRoleIndicator ={
					Size = 20,
				},
				RaidMarkerIndicator = {
					Point = "TOP",
					Size = 28,
				},
				HealthPercentText = {
					Y = 5,
				},
		},
		boss = {
			Portrait = {
				Height = 24,
				Enable = true,
				Alpha = 0.2,
				Width = 150,
			},
			Castbar = {
				X = -310,
				General = {
					Width = 150,
				},
				Text = {
					Name = {
						Size = 14,
					},
					Time = {
						ShowMax = false,
					},
				},
			},
				RaidMarkerIndicator = {
					Size = 24,
				},
			Width = 150,
			X = -35,
			Fader = {
				Enable = true,
			},
			Aura = {
				Debuffs = {
					Enable = false,
				},
			},
				HealthBar = {
					Color = "Gradient",
					Width = 150,
				},
				PowerBar = {
					Width = 150,
				},
				HealthPercentText = {
					X = -5,
					Point = "RIGHT",
					RelativePoint = "RIGHT",
					Enable = true,
					IndividualColor = {
						r = 1,
						g = 1,
						b = 1,
					},
					Size = 12,
				},
				NameText = {
					X = 5,
					Point = "LEFT",
					RelativePoint = "LEFT",
				},
		},
		Colors = {
			Smooth = {
				{1, 0, 0},
				{0.25, 0.25, 0.25},
				{0.25, 0.25, 0.25},
			},
		},
		focus = {
			Castbar = {
				General = {
				},
			},
			X = -500,
			Fader = {
				Enable = true,
			},
			Aura = {
				Debuffs = {
					Y = -35,
					PlayerOnly = true,
					Enable = true,
					ColorByType = true,
					IncludePet = true,
					AuraTimer = true,
				},
			},
			Scale = 0.85,
			Portrait = {
				Height = 24,
				Enable = true,
				Alpha = 0.2,
				Width = 200,
			},
				RaidMarkerIndicator = {
					Size = 28,
				},
				HealthPercentText = {
					ShowDead = true,
				},
		},
		target = {
			Portrait = {
				Enable = true,
				Alpha = 0.1,
				Width = 250,
			},
			Castbar = {
				General = {
				},
			},
			Scale = 0.85,
				RaidMarkerIndicator = {
					Point = "TOP",
					Size = 28,
				},
				GroupRoleIndicator ={
					Size = 20,
				},
			Y = -210,
			X = 300,
			Aura = {
				Debuffs = {
					Y = 75,
					PlayerOnly = true,
					ColorByType = true,
					IncludePet = true,
					AuraTimer = true,
				},
				Buffs = {
					Y = 60,
					ColorByType = true,
					InitialAnchor = "BOTTOMLEFT",
					AuraTimer = true,
				},
			},
				HealthBar = {
					Tapping = true,
				},
				HealthPredictionBar = {
					Enable = true,
				},
			Fader = {
				Enable = true,
			},
				HealthPercentText = {
					Y = 5,
				},
				NameText = {
					Format = "Level + Name + Race + Class",
					Length = "Long",
				},
		},
		targettarget = {
			X = 500,
			Portrait = {
				Height = 24,
				Enable = true,
				Alpha = 0.2,
				Width = 200,
			},
			Scale = 0.85,
			Fader = {
				Enable = true,
			},
				RaidMarkerIndicator = {
					Size = 28,
				},
				HealthPercentText = {
					ShowDead = true,
				},
		},
		pet = {
			Y = -210,
			X = 25,
			Point = "LEFT",
			Scale = 0.85,
			Fader = {
				Enable = true,
			},
			Portrait = {
				Enable = true,
				Alpha = 0.2,
				Width = 130,
			},
			HealthPercentText = {
				Y = 5,
			},
		},
		party = {
			Enable = false,
		},
	},
}, {__index = function(self, key) return module.db.global[key] or nil end})

for _, v in pairs(layouts) do
	v.Version = LUI.Versions.ouf
end

local function CopyData(source, destination)
	for k, v in pairs(source) do
		if type(v) == "table" then
			if not destination[k] then destination[k] = {} end
			CopyData(source[k], destination[k])
		elseif k ~= "Layout" then -- so the module.db.profile.Layout will not be copied
			destination[k] = source[k]
		end
	end
end

local function IsEmptyTable(data)
	if type(data) ~= "table" then return end
	for k, v in pairs(data) do --luacheck: ignore
		return false
	end
	return true
end

local function CleanupData(data, default)
	if type(data) ~= "table" then return end
	for k, v in pairs(data) do
		if type(v) == "table" then
			if default[k] then
				CleanupData(data[k], default[k])
				if IsEmptyTable(data[k]) then data[k] = nil end
			else
				data[k] = nil
			end
		else
			if default[k] == data[k] or default[k] == nil then data[k] = nil end
		end
	end
end

local function LoadLayout(layout)
	CopyData(module.defaults.profile, module.db.profile)
	CopyData(layouts[layout], module.db.profile)
	
	module:Refresh()
end

local function CheckLayout()
	if not module.db.profile.Layout then
		module.db.profile.Layout = "LUI"
	end
end

local function SaveLayout(layout)
	if layout == "" or layout == nil then return end
	if layouts[layout] then StaticPopup_Show("ALREADY_A_LAYOUT") return end
	
	module.db.global[layout] = {}
	
	CopyData(module.db.profile, module.db.global[layout])
	CleanupData(module.db.global[layout], module.defaults.profile)
	module.db.global[layout].Version = LUI.Versions.ouf
	module.db.profile.Layout = layout
	ACR:NotifyChange("LUI")
end

local function DeleteLayout(layout)
	if layout == "" or layout == nil then layout = module.db.profile.Layout end
	
	if layouts[layout] and not module.db.global[layout] then -- needed because of metatable!
		LUI:Print("THIS LAYOUT CAN NOT BE DELETED!!!")
		return
	end
	
	module.db.global[layout] = nil
	module.db.profile.Layout = nil
	CheckLayout()
	LoadLayout(module.db.profile.Layout)
	ACR:NotifyChange("LUI")
end

local function ImportLayoutName(name)
	if name == nil or name == "" then return end
	if layouts[name] then StaticPopup_Show("ALREADY_A_LAYOUT") return end
	importLayoutName = name
	StaticPopup_Show("IMPORT_LAYOUT_DATA")
end

local function ImportLayoutData(str)
	if str == nil or str == "" then return end
	if importLayoutName == nil then
		LUI:Print("Invalid Layout Name")
		return
	end
	if module.db.global[importLayoutName] ~= nil then StaticPopup_Show("ALREADY_A_LAYOUT") return end
	
	local valid, data = module:Deserialize(str)
	if not valid then
		LUI:Print("Error importing layout!")
		return
	end
	
	module.db.global[importLayoutName] = data
	
	if module.db.global[importLayoutName].Version ~= LUI.Versions.ouf then
		LUI:Print("This Layout was exported with a different version of LUI!")
	end
	
	module.db.profile.Layout = importLayoutName
	LoadLayout(importLayoutName)
	LUI:Print("Successfully imported "..importLayoutName.." layout!")
	importLayoutName = nil
	ACR:NotifyChange("LUI")
end

local function ExportLayout(layout)
	if layout == "" or layout == nil then layout = module.db.profile.Layout end
	if layouts[layout] == nil then return end
	
	local data = module:Serialize(module.db.global[layout])
	if data == nil then return end
	local breakDown
	for i = 1, math.ceil(string.len(data)/100) do
		local part = (strsub(data, (((i-1)*100)+1), (i*100))).." "
		breakDown = (breakDown and breakDown or "")..part
	end
	return breakDown
end

local function GetLayoutArray()
	local LayoutArray = {}
	
	for t in pairs(module.db.global) do
		table.insert(LayoutArray, t)
	end
	for t in pairs(layouts) do
		table.insert(LayoutArray, t)
	end
	table.sort(LayoutArray)
	
	return LayoutArray
end

do
	StaticPopupDialogs["ALREADY_A_LAYOUT"] = {
		preferredIndex = 3,
		text = "That layout already exists.\nPlease choose another name.",
		button1 = "OK",
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		enterClicksFirstButton = true,
	}
	
	StaticPopupDialogs["SAVE_LAYOUT"] = {
		preferredIndex = 3,
		text = 'Enter the name for your new layout',
		button1 = "Save Layout",
		button2 = "Cancel",
		hasEditBox = 1,
		editBoxWidth = 150,
		maxLetters = 20,
		OnAccept = function(self)
				self:Hide()
				SaveLayout(self.editBox:GetText())
			end,
		EditBoxOnEnterPressed = function(self)
				self:GetParent():Hide()
				SaveLayout(self:GetText())
			end,
		EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
	
	StaticPopupDialogs["DELETE_LAYOUT"] = {
		preferredIndex = 3,
		text = 'Are you sure you want to delete the current layout?',
		button1 = "Yes",
		button2 = "No",
		OnAccept = function(self) DeleteLayout() end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
	
	StaticPopupDialogs["IMPORT_LAYOUT"] = {
		preferredIndex = 3,
		text = 'Enter a name for your new layout',
		button1 = "Continue",
		button2 = "Cancel",
		hasEditBox = 1,
		editBoxWidth = 150,
		maxLetters = 20,
		OnAccept = function(self)
				self:Hide()
				ImportLayoutName(self.editBox:GetText())
			end,
		EditBoxOnEnterPressed = function(self)
				self:GetParent():Hide()
				ImportLayoutName(self:GetText())
			end,
		EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
	
	StaticPopupDialogs["IMPORT_LAYOUT_DATA"] = {
		preferredIndex = 3,
		text = "Paste the new layout string here:",
		button1 = "Import Layout",
		button2 = "Cancel",
		hasEditBox = 1,
		editBoxWidth = 500,
		maxLetters = 100000,
		OnAccept = function(self)
				ImportLayoutData(self.editBox:GetText())
			end,
		EditBoxOnEnterPressed = function(self)
				self:GetParent():Hide()
				ImportLayoutData(self:GetText())
			end,
		EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
	
	StaticPopupDialogs["EXPORT_LAYOUT"] = {
		preferredIndex = 3,
		text = "Copy the following to share it with others:",
		button1 = "Close",
		hasEditBox = 1,
		editBoxWidth = 500,
		maxLetters = 100000,
		OnShow = function(self)
				self.editBox:SetText(ExportLayout())
				self.editBox:SetFocus()
				self.editBox:HighlightText()
			end,
		EditBoxOnEnterPressed = function(self) self:GetParent():Hide() end,
		EditBoxOnExitPressed = function(self) self:GetParent():Hide() end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
	
	StaticPopupDialogs["RESET_LAYOUTS"] = {
		preferredIndex = 3,
		text = "Are you sure you want to reset all your layouts?",
		button1 = "Yes",
		button2 = "No",
		OnAccept = function(self)
				table.wipe(module.db.global)
				if module.db.global[module.db.profile.Layout] or layouts[module.db.profile.Layout] then return end
				module.db.profile.Layout = "LUI"
				CheckLayout()
				LoadLayout(module.db.profile.Layout)
				ACR:NotifyChange("LUI")
			end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
end

module.defaults.profile.Layout = "LUI"

function module:CreateImportExportOptions(order)
	-- partwise old way
	local options = {
		name = "Layout",
		type = "group",
		order = order,
		disabled = function() return not module.db.profile.Enable end,
		args = {
			desc = self:NewDesc("This is the Layout import/export page. Here you can import and export Unitframe Settings as you like.\n\n\nAttention! Sometimes importing a layout causes heavy lag, especially if the layout differs strongly from the default LUI layout.", 1),
			empty1 = self:NewDesc(" ", 2),
			SetLayout = { -- old way!
				name = "Layout",
				desc = "Choose any Layout you prefer most.",
				type = "select",
				values = GetLayoutArray,
				get = function()
						local LayoutArray = GetLayoutArray()
						for k, v in pairs(LayoutArray) do
							if v == module.db.profile.Layout then
								return k
							end
						end
					end,
				set = function(info, chosen)
						local LayoutArray = GetLayoutArray()
						for k, v in pairs(LayoutArray) do
							if k == chosen then
								if v ~= "" then
									module.db.profile.Layout = v
									LoadLayout(v)
								end
							end
						end
					end,
				order = 3,
			},
			empty2 = self:NewDesc(" ", 4),
			SaveLayout = self:NewExecute("Save Layout", "Save your current unitframe settings as a new layout.", 5, function() StaticPopup_Show("SAVE_LAYOUT") end),
			DeleteLayout = self:NewExecute("Delete Layout", "Delete the active layout.", 6, function() StaticPopup_Show("DELETE_LAYOUT") end),
			ImportLayout = self:NewExecute("Import Layout", "Import a new layout into LUI", 7, function() StaticPopup_Show("IMPORT_LAYOUT") end),
			ExportLayout = self:NewExecute("Export Layout", "Export the current layout so you can share it with others.", 8, function() StaticPopup_Show("EXPORT_LAYOUT") end),
			empty3 = LUI:NewEmpty(9),
			ResetLayouts = self:NewExecute("Reset Layouts", "Reset all layouts back to defaults", 10, function() StaticPopup_Show("RESET_LAYOUTS") end),
		}
	}

	return options
end
