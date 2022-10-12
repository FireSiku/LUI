--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: colors.lua
	Description: oUF Colors
]]

local addonname, LUI = ...
local module = LUI:GetModule("Unitframes")
local oUF = LUI.oUF

local GetQuestDifficultyColor = _G.GetQuestDifficultyColor
local UnitLevel = _G.UnitLevel
local strupper = string.upper

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
			local runeType = (_G.GetRuneType) and _G.GetRuneType(i) or 1
			oUF_LUI_player.Runes[i]:SetStatusBarColor(unpack(module.colors.runes[runeType]))
		end
	end
	local classPower = oUF_LUI_player.ClassPower
	if classPower then
		local r, g, b
		if LUI.MONK then r, g, b = unpack(module.colors.chibar[1])
		elseif LUI.PALADIN then r, g, b = unpack(module.colors.holypowerbar[1])
		elseif LUI.MAGE then r, g, b = unpack(module.colors.arcanechargesbar[1])
		elseif LUI.WARLOCK then r, g, b = unpack(module.colors.warlockbar.Shard1)
		elseif LUI.ROGUE then r, g, b = unpack(module.colors.combopoints[1])
		elseif LUI.DRUID then r, g, b = unpack(module.colors.combopoints[1])
		end
		
		classPower:SetBackdropColor(r * 0.4, g * 0.4, b * 0.4)
		for i = 1, classPower.MaxCount do
			classPower[i]:SetVertexColor(r, g, b)
		end
	end
	for k, obj in pairs(oUF.objects) do
		obj:UpdateAllElements('refreshUnit')
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
			MONK = LUI.IsRetail and self:NewColorNoAlpha("Monk", "Monk class", 12, false, "normal") or nil,
			DEMONHUNTER = LUI.IsRetail and self:NewColorNoAlpha("Demon Hunter", "Demon Hunter class", 13, false, "normal") or nil,
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
			FOCUS = LUI.IsRetail and self:NewColorNoAlpha("Focus", "Focus ressource", 4, false, "full") or nil,
			ENERGY = self:NewColorNoAlpha("Energy", "Energy ressource", 5, false, "full"),
			RUNES = self:NewColorNoAlpha("Runes", "Runes ressource", 6, false, "full"),
			RUNIC_POWER = self:NewColorNoAlpha("Runic Power", "Runic Power ressource", 7, false, "full"),
			AMMOSLOT = LUI.IsRetail and self:NewColorNoAlpha("Ammoslot", "Ammoslot ressource", 8, false, "full") or nil,
			FUEL = LUI.IsRetail and self:NewColorNoAlpha("Fuel", "Fuel ressource", 9, false, "full") or nil,
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
		HolyPowerBar = self:NewGroup("Holy Power", 6, nil, nil, not LUI.PALADIN, {
			header1 = self:NewHeader("Holy Power Colors", 1),
			["1"]	= self:NewColorNoAlpha("Holy Power", "Holy Power Bar", 2, false, "full"),
			empty1 = self:NewDesc(" ", 7),
			Reset = self:NewExecute("Restore Defaults", nil, 8, function()
				module.db.Colors.HolyPowerBar = module.defaults.Colors.HolyPowerBar
				UpdateColors()
			end),
		}),
		WarlockBar = self:NewGroup("Soul Shards", 7, nil, nil, not LUI.WARLOCK, {
			header1 = self:NewHeader("Soul Shard Colors", 1),
			["Shard1"] = self:NewColorNoAlpha("Soul Shards", "Soul Shards Bar", 2, false, "full"),
			empty1 = self:NewDesc(" ", 13),
			Reset = self:NewExecute("Restore Defaults", nil, 14, function()
				module.db.Colors.WarlockBar = module.defaults.Colors.WarlockBar
				UpdateColors()
			end),
		}),
		ArcaneChargesBar = self:NewGroup("Arcane Charges", 10, nil, nil, not LUI.MAGE, {
			header1 = self:NewHeader("Arcane Charges Colors", 1),
			["1"] = self:NewColorNoAlpha("Arcane Charges", "Arcane Charges Bar", 2, false, "full"),
			empty1 = self:NewDesc(" ", 5),
			Reset = self:NewExecute("Restore Defaults", nil, 6, function()
				module.db.Colors.ArcaneChargesBar = module.defaults.Colors.ArcaneChargesBar
				UpdateColors()
			end),
		}),
		ChiBar = self:NewGroup("Chi", 10, nil, nil, not LUI.MONK, {
			header1 = self:NewHeader("Chi Colors", 1),
			["1"] = self:NewColorNoAlpha("Chi", "Chi Bar", 2, false, "full"),
			empty1 = self:NewDesc(" ", 8),
			Reset = self:NewExecute("Restore Defaults", nil, 9, function()
				module.db.Colors.ChiBar = module.defaults.Colors.ChiBar
				UpdateColors()
			end),
		}),
		Runes = self:NewGroup("Runes", 12, nil, nil, not LUI.DEATHKNIGHT, {
			header1 = self:NewHeader("Runes Colors", 1),
			["1"] = not LUI.IsRetail and self:NewColorNoAlpha("Blood", "Runes", 2, false, "full") or nil,
			["2"] = not LUI.IsRetail and self:NewColorNoAlpha("Frost", "Runes", 3, false, "full") or nil,
			["3"] = not LUI.IsRetail and self:NewColorNoAlpha("Unholy", "Runes", 4, false, "full") or nil,
			["4"] = self:NewColorNoAlpha("Death", "Runes", 5, false, "full"),
			empty1 = self:NewDesc(" ", 6),
			Reset = self:NewExecute("Restore Defaults", nil, 7, function()
				module.db.Colors.Runes = module.defaults.Colors.Runes
				UpdateColors()
			end),
		}),
		ComboPoints = self:NewGroup("Combo Points", 13, nil, nil, not LUI.ROGUE and not LUI.DRUID, {
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
