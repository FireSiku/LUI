--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: meta.lua
	Description: oUF Meta Functions
]]

local addonname, LUI = ...
local module = LUI:GetModule("Unitframes")
local Media = LibStub("LibSharedMedia-3.0")
local oUF = LUI.oUF

-- Local Upvalues
local GetShapeshiftFormID = _G.GetShapeshiftFormID
local UnitHasVehicleUI = _G.UnitHasVehicleUI
local UnitPowerType = _G.UnitPowerType
local UnitPowerMax = _G.UnitPowerMax
local UnitIsPlayer = _G.UnitIsPlayer
local GetTotemInfo = _G.GetTotemInfo
local UnitIsUnit = _G.UnitIsUnit
local UnitClass = _G.UnitClass
local UnitPower = _G.UnitPower
local UnitLevel = _G.UnitLevel

-- Constants
local ALT_MANA_BAR_PAIR_DISPLAY_INFO = _G.ALT_MANA_BAR_PAIR_DISPLAY_INFO
local ADDITIONAL_POWER_BAR_INDEX = _G.ADDITIONAL_POWER_BAR_INDEX
local MAX_TOTEMS = _G.MAX_TOTEMS

-- The base ampount of a ressource a given class can have
local BASE_COUNT = {
	MAGE = 4,
	MONK = 5,
	PALADIN = 5,
	ROGUE = 5,
	WARLOCK = 5,
	DRUID = 5,
	EVOKER = 5,
	DEFAULT = 5,
}

-- The maximum of a ressource a given class can have
local MAX_COUNT = {
	MAGE = 4,
	MONK = 6,
	PALADIN = 5,
	ROGUE = 7,
	WARLOCK = 5,
	DRUID = 5,
	EVOKER = 6,
	DEFAULT = 5,
}

-- ####################################################################################################################
-- ##### Unitframe Elements: Class Power Bar ##########################################################################
-- ####################################################################################################################

local function ChiOverride(self, event, unit, powerType)
	if self.unit ~= unit or (powerType and powerType ~= "CHI") then return end

	 local num = UnitPower(unit, Enum.PowerType.Chi)
	 for i = 1, self.Chi.Force do
		 if i <= num then
			 self.Chi[i]:SetAlpha(1)
		 else
			 self.Chi[i]:SetAlpha(.4)
		 end
	 end
end


local function ClassPower(self, unit, oufdb)
	local r, g, b
	if LUI.MONK then r, g, b = unpack(module.colors.chibar[1])
	elseif LUI.PALADIN then r, g, b = unpack(module.colors.holypowerbar[1])
	elseif LUI.MAGE then r, g, b = unpack(module.colors.arcanechargesbar[1])
	elseif LUI.WARLOCK then r, g, b = unpack(module.colors.warlockbar.Shard1)
	else r, g, b = unpack(module.colors.combopoints[1])
	end
	
	local classPower = self.ClassPower
	if not classPower then
		classPower = CreateFrame("Frame", nil, self, "BackdropTemplate")
		-- classPower:SetFrameLevel(6)
		classPower:SetFrameStrata("BACKGROUND")
		classPower:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = LUI.Media.glowTex, tile = false, tileSize = 0, edgeSize = 1,
		})
		classPower:SetBackdropColor(r * 0.35, g * 0.35, b * 0.35)
		classPower:SetBackdropBorderColor(0, 0, 0)
		classPower.bg = classPower:CreateTexture(nil, "BACKGROUND")
		classPower.bg:SetTexture(Media:Fetch("statusbar", oufdb.ClassPowerBar.Texture))

		classPower.multiplier = 0.35
		classPower.Count = BASE_COUNT[LUI.playerClass] or BASE_COUNT.DEFAULT
		classPower.MaxCount = MAX_COUNT[LUI.playerClass] or MAX_COUNT.DEFAULT

		for i = 1, classPower.MaxCount do -- Always create frames for the max possible
			classPower[i] = CreateFrame("StatusBar", nil, classPower, "BackdropTemplate")
			classPower[i]:SetBackdrop(module.backdrop)
			classPower[i]:SetBackdropColor(0.08, 0.08, 0.08)
		end

		self.ClassPower = classPower
	end

	local x = oufdb.ClassPowerBar.Lock and 0 or oufdb.ClassPowerBar.X
	local y = oufdb.ClassPowerBar.Lock and 0.5 or oufdb.ClassPowerBar.Y

	classPower:SetHeight(oufdb.ClassPowerBar.Height)
	classPower:SetWidth(oufdb.ClassPowerBar.Width)
	classPower:ClearAllPoints()
	classPower:SetPoint("BOTTOMLEFT", self, "TOPLEFT", x, y)

	local function checkPowers(event, level)
		local pLevel = (event == "UNIT_LEVEL") and tonumber(level) or UnitLevel("player")
		local count = BASE_COUNT[LUI.playerClass]
		--- @TODO: Revisit talents alterations.
		-- if LUI.MONK then
		-- 	if select(4, GetTalentInfo(3, 1, 1)) then
		-- 		count = count + 1Power
		-- 	end
		-- elseif LUI.ROGUE then
		-- 	--Check for Strategem, increase CPoints to 6.
		-- 	if select(4, GetTalentInfo(3, 2, 1)) then
		-- 		count = 6
		-- 	end
		-- end
		classPower.Count = count

		for i = 1, classPower.MaxCount do
			local classPoint = classPower[i] ---@type StatusBar
			if oufdb.ClassPowerBar.Texture == "Empty" then
				classPoint:SetStatusBarColor(r, g, b)
			else
				classPoint:SetStatusBarTexture(Media:Fetch("statusbar", oufdb.ClassPowerBar.Texture))
				classPoint:SetStatusBarColor(r, g, b)
			end
			classPoint:SetSize(((oufdb.ClassPowerBar.Width - 2*oufdb.ClassPowerBar.Padding) / classPower.Count), oufdb.ClassPowerBar.Height)
			classPoint:ClearAllPoints()
			if i == 1 then
				classPoint:SetPoint("LEFT", classPower, "LEFT", 0, 0)
			else
				classPoint:SetPoint("LEFT", classPower[i-1], "RIGHT", oufdb.ClassPowerBar.Padding, 0)
			end
			--LUI:Print("ClassIcon["..i.."] Is Shown")
			--classPoint:Show()
			if i > classPower.Count then
				classPoint:Hide()
			end
		end
	end
	checkPowers()

	module:RegisterEvent("UNIT_LEVEL", checkPowers)
	module:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", checkPowers)
	module:RegisterEvent("PLAYER_TALENT_UPDATE", checkPowers)
	classPower.UpdateTexture = checkPowers

	function self.ClassPower.PostVisibility(element, enabled)
		if enabled then
			self.ClassPower:Show()
		else
			self.ClassPower:Hide()
		end
	end
	
end

-- ####################################################################################################################
-- ##### Unitframe Elements: Runes ####################################################################################
-- ####################################################################################################################

local function Runes(self, unit, oufdb)
	if not self.Runes then
		self.Runes = CreateFrame("Frame", nil, self)
		self.Runes:SetFrameLevel(6)
			
		for i = 1, 6 do
			self.Runes[i] = CreateFrame("StatusBar", nil, self.Runes, "BackdropTemplate")
			self.Runes[i]:SetBackdrop(module.backdrop)
			self.Runes[i]:SetBackdropColor(0.08, 0.08, 0.08)
			self.Runes[i]:RegisterEvent("RUNE_POWER_UPDATE")

		end

		self.Runes.FrameBackdrop = CreateFrame("Frame", nil, self.Runes, "BackdropTemplate")
		self.Runes.FrameBackdrop:SetPoint("TOPLEFT", self.Runes, "TOPLEFT", -3.5, 3)
		self.Runes.FrameBackdrop:SetPoint("BOTTOMRIGHT", self.Runes, "BOTTOMRIGHT", 3.5, -3)
		self.Runes.FrameBackdrop:SetFrameStrata("BACKGROUND")
		self.Runes.FrameBackdrop:SetBackdrop({
			edgeFile = LUI.Media.glowTex, edgeSize = 5,
			insets = {left = 3, right = 3, top = 3, bottom = 3}
		})
		self.Runes.FrameBackdrop:SetBackdropColor(0, 0, 0, 0)
		self.Runes.FrameBackdrop:SetBackdropBorderColor(0, 0, 0)
	end

	local x = oufdb.RunesBar.Lock and 0 or oufdb.RunesBar.X
	local y = oufdb.RunesBar.Lock and 0.5 or oufdb.RunesBar.Y

	self.Runes:SetHeight(oufdb.RunesBar.Height)
	self.Runes:SetWidth(oufdb.RunesBar.Width)
	self.Runes:ClearAllPoints()
	self.Runes:SetPoint("BOTTOMLEFT", self, "TOPLEFT", x, y)

	for i = 1, 6 do
		local runeType = (_G.GetRuneType) and _G.GetRuneType(i) or 1
		self.Runes[i]:SetStatusBarTexture(Media:Fetch("statusbar", oufdb.RunesBar.Texture))
		self.Runes[i]:SetStatusBarColor(unpack(module.colors.runes[runeType]))
		self.Runes[i]:SetSize(((oufdb.RunesBar.Width - 5 * oufdb.RunesBar.Padding) / 6), oufdb.RunesBar.Height)

		self.Runes[i]:ClearAllPoints()
		local runePoints = {0, 1, 6, 3, 2, 5}
		if runePoints[i] == 0 then
			self.Runes[i]:SetPoint("LEFT", self.Runes, "LEFT", 0, 0)
		else
			self.Runes[i]:SetPoint("LEFT", self.Runes[runePoints[i]], "RIGHT", oufdb.RunesBar.Padding, 0)
		end
	end
end

-- ####################################################################################################################
-- ##### Unitframe Elements: Totems Bar ###############################################################################
-- ####################################################################################################################

local function TotemsUpdate(self, elapsed)
	self.total = elapsed + (self.total or 0)
	if self.total >= 0.02 then
		self.total = 0
		local haveTotem, name, startTime, duration, totemIcon = GetTotemInfo(self.slot)
		if (((GetTime() - startTime) == 0) or ( duration == 0 )) then
			self:SetValue(0)
		else
			self:SetValue(1 - ((GetTime() - startTime) / duration))
		end
	end
end

local function TotemsOverride(self, event, slot)
	if slot > MAX_TOTEMS then return end

	local totem = self.Totems[slot]

	local haveTotem, name, startTime, duration, totemIcon = GetTotemInfo(slot)

	local color = module.colors.totems[slot]
	totem:SetStatusBarColor(unpack(color))
	totem:SetValue(0)

	-- Multipliers
	if (totem.bg.multiplier) then
		local mu = totem.bg.multiplier
		local r, g, b = totem:GetStatusBarColor()
		r, g, b = r*mu, g*mu, b*mu
		totem.bg:SetVertexColor(r, g, b)
	end

	if(haveTotem) then
		
		if totem.Name then
			totem.Name:SetText(name)
		end
		if(duration >= 0) then
			totem:SetValue(1 - ((GetTime() - startTime) / duration))
			-- Status bar update
			totem:SetScript("OnUpdate", TotemsUpdate)
		else
			-- There's no need to update because it doesn't have any duration
			totem:SetScript("OnUpdate",nil)
			totem:SetValue(0)
		end
		if totemIcon then
			totem.icon:SetTexture(totemIcon)
		end
	else
		-- No totem = no time 
		if totem.Name then
			totem.Name:SetText(" ")
		end
		totem:SetValue(0)
	end

	for i = 1, MAX_TOTEMS do
		local currTotem = self.Totems[i]
		if GetTotemInfo(i) then
			currTotem:Show()
		else
			currTotem:Hide()
		end
	end

end

local function Totems(self, unit, oufdb)
	if not self.Totems then
		self.Totems = CreateFrame("Frame", nil, self)
		self.Totems:SetFrameLevel(6)

		for i = 1, MAX_TOTEMS do
			local bar = CreateFrame("StatusBar", nil, self.Totems, "BackdropTemplate")
			bar:SetBackdrop(module.backdrop)
			bar:SetBackdropColor(0, 0, 0)
			bar:SetMinMaxValues(0, 1)
			bar.slot = i

			bar.bg = bar:CreateTexture(nil, "BORDER")
			bar.bg:SetAllPoints(bar)
			bar.bg:SetTexture(LUI.Media.normTex)

			bar.icon = bar:CreateTexture(nil, "OVERLAY")
			bar.icon:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT")
			bar.icon:SetSize(oufdb.TotemsBar.Height * oufdb.TotemsBar.IconScale, oufdb.TotemsBar.Height * oufdb.TotemsBar.IconScale)

			local btn = CreateFrame("Button", nil, bar, "SecureActionButtonTemplate")
			btn:RegisterForClicks("AnyUp")
			btn:SetAllPoints(bar)
			btn:SetAttribute("unit", "player")
			btn:SetAttribute("type", "destroytotem")
			btn:SetAttribute("totem-slot", i)

			self.Totems[i] = bar
			self.Totems[i].btn = btn
		end
		
		
		self.Totems.FrameBackdrop = CreateFrame("Frame", nil, self.Totems, "BackdropTemplate")
		self.Totems.FrameBackdrop:SetPoint("TOPLEFT", self.Totems, "TOPLEFT", -3.5, 3)
		self.Totems.FrameBackdrop:SetPoint("BOTTOMRIGHT", self.Totems, "BOTTOMRIGHT", 3.5, -3)
		self.Totems.FrameBackdrop:SetFrameStrata("BACKGROUND")
		self.Totems.FrameBackdrop:SetBackdrop({
			edgeFile = LUI.Media.glowTex, edgeSize = 5,
			insets = {left = 3, right = 3, top = 3, bottom = 3}
		})
		self.Totems.FrameBackdrop:SetBackdropColor(0, 0, 0, 0)
		self.Totems.FrameBackdrop:SetBackdropBorderColor(0, 0, 0)

		self.Totems.Override = TotemsOverride
	end

	local x = oufdb.TotemsBar.Lock and 0 or oufdb.TotemsBar.X
	local y = oufdb.TotemsBar.Lock and 0.5 or oufdb.TotemsBar.Y

	self.Totems:ClearAllPoints()
	self.Totems:SetSize(oufdb.TotemsBar.Width, oufdb.TotemsBar.Height)
	self.Totems:SetPoint("BOTTOMLEFT", self, "TOPLEFT", x, y)

	local totemPoints = {0, 1, 2, 3}

	for i = 1, MAX_TOTEMS do
		local bar = self.Totems[i]
		bar:SetStatusBarTexture(Media:Fetch("statusbar", oufdb.TotemsBar.Texture))
		bar:SetHeight(oufdb.TotemsBar.Height)
		bar:SetWidth((oufdb.TotemsBar.Width - 3 * oufdb.TotemsBar.Padding) / 4)
		bar.icon:SetSize(oufdb.TotemsBar.Height * oufdb.TotemsBar.IconScale, oufdb.TotemsBar.Height * oufdb.TotemsBar.IconScale)

		bar:ClearAllPoints()
		if totemPoints[i] == 0 then
			bar:SetPoint("LEFT", self.Totems, "LEFT", 0, 0)
		else
			bar:SetPoint("LEFT", self.Totems[totemPoints[i]], "RIGHT", oufdb.TotemsBar.Padding, 0)
		end

		bar.bg.multiplier = oufdb.TotemsBar.Multiplier
	end
end

-- ####################################################################################################################
-- ##### Unitframe Elements: AdditionalPower ##########################################################################
-- ####################################################################################################################

local function PostUpdateAdditionalPower(additionalpower, unit, cur, max)
	local _, class = UnitClass(unit)
	if additionalpower.color == "By Class" then
		additionalpower:SetStatusBarColor(unpack(module.colors.class[class]))
	elseif additionalpower.color == "By Type" then
		additionalpower:SetStatusBarColor(unpack(module.colors.power.MANA))
	else
		additionalpower:SetStatusBarColor(oUF.ColorGradient(cur, max, module.colors.smooth()))
	end

	local bg = additionalpower.bg

	if bg then
		local mu = bg.multiplier or 1
		local r, g, b = additionalpower:GetStatusBarColor()
		bg:SetVertexColor(r * mu, g * mu, b * mu)
	end
end

local function ShouldEnableAdditionalPower(unit)
	local shouldEnable = false
	local _, playerClass = UnitClass(unit)
	if(not UnitHasVehicleUI('player')) then
		if(UnitPowerMax(unit, ADDITIONAL_POWER_BAR_INDEX) ~= 0) then
			if LUI.IsRetail and (ALT_MANA_BAR_PAIR_DISPLAY_INFO[playerClass]) then
				local powerType = UnitPowerType(unit)
				shouldEnable = ALT_MANA_BAR_PAIR_DISPLAY_INFO[playerClass][powerType]
			end
		end
	end
	return shouldEnable
end

local function AdditionalPowerOverride(self, event, unit)
	if not unit or not UnitIsUnit(self.unit, unit) then return end
	local _, class = UnitClass(unit)
	local additionalpower = self.AdditionalPower

	local form = GetShapeshiftFormID()
	if self.AdditionalPower.ShouldEnable(unit) then
		additionalpower:Show()
	else
		return additionalpower:Hide()
	end

	local cur, max = UnitPower('player', Enum.PowerType.Mana), UnitPowerMax('player', Enum.PowerType.Mana)

	additionalpower:SetMinMaxValues(0, max)
	additionalpower:SetValue(cur)

	local r, g, b
	if(additionalpower.colorClass and UnitIsPlayer(unit)) then
		r, g, b = unpack(module.colors.class[class])
	elseif(additionalpower.colorSmooth) then
		r, g, b = oUF.ColorGradient(cur, max, module.colors.smooth())
	else
		r, g, b = unpack(module.colors.power['MANA'])
	end
	if(b) then
		additionalpower:SetStatusBarColor(r, g, b)

		local bg = additionalpower.bg
		if(bg) then
			local mu = bg.multiplier or 1
			bg:SetVertexColor(r * mu, g * mu, b * mu)
		end
	end

	if(additionalpower.PostUpdatePower) then
		return additionalpower:PostUpdatePower(unit, cur, max)
	end
end

local function SetAdditionalPowerPosition(self, unit, oufdb)
	if not oufdb.AdditionalPowerBar.OverPower then return self.Power:SetHeight(oufdb.PowerBar.Height) end

	if self.AdditionalPower:IsShown() then
		self.Power:SetHeight(oufdb.PowerBar.Height/2 - 1)
		self.AdditionalPower:SetHeight(oufdb.AdditionalPowerBar.Height/2 - 1)
	else
		self.Power:SetHeight(oufdb.PowerBar.Height)
		self.AdditionalPower:SetHeight(oufdb.AdditionalPowerBar.Height)
	end
end

local function AdditionalPower(self, unit, oufdb)
	if not self.AdditionalPower then
		local AdditionalPower = CreateFrame("StatusBar", nil, self)

		local bg = AdditionalPower:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints(AdditionalPower)
		
		self.AdditionalPower = AdditionalPower
		self.AdditionalPower.bg = bg

		self.AdditionalPower.Smooth = oufdb.AdditionalPowerBar.Smooth

		self.AdditionalPower.value = module.SetFontString(self.AdditionalPower, Media:Fetch("font", oufdb.AdditionalPowerText.Font), oufdb.AdditionalPowerText.Size, oufdb.AdditionalPowerText.Outline)
		self:Tag(self.AdditionalPower.value, "[additionalpower2]")

		self.AdditionalPower:SetScript("OnShow", function() SetAdditionalPowerPosition(self, unit, oufdb) end)
		self.AdditionalPower:SetScript("OnHide", function() SetAdditionalPowerPosition(self, unit, oufdb) end)

		self.AdditionalPower.ShouldEnable = ShouldEnableAdditionalPower
		self.AdditionalPower.SetPosition = SetAdditionalPowerPosition
		self.AdditionalPower.PostUpdatePower = PostUpdateAdditionalPower
		self.AdditionalPower.Override = AdditionalPowerOverride
	end

	self.AdditionalPower:ClearAllPoints()
	if oufdb.AdditionalPowerBar.OverPower then
		self.AdditionalPower:SetPoint("TOPLEFT", self.Power, "BOTTOMLEFT", 0, -2)
		self.AdditionalPower:SetPoint("TOPRIGHT", self.Power, "BOTTOMRIGHT", 0, -2)
	else
		self.Power:SetHeight(oufdb.PowerBar.Height)
		self.AdditionalPower:SetPoint("TOPLEFT", self, "TOPLEFT", module.db.profile.player.AdditionalPowerBar.X, module.db.profile.player.AdditionalPowerBar.Y)
	end

	self.AdditionalPower:SetHeight(oufdb.AdditionalPowerBar.Height)
	self.AdditionalPower:SetWidth(oufdb.AdditionalPowerBar.Width)
	self.AdditionalPower:SetStatusBarTexture(Media:Fetch("statusbar", oufdb.AdditionalPowerBar.Texture))

	self.AdditionalPower.value:SetFont(Media:Fetch("font", oufdb.AdditionalPowerText.Font), oufdb.AdditionalPowerText.Size, oufdb.AdditionalPowerText.Outline)
	self.AdditionalPower.value:SetPoint("CENTER", self.AdditionalPower, "CENTER")

	if oufdb.AdditionalPowerText.Enable == true then
		self.AdditionalPower.value:Show()
	else
		self.AdditionalPower.value:Hide()
	end

	self.AdditionalPower.color = oufdb.AdditionalPowerBar.Color

	self.AdditionalPower.bg:SetTexture(Media:Fetch("statusbar", oufdb.AdditionalPowerBar.TextureBG))
	self.AdditionalPower.bg:SetAlpha(oufdb.AdditionalPowerBar.BGAlpha)
	self.AdditionalPower.bg.multiplier = oufdb.AdditionalPowerBar.BGMultiplier

	if self.AdditionalPower.ShouldEnable(unit) then self.AdditionalPower.SetPosition(self, unit, oufdb) end
	if module.db.profile.player.AdditionalPowerBar.Enable then
		self.AdditionalPower:Show()
	else
		self.AdditionalPower:Hide()
	end
end

-- ####################################################################################################################
-- ##### Unitframe Elements: Wrap up ##################################################################################
-- ####################################################################################################################

module.funcs.ClassPower = ClassPower
module.funcs.Runes = Runes
module.funcs.Totems = Totems
module.funcs.AdditionalPower = AdditionalPower
