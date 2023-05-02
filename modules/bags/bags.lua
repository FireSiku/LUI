--[[ File: Bags\Bags.lua, contains core of bags module.

This file contains the basic of the Bags module, and the Container prototype, that will be used to make bag frames.
Keep as geneneric as possible to allow possible expansions. (Guild Bank, Void Storage), code specific to a container should be in their own files.

Container Members:
- type - Type of container, ie: Bags, Bank
- name - Frame name for the container
- idList - Table containing a list of Bag ID for the container
- numID - The number of Bag ID for the container. Since the idList is a hash, we cant use #idList
- itemList - Contains the individual frames for the item slots, separated by ID.
- bagsBarList- Contains the individual frames for the BagsBar
- bagList - Contains the individual parent frames for the IDs.
--]]
-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, LUIAddon
local _, LUI = ...
local L = LUI.L

---@class BagsModule
local module = LUI:GetModule("Bags")
local Media = LibStub("LibSharedMedia-3.0")

-- Locals and Constants
local format, pairs = format, pairs
local C_Container = C_Container
local RoundToSignificantDigits = _G.RoundToSignificantDigits
local SetItemButtonDesaturated = _G.SetItemButtonDesaturated
local ClearItemButtonOverlay = _G.ClearItemButtonOverlay
local SetItemButtonOverlay = _G.SetItemButtonOverlay
local SetItemButtonTexture = _G.SetItemButtonTexture
local GetItemQualityColor = _G.GetItemQualityColor
local SetItemButtonCount = _G.SetItemButtonCount
local GetItemInfo = _G.GetItemInfo

local TEXTURE_ITEM_QUEST_BORDER = _G.TEXTURE_ITEM_QUEST_BORDER
local NEW_ITEM_ATLAS_BY_QUALITY = _G.NEW_ITEM_ATLAS_BY_QUALITY
local TEXTURE_ITEM_QUEST_BANG = _G.TEXTURE_ITEM_QUEST_BANG
local SEARCH = _G.SEARCH

-- Constants
local BUTTON_SLOT_TEMPLATE = "ContainerFrameItemButtonTemplate"
local BAG_UPDATE_TIME = 0.05
local BAG_TEXTURE_SIZE = 36
local LAYOUT_OFFSET = 26

local ITEMSLOT_NORMAL_ALPHA = 1
local ITEMSLOT_FILTER_ALPHA = .2
local BACKGROUND_MULTIPLIER = 0.4

-- Local variables
local containerStorage = {}

-- ####################################################################################################################
-- ##### Container Mixin ##############################################################################################
-- ####################################################################################################################

---@class ContainerMixin
local ContainerMixin = {}

function ContainerMixin:Open()
	self:Show()
end

function ContainerMixin:Close()
	self:Hide()
end

function ContainerMixin:Toggle()
	if self:IsShown() then
		self:Hide()
	else
		self:Show()
	end
end

function ContainerMixin:StartMovingFrame()
	if not self.db.Lock then
		self:StartMoving()
	end
end

function ContainerMixin:StopMovingFrame()
	self:StopMovingOrSizing()
	local x, y = self:GetCenter()
	self.db.X = RoundToSignificantDigits(x, 2)
	self.db.Y = RoundToSignificantDigits(y, 2)
end

function ContainerMixin:OnShow()
	self.updateBucket = self:RegisterBucketEvent("BAG_UPDATE", BAG_UPDATE_TIME, "BagUpdateEvent")
	module:RegisterEvent("ITEM_LOCK_CHANGED", function(...) self:ItemLockUpdate(...) end)
	self:Layout()
end

function ContainerMixin:OnHide()
	self:UnregisterBucket(self.updateBucket)
	module:UnregisterEvent("ITEM_LOCK_CHANGED")
	if self.editbox and not self.searchText:IsShown() then
		self:ShowTitleBar()
		self.editbox:Hide()
		self.clear:Hide()
		self.editbox:ClearFocus()
		self:SearchReset()
	end
end

function ContainerMixin:ShowTitleBar()
	self.searchText:Show()
end

function ContainerMixin:HideTitleBar()
	self.searchText:Hide()
end

-- Function to get a DB option value, will fetch from generic, unless frame-specific settings is enabled
function ContainerMixin:GetOption(name)
	--TODO: Add support for frame-specific settings
	return self.db[name]
end

function ContainerMixin:IsValidID(id)
	return tContains(self.BAG_ID_LIST, id) and true or false
end

function ContainerMixin:Layout()
	for i = 1, self.NUM_BAG_IDS do
		local id = self.BAG_ID_LIST[i]
		local itemList = self.itemList[id]
		--get a new bagCount in case bags changed.
		local bagCount = C_Container.GetContainerNumSlots(id)
		if bagCount > 0 then
			self.bagList[id]:Show()
			for j = 1, bagCount do
				-- The item slots will be anchored later on.
				itemList[j] = self:NewItemSlot(id, j)
				self:SlotUpdate(itemList[j])
				itemList[j]:Show()
			end
		end

		--If there are more itemSlots than bagCount, hide them.
		--This way, we can reuse frames, instead of creating new ones
		for j = bagCount + 1, #itemList do
			if itemList[j] then
				itemList[j]:Hide()
			end
		end
	end

	self:SetAnchors()

	-- Update Search Results if searching
	if self.editbox:IsShown() then
		self:SearchUpdate()
	end
end

function ContainerMixin:SetBagsProperties()
	--local bagsBar = self.BagsBar

	-- Set Position
	self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", self.db.X or 0, self.db.Y or 0)

	self.forceRefresh = true
	module:Refresh()

	-- TODO: Integrate SetBagFonts into this
end

function ContainerMixin:NewBagInfo(id)
	-- If the ID has already been created, return it
	if self.bagList[id] then return self.bagList[id] end

	--Create the frame
	local bagFrame = CreateFrame("Frame", self:GetName()..id, self)
	bagFrame:SetID(id)

	return bagFrame
end

-- Due to using Blizzard's template itemSlots which contains differences in names and format,
-- This should be handled by containers personally [using :NewItemSlot(id, slot)]
-- The containers should then call self:SetItemSlotProperties for post-creation shared code.
function ContainerMixin:SetItemSlotProperties(itemSlot)
	--Make it easy to fetch Cooldown information
	itemSlot.cooldown = _G[itemSlot:GetName() .. "Cooldown"]
	itemSlot.cooldown:Show()

	--Update backdrop
	itemSlot:SetBackdrop(module.itemBackdrop)
	itemSlot:SetBackdropColor(module:RGBA("ItemBackground"))
end

-- ####################################################################################################################
-- ##### Container: Slot Update #######################################################################################
-- ####################################################################################################################

--- Base function for updating items.
---@param itemSlot ItemButton
function ContainerMixin:SlotUpdate(itemSlot)
	local id, slot = itemSlot.id, itemSlot.slot
	local data = C_Container.GetContainerItemInfo(id, slot)

	-- Default Border when items are locked.
	if not itemSlot.lock then
		itemSlot:SetBackdropBorderColor(module:RGBA("Border"))
		-- Check for Profession Bag
		if module:IsProfessionBag(id) then
			itemSlot:SetBackdropBorderColor(module:RGBA("Professions"))
		end
	end

	-- Add the cooldown to our item slots.
	if itemSlot.cooldown then
		local start, duration, enable = C_Container.GetContainerItemCooldown(id, slot)
		_G.CooldownFrame_Set(itemSlot.cooldown, start, duration, enable)
	end
	-- New item code from Blizzard's ContainerFrame.lua
	local newItemTexture = itemSlot.NewItemTexture
	local battlePayTexture = itemSlot.BattlepayItemTexture
	local flashAnim = itemSlot.flashAnim
	local newItemAnim = itemSlot.newitemglowAnim
	-- Not all item slots have a newItemTexture
	if newItemTexture then
		if self:GetOption("ShowNew") and C_NewItems.IsNewItem(id, slot) then
			if C_Container.IsBattlePayItem(id, slot) then
				newItemTexture:Hide()
				battlePayTexture:Show()
			else
				if data.quality and NEW_ITEM_ATLAS_BY_QUALITY[data.quality] then
					newItemTexture:SetAtlas(NEW_ITEM_ATLAS_BY_QUALITY[data.quality])
				else
					newItemTexture:SetAtlas("bags-glow-white")
				end
				newItemTexture:Show()
				battlePayTexture:Hide()
			end
			if not flashAnim:IsPlaying() and not newItemAnim:IsPlaying() then
				flashAnim:Play()
				newItemAnim:Play()
			end
		else
			-- If the item is not new, hide all related textures
			newItemTexture:Hide()
			battlePayTexture:Hide()
			if flashAnim:IsPlaying() or newItemAnim:IsPlaying() then
				flashAnim:Stop()
				newItemAnim:Stop()
			end
		end
		--Make sure that the textures are the same size as the itemframe.
		battlePayTexture:SetSize(itemSlot:GetSize())
		newItemTexture:SetSize(itemSlot:GetSize())
	end

	-- Quest Item code from Blizzard's ContainerFrame.lua
	local questTexture = _G[itemSlot:GetName().."IconQuestTexture"]
	if questTexture then
		questTexture:SetSize(itemSlot:GetSize())
		--local isQuestItem, questId, isActive = C_Container.GetContainerItemQuestInfo(id, slot)
		local questInfo = C_Container.GetContainerItemQuestInfo(id, slot)
		if questInfo.questID and not questInfo.isActive and self:GetOption("ShowQuest") then
			questTexture:SetTexture(TEXTURE_ITEM_QUEST_BANG)
			questTexture:Show()
		elseif (questInfo.questID or questInfo.isQuestItem) and self:GetOption("ShowQuest") then
			questTexture:SetTexture(TEXTURE_ITEM_QUEST_BORDER)
			questTexture:Show()
		else
			questTexture:Hide()
		end
	end

	-- Make sure to not keep name/quality info from previous item
	itemSlot.name = nil
	itemSlot.quality = nil
	itemSlot.level = nil

	-- Color Border according to quality
	local itemLink = C_Container.GetContainerItemLink(id, slot)
	if itemLink then
		-- Do not use earlier quality var, GetContainerInfo returns inacurate information for unusable items.
		-- Store the name and quality for easy searching and border coloring.
		local name, _, itemQuality = GetItemInfo(itemLink)
		itemSlot.name = name
		itemSlot.quality = itemQuality
		if self.db.ItemLevel and C_Item.GetItemInventoryTypeByID(itemLink) > 1 then
			itemSlot.level = GetDetailedItemLevelInfo(itemLink)
		end

		self:SetItemSlotBorderColor(itemSlot)
		
	end
	
	if data then
		SetItemButtonTexture(itemSlot, data.iconFileID)
		SetItemButtonCount(itemSlot, itemSlot.level or data.stackCount)
		SetItemButtonDesaturated(itemSlot, data.isLocked, 0.5, 0.5, 0.5)

		if LUI.IsRetail and self.db.ShowOverlay and itemLink then
			SetItemButtonOverlay(itemSlot, itemLink, data.quality, data.isBound)
		else
			ClearItemButtonOverlay(itemSlot)
		end
	else
		itemSlot:Reset()
	end

	itemSlot:Show()
end

function ContainerMixin:SetItemSlotBorderColor(itemSlot)
	if self:GetOption("ItemQuality") and itemSlot.quality and itemSlot.quality > 1 and not itemSlot.lock then
		local r, g, b = GetItemQualityColor(itemSlot.quality)
		itemSlot:SetBackdropBorderColor(r, g, b)
	else
		itemSlot:SetBackdropBorderColor(module:RGBA("Border"))
	end
end

function ContainerMixin:ItemLockUpdate(event_, id, slot)
	if not slot or not self:IsValidID(id) or not self.itemList[id][slot] then
		return
	end
	self:SlotUpdate(self.itemList[id][slot])
end

function ContainerMixin:BagUpdateEvent(idList)
	if not self.itemList then return end

	-- HACK: Whenever a bag is changed, BAG_UPDATE 0 triggers, instead of the missing bag ID.
	-- We need to reload the frame if a 0 happens, check it individually to skip the loop.
	if idList[0] then
		self:Layout()
		return
	end

	for id in pairs(idList) do
		if self:IsValidID(id) then
			--???: This conditional never triggers, as it should, why keep it?
			if not self.itemList[id] then
				LUI:Print("Cannot find ItemList["..id.."]. Reloading")
				self:Layout()
				return
			end
			for i = 1, #self.itemList[id] do
				self:SlotUpdate(self.itemList[id][i])
			end
		end
	end

	-- Update Search Results if searching
	if self.editbox:IsShown() then
		self:SearchUpdate()
	end
end

-- ####################################################################################################################
-- ##### Container: Set Anchors #######################################################################################
-- ####################################################################################################################

-- This function will set all itemslot anchors and the container's dimensions based on that.
function ContainerMixin:SetAnchors()
	-- index will help us stay positioned to prevent going above RowSize
	-- lineAnchor is going to store the first frame of every line, allowing to make a new line easily
	-- rightAnchor is going to store the rightmost frame, to set the width of the container
	-- rightIndex will be used to denote the position of the rightAnchor, to make sure it stays the rightmost frame
	-- previousAnchor is going to store the frame we just processed, so easily anchor the next one (unless newline)
	local lineAnchor, rightAnchor, previousAnchor
	local index = 0
	local rightIndex = 0
	local padding = self:GetOption("Padding")
	local spacing = self:GetOption("Spacing")
	local rowSize = self:GetOption("RowSize")
	for i = 1, self.NUM_BAG_IDS do
		local id = self.BAG_ID_LIST[i]
		--TODO: Add Option to newline on new bag
		-- if NewLineOnNewBag then index = 0 end
		if self:GetOption("BagNewline") then
			index = 0
		end
		for j = 1, #self.itemList[id] do
			local itemSlot = self.itemList[id][j]
			-- Make sure to clear points to prevent errors.
			itemSlot:ClearAllPoints()
			-- ItemSlots beyond bagCount are hidden, so we don't count them
			if itemSlot:IsShown() then
				-- Increment the index for positioning
				index = index + 1
				-- if lineAnchor is nil, then its the first slot.
				if not lineAnchor then
					local xOffset = padding
					--TODO: Possibly rename LAYOUT_OFFSET to TITLEBAR_HEIGHT unless used for something else
					local yOffset = LAYOUT_OFFSET + padding
					itemSlot:SetPoint("TOPLEFT", self, "TOPLEFT", xOffset, -yOffset)
					-- Set the itemSlot to be the anchor for future slots.
					lineAnchor = itemSlot
					rightAnchor = itemSlot
					previousAnchor = itemSlot
					rightIndex = index
				-- Check to see if we need to do a newline
				elseif index == 1 or index > rowSize then
					-- The previous lineAnchor takes care of the xOffset
					local yOffset = spacing
					itemSlot:SetPoint("TOP", lineAnchor, "BOTTOM", 0, -yOffset)
					-- Since it was a newline, it becomes the new lineAnchor
					lineAnchor = itemSlot
					previousAnchor = itemSlot
					index = 1
				-- In any other situation, just anchor it to the right of the previous slot
				else
					local xOffset = spacing
					-- The previousAnchor takes care of the yOffset
					itemSlot:SetPoint("LEFT", previousAnchor, "RIGHT", xOffset, 0)
					previousAnchor = itemSlot
					-- Check to see if it becomes the new rightAnchor
					if index > rightIndex then
						rightAnchor = itemSlot
						rightIndex = index
					end
				end
			end
		end  -- end of itemList loop for current ID
	end -- end of itemList for the last ID

	-- Set anchors of the background frame to cover all the items.
	self.background:ClearAllPoints()
	self.background:SetPoint("LEFT", lineAnchor, "LEFT", -padding, 0)
	self.background:SetPoint("RIGHT", rightAnchor, "RIGHT", padding, 0)
	self.background:SetPoint("BOTTOM", lineAnchor, "BOTTOM", 0, -padding)
	self.background:SetPoint("TOP", rightAnchor, "TOP", 0, LAYOUT_OFFSET + padding)
	-- Then set the size of the container frame to be equal to the background.
	self:SetSize(self.background:GetWidth(), self.background:GetHeight())
end

-- ####################################################################################################################
-- ##### Container: Search #############################################################################################
-- ####################################################################################################################

function ContainerMixin:SearchUpdate(text)
	text = strlower(text or self.editbox:GetText())

	for i = 1, self.NUM_BAG_IDS do
		local id = self.BAG_ID_LIST[i]
		for j = 1, #self.itemList[id] do
			local itemSlot = self.itemList[id][j]
			if itemSlot and not itemSlot.name then
				itemSlot:SetAlpha(ITEMSLOT_FILTER_ALPHA)
			end
			if itemSlot.name then
				if strfind(strlower(itemSlot.name), text) then
					SetItemButtonDesaturated(itemSlot, false)
					itemSlot:SetAlpha(ITEMSLOT_NORMAL_ALPHA)
				else
					SetItemButtonDesaturated(itemSlot, true)
					itemSlot:SetAlpha(ITEMSLOT_FILTER_ALPHA)
				end
			end
		end
	end
end

function ContainerMixin:SearchReset()
	for i = 1, self.NUM_BAG_IDS do
		local id = self.BAG_ID_LIST[i]
		for j = 1, #self.itemList[id] do
			local itemSlot = self.itemList[id][j]
			itemSlot:SetAlpha(ITEMSLOT_NORMAL_ALPHA)
			SetItemButtonDesaturated(itemSlot, false)
		end
	end
end

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

--- Function to create a blank slot used for tool bars, items, etc.
---@param name string
---@param parent Frame
---@param template? string @ Frame template to use. Defaults to "ContainerFrameItemButtonTemplate"
---@return ItemButton
function module:CreateSlot(name, parent, template)
	local button = CreateFrame("ItemButton", name, parent, template or BUTTON_SLOT_TEMPLATE)
	Mixin(button, _G.BackdropTemplateMixin)
	button:SetSize(BAG_TEXTURE_SIZE, BAG_TEXTURE_SIZE)
	button:SetPushedTexture("")
	button:SetNormalTexture("")

	local normalTex = _G[name.."NormalTexture"]
	if normalTex then
		normalTex:SetSize(1,1)
	end

	--Make IconTexture not clash with our backdrop
	local iconTex = _G[name.."IconTexture"]
	SetItemButtonTexture(button)
	if iconTex then
		-- This removes the white/silver border found around many IconTextures
		iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		iconTex:SetPoint("TOPLEFT", button, 3, -3)
		iconTex:SetPoint("BOTTOMRIGHT", button, -3, 3)
		-- This prevent the IconTextures from appearing (partially) above our itemSlot backdrop
		iconTex:SetDrawLayer("BORDER", -1)
		iconTex:Show()
	end

	return button
end

function module:CreateNewContainer(name, obj)
	if containerStorage[name] then return end

	-- Create the frame and set properties
	local frame = CreateFrame("Frame", "LUI"..name, UIParent)
	frame:SetFrameStrata("HIGH")
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetToplevel(true)
	frame:SetClampedToScreen(true)
	frame:SetSize(1,1)

	-- Background frame
	local bgFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	-- HACK: When Bags and Bank are opened at the same time, there is overlap happening. FIgure a better way to fix it.
	bgFrame:SetFrameLevel(frame:GetParent():GetFrameLevel()+1)
	bgFrame:SetClampedToScreen(true)
	frame.background = bgFrame

	-- Close Button
	local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	closeBtn:SetSize(32,32)
	closeBtn:SetPoint("TOPRIGHT", -3, -3)
	closeBtn:RegisterForClicks("AnyUp")
	closeBtn:SetScript("OnClick", function() frame:Close() end)
	frame.closeButton = closeBtn

	frame.toolbars = {} -- Used to store BagBar and such

	-- Embed things from the given object, then mixin the shared code or hook it.
	-- TODO: Re-evaluate if hooking is necessary or should be refactored
	for k, v in pairs(obj) do
		frame[k] = v
	end
	for k, v in pairs(ContainerMixin) do
		if frame[k] then
			module:Hook(frame, k, ContainerMixin[k])
		else
			frame[k] = v
		end
	end
	--Add AceBucket to the Container to process bag updates.
	LibStub("AceBucket-3.0"):Embed(frame)
	frame.db = module.db.profile[name]

	--Set up scripts
	frame:SetScript("OnShow", frame.OnShow)
	frame:SetScript("OnHide", frame.OnHide)
	frame:SetScript("OnMouseDown", frame.StartMovingFrame)
	frame:SetScript("OnMouseUp", frame.StopMovingFrame)

	-- Craete Search Box
	module:CreateSearchBar(frame)

	-- Create the Bag Bar
	if frame.CreateBagBar then
		module:CreateToolBar(frame, "bagsBar")
		frame.bagsBar:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 2)
		frame:CreateBagBar()
	end

	-- Create the Utility Bar
	if frame.CreateUtilBar then
		module:CreateToolBar(frame, "utilBar")
		if frame.bagsBar then
			frame.utilBar:SetPoint("LEFT", frame.bagsBar, "RIGHT", 4, 0)
		else
			frame.utilBar:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 2)
		end
		frame:CreateUtilBar()
	end

	--Preliminary table creation.
	frame.bagList = {}
	frame.itemList = {}
	for i = 1, frame.NUM_BAG_IDS do
		local id = frame.BAG_ID_LIST[i]
		frame.bagList[id] = frame:NewBagInfo(id)
		frame.itemList[id] = {}
	end

	containerStorage[name] = frame
	frame:SetBagsProperties()
	--SetBagsDimensions

	frame:Hide()
end

function module:CreateSearchEditBox(parent)
	local search = parent:CreateFontString(nil, "OVERLAY", "GameFonthighlightLarge")
	local searchText = module:ColorText(SEARCH, "Search")

	search:SetPoint("TOPLEFT", parent, db.Padding, -10)
	search:SetPoint("TOPRIGHT", -40, 0)
	search:SetJustifyH("LEFT")
	search:SetText(searchText)
end

function module:IsProfessionBag(id)
	local _, bagType = C_Container.GetContainerNumFreeSlots(id)
	if bagType and bagType > 0 then
		return true
	end
	return false
end

-- ####################################################################################################################
-- ##### Module Refresh ###############################################################################################
-- ####################################################################################################################
--TODO: Lots of options uses a loop over containers and/or items. We could combine most of them and deduplicate code.

function module:Refresh()
	for _, container in pairs(containerStorage) do
		--if container.forceRefresh then
			-- Refresh Settings
			container:SetScale(container:GetOption("Scale"))
			container:SetAnchors()
			--container:SetBagBarAnchors() -- Fix issues

			-- Re-adjust containers' editbox character limit.
			container.editbox:SetMaxLetters(container:GetOption("RowSize") * 5)

			-- Refresh Backdrops
			module:RefreshBackdrops()
			container.background:SetBackdrop(module.bagBackdrop)
			-- Refresh item slots
			for i = 1, container.NUM_BAG_IDS do
				local id = container.BAG_ID_LIST[i]
				for j = 1, #container.itemList[id] do
					container:SlotUpdate(container.itemList[id][j])
					container.itemList[id][j]:SetBackdrop(module.itemBackdrop)
				end
			end

			-- Refresh Toolbars
			for _, toolbar in pairs(container.toolbars) do
				toolbar:SetScale(container:GetOption("Scale"))
				toolbar.background:SetBackdrop(module.bagBackdrop)
				toolbar:SetAnchors()

				for i = 1, #toolbar.slotList do
				local slot = toolbar.slotList[i]
					slot:SetBackdrop(module.itemBackdrop)
				end
			end

			-- Refresh Colors
			module:RefreshColors()
			container.forceRefresh = false
		--end
	end
end

function module:RefreshBackdrops()
	local db = module.db.profile.Textures
	-- Bag Backdrop
	module.bagBackdrop = {
		bgFile = Media:Fetch("background", db.BackgroundTex),
		edgeFile = Media:Fetch("border", db.BorderTex),
		edgeSize = 15, insets = { left = 3, right = 3, top = 3, bottom = 3 }
	}
	-- Item Backdrop
	module.itemBackdrop = {
		bgFile = Media:Fetch("background", db.BackgroundTex),
		edgeFile = Media:Fetch("border", db.BorderTex),
		edgeSize = 15, insets = { left = 3, right = 3, top = 3, bottom = 3 },
	}
end

function module:RefreshColors()
	for _, container in pairs(containerStorage) do
		local r, g, b, a = module:RGBA("Background")
		local mult = BACKGROUND_MULTIPLIER
		container.background:SetBackdropColor(r * mult, g * mult, b * mult, a)
		container.background:SetBackdropBorderColor(module:RGBA("Border"))

		for i = 1, container.NUM_BAG_IDS do
			local id = container.BAG_ID_LIST[i]
			for j = 1, #container.itemList[id] do
				local itemSlot = container.itemList[id][j]
				itemSlot:SetBackdropColor(module:RGBA("ItemBackground"))
				container:SetItemSlotBorderColor(itemSlot)
			end
		end

		-- Refresh Toolbars
		for _, toolbar in pairs(container.toolbars) do
			toolbar.background:SetBackdropColor(r * mult, g * mult, b * mult, a)
			toolbar.background:SetBackdropBorderColor(module:RGBA("Border"))
			for i = 1, #toolbar.slotList do
				local slot = toolbar.slotList[i]
				slot:SetBackdropColor(module:RGBA("Background"))
				slot:SetBackdropBorderColor(module:RGBA("Border"))
			end
		end

	end
end

function module:SetBags()

	-- Bags
	module:CreateNewContainer("Bags", module.BagsContainer)
	LUIBags:CreateTitleBar()

	-- Bank
	module:CreateNewContainer("Bank", module.BankContainer)
	module:CreateNewContainer("Reagent", module.BankReagentContainer)

	module:Refresh()
end
