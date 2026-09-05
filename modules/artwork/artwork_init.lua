-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Artwork : LUIModule
---@field db LUI.Artwork.DB
local module = LUI:NewModule("Artwork", "AceHook-3.0")
module.enableButton = true
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
				Scale = 1,
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
				IsOpen = false,
				Anchor = "BT4Bar10",
				AutoPosition = false,
				X = 15,
				Y = 0,
				Scale = 1,
				Point = "RIGHT",
			},
			Left = {
				Enable = false,
				OpenInstant = false,
				IsOpen = false,
				Anchor = "BT4Bar9",
				AutoPosition = false,
				X = -15,
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
				Texture = "panel_corner_fill.tga",
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
	local leftSidebar = module.db.profile.SideBars.Left
	local rightSidebar = module.db.profile.SideBars.Right
	for _, sidebar in ipairs({leftSidebar, rightSidebar}) do
		local oldDominosID = type(sidebar.Anchor) == "string" and sidebar.Anchor:match("^Dominos Bar(%d+)$")
		if oldDominosID then
			sidebar.Anchor = "DominosFrame"..oldDominosID
		end
	end
	if not leftSidebar.PositionMigration2609 then
		if leftSidebar.Point == "LEFT" and leftSidebar.X == 15 then
			leftSidebar.X = -15
		end
		leftSidebar.PositionMigration2609 = true
	end

	if not module.artworkCreated then
		module:setPanels()
		module:setMainPanels()
		module:CreateNewSideBar("Right", "Right")
		module:CreateNewSideBar("Left", "Left")
		module:CreateOrb()
		module:CreateNavBar()
		module.artworkCreated = true
	else
		module:Refresh()
	end
end

local function DisableArtwork()
	if module:IsEnabled() or not module.artworkCreated then return end
	if module.SetChatVisible then module:SetChatVisible(true) end

	if module.ActionBarTop then module.ActionBarTop:Hide() end
	for _, panel in module:IteratePanels() do panel:Hide() end
	for kind, panel in module:IterateMainPanels() do
		panel.AlphaIn:Hide()
		panel.AlphaIn.timerin = 0
		panel.AlphaOut:Hide()
		panel.AlphaOut.timerout = 0
		panel:Hide()
		local data = module.db.profile.LUITextures[kind]
		local anchor = _G[panel.frame]
		if module:CanAlterFrame(anchor) then
			anchor:SetAlpha(1)
			anchor:Show()
		end
		for _, frameName in pairs(module:LoadAdditional(data.Additional)) do
			local frame = _G[frameName]
			if module:CanAlterFrame(frame) then
				frame:SetAlpha(1)
				frame:Show()
			end
		end
	end

	for _, sidebar in module:IterateSidebars() do
		local anchor = _G[sidebar.db.Anchor]
		if module:CanAlterFrame(anchor) then anchor:Show() end
		sidebar:Hide()
	end

	if module.Orb then module.Orb:Hide() end
	if module.NavBar then module.NavBar:Hide() end
	if module.NavBarCenter then module.NavBarCenter:Hide() end
	if module.TopPanel then module.TopPanel:Hide() end
	if module.LeftBorder then module.LeftBorder:Hide() end
	if module.LeftBorderBack then module.LeftBorderBack:Hide() end
	if module.RightBorder then module.RightBorder:Hide() end
	if module.RightBorderBack then module.RightBorderBack:Hide() end
	for _, button in module:IterateNavButtons() do button:Hide() end
end

local DisableArtworkOutOfCombat = LUI.OutOfCombatWrapper(DisableArtwork)

function module:OnDisable()
	DisableArtworkOutOfCombat()
end
