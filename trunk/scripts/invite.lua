--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: invite.lua
	Description: Autoinvite Module
	Version....: 1.3
	Rev Date...: 08/06/2011 [dd/mm/yyyy]
	
	Edits:
		v1.0: Loui
		v1.1: Hix
		v1.2: Zista
		v1.3: Hix
]] 

local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")

------------------------------------------------------------------------
-- Auto accept invite
------------------------------------------------------------------------

local function SetAutoAcceptInvite()
	if not LUI.db.profile.General.AutoAcceptInvite then return end

	local tAutoAcceptInvite = CreateFrame("Frame")
	tAutoAcceptInvite:RegisterEvent("PARTY_INVITE_REQUEST")
	
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
	
	tAutoAcceptInvite:SetScript("OnEvent", function(self, event, leader)
		if leader == nil then return end
		
		if isFriend(leader) or isGuildmate(leader) or isBNFriend(leader) then
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
end

------------------------------------------------------------------------
-- Auto invite by whisper
------------------------------------------------------------------------

local function SetAutoInvite()
	local general = LUI.db.profile.General

	local autoinvite = CreateFrame("frame")
	autoinvite:RegisterEvent("CHAT_MSG_WHISPER")
	autoinvite:SetScript("OnEvent", function(self, event, msg, sender)
		if general.Autoinvite and (IsPartyLeader("player") or (GetRealNumPartyMembers() == 0)) and msg:lower():match(general.AutoInviteKeyword) then
			InviteUnit(sender)
		end
	end)
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")

f:SetScript("OnEvent", function(self)
	SetAutoInvite()
	SetAutoAcceptInvite()
end)