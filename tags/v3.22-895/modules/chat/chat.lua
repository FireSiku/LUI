--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: chat.lua
	Description: Chat Module
]]

-- External references.
local addonname, LUI = ...
local module = LUI:Module("Chat", "AceHook-3.0")
local Buttons = module:Module("Buttons")
local EditBox = module:Module("EditBox")
local StickyChannels = module:Module("StickyChannels")
local Themes = LUI:Module("Themes")
local Media = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists

local L = LUI.L
local db, dbd

--------------------------------------------------
-- Local Variables
--------------------------------------------------

local urlEvents, urlPatterns
do
	local tlds = {
		ONION = true, -- for all the TOR fags out there
		-- Copied from http://data.iana.org/TLD/tlds-alpha-by-domain.txt
		-- Version 2008041301, Last Updated Mon Apr 21 08:07:00 2008 UTC
		AC = true,
		AD = true,
		AE = true,
		AERO = true,
		AF = true,
		AG = true,
		AI = true,
		AL = true,
		AM = true,
		AN = true,
		AO = true,
		AQ = true,
		AR = true,
		ARPA = true,
		AS = true,
		ASIA = true,
		AT = true,
		AU = true,
		AW = true,
		AX = true,
		AZ = true,
		BA = true,
		BB = true,
		BD = true,
		BE = true,
		BF = true,
		BG = true,
		BH = true,
		BI = true,
		BIZ = true,
		BJ = true,
		BM = true,
		BN = true,
		BO = true,
		BR = true,
		BS = true,
		BT = true,
		BV = true,
		BW = true,
		BY = true,
		BZ = true,
		CA = true,
		CAT = true,
		CC = true,
		CD = true,
		CF = true,
		CG = true,
		CH = true,
		CI = true,
		CK = true,
		CL = true,
		CM = true,
		CN = true,
		CO = true,
		COM = true,
		COOP = true,
		CR = true,
		CU = true,
		CV = true,
		CX = true,
		CY = true,
		CZ = true,
		DE = true,
		DJ = true,
		DK = true,
		DM = true,
		DO = true,
		DZ = true,
		EC = true,
		EDU = true,
		EE = true,
		EG = true,
		ER = true,
		ES = true,
		ET = true,
		EU = true,
		FI = true,
		FJ = true,
		FK = true,
		FM = true,
		FO = true,
		FR = true,
		GA = true,
		GB = true,
		GD = true,
		GE = true,
		GF = true,
		GG = true,
		GH = true,
		GI = true,
		GL = true,
		GM = true,
		GN = true,
		GOV = true,
		GP = true,
		GQ = true,
		GR = true,
		GS = true,
		GT = true,
		GU = true,
		GW = true,
		GY = true,
		HK = true,
		HM = true,
		HN = true,
		HR = true,
		HT = true,
		HU = true,
		ID = true,
		IE = true,
		IL = true,
		IM = true,
		IN = true,
		INFO = true,
		INT = true,
		IO = true,
		IQ = true,
		IR = true,
		IS = true,
		IT = true,
		JE = true,
		JM = true,
		JO = true,
		JOBS = true,
		JP = true,
		KE = true,
		KG = true,
		KH = true,
		KI = true,
		KM = true,
		KN = true,
		KP = true,
		KR = true,
		KW = true,
		KY = true,
		KZ = true,
		LA = true,
		LB = true,
		LC = true,
		LI = true,
		LK = true,
		LR = true,
		LS = true,
		LT = true,
		LU = true,
		LV = true,
		LY = true,
		MA = true,
		MC = true,
		MD = true,
		ME = true,
		MG = true,
		MH = true,
		MIL = true,
		MK = true,
		ML = true,
		MM = true,
		MN = true,
		MO = true,
		MOBI = true,
		MP = true,
		MQ = true,
		MR = true,
		MS = true,
		MT = true,
		MU = true,
		MUSEUM = true,
		MV = true,
		MW = true,
		MX = true,
		MY = true,
		MZ = true,
		NA = true,
		NAME = true,
		NC = true,
		NE = true,
		NET = true,
		NF = true,
		NG = true,
		NI = true,
		NL = true,
		NO = true,
		NP = true,
		NR = true,
		NU = true,
		NZ = true,
		OM = true,
		ORG = true,
		PA = true,
		PE = true,
		PF = true,
		PG = true,
		PH = true,
		PK = true,
		PL = true,
		PM = true,
		PN = true,
		PR = true,
		PRO = true,
		PS = true,
		PT = true,
		PW = true,
		PY = true,
		QA = true,
		RE = true,
		RO = true,
		RS = true,
		RU = true,
		RW = true,
		SA = true,
		SB = true,
		SC = true,
		SD = true,
		SE = true,
		SG = true,
		SH = true,
		SI = true,
		SJ = true,
		SK = true,
		SL = true,
		SM = true,
		SN = true,
		SO = true,
		SR = true,
		ST = true,
		SU = true,
		SV = true,
		SY = true,
		SZ = true,
		TC = true,
		TD = true,
		TEL = true,
		TF = true,
		TG = true,
		TH = true,
		TJ = true,
		TK = true,
		TL = true,
		TM = true,
		TN = true,
		TO = true,
		TP = true,
		TR = true,
		TRAVEL = true,
		TT = true,
		TV = true,
		TW = true,
		TZ = true,
		UA = true,
		UG = true,
		UK = true,
		UM = true,
		US = true,
		UY = true,
		UZ = true,
		VA = true,
		VC = true,
		VE = true,
		VG = true,
		VI = true,
		VN = true,
		VU = true,
		WF = true,
		WS = true,
		YE = true,
		YT = true,
		YU = true,
		ZA = true,
		ZM = true,
		ZW = true,
	}

	local formatStr = "|cffb4b4b4|Hurl:%s|h[%s]|h|r"

	local function urlLink(link)
		if link == nil then
			return ""
		end

		return format(formatStr, link, link)
	end

	local function urlLink_TLD(link, tld)
		if link == nil or tld == nil then
			return ""
		end

		if tlds[tld:upper()] then
			return format(formatStr, link, link)
		else
			return link
		end
	end

	urlEvents = {
		"CHAT_MSG_BATTLEGROUND", "CHAT_MSG_BATTLEGROUND_LEADER",
		"CHAT_MSG_CHANNEL", "CHAT_MSG_EMOTE",
		"CHAT_MSG_GUILD", "CHAT_MSG_OFFICER",
		"CHAT_MSG_PARTY", "CHAT_MSG_RAID",
		"CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING", "CHAT_MSG_PARTY_LEADER",
		"CHAT_MSG_SAY", "CHAT_MSG_WHISPER","CHAT_MSG_BN_WHISPER",
		"CHAT_MSG_WHISPER_INFORM", "CHAT_MSG_YELL", "CHAT_MSG_BN_WHISPER_INFORM","CHAT_MSG_BN_CONVERSATION"
	}

	urlPatterns = {
		-- X://Y url
		{ pattern = "^(%a[%w%.+-]+://%S+)", matchfunc=urlLink},
		{ pattern = "%f[%S](%a[%w%.+-]+://%S+)", matchfunc=urlLink},
		-- www.X.Y url
		{ pattern = "^(www%.[-%w_%%]+%.%S+)", matchfunc=urlLink},
		{ pattern = "%f[%S](www%.[-%w_%%]+%.%S+)", matchfunc=urlLink},
		-- "W X"@Y.Z email (this is seriously a valid email)
		--{ pattern = '^(%"[^%"]+%"@[-%w_%%%.]+%.(%a%a+))', matchfunc=urlLink_TLD},
		--{ pattern = '%f[%S](%"[^%"]+%"@[-%w_%%%.]+%.(%a%a+))', matchfunc=urlLink_TLD},
		-- X@Y.Z email
		{ pattern = "(%S+@[-%w_%%%.]+%.(%a%a+))", matchfunc=urlLink_TLD},
		-- XXX.YYY.ZZZ.WWW:VVVV/UUUUU IPv4 address with port and path
		{ pattern = "^([0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d:[0-6]?%d?%d?%d?%d/%S+)", matchfunc=urlLink},
		{ pattern = "%f[%S]([0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d:[0-6]?%d?%d?%d?%d/%S+)", matchfunc=urlLink},
		-- XXX.YYY.ZZZ.WWW:VVVV IPv4 address with port (IP of ts server for example)
		{ pattern = "^([0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d:[0-6]?%d?%d?%d?%d)%f[%D]", matchfunc=urlLink},
		{ pattern = "%f[%S]([0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d:[0-6]?%d?%d?%d?%d)%f[%D]", matchfunc=urlLink},
		-- XXX.YYY.ZZZ.WWW/VVVVV IPv4 address with path
		{ pattern = "^([0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%/%S+)", matchfunc=urlLink},
		{ pattern = "%f[%S]([0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%/%S+)", matchfunc=urlLink},
		-- XXX.YYY.ZZZ.WWW IPv4 address
		{ pattern = "^([0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%)%f[%D]", matchfunc=urlLink},
		{ pattern = "%f[%S]([0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%)%f[%D]", matchfunc=urlLink},
		-- X.Y.Z:WWWW/VVVVV url with port and path
		{ pattern = "^([-%w_%%%.]+[-%w_%%]%.(%a%a+):[0-6]?%d?%d?%d?%d/%S+)", matchfunc=urlLink_TLD},
		{ pattern = "%f[%S]([-%w_%%%.]+[-%w_%%]%.(%a%a+):[0-6]?%d?%d?%d?%d/%S+)", matchfunc=urlLink_TLD},
		-- X.Y.Z:WWWW url with port (ts server for example)
		{ pattern = "^([-%w_%%%.]+[-%w_%%]%.(%a%a+):[0-6]?%d?%d?%d?%d)%f[%D]", matchfunc=urlLink_TLD},
		{ pattern = "%f[%S]([-%w_%%%.]+[-%w_%%]%.(%a%a+):[0-6]?%d?%d?%d?%d)%f[%D]", matchfunc=urlLink_TLD},
		-- X.Y.Z/WWWWW url with path
		{ pattern = "^([-%w_%%%.]+[-%w_%%]%.(%a%a+)/%S+)", matchfunc=urlLink_TLD},
		{ pattern = "%f[%S]([-%w_%%%.]+[-%w_%%]%.(%a%a+)/%S+)", matchfunc=urlLink_TLD},
		-- X.Y.Z url
		{ pattern = "^([-%w_%%%.]+[-%w_%%]%.(%a%a+))", matchfunc=urlLink_TLD},
		{ pattern = "%f[%S]([-%w_%%%.]+[-%w_%%]%.(%a%a+))", matchfunc=urlLink_TLD},
	}
end

local shortChannelNames, shortWhispers, rwFormat
do
	shortChannelNames = {
		[L["Guild"]] = "[G]",
		[L["Officer"]] = "[O]",
		[L["Party"]] = "[P]",
		[PARTY_LEADER] = "[PL]",
		[L["Dungeon Guide"]] = "[DG]",
		[L["Raid"]] = "[R]",
		[L["Raid Leader"]] = "[RL]",
		[L["Raid Warning"]] = "[RW]",
		[L["Battleground"]] = "[BG]",
		[L["Battleground Leader"]] = "[BL]",
		[L["General"]] = "[General]",
		[L["Trade"]] = "[Trade]",
		[L["LocalDefense"]] = "[LocalDefense]",
		[L["WorldDefense"]] = "[WorldDefense]",
		[L["LookingForGroup"]] = "[LFG]",
		-- Not localized here intentionally
		["Whisper From"] = "[W:From]",
		["Whisper To"] = "[W:To]",
		["BN Whisper From"] = "[BN:From]",
		["BN Whisper To"] = "[BN:To]",
	}

	shortWhispers = {
		["Whisper To"] = "To (|Hplayer.-|h):",
		["Whisper From"] = "(|Hplayer.-|h) whispers:",
		["BN Whisper To"] = "To (|HBNplayer.-|h):",
		["BN Whisper From"] = "(|HBNplayer.-|h) whispers:",
	}

	rwFormat = format("(%%[(%s)%%]) |Hplayer:", L["Raid Warning"])

	for k, v in pairs(shortChannelNames) do
		shortChannelNames[k] = L[v]
	end
	for k, v in pairs(shortWhispers) do
		shortWhispers[k] = L[v]
	end
end

local linkTypes = {
	item = true,
	spell = true,
	enchant = true,
	talent = true,
	glyph = true,
	quest = true,
	achievement = true,
	instancelock = true,
	-- trade = true, -- causes the profession window to open on link hover
	--- invaild link types for GameTooltip:SetHyperlink()
	-- player = true,
	-- playerGM = true,
	-- journal = true,
	-- levelup = true,
}

--------------------------------------------------
-- Local Functions
--------------------------------------------------

local function createStaticPopups()
	StaticPopupDialogs["LUI_Chat_UrlCopy"] = {
		preferredIndex = 3,
		text = "URL - Ctrl-C to copy",
		button2 = CLOSE,
		hasEditBox = 1,
		editBoxWidth = 400,
		maxLetters = 1024, -- need this to override after other dialogs set to low numbers
		OnShow = function(self, data)
			local button = self.button2
			button:ClearAllPoints()
			button:SetWidth(200)
			button:SetPoint("CENTER", self.editBox, "CENTER", 0, -30)
		end,
		EditBoxOnEscapePressed = function(self)
			self:GetParent():Hide()
		end,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1
	}

	createStaticPopups = nil
end

local function unclampChatFrame(frame)
	frame:SetClampRectInsets(0,0,0,0)
	frame:SetClampedToScreen(false)
end

local function positionChatFrame()
	local frame = GENERAL_CHAT_DOCK.primary
	frame:SetMovable(true)
	frame:SetUserPlaced(true)
	frame:SetSize(db.width, db.height)
	frame:ClearAllPoints()
	frame:SetPoint(db.point, UIParent, db.point, db.x, db.y)
	FCF_SavePositionAndDimensions(frame)
	FCF_SetLocked(frame, 1)
end

local function configureTab(tab, minimalist)
	if minimalist then
		if module:IsHooked(tab, "OnMouseWheel") then return end

		tab:SetHeight(29)
		tab.leftTexture:Hide()
		tab.middleTexture:Hide()
		tab.rightTexture:Hide()
		tab.leftSelectedTexture:SetAlpha(0)
		tab.rightSelectedTexture:SetAlpha(0)
		tab.middleSelectedTexture:SetAlpha(0)
		tab.leftHighlightTexture:SetAlpha(0)
		tab.middleHighlightTexture:SetAlpha(0)
		tab.rightHighlightTexture:SetAlpha(0)
		tab:EnableMouseWheel(true)
		module:HookScript(tab, "OnMouseWheel")
	else
		tab:SetHeight(32)
		tab.leftTexture:Show()
		tab.middleTexture:Show()
		tab.rightTexture:Show()
		tab.leftSelectedTexture:SetAlpha(1)
		tab.rightSelectedTexture:SetAlpha(1)
		tab.middleSelectedTexture:SetAlpha(1)
		tab.leftHighlightTexture:SetAlpha(1)
		tab.middleHighlightTexture:SetAlpha(1)
		tab.rightHighlightTexture:SetAlpha(1)
		tab:EnableMouseWheel(false)
		module:Unhook(tab, "OnMouseWheel")
	end

	FCFTab_UpdateAlpha(_G[CHAT_FRAMES[tab:GetID()]])
end

local function configureTabs(minimalist)
	if minimalist then
		_G.CHAT_FRAME_FADE_OUT_TIME = 0.5
		_G.CHAT_TAB_HIDE_DELAY = 0
		_G.CHAT_FRAME_TAB_SELECTED_NOMOUSE_ALPHA = 0
		_G.CHAT_FRAME_TAB_NORMAL_NOMOUSE_ALPHA = 0
	else
		_G.CHAT_FRAME_FADE_OUT_TIME = 2
		_G.CHAT_TAB_HIDE_DELAY = 1
		_G.CHAT_FRAME_TAB_SELECTED_NOMOUSE_ALPHA = 0.4
		_G.CHAT_FRAME_TAB_NORMAL_NOMOUSE_ALPHA = 0.2
	end

	for i, name in ipairs(CHAT_FRAMES) do
		configureTab(_G[name.."Tab"], minimalist)
	end
end

local function urlFilterFunc(frame, event, msg, ...)
	if not msg then return false, msg, ... end

	for i, v in ipairs(urlPatterns) do
		msg = gsub(msg, v.pattern, v.matchfunc)
	end

	return false, msg, ...
end

local function replaceChannel(origChannel, msg, num, channel)
	return ("|Hchannel:%s|h%s|h "):format(origChannel, shortChannelNames[channel] or msg)
end

local function replaceChannelRW(msg, channel)
	return ("%s |Hplayer:"):format(shortChannelNames[channel] or msg)
end

local function replaceWhisper(msg)
	local channel

	for k, v in pairs(shortWhispers) do
		if msg:match(v) then
			channel = k
			break
		end
	end

	if not channel or not shortChannelNames[channel] then return msg end

	return gsub(msg, shortWhispers[channel], shortChannelNames[channel].." %1:")
end

--------------------------------------------------
-- Callback Functions
--------------------------------------------------

function module:SetColors()
	for i, name in ipairs(CHAT_FRAMES) do
		EditBox:ChatEdit_UpdateHeader(_G[name].editBox)
	end
end

function module:LibSharedMedia_Registered(mediaType, key)
	if mediaType == "font" and key == db.General.Font.Font then
		for i, name in ipairs(CHAT_FRAMES) do
			_G[name]:SetFont(Media:Fetch("font", db.General.Font.Font), db.General.Font.Size, db.General.Font.Flag)
		end
	end
end

--------------------------------------------------
-- Hook Functions
--------------------------------------------------

function module:FCF_OpenTemporaryWindow()
	local frame = FCF_GetCurrentChatFrame()
	unclampChatFrame(frame)
	if db.General.MinimalistTabs then
		if GENERAL_CHAT_DOCK:IsMouseOver() or GENERAL_CHAT_DOCK.selected:IsMouseOver() then
			frame.hasBeenFaded = true
		end
		configureTab(_G[frame:GetName().."Tab"], true)
	end

	frame:SetFont(Media:Fetch("font", db.General.Font.Font), db.General.Font.Size, db.General.Font.Flag)

	if db.General.ShortChannelNames and not self:IsHooked(frame, "AddMessage") then
		self:RawHook(frame, "AddMessage", true)
	end

	if db.General.DisableFading then
		frame:SetFading(nil)
	end

	if not self:IsHooked(frame, "OnHyperlinkEnter") then
		self:HookScript(frame, "OnHyperlinkEnter")
		self:HookScript(frame, "OnHyperlinkLeave")
	end
end

function module:FCF_SavePositionAndDimensions(chatFrame)
	if chatFrame ~= GENERAL_CHAT_DOCK.primary then return end

	local width, height = GetChatWindowSavedDimensions(chatFrame:GetID())
	if (width and height) then
		db.width, db.height = width, height
	end

	local point, xOffset, yOffset = GetChatWindowSavedPosition(chatFrame:GetID())
	if point then
		db.x = xOffset * GetScreenWidth()
		db.y = yOffset * GetScreenHeight()
		db.point = point
	end
end

function module:SetItemRef(link, text, button, chatFrame)
	if IsAltKeyDown() and strsub(link, 1, 6) == "player" then
		InviteUnit(link:match("player:([^:]+)"))
		return
	end

	if strsub(link, 1, 3) == "url" then
		local dialog = StaticPopup_Show("LUI_Chat_UrlCopy")
		dialog.editBox:SetText(strsub(link, 5))
		dialog.editBox:SetFocus()
		dialog.editBox:HighlightText(0)
		return
	end

	return self.hooks.SetItemRef(link, text, button, chatFrame)
end

function module:AddMessage(frame, text, ...)
	if text then
		if text:match("|Hchannel:") then
			text = gsub(text, "|Hchannel:(%S-)|h(%[([%d. ]*)([^%]]+)%])|h ", replaceChannel)
		elseif text:match("WHISPER:.-|h") then
			text = gsub(text, "^(.+:)", replaceWhisper)
		else
			text = gsub(text, rwFormat, replaceChannelRW)
			text = gsub(text, "has come online.", "is now online!")
			text = gsub(text, "(|Hplayer:.-|h) %a-:", "%1:") -- strip say/yell
		end
	end

	return self.hooks[frame].AddMessage(frame, text, ...)
end

function module:OnHyperlinkEnter(frame, link)
	if linkTypes[strmatch(link, "^(.-):")] then
		GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
		GameTooltip:SetHyperlink(link)
		GameTooltip:Show()
	end
end

function module:OnHyperlinkLeave(frame, link)
	--As of 7.1, link returns nil.
	--if linkTypes[strmatch(link, "^(.-):")] then
		GameTooltip:Hide()
	--end
end

function module:OnMouseWheel(tab, direction)
	if not _G[CHAT_FRAMES[tab:GetID()]].isDocked then return end

	local t
	for i, frame in ipairs(GENERAL_CHAT_DOCK.DOCKED_CHAT_FRAMES) do
		if frame:IsVisible() then
			t = i
			break
		end
	end

	if not t then return end

	t = t + direction

	if t == 0 then
		t = #GENERAL_CHAT_DOCK.DOCKED_CHAT_FRAMES
	elseif t > #GENERAL_CHAT_DOCK.DOCKED_CHAT_FRAMES then
		t = 1
	end

	FCFDock_SelectWindow(GENERAL_CHAT_DOCK, GENERAL_CHAT_DOCK.DOCKED_CHAT_FRAMES[t])
end

function module:ScrollFrame_OnMouseWheel(frame, direction)
	if not IsShiftKeyDown() then return end
	
	if direction > 0 then
		frame:ScrollToTop()
	else
		frame:ScrollToBottom()
	end
end
--------------------------------------------------
-- Module Variables
--------------------------------------------------

module.defaults = {
	profile = {
		x = 28,
		y = 46,
		point = "BOTTOMLEFT",
		width = 404,
		height = 171,
		General = {
			Font = {
				Font = (function()
					for i, name in ipairs(CHAT_FRAMES) do
						local font = _G[name]:GetFont()
						for k, v in pairs(Media:HashTable("font")) do
							if v == font then return k end
						end
					end
				end)(),
				Size = 14,
				Flag = "NONE",
			},
			ShortChannelNames = true,
			DisableFading = true,
			MinimalistTabs = true,
			LinkHover = true,
			BackgroundColor = {0, 0, 0, 0.4},
			ShiftMouseScroll = true,
		},
	},
}

module.conflicts = "Chatter;Prat |cff8080ff3.0|r"

module.getter = "generic"
module.setter = "Refresh"

--------------------------------------------------
-- Load Functions
--------------------------------------------------

function module:LoadOptions()
	local function refresh()
		self:Refresh()
	end
	local function resetChatPos()
		db.x = dbd.x
		db.y = dbd.y
		db.point = dbd.point
		db.width = dbd.width
		db.height = dbd.height

		positionChatFrame()
	end

	local options = {
		General = self:NewGroup(L["General Settings"], 1, {
			Font = self:NewGroup(L["Font"], 1, true, {
				Font = self:NewSelect(L["Font"], L["Choose a font"], 1, true, "LSM30_Font", refresh),
				Flag = self:NewSelect(L["Flag"], L["Choose a font flag"], 2, LUI.FontFlags, false, refresh),
				Size = self:NewSlider(L["Size"], L["Choose a fontsize"], 3, 6, 20, 1, true, false, "full")
			}),
			ShortChannelNames = self:NewToggle(L["Short channel names"], L["Use abreviated channel names"], 2, true),
			DisableFading = self:NewToggle(L["Disable fading"], L["Stop the chat from fading out over time"], 3, true),
			MinimalistTabs = self:NewToggle(L["Minimalist tabs"], L["Use minimalist style tabs"], 4, true),
			LinkHover = self:NewToggle(L["Link hover tooltip"], L["Show tooltip when mousing over links in chat"], 5, true),
			ShiftMouseScroll = self:NewToggle(L["Shift mouse scrolling"], L["Holding shift while mouse scrolling will jump to top or bottom"], 6, refresh),
			BackgroundColor = self:NewColor(L["Chat Background"], nil, 7, refresh, "full"),
			ResetPosition = self:NewExecute(L["Reset position"], L["Reset the main chat dock's position"], 8, resetChatPos, L["Are you sure?"]),
		}),
		StickyChannels = StickyChannels:LoadOptions(),
		EditBox = EditBox:LoadOptions(),
		Buttons = Buttons:LoadOptions(),
	}

	return options
end

function module:Refresh(info, value)
	if type(info) == "table" then
		self:SetDBVar(info, value)
	end

	for i, name in ipairs(CHAT_FRAMES) do
		local frame = _G[name]

		if db.General.ShortChannelNames then
			if frame ~= COMBATLOG and not self:IsHooked(frame, "AddMessage") then
				self:RawHook(frame, "AddMessage", true)
			end
		else
			self:Unhook(frame, "AddMessage")
		end

		if db.General.LinkHover then
			if not self:IsHooked(frame, "OnHyperlinkEnter") then
				self:HookScript(frame, "OnHyperlinkEnter")
				self:HookScript(frame, "OnHyperlinkLeave")
			end
		else
			self:Unhook(frame, "OnHyperlinkEnter")
			self:Unhook(frame, "OnHyperlinkLeave")
		end
		
		if db.General.ShiftMouseScroll then
			if not self:IsHooked(frame, "OnMouseWheel") then
				self:HookScript(frame, "OnMouseWheel", "ScrollFrame_OnMouseWheel")
			end
		else
			self:Unhook(frame, "OnMouseWheel")
		end

		frame:SetFading(not db.General.DisableFading)

		local r, g, b, a = unpack(db.General.BackgroundColor)
		FCF_SetWindowColor(frame, r, g, b)
		SetChatWindowColor(i, r, g, b)
		FCF_SetWindowAlpha(frame, a)
	end

	configureTabs(db.General.MinimalistTabs)

	self:LibSharedMedia_Registered("font", db.General.Font.Font)

	for name, module in self:IterateModules() do
		if module.Refresh and module:IsEnabled() then
			module:Refresh()
		end
	end
end

function module:DBCallback(event, dbobj, profile)
	db, dbd = LUI:Namespace(self)

	for name, module in self:IterateModules() do
		if module.DBCallback then
			module:DBCallback()
		end

		if db.modules[name] ~= nil and db.modules[name] ~= module:IsEnabled() then
			module:Toggle(db.modules)
		end
	end

	if self:IsEnabled() then
		positionChatFrame()
		self:Refresh()
	end
end

function module:OnInitialize()
	db, dbd = LUI:Namespace(self, true)

	local disabled = not self.enabledState
	for name, module in self:IterateModules() do
		---[[	PROFILER
		-- Add Chat module functions to the profiler.
		LUI.Profiler.TraceScope(module, name, "LUI.Chat")
		--]]

		if disabled then
			module:SetEnabledState(false)
		elseif db[name] then
			module:SetEnabledState(db[name].Enable)
		end
	end
end

function module:OnEnable()
	Media.RegisterCallback(self, "LibSharedMedia_Registered")

	if createStaticPopups then
		createStaticPopups()
	end

	positionChatFrame()

	self:SecureHook("FCF_SavePositionAndDimensions")
	self:SecureHook("FCF_OpenTemporaryWindow")
	self:RawHook("SetItemRef", true)

	for i, name in ipairs(CHAT_FRAMES) do
		local frame = _G[name]
		unclampChatFrame(frame)
	end

	for _, event in ipairs(urlEvents) do
		ChatFrame_AddMessageEventFilter(event, urlFilterFunc)
	end

	self:Refresh()

	for name, module in self:IterateModules() do
		if db.modules[name] ~= false then
			module:Enable()
		end
	end
end

function module:OnDisable()
	Media.UnregisterCallback(self, "LibSharedMedia_Registered")

	self:UnhookAll()

	if db.General.MinimalistTabs then
		configureTabs(false)
	end

	for i, name in ipairs(CHAT_FRAMES) do
		local chatFrame = _G[name]
		chatFrame:SetFading(true)
		chatFrame:SetFont(Media:Fetch("font", dbd.General.Font.Font), 14)
	end

	for _, event in ipairs(urlEvents) do
		ChatFrame_RemoveMessageEventFilter(event, urlFilterFunc)
	end
end

---[[	PROFILER
-- Add Chat module functions to the profiler.
LUI.Profiler.TraceScope(module, "Chat", "LUI")
--]]
