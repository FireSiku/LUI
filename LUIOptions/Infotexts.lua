-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class Opt
local Opt = select(2, ...)

---@type AceLocale.Localizations, LUI.Infotext, AceDB-3.0
local L, module, db = Opt:GetLUIModule("Infotext")
if not module or not module.registered then return end

local Infotext = Opt:CreateModuleOptions("Infotext", module)

-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################

local function InfoTextGroup(name)
    local group = Opt:Group({name = name, db = db[name], args = {
		Header = Opt:Header({name = name}),
		Enable = Opt:Toggle({name = "Enable", width = "full"}),
		X = Opt:Input({name = "X Value", width = "half"}),
		Y = Opt:Input({name = "Y Value", width = "half"}),
		Point = Opt:Select({name = L["Anchor Point"], desc = "Set which part of the screen the "..name.." infotext will be anchored to.", values = LUI.Corners}), --input for now
	}})
	return group
end

-- ####################################################################################################################
-- ##### Options Tables ###############################################################################################
-- ####################################################################################################################

local SettingsArgs = {}
for name, obj in module:IterateModules() do
    SettingsArgs[name] = InfoTextGroup(name)
end

Infotext.args = {
	Header = Opt:Header({name = "Infotext"}),
	Settings = Opt:Group({name = "Individual Settings", args = SettingsArgs}),
	General = Opt:Group({name = "Global Settings", args = {
		Title = Opt:Color({name = "Title Color", hasAlpha = false}),
		Hint = Opt:Color({name = "Hint Color", hasAlpha = false}),
	}}),
}

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

local GoldInfotext = Infotext.args.Settings.args.Gold.args
GoldInfotext.ShowConnected = Opt:Toggle({name = "Include Connected Realms in Server Total when possible", width = "full",
	desc = "Realms that are connected to your character's realm will show as a single entry in the realm list"})
GoldInfotext.GoldPlayerReset = Opt:Select({name = "Reset Player", desc = "Choose the player you want to clear Gold data for.", values = goldPlayerArray,
											get = function() return goldPlayerArray[goldPlayerReset] end, -- Get
											set = function(info, value) goldPlayerReset = value end}) -- Set
GoldInfotext.GoldResetButton = Opt:Execute({name = "Reset", desc = "Clear Gold data for selected character.", func = ResetGold})
