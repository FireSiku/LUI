--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: threat.lua
	Description: LUI Threat Bar
]]

local addonname, LUI = ...
local module = LUI:Module("Threat")
local oUFmodule = LUI:Module("Unitframes")
local Media = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists

local db, dbd
local LUIThreat

LUI.Versions.threatbar = 2.0

local fontflags = {"OUTLINE", "THICKOUTLINE", "MONOCHROME", "NONE"}
local positions = { "TOP", "TOPRIGHT", "TOPLEFT", "BOTTOM", "BOTTOMRIGHT", "BOTTOMLEFT", "RIGHT", "LEFT", "CENTER"}

local _, class = UnitClass("player")

local aggrocolors = {0, 1, 0, 1, 1, 0, 1, 0, 0}

local ToggleTestMode = function()
	if LUIThreat.Testmode then
		LUIThreat.Testmode = nil
		LUIThreat:Hide()
	else
		LUIThreat.Testmode = true
		LUIThreat:Show()
		LUIThreat:SetAlpha(1)
		LUIThreat:SetMinMaxValues(0, 110)
		LUIThreat:SetValue(75)
	end
end

local UpdateExpMode = function()
	local bar = LUIThreat
	local currXP = UnitXP("player")
	local maxXP = UnitXPMax("player")
	local percentXP = currXP * 100 / maxXP
	bar:SetValue(percentXP)
	if db.Text.Enable then
		bar.Text:SetFormattedText("%d%%", percentXP)
	end
	if UnitLevel("player") == 90 then
		local name, stand, barMin, barMax, barValue = GetWatchedFactionInfo()
		local repname = { "Ha", "Ho", "Un", "Ne", "Fr", "Hon", "Rev", "Ex" }
		if not name then bar:Hide()
		else if db.Enable then bar:Show() end
		end
		barMax = barMax - barMin
		barValue = barValue - barMin
		barMin = 0
		local percentRep = barValue * 100 / barMax
		bar:SetMinMaxValues(barMin,barMax)
		bar:SetValue(barValue)
		if db.Text.Enable then
			bar.Text:SetFormattedText("%d%% %s", percentRep,repname[stand] or "")
		end
	end
end

local ToggleExpMode = function()
	if LUIThreat.expMode or IsXPUserDisabled() then
		LUIThreat.expMode = nil
		LUIThreat:Hide()
		LUIThreat:RegisterEvent("PLAYER_REGEN_ENABLED")
		LUIThreat:RegisterEvent("PLAYER_REGEN_DISABLED")
		LUIThreat:UnregisterEvent("PLAYER_XP_UPDATE")
	else
		LUIThreat:UnregisterEvent("PLAYER_REGEN_ENABLED")
		LUIThreat:UnregisterEvent("PLAYER_REGEN_DISABLED")
		LUIThreat:RegisterEvent("PLAYER_XP_UPDATE")
		LUIThreat:RegisterEvent("UPDATE_FACTION")
		LUIThreat.expMode = true
		LUIThreat:Show()
		LUIThreat:SetAlpha(1)
		LUIThreat:SetMinMaxValues(0, 100)
		LUIThreat.indicator:Hide()

		UpdateExpMode()
	end
end

local Update = function(bar)
	if bar.Testmode then return end
	if db.General.expMode then return end

	if not db.General.expMode then
		if db.General.TankHide and LUIVengeance and LUIVengeance:IsShown() then
			bar:SetAlpha(0)
			return
		end
		
		if not UnitAffectingCombat("target") or not UnitCanAttack("player", "target") then
			bar:SetAlpha(0)
			return
		end
	end
	
	bar:SetAlpha(1)
	
	local hasaggro, _, threat, rawthreat = UnitDetailedThreatSituation("player", "target")
	
	if not threat then return end
	if not rawthreat then return end
	
	if hasaggro then -- tanking
		bar:SetMinMaxValues(0, 100)
		bar.helper:SetMinMaxValues(0, 100)
		bar:SetValue(100)
	elseif rawthreat / threat < 1.2 then -- melee
		bar:SetMinMaxValues(0, 110)
		bar.helper:SetMinMaxValues(0, 110)
		bar:SetValue(rawthreat)
	else -- range
		bar:SetMinMaxValues(0, 130)
		bar.helper:SetMinMaxValues(0, 130)
		bar:SetValue(rawthreat)
	end
	
	if db.Appearance.Color == "Gradient" then
		local r, g, b = oUF.ColorGradient(threat, 100, 0, 1, 0, 1, 1, 0, 1, 0, 0)
		local mu = db.Appearance.BGMultiplier or 0
		bar:SetStatusBarColor(r, g, b)
		if bar.bg then bar.bg:SetVertexColor(r * mu, g * mu, b * mu) end
	end
				
	if db.Text.Enable then
		bar.Text:SetFormattedText("%d%%", rawthreat)
	end
	
	if db.Text.Color == "Gradient" then
		bar.Text:SetTextColor(oUF.ColorGradient(threat, 100, 0, 1, 0, 1, 1, 0, 1, 0, 0))
	end
end

local SetThreat = function()
	if LUIThreat then return end
	
	LUIThreat = CreateFrame("StatusBar", "LUIThreat", UIParent)
	LUIThreat:SetFrameStrata("HIGH")
	
	LUIThreat.bg = LUIThreat:CreateTexture(nil, "BORDER")
	LUIThreat.bg:SetAllPoints(LUIThreat)
	
	LUIThreat.Text = LUIThreat:CreateFontString("LUIThreatText", "OVERLAY")
	LUIThreat.Text:SetJustifyH("LEFT")
	LUIThreat.Text:SetShadowColor(0, 0, 0)
	LUIThreat.Text:SetShadowOffset(1.25, -1.25)
	
	LUIThreat.helper = CreateFrame("StatusBar", nil, LUIThreat)
	LUIThreat.helper:SetAllPoints(LUIThreat)
	LUIThreat.helper:SetFrameLevel(LUIThreat:GetFrameLevel() - 1)
	LUIThreat.helper:SetMinMaxValues(0, 100)
	LUIThreat.helper:SetValue(100)
	LUIThreat.helper:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	
	LUIThreat.indicator = LUIThreat:CreateTexture(nil, "OVERLAY")
	LUIThreat.indicator:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
	LUIThreat.indicator:SetVertexColor(1, 1, 1, .75)
	LUIThreat.indicator:SetBlendMode("ADD")
	LUIThreat.indicator:SetHeight(LUIThreat:GetHeight() * 1.5)
	LUIThreat.indicator:SetWidth(LUIThreat:GetHeight())
	LUIThreat.indicator:SetPoint("CENTER", LUIThreat.helper:GetStatusBarTexture(), "RIGHT", 0, 0)
	LUIThreat.indicator:Show()
	
	LUIThreat:SetScript("OnEvent", function(self, event)

		if event == "PLAYER_REGEN_ENABLED" then
			self:Hide()
 		elseif event == "PLAYER_REGEN_DISABLED" then
			self:Show()
			if self.Testmode then
				self.Testmode = nil
				LUI:Print("Threatbar Testmode disabled due to combat.")
			end
		elseif event == "PLAYER_XP_UPDATE" or event == "UPDATE_FACTION" then
			UpdateExpMode()
		end
	end)
end

module.defaults = {
	profile = {
		Enable = true,
		General = {
			Width = 384,
			Height = 10,
			X = 0,
			Y = 6,
			Point = "BOTTOM",
			TankHide = true,
			expMode = false,
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
			Enable = true,
			X = 170,
			Y = 0,
			Font = "Prototype",
			Size = 14,
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

module.optionsName = "Threat Bar"
module.getter = "generic"
module.setter = "Refresh"

function module:LoadOptions()
	local disabledTextFunc = function() return not db.Text.Enable end
	local colorOptions = {"By Class", "Individual", "Gradient"}
	local dryCall = function() self:Refresh() end
	
	local options = {
		General = self:NewGroup("General", 1, {
			header = self:NewHeader("General Options", 0),
			[""] = self:NewPosSliders("Threat Bar", 1, nil, "LUIThreat", true),
			Point = self:NewSelect("Point", "Choose the Point for your Threat Bar.", 2, positions, nil, dryCall),
			empty1 = self:NewDesc(" ", 3),
			Width = self:NewInputNumber("Width", "Choose the Width for your Threat Bar.", 4, dryCall),
			Height = self:NewInputNumber("Height", "Choose the Height for your Threat Bar.", 5, dryCall),
			empty2 = self:NewDesc(" ", 6),
			TankHide = self:NewToggle("Hide if Tanking", "Whether you want to hide the Threat Bar if you are tank specced or not.\nOnly works if Vengeance Module is enabled!.", 7, true),
			expMode = self:NewToggle("Switch to Exp Mode", "If enabled, this will turn your Threat Bar into an experience bar.\nIf you are level 90 it will show a reputation bar instead.\nDisable Threat.",8,ToggleExpMode),
			empty3 = self:NewDesc(" ", 9),
			Testmode = self:NewExecute("Testmode", "Enable/Disable Threat Bar Testmode", 10, ToggleTestMode),
		}),
		Appearance = self:NewGroup("Appearance", 2, {
			header = self:NewHeader("Appearance Options", 0),
			Texture = self:NewSelect("Texture", "Choose the Texture for your Threat Bar.", 1, widgetLists.statusbar, "LSM30_Statusbar", true),
			BGTexture = self:NewSelect("Background Texture", "Choose the Background Texture for your Threat Bar.", 2, widgetLists.statusbar, "LSM30_Statusbar", true),
			BGMultiplier = self:NewSlider("Background Multiplier", "Choose the Multiplier for your Background Color.", 3, 0, 1, 0.01, true, true),
			empty1 = self:NewDesc(" ", 4),
			Color = self:NewSelect("Color", "Choose the Color Option for your Threat Bar.", 5, colorOptions, nil, dryCall),
			IndividualColor = self:NewColorNoAlpha("Individual", "Threat Bar", 6, dryCall, nil, function() return db.Appearance.Color ~= "Individual" end),
		}),
		Text = self:NewGroup("Text", 3, {
			header = self:NewHeader("Text Options", 0),
			Enable = self:NewToggle("Enable Text", "Whether you want to show a Text on your Threat Bar or not.", 1, true),
			empty1 = self:NewDesc(" ", 2),
			[""] = self:NewPosSliders("Threat Bar Text", 3, nil, "LUIThreatText", true, nil, disabledTextFunc),
			Font = self:NewSelect("Font", "Choose the Font for your Threat Bar Text.", 4, widgetLists.font, "LSM30_Font", true, nil, disabledTextFunc),
			Size = self:NewInputNumber("Fontsize", "Choose the Fontsize for your Threat Bar Text.", 5, dryCall, nil, disabledTextFunc),
			Outline = self:NewSelect("Font Flag", "Choose the Font Flag for the Threat Bar Text Font.", 6, fontflags, nil, dryCall, nil, disabledTextFunc),
			empty2 = self:NewDesc(" ", 7),
			Color = self:NewSelect("Color", "Choose the Color option for your Threat Bar Text.", 8, colorOptions, nil, dryCall, nil, disabledTextFunc),
			IndividualColor = self:NewColorNoAlpha("Individual", "Threat Bar Text", 9, dryCall, nil, function() return not db.Text.Enable or db.Text.Color ~= "Individual" end),
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
	elseif db.Appearance.Color == "Individual" then
		r, g, b = db.Appearance.IndividualColor.r, db.Appearance.IndividualColor.g, db.Appearance.IndividualColor.b
	end
	
	LUIThreat:SetWidth(LUI:Scale(db.General.Width))
	LUIThreat:SetHeight(LUI:Scale(db.General.Height))
	LUIThreat:ClearAllPoints()
	LUIThreat:SetPoint(db.General.Point, UIParent, db.General.Point, LUI:Scale(db.General.X), LUI:Scale(db.General.Y))
	LUIThreat:SetStatusBarTexture(Media:Fetch("statusbar", db.Appearance.Texture))
	if r then LUIThreat:SetStatusBarColor(r, g, b) end
	
	LUIThreat.bg:SetTexture(Media:Fetch("statusbar", db.Appearance.TextureBG))
	if r then LUIThreat.bg:SetVertexColor(r * mu, g * mu, b * mu) end
	
	if db.Text.Color == "By Class" then
		r, g, b = unpack(oUFmodule.colors.class[class])
	elseif db.Text.Color == "Individual" then
		r, g, b = db.Text.IndividualColor.r, db.Text.IndividualColor.g, db.Text.IndividualColor.b
	else
		r, g, b = nil, nil, nil
	end
	
	LUIThreat.Text:SetFont(Media:Fetch("font", db.Text.Font), db.Text.Size, db.Text.Outline)
	LUIThreat.Text:ClearAllPoints()
	LUIThreat.Text:SetPoint("CENTER", LUIThreat, "CENTER", LUI:Scale(db.Text.X), LUI:Scale(db.Text.Y))
	if r then LUIThreat.Text:SetTextColor(r, g, b) end
	
	if db.Text.Enable then
		LUIThreat.Text:Show()
	else
		LUIThreat.Text:Hide()
	end
end

function module:OnInitialize()
	db, dbd = LUI:NewNamespace(self, true)
	
	if LUICONFIG.Versions.threatbar ~= LUI.Versions.threatbar then
		db:ResetProfile()
		LUICONFIG.Versions.threatbar = LUI.Versions.threatbar
	end
end

function module:OnEnable()
	SetThreat()
	self:Refresh()
	
	LUIThreat:RegisterEvent("PLAYER_REGEN_ENABLED")
	LUIThreat:RegisterEvent("PLAYER_REGEN_DISABLED")
	LUIThreat:SetScript("OnUpdate", Update)
	LUIThreat:Hide()
	if db.General.expMode then ToggleExpMode() end
end

function module:OnDisable()
	LUIThreat:UnregisterAllEvents()
	LUIThreat:SetScript("OnUpdate", nil)
	LUIThreat:Hide()
end
