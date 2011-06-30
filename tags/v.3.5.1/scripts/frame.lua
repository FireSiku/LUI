	local f, fs
	f = CreateFrame("Frame", "LUI_Frame_Identifier", UIParent)
		f:SetWidth(320)
		f:SetHeight(20)
		f:SetPoint("CENTER")
		f:SetFrameStrata("DIALOG")
		f:SetBackdrop({
			bgFile = "Interface\\CHATFRAME\\CHATFRAMEBACKGROUND",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = "true",
			tileSize = 32,
			edgeSize = 5,
			insets = {left = 1, right = 1, top = 1, bottom = 1}
		})
		f:SetBackdropColor(0,0,0,0.6)
		f:SetBackdropBorderColor(0,0,0,1)
		f:EnableMouse(true)
		f:SetMovable(true)
		f:SetClampedToScreen(true)
		f:RegisterForDrag("LeftButton")
		f:SetScript("OnDragStart", f.StartMoving)
		f:SetScript("OnDragStop", f.StopMovingOrSizing)
		f:SetScript("OnUpdate", function()
			if GetMouseFocus() == nil then return end
			
			local name = GetMouseFocus():GetName()
			
			if name == nil then
				LUI_Frame_MouseOverActive:SetText("Not Defined")
				LUI_Frame_MouseOverActiveParent:SetText("Unavailable")
				return
			else
				LUI_Frame_MouseOverActive:SetText(name)
			end
			
			local _, parent = _G[name]:GetPoint()
			
			if parent == nil or parent == " " then
				LUI_Frame_MouseOverActiveParent:SetText("Not Defined")
			else
				LUI_Frame_MouseOverActiveParent:SetText(parent:GetName())
			end
		end)
		tinsert(UISpecialFrames,f:GetName())
	
	--[[ MOUSEOVER INFO ]]
	f = CreateFrame("FRAME", "LUI_Frame_MouseInfo", LUI_Frame_Identifier)
		f:SetHeight(32)
		f:SetWidth(320)
		f:SetPoint("TOPLEFT", LUI_Frame_Identifier, "BOTTOMLEFT", 0, -3)
		f:SetPoint("TOPRIGHT", LUI_Frame_Identifier, "BOTTOMRIGHT", 0 -3)
		f:SetBackdrop({
			bgFile = "Interface\\CHATFRAME\\CHATFRAMEBACKGROUND",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = "true",
			tileSize = 32,
			edgeSize = 5,
			insets = {left = 1, right = 1, top = 1, bottom = 1}
		})
		f:SetBackdropColor(0,0,0,0.6)
		f:SetBackdropBorderColor(0,0,0,1)
	

		b = CreateFrame("Button", "LUI_Frame_CloseButton", LUI_Frame_Identifier)
		b:SetPoint("RIGHT",0,0)
		b:SetText("CLOSE")
		b:SetNormalFontObject("GameFontNormalSmall")
		b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		b:SetWidth(50)
		b:SetHeight(20)
		b:SetBackdrop({
			bgFile = "Interface\\CHATFRAME\\CHATFRAMEBACKGROUND",
			edgeFile = "",
			tile = "false",
			tileSize = 0,
			edgeSize = 0,
			insets = {left = 0, right = 0, top = 0, bottom = 0}
			})
		b:SetBackdropColor(0,0,0,0)
		b:SetScript("OnClick", function(self, click)
			LUI_Frame_Identifier:Hide()
		end)
	
	fs = f:CreateFontString("LUI_Frame_Title")
		fs:SetFontObject("GameFontNormalSmall")
		fs:SetJustifyH("LEFT")
		fs:SetWidth(150)
		fs:SetText("LUI Frame Identifier")
		fs:SetPoint("LEFT", LUI_Frame_Identifier, "LEFT", 5,0)
	
	fs = f:CreateFontString("LUI_Frame_MouseOverText")
		fs:SetFontObject("GameFontGreenSmall")
		fs:SetJustifyH("LEFT")
		fs:SetWidth(66)
		fs:SetText("Mouseover:")
		fs:SetPoint("TOPLEFT", LUI_Frame_MouseInfo, "TOPLEFT", 5,-5)
	
	fs = f:CreateFontString("LUI_Frame_MouseOverParent")
		fs:SetFontObject("GameFontGreenSmall")
		fs:SetJustifyH("LEFT")
		fs:SetWidth(66)
		fs:SetText("Parent:")
		fs:SetPoint("TOPLEFT", LUI_Frame_MouseOverText, "BOTTOMLEFT", 0,-2)
	
	fs = f:CreateFontString("LUI_Frame_MouseOverActive")
		fs:SetFontObject("GameFontNormalSmall")
		fs:SetJustifyH("LEFT")
		fs:SetWidth(200)
		fs:SetText("")
		fs:SetPoint("LEFT", LUI_Frame_MouseOverText, "RIGHT")

	fs = f:CreateFontString("LUI_Frame_MouseOverActiveParent")
		fs:SetFontObject("GameFontNormalSmall")
		fs:SetJustifyH("LEFT")
		fs:SetWidth(200)
		fs:SetText("")
		fs:SetPoint("LEFT", LUI_Frame_MouseOverParent, "RIGHT")