local Opt = select(2, ...)
local LUI = Opt.LUI
local Profiles = Opt.SetupProfiles
local confirmedProfiles = {}

local function GetAddon(name)
	local other = name == "Bartender4" and "Dominos" or "Bartender4"
	if InCombatLockdown() or not C_AddOns.IsAddOnLoaded(name) or C_AddOns.IsAddOnLoaded(other) then return end
	local addon = _G[name]
	if addon and Profiles:Ace(addon.db) then return addon end
end

local function ConfirmSetup(name)
	local addon = GetAddon(name)
	local plan = addon and Profiles:Plan(name, Profiles:Ace(addon.db))
	confirmedProfiles[name] = plan
	return plan and Profiles:Confirmation(name, plan,
		"Bar sizes, positions and sidebar assignments will be updated in the LUI copy. Keybindings are kept.") or false
end

local function RunSetup(name, addon, apply)
	local confirmed = confirmedProfiles[name]
	confirmedProfiles[name] = nil
	LUI:RecordAddonSetup(name, "STARTED")
	local profile, message = Profiles:Run(name, Profiles:Ace(addon.db), confirmed, apply)
	LUI:RecordAddonSetup(name, profile and "COMPLETED" or "CANCELLED")
	LUI:Print(profile and (name .. ": LUI layout applied to setup profile '" .. profile .. "'.") or message)
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
	if not addon then return end
	RunSetup("Bartender4", addon, function()
		local bars = addon:GetModule("ActionBars", true)
		if not bars or not bars.db then return false, "Bartender4 action bars are unavailable." end
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
	end)
end

local function SetupDominos()
	local addon = GetAddon("Dominos")
	if not addon or not addon.Frame or not addon.SetNumButtons then return end
	RunSetup("Dominos", addon, function()
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
	end)
end

Opt.AddonSetup.args.ActionBars = Opt:InlineGroup({
	name = "Action Bar Setup",
	args = {
		Info = Opt:Desc({name = "Copy your selected Bartender4 or Dominos profile into a separate LUI setup profile, then apply two bottom rows and sidebar positioning there. Your original profile is kept. Reapplying updates the same LUI copy and keeps your keybindings."}),
		Bartender = Opt:Execute({name = "Set Up Bartender4", func = SetupBartender,
			confirm = function() return ConfirmSetup("Bartender4") end,
			disabled = function() return not GetAddon("Bartender4") end}),
		Dominos = Opt:Execute({name = "Set Up Dominos", func = SetupDominos,
			confirm = function() return ConfirmSetup("Dominos") end,
			disabled = function() return not GetAddon("Dominos") end}),
		CombatInfo = Opt:Desc({name = "Action bar setup is available outside combat. Keep only one action-bar addon enabled."}),
	},
})
