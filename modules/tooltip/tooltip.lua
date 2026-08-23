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
local UnitClassification = _G.UnitClassification
local UnitTokenFromGUID = _G.UnitTokenFromGUID
local InCombatLockdown = _G.InCombatLockdown
local UnitCreatureType = _G.UnitCreatureType
local UnitHasVehicleUI = _G.UnitHasVehicleUI
local IsShiftKeyDown = _G.IsShiftKeyDown
local UnitHealthMax = _G.UnitHealthMax
local GetGuildInfo = _G.GetGuildInfo
local UnitIsPlayer = _G.UnitIsPlayer
local UnitReaction = _G.UnitReaction
local TooltipUtil = _G.TooltipUtil
local GetItemInfo = C_Item.GetItemInfo
local UnitIsGhost = _G.UnitIsGhost
local UnitPVPName = _G.UnitPVPName
local UnitExists = _G.UnitExists
local UnitHealth = _G.UnitHealth
local UnitIsDead = _G.UnitIsDead
local IsInGuild = _G.IsInGuild
local UnitClass = _G.UnitClass
local UnitIsAFK = _G.UnitIsAFK
local UnitIsDND = _G.UnitIsDND
local UnitLevel = _G.UnitLevel
local UnitName = _G.UnitName
local UnitRace = _G.UnitRace
local UnitSex = _G.UnitSex
local pairs = pairs

-- Constants
local TicketStatusFrame = _G.TicketStatusFrame
local CHAT_FLAG_DND = _G.CHAT_FLAG_DND
local CHAT_FLAG_AFK = _G.CHAT_FLAG_AFK
local PVP_ENABLED = _G.PVP_ENABLED
local GUILD = _G.GUILD
local LEVEL = _G.LEVEL
local DEAD = _G.DEAD
local BOSS = _G.BOSS

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

-- Need Localization
-- was local classification
local MOB_CLASSIFICATION = {
	worldboss = _G.BOSS,
	rareelite = L["Tooltip_Rare"].."+",
	elite = "+",
	rare = L["Tooltip_Rare"],
	minus = "-",  -- Does not give experience or reputation.
	normal = "",
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
		HidePVP = true,
		ShowSex = false,
		Cursor = false,
		Point = "RIGHT",
		Scale = 1,
		X = -150,
		Y = 0,
		HealthFontSize = 12,
		HealthBar = "LUI_Minimalist",
		BgTexture = "Blizzard Dialog Background Dark",
		BorderTexture = "Stripped_medium",
		BorderSize = 14,
		Colors = {
			Background = { r = 0.19, g = 0.19, b = 0.19, a = 1, t = "Individual", },
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
end

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

-- Get a unit token out of a tooltip frame for use in many Unit functions.

--- Get a unit token out of a tooltip frame for use in many Unit functions. Returns "mouseover" if the unit is secret.
---@param data TooltipData
---@return string?
function module:GetTooltipUnit(data)
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
	-- SharedTooltipTemplate uses Blizzard's native NineSlice layout.
	-- Do not add BackdropTemplateMixin or call SetBackdrop here: in 12.1
	-- tooltip dimensions can be secret, and Backdrop.lua performs arithmetic
	-- on those dimensions. Keep the native tooltip backdrop intact.
	if not frame then return end
	if frame.NineSlice then
		frame.NineSlice:SetAlpha(1)
	end
end

-- Debug function, this will call UpdateTooltipBackdrop, optionally add a tooltip before doing so.
function LUI:ForceTooltipUpdate(ttip)
	if ttip then
		tinsert(TOOLTIPS_LIST, ttip)
	end
	module:UpdateTooltipBackdrop()
end

local function CanQueryGuildInfo(unit)
	if type(unit) ~= "string" then return false end
	return unit == "player"
		or unit == "target"
		or unit == "focus"
		or unit == "mouseover"
		or unit:match("^party%d+$") ~= nil
		or unit:match("^raid%d+$") ~= nil
end

local function IsGuildQueryableUnit(unit)
	if type(unit) ~= "string" then return false end
	if unit == "player" or unit == "pet" or unit == "vehicle" then return true end
	if unit:match("^party%d+$") or unit:match("^raid%d+$") or unit:match("^boss%d+$") then return true end
	if unit == "target" or unit == "focus" then return true end
	return false
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
	end

	-- Change the Health bar
	health:ClearAllPoints()
	health:SetHeight(6)
	health:SetPoint("BOTTOMLEFT", health:GetParent(), "TOPLEFT", 2, 5)
	health:SetPoint("BOTTOMRIGHT", health:GetParent(), "TOPRIGHT", -2, 5)
	health:SetStatusBarTexture(Media:Fetch("statusbar", db.HealthBar))

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

	if not issecretvalue(tooltipType) and tooltipType == Enum.TooltipDataType.Unit then
		local unit = module:GetTooltipUnit(tooltipData)
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
end

function module:UpdateBackdropColors()
	GameTooltipStatusBar:SetStatusBarColor(module:RGB("Border"))
end

-- ####################################################################################################################
-- ##### Module Hooks and Scripts #####################################################################################
-- ####################################################################################################################

function module.OnStatusBarValueChanged(frame, value_)
	local unit = module:GetTooltipUnit(GameTooltip:GetTooltipData())
	if not unit then return end

	if not frame.text then
		frame.text = module:SetFontString(frame, nil, "Health", "OVERLAY")
		frame.text:SetPoint("CENTER", GameTooltipStatusBar, 0, 6)
		frame.text:Show()
	end

	if unit then
		local isGhost = UnitIsGhost(unit)
		local isDead = UnitIsDead(unit)
		if issecretvalue(isGhost) or issecretvalue(isDead) then
			frame.text:SetText("")
		elseif isGhost then
			frame.text:SetText(L["Tooltip_Ghost"])
		elseif isDead then
			frame.text:SetText(_G.DEAD)
		else
			local current, maximum = UnitHealth(unit), UnitHealthMax(unit)
			if issecretvalue(current) or issecretvalue(maximum) then
				frame.text:SetText("")
			else
				frame.text:SetFormattedText("%s / %s", BreakUpLargeNumbers(current), BreakUpLargeNumbers(maximum))
			end
		end
		frame:Show()
	else
		frame:Hide()
	end
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

	module:SetBorderColor(frame)
end

--- Tooltip Processing function
---@param frame GameTooltip
---@param data TooltipData
function module.OnGameTooltipSetUnit(frame, data)
	if frame:IsForbidden() then return end
	-- luacheck: globals GameTooltipTextLeft1 GameTooltipTextLeft2
	
	-- We're only interested in setting up the GameTooltip itself, not all frames of that type.
	if not frame.GetName or frame:GetName() ~= "GameTooltip" then return end
	
	if db.HideCombatUnit and InCombatLockdown() then
		return frame:Hide()
	end
	local unit = module:GetTooltipUnit(data)
	-- Blizzard can populate a valid tooltip even when its protected GUID cannot
	-- be resolved back to a public unit token. Keep that native tooltip intact.
	if not unit then return end

	-- Hide tooltip on unitframes if that option is enabled
	if frame:GetOwner() == UIParent and db.HideUF then
		return frame:Hide()
	end

	local sex = UnitSex(unit)
	local race = UnitRace(unit)
	local level = UnitLevel(unit)
	local title = UnitPVPName(unit)
	local guild = IsGuildQueryableUnit(unit) and CanQueryGuildInfo(unit) and GetGuildInfo(unit) or nil
	local name, realm = UnitName(unit)
	local creatureType = UnitCreatureType(unit)
	local localizedClass, class_ = UnitClass(unit)
	local classification = UnitClassification(unit)
	local isPlayer = UnitIsPlayer(unit)

	-- Identity fields can be secret in 12.1. Do not concatenate/index them.
	if issecretvalue(sex) or issecretvalue(race) or issecretvalue(level)
		or issecretvalue(title) or issecretvalue(name) or issecretvalue(realm)
		or issecretvalue(localizedClass) or issecretvalue(class_)
		or issecretvalue(classification) or issecretvalue(creatureType)
		or issecretvalue(guild) or issecretvalue(isPlayer) then
		return
	end
	local realmSuffix = (realm and " - "..realm) or ""

	local diffColor = CreateColor(LUI:GetDifficultyColor(level))
	local unitColor = CreateColor(module:GetUnitColor(unit))

	local tooltipText = unitColor:WrapTextInColorCode((title or name)..realmSuffix)
	GameTooltipTextLeft1:SetText(tooltipText or "")

	local offset = 2
	if isPlayer then
		-- Display status next to name
		if not issecretvalue(UnitIsDND(unit)) and UnitIsDND(unit) then
			frame:AppendText(" "..CHAT_FLAG_DND)
		elseif not issecretvalue(UnitIsAFK(unit)) and UnitIsAFK(unit) then
			frame:AppendText(" "..CHAT_FLAG_AFK)
		end
		if guild then
			local guildColorName = "Guild"
			-- Color guild name differently if it's your guild
			if IsInGuild() and GetGuildInfo("player") == guild then
				guildColorName = "MyGuild"
			end
			GameTooltipTextLeft2:SetText(module:ColorText(guild, guildColorName))
			offset = offset + 1
		end
	end

	-- The line with level information isnt always the same, so we need to do some scanning.
	for i = offset, frame:NumLines() do
		local line = _G["GameTooltipTextLeft"..i]
		local text = line and line:GetText()
		if text then
			line:SetFormattedText("%s", text)
		end

		-- if text then
		-- 	-- Level line for players
		-- 	-- if text:find(LEVEL) and race then
		-- 	if race then
		-- 		local levelString = (level > 0 and level) or "??"
		-- 		local levelText = diffColor:WrapTextInColorCode(levelString)
		-- 		local classText = unitColor:WrapTextInColorCode(localizedClass)
		-- 		local sexString = (db.ShowSex) and LUI.GENDERS[sex].." " or ""
		-- 		line:SetFormattedText("%s %s%s %s", levelText, sexString, race, classText)

		-- 	-- Level line for creatures
		-- 	-- elseif text:find(LEVEL) or (creatureType and text:find(creatureType)) then
		-- 	elseif creatureType then
		-- 		-- Need to find a new way to detect world bosses
		-- 		-- if text:find(BOSS) then
		-- 		-- 	-- Always color world bosses as skulls.
		-- 		-- 	classification = "worldboss"
		-- 		-- 	diffColor:SetRGB(module:RGB("DiffSkull"))
		-- 		-- end

		-- 		local levelString = (level > 0 and level) or ""
		-- 		local levelText = diffColor:WrapTextInColorCode(levelString)
		-- 		local classificationString = diffColor:WrapTextInColorCode(MOB_CLASSIFICATION[classification])
		-- 		line:SetFormattedText("%s%s %s", levelText, classificationString, creatureType or "")
		-- 	-- Remove the PVP line if the option is set
		-- 	elseif text == PVP_ENABLED and db.HidePVP then
		-- 		line:SetText("")
		-- 	end
		-- end
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
