if IsAddOnLoaded("EnhancedColourPicker") then return end

-- if the Debug library is available then use it
if AceLibrary:HasInstance("AceDebug-2.0") then
	EnhCP = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0", "AceDB-2.0", "AceHook-2.1", "AceDebug-2.0")
--[===[@alpha@
	EnhCP:SetDebugging(true)
--@end-alpha@]===]
else
	EnhCP = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0", "AceDB-2.0", "AceHook-2.1")
	function EnhCP:Debug() end
end

-- specify where debug messages go
EnhCP.debugFrame = ChatFrame7

function EnhCP:OnEnable()
--	self:Debug("OnEnable")

	-- Initial setup when starting, reloading or zoning
	self:RegisterEvent("AceEvent_FullyInitialized", "Addon_FullyInitialized")
	
	-- when addon taken out of standby
	if AceLibrary("AceEvent-2.0"):IsFullyInitialized() then
		EnhCP:Addon_FullyInitialized()
	end
	
end

function EnhCP:Addon_FullyInitialized()
--	self:Debug("Addon_FullyInitialized")
	
	-- hook the functions to be used on a change of colour and opacity
	EnhCP:HookScript(ColorPickerFrame, "OnColorSelect", function(...)
--		self:Debug("CPF - OnColorSelect")
		EnhCP.hooks[ColorPickerFrame].OnColorSelect(...)
		local self, arg1, arg2, arg3 = ...;
		EnhCP:UpdateEB(arg1, arg2, arg3, self.opacity)
		end)
		
	EnhCP:HookScript(ColorPickerFrame, "OnShow", function(...)
--		self:Debug("CPF - OnShow")
		EnhCP.hooks[ColorPickerFrame].OnShow(...)
		local self = ...;
		-- show/hide the Alpha Edit box as required
		if self.hasOpacity then 
			EnhCPAlphaBox:Show() 
			EnhCPAlphaBoxLabel:Show() 
			EnhCPAlphaBoxText:Show()
		else
			EnhCPAlphaBox:Hide() 
			EnhCPAlphaBoxLabel:Hide() 
			EnhCPAlphaBoxText:Hide()		
		end
	
		end)
		
	EnhCP:HookScript(OpacitySliderFrame, "OnValueChanged", function(...)
--		self:Debug("OSF - OnValueChanged")
		local self = ...;
		EnhCP.hooks[OpacitySliderFrame].OnValueChanged(...)
		EnhCP:UpdateEB(nil, nil, nil, self.opacity)
		end)
		
	-- Add Buttons and EditBoxes to the original ColorPicker Frame
	local cb = CreateFrame("Button", "EnhCPCopy", ColorPickerFrame, "UIPanelButtonTemplate")
	cb:SetText("Copy")
	cb:SetWidth("75")
	cb:SetHeight("22")
	cb:SetPoint("BOTTOMLEFT", "ColorPickerFrame", "TOPLEFT", 10, -32)
	cb:SetScript("OnClick", function(self) 
		local r, g, b = ColorPickerFrame:GetColorRGB()
		local a
		if ColorPickerFrame.hasOpacity then
			a = OpacitySliderFrame:GetValue()
		else
			a = 1
		end
		local CurrentlyCopiedColor = _G.CurrentlyCopiedColor
		if not CurrentlyCopiedColor then
			CurrentlyCopiedColor = {}
			_G.CurrentlyCopiedColor = CurrentlyCopiedColor
		end
		CurrentlyCopiedColor.r = r
		CurrentlyCopiedColor.g = g
		CurrentlyCopiedColor.b = b
		CurrentlyCopiedColor.a = a
	end)
	
	local pb = CreateFrame("Button", "EnhCPPaste", ColorPickerFrame, "UIPanelButtonTemplate")
	pb:SetText("Paste")
	pb:SetWidth("75")
	pb:SetHeight("22")
	pb:SetPoint("BOTTOMRIGHT", "ColorPickerFrame", "TOPRIGHT", -10, -32)
	pb:SetScript("OnClick", function(self)
		local CurrentlyCopiedColor = _G.CurrentlyCopiedColor
		if CurrentlyCopiedColor then
			ColorPickerFrame:SetColorRGB(CurrentlyCopiedColor.r, CurrentlyCopiedColor.g, CurrentlyCopiedColor.b)
			if ColorPickerFrame.hasOpacity then
				OpacitySliderFrame:SetValue(CurrentlyCopiedColor.a)
			end
			ColorSwatch:SetTexture(CurrentlyCopiedColor.r, CurrentlyCopiedColor.g, CurrentlyCopiedColor.b)
		end 
	end)
		
	-- move the Color Picker Wheel
	ColorPickerWheel:ClearAllPoints()
	ColorPickerWheel:SetPoint("TOPLEFT", 16, -34)
	-- move the Opacity Slider Frame
	OpacitySliderFrame:ClearAllPoints()
	OpacitySliderFrame:SetPoint("TOPLEFT", "ColorSwatch", "TOPRIGHT", 52, -4)
		
	local editBoxes = { "Red", "Green", "Blue", "Alpha" }	
	for i = 1, table.getn(editBoxes) do
	
		local ebn = editBoxes[i]
		local obj = CreateFrame("EditBox", "EnhCP"..ebn.."Box", ColorPickerFrame, "InputBoxTemplate")
		obj:SetFrameStrata("DIALOG")
		obj:SetMaxLetters(4)
		obj:SetAutoFocus(false)
		obj:SetWidth(35)
		obj:SetHeight(25)
		obj:SetID(i)
		if i == 1 then 
			obj:SetPoint("TOPLEFT", 265, -68)
		else
			obj:SetPoint("TOP", "EnhCP"..editBoxes[i - 1].."Box", "BOTTOM", 0, 3)
		end
		obj:SetScript("OnEscapePressed", function(self)	self:ClearFocus() EnhCP:UpdateEB() end)
		obj:SetScript("OnEnterPressed", function(self) self:ClearFocus() EnhCP:UpdateEB() end)
		obj:SetScript("OnTextChanged", function(self) EnhCP:UpdateColour_Alpha(self) end)
		obj:SetScript("OnEditFocusGained", function() EnhCP.editBoxFocus = true end)
		obj:SetScript("OnEditFocusLost", function()	EnhCP.editBoxFocus = nil end)
		local objl = obj:CreateFontString("EnhCP"..ebn.."BoxLabel", "ARTWORK", "GameFontNormal")
		objl:SetPoint("RIGHT", "EnhCP"..ebn.."Box", "LEFT", -38, 0)
		objl:SetText(string.sub(ebn, 1, 1)..":")
		objl:SetTextColor(1, 1, 1)
		local objl = obj:CreateFontString("EnhCP"..ebn.."BoxText", "ARTWORK", "GameFontNormal")
		objl:SetPoint("LEFT", "EnhCP"..ebn.."Box", "LEFT", -38, 0)
		objl:SetTextColor(1, 1, 1)
		
		obj:Show()
	end
	-- define the Tab Pressed Scripts
	EnhCPRedBox:SetScript("OnTabPressed", function(self) EnhCPGreenBox:SetFocus() end)
	EnhCPGreenBox:SetScript("OnTabPressed", function(self) EnhCPBlueBox:SetFocus() end)
	EnhCPBlueBox:SetScript("OnTabPressed", function(self) EnhCPAlphaBox:SetFocus() end)
	EnhCPAlphaBox:SetScript("OnTabPressed", function(self) EnhCPRedBox:SetFocus() end)
	
	if IsAddOnLoaded("Skinner") then EnhCP:skinMe() end
	
end

function EnhCP:UpdateColour_Alpha(self)
--	self:Debug("UpdateColour_Alpha: [%s, %s]", this:GetID(), this:GetText())

	if not self:GetText() or self:GetText() == "" then return end
	
	local r, g, b = ColorPickerFrame:GetColorRGB()
	local a = OpacitySliderFrame:GetValue()

--	self:Debug("UpdateColour_Alpha#2: [%s, %s, %s, %s]", r, g, b, a)

	local id = self:GetID()
	
	if id == 1 then
		r = string.format("%.2f", self:GetNumber())
		if not r then r = 0 end
	elseif id == 2 then
		g = string.format("%.2f", self:GetNumber())
		if not g then g = 0 end
	elseif id == 3 then
		b = string.format("%.2f", self:GetNumber())
		if not b then b = 0 end
	else
		a = string.format("%.2f", 1 - self:GetNumber())
		if not a then a = 0 end
	end

--	self:Debug("UpdateColour_Alpha#3: [%s, %s, %s, %s]", r, g, b, a)

	if id ~= 4 then 
		ColorPickerFrame:SetColorRGB(r, g, b)
		ColorSwatch:SetTexture(r, g, b)
	else
		OpacitySliderFrame:SetValue(a)
	end
	
end

function EnhCP:UpdateEB(r, g, b, a)
--	self:Debug("UpdateEB: [%s, %s, %s, %s]", r, g, b, a)

	if EnhCP.editBoxFocus then return end

	if not r then r, g, b = ColorPickerFrame:GetColorRGB() end
	if not a then a = OpacitySliderFrame:GetValue() end
	
--	self:Debug("UpdateEB#2: [%s, %s, %s, %s]", r, g, b, a)
	
    EnhCPRedBoxText:SetText(string.format("%.2f", r))
    EnhCPGreenBoxText:SetText(string.format("%.2f", g))
    EnhCPBlueBoxText:SetText(string.format("%.2f", b))
    EnhCPAlphaBoxText:SetText(string.format("%.2f", 1 - a))

    EnhCPRedBox:SetText("")
    EnhCPGreenBox:SetText("")
    EnhCPBlueBox:SetText("")
    EnhCPAlphaBox:SetText("")

end

function EnhCP:skinMe()
	-- move buttons & skin EditBoxes if Skinner is present

	if Skinner.db.profile.Colours then 
		Skinner:moveObject(EnhCPCopy, nil, nil, "+", 4)
		Skinner:moveObject(EnhCPPaste, nil, nil, "+", 4)
	end
	
	local xOfs = 10
	Skinner:skinEditBox(EnhCPRedBox, {9, 10})
	Skinner:moveObject(EnhCPRedBox, "-", xOfs, nil, nil)
	Skinner:moveObject(EnhCPRedBoxLabel, "+", xOfs, nil, nil)
	Skinner:moveObject(EnhCPRedBoxText, "+", xOfs, nil, nil)
	Skinner:skinEditBox(EnhCPGreenBox, {9, 10})
	Skinner:moveObject(EnhCPGreenBoxLabel, "+", xOfs, nil, nil)
	Skinner:moveObject(EnhCPGreenBoxText, "+", xOfs, nil, nil)
	Skinner:skinEditBox(EnhCPBlueBox, {9, 10})
	Skinner:moveObject(EnhCPBlueBoxLabel, "+", xOfs, nil, nil)
	Skinner:moveObject(EnhCPBlueBoxText, "+", xOfs, nil, nil)
	Skinner:skinEditBox(EnhCPAlphaBox, {9, 10})
	Skinner:moveObject(EnhCPAlphaBoxLabel, "+", xOfs, nil, nil)
	Skinner:moveObject(EnhCPAlphaBoxText, "+", xOfs, nil, nil)

end