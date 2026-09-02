-- Shared container behavior for LUI's combined character bags.
-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Bags
local module = LUI:GetModule("Bags")
local Media = LibStub("LibSharedMedia-3.0")

-- Locals and Constants
local pairs = pairs
local C_Container = C_Container
local C_Timer = C_Timer
local SetItemButtonDesaturated = _G.SetItemButtonDesaturated
local ClearItemButtonOverlay = _G.ClearItemButtonOverlay
local SetItemButtonOverlay = _G.SetItemButtonOverlay
local SetItemButtonTexture = _G.SetItemButtonTexture
local GetItemQualityColor = C_Item.GetItemQualityColor
local SetItemButtonCount = _G.SetItemButtonCount
local GetDetailedItemLevelInfo = C_Item.GetDetailedItemLevelInfo

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

---@class ContainerMixin : Frame
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
	self.db.X = x
	self.db.Y = y
end

function ContainerMixin:QueueBagUpdate(id)
	if id == nil then return end
	self.pendingBagUpdates[id] = (self.pendingBagUpdates[id] or 0) + 1
	if self.bagUpdateTimer then return end

	self.bagUpdateTimer = C_Timer.NewTimer(BAG_UPDATE_TIME, function()
		self.bagUpdateTimer = nil
		local pending = self.pendingBagUpdates
		self.pendingBagUpdates = {}
		if self:IsShown() then self:BagUpdateEvent(pending) end
	end)
end

function ContainerMixin:StartBagUpdates()
	self.pendingBagUpdates = self.pendingBagUpdates or {}
	if not self.bagUpdateFrame then
		self.bagUpdateFrame = CreateFrame("Frame")
		self.bagUpdateFrame:SetScript("OnEvent", function(_, _, id)
			self:QueueBagUpdate(id)
		end)
	end
	self.bagUpdateFrame:RegisterEvent("BAG_UPDATE")
end

function ContainerMixin:StopBagUpdates()
	if self.bagUpdateFrame then self.bagUpdateFrame:UnregisterEvent("BAG_UPDATE") end
	if self.bagUpdateTimer then
		self.bagUpdateTimer:Cancel()
		self.bagUpdateTimer = nil
	end
	if self.pendingBagUpdates then wipe(self.pendingBagUpdates) end
end

function ContainerMixin:OnShow()
	self:StartBagUpdates()
	module:RegisterEvent("ITEM_LOCK_CHANGED", function(...) self:ItemLockUpdate(...) end)
	module:RegisterEvent("BAG_UPDATE_COOLDOWN", function() self:UpdateCooldowns() end)
	module:RegisterEvent("MERCHANT_SHOW", function() self:Layout() end)
	module:RegisterEvent("MERCHANT_CLOSED", function() self:Layout() end)
	self:Layout()
end

function ContainerMixin:OnHide()
	self:StopBagUpdates()
	module:UnregisterEvent("ITEM_LOCK_CHANGED")
	module:UnregisterEvent("BAG_UPDATE_COOLDOWN")
	module:UnregisterEvent("MERCHANT_SHOW")
	module:UnregisterEvent("MERCHANT_CLOSED")
	if self.editbox and not self.searchText:IsShown() then
		self:ShowTitleBar()
		self.editbox:Hide()
		self.clear:Hide()
		self.editbox:ClearFocus()
		self:SearchReset()
	end
end

function ContainerMixin:UpdateCooldowns()
	for i = 1, self.NUM_BAG_IDS do
		local id = self.BAG_ID_LIST[i]
		for j = 1, #self.itemList[id] do
			local itemSlot = self.itemList[id][j]
			if itemSlot:IsShown() then
				itemSlot:UpdateCooldown(C_Container.HasContainerItem(id, j))
			end
		end
	end
end

function ContainerMixin:ShowTitleBar()
	self.searchText:Show()
end

function ContainerMixin:HideTitleBar()
	self.searchText:Hide()
end

function ContainerMixin:GetOption(name)
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
		self.bagSizes[id] = bagCount
		if bagCount > 0 then
			self.bagList[id]:Show()
			for j = 1, bagCount do
				-- The item slots will be anchored later on.
				itemList[j] = self:NewItemSlot(id, j)
				self:SlotUpdate(itemList[j])
				itemList[j]:Show()
			end
		else
			self.bagList[id]:Hide()
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

function ContainerMixin:SetPosition()
	self:ClearAllPoints()
	if not self.db.X or self.db.X == 0 and self.db.Y == 0 then
		self:SetPoint("CENTER", UIParent, "CENTER")
	else
		self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", self.db.X, self.db.Y)
	end
end

function ContainerMixin:SetBagsProperties()
	self:SetPosition()

	self.forceRefresh = true
	self:Layout()
	module:Refresh()
end

function ContainerMixin:NewBagInfo(id)
	-- If the ID has already been created, return it
	if self.bagList[id] then return self.bagList[id] end

	--Create the frame
	local bagFrame = CreateFrame("Frame", self:GetName()..id, self)
	bagFrame:SetID(id)

	return bagFrame
end

-- Container-specific code creates Blizzard item-slot templates; this method
-- applies the shared LUI presentation afterward.
function ContainerMixin:SetItemSlotProperties(itemSlot)
	--Make it easy to fetch Cooldown information
	itemSlot.cooldown = _G[itemSlot:GetName() .. "Cooldown"]

	--Update backdrop
	LUI:ApplyFrameBackdrop(itemSlot, module.itemBackdrop)
	LUI:SetFrameBackgroundColor(itemSlot, module:RGBA("ItemBackground"))
end

-- ####################################################################################################################
-- ##### Container: Slot Update #######################################################################################
-- ####################################################################################################################

--- Base function for updating items.
---@param itemSlot ItemButton
function ContainerMixin:SlotUpdate(itemSlot)
	local id, slot = itemSlot.id, itemSlot.slot
	local data = C_Container.GetContainerItemInfo(id, slot)

	LUI:SetFrameBorderColor(itemSlot, module:RGBA("Border"))
	if module:IsProfessionBag(id) then
		LUI:SetFrameBorderColor(itemSlot, module:RGBA("Professions"))
	end

	itemSlot:SetHasItem(data ~= nil)
	itemSlot:SetReadable(data and data.isReadable)
	itemSlot:UpdateCooldown(data ~= nil)
	itemSlot:UpdateJunkItem(data and data.quality, data and data.hasNoValue)
	-- New item code from Blizzard's ContainerFrame.lua
	local newItemTexture = itemSlot.NewItemTexture
	local battlePayTexture = itemSlot.BattlepayItemTexture
	local flashAnim = itemSlot.flashAnim
	local newItemAnim = itemSlot.newitemglowAnim
	-- Not all item slots have a newItemTexture
	if newItemTexture then
		if data and self:GetOption("ShowNew") and C_NewItems.IsNewItem(id, slot) then
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
	local itemLink = data and data.hyperlink
	if itemLink then
		itemSlot.name = data.itemName
		itemSlot.quality = data.quality
		
		-- Get the item level for equippable items
		if self.db.ItemLevel and C_Item.IsEquippableItem(itemLink) then
			itemSlot.level = GetDetailedItemLevelInfo(itemLink)
		end

		self:SetItemSlotBorderColor(itemSlot)
		
	end
	
	if data then
		SetItemButtonTexture(itemSlot, data.iconFileID)
		SetItemButtonCount(itemSlot, itemSlot.level or data.stackCount)
		SetItemButtonDesaturated(itemSlot, data.isLocked)

		if self.db.ShowOverlay and itemLink then
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
	if self:GetOption("ItemQuality") and itemSlot.quality and itemSlot.quality >= Enum.ItemQuality.Uncommon then
		local r, g, b = GetItemQualityColor(itemSlot.quality)
		LUI:SetFrameBorderColor(itemSlot, r, g, b)
	elseif module:IsProfessionBag(itemSlot.id) then
		LUI:SetFrameBorderColor(itemSlot, module:RGBA("Professions"))
	else
		LUI:SetFrameBorderColor(itemSlot, module:RGBA("Border"))
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

	for id in pairs(idList) do
		if self:IsValidID(id) then
			if not self.itemList[id] then
				LUI:Print("Cannot find ItemList["..id.."]. Reloading")
				self:Layout()
				return
			end
			local bagCount = C_Container.GetContainerNumSlots(id)
			if self.bagSizes[id] ~= bagCount then
				self:Layout()
				return
			end
			for i = 1, bagCount do
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
			local data = C_Container.GetContainerItemInfo(id, j)
			if itemSlot and not itemSlot.name then
				itemSlot:SetAlpha(ITEMSLOT_FILTER_ALPHA)
			end
			if itemSlot.name then
				if strfind(strlower(itemSlot.name), text) then
					SetItemButtonDesaturated(itemSlot, data and data.isLocked)
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
			local data = C_Container.GetContainerItemInfo(id, j)
			itemSlot:SetAlpha(ITEMSLOT_NORMAL_ALPHA)
			SetItemButtonDesaturated(itemSlot, data and data.isLocked)
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

	local count = button.Count or _G[name.."Count"]
	if count then
		module:RefreshFontString(count, "Stack")
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
	frame:SetSize(600, 600)

	-- Background frame
	local bgFrame = CreateFrame("Frame", nil, frame)
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

	-- Embed things from the given object, then mix in the shared container code.
	for k, v in pairs(obj) do
		frame[k] = v
	end
	for k, v in pairs(ContainerMixin) do
		if frame[k] then
			-- Compose container-specific behavior with the shared behavior directly.
			-- AceHook's module-wide UnhookAll is reserved for Blizzard globals so
			-- disabling and re-enabling Bags cannot remove this internal method.
			local containerMethod = frame[k]
			local sharedMethod = v
			frame[k] = function(self, ...)
				containerMethod(self, ...)
				return sharedMethod(self, ...)
			end
		else
			frame[k] = v
		end
		
	end
	---@cast frame ContainerMixin

	frame.db = module.db.profile[name]

	--Set up scripts
	frame:SetScript("OnShow", frame.OnShow)
	frame:SetScript("OnHide", frame.OnHide)
	frame:SetScript("OnMouseDown", frame.StartMovingFrame)
	frame:SetScript("OnMouseUp", frame.StopMovingFrame)

	-- Create Search Box
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
	frame.bagSizes = {}
	for i = 1, frame.NUM_BAG_IDS do
		local id = frame.BAG_ID_LIST[i]
		frame.bagList[id] = frame:NewBagInfo(id)
		frame.itemList[id] = {}
	end

	containerStorage[name] = frame

	frame:Hide()
end

function module:IsProfessionBag(id)
	local _, bagType = C_Container.GetContainerNumFreeSlots(id)
	if bagType and bagType > 0 then
		return true
	end
	return false
end

function module:IsCharacterBag(id)
	return type(id) == "number"
		and id >= Enum.BagIndex.Backpack
		and id <= Enum.BagIndex.ReagentBag
end

-- ####################################################################################################################
-- ##### Module Refresh ###############################################################################################
-- ####################################################################################################################
function module:Refresh()
	for _, container in pairs(containerStorage) do
			-- Refresh Settings
			container:SetScale(container:GetOption("Scale"))
			container:SetPosition()
			container:SetAnchors()

			container.editbox:SetMaxLetters(container:GetOption("RowSize") * 5)
			module:RefreshFontString(container.editbox, "Bags")
			container.searchText:SetText(module:ColorText(SEARCH, "Search"))
			if container.gold then
				module:RefreshFontString(container.gold, "Bags")
				module:RefreshFontString(container.currency, "Bags")
			end
			if container.utilBar then
				container.utilBar:ClearAllPoints()
				if container:GetOption("BagBar") then
					container.utilBar:SetPoint("LEFT", container.bagsBar, "RIGHT", 4, 0)
				else
					container.utilBar:SetPoint("BOTTOMLEFT", container, "TOPLEFT", 0, 2)
				end
			end

			-- Refresh Backdrops
			module:RefreshBackdrops()
			LUI:ApplyFrameBackdrop(container.background, module.bagBackdrop)
			-- Refresh item slots
			for i = 1, container.NUM_BAG_IDS do
				local id = container.BAG_ID_LIST[i]
				for j = 1, #container.itemList[id] do
					local slot = container.itemList[id][j]
					container:SlotUpdate(slot)
					LUI:ApplyFrameBackdrop(slot, module.itemBackdrop)
					local count = slot.Count or _G[slot:GetName().."Count"]
					if count then module:RefreshFontString(count, "Stack") end
				end
			end

			-- Refresh Toolbars
			for _, toolbar in pairs(container.toolbars) do
				LUI:ApplyFrameBackdrop(toolbar.background, module.bagBackdrop)
				toolbar:SetAnchors()
				if toolbar == container.bagsBar then
					toolbar:SetShown(container:GetOption("BagBar"))
				end

				for i = 1, #toolbar.slotList do
				local slot = toolbar.slotList[i]
					LUI:ApplyFrameBackdrop(slot, module.itemBackdrop)
				end
			end

			-- Refresh Colors
			module:RefreshColors()
			container.forceRefresh = false
	end
end

function module:RefreshBackdrops()
	local db = module.db.profile.Textures
	-- Bag Backdrop
	module.bagBackdrop = {
		bgFile = Media:Fetch("background", db.BackgroundTex),
		edgeFile = Media:Fetch("border", db.BorderTex),
		edgeSize = db.BorderSize, insets = { left = 3, right = 3, top = 3, bottom = 3 }
	}
	-- Item Backdrop
	module.itemBackdrop = {
		bgFile = Media:Fetch("background", db.BackgroundTex),
		edgeFile = Media:Fetch("border", db.BorderTex),
		edgeSize = db.BorderSize, insets = { left = 3, right = 3, top = 3, bottom = 3 },
	}
end

function module:RefreshColors()
	for _, container in pairs(containerStorage) do
		local r, g, b, a = module:RGBA("Background")
		local mult = BACKGROUND_MULTIPLIER
		LUI:SetFrameBackgroundColor(container.background, r * mult, g * mult, b * mult, a)
		LUI:SetFrameBorderColor(container.background, module:RGBA("Border"))

		for i = 1, container.NUM_BAG_IDS do
			local id = container.BAG_ID_LIST[i]
			for j = 1, #container.itemList[id] do
				local itemSlot = container.itemList[id][j]
				LUI:SetFrameBackgroundColor(itemSlot, module:RGBA("ItemBackground"))
				container:SetItemSlotBorderColor(itemSlot)
			end
		end

		-- Refresh Toolbars
		for _, toolbar in pairs(container.toolbars) do
			LUI:SetFrameBackgroundColor(toolbar.background, r * mult, g * mult, b * mult, a)
			LUI:SetFrameBorderColor(toolbar.background, module:RGBA("Border"))
			for i = 1, #toolbar.slotList do
				local slot = toolbar.slotList[i]
				LUI:SetFrameBackgroundColor(slot, module:RGBA("Background"))
				LUI:SetFrameBorderColor(slot, module:RGBA("Border"))
			end
		end

	end
end

function module:SetBags()
	module:CreateNewContainer("Bags", module.BagsContainer)
	if not LUIBags.gold then
		LUIBags:CreateTitleBar()
	else
		LUIBags:RegisterTitleBarEvents()
	end
	LUIBags:SetBagsProperties()
end

function module:RestoreBlizzardBagState()
	if _G.LUIBags then _G.LUIBags:UnregisterAllEvents() end
	if module.originalBackpackTokenWidth then
		BackpackTokenFrame:SetWidth(module.originalBackpackTokenWidth)
		module.originalBackpackTokenWidth = nil
	end
end
