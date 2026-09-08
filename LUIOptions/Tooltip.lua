-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class Opt
local Opt = select(2, ...)

---@type AceLocale.Localizations, LUI.Tooltip, AceDB-3.0
local L, module, db = Opt:GetLUIModule("Tooltip")
if not module or not module.registered then return end

local Tooltip = Opt:CreateModuleOptions("Tooltip", module)

-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################

local function DisableIfTooltipsHidden()
    return db.HideCombat
end

local function DisableIfCursorAnchor()
    return db.Cursor
end

local function DisableIfTexturedBackground()
	return db.BgTexture ~= "None"
end

local function ColorTypeOption(name, key, order, width)
    return Opt:Select({name = name, values = LUI.ColorTypes, order = order, width = width,
        desc = "Choose Individual to use your own color, or Class Color to color players by class and NPCs by reaction.",
        get = function() return db.Colors[key].t end,
        set = function(info, value)
            db.Colors[key].t = value
            module:Refresh()
        end,
    })
end

local function ColorOpacityOption(name, key, order)
    return Opt:Slider({name = name, values = Opt.PercentValues, order = order,
        get = function() return db.Colors[key].a end,
        set = function(info, value)
            db.Colors[key].a = value
            module:Refresh()
        end,
    })
end

local function IndividualColorDisabled(key)
    return function() return db.Colors[key].t ~= "Individual" end
end

local healthBarHeightValues = {min = 1, max = 64, softMin = 4, softMax = 24, step = 1}
local healthTextPositionValues = {min = -100, max = 100, softMin = -20, softMax = 20, step = 1}

local healthTextOptions = Opt:FontMenu({name = "Health Text", order = 20})
healthTextOptions.args.ShowHealthText = Opt:Toggle({name = "Show Health Text", width = "full", order = 1})
healthTextOptions.args.Size.order = 2
healthTextOptions.args.Name.order = 3
healthTextOptions.args.Flag.order = 4
healthTextOptions.args.HealthText = Opt:Color({name = "Text Color", hasAlpha = true, order = 5})
healthTextOptions.args.HealthTextX = Opt:OffsetX({name = "Left / Right", values = healthTextPositionValues, order = 6})
healthTextOptions.args.HealthTextY = Opt:OffsetY({name = "Down / Up", values = healthTextPositionValues, order = 7})

-- ####################################################################################################################
-- ##### Options Tables ###############################################################################################
-- ####################################################################################################################

Tooltip.args = {

    --General
    Header = Opt:Header({name = L["Tooltip_Name"]}),
	HideUF = Opt:Toggle({name = L["Tooltip_HideUF_Name"], desc = L["Tooltip_HideUF_Desc"], width = "double"}),
    HideCombat = Opt:Toggle({name = L["Tooltip_HideCombat_Name"], desc = L["Tooltip_HideCombat_Desc"], width = "double"}),
	HideCombatSkills = Opt:Toggle({name = L["Tooltip_HideCombatSkills_Name"], desc = L["Tooltip_HideCombatSkills_Desc"], width = "double", disabled = DisableIfTooltipsHidden}),
	HideCombatUnit = Opt:Toggle({name = L["Tooltip_HideCombatUnit_Name"], desc = L["Tooltip_HideCombatUnit_Desc"], width = "double", disabled = DisableIfTooltipsHidden}),
    SpacerOne = Opt:Spacer({width = "full"}),
    Scale = Opt:Slider({name = L["Tooltip_Scale_Name"], desc = L["Tooltip_Scale_Desc"], values = Opt.ScaleValues}),

    -- Position
    PositionHeader = Opt:Header({name = L["Position"]}),
    Cursor = Opt:Toggle({name = L["Tooltip_Cursor_Name"], desc = L["Tooltip_Cursor_Desc"], width = "full"}),
    X = Opt:PositionX({disabled = DisableIfCursorAnchor}),
    Y = Opt:PositionY({disabled = DisableIfCursorAnchor}),
	Point = Opt:Select({name = L["Anchor"], desc = L["AnchorDesc"], values = LUI.Points, disabled = DisableIfCursorAnchor}),

    -- Health bar
    TextureHeader = Opt:Header({name = "Health Bar"}),
    HealthBar = Opt:MediaStatusbar({name = L["Tooltip_HealthBar_Name"], desc = L["Tooltip_HealthBar_Desc"], width = "double"}),
    HealthBarHeight = Opt:Slider({name = "Health Bar Height", values = healthBarHeightValues}),
    HealthBarColorType = ColorTypeOption("Health Bar Color Type", "HealthBar"),
    HealthBarColor = Opt:Color({name = "Health Bar Color", hasAlpha = false,
        desc = "Choose Individual under Health Bar Color Type to change this color.",
        get = function() local c = db.Colors.HealthBar; return c.r, c.g, c.b, c.a end,
        set = function(info, r, g, b)
            local c = db.Colors.HealthBar
            c.r, c.g, c.b = r, g, b
            module:Refresh()
        end,
        disabled = IndividualColorDisabled("HealthBar")}),
    HealthBarOpacity = ColorOpacityOption("Health Bar Opacity", "HealthBar"),
    Health = healthTextOptions,
    Appearance = Opt:InlineGroup({name = "Tooltip Appearance", db = db, args = {
        BgTexture = Opt:MediaBackground({name = "Background Texture", desc = L["BackgroundDesc"], order = 1}),
        Background = Opt:Color({name = "Background Color", hasAlpha = true, disabled = DisableIfTexturedBackground, order = 2}),
        BorderTexture = Opt:MediaBorder({name = "Border Texture", order = 3}),
        Border = Opt:Color({name = "Border Color", hasAlpha = true, disabled = IndividualColorDisabled("Border"), order = 4,
            desc = "Choose Individual under Border Color Type to change this color."}),
        BorderColorType = ColorTypeOption(L["API_BorderType_Name"], "Border", 5),
    }}),

    -- Colors
    ColorHeader = Opt:Header({name = "Guild Colors"}),
    Guild = Opt:Color({name = "Other Guilds", desc = L["Tooltip_Guild_Desc"], hasAlpha = false}),
    MyGuild = Opt:Color({name = "Own Guild", desc = L["Tooltip_MyGuild_Desc"], hasAlpha = false}),
}

-- Keep rows predictable even when helper-generated groups add their own options.
local optionOrder = {
    "Header", "HideUF", "HideCombat", "HideCombatSkills", "HideCombatUnit", "SpacerOne", "Scale",
    "PositionHeader", "Cursor", "X", "Y", "Point", "TextureHeader", "HealthBar", "HealthBarHeight",
    "HealthBarColorType", "HealthBarColor", "HealthBarOpacity", "Health", "Appearance", "ColorHeader", "Guild", "MyGuild",
}
for order, key in ipairs(optionOrder) do Tooltip.args[key].order = order end
