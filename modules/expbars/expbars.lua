--[[
	This module manages progress bars for experience, reputation, honor,
	Heart of Azeroth and house favor.

	When a secondary tracker is active, the bars can either share the main
	anchor or use two independent anchors:
	[secondary tracker] [primary tracker]

	Each tracker lives in its own data-provider file. This file owns the shared
	bar mixins, provider registration, selection priority and layout; XP and
	reputation data handling should remain in their provider files.
]]

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.ExperienceBars
local module = LUI:GetModule("Experience Bars")
local Media = LibStub("LibSharedMedia-3.0")
local GameTooltip = _G.GameTooltip
local InCombatLockdown = _G.InCombatLockdown
local RoundToSignificantDigits = _G.RoundToSignificantDigits
local max = math.max
local tonumber = tonumber
local type = type

local POINT_COORDS = {
	TOPLEFT = {0, 1}, TOP = {0.5, 1}, TOPRIGHT = {1, 1},
	LEFT = {0, 0.5}, CENTER = {0.5, 0.5}, RIGHT = {1, 0.5},
	BOTTOMLEFT = {0, 0}, BOTTOM = {0.5, 0}, BOTTOMRIGHT = {1, 0},
}

-- Match Blizzard's current status-tracking priority for the providers LUI supports.
-- House Favor has the highest priority, followed by Experience, Azerite, Honor and Reputation.
local TRACKER_PRIORITY = {
	"HouseFavor",
	"Experience",
	"Azerite",
	"Honor",
	"Reputation",
}

local function ValidPoint(point, fallback)
	return POINT_COORDS[point] and point or fallback
end

local function GetNumber(value, fallback, minimum)
	value = tonumber(value) or fallback
	if minimum then value = max(minimum, value) end
	return value
end

local function GetFramePoint(frame, point)
	local left, bottom, width, height = frame:GetRect()
	local coords = POINT_COORDS[point]
	if not left or not coords then return end
	return left + width * coords[1], bottom + height * coords[2]
end

--- Array containing all Data Providers that were loaded
---@type table<string, ExpBarDataProvider>
local dataProviderList = {}

--- Contains the bars that compose the primary exp bar
---@type ExpBar[]
local mainBarList = {}

-- ####################################################################################################################
-- ##### ExpBarDataProviderMixin ######################################################################################
-- ####################################################################################################################

---@class ExpBarDataProvider
---@field BAR_EVENTS WowEvent[] @ Array of events to register
local ExpBarDataProviderMixin = {
	BAR_EVENTS = {},
	barMin = 0,
	barValue = 0,
	barMax = 1,
}

--- Updates values whenever events are fired. This is only fired when the provider is visible.
---@param event WowEvent
function ExpBarDataProviderMixin:Update(event, ...)
	self.barMin = 0
	self.barValue = 0
	self.barMax = 1
end

--- Boolean function to know if the provider should be shown right now.
---@return boolean
function ExpBarDataProviderMixin:ShouldBeVisible()
	return false
end

--- Determine text being displayed
---@param style "None"|"Short"|"Full"?
---@return string text
function ExpBarDataProviderMixin:GetDataText(style)
	if style == "None" then return "" end
	return "No Data"
end

-- ####################################################################################################################
-- ##### ExpBarMixin ##################################################################################################
-- ####################################################################################################################

---@class ExpBar : ExpBarDataProvider, StatusBar
local ExpBarMixin = {provider = ""}

function ExpBarMixin:UpdateBar(event, ...)
	if not self:IsVisible() then return end

	self:Update(event, ...)
	self:SetMinMaxValues(self.barMin, self.barMax)
	self:SetValue(self.barValue)
	self:UpdateText()
end

function ExpBarMixin:UpdateText()
	local db = module.db.profile --[[@as table]]
	local trackerText = self:GetDataText(db.TrackerLabel or "Short") or ""
	local function AddTrackerText(valueText)
		if trackerText == "" then return valueText end
		if valueText == "" then return trackerText end
		return format("%s %s", valueText, trackerText)
	end
	local percentText = ""
	if db.ShowPercent then
		local precision = db.Precision or 2
		local percentBar = self.barMax > 0 and self.barValue / self.barMax * 100 or 0
		percentText = format("%."..precision.."f%%", percentBar)
		if not db.ShowCurrent then
			return self.text:SetText(AddTrackerText(percentText))
		end
	end
	if db.ShowCurrent then
		local text = db.ShortNumbers and AbbreviateNumbers(self.barValue) or self.barValue --[[@as string]]
		if db.ShowMax then
			text = format("%s/%s", text, db.ShortNumbers and AbbreviateNumbers(self.barMax) or self.barMax)
		end
		if db.ShowPercent then
			text = format("%s (%s)", text, percentText)
		end
		return self.text:SetText(AddTrackerText(text))
	end
	return self.text:SetText(trackerText)
end

function ExpBarMixin:ShowTooltip()
	local settings = module.db.profile
	if not settings.ShowTooltip then return end

	GameTooltip:SetOwner(self, "ANCHOR_TOP")
	GameTooltip:ClearLines()
	GameTooltip:AddLine(self:GetDataText("Full") or self.provider, 1, 0.82, 0)

	local current, maximum = self.barValue, self.barMax
	if type(current) == "number" and type(maximum) == "number"
		and not issecretvalue(current) and not issecretvalue(maximum) then
		GameTooltip:AddDoubleLine("Progress",
			format("%s / %s", BreakUpLargeNumbers(current), BreakUpLargeNumbers(maximum)),
			1, 1, 1, 1, 1, 1)
		local precision = settings.Precision or 2
		local percent = maximum > 0 and current / maximum * 100 or 0
		GameTooltip:AddDoubleLine("Percentage", format("%."..precision.."f%%", percent),
			1, 1, 1, 1, 1, 1)
	end
	GameTooltip:Show()
end

function ExpBarMixin:HideTooltip()
	if GameTooltip:GetOwner() == self then GameTooltip:Hide() end
end

local function StartAnchorMoving(frame)
	local anchor = frame.moveAnchor or frame
	if module.db.profile.Lock or InCombatLockdown() or not anchor then return end

	module.movingAnchor = anchor
	anchor:StartMoving()
	GameTooltip:Hide()
end

local function StopAnchorMoving(frame)
	local anchor = module.movingAnchor or frame.moveAnchor or frame
	if not anchor then return end

	module.movingAnchor = nil
	anchor:StopMovingOrSizing()
	module:SaveAnchorPosition(anchor)
end

function ExpBarMixin:UpdateInteractionState()
	local settings = module.db.profile
	self:EnableMouse(settings.ShowTooltip or not settings.Lock)
	if not settings.ShowTooltip then self:HideTooltip() end
end

function ExpBarMixin:UpdateTextVisibility()
	local db = module.db.profile
	if db.ShowText then
		self.text:Show()
	else
		self.text:Hide()
	end
end

function ExpBarMixin:SetBarColor(r, g, b, a)
	if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then
		r, g, b, a = module:RGBA(self.provider)
	end
	if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then
		r, g, b, a = 1, 1, 1, 1
	end

	local mult = tonumber(module.db.profile.BackgroundMultiplier) or 0.4
	a = type(a) == "number" and a or 1
	self:SetStatusBarColor(r, g, b, a)
	self.bg:SetVertexColor(r * mult, g * mult, b * mult, a)
end

function ExpBarMixin:RegisterEvents()
	if not self.BAR_EVENTS then return end
	for _, event in ipairs(self.BAR_EVENTS) do
		self:RegisterEvent(event)
	end
end

function module:SetEventHandling(enabled)
	if not module.anchor then return end

	local statusTrackingBarManager = _G.StatusTrackingBarManager
	if enabled then
		module.anchor:RegisterEvent("PLAYER_ENTERING_WORLD")
		module.anchor:RegisterEvent("PLAYER_MAX_LEVEL_UPDATE")
		module.anchor:RegisterEvent("UPDATE_FACTION")
		module.anchor:RegisterEvent("ENABLE_XP_GAIN")
		module.anchor:RegisterEvent("DISABLE_XP_GAIN")
		module.anchor:RegisterEvent("ZONE_CHANGED")
		module.anchor:RegisterEvent("ZONE_CHANGED_NEW_AREA")
		module.anchor:RegisterEvent("TRACKED_HOUSE_CHANGED")
		module.anchor:RegisterUnitEvent("UNIT_LEVEL", "player")
		if statusTrackingBarManager and not module:IsHooked(statusTrackingBarManager, "UpdateBarsShown") then
			module:SecureHook(statusTrackingBarManager, "UpdateBarsShown", "UpdateMainBarVisibility")
		end
		for bar in module:IterateMainBars() do
			bar:RegisterEvents()
		end
	else
		module.anchor:UnregisterAllEvents()
		if statusTrackingBarManager and module:IsHooked(statusTrackingBarManager, "UpdateBarsShown") then
			module:Unhook(statusTrackingBarManager, "UpdateBarsShown")
		end
		for bar in module:IterateMainBars() do
			bar:UnregisterAllEvents()
		end
	end
end

-- ####################################################################################################################
-- ##### Module Setup #################################################################################################
-- ####################################################################################################################

--- Create and register a data provider for the Experience Bars module
---@param name string
---@return ExpBarDataProvider dataProvider
function module:CreateBarDataProvider(name)
	local dataProvider = CreateFromMixins(ExpBarDataProviderMixin)
	dataProviderList[name] = dataProvider
	return dataProvider
end

--- Create an Exp Bar based on a given provider
---@param name string
---@param dataProvider string
---@return ExpBar
function module:CreateBar(name, dataProvider)
	local db = module.db.profile
	if not dataProvider or not dataProviderList[dataProvider] then
		error("Usage: CreateBar(name, dataProvider): dataProvider is not valid")
	end

	---@type ExpBar
	local bar = CreateFrame("StatusBar", name, module.anchor or UIParent)
	bar:SetFrameStrata("HIGH")
	bar:SetSize(GetNumber(db.Width, 475, 1), GetNumber(db.Height, 12, 1))
	bar:SetStatusBarTexture(module:FetchStatusBar("ExpBarFill"))

	local bg = bar:CreateTexture(nil, "BORDER")
	bg:SetTexture(module:FetchStatusBar("ExpBarBg"))
	bg:SetAllPoints(bar)
	bar.bg = bg

	local text = module:SetFontString(bar, name.."Text", "Text", "OVERLAY", "LEFT")
	text:SetPoint("RIGHT", bar, "RIGHT", db.TextX, db.TextY)
	text:SetTextColor(1, 1, 1)
	text:SetShadowColor(0, 0, 0)
	text:SetShadowOffset(1.25, -1.25)
	bar.text = text

	Mixin(bar, ExpBarMixin, dataProviderList[dataProvider])
	-- ExpBarMixin has an empty provider default, so assign the actual provider
	-- after mixing it into the bar instead of letting Mixin overwrite it.
	bar.provider = dataProvider
	bar:SetScript("OnEvent", function(_, event, ...)
		module:UpdateMainBarVisibility(event, ...)
	end)
	bar:SetScript("OnEnter", bar.ShowTooltip)
	bar:SetScript("OnLeave", bar.HideTooltip)
	bar:SetScript("OnDragStart", StartAnchorMoving)
	bar:SetScript("OnDragStop", StopAnchorMoving)
	bar:RegisterForDrag("LeftButton")
	bar:RegisterEvents()

	bar:SetBarColor(module:RGBA(dataProvider))
	bar:UpdateTextVisibility()
	bar:UpdateInteractionState()
	bar:Hide()

	return bar
end

local function CreateMover(anchor, label)
	local mover = CreateFrame("Frame", nil, anchor)
	mover:SetAllPoints(anchor)
	mover:SetFrameStrata("HIGH")
	mover:SetFrameLevel(anchor:GetFrameLevel() + 10)
	mover:EnableMouse(true)
	mover:RegisterForDrag("LeftButton")
	mover.moveAnchor = anchor
	mover:SetScript("OnDragStart", StartAnchorMoving)
	mover:SetScript("OnDragStop", StopAnchorMoving)

	local moverBackground = mover:CreateTexture(nil, "BACKGROUND")
	moverBackground:SetAllPoints(mover)
	moverBackground:SetColorTexture(0, 0.9, 0, 0.45)

	local moverText = mover:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	moverText:SetPoint("CENTER")
	moverText:SetText(label)

	return mover
end

-- ####################################################################################################################
-- ##### Main Bar #####################################################################################################
-- ####################################################################################################################

function module:IterateMainBars()
	local i, n = 0, #mainBarList
	return function()
		i = i + 1
		if i <= n then
			return mainBarList[i]
		end
	end
end

function module:SetMainBar()
	local db = module.db.profile --[[@as table]]
	local width = GetNumber(db.Width, 475, 1)
	local height = GetNumber(db.Height, 12, 1)
	local point = ValidPoint(db.Point, "BOTTOM")
	local relativePoint = ValidPoint(db.RelativePoint, "BOTTOM")

	local anchor = CreateFrame("Frame", "LUI_MainExpBar", UIParent)
	anchor:SetPoint(point, UIParent, relativePoint, GetNumber(db.X, 0), GetNumber(db.Y, 6))
	anchor:SetSize(width, height)
	module.anchor = anchor

	local secondaryAnchor = CreateFrame("Frame", "LUI_SecondaryExpBar", UIParent)
	secondaryAnchor:SetPoint(
		ValidPoint(db.SecondaryPoint, "BOTTOM"),
		UIParent,
		ValidPoint(db.SecondaryRelativePoint, "BOTTOM"),
		GetNumber(db.SecondaryX, 0),
		GetNumber(db.SecondaryY, 24)
	)
	secondaryAnchor:SetSize(GetNumber(db.SecondaryWidth, width, 1), height)
	module.secondaryAnchor = secondaryAnchor

	module.mover = CreateMover(anchor, "Experience Bar 1 - Drag to move")
	module.secondaryMover = CreateMover(secondaryAnchor, "Experience Bar 2 - Drag to move")

	anchor:SetScript("OnEvent", function(_, event, ...)
		module:UpdateMainBarVisibility(event, ...)
	end)

	local expBar = module:CreateBar("LUI_ExpBarsExp", "Experience")
	local repBar = module:CreateBar("LUI_ExpBarsRep", "Reputation")
	local honorBar = module:CreateBar("LUI_ExpBarsHonor", "Honor")
	local azeriteBar = module:CreateBar("LUI_ExpBarsAzerite", "Azerite")
	local houseFavorBar = module:CreateBar("LUI_ExpBarsHouseFavor", "HouseFavor")
	mainBarList = {expBar, repBar, honorBar, azeriteBar, houseFavorBar}

	module.ExperienceBar = expBar
	module.ReputationBar = repBar
	module.HonorBar = honorBar
	module.AzeriteBar = azeriteBar
	module.HouseFavorBar = houseFavorBar

	module:UpdateMoveState()
	return true -- mainBarsCreated
end

function module:UpdateMoveState()
	local db = module.db.profile
	local unlocked = not db.Lock

	module.anchor:SetMovable(unlocked)
	module.secondaryAnchor:SetMovable(unlocked)

	if unlocked then
		module.mover:Show()
	else
		module.mover:Hide()
	end

	if unlocked and db.SplitTracker and db.SeparateTrackerBars then
		module.secondaryAnchor:Show()
		module.secondaryMover:Show()
	else
		module.secondaryMover:Hide()
		if not module.secondaryActive then
			module.secondaryAnchor:Hide()
		end
	end
end

function module:SaveAnchorPosition(anchor)
	local db = module.db.profile
	local isSecondary = anchor == module.secondaryAnchor
	local pointKey = isSecondary and "SecondaryPoint" or "Point"
	local relativePointKey = isSecondary and "SecondaryRelativePoint" or "RelativePoint"
	local xKey = isSecondary and "SecondaryX" or "X"
	local yKey = isSecondary and "SecondaryY" or "Y"
	local point = ValidPoint(db[pointKey], "BOTTOM")
	local relativePoint = ValidPoint(db[relativePointKey], "BOTTOM")
	local frameX, frameY = GetFramePoint(anchor, point)
	local relativeX, relativeY = GetFramePoint(UIParent, relativePoint)
	if not frameX or not relativeX then return end

	db[xKey] = RoundToSignificantDigits(frameX - relativeX, 1)
	db[yKey] = RoundToSignificantDigits(frameY - relativeY, 1)
	anchor:ClearAllPoints()
	anchor:SetPoint(point, UIParent, relativePoint, db[xKey], db[yKey])
end

local function GetVisibleTrackers()
	local primary, secondary
	for _, provider in ipairs(TRACKER_PRIORITY) do
		local bar = module[provider.."Bar"]
		if bar and bar:ShouldBeVisible() then
			if not primary then
				primary = bar
			elseif not secondary then
				secondary = bar
				break
			end
		end
	end
	return primary, secondary
end

local function ConfigureBar(bar, anchor, width, height, reverseFill, textPoint, textX, textY)
	bar:ClearAllPoints()
	bar:SetReverseFill(reverseFill)
	bar:SetSize(width, height)
	bar:SetPoint(textPoint, anchor, textPoint)
	bar.moveAnchor = anchor
	bar.text:ClearAllPoints()
	bar.text:SetPoint(textPoint, bar, textPoint, textX, textY)
	bar:Show()
end

function module:UpdateMainBarVisibility(event, ...)
	local db = module.db.profile
	if not module.ExperienceBar or not module.ReputationBar
		or not module.HonorBar or not module.AzeriteBar or not module.HouseFavorBar then
		return
	end

	local primary, secondary = GetVisibleTrackers()
	if not db.SplitTracker then secondary = nil end

	for bar in module:IterateMainBars() do
		bar:Hide()
	end

	module.secondaryActive = secondary ~= nil and db.SplitTracker and db.SeparateTrackerBars

	local width = GetNumber(db.Width, 475, 1)
	local height = GetNumber(db.Height, 12, 1)
	local textX = GetNumber(db.TextX, -2)
	local textY = GetNumber(db.TextY, 0)
	module.anchor:SetSize(width, height)
	module.secondaryAnchor:SetHeight(height)

	if primary then
		if secondary and db.SeparateTrackerBars then
			local secondaryWidth = GetNumber(db.SecondaryWidth, width, 1)
			module.secondaryAnchor:SetWidth(secondaryWidth)
			module.secondaryAnchor:Show()
			ConfigureBar(primary, module.anchor, width, height, false, "RIGHT", textX, textY)
			ConfigureBar(secondary, module.secondaryAnchor, secondaryWidth, height, false, "RIGHT", textX, textY)
		elseif secondary then
			local spacing = GetNumber(db.Spacing, 10, 0)
			local halfWidth = max(1, (width - spacing) * 0.5)
			ConfigureBar(primary, module.anchor, halfWidth, height, false, "RIGHT", textX, textY)
			ConfigureBar(secondary, module.anchor, halfWidth, height, true, "LEFT", -textX, textY)
			module.secondaryAnchor:Hide()
		else
			ConfigureBar(primary, module.anchor, width, height, false, "RIGHT", textX, textY)
			module.secondaryAnchor:Hide()
		end
	else
		module.secondaryAnchor:Hide()
	end

	if primary then primary:UpdateBar(event, ...) end
	if secondary then secondary:UpdateBar(event, ...) end
	module:UpdateMoveState()
end

-- ####################################################################################################################
-- ##### Module Refresh ###############################################################################################
-- ####################################################################################################################

function module:RefreshColors()
	for bar in module:IterateMainBars() do
		bar:SetBarColor(module:RGBA(bar.provider))
	end
end

function module:Refresh()
	local db = module.db.profile
	if not module.anchor or not module.secondaryAnchor then return end

	local point = ValidPoint(db.Point, "BOTTOM")
	local relativePoint = ValidPoint(db.RelativePoint, "BOTTOM")
	module.anchor:ClearAllPoints()
	module.anchor:SetPoint(point, UIParent, relativePoint, GetNumber(db.X, 0), GetNumber(db.Y, 6))
	module.anchor:SetSize(GetNumber(db.Width, 475, 1), GetNumber(db.Height, 12, 1))

	local secondaryPoint = ValidPoint(db.SecondaryPoint, "BOTTOM")
	local secondaryRelativePoint = ValidPoint(db.SecondaryRelativePoint, "BOTTOM")
	module.secondaryAnchor:ClearAllPoints()
	module.secondaryAnchor:SetPoint(
		secondaryPoint,
		UIParent,
		secondaryRelativePoint,
		GetNumber(db.SecondaryX, 0),
		GetNumber(db.SecondaryY, 24)
	)
	module.secondaryAnchor:SetSize(
		GetNumber(db.SecondaryWidth, GetNumber(db.Width, 475, 1), 1),
		GetNumber(db.Height, 12, 1)
	)

	for bar in module:IterateMainBars() do
		bar:SetStatusBarTexture(module:FetchStatusBar("ExpBarFill"))
		bar.bg:SetTexture(module:FetchStatusBar("ExpBarBg"))
		bar.text:SetFont(Media:Fetch("font", db.Fonts.Text.Name), db.Fonts.Text.Size, db.Fonts.Text.Flag)
		bar:UpdateTextVisibility()
		bar:UpdateInteractionState()
	end
	module:RefreshColors()
	module:UpdateMainBarVisibility()
end
