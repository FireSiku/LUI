--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: chat.lua
	Description: Chat Module
]]

-- External references.
---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Chat : LUIModule, AceHook-3.0
local module = LUI:NewModule("Chat", "LUIDevAPI", "AceHook-3.0")
local Media = LibStub("LibSharedMedia-3.0")

local L = LUI.L
local db

local ChatFrameUtil = _G.ChatFrameUtil
local FCF_GetCurrentChatFrame = _G.FCF_GetCurrentChatFrame
local FCFDock_SelectWindow = _G.FCFDock_SelectWindow
local FCFTab_UpdateAlpha = _G.FCFTab_UpdateAlpha
local GENERAL_CHAT_DOCK = _G.GENERAL_CHAT_DOCK
local IsShiftKeyDown = _G.IsShiftKeyDown
local PARTY_LEADER = _G.PARTY_LEADER
local IsAltKeyDown = _G.IsAltKeyDown
local CHAT_FRAMES = _G.CHAT_FRAMES
local COMBATLOG = _G.COMBATLOG
local CLOSE = _G.CLOSE

--------------------------------------------------
-- Local Variables
--------------------------------------------------

local urlEvents, urlPatterns
do
	local formatStr = "|cffb4b4b4|Hurl:%s|h[%s]|h|r"

	local function urlLink(link)
		if link == nil then
			return ""
		end

		return format(formatStr, link, link)
	end

	urlEvents = {
		"CHAT_MSG_CHANNEL", "CHAT_MSG_COMMUNITIES_CHANNEL", "CHAT_MSG_EMOTE",
		"CHAT_MSG_GUILD", "CHAT_MSG_OFFICER",
		"CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER", "CHAT_MSG_PARTY", "CHAT_MSG_RAID",
		"CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING", "CHAT_MSG_PARTY_LEADER",
		"CHAT_MSG_SAY", "CHAT_MSG_WHISPER", "CHAT_MSG_BN_WHISPER",
		"CHAT_MSG_WHISPER_INFORM", "CHAT_MSG_YELL", "CHAT_MSG_BN_WHISPER_INFORM",
	}

	urlPatterns = {
		-- X://Y url
		{ pattern = "^(%a[%w%.+-]+://%S+)", matchfunc=urlLink},
		{ pattern = "%f[%S](%a[%w%.+-]+://%S+)", matchfunc=urlLink},
		-- www.X.Y url
		{ pattern = "^(www%.[-%w_%%]+%.%S+)", matchfunc=urlLink},
		{ pattern = "%f[%S](www%.[-%w_%%]+%.%S+)", matchfunc=urlLink},
		-- X@Y.Z email
		{ pattern = "(%S+@[-%w_%%%.]+%.(%a%a+))", matchfunc=urlLink},
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
		{ pattern = "^([-%w_%%%.]+[-%w_%%]%.(%a%a+):[0-6]?%d?%d?%d?%d/%S+)", matchfunc=urlLink},
		{ pattern = "%f[%S]([-%w_%%%.]+[-%w_%%]%.(%a%a+):[0-6]?%d?%d?%d?%d/%S+)", matchfunc=urlLink},
		-- X.Y.Z:WWWW url with port (ts server for example)
		{ pattern = "^([-%w_%%%.]+[-%w_%%]%.(%a%a+):[0-6]?%d?%d?%d?%d)%f[%D]", matchfunc=urlLink},
		{ pattern = "%f[%S]([-%w_%%%.]+[-%w_%%]%.(%a%a+):[0-6]?%d?%d?%d?%d)%f[%D]", matchfunc=urlLink},
		-- X.Y.Z/WWWWW url with path
		{ pattern = "^([-%w_%%%.]+[-%w_%%]%.(%a%a+)/%S+)", matchfunc=urlLink},
		{ pattern = "%f[%S]([-%w_%%%.]+[-%w_%%]%.(%a%a+)/%S+)", matchfunc=urlLink},
		-- X.Y.Z url
		{ pattern = "^([-%w_%%%.]+[-%w_%%]%.(%a%a+))", matchfunc=urlLink},
		{ pattern = "%f[%S]([-%w_%%%.]+[-%w_%%]%.(%a%a+))", matchfunc=urlLink},
	}
end

local shortChannelNames, shortChannelLinks, shortWhispers, rwFormat
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
	shortChannelLinks = {
		GUILD = "[G]",
		OFFICER = "[O]",
		PARTY = "[P]",
		PARTY_LEADER = "[PL]",
		RAID = "[R]",
		RAID_LEADER = "[RL]",
		RAID_WARNING = "[RW]",
		INSTANCE_CHAT = "[I]",
		INSTANCE_CHAT_LEADER = "[IL]",
	}
	if _G.INSTANCE_CHAT_MESSAGE then shortChannelNames[_G.INSTANCE_CHAT_MESSAGE] = "[I]" end
	if _G.INSTANCE_CHAT_LEADER then shortChannelNames[_G.INSTANCE_CHAT_LEADER] = "[IL]" end

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
	for k, v in pairs(shortChannelLinks) do
		shortChannelLinks[k] = L[v]
	end
	for k, v in pairs(shortWhispers) do
		shortWhispers[k] = L[v]
	end
end

local linkTypes = {
	item = true,
	spell = true,
	enchant = true,
	quest = true,
	achievement = true,
	currency = true,
	battlepet = true,
	instancelock = true,
}

local showingHyperlinkTooltip
local originalChatFrames = setmetatable({}, {__mode = "k"})
local originalTabs = setmetatable({}, {__mode = "k"})
local originalTabGlobals

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
			local button = self:GetButton2()
			local editBox = self:GetEditBox()
			button:ClearAllPoints()
			button:SetWidth(200)
			button:SetPoint("CENTER", editBox, "CENTER", 0, -30)
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

local function showURLCopy(url)
	if not url or issecretvalue(url) then return end
	if createStaticPopups then createStaticPopups() end

	local dialog = StaticPopup_Show("LUI_Chat_UrlCopy")
	if dialog then
		local editBox = dialog:GetEditBox()
		editBox:SetText(url)
		editBox:SetFocus()
		editBox:HighlightText(0)
	end
end

local function captureChatFrame(frame)
	if originalChatFrames[frame] then return end
	local font, fontSize, fontFlags = frame:GetFont()
	local left, right, top, bottom = frame:GetClampRectInsets()
	originalChatFrames[frame] = {
		font = font,
		fontSize = fontSize,
		fontFlags = fontFlags,
		fading = frame:GetFading(),
		clamped = frame:IsClampedToScreen(),
		clampInsets = {left, right, top, bottom},
	}
end

local function unclampChatFrame(frame)
	captureChatFrame(frame)
	frame:SetClampRectInsets(0,0,0,0)
	frame:SetClampedToScreen(false)
end

local function configureTab(tab, minimalist)
	if minimalist then
		if not originalTabs[tab] then
			originalTabs[tab] = {
				height = tab:GetHeight(),
				mouseWheelEnabled = tab:IsMouseWheelEnabled(),
			}
		end
		if not module:IsHooked(tab, "OnMouseWheel") then
			tab:SetHeight(29)
			tab:EnableMouseWheel(true)
			module:HookScript(tab, "OnMouseWheel")
		end
	else
		local original = originalTabs[tab]
		if original then
			tab:SetHeight(original.height)
			tab:EnableMouseWheel(original.mouseWheelEnabled)
			module:Unhook(tab, "OnMouseWheel")
			originalTabs[tab] = nil
		end
	end

	FCFTab_UpdateAlpha(_G[CHAT_FRAMES[tab:GetID()]])
end

local function configureTabs(minimalist, disableFading)
	if minimalist or disableFading then
		if not originalTabGlobals then
			originalTabGlobals = {
				fadeOutTime = _G.CHAT_FRAME_FADE_OUT_TIME,
				hideDelay = _G.CHAT_TAB_HIDE_DELAY,
				selectedMouseAlpha = _G.CHAT_FRAME_TAB_SELECTED_MOUSEOVER_ALPHA,
				selectedNoMouseAlpha = _G.CHAT_FRAME_TAB_SELECTED_NOMOUSE_ALPHA,
				normalMouseAlpha = _G.CHAT_FRAME_TAB_NORMAL_MOUSEOVER_ALPHA,
				normalNoMouseAlpha = _G.CHAT_FRAME_TAB_NORMAL_NOMOUSE_ALPHA,
			}
		end
		_G.CHAT_FRAME_FADE_OUT_TIME = minimalist and 0.5 or originalTabGlobals.fadeOutTime
		_G.CHAT_TAB_HIDE_DELAY = minimalist and 0 or originalTabGlobals.hideDelay
		_G.CHAT_FRAME_TAB_SELECTED_NOMOUSE_ALPHA = disableFading and originalTabGlobals.selectedMouseAlpha or 0
		_G.CHAT_FRAME_TAB_NORMAL_NOMOUSE_ALPHA = disableFading and originalTabGlobals.normalMouseAlpha or 0
	else
		if originalTabGlobals then
			_G.CHAT_FRAME_FADE_OUT_TIME = originalTabGlobals.fadeOutTime
			_G.CHAT_TAB_HIDE_DELAY = originalTabGlobals.hideDelay
			_G.CHAT_FRAME_TAB_SELECTED_NOMOUSE_ALPHA = originalTabGlobals.selectedNoMouseAlpha
			_G.CHAT_FRAME_TAB_NORMAL_NOMOUSE_ALPHA = originalTabGlobals.normalNoMouseAlpha
			originalTabGlobals = nil
		end
	end

	for i, name in ipairs(CHAT_FRAMES) do
		configureTab(_G[name.."Tab"], minimalist)
	end
end

local function urlFilterFunc(frame, event, msg, ...)
	if not msg or issecretvalue(msg) then return false, msg, ... end

	for i, v in ipairs(urlPatterns) do
		msg = gsub(msg, v.pattern, v.matchfunc)
	end

	return false, msg, ...
end

local function replaceChannel(origChannel, label)
	local replacement = shortChannelLinks[origChannel]
	if not replacement then
		local channelName = label:match("^%[[%d%. ]*(.-)%]$")
		if channelName then
			channelName = channelName:gsub("%s+%-%s+.*$", "")
			replacement = shortChannelNames[channelName]
		end

		if not replacement then
			local channelNumber = label:match("^%[(%d+)%.")
			if channelNumber then
				replacement = "["..channelNumber.."]"
			end
		end
	end

	return ("|Hchannel:%s|h%s|h"):format(origChannel, replacement or label)
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
	local EditBox = module:GetModule("EditBox")
	for i, name in ipairs(CHAT_FRAMES) do
		EditBox:UpdateEditBoxBackground(_G[name].editBox)
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
	end
	configureTab(_G[frame:GetName().."Tab"], db.General.MinimalistTabs)

	frame:SetFont(Media:Fetch("font", db.General.Font.Font), db.General.Font.Size, db.General.Font.Flag)

	if db.General.ShortChannelNames and not self:IsHooked(frame, "AddMessage") then
		self:RawHook(frame, "AddMessage", true)
	end

	frame:SetFading(not db.General.DisableFading)

	if db.General.LinkHover and not self:IsHooked(frame, "OnHyperlinkEnter") then
		self:HookScript(frame, "OnHyperlinkEnter")
		self:HookScript(frame, "OnHyperlinkLeave")
	end

	if db.General.ShiftMouseScroll and not self:IsHooked(frame, "OnMouseWheel") then
		self:HookScript(frame, "OnMouseWheel", "ScrollFrame_OnMouseWheel")
	end
end

function module:SetItemRef(link, text, button, chatFrame)
	if not issecretvalue(link) then
		local linkType, linkOptions = LinkUtil.SplitLinkData(link)
		if linkType == "url" then
			showURLCopy(linkOptions)
			return
		elseif IsAltKeyDown() and linkType == "player" then
			local playerName = linkOptions and linkOptions:match("^([^:]+)")
			if playerName then C_PartyInfo.InviteUnit(playerName) end
			local editBox = ChatFrameUtil.GetActiveWindow()
			if editBox then editBox:OnEscapePressed() end
			return
		end
	end

	return self.hooks.SetItemRef(link, text, button, chatFrame)
end

function module:AddMessage(frame, text, ...)
	if text and not issecretvalue(text) then
		if text:match("|Hchannel:") then
			text = gsub(text, "|Hchannel:([^|]+)|h(%b[])|h", replaceChannel)
		elseif text:match("WHISPER:.-|h") then
			text = gsub(text, "^(.+:)", replaceWhisper)
		else
			text = gsub(text, rwFormat, replaceChannelRW)
		end
	end

	return self.hooks[frame].AddMessage(frame, text, ...)
end

function module:OnHyperlinkEnter(frame, link, text)
	-- Retail chat text can be secret even when its hyperlink payload is safe.
	-- GameTooltip only needs the payload for normal links, so do not suppress
	-- item tooltips merely because the displayed text is protected.
	if issecretvalue(link) then return end
	local linkType = LinkUtil.SplitLinkData(link)
	if linkTypes[linkType] then
		GameTooltip:SetOwner(frame, "ANCHOR_CURSOR_RIGHT")
		if linkType == "battlepet" then
			if not issecretvalue(text) and BattlePetToolTip_ShowLink(text) then
				showingHyperlinkTooltip = BattlePetTooltip
			end
		else
			GameTooltip:SetHyperlink(link)
			GameTooltip:Show()
			showingHyperlinkTooltip = GameTooltip
		end
	end
end

function module:OnHyperlinkLeave(frame, link)
	if showingHyperlinkTooltip then
		showingHyperlinkTooltip:Hide()
		showingHyperlinkTooltip = nil
	end
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
				Flag = "",
			},
			ShortChannelNames = true,
			DisableFading = true,
			DisableTabFading = false,
			MinimalistTabs = true,
			LinkHover = true,
			ShiftMouseScroll = true,
		},
	},
}

module.conflicts = {"Chatter", "Prat-3.0"}
module.enableButton = true

function module:Refresh(info, value)
	if type(info) == "table" then
		self:SetDBVar(info, value)
	end

	for i, name in ipairs(CHAT_FRAMES) do
		local frame = _G[name]
		captureChatFrame(frame)

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

	end

	configureTabs(db.General.MinimalistTabs, db.General.DisableTabFading)

	self:LibSharedMedia_Registered("font", db.General.Font.Font)

	for name, module in self:IterateModules() do
		if module.Refresh and module:IsEnabled() then
			module:Refresh()
		end
	end
end

function module:DBCallback(event, dbobj, profile)
	db = LUI:Namespace(self)
	db.modules = db.modules or {}

	for name, module in self:IterateModules() do
		if module.DBCallback then
			module:DBCallback()
		end

		local shouldEnable = self:IsEnabled() and db.modules[name] ~= false
		if shouldEnable ~= module:IsEnabled() then
			module:LegacyToggle(shouldEnable)
		end
	end

	if self:IsEnabled() then
		self:Refresh()
	end
end

function module:OnInitialize()
	db = LUI:Namespace(self, true)
	db.modules = db.modules or {}
	LUI.Profiler.TraceScope(module, "Chat", "LUI", 2)

	local disabled = not self.enabledState
	for name, module in self:IterateModules() do
		-- Add Chat module functions to the profiler.
		LUI.Profiler.TraceScope(module, name, "Chat", 2)

		if disabled then
			module:SetEnabledState(false)
		elseif db.modules[name] ~= nil then
			module:SetEnabledState(db.modules[name])
		end
	end
end

function module:OnEnable()
	db.modules = db.modules or {}
		
	Media.RegisterCallback(self, "LibSharedMedia_Registered")

	if createStaticPopups then
		createStaticPopups()
	end

	self:SecureHook("FCF_OpenTemporaryWindow")
	self:RawHook("SetItemRef", true)

	for i, name in ipairs(CHAT_FRAMES) do
		local frame = _G[name]
		unclampChatFrame(frame)
	end

	for _, event in ipairs(urlEvents) do
		ChatFrameUtil.AddMessageEventFilter(event, urlFilterFunc)
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

	for name, childModule in self:IterateModules() do
		if childModule:IsEnabled() then
			childModule:Disable()
		end
	end

	self:UnhookAll()

	configureTabs(false, false)

	for i, name in ipairs(CHAT_FRAMES) do
		local chatFrame = _G[name]
		local original = originalChatFrames[chatFrame]
		if original then
			chatFrame:SetFading(original.fading)
			chatFrame:SetFont(original.font, original.fontSize, original.fontFlags)
			chatFrame:SetClampRectInsets(unpack(original.clampInsets))
			chatFrame:SetClampedToScreen(original.clamped)
			originalChatFrames[chatFrame] = nil
		end
	end

	for _, event in ipairs(urlEvents) do
		ChatFrameUtil.RemoveMessageEventFilter(event, urlFilterFunc)
	end
end
