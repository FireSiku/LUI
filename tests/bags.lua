-- Run from the repository root with Lua 5.1. These fixtures exercise LUI's
-- existing bag hooks and lifecycle, including native close-request ownership.
-- WoW's C-side taint tracking still requires verification in the game client.
local passed, failures = 0, {}
local function Check(value, why) assert(value, why); passed = passed + 1 end
local function Noop() end
local function Copy(value)
    if type(value) ~= "table" then return value end
    local result = {}; for key, item in pairs(value) do result[key] = Copy(item) end; return result
end

local function Setup(forever)
    local env = setmetatable({}, {__index = _G}); env._G = env
    env.Enum = {BagIndex = {Backpack = 0, Bag_1 = 1, Bag_2 = 2, Bag_3 = 3, Bag_4 = 4, ReagentBag = 5, Keyring = -2}, BankType = {Character = 0, Account = 2}}
    env.issecretvalue = function() return false end
    env.tContains = function(t, value) for _, item in pairs(t) do if item == value then return true end end end
    env.tinsert, env.strlower, env.strfind = table.insert, string.lower, string.find
    env.wipe = function(t) for key in pairs(t) do t[key] = nil end; return t end
    env.GetNumWatchedTokens = function() return 0 end
    env.C_CurrencyInfo, env.C_NewItems = {}, {}
    env.UISpecialFrames, env.NUM_CONTAINER_FRAMES = {}, 2
    env.SOUNDKIT = {UI_BAG_SORTING_01 = 1}
    env.LibStub = function() return {Fetch = function() return "media" end} end
    local timers, hooks, callbacks = {}, {}, {}
    env.C_Timer = {NewTimer = function(_, callback)
        local timer = {callback = callback, Cancel = function(self) self.cancelled = true end}
        timers[#timers + 1] = timer; return timer
    end}
    function env.FlushTimers()
        local count = 0
        while #timers > 0 do
            count = count + 1; assert(count < 40, "timer did not settle")
            local timer = table.remove(timers, 1)
            if not timer.cancelled then timer.callback() end
        end
    end
    env.EventRegistry = {}
    function env.EventRegistry:RegisterCallback(event, callback, owner)
        callbacks[event] = callbacks[event] or {}
        assert(not callbacks[event][owner], "duplicate native callback")
        callbacks[event][owner] = callback
    end
    function env.EventRegistry:UnregisterCallback(event, owner)
        if callbacks[event] then callbacks[event][owner] = nil end
    end
    function env.EventRegistry:TriggerEvent(event, ...)
        for owner, callback in pairs(callbacks[event] or {}) do callback(owner, ...) end
    end
    local function Frame(name, parent)
        local frame = {name = name, parent = parent, shown = false, points = {}, attributes = {}, scripts = {}, events = {}, width = 40, height = 40, scale = 1}
        function frame:GetName() return self.name end
        function frame:GetParent() return self.parent end
        function frame:SetParent(value) self.parent = value end
        function frame:SetScript(event, callback) self.scripts[event] = callback end
        function frame:HookScript(event, callback)
            local old = self.scripts[event]
            self.scripts[event] = function(self, ...) if old then old(self, ...) end; callback(self, ...) end
        end
        function frame:Show()
            if self.shown then return end
            self.shown = true; if self.scripts.OnShow then self.scripts.OnShow(self) end
        end
        function frame:Hide()
            if not self.shown then return end
            self.shown = false; if self.scripts.OnHide then self.scripts.OnHide(self) end
        end
        function frame:SetShown(value) if value then self:Show() else self:Hide() end end
        function frame:IsShown() return self.shown end
        function frame:Open() self:Show() end
        function frame:Close() self:Hide() end
        function frame:RegisterEvent(event) self.events[event] = true end
        function frame:UnregisterEvent(event) self.events[event] = nil end
        function frame:UnregisterAllEvents() self.events = {} end
        function frame:Fire(event, ...)
            if self.events[event] and self.scripts.OnEvent then self.scripts.OnEvent(self, event, ...) end
        end
        function frame:SetSize(w, h) self.width, self.height = w, h end
        function frame:GetSize() return self.width, self.height end
        function frame:GetWidth() return self.width end
        function frame:GetHeight() return self.height end
        function frame:SetScale(value) self.scale = value end
        function frame:GetScale() return self.scale end
        function frame:SetAttribute(key, value) self.attributes[key] = value end
        function frame:GetAttribute(key) return self.attributes[key] end
        function frame:GetNumPoints() return #self.points end
        function frame:GetPoint(i) return unpack(self.points[i or 1]) end
        function frame:ClearAllPoints() self.points = {} end
        function frame:SetPoint(...) self.points[#self.points + 1] = {...} end
        function frame:SetAllPoints(target) self.points = {{"TOPLEFT", target, "TOPLEFT", 0, 0}, {"BOTTOMRIGHT", target, "BOTTOMRIGHT", 0, 0}} end
        function frame:GetNormalTexture() return nil end
        function frame:GetFrameLevel() return 1 end
        frame.SetFrameLevel, frame.SetTitle = Noop, Noop
        if name then env[name] = frame end
        return frame
    end
    env.CreateFrame = function(_, name, parent) return Frame(name, parent) end
    env.UIParent = Frame("UIParent"); env.UIParent:Show()
    env.LUIBags = Frame("LUIBags", env.UIParent)
    env.ContainerFrame1 = Frame("ContainerFrame1", env.UIParent)
    env.ContainerFrame2 = Frame("ContainerFrame2", env.UIParent)
    env.ContainerFrame1.GetBagID = function() return 0 end
    env.ContainerFrame2.GetBagID = function() return 1 end
    env.InCombatLockdown = function() return env.combat == true end
    env.nativeInsert, env.nativeSort, env.sorts = true, true, 0
    env.C_Container = {
        GetInsertItemsLeftToRight = function() return env.nativeInsert end,
        SetInsertItemsLeftToRight = function(value) env.nativeInsert = value end,
        GetSortBagsRightToLeft = function() return env.nativeSort end,
        SetSortBagsRightToLeft = function(value) env.nativeSort = value end,
        SortBags = function() env.sorts = env.sorts + 1 end,
    }
    env.C_Item = {GetItemQualityColor = function() return 1, 1, 1 end}
    local module = {enabled = true}
    function module:IsEnabled() return self.enabled end
    function module:SecureHook(object, name, callback)
        if type(object) == "string" then callback, name, object = name, object, env end
        hooks[object] = hooks[object] or {}; hooks[object][name] = callback
    end
    function module:IsHooked(object, name) return hooks[object] and hooks[object][name] ~= nil end
    function module:SecureHookScript(frame, event, callback)
        hooks[frame] = hooks[frame] or {}; hooks[frame][event] = callback
        frame:HookScript(event, callback)
    end
    function module:UnhookAll() hooks = {} end
    function module:RegisterEvent() end
    function module:UnregisterEvent() end
    local lui = {IsForever = forever, GetModule = function() return module end, NewModule = function() return module end,
        SetNativeReplacementActive = Noop, Print = Noop, TooltipHasWidgets = function() return false end,
        HasClientFeature = function() return false end}
    local function Load(path) setfenv(assert(loadfile(path)), env)("LUI", lui) end
    Load("modules/bags/bags_init.lua")
    module.db = {profile = Copy(module.defaults.profile), char = Copy(module.defaults.char)}
    Load("modules/bags/bags.lua")
    Load("modules/bags/backpack.lua")
    Load("modules/bags/bank.lua")
    function env.Invoke(object, name, ...)
        local results = {object[name](...)}
        local callback = hooks[object] and hooks[object][name]
        if callback then callback(...) end
        return unpack(results)
    end
    env.ContainerFrame_AllowedToOpenBags = function() return not env.bagsBlocked end
    env.CloseBackpack = function() env.ContainerFrame1:Hide() end
    env.OpenBackpack = function() env.ContainerFrame1:Show() end
    env.ToggleBackpack = function() env.ContainerFrame1:SetShown(not env.ContainerFrame1:IsShown()) end
    env.ToggleAllBags, env.OpenAllBags = env.ToggleBackpack, env.OpenBackpack
    env.OpenBag, env.CloseBag, env.ToggleBag = Noop, Noop, Noop
    env.ContainerFrame_GenerateFrame = Noop
    env.CloseAllBags = function(frame)
        -- The same guard/event order as both clients' native CloseAllBags.
        if frame and frame ~= env.bagOpener then return false end
        env.bagOpener = nil
        env.Invoke(env, "CloseBackpack")
        env.EventRegistry:TriggerEvent("ContainerFrame.CloseAllBags")
        return true
    end
    return env, module, Frame, Load
end

local function Scenario(forever, name, callback)
    local ok, why = pcall(callback, Setup(forever))
    if not ok then failures[#failures + 1] = (forever and "Forever: " or "Retail: ") .. name .. ": " .. tostring(why) end
end

for _, forever in ipairs({false, true}) do
    Scenario(forever, "native request ownership", function(env, module, Frame)
        local originals = {}; for _, name in ipairs({"OpenAllBags", "CloseAllBags", "ToggleAllBags", "OpenBag", "CloseBag", "ToggleBag"}) do originals[name] = env[name] end
        module:EnableNativeBagHooks()
        env.bagOpener = Frame("BagOpener")
        env.Invoke(env, "OpenAllBags"); env.FlushTimers()
        Check(env.LUIBags:IsShown(), "an accepted native open opens LUI")
        Check(env.Invoke(env, "CloseAllBags", Frame("OtherPanel")) == false, "native rejects another panel's close")
        env.FlushTimers()
        Check(env.LUIBags:IsShown(), "LUI must respect a rejected native close")
        env.Invoke(env, "CloseAllBags", env.bagOpener); env.FlushTimers()
        Check(not env.LUIBags:IsShown(), "an accepted close also closes LUI")
        for name, original in pairs(originals) do Check(env[name] == original, name .. " is not replaced") end
        module:DisableNativeBagHooks(); module:UnhookAll()
        module:EnableNativeBagHooks()
        module:DisableNativeBagHooks(); module:UnhookAll()
        env.LUIBags:Show()
        env.EventRegistry:TriggerEvent("ContainerFrame.CloseAllBags"); env.FlushTimers()
        Check(env.LUIBags:IsShown(), "disabled Bags has no live close callback")
    end)
    Scenario(forever, "native sync lifecycle", function(env, module)
        module:EnableNativeBagHooks()
        env.Invoke(env, "OpenBackpack"); env.Invoke(env, "CloseBackpack"); env.FlushTimers()
        Check(not env.LUIBags:IsShown(), "nested open/close requests settle once to the final state")
        env.bagsBlocked = true; env.Invoke(env, "OpenBackpack"); env.FlushTimers()
        Check(not env.LUIBags:IsShown(), "game rules can reject an open")
        env.bagsBlocked = false; env.Invoke(env, "OpenBackpack")
        module:DisableNativeBagHooks(); env.FlushTimers()
        Check(not env.LUIBags:IsShown(), "a pending open is cancelled on disable")
        Check(env.ContainerFrame1:GetParent() == env.UIParent, "native bag parent is restored")
    end)
    if forever then
        Scenario(forever, "keyring frame reuse", function(env, module)
            module:EnableNativeBagHooks()
            Check(env.ContainerFrame2:GetParent() ~= env.UIParent, "character bags are suppressed")
            env.ContainerFrame2.GetBagID = function() return -2 end
            env.Invoke(env, "ContainerFrame_GenerateFrame", env.ContainerFrame2)
            Check(env.ContainerFrame2:GetParent() == env.UIParent, "a container reused for the native keyring is restored")
        end)
        Scenario(forever, "native bank ownership", function(_, module)
            module:EnableBank()
            Check(not module.bankIntegrationEnabled and not module.bankLoadWatcher, "Forever's bank is not restyled or initialized")
        end)
    end
    Scenario(forever, "sorting preferences", function(env, module)
        module.Refresh = Noop
        module.db.profile.Bags.FillFromBottom = true
        module:SortBags(); env.FlushTimers()
        Check(env.sorts == 1 and not env.nativeSort and not env.nativeInsert, "cleanup applies the requested fill direction")
        module:RestoreBlizzardBagState()
        Check(env.nativeSort and env.nativeInsert, "disabling restores both native sorting and loot insertion")
        module:RestoreBlizzardBagState()
        Check(env.nativeSort and env.nativeInsert, "repeated restoration is harmless")
    end)
    Scenario(forever, "external preferences", function(env, module)
        module.db.profile.Bags.FillFromBottom = false
        module:ConfigureBagLootInsertion()
        env.nativeInsert = false
        module:RestoreBlizzardBagState()
        Check(not env.nativeInsert, "do not overwrite a later native or external insertion change")
    end)
    Scenario(forever, "false preferences and a new enable cycle", function(env, module)
        module.Refresh = Noop
        env.nativeSort, env.nativeInsert = false, false
        module.db.profile.Bags.FillFromBottom = false
        module:SortBags(); env.FlushTimers()
        module:RestoreBlizzardBagState()
        Check(not env.nativeSort and not env.nativeInsert, "false preferences are saved and restored too")
        env.nativeSort, env.nativeInsert = true, true
        module:SortBags(); env.FlushTimers()
        env.nativeSort = false
        module:RestoreBlizzardBagState()
        Check(not env.nativeSort and env.nativeInsert, "a new cycle captures new baselines and preserves a later sort change")
    end)
    Scenario(forever, "disabled module", function(env, module)
        module.enabled = false
        module.db.profile.Bags.FillFromBottom = true
        module:Refresh()
        Check(env.nativeInsert, "a refresh of disabled Bags leaves native preferences alone")
        module:SortBags(); env.FlushTimers()
        Check(env.sorts == 0 and env.nativeSort, "disabled Bags cannot start sorting")
    end)
    Scenario(forever, "combat and cancellation", function(env, module)
        module.Refresh = Noop
        module:SortBags(); env.combat = true; env.FlushTimers()
        Check(env.sorts == 0, "a queued sort waits if combat begins")
        Check(module.bagSortWatcher.events.PLAYER_REGEN_ENABLED, "the sort can resume after combat")
        module.enabled = false; module:OnDisable(); env.combat = false
        module.bagSortWatcher:Fire("PLAYER_REGEN_ENABLED"); env.FlushTimers()
        Check(env.sorts == 0, "a combat-deferred sort cannot resume after disabling Bags")
    end)
end

Scenario(false, "bank presentation restoration", function(env, module, Frame)
    local bank, panel = Frame("BankFrame", env.UIParent), Frame(nil, env.UIParent)
    bank.BankPanel = panel; bank.GetTabButton = Noop
    bank:Show(); panel:Show()
    panel.RefreshBankPanel = function() env.bankRebuilds = (env.bankRebuilds or 0) + 1 end
    panel.RequestTitleRefresh, panel.RefreshBankTabs, panel.RefreshAllItemsForSelectedTab = Noop, Noop, Noop
    panel.GetActiveBankType = function() return 0 end
    local slot = Frame("BankSlot", panel); slot:Show()
    slot.Refresh = Noop; slot.GetContainerSlotID = function() return 1 end
    slot.bankType, slot.bankTabID, slot.containerSlotID = 0, 6, 1
    local originalPoints = {"TOPLEFT", panel, "TOPLEFT", 26, -63}
    slot:SetPoint(unpack(originalPoints))
    panel.EnumerateValidItems = function()
        local used; return function() if not used then used = true; return slot end end
    end
    panel.bankTabPool = {EnumerateActive = function() return function() end end}
    panel.GenerateItemSlotsForSelectedTab = function()
        slot:ClearAllPoints(); slot:SetPoint("TOPLEFT", panel, "TOPLEFT", 50, -90)
    end
    env.UpdateUIPanelPositions = Noop
    module.ApplyItemStyle, module.ApplyBagFrameStyle = Noop, Noop
    module.db.profile.Bank.Enabled = true
    module:EnableBank()
    Check(slot:GetWidth() == 36, "enabling the bank applies the LUI item size")
    env.Invoke(panel, "GenerateItemSlotsForSelectedTab", panel)
    module.db.profile.Bank.Enabled = false; module:RefreshBank()
    Check(not env.bankRebuilds, "restoring presentation must not initialize Blizzard item identities")
    Check(slot:GetWidth() == 40, "the native item size is restored")
    local point, relative, relativePoint, x, y = slot:GetPoint()
    Check(point == "TOPLEFT" and relative == panel and relativePoint == "TOPLEFT" and x == 50 and y == -90, "restore the latest native anchors after pool reuse")
    Check(slot.bankType == 0 and slot.bankTabID == 6 and slot.containerSlotID == 1, "bank item identity remains untouched")
end)

if #failures > 0 then error(table.concat(failures, "\n")) end
print("bags: " .. passed .. " checks passed")
