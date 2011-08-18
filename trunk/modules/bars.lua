--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: bars.lua
	Description: Bars Module
	Version....: 2.1
	Rev Date...: 16/08/11 [dd/mm/yy]
]] 

local addonname, LUI = ...
local module = LUI:Module("Bars", "AceHook-3.0", "AceEvent-3.0")
local Panels = LUI:Module("Panels")
local Themes = LUI:Module("Themes")
local Forte = LUI:Module("Forte")
local Fader = LUI:Module("Fader")
local Masque = LibStub("Masque", true)
local LibKeyBound = LibStub("LibKeyBound-1.0")
local widgetLists = AceGUIWidgetLSMlists

local L = LUI.L
local db, dbd
local fdir = "Interface\\AddOns\\LUI\\media\\templates\\v3\\"

LUI.Versions.bars = 2.3

local positions = {"TOP", "TOPRIGHT", "TOPLEFT","BOTTOM", "BOTTOMRIGHT", "BOTTOMLEFT","RIGHT", "LEFT", "CENTER"}

local _, class = UnitClass("player")

local buttonlist = {}
local bars = {}
local sidebars = {}

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

local isBarAddOnLoaded, isLibMasqueLoaded

local statetexts = setmetatable({
	["DRUID"] = {"Default", "Bear Form", "Cat Form", "Cat Form (Prowl)", "Moonkin Form", "Tree of Life Form"},
	["WARRIOR"] = {"Default", "Battle Stance", "Defensive Stance", "Berserker Stance"},
	["PRIEST"] = {"Default", "Shadow Form"},
	["ROGUE"] = {"Default", "Stealth", "Shadowdance"},
	["WARLOCK"] = {"Default", "Metamorphosis"},
	["DEFAULT"] = {"Default"},
}, {
	__index = function(t, k)
		return t["DEFAULT"]
	end,
})
local statetext = statetexts[class]

local defaultstates = setmetatable({
	["DRUID"] = {"1", "3", "5", "5", "4", "6"},
	["WARRIOR"] = {"1", "3", "5", "4"},
	["PRIEST"] = {"1", "3"},
	["ROGUE"] = {"1", "3", "5"},
	["WARLOCK"] = {"1", "3"},
	["DEFAULT"] = {"1"}
}, {
	__index = function(t, k)
		if type(k) == "number" then
			return {tostring(k)}
		end
		return t["DEFAULT"]
	end,
})
local defaultstate = {
	Bottombar1 = defaultstates[class],
	Bottombar2 = defaultstates[2],
	Bottombar3 = defaultstates[3],
	Bottombar4 = defaultstates[4],
	Bottombar5 = defaultstates[5],
	Bottombar6 = defaultstates[6],
	SidebarLeft1 = defaultstates[9],
	SidebarLeft2 = defaultstates[7],
	SidebarRight1 = defaultstates[10],
	SidebarRight2 = defaultstates[8],
}

local blizzstates = setmetatable({
	["DRUID"] = {"1", "7", "8", "8", "9", "10"},
	["WARRIOR"] = {"1", "7", "8", "9"},
	["PRIEST"] = {"1", "7"},
	["ROGUE"] = {"1", "7", "8"},
	["WARLOCK"] = {"1", "7"},
	["DEFAULT"] = {"1"}
}, {
	__index = function(t, k)
		if type(k) == "number" then
			return {tostring(k)}
		end
		return t["DEFAULT"]
	end,
})
local blizzstate = {
	Bottombar1 = blizzstates[class],
	Bottombar2 = blizzstates[6],
	Bottombar3 = blizzstates[5],
	Bottombar4 = blizzstates[7],
	Bottombar5 = blizzstates[8],
	Bottombar6 = blizzstates[9],
	SidebarLeft1 = blizzstates[3],
	SidebarLeft2 = blizzstates[1],
	SidebarRight1 = blizzstates[4],
	SidebarRight2 = blizzstates[2],
}

local Page = {
	["DRUID"] = {
		"[bonusbar:1,nostealth] %s; ",
		"[bonusbar:1,stealth] %s; ",
		"[bonusbar:2] %s; ",
		"[bonusbar:3] %s; ",
		"[bonusbar:4] %s; "
	},
	["WARRIOR"] = {
		"[bonusbar:1] %s; ",
		"[bonusbar:2] %s; ",
		"[bonusbar:3] %s; "
	},
	["PRIEST"] = {
		"[bonusbar:1] %s; "
	},
	["ROGUE"] = {
		"[bonusbar:1] %s; ",
		"[form:3] %s; "
	},
	["WARLOCK"] = {
		"[form:2] %s; "
	},
}

local LoadStates = function(data)
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

local GetAnchor = function(anchor)
	if string.match(anchor, "Dominos") then
		if IsAddOnLoaded("Dominos") then
			return Dominos.ActionBar:Get(string.match(anchor, "%d+"))
		end
	else
		return _G[anchor]
	end
end

local SidebarSetAlpha = function(anchor, alpha)
	anchor = GetAnchor(anchor)
	if anchor then anchor:SetAlpha(alpha) end
end

local SidebarSetAnchor = function(side, id)
	local sbdb = db["Sidebar"..side..id]
	local sb = sidebars[side..id].Anchor
	
	sb:ClearAllPoints()
	sb:SetPoint(side, UIParent, side, side == "Right" and 11 or -11, sbdb.Offset)
	sb:SetScale(1 / 0.85 * sbdb.Scale)
	
	sb[sbdb.Enable and "Show" or "Hide"](sb)
	
	if not sbdb.Enable then return end
	if sbdb.AutoPosEnable ~= true and isBarAddOnLoaded == true then return end
	
	local anchor = isBarAddOnLoaded and sbdb.Anchor or "LUIBar"..side..id
	sidebars[side..id].anchor = anchor
	
	local xOffset = tonumber(sbdb.X)
	local yOffset = tonumber(sbdb.Y)
	local sbOffset = tonumber(sbdb.Offset)
	
	anchor = GetAnchor(anchor)
	
	if not anchor then return end
	if not anchor:IsShown() then return end
	
	if not isBarAddOnLoaded then anchor:SetScale(sbdb.Scale) end
	
	local scale = anchor:GetEffectiveScale()
	local scaleUI = UIParent:GetEffectiveScale()
	
	local x = tonumber(xOffset) + ( scaleUI * math.floor( (side == "Right" and -90 or 20) / scale ) / 0.85 * sbdb.Scale)
	local y = tonumber(yOffset) + ( scaleUI * math.floor( 157 + tonumber(sbOffset) / scale / 0.85 * sbdb.Scale ) )
	
	anchor:SetFrameStrata("BACKGROUND")
	anchor:SetFrameLevel(2)
	anchor:ClearAllPoints()
	anchor:SetPoint(side, UIParent, side, x, y)
end

local Configure = function(bar, n, x)
	local buttons = bar.buttons
	for i = 2, #buttons do
		buttons[i]:ClearAllPoints()
		if (i - 1) % x == 0 then
			buttons[i]:SetPoint("TOP", buttons[i-x], "BOTTOM", 0, -2)
		else
			buttons[i]:SetPoint("LEFT", buttons[i-1], "RIGHT", 2, 0)
		end
		
		if i > n then
			buttons[i]:SetAttribute("statehidden", 1)
			buttons[i]:Hide()
		else
			buttons[i]:SetAttribute("statehidden", nil)
			if buttons[i].__IAB then ActionButton_Update(buttons[i]) end
		end
	end
end

local GetBarState = function(id)
	local bardb = db["Bottombar"..id]
	local condition = "[bonusbar:5] 11; "
	
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

local GetButton = function(bar, barid, barpos, buttonid)
	if barpos == "Bottom" then
		if barid == 1 then
			_G["ActionButton"..buttonid]:SetParent(bar)
			return _G["ActionButton"..buttonid]
		elseif barid == 2 then
			_G["MultiBarBottomLeftButton"..buttonid]:SetParent(bar)
			return _G["MultiBarBottomLeftButton"..buttonid]
		elseif barid == 3 then
			_G["MultiBarBottomRightButton"..buttonid]:SetParent(bar)
			return _G["MultiBarBottomRightButton"..buttonid]
		else
			local button = CreateFrame("CheckButton", "LUIBar"..barid.."Button"..buttonid, bar, "ActionBarButtonTemplate")
			button:SetID(buttonid)
			return button
		end
	elseif barid == 1 then
		if barpos == "Left" then
			_G["MultiBarLeftButton"..buttonid]:SetParent(bar)
			return _G["MultiBarLeftButton"..buttonid]
		else
			_G["MultiBarRightButton"..buttonid]:SetParent(bar)
			return _G["MultiBarRightButton"..buttonid]
		end
	else
		local button = CreateFrame("CheckButton", "LUIBar"..barpos..barid.."Button"..buttonid, bar, "ActionBarButtonTemplate")
		button:SetID(buttonid)
		return button
	end
end

function module:SetBarColors()
	LUIBarsTopBG:SetBackdropColor(unpack(Themes.db.profile.bar))
	LUIBarsBottomBG:SetBackdropColor(unpack(Themes.db.profile.bar2))
end

function module:SetSidebarColors()
	local r, g, b, a = unpack(Themes.db.profile.sidebar)
	
	for _, sb in pairs(sidebars) do
		sb.SidebarBack:SetBackdropColor(r, g, b, a)
		sb.SidebarBack2:SetBackdropColor(r, g, b, a)
		sb.ButtonBack:SetBackdropColor(r, g, b, 1)
		sb.Button:SetBackdropColor(r, g, b, 1)
		sb.ButtonHover:SetBackdropColor(r, g, b, 1)
	end
end

function module:SetColors()
	self:SetSidebarColors()
	self:SetBarColors()
end

function module:CreateBarBackground()
	local top = LUI:CreateMeAFrame("FRAME", "LUIBarsTopBG", UIParent, 1024, 64, 1, "BACKGROUND", 2, "BOTTOM", UIParent, "BOTTOM", tonumber(db.TopTexture.X), tonumber(db.TopTexture.Y), db.TopTexture.Alpha)
	top:SetBackdrop({
		bgFile = "Interface\\AddOns\\LUI\\media\\templates\\v4\\bars_top",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false,
		edgeSize = 1, 
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	top:SetBackdropColor(unpack(Themes.db.profile.bar))
	top:SetBackdropBorderColor(0, 0, 0, 0)
	top[db.TopTexture.Enable and "Show" or "Hide"](top)
	
	local bottom = LUI:CreateMeAFrame("FRAME", "LUIBarsBottomBG", UIParent, 512, 64, 1, "BACKGROUND", 0, "BOTTOM", UIParent, "BOTTOM", tonumber(db.BottomTexture.X), tonumber(db.BottomTexture.Y), db.BottomTexture.Alpha)
	bottom:SetBackdrop({
		bgFile = "Interface\\AddOns\\LUI\\media\\templates\\v4\\bars_bottom", 
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
		tile = false,
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	bottom:SetBackdropColor(unpack(Themes.db.profile.bar2))
	bottom:SetBackdropBorderColor(0, 0, 0, 0)
	bottom[db.BottomTexture.Enable and "Show" or "Hide"](bottom)
end

function module:CreateSidebarSlider(side, id)
	if sidebars[side..id] then return sidebars[side..id] end
	
	local bardb = db["Sidebar"..side..id]
	local other = side == "Right" and "Left" or "Right"
	local fname = side == "Right" and "sidebar" or "sidebar2"
	local isRight = side == "Right"
	
	local r, g, b, a = unpack(Themes.db.profile.sidebar)
	
	local sb = {}
	
	sidebars[side..id] = sb
	
	sb.anchor = isBarAddOnLoaded and bardb.Anchor or "LUIBar"..side..id
	
	sb.timerout, sb.timerin = 0, 0
	sb.x, sb.y, sb.xout = isRight and -30 or 30, 0, isRight and -118 or 118
	sb.pixelpersecond = isRight and -176 or 176
	sb.animationtime = 0.5
	
	sb.SlideOut = CreateFrame("Frame", nil, UIParent)
	sb.SlideOut:Hide()
	sb.SlideOut:SetScript("OnUpdate", function(self, elapsed)
		sb.timerout = sb.timerout + elapsed
		if sb.timerout < sb.animationtime then
			sb.ButtonAnchor:ClearAllPoints()
			sb.ButtonAnchor:SetPoint(other, sb.Anchor, other, sb.x + sb.timerout * sb.pixelpersecond, sb.y)
		else
			sb.ButtonAnchor:ClearAllPoints()
			sb.ButtonAnchor:SetPoint(other, sb.Anchor, other, sb.xout, sb.y)
			sb.timerout = 0
			sb.ButtonAlphaIn:Show()
			self:Hide()
		end
	end)
	
	sb.SlideIn = CreateFrame("Frame", nil, UIParent)
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
			SidebarSetAlpha(sb.anchor, alpha)
			for _, frame in pairs(Panels:LoadAdditional(bardb.Additional)) do
				SidebarSetAlpha(frame, alpha)
			end
		else
			SidebarSetAlpha(sb.anchor, 1)
			for _, frame in pairs(Panels:LoadAdditional(bardb.Additional)) do
				SidebarSetAlpha(frame, 1)
			end
			sb.bttimerin = 0
			self:Hide()
		end
	end)
	
	sb.Anchor = LUI:CreateMeAFrame("FRAME", nil, UIParent, 25, 25, 1 / 0.85 * bardb.Scale, "BACKGROUND", 0, side, UIParent, side, isRight and 11 or -11, bardb.Offset, 1)
	sb.Anchor:Show()
	
	sb.Sidebar = LUI:CreateMeAFrame("FRAME", nil, sb.Anchor, 512, 512, 1, "BACKGROUND", 2, other, sb.Anchor, other, isRight and -17 or 17, 0, 1)
	sb.Sidebar:SetBackdrop({
		bgFile = fdir..fname,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false,
		tileSize = 0,
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	sb.Sidebar:SetBackdropBorderColor(0, 0, 0, 0)
	sb.Sidebar:Show()
	
	sb.SidebarBack = LUI:CreateMeAFrame("FRAME", nil, sb.Anchor, 512, 512, 1, "BACKGROUND", 1, other, sb.Anchor, other, isRight and -25 or 25, 0, 1)
	sb.SidebarBack:SetBackdrop({
		bgFile = fdir..fname.."_back",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false,
		tileSize = 0,
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	sb.SidebarBack:SetBackdropColor(r, g, b, a)
	sb.SidebarBack:SetBackdropBorderColor(0, 0, 0, 0)
	sb.SidebarBack:Show()
	
	sb.SidebarBack2 = LUI:CreateMeAFrame("FRAME", nil, sb.Anchor, 512, 512, 1, "BACKGROUND", 3, other, sb.Anchor, other, isRight and -25 or 25, 0, 1)
	sb.SidebarBack2:SetBackdrop({
		bgFile = fdir..fname.."_back2",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false,
		tileSize = 0,
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	sb.SidebarBack2:SetBackdropColor(r, g, b, a)
	sb.SidebarBack2:SetBackdropBorderColor(0, 0, 0, 0)
	sb.SidebarBack2:Show()
	
	sb.ButtonAnchor = LUI:CreateMeAFrame("FRAME", nil, sb.Anchor, 10, 10, 1, "BACKGROUND", 0, other, sb.Anchor, other, isRight and -30 or 30, 0, 1)
	sb.ButtonAnchor:Show()
	
	sb.ButtonBack = LUI:CreateMeAFrame("FRAME", nil, sb.ButtonAnchor, 273, 267, 1, "BACKGROUND", 0, other, sb.ButtonAnchor, other, isRight and 3 or -3, -2, 1)
	sb.ButtonBack:SetBackdrop({
		bgFile = fdir..fname.."_bt_back",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false,
		tileSize = 0,
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	sb.ButtonBack:SetBackdropColor(r, g, b, 1)
	sb.ButtonBack:SetBackdropBorderColor(0, 0, 0, 0)
	sb.ButtonBack:SetAlpha(0)
	sb.ButtonBack:Show()
	
	sb.ButtonBlock = LUI:CreateMeAFrame("FRAME", nil, sb.Anchor, 80, 225, 1, "MEDIUM", 4, other, sb.Anchor, other, isRight and -82 or 82, -5, 1)
	sb.ButtonBlock:EnableMouse(true)
	sb.ButtonBlock:Show()
	
	sb.ButtonClicker = LUI:CreateMeAFrame("BUTTON", nil, sb.ButtonAnchor, 30, 215, 1, "MEDIUM", 5, other, sb.ButtonAnchor, other, isRight and 6 or -6, -5, 1)
	sb.ButtonClicker:Show()

	sb.Button = LUI:CreateMeAFrame("FRAME", nil, sb.ButtonAnchor, 266, 251, 1, "BACKGROUND", 0, other, sb.ButtonAnchor, other, 0, -2, 1)
	sb.Button:SetBackdrop({
		bgFile = fdir..fname.."_button",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false,
		tileSize = 0,
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	sb.Button:SetBackdropColor(r, g, b, 1)
	sb.Button:SetBackdropBorderColor(0, 0, 0, 0)
	sb.Button:Show()
	
	sb.ButtonHover = LUI:CreateMeAFrame("FRAME", nil, sb.ButtonAnchor, 266, 251, 1, "BACKGROUND", 0, other, sb.ButtonAnchor, other, 0, -2, 1)
	sb.ButtonHover:SetBackdrop({
		bgFile = fdir..fname.."_button_hover",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false,
		tileSize = 0,
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	sb.ButtonHover:SetBackdropColor(r, g, b, 1)
	sb.ButtonHover:SetBackdropBorderColor(0, 0, 0, 0)
	sb.ButtonHover:Hide()
	
	sb.sidebaropen = 0
	
	sb.ButtonClicker:RegisterForClicks("AnyUp")
	sb.ButtonClicker:SetScript("OnClick", function(self)
		if sb.sidebaropen == 0 then
			sb.sidebaropen = 1
			bardb.IsOpen = true
			if bardb.OpenInstant then
				sb.ButtonAnchor:ClearAllPoints()
				sb.ButtonAnchor:SetPoint(other, sb.Anchor, other, isRight and -120 or 120, 0)
				sb.ButtonBack:SetAlpha(1)
				SidebarSetAlpha(sb.anchor, 1)
				for _, frame in pairs(Panels:LoadAdditional(bardb.Additional)) do
					SidebarSetAlpha(frame, 1)
				end
				sb.ButtonBlock:Hide()
			else
				sb.SlideOut:Show()
				sb.AlphaIn:Show()
				sb.ButtonBlock:Hide()
			end
		else
			sb.sidebaropen = 0
			bardb.IsOpen = false
			if bardb.OpenInstant then
				sb.ButtonAnchor:ClearAllPoints()
				sb.ButtonAnchor:SetPoint(other, sb.Anchor, other, isRight and -32 or 32, 0)
				sb.ButtonBack:SetAlpha(0)
				SidebarSetAlpha(sb.anchor, 0)
				for _, frame in pairs(Panels:LoadAdditional(bardb.Additional)) do
					SidebarSetAlpha(frame, 0)
				end
				sb.ButtonBlock:Show()
			else
				sb.SlideIn:Show()
				sb.AlphaOut:Show()
				SidebarSetAlpha(sb.anchor, 0)
				for _, frame in pairs(Panels:LoadAdditional(bardb.Additional)) do
					SidebarSetAlpha(frame, 0)
				end
				sb.ButtonBlock:Show()
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
	SidebarSetAlpha(sb.anchor, 0)
	for _, frame in pairs(Panels:LoadAdditional(bardb.Additional)) do
		SidebarSetAlpha(frame, 0)
	end
	
	if bardb.Enable then
		sb.Anchor:Show()
		if bardb.IsOpen == true then
			sb.sidebaropen = 1
			sb.SlideOut:Show()
			sb.AlphaIn:Show()
			sb.ButtonBlock:Hide()
		end
	else
		sb.Anchor:Hide()
	end
end

function module:SetBottomBar(id)
	local bardb = db["Bottombar"..id]
	
	if not bars[id] then
		local bar = CreateFrame("Frame", "LUIBar"..id, UIParent, "SecureHandlerStateTemplate")
		bar.buttons = {}
		
		for i = 1, 12 do
			local button = GetButton(bar, id, "Bottom", i)
			button:ClearAllPoints()
			if i == 1 then button:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0) end
			bar:SetFrameRef("Button"..i, button)
			bar.buttons[i] = button
			button.__IAB = true
			if button:GetName():find("LUI") then button.buttonType = "LUIBar"..id.."Button" end
		end
		
		local buttons
		
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
		
		RegisterStateDriver(bar, "page", GetBarState(id))
		
		if bardb.Fader.Enable then
			Fader:RegisterFrame(bar, bardb.Fader, true)
		end
		
		if Masque then
			local group = Masque:Group("LUI", "Bottom Bar "..id)
			for _, button in pairs(bar.buttons) do
				group:AddButton(button)
			end
		end
		
		bars[id] = bar
	end
	
	local bar = bars[id]
	
	bar:SetPoint(bardb.Point, UIParent, bardb.Point, bardb.X * bardb.Scale, bardb.Y * bardb.Scale)
	bar:SetScale(bardb.Scale)
	
	local numrows = math.ceil(bardb.NumButtons / bardb.NumPerRow)
	bar:SetWidth(bardb.NumPerRow * 36 + (bardb.NumPerRow - 1) * 2)
	bar:SetHeight(numrows * 36 + (numrows - 1) * 2)
	
	Configure(bar, bardb.NumButtons, bardb.NumPerRow)
	
	bar[bardb.Enable and "Show" or "Hide"](bar)
end

function module:SetSideBar(side, id)
	local bardb = db["Sidebar"..side..id]
	
	if not bars[side..id] then
		local bar = CreateFrame("Frame", "LUIBar"..side..id, UIParent, "SecureHandlerStateTemplate")
		bar:SetWidth(1) -- because of way LUI handles
		bar:SetHeight(1) -- sidebar position calculation
		bar.buttons = {}
		
		for i = 1, 12 do
			local button = GetButton(bar, id, side, i)
			button:ClearAllPoints()
			if i == 1 then button:SetPoint("TOPLEFT", bar, "TOPLEFT", 5, -3) end
			bar:SetFrameRef("Button"..i, button)
			bar.buttons[i] = button
			if button:GetName():find("LUI") then button.buttonType = "LUIBar"..side..id.."Button" end
		end
		
		local buttons
		
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
		
		RegisterStateDriver(bar, "page", bardb.State[1])
		
		if Masque then
			local group = Masque:Group("LUI", side.." Sidebar "..id)
			for _, button in pairs(bar.buttons) do
				group:AddButton(button)
			end
		end
		
		bars[side..id] = bar
	end
	
	local bar = bars[side..id]
	
	Configure(bar, 12, 2)
	
	bar:SetScale(bardb.Scale)
	
	bar[bardb.Enable and "Show" or "Hide"](bar)
end

function module:SetPetBar()
	if not LUIPetBar then
		local bar = CreateFrame("Frame", "LUIPetBar", UIParent, "SecureHandlerStateTemplate")
		bar.buttons = {}
		
		RegisterStateDriver(bar, "visibility", "[pet,novehicleui,nobonusbar:5] show; hide")

		PetActionBarFrame:SetParent(bar)
		PetActionBarFrame:EnableMouse(false)
		PetActionBarFrame.showgrid = 1
		PetActionBar_ShowGrid()

		local button
		for i = 1, NUM_PET_ACTION_SLOTS do
			local button = _G["PetActionButton"..i]
			button:SetParent(bar)
			
			if i == 1 then
				button:ClearAllPoints()
				button:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
			end
			bar.buttons[i] = button
		end
		
		if Masque then
			local group = Masque:Group("LUI", "Pet Bar")
			for i = 1, NUM_PET_ACTION_SLOTS do
				group:AddButton(_G["PetActionButton"..i])
			end
		end
	end
	
	local s = db.PetBar.Scale
	LUIPetBar:SetPoint(db.PetBar.Point, UIParent, db.PetBar.Point, db.PetBar.X * s, db.PetBar.Y * s)
	LUIPetBar:SetScale(s)
	
	local numrows = math.ceil(10 / db.PetBar.NumPerRow)
	LUIPetBar:SetWidth(db.PetBar.NumPerRow * 30 + (db.PetBar.NumPerRow - 1) * 2)
	LUIPetBar:SetHeight(numrows * 30 + (numrows - 1) * 2)
	
	Configure(LUIPetBar, 10, db.PetBar.NumPerRow)
	
	LUIPetBar[db.PetBar.Enable and "Show" or "Hide"](LUIPetBar)
end

function module:SetShapeshiftBar()
	if not LUIShapeshiftBar then
		local bar = CreateFrame("Frame", "LUIShapeshiftBar", UIParent, "SecureHandlerStateTemplate")
		bar.buttons = {}

		ShapeshiftBarFrame:SetParent(bar)
		ShapeshiftBarFrame:EnableMouse(false)
		
		local group = Masque and Masque:Group("LUI", "Shapeshift Bar") or nil

		local function MoveShapeshift()
			if InCombatLockdown() then return end
			
			bar:SetWidth(30 * NUM_SHAPESHIFT_SLOTS + 2 * (NUM_SHAPESHIFT_SLOTS - 1))
			
			local button, previous
			for i = 1, NUM_SHAPESHIFT_SLOTS do
				button = _G["ShapeshiftButton"..i]
				button:ClearAllPoints()
				button:SetParent(bar)
				
				if i == 1 then
					button:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
				else
					button:SetPoint("LEFT", previous, "RIGHT", 2, 0)
				end
				previous = button
				
				if group then
					group:AddButton(button) -- will return if button is already added
				end
			end
		end
		
		-- DO NOT CHANGE
		hooksecurefunc("ShapeshiftBar_Update", MoveShapeshift)
		hooksecurefunc("ShapeshiftBar_UpdateState", MoveShapeshift)
		
		if InCombatLockdown() then
			self:RegisterEvent("PLAYER_REGEN_ENABLED", function(event)
				self:UnregisterEvent(event)
				MoveShapeshift()
			end)
		else
			MoveShapeshift()
		end
	end
	
	local s = db.ShapeshiftBar.Scale
	LUIShapeshiftBar:SetPoint(db.ShapeshiftBar.Point, UIParent, db.ShapeshiftBar.Point, db.ShapeshiftBar.X * s, db.ShapeshiftBar.Y * s)
	LUIShapeshiftBar:SetScale(s)
	
	local numrows = math.ceil(10 / db.ShapeshiftBar.NumPerRow)
	LUIShapeshiftBar:SetWidth(db.ShapeshiftBar.NumPerRow * 30 + (db.ShapeshiftBar.NumPerRow - 1) * 2)
	LUIShapeshiftBar:SetHeight(numrows * 30 + (numrows - 1) * 2)
	
	Configure(LUIShapeshiftBar, 10, db.ShapeshiftBar.NumPerRow)
	
	LUIShapeshiftBar[db.ShapeshiftBar.Enable and "Show" or "Hide"](LUIShapeshiftBar)
end

function module:SetVehicleExit()
	if not LUIVehicleExit then
		local bar = CreateFrame("Frame", "LUIVehicleExit", UIParent, "SecureHandlerStateTemplate")
		bar:SetHeight(60)
		bar:SetWidth(60)
		
		RegisterStateDriver(bar, "visibility", "[vehicleui] show; hide")
		
		local veb = CreateFrame("Button", nil, bar, "SecureActionButtonTemplate")
		veb:SetAllPoints(bar)
		veb:RegisterForClicks("AnyUp")
		veb:SetNormalTexture("Interface\\Vehicles\\UI-Vehicles-Button-Exit-Up")
		veb:SetPushedTexture("Interface\\Vehicles\\UI-Vehicles-Button-Exit-Down")
		veb:SetHighlightTexture("Interface\\Vehicles\\UI-Vehicles-Button-Exit-Down")
		veb:SetScript("OnClick", function(self) VehicleExit() end)
		
		if not UnitInVehicle("player") then bar:Hide() end
	end
	
	local s = db.VehicleExit.Scale
	LUIVehicleExit:SetPoint(db.VehicleExit.Point, UIParent, db.VehicleExit.Point, db.VehicleExit.X * s, db.VehicleExit.Y * s)
	LUIVehicleExit:SetScale(s)
	
	LUIVehicleExit[db.VehicleExit.Enable and "Show" or "Hide"](LUIVehicleExit)
end

function module:HideBlizzard()
	MainMenuBar:SetScale(0.00001)
	MainMenuBar:EnableMouse(false)
	MainMenuBar:SetAlpha(0)
	MainMenuBar:UnregisterAllEvents()

	VehicleMenuBar:SetScale(0.00001)
	VehicleMenuBar:EnableMouse(false)
	VehicleMenuBar:SetAlpha(0)
	
	ShapeshiftBarFrame:SetScale(0.00001)
	ShapeshiftBarFrame:EnableMouse(false)
	ShapeshiftBarFrame:SetAlpha(0)

	PetActionBarFrame:SetScale(0.00001)
	PetActionBarFrame:EnableMouse(false)
	PetActionBarFrame:SetAlpha(0)

	local FramesToHide = {
		MainMenuBarArtFrame,
		BonusActionBarFrame,
		VehicleMenuBar,
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

	local totem = _G["MultiCastActionBarFrame"]

	if not totem then return end

	if not module:IsHooked(totem, "Show") then
		module:RawHook(totem, "Show", LUI.dummy, true)
	end
	totem:Hide()
end

function module:SetButtons()
	if Masque then
		isLibMasqueLoaded = true
		return
	end
	
	local mediaPath = [[Interface\AddOns\LUI\media\textures\buttons2\]]

	local normTex = mediaPath..[[Normal.tga]]
	local backdropTex = mediaPath..[[Backdrop.tga]]
	local glossTex = mediaPath..[[Gloss.tga]]
	local pushedTex = mediaPath..[[Normal.tga]]
	local checkedTex = mediaPath..[[Highlight.tga]]
	local highlightTex = mediaPath..[[Highlight.tga]]
	local flashTex = mediaPath..[[Overlay.tga]]
	local borderTex = mediaPath..[[Border.tga]]

	local font = [[Interface\Addons\LUI\media\fonts\vibrocen.ttf]]

	local dummy = function() end
	
	-- LibKeyBound stuff
	local function GetHotkey(button) return GetBindingKey("CLICK "..button:GetName()..":LeftButton") end
	
	local function Button_OnEnter(button)
		if button.GetHotkey then
			LibKeyBound:Set(button)
		end
	end
	
	-- buttons
	local function StyleButton(button)
		if not button then return end
		if button.__Styled == true then return end
				
		if button:GetParent() then
			local parent = button:GetParent():GetName()
			if parent == "MultiCastActionBarFrame" then return end
			if parent == "MultiCastActionPage1" then return end
			if parent == "MultiCastActionPage2" then return end
			if parent == "MultiCastActionPage3" then return end
		end
		
		local name = button:GetName()
		local size = button:GetWidth()
		local scale = size / 36
		
		button.GetHotkey = GetHotkey
		button:HookScript("OnEnter", Button_OnEnter)
		
		-- normal
		local normal = button:GetNormalTexture()
		normal:SetTexture("")
		normal:SetDrawLayer("BORDER", 0)
		normal:SetBlendMode("BLEND")
		normal:SetVertexColor(0.133, 0.133, 0.133, 0.95)
		normal:SetWidth(40 * scale)
		normal:SetHeight(40 * scale)
		normal:ClearAllPoints()
		normal:SetPoint("CENTER", button, "CENTER", 0, 0)
		normal.SetVertexColor = dummy
		normal.SetTexture = dummy
		normal.SetWidth = dummy
		normal.SetHeight = dummy
		normal.SetSize = dummy
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
	
		-- border
		local border = _G[name.."Border"]
		border:SetTexture(borderTex)
		border.SetTexture = dummy
		border:SetDrawLayer("ARTWORK", 0)
		border:SetBlendMode("ADD")
		border:SetWidth(40 * scale)
		border:SetHeight(40 * scale)
		border:ClearAllPoints()
		border:SetPoint("CENTER", button, "CENTER", 0, 0)
		
		border.Show_ = border.Show
		border.Show = function()
			button.__equipped = true
			if db.General.ShowEquipped then border:Show_() end
		end
		border.Hide_ = border.Hide
		border.Hide = function()
			button.__equipped = false
			border:Hide_()
		end
		
		if border:IsShown() then button.__equipped = true end
		if not db.General.ShowEquipped then border:Hide_() end
		
		-- autocast
		local autocast = _G[name.."Shine"]
		if autocast then
			autocast:SetWidth(34 * scale)
			autocast:SetHeight(34 * scale)
			autocast:ClearAllPoints()
			autocast:SetPoint("CENTER", button, "CENTER", 0, 0)
		end
		
		-- hotkey
		local hotkey = _G[name.."HotKey"]
		
		hotkey:SetFont(font, 12, "OUTLINE")
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
		macro:SetFont(font, 12, "OUTLINE")
		macro:SetDrawLayer("OVERLAY")
		macro:ClearAllPoints()
		macro:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 6)
		macro:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 6)
		macro:SetHeight(10)
		
		if not db.General.ShowMacro then macro:Hide() end
		
		-- count
		local count = _G[name.."Count"]
		count:SetFont(font, 14, "OUTLINE")
		count:SetDrawLayer("OVERLAY")
		count:ClearAllPoints()
		count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 6)
		count:SetWidth(40)
		count:SetHeight(10)
		
		if not db.General.ShowCount then count:Hide() end
	
		button.SetFrameLevel = dummy
		
		table.insert(buttonlist, button)
		button.__elapsed = 0
		button.__Styled = true
	end
	
	local function StylePetButtons()
		for i = 1, NUM_PET_ACTION_SLOTS do
			StyleButton(_G["PetActionButton"..i])
		end
	end
	
	local function StyleShapeshiftButtons()
		for i = 1, NUM_SHAPESHIFT_SLOTS do
			StyleButton(_G["ShapeshiftButton"..i])
		end
	end
	
	module:SecureHook("ActionButton_Update", StyleButton)
	module:SecureHook("PetActionBar_Update", StylePetButtons)
	module:SecureHook("ShapeshiftBar_Update", StyleShapeshiftButtons)
	module:SecureHook("ShapeshiftBar_UpdateState", StyleShapeshiftButtons)
	
	-- flyout
	local buttons = 0
	local function SetupFlyoutButton()
		for i = 1, buttons do
			if _G["SpellFlyoutButton"..i] then
				_G["SpellFlyoutButton"..i]:SetSize(30, 30)
				StyleButton(_G["SpellFlyoutButton"..i])
			end
		end
	end
	SpellFlyout:HookScript("OnShow", SetupFlyoutButton)

	local function StyleFlyout(self)
		self.FlyoutBorder:SetAlpha(0)
		self.FlyoutBorderShadow:SetAlpha(0)
		
		SpellFlyoutHorizontalBackground:SetAlpha(0)
		SpellFlyoutVerticalBackground:SetAlpha(0)
		SpellFlyoutBackgroundEnd:SetAlpha(0)
			
		for i = 1, GetNumFlyouts() do
			local _, _, numSlots, isKnown = GetFlyoutInfo(GetFlyoutID(i))
			if isKnown then
				buttons = numSlots
				break
			end
		end
		
		local arrowDistance
		if (SpellFlyout and SpellFlyout:IsShown() and SpellFlyout:GetParent() == self) or GetMouseFocus() == self then
			arrowDistance = 5
		else
			arrowDistance = 2
		end
		
		if self:GetParent():GetName() == "SpellBookSpellIconsFrame" then return end
		
		if self:GetAttribute("flyoutDirection") ~= nil then
			local point = self:GetParent():GetPoint()
			
			if not point then return end
			if point:find("BOTTOM") then
				self.FlyoutArrow:ClearAllPoints()
				self.FlyoutArrow:SetPoint("TOP", self, "TOP", 0, arrowDistance)
				SetClampedTextureRotation(self.FlyoutArrow, 0)
				if not InCombatLockdown() then self:SetAttribute("flyoutDirection", "UP") end
			elseif point:find("RIGHT") then
				self.FlyoutArrow:ClearAllPoints()
				self.FlyoutArrow:SetPoint("LEFT", self, "LEFT", -arrowDistance, 0)
				SetClampedTextureRotation(self.FlyoutArrow, 270)
				if not InCombatLockdown() then self:SetAttribute("flyoutDirection", "LEFT") end
			elseif point:find("LEFT") then
				self.FlyoutArrow:ClearAllPoints()
				self.FlyoutArrow:SetPoint("RIGHT", self, "RIGHT", arrowDistance, 0)
				SetClampedTextureRotation(self.FlyoutArrow, 90)
				if not InCombatLockdown() then self:SetAttribute("flyoutDirection", "RIGHT") end
			else
				self.FlyoutArrow:ClearAllPoints()
				self.FlyoutArrow:SetPoint("BOTTOM", self, "BOTTOM", 0, -arrowDistance)
				SetClampedTextureRotation(self.FlyoutArrow, 180)
				if not InCombatLockdown() then self:SetAttribute("flyoutDirection", "BOTTOM") end
			end
		end
	end
	module:SecureHook("ActionButton_UpdateFlyout", StyleFlyout)
	
	-- hotkey text replace
	-- only EN client :/
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
	module:SecureHook("ActionButton_UpdateHotkeys", UpdateHotkey)
	
	-- usable coloring on icon
	local function Button_OnUpdate(button, elapsed)
		if button.__elapsed > 0.2 then
			local icon = _G[button:GetName().."Icon"]
			local hotkey = _G[button:GetName().."HotKey"]
			
			if not icon then return end
			
			if IsActionInRange(button.action) ~= 0 then
				local isUsable, notEnoughMana = IsUsableAction(button.action)
				if isUsable then
					icon:SetVertexColor(1, 1, 1) -- action usable
				elseif notEnoughMana then
					icon:SetVertexColor(0.5, 0.5, 1) -- oom
				else
					icon:SetVertexColor(0.4, 0.4, 0.4) -- action not usable
				end
			else
				icon:SetVertexColor(0.8, 0.1, 0.1) -- out of range
			end
			button.__elapsed = 0
		else
			button.__elapsed = button.__elapsed + elapsed
		end
	end
	module:SecureHook("ActionButton_OnUpdate", Button_OnUpdate)
end

function module:SetLibKeyBound()
	function self:LIBKEYBOUND_ENABLED() self.keyBoundMode = true end

	function self:LIBKEYBOUND_DISABLED() self.keyBoundMode = nil end

	LibKeyBound.RegisterCallback(self, "LIBKEYBOUND_ENABLED")
	LibKeyBound.RegisterCallback(self, "LIBKEYBOUND_DISABLED")
	--LibKeyBound.RegisterCallback(self, "LIBKEYBOUND_MODE_COLOR_CHANGED")
end

function module:SetBars()
	if not (IsAddOnLoaded("Bartender4") or IsAddOnLoaded("Dominos") or IsAddOnLoaded("Macaroon")) and db.General.Enable then
		if not db.StatesLoaded then LoadStates(defaultstate) end
		
		self:SetLibKeyBound()
		
		for i = 1, 6 do
			self:SetBottomBar(i)
		end
		
		for i = 1, 2 do
			self:SetSideBar("Left", i)
			self:SetSideBar("Right", i)
		end
		
		self:SetPetBar()
		self:SetShapeshiftBar()
		
		self:SetVehicleExit()
		self:HideBlizzard()
		
		self:SetButtons()
		
		-- because of an ugly bug...
		module:SecureHook(CharacterFrame, "Show", function() TokenFrame_Update() end)
	else
		isBarAddOnLoaded = true
	end
	
	self:CreateBarBackground()
	self:CreateSidebarSlider("Right", 1)
	self:CreateSidebarSlider("Right", 2)
	self:CreateSidebarSlider("Left", 1)
	self:CreateSidebarSlider("Left", 2)
end

module.defaults = {
	profile = {
		StatesLoaded = false,
		General = {
			Enable = true,
			ShowHotkey = false,
			ShowMacro = false,
			ShowCount = true,
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
			X = 0,
			Y = 0,
			Scale = 0.85,
			State = {"0"},
		},
		Bottombar1 = {
			Enable = true,
			X = 0,
			Y = 28.8,
			Point = "BOTTOM",
			Scale = 0.85,
			NumPerRow = 12,
			NumButtons = 12,
			State = {
				[1] = "0",
				[2] = "0",
				[3] = "0",
				[4] = "0",
				[5] = "0",
				[6] = "0",
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
			Y = 74.7,
			Point = "BOTTOM",
			Scale = 0.85,
			NumPerRow = 12,
			NumButtons = 12,
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
			Y = 120.6,
			Point = "BOTTOM",
			Scale = 0.85,
			NumPerRow = 12,
			NumButtons = 12,
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
			Y = 166.5,
			Point = "BOTTOM",
			Scale = 0.85,
			NumPerRow = 12,
			NumButtons = 12,
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
			Y = 212.4,
			Point = "BOTTOM",
			Scale = 0.85,
			NumPerRow = 12,
			NumButtons = 12,
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
			Y = 258.3,
			Point = "BOTTOM",
			Scale = 0.85,
			NumPerRow = 12,
			NumButtons = 12,
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
		ShapeshiftBar = {
			Enable = true,
			X = 58.8,
			Y = -370.6,
			Point = "LEFT",
			Scale = 0.85,
			NumPerRow = 10,
		},
		PetBar = {
			Enable = true,
			X = -58.8,
			Y = -370.6,
			Point = "RIGHT",
			Scale = 0.85,
			NumPerRow = 10,
		},
		VehicleExit = {
			Enable = true,
			X = -350,
			Y = -220,
			Point = "CENTER",
			Scale = 1,
		},
	},
}

module.childGroups = "select"
module.getter = "generic"
module.setter = "Refresh"

function module:LoadOptions()
	local disabled = {
		TopTex = function() return not db.TopTexture.Enable end,
		TopTexAnim = function() return not db.TopTexture.Enable or not db.TopTexture.Animation end,
		BottomTex = function() return not db.BottomTexture.Enable end,
		["Shapeshift Bar"] = function() return not db.ShapeshiftBar.Enable end,
		["Pet Bar"] = function() return not db.PetBar.Enable end,
		["Vehicle Exit"] = function() return not db.VehicleExit.Enable end
	}
	
	local function getState(info)
		info[#info] = tonumber(info[#info]) or info[#info]
		local val = self.db(info)
		for k, v in pairs(info.option.values()) do
			if v == val then
				return k
			end
		end
	end
	local function setBottombarState(info, value)
		info[#info] = tonumber(info[#info]) or info[#info]
		self.db(info, info.option.values()[value])
		
		local id = tonumber(info[#info-2]:match("%d+"))
		UnregisterStateDriver(bars[id], "page")
		RegisterStateDriver(bars[id], "page", GetBarState(id))
	end
	local function setSidebarState(info, value)
		info[#info] = tonumber(info[#info]) or info[#info]
		local val = info.option.values()[value]
		self.db(info, val)
		
		local barname = gsub(info[#info-2], "Sidebar", "LUIBar")
		UnregisterStateDriver(_G[barname], "page")
		RegisterStateDriver(_G[barname], "page", val)
	end
	
	local function createBottomBarOptions(num, order)
		local disabledFunc = function() return not db["Bottombar"..num].Enable end
		
		local option = self:NewGroup("Bottom Bar "..num, order, false, InCombatLockdown, {
			Enable = (num ~= 1) and self:NewToggle("Show Bottom Bar "..num, nil, 1, true) or nil,
			header1 = self:NewHeader("General Settings", 2),
			[""] = self:NewPosSliders("Bottom Bar "..num, 3, false, "LUIBar"..num, true, nil, disabledFunc),
			Point = self:NewSelect("Point", "Choose the Point for your Bottom Bar "..num, 4, positions, nil, nil, nil, disabledFunc),
			empty1 = self:NewDesc(" ", 5),
			Scale = self:NewSlider("Scale", "Scale of Bottom Bar "..num..".", 6, 0.1, 1.5, 0.05, true, true, nil, disabledFunc),
			empty2 = self:NewDesc(" ", 7),
			NumPerRow = self:NewSlider("Buttons Per Row", "Choose the Number of Buttons per row for your Bottom Bar "..num..".", 8, 1, 12, 1, true, nil, nil, disabledFunc),
			NumButtons = self:NewSlider("Number of Buttons", "Choose the Number of Buttons for your Bottom Bar "..num..".", 9, 1, 12, 1, true, nil, nil, disabledFunc),
			State = self:NewGroup("State Settings", 10, getState, setBottombarState, true, {
				Alt = self:NewSelect("Alt", "Choose the Alt State for Bottom Bar "..num..".\n\nDefault: "..defaultstate["Bottombar"..num][1], 25, statelist, nil, false, nil, disabledFunc),
				Ctrl = self:NewSelect("Ctrl", "Choose the Ctrl State for Bottom Bar "..num..".\n\nDefault: "..defaultstate["Bottombar"..num][1], 26, statelist, nil, false, nil, disabledFunc),
			}),
			Fader = self:NewGroup("Fader", 11, true, disabledFunc, Fader:CreateFaderOptions(_G["LUIBar"..num], db["Bottombar"..num].Fader, dbd["Bottombar"..num].Fader)),
		})
		
		if num == 1 then
			for i, name in ipairs(statetext) do
				option.args.State.args[tostring(i)] = self:NewSelect(name, "Choose the State for "..name..".\n\nDefaults:\nLUI: "..defaultstate.Bottombar1[i].."\nBlizzard: "..blizzstate.Bottombar1[i],
					i, statelist, nil, false, nil, disabledFunc)
			end
		else
			option.args.State.args["1"] = self:NewSelect("Default", "Choose the State for Bottom Bar "..num..".\n\nDefaults:\nLUI: "..defaultstate["Bottombar"..num][1].."\nBlizzard: "..blizzstate["Bottombar"..num][1],
				1, statelist, nil, false, nil, disabledFunc)
		end
		
		return option
	end
	
	local function createSideBarOptions(side, num, order)
		local disabledFunc = function() return not db["Sidebar"..side..num].Enable end
		local disabledPosFunc = function() return not db["Sidebar"..side..num].Enable or (isBarAddOnLoaded and not db["Sidebar"..side..num].AutoPosEnable) end
		
		local option = self:NewGroup(side.." Bar "..num, order, false, InCombatLockdown, {
			Enable = self:NewToggle("Show "..side.." Bar "..num, nil, 1, true),
			header1 = self:NewHeader("Anchor Settings", 2),
			Intro = isBarAddOnLoaded and self:NewDesc("Which Bar do you want to use for this Sidebar?\nChoose one or type in the MainAnchor manually.\n\nMake sure your Bar is set to 6 buttons/2 columns and isn't used for another Sidebar.\nLUI will position your Bar automatically.", 3) or nil,
			AnchorDropDown = isBarAddOnLoaded and self:NewSelect("Anchor", nil, 4, barAnchors) or nil,
			Anchor = isBarAddOnLoaded and self:NewInput("Anchor", "Choose the Bar for this Sidebar.", 5, nil, nil, disabledFunc) or nil,
			Additional = self:NewInput("Additional Frames", "Type in any additional frame names (seperated by commas), that you would like to show/hide with the Sidebar.", 6, true, nil, disabledFunc),
			header2 = self:NewHeader("General Settings", 7),
			[""] = self:NewPosSliders(side.." Bar "..num, 8, false, function() return sidebars[side..num].Anchor end, true, nil, disabledPosFunc),
			Scale = self:NewSlider("Scale", "Choose the Scale for this Sidebar.", 9, 0.1, 1.5, 0.05, true, true, nil, disabledFunc),
			AutoPosEnable = isBarAddOnLoaded and self:NewToggle("Stop touching me!", "Whether or not to have LUI handle your Bar Positioning.", 10, true, nil, disabledFunc) or nil,
			header3 = self:NewHeader("Additional Settings", 11),
			Offset = self:NewInputNumber("Y Offset", "Y Offset for your Sidebar", 12, true, nil, disabledFunc),
			OpenInstant = self:NewToggle("Open Instant", "Whether or not to show an open/close animation.", 13, true, nil, disabledFunc),
			State = not isBarAddOnLoaded and self:NewGroup("State Settings", 14, getState, setSidebarState, true, {
				["1"] = self:NewSelect("Default", "Choose the State for "..side.." Bar "..num..".\n\nDefaults:\nLUI: "..defaultstate["Sidebar"..side..num][1].."\nBlizzard: "..blizzstate["Sidebar"..side..num][1],
					1, statelist, nil, false, nil, disabledFunc),
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
	
	local function createOtherBarOptions(name, order, frame)
		local option = self:NewGroup(name, order, false, InCombatLockdown, {
			Enable = self:NewToggle("Show "..name, nil, 1, true),
			[""] = self:NewPosSliders(name, 2, false, frame, true, nil, disabled[name]),
			Point = self:NewSelect("Point", "Choose the Point for the "..name..".", 3, positions, nil, nil, nil, disabled[name]),
			Scale = self:NewSlider("Scale", "Choose the Scale for the "..name..".", 4, 0.1, 1.5, 0.05, true, true, nil, nil, disabled[name]),
			NumPerRow = (name ~= "Vehicle Exit Button") and self:NewSlider("Buttons per Row", "Choose the Number of Buttons per Row.", 5, 1, 10, 1, true, nil, nil, nil, disabled[name]) or nil,
		})
		
		return option
	end
	
	local options = {
		General = self:NewGroup("General", 1, false, InCombatLockdown, {
			Enable = self:NewToggle("Enable", "Whether or not to use LUI's Action Bars.", 1, function() StaticPopup_Show("RELOAD_UI") end), -- not sure how the api will take this
			empty1 = self:NewDesc(" ", 2),
			ShowHotkey = self:NewToggle("Show Hotkey Text", nil, 3, true, nil, nil, isLibMasqueLoaded or isBarAddOnLoaded),
			ShowMacro = self:NewToggle("Show Macro Text", nil, 4, true, nil, nil, isLibMasqueLoaded or isBarAddOnLoaded),
			ShowCount = self:NewToggle("Show Count Text", nil, 5, true, nil, nil, isLibMasqueLoaded or isBarAddOnLoaded),
			empty2 = self:NewDesc(" ", 6, nil, nil, isLibMasqueLoaded or isBarAddOnLoaded),
			ShowEquipped = self:NewToggle("Show Equipped Border", nil, 7, true, nil, nil, isLibMasqueLoaded or isBarAddOnLoaded),
			empty3 = self:NewDesc(" ", 8, nil, nil, isLibMasqueLoaded or isBarAddOnLoaded),
			LoadBlizz = self:NewExecute("Load Blizzard States", "Load the Blizzard Default Bar States.", 9, function() LoadStates(blizzstate); module:Refresh() end, nil, nil, isBarAddOnLoaded, isBarAddOnLoaded),
			LoadLUI = self:NewExecute("Load LUI States", "Load the LUI Default Bar States.", 10, function() LoadStates(defaultstate); module:Refresh() end, nil, nil, isBarAddOnLoaded, isBarAddOnLoaded),
			empty3 = self:NewDesc(" ", 11, nil, nil, isBarAddOnLoaded),
			ToggleKB = self:NewExecute("Keybinds", "Toggles Keybinding mode.", 12, function() LibKeyBound:Toggle() end, nil, nil, isBarAddOnLoaded, isBarAddOnLoaded),
		}),
		TopTexture = self:NewGroup("Top Texture", 2, false, InCombatLockdown, {
			Enable = self:NewToggle("Enable", "Whether or not to show the Top Bar Texture.", 1, true),
			Alpha = self:NewSlider("Alpha", "Choose your Top Bar Texture Alpha.", 2, nil, nil, nil, true, true, nil, disabled.TopTex),
			empty1 = self:NewDesc(" ", 3),
			[""] = self:NewPosSliders("Top Bar Texture", 4, false, "LUIBarsTopBG", nil, nil, disabled.TopTex),
			Animation = self:NewToggle("Enable Texture Animation", "Whether or not to show the Texture Animation.", 5, true, nil, disabled.TopTex, not LUI.isForteCooldownLoaded),
			AnimationHeight = self:NewInputNumber("Animation Height", "Choose the Top Bar Texture Animation Height.", 6, nil, nil, disabled.TopTexAnim, not LUI.isForteCooldownLoaded),
		}),
		BottomTexture = self:NewGroup("Bottom Texture", 3, false, InCombatLockdown, {
			Enable = self:NewToggle("Enable", "Whether or not to show the Bottom Bar Texture.", 1, true),
			Alpha = self:NewSlider("Alpha", "Choose your Bottom Bar Texture Alpha.", 2, nil, nil, nil, true, true, nil, disabled.BottomTex),
			empty1 = self:NewDesc(" ", 3),
			[""] = self:NewPosSliders("Bottom Bar Texture", 4, false, "LUIBarsBottomBG", nil, nil, disabled.BottomTex),
		}),
		Bottombar1 = not isBarAddOnLoaded and createBottomBarOptions(1, 4) or nil,
		Bottombar2 = not isBarAddOnLoaded and createBottomBarOptions(2, 5) or nil,
		Bottombar3 = not isBarAddOnLoaded and createBottomBarOptions(3, 6) or nil,
		Bottombar4 = not isBarAddOnLoaded and createBottomBarOptions(4, 7) or nil,
		Bottombar5 = not isBarAddOnLoaded and createBottomBarOptions(5, 8) or nil,
		Bottombar6 = not isBarAddOnLoaded and createBottomBarOptions(6, 9) or nil,
		SidebarRight1 = createSideBarOptions("Right", 1, 10),
		SidebarRight2 = createSideBarOptions("Right", 2, 11),
		SidebarLeft1 = createSideBarOptions("Left", 1, 12),
		SidebarLeft2 = createSideBarOptions("Left", 2, 13),
		ShapeshiftBar = not isBarAddOnLoaded and createOtherBarOptions("Shapeshift Bar", 14, "LUIShapeshiftBar") or nil,
		PetBar = not isBarAddOnLoaded and createOtherBarOptions("Pet Bar", 15, "LUIPetBar") or nil,
		VehicleExit = not isBarAddOnLoaded and createOtherBarOptions("Vehicle Exit Button", 16, "LUIVehicleExit") or nil,
	}
	
	return options
end

function module:Refresh(...)
	local info, value = ...
	if type(info) == "table" and type(value) ~= "table" then
		db(info, value)
	end
	
	if not isBarAddOnLoaded then
		for i = 1, 6 do
			self:SetBottomBar(i)
		end
		
		for i = 1, 2 do
			self:SetSideBar("Left", i)
			self:SetSideBar("Right", i)
		end
		
		self:SetPetBar()
		self:SetShapeshiftBar()
		self:SetVehicleExit()
	end
	
	LUIBarsTopBG:SetAlpha(db.TopTexture.Alpha)
	LUIBarsTopBG:ClearAllPoints()
	LUIBarsTopBG:SetPoint("BOTTOM", UIParent, "BOTTOM", db.TopTexture.X, db.TopTexture.Y)
	LUIBarsTopBG[db.TopTexture.Enable and "Show" or "Hide"](LUIBarsTopBG)
	
	if Forte:IsEnabled() and Forte.db.Cooldown.Lock then
		local FXCD = FX_Cooldown1
		if FXCD and FXCD:IsShown() then
			LUIBarsTopBG:SetPoint("BOTTOM", UIParent, "BOTTOM", db.TopTexture.X, db.TopTexture.Y + db.TopTexture.AnimationHeight)
		end
	end
	
	LUIBarsBottomBG:SetAlpha(db.BottomTexture.Alpha)
	LUIBarsBottomBG:ClearAllPoints()
	LUIBarsBottomBG:SetPoint("BOTTOM", UIParent, "BOTTOM", db.BottomTexture.X, db.BottomTexture.Y)
	LUIBarsBottomBG[db.BottomTexture.Enable and "Show" or "Hide"](LUIBarsBottomBG)
	
	for _, button in pairs(buttonlist) do
		local name = button:GetName()
		
		local count = _G[name.."Count"]
		if db.General.ShowCount then
			if count then count:Show() end
		else
			if count then count:Hide() end
		end
		
		local hotkey = _G[name.."HotKey"]
		if db.General.ShowHotkey then
			if hotkey then hotkey:Show() end
		else
			if hotkey then hotkey:Hide() end
		end
		
		local macro = _G[name.."Name"]
		if db.General.ShowMacro then
			if macro then macro:Show() end
		else
			if macro then macro:Hide() end
		end
		
		local border = _G[name.."Border"]
		if db.General.ShowEquipped and button.action and IsEquippedAction(button.action) then
			border:Show()
		else
			border:Hide()
		end
	end
	
	SidebarSetAnchor("Left", 1)
	SidebarSetAnchor("Left", 2)
	SidebarSetAnchor("Right", 1)
	SidebarSetAnchor("Right", 2)
end

function module:OnInitialize()
	db, dbd = LUI:NewNamespace(self)
	
	if LUICONFIG.Versions.bars ~= LUI.Versions.bars then
		db:ResetProfile()
		LUICONFIG.Versions.bars = LUI.Versions.bars
	end
end

function module:OnEnable()
	module:SetBars()
end

function module:OnDisable()
end
