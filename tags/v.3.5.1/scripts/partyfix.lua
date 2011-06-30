-- Create slash command to enable debug mode.
local DEBUG = false
SlashCmdList["YAIAPFIX"] = function()
	DEBUG = not DEBUG
	print("|c00ff0000YAIAP|r: Debug = "..tostring(DEBUG))
end
SLASH_YAIAPFIX1 = "/yaiap"

-- Hook SendAddonMessage.
local old = SendAddonMessage
local function fix(pre, msg, ch, ...)
	-- Filter messages with oversized parameters.
	if (type(pre) == "string" and #pre > 15) or (type(msg) == "string" and #msg > 250) then
		if DEBUG then
			-- Print message error info.
			print("|c00ff0000YAIAP|r: ["..strupper(ch).."] prefix = "..(#pre)..", message = "..(#msg)..": debugstack = "..debugstack(3, 4, 0))

			-- Pipe errored message to SendAddonMessage to create an error for debug.
			old(pre, msg, ch, ...)
		end
		return
	end

	-- Filter messages en route to a channel not accessible.
	local chl = strlower(ch)
	if (chl == "raid" and GetRealNumRaidMembers() == 0) or (chl == "party" and GetRealNumPartyMembers() == 0) or (chl == "guild" and not IsInGuild()) then
		if DEBUG then
			-- Print message error info.
			print("|c00ff0000YAIAP|r: ["..strupper(ch).."] prefix = |c0000ff00"..pre.."|r: debugstack = "..debugstack(3, 4, 0))

			-- Pipe errored message to SendAddonMessage to create an erorr for debug.
			old(pre, msg, ch, ...)
		end
		return
	end

	-- Pipe accepted message to SendAddonMessage.
	old(pre, msg, ch, ...)
end

SendAddonMessage = fix