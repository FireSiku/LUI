---@type string, LUIAddon
local addonName, LUI = ...
local L = LUI.L
local db, default

-- Increase whenever there are changes that would require remediation
-- The changes related to the version should be appended in an new IF block of the ApplyUpdate function.
local DB_VERSION = 1

StaticPopupDialogs["LUI_DB_UPDATE"] = {
	preferredIndex = 3,
	text = "This version of LUI contains settings that uses a different format. Do you want LUI to convert the affected settings to the new format?\n\nNote: Do not downgrade the version of LUI after conversion has been done. Behavior may be unexpected.",
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

	LUI:Print(DB_VERSION, ">", db.dbVersion)
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
--     db.Old = nil
-- end

--- Helper function to reduce the overall number of IF statements
---@param old_db table @ Table that contains the old setting.
---@param old_name string @ The old name of the setting to look up in the db
---@param new_name string @ The new name of the setting that should be updated
---@param new_db table? @ If the new setting is in different table. If missing, it will use old_db as the destination
local function Convert(old_db, old_name, new_name, new_db)
	if not old_db then return end -- Nothing to convert.

	assert(type(old_db) == "table", "Setting conversion failed for "..old_name..". Expected table, received "..type(old_db))
	if not new_db then new_db = old_db end
	if old_db[old_name] then
		new_db[new_name] = old_db[old_name]
		old_db[old_name] = nil
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

	if ver < 1 then
		-- Tooltip and Minimap used to be part of LUI.db, so they need to be converted
		local tt_db = LUI:GetModule("Tooltip").db.profile
		if lui_db.Tooltip then
			Convert(lui_db.Tooltip, "Hidecombat", "HideCombat", tt_db)
			Convert(lui_db.Tooltip, "Hidebuttons", "HideCombatSkills", tt_db)
			Convert(lui_db.Tooltip, "Hideuf", "HideUF", tt_db)
			Convert(lui_db.Tooltip, "ShowSex", "ShowSex", tt_db)
			Convert(lui_db.Tooltip, "Cursor", "Cursor", tt_db)
			Convert(lui_db.Tooltip, "Point", "Point", tt_db)
			Convert(lui_db.Tooltip, "Scale", "Scale", tt_db)
			Convert(lui_db.Tooltip, "X", "X", tt_db)
			Convert(lui_db.Tooltip, "Y", "Y", tt_db)
			Convert(lui_db.Tooltip.Health, "Texture", "HealthBar", tt_db)
			Convert(lui_db.Tooltip.Background, "Texture", "BgTexture", tt_db)
			Convert(lui_db.Tooltip.Background, "Color", "Background", tt_db.Colors)	
			Convert(lui_db.Tooltip.Border, "Texture", "BorderTexture", tt_db)
			Convert(lui_db.Tooltip.Border, "Size", "BorderSize", tt_db)
			Convert(lui_db.Tooltip.Border, "Color", "Border", tt_db.Colors)
		end

		local mm_db = LUI:GetModule("Minimap").db.profile
		if lui_db.Minimap then
			Convert(lui_db.Minimap.General, "AlwaysShowText", "AlwaysShowText", mm_db.General)
			Convert(lui_db.Minimap.General, "Size", "Scale", mm_db.General)
			Convert(lui_db.Minimap.General, "ShowTextures", "ShowTextures", mm_db.General)
			Convert(lui_db.Minimap.General, "MissionReport", "MissionReport", mm_db.General)

			if lui_db.Minimap.General then
				Convert(lui_db.Minimap.General.Position, "X", "X", mm_db.Position)
				Convert(lui_db.Minimap.General.Position, "Y", "Y", mm_db.Position)
				Convert(lui_db.Minimap.General.Position, "Point", "Point", mm_db.Position)
				Convert(lui_db.Minimap.General.Position, "UnLocked", "Locked", mm_db.Position)
				mm_db.Position.Locked = not mm_db.PositionLocked -- Converted setting was opposite
			end

			Convert(lui_db.Minimap.Font, "Font", "Name", mm_db.Fonts.Text)
			Convert(lui_db.Minimap.Font, "FontSize", "Size", mm_db.Fonts.Text)
			Convert(lui_db.Minimap.Font, "FontFlag", "Flag", mm_db.Fonts.Text)
			Convert(lui_db.Minimap, "Icon", "Icons", mm_db)
		
			-- Minimap Frames got moved to UI Elements
			if lui_db.Minimap.Frames then
				local ui_db = LUI:GetModule("UI Elements").db.profile
				
				Convert(lui_db.Minimap.Frames,    "AlwaysUpFrameX",         "X",              ui_db.AlwaysUpFrame)
				Convert(lui_db.Minimap.Frames,    "AlwaysUpFrameY",         "Y",              ui_db.AlwaysUpFrame)
				Convert(lui_db.Minimap.Frames, "SetAlwaysUpFrame",          "ManagePosition", ui_db.AlwaysUpFrame)
				Convert(lui_db.Minimap.Frames,    "VehicleSeatIndicatorX",  "X",              ui_db.VehicleSeatIndicator)
				Convert(lui_db.Minimap.Frames,    "VehicleSeatIndicatorY",  "Y",              ui_db.VehicleSeatIndicator)
				Convert(lui_db.Minimap.Frames, "SetVehicleSeatIndicator",   "ManagePosition", ui_db.VehicleSeatIndicator)
				Convert(lui_db.Minimap.Frames,    "DurabilityFrameX",       "X",              ui_db.DurabilityFrame)
				Convert(lui_db.Minimap.Frames,    "DurabilityFrameY",       "Y",              ui_db.DurabilityFrame)
				Convert(lui_db.Minimap.Frames, "SetDurabilityFrame",        "ManagePosition", ui_db.DurabilityFrame)
				Convert(lui_db.Minimap.Frames,    "ObjectiveTrackerFrameX", "X",              ui_db.ObjectiveTrackerFrame)
				Convert(lui_db.Minimap.Frames,    "ObjectiveTrackerFrameY", "Y",              ui_db.ObjectiveTrackerFrame)
				Convert(lui_db.Minimap.Frames, "SetObjectiveTrackerFrame",  "ManagePosition", ui_db.ObjectiveTrackerFrame)
				Convert(lui_db.Minimap.Frames,    "CaptureBarX",            "X",              ui_db.CaptureBar)
				Convert(lui_db.Minimap.Frames,    "CaptureBarY",            "Y",              ui_db.CaptureBar)
				Convert(lui_db.Minimap.Frames, "SetCaptureBar",             "ManagePosition", ui_db.CaptureBar)
				Convert(lui_db.Minimap.Frames,    "TicketStatusX",          "X",              ui_db.TicketStatus)
				Convert(lui_db.Minimap.Frames,    "TicketStatusY",          "Y",              ui_db.TicketStatus)
				Convert(lui_db.Minimap.Frames, "SetTicketStatus",           "ManagePosition", ui_db.TicketStatus)
				Convert(lui_db.Minimap.Frames,    "PlayerPowerBarAltX",     "X",              ui_db.PlayerPowerBarAlt)
				Convert(lui_db.Minimap.Frames,    "PlayerPowerBarAltY",     "Y",              ui_db.PlayerPowerBarAlt)
				Convert(lui_db.Minimap.Frames, "SetPlayerPowerBarAlt",      "ManagePosition", ui_db.PlayerPowerBarAlt)
				Convert(lui_db.Minimap.Frames,    "GroupLootContainerX",    "X",              ui_db.GroupLootContainer)
				Convert(lui_db.Minimap.Frames,    "GroupLootContainerY",    "Y",              ui_db.GroupLootContainer)
				Convert(lui_db.Minimap.Frames, "SetGroupLootContainer",     "ManagePosition", ui_db.GroupLootContainer)
				Convert(lui_db.Minimap.Frames,    "MawBuffsX",              "X",              ui_db.MawBuffs)
				Convert(lui_db.Minimap.Frames,    "MawBuffsY",              "Y",              ui_db.MawBuffs)
				Convert(lui_db.Minimap.Frames, "SetMawBuffs",               "ManagePosition", ui_db.MawBuffs)
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
			theme_db.minimap = nil
		end
		
		local micro_db = LUI:GetModule("Micromenu").db.profile
		if theme_db and theme_db.micromenu then
			if AreColorsEqual(theme_db.micromenu, colorMod:Color(LUI.playerClass)) then
				micro_db.Colors.Micromenu.t = "Class"
			else
				micro_db.Colors.Micromenu.r = theme_db.micromenu[1]
				micro_db.Colors.Micromenu.g = theme_db.micromenu[2]
				micro_db.Colors.Micromenu.b = theme_db.micromenu[3]
				micro_db.Colors.Micromenu.t = "Individual"
			end
			if AreColorsEqual(theme_db.micromenu_bg, colorMod:Color(LUI.playerClass)) then
				micro_db.Colors.Micromenu.t = "Class"
			else
				micro_db.Colors.Background.r = theme_db.micromenu_bg[1]
				micro_db.Colors.Background.g = theme_db.micromenu_bg[2]
				micro_db.Colors.Background.b = theme_db.micromenu_bg[3]
				micro_db.Colors.Background.t = "Individual"
			end
			theme_db.micromenu = nil
			theme_db.micromenu_bg = nil
			theme_db.micromenu_bg2 = nil
			theme_db.micromenu_btn = nil
			theme_db.micromenu_btn_hover = nil
		end
		
		-- Unitframes conversions
		local uf_db = LUI:GetModule("Unitframes").db.profile
		local units = {
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
		
		if uf_db.Player then
			Convert(uf_db.Player.Bars,  "HealPrediction", "HealthPrediction")
			Convert(uf_db.Player.Bars,  "DruidMana",      "AdditionalPower")
			Convert(uf_db.Player.Texts, "DruidMana",      "AdditionalPower")
			Convert(uf_db.Player.Bars,  "AltPower",       "AlternativePower")
			Convert(uf_db.Player.Texts, "AltPower",       "AlternativePower")
			Convert(uf_db.Player.Bars,  "HolyPower",      "ClassPower")
			Convert(uf_db.Player.Bars,  "Chi",            "ClassPower")
			Convert(uf_db.Player.Bars,  "WarlockBar",     "ClassPower")
			Convert(uf_db.Player.Bars,  "ArcaneCharges",  "ClassPower")
			Convert(uf_db.Player.Texts, "WarlockBar",     "ClassPower")

			if uf_db.Player.Bars then
				uf_db.Player.Bars.ShadowOrbs = nil
				uf_db.Player.Bars.Eclipse = nil
			end
			if uf_db.Player.Texts then
				uf_db.Player.Texts.Eclipse = nil
				uf_db.Player.Texts.WarlockBar = nil
			end
			if uf_db.Colors then
				uf_db.Colors.ShadowOrbsBar = nil
				uf_db.Colors.EclipseBar = nil
			end
		end

		for oldUnit, unitId in pairs(units) do
			--- Convert the tables to use unitId keys, changes Player -> player,  ToT > targettargettarget and so on.
			Convert(uf_db, oldUnit, unitId)
			local unit_db = uf_db[unitId]

			Convert(unit_db.Bars,  "Health", "HealthBar", unit_db)
			Convert(unit_db.Bars,  "Power",  "PowerBar", unit_db)
			Convert(unit_db.Bars,  "TotalAbsorb", "TotalAbsorbBar", unit_db)
			Convert(unit_db.Bars,  "HealthPrediction", "HealthPredictionBar", unit_db)
			Convert(unit_db.Bars,  "AlternativePower", "AlternativePowerBar", unit_db)
			Convert(unit_db.Bars,  "AdditionalPower", "AdditionalPowerBar", unit_db)
			Convert(unit_db.Bars,  "ClassPower", "ClassPowerBar", unit_db)
			Convert(unit_db.Bars,  "ComboPoints", "ComboPointsBar", unit_db)
			Convert(unit_db.Bars,  "Totemsw", "TotemsBar", unit_db)
			Convert(unit_db.Bars,  "Runes", "RunesBar", unit_db)
			Convert(unit_db.Texts, "Combat", "CombatFeedback", unit_db)
			Convert(unit_db.Texts, "Name", "NameText", unit_db)
			Convert(unit_db.Texts, "Health", "HealthText", unit_db)
			Convert(unit_db.Texts, "Power", "PowerText", unit_db)
			Convert(unit_db.Texts, "PvP", "PvPText", unit_db)
			Convert(unit_db.Texts, "HealthPercent", "HealthPercentText", unit_db)
			Convert(unit_db.Texts, "HealthMissing", "HealthMissingText", unit_db)
			Convert(unit_db.Texts, "PowerPercent", "PowerPercentText", unit_db)
			Convert(unit_db.Texts, "PowerMissing", "PowerMissingText", unit_db)
			Convert(unit_db.Texts, "AlternativePower", "AlternativePowerText", unit_db)
			Convert(unit_db.Texts, "AdditionalPower", "AdditionalPowerText", unit_db)
			Convert(unit_db.Texts, "ClassPower", "ClassPowerText", unit_db)
			Convert(unit_db.Icons, "Leader", "LeaderIndicator", unit_db)
			Convert(unit_db.Icons, "Role", "GroupRoleIndicator", unit_db)
			Convert(unit_db.Icons, "Raid", "RaidMarkerIndicator", unit_db)
			Convert(unit_db.Icons, "Resting", "RestingIndicator", unit_db)
			Convert(unit_db.Icons, "Combat", "CombatIndicator", unit_db)
			Convert(unit_db.Icons, "PvP", "PvIndicator", unit_db)
			if unit_db.Castbar then
				Convert(unit_db.Castbar.Text, "Name", "NameText", unit_db.Castbar)
				Convert(unit_db.Castbar.Text, "Time", "TimeText", unit_db.Castbar)
			end
		end
	end

	db.dbVersion = DB_VERSION
	LUI:Print(db.dbVersion)
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