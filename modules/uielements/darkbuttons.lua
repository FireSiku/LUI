-- Bundled dark artwork for recognized Blizzard button textures.
-- This file belongs to UI Elements; it never changes click handlers or icons.
local LUI = select(2, ...)
local module = LUI:GetModule("UI Elements")
local PATH = [[Interface\AddOns\LUI\media\buttons\]]
local replacements, artwork = {}, {}
local records = setmetatable({}, {__mode = "k"})
local hooked = setmetatable({}, {__mode = "k"})
local active, applying, hooksInstalled = false, false, false
local scanState
local aceGUIHooked = false
local eventFrame = CreateFrame("Frame")
local unpack = unpack or table.unpack

local files = {
    "ButtonHilight-Square", "CheckButtonGlow", "CheckButtonHilight",
    "UI-ActionButton-Border", "UI-CheckBox-Down", "UI-CheckBox-Highlight", "UI-CheckBox-Up",
    "UI-DialogBox-Button-Disabled", "UI-DialogBox-Button-Down",
    "UI-DialogBox-Button-Highlight", "UI-DialogBox-Button-Up",
    "UI-MinusButton-Disabled", "UI-MinusButton-Down", "UI-MinusButton-Up",
    "UI-Panel-Button-Disabled-Down", "UI-Panel-Button-Disabled", "UI-Panel-Button-Down",
    "UI-Panel-Button-Highlight", "UI-Panel-Button-Up",
    "UI-Panel-MinimizeButton-Disabled", "UI-Panel-MinimizeButton-Down",
    "UI-Panel-MinimizeButton-Highlight", "UI-Panel-MinimizeButton-Up",
    "UI-PlusButton-Disabled", "UI-PlusButton-Down", "UI-PlusButton-Up",
    "UI-Quickslot-Depress", "UI-Quickslot2", "UI-QuickslotGray", "UI-QuickslotRed",
    "UI-RotationLeft-Button-Down", "UI-RotationLeft-Button-Up",
    "UI-RotationRight-Button-Down", "UI-RotationRight-Button-Up", "UI-ScrollBar-Knob",
    "UI-ScrollBar-ScrollDownButton-Disabled", "UI-ScrollBar-ScrollDownButton-Down",
    "UI-ScrollBar-ScrollDownButton-Up", "UI-ScrollBar-ScrollUpButton-Disabled",
    "UI-ScrollBar-ScrollUpButton-Down", "UI-ScrollBar-ScrollUpButton-Up",
    "UI-SpellbookIcon-NextPage-Disabled", "UI-SpellbookIcon-NextPage-Down",
    "UI-SpellbookIcon-NextPage-Up", "UI-SpellbookIcon-PrevPage-Disabled",
    "UI-SpellbookIcon-PrevPage-Down", "UI-SpellbookIcon-PrevPage-Up",
}

-- Only these modern atlas decorations are replaced. Checkmarks, labels,
-- icons and unlisted atlas textures retain their native artwork.
local atlases = {
    ["RedButton-Exit"] = "UI-Panel-MinimizeButton-Up",
    ["RedButton-exit-pressed"] = "UI-Panel-MinimizeButton-Down",
    ["RedButton-Exit-Disabled"] = "UI-Panel-MinimizeButton-Disabled",
    ["checkbox-minimal"] = "UI-CheckBox-Up",
}
local ACTION_BORDER = "UI-HUD-ActionBar-IconFrame"
local tintAtlases = {[ACTION_BORDER] = "tint"}
-- SharedButton and the Escape menu use these three-piece decorations. Keep
-- their native slices, sizes and UVs; only their color treatment changes.
for _, family in ipairs({"128-RedButton", "128-GoldRedButton"}) do
    for _, suffix in ipairs({"", "-Disabled", "-Pressed"}) do
        tintAtlases[family .. "-Left" .. suffix] = "desaturate"
        tintAtlases[family .. "-Right" .. suffix] = "desaturate"
        tintAtlases["_" .. family .. "-Center" .. suffix] = "desaturate"
    end
end

local function IsSecret(value)
    return issecretvalue and issecretvalue(value)
end

local function CanTouch(object)
    if IsSecret(object) or not object then return false end
    return not (object.IsForbidden and object:IsForbidden())
end

local function PublicValues(...)
    for index = 1, select("#", ...) do
        if IsSecret(select(index, ...)) then return nil end
    end
    return {...}
end

local function TextureKey(texture)
    if type(texture) == "string" then
        return texture:lower():gsub("/", "\\")
    end
    return texture
end

local function DeferCombat(needsReconcile)
    -- A texture changed behind a paused discovery cursor. Revisit it after
    -- combat; merely pausing discovery does not require another full pass.
    if needsReconcile and scanState then
        if scanState.started then scanState.again = true
        else scanState.full = true end
    end
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
end

local function OwnsArtwork(region, record)
    local atlas, texture = region:GetAtlas(), region:GetTexture()
    if IsSecret(atlas) or IsSecret(texture) then return false end
    if record.file then
        -- GetTexture may return a file ID even when SetTexture received a path.
        local art = record.file
        return not atlas and (texture == art.path
            or (art.fileID and texture == art.fileID)
            or TextureKey(texture) == art.pathKey)
    end
    return atlas == record.atlas
end

local function RestoreRegion(region, record)
    if not CanTouch(region) or not OwnsArtwork(region, record) then return end
    applying = true
    if record.file then
        if record.atlas then
            region:SetAtlas(record.atlas)
        else
            region:SetTexture(record.texture)
        end
        if record.coords then region:SetTexCoord(unpack(record.coords)) end
    else
        region:SetVertexColor(unpack(record.color))
        if record.desaturation ~= nil then region:SetDesaturation(record.desaturation) end
    end
    applying = false
end

local function RestoreArtwork()
    if InCombatLockdown() then DeferCombat(); return end
    if not next(records) then return end
    for region, record in pairs(records) do
        RestoreRegion(region, record)
    end
    -- Release the old hash capacity after a complete restore.
    records = setmetatable({}, {__mode = "k"})
end

local ApplyRegion
local function SourceChanged(region)
    if applying then return end
    if not active then
        -- A native setter has replaced our art while a combat-delayed restore
        -- was pending; it must not be overwritten with an obsolete snapshot.
        local record = records[region]
        if record and CanTouch(region) and not OwnsArtwork(region, record) then
            records[region] = nil
        end
        return
    end
    ApplyRegion(region)
end

local function CoordinatesChanged(region, ...)
    if applying or not CanTouch(region) then return end
    local record = records[region]
    if not record or not record.atlas or not record.file then return end
    local coords = PublicValues(...)
    if not coords then return end
    record.coords = coords
    if not active then return end
    if InCombatLockdown() then DeferCombat(true); return end
    applying = true
    region:SetTexCoord(0, 1, 0, 1)
    applying = false
end

local function ColorChanged(region)
    if applying or not CanTouch(region) then return end
    local record = records[region]
    if not record or record.file then return end
    local color = PublicValues(region:GetVertexColor())
    if not color then return end
    record.color = color
    if not active then return end
    if InCombatLockdown() then DeferCombat(true); return end
    applying = true
    region:SetVertexColor(.18, .18, .18, color[4])
    applying = false
end

local function DesaturationChanged(region, value)
    if applying or not CanTouch(region) or IsSecret(value) then return end
    local record = records[region]
    if not record or record.desaturation == nil then return end
    if type(value) == "boolean" then value = value and 1 or 0 end
    if type(value) ~= "number" then return end
    record.desaturation = value
    if not active then return end
    if InCombatLockdown() then DeferCombat(true); return end
    applying = true
    region:SetDesaturation(1)
    applying = false
end

ApplyRegion = function(region)
    if applying or not active or not CanTouch(region) then return end
    if InCombatLockdown() then DeferCombat(true); return end
    if region:GetObjectType() ~= "Texture" then return end
    local atlas, texture = region:GetAtlas(), region:GetTexture()
    if IsSecret(atlas) or IsSecret(texture) then return end
    local previous = records[region]
    if previous and OwnsArtwork(region, previous) then
        -- Reconcile native changes made during combat without replacing the
        -- original source we need when this option/module is disabled.
        applying = true
        if previous.file and previous.atlas then
            region:SetTexCoord(0, 1, 0, 1)
        elseif not previous.file then
            region:SetVertexColor(.18, .18, .18, previous.color[4])
            if previous.desaturation ~= nil then region:SetDesaturation(1) end
        end
        applying = false
        return
    end
    -- An atlas switch can keep the previous vertex color. Undo our tint before
    -- classifying the new source, including switches to unrelated artwork.
    if previous and not previous.file then
        applying = true
        region:SetVertexColor(unpack(previous.color))
        if previous.desaturation ~= nil then region:SetDesaturation(previous.desaturation) end
        applying = false
    end
    records[region] = nil

    local file = atlas and artwork[atlases[atlas]]
    if atlas == "checkbox-minimal" then
        local parent = region:GetParent()
        if CanTouch(parent) and parent:IsObjectType("Button") then
            if region == parent:GetHighlightTexture() then file = artwork["UI-CheckBox-Highlight"]
            elseif region == parent:GetPushedTexture() then file = artwork["UI-CheckBox-Down"] end
        end
    end
    -- Do not replace a texture belonging to an unrelated atlas, even if its
    -- backing file happens to be present in the old Interface/Buttons list.
    if not atlas then file = replacements[TextureKey(texture)] end
    local tint = atlas and tintAtlases[atlas]
    if not file and not tint then return end
    -- Snapshot only values we actually change. Shared art metadata is built
    -- once, instead of retaining path/ID copies for every matching region.
    local record
    if file then
        record = {file = file}
        if atlas then
            local coords = PublicValues(region:GetTexCoord())
            if not coords then return end
            record.atlas, record.coords = atlas, coords
        else
            record.texture = texture
        end
    else
        local color = PublicValues(region:GetVertexColor())
        if not color then return end
        record = {atlas = atlas, color = color}
        if tint == "desaturate" then
            local value = region:GetDesaturation()
            if IsSecret(value) then return end
            record.desaturation = value
        end
    end
    records[region] = record
    -- Post-hooks persist for a region's lifetime. Numeric flags avoid an extra
    -- table per texture while allowing pooled textures to gain new roles.
    local flags = hooked[region] or 0
    if flags == 0 then
        hooksecurefunc(region, "SetTexture", SourceChanged)
        hooksecurefunc(region, "SetAtlas", SourceChanged)
        flags = 1
    end
    if record.coords and flags % 4 < 2 then
        hooksecurefunc(region, "SetTexCoord", CoordinatesChanged)
        flags = flags + 2
    end
    if record.color and flags % 8 < 4 then
        hooksecurefunc(region, "SetVertexColor", ColorChanged)
        flags = flags + 4
    end
    if record.desaturation ~= nil and flags < 8 then
        hooksecurefunc(region, "SetDesaturation", DesaturationChanged)
        hooksecurefunc(region, "SetDesaturated", DesaturationChanged)
        flags = flags + 8
    end
    hooked[region] = flags
    applying = true
    if file then
        region:SetTexture(file.path)
        if atlas then region:SetTexCoord(0, 1, 0, 1) end
    else
        region:SetVertexColor(.18, .18, .18, record.color[4])
        if record.desaturation ~= nil then region:SetDesaturation(1) end
    end
    applying = false
end

local function ApplyRegions(...)
    for index = 1, select("#", ...) do
        ApplyRegion(select(index, ...))
    end
end

local function ApplyButton(button)
    if not active or not CanTouch(button) or not button:IsObjectType("Button") then return end
    if InCombatLockdown() then DeferCombat(true); return end
    ApplyRegions(button:GetRegions())
end

-- Newly opened panels take priority. Background discovery remains bounded and
-- stops scheduling as soon as it finishes; opening a panel never requests it.
local QueueScan, ScheduleScan
local function GetScanState()
    if not scanState then
        scanState = {pending = {}, pendingSet = {}}
    end
    return scanState
end

local function QueueFrame(state, frame)
    if not CanTouch(frame) or state.pendingSet[frame] then return end
    state.pendingSet[frame] = true
    state.pending[#state.pending + 1] = frame
end

local function QueueChildren(state, ...)
    for index = 1, select("#", ...) do QueueFrame(state, select(index, ...)) end
end

local function ScanButtons(state)
    if scanState ~= state or not active then return end
    state.scheduled = false
    if InCombatLockdown() then DeferCombat(); return end
    state.running = true
    local started = GetTimePreciseSec()
    for _ = 1, 100 do
        local frame
        local count = #state.pending
        if count > 0 then
            frame = state.pending[count]
            state.pending[count] = nil
            state.pendingSet[frame] = nil
            if CanTouch(frame) and frame.GetChildren then
                -- Hidden children can become visible on a later tab switch.
                QueueChildren(state, frame:GetChildren())
            end
        elseif state.full then
            state.started = true
            frame = EnumerateFrames(state.cursor)
            if IsSecret(frame) or not frame then
                state.cursor, state.started = nil, false
                state.full, state.again = state.again, nil
                frame = nil
                if not state.full then break end
            else
                state.cursor = frame
            end
        else
            break
        end
        if frame then ApplyButton(frame) end
        if GetTimePreciseSec() - started >= .00075 then break end
    end
    state.running = false
    if #state.pending > 0 or state.full then
        ScheduleScan(state, .01)
    else
        scanState = nil
    end
end

ScheduleScan = function(state, delay)
    if state.scheduled then return end
    if InCombatLockdown() then DeferCombat(); return end
    state.scheduled = true
    local ticket = {}
    state.ticket = ticket
    C_Timer.After(delay or .1, function()
        if state.ticket == ticket then ScanButtons(state) end
    end)
end

QueueScan = function()
    if not active then return end
    local state = GetScanState()
    if state.started then state.again = true else state.full = true end
    ScheduleScan(state)
end

local function QueuePanel(frame)
    if not active or not CanTouch(frame) then return end
    local state = GetScanState()
    QueueFrame(state, frame)
    if state.running then return end
    -- Some callers select their tab after ShowUIPanel returns. Process this
    -- root on the next update, once those pooled buttons have been populated.
    -- Invalidate an older timer so there is still only one worker chain.
    state.ticket, state.scheduled = nil, false
    ScheduleScan(state, 0)
end

local panelHooks = {}
local panelTargets = {
    ShowUIPanel = QueuePanel,
    QuestMapFrame_Show = function() QueuePanel(_G.QuestMapFrame) end,
    QuestMapFrame_ShowQuestDetails = function()
        local frame = _G.QuestMapFrame
        if CanTouch(frame) then QueuePanel(frame.DetailsFrame or frame) end
    end,
}
local function InstallPanelHooks()
    for name, callback in pairs(panelTargets) do
        if not panelHooks[name] and type(_G[name]) == "function" then
            hooksecurefunc(name, callback)
            panelHooks[name] = true
        end
    end
end

local function HookAceGUI()
    if aceGUIHooked then return end
    local AceGUI = LibStub("AceGUI-3.0", true)
    if not AceGUI then return end
    aceGUIHooked = true
    hooksecurefunc(AceGUI, "RegisterAsWidget", function(_, widget)
        if not IsSecret(widget) and widget then ApplyButton(widget.frame) end
    end)
end

local function InstallHooks()
    if hooksInstalled then return end
    hooksInstalled = true
    for _, file in ipairs(files) do
        local path = "Interface\\Buttons\\" .. file
        local art = {path = PATH .. file .. ".blp"}
        art.pathKey = TextureKey(art.path)
        local id = GetFileIDFromPath and GetFileIDFromPath(art.path)
        if not IsSecret(id) and id and id ~= 0 then art.fileID = id end
        artwork[file] = art
        replacements[TextureKey(path)] = art
        replacements[TextureKey(path .. ".blp")] = art
        id = GetFileIDFromPath and GetFileIDFromPath(path .. ".blp")
        if not IsSecret(id) and id and id ~= 0 then replacements[id] = art end
    end
    for _, name in ipairs({"UIPanelButton_OnLoad", "UIPanelButton_OnShow"}) do
        if type(_G[name]) == "function" then hooksecurefunc(name, ApplyButton) end
    end
end

function module:RefreshDarkButtons()
    if not module:IsEnabled() or not module.db.profile.DarkButtons then
        module:StopDarkButtons()
        return
    end
    -- Managed-frame SetPoint hooks also call UI Elements:Refresh. Position
    -- updates must not restart button discovery when the option is unchanged.
    if active then return end
    active = true
    InstallHooks()
    -- Optional UI addons may have loaded while this feature was disabled.
    InstallPanelHooks()
    HookAceGUI()
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    QueueScan()
end

function module:StopDarkButtons()
    active = false
    -- Already queued callbacks compare this identity before touching frames.
    scanState = nil
    eventFrame:UnregisterEvent("ADDON_LOADED")
    eventFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
    RestoreArtwork()
end

eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_ENABLED" then
        self:UnregisterEvent(event)
        if not active then RestoreArtwork(); return end
        if scanState then
            ScheduleScan(scanState)
            return
        end
    elseif event == "ADDON_LOADED" and active then
        InstallPanelHooks()
        HookAceGUI()
    end
    QueueScan()
end)
