local addonname, LUI = ...
local script = LUI:NewScript("ErrorHider", "AceEvent-3.0")

local UIErrorsFrame = _G.UIErrorsFrame

function script:ErrorMessageHandler()
	if LUI.db.profile.General.HideErrors then

		UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE")
	else
		UIErrorsFrame:RegisterEvent("UI_ERROR_MESSAGE")
	end
end

script:RegisterEvent("PLAYER_ENTERING_WORLD", "ErrorMessageHandler")
