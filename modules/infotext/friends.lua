-- Friends Infotext

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)
local L = LUI.L

---@class LUI.Infotext
local module = LUI:GetModule("Infotext")
local element = module:NewElement("Friends", "AceEvent-3.0")
StaticPopupDialogs["LUI_CONFIRM_REMOVE_BN_FRIEND"] = {
	text = "Remove %s from your Battle.net friends list?",
	button1 = YES,
	button2 = NO,
	OnAccept = function(self, data)
		if data then
			BNRemoveFriend(data)
		end
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}

StaticPopupDialogs["LUI_SET_FRIEND_NOTE"] = {
	text = _G.SET_FRIENDNOTE_LABEL,
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = true,
	maxLetters = 127,
	editBoxWidth = 350,
	OnAccept = function(self, data)
		if not data then return end
		local note = self:GetEditBox():GetText()
		if data.isBattleNet then
			BNSetFriendNote(data.id, note)
		else
			C_FriendList.SetFriendNotes(data.name, note)
		end
	end,
	OnShow = function(self, data)
		self:GetEditBox():SetText((data and data.note) or "")
		self:GetEditBox():SetFocus()
	end,
	EditBoxOnEnterPressed = function(self) self:GetParent():GetButton1():Click() end,
	EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}

-- local copies
local format, max, min = format, math.max, math.min
local C_FriendList, C_PartyInfo, C_BattleNet = _G.C_FriendList, _G.C_PartyInfo, _G.C_BattleNet
local BNet_GetBattlenetClientAtlas = _G.BNet_GetBattlenetClientAtlas
local ToggleFriendsFrame = _G.ToggleFriendsFrame
local BNFeaturesEnabled = _G.BNFeaturesEnabled
local StaticPopup_Show = _G.StaticPopup_Show
local IsControlKeyDown = _G.IsControlKeyDown
local BNGetNumFriends = _G.BNGetNumFriends
local IsAltKeyDown = _G.IsAltKeyDown
local BNConnected = _G.BNConnected
local SetItemRef = _G.SetItemRef
local BNGetInfo = _G.BNGetInfo

-- constants
local FRIENDS_OTHER_NAME_COLOR_CODE = _G.FRIENDS_OTHER_NAME_COLOR_CODE
local FRIENDS_BNET_NAME_COLOR_CODE = _G.FRIENDS_BNET_NAME_COLOR_CODE
local BATTLENET_UNAVAILABLE = _G.BATTLENET_UNAVAILABLE
local BATTLENET_BROADCAST = _G.BATTLENET_BROADCAST
local CHAT_FLAG_AFK = _G.CHAT_FLAG_AFK
local CHAT_FLAG_DND = _G.CHAT_FLAG_DND
local FRIENDS = _G.FRIENDS
local FRIENDS_UPDATE_TIME = 15
local SOCIAL_TAB_FRIENDS = 1
local BNPLAYER_HYPERLINK_FORMAT = "|HBNplayer:%1$s|h[%1$s]|h"
local PLAYER_HYPERLINK_FORMAT = "|Hplayer:%1$s|h[%1$s]|h"
local BNPLAYER_LINK_FORMAT = "BNplayer:%s"
local PLAYER_LINK_FORMAT = "player:%s"

local TEXT_OFFSET = 5
local BC_OFFSET = 20
local SLIDER_OFFSET = -6
local GAP = 10
local BUTTON_HEIGHT = 15
local NAME_COLUMN_MAX = 190
local NOTE_COLUMN_MAX = 160
local ZONE_COLUMN_MAX = 180
local GAME_COLUMN_MAX = 240
local FRIENDS_WIDTH_PADDING = 90
local FRIENDS_HEIGHT_REDUCTION = 24


-- BNET_CLIENT Constants
local BNET_CLIENT_WOW       = _G.BNET_CLIENT_WOW

-- locals
local totalFriends = 0
local onlineFriends = 0
local totalBNFriends = 0
local onlineBNFriends = 0
local infotip
local legendTip

local function SafeValue(value, fallback)
	if value == nil or issecretvalue(value) then return fallback end
	return value
end

local function SetTextColor(fontString, colorName)
	fontString:SetTextColor(module:RGB(colorName))
end

--Add new Static Dialog, called once, no need to have local copies.
StaticPopupDialogs["LUI_SET_BN_BROADCAST"] = {
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
		C_BattleNet.SetCustomMessage(self:GetEditBox():GetText())
	end,
	OnShow = function(self)
		local _, _, _, currentBroadcast = BNGetInfo()
		self:GetEditBox():SetText(SafeValue(currentBroadcast, ""))
		self:GetEditBox():SetFocus()
	end,
	
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide()
	end, 
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

function element:BuildLegend()
	if legendTip then return end

	legendTip = CreateFrame("Frame", nil, UIParent, "TooltipBorderedFrameTemplate")
	legendTip:SetSize(220, 120)
	legendTip:SetFrameStrata("TOOLTIP")
	legendTip:SetClampedToScreen(true)
	module:ApplyInfotipBackdrop(legendTip, "Friends")

	legendTip.title = legendTip:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	legendTip.title:SetPoint("TOPLEFT", 12, -10)
	legendTip.title:SetText("Friends")

	legendTip.alt = legendTip:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	legendTip.alt:SetPoint("TOPLEFT", legendTip.title, "BOTTOMLEFT", 0, -8)
	legendTip.alt:SetText("Alt + Click     Invite")

	legendTip.ctrl = legendTip:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	legendTip.ctrl:SetPoint("TOPLEFT", legendTip.alt, "BOTTOMLEFT", 0, -5)
	legendTip.ctrl:SetText("Ctrl + Click    Edit Note")

	legendTip.middle = legendTip:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	legendTip.middle:SetPoint("TOPLEFT", legendTip.ctrl, "BOTTOMLEFT", 0, -5)
	legendTip.middle:SetText("Middle Click    Remove Friend")

	legendTip.left = legendTip:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	legendTip.left:SetPoint("TOPLEFT", legendTip.middle, "BOTTOMLEFT", 0, -5)
	legendTip.left:SetText("Left Click      Player Whisper")

	legendTip.scroll = legendTip:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	legendTip.scroll:SetPoint("TOPLEFT", legendTip.left, "BOTTOMLEFT", 0, -5)
	legendTip.scroll:SetText("Mouse Wheel     Scroll Friends")

	legendTip:Hide()
end

function element:CreateBroadcast()
	if infotip.broadcast then return infotip.broadcast end
	local bc = infotip:NewLine()
	bc:EnableMouse(true)
	bc:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			StaticPopup_Show("LUI_SET_BN_BROADCAST")
		end
	end)
	
	bc.name = bc:AddFontString("LEFT", module:RGB("Broadcast"))
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
	if infotip and infotip:IsShown() then
		infotip:UpdateTooltip()
	end
end

function element:OnSliderUpdate()
	-- Battle.net and WoW friends share one list and therefore one slider.
	-- Rebuilding the tooltip also clears every stale row anchor before the new
	-- visible range is laid out.
	element:UpdateInfotip()
end

-- ####################################################################################################################
-- ##### Infotext: Battle.net Friends Display #########################################################################
-- ####################################################################################################################

function element:CreateBNFriend(index)
	if infotip.BNFriends[index] then return infotip.BNFriends[index] end
	local bnfriend = infotip:NewLine()
	bnfriend.index = index

	bnfriend.class = bnfriend:AddTexture()
	bnfriend.name = bnfriend:AddFontString("LEFT", bnfriend.class, TEXT_OFFSET)
	bnfriend.gameText = bnfriend:AddFontString("LEFT", bnfriend.name, nil, module:RGB("GameText"))
	bnfriend.level = bnfriend:AddFontString("CENTER", bnfriend.name)
	bnfriend.faction = bnfriend:AddTexture(bnfriend.level, GAP)
	bnfriend.zone = bnfriend:AddFontString("LEFT", bnfriend.faction, TEXT_OFFSET, module:RGB("Zone"))
	bnfriend.note = bnfriend:AddFontString("CENTER", bnfriend.zone, nil, module:RGB("Note"))

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
	bc.text = bc:AddFontString("LEFT", bc.icon, TEXT_OFFSET, module:RGB("FriendBroadcast"))

	infotip.FriendsBC[index] = bc
	return bc
end

function element:GetBNFriendStatusString(isAFK, isDND)
	local statusString = ""

	if isDND then
		statusString = module:ColorText("<DND> ", "Status")
	elseif isAFK then
		statusString = module:ColorText("<AFK> ", "Status")
	end

	return statusString
end

function element:SetFactionIcon(bnfriend, faction)
	bnfriend.faction:SetTexture([[Interface\Glues\CharacterCreate\UI-CharacterCreate-Factions]])
	if faction == "Alliance" then
		bnfriend.faction:SetTexCoord(0.03, 0.47, 0.03, 0.97)
	else
		bnfriend.faction:SetTexCoord(0.53, 0.97, 0.03, 0.97)
	end
end

function element:DisplayBNFriends()
	local classIconWidth, nameColumnWidth, noteColumnWidth, gameColumnWidth = 0, 0, 0, 0
	local levelColumnWidth, factionIconWidth, zoneColumnWidth = 0, 0, 0
	infotip.bnIndex = 0
	infotip.bcIndex = 0
	for _, broadcast in ipairs(infotip.FriendsBC) do broadcast:Hide() end
	-- Iterate the complete list and filter by the authoritative Retail online
	-- flag. Offline favourites may be interleaved with online entries.
	for accountIndex = 1, totalBNFriends do
		local accountInfo = C_BattleNet.GetFriendAccountInfo(accountIndex)
		local gameInfo = accountInfo and accountInfo.gameAccountInfo
		local accountName = accountInfo and SafeValue(accountInfo.accountName)
		-- Blizzard also uses gameAccountInfo.isOnline as the authoritative Retail
		-- state; total entries may include offline favourites between online rows.
		local isOnline = accountInfo and gameInfo and SafeValue(gameInfo.isOnline, false)
		if accountName and gameInfo and isOnline then
			infotip.bnIndex = infotip.bnIndex + 1
			local bnfriend = element:CreateBNFriend(infotip.bnIndex)
			local characterName = SafeValue(gameInfo.characterName, "")
			local client = SafeValue(gameInfo.clientProgram, "")
			local btagString = format("%s%s|r", FRIENDS_BNET_NAME_COLOR_CODE, accountName)
			local statusString = element:GetBNFriendStatusString(SafeValue(accountInfo.isAFK, false), SafeValue(accountInfo.isDND, false))

			bnfriend.unit = characterName
			bnfriend.accountID = SafeValue(accountInfo.bnetAccountID)
			bnfriend.gameAccountID = SafeValue(gameInfo.gameAccountID)
			bnfriend.accountName = accountName
			bnfriend.client = client
			bnfriend.note:SetText(SafeValue(accountInfo.note, ""))
			bnfriend.note:SetShown(module.db.profile.Friends.ShowNotes)
			SetTextColor(bnfriend.gameText, "GameText")
			SetTextColor(bnfriend.zone, "Zone")
			SetTextColor(bnfriend.note, "Note")

			if client == BNET_CLIENT_WOW then
				local class = SafeValue(gameInfo.classFilename) or LUI:GetTokenFromClassName(SafeValue(gameInfo.className))
				bnfriend:SetClassIcon(bnfriend.class, class)
				local nameString = module:ColorText(characterName, class)
				bnfriend.name:SetText(format("%s%s - %s", statusString, btagString, nameString))

				local level = SafeValue(gameInfo.characterLevel)
				bnfriend.level:SetText((level and level > 0) and level or "")
				if level then bnfriend.level:SetTextColor(LUI:GetDifficultyColor(level)) end
				local factionName = SafeValue(gameInfo.factionName)
				if factionName == "Alliance" or factionName == "Horde" then
					element:SetFactionIcon(bnfriend, factionName)
					bnfriend.faction:Show()
					factionIconWidth = max(factionIconWidth, bnfriend.faction:GetWidth())
				else
					bnfriend.faction:Hide()
				end

				local realmString = ""
				local realmName = SafeValue(gameInfo.realmName)
				if realmName and realmName ~= LUI.playerRealm then
					realmString = module:ColorText(" - "..realmName, "GameText")
				end
				bnfriend.zone:SetText(SafeValue(gameInfo.areaName, "")..realmString)
				bnfriend.gameText:Hide()
				bnfriend.level:Show()
				bnfriend.zone:Show()
			else
				if BNet_GetBattlenetClientAtlas then
					bnfriend.class:SetAtlas(BNet_GetBattlenetClientAtlas(client))
				else
					bnfriend.class:SetTexture(nil)
				end
				if characterName ~= "" then
					bnfriend.name:SetText(format("%s%s - %s%s|r", statusString, btagString, FRIENDS_OTHER_NAME_COLOR_CODE, characterName))
				else
					bnfriend.name:SetText(format("%s%s", statusString, btagString))
				end
				bnfriend.gameText:SetText(SafeValue(gameInfo.richPresence, ""))
				bnfriend.level:Hide()
				bnfriend.faction:Hide()
				bnfriend.zone:Hide()
				bnfriend.gameText:Show()
			end

			nameColumnWidth = max(nameColumnWidth, bnfriend.name:GetStringWidth())
			levelColumnWidth = max(levelColumnWidth, bnfriend.level:GetStringWidth())
			zoneColumnWidth = max(zoneColumnWidth, bnfriend.zone:GetStringWidth())
			if module.db.profile.Friends.ShowNotes then
				noteColumnWidth = max(noteColumnWidth, bnfriend.note:GetStringWidth())
			end
			classIconWidth = max(classIconWidth, bnfriend.class:GetWidth())
			gameColumnWidth = max(gameColumnWidth, bnfriend.gameText:GetStringWidth())

			local customMessage = strtrim(SafeValue(accountInfo.customMessage, ""))
			if customMessage ~= "" then
				bnfriend.hasBroadcast = true
				infotip.bcIndex = infotip.bcIndex + 1
				bnfriend.broadcast = element:CreateFriendBroadcast(infotip.bcIndex)
				bnfriend.broadcast.text:SetText(customMessage)
				SetTextColor(bnfriend.broadcast.text, "FriendBroadcast")
				if bnfriend.broadcast:GetHeight() < bnfriend.broadcast.text:GetStringHeight() then
					bnfriend.broadcast:SetHeight(bnfriend.broadcast.text:GetStringHeight() + 3)
				end
			else
				bnfriend.hasBroadcast = false
				bnfriend.broadcast = nil
			end
		end
	end
	nameColumnWidth = math.min(nameColumnWidth, NAME_COLUMN_MAX)
	noteColumnWidth = math.min(noteColumnWidth, NOTE_COLUMN_MAX)
	zoneColumnWidth = math.min(zoneColumnWidth, ZONE_COLUMN_MAX)
	gameColumnWidth = math.min(gameColumnWidth, GAME_COLUMN_MAX)
	for i = 1, #infotip.BNFriends do
		local bnfriend = infotip.BNFriends[i]
		bnfriend.name:SetWidth(nameColumnWidth)
		bnfriend.level:SetWidth(levelColumnWidth)
		bnfriend.zone:SetWidth(zoneColumnWidth)
		bnfriend.note:SetWidth(noteColumnWidth)
		bnfriend.gameText:SetWidth(gameColumnWidth)
		bnfriend:Hide()
		if bnfriend.broadcast then
			bnfriend.broadcast:Hide()
		end
	end

	-- Calculate the length of the BNFriend row. This calculation need to check between
	--  gameText and wow client's toon information is the longest and adds that.
	local maxWidth = TEXT_OFFSET + classIconWidth + nameColumnWidth + noteColumnWidth + GAP * 4
	maxWidth = maxWidth + max(factionIconWidth + zoneColumnWidth + levelColumnWidth + TEXT_OFFSET + GAP, gameColumnWidth)
	infotip.maxWidth = max(infotip.maxWidth, maxWidth)

	-- Broadcast visibility follows its Battle.net friend row.
	for i = 1, #infotip.FriendsBC do
		local bc = infotip.FriendsBC[i]
		bc.text:SetWidth(infotip.maxWidth - BC_OFFSET - TEXT_OFFSET - GAP * 3)
		if i > infotip.bcIndex then bc:Hide() end
	end
end

function element.OnBNFriendButtonClick(bnfriend, button)
	if IsAltKeyDown() then
		if bnfriend.client ~= BNET_CLIENT_WOW or not bnfriend.gameAccountID then return end
		C_BattleNet.InviteFriend(bnfriend.gameAccountID)
	elseif IsControlKeyDown() then
		if not bnfriend.accountID then return end
		StaticPopup_Show("LUI_SET_FRIEND_NOTE", bnfriend.accountName, nil,
			{isBattleNet = true, id = bnfriend.accountID, note = bnfriend.note:GetText()})
	elseif button == "MiddleButton" then
		if not bnfriend.accountID then return end
		StaticPopup_Show("LUI_CONFIRM_REMOVE_BN_FRIEND", bnfriend.accountName, nil, bnfriend.accountID)
	elseif button == "LeftButton" then
		if not bnfriend.accountID then return end
		local name = format("%s:%s", bnfriend.accountName, bnfriend.accountID)
		local playerLink = format(BNPLAYER_LINK_FORMAT, name)
		local playerHyperText = format(BNPLAYER_HYPERLINK_FORMAT, name)
		SetItemRef(playerLink, playerHyperText, button)
	end
end

-- ####################################################################################################################
-- ##### Infotext: Friends Display ####################################################################################
-- ####################################################################################################################

function element:CreateFriend(index)
	if infotip.Friends[index] then return infotip.Friends[index] end
	local friend = infotip:NewLine()
	friend.index = index

	friend.class = friend:AddTexture()
	friend.name = friend:AddFontString("LEFT", friend.class, TEXT_OFFSET)
	friend.level = friend:AddFontString("CENTER", friend.name)
	friend.zone = friend:AddFontString("LEFT", friend.level, nil, module:RGB("Zone"))
	friend.note = friend:AddFontString("CENTER", friend.zone, nil, module:RGB("Note"))

	friend:SetScript("OnClick", element.OnFriendButtonClick)
	friend:AddHighlight()
	infotip.Friends[index] = friend
	return friend
end

function element:GetFriendStatusString(info)
	local status = ""
	if SafeValue(info.dnd, false) then
		status = CHAT_FLAG_DND
	elseif SafeValue(info.afk, false) then
		status = CHAT_FLAG_AFK
	end
	return module:ColorText(status, "Status")
end

function element:DisplayFriends()
	local classIconWidth, nameColumnWidth, levelColumnWidth = 0, 0, 0
	local zoneColumnWidth, noteColumnWidth = 0, 0
	infotip.friendIndex = 0
	-- The current friends list does not guarantee that every online entry is in
	-- the first GetNumOnlineFriends() indices.
	for i = 1, totalFriends do
		local info = C_FriendList.GetFriendInfoByIndex(i)
		local friendName = info and SafeValue(info.name)
		if friendName and SafeValue(info.connected, false) then
			infotip.friendIndex = infotip.friendIndex + 1
			local statusString = element:GetFriendStatusString(info)
			local class = LUI:GetTokenFromClassName(SafeValue(info.className))
			local friend = element:CreateFriend(infotip.friendIndex)
			local r, g, b = module:RGB(class)

			friend.unit = friendName
			friend.name:SetText(statusString..friendName)
			friend.name:SetTextColor(r or 1, g or 1, b or 1)
			friend:SetClassIcon(friend.class, class)
			local level = SafeValue(info.level)
			friend.level:SetText(level or "")
			if level then friend.level:SetTextColor(LUI:GetDifficultyColor(level)) end
			friend.zone:SetText(SafeValue(info.area, _G.UNKNOWN))
			friend.rawNote = SafeValue(info.notes, "")
			friend.note:SetText(friend.rawNote ~= "" and friend.rawNote or "-")
			friend.note:SetShown(module.db.profile.Friends.ShowNotes)
			SetTextColor(friend.zone, "Zone")
			SetTextColor(friend.note, "Note")

			nameColumnWidth = max(nameColumnWidth, friend.name:GetStringWidth())
			levelColumnWidth = max(levelColumnWidth, friend.level:GetStringWidth())
			zoneColumnWidth = max(zoneColumnWidth, friend.zone:GetStringWidth())
			if module.db.profile.Friends.ShowNotes then
				noteColumnWidth = max(noteColumnWidth, friend.note:GetStringWidth())
			end
			classIconWidth = max(classIconWidth, friend.class:GetWidth())
		end
	end
	nameColumnWidth = math.min(nameColumnWidth, NAME_COLUMN_MAX)
	noteColumnWidth = math.min(noteColumnWidth, NOTE_COLUMN_MAX)
	zoneColumnWidth = math.min(zoneColumnWidth, ZONE_COLUMN_MAX)

	for i = 1, #infotip.Friends do
		local friend = infotip.Friends[i]
		friend.name:SetWidth(nameColumnWidth)
		friend.level:SetWidth(levelColumnWidth)
		friend.zone:SetWidth(zoneColumnWidth)
		friend.note:SetWidth(noteColumnWidth)
		friend:Hide()
	end
	local maxWidth = TEXT_OFFSET + classIconWidth + nameColumnWidth + levelColumnWidth
	maxWidth = maxWidth + zoneColumnWidth + noteColumnWidth + GAP * 5
	infotip.maxWidth = max(infotip.maxWidth, maxWidth)
end

function element:LayoutFriendRows(baseHeight)
	local bnCount = infotip.bnIndex or 0
	local friendCount = infotip.friendIndex or 0
	local totalRows = bnCount + friendCount
	local maxWindowHeight = max(BUTTON_HEIGHT,
		UIParent:GetHeight() - GAP * 2 - FRIENDS_HEIGHT_REDUCTION)

	local function GetRow(index)
		if index <= bnCount then
			return infotip.BNFriends[index], true
		end
		return infotip.Friends[index - bnCount], false
	end

	local function GetRowHeight(index)
		local row, isBattleNet = GetRow(index)
		local height = row and row:GetHeight() or BUTTON_HEIGHT
		if isBattleNet and row and row.hasBroadcast and row.broadcast then
			height = height + row.broadcast:GetHeight()
		end
		return height
	end

	-- Find the first row of the final complete page. Battle.net broadcasts are
	-- part of their owner's height, so the slider can always reach the last
	-- friend without rendering a partial row below the frame.
	local lastPageStart = totalRows
	local lastPageHeight = baseHeight
	for index = totalRows, 1, -1 do
		local addedHeight = GetRowHeight(index)
		if index == bnCount and index < totalRows then
			addedHeight = addedHeight + BUTTON_HEIGHT
		end
		if lastPageHeight + addedHeight > maxWindowHeight then break end
		lastPageHeight = lastPageHeight + addedHeight
		lastPageStart = index
	end

	local maxOffset = max(1, lastPageStart)
	if maxOffset > 1 then
		local slider = infotip:EnsureSlider()
		slider:SetMinMaxValues(1, maxOffset)
		slider.updating = true
		slider:SetValue(min(maxOffset, max(1, slider:GetValue())))
		slider.updating = nil
		slider:Show()
		infotip.hasSlider = true
	elseif infotip.slider then
		infotip.slider:Hide()
		infotip.hasSlider = false
	end

	local firstVisible = infotip:GetSliderOffset()
	local previous
	local visibleBN = false
	local visibleFriend = false
	local visibleRows = 0
	infotip.maxHeight = baseHeight

	for _, row in ipairs(infotip.BNFriends) do
		row:Hide()
		if row.broadcast then row.broadcast:Hide() end
	end
	for _, row in ipairs(infotip.Friends) do row:Hide() end
	for _, row in ipairs(infotip.FriendsBC) do row:Hide() end
	if infotip.sep2 then infotip.sep2:Hide() end

	local function AnchorRow(row)
		row:ClearAllPoints()
		if previous then
			row:SetPoint("TOPLEFT", previous, "BOTTOMLEFT")
		elseif infotip.sep and infotip.sep:IsShown() then
			row:SetPoint("TOPLEFT", infotip.sep, "BOTTOMLEFT", GAP, 0)
		else
			row:SetPoint("TOPLEFT", infotip, "TOPLEFT", GAP, -GAP)
		end
		row:Show()
		infotip.maxHeight = infotip.maxHeight + row:GetHeight()
		previous = row
	end

	for index = firstVisible, totalRows do
		local row, isBattleNet = GetRow(index)
		local transitionHeight = visibleBN and not isBattleNet and not visibleFriend and BUTTON_HEIGHT or 0
		local addedHeight = GetRowHeight(index) + transitionHeight
		if visibleRows > 0 and infotip.maxHeight + addedHeight > maxWindowHeight then break end

		if transitionHeight > 0 then
			if not infotip.sep2 then infotip.sep2 = infotip:AddSeparator() end
			infotip.sep2:ClearAllPoints()
			infotip.sep2:SetPoint("TOPLEFT", previous, "BOTTOMLEFT")
			infotip.sep2:Show()
			infotip.maxHeight = infotip.maxHeight + infotip.sep2:GetHeight()
			previous = infotip.sep2
		end

		AnchorRow(row)
		visibleRows = visibleRows + 1
		if isBattleNet then
			visibleBN = true
			if row.hasBroadcast and row.broadcast then
				row.broadcast:ClearAllPoints()
				row.broadcast:SetPoint("TOPLEFT", previous, "BOTTOMLEFT")
				row.broadcast:Show()
				infotip.maxHeight = infotip.maxHeight + row.broadcast:GetHeight()
				previous = row.broadcast
			end
		else
			visibleFriend = true
		end
	end

	if infotip.hasSlider then
		infotip.maxWidth = infotip.maxWidth + infotip.slider:GetWidth()
		infotip.slider:ClearAllPoints()
		infotip.slider:SetPoint("TOPRIGHT", infotip, "TOPRIGHT", SLIDER_OFFSET, -GAP)
		infotip.slider:SetPoint("BOTTOMRIGHT", infotip, "BOTTOMRIGHT", SLIDER_OFFSET, GAP)
	end
end

function element:ApplyRowWidths()
	local sliderWidth = infotip.hasSlider and infotip.slider and infotip.slider:GetWidth() or 0
	local rowWidth = max(1, infotip.maxWidth - GAP * 2 - sliderWidth)
	for _, row in ipairs(infotip.BNFriends) do row:SetWidth(rowWidth) end
	for _, row in ipairs(infotip.Friends) do row:SetWidth(rowWidth) end
	for _, row in ipairs(infotip.FriendsBC) do row:SetWidth(rowWidth) end
	if infotip.broadcast then infotip.broadcast:SetWidth(rowWidth) end
	if infotip.sep then infotip.sep:SetWidth(rowWidth) end
	if infotip.sep2 then infotip.sep2:SetWidth(rowWidth) end
	if infotip.noFriends then infotip.noFriends:SetWidth(rowWidth) end
	if infotip.bnetDown then infotip.bnetDown:SetWidth(rowWidth) end
end

function element.OnFriendButtonClick(friend, button)
	if IsAltKeyDown() then
		C_PartyInfo.InviteUnit(friend.unit)
	elseif IsControlKeyDown() then
		StaticPopup_Show("LUI_SET_FRIEND_NOTE", friend.unit, nil,
			{name = friend.unit, note = friend.rawNote})
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

function element:UpdateFriends()
	local formatString = module.db.profile.Friends.showTotal and "%s: %d/%d" or "%s: %d"
	element.text = format(formatString, FRIENDS, onlineFriends + onlineBNFriends, totalFriends + totalBNFriends)
end

function element:FriendlistUpdate()
	--Make sure we don't query the server more than once per update time.
	element:ResetUpdateTimer()

	totalFriends = SafeValue(C_FriendList.GetNumFriends(), 0)
	onlineFriends = SafeValue(C_FriendList.GetNumOnlineFriends(), 0)
	totalBNFriends, onlineBNFriends = BNGetNumFriends()
	totalBNFriends = SafeValue(totalBNFriends, 0)
	onlineBNFriends = SafeValue(onlineBNFriends, 0)
	element:UpdateFriends()
end

function element.OnClick(frame_, button)
	if button == "RightButton" then
		if not _G.AddFriendFrame_Show then C_AddOns.LoadAddOn("Blizzard_AddFriend") end
		if _G.AddFriendFrame_Show then _G.AddFriendFrame_Show() end
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
	infotip.maxWidth = 0
	infotip.maxHeight = GAP * 2
	infotip.bnIndex = 0
	infotip.bcIndex = 0
	for _, line in ipairs(infotip.BNFriends) do line:Hide() end
	for _, line in ipairs(infotip.FriendsBC) do line:Hide() end
	if infotip.sep then infotip.sep:Hide() end
	if infotip.broadcast then infotip.broadcast:Hide() end
	if infotip.bnetDown then infotip.bnetDown:Hide() end

	-- // BNFriends Code Here
	if BNFeaturesEnabled() then
		if not infotip.sep then infotip.sep = infotip:AddSeparator() end
		infotip.sep:Show()
		if BNConnected() then
			if infotip.bnetDown then infotip.bnetDown:Hide() end

			-- Show Broadcast
			local broadcast = element:CreateBroadcast()
			broadcast:Show()
			
			local _, _, _, currentBroadcast = BNGetInfo()
			currentBroadcast = SafeValue(currentBroadcast, "")
			local broadcastPrefix = CreateColor(1, 1, 1):WrapTextInColorCode(BATTLENET_BROADCAST..":")
			broadcast.name:SetText(format("%s %s", broadcastPrefix or "", currentBroadcast))
			SetTextColor(broadcast.name, "Broadcast")
			infotip.sep:ClearAllPoints()
			infotip.sep:SetPoint("TOPLEFT", broadcast, "BOTTOMLEFT")
			infotip.maxWidth = broadcast.name:GetStringWidth() + GAP * 2
			infotip.maxHeight = broadcast:GetHeight() + infotip.sep:GetHeight() + GAP * 2

			element:DisplayBNFriends()

		else -- not BNConnected()
			--If you get disconnected from BNet but not from WoW, display it.
			if infotip.broadcast then infotip.broadcast:Hide() end
			local bnetDown = element:CreateNegativeLine("bnetDown")
			infotip.sep:ClearAllPoints()
			infotip.sep:SetPoint("TOPLEFT", bnetDown, "BOTTOMLEFT")
			bnetDown.name:SetText(BATTLENET_UNAVAILABLE)
			infotip.maxWidth = bnetDown.name:GetStringWidth() + GAP * 2
			infotip.maxHeight = bnetDown:GetHeight() + infotip.sep:GetHeight() + GAP * 2
		end
	end

	local rowBaseHeight = infotip.maxHeight
	element:DisplayFriends()
	infotip.maxWidth = infotip.maxWidth + FRIENDS_WIDTH_PADDING
	for _, broadcast in ipairs(infotip.FriendsBC) do
		broadcast.text:SetWidth(max(1,
			infotip.maxWidth - BC_OFFSET - TEXT_OFFSET - GAP * 3))
		broadcast:SetHeight(max(BUTTON_HEIGHT, broadcast.text:GetStringHeight() + 3))
	end
	element:LayoutFriendRows(rowBaseHeight)

	-- If no friends are online, display it.
	if (infotip.bnIndex + infotip.friendIndex) == 0 then
		local noFriends = element:CreateNegativeLine("noFriends")
		noFriends:ClearAllPoints()
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

	element:ApplyRowWidths()
	module:SetBoundedInfotipSize(infotip, infotip.maxWidth, infotip.maxHeight)
	infotip:Show()
	if module.db.profile.Friends.ShowHints then
		element:BuildLegend()
		module:ApplyInfotipBackdrop(legendTip, "Friends")
		legendTip:ClearAllPoints()
		if infotip:GetLeft() and infotip:GetLeft() < legendTip:GetWidth() + 8 then
			legendTip:SetPoint("LEFT", infotip, "RIGHT", 8, 0)
		else
			legendTip:SetPoint("RIGHT", infotip, "LEFT", -8, 0)
		end
		legendTip:Show()
	elseif legendTip then
		legendTip:Hide()
	end
end

function element:RefreshSettings()
	element:UpdateFriends()
	if infotip then infotip:Hide() end
	if legendTip then legendTip:Hide() end
end

function element.OnLeave(frame_)
	if infotip and not infotip:IsMouseOver() then
		infotip:Hide()
	end
	
	if legendTip then
		legendTip:Hide()
	end
end

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function element:OnCreate()
	element:AddUpdate(C_FriendList.ShowFriends, FRIENDS_UPDATE_TIME)
	element:RegisterEvent("FRIENDLIST_UPDATE", "FriendlistUpdate")
	C_FriendList.ShowFriends()
	element:FriendlistUpdate()

	element:RegisterEvent("BN_CONNECTED", "FriendlistUpdate")
	element:RegisterEvent("BN_DISCONNECTED", "FriendlistUpdate")
	element:RegisterEvent("BN_FRIEND_LIST_SIZE_CHANGED", "FriendlistUpdate")
	element:RegisterEvent("BN_FRIEND_INFO_CHANGED", "FriendlistUpdate")
	element:RegisterEvent("BN_CUSTOM_MESSAGE_CHANGED", "FriendlistUpdate")
	element:RegisterEvent("BN_CUSTOM_MESSAGE_LOADED", "FriendlistUpdate")
end
