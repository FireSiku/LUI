--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: showhide.lua
	Description: Show/Hide functionality for testing purposes
]]

local addonname, LUI = ...
local module = LUI:Module("Unitframes")
local oUF = LUI.oUF

local fm = string.format
local ts = tostring

local orig_DisableBlizz = oUF.DisableBlizzard
oUF.DisableBlizzard = function(self, unit)
	if not module:IsEnabled() then return orig_DisableBlizz(self, unit) end
end

local togglers = {
	Arena = CreateFrame("Frame"),
	Boss = CreateFrame("Frame"),
	Maintank = CreateFrame("Frame"),
}

function module:ShowArenaFrames()
	for k, v in next, oUF.objects do
		if v.unit and v.unit:match"(arena)%d" == "arena" then
			v.unit_ = v.unit
			v:SetAttribute("unit", "player")
		end
	end
	
	local padding = oUF_LUI_arena:GetAttribute("Padding")
	local height = oUF_LUI_arena:GetAttribute("Height")
	oUF_LUI_arena:SetHeight(height * 5 + padding * 4)
	
	togglers.Arena:RegisterEvent("PLAYER_REGEN_DISABLED")
end

function module:HideArenaFrames(event)
	togglers.Arena:UnregisterEvent("PLAYER_REGEN_DISABLED")
	
	for k, v in next, oUF.objects do
		if v.unit_ and v.unit_:match"(arena)%d" == "arena" then
			v:SetAttribute("unit", v.unit_)
			v.unit_ = nil
		end
	end
	
	if event then
		LUI:Print("Dummy Arena Frames hidden due to combat")
	end
end

function module:ShowBossFrames()
	for k, v in next, oUF.objects do
		if v.unit and v.unit:find("boss") then
			v.unit_ = v.unit
			v:SetAttribute("unit", "player")
		end
	end
	
	local padding = oUF_LUI_boss:GetAttribute("Padding")
	local height = oUF_LUI_boss:GetAttribute("Height")
	oUF_LUI_boss:SetHeight(height * 4 + padding * 3)
	
	togglers.Boss:RegisterEvent("PLAYER_REGEN_DISABLED")
end

function module:HideBossFrames(event)
	togglers.Boss:UnregisterEvent("PLAYER_REGEN_DISABLED")
	
	for k, v in next, oUF.objects do
		if v.unit_ and v.unit_:find("boss") then
			v:SetAttribute("unit", v.unit_)
			v.unit_ = nil
		end
	end
	
	if event then
		LUI:Print("Dummy Boss Frames hidden due to combat")
	end
end

function module:ShowMaintankFrames()
	oUF_LUI_maintank:SetAttribute("groupFilter", nil)
	oUF_LUI_maintank:SetAttribute("showSolo", 1)
	
	togglers.Maintank:RegisterEvent("PLAYER_REGEN_DISABLED")
end

function module:HideMaintankFrames(event)
	togglers.Maintank:UnregisterEvent("PLAYER_REGEN_DISABLED")
	
	oUF_LUI_maintank:SetAttribute("groupFilter", "MAINTANK")
	oUF_LUI_maintank:SetAttribute("showSolo", 0)
	
	if event then
		LUI:Print("Dummy MainTank Frames hidden due to combat")
	end
end

togglers.Arena:SetScript("OnEvent", module.HideArenaFrames)
togglers.Boss:SetScript("OnEvent", module.HideBossFrames)
togglers.Maintank:SetScript("OnEvent", module.HideMaintankFrames)
