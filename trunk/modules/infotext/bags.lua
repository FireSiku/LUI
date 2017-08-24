--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: infotexts\bags.lua
	Description: Creates the bag infotext stat.
]]


-- External references.
local addonname, LUI = ...
local InfoText = LUI:Module("InfoText")

-- Register stat.
local Bags = InfoText:NewStat("Bags")

function Bags:OnCreate()
	-- Check if stat is not enabled or is already created.
	if not self.db.profile.Enable then return end

	-- Local shortcuts.
	local stat = self.stat

	-- Localized functions.
	local format, GetContainerNumFreeSlots, GetContainerNumSlots = string.format, GetContainerNumFreeSlots, GetContainerNumSlots
	
	-- Variables.
	local BagTypes = {
		[0] = "Normal",
		[1] = "Quiver",
		[2] = "Ammo Pouch",
		[4] = "Soul Bag",
		[8] = "Leatherworking Bag",
		[16] = "Inscription Bag",
		[32] = "Herb Bag",
		[64] = "Enchanting Bag",
		[128] = "Engineering Bag",
		[256] = "Keyring",
		[512] = "Gem Bag",
		[1024] = "Mining Bag",
		[2048] = "Unknown",
		[4096] = "Vanity Pets",
	}
		
	-- Declare stat's events for registration.
	stat.Events = { "BAG_UPDATE" }

	-- Event functions.
	function stat:BAG_UPDATE(bagID)
		local free, total, used = 0, 0, 0

		for i = 0, NUM_BAG_SLOTS do
			free, total = free + GetContainerNumFreeSlots(i), total + GetContainerNumSlots(i)
		end

		used = total - free
		self:Text(format("Bags: %d/%d", used, total))
	end

	-- Script functions.
	function stat:OnClick()
		-- Debate: ToggleAllBags() vs. OpenAllBags().
		ToggleAllBags()
	end

	stat.OnEnable = stat.BAG_UPDATE

	function stat:OnTooltipShow()
		-- Embeded functionality: self = GameToolTip

		local freeslots, totalslots = {}, {}
		for i=0, NUM_BAG_SLOTS do
			local free, bagType = GetContainerNumFreeSlots(i)
			local total = GetContainerNumSlots(i)
			freeslots[bagType] = (freeslots[bagType] ~= nil and freeslots[bagType] + free or free)
			totalslots[bagType] = (totalslots[bagType] ~= nil and totalslots[bagType] + total or total)
		end
				
		for k, v in pairs(freeslots) do
			self:AddDoubleLine(BagTypes[k]..":", totalslots[k]-v.."/"..totalslots[k], 1, 1, 1, 1, 1, 1)
		end
		self:AddLine(" ")
				
		self:AddLine("Hint: Click to open Bags.", 0.0, 1.0, 0.0)
		self:Show()
	end
end

-- Create defaults.
Bags.defaults = {
	profile = {
		Enable = true,
		InfoPanel = {
			InfoPanel = "TopLeft",
			X = 200,
			Y = 0,
		},
	}
}
