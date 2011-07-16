--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: chat.lua
	Description: Chat Module
	Version....: 1.1
	Rev Date...: 19/01/2011 [dd/mm/yyyy]
	
	Edits:
		v1.0: Loui
		v1.1: Zista
]] 

local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local LSM = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists
local LUIHook = LUI:GetModule("LUIHook")
local module = LUI:NewModule("Chat", "AceHook-3.0")

local db
local fontflags = {'OUTLINE', 'THICKOUTLINE', 'MONOCHROME', 'NONE'}
local chatTextureAnchors = {'ChatFrame2', 'ChatFrame3', 'ChatFrame4', 'ChatFrame5', 'ChatFrame6', 'ChatFrame7', 'ChatFrame8', 'ChatFrame9', 'ChatFrame10'}
local editboxanchors = {'TOP', 'BOTTOM', 'INDIVIDUAL'}
local chatAlignments = {'LEFT', 'CENTER', 'RIGHT'}
local channels = {
	CHANNEL = "Custom channels",
	EMOTE = "Emote",
	OFFICER = "Officer",
	RAID_WARNING = "Raid Warning",
	BN_WHISPER = "RealID Whisper",
	SAY = "Say",
	WHISPER = "Whisper",
	YELL = "Yell"
}
local hooks = { }

local function SetTabsAlpha()
	CHAT_FRAME_TAB_SELECTED_NOMOUSE_ALPHA = db.Chat.Tabs.ActiveAlpha;
    CHAT_FRAME_TAB_NORMAL_NOMOUSE_ALPHA = db.Chat.Tabs.NotActiveAlpha;
	
	for i = 1, NUM_CHAT_WINDOWS do
		chatframe = _G[("ChatFrame%d"):format(i)]
		if FCF_IsValidChatFrame(chatframe) and not chatframe.oldAlpha then
			chatframe.oldAlpha = CHAT_FRAME_TAB_NORMAL_NOMOUSE_ALPHA
		end
	end
    
    for i = 1, NUM_CHAT_WINDOWS do
		chatframe = _G[("ChatFrame%d"):format(i)]
       	if FCF_IsValidChatFrame(chatframe) then
			local chatTab = _G["ChatFrame"..i.."Tab"]
            chatTab:Show()
            chatTab:Hide()
            --FloatingChatFrame_Update(chatframe:GetID()) 
            
            chatTab.mouseOverAlpha = CHAT_FRAME_TAB_SELECTED_MOUSEOVER_ALPHA;            
	        chatTab.noMouseAlpha = CHAT_FRAME_TAB_SELECTED_NOMOUSE_ALPHA;
            
            if chatframe:IsShown() then FCF_FadeOutChatFrame(chatframe) end
      	end
    end
end

local function SetChatFading()
	if db.Chat.Fading == true then
		for i = 1, NUM_CHAT_WINDOWS do
			chatframe = _G[("ChatFrame%d"):format(i)]
			chatframe:SetFading(1)
			chatframe:SetTimeVisible(180)
		end
	else
		for i = 1, NUM_CHAT_WINDOWS do
			chatframe = _G[("ChatFrame%d"):format(i)]
			chatframe:SetFading(0)
		end
	end
end

local function CheckChatMinimizeButton()
	if db.Chat.Buttons.MinimizeButton.Enable == true then
		for i = 2, NUM_CHAT_WINDOWS do
			local chatFrame = "ChatFrame"..i
			if chatFrame == db.Chat.SecondChatAnchor and db.Chat.SecondChatFrame == true then
				_G["ChatFrame"..i.."ButtonFrameMinimizeButton"]:Hide()
				_G["ChatFrame"..i.."ButtonFrameMinimizeButton"]:SetScript("OnShow", function(self) self:Hide() end)
			else
				_G["ChatFrame"..i.."ButtonFrameMinimizeButton"]:ClearAllPoints()
				_G["ChatFrame"..i.."ButtonFrameMinimizeButton"]:SetPoint("BOTTOM", _G["ChatFrame"..i.."ButtonFrame"],"BOTTOM",tonumber(db.Chat.Buttons.MinimizeButton.X),tonumber(db.Chat.Buttons.MinimizeButton.Y))
				_G["ChatFrame"..i.."ButtonFrameMinimizeButton"]:SetAlpha(db.Chat.Buttons.MinimizeButton.AlphaOut)
				_G["ChatFrame"..i.."ButtonFrameMinimizeButton"]:SetScript("OnShow", function(self) self:Show() end)
				_G["ChatFrame"..i.."ButtonFrameMinimizeButton"]:Show()
				
				_G["ChatFrame"..i.."ButtonFrameMinimizeButton"]:SetScript("OnEnter", function()
					_G["ChatFrame"..i.."ButtonFrameMinimizeButton"]:SetAlpha(tonumber(db.Chat.Buttons.MinimizeButton.AlphaIn)) 
				end)
					
				_G["ChatFrame"..i.."ButtonFrameMinimizeButton"]:SetScript("OnLeave", function()
					_G["ChatFrame"..i.."ButtonFrameMinimizeButton"]:SetAlpha(tonumber(db.Chat.Buttons.MinimizeButton.AlphaOut)) 
				end)
			end
		end
	else
		for i = 1, NUM_CHAT_WINDOWS do
			_G["ChatFrame"..i.."ButtonFrameMinimizeButton"]:Hide()
			_G["ChatFrame"..i.."ButtonFrameMinimizeButton"]:SetScript("OnShow", function(self) self:Hide() end)
		end
	end
end

local function CheckChatMenuButton()
	if db.Chat.Buttons.MenuButton.Enable == true then
		ChatFrameMenuButton:SetAlpha(tonumber(db.Chat.Buttons.MenuButton.AlphaOut))
		ChatFrameMenuButton:ClearAllPoints()
		ChatFrameMenuButton:SetPoint("BOTTOM", _G["ChatFrame1ButtonFrame"],"BOTTOM",tonumber(db.Chat.Buttons.MenuButton.X),tonumber(db.Chat.Buttons.MenuButton.Y))
		ChatFrameMenuButton:SetScript("OnShow", function(self) self:Show() end)
		ChatFrameMenuButton:Show()
		
		ChatFrameMenuButton:SetScript("OnEnter", function()
			ChatFrameMenuButton:SetAlpha(tonumber(db.Chat.Buttons.MenuButton.AlphaIn)) 
		end)
			
		ChatFrameMenuButton:SetScript("OnLeave", function()
			ChatFrameMenuButton:SetAlpha(tonumber(db.Chat.Buttons.MenuButton.AlphaOut)) 
		end)
	else
		ChatFrameMenuButton:Hide()
		ChatFrameMenuButton:SetScript("OnShow", function(self) self:Hide() end)
	end
end

local function CheckChatBottomButton()
	if db.Chat.Buttons.BottomButton.Enable == true then
		for i = 1, NUM_CHAT_WINDOWS do
			_G["ChatFrame"..i.."ButtonFrameBottomButton"]:ClearAllPoints()
			_G["ChatFrame"..i.."ButtonFrameBottomButton"]:SetPoint("BOTTOM", _G["ChatFrame"..i.."ButtonFrame"],"BOTTOM",tonumber(db.Chat.Buttons.BottomButton.X),tonumber(db.Chat.Buttons.BottomButton.Y))
			_G["ChatFrame"..i.."ButtonFrameBottomButton"]:SetAlpha(db.Chat.Buttons.BottomButton.AlphaOut)
			_G["ChatFrame"..i.."ButtonFrameBottomButton"]:SetScript("OnShow", function(self) self:Show() end)
			_G["ChatFrame"..i.."ButtonFrameBottomButton"]:Show()
			
			_G["ChatFrame"..i.."ButtonFrameBottomButton"]:SetScript("OnEnter", function()
				_G["ChatFrame"..i.."ButtonFrameBottomButton"]:SetAlpha(tonumber(db.Chat.Buttons.BottomButton.AlphaIn)) 
			end)
				
			_G["ChatFrame"..i.."ButtonFrameBottomButton"]:SetScript("OnLeave", function()
				_G["ChatFrame"..i.."ButtonFrameBottomButton"]:SetAlpha(tonumber(db.Chat.Buttons.BottomButton.AlphaOut)) 
			end)
		end
	else
		for i = 1, NUM_CHAT_WINDOWS do
			_G["ChatFrame"..i.."ButtonFrameBottomButton"]:Hide()
			_G["ChatFrame"..i.."ButtonFrameBottomButton"]:SetScript("OnShow", function(self) self:Hide() end)
		end
	end
end

local function CheckChatButtons()
	if db.Chat.Buttons.Enable == true then
		for i = 1, NUM_CHAT_WINDOWS do
			_G["ChatFrame"..i.."ButtonFrame"]:SetScript("OnShow", function(self) self:Show() end)
			_G["ChatFrame"..i.."ButtonFrame"]:Show()
		end
	else
		for i = 1, NUM_CHAT_WINDOWS do
			_G["ChatFrame"..i.."ButtonFrame"]:Hide()
			_G["ChatFrame"..i.."ButtonFrame"]:SetScript("OnShow", function(self) self:Hide() end)
		end
	end
end

local function CheckChatArrows()
	if db.Chat.Buttons.Arrows.Enable == true then
		for i = 1, NUM_CHAT_WINDOWS do
			local buttonUp = _G["ChatFrame"..i.."ButtonFrameUpButton"]
			local buttonDown = _G["ChatFrame"..i.."ButtonFrameDownButton"]
			local buttonFrame = _G["ChatFrame"..i.."ButtonFrame"]
		
			buttonUp:SetAlpha(db.Chat.Buttons.Arrows.AlphaOut)
			buttonUp:SetScript("OnShow", function(self) self:Show() end)
			buttonUp:Show()
			
			buttonDown:ClearAllPoints()
			buttonDown:SetPoint("BOTTOM", buttonFrame,"BOTTOM",tonumber(db.Chat.Buttons.Arrows.X),tonumber(db.Chat.Buttons.Arrows.Y))
			buttonDown:SetAlpha(db.Chat.Buttons.Arrows.AlphaOut)
			buttonDown:SetScript("OnShow", function(self) self:Show() end)
			buttonDown:Show()
			
			buttonUp:SetScript("OnEnter", function()
				buttonUp:SetAlpha(tonumber(db.Chat.Buttons.Arrows.AlphaIn)) 
			end)
				
			buttonUp:SetScript("OnLeave", function()
				buttonUp:SetAlpha(tonumber(db.Chat.Buttons.Arrows.AlphaOut)) 
			end)
			
			buttonDown:SetScript("OnEnter", function()
				buttonDown:SetAlpha(tonumber(db.Chat.Buttons.Arrows.AlphaIn)) 
			end)
				
			buttonDown:SetScript("OnLeave", function()
				buttonDown:SetAlpha(tonumber(db.Chat.Buttons.Arrows.AlphaOut)) 
			end)
		end
	else
		for i = 1, NUM_CHAT_WINDOWS do
			_G["ChatFrame"..i.."ButtonFrameUpButton"]:Hide()
			_G["ChatFrame"..i.."ButtonFrameDownButton"]:Hide()
			_G["ChatFrame"..i.."ButtonFrameUpButton"]:SetScript("OnShow", function(self) self:Hide() end)
			_G["ChatFrame"..i.."ButtonFrameDownButton"]:SetScript("OnShow", function(self) self:Hide() end)
		end
	end
end

local function CheckSocialButton()
	if db.Chat.Buttons.SocialButton.Enable == true then
		FriendsMicroButton:SetAlpha(db.Chat.Buttons.SocialButton.AlphaOut)
		FriendsMicroButton:ClearAllPoints()
		FriendsMicroButton:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", tonumber(db.Chat.Buttons.SocialButton.X), tonumber(db.Chat.Buttons.SocialButton.Y))
		FriendsMicroButton:SetScript("OnShow", FriendsMicroButton.Show)
		FriendsMicroButton:Show()
		
		FriendsMicroButton:SetScript("OnEnter", function()
			FriendsMicroButton:SetAlpha(tonumber(db.Chat.Buttons.SocialButton.AlphaIn)) 
		end)
			
		FriendsMicroButton:SetScript("OnLeave", function()
			FriendsMicroButton:SetAlpha(tonumber(db.Chat.Buttons.SocialButton.AlphaOut)) 
		end)
	else
		FriendsMicroButton:SetScript("OnShow", FriendsMicroButton.Hide)
		FriendsMicroButton:Hide()
	end
end

local function SetChatFont()
	for i = 1, NUM_CHAT_WINDOWS do
		_G["ChatFrame"..i]:SetFont(LSM:Fetch("font", db.Chat.Font), db.Chat.Size, db.Chat.Flag)
		_G["ChatFrame"..i.."EditBox"]:SetFont(LSM:Fetch("font", db.Chat.Editbox.Font), db.Chat.Editbox.Size, db.Chat.Editbox.Flag)
		_G["ChatFrame"..i.."EditBox"].header:SetFont(LSM:Fetch("font", db.Chat.Editbox.Font), db.Chat.Editbox.Size, db.Chat.Editbox.Flag)
	end
end

local function SetEditBoxPosition()
	for i = 1, NUM_CHAT_WINDOWS do
		local editbox = _G["ChatFrame"..i.."EditBox"]
		editbox:ClearAllPoints();
		if db.Chat.Editbox.Position.Anchor == "TOP" then
			editbox:SetPoint("BOTTOMLEFT", ChatFrame1, "TOPLEFT", 14, 12)
			editbox:SetPoint("BOTTOMRIGHT", ChatFrame1, "TOPRIGHT", 14, 12)
		elseif db.Chat.Editbox.Position.Anchor == "BOTTOM" then
			editbox:SetPoint("TOPLEFT", ChatFrame1, "BOTTOMLEFT", 0, -8)
			editbox:SetPoint("TOPRIGHT", ChatFrame1, "BOTTOMRIGHT", 0, -8)
		else		
			editbox:SetPoint("BOTTOMLEFT", ChatFrame1, "TOPLEFT", tonumber(db.Chat.Editbox.Position.X), tonumber(db.Chat.Editbox.Position.Y))
			editbox:SetPoint("BOTTOMRIGHT", ChatFrame1, "TOPRIGHT", tonumber(db.Chat.Editbox.Position.X), tonumber(db.Chat.Editbox.Position.Y))
		end
	end
end

local function SetEditBoxBackdrop()
	for i = 1, NUM_CHAT_WINDOWS do
		local editbox = _G["ChatFrame"..i.."EditBox"]
		
		editbox:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = LSM:Fetch("border", db.Chat.Editbox.Border.Texture),
			tile = 0, tileSize = 0, edgeSize = tonumber(db.Chat.Editbox.Border.Thickness),
			insets = { left = tonumber(db.Chat.Editbox.Border.Inset.left), right = tonumber(db.Chat.Editbox.Border.Inset.right), top = tonumber(db.Chat.Editbox.Border.Inset.top), bottom = tonumber(db.Chat.Editbox.Border.Inset.bottom) }
		})
	end
end

function module:SetChatPosition()
	ChatFrame1:SetMovable(true)
	ChatFrame1:SetUserPlaced(true)
	ChatFrame1:SetHeight(LUI:Scale(tonumber(db.Chat.Height)))
	ChatFrame1:SetWidth(LUI:Scale(tonumber(db.Chat.Width)))
	ChatFrame1:ClearAllPoints()
	ChatFrame1:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", LUI:Scale(tonumber(db.Chat.X)), LUI:Scale(tonumber(db.Chat.Y)))
	FCF_SavePositionAndDimensions(ChatFrame1)
	FCF_SetLocked(ChatFrame1, 1)
end

local function SetChatJustify()
	local SetChatFloating = loadstring("ChatFrame1:SetJustifyH(\""..db.Chat.Justify.."\")")
	SetChatFloating()
	
	local SetChatFloating2 = loadstring(db.Chat.SecondChatAnchor..":SetJustifyH(\""..db.Chat.Justify2.."\")")
	SetChatFloating2()
end

function module:SetColors()
	LUIHook:SetEditBoxColor()
end

function LUIHook:SetEditBoxColor(...)
	local r = db.Colors.editbox[1] or 0
	local g = db.Colors.editbox[2] or 0
	local b = db.Colors.editbox[3] or 0
	local a = db.Colors.editbox[4] or 0

	if db.Chat.Editbox.ColorByChannel == true then
		for i = 1, NUM_CHAT_WINDOWS do
			local editbox = _G["ChatFrame"..i.."EditBox"]
			local attr = editbox:GetAttribute("chatType")
			
			if attr == "CHANNEL" then
				local chan = editbox:GetAttribute("channelTarget")
				if chan == 0 then
					editbox:SetBackdropColor(r,g,b,a)
					editbox:SetBackdropBorderColor(r,g,b,a + 0.3)
				else
					local rc, gc, bc = GetMessageTypeColor("CHANNEL" .. chan)
					editbox:SetBackdropColor(rc, gc, bc, 0.2)
					editbox:SetBackdropBorderColor(rc, gc, bc, 0.5)
				end
			else
				local rc, gc, bc = GetMessageTypeColor(attr)
				editbox:SetBackdropColor(rc, gc, bc, 0.2)
				editbox:SetBackdropBorderColor(rc, gc, bc, 0.5)
			end
		end
	else
		for i = 1, NUM_CHAT_WINDOWS do
			local editbox = _G["ChatFrame"..i.."EditBox"]
			
			editbox:SetBackdropColor(r,g,b,a)
			editbox:SetBackdropBorderColor(r,g,b,a + 0.3)
		end
	end
end

local function SetChatStyle(frame)
	local id = frame:GetID()
	local chat = frame:GetName()
	local tab = _G[chat.."Tab"]
	
	-- yeah baby
	_G[chat]:SetClampRectInsets(0,0,0,0)
	
	-- Removes crap from the bottom of the chatbox so it can go to the bottom of the screen.
	_G[chat]:SetClampedToScreen(false)
	
	-- Hide textures
	for j = 1, #CHAT_FRAME_TEXTURES do
		_G[chat..CHAT_FRAME_TEXTURES[j]]:SetTexture(nil)
	end

	_G[chat.."ButtonFrameUpButton"]:Hide()
	_G[chat.."ButtonFrameDownButton"]:Hide()
	_G[chat.."ButtonFrameBottomButton"]:Hide()
	_G[chat.."ButtonFrameBottomButton"]:SetScript("OnShow", function(self) self:Hide() end)
	_G[chat.."ButtonFrameUpButton"]:SetScript("OnShow", function(self) self:Hide() end)
	_G[chat.."ButtonFrameDownButton"]:SetScript("OnShow", function(self) self:Hide() end)
end

-- Setup temp chat (BN, WHISPER) when needed.
local function SetupTempChat()
	local frame = FCF_GetCurrentChatFrame()
	SetChatStyle(frame)
end
hooksecurefunc("FCF_OpenTemporaryWindow", SetupTempChat)

function module:SetChat()
	if db.Chat.Enable ~= true then return end
	
	self:SetChatPosition()
	SetChatJustify()

	local chat_font, editbox_font
	
	if db.Chat.Font == nil or db.Chat.Font == "" then
		chat_font = "Fonts\ARIALN.TTF"
	else
		chat_font = LSM:Fetch("font", db.Chat.Font)
	end
	
	if db.Chat.Editbox.Font == nil or db.Chat.Editbox.Font == "" then
		editbox_font = "Fonts\ARIALN.TTF"
	else
		editbox_font = LSM:Fetch("font", db.Chat.Editbox.Font)
	end
		
	chat_fontsize = tonumber(db.Chat.Size)
	editbox_fontsize = tonumber(db.Chat.Editbox.Size)
	
	local player = UnitName("player")
	local ChatFrame1 = ChatFrame1
	local replace = string.gsub
	local find = string.find
	
	local replaceschan = {
		['Гильдия'] = '[Г]',
		['Группа'] = '[Гр]',
		['Рейд'] = '[Р]',
		['Лидер рейда'] = '[ЛР]',
		['Объявление рейду'] = '[ОР]',
		['Офицер'] = '[О]',
		['Поле боя'] = '[ПБ]',
		['Лидер поля боя'] = '[ЛПБ]', 
		['Guilde'] = '[G]',
		['Groupe'] = '[GR]',
		['Chef de raid'] = '[RL]',
		['Avertissement Raid'] = '[AR]',
		['Officier'] = '[O]',
		['Champs de bataille'] = '[CB]',
		['Chef de bataille'] = '[CDB]',
		['Guild'] = '[G]',
		['Party'] = '[P]',
		['Party Leader'] = '[PL]',
		['Raid'] = '[R]',
		['Raid Leader'] = '[RL]',
		['Raid Warning'] = '[RW]',
		['Officer'] = '[O]',
		['Battleground'] = '[B]',
		['Battleground Leader'] = '[BL]',
		['(%d+)%. .-'] = '[%1]',
	}
	
	-- Hook into the AddMessage function
	local AddMessageOriginal = ChatFrame1.AddMessage
	local function AddMessageHook(frame, text, ...)
		
		if db.Chat.ShortChannelNames == true then
			for k,v in pairs(replaceschan) do
				text = text:gsub('|h%['..k..'%]|h', '|h'..v..'|h')
			end
		end
		
		text = replace(text, "has come online.", "is now online!")
		text = replace(text, "|Hplayer:(.+)|h%[(.+)%]|h has earned", "|Hplayer:%1|h%2|h has earned")
		text = replace(text, "|Hplayer:(.+):(.+)|h%[(.+)%]|h whispers:", "From [|Hplayer:%1:%2|h%3|h]:")
		text = replace(text, "|Hplayer:(.+):(.+)|h%[(.+)%]|h says:", "[|Hplayer:%1:%2|h%3|h]:")	
		text = replace(text, "|Hplayer:(.+):(.+)|h%[(.+)%]|h yells:", "[|Hplayer:%1:%2|h%3|h]:")
			
		return AddMessageOriginal(frame, text, ...)
	end
	ChatFrame1.AddMessage = AddMessageHook
	
	local AddMessageOriginal2 = ChatFrame3.AddMessage
	local function AddMessageHook2(frame, text, ...)
		-- chan text smaller or hidden
		if db.Chat.ShortChannelNames == true then
			for k,v in pairs(replaceschan) do
				text = text:gsub('|h%['..k..'%]|h', '|h'..v..'|h')
			end
		end
		text = replace(text, "has come online.", "is now online!")
		text = replace(text, "|Hplayer:(.+)|h%[(.+)%]|h has earned", "|Hplayer:%1|h%2|h has earned")
		text = replace(text, "|Hplayer:(.+):(.+)|h%[(.+)%]|h whispers:", "From [|Hplayer:%1:%2|h%3|h]:")
		text = replace(text, "|Hplayer:(.+):(.+)|h%[(.+)%]|h says:", "[|Hplayer:%1:%2|h%3|h]:")	
		text = replace(text, "|Hplayer:(.+):(.+)|h%[(.+)%]|h yells:", "[|Hplayer:%1:%2|h%3|h]:")
			
		return AddMessageOriginal2(frame, text, ...)
	end
	ChatFrame3.AddMessage = AddMessageHook2
	
	-- WoW or battle.net player status
	CHAT_FLAG_AFK = "[AFK] "
	CHAT_FLAG_DND = "[DND] "
	CHAT_FLAG_GM = "[|cffff0000GM|r] "
	
	-----------------------------------------------------------------------------
	--Hide Blizzard Frames
	-----------------------------------------------------------------------------
	
	InterfaceOptionsSocialPanelChatStyle:Hide()
	InterfaceOptionsSocialPanelConversationMode:Hide()
	
	CheckChatButtons()
	CheckSocialButton()
	CheckChatArrows()
	CheckChatBottomButton()
	CheckChatMenuButton()
	CheckChatMinimizeButton()
	
	GeneralDockManagerOverflowButton:SetScript("OnShow", GeneralDockManagerOverflowButton.Hide)
	GeneralDockManagerOverflowButton:Hide()
	
	-- hide editbox colored round border
	for i = 1, 10 do
		local x=({_G["ChatFrame"..i.."EditBox"]:GetRegions()})
		x[9]:SetAlpha(0)
		x[10]:SetAlpha(0)
		x[11]:SetAlpha(0)
	end
	
	-----------------------------------------------------------------------------
	--Load Settings
	-----------------------------------------------------------------------------
	
	for i = 1, NUM_CHAT_WINDOWS do
		local chatframe = _G[("ChatFrame%d"):format(i)]
		_G["ChatFrame"..i]:SetClampRectInsets(0,0,0,0)
		_G["ChatFrame"..i]:SetWidth(LUI:Scale(tonumber(db.Chat.Width)))
		_G["ChatFrame"..i]:SetHeight(LUI:Scale(tonumber(db.Chat.Height)))
		_G["ChatFrame"..i]:SetFrameStrata("LOW")
		
		-- Hide chat textures backdrop
		for j = 1, #CHAT_FRAME_TEXTURES do
			_G["ChatFrame"..i..CHAT_FRAME_TEXTURES[j]]:SetTexture(nil)
		end
		
		-- Set Chat Font
		SetChatFont()
		
		-- Set Chat Fading
		SetChatFading()

		-----------------------------------------------------------------------------
		--EditBox Settings
		-----------------------------------------------------------------------------
		
		-- Hide Blizz Textures
		local editbox = _G["ChatFrame"..i.."EditBox"]
		local left, mid, right = select(6, editbox:GetRegions())
		left:Hide(); mid:Hide(); right:Hide()
		
		editbox.focusLeft:SetTexture([[Interface\ChatFrame\UI-ChatInputBorder-Left2]])
		editbox.focusRight:SetTexture([[Interface\ChatFrame\UI-ChatInputBorder-Right2]])
		editbox.focusMid:SetTexture([[Interface\ChatFrame\UI-ChatInputBorder-Mid2]])
		
		editbox:Hide()
		editbox:HookScript('OnEnterPressed', function(s) s:Hide() end)
		
		-- SetPosition
		SetEditBoxPosition()
		
		-- Disable alt key usage
		editbox:SetAltArrowKeyMode(false)
		
		--	Color Editbox
		SetEditBoxBackdrop()
		LUIHook:Unhook("ChatEdit_UpdateHeader")
		LUIHook:SecureHook("ChatEdit_UpdateHeader", "SetEditBoxColor", true)
		LUIHook:SetEditBoxColor()
	end
	
	-----------------------------------------------------------------------------
	--Tab Settings
	-----------------------------------------------------------------------------
	SetTabsAlpha()
	
	------------------------------------------------------------------------
	--	Lock docked tabs
	------------------------------------------------------------------------
	
	function ChatTab_OnDragStart(self)
		if IsAltKeyDown() or not _G[self:GetName():sub(1, -4)].isDocked then
			hooks[self].OnDragStart(self)
		end
	end
	
	function SetLockDockedTabs()
		if db.Chat.Tabs.LockDockedTabs == true then
			for i = 2, NUM_CHAT_WINDOWS do
				local tab = _G[("ChatFrame%dTab"):format(i)]
				if not hooks[tab] then
					hooks[tab] = { }
				end
				if not hooks[tab].OnDragStart then
					hooks[tab].OnDragStart = tab:GetScript("OnDragStart")
					tab:SetScript("OnDragStart", ChatTab_OnDragStart)
				end
			end
		else
			for i = 2, NUM_CHAT_WINDOWS do
				tab = _G[("ChatFrame%dTab"):format(i)]
				if hooks[tab] and hooks[tab].OnDragStart then
					tab:SetScript("OnDragStart", hooks[tab].OnDragStart)
					hooks[tab].OnDragStart = nil
				end
			end
		end
	end
	
	SetLockDockedTabs()
	
	-----------------------------------------------------------------------------
	-- Remember last channel
	-----------------------------------------------------------------------------
	
	if db.Chat.Sticky.Enable == true then
		for k, v in pairs(channels) do
			ChatTypeInfo[k].sticky = db.Chat.Sticky[k] and 1 or 0
		end
	else
		for k, v in pairs(channels) do
			ChatTypeInfo[k].sticky = 0
		end
	end

	-----------------------------------------------------------------------------
	-- copy url
	-----------------------------------------------------------------------------
	
	local SetItemRef_orig = SetItemRef
	function ReURL_SetItemRef(link, text, button, chatFrame)
		if (strsub(link, 1, 3) == "url") then
			local ChatFrameEditBox = ChatEdit_ChooseBoxForSend()
			local url = strsub(link, 5);
			if (not ChatFrameEditBox:IsShown()) then
				ChatEdit_ActivateChat(ChatFrameEditBox)
			end
			ChatFrameEditBox:Insert(url)
			ChatFrameEditBox:HighlightText()

		else
			SetItemRef_orig(link, text, button, chatFrame)
		end
	end
	SetItemRef = ReURL_SetItemRef

	function ReURL_AddLinkSyntax(chatstring)
		if (type(chatstring) == "string") then
			local extraspace;
			if (not strfind(chatstring, "^ ")) then
				extraspace = true;
				chatstring = " "..chatstring;
			end
			chatstring = gsub (chatstring, " www%.([_A-Za-z0-9-]+)%.(%S+)%s?", ReURL_Link("www.%1.%2"))
			chatstring = gsub (chatstring, " (%a+)://(%S+)%s?", ReURL_Link("%1://%2"))
			chatstring = gsub (chatstring, " ([_A-Za-z0-9-%.]+)@([_A-Za-z0-9-]+)(%.+)([_A-Za-z0-9-%.]+)%s?", ReURL_Link("%1@%2%3%4"))
			chatstring = gsub (chatstring, " (%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?):(%d%d?%d?%d?%d?)%s?", ReURL_Link("%1.%2.%3.%4:%5"))
			chatstring = gsub (chatstring, " (%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%s?", ReURL_Link("%1.%2.%3.%4"))
			if (extraspace) then
				chatstring = strsub(chatstring, 2);
			end
		end
		return chatstring
	end

	REURL_COLOR = "b4b4b4"
	ReURL_Brackets = false
	ReUR_CustomColor = true

	function ReURL_Link(url)
		if (ReUR_CustomColor) then
			if (ReURL_Brackets) then
				url = " |cff"..REURL_COLOR.."|Hurl:"..url.."|h["..url.."]|h|r "
			else
				url = " |cff"..REURL_COLOR.."|Hurl:"..url.."|h"..url.."|h|r "
			end
		else
			if (ReURL_Brackets) then
				url = " |Hurl:"..url.."|h["..url.."]|h "
			else
				url = " |Hurl:"..url.."|h"..url.."|h "
			end
		end
		return url
	end

	--Hook all the AddMessage funcs
	for i=1, NUM_CHAT_WINDOWS do
		local frame = getglobal("ChatFrame"..i)
		local addmessage = frame.AddMessage
		frame.AddMessage = function(self, text, ...) addmessage(self, ReURL_AddLinkSyntax(text), ...) end
	end
	
	------------------------------------------------------------------------
	--	No more click on item chat link
	------------------------------------------------------------------------
	
	if db.Chat.ShowItemTooltips == true then
		local orig1, orig2 = {}, {}
		local GameTooltip = GameTooltip
		
		local linktypes = {item = true, enchant = true, spell = true, quest = true, unit = true, talent = true, achievement = true, glyph = true}
		
		local function OnHyperlinkEnter(frame, link, ...)
			local linktype = link:match("^([^:]+)")
			if linktype and linktypes[linktype] then
				GameTooltip:SetOwner(frame, "ANCHOR_TOPRIGHT")
				GameTooltip:SetHyperlink(link)
				GameTooltip:Show()
			end
		
			if orig1[frame] then return orig1[frame](frame, link, ...) end
		end
		
		local function OnHyperlinkLeave(frame, ...)
			GameTooltip:Hide()
			if orig2[frame] then return orig2[frame](frame, ...) end
		end
		
		
		local _G = getfenv(0)
		for i=1, NUM_CHAT_WINDOWS do
			local frame = _G["ChatFrame"..i]
			orig1[frame] = frame:GetScript("OnHyperlinkEnter")
			frame:SetScript("OnHyperlinkEnter", OnHyperlinkEnter)
		
			orig2[frame] = frame:GetScript("OnHyperlinkLeave")
			frame:SetScript("OnHyperlinkLeave", OnHyperlinkLeave)
		end
	end
	
	-----------------------------------------------------------------------------
	-- Copy Chat
	-----------------------------------------------------------------------------
	
	local lines = {}
	local frame = nil
	local editBox = nil
	local isf = nil

	local function CreatCopyFrame()
		frame = CreateFrame( "Frame", "CopyFrame", UIParent)
		frame:SetBackdrop({
				bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
				edgeFile = LUI_Media.glowTex, 
				tile = 0, tileSize = 0, edgeSize = 3, 
				insets = { left = 2, right = 2, top = 2, bottom = 2 }
		})
		frame:SetBackdropColor(0,0,0,0.4)
		frame:SetBackdropBorderColor(0,0,0,0.8)
		frame:SetWidth(610)
		frame:SetHeight(200)
		frame:SetScale(1)
		frame:SetPoint("CENTER", UIParent, "CENTER", 0,10)
		frame:Hide()
		frame:SetFrameStrata("DIALOG")
	
		local scrollArea = CreateFrame( "ScrollFrame", "CopyScroll", frame, "UIPanelScrollFrameTemplate")
		scrollArea:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -30)
		scrollArea:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 8)
		
		editBox = CreateFrame( "EditBox", "CopyBox", frame)
		editBox:SetMultiLine(true)
		editBox:SetMaxLetters(99999)
		editBox:EnableMouse(true)
		editBox:SetAutoFocus(false)
		editBox:SetFontObject(ChatFontNormal)
		editBox:SetWidth(610)
		editBox:SetHeight(200)
		editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
	
		scrollArea:SetScrollChild(editBox)
	
		local close = CreateFrame( "Button", "CopyCloseButton", frame, "UIPanelCloseButton")
		close:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
	
		isf = true
	end
	
	local function GetLines(...)
		local ct = 1
		for i = select("#", ...), 1, -1 do
			local region = select(i, ...)
			if region:GetObjectType() == "FontString" then
				lines[ct] = tostring(region:GetText())
				ct = ct + 1
			end
		end
		return ct - 1
	end
	
	local function Copy(cf)
		local _, size = cf:GetFont()
		FCF_SetChatWindowFontSize(cf, cf, 0.01)
		local lineCt = GetLines(cf:GetRegions())
		local text = table.concat(lines, "\n", 1, lineCt)
		FCF_SetChatWindowFontSize(cf, cf, size)
		if not isf then CreatCopyFrame() end
		frame:Show()
		editBox:SetText(text)
		editBox:HighlightText(0)
	end
	
	if db.Chat.Buttons.Copy.Enable == true then
		for i = 1, NUM_CHAT_WINDOWS do
			local cf = _G[format("ChatFrame%d",  i)]
			local button = CreateFrame( "Button", format("ButtonCF%d", i), cf)
			button:SetPoint("BOTTOMRIGHT", tonumber(db.Chat.Buttons.Copy.X), tonumber(db.Chat.Buttons.Copy.Y))
			button:SetHeight(22)
			button:SetWidth(22)
			button:SetAlpha(db.Chat.Buttons.Copy.AlphaOut)
			button:SetNormalTexture(LUI_Media.chatcopy)
			
			button:SetScript("OnClick", function() 
				Copy(cf) 
			end)
			
			button:SetScript("OnEnter", function()
				button:SetPoint("BOTTOMRIGHT", tonumber(db.Chat.Buttons.Copy.X), tonumber(db.Chat.Buttons.Copy.Y))
				button:SetAlpha(db.Chat.Buttons.Copy.AlphaIn) 
			end)
			
			button:SetScript("OnLeave", function()
				button:SetPoint("BOTTOMRIGHT", tonumber(db.Chat.Buttons.Copy.X), tonumber(db.Chat.Buttons.Copy.Y))
				button:SetAlpha(db.Chat.Buttons.Copy.AlphaOut) 
			end)
			
			local tab = _G[format("ChatFrame%dTab", i)]
			
			tab:SetScript("OnShow", function()
				button:SetAlpha(db.Chat.Buttons.Copy.AlphaOut) 
				button:Show() 
			end)
			
			tab:SetScript("OnHide", function()
				button:SetAlpha(db.Chat.Buttons.Copy.AlphaOut)
				button:Hide() 
			end)
		end
	end
	
	------------------------------------------------------------------------
	--	Rewrite Chatframe mousewheel.
	------------------------------------------------------------------------
	
	local normscrollspeed = tonumber(db.Chat.MouseWheel.NormalSpeed)
	local ctrlscrollspeed = tonumber(db.Chat.MouseWheel.CTRLSpeed)
	local function scrollFrame(cf, up)
		if IsShiftKeyDown() then
	        if up then cf:ScrollToTop() else cf:ScrollToBottom() end
		else
		    if IsControlKeyDown() then
		        for i = 1,ctrlscrollspeed do
		            if up then cf:ScrollUp() else cf:ScrollDown() end
		        end
		    else
		        for i = 1,normscrollspeed do
		            if up then cf:ScrollUp() else cf:ScrollDown() end
		        end
		    end
		end
	end
	
	for i = 1, NUM_CHAT_WINDOWS do
		local cf = _G[format("ChatFrame%d",  i)]
		cf:SetScript("OnMouseWheel", function(cf, arg1) scrollFrame(cf, arg1 > 0) end)
	    cf:EnableMouseWheel(true)
	end
end

local defaults = {
	Chat = {
		Enable = true,
		PreventDrag = true,
		Font = "Arial Narrow",
		Size = 14,
		Height = "171",
		Width = "404",
		X = "28",
		Y = "46",
		MouseWheel = {
			NormalSpeed = "3",
			CTRLSpeed = "6",
		},
		Flag = "NONE",
		SecondChatAnchor = "ChatFrame3",
		Justify = "LEFT",
		Justify2 = "LEFT",
		ShortChannelNames = false,
		ShowItemTooltips = true,
		Fading = false,
		SecondChatFrame = false,
		Tabs = {
			NotActiveAlpha = 0,
			ActiveAlpha = 0,
			LockDockedTabs = true,
		},
		Buttons = {
			Enable = false,
			Copy = {
				Enable = true,
				X = "0",
				Y = "-4",
				AlphaIn = 0.6,
				AlphaOut = 0.1,
			},
			Arrows = {
				Enable = false,
				AlphaIn = 1,
				AlphaOut = 0.5,
				X = "0",
				Y = "22",
			},
			BottomButton = {
				Enable = false,
				AlphaIn = 1,
				AlphaOut = 0.5,
				X = "0",
				Y = "-10",
			},
			SocialButton = {
				Enable = false,
				AlphaIn = 1,
				AlphaOut = 0.5,
				X = "-3",
				Y = "210",
			},
			MenuButton = {
				Enable = false,
				AlphaIn = 1,
				AlphaOut = 0.5,
				X = "0",
				Y = "85",
			},
			MinimizeButton = {
				Enable = false,
				AlphaIn = 1,
				AlphaOut = 0.5,
				X = "0",
				Y = "0",
			},
			ResizeButton = {
				Enable = false,
				AlphaIn = 1,
				AlphaOut = 0.5,
				X = "0",
				Y = "0",
			},
		},
		Editbox = {
			Font = "Arial Narrow",
			Size = 14,
			Flag = "NONE",
			ColorByChannel = false,
			Border = {
				Texture = "glow",
				Thickness = "5",
				Inset = {
					left = "4",
					right = "4",
					top = "4",
					bottom = "4",
				},
			},
			Position = {
				Anchor = "TOP",
				X = "0",
				Y = "0",
			}
		},
		Sticky = {
			Enable = true,
			SAY = true,
			EMOTE = true,
			YELL = true,
			OFFICER = true,
			RAID_WARNING = true,
			WHISPER = true,
			BN_WHISPER = true,
			CHANNEL = true,
		},
	},
}

function module:LoadOptions()
	local options = {
		Chat = {
			name = "Chat",
			type = "group",
			disabled = function() return not db.Chat.Enable end,
			childGroups = "tab",
			args = {
				ChatSettings = {
					name = "General",
					type = "group",
					childGroups = "tab",
					order = 2,
					args = {
						Settings = {
							name = "Settings",
							type = "group",
							order = 1,
							args = {
								Enable = {
									name = "Enable",
									desc = "Enable LUI Chat Improvements.\n",
									type = "toggle",
									width = "full",
									get = function() return db.Chat.Enable end,
									set = function()
											db.Chat.Enable = not db.Chat.Enable
											StaticPopup_Show("RELOAD_UI")
										end,
									order = 1,
								},
								ShortChannelNames = {
									name = "Short Channel Names",
									desc = "Whether you want to show short Channelnames or not.\n",
									type = "toggle",
									disabled = function() return not db.Chat.Enable end,
									width = "full",
									get = function() return db.Chat.ShortChannelNames end,
									set = function()
											db.Chat.ShortChannelNames = not db.Chat.ShortChannelNames
										end,
									order = 2,
								},
								ShowItemTooltips = {
									name = "Show Item Tooltips",
									desc = "Whether you want to show Item Tooltips or not.\n",
									type = "toggle",
									disabled = function() return not db.Chat.Enable end,
									width = "full",
									get = function() return db.Chat.ShowItemTooltips end,
									set = function()
											db.Chat.ShowItemTooltips = not db.Chat.ShowItemTooltips
											StaticPopup_Show("RELOAD_UI")
										end,
									order = 3,
								},
								Fading = {
									name = "Enable Chat Fading",
									desc = "Whether you want to enable Fading or not.\n",
									type = "toggle",
									disabled = function() return not db.Chat.Enable end,
									width = "full",
									get = function() return db.Chat.Fading end,
									set = function()
											db.Chat.Fading = not db.Chat.Fading
											SetChatFading()
										end,
									order = 4,
								},
								SecondChatFrameSettings = {
									name = "Second ChatFrame",
									type = "group",
									order = 5,
									inline = true,
									args = {
										SecondChatFrame = {
											name = "Enable",
											desc = "Whether you want to show your second ChatFrame or not.\n",
											type = "toggle",
											disabled = function() return not db.Chat.Enable end,
											width = "full",
											get = function() return db.Chat.SecondChatFrame end,
											set = function(self, SecondChatFrame)
													db.Chat.SecondChatFrame = not db.Chat.SecondChatFrame
													local Panels = LUI:GetModule("Panels")
													Panels:CheckSecondChatFrame()
												end,
											order = 1,
										},
										TextureAnchor = {
											name = "Choose ChatFrame",
											desc = "Choose the Anchor for your Second ChatFrame Texture.\nDefault: "..LUI.defaults.profile.Chat.SecondChatAnchor,
											type = "select",
											values = chatTextureAnchors,
											get = function()
													for k, v in pairs(chatTextureAnchors) do
														if db.Chat.SecondChatAnchor == v then
															return k
														end
													end
												end,
											set = function(self, TextureAnchor)
													db.Chat.SecondChatAnchor = chatTextureAnchors[TextureAnchor]
													local Panels = LUI:GetModule("Panels")
													Panels:SetSecondChatAnchor()
												end,
											order = 2,
										},
										ChatJustify = {
											name = "Choose Alignment",
											desc = "Choose the Alignment for your Second ChatFrame.\nDefault: "..LUI.defaults.profile.Chat.Justify2,
											type = "select",
											values = chatAlignments,
											get = function()
													for k, v in pairs(chatAlignments) do
														if db.Chat.Justify2 == v then
															return k
														end
													end
												end,
											set = function(self, ChatJustify)
													db.Chat.Justify2 = chatAlignments[ChatJustify]
													SetChatJustify()
												end,
											order = 3,
										},
									},
								},
							},
						},
						Font = {
							name = "Font",
							type = "group",
							order = 2,
							disabled = function() return not db.Chat.Enable end,
							args = {
								Font = {
									name = "Font",
									desc = "Choose your Font!\nDefault: "..LUI.defaults.profile.Chat.Font,
									type = "select",
									dialogControl = "LSM30_Font",
									values = widgetLists.font,
									get = function()
											return db.Chat.Font
										end,
									set = function(self, font)
											db.Chat.Font = font
											SetChatFont()
										end,
									order = 1,
								},
								Fontsize = {
									name = "Fontsize",
									desc = "Choose your Fontsize!\nDefault: "..LUI.defaults.profile.Chat.Size,
									type = "range",
									min = 6,
									max = 20,
									step = 1,
									get = function() return db.Chat.Size end,
									set = function(_, Fontsize) 
												db.Chat.Size = Fontsize
												SetChatFont()
											end,
									order = 2,
								},
								FontFlag = {
									name = "Outline",
									desc = "Choose the Font Flag for your Chat.\nDefault: "..LUI.defaults.profile.Chat.Flag,
									type = "select",
									values = fontflags,
									get = function()
											for k, v in pairs(fontflags) do
												if db.Chat.Flag == v then
													return k
												end
											end
										end,
									set = function(self, FontFlag)
											db.Chat.Flag = fontflags[FontFlag]
											SetChatFont()
										end,
									order = 3,
								},
								ChatJustify = {
									name = "Choose Alignment",
									desc = "Choose the Alignment for your ChatFrame.\nDefault: "..LUI.defaults.profile.Chat.Justify,
									type = "select",
									values = chatAlignments,
									get = function()
											for k, v in pairs(chatAlignments) do
												if db.Chat.Justify == v then
													return k
												end
											end
										end,
									set = function(self, ChatJustify)
											db.Chat.Justify = chatAlignments[ChatJustify]
											SetChatJustify()
										end,
									order = 4,
								},
							},
						},
						MouseWheel = {
							name = "Mouse Wheel",
							type = "group",
							disabled = function() return not db.Chat.Enable end,
							order = 3,
							args = {
								desc = {
									name = "Check if MouseWheel is enabled within Blizzard Interface Options -> Social\n\n|cff3399ffExplanation:|r\nSHIFT+ScrollUp = Scroll to the top\nSHIFT+ScrollDown = Scroll to the bottom\nCTRL+Scroll = Use fast Scrollspeed",
									width = "full",
									type = "description",
									order = 1,
								},
								NormalScroll = {
									name = "Normal Scroll Speed",
									desc = "Value for the normal Scroll Speed\nDefault: "..LUI.defaults.profile.Chat.MouseWheel.NormalSpeed,
									type = "input",
									get = function() return db.Chat.MouseWheel.NormalSpeed end,
									set = function(self,NormalScroll)
											if NormalScroll == nil or NormalScroll == "" then
												NormalScroll = "0"
											end
											db.Chat.MouseWheel.NormalSpeed = NormalScroll
										end,
									order = 2,
								},
								empty = {
									name = " ",
									width = "full",
									type = "description",
									order = 3,
								},
								CTRLScroll = {
									name = "CTRL Scroll Speed",
									desc = "Value for the CTRL Scroll Speed\nDefault: "..LUI.defaults.profile.Chat.MouseWheel.CTRLSpeed,
									type = "input",
									get = function() return db.Chat.MouseWheel.CTRLSpeed end,
									set = function(self,CTRLScroll)
											if CTRLScroll == nil or CTRLScroll == "" then
												CTRLScroll = "0"
											end
											db.Chat.MouseWheel.CTRLSpeed = CTRLScroll
										end,
									order = 4,
								},
							},
						},
						ChatDefaults = {
							name = "Defaults",
							type = "group",
							disabled = function() return not db.Chat.Enable end,
							order = 4,
							args = {
								header1 = {
									name = "Size",
									type = "header",
									width = "full",
									order = 1,
								},
								Width = {
									name = "Width",
									desc = "Choose the Width of your ChatFrame1.\nDefault: "..LUI.defaults.profile.Chat.Width,
									type = "input",
									get = function() return db.Chat.Width end,
									set = function(self,Width)
											if Width == nil or Width == "" then
												Width = "0"
											end
											db.Chat.Width = Width
											module:SetChatPosition()
										end,
									order = 2,
								},
								Height = {
									name = "Height",
									desc = "Choose the Height of your ChatFrame1.\nDefault: "..LUI.defaults.profile.Chat.Height,
									type = "input",
									get = function() return db.Chat.Height end,
									set = function(self,Height)
											if Height == nil or Height == "" then
												Height = "0"
											end
											db.Chat.Height = Height
											module:SetChatPosition()
										end,
									order = 3,
								},
								header2 = {
									name = "Position",
									type = "header",
									width = "full",
									order = 4,
								},
								PosX = {
									name = "X Value",
									desc = "X Value for your ChatFrame1.\n\nNote:\nPositive values = right\nNegativ values = left\nDefault: "..LUI.defaults.profile.Chat.X,
									type = "input",
									get = function() return db.Chat.X end,
									set = function(self,PosX)
											if PosX == nil or PosX == "" then
												PosX = "0"
											end
											db.Chat.X = PosX
											module:SetChatPosition()
										end,
									order = 5,
								},
								PosY = {
									name = "Y Value",
									desc = "Y Value for your ChatFrame1.\n\nNote:\nPositive values = up\nNegativ values = down\nDefault: "..LUI.defaults.profile.Chat.Y,
									type = "input",
									get = function() return db.Chat.Y end,
									set = function(self,PosY)
											if PosY == nil or PosY == "" then
												PosY = "0"
											end
											db.Chat.Y = PosY
											module:SetChatPosition()
										end,
									order = 6,
								},
							},
						},
						StickyChannels = {
							name = "Sticky Channels",
							type = "group",
							disabled = function() return not db.Chat.Enable end,
							order = 5,
							args = {
								header = {
									name = "Sticky Channels",
									type = "header",
									width = "full",
									order = 1,
								},
								Enable = {
									name = "Enable Sticky Channels",
									desc = "Wether or sticky channels are enabled or not.",
									type = "toggle",
									width = "full",
									get = function() return db.Chat.Sticky.Enable end,
									set = function(self, Enabled)
											db.Chat.Sticky.Enable = not db.Chat.Sticky.Enable
											for k, v in pairs(channels) do
												ChatTypeInfo[k].sticky = 0
											end
										end,
									order = 2,
								},
								empty = {
									name = " ",
									type = "description",
									width = "full",
									order = 3,
								},
							},
						},
					},
				},
				EditboxSettings = {
					name = "Editbox",
					type = "group",
					childGroups = "tab",
					disabled = function() return not db.Chat.Enable end,
					order = 3,
					args = {
						Settings = {
							name = "Settings",
							type = "group",
							order = 1,
							args = {
								ColorByChannel = {
									name = "Color by Channel",
									desc = "Whether you want to color your Editbox by Channel or not.\n",
									type = "toggle",
									width = "full",
									get = function() return db.Chat.Editbox.ColorByChannel end,
									set = function()
												db.Chat.Editbox.ColorByChannel = not db.Chat.Editbox.ColorByChannel
											end,
									order = 1,
								},
								EditBoxColor = {
									name = "Editbox Color",
									desc = "Choose any Editbox Color.",
									type = "color",
									width = "full",
									hasAlpha = true,
									get = function() return unpack(db.Colors.editbox) end,
									set = function(_,r,g,b,a)
											db.Colors.editbox = {r,g,b,a}
											
											LUIHook:SetEditBoxColor()
										end,
									order = 3,
								},
							},
						},
						Font = {
							name = "Font",
							type = "group",
							order = 2,
							args = {
								Font = {
									name = "Font",
									desc = "Choose your Font!\nDefault: "..LUI.defaults.profile.Chat.Editbox.Font,
									type = "select",
									dialogControl = "LSM30_Font",
									values = widgetLists.font,
									get = function()
											return db.Chat.Editbox.Font
										end,
									set = function(self, font)
											db.Chat.Editbox.Font = font
											SetChatFont()
										end,
									order = 1,
								},
								Fontsize = {
									name = "Fontsize",
									desc = "Choose your Fontsize!\nDefault: "..LUI.defaults.profile.Chat.Editbox.Size,
									type = "range",
									min = 6,
									max = 20,
									step = 1,
									get = function() return db.Chat.Editbox.Size end,
									set = function(_, Fontsize) 
												db.Chat.Editbox.Size = Fontsize
												SetChatFont()
											end,
									order = 2,
								},
								FontFlag = {
									name = "Outline",
									desc = "Choose the Font Flag for your Chat.\nDefault: "..LUI.defaults.profile.Chat.Editbox.Flag,
									type = "select",
									values = fontflags,
									get = function()
											for k, v in pairs(fontflags) do
												if db.Chat.Editbox.Flag == v then
													return k
												end
											end
										end,
									set = function(self, FontFlag)
											db.Chat.Editbox.Flag = fontflags[FontFlag]
											SetChatFont()
										end,
									order = 3,
								},
							},
						},
						Border = {
							name = "Border",
							type = "group",
							order = 3,
							args = {
								BorderTexture = {
									name = "Texture",
									desc = "Choose your Editbox Border Texture!\nDefault: "..LUI.defaults.profile.Chat.Editbox.Border.Texture,
									type = "select",
									dialogControl = "LSM30_Border",
									values = widgetLists.border,
									get = function() return db.Chat.Editbox.Border.Texture end,
									set = function(self, BorderTexture)
											db.Chat.Editbox.Border.Texture = BorderTexture
											SetEditBoxBackdrop()
											LUIHook:SetEditBoxColor()
										end,
									order = 1,
								},
								BorderThickness = {
									name = "Edge Size",
									desc = "Value for your Editbox Border Edge Size.\nDefault: "..LUI.defaults.profile.Chat.Editbox.Border.Thickness,
									type = "input",
									width = "half",
									get = function() return db.Chat.Editbox.Border.Thickness end,
									set = function(self,BorderThickness)
												if BorderThickness == nil or BorderThickness == "" then
													BorderThickness = "0"
												end
												db.Chat.Editbox.Border.Thickness = BorderThickness
												SetEditBoxBackdrop()
												LUIHook:SetEditBoxColor()
											end,
									order = 2,
								},
								empty = {
									name = "   ",
									width = "full",
									type = "description",
									order = 3,
								},
								InsetLeft = {
									name = "Left",
									desc = "Value for the Left Border Inset\nDefault: "..LUI.defaults.profile.Chat.Editbox.Border.Inset.left,
									type = "input",
									width = "half",
									get = function() return db.Chat.Editbox.Border.Inset.left end,
									set = function(self,InsetLeft)
											if InsetLeft == nil or InsetLeft == "" then
												InsetLeft = "0"
											end
											db.Chat.Editbox.Border.Inset.left = InsetLeft
											SetEditBoxBackdrop()
											LUIHook:SetEditBoxColor()
										end,
									order = 4,
								},
								InsetRight = {
									name = "Right",
									desc = "Value for the Right Border Inset\nDefault: "..LUI.defaults.profile.Chat.Editbox.Border.Inset.right,
									type = "input",
									width = "half",
									get = function() return db.Chat.Editbox.Border.Inset.right end,
									set = function(self,InsetRight)
											if InsetRight == nil or InsetRight == "" then
												InsetRight = "0"
											end
											db.Chat.Editbox.Border.Inset.right = InsetRight
											SetEditBoxBackdrop()
											LUIHook:SetEditBoxColor()
										end,
									order = 5,
								},
								InsetTop = {
									name = "Top",
									desc = "Value for the Top Border Inset\nDefault: "..LUI.defaults.profile.Chat.Editbox.Border.Inset.top,
									type = "input",
									width = "half",
									get = function() return db.Chat.Editbox.Border.Inset.top end,
									set = function(self,InsetTop)
											if InsetTop == nil or InsetTop == "" then
												InsetTop = "0"
											end
											db.Chat.Editbox.Border.Inset.top = InsetTop
											SetEditBoxBackdrop()
											LUIHook:SetEditBoxColor()
										end,
									order = 6,
								},
								InsetBottom = {
									name = "Bottom",
									desc = "Value for the Bottom Border Inset\nDefault: "..LUI.defaults.profile.Chat.Editbox.Border.Inset.bottom,
									type = "input",
									width = "half",
									get = function() return db.Chat.Editbox.Border.Inset.bottom end,
									set = function(self,InsetBottom)
											if InsetBottom == nil or InsetBottom == "" then
												InsetBottom = "0"
											end
											db.Chat.Editbox.Border.Inset.bottom = InsetBottom
											SetEditBoxBackdrop()
											LUIHook:SetEditBoxColor()
										end,
									order = 7,
								},
							},
						},
						Position = {
							name = "Position",
							type = "group",
							order = 4,
							args = {
								Anchor = {
									name = "Position",
									desc = "Choose the Position for your Editbox .\nDefault: "..LUI.defaults.profile.Chat.Editbox.Position.Anchor,
									type = "select",
									values = editboxanchors,
									get = function()
											for k, v in pairs(editboxanchors) do
												if db.Chat.Editbox.Position.Anchor == v then
													return k
												end
											end
										end,
									set = function(self, Anchor)
											db.Chat.Editbox.Position.Anchor = editboxanchors[Anchor]
											SetEditBoxPosition()
										end,
									order = 1,
								},
								empty = {
									name = "   ",
									width = "full",
									type = "description",
									order = 2,
								},
								PosX = {
									name = "X Value",
									desc = "X Value for your Editbox.\n\nNote:\nPositive values = right\nNegativ values = left\nDefault: "..LUI.defaults.profile.Chat.Editbox.Position.X,
									type = "input",
									disabled = function()
										if db.Chat.Editbox.Position.Anchor == "INDIVIDUAL" then
											return false
										else
											return true
										end
									end,
									width = "half",
									get = function() return db.Chat.Editbox.Position.X end,
									set = function(self,PosX)
											if PosX == nil or PosX == "" then
												PosX = "0"
											end
											db.Chat.Editbox.Position.X = PosX
											SetEditBoxPosition()
										end,
									order = 3,
								},
								PosY = {
									name = "Y Value",
									desc = "Y Value for your Editbox.\n\nNote:\nPositive values = up\nNegativ values = down\nDefault: "..LUI.defaults.profile.Chat.Editbox.Position.Y,
									type = "input",
									disabled = function()
										if db.Chat.Editbox.Position.Anchor == "INDIVIDUAL" then
											return false
										else
											return true
										end
									end,
									width = "half",
									get = function() return db.Chat.Editbox.Position.Y end,
									set = function(self,PosY)
											if PosY == nil or PosY == "" then
												PosY = "0"
											end
											db.Chat.Editbox.Position.Y = PosY
											SetEditBoxPosition()
										end,
									order = 4,
								},
							},
						},
					},
				},
				ButtonSettings = {
					name = "Buttons",
					type = "group",
					order = 4,
					disabled = function() return not db.Chat.Enable end,
					args = {
						Enable = {
							name = "Enable",
							desc = "Enable Blizzard Chat Buttons.\n",
							type = "toggle",
							width = "full",
							get = function() return db.Chat.Buttons.Enable end,
							set = function(self, Enable)
										db.Chat.Buttons.Enable = not db.Chat.Buttons.Enable
										CheckChatButtons()
										
										if Enable == true then
											db.Chat.Buttons.MenuButton.Enable = true
											db.Chat.Buttons.SocialButton.Enable = true
											CheckChatMenuButton()
											CheckSocialButton()
										else
											db.Chat.Buttons.MenuButton.Enable = false
											db.Chat.Buttons.SocialButton.Enable = false
											CheckChatMenuButton()
											CheckSocialButton()
										end
									end,
							order = 0,
						},
						Arrows = {
							name = "Arrows",
							type = "group",
							order = 1,
							disabled = function() return not db.Chat.Buttons.Enable end,
							args = {
								Enable = {
									name = "Enable",
									desc = "Enable Chat Arrows or not.\n",
									type = "toggle",
									width = "full",
									get = function() return db.Chat.Buttons.Arrows.Enable end,
									set = function()
												db.Chat.Buttons.Arrows.Enable = not db.Chat.Buttons.Arrows.Enable
												CheckChatArrows()
											end,
									order = 1,
								},
								AlphaOut = {
									name = "Alpha Value",
									desc = "Choose any Alpha Value for your Chat Arrows.\nDefault: "..LUI.defaults.profile.Chat.Buttons.Arrows.AlphaOut,
									type = "range",
									disabled = function() return not db.Chat.Buttons.Arrows.Enable end,
									min = 0,
									max = 1,
									step = 0.05,
									get = function() return db.Chat.Buttons.Arrows.AlphaOut end,
									set = function(_, AlphaOut) 
												db.Chat.Buttons.Arrows.AlphaOut = AlphaOut
												CheckChatArrows()
											end,
									order = 2,
								},
								AlphaIn = {
									name = "Alpha Hover Value",
									desc = "Choose any MouseOver Alpha Value for your Chat Arrows.\nDefault: "..LUI.defaults.profile.Chat.Buttons.Arrows.AlphaIn,
									type = "range",
									disabled = function() return not db.Chat.Buttons.Arrows.Enable end,
									min = 0,
									max = 1,
									step = 0.05,
									get = function() return db.Chat.Buttons.Arrows.AlphaIn end,
									set = function(_, AlphaIn) 
												db.Chat.Buttons.Arrows.AlphaIn = AlphaIn
												CheckChatArrows()
											end,
									order = 3,
								},
								PosX = {
									name = "X Value",
									desc = "X Value for your Chat Arrows.\n\nNote:\nPositive values = right\nNegativ values = left\nDefault: "..LUI.defaults.profile.Chat.Buttons.Arrows.X,
									type = "input",
									disabled = function() return not db.Chat.Buttons.Arrows.Enable end,
									width = "half",
									get = function() return db.Chat.Buttons.Arrows.X end,
									set = function(self,PosX)
											if PosX == nil or PosX == "" then
												PosX = "0"
											end
											db.Chat.Buttons.Arrows.X = PosX
											CheckChatArrows()
										end,
									order = 4,
								},
								PosY = {
									name = "Y Value",
									desc = "Y Value for your Chat Arrows.\n\nNote:\nPositive values = up\nNegativ values = down\nDefault: "..LUI.defaults.profile.Chat.Buttons.Arrows.Y,
									type = "input",
									disabled = function() return not db.Chat.Buttons.Arrows.Enable end,
									width = "half",
									get = function() return db.Chat.Buttons.Arrows.Y end,
									set = function(self,PosY)
											if PosY == nil or PosY == "" then
												PosY = "0"
											end
											db.Chat.Buttons.Arrows.Y = PosY
											CheckChatArrows()
										end,
									order = 5,
								},
							},
						},
						BottomButton = {
							name = "Scroll Down Button",
							type = "group",
							order = 2,
							disabled = function() return not db.Chat.Buttons.Enable end,
							args = {
								Enable = {
									name = "Enable",
									desc = "Show Scroll Down Button or not.\n",
									type = "toggle",
									width = "full",
									get = function() return db.Chat.Buttons.BottomButton.Enable end,
									set = function()
												db.Chat.Buttons.BottomButton.Enable = not db.Chat.Buttons.BottomButton.Enable
												CheckChatBottomButton()
											end,
									order = 1,
								},
								AlphaOut = {
									name = "Alpha Value",
									desc = "Choose any Alpha Value for your Scroll Down Button.\nDefault: "..LUI.defaults.profile.Chat.Buttons.BottomButton.AlphaOut,
									type = "range",
									disabled = function() return not db.Chat.Buttons.BottomButton.Enable end,
									min = 0,
									max = 1,
									step = 0.05,
									get = function() return db.Chat.Buttons.BottomButton.AlphaOut end,
									set = function(_, AlphaOut) 
												db.Chat.Buttons.BottomButton.AlphaOut = AlphaOut
												CheckChatBottomButton()
											end,
									order = 2,
								},
								AlphaIn = {
									name = "Alpha Hover Value",
									desc = "Choose any MouseOver Alpha Value for your Scroll Down Button.\nDefault: "..LUI.defaults.profile.Chat.Buttons.BottomButton.AlphaIn,
									type = "range",
									disabled = function() return not db.Chat.Buttons.BottomButton.Enable end,
									min = 0,
									max = 1,
									step = 0.05,
									get = function() return db.Chat.Buttons.BottomButton.AlphaIn end,
									set = function(_, AlphaIn) 
												db.Chat.Buttons.BottomButton.AlphaIn = AlphaIn
												CheckChatBottomButton()
											end,
									order = 3,
								},
								PosX = {
									name = "X Value",
									desc = "X Value for your Scroll Down Button.\n\nNote:\nPositive values = right\nNegativ values = left\nDefault: "..LUI.defaults.profile.Chat.Buttons.BottomButton.X,
									type = "input",
									disabled = function() return not db.Chat.Buttons.BottomButton.Enable end,
									width = "half",
									get = function() return db.Chat.Buttons.BottomButton.X end,
									set = function(self,PosX)
											if PosX == nil or PosX == "" then
												PosX = "0"
											end
											db.Chat.Buttons.BottomButton.X = PosX
											CheckChatBottomButton()
										end,
									order = 4,
								},
								PosY = {
									name = "Y Value",
									desc = "Y Value for your Scroll Down Button.\n\nNote:\nPositive values = up\nNegativ values = down\nDefault: "..LUI.defaults.profile.Chat.Buttons.BottomButton.Y,
									type = "input",
									disabled = function() return not db.Chat.Buttons.BottomButton.Enable end,
									width = "half",
									get = function() return db.Chat.Buttons.BottomButton.Y end,
									set = function(self,PosY)
											if PosY == nil or PosY == "" then
												PosY = "0"
											end
											db.Chat.Buttons.BottomButton.Y = PosY
											CheckChatBottomButton()
										end,
									order = 5,
								},
							},
						},
						MenuButton = {
							name = "Menu Button",
							type = "group",
							order = 3,
							disabled = function() return not db.Chat.Buttons.Enable end,
							args = {
								Enable = {
									name = "Enable",
									desc = "Show Menu Button or not.\n",
									type = "toggle",
									width = "full",
									get = function() return db.Chat.Buttons.MenuButton.Enable end,
									set = function()
												db.Chat.Buttons.MenuButton.Enable = not db.Chat.Buttons.MenuButton.Enable
												CheckChatMenuButton()
											end,
									order = 1,
								},
								AlphaOut = {
									name = "Alpha Value",
									desc = "Choose any Alpha Value for your Menu Button.\nDefault: "..LUI.defaults.profile.Chat.Buttons.MenuButton.AlphaOut,
									type = "range",
									disabled = function() return not db.Chat.Buttons.MenuButton.Enable end,
									min = 0,
									max = 1,
									step = 0.05,
									get = function() return db.Chat.Buttons.MenuButton.AlphaOut end,
									set = function(_, AlphaOut) 
												db.Chat.Buttons.MenuButton.AlphaOut = AlphaOut
												CheckChatMenuButton()
											end,
									order = 2,
								},
								AlphaIn = {
									name = "Alpha Hover Value",
									desc = "Choose any MouseOver Alpha Value for your Menu Button.\nDefault: "..LUI.defaults.profile.Chat.Buttons.MenuButton.AlphaIn,
									type = "range",
									disabled = function() return not db.Chat.Buttons.MenuButton.Enable end,
									min = 0,
									max = 1,
									step = 0.05,
									get = function() return db.Chat.Buttons.MenuButton.AlphaIn end,
									set = function(_, AlphaIn) 
												db.Chat.Buttons.MenuButton.AlphaIn = AlphaIn
												CheckChatMenuButton()
											end,
									order = 3,
								},
								PosX = {
									name = "X Value",
									desc = "X Value for your Menu Button.\n\nNote:\nPositive values = right\nNegativ values = left\nDefault: "..LUI.defaults.profile.Chat.Buttons.MenuButton.X,
									type = "input",
									disabled = function() return not db.Chat.Buttons.MenuButton.Enable end,
									width = "half",
									get = function() return db.Chat.Buttons.MenuButton.X end,
									set = function(self,PosX)
											if PosX == nil or PosX == "" then
												PosX = "0"
											end
											db.Chat.Buttons.MenuButton.X = PosX
											CheckChatMenuButton()
										end,
									order = 4,
								},
								PosY = {
									name = "Y Value",
									desc = "Y Value for your Menu Button.\n\nNote:\nPositive values = up\nNegativ values = down\nDefault: "..LUI.defaults.profile.Chat.Buttons.MenuButton.Y,
									type = "input",
									disabled = function() return not db.Chat.Buttons.MenuButton.Enable end,
									width = "half",
									get = function() return db.Chat.Buttons.MenuButton.Y end,
									set = function(self,PosY)
											if PosY == nil or PosY == "" then
												PosY = "0"
											end
											db.Chat.Buttons.MenuButton.Y = PosY
											CheckChatMenuButton()
										end,
									order = 5,
								},
							},
						},
						MinimizeButton = {
							name = "Minimize Button",
							type = "group",
							order = 3,
							disabled = function() return not db.Chat.Buttons.Enable end,
							args = {
								Enable = {
									name = "Enable",
									desc = "Show Minimize Button or not.\n",
									type = "toggle",
									width = "full",
									get = function() return db.Chat.Buttons.MinimizeButton.Enable end,
									set = function()
												db.Chat.Buttons.MinimizeButton.Enable = not db.Chat.Buttons.MinimizeButton.Enable
												CheckChatMinimizeButton()
											end,
									order = 1,
								},
								AlphaOut = {
									name = "Alpha Value",
									desc = "Choose any Alpha Value for your Minimize Button.\nDefault: "..LUI.defaults.profile.Chat.Buttons.MinimizeButton.AlphaOut,
									type = "range",
									disabled = function() return not db.Chat.Buttons.MinimizeButton.Enable end,
									min = 0,
									max = 1,
									step = 0.05,
									get = function() return db.Chat.Buttons.MinimizeButton.AlphaOut end,
									set = function(_, AlphaOut) 
												db.Chat.Buttons.MinimizeButton.AlphaOut = AlphaOut
												CheckChatMinimizeButton()
											end,
									order = 2,
								},
								AlphaIn = {
									name = "Alpha Hover Value",
									desc = "Choose any MouseOver Alpha Value for your Minimize Button.\nDefault: "..LUI.defaults.profile.Chat.Buttons.MinimizeButton.AlphaIn,
									type = "range",
									disabled = function() return not db.Chat.Buttons.MinimizeButton.Enable end,
									min = 0,
									max = 1,
									step = 0.05,
									get = function() return db.Chat.Buttons.MinimizeButton.AlphaIn end,
									set = function(_, AlphaIn) 
												db.Chat.Buttons.MinimizeButton.AlphaIn = AlphaIn
												CheckChatMinimizeButton()
											end,
									order = 3,
								},
								PosX = {
									name = "X Value",
									desc = "X Value for your Minimize Button.\n\nNote:\nPositive values = right\nNegativ values = left\nDefault: "..LUI.defaults.profile.Chat.Buttons.MinimizeButton.X,
									type = "input",
									disabled = function() return not db.Chat.Buttons.MinimizeButton.Enable end,
									width = "half",
									get = function() return db.Chat.Buttons.MinimizeButton.X end,
									set = function(self,PosX)
											if PosX == nil or PosX == "" then
												PosX = "0"
											end
											db.Chat.Buttons.MinimizeButton.X = PosX
											CheckChatMinimizeButton()
										end,
									order = 4,
								},
								PosY = {
									name = "Y Value",
									desc = "Y Value for your Minimize Button.\n\nNote:\nPositive values = up\nNegativ values = down\nDefault: "..LUI.defaults.profile.Chat.Buttons.MinimizeButton.Y,
									type = "input",
									disabled = function() return not db.Chat.Buttons.MinimizeButton.Enable end,
									width = "half",
									get = function() return db.Chat.Buttons.MinimizeButton.Y end,
									set = function(self,PosY)
											if PosY == nil or PosY == "" then
												PosY = "0"
											end
											db.Chat.Buttons.MinimizeButton.Y = PosY
											CheckChatMinimizeButton()
										end,
									order = 5,
								},
							},
						},
						Social = {
							name = "Social Button",
							type = "group",
							order = 4,
							disabled = function() return not db.Chat.Buttons.Enable end,
							args = {
								Enable = {
									name = "Enable",
									desc = "Enable Social Button or not.\n",
									type = "toggle",
									width = "full",
									get = function() return db.Chat.Buttons.SocialButton.Enable end,
									set = function()
												db.Chat.Buttons.SocialButton.Enable = not db.Chat.Buttons.SocialButton.Enable
												CheckSocialButton()
											end,
									order = 1,
								},
								AlphaOut = {
									name = "Alpha Value",
									desc = "Choose any Alpha Value for your Social Button.\nDefault: "..LUI.defaults.profile.Chat.Buttons.SocialButton.AlphaOut,
									type = "range",
									disabled = function() return not db.Chat.Buttons.SocialButton.Enable end,
									min = 0,
									max = 1,
									step = 0.05,
									get = function() return db.Chat.Buttons.SocialButton.AlphaOut end,
									set = function(_, AlphaOut) 
												db.Chat.Buttons.SocialButton.AlphaOut = AlphaOut
												CheckSocialButton()
											end,
									order = 2,
								},
								AlphaIn = {
									name = "Alpha Hover Value",
									desc = "Choose any MouseOver Alpha Value for your Social Button.\nDefault: "..LUI.defaults.profile.Chat.Buttons.SocialButton.AlphaIn,
									type = "range",
									disabled = function() return not db.Chat.Buttons.SocialButton.Enable end,
									min = 0,
									max = 1,
									step = 0.05,
									get = function() return db.Chat.Buttons.SocialButton.AlphaIn end,
									set = function(_, AlphaIn) 
												db.Chat.Buttons.SocialButton.AlphaIn = AlphaIn
												CheckSocialButton()
											end,
									order = 3,
								},
								PosX = {
									name = "X Value",
									desc = "X Value for your Social Button.\n\nNote:\nPositive values = right\nNegativ values = left\nDefault: "..LUI.defaults.profile.Chat.Buttons.SocialButton.X,
									type = "input",
									disabled = function() return not db.Chat.Buttons.SocialButton.Enable end,
									width = "half",
									get = function() return db.Chat.Buttons.SocialButton.X end,
									set = function(self,PosX)
											if PosX == nil or PosX == "" then
												PosX = "0"
											end
											db.Chat.Buttons.SocialButton.X = PosX
											CheckSocialButton()
										end,
									order = 4,
								},
								PosY = {
									name = "Y Value",
									desc = "Y Value for your Social Button.\n\nNote:\nPositive values = up\nNegativ values = down\nDefault: "..LUI.defaults.profile.Chat.Buttons.SocialButton.Y,
									type = "input",
									disabled = function() return not db.Chat.Buttons.SocialButton.Enable end,
									width = "half",
									get = function() return db.Chat.Buttons.SocialButton.Y end,
									set = function(self,PosY)
											if PosY == nil or PosY == "" then
												PosY = "0"
											end
											db.Chat.Buttons.SocialButton.Y = PosY
											CheckSocialButton()
										end,
									order = 5,
								},
							},
						},
						Copy = {
							name = "Copy Text Button",
							type = "group",
							order = 5,
							args = {
								Enable = {
									name = "Enable",
									desc = "Enable Chat Copy Text Button or not.\n",
									type = "toggle",
									width = "full",
									get = function() return db.Chat.Buttons.Copy.Enable end,
									set = function()
												db.Chat.Buttons.Copy.Enable = not db.Chat.Buttons.Copy.Enable
												StaticPopup_Show("RELOAD_UI")
											end,
									order = 1,
								},
								AlphaOut = {
									name = "Alpha Value",
									desc = "Choose any Alpha Value for your Copy Text Button.\nDefault: "..LUI.defaults.profile.Chat.Buttons.Copy.AlphaOut,
									type = "range",
									disabled = function() return not db.Chat.Buttons.Copy.Enable end,
									min = 0,
									max = 1,
									step = 0.05,
									get = function() return db.Chat.Buttons.Copy.AlphaOut end,
									set = function(_, AlphaOut) 
												db.Chat.Buttons.Copy.AlphaOut = AlphaOut
											end,
									order = 2,
								},
								AlphaIn = {
									name = "Alpha Hover Value",
									desc = "Choose any Alpha Hover Value for your Copy Text Button.\nDefault: "..LUI.defaults.profile.Chat.Buttons.Copy.AlphaIn,
									type = "range",
									disabled = function() return not db.Chat.Buttons.Copy.Enable end,
									min = 0,
									max = 1,
									step = 0.05,
									get = function() return db.Chat.Buttons.Copy.AlphaIn end,
									set = function(_, AlphaIn) 
												db.Chat.Buttons.Copy.AlphaIn = AlphaIn
											end,
									order = 3,
								},
								PosX = {
									name = "X Value",
									desc = "X Value for your Copy Text Button.\n\nNote:\nPositive values = right\nNegativ values = left\nDefault: "..LUI.defaults.profile.Chat.Buttons.Copy.X,
									type = "input",
									disabled = function() return not db.Chat.Buttons.Copy.Enable end,
									width = "half",
									get = function() return db.Chat.Buttons.Copy.X end,
									set = function(self,PosX)
											if PosX == nil or PosX == "" then
												PosX = "0"
											end
											db.Chat.Buttons.Copy.X = PosX
										end,
									order = 4,
								},
								PosY = {
									name = "Y Value",
									desc = "Y Value for your Copy Text Button.\n\nNote:\nPositive values = up\nNegativ values = down\nDefault: "..LUI.defaults.profile.Chat.Buttons.Copy.Y,
									type = "input",
									disabled = function() return not db.Chat.Buttons.Copy.Enable end,
									width = "half",
									get = function() return db.Chat.Buttons.Copy.Y end,
									set = function(self,PosY)
											if PosY == nil or PosY == "" then
												PosY = "0"
											end
											db.Chat.Buttons.Copy.Y = PosY
										end,
									order = 5,
								},
								desc = {
									order = 6,
									width = "full",
									type = "description",
									name = "|cff3399ffImportant:|r\nSettings will change after Mouse-Over.",
								},
							},
						},
					},
				},
				TabSettings = {
					name = "Tabs",
					type = "group",
					order = 5,
					disabled = function() return not db.Chat.Enable end,
					args = {
						LockDockedTabs = {
							name = "Lock Docked Tabs",
							desc = "Do you want to lock Docked Tabs or not.\n",
							type = "toggle",
							width = "full",
							get = function() return db.Chat.Tabs.LockDockedTabs end,
							set = function()
										db.Chat.Tabs.LockDockedTabs = not db.Chat.Tabs.LockDockedTabs
										StaticPopup_Show("RELOAD_UI")
									end,
							order = 1,
						},
						ActiveAlpha = {
							name = "Active Alpha Value",
							desc = "Choose any active Alpha Value for your Tabs.\nDefault: "..LUI.defaults.profile.Chat.Tabs.ActiveAlpha,
							type = "range",
							min = 0,
							max = 1,
							step = 0.05,
							get = function() return db.Chat.Tabs.ActiveAlpha end,
							set = function(_, ActiveAlpha) 
										db.Chat.Tabs.ActiveAlpha = ActiveAlpha
									end,
							order = 2,
						},
						NotActiveAlpha = {
							name = "Non Active Alpha Value",
							desc = "Choose any non active Alpha Value for your Tabs.\nDefault: "..LUI.defaults.profile.Chat.Tabs.NotActiveAlpha,
							type = "range",
							min = 0,
							max = 1,
							step = 0.05,
							get = function() return db.Chat.Tabs.NotActiveAlpha end,
							set = function(_, NotActiveAlpha) 
										db.Chat.Tabs.NotActiveAlpha = NotActiveAlpha
									end,
							order = 3,
						}
					}
				}
			}
		}
	}
	
	local nextOrder = 3
	for k, v in pairs(channels) do
		options.Chat.args.ChatSettings.args.StickyChannels.args[k] = {
			name = v,
			desc = ("Make %s sticky"):format(v),
			type = "toggle",
			get = function() return db.Chat.Sticky[k] end,
			set = function(self, Enabled)
					db.Chat.Sticky[k] = Enabled
					ChatTypeInfo[k].sticky = Enabled and 1 or 0
				end,
			order = nextOrder,
		}
		nextOrder = nextOrder + 1
	end

	return options
end

function module:OnInitialize()
	LUI:MergeDefaults(LUI.db.defaults.profile, defaults)
	LUI:RefreshDefaults()
	LUI:Refresh()
	
	self.db = LUI.db
	db = self.db.profile
	
	LUI:RegisterModule(self)
end

function module:OnEnable()
	self:SetChat()
end

function module:OnDisable()
	LUI:ClearFrames()
end