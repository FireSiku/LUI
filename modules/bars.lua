--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: bars.lua
	Description: Bars Module
	Version....: 2.0
	Rev Date...: 30/03/11 [dd/mm/yy]
]] 

local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local LSM = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists
local LUIHook = LUI:GetModule("LUIHook")
local Panels = LUI:GetModule("Panels")
local module = LUI:NewModule("Bars", "AceHook-3.0")
local LibKeyBound = LibStub("LibKeyBound-1.0")

local db
local fdir = "Interface\\AddOns\\LUI\\media\\templates\\v3\\"

local _, class = UnitClass("player")

local buttonlist = {}

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

local isBarAddOnLoaded

local statetexts = {
	["DRUID"] = {"Default", "Bear Form", "Cat Form", "Cat Form (Prowl)", "Moonkin Form", "Tree of Life Form"},
	["WARRIOR"] = {"Default", "Battle Stance", "Defensive Stance", "Berserker Stance"},
	["PRIEST"] = {"Default", "Shadow Form"},
	["ROGUE"] = {"Default", "Stealth", "Shadowdance"},
	["WARLOCK"] = {"Default", "Metamorphosis"},
	["DEFAULT"] = {"Default"},
}
local statetext = statetexts[class] or statetexts["DEFAULT"]

local defaultstates = {
	["DRUID"] = {"1", "3", "5", "5", "4", "6"},
	["WARRIOR"] = {"1", "3", "5", "4"},
	["PRIEST"] = {"1", "3"},
	["ROGUE"] = {"1", "3", "5"},
	["WARLOCK"] = {"1", "3"},
	["DEFAULT"] = {"1"}
}
local defaultstate = {
	Bottombar1 = defaultstates[class] or defaultstates["DEFAULT"],
	Bottombar2 = "2",
	Bottombar3 = "3",
	SidebarLeft = "9",
	SidebarRight = "10",
}

local blizzstates = {
	["DRUID"] = {"1", "7", "8", "8", "9", "10"},
	["WARRIOR"] = {"1", "7", "8", "9"},
	["PRIEST"] = {"1", "7"},
	["ROGUE"] = {"1", "7", "8"},
	["WARLOCK"] = {"1", "7"},
	["DEFAULT"] = {"1"}
}
local blizzstate = {
	Bottombar1 = blizzstates[class] or blizzstates["DEFAULT"],
	Bottombar2 = "6",
	Bottombar3 = "5",
	SidebarLeft = "3",
	SidebarRight = "4"
}

local function LoadStates(data)
	if type(data) ~= "table" then return end
	for k, v in pairs(data) do
		if type(v) == "table" then
			for k2, v2 in pairs(v) do
				db.Bars[k].State[k2] = v2
			end
		else
			db.Bars[k].State = v
		end
	end
end

local function GetAnchorStatus(anchor)
	if strmatch(anchor, "Dominos") then
		if IsAddOnLoaded("Dominos") then
			anchor = Dominos.ActionBar:Get(string.match(anchor, "%d+"))
			return anchor:IsShown()
		end
	else
		if _G[anchor] then return _G[anchor]:IsShown() end
	end
end

local function SidebarSetAlpha(anchor,alpha)
	if strmatch(anchor, "Dominos") then
		if IsAddOnLoaded("Dominos") then
			anchor = Dominos.ActionBar:Get(string.match(anchor, "%d+"))
			anchor:SetAlpha(alpha)
		end
	else
		if GetAnchorStatus(anchor) then _G[anchor]:SetAlpha(alpha) end
	end
end

local function SetLeftSidebarAnchor()
	if db.Bars.SidebarLeft.AutoPosEnable ~= true and isBarAddOnLoaded == true then return end
	
	local anchor = isBarAddOnLoaded and db.Bars.SidebarLeft.Anchor or "LUIBarLeft"
	local xOffset = db.Bars.SidebarLeft.X
	local yOffset = db.Bars.SidebarLeft.Y
	local sbOffset = db.Bars.SidebarLeft.Offset
	
	if GetAnchorStatus(anchor) then
		if strmatch(anchor, "Dominos") then
			if IsAddOnLoaded("Dominos") then
				anchor = Dominos.ActionBar:Get(string.match(anchor, "%d+"))
				local scale = anchor:GetEffectiveScale()
				local scaleUI = UIParent:GetEffectiveScale()

				local x = tonumber(xOffset) + ( scaleUI * math.floor( 20 / scale ) )
				local y = tonumber(yOffset) + ( scaleUI * math.floor( 157 + tonumber(sbOffset) / scale ) )
				
				anchor:SetFrameStrata("BACKGROUND")
				anchor:SetFrameLevel(2)
				anchor:ClearAllPoints()
				anchor:SetPoint("LEFT", UIParent, "LEFT", x, y)
			end
		else
			anchor = _G[anchor]
			local scale = anchor:GetEffectiveScale()
			local scaleUI = UIParent:GetEffectiveScale()

			local x = tonumber(xOffset) + ( scaleUI * math.floor( 20 / scale ) )
			local y = tonumber(yOffset) + ( scaleUI * math.floor( 157 + tonumber(sbOffset) / scale ) )
			
			anchor:SetFrameStrata("BACKGROUND")
			anchor:SetFrameLevel(2)
			anchor:ClearAllPoints()
			anchor:SetPoint("LEFT", UIParent, "LEFT", x, y)
		end
	end
end

local function SetRightSidebarAnchor()
	if db.Bars.SidebarRight.AutoPosEnable ~= true and isBarAddOnLoaded == true then return end

	local anchor = isBarAddOnLoaded and db.Bars.SidebarRight.Anchor or "LUIBarRight"
	local xOffset = db.Bars.SidebarRight.X
	local yOffset = db.Bars.SidebarRight.Y
	local sbOffset = db.Bars.SidebarRight.Offset

	if GetAnchorStatus(anchor) then
		if strmatch(anchor, "Dominos") then
			if IsAddOnLoaded("Dominos") then
				anchor = Dominos.ActionBar:Get(string.match(anchor, "%d+"))
				local scale = anchor:GetEffectiveScale()
				local scaleUI = UIParent:GetEffectiveScale()

				local x = tonumber(xOffset) + ( scaleUI * math.floor( -90 / scale ) )
				local y = tonumber(yOffset) + ( scaleUI * math.floor( 157 + tonumber(sbOffset) / scale ) )
				
				anchor:SetFrameStrata("BACKGROUND")
				anchor:SetFrameLevel(2)
				anchor:ClearAllPoints()
				anchor:SetPoint("RIGHT",UIParent,"RIGHT",x,y)
			end
		else
			anchor = _G[anchor]
			local scale = anchor:GetEffectiveScale()
			local scaleUI = UIParent:GetEffectiveScale()

			local x = tonumber(xOffset) + ( scaleUI * math.floor( -90 / scale ) )
			local y = tonumber(yOffset) + ( scaleUI * math.floor( 157 + tonumber(sbOffset) / scale ) )
			
			anchor:SetFrameStrata("BACKGROUND")
			anchor:SetFrameLevel(2)
			anchor:ClearAllPoints()
			anchor:SetPoint("RIGHT",UIParent,"RIGHT",x,y)
		end
	end
end

function module:SetBarColors()
	BarsBackground:SetBackdropColor(unpack(db.Colors.bar))
	BarsBackground2:SetBackdropColor(unpack(db.Colors.bar2))
end

function module:CreateBarBackground()
	-- SET BARS TOP TEXTURE
	local BarsBackground = LUI:CreateMeAFrame("FRAME","BarsBackground",UIParent,1024,1024,1,"BACKGROUND",2,"BOTTOM",UIParent,"BOTTOM",200,-70,1)
	BarsBackground:SetBackdrop({
		bgFile=fdir.."bars_top",
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
		tile=false, edgeSize=1, 
		insets={left=0, right=0, top=0, bottom=0}
	})
	BarsBackground:SetBackdropColor(unpack(db.Colors.bar))
	BarsBackground:SetBackdropBorderColor(0,0,0,0)
	BarsBackground:ClearAllPoints()
	BarsBackground:SetPoint("BOTTOM", UIParent, "BOTTOM", tonumber(db.Bars.TopTexture.X), tonumber(db.Bars.TopTexture.Y))
	BarsBackground:SetAlpha(db.Bars.TopTexture.Alpha)
	
	if db.Bars.TopTexture.Enable == true then
		BarsBackground:Show()
	else
		BarsBackground:Hide()
	end
	
	-- SET BARS BOTTOM TEXTURE
	local BarsBackground2 = LUI:CreateMeAFrame("FRAME","BarsBackground2",UIParent,1024,1024,1,"BACKGROUND",0,"BOTTOM",UIParent,"BOTTOM",210,-145,1)
	BarsBackground2:SetBackdrop({
		bgFile=fdir.."bars_bottom", 
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		tile=false, edgeSize=1,
		insets={left=0, right=0, top=0, bottom=0}
	})
	BarsBackground2:SetBackdropColor(unpack(db.Colors.bar2))
	BarsBackground2:SetBackdropBorderColor(0,0,0,0)	
	BarsBackground2:ClearAllPoints()
	BarsBackground2:SetPoint("BOTTOM", UIParent, "BOTTOM", tonumber(db.Bars.BottomTexture.X), tonumber(db.Bars.BottomTexture.Y))
	BarsBackground2:SetAlpha(db.Bars.BottomTexture.Alpha)
	
	if db.Bars.BottomTexture.Enable == true then
		BarsBackground2:Show()
	else
		BarsBackground2:Hide()
	end
end

function module:SetSidebarColors()
	local sidebar_r, sidebar_g, sidebar_b, sidebar_a = unpack(db.Colors.sidebar)
	
	fsidebar_back:SetBackdropColor(sidebar_r,sidebar_g,sidebar_b,sidebar_a)
	fsidebar_back2:SetBackdropColor(sidebar_r,sidebar_g,sidebar_b,sidebar_a)
	fsidebar_bt_back:SetBackdropColor(sidebar_r,sidebar_g,sidebar_b,1)
	fsidebar_button:SetBackdropColor(sidebar_r,sidebar_g,sidebar_b,1)
	fsidebar_button_hover:SetBackdropColor(sidebar_r,sidebar_g,sidebar_b,1)
	
	fsidebar2_back:SetBackdropColor(sidebar_r,sidebar_g,sidebar_b,sidebar_a)
	fsidebar2_back2:SetBackdropColor(sidebar_r,sidebar_g,sidebar_b,sidebar_a)
	fsidebar2_bt_back:SetBackdropColor(sidebar_r,sidebar_g,sidebar_b,1)
	fsidebar2_button:SetBackdropColor(sidebar_r,sidebar_g,sidebar_b,1)
	fsidebar2_button_hover:SetBackdropColor(sidebar_r,sidebar_g,sidebar_b,1)
end

function module:CreateRightSidebar()
	local RightAnchor = isBarAddOnLoaded and db.Bars.SidebarRight.Anchor or "LUIBarRight"
	local isRightSidebarCreated = false
	local sidebar_r, sidebar_g, sidebar_b, sidebar_a = unpack(db.Colors.sidebar)
	
	if isRightSidebarCreated == false or isRightSidebarCreated == nil then
		local isRightSidebarCreated = true
		------------------------------------------------------
		-- / OPEN / CLOSE RIGHT SIDEBAR / --
		------------------------------------------------------
		local fsidebar_timerout,fsidebar_timerin = 0,0
		local fsidebar_y = 0
		local fsidebar_x = -30
		local fsidebar_xout = -118 
		local fsidebar_pixelpersecond = -176
		local fsidebar_animation_time = 0.5
		
		local fsidebar_SlideOut = CreateFrame("Frame", "fsidebar_SlideOut", UIParent)
		fsidebar_SlideOut:Hide()
		
		fsidebar_SlideOut:SetScript("OnUpdate", function(self,elapsed)
			fsidebar_timerout = fsidebar_timerout + elapsed
			if fsidebar_timerout < fsidebar_animation_time then
				local x2 = fsidebar_x + fsidebar_timerout * fsidebar_pixelpersecond
				fsidebar_button_anchor:ClearAllPoints()
				fsidebar_button_anchor:SetPoint("LEFT", fsidebar_anchor, "LEFT", x2, fsidebar_y)
			else
				fsidebar_button_anchor:ClearAllPoints()
				fsidebar_button_anchor:SetPoint("LEFT", fsidebar_anchor, "LEFT", fsidebar_xout, fsidebar_y)
				fsidebar_timerout = 0
				fsidebar_bt_AlphaIn:Show()
				self:Hide()
			end
		end)
		
		local fsidebar_SlideIn = CreateFrame("Frame", "fsidebar_SlideIn", UIParent)
		fsidebar_SlideIn:Hide()
		
		fsidebar_SlideIn:SetScript("OnUpdate", function(self,elapsed)
			fsidebar_timerin = fsidebar_timerin + elapsed
			if fsidebar_timerin < fsidebar_animation_time then
				local x2 = fsidebar_x - fsidebar_timerin * fsidebar_pixelpersecond + fsidebar_pixelpersecond * fsidebar_animation_time
				fsidebar_button_anchor:ClearAllPoints()
				fsidebar_button_anchor:SetPoint("LEFT", fsidebar_anchor, "LEFT", x2, fsidebar_y)
			else
				fsidebar_button_anchor:ClearAllPoints()
				fsidebar_button_anchor:SetPoint("LEFT", fsidebar_anchor, "LEFT", fsidebar_x, fsidebar_y)
				fsidebar_timerin = 0
				self:Hide()
			end
		end)
		
		local fsidebar_alpha_timerout, fsidebar_alpha_timerin = 0,0
		local fsidebar_speedin = 0.9
		local fsidebar_speedout = 0.3
		
		local fsidebar_AlphaIn = CreateFrame("Frame", "fsidebar_AlphaIn", UIParent)
		fsidebar_AlphaIn:Hide()
		
		fsidebar_AlphaIn:SetScript("OnUpdate", function(self,elapsed)
			fsidebar_alpha_timerin = fsidebar_alpha_timerin + elapsed
			if fsidebar_alpha_timerin < fsidebar_speedin then
				local alpha = fsidebar_alpha_timerin / fsidebar_speedin 
				fsidebar_bt_back:SetAlpha(alpha)
			else
				fsidebar_bt_back:SetAlpha(1)
				fsidebar_alpha_timerin = 0
				self:Hide()
			end
		end)
		
		local fsidebar_AlphaOut = CreateFrame("Frame", "fsidebar_AlphaOut", UIParent)
		fsidebar_AlphaOut:Hide()
		
		fsidebar_AlphaOut:SetScript("OnUpdate", function(self,elapsed)
			fsidebar_alpha_timerout = fsidebar_alpha_timerout + elapsed
			if fsidebar_alpha_timerout < fsidebar_speedout then
				local alpha = 1 - fsidebar_alpha_timerout / fsidebar_speedout
				fsidebar_bt_back:SetAlpha(alpha)
			else
				fsidebar_bt_back:SetAlpha(0)
				fsidebar_alpha_timerout = 0
				self:Hide()
			end
		end)
		
		local fsidebar_bt_timerin = 0
		local fsidebar_bt_speedin = 0.3
		
		local fsidebar_bt_AlphaIn = CreateFrame("Frame", "fsidebar_bt_AlphaIn", UIParent)
		fsidebar_bt_AlphaIn:Hide()
		
		fsidebar_bt_AlphaIn:SetScript("OnUpdate", function(self,elapsed)
			fsidebar_bt_timerin = fsidebar_bt_timerin + elapsed
			if fsidebar_bt_timerin < fsidebar_bt_speedin then
				local alpha = fsidebar_bt_timerin / fsidebar_bt_speedin
				SidebarSetAlpha(RightAnchor,alpha)
				
				for _, frame in pairs(Panels:LoadAdditional(db.Bars.SidebarRight.Additional)) do
					SidebarSetAlpha(frame, alpha)
				end
			else
				SidebarSetAlpha(RightAnchor,1)
				for _, frame in pairs(Panels:LoadAdditional(db.Bars.SidebarRight.Additional)) do
					SidebarSetAlpha(frame, 1)
				end
				fsidebar_bt_timerin = 0
				self:Hide()
			end
		end)
		
		------------------------------------------------------
		-- / RIGHT SIDEBAR FRAMES / --
		------------------------------------------------------
		
		fsidebar_anchor = LUI:CreateMeAFrame("FRAME","fsidebar_anchor",UIParent,25,25,1,"BACKGROUND",0,"RIGHT",UIParent,"RIGHT",11,db.Bars.SidebarRight.Offset,1)
		fsidebar_anchor:SetBackdrop({
			bgFile="Interface\\Tooltips\\UI-Tooltip-Background", 
			edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
			tile=false, edgeSize=1, 
			insets={left=0, right=0, top=0, bottom=0}
		})
		fsidebar_anchor:SetBackdropColor(0,0,0,0)
		fsidebar_anchor:SetBackdropBorderColor(0,0,0,0)
		fsidebar_anchor:Show() 
		
		local fsidebar = LUI:CreateMeAFrame("FRAME","fsidebar",fsidebar_anchor,512,512,1,"BACKGROUND",2,"LEFT",fsidebar_anchor,"LEFT",-17,0,1)
		fsidebar:SetBackdrop({
			bgFile=fdir.."sidebar", 
			edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
			tile=false, edgeSize=1, 
			insets={left=0, right=0, top=0, bottom=0}
		})
		fsidebar:SetBackdropBorderColor(0,0,0,0)
		fsidebar:Show()
		
		local fsidebar_back = LUI:CreateMeAFrame("FRAME","fsidebar_back",fsidebar_anchor,512,512,1,"BACKGROUND",1,"LEFT",fsidebar_anchor,"LEFT",-25,0,1)
		fsidebar_back:SetBackdrop({
			bgFile=fdir.."sidebar_back", 
			edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
			tile=false, edgeSize=1, 
			insets={left=0, right=0, top=0, bottom=0}
		})
		fsidebar_back:SetBackdropColor(sidebar_r,sidebar_g,sidebar_b,sidebar_a)
		fsidebar_back:SetBackdropBorderColor(0,0,0,0)
		fsidebar_back:Show()
		
		local fsidebar_back2 = LUI:CreateMeAFrame("FRAME","fsidebar_back2",fsidebar_anchor,512,512,1,"BACKGROUND",1,"LEFT",fsidebar_anchor,"LEFT",-25,0,1)
		fsidebar_back2:SetBackdrop({
			bgFile=fdir.."sidebar_back2", 
			edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
			tile=false, edgeSize=1,
			insets={left=0, right=0, top=0, bottom=0}
		})
		fsidebar_back2:SetBackdropColor(sidebar_r,sidebar_g,sidebar_b,sidebar_a)
		fsidebar_back2:SetBackdropBorderColor(0,0,0,0)
		fsidebar_back2:Show()
		
		local fsidebar_button_anchor=LUI:CreateMeAFrame("FRAME","fsidebar_button_anchor",fsidebar_anchor,10,10,1,"BACKGROUND",0,"LEFT",fsidebar_anchor,"LEFT",-30,0,1)
		fsidebar_button_anchor:SetBackdrop({
			bgFile="Interface\\Tooltips\\UI-Tooltip-Background", 
			edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
			tile=false, edgeSize=1, 
			insets={left=0, right=0, top=0, bottom=0}
		})
		fsidebar_button_anchor:SetBackdropColor(0,0,0,0)
		fsidebar_button_anchor:SetBackdropBorderColor(0,0,0,0)
		fsidebar_button_anchor:Show()
		
		local fsidebar_bt_back = LUI:CreateMeAFrame("FRAME","fsidebar_bt_back",fsidebar_button_anchor,273,267,1,"BACKGROUND",0,"LEFT",fsidebar_button_anchor,"LEFT",3,-2,1)
		fsidebar_bt_back:SetBackdrop({
			bgFile=fdir.."sidebar_bt_back", 
			edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
			tile=false, edgeSize=1, 
			insets={left=0, right=0, top=0, bottom=0}
		})
		fsidebar_bt_back:SetBackdropColor(sidebar_r,sidebar_g,sidebar_b,1)
		fsidebar_bt_back:SetBackdropBorderColor(0,0,0,0)
		fsidebar_bt_back:SetAlpha(0)
		fsidebar_bt_back:Show()
		
		local fsidebar_bt_block= LUI:CreateMeAFrame("FRAME","fsidebar_bt_block",fsidebar_anchor,80,225,1,"MEDIUM",4,"LEFT",fsidebar_anchor,"LEFT",-82,-5,1)
		fsidebar_bt_block:SetBackdrop({
			bgFile="Interface\\Tooltips\\UI-Tooltip-Background", 
			edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
			tile=false, edgeSize=1, 
			insets={left=0, right=0, top=0, bottom=0}
		})
		fsidebar_bt_block:SetBackdropColor(0,0,0,0)
		fsidebar_bt_block:SetBackdropBorderColor(0,0,0,0)
		fsidebar_bt_block:EnableMouse(true)
		fsidebar_bt_block:Show()
		
		local fsidebar_button_clicker= LUI:CreateMeAFrame("BUTTON","fsidebar_button_clicker",fsidebar_button_anchor,30,215,1,"MEDIUM",5,"LEFT",fsidebar_button_anchor,"LEFT",6,-5,1)
		fsidebar_button_clicker:SetBackdrop({
			bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
			tile=false, edgeSize=1, 
			insets={left=0, right=0, top=0, bottom=0}
		})
		fsidebar_button_clicker:SetBackdropColor(0,0,0,0)
		fsidebar_button_clicker:SetBackdropBorderColor(0,0,0,0)
		fsidebar_button_clicker:Show()
	
		local fsidebar_button = LUI:CreateMeAFrame("FRAME","fsidebar_button",fsidebar_button_anchor,266,251,1,"BACKGROUND",0,"LEFT",fsidebar_button_anchor,"LEFT",0,-2,1)
		fsidebar_button:SetBackdrop({
			bgFile=fdir.."sidebar_button", 
			edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
			tile=false, edgeSize=1, 
			insets={left=0, right=0, top=0, bottom=0}
		})
		fsidebar_button:SetBackdropColor(sidebar_r,sidebar_g,sidebar_b,1)
		fsidebar_button:SetBackdropBorderColor(0,0,0,0)
		fsidebar_button:Show()
		
		local fsidebar_button_hover = LUI:CreateMeAFrame("FRAME","fsidebar_button_hover",fsidebar_button_anchor,266,251,1,"BACKGROUND",0,"LEFT",fsidebar_button_anchor,"LEFT",0,-2,1)
		fsidebar_button_hover:SetBackdrop({
			bgFile=fdir.."sidebar_button_hover",
			edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
			tile=false, edgeSize=1,
			insets={left=0, right=0, top=0, bottom=0}
		})
		fsidebar_button_hover:SetBackdropColor(sidebar_r,sidebar_g,sidebar_b,1)
		fsidebar_button_hover:SetBackdropBorderColor(0,0,0,0)
		fsidebar_button_hover:Hide()
		
		rightSidebarOpen = 0
		
		fsidebar_button_clicker:RegisterForClicks("AnyUp")
		fsidebar_button_clicker:SetScript("OnClick", function(self)
			if rightSidebarOpen == 0 then
				rightSidebarOpen = 1
				db.Bars.SidebarRight.IsOpen = true
				if db.Bars.SidebarRight.OpenInstant then
					fsidebar_button_anchor:ClearAllPoints()
					fsidebar_button_anchor:SetPoint("LEFT",fsidebar_anchor,"LEFT",-120,0)
					fsidebar_bt_back:SetAlpha(1)
					SidebarSetAlpha(RightAnchor,1)
					for _, frame in pairs(Panels:LoadAdditional(db.Bars.SidebarRight.Additional)) do
						SidebarSetAlpha(frame, 1)
					end
					fsidebar_bt_block:Hide()
				else
					fsidebar_SlideOut:Show()
					fsidebar_AlphaIn:Show()
					fsidebar_bt_block:Hide()
				end
			else
				rightSidebarOpen = 0
				db.Bars.SidebarRight.IsOpen = false
				if db.Bars.SidebarRight.OpenInstant then
					fsidebar_button_anchor:ClearAllPoints()
					fsidebar_button_anchor:SetPoint("LEFT",fsidebar_anchor,"LEFT",-32,0)
					fsidebar_bt_back:SetAlpha(0)
					SidebarSetAlpha(RightAnchor,0)
					for _, frame in pairs(Panels:LoadAdditional(db.Bars.SidebarRight.Additional)) do
						SidebarSetAlpha(frame, 0)
					end
					fsidebar_bt_block:Show()
				else
					fsidebar_SlideIn:Show()
					fsidebar_AlphaOut:Show()
					SidebarSetAlpha(RightAnchor,0)
					for _, frame in pairs(Panels:LoadAdditional(db.Bars.SidebarRight.Additional)) do
						SidebarSetAlpha(frame, 0)
					end
					fsidebar_bt_block:Show()
				end
			end
		end)
	
		fsidebar_button_clicker:SetScript("OnEnter", function(self)
			fsidebar_button:Hide()
			fsidebar_button_hover:Show()
		end)
	
		fsidebar_button_clicker:SetScript("OnLeave", function(self)
			fsidebar_button:Show()
			fsidebar_button_hover:Hide()
		end)
	end
	
	if db.Bars.SidebarRight.Enable then	
		fsidebar_anchor:Show()
	else
		fsidebar_anchor:Hide()
	end
	
	SetRightSidebarAnchor()
	SidebarSetAlpha(RightAnchor,0)
	for _, frame in pairs(Panels:LoadAdditional(db.Bars.SidebarRight.Additional)) do
		SidebarSetAlpha(frame, 0)
	end
	
	if db.Bars.SidebarRight.Enable == true then
		if db.Bars.SidebarRight.IsOpen == true then
			rightSidebarOpen = 1
			fsidebar_SlideOut:Show()
			fsidebar_AlphaIn:Show()
			fsidebar_bt_block:Hide()
		end
	end
end

function module:CreateLeftSidebar()
	local LeftAnchor = isBarAddOnLoaded and db.Bars.SidebarLeft.Anchor or "LUIBarLeft"
	local isLeftSidebarCreated = false
	local sidebar_r, sidebar_g, sidebar_b, sidebar_a = unpack(db.Colors.sidebar)
	
	if isLeftSidebarCreated == false or isLeftSidebarCreated == nil then
		local isLeftSidebarCreated = true
		------------------------------------------------------
		-- / SLIDE LEFT SIDEBAR / --
		------------------------------------------------------
		local fsidebar2_timerout,fsidebar2_timerin = 0,0
		local fsidebar2_y = 0
		local fsidebar2_x = 30
		local fsidebar2_xout = 118
		local fsidebar2_pixelpersecond = 176
		local fsidebar2_animation_time = 0.5
		
		local fsidebar2_SlideOut = CreateFrame("Frame", "fsidebar2_SlideOut", UIParent)
		fsidebar2_SlideOut:Hide()
		
		fsidebar2_SlideOut:SetScript("OnUpdate", function(self,elapsed)
			fsidebar2_timerout = fsidebar2_timerout + elapsed
			if fsidebar2_timerout < fsidebar2_animation_time then
				local x2 = fsidebar2_x + fsidebar2_timerout * fsidebar2_pixelpersecond
				fsidebar2_button_anchor:ClearAllPoints()
				fsidebar2_button_anchor:SetPoint("RIGHT", fsidebar2_anchor, "RIGHT", x2, fsidebar2_y)
			else
				fsidebar2_button_anchor:ClearAllPoints()
				fsidebar2_button_anchor:SetPoint("RIGHT", fsidebar2_anchor, "RIGHT", fsidebar2_xout, fsidebar2_y)
				fsidebar2_timerout = 0
				fsidebar2_bt_AlphaIn:Show()
				self:Hide()
			end
		end)
		
		local fsidebar2_SlideIn = CreateFrame("Frame", "fsidebar2_SlideIn", UIParent)
		fsidebar2_SlideIn:Hide()
		
		fsidebar2_SlideIn:SetScript("OnUpdate", function(self,elapsed)
			fsidebar2_timerin = fsidebar2_timerin + elapsed
			if fsidebar2_timerin < fsidebar2_animation_time then
				local x2 = fsidebar2_x - fsidebar2_timerin * fsidebar2_pixelpersecond + fsidebar2_pixelpersecond * fsidebar2_animation_time
				fsidebar2_button_anchor:ClearAllPoints()
				fsidebar2_button_anchor:SetPoint("RIGHT", fsidebar2_anchor, "RIGHT", x2, fsidebar2_y)
			else
				fsidebar2_button_anchor:ClearAllPoints()
				fsidebar2_button_anchor:SetPoint("RIGHT", fsidebar2_anchor, "RIGHT", fsidebar2_x, fsidebar2_y)
				fsidebar2_timerin = 0
				self:Hide()
			end
		end)
		
		local fsidebar2_alpha_timerout, fsidebar2_alpha_timerin = 0,0
		local fsidebar2_speedin = 0.9
		local fsidebar2_speedout = 0.3
		
		local fsidebar2_AlphaIn = CreateFrame("Frame", "fsidebar2_AlphaIn", UIParent)
		fsidebar2_AlphaIn:Hide()
		
		fsidebar2_AlphaIn:SetScript("OnUpdate", function(self,elapsed)
			fsidebar2_alpha_timerin = fsidebar2_alpha_timerin + elapsed
			if fsidebar2_alpha_timerin < fsidebar2_speedin then
				local alpha = fsidebar2_alpha_timerin / fsidebar2_speedin 
				fsidebar2_bt_back:SetAlpha(alpha)
			else
				fsidebar2_bt_back:SetAlpha(1)
				fsidebar2_alpha_timerin = 0
				self:Hide()
			end

		end)
		
		local fsidebar2_AlphaOut = CreateFrame("Frame", "fsidebar2_AlphaOut", UIParent)
		fsidebar2_AlphaOut:Hide()
		
		fsidebar2_AlphaOut:SetScript("OnUpdate", function(self,elapsed)
			fsidebar2_alpha_timerout = fsidebar2_alpha_timerout + elapsed
			if fsidebar2_alpha_timerout < fsidebar2_speedout then
				local alpha = 1 - fsidebar2_alpha_timerout / fsidebar2_speedout
				fsidebar2_bt_back:SetAlpha(alpha)
			else
				fsidebar2_bt_back:SetAlpha(0)
				fsidebar2_alpha_timerout = 0
				self:Hide()
			end
		end)
		
		local fsidebar2_bt_timerin = 0,0
		local fsidebar2_bt_speedin = 0.3
		
		local fsidebar2_bt_AlphaIn = CreateFrame("Frame", "fsidebar2_bt_AlphaIn", UIParent)
		fsidebar2_bt_AlphaIn:Hide()
		
		fsidebar2_bt_AlphaIn:SetScript("OnUpdate", function(self,elapsed)
			fsidebar2_bt_timerin = fsidebar2_bt_timerin + elapsed
			if fsidebar2_bt_timerin < fsidebar2_bt_speedin then
				local alpha = fsidebar2_bt_timerin / fsidebar2_bt_speedin
				SidebarSetAlpha(LeftAnchor,alpha)
				for _, frame in pairs(Panels:LoadAdditional(db.Bars.SidebarLeft.Additional)) do
					SidebarSetAlpha(frame, alpha)
				end
			else
				SidebarSetAlpha(LeftAnchor,1)
				for _, frame in pairs(Panels:LoadAdditional(db.Bars.SidebarLeft.Additional)) do
					SidebarSetAlpha(frame, 1)
				end
				fsidebar2_bt_timerin = 0
				self:Hide()
			end
		end)
		
		------------------------------------------------------
		-- / LEFT SIDEBAR FRAMES / --
		------------------------------------------------------
	
		fsidebar2_anchor = LUI:CreateMeAFrame("FRAME","fsidebar2_anchor",UIParent,25,25,1,"BACKGROUND",0,"LEFT",UIParent,"LEFT",-11,db.Bars.SidebarLeft.Offset,1)
		fsidebar2_anchor:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=0, tileSize=0, edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
		fsidebar2_anchor:SetBackdropColor(0,0,0,0)
		fsidebar2_anchor:SetBackdropBorderColor(0,0,0,0)
		fsidebar2_anchor:Show()
		
		local fsidebar2 = LUI:CreateMeAFrame("FRAME","fsidebar2",fsidebar2_anchor,512,512,1,"BACKGROUND",2,"RIGHT",fsidebar2_anchor,"RIGHT",17,0,1)
		fsidebar2:SetBackdrop({bgFile=fdir.."sidebar2", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=0, tileSize=0, edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
		fsidebar2:SetBackdropBorderColor(0,0,0,0)
		fsidebar2:Show()
		
		local fsidebar2_back = LUI:CreateMeAFrame("FRAME","fsidebar2_back",fsidebar2_anchor,512,512,1,"BACKGROUND",1,"RIGHT",fsidebar2_anchor,"RIGHT",25,0,1)
		fsidebar2_back:SetBackdrop({bgFile=fdir.."sidebar2_back", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=0, tileSize=0, edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
		fsidebar2_back:SetBackdropColor(sidebar_r,sidebar_g,sidebar_b,sidebar_a)
		fsidebar2_back:SetBackdropBorderColor(0,0,0,0)
		fsidebar2_back:Show()
		
		local fsidebar2_back2 = LUI:CreateMeAFrame("FRAME","fsidebar2_back2",fsidebar2_anchor,512,512,1,"BACKGROUND",3,"RIGHT",fsidebar2_anchor,"RIGHT",25,0,1)
		fsidebar2_back2:SetBackdrop({bgFile=fdir.."sidebar2_back2", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=0, tileSize=0, edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
		fsidebar2_back2:SetBackdropColor(sidebar_r,sidebar_g,sidebar_b,1)
		fsidebar2_back2:SetBackdropBorderColor(0,0,0,0)
		fsidebar2_back2:Show()
		
		local fsidebar2_button_anchor= LUI:CreateMeAFrame("FRAME","fsidebar2_button_anchor",fsidebar2_anchor,10,10,1,"BACKGROUND",0,"RIGHT",fsidebar2_anchor,"RIGHT",30,0,1)
		fsidebar2_button_anchor:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=0, tileSize=0, edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
		fsidebar2_button_anchor:SetBackdropColor(0,0,0,0)
		fsidebar2_button_anchor:SetBackdropBorderColor(0,0,0,0)
		fsidebar2_button_anchor:Show()
		
		local fsidebar2_bt_back = LUI:CreateMeAFrame("FRAME","fsidebar2_bt_back",fsidebar2_button_anchor,273,267,1,"BACKGROUND",0,"RIGHT",fsidebar2_button_anchor,"RIGHT",-3,-2,1)
		fsidebar2_bt_back:SetBackdrop({bgFile=fdir.."sidebar2_bt_back", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=0, tileSize=0, edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
		fsidebar2_bt_back:SetBackdropColor(sidebar_r,sidebar_g,sidebar_b,1)
		fsidebar2_bt_back:SetBackdropBorderColor(0,0,0,0)
		fsidebar2_bt_back:SetAlpha(0)
		fsidebar2_bt_back:Show()
		
		local fsidebar2_bt_block= LUI:CreateMeAFrame("FRAME","fsidebar2_bt_block",fsidebar2_anchor,80,225,1,"MEDIUM",4,"RIGHT",fsidebar2_anchor,"RIGHT",82,-5,1)
		fsidebar2_bt_block:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=0, tileSize=0, edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
		fsidebar2_bt_block:SetBackdropColor(0,0,0,0)
		fsidebar2_bt_block:SetBackdropBorderColor(0,0,0,0)
		fsidebar2_bt_block:EnableMouse(true)
		fsidebar2_bt_block:Show()
		
		local fsidebar2_button_clicker= LUI:CreateMeAFrame("BUTTON","fsidebar2_button_clicker",fsidebar2_button_anchor,30,215,1,"MEDIUM",5,"RIGHT",fsidebar2_button_anchor,"RIGHT",-6,-5,1)
		fsidebar2_button_clicker:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=0, tileSize=0, edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
		fsidebar2_button_clicker:SetBackdropColor(0,0,0,0)
		fsidebar2_button_clicker:SetBackdropBorderColor(0,0,0,0)
		fsidebar2_button_clicker:Show()

		local fsidebar2_button = LUI:CreateMeAFrame("FRAME","fsidebar2_button",fsidebar2_button_anchor,266,251,1,"BACKGROUND",0,"RIGHT",fsidebar2_button_anchor,"RIGHT",0,-2,1)
		fsidebar2_button:SetBackdrop({bgFile=fdir.."sidebar2_button", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=0, tileSize=0, edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
		fsidebar2_button:SetBackdropColor(sidebar_r,sidebar_g,sidebar_b,1)
		fsidebar2_button:SetBackdropBorderColor(0,0,0,0)
		fsidebar2_button:Show()
		
		local fsidebar2_button_hover = LUI:CreateMeAFrame("FRAME","fsidebar2_button_hover",fsidebar2_button_anchor,266,251,1,"BACKGROUND",0,"RIGHT",fsidebar2_button_anchor,"RIGHT",0,-2,1)
		fsidebar2_button_hover:SetBackdrop({bgFile=fdir.."sidebar2_button_hover", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=0, tileSize=0, edgeSize=1, insets={left=0, right=0, top=0, bottom=0}})
		fsidebar2_button_hover:SetBackdropColor(sidebar_r,sidebar_g,sidebar_b,1)
		fsidebar2_button_hover:SetBackdropBorderColor(0,0,0,0)
		fsidebar2_button_hover:Hide()
	
		leftSidebarOpen = 0
		
		fsidebar2_button_clicker:RegisterForClicks("AnyUp")
		fsidebar2_button_clicker:SetScript("OnClick", function(self)
			if leftSidebarOpen == 0 then
				leftSidebarOpen = 1
				db.Bars.SidebarLeft.IsOpen = true
				if db.Bars.SidebarLeft.OpenInstant then
					fsidebar2_button_anchor:ClearAllPoints()
					fsidebar2_button_anchor:SetPoint("RIGHT",fsidebar2_anchor,"RIGHT",120,0)
					fsidebar2_bt_back:SetAlpha(1)
					SidebarSetAlpha(LeftAnchor,1)
					for _, frame in pairs(Panels:LoadAdditional(db.Bars.SidebarLeft.Additional)) do
						SidebarSetAlpha(frame, 1)
					end
					fsidebar2_bt_block:Hide()
				else
					fsidebar2_SlideOut:Show()
					fsidebar2_AlphaIn:Show()
					fsidebar2_bt_block:Hide()
				end
			else
				leftSidebarOpen = 0
				db.Bars.SidebarLeft.IsOpen = false
				if db.Bars.SidebarLeft.OpenInstant then
					fsidebar2_button_anchor:ClearAllPoints()
					fsidebar2_button_anchor:SetPoint("RIGHT",fsidebar2_anchor,"RIGHT",32,0)
					fsidebar2_bt_back:SetAlpha(0)
					SidebarSetAlpha(LeftAnchor,0)
					for _, frame in pairs(Panels:LoadAdditional(db.Bars.SidebarLeft.Additional)) do
						SidebarSetAlpha(frame, 0)
					end
					fsidebar2_bt_block:Show()
				else
					fsidebar2_SlideIn:Show()
					fsidebar2_AlphaOut:Show()
					SidebarSetAlpha(LeftAnchor,0)
					for _, frame in pairs(Panels:LoadAdditional(db.Bars.SidebarLeft.Additional)) do
						SidebarSetAlpha(frame, 0)
					end
					fsidebar2_bt_block:Show()
				end
			end
		end)
	
		fsidebar2_button_clicker:SetScript("OnEnter", function(self)
			fsidebar2_button:Hide()
			fsidebar2_button_hover:Show()
		end)
	
		fsidebar2_button_clicker:SetScript("OnLeave", function(self)
			fsidebar2_button:Show()
			fsidebar2_button_hover:Hide()
		end)
	end
	
	if db.Bars.SidebarLeft.Enable then	
		fsidebar2_anchor:Show()
	else
		fsidebar2_anchor:Hide()
	end
	
	SetLeftSidebarAnchor()
	SidebarSetAlpha(LeftAnchor,0)
	for _, frame in pairs(Panels:LoadAdditional(db.Bars.SidebarLeft.Additional)) do
		SidebarSetAlpha(frame, 0)
	end
	
	if db.Bars.SidebarLeft.Enable == true then
		if db.Bars.SidebarLeft.IsOpen == true then
			leftSidebarOpen = 1
			fsidebar2_SlideOut:Show()
			fsidebar2_AlphaIn:Show()
			fsidebar2_bt_block:Hide()
		end
	end
end

function module:SetButtons()
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
		gloss:SetAlpha(0.3)
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
			if db.Bars.ShowEquipped then border:Show_() end
		end
		border.Hide_ = border.Hide
		border.Hide = function()
			button.__equipped = false
			border:Hide_()
		end
		
		if border:IsShown() then button.__equipped = true end
		if not db.Bars.ShowEquipped then border:Hide_() end
		
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
			if db.Bars.ShowHotkey and hotkey:GetText() ~= RANGE_INDICATOR then
				hotkey:Show_()
			end
		end
		
		if not db.Bars.ShowHotkey then hotkey:Hide() end
		
		-- macro
		local macro = _G[name.."Name"]
		macro:SetFont(font, 12, "OUTLINE")
		macro:SetDrawLayer("OVERLAY")
		macro:ClearAllPoints()
		macro:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 6)
		macro:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 6)
		macro:SetHeight(10)
		
		if not db.Bars.ShowMacro then macro:Hide() end
		
		-- count
		local count = _G[name.."Count"]
		count:SetFont(font, 14, "OUTLINE")
		count:SetDrawLayer("OVERLAY")
		count:ClearAllPoints()
		count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 6)
		count:SetWidth(40)
		count:SetHeight(10)
		
		if not db.Bars.ShowCount then count:Hide() end
	
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
	
	hooksecurefunc("ActionButton_Update", StyleButton)
	hooksecurefunc("PetActionBar_Update", StylePetButtons)
	hooksecurefunc("ShapeshiftBar_Update", StyleShapeshiftButtons)
	hooksecurefunc("ShapeshiftBar_UpdateState", StyleShapeshiftButtons)
	
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
		
		if self:GetParent():GetParent():GetName() == "SpellBookSpellIconsFrame" then return end
		
		if self:GetAttribute("flyoutDirection") ~= nil then
			local point = self:GetParent():GetParent():GetPoint()
			
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
	hooksecurefunc("ActionButton_UpdateFlyout", StyleFlyout)
	
	-- hotkey text replace
	-- only EN client :/
	local function UpdateHotkey(self, abt)
		local gsub = string.gsub
		local hotkey = _G[self:GetName().."HotKey"]
		local text = hotkey:GetText()
		
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
			hotkey:SetText("")
		else
			hotkey:SetText(text)
		end
	end
	hooksecurefunc("ActionButton_UpdateHotkeys", UpdateHotkey)
	
	-- usable coloring on icon
	local function Button_OnUpdate(button, elapsed)
		if button.__elapsed > 0.25 then
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
	hooksecurefunc("ActionButton_OnUpdate", Button_OnUpdate)
end

function module:SetBottomBar1()
	local Page = {
		["DRUID"] = {
			"[bonusbar:1,nostealth] %s; ",
			"[bonusbar:1,stealth] %s; ",
			"[bonusbar:2] %s; ",
			"[bonusbar:3] %s; ",
			"[bonusbar:4] %s; "
		},
		["WARRIOR"] = {
			"[bonusbar:1] %s; ", "[bonusbar:2] %s; ", "[bonusbar:3] %s; "
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

	local function GetBar()
		local condition = "[bonusbar:5] 11; "
		if Page[class] then
			for num, word in pairs(Page[class]) do
				condition = condition..word:format(db.Bars.Bottombar1.State[num+1])
			end
		end
		condition = condition..db.Bars.Bottombar1.State[1]
		return condition
	end

	local bar = CreateFrame("Frame", "LUIBar1", UIParent, "SecureHandlerStateTemplate")
	bar:SetWidth(454)
	bar:SetHeight(36)
	bar:SetPoint("BOTTOM", UIParent, "BOTTOM", tonumber(db.Bars.Bottombar1.X), tonumber(db.Bars.Bottombar1.Y))
	bar:SetScale(tonumber(db.Bars.Bottombar1.Scale))

	local button, buttons, previous
	
	for i = 1, NUM_ACTIONBAR_BUTTONS do
		button = _G["ActionButton"..i]
		button:ClearAllPoints()
		button:SetParent(bar)
		
		if i == 1 then
			button:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
		else
			button:SetPoint("LEFT", previous, "RIGHT", 2, 0)
		end
		previous = button
		
		bar:SetFrameRef("ActionButton"..i, button)
	end
	
	bar:Execute([[
		buttons = table.new()
		for i = 1, 12 do
			table.insert(buttons, self:GetFrameRef("ActionButton"..i))
		end
	]])
	
	bar:SetAttribute("_onstate-page", [[
		for i, button in ipairs(buttons) do
			button:SetAttribute("actionpage", tonumber(newstate))
		end
	]])
	
	RegisterStateDriver(bar, "page", GetBar())
	
	bar.UpdateState = function()
		UnregisterStateDriver(bar, "page")
		RegisterStateDriver(bar, "page", GetBar())
	end
end

function module:SetBottomBar2()
	local bar = CreateFrame("Frame", "LUIBar2", UIParent, "SecureHandlerStateTemplate")
	bar:SetWidth(454)
	bar:SetHeight(36)
	bar:SetPoint("BOTTOM", UIParent, "BOTTOM", tonumber(db.Bars.Bottombar2.X), tonumber(db.Bars.Bottombar2.Y))
	bar:SetScale(tonumber(db.Bars.Bottombar2.Scale))

	local button, buttons, previous
	
	for i = 1, NUM_ACTIONBAR_BUTTONS do
		button = _G["MultiBarBottomLeftButton"..i]
		button:ClearAllPoints()
		button:SetParent(bar)
		
		if i == 1 then
			button:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
		else
			button:SetPoint("LEFT", previous, "RIGHT", 2, 0)
		end
		previous = button
		
		bar:SetFrameRef("MultiBarBottomLeftButton"..i, button)
	end
	
	bar:Execute([[
		buttons = table.new()
		for i = 1, 12 do
			table.insert(buttons, self:GetFrameRef("MultiBarBottomLeftButton"..i))
		end
	]])
	
	bar:SetAttribute("_onstate-page", [[
		for i, button in ipairs(buttons) do
			button:SetAttribute("actionpage", tonumber(newstate))
		end
	]])
			
	RegisterStateDriver(bar, "page", db.Bars.Bottombar2.State)
	
	if not db.Bars.Bottombar2.Enable then bar:Hide() end
	
	bar.UpdateState = function()
		UnregisterStateDriver(bar, "page")
		RegisterStateDriver(bar, "page", db.Bars.Bottombar2.State)
	end
end

function module:SetBottomBar3()
	local bar = CreateFrame("Frame", "LUIBar3", UIParent, "SecureHandlerStateTemplate")
	bar:SetWidth(454)
	bar:SetHeight(36)
	bar:SetPoint("BOTTOM", UIParent, "BOTTOM", tonumber(db.Bars.Bottombar3.X), tonumber(db.Bars.Bottombar3.Y))
	bar:SetScale(tonumber(db.Bars.Bottombar3.Scale))

	local button, buttons, previous
	
	for i = 1, NUM_ACTIONBAR_BUTTONS do
		button = _G["MultiBarBottomRightButton"..i]
		button:ClearAllPoints()
		button:SetParent(bar)
		
		if i == 1 then
			button:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
		else
			button:SetPoint("LEFT", previous, "RIGHT", 2, 0)
		end
		previous = button
		
		bar:SetFrameRef("MultiBarBottomRightButton"..i, button)
	end
	
	bar:Execute([[
		buttons = table.new()
		for i = 1, 12 do
			table.insert(buttons, self:GetFrameRef("MultiBarBottomRightButton"..i))
		end
	]])
	
	bar:SetAttribute("_onstate-page", [[
		for i, button in ipairs(buttons) do
			button:SetAttribute("actionpage", tonumber(newstate))
		end
	]])
			
	RegisterStateDriver(bar, "page", db.Bars.Bottombar3.State)
	
	if not db.Bars.Bottombar3.Enable then bar:Hide() end
	
	bar.UpdateState = function()
		UnregisterStateDriver(bar, "page")
		RegisterStateDriver(bar, "page", db.Bars.Bottombar3.State)
	end
end

function module:SetLeftBar()
	local bar = CreateFrame("Frame", "LUIBarLeft", UIParent, "SecureHandlerStateTemplate")
	bar:SetWidth(1) -- because of way LUI handles
	bar:SetHeight(1) -- sidebar position calculation
	bar:SetScale(0.85)

	local button, buttons, previous, previous2
	
	for i = 1, NUM_ACTIONBAR_BUTTONS do
		button = _G["MultiBarLeftButton"..i]
		button:ClearAllPoints()
		button:SetParent(bar)
		
		if i == 1 then
			button:SetPoint("TOPLEFT", bar, "TOPLEFT", 5, -3) -- like BT
			previous2 = button
		elseif i % 2 == 1 then
			button:SetPoint("TOP", previous2, "BOTTOM", 0, -2)
			previous2 = button
		else
			button:SetPoint("LEFT", previous, "RIGHT", 2, 0)
		end
		previous = button
		
		bar:SetFrameRef("MultiBarLeftButton"..i, button)
	end
	
	bar:Execute([[
		buttons = table.new()
		for i = 1, 12 do
			table.insert(buttons, self:GetFrameRef("MultiBarLeftButton"..i))
		end
	]])
	
	bar:SetAttribute("_onstate-page", [[
		for i, button in ipairs(buttons) do
			button:SetAttribute("actionpage", tonumber(newstate))
		end
	]])
	
	RegisterStateDriver(bar, "page", db.Bars.SidebarLeft.State)

	if not db.Bars.SidebarLeft.Enable then bar:Hide() end
	
	bar.UpdateState = function()
		UnregisterStateDriver(bar, "page")
		RegisterStateDriver(bar, "page", db.Bars.SidebarLeft.State)
	end
end

function module:SetRightBar()
	local bar = CreateFrame("Frame", "LUIBarRight", UIParent, "SecureHandlerStateTemplate")
	bar:SetWidth(1) -- because of way LUI handles
	bar:SetHeight(1) -- sidebar position calculation
	bar:SetScale(0.85)

	local button, buttons, previous, previous2
	
	for i = 1, NUM_ACTIONBAR_BUTTONS do
		button = _G["MultiBarRightButton"..i]
		button:ClearAllPoints()
		button:SetParent(bar)
		
		if i == 1 then
			button:SetPoint("TOPLEFT", bar, "TOPLEFT", 5, -3) -- like BT
			previous2 = button
		elseif i % 2 == 1 then
			button:SetPoint("TOP", previous2, "BOTTOM", 0, -2)
			previous2 = button
		else
			button:SetPoint("LEFT", previous, "RIGHT", 2, 0)
		end
		previous = button
		
		bar:SetFrameRef("MultiBarRightButton"..i, button)
	end
	
	bar:Execute([[
		buttons = table.new()
		for i = 1, 12 do
			table.insert(buttons, self:GetFrameRef("MultiBarRightButton"..i))
		end
	]])
	
	bar:SetAttribute("_onstate-page", [[
		for i, button in ipairs(buttons) do
			button:SetAttribute("actionpage", tonumber(newstate))
		end
	]])
	
	RegisterStateDriver(bar, "page", db.Bars.SidebarRight.State)

	if not db.Bars.SidebarRight.Enable then bar:Hide() end
	
	bar.UpdateState = function()
		UnregisterStateDriver(bar, "page")
		RegisterStateDriver(bar, "page", db.Bars.SidebarRight.State)
	end
end

function module:SetPetBar()
	local bar = CreateFrame("Frame", "LUIPetBar", UIParent, "SecureHandlerStateTemplate")
	bar:SetWidth(30 * math.ceil(NUM_PET_ACTION_SLOTS / 2) + 2 * (math.ceil(NUM_PET_ACTION_SLOTS / 2) - 1))
	bar:SetHeight(62)
	bar:SetPoint("RIGHT", UIParent, "RIGHT", tonumber(db.Bars.Petbar.X), tonumber(db.Bars.Petbar.Y))
	bar:SetScale(tonumber(db.Bars.Petbar.Scale))

	RegisterStateDriver(bar, "visibility", "[pet,novehicleui,nobonusbar:5] show; hide")

	PetActionBarFrame:SetParent(bar)
	PetActionBarFrame:EnableMouse(false)
	PetActionBarFrame.showgrid = 1
	PetActionBar_ShowGrid()

	local button, previous, previous2
	for i = 1, NUM_PET_ACTION_SLOTS do
		button = _G["PetActionButton"..i]
		button:ClearAllPoints()
		button:SetParent(bar)
		
		if i == 1 then
			button:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
			previous2 = button
		elseif i % (NUM_PET_ACTION_SLOTS / 2) == 1 then
			button:SetPoint("TOP", previous2, "BOTTOM", 0, -2)
			previous2 = button
		else
			button:SetPoint("LEFT", previous, "RIGHT", 2, 0)
		end
		previous = button
	end
end

function module:SetShapeshiftBar()
	local bar = CreateFrame("Frame", "LUIShapeshiftBar", UIParent, "SecureHandlerStateTemplate")
	bar:SetWidth(30 * NUM_SHAPESHIFT_SLOTS + 2 * (NUM_SHAPESHIFT_SLOTS - 1))
	bar:SetHeight(30)
	bar:SetPoint("LEFT", UIParent, "LEFT", tonumber(db.Bars.Shapeshiftbar.X), tonumber(db.Bars.Shapeshiftbar.Y))
	bar:SetScale(tonumber(db.Bars.Shapeshiftbar.Scale))

	ShapeshiftBarFrame:SetParent(bar)
	ShapeshiftBarFrame:EnableMouse(false)

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
		end
	end

	hooksecurefunc("ShapeshiftBar_Update", MoveShapeshift)

	MoveShapeshift()
end

function module:SetVehicleExit()
	local bar = CreateFrame("Frame", "LUIVehicleExit", UIParent, "SecureHandlerStateTemplate")
	bar:SetHeight(60)
	bar:SetWidth(60)
	bar:SetPoint("CENTER", UIParent, "CENTER", tonumber(db.Bars.VehicleExit.X), tonumber(db.Bars.VehicleExit.Y))
	bar:SetScale(tonumber(db.Bars.VehicleExit.Scale))

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
		if frame:GetObjectType() == "Frame" then frame:UnregisterAllEvents() end
		frame:HookScript("OnShow", function(self) self:Hide() end)
		frame:Hide()
		frame:SetAlpha(0)
	end

	hooksecurefunc("TalentFrame_LoadUI", function() PlayerTalentFrame:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED") end)

	local totem = _G["MultiCastActionBarFrame"]

	if not totem then return end

	totem:UnregisterAllEvents()
	totem:Hide()
	totem:HookScript("OnShow", function(self) self:Hide() end)
end

function module:SetLibKeyBound()
	function self:LIBKEYBOUND_ENABLED() self.keyBoundMode = true end

	function self:LIBKEYBOUND_DISABLED() self.keyBoundMode = nil end

	LibKeyBound.RegisterCallback(self, "LIBKEYBOUND_ENABLED")
	LibKeyBound.RegisterCallback(self, "LIBKEYBOUND_DISABLED")
	--LibKeyBound.RegisterCallback(self, "LIBKEYBOUND_MODE_COLOR_CHANGED")
end

function module:SetBars()
	if not (IsAddOnLoaded("Bartender4") or IsAddOnLoaded("Dominos")) then
		if not db.Bars.StatesLoaded then LoadStates(defaultstate) end
		
		self:SetLibKeyBound()
		
		self:SetBottomBar1()
		self:SetBottomBar2()
		self:SetBottomBar3()
		
		self:SetLeftBar()
		self:SetRightBar()
		self:SetPetBar()
		self:SetShapeshiftBar()
		
		self:SetVehicleExit()
		self:HideBlizzard()
		
		self:SetButtons()
		
		-- because of an ugly bug...
		hooksecurefunc(CharacterFrame, "Show", function()
			TokenFrame_Update()
		end)
	else
		isBarAddOnLoaded = true
	end
	
	self:CreateBarBackground()
	self:CreateRightSidebar()
	self:CreateLeftSidebar()
end

local defaults = {
	Bars = {
		StatesLoaded = false,
		ShowHotkey = false,
		ShowMacro = false,
		ShowCount = true,
		ShowEquipped = false,
		TopTexture = {
			Enable = true,
			Alpha = 0.7,
			X = "-25",
			Y = "25",
			Animation = true,
			AnimationHeight = "35",
		},
		BottomTexture = {
			Enable = true,
			Alpha = 1,
			X = "0",
			Y = "-42",
		},
		SidebarRight = { 
			Enable = true,
			OpenInstant = false,
			Offset = "0",
			IsOpen = false,
			Anchor = "BT4Bar10",
			Additional = "",
			AutoPosEnable = true,
			X = "0",
			Y = "0",
			State = "0",
		},
		SidebarLeft = {
			Enable = false,
			OpenInstant = false,
			Offset = "0",
			IsOpen = false,
			Anchor = "BT4Bar9",
			Additional = "",
			AutoPosEnable = true,
			X = "0",
			Y = "0",
			State = "0",
		},
		Bottombar1 = {
			X = "0",
			Y = "24.5",
			Scale = 0.85,
			State = {
				[1] = "0",
				[2] = "0",
				[3] = "0",
				[4] = "0",
				[5] = "0",
				[6] = "0",
			},
		},
		Bottombar2 = {
			Enable = true,
			X = "0",
			Y = "63.5",
			Scale = 0.85,
			State = "0",
		},
		Bottombar3 = {
			Enable = false,
			X = "0",
			Y = "102.5",
			Scale = 0.85,
			State = "0",
		},
		Shapeshiftbar = {
			X = "50",
			Y = "-315",
			Scale = 0.85,
		},
		Petbar = {
			X = "-50",
			Y = "-330",
			Scale = 0.85,
		},
		VehicleExit = {
			X = "-350",
			Y = "-200",
			Scale = 1,
		},
	},
}

------------------------------------------------------------------------
--	Bottom Bar Option Constructor
------------------------------------------------------------------------

-- num: 1, 2 or 3
function module:CreateBottombarOptions(num, order)
	local barName = "Bar "..num
	local barKey = "Bottombar"..num
	local bardb = db.Bars[barKey]
	local bardefaults = LUI.defaults.profile.Bars[barKey]
	
	local bar = _G["LUIBar"..num]
	
	local ApplySettings = function()
		bar:ClearAllPoints()
		bar:SetPoint("BOTTOM", UIParent, "BOTTOM", tonumber(bardb.X), tonumber(bardb.Y))
		bar:SetScale(tonumber(bardb.Scale))
		bar.UpdateState()
		
		if bardb.Enable == false then
			bar:Hide()
		else
			bar:Show()
		end
	end
	
	local DisabledFunc = function() return bardb.Enable == false end
	
	local options = {
		name = barName,
		type = "group",
		order = order,
		args = {
			Enable = (num ~= 1) and LUI:NewToggle("Enable", "Whether you want to use Bottom Bar "..num.." or not.", 1, bardb, "Enable", bardefaults, ApplySettings) or nil,
			General = {
				name = "General Settings",
				type = "group",
				guiInline = true,
				disabled = DisabledFunc,
				order = 2,
				args = {
					XValue = LUI:NewPosX(barName, 1, bardb, "", bardefaults, ApplySettings),
					YValue = LUI:NewPosY(barName, 2, bardb, "", bardefaults, ApplySettings),
					empty = LUI:NewEmpty(3),
					Scale = LUI:NewSlider("Scale", "Choose the Scale of your "..barName..".", 4, bardb, "Scale", bardefaults, 0.1, 1.5, 0.05, ApplySettings),
				},
			},
			State = {
				name = "State Configuration",
				type = "group",
				guiInline = true,
				disabled = DisabledFunc,
				order = 3,
				args = {},
			},
		},
	}
	
	if num == 1 then
		local i = 1
		for k, v in pairs(statetext) do
			local c = i
			options.args.State.args["State"..c] = {
				name = v,
				desc = "Choose the State for "..v..".\nLUI Default: "..defaultstate[barKey][c].."\nBlizzard Default: "..blizzstate[barKey][c],
				type = "select",
				values = statelist,
				get = function()
						for k, v in pairs(statelist) do
							if bardb.State[c] == v then
								return k
							end
						end
					end,
				set = function(_, select)
						bardb.State[c] = statelist[select]
						bar.UpdateState()
					end,
				order = c,
			}
			i = i + 1
		end
	else
		options.args.State.args.State = {
			name = "State",
			desc = "Choose the State for your "..barName..".\nLUI Default: "..defaultstate[barKey].."\nBlizzard Default: "..blizzstate[barKey],
			type = "select",
			values = statelist,
			get = function()
					for k, v in pairs(statelist) do
						if bardb.State == v then
							return k
						end
					end
				end,
			set = function(_, select)
					bardb.State = statelist[select]
					bar.UpdateState()
				end,
			order = 1,
		}
	end
	
	return options
end

------------------------------------------------------------------------
--	Sidebar Option Constructor
------------------------------------------------------------------------
	
-- side: "Left" or "Right"
function module:CreateSidebarOptions(side, order)
	local isRight = side == "Right"
	local sbdb = isRight and db.Bars.SidebarRight or db.Bars.SidebarLeft
	local sbdefaults = isRight and LUI.defaults.profile.Bars.SidebarRight or LUI.defaults.profile.Bars.SidebarLeft
	local sbanchor = isRight and fsidebar_anchor or fsidebar2_anchor
	
	local UIRL = function() StaticPopup_Show("RELOAD_UI") end
	
	local ApplySettings = function()
		sbanchor:ClearAllPoints()
		sbanchor:SetPoint(side, UIParent, side, isRight and 11 or -11, sbdb.Offset)
		if isRight then
			if sbdb.AutoPosEnable or isBarAddOnLoaded then SetRightSidebarAnchor() end
		else
			if sbdb.AutoPosEnable or isBarAddOnLoaded then SetLeftSidebarAnchor() end
		end
	end
	
	local ApplyAdditionalFrames = function() Panels:LoadAdditional(sbdb.Additional, true) end
	
	local DisabledFunc = function() return not sbdb.Enable end
	
	local DisabledPosFunc = function() return isBarAddOnLoaded and not sbdb.AutoPosEnable end
	
	local ShowFrameIdentifier = function() LUI_Frame_Identifier:Show() end
	
	local options = {
		name = side.." Sidebar",
		type = "group",
		order = order,
		args = {
			Enable = LUI:NewToggle("Enable", "Whether you want to show the "..side.." Sidebar or not.", 1, sbdb, "Enable", sbdefaults, UIRL),
			Settings = {
				name = "Anchor",
				type = "group",
				order = 2,
				disabled = DisabledFunc,
				guiInline = true,
				args = {
					Intro = LUI:NewDesc("Which Bar should be your right Sidebar?\nChoose one or type in the MainAnchor manually.\n\nMake sure your Bar is set to 6 buttons/2 columns.\nLUI will position your Bar automatically.", 1, "full"),
					empty = LUI:NewEmpty(2),
					FrameModifierDesc = LUI:NewDesc("Use the LUI Frame Identifier to search for the Parent Frame of your Bar.\n\nOr use the Blizzard Debug Tool: Type /framestack", 3, "full"),
					FrameIdentifier = LUI:NewExecute("LUI Frame Identifier", nil, 4, ShowFrameIdentifier),
					empty2 = LUI:NewEmpty(4),
					SidebarAnchorDropDown = LUI:NewSelect("Bar", "Choose the Bar for your Right Sidebar.", 5, barAnchors, nil, sbdb, "Anchor", sbdefaults, UIRL),
					SidebarAnchor = LUI:NewInput("Individual Bar", "Choose the Bar for your Right Sidebar.", 6, sbdb, "Anchor", sbdefaults, UIRL),
					AdditionalFrames = LUI:NewInput("Additional Frames", "Type in any additional frame names (separated by commas)\nthat you would like to show/hide with the "..side.." Sidebar.", 7, sbdb, "Additional", sbdefaults, ApplyAdditionalFrames),
					XOffset = LUI:NewPosX("Bar Anchor", 8, sbdb, "", sbdefaults, ApplySettings, nil, DisabledPosFunc),
					YOffset = LUI:NewPosY("Bar Anchor", 9, sbdb, "", sbdefaults, ApplySettings, nil, DisabledPosFunc),
					AutoPos = isBarAddOnLoaded and LUI:NewToggle("Stop touching me!", "Whether you want that LUI handles your Bar Positioning or not.", 10, sbdb, "AutoPosEnable", sbdefaults, ApplySettings) or nil,
				},
			},
			AddOptions = {
				name = "Additional Options",
				type = "group",
				order = 3,
				disabled = DisabledFunc,
				guiInline = true,
				args = {
					Offset = LUI:NewInputNumber("Sidebar Y Offset", "Y Offset from the middle-right position.", 1, sbdb, "Offset", sbdefaults, ApplySettings),
					OpenAnim = LUI:NewToggle("Open Instant", "Whether you want to show an open/close animation or not.", 2, sbdb, "OpenInstant", sbdefaults, function() end),
				},
			},
			BarOptions = not isBarAddOnLoaded and {
				name = "Bar Options",
				type = "group",
				order = 4,
				disabled = DisabledFunc,
				guiInline = true,
				args = {
					State = {
						name = "State",
						desc = "Choose the State for your "..side.." Bar.\nLUI Default: "..defaultstate["Sidebar"..side].."\nBlizzard Default: "..blizzstate["Sidebar"..side],
						type = "select",
						values = statelist,
						get = function()
								for k, v in pairs(statelist) do
									if sbdb.State == v then
										return k
									end
								end
							end,
						set = function(_, select)
								sbdb.State = statelist[select]
								if side == "Right" then LUIBarRight.UpdateState() end
								if side == "Left" then LUIBarLeft.UpdateState() end
							end,
						order = 1,
					},
				},
			} or nil,
		},
	}
	
	return options
end

function module:LoadOptions()
	local bardb = db.Bars
	local bardefaults = LUI.defaults.profile.Bars
	
	local ApplySettings = function()
		BarsBackground:SetAlpha(db.Bars.TopTexture.Alpha)
		BarsBackground:ClearAllPoints()
		BarsBackground:SetPoint("BOTTOM", UIParent, "BOTTOM", tonumber(db.Bars.TopTexture.X), tonumber(db.Bars.TopTexture.Y))
		
		if db.Bars.TopTexture.Enable == true then
			BarsBackground:Show()
		else
			BarsBackground:Hide()
		end
		
		BarsBackground2:SetAlpha(db.Bars.BottomTexture.Alpha)
		BarsBackground2:ClearAllPoints()
		BarsBackground2:SetPoint("BOTTOM", UIParent, "BOTTOM", tonumber(db.Bars.BottomTexture.X), tonumber(db.Bars.BottomTexture.Y))
		
		if db.Bars.BottomTexture.Enable == true then
			BarsBackground2:Show()
		else
			BarsBackground2:Hide()
		end
	end
	
	local ToggleTexts = function()
		for _, button in pairs(buttonlist) do
			local name = button:GetName()
			
			local count = _G[name.."Count"]
			if db.Bars.ShowCount then
				if count then count:Show() end
			else
				if count then count:Hide() end
			end
			
			local hotkey = _G[name.."HotKey"]
			if db.Bars.ShowHotkey then
				if hotkey then hotkey:Show() end
			else
				if hotkey then hotkey:Hide() end
			end
			
			local name = _G[name.."Name"]
			if db.Bars.ShowMacro then
				if name then name:Show() end
			else
				if name then name:Hide() end
			end
		end
	end
	
	local ToggleEquipped = function()
		for _, button in pairs(buttonlist) do
			local name = button:GetName()
			if _G[name] then
				local border = _G[name.."Border"]
				if db.Bars.ShowEquipped and button.action and IsEquippedAction(button.action) then
					border:Show()
				else
					border:Hide()
				end
			end
		end
	end
	
	local DisabledTopBarTex = function() return not db.Bars.TopTexture.Enable end
	
	local DisabledBottomBarTex = function() return not db.Bars.BottomTexture.Enable end
	
	local ApplySettingsPet = function()
		LUIPetBar:ClearAllPoints()
		LUIPetBar:SetPoint("RIGHT", UIParent, "RIGHT", tonumber(bardb.Petbar.X), tonumber(bardb.Petbar.Y))
		LUIPetBar:SetScale(tonumber(bardb.Petbar.Scale))
	end
	
	local ApplySettingsShapeshift = function()
		LUIShapeshiftBar:ClearAllPoints()
		LUIShapeshiftBar:SetPoint("LEFT", UIParent, "LEFT", tonumber(bardb.Shapeshiftbar.X), tonumber(bardb.Shapeshiftbar.Y))
		LUIShapeshiftBar:SetScale(tonumber(bardb.Shapeshiftbar.Scale))
	end
	
	local ApplySettingsVehicleExit = function()
		LUIVehicleExit:ClearAllPoints()
		LUIVehicleExit:SetPoint("CENTER", UIParent, "CENTER", tonumber(bardb.VehicleExit.X), tonumber(bardb.VehicleExit.Y))
		LUIVehicleExit:SetScale(tonumber(bardb.VehicleExit.Scale))
	end
	
	local LoadStatesBlizzard = function()
		LoadStates(blizzstate)
		LUIBar1.UpdateState()
		LUIBar2.UpdateState()
		LUIBar3.UpdateState()
		LUIBarLeft.UpdateState()
		LUIBarRight.UpdateState()
	end
	
	local LoadStatesLUI = function()
		LoadStates(defaultstate)
		LUIBar1.UpdateState()
		LUIBar2.UpdateState()
		LUIBar3.UpdateState()
		LUIBarLeft.UpdateState()
		LUIBarRight.UpdateState()
	end
	
	local ToggleKeybind = function() LibKeyBound:Toggle() end
	
	local options = {
		Bars = {
			name = "Bars",
			type = "group",
			order = 15,
			disabled = function() return InCombatLockdown() end,
			childGroups = "tab",
			args = {
				Settings = {
					name = "General",
					type = "group",
					order = 2,
					args = {
						GeneralSettings = not isBarAddOnLoaded and {
							name = "General",
							type = "group",
							order = 1,
							guiInline = true,
							args = {
								ShowHotkey = LUI:NewToggle("Show Hotkey Text", "Whether you want to show hotkey text or not.", 1, bardb, "ShowHotkey", bardefaults, ToggleTexts),
								ShowMacro = LUI:NewToggle("Show Macro Text", "Whether you want to show macro text or not.", 2, bardb, "ShowMacro", bardefaults, ToggleTexts),
								ShowCount = LUI:NewToggle("Show Count Text", "Whether you want to show count text or not.", 3, bardb, "ShowCount", bardefaults, ToggleTexts),
								empty = LUI:NewEmpty(4),
								ShowEquipped = LUI:NewToggle("Show Equipped Borders", "Whether you want to show the green equipped borders or not.", 5, bardb, "ShowEquipped", bardefaults, ToggleEquipped),
								empty2 = LUI:NewEmpty(6),
								LoadBlizz = LUI:NewExecute("Load Blizzard States", "Load the Blizzard Default Bar States.", 7, LoadStatesBlizzard),
								LoadLUI = LUI:NewExecute("Load LUI States", "Load the LUI Default Bar States.", 8, LoadStatesLUI),
								empty3 = LUI:NewEmpty(9),
								ToggleKeybind = LUI:NewExecute("Keybinds", "Toggles Keybinding Mode", 10, ToggleKeybind),
							},
						} or nil,
						TopTextureSettings = {
							name = "Bars Top Texture Settings",
							type = "group",
							order = 3,
							guiInline = true,
							args = {
								Toggle = LUI:NewToggle("Enable", "Whether you want to show the Top Bar Texture or not.", 1, bardb.TopTexture, "Enable", bardefaults.TopTexture, ApplySettings),
								Alpha = LUI:NewSlider("Alpha", "Choose your Bar Top Texture Alpha Value.", 2, bardb.TopTexture, "Alpha", bardefaults.TopTexture, 0, 1, 0.1, ApplySettings, nil, DisabledTopBarTex),
								XOffset = LUI:NewPosX("Top Bar Texture", 3, bardb.TopTexture, "", bardefaults.TopTexture, ApplySettings, nil, DisabledTopBarTex),
								YOffset = LUI:NewPosY("Top Bar Texture", 4, bardb.TopTexture, "", bardefaults.TopTexture, ApplySettings, nil, DisabledTopBarTex),
							},
						},
						TopBarAnimation = LUI.isForteCooldownLoaded and {
							name = "Bar Animation",
							type = "group",
							guiInline = true,
							--disabled = function() return not LUI.isForteCooldownLoaded end,
							order = 4,
							args = {
								Desc = LUI:NewDesc("This Feature will be only available if you are using ForteXorcist CooldownTimer.", 1),
								empty23223342211 = LUI:NewEmpty(2),
								Animation = LUI:NewToggle("Enable Bar Texture Animation", "Whether you want to show the Bar Texture Animation or not.", 3, bardb.TopTexture, "Animation", bardefaults.TopTexture, ApplySettings, nil, DisabledTopBarTex),
								AnimationHeight = LUI:NewHeight("Top Bar Texture Animation", 4, bardb.TopTexture, "AnimationHeight", bardefaults.TopTexture, ApplySettings, nil, DisabledTopBarTex),
							},
						} or nil,
						BottomTextureSettings = {
							name = "Bars Bottom Texture Settings",
							type = "group",
							guiInline = true,
							order = 5,
							args = {
								Toggle = LUI:NewToggle("Enable", "Whether you want to show the Bottom Bar Texture or not.", 1, bardb.BottomTexture, "Enable", bardefaults.BottomTexture, ApplySettings),
								Alpha = LUI:NewSlider("Alpha", "Choose your Bar Bottom Texture Alpha Value.", 2, bardb.BottomTexture, "Alpha", bardefaults.BottomTexture, 0, 1, 0.1, ApplySettings, nil, DisabledBottomBarTex),
								XOffset = LUI:NewPosX("Bottom Bar Texture", 3, bardb.BottomTexture, "", bardefaults.BottomTexture, ApplySettings, nil, DisabledBottomBarTex),
								YOffset = LUI:NewPosY("Bottom Bar Texture", 4, bardb.BottomTexture, "", bardefaults.BottomTexture, ApplySettings, nil, DisabledBottomBarTex),
							},
						},
					},
				},
				Bottombar1 = not isBarAddOnLoaded and module:CreateBottombarOptions(1, 3) or nil,
				Bottombar2 = not isBarAddOnLoaded and module:CreateBottombarOptions(2, 4) or nil,
				Bottombar3 = not isBarAddOnLoaded and module:CreateBottombarOptions(3, 5) or nil,
				SidebarRight = module:CreateSidebarOptions("Right", 6),
				SidebarLeft = module:CreateSidebarOptions("Left", 7),
				Otherbars = not isBarAddOnLoaded and {
					name = "Other Bars",
					type = "group",
					order = 8,
					args = {
						PetHeader = LUI:NewHeader("Pet Bar", 1, "full"),
						PetXValue = LUI:NewPosX("Pet Bar", 2, bardb.Petbar, "", bardefaults.Petbar, ApplySettingsPet),
						PetYValue = LUI:NewPosY("Pet Bar", 3, bardb.Petbar, "", bardefaults.Petbar, ApplySettingsPet),
						empty1 = LUI:NewEmpty(4),
						PetScale = LUI:NewSlider("Scale", "Choose the Scale of your Pet Bar.", 5, bardb.Petbar, "Scale", bardefaults.Petbar, 0.1, 1.5, 0.05, ApplySettingsPet),
						empty2 = LUI:NewEmpty(6),
						
						ShapeshiftHeader = LUI:NewHeader("Shapeshift Bar", 7, "full"),
						ShapeshiftXValue = LUI:NewPosX("Shapeshift Bar", 8, bardb.Shapeshiftbar, "", bardefaults.Shapeshiftbar, ApplySettingsShapeshift),
						ShapeshiftYValue = LUI:NewPosY("Shapeshift Bar", 9, bardb.Shapeshiftbar, "", bardefaults.Shapeshiftbar, ApplySettingsShapeshift),
						empty3 = LUI:NewEmpty(10),
						ShapeshiftScale = LUI:NewSlider("Scale", "Choose the Scale of your Shapeshift Bar.", 11, bardb.Shapeshiftbar, "Scale", bardefaults.Shapeshiftbar, 0.1, 1.5, 0.05, ApplySettingsShapeshift),
						empty4 = LUI:NewEmpty(12),
						
						VehicleHeader = LUI:NewHeader("Vehicle Exit Button", 13, "full"),
						VehicleXValue = LUI:NewPosX("Vehicle Exit Button", 14, bardb.VehicleExit, "", bardefaults.VehicleExit, ApplySettingsVehicleExit),
						VehicleYValue = LUI:NewPosY("Vehicle Exit Button", 15, bardb.VehicleExit, "", bardefaults.VehicleExit, ApplySettingsVehicleExit),
						empty5 = LUI:NewEmpty(16),
						VehicleScale = LUI:NewSlider("Scale", "Choose the Scale of your Vehicle Exit Button.", 17, bardb.VehicleExit, "Scale", bardefaults.VehicleExit, 0.1, 1.5, 0.05, ApplySettingsVehicleExit),
					},
				} or nil,
			},
		},
	}
	
	return options
end

function module:OnInitialize()
	LUI:MergeDefaults(LUI.db.defaults.profile, defaults)
	LUI:RefreshDefaults()
	LUI:Refresh()
	
	self.db = LUI.db.profile
	db = self.db
	
	LUI:RegisterOptions(self)
end

function module:OnEnable()
	module:SetBars()
end

function module:OnDisable()
end
