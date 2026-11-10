-- Run from the repo root, passing the packaged unmodified Ace3 directory.
local dependencies = assert(arg and arg[1], "Pass the Ace3 dependency directory")
format, strlenutf8 = string.format, string.len
strmatch, strfind, strlower = string.match, string.find, string.lower
function wipe(t) for k in pairs(t) do t[k] = nil end return t end
function CreateFrame() return {RegisterEvent = function() end, SetScript = function() end} end
function UnitFactionGroup() return "Alliance" end
function GetLocale() return "enUS" end
function UnitClass() return "Druid", "DRUID" end
function UnitRace() return "Night Elf", "NightElf" end
function GetRealmName() return "FixtureRealm" end
function UnitNameUnmodified() return "FixturePlayer" end
function GetCurrentRegion() return 3 end
function GetCurrentRegionName() return "EU" end
function geterrorhandler() return error end
function InCombatLockdown() return false end
for _, name in ipairs({"LibStub", "CallbackHandler-1.0", "AceDB-3.0"}) do dofile(dependencies .. "/" .. name .. ".lua") end

local passed = 0
local function Check(ok, message) assert(ok, message); passed = passed + 1 end
local function Copy(v)
    if type(v) ~= "table" then return v end
    local t = {}; for k, x in pairs(v) do t[k] = Copy(x) end; return t
end
local function Equal(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end
    for k, v in pairs(a) do if not Equal(v, b[k]) then return false end end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
end
local function Count(t) local n = 0; for _ in pairs(t) do n = n + 1 end; return n end
local saved = {
    profiles = {Mine = {binding = {left = "Rejuvenation"}}, ["LUI - Mine"] = {owner = "user"}},
    namespaces = {
        ActionBars = {profiles = {Mine = {position = {x = 333}, aura = 774}}},
        UnloadedModule = {profiles = {Mine = {indicator = {name = "user bouquet"}}}},
    },
}
local db = LibStub("AceDB-3.0"):New(saved, nil, "Mine")
local child = db:RegisterNamespace("ActionBars")
local lui = {db = {global = {}}}
local opt = {LUI = lui}
assert(loadfile("LUIOptions/SetupProfiles.lua"))("LUIOptions", opt)
local api, adapter = opt.SetupProfiles, opt.SetupProfiles:Ace(db)
local before = Copy(saved)
local plan = assert(api:Plan("Bartender4", adapter))
Check(Equal(before, saved) and not lui.db.global.AddonSetupProfiles, "planning must not mutate either database")
Check(plan.create and plan.target == "LUI - Mine (2)", "pre-existing user profiles need a separate destination")
local target = assert(api:Run("Bartender4", adapter, plan, function()
    child.profile.position.x = -197
end))
Check(db:GetCurrentProfile() == target and child.keys.profile == target, "native switch must include loaded namespaces")
Check(child.profile.position.x == -197 and child.profile.aura == 774 and db.profile.binding.left == "Rejuvenation", "copy includes addon and namespace settings")
Check(Equal(before.profiles.Mine, saved.profiles.Mine)
    and Equal(before.namespaces.ActionBars.profiles.Mine, saved.namespaces.ActionBars.profiles.Mine), "copy and setup must retain original settings")
Check(Equal(before.profiles["LUI - Mine"], saved.profiles["LUI - Mine"]), "matching LUI names owned by the user are never adopted")
Check(Equal(before.namespaces.UnloadedModule.profiles.Mine, saved.namespaces.UnloadedModule.profiles[target]), "AceDB must also copy unloaded namespaces")
db.profile.binding.left = "Lifebloom"
saved.namespaces.UnloadedModule.profiles[target].indicator.name = "copy only"
Check(saved.profiles.Mine.binding.left == "Rejuvenation"
    and saved.namespaces.UnloadedModule.profiles.Mine.indicator.name == "user bouquet", "copied nested tables must not alias source")
local count = Count(saved.profiles)
plan = assert(api:Plan("Bartender4", adapter))
Check(not plan.create and plan.target == target, "active LUI copy must be reused")
assert(api:Run("Bartender4", adapter, plan, function() end))
db:SetProfile("Mine")
plan = assert(api:Plan("Bartender4", adapter))
Check(not plan.create and plan.target == target, "reselecting original must find existing copy")
assert(api:Run("Bartender4", adapter, plan, function() end))
Check(Count(saved.profiles) == count, "repeat setup must not create duplicates")
-- Ownership survives reopening the LUI options namespace.
local reopened = {LUI = lui}
assert(loadfile("LUIOptions/SetupProfiles.lua"))("LUIOptions", reopened)
Check(reopened.SetupProfiles:Plan("Bartender4", adapter).target == target, "ownership must persist across options reloads")
-- Each addon has its own ownership record even if profile names overlap.
db:SetProfile("Mine")
Check(api:Plan("Grid2", adapter).create, "another addon cannot adopt this addon's copy")
-- Confirmation rejects profile changes and a target created while the dialog is open.
plan = assert(api:Plan("Grid2", adapter))
db:SetProfile(plan.target)
db.profile.marker = "created independently"
db:SetProfile("Mine")
local ran = false
Check(not api:Run("Grid2", adapter, plan, function() ran = true end) and not ran, "collision during confirmation must cancel before applying")
Check(saved.profiles[plan.target].marker == "created independently", "confirmation collision must retain independent profile")
plan = assert(api:Plan("Grid2", adapter))
db:SetProfile("Other")
Check(not api:Run("Grid2", adapter, plan, function() ran = true end) and not ran, "confirmation rejects changed source")
-- A failed copy update returns to the previous profile without resetting it.
db:SetProfile("Mine")
plan = assert(api:Plan("Bartender4", adapter))
local unchanged = Copy(saved.profiles.Mine)
Check(not api:Run("Bartender4", adapter, plan, function() error("layout failure") end), "native application errors are handled")
Check(db:GetCurrentProfile() == "Mine" and Equal(unchanged, saved.profiles.Mine), "failure restores the source selection and leaves its settings intact")
-- Missing/deleted setup targets are replaced with a fresh copy, never an original.
db:DeleteProfile(target)
plan = assert(api:Plan("Bartender4", adapter))
Check(plan.create and plan.source == "Mine" and plan.target ~= "Mine", "deleted setup target requires a new disposable copy")
-- Name generation must not split UTF-8 when shortened to fit a suffix.
local utfName = string.rep("ä", 30)
local names = {[utfName] = true}
local utfAdapter = {current = function() return utfName end, exists = function(n) return names[n] end}
local utfPlan = assert(api:Plan("Unicode", utfAdapter))
Check(#utfPlan.target <= 40 and utfPlan.target:sub(-2) == "ä", "shortened names retain complete UTF-8 characters")
names[utfPlan.target] = true
Check(api:Plan("Unicode", utfAdapter).target:sub(-4) == " (2)", "Unicode collisions receive a safe suffix")
print("Real AceDB setup profile checks passed: " .. passed)
