local addonname, addon = ...

local script = {}
LibStub("AceAddon-3.0"):EmbedLibraries(script, "AceEvent-3.0")

-- Set text to insert.
local version, revision = GetAddOnMetadata(addonname, "Version"), GetAddOnMetadata(addonname, "X-Curse-Packaged-Version")
script.text = format("\nLUI Version: %s", version) .. (version ~= revision and format(" (%s)", revision) or "")

-- Hook error handler so that error messages regarding LUI contain LUI version and revision info.
function script:ApplyHook()
	-- Get current handler.
	local current = geterrorhandler()

	-- Check hook isn't already in place.
	if current == script.new then return end

	script.old = current
	script.new = script.new or function(msg)
	-- Check text hasn't already been added by a previous hook, or that error message is about LUI.
		if not strfind(msg, script.text) and strfind(msg, "LUI") then
			-- Add LUI version text.
			msg = msg .. script.text
		end

		-- Pass message to old handler.
		script.old(msg)
	end

	-- Hook error handler.
	seterrorhandler(script.new)

	-- Check successful.
	if script.new ~= geterrorhandler() then
		--print("LUI: Could not hook the error handler :(. Someone destroyed the seterrorhandler() function.")
	end
end

-- Apply hook.
script:ApplyHook()

-- Check hook upon entering world; check if another error mod has attempted to hook the error handler, in which case the hook will be updated and applied again.
script:RegisterEvent("PLAYER_ENTERING_WORLD", "ApplyHook")

--[[
SlashCmdList["LUIERRORTEST"] = function()
	error("LUI Error Test")
end
SLASH_LUIERRORTEST1 = "/luierror"
--]]