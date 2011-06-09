--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: bags.lua
	Description: Bags Module
	Version....: 1.3.2
	Rev Date...: 27/04/11 [dd/mm/yy]

	Edits:
		v1.0: Loui
		-  a: Chaoslux
		v1.1: Chaoslux
		v1.2: Chaoslux
		v1.3: Chaoslux
		v1.3.1: Xolsom (Stack & Sort Function)
		v1.3.2: Xolsom (WoW 4.1 Fix)

	A featureless, 'pure' version of Stuffing.
	This version should work on absolutely everything,
	but I've removed pretty much all of the options.
]]

local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local LSM = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists
local module = LUI:NewModule("Bags", "AceHook-3.0", "AceEvent-3.0")

local db
local GetBags = {
	["Bags"] = {0, 1, 2, 3, 4},
	["Bank"] = {-1, 5, 6, 7, 8, 9, 10, 11},
}
local isCreated = {}

--localized API
local _G = getfenv(0)
local tinsert = table.insert
local tremove = table.remove
local strlower = string.lower
local strfind = string.find
local strsub = string.sub
local format = format
local pairs, ipairs = pairs, ipairs

local MAX_WATCHED_TOKENS = MAX_WATCHED_TOKENS

local GetItemInfo = GetItemInfo
local GetKeyRingSize = GetKeyRingSize
local GetMoneyString = GetMoneyString
local GetContainerNumSlots = GetContainerNumSlots
local GetContainerItemInfo = GetContainerItemInfo
local GetContainerItemLink = GetContainerItemLink
local GetBackpackCurrencyInfo = GetBackpackCurrencyInfo
local GetContainerItemCooldown = GetContainerItemCooldown
local GetContainerNumFreeSlots = GetContainerNumFreeSlots

local CreateFrame = CreateFrame
local OpenEditbox = OpenEditbox
local SetItemButtonCount = SetItemButtonCount
local SetItemButtonTexture = SetItemButtonTexture
local SetItemButtonDesaturated = SetItemButtonDesaturated

local BankFrameItemButton_Update = BankFrameItemButton_Update
local BankFrameItemButton_UpdateLocked = BankFrameItemButton_UpdateLocked

-- Constants. Do NOT Edit those.
local ST_NORMAL = 1	--Flagged for possible deletion
local ST_SPECIAL = 3	--Flagged for possible deletion
local bagTexSize = 30

--Wonder about new names for those. Or if their purpose is justified.
local trashButton = {}
local trashBag = {}

local LUIBags, LUIBank		-- replace self.frame and self.bankframe

--Cache tables.
local BagsInfo = {}		--replace self.bags
local ItemSlots = {}		--replace self.buttons
local BagsSlots = {}		--replace self.bagsframe_buttons

--Tooltip Frame for to scan item tooltips.
--At the moment, not sure if tooltip scanning is required.
--local LUIBagsTT = nil

-- hide bags options in default interface
InterfaceOptionsDisplayPanelShowFreeBagSpace:Hide()
--Making sure the Static Popup uses the good args.
StaticPopupDialogs["CONFIRM_BUY_BANK_SLOT"] = {
	text = CONFIRM_BUY_BANK_SLOT,
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		PurchaseSlot();
	end,
	OnShow = function(self)
		MoneyFrame_Update(self.moneyFrame, LUIBank.bankCost);
	end,
	hasMoneyFrame = 1,
	timeout = 0,
	hideOnEscape = 1,
};

--This function returns the correct variable for the bag type.
local function LUIBags_Select(bag)
	if bag == "Bank" and LUIBank then return LUIBank end
	if bag == "Bags" and LUIBags then return LUIBags end
end

local function LUIBags_OnShow()
	module:PLAYERBANKSLOTS_CHANGED(self, 29)	-- XXX: hack to force bag frame update
	module:ReloadLayout("Bags")
	module:SearchReset()

	module:RegisterEvent("BAG_UPDATE")
	module:RegisterEvent("PLAYERBANKBAGSLOTS_CHANGED")
	module:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
	module:RegisterEvent("BAG_CLOSED")
	module:RegisterEvent("ITEM_LOCK_CHANGED")
end

local function LUIBank_OnHide()
	CloseBankFrame()
end

local function LUIBags_OnHide()  -- Close the Bank if Bags are closed.
	if LUIBank and LUIBank:IsShown() then
		LUIBank:Hide()
	end

	module:UnregisterEvent("BAG_UPDATE")
	module:UnregisterEvent("PLAYERBANKBAGSLOTS_CHANGED")
	module:UnregisterEvent("PLAYERBANKSLOTS_CHANGED")
	module:UnregisterEvent("BAG_CLOSED")
	module:UnregisterEvent("ITEM_LOCK_CHANGED")
end

local function LUIBags_Open()
	LUIBags:Show()
end

local function LUIBags_Close()
	LUIBags:Hide()
end

local function LUIBags_Toggle(forceOpen)
	if LUIBags:IsShown() and not forceOpen then
		LUIBags:Hide()
		--LUI:Print("Closing Bags")
	else
		LUIBags:Show()
		--LUI:Print("OPening Bags")
	end
end

local function LUIBags_ToggleBag(id)
	if id == -2 then
		ToggleKeyRing()
		return
	end
	LUIBags_Toggle()
end

local function LUIBags_StartMoving(self)
	self:StartMoving()
end

local function LUIBags_StopMoving(self)
	self:StopMovingOrSizing()
	self:SetUserPlaced(false)

	local x, y = self:GetCenter()

	-- Get rid of the "LUI" in the frame name, leaving Bags or Bank
	local bag = strsub(self:GetName(), 4)
	db.Bags[bag].CoordX = x
	db.Bags[bag].CoordY = y
end

function module:InitSelect(bag)
	if bag == "Bank" and not LUIBank then module:InitBank() end
	if bag == "Bags" and not LUIBags then module:InitBags() end
end

function module:SlotUpdate(item)
	if not LUIBags:IsShown() then return end -- don't do any slot update if bags are not shown
	local texture, count, locked = GetContainerItemInfo(item.bag, item.slot)
	local clink = GetContainerItemLink(item.bag, item.slot)
	local color = db.Bags.Colors.Border

	if not item.frame.lock then
		item.frame:SetBackdropBorderColor(color.r, color.g, color.b, color.a)

		--Check for Profession Bag
		local bagType = module:BagType(item.bag)
		if (bagType == ST_SPECIAL) then
			local color = db.Bags.Colors.Professions
			item.frame:SetBackdropBorderColor(color.r, color.g, color.b, color.a)
		end

	end

	if item.Cooldown then
		local cd_start, cd_finish, cd_enable = GetContainerItemCooldown(item.bag, item.slot)
		CooldownFrame_SetTimer(item.Cooldown, cd_start, cd_finish, cd_enable)
	end

	if (clink) then
		local iType
		item.name, _, item.rarity, _, _, iType = GetItemInfo(clink)
		-- color slot according to item quality
		if db.Bags.Bags.ItemQuality and not item.frame.lock and item.rarity and item.rarity > 1 then
			item.frame:SetBackdropBorderColor(GetItemQualityColor(item.rarity))
		end
		if db.Bags.Bags.ShowQuest and not item.frame.lock and iType == "Quest" then
			local color = db.Bags.Colors.Quest
			item.frame:SetBackdropBorderColor(color.r, color.g, color.b, color.a)
		end
	else
		item.name, item.rarity = nil, nil
	end

	SetItemButtonTexture(item.frame, texture)
	SetItemButtonCount(item.frame, count)
	SetItemButtonDesaturated(item.frame, locked, 0.5, 0.5, 0.5)

	item.frame:Show()
end

function module:BagSlotUpdate(bag)
	if not ItemSlots then
		return
	end

	for _, item in ipairs(ItemSlots) do
		if item.bag == bag then
			module:SlotUpdate(item)
		end
	end
	if bag >= 0 and bag <= 4 then
		if LUIBags and LUIBags:IsShown() then
			module:ReloadLayout("Bags")
		end
	end
end

function module:BagFrameSlotNew(slot, parent)
	--Check if the slot doesnt already exist
	for _, v in ipairs(BagsSlots) do
		if v.slot == slot then
			--found the slot, return in.
			return v, false
		end
	end

	--Make a new slot.
	local ret = {}
	local template

	if slot > 3 then
		ret.slot = slot
		slot = slot - 4
		template = "BankItemButtonBagTemplate"
		ret.frame = CreateFrame("CheckButton", "LUIBank__Bag"..slot, parent, template)
		ret.frame:SetID(slot + 4)
		tinsert(BagsSlots, ret)

		BankFrameItemButton_Update(ret.frame)
		BankFrameItemButton_UpdateLocked(ret.frame)

		if not ret.frame.tooltipText then
			ret.frame.tooltipText = ""
		end
	else
		template = "BagSlotButtonTemplate"
		ret.frame = CreateFrame("CheckButton", "LUIBags__Bag"..slot.."Slot", parent, template)
		ret.slot = slot
		tinsert(BagsSlots, ret)
	end

	--Fix the size of the bag button
	local bagBigTexSize = bagTexSize * 1.65 -- Number found through trial and error. This give the best results.
	ret.frame:SetSize(bagTexSize, bagTexSize)
	_G[ret.frame:GetName() .. "NormalTexture"]:SetSize(bagBigTexSize,bagBigTexSize)
	_G[ret.frame:GetName() .. "IconTexture"]:SetSize(bagBigTexSize,bagBigTexSize)

	return ret
end

function module:SlotNew(bag, slot)
	for _, v in ipairs(ItemSlots) do
		if v.bag == bag and v.slot == slot then
			return v, false
		end
	end

	local template = "ContainerFrameItemButtonTemplate"

	if bag == -1 then
		template = "BankItemButtonGenericTemplate"
	end

	local ret = {}

	if #trashButton > 0 then
		local f = -1
		for i, v in ipairs(trashButton) do
			local b, s = v:GetName():match("(%d+)_(%d+)")

			b = tonumber(b)
			s = tonumber(s)

			--print (b .. " " .. s)
			if b == bag and s == slot then
				f = i
				break
			end
		end

		if f ~= -1 then
			--print("found it")
			ret.frame = trashButton[f]
			table.remove(trashButton, f)
		end
	end

	if not ret.frame then
		ret.frame = CreateFrame("Button", "LUIBags_Item" .. bag .. "_" .. slot, BagsInfo[bag], template)
	end

	ret.bag = bag
	ret.slot = slot
	ret.frame:SetID(slot)

	ret.Cooldown = _G[ret.frame:GetName() .. "Cooldown"]
	ret.Cooldown:Show()

	self:SlotUpdate(ret)

	return ret, true
end

function module:BagType(bag)
	--From OneBag. Still wondering the use of those.
	local bagProfession = 0x0008 + 0x0010 + 0x0020 + 0x0040 + 0x0080 + 0x0200 + 0x0400
	local bagType = select(2, GetContainerNumFreeSlots(bag))

	if bit.band(bagType, bagProfession) > 0 then
		return ST_SPECIAL
	end

	return ST_NORMAL
end

function module:BagNew(bag, frame)
	for _, v in pairs(BagsInfo) do
		if v:GetID() == bag then
			v.bagType = module:BagType(bag)
			return v
		end
	end

	local ret

	if #trashBag > 0 then
		local f = -1
		for i, v in pairs(trashBag) do
			if v:GetID() == bag then
				frame = i
				break
			end
		end

		if frame ~= -1 then
			--LUI:Print("found bag " .. bag)
			if type(frame) ~= "number" then frame = 1 end -- sometimes, frame ends up being a table instead of a number.
			ret = trashBag[frame]
			tremove(trashBag, frame)
			ret:Show()
			ret.bagType = module:BagType(bag)
			return ret
		end
	end

	--LUI:Print("new bag " .. bag)
	ret = CreateFrame("Frame", "LUIBag" .. bag, frame)
	ret.bagType = module:BagType(bag)

	ret:SetID(bag)
	return ret
end

function module:SearchUpdate(str)
	str = strlower(str)

	for _, b in ipairs(ItemSlots) do
		if b.frame and not b.name then
			b.frame:SetAlpha(.2)
		end
		if b.name then
			if not strfind(strlower(b.name), str) then
				SetItemButtonDesaturated(b.frame, 1, 1, 1, 1)
				b.frame:SetAlpha(.2)
			else
				SetItemButtonDesaturated(b.frame, 0, 1, 1, 1)
				b.frame:SetAlpha(1)
			end
		end
	end
end

function module:SearchReset()
	for _, item in ipairs(ItemSlots) do
		item.frame:SetAlpha(1)
		SetItemButtonDesaturated(item.frame, 0, 1, 1, 1)
	end
end

function module:CreateBagFrame(bagType)
	local frameName = "LUI"..bagType -- LUIBags, LUIBank
	local frame = CreateFrame("Frame", frameName, UIParent)
	frame:EnableMouse(1)
	frame:SetMovable(1)
	frame:SetToplevel(1)
	frame:SetFrameStrata("HIGH")
	frame:SetFrameLevel(20)

	if db.Bags[bagType].Locked == 0 then
		frame:SetScript("OnMouseDown", LUIBags_StartMoving)
		frame:SetScript("OnMouseUp", LUIBags_StopMoving)
	end

	local x = db.Bags[bagType].CoordX or 0
	local y = db.Bags[bagType].CoordY or 0
	frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)

	--Close Button, no embed options anymore.
	local closeBtn = CreateFrame("Button", frameName.."_CloseButton", frame, "UIPanelCloseButton")
	closeBtn:SetWidth(LUI:Scale(32))
	closeBtn:SetHeight(LUI:Scale(32))
	closeBtn:SetPoint("TOPRIGHT", LUI:Scale(-3), LUI:Scale(-3))
	closeBtn:SetScript("OnClick", function(self, button)
		self:GetParent():Hide()
	end)
	closeBtn:RegisterForClicks("AnyUp")
	closeBtn:GetNormalTexture():SetDesaturated(1)
	frame.closeButton = closeBtn

	-- Bag Frame
	local bagsFrame = CreateFrame("Frame", frameName.."_BagsFrame", frame)
	bagsFrame:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, LUI:Scale(2))
	bagsFrame:SetFrameStrata("HIGH")
	frame.BagsFrame = bagsFrame

	-- Sort Button
	local sortBtn = CreateFrame("Button", frameName.."_SortButton", frame, "UIPanelButtonTemplate")
	sortBtn:SetText("Stack & Sort");
	sortBtn:SetWidth(LUI:Scale(sortBtn:GetTextWidth()+20))
	sortBtn:SetHeight(LUI:Scale(sortBtn:GetTextHeight()+10))
	sortBtn:SetPoint("BOTTOMRIGHT", LUI:Scale(-3), LUI:Scale(3))
	sortBtn:SetScript("OnClick", function(self, button)
		module:PrepareSort(self:GetParent());
	end)
	sortBtn:RegisterForClicks("AnyUp")
	frame.sortButton = sortBtn

	return frame
end

function module:InitBank()
	if LUIBank then
		return
	end

	LUIBank = self:CreateBagFrame("Bank")
	LUIBank:SetScript("OnHide", LUIBank_OnHide)
end

local GetParent_StartMoving = function(self)
	LUIBags_StartMoving(self:GetParent())
end

local GetParent_StopMoving = function(self)
	LUIBags_StopMoving(self:GetParent())
end

-- Function to return a string containing tracked currencies.
local function GetTrackedCurrency()
	local currencyFormat = "%d\124T%s:%d:%d:2:0\124t"
	local currencyString = {}
	for i = 1, MAX_WATCHED_TOKENS do
		local name, count, icon = GetBackpackCurrencyInfo(i)
		if name ~= nil then
			currencyString[i] = format(currencyFormat,count,icon,0,0)
		end
	end
	local currencyReturn = ""
	for i = 1, #currencyString do
		currencyReturn = currencyReturn.."  "..currencyString[i]
	end
	return currencyReturn
end

function module:SetBags()
	if LUIBags then return end -- Bags are already setup.

	LUIBags = module:CreateBagFrame("Bags")
	LUIBags:SetScript("OnShow", LUIBags_OnShow)
	LUIBags:SetScript("OnHide", LUIBags_OnHide)

	-- Search Editbox
	local editbox = CreateFrame("EditBox", nil, LUIBags)
	editbox:Hide()
	editbox:SetAutoFocus(true)
	editbox:SetHeight(LUI:Scale(32))
	editbox:SetBackdrop( {
		bgFile = LUI_Media.blank,
		edgeFile = LUI_Media.blank,
		tile = false, edgeSize = 0,
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	})
	editbox:SetBackdropColor(0,0,0,0)
	editbox:SetBackdropBorderColor(0,0,0,0)

	local resetAndClear = function (self)
		self:GetParent().search:Show()
		self:GetParent().gold:Show()
		self:GetParent().currency:Show()
		self:ClearFocus()
		module:SearchReset()
	end

	local updateSearch = function(self, text)
		if text == true then
			module:SearchUpdate(self:GetText())
		end
	end

	editbox:SetScript("OnEscapePressed", resetAndClear)
	editbox:SetScript("OnEnterPressed", resetAndClear)
	editbox:SetScript("OnEditFocusLost", editbox.Hide)
	editbox:SetScript("OnEditFocusGained", editbox.HighlightText)
	editbox:SetScript("OnTextChanged", updateSearch)
	editbox:SetText("Search")

	--Search text
	local search = LUIBags:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
	search:SetPoint("TOPLEFT", LUIBags, LUI:Scale(db.Bags.Bags.Padding), LUI:Scale(-10))
	search:SetPoint("RIGHT", LUI:Scale(-(16 + 24)), 0)
	search:SetJustifyH("LEFT")
	search:SetText("|cff9999ff" .. "Search")
	editbox:SetAllPoints(search)

	--Gold Display, next to close button
	local gold = LUIBags:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
	gold:SetJustifyH("RIGHT")
	gold:SetPoint("RIGHT", LUIBags.closeButton, "LEFT", LUI:Scale(-3), 0)

	--Watched Currency Display, next to gold.
	local currency = LUIBags:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
	currency:SetJustifyH("RIGHT")
	currency:SetPoint("RIGHT", gold, "LEFT", LUI:Scale(-9), 0)

	LUIBags:SetScript("OnEvent", function(self, e) -- wtf is E? Found it: Elapsed time since last call
		self.gold:SetText(GetMoneyString(GetMoney(), 12))
		self.currency:SetText(GetTrackedCurrency())
	end)

	--Hooking this function allows to update watched currencies without a ReloadUI
	function module:BackpackTokenFrame_Update()
		currency:SetText(GetTrackedCurrency())
	end
	module:Hook("BackpackTokenFrame_Update", true)

	LUIBags:RegisterEvent("PLAYER_MONEY")
	LUIBags:RegisterEvent("PLAYER_LOGIN")
	LUIBags:RegisterEvent("PLAYER_TRADE_MONEY")
	LUIBags:RegisterEvent("TRADE_MONEY_CHANGED")
	LUIBags:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
	LUIBags:RegisterEvent("PLAYER_TRADE_CURRENCY")
	LUIBags:RegisterEvent("TRADE_CURRENCY_CHANGED")

	local OpenEditbox = function(self)
		self:GetParent().search:Hide()
		self:GetParent().gold:Hide()
		self:GetParent().currency:Hide()
		self:GetParent().editbox:Show()
		self:GetParent().editbox:HighlightText()
	end

	local button = CreateFrame("Button", nil, LUIBags)
	button:EnableMouse(1)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:SetAllPoints(search)
	button:SetScript("OnClick", function(self, btn)
		if btn == "RightButton" then
			OpenEditbox(self)
		else
			if self:GetParent().editbox:IsShown() then
				self:GetParent().editbox:Hide()
				self:GetParent().editbox:ClearFocus()
				self:GetParent().detail:Show()
				self:GetParent().gold:Show()
				self:GetParent().currency:Show()
				module:SearchReset()
			end
		end
	end)

	local tooltip_hide = function()
		GameTooltip:Hide()
	end

	local tooltip_show = function (self)
		GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
		GameTooltip:ClearLines()
		GameTooltip:SetText("Right-click to search.")
	end

	button:SetScript("OnEnter", tooltip_show)
	button:SetScript("OnLeave", tooltip_hide)

	button:SetScript("OnMouseDown", GetParent_StartMoving)
	button:SetScript("OnMouseUp", GetParent_StopMoving)

	LUIBags.editbox = editbox
	LUIBags.search = search
	LUIBags.button = button
	LUIBags.gold = gold
	LUIBags.currency = currency
	LUIBags:Hide()
end

function module:Layout(bagType)
	local frame = LUIBags_Select(bagType)
	local cols = db.Bags[bagType].Cols
	local bagId = GetBags[bagType]

	local slots = 0
	local rows = 0
	local off = 26

	local padding = db.Bags[bagType].Padding
	local spacing = db.Bags[bagType].Spacing
	local borderTex = LSM:Fetch("border", db.Bags[bagType].BorderTexture)
	local border_size = db.Bags[bagType].BorderSize
	local border_inset = db.Bags[bagType].BorderInset

	local color, bgcolor = db.Bags.Colors.Border, db.Bags.Colors.Background
	local border_color = { color.r, color.g, color.b, color.a }
	local background_color = { bgcolor.r, bgcolor.g, bgcolor.b, bgcolor.a }

	if not frame then
		module:InitSelect(bagType)
		frame = LUIBags_Select(bagType)
	end

	local isBank = false
	if bagType == "Bank" then
		isBank = true
	else
		frame.gold:SetText(GetMoneyString(GetMoney(), 12))
		frame.editbox:SetFont(LSM:Fetch("font", db.Bags.Bags.Font), 12)
		frame.search:SetFont(LSM:Fetch("font", db.Bags.Bags.Font), 12)
		frame.gold:SetFont(LSM:Fetch("font", db.Bags.Bags.Font), 12)
		frame.currency:SetFont(LSM:Fetch("font", db.Bags.Bags.Font), 12)

		frame.search:ClearAllPoints()
		frame.search:SetPoint("TOPLEFT", frame, LUI:Scale(db.Bags.Bags.Padding), LUI:Scale(-10))
		frame.search:SetPoint("RIGHT", LUI:Scale(-(16 + 24)), 0)
	end

	local bagsFrame = frame.BagsFrame
	if not isCreated[bagType] then
		frame:SetClampedToScreen(1)
		frame:SetBackdrop( {
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = borderTex,
			tile = false, edgeSize = 5,
			insets = { left = 3, right = 3, top = 3, bottom = 3 }
		})
		local fColor = { color.r *1.5, color.g *1.5, color.b *1.5, color.a}
		local fbgColor = { bgcolor.r /2, bgcolor.g /2, bgcolor.b /2, bgcolor.a}
		if db.Bags.Colors.BlackFrameBG then
			frame:SetBackdropColor(0.1, 0.1, 0.1, 1)
			frame:SetBackdropBorderColor(0.3, 0.3 ,0.3 ,1)
		else
			frame:SetBackdropColor(unpack(fbgColor))
			frame:SetBackdropBorderColor(unpack(fColor))
		end
		-- bag frame stuff

		bagsFrame:SetClampedToScreen(1)
		bagsFrame:SetBackdrop( {
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = borderTex,
			tile = false, edgeSize = 5,
			insets = { left = 3, right = 3, top = 3, bottom = 3 }
		})
		bagsFrame:SetBackdropColor(unpack(background_color))
		bagsFrame:SetBackdropBorderColor(unpack(border_color))

		local width = 2*padding + (#bagId - 1)*bagTexSize + spacing*(#bagId - 2)

		bagsFrame:SetHeight(LUI:Scale(2 * padding + bagTexSize))
		bagsFrame:SetWidth(LUI:Scale(width))

		local idx = 0
		for x, id in ipairs(bagId) do
			if (not isBank and id <= 3 ) or (isBank and id ~= -1) then
				local b = module:BagFrameSlotNew(id, bagsFrame)

				local Xoffset = padding + idx*bagTexSize + idx*spacing

				local BankSlots, Full = GetNumBankSlots()
				local cost = GetBankSlotCost(BankSlots);

				if isBank and not Full then

					--Most recently bought bag.
					if x == GetNumBankSlots() + 1 then

						--Set Things back up to normal after a purchase.
						local texture = b.frame:GetNormalTexture()
						b.frame:SetAlpha(1)
						b.frame:SetPushedTexture("Interface\Buttons\UI-Quickslot-Depress")
						b.frame:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
						texture:SetSize(50,50)

						b.frame:SetScript("OnClick", function(self)
							if ( IsModifiedClick("PICKUPACTION") ) then
								BankFrameItemButtonBag_Pickup(self);
							else
								BankFrameItemButtonBag_OnClick(self, button);
							end
						end)

					--Bag about to be purcahsed.
					elseif x == GetNumBankSlots() + 2 then

						local goldTex = "Interface\\Icons\\INV_Misc_Coin_02"
						--Setting the Texture.

						local texture = b.frame:GetNormalTexture()
						b.frame:SetAlpha(1)
						texture:SetTexture(goldTex)
						texture:SetSize(bagTexSize-1,bagTexSize-1)
						b.frame:SetPushedTexture(goldTex)

						-- Add the Click-To-Purchase option.
						b.frame:SetScript("OnClick", function(self)
							LUIBank.bankCost = cost
							StaticPopup_Show("CONFIRM_BUY_BANK_SLOT");
						end)

					--Unpurchased Bags.
					elseif x > GetNumBankSlots() + 2 then
						b.frame:SetAlpha(.2)
					end
				end
				if isBank and Full and LUIBank.bankCost then
					LUIBank.bankCost = nil
				end

				b.frame:ClearAllPoints()
				b.frame:SetPoint("LEFT", bagsFrame, "LEFT", LUI:Scale(Xoffset), 0)
				b.frame:Show()

				idx = idx + 1
			end
		end

		for _, id in ipairs(bagId) do
			local bagCount = GetContainerNumSlots(id)
			if bagCount > 0 then
				if not BagsInfo[id] then
					BagsInfo[id] = module:BagNew(id, frame)
				end

				slots = slots + GetContainerNumSlots(id)
			end
		end

		rows = floor(slots / cols)
		if (slots % cols) ~= 0 then
			rows = rows + 1
		end

		frame:SetWidth(LUI:Scale(cols * 31 + (cols - 1) * spacing + padding * 2))
		--frame:SetHeight(LUI:Scale(rows * 31 + (rows - 1) * spacing + off + padding * 2))
		frame:SetHeight(LUI:Scale(rows * 31 + (rows - 1) * spacing + off + padding * 2) + frame.sortButton:GetHeight());

	end

	if db.Bags[bagType].BagFrame then
		bagsFrame:Show()
	else
		bagsFrame:Hide()
	end

	local idx = 0
	for _, id in ipairs(bagId) do
		local bagCount = GetContainerNumSlots(id)

		if bagCount > 0 then
			BagsInfo[id] = module:BagNew(id, frame)
			local idBagType = BagsInfo[id].bagType

			BagsInfo[id]:Show()

			for i = 1, bagCount do
				local item, isnew = module:SlotNew(id, i)

				if isnew then
					tinsert(ItemSlots, idx + 1, item)
				end

				if not isCreated[bagType] then
					local xoff
					local yoff
					local x = (idx % cols)
					local y = floor(idx / cols)

					xoff = padding + (x * 31) + (x * spacing)
					yoff = off + padding + (y * 31) + ((y - 1) * spacing)
					yoff = yoff * -1

					item.frame:ClearAllPoints()
					item.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", LUI:Scale(xoff), LUI:Scale(yoff))
					item.frame:SetHeight(LUI:Scale(32))
					item.frame:SetWidth(LUI:Scale(32))
					item.frame:SetPushedTexture("")
					item.frame:SetNormalTexture("")
					item.frame:Show()

					item.frame:SetBackdrop( {
						bgFile = "Interface/Tooltips/UI-Tooltip-Background",
						edgeFile = borderTex,
						tile = false, tileSize = 0, edgeSize = 15,
						insets = { left = 5, right = 5, top = 5, bottom = 5 }
					})

					item.frame:SetBackdropColor(unpack(background_color))
					item.frame:SetBackdropBorderColor(unpack(border_color))

				end

				LUI:StyleButton(item.frame)
				module:SlotUpdate(item)

				local iconTex = _G[item.frame:GetName() .. "IconTexture"]
				iconTex:SetTexCoord(.08, .92, .08, .92)
				iconTex:SetPoint("TOPLEFT", item.frame, LUI:Scale(3), LUI:Scale(-3))
				iconTex:SetPoint("BOTTOMRIGHT", item.frame, LUI:Scale(-3), LUI:Scale(3))

				iconTex:Show()
				item.iconTex = iconTex

				idx = idx + 1
			end

		end

	end

	--adjust the size of the frames now.
	frame:SetScale(db.Bags[bagType].Scale)
	bagsFrame:SetScale(db.Bags[bagType].BagScale)

	isCreated[bagType] = true
end

function module:EnableBags()
	if db.Bags.Enable ~= true then return end

	-- hooking and setting key ring bag
	-- this is just a reskin of Blizzard key bag to fit LUI
	-- hooking OnShow because sometime key max slot changes.
	if not module:IsHooked(ContainerFrame1, "OnShow") then
		module:HookScript(ContainerFrame1, "OnShow", function(self)
			local keybackdrop = CreateFrame("Frame", nil, self)
			keybackdrop:SetPoint("TOPLEFT", LUI:Scale(9), LUI:Scale(-40))
			keybackdrop:SetPoint("BOTTOMLEFT", 0, 0)
			keybackdrop:SetSize(LUI:Scale(179),LUI:Scale(215))
			keybackdrop:SetBackdrop( {
				bgFile = LSM:Fetch("background", LUI_Media.empty),
				edgeFile = LSM:Fetch("border", LUI_Media.empty),
				tile = false, edgeSize = 0,
				insets = { left = 0, right = 0, top = 0, bottom = 0 }
			})
			keybackdrop:SetBackdropColor(0,0,0,0)
			keybackdrop:SetBackdropBorderColor(0,0,0,0)

			ContainerFrame1CloseButton:Hide()
			ContainerFrame1Portrait:Hide()
			ContainerFrame1Name:Hide()
			ContainerFrame1BackgroundTop:SetAlpha(0)
			ContainerFrame1BackgroundMiddle1:SetAlpha(0)
			ContainerFrame1BackgroundMiddle2:SetAlpha(0)
			ContainerFrame1BackgroundBottom:SetAlpha(0)

			local bgColor, color = db.Bags.Colors.Background, db.Bags.Colors.Border -- Shorter vars for colors.
			for i=1, GetKeyRingSize() do
				local slot = _G["ContainerFrame1Item"..i]
				local t = _G["ContainerFrame1Item"..i.."IconTexture"]
				slot:SetPushedTexture("")
				slot:SetNormalTexture("")
				t:SetTexCoord(.08, .92, .08, .92)
				t:SetPoint("TOPLEFT", slot, LUI:Scale(2), LUI:Scale(-2))
				t:SetPoint("BOTTOMRIGHT", slot, LUI:Scale(-2), LUI:Scale(2))
				slot:SetBackdrop( {
					bgFile = LSM:Fetch("background", db.Bags.Bags.BackgroundTexture),
					edgeFile = LSM:Fetch("border", db.Bags.Bags.BorderTexture),
					tile = false, edgeSize = 20,
					insets = { left = 5, right = -3, top = -3, bottom = 5 }
				})
				slot:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
				slot:SetBackdropBorderColor(color.r, color.g, color.b, color.a)
				LUI:StyleButton(slot, false)
			end

			self:ClearAllPoints()
			self:SetPoint("CENTER", UIParent, "CENTER", LUI:Scale(4), LUI:Scale(5))
		end)
	end
end

function module:PLAYERBANKBAGSLOTS_CHANGED(self, id)
	module:ReloadLayout("Bank")
end

function module:PLAYERBANKSLOTS_CHANGED(self, id)
	if id > 28 then
		for _, v in ipairs(BagsSlots) do
			if v.frame and v.frame.GetInventorySlot then

				BankFrameItemButton_Update(v.frame)
				BankFrameItemButton_UpdateLocked(v.frame)

				if not v.frame.tooltipText then
					v.frame.tooltipText = ""
				end
			end
		end
	end

	if LUIBank and LUIBank:IsShown() then
		for _, id in ipairs(GetBags["Bank"]) do
			module:BagSlotUpdate(id)

		end
	end
end

function module:BAG_UPDATE(self,id)
	module:BagSlotUpdate(id)

end

function module:ITEM_LOCK_CHANGED(self, bag, slot)
	if slot == nil then
		return
	end

	for _, v in ipairs(ItemSlots) do
		if v.bag == bag and v.slot == slot then
			module:SlotUpdate(v)
			break
		end
	end
end

function module:BANKFRAME_OPENED()
	if not LUIBank then
		module:InitBank()
	end

	module:Layout("Bank")
	for _, x in ipairs(GetBags["Bank"]) do
		module:BagSlotUpdate(x)
	end
	LUIBags_Open()
	LUIBank:Show()
end

function module:BANKFRAME_CLOSED()
	if not LUIBank then
		return
	end

	LUIBank:Hide()
end

function module:BAG_CLOSED(self, id)
	local bagId = BagsInfo[id]
	if bagId then
		tremove(BagsInfo, id)
		bagId:Hide()
		tinsert(trashBag, #trashBag + 1, bagId)
	end

	while true do
		local changed = false

		for i, v in ipairs(ItemSlots) do
			if v.bag == id then
				v.frame:Hide()
				v.iconTex:Hide()

				tinsert(trashButton, #trashButton + 1, v.frame)
				tremove(ItemSlots, i)
				v = nil
				changed = true
			end
		end

		if not changed then
			break
		end
	end

	--Hack to get a ReloadLayout on next re-open.
	isCreated["Bags"] = false
	isCreated["Bank"] = false
end

--Copy bags options over.
function module:CopyBags()
	--Iterate through all bag types.
	for bag, _ in pairs(GetBags) do

		--Check for bag types that needs to be copied.
		if bag ~= "Bags" and db.Bags[bag].CopyBags then

			for option, value in pairs(db.Bags.Bags) do
				if db.Bags[bag][option] ~= value and option ~= "Cols" then
					db.Bags[bag][option] = value
				end
			end

			-- Force re-creation of bag frames.
			module:ReloadLayout(bag)
		end
	end
end

--Used to see if any bags have the function enabled.
function module:CheckBagsCopy()
	for bag, _ in pairs(GetBags) do
		if bag ~= "Bags" then
			if db.Bags[bag].CopyBags then
				db.Bags.CopyBags = true
				return
			end
		end
	end
	db.Bags.CopyBags = false
end

function module:ReloadLayout(bag)
	isCreated[bag] = false
	local frame = LUIBags_Select(bag)
	if frame and frame:IsShown() then
		module:Layout(bag)
	end
end

-- Note: Do not make new tables inside the Bags and Bank Options.
--       It would break the CopyBags function that dynamically copy things.
local defaults = {
	Bags = {
		Enable = true,
		CopyBags = true,
		--Start of Bags Options
		Bags = {
			Font = "AvantGarde_LT_Medium",
			Cols = 12,
			Padding = 8,
			Spacing = 3,
			Scale = 1,
			BagScale = 1,
			BagFrame = true,
			ItemQuality = false,
			ShowQuest = true,
			Locked = 0,
			CoordX = 0,
			CoordY = 0,
			BackgroundTexture = "Blizzard Tooltip",
			BorderTexture = "Stripped_medium",
			BorderSize = 5,
			BorderInset = -1,
		},
		--End of Bags Options
		--Start of Bank Options
		Bank = {
			CopyBags = true,
			Font = "AvantGarde_LT_Medium",
			Cols = 14,
			Padding = 8,
			Spacing = 3,
			Scale = 1,
			BagScale = 1,
			BagFrame = true,
			ItemQuality = false,
			ShowQuest = true,
			Locked = 0,
			CoordX = 0,
			CoordY = 0,
			BackgroundTexture = "Blizzard Tooltip",
			BorderTexture = "Stripped_medium",
			BorderSize = 5,
			BorderInset = -1,
		},
		--End of Bank Options
		Colors = {
			BlackFrameBG = false,
			Border = {
				r = 0.2,
				g = 0.2,
				b = 0.2,
				a = 1,
			},
			Background = {
				r = 0.18,
				g = 0.18,
				b = 0.18,
				a = 0.8,
			},
			Professions = {
				r = 0.1,
				g = 0.5,
				b = 0.1,
				a = 1,
			},
			Quest = {
				r = 1,
				g = 1,
				b = 0,
				a = 1,
			},
		},
		--End of Colors Options
	},
}

function module:LoadOptions()
	local luidef = LUI.defaults.profile.Bags

	local function BagOpt()
		module:ReloadLayout("Bags")
		if db.Bags.CopyBags then module:CopyBags() end
	end
	local function BankOpt()
		module:ReloadLayout("Bank")
	end
	local function DisabledCopy()
		return db.Bags.Bank.CopyBags
	end
	local function ReloadBoth()
		module:ReloadLayout("Bags")
		module:ReloadLayout("Bank")
	end

	local options = {
		LUIBags = {
			name = "Bags",
			type = "group",
			childGroups = "tab",
			order = 50,
			disabled = function() return not db.Bags.Enable end,
			args = {
				Header = LUI:NewHeader("Bags", 1),
				Bags = {
					name = "Bags",
					type = "group",
					order = 3,
					args = {
						Enable = LUI:NewEnable("Bags", 1, db.Bags),
						Cols = LUI:NewSlider("Items Per Row", "Select how many items will be displayed per rows in your Bags.",
									2, db.Bags.Bags, "Cols", luidef.Bags, 4, 32, 1, BagOpt),
						Header = LUI:NewHeader("", 3),
						Padding = LUI:NewSlider("Bag Padding", "This sets the space between the background border and the adjacent items.",
									4, db.Bags.Bags, "Padding", luidef.Bags, 4, 24, 1, BagOpt),
						Spacing = LUI:NewSlider("Bag Spacing", "This sets the distance between items.",
									5, db.Bags.Bags, "Spacing", luidef.Bags, 1, 15, 1, BagOpt),
						Scale = LUI:NewScale("Bags Frame",6, db.Bags.Bags, "Scale", luidef.Bags, BagOpt),
						BagScale = LUI:NewScale("Bags BagBar",7, db.Bags.Bags, "BagScale", luidef.Bags, BagOpt),
						BagFrame = LUI:NewToggle("Show Bag Bar", nil, 8, db.Bags.Bags, "BagFrame", luidef.Bags, BagOpt),
						ItemQuality = LUI:NewToggle("Show Item Quality", nil, 9, db.Bags.Bags, "ItemQuality", luidef.Bags, BagOpt),
						ShowQuest = LUI:NewToggle("Highlight Quest Items", nil, 10, db.Bags.Bags, "ShowQuest", luidef.Bags, BagOpt),
					},
				},
				Bank = {
					name = "Bank",
					type = "group",
					order = 4,
					args = {
						CopyBags = LUI:NewToggle("Copy Bags", "Make the Bank frames copies the bags options.", 1, db.Bags.Bank, "CopyBags", luidef.Bank,
							function()
								module:CheckBagsCopy()
								if db.Bags.Bank.CopyBags then module:CopyBags() end
							end),
						Cols = LUI:NewSlider("Items Per Row", "Select how many items will be displayed per rows in your Bags.", 2,
									db.Bags.Bank, "Cols", luidef.Bank, 4, 32, 1, BankOpt),
						Header = LUI:NewHeader("", 3),
						Padding = LUI:NewSlider("Bank Padding", "This sets the space between the background border and the adjacent items.", 4,
									db.Bags.Bank, "Padding", luidef.Bank, 4, 24, 1, BankOpt, nil, DisabledCopy),
						Spacing = LUI:NewSlider("Bank Spacing", "This sets the distance between items.", 5,
									db.Bags.Bank, "Spacing", luidef.Bank, 1, 15, 1, BankOpt, nil, DisabledCopy),
						Scale = LUI:NewScale("Bank Frame",6, db.Bags.Bank, "Scale", luidef.Bank, BankOpt, nil, DisabledCopy),
						BagScale = LUI:NewScale("Bank BagBar",7, db.Bags.Bank, "BagScale", luidef.Bank, BankOpt, nil, DisabledCopy),
						BagFrame = LUI:NewToggle("Show Bag Bar", nil, 8, db.Bags.Bank, "BagFrame", luidef.Bank, BankOpt, nil, DisabledCopy),
						ItemQuality = LUI:NewToggle("Show Item Quality", nil, 9, db.Bags.Bank, "ItemQuality", luidef.Bank, BankOpt, nil, DisabledCopy),
						ShowQuest = LUI:NewToggle("Highlight Quest Items", nil, 10, db.Bags.Bank, "ShowQuest", luidef.Bank, BankOpt, nil, DisabledCopy),
					},
				},
				Colors = {
					name = "Colors",
					type = "group",
					order = 5,
					args = {
						BackgroundColor = LUI:NewColor("Background", "Bags Background", 1, db.Bags.Colors.Background, luidef.Colors.Background, ReloadBoth),
						BorderColor = LUI:NewColor("Border", "Bags Borders", 2, db.Bags.Colors.Border, luidef.Colors.Border, ReloadBoth),
						ProfessionColor = LUI:NewColor("Profession", "Profession Bags Borders", 3, db.Bags.Colors.Professions, luidef.Colors.Professions, ReloadBoth),
						QuestColor = LUI:NewColor("Quest", "Quest Items Borders", 4, db.Bags.Colors.Quest, luidef.Colors.Quest, ReloadBoth),
						FrameBG = LUI:NewToggle("Black Frame Background", "This will force the Bags' Frame Background to always be black.", 5,
									db.Bags.Colors, "BlackFrameBG", luidef.Colors, ReloadBoth)
					},
				},
				--Reminder for where to had new categories
			},
		},
	}

	return options
end

function module:OnInitialize()
	LUI:MergeDefaults(LUI.db.defaults.profile, defaults)
	LUI:RefreshDefaults()
	LUI:Refresh()

	self.db = LUI.db.profile
	db = self.db

	LUI:RegisterModule(self)
end

local OldFuncs = {}
function module:OnEnable()

	module:RegisterEvent("BANKFRAME_OPENED")
	module:RegisterEvent("BANKFRAME_CLOSED")

	-- Add LUIBags to the "Can be closed using ESC" table.
	tinsert(UISpecialFrames,"LUIBags")

	CloseAllBags()

	--Keep the old functions in mind for OnDisable
	OldFuncs["TogglePack"] = ToggleBackpack
	OldFuncs["OpenBags"] = OpenAllBags
	OldFuncs["ToggleBags"] = ToggleAllBags
	OldFuncs["OpenPack"] = OpenBackpack
	OldFuncs["ClosePack"] = CloseBackpack
	OldFuncs["CloseBags"] = CloseAllBags

	--Now changes the functions to ours
	ToggleBackpack = LUIBags_Toggle
	OpenAllBags = LUIBags_Toggle
	ToggleAllBags = LUIBags_Toggle
	OpenBackpack = LUIBags_Open
	CloseBackpack = LUIBags_Close
	CloseAllBags = LUIBags_Close

	BankFrame:UnregisterAllEvents()

	module:SetBags()
	module:EnableBags()

end

function module:OnDisable()
	InterfaceOptionsDisplayPanelShowFreeBagSpace:Show()

	--Make the bankframe works again
	BankFrame:RegisterEvent("BANKFRAME_OPENED")
	BankFrame:RegisterEvent("BANKFRAME_CLOSED")

	CloseAllBags()

	--Makes the UI functions like they were
	ToggleBackpack = OldFuncs["TogglePack"]
	OpenAllBags = OldFuncs["OpenBags"]
	ToggleAllBags = OldFuncs["ToggleBags"]
	OpenBackpack = OldFuncs["OpenPack"]
	CloseBackpack = OldFuncs["ClosePack"]
	CloseAllBags = OldFuncs["CloseBags"]

	module:Unhook(ContainerFrame1, "OnShow")

	ContainerFrame1CloseButton:Show()
	ContainerFrame1Portrait:Show()
	ContainerFrame1Name:Show()
	ContainerFrame1BackgroundTop:SetAlpha(1)
	ContainerFrame1BackgroundMiddle1:SetAlpha(1)
	ContainerFrame1BackgroundMiddle2:SetAlpha(1)
	ContainerFrame1BackgroundBottom:SetAlpha(1)

end

function module:PrepareSort(frame)
	if frame ~= LUIBags and frame ~= LUIBank then
		return;
	end

	if frame:GetScript("OnUpdate") then
		return;
	end

	self.sortFrame = frame;

	self.sortBags = {};
	self.sortItems = {};

	local bagOrder = {}
	if self.sortFrame == LUIBags then
		bagOrder = GetBags["Bags"];
	elseif self.sortFrame == LUIBank then
		bagOrder = GetBags["Bank"];
	end

	local specialBags = {};

	for _, v in pairs(bagOrder) do
		local maxSlots = GetContainerNumSlots(v);

		if maxSlots > 0 then
			local bagFamily = select(2, GetContainerNumFreeSlots(v));

			if bagFamily > 0 then
				table.insert(specialBags, {bagId = v, slot = maxSlots, maxSlots = maxSlots, bagFamily = bagFamily});
			else
				table.insert(self.sortBags, {bagId = v, slot = maxSlots, maxSlots = maxSlots, bagFamily = bagFamily});
			end
		end
	end

	for _, v in pairs(specialBags) do
		table.insert(self.sortBags, v);
	end

	for _, bag in pairs(self.sortBags) do
		for j = 1, GetContainerNumSlots(bag.bagId) do
			local itemId = GetContainerItemID(bag.bagId, j);

			if itemId then
				local _, count, locked = GetContainerItemInfo(bag.bagId, j);

				if locked then
					return;
				end

				local name, _, rarity, itemLevel, requiredLevel, itemType, itemSubType, stackCount, equipLocation, _, sellPrice = GetItemInfo(itemId);

				local sortString = rarity .. itemType .. itemSubType .. requiredLevel .. itemLevel .. name .. itemId;

				local itemFamily = GetItemFamily(itemId);

				table.insert(self.sortItems, {
					sortString = sortString,
					sBag = bag.bagId,
					sSlot = j,
					itemFamily = itemFamily,
					count = count,
					stackCount = stackCount
				});
			end
		end
	end

	table.sort(self.sortItems, function(a, b)
		if a.sortString == b.sortString then
			return a.count > b.count;
		end

		return a.sortString > b.sortString;
	end);

	-- Set targets
	for i, v in pairs(self.sortItems) do
		local bagIndex = #self.sortBags;

		-- Test for special bag
		local firstNormal = -1;
		while bit.band(v.itemFamily, self.sortBags[bagIndex].bagFamily) == 0 do
			if self.sortBags[bagIndex].bagFamily == 0 and firstNormal == -1 then
				firstNormal = bagIndex;
			end

			bagIndex = bagIndex - 1;

			if not self.sortBags[bagIndex] then
				bagIndex = firstNormal;

				break;
			end
		end

		local bag = self.sortBags[bagIndex];

		-- Stacking
		local targetchange = true;
		if i > 1 and self.sortItems[i - 1].sortString == v.sortString then
			if self.sortItems[i - 1].count < v.stackCount then
				local count = self.sortItems[i - 1].count + v.count;

				v.tBag = self.sortItems[i - 1].tBag;
				v.tSlot = self.sortItems[i - 1].tSlot;

				if count - v.stackCount > 0 then
					v.count = count - v.stackCount;

					v.tBag2 = bag.bagId;
					v.tSlot2 = bag.slot;
				else
					targetchange = false;
					v.count = count;
				end
			end
		end

		if not v.tBag then
			v.tBag = bag.bagId;
			v.tSlot = bag.slot;
		end

		if targetchange then
			bag.slot = bag.slot - 1;
		end

		if bag.slot < 1 then
			table.remove(self.sortBags, bagIndex);
		end
	end

	self.sortFrame:SetScript("OnUpdate", module.Sort);
end

function module:Sort(elapsed)
	if not module.sortTime or module.sortTime > 0.1 then
		module.sortTime = 0;
	else
		module.sortTime = module.sortTime + elapsed;
		return;
	end

	if module.sorting then
		return;
	end

	module.sorting = true;

	ClearCursor();

	local changes = 1;
	local key = 1;

	while module.sortItems[key] do
		local item = module.sortItems[key];

		if not select(3, GetContainerItemInfo(item.sBag, item.sSlot)) and not select(3, GetContainerItemInfo(item.tBag, item.tSlot)) then
			if item.sBag ~= item.tBag or item.sSlot ~= item.tSlot then
				PickupContainerItem(item.sBag, item.sSlot);
				PickupContainerItem(item.tBag, item.tSlot);

				for i = 1, #module.sortItems do
					if module.sortItems[i].sBag == item.tBag and module.sortItems[i].sSlot == item.tSlot then
						module.sortItems[i].sBag = item.sBag;
						module.sortItems[i].sSlot = item.sSlot;
					end
				end

				changes = changes + 1;
			end

			if item.tBag2 then
				item.tBag = item.tBag2;
				item.tSlot = item.tSlot2;

				item.tBag2 = nil;
				item.tSlot2 = nil;
			else
				table.remove(module.sortItems, key);
				key = key - 1;

				if changes > 5 then
					module.sorting = false;

					return;
				end
			end
		end


		key = key + 1;
	end

	if not module.sortItems[1] then
		module.sortFrame:SetScript("OnUpdate", nil);
		module.sortTime = nil;
		module.sorting = nil;
		module.sortItems = nil;
		module.sortBags = nil;
		module.sortFrame = nil;
	else
		module.sorting = false;
	end
end
