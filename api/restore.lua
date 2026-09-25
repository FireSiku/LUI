--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: restore.lua
	Description: Profile backup and restore tools.
	
	Notes:
		Creates a backup of current database settings,
		resets the active profile to current defaults,
		then restores only settings that are used.
]]


-- External references.
---@class LUIAddon
local LUI = select(2, ...)

-- Create restorer namespace.
LUI.Restore = LUI.Restore or {}
local module = LUI.Restore

-- Localized functions.
local tconcat, pairs, print, tonumber, tostring, type = table.concat, pairs, print, tonumber, tostring, type

-- Local variables.
local stack
local mismatches

local function GetBackup()
	return LUI.db.global.ProfileBackups[LUI.db:GetCurrentProfile()]
end

function module.Apply(dest, source)
	local dt, st
	for k, sv in pairs(source) do
		-- Looking up the destination also resolves AceDB's lazy wildcard
		-- defaults, such as the enabled state of individual modules.
		local v = dest[k]
		if v ~= nil then
			-- Push stack.
			stack[#stack + 1] = k

			-- Create a local temp of source[k] so that converts don't effect our backup.

			-- Check value types are the same.
			dt, st = type(v), type(sv)

			-- Try to convert.
			if dt == "number" and st == "string" then
				local num = tonumber(sv)
				if num then
					-- Print mismatch conversion with the affected database path.
					mismatches = mismatches + 1
					print("|c0090ffffLUI: |cffffff00Restore:|r Value converted because of type mismatch: [", dt, "] ~= [", st, "]; Stack =", tconcat(stack, "."))

					-- Convert.
					st = dt
					sv = num
				end
			elseif dt == "string" and st == "number" then
				local str = tostring(sv)
				if str and str ~= "" and tonumber(str) == sv then
					-- Print mismatch conversion with the affected database path.
					mismatches = mismatches + 1
					print("|c0090ffffLUI: |cffffff00Restore:|r Value converted because of type mismatch: [", dt, "] ~= [", st, "]; Stack =", tconcat(stack, "."))

					-- Convert.
					st = dt
					sv = str
				end
			end

			if dt ~= st then
				-- Print mismatch error with the affected database path.
				mismatches = mismatches + 1
				print("|c0090ffffLUI: |cffff0000Restore:|r Value skipped because of type mismatch: [", dt, "] ~= [", st, "]; Stack =", tconcat(stack, "."))
			else
				-- Apply backup values.
				if dt == "table" then
					module.Apply(v, sv)
				else
					dest[k] = sv
				end
			end

			-- Pop stack.
			stack[#stack] = nil
		end
	end
end

function module.Get(source, dest)
	for k, v in pairs(source) do
		-- Get values.
		if type(v) == "table" then
			dest[k] = {}
			module.Get(v, dest[k])
		else
			dest[k] = v
		end
	end
end

function module.Set(dest, source)
	for k, v in pairs(source) do
		-- Exact reverts also retain custom keys absent from the defaults.
		-- Copy them instead of sharing a mutable table with the backup.
		if type(v) == "table" then
			if type(dest[k]) ~= "table" then dest[k] = {} end
			module.Set(dest[k], v)
		else
			dest[k] = v
		end
	end
end

local function IsEmptyTable(data)
	if type(data) ~= "table" then return end
	for k, v in pairs(data) do --luacheck: ignore
		return false
	end
	return true
end

local function RemoveDefaults(data, default)
	if type(data) ~= "table" or type(default) ~= "table" then return end

	for k, v in pairs(data) do
		local defaultValue = default[k]
		if defaultValue == nil then defaultValue = default["*"] end
		if defaultValue == nil then defaultValue = default["**"] end
		if type(v) == "table" then
			if type(defaultValue) == "table" then
				RemoveDefaults(data[k], defaultValue)
				if IsEmptyTable(data[k]) then data[k] = nil end
			end
		else
			if defaultValue == v then data[k] = nil end
		end
	end

	-- Check if data is now empty.
	if IsEmptyTable(data) then data = nil end

	-- Return processed data.
	return data
end

local function CaptureChildren(db)
	local children = {}
	for name, child in pairs(db.children or {}) do
		local captured = {profile = {}}
		children[name] = captured
		module.Get(child.profile, captured.profile)
		RemoveDefaults(captured.profile, child.defaults and child.defaults.profile)
		if child.realm then
			captured.realm = {}
			module.Get(child.realm, captured.realm)
			RemoveDefaults(captured.realm, child.defaults and child.defaults.realm)
		end
		if child.children then captured.children = CaptureChildren(child) end
	end
	return children
end

function module.Backup()
	local db = LUI.db
	local backup = {}
	-- The root contains scalar values as well as tables (notably dbVersion).
	module.Get(db.profile, backup)
	RemoveDefaults(backup, db.defaults and db.defaults.profile)
	backup.children = CaptureChildren(db)
	-- Publish only a completed snapshot, preserving the previous backup if
	-- collection fails partway through.
	db.global.ProfileBackups[db:GetCurrentProfile()] = backup

	print("|c0090ffffLUI:|r Backup of current profile complete.")
end

function module.Reload()
	-- Prompt a reloadui.
	print("|c0090ffffLUI: |cffffff00Please reload your interface with the pop up provided to avoid errors.")
	StaticPopup_Show("RELOAD_UI")
end

local function RestoreSnapshot(db, backup, restore)
	local profile = {}
	for key, value in pairs(backup) do
		if key ~= "children" then profile[key] = value end
	end
	restore(db.profile, profile)

	local function RestoreChildren(parent, children)
		if type(children) ~= "table" then return end
		-- Only AceDB may create database objects. Unknown namespaces in old
		-- backups must not be inserted as plain tables into db.children.
		for name, child in pairs(parent.children or {}) do
			local source = children[name]
			if type(source) == "table" then
				stack[#stack + 1] = name
				for _, scope in ipairs({"profile", "realm"}) do
					if type(source[scope]) == "table" then
						stack[#stack + 1] = scope
						restore(child[scope], source[scope])
						stack[#stack] = nil
					end
				end
				stack[#stack + 1] = "children"
				RestoreChildren(child, source.children)
				stack[#stack], stack[#stack - 1] = nil, nil
			end
		end
	end
	stack = {"db", "children"}
	RestoreChildren(db, backup.children)
end

function module.Restore()
	-- Get latest backup.
	local backup = GetBackup()
	if not backup then
		return print("|c0090ffffLUI:|r Restore failed because there was not an available backup. Create backup with '/luibackup'")
	end

	-- Get current db.
	local db = LUI.db

	-- Reset database to defaults.
	db:ResetProfile(nil, true)

	-- Reset restore error count.
	mismatches = 0

	-- Begin restore process.
	-- Restore from old profiles.
	stack = {"db", "profile"}
	RestoreSnapshot(db, backup, module.Apply)

	print("|c0090ffffLUI:|r Restore of database has completed.", mismatches > 0 and "Encountered", mismatches, "mismatches which have now been corrected." or "")
	module.Reload()
end

function module.Revert()
	-- Get latest backup.
	local backup = GetBackup()
	if not backup then
		return print("|c0090ffffLUI:|r Revert failed because there was not an available backup. Create backup with '/luibackup'")
	end

	-- Get current db.
	local db = LUI.db

	-- Reset database to defaults.
	db:ResetProfile(nil, true)

	-- Begin revert process.
	-- Revert from old profiles.
	RestoreSnapshot(db, backup, module.Set)

	print("|c0090ffffLUI:|r Revert of database has completed.")
	StaticPopup_Show("RELOAD_UI")
end


_G.SLASH_LUIBACKUP1 = "/luibackup"
_G.SlashCmdList.LUIBACKUP = module.Backup

_G.SLASH_LUIRESTORE1 = "/luirestore"
_G.SlashCmdList.LUIRESTORE = module.Restore

_G.SLASH_LUIREVERT1 = "/luirevert"
_G.SlashCmdList.LUIREVERT = module.Revert
