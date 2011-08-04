local script = {}
LibStub("AceEvent-3.0"):Embed(script)
LibStub("AceHook-3.0"):Embed(script)

-- Set text to insert.
script.text = ("\nLUI Version: %s (%s)"):format(GetAddOnMetadata("LUI", "Version"), GetAddOnMetadata("LUI", "X-Curse-Packaged-Version"))

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

	-- Check successfull.
	if script.new ~= geterrorhandler() then
		--print("LUI: Could not hook the error handler :(. Someone destroyed the seterrorhandler() function.")
	end
end

-- Apply hook.
script:ApplyHook()

-- Check hook upon entering world; check if another error mod has attempted to hook the error handler, in which case the hook will be updated and applied again.
script:RegisterEvent("PLAYER_ENTERING_WORLD", script.ApplyHook)

--[[
SlashCmdList["LUIERRORTEST"] = function()
	error("LUI Error Test")
end
SLASH_LUIERRORTEST1 = "/luierror"
--]]