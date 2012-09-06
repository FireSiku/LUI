if(select(2, UnitClass('player')) ~= 'WARLOCK') then return end

local parent, ns = ...
local oUF = ns.oUF

local SPELL_POWER_DEMONIC_FURY = SPELL_POWER_DEMONIC_FURY

local Update = function(self, event, unit, powerType)
	if(self.unit ~= unit or (powerType and powerType ~= 'DEMONIC_FURY')) then return end
	
	local df = self.DemonicFury
	if(df.PreUpdate) then df:PreUpdate(unit) end

	local num = UnitPower('player', SPELL_POWER_DEMONIC_FURY)
	for i = 1, 1 do
		df[i]:SetValue(num)
	end

	if(df.PostUpdate) then
		return df:PostUpdate(unit)
	end
end

local Path = function(self, ...)
	return (self.DemonicFury.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit, 'DEMONIC_FURY')
end

local function Enable(self)
	local df = self.DemonicFury
	if(df) then
		df.__owner = self
		df.ForceUpdate = ForceUpdate

		self:RegisterEvent('UNIT_POWER', Path)

		return true
	end
end

local function Disable(self)
	local df = self.DemonicFury
	if(df) then
		self:UnregisterEvent('UNIT_POWER', Path)
	end
end

oUF:AddElement('DemonicFury', Path, Enable, Disable)
