---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Unitframes
local module = LUI:GetModule("Unitframes")
local oUF = LUI.oUF

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
		MONK = {0, 1, 0.59},
		DEMONHUNTER = {0.64, 0.19, 0.79},
		EVOKER = {0.20, 0.58, 0.50},
	},
	Power = {
		MANA = {0.31, 0.45, 0.63},
		RAGE = {0.69, 0.31, 0.31},
		FOCUS = {0.71, 0.43, 0.27},
		ENERGY = {0.65, 0.63, 0.35},
		RUNES = {0.55, 0.57, 0.61},
		RUNIC_POWER = {0, 0.82, 1},
		FUEL = {0, 0.55, 0.5},
	},
	Smooth = {
		{0.69, 0.31, 0.31},
		{0.69, 0.69, 0.31},
		{0.31, 0.69, 0.31},
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
	Runes = {
		{0.69, 0.31, 0.31},
		{0.31, 0.45, 0.63},
		{0.33, 0.59, 0.33},
	},
	LevelDiff = {
		{0.69, 0.31, 0.31}, -- Target level >= 5
		{0.71, 0.43, 0.27}, -- Target level >= 3
		{0.84, 0.75, 0.65}, -- Target level within 2
		{0.33, 0.59, 0.33}, -- Green quest range
		{0.55, 0.57, 0.61}, -- Trivial target
	},
}

local function CreateColorGroup(base, defaults, overrides)
	local group = setmetatable({}, {__index = base})
	local function Store(key, rgb)
		local r, g, b, a = rgb.r or rgb[1], rgb.g or rgb[2], rgb.b or rgb[3], rgb.a or rgb[4]
		if r and g and b then group[key] = oUF:CreateColor(r, g, b, a) end
	end
	for key, defaultRGB in pairs(defaults) do
		Store(key, overrides and overrides[key] or defaultRGB)
	end
	for key, rgb in pairs(overrides or {}) do
		Store(key, rgb)
	end
	return group
end

local powerIDs = {
	MANA = Enum.PowerType.Mana,
	RAGE = Enum.PowerType.Rage,
	FOCUS = Enum.PowerType.Focus,
	ENERGY = Enum.PowerType.Energy,
	RUNES = Enum.PowerType.Runes,
	RUNIC_POWER = Enum.PowerType.RunicPower,
}

function module:BuildUnitframeColors()
	local defaults = self.defaults.profile.Colors
	local profile = self.db.profile.Colors or defaults
	local colors = setmetatable({}, {__index = oUF.colors})
	colors.class = CreateColorGroup(oUF.colors.class, defaults.Class, profile.Class)
	colors.power = CreateColorGroup(oUF.colors.power, defaults.Power, profile.Power)
	colors.runes = CreateColorGroup(oUF.colors.runes, defaults.Runes, profile.Runes)
	colors.CombatText = profile.CombatText or defaults.CombatText
	colors.leveldiff = profile.LevelDiff or defaults.LevelDiff

	for token, powerID in pairs(powerIDs) do
		if powerID ~= nil and colors.power[token] then
			colors.power[powerID] = colors.power[token]
		end
	end

	local smooth = profile.Smooth or defaults.Smooth
	colors.health = oUF:CreateColor(oUF.colors.health:GetRGB())
	colors.health:SetCurve({
		[0] = CreateColor(unpack(smooth[1])),
		[0.5] = CreateColor(unpack(smooth[2])),
		[1] = CreateColor(unpack(smooth[3])),
	})

	self.colors = colors
end
