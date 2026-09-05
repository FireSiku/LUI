--[[
	This module manages progress bars for experience, reputation, honor,
	Heart of Azeroth and house favor.

	The primary bar can split into two when a secondary tracker is active:
	[secondary tracker] [experience]

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
local db
local Media = LibStub("LibSharedMedia-3.0")

--- Array containing all Data Providers that were loaded
---@type ExpBarDataProvider[]
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
---@return string text
function ExpBarDataProviderMixin:GetDataText()
	return "No Data"
end

-- ####################################################################################################################
-- ##### ExpBarMixin ##################################################################################################
-- ####################################################################################################################

---@class ExpBar : ExpBarDataProvider, StatusBar
local ExpBarMixin = {provider = ""}

function ExpBarMixin:UpdateBar(event, ...)
	if self:IsVisible() then
		self:Update(event, ...)
		self:SetMinMaxValues(self.barMin, self.barMax)
		self:SetValue(self.barValue)
		self:UpdateText()
	end
end

function ExpBarMixin:UpdateText()
	local db = module.db.profile --[[@as table]]
	local percentText = ""
	if db.ShowPercent then
		local precision = db.Precision or 2
		local percentBar = self.barMax > 0 and self.barValue / self.barMax * 100 or 0
		percentText = format("%."..precision.."f%%", percentBar)
		if not db.ShowCurrent then
			return self.text:SetText(format("%s %s", percentText, self:GetDataText() or ""))
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
		return self.text:SetText(format("%s %s", text, self:GetDataText() or ""))
	end
	return self.text:SetText(self:GetDataText() or "")
end

function ExpBarMixin:UpdateVisibility()
	if self:ShouldBeVisible() then
		self:Show()
	else
		self:Hide()
	end
end

function ExpBarMixin:UpdateTextVisibility()
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
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	if not self.BAR_EVENTS then return end
	for i, event in ipairs(self.BAR_EVENTS) do
		self:RegisterEvent(event)
	end
end

function module:SetEventHandling(enabled)
	if not module.anchor then return end

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
		if not module:IsHooked(_G.StatusTrackingBarManager, "UpdateBarsShown") then
			module:SecureHook(_G.StatusTrackingBarManager, "UpdateBarsShown", "UpdateMainBarVisibility")
		end
		for bar in module:IterateMainBars() do
			bar:RegisterEvents()
		end
	else
		module.anchor:UnregisterAllEvents()
		if module:IsHooked(_G.StatusTrackingBarManager, "UpdateBarsShown") then
			module:Unhook(_G.StatusTrackingBarManager, "UpdateBarsShown")
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
	if not dataProvider or not dataProviderList[dataProvider] then
		error("Usage: CreateBar(name, dataProvider): dataProvider is not valid")
	end

	---@type ExpBar
	local bar = CreateFrame("StatusBar", name, module.anchor or UIParent)
	bar:SetFrameStrata("HIGH")
	bar:SetSize(db.Width, db.Height)
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
	bar:SetScript("OnEvent", bar.UpdateBar)
	bar:RegisterEvents()
	
	bar:SetBarColor(module:RGBA(dataProvider))
	bar:UpdateTextVisibility()
	bar:UpdateVisibility()
	bar:UpdateBar()

	return bar
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
	db = module.db.profile --[[@as table]]

	local anchor = CreateFrame("Frame", "LUI_MainExpBar", UIParent)
	anchor:SetPoint(db.Point, UIParent, db.RelativePoint, db.X, db.Y)
	anchor:SetSize(db.Width, db.Height)
	module.anchor = anchor
	
	anchor:SetScript("OnEvent", function() module:UpdateMainBarVisibility() end)

	local expBar = module:CreateBar("LUI_ExpBarsExp", "Experience")
	local repBar = module:CreateBar("LUI_ExpBarsRep", "Reputation")
	local honorBar = module:CreateBar("LUI_ExpBarsHonor", "Honor")
	local azeriteBar = module:CreateBar("LUI_ExpBarsAzerite", "Azerite")
	local houseFavorBar = module:CreateBar("LUI_ExpBarsHouseFavor", "HouseFavor")
	mainBarList = {expBar, repBar, honorBar, azeriteBar, houseFavorBar}

	for bar in module:IterateMainBars() do
		bar:SetPoint("RIGHT", anchor, "RIGHT")
	end

	module.ExperienceBar = expBar
	module.ReputationBar = repBar
	module.HonorBar = honorBar
	module.AzeriteBar = azeriteBar
	module.HouseFavorBar = houseFavorBar

	return true -- mainBarsCreated
end

function module:UpdateMainBarVisibility()
	local barLeft, barRight
	if not module.ExperienceBar or not module.ReputationBar
		or not module.HonorBar or not module.AzeriteBar or not module.HouseFavorBar then
		return
	end
	-- Check which bars can be visible at the moment
	local expShown = module.ExperienceBar:ShouldBeVisible()
	local repShown = module.ReputationBar:ShouldBeVisible()
	local honorShown = module.HonorBar:ShouldBeVisible()
	local apShown = module.AzeriteBar:ShouldBeVisible()
	local houseFavorShown = module.HouseFavorBar:ShouldBeVisible()
	
	-- Decide which bars should be ultimately shown.
	if houseFavorShown then
		barRight = module.HouseFavorBar
		if expShown then
			barLeft = module.ExperienceBar
		elseif apShown then
			barLeft = module.AzeriteBar
		elseif honorShown then
			barLeft = module.HonorBar
		elseif repShown then
			barLeft = module.ReputationBar
		end
	elseif expShown then
		barRight = module.ExperienceBar
		if apShown then
			barLeft = module.AzeriteBar
		elseif honorShown then
			barLeft = module.HonorBar
		elseif repShown then
			barLeft = module.ReputationBar
		end
	elseif apShown then
		barRight = module.AzeriteBar
		if honorShown then
			barLeft = module.HonorBar
		elseif repShown then
			barLeft = module.ReputationBar
		end
	elseif honorShown then
		barRight = module.HonorBar
		if repShown then
			barLeft = module.ReputationBar
		end
	elseif repShown then
		barRight = module.ReputationBar
	end
	-- Force the main bars to be hidden.
	for bar in module:IterateMainBars() do
		bar:Hide()
	end

	-- Adjust size and visibility
	if barRight then
		local width = db.Width
		local spacing = db.Spacing
		local textX = db.TextX
		local textY = db.TextY

		barRight:ClearAllPoints()
		barRight:SetReverseFill(false)
		barRight:SetPoint("RIGHT", module.anchor, "RIGHT")
		barRight.text:ClearAllPoints()
		barRight.text:SetPoint("RIGHT", barRight, "RIGHT", textX, textY)
		barRight:Show()
		barRight:UpdateBar()
		if db.SplitTracker and barLeft then
			local halfWidth = (width - spacing) * 0.5
			barRight:SetWidth(halfWidth)
			barLeft:SetWidth(halfWidth)
			barLeft:ClearAllPoints()
			barLeft:SetReverseFill(true)
			barLeft:SetPoint("LEFT", module.anchor, "LEFT")
			barLeft.text:ClearAllPoints()
			barLeft.text:SetPoint("LEFT", barLeft, "LEFT", -textX, textY)
			barLeft:Show()
			barLeft:UpdateBar()
		else
			barRight:SetWidth(width)
		end
	end
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
	if not module.anchor then return end
	module.anchor:ClearAllPoints()
	module.anchor:SetPoint(db.Point, UIParent, db.RelativePoint, db.X, db.Y)
	module.anchor:SetSize(db.Width, db.Height)
	for bar in module:IterateMainBars() do
		bar:SetStatusBarTexture(module:FetchStatusBar("ExpBarFill"))
		bar.bg:SetTexture(module:FetchStatusBar("ExpBarBg"))
		bar.text:SetFont(Media:Fetch("font", db.Fonts.Text.Name), db.Fonts.Text.Size, db.Fonts.Text.Flag)
		bar:UpdateTextVisibility()
		bar:UpdateText()
	end
	module:RefreshColors()
	module:UpdateMainBarVisibility()
end
