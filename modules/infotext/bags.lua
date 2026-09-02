-- Bag Space Infotext

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)
local L = LUI.L

---@class InfotextModule
local module = LUI:GetModule("Infotext")
local element = module:NewElement("Bags", "AceEvent-3.0")

local format = format
local C_Container = _G.C_Container

-- Constants
local NUM_BAG_SLOTS = _G.NUM_BAG_SLOTS
local LAST_BAG = Enum.BagIndex.ReagentBag or NUM_BAG_SLOTS
-- ####################################################################################################################
-- ##### Module Refresh ###############################################################################################
-- ####################################################################################################################

function element:UpdateBags()
	local free, total = 0, 0
	for i = 0, LAST_BAG do
		free = free + (C_Container.GetContainerNumFreeSlots(i) or 0)
		total = total + C_Container.GetContainerNumSlots(i)
	end
	element.text = format(L["InfoBags_Text_Format"], total - free, total)
	element:UpdateTooltip()
end

function element.OnClick(frame_, button_)
	_G.ToggleAllBags()
end

-- ####################################################################################################################
-- ##### Infotext Display #############################################################################################
-- ####################################################################################################################

function element.OnTooltipShow(GameTooltip)
	element:TooltipHeader(L["InfoBags_Header"])
	for i = 0, LAST_BAG do
		local free = C_Container.GetContainerNumFreeSlots(i) or 0
		local total = C_Container.GetContainerNumSlots(i) or 0
		if total > 0 then
			local name = C_Container.GetBagName(i)
			if not name then
				name = i == Enum.BagIndex.Backpack and _G.BACKPACK_TOOLTIP or format("Bag %d", i)
			end
			GameTooltip:AddDoubleLine(format("%s:", name), format("%d / %d", total - free, total), 1, 1, 1, 1, 1, 1)
		end
	end

	element:AddHint(L["InfoBags_Hint_Any"])
end

element.RefreshSettings = element.UpdateBags

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function element:OnCreate()
	element:RegisterEvent("BAG_UPDATE", "UpdateBags")
	element:UpdateBags()
end
