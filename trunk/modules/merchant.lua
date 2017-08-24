--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: merchant.lua
	Description: Merchant Module
]]

-- External references.
local addonname, LUI = ...
local module = LUI:Module("Merchant", "AceEvent-3.0")

-- Database and defaults shortcuts.
local db, dbd

------------------------------------------------------
-- / Create Module / --
------------------------------------------------------

-- Localised functions.
local select, strfind, strmatch, tonumber, tostring, type = select, strfind, strmatch, tonumber, tostring, type
local GetItemCount, GetItemInfo, GetMerchantItemInfo, GetMerchantNumItems = GetItemCount, GetItemInfo, GetMerchantItemInfo, GetMerchantNumItems
local CanMerchantRepair, GetCoinTextureString, GetRepairAllCost, RepairAllItems = CanMerchantRepair, GetCoinTextureString, GetRepairAllCost, RepairAllItems
local GetContainerItemID, GetContainerItemInfo, GetContainerNumSlots, UseContainerItem =  GetContainerItemID, GetContainerItemInfo, GetContainerNumSlots, UseContainerItem

function module:ItemExclusion(info, item) -- info = true: remove item from list
	if type(info) == "table" and not GetItemInfo(item) then
		if CursorHasItem() then
			item = select(2, GetCursorInfo())
			ClearCursor()
		elseif strfind(item, "Button") then
			return OpenAllBags(true)
		end
	end

	local _, itemLink, _,_,_,_,_,_,_,_, itemPrice = GetItemInfo(item)

	-- Check item.
	if not itemLink then
		print(item .. " |cffff0000is not a valid item.")
		return
	end

	local itemID = tonumber(string.match(itemLink, "item:(%d+)"))

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
		elseif itemPrice <= 0 then
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
	local nItem = tonumber(item)
	if nItem and GetItemInfo(nItem) then
		return nItem
	end

	-- Get itemLink.
	local _, itemLink = GetItemInfo(item)
	if not itemLink then return end

	-- Extract id from itemLink.
	return tonumber(strmatch(itemLink, "|Hitem:(%d+):"))
end

function module:AutoRepair()
	if not db.AutoRepair.Enable then return end

	-- Check if merchant can repair.
	if not CanMerchantRepair() then return end

	local repairAllCost, canRepair = GetRepairAllCost()

	-- Check if player has any damaged gear and enough money to repair.
	if not canRepair then return end

	-- Check cost limit.
	if (not db.AutoRepair.Settings.NoLimit) and (repairAllCost > (db.AutoRepair.Settings.CostLimit * 1000)) then
		if db.AutoRepair.Settings.ShowError then
			print("|cffff0000The repair costs of|r " .. GetCoinTextureString(repairAllCost) .. " |cffff0000exceed the limit of|r " .. GetCoinTextureString(db.AutoRepair.Settings.CostLimit))
		end
		return
	end

	-- Try guild repair.
	if db.AutoRepair.Settings.UseGuild then
		RepairAllItems(1)

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

function module:AutoSell()
	if not db.AutoSell.Enable then return end

	local totalPrice = 0
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			local item = GetContainerItemID(bag, slot)

			if item then
				local _, itemLink, itemQuality, _,_,_,_,_,_,_, itemPrice = GetItemInfo(item)

				if itemQuality and (db.AutoSell.ItemQualities[itemQuality + 1] == not db.AutoSell.Exclusions[item]) then -- don't use ~= (itemQuality can be true or false, exclusion can be true or nil (false ~= nil will return true and sell the item))
					local _, itemCount  = GetContainerItemInfo(bag, slot)
					totalPrice = totalPrice + (itemCount * itemPrice)

					-- Sell item.
					UseContainerItem(bag, slot)
				end
			end
		end
	end

	-- Print profits.
	if db.AutoSell.Settings.ShowSuccess and (totalPrice > 0) then
		print("|cff00ff00Successfully sold specified items for:|r "..GetCoinTextureString(totalPrice))
	end
end

function module:AutoStock()
	if not db.AutoStock.Enable or db.AutoStock.Count <= 0 then return end

	-- Scan through merchants items.
	local cost, cart = 0, {}
	for i = 1, GetMerchantNumItems() do
		-- Get item info.
		local name, _, price, quantity, numAvailable = GetMerchantItemInfo(i)
		local id = self:GetItemID(GetMerchantItemLink(i))

		-- Check item is in list.
		local count = 0
		if id and db.AutoStock.List[id] then
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

	-- Check if shopping cart is affordable.
	if (not db.AutoStock.Settings.NoLimit) and (cost > db.AutoStock.Settings.CostLimit * 1000) then
		if db.AutoStock.Settings.ShowError then
			print("|cffff0000Stocking items would cost|r " .. GetCoinTextureString(cost) .. " |cffff0000and exceed the limit of|r " .. GetCoinTextureString(db.AutoStock.Settings.CostLimit * 1000))
		end
		return
	end

	-- Buy shopping cart.
	for item, qty in pairs(cart) do
		-- But item.
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
	self:AutoSell()
	self:AutoRepair()
	self:AutoStock()
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
			Count = 0,
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

module.defaultState = false
module.getter = "generic"
module.setter = "generic"

function module:LoadOptions()
	-- option variables
	local removeExclusionKey
	local exclusionList = {}

	-- disabled funcs
	local disabled = {
		AutoStock = function() return not db.AutoStock.Enable end,
		AutoRepair = function() return not db.AutoRepair.Enable end,
		AutoSell = function() return not db.AutoSell.Enable end,
		BuyLimit = function() return ((not db.AutoStock.Enable) or db.AutoStock.Settings.NoLimit) end,
		CostLimit = function() return ((not db.AutoRepair.Enable) or db.AutoRepair.Settings.NoLimit) end,
		NoExclusionSelected = function() return not removeExclusionKey end,
		NoExclusions = function() return not next(exclusionList) end,
	}

	-- option values
	local qualities = {}
	for i=0, 4 do
		qualities[i + 1] =  ITEM_QUALITY_COLORS[i]["hex"] .. _G["ITEM_QUALITY" .. i .. "_DESC"] .. "|r"
	end
	local function exclusions()
		wipe(exclusionList)
		for itemID in pairs(db.AutoSell.Exclusions) do
			local _, itemLink = GetItemInfo(itemID)
			exclusionList[itemID] = itemLink
		end
		return exclusionList
	end

	-- Auto Stock functions.
	local stockCurrent, stockList = nil, {}
	local function stockValues()
		wipe(stockList)
		--noinspection ArrayElementZero
		stockList[0] = "None"
		for id, count in pairs(db.AutoStock.List) do
			stockList[id] = GetItemInfo(id)
		end

		return stockList
	end
	local function stockGet()
		stockCurrent = (stockCurrent ~= 0 and stockCurrent) or nil
		return stockCurrent and stockList[stockCurrent] and stockCurrent or 0
	end
	local function stockSet(self, id)
		stockCurrent = (id ~= 0 and id) or nil
	end
	local function stockUpdateGet()
		return (stockCurrent and tostring(db.AutoStock.List[stockCurrent])) or "Enter a new item name, link or id (\"id:1234\")."
	end
	local function stockUpdateSet(self, v)
		if not v or v == "" then return end

		local count = tonumber(v)
		if count then
			-- Update an item in list.
			if stockCurrent and db.AutoStock.List[stockCurrent] then
				if count == 0 then
					-- Remove item id from list.
					db.AutoStock.List[stockCurrent] = nil
					db.AutoStock.Count = db.AutoStock.Count - 1
					db.AutoStock.Count = db.AutoStock.Count >= 0 and db.AutoStock.Count or 0
					stockCurrent = nil
				else
					-- Update stock count.
					db.AutoStock.List[stockCurrent] = count
				end
			end
		else
			-- Add new item.
			local id = module:GetItemID(v)
			if not id then
				id = module:GetItemID(v:match("id:(%d+)"))
				if not id then
					stockCurrent = nil
					return
				end
			end

			-- Add item id to list.
			if not db.AutoStock.List[id] then
				db.AutoStock.List[id] = 1
				db.AutoStock.Count = db.AutoStock.Count + 1
			end
			stockCurrent = id
		end
	end

	-- get/set functions
	local function exclusionGet(info) return removeExclusionKey end
	local function exclusionSet(info, value) removeExclusionKey = value end
	local function removeExclusion(info)
		if removeExclusionKey then
			self:ItemExclusion(true, removeExclusionKey)
			removeExclusionKey = nil
		end
	end

	local options = {
		Title = self:NewHeader("Merchant", 1),
		Info = self:NewDesc("This Merchant allows you to automatically sell/buy items and/or repair your armor when you open a merchant frame.", 2),
		AutoRepair = self:NewGroup("Auto Repair", 3, {
			Title = self:NewHeader("Auto Repair Settings", 1),
			Info = self:NewDesc("Set your Auto Repair options. If a guild repair fails it will not prevent a normal repair. Additionally you may also set a cost limit.", 2),
			Enable = self:NewToggle("Enable Auto Repair", nil, 3, true),
			Settings = self:NewGroup("Settings", 4, true, disabled.AutoRepair, {
				UseGuild = self:NewToggle("Use Guild Repair", nil, 1, true),
				NoLimit = self:NewToggle("No Cost Limit", nil, 2, true),
				CostLimit = self:NewSlider("Cost Limit", "The cost limit in gold after which the repair won't happen automatically.", 3, 0, 500, 10, true, false, nil, disabled.CostLimit),
				ShowError = self:NewToggle("Show Limit Error", nil, 4, true),
				ShowSuccess = self:NewToggle("Show Success Messages", nil, 5, true),
			}),
		}),
		AutoSell = self:NewGroup("Auto Sell", 3, {
			Title = self:NewHeader("Auto Sell Settings", 1),
			Info = self:NewDesc("Set your Auto Sell options.", 2),
			Enable = self:NewToggle("Enable Auto Sell", nil, 3, true),
			Settings = self:NewGroup("Settings", 4, true, disabled.AutoSell, {
				ShowSuccess = self:NewToggle("Show Success Messages", nil, 1, true),
				ShowExclusion = self:NewToggle("Show Exclusion Messages", nil, 2, true),
			}),
			Warning = self:NewDesc("|cffff9933Warning:|r You really shouldn't enable other item qualities unless you are very sure that you won't sell anything of value.", 5),
			ItemQualities = self:NewMultiSelect("Item Qualities", "Changes the item quality from which everything automatically will be sold when opening a merchant frame.",
				6, qualities, nil, nil, disabled.AutoSell),
			AddExclusion = self:NewGroup("Add Item Exclusion", 7, LUI.dummy, "ItemExclusion", true, disabled.AutoSell, {
				Description = self:NewDesc("Items in this list will behave opposite of the settings.\nTo add an item to the Exclusion list do one of the following:\n" ..
						"Drag and drop (leftclick) an item into the box.\nEnter an item id, name or link in the input box.\n\t	You can provide a link by Shift + Leftclicking on an item or link.", 1),
				DropItem = self:NewExecute("Drop an item here!", "Select an item and drop it on this slot. (Leftclick)", 2, "ItemExclusion"),
				InputItem = self:NewInput("Or enter an id, name or link", "Enter an item id, name or link (Shift + Leftclick an item)", 3, false)
			}),
			RemoveExclusion = self:NewGroup("Remove Item Exclusion", 8, exclusionGet, exclusionSet, true, disabled.AutoSell, {
				Select = self:NewSelect("Select Item", "Select the item which you want to remove from the exclusion list.", 1, exclusions, nil, false, "double"),
				Remove = self:NewExecute("Remove selected item", "Removes the selected item from the exclusion list.", 2, removeExclusion, nil, nil, disabled.NoExclusionSelected),
				Clear = self:NewExecute("Clear excluded items", "Removes the selected item from the exclusion list.", 3, "ClearExclusions", "Do you really want to clear all excluded items?", nil, disabled.NoExclusions),
			}),
		}),
		AutoStock = self:NewGroup("Auto Stock", 4, {
			Title = self:NewHeader("Auto Stock Settings", 1),
			Info = self:NewDesc("Set your Auto Stock options. Additionally you may also set a cost limit.", 2),
			Enable = self:NewToggle("Enable Auto Stock", nil, 3, true),
			Items = {
				type = "select", name = "Stock List", order = 4,
				desc = "List of all items that will automatically be restocked.",
				values = stockValues,
				get = stockGet,
				set = stockSet,
				disabled = disabled.AutoStock,
			},
			Update = {
				type = "input", name = "Count & New Item", order = 5,
				desc = "Type in the amount to buy of the selected item, or type in a new item name, link or id to add a new item to the list. If entering an item id please enter like so: \"id:1234\".",
				get = stockUpdateGet,
				set = stockUpdateSet,
				disabled = disabled.AutoStock,
			},
			Settings = self:NewGroup("Settings", 5, true, disabled.AutoStock, {
				NoLimit = self:NewToggle("No Cost Limit", nil, 1, true),
				CostLimit = self:NewSlider("Cost Limit", "The cost limit in gold after which buying items won't happen automatically.", 2, 0, 500, 10, true, false, nil, disabled.BuyLimit),
				ShowError = self:NewToggle("Show Limit Error", nil, 3, true),
				ShowSuccess = self:NewToggle("Show Success Messages", nil, 4, true),
			}),
		}),
	}

	local dropitem = options.AutoSell.args.AddExclusion.args.DropItem
	dropitem.imageWidth = 64
	dropitem.imageHeight = 64
	dropitem.imageCoords = {0.15, 0.8, 0.15, 0.8}
	dropitem.image = "Interface\\Buttons\\UI-Quickslot2"


	return options
end

function module:OnInitialize()
	db, dbd = LUI:Namespace(self, true)
end

module.DBCallback = module.OnInitialize

function module:OnEnable()
	self:RegisterEvent("MERCHANT_SHOW")
end
