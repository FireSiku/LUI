--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: editbox.lua
	Description: Chat EditBox Module
]]

-- External references.
local addonname, LUI = ...
local Chat = LUI:Module("Chat")
local module = Chat:Module("EditBox", "AceHook-3.0")
local Themes = LUI:Module("Themes")
local Media = LibStub("LibSharedMedia-3.0")

local L = LUI.L
local db, dbd, history

--------------------------------------------------
-- Local Variables
--------------------------------------------------

local backdrop = {
	insets = {
		top = 0,
		bottom = 0,
		left = 0,
		right = 0,
	},
}

--------------------------------------------------
-- Local Functions
--------------------------------------------------

local function startMoving(editBox)
	editBox:StartMoving()
end

local function stopMoving(editBox)
	editBox:StopMovingOrSizing()
	db.x = editBox:GetLeft()
	db.y = editBox:GetTop()
	db.width = max(editBox:GetRight() - editBox:GetLeft(), 10)
end

local function updateDB(editBox)
	db.x = editBox:GetLeft()
	db.y = editBox:GetTop()
	db.width = editBox:GetWidth()
end

local function setHistory(init)
	if db.History and init ~= false then
		if init then
			for _, line in ipairs(history) do
				DEFAULT_CHAT_FRAME.editBox:AddHistoryLine(line)
			end
		end

		if not module:IsHooked(DEFAULT_CHAT_FRAME.editBox, "AddHistoryLine") then
			module:SecureHook(DEFAULT_CHAT_FRAME.editBox, "AddHistoryLine")
		end
	else
		module:Unhook(DEFAULT_CHAT_FRAME.editBox, "AddHistoryLine")
	end
end

local function decorate(editBox)
	editBox:SetHeight(db.Height)

	if not editBox.decorated then
		editBox:Hide()

		local name = editBox:GetName()
		_G[name.."Left"]:Hide()
		_G[name.."Right"]:Hide()
		_G[name.."Mid"]:Hide()

		editBox.focusLeft:SetTexture(nil)
		editBox.focusRight:SetTexture(nil)
		editBox.focusMid:SetTexture(nil)

		editBox:SetMaxLetters(2048)
		editBox:SetMaxBytes(2048)

		editBox.decorated = true
	end

	local bg = editBox.bg

	if not bg then
		bg = CreateFrame("Frame", nil, editBox, "LUI_Chat_EditBoxBGTemplate")
		bg.lDrag.editBox = editBox
		bg.rDrag.editBox = editBox

		bg.lDrag.updateDB = updateDB
		bg.rDrag.updateDB = updateDB

		editBox.bg = bg
		editBox.lDrag = bg.lDrag
		editBox.rDrag = bg.rDrag
	end

	bg:Show()

	bg:SetBackdrop(backdrop)
	module:ChatEdit_UpdateHeader(editBox)
end

local function anchorEditBox(anchor)
	for i, name in ipairs(CHAT_FRAMES) do
		local editBox = _G[name].editBox

		if anchor == "FREE" or anchor == "LOCK" then
			db.x = db.x or editBox:GetLeft()
			db.y = db.y or editBox:GetTop()
			db.width = db.width or max(editBox:GetWidth(), (editBox:GetRight() or 0) - (editBox:GetLeft() or 0), 10)
		end

		editBox:ClearAllPoints()

		if anchor == "FREE" then
			editBox:EnableMouse(true)
			editBox:SetMovable(true)
			editBox:SetResizable(true)
			editBox:SetScript("OnMouseDown", startMoving)
			editBox:SetScript("OnMouseUp", stopMoving)
			editBox:SetMinResize(40, 1)

			editBox.lDrag:EnableMouse(true)
			editBox.rDrag:EnableMouse(true)
		else
			editBox:SetMovable(false)
			editBox:SetScript("OnMouseDown", nil)
			editBox:SetScript("OnMouseUp", nil)

			editBox.lDrag:EnableMouse(false)
			editBox.rDrag:EnableMouse(false)
		end

		if anchor == "TOP" then
			editBox:SetPoint("BOTTOMLEFT", _G[name], "TOPLEFT", 0, 3)
			editBox:SetPoint("BOTTOMRIGHT", _G[name], "TOPRIGHT", 0, 3)
		elseif anchor == "BOTTOM" then
			editBox:SetPoint("TOPLEFT", _G[name], "BOTTOMLEFT", 0, -8)
			editBox:SetPoint("TOPRIGHT", _G[name], "BOTTOMRIGHT", 0, -8)
		elseif anchor == "FREE" then
			editBox:SetWidth(db.width)
			editBox:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", db.x, db.y)
		elseif anchor == "LOCK" then
			editBox:SetWidth(db.width)
			editBox:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", db.x, db.y)
		end
	end
end

--------------------------------------------------
-- Callback Functions
--------------------------------------------------

function module:LibSharedMedia_Registered(mediaType, key)
	if mediaType == "font" and key == db.Font.Font then
		for i, name in ipairs(CHAT_FRAMES) do
			local editBox = _G[name].editBox
			if editBox then
				local font = Media:Fetch("font", db.Font.Font)
				editBox:SetFont(font, db.Font.Size, db.Font.Flag)
				editBox.header:SetFont(font, db.Font.Size, db.Font.Flag)
			end
		end
	elseif mediaType == "border" and key == db.Border.Texture or mediaType == "background" and key == db.Background.Texture then
		for i, name in ipairs(CHAT_FRAMES) do
			decorate(_G[name].editBox)
		end
	end
end

--------------------------------------------------
-- Hook Functions
--------------------------------------------------

function module:FCF_Tab_OnClick(frame, button)
	if db.Anchor == "TOP" and GetCVar("chatStyle") ~= "classic" then
		ChatEdit_DeactivateChat(_G[CHAT_FRAMES[frame:GetID()]].editBox)
	end
end

function module:ChatEdit_DeactivateChat(editBox)
	if editBox:IsShown() then
		editBox:SetAlpha(0)
		editBox:EnableMouse(false)
	end
end

function module:ChatEdit_SetLastActiveWindow(editBox)
	if editBox:IsShown() then
		editBox:SetAlpha(0)
	else
		editBox:SetAlpha(1)
	end
	editBox:EnableMouse(true)
end

function module:ChatEdit_UpdateHeader(editBox) -- update EditBox Colors
	if not editBox.bg then return end -- FCF_OpenTemporaryWindow calls this (hook to create editBox.bg hasn't fired yet)

	local r, g, b, a

	if db.ColorByChannel then
		local attr = editBox:GetAttribute("chatType")

		if attr == "CHANNEL" then
			local chan = editBox:GetAttribute("channelTarget")
			if chan and chan == 0 then
				r, g, b, a = unpack(Themes.db.profile.editbox)
			elseif chan then
				r, g, b = GetMessageTypeColor("CHANNEL"..chan)
			else
				r, g, b = GetMessageTypeColor(attr)
			end
		else
			r, g, b = GetMessageTypeColor(attr)
		end
	else
		r, g, b, a = unpack(Themes.db.profile.editbox)
	end

	a = a or 0.2
	editBox.bg:SetBackdropColor(r, g, b, a)
	editBox.bg:SetBackdropBorderColor(r, g, b, a+0.3)
end

do
	local extraText, chunks = {}, {}

	local function splitMsg(text, start)
		local stack = 0
		local first
		wipe(chunks)
		if start > #text then return nil end

		for i = start, start + 255 do
			local byte = text:sub(i, i)
			local bit = text:sub(i, i+1)
			if bit == "|H" then
				first = first or i
				local link = text:sub(i):match("|H(.-|h.-|h)")
				if link and not link:find("|H") then
					stack = stack + 2
				else
					stack = stack + 1
				end
			elseif bit == "|c" then
				first = first or i
				stack = stack + 1
			elseif (bit == "|r" or bit == "|h") and stack > 0 and first then
				stack = stack - 1
				if stack == 0 then
					tinsert(chunks, text:sub(first, i))
					first = nil
				end
			elseif (byte == " " or byte == "") and stack == 0 and first then
				tinsert(chunks, text:sub(first or 1, i))
				first = nil
			else
				first = first or i
			end
		end

		if #chunks == 0 then return nil end

		local str = table.concat(chunks, "")
		return start + #str, str
	end

	function module:ChatEdit_ParseText(editBox, send)
		if send == 0 then return end

		local text = editBox:GetText()

		if #text <= 255 then return end

		self:SecureHook("SendChatMessage")

		wipe(extraText)
		local first = true
		for start, chunk in splitMsg, text, 1 do
			if first then
				editBox:SetText(chunk)
				extraText.msg = chunk
				first = false
			else
				tinsert(extraText, chunk)
			end
		end
	end

	function module:SendChatMessage(text, ...)
		if text == extraText.msg then
			self:Unhook("SendChatMessage")

			for i, extra in ipairs(extraText) do
				SendChatMessage(extra, ...)
			end
		end
	end
end

function module:AddHistoryLine(frame, line)
	if history[#history] == line then return end -- return if this is the same line as the last in the table

	tinsert(history, line)

	-- clear out the excess values from beginning of table
	for i = 1, #history - frame:GetHistoryLines() do
		tremove(history, 1)
	end
end

--------------------------------------------------
-- Module Variables
--------------------------------------------------

module.defaults = {
	profile = {
		Height = 26,
		ColorByChannel = false,
		UseAlt = false,
		History = true,
		Anchor = "TOP",
		Font = {
			Font = (function()
				for i, name in ipairs(CHAT_FRAMES) do
					local font = _G[name].editBox:GetFont()
					for k, v in pairs(Media:HashTable("font")) do
						if v == font then return k end
					end
				end
			end)(),
			Size = 14,
			Flag = "NONE",
		},
		Background = {
			Texture = "Blizzard Tooltip",
			Tile = false,
			TileSize = 16,
			Insets = {
				["*"] = 4,
			},
		},
		Border = {
			Texture = "glow",
			Thickness = 5,
		},

	},
	factionrealm = {},
}

--------------------------------------------------
-- Load Functions
--------------------------------------------------

function module:LoadOptions()
	local anchorPoints = {
		TOP = L["Top"],
		BOTTOM = L["Bottom"],
		FREE = L["Free-floating"],
		LOCK = L["Free-floating (Locked)"],
	}

	local refresh = function()
		self:Refresh()
	end

	local tileDisabled = function()
		return not db.Background.Tile
	end

	local options = self:NewGroup(L["EditBox"], 2, "generic", "Refresh", {
		Font = self:NewGroup(L["Font"], 1, true, {
			Font = self:NewSelect(L["Font"], L["Choose a font"], 1, true, "LSM30_Font", refresh),
			Flag = self:NewSelect(L["Flag"], L["Choose a font flag"], 2, LUI.FontFlags, false, refresh),
			Size = self:NewSlider(L["Size"], L["Choose a fontsize"], 3, 6, 20, 1, true, false, "full")
		}),
		Anchor = self:NewSelect(L["Anchor Point"], L["Select where the EditBox anchors to the ChatFrame"], 2, anchorPoints, false, refresh),
		UseAlt = self:NewToggle(L["Use Alt key"], L["Requires the Alt key to be held down to move the cursor"], 3, true, "normal"),
		History = self:NewToggle(L["Remember history"], L["Remembers the history of the EditBox across sessions"], 4, true, "normal"),
		ColorByChannel = self:NewToggle(L["Color by channel"], L["Sets the EditBox color to the color of your currently active channel"], 5, true, "normal"),
		Height = self:NewSlider(L["Height"], L["Adjust the height of the EditBox"], 6, 5, 50, 1, true, false, "full"),
		Background = self:NewGroup(L["Background"], 7, true, {
			Texture = self:NewSelect(L["Texture"], L["Choose a texture"], 1, true, "LSM30_Background", refresh),
			empty = self:NewDesc("", 1.5, "normal"),
			Tile = self:NewToggle(L["Tile"], L["Should the background texture be tiled over the area"], 2, true, "normal"),
			TileSize = self:NewSlider(L["Tile Size"], L["Adjust the size of each tile of the background texture"], 3, 1, 200, 1, true, false, nil, tileDisabled),
			Insets = self:NewGroup(L["Insets"], 4, true, {
				top = self:NewInputNumber(L["Top"], L["Adjust the top inset of the background"], 1, refresh, "half"),
				bottom = self:NewInputNumber(L["Bottom"], L["Adjust the bottom inset of the background"], 2, refresh, "half"),
				left = self:NewInputNumber(L["Left"], L["Adjust the left inset of the background"], 3, refresh, "half"),
				right = self:NewInputNumber(L["Right"], L["Adjust the right inset of the background"], 4, refresh, "half"),
			}),
		}),
		Border = self:NewGroup(L["Border"], 8, true, {
			Texture = self:NewSelect(L["Texture"], L["Choose a texture"], 1, true, "LSM30_Border", refresh),
			Thickness = self:NewSlider(L["Thickness"], L["Adjust the thickness of the border"], 2, 1, 20, 1, refresh),
		}),
	})

	return options
end

function module:Refresh(info, value)
	if type(info) == "table" then
		self:SetDBVar(info, value)
	end

	backdrop.bgFile = Media:Fetch("background", db.Background.Texture)
	backdrop.tileSize = db.Background.TileSize
	backdrop.tile = db.Background.Tile
	backdrop.edgeFile = Media:Fetch("border", db.Border.Texture)
	backdrop.edgeSize = db.Border.Thickness
	for k in pairs(backdrop.insets) do
		backdrop.insets[k] = db.Background.Insets[k]
	end

	for i, name in ipairs(CHAT_FRAMES) do
		_G[name].editBox:SetAltArrowKeyMode(db.UseAlt)
		decorate(_G[name].editBox)
	end

	self:LibSharedMedia_Registered("font", db.Font.Font)

	anchorEditBox(db.Anchor)
	setHistory()
end

function module:OnInitialize()
	db, dbd = Chat:Namespace(self)
	history = self.db.factionrealm
end

module.DBCallback = module.OnInitialize

function module:OnEnable()
	Media.RegisterCallback(self, "LibSharedMedia_Registered")

	self:SecureHook("FCF_OpenTemporaryWindow", "Refresh")
	self:SecureHook("FCF_Tab_OnClick")
	self:SecureHook("ChatEdit_DeactivateChat")
	self:SecureHook("ChatEdit_SetLastActiveWindow")
	self:SecureHook("ChatEdit_UpdateHeader")
	self:SecureHook("ChatEdit_ParseText")

	setHistory(true)

	self:Refresh()
end

function module:OnDisable()
	Media.UnregisterCallback(self, "LibSharedMedia_Registered")

	self:UnhookAll()

	for i, name in ipairs(CHAT_FRAMES) do
		_G[name.."EditBoxLeft"]:Show()
		_G[name.."EditBoxRight"]:Show()
		_G[name.."EditBoxMid"]:Show()

		local editBox = _G[name.."EditBox"]
		editBox:Hide()
		editBox:SetAltArrowKeyMode(true)
		editBox:EnableMouse(true)
		editBox.bg:Hide()
		anchorEditBox("BOTTOM")
		editBox:SetFont(Media:Fetch("font", dbd.Font.Font), 14)
		editBox.header:SetFont(Media:Fetch("font", dbd.Font.Font), 14)
		editBox:SetMaxLetters(256)
		editBox:SetMaxBytes(256)

		editBox.decorated = nil
	end

	setHistory(false)
end
