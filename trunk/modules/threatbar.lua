--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: threat.lua
	Description: LUI Threat Bar
	Version....: 1.0
	Rev Date...: 29/07/2011 [dd/mm/yyyy]

	Edits:
		v1.0: Thaly
]]

-- External references.
local addonname, LUI = ...
local module = LUI:Module("Threat")
local Media = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists
local fontflags = {'OUTLINE', 'THICKOUTLINE', 'MONOCHROME', 'NONE'}

local _, class = UnitClass("player")

local db, dbd
local LUIThreat

local aggrocolors = {0, 1, 0, 1, 1, 0, 1, 0, 0}

local Update = function(bar)
	if db.TankHide and LUIVengeance and LUIVengeance:IsShown() then
		bar:SetAlpha(0)
		return
	end
	
	if not UnitAffectingCombat("target") or not UnitCanAttack("player", "target") then
		bar:SetAlpha(0)
		return
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
	
	if db.Color == "Gradient" then
		local r, g, b = oUF.ColorGradient(threat/100, 0, 1, 0, 1, 1, 0, 1, 0, 0)
		local mu = db.BGMultiplier or 0
		bar:SetStatusBarColor(r, g, b)
		if bar.bg then bar.bg:SetVertexColor(r * mu, g * mu, b * mu) end
	end
				
	if db.Text.Enable then
		bar.Text:SetFormattedText("%d%%", rawthreat)
	else
		bar.Text:SetText()
	end
	
	if db.Text.Color == "Gradient" then
		bar.Text:SetTextColor(oUF.ColorGradient(threat/100, 0, 1, 0, 1, 1, 0, 1, 0, 0))
	end
end

local SetThreat = function()
	if LUIThreat then return end
	
	LUIThreat = CreateFrame("StatusBar", "LUIThreat", UIParent)
	
	LUIThreat.bg = LUIThreat:CreateTexture(nil, "BORDER")
	LUIThreat.bg:SetAllPoints(LUIThreat)
	
	LUIThreat.Text = LUIThreat:CreateFontString(nil, "OVERLAY")
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
		end
	end)
end

local ApplySettings = function()
	local r, g, b
	local mu = db.BGMultiplier
	if db.Color == "By Class" then
		r, g, b = unpack(LUI.oUF_LUI.colors.class[class])
	elseif db.Color == "Individual" then
		r, g, b = db.IndividualColor.r, db.IndividualColor.g, db.IndividualColor.b
	end
	
	LUIThreat:SetWidth(LUI:Scale(db.Width))
	LUIThreat:SetHeight(LUI:Scale(db.Height))
	LUIThreat:ClearAllPoints()
	LUIThreat:SetPoint("BOTTOM", UIParent, "BOTTOM", LUI:Scale(db.X), LUI:Scale(db.Y))
	LUIThreat:SetStatusBarTexture(Media:Fetch("statusbar", db.Texture))
	if r then LUIThreat:SetStatusBarColor(r, g, b) end
	
	LUIThreat.bg:SetTexture(Media:Fetch("statusbar", db.TextureBG))
	if r then LUIThreat.bg:SetVertexColor(r * mu, g * mu, b * mu) end
	
	if db.Text.Color == "By Class" then
		r, g, b = unpack(colors.class[class])
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

module.optionsName = "Threat Bar"
module.defaults = {
	profile = {
		Enable = true,
		Width = "384",
		Height = "4",
		X = "0",
		Y = "12",
		Texture = "LUI_Gradient",
		Color = "By Class",
		TankHide = true,
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
						XValue = LUI:NewPosX("Threat Bar", 1, db, "", dbd, ApplySettings),
						YValue = LUI:NewPosY("Threat Bar", 2, db, "", dbd, ApplySettings),
						Width = LUI:NewWidth("Threat Bar", 3, db, nil, dbd, ApplySettings),
						Height = LUI:NewHeight("Threat Bar", 4, db, nil, dbd, ApplySettings),
						TankHide = LUI:NewToggle("Hide if Tanking", "Whether you want to hide the Threat Bar if you are tank specced or not.", 5, db, "TankHide", dbd, ApplySettings),
					}
				},
				Colors = {
					name = "Color",
					type = "group",
					guiInline = true,
					order = 2,
					args = {
						ColorType = LUI:NewSelect("Color", "Choose the Color Option for your Threat Bar.", 1, {"By Class", "Individual", "Gradient"}, nil, db, "Color", dbd, ApplySettings),
						Color = LUI:NewColorNoAlpha("Individual", barName, 2, db.IndividualColor, dbd.IndividualColor, ApplySettings, nil, function() return (db.Color ~= "Individual") end),
					}
					
				},
				Textures = {
					name = "Texture",
					type = "group",
					guiInline = true,
					order = 3,
					args = {
						Texture = LUI:NewSelect("Texture", "Choose the Threat Bar Texture.", 1, widgetLists.statusbar, "LSM30_Statusbar", db, "Texture", dbd, ApplySettings),
						BGTexture = LUI:NewSelect("Background Texture", "Choose the Threat Bar Background Texture.", 2, widgetLists.statusbar, "LSM30_Statusbar", db, "BGTexture", dbd, ApplySettings),
						BGMultiplier = LUI:NewSlider("Background Multiplier", "Choose the Multiplier which will be used to generate the Background Color", 3, db, "BGMultiplier", dbd, 0, 1, 0.05, ApplySettings),
					}
				}
			}
		},
		Text = {
			name = "Text",
			type = "group",
			order = 3,
			args = {
				Enable = LUI:NewToggle("Enable Text", "Whether you want to show the Threat Bar Text or not.", 1, db.Text, "Enable", dbd.Text, ApplySettings),
				FontSettings = {
					name = "Font Settings",
					type = "group",
					guiInline = true,
					order = 2,
					disabled = function() return not db.Text.Enable end,
					args = {
						FontSize = LUI:NewSlider("Size", "Choose your Threat Bar Text Fontsize.", 1, db.Text, "Size", dbd.Text, 1, 40, 1, ApplySettings),
						empty = LUI:NewEmpty(2),
						Font = LUI:NewSelect("Font", "Choose your Threat Bar Text Font.", 3, widgetLists.font, "LSM30_Font", db.Text, "Font", dbd.Text, ApplySettings),
						FontFlag = LUI:NewSelect("Font Flag", "Choose the Font Flag for the Threat Bar Text Font.", 4, fontflags, nil, db.Text, "Outline", dbd.Text, ApplySettings),
					},
				},
				Settings = {
					name = "Settings",
					type = "group",
					guiInline = true,
					order = 3,
					disabled = function() return not db.Text.Enable end,
					args = {
						XValue = LUI:NewPosX("Threat Bar Text", 1, db.Text, "", dbd.Text, ApplySettings),
						YValue = LUI:NewPosY("Threat Bar Text", 2, db.Text, "", dbd.Text, ApplySettings),
					}
				},
				Color = {
					name = "Color Settings",
					type = "group",
					guiInline = true,
					order = 4,
					disabled = function() return not db.Text.Enable end,
					args = {
						Color = LUI:NewSelect("Color", "Choose the Color Option for the Threat Bar Text.", 1, {"By Class", "Individual", "Gradient"}, nil, db.Text, "Color", dbd.Text, ApplySettings),
						IndividualColor = LUI:NewColorNoAlpha("", "Threat Bar Text", 2, db.Text.IndividualColor, dbd.Text.IndividualColor, ApplySettings),
					}
				}
			}
		}
	}
	
	return options
end

function module:OnInitialize()
	db, dbd = LUI:NewNamespace(self, true)
	
	-- Look for outdated db vars and transfer them over
	if LUI.db.profile.oUF.Player.ThreatBar then
		for k, v in pairs(LUI.db.profile.oUF.Player.ThreatBar) do
			db[k] = v
		end
		LUI.db.profile.oUF.Player.ThreatBar = nil
	end
end

function module:OnEnable()
	SetThreat()
	ApplySettings()
	
	LUIThreat:RegisterEvent("PLAYER_REGEN_ENABLED")
	LUIThreat:RegisterEvent("PLAYER_REGEN_DISABLED")
	LUIThreat:SetScript("OnUpdate", Update)
	
	LUIThreat:Hide()
end

function module:OnDisable()
	LUIThreat:UnregisterAllEvents()
	LUIThreat:SetScript("OnUpdate", nil)
	
	LUIThreat:Hide()
end
