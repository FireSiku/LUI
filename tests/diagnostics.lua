-- Run from the repository root with Lua 5.1. No WoW runtime is needed.
local passed = 0
local function Check(condition, message)
	assert(condition, message)
	passed = passed + 1
end

local state = {loadCalls = 0, reloads = 0, time = 1, combat = false}
local secret = setmetatable({}, {__tostring = function() error("restricted value was converted") end})
local frames = {}
local lui = {db = {global = {}}, Print = function() end}
function lui:IterateModules()
	return pairs({Artwork = {IsEnabled = function() return true end}})
end
local addons = {"LUI", "DandersFrames"}
local versions = {LUI = "v2611", DandersFrames = "fixture-version"}
local env = setmetatable({
	LUI = lui, WOW_PROJECT_ID = 1,
	issecretvalue = function(value) return value == secret end,
	date = function() return "2026-11-10 18:00:00" end,
	GetTime = function() return state.time end,
	GetBuildInfo = function() return "fixture-client", "12345", "", 120105 end,
	GetLocale = function() return "enUS" end,
	IsInInstance = function() return false, "none" end,
	InCombatLockdown = function() return state.combat end,
	LibStub = function() return nil end,
	ReloadUI = function() state.reloads = state.reloads + 1 end,
	SetCVar = function() error("ordinary diagnostics must not change CVars") end,
	C_AddOns = {
		GetNumAddOns = function() return #addons end,
		GetAddOnInfo = function(index) return addons[index] end,
		GetAddOnMetadata = function(name) return versions[addons[name] or name] end,
		IsAddOnLoaded = function(name) return versions[addons[name] or name] ~= nil end,
		LoadAddOn = function() state.loadCalls = state.loadCalls + 1 end,
	},
	CreateFrame = function()
		local frame = {events = {}, scripts = {}}
		function frame:RegisterEvent(event) self.events[event] = true end
		function frame:UnregisterAllEvents() self.events = {} end
		function frame:SetScript(event, callback) self.scripts[event] = callback end
		frames[#frames + 1] = frame
		return frame
	end,
}, {__index = _G})
env._G = env
local function Load(path, addon, namespace)
	setfenv(assert(loadfile(path)), env)(addon, namespace)
end

Load("api/diagnostics.lua", "LUI", lui)
lui:RecordAddonSetup("Grid2", "STARTED")
Check(state.loadCalls == 0 and env.LUIDiagnosticsDB == nil,
	"setup breadcrumbs must not load the recorder or create a database")

local diagnostics = {}
Load("LUIDiagnostics/Core.lua", "LUIDiagnostics", diagnostics)
lui:RecordAddonSetup("Grid2", "STARTED")
Check(env.LUIDiagnosticsDB == nil and next(frames[1].events) == nil,
	"a loaded but disabled recorder must not collect setup events or register listeners")

state.combat = true
Check(not diagnostics:ChangeRecording(true) and state.reloads == 0,
	"combat must still prevent starting diagnostics")
state.combat = false
Check(diagnostics:ChangeRecording(true) and state.reloads == 1,
	"starting diagnostics must request a reload")
diagnostics:Resume()
local session = diagnostics:GetLatestSession()
lui:RecordAddonSetup("Grid2", "STARTED")
diagnostics:Record("LUA_ERROR", "fixture failure", "fixture stack", "fixture")
local error = session.errors[1]
Check(#error.before == 2 and error.before[2]:find("ADDON_SETUP_STARTED Grid2", 1, true),
	"the error report must retain the setup that was in progress")
lui:RecordAddonSetup("Grid2", "COMPLETED")
local report = diagnostics:BuildReport()
Check(report:find("DandersFrames fixture-version", 1, true),
	"loaded addon versions must include Danders without a fixed allowlist")
Check(report:find("ADDON_SETUP_COMPLETED Grid2", 1, true),
	"the exported recent events must include successful setup completion")

diagnostics:Breadcrumb("ADDON_LOADED", "One")
diagnostics:Breadcrumb("ADDON_LOADED", "Two")
Check(session.events[#session.events - 1].detail == "One"
	and session.events[#session.events].detail == "Two",
	"different details in one second must remain separate")
diagnostics:Breadcrumb("ADDON_LOADED", "Two")
Check(session.events[#session.events].count == 2,
	"identical events may still be coalesced")
diagnostics:Breadcrumb("RESTRICTED_TEST", secret)
Check(session.events[#session.events].detail == "<restricted>",
	"restricted breadcrumb details must never be converted or saved")
diagnostics:Breadcrumb("TABLE_TEST", {profile = "private"})
Check(session.events[#session.events].detail == "<unavailable>",
	"arbitrary settings tables must never enter the event trail")
diagnostics:Breadcrumb("LONG_TEST", string.rep("x", 1000))
Check(#session.events[#session.events].detail < 220,
	"breadcrumb details must remain bounded")
for index = 1, 70 do diagnostics:Breadcrumb("BOUND_TEST", tostring(index)) end
Check(#session.events == diagnostics.MAX_EVENTS and session.eventsEvicted > 0,
	"setup context must obey the existing event history bound")

local savedEvents = #session.events
Check(diagnostics:ChangeRecording(false) and state.reloads == 2,
	"stopping must still request a save/reload")
lui:RecordAddonSetup("Grid2", "STARTED")
Check(not diagnostics:IsRecording() and #session.events == savedEvents
	and next(frames[1].events) == nil,
	"stopped diagnostics must neither capture setups nor keep listeners")
Check(diagnostics.SAVED_VARIABLES_PATH:find("<game folder>", 1, true)
	and diagnostics.TAINT_LOG_PATH:find("<game folder>", 1, true),
	"both exported paths must work without assuming Retail's installation folder")

print("Diagnostic checks passed: "..passed)
