-- credits to JNCL @ Curse.com

-- abbreviations
local CPF = ColorPickerFrame
local CPW = ColorPickerWheel
local CS = ColorSwatch
local OSF = OpacitySliderFrame
-- editboxes
local rEB, gEB, bEB, aEB

local editBoxFocus, r, g, b, a
local function updateEB(...)

	if editBoxFocus then return end

	r = select(1, ...)
	g = select(2, ...)
	b = select(3, ...)
	a = select(4, ...)

	if not r then r, g, b = CPF:GetColorRGB() end
	if not a then a = OSF:GetValue() end

    rEB.text:SetText(("%.2f"):format(r))
    rEB:SetText("")
    gEB.text:SetText(("%.2f"):format(g))
    gEB:SetText("")
    bEB.text:SetText(("%.2f"):format(b))
    bEB:SetText("")
    aEB.text:SetText(("%.2f"):format(1 - a))
    aEB:SetText("")

end

local id
local function updateColour_Alpha(self)

	if not self:GetText() or self:GetText() == "" then return end

	r, g, b = CPF:GetColorRGB()
	a = OSF:GetValue()

	id = self:GetID()

	if id == 1 then
		r = ("%.2f"):format(self:GetNumber()) or 0
	elseif id == 2 then
		g = ("%.2f"):format(self:GetNumber()) or 0
	elseif id == 3 then
		b = ("%.2f"):format(self:GetNumber()) or 0
	else
		a = ("%.2f"):format(1 - self:GetNumber()) or 1
	end

	if id ~= 4 then
		CPF:SetColorRGB(r, g, b)
		CS:SetTexture(r, g, b)
	else
		OSF:SetValue(a)
	end

end

local tmp, cnt, prevEB = {}, 1
local function makeEditBox(ltr)

	tmp = CreateFrame("EditBox", "CPF"..ltr, CPF, "InputBoxTemplate")
	tmp:SetMaxLetters(4)
	tmp:SetAutoFocus(false)
	tmp:SetWidth(34)
	tmp:SetHeight(23)
	tmp:SetID(cnt)
	tmp:SetNumeric(true)
	if cnt == 1 then
		tmp:SetPoint("TOPLEFT", CS, "BOTTOMLEFT", 5, -4)
	else
		tmp:SetPoint("TOP", prevEB, "BOTTOM")
	end
	-- text fields
	tmp.label = tmp:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	tmp.label:SetPoint("RIGHT", tmp, "LEFT", -6, 0)
	tmp.label:SetText(ltr..":")
	tmp.label:SetTextColor(1, 1, 1)
	tmp.text = tmp:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	tmp.text:SetPoint("LEFT", tmp, "LEFT")
	tmp.text:SetTextColor(1, 1, 1)
	-- setup scripts
	tmp:SetScript("OnEscapePressed", function(self)	self:ClearFocus() updateEB() end)
	tmp:SetScript("OnEnterPressed", function(self) self:ClearFocus() updateEB() end)
	tmp:SetScript("OnTextChanged", function(self) updateColour_Alpha(self) end)
	tmp:SetScript("OnEditFocusGained", function() editBoxFocus = true end)
	tmp:SetScript("OnEditFocusLost", function()	editBoxFocus = nil end)

	tmp:Show()
	prevEB = tmp
	cnt = cnt + 1

	return tmp

end

do
	-- hook original scripts
	CPF:HookScript("OnColorSelect", function(self, ...) updateEB(...) end)
	OSF:HookScript("OnValueChanged", function(self, ...) updateEB(nil, nil, nil, self.opacity) end)

	-- Add Buttons and EditBoxes to the original ColorPicker Frame
	tmp = CreateFrame("Button", nil, CPF, "UIPanelButtonTemplate")
	tmp:SetText("Copy")
	tmp:SetWidth("50")
	tmp:SetHeight("20")
	tmp:SetPoint("TOPLEFT", CPF, "TOPLEFT", 8, -2)
	tmp:SetScript("OnClick", function(self)
		local r, g, b = CPF:GetColorRGB()
		local a = CPF.hasOpacity and OSF:GetValue() or 0
		local c3 = _G.CurrentlyCopiedColor
		if not c3 then
			c3 = {}
			_G.CurrentlyCopiedColor = c3
		end
		c3.r, c3.g, c3.b, c3.a = r, g, b, a
	end)
	tmp = CreateFrame("Button", nil, CPF, "UIPanelButtonTemplate")
	tmp:SetText("Paste")
	tmp:SetWidth("50")
	tmp:SetHeight("20")
	tmp:SetPoint("TOPRIGHT", CPF, "TOPRIGHT", -8, -2)
	tmp:SetScript("OnClick", function(self)
		local c3 = _G.CurrentlyCopiedColor
		if c3 then
			CPF:SetColorRGB(c3.r, c3.g, c3.b)
			CS:SetTexture(c3.r, c3.g, c3.b)
			if CPF.hasOpacity then
				OSF:SetValue(c3.a)
			end
		end
	end)

	-- move the Opacity Slider Frame
	OSF:ClearAllPoints()
	OSF:SetPoint("TOPLEFT", CS, "TOPRIGHT", 47, 0)

	-- create the colour edit boxes
	rEB = makeEditBox("R")
	gEB = makeEditBox("G")
	bEB = makeEditBox("B")
	aEB = makeEditBox("A")

	makeEditBox, tmp, cnt, prevEB = nil, nil, nil, nil

	-- hook OpacitySliderFrame Show & Hide methods
	hooksecurefunc(OSF, "Show", function() aEB:Show() end)
	hooksecurefunc(OSF, "Hide", function() aEB:Hide() end)
	-- show alpha EB if Opacity
	if CPF.hasOpacity then aEB:Show() end

	-- update the EB colors
	updateEB()

	-- setup the tab sequence
	rEB:SetScript("OnTabPressed", function(self) gEB:SetFocus() end)
	gEB:SetScript("OnTabPressed", function(self) bEB:SetFocus() end)
	bEB:SetScript("OnTabPressed", function(self) if aEB:IsVisible() then aEB:SetFocus() else rEB:SetFocus() end end)
	aEB:SetScript("OnTabPressed", function(self) rEB:SetFocus() end)

end
