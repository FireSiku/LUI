local addonname, addon = ...
local LUI = LibStub("AceAddon-3.0"):NewAddon(addon, addonname)
LUI.L = LibStub("AceLocale-3.0"):GetLocale(addonname)

SLASH_RELOADUI1 = "/rl"
SlashCmdList.RELOADUI = ReloadUI