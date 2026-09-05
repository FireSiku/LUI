-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class Opt
local Opt = select(2, ...)

---@type AceLocale.Localizations, LUI.Infotext, AceDB-3.0
local L, module, db = Opt:GetLUIModule("Infotext")

local topBarTextAnchors = {
	TOP = L["Top"],
	MIDDLE = L["Center"],
	BOTTOM = L["Bottom"],
}
if not module or not module.registered then return end

local Infotext = Opt:CreateModuleOptions("Infotext", module)

-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################

local function InfoTextGroup(name)
    local group = Opt:Group({name = name, db = db[name], args = {
		Header = Opt:Header({name = name}),
		Enable = Opt:Toggle({name = "Enable", width = "full"}),
		X = Opt:PositionX(),
		Y = Opt:PositionY(),
		Point = Opt:Select({name = L["Anchor Point"], desc = "Set which part of the screen the "..name.." infotext will be anchored to.", values = LUI.Points}),
		Color = Opt:Color({name = "Text Color", hasAlpha = true, db = db[name]}),
	}})
	return group
end

local function DisableIfBackgroundTextured(background)
	return function() return background.Texture ~= "None" end
end

-- ####################################################################################################################
-- ##### Options Tables ###############################################################################################
-- ####################################################################################################################

local SettingsArgs = {}
local elementNames, knownNames = {}, {}
for name in module:IterateElements() do
	knownNames[name] = true
end
for name in module:IterateDisplays() do
	knownNames[name] = true
end
for name in pairs(knownNames) do
	elementNames[#elementNames + 1] = name
end
table.sort(elementNames)
for _, name in ipairs(elementNames) do
	SettingsArgs[name] = InfoTextGroup(name)
end

function Opt:LUIInfotextDataObjectCreated(_, name)
	if not SettingsArgs[name] then
		SettingsArgs[name] = InfoTextGroup(name)
	end
	self:RefreshOptionsPanel()
end

module.LDB.RegisterCallback(Opt, "LibDataBroker_DataObjectCreated", "LUIInfotextDataObjectCreated")

Infotext.args = {
	Header = Opt:Header({name = "Infotext"}),
	Settings = Opt:Group({name = "Individual Settings", args = SettingsArgs}),
	General = Opt:Group({name = "Global Settings", args = {
		InfotextFont = Opt:FontMenu({name = "Infotext Font", customFontLocation = "Infotext"}),
		TopBarPlacement = Opt:InlineGroup({name = "Top Bar Placement", db = db, args = {
			TopBarTextAnchor = Opt:Select({name = "Vertical Alignment", desc = "Choose where every top-screen infotext sits inside the LUI top bar.", values = topBarTextAnchors}),
			TopBarOffsetX = Opt:PositionX({name = "Left / Right", desc = "Move all top-bar infotexts left or right. Individual infotext positions remain unchanged."}),
			TopBarOffsetY = Opt:PositionY({name = "Down / Up", desc = "Move all top-bar infotexts down or up. Individual infotext positions remain unchanged."}),
		}}),
		InfotipFont = Opt:FontMenu({name = "Infotext Hover Font", desc = "Font used inside the custom Guild and Friends windows shown on mouseover.", customFontLocation = "Infotip"}),
		Title = Opt:Color({name = "Title Color", hasAlpha = false}),
		Hint = Opt:Color({name = "Hint Color", hasAlpha = false}),
		Status = Opt:Color({name = "Status Color", hasAlpha = false}),
		GameText = Opt:Color({name = "Game Text Color", hasAlpha = false}),
		Rank = Opt:Color({name = "Guild Rank Color", hasAlpha = false}),
		Zone = Opt:Color({name = "Zone Color", hasAlpha = false}),
		MOTD = Opt:Color({name = "Guild Message Color", hasAlpha = false}),
		Note = Opt:Color({name = "Note Color", hasAlpha = false}),
		Broadcast = Opt:Color({name = "Broadcast Color", hasAlpha = false}),
		FriendBroadcast = Opt:Color({name = "Friend Broadcast Color", hasAlpha = false}),
	}}),
}

local clockArgs = Infotext.args.Settings.args.Clock.args
clockArgs.instanceDifficulty = Opt:Toggle({name = "Show Instance Difficulty", width = "full"})
clockArgs.showSavedRaids = Opt:Toggle({name = "Show Saved Raids in Tooltip", width = "full"})
clockArgs.showWorldBosses = Opt:Toggle({name = "Show Saved World Bosses in Tooltip", width = "full"})

local currencyArgs = Infotext.args.Settings.args.Currency.args
currencyArgs.DisplayLimit = Opt:Slider({name = "Tooltip Currency Limit", min = 5, max = 100, step = 1})

local dualspecArgs = Infotext.args.Settings.args.Dualspec.args
dualspecArgs.lootSpec = Opt:Toggle({name = "Show Loot Specialization", width = "full"})

local equipmentArgs = Infotext.args.Settings.args.EquipmentSets.args
equipmentArgs.Text = Opt:Input({name = "Text Prefix", width = "full"})

local fpsArgs = Infotext.args.Settings.args.FPS.args
fpsArgs.MSValue = Opt:Select({name = "Latency Display", values = {Both = "Home and World", Home = "Home", World = "World"}})

local friendsArgs = Infotext.args.Settings.args.Friends.args
friendsArgs.showTotal = Opt:Toggle({name = "Show Total Friend Count", width = "full"})
friendsArgs.ShowNotes = Opt:Toggle({name = "Show Friend Notes", width = "full"})
friendsArgs.ShowHints = Opt:Toggle({name = "Show Mouse Hints", width = "full"})
friendsArgs.Background = Opt:InlineGroup({name = "Friends Window Appearance", args = {
	Texture = Opt:MediaBackground({name = "Texture", db = db.Friends.Background}),
	Color = Opt:Color({name = "Color", hasAlpha = true, db = db.Friends.Background,
		disabled = DisableIfBackgroundTextured(db.Friends.Background)}),
	BorderTexture = Opt:MediaBorder({name = "Border Texture", db = db.Friends.Background}),
	Border = Opt:Color({name = "Border Color", hasAlpha = true, db = db.Friends.Background}),
}})

local goldArgs = Infotext.args.Settings.args.Gold.args
goldArgs.showRealm = Opt:Toggle({name = "Show Realm Total", width = "full"})
goldArgs.useBlizzard = Opt:Toggle({name = "Use Blizzard Money Format", width = "full"})
goldArgs.showCopper = Opt:Toggle({name = "Show Copper with Gold", width = "full"})
goldArgs.coloredSymbols = Opt:Toggle({name = "Color Coin Symbols", width = "full"})

local guildArgs = Infotext.args.Settings.args.Guild.args
guildArgs.showTotal = Opt:Toggle({name = "Show Total Guild Count", width = "full"})
guildArgs.hideRealm = Opt:Toggle({name = "Hide Realm Names", width = "full"})
guildArgs.hideNotes = Opt:Toggle({name = "Hide Guild Notes", width = "full"})
guildArgs.Background = Opt:InlineGroup({name = "Guild Window Appearance", args = {
	Texture = Opt:MediaBackground({name = "Texture", db = db.Guild.Background}),
	Color = Opt:Color({name = "Color", hasAlpha = true, db = db.Guild.Background,
		disabled = DisableIfBackgroundTextured(db.Guild.Background)}),
	BorderTexture = Opt:MediaBorder({name = "Border Texture", db = db.Guild.Background}),
	Border = Opt:Color({name = "Border Color", hasAlpha = true, db = db.Guild.Background}),
}})

local mailArgs = Infotext.args.Settings.args.Mail.args
mailArgs.NewIndic = Opt:Input({name = "New Mail Indicator", width = "full"})

local lootSpecArgs = Infotext.args.Settings.args.LootSpec.args
lootSpecArgs.Text = Opt:Input({name = "Text Prefix", width = "full"})

-- ####################################################################################################################
-- ##### Gold Infotext ################################################################################################
-- ####################################################################################################################

local goldDB = module.db.global.Gold
local goldPlayerReset = ""
local goldPlayerArray = {}
local goldPlayerLookup = {}

local function BuildGoldPlayerArray()
	wipe(goldPlayerArray)
	wipe(goldPlayerLookup)
	for faction, realmData in pairs(goldDB) do
		for realm, playerData in pairs(realmData) do
			for player in pairs(playerData) do
				local key = faction.."\031"..realm.."\031"..player
				goldPlayerArray[key] = realm.."-"..player
				goldPlayerLookup[key] = {faction = faction, realm = realm, player = player}
			end
		end
	end
	return goldPlayerArray
end

local function ResetGold()
	local entry = goldPlayerLookup[goldPlayerReset]
	if not entry then return end
	if entry.player == LUI.playerName and entry.realm == LUI.playerRealm and entry.faction == LUI.playerFaction then
		goldDB[entry.faction][entry.realm][entry.player] = GetMoney()
	else
		goldDB[entry.faction][entry.realm][entry.player] = nil
		goldPlayerArray[goldPlayerReset] = nil
		goldPlayerLookup[goldPlayerReset] = nil
	end
	goldPlayerReset = ""

	module:GetElement("Gold"):UpdateRealmMoney()
	module:GetElement("Gold"):UpdateGold()
end

local GoldInfotext = Infotext.args.Settings.args.Gold.args
GoldInfotext.ShowConnected = Opt:Toggle({name = "Include Connected Realms in Server Total when possible", width = "full",
	desc = "Realms that are connected to your character's realm will show as a single entry in the realm list"})
GoldInfotext.GoldPlayerReset = Opt:Select({name = "Reset Player", desc = "Choose the player you want to clear Gold data for.", values = BuildGoldPlayerArray,
											get = function() return goldPlayerReset end,
											set = function(info, value)
												BuildGoldPlayerArray()
												goldPlayerReset = value
											end})
GoldInfotext.GoldResetButton = Opt:Execute({name = "Reset", desc = "Clear Gold data for selected character.", func = ResetGold})
