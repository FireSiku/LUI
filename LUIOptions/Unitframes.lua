-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class Opt
local Opt = select(2, ...)

---@type AceLocale.Localizations, LUI.Unitframes, AceDB-3.0
local L, module, db = Opt:GetLUIModule("Unitframes")
if not module or not module.registered then return end

local Unitframes = Opt:CreateModuleOptions("Unitframes", module)

-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################

local sizeValues = {softMin = 8, softMax = 64, min = 4, max = 255, step = 1}
local spacingValues = {softMin = -10, softMax = 10, step = 1}
local auraCountValues = {min = 1, max = 64, softMax = 36, step = 1}
local fontValues = {min = 4, max = 72, step = 1, softMin = 8, softMax = 36}

-- oUF cannot receive event-driven cast updates for compound target tokens such
-- as focustarget, bosstarget or maintanktargettarget.
local function UnitSupportsCastbar(unit)
    return not unit:match(".+target$")
end

local relativeUnits = {
    partytarget = true,
    partypet = true,
    bosstarget = true,
    arenatarget = true,
    arenapet = true,
    maintanktarget = true,
    maintanktargettarget = true,
}

local supportsClassPower = LUI.DRUID or LUI.PALADIN or LUI.MONK or LUI.ROGUE or LUI.WARLOCK or LUI.MAGE or LUI.EVOKER
local supportsAdditionalPower = LUI.DRUID or LUI.PRIEST or LUI.SHAMAN

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

local valueFormat = {
    ["Standard"] = "Standard",
    ["Standard Short"] = "Standard Short",
    ["Standard & Percent"] = "Standard & Percent",
    ["Standard Short & Percent"] = "Standard Short & Percent",
    ["Absolut"] = "Absolute",
    ["Absolut Short"] = "Absolute Short",
    ["Absolut & Percent"] = "Absolute & Percent",
    ["Absolut Short & Percent"] = "Absolute Short & Percent",
}

local auxiliaryPowerFormat = {
    ["Standard"] = "Standard",
    ["Absolut"] = "Absolute",
    ["Percent"] = "Percent",
}

local nameFormats = {
    ["Name"] = "Name",
    ["Name + Level"] = "Name + Level",
    ["Name + Level + Class"] = "Name + Level + Class",
    ["Name + Level + Race + Class"] = "Name + Level + Race + Class",
    ["Level"] = "Level",
    ["Level + Name"] = "Level + Name",
    ["Level + Name + Class"] = "Level + Name + Class",
    ["Level + Class + Name"] = "Level + Class + Name",
    ["Level + Race + Class + Name"] = "Level + Race + Class + Name",
}


local function UnitFontMenuGetter(info)
    local unit = info[2]
    local fontName = info[3]
	local dbUnit = info.handler.db.profile[unit]
	local prop = info[#info]
	
    -- HACK: Untill fonts are centralized inside Unitframes
    if fontName == "CastbarNameText" or fontName == "CastbarTimeText" then
        dbUnit = info.handler.db.profile[unit].Castbar
        fontName = string.sub(fontName, 8)
    end

	return dbUnit[fontName][prop]
end

local function UnitFontMenuSetter(info, value)
	local unit = info[2]
    local fontName = info[3]
	local dbUnit = info.handler.db.profile[unit]
	local prop = info[#info]

    -- HACK: Untill fonts are centralized inside Unitframes
    if fontName == "CastbarNameText" or fontName == "CastbarTimeText" then
        dbUnit = info.handler.db.profile[unit].Castbar
        fontName = string.sub(fontName, 8)
    end

	dbUnit[fontName][prop] = value

    if info.handler.Refresh then
        info.handler:Refresh()
    end
end

local function UnitFontMenu(name, desc, order, disabled, hidden)
    local group = Opt:Group(name, desc, order, nil, disabled, hidden)
	group.args.Size = Opt:Slider({name = "Size", values = sizeValues, disabled = disabled, hidden = hidden, get = UnitFontMenuGetter, set = UnitFontMenuSetter})
	group.args.Font = Opt:MediaFont({name = "Font", disabled = disabled, hidden = hidden, get = UnitFontMenuGetter, set = UnitFontMenuSetter})
	group.args.Outline = Opt:Select({name = "Outline", values = LUI.FontFlags, disabled = disabled, hidden = hidden, get = UnitFontMenuGetter, set = UnitFontMenuSetter})
	group.inline = true
	return group
end

--- Function to determine if the Individual Color option should be disabled
---@param dbOpt table @ db table of the color to look up
---@param colorSelect string @ if the Color select has a different name than "Color"
---@return function
local function IsIndividualColorSelected(dbOpt, colorSelect)
    colorSelect = colorSelect or "Color"
    return function(info) return dbOpt[colorSelect] ~= "Individual" end
end

-- ####################################################################################################################
-- ##### Options Tables ###############################################################################################
-- ####################################################################################################################

local function GenerateBarGroup(unit, name, colorTypes, order)
    local dbBar = db[unit][name]
    if not dbBar then return end    -- If that unit does not have options for that bar, nil it

    local optName = string.gsub(name, "Bar", " Bar")
    local group = Opt:Group({name = optName, db = dbBar, args = {
        Enable = Opt:Toggle({name = "Enabled", width = "full"}),
        Width = Opt:InputNumber({name = "Width"}),
        Height = Opt:InputNumber({name = "Height"}),
        X = Opt:InputNumber({name = "X Value"}),
        Y = Opt:InputNumber({name = "Y Value"}),
        Texture = Opt:MediaStatusbar({name = "Bar Texture"}),
        TextureBG = Opt:MediaStatusbar({name = "Background Texture"}),
        Smooth = Opt:Toggle({name = "Smooth Gradient"}),
        BGAlpha = Opt:Slider({name = "Background Alpha", values = Opt.PercentValues}),
        BGMultiplier = Opt:Slider({name = "Background Multiplier", values = Opt.PercentValues, onlyIf = (dbBar.BGMultiplier ~= nil)}),
        BGInvert = Opt:Toggle({name = "Invert Background", width = "full", onlyIf = (dbBar.BGInvert ~= nil)}),
        Tapping = Opt:Toggle({name = "Use tapping color", onlyIf = (dbBar.Tapping ~= nil)}),
        OverPower = Opt:Toggle({name = "Overlay the main power bar", onlyIf = (dbBar.OverPower ~= nil)}),
        Color = Opt:Select({name = "Color Type", values = colorTypes}),
        IndividualColor = Opt:Color({name = optName.." Color", hasAlpha = false, disabled = IsIndividualColorSelected(dbBar), db = dbBar})
    }})
    --- Prevent disabling Healthbar
    if name == "HealthBar" then
        group.args.Enable = nil
    end

    return group
end

local function GenerateHealthPredictionGroup(unit)
    local dbBar = db[unit].HealthPredictionBar
    if not dbBar then return end

    return Opt:Group({name = "Heal Prediction Bar", db = dbBar, args = {
        Enable = Opt:Toggle({name = "Enabled", width = "full"}),
        Texture = Opt:MediaStatusbar({name = "Bar Texture"}),
        MyColor = Opt:Color({name = "Own Heals", hasAlpha = true, db = dbBar}),
        OtherColor = Opt:Color({name = "Other Heals", hasAlpha = true, db = dbBar}),
    }})
end

local function GenerateTotalAbsorbGroup(unit)
    local dbBar = db[unit].TotalAbsorbBar
    if not dbBar then return end

    return Opt:Group({name = "Absorb Bar", db = dbBar, args = {
        Enable = Opt:Toggle({name = "Enabled", width = "full"}),
        Texture = Opt:MediaStatusbar({name = "Bar Texture"}),
        MyColor = Opt:Color({name = "Absorb Color", hasAlpha = true, db = dbBar}),
    }})
end

local function GenerateTextGroup(unit, name, colorTypes, order)
    local dbText = db[unit][name]
    if not dbText then return end    -- If that unit does not have options for that bar, nil it

    local optName = string.gsub(name, "Text", " Text")
    local group = Opt:Group({name = optName, db = dbText, args = {
        Enable = Opt:Toggle({name = "Enabled", width = "full"}),
        X = Opt:InputNumber({name = "X Value"}),
        Y = Opt:InputNumber({name = "Y Value"}),
        Point = Opt:Select({name = L["Anchor"], values = LUI.Points}),
        RelativePoint = Opt:Select({name = "Attach To", values = LUI.Points}),
        Format = Opt:Select({name = "Format", desc = "Choose the Format for your "..unit.." Name.", values = nameFormats, onlyIf = (name == "NameText")}),
        Color = Opt:Select({name = "Color Type", values = colorTypes}),
        IndividualColor = Opt:Color({name = optName.." Color", hasAlpha = false, disabled = IsIndividualColorSelected(dbText), db = dbText}),
        Font = UnitFontMenu({name = "Text Font"}),
        ShowAlways = Opt:Toggle({name = "Show when full", onlyIf = (dbText.ShowAlways ~= nil)}),
        ShowDead = Opt:Toggle({name = "Show when dead", onlyIf = (dbText.ShowDead ~= nil)}),
        ShowFull = Opt:Toggle({name = unit..name.." Show when full", onlyIf = (dbText.ShowFull ~= nil)}),
        ShowEmpty = Opt:Toggle({name = "Show when empty", onlyIf = (dbText.ShowEmpty ~= nil)}),
        ShortValue = Opt:Toggle({name = "Short value", onlyIf = (dbText.ShortValue ~= nil)}),
    }})

    if name == "HealthText" or name == "PowerText" then
        group.args.Format = Opt:Select({name = "Format", values = valueFormat, onlyIf = (name == "HealthText" or name == "PowerText")})
    end

    if name == "NameText" then
        local disabledClassificationFunc = function() return not dbText.ShowClassification end

        group.args.ColorNameByClass = Opt:Toggle({name = "Color Name By Class"})
        group.args.ColorClassByClass = Opt:Toggle({name = "Color Class By Class"})
        group.args.ColorLevelByDifficulty = Opt:Toggle({name = "Color Level By Difficulty"})
        group.args.ShowClassification = Opt:Toggle({name = "Show Classification"})
        group.args.ShortClassification = Opt:Toggle({name = "Short Classification", disabled = disabledClassificationFunc})
        group.args.IndividualColor = nil
        group.args.Color = nil
    end

    if name == "CombatFeedback" then
        group.args.ShowDamage = Opt:Toggle({name = "Show Damage"})
        group.args.ShowHeal = Opt:Toggle({name = "Show Healing"})
        group.args.ShowImmune = Opt:Toggle({name = "Show Immune"})
        group.args.ShowEnergize = Opt:Toggle({name = "Show Power Gains"})
        group.args.ShowOther = Opt:Toggle({name = "Show Others"})
        group.args.MaxAlpha = Opt:Slider({name = "Text Opacity", values = Opt.PercentValues})
        group.args.IndividualColor = nil
        group.args.Color = nil
    end

    return group
end

local function GenerateClassBarGroup(unit, name, order)
    local dbBar = db[unit][name]
    if not dbBar then return end    -- If that unit does not have options for that bar, nil it

    local optName = string.gsub(name, "Bar", " Bar")
    local group = Opt:Group({name = optName, db = dbBar, args = {
        Enable = Opt:Toggle({name = "Enabled", width = "full"}),
        Width = Opt:InputNumber({name = "Width"}),
        Height = Opt:InputNumber({name = "Height"}),
        X = Opt:InputNumber({name = "X Value"}),
        Y = Opt:InputNumber({name = "Y Value"}),
        Texture = Opt:MediaStatusbar({name = "Bar Texture"}),
        Lock = Opt:Toggle({name = "Lock", width = "full"}),
        Padding = Opt:Slider({name = "Padding", min=1, max=10, step=1}),
        IconScale = Opt:Slider({name = "Icon Scale", desc = "Choose the size multiplier for the totem icons. Values above 100% will make the icon go above the bar's height.",
            values = Opt.ScaleValues, onlyIf=(name == "TotemsBar")}),
        Multiplier = Opt:Slider({name = "Background Multiplier", values = Opt.PercentValues, onlyIf=(name == "TotemsBar")})
    }})

    return group
end

local function GenerateIndicatorGroup(unit, name, order, get, set)
    if not get or not set then return end
    local optName = string.gsub(name, "Indicator", " Indicator")
    local group = Opt:Group({name = name, get = get, set = set, args = {
        Enable = Opt:Toggle({name = "Enabled", width = "full"}),
        X = Opt:InputNumber({name = "X Value"}),
        Y = Opt:InputNumber({name = "Y Value"}),
        Size = Opt:Slider({name = "Size", values = sizeValues}),
        Point = Opt:Select({name = L["Anchor"], values = LUI.Points}),
    }})

    return group
end

local function GenerateCastbarGroup(unit, order)
    local dbCast = db[unit].Castbar
    if not dbCast then return end    -- If that unit does not have options for that bar, nil it

    local colorGet, colorSet = Opt.ColorGetSet(dbCast.Colors)
    local nameGet, nameSet = Opt.GetSet(dbCast.NameText)
    local timeGet, timeSet = Opt.GetSet(dbCast.TimeText)

    local group = Opt:Group({name = "Cast Bar", db = dbCast.General, args = {
        Enable = Opt:Toggle({name = "Enabled", width = "full"}),
        Width = Opt:InputNumber({name = "Width"}),
        Height = Opt:InputNumber({name = "Height"}),
        X = Opt:InputNumber({name = "X Value"}),
        Y = Opt:InputNumber({name = "Y Value"}),
        Point = Opt:Select({name = "Anchor Point", values = LUI.Points}),
        IndividualColor = Opt:Toggle({name = "Individual Color", desc = "If unchecked, desc = Class Color will be used", width = "full"}),
        Icon = Opt:Toggle({name = "Show Icon", width = "full"}),
        Shielded = Opt:Toggle({name = "Show Shielded Casts", desc = "Whether you want to show casts you cannot interrupt.", width = "full",
            get = function() return dbCast.General.Shield end,
            set = function(info, value)
                dbCast.General.Shield = value
                if info.handler.Refresh then info.handler:Refresh() end
            end}),
        AestheticHeader = Opt:Header({name = "Appearance"}),
        Texture = Opt:MediaStatusbar({name = "Bar Texture"}),
        TextureBG = Opt:MediaStatusbar({name = "Background Texture"}),
        --HACK: Using manual Get/Set for the Border options until they can be renamed
        BorderTexture = Opt:MediaBorder({name = "Border Texture", get = function() return dbCast.Border.Texture end,
            set = function(info, value) -- BorderTexture Set 
                dbCast.Border.Texture = value
                if info.handler.Refresh then info.handler:Refresh() end
            end}),
        BorderThickness = Opt:InputNumber({name = "Border Thickness", get = function() return dbCast.Border.Thickness end,
            set = function(info, value) -- BorderThickness Set
                dbCast.Border.Thickness = value
                if info.handler.Refresh then info.handler:Refresh() end
            end}),
        ColorHeader = Opt:Header({name = "Appearance"}),
        Bar = Opt:Color({name = "Castbar Color", hasAlpha = true, get = colorGet, set = colorSet}),
        Background = Opt:Color({name = "Background Color", hasAlpha = true, get = colorGet, set = colorSet}),
        Border = Opt:Color({name = "Border Color", hasAlpha = true, get = colorGet, set = colorSet}),
        Shield = Opt:Color({name = "Shield Color", hasAlpha = true, get = colorGet, set = colorSet}),
    }})

    return group
end

local function GenerateCastbarTextGroup(unit, name, order)
    local dbCast = db[unit].Castbar
    if not dbCast then return end    -- If that unit does not have options for that bar, nil it

    local optName = string.gsub("Cast Bar "..name, "Text", " Text")

    local colorKey = name == "NameText" and "Name" or "Time"
    local colorGet, colorSet = Opt.ColorGetSet(dbCast.Colors)
    local args = {
        Enable = Opt:Toggle({name = "Enabled", width = "full"}),
        OffsetX = Opt:InputNumber({name = "X Offset"}),
        OffsetY = Opt:InputNumber({name = "Y Offset"}),
        ShowMax = Opt:Toggle({name = "Show Max", onlyIf = (name == "TimeText"), width = "full"}),
        Font = UnitFontMenu({name = name}),
    }
    args[colorKey] = Opt:Color({name = optName.." Color", hasAlpha = false, get = colorGet, set = colorSet})

    local group = Opt:Group({name = optName, db = dbCast[name], args = args})
    return group
end

local function GenerateAuxiliaryPowerTextGroup(unit, name)
    local dbText = db[unit][name]
    if not dbText then return end

    return Opt:Group({name = string.gsub(name, "Text", " Text"), db = dbText, args = {
        Enable = Opt:Toggle({name = "Enabled", width = "full"}),
        X = Opt:InputNumber({name = "X Value"}),
        Y = Opt:InputNumber({name = "Y Value"}),
        Point = Opt:Select({name = L["Anchor"], values = LUI.Points, onlyIf = (dbText.Point ~= nil)}),
        RelativePoint = Opt:Select({name = "Attach To", values = LUI.Points, onlyIf = (dbText.RelativePoint ~= nil)}),
        Format = Opt:Select({name = "Format", values = auxiliaryPowerFormat}),
        HideIfFullMana = Opt:Toggle({name = "Hide at full mana", onlyIf = (dbText.HideIfFullMana ~= nil)}),
        Color = Opt:Select({name = "Color Type", values = powerColorTypes}),
        IndividualColor = Opt:Color({name = "Text Color", hasAlpha = false, disabled = IsIndividualColorSelected(dbText), db = dbText}),
        Font = UnitFontMenu({name = name}),
    }})
end

local function GeneratePvPTextGroup(unit)
    local dbText = db[unit].PvPText
    if not dbText then return end

    return Opt:Group({name = "PvP Timer Text", db = dbText, args = {
        Enable = Opt:Toggle({name = "Enabled", width = "full"}),
        X = Opt:InputNumber({name = "X Value"}),
        Y = Opt:InputNumber({name = "Y Value"}),
        Color = Opt:Color({name = "Text Color", hasAlpha = false, db = dbText}),
        Font = UnitFontMenu({name = "PvPText"}),
    }})
end

local function GenerateCastbarShieldGroup(unit, order)
    local dbCast = db[unit].Castbar
    if not dbCast then return end    -- If that unit does not have options for that bar, nil it

    local colorGet, colorSet = Opt.ColorGetSet(dbCast.Shield)

    local group = Opt:Group({name = "Shielded Cast Bar", db = dbCast.Shield, args = {
        Explain = Opt:Desc({name = "Additional settings when the cast bar cannot be interrupted."}),
        Enable = Opt:Toggle({name = "Enabled", width = "full"}),
        Text = Opt:Toggle({name = "Text", width = "full"}),
        IndividualColor = Opt:Toggle({name = "Override Bar Color", desc = "Change the color of the cast bar when the cast cannot be interrupted."}),
        BarColor = Opt:Color({name = "Shielded Cast Color", hasAlpha = true, get = colorGet, set = colorSet}),
        Spacer = Opt:Spacer({}),
        IndividualBorder = Opt:Toggle({name = "Override Bar Border Color", desc = "Change the border color of the cast bar when the cast cannot be interrupted."}),
        Color = Opt:Color({name = "Shielded Border Color", hasAlpha = true, get = colorGet, set = colorSet}),
        Spacer2 = Opt:Spacer({}),
        Border = Opt:Toggle({name = "Border", width = "full"}),
        Texture = Opt:MediaBorder({name = "Border Texture"}),
        Thickness = Opt:InputNumber({name = "Thickness"}),
    }})
    return group
end

local function NewUnitOptionGroup(unit, order)
    local isPlayer = (unit == "player")
    local dbUnit = db[unit]

    local unitOptions = Opt:Group({name = unit, childGroups = "tree"})
    unitOptions.args.General = Opt:Group({name = "General", db = dbUnit, args = {
        Position = Opt:Header({name = "Size & Position"}),
        Width = Opt:InputNumber({name = "Width"}),
        Height = Opt:InputNumber({name = "Height"}),
        Spacer = Opt:Spacer({}),
        X = Opt:InputNumber({name = "X Value"}),
        Y = Opt:InputNumber({name = "Y Value"}),
        Point = Opt:Select({name = L["Anchor"], values = LUI.Points}),
        RelativePoint = Opt:Select({name = "Attach To", values = LUI.Points, onlyIf = (relativeUnits[unit] == true)}),
        Scale = Opt:Slider({name = "Scale", values = Opt.ScaleValues, onlyIf = (dbUnit.Scale ~= nil)}),
        -- Groups Options
        Spacer2 = Opt:Spacer({onlyIf = (unit == "party" or unit == "boss" or unit == "arena" or unit == "maintank" or unit == "raid")}),
        Padding = Opt:InputNumber({name = "Padding", desc = "Choose the Padding between your "..unit.." Frames.", onlyIf = (unit == "party" or unit == "boss" or unit == "arena" or unit == "maintank" or unit == "raid")}),
        GroupPadding = Opt:InputNumber({name = "Group Padding", desc = "Choose the Padding between your "..unit.." Groups.", onlyIf = (unit == "raid")}),
        GrowDirection = Opt:Select({name = "Grow Direction", desc = "Choose the Grow Direction for your "..unit.." Frames.", values = LUI.Sides, onlyIf = (unit == "party" or unit == "boss" or unit == "arena" or unit == "maintank")}),
        Enable = Opt:Toggle({name = "Enabled", width = "full"}),
        -- Party-only options
        ShowPlayer = Opt:Toggle({name = "Show Player", desc = "Whether you want to show yourself within the Party Frames or not.", onlyIf = (unit == "party")}),
        ShowInRaid = Opt:Toggle({name = "Show in Raid", desc = "Whether you want to show the Party Frames in Raid or not.", onlyIf = (unit == "party")}),
        ShowInRealParty = Opt:Toggle({name = "Show only in real Parties", desc = "Whether you want to show the Party Frames only in real Parties or in Raids with 5 or less players too.", onlyIf = (unit == "party")}),
        RangeFade = Opt:Toggle({name = "Fade Out of Range", desc = "Whether you want Party Frames to fade if that player is more than 40 yards away or not.", onlyIf = (unit == "party")}),
		Preview = Opt:Execute({name = "Preview This Frame", desc = "Show this frame layout with player data while out of combat.", func = function() module:ToggleUnitframePreview(unit) end}),
		StopPreview = Opt:Execute({name = "Stop Preview", desc = "Hide all unitframe preview frames.", func = function() module:StopUnitframePreview() end}),
       
    }})

    unitOptions.args.HealthBar = GenerateBarGroup(unit, "HealthBar", healthColorTypes, 3)
    unitOptions.args.PowerBar = GenerateBarGroup(unit, "PowerBar", powerColorTypes, 4)
    unitOptions.args.HealthPredictionBar = GenerateHealthPredictionGroup(unit)
    unitOptions.args.TotalAbsorbBar = GenerateTotalAbsorbGroup(unit)
    
    if unit == "player" then
        if supportsClassPower then unitOptions.args.ClassPowerBar = GenerateClassBarGroup(unit, "ClassPowerBar", 5) end
        if LUI.DEATHKNIGHT then unitOptions.args.RunesBar = GenerateClassBarGroup(unit, "RunesBar", 6) end
        if LUI.SHAMAN then unitOptions.args.TotemsBar = GenerateClassBarGroup(unit, "TotemsBar", 7) end
    end

    if unit ~= "player" or supportsAdditionalPower then
        unitOptions.args.AdditionalPowerBar = GenerateBarGroup(unit, "AdditionalPowerBar", powerColorTypes, 10)
        unitOptions.args.AdditionalPowerText = GenerateAuxiliaryPowerTextGroup(unit, "AdditionalPowerText")
    end
    unitOptions.args.AlternativePowerBar = GenerateBarGroup(unit, "AlternativePowerBar", powerColorTypes, 10)
    unitOptions.args.AlternativePowerText = GenerateAuxiliaryPowerTextGroup(unit, "AlternativePowerText")
    
    -- Use a single entry to handle Value, Percent and Missing?
    if dbUnit.NameText then unitOptions.args.NameText = GenerateTextGroup(unit, "NameText", nil, 20) end
    if dbUnit.HealthText then unitOptions.args.HealthText = GenerateTextGroup(unit, "HealthText", healthColorTypes, 21) end
    if dbUnit.PowerText then unitOptions.args.PowerText = GenerateTextGroup(unit, "PowerText", powerColorTypes, 22) end
    if dbUnit.HealthPercentText then unitOptions.args.HealthPercentText = GenerateTextGroup(unit, "HealthPercentText", healthColorTypes, 23) end
    if dbUnit.PowerPercentText then unitOptions.args.PowerPercentText = GenerateTextGroup(unit, "PowerPercentText", powerColorTypes, 24) end
    if dbUnit.HealthMissingText then unitOptions.args.HealthMissingText = GenerateTextGroup(unit, "HealthMissingText", healthColorTypes, 25) end
    if dbUnit.PowerMissingText then unitOptions.args.PowerMissingText = GenerateTextGroup(unit, "PowerMissingText", powerColorTypes, 26) end
    if dbUnit.CombatFeedback then
        unitOptions.args.CombatFeedback = GenerateTextGroup(unit, "CombatFeedback", nil, 27)
    end

    if dbUnit.Portrait then
        unitOptions.args.Portrait = Opt:Group({name = "Portrait", db = dbUnit.Portrait, args = {
            Enable = Opt:Toggle({name = "Enabled", width = "full"}),
            Width = Opt:InputNumber({name = "Width"}),
            Height = Opt:InputNumber({name = "Height"}),
            X = Opt:InputNumber({name = "X Value"}),
            Y = Opt:InputNumber({name = "Y Value"}),
            Alpha = Opt:Slider({name = "Alpha", values = Opt.PercentValues}),
        }})
    end
    
    if dbUnit.Aura.Buffs then
        if dbUnit.Aura.Buffs.IconsPerRow == nil then
            dbUnit.Aura.Buffs.IconsPerRow = dbUnit.Aura.Buffs.Num or 8
        end
        if dbUnit.Aura.Debuffs.IconsPerRow == nil then
            dbUnit.Aura.Debuffs.IconsPerRow = dbUnit.Aura.Debuffs.Num or 8
        end

        unitOptions.args.Buffs = Opt:Group({name = "Buffs", db = dbUnit.Aura.Buffs, args = {
            Enable = Opt:Toggle({name = "Enabled", width = "full"}),
            ColorByType = Opt:Toggle({name = "Color By Type"}),
            PlayerOnly = Opt:Toggle({name = "Player Only"}),
            IncludePet = Opt:Toggle({name = "Include Pet", disabled = function() return not dbUnit.Aura.Buffs.PlayerOnly end}),
            AuraTimer = Opt:Toggle({name = "Aura Timer"}),
            DisableCooldown = Opt:Toggle({name = "Disable Cooldown", desc = "Hide the animated cooldown spiral."}),
            CooldownReverse = Opt:Toggle({name = "Cooldown Reverse", disabled = function() return dbUnit.Aura.Buffs.DisableCooldown end}),
            X = Opt:InputNumber({name = "X Value"}),
            Y = Opt:InputNumber({name = "Y Value"}),
            InitialAnchor = Opt:Select({name = L["Anchor"], values = LUI.Points}),
            GrowthX = Opt:Select({name = "Horizontal Growth", values = LUI.Directions}),
            GrowthY = Opt:Select({name = "Vertical Growth", values = LUI.Directions}),
            Size = Opt:Slider({name = "Size", values = sizeValues}),
            Spacing = Opt:Slider({name = "Spacing", values = spacingValues}),
            Num = Opt:Slider({name = "Amount of Buffs", values = auraCountValues}),
            IconsPerRow = Opt:Slider({name = "Icons Per Row", desc = "Maximum number of buff icons before starting a new row.", values = auraCountValues}),
        }})
        unitOptions.args.Debuffs = Opt:Group({name = "Debuffs", db = dbUnit.Aura.Debuffs, args = {
            Enable = Opt:Toggle({name = "Enabled", width = "full"}),
            ColorByType = Opt:Toggle({name = "Color By Type"}),
            PlayerOnly = Opt:Toggle({name = "Player Only"}),
            IncludePet = Opt:Toggle({name = "Include Pet", disabled = function() return not dbUnit.Aura.Debuffs.PlayerOnly end}),
            AuraTimer = Opt:Toggle({name = "Aura Timer"}),
            DisableCooldown = Opt:Toggle({name = "Disable Cooldown", desc = "Hide the animated cooldown spiral."}),
            CooldownReverse = Opt:Toggle({name = "Cooldown Reverse", disabled = function() return dbUnit.Aura.Debuffs.DisableCooldown end}),
            X = Opt:InputNumber({name = "X Value"}),
            Y = Opt:InputNumber({name = "Y Value"}),
            InitialAnchor = Opt:Select({name = L["Anchor"], values = LUI.Points}),
            GrowthX = Opt:Select({name = "Horizontal Growth", values = LUI.Directions}),
            GrowthY = Opt:Select({name = "Vertical Growth", values = LUI.Directions}),
            Size = Opt:Slider({name = "Size", values = sizeValues}),
            Spacing = Opt:Slider({name = "Spacing", values = spacingValues}),
            Num = Opt:Slider({name = "Amount of Debuffs", values = auraCountValues}),
            IconsPerRow = Opt:Slider({name = "Icons Per Row", desc = "Maximum number of debuff icons before starting a new row.", values = auraCountValues}),
        }})
    end

    if dbUnit.LeaderIndicator then unitOptions.args.LeaderIndicator = GenerateIndicatorGroup(unit, "Leader Icon", 50, Opt.GetSet(dbUnit.LeaderIndicator)) end
    if dbUnit.GroupRoleIndicator then unitOptions.args.GroupRoleIndicator = GenerateIndicatorGroup(unit, "Role Icon", 51, Opt.GetSet(dbUnit.GroupRoleIndicator)) end
    if dbUnit.RaidMarkerIndicator then unitOptions.args.RaidMarkerIndicator = GenerateIndicatorGroup(unit, "Raid Icon", 52, Opt.GetSet(dbUnit.RaidMarkerIndicator)) end
    if dbUnit.PvPIndicator then unitOptions.args.PvPIndicator = GenerateIndicatorGroup(unit, "PvP Icon", 53, Opt.GetSet(dbUnit.PvPIndicator)) end
    if dbUnit.PvPText then unitOptions.args.PvPText = GeneratePvPTextGroup(unit) end
    if dbUnit.RestingIndicator then unitOptions.args.RestingIndicator = GenerateIndicatorGroup(unit, "Resting Icon", 54, Opt.GetSet(dbUnit.RestingIndicator)) end
    if dbUnit.CombatIndicator then unitOptions.args.CombatIndicator = GenerateIndicatorGroup(unit, "Combat Icon", 55, Opt.GetSet(dbUnit.CombatIndicator)) end
    if dbUnit.ReadyCheckIndicator then unitOptions.args.ReadyCheckIndicator = GenerateIndicatorGroup(unit, "Ready Check Icon", 56, Opt.GetSet(dbUnit.ReadyCheckIndicator)) end

    if dbUnit.Castbar and UnitSupportsCastbar(unit) then
        unitOptions.args.Castbar = GenerateCastbarGroup(unit, 61)
        unitOptions.args.CastbarNameText = GenerateCastbarTextGroup(unit, "NameText", 62)
        unitOptions.args.CastbarTimeText = GenerateCastbarTextGroup(unit, "TimeText", 63)
        unitOptions.args.CastbarShield = GenerateCastbarShieldGroup(unit, 64)
    end

    return unitOptions
end


Unitframes.args = {
    Header = Opt:Header({name = "Unitframes"}),
    General = Opt:Group({name = L["General Settings"], db = db.Settings, args = {
		ShowV2Textures = Opt:Toggle({name = "Show LUI v2 Connector Lines", desc = "Show or hide the thin connector lines between Target, Target-of-Target, Focus and their child frames.", width = "full"}),
        ShowV2PartyTextures = Opt:Toggle({name = "Show LUI v2 Connector Frames for Party Frames", desc = "Whether you want to show LUI v2 Frame Connectors on Party Frames or not.", width = "full"}),
        ShowV2ArenaTextures = Opt:Toggle({name = "Show LUI v2 Connector Frames for Arena Frames", desc = "Whether you want to show LUI v2 Frame Connectors on Arena Frames or not.", width = "full"}),
        ShowV2BossTextures = Opt:Toggle({name = "Show LUI v2 Connector Frames for Boss Frames", desc = "Whether you want to show LUI v2 Frame Connectors on Boss Frames or not.", width = "full"}),
        Castbars = Opt:Toggle({name = "Enable Castbars", width = "full"}),
        AuratimerFont = Opt:MediaFont({name = "Aura Timer Font"}),
        AuratimerSize = Opt:Slider({name = "Aura Timer Size", values = fontValues}),
        AuratimerFlag = Opt:Select({name = "Aura Timer Outline", values = LUI.FontFlags}),
        Empty = Opt:Spacer({}),
        Move = Opt:Execute({name = "Move Unitframes", func = function() module:MoveUnitFrames() end}),
		PreviewAll = Opt:Execute({name = "Preview All Frames", desc = "Preview every unitframe layout outside combat.", func = function() module:ToggleUnitframePreview("all") end}),
		PreviewParty = Opt:Execute({name = "Preview Party", func = function() module:ToggleUnitframePreview("party") end}),
		PreviewRaid = Opt:Execute({name = "Preview Raid", func = function() module:ToggleUnitframePreview("raid") end}),
		PreviewBoss = Opt:Execute({name = "Preview Boss", func = function() module:ToggleUnitframePreview("boss") end}),
		PreviewArena = Opt:Execute({name = "Preview Arena", func = function() module:ToggleUnitframePreview("arena") end}),
		PreviewMaintank = Opt:Execute({name = "Preview Main Tank", func = function() module:ToggleUnitframePreview("maintank") end}),
		StopPreview = Opt:Execute({name = "Stop Preview", func = function() module:StopUnitframePreview() end}),
    }})
}

local numSpawns = #module.unitsSpawn
for i = 1, numSpawns do
    local unit = module.unitsSpawn[i]
    local t = NewUnitOptionGroup(unit, i+10)
    Unitframes.args[unit] = t
end

-- Add the missing entries that aren't part of unitsSpawn
local missingUnits = {"partytarget", "partypet", "bosstarget", "arenatarget", "arenapet", "maintanktarget", "maintanktargettarget"}
for i = 1, #missingUnits do
    local unit = missingUnits[i]
    local t = NewUnitOptionGroup(unit, i+numSpawns+10)
    Unitframes.args[unit] = t
end
