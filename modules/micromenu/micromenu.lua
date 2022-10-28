-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, LUIAddon
local _, LUI = ...
local L = LUI.L

---@class MicromenuModule : LUIModule
local module = LUI:NewModule("Micromenu", "AceEvent-3.0")
local db

local hooksecurefunc = _G.hooksecurefunc
local GameMenuFrame = _G.GameMenuFrame
local IsAddOnLoaded = _G.IsAddOnLoaded
local FriendsFrame = _G.FriendsFrame
local HideUIPanel = _G.HideUIPanel
local ShowUIPanel = _G.ShowUIPanel
local UnitLevel = _G.UnitLevel
local IsBagOpen = _G.IsBagOpen
local format = format

local addonLoadedCallbacks = {}
local microStorage = {}

-- List of buttons, starting from the right.
local microList = {
	"Bags",  -- Setting should be first, but textures not ready yet
	"Settings",
	"Bags",
	"Store",
	"Collections",
	"EJ",
	"LFG",
	"Guild",
	"Quests",
	"Achievements",
	"Talents",
	"Spellbook",
	"Player",
}

-- Constants

local TEXTURE_PATH_FORMAT = "Interface\\AddOns\\LUI\\modules\\micromenu\\micro_%s.tga"
local BACKGROUND_TEXTURE_PATH = "Interface\\AddOns\\LUI\\modules\\micromenu\\micro_background.tga"
local FIRST_TEXTURE_SIZE_WIDTH = 46
local LAST_TEXTURE_SIZE_WIDTH = 48
local TEXTURE_SIZE_HEIGHT = 28
local TEXTURE_SIZE_WIDTH = 33
local ALERT_ALPHA_MULT = 0.7

-- the clickable area is only 27x24
-- Wide buttons clickable area: 42x24

local WIDE_TEXTURE_CLICK_HEIGHT = 24
local WIDE_TEXTURE_CLICK_WIDTH = 42
local TEXTURE_CLICK_HEIGHT = 24
local TEXTURE_CLICK_WIDTH = 27

-- Level Requirements

local TALENT_LEVEL_REQ = 10
local LFG_LEVEL_REQ = 10

-- ####################################################################################################################
-- ##### Default Settings #############################################################################################
-- ####################################################################################################################

module.enableButton = true

module.defaults = {
	profile = {
		HideSettings = false,
		HideBags = false,
		HideStore = false,
		HideCollections = false,
		HideEJ = false,
		HideLFG = false,
		HideGuild = false,
		HideQuests = false,
		HideAchievements = false,
		HideTalents = false,
		HideSpellbook = false,
		HidePlayer = false,
		ColorMatch = true,
		Spacing = 1,
		Point = "TOPRIGHT",
		Direction = "RIGHT",
		X = -15,
		Y = -18,
		Colors = {
			Background = { r = 0.12, g = 0.12,  b = 0.12, a = 1, t = "Class", },
			Micromenu = { r = 0.12, g = 0.58,  b = 0.89, a = 1, t = "Class", },
		},
	},
}

-- ####################################################################################################################
-- ##### MicroButton Definitions ######################################################################################
-- ####################################################################################################################

local microDefinitions = {

	{ -- [1]
		name = "Settings",
		title = L["Options"],
		left = L["MicroSettings_Right"],
		right = L["MicroSettings_Left"],
		state = "ConsolidatedOptionsFrame",
		OnClick = function(self, btn)
			if btn == "RightButton" then
				--WoW Option Panel
				module:TogglePanel(GameMenuFrame)
			else
				--LUI Option Panel
				LUI:OpenOptions()
			end
		end,
	},

	{ -- [2] Currently 1 due to workaround.
		name = "Bags",
		title = L["Bags_Name"],
		any = L["MicroBags_Any"],
		state = "ConsolidatedBagFrame",
		OnClick = function(self, btn)
			_G.ToggleAllBags()
		end,
	},

	{ -- [3]
		name = "Store",
		title = L["MicroStore_Name"],
		any = L["MicroStore_Any"],
		OnClick = function(self, btn)
			_G.ToggleStoreUI()
		end,
	},

	{ -- [4]
		name = "Collections",
		alertFrame = "Collections",
		title = L["MicroCollect_Name"],
		any = L["MicroCollect_Any"],
		state = "CollectionsJournal",
		addon = "Blizzard_CollectionsJournal",
		OnClick = function(self, btn)
			_G.ToggleCollectionsJournal()
		end,
	},

	{ -- [5]
		name = "EJ",
		alertFrame = "EJ",
		title = L["MicroEJ_Name"],
		any = L["MicroEJ_Any"],
		state = "EncounterJournal",
		addon = "Blizzard_EncounterJournal",
		OnClick = function(self, btn)
			_G.ToggleEncounterJournal()
		end,
	},

	{ -- [6]
		name = "LFG",
		level = LFG_LEVEL_REQ,
		title = L["MicroLFG_Name"],
		left = L["MicroLFG_Left"],
		right = L["MicroLFG_Right"],
		state = "PVEFrame",
		OnClick = function(self, btn)
			if btn == "RightButton" then
				_G.TogglePVPUI()
			else
				_G.ToggleLFDParentFrame()
			end
		end,
	},

	{ -- [7]
		name = "Guild",
		title = L["MicroGuild_Name"],
		left = L["MicroGuild_Left"],
		right = L["MicroGuild_Right"],
		state = "ConsolidatedSocialFrame",
		OnClick = function(self, btn)
			if btn == "RightButton" then
				_G.ToggleFriendsFrame()
			else
				_G.ToggleGuildFrame()
			end
		end,
	},

	{ -- [8]
		name = "Quests",
		title = L["MicroQuest_Name"],
		any = L["MicroQuest_Any"],
		OnClick = function(self, btn)
			_G.ToggleWorldMap()
		end,
	},

	{ -- [9]
		name = "Achievements",
		title = L["MicroAch_Name"],
		any = L["MicroAch_Any"],
		state = "AchievementFrame",
		addon = "Blizzard_AchievementUI",
		OnClick = function(self, btn)
			_G.ToggleAchievementFrame()
		end,
	},

	{ -- [10]
		name = "Talents",
		alertFrame = "Talent",
		level = TALENT_LEVEL_REQ,
		title = L["MicroTalents_Name"],
		any = L["MicroTalents_Any"],
		state = "PlayerTalentFrame",
		addon = "Blizzard_TalentUI",
		OnClick = function(self, btn)
			_G.ToggleTalentFrame()
		end,
	},

	{ -- [11]
		name = "Spellbook",
		title = L["MicroSpell_Name"],
		any = L["MicroSpell_Any"],
		state = "SpellBookFrame",
		OnClick = function(self, btn)
			module:TogglePanel(_G.SpellBookFrame)
		end,
	},

	{ -- [12]
		name = "Player",
		isWide = "Left",
		title = L["MicroPlayer_Name"],
		any = L["MicroPlayer_Any"],
		state = "CharacterFrame",
		OnClick = function(self, btn)
			module:TogglePanel(_G.CharacterFrame)
		end,
	},
}

-- ####################################################################################################################
-- ##### MicroButton Mixin #########################################################################################
-- ####################################################################################################################

---@class MicroButton : Button
local MicroButtonClickerMixin = {}

function MicroButtonClickerMixin:OnEnter()
	self:SetAlpha(1)
	self.Hover = true
	GameTooltip:SetOwner(self, "ANCHOR_NONE ", 40, -100)

	local parent = self:GetParent()
	GameTooltip:SetText(parent.title)
	if parent.any then GameTooltip:AddLine(parent.any, 1, 1, 1) end
	if parent.left then GameTooltip:AddLine(parent.left, 1, 1, 1) end
	if parent.right then GameTooltip:AddLine(parent.right, 1, 1, 1) end
	if parent.level and UnitLevel("player") < parent.level then
		GameTooltip:AddLine(format(L["Micro_PlayerReq"], parent.level), LUI:NegativeColor())
	end
	GameTooltip:Show()
end

function MicroButtonClickerMixin:OnLeave()
	self:SetAlpha(self:GetParent().Opened and 1 or 0)
	self.Hover = nil
	GameTooltip:Hide()
end

MicroButtonClickerMixin.clickerBackdrop = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = nil, tile = false, tileSize = 0, edgeSize = 1,
	insets = {left = 0, right = 0, top = 0, bottom = 0}
}

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

-- Function to attach the alert frame to point to micromenu buttons
-- function module:HookAlertFrame(name, anchor)
-- 	local r, g, b, a = module:RGBA("Micromenu")
-- 	local alertFrame      = _G[name.."MicroButtonAlert"]
-- 	local alertFrameBg    = _G[name.."MicroButtonAlertBg"]
-- 	local alertFrameArrow = _G[name.."MicroButtonAlertArrow"]
-- 	local alertFrameGlow  = _G[name.."MicroButtonAlertGlow"]

-- 	alertFrame:ClearAllPoints()
-- 	alertFrame:SetPoint("TOP", anchor, "BOTTOM", 0, -12)
-- 	alertFrameBg:SetGradient("VERTICAL", CreateColor(r/4, g/4, b/4, 1), CreateColor(0, 0, 0, 1))
-- 	alertFrameArrow:ClearAllPoints()
-- 	alertFrameArrow:SetPoint("BOTTOM", alertFrame, "TOP", 0, -10)
-- 	alertFrameArrow:SetDesaturated(true)
-- 	alertFrameArrow:SetVertexColor(r, g, b, a * ALERT_ALPHA_MULT)
-- 	alertFrameGlow:SetVertexColor(r, g, b, a * ALERT_ALPHA_MULT)
-- 	alertFrameGlow:SetDesaturated(true)
-- 	alertFrameGlow:ClearAllPoints()
-- 	alertFrameGlow:SetAllPoints(alertFrameArrow)
-- 	module:SetAlertFrameColors(name)
-- end

-- -- Function to change the color of an alert frame to match micromenu.
-- local gAlertGlows = {"TopLeft", "TopRight", "BottomLeft", "BottomRight", "Top", "Bottom", "Left", "Right"}
-- function module:SetAlertFrameColors(name)
-- 	local r, g, b, a = module:RGBA("Micromenu")
-- 	_G[name.."MicroButtonAlertBg"]:SetGradient("VERTICAL", CreateColor(r/4, g/4, b/4, 1), CreateColor(0, 0, 0, 1))
-- 	_G[name.."MicroButtonAlertArrow"]:SetVertexColor(r, g, b, a * ALERT_ALPHA_MULT)
-- 	_G[name.."MicroButtonAlertGlow"]:SetVertexColor(r, g, b, a * ALERT_ALPHA_MULT)
-- 	for i = 1, #gAlertGlows do
-- 		local tex = _G[name.."MicroButtonAlertGlow"..gAlertGlows[i]]
-- 		tex:SetDesaturated(true)
-- 		tex:SetVertexColor(r, g, b)
-- 	end
-- end

function module:TogglePanel(panel)
	if panel:IsShown() then
		HideUIPanel(panel)
	else
		ShowUIPanel(panel)
	end
end

function module:GetDirectionalTexCoord(atlas)
	local left, right, top, bottom = LUI:GetCoordAtlas(atlas)

	if db.Direction == "LEFT" then
		return right, left, top, bottom
	end

	return left, right, top, bottom
end

--- Updates the micromenu clicker alpha based on frames being shown and hidden. Works well and looks OK
---@param button MicroButton @ The actual micromenu button object
---@param objectName string @ The object to hook and use as state update reference
function module:ClickerStateUpdateHandler(button, objectName)
	local objectToHook = _G[objectName]
	-- Just in case
	if not objectToHook then return end

	local function UpdateState()
		button.Opened = (objectToHook:IsShown() and true or false)
		button.clicker:SetAlpha((button.Opened or button.clicker.Hover) and 1 or 0)
	end

	-- Hook Show and Hide to trigger an update
	hooksecurefunc(objectToHook, "Show", UpdateState)
	hooksecurefunc(objectToHook, "Hide", UpdateState)
end

--- Create a new MicroButton
---@param buttonData table @ Sub-tables from microDefinition
---@return MicroButton
function module:NewMicroButton(buttonData)
	local r, g, b, a_ = module:RGBA("Micromenu")
	local name = buttonData.name

	local button = CreateFrame("Frame", "LUIMicromenu_"..name, UIParent)
	button:SetSize(TEXTURE_SIZE_WIDTH, TEXTURE_SIZE_HEIGHT)
	Mixin(button, buttonData)

	-- Make an icon for the button
	button.icon = button:CreateTexture(nil, "ARTWORK")
	button.icon:SetPoint("CENTER", 0, 0)
	button.icon:SetTexture(format(TEXTURE_PATH_FORMAT, strlower(name)))
	button.icon:SetTexCoord(LUI:GetCoordAtlas("MicroBtn_Icon"))
	button.icon:SetVertexColor(r, g, b)

	-- Make a border for the button
	button.border = button:CreateTexture(nil, "ARTWORK")
	button.border:SetAllPoints()
	button.border:SetTexture(format(TEXTURE_PATH_FORMAT, "border"))
	button.border:SetTexCoord(LUI:GetCoordAtlas("MicroBtn_Default"))
	button.border:SetVertexColor(r, g, b)

	-- Make a button for the clickable area of the texture with black background.
	button.clicker = CreateFrame("Button", nil, button, "BackdropTemplate")
	button.clicker:SetSize(TEXTURE_CLICK_WIDTH , TEXTURE_CLICK_HEIGHT)
	button.clicker:RegisterForClicks("AnyUp")
	button.clicker:SetBackdrop(MicroButtonClickerMixin.clickerBackdrop)
	button.clicker:SetPoint("CENTER", button, "CENTER", -1, 0)
	button.clicker:SetBackdropColor(0, 0, 0, 1)
	button.clicker:SetAlpha(0)
	-- Push down the clicker frame so it doesn't go above the texture.
	button.clicker:SetFrameLevel(button:GetFrameLevel()-1)

	-- Handle some definition-based info
	if button.OnClick then
		button.clicker:SetScript("OnClick", button.OnClick)
	end
	-- This is a bit of a mess and can probably be modified
	if button.state then
		if button.addon then
			if not IsAddOnLoaded(button.addon) then
				addonLoadedCallbacks[button.addon] = function()
					module:ClickerStateUpdateHandler(button, button.state)
				end
			else
				module:ClickerStateUpdateHandler(button, button.state)
			end
		else
			module:ClickerStateUpdateHandler(button, button.state)
		end
	end

	-- if button.alertFrame then
	-- 	module:HookAlertFrame(button.alertFrame, button)
	-- end

	button.clicker:SetScript("OnEnter", MicroButtonClickerMixin.OnEnter)
	button.clicker:SetScript("OnLeave", MicroButtonClickerMixin.OnLeave)
	return button
end

-- ####################################################################################################################
-- ##### Consolidated Frames ##########################################################################################
-- ####################################################################################################################
-- Consolidate all the possible options frames into one to make it easy to hook

function module:ConsolidateOptionsFrames()
	local optionsFrames = CreateFrame("Frame", "ConsolidatedOptionsFrame", UIParent)
	local ACD = LibStub("AceConfigDialog-3.0")

	local function UpdateState()
		-- When hooked frames are shown or hidden, check if any frame is currently open and update consolidated state
		if GameMenuFrame:IsShown() or ACD.OpenFrames["LUI4Options"] then
			optionsFrames:Show()
		else
			optionsFrames:Hide()
		end
	end

	-- The GameMenuFrame is easy enough
	hooksecurefunc(GameMenuFrame, "Show", UpdateState)
	hooksecurefunc(GameMenuFrame, "Hide", UpdateState)

	-- We can use ACD to hook Open, which is fired when any options frame is opened
	if ACD then
		hooksecurefunc(ACD, "Open", function()
			-- We get the LUI options frame, if its there
			local optionsFrame = ACD.OpenFrames["LUI4Options"]
			if optionsFrame then
				-- Register a callback for when the frame is closed
				hooksecurefunc(optionsFrame, "Hide", UpdateState)
				-- Invoke update for this opening
				UpdateState()
			end
		end)
	end
end

function module:ConsolidateSocialFrames()
	local socialFrames = CreateFrame("Frame", "ConsolidatedSocialFrame", UIParent)

	-- When hooked frames are shown or hidden, check if any frame is currently open and update consolidated state
	local function UpdateState()
		if FriendsFrame:IsShown() or (_G.CommunitiesFrame and _G.CommunitiesFrame:IsShown()) then
			socialFrames:Show()
		else
			socialFrames:Hide()
		end
	end

	-- Hook OnShow and OnHide from the friends frame
	FriendsFrame:HookScript("OnShow", UpdateState)
	FriendsFrame:HookScript("OnHide", UpdateState)

	-- Hook OnShow and OnHide from the communities frame once its available
	addonLoadedCallbacks["Blizzard_Communities"] = function()
		_G.CommunitiesFrame:HookScript("OnShow", UpdateState)
		_G.CommunitiesFrame:HookScript("OnHide", UpdateState)
	end
end

function module:ConsolidateBagFrames()
	local bagFrames = CreateFrame("Frame", "ConsolidatedBagFrame", UIParent)

	-- AddOn support
	local addonBagFrame
	-- ENABLE ONCE MODULE IS DONE
	-- if LUI:GetModule("Bags").db.profile.Enable then
	-- 	addonBagFrame = LUIBags
	-- else
	if IsAddOnLoaded("Stuffing") then
		addonBagFrame = _G.StuffingFrameBags
	elseif IsAddOnLoaded("Bagnon") then
		addonBagFrame = _G.BagnonFrameinventory
	elseif IsAddOnLoaded("ArkInventory") then
		addonBagFrame = _G.ARKINV_Frame1
	elseif IsAddOnLoaded("OneBag") then
		addonBagFrame = _G.OneBagFrame
	else
		addonBagFrame = nil
	end

	-- When hooked frames are shown or hidden, check if any frame is currently open and update consolidated state
	local function UpdateState()
		if (addonBagFrame and addonBagFrame:IsShown()) or IsBagOpen(0) or IsBagOpen(1) or IsBagOpen(2) or IsBagOpen(3) or IsBagOpen(4) then
			bagFrames:Show()
		else
			bagFrames:Hide()
		end
	end

	-- Hook OnShow and OnHide from the default UI bag frames
	for i = 1, 5 do
		_G["ContainerFrame"..i]:HookScript("OnShow", UpdateState)
		_G["ContainerFrame"..i]:HookScript("OnHide", UpdateState)
	end

	-- Hook OnShow and OnHide from any addon bag frame
	if addonBagFrame then
		addonBagFrame:HookScript("OnShow", UpdateState)
		addonBagFrame:HookScript("OnHide", UpdateState)
	end
end


-- ####################################################################################################################
-- ##### Module Setup #################################################################################################
-- ####################################################################################################################

function module:SetMicromenuAnchors()
	local firstAnchor, previousAnchor
	
	-- Need to invert this depending on direction, or it will increase one and shrink the other
	local buttonSpacing = (db.Direction == "LEFT" and (db.Spacing - 2)) or -(db.Spacing - 2)

	-- Due to the visual appearance of the borders, a fully centered icon will look badly placed
	-- in the smaller buttons, so need a a little offset
	local iconXOffset = (db.Direction == "LEFT") and 1 or -1

	-- Iterate through all the created micromenu buttons
	for i = 1, #microStorage do

		-- Local reference to button, and clear its point
		local button = microStorage[i]
		button:ClearAllPoints()

		-- Update its state based on db options
		if db[("Hide")..button.name] then
			button:Hide()
		else
			button:Show()
		end

		-- Only continue if the button is shown
		if button:IsShown() then
			-- We are dealing with the first button
			if not firstAnchor then
				-- The first button should use the first texture width, wide size, and the first texture coords
				button:SetPoint(db.Point, UIParent, db.Point, db.X, db.Y)
				button:SetWidth(FIRST_TEXTURE_SIZE_WIDTH)
				button.clicker:SetWidth(WIDE_TEXTURE_CLICK_WIDTH)
				button.border:SetTexCoord(module:GetDirectionalTexCoord("MicroBtn_First"))
				button.icon:ClearAllPoints()
				button.icon:SetPoint("CENTER", 0, 0)
				firstAnchor = button
				previousAnchor = button
			-- We are dealing with a middle button
			else
				-- The middle button should use the normal texture width, size, and the default texture coords
				button:SetPoint(db.Direction, previousAnchor, LUI.Opposites[db.Direction], buttonSpacing, 0)
				button:SetWidth(TEXTURE_SIZE_WIDTH)
				button.clicker:SetWidth(TEXTURE_CLICK_WIDTH)
				button.border:SetTexCoord(module:GetDirectionalTexCoord("MicroBtn_Default"))
				button.icon:ClearAllPoints()
				button.icon:SetPoint("CENTER", iconXOffset, 0)
				previousAnchor = button
			end
		end
	end

	-- In order to update the last button, we need to iterate from the back of the list,
	-- check for the first shown button that we find and update accordingly
	-- Maybe this can also be dealt with another way
	for i = #microStorage, 1, -1 do
		local button = microStorage[i]
		if button:IsShown() then
			button:SetWidth(LAST_TEXTURE_SIZE_WIDTH)
			button.clicker:SetWidth(WIDE_TEXTURE_CLICK_WIDTH)
			button.border:SetTexCoord(module:GetDirectionalTexCoord("MicroBtn_Last"))
			button.icon:ClearAllPoints()
			button.icon:SetPoint("CENTER", 0, 0)
			break
		end
	end

	module.background:ClearAllPoints()
	-- In case all the buttons are hidden in the options
	if not firstAnchor then
		return
	end

	local point = "TOP"..db.Direction
	module.background:SetPoint(point, firstAnchor, point)
	module.background:SetPoint(LUI.Opposites[point], previousAnchor, LUI.Opposites[point])
	--LUI:Print("Background has been set.", module.background:GetDebugName())
end

function module:SetMicromenuExtraButtons()
	local ThemesDB = LUI:GetModule("Themes").db.profile
	local PanelsDB = LUI:GetModule("Panels").db.profile
	local minimapMod = LUI:GetModule("Minimap", true)
	local buttonLeft, buttonMiddle, buttonRight

	local buttonMiddle = CreateFrame("Frame", "LUIMicromenu_buttonMiddle", UIParent, "BackdropTemplate")
	buttonMiddle:SetSize(128, 128)
	buttonMiddle:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -150, 6)
	buttonMiddle:SetBackdrop({
		bgFile = "Interface\\AddOns\\LUI\\media\\templates\\v3\\"..(PanelsDB.MicroMenu.AlwaysShow and "micro_anchor3" or "micro_anchor"),
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0},
	})
	buttonMiddle:SetBackdropColor(module:RGB("Micromenu"))
	buttonMiddle:SetBackdropBorderColor(0, 0, 0, 0)

	local clickerMiddle = CreateFrame("Button", "LUIMicromenu_clickerMiddle", buttonMiddle, "BackdropTemplate")
	clickerMiddle:SetSize(85, 22)
	clickerMiddle:SetPoint("TOP", buttonMiddle, "TOP", 0, 0)
	clickerMiddle:RegisterForClicks("AnyUp")

	clickerMiddle:SetScript("OnClick", function(self)
		--[[if RaidMenu.db.profile.Enable then
			RaidMenu:OverlapPrevention("MM")
		end]]
		if PanelsDB.MicroMenu.IsShown then
			PanelsDB.MicroMenu.IsShown = false

			buttonMiddle:SetBackdrop({
				bgFile = "Interface\\AddOns\\LUI\\media\\templates\\v3\\"..(GetMouseFocus() == clickerMiddle and "micro_anchor2" or "micro_anchor"),
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = false, tileSize = 0, edgeSize = 1,
				insets = {left = 0, right = 0, top = 0, bottom = 0}
			})
			buttonMiddle:SetBackdropColor(module:RGB("Micromenu"))
			buttonMiddle:SetBackdropBorderColor(0, 0, 0, 0)
		else
			PanelsDB.MicroMenu.IsShown = true

			buttonMiddle:SetBackdrop({
				bgFile = "Interface\\AddOns\\LUI\\media\\templates\\v3\\"..(GetMouseFocus() == clickerMiddle and "micro_anchor4" or "micro_anchor3"),
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = false, tileSize = 0, edgeSize = 1,
				insets = {left = 0, right = 0, top = 0, bottom = 0}
			})
			buttonMiddle:SetBackdropColor(module:RGB("Micromenu"))
			buttonMiddle:SetBackdropBorderColor(0, 0, 0, 0)
		end
	end)

	clickerMiddle:SetScript("OnEnter", function(self)
		if PanelsDB.MicroMenu.IsShown then
			buttonMiddle:SetBackdrop({
				bgFile = "Interface\\AddOns\\LUI\\media\\templates\\v3\\micro_anchor4",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = false, tileSize = 0, edgeSize = 1,
				insets = {left = 0, right = 0, top = 0, bottom = 0}
			})
			buttonMiddle:SetBackdropColor(module:RGB("Micromenu"))
			buttonMiddle:SetBackdropBorderColor(0, 0, 0, 0)
		else
			buttonMiddle:SetBackdrop({
				bgFile = "Interface\\AddOns\\LUI\\media\\templates\\v3\\micro_anchor2",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = false, tileSize = 0, edgeSize = 1,
				insets = {left = 0, right = 0, top = 0, bottom = 0}
			})
			buttonMiddle:SetBackdropColor(module:RGB("Micromenu"))
			buttonMiddle:SetBackdropBorderColor(0, 0, 0, 0)
		end
	end)

	clickerMiddle:SetScript("OnLeave", function(self)
		if PanelsDB.MicroMenu.IsShown then
			buttonMiddle:SetBackdrop({
				bgFile = "Interface\\AddOns\\LUI\\media\\templates\\v3\\micro_anchor3",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = false, tileSize = 0, edgeSize = 1,
				insets = {left = 0, right = 0, top = 0, bottom = 0}
			})
			buttonMiddle:SetBackdropColor(module:RGB("Micromenu"))
			buttonMiddle:SetBackdropBorderColor(0, 0, 0, 0)
		else
			buttonMiddle:SetBackdrop({
				bgFile = "Interface\\AddOns\\LUI\\media\\templates\\v3\\micro_anchor",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = false, tileSize = 0, edgeSize = 1,
				insets = {left = 0, right = 0, top = 0, bottom = 0}
			})
			buttonMiddle:SetBackdropColor(module:RGB("Micromenu"))
			buttonMiddle:SetBackdropBorderColor(0, 0, 0, 0)
		end
	end)

	if minimapMod then
		buttonRight = CreateFrame("Frame", "LUIMicromenu_Right", buttonMiddle, "BackdropTemplate")
		buttonRight:SetSize(128, 128)
		buttonRight:SetPoint("RIGHT", buttonMiddle, "RIGHT", 47, -3)
		buttonRight:SetBackdrop({
			bgFile = "Interface\\AddOns\\LUI\\media\\templates\\v3\\mm_button_right",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = false, tileSize = 0, edgeSize = 1,
			insets = {left = 0, right = 0, top = 0, bottom = 0}
		})
		buttonRight:SetBackdropColor(module:RGB("Micromenu"))
		buttonRight:SetBackdropBorderColor(0, 0, 0, 0)

		local clickerRight = CreateFrame("Button", "LUIMicromenu_clickerRight", buttonRight, "BackdropTemplate")
		clickerRight:SetSize(40, 12)
		clickerRight:SetPoint("TOP", buttonRight, "TOP", 22, -5)
		clickerRight:RegisterForClicks("AnyUp")

		clickerRight:SetScript("OnClick", function(self, button)
			if minimapMod:IsEnabled() then
				if button == "RightButton" then
					ToggleFrame(WorldMapFrame)
				else
					if Minimap:GetAlpha() == 0 then
						--MinimapAlphaIn:Show()
						PanelsDB.Minimap.IsShown = true
					else
						--MinimapAlphaOut:Show()
						PanelsDB.Minimap.IsShown = false
					end
				end
			else
				ToggleFrame(WorldMapFrame)
			end
		end)

		clickerRight:SetScript("OnEnter", function(self)
			buttonRight:SetBackdrop({
				bgFile = "Interface\\AddOns\\LUI\\media\\templates\\v3\\mm_button_right_hover",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = false, tileSize = 0, edgeSize = 1,
				insets = {left = 0, right = 0, top = 0, bottom = 0}
			})
			buttonRight:SetBackdropColor(module:RGB("Micromenu"))
			buttonRight:SetBackdropBorderColor(0, 0, 0, 0)
		end)

		clickerRight:SetScript("OnLeave", function(self)
			buttonRight:SetBackdrop({
				bgFile = "Interface\\AddOns\\LUI\\media\\templates\\v3\\mm_button_right",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = false, tileSize = 0, edgeSize = 1,
				insets = {left = 0, right = 0, top = 0, bottom = 0}
			})
			buttonRight:SetBackdropColor(module:RGB("Micromenu"))
			buttonRight:SetBackdropBorderColor(0, 0, 0, 0)
		end)
	end

	local raidmenu_mod = LUI:GetModule("RaidMenu", true)
	if raidmenu_mod then
		local buttonLeft = CreateFrame("Frame", "LUIMicromenu_buttonLeft", buttonMiddle, "BackdropTemplate")
		buttonLeft:SetSize(128, 128)
		buttonLeft:SetPoint("LEFT", buttonMiddle, "LEFT", -47, -3)
		buttonLeft:SetBackdrop({
			bgFile = "Interface\\AddOns\\LUI\\media\\templates\\v3\\mm_button_left",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = false, tileSize = 0, edgeSize = 1,
			insets = {left = 0, right = 0, top = 0, bottom = 0}
		})
		buttonLeft:SetBackdropColor(module:RGB("Micromenu"))
		buttonLeft:SetBackdropBorderColor(0, 0, 0, 0)

		local leftClicker = CreateFrame("Button", "LUIMicromenu_leftClicker", buttonLeft, "BackdropTemplate")
		leftClicker:SetSize(40, 12)
		leftClicker:SetPoint("TOP", buttonLeft, "TOP", -22, -5)
		leftClicker:RegisterForClicks("AnyUp")

		leftClicker:SetScript("OnClick", function(self, button)
			raidmenu_mod:OverlapPrevention("RM", "toggle")
		end)

		leftClicker:SetScript("OnEnter", function(self)
			buttonLeft:SetBackdrop({
				bgFile = "Interface\\AddOns\\LUI\\media\\templates\\v3\\mm_button_left_hover",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = false, tileSize = 0, edgeSize = 1,
				insets = {left = 0, right = 0, top = 0, bottom = 0}
			})
			buttonLeft:SetBackdropColor(module:RGB("Micromenu"))
			buttonLeft:SetBackdropBorderColor(0, 0, 0, 0)
		end)

		leftClicker:SetScript("OnLeave", function(self)
			buttonLeft:SetBackdrop({
				bgFile = "Interface\\AddOns\\LUI\\media\\templates\\v3\\mm_button_left",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = false, tileSize = 0, edgeSize = 1,
				insets = {left = 0, right = 0, top = 0, bottom = 0}
			})
			buttonLeft:SetBackdropColor(module:RGB("Micromenu"))
			buttonLeft:SetBackdropBorderColor(0, 0, 0, 0)
		end)
	end

	module.buttonMiddle = buttonMiddle
	module.buttonLeft = buttonLeft
	module.buttonRight = buttonRight
	module.clickerLeft = clickerLeft
	module.clickerRight = clickerRight
end

function module:SetMicromenu()

	-- Create Micromenu background
	local background = CreateFrame("Frame", "LUIMicromenu_Background", UIParent, "BackdropTemplate")
	background:SetBackdrop({
		bgFile = BACKGROUND_TEXTURE_PATH,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false, tilseSize = 0, edgeSize = 1,
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	})
	background:SetFrameStrata("BACKGROUND")
	background:SetBackdropColor(module:RGBA((db.ColorMatch) and "Micromenu" or "Background"))
	background:SetBackdropBorderColor(0, 0, 0, 0)
	module.background = background

	-- Create Micromenu buttons
	for i = 1, #microDefinitions do
		table.insert(microStorage, module:NewMicroButton(microDefinitions[i]))
	end

	module:SetMicromenuAnchors()
	module:SetMicromenuExtraButtons()
end

--- Fires the stored functions for the frame hooks
-- Doing it this way instead of loading the required addons in OnEnable
function module:OnEvent(_, addon)
	if addonLoadedCallbacks[addon] then
		addonLoadedCallbacks[addon]()
		addonLoadedCallbacks[addon] = nil
	end
end

-- ####################################################################################################################
-- ##### Module Refresh ###############################################################################################
-- ####################################################################################################################

function module:Refresh()
	module:SetMicromenuAnchors()
	-- module:SetAlertFrameColors("EJ")
	-- module:SetAlertFrameColors("Talent")
	-- module:SetAlertFrameColors("Collections")

	module.background:SetBackdropColor(module:RGBA((db.ColorMatch) and "Micromenu" or "Background"))
	local r, g, b, a_ = module:RGBA("Micromenu")
	for i = 1, #microList do
		local button = microStorage[microList[i]]
		if button then
			button.tex:SetVertexColor(r, g, b)
		end
	end
end

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function module:OnInitialize()
	LUI:RegisterModule(module)
	db = module.db.profile
end

function module:OnEnable()
	-- We use the OnEvent function to fire functions required for the clicker state handlers
	module:RegisterEvent("ADDON_LOADED", "OnEvent")

	-- We consolidate some frames into one for easy hooking and less spaghetti
	module:ConsolidateOptionsFrames()
	module:ConsolidateSocialFrames()
	module:ConsolidateBagFrames()

	module:SetMicromenu()
end

function module:OnDisable()
end