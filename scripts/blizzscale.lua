---@class LUIAddon
local LUI = select(2, ...)
local script = LUI:NewScript("BlizzScale", "AceEvent-3.0")

local InCombatLockdown = _G.InCombatLockdown

local blizzFrames = {
	"CharacterFrame",
	"DressUpFrame",
	"PlayerSpellsFrame",
	"GossipFrame",
	"MerchantFrame",
	"MailFrame",
	"OpenMailFrame",
	"QuestFrame",
	"TradeFrame",
	"CommunitiesFrame",
	"FriendsFrame",
	"RaidParentFrame",
	"PVEFrame",
	"TaxiFrame",
	"ItemTextFrame",
	"QuestLogPopupDetailFrame",
	"GameMenuFrame",
	"SettingsPanel",
	"KeyBindingFrame",
	"MacroFrame",
	"HelpFrame",

	"CalendarFrame",
	"AchievementFrame",
	"InspectFrame",
	"ItemSocketingFrame",
	"ArchaeologyFrame",
	"ProfessionsFrame",
	"AuctionHouseFrame",
	"EncounterJournal",
	"CollectionsJournal",
	"TransmogFrame",
	"GarrisonMissionFrame",
	"GarrisonBuildingFrame",
	"GarrisonCapacitiveDisplayFrame",
}

function script:ApplyBlizzScaling()
	local scale = LUI.db.profile.General.BlizzFrameScale
	
	if InCombatLockdown() then
		script:RegisterEvent("PLAYER_REGEN_ENABLED", "EventHandling")
		return
	end
	
	for _, frameName in ipairs(blizzFrames) do
		local frame = _G[frameName]
		if frame then
			frame:SetScale(scale)
		end
	end
end

function script:EventHandling(event)
	if event == "PLAYER_REGEN_ENABLED" then script:UnregisterEvent(event) end
	script:ApplyBlizzScaling()
end

script:RegisterEvent("PLAYER_LOGIN", "EventHandling")
script:RegisterEvent("ADDON_LOADED", "EventHandling")
