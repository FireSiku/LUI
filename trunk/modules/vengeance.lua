--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: vengeance.lua
	Description: LUI Vengeance Bar
	Version....: 1.0
	Rev Date...: 29/07/2011 [dd/mm/yyyy]

	Edits:
		v1.0: Thaly
]]

local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local module = LUI:NewModule("Vengeance")
local LSM = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists
local fontflags = {'OUTLINE', 'THICKOUTLINE', 'MONOCHROME', 'NONE'}

local _, class = UnitClass("player")

local db
local LUIVengeance

local vengeance = GetSpellInfo(93098)

local tooltip = CreateFrame("GameTooltip", "LUIVengeanceTooltip", UIParent, "GameTooltipTemplate")
local tooltiptext = _G[tooltip:GetName().."TextLeft2"]

tooltip:SetOwner(UIParent, "ANCHOR_NONE")
tooltiptext:SetText("")

local ValueChanged = function(bar, event, unit)
	if unit ~= "player" then return end
	
	if not bar.isTank then
		bar:Hide()
		return
	end
	
	local name = UnitAura("player", vengeance, nil, "PLAYER|HELPFUL")
	
	if name then
		tooltip:ClearLines()
		tooltip:SetUnitBuff("player", name)
		local value = (tooltiptext:GetText() and tonumber(string.match(tostring(tooltiptext:GetText()), "%d+"))) or -1
		
		if value > 0 then
			if value > bar.max then value = bar.max end
			if value == bar.value then return end
			
			bar:SetMinMaxValues(0, bar.max)
			bar:SetValue(value)
			bar.value = value
			bar:Show()
		end
	elseif InCombatLockdown() then
		bar:Show()
		bar:SetMinMaxValues(0, 1)
		bar:SetValue(0)
		bar.value = 0
	else
		bar:Hide()
		bar.value = 0
	end
			
	if db.profile.Text.Enable then
		if db.profile.Text.Format == "Absolut" then
			bar.Text:SetFormattedText("%d/%d", bar.value, mbar.max)
		else
			bar.Text:SetFormattedText("%d", bar.value)
		end
	else
		bar.Text:SetText("")
	end
end

local MaxChanged = function(bar, event, unit)
	if unit ~= "player" then return end
	
	if not bar.isTank then
		bar:Hide()
		return
	end
	
	local health = UnitHealthMax("player")
	local _, stamina = UnitStat("player", 3)
	
	if not health or not stamina then return end
	
	bar.max = math.floor(0.1 * (health - 15 * stamina) + stamina)
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
	
	MaxChanged(bar, event, "player")
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
		if event == "UNIT_AURA" then
			ValueChanged(self, event, ...)
		elseif event == "UNIT_MAXHEALTH" or event == "UNIT_LEVEL" then
			MaxChanged(self, event, ...)
		elseif event == "PLAYER_REGEN_DISABLED" then
			IsTank(self, event, ...)
		end
	end)
end

local ApplySettings = function()
	local r, g, b
	local mu = db.profile.BGMultiplier
	if db.profile.Color == "By Class" then
		r, g, b = unpack(LUI.oUF.colors.class[class])
	else
		r, g, b = db.profile.IndividualColor.r, db.profile.IndividualColor.g, db.profile.IndividualColor.b
	end
	
	LUIVengeance:SetWidth(LUI:Scale(db.profile.Width))
	LUIVengeance:SetHeight(LUI:Scale(db.profile.Height))
	LUIVengeance:ClearAllPoints()
	LUIVengeance:SetPoint("BOTTOM", UIParent, "BOTTOM", LUI:Scale(db.profile.X), LUI:Scale(db.profile.Y))
	LUIVengeance:SetStatusBarTexture(LSM:Fetch("statusbar", db.profile.Texture))
	LUIVengeance:SetStatusBarColor(r, g, b)
	
	LUIVengeance.bg:SetTexture(LSM:Fetch("statusbar", db.profile.TextureBG))
	LUIVengeance.bg:SetVertexColor(r * mu, g * mu, b * mu)
	
	if db.profile.Text.Color == "By Class" then
		r, g, b = unpack(LUI.oUF.colors.class[class])
	else
		r, g, b = db.profile.Text.IndividualColor.r, db.profile.Text.IndividualColor.g, db.profile.Text.IndividualColor.b
	end
	
	LUIVengeance.Text:SetFont(LSM:Fetch("font", db.profile.Text.Font), db.profile.Text.Size, db.profile.Text.Outline)
	LUIVengeance.Text:ClearAllPoints()
	LUIVengeance.Text:SetPoint("CENTER", LUIVengeance, "CENTER", LUI:Scale(db.profile.Text.X), LUI:Scale(db.profile.Text.Y))
	LUIVengeance.Text:SetTextColor(r, g, b)
	
	if db.profile.Text.Enable then
		LUIVengeance.Text:Show()
	else
		LUIVengeance.Text:Hide()
	end
end

module.optionsName = "Vengeance Bar"
module.childGroups = "tab"
module.defaults = {
	profile = {
		Enable = true,
		Width = "384",
		Height = "4",
		X = "0",
		Y = "12",
		Texture = "LUI_Gradient",
		Color = "By Class",
		IndividualColor = {
			r = 1,
			g = 1,
			b = 1,
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
				b = 1,
			},
		},
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
						XValue = LUI:NewPosX("Vengeance Bar", 1, db.profile, "", module.defaults.profile, ApplySettings),
						YValue = LUI:NewPosY("Vengeance Bar", 2, db.profile, "", module.defaults.profile, ApplySettings),
						Width = LUI:NewWidth("Vengeance Bar", 3, db.profile, nil, module.defaults.profile, ApplySettings),
						Height = LUI:NewHeight("Vengeance Bar", 4, db.profile, nil, module.defaults.profile, ApplySettings)
					}
				},
				Colors = {
					name = "Color",
					type = "group",
					guiInline = true,
					order = 2,
					args = {
						ColorType = LUI:NewSelect("Color", "Choose the Color Option for your Vengeance Bar.", 1, {"By Class", "Individual"}, nil, db.profile, "Color", module.defaults.profile, ApplySettings),
						Color = LUI:NewColorNoAlpha("Individual", barName, 2, db.profile.IndividualColor, module.defaults.profile.IndividualColor, ApplySettings, nil, function() return (db.Color ~= "Individual") end),
					}
					
				},
				Textures = {
					name = "Texture",
					type = "group",
					guiInline = true,
					order = 3,
					args = {
						Texture = LUI:NewSelect("Texture", "Choose the Vengeance Bar Texture.", 1, widgetLists.statusbar, "LSM30_Statusbar", db.profile, "Texture", module.defaults.profile, ApplySettings),
						BGTexture = LUI:NewSelect("Background Texture", "Choose the Vengeance Bar Background Texture.", 2, widgetLists.statusbar, "LSM30_Statusbar", db.profile, "BGTexture", module.defaults.profile, ApplySettings),
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
				Enable = LUI:NewToggle("Enable Text", "Whether you want to show the Vengeance Bar Text or not.", 1, db.profile.Text, "Enable", module.defaults.profile.Text, ApplySettings),
				FontSettings = {
					name = "Font Settings",
					type = "group",
					guiInline = true,
					order = 2,
					disabled = function() return not db.profile.Text.Enable end,
					args = {
						FontSize = LUI:NewSlider("Size", "Choose your Vengeance Bar Text Fontsize.", 1, db.profile.Text, "Size", module.defaults.profile.Text, 1, 40, 1, ApplySettings),
						empty = LUI:NewEmpty(2),
						Font = LUI:NewSelect("Font", "Choose your Vengeance Bar Text Font.", 3, widgetLists.font, "LSM30_Font", db.profile.Text, "Font", module.defaults.profile.Text, ApplySettings),
						FontFlag = LUI:NewSelect("Font Flag", "Choose the Font Flag for the Vengeance Bar Text Font.", 4, fontflags, nil, db.profile.Text, "Outline", module.defaults.profile.Text, ApplySettings),
					},
				},
				Settings = {
					name = "Settings",
					type = "group",
					guiInline = true,
					order = 3,
					disabled = function() return not db.profile.Text.Enable end,
					args = {
						XValue = LUI:NewPosX("Vengeance Bar Text", 1, db.profile.Text, "", module.defaults.profile.Text, ApplySettings),
						YValue = LUI:NewPosY("Vengeance Bar Text", 2, db.profile.Text, "", module.defaults.profile.Text, ApplySettings),
						Format = LUI:NewSelect("Format", "Choose the Format for the Vengeance Bar Text.", 3, {"Absolut", "Standard"}, nil, db.profile.Text, "Format", module.defaults.profile.Text, ApplySettings),
					}
				},
				Color = {
					name = "Color Settings",
					type = "group",
					guiInline = true,
					order = 4,
					disabled = function() return not db.profile.Text.Enable end,
					args = {
						Color = LUI:NewSelect("Color", "Choose the Color Option for the Vengeance Bar Text.", 1, {"By Class", "Individual"}, nil, db.profile.Text, "Color", module.defaults.profile.Text, ApplySettings),
						IndividualColor = LUI:NewColorNoAlpha("", "Vengeance Bar Text", 2, db.profile.Text.IndividualColor, module.defaults.profile.Text.IndividualColor, ApplySettings),
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
	if LUI.db.profile.oUF.Player.Vengeance then
		for k, v in pairs(LUI.db.profile.oUF.Player.Vengeance) do
			db.profile[k] = v
		end
		LUI.db.profile.oUF.Player.Vengeance = nil
	end
end

function module:OnEnable()
	SetVengeance()
	ApplySettings()
	
	LUIVengeance.max = 0
	LUIVengeance.value = 0
	
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
