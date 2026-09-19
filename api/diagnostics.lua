-- Always-available launcher. Only the on/off and return-screen flags live in
-- LUIDB; the separate load-on-demand addon owns every diagnostic record.
local _, LUI = ...
local ADDON = "LUIDiagnostics"

function LUI:GetDiagnosticsState()
	local state = self.db.global.Diagnostics
	if type(state) ~= "table" then
		state = {enabled = false}
		self.db.global.Diagnostics = state
	end
	return state
end

function LUI:LoadDiagnostics(automaticResume)
	-- Resuming a previously authorized recording only loads passive listeners.
	-- User-initiated opening, starting and stopping remain blocked in combat.
	if not automaticResume and InCombatLockdown() then
		self:Print("LUI DEBUG: Please wait until you are out of combat.")
		return
	end
	if not C_AddOns.IsAddOnLoaded(ADDON) then
		local loaded, reason = C_AddOns.LoadAddOn(ADDON)
		if not loaded then
			self:Print("LUI DEBUG: Could not load LUIDiagnostics (" .. tostring(reason) .. "). Check that its folder is installed beside LUI and enabled in the AddOns list.")
			return
		end
	end
	return _G.LUIDiagnostics
end

function LUI:OpenDiagnostics()
	local diagnostics = self:LoadDiagnostics()
	if diagnostics then diagnostics:OpenWindow() end
end

function LUI:ActionBarDiagnostics(command)
	command = (command or ""):lower():match("^%s*(.-)%s*$")
	local diagnostics = self:LoadDiagnostics(command == "")
	if diagnostics then
		diagnostics:Initialize()
		diagnostics:ActionBarCommand(command)
	end
end

function LUI:InitializeDiagnostics()
	self:RegisterChatCommand("luidebug", "OpenDiagnostics")
	self:RegisterChatCommand("luidrag", "ActionBarDiagnostics")
	self.cmdList.commands.diagnostics = "OpenDiagnostics"
	local state = self:GetDiagnosticsState()
	if state.enabled or state.showAfterReload then
		local diagnostics = self:LoadDiagnostics(true)
		if diagnostics then diagnostics:Initialize() end
	end
end
