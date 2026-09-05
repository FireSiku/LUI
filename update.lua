---@class LUIAddon
local LUI = select(2, ...)
local L = LUI.L
local db, default

-- Increase whenever there are changes that would require remediation
-- Append every database migration in a new version block in ApplyUpdate.
local DB_VERSION = 10

function LUI:GetDBVersion()
	return DB_VERSION
end

local requireReload = false

StaticPopupDialogs["LUI_DB_UPDATE"] = {
	preferredIndex = 3,
	text = "This version of LUI contains settings that needs to be restored or updated. Do you want LUI to convert the affected settings?\n\nNote: Do not downgrade the version of LUI after conversion has been done.",
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function() LUI:ApplyUpdate(db.dbVersion) end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 0,
}

function LUI:CheckUpdate()
	db = LUI.db.profile
	default = LUI.defaults.profile

	if DB_VERSION > db.dbVersion then
		StaticPopup_Show("LUI_DB_UPDATE")
	end
end

function LUI:_Resync()
	LUI:ApplyUpdate(0)
end

-- Table structure:  cleanUp[tableRef] = { Array of table keys to clean up }
-- This metatable will automatically create an empty array if cleanUp[tableRef] doesn't exist yet.
local cleanUp = setmetatable({}, {__index = function(t, k) t[k] = {}; return t[k] end, __mode = "k"})

local function ExecuteCleanUp()
	for target, keys in pairs(cleanUp) do
		for _, key in ipairs(keys) do
			target[key] = nil
		end
	end
end

local function MergeRecursive(destination, source, exclude)
	if type(destination) ~= "table" or type(source) ~= "table" then return end
	for k, v in pairs(source) do
		if type(v) == "table" then
			-- You want to keep traversing the exclusion list at the same time
			MergeRecursive(destination[k], v, exclude and exclude[k] or nil)
		else
			-- If the source value matches the excluded value, do not set it
			if not exclude or exclude[k] ~= v then
				destination[k] = v
			end
		end
	end
end

--- Helper function to reduce the overall number of IF statements
---@param display_name string @ Name that displayed to user in the format display_name.new_name
---@param old_db table @ Table that contains the old setting.
---@param old_name string|number @ The old name of the setting to look up in the db
---@param new_name string|number @ The new name of the setting that should be updated
---@param new_db table? @ If the new setting is in different table. If missing, it will use old_db as the destination
local function Convert(display_name, old_db, old_name, new_name, new_db)
	if not old_db then return end -- Nothing to convert.

	assert(type(old_db) == "table", "Setting conversion failed for "..old_name..". Expected table, received "..type(old_db))
	if not new_db then new_db = old_db end
	if old_db[old_name] ~= nil then
		if type(old_db[old_name]) == "table" then
			MergeRecursive(new_db[new_name], old_db[old_name],  old_db.FakeTable or nil)
			LUI:Printf("The settings for %s.%s have been restored", display_name, new_name)	-- Announce the changes
		else
			new_db[new_name] = old_db[old_name]
			LUI:Printf("%s.%s has been restored to %s", display_name, new_name, tostring(old_db[old_name]))	-- Announce the changes
		end

		-- Mark entry for cleanup
		table.insert(cleanUp[old_db], old_name)
	end
end

local function AreColorsEqual(color1, color2)
	local r1, r2, g1, g2, b1, b2
	if color1.r then
		r1, g1, b1 = color1.r, color1.g, color1.b
	else
		r1, g1, b1 = color1[1], color1[2], color1[3]
	end
	if color2.r then
		r2, g2, b2 = color2.r, color2.g, color2.b
	else
		r2, g2, b2 = color2[1], color2[2], color2[3]
	end

	return r1 == r2 and g1 == g2 and b1 == b2
end

function LUI:ApplyUpdate(ver)
	requireReload = false
	wipe(cleanUp)
	local lui_db = LUI.db.profile

	local old_units = {
		Player = "player",
		Pet = "pet",
		Focus = "focus",
		Target = "target",
		ToT = "targettarget",
		ToToT = "targettargettarget",
		Party = "party",
		Raid = "raid",
		Boss = "boss",
		Arena = "arena",
		Maintank = "maintank",
		ArenaPet = "arenapet",
		PartyPet = "partypet",
		PetTarget = "pettarget",
		BossTarget = "bosstarget",
		FocusTarget = "focustarget",
		PartyTarget = "partytarget",
		ArenaTarget = "arenatarget",
		MaintankTarget = "maintanktarget",
		MaintankToT = "maintanktargettarget",
	}

	if ver < 1 then
		-- Tooltip and Minimap used to be part of LUI.db, so they need to be converted
		local tt_mod = LUI:GetModule("Tooltip")
		local tt_db = tt_mod.db.profile
		if lui_db.Tooltip then
			Convert("Tooltip", lui_db.Tooltip, "Hidecombat", "HideCombat", tt_db)
			Convert("Tooltip", lui_db.Tooltip, "Hidebuttons", "HideCombatSkills", tt_db)
			Convert("Tooltip", lui_db.Tooltip, "Hideuf", "HideUF", tt_db)
			Convert("Tooltip", lui_db.Tooltip, "Cursor", "Cursor", tt_db)
			Convert("Tooltip", lui_db.Tooltip, "Point", "Point", tt_db)
			Convert("Tooltip", lui_db.Tooltip, "Scale", "Scale", tt_db)
			Convert("Tooltip", lui_db.Tooltip, "X", "X", tt_db)
			Convert("Tooltip", lui_db.Tooltip, "Y", "Y", tt_db)
			Convert("Tooltip.Textures", lui_db.Tooltip.Health, "Texture", "HealthBar", tt_db)
			Convert("Tooltip.Textures", lui_db.Tooltip.Background, "Texture", "BgTexture", tt_db)
			Convert("Tooltip.Colors", lui_db.Tooltip.Border, "Color", "Border", tt_db.Colors)

			if tt_mod.Refresh then tt_mod:Refresh() end
		end

		local mm_mod = LUI:GetModule("Minimap")
		local mm_db = mm_mod.db.profile
		if lui_db.Minimap then
			Convert("Minimap", lui_db.Minimap.General, "AlwaysShowText", "AlwaysShowText", mm_db.General)
			Convert("Minimap.Position", lui_db.Minimap.General, "Size", "Scale", mm_db.Position)
			Convert("Minimap", lui_db.Minimap.General, "ShowTextures", "ShowTextures", mm_db.General)
			Convert("Minimap", lui_db.Minimap.General, "MissionReport", "MissionReport", mm_db.General)

			if lui_db.Minimap.General then
				Convert("Minimap.Position", lui_db.Minimap.General.Position, "X", "X", mm_db.Position)
				Convert("Minimap.Position", lui_db.Minimap.General.Position, "Y", "Y", mm_db.Position)
				Convert("Minimap.Position", lui_db.Minimap.General.Position, "Point", "Point", mm_db.Position)
				-- Minimap movement is now controlled directly by its position options.
				if lui_db.Minimap.General.Position and lui_db.Minimap.General.Position.UnLocked ~= nil then
					tinsert(cleanUp[lui_db.Minimap.General.Position], "UnLocked")
				end
			end

			Convert("Minimap.Font", lui_db.Minimap.Font, "Font", "Name", mm_db.Fonts.Text)
			Convert("Minimap.Font", lui_db.Minimap.Font, "FontSize", "Size", mm_db.Fonts.Text)
			Convert("Minimap.Font", lui_db.Minimap.Font, "FontFlag", "Flag", mm_db.Fonts.Text)
			Convert("Minimap.Icons", lui_db.Minimap, "Icon", "Icons", mm_db)
			
			if mm_mod.Refresh then mm_mod:Refresh() end

			-- Preserve the legacy top-center widget position in the current
			-- UI Elements namespace.
			if lui_db.Minimap.Frames then
				local ui_mod = LUI:GetModule("UI Elements")
				local ui_db = ui_mod.db.profile

				Convert("UIElements.ZoneObjectives", lui_db.Minimap.Frames, "AlwaysUpFrameX", "X", ui_db.ZoneObjectives)
				Convert("UIElements.ZoneObjectives", lui_db.Minimap.Frames, "AlwaysUpFrameY", "Y", ui_db.ZoneObjectives)
				Convert("UIElements.ZoneObjectives", lui_db.Minimap.Frames, "SetAlwaysUpFrame", "ManagePosition", ui_db.ZoneObjectives)
				
				if ui_mod.Refresh then ui_mod:Refresh() end
			end
		end

		local colorMod = LUI:GetModule("Colors")
		local theme_db = LUI.db:GetNamespace("Themes").profile
		if theme_db and theme_db.minimap then
			if AreColorsEqual(theme_db.minimap, colorMod:Color(LUI.playerClass)) then
				mm_db.Colors.Minimap.t = "Class"
			else
				mm_db.Colors.Minimap.r = theme_db.minimap[1]
				mm_db.Colors.Minimap.g = theme_db.minimap[2]
				mm_db.Colors.Minimap.b = theme_db.minimap[3]
				mm_db.Colors.Minimap.t = "Individual"
			end
			LUI:Printf("Minimap.Color has been restored (used to be Themes.Colors.Frames.Minimap)")
			tinsert(cleanUp[theme_db], "minimap")

			if mm_mod.Refresh then mm_mod:Refresh() end
		end
		
		local micro_mod = LUI:GetModule("Micromenu")
		local micro_db = micro_mod.db.profile
		if theme_db and theme_db.micromenu then
			if AreColorsEqual(theme_db.micromenu, colorMod:Color(LUI.playerClass)) then
				micro_db.Colors.Micromenu.t = "Class"
			else
				micro_db.Colors.Micromenu.r = theme_db.micromenu[1]
				micro_db.Colors.Micromenu.g = theme_db.micromenu[2]
				micro_db.Colors.Micromenu.b = theme_db.micromenu[3]
				micro_db.Colors.Micromenu.t = "Individual"
			end
			LUI:Printf("Micromenu.Colors.Buttons has been restored (used to be Themes.Colors.MicroMenu.micromenu)")

			if theme_db.micromenu_bg then
				if AreColorsEqual(theme_db.micromenu_bg, colorMod:Color(LUI.playerClass)) then
					micro_db.Colors.Background.t = "Class"
				else
					micro_db.Colors.Background.r = theme_db.micromenu_bg[1]
					micro_db.Colors.Background.g = theme_db.micromenu_bg[2]
					micro_db.Colors.Background.b = theme_db.micromenu_bg[3]
					micro_db.Colors.Background.t = "Individual"
				end
				LUI:Printf("Micromenu.Colors.Background has been restored (used to be Themes.Colors.MicroMenu.micromenu_bg)")
			end

			tinsert(cleanUp[theme_db], "micromenu")
			tinsert(cleanUp[theme_db], "micromenu_bg")
			tinsert(cleanUp[theme_db], "micromenu_bg2")
			tinsert(cleanUp[theme_db], "micromenu_btn")
			tinsert(cleanUp[theme_db], "micromenu_btn_hover")

			if type(micro_mod.Refresh) == "function" then micro_mod:Refresh() end
		end
		
		-- Unitframes conversions
		local uf_db = LUI:GetModule("Unitframes").db.profile
		
		for oldUnit, unitId in pairs(old_units) do
			--- Convert the tables to use unitId keys, changes Player -> player,  ToT > targettargettarget and so on.
			Convert("Unitframes", uf_db, oldUnit, unitId)
			local unit_db = uf_db[unitId]
			local currUnit = format("UnitFrames.%s", unitId)

			Convert(currUnit, unit_db.Bars,  "Health", "HealthBar", unit_db)
			Convert(currUnit, unit_db.Bars,  "Power",  "PowerBar", unit_db)
			Convert(currUnit, unit_db.Bars,  "TotalAbsorb", "TotalAbsorbBar", unit_db)
			Convert(currUnit, unit_db.Bars,  "HealthPrediction", "HealthPredictionBar", unit_db)
			Convert(currUnit, unit_db.Bars,  "AlternativePower", "AlternativePowerBar", unit_db)
			Convert(currUnit, unit_db.Bars,  "AdditionalPower", "AdditionalPowerBar", unit_db)
			Convert(currUnit, unit_db.Bars,  "ClassPower", "ClassPowerBar", unit_db)
			Convert(currUnit, unit_db.Bars,  "ComboPoints", "ComboPointsBar", unit_db)
			Convert(currUnit, unit_db.Bars,  "Totems", "TotemsBar", unit_db)
			Convert(currUnit, unit_db.Bars,  "Runes", "RunesBar", unit_db)
			Convert(currUnit, unit_db.Texts, "Combat", "CombatFeedback", unit_db)
			Convert(currUnit, unit_db.Texts, "Name", "NameText", unit_db)
			Convert(currUnit, unit_db.Texts, "Health", "HealthText", unit_db)
			Convert(currUnit, unit_db.Texts, "Power", "PowerText", unit_db)
			Convert(currUnit, unit_db.Texts, "PvP", "PvPText", unit_db)
			Convert(currUnit, unit_db.Texts, "HealthPercent", "HealthPercentText", unit_db)
			Convert(currUnit, unit_db.Texts, "HealthMissing", "HealthMissingText", unit_db)
			Convert(currUnit, unit_db.Texts, "PowerPercent", "PowerPercentText", unit_db)
			Convert(currUnit, unit_db.Texts, "PowerMissing", "PowerMissingText", unit_db)
			Convert(currUnit, unit_db.Texts, "AlternativePower", "AlternativePowerText", unit_db)
			Convert(currUnit, unit_db.Texts, "AdditionalPower", "AdditionalPowerText", unit_db)
			Convert(currUnit, unit_db.Icons, "Leader", "LeaderIndicator", unit_db)
			Convert(currUnit, unit_db.Icons, "Role", "GroupRoleIndicator", unit_db)
			Convert(currUnit, unit_db.Icons, "Raid", "RaidMarkerIndicator", unit_db)
			Convert(currUnit, unit_db.Icons, "Resting", "RestingIndicator", unit_db)
			Convert(currUnit, unit_db.Icons, "Combat", "CombatIndicator", unit_db)
			Convert(currUnit, unit_db.Icons, "PvP", "PvIndicator", unit_db)
			if unit_db.Castbar then
				Convert(currUnit..".Castbar", unit_db.Castbar.Text, "Name", "NameText", unit_db.Castbar)
				Convert(currUnit..".Castbar", unit_db.Castbar.Text, "Time", "TimeText", unit_db.Castbar)
			end

			if unitId == "player" then
				Convert(currUnit, unit_db.Bars,  "HealPrediction", "HealthPredictionBar", unit_db)
				Convert(currUnit, unit_db.Bars,  "DruidMana",      "AdditionalPowerBar", unit_db)
				Convert(currUnit, unit_db.Texts, "DruidMana",      "AdditionalPowerText", unit_db)
				Convert(currUnit, unit_db.Bars,  "AltPower",       "AlternativePowerBar", unit_db)
				Convert(currUnit, unit_db.Texts, "AltPower",       "AlternativePowerText", unit_db)
				Convert(currUnit, unit_db.Bars,  "HolyPower",      "ClassPowerBar", unit_db)
				Convert(currUnit, unit_db.Bars,  "Chi",            "ClassPowerBar", unit_db)
				Convert(currUnit, unit_db.Bars,  "WarlockBar",     "ClassPowerBar", unit_db)
				Convert(currUnit, unit_db.Bars,  "ArcaneCharges",  "ClassPowerBar", unit_db)

				if uf_db.Player and uf_db.Player.Bars then
					table.insert(cleanUp[uf_db.Player.Bars], "ShadowOrbs")
					table.insert(cleanUp[uf_db.Player.Bars], "Eclipse")
				end
				if uf_db.Player and uf_db.Player.Texts then
					table.insert(cleanUp[uf_db.Player.Texts], "Eclipse")
					table.insert(cleanUp[uf_db.Player.Texts], "WarlockBar")
				end
				if uf_db.Colors then
					table.insert(cleanUp[uf_db.Colors], "ShadowOrbsBar")
					table.insert(cleanUp[uf_db.Colors], "Eclipse")
				end
			end
		end

		-- Push a refresh of all units
		for k, obj in pairs(LUI.oUF.objects) do
			obj:UpdateAllElements('SettingsConversion')
		end
	end
	
	if ver < 2 then
		--- Chunks of conversion code that were found that shouldn't be polluting the rest of the code
		if _G.LUICONFIG and _G.LUICONFIG.IsConfigured then
			LUI.db.global.luiconfig[LUI.profileName] = CopyTable(_G.LUICONFIG)
			if LUI.db.global.luiconfig[LUI.profileName].IsConfigured then
				wipe(_G.LUICONFIG)
			end
		end

		-- The PvPText was not converted in version one:
		local uf_mod = LUI:GetModule("Unitframes")
		local uf_db = uf_mod.db.profile
		if uf_db.player.Texts then
			Convert("UnitFrames.Player", uf_db.player.Texts, "PvP",            "PvPText", uf_db.player)
			Convert("UnitFrames.Player", uf_db.player.Texts, "DruidMana",      "AdditionalPowerText", uf_db.player)
			Convert("UnitFrames.Player", uf_db.player.Texts, "AltPower",       "AlternativePowerText", uf_db.player)
		end
		if uf_db.player.Bars then
			Convert("UnitFrames.Player", uf_db.player.Bars,  "HealPrediction", "HealthPredictionBar", uf_db.player)
			Convert("UnitFrames.Player", uf_db.player.Bars,  "DruidMana",      "AdditionalPowerBar", uf_db.player)
			Convert("UnitFrames.Player", uf_db.player.Bars,  "AltPower",       "AlternativePowerBar", uf_db.player)
			Convert("UnitFrames.Player", uf_db.player.Bars,  "HolyPower",      "ClassPowerBar", uf_db.player)
			Convert("UnitFrames.Player", uf_db.player.Bars,  "Chi",            "ClassPowerBar", uf_db.player)
			Convert("UnitFrames.Player", uf_db.player.Bars,  "WarlockBar",     "ClassPowerBar", uf_db.player)
			Convert("UnitFrames.Player", uf_db.player.Bars,  "ArcaneCharges",  "ClassPowerBar", uf_db.player)
		end

		-- For people that were affected by UF settings overwritten by default values, go over it again:
		-- This will recursively remove all settings that matches the non-specific defaults 
		local function RecursiveRemove(source, exclude)
			if type(source) ~= "table" then return end
			for k, v in pairs(source) do
				if type(v) == "table" then
					-- You want to keep traversing the exclusion list at the same time
					RecursiveRemove(v, exclude and exclude[k] or nil)
				else
					-- If the source value matches the excluded value, remove it
					if exclude and exclude[k] == v then
						source[k] = nil
					end
				end
			end
		end

		local old_inverted = tInvert(old_units)
		for i, unitId in ipairs(uf_mod.units) do
			RecursiveRemove(uf_db[unitId], uf_db.FakeTable)
			-- Attempt to convert again
			Convert("Unitframes", uf_db, old_inverted[unitId], unitId)
		end

		requireReload = true
		
	end
	
	if ver < 3 then
		-- Some very old profiles had string-based number values. Now that Blizzard is more strict about this, we have to sanitize it.
		local saneCount = 0

		-- go through a list of keys in a table and if any of them are strings, cast them to number
		local function Sanitize(t, list)
			if not t then return end
			for i = 1, #list do
				local key = list[i]
				if t[key] and type(t[key]) == "string" then
					t[key] = tonumber(t[key])
					saneCount = saneCount + 1
				end
			end
		end
		local colorList = {"r", "g", "b", "a"}
		local insetList = {"left", "right", "top", "bottom"}

		for modName, module in LUI:IterateModules() do
			local db = module.db and module.db.profile or nil
			-- Avoiding those two modules as they use dynamic tables
			if db and db.Colors and modName ~= "Infotext" and modName ~= "Unitframes" then
				for k, color in pairs(db.Colors) do
					if type(color) == "table" then 
						Sanitize(color, colorList)
					end
				end
			end
			if db and db.Fonts and modName ~= "Infotext" and modName ~= "Unitframes" then
				for k, font in pairs(db.Fonts) do
					Sanitize(font, {"Size"})
				end
			end
			if db and modName == "Chat" then
				Sanitize(db, {"x", "y", "width", "height"})
				Sanitize(db.General.Font, {"Size"})
			elseif db and modName == "Merchant" then
				Sanitize(db.AutoRepair.Settings, {"CostLimit"})
				Sanitize(db.AutoStock.Settings, {"CostLimit"})
			elseif db and modName == "Micromenu" then
				Sanitize(db, {"X", "Y"})
			elseif db and modName == "Minimap" then
				Sanitize(db.General, {"Scale", "CoordPrecision", "FontSize"})
				Sanitize(db.Position, {"X", "Y", "Scale"})
			elseif db and modName == "Mirror Bar" then
				Sanitize(db.General, {"Width", "Height", "X", "Y", "BarGap"})
				Sanitize(db.Text, {"Size", "OffsetX", "OffsetY"})
				Sanitize(db.Text.Color, colorList)
				Sanitize(db.Border.Color, colorList)
				Sanitize(db.Border.Inset, insetList)
			elseif db and modName == "RaidMenu" then
				Sanitize(db,  {"Spacing", "Offset", "X_Offset", "Opacity", "Scale"})
			elseif db and modName == "Tooltip" then
				Sanitize(db, {"Scale", "X", "Y"})
			elseif db and modName == "UI Elements" then
				for k, v in pairs(db) do
					Sanitize(db[k], {"X", "Y"})
				end
			elseif db and modName == "Unitframes" then
				local uf_mod = LUI:GetModule("Unitframes")
				local uf_db = uf_mod.db.profile
				for i, unitId in ipairs(uf_mod.units) do
					-- Brute force method, due to the sheer size of settings in unitframes
					local valueList = {"Height", "Width", "X", "Y", "BGMultiplier", "BGAlpha", "Size", "Spacing", "Num", "OffsetX", "OffsetY", "Thickness", "Alpha", "Left", "Right", "Top", "Bottom", "r", "g", "b", "a"}
					Sanitize(db[unitId], valueList)
					-- Look for subtables
					for k1, v1 in pairs(db[unitId]) do
						if type(v1) == "table" then
							Sanitize(v1, valueList)
							for k2, v2 in pairs(v1) do
								if type(v2) == "table" then
									Sanitize(v2, valueList)
									for k3, v3 in pairs(v2) do
										if type(v3) == "table" then
											Sanitize(v3, valueList)
										end
									end
								end
							end
						end
					end
				end
			end
		end
		LUI:Printf("Looking for numbers that were previously saved as text...")
		if saneCount > 0 then
			LUI:Printf("%s instances of this issue were found and resolved.", saneCount)
		else
			LUI:Printf("This profile was not affected by this issue.")
		end
		requireReload = true
	end

	-- Migrate settings from the retired Panels and ArtworkV3 namespaces.
	if ver < 4 then
		local profileName = LUI.db:GetCurrentProfile()
		local PanelsSV = (LUI.db and LUI.db.sv.namespaces.Panels) and LUI.db.sv.namespaces.Panels.profiles[profileName]
		local ArtworkSV = (LUI.db and LUI.db.sv.namespaces.ArtworkV3) and LUI.db.sv.namespaces.ArtworkV3.profiles[profileName]

		local artModule = LUI:GetModule("Artwork")
		local oldPanelDefaults = {
			Chat = {
				OffsetX = 0, OffsetY = 0,
				AlwaysShow = false, IsShown = false,
				Direction = "TOPRIGHT",
				Animation = "AlphaSlide",
				Width = 429, Height = 181
			},
			Tps = {
				OffsetX = 0, OffsetY = 0,
				Width = 193, Height = 181,
				AlwaysShow = false, IsShown = false,
				Anchor = "OmenAnchor",
				Additional = "",
				Direction = "TOP",
				Animation = "AlphaSlide",
			},
			Dps = {
				OffsetX = 0, OffsetY = -30,
				Width = 193, Height = 181,
				AlwaysShow = false, IsShown = false,
				Anchor = "Recount_MainWindow",
				Additional = "",
				Direction = "TOP",
				Animation = "AlphaSlide",
			},
			Raid = {
				OffsetX = 0, OffsetY = 0,
				Width = 409, Height = 181,
				AlwaysShow = false, IsShown = false,
				Anchor = "oUF_LUI_raid",
				Additional = "",
				Direction = "TOPLEFT",
				Animation = "AlphaSlide",
			},
		}
		local oldArtworkDefaults = {
			UpperArt = {
				Orb = true,
				Buttons = true,
				ButtonsBackground = true,
				CenterBackground = true,
			},
			LowerArt = {
				BlackLine = true,
				ThemedLine = true,
			},
		}
		local matchingArtworkSetting = {
			Orb = "ShowOrb",
			Buttons = "ShowButtons",
			ButtonsBackground = "TopBackground",
			CenterBackground = "CenterBackground",
			BlackLine = "BlackLines",
			ThemedLine = "ThemedLines",
		}
		
		for panel, v in pairs(oldPanelDefaults) do
			if PanelsSV and PanelsSV[panel] then
				for setting, value in pairs(v) do
					if PanelsSV[panel][setting] ~= nil and PanelsSV[panel][setting] ~= value and setting ~= "Animation" then
						artModule.db.profile.LUITextures[panel][setting] = PanelsSV[panel][setting]
					end
				end
				PanelsSV[panel] = nil
			end
		end
		if ArtworkSV and ArtworkSV.UpperArt then
			for setting, value in pairs(oldArtworkDefaults.UpperArt) do
				if ArtworkSV.UpperArt[setting] ~= nil and ArtworkSV.UpperArt[setting] ~= value then
					local matchingSetting = matchingArtworkSetting[setting]
					artModule.db.profile.LUITextures.NavBar[matchingSetting] = ArtworkSV.UpperArt[setting]
				end
			end
			ArtworkSV.UpperArt = nil
		end
		if ArtworkSV and ArtworkSV.LowerArt then
			for setting, value in pairs(oldArtworkDefaults.LowerArt) do
				if ArtworkSV.LowerArt[setting] ~= nil and ArtworkSV.LowerArt[setting] ~= value then
					local matchingSetting = matchingArtworkSetting[setting]
					artModule.db.profile.LUITextures.NavBar[matchingSetting] = ArtworkSV.LowerArt[setting]
				end
			end
			ArtworkSV.LowerArt = nil
		end
	end

	if ver < 5 then
		local chat = LUI:GetModule("Chat", true)
		if chat and chat.db then
			chat.db.profile.General.BackgroundColor = nil
		end
		local merchant = LUI:GetModule("Merchant", true)
		if merchant and merchant.db then
			merchant.db.profile.AutoStock.Count = nil
		end

		lui_db.General.AutoAcceptInvite = nil
		lui_db.Minimap = nil
		lui_db.MicroMenu = nil
		requireReload = true
	end

	if ver < 6 then
		local raidMenu = LUI:GetModule("RaidMenu", true)
		if raidMenu and raidMenu.db and raidMenu.db.profile.ShowTooltips ~= nil then
			raidMenu.db.profile.ShowToolTips = raidMenu.db.profile.ShowTooltips
			raidMenu.db.profile.ShowTooltips = nil
		end

		local minimap = LUI:GetModule("Minimap", true)
		if minimap and minimap.db then
			minimap.db.profile.General.FontSize = nil
			minimap.db.profile.Position.Locked = nil
		end

		local uiElements = LUI:GetModule("UI Elements", true)
		if uiElements and uiElements.db then
			if uiElements.db.profile.ObjectiveTrackerFrame then
				uiElements.db.profile.ObjectiveTrackerFrame.HeaderColor = nil
			end
			for _, frameName in ipairs({"AlwaysUpFrame", "VehicleSeatIndicator", "CaptureBar", "TicketStatus", "PlayerPowerBarAlt", "GroupLootContainer", "QueueStatusButton"}) do
				if uiElements.db.profile[frameName] then
					uiElements.db.profile[frameName].HideFrame = nil
				end
			end
			uiElements.db.profile.OrderHallCommandBar = nil
		end

		local chat = LUI:GetModule("Chat", true)
		if chat and chat.db then
			chat.db.profile.x = nil
			chat.db.profile.y = nil
			chat.db.profile.point = nil
			chat.db.profile.width = nil
			chat.db.profile.height = nil
		end

		local bags = LUI:GetModule("Bags", true)
		if bags and bags.db then
			bags.db.profile.Bank = nil
			bags.db.profile.Reagent = nil
			if bags.db.profile.Bags then
				bags.db.profile.Bags.BackgroundTexture = nil
				bags.db.profile.Bags.BorderTexture = nil
				bags.db.profile.Bags.BorderSize = nil
			end
		end

		local expBars = LUI:GetModule("Experience Bars", true)
		if expBars and expBars.db then
			expBars.db.profile.Genesis = nil
			expBars.db.profile.ShowGensis = nil
			expBars.db.profile.ShowRested = nil
		end

		local unitframes = LUI:GetModule("Unitframes", true)
		if unitframes and unitframes.db then
			for _, unit in ipairs(unitframes.units) do
				local aura = unitframes.db.profile[unit] and unitframes.db.profile[unit].Aura
				if aura then
					if aura.Buffs then aura.Buffs.IncludePet = nil end
					if aura.Debuffs then
						aura.Debuffs.IncludePet = nil
						aura.Debuffs.FadeOthers = nil
					end
				end
			end
		end

		local retiredModules = {"Cooldown", "Fader"}
		for _, moduleName in ipairs(retiredModules) do
			lui_db.Modules[moduleName] = nil
			if lui_db.modules then lui_db.modules[moduleName] = nil end
		end

		local namespaces = LUI.db.sv and LUI.db.sv.namespaces
		if namespaces then
			namespaces.Cooldown = nil
			namespaces.Fader = nil
			namespaces.Panels = nil
			namespaces.ArtworkV3 = nil
		end

		local versions = LUI.db.global.luiconfig[LUI.profileName].Versions
		versions.Cooldown = nil
		versions.cooldown = nil
		versions.Fader = nil
		versions.fader = nil
		versions.Omen = nil
		versions.omen = nil
		versions.Recount = nil
		versions.recount = nil
		lui_db.Recount = nil
		requireReload = true
	end

	if ver < 7 then
		lui_db.Installed = nil

		local unitframes = LUI:GetModule("Unitframes", true)
		if unitframes and unitframes.db then
			local profile = unitframes.db.profile
			profile.Settings.HideBlizzRaid = nil

			for _, unit in ipairs(unitframes.units) do
				local unitDB = profile[unit]
				if unitDB then
					-- Preserve the old PvP indicator setting that the original
					-- conversion accidentally stored under a misspelled key.
					if unitDB.PvIndicator and unitDB.PvPIndicator then
						MergeRecursive(unitDB.PvPIndicator, unitDB.PvIndicator)
					end

					for _, key in ipairs({
						"Bars", "Texts", "Icons", "FakeTable", "Fader", "UseBlizzard",
						"ClassPowerText", "ComboPointsBar", "CornerAura", "RaidDebuff", "PvIndicator",
					}) do
						unitDB[key] = nil
					end

					if unitDB.Border then unitDB.Border.Target = nil end
					if unitDB.Aura then
						for _, auraType in ipairs({"Buffs", "Debuffs"}) do
							local aura = unitDB.Aura[auraType]
							if aura then
								aura.IncludePet = nil
								aura.FadeOthers = nil
							end
						end
					end
				end
			end

		end

		local artwork = LUI:GetModule("Artwork", true)
		if artwork and artwork.db then
			local artDB = artwork.db.profile
			for _, side in pairs(artDB.SideBars) do
				side.Offset = nil
				side.Additional = nil
				side.HideEmpty = nil
			end

			local meter2 = artDB.LUITextures.Tps
			if meter2.Anchor == "OmenAnchor" then
				meter2.Anchor = "DetailsBaseFrame2"
				meter2.Additional = "DetailsRowFrame2"
			end

			local meter1 = artDB.LUITextures.Dps
			if meter1.Anchor == "Recount_MainWindow" then
				meter1.Anchor = "DetailsBaseFrame1"
				meter1.Additional = "DetailsRowFrame1"
			end
		end

		local expBars = LUI:GetModule("Experience Bars", true)
		if expBars and expBars.db then
			local expBarsDB = expBars.db.profile
			if expBarsDB.ExpBarFill == "Gradient" then
				expBarsDB.ExpBarFill = "LUI_Gradient"
			end
			if expBarsDB.ExpBarBg == "Minimalist" then
				expBarsDB.ExpBarBg = "LUI_Minimalist"
			end
		end

		requireReload = true
	end

	if ver < 8 then
		-- Profiles that already passed older migrations can still contain data
		-- from modules and integration presets removed in this release.
		for _, moduleName in ipairs({"Cooldown", "Fader"}) do
			lui_db.Modules[moduleName] = nil
			if lui_db.modules then lui_db.modules[moduleName] = nil end
		end
		lui_db.Cooldown = nil
		lui_db.Fader = nil
		lui_db.Recount = nil
		lui_db.Installed = nil
		lui_db.Fonts = nil

		local namespaces = LUI.db.sv and LUI.db.sv.namespaces
		if namespaces then
			namespaces.Cooldown = nil
			namespaces.Fader = nil
			namespaces.Panels = nil
			namespaces.ArtworkV3 = nil
		end

		local versions = LUI.db.global.luiconfig[LUI.profileName].Versions
		for _, key in ipairs({
			"Cooldown", "cooldown", "Fader", "fader", "Omen", "omen",
			"Recount", "recount", "Bartender", "bartender", "Plexus", "plexus",
		}) do
			versions[key] = nil
		end

		local minimap = LUI:GetModule("Minimap", true)
		if minimap and minimap.db then
			local minimapDB = minimap.db.profile
			local oldScale = rawget(minimapDB.General, "Scale")
			if oldScale ~= nil then
				minimapDB.Position.Scale = oldScale
				minimapDB.General.Scale = nil
			end
		end

		requireReload = true
	end

	if ver < 9 then
		local uiElements = LUI:GetModule("UI Elements", true)
		if uiElements and uiElements.db then
			local uiDB = uiElements.db.profile
			local oldZoneObjectives = rawget(uiDB, "AlwaysUpFrame")
			if oldZoneObjectives then
				MergeRecursive(uiDB.ZoneObjectives, oldZoneObjectives)
			end
			local oldGroupLoot = rawget(uiDB, "GroupLootContainer")
			if oldGroupLoot then
				MergeRecursive(uiDB.GroupLoot, oldGroupLoot)
			end
			for _, key in ipairs({
				"ObjectiveTrackerFrame", "QueueStatusButton", "PlayerPowerBarAlt",
				"AlwaysUpFrame", "DurabilityFrame", "VehicleSeatIndicator",
				"GroupLootContainer",
			}) do
				uiDB[key] = nil
			end
		end

		requireReload = true
	end

	if ver < 10 then
		local unitframes = LUI:GetModule("Unitframes", true)
		if unitframes and unitframes.db then
			local nameText = unitframes.db.profile.raid and unitframes.db.profile.raid.NameText
			if nameText and rawget(nameText, "ColorByClass") ~= nil then
				nameText.ColorNameByClass = nameText.ColorByClass
				nameText.ColorByClass = nil
			end
		end

		local artwork = LUI:GetModule("Artwork", true)
		if artwork and artwork.db then
			for _, panelDB in pairs(artwork.db.profile.Textures) do
				if panelDB.Texture == "panel_corner.tga" then
					panelDB.Texture = "panel_corner_fill.tga"
				end
			end
		end

		requireReload = true
	end

	db.dbVersion = DB_VERSION
	LUI:Printf("Conversion done! Profile %s has been updated to latest standards.", LUI.db:GetCurrentProfile())

	-- Clean up without causing the rest of the UI to stop loading if something occurs.
	pcall(ExecuteCleanUp)

	if requireReload then
		StaticPopup_Show("RELOAD_UI")
	end
end
