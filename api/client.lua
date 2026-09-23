-- Client-specific capabilities are queried at use time so late-loaded Blizzard
-- UI remains discoverable. Shared features keep their existing implementation.
local LUI = select(2, ...)

function LUI:HasClientFeature(feature)
    if feature == "Legacy" then
        return self.IsForever and _G.LegacyMicroButton ~= nil
    elseif feature == "SwingTimer" then
        return self.IsForever and C_CVar and type(C_CVar.GetCVar) == "function"
            and type(C_CVar.GetCVarBool) == "function" and type(C_CVar.SetCVar) == "function"
            and C_CVar.GetCVar("showSwingTimer") ~= nil or false
    elseif feature == "Keyring" then
        return self.IsForever and C_ActionBar and type(C_ActionBar.ShouldShowKeyring) == "function"
            and Enum and Enum.BagIndex and Enum.BagIndex.Keyring ~= nil or false
    elseif feature == "Housing" or feature == "LFG" or feature == "EJ" then
        -- These native addons are excluded from the supported Forever build.
        return self.IsRetail
    end
    return false
end
