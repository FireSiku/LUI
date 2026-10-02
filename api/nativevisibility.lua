-- Only hide native Forever widgets that have an enabled LUI replacement.
-- Keep their parents, scripts, layout, events and bag functions intact.
local LUI = select(2, ...)

local replacements = {
    ["Experience Bars"] = {
        {name = "MainStatusTrackingBarContainer", tracking = true},
        {name = "SecondaryStatusTrackingBarContainer", tracking = true},
    },
    Bags = {
        {name = "BagsBar"},
    },
}

local eventFrame
local queued = false
local Refresh, QueueRefresh

local function CanAccess(frame, name)
    return frame and frame ~= UIParent
        and not (frame.IsForbidden and frame:IsForbidden())
        and not (frame.CanBeAccessedInContext and not frame:CanBeAccessedInContext())
        and frame:GetName() == name
end

local function RestoreShownState(state)
    local frame = state.frame
    local bars = StatusTrackingBarInfo and StatusTrackingBarInfo.BarsEnum
    -- Blizzard continues updating tracker selection while its containers are
    -- hidden. Restore that current selection, not an obsolete login snapshot.
    if state.tracking and bars and frame.shownBarIndex ~= nil then
        return frame.shownBarIndex ~= bars.None or frame.isInEditMode == true
    end
    return state.wasShown
end

local function Apply(state, enabled)
    local frame = state.frame or _G[state.name]
    if not frame then return false end
    if not CanAccess(frame, state.name) then return enabled or state.hidden end
    if InCombatLockdown() then return enabled or state.hidden end

    if enabled then
        if not state.frame then
            state.frame = frame
            frame:HookScript("OnShow", function()
                if state.hidden then
                    state.wasShown = true
                    QueueRefresh()
                end
            end)
        end
        if not state.hidden then
            state.wasShown = frame:IsShown()
            state.hidden = true
        end
        if frame:IsShown() then frame:Hide() end
    elseif state.hidden then
        local shown = RestoreShownState(state)
        state.hidden = false
        state.wasShown = nil
        if frame:IsShown() ~= shown then frame:SetShown(shown) end
    end
    return false
end

Refresh = function()
    local active, pending = false, false
    for _, states in pairs(replacements) do
        active = active or states.enabled
        for _, state in ipairs(states) do
            pending = Apply(state, states.enabled) or pending
        end
    end

    eventFrame:UnregisterAllEvents()
    if active or pending then
        eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        eventFrame:RegisterEvent("ADDON_RESTRICTION_STATE_CHANGED")
        eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    end
    if active then eventFrame:RegisterEvent("ADDON_LOADED") end
end

QueueRefresh = function()
    if queued then return end
    queued = true
    -- Reconcile after the native callback has returned. Never call Hide from
    -- inside Blizzard's OnShow/layout call stack or use a polling timer.
    C_Timer.After(0, function()
        queued = false
        Refresh()
    end)
end

function LUI:SetNativeReplacementActive(moduleName, enabled)
    if not self.IsForever then return end
    local states = replacements[moduleName]
    if not states then return end
    states.enabled = enabled == true
    if not eventFrame then
        eventFrame = CreateFrame("Frame")
        eventFrame:SetScript("OnEvent", function(_, event, addon)
            if event ~= "ADDON_LOADED" or addon == "Blizzard_StatusTrackingBar"
                or addon == "Blizzard_MainMenuBarBagButtons" or addon == "Blizzard_EditMode" then
                QueueRefresh()
            end
        end)
    end
    Refresh()
end
