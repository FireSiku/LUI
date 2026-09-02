--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: buttons.lua
	Description: Chat Buttons Module
]]

-- External references.
---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Chat
local Chat = LUI:GetModule("Chat")
local module = Chat:NewModule("Buttons", "LUIDevAPI", "AceHook-3.0")

local L = LUI.L
local db

--------------------------------------------------
-- Local Variables
--------------------------------------------------

local FCF_GetCurrentChatFrame = _G.FCF_GetCurrentChatFrame
local ChatFontNormal = _G.ChatFontNormal
local CHAT_FRAMES = _G.CHAT_FRAMES
local COMBATLOG = _G.COMBATLOG

local lines = {}
local copyFrame
local killedFrameStates = setmetatable({}, {__mode = "k"})

--------------------------------------------------
-- Local Functions
--------------------------------------------------

local function getChatLines(frame)
	wipe(lines)
	for i = 1, frame:GetNumMessages() do
		local text = frame:GetMessageInfo(i)
		if text and not issecretvalue(text) then
			lines[#lines + 1] = text
		end
	end
	return table.concat(lines, "\n")
end

local function copyButtonOnClick(button, frame)
	local text = getChatLines(frame)
	copyFrame:Show()
	copyFrame.editBox:SetWidth(math.max(1, copyFrame.scrollArea:GetWidth() - 18))
	copyFrame.editBox:SetText(text)
	copyFrame.editBox:HighlightText(0)
end

local function createCopyButton(frame)
	if not frame then return end
	local button = frame.copyButton

	if not button then
		button = CreateFrame("Button", nil, frame, "LUI_Chat_CopyButtonTemplate")
		button.onClick = copyButtonOnClick
		button.frame = frame
		button.tooltipText = L["Copy chat button"]
	end

	button:SetScale(db.CopyScale)
	button:Show()
end

local function configCopyButton(show)
	if show then
		if not copyFrame then
			copyFrame = CreateFrame("Frame", "LUI_Chat_CopyFrame", UIParent)
			tinsert(UISpecialFrames, "LUI_Chat_CopyFrame")
			LUI:ApplyFrameBackdrop(copyFrame, {
				bgFile = [[Interface\DialogFrame\UI-DialogBox-Background]],
				edgeFile = [[Interface\DialogFrame\UI-DialogBox-Border]],
				tile = true, tileSize = 16, edgeSize = 16,
				insets = { left = 3, right = 3, top = 5, bottom = 3 }
			})
			LUI:SetFrameBackgroundColor(copyFrame, 0, 0, 0, 1)
			copyFrame:SetSize(500, 400)
			copyFrame:SetPoint("CENTER")
			copyFrame:SetFrameStrata("DIALOG")
			copyFrame:Hide()

			local scrollArea = CreateFrame("ScrollFrame", "LUI_Chat_CopyScrollFrame", copyFrame, "UIPanelInputScrollFrameTemplate")
			scrollArea:SetPoint("TOPLEFT", 8, -30)
			scrollArea:SetPoint("BOTTOMRIGHT", -30, 8)
			copyFrame.scrollArea = scrollArea

			for _, texture in ipairs({
				scrollArea.TopLeftTex, scrollArea.TopRightTex, scrollArea.TopTex,
				scrollArea.BottomLeftTex, scrollArea.BottomRightTex, scrollArea.BottomTex,
				scrollArea.LeftTex, scrollArea.RightTex, scrollArea.MiddleTex,
			}) do
				texture:Hide()
			end
			scrollArea.CharCount:Hide()

			local editBox = scrollArea.EditBox
			editBox:SetMaxLetters(99999)
			editBox:SetFontObject(ChatFontNormal)
			editBox:SetWidth(math.max(1, scrollArea:GetWidth() - 18))
			editBox:SetScript("OnEscapePressed", function() copyFrame:Hide() end)
			copyFrame.editBox = editBox

			local close = CreateFrame("Button", nil, copyFrame, "UIPanelCloseButton")
			close:SetPoint("TOPRIGHT")
		end

		for i, name in ipairs(CHAT_FRAMES) do
			createCopyButton(_G[name])
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
	if not frame then return end
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

local function killFrame(frame)
	if not frame then return end
	if not killedFrameStates[frame] then
		killedFrameStates[frame] = {shown = frame:IsShown()}
	end
	LUI:Kill(frame)
end

local function restoreFrame(frame)
	if not frame then return end
	local original = killedFrameStates[frame]
	LUI:Unkill(frame)
	if original then
		frame:SetShown(original.shown)
		killedFrameStates[frame] = nil
	end
end

local function hideButtons(frame)
	if not frame then return end
	killFrame(frame.buttonFrame)
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
local voiceVisibility = setmetatable({}, {__mode = "k"})

local function updateTemporaryWindowHook()
	local needed = db.HideButtons or db.CopyChat
	if needed and not module:IsHooked("FCF_OpenTemporaryWindow") then
		module:SecureHook("FCF_OpenTemporaryWindow")
	elseif not needed and module:IsHooked("FCF_OpenTemporaryWindow") then
		module:Unhook("FCF_OpenTemporaryWindow")
	end
end

local function configButtons(hide)
	if hide then
		for i, name in ipairs(chatButtonNames) do
			local frame = _G[name]
			killFrame(frame)
		end
		for i, name in ipairs(voiceButtonNames) do
			local frame = _G[name]
			if frame and not voiceVisibility[frame] then
				voiceVisibility[frame] = {query = frame.isVisible}
			end
			if frame then
				frame:SetVisibilityQueryFunction(voiceHideFunc)
				frame:UpdateVisibleState()
			end
		end
		for i, name in ipairs(CHAT_FRAMES) do
			hideButtons(_G[name])
		end
	else
		for i, name in ipairs(chatButtonNames) do
			local frame = _G[name]
			restoreFrame(frame)
		end
		for i, name in ipairs(voiceButtonNames) do
			local frame = _G[name]
			if frame then
				local original = voiceVisibility[frame]
				local visibility = original and original.query
				if not visibility then
					frame.isVisible = nil
				else
					frame:SetVisibilityQueryFunction(visibility)
				end
				voiceVisibility[frame] = nil
				frame:UpdateVisibleState()
			end
		end
		for i, name in ipairs(CHAT_FRAMES) do
			local frame = _G[name]
			restoreFrame(frame.buttonFrame)
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

	if db.HideButtons then
		hideButtons(frame)
	end
	if db.HideButtons and db.ScrollReminder then
		createScrollButton(frame)
	end
	if db.CopyChat then
		createCopyButton(frame)
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

function module:Refresh(info, value)
	if type(info) == "table" then
		self:SetDBVar(info, value)
	end

	configButtons(db.HideButtons)
	configScrollButton(db.HideButtons and db.ScrollReminder)
	configCopyButton(db.CopyChat)
	updateTemporaryWindowHook()
end

function module:OnInitialize()
	db = Chat:Namespace(self)
end

module.DBCallback = module.OnInitialize

function module:OnEnable()
	if db.HideButtons then
		configButtons(true)
		if db.ScrollReminder then
			configScrollButton(true)
		end
	end
	configCopyButton(db.CopyChat)
	updateTemporaryWindowHook()
end

function module:OnDisable()
	if db.HideButtons then
		configButtons(false)
	end
	configCopyButton(false)
	self:UnhookAll()
end
