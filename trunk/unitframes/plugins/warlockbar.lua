if(select(2, UnitClass('player')) ~= 'WARLOCK') then return end

local parent, ns = ...
local oUF = ns.oUF
local GetSpecialization = GetSpecialization

local spec = GetSpecialization()
local specPower = { "SOUL_SHARDS", "DEMONIC_FURY", "BURNING_EMBERS" }
local specType = { Enum.PowerType.SoulShards, SPELL_POWER_DEMONIC_FURY, SPELL_POWER_BURNING_EMBERS } 

local Update = function(self, event, unit, powerType)
	
	if(self.unit ~= unit or (powerType and powerType ~= specPower[spec])) then return end
	
	local wb = self.WarlockBar
	if(wb.PreUpdate) then wb:PreUpdate(unit) end
	
	local num = UnitPower(unit, specType[spec])

	if spec == 1 then
		for i = 1, 4 do
			if i <= num then wb[i]:SetAlpha(1)
			else wb[i]:SetAlpha(.4)
			end
		end
	--Demonology
	elseif spec == 2 then
		wb[1]:SetValue(num)	
	--Destruction
	elseif spec == 3 then
		local power = UnitPower(unit, specType[spec], true)
		for i = 1, 4 do
			local numOver = power - (i-1)*10
			if i <= num then
				wb[i]:SetAlpha(1)
				wb[i]:SetValue(10)
			elseif numOver > 0 then
				wb[i]:SetAlpha(.6)
				wb[i]:SetValue(numOver)
			else
				wb[i]:SetAlpha(.6)
				wb[i]:SetValue(0)
			end
		end
	end

	if(wb.PostUpdate) then
		return wb:PostUpdate(unit)
	end
end

local Path = function(self, ...)
	return (self.WarlockBar.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	local spec = GetSpecialization() -- Just to make sure its not old data.
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit, specPower[spec])
end

local function Enable(self)
	local wb = self.WarlockBar
	if(wb) then
		wb.__owner = self
		wb.ForceUpdate = ForceUpdate

		self:RegisterEvent('UNIT_POWER_UPDATE', Path)
		wb:Show()
		return true
	end
end

local function Disable(self)
	local wb = self.WarlockBar
	if(wb) then
		self:UnregisterEvent('UNIT_POWER_UPDATE', Path)
		wb:Hide()
	end
end

oUF:AddElement('WarlockBar', Path, Enable, Disable)
