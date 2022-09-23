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

local colorGet, colorSet = Opt.ColorGetSet(db.Colors)

local function InfoTextGroup(name, order)
    local group = Opt:Group(name, nil, order, nil, nil, nil, Opt.GetSet(db[name]))
    group.args.Header = Opt:Header(name, 1)
    group.args.Enable = Opt:Toggle("Enable", nil, 2)
	group.args.X = Opt:Input("X Value", nil, 3)

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
	Title = Opt:Color("Title Color", nil, 2, false, nil, nil, nil, colorGet, colorSet),
	Hint = Opt:Color("Hint Color", nil, 3, false, nil, nil, nil, colorGet, colorSet),
	--Infotext = Opt:FontMenu("Infotext Font", nil, 4),
}

local count = 10
for name, obj in module:IterateModules() do
    Infotext.Settings.args[name] = InfoTextGroup(name, count)
    count = count + 1
end

Opt.options.args.Infotext.args = Infotext

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