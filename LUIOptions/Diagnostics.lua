local _, Opt = ...

-- Intentionally outside CreateModuleOptions: this entry has no module toggle
-- and remains visible while recording is off.
Opt.options.args.Diagnostics = {
	name = "LUI DEBUG",
	type = "group",
	order = 4.5,
	args = {
		Description = {
			type = "description", order = 1, fontSize = "medium",
			name = "Collect a troubleshooting report with error details and LUI context. The guided window explains how to start, stop and share a report.",
		},
		Status = {
			type = "description", order = 2,
			name = function()
				return LUI:GetDiagnosticsState().enabled and "|cffffcc66Diagnostics: ACTIVE|r" or "Diagnostics: OFF"
			end,
		},
		Open = {
			type = "execute", order = 3, width = "double", name = "Open LUI DEBUG",
			func = function() LUI:OpenDiagnostics() end,
		},
	},
}
