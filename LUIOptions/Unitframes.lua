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
-- ##### Options Tables ###############################################################################################
-- ####################################################################################################################

Opt.options.args.Unitframes = Opt:Group("Unitframes", nil, nil, "tab")
Opt.options.args.Unitframes.handler = module

Opt.options.args.Unitframes.args.Header = Opt:Header("Unitframes", 1)

local function UnitFontMenuGetter(info)
    local unit = info[2]
    local fontName = info[3]
	local dbUnit = info.handler.db.profile[unit]
	local prop = info[#info]
	
	return dbUnit.Fonts[fontName][prop]
end

local function UnitFontMenuSetter(info, value)
	local unit = info[2]
    local fontName = info[3]
	local dbUnit = info.handler.db.profile[unit]
	local prop = info[#info]

	dbUnit.Fonts[fontName][prop] = value
end

local function UnitFontMenu(name, desc, order, disabled, hidden)
    local group = Opt:Group(name, desc, order, nil, disabled, hidden)
	group.args.Size = Opt:Slider("Size", nil, 1, sizeValues, nil, disabled, hidden, UnitFontMenuGetter, UnitFontMenuSetter)
	group.args.Name = Opt:MediaFont("Font", nil, 2, nil, disabled, hidden, UnitFontMenuGetter, UnitFontMenuSetter)
	group.args.Flag = Opt:Select("Outline", nil, 3, LUI.FontFlags, nil, disabled, hidden, UnitFontMenuGetter, UnitFontMenuSetter)
	group.inline = true
	return group
end


local function GenerateBarGroup(name, order, get, set)
    local group = Opt:Group(name, nil, order, nil, nil, nil, get, set)
    group.args = {
        Enabled = Opt:Toggle("Enabled", nil, 1, nil, "full"),
        Width = Opt:Input("Width", nil, 2),
        Height = Opt:Input("Height", nil, 3),
        X = Opt:Input("X Value", nil, 4),
        Y = Opt:Input("Y Value", nil, 5),
        Point = Opt:Select(L["Anchor"], nil, 6, LUI.Points),
        Texture = Opt:MediaStatusbar("Bar Texture", nil, 7),
        TextureBG = Opt:MediaStatusbar("Background Texture", nil, 8),
        Smooth = Opt:Toggle("Smooth Gradient", nil, 9),
    }
    return group
end

local function GenerateTextGroup(name, order, get, set)
    local group = Opt:Group(name, nil, order, nil, nil, nil, get, set)
    group.args = {
        Enabled = Opt:Toggle("Enabled", nil, 1),
        X = Opt:Input("X Value", nil, 4),
        Y = Opt:Input("Y Value", nil, 5),
        Point = Opt:Select(L["Anchor"], nil, 6, LUI.Points),
        RelativePoint = Opt:Select("Attach To", nil, 7, LUI.Points),
        Font = UnitFontMenu("Text Font", nil, 20)
    }
    return group
end

local function GenerateIconGroup(name, order, get, set)
    local group = Opt:Group(name, nil, order, nil, nil, nil, get, set)
    group.args = {
        Enabled = Opt:Toggle("Enabled", nil, 1),
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
    LUI:Print(db, unit, db[unit])

    local unitOptions = Opt:Group(unit, nil, order, "tree")
    unitOptions.args.General = Opt:Group("General", nil, 1, nil, nil, nil, Opt.GetSet(dbUnit))
    unitOptions.args.General.args = {
        Position = Opt:Header("Position", 1),
        X = Opt:Input("X Value", nil, 2),
        Y = Opt:Input("Y Value", nil, 3),
        Point = Opt:Select(L["Anchor"], nil, 4, LUI.Points),
        Scale = Opt:Slider("Scale", nil, 5, Opt.ScaleValues),
    }

    unitOptions.args.HealthBar = Opt:Group("Health Bar", nil, 2, nil, nil, nil, Opt.GetSet(dbUnit.HealthBar))
    unitOptions.args.HealthBar.args = {
        Width = Opt:Input("Width", nil, 2),
        Height = Opt:Input("Height", nil, 3),
        Texture = Opt:MediaStatusbar("Bar Texture", nil, 5),
        TextureBG = Opt:MediaStatusbar("Background Texture", nil, 6),
    }

    unitOptions.args.PowerBar = GenerateBarGroup("Power Bar", 3, Opt.GetSet(dbUnit.PowerBar))
    unitOptions.args.AbsorbBar = GenerateBarGroup("Absorb Bar", 4, Opt.GetSet(dbUnit.AborbBar))
    unitOptions.args.ClassPowerBar = GenerateBarGroup("Class Power Bar", 5, Opt.GetSet(dbUnit.ClassPowerBar))
    unitOptions.args.ClassPowerBar.args.Smooth = nil
    unitOptions.args.ClassPowerBar.args.Point = nil
    unitOptions.args.AltManaBar = GenerateBarGroup("Additional Power Bar", 6, Opt.GetSet(dbUnit.AltManaBar))

    unitOptions.args.NameText = GenerateTextGroup("Name Text", 7, Opt.GetSet(dbUnit.NameText))
    unitOptions.args.HealthText = GenerateTextGroup("Health Text", 8, Opt.GetSet(dbUnit.HealthText))
    unitOptions.args.PowerText = GenerateTextGroup("Power Text", 9, Opt.GetSet(dbUnit.PowerText))
    unitOptions.args.CombatText = GenerateTextGroup("Combat Text", 10, Opt.GetSet(dbUnit.CombatText))
    -- Use a single entry to handle Value, Percent and Missing?

    unitOptions.args.Portrait = Opt:Group("Portrait", nil, 11, nil, nil, nil, Opt.GetSet(dbUnit.Portait))
    unitOptions.args.Portrait.args = {
        Width = Opt:Input("Width", nil, 2),
        Height = Opt:Input("Height", nil, 3),
        X = Opt:Input("X Value", nil, 4),
        Y = Opt:Input("Y Value", nil, 5),
        --Point = Opt:Select(L["Anchor"], nil, 6, LUI.Points),
        Alpha = Opt:Slider("Alpha", nil, 7, Opt.PercentValues),
    }

    unitOptions.args.Buffs = Opt:Group("Buffs", nil, 12, nil, nil, nil, Opt.GetSet(dbUnit.Buffs))
    unitOptions.args.Buffs.args = {
        NYI = Opt:Desc("Auras Not Yet Implemented", 0.5),
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
    unitOptions.args.Debuffs = Opt:Group("Debuffs", nil, 13, nil, nil, nil, Opt.GetSet(dbUnit.Debuffs))
    unitOptions.args.Debuffs.args = {
        NYI = Opt:Desc("Auras Not Yet Implemented", 0.5),
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

    unitOptions.args.LeaderIcon = GenerateIconGroup("Leader Icon", 50, Opt.GetSet(dbUnit.LeaderIcon))
    unitOptions.args.RoleIcon = GenerateIconGroup("Role Icon", 50, Opt.GetSet(dbUnit.RoleIcon))
    unitOptions.args.RaidIcon = GenerateIconGroup("Raid Icon", 50, Opt.GetSet(dbUnit.RaidIcon))
    unitOptions.args.PvPIcon = GenerateIconGroup("PvP Icon", 50, Opt.GetSet(dbUnit.PvPIcon))
    --unitOptions.args.RestedIcon = GenerateIconGroup("Leader Icon", 50, Opt.GetSet(dbUnit.LeaderIcon))

    return unitOptions
end

for i = 1, #module.unitsSpawn do
    local unit = module.unitsSpawn[i]
    Opt.options.args.Unitframes.args[unit] = NewUnitOptionGroup(unit, i+10)
end

--[[

	Portrait = opt:NewGroup("Portrait", 4, "tab", nil, {
			Size = opt:NewUnitframeSize(nil, 1, true),
			Position = opt:NewPosition("Position", 2, true),
			Point = opt:NewSelect(L["Anchor"], nil, 3, LUI.Points),
			Alpha = opt:NewSlider("Alpha", nil, 4, 0, 1, 0.05, true),
        }),
]]
