local script = {}
LibStub("AceEvent-3.0"):Embed(script)
LibStub("AceHook-3.0"):Embed(script)

-- Set text to insert.
script.text = ("|cffffd200LUI Version:|cffffffff %s (%s)\n"):format(GetAddOnMetadata("LUI", "Version"), GetAddOnMetadata("LUI", "X-Curse-Packaged-Version"))

--[[
-- Hook error frame so that error messages regarding LUI contain LUI version and revision info.
script:RegisterEvent("ADDON_LOADED", function(event, addon)
	if not (addon == "Blizzard_DebugTools") then return end

	-- Hook the :SetText function.
	script:RawHook(ScriptErrorsFrameScrollFrameText, "SetText", function(frame, text)
		if strfind(text, "LUI") then
			text = script.text .. text
		end
		script.hooks[frame].SetText(frame, text)
	end, true)
	
	script:UnregisterEvent("ADDON_LOADED")
end)
]]


-- Hook error handler so that error messages regarding LUI contain LUI version and revision info.
function script:ApplyHook()
	-- Get current handler.
	local current = geterrorhandler()

	-- Check hook isn't already in place.
	if current == script.new then return end

	script.old = current
	script.new = function(msg)
		-- Check text hasn't already been added by a previous hook, or that error message is about LUI.
		if not strfind(msg, script.text) and strfind(msg, "LUI") then
			-- Add LUI version text.
			msg = script.text .. msg
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