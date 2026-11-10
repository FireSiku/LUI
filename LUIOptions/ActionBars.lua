local Opt = select(2, ...)
local LUI = Opt.LUI
local confirmedProfiles = {}

local function GetAddon(name)
	local other = name == "Bartender4" and "Dominos" or "Bartender4"
	if InCombatLockdown() or not C_AddOns.IsAddOnLoaded(name) or C_AddOns.IsAddOnLoaded(other) then return end
	local addon = _G[name]
	if addon and addon.db then return addon end
end

local function GetProfile(addon)
	local db = addon.db
	local name = db:GetCurrentProfile()
	if not name or name == "" then
		name = "LUI"
		db:SetProfile(name)
	end
	return name
end

local function ConfirmSetup(name)
	local addon = GetAddon(name)
	local profile = addon and addon.db:GetCurrentProfile() or "LUI"
	confirmedProfiles[name] = profile
	return format("Apply the LUI action-bar layout to %s profile '%s'? Bar sizes, positions and sidebar assignments will be updated. Keybindings are kept.", name, profile)
end

local function ProfileMatchesConfirmation(name, addon)
	local confirmed = confirmedProfiles[name]
	confirmedProfiles[name] = nil
	if confirmed and confirmed ~= (addon.db:GetCurrentProfile() or "LUI") then
		LUI:Print("The selected profile changed. Run setup again for the new profile.")
		return false
	end
	return true
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
	if not ProfileMatchesConfirmation("Bartender4", addon) then return end
	LUI:RecordAddonSetup("Bartender4", "STARTED")
	local profile = GetProfile(addon)
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
	LUI:RecordAddonSetup("Bartender4", "COMPLETED")
	LUI:Print("Bartender4: LUI layout applied to profile "..profile..".")
end

local function SetupDominos()
	local addon = GetAddon("Dominos")
	if not addon or not addon.Frame or not addon.SetNumButtons then return end
	if not ProfileMatchesConfirmation("Dominos", addon) then return end
	LUI:RecordAddonSetup("Dominos", "STARTED")
	local profile = GetProfile(addon)
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
	LUI:RecordAddonSetup("Dominos", "COMPLETED")
	LUI:Print("Dominos: LUI layout applied to profile "..profile..".")
end

Opt.AddonSetup.args.ActionBars = Opt:InlineGroup({
	name = "Action Bar Setup",
	args = {
		Info = Opt:Desc({name = "Enable Bartender4 or Dominos, then apply the LUI layout to its currently selected profile. This sets up two bottom rows and bars for the LUI sidebars. Reapplying updates the same profile and keeps your keybindings."}),
		Bartender = Opt:Execute({name = "Set Up Bartender4", func = SetupBartender,
			confirm = function() return ConfirmSetup("Bartender4") end,
			disabled = function() return not GetAddon("Bartender4") end}),
		Dominos = Opt:Execute({name = "Set Up Dominos", func = SetupDominos,
			confirm = function() return ConfirmSetup("Dominos") end,
			disabled = function() return not GetAddon("Dominos") end}),
		CombatInfo = Opt:Desc({name = "Action bar setup is available outside combat. Keep only one action-bar addon enabled."}),
	},
})
