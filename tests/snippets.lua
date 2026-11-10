-- Run with Lua 5.1 from the repository root. The argument points to the
-- unmodified Ace3 dependencies from the packaged test build.
local dependencies = assert(arg and arg[1], "Pass the Ace3 dependency directory")
local frames, reloads, messages = {}, 0, {}
local combat = false
strmatch, strfind, strlower = string.match, string.find, string.lower
strupper, strlen, strsub, format = string.upper, string.len, string.sub, string.format
strlenutf8 = string.len -- Fixture names are ASCII.
function wipe(value) for key in pairs(value) do value[key] = nil end return value end
function CreateFrame()
	local frame = {scripts = {}}
	function frame:RegisterEvent() end
	function frame:SetScript(event, callback) self.scripts[event] = callback end
	frames[#frames + 1] = frame
	return frame
end
function UnitFactionGroup() return "Alliance" end
function GetLocale() return "enUS" end
function UnitClass() return "Druid", "DRUID" end
function UnitRace() return "Night Elf", "NightElf" end
function GetRealmName() return "FixtureRealm" end
function UnitNameUnmodified() return "FixturePlayer" end
function GetCurrentRegion() return 3 end
function GetCurrentRegionName() return "EU" end
function InCombatLockdown() return combat end
function ReloadUI() reloads = reloads + 1 end
function geterrorhandler() return function(message) error(message) end end
function Mixin(target, ...)
	for index = 1, select("#", ...) do
		for key, value in pairs(select(index, ...)) do target[key] = value end
	end
	return target
end
function strsplit(separator, text)
	local first, rest = text:match("^(.-)" .. separator .. "(.*)$")
	return first or text, rest
end
C_AddOns = {GetAddOnMetadata = function() return "v2611" end}
for _, name in ipairs({"LibStub", "CallbackHandler-1.0", "AceDB-3.0", "AceSerializer-3.0"}) do
	dofile(dependencies .. "/" .. name .. ".lua")
end
local function Library(name, methods)
	local library = LibStub:NewLibrary(name, 1)
	for key, value in pairs(methods or {}) do library[key] = value end
	return library
end
Library("AceAddon-3.0", {NewAddon = function(_, namespace) return namespace end})
Library("LibSharedMedia-3.0")
Library("AceConfigDialog-3.0", {OpenFrames = {}, SetDefaultSize = function() end})
Library("AceConfigRegistry-3.0", {NotifyChange = function() end})
Library("AceConfig-3.0", {RegisterOptionsTable = function() end})
Library("AceDBOptions-3.0", {GetOptionsTable = function() return {args = {}} end})

local passed = 0
local function Check(condition, message)
	assert(condition, message)
	passed = passed + 1
end
local function Equal(first, second)
	if type(first) ~= type(second) then return false end
	if type(first) ~= "table" then return first == second end
	for key, value in pairs(first) do if not Equal(value, second[key]) then return false end end
	for key in pairs(second) do if first[key] == nil then return false end end
	return true
end
local aceDB, serializer = LibStub("AceDB-3.0"), LibStub("AceSerializer-3.0")
local rootDefaults = {profile = {rootOption = "default"}, global = {gold = 0}}
local sectionDefaults = {
	Unitframes = {profile = {Enable = true, width = 200, nested = {defaulted = true}}},
	Artwork = {profile = {Enable = true, color = "default"}},
	Chat = {profile = {Enable = true, font = 12, modules = {EditBox = true}}},
	Colors = {profile = {Colors = {DRUID = {r = 1, g = 0.44, b = 0.15}}}},
}
local storage = {}
LUI = {curseVersion = "v2611", L = setmetatable({}, {__index = function(_, key) return key end}),
	Print = function(_, message) messages[#messages + 1] = message end,
	Printf = function(_, pattern, ...) messages[#messages + 1] = pattern:format(...) end,
	GetModule = function() return nil end}
local function OpenDatabase()
	LUI.db = aceDB:New(storage, rootDefaults, "Mine")
	for name, defaults in pairs(sectionDefaults) do LUI.db:RegisterNamespace(name, defaults) end
	LUI.db.RegisterNamespace(LUI.db:GetNamespace("Chat"), "EditBox", {profile = {Enable = true, height = 22}})
end
local function Reopen()
	for _, frame in ipairs(frames) do
		if frame.scripts.OnEvent then frame.scripts.OnEvent(frame, "PLAYER_LOGOUT") end
	end
	OpenDatabase()
end
OpenDatabase()
local opt = {}
assert(loadfile("LUIOptions/LUIOptions.lua"))("LUIOptions", opt)
assert(loadfile("LUIOptions/Snippets.lua"))("LUIOptions", opt)
opt:OnEnable()
local api = opt.Snippets
local options = opt.options.args.Profiles.args.LayoutSnippets.args
Check(options.Share and options.Import and options.Restore, "snippet controls must live under Profiles")
local function Namespace(name) return LUI.db:GetNamespace(name) end
local function ChatEditBox() return LUI.db.GetNamespace(Namespace("Chat"), "EditBox") end
local function Encode(payload) return "!LUISnippet:1!" .. serializer:Serialize(payload) end

LUI.db:SetProfile("Source-private-name")
Namespace("Unitframes").profile.width = 180
Namespace("Unitframes").profile.nested = {custom = "source"}
Namespace("Unitframes").global.privateLayout = "account data"
Namespace("Artwork").profile.color = "source-art"
Namespace("Chat").profile.font = 18
ChatEditBox().profile.height = 35
local exported = assert(api:Export({Unitframes = true, Artwork = true, Chat = true}, "Fixture layout"))
local payload = assert(api:Read(exported))
Check(payload.sections.Unitframes and payload.sections.Artwork and payload.sections.Chat,
	"exports must include exactly the selected registered sections")
Check(not payload.profileName and not exported:find("Source-private-name", 1, true)
	and not exported:find("account data", 1, true), "snippets must exclude profile identities and account storage")
Check(payload.sections.Chat.namespaces.EditBox.profile.height == 35,
	"nested module settings must travel with their section")
LUI.db:SetProfile("Mine")
LUI.db.profile.rootOption = "keep-root"
LUI.db.global.gold = 12345
Namespace("Unitframes").profile.width = 260
Namespace("Unitframes").profile.Enable = false
Namespace("Unitframes").profile.nested = {recipientOnly = true}
Namespace("Artwork").profile.color = "keep-art"
Namespace("Chat").profile.font = 27
Namespace("Chat").profile.modules.EditBox = false
ChatEditBox().profile.Enable = false
ChatEditBox().profile.height = 45
local chatTable = Namespace("Chat").profile
local rootTable = LUI.db.profile
local unitTable = Namespace("Unitframes").profile
local profilesBefore = #LUI.db:GetProfiles()
Check(api:Apply(payload, {Unitframes = true}, "Mine"), "a selected section must import")
Check(Namespace("Unitframes").profile == unitTable and unitTable.width == 180,
	"imports must update AceDB's live profile table instead of leaving a stale cache")
Check(unitTable.Enable == false and not unitTable.nested.recipientOnly,
	"the section must replace old settings while retaining its module switch")
Check(Namespace("Chat").profile == chatTable and chatTable.font == 27
	and Namespace("Artwork").profile.color == "keep-art", "unselected sections must remain intact")
Check(LUI.db.profile == rootTable and rootTable.rootOption == "keep-root" and LUI.db.global.gold == 12345,
	"root settings and account-wide records must remain intact")
Check(LUI.db:GetCurrentProfile() == "Mine" and #LUI.db:GetProfiles() == profilesBefore,
	"imports must neither switch nor create profiles")
Check(api:CanRestore(), "the previous selected settings must be recoverable")
Reopen()
Check(Namespace("Unitframes").profile.width == 180 and Namespace("Unitframes").profile.Enable == false,
	"imported settings must survive AceDB shutdown cleanup and a database reopen")
Check(Namespace("Chat").profile.font == 27 and LUI.db.global.gold == 12345,
	"unselected and account data must also survive the reload")
Namespace("Chat").profile.font = 31
Check(api:Restore("Mine"), "the last selected import must be reversible")
Reopen()
Check(Namespace("Unitframes").profile.width == 260 and Namespace("Unitframes").profile.nested.recipientOnly,
	"restore must recover the pre-import settings after reload")
Check(Namespace("Chat").profile.font == 31 and not api:CanRestore(),
	"restore must keep subsequent edits in other sections and consume its backup")

Check(api:Apply(payload, {Chat = true}, "Mine"), "nested chat settings must import")
Check(Namespace("Chat").profile.font == 18 and Namespace("Chat").profile.modules.EditBox == false
	and ChatEditBox().profile.height == 35
	and ChatEditBox().profile.Enable == false,
	"parent and child settings must import while keeping all module switches")
Check(api:Apply(payload, {Unitframes = true}, "Mine"), "a subsequent import must succeed")
local newest = opt.ProfileTransfer.Copy(payload)
newest.sections.Unitframes.profile.width = 155
Check(api:Apply(newest, {Unitframes = true}, "Mine") and api:Restore("Mine"),
	"repeated imports must retain one useful undo step")
Check(Namespace("Unitframes").profile.width == 180 and #LUI.db:GetProfiles() == profilesBefore,
	"undo must restore the immediately previous import without accumulating profiles")

local before = opt.ProfileTransfer.Copy(storage)
local beforeReloads = reloads
combat = true
Check(not api:Apply(payload, {Unitframes = true}, "Mine") and not api:Restore("Mine"),
	"combat must block imports and restore")
combat = false
Check(not api:Apply(payload, {Unitframes = true}, "Another profile"),
	"a profile change after confirmation must cancel the import")
Check(not api:Apply(payload, {}, "Mine"), "empty selections must not write anything")
Check(not api:Apply(payload, {Colors = true}, "Mine"), "missing selected sections must not write anything")
Check(Equal(before, storage) and beforeReloads == reloads, "failed requests must leave data, backup and reload state intact")

local invalid = opt.ProfileTransfer.Copy(payload)
invalid.sections.Chat.namespaces.MissingComponent = {profile = {value = 1}}
Check(not api:Apply(invalid, {Unitframes = true, Chat = true}, "Mine") and Equal(before, storage),
	"all selected sections must be prepared before any writes when a child component is missing")
invalid = opt.ProfileTransfer.Copy(payload)
invalid.sections.Unitframes.global = {gold = 0}
Check(not api:Read(Encode(invalid)), "account-scope keys must not be accepted in section storage")
invalid = opt.ProfileTransfer.Copy(payload)
invalid.sections.Themes = {profile = {theme = "recolor all modules"}}
Check(not api:Read(Encode(invalid)), "themes must not implicitly recolor unselected modules")
invalid = opt.ProfileTransfer.Copy(payload)
invalid.sections.Bartender4 = {profile = {}}
Check(not api:Read(Encode(invalid)), "external addon settings must not be imported as LUI sections")
invalid = opt.ProfileTransfer.Copy(payload)
invalid.format = 2
Check(not api:Read(Encode(invalid)), "future formats must not be guessed")
invalid = opt.ProfileTransfer.Copy(payload)
local nested = invalid.sections.Unitframes.profile
for _ = 1, 40 do nested.deep = {}; nested = nested.deep end
Check(not api:Read(Encode(invalid)), "excessively nested data must be rejected")
invalid = opt.ProfileTransfer.Copy(payload)
invalid.sections.Unitframes.profile.width = math.huge
Check(not api:Read(Encode(invalid)), "non-finite settings must be rejected")
Check(not api:Read("!LUIProfile:1!^1^T^t^^"), "full profiles must keep their separate import route")
Check(not api:Read("!LUISnippet:1!return _G.SnippetExecuted = true") and not _G.SnippetExecuted,
	"snippet text must never be evaluated as Lua")
Check(not api:Read(exported .. string.rep("x", 2000001)), "oversized strings must be rejected")

-- Exercise the real UI callbacks, including confirmation races.
local ui = options.Import.args
ui.String.set(nil, exported)
ui.Read.func()
Check(ui.Sections.get(nil, "Unitframes") and not ui.Apply.disabled(), "reading must expose the contained sections")
ui.Apply.confirm()
ui.Sections.set(nil, "Artwork", false)
beforeReloads = reloads
ui.Apply.func()
Check(reloads == beforeReloads, "changing selected sections must invalidate the pending confirmation")
ui.Apply.confirm()
LUI.db:SetProfile("Other")
ui.Apply.func()
Check(reloads == beforeReloads, "changing profiles must invalidate a confirmed UI import")
LUI.db:SetProfile("Mine")
ui.Apply.confirm()
ui.Apply.func()
Check(reloads == beforeReloads + 1, "a confirmed unchanged UI import must reload exactly once")
local full = opt.options.args.Profiles.args.LUIProfileTransfer.args
full.GenerateExport.func()
Check(full.ExportString.get():sub(1, 14) == "!LUIProfile:1!", "existing full-profile exports must remain available")
local foreign = opt.ProfileTransfer.Copy(payload)
foreign.client = "Forever"
ui.String.set(nil, Encode(foreign))
ui.Read.func()
Check(ui.Review.name():find("another client", 1, true), "cross-client snippets must identify the source client")
print("Snippet checks passed: " .. passed)
