---@class LUIAddon
local LUI = select(2, ...)
---@type string
local script = LUI:NewScript("AutoInvite", "AceEvent-3.0")

local IsInGroup = _G.IsInGroup
local UnitIsGroupAssistant = _G.UnitIsGroupAssistant
local UnitIsGroupLeader = _G.UnitIsGroupLeader
local IsInGuild = _G.IsInGuild

local C_FriendList = C_FriendList
local C_BattleNet = C_BattleNet

local function GetDB()
	return LUI.db.profile.General
end

local function GetKeyword()
	return strtrim(GetDB().AutoInviteKeyword or "")
end

local function isFriend(guid)
	if not guid or issecretvalue(guid) then return false end
	local result = C_FriendList.IsFriend(guid)
	return result and not issecretvalue(result)
end

local function isGuildmate(name)
	if not name or issecretvalue(name) then return false end
	local result = IsInGuild() and C_GuildInfo.MemberExistsByName(name)
	return result and not issecretvalue(result)
end

local function isBNFriend(guid)
	if not guid or issecretvalue(guid) then return false end
	local accountInfo = C_BattleNet.GetAccountInfoByGUID(guid)
	local result = accountInfo and accountInfo.isFriend
	return result and not issecretvalue(result)
end

function LUI:InviteCmd()
	local db = GetDB()
	db.AutoInvite = not db.AutoInvite
	script:SetAutoInvite()
	LUI:Print("AutoInvite |cff"..(db.AutoInvite and "00FF00Enabled|r" or "FF0000Disabled|r"))
	if LibStub("AceConfigDialog-3.0").OpenFrames.LUIOptions then
		LibStub("AceConfigRegistry-3.0"):NotifyChange("LUIOptions")
	end
end


function script:SetAutoInvite()
	local enabled = GetDB().AutoInvite and GetKeyword() ~= ""
	self[enabled and "RegisterEvent" or "UnregisterEvent"](self, "CHAT_MSG_WHISPER")
	if enabled then C_FriendList.ShowFriends() end
end


function script:CHAT_MSG_WHISPER(event, message, sender, ...)
	if issecretvalue(message) or issecretvalue(sender) then return end
	local db = GetDB()
	local keyword = GetKeyword()
	if keyword == "" then return end
	local guid = select(10, ...)
	local leader = UnitIsGroupLeader("player")
	local assistant = UnitIsGroupAssistant("player")
	if issecretvalue(leader) then leader = false end
	if issecretvalue(assistant) then assistant = false end
	if (leader or assistant or not IsInGroup()) and strlower(message):find(strlower(keyword), 1, true) then
		if db.AutoInviteOnlyFriend == false or (isFriend(guid) or isGuildmate(sender) or isBNFriend(guid)) then
			C_PartyInfo.InviteUnit(sender)
		end
	end
end

function script:PLAYER_ENTERING_WORLD(event)
	LUI.Profiler.TraceScope(script, "AutoInvite", "LUI", 2)
	script:SetAutoInvite()
end

script:RegisterEvent("PLAYER_ENTERING_WORLD")

LUI.cmdList.commands.invite = "InviteCmd"
LUI.cmdList.commands.inv = "InviteCmd"
