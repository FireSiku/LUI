-- Memory Infotext

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

local _, LUI = ...
local module = LUI:GetModule("Infotext")
local element = module:NewElement("Memory")
local L = LUI.L

local format = format
local collectgarbage = collectgarbage
local GetNumAddOns, GetAddOnInfo = GetNumAddOns, GetAddOnInfo
local UpdateAddOnMemoryUsage = UpdateAddOnMemoryUsage
local GetAddOnMemoryUsage = GetAddOnMemoryUsage
local IsAddOnLoaded = IsAddOnLoaded

local totalMemory = 0
local addonMemory = {} --contains addonTitle, memoryUsage
local sortedAddons = {} -- Sorting table for addonMemory

-- Everything is too green without this multiplier
local GRADIENT_MULTIPLIER = 1.4
local MEMORY_UPDATE_TIME = 20
local KB_PER_MB = 1024

-- ####################################################################################################################
-- ##### Default Settings #############################################################################################
-- ####################################################################################################################

element.defaults = {
	profile = {
		X = 600,
	},
}
module:MergeDefaults(element.defaults, "Memory")

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

local function addonSort(a, b)
	return addonMemory[a] > addonMemory[b]
end

local function formatMemory(kb)
	if kb > KB_PER_MB then
		return format("%.2fmb", kb / KB_PER_MB)
	else
		return format("%.1fkb", kb)
	end
end

function element:UpdateMemory()
	UpdateAddOnMemoryUsage()
	totalMemory = 0

	for i = 1, GetNumAddOns() do
		local _, addonTitle = GetAddOnInfo(i)
		if IsAddOnLoaded(i) then
			addonMemory[addonTitle] = GetAddOnMemoryUsage(i)
			totalMemory = totalMemory + addonMemory[addonTitle]
		else
			addonMemory[addonTitle] = nil
		end
	end

	--sort table
	LUI:SortTable(sortedAddons, addonMemory, addonSort)
	element.text = format("%.1fmb", totalMemory / KB_PER_MB)

	element:UpdateTooltip()
end

function element.OnClick(frame_, button_)
	collectgarbage("collect")
	element:UpdateMemory()
end

-- ####################################################################################################################
-- ##### Infotext Display #############################################################################################
-- ####################################################################################################################

function element.OnTooltipShow(GameTooltip)
	element:TooltipHeader(L["InfoMemory_Header"])
	for i = 1, #sortedAddons do
		local addonTitle = sortedAddons[i]
		local r, g, b = LUI:InverseGradient((addonMemory[addonTitle] / totalMemory) * GRADIENT_MULTIPLIER)
		GameTooltip:AddDoubleLine(addonTitle, formatMemory(addonMemory[addonTitle]), 1,1,1, r, g, b)
	end

	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine(L["InfoMemory_TotalMemory"], formatMemory(totalMemory), 1,1,1, .8,.8,.8)

	element:AddHint(L["InfoMemory_Hint_Any"])
end

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function element:OnCreate()
	element:UpdateMemory()
	element:AddUpdate("UpdateMemory", MEMORY_UPDATE_TIME)
end
