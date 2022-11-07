--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: meta.lua
	Description: oUF Meta Functions
]]

local addonname, LUI = ...
local module = LUI:GetModule("Unitframes")
local Fader = LUI:GetModule("Fader", true)
local Media = LibStub("LibSharedMedia-3.0")

local oUF = LUI.oUF

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

local function UnitFrame_OnEnter(self)
	_G.UnitFrame_OnEnter(self)
	self.Highlight:Show()
end

local function UnitFrame_OnLeave(self)
	_G.UnitFrame_OnLeave(self)
	self.Highlight:Hide()
end

-- local function ArenaEnemyUnseen(self, event, unit, state)
-- 	if unit ~= self.unit then return end

-- 	if state == "unseen" then
-- 		self.Health.Override = function(health)
-- 			health:SetValue(0)
-- 			health:SetStatusBarColor(0.5, 0.5, 0.5, 1)
-- 			health.bg:SetVertexColor(0.5, 0.5, 0.5, 1)
-- 			health.value:SetText(health.value.ShowDead and "|cffD7BEA5<Unseen>|r" or "")
-- 			health.valuePercent:SetText(health.valuePercent.ShowDead and "|cffD7BEA5<Unseen>|r" or "")
-- 			health.valueMissing:SetText("")
-- 		end
-- 		self.Power.Override = function(power)
-- 			power:SetValue(0)
-- 			power:SetStatusBarColor(0.5, 0.5, 0.5, 1)
-- 			power.bg:SetVertexColor(0.5, 0.5, 0.5, 1)
-- 			power.value:SetText("")
-- 			power.valuePercent:SetText("")
-- 			power.valueMissing:SetText("")
-- 		end

-- 		self.Hide = self.Show
-- 		self:Show()
-- 	else
-- 		self.Health.Override = OverrideHealth
-- 		self.Power.Override = OverridePower

-- 		self.Hide = self.Hide_
-- 	end

-- 	self.Health:ForceUpdate()
-- 	self.Power:ForceUpdate()
-- end

-- ####################################################################################################################
-- ##### Unitframes: Style Function ###################################################################################
-- ####################################################################################################################

local function SetStyle(self, unit, isSingle)
	local oufdb

	if unit == "vehicle" then
		oufdb = module.db.profile.player
	elseif unit == unit:match("arena%d") then
		oufdb = module.db.profile.arena
	elseif unit == unit:match("arena%dtarget") then
		oufdb = module.db.profile.arenatarget
	elseif unit == unit:match("arena%dpet") then
		oufdb = module.db.profile.arenapet

	elseif unit == unit:match("boss%d") then
		oufdb = module.db.profile.boss
	elseif unit == unit:match("boss%dtarget") then
		oufdb = module.db.profile.bosstarget
	
	else
		oufdb = module.db.profile[unit]
	end


	self.colors = module.colors
	self:RegisterForClicks("AnyUp")

	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	self.MoveableFrames = ((isSingle and not unit:match("%d")) or unit == "party" or unit == "maintank" or unit == unit:match("%a+1"))

	self.SpellRange = true
	self.BarFade = false

	if isSingle then
		self:SetHeight(oufdb.Height)
		self:SetWidth(oufdb.Width)
	end

-- ####################################################################################################################
-- ##### Unitframe Style Function: Bars ###############################################################################
-- ####################################################################################################################

	module.funcs.Health(self, unit, oufdb)
	module.funcs.Power(self, unit, oufdb)
	module.funcs.FrameBackdrop(self, unit, oufdb)

	if oufdb.HealthPredictionBar and oufdb.HealthPredictionBar.Enable and false then module.funcs.HealthPrediction(self, unit, oufdb) end
	if oufdb.TotalAbsorbBar and oufdb.TotalAbsorbBar.Enable and false then module.funcs.TotalAbsorb(self, unit, oufdb) end

-- ####################################################################################################################
-- ##### Unitframe Style Function: Texts ##############################################################################
-- ####################################################################################################################

	-- creating a frame as anchor for icons, texts etc
	self.Overlay = CreateFrame("Frame", nil, self)
	self.Overlay:SetFrameLevel(8)
	self.Overlay:SetAllPoints(self.Health)

	if unit ~= "raid" then
		module.funcs.Info(self, unit, oufdb)
	else
		module.funcs.RaidInfo(self, unit, oufdb)
	end

	if unit == "party" then
		local sanityBar = _G[format("PartyMemberFrame%dPowerBarAlt", string.sub(self:GetName(), -1))]
		if sanityBar then
			sanityBar:ClearAllPoints()
			sanityBar:SetPoint("LEFT", self, "RIGHT", 25, 0)
			sanityBar:SetParent(self)
		end
	end

	module.funcs.HealthValue(self, unit, oufdb)
	module.funcs.HealthPercent(self, unit, oufdb)
	module.funcs.HealthMissing(self, unit, oufdb)

	module.funcs.PowerValue(self, unit, oufdb)
	module.funcs.PowerPercent(self, unit, oufdb)
	module.funcs.PowerMissing(self, unit, oufdb)

-- ####################################################################################################################
-- ##### Unitframe Style Function: Indicators #########################################################################
-- ####################################################################################################################

	if oufdb.Indicators then
		if oufdb.LeaderIndicator and oufdb.LeaderIndicator.Enable then module.funcs.LeaderIndicator(self, unit, oufdb) end
		if oufdb.RaidMarkerIndicator and oufdb.RaidMarkerIndicator.Enable then module.funcs.RaidTargetIndicator(self, unit, oufdb) end
		if oufdb.GroupRoleIndicator and oufdb.GroupRoleIndicator.Enable then module.funcs.GroupRoleIndicator(self, unit, oufdb) end
		if oufdb.PvPIndicator and oufdb.PvPIndicator.Enable then module.funcs.PvPIndicator(self, unit, oufdb) end
		if oufdb.RestingIndicator and oufdb.RestingIndicator.Enable then module.funcs.RestingIndicator(self, unit, oufdb) end
		if oufdb.CombatIndicator and oufdb.CombatIndicator.Enable then module.funcs.CombatIndicator(self, unit, oufdb) end
		if oufdb.ReadyCheckIndicator and oufdb.ReadyCheckIndicator.Enable then module.funcs.ReadyCheckIndicator(self, unit, oufdb) end
	end

-- ####################################################################################################################
-- ##### Unitframe Style Function: Player Specific ####################################################################
-- ####################################################################################################################

	if unit == "player" then
		
		if LUI.DEATHKNIGHT then
			if oufdb.RunesBar.Enable then
				module.funcs.Runes(self, unit, oufdb)
			end
		elseif LUI.DRUID then
			if oufdb.AdditionalPowerBar.Enable then module.funcs.AdditionalPower(self, unit, oufdb) end
			if oufdb.ClassPowerBar.Enable then module.funcs.ClassPower(self, unit, oufdb) end
		elseif LUI.PALADIN or LUI.MONK or LUI.ROGUE or LUI.WARLOCK then
			if oufdb.ClassPowerBar.Enable then module.funcs.ClassPower(self, unit, oufdb) end
		elseif LUI.SHAMAN then
			if oufdb.AdditionalPowerBar.Enable then module.funcs.AdditionalPower(self, unit, oufdb) end
			if oufdb.TotemsBar.Enable then module.funcs.Totems(self, unit, oufdb) end
		elseif LUI.MAGE then
			if oufdb.ClassPowerBar.Enable then module.funcs.ClassPower(self, unit, oufdb) end
		elseif LUI.EVOKER then
			if oufdb.ClassPowerBar.Enable then module.funcs.ClassPower(self, unit, oufdb) end
		elseif LUI.PRIEST then
			if oufdb.AdditionalPowerBar.Enable then module.funcs.AdditionalPower(self, unit, oufdb) end
		end
	end
	
-- ####################################################################################################################
-- ##### Unitframe Style Function: Raid Specific ######################################################################
-- ####################################################################################################################

	if unit == "raid" then
		if oufdb.CornerAura.Enable then module.funcs.SingleAuras(self, unit, oufdb) end
		if oufdb.RaidDebuff.Enable then module.funcs.RaidDebuffs(self, unit, oufdb) end
	end
	
-- ####################################################################################################################
-- ##### Unitframe Style Function: Others #############################################################################
-- ####################################################################################################################
	
	if oufdb.Portrait.Enable then module.funcs.Portrait(self, unit, oufdb) end

	if unit == "player" or unit == "pet" then
		if module.db.profile.player.AlternativePowerBar.Enable then module.funcs.AlternativePower(self, unit, oufdb) end
	end

	if oufdb.Aura then
		if oufdb.Aura.Buffs.Enable then module.funcs.Buffs(self, unit, oufdb) end
		if oufdb.Aura.Debuffs.Enable then module.funcs.Debuffs(self, unit, oufdb) end
	end

	if oufdb.CombatFeedback then module.funcs.CombatFeedbackText(self, unit, oufdb) end
	if module.db.profile.Settings.Castbars and oufdb.Castbar and oufdb.Castbar.General.Enable then
		module.funcs.Castbar(self, unit, oufdb)
	end
	if oufdb.Border.Aggro then module.funcs.AggroGlow(self, unit, oufdb) end

-- ####################################################################################################################
-- ##### Unitframe Style Function: V2 Textures ########################################################################
-- ####################################################################################################################

	if unit == "targettarget" and module.db.profile.Settings.ShowV2Textures then
		module.funcs.V2Textures(self, oUF_LUI_target)
	elseif unit == "targettargettarget" and module.db.profile.Settings.ShowV2Textures then
		module.funcs.V2Textures(self, oUF_LUI_targettarget)
	elseif unit == "focustarget" and module.db.profile.Settings.ShowV2Textures then
		module.funcs.V2Textures(self, oUF_LUI_focus)
	elseif unit == "focus" and module.db.profile.Settings.ShowV2Textures then
		module.funcs.V2Textures(self, oUF_LUI_player)
	elseif (unit == unit:match("arena%dtarget") and module.db.profile.Settings.ShowV2ArenaTextures) or (unit == unit:match("boss%dtarget") and module.db.profile.Settings.ShowV2BossTextures) then
		module.funcs.V2Textures(self, _G["oUF_LUI_"..unit:match("%a+%d")])
	elseif unit == "partytarget" and module.db.profile.Settings.ShowV2PartyTextures then
		module.funcs.V2Textures(self, self:GetParent())
	end

	self.Highlight = self.Health:CreateTexture(nil, "OVERLAY")
	self.Highlight:SetAllPoints(self)
	self.Highlight:SetTexture(module.highlightTex)
	self.Highlight:SetVertexColor(1,1,1,.1)
	self.Highlight:SetBlendMode("ADD")
	self.Highlight:Hide()

	--if unit == unit:match("arena%d") then
	--self.Hide_ = self.Hide
	--self:RegisterEvent("ARENA_OPPONENT_UPDATE", ArenaEnemyUnseen)
	--end

	self:RegisterEvent("PLAYER_FLAGS_CHANGED", function(self) self.Health:ForceUpdate() end)
	if unit == "player" then self:RegisterEvent("PLAYER_ENTERING_WORLD", function(self) self.Health:ForceUpdate() end) end
	if unit == "pet" then
		self.elapsed = 0
		self:SetScript("OnUpdate", function(self, elapsed)
			if self.elapsed > 2.5 then
				self:UpdateAllElements('refreshUnit')
				self.elapsed = 0
			else
				self.elapsed = self.elapsed + elapsed
			end
		end)
	end

	if Fader and oufdb.Fader and oufdb.Fader.Enable then Fader:RegisterFrame(self, oUF.Fader) end

	if unit == "raid" or (unit == "party" and oufdb.RangeFade and oufdb.Fader and not oufdb.Fader.Enable) then
		self.Range = {
			insideAlpha = 1,
			outsideAlpha = 0.5
		}
	end
	self.Power.Override = module.funcs.OverridePower

	self.__unit = unit

	if oufdb.Enable == false then self:Disable() end

	return self
end

oUF:RegisterStyle("LUI", SetStyle)
