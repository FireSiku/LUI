-- Run from the repository root with Lua 5.1.
-- Blizzard's IsBagOpen -> container enumerator can initialize a shared Lua
-- cache on its first read. Model that side effect, not WoW's C-side taint
-- engine: the micromenu must not become the owner of that native cache.
local passed = 0
local function Check(value, message) assert(value, message); passed = passed + 1 end

local function Setup(forever, customBags)
    local env = setmetatable({}, {__index = _G}); env._G = env
    local context, cache = "LUI", {writes = 0}
    local function RunAddon(callback, ...)
        local previous = context; context = "LUI"
        callback(...)
        context = previous
    end
    local function Frame(name, id)
        local frame = {shown = false, id = id, scripts = {}, hooks = {}}
        function frame:IsShown() return self.shown end
        function frame:GetID() return self.id end
        function frame:SetScript(event, callback) self.scripts[event] = callback end
        function frame:GetScript(event) return self.scripts[event] end
        function frame:HookScript(event, callback)
            self.hooks[event] = self.hooks[event] or {}
            self.hooks[event][#self.hooks[event] + 1] = callback
        end
        function frame:SetShown(shown)
            shown = not not shown
            if self.shown == shown then return end
            self.shown = shown
            local event = shown and "OnShow" or "OnHide"
            if self.scripts[event] then self.scripts[event](self) end
            for _, callback in ipairs(self.hooks[event] or {}) do RunAddon(callback, self) end
        end
        function frame:Show() self:SetShown(true) end
        function frame:Hide() self:SetShown(false) end
        if name then env[name] = frame end
        return frame
    end
    env.CreateFrame = function(_, name) return Frame(name) end
    env.UIParent = Frame("UIParent"); env.UIParent:Show()
    local frames = {}
    for index = 1, 13 do frames[index] = Frame("ContainerFrame" .. index, index - 1) end
    local combined = Frame("ContainerFrameCombinedBags", 0)
    function combined:IsBagOpen(id) return self:IsShown() and id <= 5 and id or nil end

    -- Like ContainerFrameUtil_EnumerateContainerFrames, querying open bags
    -- creates the shared enumerator lazily. Cache ownership is recorded only
    -- by this fixture; the production code never sees this test metadata.
    env.IsBagOpen = function(id)
        if combined:IsBagOpen(id) then return true end
        if not cache.frames then
            cache.frames = {}
            for index, frame in ipairs(frames) do cache.frames[index] = frame end
            cache.writes, cache.owner = cache.writes + 1, context
        end
        for _, frame in ipairs(cache.frames) do
            if frame:IsShown() and frame:GetID() == id then return true end
        end
        return false
    end
    local originalQuery = env.IsBagOpen
    env.InCombatLockdown = function() return false end
    local micro = {enabled = true}
    function micro:IsEnabled() return self.enabled end
    local bags = {enabled = false}
    function bags:IsEnabled() return self.enabled end
    if customBags then env.LUIBags = Frame("LUIBags") end
    local lui = {
        IsForever = forever,
        L = setmetatable({}, {__index = function(_, key) return key end}),
        NewModule = function(_, name) assert(name == "Micromenu"); return micro end,
        GetModule = function(_, name) if name == "Bags" then return bags end; return micro end,
    }
    setfenv(assert(loadfile("modules/micromenu/micromenu.lua")), env)("LUI", lui)
    local function Native(callback, ...)
        local previous = context; context = "Blizzard"
        callback(...)
        context = previous
    end
    local function ReadFromBank()
        -- OpenAllBags checks open bags before the bank selects its bank type.
        Native(env.IsBagOpen, 0)
    end
    return env, micro, bags, frames, combined, cache, originalQuery, Native, ReadFromBank
end

for _, forever in ipairs({false, true}) do
    local env, micro, bags, frames, combined, cache, query, Native, ReadFromBank = Setup(forever)
    local nativeClick = function() end
    frames[1]:SetScript("OnClick", nativeClick)
    micro:ConsolidateBagFrames()
    local indicator = env.ConsolidatedBagFrame
    Check(not indicator:IsShown(), "closed bags start with an inactive micromenu indicator")
    Check(cache.writes == 0, "micromenu initialization must not initialize Blizzard's container cache")
    Check(env.IsBagOpen == query, "Blizzard's bag query must remain intact")
    ReadFromBank()
    Check(cache.owner == "Blizzard", "the first native bank query must own the native enumerator cache")

    -- A bag configuration change can invalidate the native cache. Showing
    -- bags after that must not repopulate it from an addon script callback.
    cache.frames, cache.owner = nil, nil
    local nativeWrites = cache.writes
    Native(frames[1].Show, frames[1])
    Check(indicator:IsShown(), "opening the backpack activates the indicator")
    Check(cache.writes == nativeWrites and not cache.frames, "an OnShow callback leaves the native cache cold")
    Native(frames[2].Show, frames[2])
    Native(frames[1].Hide, frames[1])
    Check(indicator:IsShown(), "another open personal bag keeps the indicator active")
    Native(frames[2].Hide, frames[2])
    Check(not indicator:IsShown(), "closing the last personal bag clears the indicator")

    for _, id in ipairs({0, 1, 2, 3, 4, 5}) do
        frames[3].id = id
        Native(frames[3].Show, frames[3])
        Check(indicator:IsShown(), "personal bag " .. id .. " activates the indicator")
        Native(frames[3].Hide, frames[3])
        Check(not indicator:IsShown(), "closing personal bag " .. id .. " clears the indicator")
    end
    for _, id in ipairs({-2, -1, 6, 12, 13}) do
        frames[3].id = id
        Native(frames[3].Show, frames[3])
        Check(not indicator:IsShown(), "a keyring or bank container alone does not activate the indicator")
        Native(frames[3].Hide, frames[3])
    end
    Native(combined.Show, combined)
    Check(indicator:IsShown(), "the native combined bag activates the indicator")
    Native(combined.Hide, combined)
    Check(not indicator:IsShown(), "closing the native combined bag clears the indicator")
    Check(cache.writes == nativeWrites and not cache.frames, "all native bag callbacks preserve a cold native cache")
    Check(frames[1]:GetScript("OnClick") == nativeClick, "native item interaction scripts remain unchanged")

    micro.enabled = false
    Native(frames[1].Show, frames[1])
    Check(not indicator:IsShown(), "callbacks retained after disabling Micromenu do not update the indicator")
    Native(frames[1].Hide, frames[1])
    micro.enabled = true
    ReadFromBank()
    Check(cache.owner == "Blizzard", "the native caller still initializes an invalidated cache")

    local customEnv, customMicro, customBags, nativeFrames, _, customCache, _, CustomNative = Setup(forever, true)
    customMicro:ConsolidateBagFrames()
    customBags.enabled = true
    CustomNative(nativeFrames[1].Show, nativeFrames[1])
    Check(not customEnv.ConsolidatedBagFrame:IsShown(), "enabled LUI Bags owns the indicator even when native containers report open")
    CustomNative(customEnv.LUIBags.Show, customEnv.LUIBags)
    Check(customEnv.ConsolidatedBagFrame:IsShown(), "opening LUI Bags activates the indicator")
    CustomNative(customEnv.LUIBags.Hide, customEnv.LUIBags)
    Check(not customEnv.ConsolidatedBagFrame:IsShown(), "closing LUI Bags clears the indicator")
    Check(customCache.writes == 0, "LUI Bags mode does not initialize the native container cache")
end

print("micromenu bags: " .. passed .. " checks passed")
