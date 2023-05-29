-- Durability Infotext

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)
local L = LUI.L

---@class LUI.Infotext
local module = LUI:GetModule("Infotext")
local element = module:NewElement("Durability", "AceEvent-3.0")

-- Local copies
local floor, format, pairs = floor, format, pairs
local GetInventoryItemDurability = _G.GetInventoryItemDurability
local ToggleCharacter = _G.ToggleCharacter

-- Constants
local ARMOR = _G.ARMOR

-- Local variables
local itemDurability = {} --Holds the changing information based on slot.
local sortedItems = {} -- Sorting table for itemDurability

-- Contains Constant Information about equipment.
local EQUIP_SLOTS = {
	[(_G.INVTYPE_HEAD)] = 1,
	[(_G.INVTYPE_SHOULDER)] = 3,
	[(_G.INVTYPE_CHEST)] = 5,
	[(_G.INVTYPE_WAIST)] = 6,
	[(_G.INVTYPE_LEGS)] = 7,
	[(_G.INVTYPE_FEET)] = 8,
	[(_G.INVTYPE_WRIST)] = 9,
	[(_G.INVTYPE_HAND)] = 10,
	[(_G.INVTYPE_WEAPONMAINHAND)] = 16,
	[(_G.INVTYPE_WEAPONOFFHAND)] = 17,
}

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

--Sort by Durability, if equal, sort by slot ID
local function itemSort(a, b)
	if itemDurability[a] == itemDurability[b] then
		return EQUIP_SLOTS[b] > EQUIP_SLOTS[a]
	else
		return itemDurability[b] > itemDurability[a]
	end
end

function element:UpdateDurability()
	for localName, equipID in pairs(EQUIP_SLOTS) do
		local currentDur, maxDur = GetInventoryItemDurability(equipID)
		itemDurability[localName] = currentDur and currentDur / maxDur or nil
	end

	-- The first entry of the sorted table is the lowest value.
	LUI:SortTable(sortedItems, itemDurability, itemSort)
	local displayDur = (LUI:Count(itemDurability) > 0) and itemDurability[sortedItems[1]] * 100 or nil
	element.text = format(L["InfoArmor_Display_Format"], displayDur or 100)
	element:UpdateTooltip()
end

function element.OnClick(frame_, button_)
	--TODO: Add feature to summon mammoth with Right-Click
	ToggleCharacter("PaperDollFrame")
end

-- ####################################################################################################################
-- ##### Infotext Display #############################################################################################
-- ####################################################################################################################

function element.OnTooltipShow(GameTooltip)
	element:TooltipHeader(ARMOR)
	for i = 1, #sortedItems do
		local value = itemDurability[sortedItems[i]]
		local r, g, b = LUI:RGBGradient(value)
		GameTooltip:AddDoubleLine(sortedItems[i], floor(value * 100).."%", 1, 1, 1, r, g, b)
	end

	element:AddHint(L["InfoArmor_Hint_Any"])
end

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function element:OnCreate()
	element:RegisterEvent("UPDATE_INVENTORY_DURABILITY", "UpdateDurability")
	element:UpdateDurability()
end
