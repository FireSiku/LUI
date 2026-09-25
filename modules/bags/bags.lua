--[[
	Core of the Bags module and its reusable ContainerMixin.

	Container instances keep their container type, frame name, bag-ID list,
	item-slot frames, bag-bar buttons and per-bag parent frames here. Code that
	is specific to one container belongs in that container's own file. v2609
	uses this implementation for character bags while Blizzard owns bank frames.
]]
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
local SetItemButtonCount = _G.SetItemButtonCount
local GetItemQualityColor = C_Item.GetItemQualityColor
local GetInventoryItemQuality = _G.GetInventoryItemQuality
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

-- Local variables
local containerStorage = {}

-- LUI bag visuals use ordinary texture regions. SharedMedia border files are
-- drawn by eight lightweight edge pieces using the packed coordinates those
-- media files were authored for, keeping background and border rendering fully
-- independent.
local max = math.max
local min = math.min
local BORDER_PIECES = {
    "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner",
    "TopEdge", "BottomEdge", "LeftEdge", "RightEdge",
}
local COORD_START = 0.0625
local COORD_END = 1 - COORD_START
local CORNER_UVS = {
    TopLeftCorner     = {0.5078125, COORD_START, 0.5078125, COORD_END, 0.6171875, COORD_START, 0.6171875, COORD_END},
    TopRightCorner    = {0.6328125, COORD_START, 0.6328125, COORD_END, 0.7421875, COORD_START, 0.7421875, COORD_END},
    BottomLeftCorner  = {0.7578125, COORD_START, 0.7578125, COORD_END, 0.8671875, COORD_START, 0.8671875, COORD_END},
    BottomRightCorner = {0.8828125, COORD_START, 0.8828125, COORD_END, 0.9921875, COORD_START, 0.9921875, COORD_END},
}

-- These bundled 128x16 borders have only 3 or 5 painted pixels across each
-- 16px tile. Crop their transparent margins for the outer bag frame so its
-- thickness setting sizes the painted band, not the mostly empty tile.
local STRIPPED_BANDS = {
    ["interface/addons/lui/media/borders/stripped.tga"] = {1, 6},
    ["interface/addons/lui/media/borders/stripped_medium.tga"] = {2, 5},
    ["interface/addons/lui/media/borders/stripped_hard.tga"] = {1, 6},
}

-- Measured from the Blizzard/Details packed border images: tile size, painted
-- band start/end, and corner extent (exclusive pixel coordinates). Rounded
-- and ornamental corners need more room than the straight painted band.
local MEASURED_BORDERS = {
    ["interface/dialogframe/ui-dialogbox-border"] = {32, 0, 16, 18},
    ["interface/dialogframe/ui-dialogbox-gold-border"] = {32, 0, 16, 18},
    ["interface/tooltips/ui-tooltip-border"] = {16, 1, 6, 9},
    ["interface/addons/details/images/border_3"] = {16, 2, 5, 5},
}

-- Details 1/2 are one-pixel outlines: bevelled and square respectively.
-- Reproduce those contours with solid quads instead of magnifying their tiny
-- corner bitmaps. The outer corner cut stays fixed as the stroke grows inward.
local THIN_OUTLINES = {
    ["interface/addons/details/images/border_1"] = 3,
    ["interface/addons/details/images/border_2"] = 0,
}
local OUTLINE_SEGMENTS = {
    "TopEdge", "TopRightCorner", "RightEdge", "BottomRightCorner",
    "BottomEdge", "BottomLeftCorner", "LeftEdge", "TopLeftCorner",
}

local function UpdateThinOutline(target, skin)
    local width, height = target:GetWidth(), target:GetHeight()
    if issecretvalue(width) or issecretvalue(height) or width <= 0 or height <= 0 then return end
    local thickness = min(skin.borderSize, width / 2, height / 2)
    local cut = min(skin.outlineCut, width / 4, height / 4)
    local innerCut = max(0, cut - (2 - math.sqrt(2)) * thickness)
    innerCut = min(innerCut, (width - 2 * thickness) / 2, (height - 2 * thickness) / 2)
    local function Contour(inset, corner)
        local left, top, right, bottom = inset, inset, width - inset, height - inset
        return {
            {left + corner, top}, {right - corner, top},
            {right, top + corner}, {right, bottom - corner},
            {right - corner, bottom}, {left + corner, bottom},
            {left, bottom - corner}, {left, top + corner},
        }
    end
    local outer, inner = Contour(0, cut), Contour(thickness, innerCut)
    for i, name in ipairs(OUTLINE_SEGMENTS) do
        local nextIndex = i % 8 + 1
        local a, b, c, d = outer[i], outer[nextIndex], inner[nextIndex], inner[i]
        local piece = skin.borderPieces[name]
        piece:ClearAllPoints()
        piece:SetAllPoints(target)
        piece:SetColorTexture(1, 1, 1, 1)
        piece:SetTexCoord(0, 1, 0, 1)
        -- Vertex indices: upper left, lower left, upper right, lower right.
        piece:SetVertexOffset(1, a[1], -a[2])
        piece:SetVertexOffset(3, b[1] - width, -b[2])
        piece:SetVertexOffset(4, c[1] - width, height - c[2])
        piece:SetVertexOffset(2, d[1], height - d[2])
        local color = skin.borderColor
        if color then piece:SetVertexColor(color[1], color[2], color[3], color[4]) end
    end
end

local function UpdateMeasuredBorder(target, skin, profile)
    local tileSize, first, last, cornerEnd = profile[1], profile[2], profile[3], profile[4]
    local bandWidth = last - first
    local edgeSize = skin.borderSize
    local cornerSize = edgeSize * (cornerEnd - first) / bandWidth
    local width, height = target:GetWidth(), target:GetHeight()
    local readable = not issecretvalue(width) and not issecretvalue(height)
    if readable and width > 0 and height > 0 then
        local limit = min(width, height) / 2
        edgeSize = min(edgeSize, limit)
        cornerSize = min(edgeSize * (cornerEnd - first) / bandWidth, limit)
        -- Crop the straight tails of large corners on small item buttons;
        -- reducing the entire skin here would also reduce the chosen thickness.
        cornerEnd = first + cornerSize * bandWidth / edgeSize
    end
    local pieces = skin.borderPieces
    local function Corner(name, tile, right, bottom)
        local x1, x2 = first, cornerEnd
        local y1, y2 = first, cornerEnd
        if right then x1, x2 = tileSize - cornerEnd, tileSize - first end
        if bottom then y1, y2 = tileSize - cornerEnd, tileSize - first end
        pieces[name]:SetSize(cornerSize, cornerSize)
        pieces[name]:SetTexCoord((tile * tileSize + x1) / (8 * tileSize), (tile * tileSize + x2) / (8 * tileSize), y1 / tileSize, y2 / tileSize)
    end
    Corner("TopLeftCorner", 4, false, false)
    Corner("TopRightCorner", 5, true, false)
    Corner("BottomLeftCorner", 6, false, true)
    Corner("BottomRightCorner", 7, true, true)
    pieces.TopEdge:SetHeight(edgeSize)
    pieces.BottomEdge:SetHeight(edgeSize)
    pieces.LeftEdge:SetWidth(edgeSize)
    pieces.RightEdge:SetWidth(edgeSize)

    local repeatX, repeatY = 1, 1
    if readable then
        local tileLength = edgeSize * tileSize / bandWidth
        repeatX = max(1, (width - 2 * cornerSize) / tileLength)
        repeatY = max(1, (height - 2 * cornerSize) / tileLength)
    end
    local textureWidth = 8 * tileSize
    local left1, left2 = first / textureWidth, last / textureWidth
    local right1, right2 = (2 * tileSize - last) / textureWidth, (2 * tileSize - first) / textureWidth
    local top1, top2 = (2 * tileSize + first) / textureWidth, (2 * tileSize + last) / textureWidth
    local bottom1, bottom2 = (4 * tileSize - last) / textureWidth, (4 * tileSize - first) / textureWidth
    pieces.LeftEdge:SetTexCoord(left1, left2, 0, repeatY)
    pieces.RightEdge:SetTexCoord(right1, right2, 0, repeatY)
    pieces.TopEdge:SetTexCoord(top1, repeatX, top2, repeatX, top1, 0, top2, 0)
    pieces.BottomEdge:SetTexCoord(bottom1, repeatX, bottom2, repeatX, bottom1, 0, bottom2, 0)
end

local function SetStrippedBorderCoordinates(pieces, band)
    local first, last = band[1] + 0.5, band[2] - 0.5
    local oppositeFirst, oppositeLast = 16 - last, 16 - first
    local function Corner(name, tile, left, right, top, bottom)
        pieces[name]:SetTexCoord((tile * 16 + left) / 128, (tile * 16 + right) / 128, top / 16, bottom / 16)
    end
    Corner("TopLeftCorner", 4, first, last, first, last)
    Corner("TopRightCorner", 5, oppositeFirst, oppositeLast, first, last)
    Corner("BottomLeftCorner", 6, first, last, oppositeFirst, oppositeLast)
    Corner("BottomRightCorner", 7, oppositeFirst, oppositeLast, oppositeFirst, oppositeLast)
    pieces.LeftEdge:SetTexCoord(first / 128, last / 128, COORD_START, COORD_END)
    pieces.RightEdge:SetTexCoord((16 + oppositeFirst) / 128, (16 + oppositeLast) / 128, COORD_START, COORD_END)
    pieces.TopEdge:SetTexCoord((32 + first) / 128, COORD_END, (32 + last) / 128, COORD_END,
        (32 + first) / 128, COORD_START, (32 + last) / 128, COORD_START)
    pieces.BottomEdge:SetTexCoord((48 + oppositeFirst) / 128, COORD_END, (48 + oppositeLast) / 128, COORD_END,
        (48 + oppositeFirst) / 128, COORD_START, (48 + oppositeLast) / 128, COORD_START)
end

local function SetComplexTexCoord(texture, coords)
    texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4], coords[5], coords[6], coords[7], coords[8])
end

local function FetchBagMedia(mediaType, key, fallback)
    if key == "None" then return nil end
    local texture
    if type(key) == "string" and key ~= "" then
        texture = Media:Fetch(mediaType, key, true)
    end
    if (not texture or texture == "") and fallback then
        texture = Media:Fetch(mediaType, fallback, true)
    end
    return texture ~= "" and texture or nil
end

local function EnsureBagSkin(target)
    local skin = target.LUIBagSkin
    if skin then return skin end

    skin = { borderPieces = {} }
    target.LUIBagSkin = skin

    skin.artwork = target:CreateTexture(nil, "BACKGROUND", nil, -8)
    skin.artwork:SetAllPoints(target)

    skin.tint = target:CreateTexture(nil, "BACKGROUND", nil, -7)
    skin.tint:SetAllPoints(target)

    for _, name in ipairs(BORDER_PIECES) do
        skin.borderPieces[name] = target:CreateTexture(nil, "OVERLAY", nil, 6)
    end

    target:HookScript("OnSizeChanged", function(self)
        module:UpdateSkinBorderCoordinates(self)
    end)
    return skin
end

function module:UpdateSkinBorderCoordinates(target)
    local skin = target and target.LUIBagSkin
    if not skin or not skin.borderTexture then return end
    if skin.outlineCut ~= nil then
        UpdateThinOutline(target, skin)
        return
    end
    if skin.measuredBorder then
        UpdateMeasuredBorder(target, skin, skin.measuredBorder)
        return
    end

    local edgeSize = skin.borderSize or 1
    local width, height = target:GetWidth(), target:GetHeight()
    local readable = not issecretvalue(width) and not issecretvalue(height)
    if skin.fitBorder and readable and width > 0 and height > 0 then
        -- A small toolbar must not end up with overlapping corners.
        edgeSize = min(edgeSize, width / 2, height / 2)
        for _, name in ipairs({"TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner"}) do
            skin.borderPieces[name]:SetSize(edgeSize, edgeSize)
        end
        skin.borderPieces.TopEdge:SetHeight(edgeSize)
        skin.borderPieces.BottomEdge:SetHeight(edgeSize)
        skin.borderPieces.LeftEdge:SetWidth(edgeSize)
        skin.borderPieces.RightEdge:SetWidth(edgeSize)
    end
    if skin.strippedBand then
        SetStrippedBorderCoordinates(skin.borderPieces, skin.strippedBand)
        return
    end
    local repeatX, repeatY = COORD_END, COORD_END
    if readable then
        -- Both frame dimensions and edgeSize are already in the same UI units.
        local corners = skin.fitBorder and 2 or 1
        repeatX = max(COORD_END, width / edgeSize - corners - COORD_START)
        repeatY = max(COORD_END, height / edgeSize - corners - COORD_START)
    end

    local pieces = skin.borderPieces
    pieces.TopEdge:SetTexCoord(0.2578125, repeatX, 0.3671875, repeatX, 0.2578125, COORD_START, 0.3671875, COORD_START)
    pieces.BottomEdge:SetTexCoord(0.3828125, repeatX, 0.4921875, repeatX, 0.3828125, COORD_START, 0.4921875, COORD_START)
    pieces.LeftEdge:SetTexCoord(0.0078125, COORD_START, 0.0078125, repeatY, 0.1171875, COORD_START, 0.1171875, repeatY)
    pieces.RightEdge:SetTexCoord(0.1328125, COORD_START, 0.1328125, repeatY, 0.2421875, COORD_START, 0.2421875, repeatY)
end

function module:RefreshMedia()
    local profile = module.db and module.db.profile
    local db = profile and profile.Textures
    if not db then return end

    module.bagMedia = module.bagMedia or {}
    module.bagMedia.background = FetchBagMedia("background", db.BackgroundTex, "Blizzard Tooltip")
    module.bagMedia.border = FetchBagMedia("border", db.BorderTex, "Stripped_medium")
    module.bagMedia.itemBorder = FetchBagMedia("border", db.ItemBorderTex, "Stripped_medium")
    module.bagMedia.borderSize = math.max(1, tonumber(db.BorderSize) or 5)
    -- Item buttons are only 36 px. Keep the usable range small enough that the
    -- border remains a border instead of swallowing the icon.
    module.bagMedia.itemBorderSize = min(6, math.max(1, tonumber(db.ItemBorderSize) or 3))
end

function module:ApplyBackgroundStyle(target, colorKey)
    if not target then return end
    local skin = EnsureBagSkin(target)
    local texture = module.bagMedia and module.bagMedia.background
    local r, g, b, a = module:RGBA(colorKey)
    r, g, b = tonumber(r) or 1, tonumber(g) or 1, tonumber(b) or 1
    a = tonumber(a) or 1

    skin.tint:SetDrawLayer("BACKGROUND", -8)
    skin.artwork:SetDrawLayer("BACKGROUND", -7)

    if texture then
        -- A selected background texture is artwork, not a color swatch. Never
        -- multiply it by Background Color; only the saved opacity affects it.
        skin.tint:Hide()
        skin.artwork:SetTexture(texture)
        skin.artwork:SetVertexColor(1, 1, 1, 1)
        skin.artwork:SetAlpha(a)
        skin.artwork:Show()
    else
        -- With no artwork selected, Background Color becomes the actual fill.
        skin.artwork:Hide()
        skin.tint:SetColorTexture(r, g, b, a)
        skin.tint:Show()
    end
end

function module:ApplyItemBackgroundStyle(target)
    if not target then return end
    local skin = EnsureBagSkin(target)
    local r, g, b, a = module:RGBA("ItemBackground")
    local name = target:GetName()
    local icon = target.icon or target.Icon or (name and _G[name.."IconTexture"])
    local inset = 3

    -- This is the slot backplate underneath the item icon, similar to a Masque
    -- button backdrop. It is deliberately separate from the item border.
    skin.artwork:Hide()
    skin.tint:SetDrawLayer("BORDER", -8)
    skin.tint:ClearAllPoints()
    -- Keep the backplate beneath the icon, including its transparent parts.
    -- A larger rectangle reads as a second border around narrow/rounded skins.
    if icon then
        skin.tint:SetAllPoints(icon)
    else
        skin.tint:SetPoint("TOPLEFT", target, "TOPLEFT", inset, -inset)
        skin.tint:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", -inset, inset)
    end
    skin.tint:SetColorTexture(tonumber(r) or 0.18, tonumber(g) or 0.18, tonumber(b) or 0.18, tonumber(a) or 0.8)
    skin.tint:Show()
end

function module:HideSkinBorder(target)
    local skin = target and target.LUIBagSkin
    if not skin then return end
    skin.borderTexture = nil
    for _, piece in pairs(skin.borderPieces) do piece:Hide() end
end

function module:SetSkinBorderShown(target, shown)
    local skin = target and target.LUIBagSkin
    if not skin then return end
    for _, piece in pairs(skin.borderPieces) do
        piece:SetShown(shown and skin.borderTexture ~= nil)
    end
end

function module:SetSkinBorderColor(target, r, g, b, a)
    local skin = target and target.LUIBagSkin
    if not skin then return end
    r, g, b, a = tonumber(r) or 1, tonumber(g) or 1, tonumber(b) or 1, tonumber(a) or 1
    skin.borderColor = {r, g, b, a}
    for _, piece in pairs(skin.borderPieces) do piece:SetVertexColor(r, g, b, a) end
end

function module:ApplyBorderStyle(target, edgeTexture, edgeSize, colorKey, fitBorder)
    if not target then return end
    local skin = EnsureBagSkin(target)
    if not edgeTexture then
        module:HideSkinBorder(target)
        return
    end

    edgeSize = math.max(1, tonumber(edgeSize) or 1)
    skin.borderTexture = edgeTexture
    skin.borderSize = edgeSize
    skin.fitBorder = fitBorder
    local texturePath = type(edgeTexture) == "string" and edgeTexture:lower():gsub("\\", "/"):gsub("/+", "/")
    skin.strippedBand = fitBorder and STRIPPED_BANDS[texturePath] or nil
    local measuredPath = texturePath and texturePath:gsub("%.tga$", ""):gsub("%.blp$", "")
    skin.measuredBorder = fitBorder and MEASURED_BORDERS[measuredPath] or nil
    skin.outlineCut = fitBorder and THIN_OUTLINES[measuredPath] or nil
    local pieces = skin.borderPieces

    local topLeft, topRight = pieces.TopLeftCorner, pieces.TopRightCorner
    local bottomLeft, bottomRight = pieces.BottomLeftCorner, pieces.BottomRightCorner
    local top, bottom, left, right = pieces.TopEdge, pieces.BottomEdge, pieces.LeftEdge, pieces.RightEdge

    for _, piece in pairs(pieces) do
        piece:ClearAllPoints()
        -- A different selected texture must not inherit the outline geometry.
        piece:ClearVertexOffsets()
        piece:SetTexture(edgeTexture, true, true)
        piece:Show()
    end

    -- Keep the outside fixed while the border grows inward. The icon/backplate
    -- remains independently anchored and colored.
    topLeft:SetPoint(fitBorder and "TOPLEFT" or "CENTER", target, "TOPLEFT")
    topRight:SetPoint(fitBorder and "TOPRIGHT" or "CENTER", target, "TOPRIGHT")
    bottomLeft:SetPoint(fitBorder and "BOTTOMLEFT" or "CENTER", target, "BOTTOMLEFT")
    bottomRight:SetPoint(fitBorder and "BOTTOMRIGHT" or "CENTER", target, "BOTTOMRIGHT")
    topLeft:SetSize(edgeSize, edgeSize)
    topRight:SetSize(edgeSize, edgeSize)
    bottomLeft:SetSize(edgeSize, edgeSize)
    bottomRight:SetSize(edgeSize, edgeSize)

    top:SetPoint("TOPLEFT", topLeft, "TOPRIGHT")
    top:SetPoint("TOPRIGHT", topRight, "TOPLEFT")
    top:SetHeight(edgeSize)
    bottom:SetPoint("BOTTOMLEFT", bottomLeft, "BOTTOMRIGHT")
    bottom:SetPoint("BOTTOMRIGHT", bottomRight, "BOTTOMLEFT")
    bottom:SetHeight(edgeSize)
    left:SetPoint("TOPLEFT", topLeft, "BOTTOMLEFT")
    left:SetPoint("BOTTOMLEFT", bottomLeft, "TOPLEFT")
    left:SetWidth(edgeSize)
    right:SetPoint("TOPRIGHT", topRight, "BOTTOMRIGHT")
    right:SetPoint("BOTTOMRIGHT", bottomRight, "TOPRIGHT")
    right:SetWidth(edgeSize)

    for name, coords in pairs(CORNER_UVS) do
        SetComplexTexCoord(pieces[name], coords)
    end
    module:UpdateSkinBorderCoordinates(target)
    module:SetSkinBorderColor(target, module:RGBA(colorKey))
end

function module:ApplyBagFrameStyle(target)
    module:ApplyBackgroundStyle(target, "Background")
    local media = module.bagMedia or {}
    module:ApplyBorderStyle(target, media.border, media.borderSize, "Border", true)
end

function module:ApplyItemStyle(target)
    module:ApplyItemBackgroundStyle(target)
    local media = module.bagMedia or {}
    module:ApplyBorderStyle(target, media.itemBorder, media.itemBorderSize, "ItemBorder", true)
    module:SetSkinBorderShown(target, target.LUIHasItem ~= false)
end

function module:SetToolbarSlotBorderColor(slot, container)
    local colorKey = "Border"
    if slot.isBag and slot.inventoryID then
        if container:GetOption("ItemQuality") then
            local quality = GetInventoryItemQuality("player", slot.inventoryID)
            if quality ~= nil then
                local r, g, b = GetItemQualityColor(quality)
                module:SetSkinBorderColor(slot, r, g, b, 1)
                return
            end
        else
            colorKey = "ItemBorder"
        end
    end
    -- Empty bag sockets and utility buttons have no item quality. Use a color
    -- that remains editable while Show Item Quality disables Item Border Color.
    module:SetSkinBorderColor(slot, module:RGBA(colorKey))
end

-- ####################################################################################################################
-- ##### Container Mixin ##############################################################################################
-- ####################################################################################################################

---@class ContainerMixin : Frame
local ContainerMixin = {}

function ContainerMixin:GetDB()
	local profile = module.db and module.db.profile
	return profile and profile[self.profileKey or self.name]
end

function module:ApplyBagTextColor(fontString, colorKey)
	if not fontString then return end
	local r, g, b, a = module:RGBA(colorKey)
	if r and g and b then
		fontString:SetTextColor(r, g, b, a or 1)
	end
end

function module:RefreshBagFontString(fontString, fontKey, colorKey)
	if not fontString then return end
	module:RefreshFontString(fontString, fontKey)
	module:ApplyBagTextColor(fontString, colorKey or fontKey)
end

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
	local db = self:GetDB()
	if db and not db.Lock then
		self:StartMoving()
	end
end

function ContainerMixin:StopMovingFrame()
	self:StopMovingOrSizing()
	local x, y = self:GetCenter()
	local db = self:GetDB()
	if not db then return end
	db.X = x
	db.Y = y
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
	local db = self:GetDB()
	return db and db[name]
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
	local db = self:GetDB()
	local x = db and tonumber(db.X) or 0
	local y = db and tonumber(db.Y) or 0
	if x == 0 and y == 0 then
		self:SetPoint("CENTER", UIParent, "CENTER")
	else
		self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
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
    itemSlot.cooldown = _G[itemSlot:GetName() .. "Cooldown"]
end
-- ####################################################################################################################
-- ##### Container: Slot Update #######################################################################################
-- ####################################################################################################################

--- Base function for updating items.
---@param itemSlot ItemButton
function ContainerMixin:SlotUpdate(itemSlot)
	local id, slot = itemSlot.id, itemSlot.slot
	local data = C_Container.GetContainerItemInfo(id, slot)

	itemSlot:SetHasItem(data ~= nil)
	itemSlot.LUIHasItem = data ~= nil
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
	itemSlot.quality = data and data.quality
	itemSlot.level = nil

	local itemLink = data and data.hyperlink
	if itemLink then
		itemSlot.name = data.itemName

		if self:GetOption("ItemLevel") and C_Item.IsEquippableItem(itemLink) then
			itemSlot.level = GetDetailedItemLevelInfo(itemLink)
		end
	end

	-- LUI's own item border follows item quality when that option is enabled.
	-- The custom Item Border Color is only used when quality coloring is off.
	self:SetItemSlotBorderColor(itemSlot)

	if data then
		SetItemButtonTexture(itemSlot, data.iconFileID)
		SetItemButtonCount(itemSlot, itemSlot.level or data.stackCount)
		SetItemButtonDesaturated(itemSlot, data.isLocked)

		if self:GetOption("ShowOverlay") and itemLink then
			SetItemButtonOverlay(itemSlot, itemLink, data.quality, data.isBound)
		else
			ClearItemButtonOverlay(itemSlot)
		end
	else
		itemSlot:Reset()
	end

	-- Reset may restore the template's normal border on an empty slot.
	itemSlot:SetNormalTexture("")
	local nativeBorder = itemSlot.IconBorder or _G[itemSlot:GetName().."IconBorder"]
	if nativeBorder then nativeBorder:Hide() end
	itemSlot:Show()
end

function ContainerMixin:SetItemSlotBorderColor(itemSlot)
    -- Empty slots have a backplate, but no item/quality border. Keep the skin
    -- configured so a newly occupied slot can show its border without a reload.
    module:SetSkinBorderShown(itemSlot, itemSlot.LUIHasItem ~= false)
    if itemSlot.LUIHasItem == false then return end
    if self:GetOption("ItemQuality") and itemSlot.quality ~= nil then
        local r, g, b = GetItemQualityColor(itemSlot.quality)
        module:SetSkinBorderColor(itemSlot, r, g, b, 1)
    elseif module:IsProfessionBag(itemSlot.id) then
        module:SetSkinBorderColor(itemSlot, module:RGBA("Professions"))
    else
        module:SetSkinBorderColor(itemSlot, module:RGBA("ItemBorder"))
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

	-- Sorting moves items over multiple updates. Reapply the selected layout
	-- after those updates instead of relying only on the initial option click.
	if self.name == "Bags" then
		self:SetAnchors()
	end

	-- Update Search Results if searching
	if self.editbox:IsShown() then
		self:SearchUpdate()
	end
end

-- ####################################################################################################################
-- ##### Container: Set Anchors #######################################################################################
-- ####################################################################################################################

-- Keep the selected presentation independent of the native setting's update
-- timing. Seed existing profiles once from their current sorting direction.
function module:GetFillBagsFromBottom()
    local db = module.db.profile.Bags
    if db.FillFromBottom == nil then
        db.FillFromBottom = not C_Container.GetSortBagsRightToLeft()
    end
    return db.FillFromBottom
end

function module:SetFillBagsFromBottom(value)
    if InCombatLockdown() then return end
    module.db.profile.Bags.FillFromBottom = not not value
    module:SortBags()
end

function module:ResetBagLootOrder(clearSaved)
    for _, container in pairs(containerStorage) do
        container.bottomLootOrder = nil
    end
    if clearSaved and module.db.char then
        module.db.char.BagDisplayOrder = {}
    end
end

local function GetBagSortSnapshot()
    local bags = containerStorage.Bags
    if not bags then return "" end
    local snapshot = {}
    for _, id in ipairs(bags.BAG_ID_LIST) do
        local count = C_Container.GetContainerNumSlots(id)
        snapshot[#snapshot + 1] = id .. ":" .. count
        for slot = 1, count do
            local info = C_Container.GetContainerItemInfo(id, slot)
            if info and info.isLocked then return end
            snapshot[#snapshot + 1] = info and ((info.itemID or 0) .. ":" .. (info.stackCount or 0)) or "-"
        end
    end
    return table.concat(snapshot, ";")
end

function module:CancelBagSortTracking()
    module.bagSortGeneration = (module.bagSortGeneration or 0) + 1
    if module.bagSortTimer then module.bagSortTimer:Cancel(); module.bagSortTimer = nil end
    if module.bagLootLayoutTimer then module.bagLootLayoutTimer:Cancel(); module.bagLootLayoutTimer = nil end
    if module.bagSortWatcher then module.bagSortWatcher:UnregisterAllEvents() end
    module.bagSortSnapshot = nil
    module.bagSortSettling = nil
end

function module:ScheduleBagLootLayout()
    if module.bagLootLayoutTimer then module.bagLootLayoutTimer:Cancel() end
    local generation = module.bagSortGeneration
    module.bagLootLayoutTimer = C_Timer.NewTimer(.25, function()
        if generation ~= module.bagSortGeneration then return end
        module.bagLootLayoutTimer = nil
        local snapshot = GetBagSortSnapshot()
        -- A quiet timer alone is not enough: native cleanup can still have
        -- locked items or outstanding moves. Require two matching unlocked
        -- snapshots, and restart on native bag/lock updates even when closed.
        if snapshot == nil or snapshot ~= module.bagSortSnapshot then
            module.bagSortSnapshot = snapshot
            module:ScheduleBagLootLayout()
            return
        end
        module:CancelBagSortTracking()
        module:ResetBagLootOrder(true)
        for _, container in pairs(containerStorage) do container:Layout() end
    end)
end

function module:WatchBagSort()
    if not module.bagSortWatcher then
        module.bagSortWatcher = CreateFrame("Frame")
        module.bagSortWatcher:SetScript("OnEvent", function(_, event, id)
            if event == "PLAYER_REGEN_ENABLED" then
                module:SortBags()
                return
            end
            if not module.bagSortSettling then return end
            if event ~= "BAG_UPDATE_DELAYED" and not module:IsCharacterBag(id) then return end
            module.bagSortSnapshot = nil
            module:ScheduleBagLootLayout()
        end)
    end
    module.bagSortWatcher:RegisterEvent("BAG_UPDATE")
    module.bagSortWatcher:RegisterEvent("BAG_UPDATE_DELAYED")
    module.bagSortWatcher:RegisterEvent("ITEM_LOCK_CHANGED")
end

function module:ConfigureBagLootInsertion()
    if module.originalBagInsertOrder == nil then
        module.originalBagInsertOrder = C_Container.GetInsertItemsLeftToRight()
    end
    -- Start looting at the opposite end from cleanup: backpack first when
    -- sorting down, last normal bag first when sorting up. Blizzard retains
    -- ownership of bag filters, reagent restrictions and existing stacks.
    local insertFromLastBag = not module:GetFillBagsFromBottom()
    if C_Container.GetInsertItemsLeftToRight() ~= insertFromLastBag then
        C_Container.SetInsertItemsLeftToRight(insertFromLastBag)
    end
end

function module:SortBags()
    if InCombatLockdown() then return end
    module:CancelBagSortTracking()
    module.bagSortSettling = true
    module:ResetBagLootOrder(true)
    local direction = not module:GetFillBagsFromBottom()
    local generation = module.bagSortGeneration
    local attempts = 0
    C_Container.SetSortBagsRightToLeft(direction)
    module:ConfigureBagLootInsertion()

    local function RequestSort()
        if generation ~= module.bagSortGeneration then return end
        module.bagSortTimer = nil
        if InCombatLockdown() then
            module:CancelBagSortTracking()
            module:WatchBagSort()
            module.bagSortWatcher:RegisterEvent("PLAYER_REGEN_ENABLED")
            return
        end
        -- A zero-delay timer does not prove the direction has been applied.
        -- In particular, the first switch to top-fill must not sort using
        -- the previous direction and then cache that intermediate layout.
        if C_Container.GetSortBagsRightToLeft() ~= direction then
            attempts = attempts + 1
            if attempts >= 20 then
                module:CancelBagSortTracking()
                LUI:Print("Bag sorting direction is not ready. Please try Clean Bags again.")
                return
            end
            module.bagSortTimer = C_Timer.NewTimer(.1, RequestSort)
            return
        end
        module:WatchBagSort()
        C_Container.SortBags()
        module:Refresh()
        module:ScheduleBagLootLayout()
    end
    module.bagSortTimer = C_Timer.NewTimer(0, RequestSort)
end

local function RestoreSavedBagOrder(source, saved)
    if type(saved) ~= "table" then return end

    local order, seen = {}, {}
    for i = 1, #saved do
        local slotID = saved[i]
        local slot = type(slotID) == "number" and source[slotID]
        if not slot or not slot:IsShown() or seen[slotID] then return end
        seen[slotID] = true
        order[#order + 1] = slot
    end

    local visible = 0
    for i = 1, #source do
        if source[i]:IsShown() then visible = visible + 1 end
    end
    if #order ~= visible then return end
    return order
end

local function SaveBagOrder(savedBags, id, order)
    local saved = savedBags[id]
    if type(saved) ~= "table" then saved = {} end
    for i = 1, #order do
        saved[i] = order[i].slot
    end
    for i = #saved, #order + 1, -1 do saved[i] = nil end
    savedBags[id] = saved
end

local function GetBagDisplaySlots(container, id, reverseSlots)
    local source = container.itemList[id]
    local visible = 0
    for i = 1, #source do
        if source[i]:IsShown() then visible = visible + 1 end
    end

    -- Never restore, remap or save a loot layout while native cleanup is
    -- moving items. Show actual slots until its updates have settled.
    if module.bagSortSettling then
        local order = {}
        for i = 1, #source do
            local index = reverseSlots and (#source - i + 1) or i
            if source[index]:IsShown() then order[#order + 1] = source[index] end
        end
        return order
    end

    local cache = container.bottomLootOrder
    if not cache or cache.profile ~= module.db.profile or cache.reverseSlots ~= reverseSlots then
        cache = { profile = module.db.profile, reverseSlots = reverseSlots }
        container.bottomLootOrder = cache
    end
    local savedRoot = module.db.char and module.db.char.BagDisplayOrder
    if type(savedRoot) ~= "table" or savedRoot.reverseSlots ~= reverseSlots then
        savedRoot = { reverseSlots = reverseSlots, bags = {} }
        if module.db.char then module.db.char.BagDisplayOrder = savedRoot end
    end
    if type(savedRoot.bags) ~= "table" then savedRoot.bags = {} end

    local order = cache[id]
    if not order or order.source ~= source or #order ~= visible then
        order = RestoreSavedBagOrder(source, savedRoot.bags[id])
    end
    if not order then
        order = {}
        for i = 1, #source do
            local index = reverseSlots and (#source - i + 1) or i
            if source[index]:IsShown() then order[#order + 1] = source[index] end
        end
    end

    -- Keep occupied slots fixed, but reassign currently empty positions in
    -- native insertion order. This also handles holes left by selling or
    -- moving an item, without moving any other visible item on screen.
    local free, empty = {}, {}
    for i = 1, #source do
        local slot = source[i]
        if slot:IsShown() and not C_Container.GetContainerItemInfo(id, slot.slot) then
            free[#free + 1] = slot
            empty[slot] = true
        end
    end
    local nextFree = 1
    for i = 1, #order do
        if empty[order[i]] then
            order[i] = free[reverseSlots and nextFree or (#free - nextFree + 1)]
            nextFree = nextFree + 1
        end
    end

    -- Do not overwrite a useful saved mapping with an empty early-login
    -- snapshot. It can be validated once the real bag size is available.
    if visible > 0 then
        SaveBagOrder(savedRoot.bags, id, order)
    end
    order.source = source
    cache[id] = order
    return order
end

-- Keep every slot anchored directly to the container. Rebuilding chains of
-- sibling anchors on every open invalidates the geometry of later slots too.
-- Read the current anchor so changes by another addon are not hidden by a cache.
local function SetBagSlotPoint(slot, container, x, y)
    if slot:GetNumPoints() == 1 then
        local point, relativeTo, relativePoint, oldX, oldY = slot:GetPoint(1)
        if issecretvalue(point) or issecretvalue(relativeTo) or issecretvalue(relativePoint)
            or issecretvalue(oldX) or issecretvalue(oldY) then return end
        if point == "TOPLEFT" and relativeTo == container and relativePoint == "TOPLEFT"
            and oldX == x and oldY == y then return end
    end
    slot:ClearAllPoints()
    slot:SetPoint("TOPLEFT", container, "TOPLEFT", x, y)
end

function ContainerMixin:SetAnchors()
    local padding = self:GetOption("Padding")
    local spacing = self:GetOption("Spacing")
    local rowSize = self:GetOption("RowSize")
    local bagNewline = self:GetOption("BagNewline")
    local reverseSlots = self.name == "Bags" and module:GetFillBagsFromBottom()
    local column, rows, maxColumns = 0, 0, 0
    for i = 1, self.NUM_BAG_IDS do
        local id = self.BAG_ID_LIST[i]
        local displaySlots = self.name == "Bags" and GetBagDisplaySlots(self, id, reverseSlots) or self.itemList[id]
        if bagNewline then column = 0 end
        for j = 1, #displaySlots do
            local itemSlot = displaySlots[j]
            if itemSlot:IsShown() then
                if column == 0 or column >= rowSize then
                    rows = rows + 1
                    column = 0
                end
                local x = padding + column * (BAG_TEXTURE_SIZE + spacing)
                local y = -(LAYOUT_OFFSET + padding + (rows - 1) * (BAG_TEXTURE_SIZE + spacing))
                SetBagSlotPoint(itemSlot, self, x, y)
                column = column + 1
                maxColumns = max(maxColumns, column)
            end
        end
    end

    -- Item buttons have the fixed BAG_TEXTURE_SIZE set in CreateSlot. Compute
    -- the surface directly instead of sizing the parent from anchored children.
    local width = padding * 2 + maxColumns * BAG_TEXTURE_SIZE + max(0, maxColumns - 1) * spacing
    local height = LAYOUT_OFFSET + padding * 2 + rows * BAG_TEXTURE_SIZE + max(0, rows - 1) * spacing
    local oldWidth, oldHeight = self:GetSize()
    if not issecretvalue(oldWidth) and not issecretvalue(oldHeight)
        and (oldWidth ~= width or oldHeight ~= height) then
        self:SetSize(width, height)
    end
    SetBagSlotPoint(self.background, self, 0, 0)
    oldWidth, oldHeight = self.background:GetSize()
    if not issecretvalue(oldWidth) and not issecretvalue(oldHeight)
        and (oldWidth ~= width or oldHeight ~= height) then
        self.background:SetSize(width, height)
    end
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
				if strfind(strlower(itemSlot.name), text, 1, true) then
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

	-- Hide the native border instead of shrinking it to a visible center pixel.
	-- Keep it transparent even if a native button update shows it again.
	local normalTex = button.NormalTexture or _G[name.."NormalTexture"]
	if normalTex then
		normalTex:SetAlpha(0)
		normalTex:Hide()
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
		module:RefreshBagFontString(count, "Stack")
	end

	-- LUI owns quality coloring; do not stack Blizzard's border underneath it.
	local nativeBorder = button.IconBorder or _G[name.."IconBorder"]
	if nativeBorder then nativeBorder:Hide() end

	module:ApplyItemStyle(button)
	if parent.slotList and parent.container then
		module:SetToolbarSlotBorderColor(button, parent.container)
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

	-- Layout frame for the main bag surface. Visual layers are owned by Bags.
	local bgFrame = CreateFrame("Frame", nil, frame)
	bgFrame:SetFrameLevel(frame:GetFrameLevel())
	frame.background = bgFrame

	-- Close Button
	local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	closeBtn:SetSize(32,32)
	closeBtn:SetPoint("TOPRIGHT", -3, -3)
	closeBtn:RegisterForClicks("AnyUp")
	closeBtn:SetScript("OnClick", function() frame:Close() end)
	frame.closeButton = closeBtn
	local uiElements = LUI:GetModule("UI Elements", true)
	if uiElements and uiElements.RegisterBagCloseButton then
		uiElements:RegisterBagCloseButton(frame, closeBtn)
	end

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

	frame.profileKey = name

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
    if not module.db or not module.db.profile then return end
    module:ConfigureBagLootInsertion()
    module:RefreshMedia()

    for _, container in pairs(containerStorage) do
        local scale = tonumber(container:GetOption("Scale")) or 1
        container:SetScale(scale)
        container:SetPosition()
        container:SetAnchors()

        container.editbox:SetMaxLetters((tonumber(container:GetOption("RowSize")) or 16) * 5)
        module:RefreshBagFontString(container.editbox, "Bags")

        container.searchText:ClearAllPoints()
        container.searchText:SetPoint("TOPLEFT", container, tonumber(container:GetOption("Padding")) or 0, -10)
        container.searchText:SetPoint("TOPRIGHT", container, "TOPRIGHT", -40, 0)
        container.searchText:SetText(SEARCH)

        if container.gold then
            module:RefreshBagFontString(container.gold, "Bags")
            module:RefreshBagFontString(container.currency, "Bags")
        end

        if container.utilBar then
            container.utilBar:ClearAllPoints()
            if container:GetOption("BagBar") and container.bagsBar then
                container.utilBar:SetPoint("LEFT", container.bagsBar, "RIGHT", 4, 0)
            else
                container.utilBar:SetPoint("BOTTOMLEFT", container, "TOPLEFT", 0, 2)
            end
        end

        module:ApplyBagFrameStyle(container.background)

        for i = 1, container.NUM_BAG_IDS do
            local id = container.BAG_ID_LIST[i]
            for j = 1, #container.itemList[id] do
                local slot = container.itemList[id][j]
                module:ApplyItemStyle(slot)
                container:SlotUpdate(slot)
                local count = slot.Count or _G[slot:GetName().."Count"]
                if count then module:RefreshBagFontString(count, "Stack") end
            end
        end

        for _, toolbar in pairs(container.toolbars) do
            module:ApplyBagFrameStyle(toolbar.background)
            toolbar:SetAnchors()
            if toolbar == container.bagsBar then
                toolbar:SetShown(container:GetOption("BagBar"))
            end
            for i = 1, #toolbar.slotList do
                local slot = toolbar.slotList[i]
                module:ApplyItemStyle(slot)
                module:SetToolbarSlotBorderColor(slot, container)
            end
        end

        container.forceRefresh = false
    end

    module:RefreshColors()
end

function module:RefreshColors()
    for _, container in pairs(containerStorage) do
        module:ApplyBackgroundStyle(container.background, "Background")
        module:SetSkinBorderColor(container.background, module:RGBA("Border"))

        module:ApplyBagTextColor(container.searchText, "Search")
        module:ApplyBagTextColor(container.editbox, "Bags")
        if container.gold then
            module:ApplyBagTextColor(container.gold, "Bags")
            module:ApplyBagTextColor(container.currency, "Bags")
        end

        for i = 1, container.NUM_BAG_IDS do
            local id = container.BAG_ID_LIST[i]
            for j = 1, #container.itemList[id] do
                local itemSlot = container.itemList[id][j]
                module:ApplyItemBackgroundStyle(itemSlot)
                container:SetItemSlotBorderColor(itemSlot)
                local count = itemSlot.Count or _G[itemSlot:GetName().."Count"]
                module:ApplyBagTextColor(count, "Stack")
            end
        end

        for _, toolbar in pairs(container.toolbars) do
            module:ApplyBackgroundStyle(toolbar.background, "Background")
            module:SetSkinBorderColor(toolbar.background, module:RGBA("Border"))
            for i = 1, #toolbar.slotList do
                local slot = toolbar.slotList[i]
                module:ApplyItemBackgroundStyle(slot)
                module:SetToolbarSlotBorderColor(slot, container)
            end
        end
    end
end

function module:SetBags()
	module:RefreshMedia()
	module:CreateNewContainer("Bags", module.BagsContainer)
	if not LUIBags.gold then
		LUIBags:CreateTitleBar()
	else
		LUIBags:RegisterTitleBarEvents()
	end
	LUIBags:SetBagsProperties()
end

function module:RestoreBlizzardBagState()
	module:CancelBagSortTracking()
	module:ResetBagLootOrder(false)
	if module.originalBagInsertOrder ~= nil then
		C_Container.SetInsertItemsLeftToRight(module.originalBagInsertOrder)
		module.originalBagInsertOrder = nil
	end
	if _G.LUIBags then _G.LUIBags:UnregisterAllEvents() end
end
