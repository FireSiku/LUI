local Opt = select(2, ...)
local LUI = Opt.LUI

local FRAME_WIDTH, FRAME_HEIGHT, SPACING = 80, 33, 4
local OFFSET_X, OFFSET_Y = -28, 40
local TEXTURE = "Interface\\AddOns\\LUI\\media\\statusbars\\Gradient.tga"
local setups = {}
local confirmedProfiles = {}

local function SetValues(target, values)
	for key, value in pairs(values) do
		target[key] = type(value) == "table" and CopyTable(value) or value
	end
end

-- Grid2's active theme can have its own frame and layout settings. Apply the
-- same geometry to each theme, retaining its indicators, statuses and colors.
local function SetGridThemes(module, values)
	local base = module.dba and module.dba.profile or module.db.profile
	SetValues(base, values)
	for _, theme in pairs(base.extraThemes or {}) do
		SetValues(theme, values)
	end
	if module.db.profile ~= base then SetValues(module.db.profile, values) end
end

setups.Grid2 = {
	label = "Grid2",
	anchor = "Grid2LayoutFrame",
	get = function()
		local addon, frame, layout = _G.Grid2, _G.Grid2Frame, _G.Grid2Layout
		if not addon or not addon.db or not addon.db.GetCurrentProfile
			or not frame or not frame.db or not frame.db.profile
			or not layout or not layout.db or not layout.db.profile then return end
		return {name = addon.db:GetCurrentProfile(), frame = frame, layout = layout}
	end,
	apply = function(context)
		local scale = UIParent:GetEffectiveScale()
		SetGridThemes(context.frame, {
			frameWidth = FRAME_WIDTH, frameHeight = FRAME_HEIGHT,
			frameWidths = {}, frameHeights = {}, frameHeaderWidths = {}, frameHeaderHeights = {},
			orientation = "HORIZONTAL", barTexture = "LUI_Gradient",
		})
		SetGridThemes(context.layout, {
			layouts = {solo = "By Group", party = "By Group", arena = "By Group", raid = "By Group"},
			horizontal = false, anchor = "BOTTOMRIGHT", groupAnchor = "BOTTOMRIGHT",
			PosX = OFFSET_X * scale, PosY = OFFSET_Y * scale,
			Padding = SPACING, Spacing = 2, ScaleSize = 1, FrameLock = true,
			Positions = {}, anchors = {}, groupAnchors = {}, groupHorizontals = {}, unitsPerColumns = {},
		})
	end,
}

setups.VuhDo = {
	label = "VuhDo",
	anchor = "Vd1",
	get = function()
		local panel = _G.VUHDO_PANEL_SETUP and VUHDO_PANEL_SETUP[1]
		if not _G.VUHDO_CONFIG or not panel or not panel.MODEL or not panel.SCALING
			or not panel.POSITION or not panel.PANEL_COLOR
			or not _G.VUHDO_saveProfile or not _G.VUHDO_getProfileNamedCompressed then return end
		local _, profile = VUHDO_getProfileNamedCompressed(VUHDO_CONFIG.CURRENT_PROFILE)
		if profile and profile.HARDLOCKED then return end
		return {name = VUHDO_CONFIG.CURRENT_PROFILE, panel = panel}
	end,
	apply = function(context)
		-- Saving a VuhDo profile also refreshes its profile selector. Load the
		-- companion through the addon's normal options boundary before saving.
		local loaded = C_AddOns.LoadAddOn("VuhDoOptions")
		if not loaded then return false, "Open VuhDo's options once, then try again." end
		local name = context.name
		if not name or name == "" then
			name = "LUI"
			if VUHDO_getProfileNamedCompressed(name) then
				return false, "Select the VuhDo profile to update, then try again."
			end
		end
		local panel = context.panel
		SetValues(panel.MODEL, {groups = {1, 2, 3, 4, 5, 6, 7, 8}, ordering = 0, isReverse = false})
		SetValues(panel.SCALING, {
			barWidth = FRAME_WIDTH, barHeight = FRAME_HEIGHT,
			columnSpacing = SPACING, rowSpacing = SPACING,
			borderGapX = 2, borderGapY = 2, scale = 1,
			maxColumnsWhenStructured = 8, ommitEmptyWhenStructured = true,
			arrangeHorizontal = false, alignBottom = true,
		})
		SetValues(panel.POSITION, {
			x = OFFSET_X, y = OFFSET_Y, relativePoint = "BOTTOMRIGHT",
			orientation = "BOTTOMRIGHT", growth = "BOTTOMRIGHT", scale = 1,
		})
		panel.PANEL_COLOR.barTexture = "LUI_Gradient"
		VUHDO_CONFIG.CURRENT_PROFILE = name
		-- The setup confirmation already names the profile being updated.
		-- Mark the saved revision as local so VuhDo does not offer to fork an
		-- imported profile instead of updating it. Hardlocked profiles are skipped.
		local _, profile = VUHDO_getProfileNamedCompressed(name)
		if profile then profile.ORIGINATOR_TOON = VUHDO_PLAYER_FULL_NAME or VUHDO_PLAYER_NAME end
		VUHDO_saveProfile(name)
		context.name = name
	end,
}

setups.HealBot = {
	label = "HealBot",
	anchor = "f1_HealBot_Action",
	get = function()
		local skins = _G.Healbot_Config_Skins
		local name = skins and skins.Current_Skin
		local groups = name and skins.HealGroups and skins.HealGroups[name]
		if not groups or not groups[4] or not groups[5]
			or not _G.hbv_Skins_SetFrameVarSkin or not _G.hbv_Skins_SetVarSkin then return end
		return {name = name, groups = groups}
	end,
	apply = function(context)
		local function SetFrame(category, values)
			for key, value in pairs(values) do
				hbv_Skins_SetFrameVarSkin(value, context.name, category, key, 1)
			end
		end
		-- HealBot calls its complete raid roster "Emergency" (group 5). Keep
		-- specialized tank, focus and pet panels and all spell settings intact.
		context.groups[4].STATE, context.groups[4].FRAME = true, 1
		context.groups[5].STATE, context.groups[5].FRAME = true, 1
		SetFrame("HealBar", {
			WIDTH = FRAME_WIDTH, HEIGHT = FRAME_HEIGHT, TEXTURE = "LUI_Gradient",
			CMARGIN = SPACING, RMARGIN = SPACING, GRPCOLS = true, NUMCOLS = 1,
		})
		SetFrame("BarSort", {RAIDORDER = 3})
		SetFrame("Frame", {SCALE = 1, LOCKED = 1})
		SetFrame("Anchors", {
			FRAME = 4, BARS = 4, GROW = 2, RealFixed = false,
			X = 100 + OFFSET_X / GetScreenWidth() * 100,
			Y = OFFSET_Y / GetScreenHeight() * 100,
		})
	end,
}

local function SetDandersLayout(target, isOverride)
	-- Danders stores offsets from UIParent's center, even when the container
	-- itself uses a corner anchor.
	local x = UIParent:GetWidth() / 2 + OFFSET_X
	local y = -UIParent:GetHeight() / 2 + OFFSET_Y
	SetValues(target, {
		frameWidth = FRAME_WIDTH, frameHeight = FRAME_HEIGHT, frameSpacing = SPACING, frameScale = 1,
		healthTexture = TEXTURE, growDirection = "VERTICAL", raidUseGroups = true,
		raidGroupsPerRow = 8, raidPlayersPerRow = 5, raidGroupSpacing = SPACING,
		raidGroupVisible = {true, true, true, true, true, true, true, true},
		raidGroupDisplayOrder = {1, 2, 3, 4, 5, 6, 7, 8},
		raidGroupAnchor = "END", raidPlayerAnchor = "END",
		position = {point = "BOTTOMRIGHT", x = x, y = y},
		raidAnchorX = x, raidAnchorY = y,
	})
	if not isOverride then target.raidLocked = true end
end

setups.DandersFrames = {
	label = "Danders Frames",
	anchor = "DandersRaidFramesContainer",
	get = function()
		local addon = _G.DandersFrames
		if not addon or not addon.db or not addon.db.raid or not addon.DeepCopy
			or not addon.GetCurrentProfile or not addon.SaveCurrentProfile then return end
		if addon.AutoProfilesUI and addon.AutoProfilesUI.IsEditing and addon.AutoProfilesUI:IsEditing() then return end
		local name = addon:GetCurrentProfile()
		if not _G.DandersFramesDB_v2 or not DandersFramesDB_v2.profiles
			or not DandersFramesDB_v2.profiles[name] then return end
		return {name = name, addon = addon,
			anchor = addon.raidContainer and addon.raidContainer:GetName()}
	end,
	apply = function(context)
		local addon = context.addon
		-- DeepCopy is Danders' own way to unwrap its runtime profile proxy.
		local profile = addon:DeepCopy(addon.db)
		SetDandersLayout(profile.raid)
		-- Automatic layouts keep their conditions and aura settings. Their
		-- geometry must agree with the base layout after the next group change.
		for _, content in pairs(profile.raidAutoProfiles or {}) do
			if type(content) == "table" then
				if content.profile and content.profile.overrides then
					SetDandersLayout(content.profile.overrides, true)
				end
				for _, layout in pairs(content.profiles or {}) do
					if layout.overrides then SetDandersLayout(layout.overrides, true) end
				end
			end
		end
		addon.db.raid = profile.raid
		addon.db.raidAutoProfiles = profile.raidAutoProfiles
		addon:SaveCurrentProfile()
	end,
}

local function GetContext(id)
	if InCombatLockdown() or not C_AddOns.IsAddOnLoaded(id) then return end
	for other in pairs(setups) do
		if other ~= id and C_AddOns.IsAddOnLoaded(other) then return end
	end
	if C_AddOns.IsAddOnLoaded("Plexus") then return end
	return setups[id].get()
end

local function SetupRaidFrames(id)
	local context = GetContext(id)
	if not context then return end
	local setup = setups[id]
	if confirmedProfiles[id] and confirmedProfiles[id] ~= context.name then
		confirmedProfiles[id] = nil
		LUI:Print("The selected profile changed. Run setup again for the new profile.")
		return
	end
	confirmedProfiles[id] = nil
	local applied, message = setup.apply(context)
	if applied == false then
		LUI:Print(message)
		return
	end
	local artwork = LUI:GetModule("Artwork", true)
	if artwork and artwork.db then
		local panel = artwork.db.profile.LUITextures.Raid
		panel.Anchor = context.anchor or setup.anchor
		panel.Additional = ""
		panel.FitAnchor = true
		panel.Animation = false
		panel.OffsetX, panel.OffsetY = 0, 0
	end
	LUI:Print(setup.label..": LUI layout applied to profile '"..context.name.."'.")
	ReloadUI()
end

local args = {
	Info = Opt:Desc({name = "Apply the LUI raid layout to the raid-frame addon's selected profile. This updates the main raid panel with compact frames, all eight raid groups and a position near the bottom-right corner. Reapplying updates the same profile. Spells, click bindings and aura indicators are kept."}),
}

for _, id in ipairs({"Grid2", "VuhDo", "HealBot", "DandersFrames"}) do
	local addonID = id
	local setup = setups[id]
	args[id] = Opt:Execute({
		name = "Set Up "..setup.label,
		func = function() SetupRaidFrames(addonID) end,
		disabled = function() return not GetContext(addonID) end,
		confirm = function()
			local context = GetContext(addonID)
			confirmedProfiles[addonID] = context and context.name
			return context and format("Apply the LUI layout to %s profile '%s' and reload the UI? Frame sizes, positions and group layouts will be updated, including automatic raid layouts. Spells, click bindings and aura indicators are kept.", setup.label, context.name or "LUI") or false
		end,
	})
end

args.Requirements = Opt:Desc({name = "Enable one supported raid-frame addon and finish its initial setup first. Apply the layout outside combat. Unlock hardlocked VuhDo profiles and finish editing automatic Danders layouts first. Further adjustments and automatic profile assignments stay in that addon's options."})
Opt.AddonSetup.args.RaidFrames = Opt:InlineGroup({name = "Raid Frame Setup", args = args})
