-- LUI Color Picker based on ColorPickerPlus

---@class LUIAddon
local LUI = select(2, ...)

local script = LUI:NewScript("ColorPicker", "AceEvent-3.0")

local EXTRA_HEIGHT = 25
local TEXT_FRAME_OFFSET = 25

local colorBuffer = {}
local editingText

local ColorPickerFrame = ColorPickerFrame --[[ @as ColorPickerFrameMixin ]]

local function UpdateColor(tbox)
	local r, g, b = ColorPickerFrame.Content.ColorPicker:GetColorRGB()
	local id = tbox:GetID()

	if id == 1 then
		r = tonumber(tbox:GetText()) or 0
	elseif id == 2 then
		g = tonumber(tbox:GetText()) or 0
	elseif id == 3 then
		b = tonumber(tbox:GetText()) or 0
	end

	editingText = true
	ColorPickerFrame.Content.ColorPicker:SetColorRGB(r, g, b)
	-- ColorSwatch:SetColorTexture(r, g, b)
	editingText = nil
end

local function UpdateColorTexts(r, g, b)
	if not r then return end
	ColorPickerBoxR:SetText(string.format("%.2f", r))
	ColorPickerBoxG:SetText(string.format("%.2f", g))
	ColorPickerBoxB:SetText(string.format("%.2f", b))

	-- Note: When alpha slider is update, OnColorSelect is called with just one argument, so it's more clear to pull it directly.
	local a = ColorPickerFrame:GetColorAlpha()
	ColorPickerBoxA:SetText(string.format("%.2f", a))
end

local function UpdateAlpha(tbox)
	local a = tonumber(tbox:GetText()) or 1
	if a > 1 then a = 1 end
	editingText = true
	ColorPickerFrame.Content.ColorPicker:SetColorAlpha(a)
	editingText = nil
end

function script:PLAYER_ENTERING_WORLD(event)
	self:UnregisterEvent(event)
	local colorPicker = ColorPickerFrame.Content.ColorPicker

	ColorPickerFrame:HookScript("OnShow", function(self)
		-- ColorPickerOldColorSwatch:SetTexture(ColorPickerFrame:GetColorRGB())

		if ColorPickerFrame.hasOpacity then
			ColorPickerBoxA:Show()
			ColorPickerBoxLabelA:Show()
		else
			ColorPickerBoxA:Hide()
			ColorPickerBoxLabelA:Hide()
		end
		UpdateColorTexts()
	end)

	colorPicker:HookScript("OnColorSelect", function(colorPicker, r, g, b)
		if not editingText then UpdateColorTexts(r, g, b) end
	end)

	ColorPickerFrame:SetHeight(ColorPickerFrame:GetHeight() + EXTRA_HEIGHT)
	-- Get Hexbox Anchor points and adjust it
	local a1, p, a2, x, y = ColorPickerFrame.Content.HexBox:GetPoint()
	ColorPickerFrame.Content.HexBox:SetPoint(a1, p, a2, x, y + EXTRA_HEIGHT)

	local boxes = {"R", "G", "B", "A"}
	for i = 1, #boxes do
		local box = CreateFrame("EditBox", "ColorPickerBox"..boxes[i], ColorPickerFrame, "InputBoxTemplate")
		box:SetID(i)
		box:SetFrameStrata("DIALOG")
		box:SetHeight(24)
		box:SetWidth(56)

		box:SetAutoFocus(false)
		box:SetTextInsets(0, 5, 0, 0)
		box:SetJustifyH("RIGHT")
		box:SetMaxLetters(4)

		local label = box:CreateFontString("ColorPickerBoxLabel"..boxes[i], "ARTWORK", "GameFontNormalSmall")
		label:SetTextColor(1, 1, 1)
		label:SetPoint("RIGHT", box, "LEFT", -5, 0)
		label:SetText(boxes[i])

		if i == 4 then
			box:SetScript("OnEscapePressed", function(self) self:ClearFocus() UpdateColorTexts() end)
			box:SetScript("OnEnterPressed", function(self) self:ClearFocus() UpdateColorTexts() end)
			box:SetScript("OnTextChanged", function(self) UpdateAlpha(self) end)
		else
			box:SetScript("OnEscapePressed", function(self) self:ClearFocus() UpdateColorTexts() end)
			box:SetScript("OnEnterPressed", function(self) self:ClearFocus() UpdateColorTexts() end)
			box:SetScript("OnTextChanged", function(self) UpdateColor(self) end)
		end

		box:SetScript("OnEditFocusGained", function(self) self:SetCursorPosition(0) self:HighlightText() end)
		box:SetScript("OnEditFocusLost", function(self) self:HighlightText(0, 0) end)
		box:SetScript("OnTextSet", function(self) self:ClearFocus() end)

		box:Show()
	end

	ColorPickerBoxR:SetPoint("TOPLEFT", colorPicker, "BOTTOMLEFT", TEXT_FRAME_OFFSET, 0)
	ColorPickerBoxG:SetPoint("LEFT", ColorPickerBoxR, "RIGHT", TEXT_FRAME_OFFSET, 0)
	ColorPickerBoxB:SetPoint("LEFT", ColorPickerBoxG, "RIGHT", TEXT_FRAME_OFFSET, 0)
	ColorPickerBoxA:SetPoint("LEFT", ColorPickerBoxB, "RIGHT", TEXT_FRAME_OFFSET, 0)

	ColorPickerBoxR:SetScript("OnTabPressed", function(self) ColorPickerBoxG:SetFocus() end)
	ColorPickerBoxG:SetScript("OnTabPressed", function(self) ColorPickerBoxB:SetFocus()  end)
	ColorPickerBoxB:SetScript("OnTabPressed", function(self) ColorPickerBoxA:SetFocus()  end)
	ColorPickerBoxA:SetScript("OnTabPressed", function(self) ColorPickerBoxR:SetFocus()  end)

	local mover = CreateFrame("Frame", nil, ColorPickerFrame)
	mover:SetPoint("TOPLEFT", ColorPickerFrame, "TOP", -60, 0)
	mover:SetPoint("BOTTOMRIGHT", ColorPickerFrame, "TOP", 60, -15)
	mover:EnableMouse(true)
	mover:SetScript("OnMouseDown", function() ColorPickerFrame:StartMoving() end)
	mover:SetScript("OnMouseUp", function() ColorPickerFrame:StopMovingOrSizing() end)
	ColorPickerFrame:SetUserPlaced(true)
	ColorPickerFrame:EnableKeyboard(false)
end

script:RegisterEvent("PLAYER_ENTERING_WORLD")
