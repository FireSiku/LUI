local parent, LUI = ...

local L = LibStub("AceLocale-3.0"):NewLocale(parent, "deDE")
if not L then return end

--------------------------------------------------
-- Core
--------------------------------------------------

-- Common
L["Enable"] = "Ermöglichen"
--L["General Settings"] = true
--L["Font"] = true
--L["Choose a font"] = true
--L["Flag"] = true
--L["Choose a font flag"] = true
--L["Size"] = true
--L["Choose a fontsize"] = true
--L["Width"] = true
--L["Height"] = true
--L["Scale"] = true
--L["Anchor Point"] = true
--L["Top"] = true
--L["Bottom"] = true
--L["Left"] = true
--L["Right"] = true
--L["Adjust the top inset of the background"] = true
--L["Adjust the bottom inset of the background"] = true
--L["Adjust the left inset of the background"] = true
--L["Adjust the right inset of the background"] = true
--L["Background"] = true
--L["Border"] = true
--L["Texture"] = true
--L["Choose a texture"] = true
--L["Tile"] = true
--L["Should the background texture be tiled over the area"] = true
--L["Tile Size"] = true
--L["Adjust the size of each tile of the background texture"] = true
--L["Thickness"] = true
--L["Adjust the thickness of the border"] = true
--L["Insets"] = true

-- LUI.lua
--L["Welcome to LUI v3"] = "Welcome to |c0090ffffLUI v3|r the first and only NextGeneration\nWorld of Warcraft User Interface."
--L["Please read the FAQ"] = "Please read the FAQ if you have Questions!\nFor more information please visit\n|cff8080ffhttp://www.wow-lui.com|r\n|cff8080ffhttp://wowinterface.com|r\n\nEnjoy!|r"
--L["Version: "] = true
--L["Revision: "] = true

L["Version %s available for download."] = "Version %s steht zum Download bereit."

L["The UI needs to be reloaded!"] = "Die UI neu geladen werden muss!"

--------------------------------------------------
-- Chat
--------------------------------------------------

--L["Short channel names"] = true
--L["Use abreviated channel names"] = true
--L["Disable fading"] = true
--L["Stop the chat from fading out over time"] = true
--L["Minimalist tabs"] = true
--L["Use minimalist style tabs"] = true
--L["Chat Background"] = true
--L["Buttons"] = true
L["Hide Buttons"] = "Verstecken Schaltflächen"
L["Scroll to bottom button"] = "Blättern Sie nach unten-Taste"
--L["Show scroll to bottom button when scrolled up"] = true
--L["Scale of the scroll to bottom button"] = true
--L["Copy chat button"] = true
--L["Show copy chat button"] = true
--L["Scale of the copy chat button"] = true
--L["EditBox"] = true
--L["Free-floating"] = true
--L["Free-floating (Locked)"] = true
--L["Select where the EditBox anchors to the ChatFrame"] = true
--L["Remember history"] = true
--L["Remembers the history of the EditBox across sessions"] = true
--L["Use Alt key"] = true
--L["Requires the Alt key to be held down to move the cursor"] = true
--L["Color by channel"] = true
--L["Sets the EditBox color to the color of you currently active channel"] = true
--L["Adjust the height of the EditBox"] = true

L["Guild"] = "Gilde"
L["Officer"] = "Offizier"
L["Party"] = "Gruppe"
L["Dungeon Guide"] = "Dungeonführer"
L["Raid"] = "Schlachtzug"
L["Raid Leader"] = "Schlachtzugsleiter"
L["Raid Warning"] = "Schlachtzugswarnung"
L["Battleground"] = "Schlachtfeld"
L["Battleground Leader"] = "Schlachtfeldleiter"
--L["General"] = true
--L["Trade"] = true
--L["LocalDefense"] = true
--L["WorldDefense"] = true
--L["LookingForGroup"] = true

L["To (|Hplayer.-|h):"] = "Zu (|Hplayer.-|h):"
L["(|Hplayer.-|h) whispers:"] = "(|Hplayer.-|h) flüstert:"
L["To (|HBNplayer.-|h):"] = "Zu (|HBNplayer.-|h):"
L["(|HBNplayer.-|h) whispers:"] = "(|HBNplayer.-|h) flüstert:"

L["[G]"] = true
L["[O]"] = true
L["[P]"] = "[GR]"
--L["[PL]"] = true
--L["[DG]"] = "[DF]"
--L["[R]"] = "[S]"
--L["[RL]"] = "[SL]"
--L["[RW]"] = "[SW]"
--L["[BG]"] = true
--L["[BL]"] = true
--L["[General]"] = "[Allgemein]"
--L["[Trade]"] = "[Handel]"
--L["[LocalDefense]"] = "[LokaleVerteidigung]"
--L["[WorldDefense]"] = "[Welt-Defense]"
--L["[LFG]"] = true
L["[F:Aus]"] = true
L["[F:Zu]"] = true
L["[BN:Aus]"] = true
L["[BN:To]"] = true

--------------------------------------------------
-- World Map
--------------------------------------------------

L["Hide Completely"] = "Vollständig verstecken"
L["Only Show Markers"] = "Nur Weltkartenmarkierungen"
L["Quest Objectives"] = "Questziele"
L["Show Markers & Panels"] = "Markierungen & Panels"
L["Player"] = "Spieler"
L["Cursor"] = "Mauszeiger"
L["Classic Instances"] = "Classic Instanzen"
L["Classic Raids"] = "Classic Raids"
L["BC Instances"] = "BC Instanzen"
L["BC Raids"] = "BC Raids"
L["Wrath Instances"] = "Wrath Instanzen"
L["Wrath Raids"] = "Wrath Raids"
L["Cataclysm Instances"] = "Cataclysm Instanzen"
L["Cataclysm Raids"] = "Cataclysm Raids"
L["Battlegrounds"] = "Schlachtfelder"

--------------------------------------------------
-- Unitframes
--------------------------------------------------

L["Blizzard currently does not provide a proper way to right-click focus with custom unit frames."] = "Blizzard bietet derzeit keinen geeigneten Weg an, um mittels Rechtsklick auf benutzerdefinierte Einheiten-Rahmen ein Fokusziel zu setzen."
L["Initiate a ready check, asking your group members if they are ready to continue."] = "Bereitschaftsabfrage einleiten, um festzustellen, ob deine Gruppenmitglieder bereit sind, fortzusetzen."
L["Initiate a role check, asking your group members to specify their roles."] = "Rollenabfrage einleiten, um deine Gruppenmitglieder zu bitten, ihre Rollen zu bestimmen."
L["Type %s to Clear Focus"] = "Gib %s ein, um den Fokus zu entfernen."
L["Type %s to Set Focus"] = "Gib %s ein, um den Fokus zu setzen."