-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)
local L = LUI.L

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
	if LUI.IsRetail and db.ShowAzerite and C_AzeriteItem.HasActiveAzeriteItem() then
		local itemLocation = C_AzeriteItem.FindActiveAzeriteItem()

		-- Only show Azerite Bar when Heart is equipped
		return itemLocation:IsEquipmentSlot()
	end
end

function AzeriteDataProvider:Update()
	local itemLocation = C_AzeriteItem.FindActiveAzeriteItem()
	local currentXP, totalXP = C_AzeriteItem.GetAzeriteItemXPInfo(itemLocation)
	self.barValue = currentXP
	self.barMax = totalXP
end

function AzeriteDataProvider:GetDataText()
	local db = module.db.profile
	if db.ShowAbsolute then
		return format("AP (%s / %s)", self.barValue, self.barMax)
	end
	return "AP"
end
