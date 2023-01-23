-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, LUIAddon
local _, LUI = ...

---@type BagsModule
local module = LUI:GetModule("Bags")

local format = format
local PurchaseSlot = _G.PurchaseSlot
local CloseBankFrame = _G.CloseBankFrame
local GetNumBankSlots = _G.GetNumBankSlots
local GetBankSlotCost = _G.GetBankSlotCost
local PutItemInBag = _G.PutItemInBag
local GetCoinIcon = _G.GetCoinIcon
local GetMoneyString = _G.GetMoneyString

local CONFIRM_BUY_BANK_SLOT = _G.CONFIRM_BUY_BANK_SLOT
local BANK_BAG_PURCHASE = _G.BANK_BAG_PURCHASE
local COSTS_LABEL = _G.COSTS_LABEL
local YES = _G.YES
local NO = _G.NO

local BANK_SLOT_MAIN_TEMPLATE = "BankItemButtonGenericTemplate"
local BANK_SLOT_TEMPLATE = "ContainerFrameItemButtonTemplate"
local BANK_SLOT_NAME_FORMAT = "LUIBank_Item%d_%d"
local BANK_BAGBAR_NAME_FORMAT = "LUIBags_Bag%d"
--local EMPTY_SLOT_TEXTURE_NAME = "Interface\\paperdoll\\UI-PaperDoll-Slot-Bag"

--Making sure the Static Popup uses the good args.
--TODO: This could probably be handled better. Have it revert if you disable the module.
StaticPopupDialogs["CONFIRM_BUY_BANK_SLOT"] = {
	preferredIndex = 3,
	text = CONFIRM_BUY_BANK_SLOT,
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		PurchaseSlot();
	end,
	OnShow = function(self)
		_G.MoneyFrame_Update(self.moneyFrame, LUIBank.bankCost);
	end,
	hasMoneyFrame = 1,
	timeout = 0,
	hideOnEscape = 1,
}

-- ####################################################################################################################
-- ##### Bank Container Object ########################################################################################
-- ####################################################################################################################

local Bank = {
	--Constants
	NUM_BAG_IDS = 8,
	BAG_ID_LIST = {
		Enum.BagIndex.Bank,
		Enum.BagIndex.BankBag_1,
		Enum.BagIndex.BankBag_2,
		Enum.BagIndex.BankBag_3,
		Enum.BagIndex.BankBag_4,
		Enum.BagIndex.BankBag_5,
		Enum.BagIndex.BankBag_6,
		Enum.BagIndex.BankBag_7,
	},

	-- vars
	name = "Bank",
}

function Bank:OnShow()
end

function Bank:OnHide()
	CloseBankFrame()
end

function Bank:Layout()
	if true then return end
	self.bagsBar:SetAnchors()
	self.utilBar:SetAnchors()

	for i = 2, self.NUM_BAG_IDS do
		local id = self.BAG_ID_LIST[i]
		local bagSlot = _G[format(BANK_BAGBAR_NAME_FORMAT, id)]
		module:BankBagButtonUpdate(bagSlot)

		local bankSlots, fullBank = GetNumBankSlots()
		if not fullBank then
			local cost = GetBankSlotCost()

			--Most recently bought bag
			if i == bankSlots + 1 then
				-- Set things back up to normal after a purchase
				bagSlot:SetAlpha(1)
				bagSlot:SetScript("OnClick", function(self) PutItemInBag(self.inventoryID) end)
				bagSlot:UnregisterEvent("PLAYERBANKBAGSLOTS_CHANGED")

			-- Bag about to be purchased
			elseif i == bankSlots + 2 then
				bagSlot:SetAlpha(1)
				bagSlot.icon:SetTexture(GetCoinIcon(cost))
				bagSlot:RegisterEvent("PLAYERBANKBAGSLOTS_CHANGED")

				-- Add the Click-To-Purchase option.
				bagSlot:SetScript("OnClick", function(self)
					LUIBank.bankCost = cost
					StaticPopup_Show("CONFIRM_BUY_BANK_SLOT");
				end)

				-- BUG: Something is causing the GameTooltip to disappear prematurely.
				bagSlot:SetScript("OnEnter", function()
					GameTooltip:SetOwner(bagSlot)
					GameTooltip:SetText(BANK_BAG_PURCHASE)
					GameTooltip:AddLine(COSTS_LABEL.." "..GetMoneyString(cost))
					GameTooltip:Show()
				end)
				bagSlot:SetScript("OnLeave", function()
					_G.GameTooltip_Hide()
				end)

			-- Unpurchased bags
			elseif i > bankSlots + 2 then
				bagSlot:SetAlpha(.2)
				bagSlot.icon:SetTexture("")
			end
		elseif fullBank and LUIBank.bankCost then
			LUIBank.bankCost = nil
		end
	end
end

-- TODO: Clean this up, using LUIBank global looks dirty.
function Bank:BankSlotsUpdate()
	for i = 1, #LUIBank.itemList[-1] do
		LUIBank:SlotUpdate(LUIBank.itemList[-1][i])
	end
end

function Bank:NewItemSlot(id, slot)

	if self.itemList[id] and self.itemList[id][slot] then
		return self.itemList[id][slot]
	end

	local name = format(BANK_SLOT_NAME_FORMAT, id, slot)
	local template = (id == -1) and BANK_SLOT_MAIN_TEMPLATE or BANK_SLOT_TEMPLATE
	local itemSlot = module:CreateSlot(name, self.bagList[id], template)

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
-- ##### Bank Container: Toolbars #####################################################################################
-- ####################################################################################################################

function Bank:CreateBagBar()
	-- Starting at 2 because we don't need backpack on the BagBar
	for i = 2, self.NUM_BAG_IDS do
		local id = self.BAG_ID_LIST[i]
		local name = format(BANK_BAGBAR_NAME_FORMAT, id)
		-- index must starts at 0, but we start the loop at 2.
		local bagsSlot = module:BagBarSlotButtonTemplate(i - 2, id, name, self.bagsBar)
		self.bagsBar.slotList[i-1] = bagsSlot

		bagsSlot:Show()
	end
end

function Bank:CreateUtilBar()
	local utilBar = self.utilBar

	--CleanUp
	local button = module:CreateCleanUpButton("LUIBank_CleanUp", utilBar, C_Container.SortBankBags)
	utilBar:AddNewButton(button)
end

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################
-- When opening bank, open bags if needed.
-- If bank opened bags, bags should close at same time.

local hasBankOpenBags = false

function module.OpenBank()
	--TODO: Only create bank when needed.
	if not LUIBags:IsShown() then
		hasBankOpenBags = true
		LUIBags:Open()
	end
	LUIBank:Open()
end

function module.CloseBank()
	if hasBankOpenBags then
		LUIBags:Close()
		hasBankOpenBags = false
	end
	LUIBank:Close()
end

--Placeholders until refactor
module.BankContainer = Bank
