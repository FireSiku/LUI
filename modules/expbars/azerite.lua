-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.ExperienceBars
local module = LUI:GetModule("Experience Bars")

local C_AzeriteItem = C_AzeriteItem

-- ####################################################################################################################
-- ##### AzeriteDataProvider ##########################################################################################
-- ####################################################################################################################

local AzeriteDataProvider = module:CreateBarDataProvider("Azerite")

AzeriteDataProvider.BAR_EVENTS = {
	"AZERITE_ITEM_EXPERIENCE_CHANGED",
	"AZERITE_EMPOWERED_ITEM_EQUIPPED_STATUS_CHANGED"
}

function AzeriteDataProvider:ShouldBeVisible()
	local db = module.db.profile
	if db.ShowAzerite and C_AzeriteItem.HasActiveAzeriteItem() and not C_AzeriteItem.IsAzeriteItemAtMaxLevel() then
		local itemLocation = C_AzeriteItem.FindActiveAzeriteItem()

		return itemLocation and itemLocation:IsEquipmentSlot() and C_AzeriteItem.IsAzeriteItemEnabled(itemLocation)
	end
end

function AzeriteDataProvider:Update()
	local itemLocation = C_AzeriteItem.FindActiveAzeriteItem()
	local currentXP, totalXP = C_AzeriteItem.GetAzeriteItemXPInfo(itemLocation)
	self.barValue = currentXP
	self.barMax = totalXP
end

function AzeriteDataProvider:GetDataText()
	return "AP"
end
