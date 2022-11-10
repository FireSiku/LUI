-- Guild Infotext

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, LUIAddon
local _, LUI = ...
local L = LUI.L

---@type InfotextModule
local module = LUI:GetModule("Infotext")
local element = module:NewElement("Guild", "AceEvent-3.0")

-- local copies
local format, strsplit, max = format, string.split, math.max
local PanelTemplates_GetSelectedTab = _G.PanelTemplates_GetSelectedTab
local SetGuildRosterSelection = _G.SetGuildRosterSelection
local GetGuildRosterMOTD = _G.GetGuildRosterMOTD
local GetNumGuildMembers = _G.GetNumGuildMembers
local GetGuildRosterInfo = _G.GetGuildRosterInfo
local CanEditOfficerNote = _G.CanEditOfficerNote
local CanEditPublicNote = _G.CanEditPublicNote
local IsControlKeyDown = _G.IsControlKeyDown
local IsAltKeyDown = _G.IsAltKeyDown
local ShowUIPanel = _G.ShowUIPanel
local HideUIPanel = _G.HideUIPanel
local GuildRoster = _G.GuildRoster
local SetItemRef = _G.SetItemRef
local GuildFrame = _G.GuildFrame
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
local GUILD_TAB_INFO = 1
local GUILD_TAB_ROSTER = 2
local SLIDER_OFFSET = -6
local STATUS_AFK = 1
local STATUS_DND = 2
local TEXT_OFFSET = 5
local GAP = 10

-- locals
--local guildEntries = {}
---@TODO: Allow displaying totalGuild in infotext
local totalGuild = 0 --luacheck: ignore
local onlineGuild = 0
local infotip
local onBlock

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
	motd.name = motd:AddFontString("LEFT", element:RGB("MOTD"))
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
	mem.zone = mem:AddFontString("LEFT", mem.level, nil, element:RGB("Zone"))
	mem.note = mem:AddFontString("CENTER", mem.zone, nil, element:RGB("Note"))
	mem.rank = mem:AddFontString("RIGHT", mem.note, nil, element:RGB("Rank"))

	mem:SetScript("OnClick", element.OnGuildButtonClick)
	mem:AddHighlight()

	infotip.Members[index] = mem
	return mem
end

function element:UpdateGuildAnchorPoints(i)
	local offset = infotip:GetSliderOffset()
	if i == offset or i == 1 then
		infotip.Members[i]:SetPoint("TOPLEFT", infotip.sep, "BOTTOMLEFT", GAP)
	else
		infotip.Members[i]:SetPoint("TOPLEFT", infotip.Members[i-1], "BOTTOMLEFT")
	end
end

function element:UpdateInfotip()
	if infotip and onBlock then
		infotip:UpdateTooltip()
	end
end

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

local function ShowGuild()
	if IsInGuild() then C_GuildInfo.GuildRoster() end
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
		statusString = _G.ChatFrame_GetMobileEmbeddedTexture(73/255, 177/255, 73/255)
	end
	return statusString
end

function element:ToggleGuildTab(tabID)
	if not GuildFrame then _G.GuildFrame_LoadUI() end
	if GuildFrame and GuildFrame:IsShown() then
		if PanelTemplates_GetSelectedTab(GuildFrame) == tabID then
			return HideUIPanel(GuildFrame)
		end
	end
	_G["GuildFrameTab"..tabID]:Click()
	ShowUIPanel(GuildFrame)
end

function element:UpdateGuild()
	if not IsInGuild() then
		element.text = L["InfoGuild_NoGuild"]
		return
	end
	local totalNumGuild, guildNumOnline_, guildNumOnlineRemote = GetNumGuildMembers()
	local formatString = (module.db.profile.showTotal) and "%s: %d/%d" or "%s: %d"

	element.text = format(formatString, GUILD, guildNumOnlineRemote, totalNumGuild)
	element:UpdateInfotip()
end

function element:GuildRosterUpdate()
	--As this event is trigger by a server query but may be trigger by other reasons
	--Make sure we don't query the server more than once per update time.
	element:ResetUpdateTimer()

	local numGuildMembers, _, numOnlineAndMobile =  GetNumGuildMembers()
	totalGuild = numGuildMembers
	onlineGuild = numOnlineAndMobile

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
		if button == "LeftButton" and CanEditPublicNote() then
			SetGuildRosterSelection(member.guildIndex)
			StaticPopup_Show("SET_GUILDPLAYERNOTE")
		elseif button == "RightButton" and CanEditOfficerNote() then
			SetGuildRosterSelection(member.guildIndex)
			StaticPopup_Show("SET_GUILDOFFICERNOTE")
		end
	elseif button == "LeftButton" then
		local playerLink = format(PLAYER_LINK_FORMAT, member.unit)
		local playerHyperText = format(PLAYER_HYPERLINK_FORMAT, member.unit)
		SetItemRef(playerLink, playerHyperText, button)
	end
end

--Hints:
--Click to open Guild Roster.
--Right-Click to display Guild Information.
--Button4 to toggle notes.
function element.OnClick(frame_, button)
	-- If you arent in a guild, toggle the guild finder.
	if button == "RightButton" then
	else
		_G.ToggleGuildFrame()
	end
end

function element:OnSliderUpdate()
	local offset = infotip:GetSliderOffset()
	for i = 1, #infotip.Members do
		local member = infotip.Members[i]

		-- Set the anchor points, 1 always need to be anchored to the separator.
		element:UpdateGuildAnchorPoints(i)

		-- Show/Hide the needed members.
		if i < offset then member:Hide()                         -- Do not show if below the offset
		elseif i > onlineGuild then member:Hide()                -- Do not show if higher than total online people
		elseif i > infotip.maxLines + offset then member:Hide()  -- Do not show if higher than tooltip can display
		else
			member:Show()
		end
	end
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
		local db = module.db.profile

		-- Show MOTD
		local motd = element:CreateMOTD()
		local motdPrefix = CreateColor(1, 1, 1):WrapTextInColorCode(MOTD_COLON)
		motd.name:SetText(format("%s %s", motdPrefix, GetGuildRosterMOTD()))
		--maxWidth = motd.name:GetStringWidth() + GAP * 2
		maxHeight = motd:GetHeight() + infotip.sep:GetHeight() + GAP * 2

		local classIconWidth, nameColumnWidth, levelColumnWidth = 0, 0, 0
		local zoneColumnWidth, noteColumnWidth, rankColumnWidth = 0, 0, 0
		
		-- Add Guild members
		-- Slight complication in this process is that if "Show Offline Members" is checked, the list doesnt return
		--   online members first, it shows them by whichever sort order the guild roster is in. So we have to assign
		--   an index everytime we find an online guild member, not every time we loop. We end the loop whenever we
		--   reach the end of the guild roster OR when we have created the same amount of lines as the amount of
		--   online guild members that should be shown.
		local i, lineIndex = 1, 1
		while i <= GetNumGuildMembers() and lineIndex <= onlineGuild do
			local fullName, rank, _, level, _, zone, note, officerNote, isOnline, status, class, _, _, isMobile = GetGuildRosterInfo(i)
			if isOnline or isMobile then
				local statusString = element:GetStatusString(status, isMobile)
				local member = element:CreateGuildMember(lineIndex)
				lineIndex = lineIndex + 1

				--Name Column
				local displayName, realmName_ = strsplit("-",fullName)
				local name = (db.hideRealm) and displayName or fullName
				member.unit = fullName
				member.guildIndex = i
				member.name:SetText(statusString..name)
				member.name:SetTextColor(element:RGB(class))
				member:SetClassIcon(member.class, class)

				--Level Column
				member.level:SetText(level or "")
				member.level:SetTextColor(LUI:GetDifficultyColor(level))

				--Zone Column
				if isMobile and not isOnline then zone = REMOTE_CHAT end
				member.zone:SetText(zone or _G.UNKNOWN)

				--Note Column
				member.note:SetText(note or "-")
				if db.hideNotes then member.note:Hide() else member.note:Show() end

				--Rank Column
				member.rank:SetText(rank or "")
				--member.rank:SetPoint("LEFT", db.hideNotes and member.zone or member.note, "RIGHT", GAP)

				--Check if this member has any column larger than the current ones.
				nameColumnWidth = max(nameColumnWidth, member.name:GetStringWidth())
				levelColumnWidth = max(levelColumnWidth, member.level:GetStringWidth())
				zoneColumnWidth = max(zoneColumnWidth, member.zone:GetStringWidth())
				noteColumnWidth = max(noteColumnWidth, member.note:GetStringWidth())
				rankColumnWidth = max(rankColumnWidth, member.rank:GetStringWidth())
				classIconWidth = max(classIconWidth, member.class:GetWidth())
			end
			i = i + 1
		end

		infotip:UpdateSlider(onlineGuild)
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
			elseif j > onlineGuild then member:Hide()                 -- Do not show if higher than total online people
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
			infotip.slider:SetPoint("TOPRIGHT", infotip.Members[1], SLIDER_OFFSET, 0)
			infotip.slider:SetPoint("BOTTOMRIGHT", infotip, SLIDER_OFFSET, GAP)
		end

	else -- not in a guild
		local noGuild = element:CreateNoGuild()
		noGuild.name:SetText(ERR_GUILD_PLAYER_NOT_IN_GUILD)
		maxWidth = noGuild.name:GetStringWidth() + GAP * 2
		maxHeight = noGuild.name:GetStringHeight() + GAP * 2
	end

	infotip:SetWidth(maxWidth)
	infotip:SetHeight(maxHeight)
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
	ShowGuild()
	element:AddUpdate(ShowGuild, GUILD_UPDATE_TIME)
	element:RegisterEvent("GUILD_MOTD", "UpdateInfotip")
	element:RegisterEvent("GUILD_ROSTER_UPDATE", "GuildRosterUpdate")
	element:RegisterEvent("PLAYER_GUILD_UPDATE", function(self, unit)
		if not IsInGuild() then
			element.text = L["InfoGuild_NoGuild"]
			return
		end
		if unit and unit ~= "player" then return end
		ShowGuild()
	end)
	element:UpdateGuild()
end
