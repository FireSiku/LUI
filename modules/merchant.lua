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
local _, LUI = ...
local Merchant = LUI:NewModule("Merchant")

-- Database and defaults shortcuts.
local db
local dbd

------------------------------------------------------
-- / Create Module / --
------------------------------------------------------

function Merchant:Create(disable)
	if (not db.Merchant.Enable) or disable then
		if self.Merchant then self.Merchant:UnregisterAllEvents() end
		return
	end

	-- Create frame and local shortcut.
	self.Merchant = CreateFrame("Frame")
	local M = self.Merchant

	function M:OnEvent()
		-- Call sell and repair functions.
		self:AutoSell()
		self:AutoRepair()
	end

	function M:AutoRepair()
		if not db.Merchant.AutoRepair.Enable then return end

		-- Check if merchant can repair.
		if not CanMerchantRepair() then return end

		local cost, can = GetRepairAllCost()

		-- Check if player has enough money to repair.
		if not can then return end

		-- Check cost limit.
		if (not db.Merchant.AutoRepair.NoLimit) and (cost > (db.Merchant.AutoRepair.CostLimit * 1000)) then
			if db.Merchant.AutoRepair.ShowError then
				print("|cffff0000The repair costs of|r " .. GetCoinTextureString(cost) .. " |cffff0000exceed the limit of|r " .. GetCoinTextureString(db.Merchant.AutoRepair.CostLimit))
			end
			return
		end

		-- Try guild repair.
		if db.Merchant.AutoRepair.UseGuild then RepairAllItems(1) end

		-- Check if guild repair worked.
		local remaining, needed = GetRepairAllCost()

		if (remaining < cost) and db.Merchant.AutoRepair.ShowSuccess then
			print("|cff00ff00Successfully guild repaired armor for:|r "..GetCoinTextureString(cost - remaining))
		end

		-- Check if additional repairing is needed.
		if not needed then return end

		-- Repair remaining.
		RepairAllItems()

		if db.Merchant.AutoRepair.ShowSuccess then
			print("|cff00ff00Successfully repaired armor for:|r "..GetCoinTextureString(remaining))
		end
	end

	function M:AutoSell()
		if not db.Merchant.AutoSell.Enable then return end

		local totalPrice = 0
		for bag = 0, NUM_BAG_SLOTS do
			for slot = 1, GetContainerNumSlots(bag) do
				local item = GetContainerItemID(bag, slot)

				if item then
					local _, itemLink, itemQuality, _,_,_,_,_,_,_, itemPrice = GetItemInfo(item)

					if ((db.Merchant.AutoSell.ItemQualities[itemQuality + 1]) and (not db.Merchant.AutoSell.Exclusions[item]))
					or ((not db.Merchant.AutoSell.ItemQualities[itemQuality + 1]) and (db.Merchant.AutoSell.Exclusions[item])) then
						local _, itemCount  = GetContainerItemInfo(bag, slot)
						totalPrice = totalPrice + (itemCount * itemPrice)

						-- Sell item.
						UseContainerItem(bag, slot)
					end
				end
			end
		end

		-- Print profits.
		if (totalPrice > 0) and db.Merchant.AutoSell.ShowSuccess then
			print("|cff00ff00Successfully sold specified items for:|r "..GetCoinTextureString(totalPrice))
		end
	end


	M:RegisterEvent("MERCHANT_SHOW")
	M:SetScript("OnEvent", M.OnEvent)
end

function Merchant:ItemExclusion(item, remove)
	local _, itemLink, _,_,_,_,_,_,_,_, itemPrice = GetItemInfo(item)

	-- Check item.
	if not itemLink then
		if db.Merchant.AutoSell.ShowExclusion then
			print(item .. " |cffff0000is not a valid item.")
		end

		return
	end

	local itemID = tonumber(string.match(itemLink, "item:(%d+)"))

	if remove then
		db.Merchant.AutoSell.Exclusions[itemID] = nil

		if db.Merchant.AutoSell.ShowExclusion then
			print("|cff00ff00Successfully removed|r "..itemLink.." |cff00ff00from the exclusion list.")
		end
	else
		if db.Merchant.AutoSell.Exclusions[itemID] then
			if db.Merchant.AutoSell.ShowExclusion then
				print(itemLink.." |cffff0000 is already in the exclusion list.")
			end
		elseif itemPrice <= 0 then
			print(itemLink.." |cffff0000 has no sell price and can't be excluded.")
		else
			db.Merchant.AutoSell.Exclusions[itemID] = true

			if db.Merchant.AutoSell.ShowExclusion then
				print("|cff00ff00Successfully added|r "..itemLink.." |cff00ff00to the exclusion list.")
			end
		end
	end
end

function Merchant:ClearExclusions()
	db.Merchant.AutoSell.Exclusions = {}

	if db.Merchant.AutoSell.ShowExclusion then
		print("|cff00ff00Successfully cleared the exclusion list.")
	end
end

------------------------------------------------------
-- / Module Settings / --
------------------------------------------------------

local defaults = {
	Merchant = {
		Enable = false,
		AutoRepair = {
			Enable = false,
			CostLimit = 500,
			NoLimit = true,
			ShowError = true,
			ShowSuccess = true,
			UseGuild = false,
		},
		AutoSell = {
			Enable = false,
			Exclusions = {},
			ItemQualities = {
				true, -- Poor
				false, -- Common
				false, -- Uncommon
				false, -- Rare
				false, -- Epic
			},
			ShowExclusion = true,
			ShowSuccess = true,
		},
	},
}

function Merchant:LoadOptions()
	-- Item qualaties.
	local function qualities()
		local t = {}
		for i = 0, 4 do
			t[i + 1] =  ITEM_QUALITY_COLORS[i]["hex"] .. getglobal("ITEM_QUALITY" .. i .. "_DESC")
		end

		return t
	end

	-- Option variables.
	local removeExclusionKey

	local options = {
		Merchant = {
			type = "group",
			name = "Merchant",
			disabled = function() return not db.Merchant.Enable end,
			childGroups = "tab",
			args = {
				General = {
					name = "General",
					type = "group",
					order = 1,
					args = {
						Title = LUI:NewHeader("Merchant", 1),
						Info = LUI:NewDesc("This Merchant allows you to automatically sell items and / or repair your armor when you open a merchant frame.", 2),
						Settings = {
							name = "Settings",
							type = "group",
							order = 3,
							guiInline = true,
							args = {
								AutoRepair = LUI:NewToggle("Enable Auto Repair", nil, 1, db.Merchant.AutoRepair, "Enable", dbd.Merchant.AutoRepair),
								AutoSell = LUI:NewToggle("Enable Auto Sell", nil, 2, db.Merchant.AutoSell, "Enable", dbd.Merchant.AutoSell),
							},
						},
					},
				},
				AutoRepair = {
					name = "Auto Repair",
					type = "group",
					order = 2,
					disabled = function() return not db.Merchant.AutoRepair.Enable end,
					args = {
						Title = LUI:NewHeader("Auto Repair Settings", 1),
						Info = LUI:NewDesc("Set your Auto Repair options. If a guild repair fails it will not prevent a normal repair. Additionally you may also set a cost limit.", 2),
						Settings = {
							name = "Settings",
							type = "group",
							order = 3,
							guiInline = true,
							args = {
								UseGuild = LUI:NewToggle("Use Guild Repair", nil, 1, db.Merchant.AutoRepair, "UseGuild", dbd.Merchant.AutoRepair),
								NoLimit = LUI:NewToggle("No Cost Limit", nil, 2, db.Merchant.AutoRepair, "NoLimit", dbd.Merchant.AutoRepair),
								CostLimit = LUI:NewSlider("Cost Limit", "The cost limit in gold after which the repair won't happen automatically.", 3, db.Merchant.AutoRepair, "CostLimit", dbd.Merchant.AutoRepair, 0, 500, 10, nil, nil, function() return (not db.Merchant.AutoRepair.Enable) or db.Merchant.AutoRepair.NoLimit end),
								ShowError = LUI:NewToggle("Show Limit Error", nil, 4, db.Merchant.AutoRepair, "ShowError", dbd.Merchant.AutoRepair),
								ShowSuccess = LUI:NewToggle("Show Success Messages", nil, 5, db.Merchant.AutoRepair, "ShowSuccess", dbd.Merchant.AutoRepair),
							},
						},
					},
				},
				AutoSell = {
					name = "Auto Sell",
					type = "group",
					order = 2,
					disabled = function() return not db.Merchant.AutoSell.Enable end,
					args = {
						Title = LUI:NewHeader("Auto Sell Settings", 1),
						Info = LUI:NewDesc("Set your Auto Sell options.", 2),
						Warning = LUI:NewDesc("|cffff9933Warning:|r You really shouldn't enable other item qualities unless you are very sure that you won't sell anything of worth.", 3),
						Settings = {
							name = "Settings",
							type = "group",
							order = 3,
							guiInline = true,
							args = {
								ShowSuccess = LUI:NewToggle("Show Success Messages", nil, 1, db.Merchant.AutoSell, "ShowSuccess", dbd.Merchant.AutoSell),
								ShowExclusion = LUI:NewToggle("Show Exclusion Messages", nil, 2, db.Merchant.AutoSell, "ShowExclusion", dbd.Merchant.AutoSell),
							},
						},
						ItemQuality = {
							name = "Item Qualities",
							desc = "Changes the item quality from which everything automatically will be sold when opening a merchant frame.",
							type = "multiselect",
							values = qualities(),
							order = 4,
							set = function(_, key)
									db.Merchant.AutoSell.ItemQualities[key] = not db.Merchant.AutoSell.ItemQualities[key]
								end,
							get = function(_, key)
									return db.Merchant.AutoSell.ItemQualities[key]
								end,
						},
						AddExclusion = {
							type = "group",
							order = 5,
							name = "Add Item Exclusion",
							guiInline = true,
							args = {
								Description = LUI:NewDesc("Either select an item and drop it (leftclick) on the slot in here or enter an item id, name or link.\nYou can provide a link with a Shift + Leftclick on an item or link and the dropslot opens your bags if you don't have an item selected.", 1),
								DropItem = {
									name = "Drop an item here!",
									desc = "Select an item and drop it on this slot. (Leftclick)",
									type = "execute",
									order = 2,
									imageWidth = 64,
									imageHeight = 64,
									imageCoords = {0.15, 0.8, 0.15, 0.8},
									image = [[Interface\Buttons\UI-Quickslot2]],
									func = function()
											if CursorHasItem() then
												local _, itemID = GetCursorInfo()
												Merchant:ItemExclusion(itemID)
												ClearCursor()
											else
												OpenAllBags(true)
											end
										end,
								},
								InputItem = {
									name = "Or enter an id, name or link",
									desc = "Enter an item id, name or link (Shift + Leftclick an item)",
									type = "input",
									order = 3,
									set = function(_, item)
											Merchant:ItemExclusion(item)
										end,
								},
							},
						},
						RemoveExclusion = {
							name = "Remove Item Exclusion",
							type = "group",
							order = 6,
							guiInline = true,
							args = {
								Select = {
									name = "Select Item",
									desc = "Select the item which you want to remove from the exclusion list.",
									type = "select",
									width = "double",
									order = 1,
									values = function()
											local items = {}
											table.foreach(db.Merchant.AutoSell.Exclusions, function(itemID)
												local _, itemLink = GetItemInfo(itemID)
												items[itemID] = itemLink
											end)
											return items
										end,
									get = function()
											return removeExclusionKey
										end,
									set = function(_, key)
											removeExclusionKey = key
										end,
								},
								Remove = {
									name = "Remove selected item",
									desc = "Removes the selected item from the exclusion list.",
									type = "execute",
									order = 2,
									func = function()
											if removeExclusionKey then
												Merchant:ItemExclusion(removeExclusionKey, true)
												removeExclusionKey = nil
											end
										end,
								},
								Clear = {
									name = "Clear excluded items",
									desc = "Removes the selected item from the exclusion list.",
									type = "execute",
									order = 3,
									func = function()
											Merchant:ClearExclusions()
										end,
									confirmText = "Do you really want to clear all excluded items?",
									confirm = true,
								},
							},
						},
					},
				},
			},
		},
	}

	return options
end

function Merchant:OnInitialize()
	LUI:MergeDefaults(LUI.db.defaults.profile, defaults)
	LUI:RefreshDefaults()
	LUI:Refresh()

	-- Link database and defaults shortcuts.
	self.db = LUI.db.profile
	self.dbd = LUI.db.defaults.profile
	db = self.db
	dbd = self.dbd

	LUI:RegisterModule(self)
end

function Merchant:OnEnable()
	self:Create()
end

function Merchant:OnDisable()
	self:Create(true)
end