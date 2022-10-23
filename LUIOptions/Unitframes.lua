-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, Opt
local optName, Opt = ...
local L, module, db = Opt:GetLUIModule("Unitframes")
if not module then return end

-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################

local sizeValues = {softMin = 8, softMax = 64, min = 4, max = 255, step = 1}
local spacingValues = {softMin = -10, softMax = 10, step = 1}
local auraCountValues = {min = 1, max = 64, softMax = 36, step = 1}
local fontValues = {min = 4, max = 72, step = 1, softMin = 8, softMax = 36}

-- ####################################################################################################################
-- ##### Custom Controls ##############################################################################################
-- ####################################################################################################################

local powerColorTypes = {
    ["Individual"] = "Individual",
    ["By Class"] = "By Class",
    ["By Type"] = "By Type",
}

local healthColorTypes = {
    ["Individual"] = "Individual",
    ["By Class"] = "By Class",
    ["Gradient"] = "Gradient",
}

local function UnitFontMenuGetter(info)
    local unit = info[2]
    local fontName = info[3]
	local dbUnit = info.handler.db.profile[unit]
	local prop = info[#info]
	
	return dbUnit[fontName][prop]
end

local function UnitFontMenuSetter(info, value)
	local unit = info[2]
    local fontName = info[3]
	local dbUnit = info.handler.db.profile[unit]
	local prop = info[#info]

	dbUnit[fontName][prop] = value
end

local function UnitFontMenu(name, desc, order, disabled, hidden)
    local group = Opt:Group(name, desc, order, nil, disabled, hidden)
	group.args.Size = Opt:Slider("Size", nil, 1, sizeValues, nil, disabled, hidden, UnitFontMenuGetter, UnitFontMenuSetter)
	group.args.Name = Opt:MediaFont("Font", nil, 2, nil, disabled, hidden, UnitFontMenuGetter, UnitFontMenuSetter)
	group.args.Flag = Opt:Select("Outline", nil, 3, LUI.FontFlags, nil, disabled, hidden, UnitFontMenuGetter, UnitFontMenuSetter)
	group.inline = true
	return group
end

--- Function to determine if the Individual Color option should be disabled
---@param dbOpt table @ db table of the color to look up
---@param select string @ if the Color select has a different name than "Color"
---@return function
local function IsIndividualColorSelected(dbOpt, colorSelect)
    colorSelect = colorSelect or "Color"
    return function(info) return dbOpt[colorSelect] ~= "Individual" end
end

-- ####################################################################################################################
-- ##### Options Tables ###############################################################################################
-- ####################################################################################################################

Opt.options.args.Unitframes = Opt:Group("Unitframes", nil, nil, "tab")
Opt.options.args.Unitframes.handler = module

Opt.options.args.Unitframes.args.Header = Opt:Header("Unitframes", 1)

local function GenerateBarGroup(unit, name, colorTypes, order)
    local dbBar = db[unit][name]
    if not dbBar then return end    -- If that unit does not have options for that bar, nil it

    local optName = string.gsub(name, "Bar", " Bar")
    local group = Opt:Group(optName, nil, order, nil, nil, nil, Opt.GetSet(dbBar))
    group.args = {
        Enable = Opt:Toggle("Enabled", nil, 1, nil, "full"),
        Width = Opt:Input("Width", nil, 2),
        Height = Opt:Input("Height", nil, 3),
        X = Opt:Input("X Value", nil, 4),
        Y = Opt:Input("Y Value", nil, 5),
        Texture = Opt:MediaStatusbar("Bar Texture", nil, 7),
        TextureBG = Opt:MediaStatusbar("Background Texture", nil, 8),
        Smooth = Opt:Toggle("Smooth Gradient", nil, 9),
        BGAlpha = Opt:Slider("Background Alpha", nil, 10, Opt.PercentValues),
        BGInvert = Opt:Toggle("Invert Background", nil, 11, nil, "full"),
        Color = Opt:Select("Color Type", nil, 12, colorTypes),
        IndividualColor = Opt:Color(optName.." Color", nil, 13, false, nil, IsIndividualColorSelected(dbBar), nil, Opt.ColorGetSet(dbBar))
    }
    --- Prevent disabling Healthbar
    if name == "HealthBar" then
        group.args.Enable = nil
    end

    return group
end

local function GenerateTextGroup(unit, name, colorTypes, order)
    local dbText = db[unit][name]
    if not dbText then return end    -- If that unit does not have options for that bar, nil it

    local optName = string.gsub(name, "Text", " Text")
    local group = Opt:Group(optName, nil, order, nil, nil, nil, Opt.GetSet(dbText))
    group.args = {
        Enable = Opt:Toggle("Enabled", nil, 1, nil, "full"),
        X = Opt:Input("X Value", nil, 4),
        Y = Opt:Input("Y Value", nil, 5),
        Point = Opt:Select(L["Anchor"], nil, 6, LUI.Points),
        RelativePoint = Opt:Select("Attach To", nil, 7, LUI.Points),
        Font = UnitFontMenu("Text Font", nil, 20),
        Color = Opt:Select("Color Type", nil, 12, colorTypes),
        IndividualColor = Opt:Color(optName.." Color", nil, 13, false, nil, IsIndividualColorSelected(dbText), nil, Opt.ColorGetSet(dbText))
    }
    ---@FIXME: Streamline those options to be more Common
    if dbText.ShowAlways then 
        group.args.ShowAlways = Opt:Toggle("Show when full", nil, 31)
    end
    if dbText.ShowDead then 
        group.args.ShowDead = Opt:Toggle("Show when dead", nil, 32)
    end
    if dbText.ShowFull then 
        group.args.ShowFull = Opt:Toggle("Show when full", nil, 31)
        group.args.ShowEmpty = Opt:Toggle("Show when empty", nil, 32)
    end

    if name == "NameText" then
        group.args.ColorNameByClass = Opt:Toggle("Color Name By Class", nil, 41)
        group.args.ColorClassByClass = Opt:Toggle("Color Color By Class", nil, 42)
        group.args.ColorLevelByDifficulty = Opt:Toggle("Color Level By Difficulty", nil, 43)
        group.args.ShowClassification = Opt:Toggle("Show Classification", nil, 44)
        group.args.ShortClassification = Opt:Toggle("Short Classification", nil, 45)
        group.args.Color = nil
    end

    if name == "CombatFeedback" then
        group.args.ShowDamage = Opt:Toggle("Show Damage", nil, 41)
        group.args.ShowHeal = Opt:Toggle("Show Healing", nil, 42)
        group.args.ShowImmune = Opt:Toggle("Show Immune", nil, 43)
        group.args.ShowEnergize = Opt:Toggle("Show Power Gains", nil, 44)
        group.args.ShowOther = Opt:Toggle("Show Others", nil, 45)
        group.args.MaxAlpha = Opt:Slider("Text Opacity", nil, 46, Opt.PercentValues)
        group.args.IndividualColor = nil
        group.args.Color = nil
    end

    return group
end

local function GenerateClassBarGroup(unit, name, order)
    local dbBar = db[unit][name]
    if not dbBar then return end    -- If that unit does not have options for that bar, nil it

    local optName = string.gsub(name, "Bar", " Bar")
    local group = Opt:Group(optName, nil, order, nil, nil, nil, Opt.GetSet(dbBar))
    group.args = {
        Enable = Opt:Toggle("Enabled", nil, 1, nil, "full"),
        Width = Opt:Input("Width", nil, 2),
        Height = Opt:Input("Height", nil, 3),
        X = Opt:Input("X Value", nil, 4),
        Y = Opt:Input("Y Value", nil, 5),
        Texture = Opt:MediaStatusbar("Bar Texture", nil, 6),
        Lock = Opt:Toggle("Lock", nil, 7, nil, "full"),
        Padding = Opt:Slider("Padding", nil, 8, {min=1, max=10, step=1}),
        -- Color = Opt:Select("Color Type", nil, 12, colorTypes),
        -- IndividualColor = Opt:Color(optName.." Color", nil, 13, false, nil, IsIndividualColorSelected(dbBar), nil, Opt.ColorGetSet(dbBar))
    }

    if name == "TotemsBar" then
        group.args.IconScale = Opt:Slider("Icon Scale", "Choose the size multiplier for the totem icons. Values above 100% will make the icon go above the bar's height.", 12, Opt.ScaleValues)
    end

    return group
end

local function GenerateIndicatorGroup(unit, name, order)
    local dbIcon = db[unit][name]
    if not dbIcon then return end    -- If that unit does not have options for that bar, nil it

    local optName = string.gsub(name, "Indicator", " Indicator")
    local group = Opt:Group(name, nil, order, nil, nil, nil, Opt.GetSet(dbIcon))
    group.args = {
        Enable = Opt:Toggle("Enabled", nil, 1, nil, "full"),
        X = Opt:Input("X Value", nil, 2),
        Y = Opt:Input("Y Value", nil, 3),
        Size = Opt:Slider("Size", nil, 4, sizeValues),
        Point = Opt:Select(L["Anchor"], nil, 5, LUI.Points),
    }

    return group
end

local function NewUnitOptionGroup(unit, order)
    local isPlayer = (unit == "player")
    local dbUnit = db[unit]

    local unitOptions = Opt:Group(unit, nil, order, "tree")
    unitOptions.args.General = Opt:Group("General", nil, 1, nil, nil, nil, Opt.GetSet(dbUnit))
    unitOptions.args.General.args = {
        Position = Opt:Header("Position", 1),
        X = Opt:Input("X Value", nil, 2),
        Y = Opt:Input("Y Value", nil, 3),
        Point = Opt:Select(L["Anchor"], nil, 4, LUI.Points),
        Scale = Opt:Slider("Scale", nil, 5, Opt.ScaleValues),
    }

    unitOptions.args.HealthBar = GenerateBarGroup(unit, "HealthBar", healthColorTypes, 3)
    unitOptions.args.PowerBar = GenerateBarGroup(unit, "PowerBar", powerColorTypes, 4)
    
    if unit == "player" then 
        unitOptions.args.ClassPowerBar = GenerateClassBarGroup(unit, "ClassPowerBar", 5)
        if LUI.DEATHKNIGHT then unitOptions.args.RunesBar = GenerateClassBarGroup(unit, "RunesBar", 6) end
        if LUI.SHAMAN then unitOptions.args.TotemsBar = GenerateClassBarGroup(unit, "TotemsBar", 7) end
        --  unitOptions.args.TotalAbsorbBar = Opt:Group("Total TotalAbsorb Bar", nil, 6, nil, nil, nil, Opt.GetSet(dbUnit))
        --  unitOptions.args.HealthPredictionBar = Opt:Group("Health Prediction Bar", nil, 7, nil, nil, nil, Opt.GetSet(dbUnit))
    end

    unitOptions.args.AdditionalPowerBar = GenerateBarGroup(unit, "AdditionalPowerBar", powerColorTypes, 10)
    unitOptions.args.AlternativePowerBar = GenerateBarGroup(unit, "AlternativePowerBar", powerColorTypes, 10)
    

    -- Use a single entry to handle Value, Percent and Missing?
    if dbUnit.NameText then unitOptions.args.NameText = GenerateTextGroup(unit, "NameText", nil, 20) end
    if dbUnit.HealthText then unitOptions.args.HealthText = GenerateTextGroup(unit, "HealthText", healthColorTypes, 21) end
    if dbUnit.PowerText then unitOptions.args.PowerText = GenerateTextGroup(unit, "PowerText", powerColorTypes, 22) end
    if dbUnit.HealthPercentText then unitOptions.args.PowerText = GenerateTextGroup(unit, "HealthPercentText", healthColorTypes, 23) end
    if dbUnit.HealthMissingText then unitOptions.args.PowerText = GenerateTextGroup(unit, "HealthMissingText", healthColorTypes, 24) end
    if dbUnit.PowerPercentText then unitOptions.args.PowerText = GenerateTextGroup(unit, "PowerPercentText", powerColorTypes, 25) end
    if dbUnit.PowerMissingText then unitOptions.args.PowerText = GenerateTextGroup(unit, "PowerMissingText", powerColorTypes, 26) end
    if dbUnit.CombatFeedback then
        unitOptions.args.CombatFeedback = GenerateTextGroup(unit, "CombatFeedback", nil, 27)
    end
    
    if dbUnit.Portrait then
        unitOptions.args.Portrait = Opt:Group("Portrait", nil, 30, nil, nil, nil, Opt.GetSet(dbUnit.Portrait))
        unitOptions.args.Portrait.args = {
            Enable = Opt:Toggle("Enabled", nil, 1, nil, "full"),
            Width = Opt:Input("Width", nil, 2),
            Height = Opt:Input("Height", nil, 3),
            X = Opt:Input("X Value", nil, 4),
            Y = Opt:Input("Y Value", nil, 5),
            --Point = Opt:Select(L["Anchor"], nil, 6, LUI.Points),
            Alpha = Opt:Slider("Alpha", nil, 7, Opt.PercentValues),
        }
    end
    
    if dbUnit.Aura.Buffs then
        unitOptions.args.Buffs = Opt:Group("Buffs", nil, 31, nil, nil, nil, Opt.GetSet(dbUnit.Aura.Buffs))
        unitOptions.args.Buffs.args = {
            ColorByType = Opt:Toggle("Color By Type", nil, 1),
            PlayerOnly = Opt:Toggle("Player Only", nil, 2),
            IncludePet = Opt:Toggle("Include Pet", nil, 3),
            AuraTimer = Opt:Toggle("Aura Timer", nil, 4),
            DisableCooldown = Opt:Toggle("Disable Cooldown", nil, 5),
            CooldownReverse = Opt:Toggle("Cooldown Reverse", nil, 6),
            X = Opt:Input("X Value", nil, 7),
            Y = Opt:Input("Y Value", nil, 8),
            InitialAnchor = Opt:Select(L["Anchor"], nil, 9, LUI.Points),
            GrowthX = Opt:Select("Horizontal Growth", nil, 10, LUI.Directions),
            GrowthY = Opt:Select("Vertical Growth", nil, 10, LUI.Directions),
            Size = Opt:Slider("Size", nil, 11, sizeValues),
            Spacing = Opt:Slider("Spacing", nil, 12, spacingValues),
            Num = Opt:Slider("Amount of Buffs", nil, 13, auraCountValues),
        }
        unitOptions.args.Debuffs = Opt:Group("Debuffs", nil, 32, nil, nil, nil, Opt.GetSet(dbUnit.Aura.Debuffs))
        unitOptions.args.Debuffs.args = {
            ColorByType = Opt:Toggle("Color By Type", nil, 1),
            PlayerOnly = Opt:Toggle("Player Only", nil, 2),
            IncludePet = Opt:Toggle("Include Pet", nil, 3),
            AuraTimer = Opt:Toggle("Aura Timer", nil, 4),
            DisableCooldown = Opt:Toggle("Disable Cooldown", nil, 5),
            CooldownReverse = Opt:Toggle("Cooldown Reverse", nil, 6),
            X = Opt:Input("X Value", nil, 7),
            Y = Opt:Input("Y Value", nil, 8),
            InitialAnchor = Opt:Select(L["Anchor"], nil, 9, LUI.Points),
            GrowthX = Opt:Select("Horizontal Growth", nil, 10, LUI.Directions),
            GrowthY = Opt:Select("Vertical Growth", nil, 10, LUI.Directions),
            Size = Opt:Slider("Size", nil, 11, sizeValues),
            Spacing = Opt:Slider("Spacing", nil, 12, spacingValues),
            Num = Opt:Slider("Amount of Debuffs", nil, 13, auraCountValues),
        }
    end

    if dbUnit.LeaderIndicator then unitOptions.args.LeaderIndicator = GenerateIndicatorGroup("Leader Icon", 50, Opt.GetSet(dbUnit.LeaderIndicator)) end
    if dbUnit.GroupRoleIndicator then unitOptions.args.GroupRoleIndicator = GenerateIndicatorGroup("Role Icon", 51, Opt.GetSet(dbUnit.GroupRoleIndicator)) end
    if dbUnit.RaidMarkerIndicator then unitOptions.args.RaidMarkerIndicator = GenerateIndicatorGroup("Raid Icon", 52, Opt.GetSet(dbUnit.RaidMarkerIndicator)) end
    if dbUnit.PvPIndicator then unitOptions.args.PvPIndicator = GenerateIndicatorGroup("PvP Icon", 53, Opt.GetSet(dbUnit.PvPIndicator)) end
    if dbUnit.RestingIndicator then unitOptions.args.RestingIndicator = GenerateIndicatorGroup("Resting Icon", 54, Opt.GetSet(dbUnit.RestingIndicator)) end
    if dbUnit.ReadyCheckIndicator then unitOptions.args.ReadyCheckIndicator = GenerateIndicatorGroup("Ready Check Icon", 54, Opt.GetSet(dbUnit.ReadyCheckIndicator)) end


    return unitOptions
end

for i = 1, #module.unitsSpawn do
    local unit = module.unitsSpawn[i]
    local t = NewUnitOptionGroup(unit, i+10)
    Opt.options.args.Unitframes.args[unit] = t
end