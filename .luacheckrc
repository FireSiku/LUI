max_line_length = false

exclude_files = {
	"libs",
	"api\\oUF",
	"api\\emmy",
	"unitframes\\core",
    ".luacheckrc",
	".vsode",
}

ignore = {
	"12.", -- ignore "Setting a read-only global variable/Setting a read-only field of a global variable."
	"43.", -- Shadowed upvalues happens often when writing scripts or trying to work with another module.
	"542", -- disable warnings for empty if branches. These are useful sometimes and easy to notice otherwise.
	"614", -- disable "Trailing whitespace in a comment", used by language server docs comments
	"611", -- disable "line contains only whitespace"
	"21.", -- Disable unused warnings
}

std = "+LUI+WoW"

-- Globals set or defined by LUI. Most of these are for debug purposes and should be
-- either refactored or removed before the big release.
stds["LUI"] = {
	globals = {
		"LUI", "LUICONFIG", "PrintTooltips", "GFind", "GFindValue", "GFindCTables",
 		"GetMinimapShape", "LUIBank", "LUIReagents", "LUIBags",
		"oUF_LUI_player", "oUF_LUI_target", "oUF_LUI_pet", "oUF_LUI_focus",  "oUF_LUI_focustarget",
		"oUF_LUI_party", "oUF_LUI_raid", "oUF_LUI_raid_25", "oUF_LUI_raid_40", "oUF_LUI_boss",
		"oUF_LUI_arena","oUF_LUI_maintank", "oUF_LUI_targettarget",

		-- Globals that comes from Libraries, or related community-created API calls.
		"LibStub", "CUSTOM_CLASS_COLORS", "AceGUIWidgetLSMlists", "oUF", "oUF_RaidDebuffs"
    }
}

-- Only C_ API and select few common calls be added in globals here, the rest should be called through _G.
-- Regex used for formatting: Find: (.{150}.*?,)\s Replace: $1\n\t\t
stds["WoW"] = {
	globals = {
		-- Lua Additions
		string = { fields = { "join", "rtgsub", "split", "trim", }},
		table = { fields = { "removemulti", "wipe", }},
		"format", "strsub", "strfind", "strmatch", "strsplit", "strlower", "gsub", "wipe", "tinsert", "tremove", "floor", "ceil",
		"debugprofilestart", "debugprofilestop",

		-- Common Globals
		"UIParent", "UISpecialFrames", "CreateFrame", "CreateColor", "CreateFromMixins", "GameTooltip", "UIWidgetManager", 
		"CopyTable", "GetTime", "GetBuildInfo", "ReloadUI", "StaticPopup_Show", "IsForbidden", "NegateIf",
		
		-- Object API
		"Mixin", "Enum", "Spell", "Item", "ItemLocation", "PlayerLocation", "UiMapPoint",

		-- C_API Tables
		"C_ToyBox", "C_NamePlate", "C_AccountInfo", "C_TransmogCollection", "C_ChatBubbles", "C_Console", "C_RecruitAFriend", "C_QuestLine", "C_SocialRestrictions",
		"C_MapExplorationInfo", "C_SocialQueue", "C_FriendList", "C_CVar", "C_QuestLog", "C_PetJournal", "C_CreatureInfo", "C_Club", "C_NewItems", "C_SpellBook",
		"C_UI", "C_ItemSocketInfo", "C_AchievementInfo", "C_AuctionHouse", "C_BattleNet", "C_Scenario", "C_PartyInfo", "C_ClubFinder", "C_ChallengeMode", "C_PrototypeDialog",
		"C_AzeriteItem", "C_WowTokenUI", "C_LootJournal", "C_KeyBindings", "C_Timer", "C_LFGuildInfo", "C_LossOfControl", "C_ResearchInfo", "C_LevelLink", "C_ItemUpgrade",
		"C_VignetteInfo", "C_PetBattles", "C_ItemInteraction", "C_AdventureMap", "C_BlackMarket", "C_ArtifactUI", "C_GossipInfo", "C_InvasionInfo", "C_IslandsQueue",
		"C_Map", "C_Commentator", "C_LFGList", "C_PartyPose", "C_EquipmentSet", "C_PvP", "C_Calendar", "C_DateAndTime", "C_ModelInfo", "C_Transmog", "C_CampaignInfo",
		"C_StorePublic", "C_LootHistory", "C_TransmogSets", "C_Social", "C_ToyBoxInfo", "C_WowTokenPublic", "C_Trophy", "C_ClassColor", "C_AlliedRaces", "C_Item",
		"C_SummonInfo", "C_TaskQuest", "C_TaxiMap", "C_Texture", "C_AzeriteEssence", "C_QuestChoice", "C_SharedCharacterServices", "C_EncounterJournal", "C_ActionBar",
		"C_MountJournal", "C_Spell", "C_Cursor", "C_ChatInfo", "C_VideoOptions", "C_CharacterServicesPublic", "C_ContributionCollector", "C_ReportSystem", "C_PetInfo",
		"C_Widget", "C_Loot", "C_CurrencyInfo", "C_IncomingSummon", "C_AzeriteEmpoweredItem", "C_RaidLocks", "C_TradeSkillUI", "C_PlayerInfo", "C_DeathInfo", "C_TalkingHead",
		"C_MerchantFrame", "C_QuestSession", "C_GuildInfo", "C_Mail", "C_Debug", "C_VoiceChat", "C_FogOfWar", "C_MythicPlus", "C_LFGInfo", "C_UIWidgetManager", "C_Reputation",
		"C_AreaPoiInfo", "C_AdventureJournal", "C_PaperDollInfo", "C_ClassTrial", "C_ScrappingMachineUI", "C_Garrison", "C_Heirloom", "C_SpecializationInfo", "C_CharacterServices",
	}
}