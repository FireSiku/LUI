-- Exercise the bundled upstream elements after removing LUI's combo override.
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
        local frame = {ClassPower = element, __unit = "player", events = {}, colors = {power = {
            COMBO_POINTS = {GetRGB = function() return .2, .6, .8 end}}}}
        function frame:RegisterEvent(name, callback) self.events[name] = callback end
        function frame:UnregisterEvent(name) self.events[name] = nil end
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
        classPower.disable(frame)
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
print("ouf_compat: " .. passed .. " checks passed")
