-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, Opt
local optName, Opt = ...
local L, module, db = Opt:GetLUIModule("Merchant")
if not module or not module.registered then return end

-- ####################################################################################################################
-- ##### Utility Functions ############################################################################################
-- ####################################################################################################################


-- ####################################################################################################################
-- ##### Options Tables ###############################################################################################
-- ####################################################################################################################

Opt.options.args.Merchant = Opt:Group("Merchant", nil, nil, "tab", Opt.IsModDisabled, nil, Opt.GetSet(db))
Opt.options.args.Merchant.handler = module

local Merchant = {
    -- General
    Header = Opt:Header({name = L["Merchant"]}),
	General = Opt:Group({name = "General Settings", db = db.General}),
	NameText = Opt:Group({name = "Name Text Settings", ndb = db.Text.Name}),
	Colors = Opt:Group({name = "Bar Colors", db = db.Colors}),
}

local GeneralTab = {
	Width = Opt:InputNumber({name = "Width", desc = "Choose the Width for the Merchant."}),
	Height = Opt:InputNumber({name = "Height", desc = "Choose the Height for the Merchant."}),
	empty1 = Opt:Spacer({}),
	X = Opt:InputNumber({name = "X Value", desc = "Choose the X Value for the Merchant."}),
	Y = Opt:InputNumber({name = "Y Value", desc = "Choose the Y Value for the Merchant."}),
	empty2 = Opt:Spacer({}),
	Texture = Opt:MediaStatusbar({name = "Texture", desc = "Choose the Merchant Texture."}),
	TextureBG = Opt:MediaStatusbar({name = "Background Texture", desc = "Choose the Merchant Background Texture."}),
	BarGap = Opt:Slider({name = "Spacing", desc = "Select the Spacing between mirror bars when shown.", min = 0, max = 40, step = 1}),
	ArchyBar = Opt:Toggle({name = "Archaeology Progress Bar", desc = "Integrate the Archaeology Progress bar", width = "full"}),
}

local ColorTab = {
	FatigueBar = Opt:Color({name = "Fatigue Bar", desc = "Fatigue Bar"}),
	BreathBar = Opt:Color({name = "Breath Bar", desc = "Breath Bar"}),
	FeignBar = Opt:Color({name = "Feign Death Bar", desc = "Feign Death Bar"}),
	Bar = Opt:Color({name = "Other Bar", desc = "Other Merchants"}),
	ArchyBar = Opt:Color({name = "Archaeology Progress Bar", desc = "Archaeology Progress Bar"}),
	Background = Opt:Color({name = "Background", desc = "Merchant Background"}),
}

local NameText = {
	Font = Opt:MediaFont({name = "Font", desc = "Choose the Font for the Mirror Name Text."}),
	Color = Opt:Color({name = "Name", desc = "Mirror Name", hasAlpha = false, db = db.Text.Name}),
	Size = Opt:Slider({name = "Size", desc = "Choose the Font Size for the Mirror Name Text.", min = 6, max = 40, step = 1}),
	empty2 = Opt:Spacer({}),
	OffsetX = Opt:InputNumber({name = "X Value", desc = "Choose the X Value for the Mirror Name Text."}),
	OffsetY = Opt:InputNumber({name = "Y Value", desc = "Choose the Y Value for the Mirror Name Text."}),
}

Opt.options.args.Merchant.args = Merchant

--- Link the groups together.
Merchant.General.args = GeneralTab
Merchant.Colors.args = ColorTab
Merchant.NameText.args = NameText

-- ####################################################################################################################
-- ##### Old Options ###############################################################################################
-- ####################################################################################################################
--[[ 
	
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
			Enable = self:NewToggle({name = "Enable Auto Repair", true}),
			Settings = self:NewGroup("Settings", 4, true, disabled.AutoRepair, {
				UseGuild = self:NewToggle({name = "Use Guild Repair", true}),
				NoLimit = self:NewToggle({name = "No Cost Limit", true}),
				CostLimit = self:NewSlider({name = "Cost Limit", desc = "The cost limit in gold after which the repair won't happen automatically.", 0, 500, 10, true, false, nil, disabled.CostLimit}),
				ShowError = self:NewToggle({name = "Show Limit Error", true}),
				ShowSuccess = self:NewToggle({name = "Show Success Messages", true}),
			}),
		}),
		AutoSell = self:NewGroup("Auto Sell", 3, {
			Title = self:NewHeader("Auto Sell Settings", 1),
			Info = self:NewDesc("Set your Auto Sell options.", 2),
			Enable = self:NewToggle({name = "Enable Auto Sell", true}),
			Settings = self:NewGroup("Settings", 4, true, disabled.AutoSell, {
				ShowSuccess = self:NewToggle({name = "Show Success Messages", true}),
				ShowExclusion = self:NewToggle({name = "Show Exclusion Messages", true}),
			}),
			Warning = self:NewDesc("|cffff9933Warning:|r You really shouldn't enable other item qualities unless you are very sure that you won't sell anything of value.", 5),
			ItemQualities = self:NewMultiSelect("Item Qualities", "Changes the item quality from which everything automatically will be sold when opening a merchant frame.",
				6, qualities, nil, nil, disabled.AutoSell),
			AddExclusion = self:NewGroup("Add Item Exclusion", 7, LUI.dummy, "ItemExclusion", true, disabled.AutoSell, {
				Description = self:NewDesc("Items in this list will behave opposite of the settings.\nTo add an item to the Exclusion list do one of the following:\n" ..
						"Drag and drop ({name = leftclick) an item into the box.\nEnter an item id, desc = name or link in the input box.\n\t	You can provide a link by Shift + Leftclicking on an item or link."}),
				DropItem = self:NewExecute({name = "Drop an item here!", desc = "Select an item and drop it on this slot. (Leftclick)", "ItemExclusion"}),
				InputItem = self:NewInput("Or enter an id, name or link", "Enter an item id, name or link (Shift + Leftclick an item)", 3, false)
			}),
			RemoveExclusion = self:NewGroup("Remove Item Exclusion", 8, exclusionGet, exclusionSet, true, disabled.AutoSell, {
				Select = self:NewSelect({name = "Select Item", desc = "Select the item which you want to remove from the exclusion list.", exclusions, nil, false, "double"}),
				Remove = self:NewExecute({name = "Remove selected item", desc = "Removes the selected item from the exclusion list.", removeExclusion, nil, nil, disabled.NoExclusionSelected}),
				Clear = self:NewExecute({name = "Clear excluded items", desc = "Removes the selected item from the exclusion list.", "ClearExclusions", "Do you really want to clear all excluded items?", nil, disabled.NoExclusions}),
			}),
		}),
		AutoStock = self:NewGroup("Auto Stock", 4, {
			Title = self:NewHeader("Auto Stock Settings", 1),
			Info = self:NewDesc("Set your Auto Stock options. Additionally you may also set a cost limit.", 2),
			Enable = self:NewToggle({name = "Enable Auto Stock", true}),
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
				NoLimit = self:NewToggle({name = "No Cost Limit", true}),
				CostLimit = self:NewSlider({name = "Cost Limit", desc = "The cost limit in gold after which buying items won't happen automatically.", 0, 500, 10, true, false, nil, disabled.BuyLimit}),
				ShowError = self:NewToggle({name = "Show Limit Error", true}),
				ShowSuccess = self:NewToggle({name = "Show Success Messages", true}),
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

]]
