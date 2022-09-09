local addonname, LUI = ...
local script = LUI:NewScript("FrameIdentifier")

local GetMouseFocus = _G.GetMouseFocus

local Identifier = CreateFrame("Frame", "LUI_Frame_Identifier", UIParent, "BackdropTemplate")
Identifier:SetWidth(320)
Identifier:SetHeight(20)
Identifier:SetPoint("CENTER")
Identifier:SetFrameStrata("DIALOG")
Identifier:SetBackdrop({
	bgFile = "Interface\\CHATFRAME\\CHATFRAMEBACKGROUND",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = "true",
	tileSize = 32,
	edgeSize = 5,
	insets = {left = 1, right = 1, top = 1, bottom = 1}
})
Identifier:SetBackdropColor(0,0,0,0.6)
Identifier:SetBackdropBorderColor(0,0,0,1)
Identifier:EnableMouse(true)
Identifier:SetMovable(true)
Identifier:SetClampedToScreen(true)
Identifier:RegisterForDrag("LeftButton")
Identifier:SetScript("OnDragStart", Identifier.StartMoving)
Identifier:SetScript("OnDragStop", Identifier.StopMovingOrSizing)

--[[ MOUSEOVER INFO ]]
local MouseInfo = CreateFrame("FRAME", "LUI_Frame_MouseInfo", Identifier, "BackdropTemplate")
MouseInfo:SetHeight(32)
MouseInfo:SetWidth(320)
MouseInfo:SetPoint("TOPLEFT", Identifier, "BOTTOMLEFT", 0, -3)
MouseInfo:SetPoint("TOPRIGHT", Identifier, "BOTTOMRIGHT", 0 -3)
MouseInfo:SetBackdrop({
	bgFile = "Interface\\CHATFRAME\\CHATFRAMEBACKGROUND",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = "true",
	tileSize = 32,
	edgeSize = 5,
	insets = {left = 1, right = 1, top = 1, bottom = 1}
})
MouseInfo:SetBackdropColor(0,0,0,0.6)
MouseInfo:SetBackdropBorderColor(0,0,0,1)

local CloseButton = CreateFrame("Button", "LUI_Frame_CloseButton", Identifier, "BackdropTemplate")
CloseButton:SetPoint("RIGHT",0,0)
CloseButton:SetText("CLOSE")
CloseButton:SetNormalFontObject("GameFontNormalSmall")
CloseButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
CloseButton:SetWidth(50)
CloseButton:SetHeight(20)
CloseButton:SetBackdrop({
	bgFile = "Interface\\CHATFRAME\\CHATFRAMEBACKGROUND",
	edgeFile = "",
	tile = "false",
	tileSize = 0,
	edgeSize = 0,
	insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
CloseButton:SetBackdropColor(0,0,0,0)
CloseButton:SetScript("OnClick", function(self, click)
	Identifier:Hide()
end)

local Title = Identifier:CreateFontString("LUI_Frame_Title")
Title:SetFontObject("GameFontNormalSmall")
Title:SetJustifyH("LEFT")
Title:SetWidth(150)
Title:SetText("LUI Frame Identifier")
Title:SetPoint("LEFT", Identifier, "LEFT", 5,0)
Identifier.title = Title

local MouseText = MouseInfo:CreateFontString("LUI_Frame_MouseOverText")
MouseText:SetFontObject("GameFontGreenSmall")
MouseText:SetJustifyH("LEFT")
MouseText:SetWidth(66)
MouseText:SetText("Mouseover:")
MouseText:SetPoint("TOPLEFT", MouseInfo, "TOPLEFT", 5,-5)
MouseInfo.text = MouseText

local MouseParent = MouseInfo:CreateFontString("LUI_Frame_MouseOverParent")
MouseParent:SetFontObject("GameFontGreenSmall")
MouseParent:SetJustifyH("LEFT")
MouseParent:SetWidth(66)
MouseParent:SetText("Parent:")
MouseParent:SetPoint("TOPLEFT", Title, "BOTTOMLEFT", 0,-2)
MouseInfo.parentText = MouseParent

local MouseActive = MouseInfo:CreateFontString("LUI_Frame_MouseOverActive")
MouseActive:SetFontObject("GameFontNormalSmall")
MouseActive:SetJustifyH("LEFT")
MouseActive:SetWidth(200)
MouseActive:SetText("")
MouseActive:SetPoint("LEFT", MouseText, "RIGHT")
MouseInfo.activeText = MouseActive

local MouseActiveParent = MouseInfo:CreateFontString("LUI_Frame_MouseOverActiveParent")
MouseActiveParent:SetFontObject("GameFontNormalSmall")
MouseActiveParent:SetJustifyH("LEFT")
MouseActiveParent:SetWidth(200)
MouseActiveParent:SetText("")
MouseActiveParent:SetPoint("LEFT", MouseParent, "RIGHT")
MouseInfo.activeParentText = MouseActiveParent

Identifier:SetScript("OnUpdate", function(self)
	if GetMouseFocus() == nil then return end
	
	local name = GetMouseFocus():GetName()
	
	if name == nil then
		MouseActive:SetText("Not Defined")
		MouseActiveParent:SetText("Unavailable")
		return
	else
		MouseActive:SetText(name)
	end
	
	local _, parent = _G[name]:GetPoint()
	
	if parent == nil or parent == " " then
		MouseActiveParent:SetText("Not Defined")
	else
		MouseActiveParent:SetText(parent:GetName())
	end
end)
tinsert(UISpecialFrames,Identifier:GetName())