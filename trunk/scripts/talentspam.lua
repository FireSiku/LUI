local addonname, LUI = ...
local script = LUI:NewScript("TalentSpam", "AceEvent-3.0", "AceHook-3.0")

local spam1 = gsub(ERR_LEARN_ABILITY_S:gsub("%.", "%."), "%%s", "(.*)")
local spam2 = gsub(ERR_LEARN_SPELL_S:gsub("%.", "%."), "%%s", "(.*)")
local spam3 = gsub(ERR_SPELL_UNLEARNED_S:gsub("%.", "%."), "%%s", "(.*)")
local spam4 = gsub(ERR_LEARN_PASSIVE_S:gsub("%.", "%."), "%%s", "(.*)")
local spam5 = gsub(ERR_PET_LEARN_ABILITY_S:gsub("%.", "%."), "%%s", "(.*)")
local spam6 = gsub(ERR_PET_LEARN_SPELL_S:gsub("%.", "%."), "%%s", "(.*)")
local spam7 = gsub(ERR_PET_SPELL_UNLEARNED_S:gsub("%.", "%."), "%%s", "(.*)")

local function spamFilter(self, event, msg)
	if strfind(msg, spam1) or strfind(msg, spam2) or strfind(msg, spam3) or strfind(msg, spam4)
		or strfind(msg, spam5) or strfind(msg, spam6) or strfind(msg, spam7) then return true end
end

function script:AddFilter(...)
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "RemoveFilter")
	self:RegisterEvent("UNIT_SPELLCAST_STOP", "RemoveFilter")
	ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", spamFilter)
end

function script:RemoveFilter(event, unit)
	if unit ~= "player" then return end

	self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:UnregisterEvent("UNIT_SPELLCAST_STOP")
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", spamFilter)
end

function script:SetTalentSpam()
	if LUI.db.profile.General.HideTalentSpam then
		self:SecureHook("SetActiveSpecGroup", "AddFilter")
		self:SecureHook("SetSpecialization", "AddFilter")
	else
		self:Unhook("SetActiveSpecGroup")
		self:Unhook("SetSpecialization")
	end
end

script:RegisterEvent("PLAYER_ENTERING_WORLD", function(event)
	script:SetTalentSpam()
	script:UnregisterEvent(event)
end)