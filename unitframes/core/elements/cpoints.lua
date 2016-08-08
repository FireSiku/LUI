--[[ Element: Combo Point Icons
 Toggles visibility of the player and vehicles combo points.

 Widget

 CPoints - An array consisting of five UI widgets.

 Notes

 The default combo point texture will be applied to textures within the CPoints
 array that don't have a texture or color defined.

 Examples

   local CPoints = {}
   for index = 1, MAX_COMBO_POINTS do
      local CPoint = self:CreateTexture(nil, 'BACKGROUND')
   
      -- Position and size of the combo point.
      CPoint:SetSize(12, 16)
      CPoint:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', index * CPoint:GetWidth(), 0)
   
      CPoints[index] = CPoint
   end
   
   -- Register with oUF
   self.CPoints = CPoints

 Hooks

 Override(self) - Used to completely override the internal update function.
                  Removing the table key entry will make the element fall-back
                  to its internal function again.
]]

local parent, ns = ...
local oUF = ns.oUF

local GetComboPoints = GetComboPoints
local MAX_COMBO_POINTS = MAX_COMBO_POINTS

local Update = function(self, event, unit)
	if(unit == 'pet') then return end

	local cpoints = self.CPoints
	if(cpoints.PreUpdate) then
		cpoints:PreUpdate()
	end

	local cp
	if(UnitHasVehicleUI'player') then
		cp = GetComboPoints('vehicle', 'target')
	else
		cp = GetComboPoints('player', 'target')
	end

	for i=1, MAX_COMBO_POINTS do
		if(i <= cp) then
			cpoints[i]:Show()
		else
			cpoints[i]:Hide()
		end
	end

	if(cpoints.PostUpdate) then
		return cpoints:PostUpdate(cp)
	end
end

local Path = function(self, ...)
	return (self.CPoints.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local Enable = function(self)
	local cpoints = self.CPoints
	if(cpoints) then
		cpoints.__owner = self
		cpoints.ForceUpdate = ForceUpdate

		self:RegisterEvent('UNIT_POWER_FREQUENT', Path)
		self:RegisterEvent('PLAYER_TARGET_CHANGED', Path, true)

		for index = 1, MAX_COMBO_POINTS do
			local cpoint = cpoints[index]
			if(cpoint:IsObjectType'Texture' and not cpoint:GetTexture()) then
				cpoint:SetTexture[[Interface\ComboFrame\ComboPoint]]
				cpoint:SetTexCoord(0, 0.375, 0, 1)
			end
		end

		return true
	end
end

local Disable = function(self)
	local cpoints = self.CPoints
	if(cpoints) then
		for index = 1, MAX_COMBO_POINTS do
			cpoints[index]:Hide()
		end
		self:UnregisterEvent('UNIT_POWER_FREQUENT', Path)
		self:UnregisterEvent('PLAYER_TARGET_CHANGED', Path)
	end
end

oUF:AddElement('CPoints', Path, Enable, Disable)
