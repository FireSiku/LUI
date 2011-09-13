--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: vengeance.lua
	Description: LUI Vengeance Bar
]]

local addonname, LUI = ...
local module = LUI:Module("Vengeance")
local oUFmodule = LUI:Module("Unitframes")
local Media = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists

local fontflags = {"OUTLINE", "THICKOUTLINE", "MONOCHROME", "NONE"}
local positions = { "TOP", "TOPRIGHT", "TOPLEFT", "BOTTOM", "BOTTOMRIGHT", "BOTTOMLEFT", "RIGHT", "LEFT", "CENTER"}

local _, class = UnitClass("player")

local db, dbd
local LUIVengeance

local vengeance = GetSpellInfo(93098)

LUI.Versions.vengeance = 2.0

local ToggleTestMode = function()
	if LUIVengeance.Testmode then
		LUIVengeance.Testmode = nil
		LUIVengeance:Hide()
	else
		LUIVengeance.Testmode = true
		LUIVengeance:Show()
		LUIThreat:SetMinMaxValues(0, 100)
		LUIThreat:SetValue(50)
	end
end

local ValueChanged = function(bar, event, unit)
	if unit and unit ~= "player" then return end
	
	if not bar.isTank then
		bar:Hide()
		return
	end
	
	local value = select(14, UnitAura("player", vengeance, nil, "PLAYER|HELPFUL"))

	if value and value > 0 then
		if value > bar.max then value = bar.max end
		if value == bar.value then return end
			
		bar:SetMinMaxValues(0, bar.max)
		bar:SetValue(value)
		bar.value = value
		bar:Show()
	elseif InCombatLockdown() then
		bar:Show()
		bar:SetMinMaxValues(0, 1)
		bar:SetValue(0)
		bar.value = 0
	else
		bar:Hide()
		bar.value = 0
	end
			
	if db.Text.Enable then
		if db.Text.Format == "Absolut" then
			bar.Text:SetFormattedText("%d/%d", bar.value, mbar.max)
		else
			bar.Text:SetFormattedText("%d", bar.value)
		end
	else
		bar.Text:SetText()
	end
end

local BaseChanged = function(bar, event, unit)
	if unit and unit ~= "player" then return end
	
	if not bar.isTank then
		bar:Hide()
		return
	end
	
	local health = UnitHealthMax("player")
	local _, stamina = UnitStat("player", 3)
	
	bar.base = (health - 15 * stamina) * .1
	bar.max = bar.base + bar.stam
	bar:SetMinMaxValues(0, bar.max)
	
	ValueChanged(bar, event, unit)
end

local StamChanged = function(bar, event, unit)
	if unit and unit ~= "player" then return end
	
	if not bar.isTank then
		bar:Hide()
		return
	end
	
	local health = UnitHealthMax("player")
	local _, stamina = UnitStat("player", 3)
	
	if not health or not stamina then return end
	
	bar.stam = stamina
	bar.max = bar.base + bar.stam
	bar:SetMinMaxValues(0, bar.max)
	
	ValueChanged(bar, event, unit)
end

local IsTank = function(bar, event)
	local masteryIndex = GetPrimaryTalentTree()
	
	if masteryIndex then
		if class == "DRUID" and masteryIndex == 2 then
			bar.isTank = true
		elseif (class == "DEATH KNIGHT" or class == "DEATHKNIGHT") and masteryIndex == 1 then
			bar.isTank = true
		elseif class == "PALADIN" and masteryIndex == 2 then
			bar.isTank = true
		elseif class == "WARRIOR" and masteryIndex == 3 then
			bar.isTank = true
		else
			bar.isTank = false
			bar:Hide()
		end
	else
		bar.isTank = false
		bar:Hide()
	end
	
	StamChanged(bar, event, "player")
	BaseChanged(bar, event, "player")
end

local SetVengeance = function()
	if LUIVengeance then return end
	
	LUIVengeance = CreateFrame("StatusBar", "LUIVengeance", UIParent)
	
	LUIVengeance.bg = LUIVengeance:CreateTexture(nil, "BORDER")
	LUIVengeance.bg:SetAllPoints(LUIVengeance)
	
	LUIVengeance.Text = LUIVengeance:CreateFontString(nil, "OVERLAY")
	LUIVengeance.Text:SetJustifyH("LEFT")
	LUIVengeance.Text:SetShadowColor(0, 0, 0)
	LUIVengeance.Text:SetShadowOffset(1.25, -1.25)
	
	LUIVengeance:SetScript("OnEvent", function(self, event, ...)
		if self.Testmode then
			if event == "PLAYER_REGEN_DISABLED" then
				self.Testmode = nil
				LUI:Print("Vengeance Testmode disabled due to combat.")
			else
				return
			end
		end
		
		if event == "UNIT_AURA" then
			ValueChanged(self, event, ...)
		elseif event == "UNIT_MAXHEALTH" then
			StamChanged(self, event, ...)
		elseif event == "UNIT_LEVEL" or event == "ACTIVE_TALENT_GROUP_CHANGED" then
			StamChanged(self, event, ...)
			BaseChanged(self, event, ...)
		elseif event == "PLAYER_REGEN_DISABLED" then
			IsTank(self, event, ...)
		end
	end)
end

module.defaults = {
	profile = {
		Enable = true,
		General = {
			Width = 384,
			Height = 4,
			X = 0,
			Y = 12,
			Point = "BOTTOM",
		},
		Appearance = {
			Texture = "LUI_Gradient",
			BGTexture = "LUI_Minimalist",
			BGMultiplier = 0.4,
			Color = "By Class",
			IndividualColor = {
				r = 1,
				g = 1,
				b = 1,
			},
		},
		Text = {
			Enable = false,
			X = 0,
			Y = 0,
			Font = "neuropol",
			Size = 10,
			Outline = "NONE",
			Color = "Individual",
			IndividualColor = {
				r = 1,
				g = 1,
				b = 1,
			},
		},
	}
}

module.optionsName = "Vengeance Bar"
module.getter = "generic"
module.setter = "Refresh"

function module:LoadOptions()
	local disabledTextFunc = function() return not db.Text.Enable end
	local colorOptions = {"By Class", "Individual", "Gradient"}
	local dryCall = function() self:Refresh() end
	
	local options = {
		General = self:NewGroup("General", 1, {
			header = self:NewHeader("General Options", 0),
			[""] = self:NewPosSliders("Vengeance Bar", 1, nil, "LUIThreat", true),
			Point = self:NewSelect("Point", "Choose the Point for your Vengeance Bar.", 2, positions, nil, dryCall),
			empty1 = self:NewDesc(" ", 3),
			Width = self:NewInputNumber("Width", "Choose the Width for your Vengeance Bar.", 3, dryCall),
			Height = self:NewInputNumber("Height", "Choose the Height for your Vengeance Bar.", 4, dryCall),
			empty2 = self:NewDesc(" ", 5),
			Testmode = self:NewExecute("Testmode", "Enable/Disable Vengeance Bar Testmode", 6, ToggleTestMode),
		}),
		Appearance = self:NewGroup("Appearance", 2, {
			header = self:NewHeader("Appearance Options", 0),
			Texture = self:NewSelect("Texture", "Choose the Texture for your Vengeance Bar.", 1, widgetLists.statusbar, "LSM30_Statusbar", true),
			BGTexture = self:NewSelect("Background Texture", "Choose the Background Texture for your Vengeance Bar.", 2, widgetLists.statusbar, "LSM30_Statusbar", true),
			BGMultiplier = self:NewSlider("Background Multiplier", "Choose the Multiplier for your Background Color.", 3, 0, 1, 0.01, true, true),
			empty1 = self:NewDesc(" ", 4),
			Color = self:NewSelect("Color", "Choose the Color Option for your Vengeance Bar.", 4, colorOptions, nil, dryCall),
			IndividualColor = self:NewColorNoAlpha("Individual", "Vengeance Bar", 5, dryCall, nil, function() return db.Appearance.Color ~= "Individual" end),
		}),
		Text = self:NewGroup("Text", 3, {
			header = self:NewHeader("Text Options", 0),
			Enable = self:NewToggle("Enable Text", "Whether you want to show a Text on your Vengeance Bar or not.", 1, true),
			empty1 = self:NewDesc(" ", 4),
			[""] = self:NewPosSliders("Vengeance Bar Text", 2, nil, "LUIThreatText", true, nil, disabledTextFunc),
			Font = self:NewSelect("Font", "Choose the Font for your Vengeance Bar Text.", 3, widgetLists.font, "LSM30_Font", true, nil, disabledTextFunc),
			Size = self:NewInputNumber("Fontsize", "Choose the Fontsize for your Vengeance Bar Text.", 4, dryCall, nil, disabledTextFunc),
			Outline = self:NewSelect("Font Flag", "Choose the Font Flag for the Vengeance Bar Text Font.", 5, fontflags, nil, dryCall, nil, disabledTextFunc),
			empty2 = self:NewDesc(" ", 6),
			Color = self:NewSelect("Color", "Choose the Color option for your Vengeance Bar Text.", 6, colorOptions, nil, dryCall, nil, disabledTextFunc),
			IndividualColor = self:NewColorNoAlpha("Individual", "Vengeance Bar Text", 7, dryCall, nil, function() return not db.Text.Enable or db.Text.Color ~= "Individual" end),
		}),
	}
	
	return options
end

function module:Refresh(...)
	local info, value = ...
	if type(info) == "table" then
		db(info, value)
	end
	
	local r, g, b
	local mu = db.Appearance.BGMultiplier
	if db.Appearance.Color == "By Class" then
		r, g, b = unpack(oUFmodule.colors.class[class])
	else
		r, g, b = db.Appearance.IndividualColor.r, db.Appearance.IndividualColor.g, db.Appearance.IndividualColor.b
	end
	
	LUIVengeance:SetWidth(LUI:Scale(db.General.Width))
	LUIVengeance:SetHeight(LUI:Scale(db.General.Height))
	LUIVengeance:ClearAllPoints()
	LUIVengeance:SetPoint(db.General.Point, UIParent, db.General.Point, LUI:Scale(db.General.X), LUI:Scale(db.General.Y))
	LUIVengeance:SetStatusBarTexture(Media:Fetch("statusbar", db.Appearance.Texture))
	LUIVengeance:SetStatusBarColor(r, g, b)
	
	LUIVengeance.bg:SetTexture(Media:Fetch("statusbar", db.Appearance.TextureBG))
	LUIVengeance.bg:SetVertexColor(r * mu, g * mu, b * mu)
	
	if db.Text.Color == "By Class" then
		r, g, b = unpack(oUFmodule.colors.class[class])
	else
		r, g, b = db.Text.IndividualColor.r, db.Text.IndividualColor.g, db.Text.IndividualColor.b
	end
	
	LUIVengeance.Text:SetFont(Media:Fetch("font", db.Text.Font), db.Text.Size, db.Text.Outline)
	LUIVengeance.Text:ClearAllPoints()
	LUIVengeance.Text:SetPoint("CENTER", LUIVengeance, "CENTER", LUI:Scale(db.Text.X), LUI:Scale(db.Text.Y))
	LUIVengeance.Text:SetTextColor(r, g, b)
	
	if db.Text.Enable then
		LUIVengeance.Text:Show()
	else
		LUIVengeance.Text:Hide()
	end
end

function module:OnInitialize()
	db, dbd = LUI:NewNamespace(self, true)
	
	if LUICONFIG.Versions.vengeance ~= LUI.Versions.vengeance then
		db:ResetProfile()
		LUICONFIG.Versions.vengeance = LUI.Versions.vengeance
	end
end

function module:OnEnable()
	SetVengeance()
	self:Refresh()
	
	LUIVengeance.max = 0
	LUIVengeance.value = 0
	LUIVengeance.stam = 0
	LUIVengeance.base = 0
	
	LUIVengeance:RegisterEvent("UNIT_AURA")
	LUIVengeance:RegisterEvent("UNIT_MAXHEALTH")
	LUIVengeance:RegisterEvent("UNIT_LEVEL")	
	LUIVengeance:RegisterEvent("PLAYER_REGEN_DISABLED")
	
	LUIVengeance:Hide()
end

function module:OnDisable()
	LUIVengeance:UnregisterAllEvents()
	LUIVengeance:Hide()
end
