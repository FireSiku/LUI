-- Dualspec Infotext

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)
local L = LUI.L

---@class LUI.Infotext
local module = LUI:GetModule("Infotext")
local element = module:NewElement("Dualspec", "AceEvent-3.0")

-- local copies
local select, format = select, format
local strsplit = string.split
local GetSpecializationInfoByID = _G.GetSpecializationInfoByID
local GetLootSpecialization = _G.GetLootSpecialization
local GetNumSpecializations = _G.GetNumSpecializations
local GetSpecializationInfo = C_SpecializationInfo.GetSpecializationInfo
local GetSpecialization = C_SpecializationInfo.GetSpecialization
local IsSpecializationInfoInitialized = C_SpecializationInfo.IsInitialized
local SetSpecialization = C_SpecializationInfo.SetSpecialization

-- constants
local LOOT_SPECIALIZATION_DEFAULT = strsplit("(", _G.LOOT_SPECIALIZATION_DEFAULT):trim()
local SELECT_LOOT_SPECIALIZATION = _G.SELECT_LOOT_SPECIALIZATION
local LEVEL_UP_DUALSPEC = _G.LEVEL_UP_DUALSPEC
local MAX_SPECS = 0

-- locals
local specCache = {}
local inactiveCache = {}

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

function element:RefreshSpecInfo()
	MAX_SPECS = 0
	for i = #specCache, 1, -1 do
		specCache[i] = nil
	end

	if not IsSpecializationInfoInitialized() then
		return
	end

	MAX_SPECS = GetNumSpecializations()
	for i = 1, MAX_SPECS do
		local _, name = GetSpecializationInfo(i)
		specCache[i] = {name = name}
	end
end

function element:OnSpecializationChanged(event_, unit)
	if unit == "player" then
		element:UpdateSpec()
	end
end

function element:UpdateSpec()
	element:RefreshSpecInfo()

	local currentSpecID = GetSpecialization()
	local currentSpec = specCache[currentSpecID]
	local specName = (currentSpec) and currentSpec.name or L["InfoDualspec_NoSpec"]
	local lootSpecID = GetLootSpecialization()
	if module.db.profile.Dualspec.lootSpec and lootSpecID > 0 then
		local _, lootSpec = GetSpecializationInfoByID(lootSpecID)
		element.text = lootSpec and format("%s (%s)", specName, lootSpec) or specName
	else
		element.text = specName
	end

	inactiveCache = {}
	for i = 1, MAX_SPECS do
		if i ~= currentSpecID then -- not the active spec, put in inactive
			inactiveCache[#inactiveCache + 1] = i
		end
	end

	element:UpdateTooltip()
end

-- Left-Click: Switch to inactive spec 1
-- Right-Click: Switch to inactive spec 2
-- Middle-Click: Switch to inactive spec 3 (Druid only)
function element.OnClick(frame_, button)
	if button == "LeftButton" and inactiveCache[1] then
		SetSpecialization(inactiveCache[1])
	elseif button == "RightButton" and inactiveCache[2] then
		SetSpecialization(inactiveCache[2])
	elseif button == "MiddleButton" and inactiveCache[3] then
		SetSpecialization(inactiveCache[3])
	end
end

-- ####################################################################################################################
-- ##### Infotext Display #############################################################################################
-- ####################################################################################################################

function element.OnTooltipShow(GameTooltip)
	element:TooltipHeader(LEVEL_UP_DUALSPEC)
	element:RefreshSpecInfo()

	local activeSpec = GetSpecialization()
	local dualspecHint = ""

	for i = 1, MAX_SPECS do
		local specNum = format(L["InfoDualspec_Spec_Num"], i)
		local specName = specCache[i].name

		if i == activeSpec then
			local highlight = CreateColor(1, 1, 0)
			specNum = highlight:WrapTextInColorCode(specNum)
			specName = highlight:WrapTextInColorCode(specName)
		end
		GameTooltip:AddDoubleLine(specNum, specName, 1, 1, 1, 1, 1, 1)
	end

	GameTooltip:AddLine(" ")
	local lootSpecID = GetLootSpecialization()
	local lootSpec = lootSpecID > 0 and select(2, GetSpecializationInfoByID(lootSpecID)) or LOOT_SPECIALIZATION_DEFAULT
	GameTooltip:AddDoubleLine(format("%s:", SELECT_LOOT_SPECIALIZATION), lootSpec, 1, 1, 1, 1, 1, 1)

	for i = 1, #inactiveCache do
		dualspecHint = dualspecHint .. format(L[format("InfoDualspec_Hint_%d", i)], specCache[inactiveCache[i]].name)
		if i < #inactiveCache then dualspecHint = dualspecHint .. "\n" end
	end

	element:AddHint(dualspecHint)
end

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function element:OnCreate()
	element:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", "OnSpecializationChanged")
	element:RegisterEvent("PLAYER_LOOT_SPEC_UPDATED", "UpdateSpec")
	element:UpdateSpec()
end
