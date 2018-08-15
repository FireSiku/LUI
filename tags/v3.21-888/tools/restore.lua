--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: restore.lua
	Description: Experimental database tools.
	
	Notes:
		Creates a backup of current database settings,
		invokes a complete reset to defaults (which should remove un-wanted old corruptions... hopefully),
		then restores only settings that are used.
]]


-- External references.
local addonname, LUI = ...

-- Create restorer namespace.
LUI.Restore = LUI.Restore or {}
local module = LUI.Restore

-- Localized functions.
local tconcat, pairs, print, tonumber, tostring, type = table.concat, pairs, print, tonumber, tostring, type

-- Local variables.
local stack
local mismatches

function module.Apply(dest, source)
	local dt, st
	for k, v in pairs(dest) do
		if source[k] ~= nil then
			-- Push stack.
			stack[#stack + 1] = k

			-- Create a local temp of source[k] so that converts don't effect our backup.
			local sv = source[k]

			-- Check value types are the same.
			dt, st = type(v), type(sv)

			-- Try to convert.
			if dt == "number" and st == "string" then
				local num = tonumber(sv)
				if num then
					-- Print mismatch conversion with db stack. (i.e. db.children.Cooldown.profile.Enable).
					mismatches = mismatches + 1
					print("|c0090ffffLUI: |cffffff00Restore:|r Value converted because of type mismatch: [", dt, "] ~= [", st, "]; Stack =", tconcat(stack, "."))

					-- Convert.
					st = dt
					sv = num
				end
			elseif dt == "string" and st == "number" then
				local str = tostring(sv)
				if str and str ~= "" and tonumber(str) == sv then
					-- Print mismatch conversion with db stack. (i.e. db.children.Cooldown.profile.Enable).
					mismatches = mismatches + 1
					print("|c0090ffffLUI: |cffffff00Restore:|r Value converted because of type mismatch: [", dt, "] ~= [", st, "]; Stack =", tconcat(stack, "."))

					-- Convert.
					st = dt
					sv = str
				end
			end

			if dt ~= st then
				-- Print mismatch error with db stack. (i.e. db.children.Cooldown.profile.Enable).
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
	for k, v in pairs(dest) do
		if source[k] ~= nil then
			-- Force apply backup values.
			if type(source[k]) == "table" then
				if not type(v) == "table" then
					dest[k] = source[k]
				else
					module.Set(dest[k], source[k])
				end
			else
				dest[k] = source[k]
			end
		end
	end
end

local function IsEmptyTable(data)
	if type(data) ~= "table" then return end
	for k, v in pairs(data) do
		return false
	end
	return true
end

local function RemoveDefaults(data, default)
	if type(data) ~= "table" or type(default) ~= "table" then return end

	for k, v in pairs(data) do
		if type(v) == "table" then
			if default[k] then
				RemoveDefaults(data[k], default[k])
				if IsEmptyTable(data[k]) then data[k] = nil end
			else
				data[k] = nil
			end
		else
			if default[k] == data[k] or default[k] == nil then data[k] = nil end
		end
	end

	-- Check if data is now empty.
	if IsEmptyTable(data) then data = nil end

	-- Return processed data.
	return data
end

function module.Backup()
	-- Get current db.
	local db = LUI.db

	-- Get backup location.
	local backup = {}
	--noinspection GlobalCreationOutsideO
	LUICONFIG = LUICONFIG or {}
	LUICONFIG.BACKUP = backup

	-- Collect old profiles.
	for k, v in pairs(db.profile) do
		backup[k] = {}
		module.Get(v, backup[k])

		-- Remove default values.
		backup[k] = RemoveDefaults(backup[k], db.defaults.profile[k])
	end

	-- Collect children.
	backup.children = {}
	local child = backup.children
	for k, v in pairs(db.children) do
		-- Get child profile and realm setting.
		child[k] = {profile = {}}
		module.Get(v.profile, child[k].profile)

		-- Remove default values.
		child[k].profile = RemoveDefaults(child[k].profile, v.defaults.profile)

		if v.realm then
			child[k].realm = {}
			module.Get(v.realm, child[k].realm)

			-- Remove default values.
			child[k].realm = RemoveDefaults(child[k].realm, v.defaults.realm)
		end
	end

	print("|c0090ffffLUI:|r Backup of current profile complete.")
end

function module.Reload()
	-- Prompt a reloadui.
	print("|c0090ffffLUI: |cffffff00Please reload your interface with the pop up provided to avoid errors.")
	StaticPopup_Show("RELOAD_UI")
end

function module.Restore()
	-- Get latest backup.
	local backup = LUICONFIG.BACKUP
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
	module.Apply(db.profile, backup)

	-- Restore children.
	stack = {"db", "children"}
	module.Apply(db.children, backup.children)

	print("|c0090ffffLUI:|r Restore of database has completed.", mismatches > 0 and "Encountered", mismatches, "mismatches which have now been corrected." or "")
	module.Reload()
end

function module.Revert()
	-- Get latest backup.
	local backup = LUICONFIG.BACKUP
	if not backup then
		return print("|c0090ffffLUI:|r Revert failed because there was not an available backup. Create backup with '/luibackup'")
	end

	-- Get current db.
	local db = LUI.db

	-- Reset database to defaults.
	db:ResetProfile(nil, true)

	-- Begin revert process.
	-- Revert from old profiles.
	module.Set(db.profile, backup)

	-- Restore children.
	module.Set(db.children, backup.children)

	print("|c0090ffffLUI:|r Revert of database has completed.")
	StaticPopup_Show("RELOAD_UI")
end


SLASH_LUIBACKUP1 = "/luibackup"
SlashCmdList.LUIBACKUP = module.Backup

SLASH_LUIRESTORE1 = "/luirestore"
SlashCmdList.LUIRESTORE = module.Restore

SLASH_LUIREVERT1 = "/luirevert"
SlashCmdList.LUIREVERT = module.Revert
