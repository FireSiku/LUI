---@type string
local addonName, LUI = ...

---@class LUIAddon : AceAddon, AceEvent-3.0, AceConsole-3.0, AceComm-3.0, AceHook-3.0
---@field db AceDBObject-3.0
LUI = LibStub("AceAddon-3.0"):NewAddon(LUI, addonName, "AceComm-3.0", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")
LUI.L = LibStub("AceLocale-3.0"):GetLocale(addonName)
LUI:SetDefaultModuleLibraries("AceEvent-3.0")

local L = LUI.L
local db

LUI.IsRetail = (_G.WOW_PROJECT_ID == _G.WOW_PROJECT_MAINLINE)
LUI.IsBCC = (_G.WOW_PROJECT_ID == _G.WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
LUI.IsClassic = (_G.WOW_PROJECT_ID == _G.WOW_PROJECT_CLASSIC)

local LIVE_TOC = 120100
local LIVE_BUILD = 69283

local _, patchBuild, _, patchTOC = GetBuildInfo()

if tonumber(patchTOC) > LIVE_TOC then
    LUI.isPTR = true
elseif tonumber(patchBuild) > LIVE_BUILD then
    LUI.isPTR = true
end

--- Core is responsible for handling modules and installation process.
-- Should be first thing loaded.

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

_G["LUI"] = LUI
local Media = LibStub("LibSharedMedia-3.0")
local ACD = LibStub("AceConfigDialog-3.0")

local format, type, select = format, type, select
local InCombatLockdown = _G.InCombatLockdown
local GetAddOnMetadata = C_AddOns.GetAddOnMetadata
local IsAddOnLoaded = C_AddOns.IsAddOnLoaded

-- Constants

local GAME_VERSION_LABEL = _G.GAME_VERSION_LABEL
local GENERAL = _G.GENERAL

-- ####################################################################################################################
-- ##### Install Process ##############################################################################################
-- ####################################################################################################################

--Currently, if not installed, it will automatically install it.

--- Check if LUI is installed.
function LUI:CheckInstall()
	--Check for the big install
    db = self.db.profile
	if not db.Installed.LUI then LUI:OnInstall() end

	for name, module in self:IterateModules() do
		if (module.db and (not db.Installed[name])) then
			--If there is a module OnInstall, call it.
			if module.OnInstall and (type(module.OnInstall) == "function") then
				local installed, err = module.OnInstall()
				if installed then
					db.Installed[name] = true -- Installed correctly
				elseif err then
					-- Print Error, otherwise fails silently.
					LUI:Print(format(L["Core_ModuleInstallFail_Format"],name,err))
				end
			--If not, assume the module has no install required and proceed.
			else
				db.Installed[name] = true
				LUI:Print("Module "..name.." required no installation")
			end
		end
	end

end

function LUI:OnInstall()
    db = self.db.profile
	self.db:SetProfile(format("%s - %s", LUI.playerName, LUI.playerRealm))
	-- Got nothing to put here for now.
	db.Installed.LUI = true
	LUI:Print(L["Core_InstallSucess"])
end

-- ####################################################################################################################
-- ##### Options Menu #################################################################################################
-- ####################################################################################################################
-- If a handler is not listed for a given command, it will use LUI as the default handler.

LUI.cmdList = {
	handler = {
		--["dev"] = LUI,
	},
	commands = {
		["dev"] = "DevCommands",
		["load"] = "LoadProfile",

		-- Legacy Commands
		["debug"] = "Debug",
		["config"] = "Open",
		["install"] = "Configure",
	},
}

function LUI:OpenOptions(forceOld)
	if not forceOld then
		if not C_AddOns.IsAddOnLoaded("LUIOptions") then
			C_AddOns.LoadAddOn("LUIOptions")
		end

		self:NewOpen()
	else
		self:Open()
	end
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

function LUI:DevCommands(cmd, value)
	if cmd == "config" then
		self:OpenOptions(true)
	end
end

-- ####################################################################################################################
-- ##### Module Handling ##############################################################################################
-- ####################################################################################################################

--Function that will create a namespace for each module.
function LUI:RegisterModule(module, dev_skipDB)
	local mName = module:GetName()

	--If a module hasn't been installed yet and should be disabled by default, disable it.
	--Otherwise, modules are enabled by default, and db.modules[name] should be true.
	if module.defaultDisabled and not self.db.profile.Modules[mName] then
		self.db.profile.Modules[mName] = false
	end
	module:SetEnabledState(self.db.profile.Modules[mName])

	if module.defaults and not dev_skipDB then
		module.db = self.db:RegisterNamespace(mName, module.defaults)

	end

	--Add the module to the LUI Profiler
	LUI.Profiler.TraceScope(module, mName, "LUI", 2)

	-- To remove when all modules transitioned to new options menu
	module.registered = true
end
