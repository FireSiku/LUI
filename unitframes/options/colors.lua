--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: colors.lua
	Description: oUF Colors Module
	Version....: 1.0
	Rev Date...: 10/10/2010
]] 

local addonname, LUI = ...
local module = LUI:Module("oUF_Colors")

local oUF = LUI.oUF

local db

local _, class = UnitClass("player")

local defaults = {
	Colors = {
		Class = {
			WARRIOR = {1, 0.78, 0.55},
			PRIEST = {0.9, 0.9, 0.9},
			DRUID = {1, 0.44, 0.15},
			HUNTER = {0.22, 0.91, 0.18},
			MAGE = {0.12, 0.58, 0.89},
			PALADIN = {0.96, 0.21, 0.73},
			SHAMAN = {0.04, 0.39, 0.98},
			WARLOCK = {0.57, 0.22, 1},
			ROGUE = {0.95, 0.86, 0.16},
			DEATHKNIGHT = {0.8, 0.1, 0.1},
		},
		Power = {
			MANA = {0.31, 0.45, 0.63},
			RAGE = {0.69, 0.31, 0.31},
			FOCUS = {0.71, 0.43, 0.27},
			ENERGY = {0.65, 0.63, 0.35},
			RUNES = {0.55, 0.57, 0.61},
			RUNIC_POWER = {0, 0.82, 1},
			AMMOSLOT = {0.8, 0.6, 0},
			FUEL = {0, 0.55, 0.5},
		},
		HolyPowerBar = {
			[1] = {0.90, 0.88, 0.06},
			[2] = {0.90, 0.88, 0.06},
			[3] = {0.90, 0.88, 0.06},
		},
		SoulShardBar = {
			[1] = {0.93, 0.93, 0.93},
			[2] = {0.93, 0.93, 0.93},
			[3] = {0.93, 0.93, 0.93},
		},
		EclipseBar = {
			Lunar = {0.3, 0.52, 0.9},
			Solar = {0.8, 0.82, 0.6},
			LunarBG = {0.15, 0.26, 0.45},
			SolarBG = {0.36, 0.36, 0.27},
		},
		Runes = {
			[1] = {0.69, 0.31, 0.31}, -- Blood Rune
			[2] = {0.33, 0.59, 0.33}, -- Unholy Rune
			[3] = {0.31, 0.45, 0.63}, -- Frost Rune
			[4] = {0.84, 0.75, 0.65}, -- Death Rune
		},
		Tapped = {0.55, 0.57, 0.61},
		Smooth = {
			0.69, 0.31, 0.31, -- Low Health
			0.69, 0.69, 0.31, -- Mid Health
			0.31, 0.69, 0.31, -- High Health
		},
		ComboPoints = {
			[1] = {0.95, 0.86, 0.16},
			[2] = {0.95, 0.86, 0.16},
			[3] = {0.95, 0.86, 0.16},
			[4] = {0.95, 0.86, 0.16},
			[5] = {0.95, 0.86, 0.16},
		},
		LevelDiff = {
			[1] = {0.69, 0.31, 0.31}, -- Target Level >= 5
			[2] = {0.71, 0.43, 0.27}, -- Target Level >= 3
			[3] = {0.84, 0.75, 0.65}, -- Target Level <> 2
			[4] = {0.33, 0.59, 0.33}, -- Target Level GreenQuestRange
			[5] = {0.55, 0.57, 0.61}, -- Low Level Target
		},
		TotemBar = {
			[1] = {0.752, 0.172, 0.02}, -- Fire
			[2] = {0.741, 0.580, 0.04}, -- Earth
			[3] = {0, 0.443, 0.631}, -- Water
			[4] = {0.6, 1.0, 0.945}, -- Air
		},
		CombatText = {
			DAMAGE = {0.69, 0.31, 0.31},
			CRUSHING = {0.69, 0.31, 0.31},
			CRITICAL = {0.69, 0.31, 0.31},
			GLANCING = {0.69, 0.31, 0.31},
			STANDARD = {0.84, 0.75, 0.65},
			IMMUNE = {0.84, 0.75, 0.65},
			ABSORB = {0.84, 0.75, 0.65},
			BLOCK = {0.84, 0.75, 0.65},
			RESIST = {0.84, 0.75, 0.65},
			MISS = {0.84, 0.75, 0.65},
			HEAL = {0.33, 0.59, 0.33},
			CRITHEAL = {0.33, 0.59, 0.33},
			ENERGIZE = {0.31, 0.45, 0.63},
			CRITENERGIZE = {0.31, 0.45, 0.63},
		},
	},
}

local function applyDefaults(target, source)
	if type(target) ~= "table" then target = {} end
	for k, v in pairs(source) do
		if type(v) == "table" then
			target[k] = applyDefaults(target[k], v)
		else
			target[k] = v
		end
	end
	return target
end

function module:UpdateColors()
	oUF.colors.smooth = LUI.oUF_LUI.colors.smooth or oUF.colors.smooth
	if oUF_LUI_target.CPoints then
		for i=1, 5 do
			oUF_LUI_target.CPoints[i]:SetStatusBarColor(unpack(LUI.oUF_LUI.colors.combopoints[i]))
			if db.oUF.Target.ComboPoints.BackgroundColor.Enable == false then
				local mu = db.oUF.Target.ComboPoints.Multiplier
				local r, g, b = unpack(LUI.oUF_LUI.colors.combopoints[i])
				oUF_LUI_target.CPoints[i].bg:SetVertexColor(r*mu, g*mu, b*mu)
			end
		end
	end
	if oUF_LUI_player.HolyPower then
		for i=1, 3 do
			oUF_LUI_player.HolyPower[i]:SetStatusBarColor(unpack(LUI.oUF_LUI.colors.holypowerbar[i]))
		end
	end
	if oUF_LUI_player.SoulShards then
		for i=1, 3 do
			oUF_LUI_player.SoulShards[i]:SetStatusBarColor(unpack(LUI.oUF_LUI.colors.soulshardbar[i]))
		end
	end
	for k, obj in pairs(oUF.objects) do
		obj:UpdateAllElements()
	end
end

function module:CreateClassColorOption(class, index)
	local class2 = strupper(class)
	
	local options = {
		name = class,
		desc = "Choose the Color for the "..class.." class.",
		type = "color",
		hasAlpha = false,
		get = function() return unpack(db.oUF.Colors.Class[class2]) end,
		set = function(_, r, g, b)
				db.oUF.Colors.Class[class2] = {r, g, b}
				module:UpdateColors()
			end,
		order = index,
	}
	
	return options
end

function module:CreatePowerColorOption(power, index)
	local power2 = (power == "RunicPower") and "RUNIC_POWER" or strupper(power)
	
	local options = {
		name = power,
		desc = "Choose the Color for "..power..".",
		type = "color",
		hasAlpha = false,
		get = function() return unpack(db.oUF.Colors.Power[power2]) end,
		set = function(_, r, g, b)
				db.oUF.Colors.Power[power2] = {r, g, b}
				module:UpdateColors()
			end,
		order = index,
	}
	
	return options
end

function module:CreateCombatTextColorOption(name, desc, key, index)
	local options = {
		name = name,
		desc = "Choose the Color for "..desc.." events.",
		type = "color",
		hasAlpha = false,
		get = function() return unpack(db.oUF.Colors.CombatText[key]) end,
		set = function(_, r, g, b)
				db.oUF.Colors.CombatText[key] = {r, g, b}
				module:UpdateColors()
			end,
		order = index,
	}
	
	return options
end

function module:LoadOptions()
	local options = {
		Colors = {
			name = "Colors",
			type = "group",
			childGroups = "tab",
			disabled = function() return not db.oUF.Settings.Enable end,
			order = 4,
			args = {
				ClassColors = {
					name = "Class",
					type = "group",
					order = 1,
					args = {
						header1 = LUI:NewHeader("Class Colors", 1),
						Warrior = module:CreateClassColorOption("Warrior", 2),
						Priest = module:CreateClassColorOption("Priest", 3),
						Druid = module:CreateClassColorOption("Druid", 4),
						Hunter = module:CreateClassColorOption("Hunter", 5),
						Mage = module:CreateClassColorOption("Mage", 6),
						Paladin = module:CreateClassColorOption("Paladin", 7),
						Shaman = module:CreateClassColorOption("Shaman", 8),
						Warlock = module:CreateClassColorOption("Warlock", 9),
						Rogue = module:CreateClassColorOption("Rogue", 10),
						DeathKnight = module:CreateClassColorOption("DeathKnight", 11),
						empty = LUI:NewEmpty(12),
						Reset = LUI:NewExecute("Restore Defaults", nil, 13, function()
							db.oUF.Colors.Class = applyDefaults(db.oUF.Colors.Class, LUI.defaults.profile.oUF.Colors.Class)
							module:UpdateColors()
						end),
					},
				},
				PowerType = {
					name = "Power",
					type = "group",
					order = 2,
					args = {
						header1 = LUI:NewHeader("Power Colors", 1),
						Mana = module:CreatePowerColorOption("Mana", 2),
						Rage = module:CreatePowerColorOption("Rage", 3),
						Focus = module:CreatePowerColorOption("Focus", 4),
						Energy = module:CreatePowerColorOption("Energy", 5),
						Runes = module:CreatePowerColorOption("Runes", 6),
						RunicPower = module:CreatePowerColorOption("RunicPower", 7),
						AmmoSlot = module:CreatePowerColorOption("AmmoSlot", 8),
						Fuel = module:CreatePowerColorOption("Fuel", 9),
						empty = LUI:NewEmpty(10),
						Reset = LUI:NewExecute("Restore Defaults", nil, 11, function()
							db.oUF.Colors.Power = applyDefaults(db.oUF.Colors.Power, LUI.defaults.profile.oUF.Colors.Power)
							module:UpdateColors()
						end),
					},
				},
				HealthGradient = {
					name = "Health Gradient",
					type = "group",
					order = 3,
					args = {
						header1 = LUI:NewHeader("Health Gradient Colors", 1),
						-- Health Gradient is a little bit different, so i didnt change it to DevApi
						EmptyHP = {
							name = "Empty (Bad!)",
							desc = "Choose an individual Color for Empty HP.",
							type = "color",
							width = "full",
							hasAlpha = false,
							get = function()
								local r,g,b = select(1, unpack(db.oUF.Colors.Smooth))
								return r,g,b
							end,
							set = function(_,r,g,b)
								local r1,g1,b1,r2,g2,b2,r3,g3,b3 = unpack(db.oUF.Colors.Smooth)
								db.oUF.Colors.Smooth = {r,g,b,r2,g2,b2,r3,g3,b3}
								module:UpdateColors()
							end,
							order = 2,
						},
						OKHP = {
							name = "Half (OK!)",
							desc = "Choose an individual Color for Half HP.",
							type = "color",
							width = "full",
							hasAlpha = false,
							get = function()
								local r,g,b = select(4, unpack(db.oUF.Colors.Smooth))
								return r,g,b
							end,
							set = function(_,r,g,b)
								local r1,g1,b1,r2,g2,b2,r3,g3,b3 = unpack(db.oUF.Colors.Smooth)
								db.oUF.Colors.Smooth = {r1,g1,b1,r,g,b,r3,g3,b3}
								module:UpdateColors()
							end,
							order = 3,
						},
						FullHP = {
							name = "Full (Good!)",
							desc = "Choose an individual Color for Full HP.",
							type = "color",
							width = "full",
							hasAlpha = false,
							get = function()
								local r,g,b = select(7, unpack(db.oUF.Colors.Smooth))
								return r,g,b
							end,
							set = function(_,r,g,b)
								local r1,g1,b1,r2,g2,b2,r3,g3,b3 = unpack(db.oUF.Colors.Smooth)
								db.oUF.Colors.Smooth = {r1,g1,b1,r2,g2,b2,r,g,b}
								module:UpdateColors()
							end,
							order = 4,
						},
						empty = LUI:NewEmpty(5),
						Reset = LUI:NewExecute("Restore Defaults", nil, 6, function()
							db.oUF.Colors.Smooth = applyDefaults(db.oUF.Colors.Smooth, LUI.defaults.profile.oUF.Colors.Smooth)
							module:UpdateColors()
						end),
					},
				},
				CombatText = {
					name = "CombatText",
					type = "group",
					order = 4,
					args = {
						Damage = {
							name = "Damage",
							type = "group",
							inline = true,
							order = 1,
							args = {
								Damage = module:CreateCombatTextColorOption("Normal", "normal damage events", "DAMAGE", 1),
								Crit = module:CreateCombatTextColorOption("Crit", "critical damage events", "CRITICAL", 2),
								Crushing = module:CreateCombatTextColorOption("Crushing", "crushing damage events", "CRUSHING", 3),
								Glancing = module:CreateCombatTextColorOption("Glancing", "glancing damage events", "GLANCING", 4),
								Absorb = module:CreateCombatTextColorOption("Absorb", "absorb events", "ABSORB", 5),
								Block = module:CreateCombatTextColorOption("Block", "block events", "BLOCK", 6),
								Resist = module:CreateCombatTextColorOption("Resist", "resist events", "RESIST", 7),
								Miss = module:CreateCombatTextColorOption("Miss", "miss events", "MISS", 8)
							},
						},
						Heal = {
							name = "Heal",
							type = "group",
							inline = true,
							order = 2,
							args = {
								Damage = module:CreateCombatTextColorOption("Normal", "normal heal events", "HEAL", 1),
								Crit = module:CreateCombatTextColorOption("Crit", "critical heal events", "CRITHEAL", 2)
							},
						},
						Other = {
							name = "Other",
							type = "group",
							inline = true,
							order = 3,
							args = {
								Immune = module:CreateCombatTextColorOption("Immune", "immune events", "IMMUNE", 1),
								Energize = module:CreateCombatTextColorOption("Energize", "energize events", "ENERGIZE", 2),
								CritEnergize = module:CreateCombatTextColorOption("Crit Energize", "crit energize events", "CRITENERGIZE", 3),
								Other = module:CreateCombatTextColorOption("Other", "other events", "STANDARD", 4)
							},
						},
						empty = LUI:NewEmpty(4),
						Reset = LUI:NewExecute("Restore Defaults", nil, 5, function()
							db.oUF.Colors.CombatText = applyDefaults(db.oUF.Colors.CombatText, LUI.defaults.profile.oUF.Colors.CombatText)
							module:UpdateColors()
						end),
					},
				},
				Other = {
					name = "Other",
					type = "group",
					order = 5,
					args = {
						Runes = {
							name = "Rune Colors",
							type = "group",
							inline = true,
							hidden = class ~= "DEATHKNIGHT",
							order = 2,
							args = {
								Blood = {
									name = "Blood",
									desc = "Choose an individual Color for Blood.",
									type = "color",
									width = "full",
									hasAlpha = false,
									get = function() return unpack(db.oUF.Colors.Runes[1]) end,
									set = function(_,r,g,b)
										db.oUF.Colors.Runes[1] = {r,g,b}
										module:UpdateColors()
									end,
									order = 1,
								},
								Frost = {
									name = "Frost",
									desc = "Choose an individual Color for Frost.",
									type = "color",
									width = "full",
									hasAlpha = false,
									get = function() return unpack(db.oUF.Colors.Runes[3]) end,
									set = function(_,r,g,b)
										db.oUF.Colors.Runes[3] = {r,g,b}
										module:UpdateColors()
									end,
									order = 2,
								},
								Unholy = {
									name = "Unholy",
									desc = "Choose an individual Color for Unholy.",
									type = "color",
									width = "full",
									hasAlpha = false,
									get = function() return unpack(db.oUF.Colors.Runes[2]) end,
									set = function(_,r,g,b)
										db.oUF.Colors.Runes[2] = {r,g,b}
										module:UpdateColors()
									end,
									order = 3,
								},
								Death = {
									name = "Death",
									desc = "Choose an individual Color for Death.",
									type = "color",
									width = "full",
									hasAlpha = false,
									get = function() return unpack(db.oUF.Colors.Runes[4]) end,
									set = function(_,r,g,b)
										db.oUF.Colors.Runes[4] = {r,g,b}
										module:UpdateColors()
									end,
									order = 4,
								},
							},
						},
						ComboPoints = {
							name = "ComboPoint Colors",
							type = "group",
							inline = true,
							order = 3,
							args = {
								Combo1 = {
									name = "CP 1",
									desc = "Choose an individual Color for your 1st ComboPoint.",
									type = "color",
									width = "full",
									hasAlpha = false,
									get = function() return unpack(db.oUF.Colors.ComboPoints[1]) end,
									set = function(_,r,g,b)
										db.oUF.Colors.ComboPoints[1] = {r,g,b}
										module:UpdateColors()
									end,
									order = 1,
								},
								Combo2 = {
									name = "CP 2",
									desc = "Choose an individual Color for your 2nd ComboPoint.",
									type = "color",
									width = "full",
									hasAlpha = false,
									get = function() return unpack(db.oUF.Colors.ComboPoints[2]) end,
									set = function(_,r,g,b)
										db.oUF.Colors.ComboPoints[2] = {r,g,b}
										module:UpdateColors()
									end,
									order = 2,
								},
								Combo3 = {
									name = "CP 3",
									desc = "Choose an individual Color for your 3rd ComboPoint.",
									type = "color",
									width = "full",
									hasAlpha = false,
									get = function() return unpack(db.oUF.Colors.ComboPoints[3]) end,
									set = function(_,r,g,b)
										db.oUF.Colors.ComboPoints[3] = {r,g,b}
										module:UpdateColors()
									end,
									order = 3,
								},
								Combo4 = {
									name = "CP 4",
									desc = "Choose an individual Color for your 4rd ComboPoint.",
									type = "color",
									width = "full",
									hasAlpha = false,
									get = function() return unpack(db.oUF.Colors.ComboPoints[4]) end,
									set = function(_,r,g,b)
										db.oUF.Colors.ComboPoints[4] = {r,g,b}
										module:UpdateColors()
									end,
									order = 4,
								},
								Combo5 = {
									name = "CP 5",
									desc = "Choose an individual Color for your 5th ComboPoint.",
									type = "color",
									width = "full",
									hasAlpha = false,
									get = function() return unpack(db.oUF.Colors.ComboPoints[5]) end,
									set = function(_,r,g,b)
										db.oUF.Colors.ComboPoints[5] = {r,g,b}
										module:UpdateColors()
									end,
									order = 5,
								},
							},
						},
						Totems = {
							name = "TotemBar Colors",
							type = "group",
							inline = true,
							hidden = class ~= "SHAMAN",
							order = 4,
							args = {
								TotemFire = {
									name = "Fire",
									desc = "Choose an individual Color for your Fire Totems.",
									type = "color",
									width = "full",
									hasAlpha = false,
									get = function() return unpack(db.oUF.Colors.TotemBar[1]) end,
									set = function(_,r,g,b)
										db.oUF.Colors.TotemBar[1] = {r,g,b}
										module:UpdateColors()
									end,
									order = 1,
								},
								TotemEarth = {
									name = "Earth",
									desc = "Choose an individual Color for your Earth Totems.",
									type = "color",
									width = "full",
									hasAlpha = false,
									get = function() return unpack(db.oUF.Colors.TotemBar[2]) end,
									set = function(_,r,g,b)
										db.oUF.Colors.TotemBar[2] = {r,g,b}
										module:UpdateColors()
									end,
									order = 2,
								},
								TotemWater = {
									name = "Water",
									desc = "Choose an individual Color for your Water Totems.",
									type = "color",
									width = "full",
									hasAlpha = false,
									get = function() return unpack(db.oUF.Colors.TotemBar[3]) end,
									set = function(_,r,g,b)
										db.oUF.Colors.TotemBar[3] = {r,g,b}
										module:UpdateColors()
									end,
									order = 3,
								},
								TotemAir = {
									name = "Air",
									desc = "Choose an individual Color for your Air Totems.",
									type = "color",
									width = "full",
									hasAlpha = false,
									get = function() return unpack(db.oUF.Colors.TotemBar[4]) end,
									set = function(_,r,g,b)
										db.oUF.Colors.TotemBar[4] = {r,g,b}
										module:UpdateColors()
									end,
									order = 4,
								},
							},
						},
						LevelDiff = {
							name = "Level Difficulty Colors",
							type = "group",
							inline = true,
							order = 5,
							args = {
								LevelDiff1 = {
									name = "Target Level >= 5",
									desc = "Color for when your Target's Level is 5 or more Levels higher than yours.",
									type = "color",
									width = "full",
									hasAlpha = false,
									get = function() return unpack(db.oUF.Colors.LevelDiff[1]) end,
									set = function(_,r,g,b)
										db.oUF.Colors.LevelDiff[1] = {r,g,b}
										module:UpdateColors()
									end,
									order = 1,
								},
								LevelDiff2 = {
									name = "Target Level >= 3",
									desc = "Color for when your Target's Level is 3 - 4 Levels higher than yours.",
									type = "color",
									width = "full",
									hasAlpha = false,
									get = function() return unpack(db.oUF.Colors.LevelDiff[2]) end,
									set = function(_,r,g,b)
										db.oUF.Colors.LevelDiff[2] = {r,g,b}
										module:UpdateColors()
									end,
									order = 2,
								},
								LevelDiff3 = {
									name = "Target Level <> 2",
									desc = "Color for when your Target's Level is within 2 Levels of yours.",
									type = "color",
									width = "full",
									hasAlpha = false,
									get = function() return unpack(db.oUF.Colors.LevelDiff[3]) end,
									set = function(_,r,g,b)
										db.oUF.Colors.LevelDiff[3] = {r,g,b}
										module:UpdateColors()
									end,
									order = 3,
								},
								LevelDiff4 = {
									name = "Target Level is in Green QuestRange",
									desc = "Color for when your Target's Level is in Green QuestRange.",
									type = "color",
									width = "full",
									hasAlpha = false,
									get = function() return unpack(db.oUF.Colors.LevelDiff[4]) end,
									set = function(_,r,g,b)
										db.oUF.Colors.LevelDiff[4] = {r,g,b}
										module:UpdateColors()
									end,
									order = 4,
								},
								LevelDiff5 = {
									name = "Low Level Target",
									desc = "Color for when your Target's Level is well below yours.",
									type = "color",
									width = "full",
									hasAlpha = false,
									get = function() return unpack(db.oUF.Colors.LevelDiff[5]) end,
									set = function(_,r,g,b)
										db.oUF.Colors.LevelDiff[5] = {r,g,b}
										module:UpdateColors()
									end,
									order = 5,
								},
							},
						},
						Tapped = {
							name = "Tapped Target Colors",
							type = "group",
							inline = true,
							order = 6,
							args = {
								Tapped = {
									name = "Tapped",
									desc = "Choose an individual Color for Tapped Mobs.",
									type = "color",
									width = "full",
									hasAlpha = false,
									get = function() return unpack(db.oUF.Colors.Tapped) end,
									set = function(_,r,g,b)
										db.oUF.Colors.Tapped = {r,g,b}
										module:UpdateColors()
									end,
									order = 1,
								},
							},
						},
						HolyPower = {
							name = "Holy Power Colors",
							type = "group",
							inline = true,
							hidden = class ~= "PALADIN",
							order = 7,
							args = {
								HolyPower1 = {
									name = "Part 1",
									desc = "Choose any color for the first part of your Holy Power Bar.",
									type = "color",
									width = "full",
									hasAlpha = false,
									get = function() return unpack(db.oUF.Colors.HolyPowerBar[1]) end,
									set = function(_,r,g,b)
										db.oUF.Colors.HolyPowerBar[1] = {r,g,b}
										module:UpdateColors()
									end,
									order = 1,
								},
								HolyPower2 = {
									name = "Part 2",
									desc = "Choose any color for the second part of your Holy Power Bar.",
									type = "color",
									width = "full",
									hasAlpha = false,
									get = function() return unpack(db.oUF.Colors.HolyPowerBar[2]) end,
									set = function(_,r,g,b)
										db.oUF.Colors.HolyPowerBar[2] = {r,g,b}
										module:UpdateColors()
									end,
									order = 2,
								},
								HolyPower3 = {
									name = "Part 3",
									desc = "Choose any color for the third part of your Holy Power Bar.",
									type = "color",
									width = "full",
									hasAlpha = false,
									get = function() return unpack(db.oUF.Colors.HolyPowerBar[3]) end,
									set = function(_,r,g,b)
										db.oUF.Colors.HolyPowerBar[3] = {r,g,b}
										module:UpdateColors()
									end,
									order = 3,
								},
							},
						},
						SoulShards = {
							name = "Soul Shards",
							type = "group",
							inline = true,
							hidden = class ~= "WARLOCK",
							order = 8,
							args = {
								SoulShard1 = {
									name = "Shard 1",
									desc = "Choose any color for the first Part of your Sould Shard Bar.",
									type = "color",
									width = "full",
									hasAlpha = false,
									get = function() return unpack(db.oUF.Colors.SoulShardBar[1]) end,
									set = function(_,r,g,b)
										db.oUF.Colors.SoulShardBar[1] = {r,g,b}
										module:UpdateColors()
									end,
									order = 1,
								},
								SoulShard2 = {
									name = "Shard 2",
									desc = "Choose any color for the second Part of your Sould Shard Bar.",
									type = "color",
									width = "full",
									hasAlpha = false,
									get = function() return unpack(db.oUF.Colors.SoulShardBar[2]) end,
									set = function(_,r,g,b)
										db.oUF.Colors.SoulShardBar[2] = {r,g,b}
										module:UpdateColors()
									end,
									order = 2,
								},
								SoulShard3 = {
									name = "Shard 3",
									desc = "Choose any color for the third Part of your Sould Shard Bar.",
									type = "color",
									width = "full",
									hasAlpha = false,
									get = function() return unpack(db.oUF.Colors.SoulShardBar[3]) end,
									set = function(_,r,g,b)
										db.oUF.Colors.SoulShardBar[3] = {r,g,b}
										module:UpdateColors()
									end,
									order = 3,
								},
							},
						},
						Eclipse = {
							name = "Eclipse",
							type = "group",
							inline = true,
							hidden = class ~= "DRUID",
							order = 9,
							args = {
								EclipseLunar = {
									name = "Lunar",
									desc = "Choose any color for the Lunar Part of your Eclipse Bar.",
									type = "color",
									width = "full",
									hasAlpha = false,
									get = function() return unpack(db.oUF.Colors.EclipseBar.Lunar) end,
									set = function(_,r,g,b)
										db.oUF.Colors.EclipseBar.Lunar = {r,g,b}
										module:UpdateColors()
									end,
									order = 1,
								},
								EclipseLunarBG = {
									name = "Lunar BG",
									desc = "Choose any background color for the Lunar Part of your Eclipse Bar.",
									type = "color",
									width = "full",
									hasAlpha = false,
									get = function() return unpack(db.oUF.Colors.EclipseBar.LunarBG) end,
									set = function(_,r,g,b)
										db.oUF.Colors.EclipseBar.LunarBG = {r,g,b}
										module:UpdateColors()
									end,
									order = 2,
								},
								EclipseSolar = {
									name = "Solar",
									desc = "Choose any color for the Solar Part of your Eclipse Bar.",
									type = "color",
									width = "full",
									hasAlpha = false,
									get = function() return unpack(db.oUF.Colors.EclipseBar.Solar) end,
									set = function(_,r,g,b)
										db.oUF.Colors.EclipseBar.Solar = {r,g,b}
										module:UpdateColors()
									end,
									order = 3,
								},
								EclipseSolarBG = {
									name = "Solar BG",
									desc = "Choose any background color for the Solar Part of your Eclipse Bar.",
									type = "color",
									width = "full",
									hasAlpha = false,
									get = function() return unpack(db.oUF.Colors.EclipseBar.SolarBG) end,
									set = function(_,r,g,b)
										db.oUF.Colors.EclipseBar.SolarBG = {r,g,b}
										module:UpdateColors()
									end,
									order = 4,
								},
							},
						},
						empty = {
							name = "   ",
							type = "description",
							width = "full",
							order = 10,
						},
						Reset = {
							name = "Restore Defaults",
							type = "execute",
							order = 11,
							func = function()
								db.oUF.Colors.Runes = applyDefaults(db.oUF.Colors.Runes, LUI.defaults.profile.oUF.Colors.Runes)
								db.oUF.Colors.ComboPoints = applyDefaults(db.oUF.Colors.ComboPoints, LUI.defaults.profile.oUF.Colors.ComboPoints)
								db.oUF.Colors.TotemBar = applyDefaults(db.oUF.Colors.TotemBar, LUI.defaults.profile.oUF.Colors.TotemBar)
								db.oUF.Colors.LevelDiff = applyDefaults(db.oUF.Colors.LevelDiff, LUI.defaults.profile.oUF.Colors.LevelDiff)
								db.oUF.Colors.Tapped = applyDefaults(db.oUF.Colors.Tapped, LUI.defaults.profile.oUF.Colors.Tapped)
								db.oUF.Colors.HolyPowerBar = applyDefaults(db.oUF.Colors.HolyPowerBar, LUI.defaults.profile.oUF.Colors.HolyPowerBar)
								db.oUF.Colors.SoulShardBar = applyDefaults(db.oUF.Colors.SoulShardBar, LUI.defaults.profile.oUF.Colors.SoulShardBar)
								db.oUF.Colors.EclipseBar = applyDefaults(db.oUF.Colors.EclipseBar, LUI.defaults.profile.oUF.Colors.EclipseBar)
								module:UpdateColors()
							end,
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