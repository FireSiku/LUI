-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

local _, LUI = ...
local module = LUI:GetModule("Bags")

local GetInventoryItemTexture = _G.GetInventoryItemTexture
local GetInventorySlotInfo = _G.GetInventorySlotInfo
local PickupBagFromSlot = _G.PickupBagFromSlot
local PutItemInBag = _G.PutItemInBag
local ResetCursor = _G.ResetCursor
local PlaySound = _G.PlaySound

local CLEANUP_TEXTURE_ATLAS = "bags-button-autosort-up"
local CLEANUP_TEXTURE = "Interface\\ContainerFrame\\Bags"
local CLEANUP_SOUND = _G.SOUNDKIT.UI_BAG_SORTING_01

local SEARCH = _G.SEARCH

--luacheck: globals BAG_CLEANUP_BAGS BAG_CLEANUP_BANK BAG_CLEANUP_REAGENT_BANK
--luacheck: globals PaperDollItemSlotButton_OnEvent PaperDollItemSlotButton_OnShow PaperDollItemSlotButton_OnHide
--luacheck: globals BagSlotButton_OnEnter BankFrameItemButton_OnEnter BankFrameItemButtonBag_OnClick

-- ####################################################################################################################
-- ##### Templates: BagBar Slot Button ################################################################################
-- ####################################################################################################################
-- The end goal should be an identical button for Bags and Bank bars, but they use different APIs.
-- Note: Probably good idea to replace button with bagsSlot

function module:BagBarSlotButtonTemplate(index, id, name, parent)
	-- TODO: Clean up and make more uniform, stop relying on Blizzard API.
	local button = module:CreateSlot(name, parent)
	button.isBag = 1 -- Blizzard API support
	button.id = id
	button.index = index
	button.container = parent:GetParent().name

	button:RegisterForDrag("LeftButton")
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	button:SetScript("OnClick", function(self) PutItemInBag(self.inventoryID) end)
	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
		ResetCursor()
	end)

	--Try to have as few type-specific settings as possible
	if button.container == "Bags" then

		--PaperDollItemSlotButton OnLoad
		--slotName uses id - 1 due to Bag1-4 are refered as Bag0-Bag3
		local slotName = format("Bag%dSlot", index)
		local inventoryID, textureName = GetInventorySlotInfo(slotName)
		button.inventoryID = inventoryID
		button:SetID(inventoryID)

		local texture = _G[name.."IconTexture"]
		texture:SetTexture(textureName)
		button.backgroundTextureName = textureName

		--Rest of BagSlotTemplate OnLoad
		button:RegisterEvent("BAG_UPDATE_DELAYED")
		--button:RegisterEvent("INVENTORY_SEARCH_UPDATE")

		button.UpdateTooltip = BagSlotButton_OnEnter
		button.IconBorder:SetTexture("")
		button.IconBorder:SetSize(1,1)

		--TODO: Remove PaperDoll calls
		--BagSlotTemplate other events, unchecked.
		button:SetScript("OnEvent", function(self, event, ...)
			if event == "BAG_UPDATE_DELAYED" then
				_G.PaperDollItemSlotButton_Update(self)
				self:SetBackdropBorderColor(module:RGBA("Border"))
			else
				PaperDollItemSlotButton_OnEvent(self, event, ...)
			end
		end)
		-- OnShow/OnHide are just a bunch of update
		button:SetScript("OnShow", PaperDollItemSlotButton_OnShow)
		button:SetScript("OnHide", PaperDollItemSlotButton_OnHide)
		button:SetScript("OnDragStart", function(self) PickupBagFromSlot(self.inventoryID) end)
		button:SetScript("OnReceiveDrag", function(self) PutItemInBag(self.inventoryID) end)
		button:SetScript("OnEnter", BagSlotButton_OnEnter)
	elseif button.container == "Bank" then
		button:SetID(id-4)

		button.GetInventorySlot = _G.ButtonInventorySlot;
		button.UpdateTooltip = _G.BankFrameItemButton_OnEnter
		button.inventoryID = button:GetInventorySlot()

		button:SetScript("OnEvent", function(self, event)
			if event == "BAG_UPDATE_DELAYED" then
				module:BankBagButtonUpdate(self)
			end
			-- Triggers when purchasing bank slots
			if event == "PLAYERBANKBAGSLOTS_CHANGED" then
				LUIBank:Layout()
			end
		end)
		button:SetScript("OnDragStart", _G.BankFrameItemButtonBag_Pickup)
		button:SetScript("OnReceiveDrag", _G.BankFrameItemButtonBag_OnClick)
		button:SetScript("OnEnter", _G.BankFrameItemButton_OnEnter)

		button:SetScript("OnShow", function(self)
			module:BankBagButtonUpdate(self)
		end)

		--BankFrameItemButton_Update(button)
		module:BankBagButtonUpdate(button)
		_G.BankFrameItemButton_UpdateLocked(button)
		button.tooltipText = button.tooltipText or ""
	end

	return button
end

function module:BankBagButtonUpdate(button)
	local texture = button.icon
	local textureName = GetInventoryItemTexture("player", button.inventoryID)
	local _, slotTextureName = GetInventorySlotInfo("Bag"..button.id)

	if textureName then
		texture:SetTexture(textureName)
	elseif slotTextureName then
		--If no bag texture is found, show empty slot.
		texture:SetTexture(slotTextureName)
	end

	button:SetBackdropBorderColor(module:RGBA("Border"))

	texture:Show()
end

-- ####################################################################################################################
-- ##### Templates: CleanUp Button ####################################################################################
-- ####################################################################################################################

local CLEANUP_TEXT = {
	LUIBags_CleanUp = BAG_CLEANUP_BAGS,
	LUIBank_CleanUp = BAG_CLEANUP_BANK,
	LUIReagent_CleanUp = BAG_CLEANUP_REAGENT_BANK,
}

function module:CreateCleanUpButton(name, parent, sortFunc)
	local button = module:CreateSlot(name, parent)
	--module:ApplyBackdrop(button, module.itemBackdrop)
	button:SetScript("OnClick", function()
			PlaySound(CLEANUP_SOUND)
			sortFunc()
		end)
	button:SetScript("OnEnter", function()
			GameTooltip:SetOwner(button)
			GameTooltip:SetText(CLEANUP_TEXT[name])
			GameTooltip:Show()
		end)
	button:SetScript("OnLeave", _G.GameTooltip_Hide)

	--Adjust the icon to fit CleanUp.
	button.icon:SetTexCoord(LUI:GetCoordAtlas("CleanUp"))
	button.icon:SetTexture(CLEANUP_TEXTURE)
	button.icon:SetAtlas(CLEANUP_TEXTURE_ATLAS)

	return button
end

-- ####################################################################################################################
-- ##### Templates: Search Bar ########################################################################################
-- ####################################################################################################################

function module:CreateSearchBar(container)
	local db = module.db.profile

	-- Search Text
	local search = container:CreateFontString(nil, "OVERLAY", "GameFonthighlightLarge")
	local searchText = module:ColorText(SEARCH, "Search")
	search:SetPoint("TOPLEFT", container, db.Padding, -10)
	search:SetPoint("TOPRIGHT", -40, 0)
	search:SetJustifyH("LEFT")
	search:SetText(searchText)

	-- Search Editbox
	local editbox = CreateFrame("EditBox", nil, container)
	module:RefreshFontString(editbox, "Bags")
	
	editbox:SetHeight(32)
	editbox:SetAutoFocus(false)
	editbox:SetMaxLetters(db.RowSize * 5)
	editbox:SetTextInsets(24, 0, 0, 0)
	editbox:SetAllPoints(search)
	editbox:Hide()

	-- Editbox scripts
	editbox:SetScript("OnEscapePressed", editbox.ClearFocus)
	editbox:SetScript("OnEnterPressed", editbox.ClearFocus)
	--editbox:SetScript("OnEditFocusLost", editbox.Hide)
	--editbox:SetScript("OnEditFocusGained", editbox.HighlightText)
	editbox:SetScript("OnTextChanged", function(self, text)
		if text then
			container:SearchUpdate(self:GetText())
		end
	end)

	-- Editbox ClearButton
	local clear = CreateFrame("Button", nil, editbox)
	clear:SetPoint("LEFT", search, "LEFT", 0, 0)
	clear:SetSize(24, 24)
	clear:Hide()

	local texture = clear:CreateTexture(nil, "ARTWORK")
	texture:SetTexture("Interface\\FriendsFrame\\ClearBroadcastIcon")
	texture:SetAllPoints(clear)
	
	-- Search Button, not visible but to show the editbox
	local button = CreateFrame("Button", nil, container)
	button:EnableMouse(1)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:SetAllPoints(search)

	button:SetScript("OnClick", function(self, btn)
		if btn == "RightButton" or container.editbox:IsShown() then
			container:HideTitleBar()
			container.editbox:Show()
			container.clear:Show()
			container.editbox:SetFocus()
		end
	end)
	button:SetScript("OnMouseDown", function() container:StartMovingFrame() end)
	button:SetScript("OnMouseUp", function() container:StopMovingFrame() end)

	clear:SetScript("OnClick", function(self)
		container.editbox:Hide()
		container.clear:Hide()
		container.editbox:ClearFocus()
		container:ShowTitleBar()
		container:SearchReset()
	end)

	container.searchText = search
	container.editbox = editbox
	container.clear = clear
end
