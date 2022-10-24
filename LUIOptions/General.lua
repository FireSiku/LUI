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

local function GetVersionText()
    local version, apha, git = strsplit("-", LUI.curseVersion)
    if not version then
        return format("%s: %s", GAME_VERSION_LABEL, GetAddOnMetadata("LUI", "Version"))
    elseif not alpha then
        return format("%s: %s", GAME_VERSION_LABEL, GetAddOnMetadata("LUI", "Version"))
    else
        return format("%s %s, Alpha %s", GAME_VERSION_LABEL, version, alpha)
    end
end

General.Welcome = Opt:Group(L["Core_Welcome"], nil, 1)
General.Welcome.args = {
    IntroImage = Opt:Desc(" ", 1, nil, [=[Interface\AddOns\LUI\media\textures\logo2.tga]=], {0, 1, 0, 1}, 512, 128, "full"),
    Spacer1 = Opt:Spacer(2),
    IntroText = Opt:Desc(L["For more info, visit Discord"].."\n\n\n", 3, "medium"),
    --IntroText = Opt:Desc(L["Core_IntroText"], 3),
    VerText = Opt:Desc(GetVersionText(), 4, "large"),
    Header = Opt:Header("General Settings", 10, true),
    Master = Opt:FontMenu("Master Font", nil, 11, true, true),
}

local HIGH_PATRONS = "|cffa335eeQoke, StephenFOlson, Fearon Whitcomb, Skinny Man Music, David Cook, Dalton Matheson, Curtis Motzner, Christoph Fischer, Hansth, Michael Swancott, Steph Lee, rb4havoc, Max McBurn, Michelle Larrew, Grant Sundstrom, Cory Linnerooth, Eagle Billie, Angryrice, Ian Huisman, Greta Kratz, Sacrosact Stars, Leisulong, Christopher Rhea"
local OTHER_PATRONS = "|cff1eff00Adam Moody, Andrew DePaola, Anthony Béchard, apexius, Azona, BIRDki, Brandon Burr, Chris Manring, Confatalis, Darkion43, Dochouse, gnuheike, Joseph Arnett, Kris Springer, Lyra, Lysa Richey, Mathias Reffeldt, Melvin de Grauw, Michael Rowan, Michael Walker, Mike, McCabe, Mike Williams, Nathan Adams, Nick Giovanni, necr0, Oscar Olofsson, Philipp Rissle, Ragnarok, Richard Scholten, Romain Gorgibus, Saturos Zed, Scott Crawford, Sean O'Shea, Shawn Pitts, Slawomir Baran, Spencer Sommers, Srg Kuja, Thomas A Hutto, Tobias Lidén, Xenthe, Ziri"

General.Thanks = Opt:Group("Thanks", nil, 2)
General.Thanks.args = {
    Empty = Opt:Spacer(2),
    IntroText = Opt:Desc( "The development and sustained maintenance of LUI wasn't the work of a single person, so let's take the time to list the people that deserves thanks for their support".."\n\n", 3, "medium"),
    Staff = Opt:Desc("Current LUI Devs: |cffe6cc80Siku, Nitsah|r\n", 4, "large"),
    OldStaff = Opt:Desc("Former V3 Devs: |cffe6cc80Loui, Sinaris, hix, Zista, Shendrela, Thaly, Darkruler, Yunai, Mule|r\n\n", 5, "medium"),
    Donors = Opt:Desc("I would also like to thank everyone that donated to the project, you are all wonderful people. A special mention goes to current and former Patrons:\n", 6, "medium"),
    HighPatrons = Opt:Desc(HIGH_PATRONS.."\n", 7, "large"),
    OtherPatrons = Opt:Desc(OTHER_PATRONS.."\n", 8, "medium"),
    Discord = Opt:Desc("\n& Everyone who contributes to the discord server or helps other people when the devs are not available.", 9, "large")
}

-- General.Dev = Opt:Group("Development", nil, 3, nil, nil, true)
-- General.Dev.args = {
--     Desc = Opt:Desc("This tab shouldn't be visible, but if you do see it, pay this no mind.", 1),
--     Editbox = Opt:Input("Test", nil, 2, 20, "full", nil, nil, nil, GetEditBoxText)
-- }

--[[
    Thanks = {
    name = "Thanks",
    type = "group",
    order = 5,
    args = {
        empty5 = {
            name = " ",
            width = "full",
            type = "description",
            order = 2,
        },
        IntroText = {
            order = 3,
            width = "full",
            type = "description",
            name = "The development and sustained maintenance of LUI V3 wasn't the work of a single so I would like to take the time to list a few people that deserves thanks for their support".."\n",
        },
        Staff = {
            order = 4,
            width = "full",
            type = "description",
            fontSize = "medium",
            name = "Current V3 Devs: |cffe6cc80Siku, Mule|r\n",
        },
        OldStaff = {
            order = 5,
            width = "full",
            type = "description",
            fontSize = "medium",
            name = "Former V3 Devs: |cffe6cc80Loui, Sinaris, Zista, hix, Thaly, Shendrela, Darkruler, Yunai|r\n\n",
        },
        Donators = {
            order = 6,
            width = "full",
            type = "description",
            name = "I would also like to thank everyone that donated to the project, you are all wonderful people. A special mention goes to my current and former Patrons:".."\n",
        },
        HighPatrons = {
            order = 7,
            width = "full",
            type = "description",
            fontSize = "large",
            name = "|cffa335eeQoke, StephenFOlson, Fearon Whitcomb, Skinny Man Music, David Cook, Dalton Matheson, Curtis Motzner, Christoph Fischer, Hansth, Michael Swancott, Steph Lee, rb4havoc, Max McBurn, Michelle Larrew, Grant Sundstrom, Cory Linnerooth, Eagle Billie, Angryrice, Ian Huisman, Greta Kratz, Sacrosact Stars, Leisulong, Christopher Rhea".."\n",
        },
        
        OtherPatrons = {
            order = 8,
            width = "full",
            type = "description",
            fontSize = "medium",
            name = "|cff1eff00Adam Moody, Andrew DePaola, Anthony Béchard, apexius, Azona, BIRDki, Brandon Burr, Chris Manring, Confatalis, Darkion43, Dochouse, gnuheike, Joseph Arnett, Kris Springer, Lyra, Lysa Richey, Mathias Reffeldt, Melvin de Grauw, Michael Rowan, Michael Walker, Mike, McCabe, Mike Williams, Nathan Adams, Nick Giovanni, necr0, Oscar Olofsson, Philipp Rissle, Ragnarok, Richard Scholten, Romain Gorgibus, Saturos Zed, Scott Crawford, Sean O'Shea, Shawn Pitts, Slawomir Baran, Spencer Sommers, Srg Kuja, Thomas A Hutto, Tobias Lidén, Xenthe, Ziri".."\n",
        },
    },
},
]]