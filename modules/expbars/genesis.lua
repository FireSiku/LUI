-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, LUIAddon
local _, LUI = ...
local L = LUI.L

---@type ExpBarModule
local module = LUI:GetModule("Experience Bars")

local GENESIS_MOTE_ID = 188957
local GENESIS_STACK_SIZE = 5000
local GENESIS_MOTE_MAX = 18550

-- ####################################################################################################################
-- ##### GenesisDataProvider ##########################################################################################
-- ####################################################################################################################
-- Provider tracking Genesis Motes required to complete the Protoform Synthesis in Zereth Mortis

local GenesisDataProvider = module:CreateBarDataProvider("Genesis")

GenesisDataProvider.BAR_EVENTS = {
	"BAG_UPDATE_DELAYED",
	"ZONE_CHANGED",
}

function GenesisDataProvider:ShouldBeVisible()
	local db = module.db.profile
	return LUI.IsRetail and db.ShowGensis and (C_Map.GetBestMapForUnit("player") == 1970)
end

function GenesisDataProvider:ShouldDisplayPercentText()
	return false
end

function GenesisDataProvider:UpdateMoteLocations()
	self.moteLocations = {}
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local itemID = select(10, GetContainerItemInfo(bag, slot))
			if itemID == GENESIS_MOTE_ID then
				tinsert(self.moteLocations, ItemLocation:CreateFromBagAndSlot(bag, slot))
			end
		end
	end
end

function GenesisDataProvider:Update()
	if not self.moteLocations then
		self:UpdateMoteLocations()
	end

	local motes = 0
	for i = 1, #self.moteLocations do
		motes = motes + C_Item.GetStackCount(self.moteLocations[i])
	end
	--- CHeck if we need to recheck for new mote stacks and recheck count
	if math.fmod(motes, GENESIS_STACK_SIZE) == 0 then
		self:UpdateMoteLocations()
		motes = 0
		for i = 1, #self.moteLocations do
			motes = motes + C_Item.GetStackCount(self.moteLocations[i])
		end
	end

	self.barValue = motes
	self.barMax = GENESIS_MOTE_MAX
end

function GenesisDataProvider:GetDataText()
	return format("%s Motes", self.barValue)
end
