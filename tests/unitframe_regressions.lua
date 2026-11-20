-- Run from the repository root with Lua 5.1. Exercise real LUI callbacks and
-- upstream oUF events with native UI fixtures; no game client is required.
local passed = 0
local function Check(value, why) assert(value, why); passed = passed + 1 end
local function Noop() end

for _, forever in ipairs({false, true}) do
    local env = setmetatable({}, {__index = _G}); env._G = env
    local secret = {}
    env.issecretvalue = function(value) return rawequal(value, secret) end
    env.LE_PARTY_CATEGORY_HOME, env.LE_PARTY_CATEGORY_INSTANCE = 1, 2
    local home, instance, leader, assistant, inRaid, lfg, targetIsPlayer = true, false, true, false, false, false, false
    local groupQueries = 0
    env.IsInGroup = function(category)
        groupQueries = groupQueries + 1
        if category == 1 then return home end
        return instance
    end
    env.UnitIsUnit = function(unit, other) return unit == "target" and targetIsPlayer end
    env.UnitLeadsAnyGroup = function() return leader end
    env.UnitIsGroupLeader = function() return leader end
    env.UnitIsGroupAssistant = function() return assistant end
    env.UnitInRaid = function() if inRaid then return 1 end end
    env.IsInInstance = function() return instance == true end
    env.HasLFGRestrictions = function() return lfg end
    env.LibStub = function() return {} end
    env.C_StringUtil = {CreateSecondsFormatter = function()
        return {SetDefaultAbbreviation = Noop, SetMinInterval = Noop, SetMillisecondsThreshold = Noop}
    end}
    env.C_CurveUtil = {CreateCurve = function() return {SetType = Noop, AddPoint = Noop} end}
    env.Enum = {SecondsFormatterAbbreviation = {OneLetter = 1}, SecondsFormatterInterval = {Seconds = 1},
        PowerType = {Mana = 0}, LuaCurveType = {Linear = 1, Step = 2}}
    local elements, module, ouf = {}, {}, {}
    function ouf:RegisterStyle() end
    function ouf:AddElement(name, update, enable, disable)
        elements[name] = {update = update, enable = enable, disable = disable}
    end
    local lui = {IsForever = forever, oUF = ouf, Media = {}, GetModule = function() return module end}
    local function Load(path) setfenv(assert(loadfile(path)), env)("LUI", lui) end
    Load("modules/unitframes/layout/layout.lua")
    for _, name in ipairs({"leaderindicator", "assistantindicator"}) do
        setfenv(assert(loadfile("api/oUF13/elements/"..name..".lua")), env)("oUF", {oUF = ouf})
    end
    local function Texture()
        local texture = {SetHeight = Noop, SetWidth = Noop, ClearAllPoints = Noop, SetPoint = Noop}
        function texture:Show() self.shown = true end
        function texture:Hide() self.shown = false end
        function texture:SetAtlas(atlas) self.atlas = atlas end
        function texture:IsObjectType(kind) return kind == "Texture" end
        function texture:GetTexture() return self.texture end
        function texture:SetTexture(value) self.texture = value end
        return texture
    end
    local function Frame(unit)
        local frame = {__unit = unit, Overlay = {CreateTexture = Texture}, events = {}}
        function frame:RegisterEvent(event, callback)
            self.events[event] = self.events[event] or {}; self.events[event][callback] = true
        end
        function frame:UnregisterEvent(event, callback) self.events[event][callback] = nil end
        function frame:Fire(event)
            for callback in pairs(self.events[event] or {}) do callback(self, event) end
        end
        module.funcs.LeaderIndicator(frame, unit, {LeaderIndicator = {Size = 17, Point = "TOPLEFT", X = 0, Y = 10}})
        for name, element in pairs(elements) do Check(element.enable(frame), name.." enables") end
        return frame
    end
    local player = Frame("player")
    player:Fire("PARTY_LEADER_CHANGED")
    Check(player.LeaderIndicator.shown, "a grouped player retains the leader icon")
    home = false
    player:Fire("GROUP_ROSTER_UPDATE")
    Check(not player.LeaderIndicator.shown, "the last party member leaving hides a stale leader flag")
    home = true
    player:Fire("GROUP_ROSTER_UPDATE")
    Check(player.LeaderIndicator.shown, "rejoining restores a valid leader icon")
    leader = false
    player:Fire("PARTY_LEADER_CHANGED")
    Check(not player.LeaderIndicator.shown, "a grouped non-leader stays hidden")
    home, instance, leader, lfg = false, true, true, true
    player:Fire("GROUP_ROSTER_UPDATE")
    Check(player.LeaderIndicator.shown and player.LeaderIndicator.atlas:find("GuideIcon"), "an instance-only LFG guide remains visible")
    home, instance, lfg, inRaid = true, false, false, true
    player:Fire("GROUP_ROSTER_UPDATE")
    Check(player.LeaderIndicator.shown, "a valid one-player raid keeps its leader icon")
    home, inRaid = false, false
    local target = Frame("target")
    target:Fire("GROUP_ROSTER_UPDATE")
    Check(target.LeaderIndicator.shown, "another group's target leader stays visible while the player is solo")
    targetIsPlayer = true
    target:Fire("GROUP_ROSTER_UPDATE")
    Check(not target.LeaderIndicator.shown, "targeting oneself also hides the stale solo flag")
    targetIsPlayer = secret
    local previousQueries = groupQueries
    target:Fire("GROUP_ROSTER_UPDATE")
    Check(target.LeaderIndicator.shown and groupQueries == previousQueries, "restricted unit identity is not used in group comparisons")
    home = secret
    player:Fire("GROUP_ROSTER_UPDATE")
    Check(player.LeaderIndicator.shown, "restricted group membership does not hide an otherwise valid native indicator")
    home, leader = true, secret
    player:Fire("PARTY_LEADER_CHANGED")
    Check(not player.LeaderIndicator.shown, "upstream's restricted leader safeguard remains effective")
    home, leader, assistant, inRaid = false, false, true, true
    player:Fire("GROUP_ROSTER_UPDATE")
    Check(not player.AssistantIndicator.shown, "a stale assistant flag is hidden after group dissolution")
    home = true
    player:Fire("GROUP_ROSTER_UPDATE")
    Check(player.AssistantIndicator.shown, "valid raid assistant status returns after rejoining")
    for name, element in pairs(elements) do element.disable(player); Check(not player[name].shown, name.." disables cleanly") end
end

-- Blizzard adds UNIT_POPUP_RIGHT_CLICK after the unit data post-call. Keep
-- other instructions, widget tooltips and restricted data untouched.
do
    local env = setmetatable({}, {__index = _G}); env._G = env
    local secret = {}
    env.issecretvalue = function(value) return rawequal(value, secret) end
    env.Enum = {TooltipDataType = {Unit = 1, Item = 2}}
    env.C_Item, env.TooltipDataProcessor = {}, {AddTooltipPostCall = Noop}
    env.LibStub = function() return {} end
    env.UNIT_POPUP_RIGHT_CLICK = "Click droit pour les options"
    local enabled, widgets = true, false
    local module = {SetTooltips = Noop, SetStatusHealthBar = Noop, RegisterEvent = Noop}
    function module:IsEnabled() return enabled end
    function module:SecureHook(object, method, callback)
        if type(object) ~= "string" then return end
        local original = env[object]
        if not original then return end
        env[object] = function(...)
            original(...)
            if type(method) == "string" then return self[method](self, ...) end
            return method(...)
        end
    end
    local lui = {L = {}, NewModule = function() return module end, TooltipHasWidgets = function() return widgets end}
    local function FontString(text)
        return {text = text, shown = true, GetText = function(self) return self.text end,
            SetText = function(self, value) self.text = value end, Hide = function(self) self.shown = false end}
    end
    local function Tooltip(kind)
        local frame = {lines = {}, right = {}, data = {type = kind}, shows = 0}
        function frame:IsForbidden() return self.forbidden end
        function frame:GetTooltipData() return self.data end
        function frame:NumLines() return #self.lines end
        function frame:GetLeftLine(index) return self.lines[index] end
        function frame:GetRightLine(index) return self.right[index] end
        function frame:AddLine(text) self.lines[#self.lines + 1] = FontString(text); self.right[#self.lines] = FontString("") end
        function frame:Show() self.shows = self.shows + 1 end
        function frame:SetUnit() error("instruction removal must not rebuild a tooltip") end
        function frame:GetHeight() error("instruction removal must not inspect tooltip dimensions") end
        return frame
    end
    env.GameTooltip_AddInstructionLine = function(frame, text) frame:AddLine(text) end
    local tooltip = Tooltip(1); env.GameTooltip = tooltip
    setfenv(assert(loadfile("modules/tooltip/tooltip.lua")), env)("LUI", lui)
    module.SetTooltips, module.SetStatusHealthBar = Noop, Noop
    module:OnEnable()
    local function Reset(kind)
        tooltip.lines, tooltip.right, tooltip.data, tooltip.forbidden = {}, {}, {type = kind or 1}, false
        enabled, widgets = true, false
        tooltip:AddLine(secret); tooltip:AddLine("Level 60"); tooltip:AddLine("Addon information")
    end
    local function NativeAppend(text)
        tooltip:AddLine(" ")
        env.GameTooltip_AddInstructionLine(tooltip, text or env.UNIT_POPUP_RIGHT_CLICK)
        tooltip:Show()
    end
    Reset(); NativeAppend()
    Check(tooltip.lines[5].text == "" and not tooltip.lines[5].shown, "the localized native right-click instruction is removed")
    Check(tooltip.lines[4].text == "" and not tooltip.lines[4].shown, "its blank spacer is removed too")
    Check(tooltip.lines[1].text == secret and tooltip.lines[2].text == "Level 60" and tooltip.lines[3].text == "Addon information",
        "restricted names, normal unit rows and addon information remain intact")
    NativeAppend()
    Check(not tooltip.lines[7].shown and tooltip.lines[3].shown, "repeated native refreshes keep the instruction hidden")
    Reset(); NativeAppend("Right-click to inspect an item")
    Check(tooltip.lines[5].shown, "other right-click instructions are preserved")
    Reset(2); NativeAppend()
    Check(tooltip.lines[5].shown, "item tooltips retain their native instructions")
    Reset(); widgets = true; NativeAppend()
    Check(tooltip.lines[5].shown, "widget tooltips are untouched")
    Reset(); tooltip.forbidden = true; NativeAppend()
    Check(tooltip.lines[5].shown, "forbidden tooltips are untouched")
    Reset(); enabled = false; NativeAppend()
    Check(tooltip.lines[5].shown, "disabling the tooltip module restores normal instructions")
    Reset(secret); NativeAppend()
    Check(tooltip.lines[5].shown, "restricted tooltip types are not compared")
    Reset(); NativeAppend(secret)
    Check(tooltip.lines[5].text == secret, "restricted instruction strings are not compared or changed")
    Reset(); tooltip:AddLine("Keep this row")
    env.GameTooltip_AddInstructionLine(tooltip, env.UNIT_POPUP_RIGHT_CLICK)
    Check(tooltip.lines[4].shown and tooltip.lines[4].text == "Keep this row", "a nonblank preceding row is never removed")
    Reset(); tooltip:AddLine(" "); tooltip.right[4]:SetText("Addon right column")
    env.GameTooltip_AddInstructionLine(tooltip, env.UNIT_POPUP_RIGHT_CLICK)
    Check(tooltip.lines[4].shown and tooltip.right[4].shown, "a double-column row is never treated as a blank spacer")
    local other = Tooltip(1); other:AddLine(env.UNIT_POPUP_RIGHT_CLICK)
    module:HideUnitFrameInstruction(other, env.UNIT_POPUP_RIGHT_CLICK)
    Check(other.lines[1].shown, "other tooltip frames are not modified")
end

print("Unitframe indicator and tooltip checks passed: "..passed)
