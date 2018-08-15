local addonname, LUI = ...
local script = LUI:NewScript("BlizzScale", "AceEvent-3.0", "AceHook-3.0")

local IsAddOnLoaded = IsAddOnLoaded
local _G = _G

local blizzFrames = {
	--UI Frames
	"CharacterFrame",
	"DressUpFrame",
	"SpellBookFrame",
	"PlayerTalentFrame",
	"GossipFrame",
	"MerchantFrame",
	"MailFrame",
	"OpenMailFrame",
	"QuestFrame",
	"TradeFrame",
	"GuildFrame",
	"FriendsFrame",
	"RaidParentFrame",	-- Not sure what this frame is.
	"PVEFrame",
	"TaxiFrame",
	"ItemTextFrame",
	"QuestLogPopupDetailFrame",
	
	--Settings Frames
	"GameMenuFrame",
	"VideoOptionsFrame",
	"InterfaceOptionsFrame",
	"KeyBindingFrame",
	"MacroFrame",
	"HelpFrame",
	
	--LoadOnDemand Frames
	"CalendarFrame",
	"AchievementFrame",		-- Blizzard_AchievementUI
	"InspectFrame",			-- Blizzard_InspectUI
	"ItemSocketingFrame",	-- Blizzard_ItemSocketingUI
	"ArchaeologyFrame",		-- Blizzard_ArchaeologyUI
	"TradeSkillFrame",		-- Blizzard_TradeSkillUI
	"LookingForGuildFrame",	-- Blizzard_LookingForGuildUI
	"AuctionFrame",			-- Blizzard_AuctionUI
	"EncounterJournal",		-- Blizzard_EncounterJournal
	"PetJournalParent",		-- Blizzard_PetJournal
	"VoidStorageFrame",
	"TransmogrifyFrame",
	
	--Not sure if LoD
	"GarrisonMissionFrame",
	"GarrisonBuildingFrame",
	"GarrisonCapacitiveDisplayFrame",
	
}

local conflictAddons = {
	AuctionFrame = "Auc-Advanced"
}

-- Not Handled: Frames that need secure environment, causes taint.
local needSecure = {
	"StoreFrame",
}

local blizzEvents = {
	"PLAYER_LOGIN",
	"ARCHAEOLOGY_TOGGLE",
	"AUCTION_HOUSE_SHOW",
	"BARBER_SHOP_OPEN",
	"INSPECT_READY",
	"VOID_STORAGE_OPEN",
	"TRANSMOGRIFY_OPEN",
	"TRADE_SKILL_SHOW",
	"SOCKET_INFO_UPDATE",
}

local blizzHooks = {
	"AchievementFrame_LoadUI",
	"ArchaeologyFrame_LoadUI",
	"Calendar_LoadUI",
	"CollectionsJournal_LoadUI",
	"EncounterJournal_LoadUI",
	"MacroFrame_LoadUI",
	"KeyBindingFrame_LoadUI",
	"Garrison_LoadUI",
}

function script:ApplyBlizzScaling()
	local scale = LUI.db.profile.General.BlizzFrameScale
	
	if InCombatLockdown() then
		script:RegisterEvent("PLAYER_REGEN_ENABLED", "EventHandling")
		return
	end
	
	for i = 1, #blizzFrames do
		local frameName = blizzFrames[i]
		local frame = _G[frameName]
		--Check if the frame exists
		if frame then
			--Check if the frame has no conflicting addons, or that the addon isn't loaded.
			if not conflictAddons[frameName] or not IsAddOnLoaded(conflictAddons[frameName]) then
				frame:SetScale(scale)
			end
			
			--HACK: Fix a bug in GarrisonUI having low frame level.
			if frameName == "GarrisonCapacitiveDisplayFrame" then
				frame:SetFrameLevel(70)
			end
		end
	end
end

function script:EventHandling(event)
	script:UnregisterEvent(event)
	script:ApplyBlizzScaling()
end

do
	for i = 1, #blizzEvents do
		script:RegisterEvent(blizzEvents[i], "EventHandling")
	end
	for i = 1, #blizzHooks do
		script:SecureHook(blizzHooks[i], function()
			script:ApplyBlizzScaling()
			script:Unhook(blizzHooks[i])
		end)
	end
end
