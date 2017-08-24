--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: GMOTD.lua
	Description: Delays and colors the Guild Message of the Day
]]

-- External references.
local addonname, LUI = ...
local script = LUI:NewScript("GMOTD", "AceEvent-3.0", "AceHook-3.0")

local chatFramesRegistered = {}

function script:ChatFrame_RegisterForMessages(frame, ...)
	for i=1, select("#", ...) do
		if select(i, ...) == "GUILD" then
			-- force Blizzard's code to skip printing the GMOTD
			frame.checkedGMOTD = true

			chatFramesRegistered[frame] = true
		end
	end
end

function script:PLAYER_ENTERING_WORLD(event)
	self:UnregisterAllEvents()
	self:UnhookAll()

	if #chatFramesRegistered == 0 then return end

	local gmotd = GetGuildRosterMOTD()

	if gmotd and gmotd ~= "" then
		for frame in ipairs(chatFramesRegistered) do
			ChatFrame_DisplayGMOTD(frame, gmotd)
		end
	end

	chatFramesRegistered = nil
end

script:SecureHook("ChatFrame_RegisterForMessages")

script:RegisterEvent("PLAYER_ENTERING_WORLD")
