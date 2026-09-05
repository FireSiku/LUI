-- Memory Infotext

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)
local L = LUI.L

---@class LUI.Infotext
local module = LUI:GetModule("Infotext")
local element = module:NewElement("Memory")

local format = format
local collectgarbage = collectgarbage
local UpdateAddOnMemoryUsage = _G.UpdateAddOnMemoryUsage
local GetAddOnMemoryUsage = _G.GetAddOnMemoryUsage
local GetNumAddOns = C_AddOns.GetNumAddOns
local GetAddOnInfo = C_AddOns.GetAddOnInfo
local C_Timer = C_Timer

local totalMemory = 0
local addonMemory = {} --contains addonTitle, memoryUsage
local sortedAddons = {} -- Sorting table for addonMemory

-- Everything is too green without this multiplier
local GRADIENT_MULTIPLIER = 1.4
local MEMORY_UPDATE_TIME = 20
local USAGE_UPDATE_TIME = 600
local KB_PER_MB = 1024

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
	totalMemory = 0

	for i = 1, GetNumAddOns() do
		local addonName, addonTitle = GetAddOnInfo(i)
		addonTitle = addonTitle or addonName
		if C_AddOns.IsAddOnLoaded(i) then
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

function element.OnClick(frame, button)
	collectgarbage("collect")
	C_Timer.After(0, function()
		if button == "RightButton" then
			UpdateAddOnMemoryUsage()
			return C_Timer.After(0, function() element:UpdateMemory() end)
		end
		element:UpdateMemory()
	end)
end

-- ####################################################################################################################
-- ##### Infotext Display #############################################################################################
-- ####################################################################################################################

function element.OnTooltipShow(GameTooltip)
	element:TooltipHeader(L["InfoMemory_Header"])
	for i = 1, #sortedAddons do
		local addonTitle = sortedAddons[i]
		local ratio = totalMemory > 0 and addonMemory[addonTitle] / totalMemory or 0
		local r, g, b = LUI:InverseGradient(ratio * GRADIENT_MULTIPLIER)
		GameTooltip:AddDoubleLine(addonTitle, formatMemory(addonMemory[addonTitle]), 1,1,1, r, g, b)
	end

	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine(L["InfoMemory_TotalMemory"], formatMemory(totalMemory), 1,1,1, .8,.8,.8)

	element:AddHint(L["InfoMemory_Hint_Any"])
end

element.RefreshSettings = element.UpdateMemory

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function element:OnCreate()
	local usageElapsed = 0
	element:AddUpdate(function()
		usageElapsed = usageElapsed + MEMORY_UPDATE_TIME
		if usageElapsed >= USAGE_UPDATE_TIME and not _G.InCombatLockdown() then
			UpdateAddOnMemoryUsage()
			usageElapsed = 0
			return C_Timer.After(0, function() element:UpdateMemory() end)
		end
		element:UpdateMemory()
	end, MEMORY_UPDATE_TIME)

	-- This ensures that all addons are loaded at the time of updating memory usage.
	C_Timer.After(1, function()
		UpdateAddOnMemoryUsage()
		C_Timer.After(0, function() element:UpdateMemory() end)
	end)
end
