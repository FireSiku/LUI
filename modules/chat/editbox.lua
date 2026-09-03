--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: editbox.lua
	Description: Chat EditBox Module
]]

-- External references.
---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Chat
local Chat = LUI:GetModule("Chat")
local module = Chat:NewModule("EditBox", "LUIDevAPI", "AceHook-3.0")
local Media = LibStub("LibSharedMedia-3.0")

local L = LUI.L
local db, history

local DEFAULT_CHAT_FRAME = _G.DEFAULT_CHAT_FRAME
local CHAT_FRAMES = _G.CHAT_FRAMES
local ChatTypeInfo = _G.ChatTypeInfo
local GetCVar = _G.GetCVar
local ChatFrameUtil = _G.ChatFrameUtil

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
local originalEditBoxes = setmetatable({}, {__mode = "k"})

local function capturePoints(frame)
	local points = {}
	for i = 1, frame:GetNumPoints() do
		points[i] = {frame:GetPoint(i)}
	end
	return points
end

local function restorePoints(frame, points)
	frame:ClearAllPoints()
	for _, point in ipairs(points) do
		frame:SetPoint(unpack(point))
	end
end

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
	db.width = math.max(editBox:GetRight() - editBox:GetLeft(), 10)
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
	if not editBox.decorated then
		local name = editBox:GetName()
		local font, fontSize, fontFlags = editBox:GetFont()
		local headerFont, headerSize, headerFlags = editBox.header:GetFont()
		originalEditBoxes[editBox] = {
			shown = editBox:IsShown(),
			alpha = editBox:GetAlpha(),
			points = capturePoints(editBox),
			height = editBox:GetHeight(),
			font = font,
			fontSize = fontSize,
			fontFlags = fontFlags,
			headerFont = headerFont,
			headerSize = headerSize,
			headerFlags = headerFlags,
			altArrowKeyMode = editBox:GetAltArrowKeyMode(),
			mouseEnabled = editBox:IsMouseEnabled(),
			movable = editBox:IsMovable(),
			resizable = editBox:IsResizable(),
			onMouseDown = editBox:GetScript("OnMouseDown"),
			onMouseUp = editBox:GetScript("OnMouseUp"),
			resizeBounds = {editBox:GetResizeBounds()},
			leftShown = _G[name.."Left"]:IsShown(),
			rightShown = _G[name.."Right"]:IsShown(),
			midShown = _G[name.."Mid"]:IsShown(),
		}
		editBox:Hide()
		_G[name.."Left"]:Hide()
		_G[name.."Right"]:Hide()
		_G[name.."Mid"]:Hide()

		LUI:Kill(editBox.focusLeft)
		LUI:Kill(editBox.focusRight)
		LUI:Kill(editBox.focusMid)

		editBox.decorated = true
	end
	if not module:IsHooked(editBox, "UpdateHeader") then
		module:SecureHook(editBox, "UpdateHeader", "UpdateEditBoxBackground")
	end
	editBox:SetHeight(db.Height)

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

	LUI:ApplyFrameBackdrop(bg, backdrop)
	module:UpdateEditBoxBackground(editBox)
end

local function anchorEditBox(anchor)
	for i, name in ipairs(CHAT_FRAMES) do
		local editBox = _G[name].editBox

		if anchor == "FREE" or anchor == "LOCK" then
			db.x = db.x or editBox:GetLeft()
			db.y = db.y or editBox:GetTop()
			db.width = db.width or math.max(editBox:GetWidth(), (editBox:GetRight() or 0) - (editBox:GetLeft() or 0), 10)
		end

		editBox:ClearAllPoints()

		if anchor == "FREE" then
			editBox:EnableMouse(true)
			editBox:SetMovable(true)
			editBox:SetResizable(true)
			editBox:SetScript("OnMouseDown", startMoving)
			editBox:SetScript("OnMouseUp", stopMoving)
			editBox:SetResizeBounds(40, 1)

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
	elseif (mediaType == "border" and key == db.Border.Texture) or (mediaType == "background" and key == db.Background.Texture) then
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
		ChatFrameUtil.DeactivateChat(_G[CHAT_FRAMES[frame:GetID()]].editBox)
	end
end

function module:AfterDeactivateChat(editBox)
	if editBox:IsShown() then
		editBox:SetAlpha(0)
		editBox:EnableMouse(false)
	end
end

function module:AfterSetLastActiveWindow(editBox)
	if editBox:IsShown() then
		editBox:SetAlpha(0)
	else
		editBox:SetAlpha(1)
	end
	editBox:EnableMouse(true)
end

function module:UpdateEditBoxBackground(editBox)
	if not editBox.bg then return end -- FCF_OpenTemporaryWindow calls this (hook to create editBox.bg hasn't fired yet)

	local color = db.Background.Color
	local r, g, b, a = color.r, color.g, color.b, color.a

	if db.ColorByChannel then
		local attr = editBox:GetChatType()

		if attr and not issecretvalue(attr) then
			local colorType = attr
			if attr == "CHANNEL" then
				local chan = editBox:GetChannelTarget()
				if chan and issecretvalue(chan) then chan = nil end
				if chan and chan > 0 then
					colorType = "CHANNEL"..chan
				end
			end

			local channelColor = ChatTypeInfo[colorType]
			if channelColor then
				r, g, b = channelColor.r, channelColor.g, channelColor.b
			end
		end
	end

	a = a or 0.4
	LUI:SetFrameBackgroundColor(editBox.bg, r, g, b, a)
	LUI:SetFrameBorderColor(editBox.bg, r, g, b, math.min(1, a + 0.3))
end


function module:AddHistoryLine(frame, line)
	if not line or issecretvalue(line) then return end
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
			Flag = "",
		},
		Background = {
			Color = {r = 0.12, g = 0.58, b = 0.89, a = 0.4},
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
		local editBox = _G[name].editBox
		decorate(editBox)
		editBox:SetAltArrowKeyMode(db.UseAlt)
	end

	self:LibSharedMedia_Registered("font", db.Font.Font)

	anchorEditBox(db.Anchor)
	setHistory()
end

function module:OnInitialize()
	db = Chat:Namespace(self)
	if db.Background.Color[1] then
		local color = db.Background.Color
		db.Background.Color = {r = color[1], g = color[2], b = color[3], a = color[4]}
	end
	history = self.db.factionrealm
end

module.DBCallback = module.OnInitialize

function module:OnEnable()
	Media.RegisterCallback(self, "LibSharedMedia_Registered")

	self:SecureHook("FCF_OpenTemporaryWindow", "Refresh")
	self:SecureHook("FCF_Tab_OnClick")
	self:SecureHook(ChatFrameUtil, "DeactivateChat", "AfterDeactivateChat")
	self:SecureHook(ChatFrameUtil, "SetLastActiveWindow", "AfterSetLastActiveWindow")

	setHistory(true)

	self:Refresh()
end

function module:OnDisable()
	Media.UnregisterCallback(self, "LibSharedMedia_Registered")

	self:UnhookAll()

	for i, name in ipairs(CHAT_FRAMES) do
		local editBox = _G[name.."EditBox"]
		local original = originalEditBoxes[editBox]
		editBox:Hide()
		if editBox.bg then editBox.bg:Hide() end

		LUI:Unkill(editBox.focusLeft)
		LUI:Unkill(editBox.focusRight)
		LUI:Unkill(editBox.focusMid)
		if original then
			_G[name.."EditBoxLeft"]:SetShown(original.leftShown)
			_G[name.."EditBoxRight"]:SetShown(original.rightShown)
			_G[name.."EditBoxMid"]:SetShown(original.midShown)
			restorePoints(editBox, original.points)
			editBox:SetAlpha(original.alpha)
			editBox:SetHeight(original.height)
			editBox:SetFont(original.font, original.fontSize, original.fontFlags)
			editBox.header:SetFont(original.headerFont, original.headerSize, original.headerFlags)
			editBox:SetAltArrowKeyMode(original.altArrowKeyMode)
			editBox:EnableMouse(original.mouseEnabled)
			editBox:SetMovable(original.movable)
			editBox:SetResizable(original.resizable)
			editBox:SetScript("OnMouseDown", original.onMouseDown)
			editBox:SetScript("OnMouseUp", original.onMouseUp)
			editBox:SetResizeBounds(unpack(original.resizeBounds))
			editBox:SetShown(original.shown)
			originalEditBoxes[editBox] = nil
		end
		if editBox.SetFocusRegionsShown then
			editBox:SetFocusRegionsShown(editBox:HasFocus())
		end

		editBox.decorated = nil
	end

	setHistory(false)
end
