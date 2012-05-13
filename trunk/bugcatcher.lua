---	Name...........: BugCatcher
--	Description....: Adds LUI Version and Revision numbers to lua errors relating to LUI

-- These AddOns replace the seterrorhandler function, bail out if any of them are enabled
if IsAddOnLoaded("!BugGrabber") or IsAddOnLoaded("!Swatter") or IsAddOnLoaded("!ImprovedErrorFrame") then return end

local addonname, LUI = ...

----------------------------------------------------------------------
-- Localized API
----------------------------------------------------------------------

local _G = _G
local format, strfind, gsub = string.format, string.find, string.gsub

----------------------------------------------------------------------
-- Initialize BugCatcher
----------------------------------------------------------------------

local BugCatcher = LibStub("AceHook-3.0"):Embed( {} )

local L = LUI.L

----------------------------------------------------------------------
-- Local Variables
----------------------------------------------------------------------

local text
do -- Create format string
	local version, revision = GetAddOnMetadata(addonname, "Version"), GetAddOnMetadata(addonname, "X-Curse-Packaged-Version") or "Working Copy"
	if version == revision then
		text = format("LUI %s", version)
	else
		text = format("LUI %s (%s)", version, revision)
	end
end

----------------------------------------------------------------------
-- Local Functions
----------------------------------------------------------------------

---	formatError(message)
--	Notes.....: Adds Version and Revision numbers to error strings relating to LUI
--	Parameters:
--		(string) message: Message string to have Version and Revision number added to
local function formatError(message)
	if message and strfind(message, "LUI\\") then
		-- Strip out unneeded folder data
		message = gsub(message, "Interface\\", "")
		message = gsub(message, "AddOns\\", "")
		message = gsub(message, "%.%.%.[^\\]+", "")
		message = gsub(message, "^[\\]?LUI", text)
	end

	return message
end

----------------------------------------------------------------------
-- Hook Functions
----------------------------------------------------------------------

function BugCatcher:ScriptErrorsFrame_OnError(message, ...)
	DEBUGLOCALS_LEVEL = 6

	self.hooks.ScriptErrorsFrame_OnError(formatError(message), ...)
end

LoadAddOn("Blizzard_DebugTools")
BugCatcher:RawHook("ScriptErrorsFrame_OnError", true)

-- Register slash command for testing (/luierror)
--@debug@
SLASH_LUIERROR1 = "/luierror"
SlashCmdList.LUIERROR = function()
	-- Hide the ChatEditBox, the error will stop the function that normally does this from running
	ChatEdit_OnEscapePressed(ChatEdit_GetActiveWindow())

	-- Send a test error,
	error("LUI Error Test")
end
--@end-debug@