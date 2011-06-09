--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: hix_interruptannouncer.lua
	Description: Accounces to Party/Raid when the player interrupts a spell; giving the info.
	Version....: 1.6
	Rev Date...: 20/11/2010 [dd/mm/yyyy]
	Author.....: Hix [Trollbane] <Lingering>
	Updated by.: Zista [Fizzcrank] <Vendetta>
	
	Notes:
		Announces while in a raid or party. Disabled while in battlegrounds and WorldPVP zones (while in battle)
]]

-- Local includes/definitions
local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local module = LUI:NewModule("Hix: InterruptAnnouncer", "AceHook-3.0")
local db

local version = "1.5"
local partyChatChannels = {'SAY', 'YELL', 'PARTY'}
local raidChatChannels = {'SAY', 'YELL', 'PARTY', 'RAID', 'RAID_WARNING'}

-- Create module function
function module:SetInterruptAnnouncer()
	if (db.Hix_InterruptAnnouncer.Enable ~= true) then return end
	
	-- Create a frame to work with
	local IA = CreateFrame("frame")
	-- Set event script
	IA:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
	-- Register events
	IA:RegisterEvent("PARTY_MEMBERS_CHANGED")
	IA:RegisterEvent("UNIT_PET")
	
	-- Locale variables for module
	IA.playerGUID = nil
	IA.petGUID = nil
	IA.lastTime = nil
	IA.lastInterrupt = nil
	
	-- Pet changed event function
	function IA:UNIT_PET()
		if self.playerGUID then
			if self.petGUID ~= UnitGUID("pet") then
				self.petGUID = UnitGUID("pet")
			end
		end
	end
	
	-- Party members changed event function
	function IA:PARTY_MEMBERS_CHANGED()
		-- Check if announcer should be enabled/disabled
		local _, instanceType = IsInInstance()
		local inWG = (GetRealZoneText() == "Wintergrasp") and (GetWintergraspWaitTime() == nil)
		if (instanceType == "pvp") or inWG or ((GetNumRaidMembers() == 0) and (GetNumPartyMembers() == 0)) then
			-- Disable announcer
			self.playerGUID = nil
			self.petGUID = nil
			self.lastTime = nil
			self.lastInterrupt = nil
			self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
			return
		end
		
		-- If already active return
		if self.playerGUID then
			if self.petGUID ~= UnitGUID("pet") then
				self.petGUID = UnitGUID("pet")
			end
			return
		end
		
		-- Enable the announcer
		self.playerGUID = UnitGUID("player")
		self.petGUID = UnitGUID("pet")
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	end
	
	-- Combat log event unfiltered event function
	function IA:COMBAT_LOG_EVENT_UNFILTERED(timeStamp, event, _, sGUID, _,_,_, dName, _, spellID, spellName, _, eSpellID, eSpellName)
		-- Check if log is about player, is an intterupt, and is not a double log
		if sGUID ~= self.playerGUID then
			if db.Hix_InterruptAnnouncer.EnablePet then
				if sGUID ~= self.petGUID then return end
			else return end
		end
		if event ~= "SPELL_INTERRUPT" then return end
		if (timeStamp == self.lastTime) and (spellName == self.lastInterrupt) then return end
		
		-- Update locals
		self.lastTime, self.lastInterrupt = timeStamp, spellName
		
		-- Create and send message
		local msg = db.Hix_InterruptAnnouncer.AnnounceText
		if string.find(msg, "!target") ~= nil then
			msg = string.gsub(msg, "!target", dName)
		end
		if string.find(msg, "!spell_link") ~= nil then
			msg = string.gsub(msg, "!spell_link", GetSpellLink(eSpellID))
		end
		if string.find(msg, "!spell") ~= nil then
			msg = string.gsub(msg, "!spell", eSpellName)
		end
		if string.find(msg, "!int_link") ~= nil then
			msg = string.gsub(msg, "!int_link", GetSpellLink(spellID))
		end
		if string.find(msg, "!int") ~= nil then
			msg = string.gsub(msg, "!int", spellName)
		end
		if GetNumRaidMembers() > 0 then
			if db.Hix_InterruptAnnouncer.EnableRaid then
				if (db.Hix_InterruptAnnouncer.AnnounceRaid == "RAID_WARNING") and (not(IsRaidLeader())) and (not(IsRaidOfficer())) then
					SendChatMessage(msg, "RAID")
				else
					SendChatMessage(msg, db.Hix_InterruptAnnouncer.AnnounceRaid)
				end
			end
		else
			if db.Hix_InterruptAnnouncer.EnableParty then
				SendChatMessage(msg, db.Hix_InterruptAnnouncer.AnnounceParty)
			end
		end		
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
		AnnounceText = "!int_link - !spell_link (!target)",
	},
}

-- Load options: Creates the options menu for LUI
function module:LoadOptions()
	local options = {
		Hix_InterruptAnnouncer = {
			name = "Interrupt Announcer",
			type = "group",
			order = 60,
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
							name = "Hix Interrupt Announcer Module v" ..  version,
						},
						Info = {
							name = "Info",
							type = "group",
							order = 2,
							guiInline = true,
							args = {
								Description = {
									name = "This module will announce to your group when you interrupt a spell while in a party or raid.\nDisabled while in battlegrounds and Wintergrasp (while in battle)",
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
								Space = {
									type = "description",
									order = 6,
									name = "\n",
								},
								AnnounceTextHeader = {
									name = "Set the format of the announcement of your interupts:",
									type = "description",
									order = 7,
								},
								AnnounceTextOptions = {
									name = "Formatting Commands:",
									type = "group",
									order = 8,
									guiInline = true,
									args = {
										IntName = {
											name = "!int",
											type = "description",
											order = 1,
										},
										IntNameDesc = {
											name = "     Name the ability used to interupt the spell",
											type = "description",
											order = 1.5,
										},
										IntLink = {
											name = "!int_link",
											type = "description",
											order = 2,
										},
										IntLinkDesc = {
											name = "     Link the ability used to interupt the spell",
											type = "description",
											order = 2.5,
										},
										SpellName = {
											name = "!spell",
											type = "description",
											order = 3,
										},
										SpellDesc = {
											name = "     Name the spell that was interupted",
											type = "description",
											order = 3.5,
										},
										SpellLink = {
											name = "!spell_link",
											type = "description",
											order = 4,
										},
										SpellLinkDesc = {
											name = "     Link the spell that was interupted",
											type = "description",
											order = 4.5,
										},
										Target = {
											name = "!target",
											type = "description",
											order = 5,
										},
										TargetDesc = {
											name = "     Name the caster of the spell that was interupted",
											type = "description",
											order = 5.5,
										},
									},
								},
								AnnounceText = {
									name = "Announce Format",
									desc = "Set the format of the interrupt announcements",
									disabled = function() return not db.Hix_InterruptAnnouncer.Enable end,
									type = "input",
									width = "full",
									get = function() return db.Hix_InterruptAnnouncer.AnnounceText end,
									set = function(self, text) db.Hix_InterruptAnnouncer.AnnounceText = text; end,
									order = 9,
								},
							},
						},
						Example = {
							name = "Example",
							type = "group",
							order = 4,
							guiInline = true,
							args = {
								Text = {
									name = function()
										local spellName, spellID, eSpellName, eSpellID, dName = "Kick", "1766", "Shadow Bolt", "61558", "Dark Necromancer"
										local msg = db.Hix_InterruptAnnouncer.AnnounceText
										if string.find(msg, "!target") ~= nil then
											msg = string.gsub(msg, "!target", dName)
										end
										if string.find(msg, "!spell_link") ~= nil then
											msg = string.gsub(msg, "!spell_link", GetSpellLink(eSpellID))
										end
										if string.find(msg, "!spell") ~= nil then
											msg = string.gsub(msg, "!spell", eSpellName)
										end
										if string.find(msg, "!int_link") ~= nil then
											msg = string.gsub(msg, "!int_link", GetSpellLink(spellID))
										end
										if string.find(msg, "!int") ~= nil then
											msg = string.gsub(msg, "!int", spellName)
										end
										return msg
									end,
									type = "description",
									order = 1,
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