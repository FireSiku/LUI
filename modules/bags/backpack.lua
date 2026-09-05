-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Bags
local module = LUI:GetModule("Bags")
local Media = LibStub("LibSharedMedia-3.0")

local GetNumWatchedTokens = _G.GetNumWatchedTokens
local GetMoneyString = _G.GetMoneyString
local C_CurrencyInfo = C_CurrencyInfo
local C_Container = C_Container
local GetMoney = _G.GetMoney


-- Constants
local BAG_SLOT_TEMPLATE = "ContainerFrameItemButtonTemplate"
local BAG_SLOT_NAME_FORMAT = "LUIBags_Item%d_%d"
local CURRENCY_FORMAT = "%d\124T%s:0:0:3:0\124t"
local BAG_BAGBAR_NAME_FORMAT = "LUIBags_Bag%d"
local titleBarEvents = {
	"PLAYER_MONEY",
	"PLAYER_LOGIN",
	"PLAYER_TRADE_MONEY",
	"TRADE_MONEY_CHANGED",
	"CURRENCY_DISPLAY_UPDATE",
	"PLAYER_TRADE_CURRENCY",
	"TRADE_CURRENCY_CHANGED",
}

-- ####################################################################################################################
-- ##### Bag Container Object #########################################################################################
-- ####################################################################################################################

local Bags = {
	--Constants
	NUM_BAG_IDS = 5,
	BAG_ID_LIST = {
		Enum.BagIndex.Backpack,
		Enum.BagIndex.Bag_1,
		Enum.BagIndex.Bag_2,
		Enum.BagIndex.Bag_3,
		Enum.BagIndex.Bag_4,
	},

	-- vars
	name = "Bags",
}

table.insert(Bags.BAG_ID_LIST, Enum.BagIndex.ReagentBag)
Bags.NUM_BAG_IDS = 6

function Bags:Layout()
	self:UpdateCurrencies()
end

function Bags:NewItemSlot(id, slot)

	if self.itemList[id] and self.itemList[id][slot] then
		return self.itemList[id][slot]
	end

	local name = string.format(BAG_SLOT_NAME_FORMAT, id, slot)
	local itemSlot = module:CreateSlot(name, self.bagList[id], BAG_SLOT_TEMPLATE)

	-- id/slot info is a pain to get through template's means, make it easier
	itemSlot.id = id
	itemSlot.slot = slot
	-- SetID refers to the slot number within the bag, used by template's functions.
	itemSlot:SetID(slot)
	itemSlot:SetBagID(id)
	itemSlot:RegisterBagButtonUpdateItemContextMatching()
	itemSlot:Show()

	--Set properties
	self:SetItemSlotProperties(itemSlot)
	return itemSlot
end

-- ####################################################################################################################
-- ##### Bag Container: Title Bar #####################################################################################
-- ####################################################################################################################

function Bags:ShowTitleBar()
	self.gold:Show()
	self.currency:Show()
end

function Bags:HideTitleBar()
	self.gold:Hide()
	self.currency:Hide()
end

function Bags:CreateTitleBar()
	local db = module.db.profile.Fonts
	local gold = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
	gold:SetJustifyH("RIGHT")
	gold:SetPoint("RIGHT", self.closeButton, "LEFT", -3, 0)
	gold:SetFont(Media:Fetch("font", db.Bags.Name), db.Bags.Size, db.Bags.Flag)

	-- Watched Currency Display, next to gold
	local currency = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
	currency:SetJustifyH("RIGHT")
	currency:SetPoint("RIGHT", gold, "LEFT", -25, 0)
	currency:SetText(self:GetCurrencyString())
	currency:SetFont(Media:Fetch("font", db.Bags.Name), db.Bags.Size, db.Bags.Flag)

	local updateFunc = function() self:UpdateCurrencies() end
	self:SetScript("OnEvent", updateFunc)
	self:RegisterTitleBarEvents()

	self.gold = gold
	self.currency = currency
end

function Bags:RegisterTitleBarEvents()
	for _, event in ipairs(titleBarEvents) do
		self:RegisterEvent(event)
	end
end

local currencyString = {}
function Bags:GetCurrencyString()
	table.wipe(currencyString)
	for i = 1, GetNumWatchedTokens() do
		local data = C_CurrencyInfo.GetBackpackCurrencyInfo(i)
		if data and data.name then
			currencyString[i] = string.format(CURRENCY_FORMAT, data.quantity, data.iconFileID)
		end
	end
	return table.concat(currencyString, "  ")
end

function Bags:UpdateCurrencies()
	if not module.originalBackpackTokenWidth then
		module.originalBackpackTokenWidth = BackpackTokenFrame:GetWidth()
	end
	BackpackTokenFrame:SetWidth(self:GetWidth())
	self.gold:SetText(GetMoneyString(GetMoney()))
	self.currency:SetText(self:GetCurrencyString())
end

-- ####################################################################################################################
-- ##### Bag Container: Toolbars ######################################################################################
-- ####################################################################################################################

function Bags:CreateBagBar()
	-- Starting at 2 because we don't need backpack on the BagBar
	for i = 2, self.NUM_BAG_IDS do
		local id = self.BAG_ID_LIST[i]
		local name = string.format(BAG_BAGBAR_NAME_FORMAT, id)
		-- index must starts at 0, but we start the loop at 2.
		local bagsSlot = module:BagBarSlotButtonTemplate(i - 2, id, name, self.bagsBar)
		self.bagsBar.slotList[i-1] = bagsSlot

		bagsSlot:Show()
	end
end

function Bags:CreateUtilBar()
	local utilBar = self.utilBar

	--CleanUp
	local button = module:CreateCleanUpButton("LUIBags_CleanUp", utilBar, C_Container.SortBags)
	utilBar:AddNewButton(button)
end

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

function module.OpenBags()
	if _G.ContainerFrame_AllowedToOpenBags and not _G.ContainerFrame_AllowedToOpenBags() then
		return
	end
	LUIBags:Open()
end

function module.CloseBags()
	LUIBags:Close()
end

function module.ToggleBags()
	if _G.ContainerFrame_AllowedToOpenBags and not _G.ContainerFrame_AllowedToOpenBags() then
		return
	end
	if LUIBags:IsShown() then
		module.CloseBags()
	else
		module.OpenBags()
	end
end

-- Expose the character-bag descriptor to the shared container factory.
module.BagsContainer = Bags
