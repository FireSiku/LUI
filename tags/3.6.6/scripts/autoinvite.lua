local addonname, LUI = ...
local script = LUI:NewScript("AutoInvite", "AceEvent-3.0")

local function isFriend(name)
	for i=1, GetNumFriends() do
		if strlower(GetFriendInfo(i)) == strlower(name) then
			return true
		end
	end
end

local function isGuildmate(name)
	if IsInGuild() then
		for i=1, GetNumGuildMembers() do
			if strlower(GetGuildRosterInfo(i)) == strlower(name) then
				return true
			end
		end
	end
end

local function isBNFriend(name)
	if BNFeaturesEnabledAndConnected() then
		local playerRealm = GetRealmName()
		for i=1, BNGetNumFriends() do
			pID, _, _, _, _, client, isOnline = BNGetFriendInfo(i)
			if client == "WoW" and isOnline then
				_, tName, _, realm = BNGetToonInfo(pID)
				if realm == playerRealm then
					if strlower(tName) == strlower(name) then
						return true
					end
				end
			end
		end
	end
end

local function chatcommand()
	LUI.db.profile.General.AutoInvite = not LUI.db.profile.General.AutoInvite
	script:SetAutoInvite()
	LUI:Print("AutoInvite |cff"..(LUI.db.profile.General.AutoInvite and "00FF00Enabled|r" or "FF0000Disabled|r"))
	if LibStub("AceConfigDialog-3.0").OpenFrames[addonname] then
		LibStub("AceConfigRegistry-3.0"):NotifyChange(addonname)
	end
end


function script:SetAutoAccept()
	self[LUI.db.profile.General.AutoAcceptInvite and "RegisterEvent" or "UnregisterEvent"](self, "PARTY_INVITE_REQUEST")
end

function script:SetAutoInvite()
	self[LUI.db.profile.General.AutoInvite and "RegisterEvent" or "UnregisterEvent"](self, "CHAT_MSG_WHISPER")
end


function script:PARTY_INVITE_REQUEST(event, sender)
	if sender == nil then return end

	if isFriend(sender) or isGuildmate(sender) or isBNFriend(sender) then
		AcceptGroup()
		for i=1, STATICPOPUP_NUMDIALOGS do
			local dlg = _G["StaticPopup"..i]
			if dlg.which == "PARTY_INVITE" then
				dlg.inviteAccepted = 1
				break
			end
		end
		StaticPopup_Hide("PARTY_INVITE")
	end
end

function script:CHAT_MSG_WHISPER(event, message, sender)
	if (IsPartyLeader() or IsRealRaidLeader() or IsRaidOfficer() or (GetRealNumPartyMembers() == 0)) and strlower(message):match(strlower(LUI.db.profile.General.AutoInviteKeyword)) then
		if LUI.db.profile.General.AutoInviteOnlyFriend == false or (isFriend(sender) or isGuildmate(sender) or isBNFriend(sender)) then
			InviteUnit(sender)
		end
	end
end

function script:PLAYER_ENTERING_WORLD(event)
	script:SetAutoInvite()
	script:SetAutoAccept()
end

script:RegisterEvent("PLAYER_ENTERING_WORLD")

LUI.chatcommands["invite"] = chatcommand
LUI.chatcommands["inv"] = chatcommand