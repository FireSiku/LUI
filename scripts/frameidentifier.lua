local addonname, LUI = ...
local script = LUI:NewScript("FrameIdentifier")

local f = CreateFrame("Frame", "LUI_Frame_Identifier", UIParent)
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
f:SetScript("OnUpdate", function(self)
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
local f2 = CreateFrame("FRAME", "LUI_Frame_MouseInfo", LUI_Frame_Identifier)
f2:SetHeight(32)
f2:SetWidth(320)
f2:SetPoint("TOPLEFT", LUI_Frame_Identifier, "BOTTOMLEFT", 0, -3)
f2:SetPoint("TOPRIGHT", LUI_Frame_Identifier, "BOTTOMRIGHT", 0 -3)
f2:SetBackdrop({
	bgFile = "Interface\\CHATFRAME\\CHATFRAMEBACKGROUND",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = "true",
	tileSize = 32,
	edgeSize = 5,
	insets = {left = 1, right = 1, top = 1, bottom = 1}
})
f2:SetBackdropColor(0,0,0,0.6)
f2:SetBackdropBorderColor(0,0,0,1)

local f3 = CreateFrame("Button", "LUI_Frame_CloseButton", LUI_Frame_Identifier)
f3:SetPoint("RIGHT",0,0)
f3:SetText("CLOSE")
f3:SetNormalFontObject("GameFontNormalSmall")
f3:RegisterForClicks("LeftButtonUp", "RightButtonUp")
f3:SetWidth(50)
f3:SetHeight(20)
f3:SetBackdrop({
	bgFile = "Interface\\CHATFRAME\\CHATFRAMEBACKGROUND",
	edgeFile = "",
	tile = "false",
	tileSize = 0,
	edgeSize = 0,
	insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
f3:SetBackdropColor(0,0,0,0)
f3:SetScript("OnClick", function(self, click)
	LUI_Frame_Identifier:Hide()
end)

local fs = f:CreateFontString("LUI_Frame_Title")
fs:SetFontObject("GameFontNormalSmall")
fs:SetJustifyH("LEFT")
fs:SetWidth(150)
fs:SetText("LUI Frame Identifier")
fs:SetPoint("LEFT", f, "LEFT", 5,0)

local fs2 = f2:CreateFontString("LUI_Frame_MouseOverText")
fs2:SetFontObject("GameFontGreenSmall")
fs2:SetJustifyH("LEFT")
fs2:SetWidth(66)
fs2:SetText("Mouseover:")
fs2:SetPoint("TOPLEFT", f2, "TOPLEFT", 5,-5)

local fs3 = f2:CreateFontString("LUI_Frame_MouseOverParent")
fs3:SetFontObject("GameFontGreenSmall")
fs3:SetJustifyH("LEFT")
fs3:SetWidth(66)
fs3:SetText("Parent:")
fs3:SetPoint("TOPLEFT", fs2, "BOTTOMLEFT", 0,-2)
	
local fs4 = f2:CreateFontString("LUI_Frame_MouseOverActive")
fs4:SetFontObject("GameFontNormalSmall")
fs4:SetJustifyH("LEFT")
fs4:SetWidth(200)
fs4:SetText("")
fs4:SetPoint("LEFT", fs2, "RIGHT")

local fs5 = f2:CreateFontString("LUI_Frame_MouseOverActiveParent")
fs5:SetFontObject("GameFontNormalSmall")
fs5:SetJustifyH("LEFT")
fs5:SetWidth(200)
fs5:SetText("")
fs5:SetPoint("LEFT", fs3, "RIGHT")
