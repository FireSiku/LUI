-- Hook error frame so that error messages contain LUI version and revision info.
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(self, event, addon)
	if not (addon == "Blizzard_DebugTools") then return end

	-- Hook the :SetText function.
	local old = ScriptErrorsFrameScrollFrameText.SetText
	ScriptErrorsFrameScrollFrameText.SetText = function (self, text)
		local new = ("|cffffd200LUI Version:|cffffffff "..GetAddOnMetadata("LUI", "Version").." ("..GetAddOnMetadata("LUI", "X-Curse-Packaged-Version")..")\n")..text
		old(self, new)
	end
end)