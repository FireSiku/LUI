---@type string, LUIAddon
local addonName, LUI = ...
local L = LUI.L
local db, default

-- Increase whenever there are changes that would require remediation
-- The changes related to the version should be appended in an new IF block of the ApplyUpdate function.
local DB_VERSION = 1

StaticPopupDialogs["LUI_DB_UPDATE"] = {
	preferredIndex = 3,
	text = "This version of LUI contains settings that uses a different format. Do you want LUI to convert the affected settings to the new format?\n\nNote: Do not downgrade the version of LUI after conversion has been done. Behavior may be unexpected.",
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function() LUI:ApplyUpdate(db.dbVersion) end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 0,
}

function LUI:CheckUpdate()
	db = LUI.db.profile
	default = LUI.defaults.profile

	if DB_VERSION > db.dbVersion then
		StaticPopup_Show("LUI_DB_UPDATE")
	end
end

--Test function
function LUI:_Resync()
	LUI:ApplyUpdate(0)
end

-- For the most part, conversion should be in this format. 
-- if db.Old then
--     db.New = db.Old
--     db.Old = nil
-- end

--- Helper function to reduce the overall number of IF statements
---@param old_db table @ Table that contains the old setting.
---@param old_name string @ The old name of the setting to look up in the db
---@param new_name string @ The new name of the setting that should be updated
---@param new_db table? @ If the new setting is in different table. If missing, it will use old_db as the destination
local function Convert(old_db, old_name, new_name, new_db)
	if not old_db then return end -- Nothing to convert.

	assert(type(old_db) == "table", "Setting conversion failed for "..old_name..". Expected table, received "..type(old_db))
	if not new_db then new_db = old_db end
	if old_db[old_name] then
		new_db[new_name] = old_db[old_name]
		--old_db[old_name] = nil
	end
end

function LUI:ApplyUpdate(ver)
	
	if ver < 1 then
		-- Unitframes conversions
		local uf_db = LUI:GetModule("Unitframes").db.profile
		local units = {
			Player = "player",
			Pet = "pet",
			Focus = "focus",
			Target = "target",
			ToT = "targettarget",
			ToToT = "targettargettarget",
			Party = "party",
			Raid = "raid",
			Boss = "boss",
			Arena = "arena",
			Maintank = "maintank",
			ArenaPet = "arenapet",
			PartyPet = "partypet",
			PetTarget = "pettarget",
			BossTarget = "bosstarget",
			FocusTarget = "focustarget",
			PartyTarget = "partytarget",
			ArenaTarget = "arenatarget",
			MaintankTarget = "maintanktarget",
			MaintankToT = "maintanktargettarget",
		}
		
		if uf_db.Player then
			Convert(uf_db.Player.Bars,  "HealPrediction", "HealthPrediction")
			Convert(uf_db.Player.Bars,  "DruidMana",      "AdditionalPower")
			Convert(uf_db.Player.Texts, "DruidMana",      "AdditionalPower")
			Convert(uf_db.Player.Bars,  "AltPower",       "AlternativePower")
			Convert(uf_db.Player.Texts, "AltPower",       "AlternativePower")
			Convert(uf_db.Player.Bars,  "HolyPower",      "ClassPower")
			Convert(uf_db.Player.Bars,  "Chi",            "ClassPower")
			Convert(uf_db.Player.Bars,  "WarlockBar",     "ClassPower")
			Convert(uf_db.Player.Bars,  "ArcaneCharges",  "ClassPower")
			Convert(uf_db.Player.Texts, "WarlockBar",     "ClassPower")

			uf_db.Player.Bars.ShadowOrbs = nil
			uf_db.Player.Bars.Eclipse = nil
			uf_db.Player.Texts.Eclipse = nil
			uf_db.Player.Texts.WarlockBar = nil
			uf_db.Colors.ShadowOrbsBar = nil
			uf_db.Colors.EclipseBar = nil
		end

		for oldUnit, unitId in pairs(units) do
			--- Convert the tables to use unitId keys, changes Player -> player,  ToT > targettargettarget and so on.
			Convert(uf_db, oldUnit, unitId)
			local unit_db = uf_db[unitId]

			Convert(unit_db.Bars,  "Health", "HealthBar", unit_db)
			Convert(unit_db.Bars,  "Power",  "PowerBar", unit_db)
			Convert(unit_db.Bars,  "TotalAbsorb", "TotalAbsorbBar", unit_db)
			Convert(unit_db.Bars,  "HealthPrediction", "HealthPredictionBar", unit_db)
			Convert(unit_db.Bars,  "AlternativePower", "AlternativePowerBar", unit_db)
			Convert(unit_db.Bars,  "AdditionalPower", "AdditionalPowerBar", unit_db)
			Convert(unit_db.Bars,  "ClassPower", "ClassPowerBar", unit_db)
			Convert(unit_db.Bars,  "ComboPoints", "ComboPointsBar", unit_db)
			Convert(unit_db.Bars,  "Totemsw", "TotemsBar", unit_db)
			Convert(unit_db.Bars,  "Runes", "RunesBar", unit_db)
			Convert(unit_db.Texts, "Combat", "CombatFeedback", unit_db)
			Convert(unit_db.Texts, "Name", "NameText", unit_db)
			Convert(unit_db.Texts, "Health", "HealthText", unit_db)
			Convert(unit_db.Texts, "Power", "PowerText", unit_db)
			Convert(unit_db.Texts, "PvP", "PvPText", unit_db)
			Convert(unit_db.Texts, "HealthPercent", "HealthPercentText", unit_db)
			Convert(unit_db.Texts, "HealthMissing", "HealthMissingText", unit_db)
			Convert(unit_db.Texts, "PowerPercent", "PowerPercentText", unit_db)
			Convert(unit_db.Texts, "PowerMissing", "PowerMissingText", unit_db)
			Convert(unit_db.Texts, "AlternativePower", "AlternativePowerText", unit_db)
			Convert(unit_db.Texts, "AdditionalPower", "AdditionalPowerText", unit_db)
			Convert(unit_db.Texts, "ClassPower", "ClassPowerText", unit_db)
			Convert(unit_db.Icons, "Leader", "LeaderIndicator", unit_db)
			Convert(unit_db.Icons, "Role", "GroupRoleIndicator", unit_db)
			Convert(unit_db.Icons, "Raid", "RaidMarkerIndicator", unit_db)
			Convert(unit_db.Icons, "Resting", "RestingIndicator", unit_db)
			Convert(unit_db.Icons, "Combat", "CombatIndicator", unit_db)
			Convert(unit_db.Icons, "PvP", "PvIndicator", unit_db)
			if unit_db.Castbar then
				Convert(unit_db.Castbar.Text, "Name", "NameText", unit_db.Castbar)
				Convert(unit_db.Castbar.Text, "Time", "TimeText", unit_db.Castbar)
			end
		end
	end

	ver = DB_VERSION
end

--[[
7: https://www.wowinterface.com/forums/showthread.php?t=55422
8: https://www.wowinterface.com/forums/showthread.php?t=56361
9: https://www.wowinterface.com/forums/showthread.php?t=56943
10: https://www.wowinterface.com/forums/showthread.php?t=58257
Player.Bars.DruidMana
Player.Texts.DruidMana
-> AdditionalPower

Player.Bars.AltPower
Player.Texts.AltPower
-> AlternativePower

Player.Bars.HolyPower
Player.Bars.Chi
Player.Bars.WarlockBar
Player.Bars.ArcaneCharges
-> ClassPower

[All].Texts.Combat
-> CombatFeedback

[All].Icons -> Indicators
Lootmaster	-> MasterLooter
Leader		-> Leader
Role		-> GroupRole
Raid		-> RaidMarker
Resting		-> Resting
Combat		-> Combat
PvP		
ReadyCheck

Player.Bars.ShadowOrbs
Player.Bars.Eclipse
Player.Texts.Eclipse
Player.Texts.WarlockBar
-> nil
]]