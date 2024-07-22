-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Artwork : LUIModule
---@field db LUI.Artwork.DB
local module = LUI:NewModule("Artwork", "AceHook-3.0")
local db

-- ####################################################################################################################
-- ##### Default Settings #############################################################################################
-- ####################################################################################################################

---@class LUI.Artwork.DB
module.defaults = {
	profile = {
		LUITextures = {
			Orb = {
				Enabled = true,
				LostGalaxy = false,
			},
			NavBar = {

			},
			Chat = {
				OffsetX = 0,
				OffsetY = 0,
				AlwaysShow = false,
				IsShown = false,
				Direction = "TOPRIGHT",
				Animation = true,
				Width = 429,
				Height = 181
			},
			Tps = {
				OffsetX = 0,
				OffsetY = 0,
				Anchor = "DetailsBaseFrame2",
				Additional = "DetailsRowFrame2",
				AlwaysShow = false,
				IsShown = false,
				Direction = "TOP",
				Animation = true,
				Width = 193,
				Height = 181
			},
			Dps = {
				OffsetX = 0,
				OffsetY = 0,
				Anchor = "DetailsBaseFrame1",
				Additional = "DetailsRowFrame1",
				AlwaysShow = false,
				IsShown = false,
				Direction = "TOP",
				Animation = true,
				Width = 193,
				Height = 181
			},
			Raid = {
				OffsetX = 0,
				OffsetY = 0,
				Anchor = "oUF_LUI_raid",
				Additional = "",
				AlwaysShow = false,
				IsShown = false,
				Direction = "TOPLEFT",
				Animation = false,
				Width = 409,
				Height = 181
			},
			["Chat Background"] = {
				Created = true,
				Enabled = true,
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
			["Chat Border"] = {
				Created = true,
				Enabled = true,
				Anchored = true,
				TexMode = 1,
				Texture = "panel_corner.tga",
				Point = "TOPRIGHT",
				Parent = "ChatFrame1",
				RelativePoint = "TOPRIGHT",
				CustomTexCoords = false,
				HorizontalFlip = true,
				VerticalFlip = false,
				Width = 450,
				Height = 190,
				Order = 2,
				X = 3,
				Y = 4,
				Left = 0,
				Right = 1,
				Up = 0,
				Down = 1,
			},
			["Top Bar"] = {
				Created = true,
				Enabled = true,
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
		},
		SideBars = {
			---@class (exact) SidebarDBOptions
			Right = {
				Enable = true,
				OpenInstant = false,
				Offset = 0,
				IsOpen = false,
				Anchor = "BT4Bar10",
				Additional = "",
				AutoPosition = false,
				HideEmpty = true,
				X = 15,
				Y = 0,
				Scale = 0.711,
				Point = "RIGHT",
			},
			Left = {
				Enable = true,
				OpenInstant = false,
				Offset = 0,
				IsOpen = false,
				Anchor = "BT4Bar9",
				Additional = "",
				AutoPosition = false,
				HideEmpty = true,
				X = 15,
				Y = 0,
				Scale = 0.711,
				Point = "LEFT",
			},
		},
		Textures = {
			---@class (exact) PanelDBOptions
			['*'] = {
				Created = false,
				Enabled = false,
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
			SidebarRight = { r = 0.12, g = 0.12,  b = 0.12, a = 1, t = "Class", },
			SidebarLeft = { r = 0.12, g = 0.12,  b = 0.12, a = 1, t = "Class", },
			['*'] = { r = 0.12, g = 0.12,  b = 0.12, a = 1, t = "Class", },
		}
	},
}

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

function module:OnInitialize()
	LUI:RegisterModule(module)
end

function module:OnEnable()
	module:setPanels()
	module:setMainPanels()
	local bar = module:CreateNewSideBar("Right", "Right")
	--local bar2 = module:CreateNewSideBar("Left", "Left")
	module:CreateOrb()
	module:CreateNavBar()
end

function module:OnDisable()
end
