--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: party.lua
	Description: oUF Party Module
	Version....: 1.0
]] 

local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local module = LUI:NewModule("oUF_Party")

local db

local defaults = {
	Party = {
		Enable = true,
		UseBlizzard = false,
		Height = "43",
		Width = "170",
		X = "150",
		Y = "100",
		Scale = 1,
		Point = "LEFT",
		Padding = "50",
		ShowPlayer = false,
		ShowInRaid = false,
		ShowInRealParty = false,
		Border = {
			Aggro = false,
			EdgeFile = "glow",
			EdgeSize = 5,
			Insets = {
				Left = "3",
				Right = "3",
				Top = "3",
				Bottom = "3",
			},
			Color = {
				r = "0",
				g = "0",
				b = "0",
				a = "1",
			},
		},
		Backdrop = {
			Texture = "Blizzard Tooltip",
			Padding = {
				Left = "-4",
				Right = "4",
				Top = "4",
				Bottom = "-4",
			},
			Color = {
				r = 0,
				g = 0,
				b = 0,
				a = 1,
			},
		},
		Health = {
			Height = "30",
			Width = "170",
			X = "0",
			Y = "0",
			Color = "Individual",
			Texture = "LUI_Gradient",
			TextureBG = "LUI_Gradient",
			BGAlpha = 1,
			BGMultiplier = 0.4,
			BGInvert = false,
			Smooth = true,
			IndividualColor = {
				r = 0.25,
				g = 0.25,
				b = 0.25,
			},
		},
		Power = {
			Enable = true,
			Height = "10",
			Width = "170",
			X = "0",
			Y = "-32",
			Color = "By Class",
			Texture = "LUI_Minimalist",
			TextureBG = "LUI_Minimalist",
			BGAlpha = 1,
			BGMultiplier = 0.4,
			BGInvert = false,
			Smooth = true,
			IndividualColor = {
				r = 0.8,
				g = 0.8,
				b = 0.8,
			},
		},
		Full = {
			Enable = false,
			Height = "14",
			Width = "170",
			X = "0",
			Y = "-42",
			Texture = "LUI_Minimalist",
			Alpha = 1,
			Color = {
				r = "0.11",
				g = "0.11",
				b = "0.11",
				a = "1",
			},
		},
		HealPrediction = {
			Enable = false,
			Texture = "LUI_Gradient",
			MyColor = {
				r = 0,
				g = 0.5,
				b = 0,
				a = 0.25
			},
			OtherColor = {
				r = 0,
				g = 1,
				b = 0,
				a = 0.25
			}
		},
		Aura = {
			buffs_colorbytype = false,
			buffs_playeronly = false,
			buffs_includepet = false,
			buffs_enable = false,
			buffs_auratimer = false,
			buffs_disableCooldown = false,
			buffs_cooldownReverse = true,
			buffsX = "0",
			buffsY = "-42",
			buffs_initialAnchor = "BOTTOMLEFT",
			buffs_growthY = "DOWN",
			buffs_growthX = "RIGHT",
			buffs_size = "26",
			buffs_spacing = "2",
			buffs_num = "8",
			debuffs_colorbytype = true,
			debuffs_playeronly = false,
			debuffs_includepet = false,
			debuffs_enable = true,
			debuffs_auratimer = false,
			debuffs_disableCooldown = false,
			debuffs_cooldownReverse = true,
			debuffsX = "35",
			debuffsY = "-5",
			debuffs_initialAnchor = "RIGHT",
			debuffs_growthY = "DOWN",
			debuffs_growthX = "RIGHT",
			debuffs_size = "26",
			debuffs_spacing = "2",
			debuffs_num = "36",
		},
		Castbar = {
			Enable = true,
			Height = "20",
			Width = "100",
			X = "10",
			Y = "0",
			Texture = "LUI_Gradient",
			TextureBG = "LUI_Minimalist",
			IndividualColor = false,
			Icon = false,
			Text = {
				Name = {
					Enable = true,
					Font = "neuropol",
					Size = 13,
					OffsetX = "5",
					OffsetY = "1",
				},
				Time = {
					Enable = false,
					ShowMax = true,
					Font = "neuropol",
					Size = 13,
					OffsetX = "-5",
					OffsetY = "1",
				},
			},
			Border = {
				Texture = "glow",
				Thickness = "4",
				Inset = {
					left = "3",
					right = "3",
					top = "3",
					bottom = "3",
				},
			},
			Colors = {
				Bar = {
					r = 0.13,
					g = 0.59,
					b = 1,
					a = 0.68,
				},
				Background = {
					r = 0.15,
					g = 0.15,
					b = 0.15,
					a = 0.67,
				},
				Border = {
					r = 0,
					g = 0,
					b = 0,
					a = 0.7,
				},
				Shield = {
					Enable = true,
					r = 0.5,
					g = 0,
					b = 0,
					a = 0.1,
				},
				Name = {
					r = 0.9,
					g = 0.9,
					b = 0.9,
				},
				Time = {
					r = 0.9,
					g = 0.9,
					b = 0.9,
				},
			},
		},
		Portrait = {
			Enable = false,
			Height = "43",
			Width = "90",
			X = "0",
			Y = "0",
			Alpha = 1,
		},
		Icons = {
			Lootmaster = {
				Enable = true,
				Size = 16,
				X = "17",
				Y = "10",
				Point = "TOPLEFT",
			},
			Leader = {
				Enable = true,
				Size = 17,
				X = "0",
				Y = "10",
				Point = "TOPLEFT",
			},
			Role = {
				Enable = true,
				Size = 22,
				X = "15",
				Y = "10",
				Point = "TOPRIGHT",
			},
			Raid = {
				Enable = true,
				Size = 55,
				X = "0",
				Y = "10",
				Point = "CENTER",
			},
			PvP = {
				Enable = false,
				Size = 35,
				X = "-12",
				Y = "10",
				Point = "TOPLEFT",
			},
		},
		Texts = {
			Name = {
				Enable = true,
				Font = "Prototype",
				Size = 19,
				X = "0",
				Y = "-20",
				IndividualColor = {
					r = 1,
					g = 1,
					b = 1,
				},
				Outline = "OUTLINE",
				Point = "CENTER",
				RelativePoint = "CENTER",
				Format = "Name",
				Length = "Medium",
				ColorNameByClass = true,
				ColorClassByClass = false,
				ColorLevelByDifficulty = false,
				ShowClassification = false,
				ShortClassification = false,
			},
			Health = {
				Enable = false,
				Font = "Prototype",
				Size = 24,
				X = "0",
				Y = "-43",
				Color = "Individual",
				ShowAlways = false,
				IndividualColor = {
					r = "0",
					g = "0",
					b = "0",
				},
				Outline = "NONE",
				Point = "BOTTOMLEFT",
				RelativePoint = "BOTTOMRIGHT",
				Format = "Absolut Short",
				ShowDead = false,
			},
			Power = {
				Enable = false,
				Font = "Prototype",
				Size = 24,
				X = "0",
				Y = "-66",
				Color = "By Class",
				ShowFull = true,
				ShowEmpty = true,
				IndividualColor = {
					r = "0",
					g = "0",
					b = "0",
				},
				Outline = "NONE",
				Point = "BOTTOMLEFT",
				RelativePoint = "BOTTOMRIGHT",
				Format = "Absolut Short",
			},
			HealthPercent = {
				Enable = true,
				Font = "Prototype",
				Size = 16,
				X = "0",
				Y = "6",
				Color = "Individual",
				ShowAlways = false,
				IndividualColor = {
					r = "1",
					g = "1",
					b = "1",
				},
				Outline = "NONE",
				Point = "CENTER",
				RelativePoint = "CENTER",
				ShowDead = true,
			},
			PowerPercent = {
				Enable = false,
				Font = "Prototype",
				Size = 24,
				X = "0",
				Y = "0",
				Color = "Individual",
				ShowFull = false,
				ShowEmpty = false,
				IndividualColor = {
					r = "0",
					g = "0",
					b = "0",
				},
				Outline = "NONE",
				Point = "CENTER",
				RelativePoint = "CENTER",
			},
			HealthMissing = {
				Enable = false,
				Font = "Prototype",
				Size = 24,
				X = "0",
				Y = "0",
				Color = "Individual",
				ShortValue = true,
				ShowAlways = false,
				IndividualColor = {
					r = "0",
					g = "0",
					b = "0",
				},
				Outline = "NONE",
				Point = "RIGHT",
				RelativePoint = "RIGHT",
			},
			PowerMissing = {
				Enable = false,
				Font = "Prototype",
				Size = 24,
				X = "0",
				Y = "0",
				Color = "Individual",
				ShortValue = true,
				ShowFull = false,
				ShowEmpty = false,
				IndividualColor = {
					r = "0",
					g = "0",
					b = "0",
				},
				Outline = "NONE",
				Point = "RIGHT",
				RelativePoint = "RIGHT",
			},
		},
		Fader = {
			Casting = true,
			Combat = true,
			Enable = false,
			Health = true,
			HealthClip = 1.0,
			Hover = true,
			HoverAlpha = 0.75,
			InAlpha = 1.0,
			OutAlpha = 0.1,
			OutDelay = 0.0,
			OutTime = 1.5,
			Power = true,
			PowerClip = 0.9,
			Targeting = true,
			UseGlobalSettings = true,
		},
	},	
}

function module:LoadOptions()
	local TogglePlayer = function() oUF_LUI_party:SetAttribute("showPlayer", db.oUF.Party.ShowPlayer) end
	
	local ToggleVisibility = function() oUF_LUI_party.handler:GetScript("OnEvent")(oUF_LUI_party.handler) end
	
	local options = {
		Party = {
			args = {
				General = {
					args = {
						General = {
							args = {
								ShowPlayer = LUI:NewToggle("Show Player", "Whether you want to show yourself within the Party Frames or not.", 3, db.oUF.Party, "ShowPlayer", LUI.defaults.profile.oUF.Party, TogglePlayer, nil, function() return not db.oUF.Party.Enable end),
								ShowInRaid = LUI:NewToggle("Show In Raid", "Whether you want to show the Party Frames while in Raids with more than 5 Players or not.", 4, db.oUF.Party, "ShowInRaid", LUI.defaults.profile.oUF.Party, ToggleVisibility, nil, function() return not db.oUF.Party.Enable end),
								ShowInRealParty = LUI:NewToggle("Show only in real Partys", "Whether you want to show the Party Frames only in real Partys or in Raids with 5 or less players too", 5, db.oUF.Party, "ShowInRealParty", LUI.defaults.profile.oUF.Party, ToggleVisibility, nil, function() return not db.oUF.Party.Enable or db.oUF.Party.ShowInRaid end),
							},
						},
					},
				},
			},
		},
	}
	
	return options
end

function module:OnInitialize()
	LUI:MergeDefaults(LUI.db.defaults.profile.oUF, defaults)
	LUI:RefreshDefaults()
	LUI:Refresh()
	
	self.db = LUI.db.profile
	db = self.db
	
	LUI:RegisterUnitFrame(self)
end

function module:OnEnable()
end
