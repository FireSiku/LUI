--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: stickychannels.lua
	Description: Enables configuration of stick chat channels
]]

-- External references.
---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Chat
local Chat = LUI:GetModule("Chat")
local module = Chat:NewModule("StickyChannels", "LUIDevAPI", "AceHook-3.0")

local db --luacheck:ignore
local ChatTypeInfo = _G.ChatTypeInfo
local originalSticky = {}

module.channels = {
	GUILD = { desc = "Guild chat", sticky = true },
	OFFICER = { desc = "Officer chat", sticky = true },
	RAID = { desc = "Raid chat", sticky = true },
	PARTY = { desc = "Party chat", sticky = true },
	INSTANCE_CHAT = { desc = "Instance chat", sticky = true },
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
for k, v in pairs(module.channels) do
	module.defaults.profile.Channels[k] = v.sticky
end

function module:Refresh(info, value)
	if type(info) == "table" then
		self:SetDBVar(info, value)
	end

	-- Only write sticky flags for chat types Blizzard currently exposes.
	if db.Enabled then
		local chans = db.Channels
		for k, v in pairs(chans) do
			if ChatTypeInfo[k] then
				ChatTypeInfo[k].sticky = v and 1 or 0
			end
		end
	else
		for k, v in pairs(module.channels) do
			if ChatTypeInfo[k] then
				ChatTypeInfo[k].sticky = 0
			end
		end
	end
end

function module:OnInitialize()
	db = Chat:Namespace(self)
	for chatType in pairs(module.channels) do
		if ChatTypeInfo[chatType] and originalSticky[chatType] == nil then
			originalSticky[chatType] = ChatTypeInfo[chatType].sticky
		end
	end
end

module.DBCallback = module.OnInitialize

function module:OnEnable()
	self:Refresh()
end

function module:OnDisable()
	for chatType, sticky in pairs(originalSticky) do
		if ChatTypeInfo[chatType] then
			ChatTypeInfo[chatType].sticky = sticky
		end
	end
end
