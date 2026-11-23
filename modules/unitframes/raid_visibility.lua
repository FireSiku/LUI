-- Suppress only the native raid container while LUI provides the raid frames.
-- Roleset filtering survives native Show calls without changing saved options,
-- parents, scripts, events or Blizzard's secure visibility driver.
local LUI = select(2, ...)
local module = LUI:GetModule("Unitframes")
local wanted, ownedFrame, eventFrame, queued
local hooked = setmetatable({}, {__mode = "k"})

local function CanAccess(frame)
    return frame and not (frame.IsForbidden and frame:IsForbidden())
        and not (frame.CanBeAccessedInContext and not frame:CanBeAccessedInContext())
end

local function HasBlock(frame)
    for _, name in ipairs(frame:GetRolesetNames()) do
        if name == "alwaysBlocked" then return true end
    end
    return false
end

local function QueueRefresh()
    if queued then return end
    queued = true
    C_Timer.After(0, function()
        queued = false
        module:RefreshBlizzardRaidVisibility()
    end)
end

function module:RefreshBlizzardRaidVisibility()
    local hide = wanted and self:IsEnabled()
    local frame = _G.CompactRaidFrameContainer
    if not InCombatLockdown() then
        if ownedFrame and (not hide or ownedFrame ~= frame) and CanAccess(ownedFrame) then
            ownedFrame:RemoveRoleset("alwaysBlocked")
            ownedFrame = nil
        end
        if hide and CanAccess(frame) then
            -- Respect an existing block owned by Blizzard or another addon.
            -- Only remove a tag that this module actually added.
            if not HasBlock(frame) then
                frame:AddRoleset("alwaysBlocked")
                ownedFrame = frame
            end
            if not hooked[frame] then
                hooked[frame] = true
                hooksecurefunc(frame, "SetRolesets", function()
                    if wanted then QueueRefresh() end
                end)
            end
        end
    end

    eventFrame:UnregisterAllEvents()
    if hide or ownedFrame then
        for _, event in ipairs({"PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE",
            "PLAYER_REGEN_ENABLED", "ADDON_RESTRICTION_STATE_CHANGED", "ADDON_LOADED"}) do
            eventFrame:RegisterEvent(event)
        end
    end
end

function module:SetBlizzardRaidFramesHidden(hidden)
    wanted = hidden == true
    if not eventFrame then
        eventFrame = CreateFrame("Frame")
        eventFrame:SetScript("OnEvent", function(_, event, addon)
            if event ~= "ADDON_LOADED" or addon == "Blizzard_CompactRaidFrames"
                or addon == "Blizzard_UnitFrame" then
                module:RefreshBlizzardRaidVisibility()
            end
        end)
    end
    self:RefreshBlizzardRaidVisibility()
end
