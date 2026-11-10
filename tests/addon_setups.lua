-- Real option callbacks with native profile-boundary fixtures for all six addons.
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
local passed = 0
local function Check(value, why) assert(value, why); passed = passed + 1 end

local function Environment(id)
    local s = {id = id, loaded = {[id] = true}, combat = false, reloads = 0, events = {}, messages = {}}
    local art = {db = {profile = {LUITextures = {Raid = {}}, SideBars = {}}}}
    function art:IsEnabled() return true end
    function art:IterateSidebars() return pairs({}) end
    function art:Refresh() end
    local lui = {db = {global = {}}, GetModule = function() return art end,
        L = {CPanel_Modules = "Modules"}, IterateModules = function() return pairs({}) end,
        Print = function(_, v) s.messages[#s.messages + 1] = v end}
    local opt = {LUI = lui, options = {args = {}}}
    for _, method in ipairs({"Group", "InlineGroup", "Desc", "Execute"}) do opt[method] = function(_, v) return v end end
    function opt:CreateModuleOptions(name) local t = {args = {}}; self.options.args[name] = t; return t end
    local env = setmetatable({CopyTable = Copy, format = string.format,
        InCombatLockdown = function() return s.combat end,
        ReloadUI = function() s.reloads = s.reloads + 1 end,
        GetScreenWidth = function() return 1920 end, GetScreenHeight = function() return 1080 end,
        UIParent = {GetEffectiveScale = function() return .8 end,
            GetWidth = function() return 1920 end, GetHeight = function() return 1080 end},
        C_AddOns = {IsAddOnLoaded = function(n) return s.loaded[n] or false end,
            LoadAddOn = function() return not s.loadFailure end}}, {__index = _G})
    env._G = env
    env.LUIDiagnostics = {IsRecording = function() return true end,
        Breadcrumb = function(_, event, detail) s.events[#s.events + 1] = {event, detail} end}
    local function Load(file, name, namespace)
        local f = assert(loadfile(file)); setfenv(f, env)(name, namespace)
    end
    function s:Load()
        Load("api/diagnostics.lua", "LUI", lui)
        Load("LUIOptions/CPanel.lua", "LUIOptions", opt)
        Load("LUIOptions/SetupProfiles.lua", "LUIOptions", opt)
        local bars = id == "Bartender4" or id == "Dominos"
        Load(bars and "LUIOptions/ActionBars.lua" or "LUIOptions/RaidFrames.lua", "LUIOptions", opt)
        self.button = opt.AddonSetup.args[bars and "ActionBars" or "RaidFrames"].args[id == "Bartender4" and "Bartender" or id]
    end
    function s:Apply() assert(type(self.button.confirm()) == "string"); self.button.func() end
    s.env, s.opt, s.art = env, opt, art
    return s, env
end

-- These functions model AceDB's destination-before-CopyProfile contract.
-- tests/setup_profiles.lua additionally exercises the unmodified real AceDB.
local function Ace(s, profiles, onSelect)
    local active, db = "Mine", {}
    function db:GetCurrentProfile() return active end
    function db:GetProfiles() local t = {}; for n in pairs(profiles) do t[#t + 1] = n end; return t end
    function db:SetProfile(n) active = n; profiles[n] = profiles[n] or {}; self.profile = profiles[n]; if onSelect then onSelect(self.profile) end end
    function db:CopyProfile(n) profiles[active] = Copy(profiles[n]); self.profile = profiles[active]; if onSelect then onSelect(self.profile) end end
    db:SetProfile(active)
    s.current = function() return active end
    s.select = function(n) db:SetProfile(n) end
    s.profiles = profiles
    return db
end

local function Fixture(id)
    local s, e = Environment(id)
    local p = {Mine = {marker = "original", binding = {left = "Rejuvenation"}}, Other = {marker = "other"},
        ["LUI - Mine"] = {marker = "unrelated existing name"}}
    s.profiles = p
    if id == "Grid2" then
        p.Mine.frame = {frameWidth = 110, statuses = {hot = 774}, extraThemes = {{frameWidth = 130, indicator = "keep"}}}
        p.Mine.layout = {layouts = {raid = "My 25"}, extraThemes = {{layouts = {raid = "My 25"}}}}
        local frame, layout = {dba = {}, db = {}}, {dba = {}, db = {}}
        e.Grid2Frame, e.Grid2Layout = frame, layout
        local db = Ace(s, p, function(profile)
            profile.frame, profile.layout = profile.frame or {}, profile.layout or {}
            frame.dba.profile, frame.db.profile = profile.frame, profile.frame.extraThemes and profile.frame.extraThemes[1] or profile.frame
            layout.dba.profile, layout.db.profile = profile.layout, profile.layout
        end)
        e.Grid2 = {db = db}
        s.verify = function(target)
            Check(target.frame.frameWidth == 80 and #target.layout.layouts.raid > 0, "Grid2 copy gets geometry")
            Check(target.layout.layouts.raid == "By Group" and target.frame.extraThemes[1].frameWidth == 80, "Grid2 themes get complete raid layout")
            Check(target.frame.statuses.hot == 774 and target.frame.extraThemes[1].indicator == "keep", "Grid2 indicators retained")
        end
    elseif id == "Bartender4" or id == "Dominos" then
        p.Mine.modules = {ActionBars = true}
        p.Mine.bars = {actionbars = {[1] = {position = {x = 333}}, [6] = {position = {y = 444}}}}
        p.Mine.frames = {[1] = {x = 33}, [6] = {y = 44}}
        local bars = {db = {}}
        local db = Ace(s, p, function(profile) bars.db.profile = profile.bars end)
        if id == "Bartender4" then
            e.Bartender4 = {db = db, CONFIG_VERSION = 1, GetModule = function() return bars end,
                UpdateModuleConfigs = function() if s.fail then error("fixture layout failure") end end}
            s.verify = function(target) Check(target.bars.actionbars[1].position.x == -197 and target.bars.actionbars[6].buttons == 12, "Bartender copy gets bars") end
        else
            local function Bar(n)
                local function Set(k) return function(_, v) db.profile.frames[n][k] = v end end
                return {ClearSavedAnchor = function() db.profile.frames[n].anchor = nil end,
                    SetNumButtons = Set("buttons"), SetColumns = Set("columns"), SetSpacing = Set("spacing"),
                    SetPadding = Set("padding"), SetFrameScale = Set("scale"),
                    SavePosition = function(_, point, relative, x, y) db.profile.frames[n].x, db.profile.frames[n].y = x, y end,
                    RestorePosition = function() end, ShowFrame = function() end}
            end
            e.Dominos = {db = db, Frame = {Get = function(_, n) return Bar(n) end}, Reload = function() end,
                SetNumButtons = function(_, n) db.profile.numButtons = n end}
            s.verify = function(target) Check(target.numButtons == 12 and target.frames[1].columns == 12 and target.frames[6].scale == .85, "Dominos copy gets bars") end
        end
    elseif id == "DandersFrames" then
        p.Mine.raid = {frameWidth = 110, auraDesigner = {spell = 774}}
        p.Mine.party = {marker = "keep"}
        p.Mine.raidAutoProfiles = {enabled = true, instanced = {profiles = {{minSize = 26, overrides = {auraSize = 15}}}}}
        e.DandersFramesDB_v2 = {currentProfile = "Mine", profiles = p}
        local a = {db = p.Mine, DeepCopy = function(_, v) return Copy(v) end}
        function a:GetCurrentProfile() return e.DandersFramesDB_v2.currentProfile end
        function a:SaveCurrentProfile() p[self:GetCurrentProfile()] = Copy(self.db) end
        function a:SetProfile(n) self:SaveCurrentProfile(); e.DandersFramesDB_v2.currentProfile = n; self.db = p[n] end
        function a:DuplicateProfile(n)
            if p[n] then return false end
            self:SaveCurrentProfile(); p[n] = Copy(self.db); e.DandersFramesDB_v2.currentProfile = n; self.db = p[n]; return true
        end
        e.DandersFrames = a
        s.current = function() return a:GetCurrentProfile() end; s.select = function(n) a:SetProfile(n) end
        s.verify = function(target)
            local auto = target.raidAutoProfiles.instanced.profiles[1]
            Check(#target.raid.raidGroupVisible == 8 and #auto.overrides.raidGroupVisible == 8, "Danders copy includes group 8")
            Check(auto.minSize == 26 and auto.overrides.auraSize == 15 and target.raid.auraDesigner.spell == 774 and target.party.marker == "keep", "Danders conditions and auras retained")
        end
    elseif id == "HealBot" then
        local skins = {Current_Skin = "Mine", Skins = {"Mine", "Other", "LUI - Mine"}, HealGroups = {}, Icons = {}}
        for name, value in pairs(p) do
            value.groups = {[4] = {STATE = false, FRAME = 2}, [5] = {STATE = true, FRAME = 3}, [10] = {marker = "pet"}}
            value.icons = {hot = 774}; skins.HealGroups[name], skins.Icons[name] = value.groups, value.icons
        end
        e.Healbot_Config_Skins, e.HealBot_Data = skins, {UILOCK = false}
        e.HealBot_Options_checkSkinName = function(n) return p[n] ~= nil end
        e.HealBot_Options_Set_Current_Skin = function(n) skins.Current_Skin = n end
        e.HealBot_Options_setNewSkin = function(n)
            assert(not p[n]); p[n] = Copy(p[skins.Current_Skin]); skins.HealGroups[n], skins.Icons[n] = p[n].groups, p[n].icons
            skins.Skins[#skins.Skins + 1] = n; skins.Current_Skin = n
        end
        e.hbv_Skins_SetVarSkin = function() end
        e.hbv_Skins_SetFrameVarSkin = function(v, n, category, key)
            p[n][category] = p[n][category] or {}; p[n][category][key] = v
        end
        s.current = function() return skins.Current_Skin end; s.select = e.HealBot_Options_Set_Current_Skin
        s.verify = function(target)
            Check(target.groups[4].FRAME == 1 and target.groups[5].FRAME == 1 and target.HealBar.WIDTH == 80, "HealBot new skin gets geometry")
            Check(target.icons.hot == 774 and target.groups[10].marker == "pet", "HealBot auras and other panels retained")
        end
    elseif id == "VuhDo" then
        p.Mine.NAME, p.Mine.ORIGINATOR_TOON, p.Mine.HARDLOCKED = "Mine", "Another player", true
        p.Mine.CONFIG = {CURRENT_PROFILE = "Mine"}
        p.Mine.PANEL_SETUP = {{MODEL = {}, SCALING = {}, POSITION = {x = 123}, PANEL_COLOR = {}, HOTS = {mine = 774}}, {marker = "secondary"}}
        p.Mine.SPELL_CONFIG, p.Mine.INDICATOR_CONFIG = {left = "Rejuvenation"}, {debuff = "My Bouquet"}
        for name, value in pairs(p) do
            if name ~= "Mine" then
                value.CONFIG, value.PANEL_SETUP = {CURRENT_PROFILE = name}, {{MODEL = {}, SCALING = {}}}
                value.SPELL_CONFIG, value.INDICATOR_CONFIG = {}, {}
            end
        end
        e.VUHDO_CONFIG, e.VUHDO_PANEL_SETUP = Copy(p.Mine.CONFIG), Copy(p.Mine.PANEL_SETUP)
        e.VUHDO_SPELL_CONFIG, e.VUHDO_INDICATOR_CONFIG = Copy(p.Mine.SPELL_CONFIG), Copy(p.Mine.INDICATOR_CONFIG)
        e.VUHDO_PLAYER_FULL_NAME, e.VUHDO_PLAYER_NAME = "Tester-Realm", "Tester"
        e.VUHDO_DEFAULT_PROFILE, e.VUHDO_IS_DEFAULT_PROFILE = "Mine", true
        e.VUHDO_getProfileNamedCompressed = function(n) if p[n] then return 1, p[n] end end
        e.VUHDO_saveProfile = function(n)
            assert(n ~= "Mine", "VuhDo must never overwrite source")
            p[n] = {NAME = n, ORIGINATOR_TOON = e.VUHDO_PLAYER_FULL_NAME,
                CONFIG = Copy(e.VUHDO_CONFIG), PANEL_SETUP = Copy(e.VUHDO_PANEL_SETUP),
                SPELL_CONFIG = Copy(e.VUHDO_SPELL_CONFIG), INDICATOR_CONFIG = Copy(e.VUHDO_INDICATOR_CONFIG)}
            if e.VUHDO_IS_DEFAULT_PROFILE then e.VUHDO_DEFAULT_PROFILE = n end
        end
        e.VUHDO_loadProfile = function(n)
            local value = p[n]; e.VUHDO_CONFIG, e.VUHDO_PANEL_SETUP = Copy(value.CONFIG), Copy(value.PANEL_SETUP)
            e.VUHDO_CONFIG.CURRENT_PROFILE = n
            e.VUHDO_SPELL_CONFIG, e.VUHDO_INDICATOR_CONFIG = Copy(value.SPELL_CONFIG), Copy(value.INDICATOR_CONFIG)
        end
        s.current = function() return e.VUHDO_CONFIG.CURRENT_PROFILE end; s.select = e.VUHDO_loadProfile
        s.verify = function(target)
            Check(#target.PANEL_SETUP[1].MODEL.groups == 8 and target.PANEL_SETUP[1].SCALING.barWidth == 80, "VuhDo copy gets eight groups")
            Check(target.SPELL_CONFIG.left == "Rejuvenation" and target.INDICATOR_CONFIG.debuff == "My Bouquet" and target.PANEL_SETUP[1].HOTS.mine == 774 and target.PANEL_SETUP[2].marker == "secondary", "VuhDo spells and panels retained")
            Check(e.VUHDO_DEFAULT_PROFILE == "Mine", "VuhDo default assignment retained")
        end
    end
    s:Load()
    return s, e
end

for _, id in ipairs({"Bartender4", "Dominos", "Grid2", "VuhDo", "HealBot", "DandersFrames"}) do
    local s = Fixture(id)
    local before = Copy(s.profiles)
    s.button.func()
    Check(Equal(before, s.profiles) and s.current() == "Mine", id .. ": unconfirmed callbacks cannot write")
    Check(s.button.confirm():find("Mine", 1, true), id .. ": confirmation names source")
    Check(Equal(before, s.profiles), id .. ": asking for confirmation is read-only")
    s.button.func()
    local target = s.current()
    Check(target ~= "Mine" and target ~= "LUI - Mine", id .. ": pre-existing names cannot be overwritten")
    Check(Equal(before.Mine, s.profiles.Mine) and Equal(before.Other, s.profiles.Other)
        and Equal(before["LUI - Mine"], s.profiles["LUI - Mine"]), id .. ": originals and unrelated profiles must remain exact")
    Check(id == "VuhDo" or s.profiles[target].binding.left == "Rejuvenation", id .. ": bindings copied")
    s.verify(s.profiles[target])
    local count = Count(s.profiles)
    s:Apply()
    Check(s.current() == target and Count(s.profiles) == count, id .. ": repeat setup reuses active owned copy")
    s.select("Mine"); s:Apply()
    Check(s.current() == target and Count(s.profiles) == count, id .. ": returning to original reuses its owned copy")
    Check(Equal(before.Mine, s.profiles.Mine), id .. ": repeated setup preserves source")
    local endEvent = s.events[#s.events]
    Check(endEvent[1] == "ADDON_SETUP_COMPLETED" and endEvent[2] == id, id .. ": diagnostics contain only addon ID")
    s.select("Mine"); s.button.confirm(); s.select("Other"); s.button.func()
    Check(s.current() == "Other" and Count(s.profiles) == count, id .. ": changed source cancels confirmation")
    s.select("Mine"); s.combat = true; local old = Copy(s.profiles); s.button.func()
    Check(s.button.disabled() and Equal(old, s.profiles), id .. ": combat blocks mutation")
end

-- Collision after confirmation, copy/application failure and native blockers.
do
    local s = Fixture("Grid2")
    s.button.confirm(); s.profiles["LUI - Mine (2)"] = {marker = "created while dialog open"}
    s.button.func()
    Check(s.current() == "Mine" and s.profiles["LUI - Mine (2)"].marker == "created while dialog open", "target race aborts before writes")
end
do
    local s = Fixture("Bartender4")
    local before = Copy(s.profiles.Mine); s.fail = true; s:Apply()
    Check(s.current() == "Mine" and Equal(before, s.profiles.Mine), "failed layout restores previous profile without rewriting it")
    Check(s.events[#s.events][1] == "ADDON_SETUP_CANCELLED", "failed setup is recorded as cancelled")
    local count = Count(s.profiles); s.fail = false; s:Apply()
    Check(Count(s.profiles) == count, "retry after failed layout reuses its created copy")
end
do
    local s, e = Fixture("VuhDo")
    s.loadFailure = true; local before = Copy(s.profiles); s:Apply()
    Check(s.current() == "Mine" and Equal(before, s.profiles), "missing VuhDo options cannot change original")
    s.loadFailure = false; s:Apply(); s.profiles[s.current()].HARDLOCKED = true
    Check(s.button.disabled(), "locked LUI VuhDo copy cannot be overwritten")
end
do
    local s, e = Fixture("HealBot"); e.HealBot_Data.UILOCK = true
    Check(s.button.disabled(), "HealBot native UI lock blocks copying")
end
do
    local s, e = Fixture("DandersFrames")
    e.DandersFrames.AutoProfilesUI = {IsEditing = function() return true end}
    Check(s.button.disabled(), "editing Danders automatic layouts blocks copying")
end
do
    local s = Fixture("Grid2"); s.loaded.VuhDo = true
    Check(s.button.disabled(), "multiple raid addons block setup")
    s.loaded.VuhDo = nil; s.loaded.Plexus = true
    Check(s.button.disabled(), "Plexus also blocks raid setup")
end
print("Addon setup checks passed: " .. passed)
