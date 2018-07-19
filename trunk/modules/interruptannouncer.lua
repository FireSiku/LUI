--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: interruptannouncer.lua
	Description: Accounces to Party/Raid when the player interrupts a spell; giving the info.
	Version....: 1.8
	Rev Date...: 09/07/2011 [dd/mm/yyyy]
	Author.....: Hix [Trollbane] <Lingering>

	Notes:
		Announces while in a raid or party. Disabled while in battlegrounds and WorldPVP zones (while in battle).
		This is an evolved version of the Hix: Interrupt Announcer addOn, providing LUI incorporation and additional options.
]]

-- External references.
local addonname, LUI = ...
local module = LUI:Module("InterruptAnnouncer", "AceEvent-3.0")
local Profiler = LUI.Profiler

LUI.Versions.interrupt = 2

-- Database and defaults shortcuts.
local db, dbd

local partyChatChannels = {"SAY", "YELL", "PARTY"}
local raidChatChannels = {"SAY", "YELL", "PARTY", "RAID", "RAID_WARNING"}

 -- spellID/spellName is the spell used to interrupt; interruptedSpellID/interruptedSpellName is the spell that was interruped
function module:COMBAT_LOG_EVENT_UNFILTERED(_, timestamp, event, _, sourceGUID, sourceName, _, _, _, destName, _, _, spellID, spellName, _, interruptedSpellID, interruptedSpellName)
	-- Filter combat events.
	if event ~= "SPELL_INTERRUPT" then return end
	if sourceGUID ~= self.GUID and sourceGUID ~= self.petGUID then return end
	if timestamp == self.lastTime and interruptedSpellID == self.lastInterrupt then return end

	-- Update variables.
	self.lastTime, self.lastInterrupt = timestamp, interruptedSpellID

	-- Send chat message.
	if db.General.EnableFormat then
		-- Create msg from custom format and keywords.
		local msg = db.Format.Format
		msg = msg:gsub("!player", sourceName)
		msg = msg:gsub("!target", destName)
		msg = msg:gsub("!interruptSpell", spellName)
		msg = msg:gsub("!interruptLink", GetSpellLink(spellID))
		msg = msg:gsub("!spellName", interruptedSpellName)
		msg = msg:gsub("!spellLink", GetSpellLink(interruptedSpellID))

		SendChatMessage(msg, self.channel)
	else
		SendChatMessage(format("%s - %s (%s)", spellName, GetSpellLink(interruptedSpellID), destName), self.channel)
	end
end

function module:GROUP_ROSTER_UPDATE()
	-- Check if announcer should be enabled/disabled.
	local _, instanceType = IsInInstance()
	if (instanceType == "pvp") or IsInActiveWorldPVP() or ((GetNumGroupMembers() == 0) and (GetNumSubgroupMembers() == 0)) then
		return module:Deactivate()
	end

	-- Set channel for output.
	if (IsInRaid()) then
		if not db.General.EnableRaid then
			return module:Deactivate()
		end

		if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
			self.channel = "INSTANCE_CHAT"
		elseif db.General.AnnounceRaid == "RAID_WARNING" and not UnitIsGroupLeader("player") and not UnitIsGroupAssistant("player") then
			self.channel = "RAID"
		else
			self.channel = db.General.AnnounceRaid
		end
	else
		if not db.General.EnableParty then
			return module:Deactivate()
		end

		if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
			self.channel = "INSTANCE_CHAT"
		else
			self.channel = db.General.AnnounceParty
		end
	end

	if self.GUID then return end

	-- Collect GUIDs.
	self.GUID = UnitGUID("player")
	self:UNIT_PET(_, "player")

	-- Register combat events.
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function module:UNIT_PET(_, unit)
	if not (db.General.EnablePet and unit == "player" and self.GUID) then return end

	-- Update pet GUID.
	self.petGUID = UnitGUID("pet")
end

function module:Deactivate()
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	-- Reset variables.
	self.channel = nil
	self.GUID = nil
	self.lastTime = nil
	self.lastInterrupt = nil
	self.petGUID = nil
end


---[[	PROFILER
-- Add InterruptAnnouncer functions to the profiler.
Profiler.TraceScope(module, "InterruptAnnouncer", "LUI")
--]]


-- Defaults for the module.
module.defaults = {
	profile = {
		Enable = true,
		General = {
			EnableParty = true,
			EnableRaid = true,
			AnnounceParty = "PARTY",
			AnnounceRaid = "RAID",
			EnablePet = true,
			EnableFormat = false,
		},
		Format = {
			Format = "!interruptSpell - !spellLink (!target)",
		},
	},
}

module.optionsName = "Interrupt Announcer"
module.getter = function(info) return (info.option.type == "select" and info.option.values(db(info)) or db(info)) end
module.setter = function(info, value) db(info, info.option.type == "select" and info.option.values()[value] or value); module:Refresh() end

-- Load options: Creates the options menu for LUI.
function module:LoadOptions()
	local partyDisabled = function()
		return not db.General.EnableParty
	end
	local raidDisabled = function()
		return not db.General.EnableRaid
	end
	local customDisabled = function()
		return not db.General.EnableFormat
	end

	local options = {
		General = self:NewGroup("General", 1, {
			Title = self:NewHeader("Interrupt Announcer", 1),
			Info = self:NewGroup("Info", 2, true, {
				A = self:NewDesc("This module will announce to your group when you interrupt a spell while in a party or raid.", 1),
				B = self:NewDesc("The interrupt announcer is disabled while in battlegrounds and WorldPVP (while in battle).", 2),
				C = self:NewDesc("A standalone version of this addon is available on curse if prefered:\nhttp://wow.curse.com/downloads/wow-addons/details/hix_interruptannouncer.aspx", 3),
			}),
			Settings = self:NewHeader("Settings", 3),
			EnableParty = self:NewToggle("Enable In Party", nil, 4, true, "normal"),
			AnnounceParty = self:NewSelect("Announce Channel For Party", "Which channel to announce interrupts to while in a party", 5, partyChatChannels, nil, true, nil, partyDisabled),
			EnableRaid = self:NewToggle("Enable In Raid", nil, 6, true, "normal"),
			AnnounceRaid = self:NewSelect("Announce Channel For Raid", "Which channel to announce interrupts to while in a raid", 7, raidChatChannels, nil, true, nil, raidDisabled),
			EnablePet = self:NewToggle("Announce Pet Interrupts", nil, 8, true),
			EnableFormat = self:NewToggle("Enable Custom Format", nil, 9, true),
		}),
		Format = self:NewGroup("Announce Format", 2, false, customDisabled, {
			Info = self:NewGroup("Info", 1, true, {
				A = self:NewDesc("You can customise the interrupt announcers output format.", 1),
				B = self:NewDesc("Enter into the box below the format you wish to use. There are select keywords that will be replaced by realtime data before outputing:", 2),
				C = self:NewDesc("!player = interruptors name\n!target = targets name\n!interruptSpell = the name of the spell used to interrupt\n!interruptLink = the spell link of the spell used to interrupt", 3),
				D = self:NewDesc("!spellName = the name of the spell that was interrupted\n!spellLink = the spell link of the spell that was interrupted.", 4),
			}),
			Format = self:NewInput("Announce Format", "Create a string that becomes the interrupt announcers output format. Use keywords to be replaced by realtime data.", 2, true, "double"),
		}),
	}

	return options
end

module.Refresh = module.GROUP_ROSTER_UPDATE

-- Initialize module: Called when the addon should intialize its self; this is where we load in database values.
function module:OnInitialize()
	db, dbd = LUI:NewNamespace(self, true)
	local ProfileName = UnitName("player").." - "..GetRealmName()

	if LUI.db.global.luiconfig[ProfileName].Versions.interrupt ~= LUI.Versions.interrupt then
		db:ResetProfile()
		LUI.db.global.luiconfig[ProfileName].Versions.interrupt = LUI.Versions.interrupt
	end
end

-- Enable module: Called when addon is enabled.
function module:OnEnable()
	self:RegisterEvent("UNIT_PET")
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE")
	self:GROUP_ROSTER_UPDATE()
end

function module:OnDisable()
	self:UnregisterAllEvents()
	self:Deactivate()
end
