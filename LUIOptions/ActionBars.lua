local Opt = select(2, ...)
local LUI = Opt.LUI

local function GetAddon(name)
	local other = name == "Bartender4" and "Dominos" or "Bartender4"
	if InCombatLockdown() or not C_AddOns.IsAddOnLoaded(name) or C_AddOns.IsAddOnLoaded(other) then return end
	local addon = _G[name]
	if addon and addon.db then return addon end
end

local function CopyProfile(addon)
	local db = addon.db
	local previous = db:GetCurrentProfile()
	local profiles = {}
	for _, name in ipairs(db:GetProfiles()) do profiles[name] = true end
	local name, index = "LUI", 1
	while profiles[name] do
		index = index + 1
		name = "LUI ("..index..")"
	end
	db:SetProfile(name)
	db:CopyProfile(previous)
	return name
end

local function ConfigureSidebars(prefix)
	local artwork = LUI:GetModule("Artwork", true)
	if not artwork or not artwork:IsEnabled() then return end
	for _, sidebar in artwork:IterateSidebars() do
		local settings = artwork.db.profile.SideBars[sidebar.name]
		settings.Anchor = prefix..(sidebar.side == "Left" and 3 or 4)
		settings.AutoPosition = true
	end
	artwork:Refresh()
end

local function SetupBartender()
	local addon = GetAddon("Bartender4")
	local bars = addon and addon:GetModule("ActionBars", true)
	if not bars or not bars.db then return end
	local profile = CopyProfile(addon)
	bars.db.profile.enabled = true
	for row, id in ipairs({1, 6}) do
		local bar = bars.db.profile.actionbars[id]
		bar.enabled, bar.buttons, bar.rows, bar.padding = true, 12, 1, 2
		bar.version = addon.CONFIG_VERSION
		bar.position.point, bar.position.x, bar.position.y = "BOTTOM", -197, 60 + (row - 1) * 34
		bar.position.scale = 0.85
		bar.position.growHorizontal, bar.position.growVertical = "RIGHT", "DOWN"
	end
	addon:UpdateModuleConfigs()
	ConfigureSidebars("BT4Bar")
	LUI:Print("Bartender4: LUI layout applied to profile "..profile..".")
end

local function SetupDominos()
	local addon = GetAddon("Dominos")
	if not addon or not addon.Frame or not addon.SetNumButtons then return end
	local profile = CopyProfile(addon)
	local enabled = addon.db.profile.modules.ActionBars
	addon.db.profile.modules.ActionBars = true
	addon:SetNumButtons(12)
	if not enabled then addon:Reload() end
	for row, id in ipairs({1, 6}) do
		local bar = addon.Frame:Get(id)
		bar:ClearSavedAnchor()
		bar:SetNumButtons(12)
		bar:SetColumns(12)
		bar:SetSpacing(2)
		bar:SetPadding(2, 2)
		bar:SetFrameScale(0.85)
		bar:SavePosition("BOTTOM", "BOTTOM", 0, (28 + (row - 1) * 34) / 0.85)
		bar:RestorePosition()
		bar:ShowFrame()
	end
	ConfigureSidebars("DominosFrame")
	LUI:Print("Dominos: LUI layout applied to profile "..profile..".")
end

Opt.options.args.General.args.Welcome.args.ActionBars = Opt:InlineGroup({
	name = "Action Bar Setup",
	args = {
		Info = Opt:Desc({name = "Enable Bartender4 or Dominos, then apply the LUI layout here. This creates and activates a copy of your current action-bar profile with two bottom rows and bars for the LUI sidebars. Your original profile remains available in the action-bar addon's options."}),
		Bartender = Opt:Execute({name = "Set Up Bartender4", func = SetupBartender,
			disabled = function() return not GetAddon("Bartender4") end}),
		Dominos = Opt:Execute({name = "Set Up Dominos", func = SetupDominos,
			disabled = function() return not GetAddon("Dominos") end}),
		CombatInfo = Opt:Desc({name = "Action bar setup is available outside combat. Keep only one action-bar addon enabled."}),
	},
})
