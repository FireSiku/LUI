-- yleaf (yaroot@gmail.com)

local _, ns = ...
local oUF = ns.oUF or oUF

local addon = {}
ns.oUF_RaidDebuffs = addon
if not _G.oUF_RaidDebuffs then
	_G.oUF_RaidDebuffs = addon
end

local debuff_data = {}
addon.DebuffData = debuff_data

addon.ShowDispelableDebuff = true
addon.FilterDispellableDebuff = true
addon.MatchBySpellName = true

local function add(spell, priority)
	if addon.MatchBySpellName and type(spell) == 'number' then
		spell = GetSpellInfo(spell)
	end
	debuff_data[spell] = priority
end

function addon:RegisterDebuffs(t)
	for id, prio in next, t do
		add(id, prio)
	end
end

function addon:ResetDebuffData()
	wipe(debuff_data)
end


local DispellColor = {
	['Magic']	= {.2, .6, 1},
	['Curse']	= {.6, 0, 1},
	['Disease']	= {.6, .4, 0},
	['Poison']	= {0, .6, 0},
	['none'] = {0, 0, 0},
}

local DispellPriority = {
	['Magic']	= 14,
	['Curse']	= 13,
	['Disease']	= 12,
	['Poison']	= 11,
}

local DispellFilter
do
	local dispellClasses = {
		['PRIEST'] = {
			['Magic'] = true,
			['Disease'] = true,
		},
		['SHAMAN'] = {
			['Magic'] = true,
			['Disease'] = true,
			['Curse'] = true,
		},
		['PALADIN'] = {
			['Poison'] = true,
			['Magic'] = true,
			['Disease'] = true,
		},
		['MAGE'] = {
			['Curse'] = true,
		},
		['DRUID'] = {
			['Magic'] = true,
			['Curse'] = true,
			['Poison'] = true,
		},
		['MONK'] = {
			['Poison'] = true,
			['Magic'] = true,
			['Disease'] = true,
		},
	}

	DispellFilter = dispellClasses[select(2, UnitClass('player'))] or {}
end

local function formatTime(s)
	if s > 60 then
		return format('%dm', s/60), s%60
	else
		return format('%d', s), s - floor(s)
	end
end

local function OnUpdate(self, elps)
	self.nextUpdate = self.nextUpdate - elps
	if self.nextUpdate > 0 then return end

	local timeLeft = self.endTime - GetTime()
	if timeLeft > 0 then
		local text, nextUpdate = formatTime(timeLeft)
		self.time:SetText(text)
		self.nextUpdate = nextUpdate
	else
		self:SetScript('OnUpdate', nil)
		self.time:Hide()
	end
end

local function UpdateDebuff(self, name, icon, count, debuffType, duration, endTime)
	local f = self.RaidDebuffs
	if name then
		-- if (not duration or type(duration) ~= "number") or (not expires or type(expires) ~= "number") then
		-- 	LUI:Printf("Name: %s, iconID: %s, type: %s, duration: %s, expires: %s, caster: %s", name, icon, count, dispelType, duration, expires, caster)
		-- end
		f.icon:SetTexture(icon)
		f.icon:Show()

		if f.count then
			if count and (count > 0) then
				f.count:SetText(count)
				f.count:Show()
			else
				f.count:Hide()
			end
		end

		if f.time then
			if duration and (duration > 0) then
				f.endTime = endTime
				f.nextUpdate = 0
				f:SetScript('OnUpdate', OnUpdate)
				f.time:Show()
			else
				f:SetScript('OnUpdate', nil)
				f.time:Hide()
			end
		end

		if f.cd then
			if duration and (duration > 0) then
				f.cd:SetCooldown(endTime - duration, duration)
				f.cd:Show()
			else
				f.cd:Hide()
			end
		end

		local c = DispellColor[debuffType] or DispellColor.none
		f:SetBackdropColor(c[1], c[2], c[3])

		f:Show()
	else
		f:Hide()
	end
end

local function Update(self, event, unit)
	if unit ~= self.unit then return end
	local _name, _icon, _count, _dtype, _duration, _endTime
	local _priority, priority = 0, nil
	for i = 1, 40 do
		local name, icon, count, debuffType, duration, expirationTime, _, _, _, spellId = UnitAura(unit, i, 'HARMFUL')
		if (not name) then break end

		if addon.ShowDispelableDebuff and debuffType then
			if addon.FilterDispellableDebuff then
				priority = DispellFilter[debuffType] and DispellPriority[debuffType]
			else
				priority = DispellPriority[debuffType]
			end

			if priority and (priority > _priority) then
				_priority, _name, _icon, _count, _dtype, _duration, _endTime = priority, name, icon, count, debuffType, duration, expirationTime
			end
		end

		priority = debuff_data[addon.MatchBySpellName and name or spellId]
		if priority and (priority > _priority) then
			_priority, _name, _icon, _count, _dtype, _duration, _endTime = priority, name, icon, count, debuffType, duration, expirationTime
		end
	end

	UpdateDebuff(self, _name, _icon, _count, _dtype, _duration, _endTime)
end

local function Enable(self)
	if self.RaidDebuffs then
		self:RegisterEvent('UNIT_AURA', Update)
		return true
	end
end

local function Disable(self)
	if self.RaidDebuffs then
		self:UnregisterEvent('UNIT_AURA', Update)
		self.RaidDebuffs:Hide()
	end
end

oUF:AddElement('RaidDebuffs', Update, Enable, Disable)
