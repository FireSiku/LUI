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
local geterrorhandler, seterrorhandler = geterrorhandler, seterrorhandler

----------------------------------------------------------------------
-- Initialize BugCatcher
----------------------------------------------------------------------

local BugCatcher = LibStub("AceEvent-3.0"):Embed( {} )

local L = LUI.L

----------------------------------------------------------------------
-- Local Variables
----------------------------------------------------------------------

local errorHandler

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

---	formatError(msg)
--	Notes.....: Adds Version and Revision numbers to error strings relating to LUI
--	Parameters:
--		(string) msg: Message string to have Version and Revision number added to
local function formatError(msg)
	if not (msg and strfind(msg, "LUI\\")) then
		errorHandler(msg)
		return
	end

	-- Strip out unneeded folder data
	msg = gsub(msg, "Interface\\", "")
	msg = gsub(msg, "AddOns\\", "")
	msg = gsub(msg, "%.%.%.[^\\]+", "")
	msg = gsub(msg, "^[\\]?LUI", text)

	-- Replace Interface\AddOns\LUI with Version number
	errorHandler(msg)
end

----------------------------------------------------------------------
-- Event Functions
----------------------------------------------------------------------

function BugCatcher:PLAYER_ENTERING_WORLD()
	-- Get current handler
	local current = geterrorhandler()

	-- Check that our function isn't the current handler
	if current == formatError then return end

	-- Save the handler for use later
	errorHandler = current

	-- Set our function as the handler
	seterrorhandler(formatError)

	--@debug@
	-- Check if someone broke the seterrorhandler() function
	if geterrorhandler() ~= formatError then
		LUI:Print("Could not set the error handler :(\nSomeone destroyed the seterrorhandler() function.")
	end
	--@end-debug@
end

-- Set the error handler now in case any errors occur before PEW
BugCatcher:PLAYER_ENTERING_WORLD()

-- Set it again upon PEW in case another addon changed the handler
BugCatcher:RegisterEvent("PLAYER_ENTERING_WORLD")

--[[
-- Register slash command for testing (/lui error)
LUI.chatcommands.error = function()
-- Hide the ChatEditBox, the error will stop the function that normally does this from running
	ChatEdit_OnEscapePressed(ChatEdit_GetActiveWindow())

	-- Send a test error,
	error("LUI Error Test")
end
--]]