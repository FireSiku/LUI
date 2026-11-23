-- Exercise the bundled upstream elements and LUI's extra Forever safeguards.
-- Run with Lua 5.1 from the repository root; no embedded oUF source is changed.
local passed = 0
local function Check(value, why) assert(value, why); passed = passed + 1 end
local function Noop() end
for _, forever in ipairs({false, true}) do
    for _, class in ipairs({"DRUID", "ROGUE"}) do
        local env = setmetatable({}, {__index = _G}); env._G = env
        local currentTarget, legacyCalls = "first", 0
        local points = {first = 3, second = 1, none = 0}
        local registered = {}
        local ouf = {Private = {GameCompatibility = {Warlords = not forever}, GameVersion = {Forever = forever},
            unitIsUnit = function(a, b) return a == b end}}
        function ouf:AddElement(name, update, enable, disable)
            registered[name] = {update = update, enable = enable, disable = disable}
        end
        local namespace = {oUF = ouf}
        env.Constants = {UnitPowerSpellIDs = {}}
        env.Enum = {PowerType = {Energy = 3, ComboPoints = 4}, StatusBarInterpolation = {Immediate = 0},
            SecondsFormatterAbbreviation = {OneLetter = 0}, SecondsFormatterInterval = {Seconds = 0}}
        env.UnitClassBase = function() return class end
        env.UnitHasVehicleUI = function() return false end
        env.UnitPowerType = function() return 3 end
        env.C_SpellBook = {IsSpellKnown = function() return true end}
        env.UnitPowerMax = function() return 5 end
        env.GetComboPoints = function(unit, target)
            Check(unit == "player" and target == "target", "Forever queries target-bound combo points")
            legacyCalls = legacyCalls + 1
            return points[currentTarget]
        end
        env.UnitPower = function() return 4 end
        env.GetUnitChargedPowerPoints = function() return nil end
        local function Load(path) setfenv(assert(loadfile(path)), env)("LUI", namespace) end
        Load("api/oUF13/elements/classpower.lua")
        local element = {}
        for i = 1, 5 do
            element[i] = {IsObjectType = function() return true end, GetStatusBarTexture = function() return true end,
                SetMinMaxValues = Noop, SetStatusBarColor = Noop,
                Hide = function(self) self.shown = false end,
                SetShown = function(self, value) self.shown = value end,
                SetValue = function(self, value) self.value = math.max(0, math.min(1, value)) end}
        end
        local frame = {ClassPower = element, __unit = "player", events = {}, callbacks = {}, colors = {power = {
            COMBO_POINTS = {GetRGB = function() return .2, .6, .8 end}}}}
        function frame:RegisterEvent(name, callback)
            local callbacks = self.callbacks[name] or {}; self.callbacks[name] = callbacks
            callbacks[callback] = true
            self.events[name] = function(self, ...) for handler in pairs(callbacks) do handler(self, ...) end end
        end
        function frame:UnregisterEvent(name, callback)
            local callbacks = self.callbacks[name]
            if callbacks and callback then callbacks[callback] = nil end
            if not callback or not callbacks or not next(callbacks) then self.events[name], self.callbacks[name] = nil, nil end
        end
        local classPower = registered.ClassPower
        Check(classPower.enable(frame, "player"), "native class power enables for " .. class)
        classPower.update(frame, "ForceUpdate", "player")
        Check(element[1].value == 1 and element[forever and 4 or 5].value == 0, "initial native points are rendered")
        Check((legacyCalls > 0) == forever, "each client uses its own native combo-point API")
        if forever then
            Check(type(frame.events.PLAYER_TARGET_CHANGED) == "function", "upstream registers Forever target changes")
            currentTarget = "second"
            frame.events.PLAYER_TARGET_CHANGED(frame, "PLAYER_TARGET_CHANGED")
            Check(element[1].value == 1 and element[2].value == 0, "switching targets removes the previous target's combo points")
            currentTarget = "none"
            frame.events.PLAYER_TARGET_CHANGED(frame, "PLAYER_TARGET_CHANGED")
            Check(element[1].value == 0, "clearing target clears combo points")
        else
            Check(not frame.events.PLAYER_TARGET_CHANGED, "Retail keeps its player-bound power lifecycle")
        end
        if forever then
            local adapter, initialize, restricted = {}, nil, {}
            local restrictedCurrent, maximum = false, 5
            local readPoints = env.GetComboPoints
            env.GetComboPoints = function(...) if restrictedCurrent then return restricted end; return readPoints(...) end
            env.UnitPowerMax = function() return maximum end
            env.issecretvalue = function(value) return value == restricted end
            env.hooksecurefunc = function(object, name, callback)
                local original = assert(object[name])
                object[name] = function(self, ...)
                    local result = original(self, ...); callback(self, ...); return result
                end
            end
            local lui = {IsForever = true, DRUID = class == "DRUID", ROGUE = class == "ROGUE",
                GetModule = function() return adapter end,
                oUF = {RegisterInitCallback = function(_, callback) initialize = callback end}}
            function element:SetAlpha(value) self.alpha = value end
            frame.elementEnabled = true
            function frame:IsElementEnabled() return self.elementEnabled end
            function frame:IsElementPaused() return self.paused end
            frame.EnableElement = Noop
            function frame:DisableElement() self.elementEnabled = false; classPower.disable(self) end
            function frame:PauseElement() self.paused = true; element.ClassPowerDisable(self, true) end
            function frame:ResumeElement() self.paused = false; element.ClassPowerEnable(self, false) end
            setfenv(assert(loadfile("modules/unitframes/classpower_compat.lua")), env)("LUI", lui)
            adapter:PrepareForeverComboPoints(frame)
            currentTarget = "first"
            initialize(frame)
            Check(element.alpha == 1 and element[3].value == 1, "LUI safeguards retain normal native visibility and points")
            local callbacks = 0; for _ in pairs(frame.callbacks.PLAYER_TARGET_CHANGED) do callbacks = callbacks + 1 end
            Check(callbacks == 2, "LUI and upstream target callbacks coexist without replacing each other")
            currentTarget = "second"
            frame.events.PLAYER_TARGET_CHANGED(frame, "PLAYER_TARGET_CHANGED")
            Check(element[1].value == 1 and element[2].value == 0, "target changes also work with the LUI adapter")
            points.second = 2
            frame.events.COMBO_TARGET_CHANGED(frame, "COMBO_TARGET_CHANGED")
            Check(element[2].value == 1, "combo-target updates refresh without changing the selected target")
            restrictedCurrent = true
            frame.events.UNIT_POWER_UPDATE(frame, "UNIT_POWER_UPDATE", "player", "COMBO_POINTS")
            Check(element.alpha == 0, "restricted current points are hidden before comparison or arithmetic")
            restrictedCurrent, maximum = false, restricted
            frame.events.UNIT_POWER_UPDATE(frame, "UNIT_POWER_UPDATE", "player", "COMBO_POINTS")
            Check(element.alpha == 0, "restricted maximum points are hidden before comparison or arithmetic")
            maximum = 7
            frame.events.UNIT_POWER_UPDATE(frame, "UNIT_POWER_UPDATE", "player", "COMBO_POINTS")
            Check(element.alpha == 1 and element[5].shown, "normal data restores visibility and updates stay within the available widgets")
            frame:PauseElement("ClassPower")
            Check(not frame.events.PLAYER_TARGET_CHANGED and not frame.events.COMBO_TARGET_CHANGED, "pausing removes both sets of combo-target callbacks")
            maximum = 5
            frame:ResumeElement("ClassPower")
            Check(frame.events.PLAYER_TARGET_CHANGED and frame.events.COMBO_TARGET_CHANGED, "resuming restores native and LUI update events")
            frame:DisableElement("ClassPower")
        else
            classPower.disable(frame)
        end
        Check(not next(frame.events), "disabling native class power removes every registered event")

        -- Ask the real GCD event handler which client-specific spell it reads.
        local requestedSpell
        env.C_StringUtil = {CreateSecondsFormatter = function() return {
            SetDefaultAbbreviation = Noop, SetMinInterval = Noop, SetMillisecondsThreshold = Noop} end}
        env.C_Spell = {GetSpellCooldown = function(id) requestedSpell = id; return nil end}
        env.C_DurationUtil = {CreateDuration = function() return {} end}
        Load("api/oUF13/elements/castbar.lua")
        frame.hasChildren = true -- Avoid replacing Blizzard's native castbar in this fixture.
        frame.Castbar = {showGlobalCooldown = true, ShouldShow = function() return true end,
            SetScript = Noop, Hide = Noop, IsObjectType = function() return false end}
        Check(registered.Castbar.enable(frame, "player"), "native castbar enables")
        frame.events.UNIT_SPELLCAST_SUCCEEDED(frame, "UNIT_SPELLCAST_SUCCEEDED", "player", nil, 1)
        Check(requestedSpell == (forever and 1283885 or 61304), "GCD queries use the correct client spell")
    end
end

-- A party pet is eligible even when the legacy player-only party query is false.
local registered, opaque = {}, {}
local env = setmetatable({UnitIsConnected = function() return true end,
    UnitInParty = function() return false end,
    UnitPlayerOrPetInParty = function(unit) return unit == "partypet1" end,
    UnitInRange = function() return opaque end}, {__index = _G})
local namespace = {oUF = {AddElement = function(_, name, update) registered[name] = update end}}
setfenv(assert(loadfile("api/oUF13/elements/range.lua")), env)("LUI", namespace)
local frame = {__unit = "partypet1", Range = {insideAlpha = 1, outsideAlpha = .2},
    SetAlpha = function() error("eligible pets must use the native boolean alpha setter") end,
    SetAlphaFromBoolean = function(self, value, inside, outside) self.applied = {value, inside, outside} end}
registered.Range(frame, "UNIT_IN_RANGE_UPDATE")
Check(frame.applied[1] == opaque and frame.applied[3] == .2, "pet range booleans are forwarded without inspecting restricted values")

-- Raid layouts use the existing oUF Blizzard-frame suppression path, like
-- single-unit and party replacements. Exercise the real LUI enable/toggle path.
for _, forever in ipairs({false, true}) do
    for _, scenario in ipairs({"raid", "disabled", "external"}) do
        local env = setmetatable({}, {__index = _G}); env._G = env
        local combat = false
        local function Frame(name)
            local f = {events = {}, scripts = {}, attributes = {}, shown = true}
            function f:RegisterEvent(event) self.events[event] = true end
            function f:UnregisterEvent(event) self.events[event] = nil end
            function f:UnregisterAllEvents() self.events = {} end
            function f:SetScript(event, callback) self.scripts[event] = callback end
            function f:SetAttribute(key, value) self.attributes[key] = value end
            function f:GetAttribute(key) return self.attributes[key] end
            function f:SetRolesets(value) self.roleset = value end
            function f:Show() self.shown = true end
            function f:Hide() self.shown = false end
            function f:IsShown() return self.shown and self.roleset ~= "alwaysBlocked" end
            for _, method in ipairs({"SetWidth", "SetHeight", "SetSize", "SetScale", "SetPoint", "SetParent", "ClearAllPoints"}) do
                f[method] = Noop
            end
            if name then env[name] = f end
            return f
        end
        env.UIParent = Frame("UIParent")
        env.MAX_BOSS_FRAMES = 5
        env.CreateFrame = function(_, name) return Frame(name) end
        env.InCombatLockdown = function() return combat end
        env.LibStub = function() return {} end
        env.RegisterStateDriver, env.UnregisterStateDriver = Noop, Noop
        env.C_AddOns = {IsAddOnLoaded = function(name) return scenario == "external" and name == "Grid2" end}
        env.SetCVar = function() error("the raid fix must not change saved Blizzard preferences") end
        local module = {IsEnabled = function() return true end, DisableFading = Noop}
        local ouf = {Private = {GameVersion = {Forever = forever}}, SetActiveStyle = Noop,
            SpawnHeader = function(_, name) return Frame(name) end}
        local lui = {IsForever = forever, oUF = ouf, Points = {}, Profiler = {TraceScope = Noop},
            NewModule = function() return module end, GetModule = function() return module end,
            OutOfCombatWrapper = function(callback) return callback end}
        setfenv(assert(loadfile("api/oUF13/blizzard.lua")), env)("oUF", {oUF = ouf})
        local function Load(path) setfenv(assert(loadfile(path)), env)("LUI", lui) end
        Load("modules/unitframes/unitframes_init.lua")
        Load("modules/unitframes/options/toggle.lua")
        module.PositionFrame, module.ConfigureRaidGroupLabel = Noop, Noop
        module.GetUnitFrameFootprintHeight = function() return 20 end
        module.GetUnitFrameStackOverflow = function() return 0 end
        module.SpawnPreconfiguredHeader = function(_, name) return Frame(name) end
        module.db = {profile = {}}
        for _, unit in ipairs(module.units) do
            module.db.profile[unit] = {Enable = false, UseBlizzard = false, X = 0, Y = 0, Scale = 1}
        end
        module.db.profile.raid = {Enable = scenario ~= "disabled", Height = 20, Width = 50, Padding = 3, GroupPadding = 4}
        local native = Frame("CompactRaidFrameContainer")
        native:RegisterEvent("GROUP_ROSTER_UPDATE")
        local originalShow = native.Show
        module:OnEnable()
        if scenario == "raid" then
            Check(not native:IsShown() and env.oUF_LUI_raid.shown, "enabling the LUI raid layout uses oUF to suppress duplicate Blizzard frames")
            Check(native.roleset == "alwaysBlocked" and not next(native.events), "raid suppression uses the same native roleset and event cleanup as other oUF replacements")
            combat = true; native:Show()
            Check(not native:IsShown() and native.Show == originalShow, "native Show calls cannot restore duplicates in combat and Show is not replaced")
            combat = false
            native.roleset = "unitFrames"
            ouf:DisableBlizzard("raid40")
            Check(not native:IsShown(), "numbered raid units use the same suppression case")
            native.roleset = "unitFrames"
            ouf:DisableBlizzard("raidpet1")
            Check(native:IsShown(), "raid-pet tokens are not mistaken for the raid replacement")
            env.CompactRaidFrameContainer = nil
            ouf:DisableBlizzard("raid")
            env.CompactRaidFrameContainer = native
            module.ToggleUnit("raid")
            Check(not native:IsShown(), "the normal refresh retries suppression after a previously missing native frame")
        else
            Check(native:IsShown() and native.events.GROUP_ROSTER_UPDATE,
                "native raid frames remain untouched when LUI raid frames are disabled or another raid addon owns the layout")
            Check(not env.oUF_LUI_raid, "no LUI raid layout is created when disabled or delegated")
        end
        local target = Frame("TargetFrame")
        target:RegisterEvent("UNIT_TARGET")
        ouf:DisableBlizzard("target")
        Check(not target:IsShown() and not next(target.events), "the established target-frame suppression still works")
    end
end
print("ouf_compat: " .. passed .. " checks passed")
