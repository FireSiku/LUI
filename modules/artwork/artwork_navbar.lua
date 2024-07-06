-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Artwork : LUIModule
local module = LUI:GetModule("Artwork")
local db

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

function module:CreateNavBar()
	db = self.db.profile


end

-- ####################################################################################################################
-- ##### Snippets of Old Code #############################################################################################
-- ####################################################################################################################
--[[ 

	local function SetFrameBackdrop(frame, fileName)
		if not frame then LUI:Print("frame not found:", fileName) end
		frame.Backdrop = {
			bgFile = directory..fileName,
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			edgeSize = 1,
			insets = {left = 0, right = 0, top = 0, bottom = 0}
		}
		frame:SetBackdrop(frame.Backdrop)
		frame:SetBackdropBorderColor(0,0,0,0)
	end

	LUI.Navi.TopButtonBackground = LUI:CreateMeAFrame("Frame", nil, UIParent, 1024, 1024, 1, "BACKGROUND", 1, "TOP", UIParent, "TOP", 17, -16, 1)
	SetFrameBackdrop(LUI.Navi.TopButtonBackground, "top")
	LUI.Navi.TopButtonBackground:Show()

	LUI.Navi.CenterBackground = LUI:CreateMeAFrame("Frame", nil, UIParent, 1035, 1024, 1, "BACKGROUND", 0, "TOP", UIParent, "TOP", 17, -17, 1)
	SetFrameBackdrop(LUI.Navi.CenterBackground, "top_back")
	LUI.Navi.CenterBackground:SetBackdropColor(unpack(color_top))
	LUI.Navi.CenterBackground:Show()

	LUI.Navi.CenterBackgroundAlternative = LUI:CreateMeAFrame("Frame", nil, UIParent, 1035, 1024, 1, "BACKGROUND", 0, "TOP", UIParent, "TOP", 17, -17, 1)
	SetFrameBackdrop(LUI.Navi.CenterBackgroundAlternative, "top_back_complete")
	LUI.Navi.CenterBackgroundAlternative:SetBackdropColor(unpack(color_top))
	LUI.Navi.CenterBackgroundAlternative:Hide()

	-- Chat button.
	LUI.Navi.Chat = LUI:CreateMeAFrame("Frame", nil, LUI.Orb, 126, 120, 1, "LOW", 1, "LEFT", LUI.Orb, "LEFT", -176, 49, 0)
	LUI.Navi.Chat:SetBackdrop({
		bgFile = directory.."button_left2",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.Navi.Chat:SetBackdropColor(unpack(navi))
	LUI.Navi.Chat:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Navi.Chat:Show()

	LUI.Navi.Chat.Hover = LUI:CreateMeAFrame("Frame", nil, LUI.Orb, 124, 120, 1, "LOW", 1, "LEFT", LUI.Orb, "LEFT", -176, 49, 0)
	LUI.Navi.Chat.Hover:SetBackdrop({
		bgFile = directory.."button_left2_hover",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.Navi.Chat.Hover:SetBackdropColor(unpack(navi_hover))
	LUI.Navi.Chat.Hover:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Navi.Chat.Hover:Show()

	LUI.Navi.Chat.Clicker = CreateFrame("Button", nil, LUI.Navi.Chat)
	LUI.Navi.Chat.Clicker:SetWidth(70)
	LUI.Navi.Chat.Clicker:SetHeight(30)
	LUI.Navi.Chat.Clicker:SetScale(1)
	LUI.Navi.Chat.Clicker:SetFrameStrata("LOW")
	LUI.Navi.Chat.Clicker:SetFrameLevel(2)
	LUI.Navi.Chat.Clicker:SetPoint("CENTER", LUI.Navi.Chat, "CENTER", -5, -42)
	LUI.Navi.Chat.Clicker:SetAlpha(0)

	LUI.Navi.Chat.Clicker:RegisterForClicks("AnyUp")
	LUI.Navi.Chat.Clicker:SetScript("OnEnter", function(self) LUI.Navi.Chat.Hover:SetAlpha(1) end)
	LUI.Navi.Chat.Clicker:SetScript("OnLeave", function(self) LUI.Navi.Chat.Hover:SetAlpha(0) end)
	LUI.Navi.Chat.Clicker:SetScript("OnClick", function(self)
		if LUI.Navi.Chat:GetAlpha() == 0 then
			LUI.Navi.Chat.AlphaIn:Show()
			module:AlphaIn("Chat")
			db.Chat.IsShown = true
			LUI:SetChatVisible(true)
		else
			LUI.Navi.Chat.AlphaOut:Show()
			module:AlphaOut("Chat")
			db.Chat.IsShown = false
			LUI:SetChatVisible(true)
		end
	end)

-- TPS button.
	LUI.Navi.Tps = LUI:CreateMeAFrame("Frame", nil, LUI.Orb, 63, 67, 1, "LOW", 1, "LEFT", LUI.Orb, "LEFT", -74, 18, 0)
	LUI.Navi.Tps:SetBackdrop({
		bgFile = directory.."button_left1",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.Navi.Tps:SetBackdropColor(unpack(navi))
	LUI.Navi.Tps:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Navi.Tps:Show()

	LUI.Navi.Tps.Hover = LUI:CreateMeAFrame("Frame", nil, LUI.Orb, 63, 60, 1, "LOW", 1, "LEFT", LUI.Orb, "LEFT", -74, 16, 0)
	LUI.Navi.Tps.Hover:SetBackdrop({
		bgFile = directory.."button_left1_hover",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.Navi.Tps.Hover:SetBackdropColor(unpack(navi_hover))
	LUI.Navi.Tps.Hover:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Navi.Tps.Hover:Show()

	LUI.Navi.Tps.Clicker = CreateFrame("Button", nil, LUI.Navi.Tps)
	LUI.Navi.Tps.Clicker:SetWidth(63)
	LUI.Navi.Tps.Clicker:SetHeight(30)
	LUI.Navi.Tps.Clicker:SetScale(1)
	LUI.Navi.Tps.Clicker:SetFrameStrata("LOW")
	LUI.Navi.Tps.Clicker:SetFrameLevel(2)
	LUI.Navi.Tps.Clicker:SetPoint("CENTER", LUI.Navi.Tps, "CENTER", 0, -12)
	LUI.Navi.Tps.Clicker:SetAlpha(0)

	LUI.Navi.Tps.Clicker:RegisterForClicks("AnyUp")
	LUI.Navi.Tps.Clicker:SetScript("OnEnter", function(self) LUI.Navi.Tps.Hover:SetAlpha(1) end)
	LUI.Navi.Tps.Clicker:SetScript("OnLeave", function(self) LUI.Navi.Tps.Hover:SetAlpha(0) end)
	LUI.Navi.Tps.Clicker:SetScript("OnClick", function(self)
		if _G[db.Tps.Anchor] and LUI:CanAlterFrame(_G[db.Tps.Anchor]) then
			if LUI.Navi.Tps:GetAlpha() == 0 then
				LUI.Navi.Tps.AlphaIn:Show()
				module:AlphaIn("Tps")
				db.Tps.IsShown = true
			else
				LUI.Navi.Tps.AlphaOut:Show()
				module:AlphaOut("Tps")
				db.Tps.IsShown = false
			end
		end
	end)

-- DPS button.
	LUI.Navi.Dps = LUI:CreateMeAFrame("Frame", nil, LUI.Orb, 63, 67, 1, "LOW", 1, "RIGHT", LUI.Orb, "RIGHT", 77, 21, 0)
	LUI.Navi.Dps:SetBackdrop({
		bgFile = directory.."button_right1",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.Navi.Dps:SetBackdropColor(unpack(navi))
	LUI.Navi.Dps:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Navi.Dps:Show()

	LUI.Navi.Dps.Hover = LUI:CreateMeAFrame("Frame", nil, LUI.Orb, 63, 60, 1, "LOW", 1, "RIGHT", LUI.Orb, "RIGHT", 77, 19, 0)
	LUI.Navi.Dps.Hover:SetBackdrop({
		bgFile = directory.."button_right1_hover",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.Navi.Dps.Hover:SetBackdropColor(unpack(navi_hover))
	LUI.Navi.Dps.Hover:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Navi.Dps.Hover:Show()

	LUI.Navi.Dps.Clicker = CreateFrame("Button", nil, LUI.Navi.Dps)
	LUI.Navi.Dps.Clicker:SetWidth(63)
	LUI.Navi.Dps.Clicker:SetHeight(30)
	LUI.Navi.Dps.Clicker:SetScale(1)
	LUI.Navi.Dps.Clicker:SetFrameStrata("LOW")
	LUI.Navi.Dps.Clicker:SetFrameLevel(2)
	LUI.Navi.Dps.Clicker:SetPoint("CENTER", LUI.Navi.Dps, "CENTER", 0, -12)
	LUI.Navi.Dps.Clicker:SetAlpha(0)

	LUI.Navi.Dps.Clicker:RegisterForClicks("AnyUp")
	LUI.Navi.Dps.Clicker:SetScript("OnEnter", function(self) LUI.Navi.Dps.Hover:SetAlpha(1) end)
	LUI.Navi.Dps.Clicker:SetScript("OnLeave", function(self) LUI.Navi.Dps.Hover:SetAlpha(0) end)
	LUI.Navi.Dps.Clicker:SetScript("OnClick", function(self)
		if _G[db.Dps.Anchor] and LUI:CanAlterFrame(_G[db.Dps.Anchor]) then
			if LUI.Navi.Dps:GetAlpha() == 0 then
				LUI.Navi.Dps.AlphaIn:Show()
				module:AlphaIn("Dps")
				db.Dps.IsShown = true
			else
				LUI.Navi.Dps.AlphaOut:Show()
				module:AlphaOut("Dps")
				db.Dps.IsShown = false
			end
		end
	end)


-- Raid button.
	LUI.Navi.Raid = LUI:CreateMeAFrame("Frame", nil, LUI.Orb, 126, 120, 1, "LOW", 1, "RIGHT", LUI.Orb, "RIGHT", 184, 47, 0)
	LUI.Navi.Raid:SetBackdrop({
		bgFile = directory.."button_right2",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.Navi.Raid:SetBackdropColor(unpack(navi))
	LUI.Navi.Raid:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Navi.Raid:Show()

	LUI.Navi.Raid.Hover = LUI:CreateMeAFrame("Frame", nil, LUI.Orb, 124, 120, 1, "LOW", 1, "RIGHT", LUI.Orb, "RIGHT", 182, 47, 0)
	LUI.Navi.Raid.Hover:SetBackdrop({
		bgFile = directory.."button_right2_hover",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	})
	LUI.Navi.Raid.Hover:SetBackdropColor(unpack(navi_hover))
	LUI.Navi.Raid.Hover:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.Navi.Raid.Hover:Show()

	LUI.Navi.Raid.Clicker = CreateFrame("Button", nil, LUI.Navi.Raid)
	LUI.Navi.Raid.Clicker:SetWidth(78)
	LUI.Navi.Raid.Clicker:SetHeight(30)
	LUI.Navi.Raid.Clicker:SetScale(1)
	LUI.Navi.Raid.Clicker:SetFrameStrata("LOW")
	LUI.Navi.Raid.Clicker:SetFrameLevel(2)
	LUI.Navi.Raid.Clicker:SetPoint("CENTER", LUI.Navi.Raid, "CENTER", 0, -42)
	LUI.Navi.Raid.Clicker:SetAlpha(0)

	LUI.Navi.Raid.Clicker:RegisterForClicks("AnyUp")
	LUI.Navi.Raid.Clicker:SetScript("OnEnter", function(self) LUI.Navi.Raid.Hover:SetAlpha(1) end)
	LUI.Navi.Raid.Clicker:SetScript("OnLeave", function(self) LUI.Navi.Raid.Hover:SetAlpha(0) end)
	LUI.Navi.Raid.Clicker:SetScript("OnClick", function(self)
		if _G[db.Raid.Anchor] and LUI:CanAlterFrame(_G[db.Raid.Anchor]) then
			if LUI.Navi.Raid:GetAlpha() == 0 then
				LUI.Navi.Raid.AlphaIn:Show()
				module:AlphaIn("Raid")
				db.Raid.IsShown = true
			else
				LUI.Navi.Raid.AlphaOut:Show()
				module:AlphaOut("Raid")
				db.Raid.IsShown = false
			end
		end
	end)

--]]
