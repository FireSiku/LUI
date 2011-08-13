local parent, LUI = ...

local L = LibStub("AceLocale-3.0"):NewLocale(parent, "deDE")
if not L then return end

--------------------------------------------------
-- Core
--------------------------------------------------

-- LUI.lua
-- L["Welcome to LUI v3"] = "Welcome to |c0090ffffLUI v3|r the first and only NextGeneration\nWorld of Warcraft User Interface."
-- L["Please read the FAQ"] = "Please read the FAQ if you have Questions!\nFor more information please visit\n|cff8080ffhttp://www.wow-lui.com|r\n|cff8080ffhttp://wowinterface.com|r\n\nEnjoy!|r"
L["Version: "] = true
L["Revision: "] = true

L["Version %s available for download."] = "Version 3.5 steht zum Download bereit."

L["The UI needs to be reloaded!"] = "Die UI neu geladen werden muss!"

--------------------------------------------------
-- Modules
--------------------------------------------------

-- Map.lua
-- L["Hide Completely"] = 
-- L["Only Show Markers"] = 
L["Quest Objectives"] = "Questziele"
-- L["Show Markers & Panels"] = 