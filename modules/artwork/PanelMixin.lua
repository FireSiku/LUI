---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Artwork : LUIModule
local module = LUI:GetModule("Artwork")

---@class PanelMixin
local PanelMixin = {}

local LUI_TEX_DIR = "Interface\\AddOns\\LUI\\media\\textures\\"

-- Table to keep info about preset textures.
-- First four are tex coords (Left, Right, Up, Down)
-- next two are Width/Length of the visible texture.
local LUI_TEXTURES_INFO = {
	["left_border.tga"] =         {20/1024,  595/1024, 231/512, 492/512, 575, 261},
	["left_border_back.tga"] =    {20/1024,  595/1024, 231/512, 492/512, 575, 261},
	["panel_corner_fill.tga"] =   {22/512,   372/512,  12/256,  183/256, 350, 85 },
	["panel_corner_border.tga"] = {14/512,   341/512,  5/256,   145/256, 327, 140},
	["panel_center_border.tga"] = {10/256,   246/256,  9/256,   168/256, 236, 159},
	["bar_top.tga"] =             {161/1024, 863/1024, 13/64,   52/64,   702, 34 },
}

-- ####################################################################################################################
-- ##### Mixin Functions ##############################################################################################
-- ####################################################################################################################

--- Get the parent frame of the panel.
---@return Frame parent
function PanelMixin:GetParent()
	--TODO: Add support for LibWindow for proper texture scaling when not anchored.
	if self.db.Anchored then
		return _G[self.db.Parent]
	else
		return UIParent
	end
end

--- Get the texture path
---@return string texturePath
function PanelMixin:GetTexture()
	-- TODO: Add support for various texture directories in the future.
	if self.db.TexMode == 3 then
		return self.db.Texture
	else
		return LUI_TEX_DIR..self.db.Texture
	end
end

--- Get the texture coordinates, taking flipping into account.
---@return number left
---@return number right
---@return number up
---@return number down
function PanelMixin:GetTexCoord()
	--PH: Grab TexCoord valuess from self.db.entries
	local left, right, up, down = self.db.Left, self.db.Right, self.db.Up, self.db.Down

	if LUI_TEXTURES_INFO[self.db.Texture] then
		local coord = LUI_TEXTURES_INFO[self.db.Texture]
		left, right, up, down = coord[1], coord[2], coord[3], coord[4]
	end

	local hFlip = self.db.HorizontalFlip
	local vFlip = self.db.VerticalFlip

	if hFlip and vFlip then
		--Flip Horizontally and Vertically
		return right, left, down, up
	elseif hFlip and not vFlip then
		--Flip Horizontally only
		return right, left, up, down
	elseif vFlip and not hFlip then
		--Flip Vertically only
		return left, right, down, up
	else
		--Do not flip
		return left, right, up, down
	end
end

--- Refresh the panel's settings and position
function PanelMixin:Refresh()
	local parent = self:GetParent()
	local r, g, b, a = module:RGBA(self.name)

	--self:SetPoint(self.db.Point, parent, self.db.RelativePoint, self.db.X, self.db.Y)
	self:SetSize(self.db.Width, self.db.Height)
	LUI:RegisterConfig(self, self.db)
	LUI:RestorePosition(self)
	self:SetParent(parent)
	self:SetAlpha(a)
	self.tex:SetTexture(self:GetTexture())
	self.tex:SetTexCoord(self:GetTexCoord())
	self.tex:SetDesaturated(true)
	self.tex:SetVertexColor(r, g, b)

	if self.db.Enabled then
		self:Show()
	else
		self:Hide()
	end

end

module.PanelMixin = PanelMixin
