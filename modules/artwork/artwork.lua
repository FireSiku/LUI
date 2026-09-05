-- Artwork panel lifecycle. Custom panels are regular frames and are safe to
-- refresh immediately; the complete refresh is deferred while in combat.

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Artwork : LUIModule
local module = LUI:GetModule("Artwork")

local customPanels = {}

local refreshQueue = CreateFrame("Frame")
refreshQueue:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	if module:IsEnabled() then module:Refresh() end
end)

local function CreatePanelFrame(name)
	local panel = CreateFrame("Frame", "LUIPanel_"..name, UIParent)
	Mixin(panel, module.PanelMixin)

	local texture = panel:CreateTexture(nil, "BACKGROUND")
	texture:SetAllPoints(panel)
	panel.name = name
	panel.tex = texture
	return panel
end

function module:CreateNewPanel(name, panelDB)
	local panel = customPanels[name] or CreatePanelFrame(name)
	customPanels[name] = panel
	panel.db = panelDB
	panel:Refresh()
	return panel
end

function module:DeletePanel(name)
	local panel = customPanels[name]
	if panel then
		panel:Hide()
		panel.db = nil
	end
end

function module:IteratePanels()
	return pairs(customPanels)
end

local function CreateActionBarTop()
	local panel = CreatePanelFrame("ActionBarTopTexture")
	panel.db = module.db.profile.LUITextures.ActionBarTopTexture
	return panel
end

function module:setPanels()
	local profile = self.db.profile
	local activePanels = {}
	self.panelList = {}

	for name, panelDB in pairs(profile.Textures) do
		-- Older defaults referred to a texture name that never existed in the
		-- shipped media directory. Repair it without touching valid custom paths.
		if panelDB.Texture == "panel_corner.tga" then
			panelDB.Texture = "panel_corner_fill.tga"
		end
		activePanels[name] = true
		self:CreateNewPanel(name, panelDB)
		table.insert(self.panelList, name)
	end

	table.sort(self.panelList, function(a, b)
		return (profile.Textures[a].Order or 100) < (profile.Textures[b].Order or 100)
	end)

	for name, panel in pairs(customPanels) do
		if not activePanels[name] then
			panel:Hide()
			panel.db = nil
		end
	end

	self.ActionBarTop = self.ActionBarTop or CreateActionBarTop()
	self.ActionBarTop.db = profile.LUITextures.ActionBarTopTexture
	self.ActionBarTop:Refresh()
end

function module:GetPanelByName(name)
	local panel = customPanels[name]
	return panel and panel.db and panel or nil
end

function module:Refresh()
	if InCombatLockdown() then
		refreshQueue:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end
	refreshQueue:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:setPanels()
	for _, sidebar in self:IterateSidebars() do
		sidebar:Refresh()
	end
	self:RefreshNavBar()
	self:RefreshOrb()
	self:RefreshMainPanels()
end
