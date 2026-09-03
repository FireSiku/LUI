-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Bags
local module = LUI:GetModule("Bags")

local GetInventoryItemTexture = _G.GetInventoryItemTexture
local GameTooltip_SetTitle = _G.GameTooltip_SetTitle
local PickupBagFromSlot = _G.PickupBagFromSlot
local PutItemInBag = _G.PutItemInBag
local ResetCursor = _G.ResetCursor

local BAGINDEX_BACKPACK = Enum.BagIndex.Backpack or 0

--luacheck: globals PaperDollItemSlotButton_OnEvent PaperDollItemSlotButton_OnShow PaperDollItemSlotButton_OnHide
--luacheck: globals BagSlotButton_OnEnter

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

--- Create a toolbar for a given container
---@param container ContainerMixin
---@param name string
function module:CreateToolBar(container, name)
	local toolBar = CreateFrame("Frame", nil, container)
	toolBar:SetClampedToScreen(true)
	toolBar:SetSize(1,1)

	local bgFrame = CreateFrame("Frame", nil, toolBar)
	--Force it to the lowest frame level to prevent layering issues
	bgFrame:SetFrameLevel(toolBar:GetParent():GetFrameLevel())
	bgFrame:SetClampedToScreen(true)

	LUI:ApplyFrameBackdrop(bgFrame, module.bagBackdrop)
	LUI:SetFrameBackgroundColor(bgFrame, module:RGBA("Background"))
	LUI:SetFrameBorderColor(bgFrame, module:RGBA("Border"))

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
-- ####################################################################################################################
-- ##### Templates: Bag Bar Filter Menu ##############################################################################
-- ####################################################################################################################
local function ShowBagFilterMenu(owner)
	local bagID = owner:GetBagID()
	if not ContainerFrame_CanContainerUseFilterMenu(bagID) then return end

	MenuUtil.CreateContextMenu(owner, function(_, rootDescription)
		rootDescription:CreateTitle(BAG_FILTER_ASSIGN_TO)
		for _, flag in ContainerFrameUtil_EnumerateBagGearFilters() do
			local filterFlag = flag
			local function IsSelected()
				return C_Container.GetBagSlotFlag(bagID, filterFlag)
			end
			local function SetSelected()
				local value = not IsSelected()
				C_Container.SetBagSlotFlag(bagID, filterFlag, value)
				ContainerFrameSettingsManager:SetFilterFlag(bagID, filterFlag, value)
			end
			local checkbox = rootDescription:CreateCheckbox(BAG_FILTER_LABELS[filterFlag], IsSelected, SetSelected)
			checkbox:SetResponse(MenuResponse.Close)
		end

		rootDescription:CreateDivider()
		rootDescription:CreateTitle(BAG_FILTER_IGNORE)

		do
			local flag = Enum.BagSlotFlags.DisableAutoSort
			local function IsSelected()
				return C_Container.GetBagSlotFlag(bagID, flag)
			end
			local function SetSelected()
				C_Container.SetBagSlotFlag(bagID, flag, not IsSelected())
			end
			local checkbox = rootDescription:CreateCheckbox(BAG_FILTER_CLEANUP, IsSelected, SetSelected)
			checkbox:SetResponse(MenuResponse.Close)
		end

		do
			local flag = Enum.BagSlotFlags.ExcludeJunkSell
			local function IsSelected()
				return C_Container.GetBagSlotFlag(bagID, flag)
			end
			local function SetSelected()
				C_Container.SetBagSlotFlag(bagID, flag, not IsSelected())
			end
			local checkbox = rootDescription:CreateCheckbox(SELL_ALL_JUNK_ITEMS_EXCLUDE_FLAG, IsSelected, SetSelected)
			checkbox:SetResponse(MenuResponse.Close)
		end
	end)
end

-- ####################################################################################################################
-- ##### Templates: BagBar Slot Button ################################################################################
-- ####################################################################################################################
--- Called when the mouse enters a BagBar slot button.
---@param self ItemButton
local function BarBarSlotOnEnter(self)
	_G.EventRegistry:TriggerEvent("BagSlot.OnEnter", self)
	GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
	
	local bagId = self:GetBagID()
	if bagId == BAGINDEX_BACKPACK then
        GameTooltip_SetTitle(GameTooltip, BACKPACK_TOOLTIP)
    else
        local hasItem = GameTooltip:SetInventoryItem('player', self.inventoryID)
        if not hasItem then
            if bagId == Enum.BagIndex.ReagentBag then
                GameTooltip_SetTitle(GameTooltip, EQUIP_CONTAINER_REAGENT)
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

	button:SetScript("OnClick", function(self, btn)
		local bagID = self:GetBagID()
		if btn == "RightButton" then
			ShowBagFilterMenu(self)
		elseif CursorHasItem() and not self.purchaseCost then
			PutItemInBag(self.inventoryID)
		elseif bagID ~= Enum.BagIndex.Backpack then
			PickupBagFromSlot(self.inventoryID)
		end
	end)
	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
		ResetCursor()
		_G.EventRegistry:TriggerEvent("BagSlot.OnLeave", button)
	end)
	button:SetScript("OnEnter", BarBarSlotOnEnter)

	-- PaperDollItemSlotButton_OnLoad
	button.inventoryID = C_Container.ContainerIDToInventoryID(id)
	button:SetID(button.inventoryID)

	local texture = _G[name.."IconTexture"]
	local textureName = GetInventoryItemTexture("player", button.inventoryID)
	texture:SetTexture(textureName)

	button:RegisterEvent("INVENTORY_SEARCH_UPDATE")
	button.UpdateTooltip = BagSlotButton_OnEnter
	button.IconBorder:SetTexture("")
	button.IconBorder:SetSize(1,1)

	button:SetScript("OnEvent", function(self, event, ...)
		if event == "BAG_UPDATE_DELAYED" then
			_G.PaperDollItemSlotButton_Update(self)
			LUI:SetFrameBorderColor(self, module:RGBA("Border"))
		elseif event == "INVENTORY_SEARCH_UPDATE" then
			self:SetMatchesSearch(not C_Container.IsContainerFiltered(self.id));
		else
			PaperDollItemSlotButton_OnEvent(self, event, ...)
		end
	end)
	button:SetScript("OnShow", PaperDollItemSlotButton_OnShow)
	button:SetScript("OnHide", PaperDollItemSlotButton_OnHide)
	button:SetScript("OnDragStart", function(self) PickupBagFromSlot(self.inventoryID) end)
	button:SetScript("OnReceiveDrag", function(self) PutItemInBag(self.inventoryID) end)

	return button
end
