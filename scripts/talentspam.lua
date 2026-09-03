---@class LUIAddon
local LUI = select(2, ...)
local script = LUI:NewScript("TalentSpam", "AceEvent-3.0")

local messageTemplates = {
	_G.ERR_LEARN_ABILITY_S,
	_G.ERR_LEARN_SPELL_S,
	_G.ERR_SPELL_UNLEARNED_S,
	_G.ERR_LEARN_PASSIVE_S,
	_G.ERR_PET_LEARN_ABILITY_S,
	_G.ERR_PET_LEARN_SPELL_S,
	_G.ERR_PET_SPELL_UNLEARNED_S,
}

local function CreateMessagePattern(template)
	local placeholder = "\001"
	template = template:gsub("%%s", placeholder)
	template = template:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
	template = template:gsub(placeholder, ".+")
	return "^"..template.."$"
end

local spamPatterns = {}
for _, template in pairs(messageTemplates) do
	if type(template) == "string" then
		spamPatterns[#spamPatterns + 1] = CreateMessagePattern(template)
	end
end

local function spamFilter(_, _, msg)
	if LUI.db.profile.General.HideTalentSpam and not issecretvalue(msg) then
		for i = 1, #spamPatterns do
			if strfind(msg, spamPatterns[i]) then return true end
		end
	end
end

local filterRegistered = false
function script:SetTalentSpam()
	local enabled = LUI.db.profile.General.HideTalentSpam
	if enabled and not filterRegistered then
		_G.ChatFrameUtil.AddMessageEventFilter("CHAT_MSG_SYSTEM", spamFilter)
		filterRegistered = true
	elseif not enabled and filterRegistered then
		_G.ChatFrameUtil.RemoveMessageEventFilter("CHAT_MSG_SYSTEM", spamFilter)
		filterRegistered = false
	end
end

script:RegisterEvent("PLAYER_ENTERING_WORLD", function(event)
	script:SetTalentSpam()
	script:UnregisterEvent(event)
end)
