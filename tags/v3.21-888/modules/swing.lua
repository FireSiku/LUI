--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: swing.lua
	Description: LUI Swing Timer
]]

local addonname, LUI = ...
local module = LUI:Module("Swing")
local oUFmodule = LUI:Module("Unitframes")
local Media = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists

local fontflags = {"OUTLINE", "THICKOUTLINE", "MONOCHROME", "NONE"}
local positions = { "TOP", "TOPRIGHT", "TOPLEFT", "BOTTOM", "BOTTOMRIGHT", "BOTTOMLEFT", "RIGHT", "LEFT", "CENTER"}

local _, class = UnitClass("player")

local db, dbd
local LUISwing

LUI.Versions.swing = 2.0

local meleeing
local rangeing
local lasthit

local MainhandID = GetInventoryItemID("player", 16)
local OffhandID = GetInventoryItemID("player", 17)
local RangedID = GetInventoryItemID("player", 18)

local ToggleTestMode = function()
	if LUISwing.Testmode then
		LUISwing.Testmode = nil
		LUISwing:Hide()
	else
		LUISwing.Testmode = true
		LUISwing:Show()
		LUISwing.Twohand:Show()
		LUISwing.Twohand:SetMinMaxValues(0, 2)
		LUISwing.Twohand:SetValue(1)
		LUISwing.Mainhand:Hide()
		LUISwing.Offhand:Hide()
	end
end

local SwingStopped = function(element)
	local bar = element.__owner

	local swing = bar.Twohand
	local swingMH = bar.Mainhand
	local swingOH = bar.Offhand

	if swing:IsShown() then return end
	if swingMH:IsShown() then return end
	if swingOH:IsShown() then return end

	bar:Hide()
end

local OnDurationUpdate
do
	local checkelapsed = 0
	local slamelapsed = 0
	local slamtime = 0
	local now
	local slam = GetSpellInfo(1464)
	function OnDurationUpdate(self, elapsed)
		now = GetTime()

		if meleeing then
			if checkelapsed > 0.02 then
				-- little hack for detecting melee stop
				-- improve... dw sucks at this point -.-
				if lasthit + self.speed + slamtime < now then
					self:Hide()
					self:SetScript("OnUpdate", nil)
					SwingStopped(self)
					meleeing = false
					rangeing = false
				end

				checkelapsed = 0
			else
				checkelapsed = checkelapsed + elapsed
			end
		end

		local spell = UnitCastingInfo("player")

		if slam == spell then
			-- slamelapsed: time to add for one slam
			slamelapsed = slamelapsed + elapsed
			-- slamtime: needed for meleeing hack (see some lines above)
			slamtime = slamtime + elapsed
		else
			-- after slam
			if slamelapsed ~= 0 then
				self.min = self.min + slamelapsed
				self.max = self.max + slamelapsed
				self:SetMinMaxValues(self.min, self.max)
				slamelapsed = 0
			end

			if now > self.max then
				if meleeing then
					if lasthit then
						self.min = self.max
						self.max = self.max + self.speed
						self:SetMinMaxValues(self.min, self.max)
						slamtime = 0
					end
				else
					self:Hide()
					self:SetScript("OnUpdate", nil)
					meleeing = false
					rangeing = false
				end
			else
				self:SetValue(now)
				if db.Text.Enable then
					if db.Text.Format == "Absolut" then
						self.Text:SetFormattedText("%.1f/%.1f", self.max - now, self.max - self.min)
					else
						self.Text:SetFormattedText("%.1f", self.max - now)
					end
				else
					self.Text:SetText()
				end
			end
		end
	end
end

local MeleeChange = function(bar, event, unit)
	if unit ~= "player" then return end
	if not meleeing then return end

	local swing = bar.Twohand
	local swingMH = bar.Mainhand
	local swingOH = bar.Offhand

	local NewMainhandID = GetInventoryItemID("player", 16)
	local NewOffhandID = GetInventoryItemID("player", 17)

	local now = GetTime()
	local mhspeed, ohspeed = UnitAttackSpeed("player")

	if MainhandID ~= NewMainhandID or OffhandID ~= NewOffhandID then
		if ohspeed then
			swing:Hide()
			swing:SetScript("OnUpdate", nil)

			swingMH.min = GetTime()
			swingMH.max = swingMH.min + mhspeed
			swingMH.speed = mhspeed

			swingMH:Show()
			swingMH:SetMinMaxValues(swingMH.min, swingMH.max)
			swingMH:SetScript("OnUpdate", OnDurationUpdate)

			swingOH.min = GetTime()
			swingOH.max = swingOH.min + ohspeed
			swingOH.speed = ohspeed

			swingOH:Show()
			swingOH:SetMinMaxValues(swingOH.min, swingMH.max)
			swingOH:SetScript("OnUpdate", OnDurationUpdate)
		else
			swing.min = GetTime()
			swing.max = swing.min + mhspeed
			swing.speed = mhspeed

			swing:Show()
			swing:SetMinMaxValues(swing.min, swing.max)
			swing:SetScript("OnUpdate", OnDurationUpdate)

			swingMH:Hide()
			swingMH:SetScript("OnUpdate", nil)

			swingOH:Hide()
			swingOH:SetScript("OnUpdate", nil)

		end

		lasthit = now

		MainhandID = NewMainhandID
		OffhandID = NewOffhandID
	else
		if ohspeed then
			if swingMH.speed ~= mhspeed then
				local percentage = (swingMH.max - now) / (swingMH.speed)
				swingMH.min = now - mhspeed * (1 - percentage)
				swingMH.max = now + mhspeed * percentage
				swingMH:SetMinMaxValues(swingMH.min, swingMH.max)
				swingMH.speed = mhspeed
			end
			if swingOH.speed ~= ohspeed then
				local percentage = (swingOH.max - now) / (swingOH.speed)
				swingOH.min = now - ohspeed * (1 - percentage)
				swingOH.max = now + ohspeed * percentage
				swingOH:SetMinMaxValues(swingOH.min, swingOH.max)
				swingOH.speed = ohspeed
			end
		else
			if swing.speed ~= mhspeed then
				local percentage = (swing.max - now) / (swing.speed)
				swing.min = now - mhspeed * (1 - percentage)
				swing.max = now + mhspeed * percentage
				swing:SetMinMaxValues(swing.min, swing.max)
				swing.speed = mhspeed
			end
		end
	end
end

local RangedChange = function(bar, event, unit)
	if unit ~= "player" then return end
	if not rangeing then return end

	local swing = bar.Twohand

	local NewRangedID = GetInventoryItemID("player", 18)

	local now = GetTime()
	local speed = UnitRangedDamage("player")

	if RangedID ~= NewRangedID then
		swing.speed = UnitRangedDamage(unit)
		swing.min = GetTime()
		swing.max = swing.min + swing.speed

		swing:Show()
		swing:SetMinMaxValues(swing.min, swing.max)
		swing:SetScript("OnUpdate", OnDurationUpdate)
	else
		if swing.speed ~= speed then
			local percentage = (swing.max - GetTime()) / (swing.speed)
			swing.min = now - speed * (1 - percentage)
			swing.max = now + speed * percentage
			swing.speed = speed
		end
	end
end

local Ranged = function(bar, event, unit, spellName)
	if unit ~= "player" then return end
	if spellName ~= GetSpellInfo(75) and spellName ~= GetSpellInfo(5019) then return end

	local swing = bar.Twohand
	local swingMH = bar.Mainhand
	local swingOH = bar.Offhand

	meleeing = false
	rangeing = true

	bar:Show()

	swing.speed = UnitRangedDamage(unit)
	swing.min = GetTime()
	swing.max = swing.min + swing.speed

	swing:Show()
	swing:SetMinMaxValues(swing.min, swing.max)
	swing:SetScript("OnUpdate", OnDurationUpdate)

	swingMH:Hide()
	swingMH:SetScript("OnUpdate", nil)

	swingOH:Hide()
	swingOH:SetScript("OnUpdate", nil)
end

local Melee = function(bar, event, _, subevent, _, GUID)
	if UnitGUID("player") ~= GUID then return end
	if not string.find(subevent, "SWING") then return end

	local swing = bar.Twohand
	local swingMH = bar.Mainhand
	local swingOH = bar.Offhand

	-- calculation of new hits is in OnDurationUpdate
	-- workaround, cant differ between mainhand and offhand hits
	if not meleeing then
		bar:Show()

		swing:Hide()
		swingMH:Hide()
		swingOH:Hide()

		swing:SetScript("OnUpdate", nil)
		swingMH:SetScript("OnUpdate", nil)
		swingOH:SetScript("OnUpdate", nil)

		local mhspeed, ohspeed = UnitAttackSpeed("player")

		if ohspeed then
			swingMH.min = GetTime()
			swingMH.max = swingMH.min + mhspeed
			swingMH.speed = mhspeed

			swingMH:Show()
			swingMH:SetMinMaxValues(swingMH.min, swingMH.max)
			swingMH:SetScript("OnUpdate", OnDurationUpdate)

			swingOH.min = GetTime()
			swingOH.max = swingOH.min + ohspeed
			swingOH.speed = ohspeed

			swingOH:Show()
			swingOH:SetMinMaxValues(swingOH.min, swingOH.max)
			swingOH:SetScript("OnUpdate", OnDurationUpdate)
		else
			swing.min = GetTime()
			swing.max = swing.min + mhspeed
			swing.speed = mhspeed

			swing:Show()
			swing:SetMinMaxValues(swing.min, swing.max)
			swing:SetScript("OnUpdate", OnDurationUpdate)
		end

		meleeing = true
		rangeing = false
	end

	lasthit = GetTime()
end

local ParryHaste = function(bar, event, _, subevent, _, _, _, _, _, _, tarGUID, _, missType)
	if UnitGUID("player") ~= tarGUID then return end
	if not meleeing then return end
	if not string.find(subevent, "MISSED") then return end
	if missType ~= "PARRY" then return end

	local swing = bar.Twohand
	local swingMH = bar.Mainhand
	local swingOH = bar.Offhand

	local _, dualwield = UnitAttackSpeed("player")
	local now = GetTime()

	-- needed calculations, so the timer doesnt jump on parryhaste
	if dualwield then
		local percentage = (swingMH.max - now) / swingMH.speed

		if percentage > 0.6 then
			swingMH.max = now + swingMH.speed * 0.6
			swingMH.min = now - (swingMH.max - now) * percentage / (1 - percentage)
			swingMH:SetMinMaxValues(swingMH.min, swingMH.max)
		elseif percentage > 0.2 then
			swingMH.max = now + swingMH.speed * 0.2
			swingMH.min = now - (swingMH.max - now) * percentage / (1 - percentage)
			swingMH:SetMinMaxValues(swingMH.min, swingMH.max)
		end

		percentage = (swingOH.max - now) / swingOH.speed

		if percentage > 0.6 then
			swingOH.max = now + swingOH.speed * 0.6
			swingOH.min = now - (swingOH.max - now) * percentage / (1 - percentage)
			swingOH:SetMinMaxValues(swingOH.min, swingOH.max)
		elseif percentage > 0.2 then
			swingOH.max = now + swingOH.speed * 0.2
			swingOH.min = now - (swingOH.max - now) * percentage / (1 - percentage)
			swingOH:SetMinMaxValues(swingOH.min, swingOH.max)
		end
	else
		local percentage = (swing.max - now) / swing.speed

		if percentage > 0.6 then
			swing.max = now + swing.speed * 0.6
			swing.min = now - (swing.max - now) * percentage / (1 - percentage)
			swing:SetMinMaxValues(swing.min, swing.max)
		elseif percentage > 0.2 then
			swing.max = now + swing.speed * 0.2
			swing.min = now - (swing.max - now) * percentage / (1 - percentage)
			swing:SetMinMaxValues(swing.min, swing.max)
		end
	end
end

local Ooc = function(bar)
	-- strange behaviour sometimes...
	meleeing = false
	rangeing = false
end

local SetSwing = function()
	if LUISwing then return end

	LUISwing = CreateFrame("Frame", "LUISwing", UIParent)
	LUISwing:SetFrameStrata("HIGH")

	LUISwing.Twohand = CreateFrame("StatusBar", nil, LUISwing)
	LUISwing.Twohand:SetPoint("TOPLEFT", LUISwing, "TOPLEFT", 0, 0)
	LUISwing.Twohand:SetPoint("BOTTOMRIGHT", LUISwing, "BOTTOMRIGHT", 0, 0)
	LUISwing.Twohand:SetFrameLevel(20)
	LUISwing.Twohand:Hide()

	LUISwing.Twohand.bg = LUISwing.Twohand:CreateTexture(nil, "BACKGROUND")
	LUISwing.Twohand.bg:SetAllPoints(LUISwing.Twohand)
	LUISwing.Twohand.__owner = LUISwing

	LUISwing.Mainhand = CreateFrame("StatusBar", nil, LUISwing)
	LUISwing.Mainhand:SetPoint("TOPLEFT", LUISwing, "TOPLEFT", 0, 0)
	LUISwing.Mainhand:SetPoint("BOTTOMRIGHT", LUISwing, "RIGHT", 0, 0)
	LUISwing.Mainhand:SetFrameLevel(20)
	LUISwing.Mainhand:Hide()

	LUISwing.Mainhand.bg = LUISwing.Mainhand:CreateTexture(nil, "BACKGROUND")
	LUISwing.Mainhand.bg:SetAllPoints(LUISwing.Mainhand)
	LUISwing.Mainhand.__owner = LUISwing

	LUISwing.Offhand = CreateFrame("StatusBar", nil, LUISwing)
	LUISwing.Offhand:SetPoint("TOPLEFT", LUISwing, "LEFT", 0, 0)
	LUISwing.Offhand:SetPoint("BOTTOMRIGHT", LUISwing, "BOTTOMRIGHT", 0, 0)
	LUISwing.Offhand:SetFrameLevel(20)
	LUISwing.Offhand:Hide()

	LUISwing.Offhand.bg = LUISwing.Offhand:CreateTexture(nil, "BACKGROUND")
	LUISwing.Offhand.bg:SetAllPoints(LUISwing.Offhand)
	LUISwing.Offhand.__owner = LUISwing

	-- texts
	LUISwing.Twohand.Text = LUISwing.Twohand:CreateFontString(nil, "OVERLAY")
	LUISwing.Twohand.Text:SetJustifyH("LEFT")
	LUISwing.Twohand.Text:SetShadowColor(0, 0, 0)
	LUISwing.Twohand.Text:SetShadowOffset(1.25, -1.25)

	LUISwing.Mainhand.Text = LUISwing.Mainhand:CreateFontString(nil, "OVERLAY")
	LUISwing.Mainhand.Text:SetJustifyH("LEFT")
	LUISwing.Mainhand.Text:SetShadowColor(0, 0, 0)
	LUISwing.Mainhand.Text:SetShadowOffset(1.25, -1.25)
	LUISwing.Mainhand.Text:SetPoint("BOTTOM", LUISwing.Twohand.Text, "CENTER", 0, 1)

	LUISwing.Offhand.Text = LUISwing.Offhand:CreateFontString(nil, "OVERLAY")
	LUISwing.Offhand.Text:SetJustifyH("LEFT")
	LUISwing.Offhand.Text:SetShadowColor(0, 0, 0)
	LUISwing.Offhand.Text:SetShadowOffset(1.25, -1.25)
	LUISwing.Offhand.Text:SetPoint("TOP", LUISwing.Twohand.Text, "CENTER", 0, -1)

	LUISwing:SetScript("OnEvent", function(self, event, ...)
		if event == "PLAYER_REGEN_DISABLED" then
			if self.Testmode then
				self.Testmode = nil
				self:Hide()
			end
		elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
			Ranged(self, event, ...)
		elseif event == "UNIT_RANGEDDAMAGE" then
			RangedChange(self, event, ...)
		elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
			Melee(self, event, ...)
			ParryHaste(self, event, ...)
		elseif event == "UNIT_ATTACK_SPEED" then
			MeleeChange(self, event, ...)
		elseif event == "PLAYER_REGEN_ENABLED" then
			Ooc(self, event, ...)
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
			Y = 86.5,
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

module.optionsName = "Swing Timer"
module.getter = "generic"
module.setter = "Refresh"

function module:LoadOptions()
	local disabledTextFunc = function() return not db.Text.Enable end
	local colorOptions = {"By Class", "Individual", "Gradient"}
	local dryCall = function() self:Refresh() end

	local options = {
		General = self:NewGroup("General", 1, {
			header = self:NewHeader("General Options", 0),
			[""] = self:NewPosSliders("Swing Timer", 1, nil, "LUISwing", true),
			Point = self:NewSelect("Point", "Choose the Point for your Swing Timer.", 2, positions, nil, dryCall),
			empty1 = self:NewDesc(" ", 3),
			Width = self:NewInputNumber("Width", "Choose the Width for your Swing Timer.", 4, dryCall),
			Height = self:NewInputNumber("Height", "Choose the Height for your Swing Timer.", 5, dryCall),
			empty2 = self:NewDesc(" ", 6),
			Testmode = self:NewExecute("Testmode", "Enable/Disable Swing Timer Testmode", 7, ToggleTestMode),
		}),
		Appearance = self:NewGroup("Appearance", 2, {
			header = self:NewHeader("Appearance Options", 0),
			Texture = self:NewSelect("Texture", "Choose the Texture for your Swing Timer.", 1, widgetLists.statusbar, "LSM30_Statusbar", true),
			BGTexture = self:NewSelect("Background Texture", "Choose the Background Texture for your Swing Timer.", 2, widgetLists.statusbar, "LSM30_Statusbar", true),
			BGMultiplier = self:NewSlider("Background Multiplier", "Choose the Multiplier for your Background Color.", 3, 0, 1, 0.01, true, true),
			empty1 = self:NewDesc(" ", 4),
			Color = self:NewSelect("Color", "Choose the Color Option for your Swing Timer.", 5, colorOptions, nil, dryCall),
			IndividualColor = self:NewColorNoAlpha("Individual", "Swing Timer", 6, dryCall, nil, function() return db.Appearance.Color ~= "Individual" end),
		}),
		Text = self:NewGroup("Text", 3, {
			header = self:NewHeader("Text Options", 0),
			Enable = self:NewToggle("Enable Text", "Whether you want to show a Text on your Swing Timer or not.", 1, true),
			empty1 = self:NewDesc(" ", 2),
			[""] = self:NewPosSliders("Swing Timer Text", 3, nil, "LUISwingText", true, nil, disabledTextFunc),
			Font = self:NewSelect("Font", "Choose the Font for your Swing Timer Text.", 4, widgetLists.font, "LSM30_Font", true, nil, disabledTextFunc),
			Size = self:NewInputNumber("Fontsize", "Choose the Fontsize for your Swing Timer Text.", 5, dryCall, nil, disabledTextFunc),
			Outline = self:NewSelect("Font Flag", "Choose the Font Flag for the Swing Timer Text Font.", 6, fontflags, nil, dryCall, nil, disabledTextFunc),
			empty2 = self:NewDesc(" ", 7),
			Color = self:NewSelect("Color", "Choose the Color option for your Swing Timer Text.", 8, colorOptions, nil, dryCall, nil, disabledTextFunc),
			IndividualColor = self:NewColorNoAlpha("Individual", "Swing Timer Text", 9, dryCall, nil, function() return not db.Text.Enable or db.Text.Color ~= "Individual" end),
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

	LUISwing:SetWidth(LUI:Scale(db.General.Width))
	LUISwing:SetHeight(LUI:Scale(db.General.Height))
	LUISwing:ClearAllPoints()
	LUISwing:SetPoint(db.General.Point, UIParent, db.General.Point, LUI:Scale(db.General.X), LUI:Scale(db.General.Y))

	LUISwing.Twohand:SetStatusBarTexture(Media:Fetch("statusbar", db.Appearance.Texture))
	LUISwing.Twohand:SetStatusBarColor(r, g, b)
	LUISwing.Twohand.bg:SetTexture(Media:Fetch("statusbar", db.Appearance.TextureBG))
	LUISwing.Twohand.bg:SetVertexColor(r*mu, g*mu, b*mu)

	LUISwing.Mainhand:SetStatusBarTexture(Media:Fetch("statusbar", db.Appearance.Texture))
	LUISwing.Mainhand:SetStatusBarColor(r, g, b)
	LUISwing.Offhand:SetStatusBarTexture(Media:Fetch("statusbar", db.Appearance.TextureBG))
	LUISwing.Offhand:SetStatusBarColor(r, g, b)

	LUISwing.Mainhand.bg:SetTexture(Media:Fetch("statusbar", db.Appearance.Texture))
	LUISwing.Mainhand.bg:SetVertexColor(r*mu, g*mu, b*mu)
	LUISwing.Offhand.bg:SetTexture(Media:Fetch("statusbar", db.Appearance.TextureBG))
	LUISwing.Offhand.bg:SetVertexColor(r*mu, g*mu, b*mu)

	if db.Text.Color == "By Class" then
		r, g, b = unpack(colors.class[class])
	else
		r, g, b = db.Text.IndividualColor.r, db.Text.IndividualColor.g, db.Text.IndividualColor.b
	end

	LUISwing.Mainhand.Text:SetFont(Media:Fetch("font", db.Text.Font), db.Text.Size, db.Text.Outline)
	LUISwing.Mainhand.Text:SetTextColor(r, g, b)

	LUISwing.Offhand.Text:SetFont(Media:Fetch("font", db.Text.Font), db.Text.Size, db.Text.Outline)
	LUISwing.Offhand.Text:SetTextColor(r, g, b)

	LUISwing.Twohand.Text:SetFont(Media:Fetch("font", db.Text.Font), db.Text.Size, db.Text.Outline)
	LUISwing.Twohand.Text:SetTextColor(r, g, b)
	LUISwing.Twohand.Text:ClearAllPoints()
	LUISwing.Twohand.Text:SetPoint("CENTER", LUISwing.Twohand, "CENTER", LUI:Scale(db.Text.X), LUI:Scale(db.Text.Y))

	if db.Text.Enable then
		LUISwing.Twohand.Text:Show()
		LUISwing.Mainhand.Text:Show()
		LUISwing.Offhand.Text:Show()
	else
		LUISwing.Twohand.Text:Hide()
		LUISwing.Mainhand.Text:Hide()
		LUISwing.Offhand.Text:Hide()
	end
end

function module:OnInitialize()
	db, dbd = LUI:NewNamespace(self, true)
	local ProfileName = UnitName("player").." - "..GetRealmName()

	if LUI.db.global.luiconfig[ProfileName].Versions.swing ~= LUI.Versions.swing then
		db:ResetProfile()
		LUI.db.global.luiconfig[ProfileName].Versions.swing = LUI.Versions.swing
	end
end

function module:OnEnable()
	SetSwing()
	self:Refresh()

	LUISwing:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED") -- Ranged
	LUISwing:RegisterEvent("UNIT_RANGEDDAMAGE") -- RangedChange
	LUISwing:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED") -- Melee, ParryHaste
	LUISwing:RegisterEvent("UNIT_ATTACK_SPEED") -- MeleeChange
	LUISwing:RegisterEvent("PLAYER_REGEN_ENABLED") -- Ooc

	LUISwing:Hide()
end

function module:OnDisable()
	LUISwing:UnregisterAllEvents()
	LUISwing:Hide()
end
