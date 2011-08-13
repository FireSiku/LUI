--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: target.lua
	Description: oUF Target Module
	Version....: 1.0
]] 

local _, ns = ...
local oUF = ns.oUF or oUF

local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local module = LUI:NewModule("oUF_Target")
local Forte
local LSM = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists

local db

local defaults = {
	Target = {
		Height = "43",
		Width = "250",
		X = "200",
		Y = "-200",
		Point = "CENTER",
		Scale = 1,
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
			Width = "250",
			X = "0",
			Y = "0",
			Color = "Individual",
			Texture = "LUI_Gradient",
			TextureBG = "LUI_Gradient",
			BGAlpha = 1,
			BGMultiplier = 0.4,
			BGInvert = false,
			Smooth = true,
			Tapping = false,
			IndividualColor = {
				r = 0.25,
				g = 0.25,
				b = 0.25,
			},
		},
		Power = {
			Enable = true,
			Height = "10",
			Width = "250",
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
			Height = "17",
			Width = "250",
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
		ComboPoints = {
			Enable = true,
			ShowAlways = false,
			X = "0",
			Y = "0.5",
			Height = "5",
			Width = "249",
			Texture = "LUI_Ruben",
			Padding = 1,
			Multiplier = 0.4,
			BackgroundColor = {
				Enable = true,
				r = 0.23,
				g = 0.23,
				b = 0.23,
			},
		},
		Aura = {
			buffs_colorbytype = false,
			buffs_playeronly = false,
			buffs_includepet = false,
			buffs_enable = true,
			buffs_auratimer = false,
			buffs_disableCooldown = false,
			buffs_cooldownReverse = true,
			buffsX = "-0.5",
			buffsY = "30",
			buffs_initialAnchor = "TOPLEFT",
			buffs_growthY = "UP",
			buffs_growthX = "RIGHT",
			buffs_size = "26",
			buffs_spacing = "2",
			buffs_num = "36",
			debuffs_colorbytype = false,
			debuffs_playeronly = false,
			debuffs_includepet = false,
			debuffs_enable = true,
			debuffs_auratimer = false,
			debuffs_disableCooldown = false,
			debuffs_cooldownReverse = true,
			debuffsX = "-0.5",
			debuffsY = "60",
			debuffs_initialAnchor = "TOPRIGHT",
			debuffs_growthY = "UP",
			debuffs_growthX = "LEFT",
			debuffs_size = "26",
			debuffs_spacing = "2",
			debuffs_num = "36",
		},
		Castbar = {
			Enable = true,
			Height = "33",
			Width = "360",
			X = "13",
			Y = "205",
			Point = "BOTTOM",
			Texture = "LUI_Gradient",
			TextureBG = "LUI_Minimalist",
			IndividualColor = false,
			Icon = true,
			Text = {
				Name = {
					Enable = true,
					Font = "neuropol",
					Size = 15,
					OffsetX = "5",
					OffsetY = "1",
				},
				Time = {
					Enable = true,
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
			Width = "110",
			X = "0",
			Y = "0",
			Alpha = 1,
		},
		Icons = {
			Lootmaster = {
				Enable = true,
				Size = 15,
				X = "16",
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
				Size = 25,
				X = "5",
				Y = "0",
				IndividualColor = {
					r = 1,
					g = 1,
					b = 1,
				},
				Outline = "NONE",
				Point = "BOTTOMLEFT",
				RelativePoint = "BOTTOMRIGHT",
				Format = "Level + Name",
				Length = "Medium",
				ColorNameByClass = true,
				ColorClassByClass = true,
				ColorLevelByDifficulty = true,
				ShowClassification = true,
				ShortClassification = false,
			},
			Health = {
				Enable = true,
				Font = "Prototype",
				Size = 28,
				X = "0",
				Y = "-31",
				Color = "Individual",
				ShowAlways = true,
				IndividualColor = {
					r = "1",
					g = "1",
					b = "1",
				},
				Outline = "NONE",
				Point = "BOTTOMLEFT",
				RelativePoint = "BOTTOMLEFT",
				Format = "Standard",
				ShowDead = false,
			},
			Power = {
				Enable = true,
				Font = "Prototype",
				Size = 21,
				X = "0",
				Y = "-51",
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
				RelativePoint = "BOTTOMLEFT",
				Format = "Standard",
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
			Combat = {
				Enable = false,
				Font = "vibrocen",
				Outline = "OUTLINE",
				Size = 20,
				Point = "CENTER",
				RelativePoint = "BOTTOM",
				X = "0",
				Y = "0",
				ShowDamage = true,
				ShowHeal = true,
				ShowImmune = true,
				ShowEnergize = true,
				ShowOther = true,
				MaxAlpha = 0.6,
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
	local ToggleTapping = function(self, Enable)
		oUF_LUI_target.Health.colorTapping = Enable
		oUF_LUI_target:UpdateAllElements()
	end
	
	local ToggleCPoints = function(self, Enable)
		if not oUF_LUI_target.CPoints then LUI.oUF_LUI.funcs.CPoints(oUF_LUI_target, oUF_LUI_target.__unit, db.oUF.Target) end
		if Enable then
			oUF_LUI_target:EnableElement("CPoints")
		else
			oUF_LUI_target:DisableElement("CPoints")
		end

		if Forte then Forte:SetPosForte() end

		oUF_LUI_target:UpdateAllElements()
	end
	
	local ApplyCPoints = function()
		LUI.oUF_LUI.funcs.CPoints(oUF_LUI_target, oUF_LUI_target.__unit, db.oUF.Target)
		if Forte then Forte:SetPosForte() end
		oUF_LUI_target:UpdateAllElements()
	end
	
	local options = {
		Target = {
			args = {
				Bars = {
					args = {
						Health = {
							args = {
								Colors = {
									args = {
										Tapping = LUI:NewToggle("Enable Tapping", "Whether you want to show tapped Healthbars or not.", 6, db.oUF.Target.Health, "Tapping", LUI.defaults.profile.oUF.Target.Health, ToggleTapping),
									},
								},
							},
						},
						ComboPoints = {
							name = "Combo Points",
							type = "group",
							order = 11,
							args = {
								Enable = LUI:NewToggle("Enable", "Whether you want to show your Combo Points or not.", 1, db.oUF.Target.ComboPoints, "Enable", LUI.defaults.profile.oUF.Target.ComboPoints, ToggleCPoints),
								ShowAlways = LUI:NewToggle("Show Always", "Whether you want to always show your ComboPoints or not.", 2, db.oUF.Target.ComboPoints, "ShowAlways", LUI.defaults.profile.oUF.Target.ComboPoints, ApplyCPoints, nil, function() return not db.oUF.Target.ComboPoints.Enable end),
								empty = LUI:NewEmpty(3),
								desc = LUI:NewDesc("|cff3399ffImportant:|r\nTo Change the Color for each ComboPoint\nplease go to UnitFrames->Colors->Other", 4),
								empty2 = LUI:NewEmpty(5),
								Settings = {
									name = "Settings",
									type = "group",
									disabled = function() return not db.oUF.Target.ComboPoints.Enable end,
									guiInline = true,
									order = 6,
									args = {
										XValue = LUI:NewPosX("Combo Points", 1, db.oUF.Target.ComboPoints, "", LUI.defaults.profile.oUF.Target.ComboPoints, ApplyCPoints),
										YValue = LUI:NewPosY("Combo Points", 2, db.oUF.Target.ComboPoints, "", LUI.defaults.profile.oUF.Target.ComboPoints, ApplyCPoints),
										Width = LUI:NewWidth("Combo Points", 3, db.oUF.Target.ComboPoints, nil, LUI.defaults.profile.oUF.Target.ComboPoints, ApplyCPoints),
										Height = LUI:NewHeight("Combo Points", 4, db.oUF.Target.ComboPoints, nil, LUI.defaults.profile.oUF.Target.ComboPoints, ApplyCPoints),
										Padding = LUI:NewPadding("your Combo Points Segments", 5, db.oUF.Target.ComboPoints, nil, LUI.defaults.profile.oUF.Target.ComboPoints, ApplyCPoints),
										empty = LUI:NewEmpty(6),
										Texture = LUI:NewSelect("Texture", "Choose your Combo Points Texture.", 7, widgetLists.statusbar, "LSM30_Statusbar", db.oUF.Target.ComboPoints, "Texture", LUI.defaults.profile.oUF.Target.ComboPoints, ApplyCPoints),
										Multiplier = LUI:NewSlider("Multiplier", "Choose your Combo Points Background Multiplier.", 8, db.oUF.Target.ComboPoints, "Multiplier", LUI.defaults.profile.oUF.Target.ComboPoints, 0, 1, 0.05, ApplyCPoints, nil, function() return db.oUF.Target.ComboPoints.BackgroundColor.Enable end),
										IndividualBGColor = LUI:NewToggle("Individual Background Color", "Whether you want to use an individual Background Color or not.", 10, db.oUF.Target.ComboPoints.BackgroundColor, "Enable", LUI.defaults.profile.oUF.Target.ComboPoints, ApplyCPoints),
										BackgroundColor = LUI:NewColorNoAlpha("Combo Points Background", nil, 11, db.oUF.Target.ComboPoints.BackgroundColor, LUI.defaults.profile.oUF.Target.ComboPoints.BackgroundColor, ApplyCPoints, "full", function() return not db.oUF.Target.ComboPoints.BackgroundColor.Enable end),
									},
								},
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
	
	Forte = LUI:GetModule("Forte", true)
	
	LUI:RegisterUnitFrame(self)
end