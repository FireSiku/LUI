--[[
	Project.: LUI NextGenWoWUserInterface
	File....: LUI.lua
	Original version: 3.403
	Original revision date: 13/02/2011
	Author..: Louí [EU-Das Syndikat] <In Fidem>
]]

---@class LUIAddon
local LUI = select(2, ...)
local L = LUI.L

local AceAddon = LibStub("AceAddon-3.0")

---@type string
local addonname = ...

local Media = LibStub("LibSharedMedia-3.0")

local IsAddOnLoaded = C_AddOns.IsAddOnLoaded
local GetNumAddOns = C_AddOns.GetNumAddOns
local GetAddOnInfo = C_AddOns.GetAddOnInfo
local GetAddOnEnableState = C_AddOns.GetAddOnEnableState
local IsLoggedIn = _G.IsLoggedIn
local IsInGroup = _G.IsInGroup
local strjoin = _G.strjoin

local ACCEPT = _G.ACCEPT
local CANCEL = _G.CANCEL

LUI.Versions = {lui = 3404}

LUI.playerClass = select(2, _G.UnitClass("player"))
LUI.playerFaction = _G.UnitFactionGroup("player")
LUI.playerName =  _G.UnitName("player")
LUI.playerRealm = _G.GetRealmName()
LUI.playerFullName = format("%s-%s", LUI.playerName, LUI.playerRealm)
LUI.otherFaction = (LUI.playerFaction == "Horde") and "Alliance" or "Horde"

-- Provide quick access to locale-independent class checks, such as "if LUI.MAGE then"
LUI[LUI.playerClass] = true

-- Character key used by LUI's integration presets and migration storage.
LUI.profileName = format("%s - %s", LUI.playerName, LUI.playerRealm)

-- REGISTER FONTS
Media:Register("font", "vibrocen", [[Interface\Addons\LUI\media\fonts\vibrocen.ttf]])
Media:Register("font", "vibroceb", [[Interface\Addons\LUI\media\fonts\vibroceb.ttf]])
Media:Register("font", "Prototype", [[Interface\Addons\LUI\media\fonts\prototype.ttf]])
Media:Register("font", "neuropol", [[Interface\AddOns\LUI\media\fonts\neuropol.ttf]])
Media:Register("font", "AvantGarde_LT_Medium", [[Interface\AddOns\LUI\media\fonts\AvantGarde_LT_Medium.ttf]])
Media:Register("font", "Arial Narrow", [[Interface\AddOns\LUI\media\fonts\ARIALN.TTF]])
Media:Register("font", "Pepsi", [[Interface\AddOns\LUI\media\fonts\pepsi.ttf]])
Media:Register("font", "NotoSans-SCB", [[Interface\AddOns\LUI\media\fonts\NotoSans-SemiCondensedBold.ttf]])

-- REGISTER BORDERS
Media:Register("border", "glow", [[Interface\Addons\LUI\media\borders\glow.tga]])
Media:Register("border", "Stripped", [[Interface\Addons\LUI\media\\borders\Stripped.tga]])
Media:Register("border", "Stripped_hard", [[Interface\Addons\LUI\media\borders\Stripped_hard.tga]])
Media:Register("border", "Stripped_medium", [[Interface\Addons\LUI\media\borders\Stripped_medium.tga]])

-- REGISTER STATUSBARS
-- Keep this legacy media name because existing profiles may still reference it.
Media:Register("statusbar", "oUF LUI", [[Interface\AddOns\LUI\media\statusbars\Minimalist.tga]])
Media:Register("statusbar", "LUI_Gradient", [[Interface\AddOns\LUI\media\statusbars\Gradient.tga]])
Media:Register("statusbar", "LUI_Minimalist", [[Interface\AddOns\LUI\media\statusbars\Minimalist.tga]])
Media:Register("statusbar", "LUI_Ruben", [[Interface\AddOns\LUI\media\statusbars\Ruben.tga]])
Media:Register("statusbar", "Smelly", [[Interface\AddOns\LUI\media\statusbars\Smelly.tga]])
Media:Register("statusbar", "Neal", [[Interface\AddOns\LUI\media\statusbars\Neal]])
Media:Register("statusbar", "RenaitreMinion", [[Interface\AddOns\LUI\media\statusbars\RenaitreMinion.tga]])
Media:Register("statusbar", "Otravi", [[Interface\AddOns\LUI\media\statusbars\Otravi.tga]])
Media:Register("statusbar", "Empty", [[Interface\AddOns\LUI\media\textures\blank.tga]])

LUI.Media = {
	["blank"] = [[Interface\AddOns\LUI\media\textures\blank.tga]],
	["glowTex"] = [[Interface\AddOns\LUI\media\borders\glow.tga]],
}

LUI.Opposites = {
	-- Sides
	TOP = "BOTTOM",
	BOTTOM = "TOP",
	LEFT = "RIGHT",
	RIGHT = "LEFT",
	-- Corners
	TOPLEFT = "BOTTOMRIGHT",
	TOPRIGHT = "BOTTOMLEFT",
	BOTTOMLEFT = "TOPRIGHT",
	BOTTOMRIGHT = "TOPLEFT",
}

------------------------------------------------------
-- / CREATING DEFAULTS / --
------------------------------------------------------

LUI.defaults = {
	profile = {
		General = {
			HideErrors = false,
			HideTalentSpam = false,
			AutoInvite = false,
			AutoInviteOnlyFriend = true,
			AutoInviteKeyword = "",
			BlizzFrameScale = 1,
			ModuleMessages = true,
			DamageFont = "neuropol",
			DamageFontSize = 25,
			DamageFontSizeCrit = 34,
			["*"] = {},
		},
		Modules = {
			["*"] = true,
		},
		dbVersion = 0,
	},
	global = {
		luiconfig = {},
		ProfileBackups = {},
	},
}

local db_
local db = setmetatable({}, {
	__index = function(t, k)
		return db_[k]
	end,
	__newindex = function(t, k, v)
		db_[k] = v
	end
})

local killedObjects = setmetatable({}, {__mode = "k"})
local killedObjectQueue = CreateFrame("Frame")

local function HideKilledObject(object)
	if not object.__luiKilled then
		killedObjects[object] = nil
		return
	end
	if object.IsProtected and object:IsProtected() and InCombatLockdown() then
		killedObjects[object] = true
		killedObjectQueue:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end
	object:Hide()
end

killedObjectQueue:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	for object in pairs(killedObjects) do
		killedObjects[object] = nil
		HideKilledObject(object)
	end
end)

--- Hide a region persistently without replacing Blizzard methods.
---@param object Frame
function LUI:Kill(object)
	if not object then return end
	if object.IsForbidden and object:IsForbidden() then return end
	object.__luiKilled = true
	if not object.__luiKillHooked then
		object.__luiKillHooked = true
		hooksecurefunc(object, "Show", HideKilledObject)
	end
	HideKilledObject(object)
end

--- Allow a region hidden by Kill to be shown again.
---@param object Frame Frame to revert
---@param force boolean Force the frame to be shown
function LUI:Unkill(object, force)
	if not object then return end
	if object.IsForbidden and object:IsForbidden() then return end
	object.__luiKilled = nil
	killedObjects[object] = nil
	if force then object:Show() end
end

local function scale(x)
	local uiWidth, uiHeight = GetPhysicalScreenSize()
	local scaleUI = UIParent:GetEffectiveScale()
	local mult = 768/uiHeight/scaleUI
	LUI.mult = mult
	return mult*math.floor(x/mult+.5)
end

function LUI:Scale(x) return scale(x) end

--- Function to simplify creating a frame
---@generic T, Tp
---@param fart `T` | FrameType
---@param fname string
---@param fparent any
---@param fwidth number
---@param fheight number
---@param fscale number
---@param fstrata FrameStrata
---@param flevel number
---@param fpoint AnchorPoint
---@param frelativeFrame any
---@param frelativePoint AnchorPoint
---@param fofsx number
---@param fofsy number
---@param falpha number
---@param finherit `Tp` | TemplateType
---@return T|Tp
function LUI:CreateMeAFrame(fart,fname,fparent,fwidth,fheight,fscale,fstrata,flevel,
							fpoint,frelativeFrame,frelativePoint,fofsx,fofsy,falpha,finherit)
	local f = CreateFrame(fart,fname,fparent,finherit)
	local sw = scale(fwidth)
	local sh = scale(fheight)
	local sx = scale(fofsx)
	local sy = scale(fofsy)
	f:SetWidth(sw)
	f:SetHeight(sh)
	f:SetFrameStrata(fstrata)
	f:SetFrameLevel(flevel)
	f:SetPoint(fpoint,frelativeFrame,frelativePoint,sx,sy)
	f:SetAlpha(falpha)
	return f
end

------------------------------------------------------
-- / SYNC ADDON VERSION / --
------------------------------------------------------

function LUI:SyncAddonVersion()
	local versionText = C_AddOns.GetAddOnMetadata(addonname, "Version") or "0"
	local version = tonumber(versionText:match("%d+")) or 0
	local newestVersion = version
	local lastGroupDistribution

	local function sendVersion(distribution, target) -- (distribution [, target])
		if distribution == "WHISPER" and not target then
			return
		end
		LUI:SendCommMessage("LUI_Version", tostring(version), distribution, target)
	end

	local function checkVersion(prefix, text, distribution, from)
		local remoteVersion = tonumber(text)
		if not remoteVersion then return end
		if version < remoteVersion and newestVersion < remoteVersion then
			newestVersion = remoteVersion
			LUI:Print(format(L["Version %s available for download."], "v"..remoteVersion))
		elseif version > remoteVersion and distribution ~= "WHISPER" then
			sendVersion("WHISPER", from)
		end
	end

	local function groupUpdate()
		local distribution
		if IsInGroup(_G.LE_PARTY_CATEGORY_INSTANCE) then
			distribution = "INSTANCE_CHAT"
		elseif IsInRaid() then
			distribution = "RAID"
		elseif IsInGroup() then
			distribution = "PARTY"
		end

		if distribution and distribution ~= lastGroupDistribution then
			lastGroupDistribution = distribution
			sendVersion(distribution)
		else
			lastGroupDistribution = distribution
		end
	end

	LUI:RegisterComm("LUI_Version", checkVersion)
	if IsInGuild() then sendVersion("GUILD") end
	groupUpdate()
	LUI:RegisterEvent("GROUP_ROSTER_UPDATE", groupUpdate)
end

------------------------------------------------------
-- / SET DAMAGE FONT / --
------------------------------------------------------

function LUI:SetDamageFont(_, loadedAddon)
	if loadedAddon and loadedAddon ~= "Blizzard_CombatText" then return end

	local constants = _G.CombatTextConstants
	local fontObject = _G.CombatTextFont
	if not constants or not fontObject then return end

	local fontPath = Media:Fetch("font", db.General.DamageFont)
	local _, _, fontFlags = fontObject:GetFont()
	fontObject:SetFont(fontPath, db.General.DamageFontSize, fontFlags)

	constants.MessageHeight = db.General.DamageFontSize
	constants.CriticalHitMaxHeight = db.General.DamageFontSizeCrit
	constants.CriticalHitMinHeight = max(db.General.DamageFontSizeCrit - 2, 1)

	if loadedAddon then
		self:UnregisterEvent("ADDON_LOADED")
	end
end

------------------------------------------------------
-- / LOAD EXTRA MODULES / --
------------------------------------------------------

function LUI:LoadExtraModules()
	for i=1, GetNumAddOns() do
		local name, _, _, loadable = GetAddOnInfo(i)
		local enabled = GetAddOnEnableState(name) > 0
		if strfind(name, "LUI_") and enabled and loadable then
			C_AddOns.LoadAddOn(i)
		end
	end
end

------------------------------------------------------
-- / MODULES / --
------------------------------------------------------

-- This is called whenever a module is created via NewModule. This method allow us to mark child modules as being nested without using prototypes.
function LUI:OnModuleCreated(newModule)
	newModule.Namespace = self.Namespace
	newModule.GetLegacyPrototype = self.GetLegacyPrototype
	newModule.OnModuleCreated = function(self, newElement)
		newElement.isNestedModule = true
	end
end

local function conflictChecker(...)
	for i=1, select("#", ...) do
		local addon = select(i, ...)
		-- Check the configured state as well as the current load state. LUI can
		-- initialize before a conflicting addon solely because of addon order.
		if C_AddOns.IsAddOnLoaded(addon) or C_AddOns.GetAddOnEnableState(addon) > 0 then
			return addon
		end
	end
end
function LUI:CheckConflict(...) -- self is module
	local conflict
	if type(self.conflicts) == "table" then
		conflict = conflictChecker(unpack(self.conflicts))
	else
		conflict = conflictChecker((";"):split(self.conflicts))
	end

	if conflict then
		-- disable without calling OnDisable function
		AceAddon.statuses[self.name] = false
		self:SetEnabledState(false)
		-- same for child modules
		for name, module in self:IterateModules() do
			AceAddon.statuses[module.name] = false
			module:SetEnabledState(false)
		end
		if db.General.ModuleMessages then
			LUI:Printf("|cffFF0000%s could not be enabled because of a conflicting addon: %s.", self:GetName(), conflict)
		end
		return
	else
		return LUI.hooks[self].OnEnable(self, ...)
	end
end

------------------------------------------------------
-- / SCRIPTS / --
------------------------------------------------------

do
	local scripts = {}

	--- Create a new script object.
	---@param name any
	---@param ... unknown
	---@return table
	function LUI:NewScript(name, ...)
		local script = {}
		scripts[name] = script

		local errormsg
		for i=1, select("#", ...) do
			local lib = select(i, ...)
			if type(lib) ~= "string" then
				errormsg = "Error generating script: "..name.." - library names must be string values!"
			elseif not LibStub(lib, true) then
				errormsg = "Error generating script: "..name.." - '"..lib.."' library does not exist!"
			elseif type(LibStub(lib).Embed) ~= "function" then
				errormsg = "Error generating script: "..name.." - '"..lib.."' library is not Embedable!"
			end
			if errormsg then
				return {}, self:Print(errormsg)
			end

			LibStub(lib):Embed(script)
		end

		return script
	end

	function LUI:FetchScript(name)
		return scripts[name]
	end
end

------------------------------------------------------
-- / OPTIONS MENU / --
------------------------------------------------------

local function mergeOldDB(dest, src)
	if type(dest) ~= "table" then dest = {} end
	for k, v in pairs(src) do
		if type(v) == type(dest[k]) then
			if type(v) == "table" then
				dest[k] = mergeOldDB(dest[k], v)
			else
				dest[k] = v
			end
		end
	end
	return dest
end

function LUI:NewNamespace(module, enableButton, version)
	local mName = module:GetName()
	if enableButton then module.enableButton = true end

	-- Register namespace
	local mdb = self.db:RegisterNamespace(mName, module.defaults)

	-- Create db metatable
	module.db = setmetatable({}, {
		__index = function(t, k)
			if mdb[k] then
				return mdb[k]
			else
				return mdb.profile[k]
			end
		end,
		__newindex = function(t, k, v)
			if mdb[k] then
				mdb[k] = v
			else
				mdb.profile[k] = v
			end
		end,
		__call = function(t, info, value)
			local dbloc = mdb.profile
			for i=2, #info-1 do
				dbloc = dbloc[info[i]]
				if type(dbloc) ~= "table" then
					error("Error accessing db:\nCould not access "..strjoin(".", info[1], "db.profile", unpack(info, 2, dbloc == nil and i or i+1)).."\ndb layout must be the same as info", 2)
				end
			end
			if value ~= nil then
				dbloc[info[#info]] = value
			else
				return dbloc[info[#info]]
			end
		end,
	})

	-- Create defaults metatable (the module.defaults table was handed off to AceDB and now exists as module.db.defaults)
	module.defaults = setmetatable({}, {
		__index = function(t, k)
			if mdb.defaults[k] then
				return mdb.defaults[k]
			else
				return mdb.defaults.profile[k]
			end
		end,
		__newindex = function(t, k, v)
			if mdb.defaults[k] then
				mdb.defaults[k] = v
			else
				mdb.defaults.profile[k] = v
			end
		end,
		__call = function(t, info, value)
			local dbloc = mdb.defaults.profile
			for i=2, #info-1 do
				dbloc = dbloc[info[i]]
				if type(dbloc) ~= "table" then
					error("Error accessing db:\nCould not access "..strjoin(".", info[1], "db.defaults.profile", unpack(info, 2, dbloc == nil and i or i+1)).."\ndb layout must be the same as info", 2)
				end
			end
			if value ~= nil then
				dbloc[info[#info]] = value
			else
				return dbloc[info[#info]]
			end
		end,
	})

	-- Look for outdated db vars and transfer them over
	if LUI.db.profile[mName] then
		mergeOldDB(module.db.profile, LUI.db.profile[mName])
		LUI.db.profile[mName] = nil
	end

	-- Set module enabled state
	if not self.enabledState or (module.addon and not C_AddOns.IsAddOnLoaded(module.addon)) then
		module:SetEnabledState(false)
	elseif module.db.profile.Enable ~= nil then
		module:SetEnabledState(module.db.profile.Enable)
	end

	-- Hook conflicting addon checker
	if module.conflicts then
		LUI:RawHook(module, "OnEnable", LUI.CheckConflict)
	end

	-- Register Callbacks
	if type(module.Refresh) == "function" then
		module.db.RegisterCallback(module, "OnProfileChanged", LUI.RefreshModule, module)
		module.db.RegisterCallback(module, "OnProfileCopied", LUI.RefreshModule, module)
		module.db.RegisterCallback(module, "OnProfileReset", LUI.RefreshModule, module)
	end

	-- Check for module version update
	local global_db = LUI.db.global.luiconfig[LUI.profileName]
	if version and version ~= global_db.Versions[mName] then
		if module.OnVersionUpdate then
			module:OnVersionUpdate(global_db.Versions[mName], version)
		else
			module.db:ResetProfile()
		end
		global_db.Versions[mName] = version
	end

	return module.db, module.defaults
end

function LUI:Namespace(module, toggleButton, version) -- no metatables (note: do not use defaults.Enable for the enabled state, it is handled by the parent module)
	local mName = module:GetName()
	if self.db.children and self.db.children[mName] then return module.db.profile, module.db.defaults.profile end
	if toggleButton then module.enableButton = true end

	-- Legacy namespaces keep their enabled state in the parent module's
	-- `modules` table. Mark top-level users so the new control panel can expose
	-- them without moving existing SavedVariables to the newer Modules table.
	if not module.isNestedModule then
		module.legacyNamespace = true
		module.registered = true
	end

	-- Register namespace
	module.db = LUI.db.RegisterNamespace(self.db, mName, module.defaults)

	-- Look for outdated db vars and transfer them over
	if self.db.profile[mName] then
		mergeOldDB(module.db.profile, self.db.profile[mName])
		self.db.profile[mName] = nil
	end

	-- Create modules table in parent's db if it doesn't exist already
	self.db.profile.modules = self.db.profile.modules or {}

	-- Look for incorrect Enable var usage
	if rawget(module.db.profile, "Enable") ~= nil then
		if rawget(module.db.defaults.profile, "Enable") ~= nil then
			module:SetEnabledState(false)
			error(format("Incorrect use of Enable db var in %s", tostring(module)), 2)
		elseif self.db.profile.modules[mName] == nil then -- old var in user's SavedVariables (move it over)
			self.db.profile.modules[mName] = module.db.profile.Enable
		end
		module.db.profile.Enable = nil
	end

	-- Set Enabled state
	if not self.enabledState or (module.addon and not C_AddOns.IsAddOnLoaded(module.addon)) then
		module:SetEnabledState(false)
	elseif self.db.profile.modules[mName] ~= nil then
		module:SetEnabledState(self.db.profile.modules[mName])
	elseif module.defaultState ~= nil then
		module:SetEnabledState(module.defaultState)
		self.db.profile.modules[mName] = module.defaultState
	end

	if not module.isNestedModule then
		-- Hook conflicting addon checker
		if module.conflicts then
			LUI:RawHook(module, "OnEnable", LUI.CheckConflict)
		end

		-- Register DB Callbacks
		if type(module.DBCallback) == "function" then
			module.db.RegisterCallback(module, "OnProfileChanged", "DBCallback")
			module.db.RegisterCallback(module, "OnProfileCopied", "DBCallback")
			module.db.RegisterCallback(module, "OnProfileReset", "DBCallback")
		end

	end

	-- Check for module version update
	local global_db = LUI.db.global.luiconfig[LUI.profileName]
	if version and version ~= global_db.Versions[mName] then
		if module.OnVersionUpdate then
			module:OnVersionUpdate(global_db.Versions[mName], version)
		else
			module.db:ResetProfile()
		end
		global_db.Versions[mName] = version
	end

	return module.db.profile, module.db.defaults.profile
end


------------------------------------------------------
-- / SETUP LUI / --
------------------------------------------------------

function LUI:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("LUIDB", LUI.defaults, true)

	local global_db = self.db.global.luiconfig[LUI.profileName]
	local firstRun = not (global_db and global_db.IsConfigured)
	if firstRun then
		self.db:SetProfile(LUI.profileName)
		global_db = {Versions = {}, IsConfigured = true}
		self.db.global.luiconfig[LUI.profileName] = global_db
		self.db.profile.dbVersion = self:GetDBVersion()
		self.openOptionsOnLogin = true
	else
		global_db.Versions = global_db.Versions or {}
	end

	db_ = self.db.profile
	global_db.Versions.lui = LUI.Versions.lui

	self.db.RegisterCallback(self, "OnProfileChanged", "Refresh")
	self.db.RegisterCallback(self, "OnProfileCopied", "Refresh")
	self.db.RegisterCallback(self, "OnProfileReset", "Refresh")

	self:RegisterChatCommand(addonname, "ChatCommand")

	if IsAddOnLoaded("Blizzard_CombatText") then
		self:SetDamageFont()
	else
		self:RegisterEvent("ADDON_LOADED", "SetDamageFont")
	end
	self:LoadExtraModules()

	-- Shared confirmation used by profile restores, migrations and settings that
	-- cannot safely rebuild protected frames while the UI is running.
	StaticPopupDialogs["RELOAD_UI"] = {
		preferredIndex = 3,
		text = L["The UI needs to be reloaded!"],
		button1 = ACCEPT,
		button2 = CANCEL,
		OnAccept = ReloadUI,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1
	}

end

function LUI:OnEnable()
	db_ = self.db.profile
	self:SyncAddonVersion()
	self:CheckUpdate()
	if self.openOptionsOnLogin then
		self.openOptionsOnLogin = nil
		C_Timer.After(0, function()
			if LUI:IsEnabled() then LUI:OpenOptions() end
		end)
	end
end

function LUI:Refresh(dbEvent)
	db_ = self.db.profile

	if not IsLoggedIn() then return end -- in case db callbacks fire before the OnEnable function

	if dbEvent then -- remove once all modules are using namespaces
		return ReloadUI()
	end
end

function LUI:RefreshModule(...) -- LUI.RefreshModule(module, callback_event, db, ...)
	if AceAddon.statuses[self.name] then -- check if self is enabled and if OnEnable script has ran
		self:Refresh(...)
	end
end
