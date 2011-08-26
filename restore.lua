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

-- Local variables.
local db
local backup
local stack
local mismatches

-- Localized functions.
local tconcat, pairs, print, type = table.concat, pairs, print, type

local function Apply(dest, source)
	local dt, st
	for k, v in pairs(dest) do
		if source[k] ~= nil then
			-- Push stack.
			stack[#stack + 1] = k

			-- Check value types are the same.
			dt, st = type(v), type(source[k])
			if dt ~= st then
				-- Print mismatch error with db stack. (i.e. db.children.Cooldown.profile.Enable).
				mismatches = mismatches + 1
				print("|c0090ffffLUI: |cffff0000Restore:|r Value skipped because of type mismatch: [", dt, "] ~= [", st, "]; Stack =", tconcat(stack, "."))
			else
				-- Apply backup values.
				if dt == "table" then
					Apply(dest[k], source[k])
				else
					dest[k] = source[k]
				end
			end

			-- Pop stack.
			stack[#stack] = nil
		end
	end
end

local function Get(source, dest)
	for k, v in pairs(source) do
		-- Get values.
		if type(v) == "table" then
			dest[k] = {}
			Get(v, dest[k])
		else
			dest[k] = v
		end
	end
end

local function Set(dest, source)
	for k, v in pairs(dest) do
		if source[k] ~= nil then
			-- Force apply backup values.
			if type(source[k]) == "table" then
				if not type(v) == "table" then
					dest[k] = source[k]
				else
					Set(dest[k], source[k])
				end
			else
				dest[k] = source[k]
			end
		end
	end
end

local function Backup()
	-- Get current db.
	db = LUI.db

	-- Get backups location.
	backup = {}
	LUICONFIG = LUICONFIG or {}
	LUICONFIG.BACKUP = backup

	-- Backup old profiles.
	for k, v in pairs(db.profile) do
		backup[k] = {}
		Get(v, backup[k])
	end

	-- Backup children.
	backup.children = {}
	local child = backup.children
	for k, v in pairs(db.children) do
		-- Get child profile and realm setting.
		child[k] = {profile = {}}
		Get(v.profile, child[k].profile)

		if v.realm then
			child[k].realm = {}
			Get(v.realm, child[k].realm)
		end
	end

	print("|c0090ffffLUI:|r Backup of current profile complete.")
end

local function Reload()
	print("|cffffff00Please reload your interface with the pop up provided to avoid errors.")
	StaticPopup_Show("RELOAD_UI")
end

local function Restore()
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
	Apply(db.profile, backup)

	-- Restore children.
	stack = {"db", "children"}
	Apply(db.children, backup.children)

	print("|c0090ffffLUI:|r Restore of database has completed.", "Encountered", mismatches, " mismatches which have now been corrected.")
	Reload()
end

local function Revert()
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
	Set(db.profile, backup)

	-- Restore children.
	Set(db.children, backup.children)

	print("|c0090ffffLUI:|r Revert of database has completed.")
	StaticPopup_Show("RELOAD_UI")
end


SLASH_LUIBACKUP1 = "/luibackup"
SlashCmdList.LUIBACKUP = Backup

SLASH_LUIRESTORE1 = "/luirestore"
SlashCmdList.LUIRESTORE = Restore

SLASH_LUIREVERT1 = "/luirevert"
SlashCmdList.LUIREVERT = Revert