local parent, ns = ...
local oUF = ns.oUF

local Update = function(self, event)
	local unit = self.unit
	if(UnitInRaid(unit) and UnitIsGroupAssistant(unit) and not UnitIsGroupLeader(unit)) then
		self.Assistant:Show()
	else
		self.Assistant:Hide()
	end
end

local Path = function(self, ...)
	return (self.Assistant.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate')
end

local Enable = function(self)
	local assistant = self.Assistant
	if(assistant) then
		self:RegisterEvent("GROUP_ROSTER_UPDATE", Path)

		if(assistant:IsObjectType"Texture" and not assistant:GetTexture()) then
			assistant:SetTexture[[Interface\GroupFrame\UI-Group-AssistantIcon]]
		end

		assistant.__owner = self
		assistant.ForceUpdate = ForceUpdate

		return true
	end
end

local Disable = function(self)
	local assistant = self.Assistant
	if(assistant) then
		self:UnregisterEvent("GROUP_ROSTER_UPDATE", Path)
	end
end

oUF:AddElement('Assistant', Path, Enable, Disable)
