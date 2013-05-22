--[[
	Project.: oUF_SingleAuras
	File....: oUF_SingleAuras.lua
	Version.: 40100.1
	Rev Date: 27/05/2011
	Authors.: Shandrela [Bloodmoon] @ EU-Baelgun
]]

--[[
	Code Example:
	 local SA = {}
	 
	 SA.TL = CreateFrame("Frame", nil, self)
	 SA.TL.onlyPlayer = true
	 SA.TL.spellName = "Vigilance"
	 SA.TL.isDebuff = false
	 SA.TL:SetWidth(12)
	 SA.TL:SetHeight(12)
	 SA.TL:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -1)
	 
	 SA.TR = CreateFrame("Frame", nil, self)
	 SA.TR.onlyPlayer = false
	 SA.TR.spellName = "Battle Shout"
	 SA.TR:SetWidth(12)
	 SA.TR:SetHeight(12)
	 SA.TR:SetPoint("TOPRIGHT", self, "TOPRIGHT", -1, -1)
	 
	--you can create the texture by yourself if you want:
	 SA.TR.tex = SA.TR:CreateTexture(nil, "Overlay")
	 SA.TR.tex:SetAllPoints(SA.TR)
	 SA.TR.tex:SetTexCoord(0.1, 0.9, 0.1, 0.9)
	
	self.SingleAuras = SA
--]]

local _, ns = ...
local oUF = oUF or ns.oUF

local UnitAura = UnitAura

local Update = function(self, event, unit)
	if not unit or unit ~= self.__owner.unit then return end
	if event ~= "UNIT_AURA" then return end
	
	local index = 1
	
	while true do
		local name, _, icon, _, debuffType, _, _, unitCaster = UnitAura(unit, index, self.isDebuff and "HARMFUL" or "HELPFUL")
		
		if not name then
			self:Hide()
			
			break
		end
		
		if name == self.spellName then
			if unitCaster == "player" or not self.onlyPlayer then
				self.tex:SetTexture(icon)
				self:Show()
				
				break
			end
		end
		
		index = index + 1
	end
end

local Enable = function(self, unit)
	local t = self.SingleAuras
	
	if not t then return end
	
	for _, frame in pairs(t) do
		if frame.GetObjectType and frame:GetObjectType() == "Frame" then
			if not frame.tex then
				frame.tex = frame:CreateTexture(nil, "OVERLAY")
				frame.tex:SetAllPoints(frame)
				frame.tex:SetTexCoord(0.1, 0.9, 0.1, 0.9)
			end
			
			frame.__owner = self
			if type(frame.spellName) == "string" then
				frame:RegisterEvent("UNIT_AURA")
				frame:SetScript("OnEvent", Update)
			else
				frame:UnregisterEvent("UNIT_AURA")
				frame:SetScript("OnEvent", nil)
				frame:Hide()
			end
		end
	end
end

local Disable = function(self, unit)
	local t = self.SingleAuras
	
	if not t then return end
	
	for _, frame in pairs(t) do
		if frame.GetObjectType and frame:GetObjectType() == "Frame" then
			frame:UnregisterEvent("UNIT_AURA")
			frame:SetScript("OnEvent", nil)
			frame:Hide()
		end
	end
end

oUF:AddElement("SingleAuras", nil, Enable, Disable)
