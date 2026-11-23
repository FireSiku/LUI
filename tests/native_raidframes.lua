-- Exercise native raid visibility and the real unitframe toggle/module lifecycle.
local passed = 0
local function Check(value, why) assert(value, why); passed = passed + 1 end
local function Noop() end
for _, forever in ipairs({false, true}) do
    local env = setmetatable({}, {__index = _G}); env._G = env
    local combat, external, enabled = false, false, true
    local frames, timers = {}, {}
    local function Frame(name)
        local frame = {name = name, events = {}, scripts = {}, attributes = {}, shown = true}
        function frame:RegisterEvent(event) self.events[event] = true end
        function frame:UnregisterEvent(event) self.events[event] = nil end
        function frame:UnregisterAllEvents() self.events = {} end
        function frame:SetScript(event, callback) self.scripts[event] = callback end
        function frame:SetAttribute(key, value) self.attributes[key] = value end
        function frame:GetAttribute(key) return self.attributes[key] end
        function frame:Show() self.shown = true end
        function frame:Hide() self.shown = false end
        function frame:Fire(event, ...) if self.events[event] then self.scripts.OnEvent(self, event, ...) end end
        for _, method in ipairs({"SetWidth", "SetHeight", "SetSize", "SetScale", "SetPoint", "SetParent", "ClearAllPoints"}) do
            frame[method] = Noop
        end
        frames[#frames + 1] = frame
        if name then env[name] = frame end
        return frame
    end
    env.UIParent = Frame("UIParent")
    env.MAX_BOSS_FRAMES = 5
    env.InCombatLockdown = function() return combat end
    env.C_Timer = {After = function(_, callback) timers[#timers + 1] = callback end}
    env.C_AddOns = {IsAddOnLoaded = function(name) return external and name == "Grid2" end}
    env.RegisterStateDriver, env.UnregisterStateDriver = Noop, Noop
    env.LibStub = function() return {} end
    env.SetCVar = function() error("native raid preferences must not be changed") end
    env.CreateFrame = function(_, name) return Frame(name) end
    local hooks = 0
    env.hooksecurefunc = function(object, name, callback)
        hooks = hooks + 1
        local original = object[name]
        object[name] = function(self, ...)
            original(self, ...); callback(self, ...)
        end
    end
    local module = {IsEnabled = function() return enabled end, DisableFading = Noop}
    local lui = {IsForever = forever, Points = {}, Profiler = {TraceScope = Noop},
        OutOfCombatWrapper = function(callback) return callback end,
        NewModule = function() return module end, GetModule = function() return module end,
        oUF = {SetActiveStyle = Noop, SpawnHeader = function(_, name) return Frame(name) end}}
    local function Load(path) setfenv(assert(loadfile(path)), env)("LUI", lui) end
    Load("modules/unitframes/unitframes_init.lua")
    Load("modules/unitframes/raid_visibility.lua")
    Load("modules/unitframes/options/toggle.lua")
    module.PositionFrame, module.ConfigureRaidGroupLabel = Noop, Noop
    module.GetUnitFrameFootprintHeight = function() return 20 end
    module.GetUnitFrameStackOverflow = function() return 0 end
    module.SpawnPreconfiguredHeader = function(_, name) return Frame(name) end
    module.db = {profile = {}}
    for _, unit in ipairs(module.units) do
        module.db.profile[unit] = {Enable = false, UseBlizzard = false, X = 0, Y = 0, Scale = 1}
    end
    module.db.profile.raid = {Enable = true, Height = 20, Width = 50, Padding = 3, GroupPadding = 4}

    local function Native(roles)
        local frame = {roles = roles or {unitFrames = true}, shown = true, mutations = 0,
            nativeEvents = {GROUP_ROSTER_UPDATE = true}, nativeScripts = {}, parent = env.UIParent}
        function frame:IsForbidden() return self.forbidden end
        function frame:CanBeAccessedInContext() return not self.inaccessible end
        function frame:GetRolesetNames()
            local list = {}; for role in pairs(self.roles) do list[#list + 1] = role end; return list
        end
        function frame:AddRoleset(role)
            assert(not combat and not self.forbidden and not self.inaccessible)
            self.roles[role] = true; self.mutations = self.mutations + 1
        end
        function frame:RemoveRoleset(role)
            assert(not combat and not self.forbidden and not self.inaccessible)
            self.roles[role] = nil; self.mutations = self.mutations + 1
        end
        function frame:SetRolesets(role) self.roles = {[role] = true} end
        function frame:IsShown() return self.shown and not self.roles.alwaysBlocked end
        function frame:Show() self.shown = true end
        for _, method in ipairs({"Hide", "SetParent", "UnregisterAllEvents", "SetScript", "SetAttribute"}) do
            frame[method] = function() error("native "..method.." must stay untouched") end
        end
        return frame
    end
    local native = Native(); env.CompactRaidFrameContainer = native
    module:OnEnable()
    Check(not native:IsShown() and env.oUF_LUI_raid.shown, "enabling LUI raid frames suppresses duplicate Blizzard frames")
    Check(native.roles.unitFrames and native.roles.alwaysBlocked, "the native roleset is preserved alongside the temporary block")
    local driver = frames[#frames]
    local mutations = native.mutations
    module.ToggleUnit("raid")
    Check(native.mutations == mutations and hooks == 1, "repeated refreshes do not add duplicate blocks or hooks")
    native:Show(); driver:Fire("GROUP_ROSTER_UPDATE")
    Check(not native:IsShown(), "native group updates cannot bring duplicate raid frames back")
    native:SetRolesets("raidFrames")
    Check(#timers == 1, "native roleset resets are reconciled after the Blizzard call returns")
    while #timers > 0 do table.remove(timers, 1)() end
    Check(native.roles.raidFrames and not native:IsShown(), "Edit Mode/native roleset replacement retains suppression")
    module.ToggleUnit("raid", false)
    Check(native:IsShown() and not env.oUF_LUI_raid.shown, "disabling only LUI raid frames restores native visibility")
    Check(native.roles.raidFrames and not native.roles.unitFrames, "restoring uses the current native roles, not an old snapshot")
    Check(not next(driver.events), "idle controllers do not keep listening to game events")

    native.shown = false
    module.ToggleUnit("raid", true); module.ToggleUnit("raid", false)
    Check(not native:IsShown() and not native.shown, "native frames intentionally hidden by Blizzard are not forced visible")
    native.shown = true
    module.ToggleUnit("raid", true)
    enabled = false; module:OnDisable()
    Check(native:IsShown() and not env.oUF_LUI_raid.shown, "disabling the complete unitframe module restores Blizzard frames")
    enabled = true; module:OnEnable()
    Check(not native:IsShown(), "re-enabling the module reapplies suppression")
    external = true; module.ToggleUnit("raid")
    Check(native:IsShown() and not env.oUF_LUI_raid.shown, "handoff to an external raid addon stops LUI's own replacement and block")
    external = false; module.ToggleUnit("raid")
    Check(not native:IsShown(), "returning to LUI raid frames restores the replacement")

    combat = true; mutations = native.mutations
    module:SetBlizzardRaidFramesHidden(false)
    Check(native.mutations == mutations and not native:IsShown(), "protected restoration is deferred during combat")
    Check(driver.events.PLAYER_REGEN_ENABLED, "deferred restoration waits for combat to end")
    combat = false; driver:Fire("PLAYER_REGEN_ENABLED")
    Check(native:IsShown() and not next(driver.events), "combat end restores and stops the event listener")
    combat = true; mutations = native.mutations
    module:SetBlizzardRaidFramesHidden(true)
    Check(native.mutations == mutations and native:IsShown(), "activation also avoids protected changes during combat")
    combat = false; driver:Fire("PLAYER_REGEN_ENABLED")
    Check(not native:IsShown(), "combat end applies deferred activation")
    module:SetBlizzardRaidFramesHidden(false)
    combat = true; module:SetBlizzardRaidFramesHidden(true); module:SetBlizzardRaidFramesHidden(false)
    combat = false; module:RefreshBlizzardRaidVisibility()
    Check(native:IsShown(), "a cancelled combat request cannot hide frames later")

    native.inaccessible = true; mutations = native.mutations
    module:SetBlizzardRaidFramesHidden(true)
    Check(native.mutations == mutations, "inaccessible native frames are untouched")
    native.inaccessible = false; driver:Fire("ADDON_RESTRICTION_STATE_CHANGED")
    Check(not native:IsShown(), "visibility is reconciled when restrictions clear")
    native.forbidden = true; mutations = native.mutations
    module:SetBlizzardRaidFramesHidden(false)
    Check(native.mutations == mutations, "forbidden native frames are untouched during restoration")
    native.forbidden = false; driver:Fire("ADDON_RESTRICTION_STATE_CHANGED")
    Check(native:IsShown(), "deferred restoration retries when the frame becomes accessible")

    env.CompactRaidFrameContainer = nil
    module:SetBlizzardRaidFramesHidden(true)
    Check(not env.CompactRaidFrameContainer and driver.events.ADDON_LOADED, "late-loaded native frames are awaited without creating replacements")
    native = Native({unitFrames = true, alwaysBlocked = true}); env.CompactRaidFrameContainer = native
    driver:Fire("ADDON_LOADED", "Blizzard_CompactRaidFrames")
    module:SetBlizzardRaidFramesHidden(false)
    Check(native.roles.alwaysBlocked and native.mutations == 0, "an existing block owned by another addon is never removed")
    env.CompactRaidFrameContainer = nil; module:SetBlizzardRaidFramesHidden(true)
    native = Native(); env.CompactRaidFrameContainer = native
    driver:Fire("ADDON_LOADED", "UnrelatedAddon")
    Check(native:IsShown(), "unrelated addon loads do not change native raid frames")
    driver:Fire("ADDON_LOADED", "Blizzard_CompactRaidFrames")
    Check(not native:IsShown(), "late Blizzard raid addon loading applies the block")
    module:SetBlizzardRaidFramesHidden(false)
    Check(native.nativeEvents.GROUP_ROSTER_UPDATE and not next(native.nativeScripts) and native.parent == env.UIParent,
        "native events, scripts and parent remain intact")
    Check(module.db.profile.raid.Enable == true, "visibility control never rewrites saved raid settings")
end
print("Native raid-frame visibility checks passed: "..passed)
