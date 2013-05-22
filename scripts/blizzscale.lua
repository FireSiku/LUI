local addonname, LUI = ...
local script = LUI:NewScript("BlizzScale", "AceEvent-3.0")

function script:ADDON_LOADED(event, name)
	if event == "ADDON_LOADED" and (name == nil or select(7, GetAddOnInfo(name)) ~= "SECURE") then return end
	if InCombatLockdown() then
		self:RegisterEvent("PLAYER_REGEN_ENABLED", "ADDON_LOADED")
		return
	elseif event == "PLAYER_REGEN_ENABLED" then
		self:UnregisterEvent(event)
	end
	
	local scale = LUI.db.profile.General.BlizzFrameScale
	local blizzFrames = {
		CalendarFrame,
		CharacterFrame,
		DressUpFrame,
		ItemSocketingFrame,
		InspectFrame,
		SpellBookFrame,
		PlayerTalentFrame,
		QuestLogFrame,
		QuestFrame,
		QuestLogDetailFrame,
		ArchaeologyFrame,
		GossipFrame,
		AchievementFrame,
		MerchantFrame,
		TradeFrame,
		MailFrame,
		OpenMailFrame,
		TradeSkillFrame,
		ClassTrainerFrame,
		ReforgingFrame,
		LookingForGuildFrame,
		GuildFrame,
		FriendsFrame,
		RaidParentFrame,
		HelpFrame,
		MacroFrame,
		GameMenuFrame,
		VideoOptionsFrame,
		InterfaceOptionsFrame,
		KeyBindingFrame,
		PVEFrame,
		PVPUIFrame,
	}

	for _, frame in pairs(blizzFrames) do
		if frame then frame:SetScale(scale) end
	end

	if AuctionFrame and not IsAddOnLoaded("Auc-Advanced") then
		AuctionFrame:SetScale(scale)
	end
end

script:RegisterEvent("PLAYER_LOGIN", function(event)
	script:UnregisterEvent(event)

	script:RegisterEvent("ADDON_LOADED")
	script:ADDON_LOADED()
end)