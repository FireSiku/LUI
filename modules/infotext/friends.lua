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
local NOTE_COLUMN_MAX = 160
local GAME_COLUMN_MAX = 240
local FRIENDS_WIDTH_PADDING = 90
local FRIENDS_HEIGHT_REDUCTION = 24
local FRIENDS_SLIDER_WIDTH = 16


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
	if issecretvalue(value) or value == nil then return fallback end
	return value
end

local function FitColumnWidth(requiredWidth, otherColumnsWidth)
	-- Keep complete text on one line whenever the screen allows it.
	-- Reserve the window padding and scrollbar before allocating this column.
	local sliderWidth = infotip.slider and infotip.slider:GetWidth() or FRIENDS_SLIDER_WIDTH
	local available = max(1, UIParent:GetWidth() - GAP * 2 - sliderWidth
		- FRIENDS_WIDTH_PADDING - otherColumnsWidth)
	return min(requiredWidth, available)
end

local function SetTextColor(fontString, colorName)
	fontString:SetTextColor(module:RGB(colorName))
end

-- The edit box needs its own Enter handler: enterClicksFirstButton alone
-- does not confirm while typing. Share the save action with Accept.
local function SaveBroadcast(dialog)
    C_BattleNet.SetCustomMessage(SafeValue(dialog:GetEditBox():GetText(), ""))
end

--Add new Static Dialog, called once, no need to have local copies.
StaticPopupDialogs["LUI_SET_BN_BROADCAST"] = {
	text = _G.BN_BROADCAST_TOOLTIP,
	button1 = _G.ACCEPT,
	button2 = _G.CANCEL,
	exclusive = true,
	whileDead = true,
	hideOnEscape = true,

	timeout = 0,
	hasEditBox = 1,
	maxLetters = 127,
	OnAccept = SaveBroadcast,
	OnShow = function(self)
		local _, _, _, currentBroadcast = BNGetInfo()
		self:GetEditBox():SetText(SafeValue(currentBroadcast, ""))
		self:GetEditBox():SetFocus()
	end,
	
    EditBoxOnEnterPressed = function(editBox)
        local dialog = editBox.GetOwningDialog and editBox:GetOwningDialog() or editBox:GetParent()
        if not dialog or not dialog:GetButton1():IsEnabled() then return end
        SaveBroadcast(dialog)
        dialog:Hide()
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
	infotip:HookScript("OnHide", function()
		if legendTip then legendTip:Hide() end
	end)
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

-- Optional Retail-only Raider.IO integration. Resolve the displayed character,
-- never a different character on the same Battle.net account.
local scoreRegions = {"us", "kr", "eu", "tw", "cn"}

function element:IsFriendScoreEnabled()
    return LUI.IsRetail and module.db.profile.Friends.ShowScore
        and type(_G.RaiderIO) == "table" and type(_G.RaiderIO.GetProfile) == "function"
end

function element:UpdateFriendScore(row, name, realm, region)
    row.score:SetText("")
    row.score:Hide()
    row.scoreName, row.scoreRealm, row.scoreRegion = nil, nil, nil
    if not self:IsFriendScoreEnabled() then return end
    name, realm, region = SafeValue(name), SafeValue(realm), SafeValue(region)
    if type(name) ~= "string" or name == "" or type(realm) ~= "string" or realm == "" then return end
    local ok, profile = pcall(_G.RaiderIO.GetProfile, name, realm, region)
    profile = ok and SafeValue(profile)
    if type(profile) ~= "table" or not SafeValue(profile.success, false) then return end
    local keystone = SafeValue(profile.mythicKeystoneProfile)
    if type(keystone) ~= "table" or (issecretvalue(keystone.blocked) or keystone.blocked)
        or not SafeValue(keystone.hasRenderableData, false) then return end
    local score = SafeValue(keystone.currentScore)
    if type(score) ~= "number" or not (score >= 0 and score < math.huge) then return end
    row.scoreName, row.scoreRealm, row.scoreRegion = name, realm, region
    row.score:SetText(format("M+ %.0f", score))
    row.score:SetTextColor(1, 1, 1)
    if type(_G.RaiderIO.GetScoreColor) == "function" then
        local colorOK, red, green, blue = pcall(_G.RaiderIO.GetScoreColor, score)
        red, green, blue = SafeValue(red), SafeValue(green), SafeValue(blue)
        if colorOK and type(red) == "number" and type(green) == "number" and type(blue) == "number" then
            row.score:SetTextColor(red, green, blue)
        end
    end
    row.score:Show()
end

function element:GetBNScoreIdentity(gameInfo)
    if not LUI.IsRetail or SafeValue(gameInfo.clientProgram) ~= BNET_CLIENT_WOW
        or SafeValue(gameInfo.wowProjectID) ~= WOW_PROJECT_MAINLINE then return end
    local region = scoreRegions[SafeValue(gameInfo.regionID, 0)]
    if not region and not SafeValue(gameInfo.isInCurrentRegion, false) then return end
    return SafeValue(gameInfo.characterName), SafeValue(gameInfo.realmName), region
end

local function HideFriendScoreTooltip(row)
    if GameTooltip and GameTooltip:IsOwned(row) then GameTooltip:Hide() end
end

-- Place the detail tooltip beside the whole Friends window, on the side
-- facing the screen centre. Compare physical dimensions to support UI scaling.
function element:PositionFriendScoreTooltip(row)
    local tip = GameTooltip
    local uiScale, tipScale = UIParent:GetEffectiveScale(), tip:GetEffectiveScale()
    local windowScale, rowScale = infotip:GetEffectiveScale(), row:GetEffectiveScale()
    local left, right, top = infotip:GetLeft(), infotip:GetRight(), row:GetTop()
    if not left or not right or not top then return end
    local screenWidth, screenHeight = UIParent:GetWidth() * uiScale, UIParent:GetHeight() * uiScale
    local width, height = tip:GetWidth() * tipScale, tip:GetHeight() * tipScale
    local gap = 8 * uiScale
    left, right, top = left * windowScale, right * windowScale, top * rowScale
    local owner = infotip:GetParent()
    local centre = owner and owner:GetCenter()
    centre = centre and centre * owner:GetEffectiveScale() or (left + right) / 2
    local useLeft = centre >= screenWidth / 2
    local leftSpace, rightSpace = left - gap * 2, screenWidth - right - gap * 2
    if useLeft and leftSpace < width and rightSpace >= width then
        useLeft = false
    elseif not useLeft and rightSpace < width and leftSpace >= width then
        useLeft = true
    elseif leftSpace < width and rightSpace < width then
        useLeft = leftSpace >= rightSpace
    end
    local x = useLeft and (left - gap - width) or (right + gap)
    -- Very wide lists may leave neither side enough room. Keep the details
    -- readable within the screen, allowing only the unavoidable overlap.
    x = max(gap, min(x, screenWidth - width - gap))
    local y = min(screenHeight - gap, max(top, height + gap))
    tip:ClearAllPoints()
    tip:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / tipScale, y / tipScale)
end

function element:AddFriendScore(row)
    row.score = row:AddFontString("RIGHT", row.zone, GAP)
    row.score:SetWordWrap(false)
    row.score:Hide()
    row:HookScript("OnEnter", function(self)
        if not element:IsFriendScoreEnabled() or not module.db.profile.Friends.ShowScoreDetails
            or not self.scoreName or type(_G.RaiderIO.ShowProfile) ~= "function" then return end
        GameTooltip:SetOwner(self, "ANCHOR_NONE")
        GameTooltip:SetText(self.scoreName.." - "..self.scoreRealm)
        local ok, shown = pcall(_G.RaiderIO.ShowProfile, GameTooltip,
            self.scoreName, self.scoreRealm, self.scoreRegion)
        if not ok or not shown then
            HideFriendScoreTooltip(self)
        else
            element:PositionFriendScoreTooltip(self)
        end
    end)
    row:HookScript("OnLeave", HideFriendScoreTooltip)
    row:HookScript("OnHide", HideFriendScoreTooltip)
end

function element:PositionFriendScore(row, width, isWoW)
    row.score:ClearAllPoints()
    row.score:SetPoint("LEFT", row.zone, "RIGHT", GAP, 0)
    row.score:SetWidth(max(1, width))
    row.score:SetShown(isWoW and width > 0)
    row.note:ClearAllPoints()
    local anchor = not isWoW and row.gameText or (width > 0 and row.score or row.zone)
    row.note:SetPoint("LEFT", anchor, "RIGHT", GAP, 0)
end

function element:CreateBNFriend(index)
	if infotip.BNFriends[index] then return infotip.BNFriends[index] end
	local bnfriend = infotip:NewLine()
	bnfriend.index = index

	bnfriend.class = bnfriend:AddTexture()
	bnfriend.name = bnfriend:AddFontString("LEFT", bnfriend.class, TEXT_OFFSET)
	bnfriend.name:SetWordWrap(false)
	bnfriend.gameText = bnfriend:AddFontString("LEFT", bnfriend.name, nil, module:RGB("GameText"))
	bnfriend.level = bnfriend:AddFontString("CENTER", bnfriend.name)
	bnfriend.faction = bnfriend:AddTexture(bnfriend.level, GAP)
	bnfriend.zone = bnfriend:AddFontString("LEFT", bnfriend.faction, TEXT_OFFSET, module:RGB("Zone"))
	bnfriend.note = bnfriend:AddFontString("CENTER", bnfriend.zone, nil, module:RGB("Note"))

	bnfriend:SetScript("OnClick", element.OnBNFriendButtonClick)
	bnfriend:AddHighlight()
	element:AddFriendScore(bnfriend)
	infotip.BNFriends[index] = bnfriend
	return bnfriend
end

function element:CreateFriendBroadcast(index)
	if infotip.FriendsBC[index] then return infotip.FriendsBC[index] end
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
	local scoreColumnWidth = 0
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
            element:UpdateFriendScore(bnfriend, element:GetBNScoreIdentity(gameInfo))
            scoreColumnWidth = max(scoreColumnWidth, module:GetInfotipTextWidth(bnfriend.score))
			bnfriend.note:SetText(SafeValue(accountInfo.note, ""))
			bnfriend.note:SetShown(module.db.profile.Friends.ShowNotes)
			SetTextColor(bnfriend.gameText, "GameText")
			SetTextColor(bnfriend.zone, "Zone")
			SetTextColor(bnfriend.note, "Note")

			if client == BNET_CLIENT_WOW then
				bnfriend.note:ClearAllPoints()
				bnfriend.note:SetPoint("LEFT", bnfriend.zone, "RIGHT", GAP, 0)
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
				bnfriend.note:ClearAllPoints()
				bnfriend.note:SetPoint("LEFT", bnfriend.gameText, "RIGHT", GAP, 0)
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

			nameColumnWidth = max(nameColumnWidth, module:GetInfotipTextWidth(bnfriend.name))
			levelColumnWidth = max(levelColumnWidth, module:GetInfotipTextWidth(bnfriend.level))
			zoneColumnWidth = max(zoneColumnWidth, module:GetInfotipTextWidth(bnfriend.zone))
			if module.db.profile.Friends.ShowNotes then
				noteColumnWidth = max(noteColumnWidth, module:GetInfotipTextWidth(bnfriend.note))
			end
			classIconWidth = max(classIconWidth, bnfriend.class:GetWidth())
			gameColumnWidth = max(gameColumnWidth, module:GetInfotipTextWidth(bnfriend.gameText))

			local customMessage = strtrim(SafeValue(accountInfo.customMessage, ""))
			if customMessage ~= "" then
				bnfriend.hasBroadcast = true
				infotip.bcIndex = infotip.bcIndex + 1
				bnfriend.broadcast = element:CreateFriendBroadcast(infotip.bcIndex)
				bnfriend.broadcast.text:SetText(customMessage)
				SetTextColor(bnfriend.broadcast.text, "FriendBroadcast")
			else
				bnfriend.hasBroadcast = false
				bnfriend.broadcast = nil
			end
		end
	end
	noteColumnWidth = math.min(noteColumnWidth, NOTE_COLUMN_MAX)
	gameColumnWidth = math.min(gameColumnWidth, GAME_COLUMN_MAX)
	-- Account and current character form one label; size it to the full pair.
	-- Only the screen limit may shorten it, while zone text can still wrap.
    local scoreWidth = scoreColumnWidth > 0 and (scoreColumnWidth + GAP) or 0
	local fixedWidth = TEXT_OFFSET + classIconWidth + noteColumnWidth + GAP * 4 + scoreWidth
	local wowInfoWidth = factionIconWidth + levelColumnWidth + TEXT_OFFSET + GAP
	nameColumnWidth = FitColumnWidth(nameColumnWidth,
		fixedWidth + max(wowInfoWidth + 1, gameColumnWidth))
	zoneColumnWidth = FitColumnWidth(zoneColumnWidth, fixedWidth + nameColumnWidth + wowInfoWidth)
	for i = 1, #infotip.BNFriends do
		local bnfriend = infotip.BNFriends[i]
		bnfriend.name:SetWidth(nameColumnWidth)
		bnfriend.level:SetWidth(levelColumnWidth)
		bnfriend.zone:SetWidth(zoneColumnWidth)
		bnfriend.note:SetWidth(noteColumnWidth)
		element:PositionFriendScore(bnfriend, scoreColumnWidth, bnfriend.client == BNET_CLIENT_WOW)
		bnfriend.gameText:SetWidth(gameColumnWidth)
		bnfriend:Hide()
		if bnfriend.broadcast then
			bnfriend.broadcast:Hide()
		end
	end

	-- Calculate the length of the BNFriend row. This calculation need to check between
	--  gameText and wow client's toon information is the longest and adds that.
	local maxWidth = TEXT_OFFSET + classIconWidth + nameColumnWidth + noteColumnWidth + GAP * 4
	maxWidth = maxWidth + max(factionIconWidth + zoneColumnWidth + levelColumnWidth + TEXT_OFFSET + GAP + scoreWidth, gameColumnWidth)
	infotip.maxWidth = max(infotip.maxWidth, maxWidth)

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
	friend.name:SetWordWrap(false)
	friend.level = friend:AddFontString("CENTER", friend.name)
	friend.zone = friend:AddFontString("LEFT", friend.level, nil, module:RGB("Zone"))
	friend.note = friend:AddFontString("CENTER", friend.zone, nil, module:RGB("Note"))

	friend:SetScript("OnClick", element.OnFriendButtonClick)
	friend:AddHighlight()
	element:AddFriendScore(friend)
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
	local zoneColumnWidth, noteColumnWidth, scoreColumnWidth = 0, 0, 0
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
            local scoreName, scoreRealm = friendName:match("^([^%-]+)%-(.+)$")
            element:UpdateFriendScore(friend, scoreName or friendName, scoreRealm or LUI.playerRealm)
            scoreColumnWidth = max(scoreColumnWidth, module:GetInfotipTextWidth(friend.score))
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

			nameColumnWidth = max(nameColumnWidth, module:GetInfotipTextWidth(friend.name))
			levelColumnWidth = max(levelColumnWidth, module:GetInfotipTextWidth(friend.level))
			zoneColumnWidth = max(zoneColumnWidth, module:GetInfotipTextWidth(friend.zone))
			if module.db.profile.Friends.ShowNotes then
				noteColumnWidth = max(noteColumnWidth, module:GetInfotipTextWidth(friend.note))
			end
			classIconWidth = max(classIconWidth, friend.class:GetWidth())
		end
	end
	noteColumnWidth = math.min(noteColumnWidth, NOTE_COLUMN_MAX)
	local scoreWidth = scoreColumnWidth > 0 and (scoreColumnWidth + GAP) or 0
	-- Match Battle.net rows: reserve the other columns, then allow the full
	-- character name (including realm/status) up to the screen limit.
	nameColumnWidth = FitColumnWidth(nameColumnWidth,
		TEXT_OFFSET + classIconWidth + levelColumnWidth
		+ noteColumnWidth + GAP * 5 + scoreWidth + 1)
	zoneColumnWidth = FitColumnWidth(zoneColumnWidth,
		TEXT_OFFSET + classIconWidth + nameColumnWidth + levelColumnWidth
		+ noteColumnWidth + GAP * 5 + scoreWidth)

	for i = 1, #infotip.Friends do
		local friend = infotip.Friends[i]
		friend.name:SetWidth(nameColumnWidth)
		friend.level:SetWidth(levelColumnWidth)
		friend.zone:SetWidth(zoneColumnWidth)
		friend.note:SetWidth(noteColumnWidth)
		element:PositionFriendScore(friend, scoreColumnWidth, true)
		friend:Hide()
	end
	local maxWidth = TEXT_OFFSET + classIconWidth + nameColumnWidth + levelColumnWidth
	maxWidth = maxWidth + zoneColumnWidth + noteColumnWidth + GAP * 5 + scoreWidth
	infotip.maxWidth = max(infotip.maxWidth, maxWidth)
end

function element:PrepareFriendRows()
	-- Reserve space for a scrollbar before deciding how much wider the
	-- content can become. It may be needed once wrapped row heights are known.
	local sliderWidth = infotip.slider and infotip.slider:GetWidth() or FRIENDS_SLIDER_WIDTH
	local available = max(0, UIParent:GetWidth() - GAP * 2 - sliderWidth - infotip.maxWidth)
	local extraWidth = min(available, max(0, tonumber(module.db.profile.Friends.ExtraWidth) or 0))
	infotip.maxWidth = infotip.maxWidth + extraWidth

	for index = 1, infotip.bnIndex do
		local row = infotip.BNFriends[index]
		row.zone:SetWidth(row.zone:GetWidth() + extraWidth)
		row.gameText:SetWidth(row.gameText:GetWidth() + extraWidth)
		row:UpdateTextHeight()
	end
	for index = 1, infotip.friendIndex do
		local row = infotip.Friends[index]
		row.zone:SetWidth(row.zone:GetWidth() + extraWidth)
		row:UpdateTextHeight()
	end
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
	infotip:SetScrollRange(maxOffset)

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
	element:UpdateInfotip()
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

function element.OnEnter(frame_, requestRoster)
	if requestRoster ~= false then C_FriendList.ShowFriends() end
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
			infotip.maxWidth = module:GetInfotipTextWidth(broadcast.name) + GAP * 2

			element:DisplayBNFriends()

		else -- not BNConnected()
			--If you get disconnected from BNet but not from WoW, display it.
			if infotip.broadcast then infotip.broadcast:Hide() end
			local bnetDown = element:CreateNegativeLine("bnetDown")
			bnetDown:Show()
			infotip.sep:ClearAllPoints()
			infotip.sep:SetPoint("TOPLEFT", bnetDown, "BOTTOMLEFT")
			bnetDown.name:SetText(BATTLENET_UNAVAILABLE)
			infotip.maxWidth = module:GetInfotipTextWidth(bnetDown.name) + GAP * 2
		end
	end

	element:DisplayFriends()
	infotip.maxWidth = min(UIParent:GetWidth() - GAP * 2 - FRIENDS_SLIDER_WIDTH,
		infotip.maxWidth + FRIENDS_WIDTH_PADDING)
	element:PrepareFriendRows()
	local rowBaseHeight = GAP * 2
	local header = infotip.broadcast and infotip.broadcast:IsShown() and infotip.broadcast
		or infotip.bnetDown and infotip.bnetDown:IsShown() and infotip.bnetDown
	if header then
		header:SetWidth(max(1, infotip.maxWidth - GAP * 2))
		rowBaseHeight = rowBaseHeight + header:UpdateTextHeight() + infotip.sep:GetHeight()
	end
	for _, broadcast in ipairs(infotip.FriendsBC) do
		broadcast.text:SetWidth(max(1,
			infotip.maxWidth - BC_OFFSET - TEXT_OFFSET - GAP * 3))
		broadcast:UpdateTextHeight()
	end
	element:LayoutFriendRows(rowBaseHeight)

	-- If no friends are online, display it.
	if (infotip.bnIndex + infotip.friendIndex) == 0 then
		local noFriends = element:CreateNegativeLine("noFriends")
		noFriends:Show()
		noFriends.name:SetText(L["InfoFriends_NoFriends"])
		infotip.maxWidth = min(UIParent:GetWidth() - GAP * 2,
			max(infotip.maxWidth, module:GetInfotipTextWidth(noFriends.name) + GAP * 2))
		noFriends:SetWidth(max(1, infotip.maxWidth - GAP * 2))
		noFriends:UpdateTextHeight()
		noFriends:ClearAllPoints()
		-- if you're on an account with BNet disabled, no separator are created.
		if infotip.sep and infotip.sep:IsShown() then
			noFriends:SetPoint("TOPLEFT", infotip.sep, "BOTTOMLEFT")
			infotip.maxHeight = infotip.maxHeight + noFriends:GetHeight()
		else
			noFriends:SetPoint("TOPLEFT", GAP, -GAP)
			infotip.maxHeight = noFriends:GetHeight() + GAP * 2
		end
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
