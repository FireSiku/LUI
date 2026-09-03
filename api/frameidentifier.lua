---@class LUIAddon
local LUI = select(2, ...)
local script = LUI:NewScript("FrameIdentifier")

local GetMouseFoci = _G.GetMouseFoci

local Identifier = CreateFrame("Frame", "LUI_Frame_Identifier", UIParent)
Identifier:SetWidth(320)
Identifier:SetHeight(20)
Identifier:SetPoint("CENTER")
Identifier:SetFrameStrata("DIALOG")
LUI:ApplyFrameBackdrop(Identifier, {
	bgFile = "Interface\\CHATFRAME\\CHATFRAMEBACKGROUND",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 32,
	edgeSize = 5,
	insets = {left = 1, right = 1, top = 1, bottom = 1}
})
LUI:SetFrameBackgroundColor(Identifier, 0, 0, 0, 0.6)
LUI:SetFrameBorderColor(Identifier, 0, 0, 0, 1)
Identifier:EnableMouse(true)
Identifier:SetMovable(true)
Identifier:SetClampedToScreen(true)
Identifier:RegisterForDrag("LeftButton")
Identifier:SetScript("OnDragStart", Identifier.StartMoving)
Identifier:SetScript("OnDragStop", Identifier.StopMovingOrSizing)

--[[ MOUSEOVER INFO ]]
local MouseInfo = CreateFrame("FRAME", "LUI_Frame_MouseInfo", Identifier)
MouseInfo:SetHeight(32)
MouseInfo:SetWidth(320)
MouseInfo:SetPoint("TOPLEFT", Identifier, "BOTTOMLEFT", 0, -3)
MouseInfo:SetPoint("TOPRIGHT", Identifier, "BOTTOMRIGHT", 0, -3)
LUI:ApplyFrameBackdrop(MouseInfo, {
	bgFile = "Interface\\CHATFRAME\\CHATFRAMEBACKGROUND",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 32,
	edgeSize = 5,
	insets = {left = 1, right = 1, top = 1, bottom = 1}
})
LUI:SetFrameBackgroundColor(MouseInfo, 0, 0, 0, 0.6)
LUI:SetFrameBorderColor(MouseInfo, 0, 0, 0, 1)

local CloseButton = CreateFrame("Button", "LUI_Frame_CloseButton", Identifier)
CloseButton:SetPoint("RIGHT",0,0)
CloseButton:SetText("CLOSE")
CloseButton:SetNormalFontObject("GameFontNormalSmall")
CloseButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
CloseButton:SetWidth(50)
CloseButton:SetHeight(20)
CloseButton:SetScript("OnClick", function()
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

local function GetObjectDisplayName(object)
	if not object or issecretvalue(object) then return end

	local name = object.GetName and object:GetName()
	if type(name) == "string" and not issecretvalue(name) then
		return name
	end

	-- Anonymous Blizzard frames, including Damage Meter rows, can expose a
	-- region through GetName(). GetDebugName returns a safe textual identifier.
	local debugName = object.GetDebugName and object:GetDebugName(true)
	if type(debugName) == "string" and not issecretvalue(debugName) then
		return debugName
	end
end

Identifier:SetScript("OnUpdate", function()
	local focus = GetMouseFoci()[1]
	if not focus then return end

	local name = GetObjectDisplayName(focus)
	if not name then
		MouseActive:SetText("Not Defined")
		MouseActiveParent:SetText("Unavailable")
		return
	end
	MouseActive:SetText(name)

	local _, parent = focus:GetPoint()
	if not parent or issecretvalue(parent) then
		MouseActiveParent:SetText("Not Defined")
	else
		MouseActiveParent:SetText(GetObjectDisplayName(parent) or "Not Defined")
	end
end)
tinsert(UISpecialFrames,Identifier:GetName())
Identifier:Hide()
