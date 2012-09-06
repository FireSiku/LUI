if(select(2, UnitClass('player')) ~= 'WARLOCK') then return end

local parent, ns = ...
local oUF = ns.oUF

local SPELL_POWER_BURNING_EMBERS = SPELL_POWER_BURNING_EMBERS

local Update = function(self, event, unit, powerType)
	if(self.unit ~= unit or (powerType and powerType ~= 'BURNING_EMBERS')) then return end
	
	local be = self.BurningEmbers
	if(be.PreUpdate) then be:PreUpdate(unit) end

	local num = UnitPower('player', SPELL_POWER_BURNING_EMBERS)
	for i = 1, 4 do
		if(i <= num) then
			be[i]:SetAlpha(1)
		else
			be[i]:SetAlpha(0)
		end
	end

	if(be.PostUpdate) then
		return be:PostUpdate(unit)
	end
end

local Path = function(self, ...)
	return (self.BurningEmbers.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit, 'BURNING_EMBERS')
end

local function Enable(self)
	local be = self.BurningEmbers
	if(be) then
		be.__owner = self
		be.ForceUpdate = ForceUpdate

		self:RegisterEvent('UNIT_POWER', Path)

		return true
	end
end

local function Disable(self)
	local be = self.BurningEmbers
	if(be) then
		self:UnregisterEvent('UNIT_POWER', Path)
	end
end

oUF:AddElement('BurningEmbers', Path, Enable, Disable)
