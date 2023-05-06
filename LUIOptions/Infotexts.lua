-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, Opt
local optName, Opt = ...
local L, module, db = Opt:GetLUIModule("Infotext")
if not module or not module.registered then return end


-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################

local function InfoTextGroup(name, order)
    local group = Opt:Group(name, nil, order, nil, nil, nil, Opt.GetSet(db[name]))
    group.args.Header = Opt:Header(name, 1)
    group.args.Enable = Opt:Toggle("Enable", nil, 2, nil, "full")
	group.args.X = Opt:Input("X Value", nil, 3, nil, "half")
	group.args.Y = Opt:Input("Y Value", nil, 4, nil, "half")
	group.args.Point = Opt:Select(L["Anchor Point"],  "Set which part of the screen the "..name.." infotext will be anchored to.", 5, LUI.Corners) --input for now
	return group
end

-- ####################################################################################################################
-- ##### Options Tables ###############################################################################################
-- ####################################################################################################################

Opt.options.args.Infotext = Opt:Group("Infotexts", nil, nil, "tab", Opt.IsModDisabled, nil, Opt.GetSet(db))
Opt.options.args.Infotext.handler = module

local Infotext = {
	Header = Opt:Header("Infotext", 1),
	Settings = Opt:Group("Individual Settings", nil, 2),
	General = Opt:Group("Global Settings", nil, 3),
}

Infotext.General.args = {
	Title = Opt:Color("Title Color", nil, 2, false),
	Hint = Opt:Color("Hint Color", nil, 3, false),
	--Infotext = Opt:FontMenu("Infotext Font", nil, 4),
}

local count = 10
for name, obj in module:IterateModules() do
    Infotext.Settings.args[name] = InfoTextGroup(name, count)
    count = count + 1
end

Opt.options.args.Infotext.args = Infotext

-- ####################################################################################################################
-- ##### Gold Infotext ################################################################################################
-- ####################################################################################################################

local goldDB = module.db.global.Gold
local goldPlayerReset = ""
local goldPlayerArray = {}
for faction, realmData in pairs(goldDB) do
	for realm, playerData in pairs(realmData) do
		for player, money in pairs(playerData) do
			goldPlayerArray[realm.."-"..player] = realm.."-"..player
		end
	end
end

-- Rewrite the function above after removing the self argument
local function ResetGold()
	local player = goldPlayerReset
	local realm, name = strsplit("-", player)
	for faction, factionData in pairs(goldDB) do
		if factionData[realm][name] then
			if name == LUI.playerName then
				goldDB[faction][realm][name] = GetMoney()
			else
				goldDB[faction][realm][name] = nil
				goldPlayerArray[player] = nil
			end
			break
		end
	end

	module:GetElement("Gold"):UpdateRealmMoney()
	module:GetElement("Gold"):UpdateGold()
end

local GoldInfotext = Infotext.Settings.args.Gold.args
GoldInfotext.ShowConnected = Opt:Toggle("Include Connected Realms in Server Total when possible", "Realms that are connected to your character's realm will show as a single entry in the realm list", 6, nil, "full")
GoldInfotext.GoldPlayerReset = Opt:Select("Reset Player", "Choose the player you want to clear Gold data for.", 7, goldPlayerArray, nil, nil, nil,
											function() return goldPlayerArray[goldPlayerReset] end, -- Get
											function(info, value) goldPlayerReset = value end) -- Set
GoldInfotext.GoldResetButton = Opt:Execute("Reset", "Clear Gold data for selected character.", 8, ResetGold)

-- ####################################################################################################################
-- ##### Clock Infotext ###############################################################################################
-- ####################################################################################################################

--[[
	function element:LoadOptions()
	local function MilitaryTime(info_, value)
		--Set
		if type(value) == "boolean" then
			SetCVar(CVAR_MILITARY, value and 1 or 0, true)
			element:UpdateCVar()
		--Get
		else
			return cvarMilitary
		end
	end
	local function LocalTime(info_, value)
		--Set
		if type(value) == "boolean" then
			SetCVar(CVAR_LOCAL, value and 1 or 0, true)
			element:UpdateCVar()
		--Get
		else
			return cvarLocal
		end
	end
	local militaryMeta = { get = MilitaryTime, set = MilitaryTime }
	local localMeta = { get = LocalTime, set = LocalTime }

	local options = {
		setClock24h = element:NewToggle(TIMEMANAGER_24HOURMODE, nil, 1, militaryMeta, "normal"),
		setClockLocal = element:NewToggle(TIMEMANAGER_LOCALTIME, nil, 2, localMeta, "normal"),
		instanceDifficulty = element:NewToggle(L["InfoClock_InstanceDifficulty_Name"],
		                                       L["InfoClock_InstanceDifficulty_Desc"], 3, "UpdateClock"),
		showSavedRaids = element:NewToggle(L["InfoClock_ShowSavedRaids_Name"],
		                                   L["InfoClock_ShowSavedRaids_Desc"], 5, "UpdateTooltip"),
		showWorldBosses = element:NewToggle(L["InfoClock_ShowWorldBosses_Name"],
		                                    L["InfoClock_ShowWorldBosses_Desc"], 6, "UpdateTooltip"),

	}
	return options
end
]]
