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
}

local TOOLTIP_BACKGROUND_TILE_SIZE = 16

-- local variables
local oldDefault = {}
local initialScale = setmetatable({}, { __mode = "k" })
local nativeBackdrop = setmetatable({}, { __mode = "k" })
local tooltipPostCallRegistered = false

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
			Background = { r = 0,    g = 0,    b = 0,    a = 0.8,                   },
			Guild =      { r = 0,    g = 0.55, b = 1,                             },
			MyGuild =    { r = 0,    g = 1,    b = 0.1,                           },
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
		local tooltip = _G[TOOLTIPS_LIST[i]]
		if tooltip and (not tooltip.IsForbidden or not tooltip:IsForbidden()) then
			module:RestoreNativeBackdrop(tooltip)
			tooltip:SetScale(initialScale[tooltip] or 1)
		end
	end

	-- This tooltip has no name, need to fetch and manually invoke
	-- It is the tooltip that appears when hovering the campaign at the top of the questlog
	local getCampaignTooltip = _G.QuestMapLog_GetCampaignTooltip
	local campaignFrame = getCampaignTooltip and getCampaignTooltip()
	if campaignFrame and (not campaignFrame.IsForbidden or not campaignFrame:IsForbidden()) then
		module:RestoreNativeBackdrop(campaignFrame)
		campaignFrame:SetScale(initialScale[campaignFrame] or 1)
	end
end

function module:RevertHealthBar()
	local health = GameTooltipStatusBar
	local stored = oldDefault.Health
	if not stored then return end
	health:ClearAllPoints()
	for i = 1, #stored.Points do
		local point, relativeTo, relativePoint, xOffset, yOffset = unpack(stored.Points[i])
		health:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
	end
	health:SetHeight(stored.Height)
	local texture = health:GetStatusBarTexture()
	if stored.StatusBarAtlas then
		texture:SetAtlas(stored.StatusBarAtlas)
	else
		texture:SetTexture(stored.StatusBarTexture)
	end
	texture:SetTexCoord(unpack(stored.StatusBarTexCoord))
	texture:SetVertexColor(unpack(stored.StatusBarVertexColor))
	health:SetScript("OnValueChanged", stored.OnValueChanged)
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
	local mouseoverExists = UnitExists("mouseover")
	if not issecretvalue(mouseoverExists) and mouseoverExists then
		return "mouseover"
	end
end

local function SetTooltipBackgroundTexture(frame, background, texture)
	background:SetTexture(texture, true, true)

	-- SharedMedia background entries are backdrop tiles, not full-frame images.
	-- Reproduce BackdropTemplate's tile sizing on the existing NineSlice center
	-- without feeding protected tooltip dimensions into SharedXML/Backdrop.lua.
	local width, height = background:GetSize()
	if not issecretvalue(width) and not issecretvalue(height)
		and type(width) == "number" and type(height) == "number" then
		local scale = frame:GetEffectiveScale()
		if issecretvalue(scale) or type(scale) ~= "number" then scale = 1 end
		background:SetTexCoord(
			0, math.max(1, width * scale / TOOLTIP_BACKGROUND_TILE_SIZE),
			0, math.max(1, height * scale / TOOLTIP_BACKGROUND_TILE_SIZE)
		)
	else
		background:SetTexCoord(0, 1, 0, 1)
	end
	-- Preserve Blizzard's existing NineSlice center color. LibQTip-based
	-- addons copy GameTooltip's colors without copying its background texture.
end

function module:UpdateTooltipBackdrop(frame)
	if not frame then return end
	if frame.IsForbidden and frame:IsForbidden() then return end

	-- Keep Blizzard's 12.1 NineSlice layout and only change its existing
	-- textures and colors. Adding the legacy backdrop mixin or API calls
	-- here can make secret tooltip dimensions enter Backdrop.lua arithmetic.
	local nineSlice = frame.NineSlice
	if nineSlice and not (nineSlice.IsForbidden and nineSlice:IsForbidden()) then
		module:CaptureNativeBackdrop(frame)
		nineSlice:SetAlpha(1)

		local background = nineSlice.Center
		if background and background.SetTexture then
			local texture = Media:Fetch("background", db.BgTexture, true)
			if db.BgTexture == "None" or not texture or texture == "" then
				background:SetColorTexture(1, 1, 1, 1)
				background:SetTexCoord(0, 1, 0, 1)
				background:SetVertexColor(module:RGBA("Background"))
			else
				SetTooltipBackgroundTexture(frame, background, texture)
			end
		end

		if nineSlice.SetBorderColor then
			nineSlice:SetBorderColor(module:RGBA("Border"))
		end
	end
end

function module:CaptureNativeBackdrop(frame, refreshCenter)
	local nineSlice = frame and frame.NineSlice
	local background = nineSlice and nineSlice.Center
	if not background or (nineSlice.IsForbidden and nineSlice:IsForbidden()) then return end

	local state = nativeBackdrop[frame]
	if not state then
		state = {
			alpha = nineSlice:GetAlpha(),
			borderColor = { nineSlice:GetBorderColor() },
		}
		nativeBackdrop[frame] = state
	end

	if refreshCenter or not state.centerTexture then
		state.centerAtlas = background.GetAtlas and background:GetAtlas() or nil
		state.centerTexture = background:GetTexture()
		state.centerTexCoord = { background:GetTexCoord() }
		state.centerColor = { background:GetVertexColor() }
	end
end

function module:RestoreNativeBackdrop(frame)
	local state = nativeBackdrop[frame]
	local nineSlice = frame and frame.NineSlice
	local background = nineSlice and nineSlice.Center
	if not state or not background then return end

	if state.centerAtlas then
		background:SetAtlas(state.centerAtlas)
	else
		background:SetTexture(state.centerTexture)
	end
	background:SetTexCoord(unpack(state.centerTexCoord))
	background:SetVertexColor(unpack(state.centerColor))
	nineSlice:SetBorderColor(unpack(state.borderColor))
	nineSlice:SetAlpha(state.alpha)
	nativeBackdrop[frame] = nil
end

function module:OnBackdropStyleApplied(frame)
	if not module:IsEnabled() then return end
	module:CaptureNativeBackdrop(frame, true)
	module:UpdateTooltipBackdrop(frame)
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
		if issecretvalue(class) then
			local color = C_ClassColor.GetClassColor(class)
			return color:GetRGB()
		end
		return module:RGB(class)
	else
		return LUI:GetReactionColor(unit)
	end
end

-- ####################################################################################################################
-- ##### Module Setup #################################################################################################
-- ####################################################################################################################

function module:SetTooltip(tooltip)
	if not tooltip or (tooltip.IsForbidden and tooltip:IsForbidden()) then return end

	-- Retail tooltips use SharedTooltipTemplate/NineSlice natively.
	-- Keep that native layout instead of mixing legacy backdrop support into
	-- Blizzard/Ace tooltips after creation.
	if tooltip.NineSlice then
		tooltip.NineSlice:SetAlpha(1)
	end

	-- Store initial scale for future reference
	if not initialScale[tooltip] then
		initialScale[tooltip] = tooltip:GetScale()
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
			module:SetTooltip(tooltip)
		end
	end

	-- This tooltip has no name, need to fetch and manually invoke
	-- It is the tooltip that appears when hovering the campaign at the top of the questlog
	local getCampaignTooltip = _G.QuestMapLog_GetCampaignTooltip
	if LUI.IsRetail and getCampaignTooltip then
		module:SetTooltip(getCampaignTooltip())
	end

	-- StoreTooltip belongs to Blizzard_StoreUI's forbidden scope in Retail 12.1.
	-- Addons must leave it untouched.
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
		local statusBarTexture = health:GetStatusBarTexture()
		oldDefault.Health.StatusBarAtlas = statusBarTexture.GetAtlas and statusBarTexture:GetAtlas() or nil
		oldDefault.Health.StatusBarTexture = statusBarTexture:GetTexture()
		oldDefault.Health.StatusBarTexCoord = { statusBarTexture:GetTexCoord() }
		oldDefault.Health.StatusBarVertexColor = { statusBarTexture:GetVertexColor() }
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
	local color = module:Color("Border")

	if db.Colors.Border.t == "Class"
		and not issecretvalue(tooltipType)
		and tooltipType == Enum.TooltipDataType.Unit then
		local unit = module:GetTooltipUnit(tooltipData, frame)
		if unit then
			local playerUnit = UnitIsPlayer(unit)
			local reaction = UnitReaction(unit, "player")
			if not issecretvalue(playerUnit) and playerUnit then
				local _, class = UnitClass(unit)
				if issecretvalue(class) then
					color = C_ClassColor.GetClassColor(class)
				elseif class then
					color = module:Color(class)
				end
			elseif not issecretvalue(reaction) and reaction then
				color = CreateColor(LUI:GetReactionColor(unit))
			end
		end
	end

	if not color then return end
	health:SetStatusBarColor(color:GetRGB())
	if frame.NineSlice and frame.NineSlice.SetBorderColor then
		local r, g, b = color:GetRGB()
		frame.NineSlice:SetBorderColor(r, g, b, 1)
	end
end

function module:UpdateBackdropColors()
	for i = 1, #TOOLTIPS_LIST do
		module:UpdateTooltipBackdrop(_G[TOOLTIPS_LIST[i]])
	end
	local color = module:Color("Border")
	if color then GameTooltipStatusBar:SetStatusBarColor(color:GetRGB()) end
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
	if not module:IsEnabled() then return end
	if db.HideCombat and InCombatLockdown() then
		return frame:Hide()
	end

	--If a frame has a smaller scale than normal for any reasons, make sure that's respected.
	if initialScale[frame] then
		frame:SetScale(initialScale[frame] * db.Scale)
	else
		frame:SetScale(db.Scale)
	end

	module:UpdateTooltipBackdrop(frame)
	module:SetBorderColor(frame)

end

local function GetGuildTooltipLine(data)
	local lines = data and data.lines
	if not lines or issecretvalue(lines) then return end

	-- The guild row has no dedicated line type. Locate Blizzard's UnitLevel
	-- row and color the immediately preceding row instead of assuming that
	-- guild and level are always lines 2 and 3.
	for index = 3, #lines do
		local levelLine = lines[index]
		if levelLine and not issecretvalue(levelLine) then
			local levelText = levelLine.leftText
			local isLevelLine = levelLine.type == Enum.TooltipDataLineType.UnitLevel
				or (levelText and not issecretvalue(levelText) and levelText:find(LEVEL, 1, true))
			if isLevelLine then
				local guildIndex = index - 2
				if guildIndex <= 1 then return end
				local guildLine = lines[guildIndex]
				local guildText = guildLine and not issecretvalue(guildLine) and guildLine.leftText
				if guildText and not issecretvalue(guildText) then
					return guildIndex, guildText
				end
			end
		end
	end
end

function module:ApplyGuildColor(frame, data)
	if not frame or frame:IsForbidden() then return end

	local lineIndex, tooltipGuild = GetGuildTooltipLine(data)
	if not tooltipGuild or not lineIndex then return end

	local guildColorName = "Guild"
	local unit = module:GetTooltipUnit(data, frame)
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
	if not module:IsEnabled() then return end
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
		local isDND = UnitIsDND(unit)
		local isAFK = UnitIsAFK(unit)
		if not issecretvalue(isDND) and isDND then
			frame:AppendText(" "..CHAT_FLAG_DND)
		elseif not issecretvalue(isAFK) and isAFK then
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
	if not module:IsEnabled() then return end
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
	module:SecureHook("SharedTooltip_SetBackdropStyle", "OnBackdropStyleApplied")

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
	-- Blizzard provides no removal API for tooltip post-calls. Register once and
	-- let the callback's enabled-state guard handle later module toggles.
	if not tooltipPostCallRegistered then
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, module.OnGameTooltipSetUnit)
		tooltipPostCallRegistered = true
	end

	--Hide ability tooltips if option is enabled
	module:SecureHook(GameTooltip, "SetAction", "HideCombatSkillTooltips")
	module:SecureHook(GameTooltip, "SetPetAction", "HideCombatSkillTooltips")
	module:SecureHook(GameTooltip, "SetShapeshift", "HideCombatSkillTooltips")
end

function module:OnDisable()
	module:UnregisterEvent("ADDON_LOADED")
	module:UnhookAll()
	module:RevertTooltipBackdrop()
	module:RevertHealthBar()
end
