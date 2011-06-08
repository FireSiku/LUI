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
	tAutoAcceptInvite:RegisterEvent("PARTY_MEMBERS_CHANGED")
	
	-- used to hide static popup when auto-accepting
	local hidestatic
	
	tAutoAcceptInvite:SetScript("OnEvent", function(self, event, ...)
		local leader = ...
		
		if event == "PARTY_INVITE_REQUEST" then
			if (GetNumRealPartyMembers() > 0) or (GetNumRealRaidMembers() > 0) then return end
						
			for friendIndex = 1, GetNumFriends() do
				local friendName = GetFriendInfo(friendIndex)
				if friendName == leader then
					AcceptGroup()
					hidestatic = true
					return
				end
			end
			
			for guildIndex = 1, GetNumGuildMembers(true) do
				local guildMemberName = GetGuildRosterInfo(guildIndex)
				if guildMemberName == leader then
					AcceptGroup()
					hidestatic = true
					return
				end
			end
		elseif event == "PARTY_MEMBERS_CHANGED" and hidestatic == true then
			for i=1, STATICPOPUP_NUMDIALOGS do
				local dlg = _G["StaticPopup"..i]
				if dlg.which == "PARTY_INVITE" then
					dlg.inviteAccepted = 1
					break
				end
			end
			StaticPopup_Hide("PARTY_INVITE")
			hidestatic = false
		end
	end)
end

------------------------------------------------------------------------
-- Auto invite by whisper
------------------------------------------------------------------------

local function SetAutoInvite()
	local enabled = LUI.db.profile.General.Autoinvite
	local keyword = LUI.db.profile.General.AutoInviteKeyword

	local autoinvite = CreateFrame("frame")
	autoinvite:RegisterEvent("CHAT_MSG_WHISPER")
	autoinvite:SetScript("OnEvent", function(self, event, msg, sender)
		if enabled and (IsPartyLeader("player") or (GetRealNumPartyMembers() == 0) and msg:lower():match(keyword) then
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