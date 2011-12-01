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
	},
	SoulShardBar = {
		[1] = {0.93, 0.93, 0.93},
		[2] = {0.93, 0.93, 0.93},
		[3] = {0.93, 0.93, 0.93},
	},
	EclipseBar = {
		Lunar = {0.3, 0.52, 0.9},
		LunarBG = {0.15, 0.26, 0.45},
		Solar = {0.8, 0.82, 0.6},
		SolarBG = {0.36, 0.36, 0.27},
	},
	Runes = {
		[1] = {0.69, 0.31, 0.31}, -- Blood Rune
		[2] = {0.33, 0.59, 0.33}, -- Unholy Rune
		[3] = {0.31, 0.45, 0.63}, -- Frost Rune
		[4] = {0.84, 0.75, 0.65}, -- Death Rune
	},
	ComboPoints = {
		[1] = {0.95, 0.86, 0.16},
		[2] = {0.95, 0.86, 0.16},
		[3] = {0.95, 0.86, 0.16},
		[4] = {0.95, 0.86, 0.16},
		[5] = {0.95, 0.86, 0.16},
	},
	TotemBar = {
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
	Tapped = {0.55, 0.57, 0.61},
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
	totembar = setmetatable({}, {
		__index = function(t, k)
			return module.db.Colors.TotemBar[k] or oUF.colors.totembar[k]
		end
	}),
	holypowerbar = setmetatable({}, {
		__index = function(t, k)
			return module.db.Colors.HolyPowerBar[k] or oUF.colors.holypowerbar[k]
		end
	}),
	soulshardbar = setmetatable({}, {
		__index = function(t, k)
			return module.db.Colors.SoulShardBar[k] or oUF.colors.soulshardbar[k]
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
	if oUF_LUI_target.CPoints then
		for i = 1, 5 do
			oUF_LUI_target.CPoints[i]:SetStatusBarColor(unpack(module.colors.combopoints[i]))
			if module.db.Target.Bars.ComboPoints.BackgroundColor.Enable == false then
				local mu = module.db.Target.Bars.ComboPoints.Multiplier
				local r, g, b = unpack(module.colors.combopoints[i])
				oUF_LUI_target.CPoints[i].bg:SetVertexColor(r*mu, g*mu, b*mu)
			end
		end
	end
	if oUF_LUI_player.HolyPower then
		for i = 1, 3 do
			oUF_LUI_player.HolyPower[i]:SetStatusBarColor(unpack(module.colors.holypowerbar[i]))
		end
	end
	if oUF_LUI_player.SoulShards then
		for i = 1, 3 do
			oUF_LUI_player.SoulShards[i]:SetStatusBarColor(unpack(module.colors.soulshardbar[i]))
		end
	end
	for k, obj in pairs(oUF.objects) do
		obj:UpdateAllElements()
	end
end

local colorGetter = function(info)
	local t = module.db.Colors[info[#info-1]][tonumber(info[#info]) and tonumber(info[#info]) or info[#info]]
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
			WARRIOR = self:NewColorNoAlpha("Warrior", "Warrior class", 2, false, "full"),
			PRIEST = self:NewColorNoAlpha("Priest", "Priest class", 3, false, "full"),
			DRUID = self:NewColorNoAlpha("Druid", "Druid class", 4, false, "full"),
			HUNTER = self:NewColorNoAlpha("Hunter", "Hunter class", 5, false, "full"),
			MAGE = self:NewColorNoAlpha("Mage", "Mage class", 6, false, "full"),
			PALADIN = self:NewColorNoAlpha("Paladin", "Paladin class", 7, false, "full"),
			SHAMAN = self:NewColorNoAlpha("Shaman", "Shaman class", 8, false, "full"),
			WARLOCK = self:NewColorNoAlpha("Warlock", "Warlock class", 9, false, "full"),
			ROGUE = self:NewColorNoAlpha("Rogue", "Rogue class", 10, false, "full"),
			DEATHKNIGHT = self:NewColorNoAlpha("Death Knight", "Death Knight class", 11, false, "full"),
			empty1 = self:NewDesc(" ", 12),
			Reset = self:NewExecute("Restore Defaults", nil, 13, function()
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
			RUNES = self:NewColorNoAlpha("Runes", "Runes ressource", 6, false, "full"),
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
		HolyPowerBar = self:NewGroup("Holy Power", 5, nil, nil, class ~= "PALADIN", {
			header1 = self:NewHeader("Holy Power Colors", 1),
			["1"]	= self:NewColorNoAlpha("Part 1", "first part of your Holy Power Bar", 2, false, "full"),
			["2"]	= self:NewColorNoAlpha("Part 2", "second part of your Holy Power Bar", 3, false, "full"),
			["3"]	= self:NewColorNoAlpha("Part 2", "third part of your Holy Power Bar", 4, false, "full"),
			empty1 = self:NewDesc(" ", 5),
			Reset = self:NewExecute("Restore Defaults", nil, 6, function()
				module.db.Colors.HolyPowerBar = module.defaults.Colors.HolyPowerBar
				UpdateColors()
			end),
		}),
		SoulShardBar = self:NewGroup("Soul Shard", 6, nil, nil, class ~= "WARLOCK", {
			header1 = self:NewHeader("Soul Shard Colors", 1),
			["1"] = self:NewColorNoAlpha("Part 1", "first part of your Soul Shard Bar", 2, false, "full"),
			["2"]	= self:NewColorNoAlpha("Part 2", "second part of your Soul Shard Bar", 3, false, "full"),
			["3"]	= self:NewColorNoAlpha("Part 2", "third part of your Soul Shard Bar", 4, false, "full"),
			empty1 = self:NewDesc(" ", 5),
			Reset = self:NewExecute("Restore Defaults", nil, 6, function()
				module.db.Colors.SoulShardBar = module.defaults.Colors.SoulShardBar
				UpdateColors()
			end),
		}),
		EclipseBar = self:NewGroup("Eclipse Bar", 7, nil, nil, class ~= "DRUID", {
			header1 = self:NewHeader("Eclipse Bar Colors", 1),
			Lunar = self:NewColorNoAlpha("Lunar", "Lunar Part of your Eclipse Bar", 2, false, "full"),
			LunarBG = self:NewColorNoAlpha("Lunar BG", "Lunar Part Background of your Eclipse Bar", 3, false, "full"),
			Solar = self:NewColorNoAlpha("Solar", "Solar Part of your Eclipse Bar", 4, false, "full"),
			SolarBG = self:NewColorNoAlpha("Solar BG", "Solar Part Background of your Eclipse Bar", 5, false, "full"),
			empty1 = self:NewDesc(" ", 6),
			Reset = self:NewExecute("Restore Defaults", nil, 7, function()
				module.db.Colors.EclipseBar = module.defaults.Colors.SoulShardBar
				UpdateColors()
			end),
		}),
		Runes = self:NewGroup("Runes", 8, nil, nil, class ~= "DEATHKNIGHT" and class ~= "DEATH KNIGHT", {
			header1 = self:NewHeader("Runes Colors", 1),
			["1"] = self:NewColorNoAlpha("Blood", "Blood Runes", 2, false, "full"),
			["2"] = self:NewColorNoAlpha("Unholy", "Unholy Runes", 3, false, "full"),
			["3"] = self:NewColorNoAlpha("Frost", "Frost Runes", 4, false, "full"),
			["4"] = self:NewColorNoAlpha("Death", "Death Runes", 5, false, "full"),
			empty1 = self:NewDesc(" ", 6),
			Reset = self:NewExecute("Restore Defaults", nil, 7, function()
				module.db.Colors.Runes = module.defaults.Colors.Runes
				UpdateColors()
			end),
		}),
		ComboPoints = self:NewGroup("Combo Points", 9, nil, nil, class ~= "ROGUE", {
			header1 = self:NewHeader("Combo Points Colors", 1),
			["1"] = self:NewColorNoAlpha("Part 1", "first Combo Point", 2, false, "full"),
			["2"] = self:NewColorNoAlpha("Part 2", "second Combo Point", 3, false, "full"),
			["3"] = self:NewColorNoAlpha("Part 3", "third Combo Point", 4, false, "full"),
			["4"] = self:NewColorNoAlpha("Part 4", "fourth Combo Point", 5, false, "full"),
			["5"] = self:NewColorNoAlpha("Part 5", "fifth Combo Point", 6, false, "full"),
			empty1 = self:NewDesc(" ", 7),
			Reset = self:NewExecute("Restore Defaults", nil, 8, function()
				module.db.Colors.ComboPoints = module.defaults.Colors.ComboPoints
				UpdateColors()
			end),
		}),
		TotemBar = self:NewGroup("Totems", 10, nil, nil, class ~= "SHAMAN", {
			header1 = self:NewHeader("Totem Colors", 1),
			["1"] = self:NewColorNoAlpha("Fire", "Fire Totem", 2, false, "full"),
			["2"] = self:NewColorNoAlpha("Earth", "Earth Totem", 3, false, "full"),
			["3"] = self:NewColorNoAlpha("Water", "Water Totem", 4, false, "full"),
			["4"] = self:NewColorNoAlpha("Air", "Air Totem", 5, false, "full"),
			empty1 = self:NewDesc(" ", 6),
			Reset = self:NewExecute("Restore Defaults", nil, 7, function()
				module.db.Colors.ComboPoints = module.defaults.Colors.ComboPoints
				UpdateColors()
			end),
		}),
		LevelDiff = self:NewGroup("Level Difference", 11, {
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
	})
	
	return options
end
