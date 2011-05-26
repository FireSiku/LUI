local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local db = LUI.db.profile

oUF_LUI = {}
oUF_LUI.colors = setmetatable({
	power = setmetatable({
		["POWER_TYPE_STEAM"] = {0.55, 0.57, 0.61},
		["POWER_TYPE_PYRITE"] = {0.60, 0.09, 0.17},
	}, {
		__index = function(t, k)
			return db.oUF.Colors.Power[k] or oUF.colors.power[k]
		end
	}),
	class = setmetatable({}, {
		__index = function(t, k)
			return db.oUF.Colors.Class[k] or oUF.colors.class[k]
		end
	}),
	leveldiff = setmetatable({}, {
		__index = function(t, k)
			local diffColor = GetQuestDifficultyColor(UnitLevel("target"))
			return db.oUF.Colors.LevelDiff[k] or {diffColor.r, diffColor.g, diffColor.b}
		end
	}),
	combattext = setmetatable({}, {
		__index = function(t, k)
			return db.oUF.Colors.CombatText[k]
		end
	}),
	combopoints = setmetatable({}, {
		__index = function(t, k)
			return db.oUF.Colors.ComboPoints[k] or oUF.colors.combopoints[k]
		end
	}),
	runes = setmetatable({}, {
		__index = function(t, k)
			return db.oUF.Colors.Runes[k] or oUF.colors.runes[k]
		end
	}),
	totembar = setmetatable({}, {
		__index = function(t, k)
			return db.oUF.Colors.TotemBar[k] or oUF.colors.totembar[k]
		end
	}),
	holypowerbar = setmetatable({}, {
		__index = function(t, k)
			return db.oUF.Colors.HolyPowerBar[k] or oUF.colors.holypowerbar[k]
		end
	}),
	soulshardbar = setmetatable({}, {
		__index = function(t, k)
			return db.oUF.Colors.SoulShardBar[k] or oUF.colors.soulshardbar[k]
		end
	}),
	eclipsebar = setmetatable({}, {
		__index = function(t, k)
			return db.oUF.Colors.EclipseBar[k]
		end
	}),
}, {
	__index = function(t, k)
		return db.oUF.Colors[k and (k:gsub("^%a", strupper)) or k] or oUF.colors[k]
	end
})

oUF.colors.smooth = oUF_LUI.colors.smooth or oUF.colors.smooth