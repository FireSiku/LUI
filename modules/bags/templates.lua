-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Bags
local module = LUI:GetModule("Bags")

local PlaySound = _G.PlaySound

local CLEANUP_TEXTURE_ATLAS = "bags-button-autosort-up"
local CLEANUP_SOUND = _G.SOUNDKIT.UI_BAG_SORTING_01

local SEARCH = _G.SEARCH

--luacheck: globals BAG_CLEANUP_BAGS
-- ####################################################################################################################
-- ##### Templates: CleanUp Button ####################################################################################
-- ####################################################################################################################

local CLEANUP_TEXT = {
	LUIBags_CleanUp = BAG_CLEANUP_BAGS,
}

function module:CreateCleanUpButton(name, parent, sortFunc)
	local button = module:CreateSlot(name, parent, "")
	button:SetScript("OnClick", function()
			PlaySound(CLEANUP_SOUND)
			sortFunc()
		end)
	button:SetScript("OnEnter", function()
			if LUI:TooltipHasWidgets(GameTooltip) then return end
			GameTooltip:SetOwner(button)
			GameTooltip:SetText(CLEANUP_TEXT[name])
			GameTooltip:Show()
		end)
	button:SetScript("OnLeave", _G.GameTooltip_Hide)

	button.icon:SetAtlas(CLEANUP_TEXTURE_ATLAS)

	return button
end

-- ####################################################################################################################
-- ##### Templates: Search Bar ########################################################################################
-- ####################################################################################################################

function module:CreateSearchBar(container)
	local db = container:GetDB() or {}

	-- Search Text
	local search = container:CreateFontString(nil, "OVERLAY", "GameFonthighlightLarge")
	local searchText = SEARCH
	search:SetPoint("TOPLEFT", container, tonumber(db.Padding) or 0, -10)
	search:SetPoint("TOPRIGHT", -40, 0)
	search:SetJustifyH("LEFT")
	search:SetText(searchText)
	local searchR, searchG, searchB, searchA = module:RGBA("Search")
	if searchR and searchG and searchB then
		search:SetTextColor(searchR, searchG, searchB, searchA or 1)
	end

	-- Search Editbox
	local editbox = CreateFrame("EditBox", nil, container)
	module:RefreshBagFontString(editbox, "Bags")
	
	editbox:SetHeight(32)
	editbox:SetAutoFocus(false)
	editbox:SetMaxLetters((tonumber(db.RowSize) or 16) * 5)
	editbox:SetTextInsets(24, 0, 0, 0)
	editbox:SetAllPoints(search)
	editbox:Hide()

	-- Editbox scripts
	editbox:SetScript("OnEscapePressed", editbox.ClearFocus)
	editbox:SetScript("OnEnterPressed", editbox.ClearFocus)
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

	button:SetScript("OnClick", function()
		container:HideTitleBar()
		container.editbox:Show()
		container.clear:Show()
		container.editbox:SetFocus()
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
