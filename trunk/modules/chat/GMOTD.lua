--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: GMOTD.lua
	Description: Delays and colors the Guild Message of the Day
]]

-- External references.
local addonname, LUI = ...
local script = LUI:NewScript("GMOTD", "AceEvent-3.0", "AceHook-3.0")

local gmotd

function script:ChatFrame_DisplayGMOTD(frame, msg)
	gmotd = msg
end

function script:PLAYER_ENTERING_WORLD(event)
	self:UnregisterEvent(event)
	self:UnhookAll()

	if gmotd then
		ChatFrame_DisplayGMOTD(ChatFrame1, gmotd)
		gmotd = nil
	end
end

script:RawHook("ChatFrame_DisplayGMOTD", true)

script:RegisterEvent("PLAYER_ENTERING_WORLD")