if(select(2, UnitClass('player')) ~= 'MONK') then return end

local parent, ns = ...
local oUF = ns.oUF

local SPELL_POWER_CHI = SPELL_POWER_CHI
local MAX_CHI = 5

local Update = function(self, event, unit, powerType)
	if(self.unit ~= unit or (powerType and powerType ~= 'CHI')) then return end

	local ch = self.HolyPower
	if(ch.PreUpdate) then ch:PreUpdate(unit) end

	local num = UnitPower('player', SPELL_POWER_CHI)
	for i = 1, MAX_CHI do
		if(i <= num) then
			ch[i]:SetAlpha(1)
		else
			ch[i]:SetAlpha(0)
		end
	end

	if(ch.PostUpdate) then
		return ch:PostUpdate(unit)
	end
end

local Path = function(self, ...)
	return (self.Chi.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit, 'CHI')
end

local function Enable(self)
	local ch = self.Chi
	if(ch) then
		ch.__owner = self
		ch.ForceUpdate = ForceUpdate
		ch:Show()

		self:RegisterEvent('UNIT_POWER', Path)

		return true
	end
end

local function Disable(self)
	local ch = self.Chi
	if(ch) then
		self:UnregisterEvent('UNIT_POWER', Path)
		ch:Hide()
	end
end

oUF:AddElement('Chi', Path, Enable, Disable)
