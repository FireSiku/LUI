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
    Header = Opt:Header(L["Tooltip_Name"], 1),
	HideUF = Opt:Toggle(L["Tooltip_HideUF_Name"], L["Tooltip_HideUF_Desc"], 2, nil, "double"),
    HideCombat = Opt:Toggle(L["Tooltip_HideCombat_Name"], L["Tooltip_HideCombat_Desc"], 3, nil, "double"),
	HideCombatSkills = Opt:Toggle(L["Tooltip_HideCombatSkills_Name"], L["Tooltip_HideCombatSkills_Desc"], 3, nil, "double", DisableIfTooltipsHidden),
	HideCombatUnit = Opt:Toggle(L["Tooltip_HideCombatUnit_Name"], L["Tooltip_HideCombatUnit_Desc"], 4, nil, "double", DisableIfTooltipsHidden),
	HidePVP = Opt:Toggle(L["Tooltip_HidePVP_Name"], L["Tooltip_HidePVP_Desc"], 6, nil, "double"),
    ShowSex = Opt:Toggle(L["Tooltip_ShowSex_Name"], L["Tooltip_ShowSex_Desc"], 7),
    SpacerOne = Opt:Spacer(8, "full"),
    Scale = Opt:Slider(L["Tooltip_Scale_Name"], L["Tooltip_Scale_Desc"], 9, Opt.ScaleValues),
    BorderSize = Opt:Slider(L["Tooltip_BorderSize_Name"], L["Tooltip_BorderSize_Desc"], 10, {min = 1, max = 30, step = 1}),

    -- Position
    PositionHeader = Opt:Header(L["Position"], 20),
    Cursor = Opt:Toggle(L["Tooltip_Cursor_Name"], L["Tooltip_Cursor_Desc"], 21, nil, "full"),
    X = Opt:Input(L["API_XValue_Name"], format(L["API_XValue_Desc"], L["Tooltip_Name"]), 22, nil, nil, DisableIfCursorAnchor),
    Y = Opt:Input(L["API_YValue_Name"], format(L["API_YValue_Desc"], L["Tooltip_Name"]), 23, nil, nil, DisableIfCursorAnchor),
	Point = Opt:Select(L["Anchor"], L["AnchorDesc"], 24, LUI.Points, nil, DisableIfCursorAnchor),

    -- Textures
    TextureHeader = Opt:Header(L["Textures"], 30),
    HealthBar = Opt:MediaStatusbar(L["Tooltip_HealthBar_Name"], L["Tooltip_HealthBar_Desc"], 31, "double"),
    SpacerTwo = Opt:Spacer(32),
    BgTexture = Opt:MediaBackground(L["Tooltip_BackgroundTex_Name"], L["BackgroundDesc"], 33, "double"),
    SpacerThree = Opt:Spacer(34),
    BorderTexture = Opt:MediaBorder(L["Tooltip_BorderTex_Name"], L["BorderDesc"], 35, "double"),

    -- Colors
    ColorHeader = Opt:Header(_G.COLORS, 40),
    Guild = Opt:Color(_G.GUILD, L["Tooltip_Guild_Desc"], 41, false),
    MyGuild = Opt:Color(L["Tooltip_MyGuild"], L["Tooltip_MyGuild_Desc"], 42, false),
    SpacerFour = Opt:Spacer(43),
    Background = Opt:Color(L["API_BackgroundColor_Name"], nil, 44, true),
    BgColorType = Opt:Select(L["API_BackgroundType_Name"], nil, 45, LUI.ColorTypes, nil, nil, nil,
                             function(info) return db.Colors.Background.t end, -- getter
                             function(info, value) db.Colors.Background.t = value end), -- setter
    SpacerFive = Opt:Spacer(46),
    Border = Opt:Color(L["API_BorderColor_Name"], nil, 47, true),
    BorderColorType = Opt:Select(L["API_BorderType_Name"], nil, 48, LUI.ColorTypes, nil, nil, nil,
                                 function(info) return db.Colors.Border.t end, -- getter
                                 function(info, value) db.Colors.Border.t = value end), -- setter
}

Opt.options.args.Tooltip.args = Tooltip