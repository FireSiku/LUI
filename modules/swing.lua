--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: swing.lua
	Description: LUI Swing Timer
	Version....: 1.0
	Rev Date...: 29/07/2011 [dd/mm/yyyy]

	Edits:
		v1.0: Thaly
]]

local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local module = LUI:NewModule("Swing")
local LSM = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists
local fontflags = {'OUTLINE', 'THICKOUTLINE', 'MONOCHROME', 'NONE'}

local _, class = UnitClass("player")

local db
local LUISwing

local meleeing
local rangeing
local lasthit

local MainhandID = GetInventoryItemID("player", 16)
local OffhandID = GetInventoryItemID("player", 17)
local RangedID = GetInventoryItemID("player", 18)

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
				if db.profile.Text.Enable then
					if db.profile.Text.Format == "Absolut" then
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
		if event == "UNIT_SPELLCAST_SUCCEEDED" then
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

local ApplySettings = function()
	LUISwing:SetWidth(LUI:Scale(db.profile.Width))
	LUISwing:SetHeight(LUI:Scale(db.profile.Height))
	LUISwing:ClearAllPoints()
	LUISwing:SetPoint("BOTTOM", UIParent, "BOTTOM", LUI:Scale(db.profile.X), LUI:Scale(db.profile.Y))

	local r, g, b
	local mu = db.profile.BGMultiplier
	if db.profile.Color == "By Class" then
		r, g, b = unpack(LUI.oUF.colors.class[class])
	else
		r, g, b = db.profile.IndividualColor.r, db.profile.IndividualColor.g, db.profile.IndividualColor.b
	end
	
	LUISwing.Twohand:SetStatusBarTexture(LSM:Fetch("statusbar", db.profile.Texture))
	LUISwing.Twohand:SetStatusBarColor(r, g, b)
	LUISwing.Twohand.bg:SetTexture(LSM:Fetch("statusbar", db.profile.TextureBG))
	LUISwing.Twohand.bg:SetVertexColor(r*mu, g*mu, b*mu)
	
	LUISwing.Mainhand:SetStatusBarTexture(LSM:Fetch("statusbar", db.profile.Texture))
	LUISwing.Mainhand:SetStatusBarColor(r, g, b)
	LUISwing.Offhand:SetStatusBarTexture(LSM:Fetch("statusbar", db.profile.Texture))
	LUISwing.Offhand:SetStatusBarColor(r, g, b)
	
	LUISwing.Mainhand.bg:SetTexture(LSM:Fetch("statusbar", db.profile.TextureBG))
	LUISwing.Mainhand.bg:SetVertexColor(r*mu, g*mu, b*mu)
	LUISwing.Offhand.bg:SetTexture(LSM:Fetch("statusbar", db.profile.TextureBG))
	LUISwing.Offhand.bg:SetVertexColor(r*mu, g*mu, b*mu)
	
	-- texts
	if db.profile.Text.Color == "By Class" then
		r, g, b = unpack(colors.class[class])
	else
		r, g, b = db.profile.Text.IndividualColor.r, db.profile.Text.IndividualColor.g, db.profile.Text.IndividualColor.b
	end
	
	LUISwing.Mainhand.Text:SetFont(LSM:Fetch("font", db.profile.Text.Font), db.profile.Text.Size, db.profile.Text.Outline)
	LUISwing.Mainhand.Text:SetTextColor(r, g, b)
	
	LUISwing.Offhand.Text:SetFont(LSM:Fetch("font", db.profile.Text.Font), db.profile.Text.Size, db.profile.Text.Outline)
	LUISwing.Offhand.Text:SetTextColor(r, g, b)
	
	LUISwing.Twohand.Text:SetFont(LSM:Fetch("font", db.profile.Text.Font), db.profile.Text.Size, db.profile.Text.Outline)
	LUISwing.Twohand.Text:SetTextColor(r, g, b)
	LUISwing.Twohand.Text:ClearAllPoints()
	LUISwing.Twohand.Text:SetPoint("CENTER", LUISwing.Twohand, "CENTER", LUI:Scale(db.profile.Text.X), LUI:Scale(db.profile.Text.Y))
	
	if db.profile.Text.Enable then
		LUISwing.Twohand.Text:Show()
		LUISwing.Mainhand.Text:Show()
		LUISwing.Offhand.Text:Show()
	else
		LUISwing.Twohand.Text:Hide()
		LUISwing.Mainhand.Text:Hide()
		LUISwing.Offhand.Text:Hide()
	end
end

module.optionsName = "Swing Timer"
module.childGroups = "tab"
module.defaults = {
	profile = {
		Enable = true,
		Width = "384",
		Height = "4",
		X = "0",
		Y = "86.5",
		Texture = "LUI_Gradient",
		Color = "By Class",
		IndividualColor = {
			r = 1,
			g = 1,
			b = 1
		},
		BGTexture = "LUI_Minimalist",
		BGMultiplier = 0.4,
		Text = {
			Enable = false,
			X = "0",
			Y = "0",
			Format = "Standard",
			Font = "neuropol",
			Size = 10,
			Outline = "NONE",
			Color = "Individual",
			IndividualColor = {
				r = 1,
				g = 1,
				b = 1
			}
		}
	}
}

function module:LoadOptions()
	local options = {
		Bar = {
			name = "Bar",
			type = "group",
			order = 2,
			args = {
				General = {
					name = "General",
					type = "group",
					guiInline = true,
					order = 1,
					args = {
						XValue = LUI:NewPosX("Swing Timer", 1, db.profile, "", module.defaults.profile, ApplySettings),
						YValue = LUI:NewPosY("Swing Timer", 2, db.profile, "", module.defaults.profile, ApplySettings),
						Width = LUI:NewWidth("Swing Timer", 3, db.profile, nil, module.defaults.profile, ApplySettings),
						Height = LUI:NewHeight("Swing Timer", 4, db.profile, nil, module.defaults.profile, ApplySettings)
					}
				},
				Colors = {
					name = "Color",
					type = "group",
					guiInline = true,
					order = 2,
					args = {
						ColorType = LUI:NewSelect("Color", "Choose the Color Option for your Swing Timer.", 1, {"By Class", "Individual"}, nil, db.profile, "Color", module.defaults.profile, ApplySettings),
						Color = LUI:NewColorNoAlpha("Individual", barName, 2, db.profile.IndividualColor, module.defaults.profile.IndividualColor, ApplySettings, nil, function() return (db.Color ~= "Individual") end),
					}
					
				},
				Textures = {
					name = "Texture",
					type = "group",
					guiInline = true,
					order = 3,
					args = {
						Texture = LUI:NewSelect("Texture", "Choose the Swing Timer Texture.", 1, widgetLists.statusbar, "LSM30_Statusbar", db.profile, "Texture", module.defaults.profile, ApplySettings),
						BGTexture = LUI:NewSelect("Background Texture", "Choose the Swing Timer Background Texture.", 2, widgetLists.statusbar, "LSM30_Statusbar", db.profile, "BGTexture", module.defaults.profile, ApplySettings),
						BGMultiplier = LUI:NewSlider("Background Multiplier", "Choose the Multiplier which will be used to generate the Background Color", 3, db.profile, "BGMultiplier", module.defaults.profile, 0, 1, 0.05, ApplySettings),
					}
				}
			}
		},
		Text = {
			name = "Text",
			type = "group",
			order = 3,
			args = {
				Enable = LUI:NewToggle("Enable Text", "Whether you want to show the Swing Timer Text or not.", 1, db.profile.Text, "Enable", module.defaults.profile.Text, ApplySettings),
				FontSettings = {
					name = "Font Settings",
					type = "group",
					guiInline = true,
					order = 2,
					disabled = function() return not db.profile.Text.Enable end,
					args = {
						FontSize = LUI:NewSlider("Size", "Choose your Swing Timer Text Fontsize.", 1, db.profile.Text, "Size", module.defaults.profile.Text, 1, 40, 1, ApplySettings),
						empty = LUI:NewEmpty(2),
						Font = LUI:NewSelect("Font", "Choose your Swing Timer Text Font.", 3, widgetLists.font, "LSM30_Font", db.profile.Text, "Font", module.defaults.profile.Text, ApplySettings),
						FontFlag = LUI:NewSelect("Font Flag", "Choose the Font Flag for the Swing Timer Text Font.", 4, fontflags, nil, db.profile.Text, "Outline", module.defaults.profile.Text, ApplySettings),
					},
				},
				Settings = {
					name = "Settings",
					type = "group",
					guiInline = true,
					order = 3,
					disabled = function() return not db.profile.Text.Enable end,
					args = {
						XValue = LUI:NewPosX("Swing Timer Text", 1, db.profile.Text, "", module.defaults.profile.Text, ApplySettings),
						YValue = LUI:NewPosY("Swing Timer Text", 2, db.profile.Text, "", module.defaults.profile.Text, ApplySettings),
						Format = LUI:NewSelect("Format", "Choose the Format for the Swing Timer Text.", 3, {"Absolut", "Standard"}, nil, db.profile.Text, "Format", module.defaults.profile.Text, ApplySettings),
					}
				},
				Color = {
					name = "Color Settings",
					type = "group",
					guiInline = true,
					order = 4,
					disabled = function() return not db.profile.Text.Enable end,
					args = {
						Color = LUI:NewSelect("Color", "Choose the Color Option for the Swing Timer Text.", 1, {"By Class", "Individual"}, nil, db.profile.Text, "Color", module.defaults.profile.Text, ApplySettings),
						IndividualColor = LUI:NewColorNoAlpha("", "Swing Timer Text", 2, db.profile.Text.IndividualColor, module.defaults.profile.Text.IndividualColor, ApplySettings),
					}
				}
			}
		}
	}

	return options
end

function module:OnInitialize()
	db = LUI:NewNamespace(self, true)
	
	-- Look for outdated db vars and transfer them over
	if LUI.db.profile.oUF.Player.Swing then
		for k, v in pairs(LUI.db.profile.oUF.Player.Swing) do
			db.profile[k] = v
		end
		LUI.db.profile.oUF.Player.Swing = nil
	end
end

function module:OnEnable()
	SetSwing()
	ApplySettings()
	
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
