--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: meta.lua
	Description: oUF Meta Functions
]]

local addonname, LUI = ...
local module = LUI:GetModule("Unitframes")
local Media = LibStub("LibSharedMedia-3.0")
local oUF = LUI.oUF

local DebuffTypeColor = _G.DebuffTypeColor
local GetSpellInfo = _G.GetSpellInfo

local prototypeFont = [=[Interface\Addons\LUI\media\fonts\Prototype.ttf]=]

local cornerAuras = {
	WARRIOR = {
		TOPLEFT = {50720, true},
	},
	PRIEST = {
		TOPLEFT = {139, true}, -- Renew
		TOPRIGHT = {17}, -- Power Word: Shield
		BOTTOMLEFT = {33076}, -- Prayer of Mending
		BOTTOMRIGHT = {194384, true}, -- Atonement
	},
	DRUID = {
		TOPLEFT = {8936, true}, -- Regrowth
		TOPRIGHT = {94447}, -- Lifebloom
		BOTTOMLEFT = {774, true}, -- Rejuvenation
		BOTTOMRIGHT = {48438, true}, -- Wild Growth
	},
	MAGE = {
		TOPLEFT = {54646}, -- Focus Magic
	},
	MONK = {
		TOPLEFT = {115151, true} -- Renewing Mist
	},
	PALADIN = {
		TOPLEFT = {25771, false, true}, -- Forbearance
	},
	SHAMAN = {
		TOPLEFT = {61295, true}, -- Riptide
		TOPRIGHT = {974}, -- Earth Shield
	},
	WARLOCK = {
		TOPLEFT = {80398}, -- Dark Intent
	},
}



--- Aura Filtering function
---@param element ufAuras
---@param unit UnitId
---@param data UnitAuraInfo
---@return boolean show @ indicates whether the aura button should be shown
local function FilterAura(element, unit, data)
	local caster = data.sourceUnit

	-- When OnlyShowPlayer is used, only show auras that comes from the player (or when they're in a vehicle)
	if element.onlyShowPlayer and (caster == "player" or caster == "vehicle") then
		return true

	-- When IncludePet is used show auras that comes from the player's pet as well.
	elseif element.includePet and caster == "pet" then
		return true

	-- Show all named auras when OnlyShowPlayer is not being used
	elseif data.name and not element.onlyShowPlayer then
		return true

	end
end

local function CreateAuraTimer(self,elapsed)
	if self.timeLeft then
		self.elapsed = (self.elapsed or 0) + elapsed
		if self.elapsed >= 0.1 then
			if not self.first then
				self.timeLeft = self.timeLeft - self.elapsed
			else
				self.timeLeft = self.timeLeft - GetTime()
				self.first = false
			end
			if self.timeLeft > 0 then
				self.remaining:SetText(module.FormatTime(self.timeLeft))
				self.remaining:SetTextColor(1, 1, 1)
			else
				self.remaining:Hide()
				self:SetScript("OnUpdate", nil)
			end
			self.elapsed = 0
		end
	end
end

local function PostCreateAura(element, button)
	button.backdrop = CreateFrame("Frame", nil, button, "BackdropTemplate")
	button.backdrop:SetPoint("TOPLEFT", button, "TOPLEFT", -3.5, 3)
	button.backdrop:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 4, -3.5)
	button.backdrop:SetFrameStrata("BACKGROUND")
	button.backdrop:SetBackdrop({
		edgeFile = LUI.Media.glowTex, edgeSize = 5,
		insets = {left = 3, right = 3, top = 3, bottom = 3}
	})
	button.backdrop:SetBackdropColor(0, 0, 0, 0)
	button.backdrop:SetBackdropBorderColor(0, 0, 0)
	button.Count:SetPoint("BOTTOMRIGHT", -1, 2)
	button.Count:SetJustifyH("RIGHT")
	button.Count:SetFont(prototypeFont, 16, "OUTLINE")
	button.Count:SetTextColor(0.84, 0.75, 0.65)

	button.remaining = module.SetFontString(button, Media:Fetch("font", module.db.profile.Settings.AuratimerFont), module.db.profile.Settings.AuratimerSize, module.db.profile.Settings.AuratimerFlag)
	button.remaining:SetPoint("TOPLEFT", 1, -1)

	button.Cooldown.noCooldownCount = true

	button.Overlay:Hide()

	button.auratype = button:CreateTexture(nil, "OVERLAY")
	button.auratype:SetTexture(module.buttonTex)
	button.auratype:SetPoint("TOPLEFT", button, "TOPLEFT", -2, 2)
	button.auratype:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
	button.auratype:SetTexCoord(0, 1, 0.02, 1)
end

--- PostUpdate for Auras (Buffs/Debuffs)
---@param element ufAuras
---@param button ufAuraButton
---@param unit UnitId
---@param data UnitAuraInfo
---@param position number
local function PostUpdateAura(element, button, unit, data, position)
	if button.isHarmful then
		if data.sourceUnit == "player" or data.sourceUnit == "pet" or data.sourceUnit == "vehicle" then
			button.Icon:SetDesaturated()
		else
			button.Icon:SetDesaturated(element.fadeOthers)
		end
	end

	if element.showAuraType and data.dispelName then
		local color = DebuffTypeColor[data.dispelName] or DebuffTypeColor.none
		button.auratype:SetVertexColor(color.r, color.g, color.b)
	else
		if button.isHarmful then
			button.auratype:SetVertexColor(0.69, 0.31, 0.31)
		else
			button.auratype:SetVertexColor(1, 1, 1)
		end
	end

	if element.disableCooldown or (not data.duration) or data.duration <= 0 then
		button.Cooldown:Hide()
	else
		button.Cooldown:Show()
	end

	button.Cooldown:SetReverse(element.cooldownReverse)

	if data.duration and data.duration > 0 then
		if element.showAuratimer then
			button.remaining:Show()
		else
			button.remaining:Hide()
		end
	else
		button.remaining:Hide()
	end

	button.duration = data.duration
	button.timeLeft = data.expirationTime
	button.first = true
	button:SetScript("OnUpdate", CreateAuraTimer)
end

-- #############################################z######################################################################
-- ##### Unitframe Elements: Buffs ####################################################################################
-- ####################################################################################################################


local function Buffs(self, unit, oufdb)
	if not self.Buffs then self.Buffs = CreateFrame("Frame", nil, self) end

	self.Buffs:SetHeight(oufdb.Aura.Buffs.Size)
	self.Buffs:SetWidth(oufdb.Width)
	self.Buffs.size = oufdb.Aura.Buffs.Size
	self.Buffs.spacing = oufdb.Aura.Buffs.Spacing
	self.Buffs.num = oufdb.Aura.Buffs.Num

	for i = 1, #self.Buffs do
		local button = self.Buffs[i]
		if button and button:IsShown() then
			button:SetWidth(oufdb.Aura.Buffs.Size)
			button:SetHeight(oufdb.Aura.Buffs.Size)
		elseif not button then
			break
		end
	end

	self.Buffs:ClearAllPoints()
	self.Buffs:SetPoint(oufdb.Aura.Buffs.InitialAnchor, self, oufdb.Aura.Buffs.InitialAnchor, oufdb.Aura.Buffs.X, oufdb.Aura.Buffs.Y)
	self.Buffs.initialAnchor = oufdb.Aura.Buffs.InitialAnchor
	self.Buffs["growth-y"] = oufdb.Aura.Buffs.GrowthY
	self.Buffs["growth-x"] = oufdb.Aura.Buffs.GrowthX
	self.Buffs.onlyShowPlayer = oufdb.Aura.Buffs.PlayerOnly
	self.Buffs.includePet = oufdb.Aura.Buffs.IncludePet
	self.Buffs.showStealableBuffs = (unit ~= "player" and (LUI.MAGE or LUI.SHAMAN))
	self.Buffs.showAuraType = oufdb.Aura.Buffs.ColorByType
	self.Buffs.showAuratimer = oufdb.Aura.Buffs.AuraTimer
	self.Buffs.disableCooldown = oufdb.Aura.Buffs.DisableCooldown
	self.Buffs.cooldownReverse = oufdb.Aura.Buffs.CooldownReverse

	self.Buffs.PostCreateButton = PostCreateAura
	self.Buffs.PostUpdateButton = PostUpdateAura
	--self.Buffs.FilterAura = FilterAura
	if not self.Buffs.createdButtons then self.Buffs.createdButtons = 0 end
	if not self.Buffs.anchoredButtons then self.Buffs.anchoredButtons = 0 end
end

-- #############################################z######################################################################
-- ##### Unitframe Elements: Debuffs ##################################################################################
-- ####################################################################################################################

local function Debuffs(self, unit, oufdb)
	if not self.Debuffs then self.Debuffs = CreateFrame("Frame", nil, self) end

	self.Debuffs:SetHeight(oufdb.Aura.Debuffs.Size)
	self.Debuffs:SetWidth(oufdb.Width)
	self.Debuffs.size = oufdb.Aura.Debuffs.Size
	self.Debuffs.spacing = oufdb.Aura.Debuffs.Spacing
	self.Debuffs.num = oufdb.Aura.Debuffs.Num

	for i = 1, #self.Debuffs do
		local button = self.Debuffs[i]
		if button and button:IsShown() then
			button:SetWidth(oufdb.Aura.Debuffs.Size)
			button:SetHeight(oufdb.Aura.Debuffs.Size)
		elseif not button then
			break
		end
	end

	self.Debuffs:ClearAllPoints()
	self.Debuffs:SetPoint(oufdb.Aura.Debuffs.InitialAnchor, self, oufdb.Aura.Debuffs.InitialAnchor, oufdb.Aura.Debuffs.X, oufdb.Aura.Debuffs.Y)
	self.Debuffs.initialAnchor = oufdb.Aura.Debuffs.InitialAnchor
	self.Debuffs["growth-y"] = oufdb.Aura.Debuffs.GrowthY
	self.Debuffs["growth-x"] = oufdb.Aura.Debuffs.GrowthX
	self.Debuffs.onlyShowPlayer = oufdb.Aura.Debuffs.PlayerOnly
	self.Debuffs.includePet = oufdb.Aura.Debuffs.IncludePet
	self.Debuffs.fadeOthers = oufdb.Aura.Debuffs.FadeOthers
	self.Debuffs.showStealableBuffs = (unit ~= "player" and (LUI.MAGE or LUI.SHAMAN))
	self.Debuffs.showAuraType = oufdb.Aura.Debuffs.ColorByType
	self.Debuffs.showAuratimer = oufdb.Aura.Debuffs.AuraTimer
	self.Debuffs.disableCooldown = oufdb.Aura.Debuffs.DisableCooldown
	self.Debuffs.cooldownReverse = oufdb.Aura.Debuffs.CooldownReverse

	self.Debuffs.PostCreateButton = PostCreateAura
	self.Debuffs.PostUpdateButton = PostUpdateAura
	--self.Debuffs.FilterAura = FilterAura
	if not self.Debuffs.createdButtons then self.Debuffs.createdButtons = 0 end
	if not self.Debuffs.anchoredButtons then self.Debuffs.anchoredButtons = 0 end
end

-- ####################################################################################################################
-- ##### Unitframe Elements: Raid Single Auras ########################################################################
-- ####################################################################################################################

local function SingleAuras(self, unit, oufdb)
	if not cornerAuras[LUI.playerClass] then return end
	if not self.SingleAuras then self.SingleAuras = {} end

	for k, data in pairs(cornerAuras[LUI.playerClass]) do
		local spellId, onlyPlayer, isDebuff = unpack(data)
		local spellName = GetSpellInfo(spellId)

		local x = k:find("RIGHT") and - oufdb.CornerAura.Inset or oufdb.CornerAura.Inset
		local y = k:find("TOP") and - oufdb.CornerAura.Inset or oufdb.CornerAura.Inset

		if not self.SingleAuras[k] then
			self.SingleAuras[k] = CreateFrame("Frame", nil, self)
			self.SingleAuras[k]:SetFrameLevel(7)
		end

		self.SingleAuras[k].spellName = spellName
		self.SingleAuras[k].onlyPlayer = onlyPlayer
		self.SingleAuras[k].isDebuff = isDebuff
		self.SingleAuras[k]:SetWidth(oufdb.CornerAura.Size)
		self.SingleAuras[k]:SetHeight(oufdb.CornerAura.Size)
		self.SingleAuras[k]:ClearAllPoints()
		self.SingleAuras[k]:SetPoint(k, self, k, x, y)
	end
end

-- ####################################################################################################################
-- ##### Unitframe Elements: Raid Debuffs #############################################################################
-- ####################################################################################################################

local function RaidDebuffs(self, unit, oufdb)
	if not self.RaidDebuffs then
		self.RaidDebuffs = CreateFrame("Frame", nil, self, "BackdropTemplate")
		self.RaidDebuffs:SetPoint("CENTER", self, "CENTER", 0, 0)
		self.RaidDebuffs:SetFrameLevel(7)

		self.RaidDebuffs:SetBackdrop({
			bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
			insets = {top = -1, left = -1, bottom = -1, right = -1},
		})

		self.RaidDebuffs.icon = self.RaidDebuffs:CreateTexture(nil, "OVERLAY")
		self.RaidDebuffs.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
		self.RaidDebuffs.icon:SetAllPoints(self.RaidDebuffs)

		self.RaidDebuffs.cd = CreateFrame("Cooldown", nil, self.RaidDebuffs)
		self.RaidDebuffs.cd:SetAllPoints(self.RaidDebuffs)
	end

	self.RaidDebuffs:SetHeight(oufdb.RaidDebuff.Size)
	self.RaidDebuffs:SetWidth(oufdb.RaidDebuff.Size)
end

-- ####################################################################################################################
-- ##### Unitframe Elements: Wrap up ##################################################################################
-- ####################################################################################################################

module.funcs.Buffs = Buffs
module.funcs.Debuffs = Debuffs
module.funcs.SingleAuras = SingleAuras
module.funcs.RaidDebuffs = RaidDebuffs
