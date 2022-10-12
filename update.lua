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
        local units = {"Player", "Target", "ToT", "ToToT", "Focus", "FocusTarget", "Pet", "PetTarget", "Party", "PartyTarget", "PartyPet", "Boss", "BossTarget", "Maintank", "MaintankTarget", "MaintankToT", "Arena", "ArenaTarget", "ArenaPet", "Raid"}

        Convert(uf_db.Player.Bars, "HealPrediction", "HealthPrediction")
        Convert(uf_db.Player.Bars, "DruidMana", "AdditionalPower")
        Convert(uf_db.Player.Texts, "DruidMana", "AdditionalPower")
        Convert(uf_db.Player.Bars, "AltPower", "AlternativePower")
        Convert(uf_db.Player.Texts, "AltPower", "AlternativePower")
        Convert(uf_db.Player.Bars, "HolyPower", "ClassPower")
        Convert(uf_db.Player.Bars, "Chi", "ClassPower")
        Convert(uf_db.Player.Bars, "WarlockBar", "ClassPower")
        Convert(uf_db.Player.Bars, "ArcaneCharges", "ClassPower")
       
        for _, unit in ipairs(units) do
            Convert(uf_db[unit], "Icons", "Indicators")
            Convert(uf_db[unit].Texts, "Combat", "CombatFeedback")
            Convert(uf_db[unit].Icons, "Raid", "RaidIcon")
        end
        uf_db.Player.Bars.ShadowOrbs = nil
        uf_db.Player.Bars.Eclipse = nil
        uf_db.Player.Texts.Eclipse = nil
        uf_db.Player.Texts.WarlockBar = nil
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
Raid		-> RaidRole
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