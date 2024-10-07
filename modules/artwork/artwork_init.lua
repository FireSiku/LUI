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
			NavBar = {
				Enabled = true,
				ShowOrb = true,
				ShowButtons = true,
				TopBackground = true,
				CenterBackground = true,
				ThemedLines = true,
				BlackLines = true,
				LostGalaxy = false,
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
			["ActionBarTopTexture"] = {
				Created = true,
				Enabled = true,
				Anchored = true,
				TexMode = 1,
				Texture = "bar_top.tga",
				Point = "BOTTOM",
				Parent = "UIParent",
				RelativePoint = "BOTTOM",
				CustomTexCoords = false,
				HorizontalFlip = false,
				VerticalFlip = false,
				Width = 500,
				Height = 32,
				Order = 3,
				X = 0,
				Y = 110,
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
				Scale = 1,
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
				Scale = 1,
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
			ActionBarTopTexture = { r = 0.12, g = 0.12,  b = 0.12, a = 0.5, t = "Class", },
			SidebarRight = { r = 0.12, g = 0.12,  b = 0.12, a = 1, t = "Class", },
			SidebarLeft = { r = 0.12, g = 0.12,  b = 0.12, a = 1, t = "Class", },
			NavButtons = { r = 0.12, g = 0.12,  b = 0.12, a = 0.75, t = "Class", },
			Chat = { r = 0.12, g = 0.12,  b = 0.12, a = 0.4, t = "Class", },
			Tps = { r = 0.12, g = 0.12,  b = 0.12, a = 0.4, t = "Class", },
			Dps = { r = 0.12, g = 0.12,  b = 0.12, a = 0.4, t = "Class", },
			Raid = { r = 0.12, g = 0.12,  b = 0.12, a = 0.4, t = "Class", },
			ChatBorder = { r = 0.12, g = 0.12,  b = 0.12, a = 0.4, t = "Class", },
			TpsBorder = { r = 0.12, g = 0.12,  b = 0.12, a = 0.4, t = "Class", },
			DpsBorder = { r = 0.12, g = 0.12,  b = 0.12, a = 0.4, t = "Class", },
			RaidBorder = { r = 0.12, g = 0.12,  b = 0.12, a = 0.4, t = "Class", },
			Orb = { r = 0.12, g = 0.12,  b = 0.12, a = 1, t = "Class", },
			TopPanel = { r = 0.12, g = 0.12,  b = 0.12, a = 0.75, t = "Class", },
			LeftBorder = { r = 0, g = 0,  b = 0, a = 1, t = "Individual", },
			RightBorder = { r = 0, g = 0,  b = 0, a = 1, t = "Individual", },
			LeftBorderBack = { r = 0.12, g = 0.12,  b = 0.12, a = 0.75, t = "Class", },
			RightBorderBack = { r = 0.12, g = 0.12,  b = 0.12, a = 0.75, t = "Class", },
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
