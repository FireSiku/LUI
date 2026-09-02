-- Built-in artwork panel lifecycle.

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Artwork : LUIModule
local module = LUI:GetModule("Artwork")

local refreshQueue = CreateFrame("Frame")
refreshQueue:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	if module:IsEnabled() then module:Refresh() end
end)

local function CreateActionBarTop()
	local panel = CreateFrame("Frame", "LUIPanel_ActionBarTopTexture", UIParent)
	local panelDB = module.db.profile.LUITextures.ActionBarTopTexture
	LUI:RegisterConfig(panel, panelDB)
	LUI:RestorePosition(panel)
	Mixin(panel, module.PanelMixin)

	local texture = panel:CreateTexture(nil, "BACKGROUND")
	texture:SetAllPoints(panel)
	panel.name = "ActionBarTopTexture"
	panel.tex = texture
	panel.db = panelDB
	return panel
end

function module:setPanels()
	module.ActionBarTop = module.ActionBarTop or CreateActionBarTop()
	module.ActionBarTop.db = module.db.profile.LUITextures.ActionBarTopTexture
	module.ActionBarTop:Refresh()
end

function module:Refresh()
	if InCombatLockdown() then
		refreshQueue:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end
	refreshQueue:UnregisterEvent("PLAYER_REGEN_ENABLED")
	if module.ActionBarTop then module.ActionBarTop:Refresh() end
	for _, sidebar in module:IterateSidebars() do
		sidebar:Refresh()
	end
	module:RefreshNavBar()
	module:RefreshOrb()
	module:RefreshMainPanels()
end
