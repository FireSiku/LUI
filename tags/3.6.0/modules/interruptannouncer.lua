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
local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local module = LUI:NewModule("InterruptAnnouncer")

-- Database and defaults shortcuts.
local db, dbd

local partyChatChannels = {"SAY", "YELL", "PARTY"}
local raidChatChannels = {"SAY", "YELL", "PARTY", "RAID", "RAID_WARNING"}

-- Create module function.
function module:Create()
	if not db.Enable then return end
	
	-- Create a frame to work with.
	local IA = CreateFrame("frame")

	-- Set event script.
	IA:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)

	-- Register events.
	IA:RegisterEvent("PARTY_MEMBERS_CHANGED")
	IA:RegisterEvent("UNIT_PET")
	
	-- Locale variables for module.
	IA.channel = nil
	IA.GUID = nil
	IA.lastTime = nil
	IA.lastInterrupt = nil
	IA.petGUID = nil
	
	-- Combat log event unfiltered event function.
	function IA:COMBAT_LOG_EVENT_UNFILTERED(timeStamp, event, _, sGUID, sName,_,_,_, dName, _,_, interruptID, interruptName, _, spellID, spellName)
		-- Filter combat events.
		if (sGUID ~= self.GUID) and (sGUID ~= self.petGUID) then return end
		if (event ~= "SPELL_INTERRUPT") then return end
		if (timeStamp == self.lastTime) and (spellID == self.lastInterrupt) then return end
		
		-- Update variables.
		self.lastTime, self.lastInterrupt = timeStamp, spellID

		-- Send chat message.
		if db.EnableFormat then
			-- Create msg from custom format and keywords.
			local msg = db.Format
			msg = msg:gsub("!player", sName)
			msg = msg:gsub("!target", dName)
			msg = msg:gsub("!interruptSpell", interruptName)
			msg = msg:gsub("!interruptLink", GetSpellLink(interruptID))
			msg = msg:gsub("!spellName", spellName)
			msg = msg:gsub("!spellLink", GetSpellLink(spellID))

			SendChatMessage(msg, self.channel)
		else
			SendChatMessage(format("%s - %s (%s)", interruptName, GetSpellLink(spellID), dName), self.channel)
		end
	end

	-- Party members changed event function.
	function IA:PARTY_MEMBERS_CHANGED()
		-- Check if announcer should be enabled/disabled.
		local _, instanceType = IsInInstance()
		if (instanceType == "pvp") or IsInActiveWorldPVP() or ((GetRealNumRaidMembers() == 0) and (GetRealNumPartyMembers() == 0)) then
			-- Unregister combat events.
			self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
			self:UnregisterEvent("UNIT_PET")
		
			-- Reset variables.
			self.channel = nil
			self.GUID = nil
			self.lastTime = nil
			self.lastInterrupt = nil
			self.petGUID = nil
			return
		end

		-- Set channel for output.
		if (GetRealNumRaidMembers() > 0) then
			if db.EnableRaid then
				if (db.AnnounceRaid == "RAID_WARNING") and (not(IsRaidLeader())) and (not(IsRaidOfficer())) then
					self.channel = "RAID"
				else
					self.channel = db.AnnounceRaid
				end
			else
				-- Unregister combat events.
				self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
				self:UnregisterEvent("UNIT_PET")
		
				-- Reset variables.
				self.channel = nil
				self.GUID = nil
				self.lastTime = nil
				self.lastInterrupt = nil
				self.petGUID = nil
				return
			end
		else
			if db.EnableParty then
				self.channel = db.AnnounceParty
			else
				-- Unregister combat events.
				self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
				self:UnregisterEvent("UNIT_PET")
		
				-- Reset variables.
				self.channel = nil
				self.GUID = nil
				self.lastTime = nil
				self.lastInterrupt = nil
				self.petGUID = nil
				return
			end
		end
		
		if self.GUID then return end

		-- Collect GUIDs.
		self.GUID = UnitGUID("player")
		if db.EnablePet then self.petGUID = UnitGUID("pet") end
		
		-- Register combat events.
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:RegisterEvent("UNIT_PET")
	end

	-- Pet changed event function.
	function IA:UNIT_PET(unit)
		if unit ~= "player" then return end
		if not self.GUID then return end
		if not db.EnablePet then return end
	
		-- Update pet GUID.
		self.petGUID = UnitGUID("pet")
	end	
end

-- Defaults for the module.
module.defaults = {
	profile = {
		Enable = true,
		AnnounceParty = "PARTY",
		AnnounceRaid = "RAID",
		EnableFormat = false,
		EnableParty = true,
		EnablePet = true,
		EnableRaid = true,
		Format = "!interruptName - !spellLink (!target)",
	},
}
module.optionsName = "Interrupt Announcer"

-- Load options: Creates the options menu for LUI.
function module:LoadOptions()
	local options = {
		Title = LUI:NewHeader("Interrupt Announcer", 1),
		General = {
			name = "General",
			type = "group",
			order = 2,
			args = {
				Info = {
					name = "Info",
					type = "group",
					order = 1,
					guiInline = true,
					args = {
						A = LUI:NewDesc("This module will announce to your group when you interrupt a spell while in a party or raid.", 1),
						B = LUI:NewDesc("The interrupt announcer is disabled while in battlegrounds and WorldPVP (while in battle).", 2),
						C = LUI:NewDesc("A standalone version of this addon is available on curse if prefered:\nhttp://wow.curse.com/downloads/wow-addons/details/hix_interruptannouncer.aspx", 3),
					},
				},
				Settings = {
					name = "Settings",
					type = "group",
					order = 2,
					guiInline = true,
					args = {
						EnableParty = LUI:NewToggle("Enable In Party", nil, 1, db, "EnableParty", dbd),
						EnableRaid = LUI:NewToggle("Enable In Raid", nil, 2, db, "EnableRaid", dbd),
						EnablePet = LUI:NewToggle("Announce Pet Interrupts", nil, 3, db, "EnablePet", dbd),
						EnableFormat = LUI:NewToggle("Enable Custom Format", nil, 4, db, "EnableFormat", dbd),
						AnnouceParty = LUI:NewSelect("Announce Channel For Party", "Which channel to announce interrupts to while in a party", 5, partyChatChannels, nil, db, "AnnounceParty", dbd),
						AnnouceRaid = LUI:NewSelect("Announce Channel For Raid", "Which channel to announce interrupts to while in a raid", 6, raidChatChannels, nil, db, "AnnounceRaid", dbd),
					},
				},
			},
		},
		Format = {
			name = "Announce Format",
			type = "group",
			order = 3,
			disabled = function() return not db.EnableFormat end,
			args = {
				Info = {
					name = "Info",
					type = "group",
					order = 1,
					guiInline = true,
					args = {
						A = LUI:NewDesc("You can customise the interrupt announcers output format.", 1),
						B = LUI:NewDesc("Enter into the box below the format you wish to use. There are select keywords that will be replaced by realtime data before outputing:", 2),
						C = LUI:NewDesc("!player = interruptors name\n!target = targets name\n!interruptSpell = the interrupts spell name\n!interruptLink = the interrupts spell link\n!spellName = the spell name interrupted\n!spellLink = the spell link of the spell interrupted.", 3),
					},
				},
				Format = LUI:NewInput("Announce Format", "Create a string that becomes the interrupt announcers output format. Use keywords to be replaced by realtime data.", 2, db, "Format", dbd, nil, "double"),
			},
		},
	}

	return options
end

-- Initialize module: Called when the addon should intialize its self; this is where we load in database values.
function module:OnInitialize()
	db, dbd = LUI:NewNamespace(self, true)	
end

-- Enable module: Called when addon is enabled.
function module:OnEnable()
	self:Create()
end