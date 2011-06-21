local DEBUG = false
SlashCmdList["YAIAPFIX"] = function()
	DEBUG = not DEBUG
	print("|c00ff0000YAIAP|r: Debug = "..tostring(DEBUG))
end
SLASH_YAIAPFIX1 = "/yaiap"

local old = SendAddonMessage
local function fix(pre, msg, ch, ...)
	local chl = strlower(ch)
	if (chl == "raid" and GetRealNumRaidMembers() == 0) or (chl == "party" and GetRealNumPartyMembers() == 0) or (chl == "guild" and not IsInGuild()) then
		if DEBUG == true then 
			print("|c00ff0000YAIAP|r: ["..strupper(ch).."] prefix = |c0000ff00"..pre.."|r: debugstack = "..debugstack(3, 4, 0))
			old(pre, msg, ch, ...)
		end
		return
	end
	old(pre, msg, ch, ...)
end

SendAddonMessage = fix