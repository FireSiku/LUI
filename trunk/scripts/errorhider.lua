local addonname, LUI = ...
local script = LUI:NewScript("ErrorHider", "AceEvent-3.0")

function script:ErrorMessageHandler()
	if LUI.db.profile.General.HideErrors then

		-- local function isException(message)
		-- 	local ex = LUI.db.profile.General.ErrorExceptions
		-- 	local message = message

		-- 	if ex == nil or ex == "" then
		-- 		return false
		-- 	else
		-- 		ex = strlower(ex)
		-- 		message = strlower(message)

		-- 		if ex == message or strfind(ex, message..",") or strfind(ex, ","..message) then
		-- 			return true
		-- 		else
		-- 			return false
		-- 		end
		-- 	end
		-- end

		UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE")
		-- self:RegisterEvent("UI_ERROR_MESSAGE", function(event, message)
		-- 	if isException(message) then
		-- 		UIErrorsFrame:AddMessage(message, 1, .1, .1)
		-- 	end
		-- end)
	else
		--self:UnregisterEvent("UI_ERROR_MESSAGE")
		UIErrorsFrame:RegisterEvent("UI_ERROR_MESSAGE")
	end
end

script:RegisterEvent("PLAYER_ENTERING_WORLD", "ErrorMessageHandler")
