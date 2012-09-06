--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: hideblizzard.lua
	Description: Blizzard UnitFrame Hider
]]

local addonname, LUI = ...
local UF = LUI:Module("Unitframes")
local module = UF:Module("HideBlizzard", "AceEvent-3.0", "AceHook-3.0")

local argcheck = LUI.argcheck

local OutOfCombatWrapper
do
	local inCombat, inLockdown = false, false
	local actionsToPerform = {}
	
	module:RegisterEvent("PLAYER_REGEN_ENABLED", function()
		inCombat, inLockdown = false, false
		
		for i, func in ipairs(actionsToPerform) do
			func()
			actionsToPerform[i] = nil
		end
	end)
	module:RegisterEvent("PLAYER_REGEN_DISABLED", function()
		inCombat = true
	end)
	
	local function RunOnLeaveCombat(func)
		if not inCombat then
			-- out of combat, call right away and return
			func()
			return
		end
		if not inLockdown then
			inLockdown = InCombatLockdown() -- still in PLAYER_REGEN_DISABLED
			if not inLockdown then
				func()
				return
			end
		end
		tinsert(actionsToPerform, func)
	end
	
	function OutOfCombatWrapper(func)
		return function()
			return RunOnLeaveCombat(func)
		end
	end
end

local hidden, hide, show = {}, nil, nil
do
	local hook = setmetatable({}, {
		__call = function(t, unit, hookto)
			if t[unit] then return end
			t[unit] = true
			
			hooksecurefunc(hookto, function()
				if hidden[unit] then
					hide[unit]()
				end
			end)
		end
	})
	
	local compact_raid
	
	hide = {
		player = function()
			-- Only hide the PlayerFrame, do not mess with the events.
			-- Messing the PlayerFrame ends up spreading taint.
			PlayerFrame:Hide()
		end,
		target = function()
			TargetFrame:UnregisterAllEvents()
			TargetFrame:Hide()
			ComboFrame:UnregisterAllEvents()
		end,
		focus = function()
			FocusFrame:UnregisterAllEvents()
			FocusFrame:Hide()
		end,
		party = function()
			for i = 1, 4 do
				local frame = _G["PartyMemberFrame"..i]
				frame:UnregisterAllEvents()
				frame:Hide()
				frame.Show = function() end
			end
			
			UIParent:UnregisterEvent("RAID_ROSTER_UPDATE")
			
			if CompactPartyFrame then
				CompactPartyFrame:UnregisterEvent("RAID_ROSTER_UPDATE")
				CompactPartyFrame:Hide()
				
				if hook.party == "CompactPartyFrame_Generate" then
					hook.party = nil
				end
				if CompactPartyFrame_UpdateShown then
					hook("party", "CompactPartyFrame_UpdateShown")
				end
			else
				hook("party", "CompactPartyFrame_Generate")
			end
		end,
		raid = function()
			CompactRaidFrameManager:UnregisterEvent("PARTY_MEMBERS_CHANGED")
			CompactRaidFrameManager:UnregisterEvent("RAID_ROSTER_UPDATE")
			CompactRaidFrameManager:UnregisterEvent("PLAYER_ENTERING_WORLD")
			CompactRaidFrameManager:Hide()
			compact_raid = CompactRaidFrameManager_GetSetting("IsShown")
			if compact_raid and compact_raid ~= "0" then 
				CompactRaidFrameManager_SetSetting("IsShown", "0")
			end
			hook("raid", "CompactRaidFrameManager_UpdateShown")
		end,
		boss = function()
			for i = 1, MAX_BOSS_FRAMES do
				local frame = _G["Boss"..i.."TargetFrame"]
				frame:UnregisterAllEvents()
				frame:Hide()
			end
		end,
		arena = function()
			if IsAddOnLoaded("Blizzard_ArenaUI") then
				ArenaEnemyFrames:UnregisterAllEvents()
			else
				hook("arena", "Arena_LoadUI")
			end
		end,
		castbar = function()
			CastingBarFrame:UnregisterAllEvents()
			PetCastingBarFrame:UnregisterAllEvents()
		end,
		runebar = function()
			hook("runebar", "PlayerFrame_HideVehicleTexture")
			RuneFrame:UnregisterAllEvents()
			RuneFrame:Hide()
		end,
		altpower = function()
			PlayerPowerBarAlt:UnregisterAllEvents()
			PlayerPowerBarAlt:Hide()
		end,
		aura = function()
			BuffFrame:Hide()
			TemporaryEnchantFrame:Hide()
			ConsolidatedBuffs:Hide()
			BuffFrame:UnregisterAllEvents()
		end,
	}
	show = {
		player = function()
			PlayerFrame:Show()
		end,
		target = function()
			TargetFrame:GetScript("OnLoad")(TargetFrame)
			ComboFrame:GetScript("OnLoad")(ComboFrame)
		end,
		focus = function()
			FocusFrame:GetScript("OnLoad")(FocusFrame)
		end,
		party = function()
			for i = 1, 4 do
				local frame = _G["PartyMemberFrame"..i]
				frame.Show = nil -- reset access to the frame metatable's show function
				frame:GetScript("OnLoad")(frame)
				frame:GetScript("OnEvent")(frame, "PARTY_MEMBERS_CHANGED")
				
				PartyMemberFrame_UpdateMember(frame)
			end

			UIParent:RegisterEvent("RAID_ROSTER_UPDATE")
			
			if CompactPartyFrame then
				CompactPartyFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
				CompactPartyFrame:RegisterEvent("RAID_ROSTER_UPDATE")
				if GetDisplayedAllyFrames then
					if GetDisplayedAllyFrames() == "compact-party" then
						CompactPartyFrame:Show()
					end
				elseif GetCVarBool("useCompactPartyFrames") and GetNumPartyMembers() > 0 and GetNumRaidMembers() == 0 then
					CompactPartyFrame:Show()
				end
			end
		end,
		raid = function()
			CompactRaidFrameManager:RegisterEvent("PARTY_MEMBERS_CHANGED")
			CompactRaidFrameManager:RegisterEvent("RAID_ROSTER_UPDATE")	
			CompactRaidFrameManager:RegisterEvent("PLAYER_ENTERING_WORLD")
			if GetDisplayedAllyFrames then
				if GetDisplayedAllyFrames() == "raid" then
					CompactRaidFrameManager:Show()
				end
			elseif GetNumRaidMembers() > 0 then
				CompactRaidFrameManager:Show()
			end
			if compact_raid and compact_raid ~= "0" then
				CompactRaidFrameManager_SetSetting("IsShown", "1")
			end
		end,
		boss = function()
			for i = 1, MAX_BOSS_FRAMES do
				local frame = _G["Boss"..i.."TargetFrame"]
				frame:GetScript("OnLoad")(frame)
			end
		end,
		arena = function()
			if IsAddOnLoaded("Blizzard_ArenaUI") then
				ArenaEnemyFrames:GetScript("OnLoad")(ArenaEnemyFrames)
				ArenaEnemyFrames:GetScript("OnEvent")(ArenaEnemyFrames, "VARIABLES_LOADED")
			end
		end,
		castbar = function()
			CastingBarFrame:GetScript("OnLoad")(CastingBarFrame)
			PetCastingBarFrame:GetScript("OnLoad")(PetCastingBarFrame)
		end,
		runebar = function()
			local _,class = UnitClass("player")
			if class == "DEATHKNIGHT" then
				RuneFrame:Show()
			end
			RuneFrame:GetScript("OnLoad")(RuneFrame)
			RuneFrame:GetScript("OnEvent")(RuneFrame, "PLAYER_ENTERING_WORLD")
		end,
		altpower = function()
			PlayerPowerBarAlt:GetScript("OnLoad")(PlayerPowerBarAlt)
			UnitPowerBarAlt_UpdateAll(PlayerPowerBarAlt)
		end,
		aura = function()
			BuffFrame:Show()
			if GetCVarBool("consolidateBuffs") then
				ConsolidatedBuffs:Show()
			end
			TemporaryEnchantFrame:Show()
			
			-- Can't use OnLoad because doing so resets some variables which requires an update to get the frame back in the proper state, which in Cata causes taint.
			BuffFrame:RegisterEvent("UNIT_AURA")
			
			-- This isn't perfect.  It doesn't update the buffs till the next aura update.  However, in Cata it causes taint to force the update.
			-- However, it should work for 99% of peoples use cases, which is toggling it on and off to see what it does or setting it and leaving it set.
			-- BuffFrame:GetScript("OnEvent")(BuffFrame, "UNIT_AURA", PlayerFrame.unit)
		end,
	}
	
	for k, v in pairs(hide) do
		hide[k] = OutOfCombatWrapper(v)
	end
	for k, v in pairs(show) do
		show[k] = OutOfCombatWrapper(v)
	end
end

function module:Hide(unit, override)
	argcheck(unit, "typeof", "string")
	unit = unit:lower()
	argcheck(unit, "isin", hide)
	
	if hidden[unit] then return end
	
	hidden[unit] = true
	if (UF:IsEnabled() and self:IsEnabled()) or override then
		hide[unit]()
	end
	return true -- inform that unitframe was hidden
end

function module:Show(unit, override)
	argcheck(unit, "typeof", "string")
	unit = unit:lower()
	argcheck(unit, "isin", show)
	
	if not hidden[unit] then return end
	
	hidden[unit] = nil
	if (UF:IsEnabled() and self:IsEnabled()) or override then
		show[unit]()
	end
	return true -- inform that unitframe was shown
end

function module:IsUnitHideable(unit)
	argcheck(unit, "typeof", "string")
	
	return hide[unit:lower()] ~= nil
end

function module:OnEnable()
	for unit in pairs(hidden) do
		hide[unit]()
	end
end

function module:OnDisable()
	for unit in pairs(hidden) do
		show[unit]()
	end
end