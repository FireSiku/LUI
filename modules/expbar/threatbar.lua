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

local LEVEL_CAP = MAX_PLAYER_LEVEL
local C_AzeriteItem = C_AzeriteItem

LUI.Versions.threatbar = 2.0

local fontflags = {"OUTLINE", "THICKOUTLINE", "MONOCHROME", "NONE"}
local positions = { "TOP", "TOPRIGHT", "TOPLEFT", "BOTTOM", "BOTTOMRIGHT", "BOTTOMLEFT", "RIGHT", "LEFT", "CENTER"}

local _, class = UnitClass("player")

local aggrocolors = {0, 1, 0, 1, 1, 0, 1, 0, 0}

local PRECISION_FORMAT = {
	[0] = "%.0f%%",
	[1] = "%.1f%%",
	[2] = "%.2f%%",
	[3] = "%.3f%%",
}

-- function to short-display HP value on StatusBar
local function ShortValue(value)
	if value >= 1e7 then
		return ('%.1fm'):format(value / 1e6):gsub('%.?0+([km])$', '%1')
	elseif value >= 1e6 then
		return ('%.2fm'):format(value / 1e6):gsub('%.?0+([km])$', '%1')
	elseif value >= 1e5 then
		return ('%.1fk'):format(value / 1e3)
	elseif value >= 1e4 then
		return ('%.2fk'):format(value / 1e3):gsub('%.?0+([km])$', '%1')
	else
		return value
	end
end

local function ToggleTestMode()
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

local function UpdateExpMode()
	local bar = LUIThreat
	local bar2 = LUIThreat.artifact
	local width = bar:GetWidth()
	local left, percentBar, percentBar2
	local precision = db.Text.Precision or 0
	if UnitLevel("player") ~= LEVEL_CAP and not IsXPUserDisabled() then -- EXP MODE
		local restXP = GetXPExhaustion() or 0
		local currXP = UnitXP("player")
		local maxXP = UnitXPMax("player")
		percentBar = currXP * 100 / maxXP
		local percentRE = restXP * 100 / maxXP
		bar:SetValue(percentBar)
		if db.General.showRested then
			local left = width / 100 * percentBar
			if ( percentBar + percentRE > 100 ) then
				right = width - left
			else
				right = width / 100 * percentRE
			end
			if right == 0 then
				bar.rested:Hide()
			else
				if not bar.rested:IsShown() then
					bar.rested:Show()
				end
				bar.rested:SetPoint("TOPLEFT", LUIThreat, left, 0)
				bar.rested:SetSize(right, LUIThreat:GetHeight())
			end
		end
		if db.Text.Enable then
			if percentRE ~= 0 and db.General.showRested then
				local txtformat = string.format("%s (R: %s)", PRECISION_FORMAT[precision], PRECISION_FORMAT[precision])
				bar.Text:SetFormattedText(txtformat, percentBar, percentRE)
			elseif db.General.ShowAbsolute then
				bar.Text:SetFormattedText(PRECISION_FORMAT[precision].." (%s / %s)" , percentBar, ShortValue(currXP), ShortValue(maxXP))
			else
				bar.Text:SetFormattedText(PRECISION_FORMAT[precision], percentBar)
			end
		end
	else -- REP MODE
		local name, stand, barMin, barMax, barValue, factionID = GetWatchedFactionInfo()

		local repname = { "Ha", "Ho", "Un", "Ne", "Fr", "Hon", "Rev", "Ex" }
		local repText = repname[stand]
		if name and db.Enable then
			--Friendship Support
			local friend, friendValue, _, _, _, _, friendText, friendMin, friendMax = GetFriendshipReputation(factionID);
			if friend ~= nil then -- Friendship support
				--if you're maxed, friendMax will be nil, and value will contain max.
				barMin, barMax, barValue = friendMin, friendMax or friendValue, friendValue
				repText = friendText
			end
			-- Display values
			if C_Reputation.IsFactionParagon(factionID) and barMin == barMax then
				local currentValue, rewardThreshold, _, rewardPending = C_Reputation.GetFactionParagonInfo(factionID)
				barMin = 0
				barValue =  ( currentValue - rewardThreshold ) % rewardThreshold
				barMax = rewardThreshold
				percentBar = barValue / 100
				repText = (rewardPending) and "Pa+1" or "Pa"
			elseif barMin == barMax then
				barMin, barMax, barValue = 0, 1, 1
				percentBar = 100
			else
				barMax = barMax - barMin
				barValue = barValue - barMin
				barMin = 0
				percentBar = barValue * 100 / barMax
			end
			bar:SetMinMaxValues(barMin,barMax)
			bar:SetValue(barValue)
			
			if db.Text.Enable and db.General.ShowAbsolute then
				bar.Text:SetFormattedText(PRECISION_FORMAT[precision].." %s (%s / %s)", percentBar, repText or "", ShortValue(barValue), ShortValue(barMax))
			elseif db.Text.Enable then
				bar.Text:SetFormattedText(PRECISION_FORMAT[precision].." %s", percentBar, repText or "")
			end
			bar:Show()
			bar.rested:Hide()
		else bar:Hide()
		end
	end

	--ARTIFACT MODE
	if db.General.artifact and C_AzeriteItem.HasActiveAzeriteItem() then
		local itemLocation = C_AzeriteItem.FindActiveAzeriteItem()
		if itemLocation then

			local xp, totalXP = C_AzeriteItem.GetAzeriteItemXPInfo(itemLocation)
			--local xpNextPoint = totalXP - xp, ShowAbsolute

			percentBar2 = xp * 100 / totalXP
			bar2:SetMinMaxValues(0, totalXP)
			bar2:SetValue(xp)
			if db.General.ShowAbsolute then
				bar2.Text:SetFormattedText("%."..precision.."f%% AP (%s / %s)" , percentBar2, ShortValue(xp), ShortValue(totalXP))
			else
				bar2.Text:SetFormattedText("%."..precision.."f%% AP" , percentBar2)
			end
			bar2:Show()
		else
			bar2:Hide()
		end
	else
		bar2:Hide()
	end

	if not percentBar or percentBar == -math.huge then
		percentBar = 0
	end
	if not percentBar2 or percentBar2 == -math.huge then
		percentBar2 = 0
	end

	if not bar:IsShown() and not bar2:IsShown() then
		-- Do nothing
	elseif bar:IsShown() and bar2:IsShown() then
		local halfWidth = (LUI:Scale(db.General.Width) - 10) * 0.5
		bar:SetWidth(halfWidth)
		bar2:SetWidth(halfWidth)
		bar.rested:SetWidth(halfWidth)
		bar:ClearAllPoints()
		bar2:ClearAllPoints()
		bar.rested:ClearAllPoints()
		bar:SetPoint("RIGHT", module.anchor, "RIGHT", 0, 0)
		bar2:SetPoint("LEFT", module.anchor, "LEFT", 0, 0)
		bar.rested:SetPoint("RIGHT", module.anchor, "RIGHT", 0, 0)
		bar2:SetReverseFill(true)
		bar2.Text:ClearAllPoints()
		bar2.Text:SetPoint("LEFT", bar2, "LEFT", -LUI:Scale(db.Text.X), LUI:Scale(db.Text.Y))
	elseif bar:IsShown() and not bar2:IsShown() then
		bar:SetWidth(LUI:Scale(db.General.Width))
		bar:SetAllPoints(module.anchor)
	elseif not bar:IsShown() and bar2:IsShown() then
		bar2:SetWidth(LUI:Scale(db.General.Width))
		bar:ClearAllPoints()
		bar2:SetAllPoints(module.anchor)
		bar2:SetReverseFill(false)
		bar2.Text:ClearAllPoints()
		bar2.Text:SetPoint("RIGHT", bar2, "RIGHT", LUI:Scale(db.Text.X), LUI:Scale(db.Text.Y))
	end

	module.anchor:SetSize(LUI:Scale(db.General.Width), LUI:Scale(db.General.Height))
	module.anchor:ClearAllPoints()
	module.anchor:SetPoint(db.General.Point, UIParent, db.General.Point, LUI:Scale(db.General.X), LUI:Scale(db.General.Y))

	if db.Appearance.Color == "Gradient" then
		local r, g, b = oUF.ColorGradient((100 - percentBar), 100, 0, 1, 0, 1, 1, 0, 1, 0, 0)
		local r2, g2, b2 = oUF.ColorGradient((100 - percentBar2), 100, 0, 1, 0, 1, 1, 0, 1, 0, 0)
		local mu = db.Appearance.BGMultiplier or 0
		bar:SetStatusBarColor(r, g, b)
		if bar.bg then bar.bg:SetVertexColor(r * mu, g * mu, b * mu) end
		bar2:SetStatusBarColor(r2, g2, b2)
		if bar2.bg then bar2.bg:SetVertexColor(r2 * mu, g2 * mu, b2 * mu) end
	end
	if db.Text.Color == "Gradient" then
		bar.Text:SetTextColor(oUF.ColorGradient((100 - percentBar), 100, 0, 1, 0, 1, 1, 0, 1, 0, 0))
		bar2.Text:SetTextColor(oUF.ColorGradient((100 - percentBar2), 100, 0, 1, 0, 1, 1, 0, 1, 0, 0))
	end
end

local function ToggleExpMode()
	local bar = LUIThreat
	if bar.expMode or IsXPUserDisabled() then
		bar.expMode = nil
		bar:Hide()
		bar.artifact:Hide()
		bar:RegisterEvent("PLAYER_REGEN_ENABLED")
		bar:RegisterEvent("PLAYER_REGEN_DISABLED")
		bar:UnregisterEvent("PLAYER_XP_UPDATE")
		bar:UnregisterEvent("UPDATE_FACTION")
		bar:UnregisterEvent("UPDATE_EXHAUSTION")
		bar:UnregisterEvent("PLAYER_ENTERING_WORLD")
		bar:UnregisterEvent("AZERITE_ITEM_EXPERIENCE_CHANGED")
		bar:UnregisterEvent("CVAR_UPDATE")
	else
		bar:UnregisterEvent("PLAYER_REGEN_ENABLED")
		bar:UnregisterEvent("PLAYER_REGEN_DISABLED")
		bar:RegisterEvent("PLAYER_XP_UPDATE")
		bar:RegisterEvent("UPDATE_EXHAUSTION")
		bar:RegisterEvent("UPDATE_FACTION")
		bar:RegisterEvent("PLAYER_ENTERING_WORLD")
		bar:RegisterEvent("AZERITE_ITEM_EXPERIENCE_CHANGED")
		bar:RegisterEvent("CVAR_UPDATE")
		bar.expMode = true
		bar:Show()
		bar:SetAlpha(1)
		bar:SetMinMaxValues(0, 100)
		bar.indicator:Hide()
		bar.rested:Show()

		UpdateExpMode()
	end
end

local function Update(bar)
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
	elseif threat > 0 and rawthreat / threat < 1.2 then -- melee
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

local function SetThreat()
	if LUIThreat then return end

	local anchor = CreateFrame("Frame", "LUI_ThreatBarAnchor", UIParent)
	anchor:SetPoint(db.General.Point, UIParent, db.General.Point, LUI:Scale(db.General.X), LUI:Scale(db.General.Y))
	anchor:SetSize(LUI:Scale(db.General.Width), LUI:Scale(db.General.Height))
	module.anchor = anchor
	module.anchor:Show()

	local bar = CreateFrame("StatusBar", "LUIThreat", anchor)
	bar:SetFrameStrata("HIGH")
	bar:SetAllPoints(anchor)

	local bg = bar:CreateTexture(nil, "BORDER")
	bg:SetAllPoints(bar)
	
	local text = bar:CreateFontString("LUIThreatText", "OVERLAY")
	text:SetJustifyH("LEFT")
	text:SetShadowColor(0, 0, 0)
	text:SetShadowOffset(1.25, -1.25)
	
	local helper = CreateFrame("StatusBar", nil, bar)
	helper:SetAllPoints(bar)
	helper:SetFrameLevel(bar:GetFrameLevel() - 1)
	helper:SetMinMaxValues(0, 100)
	helper:SetValue(100)
	helper:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	
	local indicator = bar:CreateTexture(nil, "OVERLAY")
	indicator:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
	indicator:SetVertexColor(1, 1, 1, .75)
	indicator:SetBlendMode("ADD")
	indicator:SetHeight(bar:GetHeight() * 1.5)
	indicator:SetWidth(bar:GetHeight())
	indicator:SetPoint("CENTER", helper:GetStatusBarTexture(), "RIGHT", 0, 0)
	indicator:Show()
	
	local rested = bar:CreateTexture(nil, "OVERLAY")
	rested:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
	rested:SetVertexColor(0.7, 0.7, 0.7, 0.2)
	rested:SetBlendMode("ADD")
	rested:Show()

	local artifact = CreateFrame("StatusBar", "LUIArtifact", anchor)
	artifact:SetFrameStrata("HIGH")

	artifact.bg = artifact:CreateTexture(nil, "BORDER")
	artifact.bg:SetAllPoints(artifact)
	
	artifact.Text = artifact:CreateFontString("LUIArtifactText", "OVERLAY")
	artifact.Text:SetJustifyH("RIGHT")
	artifact.Text:SetShadowColor(0, 0, 0)
	artifact.Text:SetShadowOffset(1.25, -1.25)

	LUIThreat = bar
	LUIThreat.bg = bg
	LUIThreat.Text = text
	LUIThreat.helper = helper
	LUIThreat.indicator = indicator
	LUIThreat.rested = rested
	LUIThreat.artifact = artifact

	LUIThreat:SetScript("OnEvent", function(self, event)
		if event == "PLAYER_REGEN_ENABLED" then
			self:Hide()
		elseif event == "PLAYER_REGEN_DISABLED" then
			self:Show()
			if self.Testmode then
				self.Testmode = nil
				LUI:Print("Threatbar Testmode disabled due to combat.")
			end
		elseif event == "PLAYER_XP_UPDATE" or event == "UPDATE_FACTION" or event == "UPDATE_EXHAUSTION" then
			UpdateExpMode()
		elseif db.General.artifact and event == "PLAYER_ENTERING_WORLD" or event == "AZERITE_ITEM_EXPERIENCE_CHANGED" or event == "CVAR_UPDATE" then
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
			showRested = false,
			artifact = false,
			ShowAbsolute = false,
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
			X = 0,
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
			Precision = 0,
		},
	}
}

module.optionsName = "Threat/Exp Bar"
module.getter = "generic"
module.setter = "Refresh"

function module:LoadOptions()
	local disabledTextFunc = function() return not db.Text.Enable end
	local colorOptions = {"By Class", "Individual", "Gradient"}
	local disabledExpMode = function() return not db.General.expMode end
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
			expMode = self:NewToggle("Switch to Exp Mode", "If enabled, this will turn your Threat Bar into an experience bar.\nIf you are level 100 it will show a reputation bar instead.\nDisable Threat.",8,ToggleExpMode),
			showRested = self:NewToggle("Show Rested Experience", "If enabled, this will show your rested experience as well.", 9, dryCall, nil, disabledExpMode),
			ShowAbsolute = self:NewToggle("Show Absolute Values", "If enabled, this will show numerical values for current and max values.\n\nNote: Numerical XP values will not be shown if Rested Exp is displayed.", 10, dryCall, nil, disabledExpMode),
			artifact = self:NewToggle("Show Azerite XP", "If enabled, this will show your experience with the Heart of Azeroth. \nHidden if you do not have one. \n\nIf you are tracking XP or Rep, this will be shown along side your XP or Rep.", 11, dryCall, nil, disabledExpMode),
			empty3 = self:NewDesc(" ", 12),
			Testmode = self:NewExecute("Testmode", "Enable/Disable Threat Bar Testmode", 13, ToggleTestMode),
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
			Precision = self:NewSlider("Percentage Precision", "How many decimal places will be shown in percentages.", 10, 0, 3, 1, true, false, nil, disabledTextFunc),
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

	module.anchor:SetSize(LUI:Scale(db.General.Width), LUI:Scale(db.General.Height))
	module.anchor:ClearAllPoints()
	module.anchor:SetPoint(db.General.Point, UIParent, db.General.Point, LUI:Scale(db.General.X), LUI:Scale(db.General.Y))
	LUIThreat:SetSize(LUI:Scale(db.General.Width), LUI:Scale(db.General.Height))
	LUIThreat:SetStatusBarTexture(Media:Fetch("statusbar", db.Appearance.Texture))
	LUIThreat.artifact:SetSize(LUI:Scale(db.General.Width), LUI:Scale(db.General.Height))
	LUIThreat.artifact:SetStatusBarTexture(Media:Fetch("statusbar", db.Appearance.Texture))
	if r then
		LUIThreat:SetStatusBarColor(r, g, b)
		LUIThreat.artifact:SetStatusBarColor(r, g, b)
	end

	LUIThreat.bg:SetTexture(Media:Fetch("statusbar", db.Appearance.BGTexture))
	LUIThreat.artifact.bg:SetTexture(Media:Fetch("statusbar", db.Appearance.BGTexture))
	if r then
		LUIThreat.bg:SetVertexColor(r * mu, g * mu, b * mu)
		LUIThreat.artifact.bg:SetVertexColor(r * mu, g * mu, b * mu)
	end

	if db.Text.Color == "By Class" then
		r, g, b = unpack(oUFmodule.colors.class[class])
	elseif db.Text.Color == "Individual" then
		r, g, b = db.Text.IndividualColor.r, db.Text.IndividualColor.g, db.Text.IndividualColor.b
	else
		r, g, b = nil, nil, nil
	end

	LUIThreat.Text:SetFont(Media:Fetch("font", db.Text.Font), db.Text.Size, db.Text.Outline)
	LUIThreat.Text:ClearAllPoints()
	LUIThreat.Text:SetPoint("RIGHT", LUIThreat, "RIGHT", LUI:Scale(db.Text.X), LUI:Scale(db.Text.Y))
	if r then LUIThreat.Text:SetTextColor(r, g, b) end

	LUIThreat.artifact.Text:SetFont(Media:Fetch("font", db.Text.Font), db.Text.Size, db.Text.Outline)
	LUIThreat.artifact.Text:ClearAllPoints()
	LUIThreat.artifact.Text:SetPoint("LEFT", LUIThreat.artifact, "LEFT", -LUI:Scale(db.Text.X), LUI:Scale(db.Text.Y))
	if r then LUIThreat.artifact.Text:SetTextColor(r, g, b) end

	if db.General.expMode then
		UpdateExpMode()
		if db.General.showRested then
			LUIThreat.rested:Show()
		else
			LUIThreat.rested:Hide()
		end
	end

	if db.Text.Enable then
		LUIThreat.Text:Show()
		LUIThreat.artifact.Text:Show()
	else
		LUIThreat.Text:Hide()
		LUIThreat.artifact.Text:Hide()
	end
end

function module:OnInitialize()
	db, dbd = LUI:NewNamespace(self, true)
	local ProfileName = UnitName("player").." - "..GetRealmName()

	if LUI.db.global.luiconfig[ProfileName].Versions.threatbar ~= LUI.Versions.threatbar then
		db:ResetProfile()
		LUI.db.global.luiconfig[ProfileName].Versions.threatbar = LUI.Versions.threatbar
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
