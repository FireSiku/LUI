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
		if frame and not (frame.IsForbidden and frame:IsForbidden()) then
			local currentScale = frame:GetScale()
			-- GetScale can round through a float (e.g. 0.85 -> 0.85000002).
			-- Avoid rewriting every existing window whenever any addon loads.
			if not issecretvalue(currentScale) and math.abs(currentScale - scale) > 0.000001 then
				frame:SetScale(scale)
			end
		end
	end
end

function script:EventHandling(event)
	if event == "PLAYER_REGEN_ENABLED" then script:UnregisterEvent(event) end
	script:ApplyBlizzScaling()
end

script:RegisterEvent("PLAYER_LOGIN", "EventHandling")
script:RegisterEvent("ADDON_LOADED", "EventHandling")
