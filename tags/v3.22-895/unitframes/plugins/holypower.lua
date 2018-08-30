if(select(2, UnitClass('player')) ~= 'PALADIN') then return end

local parent, ns = ...
local oUF = ns.oUF

local MAX_HOLY_POWER = 5

local Update = function(self, event, unit, powerType)
	if(self.unit ~= unit or (powerType and powerType ~= 'HOLY_POWER')) then return end

	local hp = self.HolyPower
	if(hp.PreUpdate) then hp:PreUpdate(unit) end

	local num = UnitPower('player', Enum.PowerType.HolyPower)
	for i = 1, MAX_HOLY_POWER do
		if(i <= num) then
			hp[i]:SetAlpha(1)
		else
			hp[i]:SetAlpha(0)
		end
	end

	if(hp.PostUpdate) then
		return hp:PostUpdate(unit)
	end
end

local Path = function(self, ...)
	return (self.HolyPower.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit, 'HOLY_POWER')
end

local function Enable(self)
	local hp = self.HolyPower
	if(hp) then
		hp.__owner = self
		hp.ForceUpdate = ForceUpdate

		self:RegisterEvent('UNIT_POWER_UPDATE', Path)
		hp:Show()
		return true
	end
end

local function Disable(self)
	local hp = self.HolyPower
	if(hp) then
		self:UnregisterEvent('UNIT_POWER_UPDATE', Path)
		hp:Hide()
	end
end

oUF:AddElement('HolyPower', Path, Enable, Disable)
