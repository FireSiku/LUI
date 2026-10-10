local ADDON, D = ...
_G.LUIDiagnostics = D
D.VERSION = "0.1.5"
D.MAX_SESSIONS, D.MAX_ERRORS, D.MAX_EVENTS = 3, 40, 60
local frame = CreateFrame("Frame")
local recording, busy = false, false
local session, database
local errorIndex, recentNative = {}, {}
local rateSecond, rateCount = -1, 0
local callbackMode, callbackOwner
local nativeEvents = {ADDON_ACTION_BLOCKED = true, ADDON_ACTION_FORBIDDEN = true, LUA_WARNING = true}
local watchedEvents = {
	"ADDON_ACTION_BLOCKED", "ADDON_ACTION_FORBIDDEN", "LUA_WARNING",
	"PLAYER_ENTERING_WORLD", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
	"GROUP_ROSTER_UPDATE", "GUILD_ROSTER_UPDATE", "ADDON_LOADED", "PLAYER_LOGOUT",
}
local watchedFrames = {"CommunitiesFrame", "FriendsFrame", "GuildFrame", "GameTooltip", "SettingsPanel"}

local function Secret(value)
	return issecretvalue and issecretvalue(value)
end

local function Text(value, limit)
	if Secret(value) then return "<restricted>" end
	local kind = type(value)
	if kind ~= "string" and kind ~= "number" and kind ~= "boolean" then return "<unavailable>" end
	local text = tostring(value)
	-- Prevent error strings from injecting clickable links or textures into the
	-- copy window. No error locals or arbitrary tables are serialized.
	text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
	text = text:gsub("|H.-|h(.-)|h", "%1"):gsub("|T.-|t", ""):gsub("|A.-|a", "")
	limit = limit or 200
	if #text > limit then text = text:sub(1, limit) .. " [truncated]" end
	return text
end
D.Text = Text

local function Read(func, ...)
	if type(func) ~= "function" then return nil end
	local ok, value = pcall(func, ...)
	if ok and not Secret(value) then return value end
end

local function Stamp()
	return date("%Y-%m-%d %H:%M:%S")
end

local function Boolean(value)
	if Secret(value) or value == nil then return "unknown" end
	return value and "yes" or "no"
end

function D:IsRecording() return recording end

function D:GetDatabase()
	if database then return database end
	if type(LUIDiagnosticsDB) ~= "table" then LUIDiagnosticsDB = {} end
	database = LUIDiagnosticsDB
	database.schema = 1
	if type(database.sessions) ~= "table" then database.sessions = {} end
	while #database.sessions > self.MAX_SESSIONS do table.remove(database.sessions, 1) end
	return database
end

function D:GetLatestSession()
	local db = self:GetDatabase()
	return db.sessions[#db.sessions]
end

local function Modules()
	local list = {}
	for name, module in LUI:IterateModules() do
		if #list >= 100 then break end
		list[#list + 1] = Text(name, 80) .. "=" .. Boolean(Read(module.IsEnabled, module))
	end
	table.sort(list)
	return table.concat(list, ", ")
end

local function FrameState(name)
	local object = _G[name]
	if Secret(object) then return "restricted" end
	if not object then return "not loaded" end
	local ok, state = pcall(function()
		if object.IsForbidden and object:IsForbidden() then return "forbidden" end
		local shown = object:IsShown()
		if Secret(shown) then return "restricted" end
		return shown and "open" or "closed"
	end)
	return ok and state or "unavailable"
end

local function Context()
	local context = {
		combat = Boolean(Read(InCombatLockdown)),
		instance = "unknown",
		frames = {},
		modules = Modules(),
	}
	local ok, _, instanceType = pcall(IsInInstance)
	if ok then context.instance = Text(instanceType, 40) end
	for _, name in ipairs(watchedFrames) do context.frames[name] = FrameState(name) end
	local registry = LibStub("AceConfigDialog-3.0", true)
	local options = registry and registry.OpenFrames.LUIOptions
	context.frames.LUIOptions = options and "open" or "closed"
	return context
end

local function Environment()
	local version, build, _, interface = GetBuildInfo()
	local env = {
		wow = Text(version), build = Text(build), interface = Text(interface),
		lui = Text(Read(C_AddOns.GetAddOnMetadata, "LUI", "Version")),
		diagnostics = D.VERSION, locale = Text(GetLocale()),
		project = Text(WOW_PROJECT_ID), modules = Modules(), addons = {},
		bugGrabber = Text(Read(C_AddOns.GetAddOnMetadata, "!BugGrabber", "Version")),
	}
	local count = Read(C_AddOns.GetNumAddOns) or 0
	for i = 1, math.min(count, 500) do
		if Read(C_AddOns.IsAddOnLoaded, i) then
			env.addons[#env.addons + 1] = Text(Read(C_AddOns.GetAddOnInfo, i), 100)
				.. " " .. Text(Read(C_AddOns.GetAddOnMetadata, i, "Version"), 100)
		end
	end
	table.sort(env.addons)
	return env
end

function D:Breadcrumb(event, detail)
	if not recording or not session then return end
	local last = session.events[#session.events]
	local at = Stamp()
	if last and last.event == event and last.at == at then
		last.count = (last.count or 1) + 1
		return
	end
	session.events[#session.events + 1] = {event = event, at = at, detail = detail}
	if #session.events > self.MAX_EVENTS then
		table.remove(session.events, 1)
		session.eventsEvicted = session.eventsEvicted + 1
	end
end

local function BreadcrumbCopy()
	local entries = {}
	for i = math.max(1, #session.events - 7), #session.events do
		local item = session.events[i]
		entries[#entries + 1] = item.at .. " " .. item.event .. (item.detail and " " .. item.detail or "")
	end
	return entries
end

local function Capture(kind, message, stack, stackSource, addon, func)
	message = Text(message, 3000)
	local key = kind .. "\n" .. message
	local entry = errorIndex[key]
	session.observed = session.observed + 1
	if entry then
		entry.count = entry.count + 1
		entry.lastAt = Stamp()
		return
	end
	local second = math.floor(GetTime())
	if second ~= rateSecond then rateSecond, rateCount = second, 0 end
	rateCount = rateCount + 1
	if rateCount > 5 then
		session.throttled = session.throttled + 1
		return
	end
	if D.CaptureActionBars then D:CaptureActionBars("error") end
	if not stack then
		stack = Read(debugstack, 4, 18, 8)
		stackSource = "Diagnostic event handler; not necessarily the original failing call"
	end
	entry = {
		kind = kind, message = message, stack = Text(stack, 10000), stackSource = stackSource,
		addon = addon, func = func, firstAt = Stamp(), lastAt = Stamp(), count = 1,
		context = Context(), before = BreadcrumbCopy(),
	}
	session.errors[#session.errors + 1] = entry
	errorIndex[key] = entry
	if #session.errors > D.MAX_ERRORS then
		local removed = table.remove(session.errors, 1)
		errorIndex[removed.kind .. "\n" .. removed.message] = nil
		session.errorsEvicted = session.errorsEvicted + 1
	end
end

function D:Record(...)
	if not recording or busy then return end
	busy = true
	local ok = pcall(Capture, ...)
	busy = false
	if not ok then session.captureFailures = session.captureFailures + 1 end
end

function D:OnBug(errorObject)
	if not recording or Secret(errorObject) or type(errorObject) ~= "table" then return end
	local message = Text(errorObject.message, 3000)
	-- Native events give us every occurrence (BugGrabber may suppress later
	-- protected calls). Use its original stack when both listeners see one event.
	for _, event in ipairs({"ADDON_ACTION_BLOCKED", "ADDON_ACTION_FORBIDDEN", "LUA_WARNING"}) do
		local prefix = event == "LUA_WARNING" and "LUA_WARNING:" or "[" .. event .. "]"
		if message:sub(1, #prefix) == prefix then
			recentNative[event] = {message = message, stack = Text(errorObject.stack, 10000), time = GetTime()}
			return
		end
	end
	self:Record("LUA_ERROR", message, Text(errorObject.stack, 10000), "BugGrabber")
end

function D:AttachBugGrabber()
	if callbackMode or not _G.BugGrabber then return end
	local bg = _G.BugGrabber
	-- Older releases use CallbackHandler; current releases send an opaque ID
	-- through Blizzard's EventRegistry. Do not replace the global error handler.
	if bg.setupCallbacks and not bg.RegisterCallback then pcall(bg.setupCallbacks) end
	if bg.RegisterCallback then
		local ok = pcall(bg.RegisterCallback, self, "BugGrabber_BugGrabbed", function(_, err) self:OnBug(err) end)
		if ok then callbackMode, callbackOwner = "legacy", bg end
	elseif EventRegistry and bg.GetErrorByID then
		EventRegistry:RegisterCallback("BugGrabber.BugGrabbed", function(_, id)
			if not recording or Secret(id) then return end
			local ok, err = pcall(bg.GetErrorByID, bg, id)
			if ok then self:OnBug(err) end
		end, self)
		callbackMode, callbackOwner = "registry", bg
	end
	if session then session.bugGrabberMode = callbackMode or "unavailable" end
end

function D:DetachBugGrabber()
	if callbackMode == "registry" then
		EventRegistry:UnregisterCallback("BugGrabber.BugGrabbed", self)
	elseif callbackMode == "legacy" and callbackOwner.UnregisterCallback then
		pcall(callbackOwner.UnregisterCallback, self, "BugGrabber_BugGrabbed")
	end
	callbackMode, callbackOwner = nil, nil
end

function D:GetCaptureStatus()
	if not recording then return "Recording is off." end
	if not callbackMode then return "BugGrabber is unavailable: blocked actions and Lua warnings only. Enable !BugGrabber for Lua errors and original stacks." end
	if Read(callbackOwner.IsPaused, callbackOwner) then return "BugGrabber is throttling errors. Some Lua errors may be missing; native blocked actions are still recorded." end
	return "BugGrabber connected. Lua errors, blocked actions and Lua warnings are recorded."
end

function D:Resume()
	if recording then return end
	local db = self:GetDatabase()
	local state = LUI:GetDiagnosticsState()
	session = self:GetLatestSession()
	if state.newSession or not session or session.finishedAt then
		db.nextID = (tonumber(db.nextID) or 0) + 1
		session = {
			id = db.nextID, startedAt = Stamp(), errors = {}, events = {}, observed = 0,
			throttled = 0, errorsEvicted = 0, eventsEvicted = 0, captureFailures = 0,
			reloads = 0, environment = Environment(), bugGrabberMode = "unavailable",
		}
		db.sessions[#db.sessions + 1] = session
		while #db.sessions > self.MAX_SESSIONS do table.remove(db.sessions, 1) end
	else
		session.reloads = session.reloads + 1
	end
	state.newSession = nil
	errorIndex, recentNative = {}, {}
	for _, entry in ipairs(session.errors) do errorIndex[entry.kind .. "\n" .. entry.message] = entry end
	rateSecond, rateCount = -1, 0
	recording = true
	self:AttachBugGrabber()
	for _, event in ipairs(watchedEvents) do frame:RegisterEvent(event) end
	self:Breadcrumb("DIAGNOSTICS_RESUMED")
	if self.BeginActionBarCapture then self:BeginActionBarCapture(session) end
end

function D:Stop()
	if self.EndActionBarCapture then self:EndActionBarCapture() end
	if session and recording then
		self:Breadcrumb("DIAGNOSTICS_STOPPED")
		session.finishedAt = Stamp()
		session.captureStatusAtEnd = self:GetCaptureStatus()
	end
	recording = false
	frame:UnregisterAllEvents()
	self:DetachBugGrabber()
end

function D:ChangeRecording(enabled)
	-- Recheck at the moment of confirmation, not just when the window opens.
	if InCombatLockdown() then LUI:Print("LUI DEBUG: Please wait until you are out of combat.") return false end
	local state = LUI:GetDiagnosticsState()
	if enabled then
		if recording then return false end
		state.enabled, state.newSession, state.showAfterReload = true, true, "started"
		if self:GetDatabase().actionBarTrace then state.showAfterReload = nil end
	else
		self:Stop()
		state.enabled, state.showAfterReload = false, "stopped"
	end
	ReloadUI()
	return true
end

function D:Initialize()
	if self.initialized then return end
	self.initialized = true
	self:GetDatabase()
	if LUI:GetDiagnosticsState().enabled then self:Resume() end
	local function Ready()
		if recording then session.environment = Environment() end
		local state = LUI:GetDiagnosticsState()
		if recording then LUI:Print("LUI DEBUG is ACTIVE. Open LUI DEBUG to stop recording and share your report.") end
		if state.showAfterReload then
			local page = state.showAfterReload
			state.showAfterReload = nil
			-- An unusual combat login must not cause an unsolicited window later.
			if not InCombatLockdown() then self:OpenWindow(page) end
		end
	end
	if IsLoggedIn() then
		C_Timer.After(0, Ready)
	else
		local login = CreateFrame("Frame")
		login:RegisterEvent("PLAYER_LOGIN")
		login:SetScript("OnEvent", function()
			login:UnregisterAllEvents()
			C_Timer.After(0, Ready)
		end)
	end
end

frame:SetScript("OnEvent", function(_, event, ...)
	if not recording then return end
	if nativeEvents[event] then
		local addon, func = ...
		local extra = recentNative[event]
		recentNative[event] = nil
		local stack, source
		if extra and GetTime() - extra.time < 0.1 then
			stack, source = extra.stack, "BugGrabber (same native event)"
		end
		if event == "LUA_WARNING" then
			D:Record(event, Text(addon, 3000), stack, source)
		else
			addon, func = Text(addon, 150), Text(func, 300)
			D:Record(event, addon .. ": " .. func, stack, source, addon, func)
		end
	else
		local detail
		if event == "ADDON_LOADED" then
			detail = Text((...), 100)
			D:AttachBugGrabber()
		elseif event == "PLAYER_LOGOUT" then
			session.lastSavedAt = Stamp()
		elseif event == "PLAYER_ENTERING_WORLD" then
			session.environment = Environment()
		end
		D:Breadcrumb(event, detail)
	end
end)

function D:BuildReport()
	local current = self:GetLatestSession()
	if not current then return "No diagnostic session has been recorded yet." end
	local lines = {}
	local function Add(text) lines[#lines + 1] = text or "" end
	local env = current.environment
	Add("LUI DIAGNOSTICS REPORT | schema 1 | addon " .. self.VERSION)
	Add("Session " .. current.id .. " | " .. current.startedAt .. " -> " .. (current.finishedAt or "ACTIVE"))
	Add("WoW " .. env.wow .. " | build " .. env.build .. " | interface " .. env.interface .. " | " .. env.locale)
	Add("LUI " .. env.lui .. " | BugGrabber " .. env.bugGrabber .. " | integration " .. current.bugGrabberMode)
	Add("Reloads/relogins: " .. current.reloads .. " | observed: " .. current.observed .. " | stored groups: " .. #current.errors)
	Add("New errors throttled: " .. current.throttled .. " | groups evicted: " .. current.errorsEvicted .. " | capture failures: " .. current.captureFailures)
	Add(current.captureStatusAtEnd or self:GetCaptureStatus())
	Add("Context and preceding events describe the FIRST occurrence of each stored error group. Counts include later repeats.")
	Add("This report provides context; addon attribution does not prove the root cause. Restricted values are omitted.")
	Add("No settings or chat history are collected. Error messages/stacks can contain names; review before sharing.")
	Add()
	Add("MODULES: " .. env.modules)
	Add("LOADED ADDONS (latest environment snapshot):")
	for _, addon in ipairs(env.addons) do Add("  " .. addon) end
	for index, err in ipairs(current.errors) do
		Add()
		Add("--- " .. index .. ". " .. err.kind .. " | occurrences " .. err.count .. " ---")
		Add("First: " .. err.firstAt .. " | last: " .. err.lastAt)
		Add(err.message)
		Add("Combat: " .. err.context.combat .. " | instance: " .. err.context.instance)
		for _, name in ipairs(watchedFrames) do Add(name .. ": " .. err.context.frames[name]) end
		Add("LUIOptions: " .. err.context.frames.LUIOptions)
		Add("Modules at first occurrence: " .. err.context.modules)
		Add("Preceding events:")
		for _, event in ipairs(err.before) do Add("  " .. event) end
		Add("Stack source: " .. (err.stackSource or "unavailable"))
		Add(err.stack)
	end
	Add()
	Add("RECENT EVENTS | older entries evicted: " .. current.eventsEvicted)
	for _, event in ipairs(current.events) do
		Add(event.at .. " " .. event.event .. (event.detail and " " .. event.detail or "") .. (event.count and " x" .. event.count or ""))
	end
	if self.AppendActionBarReport then self:AppendActionBarReport(current, Add) end
	Add()
	Add("END OF REPORT | session " .. current.id .. " | " .. #current.errors .. " stored error groups")
	return table.concat(lines, "\n")
end
