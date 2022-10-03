-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, Opt
local optName, Opt = ...

local LUI = Opt.LUI
local db = LUI.db.profile
local L = LUI.L

local GAME_VERSION_LABEL = _G.GAME_VERSION_LABEL
local GetAddOnMetadata = _G.GetAddOnMetadata

-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################

local function GetEditBoxText()
    local t = {}
    for name, value in pairs(_G) do
        if type(value) == "table" and value.GetObjectType and not string.match(name, "Frame$") then
            if value.IsForbidden and value:IsForbidden() then print(name.." Is Forbidden")
            elseif value.GetParent and (value:GetParent() == nil or value:GetParent() == UIParent) then
            --if string.match(name, "_COLORS?$") then
            -- if not (string.match(name, "Frame$") or string.match(name, "C_") or string.match(name, "_COLORS?$")) and
            -- not (string.match(name, "Mixin$") or string.match(name, "Util$")) then
                table.insert(t, name)
                --s = format('%s"%s", ', s, name)
            end
        end
    end
    table.sort(t)
    local s = ""
    for i = 1, #t do
        s = format('%s"%s", ', s, t[i])
    end
    return s.."--"
end

-- ####################################################################################################################
-- ##### Options Tables ###############################################################################################
-- ####################################################################################################################

Opt.options.args.General = Opt:Group("General", nil, 1, "tab", nil, nil, Opt.GetSet(db))
Opt.options.args.General.handler = LUI
local General = Opt.options.args.General.args

General.Welcome = Opt:Group(L["Core_Welcome"], nil, 1)
General.Welcome.args = {
    IntroText = Opt:Desc(L["Core_IntroText"], 3),
    VerText = Opt:Desc(format("%s: %s", GAME_VERSION_LABEL, GetAddOnMetadata("LUI", "Version")), 4),
    RevText = Opt:Desc(format(L["Core_Revision_Format"], LUI.curseVersion or "???"), 5),
    Header = Opt:Header("General Settings", 10),
    Master = Opt:FontMenu("Master Font", nil, 11),
}
General.Dev = Opt:Group("Development", nil, 3, nil, nil, true)
General.Dev.args = {
    Desc = Opt:Desc("This tab shouldn't be visible, but if you do see it, pay this no mind.", 1),
    Editbox = Opt:Input("Test", nil, 2, 20, "full", nil, nil, nil, GetEditBoxText)
}