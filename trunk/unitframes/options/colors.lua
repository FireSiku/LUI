--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: colors.lua
	Description: oUF Colors
]] 

local addonname, LUI = ...
local module = LUI:Module("Unitframes")
local oUF = LUI.oUF

local _, class = UnitClass("player")

module.defaults.profile.Colors = {
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
		MONK = {0.00, 1.00, 0.59},
		DEMONHUNTER = {0.64, 0.19, 0.79},
	},
	--[[ This section shows the actual real Blizzard colors.
	     Some people have asked for them so making it easier
		 for those people to use them.
	Class = {
		WARRIOR = {0.78, 0.61, 0.43},
		PRIEST = {1.00, 1.00, 1.00},
		DRUID = {1.00, 0.49, 0.04},
		HUNTER = {0.67, 0.83, 0.45},
		MAGE = {0.41, 0.80, 0.94},
		PALADIN = {0.96, 0.55, 0.73},
		SHAMAN = {0.00, 0.44, 0.87},
		WARLOCK = {0.58, 0.51, 0.79},
		ROGUE = {1.00, 0.96, 0.41},
		DEATHKNIGHT = {0.77, 0.12, 0.23},
		MONK = {0.00, 1.00, 0.59},
	},]]--
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
	Smooth = {
		[1] = {0.69, 0.31, 0.31}, -- Low Health
		[2] = {0.69, 0.69, 0.31}, -- Mid Health
		[3] = {0.31, 0.69, 0.31}, -- High Health
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
	--merker
	HolyPowerBar = {
		[1] = {0.90, 0.88, 0.06},
		[2] = {0.90, 0.88, 0.06},
		[3] = {0.90, 0.88, 0.06},
		[4] = {0.90, 0.88, 0.06},
		[5] = {0.90, 0.88, 0.06},
	},
	ArcaneChargesBar = {
		[1] = {0.12, 0.58, 0.89},
		[2] = {0.12, 0.58, 0.89},
		[3] = {0.12, 0.58, 0.89},
		[4] = {0.12, 0.58, 0.89},
		[5] = {0.12, 0.58, 0.89},
		[6] = {0.12, 0.58, 0.89},
	},
	ChiBar = {
		[1] = {0.00, 1.00, 0.59},
		[2] = {0.00, 1.00, 0.59},
		[3] = {0.00, 1.00, 0.59},
		[4] = {0.00, 1.00, 0.59},
		[5] = {0.00, 1.00, 0.59},
		[6] = {0.00, 1.00, 0.59},
	},
	WarlockBar = {
		["Fury"] = {0.8, 0.1, 0.1},
		["Shard1"] = {0.57, 0.22, 1},
		["Shard2"] = {0.57, 0.22, 1},
		["Shard3"] = {0.57, 0.22, 1},
		["Shard4"] = {0.57, 0.22, 1},
		["Ember1"] = {0.69, 0.31, 0.31},
		["Ember2"] = {0.69, 0.31, 0.31},
		["Ember3"] = {0.69, 0.31, 0.31},
		["Ember4"] = {0.69, 0.31, 0.31},
	},
	ShadowOrbsBar = {
		[1] = {0.93, 0.93, 0.93},
		[2] = {0.93, 0.93, 0.93},
		[3] = {0.93, 0.93, 0.93},
		[4] = {0.93, 0.93, 0.93},
		[5] = {0.93, 0.93, 0.93},
	},
	EclipseBar = {
		Lunar = {0.3, 0.52, 0.9},
		LunarBG = {0.15, 0.26, 0.45},
		Solar = {0.8, 0.82, 0.6},
		SolarBG = {0.36, 0.36, 0.27},
	},
	Runes = {
		[1] = {0.84, 0.75, 0.65}, -- Death Rune
	},
	ComboPoints = {
		[1] = {0.95, 0.86, 0.16},
		[2] = {0.95, 0.86, 0.16},
		[3] = {0.95, 0.86, 0.16},
		[4] = {0.95, 0.86, 0.16},
		[5] = {0.95, 0.86, 0.16},
	},
	Totems = {
		[1] = {0.752, 0.172, 0.02}, -- Fire
		[2] = {0.741, 0.580, 0.04}, -- Earth
		[3] = {0, 0.443, 0.631}, -- Water
		[4] = {0.6, 1.0, 0.945}, -- Air
	},
	LevelDiff = {
		[1] = {0.69, 0.31, 0.31}, -- Target Level >= 5
		[2] = {0.71, 0.43, 0.27}, -- Target Level >= 3
		[3] = {0.84, 0.75, 0.65}, -- Target Level <> 2
		[4] = {0.33, 0.59, 0.33}, -- Target Level GreenQuestRange
		[5] = {0.55, 0.57, 0.61}, -- Low Level Target
	},
	Misc = {
		Tapped = {0.7, 0.7, 0.7},
		Hostile = {0.7, 0.3, 0.3},
		Neutral = {0.7, 0.7, 0.3},
		Friendly = {0.3, 0.7, 0.3},
	},
}

module.colors = setmetatable({
	power = setmetatable({
		["POWER_TYPE_STEAM"] = {0.55, 0.57, 0.61},
		["POWER_TYPE_PYRITE"] = {0.60, 0.09, 0.17},
	}, {
		__index = function(t, k)
			return module.db.Colors.Power[k] or oUF.colors.power[k]
		end
	}),
	class = setmetatable({}, {
		__index = function(t, k)
			return module.db.Colors.Class[k] or oUF.colors.class[k] or {0.5, 0.5, 0.5, 1}
		end
	}),
	leveldiff = setmetatable({}, {
		__index = function(t, k)
			local diffColor = GetQuestDifficultyColor(UnitLevel("target"))
			return module.db.Colors.LevelDiff[k] or {diffColor.r, diffColor.g, diffColor.b}
		end
	}),
	combattext = setmetatable({}, {
		__index = function(t, k)
			return module.db.Colors.CombatText[k]
		end
	}),
	combopoints = setmetatable({}, {
		__index = function(t, k)
			return module.db.Colors.ComboPoints[k] or oUF.colors.combopoints[k]
		end
	}),
	runes = setmetatable({}, {
		__index = function(t, k)
			return module.db.Colors.Runes[k] or oUF.colors.runes[k]
		end
	}),
	totems = setmetatable({}, {
		__index = function(t, k)
			return module.db.Colors.Totems[k] or oUF.colors.totems[k]
		end
	}),
	holypowerbar = setmetatable({}, {
		__index = function(t, k)
			return module.db.Colors.HolyPowerBar[k] or oUF.colors.holypowerbar[k]
		end
	}),
	warlockbar = setmetatable({}, {
		__index = function(t, k)
			return module.db.Colors.WarlockBar[k] or oUF.colors.warlockbar[k]
		end
	}),
	shadoworbsbar = setmetatable({}, {
		__index = function(t, k)
			return module.db.Colors.ShadowOrbsBar[k] or oUF.colors.shadoworbsbar[k]
		end
	}),
	arcanechargesbar = setmetatable({}, {
		__index = function(t, k)
			return module.db.Colors.ArcaneChargesBar[k] or oUF.colors.arcanechargesbar[k]
		end
	}),
	chibar = setmetatable({}, {
		__index = function(t, k)
			return module.db.Colors.ChiBar[k] or oUF.colors.chibar[k]
		end
	}),
	eclipsebar = setmetatable({}, {
		__index = function(t, k)
			return module.db.Colors.EclipseBar[k]
		end
	}),
	smooth = setmetatable({}, {
		__index = function(t, k)
			return module.db.Colors.Smooth[math.ceil(k/3)][(k-1)%3+1]
		end,
		__call = function(t)
			return t[1], t[2], t[3], t[4], t[5], t[6], t[7], t[8], t[9]
		end
	}),
}, {
	__index = function(t, k)
		return module.db.Colors[k and (k:gsub("^%a", strupper)) or k] or oUF.colors[k]
	end
})

local function UpdateColors()
	if oUF_LUI_player.Runes then
		for i = 1, 6 do
			oUF_LUI_player.Runes[i]:SetStatusBarColor(unpack(module.colors.runes[1]))
		end
	end
	local classIcons = oUF_LUI_player.ClassIcons
	if classIcons then
		local r, g, b
		if class == "MONK" then r, g, b = unpack(module.colors.chibar[1])
		elseif class == "PALADIN" then r, g, b = unpack(module.colors.holypowerbar[1])
		elseif class == "MAGE" then r, g, b = unpack(module.colors.arcanechargesbar[1])
		elseif class == "WARLOCK" then r, g, b = unpack(module.colors.warlockbar.Shard1)
		elseif class == "ROGUE" then r, g, b = unpack(module.colors.combopoints[1])
		elseif class == "DRUID" then r, g, b = unpack(module.colors.combopoints[1])
		end
		
		classIcons:SetBackdropColor(r * 0.4, g * 0.4, b * 0.4)
		for i = 1, classIcons.MaxCount do
			classIcons[i]:SetVertexColor(r, g, b)
		end
	end
	for k, obj in pairs(oUF.objects) do
		obj:UpdateAllElements()
	end
end

local colorGetter = function(info)
	local t = module.db.Colors[info[#info-1]][tonumber(info[#info]) or info[#info]]
	if t.r then
		return t.r, t.g, t.b, t.a
	else
		return t[1], t[2], t[3], t[4]
	end
end
local colorSetter = function(info, r, g, b, a)
	local t = module.db.Colors[info[#info-1]][tonumber(info[#info]) or info[#info]]
	if t.r then
		t.r, t.g, t.b, t.a = r, g, b, a
	else
		t[1], t[2], t[3], t[4] = r, g, b, a
	end
	UpdateColors()
end

function module:CreateColorOptions(order)
	local options = self:NewGroup("Colors", order, "tab", colorGetter, colorSetter, {
		Class = self:NewGroup("Class", 1, {
			header1 = self:NewHeader("Class Colors", 1),
			WARRIOR = self:NewColorNoAlpha("Warrior", "Warrior class", 2, false, "normal"),
			PRIEST = self:NewColorNoAlpha("Priest", "Priest class", 3, false, "normal"),
			DRUID = self:NewColorNoAlpha("Druid", "Druid class", 4, false, "normal"),
			HUNTER = self:NewColorNoAlpha("Hunter", "Hunter class", 5, false, "normal"),
			MAGE = self:NewColorNoAlpha("Mage", "Mage class", 6, false, "normal"),
			PALADIN = self:NewColorNoAlpha("Paladin", "Paladin class", 7, false, "normal"),
			SHAMAN = self:NewColorNoAlpha("Shaman", "Shaman class", 8, false, "normal"),
			WARLOCK = self:NewColorNoAlpha("Warlock", "Warlock class", 9, false, "normal"),
			ROGUE = self:NewColorNoAlpha("Rogue", "Rogue class", 10, false, "normal"),
			DEATHKNIGHT = self:NewColorNoAlpha("Death Knight", "Death Knight class", 11, false, "normal"),
			MONK = self:NewColorNoAlpha("Monk", "Monk class", 12, false, "normal"),
			DEMONHUNTER = self:NewColorNoAlpha("Demon Hunter", "Demon Hunter class", 13, false, "normal"),
			empty1 = self:NewDesc(" ", 14),
			Reset = self:NewExecute("Restore Defaults", nil, 15, function()
				module.db.Colors.Class = module.defaults.Colors.Class
				UpdateColors()
			end),
		}),
		Power = self:NewGroup("Power", 2, {
			header1 = self:NewHeader("Power Colors", 1),
			MANA = self:NewColorNoAlpha("Mana", "Mana ressource", 2, false, "full"),
			RAGE = self:NewColorNoAlpha("Rage", "Rage ressource", 3, false, "full"),
			FOCUS = self:NewColorNoAlpha("Focus", "Focus ressource", 4, false, "full"),
			ENERGY = self:NewColorNoAlpha("Energy", "Energy ressource", 5, false, "full"),
			--RUNES = self:NewColorNoAlpha("Runes", "Runes ressource", 6, false, "full"),
			RUNIC_POWER = self:NewColorNoAlpha("Runic Power", "Runic Power ressource", 7, false, "full"),
			AMMOSLOT = self:NewColorNoAlpha("Ammoslot", "Ammoslot ressource", 8, false, "full"),
			FUEL = self:NewColorNoAlpha("Fuel", "Fuel ressource", 9, false, "full"),
			empty1 = self:NewDesc(" ", 10),
			Reset = self:NewExecute("Restore Defaults", nil, 11, function()
				module.db.Colors.Power = module.defaults.Colors.Power
				UpdateColors()
			end),
		}),
		Smooth = self:NewGroup("Gradient Health", 3, {
			header1 = self:NewHeader("Gradient Health Colors", 1),
			["1"] = self:NewColorNoAlpha("Low Health", nil, 2, false, "full"),
			["2"] = self:NewColorNoAlpha("Medium Health", nil, 3, false, "full"),
			["3"] = self:NewColorNoAlpha("High Health", nil, 4, false, "full"),
			empty1 = self:NewDesc(" ", 5),
			Reset = self:NewExecute("Restore Defaults", nil, 6, function()
				module.db.Colors.Smooth = module.defaults.Colors.Smooth
				UpdateColors()
			end),
		}),
		CombatText = self:NewGroup("Combat Text", 4, {
			header1 = self:NewHeader("Combat Text Colors", 1),
			DAMAGE = self:NewColorNoAlpha("Normal Damage", "normal damage events", 2, false, "full"),
			CRITICAL = self:NewColorNoAlpha("Crit Damage", "critical damage events", 3, false, "full"),
			CRUSHING = self:NewColorNoAlpha("Crushing", "crushing damage events", 4, false, "full"),
			GLANCING = self:NewColorNoAlpha("Glancing", "glancing damage events", 5, false, "full"),
			empty1 = self:NewDesc(" ", 6),
			IMMUNE = self:NewColorNoAlpha("Immune", "immune events", 7, false, "full"),
			ABSORB = self:NewColorNoAlpha("Absorb", "absorb events", 8, false, "full"),
			BLOCK = self:NewColorNoAlpha("Block", "block events", 9, false, "full"),
			RESIST = self:NewColorNoAlpha("Resist", "resist events", 10, false, "full"),
			MISS = self:NewColorNoAlpha("Miss", "miss events", 11, false, "full"),
			empty2 = self:NewDesc(" ", 12),
			HEAL = self:NewColorNoAlpha("Normal Heal", "normal heal events", 13, false, "full"),
			CRITHEAL = self:NewColorNoAlpha("Crit Heal", "critical heal events", 14, false, "full"),
			empty3 = self:NewDesc(" ", 15),
			ENERGIZE = self:NewColorNoAlpha("Energize", "normal energize events", 16, false, "full"),
			CRITENERGIZE = self:NewColorNoAlpha("Crit Energize", "critical energize events", 17, false, "full"),
			STANDARD = self:NewColorNoAlpha("Other", "Choose the Color for other events", 18, false, "full"),
			empty4 = self:NewDesc(" ", 19),
			Reset = self:NewExecute("Restore Defaults", nil, 20, function()
				module.db.Colors.CombatText = module.defaults.Colors.CombatText
				UpdateColors()
			end),
		}),
		LevelDiff = self:NewGroup("Level Difference", 5, {
			header1 = self:NewHeader("Level Difference Colors", 1),
			["1"] = self:NewColorNoAlpha("Target Level >= 5", nil, 2, false, "full"),
			["2"] = self:NewColorNoAlpha("Target Level >= 3", nil, 3, false, "full"),
			["3"] = self:NewColorNoAlpha("Target Level <> 2", nil, 4, false, "full"),
			["4"] = self:NewColorNoAlpha("Target Level <= 3", nil, 5, false, "full"),
			["5"] = self:NewColorNoAlpha("Low Level Target", nil, 6, false, "full"),
			empty1 = self:NewDesc(" ", 7),
			Reset = self:NewExecute("Restore Defaults", nil, 8, function()
				module.db.Colors.LevelDiff = module.defaults.Colors.LevelDiff
				UpdateColors()
			end),
		}),
		HolyPowerBar = self:NewGroup("Holy Power", 6, nil, nil, class ~= "PALADIN", {
			header1 = self:NewHeader("Holy Power Colors", 1),
			["1"]	= self:NewColorNoAlpha("Holy Power", "Holy Power Bar", 2, false, "full"),
			empty1 = self:NewDesc(" ", 7),
			Reset = self:NewExecute("Restore Defaults", nil, 8, function()
				module.db.Colors.HolyPowerBar = module.defaults.Colors.HolyPowerBar
				UpdateColors()
			end),
		}),
		WarlockBar = self:NewGroup("Soul Shards", 7, nil, nil, class ~= "WARLOCK", {
			header1 = self:NewHeader("Soul Shard Colors", 1),
			["Shard1"] = self:NewColorNoAlpha("Soul Shards", "Soul Shards Bar", 2, false, "full"),
			empty1 = self:NewDesc(" ", 13),
			Reset = self:NewExecute("Restore Defaults", nil, 14, function()
				module.db.Colors.WarlockBar = module.defaults.Colors.WarlockBar
				UpdateColors()
			end),
		}),
		ArcaneChargesBar = self:NewGroup("Arcane Charges", 10, nil, nil, class ~= "MAGE", {
			header1 = self:NewHeader("Arcane Charges Colors", 1),
			["1"] = self:NewColorNoAlpha("Arcane Charges", "Arcane Charges Bar", 2, false, "full"),
			empty1 = self:NewDesc(" ", 5),
			Reset = self:NewExecute("Restore Defaults", nil, 6, function()
				module.db.Colors.ArcaneChargesBar = module.defaults.Colors.ArcaneChargesBar
				UpdateColors()
			end),
		}),
		ChiBar = self:NewGroup("Chi", 10, nil, nil, class ~= "MONK", {
			header1 = self:NewHeader("Chi Colors", 1),
			["1"] = self:NewColorNoAlpha("Chi", "Chi Bar", 2, false, "full"),
			empty1 = self:NewDesc(" ", 8),
			Reset = self:NewExecute("Restore Defaults", nil, 9, function()
				module.db.Colors.ChiBar = module.defaults.Colors.ChiBar
				UpdateColors()
			end),
		}),
		Runes = self:NewGroup("Runes", 12, nil, nil, class ~= "DEATHKNIGHT" and class ~= "DEATH KNIGHT", {
			header1 = self:NewHeader("Runes Colors", 1),
			["1"] = self:NewColorNoAlpha("Death", "Runes", 5, false, "full"),
			empty1 = self:NewDesc(" ", 6),
			Reset = self:NewExecute("Restore Defaults", nil, 7, function()
				module.db.Colors.Runes = module.defaults.Colors.Runes
				UpdateColors()
			end),
		}),
		ComboPoints = self:NewGroup("Combo Points", 13, nil, nil, class ~= "ROGUE" and class ~= "DRUID", {
			header1 = self:NewHeader("Combo Points Colors", 1),
			["1"] = self:NewColorNoAlpha("Combo Points", "Combo Points Bar", 2, false, "full"),
			empty1 = self:NewDesc(" ", 7),
			Reset = self:NewExecute("Restore Defaults", nil, 8, function()
				module.db.Colors.ComboPoints = module.defaults.Colors.ComboPoints
				UpdateColors()
			end),
		}),
		Misc = self:NewGroup("Misc", 15, {
			header1 = self:NewHeader("Misc Colors", 1),
			Tapped = self:NewColorNoAlpha("Tapped", "Tapped Target", 2, false, "full"),
			Hostile = self:NewColorNoAlpha("Hostile NPC", "Hostile NPC", 3, false, "full"),
			Neutral = self:NewColorNoAlpha("Neutral NPC", "Neutral NPC", 4, false, "full"),
			Friendly = self:NewColorNoAlpha("Friendly NPC", "Friendly NPC", 5, false, "full"),
			empty1 = self:NewDesc(" ", 6),
			Reset = self:NewExecute("Restore Defaults", nil, 7, function()
				module.db.Colors.Misc = module.defaults.Colors.Misc
				UpdateColors()
			end),
		}),
		
	})
	
	return options
end
