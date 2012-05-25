-- Register the Reload UI Slash Command before anything can fail
SLASH_RELOADUI1 = "/rl"
SlashCmdList.RELOADUI = ReloadUI

local addonname, LUI = ...

LUI.Lib = _G.LibStub

LUI.Lib("AceAddon-3.0"):NewAddon(LUI, addonname, "AceComm-3.0", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")
LUI.L = LUI.Lib("AceLocale-3.0"):GetLocale(addonname)

