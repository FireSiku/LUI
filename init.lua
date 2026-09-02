---@type string
local addonName, LUI = ...

---@class LUIAddon : AceAddon, AceEvent-3.0, AceConsole-3.0, AceComm-3.0, AceHook-3.0
---@field db AceDBObject-3.0
LUI = LibStub("AceAddon-3.0"):NewAddon(LUI, addonName, "AceComm-3.0", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")
LUI.L = LibStub("AceLocale-3.0"):GetLocale(addonName)
LUI:SetDefaultModuleLibraries("AceEvent-3.0")

LUI.IsRetail = (_G.WOW_PROJECT_ID == _G.WOW_PROJECT_MAINLINE)

_G["LUI"] = LUI

-- ####################################################################################################################
-- ##### Options Menu #################################################################################################
-- ####################################################################################################################
-- If a handler is not listed for a given command, it will use LUI as the default handler.

LUI.cmdList = {
	handler = {},
	commands = {
		["debug"] = "Debug",
		["config"] = "OpenOptions",
	},
}

function LUI:OpenOptions()
	if not C_AddOns.IsAddOnLoaded("LUIOptions") then
		C_AddOns.LoadAddOn("LUIOptions")
	end

	self:NewOpen()
end

function LUI:ChatCommand(input)
	if not input or input:trim() == "" then
		self:OpenOptions()
	else
		input = input:lower() -- avoid capitalization
		local mod = self:GetArgs(input)
		local value = string.gsub(input, mod, ""):trim()
		local cmd = mod and self.cmdList.commands[mod]
		
		if cmd then
			-- If no handler is defined, defaults to LUI as the handler
			local handler = self.cmdList.handler[mod] or self
			
			-- Call the function that will handle the command.
			if handler[cmd] then
				handler[cmd](handler, value)
			else
				LUI:Print("Invalid command:", cmd)
			end
		-- If there are no function associated to the chat command.
		elseif mod then
			LUI:Print("Unknown command:", mod)
		end
	end
end

-- ####################################################################################################################
-- ##### Module Handling ##############################################################################################
-- ####################################################################################################################

--Function that will create a namespace for each module.
function LUI:RegisterModule(module, dev_skipDB)
	local mName = module:GetName()

	module:SetEnabledState(self.db.profile.Modules[mName])

	if module.defaults and not dev_skipDB then
		module.db = self.db:RegisterNamespace(mName, module.defaults)

	end

	--Add the module to the LUI Profiler
	LUI.Profiler.TraceScope(module, mName, "LUI", 2)

	module.registered = true
end
