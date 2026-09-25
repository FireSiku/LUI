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
local deferredReconcile
local combatQueued = false
local deferredObjects = setmetatable({}, {__mode = "k"})
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
-- Trading Post icon buttons keep their cart/delete/rotation glyphs. These
-- native atlas faces need tinting rather than a rectangular replacement.
for _, family in ipairs({"128-RedButton-ShoppingCart", "128-RedButton-Delete"}) do
    for _, suffix in ipairs({"", "-Pressed", "-Disabled", "-Highlight"}) do
        tintAtlases[family .. suffix] = "window-icon"
    end
end
tintAtlases["perks-button-up"] = "window-icon"
tintAtlases["perks-button-down"] = "window-icon"
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
-- Both LUI close-button resolutions use the same transparent margins.
-- The calendar's native cut-out needs the full button face inside its box.
local calendarCloseCoords = {6 / 32, 25 / 32, 7 / 32, 25 / 32}

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
        -- Inventory/equipment slots own their appearance (LUI Bags also draws
        -- its own borders). Never install generic button/texture hooks on
        -- these slots or their descendants: showing a full bag would run the
        -- cosmetic callbacks again for every icon, overlay and cooldown.
        local isItemButton = object:IsObjectType("ItemButton")
        if IsSecret(isItemButton) or isItemButton then return false end
        if object == UIParent then return true end
        if object.IsProtected and object:IsProtected() then return false end
        -- Explicitly registered menu controls can have a protected window
        -- above them. Check the control itself before allowing its artwork.
        -- Other children (talents, spells, tabs and action buttons) keep
        -- the full guard.
        local owner = cosmeticOwners[object]
        if owner and object.GetParent and object:GetParent() == owner then return true end
        -- Exclude the complete LUI bag tree, not just objects identifying as
        -- ItemButton. Plain overlay buttons, cooldown frames and bag parents
        -- can otherwise acquire their own OnShow discovery/styling hooks.
        -- The explicitly registered close button above remains supported.
        if object == _G.LUIBags then return false end
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

local function DeferCombat(needsReconcile, object, operation)
    if needsReconcile then deferredReconcile = true end
    if object and not IsSecret(object) and deferredObjects[object] ~= "branch" then
        deferredObjects[object] = operation or "paint"
    end
    if not combatQueued then
        combatQueued = true
        eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    end
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
    if state.layoutWidth == width and state.layoutHeight == height then return true end
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
    state.layoutWidth, state.layoutHeight = width, height
    return true
end

local function RestoreSharedButton(state)
    if not state then return end
    if state.restored and not state.saved then return end
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
    state.appliedState = nil
    state.restored = true
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
        if IsSecret(region) or not region or customRegions[region] or seen[region] then return end
        if not CanStyle(region) or region:GetParent() ~= button then return end
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
    -- Do not enumerate/allocate legacy texture parts for a different style.
    if InCombatLockdown() then DeferCombat(false, button); return true end
    if StyleForButton(button) ~= "hd" then
        RestoreSharedButton(sharedButtons[button])
        return false
    end
    local family = button.atlasName
    if IsSecret(family) then return false end
    local modern = family and sharedFamilies[family]
    local parts = not modern and LegacyButtonParts(button)
    if not modern and not parts then
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
    for _, original in ipairs(state.saved) do
        local alpha = original.texture:GetAlpha()
        if IsSecret(alpha) then return true end
        if alpha ~= 0 then original.texture:SetAlpha(0) end
    end
    local colors = sharedColors[buttonState] or sharedColors.NORMAL
    if state.appliedState ~= colors then
        local face, top, bottom, left, right = unpack(state.normal)
        face:SetGradient("VERTICAL", colors.bottom, colors.top)
        top:SetColorTexture(unpack(colors.edgeTop))
        bottom:SetColorTexture(unpack(colors.edgeBottom))
        left:SetColorTexture(unpack(sharedEdgeLeft))
        right:SetColorTexture(unpack(sharedEdgeRight))
        for _, texture in ipairs(state.normal) do texture:Show() end
        state.highlight[1]:SetShown(buttonState ~= "DISABLED")
        state.appliedState = colors
    end
    state.restored = false
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

local function SlicedButtonUnchanged(button, state, parts, buttonState, classic)
    if not state or not state.saved or state.appliedState ~= buttonState
        or state.appliedClassic ~= classic or #state.saved ~= #parts then return false end
    local width, height = button:GetSize()
    if IsSecret(width) or IsSecret(height) or width <= 0 or height <= 0
        or state.appliedWidth ~= width or state.appliedHeight ~= height then return false end
    -- Revalidate the current sources, ownership and native alpha. Pooled
    -- controls can replace their textures or become restricted at any time.
    for index, texture in ipairs(parts) do
        if state.saved[index].texture ~= texture or not CanStyle(texture)
            or texture:GetParent() ~= button then return false end
        local alpha = texture:GetAlpha()
        if IsSecret(alpha) or alpha ~= 0 then return false end
    end
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
    if SlicedButtonUnchanged(button, state, parts, buttonState, classic) then return true end
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
        -- ApplyButton already owns the common OnShow hook.
        for _, script in ipairs({"OnEnable", "OnDisable", "OnSizeChanged"}) do
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
    local width, height = button:GetSize()
    if not IsSecret(width) and not IsSecret(height) then
        state.appliedWidth, state.appliedHeight = width, height
    else
        state.appliedWidth, state.appliedHeight = nil, nil
    end
    state.appliedState, state.appliedClassic = buttonState, classic
    state.restored = false
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
    if not record or not record.coords or not record.file then return end
    local coords = PublicValues(...)
    if not coords then return end
    record.coords = coords
    if not active then return end
    if InCombatLockdown() then DeferCombat(false, region); return end
    if StyleForRegion(region) ~= record.style then ApplyRegion(region); return end
    applying = true
    if record.appliedCoords then region:SetTexCoord(unpack(record.appliedCoords))
    else region:SetTexCoord(0, 1, 0, 1) end
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
    if InCombatLockdown() then DeferCombat(false, region); return end
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
    if InCombatLockdown() then DeferCombat(false, region); return end
    if StyleForRegion(region) ~= record.style then ApplyRegion(region); return end
    applying = true
    region:SetDesaturation(1)
    applying = false
end

ApplyRegion = function(region)
    if applying or not active or not CanStyle(region) or customRegions[region] then return end
    if InCombatLockdown() then DeferCombat(false, region); return end
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
        if previous.file and previous.coords then
            if previous.appliedCoords then region:SetTexCoord(unpack(previous.appliedCoords))
            else region:SetTexCoord(0, 1, 0, 1) end
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
    elseif previous and previous.appliedCoords and not atlas then
        -- SetTexture retains UVs. Remove our calendar crop before recording
        -- a different file; SetAtlas already supplies its own coordinates.
        applying = true
        region:SetTexCoord(unpack(previous.coords))
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
        if region:GetParent() == _G.CalendarCloseButton
            and file.name:match("^UI%-Panel%-MinimizeButton%-") then
            record.appliedCoords = calendarCloseCoords
        end
        if atlas or record.appliedCoords then
            local coords = PublicValues(region:GetTexCoord())
            if not coords then return end
            record.coords = coords
        end
        if atlas then record.atlas = atlas else record.texture = texture end
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
        if record.appliedCoords then region:SetTexCoord(unpack(record.appliedCoords))
        elseif atlas then region:SetTexCoord(0, 1, 0, 1) end
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
    if InCombatLockdown() then DeferCombat(false, button); return end
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


-- Explicit public control paths from Blizzard XML (Retail and Forever); absent paths are skipped.
-- Legacy controls and protected-window cosmetic leaves are registered separately.
local controlTargets = {
    ["PerksProgramFrame"] = {buttons = {"FooterFrame.AddToCartButton", "FooterFrame.LeaveButton", "FooterFrame.PurchaseButton", "FooterFrame.RefundButton", "FooterFrame.RemoveFromCartButton", "FooterFrame.RotateButtonContainer.RotateLeftButton", "FooterFrame.RotateButtonContainer.RotateRightButton", "FooterFrame.ToggleAttackAnimation", "FooterFrame.ToggleHideArmor", "FooterFrame.ToggleMountSpecial", "FooterFrame.TogglePlayerPreview", "FooterFrame.ViewCartButton", "ModelSceneContainerFrame.AlteredFormButton", "ModelSceneContainerFrame.NormalFormButton", "ProductsFrame.PerksProgramShoppingCartFrame.ClearCartButton", "ProductsFrame.PerksProgramShoppingCartFrame.CloseButton", "ProductsFrame.PerksProgramShoppingCartFrame.PurchaseCartButton", "ProductsFrame.ProductsScrollBoxContainer.NameSortButton", "ProductsFrame.ProductsScrollBoxContainer.PerksProgramHoldFrame.FrozenProductContainer.ProductButton", "ProductsFrame.ProductsScrollBoxContainer.PerksProgramHoldFrame.FrozenProductContainer.ProductButton.ContentsContainer.CartToggleButton", "ProductsFrame.ProductsScrollBoxContainer.PriceSortButton", "ProductsFrame.ProductsScrollBoxContainer.TimeSortButton"}, scrolls = {"ProductsFrame.PerksProgramProductDetailsContainerFrame.SetDetailsScrollBoxContainer.ScrollBox", "ProductsFrame.PerksProgramShoppingCartFrame.ItemList.ScrollBox", "ProductsFrame.ProductsScrollBoxContainer.ScrollBox"}},
    ["AchievementFrame"] = {buttons = {"HeaderDetails.Back", "HeaderDetails.Filters.SearchBox.SearchPreviewContainer.SearchPreview1", "HeaderDetails.Filters.SearchBox.SearchPreviewContainer.SearchPreview2", "HeaderDetails.Filters.SearchBox.SearchPreviewContainer.SearchPreview3", "HeaderDetails.Filters.SearchBox.SearchPreviewContainer.SearchPreview4", "HeaderDetails.Filters.SearchBox.SearchPreviewContainer.SearchPreview5", "HeaderDetails.Filters.SearchBox.SearchPreviewContainer.ShowAllSearchResults", "SearchResults.CloseButton", "Tab1", "Tab2", "Tab3"}, scrolls = {"Categories.ScrollBox", "SearchResults.ScrollBox"}},
    ["AchievementFrameAchievements"] = {buttons = {}, scrolls = {"ScrollBox"}},
    ["AchievementFrameCloseButton"] = {buttons = {"."}, scrolls = {}},
    ["AchievementFrameComparison"] = {buttons = {}, scrolls = {"AchievementContainer.ScrollBox", "StatContainer.ScrollBox"}},
    ["AchievementFrameStats"] = {buttons = {}, scrolls = {"ScrollBox"}},
    ["AchievementFrameSummaryCategoriesCategory10Button"] = {buttons = {"."}, scrolls = {}},
    ["AchievementFrameSummaryCategoriesCategory11Button"] = {buttons = {"."}, scrolls = {}},
    ["AchievementFrameSummaryCategoriesCategory12Button"] = {buttons = {"."}, scrolls = {}},
    ["AchievementFrameSummaryCategoriesCategory1Button"] = {buttons = {"."}, scrolls = {}},
    ["AchievementFrameSummaryCategoriesCategory2Button"] = {buttons = {"."}, scrolls = {}},
    ["AchievementFrameSummaryCategoriesCategory3Button"] = {buttons = {"."}, scrolls = {}},
    ["AchievementFrameSummaryCategoriesCategory4Button"] = {buttons = {"."}, scrolls = {}},
    ["AchievementFrameSummaryCategoriesCategory5Button"] = {buttons = {"."}, scrolls = {}},
    ["AchievementFrameSummaryCategoriesCategory6Button"] = {buttons = {"."}, scrolls = {}},
    ["AchievementFrameSummaryCategoriesCategory7Button"] = {buttons = {"."}, scrolls = {}},
    ["AchievementFrameSummaryCategoriesCategory8Button"] = {buttons = {"."}, scrolls = {}},
    ["AchievementFrameSummaryCategoriesCategory9Button"] = {buttons = {"."}, scrolls = {}},
    ["AuctionHouseFrame"] = {buttons = {"AuctionsFrame.AllAuctionsList.RefreshFrame.RefreshButton", "AuctionsFrame.AuctionsTab", "AuctionsFrame.BidFrame.BidButton", "AuctionsFrame.BidsList.RefreshFrame.RefreshButton", "AuctionsFrame.BidsTab", "AuctionsFrame.BuyoutFrame.BuyoutButton", "AuctionsFrame.CancelAuctionButton", "AuctionsFrame.CommoditiesList.RefreshFrame.RefreshButton", "AuctionsFrame.ItemDisplay", "AuctionsFrame.ItemDisplay.FavoriteButton", "AuctionsFrame.ItemDisplay.ItemButton", "AuctionsFrame.ItemList.RefreshFrame.RefreshButton", "AuctionsTab", "BrowseResultsFrame.ItemList.RefreshFrame.RefreshButton", "BuyDialog.BuyNowButton", "BuyDialog.CancelButton", "BuyDialog.Notification.Button", "BuyDialog.OkayButton", "BuyTab", "CloseButton", "CommoditiesBuyFrame.BackButton", "CommoditiesBuyFrame.BuyDisplay.BuyButton", "CommoditiesBuyFrame.BuyDisplay.ItemDisplay", "CommoditiesBuyFrame.BuyDisplay.ItemDisplay.FavoriteButton", "CommoditiesBuyFrame.BuyDisplay.ItemDisplay.ItemButton", "CommoditiesBuyFrame.BuyDisplay.QuantityInput.MaxButton", "CommoditiesBuyFrame.ItemList.RefreshFrame.RefreshButton", "CommoditiesSellFrame.ItemDisplay", "CommoditiesSellFrame.ItemDisplay.ItemButton", "CommoditiesSellFrame.Overlay", "CommoditiesSellFrame.PostButton", "CommoditiesSellFrame.QuantityInput.MaxButton", "CommoditiesSellList.RefreshFrame.RefreshButton", "DialogOverlay", "ItemBuyFrame.BackButton", "ItemBuyFrame.BidFrame.BidButton", "ItemBuyFrame.BuyoutFrame.BuyoutButton", "ItemBuyFrame.ItemDisplay", "ItemBuyFrame.ItemDisplay.FavoriteButton", "ItemBuyFrame.ItemDisplay.ItemButton", "ItemBuyFrame.ItemList.RefreshFrame.RefreshButton", "ItemSellFrame.BuyoutModeCheckButton", "ItemSellFrame.DisabledOverlay", "ItemSellFrame.ItemDisplay", "ItemSellFrame.ItemDisplay.ItemButton", "ItemSellFrame.Overlay", "ItemSellFrame.PostButton", "ItemSellFrame.QuantityInput.MaxButton", "ItemSellList.RefreshFrame.RefreshButton", "SearchBar.FavoritesSearchButton", "SearchBar.FilterButton.ClearFiltersButton", "SearchBar.SearchButton", "SellTab", "WoWTokenResults.Buyout", "WoWTokenResults.GameTimeTutorial.CloseButton", "WoWTokenResults.GameTimeTutorial.RightDisplay.StoreButton", "WoWTokenResults.HelpButton", "WoWTokenResults.TokenDisplay", "WoWTokenResults.TokenDisplay.FavoriteButton", "WoWTokenResults.TokenDisplay.ItemButton", "WoWTokenSellFrame.DummyRefreshButton", "WoWTokenSellFrame.ItemDisplay", "WoWTokenSellFrame.ItemDisplay.ItemButton", "WoWTokenSellFrame.PostButton"}, scrolls = {"AuctionsFrame.AllAuctionsList.ScrollBox", "AuctionsFrame.BidsList.ScrollBox", "AuctionsFrame.CommoditiesList.ScrollBox", "AuctionsFrame.ItemList.ScrollBox", "AuctionsFrame.SummaryList.ScrollBox", "BrowseResultsFrame.ItemList.ScrollBox", "CategoriesList.ScrollBox", "CommoditiesBuyFrame.ItemList.ScrollBox", "CommoditiesSellList.ScrollBox", "ItemBuyFrame.ItemList.ScrollBox", "ItemSellList.ScrollBox"}},
    ["AuctionHouseMultisellProgressFrame"] = {buttons = {"CancelButton"}, scrolls = {}},
    ["BagItemAutoSortButton"] = {buttons = {"."}, scrolls = {}},
    ["BankCleanUpConfirmationPopup"] = {buttons = {"AcceptButton", "CancelButton", "HidePopupCheckbox.Checkbox"}, scrolls = {}},
    ["BankFrame"] = {buttons = {"BankPanel.AutoDepositFrame.DepositButton", "BankPanel.AutoDepositFrame.IncludeReagentsCheckbox", "BankPanel.AutoSortButton", "BankPanel.MoneyFrame.DepositButton", "BankPanel.MoneyFrame.WithdrawButton", "BankPanel.PurchaseButton", "BankPanel.PurchasePrompt.TabCostFrame.PurchaseButton", "BankPanel.PurchaseTab", "BankPanel.TabSettingsMenu.BorderBox.SelectedIconArea.SelectedIconButton", "BankPanel.TabSettingsMenu.DepositSettingsMenu.AssignConsumablesCheckbox", "BankPanel.TabSettingsMenu.DepositSettingsMenu.AssignEquipmentCheckbox", "BankPanel.TabSettingsMenu.DepositSettingsMenu.AssignJunkCheckbox", "BankPanel.TabSettingsMenu.DepositSettingsMenu.AssignProfessionGoodsCheckbox", "BankPanel.TabSettingsMenu.DepositSettingsMenu.AssignReagentsCheckbox", "BankPanel.TabSettingsMenu.DepositSettingsMenu.IgnoreCleanUpCheckbox", "CloseButton"}, scrolls = {"BankPanel.TabSettingsMenu.IconSelector"}},
    ["BasicMessageDialogButton"] = {buttons = {"."}, scrolls = {}},
    ["BonusRollFrame"] = {buttons = {"PromptFrame.EncounterJournalLinkButton", "PromptFrame.PassButton", "PromptFrame.RollButton"}, scrolls = {}},
    ["CharacterBackSlot"] = {buttons = {"popoutButton"}, scrolls = {}},
    ["CharacterChestSlot"] = {buttons = {"popoutButton"}, scrolls = {}},
    ["CharacterFeetSlot"] = {buttons = {"popoutButton"}, scrolls = {}},
    ["CharacterFinger0Slot"] = {buttons = {"popoutButton"}, scrolls = {}},
    ["CharacterFinger1Slot"] = {buttons = {"popoutButton"}, scrolls = {}},
    ["CharacterFrame"] = {buttons = {"CloseButton", "RightPaneToggleButton"}, scrolls = {}},
    ["CharacterFrameTab1"] = {buttons = {"."}, scrolls = {}},
    ["CharacterFrameTab2"] = {buttons = {"."}, scrolls = {}},
    ["CharacterFrameTab3"] = {buttons = {"."}, scrolls = {}},
    ["CharacterHandsSlot"] = {buttons = {"popoutButton"}, scrolls = {}},
    ["CharacterHeadSlot"] = {buttons = {"popoutButton"}, scrolls = {}},
    ["CharacterLegsSlot"] = {buttons = {"popoutButton"}, scrolls = {}},
    ["CharacterMainHandSlot"] = {buttons = {"popoutButton"}, scrolls = {}},
    ["CharacterNeckSlot"] = {buttons = {"popoutButton"}, scrolls = {}},
    ["CharacterRangedSlot"] = {buttons = {"popoutButton"}, scrolls = {}},
    ["CharacterSecondaryHandSlot"] = {buttons = {"popoutButton"}, scrolls = {}},
    ["CharacterShirtSlot"] = {buttons = {"popoutButton"}, scrolls = {}},
    ["CharacterShoulderSlot"] = {buttons = {"popoutButton"}, scrolls = {}},
    ["CharacterStatsPanePetScrollBox"] = {buttons = {}, scrolls = {".", "ScrollBox"}},
    ["CharacterStatsPaneScrollBox"] = {buttons = {}, scrolls = {".", "ScrollBox"}},
    ["CharacterTabardSlot"] = {buttons = {"popoutButton"}, scrolls = {}},
    ["CharacterTrinket0Slot"] = {buttons = {"popoutButton"}, scrolls = {}},
    ["CharacterTrinket1Slot"] = {buttons = {"popoutButton"}, scrolls = {}},
    ["CharacterWaistSlot"] = {buttons = {"popoutButton"}, scrolls = {}},
    ["CharacterWristSlot"] = {buttons = {"popoutButton"}, scrolls = {}},
    ["CinematicFrameCloseDialogConfirmButton"] = {buttons = {"."}, scrolls = {}},
    ["CinematicFrameCloseDialogResumeButton"] = {buttons = {"."}, scrolls = {}},
    ["CoinPickupCancelButton"] = {buttons = {"."}, scrolls = {}},
    ["CoinPickupLeftButton"] = {buttons = {"."}, scrolls = {}},
    ["CoinPickupOkayButton"] = {buttons = {"."}, scrolls = {}},
    ["CoinPickupRightButton"] = {buttons = {"."}, scrolls = {}},
    ["CollectionsJournal"] = {buttons = {"CloseButton", "HeirloomsTab", "MountsTab", "PetsTab", "ToysTab", "WarbandScenesTab", "WardrobeTab"}, scrolls = {}},
    ["CommunitiesAvatarPickerDialog"] = {buttons = {}, scrolls = {"ScrollBox"}},
    ["CommunitiesFrame"] = {buttons = {"ChatTab", "CloseButton", "ClubFinderInvitationFrame.AcceptButton", "ClubFinderInvitationFrame.ApplyButton", "ClubFinderInvitationFrame.DeclineButton", "ClubFinderInvitationFrame.RequestToJoinFrame.Apply", "ClubFinderInvitationFrame.RequestToJoinFrame.Cancel", "ClubFinderInvitationFrame.WarningDialog.Accept", "ClubFinderInvitationFrame.WarningDialog.Cancel", "CommunitiesCalendarButton", "CommunitiesControlFrame.CommunitiesSettingsButton", "CommunitiesControlFrame.GuildControlButton", "CommunitiesControlFrame.GuildRecruitmentButton", "CommunityFinderFrame.ClubFinderPendingTab", "CommunityFinderFrame.ClubFinderSearchTab", "CommunityFinderFrame.GuildCards.FirstCard", "CommunityFinderFrame.GuildCards.FirstCard.RequestJoin", "CommunityFinderFrame.GuildCards.NextPage", "CommunityFinderFrame.GuildCards.PreviousPage", "CommunityFinderFrame.GuildCards.SecondCard", "CommunityFinderFrame.GuildCards.SecondCard.RequestJoin", "CommunityFinderFrame.GuildCards.ThirdCard", "CommunityFinderFrame.GuildCards.ThirdCard.RequestJoin", "CommunityFinderFrame.OptionsList.DpsRoleFrame.Checkbox", "CommunityFinderFrame.OptionsList.HealerRoleFrame.Checkbox", "CommunityFinderFrame.OptionsList.Search", "CommunityFinderFrame.OptionsList.TankRoleFrame.Checkbox", "CommunityFinderFrame.PendingGuildCards.FirstCard", "CommunityFinderFrame.PendingGuildCards.FirstCard.RequestJoin", "CommunityFinderFrame.PendingGuildCards.NextPage", "CommunityFinderFrame.PendingGuildCards.PreviousPage", "CommunityFinderFrame.PendingGuildCards.SecondCard", "CommunityFinderFrame.PendingGuildCards.SecondCard.RequestJoin", "CommunityFinderFrame.PendingGuildCards.ThirdCard", "CommunityFinderFrame.PendingGuildCards.ThirdCard.RequestJoin", "CommunityFinderFrame.RequestToJoinFrame.Apply", "CommunityFinderFrame.RequestToJoinFrame.Cancel", "CommunityNameChangeFrame.Button", "CommunityNameChangeFrame.CloseButton", "CommunityPostingChangeFrame.Button", "CommunityPostingChangeFrame.CloseButton", "EditStreamDialog.Accept", "EditStreamDialog.Cancel", "EditStreamDialog.Delete", "EditStreamDialog.TypeCheckbox", "GuildBenefitsFrame.GuildRewardsTutorialButton", "GuildBenefitsTab", "GuildDetailsFrame.Info.EditDetailsButton", "GuildDetailsFrame.Info.EditMOTDButton", "GuildDetailsFrame.News.GMImpeachButton", "GuildDetailsFrame.News.SetFiltersButton", "GuildFinderFrame.ClubFinderPendingTab", "GuildFinderFrame.ClubFinderSearchTab", "GuildFinderFrame.GuildCards.FirstCard", "GuildFinderFrame.GuildCards.FirstCard.RequestJoin", "GuildFinderFrame.GuildCards.NextPage", "GuildFinderFrame.GuildCards.PreviousPage", "GuildFinderFrame.GuildCards.SecondCard", "GuildFinderFrame.GuildCards.SecondCard.RequestJoin", "GuildFinderFrame.GuildCards.ThirdCard", "GuildFinderFrame.GuildCards.ThirdCard.RequestJoin", "GuildFinderFrame.OptionsList.DpsRoleFrame.Checkbox", "GuildFinderFrame.OptionsList.HealerRoleFrame.Checkbox", "GuildFinderFrame.OptionsList.Search", "GuildFinderFrame.OptionsList.TankRoleFrame.Checkbox", "GuildFinderFrame.PendingGuildCards.FirstCard", "GuildFinderFrame.PendingGuildCards.FirstCard.RequestJoin", "GuildFinderFrame.PendingGuildCards.NextPage", "GuildFinderFrame.PendingGuildCards.PreviousPage", "GuildFinderFrame.PendingGuildCards.SecondCard", "GuildFinderFrame.PendingGuildCards.SecondCard.RequestJoin", "GuildFinderFrame.PendingGuildCards.ThirdCard", "GuildFinderFrame.PendingGuildCards.ThirdCard.RequestJoin", "GuildFinderFrame.RequestToJoinFrame.Apply", "GuildFinderFrame.RequestToJoinFrame.Cancel", "GuildInfoTab", "GuildLogButton", "GuildMemberDetailFrame.CloseButton", "GuildMemberDetailFrame.GroupInviteButton", "GuildMemberDetailFrame.RemoveButton", "GuildNameAlertFrame", "GuildNameChangeFrame.Button", "GuildNameChangeFrame.CloseButton", "GuildPostingChangeFrame.Button", "GuildPostingChangeFrame.CloseButton", "InvitationFrame.AcceptButton", "InvitationFrame.DeclineButton", "InviteButton", "MaximizeMinimizeFrame.MaximizeButton", "MaximizeMinimizeFrame.MinimizeButton", "MemberList.ShowOfflineButton", "PostingExpirationText.InfoButton", "RecruitmentDialog.Accept", "RecruitmentDialog.Cancel", "RecruitmentDialog.MaxLevelOnly.Button", "RecruitmentDialog.MinIlvlOnly.Button", "RecruitmentDialog.ShouldListClub.Button", "RosterTab", "TicketFrame.AcceptButton", "TicketFrame.DeclineButton"}, scrolls = {"ApplicantList.ScrollBox", "CommunitiesList.ScrollBox", "CommunityFinderFrame.CommunityCards.ScrollBox", "CommunityFinderFrame.PendingCommunityCards.ScrollBox", "GuildBenefitsFrame.Perks.ScrollBox", "GuildBenefitsFrame.Rewards.ScrollBox", "GuildDetailsFrame.News.ScrollBox", "GuildFinderFrame.CommunityCards.ScrollBox", "GuildFinderFrame.PendingCommunityCards.ScrollBox", "MemberList.ScrollBox"}},
    ["CommunitiesGuildLogFrameCloseButton"] = {buttons = {"."}, scrolls = {}},
    ["CommunitiesGuildNewsFiltersFrame"] = {buttons = {"Achievement", "CloseButton", "DungeonEncounter", "EpicItemCrafted", "EpicItemLooted", "EpicItemPurchased", "GuildAchievement", "LegendaryItemLooted"}, scrolls = {}},
    ["CommunitiesGuildTextEditFrameAcceptButton"] = {buttons = {"."}, scrolls = {}},
    ["CommunitiesGuildTextEditFrameCloseButton"] = {buttons = {"."}, scrolls = {}},
    ["CommunitiesSettingsDialog"] = {buttons = {"Accept", "AutoAcceptApplications.Button", "Cancel", "ChangeAvatarButton", "CrossFactionToggle.CheckButton", "Delete", "MaxLevelOnly.Button", "MinIlvlOnly.Button", "ShouldListClub.Button"}, scrolls = {}},
    ["CommunitiesTicketManagerDialog"] = {buttons = {"Close", "Copy", "GenerateLinkButton", "LinkToChat", "MaximizeButton"}, scrolls = {"InviteManager.ScrollBox"}},
    ["ConquestFrame"] = {buttons = {"Arena2v2", "Arena3v3", "ConquestBar.Reward", "JoinButton", "RatedBG", "RatedBGBlitz", "RatedSoloShuffle", "RoleList.DPSIcon", "RoleList.DPSIcon.checkButton", "RoleList.HealerIcon", "RoleList.HealerIcon.checkButton", "RoleList.TankIcon", "RoleList.TankIcon.checkButton"}, scrolls = {}},
    ["ContainedAlertFrame"] = {buttons = {"."}, scrolls = {}},
    ["DestinyFrame"] = {buttons = {"allianceButton", "hordeButton"}, scrolls = {}},
    ["DressUpFrame"] = {buttons = {"CloseButton", "MaximizeMinimizeFrame.MaximizeButton", "MaximizeMinimizeFrame.MinimizeButton", "ResetButton", "ToggleCustomSetDetailsButton"}, scrolls = {"SetSelectionPanel.ScrollBox"}},
    ["DressUpFrameCancelButton"] = {buttons = {"."}, scrolls = {}},
    ["DropDownToggleButton"] = {buttons = {"."}, scrolls = {}},
    ["EncounterJournal"] = {buttons = {"CloseButton", "JourneysFrame.JourneyOverview.OverviewBtn", "JourneysFrame.JourneyProgress.DelvesCompanionConfigurationFrame.CompanionConfigBtn", "JourneysFrame.JourneyProgress.LevelSkipButton", "JourneysFrame.JourneyProgress.OverviewBtn", "JourneysTab", "LootJournalTab", "MonthlyActivitiesFrame.HelpButton", "MonthlyActivitiesTab", "TutorialsFrame.Contents.StartButton", "TutorialsTab", "dungeonsTab", "encounter.info.bossTab", "encounter.info.instanceButton", "encounter.info.lootTab", "encounter.info.modelTab", "encounter.info.overviewTab", "encounter.instance.mapButton", "instanceSelect.GreatVaultButton", "navBar.home", "raidsTab", "suggestFrame.Suggestion1.button", "suggestFrame.Suggestion1.nextButton", "suggestFrame.Suggestion1.prevButton", "suggestFrame.Suggestion2.centerDisplay.button", "suggestFrame.Suggestion3.centerDisplay.button", "suggestTab"}, scrolls = {"JourneysFrame.JourneysList", "MonthlyActivitiesFrame.FilterList.ScrollBox", "MonthlyActivitiesFrame.ScrollBox", "encounter.info.BossesScrollBox", "encounter.info.LootContainer.ScrollBox", "encounter.instance.LoreScrollingFont.ScrollBox", "instanceSelect.ScrollBox", "searchResults", "searchResults.ScrollBox"}},
    ["EncounterJournalEncounterFrameInfoCreatureButton1"] = {buttons = {"."}, scrolls = {}},
    ["EncounterJournalSearchResultsCloseButton"] = {buttons = {"."}, scrolls = {}},
    ["EquipmentFlyoutFrame"] = {buttons = {"NavigationFrame.NextButton", "NavigationFrame.PageTurnIndicatorLeft", "NavigationFrame.PageTurnIndicatorRight", "NavigationFrame.PrevButton"}, scrolls = {}},
    ["EventButton"] = {buttons = {"."}, scrolls = {}},
    ["EventToastManagerFrame"] = {buttons = {"HideButton"}, scrolls = {}},
    ["EventToastManagerSideDisplay"] = {buttons = {"."}, scrolls = {}},
    ["FloatingBattlePetTooltip"] = {buttons = {"CloseButton", "JournalClick"}, scrolls = {}},
    ["FloatingPetBattleAbilityTooltip"] = {buttons = {"CloseButton"}, scrolls = {}},
    ["FriendsFrame"] = {buttons = {"CloseButton", "FriendsTabHeader.BattlenetFrame.BroadcastFrame.CancelButton", "FriendsTabHeader.BattlenetFrame.BroadcastFrame.UpdateButton", "FriendsTabHeader.BattlenetFrame.UnavailableInfoButton", "IgnoreListWindow.CloseButton", "IgnoreListWindow.UnignorePlayerButton"}, scrolls = {"IgnoreListWindow.ScrollBox"}},
    ["FriendsFrameAddFriendButton"] = {buttons = {"."}, scrolls = {}},
    ["FriendsFrameSendMessageButton"] = {buttons = {"."}, scrolls = {}},
    ["FriendsFrameTab1"] = {buttons = {"."}, scrolls = {}},
    ["FriendsFrameTab2"] = {buttons = {"."}, scrolls = {}},
    ["FriendsFrameTab3"] = {buttons = {"."}, scrolls = {}},
    ["FriendsFrameTab4"] = {buttons = {"."}, scrolls = {}},
    ["FriendsFriendsFrame"] = {buttons = {"CloseButton", "SendRequestButton"}, scrolls = {"ScrollBox"}},
    ["FriendsListFrame"] = {buttons = {}, scrolls = {"ScrollBox"}},
    ["QuickJoinFrame"] = {buttons = {"JoinQueueButton"}, scrolls = {}},
    ["QuickJoinRoleSelectionFrame"] = {buttons = {"CloseButton", "AcceptButton", "CancelButton", "RoleButtonTank.CheckButton", "RoleButtonHealer.CheckButton", "RoleButtonDPS.CheckButton"}, scrolls = {}},
    ["RaidParentFrame"] = {buttons = {"CloseButton"}, scrolls = {}},
    ["RaidParentFrameTab1"] = {buttons = {"."}, scrolls = {}},
    ["RaidParentFrameTab2"] = {buttons = {"."}, scrolls = {}},
    ["RaidFrameConvertToRaidButton"] = {buttons = {"."}, scrolls = {}},
    ["RaidFrameRaidInfoButton"] = {buttons = {"."}, scrolls = {}},
    ["RaidFrameAllAssistCheckButton"] = {buttons = {"."}, scrolls = {}},
    ["RaidInfoCloseButton"] = {buttons = {"."}, scrolls = {}},
    ["RaidInfoExtendButton"] = {buttons = {"."}, scrolls = {}},
    ["RaidInfoCancelButton"] = {buttons = {"."}, scrolls = {}},
    ["GearManagerPopupFrame"] = {buttons = {"BorderBox.SelectedIconArea.SelectedIconButton"}, scrolls = {"IconSelector"}},
    ["GhostFrame"] = {buttons = {"."}, scrolls = {}},
    ["GroupFinderFrame"] = {buttons = {"groupButton1", "groupButton2", "groupButton3", "groupButton4"}, scrolls = {}},
    ["GroupLootFrame1"] = {buttons = {"GreedButton", "IconFrame", "NeedButton", "PassButton", "TransmogButton"}, scrolls = {}},
    ["GroupLootFrame2"] = {buttons = {"GreedButton", "IconFrame", "NeedButton", "PassButton", "TransmogButton"}, scrolls = {}},
    ["GroupLootFrame3"] = {buttons = {"GreedButton", "IconFrame", "NeedButton", "PassButton", "TransmogButton"}, scrolls = {}},
    ["GroupLootFrame4"] = {buttons = {"GreedButton", "IconFrame", "NeedButton", "PassButton", "TransmogButton"}, scrolls = {}},
    ["GroupLootHistoryFrame"] = {buttons = {"ClosePanelButton", "ResizeButton"}, scrolls = {"ScrollBox"}},
    ["GuildBankFrame"] = {buttons = {"BuyInfo.PurchaseButton", "CloseButton", "DepositButton", "Info.SaveButton", "WithdrawButton"}, scrolls = {}},
    ["GuildBankFrameTab1"] = {buttons = {"."}, scrolls = {}},
    ["GuildBankFrameTab2"] = {buttons = {"."}, scrolls = {}},
    ["GuildBankFrameTab3"] = {buttons = {"."}, scrolls = {}},
    ["GuildBankFrameTab4"] = {buttons = {"."}, scrolls = {}},
    ["GuildBankPopupFrame"] = {buttons = {"BorderBox.SelectedIconArea.SelectedIconButton"}, scrolls = {"IconSelector"}},
    ["GuildBankTab1"] = {buttons = {"Button"}, scrolls = {}},
    ["GuildBankTab2"] = {buttons = {"Button"}, scrolls = {}},
    ["GuildBankTab3"] = {buttons = {"Button"}, scrolls = {}},
    ["GuildBankTab4"] = {buttons = {"Button"}, scrolls = {}},
    ["GuildBankTab5"] = {buttons = {"Button"}, scrolls = {}},
    ["GuildBankTab6"] = {buttons = {"Button"}, scrolls = {}},
    ["GuildBankTab7"] = {buttons = {"Button"}, scrolls = {}},
    ["GuildBankTab8"] = {buttons = {"Button"}, scrolls = {}},
    ["GuildInviteFrameDeclineButton"] = {buttons = {"."}, scrolls = {}},
    ["GuildInviteFrameJoinButton"] = {buttons = {"."}, scrolls = {}},
    ["GuildRegistrarButton1"] = {buttons = {"."}, scrolls = {}},
    ["GuildRegistrarButton2"] = {buttons = {"."}, scrolls = {}},
    ["GuildRegistrarFrame"] = {buttons = {"CloseButton"}, scrolls = {}},
    ["GuildRegistrarFrameCancelButton"] = {buttons = {"."}, scrolls = {}},
    ["GuildRegistrarFrameGoodbyeButton"] = {buttons = {"."}, scrolls = {}},
    ["GuildRegistrarFramePurchaseButton"] = {buttons = {"."}, scrolls = {}},
    ["HeirloomsJournal"] = {buttons = {"PagingFrame.NextPageButton", "PagingFrame.PrevPageButton"}, scrolls = {}},
    ["HonorFrame"] = {buttons = {"BonusFrame.Arena1Button", "BonusFrame.BrawlButton", "BonusFrame.BrawlButton2", "BonusFrame.RandomBGButton", "BonusFrame.RandomEpicBGButton", "ConquestBar.Reward", "QueueButton", "RoleList.DPSIcon", "RoleList.DPSIcon.checkButton", "RoleList.HealerIcon", "RoleList.HealerIcon.checkButton", "RoleList.TankIcon", "RoleList.TankIcon.checkButton"}, scrolls = {"SpecificScrollBox"}},
    ["InboxNextPageButton"] = {buttons = {"."}, scrolls = {}},
    ["InboxPrevPageButton"] = {buttons = {"."}, scrolls = {}},
    ["InspectRecipeFrame"] = {buttons = {"CloseButton", "SchematicForm.AllocateBestQualityCheckbox", "SchematicForm.Concentrate.ConcentrateToggleButton", "SchematicForm.Details.CraftingChoicesContainer.ConcentrateContainer.ConcentrateToggleButton", "SchematicForm.FavoriteButton", "SchematicForm.OutputIcon", "SchematicForm.QualityDialog.AcceptButton", "SchematicForm.QualityDialog.CancelButton", "SchematicForm.QualityDialog.ClosePanelButton", "SchematicForm.RecipeSourceButton", "SchematicForm.TrackRecipeCheckbox"}, scrolls = {}},
    ["ItemTextFrame"] = {buttons = {"CloseButton"}, scrolls = {}},
    ["ItemTextNextPageButton"] = {buttons = {"."}, scrolls = {}},
    ["ItemTextPrevPageButton"] = {buttons = {"."}, scrolls = {}},
    ["JumpToUnreadButton"] = {buttons = {"."}, scrolls = {}},
    ["LFDQueueFrame"] = {buttons = {}, scrolls = {"Follower.ScrollBox", "Specific.ScrollBox"}},
    ["LFDQueueFrameFindGroupButton"] = {buttons = {"."}, scrolls = {}},
    ["LFDQueueFrameNoLFDWhileLFRLeaveQueueButton"] = {buttons = {"."}, scrolls = {}},
    ["LFDQueueFramePartyBackfillBackfillButton"] = {buttons = {"."}, scrolls = {}},
    ["LFDQueueFramePartyBackfillNoBackfillButton"] = {buttons = {"."}, scrolls = {}},
    ["LFDQueueFrameRoleButtonDPS"] = {buttons = {".", "checkButton"}, scrolls = {}},
    ["LFDQueueFrameRoleButtonHealer"] = {buttons = {".", "checkButton"}, scrolls = {}},
    ["LFDQueueFrameRoleButtonLeader"] = {buttons = {".", "checkButton"}, scrolls = {}},
    ["LFDQueueFrameRoleButtonTank"] = {buttons = {".", "checkButton"}, scrolls = {}},
    ["LFDRoleCheckPopupAcceptButton"] = {buttons = {"."}, scrolls = {}},
    ["LFDRoleCheckPopupDeclineButton"] = {buttons = {"."}, scrolls = {}},
    ["LFDRoleCheckPopupRoleButtonDPS"] = {buttons = {".", "checkButton"}, scrolls = {}},
    ["LFDRoleCheckPopupRoleButtonHealer"] = {buttons = {".", "checkButton"}, scrolls = {}},
    ["LFDRoleCheckPopupRoleButtonTank"] = {buttons = {".", "checkButton"}, scrolls = {}},
    ["LFGDungeonReadyDialog"] = {buttons = {"enterButton", "leaveButton"}, scrolls = {}},
    ["LFGDungeonReadyDialogCloseButton"] = {buttons = {"."}, scrolls = {}},
    ["LFGDungeonReadyStatusCloseButton"] = {buttons = {"."}, scrolls = {}},
    ["LFGInvitePopupAcceptButton"] = {buttons = {"."}, scrolls = {}},
    ["LFGInvitePopupDeclineButton"] = {buttons = {"."}, scrolls = {}},
    ["LFGInvitePopupRoleButtonDPS"] = {buttons = {".", "checkButton"}, scrolls = {}},
    ["LFGInvitePopupRoleButtonHealer"] = {buttons = {".", "checkButton"}, scrolls = {}},
    ["LFGInvitePopupRoleButtonTank"] = {buttons = {".", "checkButton"}, scrolls = {}},
    ["LFGListApplicationDialog"] = {buttons = {"CancelButton", "DamagerButton", "DamagerButton.CheckButton", "HealerButton", "HealerButton.CheckButton", "SignUpButton", "TankButton", "TankButton.CheckButton"}, scrolls = {}},
    ["LFGListFrame"] = {buttons = {"ApplicationViewer.AutoAcceptButton", "ApplicationViewer.BrowseGroupsButton", "ApplicationViewer.EditButton", "ApplicationViewer.ItemLevelColumnHeader", "ApplicationViewer.NameColumnHeader", "ApplicationViewer.RatingColumnHeader", "ApplicationViewer.RefreshButton", "ApplicationViewer.RemoveEntryButton", "ApplicationViewer.RoleColumnHeader", "CategorySelection.FindGroupButton", "CategorySelection.StartGroupButton", "EntryCreation.ActivityFinder.Dialog.CancelButton", "EntryCreation.ActivityFinder.Dialog.EntryBox.LockButton", "EntryCreation.ActivityFinder.Dialog.SelectButton", "EntryCreation.CancelButton", "EntryCreation.CrossFactionGroup.CheckButton", "EntryCreation.Description.LockButton", "EntryCreation.ItemLevel.CheckButton", "EntryCreation.ItemLevel.EditBox.LockButton", "EntryCreation.ListGroupButton", "EntryCreation.ListGroupButton.DisableStateClickButton", "EntryCreation.MythicPlusRating.CheckButton", "EntryCreation.MythicPlusRating.EditBox.LockButton", "EntryCreation.Name.LockButton", "EntryCreation.PVPRating.CheckButton", "EntryCreation.PVPRating.EditBox.LockButton", "EntryCreation.PrivateGroup.CheckButton", "EntryCreation.PvpItemLevel.CheckButton", "EntryCreation.PvpItemLevel.EditBox.LockButton", "EntryCreation.VoiceChat.CheckButton", "EntryCreation.VoiceChat.EditBox.LockButton", "SearchPanel.BackButton", "SearchPanel.BackToGroupButton", "SearchPanel.RefreshButton", "SearchPanel.ScrollBox.StartGroupButton", "SearchPanel.SignUpButton"}, scrolls = {"ApplicationViewer.ScrollBox", "EntryCreation.ActivityFinder.Dialog.ScrollBox", "SearchPanel.ScrollBox"}},
    ["LFGListInviteDialog"] = {buttons = {"AcceptButton", "AcknowledgeButton", "DeclineButton"}, scrolls = {}},
    ["LFGReadyCheckPopup"] = {buttons = {"NoButton", "YesButton"}, scrolls = {}},
    ["LootFrame"] = {buttons = {"ClosePanelButton"}, scrolls = {"ScrollBox"}},
    ["MailFrame"] = {buttons = {"CloseButton"}, scrolls = {}},
    ["MailFrameTab1"] = {buttons = {"."}, scrolls = {}},
    ["MailFrameTab2"] = {buttons = {"."}, scrolls = {}},
    ["MailItem1"] = {buttons = {"Button"}, scrolls = {}},
    ["MailItem1ExpireTime"] = {buttons = {"."}, scrolls = {}},
    ["MailItem2"] = {buttons = {"Button"}, scrolls = {}},
    ["MailItem2ExpireTime"] = {buttons = {"."}, scrolls = {}},
    ["MailItem3"] = {buttons = {"Button"}, scrolls = {}},
    ["MailItem3ExpireTime"] = {buttons = {"."}, scrolls = {}},
    ["MailItem4"] = {buttons = {"Button"}, scrolls = {}},
    ["MailItem4ExpireTime"] = {buttons = {"."}, scrolls = {}},
    ["MailItem5"] = {buttons = {"Button"}, scrolls = {}},
    ["MailItem5ExpireTime"] = {buttons = {"."}, scrolls = {}},
    ["MailItem6"] = {buttons = {"Button"}, scrolls = {}},
    ["MailItem6ExpireTime"] = {buttons = {"."}, scrolls = {}},
    ["MailItem7"] = {buttons = {"Button"}, scrolls = {}},
    ["MailItem7ExpireTime"] = {buttons = {"."}, scrolls = {}},
    ["MapQuestInfoRewardsFrame"] = {buttons = {"ArtifactXPFrame", "HonorFrame", "MoneyFrame", "SkillPointFrame", "TitleFrame", "WarModeBonusFrame", "XPFrame"}, scrolls = {}},
    ["MapQuestInfoRewardsFrameQuestInfoItem1"] = {buttons = {"."}, scrolls = {}},
    ["MasterLooterFrame"] = {buttons = {"player1"}, scrolls = {}},
    ["MerchantFrame"] = {buttons = {"CloseButton"}, scrolls = {}},
    ["MerchantFrameTab1"] = {buttons = {"."}, scrolls = {}},
    ["MerchantFrameTab2"] = {buttons = {"."}, scrolls = {}},
    ["MerchantGuildBankRepairButton"] = {buttons = {"."}, scrolls = {}},
    ["MerchantNextPageButton"] = {buttons = {"."}, scrolls = {}},
    ["MerchantPrevPageButton"] = {buttons = {"."}, scrolls = {}},
    ["MerchantRepairAllButton"] = {buttons = {"."}, scrolls = {}},
    ["MerchantRepairItemButton"] = {buttons = {"."}, scrolls = {}},
    ["MerchantSellAllJunkButton"] = {buttons = {"."}, scrolls = {}},
    ["ModelPreviewFrame"] = {buttons = {"CloseButton", "Display.ModelScene.CarouselLeftButton", "Display.ModelScene.CarouselRightButton", "Display.ModelScene.ControlFrame.resetButton", "Display.ModelScene.ControlFrame.rotateLeftButton", "Display.ModelScene.ControlFrame.rotateRightButton", "Display.ModelScene.ControlFrame.zoomInButton", "Display.ModelScene.ControlFrame.zoomOutButton"}, scrolls = {}},
    ["MountJournal"] = {buttons = {"BottomLeftInset.SlotButton", "BottomLeftInset.SuppressedMountEquipmentButton", "DynamicFlightFlyoutPopup.DynamicFlightModeButton", "DynamicFlightFlyoutPopup.OpenDynamicFlightSkillTreeButton", "MountButton", "MountDisplay.InfoButton", "MountDisplay.ModelScene.TogglePlayer", "SummonRandomFavoriteSpellFrame.Button", "ToggleDynamicFlightFlyoutButton"}, scrolls = {"ScrollBox"}},
    ["OpenAllMail"] = {buttons = {"."}, scrolls = {}},
    ["OpenMailCancelButton"] = {buttons = {"."}, scrolls = {}},
    ["OpenMailDeleteButton"] = {buttons = {"."}, scrolls = {}},
    ["OpenMailFrame"] = {buttons = {"CloseButton"}, scrolls = {}},
    ["OpenMailReplyButton"] = {buttons = {"."}, scrolls = {}},
    ["OpenMailReportSpamButton"] = {buttons = {"."}, scrolls = {}},
    ["PVEFrame"] = {buttons = {"CloseButton", "tab1", "tab2", "tab3"}, scrolls = {}},
    ["PVPFramePopup"] = {buttons = {"minimizeButton"}, scrolls = {}},
    ["PVPFramePopupAcceptButton"] = {buttons = {"."}, scrolls = {}},
    ["PVPFramePopupDeclineButton"] = {buttons = {"."}, scrolls = {}},
    ["PVPQueueFrame"] = {buttons = {"CategoryButton1", "CategoryButton2", "CategoryButton3", "CategoryButton4", "CategoryButton5", "HonorInset.CasualPanel.HonorLevelDisplay.NextRewardLevel", "HonorInset.PlunderstormPanel.PlunderstoreButton", "HonorInset.RatedPanel.HonorLevelDisplay.NextRewardLevel", "HonorInset.TrainingGroundsPanel.HonorLevelDisplay.NextRewardLevel", "NewSeasonPopup.Leave", "PrestigeLevelDialog.Accept", "PrestigeLevelDialog.Cancel", "PrestigeLevelDialog.CloseButton"}, scrolls = {}},
    ["PVPRankFrame"] = {buttons = {"MainInfoFrame.RankProgressBarDisplay.NextRewardLevel"}, scrolls = {"DetailFrame.Description.ScrollBox"}},
    ["PVPReadyDialog"] = {buttons = {"enterButton", "leaveButton"}, scrolls = {}},
    ["PVPReadyDialogCloseButton"] = {buttons = {"."}, scrolls = {}},
    ["PVPRoleCheckPopup"] = {buttons = {"DPSIcon", "DPSIcon.checkButton", "HealerIcon", "HealerIcon.checkButton", "TankIcon", "TankIcon.checkButton"}, scrolls = {}},
    ["PVPRoleCheckPopupAcceptButton"] = {buttons = {"."}, scrolls = {}},
    ["PVPRoleCheckPopupDeclineButton"] = {buttons = {"."}, scrolls = {}},
    ["PaperDollFrame"] = {buttons = {"CharacterModelScene.ControlFrame.resetButton", "CharacterModelScene.ControlFrame.rotateLeftButton", "CharacterModelScene.ControlFrame.rotateRightButton", "CharacterModelScene.ControlFrame.zoomInButton", "CharacterModelScene.ControlFrame.zoomOutButton", "EquipmentManagerPane.EquipSet", "EquipmentManagerPane.NewSet", "EquipmentManagerPane.SaveSet"}, scrolls = {"EquipmentManagerPane.ScrollBox", "TitleManagerPane.ScrollBox"}},
    ["PaperDollSidebarTab1"] = {buttons = {"."}, scrolls = {}},
    ["PaperDollSidebarTab2"] = {buttons = {"."}, scrolls = {}},
    ["PaperDollSidebarTab3"] = {buttons = {"."}, scrolls = {}},
    ["PetJournal"] = {buttons = {"AchievementStatus", "FindBattleButton", "HealPetSpellFrame.Button", "Loadout.Pet1", "Loadout.Pet1.MenuRegion", "Loadout.Pet1.dragButton", "Loadout.Pet1.modelScene.cardButton", "Loadout.Pet1.setButton", "Loadout.Pet1.spell1", "Loadout.Pet1.spell2", "Loadout.Pet1.spell3", "Loadout.Pet2", "Loadout.Pet2.MenuRegion", "Loadout.Pet2.dragButton", "Loadout.Pet2.modelScene.cardButton", "Loadout.Pet2.setButton", "Loadout.Pet2.spell1", "Loadout.Pet2.spell2", "Loadout.Pet2.spell3", "Loadout.Pet3", "Loadout.Pet3.MenuRegion", "Loadout.Pet3.dragButton", "Loadout.Pet3.modelScene.cardButton", "Loadout.Pet3.setButton", "Loadout.Pet3.spell1", "Loadout.Pet3.spell2", "Loadout.Pet3.spell3", "MainHelpButton", "PetCard.PetInfo", "PetCard.spell1", "PetCard.spell2", "PetCard.spell3", "PetCard.spell4", "PetCard.spell5", "PetCard.spell6", "SpellSelect.Spell1", "SpellSelect.Spell2", "SummonButton", "SummonRandomPetSpellFrame.Button"}, scrolls = {"ScrollBox"}},
    ["PetitionFrame"] = {buttons = {"CloseButton"}, scrolls = {}},
    ["PetitionFrameCancelButton"] = {buttons = {"."}, scrolls = {}},
    ["PetitionFrameRenameButton"] = {buttons = {"."}, scrolls = {}},
    ["PetitionFrameRequestButton"] = {buttons = {"."}, scrolls = {}},
    ["PetitionFrameSignButton"] = {buttons = {"."}, scrolls = {}},
    ["PingSystemTutorial"] = {buttons = {"CloseButton"}, scrolls = {}},
    ["PlunderstormFrame"] = {buttons = {"StartQueue"}, scrolls = {}},
    ["PlunderstormFramePopup"] = {buttons = {"AcceptButton", "DeclineButton"}, scrolls = {}},
    ["PrimaryProfession1"] = {buttons = {"SpellButton1", "SpellButton2", "UnlearnButton"}, scrolls = {}},
    ["PrimaryProfession2"] = {buttons = {"SpellButton1", "SpellButton2", "UnlearnButton"}, scrolls = {}},
    ["ProfessionsBookFrame"] = {buttons = {"CloseButton", "MainHelpButton"}, scrolls = {}},
    ["ProfessionsCustomerOrdersFrame"] = {buttons = {"BrowseOrders.SearchBar.FavoritesSearchButton", "BrowseOrders.SearchBar.SearchButton", "BrowseTab", "CloseButton", "Form.AllocateBestQualityCheckbox", "Form.BackButton", "Form.CurrentListings.CloseButton", "Form.FavoriteButton", "Form.OutputIcon", "Form.PaymentContainer.CancelOrderButton", "Form.PaymentContainer.ListOrderButton", "Form.PaymentContainer.ViewListingsButton", "Form.QualityDialog.AcceptButton", "Form.QualityDialog.CancelButton", "Form.QualityDialog.ClosePanelButton", "Form.TrackRecipeCheckbox.Checkbox", "MyOrdersPage.RefreshButton", "OrdersTab"}, scrolls = {"BrowseOrders.CategoryList.ScrollBox", "BrowseOrders.RecipeList.ScrollBox", "Form.CurrentListings.OrderList.ScrollBox", "Form.PaymentContainer.NoteEditBox.ScrollingEditBox.ScrollBox", "MyOrdersPage.OrderList.ScrollBox"}},
    ["ProfessionsFrame"] = {buttons = {"CloseButton", "CraftingPage.CraftingOutputLog.ClosePanelButton", "CraftingPage.CreateAllButton", "CraftingPage.CreateButton", "CraftingPage.MinimizedSearchResults.CloseButton", "CraftingPage.SchematicForm.AllocateBestQualityCheckbox", "CraftingPage.SchematicForm.Concentrate.ConcentrateToggleButton", "CraftingPage.SchematicForm.Details.CraftingChoicesContainer.ConcentrateContainer.ConcentrateToggleButton", "CraftingPage.SchematicForm.FavoriteButton", "CraftingPage.SchematicForm.OutputIcon", "CraftingPage.SchematicForm.QualityDialog.AcceptButton", "CraftingPage.SchematicForm.QualityDialog.CancelButton", "CraftingPage.SchematicForm.QualityDialog.ClosePanelButton", "CraftingPage.SchematicForm.RecipeSourceButton", "CraftingPage.SchematicForm.TrackRecipeCheckbox", "CraftingPage.TutorialButton", "CraftingPage.ViewGuildCraftersButton", "MaximizeMinimize.MaximizeButton", "MaximizeMinimize.MinimizeButton", "OrdersPage.BrowseFrame.BackButton", "OrdersPage.BrowseFrame.FavoritesSearchButton", "OrdersPage.BrowseFrame.GuildOrdersButton", "OrdersPage.BrowseFrame.NpcOrdersButton", "OrdersPage.BrowseFrame.PersonalOrdersButton", "OrdersPage.BrowseFrame.PublicOrdersButton", "OrdersPage.BrowseFrame.SearchButton", "OrdersPage.OrderView.CompleteOrderButton", "OrdersPage.OrderView.CraftingOutputLog.ClosePanelButton", "OrdersPage.OrderView.CreateButton", "OrdersPage.OrderView.DeclineOrderDialog.CancelButton", "OrdersPage.OrderView.DeclineOrderDialog.ConfirmButton", "OrdersPage.OrderView.OrderDetails.FulfillmentForm.ItemIcon", "OrdersPage.OrderView.OrderDetails.SchematicForm.AllocateBestQualityCheckbox", "OrdersPage.OrderView.OrderDetails.SchematicForm.Concentrate.ConcentrateToggleButton", "OrdersPage.OrderView.OrderDetails.SchematicForm.Details.CraftingChoicesContainer.ConcentrateContainer.ConcentrateToggleButton", "OrdersPage.OrderView.OrderDetails.SchematicForm.FavoriteButton", "OrdersPage.OrderView.OrderDetails.SchematicForm.OutputIcon", "OrdersPage.OrderView.OrderDetails.SchematicForm.QualityDialog.AcceptButton", "OrdersPage.OrderView.OrderDetails.SchematicForm.QualityDialog.CancelButton", "OrdersPage.OrderView.OrderDetails.SchematicForm.QualityDialog.ClosePanelButton", "OrdersPage.OrderView.OrderDetails.SchematicForm.RecipeSourceButton", "OrdersPage.OrderView.OrderDetails.SchematicForm.TrackRecipeCheckbox", "OrdersPage.OrderView.OrderInfo.BackButton", "OrdersPage.OrderView.OrderInfo.DeclineOrderButton", "OrdersPage.OrderView.OrderInfo.ReleaseOrderButton", "OrdersPage.OrderView.OrderInfo.StartOrderButton", "OrdersPage.OrderView.StartRecraftButton", "OrdersPage.OrderView.StopRecraftButton", "SpecPage.ApplyButton", "SpecPage.BackToFullTreeButton", "SpecPage.BackToPreviewButton", "SpecPage.DetailedView.Path", "SpecPage.DetailedView.SpendPointsButton", "SpecPage.DetailedView.UnlockPathButton", "SpecPage.UndoButton", "SpecPage.UnlockTabButton", "SpecPage.ViewPreviewButton", "SpecPage.ViewTreeButton"}, scrolls = {"CraftingPage.CraftingOutputLog.ScrollBox", "CraftingPage.GuildFrame.Container.ScrollBox", "CraftingPage.MinimizedSearchResults.ScrollBox", "CraftingPage.RecipeList.ScrollBox", "OrdersPage.BrowseFrame.OrderList.ScrollBox", "OrdersPage.BrowseFrame.RecipeList.ScrollBox", "OrdersPage.OrderView.CraftingOutputLog.ScrollBox", "OrdersPage.OrderView.DeclineOrderDialog.NoteEditBox.ScrollingEditBox.ScrollBox", "OrdersPage.OrderView.OrderDetails.FulfillmentForm.NoteEditBox.ScrollingEditBox.ScrollBox"}},
    ["QuestFrame"] = {buttons = {"CloseButton"}, scrolls = {}},
    ["QuestFrameAcceptButton"] = {buttons = {"."}, scrolls = {}},
    ["QuestFrameCompleteButton"] = {buttons = {"."}, scrolls = {}},
    ["QuestFrameCompleteQuestButton"] = {buttons = {"."}, scrolls = {}},
    ["QuestFrameDeclineButton"] = {buttons = {"."}, scrolls = {}},
    ["QuestFrameGoodbyeButton"] = {buttons = {"."}, scrolls = {}},
    ["QuestFrameGreetingGoodbyeButton"] = {buttons = {"."}, scrolls = {}},
    ["QuestInfoRewardsFrame"] = {buttons = {"ArtifactXPFrame", "HonorFrame", "SkillPointFrame", "WarModeBonusFrame"}, scrolls = {}},
    ["QuestInfoRewardsFrameQuestInfoItem1"] = {buttons = {"."}, scrolls = {}},
    ["QuestInfoSpellObjectiveFrame"] = {buttons = {"."}, scrolls = {}},
    ["QuestLogPopupDetailFrame"] = {buttons = {"AbandonButton", "CloseButton", "ShareButton", "ShowMapButton", "TrackButton"}, scrolls = {}},
    ["QuestMapFrame"] = {buttons = {"QuestSessionManagement.ExecuteSessionCommand", "QuestsFrame.CampaignOverview.Header.BackButton", "QuestsFrame.DetailsFrame.AbandonButton", "QuestsFrame.DetailsFrame.BackFrame.BackButton", "QuestsFrame.DetailsFrame.DestinationMapButton", "QuestsFrame.DetailsFrame.ShareButton", "QuestsFrame.DetailsFrame.TrackButton", "QuestsFrame.DetailsFrame.WaypointMapButton"}, scrolls = {"EventsFrame.ScrollBox"}},
    ["QuestSessionManager"] = {buttons = {"CheckConvertToRaidDialog.ButtonContainer.Confirm", "CheckConvertToRaidDialog.ButtonContainer.Decline", "CheckLeavePartyDialog.ButtonContainer.Confirm", "CheckLeavePartyDialog.ButtonContainer.Decline", "CheckStartDialog.ButtonContainer.Confirm", "CheckStartDialog.ButtonContainer.Decline", "CheckStopDialog.ButtonContainer.Confirm", "CheckStopDialog.ButtonContainer.Decline", "ConfirmBNJoinGroupRequestDialog.ButtonContainer.Confirm", "ConfirmBNJoinGroupRequestDialog.ButtonContainer.Decline", "ConfirmInviteToGroupDialog.ButtonContainer.Confirm", "ConfirmInviteToGroupDialog.ButtonContainer.Decline", "ConfirmInviteToGroupReceivedDialog.ButtonContainer.Confirm", "ConfirmInviteToGroupReceivedDialog.ButtonContainer.Decline", "ConfirmInviteTravelPassConfirmationDialog.ButtonContainer.Confirm", "ConfirmInviteTravelPassConfirmationDialog.ButtonContainer.Decline", "ConfirmJoinGroupRequestDialog.ButtonContainer.Confirm", "ConfirmJoinGroupRequestDialog.ButtonContainer.Decline", "ConfirmRequestToJoinGroupDialog.ButtonContainer.Confirm", "ConfirmRequestToJoinGroupDialog.ButtonContainer.Decline", "StartDialog.ButtonContainer.Confirm", "StartDialog.ButtonContainer.Decline", "StartDialog.MinimizeButton"}, scrolls = {}},
    ["RaidFinderFrameFindRaidButton"] = {buttons = {"."}, scrolls = {}},
    ["RaidFinderQueueFrameIneligibleFrame"] = {buttons = {"leaveQueueButton"}, scrolls = {}},
    ["RaidFinderQueueFramePartyBackfillBackfillButton"] = {buttons = {"."}, scrolls = {}},
    ["RaidFinderQueueFramePartyBackfillNoBackfillButton"] = {buttons = {"."}, scrolls = {}},
    ["RaidFinderQueueFrameRoleButtonDPS"] = {buttons = {".", "checkButton"}, scrolls = {}},
    ["RaidFinderQueueFrameRoleButtonHealer"] = {buttons = {".", "checkButton"}, scrolls = {}},
    ["RaidFinderQueueFrameRoleButtonLeader"] = {buttons = {".", "checkButton"}, scrolls = {}},
    ["RaidFinderQueueFrameRoleButtonTank"] = {buttons = {".", "checkButton"}, scrolls = {}},
    ["RatingMenuButtonOkay"] = {buttons = {"."}, scrolls = {}},
    ["ReadyCheckFrameNoButton"] = {buttons = {"."}, scrolls = {}},
    ["ReadyCheckFrameYesButton"] = {buttons = {"."}, scrolls = {}},
    ["ReadyStatus"] = {buttons = {"CloseButton"}, scrolls = {}},
    ["ReputationFrame"] = {buttons = {"ReputationDetailFrame.AtWarCheckbox", "ReputationDetailFrame.CloseButton", "ReputationDetailFrame.MakeInactiveCheckbox", "ReputationDetailFrame.ViewRenownButton", "ReputationDetailFrame.WatchFactionCheckbox"}, scrolls = {"ReputationDetailFrame.Description.ScrollBox", "ReputationDetailFrame.ScrollingDescription.ScrollBox", "ScrollBox"}},
    ["RolePollPopup"] = {buttons = {"acceptButton"}, scrolls = {}},
    ["RolePollPopupCloseButton"] = {buttons = {"."}, scrolls = {}},
    ["RolePollPopupRoleButtonDPS"] = {buttons = {".", "checkButton"}, scrolls = {}},
    ["RolePollPopupRoleButtonHealer"] = {buttons = {".", "checkButton"}, scrolls = {}},
    ["RolePollPopupRoleButtonTank"] = {buttons = {".", "checkButton"}, scrolls = {}},
    ["ScenarioFinderFrame"] = {buttons = {}, scrolls = {"Queue.Specific.ScrollFrame"}},
    ["ScenarioQueueFrameFindGroupButton"] = {buttons = {"."}, scrolls = {}},
    ["ScenarioQueueFramePartyBackfillBackfillButton"] = {buttons = {"."}, scrolls = {}},
    ["ScenarioQueueFramePartyBackfillNoBackfillButton"] = {buttons = {"."}, scrolls = {}},
    ["SecondaryProfession1"] = {buttons = {"SpellButton1", "SpellButton2"}, scrolls = {}},
    ["SecondaryProfession2"] = {buttons = {"SpellButton1", "SpellButton2"}, scrolls = {}},
    ["SecondaryProfession3"] = {buttons = {"SpellButton1", "SpellButton2"}, scrolls = {}},
    ["SendMailAttachment1"] = {buttons = {"."}, scrolls = {}},
    ["SendMailAttachment10"] = {buttons = {"."}, scrolls = {}},
    ["SendMailAttachment11"] = {buttons = {"."}, scrolls = {}},
    ["SendMailAttachment12"] = {buttons = {"."}, scrolls = {}},
    ["SendMailAttachment13"] = {buttons = {"."}, scrolls = {}},
    ["SendMailAttachment14"] = {buttons = {"."}, scrolls = {}},
    ["SendMailAttachment15"] = {buttons = {"."}, scrolls = {}},
    ["SendMailAttachment16"] = {buttons = {"."}, scrolls = {}},
    ["SendMailAttachment2"] = {buttons = {"."}, scrolls = {}},
    ["SendMailAttachment3"] = {buttons = {"."}, scrolls = {}},
    ["SendMailAttachment4"] = {buttons = {"."}, scrolls = {}},
    ["SendMailAttachment5"] = {buttons = {"."}, scrolls = {}},
    ["SendMailAttachment6"] = {buttons = {"."}, scrolls = {}},
    ["SendMailAttachment7"] = {buttons = {"."}, scrolls = {}},
    ["SendMailAttachment8"] = {buttons = {"."}, scrolls = {}},
    ["SendMailAttachment9"] = {buttons = {"."}, scrolls = {}},
    ["SendMailCODButton"] = {buttons = {"."}, scrolls = {}},
    ["SendMailCancelButton"] = {buttons = {"."}, scrolls = {}},
    ["SendMailMailButton"] = {buttons = {"."}, scrolls = {}},
    ["SendMailSendMoneyButton"] = {buttons = {"."}, scrolls = {}},
    ["SettingsPanel"] = {buttons = {"AddOnsTab", "ApplyButton", "CloseButton", "ClosePanelButton", "Container.SettingsList.Header.DefaultsButton", "Container.SettingsList.Header.TutorialButton", "Container.SettingsList.ScrollBox.InputBlocker", "GameTab", "SearchBox.clearButton"}, scrolls = {"CategoryList.ScrollBox", "Container.SettingsList.ScrollBox"}},
    ["SideDressUpFrame"] = {buttons = {"ResetButton"}, scrolls = {}},
    ["SideDressUpFrameCloseButton"] = {buttons = {"."}, scrolls = {}},
    ["SkillsFrame"] = {buttons = {}, scrolls = {"ScrollBox", "SkillDetailFrame.Description.ScrollBox"}},
    ["StackSplitFrame"] = {buttons = {"CancelButton", "LeftButton", "OkayButton", "RightButton"}, scrolls = {}},
    ["TabardCharacterModelRotateLeftButton"] = {buttons = {"."}, scrolls = {}},
    ["TabardCharacterModelRotateRightButton"] = {buttons = {"."}, scrolls = {}},
    ["TabardFrame"] = {buttons = {"CloseButton"}, scrolls = {}},
    ["TabardFrameAcceptButton"] = {buttons = {"."}, scrolls = {}},
    ["TabardFrameCancelButton"] = {buttons = {"."}, scrolls = {}},
    ["TabardFrameCustomization1LeftButton"] = {buttons = {"."}, scrolls = {}},
    ["TabardFrameCustomization1RightButton"] = {buttons = {"."}, scrolls = {}},
    ["TabardFrameCustomization2LeftButton"] = {buttons = {"."}, scrolls = {}},
    ["TabardFrameCustomization2RightButton"] = {buttons = {"."}, scrolls = {}},
    ["TabardFrameCustomization3LeftButton"] = {buttons = {"."}, scrolls = {}},
    ["TabardFrameCustomization3RightButton"] = {buttons = {"."}, scrolls = {}},
    ["TabardFrameCustomization4LeftButton"] = {buttons = {"."}, scrolls = {}},
    ["TabardFrameCustomization4RightButton"] = {buttons = {"."}, scrolls = {}},
    ["TabardFrameCustomization5LeftButton"] = {buttons = {"."}, scrolls = {}},
    ["TabardFrameCustomization5RightButton"] = {buttons = {"."}, scrolls = {}},
    ["TaxiFrame"] = {buttons = {"CloseButton"}, scrolls = {}},
    ["ToyBox"] = {buttons = {"PagingFrame.NextPageButton", "PagingFrame.PrevPageButton", "iconsFrame.spellButton1", "iconsFrame.spellButton10", "iconsFrame.spellButton11", "iconsFrame.spellButton12", "iconsFrame.spellButton13", "iconsFrame.spellButton14", "iconsFrame.spellButton15", "iconsFrame.spellButton16", "iconsFrame.spellButton17", "iconsFrame.spellButton18", "iconsFrame.spellButton2", "iconsFrame.spellButton3", "iconsFrame.spellButton4", "iconsFrame.spellButton5", "iconsFrame.spellButton6", "iconsFrame.spellButton7", "iconsFrame.spellButton8", "iconsFrame.spellButton9"}, scrolls = {}},
    ["TradeFrame"] = {buttons = {"CloseButton"}, scrolls = {}},
    ["TradeFrameCancelButton"] = {buttons = {"."}, scrolls = {}},
    ["TradeFrameTradeButton"] = {buttons = {"."}, scrolls = {}},
    ["TrainingGroundsFrame"] = {buttons = {"BonusTrainingGroundList.RandomTrainingGroundArenaButton", "BonusTrainingGroundList.RandomTrainingGroundButton", "ConquestBar.Reward", "QueueButton", "RoleList.DPSIcon", "RoleList.DPSIcon.checkButton", "RoleList.HealerIcon", "RoleList.HealerIcon.checkButton", "RoleList.TankIcon", "RoleList.TankIcon.checkButton"}, scrolls = {"SpecificTrainingGroundList.ScrollBox"}},
    ["TransmogAndMountDressupFrame"] = {buttons = {"ShowMountCheckButton"}, scrolls = {}},
    ["TutorialFrameAlertButton"] = {buttons = {"."}, scrolls = {}},
    ["TutorialFrameCloseButton"] = {buttons = {"."}, scrolls = {}},
    ["TutorialFrameNextButton"] = {buttons = {"."}, scrolls = {}},
    ["TutorialFrameOkayButton"] = {buttons = {"."}, scrolls = {}},
    ["TutorialFramePrevButton"] = {buttons = {"."}, scrolls = {}},
    ["WarbandSceneJournal"] = {buttons = {"IconsFrame.Icons.Controls.ShowOwned.Checkbox"}, scrolls = {}},
    ["WardrobeCollectionFrame"] = {buttons = {"InfoButton", "ItemsCollectionFrame.PagingFrame.NextPageButton", "ItemsCollectionFrame.PagingFrame.PrevPageButton", "ItemsTab", "SetsTab"}, scrolls = {"SetsCollectionFrame.ListContainer.ScrollBox"}},
    ["WardrobeCustomSetEditFrame"] = {buttons = {"AcceptButton", "CancelButton", "DeleteButton"}, scrolls = {}},
    ["WeeklyRewardsFrame"] = {buttons = {"CloseButton", "SelectRewardButton"}, scrolls = {}},
    ["WhoFrame"] = {buttons = {"LevelHeader"}, scrolls = {"ScrollBox"}},
    ["WhoFrameAddFriendButton"] = {buttons = {"."}, scrolls = {}},
    ["WhoFrameColumnHeader1"] = {buttons = {"."}, scrolls = {}},
    ["WhoFrameColumnHeader2"] = {buttons = {"."}, scrolls = {}},
    ["WhoFrameColumnHeader4"] = {buttons = {"."}, scrolls = {}},
    ["WhoFrameGroupInviteButton"] = {buttons = {"."}, scrolls = {}},
    ["WhoFrameWhoButton"] = {buttons = {"."}, scrolls = {}},
    ["CalendarClassTotalsButton"] = {buttons = {"."}, scrolls = {}},
    ["CalendarCloseButton"] = {buttons = {"."}, scrolls = {}},
    ["CalendarCreateEventAutoApproveCheck"] = {buttons = {"."}, scrolls = {}},
    ["CalendarCreateEventCloseButton"] = {buttons = {"."}, scrolls = {}},
    ["CalendarCreateEventCreateButton"] = {buttons = {"."}, scrolls = {}},
    ["CalendarCreateEventDescriptionContainer"] = {buttons = {}, scrolls = {"ScrollingEditBox.ScrollBox"}},
    ["CalendarCreateEventInviteButton"] = {buttons = {"."}, scrolls = {}},
    ["CalendarCreateEventInviteList"] = {buttons = {}, scrolls = {"ScrollBox"}},
    ["CalendarCreateEventInviteListClassSortButton"] = {buttons = {"."}, scrolls = {}},
    ["CalendarCreateEventInviteListNameSortButton"] = {buttons = {"."}, scrolls = {}},
    ["CalendarCreateEventInviteListStatusSortButton"] = {buttons = {"."}, scrolls = {}},
    ["CalendarCreateEventLockEventCheck"] = {buttons = {"."}, scrolls = {}},
    ["CalendarCreateEventMassInviteButton"] = {buttons = {"."}, scrolls = {}},
    ["CalendarCreateEventRaidInviteButton"] = {buttons = {"."}, scrolls = {}},
    ["CalendarEventPickerCloseButton"] = {buttons = {"."}, scrolls = {}},
    ["CalendarEventPickerFrame"] = {buttons = {}, scrolls = {"ScrollBox"}},
    ["CalendarMassInviteAcceptButton"] = {buttons = {"."}, scrolls = {}},
    ["CalendarMassInviteCloseButton"] = {buttons = {"."}, scrolls = {}},
    ["CalendarNextMonthButton"] = {buttons = {"."}, scrolls = {}},
    ["CalendarPrevMonthButton"] = {buttons = {"."}, scrolls = {}},
    ["CalendarTexturePickerAcceptButton"] = {buttons = {"."}, scrolls = {}},
    ["CalendarTexturePickerCancelButton"] = {buttons = {"."}, scrolls = {}},
    ["CalendarTexturePickerFrame"] = {buttons = {}, scrolls = {"ScrollBox"}},
    ["CalendarViewEventAcceptButton"] = {buttons = {"."}, scrolls = {}},
    ["CalendarViewEventCloseButton"] = {buttons = {"."}, scrolls = {}},
    ["CalendarViewEventDeclineButton"] = {buttons = {"."}, scrolls = {}},
    ["CalendarViewEventDescriptionContainer"] = {buttons = {}, scrolls = {"ScrollingFont.ScrollBox"}},
    ["CalendarViewEventFrame"] = {buttons = {"HeaderFrame"}, scrolls = {}},
    ["CalendarViewEventInviteList"] = {buttons = {}, scrolls = {"ScrollBox"}},
    ["CalendarViewEventInviteListClassSortButton"] = {buttons = {"."}, scrolls = {}},
    ["CalendarViewEventInviteListNameSortButton"] = {buttons = {"."}, scrolls = {}},
    ["CalendarViewEventInviteListStatusSortButton"] = {buttons = {"."}, scrolls = {}},
    ["CalendarViewEventRemoveButton"] = {buttons = {"."}, scrolls = {}},
    ["CalendarViewEventTentativeButton"] = {buttons = {"."}, scrolls = {}},
    ["CalendarViewHolidayCloseButton"] = {buttons = {"."}, scrolls = {}},
    ["CalendarViewHolidayFrame"] = {buttons = {}, scrolls = {"ScrollingFont.ScrollBox"}},
    ["CalendarViewRaidCloseButton"] = {buttons = {"."}, scrolls = {}},
    ["CalendarViewRaidFrame"] = {buttons = {}, scrolls = {"ScrollingFont.ScrollBox"}},
    ["WorldMapFrame"] = {buttons = {"BorderFrame.CloseButton", "BorderFrame.MaximizeMinimizeFrame.MaximizeButton", "BorderFrame.MaximizeMinimizeFrame.MinimizeButton", "BorderFrame.Tutorial"}, scrolls = {}},
    ["CatalogShopFrame"] = {buttons = {"CatalogShopDetailsFrame.ButtonContainer.DetailsButton", "CatalogShopDetailsFrame.ButtonContainer.PurchaseButton", "CatalogShopDetailsFrame.ProductRefundContainer.RefundButton", "CatalogShopErrorFrame.AcceptButton", "CatalogShopErrorFrame.WebsiteButton", "CatalogShopVCFrame.vcPurchaseButton", "CloseButton", "HeaderFrame.CatalogShopNavBar.ScrollBackwards", "HeaderFrame.CatalogShopNavBar.ScrollForwards", "ModelSceneContainerFrame.AlternateFormButton", "ModelSceneContainerFrame.NormalFormButton", "PMTImageContainerFrame.ImageCarousel.LeftButton", "PMTImageContainerFrame.ImageCarousel.RightButton", "PersistentRefundContainerFrame.PersistentRefundButton", "ProductDetailsContainerFrame.BackButton"}, scrolls = {"HeaderFrame.CatalogShopNavBar.NavButtonScrollBox", "IconTrainFrame.IconTrainScrollBox", "PMTImageContainerFrame.ImageCarousel.ScrollBox", "ProductContainerFrame.ProductsScrollBoxContainer.ScrollBox", "ProductDetailsContainerFrame.DetailsProductContainerFrame.ProductsScrollBoxContainer.ScrollBox"}},
}

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

-- Prepare public controls at their owning window's lifecycle, never by
-- EnumerateFrames or by replacing Blizzard templates / frame metatables.
local revision = 0
local preparedButtons = setmetatable({}, {__mode = "k"})
local panelNamesByFrame = setmetatable({}, {__mode = "k"})
local rootShowHooks = setmetatable({}, {__mode = "k"})
local scrollHooks = setmetatable({}, {__mode = "k"})
local menuHooks = setmetatable({}, {__mode = "k"})
local preparing = setmetatable({}, {__mode = "k"})
local PrepareRoot, PrepareKnownPanels

local function ResolveControl(root, path)
    local object = root
    for key in path:gmatch("[^.]+") do
        if not CanTouch(object) then return end
        object = object[key]
    end
    if CanTouch(object) then return object end
end

local function PrepareButton(button)
    if not active or not CanStyle(button) or not button:IsObjectType("Button") then return end
    if InCombatLockdown() then DeferCombat(false, button); return end
    local previous = preparedButtons[button]
    local parent = button:GetParent()
    if previous and previous.revision == revision and previous.parent == parent then return end
    ApplyButton(button)
    previous = previous or {}
    previous.revision, previous.parent = revision, parent
    preparedButtons[button] = previous
end

-- Only a newly initialized list row or an AceGUI widget is inspected here.
-- The window tree is never traversed. Cap both depth and work for addon rows.
local function PrepareBranch(root)
    if not active or not CanStyle(root) then return end
    if InCombatLockdown() then DeferCombat(false, root, "branch"); return end
    local remaining = 64
    local Visit
    Visit = function(object, depth)
        if remaining == 0 or depth > 6 or not CanStyle(object) then return end
        remaining = remaining - 1
        PrepareButton(object)
        if object.GetChildren then
            local function Children(...)
                for index = 1, select("#", ...) do
                    if remaining == 0 then return end
                    Visit(select(index, ...), depth + 1)
                end
            end
            Children(object:GetChildren())
        end
    end
    Visit(root, 0)
end

local function PrepareScrollBox(scrollBox)
    if not CanStyle(scrollBox) or not scrollBox.RegisterCallback
        or not scrollBox.ForEachFrame or not scrollBox.GetView then return end
    if InCombatLockdown() then DeferCombat(true); return end
    local util = _G.ScrollUtil
    if not util or type(util.AddInitializedFrameCallback) ~= "function" then return end
    local previous = scrollHooks[scrollBox]
    if not previous then
        previous = {}
        scrollHooks[scrollBox] = previous
        -- The callback is documented for addons; do not replace initializers
        -- or hook the frame pool / shared ScrollBox mixins.
        util.AddInitializedFrameCallback(scrollBox, function(_, frame)
            PrepareBranch(frame)
        end, eventFrame, false)
    end
    -- Load-on-demand windows can create their ScrollBox before assigning a
    -- view. Keep the initialization callback, but do not enumerate that list
    -- until Blizzard has installed its view. No polling or native Init calls.
    local view = scrollBox:GetView()
    if IsSecret(view) or type(view) ~= "table" or type(view.ForEachFrame) ~= "function" then return end
    if type(view.IsInitialized) == "function" then
        local initialized = view:IsInitialized()
        if IsSecret(initialized) or not initialized then return end
    end
    if previous.revision ~= revision or previous.view ~= view then
        scrollBox:ForEachFrame(PrepareBranch)
        previous.revision, previous.view = revision, view
    end
end

local function PrepareMenuButtons(frame)
    if not active or not CanStyle(frame) then return end
    if InCombatLockdown() then DeferCombat(true); return end
    local pool = frame.buttonPool
    if IsSecret(pool) or type(pool) ~= "table" or type(pool.EnumerateActive) ~= "function" then return end
    for button in pool:EnumerateActive() do
        if CanTouch(button) and button:GetParent() == frame then PrepareButton(button) end
    end
end

local commonControls = {
    "CloseButton", "ClosePanelButton", "OkayButton", "CancelButton", "AcceptButton",
    "ApplyButton", "BackButton", "NextButton", "PrevButton", "PreviousButton",
    "MaximizeMinimizeButton.MaximizeButton", "MaximizeMinimizeButton.MinimizeButton",
    "MaximizeMinimizeFrame.MaximizeButton", "MaximizeMinimizeFrame.MinimizeButton",
    "button1", "button2", "button3", "button4", "Button1", "Button2", "Button3", "Button4",
}

local function PrepareMapControls(frame, name)
    if name ~= "WorldMapFrame" and name ~= "QuestMapFrame" then return end
    local targets = controlTargets[name]
    if not targets then return end
    for _, path in ipairs(targets.buttons) do
        local button = ResolveControl(frame, path)
        if CanTouch(button) and button:IsObjectType("Button") then
            local ancestor = button:GetParent()
            for _ = 1, 32 do
                if not CanTouch(ancestor) then break end
                if ancestor == frame then
                    RegisterCosmeticButton(button:GetParent(), button)
                    break
                end
                ancestor = ancestor:GetParent()
            end
        end
    end
end

PrepareRoot = function(frame, name)
    if not active or not CanTouch(frame) or preparing[frame] then return end
    if InCombatLockdown() then DeferCombat(true); return end
    preparing[frame] = true
    RegisterCloseButton(frame, name)
    PrepareMapControls(frame, name)
    if frame == _G.PlayerSpellsFrame then PreparePlayerSpellsControls() end
    if CanStyle(frame) then
        PrepareButton(frame)
        if not frame:IsObjectType("Button") then
            for _, path in ipairs(commonControls) do PrepareButton(ResolveControl(frame, path)) end
        end
        if name and name:match("^StaticPopup%d+$") then
            for index = 1, 4 do PrepareButton(_G[name .. "Button" .. index]) end
        end
        local targets = name and controlTargets[name]
        if targets then
            for _, path in ipairs(targets.buttons) do PrepareButton(ResolveControl(frame, path)) end
            for _, path in ipairs(targets.scrolls) do PrepareScrollBox(ResolveControl(frame, path)) end
        end
        if not frame:IsObjectType("Button") and not rootShowHooks[frame] then
            frame:HookScript("OnShow", function(self)
                PrepareRoot(self, panelNamesByFrame[self])
            end)
            rootShowHooks[frame] = true
        end
        if frame == _G.GameMenuFrame then
            if not menuHooks[frame] and type(frame.InitButtons) == "function" then
                -- Observe the concrete menu instance after its own build;
                -- no replacement of native scripts, methods or mixins.
                hooksecurefunc(frame, "InitButtons", PrepareMenuButtons)
                menuHooks[frame] = true
            end
            PrepareMenuButtons(frame)
        end
    end
    preparing[frame] = nil
end

QueuePanel = function(frame)
    if not active or not CanTouch(frame) then return end
    PrepareRoot(frame, panelNamesByFrame[frame])
end

PrepareKnownPanels = function(force)
    if not active then return end
    if InCombatLockdown() then DeferCombat(true); return end
    local function PrepareName(name)
        local frame = _G[name]
        if IsSecret(frame) or not frame then return end
        if not force and preparedPanels[frame] == revision then return end
        if not CanTouch(frame) then return end
        panelNamesByFrame[frame] = name
        PrepareRoot(frame, name)
        preparedPanels[frame] = revision
    end
    for _, name in ipairs(panelNames) do PrepareName(name) end
    for name in pairs(controlTargets) do PrepareName(name) end
    -- Legacy clients use named menu buttons rather than a button pool.
    for _, suffix in ipairs({"Help", "Store", "Options", "UIOptions", "Keybindings",
        "Macros", "Addons", "Logout", "Quit", "Continue", "EditMode", "Ratings"}) do
        PrepareName("GameMenuButton" .. suffix)
    end
    for index = 1, 4 do PrepareName("StaticPopup" .. index) end
    PreparePlayerSpellsControls()
    PrepareReadyCheckButtons()
end

local panelHooks = {}
local panelTargets = {
    ShowReadyCheck = function() PrepareReadyCheckButtons() end,
    ShowUIPanel = QueuePanel,
    StaticPopup_OnShow = QueuePanel,
    StaticPopupSpecial_Show = QueuePanel,
    QuestMapFrame_Show = function() QueuePanel(_G.QuestMapFrame) end,
    QuestMapFrame_ShowQuestDetails = function()
        local frame = _G.QuestMapFrame
        if CanTouch(frame) then QueuePanel(frame.DetailsFrame or frame) end
    end,
}
local menuEventInstalled = false
local function InstallPanelHooks()
    for name, callback in pairs(panelTargets) do
        if not panelHooks[name] and type(_G[name]) == "function" then
            hooksecurefunc(name, callback)
            panelHooks[name] = true
        end
    end
    if not menuEventInstalled and _G.EventRegistry then
        _G.EventRegistry:RegisterCallback("GameMenuFrame.Shown", function()
            PrepareMenuButtons(_G.GameMenuFrame)
        end, eventFrame)
        menuEventInstalled = true
    end
end

local function HookAceGUI()
    if aceGUIHooked then return end
    local AceGUI = LibStub("AceGUI-3.0", true)
    if not AceGUI then return end
    aceGUIHooked = true
    hooksecurefunc(AceGUI, "RegisterAsWidget", function(_, widget)
        if not IsSecret(widget) and type(widget) == "table" then PrepareBranch(widget.frame) end
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
    active = false
    deferredReconcile = nil
    wipe(deferredObjects)
    revision = revision + 1
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
end

function module:StopDarkButtons()
    active, pendingRefresh = false, nil
    deferredReconcile = nil
    wipe(deferredObjects)
    eventFrame:UnregisterEvent("ADDON_LOADED")
    eventFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
    RestoreArtwork()
end

eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_ENABLED" then
        self:UnregisterEvent(event)
        combatQueued = false
        if pendingRefresh then module:RefreshDarkButtons(); return end
        if not active then RestoreArtwork(); return end
        -- Reconcile only registered controls and the objects deferred in combat.
        if deferredReconcile then PrepareKnownPanels(true) end
        deferredReconcile = nil
        for object, operation in pairs(deferredObjects) do
            deferredObjects[object] = nil
            if CanStyle(object) then
                if object:IsObjectType("Texture") then ApplyRegion(object)
                elseif operation == "branch" then PrepareBranch(object)
                else ApplyButton(object) end
            end
        end
    elseif active then
        InstallPanelHooks()
        HookAceGUI()
        InstallPlayerSpellsEvents()
        PrepareKnownPanels()
    end
end)
