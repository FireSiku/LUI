-- -- Register the Reload UI Slash Command before anything can fail
-- SLASH_RELOADUI1 = "/rl"
-- SlashCmdList.RELOADUI = ReloadUI

---@type string
local addonName, LUI = ...

---@class LUIAddon : AceAddon, AceEvent-3.0, AceConsole-3.0
LUI = LibStub("AceAddon-3.0"):NewAddon(LUI, addonName, "AceComm-3.0", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")
---@type table @ Localization Table
LUI.L = LibStub("AceLocale-3.0"):GetLocale(addonName)
LUI:SetDefaultModuleLibraries("AceEvent-3.0")

local L = LUI.L
local db

LUI.Rev = "2210"
LUI.IsRetail = (_G.WOW_PROJECT_ID == _G.WOW_PROJECT_MAINLINE)
LUI.IsBCC = (_G.WOW_PROJECT_ID == _G.WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
LUI.IsClassic = (_G.WOW_PROJECT_ID == _G.WOW_PROJECT_CLASSIC)

local LIVE_TOC = 90207
local LIVE_BUILD = 45338
local BETA_TOC = 100000

local _, patchBuild, _, patchTOC = GetBuildInfo()

if tonumber(patchTOC) > BETA_TOC then
    LUI.IsBeta = true
elseif tonumber(patchTOC) > LIVE_TOC then
    LUI.isPTR = true
elseif tonumber(patchBuild) > LIVE_BUILD then
    LUI.isPTR = true
end

--- Core is responsible for handling modules and installation process.
-- Should be first thing loaded.

-- ####################################################################################################################
-- ##### Setup and Locals #############################################################################################
-- ####################################################################################################################

--For Testing Purposes Only
_G["LUI"] = LUI
local Media = LibStub("LibSharedMedia-3.0")
local ACD = LibStub("AceConfigDialog-3.0")

local format, type, select = format, type, select
local InCombatLockdown = _G.InCombatLockdown
local GetAddOnMetadata = _G.GetAddOnMetadata
local IsAddOnLoaded = _G.IsAddOnLoaded

-- Constants

local GAME_VERSION_LABEL = _G.GAME_VERSION_LABEL
local GENERAL = _G.GENERAL

-- ####################################################################################################################
-- ##### Default Settings #############################################################################################
-- ####################################################################################################################

-- LUI.defaults = {
-- 	profile = {
-- 		General = {
-- 			IsConfigured = false, -- Currently unused, will be when Install process is done
-- 			BlizzFrameScale = 1, -- Not sure if we'll use that, or if it's going to be part of scripts.
-- 			ModuleMessages = true,
-- 			MasterFont = "NotoSans-SCB",
-- 			MasterFlag = "OUTLINE",
-- 		},
-- 		Snippets = {
-- 		-- Siku TODO note: Snippet Engine. Dynamic creation and editing of LUIv3's Scripts.
-- 		},
-- 		Modules = {
-- 			["*"] = true,
-- 		},
-- 		Installed = {
-- 			["*"] = false,
-- 		},
-- 		Fonts = {
-- 			Master = { Name = "NotoSans-SCB", Size = 12, Flag = "OUTLINE", },
-- 		},
-- 	},
-- }

-- ####################################################################################################################
-- ##### Loading Media ################################################################################################
-- ####################################################################################################################

-- REGISTER FONTS
-- Media:Register("font", "vibroceb", [[Interface\Addons\LUI4\media\fonts\vibroceb.ttf]])
-- Media:Register("font", "Prototype", [[Interface\Addons\LUI4\media\fonts\prototype.ttf]])
-- Media:Register("font", "NotoSans-SCB", [[Interface\AddOns\LUI4\media\fonts\NotoSans-SemiCondensedBold.ttf]])

-- -- REGISTER BORDERS
-- Media:Register("border", "glow", [[Interface\Addons\LUI4\media\borders\glow.tga]])
-- Media:Register("border", "Stripped", [[Interface\Addons\LUI4\media\borders\Stripped.tga]])
-- Media:Register("border", "Stripped_hard", [[Interface\Addons\LUI4\media\borders\Stripped_hard.tga]])
-- Media:Register("border", "Stripped_medium", [[Interface\Addons\LUI4\media\borders\Stripped_medium.tga]])

-- -- REGISTER STATUSBARS
-- Media:Register("statusbar", "Minimalist", [[Interface\AddOns\LUI4\media\statusbar\minimalist.tga]])
-- Media:Register("statusbar", "Gradient", [[Interface\AddOns\LUI4\media\statusbar\gradient.tga]])
-- Media:Register("statusbar", "Ruben", [[Interface\AddOns\LUI4\media\statusbar\Ruben.tga]])

-- LUI.blank = [[Interface\AddOns\LUI4\media\blank.tga]]

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
				-- Print for testing purposes while we setup all modules during development.
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
		if not IsAddOnLoaded("LUIOptions") then
			_G.LoadAddOn("LUIOptions")
		end

		self:NewOpen()
	else
		self:Open()
	end
end

--TODO: Handle of chat command is a mess that need fixing.
--Future: Make it so that modules can handle chat command through /lui [moduleName] [setting] [value]
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
-- 	--/lui dev installed moduleName
-- 	--Reverts the installed state of a certain module (or all of them)
-- 	if cmd == "installed" then
-- 		LUI:Print(format(L["Core_Dev_RevertState_Format"], value))
-- 	end
end

-- ####################################################################################################################
-- ##### Module Handling ##############################################################################################
-- ####################################################################################################################

--Function that will create a namespace for each module.
function LUI:RegisterModule(module, dev_skipDB)
	local mName = module:GetName()

	--If a module hasn't been installed yet and should be disabled by default, disable it.
	--Otherwise, modules are enabled by default, and db.modules[name] should be true.
	if module.defaultDisabled and not db.Installed[mName] then
		db.Modules[mName] = false
	end
	module:SetEnabledState(self.db.profile.Modules[mName])

	if module.defaults and not dev_skipDB then
		module.db = self.db:RegisterNamespace(mName, module.defaults)

		-- Register Callbacks
		--TODO: Recheck Register Callbacks
		--if type(module.Refresh) == "function" then
		--	module.db.RegisterCallback(module, "OnProfileChanged", LUI.RefreshModule, module)
		--	module.db.RegisterCallback(module, "OnProfileCopied", LUI.RefreshModule, module)
		--	module.db.RegisterCallback(module, "OnProfileReset", LUI.RefreshModule, module)
		--end
	end

	--Add the module to the LUI Profiler
	LUI.Profiler.TraceScope(module, mName, "LUI", 2)

	-- To remove when all modules transitioned to new options menu
	module.registered = true
end

-- ####################################################################################################################
-- ##### Framework Events #############################################################################################
-- ####################################################################################################################

-- function LUI:OnInitialize()
-- 	self.db = LibStub("AceDB-3.0"):New("LUI4DB", LUI.defaults, true)
-- 	self.db.RegisterCallback(self, "OnProfileChanged", "Refresh")
-- 	self.db.RegisterCallback(self, "OnProfileCopied", "Refresh")
-- 	self.db.RegisterCallback(self, "OnProfileReset", "Refresh")
-- 	db = self.db.profile

-- 	LUI:EmbedModule(LUI)
-- 	self:RegisterChatCommand("lui", "ChatCommand")
-- end

-- function LUI:OnEnable()
-- 	LUI:CheckInstall()

-- 	local font = db.Fonts.Master
-- 	LUI.MasterFont = CreateFont("LUIMasterFont")
-- 	LUI.MasterFont:SetFont(font.Name, font.Size, font.Flag)
-- end

-- function LUI:Refresh()
-- 	if not _G.IsLoggedIn() then return end -- in case of db callbacks fires before OnEnable function

-- 	--Failsafe calling OnEnable/OnDisable on Profile change to
-- 	for name_, module in self:IterateModules() do
-- 		local db = module.db
-- 		if db and db.profile and db.profile.Enable ~= nil then
-- 			module[db.profile.Enable and "Enable" or "Disable"](module)
-- 		end
-- 	end
-- end
