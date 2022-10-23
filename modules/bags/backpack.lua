-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

local _, LUI = ...
local module = LUI:GetModule("Bags")
local Media = LibStub("LibSharedMedia-3.0")

local format, tinsert, wipe = format, tinsert, wipe
local GetBackpackCurrencyInfo = GetBackpackCurrencyInfo
local GetMoneyString = GetMoneyString
local GetMoney = GetMoney

-- Constants
local MAX_WATCHED_TOKENS = MAX_WATCHED_TOKENS

local BACKPACK_TOKEN_UPDATE_FUNC = "BackpackTokenFrame_Update"
local BAG_SLOT_TEMPLATE = "ContainerFrameItemButtonTemplate"
local BAG_SLOT_NAME_FORMAT = "LUIBags_Item%d_%d"
local CURRENCY_FORMAT = "%d\124T%s:0:0:3:0\124t"
local BAG_BAGBAR_NAME_FORMAT = "LUIBags_Bag%d"

-- ####################################################################################################################
-- ##### Bag Container Object #########################################################################################
-- ####################################################################################################################

local Bags = {
	--Constants
	NUM_BAG_IDS = 5,
	BAG_ID_LIST = { 0, 1, 2, 3, 4 },

	-- vars
	name = "Bags",
}

function Bags:OnShow()
end

function Bags:OnHide()
end

function Bags:Layout()
	self:UpdateCurrencies()
	self.bagsBar:SetAnchors()
	self.utilBar:SetAnchors()
end

function Bags:NewItemSlot(id, slot)

	if self.itemList[id] and self.itemList[id][slot] then
		return self.itemList[id][slot]
	end

	local name = format(BAG_SLOT_NAME_FORMAT, id, slot)
	local itemSlot = module:CreateSlot(name, self.bagList[id], BAG_SLOT_TEMPLATE)
	--local itemSlot = CreateFrame("Button", name, self.bagList[id], BAG_SLOT_TEMPLATE)

	-- id/slot info is a pain to get through template's means, make it easier
	itemSlot.id = id
	itemSlot.slot = slot
	-- SetID refers to the slot number within the bag, used by template's functions.
	itemSlot:SetID(slot)
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
	--TODO: Possibly change those two to use LUI FontStrings api
	local gold = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
	gold:SetJustifyH("RIGHT")
	gold:SetPoint("RIGHT", self.closeButton, "LEFT", -3, 0)
	gold:SetFont(Media:Fetch("font", db.Bags.Name), db.Bags.Size, db.Bags.Flag)

	-- Watched Currency Display, next to gold
	local currency = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
	currency:SetJustifyH("RIGHT")
	currency:SetPoint("RIGHT", gold, "LEFT", -10, 0)
	currency:SetText(self:GetCurrencyString())
	currency:SetFont(Media:Fetch("font", db.Bags.Name), db.Bags.Size, db.Bags.Flag)

	--Hooking this function allows to update watched currencies without a ReloadUI
	local updateFunc = function() self:UpdateCurrencies() end
	module:SecureHook(BACKPACK_TOKEN_UPDATE_FUNC, updateFunc)
	self:SetScript("OnEvent", updateFunc)
	self:RegisterEvent("PLAYER_MONEY")
	self:RegisterEvent("PLAYER_LOGIN")
	self:RegisterEvent("PLAYER_TRADE_MONEY")
	self:RegisterEvent("TRADE_MONEY_CHANGED")
	self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
	self:RegisterEvent("PLAYER_TRADE_CURRENCY")
	self:RegisterEvent("TRADE_CURRENCY_CHANGED")

	self.gold = gold
	self.currency = currency
end

local currencyString = {}
function Bags:GetCurrencyString()
	wipe(currencyString)
	for i = 1, MAX_WATCHED_TOKENS do
		local name, count, icon = GetBackpackCurrencyInfo(i)
		if name then
			currencyString[i] = format(CURRENCY_FORMAT,count,icon)
		end
	end
	return table.concat(currencyString, "  ")
end

function Bags:UpdateCurrencies()
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
		local name = format(BAG_BAGBAR_NAME_FORMAT, id)
		-- index must starts at 0, but we start the loop at 2.
		local bagsSlot = module:BagBarSlotButtonTemplate(i - 2, id, name, self.bagsBar)
		self.bagsBar.slotList[i-1] = bagsSlot

		bagsSlot:Show()
	end
end

function Bags:CreateUtilBar()
	local utilBar = self.utilBar

	--CleanUp
	local button = module:CreateCleanUpButton("LUIBags_CleanUp", utilBar, SortBags)
	utilBar:AddNewButton(button)
end

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

local function OpenBags()
	LUIBags:Open()
end

local function CloseBags()
	LUIBags:Close()
end

local function ToggleBags()
	if LUIBags:IsShown() then
		CloseBags()
	else
		OpenBags()
	end
end

--Placeholders until refactor
module.BagsContainer = Bags