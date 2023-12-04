-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class Opt
local Opt = select(2, ...)

---@type AceLocale.Localizations, LUI.Merchant, AceDB-3.0
local L, module, db = Opt:GetLUIModule("Merchant")
if not module or not module.registered then return end

local Merchant = Opt:CreateModuleOptions("Merchant", module)

-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################

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
local stockCurrent
local stockList = {}
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
local function stockUpdateSet(info, v)
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
		module:ItemExclusion(true, removeExclusionKey)
		removeExclusionKey = nil
	end
end

-- ####################################################################################################################
-- ##### Options Tables ###############################################################################################
-- ####################################################################################################################

Merchant.args = {
    -- General
    Header = Opt:Header({name = L["Merchant"]}),
	Info = Opt:Desc({name = "This Merchant allows you to automatically sell/buy items and/or repair your armor when you open a merchant frame."}),
	AutoRepair = Opt:Group({name = "Auto Repair", db = db.AutoRepair, args = {
		Title = Opt:Header({name = "Auto Repair Settings"}),
		Info = Opt:Desc({name = "Set your Auto Repair options. If a guild repair fails it will not prevent a normal repair. Additionally you may also set a cost limit."}),
		Enable = Opt:Toggle({name = "Enable Auto Repair"}),
		Settings = Opt:InlineGroup({name = "Settings",  db = db.AutoRepair.Settings, disabled = disabled.AutoRepair,args = {
			ShowSuccess = Opt:Toggle({name = "Show Success Messages", width = "full"}),
			UseGuild = Opt:Toggle({name = "Use Guild Repair", width = "full"}),
			NoLimit = Opt:Toggle({name = "No Cost Limit", width = "full"}),
			ShowError = Opt:Toggle({name = "Show Limit Error", disabled = disabled.CostLimit}),
			CostLimit = Opt:Slider({name = "Cost Limit", min = 0, max = 500, step = 10, disabled = disabled.CostLimit, desc = "The cost limit in gold after which the repair won't happen automatically."}),
		}}),
	}}),
	AutoSell = Opt:Group({name = "Auto Sell", db = db.AutoSell, args = {
		Title = Opt:Header({name = "Auto Sell Settings"}),
		Info = Opt:Desc({name = "Set your Auto Sell options."}),
		Enable = Opt:Toggle({name = "Enable Auto Sell", width = "full"}),
		Settings = Opt:InlineGroup({name = "Settings", db = db.AutoSell.Settings, disabled = disabled.AutoSell, args = {
			ShowSuccess = Opt:Toggle({name = "Show Success Messages", width = "full"}),
			ShowExclusion = Opt:Toggle({name = "Show Exclusion Messages", width = "full"}),
		}}),
		Warning = Opt:Desc({name = "|cffff9933Warning:|r You really shouldn't enable other item qualities unless you are very sure that you won't sell anything of value."}),
		--- @TODO: ItemQualities is not pulling DB correctly. 
		ItemQualities = Opt:MultiSelect({name = "Item Qualities", db = db.AutoSell, desc = "Changes the item quality from which everything automatically will be sold when opening a merchant frame.",
			values = qualities, disabled = disabled.AutoSell}),
		AddExclusion = Opt:InlineGroup({name = "Add Item Exclusion", set = module.ItemExclusion, disabled = disabled.AutoSell, args = {
			Description = Opt:Desc({name = "Items in this list will behave opposite of the settings.\nTo add an item to the Exclusion list do one of the following:\n" ..
				"Drag and drop (leftclick) an item into the box.\nEnter an item id, desc = name or link in the input box.\n\t" ..
				"You can provide a link by Shift + Leftclicking on an item or link."}),
			DropItem = Opt:Execute({name = "Drop an item here!", desc = "Select an item and drop it on this slot. (Leftclick)", func = module.ItemExclusion,
				imageWidth = 64, imageHeight = 64, imageCoords = {0.15, 0.8, 0.15, 0.8}, image = "Interface\\Buttons\\UI-Quickslot2"}),
			InputItem = Opt:Input({name = "Or enter an id, name or link", desc = "Enter an item id, name or link (Shift + Leftclick an item)"})
		}}),
		RemoveExclusion = Opt:InlineGroup({name = "Remove Item Exclusion", get = exclusionGet, set = exclusionSet, disabled = disabled.AutoSell, args = {
			Select = Opt:Select({name = "Select Item", desc = "Select the item which you want to remove from the exclusion list.", values = exclusions, width = "double"}),
			Remove = Opt:Execute({name = "Remove selected item", desc = "Removes the selected item from the exclusion list.", func = removeExclusion, disabled = disabled.NoExclusionSelected}),
			Clear = Opt:Execute({name = "Clear excluded items", desc = "Removes the selected item from the exclusion list.", func = module.ClearExclusions, confirm = "Do you really want to clear all excluded items?", disabled = disabled.NoExclusions}),
		}}),
	}}),

	AutoStock = Opt:Group({name = "Auto Stock", db = db.AutoStock, args = {
		Title = Opt:Header({name = "Auto Stock Settings"}),
		Info = Opt:Desc({name = "Set your Auto Stock options. Additionally you may also set a cost limit."}),
		Enable = Opt:Toggle({name = "Enable Auto Stock", width = "full"}),
		Items = Opt:Select({name = "Stock List", desc = "List of all items that will automatically be restocked.", values = stockValues, get = stockGet, set = stockSet, disabled = disabled.AutoStock}),
		Update = Opt:Input({name = "Count & New Item", desc = "Type in the amount to buy of the selected item, or type in a new item name, link or id to add a new item to the list. If entering an item id please enter like so: \"id:1234\".", 
			get = stockUpdateGet, set = stockUpdateSet, disabled = disabled.AutoStock }),
		Settings = Opt:InlineGroup({name = "Settings", db = db.AutoStock.Settings, disabled = disabled.AutoStock, args = {
			ShowSuccess = Opt:Toggle({name = "Show Success Messages", width = "full"}),
			NoLimit = Opt:Toggle({name = "No Cost Limit", width = "full"}),
			ShowError = Opt:Toggle({name = "Show Limit Error", disabled = disabled.BuyLimit}),
			CostLimit = Opt:Slider({name = "Cost Limit", desc = "The cost limit in gold after which buying items won't happen automatically.", 
				min = 0, max = 500, step = 10, disabled = disabled.BuyLimit}),
		}}),
	}}),
}
