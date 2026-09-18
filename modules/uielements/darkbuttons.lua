-- Independently selectable artwork for the Escape menu and other buttons.
-- This file belongs to UI Elements; it never changes click handlers or icons.
local LUI = select(2, ...)
local module = LUI:GetModule("UI Elements")
local PATH = [[Interface\AddOns\LUI\media\buttons\]]
local replacements, artwork = {}, {classic = {}, hd = {}}
local records = setmetatable({}, {__mode = "k"})
local hooked = setmetatable({}, {__mode = "k"})
local active, applying, hooksInstalled = false, false, false
local buttonStyle, escapeButtonStyle, pendingRefresh
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
local sharedFamilies = {
    ["128-RedButton"] = true,
    ["128-GoldRedButton"] = true,
}
for family in pairs(sharedFamilies) do
    for _, suffix in ipairs({"", "-Disabled", "-Pressed"}) do
        tintAtlases[family .. "-Left" .. suffix] = "desaturate"
        tintAtlases[family .. "-Right" .. suffix] = "desaturate"
        tintAtlases["_" .. family .. "-Center" .. suffix] = "desaturate"
    end
    tintAtlases[family .. "-Highlight"] = "desaturate"
end
local sharedButtons = setmetatable({}, {__mode = "k"})
local legacyButtons = setmetatable({}, {__mode = "k"})
local customRegions = setmetatable({}, {__mode = "k"})

local function IsSecret(value)
    return issecretvalue and issecretvalue(value)
end

local function CanTouch(object)
    if IsSecret(object) or not object then return false end
    if object.IsForbidden and object:IsForbidden() then return false end
    -- Some enumerated addon frames reject native methods even though
    -- IsForbidden reports false. Treat a rejected type query as inaccessible;
    -- never continue discovery or install texture hooks on that object.
    if not object.IsObjectType then return false end
    local accessible = pcall(object.IsObjectType, object, "Region")
    return accessible
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

local function StyleForButton(button)
    -- Use ownership, not names: pooled menu buttons may have no global name.
    -- A bounded walk also includes child controls inside the menu.
    local frame = button
    for _ = 1, 32 do
        if not CanTouch(frame) then return "blizzard" end
        if frame == _G.GameMenuFrame then return escapeButtonStyle end
        if not frame.GetParent then break end
        frame = frame:GetParent()
        if not frame then break end
    end
    return buttonStyle
end

local function StyleForRegion(region)
    return StyleForButton(region:GetParent())
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

-- Menu and shared buttons use a rectangle drawn at their existing size.
-- Native gradient/solid textures keep the face and bevel sharp at any scale.
local sharedColors = {
    NORMAL = {bottom = CreateColor(.108, .108, .108, 1), top = CreateColor(.27, .27, .27, 1), edgeTop = .432, edgeBottom = .0315, edgeSide = .081},
    PUSHED = {bottom = CreateColor(.198, .198, .198, 1), top = CreateColor(.09, .09, .09, 1), edgeTop = .0315, edgeBottom = .252, edgeSide = .063},
    DISABLED = {bottom = CreateColor(.09, .09, .09, 1), top = CreateColor(.171, .171, .171, 1), edgeTop = .225, edgeBottom = .0405, edgeSide = .0675},
}

local function LayoutSharedButton(button, state)
    local width, height = button:GetSize()
    if IsSecret(width) or IsSecret(height) or width <= 2 or height <= 2 then return end
    local face, top, bottom, left, right = unpack(state.normal)
    face:ClearAllPoints()
    face:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
    face:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    top:ClearAllPoints()
    top:SetPoint("TOPLEFT", face, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", face, "TOPRIGHT", 0, 0)
    top:SetHeight(1)
    bottom:ClearAllPoints()
    bottom:SetPoint("BOTTOMLEFT", face, "BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", face, "BOTTOMRIGHT", 0, 0)
    bottom:SetHeight(1)
    left:ClearAllPoints()
    left:SetPoint("TOPLEFT", face, "TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", face, "BOTTOMLEFT", 0, 0)
    left:SetWidth(1)
    right:ClearAllPoints()
    right:SetPoint("TOPRIGHT", face, "TOPRIGHT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", face, "BOTTOMRIGHT", 0, 0)
    right:SetWidth(1)
    state.highlight[1]:SetAllPoints(face)
end

local function RestoreSharedButton(state)
    if not state then return end
    if state.saved then
        for _, original in ipairs(state.saved) do
            if CanTouch(original.texture) then original.texture:SetAlpha(original.alpha) end
        end
        state.saved = nil
    end
    for _, textures in ipairs({state.normal, state.highlight}) do
        for _, texture in ipairs(textures) do
            if CanTouch(texture) then texture:Hide() end
        end
    end
end

local function RestoreSharedButtons()
    for _, state in pairs(sharedButtons) do RestoreSharedButton(state) end
end

local ApplyButton, ApplySharedButton, RestoreRegion, SourceChanged
ApplySharedButton = function(button, buttonState)
    if not active or not CanTouch(button) then return false end
    local family = button.atlasName
    if IsSecret(family) or not family or not sharedFamilies[family] then return false end
    if InCombatLockdown() then DeferCombat(true); return true end
    if StyleForButton(button) ~= "hd" then
        RestoreSharedButton(sharedButtons[button])
        return false
    end
    if not CanTouch(button.Left) or not CanTouch(button.Center) or not CanTouch(button.Right) then return true end
    local highlight = button:GetHighlightTexture()
    if not CanTouch(highlight) then return true end
    local enabled = button:IsEnabled()
    buttonState = buttonState or button:GetButtonState()
    if IsSecret(enabled) or IsSecret(buttonState) then return true end
    if not enabled then buttonState = "DISABLED" end

    local state = sharedButtons[button]
    if not state then
        state = {normal = {}, highlight = {}}
        sharedButtons[button] = state
        for index = 1, 5 do
            local texture = button:CreateTexture(nil, "BACKGROUND", nil, index == 1 and 1 or 2)
            texture:SetColorTexture(1, 1, 1, 1)
            state.normal[index] = texture
        end
        local glow = button:CreateTexture(nil, "HIGHLIGHT")
        glow:SetColorTexture(.18, .30, .52, .35)
        glow:SetBlendMode("ADD")
        state.highlight[1] = glow
        hooksecurefunc(button, "UpdateButton", function(self, value) ApplyButton(self, value) end)
        hooksecurefunc(button, "UpdateScale", function(self)
            if not active or not state.saved or not CanTouch(self) then return end
            if InCombatLockdown() then DeferCombat(true); return end
            if StyleForButton(self) ~= "hd" then RestoreSharedButton(state); return end
            LayoutSharedButton(self, state)
        end)
    end
    if not state.saved then
        local saved = {}
        for _, texture in ipairs({button.Left, button.Center, button.Right, highlight}) do
            local alpha = texture:GetAlpha()
            if IsSecret(alpha) then return true end
            saved[#saved + 1] = {texture = texture, alpha = alpha}
        end
        state.saved = saved
    end
    for _, original in ipairs(state.saved) do original.texture:SetAlpha(0) end
    LayoutSharedButton(button, state)
    local colors = sharedColors[buttonState] or sharedColors.NORMAL
    local face, top, bottom, left, right = unpack(state.normal)
    face:SetGradient("VERTICAL", colors.bottom, colors.top)
    top:SetColorTexture(colors.edgeTop, colors.edgeTop, colors.edgeTop, 1)
    bottom:SetColorTexture(colors.edgeBottom, colors.edgeBottom, colors.edgeBottom, 1)
    left:SetColorTexture(colors.edgeSide, colors.edgeSide, colors.edgeSide, 1)
    right:SetColorTexture(colors.edgeSide, colors.edgeSide, colors.edgeSide, 1)
    for _, texture in ipairs(state.normal) do texture:Show() end
    state.highlight[1]:SetShown(buttonState ~= "DISABLED")
    return true
end

local buttonTextureGetters = {"GetNormalTexture", "GetPushedTexture", "GetDisabledTexture", "GetHighlightTexture"}
local panelFiles = {
    ["UI-Panel-Button-Up"] = true, ["UI-Panel-Button-Down"] = true,
    ["UI-Panel-Button-Disabled"] = true, ["UI-Panel-Button-Disabled-Down"] = true,
    ["UI-DialogBox-Button-Up"] = true, ["UI-DialogBox-Button-Down"] = true,
    ["UI-DialogBox-Button-Disabled"] = true,
}

local function LegacyButtonParts(button)
    local parts, seen, hasFace = {}, {}, false
    local function Add(region)
        if not CanTouch(region) or customRegions[region] or seen[region] then return end
        if region:GetObjectType() ~= "Texture" then return end
        local atlas, texture = region:GetAtlas(), region:GetTexture()
        if IsSecret(atlas) or IsSecret(texture) then return end
        local record = records[region]
        local file = record and record.file and record.file.name or (not atlas and replacements[TextureKey(texture)])
        if panelFiles[file] then hasFace = true end
        if panelFiles[file] or file == "UI-Panel-Button-Highlight" or file == "UI-DialogBox-Button-Highlight" then
            seen[region] = true
            parts[#parts + 1] = region
        end
    end
    local function AddRegions(...)
        for index = 1, select("#", ...) do Add(select(index, ...)) end
    end
    AddRegions(button:GetRegions())
    for _, getter in ipairs(buttonTextureGetters) do
        if button[getter] then Add(button[getter](button)) end
    end
    if not hasFace then return end
    local highlight = button:GetHighlightTexture()
    if CanTouch(highlight) and not seen[highlight] then parts[#parts + 1] = highlight end
    return parts
end

local function LayoutLegacyButton(button, state)
    local width, height = button:GetSize()
    if IsSecret(width) or IsSecret(height) or width <= 0 or height <= 0 then return false end
    local left, center, right = unpack(state.normal)
    local leftWidth = state.leftInfo.width * height / state.leftInfo.height
    local rightWidth = state.rightInfo.width * height / state.rightInfo.height
    local fullLeft, fullRight = leftWidth, rightWidth
    -- Preserve the native cap aspect ratios, cropping only when very narrow.
    if leftWidth + rightWidth > width then
        local extra = leftWidth + rightWidth - width
        if leftWidth - extra > rightWidth then leftWidth = leftWidth - extra
        elseif rightWidth - extra > leftWidth then rightWidth = rightWidth - extra
        else leftWidth, rightWidth = width / 2, width / 2 end
    end
    left:ClearAllPoints()
    left:SetPoint("TOPLEFT", button, "TOPLEFT")
    left:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT")
    left:SetWidth(leftWidth)
    left:SetTexCoord(0, leftWidth / fullLeft, 0, 1)
    right:ClearAllPoints()
    right:SetPoint("TOPRIGHT", button, "TOPRIGHT")
    right:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT")
    right:SetWidth(rightWidth)
    right:SetTexCoord(1 - rightWidth / fullRight, 1, 0, 1)
    center:ClearAllPoints()
    center:SetPoint("TOPLEFT", left, "TOPRIGHT")
    center:SetPoint("BOTTOMRIGHT", right, "BOTTOMLEFT")
    center:SetTexCoord(0, 1, 0, 1)
    state.highlight[1]:SetAllPoints(button)
    return true
end

local function ApplyLegacyDarkButton(button, buttonState)
    local state = legacyButtons[button]
    if StyleForButton(button) ~= "dark" then
        RestoreSharedButton(state)
        return false
    end
    local parts = LegacyButtonParts(button)
    if not parts then RestoreSharedButton(state); return false end
    local enabled = button:IsEnabled()
    buttonState = buttonState or button:GetButtonState()
    if IsSecret(enabled) or IsSecret(buttonState) then return true end
    if not enabled then buttonState = "DISABLED" end
    if not state then
        if not C_Texture or not C_Texture.GetAtlasInfo then return false end
        local leftInfo = C_Texture.GetAtlasInfo("128-RedButton-Left")
        local rightInfo = C_Texture.GetAtlasInfo("128-RedButton-Right")
        if not leftInfo or not rightInfo then return false end
        state = {normal = {}, highlight = {}, leftInfo = leftInfo, rightInfo = rightInfo}
        legacyButtons[button] = state
        for index = 1, 3 do
            local texture = button:CreateTexture(nil, "BACKGROUND", nil, 1)
            customRegions[texture] = true
            state.normal[index] = texture
        end
        local highlight = button:CreateTexture(nil, "HIGHLIGHT")
        customRegions[highlight] = true
        highlight:SetBlendMode("ADD")
        state.highlight[1] = highlight
        local function Update(self) ApplyButton(self) end
        for _, script in ipairs({"OnShow", "OnEnable", "OnDisable", "OnSizeChanged"}) do
            button:HookScript(script, Update)
        end
        button:HookScript("OnMouseDown", function(self) ApplyButton(self, "PUSHED") end)
        button:HookScript("OnMouseUp", function(self) ApplyButton(self, "NORMAL") end)
        if button.SetButtonState then hooksecurefunc(button, "SetButtonState", function(self, value) ApplyButton(self, value) end) end
    end
    RestoreSharedButton(state)
    local suffix = buttonState == "DISABLED" and "-Disabled" or buttonState == "PUSHED" and "-Pressed" or ""
    for index, atlas in ipairs({"128-RedButton-Left", "_128-RedButton-Center", "128-RedButton-Right"}) do
        local texture = state.normal[index]
        texture:SetAtlas(atlas .. suffix)
        texture:SetHorizTile(index == 2)
        texture:SetVertTile(false)
        texture:SetDesaturation(1)
        texture:SetVertexColor(1, 1, 1, 1)
    end
    state.highlight[1]:SetAtlas("128-RedButton-Highlight")
    state.highlight[1]:SetDesaturation(1)
    state.highlight[1]:SetVertexColor(1, 1, 1, 1)
    if not LayoutLegacyButton(button, state) then return true end
    local saved = {}
    for _, texture in ipairs(parts) do
        if records[texture] then RestoreRegion(texture, records[texture]); records[texture] = nil end
        local alpha = texture:GetAlpha()
        if IsSecret(alpha) then return true end
        saved[#saved + 1] = {texture = texture, alpha = alpha}
        if not hooked[texture] then
            hooksecurefunc(texture, "SetTexture", SourceChanged)
            hooksecurefunc(texture, "SetAtlas", SourceChanged)
            hooked[texture] = 1
        end
    end
    state.saved = saved
    for _, original in ipairs(saved) do original.texture:SetAlpha(0) end
    for _, texture in ipairs(state.normal) do texture:Show() end
    state.highlight[1]:SetShown(buttonState ~= "DISABLED")
    return true
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
    if record.atlas then return atlas == record.atlas end
    return not atlas and TextureKey(texture) == TextureKey(record.texture)
end

RestoreRegion = function(region, record)
    if not CanTouch(region) or (record.file and not OwnsArtwork(region, record)) then return end
    applying = true
    if record.file then
        if record.atlas then
            region:SetAtlas(record.atlas)
        else
            region:SetTexture(record.texture)
        end
        if record.coords then region:SetTexCoord(unpack(record.coords)) end
    else
        -- Tint survives source changes. Restore it even if the native file
        -- changed while a combat-delayed disable was pending.
        region:SetVertexColor(unpack(record.color))
        if record.desaturation ~= nil then region:SetDesaturation(record.desaturation) end
    end
    applying = false
end

local function RestoreArtwork()
    if InCombatLockdown() then DeferCombat(); return end
    RestoreSharedButtons()
    for _, state in pairs(legacyButtons) do RestoreSharedButton(state) end
    if not next(records) then return end
    for region, record in pairs(records) do
        RestoreRegion(region, record)
    end
    -- Release the old hash capacity after a complete restore.
    records = setmetatable({}, {__mode = "k"})
end

local ApplyRegion
SourceChanged = function(region)
    if applying then return end
    if not active then
        -- A native setter has replaced our art while a combat-delayed restore
        -- was pending; it must not be overwritten with an obsolete snapshot.
        local record = records[region]
        if record and record.file and CanTouch(region) and not OwnsArtwork(region, record) then
            records[region] = nil
        end
        return
    end
    local parent = CanTouch(region) and region:GetParent()
    if CanTouch(parent) and legacyButtons[parent] then ApplyButton(parent); return end
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
    if StyleForRegion(region) ~= record.style then ApplyRegion(region); return end
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
    if StyleForRegion(region) ~= record.style then ApplyRegion(region); return end
    applying = true
    region:SetVertexColor(record.tint, record.tint, record.tint, color[4])
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
    if StyleForRegion(region) ~= record.style then ApplyRegion(region); return end
    applying = true
    region:SetDesaturation(1)
    applying = false
end

ApplyRegion = function(region)
    if applying or not active or not CanTouch(region) or customRegions[region] then return end
    if InCombatLockdown() then DeferCombat(true); return end
    if region:GetObjectType() ~= "Texture" then return end
    local atlas, texture = region:GetAtlas(), region:GetTexture()
    if IsSecret(atlas) or IsSecret(texture) then return end
    local style = StyleForRegion(region)
    local previous = records[region]
    if previous and previous.style ~= style then
        RestoreRegion(region, previous)
        records[region], previous = nil, nil
        atlas, texture = region:GetAtlas(), region:GetTexture()
        if IsSecret(atlas) or IsSecret(texture) then return end
    end
    if style == "blizzard" then return end
    if previous and OwnsArtwork(region, previous) then
        -- Reconcile native changes made during combat without replacing the
        -- original source we need when this option/module is disabled.
        applying = true
        if previous.file and previous.atlas then
            region:SetTexCoord(0, 1, 0, 1)
        elseif not previous.file then
            region:SetVertexColor(previous.tint, previous.tint, previous.tint, previous.color[4])
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

    local artSet = artwork[style == "hd" and "hd" or "classic"]
    local file = atlas and artSet[atlases[atlas]]
    if atlas == "checkbox-minimal" then
        local parent = region:GetParent()
        if CanTouch(parent) and parent:IsObjectType("Button") then
            if region == parent:GetHighlightTexture() then file = artSet["UI-CheckBox-Highlight"]
            elseif region == parent:GetPushedTexture() then file = artSet["UI-CheckBox-Down"] end
        end
    end
    -- Do not replace a texture belonging to an unrelated atlas, even if its
    -- backing file happens to be present in the old Interface/Buttons list.
    if not atlas then file = artSet[replacements[TextureKey(texture)]] end
    local tint = atlas and tintAtlases[atlas]
    if style == "dark" and file then
        -- Keep native shapes, detail and UVs for Blizzard Dark, including
        -- older file-based buttons; only remove their original color.
        file, tint = nil, "desaturate"
    end
    -- HD shared buttons draw their own face; native slices stay untouched.
    if style == "hd" and tint == "desaturate" then return end
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
        record = {atlas = atlas, texture = texture, color = color, tint = tint == "desaturate" and 1 or .18}
        if tint == "desaturate" then
            local value = region:GetDesaturation()
            if IsSecret(value) then return end
            record.desaturation = value
        end
    end
    record.style = style
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
        region:SetVertexColor(record.tint, record.tint, record.tint, record.color[4])
        if record.desaturation ~= nil then region:SetDesaturation(1) end
    end
    applying = false
end

local function ApplyRegions(...)
    for index = 1, select("#", ...) do
        ApplyRegion(select(index, ...))
    end
end

ApplyButton = function(button, buttonState)
    if not active or not CanTouch(button) or not button:IsObjectType("Button") then return end
    if InCombatLockdown() then DeferCombat(true); return end
    if ApplySharedButton(button, buttonState) then return end
    if ApplyLegacyDarkButton(button, buttonState) then return end
    ApplyRegions(button:GetRegions())
    -- Button state textures are not consistently included in GetRegions.
    for _, getter in ipairs(buttonTextureGetters) do
        if button[getter] then ApplyRegion(button[getter](button)) end
    end
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
    StaticPopup_OnShow = QueuePanel,
    StaticPopupSpecial_Show = QueuePanel,
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
        for _, style in ipairs({"classic", "hd"}) do
            local art = {name = file, path = PATH .. (style == "hd" and "hd\\" .. file .. ".tga" or file .. ".blp")}
            art.pathKey = TextureKey(art.path)
            local id = GetFileIDFromPath and GetFileIDFromPath(art.path)
            if not IsSecret(id) and id and id ~= 0 then art.fileID = id end
            artwork[style][file] = art
        end
        replacements[TextureKey(path)] = file
        replacements[TextureKey(path .. ".blp")] = file
        local id = GetFileIDFromPath and GetFileIDFromPath(path .. ".blp")
        if not IsSecret(id) and id and id ~= 0 then replacements[id] = file end
        id = GetFileIDFromPath and GetFileIDFromPath(path)
        if not IsSecret(id) and id and id ~= 0 then replacements[id] = file end
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
    local profile = module.db.profile
    local nextButton = profile.ButtonStyle
    local nextEscape = profile.EscapeButtonStyle
    if nextButton ~= "blizzard" and nextButton ~= "dark" and nextButton ~= "hd" then nextButton = "classic" end
    if nextEscape ~= "blizzard" and nextEscape ~= "hd" then nextEscape = "dark" end
    if nextButton == "blizzard" and nextEscape == "blizzard" then
        module:StopDarkButtons()
        return
    end
    -- Managed-frame SetPoint hooks also call UI Elements:Refresh. Position
    -- updates must not restart button discovery when the option is unchanged.
    if active and buttonStyle == nextButton and escapeButtonStyle == nextEscape then
        pendingRefresh = nil
        return
    end
    if InCombatLockdown() then
        pendingRefresh = true
        DeferCombat()
        return
    end
    pendingRefresh = nil
    active, scanState = false, nil
    RestoreArtwork()
    buttonStyle, escapeButtonStyle = nextButton, nextEscape
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
    active, pendingRefresh = false, nil
    -- Already queued callbacks compare this identity before touching frames.
    scanState = nil
    eventFrame:UnregisterEvent("ADDON_LOADED")
    eventFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
    RestoreArtwork()
end

eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_ENABLED" then
        self:UnregisterEvent(event)
        if pendingRefresh then module:RefreshDarkButtons(); return end
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
