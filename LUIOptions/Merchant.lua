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
    Header = Opt:Header(L["Merchant"], 1),
	General = Opt:Group("General Settings", nil, 2, nil, nil, nil, Opt.GetSet(db.General)),
	NameText = Opt:Group("Name Text Settings", nil, 5, nil, nil, nil, Opt.GetSet(db.Text.Name)),
	Colors = Opt:Group("Bar Colors", nil, 4, nil, nil, nil, Opt.GetSet(db.Colors)),
}

local GeneralTab = {
	Width = Opt:InputNumber("Width", "Choose the Width for the Merchant.", 1),
	Height = Opt:InputNumber("Height", "Choose the Height for the Merchant.", 2),
	empty1 = Opt:Desc(" ", 3),
	X = Opt:InputNumber("X Value", "Choose the X Value for the Merchant.", 4),
	Y = Opt:InputNumber("Y Value", "Choose the Y Value for the Merchant.", 5),
	empty2 = Opt:Desc(" ", 6),
	Texture = Opt:MediaStatusbar("Texture", "Choose the Merchant Texture.", 7),
	TextureBG = Opt:MediaStatusbar("Background Texture", "Choose the Merchant Background Texture.", 8),
	BarGap = Opt:Slider("Spacing", "Select the Spacing between mirror bars when shown.", 9, {min = 0, max = 40, step = 1}),
	ArchyBar = Opt:Toggle("Archaeology Progress Bar", "Integrate the Archaeology Progress bar", 10, nil, "full"),
}

local ColorTab = {
	FatigueBar = Opt:Color("Fatigue Bar", "Fatigue Bar", 1),
	BreathBar = Opt:Color("Breath Bar", "Breath Bar", 2),
	FeignBar = Opt:Color("Feign Death Bar", "Feign Death Bar", 3),
	Bar = Opt:Color("Other Bar", "Other Merchants", 4),
	ArchyBar = Opt:Color("Archaeology Progress Bar", "Archaeology Progress Bar", 5),
	Background = Opt:Color("Background", "Merchant Background", 6),
}

local NameText = {
	Font = Opt:MediaFont("Font", "Choose the Font for the Mirror Name Text.", 2),
	Color = Opt:Color("Name", "Mirror Name", 4, false, nil, nil, nil, Opt.ColorGetSet(db.Text.Name)),
	Size = Opt:Slider("Size", "Choose the Font Size for the Mirror Name Text.", 3, {min = 6, max = 40, step = 1}),
	empty2 = Opt:Desc(" ", 5),
	OffsetX = Opt:InputNumber("X Value", "Choose the X Value for the Mirror Name Text.", 6),
	OffsetY = Opt:InputNumber("Y Value", "Choose the Y Value for the Mirror Name Text.", 7),
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

]]