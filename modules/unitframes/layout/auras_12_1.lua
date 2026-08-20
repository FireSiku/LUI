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
    if db.PlayerOnly and not db.IncludePet then
        filter = filter .. "|PLAYER"
    end
    return filter
end

local function BuildCandidateFilters(db)
    if db.PlayerOnly and db.IncludePet then
        return {isFromPlayerOrPlayerPet = true}
    end

    return {}
end

local function BuildLayout(db)
    return {
        elementWidth = db.Size,
        elementHeight = db.Size,
        elementSpacing = db.Spacing or 0,
        lineSpacing = db.Spacing or 0,
    }
end

local function GetContainerSize(db)
    local total = math.max(tonumber(db.Num) or 8, 1)
    local perRow = math.min(math.max(tonumber(db.IconsPerRow) or total, 1), total)
    local size = tonumber(db.Size) or 1
    local spacing = tonumber(db.Spacing) or 0
    local rows = math.ceil(total / perRow)

    local width = math.max(size, perRow * size + (perRow - 1) * spacing)
    local height = math.max(size, rows * size + (rows - 1) * spacing)
    return width, height
end

local function ConfigureButton(button, state)
    local db = state.db
    local settings = module.db.profile.Settings

    button:SetSize(db.Size, db.Size)

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
        auraType:SetAllPoints(button)
        button.AuraType = auraType
        button:AddDispelTypeTexture(auraType, {
            showWhenHarmful = kind == "Debuffs",
            showWhenHelpful = kind == "Buffs",
            showWithoutDispelType = false,
            style = Enum.CustomAuraButtonDispelTypeTextureStyle.Border,
        })

        button:SetTooltipAnchorPoint("ANCHOR_BOTTOMRIGHT", 0, 0)
        ConfigureButton(button, state)
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
    local containerWidth, containerHeight = GetContainerSize(db)
    local container = owner:CreateAuras({
        initialAnchor = db.InitialAnchor,
        growthX = db.GrowthX,
        growthY = db.GrowthY,
        layoutLimit = containerWidth,
    })

    container:SetSize(containerWidth, containerHeight)

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
            candidateFilters = BuildCandidateFilters(db),
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
    local containerWidth, containerHeight = GetContainerSize(db)

    local field = kind
    local container = owner[field]

    if not container or not container.__luiManaged then
        owner[field] = CreateContainer(owner, unit, kind, db)
        return
    end

    container.__luiState.db = db
    container:SetSize(containerWidth, containerHeight)
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
        BuildCandidateFilters(db)
    )
    container:SetAuraGroupMaxFrameCount(
        container.__luiKey,
        db.Num or 8
    )
    container:SetAuraGroupLayout(
        container.__luiKey,
        BuildLayout(db)
    )

    container:SetFlowLayoutMaximumLineSize(containerWidth)
    container:SetFlowLayoutAnchorPoint(
        db.InitialAnchor or "BOTTOMLEFT"
    )
    container:SetFlowLayoutGrowthDirection(
        db.GrowthX == "LEFT" and -1 or 1,
        db.GrowthY == "DOWN" and -1 or 1
    )

    for index = 1, container:GetAuraGroupFrameCount(container.__luiKey) do
        local button = container:GetAuraGroupFrame(container.__luiKey, index)
        if button then
            ConfigureButton(button, container.__luiState)
        end
    end

    if container:GetUnit() ~= unit then
        container:SetUnit(unit)
    else
        container:ForceUpdate()
    end

    container:SetEnabled(true)
    container:Show()
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
