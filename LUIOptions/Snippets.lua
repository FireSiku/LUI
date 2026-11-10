-- Share selected LUI settings as data, independently of full-profile imports.
local _, Opt = ...
local LUI = Opt.LUI
local Copy, Capture = Opt.ProfileTransfer.Copy, Opt.ProfileTransfer.Capture
local PREFIX, KIND, FORMAT = "!LUISnippet:1!", "LUI_SNIPPET", 1
local MAX_TEXT, MAX_VALUES = 2000000, 100000
local BACKUP_KEY = "LayoutSnippetBackup"
local Snippets = {}
Opt.Snippets = Snippets

-- Keep Themes separate: applying a theme can recolor otherwise unselected
-- modules. Artwork carries its actual saved colors, not global theme storage.
local sections = {
	Artwork = "Artwork", Bags = "Bags", Chat = "Chat",
	Colors = "Colors (shared palette)", ["Experience Bars"] = "Experience Bars",
	Infotext = "Infotext", Micromenu = "Micromenu", Minimap = "Minimap",
	["Mirror Bar"] = "Mirror Bar", Tooltip = "Tooltip",
	["UI Elements"] = "UI Elements", Unitframes = "Unitframes",
}

local function Trim(value)
	return type(value) == "string" and value:match("^%s*(.-)%s*$") or ""
end

local function Client()
	return LUI.IsForever and "Forever" or "Retail"
end

local function Label(value)
	return tostring(value):gsub("[%c]", " "):gsub("|", "||")
end

local function CheckData(value, seen, depth, budget)
	budget.count = budget.count + 1
	if budget.count > MAX_VALUES or depth > 30 then return false end
	local kind = type(value)
	if kind == "number" then return value == value and value ~= math.huge and value ~= -math.huge end
	if kind == "nil" or kind == "boolean" or kind == "string" then return true end
	if kind ~= "table" or seen[value] then return false end
	seen[value] = true
	for key, child in pairs(value) do
		local keyType = type(key)
		if (keyType ~= "number" and keyType ~= "string" and keyType ~= "boolean")
			or not CheckData(key, seen, depth + 1, budget)
			or not CheckData(child, seen, depth + 1, budget) then return false end
	end
	seen[value] = nil
	return true
end

local function CheckStorage(storage)
	if type(storage) ~= "table" or type(storage.profile) ~= "table" then return false end
	for key in pairs(storage) do
		if key ~= "profile" and key ~= "namespaces" then return false end
	end
	if storage.namespaces ~= nil then
		if type(storage.namespaces) ~= "table" then return false end
		for name, child in pairs(storage.namespaces) do
			if type(name) ~= "string" or not CheckStorage(child) then return false end
		end
	end
	return true
end

local function CheckSections(data)
	if type(data) ~= "table" or not next(data)
		or not CheckData(data, {}, 0, {count = 0}) then return false end
	for name, storage in pairs(data) do
		if not sections[name] or not CheckStorage(storage) then return false end
	end
	return true
end

function Snippets:GetSections()
	local available = {}
	for name, label in pairs(sections) do
		if LUI.db:GetNamespace(name, true) then available[name] = label end
	end
	return available
end

function Snippets:Export(selected, name)
	name = Trim(name)
	if name == "" or #name > 100 or name:find("[%c]") then
		return nil, "Enter a short snippet name."
	end
	local profile = LUI.db:GetCurrentProfile()
	local data = {}
	for section, included in pairs(selected) do
		if included then
			local db = sections[section] and LUI.db:GetNamespace(section, true)
			if not db then return nil, "A selected section is unavailable." end
			data[section] = Capture(db.sv, profile)
		end
	end
	if not CheckSections(data) then return nil, "Select sections containing supported LUI settings." end
	local payload = {
		kind = KIND, format = FORMAT, name = name, client = Client(),
		addonVersion = C_AddOns.GetAddOnMetadata("LUI", "Version") or "unknown",
		sections = data,
	}
	local text = PREFIX .. LibStub("AceSerializer-3.0"):Serialize(payload)
	if #text > MAX_TEXT then return nil, "The selected settings are too large. Share fewer sections." end
	return text
end

function Snippets:Read(text)
	text = Trim(text)
	if #text > MAX_TEXT or text:sub(1, #PREFIX) ~= PREFIX then
		return nil, "Paste a complete LUI snippet string. Full profiles use Profile Import / Export."
	end
	local ok, valid, payload = pcall(function()
		return LibStub("AceSerializer-3.0"):Deserialize(text:sub(#PREFIX + 1))
	end)
	if not ok or not valid or type(payload) ~= "table"
		or payload.kind ~= KIND or payload.format ~= FORMAT
		or type(payload.name) ~= "string" or #payload.name > 100
		or Trim(payload.name) == "" or payload.name:find("[%c]")
		or (payload.client ~= "Retail" and payload.client ~= "Forever")
		or type(payload.addonVersion) ~= "string" or #payload.addonVersion > 100
		or not CheckSections(payload.sections) then
		return nil, "The LUI snippet is invalid, damaged or uses an unsupported format."
	end
	return payload
end

-- Use registered AceDB namespaces, never create a namespace from imported data.
-- Preserve module switches while replacing the chosen settings sections.
local function Prepare(db, captured, writes)
	local before = db.profile
	local replacement = Copy(captured.profile)
	for _, key in ipairs({"Enable", "modules", "Modules"}) do
		replacement[key] = Copy(before[key])
	end
	writes[#writes + 1] = {target = before, replacement = replacement}
	for name, child in pairs(captured.namespaces or {}) do
		-- AceDB children expose a restricted method set. LUI also uses the
		-- parent API with an explicit child receiver for nested module storage.
		local childDB = LUI.db.GetNamespace(db, name, true)
		if not childDB then return false end
		if not Prepare(childDB, child, writes) then return false end
	end
	-- Absent child settings represent defaults, not the recipient's old values.
	for name, childDB in pairs(db.children or {}) do
		if not captured.namespaces or not captured.namespaces[name] then
			if not Prepare(childDB, {profile = {}}, writes) then return false end
		end
	end
	return true
end

local function PrepareSections(data, selected)
	if not CheckSections(data) then return nil, "The snippet contains unsupported settings." end
	local writes, before = {}, {}
	local profile = LUI.db:GetCurrentProfile()
	for section, included in pairs(selected) do
		if included then
			local db = sections[section] and data[section] and LUI.db:GetNamespace(section, true)
			if not db then return nil, "A selected section is not available in this snippet or client." end
			before[section] = Capture(db.sv, profile)
			if not Prepare(db, data[section], writes) then
				return nil, "A selected section needs a LUI component that is unavailable in this client."
			end
		end
	end
	if not next(before) then return nil, "Select at least one section to import." end
	return writes, before
end

local function Commit(writes)
	-- Keep AceDB's live table identity and defaults metadata. Replacing only
	-- SavedVariables would leave its cached profile pointing to the old table.
	for _, write in ipairs(writes) do
		for key in pairs(write.target) do write.target[key] = nil end
		for key, value in pairs(write.replacement) do write.target[key] = value end
	end
end

function Snippets:Apply(payload, selected, expectedProfile)
	if InCombatLockdown() then return nil, "Snippets cannot be imported while in combat." end
	local profile = LUI.db:GetCurrentProfile()
	if profile ~= expectedProfile then return nil, "The active profile changed. Review the import again." end
	local writes, before = PrepareSections(payload.sections, selected)
	if not writes then return nil, before end
	LUI.db.global[BACKUP_KEY] = {format = FORMAT, profile = profile, sections = before}
	Commit(writes)
	ReloadUI()
	return true
end

function Snippets:CanRestore()
	local backup = LUI.db.global[BACKUP_KEY]
	return type(backup) == "table" and backup.format == FORMAT
		and backup.profile == LUI.db:GetCurrentProfile() and CheckSections(backup.sections)
end

function Snippets:Restore(expectedProfile)
	if InCombatLockdown() then return nil, "Snippets cannot be restored while in combat." end
	if LUI.db:GetCurrentProfile() ~= expectedProfile or not self:CanRestore() then
		return nil, "There is no snippet backup for the active profile."
	end
	local backup = LUI.db.global[BACKUP_KEY]
	local selected = {}
	for section in pairs(backup.sections) do selected[section] = true end
	local writes, message = PrepareSections(backup.sections, selected)
	if not writes then return nil, message end
	Commit(writes)
	LUI.db.global[BACKUP_KEY] = nil
	ReloadUI()
	return true
end

local exportName, exportText, importText = "My LUI layout", "", ""
local exportSelected, importSelected = {Unitframes = true}, {}
local incoming, reviewText = nil, "Paste a snippet and click Read Snippet."
local confirmedImport, confirmedRestore

local function Notify()
	Opt.ACR:NotifyChange("LUIOptions")
end

local function Run(method, ...)
	local ok, result, message = pcall(method, Snippets, ...)
	if not ok then message = "The settings could not be processed." end
	if not ok or not result then LUI:Print(message) end
	return ok and result
end

local function SelectedNames(selected)
	local names = {}
	for section, included in pairs(selected) do
		if included then names[#names + 1] = sections[section] end
	end
	table.sort(names)
	return table.concat(names, ", ")
end

function Opt:CreateSnippetOptions()
	return {
		name = "Layout Snippets", type = "group", order = 91, childGroups = "tab",
		args = {
			Share = {name = "Share", type = "group", order = 1, args = {
				Description = {type = "description", order = 1, width = "full",
					name = "Share selected LUI sections, including their saved appearance and positions. External addon profiles are separate. Colors shares the common palette; individual colors travel with their own section."},
				Name = {name = "Snippet Name", type = "input", order = 2, width = "full",
					get = function() return exportName end,
					set = function(_, value) exportName, exportText = value, "" end},
				Sections = {name = "Include Sections", type = "multiselect", order = 3,
					values = function() return Snippets:GetSections() end,
					get = function(_, key) return exportSelected[key] end,
					set = function(_, key, value) exportSelected[key], exportText = value, "" end},
				Generate = {name = "Generate Snippet", type = "execute", order = 4,
					func = function()
						exportText = Run(Snippets.Export, exportSelected, exportName) or ""
						Notify()
					end},
				String = {name = "Snippet String", type = "input", order = 5, width = "full", multiline = 8,
					desc = "Copy the entire string with Ctrl+A, Ctrl+C.",
					get = function() return exportText end,
					set = function(_, value) exportText = value end},
			}},
			Import = {name = "Import", type = "group", order = 2, args = {
				Description = {type = "description", order = 1, width = "full",
					name = "Read a snippet, then choose which sections to replace in your active profile. Module switches are kept. One backup of the latest snippet import is retained. Shared palette changes also affect other elements using those colors."},
				String = {name = "Snippet String", type = "input", order = 2, width = "full", multiline = 6,
					get = function() return importText end,
					set = function(_, value)
						importText, incoming, confirmedImport = value, nil, nil
						importSelected, reviewText = {}, "Click Read Snippet to inspect this string."
					end},
				Read = {name = "Read Snippet", type = "execute", order = 3,
					func = function()
						incoming = Run(Snippets.Read, importText)
						importSelected, confirmedImport = {}, nil
						if incoming then
							local available = Snippets:GetSections()
							for name in pairs(incoming.sections) do importSelected[name] = available[name] and true or false end
							reviewText = Label(incoming.name) .. " | LUI " .. Label(incoming.addonVersion) .. " | " .. incoming.client
							if incoming.client ~= Client() then reviewText = reviewText .. "\nCreated for another client; check frame availability and positions after importing." end
						else reviewText = "The string could not be read. Check the message in chat." end
						Notify()
					end},
				Review = {type = "description", order = 4, width = "full", fontSize = "medium",
					name = function() return reviewText end},
				Sections = {name = "Import Sections", type = "multiselect", order = 5,
					values = function()
						local values = {}
						local available = Snippets:GetSections()
						if incoming then
							for name in pairs(incoming.sections) do
								values[name] = sections[name] .. (available[name] and "" or " (unavailable)")
							end
						end
						return values
					end,
					get = function(_, key) return importSelected[key] end,
					set = function(_, key, value) importSelected[key], confirmedImport = value, nil end},
				Apply = {name = "Apply to Current Profile", type = "execute", order = 6,
					disabled = function() return InCombatLockdown() or not incoming or SelectedNames(importSelected) == "" end,
					confirm = function()
						confirmedImport = {profile = LUI.db:GetCurrentProfile(), payload = incoming, selected = Copy(importSelected)}
						return "Replace " .. SelectedNames(importSelected) .. " in profile '" .. Label(confirmedImport.profile) .. "' and reload the UI?"
					end,
					func = function()
						local request = confirmedImport
						confirmedImport = nil
						if request and request.payload == incoming then
							Run(Snippets.Apply, incoming, request.selected, request.profile)
						else LUI:Print("Review and confirm the snippet import again.") end
					end},
			}},
			Restore = {name = "Restore", type = "group", order = 3, args = {
				Description = {type = "description", order = 1, width = "full",
					name = function()
						local text = "Restore the affected sections to their state before the latest snippet import. Other sections stay as they are. This backup is replaced by the next import and can only be restored in the same profile."
						local backup = LUI.db.global[BACKUP_KEY]
						if type(backup) == "table" and type(backup.profile) == "string" then
							text = text .. "\nLast backup: profile '" .. Label(backup.profile) .. "'."
						end
						return text
					end},
				Restore = {name = "Undo Last Snippet Import", type = "execute", order = 2,
					disabled = function() return InCombatLockdown() or not Snippets:CanRestore() end,
					confirm = function()
						confirmedRestore = LUI.db:GetCurrentProfile()
						return "Restore the last snippet backup for profile '" .. Label(confirmedRestore) .. "' and reload the UI?"
					end,
					func = function()
						local profile = confirmedRestore
						confirmedRestore = nil
						Run(Snippets.Restore, profile)
					end},
			}},
		},
	}
end
