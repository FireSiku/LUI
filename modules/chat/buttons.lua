--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: buttons.lua
	Description: Chat Buttons Module
]]

-- External references.
local addonname, LUI = ...
local Chat = LUI:Module("Chat")
local module = Chat:Module("Buttons", "AceHook-3.0")

local L = LUI.L
local db, dbd

--------------------------------------------------
-- Local Variables
--------------------------------------------------

local lines = {}

local copyFrame

--------------------------------------------------
-- Local Functions
--------------------------------------------------

local function getChatLines(...)
	wipe(lines)
	local numLines = select("#", ...)
	for i = 1, numLines do
		local region = select(numLines-i+1, ...)
		if region:GetObjectType() == "FontString" then
			lines[i] = tostring(region:GetText())
		end
	end
end

local function copyButtonOnClick(button, frame)
	local _, size = frame:GetFont()
	FCF_SetChatWindowFontSize(frame, frame, 0.01)
	getChatLines(frame:GetRegions())
	local text = table.concat(lines, "\n")
	FCF_SetChatWindowFontSize(frame, frame, size)
	copyFrame:Show()
	copyFrame.editBox:SetText(text)
	copyFrame.editBox:HighlightText(0)
end

local function createCopyButtton(frame)
	local button = frame.copyButton

	if not button then
		button = CreateFrame("Button", nil, frame, "LUI_Chat_CopyButtonTemplate")
		button.onClick = copyButtonOnClick
		button.frame = frame
	end

	button:SetScale(db.CopyScale)
	button:Show()
end

local function configCopyButton(show)
	if show then
		if not copyFrame then
			copyFrame = CreateFrame("Frame", "LUI_Chat_CopyFrame", UIParent)
			tinsert(UISpecialFrames, "LUI_Chat_CopyFrame")
			copyFrame:SetBackdrop({
				bgFile = [[Interface\DialogFrame\UI-DialogBox-Background]],
				edgeFile = [[Interface\DialogFrame\UI-DialogBox-Border]],
				tile = true, tileSize = 16, edgeSize = 16,
				insets = { left = 3, right = 3, top = 5, bottom = 3 }
			})
			copyFrame:SetBackdropColor(0, 0, 0, 1)
			copyFrame:SetSize(500, 400)
			copyFrame:SetPoint("CENTER")
			copyFrame:SetFrameStrata("DIALOG")
			copyFrame:Hide()

			local scrollArea = CreateFrame("ScrollFrame", "LUI_Chat_CopyScrollFrame", copyFrame, "UIPanelScrollFrameTemplate")
			scrollArea:SetPoint("TOPLEFT", 8, -30)
			scrollArea:SetPoint("BOTTOMRIGHT", -30, 8)
			copyFrame.scrollArea = scrollArea

			local editBox = CreateFrame("EditBox", nil, copyFrame)
			editBox:SetMultiLine(true)
			editBox:SetMaxLetters(99999)
			editBox:EnableMouse(true)
			editBox:SetAutoFocus(false)
			editBox:SetFontObject(ChatFontNormal)
			editBox:SetSize(400, 270)
			editBox:SetScript("OnEscapePressed", function() copyFrame:Hide() end)
			copyFrame.editBox = editBox

			scrollArea:SetScrollChild(editBox)

			local close = CreateFrame("Button", nil, copyFrame, "UIPanelCloseButton")
			close:SetPoint("TOPRIGHT")
		end

		for i, name in ipairs(CHAT_FRAMES) do
			createCopyButtton(_G[name])
		end
	else
		if not copyFrame then return end

		copyFrame:Hide()
		for i, name in ipairs(CHAT_FRAMES) do
			local frame = _G[name]
			if frame.copyButton then
				frame.copyButton:Hide()
			end
		end
	end
end

local function createScrollButton(frame)
	local button = frame.downButton

	if not button then
		button = CreateFrame("Button", nil, frame, "LUI_Chat_ScrollButtonTemplate")
		button.frame = frame
	end

	button:SetScale(db.ScrollScale)

	if module:IsHooked(frame, "ScrollUp") then return end

	module:SecureHook(frame, "ScrollUp", "Scroll")
	module:SecureHook(frame, "ScrollToTop", "Scroll")
	module:SecureHook(frame, "PageUp", "Scroll")
	module:SecureHook(frame, "ScrollDown", "Scroll")
	module:SecureHook(frame, "ScrollToBottom", "Scroll")
	module:SecureHook(frame, "PageDown", "Scroll")

	if frame:GetScrollOffset() ~= 0 then
		button:Show()
	end

	if frame ~= COMBATLOG then
		module:SecureHook(frame, "AddMessage")
	end
end

local function configScrollButton(show)
	if show then
		for i, name in ipairs(CHAT_FRAMES) do
			createScrollButton(_G[name])
		end
	else
		for i, name in ipairs(CHAT_FRAMES) do
			local frame = _G[name]

			if frame.downButton then
				module:Unhook(frame, "ScrollUp")
				module:Unhook(frame, "ScrollToTop")
				module:Unhook(frame, "PageUp")
				module:Unhook(frame, "ScrollDown")
				module:Unhook(frame, "ScrollToBottom")
				module:Unhook(frame, "PageDown")
				module:Unhook(frame, "AddMessage")

				frame.downButton:Hide()
			end
		end
	end
end

local function hideButtons(frame)
	frame.buttonFrame.Show = LUI.dummy
	frame.buttonFrame:Hide()
end

local chatButtonNames = {
	"ChatFrameMenuButton",
	"QuickJoinToastButton",
}
local voiceButtonNames = {
	"ChatFrameChannelButton",
	"ChatFrameToggleVoiceDeafenButton",
	"ChatFrameToggleVoiceMuteButton",
}

local voiceHideFunc = function() return false end
local voiceOrigFunc = function() return C_VoiceChat.IsLoggedIn() end

local function configButtons(hide)
	if hide then
		if module:IsHooked("FCF_OpenTemporaryWindow") then return end

		module:SecureHook("FCF_OpenTemporaryWindow")
		
		for i, name in ipairs(chatButtonNames) do
			local frame = _G[name]
			LUI:Kill(frame)
		end

		for i, name in pairs(voiceButtonNames) do
			local frame = _G[name]
			frame:SetVisibilityQueryFunction(voiceHideFunc)
			frame:Hide()
		end

		for i, name in ipairs(CHAT_FRAMES) do
			hideButtons(_G[name])
		end
	else
		module:Unhook("FCF_OpenTemporaryWindow")

		for i, name in ipairs(chatButtonNames) do
			local frame = _G[name]
			frame.Show = nil
			frame:Show()
		end

		for i, name in pairs(voiceButtonNames) do
			local frame = _G[name]
			frame:SetVisibilityQueryFunction(voiceOrigFunc)
			if C_VoiceChat.IsLoggedIn() then
				frame:Show()
			end
		end

		for i, name in ipairs(CHAT_FRAMES) do
			local frame = _G[name]
			frame.buttonFrame.Show = nil
			frame.buttonFrame:Show()
		end

		configScrollButton(false)
	end
end

--------------------------------------------------
-- Hook Functions
--------------------------------------------------

function module:Scroll(frame)
	if frame:GetScrollOffset() == 0 then
		frame.downButton:Hide()
	else
		frame.downButton:Show()
	end
	frame.downButton:UnlockHighlight()
end

function module:AddMessage(frame)
	if frame:GetScrollOffset() > 0 then
		frame.downButton:Show()
		frame.downButton:LockHighlight() -- button glow informing of new message
	else
		frame.downButton:Hide()
		frame.downButton:UnlockHighlight()
	end
end

function module:FCF_OpenTemporaryWindow()
	local frame = FCF_GetCurrentChatFrame()

	hideButtons(frame)
	if db.ScrollReminder then
		createScrollButton(frame)
	end
end

--------------------------------------------------
-- Module Variables
--------------------------------------------------

module.defaults = {
	profile = {
		HideButtons = true,
		ScrollReminder = true,
		ScrollScale = 1,
		CopyChat = true,
		CopyScale = 1,
	}
}

--------------------------------------------------
-- Load Functions
--------------------------------------------------

function module:LoadOptions()
	local function buttonsDisabled()
		return not db.HideButtons
	end
	local function scrollButtonDisabled()
		return not db.HideButtons and not db.ScrollReminder
	end
	local function copyButtonDisabled()
		return not db.CopyChat
	end

	local options = self:NewGroup(L["Buttons"], 3, "generic", "Refresh", {
		HideButtons = self:NewToggle(L["Hide Buttons"], nil, 1, true),
		ScrollReminder = self:NewToggle(L["Scroll to bottom button"], L["Show scroll to bottom button when scrolled up"], 2, true, "normal", buttonsDisabled),
		ScrollScale = self:NewSlider(L["Scale"], L["Scale of the scroll to bottom button"], 3, 0.5, 2, 0.05, true, true, nil, scrollButtonDisabled),
		CopyChat = self:NewToggle(L["Copy chat button"], L["Show copy chat button"], 4, true, "normal"),
		CopyScale = self:NewSlider(L["Scale"], L["Scale of the copy chat button"], 5, 0.5, 2, 0.05, true, true, nil, copyButtonDisabled),
	})

	return options
end

function module:Refresh(info, value)
	if type(info) == "table" then
		self:SetDBVar(info, value)
	end

	configButtons(db.HideButtons)
	configScrollButton(db.HideButtons and db.ScrollReminder)
	configCopyButton(db.CopyChat)
end

function module:OnInitialize()
	db, dbd = Chat:Namespace(self)
end

module.DBCallback = module.OnInitialize

function module:OnEnable()
	if db.HideButtons then
		configButtons(true)
		if db.ScrollReminder then
			configScrollButton(true)
		end
	end
	if db.CopyChat then
		configCopyButton(true)
	end
end

function module:OnDisable()
	self:UnhookAll()

	if db.HideButtons then
		configButtons(false)
	end
	if db.CopyChat then
		configCopyButton(false)
	end
end
