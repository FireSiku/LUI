--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: infotexts\bags.lua
	Description: Creates the bag infotext stat.
	Version....: 1.0
	Rev Date...: 05/08/2011 [dd/mm/yyyy]
]]


-- External references.
local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local InfoText = LUI:GetModule("InfoText", true)
if not InfoText then return end

-- Register stat.
local Bags = InfoText:NewStat("Bags")

-- Database and defaults shortcuts.
local db, dbd

function Bags:OnCreate()
	-- Check if stat is not enabled or is already created.
	if (not self.db[self.name].Enable) or self.Created then return end

	-- Local shortcuts.
	local stat = self.stat

	-- Localized functions.
	local GetContainerNumFreeSlots, GetContainerNumSlots = GetContainerNumFreeSlots, GetContainerNumSlots
	
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
		self.text:SetText("Bags:"..used.."/"..total)

		-- Update tooltip if open.
		self:UpdateTooltip()
	end

	-- Script functions.
	function stat:OnClick()
		-- Debate: ToggleAllBags() vs. OpenAllBags().
		ToggleAllBags()
	end

	stat.OnEnable = stat.BAG_UPDATE

	function stat:OnEnter()
		-- Check tooltip creation is allowed.
		if not InfoText:TooltipAvailable() then return end

		local freeslots, totalslots = {}, {}
		for i=0, NUM_BAG_SLOTS do
			local free, bagType = GetContainerNumFreeSlots(i)
			local total = GetContainerNumSlots(i)
			freeslots[bagType] = (freeslots[bagType] ~= nil and freeslots[bagType] + free or free)
			totalslots[bagType] = (totalslots[bagType] ~= nil and totalslots[bagType] + total or total)
		end
				
		GameTooltip:SetOwner(self, getOwnerAnchor(self))
		GameTooltip:ClearLines()
		GameTooltip:AddLine("Bags:", 0.4, 0.78, 1)
		GameTooltip:AddLine(" ")
				
		for k, v in pairs(freeslots) do
			GameTooltip:AddDoubleLine(BagTypes[k]..":", totalslots[k]-v.."/"..totalslots[k], 1, 1, 1, 1, 1, 1)
		end
		GameTooltip:AddLine(" ")
				
		GameTooltip:AddLine("Hint: Click to open Bags.", 0.0, 1.0, 0.0)
		GameTooltip:Show()
	end

	self.Created = true
end

-- Create defaults.
Bags.defaults = {
	Enable = true,
	X = 200,
	Y = 0,
	InfoPanel = "TopLeft",
	Font = "vibroceb",
	FontSize = 12,
	Outline = "NONE",
	Color = {
		r = 1,
		g = 1,
		b = 1,
		a = 1,
	},
}

function Bags:OnInitialise(_db, _dbd)
	-- Create database references.
	self.db, self.defaults = _db, _dbd
	db, dbd = _db, _dbd
end