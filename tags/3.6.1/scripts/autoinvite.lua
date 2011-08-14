local _, LUI = ...
local script = LUI:NewScript("AutoInvite", "AceEvent-3.0")

function script:SetAutoAccept()
	if LUI.db.profile.General.AutoAcceptInvite then

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

		self:RegisterEvent("PARTY_INVITE_REQUEST", function(event, sender)
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
		end)
	else
		self:UnregisterEvent("PARTY_INVITE_REQUEST")
	end
end

function script:SetAutoInvite()
	if LUI.db.profile.General.Autoinvite then
		self:RegisterEvent("CHAT_MSG_WHISPER", function(event, message, sender)
			if (IsPartyLeader() or IsRealRaidLeader() or IsRaidOfficer() or (GetRealNumPartyMembers() == 0)) and strlower(message):match(strlower(LUI.db.profile.General.AutoInviteKeyword)) then
				InviteUnit(sender)
			end
		end)
	else
		self:UnregisterEvent("CHAT_MSG_WHISPER")
	end
end

script:RegisterEvent("PLAYER_ENTERING_WORLD", function(event)
	script:SetAutoInvite()
	script:SetAutoAccept()
end)