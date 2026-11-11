-- Exercise the real defaults, option callbacks, anchor validation and fader.
local passed = 0
local function Check(value, why) assert(value, why); passed = passed + 1 end
local function Near(a, b) return math.abs(a - b) < 0.000001 end
local function Copy(v)
    if type(v) ~= "table" then return v end
    local t = {}; for k, x in pairs(v) do t[k] = Copy(x) end; return t
end
local combat, target = false, false
local frames, env = {}, setmetatable({}, {__index = _G})
env._G = env
local function Frame(name)
    local f = {name = name, scripts = {}, events = {}, alpha = 1, visible = true, points = {}, changes = 0}
    function f:IsObjectType(kind) return kind == "Frame" end
    function f:IsForbidden() return self.forbidden end
    function f:GetName() return self.name end
    function f:GetParent() return self.parent end
    function f:GetNumPoints() return #self.points end
    function f:GetPoint(i) return unpack(self.points[i]) end
    function f:SetPoint(...) self.points[#self.points + 1] = {...}; self.changes = self.changes + 1 end
    function f:ClearAllPoints() self.points = {}; self.changes = self.changes + 1 end
    function f:RegisterEvent(event) self.events[event] = true end
    function f:UnregisterAllEvents() self.events = {} end
    function f:SetScript(event, callback) self.scripts[event] = callback end
    function f:IsVisible() return self.visible end
    function f:IsMouseOver() return self.hovered end
    function f:IsElementEnabled(name) return name == "Range" and self.rangeEnabled end
    function f:SetAlpha(value) self.alpha = value end
    function f:SetAlphaFromBoolean(value, inside, outside) self.rangeCall = {value, inside, outside} end
    if name then env[name] = f end
    return f
end
env.UIParent = Frame("UIParent")
env.CopyTable, env.format, env.LibStub = Copy, string.format, function() return {} end
env.InCombatLockdown = function() return combat end
env.UnitExists = function(unit) assert(unit == "target"); return target end
env.CreateFrame = function() local f = Frame(); frames[#frames + 1] = f; return f end
local module = {BuildUnitframeColors = function() end, IsEnabled = function() return true end}
function module:SecureHookScript(frame, event, callback) frame.scripts[event] = callback end
function module:Unhook(frame, event) frame.scripts[event] = nil end
local lui = {Points = {CENTER = "Center", LEFT = "Left", RIGHT = "Right"}, db = {global = {}},
    RegisterEvent = function() end, OutOfCombatWrapper = function(fn) return fn end,
    NewModule = function() return module end,
    GetModule = function(_, name) if name == "Unitframes" then return module end end,
    RegisterModule = function(_, m) m.db = {profile = Copy(m.defaults.profile)}; m.registered = true end}
env.LUI = lui
local function Load(file, namespace, addon)
    local fn = assert(loadfile(file)); setfenv(fn, env)(addon or "LUI", namespace or lui)
end
Load("api/utils.lua")
Load("modules/unitframes/unitframes_init.lua")
Load("modules/unitframes/defaults/Settings.lua")
for _, unit in ipairs(module.units) do Load("modules/unitframes/defaults/"..unit..".lua") end
module:OnInitialize()
for _, unit in ipairs(module.units) do
    Check(module.db.profile[unit].Fading.ShowWithTarget == false, unit..": target visibility defaults off")
end
local options
local opt = {LUI = lui, GetLUIModule = function() return setmetatable({}, {__index = function(_, k) return k end}), module, module.db.profile end,
    CreateModuleOptions = function() options = {}; return options end,
    GetSet = function() return function() end, function() end end,
    ColorGetSet = function() return function() end, function() end end,
    RefreshOptionsPanel = function() end}
for _, method in ipairs({"Group", "InlineGroup", "Header", "Desc", "Execute", "Toggle", "Select", "Slider", "Input", "InputNumber",
    "PositionX", "PositionY", "OffsetX", "OffsetY", "Spacer", "Color", "MediaFont", "MediaStatusbar", "MediaBackground", "MediaBorder"}) do
    opt[method] = function(_, t) t = t or {}; if method == "Group" or method == "InlineGroup" then t.args = t.args or {} end; return t end
end
Load("LUIOptions/Unitframes.lua", opt, "LUIOptions")
local anchor = options.args.player.args.General.args.Anchor
local viewers = {"EssentialCooldownViewer", "UtilityCooldownViewer", "BuffIconCooldownViewer", "BuffBarCooldownViewer"}
for _, name in ipairs(viewers) do Check(not anchor.values()[name] and not env[name], "missing CDM anchors are not created or offered") end
for _, name in ipairs(viewers) do Frame(name).parent = env.UIParent end
for _, name in ipairs(viewers) do Check(anchor.values()[name] ~= nil, "loaded CDM anchor is offered: "..name) end
local player = Frame("oUF_LUI_player")
local settings = module.db.profile.player
settings.Anchor, settings.AnchorPoint, settings.Point, settings.X, settings.Y, settings.Scale = viewers[1], "LEFT", "RIGHT", 42, -12, 2
module:RefreshAnchors()
Check(player.points[1][2] == env[viewers[1]] and player.points[1][3] == "LEFT"
    and player.points[1][4] == 21 and player.points[1][5] == -6, "selected CDM is used by the real position code")
for _, name in ipairs(viewers) do Check(env[name].changes == 0 and env[name].parent == env.UIParent, "LUI never repositions or reparents the CDM") end
env[viewers[1]]:SetPoint("CENTER", player, "CENTER", 0, 0)
Check(anchor.validate(nil, viewers[1]) ~= true, "CDM dependency cycles are rejected")
module:RefreshAnchors()
Check(player.points[1][2] == env.UIParent, "invalid CDM anchors fall back to screen")
env[viewers[1]]:ClearAllPoints()
env[viewers[1]].forbidden = true
Check(anchor.validate(nil, viewers[1]) ~= true, "forbidden anchors are rejected")
env[viewers[1]].forbidden = false
settings.Anchor = "UIParent"
module:RefreshAnchors()
Check(player.points[1][2] == env.UIParent, "screen anchoring remains selectable")
local fadingOptions = options.args.player.args.General.args.Fading.args
Check(fadingOptions.ShowWithTarget and fadingOptions.ShowWithTarget.disabled(), "target toggle is present and disabled when fading is off")
settings.Fading.Enable = true
Check(not fadingOptions.ShowWithTarget.disabled(), "target toggle enables with fading")
Load("modules/unitframes/layout/fading.lua")
local events = frames[#frames]
local function Event(name) assert(events.events[name], name.." is not registered"); events.scripts.OnEvent(events, name) end
local function Script(frame, name) assert(frame.scripts[name]); frame.scripts[name](frame) end
local function Alpha(value, why) Check(Near(player.alpha, value), why) end
-- Existing profiles without the new key retain their old fading behavior.
settings.Fading.ShowWithTarget = nil; target = true
module:ConfigureFading(player, settings)
Alpha(.35, "old profiles stay faded with a target until explicitly enabled")
settings.Fading.ShowWithTarget = true
module:ConfigureFading(player, settings)
Alpha(1, "an already selected target restores opacity when enabled")
target = false; Event("PLAYER_TARGET_CHANGED")
Alpha(.35, "clearing target restores out-of-combat opacity")
Script(player, "OnEnter"); Alpha(1, "mouseover still restores opacity")
Event("PLAYER_TARGET_CHANGED"); Alpha(1, "target changes preserve mouseover opacity")
Script(player, "OnLeave"); Alpha(.35, "leaving mouseover fades when no target exists")
combat = true; Event("PLAYER_REGEN_DISABLED"); Alpha(1, "combat restores opacity")
Event("PLAYER_TARGET_CHANGED"); Alpha(1, "clearing target cannot clear combat state")
target = true; Event("PLAYER_TARGET_CHANGED"); Alpha(1, "selecting target in combat preserves opacity")
combat = false; Event("PLAYER_REGEN_ENABLED"); Alpha(1, "target keeps frame visible after combat")
local other = Frame()
module:ConfigureFading(other, {Enable = true, Fading = {Enable = true, ShowWithTarget = false, OutOfCombatAlpha = .2}})
Check(other.alpha == .2 and player.alpha == 1, "target visibility is configured separately for each unit")
-- Range booleans stay opaque; only the normal alpha multipliers are adjusted.
local opaque = {}
local oldPre, oldPost = function() end, function() end
player.Range = {__owner = player, insideAlpha = .8, outsideAlpha = .2, PreUpdate = oldPre, PostUpdate = oldPost}
player.rangeEnabled = true
module:ConfigureFading(player, settings)
player.Range:PostUpdate(player, opaque, true)
Event("PLAYER_TARGET_CHANGED")
Check(player.rangeCall[1] == opaque and Near(player.rangeCall[2], .8) and Near(player.rangeCall[3], .2), "target visibility retains normal range fading and opaque boolean")
target = false; Event("PLAYER_TARGET_CHANGED")
Check(Near(player.rangeCall[2], .28) and Near(player.rangeCall[3], .07), "clearing target combines range fading with out-of-combat opacity")
module:DisableFading()
Check(player.Range.PreUpdate == oldPre and player.Range.PostUpdate == oldPost
    and player.Range.insideAlpha == .8 and player.Range.outsideAlpha == .2, "disabling restores original range callbacks and opacity")
Check(not next(events.events) and not next(player.scripts) and not next(other.scripts), "disabling all fading removes its events and hooks")
player.rangeEnabled = false; target = true
module:ConfigureFading(player, settings); Alpha(1, "enabling fading initializes the current target")
player.visible = false; Script(player, "OnHide")
target = false; Event("PLAYER_TARGET_CHANGED")
player.visible = true; Script(player, "OnShow"); Alpha(.35, "hidden frames use the current target state when shown again")
module:DisableFading()
local preview = Frame(); preview.LUIPreview = true
module:ConfigureFading(preview, settings)
Check(preview.alpha == 1 and not next(preview.scripts) and not next(events.events), "previews remain fully visible without fader hooks")
print("Unitframe visibility and anchor checks passed: "..passed)
