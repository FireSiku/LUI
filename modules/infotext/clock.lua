-- Clock Infotext

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)
local L = LUI.L

---@class InfotextModule
local module = LUI:GetModule("Infotext")
local element = module:NewElement("Clock", "AceEvent-3.0", "AceHook-3.0")
LUI.Profiler.TraceScope(module, "Clock", "Infotext", 2)

-- local copies
local gsub, format, tonumber, date = gsub, format, tonumber, date
local GetNumSavedWorldBosses = _G.GetNumSavedWorldBosses
local GetSavedWorldBossInfo = _G.GetSavedWorldBossInfo
local GetSavedInstanceInfo = _G.GetSavedInstanceInfo
local GetNumSavedInstances = _G.GetNumSavedInstances
local TimeBreakDown = _G.ChatFrameUtil.TimeBreakDown
local GetInstanceInfo = _G.GetInstanceInfo
local GetDifficultyInfo = _G.GetDifficultyInfo
local GameTimeFrame = _G.GameTimeFrame
local InGuildParty = _G.InGuildParty
local IsInInstance = _G.IsInInstance
local GetGameTime = _G.GetGameTime
local GetCVarBool = _G.GetCVarBool

-- local variables
local cvarLocal, cvarMilitary -- Cache containing CVars
local guildParty         -- If there's a G or not in the text
local instanceInfo       -- Any instance tag would go in this.
local invitesPending = false

-- constants
local GAMETIME_TOOLTIP_TOGGLE_CALENDAR = _G.GAMETIME_TOOLTIP_TOGGLE_CALENDAR
local TIMEMANAGER_TOOLTIP_LOCALTIME = _G.TIMEMANAGER_TOOLTIP_LOCALTIME
local TIMEMANAGER_TOOLTIP_REALMTIME = _G.TIMEMANAGER_TOOLTIP_REALMTIME
local TIMEMANAGER_TITLE = _G.TIMEMANAGER_TITLE
local TIMEMANAGER_PM = _G.TIMEMANAGER_PM
local TIMEMANAGER_AM = _G.TIMEMANAGER_AM
local CVAR_MILITARY = "timeMgrUseMilitaryTime"
local CVAR_LOCAL = "timeMgrUseLocalTime"

local CLOCK_UPDATE_TIME = 1

local RAID_INFO_WORLD_BOSS = _G.RAID_INFO_WORLD_BOSS

local COLOR_CODES = {
	Guild = "|cff66c7ff",
	Normal = "|cff00ff00",
	Heroic = "|cffff0000",
	LFR = "|cffaaaaaa",
}

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

--First we format the secs into a day/hour/minute format. The leading space is necessary.
--Then we remove spaces followed by a 0, such as 0d or 0h. Those extra spaces are then trimmed.
local function formatTime(sec)
	local timeLeft = format(L["InfoClock_LockoutTimeLeft_Format"], TimeBreakDown(sec))
	timeLeft = gsub(timeLeft, L["InfoClock_LockoutTimeLeftGsub_Format"], "")
	return timeLeft:trim()
end

local function OneRaidCheck(bool)
	if not bool then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(L["InfoClock_SavedRaids"])
	end
	return true
end

local function GetLocalizedDifficulty(difficulty)
	local name, _, isHeroic, isChallengeMode, displayHeroic, displayMythic, _, isLFR = GetDifficultyInfo(difficulty)
	if not name then return end
	local colorCode = COLOR_CODES.Normal
	if isLFR then
		colorCode = COLOR_CODES.LFR
	elseif isHeroic or isChallengeMode or displayHeroic or displayMythic then
		colorCode = COLOR_CODES.Heroic
	end
	return name, colorCode
end

function element:UpdateInvites()
	invitesPending = C_Calendar.GetNumPendingInvites() > 0
end

function element:UpdateGuildParty()
	guildParty = InGuildParty() and string.format(" %s%s|r", COLOR_CODES.Guild, L["InfoClock_Instance_Guild"]) or nil
end

function element:UpdateInstanceInfo()
	local isInstance, instanceType = IsInInstance()
	if isInstance then
		local _, _, difficulty, _, _, _, _, _, groupSize = GetInstanceInfo()
		local localizedDiff, colorCode = GetLocalizedDifficulty(difficulty)
		if localizedDiff and (instanceType == "raid" or instanceType == "party") then
			instanceInfo = string.format("%d %s%s|r", groupSize, colorCode, localizedDiff)
			return
		end
	end
	instanceInfo = nil
end

-- luacheck: globals TimeManagerMilitaryTimeCheck TimeManagerLocalTimeCheck
function element:UpdateCVar()
	cvarMilitary = GetCVarBool(CVAR_MILITARY)
	cvarLocal = GetCVarBool(CVAR_LOCAL)

	if _G.TimeManagerMilitaryTimeCheck then _G.TimeManagerMilitaryTimeCheck:SetChecked(cvarMilitary) end
	if _G.TimeManagerLocalTimeCheck then _G.TimeManagerLocalTimeCheck:SetChecked(cvarLocal) end
	-- Only Refresh the options if the option panel is loaded.
	if element.RefreshOptionsPanel then
		element:RefreshOptionsPanel()
	end
	element:UpdateClock()
end

function element:HookTimeManager()
	if not _G.TimeManagerMilitaryTimeCheck or not _G.TimeManagerLocalTimeCheck
		or element:IsHooked(_G.TimeManagerMilitaryTimeCheck, "OnClick") then return end
	element:SecureHookScript(_G.TimeManagerMilitaryTimeCheck, "OnClick", "UpdateCVar")
	element:SecureHookScript(_G.TimeManagerLocalTimeCheck, "OnClick", "UpdateCVar")
	element:UpdateCVar()
end

function element:ADDON_LOADED(_, addonName)
	if addonName == "Blizzard_TimeManager" then
		element:HookTimeManager()
		element:UnregisterEvent("ADDON_LOADED")
	end
end

function element:CVAR_UPDATE(_, cvarName)
	if cvarName == CVAR_MILITARY or cvarName == CVAR_LOCAL then
		element:UpdateCVar()
	end
end

function element:GetTime(useLocal)
	local Hr, Min, PM
	if useLocal then
		Hr, Min = tonumber(date("%H")), tonumber(date("%M"))
	else
		Hr, Min = GetGameTime()
	end
	if not cvarMilitary then
		PM = (Hr >= 12) and TIMEMANAGER_PM or TIMEMANAGER_AM
		if Hr > 12 then
			Hr = Hr - 12
		elseif Hr == 0 then
			Hr = 12
		end
	end

	return format("%d:%.2d %s", Hr, Min, PM or ""):trim()
end

function element:UpdateClock()
	if invitesPending then
		element.text = L["InfoClock_InvitePending"]
	else
		local timeFormat = (module.db.profile.Clock.instanceDifficulty and instanceInfo) and "%s (%s%s)" or "%s"
		element.text = format(timeFormat, element:GetTime(cvarLocal), instanceInfo or "", guildParty or "")
	end
	element:UpdateTooltip()
end

-- Click: Open Calendar Frame
-- RightClick: Open Time Manager
function element.OnClick(frame_, button)
	if button == "RightButton" then
		_G.ToggleTimeManager()
	else
		GameTimeFrame:Click()
	end
end

-- ####################################################################################################################
-- ##### Infotext Display #############################################################################################
-- ####################################################################################################################

function element.OnTooltipShow(GameTooltip)
	element:TooltipHeader(TIMEMANAGER_TITLE)

	--Display both set of times.
	GameTooltip:AddDoubleLine(cvarLocal and TIMEMANAGER_TOOLTIP_LOCALTIME or TIMEMANAGER_TOOLTIP_REALMTIME,
	                         element:GetTime(cvarLocal))
	GameTooltip:AddDoubleLine(cvarLocal and TIMEMANAGER_TOOLTIP_REALMTIME or TIMEMANAGER_TOOLTIP_LOCALTIME,
	                          element:GetTime(not cvarLocal))

	local db = module.db.profile.Clock
	local oneraid -- Used so we dont display "Saved Raids:" unless you are saved to at least one.
	if db.showSavedRaids then
		for i = 1, GetNumSavedInstances() do
			local name, _, reset, difficulty, locked, extended, _,
					isRaid, maxPlayers, _, maxBosses, defeatedBosses = GetSavedInstanceInfo(i)
			if isRaid and (locked or extended) then
				local localizedDiff = GetLocalizedDifficulty(difficulty) or ""
				local r, g, b = 1, 1, 1
				if extended then r, g, b = 0.5, 1, 0.5 end
				oneraid = OneRaidCheck(oneraid)
				local nameFormat = format("%s |cffaaaaaa%s %s|r", name, maxPlayers, localizedDiff)
				nameFormat = format("%s (%s/%s)", nameFormat, defeatedBosses, maxBosses)
				GameTooltip:AddDoubleLine(nameFormat, formatTime(reset), 1,1,1, r,g,b)
			end
		end
	end
	--Check for World Bosses too
	if db.showWorldBosses then
		for i = 1, GetNumSavedWorldBosses() do
			local name, _, reset = GetSavedWorldBossInfo(i)
			oneraid = OneRaidCheck(oneraid)
			GameTooltip:AddDoubleLine(format("%s |cffaaaaaa(%s)|r", name, RAID_INFO_WORLD_BOSS),
			                          formatTime(reset), 1,1,1, 1,1,1)
		end
	end

	element:AddHint(GAMETIME_TOOLTIP_TOGGLE_CALENDAR, L["InfoClock_Hint_Right"])
end

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function element:OnCreate()
	-- Update tags that can be found next to the clock.
	element:RegisterEvent("GUILD_PARTY_STATE_UPDATED", "UpdateGuildParty")
	element:RegisterEvent("PLAYER_DIFFICULTY_CHANGED", "UpdateInstanceInfo")
	element:RegisterEvent("INSTANCE_GROUP_SIZE_CHANGED", "UpdateInstanceInfo")
	element:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateInstanceInfo")
	element:UpdateGuildParty()
	element:UpdateInstanceInfo()

	-- Update cached CVar data.
	element:UpdateCVar()
	element:RegisterEvent("CVAR_UPDATE")
	if C_AddOns.IsAddOnLoaded("Blizzard_TimeManager") then
		element:HookTimeManager()
	else
		element:RegisterEvent("ADDON_LOADED")
	end

	element:RegisterEvent("CALENDAR_UPDATE_PENDING_INVITES", "UpdateInvites")
	element:UpdateInvites()

	element:AddUpdate("UpdateClock", CLOCK_UPDATE_TIME)
end

function element:RefreshSettings()
	element:UpdateInstanceInfo()
	element:UpdateClock()
end
