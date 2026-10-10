-- Use Blizzard's native swing timer and its own saved setting. Do not copy the
-- CVar into LUI profiles or overwrite it at login / on a profile change.
local LUI = select(2, ...)
local module = LUI:GetModule("UI Elements")

function module:IsSwingTimerAvailable()
    return LUI:HasClientFeature("SwingTimer")
end

function module:GetSwingTimerEnabled()
    return self:IsSwingTimerAvailable() and C_CVar.GetCVarBool("showSwingTimer") or false
end

function module:SetSwingTimerEnabled(enabled)
    if InCombatLockdown() or not self:IsSwingTimerAvailable() then return end
    C_CVar.SetCVar("showSwingTimer", enabled and "1" or "0")
end
