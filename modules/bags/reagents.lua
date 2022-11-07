-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################
--luacheck: globals LUIReagent

local _, LUI = ...
local module = LUI:GetModule("Bags")

local format = format

-- Constants
local REAGENTS_SLOT_TEMPLATE = "ReagentBankItemButtonGenericTemplate"
local REAGENTS_SLOT_NAME_FORMAT = "LUIReagent_Item%d_%d"
local REAGENTS_DEPOSIT_SOUND = SOUNDKIT.IG_MAINMENU_OPTION
local REAGENTS_DEPOSIT_ICON = 413587 -- Mobile Banking Icon
--luacheck: globals REAGENTBANK_DEPOSIT REAGENTBANK_PURCHASE_TEXT REAGENT_BANK BANKSLOTPURCHASE

-- ####################################################################################################################
-- ##### Container Object #############################################################################################
-- ####################################################################################################################

local Reagent = {
	--Constants
	NUM_BAG_IDS = 1,
	BAG_ID_LIST = { -3, },

	-- vars
	name = "Reagent",
}

function Reagent:OnShow()
end

function Reagent:OnHide()
	CloseBankFrame()
end

function Reagent:Layout()
	self.utilBar:SetAnchors()

	if not IsReagentBankUnlocked() then
		if not self.unlockText then self:CreateUnlockInfo() end
		for i = 1, #LUIReagent.itemList[-3] do
			LUIReagent.itemList[-3][i]:Hide()
		end
	end
end

function Reagent:NewItemSlot(id, slot)

	if self.itemList[id] and self.itemList[id][slot] then
		return self.itemList[id][slot]
	end

	local name = format(REAGENTS_SLOT_NAME_FORMAT, id, slot)
	local template = REAGENTS_SLOT_TEMPLATE
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

function Reagent:CreateUtilBar()
	local utilBar = self.utilBar

	-- CleanUp
	local cleanUpButton = module:CreateCleanUpButton("LUIReagent_CleanUp", utilBar, SortReagentBankBags)
	utilBar:AddNewButton(cleanUpButton)

	-- Deposit
	local depositButton = module:CreateSlot("LUIReagent_Deposit", utilBar)
	depositButton:SetScript("OnClick", function()
			PlaySound(REAGENTS_DEPOSIT_SOUND)
            DepositReagentBank()
		end)
	depositButton.icon:SetTexture(REAGENTS_DEPOSIT_ICON)
	utilBar:SetButtonTooltip(depositButton, REAGENTBANK_DEPOSIT)
	utilBar:AddNewButton(depositButton)
end

--Clean this up, using LUIReagent global looks dirty.
function Reagent:BankSlotsUpdate()
	for i = 1, #LUIReagent.itemList[-3] do
		LUIReagent:SlotUpdate(LUIReagent.itemList[-3][i])
	end
end

function Reagent:CreateUnlockInfo()
	local text = self:CreateFontString("$parentText", "ARTWORK", "GameFontHighlightMedium")
	text:SetSize(512, 32)
	text:SetJustifyV("BOTTOM")
	text:SetPoint("BOTTOM", self, "CENTER", 0, -8)
	text:SetText(REAGENTBANK_PURCHASE_TEXT)
	text:Show()

	local title = self:CreateFontString("$parentTitle", "ARTWORK", "QuestFont_Enormous")
	title:SetSize(384, 0)
	title:SetJustifyV("BOTTOM")
	title:SetPoint("BOTTOM", text, "TOP", 0, 8)
	title:SetText(REAGENT_BANK)
	title:Show()

	local tabCost = self:CreateFontString("$parentTabCost", "ARTWORK", "GameFontNormalMed3")
	tabCost:SetSize(124, 21)
	tabCost:SetJustifyV("BOTTOM")
	tabCost:SetPoint("TOP", text, "BOTTOM", -50, -10)
	tabCost:SetText(COSTS_LABEL.." "..GetMoneyString(GetReagentBankCost()))
	tabCost:Show()

	local button = CreateFrame("Button", "parentPurchaseButton", self, "UIPanelButtonTemplate")
	button:SetSize(124, 21)
	button:SetText(BANKSLOTPURCHASE)
	button:SetPoint("LEFT", tabCost, "RIGHT", 10, 0)
	button:SetScript("OnClick", function()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION);
        StaticPopup_Show("CONFIRM_BUY_REAGENTBANK_TAB");
	end)
	button:Show()

	self.unlockText = text
	self.unlockTitle = title
	self.unlockTabCost = tabCost
	self.unlockButton = button
end

module.BankReagentContainer = Reagent
