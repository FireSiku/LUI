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
local copySource = {}
local copySection = {}
local copySizes = {}
local copyPositions = {}

local COPY_SECTIONS = {
    All = "All Settings",
    General = "General",
    Bars = "Bars",
    Texts = "Texts",
    Auras = "Auras",
    Indicators = "Indicators",
    Castbar = "Cast Bar",
    Portrait = "Portrait",
    Appearance = "Backdrop & Border",
}

local POSITION_KEYS = {
    X = true, Y = true, Point = true, RelativePoint = true, InitialAnchor = true,
    GrowthX = true, GrowthY = true, GrowDirection = true,
}

local SIZE_KEYS = {
    Width = true, Height = true, Size = true, Scale = true, Spacing = true,
    Padding = true, GroupPadding = true, Thickness = true, IconScale = true,
}

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

local supportsClassPower = LUI.DEMONHUNTER or LUI.DRUID or LUI.EVOKER or LUI.HUNTER or LUI.MAGE
    or LUI.MONK or LUI.PALADIN or LUI.ROGUE or LUI.SHAMAN or LUI.WARLOCK
local supportsAdditionalPower = LUI.DRUID or LUI.PRIEST or LUI.SHAMAN

-- ####################################################################################################################
-- ##### Custom Controls ##############################################################################################
-- ####################################################################################################################

local powerColorTypes = {
    ["Individual"] = "Individual",
    ["By Class"] = "By Class",
    ["By Type"] = "By Type",
}

local additionalPowerColorTypes = {
    ["Individual"] = "Individual",
    ["By Class"] = "By Class",
    ["By Type"] = "By Type",
    ["Gradient"] = "Gradient",
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

local optionsLayouts = {
    ["Compact"] = "Compact",
    ["Categorized"] = "Categorized",
}

local nameFormats = {
    ["Name"] = "Name",
    ["Name + Level"] = "Name + Level",
    ["Name + Level + Class"] = "Name + Level + Class",
    ["Name + Level + Race + Class"] = "Name + Level + Race + Class",
    ["Level"] = "Level",
    ["Level + Name"] = "Level + Name",
    ["Level + Name + Class"] = "Level + Name + Class",
    ["Level + Name + Race + Class"] = "Level + Name + Race + Class",
    ["Level + Class + Name"] = "Level + Class + Name",
    ["Level + Race + Class + Name"] = "Level + Race + Class + Name",
}

local horizontalDirections = {LEFT = "Left", RIGHT = "Right"}
local verticalDirections = {UP = "Up", DOWN = "Down"}

local function CopyCompatible(source, destination, withSizes, withPositions)
    if type(source) ~= "table" or type(destination) ~= "table" then return end
    for key, value in pairs(source) do
        if (withSizes or not SIZE_KEYS[key]) and (withPositions or not POSITION_KEYS[key]) then
            if type(value) == "table" and type(destination[key]) == "table" then
                CopyCompatible(value, destination[key], withSizes, withPositions)
            elseif type(value) == type(destination[key]) then
                destination[key] = value
            end
        end
    end
end

local function ResetTable(source, destination)
    for key in pairs(destination) do
        if source[key] == nil then destination[key] = nil end
    end

    for key, value in pairs(source) do
        if type(value) == "table" then
            if type(destination[key]) ~= "table" then destination[key] = {} end
            ResetTable(value, destination[key])
        else
            destination[key] = value
        end
    end
end

local function SectionKeys(dbUnit, section)
    local keys = {}
    if section == "All" then return keys, true end
    for key, value in pairs(dbUnit) do
        if type(key) == "string" and (section == "General" and type(value) ~= "table"
            or section == "Bars" and key:match("Bar$")
            or section == "Texts" and (key:match("Text$") or key == "CombatFeedback")
            or section == "Auras" and key == "Aura"
            or section == "Indicators" and key:match("Indicator$")
            or section == "Castbar" and key == "Castbar"
            or section == "Portrait" and key == "Portrait"
            or section == "Appearance" and (key == "Backdrop" or key == "Border")) then
            keys[#keys + 1] = key
        end
    end
    return keys, false
end

local function CopyUnitSettings(targetUnit)
    local sourceUnit = copySource[targetUnit]
    if not sourceUnit or sourceUnit == targetUnit then return end
    local source, destination = db[sourceUnit], db[targetUnit]
    local keys, copyAll = SectionKeys(source, copySection[targetUnit] or "All")
    if copyAll then
        CopyCompatible(source, destination, copySizes[targetUnit], copyPositions[targetUnit])
    else
        for _, key in ipairs(keys) do
            if type(source[key]) == "table" and type(destination[key]) == "table" then
                CopyCompatible(source[key], destination[key], copySizes[targetUnit], copyPositions[targetUnit])
            elseif type(source[key]) == type(destination[key]) then
                destination[key] = source[key]
            end
        end
    end
    module:Refresh()
end

local function GenerateCopyGroup(unit, order)
    local values = {}
    for _, sourceUnit in ipairs(module.units) do
        if sourceUnit ~= unit then values[sourceUnit] = sourceUnit end
    end
    return Opt:Group({name = "Copy Settings", order = order, args = {
        Source = Opt:Select({name = "Copy From", values = values, get = function() return copySource[unit] end, set = function(_, value) copySource[unit] = value end}),
        Section = Opt:Select({name = "Section", values = COPY_SECTIONS, get = function() return copySection[unit] or "All" end, set = function(_, value) copySection[unit] = value end}),
        IncludeSizes = Opt:Toggle({name = "Include Sizes", get = function() return copySizes[unit] == true end, set = function(_, value) copySizes[unit] = value end}),
        IncludePositions = Opt:Toggle({name = "Include Positions", get = function() return copyPositions[unit] == true end, set = function(_, value) copyPositions[unit] = value end}),
        Apply = Opt:Execute({name = "Copy to "..unit, disabled = function() return not copySource[unit] end, confirm = "Overwrite the selected settings for "..unit.."?", func = function() CopyUnitSettings(unit) end}),
    }})
end


local function UnitFontMenu(dbFont, name)
    return Opt:InlineGroup({name = name, db = dbFont, args = {
        Size = Opt:Slider({name = "Size", values = sizeValues}),
        Font = Opt:MediaFont({name = "Font"}),
        Outline = Opt:Select({name = "Outline", values = LUI.FontFlags}),
    }})
end

--- Function to determine if the Individual Color option should be disabled
---@param dbOpt table @ db table of the color to look up
---@param colorSelect string @ if the Color select has a different name than "Color"
---@return function
local function IsIndividualColorSelected(dbOpt, colorSelect)
    colorSelect = colorSelect or "Color"
    return function(info) return dbOpt[colorSelect] ~= "Individual" end
end

local function OptionLabel(name)
    return (name:gsub("(%l)(%u)", "%1 %2"))
end

-- ####################################################################################################################
-- ##### Options Tables ###############################################################################################
-- ####################################################################################################################

local function GenerateBarGroup(unit, name, colorTypes, order)
    local dbBar = db[unit][name]
    if not dbBar then return end    -- If that unit does not have options for that bar, nil it

    local optName = OptionLabel(name)
    local group = Opt:Group({name = optName, order = order, db = dbBar, args = {
        Enable = Opt:Toggle({name = "Enabled", width = "full"}),
        Width = Opt:InputNumber({name = "Width"}),
        Height = Opt:InputNumber({name = "Height"}),
        X = Opt:OffsetX(),
        Y = Opt:OffsetY(),
        Texture = Opt:MediaStatusbar({name = "Bar Texture"}),
        TextureBG = Opt:MediaStatusbar({name = "Background Texture"}),
        Smooth = Opt:Toggle({name = "Smooth Bar Animation"}),
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

local function GenerateHealthPredictionGroup(unit, order)
    local dbBar = db[unit].HealthPredictionBar
    if not dbBar then return end

    return Opt:Group({name = "Heal Prediction Bar", order = order, db = dbBar, args = {
        Enable = Opt:Toggle({name = "Enabled", width = "full"}),
        Texture = Opt:MediaStatusbar({name = "Bar Texture"}),
        MyColor = Opt:Color({name = "Own Heals", hasAlpha = true, db = dbBar}),
        OtherColor = Opt:Color({name = "Other Heals", hasAlpha = true, db = dbBar}),
    }})
end

local function GenerateTotalAbsorbGroup(unit, order)
    local dbBar = db[unit].TotalAbsorbBar
    if not dbBar then return end

    return Opt:Group({name = "Absorb Bar", order = order, db = dbBar, args = {
        Enable = Opt:Toggle({name = "Enabled", width = "full"}),
        Texture = Opt:MediaStatusbar({name = "Bar Texture"}),
        MyColor = Opt:Color({name = "Absorb Color", hasAlpha = true, db = dbBar}),
    }})
end

local function GenerateTextGroup(unit, name, colorTypes, order)
    local dbText = db[unit][name]
    if not dbText then return end    -- If that unit does not have options for that bar, nil it

    local optName = OptionLabel(name)
    local group = Opt:Group({name = optName, order = order, db = dbText, args = {
        Enable = Opt:Toggle({name = "Enabled", width = "full"}),
        X = Opt:OffsetX(),
        Y = Opt:OffsetY(),
        Point = Opt:Select({name = L["Anchor"], values = LUI.Points}),
        RelativePoint = Opt:Select({name = "Attach To", values = LUI.Points}),
        Format = Opt:Select({name = "Format", desc = "Choose the Format for your "..unit.." Name.", values = nameFormats, onlyIf = (name == "NameText")}),
        Color = Opt:Select({name = "Color Type", values = colorTypes}),
        IndividualColor = Opt:Color({name = optName.." Color", hasAlpha = false, disabled = IsIndividualColorSelected(dbText), db = dbText}),
        Font = UnitFontMenu(dbText, "Text Font"),
        ShowAlways = Opt:Toggle({name = "Show when full", onlyIf = (dbText.ShowAlways ~= nil)}),
        ShowDead = Opt:Toggle({name = "Show when dead", onlyIf = (dbText.ShowDead ~= nil)}),
        ShowFull = Opt:Toggle({name = "Show when full", onlyIf = (dbText.ShowFull ~= nil)}),
        ShowEmpty = Opt:Toggle({name = "Show when empty", onlyIf = (dbText.ShowEmpty ~= nil)}),
        ShortValue = Opt:Toggle({name = "Short value", onlyIf = (dbText.ShortValue ~= nil)}),
    }})

    if name == "HealthText" or name == "PowerText" then
        group.args.Format = Opt:Select({name = "Format", values = valueFormat, onlyIf = (name == "HealthText" or name == "PowerText")})
    end

    if name == "NameText" then
        local disabledClassificationFunc = function() return not dbText.ShowClassification end

		group.args.IndividualColor = Opt:Color({name = "Name Color", hasAlpha = false, db = dbText})
		group.args.ColorNameByClass = Opt:Toggle({name = "Color Name by Class"})
		if unit ~= "raid" then
			group.args.ColorClassByClass = Opt:Toggle({name = "Color Class by Class"})
            group.args.ColorLevelByDifficulty = Opt:Toggle({name = "Color Level by Difficulty"})
            group.args.ShowClassification = Opt:Toggle({name = "Show Classification"})
            group.args.ShortClassification = Opt:Toggle({name = "Short Classification", disabled = disabledClassificationFunc})
        else
            group.args.Format = nil
        end
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

    local optName = OptionLabel(name)
    local group = Opt:Group({name = optName, order = order, db = dbBar, args = {
        Enable = Opt:Toggle({name = "Enabled", width = "full"}),
        Width = Opt:InputNumber({name = "Width"}),
        Height = Opt:InputNumber({name = "Height"}),
        X = Opt:OffsetX(),
        Y = Opt:OffsetY(),
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
    local group = Opt:Group({name = name, order = order, get = get, set = set, args = {
        Enable = Opt:Toggle({name = "Enabled", width = "full"}),
        X = Opt:OffsetX(),
        Y = Opt:OffsetY(),
        Size = Opt:Slider({name = "Size", values = sizeValues}),
        Point = Opt:Select({name = L["Anchor"], values = LUI.Points}),
    }})

    return group
end

local function GenerateAppearanceGroup(unit, order)
    local dbUnit = db[unit]

    return Opt:Group({name = "Backdrop & Border", order = order, args = {
        Backdrop = Opt:Group({name = "Background", db = dbUnit.Backdrop, args = {
            Color = Opt:Color({name = "Background Color", hasAlpha = true, db = dbUnit.Backdrop}),
            Texture = Opt:MediaBackground({name = "Background Texture"}),
            Padding = Opt:InlineGroup({name = "Padding", db = dbUnit.Backdrop.Padding, args = {
                Left = Opt:InputNumber({name = "Left", width = "half"}),
                Right = Opt:InputNumber({name = "Right", width = "half"}),
                Top = Opt:InputNumber({name = "Top", width = "half"}),
                Bottom = Opt:InputNumber({name = "Bottom", width = "half"}),
            }}),
        }}),
        Border = Opt:Group({name = "Border", db = dbUnit.Border, args = {
            Color = Opt:Color({name = "Border Color", hasAlpha = true, db = dbUnit.Border}),
            EdgeFile = Opt:MediaBorder({name = "Border Texture"}),
            EdgeSize = Opt:Slider({name = "Border Size", min = 1, max = 50, step = 1}),
            Aggro = Opt:Toggle({name = "Aggro Glow", desc = "Color the border by threat status.", width = "full"}),
            Insets = Opt:InlineGroup({name = "Insets", db = dbUnit.Border.Insets, args = {
                Left = Opt:InputNumber({name = "Left", width = "half"}),
                Right = Opt:InputNumber({name = "Right", width = "half"}),
                Top = Opt:InputNumber({name = "Top", width = "half"}),
                Bottom = Opt:InputNumber({name = "Bottom", width = "half"}),
            }}),
        }}),
    }})
end

local function GenerateCastbarGroup(unit, order)
    local dbCast = db[unit].Castbar
    if not dbCast then return end    -- If that unit does not have options for that bar, nil it

    local defaultCast = module.defaults.profile[unit] and module.defaults.profile[unit].Castbar
    local defaultColors = defaultCast and defaultCast.Colors
    local colorGet, colorSet = Opt.ColorGetSet(dbCast.Colors, defaultColors)
    local latencyColorGet, latencyColorSet = Opt.ColorGetSet(dbCast.Colors, defaultColors, "Latency")

    local group = Opt:Group({name = "Cast Bar", order = order, db = dbCast.General, args = {
        Enable = Opt:Toggle({name = "Enabled", width = "full"}),
        Preview = Opt:Execute({
            name = "Preview Cast Bar",
            desc = "Show a shielded test cast with a long spell name outside combat.",
            func = function() module:ShowCastbarPreview(unit) end,
        }),
        StopPreview = Opt:Execute({
            name = "Stop Cast Bar Preview",
            desc = "Hide the cast bar test without closing other unit frame previews.",
            func = function() module:StopCastbarPreview() end,
        }),
        Width = Opt:InputNumber({name = "Width"}),
        Height = Opt:InputNumber({name = "Height"}),
        X = Opt:OffsetX(),
        Y = Opt:OffsetY(),
        Point = Opt:Select({name = "Anchor Point", values = LUI.Points}),
        IndividualColor = Opt:Toggle({name = "Individual Color", desc = "If unchecked, the class color will be used.", width = "full"}),
        Icon = Opt:Toggle({name = "Show Icon", width = "full"}),
        Latency = Opt:Toggle({name = "Show Latency Safe Zone", desc = "Shows your current network latency at the end of the player cast bar.", width = "full", onlyIf = (unit == "player")}),
        Shielded = Opt:Toggle({name = "Show Shielded Casts", desc = "Whether you want to show casts you cannot interrupt.", width = "full",
            get = function() return dbCast.General.Shield end,
            set = function(info, value)
                dbCast.General.Shield = value
                if info.handler.Refresh then info.handler:Refresh() end
            end}),
        AestheticHeader = Opt:Header({name = "Appearance"}),
        Texture = Opt:MediaStatusbar({name = "Bar Texture"}),
        TextureBG = Opt:MediaStatusbar({name = "Background Texture"}),
		-- The stored border keys differ from the control labels.
		BorderTexture = Opt:MediaBorder({name = "Border Texture", get = function() return dbCast.Border.Texture end,
			set = function(info, value)
                dbCast.Border.Texture = value
                if info.handler.Refresh then info.handler:Refresh() end
            end}),
		BorderThickness = Opt:InputNumber({name = "Border Thickness", get = function() return tostring(dbCast.Border.Thickness) end,
			set = function(info, value)
                dbCast.Border.Thickness = tonumber(value)
                if info.handler.Refresh then info.handler:Refresh() end
            end}),
        BorderInset = Opt:InlineGroup({name = "Border Insets", db = dbCast.Border.Inset, args = {
            left = Opt:InputNumber({name = "Left", width = "half"}),
            right = Opt:InputNumber({name = "Right", width = "half"}),
            top = Opt:InputNumber({name = "Top", width = "half"}),
            bottom = Opt:InputNumber({name = "Bottom", width = "half"}),
        }}),
        ColorHeader = Opt:Header({name = "Appearance"}),
        Bar = Opt:Color({name = "Castbar Color", hasAlpha = true, get = colorGet, set = colorSet}),
        Background = Opt:Color({name = "Background Color", hasAlpha = true, get = colorGet, set = colorSet}),
        Border = Opt:Color({name = "Border Color", hasAlpha = true, get = colorGet, set = colorSet}),
        Shield = Opt:Color({name = "Shield Color", hasAlpha = true, get = colorGet, set = colorSet}),
        LatencyColor = Opt:Color({name = "Latency Color", hasAlpha = true, onlyIf = (unit == "player"), get = latencyColorGet, set = latencyColorSet}),
    }})

    return group
end

local function GenerateCastbarTextGroup(unit, name, order)
    local dbCast = db[unit].Castbar
    if not dbCast then return end    -- If that unit does not have options for that bar, nil it

    local optName = string.gsub("Cast Bar "..name, "Text", " Text")

    local colorKey = name == "NameText" and "Name" or "Time"
    local defaultCast = module.defaults.profile[unit] and module.defaults.profile[unit].Castbar
    local colorGet, colorSet = Opt.ColorGetSet(dbCast.Colors, defaultCast and defaultCast.Colors)
    local args = {
        Enable = Opt:Toggle({name = "Enabled", width = "full"}),
        OffsetX = Opt:OffsetX(),
        OffsetY = Opt:OffsetY(),
        ShowMax = Opt:Toggle({name = "Show Max", onlyIf = (name == "TimeText"), width = "full"}),
        Font = UnitFontMenu(dbCast[name], name),
    }
    args[colorKey] = Opt:Color({name = optName.." Color", hasAlpha = false, get = colorGet, set = colorSet})

    local group = Opt:Group({name = optName, order = order, db = dbCast[name], args = args})
    return group
end

local function GenerateAuxiliaryPowerTextGroup(unit, name, order)
    local dbText = db[unit][name]
    if not dbText then return end

    return Opt:Group({name = OptionLabel(name), order = order, db = dbText, args = {
        Enable = Opt:Toggle({name = "Enabled", width = "full"}),
        X = Opt:OffsetX(),
        Y = Opt:OffsetY(),
        Point = Opt:Select({name = L["Anchor"], values = LUI.Points, onlyIf = (dbText.Point ~= nil)}),
        RelativePoint = Opt:Select({name = "Attach To", values = LUI.Points, onlyIf = (dbText.RelativePoint ~= nil)}),
        Format = Opt:Select({name = "Format", values = auxiliaryPowerFormat}),
        HideIfFullMana = Opt:Toggle({name = "Hide at full mana", onlyIf = (dbText.HideIfFullMana ~= nil)}),
        Color = Opt:Select({name = "Color Type", values = powerColorTypes}),
        IndividualColor = Opt:Color({name = "Text Color", hasAlpha = false, disabled = IsIndividualColorSelected(dbText), db = dbText}),
        Font = UnitFontMenu(dbText, name),
    }})
end

local function GeneratePvPTextGroup(unit, order)
    local dbText = db[unit].PvPText
    if not dbText then return end

    return Opt:Group({name = "PvP Timer Text", order = order, db = dbText, args = {
        Enable = Opt:Toggle({name = "Enabled", width = "full"}),
        X = Opt:OffsetX(),
        Y = Opt:OffsetY(),
        Color = Opt:Color({name = "Text Color", hasAlpha = false, db = dbText}),
        Font = UnitFontMenu(dbText, "PvP Text"),
    }})
end

local function GenerateCastbarShieldGroup(unit, order)
    local dbCast = db[unit].Castbar
    if not dbCast then return end    -- If that unit does not have options for that bar, nil it

    local defaultCast = module.defaults.profile[unit] and module.defaults.profile[unit].Castbar
    local colorGet, colorSet = Opt.ColorGetSet(dbCast.Shield, defaultCast and defaultCast.Shield)

    local group = Opt:Group({name = "Shielded Cast Bar", order = order, db = dbCast.Shield, args = {
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
        Inset = Opt:InlineGroup({name = "Border Insets", db = dbCast.Shield.Inset, args = {
            left = Opt:InputNumber({name = "Left", width = "half"}),
            right = Opt:InputNumber({name = "Right", width = "half"}),
            top = Opt:InputNumber({name = "Top", width = "half"}),
            bottom = Opt:InputNumber({name = "Bottom", width = "half"}),
        }}),
    }})
    return group
end

local function GetOptionsLayout()
    if LUI.db.global.UnitframesOptionsLayout == "Categorized" then
        return "Categorized"
    end
    return "Compact"
end

local BuildUnitframeOptions

local function NewUnitOptionGroup(unit, order, categorized)
    local dbUnit = db[unit]

    local unitOptions = Opt:Group({name = unit, order = order, childGroups = "tree"})
    local barOptions = categorized and Opt:Group({name = "Bars", order = 2, childGroups = "tab"}) or unitOptions
    local textOptions = categorized and Opt:Group({name = "Texts", order = 3, childGroups = "tab"}) or unitOptions
    local auraOptions = categorized and Opt:Group({name = "Auras", order = 5, childGroups = "tab"}) or unitOptions
    local indicatorOptions = categorized and Opt:Group({name = "Indicators", order = 6, childGroups = "tab"}) or unitOptions
    local castbarOptions = categorized and Opt:Group({name = "Cast Bar", order = 7, childGroups = "tab"}) or unitOptions

    unitOptions.args.General = Opt:Group({name = "General", order = 1, db = dbUnit, args = {
        Enable = Opt:Toggle({name = "Enabled", width = "full"}),
        Position = Opt:Header({name = "Size & Position"}),
        Width = Opt:InputNumber({name = "Width"}),
        Height = Opt:InputNumber({name = "Height"}),
        Spacer = Opt:Spacer({}),
        X = Opt:PositionX(),
        Y = Opt:PositionY(),
        Point = Opt:Select({name = L["Anchor"], values = LUI.Points}),
        RelativePoint = Opt:Select({name = "Attach To", values = LUI.Points, onlyIf = (relativeUnits[unit] == true)}),
        Scale = Opt:Slider({name = "Scale", values = Opt.ScaleValues, onlyIf = (dbUnit.Scale ~= nil)}),
        -- Groups Options
        Spacer2 = Opt:Spacer({onlyIf = (unit == "party" or unit == "boss" or unit == "arena" or unit == "maintank" or unit == "raid")}),
        Padding = Opt:InputNumber({name = "Padding", desc = "Choose the Padding between your "..unit.." Frames.", onlyIf = (unit == "party" or unit == "boss" or unit == "arena" or unit == "maintank" or unit == "raid")}),
        GroupPadding = Opt:InputNumber({name = "Group Padding", desc = "Choose the Padding between your "..unit.." Groups.", onlyIf = (unit == "raid")}),
        GrowDirection = Opt:Select({name = "Grow Direction", desc = "Choose the Grow Direction for your "..unit.." Frames.", values = LUI.Sides, onlyIf = (unit == "party" or unit == "boss" or unit == "arena" or unit == "maintank")}),
        -- Party-only options
        ShowPlayer = Opt:Toggle({name = "Show Player", desc = "Whether you want to show yourself within the Party Frames or not.", onlyIf = (unit == "party")}),
        ShowInRaid = Opt:Toggle({name = "Show in Raid", desc = "Whether you want to show the Party Frames in Raid or not.", onlyIf = (unit == "party")}),
        ShowInRealParty = Opt:Toggle({name = "Show only in real Parties", desc = "Whether you want to show the Party Frames only in real Parties or in Raids with 5 or less players too.", onlyIf = (unit == "party")}),
        RangeFade = Opt:Toggle({name = "Fade Out of Range", desc = "Whether you want Party Frames to fade if that player is more than 40 yards away or not.", onlyIf = (unit == "party")}),
		Preview = Opt:Execute({name = "Preview This Frame", desc = "Show this frame layout with player data while out of combat.", func = function() module:ToggleUnitframePreview(unit) end}),
        StopPreview = Opt:Execute({name = "Stop Preview", desc = "Hide all unitframe preview frames.", func = function() module:StopUnitframePreview() end}),
        Reset = Opt:Execute({name = "Reset This Frame", desc = "Restore this unit frame's default settings.", confirm = "Reset all settings for "..unit.."?", func = function()
            ResetTable(module.defaults.profile[unit], db[unit])
            module:Refresh()
            Opt:RefreshOptionsPanel()
        end}),
       
    }})

    barOptions.args.HealthBar = GenerateBarGroup(unit, "HealthBar", healthColorTypes, categorized and 1 or 10)
    barOptions.args.PowerBar = GenerateBarGroup(unit, "PowerBar", powerColorTypes, categorized and 2 or 11)
    barOptions.args.HealthPredictionBar = GenerateHealthPredictionGroup(unit, categorized and 3 or 12)
    barOptions.args.TotalAbsorbBar = GenerateTotalAbsorbGroup(unit, categorized and 4 or 13)
    
    if unit == "player" then
        if supportsClassPower then barOptions.args.ClassPowerBar = GenerateClassBarGroup(unit, "ClassPowerBar", categorized and 5 or 14) end
        if LUI.DEATHKNIGHT then barOptions.args.RunesBar = GenerateClassBarGroup(unit, "RunesBar", categorized and 6 or 15) end
        if LUI.SHAMAN then barOptions.args.TotemsBar = GenerateClassBarGroup(unit, "TotemsBar", categorized and 7 or 16) end
    end

    if unit == "player" and supportsAdditionalPower then
        barOptions.args.AdditionalPowerBar = GenerateBarGroup(unit, "AdditionalPowerBar", additionalPowerColorTypes, categorized and 10 or 17)
        textOptions.args.AdditionalPowerText = GenerateAuxiliaryPowerTextGroup(unit, "AdditionalPowerText", categorized and 10 or 38)
    end
    if unit == "player" then
        barOptions.args.AlternativePowerBar = GenerateBarGroup(unit, "AlternativePowerBar", powerColorTypes, categorized and 11 or 18)
        textOptions.args.AlternativePowerText = GenerateAuxiliaryPowerTextGroup(unit, "AlternativePowerText", categorized and 11 or 39)
    end
    
    if dbUnit.NameText then textOptions.args.NameText = GenerateTextGroup(unit, "NameText", nil, categorized and 1 or 30) end
    if dbUnit.HealthText then textOptions.args.HealthText = GenerateTextGroup(unit, "HealthText", healthColorTypes, categorized and 2 or 31) end
    if dbUnit.PowerText then textOptions.args.PowerText = GenerateTextGroup(unit, "PowerText", powerColorTypes, categorized and 3 or 32) end
    if dbUnit.HealthPercentText then textOptions.args.HealthPercentText = GenerateTextGroup(unit, "HealthPercentText", healthColorTypes, categorized and 4 or 33) end
    if dbUnit.PowerPercentText then textOptions.args.PowerPercentText = GenerateTextGroup(unit, "PowerPercentText", powerColorTypes, categorized and 5 or 34) end
    if dbUnit.HealthMissingText then textOptions.args.HealthMissingText = GenerateTextGroup(unit, "HealthMissingText", healthColorTypes, categorized and 6 or 35) end
    if dbUnit.PowerMissingText then textOptions.args.PowerMissingText = GenerateTextGroup(unit, "PowerMissingText", powerColorTypes, categorized and 7 or 36) end
    if dbUnit.CombatFeedback then
        textOptions.args.CombatFeedback = GenerateTextGroup(unit, "CombatFeedback", nil, categorized and 8 or 37)
    end

    if dbUnit.Portrait then
        unitOptions.args.Portrait = Opt:Group({name = "Portrait", order = categorized and 4 or 50, db = dbUnit.Portrait, args = {
            Enable = Opt:Toggle({name = "Enabled", width = "full"}),
            Width = Opt:InputNumber({name = "Width"}),
            Height = Opt:InputNumber({name = "Height"}),
            X = Opt:OffsetX(),
            Y = Opt:OffsetY(),
            Alpha = Opt:Slider({name = "Alpha", values = Opt.PercentValues}),
        }})
    end

    unitOptions.args.Appearance = GenerateAppearanceGroup(unit, categorized and 8 or 55)

    if dbUnit.Aura.Buffs then
        auraOptions.args.Buffs = Opt:Group({name = "Buffs", order = categorized and 1 or 60, db = dbUnit.Aura.Buffs, args = {
            Enable = Opt:Toggle({name = "Enabled", width = "full"}),
            ColorByType = Opt:Toggle({name = "Dispel Type Border", desc = "Show Blizzard's colored aura border for magic, curse, disease, and poison."}),
            PlayerOnly = Opt:Toggle({name = "Player & Pet Only", desc = "Show only auras applied by you, your pet, or your vehicle. Retail's protected aura API no longer allows addons to separate these sources."}),
            AuraTimer = Opt:Toggle({name = "Aura Timer"}),
            DisableCooldown = Opt:Toggle({name = "Disable Cooldown", desc = "Hide the animated cooldown spiral."}),
            CooldownReverse = Opt:Toggle({name = "Cooldown Reverse", disabled = function() return dbUnit.Aura.Buffs.DisableCooldown end}),
            X = Opt:OffsetX(),
            Y = Opt:OffsetY(),
            InitialAnchor = Opt:Select({name = L["Anchor"], values = LUI.Points}),
            GrowthX = Opt:Select({name = "Horizontal Growth", values = horizontalDirections}),
            GrowthY = Opt:Select({name = "Vertical Growth", values = verticalDirections}),
            Size = Opt:Slider({name = "Size", values = sizeValues}),
            Spacing = Opt:Slider({name = "Spacing", values = spacingValues}),
            Num = Opt:Slider({name = "Amount of Buffs", values = auraCountValues}),
            IconsPerRow = Opt:Slider({name = "Icons Per Row", desc = "Maximum number of buff icons before starting a new row.", values = auraCountValues}),
        }})
        auraOptions.args.Debuffs = Opt:Group({name = "Debuffs", order = categorized and 2 or 61, db = dbUnit.Aura.Debuffs, args = {
            Enable = Opt:Toggle({name = "Enabled", width = "full"}),
            ColorByType = Opt:Toggle({name = "Dispel Type Border", desc = "Show Blizzard's colored aura border for magic, curse, disease, and poison."}),
            PlayerOnly = Opt:Toggle({name = "Player & Pet Only", desc = "Show only auras applied by you, your pet, or your vehicle. Retail's protected aura API no longer allows addons to separate these sources."}),
            AuraTimer = Opt:Toggle({name = "Aura Timer"}),
            DisableCooldown = Opt:Toggle({name = "Disable Cooldown", desc = "Hide the animated cooldown spiral."}),
            CooldownReverse = Opt:Toggle({name = "Cooldown Reverse", disabled = function() return dbUnit.Aura.Debuffs.DisableCooldown end}),
            X = Opt:OffsetX(),
            Y = Opt:OffsetY(),
            InitialAnchor = Opt:Select({name = L["Anchor"], values = LUI.Points}),
            GrowthX = Opt:Select({name = "Horizontal Growth", values = horizontalDirections}),
            GrowthY = Opt:Select({name = "Vertical Growth", values = verticalDirections}),
            Size = Opt:Slider({name = "Size", values = sizeValues}),
            Spacing = Opt:Slider({name = "Spacing", values = spacingValues}),
            Num = Opt:Slider({name = "Amount of Debuffs", values = auraCountValues}),
            IconsPerRow = Opt:Slider({name = "Icons Per Row", desc = "Maximum number of debuff icons before starting a new row.", values = auraCountValues}),
        }})
    end

    if dbUnit.LeaderIndicator then indicatorOptions.args.LeaderIndicator = GenerateIndicatorGroup(unit, "Leader Icon", categorized and 1 or 70, Opt.GetSet(dbUnit.LeaderIndicator)) end
    if dbUnit.GroupRoleIndicator then indicatorOptions.args.GroupRoleIndicator = GenerateIndicatorGroup(unit, "Role Icon", categorized and 2 or 71, Opt.GetSet(dbUnit.GroupRoleIndicator)) end
    if dbUnit.RaidMarkerIndicator then indicatorOptions.args.RaidMarkerIndicator = GenerateIndicatorGroup(unit, "Raid Icon", categorized and 3 or 72, Opt.GetSet(dbUnit.RaidMarkerIndicator)) end
    if dbUnit.PvPIndicator then indicatorOptions.args.PvPIndicator = GenerateIndicatorGroup(unit, "PvP Icon", categorized and 4 or 73, Opt.GetSet(dbUnit.PvPIndicator)) end
    if dbUnit.PvPText then textOptions.args.PvPText = GeneratePvPTextGroup(unit, categorized and 9 or 40) end
    if dbUnit.RestingIndicator then indicatorOptions.args.RestingIndicator = GenerateIndicatorGroup(unit, "Resting Icon", categorized and 5 or 74, Opt.GetSet(dbUnit.RestingIndicator)) end
    if dbUnit.CombatIndicator then indicatorOptions.args.CombatIndicator = GenerateIndicatorGroup(unit, "Combat Icon", categorized and 6 or 75, Opt.GetSet(dbUnit.CombatIndicator)) end
    if dbUnit.ReadyCheckIndicator then indicatorOptions.args.ReadyCheckIndicator = GenerateIndicatorGroup(unit, "Ready Check Icon", categorized and 7 or 76, Opt.GetSet(dbUnit.ReadyCheckIndicator)) end

    if dbUnit.Castbar and UnitSupportsCastbar(unit) then
        local castbarPrefix = categorized and "" or "Castbar"
        castbarOptions.args[castbarPrefix.."General"] = GenerateCastbarGroup(unit, categorized and 1 or 80)
        castbarOptions.args[castbarPrefix.."NameText"] = GenerateCastbarTextGroup(unit, "NameText", categorized and 2 or 81)
        castbarOptions.args[castbarPrefix.."TimeText"] = GenerateCastbarTextGroup(unit, "TimeText", categorized and 3 or 82)
        castbarOptions.args[castbarPrefix.."Shield"] = GenerateCastbarShieldGroup(unit, categorized and 4 or 83)
    end

    if categorized then
        if next(barOptions.args) then unitOptions.args.Bars = barOptions end
        if next(textOptions.args) then unitOptions.args.Texts = textOptions end
        if next(auraOptions.args) then unitOptions.args.Auras = auraOptions end
        if next(indicatorOptions.args) then unitOptions.args.Indicators = indicatorOptions end
        if next(castbarOptions.args) then unitOptions.args.Castbar = castbarOptions end
    end

    unitOptions.args.CopySettings = GenerateCopyGroup(unit, 100)

    return unitOptions
end


BuildUnitframeOptions = function()
    local optionsLayout = GetOptionsLayout()
    local categorized = optionsLayout == "Categorized"

    Unitframes.args = {
        Header = Opt:Header({name = "Unitframes", order = 1}),
        General = Opt:Group({name = L["General Settings"], order = 2, db = db.Settings, args = {
            OptionsLayout = Opt:Select({name = "Options Layout", desc = "Choose a compact component list or organize the same options into categories.", values = optionsLayouts,
                get = GetOptionsLayout,
                set = function(_, value)
                    if value == GetOptionsLayout() then return end
                    LUI.db.global.UnitframesOptionsLayout = value
                    BuildUnitframeOptions()
                    Opt:RefreshOptionsPanel()
                end}),
            LayoutSpacer = Opt:Spacer({}),
            ShowV2Textures = Opt:Toggle({name = "Show LUI v2 Connector Lines", desc = "Show or hide the thin connector lines between Target, Target-of-Target, Focus and their child frames.", width = "full"}),
            ShowV2PartyTextures = Opt:Toggle({name = "Show LUI v2 Connector Frames for Party Frames", desc = "Whether you want to show LUI v2 Frame Connectors on Party Frames or not.", width = "full"}),
            ShowV2ArenaTextures = Opt:Toggle({name = "Show LUI v2 Connector Frames for Arena Frames", desc = "Whether you want to show LUI v2 Frame Connectors on Arena Frames or not.", width = "full"}),
            ShowV2BossTextures = Opt:Toggle({name = "Show LUI v2 Connector Frames for Boss Frames", desc = "Whether you want to show LUI v2 Frame Connectors on Boss Frames or not.", width = "full"}),
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
        }}),
    }

    -- module.units is the authoritative list and includes both directly spawned
    -- frames and child frames such as party targets, pets and boss targets.
    for i, unit in ipairs(module.units) do
        Unitframes.args[unit] = NewUnitOptionGroup(unit, i + 10, categorized)
    end
end

BuildUnitframeOptions()
