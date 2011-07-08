local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")

local function hideErrors()
	local event = CreateFrame("Frame")
	local dummy = function() end

	UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE")
	event.UI_ERROR_MESSAGE = function(self, event, error)
		if(not stuff[error]) then
			UIErrorsFrame:AddMessage(error, 1, .1, .1)
		end
	end
		
	event:RegisterEvent("UI_ERROR_MESSAGE")
end

local enable = CreateFrame("Frame", nil, UIParent)
enable:RegisterEvent("PLAYER_ENTERING_WORLD")

enable:SetScript("OnEvent", function(self)
	if LUI.db.profile.General.HideErrors == true then
		hideErrors()
	end
end)