--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: merchant.lua
	Description: Merchant Module
	Version....: 1.3
	Rev Date...: 01/07/2011 [dd/mm/yyyy]
	Author...: Xolsom

	Edits:
		v1.3: Hix
]]

-- External references.
local addonname, LUI = ...
local module = LUI:Module("Merchant", "AceEvent-3.0")

-- Database and defaults shortcuts.
local db, dbd

------------------------------------------------------
-- / Create Module / --
------------------------------------------------------

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
	db.AutoSell.Exclusions = {}

	if db.AutoSell.Settings.ShowExclusion then
		print("|cff00ff00Successfully cleared the exclusion list.")
	end
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

				if (db.AutoSell.ItemQualities[itemQuality + 1] and not db.AutoSell.Exclusions[item])
				or ((not db.AutoSell.ItemQualities[itemQuality + 1]) and db.AutoSell.Exclusions[item]) then
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

------------------------------------------------------
-- / Event Functions / --
------------------------------------------------------

function module:MERCHANT_SHOW()
	self:AutoSell()
	self:AutoRepair()
end

------------------------------------------------------
-- / Module Settings / --
------------------------------------------------------

module.defaults = {
	profile = {
		Enable = false,
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
	},
}

module.getter = "generic"
module.setter = "generic"

function module:LoadOptions()
	-- disabled funcs
	local disabled = {
		AutoRepair = function() return not db.AutoRepair.Enable end,
		AutoSell = function() return not db.AutoSell.Enable end,
		CostLimit = function() return ((not db.AutoRepair.Enable) or db.AutoRepair.Settings.NoLimit) end,
	}
	
	-- option variables
	local removeExclusionKey
	
	-- option values
	local qualities = {}
	for i=0, 4 do
		qualities[i + 1] =  ITEM_QUALITY_COLORS[i]["hex"] .. _G["ITEM_QUALITY" .. i .. "_DESC"] .. "|r"
	end
	local function exclusions()
		local items = {}
		for itemID in pairs(db.AutoSell.Exclusions) do
			local _, itemLink = GetItemInfo(itemID)
			items[itemID] = itemLink
		end
		return items
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
		Info = self:NewDesc("This Merchant allows you to automatically sell items and/or repair your armor when you open a merchant frame.", 2),
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
		AutoSell = self:NewGroup("Auto Sell", 2, {
			Title = self:NewHeader("Auto Sell Settings", 1),
			Info = self:NewDesc("Set your Auto Sell options.", 2),
			Enable = self:NewToggle("Enable Auto Sell", nil, 3, true),
			Settings = self:NewGroup("Settings", 4, true, disabled.AutoSell, {
				ShowSuccess = self:NewToggle("Show Success Messages", nil, 1, true),
				ShowExclusion = self:NewToggle("Show Exclusion Messages", nil, 2, true),
			}),
			Warning = self:NewDesc("|cffff9933Warning:|r You really shouldn't enable other item qualities unless you are very sure that you won't sell anything of worth.", 5),
			ItemQualities = self:NewMultiSelect("Item Qualities", "Changes the item quality from which everything automatically will be sold when opening a merchant frame.",
				6, qualities, nil, nil, disabled.AutoSell),
			AddExclusion = self:NewGroup("Add Item Exclusion", 7, LUI.dummy, "ItemExclusion", true, disabled.AutoSell, {
				Description = self:NewDesc("Items in this list will behave oposite of the settings.\nTo add an item to the Exclusion list do one of the following:\n" ..
					"Drag and drop (leftclick) an item into the box.\nEnter an item id, name or link in the input box.\n\t	You can provide a link by Shift + Leftclicking on an item or link.", 1),
				DropItem = self:NewExecute("Drop an item here!", "Select an item and drop it on this slot. (Leftclick)", 2, "ItemExclusion"),
				InputItem = self:NewInput("Or enter an id, name or link", "Enter an item id, name or link (Shift + Leftclick an item)", 3, false)
			}),
			RemoveExclusion = self:NewGroup("Remove Item Exclusion", 8, exclusionGet, exclusionSet, true, disabled.AutoSell, {
				Select = self:NewSelect("Select Item", "Select the item which you want to remove from the exclusion list.", 1, exclusions, nil, false, "double"),
				Remove = self:NewExecute("Remove selected item", "Removes the selected item from the exclusion list.", 2, removeExclusion),
				Clear = self:NewExecute("Clear excluded items", "Removes the selected item from the exclusion list.", 3, "ClearExclusions", "Do you really want to clear all excluded items?"),
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
	db, dbd = LUI:NewNamespace(self, true)
end

function module:OnEnable()
	self:RegisterEvent("MERCHANT_SHOW")
end

function module:OnDisable()
	self:UnregisterAllEvents()
end