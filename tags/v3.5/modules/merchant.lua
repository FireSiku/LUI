--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: merchant.lua
	Description: Merchant Module
	Version....: 1.2.2
	Rev Date...: 04/27/2011
	Author...: Xolsom
]]

local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local module = LUI:NewModule("Merchant", "AceHook-3.0")

local version = "1.2.2"
local merchantCheck -- Event checker
local maxItemQuality = 4 -- Epic
local autoClose = false
local removeExclusionKey

local defaults = {
	Merchant = {
		AutoClose = false,
		AutoRepair = {
			CostLimit = 5000000,
			Enable = false,
			NoLimit = true,
			ShowError = true,
			ShowSuccess = true,
			UseGuild = false,
		},
		AutoSell = {
			Enable = false,
			Exclusions = {},
			ItemQualitys = {
				true, -- Poor
				false, -- Common
				false, -- Uncommon
				false, -- Rare
				false, -- Epic
			},
			ShowExclusion = true,
			ShowSuccess = true,
		},
		Enable = true,
	},
}

function module:AutoMerchant()
	if not db.Merchant.Enable then
		return
	end

	self:AutoSell()

	self:AutoRepair()

	if autoClose and db.Merchant.AutoClose then
		autoClose = false

		CloseMerchant()
	end
end

function module:AutoRepair()
	if not db.Merchant.AutoRepair.Enable then
		return
	end

	if CanMerchantRepair() then
		local cost, can = GetRepairAllCost()

		if can then
			if cost > db.Merchant.AutoRepair.CostLimit and not db.Merchant.AutoRepair.NoLimit then
				if db.Merchant.AutoRepair.ShowError then
					print("|cffff0000The repair costs of|r " .. GetCoinTextureString(cost) .. " |cffff0000exceed the limit of|r " .. GetCoinTextureString(db.Merchant.AutoRepair.CostLimit))
				end

				return
			else
				if db.Merchant.AutoRepair.UseGuild then
					RepairAllItems(1);
				end

				-- Check if guild repair worked (both should be 0 / false)
				local cost2, can2 = GetRepairAllCost()

				if db.Merchant.AutoRepair.ShowSuccess and db.Merchant.AutoRepair.UseGuild and cost2 < cost then
					print("|cff00ff00Successfully guild repaired all armor for|r " .. GetCoinTextureString(cost - cost2))
				end

				if can2 then
					RepairAllItems();

					if db.Merchant.AutoRepair.ShowSuccess then
						print("|cff00ff00Successfully repaired all armor for|r " .. GetCoinTextureString(cost2))
					end
				end

				autoClose = true
			end
		end
	end
end

function module:AutoSell()
	if not db.Merchant.AutoSell.Enable then
		return
	end

	local totalPrice = 0
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			local item = GetContainerItemID(bag, slot)

			if item then
				local _, itemLink, itemQuality, _, _, _, _, _, _, _, itemPrice = GetItemInfo(item);
				local _, _, itemID = string.find(itemLink, "item:(%d+)")

				if (db.Merchant.AutoSell.ItemQualitys[itemQuality + 1] and not db.Merchant.AutoSell.Exclusions[itemID])
				or (not db.Merchant.AutoSell.ItemQualitys[itemQuality + 1] and db.Merchant.AutoSell.Exclusions[itemID])
				then
					UseContainerItem(bag, slot)

					local _, itemCount  = GetContainerItemInfo(bag, slot)
					totalPrice = totalPrice + itemCount * itemPrice
				end
			end
		end
	end

	if totalPrice > 0 then
		if db.Merchant.AutoSell.ShowSuccess then
			print("|cff00ff00Successfully sold all specified items for|r  " .. GetCoinTextureString(totalPrice))
		end

		autoClose = true
	end
end

function module:ItemExclusion(item, remove)
	local _, itemLink, _, _, _, _, _, _, _, _, itemPrice = GetItemInfo(item);

	if not itemLink then
		if db.Merchant.AutoSell.ShowExclusion then
			print(item .. " |cffff0000is not a valid item.")
		end

		return
	end

	local _, _, itemID = string.find(itemLink, "item:(%d+)")

	if remove then
		db.Merchant.AutoSell.Exclusions[itemID] = nil

		if db.Merchant.AutoSell.ShowExclusion then
			print("|cff00ff00Successfully removed|r " .. itemLink .. " |cff00ff00from the exclusion list.")
		end
	else
		if db.Merchant.AutoSell.Exclusions[itemID] then
			if db.Merchant.AutoSell.ShowExclusion then
				print(itemLink .. " |cffff0000 is already in the exclusion list.")
			end
		elseif itemPrice <= 0 then
			print(itemLink .. " |cffff0000 has no sell price and can't be excluded.")
		else
			db.Merchant.AutoSell.Exclusions[itemID] = true

			if db.Merchant.AutoSell.ShowExclusion then
				print("|cff00ff00Successfully added|r " .. itemLink .. " |cff00ff00to the exclusion list.")
			end
		end
	end
end

function module:ClearExclusions()
	db.Merchant.AutoSell.Exclusions = {}

	if db.Merchant.AutoSell.ShowExclusion then
		print("|cff00ff00Successfully cleared the exclusion list.")
	end
end

function module:LoadOptions()
	local options = {
		Merchant = {
			type = "group",
			order = 35,
			name = "Merchant",
			disabled = function()
					return not db.Merchant.Enable
				end,
			childGroups = "tab",
			args = {
				General = {
					type = "group",
					order = 1,
					name = "General",
					args = {
						Title = {
							type = "header",
							order = 1,
							name = "Merchant Module v" ..  version,
						},
						Info = {
							type = "group",
							order = 2,
							name = "Info",
							guiInline = true,
							args = {
								Description = {
									type = "description",
									order = 1,
									name = "This module allows you to automatically sell items and / or repair your armor when you open a merchant frame.",
								},
							},
						},
						Settings = {
							type = "group",
							order = 3,
							name = "Settings",
							guiInline = true,
							args = {
								AutoRepair = {
									type = "toggle",
									set = function(_, enable)
											db.Merchant.AutoRepair.Enable = enable
										end,
									order = 1,
									name = "Enable Auto Repair",
									get = function()
											return db.Merchant.AutoRepair.Enable
										end,
									desc = "Whether you want to enable Auto Repair or not.",
								},
								AutoSell = {
									type = "toggle",
									set = function(_, enable)
											db.Merchant.AutoSell.Enable = enable
										end,
									order = 2,
									name = "Enable Auto Sell",
									get = function()
											return db.Merchant.AutoSell.Enable
										end,
									disabled = false,
									desc = "Whether you want to enable Auto Sell or not.",
								},
								Space = {
									type = "description",
									order = 3,
									name = "\n"
								},
								AutoClose = {
									type = "toggle",
									set = function(_, autoClose)
											db.Merchant.AutoClose = autoClose
										end,
									order = 4,
									name = "Enable Auto Close",
									get = function()
											return db.Merchant.AutoClose
										end,
									desc = "Whether you want to automatically close the merchant frame after a successful repair or sale or not.",
								},
							},
						},
					},
				},
				AutoRepair = {
					type = "group",
					order = 2,
					name = "Auto Repair",
					disabled = function()
							return not db.Merchant.AutoRepair.Enable
						end,
					args = {
						Title = {
							type = "header",
							order = 1,
							name = "Auto Repair settings",
						},
						Info = {
							type = "group",
							order = 2,
							name = "Info",
							guiInline = true,
							args = {
								Description = {
									type = "description",
									order = 1,
									name = "Set your Auto Repair options. If a guild repair fails it will not prevent a normal repair. Additionally you may also set a cost limit.",
								},
							},
						},
						Settings = {
							type = "group",
							order = 3,
							name = "Settings",
							guiInline = true,
							args = {
								UseGuild = {
									width = "full",
									type = "toggle",
									set = function(_, useGuild)
											db.Merchant.AutoRepair.UseGuild = useGuild
										end,
									order = 1,
									name = "Use Guild Repair",
									get = function()
											return db.Merchant.AutoRepair.UseGuild
										end,
									desc = "Whether you want to user guild repair or not. Normal repair will still be used if the guild repair doesn't work.",
								},
								NoLimit = {
									type = "toggle",
									set = function(_, noLimit)
											db.Merchant.AutoRepair.NoLimit = noLimit
										end,
									order = 2,
									name = "No Cost Limit",
									get = function()
											return db.Merchant.AutoRepair.NoLimit
										end,
									desc = "Whether you always want to try to repair as long as gold is available.",
								},
								CostLimit = {
									type = "range",
									step = 1,
									set = function(_, costLimit)
											db.Merchant.AutoRepair.CostLimit = costLimit * 10000
										end,
									order = 3,
									name = "Cost Limit",
									min = 0,
									max = 500,
									get = function()
											return db.Merchant.AutoRepair.CostLimit / 10000
										end,
									disabled = function()
											return db.Merchant.AutoRepair.NoLimit or not db.Merchant.AutoRepair.Enable
										end,
									desc = "The cost limit in gold after which the repair won't happen automatically.",
									bigStep = 10,
								},
								ShowError = {
									width = "full",
									type = "toggle",
									set = function(_, showError)
											db.Merchant.AutoRepair.ShowError = showError
										end,
									order = 4,
									name = "Show Limit Error",
									get = function()
											return db.Merchant.AutoRepair.ShowError
										end,
									desc = "Whether you want to show the error message when the repair costs exceed the limit or not.",
								},
								ShowSuccess = {
									width = "full",
									type = "toggle",
									set = function(_, showSuccess)
											db.Merchant.AutoRepair.ShowSuccess = showSuccess
										end,
									order = 5,
									name = "Show Success Messages",
									get = function()
											return db.Merchant.AutoRepair.ShowSuccess
										end,
									desc = "Whether you want to show the success messages or not.",
								},
							},
						},
					},
				},
				AutoSell = {
					type = "group",
					order = 2,
					name = "Auto Sell",
					disabled = function()
							return not db.Merchant.AutoSell.Enable
						end,
					args = {
						Title = {
							type = "header",
							order = 1,
							name = "Auto Sell settings",
						},
						Info = {
							type = "group",
							order = 2,
							name = "Info",
							guiInline = true,
							args = {
								Description = {
									type = "description",
									order = 1,
									name = "Set your Auto Sell options.",
								},
								Exclusion = {
									type = "description",
									order = 2,
									name = "\n|cff3399ffNotice:|r An excluded item will be sold, when its quality is disabled and contrary not sold, when its quality is enabled.",
								},
								Warning = {
									type = "description",
									order = 3,
									name = "\n|cffff9933Beware:|r You really shouldn't enable other item qualitys unless you are very sure that you won't sell anything of worth.",
								},
							},
						},
						Settings = {
							type = "group",
							order = 3,
							name = "Settings",
							guiInline = true,
							args = {
								ShowSuccess = {
									width = "full",
									type = "toggle",
									set = function(_, showSuccess)
											db.Merchant.AutoSell.ShowSuccess = showSuccess
										end,
									order = 1,
									name = "Show Success Message",
									get = function()
											return db.Merchant.AutoSell.ShowSuccess
										end,
									desc = "Whether you want to show the success message or not.",
								},
								ShowExclusion = {
									width = "full",
									type = "toggle",
									set = function(_, showExclusion)
											db.Merchant.AutoSell.ShowExclusion = showExclusion
										end,
									order = 2,
									name = "Show Exclusion Messages",
									get = function()
											return db.Merchant.AutoSell.ShowExclusion
										end,
									desc = "Whether you want to show the exclusion messages or not. (Add / Remove item)",
								},
							},
						},
						ItemQuality = {
							values = function()
									local qualitys = {}
									for i = 0, maxItemQuality do
										qualitys[i + 1] =  ITEM_QUALITY_COLORS[i]["hex"] .. getglobal("ITEM_QUALITY" .. i .. "_DESC")
									end
									return qualitys
								end,
							type = "multiselect",
							set = function(_, key)
									db.Merchant.AutoSell.ItemQualitys[key] = not db.Merchant.AutoSell.ItemQualitys[key]
								end,
							order = 4,
							name = "Item Qualitys",
							get = function(_, key)
									return db.Merchant.AutoSell.ItemQualitys[key]
								end,
							desc = "Changes the item quality from which everything automatically will be sold when opening a merchant frame.",
							confirm = function(_, key)
									if not db.Merchant.AutoSell.ItemQualitys[key] then
										return "Do you really want to enable the " .. ITEM_QUALITY_COLORS[key - 1]["hex"] .. getglobal("ITEM_QUALITY" .. key - 1 .. "_DESC") .. "|r item quality?"
									else
										return false
									end
								end,
						},
						AddExclusion = {
							type = "group",
							order = 5,
							name = "Add Item Exclusion",
							guiInline = true,
							args = {
								Description = {
									type = "description",
									order = 1,
									name = "Either select an item and drop it (leftclick) on the slot in here or enter an item id, name or link.\nYou can provide a link with a Shift + Leftclick on an item or link and the dropslot opens your bags if you don't have an item selected.",
								},
								DropItem = {
									type = "execute",
									name = "Drop an item here!",
									order = 2,
									imageWidth = 64,
									imageHeight = 64,
									imageCoords = {0.15, 0.8, 0.15, 0.8},
									image = [[Interface\Buttons\UI-Quickslot2]],
									func = function()
											if CursorHasItem() then
												local _, itemID = GetCursorInfo()
												module:ItemExclusion(itemID)
												ClearCursor()
											else
												OpenAllBags(true)
											end
										end,
									desc = "Select an item and drop it on this slot. (Leftclick)",
								},
								InputItem = {
									type = "input",
									set = function(_, item)
											module:ItemExclusion(item)
										end,
									order = 3,
									name = "Or enter an id, name or link",
									desc = "Enter an item id, name or link (Shift + Leftclick an item)",
								},
							},
						},
						RemoveExclusion = {
							type = "group",
							order = 6,
							name = "Remove Item Exclusion",
							guiInline = true,
							args = {
								Select = {
									width = "double",
									values = function()
											local items = {}
											table.foreach(db.Merchant.AutoSell.Exclusions, function(itemID)
												local _, itemLink = GetItemInfo(itemID)
												items[itemID] = itemLink
											end)
											return items
										end,
									type = "select",
									order = 1,
									name = "Select item",
									get = function()
											return removeExclusionKey
										end,
									set = function(_, key)
											removeExclusionKey = key
										end,
									desc = "Select the item which you want to remove from the exclusion list.",
								},
								Remove = {
									type = "execute",
									name = "Remove selected item",
									order = 2,
									func = function()
											if removeExclusionKey then
												module:ItemExclusion(removeExclusionKey, true)
												removeExclusionKey = nil
											end
										end,
									desc = "Removes the selected item from the exclusion list.",
								},
								Clear = {
									type = "execute",
									name = "Clear excluded items",
									order = 3,
									func = function()
											module:ClearExclusions()
										end,
									desc = "Removes the selected item from the exclusion list.",
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

function module:HandleEvents()
	merchantCheck = CreateFrame("Frame", _, UIParent)

	merchantCheck:HookScript("onEvent", function(_, event)
		if event == "MERCHANT_SHOW" then
			self:AutoMerchant()
		end
	end)

	merchantCheck:RegisterEvent("MERCHANT_SHOW")
end


function module:OnInitialize()
	LUI:MergeDefaults(LUI.db.defaults.profile, defaults)
	LUI:RefreshDefaults()
	LUI:Refresh()

	self.db = LUI.db.profile
	db = self.db

	LUI:RegisterModule(self);
end

function module:OnEnable()
	self:HandleEvents()
end
