-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@type string, LUIAddon
local _, LUI = ...

---@class BagsModule
local module = LUI:GetModule("Bags")

local GetInventoryItemTexture = _G.GetInventoryItemTexture
local GetInventorySlotInfo = _G.GetInventorySlotInfo
local GameTooltip_SetTitle = _G.GameTooltip_SetTitle
local IsContainerFiltered = _G.IsContainerFiltered
local PickupBagFromSlot = _G.PickupBagFromSlot
local PutItemInBag = _G.PutItemInBag
local ResetCursor = _G.ResetCursor

local BAGINDEX_BACKPACK = Enum.BagIndex.Backpack or 0
local BAGINDEX_BANK = Enum.BagIndex.Bank or 1

--luacheck: globals PaperDollItemSlotButton_OnEvent PaperDollItemSlotButton_OnShow PaperDollItemSlotButton_OnHide
--luacheck: globals BagSlotButton_OnEnter BankFrameItemButton_OnEnter BankFrameItemButtonBag_OnClick

-- ####################################################################################################################
-- ##### Toolbar Mixin ################################################################################################
-- ####################################################################################################################
-- Toolbars is the generic names for any bar that will be around the main container frame.
-- The primary toolbars will be the BagBar and the Utility Bar

---@class ToolbarMixin
---@field slotList ItemButton[] @ Array containing all current slots for toolbar
---@field nextIndex number @ Index of the next slot to be created
---@field container ContainerMixin
---@field background Frame
local ToolbarMixin = {}

function ToolbarMixin:SetAnchors()
	local padding = self.container:GetOption("Padding")
	local spacing = self.container:GetOption("Spacing")
	local previousAnchor, firstAnchor
	for i = 1, #self.slotList do
		local slot = self.slotList[i]
		slot:ClearAllPoints()

		if not slot.hidden then
			slot:Show()
			if not previousAnchor then -- first slot
				slot:SetPoint("TOPLEFT", self, "TOPLEFT", padding, -padding)
				previousAnchor = slot
				firstAnchor = slot
			else
				slot:SetPoint("LEFT", previousAnchor, "RIGHT", spacing, 0)
				previousAnchor = slot
			end
		else
			slot:Hide()
		end
	end

	self.background:SetPoint("LEFT", firstAnchor, "LEFT", -padding, 0)
	self.background:SetPoint("TOP", firstAnchor, "TOP", 0, padding)
	self.background:SetPoint("BOTTOM", firstAnchor, "BOTTOM", 0, -padding)
	self.background:SetPoint("RIGHT", previousAnchor, "RIGHT", padding, 0)

	self:SetSize(self.background:GetWidth(), self.background:GetHeight())
	self:Show()
end

---	Simple function to add a new button to the toolbar.
---@param newButton Frame
function ToolbarMixin:AddNewButton(newButton)
	self.slotList[self.nextIndex] = newButton
	self.nextIndex = self.nextIndex + 1
end

function ToolbarMixin:ShowButton(button)
	button.hidden = false
	self:SetAnchors()
end

function ToolbarMixin:HideButton(button)
	button.hidden = true
	self:SetAnchors()
end

function ToolbarMixin:SetButtonTooltip(button, text)
	button:SetScript("OnEnter", function()
			GameTooltip:SetOwner(button)
			GameTooltip:SetText(text)
			GameTooltip:Show()
		end)
	button:SetScript("OnLeave", _G.GameTooltip_Hide)
end

--- Create a toolbar for a given container
---@param container ContainerMixin
---@param name string
function module:CreateToolBar(container, name)
	local toolBar = CreateFrame("Frame", nil, container)
	toolBar:SetClampedToScreen(true)
	toolBar:SetSize(1,1)

	local bgFrame = CreateFrame("Frame", nil, toolBar, "BackdropTemplate")
	--Force it to the lowest frame level to prevent layering issues
	bgFrame:SetFrameLevel(toolBar:GetParent():GetFrameLevel())
	bgFrame:SetClampedToScreen(true)

	bgFrame:SetBackdrop(module.bagBackdrop)
	bgFrame:SetBackdropColor(module:RGBA("Background"))
	bgFrame:SetBackdropBorderColor(module:RGBA("Border"))

	toolBar.slotList = {}
	toolBar.nextIndex = 1
	toolBar.container = container
	toolBar.background = bgFrame
	container.toolbars[name] = toolBar
	if not container[name] then
		container[name] = toolBar
	end

	return Mixin(toolBar, ToolbarMixin)
end

--[[
	function PaperDollItemSlotButton_OnLoad(self)
		self:RegisterForDrag("LeftButton");
		self:RegisterForClicks("LeftButtonUp", "RightButtonUp");
		
		local slotName = PaperDollItemSlotButton_GetSlotName(self);
		local id, textureName, checkRelic = GetInventorySlotInfo(slotName);
		self:SetID(id);
		local texture = self.icon;
		texture:SetTexture(textureName);
		self.backgroundTextureName = textureName;
		self.checkRelic = checkRelic;
		self.UpdateTooltip = PaperDollItemSlotButton_OnEnter;
		itemSlotButtons[id] = self;
		self.verticalFlyout = VERTICAL_FLYOUTS[id];
		local popoutButton = self.popoutButton;
		if ( popoutButton ) then
			if ( self.verticalFlyout ) then
				popoutButton:SetHeight(16);
				popoutButton:SetWidth(38);
				popoutButton:GetNormalTexture():SetTexCoord(0.15625, 0.84375, 0.5, 0);
				popoutButton:GetHighlightTexture():SetTexCoord(0.15625, 0.84375, 1, 0.5);
				popoutButton:ClearAllPoints();
				popoutButton:SetPoint("TOP", self, "BOTTOM", 0, 4);
			else
				popoutButton:SetHeight(38);
				popoutButton:SetWidth(16);
				popoutButton:GetNormalTexture():SetTexCoord(0.15625, 0.5, 0.84375, 0.5, 0.15625, 0, 0.84375, 0);
				popoutButton:GetHighlightTexture():SetTexCoord(0.15625, 1, 0.84375, 1, 0.15625, 0.5, 0.84375, 0.5);
				popoutButton:ClearAllPoints();
				popoutButton:SetPoint("LEFT", self, "RIGHT", -8, 0);
			end
		end
	end

function BaseBagSlotButtonMixin:OnLoadInternal()
	PaperDollItemSlotButton_OnLoad(self);
	self:RegisterForClicks("AnyUp");
	self:RegisterEvent("BAG_UPDATE_DELAYED");
	self:RegisterEvent("INVENTORY_SEARCH_UPDATE");
	self.isBag = 1;
	self.maxDisplayCount = 999;
	self.UpdateTooltip = self.BagSlotOnEnter;
	self.Count:ClearAllPoints();
	self.Count:SetPoint("BOTTOMRIGHT", -2, 2);
	self:RegisterBagButtonUpdateItemContextMatching();
end
function BaseBagSlotButtonMixin:BagSlotOnEvent(event, ...)
	if event == "ITEM_PUSH" then
		local bagSlot, iconFileID = ...;
		if self:GetID() == bagSlot then
			self.AnimIcon:SetTexture(iconFileID);
			self.FlyIn:Play(true);
		end
	elseif event == "BAG_UPDATE_DELAYED" then
		PaperDollItemSlotButton_Update(self);
	elseif event == "INVENTORY_SEARCH_UPDATE" then
		self:SetMatchesSearch(not IsContainerFiltered(self:GetBagID()));
	else
		PaperDollItemSlotButton_OnEvent(self, event, ...);
	end
end
]]
-- ####################################################################################################################
-- ##### Templates: BagBar Fiter Dropdown #############################################################################
-- ####################################################################################################################
-- The Filter Dropdown code is taken from the ContainerFrame.lua file, and modified to work with our buttons.
-- The FrameXML declares them as local functions, so we have to copy them here.
local function OnBagFilterClicked(bagID, filterID, value)
	C_Container.SetBagSlotFlag(bagID, filterID, value);
	ContainerFrameSettingsManager:SetFilterFlag(bagID, filterID, value);
end

local function BagFilterDropDown(self, level)
	local bagID = self:GetParent():GetBagID()
	if not ContainerFrame_CanContainerUseFilterMenu(bagID) then
		return;
	end
	
	-- Filter Assignment Header
	local info = UIDropDownMenu_CreateInfo();
	info.text = BAG_FILTER_ASSIGN_TO;
	info.isTitle = 1;
	info.notCheckable = 1;
	UIDropDownMenu_AddButton(info, level);

	-- Filter Assignment Options
	info = UIDropDownMenu_CreateInfo();
	local activeBagFilter = ContainerFrameSettingsManager:GetFilterFlag(bagID);
	for i, flag in ContainerFrameUtil_EnumerateBagGearFilters() do
		info.text = BAG_FILTER_LABELS[flag];
		info.checked = activeBagFilter == flag;
		info.func = function(_, _, _, value)
			return OnBagFilterClicked(bagID, flag, not value);
		end
		UIDropDownMenu_AddButton(info, level);
	end

	-- CleanUp Header
	info = UIDropDownMenu_CreateInfo();
	info.text = BAG_FILTER_CLEANUP;
	info.isTitle = 1;
	info.notCheckable = 1;
	UIDropDownMenu_AddButton(info, level);

	-- CleanUp Options
	info = UIDropDownMenu_CreateInfo();
	info.text = BAG_FILTER_IGNORE;
	info.func = function(_, _, _, value)
		if bagID == BAGINDEX_BANK then
			C_Container.SetBankAutosortDisabled(not value);
		elseif bagID == BAGINDEX_BACKPACK then
			C_Container.SetBackpackAutosortDisabled(not value);
		else
			C_Container.SetBagSlotFlag(bagID, Enum.BagSlotFlags.DisableAutoSort, not value);
		end
	end
	if bagID == BAGINDEX_BANK then
		info.checked = C_Container.GetBankAutosortDisabled();
	elseif bagID == BAGINDEX_BACKPACK then
		info.checked = C_Container.GetBackpackAutosortDisabled();
	else
		info.checked = C_Container.GetBagSlotFlag(bagID, Enum.BagSlotFlags.DisableAutoSort);
	end
	UIDropDownMenu_AddButton(info, level);

end

-- ####################################################################################################################
-- ##### Templates: BagBar Slot Button ################################################################################
-- ####################################################################################################################
-- The end goal should be an identical button for Bags and Bank bars, without directly using Blizzard code.
-- This is to avoid potential taint. Bags and Bank use different APIs sometimes.
-- Note: Probably good idea to replace button with bagsSlot

--- Called when the mouse enters a BagBar slot button.
---@param self ItemButton
local function BarBarSlotOnEnter(self)
	_G.EventRegistry:TriggerEvent("BagSlot.OnEnter", self)
	GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
	
	local bagId = self:GetBagID()
	if bagId == BAGINDEX_BACKPACK then
        GameTooltip_SetTitle(GameTooltip, BACKPACK_TOOLTIP)
    elseif bagId == BAGINDEX_BANK then
        GameTooltip_SetTitle(GameTooltip, BANK)
    else
        local hasItem = GameTooltip:SetInventoryItem('player', self.inventoryID)
        if not hasItem then
			local isBank = self.container == "Bank"
            if self.purchaseCost then
                GameTooltip:ClearLines()
                GameTooltip_SetTitle(GameTooltip, BANK_BAG_PURCHASE)
                GameTooltip:AddDoubleLine(COSTS_LABEL, GetCoinTextureString(self.purchaseCost))
            elseif bagId == Enum.BagIndex.ReagentBag then
                GameTooltip_SetTitle(GameTooltip, EQUIP_CONTAINER_REAGENT)
            elseif isBank and bagId > GetNumBankSlots() + NUM_TOTAL_EQUIPPED_BAG_SLOTS then
                GameTooltip_SetTitle(GameTooltip, BANK_BAG_PURCHASE)
            elseif isBank then
                GameTooltip_SetTitle(GameTooltip, BANK_BAG)
            else
                GameTooltip_SetTitle(GameTooltip, EQUIP_CONTAINER)
            end
        end
    end
    GameTooltip:Show()
end

--- Create an ItemButton specific to the BagBar
---@param index number
---@param id number
---@param name string
---@param parent Frame @ Should be a container's BagBar.
---@return ItemButton
function module:BagBarSlotButtonTemplate(index, id, name, parent)
	-- TODO: Clean up and make more uniform, stop relying on Blizzard API.
	local button = module:CreateSlot(name, parent, "")
	button.isBag = 1 -- Blizzard API support
	button.id = id
	button:SetBagID(id)
	button.index = index
	button.container = parent:GetParent().name

	button:RegisterForDrag("LeftButton")
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:RegisterBagButtonUpdateItemContextMatching()
	button:RegisterEvent("BAG_UPDATE_DELAYED")
	button.GetIsBarExpanded = function() return true end
	button.FilterDropDown = CreateFrame("Frame", "$parentFilterDropDown", button, "UIDropDownMenuTemplate")
	UIDropDownMenu_SetInitializeFunction(button.FilterDropDown, BagFilterDropDown)

	button:SetScript("OnClick", function(self, btn)
		local bagID = self:GetBagID()
		if btn == "RightButton" then
			ToggleDropDownMenu(1, nil, self.FilterDropDown, self, 0, 0)
		elseif CursorHasItem() and not self.purchaseCost then
			PutItemInBag(self.inventoryID)
		elseif self.purchaseCost then
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
			BankFrame.nextSlotCost = self.purchaseCost
			StaticPopup_Show('CONFIRM_BUY_BANK_SLOT')
		elseif bagID ~= Enum.BagIndex.Backpack and bagID ~= Enum.BagIndex.Bank then
			PickupBagFromSlot(self.inventoryID)
		end
	end)
	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
		ResetCursor()
		_G.EventRegistry:TriggerEvent("BagSlot.OnLeave", button)
	end)
	button:SetScript("OnEnter", BarBarSlotOnEnter)

	--Try to have as few type-specific settings as possible
	if button.container == "Bags" then
		
		--PaperDollItemSlotButton_OnLoad
		--slotName uses id - 1 due to Bag1-4 are refered as Bag0-Bag3
		local slotName = string.format("BAG%dSLOT", index)
		button.inventoryID = C_Container.ContainerIDToInventoryID(id)
		button:SetID(button.inventoryID)

		local texture = _G[name.."IconTexture"]
		local textureName = GetInventoryItemTexture("player", button.inventoryID)
		texture:SetTexture(textureName)

		--Rest of BagSlotTemplate OnLoad
		button:RegisterEvent("INVENTORY_SEARCH_UPDATE")

		button.UpdateTooltip = BagSlotButton_OnEnter
		button.IconBorder:SetTexture("")
		button.IconBorder:SetSize(1,1)

		--TODO: Remove PaperDoll calls
		--BagSlotTemplate other events, unchecked.
		button:SetScript("OnEvent", function(self, event, ...)
			if event == "BAG_UPDATE_DELAYED" then
				_G.PaperDollItemSlotButton_Update(self)
				self:SetBackdropBorderColor(module:RGBA("Border"))
			elseif event == "INVENTORY_SEARCH_UPDATE" then
				self:SetMatchesSearch(not IsContainerFiltered(self.id));
			else
				PaperDollItemSlotButton_OnEvent(self, event, ...)
			end
		end)
		-- OnShow/OnHide are just a bunch of update
		button:SetScript("OnShow", PaperDollItemSlotButton_OnShow)
		button:SetScript("OnHide", PaperDollItemSlotButton_OnHide)
		button:SetScript("OnDragStart", function(self) PickupBagFromSlot(self.inventoryID) end)
		button:SetScript("OnReceiveDrag", function(self) PutItemInBag(self.inventoryID) end)
	elseif button.container == "Bank" then
		button:SetID(id-5)
		button.invSlotName = "BAG"..id-5
		button.GetInventorySlot = _G.ButtonInventorySlot;
		button.UpdateTooltip = _G.BankFrameItemButton_OnEnter
		button.inventoryID = button:GetInventorySlot()
		button:RegisterEvent("PLAYERBANKBAGSLOTS_CHANGED")

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
	local _, slotTextureName = GetInventorySlotInfo(button.invSlotName)

	if textureName then
		texture:SetTexture(textureName)
	elseif slotTextureName then
		--If no bag texture is found, show empty slot.
		texture:SetTexture(slotTextureName)
	end

	button:SetBackdropBorderColor(module:RGBA("Border"))

	texture:Show()
end
