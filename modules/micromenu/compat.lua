-- Client-specific menu availability; common menu layout and styling stay shared.
local LUI = select(2, ...)
local module = LUI:GetModule("Micromenu")
local rules = {
    Player = "CharacterPanelDisabled", Spellbook = "ProfessionsPanelDisabled",
    Quests = "QuestLogMicrobuttonDisabled", Housing = "HousingDashboardDisabled",
    Guild = "CommunitiesPanelDisabled", LFG = "FinderPanelDisabled",
    Collections = "CollectionsPanelDisabled", EJ = "EncounterJournalDisabled",
    Store = "StoreDisabled", Achievements = "AchievementsPanelDisabled",
}
local functions = {
    Collections = "ToggleCollectionsJournal", EJ = "ToggleEncounterJournal",
    LFG = "ToggleLFDParentFrame", Achievements = "ToggleAchievementFrame",
}

function module:IsClientButtonAvailable(name)
    if name == "Legacy" then return LUI:HasClientFeature("Legacy") end
    if name == "Housing" or name == "LFG" or name == "EJ" then
        if not LUI:HasClientFeature(name) then return false end
    end
    if not LUI.IsForever then return true end
    local rule = rules[name] and Enum.GameRule and Enum.GameRule[rules[name]]
    if rule and C_GameRules and C_GameRules.IsGameRuleActive
        and C_GameRules.IsGameRuleActive(rule) then return false end
    if name == "EJ" and GameRulesUtil and GameRulesUtil.EJIsDisabled
        and GameRulesUtil.EJIsDisabled() then return false end
    local action = functions[name]
    if action and type(_G[action]) ~= "function" then return false end
    if name == "Store" and not _G.StoreMicroButton then return false end
    return true
end
