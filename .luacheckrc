max_line_length = false

exclude_files = {
	"libs",
	"api\\oUF",
	"api\\oUF11",
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
		"format", "strsub", "strfind", "strmatch", "strsplit", "strlower", "gsub", "wipe", "tinsert", "tremove", "floor", "ceil", "date",
		"debugprofilestop", "tDeleteItem", "tContains",

		-- Common Globals
		"UIParent", "UISpecialFrames", "CreateFrame", "CreateColor", "CreateFont", "CreateFromMixins", "GameTooltip", "UIWidgetManager",
		"CopyTable", "GetTime", "GetBuildInfo", "ReloadUI", "StaticPopupDialogs", "StaticPopup_Show", "IsForbidden", "NegateIf",
		
		-- Object API
		"Mixin", "Enum", "ContinuableContainer", "Item", "ItemLocation", "PlayerLocation", "Spell", "UiMapPoint",

		-- C_API Tables
		"C_ToyBox", "C_NamePlate", "C_AccountInfo", "C_TransmogCollection", "C_PlayerInteractionManager", "C_Console", "C_RecruitAFriend", "C_QuestLine", "C_ModifiedInstance",
		"C_SocialRestrictions", "C_ClassTalents", "C_MapExplorationInfo", "C_WeeklyRewards", "C_SocialQueue", "C_FriendList", "C_CVar", "C_PlayerMentorship", "C_Navigation", 
		"C_System", "C_QuestLog", "C_PetJournal", "C_CreatureInfo", "C_Club", "C_NewItems", "C_SpellBook", "C_WowTokenUI", "C_Covenants", "C_ItemSocketInfo", "C_ReturningPlayerUI",
		"C_Debug", "C_FunctionContainers", "C_TaxiMap", "C_AuctionHouse", "C_BattleNet", "C_PartyInfo", "C_ClubFinder", "C_SystemVisibilityManager", "C_ChallengeMode",
		"C_ChromieTime", "C_PrototypeDialog", "C_AzeriteItem", "C_ScriptedAnimations", "C_LootJournal", "C_KeyBindings", "C_LevelSquish", "C_ClassTrial", "C_InvasionInfo", 
		"C_GamePad", "C_LossOfControl", "C_ResearchInfo", "C_CharacterServicesPublic", "C_EventUtils", "C_ItemUpgrade", "C_PetBattles", "C_SuperTrack", "C_CovenantCallings",
		"C_ItemInteraction", "C_UnitAuras", "C_AdventureMap", "C_ScenarioInfo", "C_BlackMarket", "C_GossipInfo", "C_GuildInfo", "C_PvP", "C_IslandsQueue", "C_UIColor",
		"C_Map", "C_Commentator", "C_LFGList", "C_PartyPose", "C_EquipmentSet", "C_BarberShop", "C_Sound", "C_AnimaDiversion", "C_LoreText", "C_FogOfWar", "C_Calendar",
		"C_LegendaryCrafting", "C_FrameManager", "C_CameraDefaults", "C_ModelInfo", "C_CovenantPreview", "C_Transmog", "C_CampaignInfo", "C_Traits", "C_StorePublic",
		"C_LootHistory", "C_TooltipComparison", "C_TransmogSets", "C_Social", "C_AchievementInfo", "C_WowTokenPublic", "C_TooltipInfo", "C_Trophy", "C_ClassColor",
		"C_AlliedRaces", "C_Item", "C_SummonInfo", "C_PaperDollInfo", "C_Texture", "C_AzeriteEssence", "C_ArdenwealdGardening", "C_Soulbinds", "C_EncounterJournal",
		"C_HeirloomInfo", "C_Cursor", "C_ActionBar", "C_ZoneAbility", "C_XMLUtil", "C_Spell", "C_ChatInfo", "C_MountJournal", "C_ChatBubbles", "C_VoiceChat",
		"C_ContributionCollector", "C_LevelLink", "C_SplashScreen", "C_MajorFactions", "C_ReportSystem", "C_PetInfo", "C_Widget", "C_StableInfo", "C_VideoOptions",
		"C_Loot", "C_ProfSpecs", "C_CurrencyInfo", "C_IncomingSummon", "C_VignetteInfo", "C_AzeriteEmpoweredItem", "C_DeathInfo", "C_CraftingOrders", "C_RaidLocks",
		"C_PlayerInfo", "C_TradeSkillUI", "C_TalkingHead", "C_Timer", "C_EditMode", "C_DateAndTime", "C_MerchantFrame", "C_EventToastManager", "C_ToyBoxInfo", "C_Mail",
		"C_QuestOffer", "C_SharedCharacterServices", "C_Minimap", "C_Tutorial", "C_TaskQuest", "C_QuestSession", "C_MythicPlus", "C_Container", "C_LFGInfo", "C_UIWidgetManager",
		"C_AreaPoiInfo", "C_CovenantSanctumUI", "C_AdventureJournal", "C_Garrison", "C_Heirloom", "C_ScrappingMachineUI", "C_QuestItemUse", "C_PlayerChoice", "C_ClickBindings",
		"C_ArtifactUI", "C_UserFeedback", "C_UI", "C_TTSSettings", "C_SpecializationInfo", "C_CharacterServices", "C_Scenario", "C_BehavioralMessaging", "C_Reputation",
	}
}

		