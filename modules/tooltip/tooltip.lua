-- This module handle tooltips shown around the interface and skinning GameTooltip.

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)
local L = LUI.L

---@class LUI.Tooltip : LUIModule, AceHook-3.0
local module = LUI:NewModule("Tooltip", "AceHook-3.0")
local Media = LibStub("LibSharedMedia-3.0")
local db

local QuestMapLog_GetCampaignTooltip = _G.QuestMapLog_GetCampaignTooltip
local TooltipDataProcessor = _G.TooltipDataProcessor
local GameTooltipStatusBar = _G.GameTooltipStatusBar
local BreakUpLargeNumbers = _G.BreakUpLargeNumbers
local GetItemQualityColor = C_Item.GetItemQualityColor
local UnitTokenFromGUID = _G.UnitTokenFromGUID
local InCombatLockdown = _G.InCombatLockdown
local UnitHasVehicleUI = _G.UnitHasVehicleUI
local IsShiftKeyDown = _G.IsShiftKeyDown
local UnitHealthMax = _G.UnitHealthMax
local UnitIsPlayer = _G.UnitIsPlayer
local UnitIsInMyGuild = _G.UnitIsInMyGuild
local UnitReaction = _G.UnitReaction
local GetItemInfo = C_Item.GetItemInfo
local UnitIsGhost = _G.UnitIsGhost
local UnitPVPName = _G.UnitPVPName
local UnitExists = _G.UnitExists
local UnitHealth = _G.UnitHealth
local UnitIsDead = _G.UnitIsDead
local UnitClass = _G.UnitClass
local UnitIsAFK = _G.UnitIsAFK
local UnitIsDND = _G.UnitIsDND
local UnitName = _G.UnitName

-- Constants
local CHAT_FLAG_DND = _G.CHAT_FLAG_DND
local CHAT_FLAG_AFK = _G.CHAT_FLAG_AFK
local LEVEL = _G.LEVEL

local TOOLTIPS_LIST = {
	"GameTooltip",
	"ItemRefTooltip",
	"ItemRefShoppingTooltip1",
	"ItemRefShoppingTooltip2",
	"ShoppingTooltip1",
	"ShoppingTooltip2",
	"FriendsTooltip",
	"TicketStatusFrameButton",
	"DropDownList1MenuBackdrop",
	"DropDownList2MenuBackdrop",
	"BrowserSettingsTooltip",
	"FrameStackTooltip",
	"EventTraceTooltip",
	"WorldMapTooltip",
	"WorldMapCompareTooltip1",
	"WorldMapCompareTooltip2",
	"ReputationParagonTooltip",
	"ScenarioStepRewardTooltip",
	"EncounterJournalTooltip",
	"PVPRewardTooltip",
	"ConquestTooltip",
	"FloatingBattlePetTooltip",
	"FloatingPetBattleAbilityTooltip",
	"PetJournalPrimaryAbilityTooltip",
	"FloatingGarrisonFollowerTooltip",
	"GarrisonFollowerAbilityTooltip",
	"GarrisonMissionMechanicTooltip",
	"GarrisonShipyardMapMissionTooltip",
	"GarrisonMissionMechanicFollowerCounterTooltip",
	"ContributionTooltip",
	"ContributionBuffTooltip",
	"AddonTooltip",
	"LibDBIconTooltip",
	"AceConfigDialogTooltip",
}

-- local variables
local oldDefault = {}
local initialScale = {}

-- ####################################################################################################################
-- ##### Default Settings #############################################################################################
-- ####################################################################################################################

module.defaults = {
	profile = {
		HideCombat = false,
		HideCombatSkills = false,
		HideCombatUnit = false,
		HideUF = false,
		Cursor = false,
		Point = "RIGHT",
		Scale = 1,
		X = -150,
		Y = 0,
		HealthBar = "LUI_Minimalist",
		HealthBarHeight = 6,
		HealthTextX = 0,
		HealthTextY = 9,
		BgTexture = "Blizzard Dialog Background Dark",
		Colors = {
			Border =     { r = 0.3,  g = 0.3,  b = 0.3,  a = 1, t = "Individual", },
			Guild =      { r = 0,    g = 1,    b = 0.1,                           },
			MyGuild =    { r = 0,    g = 0.55, b = 1,                             },
		},
		Fonts = {
			Health = { Name = "NotoSans-SCB", Size = 12, Flag = "OUTLINE", },
		},
	},
}

-- ####################################################################################################################
-- ##### Revert Functions #############################################################################################
-- ####################################################################################################################

function module:RevertTooltipBackdrop()
	for i = 1, #TOOLTIPS_LIST do
		local tooltipName = TOOLTIPS_LIST[i]
		local tooltip = _G[tooltipName]
		if tooltip then
			if tooltip.NineSlice then tooltip.NineSlice:SetAlpha(1) end
			tooltip:SetScale(initialScale[tooltipName] or 1)
		end
	end

	-- This tooltip has no name, need to fetch and manually invoke
	-- It is the tooltip that appears when hovering the campaign at the top of the questlog
	local campaignFrame = _G.QuestMapLog_GetCampaignTooltip()
	campaignFrame.NineSlice:SetAlpha(1)
	campaignFrame:SetScale(1)
end

function module:RevertHealthBar()
	local health = GameTooltipStatusBar
	local numPoints = health:GetNumPoints()
	health:ClearAllPoints()
	for i = 1, numPoints do
		local point, relativeTo, relativePoint, xOffset, yOffset = unpack(oldDefault.Health.Points[i])
		health:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
	end
	health:SetHeight(oldDefault.Health.Height)
	health:SetStatusBarTexture(oldDefault.Health.StatusBarTexture)
	health:SetScript("OnValueChanged", oldDefault.Health.OnValueChanged)
	if health.text then health.text:Hide() end
end

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

-- Get a unit token out of a tooltip frame for use in many Unit functions.

local function GetTooltipOwnerUnit(tooltip)
	local owner = tooltip and tooltip.GetOwner and tooltip:GetOwner()

	while owner do
		local unit
		if owner.GetAttribute then
			unit = owner:GetAttribute("unit")
		end
		if type(unit) == "string" and not issecretvalue(unit) then
			return unit
		end

		unit = owner.__unit
		if type(unit) == "string" and not issecretvalue(unit) then
			return unit
		end

		owner = owner.GetParent and owner:GetParent()
	end
end

--- Get a unit token out of a tooltip frame for use in many Unit functions.
---@param data TooltipData
---@param tooltip GameTooltip?
---@return string?
function module:GetTooltipUnit(data, tooltip)
	local ownerUnit = GetTooltipOwnerUnit(tooltip)
	if ownerUnit then return ownerUnit end

	if not data then return end
	local guid = data.guid
	if not issecretvalue(guid) and guid then
		local unit = UnitTokenFromGUID(guid)
		if unit and not issecretvalue(unit) then
			return unit
		end
	end
	if UnitExists("mouseover") then
		return "mouseover"
	end
end

function module:UpdateTooltipBackdrop(frame)
	if not frame then return end
	if frame.IsForbidden and frame:IsForbidden() then return end

	-- Keep Blizzard's 12.1 NineSlice layout and only change its existing
	-- textures and colors. Adding BackdropTemplateMixin or calling SetBackdrop
	-- here can make secret tooltip dimensions enter Backdrop.lua arithmetic.
	local nineSlice = frame.NineSlice
	if nineSlice then
		nineSlice:SetAlpha(1)

		local background = nineSlice.Center
		if background and background.SetTexture then
			background:SetTexture(Media:Fetch("background", db.BgTexture))
			background:SetTexCoord(0, 1, 0, 1)
			nineSlice:SetCenterColor(1, 1, 1, 1)
		end

		if nineSlice.SetBorderColor then
			nineSlice:SetBorderColor(module:RGBA("Border"))
		end
	end
end

-- Debug function, this will call UpdateTooltipBackdrop, optionally add a tooltip before doing so.
function LUI:ForceTooltipUpdate(ttip)
	if not ttip then
		module:UpdateBackdropColors()
		return
	end

	local frame = ttip
	if type(ttip) == "string" then
		frame = _G[ttip]
		local registered
		for i = 1, #TOOLTIPS_LIST do
			if TOOLTIPS_LIST[i] == ttip then
				registered = true
				break
			end
		end
		if not registered then
			tinsert(TOOLTIPS_LIST, ttip)
		end
	end

	module:UpdateTooltipBackdrop(frame)
end

function module:GetUnitColor(unit)
	local isPlayer = UnitIsPlayer(unit)
	local hasVehicleUI = UnitHasVehicleUI(unit)
	if issecretvalue(isPlayer) or issecretvalue(hasVehicleUI) then
		return 1, 1, 1
	elseif isPlayer and not hasVehicleUI then
		local _, class = UnitClass(unit)
		if issecretvalue(class) then return 1, 1, 1 end
		return module:RGB(class)
	else
		return LUI:GetReactionColor(unit)
	end
end

-- ####################################################################################################################
-- ##### Module Setup #################################################################################################
-- ####################################################################################################################

function module:SetTooltip(tooltip, name)
	-- Retail tooltips use SharedTooltipTemplate/NineSlice natively.
	-- Keep that native layout instead of mixing BackdropTemplate into
	-- Blizzard/Ace tooltips after creation.
	if tooltip.NineSlice then
		tooltip.NineSlice:SetAlpha(1)
	end

	-- Store initial scale for future reference
	if name and not initialScale[name] then
		initialScale[name] = tooltip:GetScale()
	end

	-- Hook its OnShow
	if not module:IsHooked(tooltip, "OnShow") then
		module:HookScript(tooltip, "OnShow", "OnTooltipShow")
	end
end

function module:SetTooltips()
	-- Iterate through the list of tooltips we want to alter
	for i = 1, #TOOLTIPS_LIST do
		local tooltipName = TOOLTIPS_LIST[i]
		local tooltip = _G[tooltipName]

		if tooltip then
			module:SetTooltip(tooltip, tooltipName)
		end
	end

	-- This tooltip has no name, need to fetch and manually invoke
	-- It is the tooltip that appears when hovering the campaign at the top of the questlog
	if LUI.IsRetail then module:SetTooltip(QuestMapLog_GetCampaignTooltip()) end

	-- TODO: Yet to solve the StoreTooltip, if possible
end

-- luacheck: globals GameTooltipStatusBar
local function SetupStatusHealthText(health)
	if not health.text then
		health.text = health:CreateFontString(nil, "OVERLAY")
	end

	local font = db.Fonts.Health
	health.text:ClearAllPoints()
	health.text:SetPoint("CENTER", health, "CENTER", db.HealthTextX, db.HealthTextY)
	health.text:SetFont(Media:Fetch("font", font.Name), font.Size, font.Flag)
	health.text:Show()
end

function module:SetStatusHealthBar()
	local health = GameTooltipStatusBar

	-- Save default data before replacing it (for reverting)
	if not oldDefault.Health then
		oldDefault.Health = {}
		oldDefault.Health.Points = {}
		for i = 1, health:GetNumPoints() do
			oldDefault.Health.Points[i] = { health:GetPoint(i) }
		end
		oldDefault.Health.Height = health:GetHeight()
		oldDefault.Health.StatusBarTexture = health:GetStatusBarTexture()
		oldDefault.Health.OnValueChanged = health:GetScript("OnValueChanged")
	end

	-- Change the Health bar
	health:ClearAllPoints()
	health:SetHeight(db.HealthBarHeight)
	health:SetPoint("BOTTOMLEFT", health:GetParent(), "TOPLEFT", 2, 5)
	health:SetPoint("BOTTOMRIGHT", health:GetParent(), "TOPRIGHT", -2, 5)
	health:SetStatusBarTexture(Media:Fetch("statusbar", db.HealthBar))
	SetupStatusHealthText(health)

	-- Add health values.
	health:SetScript("OnValueChanged", module.OnStatusBarValueChanged)
end

function module:SetBorderColor(frame)
	-- WoW 12.1 tooltips keep Blizzard's native NineSlice backdrop. We still
	-- color the tooltip health bar, but do not call legacy backdrop methods.
	local health = GameTooltipStatusBar
	local tooltipData = frame.GetTooltipData and frame:GetTooltipData()
	local tooltipType = tooltipData and tooltipData.type
	local r, g, b = module:RGB("Border")

	if db.Colors.Border.t == "Class"
		and not issecretvalue(tooltipType)
		and tooltipType == Enum.TooltipDataType.Unit then
		local unit = module:GetTooltipUnit(tooltipData, frame)
		if unit then
			local playerUnit = UnitIsPlayer(unit)
			local reaction = UnitReaction(unit, "player")
			if not issecretvalue(playerUnit) and playerUnit then
				local _, class = UnitClass(unit)
				if not issecretvalue(class) then
					r, g, b = module:RGB(class)
				end
			elseif not issecretvalue(reaction) and reaction then
				r, g, b = LUI:GetReactionColor(unit)
			end
		end
	end

	health:SetStatusBarColor(r, g, b)
	if frame.NineSlice and frame.NineSlice.SetBorderColor then
		frame.NineSlice:SetBorderColor(r, g, b, 1)
	end
end

function module:UpdateBackdropColors()
	for i = 1, #TOOLTIPS_LIST do
		module:UpdateTooltipBackdrop(_G[TOOLTIPS_LIST[i]])
	end
	GameTooltipStatusBar:SetStatusBarColor(module:RGB("Border"))
end

function module:Refresh()
	db = module.db.profile
	module:SetStatusHealthBar()
	module:UpdateBackdropColors()
end

module.RefreshColors = module.Refresh

-- ####################################################################################################################
-- ##### Module Hooks and Scripts #####################################################################################
-- ####################################################################################################################

function module.OnStatusBarValueChanged(frame)
	local unit = module:GetTooltipUnit(GameTooltip:GetTooltipData(), GameTooltip)
	if not unit then return end

	local isGhost = UnitIsGhost(unit)
	local isDead = UnitIsDead(unit)
	if not issecretvalue(isGhost) and isGhost then
		frame.text:SetText(L["Tooltip_Ghost"])
	elseif not issecretvalue(isDead) and isDead then
		frame.text:SetText(_G.DEAD)
	else
		-- Both BreakUpLargeNumbers and FontString:SetFormattedText accept secret
		-- values, preserving localized thousands separators for restricted health.
		frame.text:SetFormattedText(
			"%s / %s",
			BreakUpLargeNumbers(UnitHealth(unit)),
			BreakUpLargeNumbers(UnitHealthMax(unit))
		)
	end
	frame:Show()
end

function module:OnTooltipShow(frame)
	if db.HideCombat and InCombatLockdown() then
		return frame:Hide()
	end
	
	---@TODO: Investigate why a frame with no name would be called for this function. Issue #46
	if not frame.GetName then return end

	--If a frame has a smaller scale than normal for any reasons, make sure that's respected.
	if initialScale[frame:GetName()] then
		frame:SetScale(initialScale[frame:GetName()] * db.Scale)
	else
		frame:SetScale(db.Scale)
	end

	module:UpdateTooltipBackdrop(frame)
	module:SetBorderColor(frame)

end

local function GetGuildTooltipLine(data)
	local lines = data and data.lines
	if not lines or issecretvalue(lines) then return end

	-- Blizzard does not assign a dedicated TooltipDataLineType to the guild
	-- row. In a player tooltip the guild row directly precedes the localized
	-- level row, so identify both from the structured tooltip data.
	local guildLine = lines[2]
	local levelLine = lines[3]
	local unitLine = lines[1]
	if not unitLine or not guildLine or not levelLine
		or issecretvalue(unitLine) or issecretvalue(guildLine)
		or issecretvalue(levelLine) then return end

	local guildText = guildLine.leftText
	local levelText = levelLine.leftText
	if not guildText or not levelText
		or issecretvalue(guildText) or issecretvalue(levelText) then return end

	if levelText:find(LEVEL, 1, true) then
		local unit = unitLine.unitToken
		if issecretvalue(unit) then unit = nil end
		return 2, guildText, unit
	end
end

function module:ApplyGuildColor(frame, data)
	if not frame or frame:IsForbidden() then return end

	local lineIndex, tooltipGuild, unit = GetGuildTooltipLine(data)
	if not tooltipGuild or not lineIndex then return end

	local guildColorName = "Guild"
	local isMyGuild = unit and UnitIsInMyGuild(unit)
	if not issecretvalue(isMyGuild) and isMyGuild then
		guildColorName = "MyGuild"
	end

	local frameName = frame:GetName()
	local guildLine = frameName and _G[frameName.."TextLeft"..lineIndex]
	if guildLine then
		guildLine:SetTextColor(module:RGB(guildColorName))
	end
end

--- Tooltip Processing function
---@param frame GameTooltip
---@param data TooltipData
function module.OnGameTooltipSetUnit(frame, data)
	if frame:IsForbidden() then return end
	-- luacheck: globals GameTooltipTextLeft1
	
	-- We're only interested in setting up the GameTooltip itself, not all frames of that type.
	if not frame.GetName or frame:GetName() ~= "GameTooltip" then return end

	-- Blizzard applies the unit tooltip layout after OnShow. Reapply the selected
	-- background texture after the tooltip data is complete.
	module:UpdateTooltipBackdrop(frame)
	
	if db.HideCombatUnit and InCombatLockdown() then
		return frame:Hide()
	end

	-- The tooltip data is authoritative even when Blizzard does not expose a
	-- usable unit token for the hovered player.
	module:ApplyGuildColor(frame, data)

	-- oUF frames expose their active unit through __unit.
	local owner = frame:GetOwner()
	if db.HideUF and owner and owner.__unit then
		return frame:Hide()
	end

	local unit = module:GetTooltipUnit(data, frame)
	-- Blizzard can populate a valid tooltip even when its protected GUID cannot
	-- be resolved back to a public unit token. Keep that native tooltip intact.
	if not unit then return end

	-- The status bar value may already be set before OnValueChanged is hooked.
	-- Refresh its text whenever Blizzard finishes building a unit tooltip.
	module.OnStatusBarValueChanged(GameTooltipStatusBar)

	local title = UnitPVPName(unit)
	local name, realm = UnitName(unit)
	local isPlayer = UnitIsPlayer(unit)

	-- Identity fields can be secret in 12.1. Do not concatenate/index them.
	if issecretvalue(title) or issecretvalue(name) or issecretvalue(realm)
		or issecretvalue(isPlayer) then
		return
	end
	local realmSuffix = (realm and " - "..realm) or ""

	local unitColor = CreateColor(module:GetUnitColor(unit))

	local tooltipText = unitColor:WrapTextInColorCode((title or name)..realmSuffix)
	GameTooltipTextLeft1:SetText(tooltipText or "")

	if isPlayer then
		-- Display status next to name
		if not issecretvalue(UnitIsDND(unit)) and UnitIsDND(unit) then
			frame:AppendText(" "..CHAT_FLAG_DND)
		elseif not issecretvalue(UnitIsAFK(unit)) and UnitIsAFK(unit) then
			frame:AppendText(" "..CHAT_FLAG_AFK)
		end
	end

	--Add ToT Line
	local targetExists = UnitExists(unit.."target")
	if not issecretvalue(targetExists) and targetExists and unit~="player" then
		local targetName = UnitName(unit.."target")
		if targetName ~= nil and not issecretvalue(targetName) then
			GameTooltip:AddLine(targetName, module:GetUnitColor(unit.."target"))
		end
	end

	module:SetBorderColor(frame)
end

function module:HideCombatSkillTooltips(frame)
	if db.HideCombatSkills and InCombatLockdown() and not IsShiftKeyDown() then
		frame:Hide()
	end
end

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

module.enableButton = true

function module:OnInitialize()
	LUI:RegisterModule(module)
	db = module.db.profile
end

function module:OnEnable()
	module:SetTooltips()

	-- Many tooltips are found in Blizzard LoadOnDemand addons
	module:RegisterEvent("ADDON_LOADED", "SetTooltips")
	module:SecureHook("SharedTooltip_SetBackdropStyle", "UpdateTooltipBackdrop")

	module:SecureHook("GameTooltip_SetDefaultAnchor", function(frame, parent)
		if db.Cursor then
			frame:SetOwner(parent, "ANCHOR_CURSOR")
		else
			frame:SetOwner(parent, "ANCHOR_NONE")
			frame:ClearAllPoints()
			frame:SetPoint(db.Point, UIParent, db.X, db.Y)
		end
	end)


	module:SetStatusHealthBar()
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, module.OnGameTooltipSetUnit)

	--Hide ability tooltips if option is enabled
	module:SecureHook(GameTooltip, "SetAction", "HideCombatSkillTooltips")
	module:SecureHook(GameTooltip, "SetPetAction", "HideCombatSkillTooltips")
	module:SecureHook(GameTooltip, "SetShapeshift", "HideCombatSkillTooltips")
end

function module:OnDisable()
	module:RevertTooltipBackdrop()
	module:RevertHealthBar()
end
