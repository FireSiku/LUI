-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

local _, LUI = ...
local module = LUI:GetModule("Experience Bars")
local L = LUI.L

local IsWatchingHonorAsXP = _G.IsWatchingHonorAsXP
local IsInActiveWorldPVP = _G.IsInActiveWorldPVP
local UnitHonorMax = _G.UnitHonorMax
local UnitHonor = _G.UnitHonor

-- ####################################################################################################################
-- ##### HonorDataProvider ###############################################################################################
-- ####################################################################################################################

local HonorDataProvider = module:CreateBarDataProvider("Honor")

HonorDataProvider.BAR_EVENTS = {
	"HONOR_XP_UPDATE",
	"CVAR_UPDATE",
	"ZONE_CHANGED",
	"ZONE_CHANGED_NEW_AREA",
}

function HonorDataProvider:ShouldBeVisible()
	return LUI.IsRetail and (IsWatchingHonorAsXP() or C_PvP.IsActiveBattlefield() or IsInActiveWorldPVP())
end

function HonorDataProvider:Update()
	local honorCurrent = UnitHonor("player")
	local honorMax = UnitHonorMax("player")

	self.barValue = honorCurrent
	self.barMax = honorMax
end

function HonorDataProvider:GetDataText()
	return "Honor"
end