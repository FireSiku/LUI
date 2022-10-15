--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: hideblizzard.lua
	Description: Blizzard Frame Hider
]]

local addonname, LUI = ...
local Blizzard = {}
LUI.Blizzard = Blizzard
LibStub("AceHook-3.0"):Embed(Blizzard)

local GetNumSubgroupMembers = _G.GetNumSubgroupMembers
local GetNumGroupMembers = _G.GetNumGroupMembers
local IsAddOnLoaded = _G.IsAddOnLoaded
local GetCVarBool = _G.GetCVarBool

local CompactRaidFrameManager_GetSetting = _G.CompactRaidFrameManager_GetSetting
local CompactRaidFrameManager_SetSetting = _G.CompactRaidFrameManager_SetSetting
local PartyMemberFrame_UpdateMember = _G.PartyMemberFrame_UpdateMember
local CompactPartyFrame_UpdateShown = _G.CompactPartyFrame_UpdateShown
local CompactRaidFrameManager = _G.CompactRaidFrameManager
local GetDisplayedAllyFrames = _G.GetDisplayedAllyFrames
local TemporaryEnchantFrame = _G.TemporaryEnchantFrame
local ConsolidatedBuffs = _G.ConsolidatedBuffs
local PlayerTalentFrame = _G.PlayerTalentFrame
local BuffFrame = _G.BuffFrame

local oocWrapper = LUI.OutOfCombatWrapper
local argcheck = LUI.argcheck

local hidden = {}

local show, hide, hook, unhook
do
	if LUI.IsRetail then
		Blizzard:SecureHook("OrderHall_LoadUI", function()
			LUI:Kill(_G.OrderHallCommandBar)
		end)
	end
	hook = setmetatable({}, {
		__call = function(t, type, hookto)
			if t[type] then return end
			t[type] = hookto

			Blizzard:SecureHook(hookto, hide[type])
		end
	})
	unhook = function(type)
		Blizzard:Unhook(hook[type])
		hook[type] = nil
	end
	
	local compact_raid

	local actionbarFrames = {
		MainMenuBar = true,
		MultiBarLeft = true,
		MultiBarRight = true,
		MultiBarBottomLeft = true,
		MultiBarBottomRight = true,
		MultiCastActionBarFrame = true,
		ShapeshiftBarFrame = true,
		PossessBarFrame = true,
		ExtraActionBarFrame = true,
	}
	local actionbarStates = {}
	local setActonbarToShown = function(frame)
		actionbarStates[frame] = 1
	end
	local setActionbarToHidden = function(frame)
		actionbarStates[frame] = nil
	end

	hide = {
		party = function()
			for i = 1, 4 do
				local frame = _G["PartyMemberFrame"..i]
				frame:UnregisterAllEvents()
				frame:Hide()
				frame.Show = LUI.dummy
			end

			UIParent:UnregisterEvent("GROUP_ROSTER_UPDATE")

			if _G.CompactPartyFrame then
				_G.CompactPartyFrame:UnregisterEvent("GROUP_ROSTER_UPDATE")
				_G.CompactPartyFrame:Hide()

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
			if CompactRaidFrameManager then
				CompactRaidFrameManager:UnregisterEvent("GROUP_ROSTER_UPDATE")
				CompactRaidFrameManager:UnregisterEvent("PLAYER_ENTERING_WORLD")
				CompactRaidFrameManager:Hide()
				compact_raid = CompactRaidFrameManager_GetSetting("IsShown")
				if compact_raid and compact_raid ~= "0" then
					CompactRaidFrameManager_SetSetting("IsShown", "0")
				end
				hook("raid", "CompactRaidFrameManager_UpdateShown")
			end
		end,

		arena = function()
			if IsAddOnLoaded("Blizzard_ArenaUI") then
				_G.ArenaEnemyFrames:UnregisterAllEvents()
			else
				hook("arena", "Arena_LoadUI")
			end
		end,

		aura = function()
			BuffFrame:Hide()
			TemporaryEnchantFrame:Hide()
			BuffFrame:UnregisterAllEvents()
		end,
		actionbars = function()
			for frame, hide in pairs(actionbarFrames) do
				frame = _G[frame]
				-- Set frame to ignore Blizzard's UIPARENT_MANAGED_FRAME_POSITIONS
				frame.ignoreFramePositionManager = true

				if hide then
					frame:UnregisterAllEvents()

					actionbarStates[frame] = frame:IsShown()
					frame.Show = setActonbarToShown
					frame:Hide()
					frame.Hide = setActionbarToHidden
				end
			end

			local talentFrame = PlayerTalentFrame
			if talentFrame then
				talentFrame:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
			else
				Blizzard:SecureHook("TalentFrame_LoadUI", function()
					Blizzard:Unhook("TalentFrame_LoadUI")
					PlayerTalentFrame:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
				end)
			end
		end,
	}
	show = {
		party = function()
			Blizzard:Unhook("CompactPartyFrame_Generate")
			for i = 1, 4 do
				local frame = _G["PartyMemberFrame"..i]
				frame.Show = nil -- reset access to the frame metatable's show function
				frame:GetScript("OnLoad")(frame)
				frame:GetScript("OnEvent")(frame, "GROUP_ROSTER_UPDATE")
				PartyMemberFrame_UpdateMember(frame)
			end
			UIParent:RegisterEvent("GROUP_ROSTER_UPDATE")
			if _G.CompactPartyFrame then
				_G.CompactPartyFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
				if GetDisplayedAllyFrames then
					if GetDisplayedAllyFrames() == "compact-party" then
						_G.CompactPartyFrame:Show()
					end
				elseif GetCVarBool("useCompactPartyFrames") and GetNumSubgroupMembers() > 0 and GetNumGroupMembers() == 0 then
					_G.CompactPartyFrame:Show()
				end
			end
		end,

		raid = function()
			CompactRaidFrameManager:RegisterEvent("GROUP_ROSTER_UPDATE")
			CompactRaidFrameManager:RegisterEvent("PLAYER_ENTERING_WORLD")
			if GetDisplayedAllyFrames then
				if GetDisplayedAllyFrames() == "raid" then
					CompactRaidFrameManager:Show()
				end
			elseif GetNumGroupMembers() > 0 then
				CompactRaidFrameManager:Show()
			end
			if compact_raid and compact_raid ~= "0" then
				CompactRaidFrameManager_SetSetting("IsShown", "1")
			end
		end,

		arena = function()
			if IsAddOnLoaded("Blizzard_ArenaUI") then
				_G.ArenaEnemyFrames:GetScript("OnLoad")(_G.ArenaEnemyFrames)
				_G.ArenaEnemyFrames:GetScript("OnEvent")(_G.ArenaEnemyFrames, "VARIABLES_LOADED")
			end
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
		actionbars = function()
			for frame, hide in pairs(actionbarFrames) do
				frame = _G[frame]
				-- re-initiate frame into Blizzard's UIPARENT_MANAGED_FRAME_POSITIONS
				frame.ignoreFramePositionManager = nil

				if hide then
					frame.Show = nil
					frame.Hide = nil

					local onload = frame:GetScript("OnLoad")
					if onload then
						onload(frame)
					end

					if actionbarStates[frame] then
						frame:Show()
						actionbarStates[frame] = nil
					end
				end
			end

			local talentFrame = PlayerTalentFrame
			if talentFrame then
				talentFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED") -- TODO: find out if we need to force fire this after registering it
			else
				Blizzard:Unhook("TalentFrame_LoadUI")
			end
		end
	}

	for k, v in pairs(hide) do
		hide[k] = oocWrapper(v)
	end
	for k, v in pairs(show) do
		show[k] = oocWrapper(v)
	end
end

function Blizzard:Hide(type)
	argcheck(type, "typeof", "string")
	type = type:lower()

	if not hide[type] then return end
	if hidden[type] then return end

	hidden[type] = true
	hide[type]()
	if LUI.IsRetail then _G.MicroButtonAndBagsBar:Hide() end -- does not work with actionbarframes function.
	return true -- inform that the object was hidden
end

function Blizzard:Show(type)
	argcheck(type, "typeof", "string")
	type = type:lower()

	if not show[type] then return end
	if not hidden[type] then return end

	hidden[type] = nil
	if hook[type] then
		unhook(type)
	end
	show[type]()
	if LUI.IsRetail then _G.MicroButtonAndBagsBar:Show() end
	return true -- inform that the object was shown
end

function Blizzard:IsHideable(type)
	argcheck(type, "typeof", "string")

	return hide[type:lower()] ~= nil
end

LUI.Profiler.TraceScope(Blizzard, "HideBlizzard", "LUI", 2)