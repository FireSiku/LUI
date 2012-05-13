local addonname, LUI = ...

local L = _G.LibStub("AceLocale-3.0"):NewLocale(addonname, "deDE")
if not L then return end

--@localization(locale="deDE", format="lua_additive_table", handle-unlocalized="comment", same-key-is-true=true)@