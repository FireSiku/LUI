-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class Opt
local Opt = select(2, ...)

---@class LUIAddon
local LUI = Opt.LUI
local db = LUI.db.profile

---@type AceLocale.Localizations
local L = LUI.L

local GAME_VERSION_LABEL = _G.GAME_VERSION_LABEL
local GetAddOnMetadata = C_AddOns.GetAddOnMetadata

local General = Opt:CreateModuleOptions("General", LUI)
General.order = 1

local function GetVersionText()
    local version, alpha, git = strsplit("-", LUI.curseVersion)
    if not version then
        return format("%s: %s", GAME_VERSION_LABEL, GetAddOnMetadata("LUI", "Version"))
    elseif not alpha then
        return format("%s: %s", GAME_VERSION_LABEL, GetAddOnMetadata("LUI", "Version"))
    else
        return format("%s: %s, Alpha %s", GAME_VERSION_LABEL, version, alpha)
    end
end

-- ####################################################################################################################
-- ##### Options Tables ###############################################################################################
-- ####################################################################################################################

local HIGH_PATRONS = "|cffa335eeQoke, StephenFOlson, Fearon Whitcomb, Skinny Man Music, David Cook, Dalton Matheson, Curtis Motzner, Christoph Fischer, Hansth, Michael Swancott, Steph Lee, rb4havoc, Max McBurn, Michelle Larrew, Grant Sundstrom, Cory Linnerooth, Eagle Billie, Angryrice, Ian Huisman, Greta Kratz, Sacrosact Stars, Leisulong, Christopher Rhea"
local OTHER_PATRONS = "|cff1eff00Adam Moody, Andrew DePaola, Anthony Béchard, apexius, Azona, BIRDki, Brandon Burr, Chris Manring, Confatalis, Darkion43, Dochouse, gnuheike, Joseph Arnett, Kris Springer, Lyra, Lysa Richey, Mathias Reffeldt, Melvin de Grauw, Michael Rowan, Michael Walker, Mike, McCabe, Mike Williams, Nathan Adams, Nick Giovanni, necr0, Oscar Olofsson, Philipp Rissle, Ragnarok, Richard Scholten, Romain Gorgibus, Saturos Zed, Scott Crawford, Sean O'Shea, Shawn Pitts, Slawomir Baran, Spencer Sommers, Srg Kuja, Thomas A Hutto, Tobias Lidén, Xenthe, Ziri"

General.args = {
    Welcome = Opt:Group({name = L["Core_Welcome"], args = {
        IntroImage = Opt:Desc({name = " ", image = [=[Interface\AddOns\LUI\media\textures\logo2.tga]=], imageCoords = {0, 0, 1}, imageWidth = 512, imageHeight = 128, width = "full"}),
        Spacer1 = Opt:Spacer({}),
        IntroText = Opt:Desc({name = L["For more info, visit Discord"].."\n\n\n", fontSize = "medium"}),
        VerText = Opt:Desc({name = GetVersionText(), fontSize = "large"}),
        Header = Opt:Header({name = "General Settings"}),
        OldOptionsDesc = Opt:Desc({name = "\n\nSome legacy module settings remain available in the old options panel:\n", fontSize = "medium"}),
        OldOptionsButton = Opt:Execute({name = "Old LUI Options", func = function() LUI:OpenOptions(true) end}),
        Master = Opt:FontMenu({name = "Master Font", disabled = true, hidden = true}),
    }}),
    Thanks = Opt:Group({name = "Thanks", args = {
        Empty = Opt:Spacer({}),
        IntroText = Opt:Desc({name =  "The development and sustained maintenance of LUI wasn't the work of a single person, so let's take the time to list the people that deserves thanks for their support".."\n\n", fontSize = "medium"}),
        Staff = Opt:Desc({name = "Current LUI Devs: |cffe6cc80Siku, Nitsah, Pahn|r\n", fontSize = "large"}),
        OldStaff = Opt:Desc({name = "Former V3 Devs: |cffe6cc80Loui, Sinaris, hix, Zista, Shendrela, Thaly, Darkruler, Yunai, Mule|r\n\n", fontSize = "medium"}),
        Donors = Opt:Desc({name = "I would also like to thank everyone that donated to the project, you are all wonderful people. A special mention goes to current and former Patrons:\n", fontSize = "medium"}),
        HighPatrons = Opt:Desc({name = HIGH_PATRONS.."\n", fontSize = "large"}),
        OtherPatrons = Opt:Desc({name = OTHER_PATRONS.."\n", fontSize = "medium"}),
        Discord = Opt:Desc({name = "\n& Everyone who contributes to the discord server or helps other people when the devs are not available.", fontSize = "large"})
    }}),
}
