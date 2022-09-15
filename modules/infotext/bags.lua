-- FPS/Latency Infotext

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

local _, LUI = ...
local module = LUI:GetModule("Infotext")
local element = module:NewElement("Bags", "AceEvent-3.0")
local L = LUI.L

--local copies
local wipe, format, pairs = wipe, format, pairs
local GetContainerNumFreeSlots = GetContainerNumFreeSlots
local GetContainerNumSlots = GetContainerNumSlots

-- Constants
local NUM_BAG_SLOTS = NUM_BAG_SLOTS
local BAG_TYPES = { -- List of bagType Bitfields
	[0x0000] = L["BagType_Normal"],            -- 0
	[0x0001] = L["BagType_Quiver"],            -- 1
	[0x0002] = L["BagType_AmmoPouch"],         -- 2
	[0x0004] = L["BagType_SoulBag"],           -- 4
	[0x0008] = L["BagType_LeatherworkingBag"], -- 8
	[0x0010] = L["BagType_InscriptionBag"],    -- 16
	[0x0020] = L["BagType_HerbBag"],           -- 32
	[0x0040] = L["BagType_EnchantingBag"],     -- 64
	[0x0080] = L["BagType_EngineeringBag"],    -- 128
	[0x0100] = L["BagType_Keyring"],           -- 256
	[0x0200] = L["BagType_GemBag"],            -- 512
	[0x0400] = L["BagType_MiningBag"],         -- 1024
 -- [0x0800] = "Unused",                       -- 2048
	[0x1000] = L["BagType_VanityPets"],        -- 4096
 -- [0x2000] = "Unused",                       -- 8192
 -- [0x4000] = "Unused",                       -- 16384
	[0x8000] = L["BagType_TackleBox"],         -- 32768
    [0x10000] = L["BagType_CookingBag"],       -- 65536
}

--Local variables
local freeSlots = {}
local totalSlots = {}


-- ####################################################################################################################
-- ##### Default Settings #############################################################################################
-- ####################################################################################################################

element.defaults = {
	profile = {
		X = 150,
	},
}
module:MergeDefaults(element.defaults, "Bags")

-- ####################################################################################################################
-- ##### Module Refresh ###############################################################################################
-- ####################################################################################################################

function element:UpdateBags()
	local free, total = 0, 0
	for i = 0, NUM_BAG_SLOTS do
		free = free + GetContainerNumFreeSlots(i)
		total = total + GetContainerNumSlots(i)
	end
	element.text = format(L["InfoBags_Text_Format"], total - free, total)
	element:UpdateTooltip()
end

function element.OnClick(frame_, button_)
	ToggleAllBags()
end

-- ####################################################################################################################
-- ##### Infotext Display #############################################################################################
-- ####################################################################################################################

function element.OnTooltipShow(GameTooltip)
	element:TooltipHeader(L["InfoBags_Header"])
	wipe(freeSlots)
	wipe(totalSlots)
	for i=0, NUM_BAG_SLOTS do
		local free, bagType = GetContainerNumFreeSlots(i)
		local total = GetContainerNumSlots(i)
		if bagType then
			freeSlots[bagType] = (freeSlots[bagType] and freeSlots[bagType] + free) or free
			totalSlots[bagType] = (totalSlots[bagType] and totalSlots[bagType] + total) or total
		end
	end

	for k, free in pairs(freeSlots) do
		GameTooltip:AddDoubleLine(format("%s:", BAG_TYPES[k] or L["InfoBags_BagType_Unknown"]),
								  format("%d / %d", totalSlots[k]-free, totalSlots[k]),
								  1, 1, 1, 1, 1, 1) --AddDoubleLine requires color definitions at the end.
	end

	element:AddHint(L["InfoBags_Hint_Any"])
end

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function element:OnCreate()
	element:RegisterEvent("BAG_UPDATE", "UpdateBags")
	element:UpdateBags()
end
