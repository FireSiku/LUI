-- LUI presentation for the current Blizzard character/account bank. Blizzard
-- retains the bank frame, tab data, item buttons, interaction scripts, money,
-- access checks and confirmation dialogs. No legacy bank container IDs or
-- character-bag sorting hooks are used here.
local LUI = select(2, ...)
local module = LUI:GetModule("Bags")
local SLOT_SIZE, TOP_SPACE, BOTTOM_SPACE, SIDE_SPACE = 36, 63, 100, 26

local function SavePoints(region)
    local points = {}
    for i = 1, region:GetNumPoints() do points[i] = {region:GetPoint(i)} end
    return points
end

local function RestorePoints(region, points)
    region:ClearAllPoints()
    for _, point in ipairs(points) do region:SetPoint(unpack(point)) end
end

local function HideArtwork(state, region)
    if not region then return end
    if state.alphas[region] == nil then state.alphas[region] = region:GetAlpha() end
    region:SetAlpha(0)
end

local function HideSkin(target)
    module:HideSkinBorder(target)
    local skin = target.LUIBagSkin
    if skin then skin.tint:Hide(); skin.artwork:Hide() end
end

function module:IsBankStyleEnabled()
    local db = module.db and module.db.profile and module.db.profile.Bank
    return module.bankIntegrationEnabled and db and db.Enabled
end

function module:StyleBankItem(button)
    if not module:IsBankStyleEnabled() then return end
    local state = module.bankStyleState
    if not state or state.restoring then return end
    local saved = state.slots[button]
    local icon = button.icon or button.Icon
    if not saved then
        saved = {width = button:GetWidth(), height = button:GetHeight()}
        if icon then
            saved.icon = icon
            saved.iconPoints = SavePoints(icon)
            saved.iconCoords = {icon:GetTexCoord()}
        end
        if button.Count then
            saved.countFont = {button.Count:GetFont()}
            saved.countColor = {button.Count:GetTextColor()}
        end
        state.slots[button] = saved
    end
    if not module:IsHooked(button, "Refresh") then
        module:SecureHook(button, "Refresh", function(self) module:StyleBankItem(self) end)
    end

    button:SetSize(SLOT_SIZE, SLOT_SIZE)
    if icon then
        icon:ClearAllPoints()
        icon:SetPoint("TOPLEFT", button, "TOPLEFT", 3, -3)
        icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -3, 3)
        icon:SetTexCoord(.08, .92, .08, .92)
    end
    HideArtwork(state, button.Background)
    HideArtwork(state, button.IconBorder)
    HideArtwork(state, button:GetNormalTexture())

    local info = button.itemInfo
    button.LUIHasItem = info ~= nil
    module:ApplyItemStyle(button)
    local bags = module.db.profile.Bags
    if info and bags.ItemQuality and info.quality ~= nil then
        local r, g, b = C_Item.GetItemQualityColor(info.quality)
        module:SetSkinBorderColor(button, r, g, b, 1)
    end
    if button.Count then module:RefreshBagFontString(button.Count, "Stack") end
end

-- Native bank tabs put an additive selection glow over the icon. Keep the
-- native icon and socket without adding another outline in LUI presentation.
function module:StyleBankTab(tab)
    if not module:IsBankStyleEnabled() then return end
    local state = module.bankStyleState
    if not state or state.restoring or not tab.SelectedTexture then return end
    if not state.tabs[tab] then
        local highlight = tab:GetHighlightTexture()
        state.tabs[tab] = {
            selectionTexture = tab.SelectedTexture:GetTexture(),
            highlight = highlight,
            highlightAlpha = highlight and highlight:GetAlpha(),
            highlightBlend = highlight and highlight:GetBlendMode(),
        }
    end
    if not module:IsHooked(tab, "RefreshVisuals") then
        module:SecureHook(tab, "RefreshVisuals", function(self) module:StyleBankTab(self) end)
    end
    -- Clearing the artwork also prevents the native alpha animation from
    -- bringing the glow back. The animation and native selection state remain.
    tab.SelectedTexture:SetTexture(nil)
    local highlight = tab:GetHighlightTexture()
    if highlight then highlight:SetBlendMode("BLEND"); highlight:SetAlpha(.15) end
    HideSkin(tab)
end

function module:RefreshBankNames()
    local state = module.bankStyleState
    local frame, panel = state.frame, state.panel
    local accountTab = frame:GetTabButton(frame.accountBankTabID)
    if accountTab then
        if not state.accountTab then
            state.accountTab = accountTab
            state.accountTabText = accountTab.tabText
            state.accountTabLabel = accountTab:GetText()
        end
        accountTab.tabText = "Warband"
        accountTab:SetText("Warband")
        accountTab:UpdateTabWidth()
    end
    local title = panel:GetActiveBankType() == Enum.BankType.Account and "Warband" or BANK
    frame:SetTitle(title)
    if state.title then state.title:SetText(title) end
end

function module:RestoreBankStyle()
    local state = module.bankStyleState
    if not state or not state.active or state.restoring then return end
    state.restoring = true
    state.active = false
    for region, alpha in pairs(state.alphas) do region:SetAlpha(alpha) end
    wipe(state.alphas)
    for button, saved in pairs(state.slots) do
        HideSkin(button)
        button.LUIHasItem = nil
        button:SetSize(saved.width, saved.height)
        if saved.icon then
            RestorePoints(saved.icon, saved.iconPoints)
            saved.icon:SetTexCoord(unpack(saved.iconCoords))
        end
        if button.Count and saved.countFont and saved.countFont[1] then
            button.Count:SetFont(unpack(saved.countFont))
            button.Count:SetTextColor(unpack(saved.countColor))
        end
    end
    wipe(state.slots)
    for tab, saved in pairs(state.tabs) do
        HideSkin(tab)
        tab.SelectedTexture:SetTexture(saved.selectionTexture)
        if saved.highlight then
            saved.highlight:SetBlendMode(saved.highlightBlend)
            saved.highlight:SetAlpha(saved.highlightAlpha)
        end
    end
    wipe(state.tabs)
    if state.accountTab then
        state.accountTab.tabText = state.accountTabText
        state.accountTab:SetText(state.accountTabLabel)
        state.accountTab:UpdateTabWidth()
        state.accountTab = nil
    end
    state.background:Hide()
    local frame, panel = state.frame, state.panel
    frame:SetSize(state.frameWidth, state.frameHeight)
    frame:SetScale(state.frameScale)
    frame:SetAttribute("UIPanelLayout-width", state.layoutWidth)
    frame:SetAttribute("UIPanelLayout-height", state.layoutHeight)
    panel:SetSize(state.panelWidth, state.panelHeight)
    if state.title then
        RestorePoints(state.title, state.titlePoints)
        state.title:SetText(state.titleText)
    end
    -- Let Blizzard regenerate its native slot anchors, including the correct
    -- purchase/locked panel when there are no accessible item slots.
    if panel:IsShown() then
        panel:RefreshBankPanel()
        panel:RequestTitleRefresh()
    end
    if frame:IsShown() then UpdateUIPanelPositions(frame) end
    state.restoring = false
end

function module:RefreshBank()
    if not module:IsBankStyleEnabled() then
        module:RestoreBankStyle()
        return
    end
    if not module:AttachBankHooks() then return end
    local state = module.bankStyleState
    if state.refreshing or state.restoring then return end
    state.refreshing = true
    local frame, panel = state.frame, state.panel
    local db = module.db.profile.Bank
    state.active = true

    HideArtwork(state, frame.Background)
    HideArtwork(state, frame.NineSlice)
    HideArtwork(state, frame.PortraitContainer)
    HideArtwork(state, panel.NineSlice)
    HideArtwork(state, panel.EdgeShadows)
    state.background:SetFrameLevel(frame:GetFrameLevel())
    state.background:SetAllPoints(frame)
    module:ApplyBagFrameStyle(state.background)
    state.background:Show()
    if state.title then
        state.title:ClearAllPoints()
        state.title:SetPoint("TOP", frame, "TOP", 0, -5)
    end

    -- Pool enumeration has no defined order. Lay out the actual bank slot IDs
    -- in row order without replacing buttons or changing their item identity.
    local buttons = {}
    for button in panel:EnumerateValidItems() do buttons[#buttons + 1] = button end
    -- Bank cleanup keeps using Blizzard's own action and confirmations. Only
    -- the display direction changes: the first real slot appears at the end
    -- of the grid in bottom-fill mode. No shared bag-sort setting is changed.
    table.sort(buttons, function(a, b)
        if db.FillFromBottom then
            return a:GetContainerSlotID() > b:GetContainerSlotID()
        end
        return a:GetContainerSlotID() < b:GetContainerSlotID()
    end)
    local columns = math.max(8, math.min(20, tonumber(db.RowSize) or 14))
    local spacing = math.max(0, math.min(12, tonumber(db.Spacing) or 4))
    local groupSpacing = math.max(0, math.min(24, tonumber(db.ColumnGroupSpacing) or 0))
    local width, height = state.panelWidth, state.panelHeight
    -- The deposit button is centered. Its reagent checkbox and label extend
    -- to the right, so reserve that same extent on both sides of the center.
    local deposit = panel.AutoDepositFrame
    local checkbox = deposit and deposit.IncludeReagentsCheckbox
    if checkbox and checkbox:IsShown() then
        local label = checkbox.Text
        local labelWidth = label and math.max(label:GetWidth(), label:GetStringWidth()) or 0
        local rightExtent = deposit.DepositButton:GetWidth() / 2 + 10 + checkbox:GetWidth() + 4 + labelWidth
        width = math.max(width, 2 * (rightExtent + SIDE_SPACE))
    end
    if #buttons > 0 then
        local rows = math.ceil(#buttons / columns)
        local gridWidth = columns * SLOT_SIZE + (columns - 1) * spacing
            + math.floor((columns - 1) / 2) * groupSpacing
        width = math.max(width, 2 * SIDE_SPACE + gridWidth)
        local gridLeft = (width - gridWidth) / 2
        height = TOP_SPACE + rows * SLOT_SIZE + (rows - 1) * spacing + BOTTOM_SPACE
        for index, button in ipairs(buttons) do
            module:StyleBankItem(button)
            button:ClearAllPoints()
            local column = (index - 1) % columns
            button:SetPoint("TOPLEFT", panel, "TOPLEFT",
                gridLeft + column * (SLOT_SIZE + spacing) + math.floor(column / 2) * groupSpacing,
                -TOP_SPACE - math.floor((index - 1) / columns) * (SLOT_SIZE + spacing))
        end
    end
    for tab in panel.bankTabPool:EnumerateActive() do module:StyleBankTab(tab) end
    module:RefreshBankNames()
    local scale = state.frameScale * math.max(.5, math.min(1.5, tonumber(db.Scale) or 1))
    local changed = frame:GetWidth() ~= width or frame:GetHeight() ~= height or frame:GetScale() ~= scale
    panel:SetSize(width, height)
    frame:SetSize(width, height)
    frame:SetScale(scale)
    frame:SetAttribute("UIPanelLayout-width", width)
    frame:SetAttribute("UIPanelLayout-height", height)
    if changed and frame:IsShown() then UpdateUIPanelPositions(frame) end
    state.refreshing = false
end

function module:AttachBankHooks()
    local frame = _G.BankFrame
    local panel = frame and frame.BankPanel
    if not panel or not panel.EnumerateValidItems or not panel.RefreshBankPanel then return false end
    if not module.bankStyleState then
        local title = _G.BankFrameTitleText
        local background = CreateFrame("Frame", nil, frame)
        background:Hide()
        module.bankStyleState = {
            frame = frame, panel = panel, background = background,
            frameWidth = frame:GetWidth(), frameHeight = frame:GetHeight(), frameScale = frame:GetScale(),
            panelWidth = panel:GetWidth(), panelHeight = panel:GetHeight(),
            layoutWidth = frame:GetAttribute("UIPanelLayout-width"), layoutHeight = frame:GetAttribute("UIPanelLayout-height"),
            title = title, titlePoints = title and SavePoints(title), titleText = title and title:GetText(),
            alphas = {}, slots = {}, tabs = {},
        }
    end
    for _, method in ipairs({"GenerateItemSlotsForSelectedTab", "RefreshAllItemsForSelectedTab", "RefreshBankPanel", "RefreshBankTabs", "RequestTitleRefresh"}) do
        if not module:IsHooked(panel, method) then
            module:SecureHook(panel, method, function() module:RefreshBank() end)
        end
    end
    if not module:IsHooked(frame, "OnShow") then
        module:SecureHookScript(frame, "OnShow", function() module:RefreshBank() end)
    end
    return true
end

function module:EnableBank()
    -- Forever's native bank owns bag sockets and pages. The Retail grid would
    -- move these items out of their native pages, so retain that bank layout.
    if LUI.IsForever then return end
    module.bankIntegrationEnabled = true
    if not module.bankLoadWatcher then
        module.bankLoadWatcher = CreateFrame("Frame")
        module.bankLoadWatcher:SetScript("OnEvent", function()
            if module:AttachBankHooks() then
                module.bankLoadWatcher:UnregisterEvent("ADDON_LOADED")
                module:RefreshBank()
            end
        end)
    end
    if not module:IsHooked(module, "RefreshColors") then
        module:SecureHook(module, "RefreshColors", function() module:RefreshBank() end)
    end
    if module:AttachBankHooks() then module:RefreshBank()
    else module.bankLoadWatcher:RegisterEvent("ADDON_LOADED") end
end

function module:DisableBank()
    module.bankIntegrationEnabled = false
    if module.bankLoadWatcher then module.bankLoadWatcher:UnregisterAllEvents() end
    module:RestoreBankStyle()
end
