-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class Opt
local Opt = select(2, ...)

---@class LUIAddon
local LUI = Opt.LUI
local db = LUI.db.profile
local generalDB = db.General

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

local function SetGeneralOption(key, callback)
    return function(_, value)
        generalDB[key] = value
        if callback then callback() end
    end
end

local function ApplyBlizzardScale()
    LUI:FetchScript("BlizzScale"):ApplyBlizzScaling()
end

local function ApplyErrorFilter()
    LUI:FetchScript("ErrorHider"):ErrorMessageHandler()
end

local function ApplyTalentFilter()
    LUI:FetchScript("TalentSpam"):SetTalentSpam()
end

local function ApplyAutoInvite()
    LUI:FetchScript("AutoInvite"):SetAutoInvite()
end

local function ApplyDamageFont()
    LUI:SetDamageFont()
end

local function BackupProfile()
    LUI.Restore.Backup()
end

local function RestoreProfile()
    LUI.Restore.Restore()
end

local function RevertProfile()
    LUI.Restore.Revert()
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
	}}),
    Settings = Opt:Group({name = "Settings", db = generalDB, args = {
        Blizzard = Opt:Group({name = "Blizzard UI", inline = true, args = {
            BlizzFrameScale = Opt:Slider({name = "Blizzard Frame Scale", desc = "Scale the Game Menu, Settings panel, character frame, spellbook and other supported Blizzard windows.", values = Opt.ScaleValues, set = SetGeneralOption("BlizzFrameScale", ApplyBlizzardScale)}),
            HideErrors = Opt:Toggle({name = "Hide Blizzard Error Messages", desc = "Hide messages such as 'Not enough energy'.", width = "full", set = SetGeneralOption("HideErrors", ApplyErrorFilter)}),
            HideTalentSpam = Opt:Toggle({name = "Hide Talent Change Spam", desc = "Filter system chat messages produced by talent and specialization changes.", width = "full", set = SetGeneralOption("HideTalentSpam", ApplyTalentFilter)}),
            ModuleMessages = Opt:Toggle({name = "Show Module Messages", desc = "Show messages when LUI modules are enabled or disabled.", width = "full"}),
        }}),
        Invites = Opt:Group({name = "Invites", inline = true, args = {
            AutoInvite = Opt:Toggle({name = "Enable AutoInvite", desc = "Invite players who whisper the configured keyword.", width = "full", set = SetGeneralOption("AutoInvite", ApplyAutoInvite)}),
            AutoInviteOnlyFriend = Opt:Toggle({name = "Only Friends and Guildmates", disabled = function() return not generalDB.AutoInvite end, width = "full"}),
            AutoInviteKeyword = Opt:Input({name = "AutoInvite Keyword", desc = "AutoInvite remains inactive until a non-empty keyword is entered.", disabled = function() return not generalDB.AutoInvite end, set = SetGeneralOption("AutoInviteKeyword", ApplyAutoInvite), width = "full"}),
        }}),
        DamageText = Opt:Group({name = "Damage Text", inline = true, args = {
            DamageFont = Opt:MediaFont({name = "Font", set = SetGeneralOption("DamageFont", ApplyDamageFont)}),
            DamageFontSize = Opt:Slider({name = "Font Size", min = 20, max = 60, step = 1, set = SetGeneralOption("DamageFontSize", ApplyDamageFont)}),
            DamageFontSizeCrit = Opt:Slider({name = "Critical Font Size", min = 20, max = 60, step = 1, set = SetGeneralOption("DamageFontSizeCrit", ApplyDamageFont)}),
        }}),
		ProfileTools = Opt:Group({name = "Profile Backup", inline = true, args = {
			Backup = Opt:Execute({name = "Create Backup", desc = "Save the current profile settings for Restore or Revert.", func = BackupProfile}),
			Restore = Opt:Execute({name = "Restore Current Settings", desc = "Reset to current defaults, then restore compatible values from the backup.", confirm = "Restore the latest backup for this profile?", func = RestoreProfile}),
			Revert = Opt:Execute({name = "Revert Exact Backup", desc = "Replace matching current settings with the exact values from the backup.", confirm = "Revert this profile to its latest exact backup?", func = RevertProfile}),
		}}),
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
