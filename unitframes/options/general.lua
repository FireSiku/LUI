--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: general.lua
	Description: oUF General Options
]]

local addonname, LUI = ...
local module = LUI:Module("Unitframes")
local Fader = LUI:Module("Fader")
local Forte = LUI:Module("Forte")

local oUF = LUI.oUF
local Blizzard = LUI.Blizzard

local _, class = UnitClass("player")

local widgetLists = AceGUIWidgetLSMlists

local units = {"Player", "Target", "ToT", "ToToT", "Focus", "FocusTarget", "Pet", "PetTarget", "Party", "PartyTarget", "PartyPet", "Boss", "BossTarget", "Maintank", "MaintankTarget", "MaintankToT", "Arena", "ArenaTarget", "ArenaPet", "Raid"}

local iconlist = {
	PvP = {"PvP"},
	Combat = {"Combat"},
	Resting = {"Resting"},
	Lootmaster = {"MasterLooter"},
	Leader = {"Leader", "Assistant"},
	Role = {"LFDRole"},
	Raid = {"RaidIcon"},
	ReadyCheck = {"ReadyCheck"},
}

-- needed for moving frames and some other things
local ufMover = {
	Party = "oUF_LUI_party",
	Boss = "oUF_LUI_boss",
	Maintank = "oUF_LUI_maintank",
	Arena = "oUF_LUI_arena",
	Player = "oUF_LUI_player",
	Target = "oUF_LUI_target",
	ToT = "oUF_LUI_targettarget",
	ToToT = "oUF_LUI_targettargettarget",
	Focus = "oUF_LUI_focus",
	FocusTarget = "oUF_LUI_focustarget",
	Pet = "oUF_LUI_pet",
	PetTarget = "oUF_LUI_pettarget",
	Raid = "oUF_LUI_raid",
}

local barColors = {
	Health = {"By Class", "Gradient", "Individual"},
	Power = {"By Class", "By Type", "Individual"}
}

local barKeys = {
	Runes = "Runes",
	HolyPower = "ClassIcons",
	AltPower = "AltPowerBar",
	DruidMana = "DruidMana",
	WarlockBar = "ClassIcons",
	ArcaneCharges = "ClassIcons",
	Chi = "ClassIcons",
}

local barNames = {
	Runes = "Runes",
	HolyPower = "Holy Power",
	AltPower = "Alternate Power",
	DruidMana = "Druid Mana",
	ArcaneCharges = "Arcane Charges",
	WarlockBar = "Warlock Bars",
	Chi = "Chi",
}

local _, class = UnitClass("player")
if class == "ROGUE" or class == "DRUID" then
	barNames.Chi = "Combo Points"
end

local fontflags = {"OUTLINE", "THICKOUTLINE", "MONOCHROME", "NONE"}
local directions = {"TOP", "BOTTOM", "RIGHT", "LEFT"}
local positions = {"TOP", "TOPRIGHT", "TOPLEFT", "BOTTOM", "BOTTOMRIGHT", "BOTTOMLEFT", "RIGHT", "LEFT", "CENTER"}
local justifications = {"RIGHT", "LEFT", "CENTER"}
local valueFormat = {"Absolut", "Absolut & Percent", "Absolut Short", "Absolut Short & Percent", "Standard", "Standard & Percent", "Standard Short", "Standard Short & Percent"}
local nameFormat = {"Name", "Name + Level", "Name + Level + Class", "Name + Level + Race + Class", "Level", "Level + Name", "Level + Name + Class", "Level + Class + Name", "Level + Name + Race + Class", "Level + Race + Class + Name"}
local nameLenghts = {"Short", "Medium", "Long"}
local growthY = {"UP", "DOWN"}
local growthX = {"LEFT", "RIGHT"}

function module.ToggleRangeFadeParty(enable) -- when the option calls this func, self will be info arg, so don't use self in here.
	enable = enable or module.db.Party.RangeFade

	for i, frame in ipairs(oUF_LUI_party) do
		if enable then
			frame.Range = frame.Range or {insideAlpha = 1, outsideAlpha = 0.5}
			frame:EnableElement("Range")
		else
			frame:DisableElement("Range")
			if frame.Range and (frame:GetAlpha() ~= frame.Range.insideAlpha) then
				frame:SetAlpha(frame.Range.insideAlpha)
			end
		end
	end
end

--------------------------------------------------------------------------
--  Bar Option Constructors
--------------------------------------------------------------------------

-- barType: "XP", "Rep"
function module:CreateXpRepOptionsPart(barType, order)
	local barKey = (barType == "XP") and "Experience" or "Reputation"

	local disabledFunc = function() return not self.db.XP_Rep[barKey].Enable end

	local toggleFunc
	if barType == "XP" then
		toggleFunc = function()
			if not oUF_LUI_player.XP then module.funcs.Experience(oUF_LUI_player, oUF_LUI_player.__unit, xprepdb) end
			if self.db.XP_Rep.Experience.Enable and UnitLevel("player") ~= MAX_PLAYER_LEVEL then
				oUF_LUI_player.Experience:ForceUpdate()
				oUF_LUI_player.XP:Show()
				if oUF_LUI_player.Rep then oUF_LUI_player.Rep:Hide() end
			else
				oUF_LUI_player.XP:Hide()
				if oUF_LUI_player.Rep then
					if self.db.XP_Rep.Reputation.Enable then
						oUF_LUI_player.Rep:Show()
					else
						oUF_LUI_player.Rep:Hide()
					end
				end
			end
			oUF_LUI_player.XP.Enable = self.db.XP_Rep.Experience.Enable
		end
	else
		toggleFunc = function()
			if not oUF_LUI_player.Rep then module.funcs.Reputation(oUF_LUI_player, oUF_LUI_player.__unit, xprepdb) end
			if self.db.XP_Rep.Reputation.Enable then
				oUF_LUI_player.Reputation:ForceUpdate()
				oUF_LUI_player.Rep:Show()
				if oUF_LUI_player.XP then oUF_LUI_player.XP:Hide() end
			else
				oUF_LUI_player.Rep:Hide()
				if oUF_LUI_player.XP then
					if self.db.XP_Rep.Experience.Enable and UnitLevel("player") ~= MAX_PLAYER_LEVEL then
						oUF_LUI_player.XP:Show()
					else
						oUF_LUI_player.XP:Hide()
					end
				end
			end
			oUF_LUI_player.Rep.Enable = self.db.XP_Rep.Reputation.Enable
		end
	end

	local applySettings = function()
		if oUF_LUI_player.XP then module.funcs.Experience(oUF_LUI_player, oUF_LUI_player.__unit, self.db.XP_Rep) end
		if oUF_LUI_player.Rep then module.funcs.Reputation(oUF_LUI_player, oUF_LUI_player.__unit, self.db.XP_Rep) end
	end

	local options = self:NewGroup(barType, order, {
		Enable = self:NewToggle("Enable", "Whether you want to show the "..barType.." Bar or not.", 1, toggleFunc, "full"),
		empty1 = self:NewDesc(" ", 2),
		ShowValue = self:NewToggle("Show Value", "Whether you want to show how much "..barType.." you have in the "..barType.." bar or not.", 3, applySettings, nil, disabledFunc),
		AlwaysShow = self:NewToggle("Always Show", "Whether you want the "..barType.." bar to show always or not.", 4, applySettings, nil, disabledFunc),
		BGColor = self:NewColor("Background", barType.."bar Background", 5, applySettings, nil, disabledFunc),
		FillColor = self:NewColor("Fill", barType.."bar Fill", 6, applySettings, nil, disabledFunc),
		RestedColor = (barType == "XP") and self:NewColor("Rested", barType.."bar Rested.", 7, applySettings, "full", disabledFunc) or nil,
		Alpha = self:NewSlider("Alpha", "Select the alpha of the "..barType.." bar when shown.", 8, 0, 1, 0.01, applySettings, true, nil, disabledFunc),
	})

	return options
end

function module:CreateXpRepOptions(order)
	local resetFunc = function()
		self.db.profile.XP_Rep = self.defaults.profile.XP_Rep
		StaticPopup_Show("RELOAD_UI")
	end

	local applySettings = function()
		if oUF_LUI_player.XP then module.funcs.Experience(oUF_LUI_player, oUF_LUI_player.__unit, self.db.XP_Rep) end
		if oUF_LUI_player.Rep then module.funcs.Reputation(oUF_LUI_player, oUF_LUI_player.__unit, self.db.XP_Rep) end
	end

	local options = self:NewGroup("XP / Rep", order, "tab", {
		Info = self:NewGroup("Info", 1, {
			About = self:NewDesc("The XP and Rep bars are located below the Player UnitFrame and will show on mouseover.\nThe Experience Bar will only be shown if you are not yet Level "..MAX_PLAYER_LEVEL..".\n\nIf you are not yet Level "..MAX_PLAYER_LEVEL.." you can right click on either bar to switch to the other.\nWhen you left click on one of the bars, information about that bar will be copied into your Chat EditBox if it is open and added to the Chat Window if not.\n\n\n", 1),
			Reset = self:NewExecute("Reset", nil, 2, resetFunc),
		}),
		Experience = self:CreateXpRepOptionsPart("XP", 2),
		Reputation = self:CreateXpRepOptionsPart("Rep", 3),
		General = self:NewGroup("Font", 4, {
			Font = self:NewSelect("Font", "Choose the Font for the XP/Rep text.", 1, widgetLists.font, "LSM30_Font", applySettings),
			FontSize = self:NewSlider("Font Size", "Choose the Font Size for the XP/Rep text.", 2, 6, 20, 1, applySettings),
			FontFlag = self:NewSelect("Font Flag", "Choose the Font Flag for the XP/Rep text.", 3, fontflags, nil, applySettings),
			FontJustify = self:NewSelect("Font Justify", "Choose the Font Justification for the XP/Rep text.", 4, justifications, nil, applySettings),
			FontColor = self:NewColor("Font", "XP/Rep text", 5, applySettings),
		}),
	})

	return options
end

function module:CreateHealPredictionOptions(unit, order)
	local disabledFunc = function() return not self.db[unit].Bars.HealPrediction.Enable end

	local applySettings = function()
		for _, frame in pairs(self.framelist[unit]) do
			if _G[frame] then
				module.funcs.HealPrediction(_G[frame], _G[frame].__unit, self.db[unit])
				if self.db[unit].Bars.HealPrediction.Enable then
					_G[frame]:EnableElement("HealPrediction")
				else
					_G[frame]:DisableElement("HealPrediction")
				end
				_G[frame]:UpdateAllElements()
			end
		end
	end

	local options = self:NewGroup("Heal Prediction", order, {
		Enable = self:NewToggle("Enable", "Whether you want to show predicted Heals on "..unit.." or not.", 1, applySettings, "full"),
		MyColor = self:NewColor("My", "Heal Prediction Bar", 2, applySettings, nil, disabledFunc),
		OtherColor = self:NewColor("Other", "Heal Prediction Bar", 3, applySettings, nil, disabledFunc),
		empty1 = self:NewDesc(" ", 4),
		Texture = self:NewSelect("Texture", "Choose your Heal Prediction Texture.", 5, widgetLists.statusbar, "LSM30_Statusbar", applySettings, nil, disabledFunc),
	})

	return options
end

function module:CreateTotalAbsorbOptions(unit, order)
	local disabledFunc = function() return not self.db[unit].Bars.TotalAbsorb.Enable end

	local applySettings = function()
		for _, frame in pairs(self.framelist[unit]) do
			if _G[frame] then
				module.funcs.TotalAbsorb(_G[frame], _G[frame].__unit, self.db[unit])
				if self.db[unit].Bars.TotalAbsorb.Enable then
					_G[frame]:EnableElement("TotalAbsorb")
				else
					_G[frame]:DisableElement("TotalAbsorb")
				end
				_G[frame]:UpdateAllElements()
			end
		end
	end

	local options = self:NewGroup("Absorb Bar", order, {
		Enable = self:NewToggle("Enable", "Whether you want to show the Absorb Bar on "..unit.." or not.", 1, applySettings, "full"),
		MyColor = self:NewColor("My", "Absorb Bar", 2, applySettings, nil, disabledFunc),
		empty1 = self:NewDesc(" ", 4),
		Texture = self:NewSelect("Texture", "Choose your Absorb Bar Texture.", 5, widgetLists.statusbar, "LSM30_Statusbar", applySettings, nil, disabledFunc),
	})

	return options
end

-- barType: "Health", "Power", "Full"
function module:CreateBarOptions(unit, order, barType)
	local disabledFunc = (barType ~= "Health") and function() return not self.db[unit].Bars[barType].Enable end or nil
	local disabledColorFunc = (barType ~= "Full") and function() return not (self.db[unit].Bars[barType].Enable ~= false and self.db[unit].Bars[barType].Color == "Individual") end or nil

	local applySettings = function()
		for _, frame in pairs(self.framelist[unit]) do
			if _G[frame] then
				module.funcs[barType](_G[frame], _G[frame].__unit, self.db[unit])
				if barType == "Health" and _G[frame].HealPrediction then
					module.funcs.HealPrediction(_G[frame], _G[frame].__unit, self.db[unit])
				end
				_G[frame]:UpdateAllElements()
			end
		end
	end

	local toggleSmooth = function(info, Smooth)
		for _, frame in pairs(self.framelist[unit]) do
			if Smooth then
				if _G[frame] then _G[frame]:SmoothBar(_G[frame][barType]) end
			else
				if _G[frame] then _G[frame][barType].SetValue = _G[frame][barType].SetValue_ end
			end
		end
	end

	local options = self:NewGroup(barType, order, {
		Enable = (barType ~= "Health") and self:NewToggle("Enable", "Whether you want to show "..barType.."bar or not.", 1, applySettings, "full") or nil,
		empty1 = (barType ~= "Health") and self:NewDesc(" ", 2) or nil,
		Height = self:NewInputNumber("Height", "Choose the Height for your "..barType.."bar.", 3, applySettings, nil, disabledFunc),
		Width = self:NewInputNumber("Width", "Choose the Width for your "..barType.."bar.", 4, applySettings, nil, disabledFunc),
		X = self:NewInputNumber("X Value", "Choose the X Value for your "..barType.."bar.", 5, applySettings, nil, disabledFunc),
		Y = self:NewInputNumber("Y Value", "Choose the Y Value for your "..barType.."bar.", 6, applySettings, nil, disabledFunc),
		empty2 = self:NewDesc(" ", 7),
		Smooth = (barType ~= "Full") and self:NewToggle("Enable Smooth Bar Animation", "Whether you want to use Smooth Animations or not.", 8, toggleSmooth, nil, disabledFunc) or nil,
		IndividualColor = self:NewColorNoAlpha(barType.."bar", barType.."bar", 9, applySettings, nil, disabledColorFunc),
		Color = (barType ~= "Full") and self:NewSelect("Color", "Choose the Color Option for the "..barType.."bar.", 10, barColors[barType], nil, applySettings, nil, disabledFunc) or nil,
		Tapping = (unit == "Target" and barType == "Health") and self:NewToggle("Enable Tapping", "Whether you want to show tapped Healthbars or not.", 11, applySettings, nil, disabledFunc) or nil,
		empty3 = self:NewDesc(" ", 12),
		Texture = self:NewSelect("Texture", "Choose the "..barType.."bar Texture.", 13, widgetLists.statusbar, "LSM30_Statusbar", applySettings, nil, disabledFunc),
		TextureBG = (barType ~= "Full") and self:NewSelect("Background Texture", "Choose the "..barType.."bar Background Texture.", 14, widgetLists.statusbar, "LSM30_Statusbar", applySettings, nil, disabledFunc) or nil,
		BGAlpha = (barType ~= "Full") and self:NewSlider("Background Alpha", "Choose the Alpha for the "..barType.."bar Background.", 15, 0, 1, 0.01, applySettings, true, nil, disabledFunc) or nil,
		BGMultiplier = (barType ~= "Full") and self:NewSlider("Background Multiplier", "Choose the BG Multiplier used for calculation of the Background Color", 16, 0, 1, 0.01, applySettings, true, nil, disabledFunc) or nil,
		BGInvert = (barType ~= "Full") and self:NewToggle("Invert Colors", "Whether you want to invert the Background Color or not. Suggested for dark Bar Colors!", 17, applySettings, nil, disabledFunc) or nil,
	})

	return options
end

--barKey: Key in the ouf layout / the creator funcs
--barName: Shown Name in the options
--barType: Key in the options/db

--barType: Totems, Runes, HolyPower, Eclipse, ShadowOrbs, ArcaneCharges, WarlockBars
function module:CreatePlayerBarOptions(barType, order)
	local barName = barNames[barType]
	local barKey = barKeys[barType]

	local isLocked = function() return not self.db.Player.Bars[barType].Enable or self.db.Player.Bars[barType].Lock end

	local disabledFunc = function() return not self.db.Player.Bars[barType].Enable end

	local applySettings = function(info, Enable)
		self.funcs[barKey](oUF_LUI_player, oUF_LUI_player.__unit, self.db.Player)
		if info[5] == "Enable" then
			if Enable then
				oUF_LUI_player:EnableElement(barKey)
				if barType == "Runes" then
					Blizzard:Hide("runebar")
				elseif barType == "Totems" then
					oUF_LUI_player[barKey]:Show()
				end
			else
				oUF_LUI_player:DisableElement(barKey)
				if barType == "Runes" then
					Blizzard:Show("runebar")
				elseif barType == "Totems" then
					oUF_LUI_player[barKey]:Hide()
				end
			end
		end
		Forte:SetPosForte()
		oUF_LUI_player:UpdateAllElements()
	end

	local options = self:NewGroup(barName, order, {
		Enable = self:NewToggle("Enable", "Whether you want to show the "..barName.." or not", 1, applySettings, "full"),
		empty1 = self:NewDesc(" ", 2),
		Lock = self:NewToggle("Lock", "Whether you want to lock the "..barName.." to your PlayerFrame or not.\nIf locked, Forte Spelltimer will adjust automaticly", 3, applySettings, "full", disabledFunc),
		X = self:NewInputNumber("X Value", "Choose the X Value for your "..barName..".", 4, applySettings, nil, isLocked),
		Y = self:NewInputNumber("Y Value", "Choose the Y Value for your "..barName..".", 5, applySettings, nil, isLocked),
		Width = self:NewInputNumber("Width", "Choose the Width for your "..barName..".", 6, applySettings, nil, disabledFunc),
		Height = self:NewInputNumber("Height", "Choose the Height for your "..barName..".", 7, applySettings, nil, disabledFunc),
		empty2 = self:NewDesc(" ", 8),
		Padding = (barType ~= "Eclipse") and self:NewSlider("Padding", "Choose the Padding between your "..barName.." Elements.", 9, 1, 10, 1, applySettings, nil, nil, disabledFunc) or nil,
		Texture = self:NewSelect("Texture", "Choose the "..barName.." Texture.", 10, widgetLists.statusbar, "LSM30_Statusbar", applySettings, nil, disabledFunc),
		Multiplier = (barType == "Totems") and self:NewSlider("Multiplier", "Choose the "..barName.." Background Multiplier.", 11, 0, 1, 0.01, applySettings, nil, nil, disabledFunc) or nil,
	})

	return options
end

-- barType: "DruidMana", "AltPower"
function module:CreatePlayerBarOverlappingOptions(barType, order)
	local barName = barNames[barType]
	local barKey = barKeys[barType]

	local disabledFunc = function() return not module.db.Player.Bars[barType].Enable end
	local disabledFunc2 = function() return not (module.db.Player.Bars[barType].Enable or not module.db.Player.Bars[barType].OverPower) end

	local values = (barType == "DruidMana") and {
		["By Class"] = "By Class",
		["By Type"] = "By Type",
		["Gradient"] = "Gradient"
	} or {
		["By Class"] = "By Class",
		["By Type"] = "By Type",
		["Individual"] = "Individual"
	}

	local applySettings = function()
		module.funcs[barKey](oUF_LUI_player, oUF_LUI_player.__unit, self.db.Player)
		if oUF_LUI_pet and barType == "AltPower" then module.funcs[barKey](oUF_LUI_pet, oUF_LUI_pet.__unit, self.db.Player) end
		if self.db.Player.Bars[barType].Enable then
			oUF_LUI_player:EnableElement(barKey)
			if oUF_LUI_pet and barType == "AltPower" then oUF_LUI_pet:EnableElement(barKey) end
		else
			oUF_LUI_player:DisableElement(barKey)
			if oUF_LUI_pet and barType == "AltPower" then oUF_LUI_pet:DisableElement(barKey) end
		end
	end

	local smoothBar = function(self, Smooth)
		if barType == "DruidMana" then
			if Smooth then
				oUF_LUI_player:SmoothBar(oUF_LUI_player.DruidMana)
			else
				oUF_LUI_player.DruidMana.SetValue = oUF_LUI_player.DruidMana.SetValue_
			end
		else
			if Smooth then
				oUF_LUI_player:SmoothBar(oUF_LUI_player.AltPowerBar)
				if oUF_LUI_pet then oUF_LUI_pet:SmoothBar(oUF_LUI_pet.AltPowerBar) end
			else
				oUF_LUI_player.AltPowerBar.SetValue = oUF_LUI_player.AltPowerBar.SetValue_
				if oUF_LUI_pet then oUF_LUI_pet.AltPowerBar.SetValue = oUF_LUI_pet.AltPowerBar.SetValue_ end
			end
		end
	end

	local options = self:NewGroup(barName, order, {
		Enable = self:NewToggle("Enable", "Whether you want to show the "..barName.." Bar or not.", 1, applySettings, "full"),
		empty1 = self:NewDesc(" ", 2),
		OverPower = self:NewToggle("Over Power Bar", "Whether you want the "..barName.." Bar to take up half the Power bar or not.\n\nNote: This option disables other OverPower options!", 3, applySettings, nil, disabledFunc),
		X = self:NewInputNumber("X Value", "Choose the X Value for your "..barName.." Bar.", 4, applySettings, nil, disabledFunc),
		Y = self:NewInputNumber("Y Value", "Choose the Y Value for your "..barName.." Bar.", 5, applySettings, nil, disabledFunc),
		Width = self:NewInputNumber("Width", "Choose the Width for your "..barName.." Bar.", 6, applySettings, nil, disabledFunc),
		Height = self:NewInputNumber("Height", "Choose the Height for your "..barName.." Bar.", 7, applySettings, nil, disabledFunc),
		Smooth = self:NewToggle("Enable Smooth Bar Animation", "Whether you want to use Smooth Animations or not.", 8, smoothBar, nil, disabledFunc),
		Color = self:NewSelect("Color", "Choose the Color Option for the "..barName.." Bar.", 9, values, nil, applySettings, nil, disabledFunc),
		empty3 = self:NewDesc(" ", 10),
		Texture = self:NewSelect("Texture", "Choose the Texture for the "..barName.." Bar.", 11, widgetLists.statusbar, "LSM30_Statusbar", applySettings, nil, disabledFunc),
		TextureBG = self:NewSelect("Background Texture", "Choose the Background Texture for the "..barName.." Bar.", 12, widgetLists.statusbar, "LSM30_Statusbar", applySettings, nil, disabledFunc),
		BGAlpha = self:NewSlider("Background Alpha", "Choose the Alpha Value for the "..barName.." Bar Background.", 13, 0, 1, 0.01, applySettings, true, nil, disabledFunc),
		BGMultiplier = self:NewSlider("Background Multiplier", "Choose the Multiplier for the "..barName.." Bar Background.", 14, 0, 1, 0.01, applySettings, true, nil, disabledFunc),
	})

	return options
end

function module:CreateComboPointsOptions(order)
	local disabledFunc = function() return not self.db.Target.Bars.ComboPoints.Enable end

	local isLocked = function() return not self.db.Target.Bars.ComboPoints.Enable or self.db.Target.Bars.ComboPoints.Lock end

	local applySettings = function(info, Enable)
		module.funcs.CPoints(oUF_LUI_target, oUF_LUI_target.__unit, self.db.Target)
		if info[5] == "Enable" then
			if Enable then
				oUF_LUI_target:EnableElement("CPoints")
			else
				oUF_LUI_target:DisableElement("CPoints")
			end
		end
		Forte:SetPosForte()
		oUF_LUI_target:UpdateAllElements()
	end

	local options = self:NewGroup("Combo Points", order, {
		Enable = self:NewToggle("Enable", "Whether you want to show your Combo Points or not.", 1, applySettings, "full"),
		empty1 = self:NewDesc(" ", 2),
		ShowAlways = self:NewToggle("Show Always", "Whether you want to always show your Combo Points or not.", 3, applySettings, nil, disabledFunc),
		Lock = self:NewToggle("Lock", "Whether you want to lock the Combo Points to your TargetFrame or not.\nIf locked, Forte Spelltimer will adjust automaticly", 4, applySettings, "full", disabledFunc),
		empty2 = self:NewDesc(" ", 5),
		X = self:NewInputNumber("X Value", "Choose the X Value for your Combo Points.", 6, applySettings, nil, isLocked),
		Y = self:NewInputNumber("Y Value", "Choose the Y Value for your Combo Points.", 7, applySettings, nil, isLocked),
		Width = self:NewInputNumber("Width", "Choose the Width for your Combo Points.", 8, applySettings, nil, disabledFunc),
		Height = self:NewInputNumber("Height", "Choose the Height for your Combo Points.", 9, applySettings, nil, disabledFunc),
		Padding = self:NewInputNumber("Padding", "Choose the Padding between your Combo Point Segments.", 10, applySettings, nil, disabledFunc),
		empty3 = self:NewDesc(" ", 11),
		Texture = self:NewSelect("Texture", "Choose your Combo Points Texture.", 12, widgetLists.statusbar, "LSM30_Statusbar", applySettings, nil, disabledFunc),
		Multiplier = self:NewSlider("Multiplier", "Choose your Combo Points Background Multiplier", 13, 0, 1, 0.01, applySettings, true, nil, disabledFunc),
		IndividualBGColor = self:NewToggle("Individual Background Color", "Whether you want to use an individual Background Color or not.", 14, applySettings, nil, disabledFunc),
		BackgroundColor = self:NewColorNoAlpha("Combo Points Background", nil, 15, applySettings, nil, function() return not (self.db.Target.Bars.ComboPoints.Enable or self.db.Target.Bars.ComboPoints.IndividualColor) end),
	})

	return options
end

------------------------------------------------------------------------
--	Text Options Constructors
------------------------------------------------------------------------

function module:CreateNameTextOptions(unit, order)
	local disabledNameFunc = function() return not self.db[unit].Texts.Name.Enable end

	local applyInfoText = function()
		for _, frame in pairs(self.framelist[unit]) do
			if _G[frame] then
				module.funcs.Info(_G[frame], _G[frame].__unit, self.db[unit])
				if self.db[unit].Texts.Name.Enable then
					_G[frame].Info:Show()
				else
					_G[frame].Info:Hide()
				end
			end
		end
	end

	local options = self:NewGroup("Name", 1, {
		Enable = self:NewToggle("Enable", "Whether you want to show the "..unit.." Name or not.", 1, applyInfoText, "full"),
		empty1 = self:NewDesc(" ", 2),
		Font = self:NewSelect("Font", "Choose the Font for "..unit.." Name.", 3, widgetLists.font, "LSM30_Font", applyInfoText, nil, disabledTextFunc),
		Size = self:NewSlider("Size", "Choose the "..unit.." Name Fontsize.", 4, 1, 40, 1, applyInfoText, nil, nil, disabledTextFunc),
		Outline = self:NewSelect("Font Flag", "Choose the Font Flag for "..unit.." Name.", 5, fontflags, nil, applyInfoText, nil, disabledTextFunc),
		empty2 = self:NewDesc(" ", 6),
		X = self:NewInputNumber("X Value", "Choose the X Value for your "..unit.." Name.", 7, applyInfoText, nil, disabledTextFunc),
		Y = self:NewInputNumber("Y Value", "Choose the Y Value for your "..unit.." Name.", 8, applyInfoText, nil, disabledTextFunc),
		Point = self:NewSelect("Point", "Choose the Point for your "..unit.." Name.", 9, positions, nil, applyInfoText, nil, disabledTextFunc),
		RelativePoint = self:NewSelect("Relative Point", "Choose the Relative Point for your "..unit.." Name.", 10, positions, nil, applyInfoText, nil, disabledTextFunc),
		empty3 = self:NewDesc(" ", 11),
		Format = self:NewSelect("Format", "Choose the Format for your "..unit.." Name.", 12, nameFormat, nil, applyInfoText, nil, disabledTextFunc),
		Length = self:NewSelect("Length", "Choose the Length for your "..unit.." Name.", 13, nameLenghts, nil, applyInfoText, nil, disabledTextFunc),
		empty4 = self:NewDesc(" ", 14),
		ColorNameByClass = self:NewToggle("Color Name by Class", "Whether you want to color the "..unit.." Name by Class or not.", 15, applyInfoText, nil, disabledTextFunc),
		ColorClassByClass = self:NewToggle("Color Class by Class", "Whether you want to color the "..unit.." Class by Class or not.", 16, applyInfoText, nil, disabledTextFunc),
		ColorLevelByDifficulty = self:NewToggle("Color Level by Difficulty", "Whether you want to color the Level by Difficulty or not.", 17, applyInfoText, nil, disabledTextFunc),
		ShowClassification = self:NewToggle("Show Classifications", "Whether you want to show Classifications like Elite, Boss or not.", 18, applyInfoText, nil, disabledTextFunc),
		ShortClassification = self:NewToggle("Short Classifications", "Whether you want to show short Classifications or not.", 19, applyInfoText, nil, disabledTextFunc),
		empty5 = self:NewDesc(" ", 20),
		IndividualColor = self:NewColorNoAlpha("Name", "Name Text", 21, applyInfoText, nil, disabledTextFunc),
	})

	return options
end

function module:CreateRaidNameTextOptions(order)
	local disabledFunc = function() return not module.db.Raid.Texts.Name.Enable end

	local disabledColorFunc = function() return not (self.db.Raid.Texts.Name.Enable and self.db.Raid.Texts.Name.ColorByClass) end

	local applySettings = function()
		for _, frame in pairs(self.framelist.Raid) do
			if _G[frame] then
				module.funcs.RaidInfo(_G[frame], _G[frame].__unit, self.db.Raid)
				if self.db.Raid.Texts.Name.Enable then
					_G[frame].Info:Show()
				else
					_G[frame].Info:Hide()
				end
			end
		end
	end

	local options = self:NewGroup("Name", order, {
		Enable = self:NewToggle("Enable", "Whether you want to show the Raid Name or not.", 1, applySettings, "full"),
		empty1 = self:NewDesc(" ", 2),
		Font = self:NewSelect("Font", "Choose the Font for the Raid Name.", 3, widgetLists.font, "LSM30_Font", applySettings, nil, disabledFunc),
		Size = self:NewSlider("Size", "Choose the Raid Name Fontsize.", 4, 1, 40, 1, applySettings, nil, nil, disabledFunc),
		Outline = self:NewSelect("Font Flag", "Choose the Raid Name Fontflag.", 5, fontflags, nil, applySettings, nil, disabledFunc),
		empty2 = self:NewDesc(" ", 6),
		ColorByClass = self:NewToggle("Color Name by Class", "Whether you want to color the Raid Name by Class or not.", 7, applySettings, nil, disabledFunc),
		IndividualColor = self:NewColorNoAlpha("", "Name Text", 8, applySettings, nil, disabledColorFunc),
		empty3 = self:NewDesc(" ", 9),
		ShowDead = self:NewToggle("Show Dead/AFK/Disconnected", "Whether you want to switch the Name to Dead/AFK/Disconnected or not.", 10, applySettings, nil, disabledFunc),
		OnlyWhenFull = self:NewToggle("Only When Full", "This will only show the name text when the unit's health is at full.", 11, applySettings, nil, disabledFunc),
	})

	return options
end

-- parentName: "Health", "Power"
-- textType: "Value", "Percent", "Missing"
function module:CreateTextOptions(unit, order, parentName, textType)
	local textFunc = parentName..textType
	local textName = parentName.." "..textType
	if textType == "Value" then textType = "" end
	local textKey = parentName..textType

	local applySettings = function()
		for _, frame in pairs(self.framelist[unit]) do
			if _G[frame] then
				module.funcs[textFunc](_G[frame], _G[frame].__unit, self.db[unit])
				_G[frame]:UpdateAllElements()
			end
		end
	end

	local disabledFunc = function() return not self.db[unit].Texts[textKey].Enable end
	local disabledColorFunc = function() return not self.db[unit].Texts[textKey].Enable or self.db[unit].Texts[textKey].Color ~= "Individual" end

	local options = self:NewGroup(textName, order, {
		Enable = self:NewToggle("Enable", "Whether you want to show "..textName.." Value or not.", 1, applySettings, "full"),
		empty1 = self:NewDesc(" ", 2),
		Font = self:NewSelect("Font", "Choose the "..unit.." "..textName.." Font.", 3, widgetLists.font, "LSM30_Font", applySettings, nil, disabledFunc),
		Size = self:NewSlider("Font Size", "Choose the "..unit.." "..textName.." Fontsize.", 4, 1, 40, 1, applySettings, nil, nil, disabledFunc),
		Outline = self:NewSelect("Font Flag", "Choose the "..unit.." "..textName.." Fontflag.", 5, fontflags, nil, applySettings, nil, disabledFunc),
		empty2 = self:NewDesc(" ", 6),
		X = self:NewInputNumber("X Value", "Choose the X Value for your "..textName..".", 7, applySettings, nil, disabledFunc),
		Y = self:NewInputNumber("Y Value", "Choose the Y Value for your "..textName..".", 8, applySettings, nil, disabledFunc),
		Point = self:NewSelect("Point", "Choose the Point for your "..unit.." "..textName..".", 9, positions, nil, applySettings, nil, disabledFunc),
		RelativePoint = self:NewSelect("Relative Point", "Choose the Relative Point for your "..unit.." "..textName..".", 10, positions, nil, applySettings, nil, disabledFunc),
		empty3 = self:NewDesc(" ", 11),
		Format = (textType == "") and self:NewSelect("Format", "Choose the Format for the "..unit.." "..textName, 12, valueFormat, nil, applySettings, nil, disabledFunc) or nil,
		ShowAlways = (parentName == "Health") and self:NewToggle("Show Always", "Always show "..unit.." "..textName.." or just if the Unit has no MaxHP", 13, applySettings, nil, disabledFunc) or nil,
		ShowFull = (parentName == "Power") and self:NewToggle("Show Full", "Whether show "..unit.." "..textName.." when full or not.", 14, applySettings, nil, disabledFunc) or nil,
		ShowEmpty = (parentName == "Power") and self:NewToggle("Show Empty", "Whether show "..unit.." "..textName.." when empty or not.", 15, applySettings, nil, disabledFunc) or nil,
		ShowDead = (parentName == "Health" and textType ~= "Missing") and self:NewToggle("Show Dead/AFK/Disconnected", "Whether you want to switch the "..textName.." Value to Dead/AFK Disconnected or not.", 16, applySettings, nil, disabledFunc) or nil,
		empty4 = self:NewDesc(" ", 17),
		Color = self:NewSelect("Color", "Choose the Color Option for the "..textType.." Value.", 18, barColors[parentName], nil, applySettings, nil, disabledFunc),
		IndividualColor = self:NewColorNoAlpha("Individual", textType.." Value", 19, applySettings, nil, disabledColorFunc),
	})

	return options
end

function module:CreateCombatTextOptions(unit, order)
	local disabledCombatFunc = function() return not self.db[unit].Texts.Combat.Enable end

	local applyCombatFeedback = function()
		for _, frame in pairs(self.framelist[unit]) do
			if _G[frame] then module.funcs.CombatFeedbackText(_G[frame], _G[frame].__unit, self.db[unit]) end
		end
	end

	local options = self:NewGroup("Combat", order, {
		Enable = self:NewToggle("Enable", "Whether you want to show Combat Text on the "..unit.." Frame or not.", 1, applyCombatFeedback, "full"),
		empty1 = self:NewDesc(" ", 2),
		Size = self:NewSlider("Size", "Choose the "..unit.." Combat Text Fontsize.", 3, 1, 40, 1, applyCombatFeedback, nil, nil, disabledCombatFunc),
		Font = self:NewSelect("Font", "Choose the Font for "..unit.." Combat Text.", 4, widgetLists.font, "LSM30_Font", applyCombatFeedback, nil, disabledCombatFunc),
		Outline = self:NewSelect("Font Flag", "Choose the Font Flag for "..unit.." Combat Text.", 5, fontflags, nil, applyCombatFeedback, nil, disabledCombatFunc),
		empty2 = self:NewDesc(" ", 6),
		X = self:NewInputNumber("X Value", "Choose the X Value for your "..unit.." Combat Text.", 7, applyCombatFeedback, nil, disabledCombatFunc),
		Y = self:NewInputNumber("Y Value", "Choose the Y Value for your "..unit.." Combat Text.", 8, applyCombatFeedback, nil, disabledCombatFunc),
		Point = self:NewSelect("Point", "Choose the Point for your "..unit.." Combat Text.", 9, positions, nil, applyCombatFeedback, nil, disabledCombatFunc),
		RelativePoint = self:NewSelect("Relative Point", "Choose the Relative Point for your "..unit.." Combat Text.", 10, positions, nil, applyCombatFeedback, nil, disabledCombatFunc),
	})

	return options
end

--barKey: Key in the ouf layout / the creator funcs
--barName: Shown Name in the options
--barType: Key in the options/db
--barType: Eclipse, AltPower, PvP, DruidMana?

function module:CreatePlayerBarTextOptions(barType, order)
	local barName = barNames[barType]
	local barKey = barKeys[barType]

	local textformats = barType == "AltPower" and {
		Absolut = "Absolut",
		Percent = "Percent",
		Standard = "Standard"
	} or {
		Absolut = "Absolut",
		Standard = "Standard"
	}

	local disabledFunc = function() return not self.db.Player.Texts[barType].Enable end

	local applySettings = function()
		module.funcs[barKey](oUF_LUI_player, oUF_LUI_player.__unit, self.db.Player)
		if self.db.Player.Bars[barType].Enable then
			oUF_LUI_player:EnableElement(barKey)
		else
			oUF_LUI_player:DisableElement(barKey)
		end
		Forte:SetPosForte()
		oUF_LUI_player:UpdateAllElements()
	end

	local options = self:NewGroup(barName, order, nil, function() return not self.db.Player.Bars[barType].Enable end, {
		Enable = self:NewToggle("Enable", "Whether you want to show the "..barType.." Bar Text or not.", 1, applySettings, "full"),
		empty1 = self:NewDesc(" ", 2),
		Font = self:NewSelect("Font", "Choose your "..barType.." Bar Text Font.", 3, widgetLists.font, "LSM30_Font", applySettings, nil, disabledFunc),
		Size = self:NewSlider("Size", "Choose your "..barType.." Bar Text Fontsize.", 4, 1, 40, 1, applySettings, nil, nil, disabledFunc),
		Outline = self:NewSelect("Font Flag", "Choose the Font Flag for the "..barType.." Bar Text.", 5, fontflags, nil, applySettings, nil, disabledFunc),
		empty2 = self:NewDesc(" ", 6),
		X = self:NewInputNumber("X Value", "Choose the X Value for your "..barName.." Bar Text.", 7, applySettings, nil, disabledFunc),
		Y = self:NewInputNumber("Y Value", "Choose the Y Value for your "..barName.." Bar Text.", 8, applySettings, nil, disabledFunc),
		empty3 = self:NewDesc(" ", 9),
		Format = (barType == "AltPower") and self:NewSelect("Format", "Choose the Format for the "..barType.." Bar Text.", 10, textformats, nil, applySettings, nil, disabledFunc) or nil,
		Color = (barType == "AltPower") and self:NewSelect("Color", "Choose the Color Option for the "..barType.." Bar Text.", 11, {["By Class"] = "By Class", ["Individual"] = "Individual"}, nil, applySettings, nil, disabledFunc) or nil,
		IndividualColor = (barType == "AltPower") and self:NewColorNoAlpha("", barType.." Bar Text", 12, applySettings, nil, disabledFunc) or nil,
	})

	return options
end

function module:CreatePvpTimerOptions(order)
	local disabledFunc = function() return not self.db.Player.Texts.PvP.Enable end

	local applySettings = function()
		module.funcs.PvP(oUF_LUI_player, oUF_LUI_player.__unit, self.db.Player)
		oUF_LUI_player:UpdateAllElements()
	end

	local options = self:NewGroup("PvP", order, nil, function() return not self.db.Player.Icons.PvP.Enable end, {
		Enable = self:NewToggle("Enable", "Whether you want to show a timer next to your PvP Icon when you're pvp flagged or not.", 1, applySettings, "full"),
		empty1 = self:NewDesc(" ", 2),
		Font = self:NewSelect("Font", "Choose your PvP Timer Text Font.", 3, widgetLists.font, "LSM30_Font", applySettings, nil, disabledFunc),
		Size = self:NewSlider("Size", "Choose your PvP Timer Text Fontsize.", 4, 1, 40, 1, applySettings, nil, nil, disabledFunc),
		Outline = self:NewSelect("Font Flag", "Choose the Font Flag for the PvP Timer Text.", 5, fontflags, nil, applySettings, nil, disabledFunc),
		empty2 = self:NewDesc(" ", 6),
		X = self:NewInputNumber("X Value", "Choose the X Value for your PvP Timer Text.", 7, applySettings, nil, disabledFunc),
		Y = self:NewInputNumber("Y Value", "Choose the Y Value for your PvP Timer Text.", 8, applySettings, nil, disabledFunc),
		empty3 = self:NewDesc(" ", 9),
		Color = self:NewColorNoAlpha("", "PvP Timer Text", 10, applySettings, nil, disabledFunc),
	})

	return options
end

function module:CreateDruidManaTimerOptions(order)
	local disabledFunc = function() return not self.db.Player.Texts.DruidMana.Enable end
	local disabledColorFunc = function() return not self.db.Player.Texts.DruidMana.Enable or self.db.Player.Texts.DruidMana.Color ~= "Individual" end

	local applySettings = function()
		module.funcs.DruidMana(oUF_LUI_player, oUF_LUI_player.__unit, self.db.Player)
		if oUF_LUI_player.AltPowerBar then oUF_LUI_player.AltPowerBar.SetPosition() end
		oUF_LUI_player.DruidMana.SetPosition()
		oUF_LUI_player:UpdateAllElements()
	end

	local options = self:NewGroup("Druid Mana", order, nil, function() return not self.db.Player.Bars.DruidMana.Enable end, {
		Enable = self:NewToggle("Enable", "Whether you want to show your Druid Mana Value while in Cat/Bear or not.", 2, applySettings),
		empty1 = self:NewDesc(" ", 2),
		Font = self:NewSelect("Font", "Choose your Druid Mana Bar Text Font.", 3, widgetLists.font, "LSM30_Font", applySettings, nil, disabledFunc),
		Size = self:NewSlider("Size", "Choose your Druid Mana Bar Text Fontsize.", 4, 1, 40, 1, applySettings, nil, nil, disabledFunc),
		Outline = self:NewSelect("Font Flag", "Choose the Font Flag for the Druid Mana Bar Text.", 5, fontflags, nil, applySettings, nil, disabledFunc),
		empty2 = self:NewDesc(" ", 6),
		X = self:NewInputNumber("X Value", "Choose the X Value for your Druid Mana Bar Text.", 7, applySettings, nil, disabledFunc),
		Y = self:NewInputNumber("Y Value", "Choose the Y Value for your Druid Mana Bar Text.", 8, applySettings, nil, disabledFunc),
		Point = self:NewSelect("Point", "Choose the Point for your Druid Mana Bar Text.", 9, positions, nil, applySettings, nil, disabledFunc),
		RelativePoint = self:NewSelect("Relative Point", "Choose the relative Point for your Druid Mana Bar Text.", 10, positions, nil, applySettings, nil, disabledFunc),
		empty3 = self:NewDesc(" ", 11),
		Format = self:NewSelect("Format", "Choose the Format for the Druid Mana Text.", 12, valueFormat, nil, applySettings, nil, disabledFunc),
		HideIfFullMana = self:NewToggle("Hide if Full Mana", "Whether you want to hide the Druid Mana Text when you have full Mana or not.", 13, applySettings, nil, disabledFunc),
		Color = self:NewSelect("Color", "Choose the Color Option for the Druid Mana Text", 14, barColors.Power, nil, applySettings, nil, disabledFunc),
		IndividualColor = self:NewColorNoAlpha("", "Druid Mana Text", 15, applySettings, nil, disabledColorFunc),
	})

	return options
end

------------------------------------------------------------------------
--	Other Options Constructors
------------------------------------------------------------------------

function module:CreateCastbarOptions(unit, order)
	local disabledFunc = function() return self.db.Settings.Castbars == false or self.db[unit].Enable == false end
	local disabledCastbarFunc = function() return not self.db[unit].Castbar.General.Enable end
	local disabledCastbarLatencyFunc = function() return not (self.db[unit].Castbar.General.Enable and self.db[unit].Castbar.General.Latency) end
	local disabledCastbarShieldFunc = function() return not (self.db[unit].Castbar.General.Enable and self.db[unit].Castbar.General.Shield) end
	local disabledCastbarShieldColorFunc = function() return not (self.db[unit].Castbar.General.Enable and self.db[unit].Castbar.General.Shield and self.db[unit].Castbar.Shield.IndividualColor) end
	local disabledCastbarShieldBorderFunc = function() return not (self.db[unit].Castbar.General.Enable and self.db[unit].Castbar.General.Shield and self.db[unit].Castbar.Shield.IndividualBorder) end
	local disabledCastbarNameFunc = function() return not (self.db[unit].Castbar.General.Enable and self.db[unit].Castbar.Text.Name.Enable) end
	local disabledCastbarTimeFunc = function() return not (self.db[unit].Castbar.General.Enable and self.db[unit].Castbar.Text.Time.Enable) end

	local applyCastbar = function()
		for _, frame in pairs(self.framelist[unit]) do
			if _G[frame] then
				module.funcs.Castbar(_G[frame], _G[frame].__unit, self.db[unit])
				if self.db[unit].Castbar.General.Enable then
					_G[frame]:EnableElement("Castbar")
					if unit == "Player" then
						Blizzard:Hide("castbar")
					end
				else
					_G[frame]:DisableElement("Castbar")
					_G[frame].Castbar:Hide()
					if unit == "Player" then
						Blizzard:Show("castbar")
					end
				end
				_G[frame]:UpdateAllElements()
			end
		end
	end

	local testCastbar = function()
		if _G[self.framelist[unit][1]]:IsShown() then
			for _, frame in pairs(self.framelist[unit]) do
				if _G[frame] and _G[frame].Castbar then
					_G[frame].Castbar.max = 60
					_G[frame].Castbar.duration = 0
					_G[frame].Castbar.delay = 0
					_G[frame].Castbar:SetMinMaxValues(0, 60)
					_G[frame].Castbar.casting = true
					_G[frame].Castbar.Text:SetText("Dummy Castbar")
					_G[frame].Castbar:PostCastStart(_G[frame].__unit, "Dummy Castbar")
					_G[frame].Castbar:Show()
				end
			end
		else
			LUI:Print("The "..unit.." Frame(s) must be shown for the dummy castbar to work.")
		end
	end

	local options = self:NewGroup("Castbar", order, "tab", nil, disabledFunc, {
		Test = self:NewExecute("Test Castbar", "Test the Castbar.", 1, testCastbar, nil, nil, disabledCastbarFunc),
		General = self:NewGroup("General", 2, {
			Enable = self:NewToggle("Enable", "Whether you want to show your "..unit.." Castbar or not.", 1, applyCastbar, "full"),
			empty1 = self:NewDesc(" ", 2),
			Width = self:NewInputNumber("Width", "Choose the Width for the Castbar.", 3, applyCastbar, nil, disabledCastbarFunc),
			Height = self:NewInputNumber("Height", "Choose the Height for the Castbar.", 4, applyCastbar, nil, disabledCastbarFunc),
			X = self:NewInputNumber("X Value", "Choose the X Value for the Castbar.", 5, applyCastbar, nil, disabledCastbarFunc),
			Y = self:NewInputNumber("Y Value", "Choose the Y Value for the Castbar.", 6, applyCastbar, nil, disabledCastbarFunc),
			Point = (unit == "Player" or unit == "Target") and self:NewSelect("Point", "Choose the Point for your Castbar.", 7, positions, nil, applyCastbar, nil, disabledCastbarFunc) or nil,
			empty2 = self:NewDesc(" ", 8),
			Texture = self:NewSelect("Texture", "Choose the Castbar Texture.", 9, widgetLists.statusbar, "LSM30_Statusbar", applyCastbar, nil, disabledCastbarFunc),
			TextureBG = self:NewSelect("Background Texture", "Choose the Castbar Background Texture.", 10, widgetLists.statusbar, "LSM30_Statusbar", applyCastbar, nil, disabledCastbarFunc),
			Latency = (unit == "Player") and self:NewToggle("Latency", "Whether you want to show the Latency or not.", 11, applyCastbar, nil, disabledCastbarFunc) or nil,
			Shield = self:NewToggle("Show Shielded Casts", "Whether you want to show casts you cannot interrupt.", 12, applyCastbar, nil, disabledCastbarFunc),
			IndividualColor = self:NewToggle("Individual Color", "Whether you want to use an individual Color or not.", 13, applyCastbar, nil, disabledCastbarFunc),
			Icon = self:NewToggle("Show Icon", "Whether you want to show the Castbar Icon or not.", 14, applyCastbar, nil, disabledCastbarFunc),
		}),
		Colors = self:NewGroup("Colors", 3, nil, function() return not (self.db[unit].Castbar.General.Enable and self.db[unit].Castbar.General.IndividualColor) end, {
			Bar = self:NewColor("Bar", "Castbar", 1, applyCastbar),
			Background = self:NewColor("Background", "Castbar Background", 2, applyCastbar),
			Border = self:NewColor("Border", "Castbar Border", 3, applyCastbar),
			Latency = (unit == "Player") and self:NewColor("Latency", "Casting Delay", 4, applyCastbar, nil, disabledCastbarLatencyFunc) or nil,
			empty1 = self:NewDesc(" ", 6),
			Name = self:NewColorNoAlpha("Name", "Spell Name", 7, applyCastbar, nil, disabledCastbarNameFunc),
			Time = self:NewColorNoAlpha("Time", "Cast Time", 8, applyCastbar, nil, disabledCastbarTimeFunc),
		}),
		Text = self:NewGroup("Texts", 4, nil, disabledCastbarFunc, {
			Name = self:NewGroup("Name", 1, true, {
				Enable = self:NewToggle("Enable", "Whether you want to show the Cast Name Text or not.", 1, applyCastbar, "full"),
				Font = self:NewSelect("Font", "Choose the Font for the Cast Name Text.", 2, widgetLists.font, "LSM30_Font", applyCastbar, nil, disabledCastbarNameFunc),
				Size = self:NewSlider("Size", "Choose the Font Size for the Cast Name Text.", 3, 1, 40, 1, applyCastbar, nil, nil, disabledCastbarNameFunc),
				OffsetX = self:NewInputNumber("X Value", "Choose the X Value for the Cast Name Text.", 4, applyCastbar, nil, disabledCastbarNameFunc),
				OffsetY = self:NewInputNumber("Y Value", "Choose the Y Value for the Cast Name Text.", 5, applyCastbar, nil, disabledCastbarNameFunc),
			}),
			Time = self:NewGroup("Time", 2, true, {
				Enable = self:NewToggle("Enable", "Whether you want to show the Cast Time Text or not.", 1, applyCastbar, "full"),
				Font = self:NewSelect("Font", "Choose the Font for the Cast Time Text.", 2, widgetLists.font, "LSM30_Font", applyCastbar, nil, disabledCastbarTimeFunc),
				Size = self:NewSlider("Size", "Choose the Font Size for the Cast Time Text.", 3, 1, 40, 1, applyCastbar, nil, nil, disabledCastbarTimeFunc),
				OffsetX = self:NewInputNumber("X Value", "Choose the X Value for the Cast Time Text.", 4, applyCastbar, nil, disabledCastbarTimeFunc),
				OffsetY = self:NewInputNumber("Y Value", "Choose the Y Value for the Cast Time Text.", 5, applyCastbar, nil, disabledCastbarTimeFunc),
				ShowMax = self:NewToggle("Show Max", "Whether you want to show the max Time or not.", 6, applyCastbar, "full", disabledCastbarTimeFunc),
			}),
		}),
		Border = self:NewGroup("Border", 5, nil, disabledCastbarFunc, {
			Texture = self:NewSelect("Border Texture", "Choose the Border Texture.", 1, widgetLists.border, "LSM30_Border", applyCastbar),
			Thickness = self:NewInputNumber("Border Thickness", "Value for your Castbar Border Thickness.", 2, applyCastbar),
			Inset = self:NewGroup("Insets", 3, true, {
				left = self:NewInputNumber("Left", "Value for the left Border Inset.", 1, applyCastbar, "half"),
				right = self:NewInputNumber("Right", "Value for the right Border Inset.", 2, applyCastbar, "half"),
				top = self:NewInputNumber("Top", "Value for the top Border Inset.", 3, applyCastbar, "half"),
				bottom = self:NewInputNumber("Bottom", "Value for the bottom Border Inset.", 4, applyCastbar, "half"),
			}),
		}),
		Shield = self:NewGroup("Shield", 6, nil, disabledCastbarShieldFunc, {
			IndividualColor = self:NewToggle("Set Bar Color", "Whether you want to set a different bar color for noninterruptible casts.", 3, applyCastbar, "normal", disabledCastbarShieldFunc),
			BarColor = self:NewColor("Bar", "noninterruptable casts", 4, applyCastbar, "normal", disabledCastbarShieldColorFunc),
			IndividualBorder = self:NewToggle("Set Border", "Whether you want to set a different border for noninterruptible casts.", 6, applyCastbar, "normal", disabledCastbarShieldFunc),
			Color = self:NewColor("Border", "noninterruptable casts", 7, applyCastbar, "normal", disabledCastbarShieldBorderFunc),
			Texture = self:NewSelect("Border Texture", "Choose the Border Texture.", 8, widgetLists.border, "LSM30_Border", applyCastbar, nil, disabledCastbarShieldBorderFunc),
			Thickness = self:NewInputNumber("Border Thickness", "Value for your Castbar Border Thickness.", 9, applyCastbar, nil, disabledCastbarShieldBorderFunc),
			Inset = self:NewGroup("Insets", 10, true, {
				left = self:NewInputNumber("Left", "Value for the left Border Inset.", 1, applyCastbar, "half", disabledCastbarShieldBorderFunc),
				right = self:NewInputNumber("Right", "Value for the right Border Inset.", 2, applyCastbar, "half", disabledCastbarShieldBorderFunc),
				top = self:NewInputNumber("Top", "Value for the top Border Inset.", 3, applyCastbar, "half", disabledCastbarShieldBorderFunc),
				bottom = self:NewInputNumber("Bottom", "Value for the bottom Border Inset.", 4, applyCastbar, "half", disabledCastbarShieldBorderFunc),
			}),
		}),
	})

	return options
end

-- type: "Buffs", "Debuffs"
function module:CreateAuraOptions(unit, order, type)
	local disabledFunc = function() return not self.db[unit].Aura[type].Enable end
	local disabledPetFunc = function() return not self.db[unit].Aura[type].Enable or not self.db[unit].Aura[type].PlayerOnly end
	local disabledOthersFunc = function() return not self.db[unit].Aura[type].Enable or self.db[unit].Aura[type].PlayerOnly end
	local disabledCDFunc = function() return not self.db[unit].Aura[type].Enable or self.db[unit].Aura[type].DisableCooldown end

	local applySettings = function()
		for _, frame in pairs(self.framelist[unit]) do
			if _G[frame] then
				module.funcs[type](_G[frame], _G[frame].__unit, self.db[unit])
				if self.db[unit].Aura[type].Enable then
					_G[frame]:EnableElement("Aura")
					_G[frame][type]:Show()
				else
					if self.db[unit].Aura.Buffs.Enable == false and self.db[unit].Aura.Debuffs.Enable == false then
						_G[frame]:DisableElement("Aura")
					end
					_G[frame][type]:Hide()
				end
				_G[frame]:UpdateAllElements()
			end
		end
	end

	local options = self:NewGroup(type, order, {
		Enable = self:NewToggle("Enable", "Whether you want to show "..unit.." "..type.." or not.", 1, applySettings, "full"),
		empty1 = self:NewDesc(" ", 2),
		X = self:NewInputNumber("X Value", "Choose the X Value for your "..unit.." "..type..".", 3, applySettings, nil, disabledFunc),
		Y = self:NewInputNumber("Y Value", "Choose the Y Value for your "..unit.." "..type..".", 4, applySettings, nil, disabledFunc),
		InitialAnchor = self:NewSelect("Initial Anchor", "Choose the initial Anchor for the "..unit.." "..type..".", 5, positions, nil, applySettings, nil, disabledFunc),
		GrowthX = self:NewSelect("Growth X", "Choose the Growth X direction for the "..unit.." "..type..".", 6, growthX, nil, applySettings, nil, disabledFunc),
		GrowthY = self:NewSelect("Growth Y", "Choose the Growth Y direction for the "..unit.." "..type..".", 7, growthY, nil, applySettings, nil, disabledFunc),
		empty2 = self:NewDesc(" ", 8),
		Size = self:NewInputNumber("Size", "Choose the Size for the "..unit.." "..type..".", 9, applySettings, nil, disabledFunc),
		Spacing = self:NewInputNumber("Spacing", "Choose the Spacing between your "..unit.." "..type..".", 10, applySettings, nil, disabledFunc),
		Num = self:NewInputNumber("Amount", "Choose the Amount of "..unit.." "..type.." you want to show.", 11, applySettings, nil, disabledFunc),
		empty3 = self:NewDesc(" ", 12),
		AuraTimer = self:NewToggle("Enable Auratimer", "Whether you want to show Auratimers or not.", 14, applySettings, "full", disabledFunc),
		PlayerOnly = self:NewToggle("Player "..type.." Only", "Whether you want to show only the "..type.." or not.", 15, applySettings, nil, disabledFunc),
		IncludePet = self:NewToggle("Include Pet "..type, "Whether you want to include Pet "..type.." or not.", 16, applySettings, nil, disabledPetFunc),
		FadeOthers = type == "Debuffs" and self:NewToggle("Fade Other's "..type, "Whether you want "..type.." cast by others be grayed out or not", 17, applySettings, nil, disabledOthersFunc) or nil,
		ColorByType = self:NewToggle("Color by Type", "Whether you want to color "..type.." by Type or not.", 18, applySettings, "full", disabledFunc),
		DisableCooldown = self:NewToggle("Hide Cooldown Spiral", "Whether you want to disable the cooldown spiral effect or not.", 19, applySettings, nil, disabledFunc),
		CooldownReverse = self:NewToggle("Reverse Cooldown Spiral", "Whether you want to reverse the cooldown spiral effect or not.", 20, applySettings, nil, disabledCDFunc),
	})

	return options
end

function module:CreatePortraitOptions(unit, order)
	local disabledFunc = function() return not self.db[unit].Enable end
	local disabledPortraitFunc = function() return not self.db[unit].Portrait.Enable end

	local applyPortrait = function()
		for _, frame in pairs(self.framelist[unit]) do
			if _G[frame] then
				module.funcs.Portrait(_G[frame], _G[frame].__unit, self.db[unit])
				if self.db[unit].Portrait.Enable == true then
					_G[frame]:EnableElement("Portrait")
					_G[frame].Portrait:Show()
				else
					_G[frame]:DisableElement("Portrait")
					_G[frame].Portrait:Hide()
				end
				_G[frame]:UpdateAllElements()
			end
		end
	end

	local options = self:NewGroup("Portrait", order, "tab", nil, disabledFunc, {
		Enable = self:NewToggle("Enable", "Whether you want to show the Portrait or not.", 1, applyPortrait, "full"),
		empty1 = self:NewDesc(" ", 2),
		Width = self:NewInputNumber("Width", "Choose the Width for the Portrait.", 3, applyPortrait, nil, disabledPortraitFunc),
		Height = self:NewInputNumber("Height", "Choose the Height for the Portrait.", 4, applyPortrait, nil, disabledPortraitFunc),
		X = self:NewInputNumber("X Value", "Choose the X Value for the Portrait.", 5, applyPortrait, nil, disabledPortraitFunc),
		Y = self:NewInputNumber("Y Value", "Choose the Y Value for the Portrait.", 6, applyPortrait, nil, disabledPortraitFunc),
		Alpha = self:NewSlider("Alpha", "Choose the Alpha for the Portrait.", 7, 0, 1, 0.01, applyPortrait, true, nil, disabledPortraitFunc),
	})

	return options
end

-- iconType: "PvP", "Combat", "Resting", "Lootmaster", "Leader", "Role", "Raid", "ReadyCheck"
function module:CreateIconOptions(unit, order, iconType)
	local disabledFunc = function() return not self.db[unit].Icons[iconType].Enable end

	local applySettings = function()
		for _, frame in pairs(self.framelist[unit]) do
			if _G[frame] then
				module.funcs[iconlist[iconType][1]](_G[frame], _G[frame].__unit, self.db[unit])
				for _, icon in pairs(iconlist[iconType]) do
					if self.db[unit].Icons[iconType].Enable then
						_G[frame]:EnableElement(icon)
						_G[frame]:UpdateAllElements()
					else
						_G[frame]:DisableElement(icon)
						_G[frame][icon]:Hide()
					end
				end
			end
		end
	end

	local showHideFunc = function()
		for _, frame in pairs(self.framelist[unit]) do
			if _G[frame] and _G[frame][iconlist[iconType][1]] then
				if _G[frame][iconlist[iconType][1]]:IsShown() then _G[frame][iconlist[iconType][1]]:Hide() else _G[frame][iconlist[iconType][1]]:Show() end
			end
		end
	end

	local options = self:NewGroup(iconType, order, {
		Enable = self:NewToggle("Enable", "Whether you want to show the "..iconType.." Icon or not.", 1, applySettings, "full"),
		empty1 = self:NewDesc(" ", 2),
		X = self:NewInputNumber("X Value", "Choose the X Value for your "..iconType.." Icon.", 3, applySettings, nil, disabledFunc),
		Y = self:NewInputNumber("Y Value", "Choose the Y Value for your "..iconType.." Icon.", 4, applySettings, nil, disabledFunc),
		Point = self:NewSelect("Point", "Choose the Point for your "..iconType.." Icon.", 5, positions, nil, applySettings, nil, disabledFunc),
		Size = self:NewSlider("Size", "Choose the Size for your "..iconType.." Icon.", 6, 5, 60, 1, applySettings, nil, nil, disabledFunc),
		empty2 = self:NewDesc(" ", 7),
		Toggle = self:NewExecute("Show/Hide", "Toggles the "..iconType.." Icon.", 8, showHideFunc, nil, nil, disabledFunc),
	})

	return options
end

function module:CreateUnitOptions(unit, order)
	local disabledFunc = function() return not self.db[unit].Enable end

	local disabledUnitFunc = function()
		if not self.db.Enable then return true end

		if unit == "MaintankToT" then
			return not (self.db.MaintankTarget.Enable and self.db.Maintank.Enable)
		elseif unit == "MaintankTarget" then
			return not self.db.Maintank.Enable
		elseif unit == "PartyTarget" or unit == "PartyPet" then
			return not self.db.Party.Enable
		elseif unit == "ArenaTarget" or unit == "ArenaPet" then
			return not self.db.Arena.Enable
		else
			return false
		end
	end

	local testFunc = function()
		if _G[self.framelist[unit][1]] and _G[self.framelist[unit][1]]:IsShown() then
			self["Hide"..unit.."Frames"](self)
		else
			self["Show"..unit.."Frames"](self)
		end
	end

	local generalGet = function(info)
		local x
		for i = 1, #info do
			x = i
			if info[i] == unit then break end
		end
		local t = module.db[unit]
		for i = x+1, #info do
			if info[i] ~= "General" then
				t = t[info[i]]
			end
		end
		if type(t) == "table" then
			if t.r then
				return t.r, t.g, t.b, t.a
			else
				return unpack(t)
			end
		elseif info[#info] == "GroupPadding" or info[#info] == "Padding" or info[#info] == "X" or info[#info] == "Y" or info[#info] == "Width" or info[#info] == "Height" or info[#info] == "Left" or info[#info] == "Top" or info[#info] == "Right" or info[#info] == "Bottom" then
			if type(t) ~= "number" then t = 0 end
			return tostring(tonumber(string.format("%.1f", t)))
		elseif info[#info] == "Point" or info[#info] == "RelativePoint" then
			for k, v in pairs(positions) do
				if v == t then return k end
			end
		elseif info[#info] == "GrowDirection" then
			for k, v in pairs(directions) do
				if v == t then return k end
			end
		else
			return t
		end
	end

	local generalSet = function(info, ...)
		local x
		for i = 1, #info do
			x = i
			if info[i] == unit then break end
		end
		local t = module.db[unit]
		for i = x+1, #info-1 do
			if info[i] ~= "General" then
				t = t[info[i]]
			end
		end
		if type(t[info[#info]]) == "table" then
			t = t[info[#info]]
			if t.r then
				t.r, t.g, t.b, t.a = ...
			else
				t[1], t[2], t[3], t[4] = ...
			end
		elseif info[#info] == "GroupPadding" or info[#info] == "Padding" or info[#info] == "X" or info[#info] == "Y" or info[#info] == "Width" or info[#info] == "Height" or info[#info] == "Left" or info[#info] == "Top" or info[#info] == "Right" or info[#info] == "Left" then
			local val = ...
			t[info[#info]] = tonumber(val)

		elseif info[#info] == "Point" or info[#info] == "RelativePoint" then
			local val = ...
			t[info[#info]] = positions[val]
		elseif info[#info] == "GrowDirection" then
			local val = ...
			t[info[#info]] = directions[val]
		else
			local val = ...
			t[info[#info]] = val
		end
		module.ToggleUnit(unit)
		module.ApplySettings(unit)

		if unit == "Player" or unit == "Target" or unit == "Focus" then
			Forte:SetPosForte();
		end
	end

	-- because of special way of get/set funcs, i add the default values manually here
	local options = self:NewGroup(unit, order * 2 + 10, "tab", nil, disabledUnitFunc, {
		header1 = self:NewHeader(unit, 1),
		General = self:NewGroup("General", 2, "tab", generalGet, generalSet, {
			General = self:NewGroup("General", 1, {
				Enable = (unit ~= "Player" and unit ~= "Target") and self:NewToggle("Enable", "Whether you want to show "..unit.." Frame(s) or not.\n\nDefault: "..(self.defaults[unit].Enable and "Enabled" or "Disabled"), 1, false, "full") or nil,
				UseBlizzard = (unit == "Party" or unit == "Boss" or unit == "Arena" or unit == "Raid") and self:NewToggle("Use Blizzard "..unit.." Frames", "Whether you want to use Blizzard "..unit.." Frames or not.", 2, false, "full", function() return self.db[unit].Enable end) or nil,
				ShowPlayer = (unit == "Party") and self:NewToggle("Show Player", "Whether you want to show yourself within the Party Frames or not.", 3, false, nil, disabledFunc) or nil,
				ShowInRaid = (unit == "Party") and self:NewToggle("Show in Raid", "Whether you want to show the Party Frames in Raid or not.", 4, false, nil, disabledFunc) or nil,
				ShowInRealPartys = (unit == "Party") and self:NewToggle("Show only in real Parties", "Whether you want to show the Party Frames only in real Parties or in Raids with 5 or less players too.", 5, false, nil, function() return not module.db.Party.Enable or module.db.Party.ShowInRaid end) or nil,
				empty1 = (unit ~= "Player" and unit ~= "Target") and self:NewDesc(" ", 6) or nil,
				Padding = (unit == "Party" or unit == "Boss" or unit == "Arena" or unit == "Maintank" or unit == "Raid") and self:NewInputNumber("Padding", "Choose the Padding between your "..unit.." Frames.\n\nDefault: "..self.defaults[unit].Padding, 7, false, nil, disabledFunc) or nil,
				GroupPadding = (unit == "Raid") and self:NewInputNumber("Group Padding", "Choose the Padding between your "..unit.." Groups.\n\nDefault: "..self.defaults[unit].GroupPadding, 8, false, nil, disabledFunc) or nil,
				GrowDirection = (unit == "Party" or unit == "Boss"or unit == "Arena" or unit == "Maintank") and self:NewSelect("Grow Direction", "Choose the Grow Direction for your "..unit.." Frames.\n\nDefault: "..self.defaults[unit].GrowDirection, 9, directions, nil, false, nil, disabledFunc) or nil,
				empty2 = (unit == "Party" or unit == "Boss" or unit == "Arena" or unit == "Maintank" or unit == "Raid") and self:NewDesc(" ", 10) or nil,
				X = self:NewInputNumber("X Value", "Choose the X Value for your "..unit.." Frame(s).\n\nDefault: "..self.defaults[unit].X, 11, false, nil, disabledFunc),
				Y = self:NewInputNumber("Y Value", "Choose the Y Value for your "..unit.." Frame(s).\n\nDefault: "..self.defaults[unit].Y, 12, false, nil, disabledFunc),
				Point = self:NewSelect("Point", "Choose the Point for your "..unit.." Frame(s).\n\nDefault: "..self.defaults[unit].Point, 13, positions, nil, false, nil, disabledFunc),
				RelativePoint = (not ufMover[unit]) and self:NewSelect("Relative Point", "Choose the relative Point for your "..unit.." Frame(s).\n\nDefault: "..self.defaults[unit].RelativePoint, 14, positions, nil, false, nil, disabledFunc) or nil,
				empty3 = self:NewDesc(" ", 15),
				Height = self:NewInputNumber("Height", "Choose the Height for your "..unit.." Frame(s).\n\nDefault: "..self.defaults[unit].Height, 16, false, nil, disabledFunc),
				Width = self:NewInputNumber("Width", "Choose the Width for your "..unit.." Frame(s).\n\nDefault: "..self.defaults[unit].Width, 17, false, nil, disabledFunc),
				Scale = (unit ~= "Raid" and ufMover[unit]) and self:NewSlider("Scale", "Choose the Scale for your "..unit.." Frame(s).\n\nDefault: 100%", 18, 0.1, 2, 0.01, false, nil, nil, disabledFunc) or nil,
				empty4 = (unit == "Arena" or unit == "Boss" or unit == "Maintank" or unit == "Party") and self:NewDesc(" ", 19) or nil,
				Toggle = (unit == "Arena" or unit == "Boss" or unit == "Maintank") and self:NewExecute("Show/Hide", "Toggles the "..unit.." Frames", 20, testFunc, nil, nil, disabledFunc) or nil,
				RangeFade = (unit == "Party") and self:NewToggle("Fade Out of Range", "Whether you want Party Frames to fade if that player is more than 40 yards away or not.", 21, false, nil, function() return not (self.db.Party.Enable and not self.db.Party.Fader.Enable) end) or nil,
				empty5 = self:NewHeader("Reset to Defaults", 22),
				ResetToDefaults = self:NewExecute("Reset to Defaults", "Reset this unitframe's settings to the defaults.\n\nRequires a UI reload.", 23, function() self.db[unit] = {} ReloadUI() end, true),
			}),
			Backdrop = self:NewGroup("Background", 2, nil, disabledFunc, {
				Color = self:NewColor("Background", nil, 1, false),
				Texture = self:NewSelect("Backdrop Texture", "Choose the Backdrop Texture.", 2, widgetLists.background, "LSM30_Background", false),
				Padding = self:NewGroup("Padding", 3, true, {
					Left = self:NewInputNumber("Left", "Value for the left Backdrop Padding.", 1, false, "half"),
					Right = self:NewInputNumber("Right", "Value for the right Backdrop Padding.", 2, false, "half"),
					Top = self:NewInputNumber("Top", "Value for the top Backdrop Padding.", 3, false, "half"),
					Bottom = self:NewInputNumber("Bottom", "Value for the bottom Backdrop Padding.", 4, false, "half"),
				}),
			}),
			Border = self:NewGroup("Border", 3, nil, disabledFunc, {
				Color = self:NewColor("Border", nil, 1, false),
				EdgeFile = self:NewSelect("Border Texture", "Choose the Border Texture.", 2, widgetLists.border, "LSM30_Border", false),
				EdgeSize = self:NewSlider("Edge Size", "Choose the Edge Size for the Frame Border.", 3, 1, 50, 1, false),
				Aggro = (unit == "Player" or unit == "Target" or unit == "Focus" or unit == "Pet" or unit == "Maintank" or unit == "Party" or unit == "PartyPet" or unit == "Raid") and self:NewToggle("Aggro Glow", "Whether you want the border color to change if the unit has aggro or not.", 4, false) or nil,
				Insets = self:NewGroup("Insets", 5, true, {
					Left = self:NewInputNumber("Left", "Value for the left Border Inset.", 1, false, "half"),
					Right = self:NewInputNumber("Right", "Value for the right Border Inset.", 2, false, "half"),
					Top = self:NewInputNumber("Top", "Value for the top Border Inset.", 3, false, "half"),
					Bottom = self:NewInputNumber("Bottom", "Value for the bottom Border Inset.", 4, false, "half"),
				}),
			}),
			--platz!
			AlphaFader = self.db[unit].Fader and self:NewGroup("Fader", 8, Fader:CreateFaderOptions(self.framelist[unit], self.db[unit].Fader, self.defaults[unit].Fader)) or nil,
			CopySettings = self:CreateCopyOptions(unit, 9),
		}),
		Bars = self:NewGroup("Bars", 3, "tab", nil, disabledFunc, {
			Health = self:CreateBarOptions(unit, 1, "Health"),
			Power = self:CreateBarOptions(unit, 2, "Power"),
			Full = self:CreateBarOptions(unit, 3, "Full"),
			HealPrediction = self.db[unit].Bars.HealPrediction and self:CreateHealPredictionOptions(unit, 4) or nil,
			TotalAbsorb = self.db[unit].Bars.TotalAbsorb and self:CreateTotalAbsorbOptions(unit, 5) or nil,
			DruidMana = ((class == "DRUID" or class == "PRIEST" or class == "SHAMAN") and unit == "Player") and self:CreatePlayerBarOverlappingOptions("DruidMana", 11) or nil,
			AltPower = (unit == "Player") and self:CreatePlayerBarOverlappingOptions("AltPower", 12) or nil,
			Runes = ((class == "DEATHKNIGHT" or class == "DEATH KNIGHT") and unit == "Player") and self:CreatePlayerBarOptions("Runes", 14) or nil,
			HolyPower = (class == "PALADIN" and unit == "Player") and self:CreatePlayerBarOptions("HolyPower", 15) or nil,
			WarlockBar = (class == "WARLOCK" and unit == "Player") and self:CreatePlayerBarOptions("WarlockBar", 16) or nil,
			ArcaneCharges = (class == "MAGE" and unit == "Player") and self:CreatePlayerBarOptions("ArcaneCharges", 16) or nil,
			Chi = ((class == "MONK" or class == "DRUID" or class == "ROGUE") and unit == "Player") and self:CreatePlayerBarOptions("Chi", 16) or nil,
			ComboPoints = (unit == "Target") and self:CreateComboPointsOptions(18) or nil,
		}),
		Texts = self:NewGroup("Texts", 4, "tab", nil, disabledFunc, {
			Name = (unit ~= "Raid") and self:CreateNameTextOptions(unit, 1) or self:CreateRaidNameTextOptions(1),
			Health = self:CreateTextOptions(unit, 2, "Health", "Value"),
			Power = self:CreateTextOptions(unit, 3, "Power", "Value"),
			HealthPercent = self:CreateTextOptions(unit, 4, "Health", "Percent"),
			PowerPercent = self:CreateTextOptions(unit, 5, "Power", "Percent"),
			HealthMissing = self:CreateTextOptions(unit, 6, "Health", "Missing"),
			PowerMissing = self:CreateTextOptions(unit, 7, "Power", "Missing"),
			Combat = (unit == "Player" or unit == "Target" or unit == "Focus" or unit == "Pet" or unit == "ToT") and self:CreateCombatTextOptions(unit, 8) or nil,
			DruidMana = (unit == "Player" and (class == "DRUID" or class == "SHAMAN" or class == "PRIEST")) and self:CreateDruidManaTimerOptions(9) or nil,
			WarlockBar = (unit == "Player" and class == "WARLOCK") and self:CreatePlayerBarTextOptions("WarlockBar", 9) or nil,
			PvP = (unit == "Player") and self:CreatePvpTimerOptions(10) or nil,
			AltPower = (unit == "Player") and self:CreatePlayerBarTextOptions("AltPower", 12) or nil,
		}),
		Castbar = (self.defaults[unit].Castbar) and self:CreateCastbarOptions(unit, 5) or nil,
		Aura = (self.defaults[unit].Aura) and self:NewGroup("Auras", 6, "tab", nil, disabledFunc, {
			Buffs = self:CreateAuraOptions(unit, 1, "Buffs"),
			Debuffs = self:CreateAuraOptions(unit, 2, "Debuffs"),
		}) or nil,
		Portrait = self:CreatePortraitOptions(unit, 7),
		Icons = self.defaults[unit].Icons and self:NewGroup("Icons", 8, "tab", nil, disabledFunc, {
			PvP = self.db[unit].Icons.PvP and self:CreateIconOptions(unit, 1, "PvP") or nil,
			Combat = self.db[unit].Icons.Combat and self:CreateIconOptions(unit, 2, "Combat") or nil,
			Resting = self.db[unit].Icons.Resting and self:CreateIconOptions(unit, 3, "Resting") or nil,
			Lootmaster = self.db[unit].Icons.Lootmaster and self:CreateIconOptions(unit, 4, "Lootmaster") or nil,
			Leader = self.db[unit].Icons.Leader and self:CreateIconOptions(unit, 5, "Leader") or nil,
			Role = self.db[unit].Icons.Role and self:CreateIconOptions(unit, 6, "Role") or nil,
			Raid = self.db[unit].Icons.Raid and self:CreateIconOptions(unit, 7, "Raid") or nil,
			ReadyCheck = self.db[unit].Icons.ReadyCheck and self:CreateIconOptions(unit, 8, "ReadyCheck") or nil,
		}) or nil,
	})

	return options
end
