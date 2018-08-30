local addonname, LUI = ...
local script = LUI:NewScript("TalentSpam", "AceEvent-3.0", "AceHook-3.0")

local spam = {
    ERR_LEARN_ABILITY_S:gsub("%.", "%."),       -- 1
    ERR_LEARN_SPELL_S:gsub("%.", "%."),         -- 2
    ERR_SPELL_UNLEARNED_S:gsub("%.", "%."),     -- 3
    ERR_LEARN_PASSIVE_S:gsub("%.", "%."),       -- 4
    ERR_PET_LEARN_ABILITY_S:gsub("%.", "%."),   -- 5
    ERR_PET_LEARN_SPELL_S:gsub("%.", "%."),     -- 6
    ERR_PET_SPELL_UNLEARNED_S:gsub("%.", "%."), -- 7
}

local function gsubSpam(spamString)
	return gsub(spamString, "%%s", "(.*)")
end

local function spamFilter(self, event, msg)
	if LUI.db.profile.General.HideTalentSpam and PlayerTalentFrame and PlayerTalentFrame:IsShown() then
		for i = 1, #spam do
			if strfind(msg, gsubSpam(spam[i])) then return true end
		end
	end
end

function script:SetTalentSpam()
	if LUI.db.profile.General.HideTalentSpam then
		ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", spamFilter)
	else
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", spamFilter)
	end
end

script:RegisterEvent("PLAYER_ENTERING_WORLD", function(event)
	script:SetTalentSpam()
	script:UnregisterEvent(event)
end)
