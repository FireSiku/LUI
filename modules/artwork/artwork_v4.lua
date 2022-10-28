-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

local _, LUI = ...
local module = LUI:NewModule("Artwork")
local L = LUI.L
local db

-- ####################################################################################################################
-- ##### Default Settings #############################################################################################
-- ####################################################################################################################

module.defaults = {
	profile = {
		Textures = {
			ChatBG = {
				Anchored = true,
				TexMode = 1,
				Texture = "panel_corner.tga",
				Point = "TOPRIGHT",
				Parent = "ChatFrame1",
				RelativePoint = "TOPRIGHT",
				CustomTexCoords = false,
				HorizontalFlip = true,
				VerticalFlip = false,
				Width = 409,
				Height = 182,
				Order = 1,
				X = 3,
				Y = 4,
				Left = 0,
				Right = 1,
				Up = 0,
				Down = 1,
			},
		--[[	TestBG = {
				Anchored = true,
				TexMode = 1,
				Texture = "panel_corner.tga",
				Point = "TOPLEFT",
				Parent = "ObjectiveTrackerFrame",
				RelativePoint = "TOPLEFT",
				CustomTexCoords = false,
				HorizontalFlip = false,
				VerticalFlip = false,
				Width = 409,
				Height = 182,
				Order = 2,
				X = -25,
				Y = -2,
				Left = 0,
				Right = 1,
				Up = 0,
				Down = 1,
			},]]
			["Top Bar"] = {
				Anchored = false,
				TexMode = 1,
				Texture = "bar_top.tga",
				Point = "BOTTOM",
				Parent = "UIParent",
				RelativePoint = "BOTTOM",
				CustomTexCoords = false,
				HorizontalFlip = false,
				VerticalFlip = false,
				Width = 702,
				Height = 36,
				Order = 3,
				X = 0,
				Y = 120,
				Left = 0,
				Right = 1,
				Up = 0,
				Down = 1,
			},
			['*'] = {
				Anchored = true,
				TexMode = 1,
				Texture = "panel_corner.tga",
				Point = "CENTER",
				Parent = "UIParent",
				RelativePoint = "CENTER",
				CustomTexCoords = false,
				HorizontalFlip = false,
				VerticalFlip = false,
				Width = 400,
				Height = 300,
				Order = 100,
				X = 0,
				Y = 0,
				Scale = 1,
				Left = 0,
				Right = 1,
				Up = 0,
				Down = 1,
			},
		},
		Colors = {
			ChatBG = { r = 0.12, g = 0.12,  b = 0.12, a = 0.5, t = "Class", },
			["Top Bar"] = { r = 0.12, g = 0.12,  b = 0.12, a = 0.5, t = "Class", },
			['*'] = { r = 0.12, g = 0.12,  b = 0.12, a = 1, t = "Class", },
		}
	},
}

-- ####################################################################################################################
-- ##### Constant Tables ##############################################################################################
-- ####################################################################################################################

-- Table to keep info about preset textures.
-- First four are tex coords (Left, Right, Up, Down)
-- next two are Width/Length of the visible texture.
local LUI_TEXTURES_INFO = {
	["left_border.tga"] =         {20/1024,  595/1024, 231/512, 492/512, 575, 261},
	["left_border_back.tga"] =    {20/1024,  595/1024, 231/512, 492/512, 575, 261},
	["panel_corner.tga"] =        {22/512,   372/512,  12/256,  183/256, 350, 85 },
	["panel_corner_border.tga"] = {14/512,   341/512,  5/256,   145/256, 327, 140},
	["panel_center_border.tga"] = {10/256,   246/256,  9/256,   168/256, 236, 159},
	["bar_top.tga"] =             {161/1024, 863/1024, 13/64,   52/64,   702, 34 },
}

--Table to hold all panels frames.
local _panels = {}

-- LUI Textures Directory
local LUI_TEX_DIR = "Interface\\AddOns\\LUI4\\media\\textures\\"

-- ####################################################################################################################
-- ##### Panel Mixin ##################################################################################################
-- ####################################################################################################################

local PanelMixin = {}

function PanelMixin:GetParent()
	--TODO: Add support for LibWindow for proper texture scaling when not anchored.
	if self.db.Anchored then
		return _G[self.db.Parent]
	else
		return UIParent
	end
end

function PanelMixin:GetTexture()
	-- TODO: Add support for various texture directories in the future.
	if self.db.TexMode == 3 then
		return self.db.Texture
	else
		return LUI_TEX_DIR..self.db.Texture
	end
end

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

function PanelMixin:Refresh()
	local parent = _G[self.db.Parent]
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

end

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

function module:CreateNewPanel(name, db)
	local panel = CreateFrame("Frame", "LUIPanel_"..name, UIParent)
	LUI:RegisterConfig(panel, db)
	LUI:RestorePosition(panel)
	-- LUI:MakeDraggable(panel)
	-- panel:EnableMouse(true)
	Mixin(panel, PanelMixin)

	local tex = panel:CreateTexture(nil, "BACKGROUND")
	tex:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT")
	tex:SetPoint("TOPLEFT", panel, "TOPLEFT")
	
	_panels[name] = panel
	panel.name = name
	panel.tex = tex
	panel.db = db

	panel:Refresh()
	return panel
end

function module:setPanels()
	module.panelList = {}

	for name, paneldb in pairs(db.Textures) do
		local frame = module:CreateNewPanel(name, paneldb)
		table.insert(module.panelList, name)
	end
	sort(module.panelList, function(a, b)
		return db.Textures[a].Order < db.Textures[b].Order
	end)
end

function module:GetPanelByName(name)
	return _panels[name]
end

function module:Refresh()
	for name, panel in pairs(_panels) do
		panel:Refresh()
	end
end

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function module:OnInitialize()
	LUI:RegisterModule(module)
	db = module.db.profile
end

function module:OnEnable()
	module:setPanels()
end

function module:OnDisable()
end
