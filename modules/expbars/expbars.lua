--[[
	This module handle experience bars of all sorts.
	By default it will serves as an experience bar under the action bars
	This main bar will split off in two if you are watching a reputation or honor.
	[Rep  <--] [-->   XP]

	Honor takes priority over faction reputations.
	If displaying Azerite is enabled, it becomes AP / XP.
	At max level, the XP bar is fully replaced by a rep/honor tracking bar. Hidden if not tracking either of them.
	
	Upcoming new feautre: Letting users create an additional customizable tracking bar.

	This file handles the handling of the bars, XP/Rep data handling should be in their own files.
]]

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)
local L = LUI.L

---@class LUI.ExperienceBars
local module = LUI:GetModule("Experience Bars")
local db

--- Array containing all Data Providers that were loaded
---@type ExpBarDataProvider[]
local dataProviderList = {}

--- Contains all Exp Bars that were created.
---@type ExpBar[]
local barsList = {}

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

--- Boolean function to indicate the data provider has a tooltip when hovering the bar
---@return boolean
function ExpBarDataProviderMixin:HasTooltip()
	return false
end

--- Override this function to fill tooltip text
function ExpBarDataProviderMixin:SetTooltipInfo(tooltip)
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
		local percentBar = self.barValue / self.barMax * 100
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

function ExpBarMixin:SetBarColor(r, g, b)
	local mult = 0.4 -- Placeholder for LUI:GetBGMultiplier
	self:SetStatusBarColor(r, g, b)
	self.bg:SetVertexColor(r * mult, g * mult, b * mult)
end

function ExpBarMixin:RegisterEvents()
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	if not self.BAR_EVENTS then return end
	for i, event in ipairs(self.BAR_EVENTS) do
		self:RegisterEvent(event)
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
	local bar = CreateFrame("StatusBar", name, UIParent)
	bar:SetFrameStrata("HIGH")
	bar:SetSize(db.Width, db.Height)
	bar:SetStatusBarTexture(module:FetchStatusBar("ExpBarFill"))

	local bg = bar:CreateTexture(nil, "BORDER")
	bg:SetTexture(module:FetchStatusBar("ExpBarFill"))
	bg:SetAllPoints(bar)
	bar.bg = bg

	local text = module:SetFontString(bar, name.."Text", "Text", "OVERLAY", "LEFT")
	text:SetPoint("RIGHT", bar, "RIGHT", db.TextX, db.TextY)
	text:SetTextColor(1, 1, 1)
	text:SetShadowColor(0, 0, 0)
	text:SetShadowOffset(1.25, -1.25)
	bar.text = text

	bar.provider = dataProvider
	Mixin(bar, ExpBarMixin, dataProviderList[dataProvider])
	bar:SetScript("OnEvent", bar.UpdateBar)
	bar:RegisterEvents()
	
	bar:SetBarColor(module:RGB("Experience"))
	bar:UpdateTextVisibility()
	bar:UpdateVisibility()
	bar:UpdateBar()

	tinsert(barsList, bar)
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
	
	anchor:RegisterEvent("PLAYER_ENTERING_WORLD");
	anchor:RegisterEvent("UPDATE_EXPANSION_LEVEL");
	anchor:RegisterEvent("UPDATE_FACTION");
	anchor:RegisterEvent("ENABLE_XP_GAIN");
	anchor:RegisterEvent("DISABLE_XP_GAIN");
	anchor:RegisterEvent("ZONE_CHANGED");
	anchor:RegisterEvent("ZONE_CHANGED_NEW_AREA");
	anchor:RegisterUnitEvent("UNIT_LEVEL", "player")
	anchor:SetScript("OnEvent", function() module:UpdateMainBarVisibility() end)
	module:SecureHook(_G.StatusTrackingBarManager, "UpdateBarsShown", "UpdateMainBarVisibility")

	local expBar = module:CreateBar("LUI_ExpBarsExp", "Experience")
	local repBar = module:CreateBar("LUI_ExpBarsRep", "Reputation")
	local honorBar = module:CreateBar("LUI_ExpBarsHonor", "Honor")
	local azeriteBar = module:CreateBar("LUI_ExpBarsAzerite", "Azerite")
	local genesisBar = module:CreateBar("LUI_ExpBarsGenesis", "Genesis") ---@TEST: Genesis
	mainBarList = {expBar, repBar, honorBar, azeriteBar}

	for bar in module:IterateMainBars() do
		bar:SetPoint("RIGHT", anchor, "RIGHT")
	end

	module.anchor = anchor
	module.ExperienceBar = expBar
	module.ReputationBar = repBar
	module.HonorBar = honorBar
	module.AzeriteBar = azeriteBar
	module.GenesisBar = genesisBar ---@TEST: Genesis

	return true -- mainBarsCreated
end

function module:UpdateMainBarVisibility()
	local barLeft, barRight

	-- Check which bars can be visible at the moment
	local expShown = module.ExperienceBar:ShouldBeVisible()
	local repShown = module.ReputationBar:ShouldBeVisible()
	local honorShown = module.HonorBar:ShouldBeVisible()
	local apShown = module.AzeriteBar:ShouldBeVisible()
	local gnShown = module.GenesisBar:ShouldBeVisible()
	
	-- Decide which bars should be ultimately shown.
	if expShown then
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
	if gnShown then barRight = module.GenesisBar end

	-- Force the main bars to be hidden.
	for bar in module:IterateMainBars() do
		bar:Hide()
	end

	-- Adjust size and visibility
	if barRight then
		--- HACK: This is a hack to provide default values in the rare cases where the UI makes some calls to the EXP bar before everything is loaded.
		local width = db.Width or 475
		local spacing = db.Spacing or 10
		local textX = db.TextX or -2
		local textY = db.TextY or 0

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
		bar:SetBarColor(module:RGB("Experience"))
	end
end

function module:Refresh()
	module.anchor:SetPoint(db.Point, UIParent, db.RelativePoint, db.X, db.Y)
	module.anchor:SetSize(db.Width, db.Height)
	for bar in module:IterateMainBars() do
		bar:SetStatusBarTexture(module:FetchStatusBar("ExpBarFill"))
		bar.bg:SetTexture(module:FetchStatusBar("ExpBarFill"))
		bar:UpdateTextVisibility()
		bar:UpdateText()
	end
	module:UpdateMainBarVisibility()
end
