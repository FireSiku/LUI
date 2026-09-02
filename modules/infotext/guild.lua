-- Guild Infotext

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)
local L = LUI.L

---@class LUI.Infotext
local module = LUI:GetModule("Infotext")
local element = module:NewElement("Guild", "AceEvent-3.0")

-- local copies
local format, strsplit, max = format, string.split, math.max
local GetNumGuildMembers = _G.GetNumGuildMembers
local GetGuildRosterInfo = _G.GetGuildRosterInfo
local CanEditOfficerNote = C_GuildInfo.CanEditOfficerNote
local CanEditPublicNote = _G.CanEditPublicNote
local IsControlKeyDown = _G.IsControlKeyDown
local IsAltKeyDown = _G.IsAltKeyDown
local SetItemRef = _G.SetItemRef
local IsInGuild = _G.IsInGuild

-- constants
local ERR_GUILD_PLAYER_NOT_IN_GUILD = _G.ERR_GUILD_PLAYER_NOT_IN_GUILD
local CHAT_FLAG_AFK = _G.CHAT_FLAG_AFK
local CHAT_FLAG_DND = _G.CHAT_FLAG_DND
local REMOTE_CHAT = _G.REMOTE_CHAT
local MOTD_COLON = _G.MOTD_COLON
local GUILD = _G.GUILD

local PLAYER_HYPERLINK_FORMAT = "|Hplayer:%1$s|h[%1$s]|h"
local PLAYER_LINK_FORMAT = "player:%s"
local GUILD_UPDATE_TIME = 15
local STATUS_AFK = 1
local STATUS_DND = 2
local SLIDER_OFFSET = -6
local TEXT_OFFSET = 5
local GAP = 10
local NAME_COLUMN_MAX = 190
local NOTE_COLUMN_MAX = 160
local ZONE_COLUMN_MAX = 180
local RANK_COLUMN_MAX = 140

-- locals
local totalGuild = 0
local onlineGuild = 0
local guildMOTD = ""
local infotip

local function SetTextColor(fontString, colorName)
	fontString:SetTextColor(module:RGB(colorName))
end

-- ####################################################################################################################
-- ##### Infotip Setup ################################################################################################
-- ####################################################################################################################

function element:BuildTooltip()
	infotip = module:NewInfotip(element)
	infotip.Members = {}
end

function element:CreateMOTD()
	if infotip.motd then return infotip.motd end
	local motd = infotip:NewLine()
	motd.name = motd:AddFontString("LEFT", module:RGB("MOTD"))
	motd.name:SetJustifyV("TOP")
	motd.name:SetPoint("TOPLEFT")
	motd.name:SetPoint("TOPRIGHT")
	motd:SetPoint("TOPLEFT", GAP, -GAP)
	infotip.motd = motd
	infotip.sep = infotip:AddSeparator(motd)
	return motd
end

function element:CreateNoGuild()
	if infotip.noGuild then return infotip.noGuild end
	local noGuild = infotip:NewLine()
	noGuild.name = noGuild:AddFontString("LEFT", LUI:NegativeColor())
	noGuild.name:SetPoint("TOPLEFT")
	noGuild.name:SetPoint("TOPRIGHT")
	noGuild:SetPoint("TOPLEFT", GAP, -GAP)
	infotip.noGuild = noGuild
	return noGuild
end

function element:CreateGuildMember(index)
	if infotip.Members[index] then return infotip.Members[index] end
	local mem = infotip:NewLine()

	mem.class = mem:AddTexture()
	mem.name = mem:AddFontString("LEFT", mem.class, TEXT_OFFSET)
	mem.level = mem:AddFontString("CENTER", mem.name)
	mem.zone = mem:AddFontString("LEFT", mem.level, nil, module:RGB("Zone"))
	mem.note = mem:AddFontString("CENTER", mem.zone, nil, module:RGB("Note"))
	mem.rank = mem:AddFontString("RIGHT", mem.note, nil, module:RGB("Rank"))

	mem:SetScript("OnClick", element.OnGuildButtonClick)
	mem:AddHighlight()

	infotip.Members[index] = mem
	return mem
end

function element:UpdateGuildAnchorPoints(i)
	local offset = infotip:GetSliderOffset()
	infotip.Members[i]:ClearAllPoints()
	if i == offset or i == 1 then
		infotip.Members[i]:SetPoint("TOPLEFT", infotip.sep, "BOTTOMLEFT", GAP)
	else
		infotip.Members[i]:SetPoint("TOPLEFT", infotip.Members[i-1], "BOTTOMLEFT")
	end
end

function element:UpdateInfotip()
	if infotip and infotip:IsShown() then
		infotip:UpdateTooltip()
	end
end

function element:GuildMOTD(_, motdText)
	guildMOTD = (motdText and not issecretvalue(motdText)) and motdText or ""
	element:UpdateInfotip()
end

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

local function ShowGuild()
	if IsInGuild() then C_GuildInfo.GuildRoster() end
end

local function SafeValue(value, fallback)
	if value == nil or issecretvalue(value) then return fallback end
	return value
end

function element:GetStatusString(status, isMobile)
	local MOBILE_BUSY_ICON = ""
	local MOBILE_AWAY_ICON = ""
	if isMobile then
		MOBILE_BUSY_ICON = "|TInterface\\ChatFrame\\UI-ChatIcon-ArmoryChat-BusyMobile:14:14:0:0:16:16:0:16:0:16|t"
		MOBILE_AWAY_ICON = "|TInterface\\ChatFrame\\UI-ChatIcon-ArmoryChat-AwayMobile:14:14:0:0:16:16:0:16:0:16|t"
	end
	--Status Color: 0.7, 0.7, 0.7 to change when tooltip setup.
	local statusString = ""
	if status == STATUS_DND then
		statusString = module:ColorText(CHAT_FLAG_DND..MOBILE_BUSY_ICON, "Status")
	elseif status == STATUS_AFK then
		statusString = module:ColorText(CHAT_FLAG_AFK..MOBILE_AWAY_ICON, "Status")
	elseif isMobile then
		local mobileTexture = _G.ChatFrameUtil and _G.ChatFrameUtil.GetMobileEmbeddedTexture
			or _G.ChatFrame_GetMobileEmbeddedTexture
		if mobileTexture then statusString = mobileTexture(73/255, 177/255, 73/255) end
	end
	return statusString
end

function element:UpdateGuild()
	if not IsInGuild() then
		element.text = L["InfoGuild_NoGuild"]
		return
	end
	totalGuild, onlineGuild = GetNumGuildMembers()
	totalGuild = SafeValue(totalGuild, 0)
	onlineGuild = SafeValue(onlineGuild, 0)
	local formatString = module.db.profile.Guild.showTotal and "%s: %d/%d" or "%s: %d"

	element.text = format(formatString, GUILD, onlineGuild, totalGuild)
	element:UpdateInfotip()
end

function element:GuildRosterUpdate()
	--As this event is trigger by a server query but may be trigger by other reasons
	--Make sure we don't query the server more than once per update time.
	element:ResetUpdateTimer()

	totalGuild, onlineGuild = GetNumGuildMembers()
	totalGuild = SafeValue(totalGuild, 0)
	onlineGuild = SafeValue(onlineGuild, 0)
	element:UpdateGuild()
end

-- Alt-Click: Invite member
-- Ctrl-LeftClick: Edit Public Note
-- Ctrl-RightClick: Edit Officer Note
-- LeftClick: Whisper
-- Shift-LeftClick: /who
function element.OnGuildButtonClick(member, button)
	if IsAltKeyDown() then
		C_PartyInfo.InviteUnit(member.unit)
	elseif IsControlKeyDown() then
		local isPublic = button == "LeftButton"
		if member.guid and ((isPublic and CanEditPublicNote()) or (not isPublic and CanEditOfficerNote())) then
			local dialog = StaticPopup_Show("LUI_SET_GUILD_NOTE")
			if dialog then
				dialog.data = {guid = member.guid, isPublic = isPublic}
				local editBox = dialog:GetEditBox()
				editBox:SetText(isPublic and member.rawNote or member.officerNote)
				editBox:HighlightText()
			end
		end
	elseif button == "LeftButton" then
		local playerLink = format(PLAYER_LINK_FORMAT, member.unit)
		local playerHyperText = format(PLAYER_HYPERLINK_FORMAT, member.unit)
		SetItemRef(playerLink, playerHyperText, button)
	end
end

function element.OnClick(frame_, button)
	_G.ToggleGuildFrame()
end

function element:OnSliderUpdate()
	-- Rebuild from the authoritative roster instead of moving the old anchor
	-- chain in place. This prevents stale rows from surviving a roster change.
	element:UpdateInfotip()
end

-- ####################################################################################################################
-- ##### Infotext Display #############################################################################################
-- ####################################################################################################################

function element.OnEnter(frame_)
	ShowGuild()
	if not infotip then element:BuildTooltip() end
	local maxWidth, maxHeight
	if IsInGuild() then
		if infotip.noGuild then infotip.noGuild:Hide() end
		local db = module.db.profile.Guild

		-- Show MOTD
		local motd = element:CreateMOTD()
		local motdPrefix = CreateColor(1, 1, 1):WrapTextInColorCode(MOTD_COLON)
		motd.name:SetText(format("%s %s", motdPrefix, guildMOTD))
		SetTextColor(motd.name, "MOTD")
		maxHeight = motd:GetHeight() + infotip.sep:GetHeight() + GAP * 2
		local classIconWidth, nameColumnWidth, levelColumnWidth = 0, 0, 0
		local zoneColumnWidth, noteColumnWidth, rankColumnWidth = 0, 0, 0
		
		-- The guild roster API preserves Blizzard's displayed row order and is
		-- immediately available when the tooltip is first opened.
		totalGuild, onlineGuild = GetNumGuildMembers()
		totalGuild = SafeValue(totalGuild, 0)
		onlineGuild = SafeValue(onlineGuild, 0)
		local rosterIndex, lineIndex = 1, 1
		while rosterIndex <= totalGuild and lineIndex <= onlineGuild do
			local fullName, rank, _, level, _, zone, note, officerNote, isOnline,
				status, class, _, _, isMobile, _, _, guid = GetGuildRosterInfo(rosterIndex)
			fullName = SafeValue(fullName)
			isOnline = SafeValue(isOnline, false)
			isMobile = SafeValue(isMobile, false)
			if fullName and (isOnline or isMobile) then
				local statusString = element:GetStatusString(SafeValue(status, 0), isMobile)
				local member = element:CreateGuildMember(lineIndex)
				lineIndex = lineIndex + 1

				--Name Column
				local displayName = strsplit("-", fullName)
				local name = (db.hideRealm) and displayName or fullName
				member.unit = fullName
				member.guildIndex = rosterIndex
				member.guid = SafeValue(guid)
				member.rawNote = SafeValue(note, "")
				member.officerNote = SafeValue(officerNote, "")
				member.name:SetText(statusString..name)
				local classToken = SafeValue(class)
				classToken = classToken and (LUI:GetTokenFromClassName(classToken) or classToken)
				member.name:SetTextColor(LUI:GetClassColor(classToken))
				member:SetClassIcon(member.class, classToken)

				--Level Column
				level = SafeValue(level)
				member.level:SetText(level or "")
				if level then member.level:SetTextColor(LUI:GetDifficultyColor(level)) end

				--Zone Column
				zone = SafeValue(zone, _G.UNKNOWN)
				if isMobile and not isOnline then zone = REMOTE_CHAT end
				member.zone:SetText(zone or _G.UNKNOWN)
				SetTextColor(member.zone, "Zone")

				--Note Column
				member.note:SetText(member.rawNote ~= "" and member.rawNote or "-")
				SetTextColor(member.note, "Note")
				if db.hideNotes then member.note:Hide() else member.note:Show() end

				--Rank Column
				member.rank:SetText(SafeValue(rank, ""))
				SetTextColor(member.rank, "Rank")

				--Check if this member has any column larger than the current ones.
				nameColumnWidth = max(nameColumnWidth, member.name:GetStringWidth())
				levelColumnWidth = max(levelColumnWidth, member.level:GetStringWidth())
				zoneColumnWidth = max(zoneColumnWidth, member.zone:GetStringWidth())
				if not db.hideNotes then
					noteColumnWidth = max(noteColumnWidth, member.note:GetStringWidth())
				end
				rankColumnWidth = max(rankColumnWidth, member.rank:GetStringWidth())
				classIconWidth = max(classIconWidth, member.class:GetWidth())
			end
			rosterIndex = rosterIndex + 1
		end
		nameColumnWidth = math.min(nameColumnWidth, NAME_COLUMN_MAX)
		noteColumnWidth = math.min(noteColumnWidth, NOTE_COLUMN_MAX)
		zoneColumnWidth = math.min(zoneColumnWidth, ZONE_COLUMN_MAX)
		rankColumnWidth = math.min(rankColumnWidth, RANK_COLUMN_MAX)

		local visibleGuild = lineIndex - 1
		infotip:UpdateSlider(visibleGuild)
		local offset = infotip:GetSliderOffset()

		-- Adjust things such as width and hide/show for every created lines.
		for j = 1, #infotip.Members do
			local member = infotip.Members[j]
			member.name:SetWidth(nameColumnWidth)
			member.level:SetWidth(levelColumnWidth)
			member.zone:SetWidth(zoneColumnWidth)
			member.note:SetWidth(noteColumnWidth)
			member.rank:SetWidth(rankColumnWidth)
			element:UpdateGuildAnchorPoints(j)

			-- Show/Hide the needed members.
			if j < offset then member:Hide()                          -- Do not show if below the offset
			elseif j > visibleGuild then member:Hide()                 -- Do not show if higher than the built roster
			elseif j >= infotip.maxLines + offset then member:Hide()  -- Do not show if higher than tooltip can display
			else
				maxHeight = maxHeight + member:GetHeight()            -- Only add height based on shown buttons.
				member:Show()
			end
		end

		maxWidth = TEXT_OFFSET + classIconWidth + nameColumnWidth + levelColumnWidth
		maxWidth = maxWidth + zoneColumnWidth + noteColumnWidth + rankColumnWidth + GAP * 6
		if infotip.hasSlider then
			maxWidth = maxWidth + infotip.slider:GetWidth()
			infotip.slider:ClearAllPoints()
			infotip.slider:SetPoint("TOPRIGHT", infotip, "TOPRIGHT", SLIDER_OFFSET, -GAP)
			infotip.slider:SetPoint("BOTTOMRIGHT", infotip, "BOTTOMRIGHT", SLIDER_OFFSET, GAP)
		end
		local rowWidth = max(1, maxWidth - GAP * 2
			- (infotip.hasSlider and infotip.slider:GetWidth() or 0))
		for _, member in ipairs(infotip.Members) do member:SetWidth(rowWidth) end

	else -- not in a guild
		if infotip.motd then infotip.motd:Hide() end
		if infotip.sep then infotip.sep:Hide() end
		if infotip.slider then infotip.slider:Hide() end
		infotip.hasSlider = false
		for _, member in ipairs(infotip.Members) do member:Hide() end
		local noGuild = element:CreateNoGuild()
		noGuild.name:SetText(ERR_GUILD_PLAYER_NOT_IN_GUILD)
		maxWidth = noGuild.name:GetStringWidth() + GAP * 2
		maxHeight = noGuild.name:GetStringHeight() + GAP * 2
	end

	module:SetBoundedInfotipSize(infotip, maxWidth, maxHeight)
	infotip:Show()
end

function element:RefreshSettings()
	element:UpdateGuild()
	if infotip then infotip:Hide() end
end

function element.OnLeave(frame_)
	if infotip and not infotip:IsMouseOver() then
		infotip:Hide()
	end
end

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function element:OnCreate()
	StaticPopupDialogs["LUI_SET_GUILD_NOTE"] = {
		preferredIndex = 3,
		text = "Edit guild note",
		button1 = ACCEPT,
		button2 = CANCEL,
		hasEditBox = true,
		OnAccept = function(self)
			local noteData = self.data
			if noteData and noteData.guid then
				C_GuildInfo.SetNote(noteData.guid, self:GetEditBox():GetText(), noteData.isPublic)
			end
		end,
		EditBoxOnEnterPressed = function(self) self:GetParent():GetButton1():Click() end,
		EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
	element:RegisterEvent("GUILD_MOTD", "GuildMOTD")
	ShowGuild()
	element:AddUpdate(ShowGuild, GUILD_UPDATE_TIME)
	element:RegisterEvent("GUILD_ROSTER_UPDATE", "GuildRosterUpdate")
	element:RegisterEvent("PLAYER_GUILD_UPDATE", function(self, _, unit)
		if not IsInGuild() then
			element.text = L["InfoGuild_NoGuild"]
			element:UpdateInfotip()
			return
		end
		if unit and unit ~= "player" then return end
		ShowGuild()
		element:UpdateGuild()
	end)
	element:UpdateGuild()
end
