-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Bags
local module = LUI:GetModule("Bags")

local GetNumWatchedTokens = _G.GetNumWatchedTokens
local GetMoneyString = _G.GetMoneyString
local C_CurrencyInfo = C_CurrencyInfo
local C_Container = C_Container
local GetMoney = _G.GetMoney


-- Constants
local BAG_SLOT_TEMPLATE = "ContainerFrameItemButtonTemplate"
local BAG_SLOT_NAME_FORMAT = "LUIBags_Item%d_%d"
local CURRENCY_FORMAT = "%d\124T%s:0:0:3:0\124t"
local BAG_BAGBAR_NAME_FORMAT = "LUIBags_Bag%d"
local titleBarEvents = {
	"PLAYER_MONEY",
	"PLAYER_LOGIN",
	"PLAYER_TRADE_MONEY",
	"TRADE_MONEY_CHANGED",
	"CURRENCY_DISPLAY_UPDATE",
	"PLAYER_TRADE_CURRENCY",
	"TRADE_CURRENCY_CHANGED",
}

-- ####################################################################################################################
-- ##### Bag Container Object #########################################################################################
-- ####################################################################################################################

local Bags = {
	--Constants
	NUM_BAG_IDS = 5,
	BAG_ID_LIST = {
		Enum.BagIndex.Backpack,
		Enum.BagIndex.Bag_1,
		Enum.BagIndex.Bag_2,
		Enum.BagIndex.Bag_3,
		Enum.BagIndex.Bag_4,
	},

	-- vars
	name = "Bags",
}

table.insert(Bags.BAG_ID_LIST, Enum.BagIndex.ReagentBag)
Bags.NUM_BAG_IDS = 6

function Bags:Layout()
	self:UpdateCurrencies()
end

function Bags:NewItemSlot(id, slot)

	if self.itemList[id] and self.itemList[id][slot] then
		return self.itemList[id][slot]
	end

	local name = string.format(BAG_SLOT_NAME_FORMAT, id, slot)
	local itemSlot = module:CreateSlot(name, self.bagList[id], BAG_SLOT_TEMPLATE)

	-- id/slot info is a pain to get through template's means, make it easier
	itemSlot.id = id
	itemSlot.slot = slot
	-- SetID refers to the slot number within the bag, used by template's functions.
	itemSlot:SetID(slot)
	itemSlot:SetBagID(id)
	itemSlot:RegisterBagButtonUpdateItemContextMatching()
	itemSlot:Show()

	--Set properties
	self:SetItemSlotProperties(itemSlot)
	return itemSlot
end

-- ####################################################################################################################
-- ##### Bag Container: Title Bar #####################################################################################
-- ####################################################################################################################

function Bags:ShowTitleBar()
	self.gold:Show()
	self.currency:Show()
end

function Bags:HideTitleBar()
	self.gold:Hide()
	self.currency:Hide()
end

function Bags:CreateTitleBar()
	local gold = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
	gold:SetJustifyH("RIGHT")
	gold:SetPoint("RIGHT", self.closeButton, "LEFT", -3, 0)
	module:RefreshBagFontString(gold, "Bags")

	-- Watched Currency Display, next to gold
	local currency = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
	currency:SetJustifyH("RIGHT")
	currency:SetPoint("RIGHT", gold, "LEFT", -25, 0)
	currency:SetText(self:GetCurrencyString())
	module:RefreshBagFontString(currency, "Bags")

	local updateFunc = function() self:UpdateCurrencies() end
	self:SetScript("OnEvent", updateFunc)
	self:RegisterTitleBarEvents()

	self.gold = gold
	self.currency = currency
end

function Bags:RegisterTitleBarEvents()
	for _, event in ipairs(titleBarEvents) do
		self:RegisterEvent(event)
	end
end

local currencyString = {}
function Bags:GetCurrencyString()
	table.wipe(currencyString)
	for i = 1, GetNumWatchedTokens() do
		local data = C_CurrencyInfo.GetBackpackCurrencyInfo(i)
		if data and data.name then
			currencyString[i] = string.format(CURRENCY_FORMAT, data.quantity, data.iconFileID)
		end
	end
	return table.concat(currencyString, "  ")
end

function Bags:UpdateCurrencies()
	self.gold:SetText(GetMoneyString(GetMoney(), true))
	self.currency:SetText(self:GetCurrencyString())
end

-- ####################################################################################################################
-- ##### Bag Container: Toolbars ######################################################################################
-- ####################################################################################################################

function Bags:CreateBagBar()
	-- Starting at 2 because we don't need backpack on the BagBar
	for i = 2, self.NUM_BAG_IDS do
		local id = self.BAG_ID_LIST[i]
		local name = string.format(BAG_BAGBAR_NAME_FORMAT, id)
		-- index must starts at 0, but we start the loop at 2.
		local bagsSlot = module:BagBarSlotButtonTemplate(i - 2, id, name, self.bagsBar)
		self.bagsBar.slotList[i-1] = bagsSlot

		bagsSlot:Show()
	end
end

function Bags:CreateUtilBar()
	local utilBar = self.utilBar

	--CleanUp
	local button = module:CreateCleanUpButton("LUIBags_CleanUp", utilBar, function() module:SortBags() end)
	utilBar:AddNewButton(button)
	module:CreateKeyringButton(utilBar)
end

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

function module.OpenBags()
	if _G.ContainerFrame_AllowedToOpenBags and not _G.ContainerFrame_AllowedToOpenBags() then
		return
	end
	LUIBags:Open()
end

function module.CloseBags()
	LUIBags:Close()
end

function module.ToggleBags()
	if _G.ContainerFrame_AllowedToOpenBags and not _G.ContainerFrame_AllowedToOpenBags() then
		return
	end
	if LUIBags:IsShown() then
		module.CloseBags()
	else
		module.OpenBags()
	end
end

-- Both clients open bags before protected bank initialization. Replacing any
-- nested bag global taints bank selection, free-slot purchases and item clicks.
-- Keep those functions intact and handle their open/close requests separately.
local nativeBagParents = {}
local nativeBagFrames = {}
local nativeBagHolder
local nativeBagHooksEnabled = false
local nativeBagSyncTimer
local nativeBagRequestedOpen

local function HideNativeBagFrames()
	for frame in pairs(nativeBagParents) do
		frame:Hide()
	end
end

local function SyncNativeBags()
	nativeBagSyncTimer = nil
	if not nativeBagHooksEnabled then return end
	local shown = nativeBagRequestedOpen
	nativeBagRequestedOpen = nil
	if shown ~= LUIBags:IsShown() then
		if shown then module.OpenBags() else module.CloseBags() end
	end
	-- A coalesced close or a rejected open may leave LUI hidden throughout,
	-- so its OnHide cannot clear native bags that still report IsShown().
	if not LUIBags:IsShown() then HideNativeBagFrames() end
end

local function QueueNativeBagSync(shown)
	if not nativeBagHooksEnabled then return end
	nativeBagRequestedOpen = shown
	if not nativeBagSyncTimer then
		-- OpenAllBags and ToggleBackpack call other hooked bag functions. Apply
		-- only the outermost request, once, after that call chain has finished.
		nativeBagSyncTimer = C_Timer.NewTimer(0, SyncNativeBags)
	end
end

local function RequestNativeBagOpen()
	if ContainerFrame_AllowedToOpenBags() then QueueNativeBagSync(true) end
end

local function RequestNativeBagClose()
	QueueNativeBagSync(false)
end

local function RequestNativeBagToggle()
	if ContainerFrame_AllowedToOpenBags() then
		QueueNativeBagSync(not LUIBags:IsShown())
	end
end

local function SuppressNativeBagFrame(frame)
	if not frame then return end
	nativeBagFrames[frame] = true
	-- Forever uses the same container pool for its native keyring. A frame
	-- reused for keys must remain visible under its current native parent.
	if LUI.IsForever and frame.GetBagID and frame:GetBagID() == Enum.BagIndex.Keyring then
		local parent = nativeBagParents[frame]
		if parent then
			if frame:GetParent() == nativeBagHolder then frame:SetParent(parent) end
			nativeBagParents[frame] = nil
		end
		return
	end
	local parent = frame:GetParent()
	if parent ~= nativeBagHolder then
		nativeBagParents[frame] = parent
		-- Keep native rendering and per-frame updates inactive. Do not replace
		-- native methods or write their Lua state while suppressing the frames.
		frame:SetParent(nativeBagHolder)
	end
end

local function SuppressNativeBagFrames()
	if not nativeBagHooksEnabled then return end
	for i = 1, NUM_CONTAINER_FRAMES do
		SuppressNativeBagFrame(_G["ContainerFrame"..i])
	end
	SuppressNativeBagFrame(_G.ContainerFrameCombinedBags)
end

function module:EnableNativeBagHooks()
	if not nativeBagHolder then
		nativeBagHolder = CreateFrame("Frame", nil, UIParent)
		nativeBagHolder:Hide()
	end
	nativeBagHooksEnabled = true
	SuppressNativeBagFrames()
	-- Reparenting an open native bag makes it invisible, not closed. ESC
	-- would otherwise consume its first press closing that hidden window.
	if not LUIBags:IsShown() then HideNativeBagFrames() end

	for name, handler in pairs({
		ToggleBackpack = RequestNativeBagToggle,
		ToggleAllBags = RequestNativeBagToggle,
		OpenBackpack = RequestNativeBagOpen,
		OpenAllBags = RequestNativeBagOpen,
		CloseBackpack = RequestNativeBagClose,
		CloseAllBags = RequestNativeBagClose,
	}) do
		if type(_G[name]) == "function" then
			module:SecureHook(name, handler)
		end
	end
	for name, handler in pairs({ToggleBag = RequestNativeBagToggle, OpenBag = RequestNativeBagOpen, CloseBag = RequestNativeBagClose}) do
		local request = handler
		module:SecureHook(name, function(id)
			if module:IsCharacterBag(id) then request() end
		end)
	end
	for _, name in ipairs({"ContainerFrame_SetFullScreenFrame", "ContainerFrame_ClearFullScreenFrame"}) do
		if type(_G[name]) == "function" then
			module:SecureHook(name, SuppressNativeBagFrames)
		end
	end
	if LUI.IsForever and type(_G.ContainerFrame_GenerateFrame) == "function" then
		module:SecureHook("ContainerFrame_GenerateFrame", function(frame)
			if nativeBagHooksEnabled and nativeBagFrames[frame] then SuppressNativeBagFrame(frame) end
		end)
	end
	module:SecureHookScript(LUIBags, "OnHide", function()
		if not LUIBags:IsShown() then
			-- Do not call CloseAllBags here: it writes Blizzard's bag-opener
			-- upvalue from addon code. These hidden children need only C Hide().
			HideNativeBagFrames()
		end
	end)
end

function module:DisableNativeBagHooks()
	nativeBagHooksEnabled = false
	nativeBagRequestedOpen = nil
	if nativeBagSyncTimer then
		nativeBagSyncTimer:Cancel()
		nativeBagSyncTimer = nil
	end
	-- Hide before restoring parents so native windows do not flash on disable.
	HideNativeBagFrames()
	for frame, parent in pairs(nativeBagParents) do
		frame:SetParent(parent)
		nativeBagParents[frame] = nil
	end
end

-- Expose the character-bag descriptor to the shared container factory.
module.BagsContainer = Bags
