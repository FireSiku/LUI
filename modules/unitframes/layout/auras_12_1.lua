--[[
LUI Unitframes - WoW 12.1 AuraContainer integration

Aura data is deliberately never read by addon Lua. Blizzard's AuraContainer owns
filtering, updates, secure/secret aura state and AuraButton creation.
]]

---@class LUIAddon
local LUI = select(2, ...)
local module = LUI:GetModule("Unitframes")
local Media = LibStub("LibSharedMedia-3.0")

local function BuildFilter(kind, db)
    local filter = kind == "Buffs" and "HELPFUL" or "HARMFUL"
    return db.PlayerOnly and (filter .. "|PLAYER") or filter
end

local function BuildLayout(db)
    return {
        elementWidth = db.Size,
        elementHeight = db.Size,
        elementSpacing = db.Spacing or 0,
        lineSpacing = db.Spacing or 0,
    }
end

local function GetContainerLayoutLimit(db)
    local total = math.max(tonumber(db.Num) or 8, 1)
    local perRow = math.min(math.max(tonumber(db.IconsPerRow) or total, 1), total)
    local size = tonumber(db.Size) or 1
    local spacing = tonumber(db.Spacing) or 0

    return math.max(size, perRow * size + (perRow - 1) * spacing)
end

local function ApplyButtonAppearance(button, db)
    -- Assigned 12.1 aura buttons may become explicitly forbidden even when
    -- InCombatLockdown() briefly reports false during a reload while dead.
    -- Their layout is updated through SetAuraGroupLayout below; direct region
    -- mutations must wait until Blizzard exposes the button again.
    if button.IsForbidden and button:IsForbidden() then return end

    local settings = module.db.profile.Settings

    button.Cooldown:SetReverse(db.CooldownReverse == true)
    button.Cooldown:SetAlpha(db.DisableCooldown == true and 0 or 1)

    button.Time:SetAlpha(db.AuraTimer == true and 1 or 0)
    button.Time:SetFont(
        Media:Fetch("font", settings.AuratimerFont),
        settings.AuratimerSize,
        settings.AuratimerFlag
    )

    button.AuraTypeHolder:SetAlpha(db.ColorByType == true and 1 or 0)
end

local function MakeInitializer(state, kind)
    return function(button)
        local db = state.db
        button:SetSize(db.Size, db.Size)

        local background = button:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints(button)
        background:SetColorTexture(0, 0, 0, 1)

        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
        icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        button:SetIcon(icon)

        local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
        cooldown:SetPoint("TOPLEFT", icon, "TOPLEFT")
        cooldown:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT")
        cooldown:SetHideCountdownNumbers(true)
        cooldown:SetDrawEdge(false)
        cooldown:SetDrawBling(false)
        button.Cooldown = cooldown
        button:SetDurationCooldown(cooldown)

        local textParent = CreateFrame("Frame", nil, button)
        textParent:SetAllPoints(button)
        textParent:SetFrameLevel(cooldown:GetFrameLevel() + 1)

        local count = textParent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
        button.Count = count
        button:SetApplicationCount(count, {})

        local timer = textParent:CreateFontString(nil, "OVERLAY")
        timer:SetPoint("CENTER", button, "CENTER")
        button.Time = timer
        button:SetDurationText(timer, {})

        local auraTypeHolder = CreateFrame("Frame", nil, button)
        auraTypeHolder:SetAllPoints(button)
        auraTypeHolder:SetFrameLevel(button:GetFrameLevel() + 2)
        button.AuraTypeHolder = auraTypeHolder

        local auraType = auraTypeHolder:CreateTexture(nil, "OVERLAY")
        auraType:SetTexture([[Interface\AddOns\LUI\media\buttons\ufAura.tga]])
        auraType:SetPoint("TOPLEFT", button, "TOPLEFT", -2, 2)
        auraType:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
        auraType:SetTexCoord(0, 1, 0.02, 1)
        button.AuraType = auraType
        button:AddDispelTypeTexture(auraType, {
            showWhenHarmful = kind == "Debuffs",
            showWhenHelpful = kind == "Buffs",
            showWithoutDispelType = false,
            -- Keep LUI's original outer aura frame. Blizzard securely applies
            -- the dispel color without replacing it with the inset border atlas.
            style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
        })

        button:SetTooltipAnchorPoint("ANCHOR_BOTTOMRIGHT", 0, 0)
        ApplyButtonAppearance(button, db)
    end
end

local function RefreshButtonAppearance(container, db)
    local key = container.__luiKey
    local count = container:GetAuraGroupFrameCount(key)

    -- The public accessors enumerate Blizzard's preallocated buttons without
    -- reading aura data. ApplyButtonAppearance skips any button that is still
    -- explicitly forbidden after a combat reload.
    for index = 1, count do
        local button = container:GetAuraGroupFrame(key, index)
        if button then ApplyButtonAppearance(button, db) end
    end
end

local function ResolveUnit(owner, fallbackUnit)
    local unit = owner.__unit
    if type(unit) == "string" and not issecretvalue(unit) then
        return unit
    end

    unit = owner:GetAttribute("unit")
    if type(unit) == "string" and not issecretvalue(unit) then
        return unit
    end

    return fallbackUnit
end

local function CreateContainer(owner, unit, kind, db)
    local state = {db = db}
    local containerWidth = GetContainerLayoutLimit(db)
    local container = owner:CreateAuras({
        initialAnchor = db.InitialAnchor,
        growthX = db.GrowthX,
        growthY = db.GrowthY,
        layoutLimit = containerWidth,
    })

    if container.SetFlowLayoutMaximumLineSize then
        container:SetFlowLayoutMaximumLineSize(containerWidth)
    end

    container:ClearAllPoints()
    container:SetPoint(
        db.InitialAnchor,
        owner,
        db.InitialAnchor,
        db.X or 0,
        db.Y or 0
    )

    container:SetUnit(unit)

    local key = container:AddGroup(
        BuildFilter(kind, db),
        {
            maxFrameCount = db.Num or 8,
            initializeFrame = MakeInitializer(state, kind),
            layout = BuildLayout(db),
        }
    )

    if container.SetFlowLayoutAnchorPoint then
        container:SetFlowLayoutAnchorPoint(
            db.InitialAnchor or "BOTTOMLEFT"
        )
    end

    if container.SetFlowLayoutGrowthDirection
        and AnchorUtil
        and AnchorUtil.FlowDirection
    then
        container:SetFlowLayoutGrowthDirection(
            db.GrowthX == "LEFT" and -1 or 1,
            db.GrowthY == "DOWN" and -1 or 1
        )
    end

    container:SetEnabled(true)
    container:Show()
    container:UpdateAllAuras()

    container.__luiKey = key
    container.__luiState = state
    container.__luiManaged = true

    return container
end

local function Apply(owner, unit, kind, db)
    unit = ResolveUnit(owner, unit)
    local containerWidth = GetContainerLayoutLimit(db)

    local field = kind
    local container = owner[field]

    if not container or not container.__luiManaged then
        owner[field] = CreateContainer(owner, unit, kind, db)
        return
    end

    container.__luiState.db = db

    container:ClearAllPoints()
    container:SetPoint(
        db.InitialAnchor,
        owner,
        db.InitialAnchor,
        db.X or 0,
        db.Y or 0
    )

    container:SetAuraGroupFilterString(
        container.__luiKey,
        BuildFilter(kind, db)
    )
    container:SetAuraGroupCandidateFilters(
        container.__luiKey,
        nil
    )
    container:SetAuraGroupMaxFrameCount(
        container.__luiKey,
        db.Num or 8
    )
    container:SetAuraGroupLayout(
        container.__luiKey,
        BuildLayout(db)
    )

    if container.SetFlowLayoutMaximumLineSize then
        container:SetFlowLayoutMaximumLineSize(containerWidth)
    end
    if container.SetFlowLayoutAnchorPoint then
        container:SetFlowLayoutAnchorPoint(
            db.InitialAnchor or "BOTTOMLEFT"
        )
    end
    if container.SetFlowLayoutGrowthDirection then
        container:SetFlowLayoutGrowthDirection(
            db.GrowthX == "LEFT" and -1 or 1,
            db.GrowthY == "DOWN" and -1 or 1
        )
    end

    -- Do not compare AuraContainer:GetUnit(): unit identity can be secret.
    -- SetUnit is the supported container API and is safe to call with our
    -- resolved public unit token.
    container:SetUnit(unit)

    RefreshButtonAppearance(container, db)
    container:SetEnabled(true)
    container:Show()
    container:UpdateAllAuras()
end

module.funcs.Buffs = function(self, unit, oufdb)
    Apply(
        self,
        unit,
        "Buffs",
        oufdb.Aura.Buffs
    )
end

module.funcs.Debuffs = function(self, unit, oufdb)
    Apply(
        self,
        unit,
        "Debuffs",
        oufdb.Aura.Debuffs
    )
end
