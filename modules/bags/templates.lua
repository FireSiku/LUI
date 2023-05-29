-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Bags
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
-- ##### Templates: CleanUp Button ####################################################################################
-- ####################################################################################################################

local CLEANUP_TEXT = {
	LUIBags_CleanUp = BAG_CLEANUP_BAGS,
	LUIBank_CleanUp = BAG_CLEANUP_BANK,
	LUIReagent_CleanUp = BAG_CLEANUP_REAGENT_BANK,
}

function module:CreateCleanUpButton(name, parent, sortFunc)
	local button = module:CreateSlot(name, parent, "")
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
	local db = module.db.profile.Bags

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
