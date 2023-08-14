-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, Opt
local optName, Opt = ...
local L, module, db = Opt:GetLUIModule("Tooltip")
if not module or not module.registered then return end


-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################

local function DisableIfTooltipsHidden()
    return db.HideCombat
end

local function DisableIfCursorAnchor()
    return db.Cursor
end

-- ####################################################################################################################
-- ##### Options Tables ###############################################################################################
-- ####################################################################################################################

Opt.options.args.Tooltip = Opt:Group("Tooltip", nil, nil, "tab", Opt.IsModDisabled, nil, Opt.GetSet(db))
Opt.options.args.Tooltip.handler = module
local Tooltip = {

    --General
    Header = Opt:Header({name = L["Tooltip_Name"]}),
	HideUF = Opt:Toggle({name = L["Tooltip_HideUF_Name"], desc = L["Tooltip_HideUF_Desc"], width = "double"}),
    HideCombat = Opt:Toggle({name = L["Tooltip_HideCombat_Name"], desc = L["Tooltip_HideCombat_Desc"], width = "double"}),
	HideCombatSkills = Opt:Toggle({name = L["Tooltip_HideCombatSkills_Name"], desc = L["Tooltip_HideCombatSkills_Desc"], width = "double", disabled = DisableIfTooltipsHidden}),
	HideCombatUnit = Opt:Toggle({name = L["Tooltip_HideCombatUnit_Name"], desc = L["Tooltip_HideCombatUnit_Desc"], width = "double", disabled = DisableIfTooltipsHidden}),
	HidePVP = Opt:Toggle({name = L["Tooltip_HidePVP_Name"], desc = L["Tooltip_HidePVP_Desc"], width = "double"}),
    ShowSex = Opt:Toggle({name = L["Tooltip_ShowSex_Name"], desc = L["Tooltip_ShowSex_Desc"]}),
    SpacerOne = Opt:Spacer({width = "full"}),
    Scale = Opt:Slider({name = L["Tooltip_Scale_Name"], desc = L["Tooltip_Scale_Desc"], values = Opt.ScaleValues}),
    BorderSize = Opt:Slider({name = L["Tooltip_BorderSize_Name"], desc = L["Tooltip_BorderSize_Desc"], min = 1, max = 30, step = 1}),

    -- Position
    PositionHeader = Opt:Header({name = L["Position"]}),
    Cursor = Opt:Toggle({name = L["Tooltip_Cursor_Name"], desc = L["Tooltip_Cursor_Desc"], width = "full"}),
    X = Opt:Input({name = L["API_XValue_Name"], desc = format(L["API_XValue_Desc"], L["Tooltip_Name"]), disabled = DisableIfCursorAnchor}),
    Y = Opt:Input({name = L["API_YValue_Name"], desc = format(L["API_YValue_Desc"], L["Tooltip_Name"]), disabled = DisableIfCursorAnchor}),
	Point = Opt:Select({name = L["Anchor"], desc = L["AnchorDesc"], values = LUI.Points, disabled = DisableIfCursorAnchor}),

    -- Textures
    TextureHeader = Opt:Header({name = L["Textures"]}),
    HealthBar = Opt:MediaStatusbar({name = L["Tooltip_HealthBar_Name"], desc = L["Tooltip_HealthBar_Desc"], width = "double"}),
    SpacerTwo = Opt:Spacer({}),
    BgTexture = Opt:MediaBackground({name = L["Tooltip_BackgroundTex_Name"], desc = L["BackgroundDesc"], width = "double"}),
    SpacerThree = Opt:Spacer({}),
    BorderTexture = Opt:MediaBorder({name = L["Tooltip_BorderTex_Name"], desc = L["BorderDesc"], width = "double"}),

    -- Colors
    ColorHeader = Opt:Header({name = _G.COLORS}),
    Guild = Opt:Color({name = _G.GUILD, desc = L["Tooltip_Guild_Desc"], hasAlpha = false}),
    MyGuild = Opt:Color({name = L["Tooltip_MyGuild"], desc = L["Tooltip_MyGuild_Desc"], hasAlpha = false}),
    SpacerFour = Opt:Spacer({}),
    Background = Opt:Color({name = L["API_BackgroundColor_Name"], hasAlpha = true}),
    BgColorType = Opt:Select({name = L["API_BackgroundType_Name"], values = LUI.ColorTypes,
        get = function(info) return db.Colors.Background.t end, -- getter
        set = function(info, value) db.Colors.Background.t = value end}), -- setter
    SpacerFive = Opt:Spacer({}),
    Border = Opt:Color({name = L["API_BorderColor_Name"], hasAlpha = true}),
    BorderColorType = Opt:Select({name = L["API_BorderType_Name"], values = LUI.ColorTypes, 
        get = function(info) return db.Colors.Border.t end, -- getter
        set = function(info, value) db.Colors.Border.t = value end}), -- setter
}

Opt.options.args.Tooltip.args = Tooltip
