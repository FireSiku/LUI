-- Gold Infotext

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, LUIAddon
local _, LUI = ...
local L = LUI.L

---@type InfotextModule
local module = LUI:GetModule("Infotext")
local element = module:NewElement("Gold", "AceEvent-3.0")

-- local copies
local pairs, ipairs, mod = pairs, ipairs, math.fmod
local format, floor, abs = format, floor, math.abs
local BreakUpLargeNumbers = _G.BreakUpLargeNumbers
local GetMoneyString = _G.GetMoneyString
local GetMoney = _G.GetMoney

-- constants
local COPPER_AMOUNT_SYMBOL = _G.COPPER_AMOUNT_SYMBOL
local SILVER_AMOUNT_SYMBOL = _G.SILVER_AMOUNT_SYMBOL
local GOLD_AMOUNT_SYMBOL = _G.GOLD_AMOUNT_SYMBOL
local COPPER_PER_SILVER = _G.COPPER_PER_SILVER
local SILVER_PER_GOLD = _G.SILVER_PER_GOLD
local COPPER_PER_GOLD = _G.COPPER_PER_GOLD
local MONEY_COLON = _G.MONEY_COLON

local SILVER_COLOR = "|cffc7c7cf"
local COPPER_COLOR = "|cffeda55f"
local GOLD_COLOR = "|cffffd700"

-- Prevent Neutral and any other minor faction Blizzard entering the global db. (ie: Scourge event)
local SUPPORTED_FACTION = {
	Alliance = true,
	Horde = true,
	Neutral = false,
}
local FACTION_ORDER_REALM = {
	LUI.playerFaction,
	LUI.otherFaction,
	"Neutral",
}
local FACTION_ORDER_GLOBAL = {
	LUI.playerFaction,
	LUI.otherFaction,
}

-- locals
local moneyProfit = 0
local moneySpent = 0
local previousMoney = 0
local realmMoney = 0

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

function element:FormatMoney(money, color)
	local db = module.db.profile.Gold
	if db.useBlizzard then
		return GetMoneyString(money)
	end

	money = abs(money)
	local gold = floor(money / (COPPER_PER_GOLD))
	local silver = mod(floor(money / COPPER_PER_SILVER), SILVER_PER_GOLD)
	local copper = mod(money, COPPER_PER_SILVER)
	--BreakUpLargeNumber returns a string, not a number.
	local goldString = format("%s%s%s|r", BreakUpLargeNumbers(gold), (color) and GOLD_COLOR or "", GOLD_AMOUNT_SYMBOL)
	local silverString = format("%d%s%s|r", silver, (color) and SILVER_COLOR or "", SILVER_AMOUNT_SYMBOL)
	local copperString = format("%d%s%s|r", copper, (color) and COPPER_COLOR or "", COPPER_AMOUNT_SYMBOL)

	if gold > 0 and db.showCopper then
		return format("%s %s %s", goldString, silverString, copperString)
	elseif gold > 0 then
		return format("%s %s", goldString, silverString)
	elseif silver > 0 then
		return format("%s %s", silverString, copperString)
	else
		return format("%s", copperString)
	end

end

function element:CacheConnectedRealms()
	local connectedRealms = GetAutoCompleteRealms()
	local goldDB = module.db.global.Gold[LUI.playerFaction]
	local realmDB = module.db.global.ConnectedRealms

	if connectedRealms then
		local realmShown, realmChars
		for i = 1, #connectedRealms do
			local realm = connectedRealms[i]
			-- Copy the list of connected realms and remove itself from the list
			realmDB[realm] = CopyTable(connectedRealms)
			table.remove(realmDB[realm], i)
			if i == 1 then
				realmDB[realm].Show = true
				realmChars = LUI:Count(goldDB[realm])
				realmShown = realm
			elseif i > 1 and LUI:Count(goldDB[realm]) > realmChars then
				realmDB[realmShown].Show = false
				realmDB[realm].Show = true
				realmShown = realm
			else
				realmDB[realm].Show = false
			end
		end
	end
end

function element:UpdateGold()
	local db = module.db.profile.Gold
	local realm = LUI.playerRealm
	local faction = LUI.playerFaction
	local goldDB = module.db.global.Gold[faction]

	local newMoney = GetMoney()

	-- Change will be positive if we gain money
	local change = newMoney - previousMoney

	if previousMoney > newMoney then  -- Lost Money
		moneySpent = moneySpent - change
	else                              -- Gained Money
		moneyProfit = moneyProfit + change
	end

	--Update gold count
	previousMoney = newMoney
	if SUPPORTED_FACTION[faction] then
		goldDB[realm][LUI.playerName] = newMoney
		realmMoney = realmMoney + change
	end

	local money = (db.showRealm and realmMoney) or newMoney
	element.text = element:FormatMoney(money)
	element:UpdateTooltip()
end

function element:UpdateRealmMoney()
	local faction = LUI.playerFaction
	local goldDB = module.db.global.Gold[faction]
	
	--Update for current character
	if SUPPORTED_FACTION[faction] then
		--goldDB[LUI.playerRealm][LUI.playerName] = GetMoney()
		local total = 0
		for player, money in pairs(goldDB[LUI.playerRealm]) do
			total = total + money
		end
		if module.db.profile.Gold.ShowConnected and module.db.global.ConnectedRealms[LUI.playerRealm] then
			for _, connectedRealm in ipairs(module.db.global.ConnectedRealms[LUI.playerRealm]) do
				for player, money in pairs(goldDB[connectedRealm]) do
					total = total + money
				end
			end
		end
		realmMoney = total
	end
end

function element.OnClick(frame_, button)
	if button == "RightButton" then
		moneySpent = 0
		moneyProfit = 0
		element:UpdateTooltip()
	else
		local db = module.db.profile.Gold
		db.showRealm = not db.showRealm
		element:UpdateGold()
	end
end

--- Determine if a realm should be shown in the tooltip
function element:ShouldRealmBeShown(realmName)
	local goldDB = module.db.global.Gold
	local realmDB = module.db.global.ConnectedRealms
	-- All realms are shown when not connecting realms
	if not module.db.profile.Gold.ShowConnected then
		return true
	-- If the realm has gold information but is not connected, it should be shown
	elseif (goldDB.Alliance[realmName] or goldDB.Horde[realmName]) and not realmDB[realmName] then
		return true
	-- Check the connected realms table to know if the realm should be shown
	elseif realmDB[realmName] and realmDB[realmName].Show then
		return true
	else
		return false
	end
end

-- ####################################################################################################################
-- ##### Infotext Display #############################################################################################
-- ####################################################################################################################

function element.OnTooltipShow(GameTooltip)
	element:TooltipHeader(MONEY_COLON)

	GameTooltip:AddLine(L["InfoGold_Session"])
	GameTooltip:AddDoubleLine(L["InfoGold_Earned"], element:FormatMoney(moneyProfit, true), 1,1,1, 1,1,1)
	GameTooltip:AddDoubleLine(L["InfoGold_Spent"], element:FormatMoney(moneySpent, true), 1,1,1, 1,1,1)

	local change = moneyProfit - moneySpent
	if change > 0 then
		local r, g, b = LUI:PositiveColor()
		GameTooltip:AddDoubleLine(L["InfoGold_Profit"], element:FormatMoney(change, true), r, g, b, 1,1,1)
	elseif change < 0 then
		local r, g, b = LUI:NegativeColor()
		GameTooltip:AddDoubleLine(L["InfoGold_Deficit"], element:FormatMoney(change, true), r, g, b, 1,1,1)
	end

	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(L["InfoGold_Characters"] )
	local realmDB = module.db.global.Gold
	for i, faction in ipairs(FACTION_ORDER_GLOBAL) do
		for name, money in pairs(realmDB[faction][LUI.playerRealm]) do
			local r, g, b = LUI:GetFactionColor(faction)
			GameTooltip:AddDoubleLine(name, element:FormatMoney(money, true), r, g, b, 1,1,1)
		end
	end
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(L["InfoGold_Realms"])
	for i, faction in ipairs(FACTION_ORDER_GLOBAL) do
		for realm, realmData in pairs(realmDB[faction]) do
			if type(realmData) ~= "table" then realmDB[faction][realm] = nil
			elseif element:ShouldRealmBeShown(realm) then
				local r, g, b = LUI:GetFactionColor(faction)
				local total = 0
				for player, money in pairs(realmData) do
					total = total + money
				end
				if module.db.profile.Gold.ShowConnected and module.db.global.ConnectedRealms[realm] then
					for _, connectedRealm in ipairs(module.db.global.ConnectedRealms[realm]) do
						for player, money in pairs(realmDB[faction][connectedRealm]) do
							total = total + money
						end
					end
				end
				if total > 0 then
					GameTooltip:AddDoubleLine(format("%s-%s", realm, faction), element:FormatMoney(total, true), r, g, b, 1,1,1)
				end
			end
		end
	end

	element:AddHint(L["InfoGold_Hint_Any"], L["InfoGold_Hint_Right"])
end

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function element:OnCreate()
	previousMoney = GetMoney()

	-- This makes sure that realm tables are always created without a ton of nil checks.
	local autocreateRealm = {
		__index = function(t, k)
			-- Remove spaces found in the name
			local r = string.gsub(k, " ", "")
			-- Check if it already exists
			if rawget(t, r) then return t[r] end

			t[r] = {}
			return t[r]
		end
	}
	setmetatable(module.db.global.Gold.Alliance, autocreateRealm)
	setmetatable(module.db.global.Gold.Horde, autocreateRealm)

	-- Transfer db.realm to db.global
	if module.db.realm.Gold then
		for faction, realmDB in pairs(module.db.realm.Gold) do
			if SUPPORTED_FACTION[faction] then
				module.db.global.Gold[faction][LUI.playerRealm] = {}
				for player, money in pairs(realmDB) do
					module.db.global.Gold[faction][LUI.playerRealm][player] = money
				end
			end
		end
		module.db.realm.Gold = nil
	end
	
	element:CacheConnectedRealms()
	element:RegisterEvent("PLAYER_MONEY", "UpdateGold")
	element:UpdateRealmMoney()
	element:UpdateGold()
end
