-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)
local L = LUI.L

---@class LUI.ExperienceBars
local module = LUI:GetModule("Experience Bars")

local SHORT_REPUTATION_NAMES = {
	L["ExpBar_ShortName_Hatred"],		-- Ha
	L["ExpBar_ShortName_Hostile"],		-- Ho
	L["ExpBar_ShortName_Unfriendly"],	-- Un
	L["ExpBar_ShortName_Neutral"],		-- Ne
	L["ExpBar_ShortName_Friendly"],		-- Fr
	L["ExpBar_ShortName_Honored"],		-- Hon
	L["ExpBar_ShortName_Revered"],		-- Rev
	L["ExpBar_ShortName_Exalted"],		-- Ex
}

local GetWatchedFactionInfo = _G.GetWatchedFactionInfo
local C_Reputation = C_Reputation

-- ####################################################################################################################
-- ##### ReputationDataProvider #######################################################################################
-- ####################################################################################################################
-- Blizzard store reputation in an interesting way.
-- barMin represents the minimum bound for the current standing, barMax represents the maximum bound.
-- For example, barMin for revered is 21000 (3000+6000+12000 from Neutral to Honored), barMax is 42000.
-- To get a 0 / 21000 representation, we have to reduce all three values by barMin.
-- Patch 7.2 changed barMin to be equal to barMax at Exalted, so we need to handle that too.
--- @TODO: Add support for Friendships

local ReputationDataProvider = module:CreateBarDataProvider("Reputation")

ReputationDataProvider.BAR_EVENTS = {
	"QUEST_LOG_UPDATE",
	"UPDATE_FACTION",
}

function ReputationDataProvider:ShouldBeVisible()
	local name = GetWatchedFactionInfo()
	if name then return true end
end

function ReputationDataProvider:GetParagonValues(factionID)
	-- currentValue is the total amount of paragon a character accrued.
	-- Need to remove threshold value out of currentValue for every reward already received.

	local currentValue, rewardThreshold, _,  rewardPending = C_Reputation.GetFactionParagonInfo(factionID)
	currentValue = (currentValue - rewardThreshold) % rewardThreshold

	if rewardPending then
		-- If there's a reward pending, the bar should be full, adjust percent value to be above 100%
		self.repText = L["ExpBar_ShortName_Reward"]
		return currentValue + rewardThreshold, rewardThreshold
	else
		self.repText = L["ExpBar_ShortName_Paragon"]
		return currentValue, rewardThreshold
	end
end

function ReputationDataProvider:GetMajorValues(factionID)
	local majorFactionData = C_MajorFactions.GetMajorFactionData(factionID)
	
	self.repText = "R+" .. majorFactionData.renownLevel
	return majorFactionData.renownReputationEarned, majorFactionData.renownLevelThreshold
end

function ReputationDataProvider:GetFriendshipValues(factionID)
	local reputationInfo = C_GossipInfo.GetFriendshipReputation(factionID)
	self.repText = reputationInfo.reaction
	-- If the friendship is maxed, there will not be a next threshold, so we can just return a full bar.
	if not reputationInfo.nextThreshold then return 1, 1 end

	-- reactionThreshold is the amount that was needead to get to the current friendship rank.
	-- nextThreshold is the amount needed to get to the next threshold
	-- Standing is the current total reputation. 
	local barMax = reputationInfo.nextThreshold - reputationInfo.reactionThreshold
	local barValue = reputationInfo.standing - reputationInfo.reactionThreshold

	return barValue, barMax
end

function ReputationDataProvider:Update()
	local _, standing, barMin, barMax, barValue, factionID = GetWatchedFactionInfo()

	self.repText = SHORT_REPUTATION_NAMES[standing]
	local friendshipInfo = C_GossipInfo.GetFriendshipReputation(factionID)

	-- Check for the various types of reputations
	if C_Reputation.IsFactionParagon(factionID) and barMin == barMax then
		barValue, barMax = self:GetParagonValues(factionID)

	elseif C_Reputation.IsMajorFaction(factionID) then
		barValue, barMax = self:GetMajorValues(factionID)

	elseif friendshipInfo and friendshipInfo.maxRep > 0 then
		barValue, barMax = self:GetFriendshipValues(factionID)
		
	elseif barMin == barMax then
		barValue, barMax = 1, 1
	else
		-- For regular reputations, barValue is the cumulative of all ranks.
		-- barMin is the value for all ranks before the current one.
		barMax = barMax - barMin
		barValue = barValue - barMin
	end
	
	self.barMin = 0
	self.barMax = barMax
	self.barValue = barValue
end

function ReputationDataProvider:GetDataText()
	return self.repText
end
