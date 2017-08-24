--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: stickychannels.lua
	Description: Enables configuration of stick chat channels
]]

-- External references.
local addonname, LUI = ...
local Chat = LUI:Module("Chat")
local module = Chat:Module("StickyChannels", "AceHook-3.0")

local db, dbd

local channels = {
	GUILD = { desc = "Guild chat", sticky = true },
	OFFICER = { desc = "Officer chat", sticky = true },
	RAID = { desc = "Raid chat", sticky = true },
	PARTY = { desc = "Party chat", sticky = true },
	-- Tested on the PTR - BATTLEGROUND causes errors, needs to be investigated once API changes are all known
	--BATTLEGROUND = { desc = "Battleground chat", sticky = true },
	SAY = { desc = "Say", sticky = true },
	WHISPER = { desc = "Whispers", sticky = true },
	EMOTE = { desc = "Emotes", sticky = false },
	YELL = { desc = "Yells", sticky = false },
	RAID_WARNING = { desc = "Raid warnings", sticky = false },
	BN_WHISPER = { desc = "RealID whispers", sticky = true },
	CHANNEL = { desc = "Custom chat channels", sticky = true },
}

--------------------------------------------------
-- Module Variables
--------------------------------------------------

module.defaults = {
	profile = {
		Enabled = true,
		Channels = {}
	},
}
for k, v in pairs(channels) do
	module.defaults.profile.Channels[k] = v.sticky
end

--------------------------------------------------
-- Load Functions
--------------------------------------------------

function module:LoadOptions()
	local chans = db.Channels
	local funcs = {
		Enabled = function() return not db.Enabled end
	}
	nextOrder = 1
	local options = self:NewGroup("StickyChannels", 4, "generic", "Refresh", {
		Enabled = self:NewToggle("Enable Sticky Channels", nil, 1, true),
		Channels = self:NewGroup("Sticky Channels", 2, true, funcs.Enabled, {}),
	})
	for k, v in pairs(chans) do
		options.args.Channels.args[k] = self:NewToggle(channels[k].desc, "Enable sticky flag for " .. channels[k].desc, nextOrder, true, "normal")
		nextOrder = nextOrder + 1		
	end

	return options
end

function module:Refresh(info, value)
	if type(info) == "table" then
		self:SetDBVar(info, value)
	end

-- Extra checking to make sure we only set the sticky flag on valid channels
	if db.Enabled == true then
		local chans = db.Channels
		for k, v in pairs(chans) do
			if ChatTypeInfo[k] then
				ChatTypeInfo[k].sticky = v and 1 or 0
			end
		end
	else
		for k, v in pairs(channels) do
			if ChatTypeInfo[k] then
				ChatTypeInfo[k].sticky = 0
			end
		end
	end
end

function module:OnInitialize()
	db, dbd = Chat:Namespace(self)
end

module.DBCallback = module.OnInitialize

function module:OnEnable()
	self:Refresh()
end

function module:OnDisable()
end
