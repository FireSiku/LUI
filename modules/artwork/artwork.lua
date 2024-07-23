-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Artwork : LUIModule
local module = LUI:GetModule("Artwork")
local db

--Table to hold all panels frames.
local _panels = {}

-- ####################################################################################################################
-- ##### Module Functions #############################################################################################
-- ####################################################################################################################

function module:CreateNewPanel(name, paneldb)
	local panel = CreateFrame("Frame", "LUIPanel_"..name, UIParent)
	LUI:RegisterConfig(panel, paneldb)
	LUI:RestorePosition(panel)
	-- LUI:MakeDraggable(panel)
	-- panel:EnableMouse(true)
	Mixin(panel, module.PanelMixin)

	local tex = panel:CreateTexture(nil, "BACKGROUND")
	tex:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT")
	tex:SetPoint("TOPLEFT", panel, "TOPLEFT")
	
	_panels[name] = panel
	panel.name = name
	panel.tex = tex
	panel.db = paneldb

	panel:Refresh()
	return panel
end

function module:setPanels()
	db = self.db.profile
	module.panelList = {}

	for name, paneldb in pairs(db.Textures) do
		local frame = module:CreateNewPanel(name, paneldb)
		table.insert(module.panelList, name)
	end
	sort(module.panelList, function(a, b)
		return db.Textures[a].Order < db.Textures[b].Order
	end)

	module.ActionBarTop = module:CreateNewPanel("ActionBarTopTexture", db.LUITextures.ActionBarTopTexture)
end

function module:GetPanelByName(name)
	return _panels[name]
end

function module:Refresh()
	for name, panel in pairs(_panels) do
		panel:Refresh()
	end
	module.ActionBarTop:Refresh()
	for name, sidebar in module:IterateSidebars() do
		sidebar:Refresh()
	end
	module:RefreshNavBar()
	module:RefreshOrb()
	module:RefreshMainPanels()
end
