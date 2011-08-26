--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: restore.lua
	Description: Experimental database tools.
	
	Notes:
		Creates a backup of current database settings,
		invokes a complete reset to defaults (which should remove un-wanted old corruptions... hopefully),
		then resotres only settings that are used.
]]


-- External references.
local addonname, LUI = ...

-- Create restorer namespace.
LUI.Restore = LUI.Restore or {}
local module = LUI.Restore

-- Localized functions.
local tconcat, pairs, print, tonumber, tostring, type = table.concat, pairs, print, tonumber, tostring, type

-- Local variables.
local db
local backup
local stack
local mismatches

function module.Apply(dest, source)
	local dt, st
	for k, v in pairs(dest) do
		if source[k] ~= nil then
			-- Push stack.
			stack[#stack + 1] = k

			-- Check value types are the same.
			dt, st = type(v), type(source[k])

			-- Try to convert.
			if dt == "number" and st == "string" then
				local num = tonumber(source[k])
				if num then
					-- Print mismatch convertion with db stack. (i.e. db.children.Cooldown.profile.Enable).
					mismatches = mismatches + 1
					print("|c0090ffffLUI: |cffffff00Restore:|r Value converted because of type mismatch: [", dt, "] ~= [", st, "]; Stack =", tconcat(stack, "."))

					-- Convert.
					st = dt
					source[k] = num
				end
			elseif dt == "string" and st == "number" then
				local str = tostring(source[k])
				if str and str ~= "" and tonumber(str) == source[k] then
					-- Print mismatch convertion with db stack. (i.e. db.children.Cooldown.profile.Enable).
					mismatches = mismatches + 1
					print("|c0090ffffLUI: |cffffff00Restore:|r Value converted because of type mismatch: [", dt, "] ~= [", st, "]; Stack =", tconcat(stack, "."))

					-- Convert.
					st = dt
					source[k] = str
				end
			end

			if dt ~= st then
				-- Print mismatch error with db stack. (i.e. db.children.Cooldown.profile.Enable).
				mismatches = mismatches + 1
				print("|c0090ffffLUI: |cffff0000Restore:|r Value skipped because of type mismatch: [", dt, "] ~= [", st, "]; Stack =", tconcat(stack, "."))
			else
				-- Apply backup values.
				if dt == "table" then
					module.Apply(dest[k], source[k])
				else
					dest[k] = source[k]
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

function module.Backup()
	-- Get current db.
	db = LUI.db

	-- Get backups location.
	backup = {}
	LUICONFIG = LUICONFIG or {}
	LUICONFIG.BACKUP = backup

	-- Backup old profiles.
	for k, v in pairs(db.profile) do
		backup[k] = {}
		module.Get(v, backup[k])
	end

	-- Backup children.
	backup.children = {}
	local child = backup.children
	for k, v in pairs(db.children) do
		-- Get child profile and realm setting.
		child[k] = {profile = {}}
		module.Get(v.profile, child[k].profile)

		if v.realm then
			child[k].realm = {}
			module.Get(v.realm, child[k].realm)
		end
	end

	print("|c0090ffffLUI:|r Backup of current profile complete.")
end

function module.Reload()
	-- Promote a reloadui.
	print("|c0090ffffLUI: |cffffff00Please reload your interface with the pop up provided to avoid errors.")
	StaticPopup_Show("RELOAD_UI")
end

function module.Restore()
	-- Get latest backup.
	backup = LUICONFIG.BACKUP
	if not backup then
		return print("|c0090ffffLUI: Restore failed because there was not an available backup. Create backup with '/luibackup'")
	end

	-- Get current db.
	db = LUI.db

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
	backup = LUICONFIG.BACKUP
	if not backup then
		return print("|c0090ffffLUI: Revert failed because there was not an available backup. Create backup with '/luibackup'")
	end
	
	-- Get current db.
	db = LUI.db

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