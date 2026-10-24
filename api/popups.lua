-- LUI dialogs have their own frames, callbacks and visible list. Never use
-- StaticPopupTemplate or register these frames in Blizzard's popup pools.
local LUI = select(2, ...)
local definitions, frames, visible = {}, {}, {}
LUI.PopupDialogs = definitions

local GAP, MARGIN = 12, 24
local Layout, Choose

local function Call(callback, ...)
	if not callback then return true end
	local args, count = {...}, select("#", ...)
	return xpcall(function() return callback(unpack(args, 1, count)) end, geterrorhandler())
end

local function IsPublic(value)
	return not issecretvalue(value)
end

local function RemoveVisible(frame)
	for index = #visible, 1, -1 do
		if visible[index] == frame then table.remove(visible, index) end
	end
end

local function ReadBlizzardBounds(bounds)
	-- Read placement only. Repositioning, parenting or registering a Blizzard
	-- dialog here would defeat the separation of the two popup systems.
	local scale = UIParent:GetEffectiveScale()
	local function Read(frame)
		if not IsPublic(frame) or not frame then return end
		local forbidden = frame.IsForbidden and frame:IsForbidden()
		if not IsPublic(forbidden) or forbidden then return end
		local shown = frame:IsShown()
		if not IsPublic(shown) or not shown then return end
		local ok, left, bottom, width, height = pcall(frame.GetRect, frame)
		if not ok then return end
		local scaleOK, frameScale = pcall(frame.GetEffectiveScale, frame)
		if not scaleOK then return end
		if not (IsPublic(left) and IsPublic(bottom) and IsPublic(width) and IsPublic(height)
			and IsPublic(frameScale)) or not left or not bottom or not width or not height or not frameScale then return end
		if width <= 0 or height <= 0 then return end
		local ratio = frameScale / scale
		bounds[#bounds + 1] = {left * ratio, bottom * ratio, (left + width) * ratio, (bottom + height) * ratio}
	end
	if StaticPopup_ForEachShownDialog then
		StaticPopup_ForEachShownDialog(Read)
	else
		for index = 1, 4 do Read(_G["StaticPopup" .. index]) end
		Read(_G.InstanceAbandonPopup)
	end
end

Layout = function()
	if #visible == 0 then return end
	local screenWidth, screenHeight = UIParent:GetSize()
	local bounds = {}
	ReadBlizzardBounds(bounds)
	table.sort(bounds, function(a, b) return a[4] > b[4] end)
	for index, frame in ipairs(visible) do
		local width, height = frame:GetSize()
		local scale = math.min(1, (screenWidth - MARGIN * 2) / width, (screenHeight - MARGIN * 2) / height)
		frame:SetScale(scale)
		width, height = width * scale, height * scale
		local chosenX, chosenY
		for _, x in ipairs({(screenWidth - width) / 2, screenWidth - width - MARGIN, MARGIN}) do
			local top = math.min(screenHeight - 135, screenHeight - MARGIN)
			-- Each collision moves us below one occupied rectangle; the loop is
			-- bounded even when a small screen has no completely free location.
			for _ = 1, #bounds + 1 do
				local nextTop = top
				for _, rect in ipairs(bounds) do
					if x < rect[3] + GAP and x + width > rect[1] - GAP
						and top > rect[2] - GAP and top - height < rect[4] + GAP then
						nextTop = math.min(nextTop, rect[2] - GAP)
					end
				end
				if nextTop == top then break end
				top = nextTop
			end
			if top - height >= MARGIN then chosenX, chosenY = x, top; break end
		end
		chosenX = chosenX or (screenWidth - width) / 2
		chosenY = chosenY or math.max(height + MARGIN, screenHeight - 135)
		frame:ClearAllPoints()
		frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", chosenX / scale, chosenY / scale)
		frame:SetFrameLevel(100 + index * 4)
		bounds[#bounds + 1] = {chosenX, chosenY - height, chosenX + width, chosenY}
	end
end

local function Resize(frame)
	local info = frame.definition
	local buttonWidth, count = info.buttonWidth or 120, 0
	for index, button in ipairs(frame.buttons) do
		local text = info["button" .. index]
		button:SetShown(text ~= nil)
		if text then
			button:SetText(text)
			button:Enable()
			buttonWidth = math.max(buttonWidth, button:GetTextWidth() + 32)
			count = count + 1
		end
	end
	local rowWidth = count * buttonWidth + math.max(0, count - 1) * GAP
	local editWidth = info.editBoxWidth or 350
	local width = math.max(340, rowWidth + MARGIN * 2, info.hasEditBox and editWidth + MARGIN * 2 or 0)
	frame.Text:SetWidth(width - MARGIN * 2)
	local textHeight = math.max(18, frame.Text:GetStringHeight())
	frame.EditBox:SetSize(editWidth, 24)
	frame.EditBox:ClearAllPoints()
	frame.EditBox:SetPoint("TOP", frame, "TOP", 0, -MARGIN - textHeight - 16)
	local height = MARGIN * 2 + textHeight + (info.hasEditBox and 44 or 0) + (count > 0 and 40 or 0)
	frame:SetSize(width, height)
	local offset = -rowWidth / 2
	for index, button in ipairs(frame.buttons) do
		if info["button" .. index] then
			button:SetSize(buttonWidth, 24)
			button:ClearAllPoints()
			button:SetPoint("BOTTOMLEFT", frame, "BOTTOM", offset, MARGIN)
			offset = offset + buttonWidth + GAP
		end
	end
end

Choose = function(frame, index)
	local button = frame.buttons[index]
	if not frame.active or frame.choosing or not button:IsShown() or not button:IsEnabled() then return end
	local info, generation = frame.definition, frame.generation
	local callback = info[index == 1 and "OnAccept" or index == 2 and "OnCancel" or "OnAlt"]
	frame.choosing = true
	local ok, keepOpen = Call(callback, frame, frame.data, "clicked")
	if frame.generation ~= generation then return end
	frame.choosing = nil
	if ok and frame.active and not keepOpen then frame:Hide() end
end

local function CreatePopup(which)
	local frame = CreateFrame("Frame", "LUIPopup_" .. which, UIParent, "BackdropTemplate")
	frame:Hide()
	frame:SetFrameStrata("DIALOG")
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:EnableKeyboard(true)
	frame:SetPropagateKeyboardInput(true)
	frame:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32,
		insets = {left = 11, right = 12, top = 12, bottom = 11}})
	frame.Text = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	frame.Text:SetPoint("TOP", frame, "TOP", 0, -MARGIN)
	frame.Text:SetJustifyH("CENTER")
	frame.Text:SetWordWrap(true)
	frame.EditBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
	frame.EditBox:SetAutoFocus(false)
	frame.EditBox:SetScript("OnEscapePressed", function(editBox)
		if not frame.active then return end
		local callback = frame.definition.EditBoxOnEscapePressed
		if callback then Call(callback, editBox, frame.data)
		elseif frame.definition.hideOnEscape then Choose(frame, 2) end
	end)
	frame.EditBox:SetScript("OnEnterPressed", function(editBox)
		if not frame.active then return end
		local callback = frame.definition.EditBoxOnEnterPressed
		if callback then Call(callback, editBox, frame.data)
		elseif frame.definition.enterClicksFirstButton then Choose(frame, 1) end
	end)
	frame.EditBox.GetOwningDialog = function() return frame end
	frame.GetEditBox = function(self) return self.EditBox end
	frame.buttons = {}
	for index = 1, 3 do
		local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		frame.buttons[index] = button
		frame["GetButton" .. index] = function(self) return self.buttons[index] end
		button:SetScript("OnClick", function() Choose(frame, index) end)
	end
	frame:SetScript("OnKeyDown", function(self, key)
		local top = self.active and visible[#visible] == self and not self.choosing
		local escape = top and key == "ESCAPE" and self.definition.hideOnEscape
		local enter = top and key == "ENTER" and self.definition.enterClicksFirstButton and not self.EditBox:HasFocus()
		self:SetPropagateKeyboardInput(not (escape or enter))
		if escape then
			local generation = self.generation
			self.choosing = true
			Call(self.definition.OnCancel, self, self.data, "clicked")
			if self.generation == generation then self.choosing = nil; self:Hide() end
		elseif enter then Choose(self, 1) end
		-- A callback may reopen this frame. Still consume the current key.
		if escape or enter then self:SetPropagateKeyboardInput(false) end
	end)
	frame:SetScript("OnHide", function(self)
		-- Hiding UIParent must not discard a dialog that is still locally shown.
		if not self.active or self:IsShown() then return end
		local info, data, generation = self.definition, self.data, self.generation
		self.active = nil
		self.EditBox:ClearFocus()
		RemoveVisible(self)
		Layout()
		Call(info.OnHide, self, data)
		if self.generation == generation and not self.active then
			self.data = nil
			self.EditBox:SetText("")
		end
	end)
	frames[which] = frame
	local uiElements = LUI:GetModule("UI Elements", true)
	if uiElements and uiElements.RegisterPopupButton then
		for _, button in ipairs(frame.buttons) do uiElements:RegisterPopupButton(frame, button) end
	end
	return frame
end

function LUI:ShowPopup(which, text1, text2, data)
	local info = assert(definitions[which], "Unknown LUI dialog: " .. tostring(which))
	local frame = frames[which] or CreatePopup(which)
	if frame.active then
		frame:Hide()
		-- An OnHide callback may deliberately open a replacement instance.
		if frame.active then return frame end
	end
	if info.exclusive then
		for index = #visible, 1, -1 do
			local previous = visible[index]
			if previous.definition.exclusive then previous:Hide() end
		end
	end
	frame.generation = (frame.generation or 0) + 1
	local generation = frame.generation
	frame.definition, frame.data, frame.choosing = info, data, nil
	frame.Text:SetFormattedText(info.text, text1, text2)
	frame.EditBox:SetMaxLetters(info.maxLetters or 0)
	frame.EditBox:SetText("")
	frame.EditBox:SetShown(not not info.hasEditBox)
	frame.active = true
	visible[#visible + 1] = frame
	Resize(frame)
	Layout()
	frame:SetPropagateKeyboardInput(true)
	frame:Show()
	frame:Raise()
	local ok = Call(info.OnShow, frame, data)
	if frame.generation == generation and frame.active then
		if not ok then frame:Hide(); return end
		if info.hasEditBox then frame.EditBox:SetFocus() end
		return frame
	end
end

function LUI:HidePopup(which)
	local frame = frames[which]
	if frame and frame.active then frame:Hide() end
end

function LUI:IsPopupButton(parent, button)
	for _, frame in pairs(frames) do
		if frame == parent then
			for _, owned in ipairs(frame.buttons) do if owned == button then return true end end
		end
	end
	return false
end

function LUI:ForEachPopupButton(callback)
	for _, frame in pairs(frames) do
		for _, button in ipairs(frame.buttons) do callback(frame, button) end
	end
end

-- Observe native placement changes, but move only LUI-owned frames.
for _, name in ipairs({"StaticPopup_Show", "StaticPopup_OnHide", "StaticPopupSpecial_Show", "StaticPopupSpecial_Hide",
	"StaticPopup_ResizeShownDialogs"}) do
	if type(_G[name]) == "function" then hooksecurefunc(name, Layout) end
end
local events = CreateFrame("Frame")
events:RegisterEvent("DISPLAY_SIZE_CHANGED")
events:RegisterEvent("UI_SCALE_CHANGED")
events:SetScript("OnEvent", Layout)
