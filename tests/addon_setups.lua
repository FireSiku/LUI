-- Run from the repository root with Lua 5.1.
-- These checks exercise the options' real callbacks against addon API fixtures.
local function Copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in pairs(value) do result[key] = Copy(child) end
	return result
end

local function Count(value)
	local count = 0
	for _ in pairs(value) do count = count + 1 end
	return count
end

local passed = 0
local function Check(condition, message)
	assert(condition, message)
	passed = passed + 1
end

local function Environment(addonID, file)
	local state = {loaded = {[addonID] = true}, reloads = 0, combat = false}
	local artwork = {db = {profile = {LUITextures = {Raid = {}}, SideBars = {}}}}
	function artwork:IsEnabled() return true end
	function artwork:IterateSidebars() return pairs({}) end
	function artwork:Refresh() end
	local lui = {GetModule = function() return artwork end, Print = function() end,
		L = {CPanel_Modules = "Modules"}, IterateModules = function() return pairs({}) end}
	local opt = {LUI = lui, options = {args = {General = {args = {Welcome = {args = {}}}}}}}
	for _, method in ipairs({"Group", "InlineGroup", "Desc", "Execute"}) do
		opt[method] = function(_, data) return data end
	end
	function opt:CreateModuleOptions(name)
		local group = {args = {}}
		self.options.args[name] = group
		return group
	end
	local env = setmetatable({
		CopyTable = Copy, format = string.format,
		InCombatLockdown = function() return state.combat end,
		ReloadUI = function() state.reloads = state.reloads + 1 end,
		GetScreenWidth = function() return 1920 end,
		GetScreenHeight = function() return 1080 end,
		UIParent = {
			GetEffectiveScale = function() return 0.8 end,
			GetWidth = function() return 1920 end,
			GetHeight = function() return 1080 end,
		},
		C_AddOns = {
			IsAddOnLoaded = function(name) return state.loaded[name] or false end,
			LoadAddOn = function() return true end,
		},
	}, {__index = _G})
	env._G = env
	state.environment, state.options, state.artwork = env, opt, artwork
	function state:Load()
		local diagnostics = assert(loadfile("api/diagnostics.lua"))
		setfenv(diagnostics, env)("LUI", lui)
		local controlPanel = assert(loadfile("LUIOptions/CPanel.lua"))
		setfenv(controlPanel, env)("LUIOptions", opt)
		local chunk = assert(loadfile(file or "LUIOptions/RaidFrames.lua"))
		setfenv(chunk, env)("LUIOptions", opt)
		local group = opt.options.args["Control Panel"].args.AddonSetup.args[file and "ActionBars" or "RaidFrames"]
		self.button = group.args[addonID == "Bartender4" and "Bartender" or addonID]
	end
	return state, env
end

-- Grid2: preserve the chosen profile, custom statuses and other profiles;
-- update base and extra themes, including a previously limited 25-player layout.
do
	local state, env = Environment("Grid2")
	local active = "My Healer"
	local profiles = {[active] = {statuses = {myHot = {spell = 774}}}, Other = {marker = "keep"}}
	env.Grid2 = {db = {GetCurrentProfile = function() return active end}}
	local frame = {frameWidth = 110, extraThemes = {{frameWidth = 130, marker = "theme"}}}
	local layout = {layouts = {raid = "My 25"}, extraThemes = {{layouts = {raid = "My 25"}}}}
	env.Grid2Frame = {dba = {profile = frame}, db = {profile = frame.extraThemes[1]}}
	env.Grid2Layout = {dba = {profile = layout}, db = {profile = layout.extraThemes[1]}}
	state:Load()
	Check(state.button.confirm():find(active, 1, true), "confirmation must name the active Grid2 profile")
	state.button.func()
	state.button.func()
	Check(Count(profiles) == 2 and active == "My Healer", "Grid2 setup must not copy or switch profiles")
	Check(profiles[active].statuses.myHot.spell == 774 and profiles.Other.marker == "keep", "Grid2 healing data must survive")
	Check(layout.layouts.raid == "By Group" and layout.extraThemes[1].layouts.raid == "By Group", "all Grid2 themes must allow the full raid")
	Check(frame.extraThemes[1].marker == "theme", "Grid2 theme settings outside layout must survive")
	Check(state.artwork.db.profile.LUITextures.Raid.FitAnchor, "raid artwork must follow changing roster bounds")
	local before = state.reloads
	state.combat = true
	state.button.func()
	Check(state.reloads == before and state.button.disabled(), "combat must block setup")
	state.combat = false
	state.loaded.VuhDo = true
	Check(state.button.disabled(), "simultaneous raid-frame addons must block setup")
	state.loaded.VuhDo = nil
	state.button.confirm()
	active = "Other"
	state.button.func()
	Check(state.reloads == before, "a profile change after confirmation must cancel setup")
end

-- VuhDo: keep spells, indicators, secondary panels, and a single saved profile.
do
	local state, env = Environment("VuhDo")
	local stored = {NAME = "Imported Healer", ORIGINATOR_TOON = "Another player"}
	local profiles = {stored}
	env.VUHDO_CONFIG = {CURRENT_PROFILE = stored.NAME}
	env.VUHDO_PANEL_SETUP = {[1] = {MODEL = {}, SCALING = {}, POSITION = {}, PANEL_COLOR = {}, HOTS = {mine = 774}}, [2] = {marker = "keep"}}
	env.VUHDO_PLAYER_FULL_NAME = "Tester-Realm"
	env.VUHDO_SPELL_CONFIG = {left = "Rejuvenation"}
	env.VUHDO_INDICATOR_CONFIG = {debuff = "My Bouquet"}
	env.VUHDO_getProfileNamedCompressed = function(name)
		for index, profile in ipairs(profiles) do if profile.NAME == name then return index, profile end end
	end
	env.VUHDO_saveProfile = function(name)
		Check(stored.ORIGINATOR_TOON == env.VUHDO_PLAYER_FULL_NAME, "VuhDo must update an imported profile instead of opening its copy flow")
		stored.CONFIG = Copy(env.VUHDO_CONFIG)
		stored.PANEL_SETUP = Copy(env.VUHDO_PANEL_SETUP)
	end
	state:Load()
	state.button.func()
	state.button.func()
	Check(#profiles == 1 and stored.NAME == "Imported Healer", "VuhDo setup must reuse the selected profile")
	Check(#stored.PANEL_SETUP[1].MODEL.groups == 8, "VuhDo must include all eight groups")
	Check(env.VUHDO_SPELL_CONFIG.left == "Rejuvenation" and env.VUHDO_INDICATOR_CONFIG.debuff == "My Bouquet", "VuhDo bindings and indicators must survive")
	Check(stored.PANEL_SETUP[1].HOTS.mine == 774 and stored.PANEL_SETUP[2].marker == "keep", "VuhDo custom auras and secondary panels must survive")
	stored.HARDLOCKED = true
	Check(state.button.disabled(), "a hardlocked VuhDo profile must not be silently forked")
end

-- HealBot: update the active skin through its settings API, retaining healing data.
do
	local state, env = Environment("HealBot")
	local name = "My Skin"
	local groups = {[4] = {STATE = false, FRAME = 2}, [5] = {STATE = true, FRAME = 3}, [10] = {marker = "pet"}}
	env.Healbot_Config_Skins = {Current_Skin = name, HealGroups = {[name] = groups}, Icons = {[name] = {spell = 774}}}
	local fields = {}
	env.hbv_Skins_SetFrameVarSkin = function(value, skin, category, key, frame)
		assert(skin == name and frame == 1)
		fields[category] = fields[category] or {}
		fields[category][key] = value
	end
	env.hbv_Skins_SetVarSkin = function() end
	state:Load()
	state.button.func()
	state.button.func()
	Check(env.Healbot_Config_Skins.Current_Skin == name and Count(env.Healbot_Config_Skins.HealGroups) == 1, "HealBot must reuse the current skin")
	Check(groups[4].FRAME == 1 and groups[5].STATE and groups[5].FRAME == 1, "HealBot must include party and complete raid rosters")
	Check(fields.BarSort.RAIDORDER == 3 and fields.HealBar.NUMCOLS == 1, "HealBot must use group sorting and one group per column")
	Check(groups[10].marker == "pet" and env.Healbot_Config_Skins.Icons[name].spell == 774, "HealBot pet and aura settings must survive")
end

-- Danders: keep profile identity and click-casting; include large-raid layouts
-- without dropping their conditions or per-layout aura settings.
do
	local state, env = Environment("DandersFrames")
	local profile = {raid = {auraDesigner = {spell = 774}}, party = {marker = "keep"},
		raidAutoProfiles = {enabled = true, instanced = {profiles = {{minSize = 26, overrides = {raidGroupVisible = {true}, auraSize = 15}}}}}}
	env.DandersFramesDB_v2 = {currentProfile = "My Raid", profiles = {["My Raid"] = profile, Other = {marker = "keep"}}}
	env.DandersFrames = {db = profile, DeepCopy = function(_, value) return Copy(value) end,
		GetCurrentProfile = function() return "My Raid" end,
		SaveCurrentProfile = function(self) env.DandersFramesDB_v2.profiles["My Raid"] = Copy(self.db) end}
	state:Load()
	state.button.func()
	state.button.func()
	local stored = env.DandersFramesDB_v2.profiles["My Raid"]
	local automatic = stored.raidAutoProfiles.instanced.profiles[1]
	Check(Count(env.DandersFramesDB_v2.profiles) == 2, "Danders setup must not create profiles")
	Check(#stored.raid.raidGroupVisible == 8 and #automatic.overrides.raidGroupVisible == 8, "Danders base and automatic layouts must include group 8")
	Check(automatic.minSize == 26 and automatic.overrides.auraSize == 15 and stored.raid.auraDesigner.spell == 774, "Danders conditions and aura indicators must survive")
	Check(stored.party.marker == "keep" and env.DandersFramesDB_v2.profiles.Other.marker == "keep", "Danders party and other profiles must survive")
end

-- Both action-bar setups must update the selected profile repeatedly without
-- calling CopyProfile/SetProfile, which would reintroduce profile accumulation.
for _, addonID in ipairs({"Bartender4", "Dominos"}) do
	local state, env = Environment(addonID, "LUIOptions/ActionBars.lua")
	local db = {profile = {modules = {ActionBars = true}}, GetCurrentProfile = function() return "My Bars" end,
		SetProfile = function() error("unexpected profile creation") end,
		CopyProfile = function() error("unexpected profile copy") end}
	if addonID == "Bartender4" then
		local bars = {db = {profile = {actionbars = {[1] = {position = {}}, [6] = {position = {}}}}}}
		env.Bartender4 = {db = db, CONFIG_VERSION = 1, GetModule = function() return bars end, UpdateModuleConfigs = function() end}
	else
		local bar = setmetatable({}, {__index = function() return function() end end})
		env.Dominos = {db = db, Frame = {Get = function() return bar end}, SetNumButtons = function() end}
	end
	state:Load()
	state.button.func()
	state.button.func()
	Check(db:GetCurrentProfile() == "My Bars", addonID.." must update the selected profile")
	local events = {}
	env.LUIDiagnostics = {IsRecording = function() return true end,
		Breadcrumb = function(_, event, detail) events[#events + 1] = {event, detail} end}
	state.button.func()
	Check(#events == 2 and events[1][1] == "ADDON_SETUP_STARTED"
		and events[2][1] == "ADDON_SETUP_COMPLETED" and events[2][2] == addonID,
		addonID.." must record setup progress only when diagnostics is already active")
	if addonID == "Bartender4" then
		events = {}
		env.Bartender4.UpdateModuleConfigs = function() error("fixture failure") end
		local ok = pcall(state.button.func)
		Check(not ok and #events == 1 and events[1][1] == "ADDON_SETUP_STARTED",
			"a failing setup must remain visible to the native error handler without claiming completion")
	end
end

print("Addon setup checks passed: "..passed)
