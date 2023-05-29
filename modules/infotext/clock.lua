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
local TimeBreakDown = _G.ChatFrame_TimeBreakDown
local GetInstanceInfo = _G.GetInstanceInfo
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

--Instance Difficulty constants
--local TAG_GUILD_GROUP = " |cff66c7ffG|r"
local RAID_INFO_WORLD_BOSS = _G.RAID_INFO_WORLD_BOSS

-- Do not localize those strings. All of them have an associated localized InfoClock_Instance_* entry
-- List as per  https://wowpedia.fandom.com/wiki/DifficultyID
local INSTANCE_DIFFICULTY_FORMAT = {
	[1]  = "Normal",    -- 5man Normal
	[2]  = "Heroic",    -- 5man Heroic
	[3]  = "Normal",    -- 10man Normal (Legacy)
	[4]  = "Normal",    -- 25man Normal (Legacy)
	[5]  = "Heroic",    -- 10man Heroic (Legacy)
	[6]  = "Heroic",    -- 25man Heroic (Legacy)
	[7]  = "LFR",       -- 25man Raid Finder (Legacy)
	[8]  = "Mythic", 	-- 5man Mythic Keystone / Challenge Mode 
	[9]  = "Normal",    -- 40man Normal
	[11] = "Heroic",    -- 3man Heroic Scenario
	[12] = "Normal",    -- 3man Scenario
	[14] = "Normal",    -- Flexible Normal
	[15] = "Heroic",    -- Flexible Heroic
	[16] = "Mythic",    -- 20man Mythic
	[17] = "LFR",       -- Flexible Raid Finder
	[18] = "Event",     -- Event Party
	[19] = "Event",     -- Event Raid
	[20] = "Event",     -- Event Scenario
	[23] = "Mythic",    -- 5man Mythic
	[24] = "Timewalk",  -- Timewalking Dungeons
	[25] = "Event",     -- World PVP Scenario
	[29] = "Event",     -- PvEvP Scenario
	[30] = "Event",     -- Event
	[32] = "Event",     -- World PVP Scenario
	[33] = "Timewalk",  -- Timewalking Raid
	[34] = "Normal",    -- PvP
	[38] = "Normal",    -- Normal Scenario
	[39] = "Heroic",    -- Heroic Scenario
	[40] = "Mythic",    -- Mythic Scenario
	[45] = "Heroic",    -- PvP Scenario (DisplayHeroic)
	[147] = "Normal",    -- Normal Warfronts
	[149] = "Heroic",    -- Heroic Warfronts
	[150] = "Normal",   -- Normal Party
	[151] = "Timewalk", -- Timewalking LFR
}

local COLOR_CODES = {
	Guild = "|cff66c7ff",
	Normal = "|cff00ff00",
	Heroic = "|cffff0000",
	LFR = "|cffaaaaaa",
	Mythic = "|cffff0000",
	Event = "|cffaaaaaa",
	Timewalk = "|cffaaaaaa",
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
	local diff = INSTANCE_DIFFICULTY_FORMAT[difficulty]
	if not diff then return end
	
	local LString = format("InfoClock_Instance_%s", diff)
	return L[LString], COLOR_CODES[diff]
end

if LUI.IsRetail then
	function element:UpdateInvites()
		invitesPending = (GameTimeFrame and GameTimeFrame.pendingCalendarInvites > 0) and true or false
	end

	function element:UpdateGuildParty()
		--local TAG_GUILD_GROUP = " |cff66c7ffG|r"
		guildParty = InGuildParty() and string.format(" %s%s|r", COLOR_CODES.Guild, L["InfoClock_Instance_Guild"]) or nil
	end
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

	--HACK: Blizzard's TimeFrame checkboxes do not update when cvars are changed, so make sure they are up to date.
	TimeManagerMilitaryTimeCheck:SetChecked((cvarMilitary) and true or false)
	TimeManagerLocalTimeCheck:SetChecked((cvarLocal) and true or false)
	-- Only Refresh the options if the option panel is loaded.
	if element.RefreshOptionsPanel then
		element:RefreshOptionsPanel()
	end
	element:UpdateClock()
end

function element:GetTime(useLocal)
	local Hr, Min, PM
	if useLocal then
		Hr, Min = tonumber(date("%H")), date("%M")
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
		local timeFormat = (module.db.profile.instanceDifficulty and instanceInfo) and "%s (%s%s)" or "%s"
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

	local db = module.db.profile
	local oneraid -- Used so we dont display "Saved Raids:" unless you are saved to at least one.
	if db.showSavedRaids then
		for i = 1, GetNumSavedInstances() do
			local name, _, reset, difficulty, locked, extended, _,
					isRaid, maxPlayers, _, maxBosses, defeatedBosses = GetSavedInstanceInfo(i)
			if isRaid and (locked or extended) then
				local localizedDiff = GetLocalizedDifficulty(difficulty)
				local r, g, b = 1, 1, 1
				if extended then r, g, b = 0.5, 1, 0.5 end
				oneraid = OneRaidCheck(oneraid)
				local nameFormat = format("%s |cffaaaaaa%s%s", name, maxPlayers, localizedDiff)
				nameFormat = format("%s (%s/%s)", nameFormat, defeatedBosses, maxBosses)
				GameTooltip:AddDoubleLine(nameFormat, formatTime(reset), 1,1,1, r,g,b)
			end
		end
	end
	--Check for World Bosses too
	if LUI.IsRetail and db.showWorldBosses then
		for i = 1, GetNumSavedWorldBosses() do
			local name, _, reset = GetSavedWorldBossInfo(i)
			oneraid = OneRaidCheck(oneraid)
			GameTooltip:AddDoubleLine(format("%s |cffaaaaaa(%s)", name, RAID_INFO_WORLD_BOSS),
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
	if LUI.IsRetail then element:RegisterEvent("GUILD_PARTY_STATE_UPDATED", "UpdateGuildParty") end
	if LUI.IsRetail then element:RegisterEvent("PLAYER_DIFFICULTY_CHANGED", "UpdateInstanceInfo") end
	element:RegisterEvent("INSTANCE_GROUP_SIZE_CHANGED", "UpdateInstanceInfo")
	element:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateInstanceInfo")
	if LUI.IsRetail then element:UpdateGuildParty() end
	element:UpdateInstanceInfo()

	-- Update cached CVar data.
	element:SecureHookScript(TimeManagerMilitaryTimeCheck, "OnClick", "UpdateCVar")
	element:SecureHookScript(TimeManagerLocalTimeCheck, "OnClick", "UpdateCVar")
	element:UpdateCVar()

	if LUI.IsRetail then
		-- Update calendar invites
		element:RegisterEvent("CALENDAR_UPDATE_PENDING_INVITES", "UpdateInvites")
		element:UpdateInvites()
	end

	element:AddUpdate("UpdateClock", CLOCK_UPDATE_TIME)
end
