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
local cosmeticOwners = setmetatable({}, {__mode = "k"})
local showHooks = setmetatable({}, {__mode = "k"})
local preparedPanels = setmetatable({}, {__mode = "k"})
local knownButtons = setmetatable({}, {__mode = "k"})
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
    ["RedButton-Highlight"] = "UI-Panel-MinimizeButton-Highlight",
    ["checkbox-minimal"] = "UI-CheckBox-Up",
}
local ACTION_BORDER = "UI-HUD-ActionBar-IconFrame"
local tintAtlases = {[ACTION_BORDER] = "tint"}
-- Window size controls retain their arrow glyphs in every custom style.
-- These are separate from the three-slice button faces replaced by LUI HD.
for _, atlas in ipairs({"RedButton-Expand", "RedButton-Expand-Pressed", "RedButton-Expand-Disabled",
    "RedButton-Condense", "RedButton-Condense-Pressed", "RedButton-Condense-disabled",
    "RedButton-MiniCondense", "RedButton-MiniCondense-pressed", "RedButton-MiniCondense-disabled"}) do
    tintAtlases[atlas] = "window-icon"
end
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

local restrictionQueries = {
    "HasAnySecretAspect", "HasAnyForbiddenAspects", "HasAccessConstraints", "IsForbidden",
}

local function CanTouch(object)
    if IsSecret(object) or not object then return false end
    -- Aura buttons can be neither forbidden nor protected while their secret
    -- visibility still disallows OnShow hooks. Exclude restricted objects
    -- before discovery, styling or restoration, including their descendants.
    -- Recheck on every call: pooled objects can acquire restrictions later.
    for _, name in ipairs(restrictionQueries) do
        local query = object[name]
        if query then
            local ok, restricted = pcall(query, object)
            if not ok or IsSecret(restricted) or restricted ~= false then return false end
        end
    end
    -- Some enumerated addon frames reject native methods even though
    -- IsForbidden reports false. Treat a rejected type query as inaccessible;
    -- never continue discovery or install texture hooks on that object.
    if not object.IsObjectType then return false end
    local accessible, isRegion = pcall(object.IsObjectType, object, "Region")
    return accessible and not IsSecret(isRegion)
end

-- Cosmetic discovery must not install hooks on secure action controls or
-- their textures, including unnamed children. Check ownership on every call
-- because pooled regions can be reparented after their first scan.
local function CanStyle(object)
    for _ = 1, 32 do
        if not CanTouch(object) then return false end
        if object == UIParent then return true end
        if object.IsProtected and object:IsProtected() then return false end
        -- Explicitly registered menu controls can have a protected window
        -- above them. Check the control itself before allowing its artwork.
        -- Other children (talents, spells, tabs and action buttons) keep
        -- the full guard.
        local owner = cosmeticOwners[object]
        if owner and object.GetParent and object:GetParent() == owner then return true end
        if not object.GetParent then return false end
        object = object:GetParent()
        if IsSecret(object) then return false end
        if not object then return true end
    end
    return false
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
-- Use the same final RGB values as Canvas.face in generate_hd_buttons.py
-- (including its 0.90 material brightness), not a separate gray palette.
local function HDColor(red, green, blue)
    return CreateColor(red / 255, green / 255, blue / 255, 1)
end
local function HDTextureColor(red, green, blue)
    return {red / 255, green / 255, blue / 255, 1}
end
local sharedColors = {
    NORMAL = {bottom = HDColor(27, 29, 29), top = HDColor(69, 72, 71),
        edgeTop = HDTextureColor(89, 92, 88), edgeBottom = HDTextureColor(12, 13, 13)},
    PUSHED = {bottom = HDColor(43, 45, 45), top = HDColor(28, 30, 30),
        edgeTop = HDTextureColor(11, 12, 12), edgeBottom = HDTextureColor(89, 92, 88)},
    DISABLED = {bottom = HDColor(29, 31, 30), top = HDColor(40, 41, 40),
        edgeTop = HDTextureColor(57, 59, 57), edgeBottom = HDTextureColor(12, 13, 13)},
}
local sharedEdgeLeft = HDTextureColor(42, 45, 43)
local sharedEdgeRight = HDTextureColor(15, 16, 16)

local function LayoutSharedButton(button, state)
    local width, height = button:GetSize()
    if IsSecret(width) or IsSecret(height) or width <= 2 or height <= 2 then return false end
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
    return true
end

local function RestoreSharedButton(state)
    if not state then return end
    if state.saved then
        for _, original in ipairs(state.saved) do
            if CanStyle(original.texture) then original.texture:SetAlpha(original.alpha) end
        end
        state.saved = nil
    end
    for _, textures in ipairs({state.normal, state.highlight}) do
        for _, texture in ipairs(textures) do
            if CanStyle(texture) then texture:Hide() end
        end
    end
end

local function RestoreSharedButtons()
    for _, state in pairs(sharedButtons) do RestoreSharedButton(state) end
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
        if not CanStyle(region) or region:GetParent() ~= button or customRegions[region] or seen[region] then return end
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
    if CanStyle(highlight) and highlight:GetParent() == button and not seen[highlight] then
        parts[#parts + 1] = highlight
    end
    return parts
end

local ApplyButton, ApplySharedButton, RestoreRegion, SourceChanged
local QueuePanel
ApplySharedButton = function(button, buttonState)
    if not active or not CanStyle(button) then return false end
    local family = button.atlasName
    if IsSecret(family) then return false end
    local modern = family and sharedFamilies[family]
    local parts = not modern and LegacyButtonParts(button)
    if not modern and not parts then
        RestoreSharedButton(sharedButtons[button])
        return false
    end
    if InCombatLockdown() then DeferCombat(true); return true end
    if StyleForButton(button) ~= "hd" then
        RestoreSharedButton(sharedButtons[button])
        return false
    end
    if modern then
        if not CanTouch(button.Left) or not CanTouch(button.Center) or not CanTouch(button.Right) then return true end
        local highlight = button:GetHighlightTexture()
        if not CanTouch(highlight) then return true end
        parts = {button.Left, button.Center, button.Right, highlight}
    end
    for _, texture in ipairs(parts) do
        if not CanStyle(texture) or texture:GetParent() ~= button then return true end
    end
    local enabled = button:IsEnabled()
    buttonState = buttonState or button:GetButtonState()
    if IsSecret(enabled) or IsSecret(buttonState) then return true end
    if not enabled then buttonState = "DISABLED" end

    local state = sharedButtons[button]
    if not state then
        state = {normal = {}, highlight = {}}
        sharedButtons[button] = state
        for index = 1, 5 do
            -- Bottom-row buttons can share a level with panel border art.
            -- Keep the face above that art and below the button's text.
            local texture = button:CreateTexture(nil, "ARTWORK", nil, index == 1 and -2 or -1)
            customRegions[texture] = true
            texture:SetColorTexture(1, 1, 1, 1)
            texture:Hide()
            state.normal[index] = texture
        end
        local glow = button:CreateTexture(nil, "HIGHLIGHT")
        customRegions[glow] = true
        glow:SetColorTexture(.18, .30, .52, .35)
        glow:SetBlendMode("ADD")
        glow:Hide()
        state.highlight[1] = glow
        if modern then
            hooksecurefunc(button, "UpdateButton", function(self, value) ApplyButton(self, value) end)
            hooksecurefunc(button, "UpdateScale", function(self) ApplyButton(self) end)
        else
            button:HookScript("OnMouseDown", function(self) ApplyButton(self, "PUSHED") end)
            button:HookScript("OnMouseUp", function(self) ApplyButton(self, "NORMAL") end)
            if button.SetButtonState then
                hooksecurefunc(button, "SetButtonState", function(self, value) ApplyButton(self, value) end)
            end
        end
        for _, script in ipairs({"OnSizeChanged", "OnEnable", "OnDisable"}) do
            button:HookScript(script, function(self) ApplyButton(self) end)
        end
    end
    -- Never hide the native face until its replacement has valid anchors.
    -- A hidden or newly constructed button can acquire its size later.
    if not LayoutSharedButton(button, state) then
        RestoreSharedButton(state)
        return true
    end
    if not state.saved then
        local saved = {}
        for _, texture in ipairs(parts) do
            local alpha = texture:GetAlpha()
            if IsSecret(alpha) then return true end
            saved[#saved + 1] = {texture = texture, alpha = alpha}
            if not modern and not hooked[texture] then
                hooksecurefunc(texture, "SetTexture", SourceChanged)
                hooksecurefunc(texture, "SetAtlas", SourceChanged)
                hooked[texture] = 1
            end
        end
        state.saved = saved
    end
    for _, original in ipairs(state.saved) do
        if not CanStyle(original.texture) or original.texture:GetParent() ~= button then
            RestoreSharedButton(state)
            return true
        end
    end
    for _, original in ipairs(state.saved) do original.texture:SetAlpha(0) end
    local colors = sharedColors[buttonState] or sharedColors.NORMAL
    local face, top, bottom, left, right = unpack(state.normal)
    face:SetGradient("VERTICAL", colors.bottom, colors.top)
    top:SetColorTexture(unpack(colors.edgeTop))
    bottom:SetColorTexture(unpack(colors.edgeBottom))
    left:SetColorTexture(unpack(sharedEdgeLeft))
    right:SetColorTexture(unpack(sharedEdgeRight))
    for _, texture in ipairs(state.normal) do texture:Show() end
    state.highlight[1]:SetShown(buttonState ~= "DISABLED")
    return true
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
    left:SetTexCoord(0, leftWidth / fullLeft * (state.classic and .09375 or 1), 0, state.classic and .6875 or 1)
    right:ClearAllPoints()
    right:SetPoint("TOPRIGHT", button, "TOPRIGHT")
    right:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT")
    right:SetWidth(rightWidth)
    if state.classic then
        right:SetTexCoord(.625 - rightWidth / fullRight * .09375, .625, 0, .6875)
    else
        right:SetTexCoord(1 - rightWidth / fullRight, 1, 0, 1)
    end
    center:ClearAllPoints()
    center:SetPoint("TOPLEFT", left, "TOPRIGHT")
    center:SetPoint("BOTTOMRIGHT", right, "BOTTOMLEFT")
    if state.classic then center:SetTexCoord(.09375, .53125, 0, .6875)
    else center:SetTexCoord(0, 1, 0, 1) end
    state.highlight[1]:SetAllPoints(button)
    return true
end

local function ApplySlicedButton(button, buttonState)
    local state = legacyButtons[button]
    local style = StyleForButton(button)
    local family = button.atlasName
    if IsSecret(family) then return false end
    local classic = style == "classic" and family and sharedFamilies[family] or false
    if style ~= "dark" and not classic then
        RestoreSharedButton(state)
        return false
    end
    -- Modern atlas buttons need the same classic BLP slices as older panel
    -- buttons; simply desaturating their atlases is the Blizzard Dark style.
    local parts
    if classic then
        local highlight = button:GetHighlightTexture()
        for _, key in ipairs({"Left", "Center", "Right"}) do
            if not CanStyle(button[key]) or button[key]:GetParent() ~= button then return true end
        end
        if not CanStyle(highlight) or highlight:GetParent() ~= button then return true end
        parts = {button.Left, button.Center, button.Right, highlight}
    else
        parts = LegacyButtonParts(button)
    end
    if not parts then RestoreSharedButton(state); return false end
    local enabled = button:IsEnabled()
    buttonState = buttonState or button:GetButtonState()
    if IsSecret(enabled) or IsSecret(buttonState) then return true end
    if not enabled then buttonState = "DISABLED" end
    if not state or state.classic ~= classic then
        local leftInfo, rightInfo
        if classic then
            leftInfo, rightInfo = {width = 12, height = 22}, {width = 12, height = 22}
        else
            if not C_Texture or not C_Texture.GetAtlasInfo then return false end
            leftInfo = C_Texture.GetAtlasInfo("128-RedButton-Left")
            rightInfo = C_Texture.GetAtlasInfo("128-RedButton-Right")
        end
        if not leftInfo or not rightInfo then return false end
        state = state or {normal = {}, highlight = {}}
        state.leftInfo, state.rightInfo, state.classic = leftInfo, rightInfo, classic
    end
    if not legacyButtons[button] then
        legacyButtons[button] = state
        for index = 1, 3 do
            local texture = button:CreateTexture(nil, "ARTWORK", nil, -2)
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
        if button.UpdateButton then hooksecurefunc(button, "UpdateButton", function(self, value) ApplyButton(self, value) end) end
    end
    RestoreSharedButton(state)
    local suffix = buttonState == "DISABLED" and "-Disabled" or buttonState == "PUSHED" and "-Pressed" or ""
    local classicFile = "UI-Panel-Button-" .. (buttonState == "DISABLED" and "Disabled" or buttonState == "PUSHED" and "Down" or "Up")
    for index, atlas in ipairs({"128-RedButton-Left", "_128-RedButton-Center", "128-RedButton-Right"}) do
        local texture = state.normal[index]
        if classic then texture:SetTexture(artwork.classic[classicFile].path)
        else texture:SetAtlas(atlas .. suffix) end
        texture:SetHorizTile(not classic and index == 2)
        texture:SetVertTile(false)
        texture:SetDesaturation(classic and 0 or 1)
        texture:SetVertexColor(1, 1, 1, 1)
    end
    if classic then
        state.highlight[1]:SetTexture(artwork.classic["UI-Panel-Button-Highlight"].path)
        state.highlight[1]:SetTexCoord(0, .625, 0, .6875)
    else
        state.highlight[1]:SetAtlas("128-RedButton-Highlight")
        state.highlight[1]:SetTexCoord(0, 1, 0, 1)
    end
    state.highlight[1]:SetDesaturation(classic and 0 or 1)
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
    if not CanStyle(region) or (record.file and not OwnsArtwork(region, record)) then return end
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
    if CanTouch(parent) and (legacyButtons[parent] or sharedButtons[parent]) then ApplyButton(parent); return end
    ApplyRegion(region)
end

local function CoordinatesChanged(region, ...)
    if applying or not CanStyle(region) then return end
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
    if applying or not CanStyle(region) then return end
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
    if applying or not CanStyle(region) or IsSecret(value) then return end
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
    if applying or not active or not CanStyle(region) or customRegions[region] then return end
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
        local gray = tint == "desaturate" and 1 or tint == "window-icon" and .65 or .18
        record = {atlas = atlas, texture = texture, color = color, tint = gray}
        if tint == "desaturate" or tint == "window-icon" then
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
    if not active or not CanStyle(button) or not button:IsObjectType("Button") then return end
    if InCombatLockdown() then DeferCombat(true); return end
    knownButtons[button] = true
    if not showHooks[button] then
        local success = button:HookScript("OnShow", function(self) ApplyButton(self) end)
        if success ~= false then showHooks[button] = true end
    end
    if ApplySharedButton(button, buttonState) then return end
    if ApplySlicedButton(button, buttonState) then return end
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

-- Known native window close buttons may sit below a protected window. Only
-- the verified close branch is allowed; the window's action/talent children
-- still fail CanStyle. Some templates expose a global name, not a parent key.
local panelNames = {
    "GameMenuFrame", "PlayerSpellsFrame", "SpellBookFrame", "CharacterFrame",
    "CollectionsJournal", "EncounterJournal", "AchievementFrame", "FriendsFrame",
    "CommunitiesFrame", "GuildFrame", "PVEFrame", "PVPUIFrame", "ProfessionsFrame",
    "ProfessionsBookFrame", "QuestFrame", "GossipFrame", "MerchantFrame", "MailFrame",
    "AuctionHouseFrame", "BankFrame", "ItemTextFrame", "WorldMapFrame", "SettingsPanel",
    "LUIBags", "LegacySystemFrame", "ReadyCheckFrame", "ReadyCheckListenerFrame",
}

local function RegisterCloseButton(frame, name)
    if not CanTouch(frame) then return end
    local close = frame.CloseButton or (name == "LUIBags" and frame.closeButton)
        or (name and _G[name .. "CloseButton"])
    if CanTouch(close) and close.GetParent and close:GetParent() == frame then
        cosmeticOwners[close] = frame
        ApplyButton(close)
    end
end

-- Bags creates an unnamed close button and can become protected through its
-- item controls. Register this exact LUI-owned leaf at construction time;
-- never relax the guard for the inventory or its item slots.
function module:RegisterBagCloseButton(frame, button)
    if frame ~= _G.LUIBags or not CanTouch(frame) or frame.closeButton ~= button then return end
    if not CanTouch(button) or button:GetParent() ~= frame then return end
    cosmeticOwners[button] = frame
    ApplyButton(button)
end

local function RegisterCosmeticButton(parent, button)
    if not CanTouch(parent) or not CanTouch(button) or button:GetParent() ~= parent then return end
    cosmeticOwners[button] = parent
    ApplyButton(button)
end

-- Register only the two native response controls, including while hidden so
-- their artwork is ready before the first ready check. Keep native OnClick
-- handlers intact; all restrictions on the buttons/textures still apply.
local function PrepareReadyCheckButtons()
    if not active then return end
    local root = _G.ReadyCheckFrame
    if not CanTouch(root) then return end
    local parent = _G.ReadyCheckListenerFrame
    if parent then
        if not CanTouch(parent) or parent:GetParent() ~= root then return end
    else
        parent = root
    end
    RegisterCosmeticButton(parent, _G.ReadyCheckFrameYesButton)
    RegisterCosmeticButton(parent, _G.ReadyCheckFrameNoButton)
end

local function PreparePlayerSpellsControls()
    if not active then return end
    local frame = _G.PlayerSpellsFrame
    if not CanTouch(frame) then return end
    local sizeControls = frame.MaximizeMinimizeButton
    if CanTouch(sizeControls) and sizeControls:GetParent() == frame then
        RegisterCosmeticButton(sizeControls, sizeControls.MaximizeButton)
        RegisterCosmeticButton(sizeControls, sizeControls.MinimizeButton)
    end
    local talents = frame.TalentsFrame
    if CanTouch(talents) and talents:GetParent() == frame then
        RegisterCosmeticButton(talents, talents.ApplyButton)
        RegisterCosmeticButton(talents, talents.InspectCopyButton)
    end
    local spec = frame.SpecFrame
    if not CanTouch(spec) or spec:GetParent() ~= frame then return end
    local pool = spec.SpecContentFramePool
    if IsSecret(pool) or not pool or type(pool.EnumerateActive) ~= "function" then return end
    for content in pool:EnumerateActive() do
        if CanTouch(content) and content:GetParent() == spec then
            RegisterCosmeticButton(content, content.ActivateButton)
        end
    end
end

local playerSpellsEventsInstalled = false
local function InstallPlayerSpellsEvents()
    if playerSpellsEventsInstalled or not _G.EventRegistry then return end
    playerSpellsEventsInstalled = true
    -- Observe Blizzard's completed opening/tab transition. Do not invoke or
    -- replace any native click, talent update, selection or action-bar code.
    for _, event in ipairs({"PlayerSpellsFrame.OpenFrame", "PlayerSpellsFrame.TabSet",
        "PlayerSpellsFrame.SpecFrame.Show"}) do
        _G.EventRegistry:RegisterCallback(event, PreparePlayerSpellsControls, eventFrame)
    end
end

QueuePanel = function(frame)
    if not active or not CanTouch(frame) then return end
    if InCombatLockdown() then QueueFrame(GetScanState(), frame); DeferCombat(true); return end
    -- Deal with the close control even when the rest of this root is secure.
    for _, name in ipairs(panelNames) do
        if frame == _G[name] then RegisterCloseButton(frame, name); break end
    end
    if frame == _G.PlayerSpellsFrame then PreparePlayerSpellsControls() end
    if not CanStyle(frame) then return end
    local state = GetScanState()
    -- Apply the visible branch during the opening call, before it is painted.
    -- Never perform a synchronous scan of every frame in the UI. Very large
    -- trees spill into the existing bounded worker; hidden branches get an
    -- OnShow hook so they are styled when a tab first makes them visible.
    local pending, seen = {frame}, {}
    local started = GetTimePreciseSec()
    for _ = 1, 256 do
        local object = table.remove(pending)
        if not object then break end
        if not seen[object] and CanStyle(object) then
            seen[object] = true
            if object:IsObjectType("Button") then
                ApplyButton(object)
            elseif object.HookScript and not showHooks[object] then
                local success = object:HookScript("OnShow", function(self) QueuePanel(self) end)
                if success ~= false then showHooks[object] = true end
            end
            if object.GetChildren and (object == frame or not object.IsShown or object:IsShown()) then
                for _, child in ipairs({object:GetChildren()}) do pending[#pending + 1] = child end
            end
        end
        if GetTimePreciseSec() - started >= .002 then break end
    end
    for _, object in ipairs(pending) do QueueFrame(state, object) end
    -- Also discover controls populated by the native caller after ShowUIPanel.
    QueueFrame(state, frame)
    if state.running then return end
    state.ticket, state.scheduled = nil, false
    ScheduleScan(state, 0)
end


local function PrepareKnownPanels(force)
    PrepareReadyCheckButtons()
    for _, name in ipairs(panelNames) do
        local frame = _G[name]
        if CanTouch(frame) and (force or not preparedPanels[frame]) then
            preparedPanels[frame] = true
            RegisterCloseButton(frame, name)
            QueuePanel(frame)
        end
    end
    PreparePlayerSpellsControls()
end

local panelHooks = {}
local panelTargets = {
    ShowReadyCheck = function()
        PrepareReadyCheckButtons()
        QueuePanel(_G.ReadyCheckListenerFrame or _G.ReadyCheckFrame)
    end,
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
    InstallPlayerSpellsEvents()
    -- A style selection must repaint known visible controls in this call.
    -- Do not make the user wait for a fresh EnumerateFrames pass. Hidden
    -- controls already have OnShow hooks and can be reconciled lazily.
    for button in pairs(knownButtons) do
        if CanTouch(button) and button.IsVisible and button:IsVisible() then ApplyButton(button) end
    end
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    PrepareKnownPanels(true)
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
        PreparePlayerSpellsControls()
        PrepareReadyCheckButtons()
        if scanState then
            ScheduleScan(scanState)
            return
        end
    elseif event == "ADDON_LOADED" and active then
        InstallPanelHooks()
        HookAceGUI()
        InstallPlayerSpellsEvents()
        PrepareKnownPanels()
    end
    QueueScan()
end)
