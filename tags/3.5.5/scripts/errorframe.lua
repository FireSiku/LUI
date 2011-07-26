local script = {}
LibStub("AceEvent-3.0"):Embed(script)
LibStub("AceHook-3.0"):Embed(script)

-- Hook error frame so that error messages regarding LUI contain LUI version and revision info.
script:RegisterEvent("ADDON_LOADED", function(event, addon)
	if not (addon == "Blizzard_DebugTools") then return end

	-- Hook the :SetText function.
	script:RawHook(ScriptErrorsFrameScrollFrameText, "SetText", function(frame, text)
		if strfind(text, "Interface\\AddOns\\LUI") then
			text = ("|cffffd200LUI Version:|cffffffff "..GetAddOnMetadata("LUI", "Version").." ("..GetAddOnMetadata("LUI", "X-Curse-Packaged-Version")..")\n")..text
		end
		script.hooks[frame].SetText(frame, text)
	end, true)
	
	script:UnregisterEvent("ADDON_LOADED")
end)