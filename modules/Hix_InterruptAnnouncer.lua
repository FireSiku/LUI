--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: hix_interruptannouncer.lua
	Description: Accounces to Party/Raid when the player interrupts a spell; giving the info.
	Version....: 1.7
	Rev Date...: 18/06/2011 [dd/mm/yyyy]
	Author.....: Hix [Trollbane] <Lingering>
	Options by.: Zista [Fizzcrank] <Vendetta>
	
	Notes:
		Announces while in a raid or party. Disabled while in battlegrounds and WorldPVP zones (while in battle)
]]

-- Local includes/definitions
local version = "1.7"
local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local module = LUI:NewModule("Hix: InterruptAnnouncer", "AceHook-3.0")
local db

local partyChatChannels = {'SAY', 'YELL', 'PARTY'}
local raidChatChannels = {'SAY', 'YELL', 'PARTY', 'RAID', 'RAID_WARNING'}

-- Create module function
function module:SetInterruptAnnouncer()
	if not db.Hix_InterruptAnnouncer.Enable then return end
	
	-- Create a frame to work with
	local IA = CreateFrame("frame")

	-- Set event script
	IA:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)

	-- Register events
	IA:RegisterEvent("PARTY_MEMBERS_CHANGED")
	IA:RegisterEvent("UNIT_PET")
	
	-- Locale variables for module
	IA.channel = nil
	IA.GUID = nil
	IA.lastTime = nil
	IA.lastInterrupt = nil
	IA.petGUID = nil
	
	-- Combat log event unfiltered event function
	function IA:COMBAT_LOG_EVENT_UNFILTERED(timeStamp, event, _, sGUID, _,_,_, dName, _,_, spellName, _, spellID)
		-- Filter combat events.
		if (sGUID ~= self.GUID) and (sGUID ~= self.petGUID) then return end
		if (event ~= "SPELL_INTERRUPT") then return end
		if (timeStamp == self.lastTime) and (spellID == self.lastInterrupt) then return end
		
		-- Update variables.
		self.lastTime, self.lastInterrupt = timeStamp, spellID

		-- Send chat message.
		SendChatMessage(format("%s - %s (%s)", spellName, GetSpellLink(spellID), dName), self.channel)
	end

	-- Party members changed event function
	function IA:PARTY_MEMBERS_CHANGED()
		-- Check if announcer should be enabled/disabled
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
			if db.Hix_InterruptAnnouncer.EnableRaid then
				if (db.Hix_InterruptAnnouncer.AnnounceRaid == "RAID_WARNING") and (not(IsRaidLeader())) and (not(IsRaidOfficer())) then
					self.channel = "RAID"
				else
					self.channel = db.Hix_InterruptAnnouncer.AnnounceRaid
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
			if db.Hix_InterruptAnnouncer.EnableParty then
				self.channel = db.Hix_InterruptAnnouncer.AnnounceParty
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
		if db.Hix_InterruptAnnouncer.EnablePet then self.petGUID = UnitGUID("pet") end
		
		-- Register combat events.
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:RegisterEvent("UNIT_PET")
	end

	-- Pet changed event function
	function IA:UNIT_PET(unit)
		if unit ~= "player" then return end
		if not self.GUID then return end
		if not db.Hix_InterruptAnnouncer.EnablePet then return end
	
		-- Update pet GUID.
		self.petGUID = UnitGUID("pet")
	end	
end

-- Defaults for the module
local defaults = {
	Hix_InterruptAnnouncer = {
		Enable = true,
		EnableParty = true,
		EnableRaid = true,
		EnablePet = true,
		AnnounceParty = "PARTY",
		AnnounceRaid = "RAID",
	},
}

-- Load options: Creates the options menu for LUI
function module:LoadOptions()
	local options = {
		Hix_InterruptAnnouncer = {
			name = "Interrupt Announcer",
			type = "group",
			disabled = function() return not db.Hix_InterruptAnnouncer.Enable end,
			childGroups = "tab",
			args = {
				General = {
					name = "General",
					type = "group",
					order = 1,
					args = {
						Title = {
							type = "header",
							order = 1,
							name = "Hix: Interrupt Announcer Module v" ..  version,
						},
						Info = {
							name = "Info",
							type = "group",
							order = 2,
							guiInline = true,
							args = {
								Description = {
									name = "This module will announce to your group when you interrupt a spell while in a party or raid.\n\nThe announcer is disabled while in battlegrounds and WorldPVP (while in battle).\n\nA standalone version of this addon is available on curse if prefered:\nhttp://wow.curse.com/downloads/wow-addons/details/hix_interruptannouncer.aspx",
									type = "description",
									order = 1,
								},
							},
						},
						Settings = {
							name = "Settings",
							type = "group",
							order = 3,
							guiInline = true,
							args = {
								EnableParty = {
									name = "Enable in Party",
									desc = "Weather or not to announce interrupts while in a party",
									disabled = function() return not db.Hix_InterruptAnnouncer.Enable end,
									type = "toggle",
									get = function() return db.Hix_InterruptAnnouncer.EnableParty end,
									set = function(self) db.Hix_InterruptAnnouncer.EnableParty = not db.Hix_InterruptAnnouncer.EnableParty; end,
									order = 1,
								},
								EnableRaid = {
									name = "Enable in Raid",
									desc = "Weather or not to announce interrupts while in a raid group",
									disabled = function() return not db.Hix_InterruptAnnouncer.Enable end,
									type = "toggle",
									get = function() return db.Hix_InterruptAnnouncer.EnableRaid end,
									set = function(self) db.Hix_InterruptAnnouncer.EnableRaid = not db.Hix_InterruptAnnouncer.EnableRaid; end,
									order = 2,
								},
								AnnouceParty = {
									name = "Announce channel for Party",
									desc = "Which channel to announce interrupts to while in a party",
									disabled = function() return not db.Hix_InterruptAnnouncer.EnableParty end,
									type = "select",
									values = partyChatChannels,
									get = function()
										for k, v in pairs(partyChatChannels) do
											if db.Hix_InterruptAnnouncer.AnnounceParty == v then
												return k
											end
										end
									end,
									set = function(self, channel) db.Hix_InterruptAnnouncer.AnnounceParty = partyChatChannels[channel]; end,
									order = 3,
								},
								AnnouceRaid = {
									name = "Announce channel for Raid",
									desc = "Which channel to announce interrupts to while in a raid group\n\nRAID_WARNING will default to RAID if you aren't promoted",
									disabled = function() return not db.Hix_InterruptAnnouncer.EnableRaid end,
									type = "select",
									values = raidChatChannels,
									get = function()
										for k, v in pairs(raidChatChannels) do
											if db.Hix_InterruptAnnouncer.AnnounceRaid == v then
												return k
											end
										end
									end,
									set = function(self, channel) db.Hix_InterruptAnnouncer.AnnounceRaid = raidChatChannels[channel]; end,
									order = 4,
								},
								EnablePet = {
									name = "Annouce pet interrupts",
									desc = "Announce interrupts done by your pet",
									disabled = function() return not db.Hix_InterruptAnnouncer.Enable end,
									type = "toggle",
									get = function() return db.Hix_InterruptAnnouncer.EnablePet end,
									set = function(self) db.Hix_InterruptAnnouncer.EnablePet = not db.Hix_InterruptAnnouncer.EnablePet; end,
									order = 5,
								},
							},
						},
					},
				},
			},
		},
	}
	return options
end

-- Initialize module: Called when the addon should intialize its' self; this is where we load in database values
function module:OnInitialize()
	LUI:MergeDefaults(LUI.db.defaults.profile, defaults)
	LUI:RefreshDefaults()
	LUI:Refresh()
	
	self.db = LUI.db.profile
	db = self.db
	
	LUI:RegisterModule(self, "Hix_InterruptAnnouncer")
end

-- Enable module: Called when addon is enabled
function module:OnEnable()
	self:SetInterruptAnnouncer()
end