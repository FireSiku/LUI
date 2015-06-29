--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: pallypower.lua
	Description: PallyPower Module
	Version....: 1.0
]] 

local addonname, LUI = ...
local module = LUI:Module("PallyPower")

function module:SetPallyPower()
	if IsAddOnLoaded("PallyPower") ~= true then return end

	PallyPower.db.profile.cBuffNeedAll = {r = 0.5, g = 0.5, b = 0.5, t = 0.7}
	PallyPower.db.profile.cBuffNeedSome = {r = 0.5, g = 0.5, b = 0.5, t = 0.7}
	PallyPower.db.profile.cBuffNeedSpecial = {r = 0.5, g = 0.5, b = 0.5, t = 0.7}
	PallyPower.db.profile.cBuffGood = {r = 0.2, g = 0.2, b = 0.2, t = 0.6}
	PallyPower.db.profile.display.hideDragHandle = false
	PallyPower.db.profile.display.frameLocked = true
	
	PallyPower.ClassIcons = {
		[1] = "Interface\\AddOns\\LUI\\media\\textures\\icons\\Warrior",
		[2] = "Interface\\AddOns\\LUI\\media\\textures\\icons\\Rogue",
		[3] = "Interface\\AddOns\\LUI\\media\\textures\\icons\\Priest",
		[4] = "Interface\\AddOns\\LUI\\media\\textures\\icons\\Druid",
		[5] = "Interface\\AddOns\\LUI\\media\\textures\\icons\\Paladin",
		[6] = "Interface\\AddOns\\LUI\\media\\textures\\icons\\Hunter",
		[7] = "Interface\\AddOns\\LUI\\media\\textures\\icons\\Mage",
		[8] = "Interface\\AddOns\\LUI\\media\\textures\\icons\\Warlock",
		[9] = "Interface\\AddOns\\LUI\\media\\textures\\icons\\Shaman",
		[10] = "Interface\\AddOns\\LUI\\media\\textures\\icons\\DeathKnight",
		[11] = "Interface\\AddOns\\LUI\\media\\textures\\icons\\Pet"};
	
	PallyPower.AuraIcons = {
		[-1] = "",
		[1] = "Interface\\AddOns\\LUI\\media\\textures\\icons\\Aura_Devotion",
		[2] = "Interface\\AddOns\\LUI\\media\\textures\\icons\\Aura_Flight",
		[3] = "Interface\\AddOns\\LUI\\media\\textures\\icons\\Aura_Mindsooth",
		[4] = "Interface\\AddOns\\LUI\\media\\textures\\icons\\Aura_Shadow",
		[5] = "Interface\\AddOns\\LUI\\media\\textures\\icons\\Aura_Frost",
		[6] = "Interface\\AddOns\\LUI\\media\\textures\\icons\\Aura_Fire",
		[7] = "Interface\\AddOns\\LUI\\media\\textures\\icons\\Aura_Crusader"};
	
	PallyPower.BlessingIcons = {
		[-1] = "",
		[1] = "Interface\\AddOns\\LUI\\media\\textures\\icons\\Blessing_Wisdom_Greater",
		[2] = "Interface\\AddOns\\LUI\\media\\textures\\icons\\Blessing_Might_Greater",
		[3] = "Interface\\AddOns\\LUI\\media\\textures\\icons\\Blessing_Kings_Greater",
		[4] = "Interface\\AddOns\\LUI\\media\\textures\\icons\\Blessing_Sanctuary_Greater"};
		
	PallyPower.NormalBlessingIcons = {
		[-1] = "",
		[1] = "Interface\\AddOns\\LUI\\media\\textures\\icons\\Blessing_Wisdom",
		[2] = "Interface\\AddOns\\LUI\\media\\textures\\icons\\Blessing_Might",
		[3] = "Interface\\AddOns\\LUI\\media\\textures\\icons\\Blessing_Kingsr",
		[4] = "Interface\\AddOns\\LUI\\media\\textures\\icons\\Blessing_Sanctuary"};
	
	PallyPowerAura:SetWidth(140)
	PallyPowerRF:SetWidth(140)
	PallyPowerAuto:SetWidth(140)
	
	PallyPowerAura:SetBackdropBorderColor(0,0,0,0.8)
	PallyPowerRF:SetBackdropBorderColor(0,0,0,0.8)
	PallyPowerAuto:SetBackdropBorderColor(0,0,0,0.8)
	
	PallyPowerC1:SetWidth(140)
	PallyPowerC2:SetWidth(140)
	PallyPowerC3:SetWidth(140)
	PallyPowerC4:SetWidth(140)
	PallyPowerC5:SetWidth(140)
	PallyPowerC6:SetWidth(140)
	PallyPowerC7:SetWidth(140)
	PallyPowerC8:SetWidth(140)
	PallyPowerC9:SetWidth(140)
	PallyPowerC10:SetWidth(140)
	PallyPowerC11:SetWidth(140)
	
	PallyPowerC1:SetFrameStrata("HIGH")
	PallyPowerC2:SetFrameStrata("HIGH")
	PallyPowerC3:SetFrameStrata("HIGH")
	PallyPowerC4:SetFrameStrata("HIGH")
	PallyPowerC5:SetFrameStrata("HIGH")
	PallyPowerC6:SetFrameStrata("HIGH")
	PallyPowerC7:SetFrameStrata("HIGH")
	PallyPowerC8:SetFrameStrata("HIGH")
	PallyPowerC9:SetFrameStrata("HIGH")
	PallyPowerC10:SetFrameStrata("HIGH")
	PallyPowerC11:SetFrameStrata("HIGH")
	
	PallyPowerC1:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC1P1:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC1P2:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC1P3:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC1P4:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC1P5:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC1P6:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC1P7:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC1P8:SetBackdropBorderColor(0,0,0,0.8)
	PallyPowerC2:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC2P1:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC2P2:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC2P3:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC2P4:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC2P5:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC2P6:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC2P7:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC2P8:SetBackdropBorderColor(0,0,0,0.8)
	PallyPowerC3:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC3P1:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC3P2:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC3P3:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC3P4:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC3P5:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC3P6:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC3P7:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC3P8:SetBackdropBorderColor(0,0,0,0.8)
	PallyPowerC4:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC4P1:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC4P2:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC4P3:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC4P4:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC4P5:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC4P6:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC4P7:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC4P8:SetBackdropBorderColor(0,0,0,0.8)
	PallyPowerC5:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC5P1:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC5P2:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC5P3:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC5P4:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC5P5:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC5P6:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC5P7:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC5P8:SetBackdropBorderColor(0,0,0,0.8)
	PallyPowerC6:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC6P1:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC6P2:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC6P3:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC6P4:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC6P5:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC6P6:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC6P7:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC6P8:SetBackdropBorderColor(0,0,0,0.8)
	PallyPowerC7:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC7P1:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC7P2:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC7P3:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC7P4:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC7P5:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC7P6:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC7P7:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC7P8:SetBackdropBorderColor(0,0,0,0.8)
	PallyPowerC8:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC8P1:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC8P2:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC8P3:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC8P4:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC8P5:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC8P6:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC8P7:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC8P8:SetBackdropBorderColor(0,0,0,0.8)
	PallyPowerC9:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC9P1:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC9P2:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC9P3:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC9P4:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC9P5:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC9P6:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC9P7:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC9P8:SetBackdropBorderColor(0,0,0,0.8)
	PallyPowerC10:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC10P1:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC10P2:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC10P3:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC10P4:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC10P5:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC10P6:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC10P7:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC10P8:SetBackdropBorderColor(0,0,0,0.8)
	PallyPowerC11:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC11P1:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC11P2:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC11P3:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC11P4:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC11P5:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC11P6:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC11P7:SetBackdropBorderColor(0,0,0,0.8)
		PallyPowerC11P8:SetBackdropBorderColor(0,0,0,0.8)
	
	PallyPowerAnchor:ClearAllPoints()
	PallyPowerAnchor:SetPoint("TOPLEFT", PallyPowerAura, "TOPLEFT", -20, 0)
	PallyPowerAnchor:Show()
	PallyPowerAnchor:SetAlpha(1)
	
	PallyPowerFrame:SetAlpha(0)
	PallyPowerFrame:Hide()
end

function module:OnEnable()
	self:SetPallyPower()
end