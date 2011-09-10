local addonname, LUI = ...
local script = LUI:NewScript("BlizzScale", "AceEvent-3.0")

function script:SetBlizzScale()
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
		PVPFrame,
		LFDParentFrame,
		LFRParentFrame,
		HelpFrame,
		MacroFrame,
		GameMenuFrame,
		VideoOptionsFrame,
		InterfaceOptionsFrame,
		KeyBindingFrame,
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

	script:RegisterEvent("ADDON_LOADED", function(event, name)
		if name == nil then return end
		if select(7, GetAddOnInfo(name)) == "SECURE" then script:SetBlizzScale() end
	end)
	script:SetBlizzScale()
end)