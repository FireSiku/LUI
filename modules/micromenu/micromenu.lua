-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)
local L = LUI.L

---@class LUI.Micromenu : LUIModule
local module = LUI:NewModule("Micromenu", "AceHook-3.0")
local db

local PlayerSpellsUtil = _G.PlayerSpellsUtil
local hooksecurefunc = _G.hooksecurefunc
local GameMenuFrame = _G.GameMenuFrame
local FriendsFrame = _G.FriendsFrame
local HideUIPanel = _G.HideUIPanel
local ShowUIPanel = _G.ShowUIPanel
local UnitLevel = _G.UnitLevel
local issecretvalue = _G.issecretvalue
local IsBagOpen = _G.IsBagOpen
local Minimap = _G.Minimap
local format = format
local InCombatLockdown = _G.InCombatLockdown

local function OpenWorldMapSafe()
	if InCombatLockdown() then return end
	if C_Map and C_Map.OpenWorldMap then
		C_Map.OpenWorldMap()
	end
end

local TALENT_TAB = PlayerSpellsUtil.FrameTabs.ClassTalents or 2
local SPELL_TAB = PlayerSpellsUtil.FrameTabs.SpellBook or 3

local addonLoadedCallbacks = {}
local microStorage = {}
local pendingAction
local nativeMicroFrameState = setmetatable({}, {__mode = "k"})

local combatQueue = CreateFrame("Frame")
combatQueue:Hide()
combatQueue:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:Hide()

	local action = pendingAction
	pendingAction = nil
	if action == "disable" or not module:IsEnabled() then
		module:ApplyDisabledState()
	else
		module:ApplyEnabledState()
	end
end)

local function QueueAfterCombat(action)
	-- Enable/disable represents the final desired state; refresh never overrides it.
	if action ~= "refresh" or not pendingAction then
		pendingAction = action
	end
	combatQueue:RegisterEvent("PLAYER_REGEN_ENABLED")
	combatQueue:Show()
end

local function EnforceNativeMicroBarHidden()
	if InCombatLockdown() then
		QueueAfterCombat("refresh")
		return
	end
	for frame, state in pairs(nativeMicroFrameState) do
		if state.owned then
			frame:SetAlpha(0)
			frame:EnableMouse(false)
			frame:Hide()
		end
	end
end

local function HideNativeMicroFrame(frame)
	if not frame then return end
	local state = nativeMicroFrameState[frame]
	if not state then
		state = {
			hooked = false,
		}
		nativeMicroFrameState[frame] = state
	end
	if not state.owned then
		state.owned = not frame.__luiKilled
		state.wasShown = frame:IsShown()
		state.alpha = frame:GetAlpha()
		state.mouseEnabled = frame:IsMouseEnabled()
	end
	if state.owned and not frame.__luiKilled then LUI:Kill(frame) end
	if state.owned and not state.hooked then
		state.hooked = true
		hooksecurefunc(frame, "SetShown", function(_, shown)
			if state.owned and shown then EnforceNativeMicroBarHidden() end
		end)
	end
end

local function HideNativeMicroBar()
	-- MicroButtonAndBagsBar is only the legacy anchor in current Retail.
	-- MicroMenu is the frame that actually owns the visible Blizzard buttons.
	HideNativeMicroFrame(_G.MicroButtonAndBagsBar)
	HideNativeMicroFrame(_G.MicroMenu)
	EnforceNativeMicroBarHidden()
end

local function RestoreNativeMicroBar()
	for frame, state in pairs(nativeMicroFrameState) do
		if state.owned then
			state.owned = false
			LUI:Unkill(frame, false)
			frame:SetAlpha(state.alpha)
			frame:EnableMouse(state.mouseEnabled)
			if state.wasShown then frame:Show() end
		end
	end
end

-- Constants

local TEXTURE_PATH_FORMAT = "Interface\\AddOns\\LUI\\modules\\micromenu\\micro_%s.tga"
local BACKGROUND_TEXTURE_PATH = "Interface\\AddOns\\LUI\\modules\\micromenu\\micro_background.tga"
local EXTRA_TEXTURE_PATH = "Interface\\AddOns\\LUI\\media\\templates\\v3\\"
local FIRST_TEXTURE_SIZE_WIDTH = 46
local LAST_TEXTURE_SIZE_WIDTH = 48
local TEXTURE_SIZE_HEIGHT = 28
local TEXTURE_SIZE_WIDTH = 33
-- The clickable area is only 27x24.
-- Wide buttons clickable area: 42x24.

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
		AlwaysShow = true,
		IsShown = true,
		HideBags = false,
		HideStore = false,
		HideCollections = false,
		HideEJ = false,
		HideLFG = false,
		HideGuild = false,
		HideHousing = false,
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
			Background = { r = 0.12, g = 0.12, b = 0.12, a = 1, t = "Class", },
			Micromenu = { r = 0.12, g = 0.58, b = 0.89, a = 1, t = "Class", },
		},
	},
}

-- ####################################################################################################################
-- ##### MicroButton Definitions ######################################################################################
-- ####################################################################################################################

local microDefinitions = {

	{
		name = "Settings",
		title = L["Options"],
		left = L["MicroSettings_Right"],
		right = L["MicroSettings_Left"],
		state = "ConsolidatedOptionsFrame",
		OnClick = function(self, btn)
			if btn == "RightButton" then
				-- WoW Option Panel
				module:TogglePanel(GameMenuFrame)
			else
				-- LUI Option Panel
				LUI:OpenOptions()
			end
		end,
	},

	{
		name = "Bags",
		title = L["Bags_Name"],
		any = L["MicroBags_Any"],
		state = "ConsolidatedBagFrame",
		OnClick = function(self, btn)
			_G.ToggleAllBags()
		end,
	},

	{
		name = "Store",
		title = L["MicroStore_Name"],
		any = L["MicroStore_Any"],
	},

	{
		name = "Collections",
		title = L["MicroCollect_Name"],
		any = L["MicroCollect_Any"],
		state = "CollectionsJournal",
		addon = "Blizzard_CollectionsJournal",
		OnClick = function(self, btn)
			_G.ToggleCollectionsJournal()
		end,
	},

	{
		name = "EJ",
		title = L["MicroEJ_Name"],
		any = L["MicroEJ_Any"],
		state = "EncounterJournal",
		addon = "Blizzard_EncounterJournal",
		OnClick = function(self, btn)
			_G.ToggleEncounterJournal()
		end,
	},

	{
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

	{
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

	{
		name = "Housing",
		title = _G.HOUSING_MICRO_BUTTON or "Housing",
		any = _G.HOUSING_DASHBOARD_MICRO_BUTTON_TUTORIAL_TEXT or "Show/Hide the Housing Dashboard",
		state = "HousingDashboardFrame",
		addon = "Blizzard_HousingDashboard",
		secureClickTarget = "HousingMicroButton",
	},

	{
		name = "Quests",
		title = L["MicroQuest_Name"],
		any = L["MicroQuest_Any"],
		OnClick = function(self, btn)
			_G.ToggleQuestLog()
		end,
	},

	{
		name = "Achievements",
		title = L["MicroAch_Name"],
		any = L["MicroAch_Any"],
		state = "AchievementFrame",
		addon = "Blizzard_AchievementUI",
		OnClick = function(self, btn)
			_G.ToggleAchievementFrame()
		end,
	},

	{
		name = "Talents",
		level = TALENT_LEVEL_REQ,
		title = L["MicroTalents_Name"],
		left = L["MicroTalents_Left"],
		right = L["MicroTalents_Right"],
		state = "PlayerSpellsFrame",
		addon = "Blizzard_PlayerSpells",
		OnClick = function(self, btn)
			if btn == "RightButton" then
				PlayerSpellsUtil.TogglePlayerSpellsFrame(SPELL_TAB)
			else
				PlayerSpellsUtil.TogglePlayerSpellsFrame(TALENT_TAB)
			end
		end,
	},

	{
		name = "Spellbook",
		title = L["MicroProfession_Name"],
		any = L["MicroProfession_Any"],
		state = "ProfessionsBookFrame",
		addon = "Blizzard_ProfessionsBook",
		OnClick = function(self, btn)
			_G.ToggleProfessionsBook()
		end,
	},

	{
		name = "Player",
		isWide = "Left",
		title = L["MicroPlayer_Name"],
		any = L["MicroPlayer_Any"],
		state = "CharacterFrame",
		OnClick = function(self, btn)
			_G.ToggleCharacter("PaperDollFrame")
		end,
	},
}

-- ####################################################################################################################
-- ##### MicroButton Mixin ############################################################################################
-- ####################################################################################################################

---@class MicroButton : Button
local MicroButtonClickerMixin = {}

function MicroButtonClickerMixin:OnEnter()
	self:SetAlpha(1)
	self.Hover = true
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")

	local parent = self:GetParent()
	GameTooltip_SetTitle(GameTooltip, parent.title)

	if parent.any then
		GameTooltip:AddLine(parent.any, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
	end
	if parent.left then
		GameTooltip:AddLine(parent.left, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b, true)
	end
	if parent.right then
		GameTooltip:AddLine(parent.right, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b, true)
	end
	local playerLevel = UnitLevel("player")
	if parent.level and not issecretvalue(playerLevel) and playerLevel < parent.level then
		GameTooltip:AddLine(format(L["Micro_PlayerReq"], parent.level), LUI:NegativeColor())
	end
	GameTooltip:Show()
end

function MicroButtonClickerMixin:OnLeave()
	self:SetAlpha(self:GetParent().Opened and 1 or 0)
	self.Hover = nil
	GameTooltip:Hide()
end

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

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

--- Updates the micromenu clicker alpha based on frames being shown and hidden.
---@param button MicroButton
---@param objectName string
function module:ClickerStateUpdateHandler(button, objectName)
	local objectToHook = _G[objectName]

	if not objectToHook then
		return
	end

	local function UpdateState()
		button.Opened = objectToHook:IsShown() and true or false
		button.clicker:SetAlpha((button.Opened or button.clicker.Hover) and 1 or 0)
	end

	hooksecurefunc(objectToHook, "Show", UpdateState)
	hooksecurefunc(objectToHook, "Hide", UpdateState)
	UpdateState()
end

--- Create a new MicroButton.
---@param buttonData table
---@return MicroButton
function module:NewMicroButton(buttonData)
	local r, g, b = module:RGB("Micromenu")
	local name = buttonData.name

	local button = CreateFrame("Frame", "LUIMicromenu_" .. name, _G.LUIMicromenu_Background)
	button:SetSize(TEXTURE_SIZE_WIDTH, TEXTURE_SIZE_HEIGHT)
	button = Mixin(button, buttonData) --[[@as MicroButton]]

	-- Make an icon for the button.
	button.icon = button:CreateTexture(nil, "ARTWORK")
	button.icon:SetPoint("CENTER", 0, 0)
	button.icon:SetTexture(format(TEXTURE_PATH_FORMAT, strlower(name)))
	button.icon:SetTexCoord(LUI:GetCoordAtlas("MicroBtn_Icon"))
	button.icon:SetVertexColor(r, g, b)

	-- Make a border for the button.
	button.border = button:CreateTexture(nil, "ARTWORK")
	button.border:SetAllPoints()
	button.border:SetTexture(format(TEXTURE_PATH_FORMAT, "border"))
	button.border:SetTexCoord(LUI:GetCoordAtlas("MicroBtn_Default"))
	button.border:SetVertexColor(r, g, b)

	-- Create the clickable area.
	-- Protected Blizzard microbuttons keep the original hardware click path.
	local secureClickTarget = button.secureClickTarget
	if name == "Store" then
		secureClickTarget = "StoreMicroButton"
	end

	if secureClickTarget then
		button.clicker = CreateFrame(
			"Button",
			nil,
			button,
			"SecureActionButtonTemplate"
		)

		button.clicker:SetAttribute("type1", "macro")
		button.clicker:SetAttribute("macrotext1", "/click " .. secureClickTarget)
		button.clicker:SetAttribute("useOnKeyDown", false)
	else
		button.clicker = CreateFrame("Button", nil, button)
	end

	button.clicker:SetSize(TEXTURE_CLICK_WIDTH, TEXTURE_CLICK_HEIGHT)
	if secureClickTarget then
		button.clicker:RegisterForClicks("AnyUp", "AnyDown")
	else
		button.clicker:RegisterForClicks("AnyUp")
	end
	button.clicker:SetPoint("CENTER", button, "CENTER", -1, 0)
	button.clicker.Fill = LUI:CreateFrameTexture(button.clicker, LUI.Media.blank)
	button.clicker.Fill:SetColorTexture(0, 0, 0, 1)
	button.clicker:SetAlpha(0)

	-- Push down the clicker frame so it does not go above the texture.
	button.clicker:SetFrameLevel(button:GetFrameLevel() - 1)

	if button.OnClick and not secureClickTarget then
		button.clicker:SetScript("OnClick", button.OnClick)
	end

	if button.state then
		if button.addon and not C_AddOns.IsAddOnLoaded(button.addon) then
			addonLoadedCallbacks[button.addon] = function()
				module:ClickerStateUpdateHandler(button, button.state)
			end
		else
			module:ClickerStateUpdateHandler(button, button.state)
		end
	end

	button.clicker:SetScript("OnEnter", MicroButtonClickerMixin.OnEnter)
	button.clicker:SetScript("OnLeave", MicroButtonClickerMixin.OnLeave)

	return button
end

-- ####################################################################################################################
-- ##### Consolidated Frames ##########################################################################################
-- ####################################################################################################################

function module:ConsolidateOptionsFrames()
	local optionsFrames = CreateFrame("Frame", "ConsolidatedOptionsFrame", UIParent)
	local ACD = LibStub("AceConfigDialog-3.0")
	local hookedOptionsFrames = setmetatable({}, {__mode = "k"})

	local function UpdateState()
		local widget = ACD.OpenFrames["LUIOptions"]
		local optionsFrame = widget and widget.frame

		if GameMenuFrame:IsShown() or (optionsFrame and optionsFrame:IsShown()) then
			optionsFrames:Show()
		else
			optionsFrames:Hide()
		end
	end

	local function HookOptionsFrame()
		local widget = ACD.OpenFrames["LUIOptions"]
		local frame = widget and widget.frame

		if frame and not hookedOptionsFrames[frame] then
			hookedOptionsFrames[frame] = true
			frame:HookScript("OnHide", UpdateState)
		end

		UpdateState()
	end

	hooksecurefunc(GameMenuFrame, "Show", UpdateState)
	hooksecurefunc(GameMenuFrame, "Hide", UpdateState)
	hooksecurefunc(ACD, "Open", HookOptionsFrame)
	HookOptionsFrame()
	UpdateState()
end

function module:ConsolidateSocialFrames()
	local socialFrames = CreateFrame("Frame", "ConsolidatedSocialFrame", UIParent)

	local function UpdateState()
		if FriendsFrame:IsShown() or (_G.CommunitiesFrame and _G.CommunitiesFrame:IsShown()) then
			socialFrames:Show()
		else
			socialFrames:Hide()
		end
	end

	FriendsFrame:HookScript("OnShow", UpdateState)
	FriendsFrame:HookScript("OnHide", UpdateState)

	local function HookCommunitiesFrame()
		_G.CommunitiesFrame:HookScript("OnShow", UpdateState)
		_G.CommunitiesFrame:HookScript("OnHide", UpdateState)
		UpdateState()
	end
	if _G.CommunitiesFrame then
		HookCommunitiesFrame()
	else
		addonLoadedCallbacks["Blizzard_Communities"] = HookCommunitiesFrame
	end
	UpdateState()
end

function module:ConsolidateBagFrames()
	local bagFrames = CreateFrame("Frame", "ConsolidatedBagFrame", UIParent)

	local function UpdateState()
		if
			(_G.LUIBags and _G.LUIBags:IsShown())
			or IsBagOpen(0)
			or IsBagOpen(1)
			or IsBagOpen(2)
			or IsBagOpen(3)
			or IsBagOpen(4)
			or IsBagOpen(5)
		then
			bagFrames:Show()
		else
			bagFrames:Hide()
		end
	end

	for i = 1, 13 do
		local frame = _G["ContainerFrame" .. i]
		if frame then
			frame:HookScript("OnShow", UpdateState)
			frame:HookScript("OnHide", UpdateState)
		end
	end

	if _G.ContainerFrameCombinedBags then
		_G.ContainerFrameCombinedBags:HookScript("OnShow", UpdateState)
		_G.ContainerFrameCombinedBags:HookScript("OnHide", UpdateState)
	end
	if _G.LUIBags then
		_G.LUIBags:HookScript("OnShow", UpdateState)
		_G.LUIBags:HookScript("OnHide", UpdateState)
	end
	UpdateState()
end

-- ####################################################################################################################
-- ##### Module Setup #################################################################################################
-- ####################################################################################################################

function module:SetMicromenuAnchors()
	local firstAnchor, previousAnchor

	local buttonSpacing = (db.Direction == "LEFT" and (db.Spacing - 2)) or -(db.Spacing - 2)
	local iconXOffset = (db.Direction == "LEFT") and 1 or -1

	for i = 1, #microStorage do
		local button = microStorage[i]
		button:ClearAllPoints()

		if db[("Hide") .. button.name] then
			button:Hide()
		else
			button:Show()
		end

		if button:IsShown() then
			if not firstAnchor then
				button:SetPoint(db.Point, UIParent, db.Point, db.X, db.Y)
				button:SetWidth(FIRST_TEXTURE_SIZE_WIDTH)
				button.clicker:SetWidth(WIDE_TEXTURE_CLICK_WIDTH)
				button.border:SetTexCoord(module:GetDirectionalTexCoord("MicroBtn_First"))
				button.icon:ClearAllPoints()
				button.icon:SetPoint("CENTER", 0, 0)
				firstAnchor = button
				previousAnchor = button
			else
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

	if not firstAnchor then
		module.background:Hide()
		return
	end

	local point = "TOP" .. db.Direction
	module.background:SetPoint(point, firstAnchor, point)
	module.background:SetPoint(LUI.Opposites[point], previousAnchor, LUI.Opposites[point])
	module.background:SetShown(db.IsShown)
end

function module:SetMicromenuExtraButtons()
	local minimapMod = LUI:GetModule("Minimap", true)
	local buttonLeft, buttonMiddle, buttonRight
	local clickerLeft, clickerMiddle, clickerRight

	buttonMiddle = CreateFrame("Frame", "LUIMicromenu_buttonMiddle", UIParent)
	buttonMiddle:SetSize(128, 128)
	buttonMiddle:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -150, 6)
	buttonMiddle.Texture = LUI:CreateFrameTexture(buttonMiddle, EXTRA_TEXTURE_PATH .. (db.IsShown and "micro_anchor3" or "micro_anchor"))
	buttonMiddle.Texture:SetVertexColor(module:RGB("Micromenu"))

	clickerMiddle = CreateFrame("Button", "LUIMicromenu_clickerMiddle", buttonMiddle)
	clickerMiddle:SetSize(85, 22)
	clickerMiddle:SetPoint("TOP", buttonMiddle, "TOP", 0, 0)
	clickerMiddle:RegisterForClicks("AnyUp")

	clickerMiddle:SetScript("OnClick", function(self)
		if _G.LUIMicromenu_Background:IsVisible() then
			db.IsShown = false

			buttonMiddle.Texture:SetTexture(EXTRA_TEXTURE_PATH .. (clickerMiddle:IsMouseMotionFocus() and "micro_anchor2" or "micro_anchor"))
			_G.LUIMicromenu_Background:Hide()
		else
			db.IsShown = true

			buttonMiddle.Texture:SetTexture(EXTRA_TEXTURE_PATH .. (clickerMiddle:IsMouseMotionFocus() and "micro_anchor4" or "micro_anchor3"))
			_G.LUIMicromenu_Background:Show()
		end
	end)

	clickerMiddle:SetScript("OnEnter", function(self)
		if db.IsShown then
			buttonMiddle.Texture:SetTexture(EXTRA_TEXTURE_PATH .. "micro_anchor4")
		else
			buttonMiddle.Texture:SetTexture(EXTRA_TEXTURE_PATH .. "micro_anchor2")
		end
	end)

	clickerMiddle:SetScript("OnLeave", function(self)
		if db.IsShown then
			buttonMiddle.Texture:SetTexture(EXTRA_TEXTURE_PATH .. "micro_anchor3")
		else
			buttonMiddle.Texture:SetTexture(EXTRA_TEXTURE_PATH .. "micro_anchor")
		end
	end)

	if minimapMod then
		buttonRight = CreateFrame("Frame", "LUIMicromenu_Right", buttonMiddle)
		buttonRight:SetSize(128, 128)
		buttonRight:SetPoint("RIGHT", buttonMiddle, "RIGHT", 47, -3)
		buttonRight.Texture = LUI:CreateFrameTexture(buttonRight, EXTRA_TEXTURE_PATH .. "mm_button_right")
		buttonRight.Texture:SetVertexColor(module:RGB("Micromenu"))

		clickerRight = CreateFrame("Button", "LUIMicromenu_clickerRight", buttonRight)
		clickerRight:SetSize(40, 12)
		clickerRight:SetPoint("TOP", buttonRight, "TOP", 22, -5)
		clickerRight:RegisterForClicks("AnyUp")

		clickerRight:SetScript("OnClick", function(self, button)
			if minimapMod:IsEnabled() then
				if button == "RightButton" then
					OpenWorldMapSafe()
				else
					if Minimap:IsVisible() then
						Minimap:Hide()
					else
						Minimap:Show()
					end
				end
			else
				OpenWorldMapSafe()
			end
		end)

		clickerRight:SetScript("OnEnter", function(self)
			buttonRight.Texture:SetTexture(EXTRA_TEXTURE_PATH .. "mm_button_right_hover")
		end)

		clickerRight:SetScript("OnLeave", function(self)
			buttonRight.Texture:SetTexture(EXTRA_TEXTURE_PATH .. "mm_button_right")
		end)
	end

	local raidmenu_mod = LUI:GetModule("RaidMenu", true)

	if raidmenu_mod then
		buttonLeft = CreateFrame("Frame", "LUIMicromenu_buttonLeft", buttonMiddle)
		buttonLeft:SetSize(128, 128)
		buttonLeft:SetPoint("LEFT", buttonMiddle, "LEFT", -47, -3)
		buttonLeft.Texture = LUI:CreateFrameTexture(buttonLeft, EXTRA_TEXTURE_PATH .. "mm_button_left")
		buttonLeft.Texture:SetVertexColor(module:RGB("Micromenu"))

		clickerLeft = CreateFrame("Button", "LUIMicromenu_clickerLeft", buttonLeft)
		clickerLeft:SetSize(40, 12)
		clickerLeft:SetPoint("TOP", buttonLeft, "TOP", -22, -5)
		clickerLeft:RegisterForClicks("AnyUp")

		clickerLeft:SetScript("OnClick", function(self, button)
			raidmenu_mod:OverlapPrevention("RM", "toggle")
		end)

		clickerLeft:SetScript("OnEnter", function(self)
			buttonLeft.Texture:SetTexture(EXTRA_TEXTURE_PATH .. "mm_button_left_hover")
		end)

		clickerLeft:SetScript("OnLeave", function(self)
			buttonLeft.Texture:SetTexture(EXTRA_TEXTURE_PATH .. "mm_button_left")
		end)
	end

	module.buttonMiddle = buttonMiddle
	module.buttonLeft = buttonLeft
	module.buttonRight = buttonRight
	module.clickerLeft = clickerLeft
	module.clickerRight = clickerRight
	module.clickerMiddle = clickerMiddle
end

function module:SetMicromenu()
	-- Create Micromenu background.
	local background = CreateFrame("Frame", "LUIMicromenu_Background", UIParent)
	background:SetFrameStrata("BACKGROUND")
	background.Texture = LUI:CreateFrameTexture(background, BACKGROUND_TEXTURE_PATH)
	background.Texture:SetVertexColor(module:RGBA((db.ColorMatch) and "Micromenu" or "Background"))
	module.background = background

	-- Create Micromenu buttons.
	for i = 1, #microDefinitions do
		table.insert(microStorage, module:NewMicroButton(microDefinitions[i]))
	end

	module:SetMicromenuAnchors()
	module:SetMicromenuExtraButtons()
	background:SetShown(db.IsShown)
end

--- Fires the stored functions for the frame hooks.
function module:OnEvent(event, addon)
	if event == "PLAYER_ENTERING_WORLD" or event == "EDIT_MODE_LAYOUTS_UPDATED" then
		HideNativeMicroBar()
		return
	end
	if addonLoadedCallbacks[addon] then
		addonLoadedCallbacks[addon]()
		addonLoadedCallbacks[addon] = nil
	end
end

local function RunLoadedAddonCallbacks()
	for addon, callback in pairs(addonLoadedCallbacks) do
		if C_AddOns.IsAddOnLoaded(addon) then
			callback()
			addonLoadedCallbacks[addon] = nil
		end
	end
end

-- ####################################################################################################################
-- ##### Module Refresh ###############################################################################################
-- ####################################################################################################################

function module:RefreshColors()
	if not module.background then return end

	module.background.Texture:SetVertexColor(module:RGBA((db.ColorMatch) and "Micromenu" or "Background"))

	local r, g, b = module:RGB("Micromenu")

	for i = 1, #microStorage do
		local button = microStorage[i]
		button.icon:SetVertexColor(r, g, b)
		button.border:SetVertexColor(r, g, b)
	end

	module.buttonMiddle.Texture:SetVertexColor(r, g, b)
	if module.buttonLeft then module.buttonLeft.Texture:SetVertexColor(r, g, b) end
	if module.buttonRight then module.buttonRight.Texture:SetVertexColor(r, g, b) end
end

function module:Refresh()
	if InCombatLockdown() then
		QueueAfterCombat("refresh")
		return
	end
	if not module.background then return end

	module:SetMicromenuAnchors()
	module:RefreshColors()
end

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function module:OnInitialize()
	local oldDB = rawget(LUI.db.profile, "MicroMenu")
	LUI:RegisterModule(module)
	db = module.db.profile
	if oldDB then
		if rawget(oldDB, "AlwaysShow") ~= nil then db.AlwaysShow = oldDB.AlwaysShow end
		if rawget(oldDB, "IsShown") ~= nil then db.IsShown = oldDB.IsShown end
		LUI.db.profile.MicroMenu = nil
	end
	if db.AlwaysShow then db.IsShown = true end
end

function module:ApplyEnabledState()
	HideNativeMicroBar()
	module:RegisterEvent("ADDON_LOADED", "OnEvent")
	module:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	module:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED", "OnEvent")

	if not module.background then
		module:ConsolidateOptionsFrames()
		module:ConsolidateSocialFrames()
		module:ConsolidateBagFrames()
		module:SetMicromenu()
	else
		module.buttonMiddle:Show()
		if module.buttonLeft then module.buttonLeft:Show() end
		if module.buttonRight then module.buttonRight:Show() end
		module:Refresh()
	end
	RunLoadedAddonCallbacks()
	module:SetAlerts()

	local raidMenu = LUI:GetModule("RaidMenu", true)
	if raidMenu and raidMenu:IsEnabled() then
		raidMenu:SetRaidMenu()
	end
end

function module:ApplyDisabledState()
	RestoreNativeMicroBar()
	module:RestoreAlerts()
	module:UnhookAll()
	if not module.background then return end
	local raidMenu = LUI:GetModule("RaidMenu", true)
	if raidMenu and raidMenu.HideRaidMenu then raidMenu:HideRaidMenu() end
	module.background:Hide()
	module.buttonMiddle:Hide()
	if module.buttonLeft then module.buttonLeft:Hide() end
	if module.buttonRight then module.buttonRight:Hide() end
	for i = 1, #microStorage do
		microStorage[i]:Hide()
	end
end

function module:OnEnable()
	if InCombatLockdown() then
		QueueAfterCombat("enable")
		return
	end
	module:ApplyEnabledState()
end

function module:OnDisable()
	module:UnregisterAllEvents()
	if InCombatLockdown() then
		QueueAfterCombat("disable")
		return
	end
	module:ApplyDisabledState()
end
