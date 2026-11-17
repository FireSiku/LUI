-- Run from the repository root with Lua 5.1. Native UI widgets are fixtures;
-- palette resolution, theme capture and the artwork renderers are real code.
local passed = 0
local function Check(value, why) assert(value, why); passed = passed + 1 end
local function Copy(value)
    if type(value) ~= "table" then return value end
    local result = {}; for key, item in pairs(value) do result[key] = Copy(item) end; return result
end
local function Equal(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end
    for key, value in pairs(a) do if not Equal(value, b[key]) then return false end end
    for key in pairs(b) do if a[key] == nil then return false end end
    return true
end
local function Noop() end
local combat, secret, frames = false, {}, {}
local env = setmetatable({}, {__index = _G})
env._G = env
local function Frame(name)
    local frame = {scripts = {}, attributes = {}, alpha = 1, level = 2}
    for _, method in ipairs({"SetSize", "SetPoint", "SetAllPoints", "SetTexture", "SetTexCoord", "SetFrameStrata",
        "SetColorTexture", "RegisterForClicks", "RegisterEvent", "UnregisterEvent", "SetDesaturated"}) do frame[method] = Noop end
    function frame:SetScript(event, callback) self.scripts[event] = callback end
    function frame:Show() self.shown = true end
    function frame:Hide() self.shown = false end
    function frame:SetAlpha(value) self.alpha = value end
    function frame:SetFrameLevel(value) self.level = value end
    function frame:GetFrameLevel() return self.level end
    function frame:SetAttribute(key, value) self.attributes[key] = value end
    function frame:SetVertexColor(r, g, b, a) self.color = {r, g, b, a or 1} end
    function frame:CreateTexture() return Frame() end
    function frame:Stop() self.stopped = true end
    if name then env[name] = frame end
    frames[#frames + 1] = frame
    return frame
end
env.CreateFrame = function(_, name) return Frame(name) end
env.InCombatLockdown = function() return combat end
env.issecretvalue = function(value) return value == secret end
env.UnitLevel = function() return 60 end
env.UnitQuestTrivialLevelRange = function() return 8 end
env.format, env.strlower, env.gsub = string.format, string.lower, string.gsub
env.LibStub = function() return {NotifyChange = Noop} end
env.Mixin = function(target, source) for key, value in pairs(source) do target[key] = value end; return target end
env.UIParent = Frame("UIParent")
local modules = {}
local lui = {L = setmetatable({}, {__index = function(_, key) return key end}), db = {profile = {}},
    playerClass = "DRUID", PopupDialogs = {}, Media = {blank = "blank"},
    Profiler = {TraceScope = Noop}, RegisterConfig = Noop, RestorePosition = Noop,
    SetDefaultModulePrototype = Noop, GetCoordAtlas = Noop,
    OutOfCombatWrapper = function(callback) return callback end}
function lui:NewModule(name)
    local module = {name = name, enabled = true, RegisterEvent = Noop, UnregisterEvent = Noop}
    function module:GetName() return self.name end
    function module:IsEnabled() return self.enabled end
    function module:GetDB(key) return self.db.profile[key] end
    self:EmbedModule(module)
    modules[name] = module
    return module
end
function lui:GetModule(name) return modules[name] end
function lui:IterateModules() return pairs(modules) end
function lui:RegisterModule(module) module.db = {profile = Copy(module.defaults.profile)} end
function lui:NewNamespace(module)
    if not module.db then
        local profile = Copy(module.defaults.profile)
        module.db = setmetatable({profile = profile, global = Copy(module.defaults.global)},
            {__index = profile, __newindex = function(_, key, value) profile[key] = value end})
    end
    return module.db, module.defaults
end
env.LUI = lui
function lui:CreateFrameTexture() return Frame() end
local function Load(path) setfenv(assert(loadfile(path)), env)("LUI", lui) end
Load("api/modapi.lua")
Load("api/colors.lua")
local palette = modules.Colors
palette:OnInitialize()
Load("modules/artwork/artwork_init.lua")
local artwork = modules.Artwork
artwork:OnInitialize()
Load("modules/artwork/SidebarMixin.lua")
Load("modules/artwork/artwork_navbar.lua")
Load("modules/artwork/artwork_orb.lua")
Load("modules/artwork/artwork.lua")
local colors = artwork.db.profile.Colors
colors.LeftBorderBack = {r = .05, g = .4, b = .95, a = .26, t = "Individual"}
colors.RightBorderBack = {r = .9, g = .1, b = .2, a = .8, t = "Class"}
for _, name in ipairs({"NavBar", "NavBarCenter", "TopPanel", "LeftBorder", "RightBorder", "LeftBorderBack", "RightBorderBack"}) do
    artwork[name] = Frame(); artwork[name].Texture = Frame()
end
local before = Copy(artwork.db.profile)
artwork:RefreshNavBar()
Check(Equal(artwork.LeftBorderBack.Texture.color, {.05, .4, .95, .26}), "left line uses the configured color and opacity")
Check(Equal(artwork.RightBorderBack.Texture.color, artwork.LeftBorderBack.Texture.color), "both bottom lines follow the shared control")
Check(Equal(before, artwork.db.profile), "rendering never changes the saved right-side or individual color")

-- Exercise a real sidebar instance, including its color refresh after login.
-- CreateNewSideBar also constructs animations, so capture its actual mixin.
local sidebarFile = assert(io.open("modules/artwork/SidebarMixin.lua"))
local sidebarSource = sidebarFile:read("*a"); sidebarFile:close()
local prefix = sidebarSource:match("^(.-)function module:CreateNewSideBar")
assert(prefix, "sidebar constructor marker")
local SidebarMixin = setfenv(assert(loadstring(prefix .. "\nreturn SidebarMixin")), env)("LUI", lui)
local sidebar = Frame()
sidebar.name, sidebar.side = "Left", "Left"
for _, name in ipairs({"Sbar", "Drawer", "DrawerButton", "DrawerButtonOpen", "BtnAnchor", "BtnAnchorOpen", "OpenAnim", "CloseAnim"}) do sidebar[name] = Frame() end
artwork.db.profile.SideBars.Left.Enable = false
colors.SidebarLeft = {r = .2, g = .6, b = .4, a = .33, t = "Individual"}
SidebarMixin.Refresh(sidebar)
for _, name in ipairs({"Sbar", "Drawer", "DrawerButton", "DrawerButtonOpen"}) do
    Check(Equal(sidebar[name].color, {.2, .6, .4, .33}), "sidebar opacity applies to " .. name)
end
artwork.Orb = Frame()
for _, name in ipairs({"Back", "Galaxy1", "Galaxy2", "Galaxy3", "ClickerTex", "LostGalaxy"}) do artwork.Orb[name] = Frame() end
colors.Orb = {r = .2, g = .6, b = .4, a = .33, t = "Individual"}
artwork:RefreshOrb()
Check(artwork.Orb.alpha == .33, "the complete orb inherits its configured opacity")
Check(artwork.Orb.ClickerTex.color[4] == .75, "orb animation opacity remains independent")

Load("modules/micromenu/micromenu.lua")
local micro = modules.Micromenu
micro:OnInitialize()
micro.db.profile.Colors.Micromenu = {r = .2, g = .6, b = .4, a = .31, t = "Individual"}
micro.background = Frame(); micro.background.Texture = Frame()
micro.buttonMiddle = Frame(); micro.buttonMiddle.Texture = Frame()
micro:RefreshColors()
local microButton = micro:NewMicroButton({name = "Fixture"})
Check(microButton.icon.color[4] == .31 and microButton.border.color[4] == .31, "new micromenu icons and borders use saved opacity")
Check(micro.buttonMiddle.Texture.color[4] == .31, "micromenu toggle artwork uses saved opacity")
Check(micro.background.Texture.color[4] == .31, "matched micromenu background uses the same opacity")

-- Palette edits redraw live consumers, preserve individual mode, skip disabled
-- modules, and never replace the independent unitframe palette.
local calls = {callback = 0, disabled = 0, unitframes = 0}
lui:AddColorCallback("Fixture", function() calls.callback = calls.callback + 1 end)
modules.Disabled = {IsEnabled = function() return false end, RefreshColors = function() calls.disabled = calls.disabled + 1 end}
modules.Unitframes = {IsEnabled = function() return true end, Refresh = function() calls.unitframes = calls.unitframes + 1 end}
artwork.setPanels, artwork.RefreshMainPanels = Noop, Noop
colors.LeftBorderBack.t = "Class"
local allBefore = Copy(artwork.db.profile)
palette.db.profile.Colors.DRUID = {r = .7, g = .3, b = .8}
palette:RefreshColors()
Check(Equal(artwork.RightBorderBack.Texture.color, {.7, .3, .8, .26}), "shared class-palette changes reach artwork immediately")
Check(Equal(allBefore, artwork.db.profile), "palette refresh does not rewrite individual settings or color modes")
Check(calls.callback == 1 and calls.disabled == 0 and calls.unitframes == 0, "custom callbacks run once and disabled/independent modules are untouched")
combat = true
palette:RefreshColors()
Check(Equal(allBefore, artwork.db.profile), "deferred combat refresh also preserves stored colors")
combat = false

for index, entry in ipairs({{65, "DiffSkull"}, {63, "DiffHard"}, {58, "DiffEqual"}, {52, "DiffEasy"}, {51, "DiffLow"}, {-1, "DiffSkull"}}) do
    local key = entry[2]
    palette.db.profile.Colors[key] = {r = index / 10, g = .23, b = .67}
    local r, g, b = lui:GetDifficultyColor(entry[1])
    Check(r == index / 10 and g == .23 and b == .67, "custom difficulty color is used at boundary " .. entry[1])
end
local r, g, b = lui:GetDifficultyColor(secret)
Check(r == 1 and g == 1 and b == 1, "restricted levels are not compared or used in arithmetic")

Load("modules/artwork/themes.lua")
local themes = modules.Themes
themes:OnInitialize()
themes.db.theme = "Druid"
local colorsBefore = Copy(artwork.db.profile.Colors)
local microBefore = Copy(micro.db.profile.Colors)
themes:CaptureModernTheme()
Check(Equal(themes.db.color_bottom, {.7, .3, .8, .26}), "theme capture stores the visible class color")
Check(Equal(themes.db.micromenu, {.2, .6, .4, .31}), "theme capture retains individual color and opacity")
Check(Equal(colorsBefore, artwork.db.profile.Colors) and Equal(microBefore, micro.db.profile.Colors), "theme capture never mutates live module colors")
local registered = 0
themes.RegisterEvent = function() registered = registered + 1 end
themes:OnInitialize()
themes:OnEnable()
Check(registered == 0, "a valid existing theme is not reapplied on login or reload")
Check(Equal(colorsBefore, artwork.db.profile.Colors), "login keeps manual adjustments made after choosing a theme")
print("colors: " .. passed .. " checks passed")
