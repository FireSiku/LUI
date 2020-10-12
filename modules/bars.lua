--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: bars.lua
	Description: Bars Module
]] 

local addonname, LUI = ...
local module = LUI:Module("Bars", "AceHook-3.0", "AceEvent-3.0")
local Themes = LUI:Module("Themes")
local Masque = LibStub("Masque", true)
local Media = LibStub("LibSharedMedia-3.0")
local LibKeyBound = LibStub("LibKeyBound-1.0")
local widgetLists = AceGUIWidgetLSMlists

local L = LUI.L
local db, dbd

LUI.Versions.bars = 2.4

local _, class = UnitClass("player")

local buttonlist = {}
local bars = {}
local sidebars = {}

local isBarAddOnLoaded

local barAnchors = {
	"BT4Bar1",
	"BT4Bar2",
	"BT4Bar3",
	"BT4Bar4",
	"BT4Bar5",
	"BT4Bar6",
	"BT4Bar7",
	"BT4Bar8",
	"BT4Bar9",
	"BT4Bar10",
	"Dominos Bar1",
	"Dominos Bar2",
	"Dominos Bar3",
	"Dominos Bar4",
	"Dominos Bar5",
	"Dominos Bar6",
	"Dominos Bar7",
	"Dominos Bar8",
	"Dominos Bar9",
	"Dominos Bar10",
}
local statelist = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"}
local pointList = {"CENTER", "TOP", "BOTTOM", "LEFT", "RIGHT", "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT"}

local statetext = {"Default"}

local defaultstate = {
	Bottombar1 = {"1"},
	Bottombar2 = {"2"},
	Bottombar3 = {"3"},
	Bottombar4 = {"4"},
	Bottombar5 = {"5"},
	Bottombar6 = {"6"},
	SidebarLeft1 = {"9"},
	SidebarLeft2 = {"7"},
	SidebarRight1 = {"10"},
	SidebarRight2 = {"8"},
}

do
	if class == "DRUID" then
		statetext = {"Default", "Bear Form", "Cat Form", "Cat Form (Prowl)", "Moonkin Form"}
		defaultstate.Bottombar1 = {"1", "9", "7", "7", "1"}
	elseif class == "ROGUE" then
		statetext = {"Default", "Stealth"}
		defaultstate.Bottombar1 = {"1", "7"}
	end
end

local Page = {
	["DRUID"] = {
		"[bonusbar:3] %s; ", -- Bear Form
		"[bonusbar:1,nostealth] %s; ", -- Cat Form
		"[bonusbar:1,stealth] %s; ", -- Cat Form (prowling)
		"[bonusbar:4] %s; ", -- Moonkin Form
	},
	["ROGUE"] = {
		"[bonusbar:1] %s; ", -- Stealth
	},
}

local toggleDummyBar
do
	local function playerRegenDisabled(bar, event)
		module:UnregisterEvent(event)

		toggleDummyBar(bar, false)
		LUI:Print("Dummy "..bar:GetName().." hidden due to combat.")
	end

	toggleDummyBar = function(bar, show)
		if show == nil then
			show = not bar:IsShown()
		end

		local parent = bar:GetParent()

		if show then
			parent:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"})
			bar.button:Show()
			bar:Show()
			bar.outro:Stop()
			bar.intro:Play()

			module:RegisterEvent("PLAYER_REGEN_DISABLED", playerRegenDisabled, bar)
		else
			parent:SetBackdrop({})
			bar.intro:Stop()
			bar:Hide()
		end
	end
end

local last = "HIDEGRID"
local function HookGrid(self, event)
	if event == "ACTIONBAR_SHOWGRID" then
		for i, button in pairs(self.buttons) do
			button:SetAlpha(1)
		end
		last = "SHOWGRID"
	elseif event == "ACTIONBAR_HIDEGRID" then
		for i, button in pairs(self.buttons) do
			if self.HideEmpty and not HasAction(button.action) then
				button:SetAlpha(0)
			end
		end
		last = "HIDEGRID"
	else
		for i, button in pairs(self.buttons) do
			if self.HideEmpty and not HasAction(button.action) and last == "HIDEGRID" then
				button:SetAlpha(0)
			else
				button:SetAlpha(1)
			end
		end
	end
end

local function LoadStates(data)
	if type(data) ~= "table" then return end
	for k, v in pairs(data) do
		db[k].State = {unpack(v)}
		if k:find("Bottombar") then
			db[k].State.Alt = v[1]
			db[k].State.Ctrl = v[1]
		end
	end

	db.StatesLoaded = true
end

local function GetAnchor(anchor)
	if string.find(anchor, "Dominos") then
		if IsAddOnLoaded("Dominos") then
			return Dominos.ActionBar:Get(string.match(anchor, "%d+"))
		end
	else
		return _G[anchor]
	end
end

local function GetAdditionalAnchors(str)
	str = string.gsub(str, " ", "")
	local t = {}
	local fname
	while true do
		if not string.find(str, ",") then break end
		fname, str = strsplit(",", str, 2)
		table.insert(t, fname)
	end
	return t
end

local function SidebarSetAlpha(anchor, alpha)
	anchor = GetAnchor(anchor)
	if anchor then anchor:SetAlpha(alpha) end
end

local function SidebarSetAnchor(side, id)
	local sideID = side..id
	local bardb = db["Sidebar"..sideID]
	local sb = sidebars[sideID].Anchor

	if not bardb.Enable then
		sb:Hide()
		return
	end

	sb:ClearAllPoints()
	sb:SetPoint(side, UIParent, side, NegateIf(-11, side == "Right"), bardb.Offset)
	sb:SetScale(1 / 0.85 * bardb.Scale)
	sb:Show()

	if not bardb.AutoPosEnable and isBarAddOnLoaded then return end

	local anchorName = isBarAddOnLoaded and bardb.Anchor or "LUIBar"..sideID
	sidebars[sideID].Main = anchorName

	local xOffset = tonumber(bardb.X)
	local yOffset = tonumber(bardb.Y)
	local sbOffset = tonumber(bardb.Offset)

	local anchor = GetAnchor(anchorName)

	if not anchor then return end
	if not anchor:IsShown() then return end

	if not isBarAddOnLoaded then 
		anchor:SetScale(bardb.Scale)
	end

	local scale = anchor:GetEffectiveScale()
	local scaleUI = UIParent:GetEffectiveScale()

	local x = LUI:Scale(xOffset - LUI:Scale(5))
	local y = LUI:Scale(yOffset - LUI:Scale(16))

	-- local x = xOffset + ( scaleUI * math.floor( (side == "Right" and -90 or 20) / scale ) / 0.85 * bardb.Scale)
	-- local y = yOffset + ( scaleUI * math.floor( 157 + sbOffset / scale / 0.85 * bardb.Scale ) )

	local barAnchor = select(5, sb:GetChildren())
	anchor:SetFrameStrata("BACKGROUND")
	anchor:SetFrameLevel(2)
	anchor:ClearAllPoints()
	anchor:SetPoint("TOP", barAnchor, "TOP", x, y)
end

local function ToggleBar(bar, condition)
	if condition then
		bar:Show()
	else
		bar:Hide()
	end
end

local function Configure(bar, numButtons, numPerRow)
	if bar then
		local numRows = math.ceil(numButtons / numPerRow)
		bar:SetWidth(numPerRow * 36 + (numPerRow - 1) * 2)
		bar:SetHeight(numRows * 36 + (numRows - 1) * 2)
	end

	local buttons = bar.buttons
	for i = 1, #buttons do
		if i ~= 1 then
			buttons[i]:ClearAllPoints()
			if (i - 1) % numPerRow == 0 then
				buttons[i]:SetPoint("TOPLEFT", buttons[i-numPerRow], "BOTTOMLEFT", 0, -2)
			else
				buttons[i]:SetPoint("TOPLEFT", buttons[i-1], "TOPRIGHT", 2, 0)
			end
		end

		if buttons[i].__IAB then
			if i > numButtons then
				buttons[i]:SetAttribute("statehidden", 1)
				buttons[i]:Hide()
			else
				buttons[i]:SetAttribute("statehidden", nil)
				buttons[i]:Show()
				if LUI.PTR then
					buttons[i]:Update()
				else
					ActionButton_Update(buttons[i])
				end
			end
		end
	end
end

local function GetBarState(id)
	local bardb = db["Bottombar"..id]
	local condition = id == 1 and "[bonusbar:5] 11; " or ""

	if bardb.State.Alt ~= bardb.State[1] then
		condition = condition.."[mod:alt] "..bardb.State.Alt.."; "
	end

	if bardb.State.Ctrl ~= bardb.State[1] then
		condition = condition.."[mod:ctrl] "..bardb.State.Ctrl.."; "
	end

	if id == 1 and Page[class] then
		for num, word in pairs(Page[class]) do
			condition = condition..word:format(bardb.State[num+1])
		end
	end
	condition = condition..bardb.State[1]

	return condition
end

local function CreateButton(bar, barid, barpos, buttonid)
	local button = CreateFrame("CheckButton", format("LUIBar%s%sButton%s", barpos, barid, buttonid), bar, "ActionBarButtonTemplate")
	button:SetID(buttonid)

	module:HookActionButton(button)
	return button
end

local function CreateBackdrop(frame, bgSuffix)
	frame:SetBackdrop({
		bgFile = "Interface\\AddOns\\LUI\\media\\templates\\v3\\"..bgSuffix,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	frame:SetBackdropBorderColor(0, 0, 0, 0)
end

local function UpdateUIPanelOffset(isLeft)
	if not db.General.AdjustUIPanels then
		UIParent:SetAttribute("LEFT_OFFSET", 16)
	end

	if isLeft then
		local left1 = (sidebars.Left1 and db.SidebarLeft1.Enable) and sidebars.Left1.ButtonAnchor:GetRight() or 16
		local left2 = (sidebars.Left2 and db.SidebarLeft2.Enable) and sidebars.Left2.ButtonAnchor:GetRight() or 16
		UIParent:SetAttribute("LEFT_OFFSET", ceil(max(left1, left2)))
	end
end

function module:SetBarColors()
	LUIBarsTopBG:SetBackdropColor(unpack(Themes.db.bar))
	LUIBarsBottomBG:SetBackdropColor(unpack(Themes.db.bar2))
end

function module:SetSidebarColors()
	local r, g, b, a = unpack(Themes.db.sidebar)

	for _, sb in pairs(sidebars) do
		sb.SidebarBack:SetBackdropColor(r, g, b, a)
		sb.SidebarBack2:SetBackdropColor(r, g, b, a)
		sb.ButtonBack:SetBackdropColor(r, g, b, 1)
		sb.Button:SetBackdropColor(r, g, b, 1)
		sb.ButtonHover:SetBackdropColor(r, g, b, 1)
	end
end

function module:SetColors()
	module:SetSidebarColors()
	module:SetBarColors()
end

function module:CreateBarBackground()
	local top = LUI:CreateMeAFrame("FRAME", "LUIBarsTopBG", UIParent, 1024, 64, 1, "BACKGROUND", 2, "BOTTOM", UIParent, "BOTTOM", tonumber(db.TopTexture.X), tonumber(db.TopTexture.Y), db.TopTexture.Alpha)
	CreateBackdrop(top, "bars_top")
	top:SetBackdropColor(unpack(Themes.db.bar))
	ToggleBar(top, db.TopTexture.Enable)

	local bottom = LUI:CreateMeAFrame("FRAME", "LUIBarsBottomBG", UIParent, 512, 64, 1, "BACKGROUND", 0, "BOTTOM", UIParent, "BOTTOM", tonumber(db.BottomTexture.X), tonumber(db.BottomTexture.Y), db.BottomTexture.Alpha)
	CreateBackdrop(bottom, "bars_bottom")
	bottom:SetBackdropColor(unpack(Themes.db.bar2))
	ToggleBar(bottom, db.BottomTexture.Enable)
end

function module:CreateSidebarSlider(side, id)
	local sideID = side..id
	if sidebars[sideID] then return sidebars[sideID] end

	local isRight = (side == "Right")
	local bardb = db["Sidebar"..sideID]
	local other = isRight and "Left" or "Right"
	local fname = isRight and "sidebar" or "sidebar2"
	local r, g, b, a = unpack(Themes.db.sidebar)

	local sb = {}

	sidebars[sideID] = sb

	sb.Main = isBarAddOnLoaded and bardb.Anchor or "LUIBar"..sideID
	sb.Additional = GetAdditionalAnchors(bardb.Additional)

	sb.timerout, sb.timerin = 0, 0
	sb.x, sb.y, sb.xout = NegateIf(30, isRight), 0, NegateIf(118, isRight)
	sb.pixelpersecond = NegateIf(176, isRight)
	sb.animationtime = 0.5

	sb.SlideOut = CreateFrame("Frame")
	sb.SlideOut:Hide()
	sb.SlideOut:SetScript("OnUpdate", function(self, elapsed)
		sb.timerout = sb.timerout + elapsed
		sb.ButtonAnchor:ClearAllPoints()
		if sb.timerout < sb.animationtime then
			sb.ButtonAnchor:SetPoint(other, sb.Anchor, other, sb.x + sb.timerout * sb.pixelpersecond, sb.y)
		else
			sb.ButtonAnchor:SetPoint(other, sb.Anchor, other, sb.xout, sb.y)
			sb.timerout = 0
			sb.ButtonAlphaIn:Show()
			self:Hide()
			UpdateUIPanelOffset(not isRight)
		end
	end)

	sb.SlideIn = CreateFrame("Frame")
	sb.SlideIn:Hide()
	sb.SlideIn:SetScript("OnUpdate", function(self, elapsed)
		sb.timerin = sb.timerin + elapsed
		if sb.timerin < sb.animationtime then
			sb.ButtonAnchor:ClearAllPoints()
			sb.ButtonAnchor:SetPoint(other, sb.Anchor, other, sb.x - sb.timerin * sb.pixelpersecond + sb.pixelpersecond * sb.animationtime, sb.y)
		else
			sb.ButtonAnchor:ClearAllPoints()
			sb.ButtonAnchor:SetPoint(other, sb.Anchor, other, sb.x, sb.y)
			sb.timerin = 0
			self:Hide()
			UpdateUIPanelOffset(not isRight)
		end
	end)

	sb.alphatimerout, sb.alphatimerin = 0, 0
	sb.speedin, sb.speedout = 0.9, 0.3

	sb.AlphaIn = CreateFrame("Frame", nil, UIParent)
	sb.AlphaIn:Hide()
	sb.AlphaIn:SetScript("OnUpdate", function(self, elapsed)
		sb.alphatimerin = sb.alphatimerin + elapsed
		if sb.alphatimerin < sb.speedin then
			sb.ButtonBack:SetAlpha(sb.alphatimerin / sb.speedin)
		else
			sb.ButtonBack:SetAlpha(1)
			sb.alphatimerin = 0
			self:Hide()
		end
	end)

	sb.AlphaOut = CreateFrame("Frame", nil, UIParent)
	sb.AlphaOut:Hide()
	sb.AlphaOut:SetScript("OnUpdate", function(self, elapsed)
		sb.alphatimerout = sb.alphatimerout + elapsed
		if sb.alphatimerout < sb.speedout then
			sb.ButtonBack:SetAlpha(1 - sb.alphatimerout / sb.speedout)
		else
			sb.ButtonBack:SetAlpha(0)
			sb.alphatimerout = 0
			self:Hide()
		end
	end)

	sb.bttimerin = 0
	sb.btspeedin = 0.3

	sb.ButtonAlphaIn = CreateFrame("Frame", nil, UIParent)
	sb.ButtonAlphaIn:Hide()
	sb.ButtonAlphaIn:SetScript("OnUpdate", function(self,elapsed)
		sb.bttimerin = sb.bttimerin + elapsed
		if sb.bttimerin < sb.btspeedin then
			local alpha = sb.bttimerin / sb.btspeedin
			SidebarSetAlpha(sb.Main, alpha)
			for _, frame in pairs(sb.Additional) do
				SidebarSetAlpha(frame, alpha)
			end
		else
			SidebarSetAlpha(sb.Main, 1)
			for _, frame in pairs(sb.Additional) do
				SidebarSetAlpha(frame, 1)
			end
			sb.bttimerin = 0
			self:Hide()
		end
	end)

	sb.Anchor = LUI:CreateMeAFrame("FRAME", nil, UIParent, 25, 25, 1 / 0.85 * bardb.Scale, "BACKGROUND", 0, side, UIParent, side, NegateIf(-11, isRight), bardb.Offset, 1)
	sb.Anchor:Show()

	sb.Sidebar = LUI:CreateMeAFrame("FRAME", nil, sb.Anchor, 512, 512, 1, "BACKGROUND", 2, other, sb.Anchor, other, NegateIf(17, isRight), 0, 1)
	CreateBackdrop(sb.Sidebar, fname)
	sb.Sidebar:Show()

	sb.SidebarBack = LUI:CreateMeAFrame("FRAME", nil, sb.Anchor, 512, 512, 1, "BACKGROUND", 1, other, sb.Anchor, other, NegateIf(25, isRight), 0, 1)
	CreateBackdrop(sb.SidebarBack, fname.."_back")
	sb.SidebarBack:SetBackdropColor(r, g, b, a)
	sb.SidebarBack:Show()

	sb.SidebarBack2 = LUI:CreateMeAFrame("FRAME", nil, sb.Anchor, 512, 512, 1, "BACKGROUND", 3, other, sb.Anchor, other, NegateIf(25, isRight), 0, 1)
	CreateBackdrop(sb.SidebarBack2, fname.."_back2")
	sb.SidebarBack2:SetBackdropColor(r, g, b, a)
	sb.SidebarBack2:Show()

	sb.ButtonAnchor = LUI:CreateMeAFrame("FRAME", nil, sb.Anchor, 10, 10, 1, "BACKGROUND", 0, other, sb.Anchor, other, NegateIf(30, isRight), 0, 1)
	sb.ButtonAnchor:Show()

	sb.ButtonBack = LUI:CreateMeAFrame("FRAME", nil, sb.ButtonAnchor, 273, 267, 1, "BACKGROUND", 0, other, sb.ButtonAnchor, other, NegateIf(-3, isRight), -2, 1)
	CreateBackdrop(sb.ButtonBack, fname.."_bt_back")
	sb.ButtonBack:SetBackdropColor(r, g, b, 1)
	sb.ButtonBack:SetAlpha(0)
	sb.ButtonBack:Show()

	sb.SidebarBlock = LUI:CreateMeAFrame("FRAME", nil, sb.Anchor, 80, 225, 1, "MEDIUM", 4, other, sb.Anchor, other, NegateIf(82, isRight), -5, 1)
	sb.SidebarBlock:EnableMouse(true)
	sb.SidebarBlock:Show()

	sb.ButtonClicker = LUI:CreateMeAFrame("BUTTON", nil, sb.ButtonAnchor, 30, 215, 1, "MEDIUM", 5, other, sb.ButtonAnchor, other, NegateIf(-6, isRight), -5, 1)
	sb.ButtonClicker:Show()

	sb.Button = LUI:CreateMeAFrame("FRAME", nil, sb.ButtonAnchor, 266, 251, 1, "BACKGROUND", 0, other, sb.ButtonAnchor, other, 0, -2, 1)
	CreateBackdrop(sb.Button, fname.."_button")
	sb.Button:SetBackdropColor(r, g, b, 1)
	sb.Button:Show()

	sb.ButtonHover = LUI:CreateMeAFrame("FRAME", nil, sb.ButtonAnchor, 266, 251, 1, "BACKGROUND", 0, other, sb.ButtonAnchor, other, 0, -2, 1)
	CreateBackdrop(sb.ButtonHover, fname.."_button_hover")
	sb.ButtonHover:SetBackdropColor(r, g, b, 1)
	sb.ButtonHover:Hide()

	sb.sidebaropen = 0

	sb.ButtonClicker:RegisterForClicks("AnyUp")
	sb.ButtonClicker:SetScript("OnClick", function(self)
		if sb.sidebaropen == 0 then
			sb.sidebaropen = 1
			bardb.IsOpen = true
			if bardb.OpenInstant then
				sb.ButtonAnchor:ClearAllPoints()
				sb.ButtonAnchor:SetPoint(other, sb.Anchor, other, NegateIf(120, isRight), 0)
				sb.ButtonBack:SetAlpha(1)
				SidebarSetAlpha(sb.Main, 1)
				for _, frame in pairs(sb.Additional) do
					SidebarSetAlpha(frame, 1)
				end
				sb.SidebarBlock:Hide()
				UpdateUIPanelOffset(not isRight)
			else
				sb.SlideOut:Show()
				sb.AlphaIn:Show()
				sb.SidebarBlock:Hide()
			end
		else
			sb.sidebaropen = 0
			bardb.IsOpen = false
			if bardb.OpenInstant then
				sb.ButtonAnchor:ClearAllPoints()
				sb.ButtonAnchor:SetPoint(other, sb.Anchor, other, NegateIf(32, isRight), 0)
				sb.ButtonBack:SetAlpha(0)
				SidebarSetAlpha(sb.Main, 0)
				for _, frame in pairs(sb.Additional) do
					SidebarSetAlpha(frame, 0)
				end
				sb.SidebarBlock:Show()
				UpdateUIPanelOffset(not isRight)
			else
				sb.SlideIn:Show()
				sb.AlphaOut:Show()
				SidebarSetAlpha(sb.Main, 0)
				for _, frame in pairs(sb.Additional) do
					SidebarSetAlpha(frame, 0)
				end
				sb.SidebarBlock:Show()
			end
		end
	end)

	sb.ButtonClicker:SetScript("OnEnter", function(self)
		sb.Button:Hide()
		sb.ButtonHover:Show()
	end)

	sb.ButtonClicker:SetScript("OnLeave", function(self)
		sb.Button:Show()
		sb.ButtonHover:Hide()
	end)

	SidebarSetAnchor(side, id)
	SidebarSetAlpha(sb.Main, 0)
	for _, frame in pairs(sb.Additional) do
		SidebarSetAlpha(frame, 0)
	end

	ToggleBar(sb.Anchor, bardb.Enable)
	if bardb.Enable and bardb.IsOpen then
		sb.sidebaropen = 1
		sb.SlideOut:Show()
		sb.AlphaIn:Show()
		sb.SidebarBlock:Hide()
	end
end

local function SetOnStatePage(bar) 
	bar:Execute([[
		buttons = table.new()
		for i = 1, 12 do
			table.insert(buttons, self:GetFrameRef("Button"..i))
		end
	]])

	bar:SetAttribute("_onstate-page", [[
		for i, button in ipairs(buttons) do
			button:SetAttribute("actionpage", tonumber(newstate))
		end
	]])
end

function module:SetBottomBar(id)
	local bardb = db["Bottombar"..id]

	if not bars[id] then
		local bar = CreateFrame("Frame", "LUIBar"..id, UIParent, "SecureHandlerStateTemplate")
		bar.buttons = {}

		for i = 1, 12 do
			local button = CreateButton(bar, id, "Bottom", i)
			button:UnregisterEvent("ACTIONBAR_SHOWGRID")
			button:UnregisterEvent("ACTIONBAR_HIDEGRID")
			button:SetAttribute("showgrid", 100)
			if i == 1 then
				button:ClearAllPoints()
				button:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
			end
			bar:SetFrameRef("Button"..i, button)
			bar.buttons[i] = button
			button.__IAB = true
			if button:GetName():find("LUI") then button.buttonType = "LUIBar"..id.."Button" end
		end

		bar:RegisterEvent("ACTIONBAR_SHOWGRID")
		bar:RegisterEvent("ACTIONBAR_HIDEGRID")
		bar:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
		bar:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
		bar:RegisterEvent("PLAYER_ENTERING_WORLD")
		bar:SetScript("OnEvent", HookGrid)

		SetOnStatePage(bar)
		RegisterStateDriver(bar, "page", GetBarState(id))

		-- if bardb.Fader.Enable then
		-- 	Fader:RegisterFrame(bar, bardb.Fader, true)
		-- end

		if Masque then
			local group = Masque:Group("LUI", "Bottom Bar "..id)
			for _, button in pairs(bar.buttons) do
				group:AddButton(button)
			end
		end

		bars[id] = bar
	end

	local bar = bars[id]

	bar.HideEmpty = bardb.HideEmpty

	bar:ClearAllPoints()
	bar:SetPoint(bardb.Point, UIParent, bardb.Point, bardb.X / bardb.Scale, bardb.Y / bardb.Scale)
	bar:SetScale(bardb.Scale)

	Configure(bar, bardb.NumButtons, bardb.NumPerRow)

	if id == 1 then
		bar:Show()
		RegisterStateDriver(bar, "visibility", "[petbattle] [vehicleui] hide; show")
	elseif bardb.Enable then
		UnregisterStateDriver(bar, "visibility")
		RegisterStateDriver(bar, "visibility", "[petbattle] [vehicleui] [bonusbar:5] hide; show")
	else
		UnregisterStateDriver(bar, "visibility")
		bar:Hide()
	end
	ToggleBar(bar, bardb.Enable)
end

function module:SetSideBar(side, id)
	local sideID = side..id
	local bardb = db["Sidebar"..sideID]

	if not bars[sideID] then
		local bar = CreateFrame("Frame", "LUIBar"..sideID, UIParent, "SecureHandlerStateTemplate")
		bar:SetWidth(1) -- because of way LUI handles
		bar:SetHeight(1) -- sidebar position calculation
		bar.buttons = {}

		for i = 1, 12 do
			local button = CreateButton(bar, id, side, i)

			button:UnregisterEvent("ACTIONBAR_SHOWGRID")
			button:UnregisterEvent("ACTIONBAR_HIDEGRID")
			button:SetAttribute("showgrid", 100)
			if i == 1 then
				button:ClearAllPoints()
				button:SetPoint("TOPLEFT", bar, "TOPLEFT", 5, -3)
			end
			bar:SetFrameRef("Button"..i, button)
			bar.buttons[i] = button
			if button:GetName():find("LUI") then button.buttonType = "LUIBar"..sideID.."Button" end
			button:SetAttribute("flyoutDirection", side == "Left" and "RIGHT" or "LEFT")
		end

		bar:RegisterEvent("ACTIONBAR_SHOWGRID")
		bar:RegisterEvent("ACTIONBAR_HIDEGRID")
		bar:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
		bar:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
		bar:RegisterEvent("PLAYER_ENTERING_WORLD")
		bar:SetScript("OnEvent", HookGrid)

		SetOnStatePage(bar)
		RegisterStateDriver(bar, "page", bardb.State[1])

		if Masque then
			local group = Masque:Group("LUI", side.." Sidebar "..id)
			for _, button in pairs(bar.buttons) do
				group:AddButton(button)
			end
		end

		bars[sideID] = bar
	end

	local bar = bars[sideID]
	bar.HideEmpty = bardb.HideEmpty

	Configure(bar, 12, 2)
	bar:SetScale(bardb.Scale)
	ToggleBar(bar, bardb.Enable)
end

function module:SetPetBar()
	if not LUIPetBar then
		local bar = CreateFrame("Frame", "LUIPetBar", UIParent, "SecureHandlerStateTemplate")
		bar.buttons = {}

		RegisterStateDriver(bar, "visibility", "[petbattle] [vehicleui] [bonusbar:5] [nopet] hide; show")

		PetActionBarFrame:SetParent(bar)
		PetActionBarFrame:EnableMouse(false)
		PetActionBarFrame:UnregisterEvent("PET_BAR_SHOWGRID")
		PetActionBarFrame:UnregisterEvent("PET_BAR_HIDEGRID")

		for i = 1, 10 do
			local button = _G["PetActionButton"..i]
			button:SetParent(bar)
			button:Show()
			button.Show = function() end
			button.Hide = function() end
			if i == 1 then
				button:ClearAllPoints()
				button:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
			end
			bar.buttons[i] = button
		end

		if Masque then
			local group = Masque:Group("LUI", "Pet Bar")
			for i = 1, 10 do
				group:AddButton(_G["PetActionButton"..i])
			end
		end
	end

	local scale = db.PetBar.Scale
	LUIPetBar:ClearAllPoints()
	LUIPetBar:SetPoint(db.PetBar.Point, UIParent, db.PetBar.Point, db.PetBar.X / scale, db.PetBar.Y / scale)
	LUIPetBar:SetScale(scale)

	Configure(LUIPetBar, 10, db.PetBar.NumPerRow)
	ToggleBar(LUIPetBar, db.PetBar.Enable)
end

function module:SetStanceBar()
	if not LUIStanceBar then
		local bar = CreateFrame("Frame", "LUIStanceBar", UIParent, "SecureHandlerStateTemplate")
		bar.buttons = {}

		StanceBarFrame:SetParent(bar)
		StanceBarFrame:EnableMouse(false)

		for i = 1, NUM_STANCE_SLOTS do
			local button = _G['StanceButton'..i]
			button:SetParent(bar)
			if i == 1 then
				button:ClearAllPoints()
				button:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
			end
			bar.buttons[i] = button
		end

		local function MoveStance()
			if InCombatLockdown() then return end

			StanceButton1:ClearAllPoints()
			StanceButton1:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)

			Configure(LUIStanceBar, 10, db.StanceBar.NumPerRow)
		end

		-- DO NOT CHANGE
		hooksecurefunc("StanceBar_Update", MoveStance)
		hooksecurefunc("StanceBar_UpdateState", MoveStance)

		if Masque then
			local group = Masque:Group("LUI", "Stance Bar")
			for i = 1, 10 do
				group:AddButton(_G['StanceButton'..i])
			end
		end
	end

	local scale = db.StanceBar.Scale
	LUIStanceBar:ClearAllPoints()
	LUIStanceBar:SetPoint(db.StanceBar.Point, UIParent, db.StanceBar.Point, db.StanceBar.X / scale, db.StanceBar.Y / scale)
	LUIStanceBar:SetScale(scale)

	Configure(LUIStanceBar, 10, db.StanceBar.NumPerRow)
	ToggleBar(LUIStanceBar, db.StanceBar.Enable and GetNumShapeshiftForms() > 0)
end

function module:SetVehicleExit()
	if not LUIVehicleExit then
		local bar = CreateFrame("Frame", "LUIVehicleExit", UIParent, "SecureHandlerStateTemplate")
		bar:SetHeight(60)
		bar:SetWidth(60)

		RegisterStateDriver(bar, "visibility", "[vehicleui] [bonusbar:5] [target=vehicle, exists] show; hide")

		local veb = CreateFrame("Button", nil, bar, "SecureActionButtonTemplate")
		veb:SetAllPoints(bar)
		veb:RegisterForClicks("AnyUp")
		veb:SetNormalTexture("Interface\\Vehicles\\UI-Vehicles-Button-Exit-Up")
		veb:SetPushedTexture("Interface\\Vehicles\\UI-Vehicles-Button-Exit-Down")
		veb:SetHighlightTexture("Interface\\Vehicles\\UI-Vehicles-Button-Exit-Down")
		veb:SetScript("OnClick", function(self) VehicleExit() end)

		if not UnitInVehicle("player") then bar:Hide() end
	end

	local scale = db.VehicleExit.Scale
	LUIVehicleExit:ClearAllPoints()
	LUIVehicleExit:SetPoint(db.VehicleExit.Point, UIParent, db.VehicleExit.Point, db.VehicleExit.X / scale, db.VehicleExit.Y / scale)
	LUIVehicleExit:SetScale(scale)

	ToggleBar(LUIVehicleExit, db.VehicleExit.Enable)
end

function module:SetExtraActionBar()
	local bar = LUIExtraActionBar
	if not bar then
		bar = CreateFrame("Frame", "LUIExtraActionBar", UIParent, "SecureHandlerStateTemplate")
		bar:SetHeight(52)
		bar:SetWidth(52)
		bar.content = ExtraActionBarFrame

		bar.content.ignoreFramePositionManager = true

		bar.content:SetParent(bar)
		bar.content:ClearAllPoints()
		bar.content:SetPoint("CENTER", bar, "CENTER", 0, 0)
	end

	local scale = db.ExtraActionBar.Scale
	bar:ClearAllPoints()
	bar:SetPoint(db.ExtraActionBar.Point, UIParent, db.ExtraActionBar.Point, db.ExtraActionBar.X / scale, db.ExtraActionBar.Y / scale)
	bar:SetScale(scale)

	ToggleBar(bar.content.button.style, not db.ExtraActionBar.HideTextures)
	ToggleBar(bar, db.ExtraActionBar.Enable)
end

function module:HideBlizzard()
	LUI:Print("Hiding Blizzard frames")
	MainMenuBar:SetScale(0.00001)
	MainMenuBar:EnableMouse(false)
	MainMenuBar:SetAlpha(0)
	MainMenuBar:UnregisterAllEvents()

	module:SecureHookScript(InterfaceOptionsActionBarsPanel, "OnEvent", function(frame, event)
		if event == "PLAYER_ENTERING_WORLD" then
			_G.SHOW_MULTI_ACTIONBAR_1 = nil
			_G.SHOW_MULTI_ACTIONBAR_2 = nil
			_G.SHOW_MULTI_ACTIONBAR_3 = nil
			_G.SHOW_MULTI_ACTIONBAR_4 = nil
			InterfaceOptions_UpdateMultiActionBars()
		end
	end)

	PossessBarFrame:SetScale(0.00001)
	PossessBarFrame:EnableMouse(false)
	PossessBarFrame:SetAlpha(0)

	PetActionBarFrame:SetScale(0.00001)
	PetActionBarFrame:EnableMouse(false)
	PetActionBarFrame:SetAlpha(0)

	StanceBarFrame:SetScale(0.00001)
	StanceBarFrame:EnableMouse(false)
	StanceBarFrame:SetAlpha(0)

	local FramesToHide = {
		MainMenuBarArtFrame,
		BonusActionBarFrame,
		PossessBarFrame,
	}

	for _, frame in pairs(FramesToHide) do
		if not module:IsHooked(frame, "Show") then
			module:RawHook(frame, "Show", LUI.dummy, true)
		end
		frame:Hide()
	end

	module:SecureHook("TalentFrame_LoadUI", function()
		PlayerTalentFrame:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
	end)
end

local function StyleButton(button)
	if InCombatLockdown() then return end
	if not button then return end

	local normTex = [[Interface\AddOns\LUI\media\textures\buttons2\Normal.tga]]
	local backdropTex = [[Interface\AddOns\LUI\media\textures\buttons2\Backdrop.tga]]
	local glossTex = [[Interface\AddOns\LUI\media\textures\buttons2\Gloss.tga]]
	local pushedTex = [[Interface\AddOns\LUI\media\textures\buttons2\Normal.tga]]
	local checkedTex = [[Interface\AddOns\LUI\media\textures\buttons2\Highlight.tga]]
	local highlightTex = [[Interface\AddOns\LUI\media\textures\buttons2\Highlight.tga]]
	local flashTex = [[Interface\AddOns\LUI\media\textures\buttons2\Overlay.tga]]
	local borderTex = [[Interface\AddOns\LUI\media\textures\buttons2\Border.tga]]
	local font = [[Interface\Addons\LUI\media\fonts\vibrocen.ttf]]
	local dummy = function() end

	if button:GetNormalTexture() then
		button:GetNormalTexture():SetAlpha(0)
	end

	if button:GetParent() then
		if button:GetParent().HideEmpty and not HasAction(button.action) then
			button:SetAlpha(0)
		else
			button:SetAlpha(1)
		end
	end

	if button.__Styled then return end

	table.insert(buttonlist, button)
	button.__Styled = true

	local parent = button:GetParent()
	if parent then
		parent = parent:GetName()

		if parent == "MultiCastActionBarFrame" then return end
		if parent == "MultiCastActionPage1" then return end
		if parent == "MultiCastActionPage2" then return end
		if parent == "MultiCastActionPage3" then return end
		if parent == "ExtraActionBarFrame" then return end
	end

	local name = button:GetName()
	local size = button:GetWidth()
	local scale = size / 36

	-- first style texts / equipped border, then check for BF/Masque, if not loaded, proceed!
	-- hotkey
	local hotkey = _G[name.."HotKey"]
	hotkey:SetFont(Media:Fetch("font", db.General.HotkeyFont), db.General.HotkeySize, db.General.HotkeyOutline)
	hotkey:SetDrawLayer("OVERLAY")
	hotkey:ClearAllPoints()
	hotkey:SetPoint("TOPRIGHT", button, "TOPRIGHT", -1, -4)
	hotkey:SetWidth(40)
	hotkey:SetHeight(10)

	hotkey.Show_ = hotkey.Show
	hotkey.Show = function()
		if db.General.ShowHotkey and hotkey:GetText() ~= RANGE_INDICATOR then
			hotkey:Show_()
		end
	end

	if not db.General.ShowHotkey then hotkey:Hide() end

	-- macro
	local macro = _G[name.."Name"]
	macro:SetFont(Media:Fetch("font", db.General.MacroFont), db.General.MacroSize, db.General.MacroOutline)
	macro:SetDrawLayer("OVERLAY")
	macro:ClearAllPoints()
	macro:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 4)
	macro:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 4)
	macro:SetHeight(10)

	if not db.General.ShowMacro then macro:Hide() end

	-- count
	local count = _G[name.."Count"]
	count:SetFont(Media:Fetch("font", db.General.CountFont), db.General.CountSize, db.General.CountOutline)
	count:SetDrawLayer("OVERLAY")
	count:ClearAllPoints()
	count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 6)
	count:SetWidth(40)
	count:SetHeight(10)

	if not db.General.ShowCount then count:Hide() end

	-- border (show/hide functionality)
	local border = _G[name.."Border"]

	border.Show_ = border.Show
	border.Show = function() if db.General.ShowEquipped then border:Show_() end end

	if not db.General.ShowEquipped then border:Hide() end

	button.GetHotkey = function(button) return GetBindingKey("CLICK "..button:GetName()..":LeftButton") end
	button:HookScript("OnEnter", function(button)
		if button.GetHotkey then
			LibKeyBound:Set(button)
		end
	end)

	if Masque then return end

	-- normal
	local normal = button:GetNormalTexture()
	normal:SetTexture("")
	normal.SetTextureOrig = normal.SetTexture
	normal.SetTexture = function(self) self:SetTextureOrig("") end
	normal:Hide()
	normal.Show = normal.Hide
	button.SetNormalTexture = dummy

	local newnormal = button:CreateTexture(name.."Normal", "BACKGROUND", 0)
	newnormal:SetTexture(normTex)
	newnormal:SetDrawLayer("BORDER", 0)
	newnormal:SetBlendMode("BLEND")
	newnormal:SetVertexColor(0.133, 0.133, 0.133, 0.95)
	newnormal:SetWidth(40 * scale)
	newnormal:SetHeight(40 * scale)
	newnormal:ClearAllPoints()
	newnormal:SetPoint("CENTER", button, "CENTER", 0, 0)

	-- backdrop
	local backdrop = button:CreateTexture(name.."Backdrop", "BACKGROUND", 0)
	backdrop:SetParent(button)
	backdrop:SetTexture(backdropTex)
	backdrop:SetBlendMode("BLEND")
	backdrop:SetVertexColor(0.11, 0.11, 0.11, 1)
	backdrop:SetWidth(40 * scale)
	backdrop:SetHeight(40 * scale)
	backdrop:ClearAllPoints()
	backdrop:SetPoint("CENTER", button, "CENTER", 0, 0)

	-- gloss
	local gloss = button:CreateTexture(name.."Gloss", "OVERLAY", 0)
	gloss:SetTexture(glossTex)
	gloss:SetBlendMode("BLEND")
	gloss:SetVertexColor(1, 1, 1, 1)
	gloss:SetAlpha(0.5)
	gloss:SetWidth(40 * scale)
	gloss:SetHeight(40 * scale)
	gloss:ClearAllPoints()
	gloss:SetPoint("CENTER", button, "CENTER", 0, 0)

	-- cooldown
	local cooldown = _G[name.."Cooldown"]
	cooldown:SetWidth(33 * scale)
	cooldown:SetHeight(33 * scale)
	cooldown:ClearAllPoints()
	cooldown:SetPoint("CENTER", button, "CENTER", 0, 0)

	-- pushed
	local pushed = button:GetPushedTexture()
	pushed:SetTexture(pushedTex)
	pushed:SetDrawLayer("BORDER", 5)
	pushed:SetBlendMode("ALPHAKEY")
	pushed:SetVertexColor(0.32, 0.32, 0.32, 1)
	pushed:SetWidth(40 * scale)
	pushed:SetHeight(40 * scale)
	pushed:ClearAllPoints()
	pushed:SetPoint("CENTER", button, "CENTER", 0, 0)
	button.SetPushedTexture = dummy

	-- checked
	local checked = button:GetCheckedTexture()
	checked:SetTexture(checkedTex)
	checked:SetDrawLayer("BORDER", 2)
	checked:SetBlendMode("ADD")
	checked:SetVertexColor(0.4, 0.4, 0.4, 1)
	checked:SetWidth(40 * scale)
	checked:SetHeight(40 * scale)
	checked:ClearAllPoints()
	checked:SetPoint("CENTER", button, "CENTER", 0, 0)
	button.SetCheckedTexture = dummy

	-- highlight
	local highlight = button:GetHighlightTexture()
	highlight:SetTexture(highlightTex)
	highlight:SetDrawLayer("HIGHLIGHT", 0)
	highlight:SetBlendMode("ADD")
	highlight:SetVertexColor(0.4, 0.4, 0.4, 1)
	highlight:SetWidth(40 * scale)
	highlight:SetHeight(40 * scale)
	highlight:ClearAllPoints()
	highlight:SetPoint("CENTER", button, "CENTER", 0, 0)
	button.SetHightlightTexture = dummy

	-- icon
	local icon = _G[name.."Icon"]
	icon:SetParent(button)
	icon:SetDrawLayer("BORDER", -5)
	icon:SetBlendMode("BLEND")
	icon:SetWidth(34 * scale)
	icon:SetHeight(34 * scale)
	icon:ClearAllPoints()
	icon:SetPoint("CENTER", button, "CENTER", 0, 0)

	-- flash
	local flash = _G[name.."Flash"]
	flash:SetTexture(flashTex)
	flash:SetDrawLayer("ARTWORK", 0)
	flash:SetBlendMode("BLEND")
	flash:SetVertexColor(1, 0, 0, 1)
	flash:SetWidth(40 * scale)
	flash:SetHeight(40 * scale)
	flash:ClearAllPoints()
	flash:SetPoint("CENTER", button, "CENTER", 0, 0)
	flash.SetTexture = dummy

	-- border (styling)
	border:SetTexture(borderTex)
	border.SetTexture = dummy
	border:SetDrawLayer("ARTWORK", 0)
	border:SetBlendMode("ADD")
	border:SetWidth(40 * scale)
	border:SetHeight(40 * scale)
	border:ClearAllPoints()
	border:SetPoint("CENTER", button, "CENTER", 0, 0)

	-- autocast
	local autocast = _G[name.."Shine"]
	if autocast then
		autocast:SetWidth(34 * scale)
		autocast:SetHeight(34 * scale)
		autocast:ClearAllPoints()
		autocast:SetPoint("CENTER", button, "CENTER", 0, 0)
	end

	button.SetFrameLevel = dummy
end

local function StylePetButtons()
	for i = 1, 10 do
		StyleButton(_G["PetActionButton"..i])
	end
end

local function StyleStanceButtons()
	for i = 1, 10 do
		StyleButton(_G['StanceButton'..i])
	end
end

local flyoutButtons = 0
local function StyleFlyout(self)
	if not self.FlyoutArrow then return end

	self.FlyoutBorder:SetAlpha(0)
	self.FlyoutBorderShadow:SetAlpha(0)

	SpellFlyoutHorizontalBackground:SetAlpha(0)
	SpellFlyoutVerticalBackground:SetAlpha(0)
	SpellFlyoutBackgroundEnd:SetAlpha(0)

	for i = 1, GetNumFlyouts() do
		local _, _, numSlots, isKnown = GetFlyoutInfo(GetFlyoutID(i))
		if isKnown then
			flyoutButtons = numSlots
			break
		end
	end

	local arrowDistance
	if (SpellFlyout and SpellFlyout:IsShown() and SpellFlyout:GetParent() == self) or GetMouseFocus() == self then
		arrowDistance = 5
	else
		arrowDistance = 2
	end
end

local function StyleFlyoutButton()
	for i = 1, flyoutButtons do
		if _G["SpellFlyoutButton"..i] then
			StyleButton(_G["SpellFlyoutButton"..i])
		end
	end
end

local function UpdateHotkey(self, abt)
	local gsub = string.gsub
	local hotkey = _G[self:GetName().."HotKey"]
	local text = hotkey:GetText()

	if text == nil then text = "" end

	text = gsub(text, "(s%-)", "S")
	text = gsub(text, "(a%-)", "A")
	text = gsub(text, "(c%-)", "C")
	text = gsub(text, "(Mouse Button )", "M")
	text = gsub(text, "(Middle Mouse)", "M3")
	text = gsub(text, "(Mouse Wheel Down)", "MWD")
	text = gsub(text, "(Mouse Wheel Up)", "MWU")
	text = gsub(text, "(Num Pad )", "N")
	text = gsub(text, "(Page Up)", "PU")
	text = gsub(text, "(Page Down)", "PD")
	text = gsub(text, "(Spacebar)", "SpB")
	text = gsub(text, "(Insert)", "Ins")
	text = gsub(text, "(Home)", "Hm")
	text = gsub(text, "(Delete)", "Del")

	if hotkey:GetText() == _G["RANGE_INDICATOR"] then
		hotkey:SetText()
	else
		hotkey:SetText(text)
	end
end

local function Button_UpdateUsable(button)
	local icon = _G[button:GetName().."Icon"]
	local isUsable, notEnoughMana = IsUsableAction(button.action)

	if IsActionInRange(button.action) ~= 0 then
		if isUsable then
			icon:SetVertexColor(1.0, 1.0, 1.0)
		elseif notEnoughMana then
			icon:SetVertexColor(0.5, 0.5, 1.0)
		else
			icon:SetVertexColor(0.4, 0.4, 0.4)
		end
	else
		icon:SetVertexColor(0.8, 0.1, 0.1)
	end
end

local function Button_OnUpdate(button, elapsed)
	button.__elapsed = (button.__elapsed or 0) + elapsed

	if button.__elapsed > 0.2 then
		button.__elapsed = nil
		Button_UpdateUsable(button)
	end
end

function module:HookActionButton(button)
	if LUI.PTR and button then
		module:SecureHook(button, "Update", StyleButton)
		module:SecureHook(button, "OnUpdate", Button_OnUpdate)
		module:SecureHook(button, "UpdateHotkeys", UpdateHotkey)
		module:SecureHook(button, "UpdateUsable", Button_UpdateUsable)
	elseif not LUI.PTR then
		module:SecureHook("ActionButton_Update", StyleButton)
		module:SecureHook("ActionButton_OnUpdate", Button_OnUpdate)
		module:SecureHook("ActionButton_UpdateHotkeys", UpdateHotkey)
		module:SecureHook("ActionButton_UpdateUsable", Button_UpdateUsable)
	end
	--Prevent rehooking.
	if not module:IsHooked("StanceBar_Update") then
		module:SecureHook("StanceBar_Update", StyleStanceButtons)
		module:SecureHook("StanceBar_UpdateState", StyleStanceButtons)
		module:SecureHook("PetActionBar_Update", StylePetButtons)
		module:SecureHook("ActionButton_UpdateFlyout", StyleFlyout)
		SpellFlyout:HookScript("OnShow", StyleFlyoutButton)
	end
end

function module:LIBKEYBOUND_ENABLED()
	module.keyBoundMode = true
end
function module:LIBKEYBOUND_DISABLED()
	module.keyBoundMode = nil
end

function module:SetLibKeyBound()
	LibKeyBound.RegisterCallback(self, "LIBKEYBOUND_ENABLED")
	LibKeyBound.RegisterCallback(self, "LIBKEYBOUND_DISABLED")
	--LibKeyBound.RegisterCallback(self, "LIBKEYBOUND_MODE_COLOR_CHANGED")
end

function module:SetBars()
	if not (IsAddOnLoaded("Bartender4") or IsAddOnLoaded("Dominos") or IsAddOnLoaded("Macaroon")) and db.General.Enable then
		if not db.StatesLoaded then LoadStates(defaultstate) end

		module:SetLibKeyBound()

		for i = 1, 6 do
			module:SetBottomBar(i)
		end

		for i = 1, 2 do
			module:SetSideBar("Left", i)
			module:SetSideBar("Right", i)
		end

		module:SetPetBar()
		module:SetStanceBar()
		module:SetVehicleExit()
		module:SetExtraActionBar()

		module:HideBlizzard()
		module:HookActionButton()

		-- because of an ugly bug...
		module:SecureHook(CharacterFrame, "Show", function() TokenFrame_Update() end)
		module:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

	else
		isBarAddOnLoaded = true
	end

	module:CreateBarBackground()

	module:CreateSidebarSlider("Right", 1)
	module:CreateSidebarSlider("Right", 2)
	module:CreateSidebarSlider("Left", 1)
	module:CreateSidebarSlider("Left", 2)

	UpdateUIPanelOffset(true)
end

module.defaults = {
	profile = {
		StatesLoaded = false,
		General = {
			Enable = true,
			AdjustUIPanels = true,
			ShowHotkey = false,
			HotkeyFont = "vibrocen",
			HotkeySize = 12,
			HotkeyOutline = "OUTLINE",
			ShowMacro = false,
			MacroFont = "vibrocen",
			MacroSize = 12,
			MacroOutline = "OUTLINE",
			ShowCount = true,
			CountFont = "vibrocen",
			CountSize = 14,
			CountOutline = "OUTLINE",
			ShowEquipped = false
		},
		TopTexture = {
			Enable = true,
			Alpha = 0.7,
			X = 0,
			Y = 60,
			Animation = true,
			AnimationHeight = 35,
		},
		BottomTexture = {
			Enable = true,
			Alpha = 1,
			X = 0,
			Y = -25,
		},
		SidebarRight1 = {
			Enable = true,
			OpenInstant = false,
			Offset = 0,
			IsOpen = false,
			Anchor = "BT4Bar10",
			Additional = "",
			AutoPosEnable = true,
			HideEmpty = true,
			X = 0,
			Y = 0,
			Scale = 0.85,
			State = {"0"},
		},
		SidebarRight2 = {
			Enable = false,
			OpenInstant = false,
			Offset = 250,
			IsOpen = false,
			Anchor = "BT4Bar8",
			Additional = "",
			AutoPosEnable = true,
			HideEmpty = true,
			X = 0,
			Y = 0,
			Scale = 0.85,
			State = {"0"},
		},
		SidebarLeft1 = {
			Enable = false,
			OpenInstant = false,
			Offset = 0,
			IsOpen = false,
			Anchor = "BT4Bar9",
			Additional = "",
			AutoPosEnable = true,
			HideEmpty = true,
			X = 0,
			Y = 0,
			Scale = 0.85,
			State = {"0"},
		},
		SidebarLeft2 = {
			Enable = false,
			OpenInstant = false,
			Offset = 250,
			IsOpen = false,
			Anchor = "BT4Bar7",
			Additional = "",
			AutoPosEnable = true,
			HideEmpty = true,
			X = 0,
			Y = 0,
			Scale = 0.85,
			State = {"0"},
		},
		Bottombar1 = {
			Enable = true,
			X = 0,
			Y = 20.8,
			Point = "BOTTOM",
			Scale = 0.85,
			NumPerRow = 12,
			NumButtons = 12,
			HideEmpty = false,
			State = {
				[1] = "0",
				[2] = "0",
				[3] = "0",
				[4] = "0",
				[5] = "0",
				Alt = "0",
				Ctrl = "0",
			},
			Fader = {
				Casting = true,
				Combat = true,
				Enable = false,
				Health = true,
				HealthClip = 1.0,
				Hover = true,
				HoverAlpha = 0.75,
				InAlpha = 1.0,
				OutAlpha = 0.1,
				OutDelay = 0.0,
				OutTime = 1.5,
				Power = true,
				PowerClip = 0.9,
				Targeting = true,
				UseGlobalSettings = true,
			},
		},
		Bottombar2 = {
			Enable = true,
			X = 0,
			Y = 54,
			Point = "BOTTOM",
			Scale = 0.85,
			NumPerRow = 12,
			NumButtons = 12,
			HideEmpty = false,
			State = {
				[1] = "0",
				Alt = "0",
				Ctrl = "0",
			},
			Fader = {
				Casting = true,
				Combat = true,
				Enable = false,
				Health = true,
				HealthClip = 1.0,
				Hover = true,
				HoverAlpha = 0.75,
				InAlpha = 1.0,
				OutAlpha = 0.1,
				OutDelay = 0.0,
				OutTime = 1.5,
				Power = true,
				PowerClip = 0.9,
				Targeting = true,
				UseGlobalSettings = true,
			},
		},
		Bottombar3 = {
			Enable = false,
			X = 0,
			Y = 87.2,
			Point = "BOTTOM",
			Scale = 0.85,
			NumPerRow = 12,
			NumButtons = 12,
			HideEmpty = false,
			State = {
				[1] = "0",
				Alt = "0",
				Ctrl = "0",
			},
			Fader = {
				Casting = true,
				Combat = true,
				Enable = false,
				Health = true,
				HealthClip = 1.0,
				Hover = true,
				HoverAlpha = 0.75,
				InAlpha = 1.0,
				OutAlpha = 0.1,
				OutDelay = 0.0,
				OutTime = 1.5,
				Power = true,
				PowerClip = 0.9,
				Targeting = true,
				UseGlobalSettings = true,
			},
		},
		Bottombar4 = {
			Enable = false,
			X = 0,
			Y = 120.4,
			Point = "BOTTOM",
			Scale = 0.85,
			NumPerRow = 12,
			NumButtons = 12,
			HideEmpty = false,
			State = {
				[1] = "0",
				Alt = "0",
				Ctrl = "0",
			},
			Fader = {
				Casting = true,
				Combat = true,
				Enable = false,
				Health = true,
				HealthClip = 1.0,
				Hover = true,
				HoverAlpha = 0.75,
				InAlpha = 1.0,
				OutAlpha = 0.1,
				OutDelay = 0.0,
				OutTime = 1.5,
				Power = true,
				PowerClip = 0.9,
				Targeting = true,
				UseGlobalSettings = true,
			},
		},
		Bottombar5 = {
			Enable = false,
			X = 0,
			Y = 153.6,
			Point = "BOTTOM",
			Scale = 0.85,
			NumPerRow = 12,
			NumButtons = 12,
			HideEmpty = false,
			State = {
				[1] = "0",
				Alt = "0",
				Ctrl = "0",
			},
			Fader = {
				Casting = true,
				Combat = true,
				Enable = false,
				Health = true,
				HealthClip = 1.0,
				Hover = true,
				HoverAlpha = 0.75,
				InAlpha = 1.0,
				OutAlpha = 0.1,
				OutDelay = 0.0,
				OutTime = 1.5,
				Power = true,
				PowerClip = 0.9,
				Targeting = true,
				UseGlobalSettings = true,
			},
		},
		Bottombar6 = {
			Enable = false,
			X = 0,
			Y = 186.8,
			Point = "BOTTOM",
			Scale = 0.85,
			NumPerRow = 12,
			NumButtons = 12,
			HideEmpty = false,
			State = {
				[1] = "0",
				Alt = "0",
				Ctrl = "0",
			},
			Fader = {
				Casting = true,
				Combat = true,
				Enable = false,
				Health = true,
				HealthClip = 1.0,
				Hover = true,
				HoverAlpha = 0.75,
				InAlpha = 1.0,
				OutAlpha = 0.1,
				OutDelay = 0.0,
				OutTime = 1.5,
				Power = true,
				PowerClip = 0.9,
				Targeting = true,
				UseGlobalSettings = true,
			},
		},
		StanceBar = {
			Enable = true,
			X = 42.5,
			Y = -267.8,
			Point = "LEFT",
			Scale = 0.85,
			NumPerRow = 10,
			Fader = {
				Casting = true,
				Combat = true,
				Enable = false,
				Health = true,
				HealthClip = 1.0,
				Hover = true,
				HoverAlpha = 0.75,
				InAlpha = 1.0,
				OutAlpha = 0.1,
				OutDelay = 0.0,
				OutTime = 1.5,
				Power = true,
				PowerClip = 0.9,
				Targeting = true,
				UseGlobalSettings = true,
			},
		},
		PetBar = {
			Enable = true,
			X = -42.5,
			Y = -267.8,
			Point = "RIGHT",
			Scale = 0.85,
			NumPerRow = 10,
			Fader = {
				Casting = true,
				Combat = true,
				Enable = false,
				Health = true,
				HealthClip = 1.0,
				Hover = true,
				HoverAlpha = 0.75,
				InAlpha = 1.0,
				OutAlpha = 0.1,
				OutDelay = 0.0,
				OutTime = 1.5,
				Power = true,
				PowerClip = 0.9,
				Targeting = true,
				UseGlobalSettings = true,
			},
		},
		VehicleExit = {
			Enable = true,
			X = -350,
			Y = -220,
			Point = "CENTER",
			Scale = 1,
		},
		ExtraActionBar = {
			Enable = true,
			X = 0, -- -314,
			Y = 245, -- 41,
			Point = "BOTTOM",
			Scale = 0.85,
			HideTextures = false,
		},
	},
}

function T()
	return "Alt "..db.Bottombar1.State["Alt"], "Ctrl "..db.Bottombar1.State["Ctrl"],
			db.Bottombar1.State[1], db.Bottombar1.State[2], db.Bottombar1.State[3],
			db.Bottombar1.State[4], db.Bottombar1.State[5], db.Bottombar1.State[6]
end

module.childGroups = "select"
module.getter = "generic"
module.setter = "Refresh"

local function getState(info)
	info[#info] = tonumber(info[#info]) or info[#info]
	local val = module.db(info)
	for k, v in pairs(info.option.values()) do
		if v == val then
			return k
		end
	end
end
local function setOptionPoints()
	module:Refresh()
	module:UpdatePositionOptions()
end

local function setBottombarState(info, value)
	info[#info] = tonumber(info[#info]) or info[#info]
	module.db(info, info.option.values()[value])

	local id = tonumber(info[#info-2]:match("%d+"))
	UnregisterStateDriver(bars[id], "page")
	RegisterStateDriver(bars[id], "page", GetBarState(id))
end

local function createBottomBarOptions(num, order)
	if isBarAddOnLoaded then return end
	local disabledFunc = function() return not db["Bottombar"..num].Enable end

	local option = module:NewGroup("Action Bar "..num, order, false, InCombatLockdown, {
		header0 = module:NewHeader("Action Bar "..num.." Settings", 0),
		Enable = (num ~= 1) and module:NewToggle("Show Action Bar "..num, nil, 1, true) or nil,
		empty1 = (num ~= 1) and  module:NewDesc(" ", 2) or nil,
		HideEmpty = module:NewToggle("Hide Empty Buttons", nil, 3, true, nil, disabledFunc),
		[""] = module:NewPosSliders("Action Bar "..num, 4, false, "LUIBar"..num, true, nil, disabledFunc),
		Point = module:NewSelect("Point", "Choose the Point for your Action Bar "..num, 5, pointList, nil, setOptionPoints, nil, disabledFunc),
		empty2 = module:NewDesc(" ", 6),
		Scale = module:NewSlider("Scale", "Scale of Action Bar "..num..".", 7, 0.1, 1.5, 0.05, true, true, nil, disabledFunc),
		empty3 = module:NewDesc(" ", 8),
		NumPerRow = module:NewSlider("Buttons Per Row", "Choose the Number of Buttons per row for your Action Bar "..num..".", 9, 1, 12, 1, true, nil, nil, disabledFunc),
		NumButtons = module:NewSlider("Number of Buttons", "Choose the Number of Buttons for your Action Bar "..num..".", 10, 1, 12, 1, true, nil, nil, disabledFunc),
		State = module:NewGroup("State Settings", 11, getState, setBottombarState, true, {
			Alt = module:NewSelect("Alt", "Choose the Alt State for Action Bar "..num..".\n\nDefault: "..defaultstate["Bottombar"..num][1], 25, statelist, nil, false, nil, disabledFunc),
			Ctrl = module:NewSelect("Ctrl", "Choose the Ctrl State for Action Bar "..num..".\n\nDefault: "..defaultstate["Bottombar"..num][1], 26, statelist, nil, false, nil, disabledFunc),
		}),
	})

	if num == 1 then
		for i, name in ipairs(statetext) do							   
			option.args.State.args[tostring(i)] = module:NewSelect(name, format("Choose the State for %s.\n\nDefaults: %s", name, defaultstate.Bottombar1[i]), i, statelist, nil, false, nil, disabledFunc)
		end
	else	
		option.args.State.args["1"] = module:NewSelect("Default", format("Choose the State for Action Bar %s.\n\nDefaults: %s", num, defaultstate["Bottombar"..num][1]), 1, statelist, nil, false, nil, disabledFunc)
	end

	return option
end

local function setSidebarState(info, value)
	info[#info] = tonumber(info[#info]) or info[#info]
	local val = info.option.values()[value]
	module.db(info, val)

	local barname = gsub(info[#info-2], "Sidebar", "LUIBar")
	UnregisterStateDriver(_G[barname], "page")
	RegisterStateDriver(_G[barname], "page", val)
end

local optIsDisabled = {
	TopTex = function() return not db.TopTexture.Enable end,
	TopTexAnim = function() return not db.TopTexture.Enable or not db.TopTexture.Animation end,
	BottomTex = function() return not db.BottomTexture.Enable end,
	["Stance Bar"] = function() return not db.StanceBar.Enable end,
	["Pet Bar"] = function() return not db.PetBar.Enable end,
	["Vehicle Exit"] = function() return not db.VehicleExit.Enable end,
	Hotkey = function() return not db.General.ShowHotkey end,
	Count = function() return not db.General.ShowCount end,
	Macro = function() return not db.General.ShowMacro end,
}

local function createSideBarOptions(side, num, order)
	local disabledFunc = function() return not db["Sidebar"..side..num].Enable end
	local disabledPosFunc = function() return not db["Sidebar"..side..num].Enable or (isBarAddOnLoaded and not db["Sidebar"..side..num].AutoPosEnable) end

	local option = module:NewGroup(side.." Bar "..num, order, false, InCombatLockdown, {
		header1 = module:NewHeader(side.." Bar "..num.." Settings", 0),
		Enable = module:NewToggle("Show "..side.." Bar "..num, nil, 1, true),
		empty1 = module:NewDesc(" ", 2),
		Intro = isBarAddOnLoaded and module:NewDesc("Which Bar do you want to use for this Sidebar?\nChoose one or type in the MainAnchor manually.\n\nMake sure your Bar is set to 6 buttons/2 columns and isn't used for another Sidebar.\nLUI will position your Bar automatically.", 3) or nil,
		AnchorDropDown = isBarAddOnLoaded and module:NewSelect("Anchor", nil, 4, barAnchors) or nil,
		Anchor = isBarAddOnLoaded and module:NewInput("Anchor", "Choose the Bar for this Sidebar.", 5, nil, nil, disabledFunc) or nil,
		Additional = module:NewInput("Additional Frames", "Type in any additional frame names (seperated by commas), that you would like to show/hide with the Sidebar.", 6, true, nil, disabledFunc),
		empty2 = module:NewDesc(" ", 7),
		[""] = module:NewPosSliders(side.." Bar "..num, 8, false, function() return GetAnchor(sidebars[side..num].Main) end, true, nil, disabledPosFunc),
		Scale = module:NewSlider("Scale", "Choose the Scale for this Sidebar.", 9, 0.1, 1.5, 0.05, true, true, nil, disabledFunc),
		AutoPosEnable = isBarAddOnLoaded and module:NewToggle("Stop touching me!", "Whether or not to have LUI handle your Bar Positioning.", 10, true, nil, disabledFunc) or nil,
		HideEmpty = not isBarAddOnLoaded and module:NewToggle("Hide Empty Buttons", nil, 11, true, nil, disabledFunc) or nil,
		empty3 = module:NewDesc(" ", 12),
		Offset = module:NewInputNumber("Y Offset", "Y Offset for your Sidebar", 13, setOptionPoints, nil, disabledFunc),
		OpenInstant = module:NewToggle("Open Instant", "Whether or not to show an open/close animation.", 14, true, nil, disabledFunc),
		State = not isBarAddOnLoaded and module:NewGroup("State Settings", 15, getState, setSidebarState, true, {
			["1"] = module:NewSelect("Default", "Choose the State for "..side.." Bar "..num..".\n\nDefaults: "..defaultstate["Sidebar"..side..num][1], 1, statelist, nil, false, nil, disabledFunc),
		}) or nil,
	})

	if option.args.AnchorDropDown then
		option.args.AnchorDropDown.desc = function(info)
			info[#info] = "Anchor"
			return "Choose the Bar for this Sidebar.\n\nDefault: "..dbd(info)
		end
		option.args.AnchorDropDown.get = function(info)
			info[#info] = "Anchor"
			local val = db(info)
			for k, v in pairs(info.option.values()) do
				if v == val then
					return k
				end
			end
		end
		option.args.AnchorDropDown.set = function(info, value)
			info[#info] = "Anchor"
			db(info, info.option.values()[value])
			SidebarSetAnchor(side, num)
		end
	end

	return option
end

local function createOtherBarOptions(name, order, frame, dbName, multiRow)
	if isBarAddOnLoaded then return end
	local specialBar = (name == "Extra Action Bar")
	local function setDummyBar()
		if InCombatLockdown() then return end
		toggleDummyBar(ExtraActionBarFrame)
	end

	local option = module:NewGroup(name, order, false, InCombatLockdown, {
		header0 = module:NewHeader(name.." Settings", 0),
		Enable = module:NewToggle("Show "..name, nil, 1, true),
		[""] = module:NewPosSliders(name, 2, false, frame, true, nil, optIsDisabled[name]),
		Point = module:NewSelect("Point", "Choose the Point for the "..name..".", 3, pointList, nil, setOptionPoints, nil, optIsDisabled[name]),
		Scale = module:NewSlider("Scale", "Choose the Scale for the "..name..".", 4, 0.1, 1.5, 0.05, true, true, nil, nil, optIsDisabled[name]),

		HideTextures = specialBar and module:NewToggle("Hide Textures", "Whether or not to hide "..name.." textures.", 5, true) or nil,
		DummyBar = specialBar and module:NewExecute("Show Dummy "..name, "Click to show/hide a dummy "..name..".", 6, setDummyBar, nil, optIsDisabled[name]) or nil,
		NumPerRow = multiRow and module:NewSlider("Buttons per Row", "Choose the Number of Buttons per Row.", 5, 1, 10, 1, true, nil, nil, nil, optIsDisabled[name]) or nil,
	})

	return option
end

function module:LoadOptions()
	local dryCall = function() module:Refresh() end

	local options = {
		General = module:NewGroup("General", 1, false, InCombatLockdown, {
			header1 = module:NewHeader("General Settings", 0),
			Enable = module:NewToggle("Enable", "Whether or not to use LUI's Action Bars.", 1, function() StaticPopup_Show("RELOAD_UI") end),
			empty1 = module:NewDesc(" ", 2),
			AdjustUIPanels = module:NewToggle("Adjust Blizzard's UI Panel positions", nil, 3, true),
			empty2 = module:NewDesc(" ", 4),
			ShowHotkey = module:NewToggle("Show Hotkey Text", nil, 5, true, nil, nil, isBarAddOnLoaded),
			HotkeySize = module:NewSlider("Hotkey Size", "Choose your Hotkey Fontsize.", 6, 1, 40, 1, true, nil, nil, optIsDisabled.Hotkey, isBarAddOnLoaded),
			HotkeyFont = module:NewSelect("Hotkey Font", "Choose your Hotkey Font.", 7, widgetLists.font, "LSM30_Font", true, nil, optIsDisabled.Hotkey, isBarAddOnLoaded),
			HotkeyOutline = module:NewSelect("HotkeyFont Flag", "Choose your Hotkey Fontflag.", 8, LUI.FontFlags, false, dryCall, nil, optIsDisabled.Hotkey, isBarAddOnLoaded),
			empty3 = module:NewDesc(" ", 9, nil, nil, isBarAddOnLoaded),
			ShowMacro = module:NewToggle("Show Macro Text", nil, 10, true, nil, nil, isBarAddOnLoaded),
			MacroSize = module:NewSlider("Macro Size", "Choose your Macro Fontsize.", 11, 1, 40, 1, true, nil, nil, optIsDisabled.Macro, isBarAddOnLoaded),
			MacroFont = module:NewSelect("Macro Font", "Choose your Macro Font.", 12, widgetLists.font, "LSM30_Font", true, nil, optIsDisabled.Macro, isBarAddOnLoaded),
			MacroOutline = module:NewSelect("Macro Font Flag", "Choose your Macro Fontflag.", 13, LUI.FontFlags, false, dryCall, nil, optIsDisabled.Macro, isBarAddOnLoaded),
			empty4 = module:NewDesc(" ", 14, nil, nil, isBarAddOnLoaded),
			ShowCount = module:NewToggle("Show Count Text", nil, 15, true, nil, nil, isBarAddOnLoaded),
			CountSize = module:NewSlider("Count Size", "Choose your Count Fontsize.", 16, 1, 40, 1, true, nil, nil, optIsDisabled.Count, isBarAddOnLoaded),
			CountFont = module:NewSelect("Count Font", "Choose your Count Font.", 17, widgetLists.font, "LSM30_Font", true, nil, optIsDisabled.Count, isBarAddOnLoaded),
			CountOutline = module:NewSelect("Count Font Flag", "Choose your Count Fontflag.", 18, LUI.FontFlags, false, dryCall, nil, optIsDisabled.Count, isBarAddOnLoaded),
			empty5 = module:NewDesc(" ", 19, nil, nil, isBarAddOnLoaded),
			ShowEquipped = module:NewToggle("Show Equipped Border", nil, 20, true, nil, nil, isBarAddOnLoaded),
			empty6 = module:NewDesc(" ", 21, nil, nil, isBarAddOnLoaded),
			LoadLUI = module:NewExecute("Load LUI States", "Load the default Bar States.", 21, function() LoadStates(defaultstate); module:Refresh() end, nil, nil, isBarAddOnLoaded, isBarAddOnLoaded),
			empty7 = module:NewDesc(" ", 23, nil, nil, isBarAddOnLoaded),
			ToggleKB = module:NewExecute("Keybinds", "Toggles Keybinding mode.", 24, function() LibKeyBound:Toggle() end, nil, nil, isBarAddOnLoaded, isBarAddOnLoaded),
			empty8 = module:NewDesc(" ", 25),
			Reset = module:NewExecute("Restore Defaults", "Restores Bar Default Settings. (Does NOT affect Bartender etc! For this go to General->AddOns)", -1, function() module.db:ResetProfile(); module:Refresh() end),
		}),
		TopTexture = module:NewGroup("Top Texture", 2, false, InCombatLockdown, {
			header1 = module:NewHeader("Top Texture Settings", 0),
			Enable = module:NewToggle("Enable", "Whether or not to show the Top Bar Texture.", 1, true),
			Alpha = module:NewSlider("Alpha", "Choose your Top Bar Texture Alpha.", 2, nil, nil, nil, true, true, nil, optIsDisabled.TopTex),
			empty1 = module:NewDesc(" ", 3),
			[""] = module:NewPosSliders("Top Bar Texture", 4, false, "LUIBarsTopBG", nil, nil, optIsDisabled.TopTex),
		}),
		BottomTexture = module:NewGroup("Bottom Texture", 3, false, InCombatLockdown, {
			header1 = module:NewHeader("Bottom Texture Settings", 0),
			Enable = module:NewToggle("Enable", "Whether or not to show the Bottom Bar Texture.", 1, true),
			Alpha = module:NewSlider("Alpha", "Choose your Bottom Bar Texture Alpha.", 2, nil, nil, nil, true, true, nil, optIsDisabled.BottomTex),
			empty1 = module:NewDesc(" ", 3),
			[""] = module:NewPosSliders("Bottom Bar Texture", 4, false, "LUIBarsBottomBG", nil, nil, optIsDisabled.BottomTex),
		}),
		Bottombar1 = createBottomBarOptions(1, 4),
		Bottombar2 = createBottomBarOptions(2, 5),
		Bottombar3 = createBottomBarOptions(3, 6),
		Bottombar4 = createBottomBarOptions(4, 7),
		Bottombar5 = createBottomBarOptions(5, 8),
		Bottombar6 = createBottomBarOptions(6, 9),
		SidebarRight1 = createSideBarOptions("Right", 1, 10),
		SidebarRight2 = createSideBarOptions("Right", 2, 11),
		SidebarLeft1 = createSideBarOptions("Left", 1, 12),
		SidebarLeft2 = createSideBarOptions("Left", 2, 13),
		StanceBar = createOtherBarOptions("Shapeshift/Stance Bar", 14, "LUIStanceBar", "StanceBar", true),
		PetBar = createOtherBarOptions("Pet Bar", 15, "LUIPetBar", "PetBar", true),
		VehicleExit = createOtherBarOptions("Vehicle Exit Button", 17, "LUIVehicleExit"),
		ExtraActionBar = createOtherBarOptions("Extra Action Bar", 18, "LUIExtraActionBar"),
	}

	return options
end

function module:Refresh(...)
	local info, value = ...
	if type(info) == "table" then
		db(info, value)
	end

	if not isBarAddOnLoaded then
		for i = 1, 6 do
			module:SetBottomBar(i)
		end

		for i = 1, 2 do
			module:SetSideBar("Left", i)
			module:SetSideBar("Right", i)
		end

		for _, bar in pairs(bars) do
			HookGrid(bar)
		end

		module:SetPetBar()
		module:SetStanceBar()
		module:SetVehicleExit()
		module:SetExtraActionBar()
	end

	LUIBarsTopBG:SetAlpha(db.TopTexture.Alpha)
	LUIBarsTopBG:ClearAllPoints()
	LUIBarsTopBG:SetPoint("BOTTOM", UIParent, "BOTTOM", db.TopTexture.X, db.TopTexture.Y)
	LUIBarsTopBG[db.TopTexture.Enable and "Show" or "Hide"](LUIBarsTopBG)

	LUIBarsBottomBG:SetAlpha(db.BottomTexture.Alpha)
	LUIBarsBottomBG:ClearAllPoints()
	LUIBarsBottomBG:SetPoint("BOTTOM", UIParent, "BOTTOM", db.BottomTexture.X, db.BottomTexture.Y)
	LUIBarsBottomBG[db.BottomTexture.Enable and "Show" or "Hide"](LUIBarsBottomBG)

	for _, button in pairs(buttonlist) do
		local name = button:GetName()

		local count = _G[name.."Count"]
		if count then
			count:SetFont(Media:Fetch("font", db.General.CountFont), db.General.CountSize, db.General.CountOutline)
			if db.General.ShowCount then
				count:Show()
			else
				count:Hide()
			end
		end

		local hotkey = _G[name.."HotKey"]
		if hotkey then
			hotkey:SetFont(Media:Fetch("font", db.General.HotkeyFont), db.General.HotkeySize, db.General.HotkeyOutline)
			if db.General.ShowHotkey then
				hotkey:Show()
			else
				hotkey:Hide()
			end
		end

		local macro = _G[name.."Name"]
		if macro then
			macro:SetFont(Media:Fetch("font", db.General.MacroFont), db.General.MacroSize, db.General.MacroOutline)
			if db.General.ShowMacro then
				macro:Show()
			else
				macro:Hide()
			end
		end

		local border = _G[name.."Border"]
		if db.General.ShowEquipped and button.action and IsEquippedAction(button.action) then
			if border then border:Show() end
		else
			if border then border:Hide() end
		end
	end

	SidebarSetAnchor("Left", 1)
	SidebarSetAnchor("Left", 2)
	SidebarSetAnchor("Right", 1)
	SidebarSetAnchor("Right", 2)

	UpdateUIPanelOffset(true)
end

function module:OnInitialize()
	db, dbd = LUI:NewNamespace(self)

	local ProfileName = UnitName("player").." - "..GetRealmName()

	if LUI.db.global.luiconfig[ProfileName].Versions.bars ~= LUI.Versions.bars then

		-- recalc X/Y values for fixed scale options
		if LUI.Versions.bars < 2.4 then
			print("bla")
			for k, v in pairs(module.db.profile) do
				if type(v) == "table" then
					if v.Scale then
						if v.X ~= module.defaults.profile[k].X then
							v.X = v.X * v.Scale * v.Scale
						end

						if v.Y ~= module.defaults.profile[k].Y then
							v.Y = v.Y * v.Scale * v.Scale
						end
					end
				end
			end
		end

		-- exclude this time!
		if not (LUI.Versions.bars == 2.4 and LUI.db.global.luiconfig[ProfileName].Versions.bars == 2.3) then
			db:ResetProfile()
		end
		LUI.db.global.luiconfig[ProfileName].Versions.bars = LUI.Versions.bars
	end
end

function module:PLAYER_SPECIALIZATION_CHANGED()
	module:SetStanceBar()
end

function module:OnEnable()
	module:SetBars()
end

function module:OnDisable()
	module:UnRegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
end
