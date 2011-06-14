--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: player.lua
	Description: oUF Player Module
	Version....: 1.0
]] 

local _, ns = ...
local oUF = ns.oUF or oUF

local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local module = LUI:NewModule("oUF_Player")
local general = LUI:GetModule("oUF_General")
local Forte
local LSM = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists

local db

local positions = {"TOP", "TOPRIGHT", "TOPLEFT","BOTTOM", "BOTTOMRIGHT", "BOTTOMLEFT","RIGHT", "LEFT", "CENTER"}
local fontflags = {'OUTLINE', 'THICKOUTLINE', 'MONOCHROME', 'NONE'}
local justifications = {'LEFT', 'CENTER', 'RIGHT'}
local valueFormat = {'Absolut', 'Absolut & Percent', 'Absolut Short', 'Absolut Short & Percent', 'Standard', 'Standard Short'}
local _, class = UnitClass("player")

local defaults = {
	XP_Rep = {
		Font = "vibrocen",
		FontSize = 14,
		FontFlag = "NONE",
		FontJustify = "CENTER",
		FontColor = {
			r = 0,
			g = 1,
			b = 1,
			a = 1,
		},
		Experience = {
			Enable = true,
			ShowValue = true,
			AlwaysShow = false,
			Alpha = 1,
			BGColor = {
				r = 0,
				g = 0,
				b = 0,
				a = 0.7,
			},
			FillColor = {
				r = 0.33,
				g = 0.33,
				b = 0.33,
				a = 1,
			},
			RestedColor = {
				r = 0,
				g = 0.39,
				b = 0.88,
				a = 0.5,
			},
		},
		Reputation = {
			Enable = true,
			ShowValue = true,
			AlwaysShow = false,
			Alpha = 1,
			BGColor = {
				r = 0,
				g = 0,
				b = 0,
				a = 0.7,
			},
			FillColor = {
				r = 0.33,
				g = 0.33,
				b = 0.33,
				a = 1,
			},
		},
	},
	Player = {
		Height = "43",
		Width = "250",
		X = "-200",
		Y = "-200",
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
				r = 0,
				g = 0,
				b = 0,
				a = 1,
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
			Padding = "0",
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
			Padding = "-2",
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
			Texture = "LUI_Minimalist",
			Padding = "-12",
			Alpha = 1,
			Color = {
				r = 0.11,
				g = 0.11,
				b = 0.11,
				a = 1,
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
		DruidMana = {
			Enable = true,
			OverPower = true,
			Height = "10",
			Padding = "-2",
			Color = "By Type",
			Texture = "LUI_Minimalist",
			TextureBG = "LUI_Minimalist",
			BGAlpha = 1,
			BGMultiplier = 0.4,
			Smooth = true,
		},
		Totems = {
			Enable = true,
			X = "0",
			Y = "0.5",
			Height = "8",
			Width = "250",
			Texture = "LUI_Minimalist",
			Padding = 1,
			Multiplier = 0.5,
			Lock = true,
		},
		Runes = {
			Enable = true,
			X = "0",
			Y = "0.5",
			Height = "8",
			Width = "250",
			Texture = "LUI_Minimalist",
			Padding = 1,
			Lock = true,
		},
		HolyPower = {
			Enable = true,
			X = "0",
			Y = "0.5",
			Height = "8",
			Width = "250",
			Texture = "LUI_Minimalist",
			Padding = 1,
			Lock = true,
		},
		SoulShards = {
			Enable = true,
			X = "0",
			Y = "0.5",
			Height = "8",
			Width = "250",
			Texture = "LUI_Minimalist",
			Padding = 2,
			Lock = true,
		},
		Eclipse = {
			Enable = true,
			X = "0",
			Y = "0.5",
			Height = "8",
			Width = "250",
			Texture = "LUI_Minimalist",
			Lock = true,
			Text = {
				Enable = true,
				Font = "neuropol",
				Size = 12,
				Outline = "NONE",
				X = "0",
				Y = "0",
			},
		},
		AltPower = {
			Enable = true,
			OverPower = false,
			Color = "By Type",
			IndividualColor = {
				r = 1,
				g = 1,
				b = 1,
			},
			Height = "10",
			Padding = "-2",
			Texture = "LUI_Gradient",
			TextureBG = "LUI_Gradient",
			BGAlpha = 1,
			BGMultiplier = 0.4,
			Smooth = true,
			Text = {
				Enable = false,
				X = "0",
				Y = "0",
				Format = "Standard",
				Font = "neuropol",
				Size = 10,
				Outline = "NONE",
				Color = "Individual",
				IndividualColor = {
					r = 1,
					g = 1,
					b = 1,
				},
			},
		},
		Swing = {
			Enable = true,
			Width = "384",
			Height = "4",
			X = "0",
			Y = "86.5",
			Texture = "LUI_Gradient",
			Color = "By Class",
			IndividualColor = {
				r = 1,
				g = 1,
				b = 1,
			},
			BGTexture = "LUI_Minimalist",
			BGMultiplier = 0.4,
			Text = {
				Enable = false,
				X = "0",
				Y = "0",
				Format = "Standard",
				Font = "neuropol",
				Size = 10,
				Outline = "NONE",
				Color = "Individual",
				IndividualColor = {
					r = 1,
					g = 1,
					b = 1,
				},
			},
		},
		Vengeance = {
			Enable = true,
			Width = "384",
			Height = "4",
			X = "0",
			Y = "12",
			Texture = "LUI_Gradient",
			Color = "By Class",
			IndividualColor = {
				r = 1,
				g = 1,
				b = 1,
			},
			BGTexture = "LUI_Minimalist",
			BGMultiplier = 0.4,
			Text = {
				Enable = false,
				X = "0",
				Y = "0",
				Format = "Standard",
				Font = "neuropol",
				Size = 10,
				Outline = "NONE",
				Color = "Individual",
				IndividualColor = {
					r = 1,
					g = 1,
					b = 1,
				},
			},
		},
		Aura = {
			buffs_colorbytype = false,
			buffs_playeronly = false,
			buffs_includepet = false,
			buffs_enable = false,
			buffs_auratimer = false,
			buffs_disableCooldown = false,
			buffs_cooldownReverse = true,
			buffsX = "-0.5",
			buffsY = "-30",
			buffs_initialAnchor = "BOTTOMRIGHT",
			buffs_growthY = "DOWN",
			buffs_growthX = "LEFT",
			buffs_size = "26",
			buffs_spacing = "2",
			buffs_num = "8",
			debuffs_colorbytype = false,
			debuffs_playeronly = false,
			debuffs_includepet = false,
			debuffs_enable = false,
			debuffs_auratimer = false,
			debuffs_disableCooldown = false,
			debuffs_cooldownReverse = true,
			debuffsX = "-0.5",
			debuffsY = "-60",
			debuffs_initialAnchor = "BOTTOMLEFT",
			debuffs_growthY = "DOWN",
			debuffs_growthX = "RIGHT",
			debuffs_size = "26",
			debuffs_spacing = "2",
			debuffs_num = "36",
		},
		Castbar = {
			Enable = true,
			Height = "33",
			Width = "360",
			X = "13",
			Y = "155",
			Texture = "LUI_Gradient",
			TextureBG = "LUI_Minimalist",
			IndividualColor = false,
			Latency = true,
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
				Latency = {
					r = 0.11,
					g = 0.11,
					b = 0.11,
					a = 0.74,
				},
				Border = {
					r = 0,
					g = 0,
					b = 0,
					a = 0.7,
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
			Resting = {
				Enable = false,
				Size = 27,
				X = "-12",
				Y = "13",
				Point = "TOPLEFT",
			},
			Combat = {
				Enable = false,
				Size = 27,
				X = "-15",
				Y = "-30",
				Point = "BOTTOMLEFT",
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
				Enable = false,
				Font = "Prototype",
				Size = 24,
				X = "0",
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
					r = 1,
					g = 1,
					b = 1,
				},
				Outline = "NONE",
				Point = "BOTTOMRIGHT",
				RelativePoint = "BOTTOMRIGHT",
				Format = "Standard",
				ShowDead = false,
			},
			Power = {
				Enable = true,
				Font = "Prototype",
				Size = 21,
				X = "0",
				Y = "-52",
				Color = "By Class",
				ShowFull = true,
				ShowEmpty = true,
				IndividualColor = {
					r = 1,
					g = 1,
					b = 1,
				},
				Outline = "NONE",
				Point = "BOTTOMRIGHT",
				RelativePoint = "BOTTOMRIGHT",
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
					r = 1,
					g = 1,
					b = 1,
				},
				Outline = "NONE",
				Point = "CENTER",
				RelativePoint = "CENTER",
				ShowDead = true,
			},
			PowerPercent = {
				Enable = false,
				Font = "Prototype",
				Size = 14,
				X = "0",
				Y = "-15",
				Color = "Individual",
				ShowFull = false,
				ShowEmpty = false,
				IndividualColor = {
					r = 1,
					g = 1,
					b = 1,
				},
				Outline = "NONE",
				Point = "CENTER",
				RelativePoint = "CENTER",
			},
			HealthMissing = {
				Enable = false,
				Font = "Prototype",
				Size = 15,
				X = "-3",
				Y = "0",
				Color = "Individual",
				ShortValue = true,
				ShowAlways = false,
				IndividualColor = {
					r = 1,
					g = 1,
					b = 1,
				},
				Outline = "NONE",
				Point = "BOTTOMRIGHT",
				RelativePoint = "BOTTOMRIGHT",
			},
			PowerMissing = {
				Enable = false,
				Font = "Prototype",
				Size = 13,
				X = "-3",
				Y = "-15",
				Color = "Individual",
				ShortValue = true,
				ShowFull = false,
				ShowEmpty = false,
				IndividualColor = {
					r = 1,
					g = 1,
					b = 1,
				},
				Outline = "NONE",
				Point = "RIGHT",
				RelativePoint = "RIGHT",
			},
			DruidMana = {
				Enable = true,
				Font = "Prototype",
				Outline = "NONE",
				Size = 14,
				X = "0",
				Y = "0",
				Point = "BOTTOM",
				RelativePoint = "BOTTOM",
				Format = "Standard",
				HideIfFullMana = true,
				Color = "Individual",
				IndividualColor = {
					r = 1,
					g = 1,
					b = 1,
				},
			},
			Combat = {
				Enable = false,
				Font = "vibrocen",
				Outline = "OUTLINE",
				Size = 20,
				Point = "CENTER", ----- here down
				RelativePoint = "BOTTOM",
				X = "0",
				Y = "0",
				ShowDamage = true,
				ShowHeal = true,
				ShowImmune = true,
				ShowEnergize = true,
				ShowOther = true,
				MaxAlpha = 0.6, ----- to here
			},
			PvP = {
				Enable = true,
				Font = "vibroceb",
				Outline = "NONE",
				Size = 12,
				X = "20",
				Y = "5",
				Color = {
					r = 1.0,
					g = 0.1,
					b = 0.1,
				},
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

local barKeys = {
	Totems = "TotemBar",
	Runes = "Runes",
	HolyPower = "HolyPower",
	SoulShards = "SoulShards",
	Eclipse = "EclipseBar",
	Swing = "Swing",
	Vengeance = "Vengeance",
	AltPower = "AltPowerBar",
}
local barNames = {
	Totems = "Totems",
	Runes = "Runes",
	HolyPower = "Holy Power",
	SoulShards = "Soulshards",
	Eclipse = "Eclipse",
	Swing = "Swingtimer",
	Vengeance = "Vengeance",
	AltPower = "Alternate Power",
}

------------------------------------------------------------------------
--	XP/Rep Options Constructor
------------------------------------------------------------------------
	
function module:CreateXpRepOptionsPart(barType, order)
	local xprepdb = (barType == "XP") and db.oUF.XP_Rep.Experience or db.oUF.XP_Rep.Reputation
	local xprepdefaults = (barType == "XP") and LUI.defaults.profile.oUF.XP_Rep.Experience or LUI.defaults.profile.oUF.XP_Rep.Reputation
	
	local Toggle
	if barType == "XP" then
		Toggle = function()
			if not oUF_LUI_player.Experience then LUI.oUF.funcs.Experience(oUF_LUI_player, oUF_LUI_player.__unit, xprepdb) end
			if db.oUF.XP_Rep.Experience.Enable then
				oUF_LUI_player.Experience:Show()
				if oUF_LUI_player.Reputation then oUF_LUI_player.Reputation:Hide() end
			else
				oUF_LUI_player.Experience:Hide()
				if oUF_LUI_player.Reputation then oUF_LUI_player.Reputation:Show() end
			end
		end
	else
		Toggle = function()
			if not oUF_LUI_player.Reputation then LUI.oUF.funcs.Reputation(oUF_LUI_player, oUF_LUI_player.__unit, xprepdb) end
			if db.oUF.XP_Rep.Reputation.Enable then
				oUF_LUI_player.Reputation:Show()
				if oUF_LUI_player.Experience then oUF_LUI_player.Experience:Hide() end
			else
				oUF_LUI_player.Reputation:Hide()
				if oUF_LUI_player.Experience then oUF_LUI_player.Experience:Show() end
			end
		end
	end
	
	local ApplySettings = function()
		if oUF_LUI_player.Experience then LUI.oUF.funcs.Experience(oUF_LUI_player, oUF_LUI_player.__unit, xprepdb) end
		if oUF_LUI_player.Reputation then LUI.oUF.funcs.Reputation(oUF_LUI_player, oUF_LUI_player.__unit, xprepdb) end
	end
	
	local options = {
		name = "XPBar",
		type = "group",
		order = 3,
		args = {
			Enable = LUI:NewToggle("Enable", "Whether you want to show the Experience Bar or not.", 1, db.oUF.XP_Rep.Experience, "Enable", LUI.defaults.profile.oUF.XP_Rep.Experience, Toggle),
			Settings = {
				name = "Settings",
				type = "group",
				disabled = function() return not db.oUF.XP_Rep.Experience.Enable end,
				guiInline = true,
				order = 2,
				args = {
					ShowValue = LUI:NewToggle("Show Value", "Whether you want to show how much "..barType.." you have in the "..barType.." bar or not.", 1, xprepdb, "ShowValue", xprepdefaults, ApplySettings),
					AlwaysShow = LUI:NewToggle("Always Show", "Whether you want the "..barType.." bar to show always or not.", 2, xprepdb, "AlwaysShow", xprepdefaults, ApplySettings),
					BGColor = LUI:NewColor("Background", barType.." bar Background.", 3, xprepdb.BGColor, xprepdefaults.BGColor, ApplySettings),
					FillColor = LUI:NewColor("Fill", barType.." bar Fill.", 4, xprepdb.FillColor, xprepdefaults.FillColor, ApplySettings),
					RestedColor = (barType == "XP") and LUI:NewColor("Rested", barType.." bar Rested.", 5, xprepdb.RestedColor, xprepdefaults.FillColor, ApplySettings) or nil,
					Alpha = LUI:NewSlider("Alpha", "Select the alpha of the "..barType.." bar when shown.", 6, xprepdb, "Alpha", xprepdefaults, 0, 1, 0.05, ApplySettings, nil, nil, nil, true),
				},
			},
		},
	}
	
	return options
end

function module:CreateXpRepOptions(order)
	local xprepdb = db.oUF.XP_Rep
	local xprepdefaults = LUI.defaults.profile.oUF.XP_Rep
	
	local ResetXpRep = function()
		db.oUF.XP_Rep = defaults.XP_Rep
		StaticPopup_Show("RELOAD_UI")
	end
	
	local options = {
		name = "XP / Rep",
		type = "group",
		order = order,
		disabled = function() return not db.oUF.Settings.Enable end,
		childGroups = "tab",
		args = {
			header = LUI:NewHeader("XP / Rep", 1),
			Info = {
				name = "Info",
				type = "group",
				order = 2,
				args = {
					About = {
						name = "About",
						type = "group",
						order = 1,
						guiInline = true,
						args = {
							desc = LUI:NewDesc("The XP and Rep bars are located below the Player UnitFrame and will show on mouseover.\nThe Experience Bar will only be shown if you are not yet Level "..MAX_PLAYER_LEVEL..".\n\nIf you are not yet Level "..MAX_PLAYER_LEVEL.." you can right click on either bar to switch to the other.\nWhen you left click on one of the bars, information about that bar will be paste into your Chat EditBox if it is open and added to the Chat Window if not.\n\n\n", 1)
						},
					},
					Reset = LUI:NewExecute("Reset", nil, 5, ResetXpRep),
				},
			},
			Experience = module:CreateXpRepOptionsPart("XP", 3),
			Reputation = module:CreateXpRepOptionsPart("Rep", 4),
			Font = {
				name = "Font",
				type = "group",
				order = 5,
				args = {
					Font = LUI:NewSelect("Font", "Choose the Font for the XP/Rep text.", 1, widgetLists.font, "LSM30_Font", xprepdb, "Font", xprepdefaults, ApplySettings),
					Size = LUI:NewSlider("Font Size", "Choose the Font Size for the XP/Rep text.", 2, xprepdb, "FontSize", xprepdefaults, 6, 20, 1, ApplySettings),
					Flag = LUI:NewSelect("Font Flag", "Choose the Font Flag for the XP/Rep text.", 3, fontflags, nil, xprepdb, "FontFlag", xprepdefaults, ApplySettings),
					Justify	= LUI:NewSelect("Font Justify", "Choose the Font Justification for the XP/Rep text.", 4, justifications, nil, xprepdb, "FontJustify", xprepdefaults, ApplySettings),
					Color = LUI:NewColor("Font", "XP/Rep text", 5, xprepdb.FontColor, xprepdefaults.FontColor, ApplySettings),
				},
			},
		},
	}
	
	return options
end

------------------------------------------------------------------------
--	Bar Options Constructor
------------------------------------------------------------------------

--barKey: Key in the ouf layout / the creator funcs
--barName: Shown Name in the options
--barType: Key in the options/db
--barType: Vengeance, Swing, Totems, Runes, HolyPower, SoulShards, Eclipse
function module:CreateBarOptions(barType, order)
	local barName = barNames[barType]
	local barKey = barKeys[barType]
	local bardb = db.oUF.Player[barType]
	local bardefaults = LUI.defaults.profile.oUF.Player[barType]
	
	local isLockable = not (barType == "Vengeance" or barType == "Swing")
	local isLocked
	if isLockable then isLocked = function() return not bardb.Enable or bardb.Lock end end
	
	local ToggleFunc = function(self, Enable)
		if not oUF_LUI_player[barKey] then LUI.oUF.funcs[barKey](oUF_LUI_player, oUF_LUI_player.__unit, db.oUF.Player) end
		if Enable then
			oUF_LUI_player:EnableElement(barKey)
		else
			oUF_LUI_player:DisableElement(barKey)
		end

		if Forte then Forte:SetPosForte() end

		oUF_LUI_player:UpdateAllElements()
	end
	
	local ApplySettings = function()
		LUI.oUF.funcs[barKey](oUF_LUI_player, oUF_LUI_player.__unit, db.oUF.Player)
		oUF_LUI_player:UpdateAllElements()
	end
	
	local options = {
		name = barName,
		type = "group",
		order = order,
		args = {
			Enable = LUI:NewToggle("Enable", "Whether you want to show the "..barName.." or not", 1, bardb, "Enable", bardefaults, ToggleFunc),
			General = {
				name = "General Settings",
				type = "group",
				disabled = function() return not bardb.Enable end,
				guiInline = true,
				order = 2,
				args = {
					Lock = isLockable and LUI:NewToggle("Lock", "Whether you want to lock the "..barName.." to your PlayerFrame or not.\nIf locked, Forte Spelltimer will be adjust automaticly", 1, bardb, "Lock", bardefaults, ApplySettings) or nil,
					XValue = LUI:NewPosX(barName, 2, bardb, "", bardefaults, ApplySettings, nil, function() return not bardb.Enable or bardb.Lock end),
					YValue = LUI:NewPosY(barName, 3, bardb, "", bardefaults, ApplySettings, nil, function() return not bardb.Enable or bardb.Lock end),
					Width = LUI:NewWidth(barName, 4, bardb, nil, bardefaults, ApplySettings),
					Height = LUI:NewHeight(barName, 5, bardb, nil, bardefaults, ApplySettings),
					empty = LUI:NewEmpty(6),
					Padding = (barType ~= "Eclipse" and isLockable) and LUI:NewSlider("Padding", "Choose the Padding between your "..barName.." Elements.", 12, bardb, "Padding", bardefaults, 1, 10, 1, ApplySettings) or nil,
				},
			},
			Colors = (not isLockable) and {
				name = "Color Settings",
				type = "group",
				disabled = function() return not bardb.Enable end,
				guiInline = true,
				order = 3,
				args = {
					ColorType = LUI:NewSelect("Color", "Choose the Color Option for your "..barName..".", 1, {"By Class", "Individual"}, nil, bardb, "Color", bardefaults, ApplySettings),
					Color = LUI:NewColorNoAlpha("Individual", barName, 2, bardb.IndividualColor, bardefaults.IndividualColor, ApplySettings, nil, function() return (bardb.Color == "By Class") end),
				},
			} or nil,
			Textures = {
				name = "Texture Settings",
				type = "group",
				disabled = function() return not bardb.Enable end,
				guiInline = true,
				order = 3,
				args = {
					Texture = LUI:NewSelect("Texture", "Choose the "..barName.." Texture.", 1, widgetLists.statusbar, "LSM30_Statusbar", bardb, "Texture", bardefaults, ApplySettings),
					BGTexture = (not isLockable) and LUI:NewSelect("Background Texture", "Choose the "..barName.." Background Texture.", 2, widgetLists.statusbar, "LSM30_Statusbar", bardb, "BGTexture", bardefaults, ApplySettings) or nil,
					Multiplier = (barType == "TotemBar") and LUI:NewSlider("Multiplier", "Choose the "..barName.." Background Multiplier.", 3, bardb, "Multiplier", bardefaults, 0, 1, 0.05, ApplySettings) or nil,
					BGMultiplier = (not isLockable) and LUI:NewSlider("Background Multiplier", "Choose the Multiplier which will be used to generate the Background Color.", 4, bardb, "BGMultiplier", bardefaults, 0, 1, 0.05, ApplySettings) or nil,
				},
			},
		}
	}
	
	return options
end

------------------------------------------------------------------------
--	Bar Text Options Constructor
------------------------------------------------------------------------

--barKey: Key in the ouf layout / the creator funcs
--barName: Shown Name in the options
--barType: Key in the options/db
--barType: Vengeance, Swing, Eclipse, AltPower
function module:CreateBarTextOptions(barType, order)
	local barName = barNames[barType]
	local barKey = barKeys[barType]
	local bardb = db.oUF.Player[barType]
	local bardefaults = LUI.defaults.profile.oUF.Player[barType]
	
	local textformats = barType == "AltPower" and {"Absolut", "Percent", "Standard"} or {"Absolut", "Standard"}
	
	local ApplySettings = function()
		LUI.oUF.funcs[barKey](oUF_LUI_player, oUF_LUI_player.__unit, db.oUF.Player)
		oUF_LUI_player:UpdateAllElements()
	end
	
	local options = {
		name = barName,
		type = "group",
		disabled = function() return not bardb.Enable end,
		order = order,
		args = {
			Enable = LUI:NewToggle("Enable Text", "Whether you want to show the "..barType.." Bar Text or not.", 1, bardb.Text, "Enable", bardefaults.Text, ApplySettings, nil, function() return not bardb.Enable end),
			FontSettings = {
				name = "Font Settings",
				type = "group",
				disabled = function() return not bardb.Text.Enable end,
				guiInline = true,
				order = 2,
				args = {
					FontSize = LUI:NewSlider("Size", "Choose your "..barType.." Bar Text Fontsize.", 1, bardb.Text, "Size", bardefaults.Text, 1, 40, 1, ApplySettings),
					empty = LUI:NewEmpty(2),
					Font = LUI:NewSelect("Font", "Choose your "..barType.." Bar Text Font.", 3, widgetLists.font, "LSM30_Font", bardb.Text, "Font", bardefaults.Text, ApplySettings),
					FontFlag = LUI:NewSelect("Font Flag", "Choose the Font Flag for the "..barType.." Bar Text.", 4, fontflags, nil, bardb.Text, "Outline", bardefaults.Text, ApplySettings),
				},
			},
			Settings = {
				name = "Settings",
				type = "group",
				disabled = function() return not bardb.Text.Enable end,
				guiInline = true,
				order = 3,
				args = {
					XValue = LUI:NewPosX(barType.." Bar Text", 1, bardb.Text, "", bardefaults.Text, ApplySettings),
					YValue = LUI:NewPosY(barType.." Bar Text", 2, bardb.Text, "", bardefaults.Text, ApplySettings),
					Format = (barType ~= "Eclipse") and LUI:NewSelect("Format", "Choose the Format for the "..barType.." Bar Text.", 3, textformats, nil, bardb.Text, "Format", bardefaults.Text, ApplySettings) or nil,
				},
			},
			Color = (barType ~= "Eclipse") and {
				name = "Color Settings",
				type = "group",
				disabled = function() return not bardb.Text.Enable end,
				guiInline = true,
				order = 4,
				args = {
					Color = LUI:NewSelect("Color", "Choose the Color Option for the "..barType.." Bar Text.", 1, {"By Class", "Individual"}, nil, bardb.Text, "Color", bardefaults.Text, ApplySettings),
					IndividualColor = LUI:NewColorNoAlpha("", barType.." Bar Text", 2, bardb.Text.IndividualColor, bardefaults.Text.IndividualColor, ApplySettings),
				},
			} or nil,
		},
	}
	
	return options
end

------------------------------------------------------------------------
--	General Options
------------------------------------------------------------------------
	
function module:LoadOptions()
	local ToggleDruidManaBar = function(self, Enable)
		if not oUF_LUI_player.DruidMana then LUI.oUF.funcs.DruidMana(oUF_LUI_player, oUF_LUI_player.__unit, db.oUF.Player) end
		if Enable then
			oUF_LUI_player:EnableElement("DruidMana")
		else
			oUF_LUI_player:DisableElement("DruidMana")
		end
		oUF_LUI_player:UpdateAllElements()
	end

	local ToggleDruidManaText = function(self, Enable)
		if Enable then
			oUF_LUI_player.DruidMana.value:Show()
		else
			oUF_LUI_player.DruidMana.value:Hide()
		end
	end
	
	local StyleDruidMana = function()
		db.oUF.Player.AltPower.OverPower = not db.oUF.Player.DruidMana.OverPower
		LUI.oUF.funcs.DruidMana(oUF_LUI_player, oUF_LUI_player.__unit, db.oUF.Player)
		if oUF_LUI_player.AltPowerBar then oUF_LUI_player.AltPowerBar.SetPosition() end
		oUF_LUI_player.DruidMana.SetPosition()
		oUF_LUI_player:UpdateAllElements()
	end
	
	local SmoothDruidMana = function(self, Smooth)
		if Smooth then
			oUF_LUI_player:SmoothBar(oUF_LUI_player.DruidMana.ManaBar)
		else
			oUF_LUI_player.DruidMana.ManaBar.SetValue = oUF_LUI_player.DruidMana.ManaBar.SetValue_
		end
	end
	
	local StylePvP = function()
		LUI.oUF.funcs.PvP(oUF_LUI_player, oUF_LUI_player.__unit, db.oUF.Player)
		oUF_LUI_player:UpdateAllElements()
	end
	
	local ToggleAltPower = function(self, Enable)
		if not oUF_LUI_player.AltPowerBar then
			LUI.oUF.funcs.AltPowerBar(oUF_LUI_player, oUF_LUI_player.__unit, db.oUF.Player)
			if oUF_LUI_pet then LUI.oUF.funcs.AltPowerBar(oUF_LUI_pet, oUF_LUI_pet.__unit, db.oUF.Pet) end
		end
		if oUF_LUI_pet and not oUF_LUI_pet.AltPowerBar then oUF_LUI_pet.CreateAltPowerBar() end
		if Enable then
			oUF_LUI_player:EnableElement("AltPowerBar")
			if oUF_LUI_pet then oUF_LUI_pet:EnableElement("AltPowerBar") end
		else
			oUF_LUI_player:DisableElement("AltPowerBar")
			if oUF_LUI_pet then oUF_LUI_pet:DisableElement("AltPowerBar") end
		end
		oUF_LUI_player:UpdateAllElements()
	end
	
	local StyleAltPower = function()
		db.oUF.Player.DruidMana.OverPower = not db.oUF.Player.AltPower.OverPower
		LUI.oUF.funcs.AltPowerBar(oUF_LUI_player, oUF_LUI_player.__unit, db.oUF.Player)
		if oUF_LUI_pet then LUI.oUF.funcs.AltPowerBar(oUF_LUI_pet, oUF_LUI_pet.__unit, db.oUF.Pet) end
		if oUF_LUI_player.DruidMana then oUF_LUI_player.DruidMana.SetPosition() end
		oUF_LUI_player:UpdateAllElements()
		if oUF_LUI_pet then oUF_LUI_pet:UpdateAllElements() end
	end
	
	local options = {
		XP_Rep = module:CreateXpRepOptions(5),
		Player = {
			args = {
				Bars = {
					args = {
						DruidMana = (class == "DRUID") and {
							name = "Druid Mana",
							type = "group",
							order = 11,
							args = {
								DruidManaEnable = LUI:NewToggle("Enable", "Whether you want to show the Druid Mana Bar while in Cat/Bear or not.", 1, db.oUF.Player.DruidMana, "Enable", LUI.defaults.profile.oUF.Player.DruidMana, ToggleDruidManaBar),
								General = {
									name = "Settings",
									type = "group",
									disabled = function() return not db.oUF.Player.DruidMana.Enable end,
									guiInline = true,
									order = 2,
									args = {
										OverPower = LUI:NewToggle("Over Power Bar", "Whether you want the Druid Mana Bar to take up halt the Power bar or not.\n\nNote: This option disables the OverPower option of the Alternate Power Bar.", 1, db.oUF.Player.DruidMana, "OverPower", LUI.defaults.profile.oUF.Player.DruidMana, StyleDruidMana),
										Height = LUI:NewHeight("Druid Mana Bar", 2, db.oUF.Player.DruidMana, nil, LUI.defaults.profile.oUF.Player.DruidMana, StyleDruidMana),
										Padding = LUI:NewPadding("Power Bar & Druid Mana Bar", 3, db.oUF.Player.DruidMana, nil, LUI.defaults.profile.oUF.Player.DruidMana, StyleDruidMana),
										Smooth = LUI:NewToggle("Enable Smooth Bar Animation", "Whether you want to use Smooth Animations or not.", 4, db.oUF.Player.DruidMana, "Smooth", LUI.defaults.profile.oUF.Player.DruidMana, SmoothDruidMana),
									},
								},
								Colors = {
									name = "Color Settings",
									type = "group",
									disabled = function() return not db.oUF.Player.DruidMana.Enable end,
									guiInline = true,
									order = 3,
									args = {
										ColorType = LUI:NewSelect("Color", "Choose the Color Option for the Druid Mana Bar", 1, {"By Class", "By Type", "Gradient"}, nil, db.oUF.Player.DruidMana, "Color", LUI.defaults.profile.oUF.Player.Texts.DruidMana, StyleDruidMana),
									},
								},
								Textures = {
									name = "Texture Settings",
									type = "group",
									disabled = function() return not db.oUF.Player.DruidMana.Enable end,
									guiInline = true,
									order = 4,
									args = {
										DruidManaTex = LUI:NewSelect("Texture", "Choose the Druid Mana Bar Texture.", 1, widgetLists.statusbar, "LSM30_Statusbar", db.oUF.Player.DruidMana, "Texture", LUI.defaults.profile.oUF.Player.DruidMana, StyleDruidMana),
										DruidManaTexBG = LUI:NewSelect("Background Texture", "Choose the Druid Mana Bar Background Texture.", 2, widgetLists.statusbar, "LSM30_Statusbar", db.oUF.Player.DruidMana, "TextureBG",LUI.defaults.profile.oUF.Player.DruidMana, StyleDruidMana),
										DruidManaTexBGAlpha = LUI:NewSlider("Background Alpha", "Choose the Alpha Value for the Druid Mana Bar Background.", 3, db.oUF.Player.DruidMana, "BGAlpha",LUI.defaults.profile.oUF.Player.DruidMana, 0, 1, 0.05, StyleDruidMana),
										DruidManaTexBGMultiplier = LUI:NewSlider("Background Multiplier", "Choose the Multiplier which will be used to generate the Background Color.", 4, db.oUF.Player.DruidMana, "BGMultiplier", LUI.defaults.profile.oUF.Player.DruidMana, 0, 1, 0.05, StyleDruidMana),
									},
								},
							},
						} or nil,
						TotemBar = (class == "SHAMAN") and module:CreateBarOptions("Totems", 12) or nil,
						RuneBar = (class == "DEATHKNIGHT" or class == "DEATH KNIGHT") and module:CreateBarOptions("Runes", 13) or nil,
						HolyPower = (class == "PALADIN") and module:CreateBarOptions("HolyPower", 14) or nil,
						SoulShards = (class == "WARLOCK") and module:CreateBarOptions("SoulShards", 15) or nil,
						Eclipse = (class == "DRUID") and module:CreateBarOptions("Eclipse", 16) or nil,
						Swing = module:CreateBarOptions("Swing", 17),
						Vengeance = (class == "DRUID" or class == "WARRIOR" or class == "PALADIN" or class == "DEATHKNIGHT" or class == "DEATH KNIGHT") and module:CreateBarOptions("Vengeance", 18) or nil,
						AltPower = {
							name = "Alternate Power",
							type = "group",
							order = 19,
							args = {
								Enable = LUI:NewToggle("Enable", "Whether you want to show the Alternate Power Bar or not.", 1, db.oUF.Player.AltPower, "Enable", LUI.defaults.profile.oUF.Player.AltPower, ToggleAltPower),
								General = {
									name = "Settings",
									type = "group",
									guiInline = true,
									order = 2,
									args = {
										OverPower = LUI:NewToggle("Over Power Bar", "Whether you want the Alternate Power Bar to take up halt the Power bar or not.\n\nNote: This option disables the OverPower option of the Druid Mana Bar.", 1, db.oUF.Player.AltPower, "OverPower", LUI.defaults.profile.oUF.Player.AltPower, StyleAltPower),
										Height = LUI:NewHeight("Alternate Power Bar", 2, db.oUF.Player.AltPower, nil, LUI.defaults.profile.oUF.Player.AltPower, StyleAltPower),
										Padding = LUI:NewPadding("Power & Alternate Power Bar", 3, db.oUF.Player.AltPower, nil, LUI.defaults.profile.oUF.Player.AltPower, StyleAltPower),
									},
								},
								Colors = {
									name = "Color Settings",
									type = "group",
									disabled = function() return not db.oUF.Player.AltPower.Enable end,
									guiInline = true,
									order = 3,
									args = {
										ColorType = LUI:NewSelect("Color", "Choose the Color Option for the Alternate Power Bar", 1, {"By Class", "By Type", "Individual"}, nil, db.oUF.Player.AltPower, "Color", LUI.defaults.profile.oUF.Player.AltPower, StyleAltPower),
										IndividualColor = LUI:NewColorNoAlpha("Alternate Power Bar", nil, 2, db.oUF.Player.AltPower.IndividualColor, LUI.defaults.profile.oUF.Player.AltPower.IndividualColor, ApplySettings, nil, function() return (db.oUF.Player.AltPower.Color ~= "Individual") end),
									},
								},
								Textures = {
									name = "Texture Settings",
									type = "group",
									disabled = function() return not db.oUF.Player.AltPower.Enable end,
									guiInline = true,
									order = 4,
									args = {
										Texture = LUI:NewSelect("Texture", "Choose the Alternate Power Bar Texture.", 1, widgetLists.statusbar, "LSM30_Statusbar", db.oUF.Player.AltPower, "Texture", LUI.defaults.profile.oUF.Player.AltPower, ApplySettings),
										TextureBG = LUI:NewSelect("Background Texture", "Choose the Alternate Power Bar Background Texture.", 2, widgetLists.statusbar, "LSM30_Statusbar", db.oUF.Player.AltPower, "TextureBG", LUI.defaults.profile.oUF.Player.AltPower, ApplySettings),
										BGAlpha = LUI:NewSlider("Background Alpha", "Choose the Alpha Value for your Alternate Power Bar Background.", 3, db.oUF.Player.AltPower, "BGAlpha", LUI.defaults.profile.oUF.Player.AltPower, 0, 1, 0.05, ApplySettings),
										BGMultiplier = LUI:NewSlider("Background Multiplier", "Choose the Multiplier which will be used to generate the Background Color", 4, db.oUF.Player.AltPower, "BGMultiplier", LUI.defaults.profile.oUF.Player.AltPower, 0, 1, 0.05, ApplySettings),
									},
								},
							},
						},
					},
				},
				Texts = {
					args = {
						DruidMana = (class == "DRUID") and {
							name = "Druid Mana",
							type = "group",
							order = 9,
							args = {
								Enable = LUI:NewToggle("Enable", "Whether you want to show your Druid Mana Value while in Cat/Bear or not.", 1, db.oUF.Player.Texts.DruidMana, "Enable", LUI.defaults.profile.oUF.Player.Texts.DruidMana, ToggleDruidManaText),
								FontSettings = {
									name = "Font Settings",
									type = "group",
									disabled = function() return not db.oUF.Player.Texts.DruidMana.Enable end,
									guiInline = true,
									order = 2,
									args = {
										FontSize = LUI:NewSlider("Size", "Choose the Druid Mana Fontsize.", 1, db.oUF.Player.Texts.DruidMana, "Size", LUI.defaults.profile.oUF.Player.Texts.DruidMana, 1, 40, 1, StyleDruidMana),
										empty = LUI:NewEmpty(2),
										Font = LUI:NewSelect("Font", "Choose the Druid Mana Font.", 3, widgetLists.font, "LSM30_Font", db.oUF.Player.Texts.DruidMana, "Font", LUI.defaults.profile.oUF.Player.Texts.DruidMana, StyleDruidMana),
										FontFlag = LUI:NewSelect("Font Flag", "Choose the Druid Mana Font Flag.", 4, fontflags, nil, db.oUF.Player.Texts.DruidMana, "Outline", LUI.defaults.profile.oUF.Player.Texts.DruidMana, StyleDruidMana),
										XValue = LUI:NewPosX("Druid Mana", 5, db.oUF.Player.Texts.DruidMana, "", LUI.defaults.profile.oUF.Player.Texts.DruidMana, StyleDruidMana),
										YValue = LUI:NewPosY("Druid Mana", 6, db.oUF.Player.Texts.DruidMana, "", LUI.defaults.profile.oUF.Player.Texts.DruidMana, StyleDruidMana),
										Point = LUI:NewSelect("Point", "Choose the Point for your Druid Mana Text.", 7, positions, nil, db.oUF.Player.Texts.DruidMana, "Point", LUI.defaults.profile.oUF.Player.Texts.DruidMana, StyleDruidMana),
										RelativePoint = LUI:NewSelect("Relative Point", "Choose the Relative Point for your Druid Mana Text.", 8, positions, nil, db.oUF.Player.Texts.DruidMana, "RelativePoint", LUI.defaults.profile.oUF.Player.Texts.DruidMana, StyleDruidMana),
									},
								},
								Settings = {
									name = "Settings",
									type = "group",
									disabled = function() return not db.oUF.Player.Texts.DruidMana.Enable end,
									guiInline = true,
									order = 3,
									args = {
										Format = LUI:NewSelect("Format", "Choose the Format for the Druid Mana Text.", 1, valueFormat, nil, db.oUF.Player.Texts.DruidMana, "Format", LUI.defaults.profile.oUF.Player.Texts.DruidMana, StyleDruidMana),
										empty = LUI:NewEmpty(2),
										HideIfFullMana = LUI:NewToggle("Hide if Full Mana", "Whether you want to hide the Druid Mana Text when you have full Mana or not.", 3, db.oUF.Player.Texts.DruidMana, "HideIfFullMana", LUI.defaults.profile.oUF.Player.Texts.DruidMana, StyleDruidMana),
									},
								},
								Colors = {
									name = "Color Settings",
									type = "group",
									disabled = function() return not db.oUF.Player.Texts.DruidMana.Enable end,
									guiInline = true,
									order = 4,
									args = {
										ColorType = LUI:NewSelect("Color", "Choose the Color Option for the Druid Mana Text", 1, {"By Class", "By Type", "Individual"}, nil, db.oUF.Player.Texts.DruidMana, "Color", LUI.defaults.profile.oUF.Player.Texts.DruidMana, StyleDruidMana),
										IndividualColor = LUI:NewColorNoAlpha("Druid Mana Text", "Druid Mana Text", 2, db.oUF.Player.Texts.DruidMana.IndividualColor, LUI.defaults.profile.oUF.Player.Texts.DruidMana.IndividualColor, StyleDruidMana, "full", function() return (db.oUF.Player.Texts.DruidMana.Color ~= "Individual") end),
									},
								},
							},
						} or nil,
						PvPTimer = {
							name = "PvP Timer",
							type = "group",
							disabled = function() return not db.oUF.Player.Icons.PvP.Enable end,
							order = 10,
							args = {
								Enable = LUI:NewToggle("Enable", "Whether you want to show a timer next to your PvP Icon when you're pvp flagged or not.", 1, db.oUF.Player.Texts.PvP, "Enable", LUI.defaults.profile.oUF.Player.Texts.PvP, StylePvP),
								Settings = {
									name = "Settings",
									type = "group",
									disabled = function() return not db.oUF.Player.Texts.PvP.Enable end,
									guiInline = true,
									order = 2,
									args = {
										XValue = LUI:NewPosX("PvP Timer", 1, db.oUF.Player.Texts.PvP, "", LUI.defaults.profile.oUF.Player.Texts.PvP, StylePvP),
										YValue = LUI:NewPosY("PvP Timer", 2, db.oUF.Player.Texts.PvP, "", LUI.defaults.profile.oUF.Player.Texts.PvP, StylePvP),
										Font = LUI:NewSelect("Font", "Choose the PvP Timer Font.", 3, widgetLists.font, "LSM30_Font", db.oUF.Player.Texts.PvP, "Font", LUI.defaults.profile.oUF.Player.Texts.PvP, StylePvP),
										FontFlag = LUI:NewSelect("Font Flag", "Choose the PvP Timer Font Flag.", 4, fontflags, nil, db.oUF.Player.Texts.PvP, "Outline", LUI.defaults.profile.oUF.Player.Texts.PvP, StylePvP),
										FontSize = LUI:NewSlider("Size", "Choose the PvP Timer Fontsize.", 5, db.oUF.Player.Texts.PvP, "Size", LUI.defaults.profile.oUF.Player.Texts.PvP, 1, 40, 1, StylePvP),
										Color = LUI:NewColorNoAlpha("Individual", "PvP Timer", 6, db.oUF.Player.Texts.PvP.Color, LUI.defaults.profile.oUF.Player.Texts.PvP.Color, StylePvP),
									},
								},
							},
						},
						Vengeance = (class == "DRUID" or class == "WARRIOR" or class == "PALADIN" or class == "DEATHKNIGHT" or class == "DEATH KNIGHT") and module:CreateBarTextOptions("Vengeance", 11) or nil,
						Swing = module:CreateBarTextOptions("Swing", 12),
						Eclipse = (class == "DRUID") and module:CreateBarTextOptions("Eclipse", 13) or nil,
						AltPower = module:CreateBarTextOptions("AltPower", 14),
					},
				},
				Castbar = {
					args = {
						CastbarColors = {
							args = {
								Colors = {
									args = {
										CBLatencyColor = LUI:NewColor("Castbar Latency Color", nil, 5, db.oUF.Player.Castbar.Colors.Latency, LUI.defaults.profile.oUF.Player.Castbar.Colors.Latency, oUF_LUI_player.StyleCastbar, nil, function() return not db.oUF.Player.Castbar.IndividualColor end)
									},
								},
							},
						},
					},
				},
				Icons = {
					args = {
						Resting = general:CreateIconOptions("Player", 6, "Resting"),
						Combat = general:CreateIconOptions("Player", 7, "Combat"),
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
