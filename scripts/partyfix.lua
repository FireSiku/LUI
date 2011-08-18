local addonname, LUI = ...
local script = LUI:NewScript("YAIAP", "AceHook-3.0")

-- Create slash command to enable debug mode.
local DEBUG = false
SlashCmdList["LUIYAIAP"] = function()
	DEBUG = not DEBUG
	print("|c0090ffffLUI|r: YAIAP Debug "..(DEBUG and "Enabled" or "Disabled"))
end
SLASH_LUIYAIAP1 = "/yaiap"

-- Hook SendAddonMessage.
script:RawHook("SendAddonMessage", function(prefix, text, chatType, ...)
	---[[	Removed since causing more issues than solved. I may be a better fix to shorten prefix to 16 characters rather than cause error.
	--		Re-Added with prefix substring fix.
	
	-- Filter messages with oversized parameters.
	if type(prefix) == "string" and #prefix > 16 then
		if DEBUG then
			-- Print message error info.
			print("|c0090ffffLUI|r: YAIAP: ["..strupper(chatType).."] prefix is to large ("..#prefix.."): debugstack = "..debugstack(3, 4, 0))

			-- Pipe errored message to SendAddonMessage to create an error for debug.
			script.hooks.SendAddonMessage(prefix, text, chatType, ...)
		end
		
		-- Srink prefix to 16 characters rather than skipping send.
		--return
		prefix = prefix:sub(1, 16)
	end
	--]]

	-- Filter messages en route to a channel not accessible.
	local chl = strlower(chatType)
	if (chl == "raid" and GetRealNumRaidMembers() == 0) or (chl == "party" and GetRealNumPartyMembers() == 0) or (chl == "guild" and not IsInGuild()) then
		if DEBUG then
			-- Print message error info.
			print("|c0090ffffLUI|r: YAIAP: ["..strupper(chatType).."] prefix = |c0000ff00"..prefix.."|r: debugstack = "..debugstack(3, 4, 0))

			-- Pipe errored message to SendAddonMessage to create an erorr for debug.
			script.hooks.SendAddonMessage(prefix, text, chatType, ...)
		end
		return
	end

	-- Pipe accepted message to SendAddonMessage.
	script.hooks.SendAddonMessage(prefix, text, chatType, ...)
end, true)