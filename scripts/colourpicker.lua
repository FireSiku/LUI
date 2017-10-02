-- LUI Color Picker based on ColorPickerPlus
local addonname, LUI = ...
local script = LUI:NewScript("ColorPicker", "AceEvent-3.0")

local colorBuffer = {}
local editingText

local function UpdateColor(tbox)
	local r, g, b = ColorPickerFrame:GetColorRGB()
	local id = tbox:GetID()

	if id == 1 then
		r = tonumber(tbox:GetText()) or 0
	elseif id == 2 then
		g = tonumber(tbox:GetText()) or 0
	elseif id == 3 then
		b = tonumber(tbox:GetText()) or 0
	end

	editingText = true
	ColorPickerFrame:SetColorRGB(r, g, b)
	ColorSwatch:SetColorTexture(r, g, b)
	editingText = nil
end

local function UpdateColorTexts()
	local r, g, b = ColorPickerFrame:GetColorRGB()
	ColorPickerBoxR:SetText(string.format("%.2f", r))
	ColorPickerBoxG:SetText(string.format("%.2f", g))
	ColorPickerBoxB:SetText(string.format("%.2f", b))
end

local function UpdateAlpha(tbox)
	local a = tonumber(tbox:GetText()) or 1
	if a > 1 then a = 1 end
	editingText = true
	OpacitySliderFrame:SetValue(1 - a)
	editingText = nil
end

local function UpdateAlphaText()
	local a = 1 - OpacitySliderFrame:GetValue()
	ColorPickerBoxA:SetText(string.format("%.2f", a))
end

function script:PLAYER_ENTERING_WORLD(event)
	self:UnregisterEvent(event)

	ColorPickerFrame:HookScript("OnShow", function(self)
		ColorPickerOldColorSwatch:SetTexture(ColorPickerFrame:GetColorRGB())

		if ColorPickerFrame.hasOpacity then
			ColorPickerBoxA:Show()
			ColorPickerBoxLabelA:Show()
			UpdateAlphaText()
		else
			ColorPickerBoxA:Hide()
			ColorPickerBoxLabelA:Hide()
		end
		UpdateColorTexts()
	end)

	ColorPickerFrame:HookScript("OnColorSelect", function()
		if not editingText then UpdateColorTexts() end
	end)

	OpacitySliderFrame:HookScript("OnValueChanged", function()
		if not editingText then UpdateAlphaText() end
	end)

	ColorPickerFrame:SetHeight(ColorPickerFrame:GetHeight() + 40)

	ColorSwatch:ClearAllPoints()
	ColorSwatch:SetPoint("TOPLEFT", ColorPickerFrame, "TOPLEFT", 230, -45)

	local w, h = ColorSwatch:GetSize()

	local ColorPickerOldColorSwatch = ColorPickerFrame:CreateTexture("ColorPickerOldColorSwatch")
	ColorPickerOldColorSwatch:SetSize(w * .75, h * .75)
	ColorPickerOldColorSwatch:SetColorTexture(0, 0, 0)
	ColorPickerOldColorSwatch:SetDrawLayer("BORDER")
	ColorPickerOldColorSwatch:SetPoint("BOTTOMLEFT", ColorSwatch, "TOPRIGHT", - w / 2, - h / 3)

	local ColorPickerCopyColorSwatch = ColorPickerFrame:CreateTexture("ColorPickerCopyColorSwatch")
	ColorPickerCopyColorSwatch:SetSize(w, h)
	ColorPickerCopyColorSwatch:SetColorTexture(0, 0, 0)
	ColorPickerCopyColorSwatch:Hide()

	local ColorPickerCopy = CreateFrame("Button", "ColorPickerCopy", ColorPickerFrame, "UIPanelButtonTemplate")
	ColorPickerCopy:SetText("Copy")
	ColorPickerCopy:SetWidth(70)
	ColorPickerCopy:SetHeight(20)
	ColorPickerCopy:SetScale(.8)
	ColorPickerCopy:SetPoint("TOPLEFT", ColorSwatch, "BOTTOMLEFT", -15, -5)

	ColorPickerCopy:SetScript("OnClick", function()
		colorBuffer.r, colorBuffer.g, colorBuffer.b = ColorPickerFrame:GetColorRGB()

		ColorPickerPaste:Enable()
		ColorPickerCopyColorSwatch:SetColorTexture(colorBuffer.r, colorBuffer.g, colorBuffer.b)
		ColorPickerCopyColorSwatch:Show()

		colorBuffer.a = ColorPickerFrame.hasOpacity and OpacitySliderFrame:GetValue() or nil
	end)

	local ColorPickerPaste = CreateFrame("Button", "ColorPickerPaste", ColorPickerFrame, "UIPanelButtonTemplate")
	ColorPickerPaste:SetText("Paste")
	ColorPickerPaste:SetWidth(70)
	ColorPickerPaste:SetHeight(22)
	ColorPickerPaste:SetScale(.8)
	ColorPickerPaste:SetPoint("TOPLEFT", ColorPickerCopy, "BOTTOMLEFT", 0, -7)
	ColorPickerPaste:Disable()

	ColorPickerPaste:SetScript("OnClick", function()
		ColorPickerFrame:SetColorRGB(colorBuffer.r, colorBuffer.g, colorBuffer.b)
		ColorSwatch:SetColorTexture(colorBuffer.r, colorBuffer.g, colorBuffer.b)
		if ColorPickerFrame.hasOpacity and colorBuffer.a then
			OpacitySliderFrame:SetValue(colorBuffer.a)
		end
	end)

	ColorPickerCopyColorSwatch:SetPoint("LEFT", ColorSwatch, "LEFT")
	ColorPickerCopyColorSwatch:SetPoint("TOP", ColorPickerPaste, "BOTTOM", 0, -5)

	OpacitySliderFrame:ClearAllPoints()
	OpacitySliderFrame:SetPoint("BOTTOM", ColorPickerCopyColorSwatch, "BOTTOM", 0, 10)
	OpacitySliderFrame:SetPoint("RIGHT", ColorPickerFrame, "RIGHT", -35, 13)

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
			box:SetScript("OnEscapePressed", function(self) self:ClearFocus() UpdateAlphaText() end)
			box:SetScript("OnEnterPressed", function(self) self:ClearFocus() UpdateAlphaText() end)
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

	ColorPickerBoxB:SetPoint("TOP", ColorPickerPaste, "BOTTOM", 0, -45)
	ColorPickerBoxG:SetPoint("RIGHT", ColorPickerBoxB, "LEFT", -25, 0)
	ColorPickerBoxR:SetPoint("RIGHT", ColorPickerBoxG, "LEFT", -25, 0)
	ColorPickerBoxA:SetPoint("LEFT", ColorPickerBoxB, "RIGHT", 25, 0)

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
