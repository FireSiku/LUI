---@type string, LUIAddon
local addonName, LUI = ...
local L = LUI.L
local db, default

-- Increase whenever there are changes that would require remediation
-- The changes related to the version should be appended in an new IF block of the ApplyUpdate function.
local DB_VERSION = 3

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

--Test function
function LUI:_Resync()
	LUI:ApplyUpdate(0)
end

-- For the most part, conversion should be in this format. 
-- if db.Old then
--     db.New = db.Old
--     table.insert(cleanUp[db], Old)
-- end

-- Table structure:  cleanUp[tableRef] = { Array of table keys to clean up }
-- This metatable will automatically create an empty array if cleanUp[tableRef] doesn't exist yet.
local cleanUp = setmetatable({}, {__index = function(t, k) t[k] = {}; return t[k] end, __mode = "k"})

local function ExecuteCleanUp()
	for t, k in pairs(cleanUp) do
		t[k] = nil
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
---@param old_name string @ The old name of the setting to look up in the db
---@param new_name string @ The new name of the setting that should be updated
---@param new_db table? @ If the new setting is in different table. If missing, it will use old_db as the destination
local function Convert(display_name, old_db, old_name, new_name, new_db)
	if not old_db then return end -- Nothing to convert.

	assert(type(old_db) == "table", "Setting conversion failed for "..old_name..". Expected table, received "..type(old_db))
	if not new_db then new_db = old_db end
	if old_db[old_name] then
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
			Convert("Tooltip", lui_db.Tooltip, "ShowSex", "ShowSex", tt_db)
			Convert("Tooltip", lui_db.Tooltip, "Cursor", "Cursor", tt_db)
			Convert("Tooltip", lui_db.Tooltip, "Point", "Point", tt_db)
			Convert("Tooltip", lui_db.Tooltip, "Scale", "Scale", tt_db)
			Convert("Tooltip", lui_db.Tooltip, "X", "X", tt_db)
			Convert("Tooltip", lui_db.Tooltip, "Y", "Y", tt_db)
			Convert("Tooltip", lui_db.Tooltip.Border, "Size", "BorderSize", tt_db)
			Convert("Tooltip.Textures", lui_db.Tooltip.Health, "Texture", "HealthBar", tt_db)
			Convert("Tooltip.Textures", lui_db.Tooltip.Background, "Texture", "BgTexture", tt_db)
			Convert("Tooltip.Textures", lui_db.Tooltip.Border, "Texture", "BorderTexture", tt_db)
			Convert("Tooltip.Colors", lui_db.Tooltip.Background, "Color", "Background", tt_db.Colors)	
			Convert("Tooltip.Colors", lui_db.Tooltip.Border, "Color", "Border", tt_db.Colors)

			if tt_mod.Refresh then tt_mod:Refresh() end
		end

		local mm_mod = LUI:GetModule("Minimap")
		local mm_db = mm_mod.db.profile
		if lui_db.Minimap then
			Convert("Minimap", lui_db.Minimap.General, "AlwaysShowText", "AlwaysShowText", mm_db.General)
			Convert("Minimap", lui_db.Minimap.General, "Size", "Scale", mm_db.General)
			Convert("Minimap", lui_db.Minimap.General, "ShowTextures", "ShowTextures", mm_db.General)
			Convert("Minimap", lui_db.Minimap.General, "MissionReport", "MissionReport", mm_db.General)

			if lui_db.Minimap.General then
				Convert("Minimap.Position", lui_db.Minimap.General.Position, "X", "X", mm_db.Position)
				Convert("Minimap.Position", lui_db.Minimap.General.Position, "Y", "Y", mm_db.Position)
				Convert("Minimap.Position", lui_db.Minimap.General.Position, "Point", "Point", mm_db.Position)
				-- Need to check so we dont switch the default Locked if Unlocked is not found
				local UnLocked = lui_db.Minimap.General.Position and lui_db.Minimap.General.Position.UnLocked or nil
				if UnLocked then
					Convert("Minimap.Position", lui_db.Minimap.General.Position, "UnLocked", "Locked", mm_db.Position)
					mm_db.Position.Locked = not mm_db.PositionLocked -- Converted setting was opposite
					LUI:Printf("Minimap.Position.Locked has been re-adjusted to %s (Was Position.Unlocked: %s)", not UnLocked, UnLocked)
				end
			end

			Convert("Minimap.Font", lui_db.Minimap.Font, "Font", "Name", mm_db.Fonts.Text)
			Convert("Minimap.Font", lui_db.Minimap.Font, "FontSize", "Size", mm_db.Fonts.Text)
			Convert("Minimap.Font", lui_db.Minimap.Font, "FontFlag", "Flag", mm_db.Fonts.Text)
			Convert("Minimap.Icons", lui_db.Minimap, "Icon", "Icons", mm_db)
			
			if mm_mod.Refresh then mm_mod:Refresh() end

			-- Minimap Frames got moved to UI Elements
			if lui_db.Minimap.Frames then
				local ui_mod = LUI:GetModule("UI Elements")
				local ui_db = ui_mod.db.profile

				Convert("UIElements.AlwaysUpFrame",         lui_db.Minimap.Frames,    "AlwaysUpFrameX",         "X",              ui_db.AlwaysUpFrame)
				Convert("UIElements.AlwaysUpFrame",         lui_db.Minimap.Frames,    "AlwaysUpFrameY",         "Y",              ui_db.AlwaysUpFrame)
				Convert("UIElements.AlwaysUpFrame",         lui_db.Minimap.Frames, "SetAlwaysUpFrame",          "ManagePosition", ui_db.AlwaysUpFrame)
				Convert("UIElements.VehicleSeatIndicator",  lui_db.Minimap.Frames,    "VehicleSeatIndicatorX",  "X",              ui_db.VehicleSeatIndicator)
				Convert("UIElements.VehicleSeatIndicator",  lui_db.Minimap.Frames,    "VehicleSeatIndicatorY",  "Y",              ui_db.VehicleSeatIndicator)
				Convert("UIElements.VehicleSeatIndicator",  lui_db.Minimap.Frames, "SetVehicleSeatIndicator",   "ManagePosition", ui_db.VehicleSeatIndicator)
				Convert("UIElements.DurabilityFrame",       lui_db.Minimap.Frames,    "DurabilityFrameX",       "X",              ui_db.DurabilityFrame)
				Convert("UIElements.DurabilityFrame",       lui_db.Minimap.Frames,    "DurabilityFrameY",       "Y",              ui_db.DurabilityFrame)
				Convert("UIElements.DurabilityFrame",       lui_db.Minimap.Frames, "SetDurabilityFrame",        "ManagePosition", ui_db.DurabilityFrame)
				Convert("UIElements.ObjectiveTrackerFrame", lui_db.Minimap.Frames,    "ObjectiveTrackerFrameX", "X",              ui_db.ObjectiveTrackerFrame)
				Convert("UIElements.ObjectiveTrackerFrame", lui_db.Minimap.Frames,    "ObjectiveTrackerFrameY", "Y",              ui_db.ObjectiveTrackerFrame)
				Convert("UIElements.ObjectiveTrackerFrame", lui_db.Minimap.Frames, "SetObjectiveTrackerFrame",  "ManagePosition", ui_db.ObjectiveTrackerFrame)
				Convert("UIElements.CaptureBar",            lui_db.Minimap.Frames,    "CaptureBarX",            "X",              ui_db.CaptureBar)
				Convert("UIElements.CaptureBar",            lui_db.Minimap.Frames,    "CaptureBarY",            "Y",              ui_db.CaptureBar)
				Convert("UIElements.CaptureBar",            lui_db.Minimap.Frames, "SetCaptureBar",             "ManagePosition", ui_db.CaptureBar)
				Convert("UIElements.TicketStatus",          lui_db.Minimap.Frames,    "TicketStatusX",          "X",              ui_db.TicketStatus)
				Convert("UIElements.TicketStatus",          lui_db.Minimap.Frames,    "TicketStatusY",          "Y",              ui_db.TicketStatus)
				Convert("UIElements.TicketStatus",          lui_db.Minimap.Frames, "SetTicketStatus",           "ManagePosition", ui_db.TicketStatus)
				Convert("UIElements.PlayerPowerBarAlt",     lui_db.Minimap.Frames,    "PlayerPowerBarAltX",     "X",              ui_db.PlayerPowerBarAlt)
				Convert("UIElements.PlayerPowerBarAlt",     lui_db.Minimap.Frames,    "PlayerPowerBarAltY",     "Y",              ui_db.PlayerPowerBarAlt)
				Convert("UIElements.PlayerPowerBarAlt",     lui_db.Minimap.Frames, "SetPlayerPowerBarAlt",      "ManagePosition", ui_db.PlayerPowerBarAlt)
				Convert("UIElements.GroupLootContainer",    lui_db.Minimap.Frames,    "GroupLootContainerX",    "X",              ui_db.GroupLootContainer)
				Convert("UIElements.GroupLootContainer",    lui_db.Minimap.Frames,    "GroupLootContainerY",    "Y",              ui_db.GroupLootContainer)
				Convert("UIElements.GroupLootContainer",    lui_db.Minimap.Frames, "SetGroupLootContainer",     "ManagePosition", ui_db.GroupLootContainer)
				Convert("UIElements.MawBuffs",              lui_db.Minimap.Frames,    "MawBuffsX",              "X",              ui_db.MawBuffs)
				Convert("UIElements.MawBuffs",              lui_db.Minimap.Frames,    "MawBuffsY",              "Y",              ui_db.MawBuffs)
				Convert("UIElements.MawBuffs",              lui_db.Minimap.Frames, "SetMawBuffs",               "ManagePosition", ui_db.MawBuffs)
				
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

			if AreColorsEqual(theme_db.micromenu_bg, colorMod:Color(LUI.playerClass)) then
				micro_db.Colors.Micromenu.t = "Class"
			else
				micro_db.Colors.Background.r = theme_db.micromenu_bg[1]
				micro_db.Colors.Background.g = theme_db.micromenu_bg[2]
				micro_db.Colors.Background.b = theme_db.micromenu_bg[3]
				micro_db.Colors.Background.t = "Individual"
			end
			LUI:Printf("Micromenu.Colors.Background has been restored (used to be Themes.Colors.MicroMenu.micromenu_bg)")

			tinsert(cleanUp[theme_db], "minimap")
			tinsert(cleanUp[theme_db], "minimap_bg")
			tinsert(cleanUp[theme_db], "minimap_bg2")
			tinsert(cleanUp[theme_db], "minimap_btn")
			tinsert(cleanUp[theme_db], "minimap_btn_hover")

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
			Convert(currUnit, unit_db.Texts, "ClassPower", "ClassPowerText", unit_db)
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
				Convert(currUnit, unit_db.Texts, "WarlockBar",     "ClassPowerText", unit_db)

				if uf_db.Player.Bars then
					table.insert(cleanUp[uf_db.Player.Bars], "ShadowOrbs")
					table.insert(cleanUp[uf_db.Player.Bars], "Eclipse")
				end
				if uf_db.Player.Texts then
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
		for k, obj in pairs(oUF.objects) do
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
			Convert("UnitFrames.Player", uf_db.player.Texts, "WarlockBar",     "ClassPowerText", uf_db.player)
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
		
		-- Convert some modules that were using color arrays
		local function ConvertColorArray(name, color)
			Convert(name, color, 1, "r")
			Convert(name, color, 1, "g")
			Convert(name, color, 1, "b")
			Convert(name, color, 1, "a")
		end

		local cd_db = LUI:GetModule("Cooldown").db.profile
		ConvertColorArray("Cooldown.Colors.Day", cd_db.Colors.Day)
		ConvertColorArray("Cooldown.Colors.Hour", cd_db.Colors.Hour)
		ConvertColorArray("Cooldown.Colors.Min", cd_db.Colors.Min)
		ConvertColorArray("Cooldown.Colors.Sec", cd_db.Colors.Sec)
		ConvertColorArray("Cooldown.Colors.Threshold", cd_db.Colors.Threshold)
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
		local colorArray = {1, 2, 3, 4}

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
			if modName == "Panels" then
				local keys = {"OffsetX", "OffsetY", "Width", "Height"}
				Sanitize(db.Chat, keys)
				Sanitize(db.Tps, keys)
				Sanitize(db.Dps, keys)
				Sanitize(db.Raid, keys)
			elseif modName == "Chat" then
				Sanitize(db, {"x", "y", "width", "height"})
				Sanitize(db.General.Font, {"Size"})
				Sanitize(db.General.BackgroundColor, colorArray)
			elseif modName == "Cooldown" then
				Sanitize(db.General, {"MinDuration", "MinScale", "Precision", "Threshold", "MinToSec"})
			elseif modName == "Merchant" then
				Sanitize(db.AutoRepair.Settings, {"CostLimit"})
				Sanitize(db.AutoStock.Settings, {"CostLimit"})
			elseif modName == "Micromenu" then
				Sanitize(db, {"X", "Y"})
			elseif modName == "Minimap" then
				Sanitize(db.General, {"Scale", "CoordPrecision", "FontSize"})
				Sanitize(db.Position, {"X", "Y", "Scale"})
			elseif modName == "Mirror Bar" then
				Sanitize(db.General, {"Width", "Height", "X", "Y", "BarGap"})
				Sanitize(db.Text, {"Size", "OffsetX", "OffsetY"})
				Sanitize(db.Text.Color, colorList)
				Sanitize(db.Border.Color, colorList)
				Sanitize(db.Border.Inset, insetList)
			elseif modName == "RaidMenu" then
				Sanitize(db, "Spacing", "Offset", "X_Offset", "Opacity", "Scale")
			elseif modName == "Tooltip" then
				Sanitize(db, "Scale", "X", "Y", "HealthFontSize", "BorderSize")
			elseif modName == "UI Elements" then
				for k, v in pairs(db) do
					Sanitize(db[k], {"X", "Y"})
				end
			elseif modName == "Unitframes" then
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

	db.dbVersion = DB_VERSION
	LUI:Printf("Conversion done! Profile %s has been updated to latest standards.", LUI.db:GetCurrentProfile())

	-- Clean up without causing the rest of the UI to stop loading if something occurs.
	pcall(ExecuteCleanUp)

	if requireReload then
		StaticPopup_Show("RELOAD_UI")
	end
end

--[[
7: https://www.wowinterface.com/forums/showthread.php?t=55422
8: https://www.wowinterface.com/forums/showthread.php?t=56361
9: https://www.wowinterface.com/forums/showthread.php?t=56943
10: https://www.wowinterface.com/forums/showthread.php?t=58257
Player.Bars.DruidMana
Player.Texts.DruidMana
-> AdditionalPower

Player.Bars.AltPower
Player.Texts.AltPower
-> AlternativePower

Player.Bars.HolyPower
Player.Bars.Chi
Player.Bars.WarlockBar
Player.Bars.ArcaneCharges
-> ClassPower

[All].Texts.Combat
-> CombatFeedback

[All].Icons -> Indicators
Lootmaster	-> MasterLooter
Leader		-> Leader
Role		-> GroupRole
Raid		-> RaidMarker
Resting		-> Resting
Combat		-> Combat
PvP		
ReadyCheck

Player.Bars.ShadowOrbs
Player.Bars.Eclipse
Player.Texts.Eclipse
Player.Texts.WarlockBar
-> nil
]]
