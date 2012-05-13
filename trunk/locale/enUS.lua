local addonname, LUI = ...

local silent = false
--@debug@
silent = true
--@end-debug@

local L = _G.LibStub("AceLocale-3.0"):NewLocale(addonname, "enUS", true, silent)

--@localization(locale="enUS", format="lua_additive_table", handle-unlocalized="comment", same-key-is-true=true)@