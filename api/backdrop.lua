--- LUI-owned scalable frame backgrounds and SharedMedia borders.

---@class LUIAddon
local LUI = select(2, ...)

local max = math.max

-- SharedMedia border files use the packed coordinates supported by
-- Blizzard's current backdrop renderer. LUI owns these texture regions, so
-- target frames do not need Blizzard's legacy backdrop mixin.
local COORD_START = 0.0625
local COORD_END = 1 - COORD_START
local CORNER_UVS = {
	TopLeftCorner = {0.5078125, COORD_START, 0.5078125, COORD_END, 0.6171875, COORD_START, 0.6171875, COORD_END},
	TopRightCorner = {0.6328125, COORD_START, 0.6328125, COORD_END, 0.7421875, COORD_START, 0.7421875, COORD_END},
	BottomLeftCorner = {0.7578125, COORD_START, 0.7578125, COORD_END, 0.8671875, COORD_START, 0.8671875, COORD_END},
	BottomRightCorner = {0.8828125, COORD_START, 0.8828125, COORD_END, 0.9921875, COORD_START, 0.9921875, COORD_END},
}
local BORDER_PIECES = {
	"TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner",
	"TopEdge", "BottomEdge", "LeftEdge", "RightEdge",
}

local function SetComplexTexCoord(texture, coords)
	texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4], coords[5], coords[6], coords[7], coords[8])
end

local function UpdateCoordinates(frame)
	local state = frame.__luiBackdrop
	if not state or not state.info then return end

	local info = state.info
	local edgeSize = state.edgeSize
	local scale = frame:GetEffectiveScale()
	local repeatX = max(0, (frame:GetWidth() / edgeSize) * scale - 2 - COORD_START)
	local repeatY = max(0, (frame:GetHeight() / edgeSize) * scale - 2 - COORD_START)
	local pieces = state.pieces

	pieces.TopEdge:SetTexCoord(0.2578125, repeatX, 0.3671875, repeatX, 0.2578125, COORD_START, 0.3671875, COORD_START)
	pieces.BottomEdge:SetTexCoord(0.3828125, repeatX, 0.4921875, repeatX, 0.3828125, COORD_START, 0.4921875, COORD_START)
	pieces.LeftEdge:SetTexCoord(0.0078125, COORD_START, 0.0078125, repeatY, 0.1171875, COORD_START, 0.1171875, repeatY)
	pieces.RightEdge:SetTexCoord(0.1328125, COORD_START, 0.1328125, repeatY, 0.2421875, COORD_START, 0.2421875, repeatY)

	if info.tile then
		local tileSize = tonumber(info.tileSize) or edgeSize
		if tileSize > 0 then
			pieces.Center:SetTexCoord(0, (frame:GetWidth() / tileSize) * scale, 0, (frame:GetHeight() / tileSize) * scale)
		end
	else
		pieces.Center:SetTexCoord(0, 1, 0, 1)
	end
end

local function CreateBackdrop(frame)
	local state = {
		backgroundColor = {1, 1, 1, 1},
		borderColor = {1, 1, 1, 1},
		pieces = {},
	}
	frame.__luiBackdrop = state

	local pieces = state.pieces
	pieces.Center = frame:CreateTexture(nil, "BACKGROUND")
	for _, name in ipairs(BORDER_PIECES) do
		pieces[name] = frame:CreateTexture(nil, "BORDER")
	end

	frame:HookScript("OnSizeChanged", UpdateCoordinates)
	return state
end

--- Draw a scalable background and packed SharedMedia border.
---@param frame Frame
---@param info backdropInfo
function LUI:ApplyFrameBackdrop(frame, info)
	if not info or (not info.bgFile and not info.edgeFile) then
		return self:ClearFrameBackdrop(frame)
	end

	local state = frame.__luiBackdrop or CreateBackdrop(frame)
	local pieces = state.pieces
	local edgeSize = tonumber(info.edgeSize) or 39
	if edgeSize <= 0 then edgeSize = 1 end
	state.info = info
	state.edgeSize = edgeSize

	local background = pieces.Center
	local insets = info.insets or {}
	-- Blizzard's BackdropTemplate applies its center offsets relative to the
	-- inner corners of the NineSlice. These LUI textures are anchored directly
	-- to the owner frame, so only the final insets belong here. Applying the
	-- intermediate -edgeSize/+edgeSize offsets directly to the frame makes the
	-- background protrude beyond the border by edgeSize minus the inset.
	background:ClearAllPoints()
	background:SetPoint("TOPLEFT", frame, "TOPLEFT", insets.left or 0, -(insets.top or 0))
	background:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -(insets.right or 0), insets.bottom or 0)
	background:SetTexture(info.bgFile, info.tile == true, info.tile == true)
	background:SetVertexColor(unpack(state.backgroundColor))
	background:SetShown(info.bgFile ~= nil)

	local topLeft = pieces.TopLeftCorner
	local topRight = pieces.TopRightCorner
	local bottomLeft = pieces.BottomLeftCorner
	local bottomRight = pieces.BottomRightCorner
	topLeft:ClearAllPoints()
	topRight:ClearAllPoints()
	bottomLeft:ClearAllPoints()
	bottomRight:ClearAllPoints()
	topLeft:SetPoint("TOPLEFT", frame)
	topRight:SetPoint("TOPRIGHT", frame)
	bottomLeft:SetPoint("BOTTOMLEFT", frame)
	bottomRight:SetPoint("BOTTOMRIGHT", frame)
	topLeft:SetSize(edgeSize, edgeSize)
	topRight:SetSize(edgeSize, edgeSize)
	bottomLeft:SetSize(edgeSize, edgeSize)
	bottomRight:SetSize(edgeSize, edgeSize)

	pieces.TopEdge:ClearAllPoints()
	pieces.TopEdge:SetPoint("TOPLEFT", topLeft, "TOPRIGHT")
	pieces.TopEdge:SetPoint("TOPRIGHT", topRight, "TOPLEFT")
	pieces.TopEdge:SetHeight(edgeSize)
	pieces.BottomEdge:ClearAllPoints()
	pieces.BottomEdge:SetPoint("BOTTOMLEFT", bottomLeft, "BOTTOMRIGHT")
	pieces.BottomEdge:SetPoint("BOTTOMRIGHT", bottomRight, "BOTTOMLEFT")
	pieces.BottomEdge:SetHeight(edgeSize)
	pieces.LeftEdge:ClearAllPoints()
	pieces.LeftEdge:SetPoint("TOPLEFT", topLeft, "BOTTOMLEFT")
	pieces.LeftEdge:SetPoint("BOTTOMLEFT", bottomLeft, "TOPLEFT")
	pieces.LeftEdge:SetWidth(edgeSize)
	pieces.RightEdge:ClearAllPoints()
	pieces.RightEdge:SetPoint("TOPRIGHT", topRight, "BOTTOMRIGHT")
	pieces.RightEdge:SetPoint("BOTTOMRIGHT", bottomRight, "TOPRIGHT")
	pieces.RightEdge:SetWidth(edgeSize)

	local tileEdge = info.tileEdge ~= false
	for _, name in ipairs(BORDER_PIECES) do
		local piece = pieces[name]
		piece:SetTexture(info.edgeFile, tileEdge, tileEdge)
		piece:SetVertexColor(unpack(state.borderColor))
		piece:SetShown(info.edgeFile ~= nil)
	end
	for name, coords in pairs(CORNER_UVS) do
		SetComplexTexCoord(pieces[name], coords)
	end
	UpdateCoordinates(frame)
end

---@param frame Frame
function LUI:ClearFrameBackdrop(frame)
	local state = frame.__luiBackdrop
	if not state then return end
	state.info = nil
	for _, piece in pairs(state.pieces) do
		piece:Hide()
	end
end

---@param frame Frame
function LUI:SetFrameBackgroundColor(frame, r, g, b, a)
	local state = frame.__luiBackdrop
	if not state then return end
	state.backgroundColor[1], state.backgroundColor[2], state.backgroundColor[3], state.backgroundColor[4] = r, g, b, a or 1
	state.pieces.Center:SetVertexColor(r, g, b, a or 1)
end

---@param frame Frame
function LUI:SetFrameBorderColor(frame, r, g, b, a)
	local state = frame.__luiBackdrop
	if not state then return end
	state.borderColor[1], state.borderColor[2], state.borderColor[3], state.borderColor[4] = r, g, b, a or 1
	for _, name in ipairs(BORDER_PIECES) do
		state.pieces[name]:SetVertexColor(r, g, b, a or 1)
	end
end

--- Attach a fixed image or fill to a frame without creating a backdrop.
---@param frame Frame
---@param texture string|number
---@param layer? DrawLayer
---@param subLevel? number
---@return Texture
function LUI:CreateFrameTexture(frame, texture, layer, subLevel)
	local region = frame:CreateTexture(nil, layer or "BACKGROUND", nil, subLevel)
	region:SetAllPoints(frame)
	region:SetTexture(texture)
	return region
end
