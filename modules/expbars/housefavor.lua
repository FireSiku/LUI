---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.ExperienceBars
local module = LUI:GetModule("Experience Bars")

local HouseFavorDataProvider = module:CreateBarDataProvider("HouseFavor")

HouseFavorDataProvider.BAR_EVENTS = {
	"HOUSE_LEVEL_FAVOR_UPDATED",
}

function HouseFavorDataProvider:ShouldBeVisible()
	return C_Housing.GetTrackedHouseGuid() ~= nil
end

function HouseFavorDataProvider:Update(event, houseLevelFavor)
	local trackedHouseGUID = C_Housing.GetTrackedHouseGuid()
	if not trackedHouseGUID then
		self.houseLevelFavor = nil
		self.barMin, self.barValue, self.barMax = 0, 0, 1
		return
	end

	if event == "HOUSE_LEVEL_FAVOR_UPDATED" and houseLevelFavor
		and houseLevelFavor.houseGUID == trackedHouseGUID then
		self.houseLevelFavor = houseLevelFavor
	elseif not self.houseLevelFavor or self.houseLevelFavor.houseGUID ~= trackedHouseGUID then
		self.houseLevelFavor = nil
		C_Housing.GetCurrentHouseLevelFavor(trackedHouseGUID)
	end

	local data = self.houseLevelFavor
	if not data then
		self.barMin, self.barValue, self.barMax = 0, 0, 1
		return
	end

	self.houseLevel = data.houseLevel
	if data.houseLevel >= C_Housing.GetMaxHouseLevel() then
		self.barMin, self.barValue, self.barMax = 0, 1, 1
		return
	end

	local threshold = C_Housing.GetHouseLevelFavorForLevel(data.houseLevel)
	local nextThreshold = C_Housing.GetHouseLevelFavorForLevel(data.houseLevel + 1)
	self.barMin = 0
	self.barValue = math.max(0, data.houseFavor - threshold)
	self.barMax = math.max(1, nextThreshold - threshold)
end

function HouseFavorDataProvider:GetDataText()
	return self.houseLevel and ("Favor " .. self.houseLevel) or "Favor"
end
