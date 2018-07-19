if(select(2, UnitClass('player')) ~= 'PRIEST') then return end

local parent, ns = ...
local oUF = ns.oUF

local SPELL_POWER_SHADOW_ORBS = SPELL_POWER_SHADOW_ORBS

local Update = function(self, event, unit, powerType)
	if(self.unit ~= unit or (powerType and powerType ~= 'SHADOW_ORBS')) then return end

	local so = self.ShadowOrbs
	if(so.PreUpdate) then so:PreUpdate(unit) end

	local num = UnitPower('player', SPELL_POWER_SHADOW_ORBS)
	for i = 1, 3 do
		if(i <= num) then
			so[i]:SetAlpha(1)
		else
			so[i]:SetAlpha(0)
		end
	end

	if(so.PostUpdate) then
		return so:PostUpdate(unit)
	end
end

local Path = function(self, ...)
	return (self.ShadowOrbs.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit, 'SHADOW_ORBS')
end

local function Enable(self)
	local so = self.ShadowOrbs
	if(so) then
		so.__owner = self
		so.ForceUpdate = ForceUpdate

		self:RegisterEvent('UNIT_POWER_UPDATE', Path)
		so:Show()
		return true
	end
end

local function Disable(self)
	local so = self.ShadowOrbs
	if(so) then
		self:UnregisterEvent('UNIT_POWER_UPDATE', Path)
		so:Hide()
	end
end

oUF:AddElement('ShadowOrbs', Path, Enable, Disable)

