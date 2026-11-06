--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: merchant.lua
	Description: Automatic merchant selling, repair and restocking
]]

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Merchant : LUIModule
local module = LUI:NewModule("Merchant", "LUIDevAPI")

-- Database and defaults shortcuts.
local db

------------------------------------------------------
-- / Create Module / --
------------------------------------------------------

-- Localised functions.
local GetCoinTextureString = C_CurrencyInfo.GetCoinTextureString
local GetMerchantItemLink = _G.GetMerchantItemLink
local GetMerchantNumItems = _G.GetMerchantNumItems
local CanMerchantRepair = _G.CanMerchantRepair
local GetRepairAllCost = _G.GetRepairAllCost
local BuyMerchantItem = _G.BuyMerchantItem
local RepairAllItems = _G.RepairAllItems
local GetCursorInfo = _G.GetCursorInfo
local CursorHasItem = _G.CursorHasItem
local GetItemCount = C_Item.GetItemCount
local GetItemInfo = C_Item.GetItemInfo
local GetItemInfoInstant = C_Item.GetItemInfoInstant
local GetMoney = _G.GetMoney
local ClearCursor = _G.ClearCursor
local Item = _G.Item
local COPPER_PER_GOLD = _G.COPPER_PER_GOLD
local tostring = tostring
local tonumber = tonumber
local select = select

function module:ItemExclusion(info, item, loadAttempted) -- info = true: remove item from list
	if type(info) == "table" and not item then
		if CursorHasItem() then
			item = select(2, GetCursorInfo())
			ClearCursor()
		else
			return
		end
	end
	if not item or item == "" then return end

	local itemID = self:GetItemID(item)
	if not itemID then
		print(tostring(item) .. " |cffff0000is not a valid item.")
		return
	end

	local _, itemLink, _,_,_,_,_,_,_,_, itemPrice = GetItemInfo(itemID)

	if not itemLink then
		if not loadAttempted and Item then
			local remove = info == true
			Item:CreateFromItemID(itemID):ContinueOnItemLoad(function()
				module:ItemExclusion(remove, itemID, true)
			end)
			return
		end
		print(tostring(itemID) .. " |cffff0000could not be loaded as an item.")
		return
	end

	if info == true then -- remove
		db.AutoSell.Exclusions[itemID] = nil

		if db.AutoSell.Settings.ShowExclusion then
			print("|cff00ff00Successfully removed|r "..itemLink.." |cff00ff00from the exclusion list.")
		end
	else
		if db.AutoSell.Exclusions[itemID] then
			if db.AutoSell.Settings.ShowExclusion then
				print(itemLink.." |cffff0000 is already in the exclusion list.")
			end
		elseif not itemPrice or itemPrice <= 0 then
			print(itemLink.." |cffff0000 has no sell price and can't be excluded.")
		else
			db.AutoSell.Exclusions[itemID] = true

			if db.AutoSell.Settings.ShowExclusion then
				print("|cff00ff00Successfully added|r "..itemLink.." |cff00ff00to the exclusion list.")
			end
		end
	end
end

function module:ClearExclusions()
	wipe(db.AutoSell.Exclusions)

	if db.AutoSell.Settings.ShowExclusion then
		print("|cff00ff00Successfully cleared the exclusion list.")
	end
end

function module:GetItemID(item)
	if not item then return end
	if type(item) == "string" then
		local explicitID = item:match("^id:(%d+)$")
		if explicitID then return tonumber(explicitID) end
	end
	local itemQuery = tonumber(item) or item
	local itemID = GetItemInfoInstant(itemQuery)
	if itemID then return itemID end

	-- Get itemLink.
	local _, itemLink = GetItemInfo(itemQuery)
	if not itemLink then return end

	-- Extract id from itemLink.
	return tonumber(string.match(itemLink, "|Hitem:(%d+):"))
end

function module:AutoRepair()
	if not db.AutoRepair.Enable then return end

	-- Check if merchant can repair.
	if not CanMerchantRepair() then return end

	local repairAllCost, canRepair = GetRepairAllCost()

	-- Check if player has any damaged gear and enough money to repair.
	if not canRepair then return end

	-- Check cost limit.
	if (not db.AutoRepair.Settings.NoLimit) and (repairAllCost > (db.AutoRepair.Settings.CostLimit * COPPER_PER_GOLD)) then
		if db.AutoRepair.Settings.ShowError then
			print("|cffff0000The repair costs of|r " .. GetCoinTextureString(repairAllCost) .. " |cffff0000exceed the limit of|r " .. GetCoinTextureString(db.AutoRepair.Settings.CostLimit * COPPER_PER_GOLD))
		end
		return
	end

	-- Try guild repair.
	if db.AutoRepair.Settings.UseGuild then
		RepairAllItems(true)

		-- Check if guild repair worked.
		local remaining, needed = GetRepairAllCost()

		if remaining < repairAllCost then
			if db.AutoRepair.Settings.ShowSuccess then
				print("|cff00ff00Successfully guild repaired armor for:|r "..GetCoinTextureString(repairAllCost - remaining))
			end
			repairAllCost = remaining
		end

		-- Check if additional repairing is needed.
		if not needed then return end
	end

	-- Repair remaining.
	RepairAllItems()

	if db.AutoRepair.Settings.ShowSuccess then
		print("|cff00ff00Successfully repaired armor for:|r "..GetCoinTextureString(repairAllCost))
	end
end

local SELL_INTERVAL, SELL_TIMEOUT = .2, 5
local sellSession
local merchantOpen = false
local merchantBlocked = false

local function CancelAutoSell()
	if sellSession and sellSession.timer then sellSession.timer:Cancel() end
	sellSession = nil
end

local function GetAutoSellInfo(bag, slot)
	local info = C_Container.GetContainerItemInfo(bag, slot)
	if info and info.itemID and not info.isLocked and not info.hasNoValue
		and info.quality and db.AutoSell.ItemQualities[info.quality + 1]
		and not db.AutoSell.Exclusions[info.itemID] then
		local price = select(11, GetItemInfo(info.hyperlink))
		if price and price > 0 then return info, price end
	end
end

local function GetSlotGUID(bag, slot)
	return C_Item.GetItemGUID(ItemLocation:CreateFromBagAndSlot(bag, slot))
end

local function FinishAutoSell()
	local totalPrice = sellSession.totalPrice
	CancelAutoSell()
	if db.AutoSell.Settings.ShowSuccess and totalPrice > 0 then
		print("|cff00ff00Successfully sold specified items for:|r "..GetCoinTextureString(totalPrice))
	end
	if not merchantBlocked then module:AutoStock() end
end

local ProcessAutoSell
local function ScheduleAutoSell(session)
	session.timer = C_Timer.NewTimer(SELL_INTERVAL, function()
		-- A close, profile switch or disable may already have replaced this visit.
		if sellSession ~= session then return end
		session.timer = nil
		ProcessAutoSell(session)
	end)
end

ProcessAutoSell = function(session)
	if not merchantOpen or not module:IsEnabled() or not _G.MerchantFrame or not _G.MerchantFrame:IsShown() then
		CancelAutoSell()
		return
	end
	if not db.AutoSell.Enable then
		FinishAutoSell()
		return
	end

	local pending = session.pending
	if pending then
		local info = C_Container.GetContainerItemInfo(pending.bag, pending.slot)
		local sameItem = info and GetSlotGUID(pending.bag, pending.slot) == pending.guid
		-- Wait for the sold stack to leave the bag. A move to another slot is
		-- not a sale, so also require the carried item count to decrease.
		if not sameItem and GetItemCount(pending.itemID) <= pending.carriedCount - pending.count then
			session.totalPrice = session.totalPrice + pending.price
			session.pending = nil
		elseif GetTime() >= pending.deadline then
			-- Never retry an unanswered sale or send more transactions after it.
			merchantBlocked = true
			FinishAutoSell()
			return
		else
			ScheduleAutoSell(session)
			return
		end
	end

	while session.index <= #session.queue do
		local entry = session.queue[session.index]
		session.index = session.index + 1
		local info, price = GetAutoSellInfo(entry.bag, entry.slot)
		-- Do not sell a replacement item after sorting or moving bag contents.
		if info and info.itemID == entry.itemID and GetSlotGUID(entry.bag, entry.slot) == entry.guid then
			session.pending = {
				bag = entry.bag, slot = entry.slot, guid = entry.guid, itemID = entry.itemID,
				count = info.stackCount, price = info.stackCount * price,
				carriedCount = GetItemCount(info.itemID), deadline = GetTime() + SELL_TIMEOUT,
			}
			C_Container.UseContainerItem(entry.bag, entry.slot)
			if sellSession == session then ScheduleAutoSell(session) end
			return
		end
	end
	FinishAutoSell()
end

function module:AutoSell()
	if not db.AutoSell.Enable or not merchantOpen or merchantBlocked or sellSession then return end

	local queue = {}
	local lastBag = Enum.BagIndex.ReagentBag or _G.NUM_BAG_SLOTS
	for bag = 0, lastBag do
		for slot = 1, C_Container.GetContainerNumSlots(bag) do
			local info = GetAutoSellInfo(bag, slot)
			if info then
				queue[#queue + 1] = {bag = bag, slot = slot, itemID = info.itemID, guid = GetSlotGUID(bag, slot)}
			end
		end
	end
	if #queue == 0 then return end

	-- Pace requests and wait for each inventory response before the next sale.
	sellSession = {queue = queue, index = 1, totalPrice = 0}
	ScheduleAutoSell(sellSession)
end

function module:AutoStock()
	if not db.AutoStock.Enable or not next(db.AutoStock.List) then return end

	-- Scan through merchants items.
	local cost, cart = 0, {}
	for i = 1, GetMerchantNumItems() do
		local merchantInfo = C_MerchantFrame.GetItemInfo(i)
		local id = self:GetItemID(GetMerchantItemLink(i))

		-- Check item is in list.
		local count = 0
		if merchantInfo and merchantInfo.isPurchasable and not merchantInfo.hasExtendedCost and merchantInfo.stackCount > 0 and id and db.AutoStock.List[id] then
			local name = merchantInfo.name or tostring(id)
			local price = merchantInfo.price
			local quantity = merchantInfo.stackCount
			local numAvailable = merchantInfo.numAvailable
			-- Add to shopping cart.
			count = db.AutoStock.List[id] - GetItemCount(id)
			if numAvailable ~= -1 and numAvailable < count then
				if db.AutoStock.Settings.ShowError then
					print("|cffff0000Only " .. numAvailable .. " " .. name .. (numAvailable == 1 and " was" or "s were") .. " available for purchase.|r")
				end
				count = numAvailable
			end
			if count > 0 then
				cart[i] = count
				cost = cost + (price / quantity * count)
			end
		end
	end

	-- Check if shopping cart is empty.
	if cost <= 0 then return end
	if cost > GetMoney() then
		if db.AutoStock.Settings.ShowError then
			print("|cffff0000Stocking items would cost|r " .. GetCoinTextureString(cost) .. " |cffff0000but you do not have enough money.|r")
		end
		return
	end

	-- Check if shopping cart is affordable.
	if (not db.AutoStock.Settings.NoLimit) and (cost > db.AutoStock.Settings.CostLimit * COPPER_PER_GOLD) then
		if db.AutoStock.Settings.ShowError then
			print("|cffff0000Stocking items would cost|r " .. GetCoinTextureString(cost) .. " |cffff0000and exceed the limit of|r " .. GetCoinTextureString(db.AutoStock.Settings.CostLimit * COPPER_PER_GOLD))
		end
		return
	end

	-- Buy shopping cart.
	for item, qty in pairs(cart) do
		BuyMerchantItem(item, qty)
	end

	if db.AutoStock.Settings.ShowSuccess then
		print("|cff00ff00Successfully stocked items for:|r "..GetCoinTextureString(cost))
	end
end

------------------------------------------------------
-- / Event Functions / --
------------------------------------------------------

function module:MERCHANT_SHOW()
	if merchantOpen then return end
	merchantOpen = true
	merchantBlocked = false
	self:AutoSell()
	self:AutoRepair()
	if not sellSession then self:AutoStock() end
end

function module:MERCHANT_CLOSED()
	merchantOpen = false
	merchantBlocked = false
	CancelAutoSell()
end

function module:MERCHANT_UPDATE()
	-- Merchant links and item data can arrive after MERCHANT_SHOW. Purchases
	-- must wait for selling to finish so restocking cannot mask a sold stack.
	if merchantOpen and not sellSession and not merchantBlocked then self:AutoStock() end
end

------------------------------------------------------
-- / Module Settings / --
------------------------------------------------------

module.defaults = {
	profile = {
		AutoRepair = {
			Enable = true,
			Settings = {
				UseGuild = false,
				NoLimit = true,
				CostLimit = 500,
				ShowError = true,
				ShowSuccess = true,
			},
		},
		AutoSell = {
			Enable = false,
			Settings = {
				ShowSuccess = true,
				ShowExclusion = true,
			},
			Exclusions = {},
			ItemQualities = {
				true, -- Poor
				false, -- Common
				false, -- Uncommon
				false, -- Rare
				false, -- Epic
			},
		},
		AutoStock = {
			Enable = false,
			List = {
			},
			Settings = {
				NoLimit = true,
				CostLimit = 250,
				ShowError = true,
				ShowSuccess = true,
			},
		},
	},
}

module.enableButton = true
module.defaultState = false

function module:OnInitialize()
	CancelAutoSell()
	db = LUI:Namespace(self, true)
end

module.DBCallback = module.OnInitialize

function module:OnEnable()
	self:RegisterEvent("MERCHANT_SHOW")
	self:RegisterEvent("MERCHANT_CLOSED")
	self:RegisterEvent("MERCHANT_UPDATE")
end

function module:OnDisable()
	self:MERCHANT_CLOSED()
	self:UnregisterAllEvents()
end
