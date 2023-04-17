-- Friends Infotext

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, LUIAddon
local _, LUI = ...
local L = LUI.L

---@type InfotextModule
local module = LUI:GetModule("Infotext")
local element = module:NewElement("Friends", "AceEvent-3.0")

-- local copies
local format, max = format, math.max
local C_FriendList, C_PartyInfo, C_BattleNet = _G.C_FriendList, _G.C_PartyInfo, _G.C_BattleNet
local FriendsFrame_BattlenetInviteByIndex = _G.FriendsFrame_BattlenetInviteByIndex
local BNet_GetClientTexture = _G.BNet_GetClientTexture
local ToggleFriendsFrame = _G.ToggleFriendsFrame
local BNSetCustomMessage = _G.BNSetCustomMessage
local BNFeaturesEnabled = _G.BNFeaturesEnabled
local StaticPopup_Show = _G.StaticPopup_Show
local IsControlKeyDown = _G.IsControlKeyDown
local BNGetNumFriends = _G.BNGetNumFriends
local BNGetFriendInfo = _G.BNGetFriendInfo
local IsAltKeyDown = _G.IsAltKeyDown
local BNConnected = _G.BNConnected
local SetItemRef = _G.SetItemRef
local BNGetInfo = _G.BNGetInfo

local BNGetNumFriendGameAccounts = _G.BNGetNumFriendGameAccounts
local BNGetFriendGameAccountInfo = _G.BNGetFriendGameAccountInfo

-- constants
local FRIENDS_OTHER_NAME_COLOR_CODE = _G.FRIENDS_OTHER_NAME_COLOR_CODE
local FRIENDS_BNET_NAME_COLOR_CODE = _G.FRIENDS_BNET_NAME_COLOR_CODE
--local FRIENDS_PRESENCE_COLOR_CODE = _G.FRIENDS_PRESENCE_COLOR_CODE
local BATTLENET_UNAVAILABLE = _G.BATTLENET_UNAVAILABLE
local BATTLENET_BROADCAST = _G.BATTLENET_BROADCAST
local CHAT_FLAG_AFK = _G.CHAT_FLAG_AFK
local CHAT_FLAG_DND = _G.CHAT_FLAG_DND
local FRIENDS = _G.FRIENDS
local FRIENDS_UPDATE_TIME = 15
local SOCIAL_TAB_FRIENDS = 1
-- local BLANK_NOTE = "|cffffcc00-"
-- local TOOLTIP_ICON_FORMAT = "|T%s:13:13:0:0|t"
local BNPLAYER_HYPERLINK_FORMAT = "|HBNplayer:%1$s|h[%1$s]|h"
local PLAYER_HYPERLINK_FORMAT = "|Hplayer:%1$s|h[%1$s]|h"
local BNPLAYER_LINK_FORMAT = "BNplayer:%s"
local PLAYER_LINK_FORMAT = "player:%s"

local TEXT_OFFSET = 5
local BC_OFFSET = 20
local GAP = 10


-- BNET_CLIENT Constants
local BNET_CLIENT_WOW       = _G.BNET_CLIENT_WOW
local BNET_CLIENT_APP       = _G.BNET_CLIENT_APP
-- local BNET_CLIENT_SC        = BNET_CLIENT_SC
-- local BNET_CLIENT_SC2       = BNET_CLIENT_SC2
-- local BNET_CLIENT_D3        = BNET_CLIENT_D3
-- local BNET_CLIENT_WTCG      = BNET_CLIENT_WTCG
-- local BNET_CLIENT_HEROES    = BNET_CLIENT_HEROES
-- local BNET_CLIENT_OVERWATCH = BNET_CLIENT_OVERWATCH
-- local BNET_CLIENT_DESTINY2  = BNET_CLIENT_DESTINY2
local BNET_CLIENT_MOBILE    = "BSAp" -- Doesnt seem to have an official constant yet.

-- locals
--local friendEntries = {}
local totalFriends = 0
local onlineFriends = 0
local totalBNFriends = 0
local onlineBNFriends = 0
local infotip
local onBlock

--Add new Static Dialog, called once, no need to have local copies.
StaticPopupDialogs["SET_BN_BROADCAST"] = {
	text = _G.BN_BROADCAST_TOOLTIP,
	button1 = _G.ACCEPT,
	button2 = _G.CANCEL,
	exclusive = true,
	whileDead = true,
	hideOnEscape = true,
	enterClicksFirstButton = true,

	timeout = 0,
	hasEditBox = 1,
	maxLetters = 127,
	OnAccept = function(self)
		BNSetCustomMessage(self.editBox:GetText())
	end,
	OnShow = function(self)
		local _, _, _, currentBroadcast = BNGetInfo()
		self.editBox:SetText(currentBroadcast)
		self.editBox:SetFocus()
	end,
	--[[Not sure if those are needed with hideOnEscape and enterClicksFirstButton
	EditBoxOnEnterPressed = function(self)
		BNSetCustomMessage(self:GetText())
		self:GetParent():Hide()
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide()
	end, --]]
}

-- ####################################################################################################################
-- ##### Infotip Setup ################################################################################################
-- ####################################################################################################################

function element:BuildTooltip()
	infotip = module:NewInfotip(element)
	infotip.BNFriends = {}
	infotip.FriendsBC = {}
	infotip.Friends = {}
end

function element:CreateBroadcast()
	if infotip.broadcast then return infotip.broadcast end
	local bc = infotip:NewLine()
	bc.name = bc:AddFontString("LEFT", element:RGB("Broadcast"))
	bc.name:SetJustifyV("TOP")
	bc.name:SetPoint("TOPLEFT")
	bc.name:SetPoint("TOPRIGHT")
	bc:SetPoint("TOPLEFT", GAP, -GAP)
	infotip.broadcast = bc
	return bc
end

function element:CreateNegativeLine(name)
	if infotip[name] then return infotip[name] end
	local neg = infotip:NewLine()
	neg.name = neg:AddFontString("LEFT", LUI:NegativeColor())
	neg.name:SetJustifyV("TOP")
	neg.name:SetPoint("TOPLEFT")
	neg.name:SetPoint("TOPRIGHT")
	neg:SetPoint("TOPLEFT", GAP, -GAP)
	infotip[name] = neg
	return neg
end

function element:UpdateInfotip()
	if infotip and onBlock then
		infotip:UpdateTooltip()
	end
end

-- ####################################################################################################################
-- ##### Infotext: Battle.net Friends Dispslay ########################################################################
-- ####################################################################################################################

function element:CreateBNFriend(index)
	if infotip.BNFriends[index] then return infotip.BNFriends[index] end
	local bnfriend = infotip:NewLine()
	bnfriend.index = index

	bnfriend.class = bnfriend:AddTexture()
	bnfriend.name = bnfriend:AddFontString("LEFT", bnfriend.class, TEXT_OFFSET)
	bnfriend.gameText = bnfriend:AddFontString("LEFT", bnfriend.name, nil, element:RGB("GameText"))
	bnfriend.level = bnfriend:AddFontString("CENTER", bnfriend.name)
	bnfriend.faction = bnfriend:AddTexture(bnfriend.level, GAP)
	bnfriend.zone = bnfriend:AddFontString("LEFT", bnfriend.faction, TEXT_OFFSET, element:RGB("Zone"))
	bnfriend.note = bnfriend:AddFontString("CENTER", bnfriend.zone, nil, element:RGB("Note"))

	bnfriend:SetScript("OnClick", element.OnBNFriendButtonClick)
	bnfriend:AddHighlight()
	infotip.BNFriends[index] = bnfriend
	return bnfriend
end

function element:CreateFriendBroadcast(index)
	if infotip.FriendsBC[index] then
		infotip.FriendsBC[index]:ResetHeight()
		return infotip.FriendsBC[index]
	end
	local bc = infotip:NewLine()
	bc.index = index

	--Broadcast Icon
	bc.icon = bc:AddTexture(nil, BC_OFFSET)
	bc.icon:SetTexture([[Interface\FriendsFrame\BroadcastIcon]])
	bc.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

	--Broadcast Text
	bc.text = bc:AddFontString("LEFT", bc.icon, TEXT_OFFSET, element:RGB("FriendBroadcast"))

	infotip.FriendsBC[index] = bc
	return bc
end

function element:GetBNFriendStatusString(isAFK, isDND)
	local statusString = ""
	if isDND then
		statusString = module:ColorText(CHAT_FLAG_DND, "Status")
	elseif isAFK then
		statusString = module:ColorText(CHAT_FLAG_AFK, "Status")
	end
	return statusString
end

function element:UpdateBNFriendAnchorPoints(i)
	local bnfriend = infotip.BNFriends[i]
	if i == 1 then
		bnfriend:SetPoint("TOPLEFT", infotip.sep, "BOTTOMLEFT", GAP)
	else
		-- Check if the previous BNFriend has a broadcast.
		local offset = 0
		if infotip.BNFriends[i-1].hasBroadcast then
			offset = infotip.BNFriends[i-1].broadcast:GetHeight()
		end
		bnfriend:SetPoint("TOPLEFT", infotip.BNFriends[i-1], "BOTTOMLEFT", 0, -offset)
	end
end

function element:SetFactionIcon(bnfriend, faction)
	-- Warning: May be localization sensitive. To verify.
	bnfriend.faction:SetTexture([[Interface\Glues\CharacterCreate\UI-CharacterCreate-Factions]])
	if faction == "Alliance" then
		bnfriend.faction:SetTexCoord(0.03, 0.47, 0.03, 0.97)
	else
		bnfriend.faction:SetTexCoord(0.53, 0.97, 0.03, 0.97)
	end
end

-- Boolean function to see if a given client for BNFriend should be shown.
-- Note: This could allow for not filtering out app clients in the future.
function element:IsBNClientShown(i, index)
	local numAccounts = C_BattleNet.GetFriendNumGameAccounts(i)
	local _, _, client = C_BattleNet.GetFriendGameAccountInfo(i, index)

	-- Friend only has one account
	if numAccounts == 1 then return true end

	-- If connected on a client and also on the app.
	if (numAccounts > 1 and client ~= BNET_CLIENT_APP and client ~= BNET_CLIENT_MOBILE) then return true end

	--Previous check filters out people connected on mobile and app at same time, or connected on two apps.
	local _, _, nextClient = C_BattleNet.GetFriendGameAccountInfo(i, index + 1)
	if numAccounts == 2 and client == BNET_CLIENT_APP and
	    (nextClient == BNET_CLIENT_MOBILE or nextClient == BNET_CLIENT_APP) then
		return true
	end
	return false
end

function element:DisplayBNFriends()
	local classIconWidth, nameColumnWidth, noteColumnWidth, gameColumnWidth = 0, 0, 0, 0
	local levelColumnWidth, factionIconWidth, zoneColumnWidth = 0, 0, 0
	infotip.bnIndex = 0 -- BNFriends
	infotip.bcIndex = 0 -- Friend Broadcasts
	local total, bnetOnline, fav, favOnline = BNGetNumFriends()
	local favOffset = fav - favOnline

	for i = 1, bnetOnline do
		-- Since offline favorites show before other online friends, we need to offset to skip over those
		local offset = (i > favOnline) and favOffset or 0
		local acc = C_BattleNet.GetFriendAccountInfo(i+offset)
		local game = acc.gameAccountInfo

		local btagString = format("%s%s|r", FRIENDS_BNET_NAME_COLOR_CODE, acc.accountName)
		local statusString = element:GetBNFriendStatusString(acc.isAFK, acc.isDND)

		-- if element:IsBNClientShown(i, accountIndex) then
			infotip.bnIndex = infotip.bnIndex + 1
			local bnfriend = element:CreateBNFriend(infotip.bnIndex)
			bnfriend.unit = game.characterName
			bnfriend.accountID = acc.bnetAccountID
			bnfriend.accountName = acc.accountName
			bnfriend.client = game.clientProgram
			bnfriend.note:SetText(acc.note or "")
			bnfriend.lastOnline = acc.lastOnlineTime
			bnfriend.isOnline = acc.isOnline

			-- WoW BN Friends have additional information about their currently active toon.
			if game.clientProgram == BNET_CLIENT_WOW then
				-- Name Column
				local class = LUI:GetTokenFromClassName(game.className)
				bnfriend:SetClassIcon(bnfriend.class, class)
				local nameString = module:ColorText(game.characterName, class)
				bnfriend.name:SetText(format("%s%s - %s",statusString, btagString, nameString))

				-- Level/Faction Column - Only displayed for WoW toons.
				bnfriend.level:SetText(game.characterLevel or "")
				bnfriend.level:SetTextColor(LUI:GetDifficultyColor(game.characterLevel))
				element:SetFactionIcon(bnfriend, game.factionName)

				-- Zone Column - Also display Realm if they are on a different one.
				local realmString = ""
				if game.realmName ~= LUI.playerRealm then
					realmString = module:ColorText(" - "..(game.realmName or ""), "GameText")
				end
				bnfriend.zone:SetText((game.areaName or "")..realmString)

				--Hide GameText, only used for other clients.
				bnfriend.gameText:Hide()
				bnfriend.faction:Show()
				bnfriend.level:Show()
				bnfriend.zone:Show()
			else
				-- bnfriend.class:SetTexture(BNet_GetClientTexture(client))
				bnfriend.class:SetTexCoord(0.2, 0.8, 0.2, 0.8)
				-- if no character name is given, it will be an empty string instead of nil.
				if game.characterName and not game.characterName == "" then
					local nameString = FRIENDS_OTHER_NAME_COLOR_CODE..(game.characterName)
					bnfriend.name:SetText(format("%s%s - %s", statusString, btagString, nameString))
				else
					bnfriend.name:SetText(format("%s%s", statusString, btagString))
				end
				bnfriend.gameText:SetText(game.richPresence or "")
				-- Hide wow-centric fontstrings
				bnfriend.level:Hide()
				bnfriend.faction:Hide()
				bnfriend.zone:Hide()
				bnfriend.gameText:Show()
			end

			nameColumnWidth  = max(nameColumnWidth,  bnfriend.name:GetStringWidth())
			levelColumnWidth = max(levelColumnWidth, bnfriend.level:GetStringWidth())
			zoneColumnWidth  = max(zoneColumnWidth,  bnfriend.zone:GetStringWidth())
			noteColumnWidth  = max(noteColumnWidth,  bnfriend.note:GetStringWidth())
			classIconWidth   = max(classIconWidth,   bnfriend.class:GetWidth())
			gameColumnWidth  = max(gameColumnWidth,  bnfriend.gameText:GetStringWidth())
		-- end


		local bnfriend = infotip.BNFriends[infotip.bnIndex]
		--Make sure to only display broaawdcast once per friend.
		if acc.broadcast and acc.broadcast ~= "" then
			bnfriend.hasBroadcast = true
			infotip.bcIndex = infotip.bcIndex + 1
			bnfriend.broadcast = element:CreateFriendBroadcast(infotip.bcIndex)
			bnfriend.broadcast.text:SetText(acc.customMessage)
			-- Adjust height if string gets wrapped.
			if bnfriend.broadcast:GetHeight() < bnfriend.broadcast.text:GetStringHeight() then
			-- 3 seems to be the difference between StringHeight and Height for non-wrapped lines
			-- Keep that difference to prevent the text from looking squeezed.
				bnfriend.broadcast:SetHeight(bnfriend.broadcast.text:GetStringHeight() + 3)
			end
			bnfriend.broadcast:SetPoint("TOPLEFT", bnfriend, "BOTTOMLEFT")
		else
			bnfriend.hasBroadcast = false
		end
	end

	for i = 1, #infotip.BNFriends do
		local bnfriend = infotip.BNFriends[i]
		bnfriend.name:SetWidth(nameColumnWidth)
		bnfriend.level:SetWidth(levelColumnWidth)
		bnfriend.zone:SetWidth(zoneColumnWidth)
		bnfriend.note:SetWidth(noteColumnWidth)
		bnfriend.gameText:SetWidth(gameColumnWidth)
		element:UpdateBNFriendAnchorPoints(i)

		-- Show/Hide the needed members.
		if i > infotip.bnIndex then bnfriend:Hide()
		else
			infotip.maxHeight = infotip.maxHeight + bnfriend:GetHeight()
			bnfriend:Show()
		end
	end

	-- Calculate the length of the BNFriend row. This calculation need to check between
	--  gameText and wow client's toon information is the longest and adds that.
	local maxWidth = TEXT_OFFSET + classIconWidth + nameColumnWidth + noteColumnWidth + GAP * 4
	maxWidth = maxWidth + max(factionIconWidth + zoneColumnWidth + levelColumnWidth + TEXT_OFFSET + GAP, gameColumnWidth)
	infotip.maxWidth = max(infotip.maxWidth, maxWidth)

	--Set the broadcast lines to be equal to infotip width.
	for i = 1, #infotip.FriendsBC do
		local bc = infotip.FriendsBC[i]
		bc.text:SetWidth(infotip.maxWidth - BC_OFFSET - TEXT_OFFSET - GAP * 3)

		if i > infotip.bcIndex then bc:Hide()
		else
			infotip.maxHeight = infotip.maxHeight + bc:GetHeight()
			bc:Show()
		end
	end
end

function element.OnBNFriendButtonClick(bnfriend, button)
	if IsAltKeyDown() then
		if bnfriend.client ~= BNET_CLIENT_WOW then return end
		FriendsFrame_BattlenetInviteByIndex(bnfriend.index)
	elseif IsControlKeyDown() then
		_G.FriendsFrame.NotesID = bnfriend.accountID
		StaticPopup_Show("SET_BNFRIENDNOTE", bnfriend.accountName)
	elseif button == "MiddleButton" then
		StaticPopup_Show("CONFIRM_REMOVE_FRIEND", bnfriend.accountName, nil, bnfriend.accountID)
	elseif button == "LeftButton" then
		local name = format("%s:%s", bnfriend.accountName, bnfriend.accountID)
		local playerLink = format(BNPLAYER_LINK_FORMAT, name)
		local playerHyperText = format(BNPLAYER_HYPERLINK_FORMAT, name)
		SetItemRef(playerLink, playerHyperText, button)
	end
end

-- ####################################################################################################################
-- ##### Infotext: Friends Dispslay ###################################################################################
-- ####################################################################################################################

function element:CreateFriend(index)
	if infotip.Friends[index] then return infotip.Friends[index] end
	local friend = infotip:NewLine()
	friend.index = index

	friend.class = friend:AddTexture()
	friend.name = friend:AddFontString("LEFT", friend.class, TEXT_OFFSET)
	friend.level = friend:AddFontString("CENTER", friend.name)
	friend.zone = friend:AddFontString("LEFT", friend.level, nil, element:RGB("Zone"))
	friend.note = friend:AddFontString("CENTER", friend.zone, nil, element:RGB("Note"))

	friend:SetScript("OnClick", element.OnFriendButtonClick)
	friend:AddHighlight()
	infotip.Friends[index] = friend
	return friend
end

function element:GetFriendStatusString(info)
	local status = ""
	if info.dnd then
		status = CHAT_FLAG_DND
	elseif info.afk then
		status = CHAT_FLAG_AFK
	end
	return module:ColorText(status, "Status")
end

function element:UpdateFriendAnchorPoints(i)
	if i == 1 then
		if infotip.sep2 and infotip.sep2:IsShown() then
			infotip.Friends[i]:SetPoint("TOPLEFT", infotip.sep2, "BOTTOMLEFT", GAP)
		else
			infotip.Friends[i]:SetPoint("TOPLEFT", infotip.sep, "BOTTOMLEFT", GAP)
		end
	else
		infotip.Friends[i]:SetPoint("TOPLEFT", infotip.Friends[i-1], "BOTTOMLEFT")
	end
end

function element:DisplayFriends()
	local classIconWidth, nameColumnWidth, levelColumnWidth = 0, 0, 0
	local zoneColumnWidth, noteColumnWidth = 0, 0
	for i = 1, onlineFriends do
		--local name, level, class, zone, _, status, note = GetFriendInfo(i)
		local info = C_FriendList.GetFriendInfoByIndex(i)
		local statusString = element:GetFriendStatusString(info)
		--GetFriendInfo returns a localized class name, we need a token to work with.
		local class = LUI:GetTokenFromClassName(info.className)
		local friend = element:CreateFriend(i)

		local r, g, b = element:RGB(class)

		-- Name Column
		friend.unit = info.name
		friend.name:SetText(statusString..info.name)
		friend.name:SetTextColor(r or 1, g or 1, b or 1)
		friend:SetClassIcon(friend.class, class)

		friend.level:SetText(info.level or "")
		friend.level:SetTextColor(LUI:GetDifficultyColor(info.level))

		friend.zone:SetText(info.area or _G.UNKNOWN)
		friend.note:SetText(info.notes or "-")

		nameColumnWidth  = max(nameColumnWidth,  friend.name:GetStringWidth())
		levelColumnWidth = max(levelColumnWidth, friend.level:GetStringWidth())
		zoneColumnWidth  = max(zoneColumnWidth,  friend.zone:GetStringWidth())
		noteColumnWidth  = max(noteColumnWidth,  friend.note:GetStringWidth())
		classIconWidth   = max(classIconWidth,   friend.class:GetWidth())
	end

	for i = 1, #infotip.Friends do
		local friend = infotip.Friends[i]
		friend.name:SetWidth(nameColumnWidth)
		friend.level:SetWidth(levelColumnWidth)
		friend.zone:SetWidth(zoneColumnWidth)
		friend.note:SetWidth(noteColumnWidth)
		element:UpdateFriendAnchorPoints(i)

		-- Show/Hide the needed members.
		if i > onlineFriends then friend:Hide()
		else
			infotip.maxHeight = infotip.maxHeight + friend:GetHeight()
			friend:Show()
		end
	end
	local maxWidth = TEXT_OFFSET + classIconWidth + nameColumnWidth + levelColumnWidth
	maxWidth = maxWidth + zoneColumnWidth + noteColumnWidth + GAP * 5
	infotip.maxWidth = max(infotip.maxWidth, maxWidth)
end

function element.OnFriendButtonClick(friend, button)
	if IsAltKeyDown() then
		C_PartyInfo.InviteUnit(friend.unit)
	elseif IsControlKeyDown() then
		_G.FriendsFrame.NotesID = friend.index
		StaticPopup_Show("SET_FRIENDNOTE", friend.unit)
	elseif button == "MiddleButton" then
		C_FriendList.RemoveFriend(friend.unit)
	elseif button == "LeftButton" then
		local playerLink = format(PLAYER_LINK_FORMAT, friend.unit)
		local playerHyperText = format(PLAYER_HYPERLINK_FORMAT, friend.unit)
		SetItemRef(playerLink, playerHyperText, button)
	end
end

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################
 -- Friends/Guild have different tooltip implementation, comment all tooltip updates for now.

function element:UpdateFriends()
	local formatString = (module.db.profile.showTotal) and "%s: %d/%d" or "%s: %d"
	element.text = format(formatString, FRIENDS, onlineFriends + onlineBNFriends, totalFriends + totalBNFriends)
	--tooltip:Update()
end

function element:FriendlistUpdate()
	--Make sure we don't query the server more than once per update time.
	element:ResetUpdateTimer()

	totalFriends, onlineFriends = C_FriendList.GetNumFriends(), C_FriendList.GetNumOnlineFriends()
	totalBNFriends, onlineBNFriends = BNGetNumFriends()
	element:UpdateFriends()
end

--Hints:
--Click to open Friends List.
--Right-Click to add a Friend.
--Button4 to toggle notes.
function element.OnClick(frame_, button)
	if button == "RightButton" then
		_G.FriendsFrameAddFriendButton:Click()
	elseif button == "Button4" then
		--db.showNotes = not db.showNotes
		--tooltip:Update()
	else
		-- Click: Toggle Friends frame, 1st tab.
		ToggleFriendsFrame(SOCIAL_TAB_FRIENDS)
	end
end

-- ####################################################################################################################
-- ##### Infotext Display #############################################################################################
-- ####################################################################################################################

function element.OnEnter(frame_)
	C_FriendList.ShowFriends()
	if not infotip then element:BuildTooltip() end

	-- // BNFriends Code Here
	if BNFeaturesEnabled() then
		if not infotip.sep then infotip.sep = infotip:AddSeparator() end
		if BNConnected() then
			if infotip.bnetDown then infotip.bnetDown:Hide() end

			-- Show Broadcast
			local broadcast = element:CreateBroadcast()
			local _, _, _, currentBroadcast = BNGetInfo()
			local broadcastPrefix = CreateColor(1, 1, 1):WrapTextInColorCode(BATTLENET_BROADCAST..":")
			broadcast.name:SetText( format("%s %s", broadcastPrefix or "", currentBroadcast or "") )
			infotip.sep:SetPoint("TOPLEFT", broadcast, "BOTTOMLEFT")
			infotip.maxWidth = broadcast.name:GetStringWidth() + GAP * 2
			infotip.maxHeight = broadcast:GetHeight() + infotip.sep:GetHeight() + GAP * 2

			element:DisplayBNFriends()

		else -- not BNConnected()
			--If you get disconnected from BNet but not from WoW, display it.
			if infotip.broadcast then infotip.broadcast:Hide() end
			local bnetDown = element:CreateNegativeLine("bnetDown")
			infotip.sep:SetPoint("TOPLEFT", bnetDown, "BOTTOMLEFT")
			bnetDown.name:SetText(BATTLENET_UNAVAILABLE)
			infotip.maxWidth = bnetDown.name:GetStringWidth() + GAP * 2
			infotip.maxHeight = bnetDown:GetHeight() + infotip.sep:GetHeight() + GAP * 2
		end
	end

	-- If there are BNFriends and Friends online, show a second separator between them.
	if onlineBNFriends > 0 and onlineFriends > 0 then
		if not infotip.sep2 then infotip.sep2 = infotip:AddSeparator() end
		local sepAnchor = infotip.BNFriends[infotip.bnIndex]
		if infotip.BNFriends[infotip.bnIndex].hasBroadcast then
			sepAnchor = infotip.BNFriends[infotip.bnIndex].broadcast
		end
		infotip.sep2:SetPoint("TOPLEFT", sepAnchor, "BOTTOMLEFT")
		infotip.maxHeight = infotip.maxHeight + infotip.sep2:GetHeight()
		infotip.sep2:Show()
	else
		if infotip.sep2 then infotip.sep2:Hide() end
	end

	element:DisplayFriends()

	-- If no friends are online, display it.
	if (onlineFriends + onlineBNFriends) == 0 then
		local noFriends = element:CreateNegativeLine("noFriends")
		-- if you're on an account with BNet disabled, no separator are created.
		if infotip.sep then
			noFriends:SetPoint("TOPLEFT", infotip.sep, "BOTTOMLEFT")
			infotip.maxHeight = infotip.maxHeight + noFriends:GetHeight()
		else
			noFriends:SetPoint("TOPLEFT", GAP, -GAP)
			infotip.maxHeight = noFriends:GetHeight() + GAP * 2
		end
		noFriends.name:SetText(L["InfoFriends_NoFriends"])
		infotip.maxWidth = max(infotip.maxWidth, noFriends.name:GetStringWidth() + GAP*2)
	else
		if infotip.noFriends then infotip.noFriends:Hide() end
	end

	infotip:SetWidth(infotip.maxWidth)
	infotip:SetHeight(infotip.maxHeight)
	infotip:Show()
	onBlock = true
end

function element.OnLeave(frame_)
	if not infotip:IsMouseOver() then
		infotip:Hide()
		onBlock = false
	end
end

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function element:OnCreate()
	element:AddUpdate(C_FriendList.ShowFriends, FRIENDS_UPDATE_TIME)
	element:FriendlistUpdate()
	element:RegisterEvent("FRIENDLIST_UPDATE", "FriendlistUpdate")
	C_FriendList.ShowFriends()

	element:RegisterEvent("BN_CONNECTED", "UpdateFriends")
	element:RegisterEvent("BN_DISCONNECTED", "UpdateFriends")
	element:RegisterEvent("BN_FRIEND_ACCOUNT_ONLINE", "UpdateFriends")
	element:RegisterEvent("BN_FRIEND_ACCOUNT_OFFLINE", "UpdateFriends")
end
