-- Profile ownership for optional addon layouts. Only LUI-created copies may
-- receive a setup; existing profiles are sources, never implicit targets.
local _, Opt = ...
local LUI = Opt.LUI
local Profiles = {}
Opt.SetupProfiles = Profiles

local function Records(id, create)
	local global = LUI.db.global
	if create then
		global.AddonSetupProfiles = global.AddonSetupProfiles or {}
		global.AddonSetupProfiles[id] = global.AddonSetupProfiles[id] or {}
	end
	return global.AddonSetupProfiles and global.AddonSetupProfiles[id]
end

local function Shorten(text, limit)
	local cut = math.min(#text, limit)
	-- Keep UTF-8 names intact when making room for a collision suffix.
	while cut > 0 do
		local byte = text:byte(cut + 1)
		if not byte or byte < 128 or byte >= 192 then break end
		cut = cut - 1
	end
	return text:sub(1, cut)
end

local function Label(text)
	return tostring(text):gsub("|", "||")
end

function Profiles:Plan(id, adapter)
	local source = adapter.current()
	if type(source) ~= "string" or source == "" or not adapter.exists(source) then
		return nil, "Save and select a profile in the addon before running LUI setup."
	end
	local records = Records(id)
	if records then
		for original, target in pairs(records) do
			if target == source and original ~= target then
				if adapter.writable and not adapter.writable(target) then
					return nil, "Unlock or save the LUI setup profile locally in the addon before updating it."
				end
				return {source = source, original = original, target = target, create = false}
			end
		end
		local target = records[source]
		if type(target) == "string" and target ~= source and adapter.exists(target) then
			if adapter.writable and not adapter.writable(target) then
				return nil, "Unlock or save the LUI setup profile locally in the addon before updating it."
			end
			return {source = source, original = source, target = target, create = false}
		end
	end
	local base = Shorten("LUI - " .. source:gsub("[%c]", " "), 40)
	local target, index = base, 1
	while adapter.exists(target) do
		index = index + 1
		if index > 1000 then return nil, "Choose a different source profile before running setup." end
		local suffix = " (" .. index .. ")"
		target = Shorten(base, 40 - #suffix) .. suffix
	end
	return {source = source, original = source, target = target, create = true}
end

function Profiles:Confirmation(label, plan, changes)
	local action = plan.create
		and format("Create and select %s profile '%s' as a copy of '%s'?", label, Label(plan.target), Label(plan.source))
		or format("Update and select the existing %s LUI setup profile '%s'?", label, Label(plan.target))
	return action .. "\n\n" .. changes .. "\n\nOriginal profile '" .. Label(plan.original)
		.. "' is kept. Select it in the addon to return to your previous layout."
end

function Profiles:Run(id, adapter, confirmed, apply)
	if InCombatLockdown() then return nil, "Addon setup is unavailable in combat." end
	local current = self:Plan(id, adapter)
	if not confirmed or not current or current.source ~= confirmed.source
		or current.original ~= confirmed.original or current.target ~= confirmed.target
		or current.create ~= confirmed.create then
		return nil, "The selected profile or setup target changed. Review and confirm setup again."
	end
	local ok, result, message = pcall(function()
		if confirmed.create then
			if adapter.copy(confirmed.source, confirmed.target) == false then
				return false, "The addon could not copy the current profile."
			end
		elseif confirmed.source ~= confirmed.target then
			adapter.select(confirmed.target)
		end
		if adapter.current() ~= confirmed.target or not adapter.exists(confirmed.target) then
			return false, "The addon did not activate the LUI setup profile."
		end
		-- Remember a successfully created copy even if its layout application
		-- fails. Retrying must not create a growing list of duplicate profiles.
		Records(id, true)[confirmed.original] = confirmed.target
		return apply(confirmed.target)
	end)
	if not ok or result == false then
		-- A failed attempt can leave only the disposable copy partially set up.
		-- Return through the addon's own profile boundary, never rewrite source.
		local restored = pcall(adapter.select, confirmed.source)
		if not restored or adapter.current() ~= confirmed.source then
			return nil, "Setup stopped. Your original profile is kept; select it in the addon to return to it."
		end
		return nil, ok and message or "Setup stopped because the addon reported an error. Your previous profile was selected again."
	end
	return confirmed.target
end

function Profiles:Ace(db)
	if not db or type(db.GetCurrentProfile) ~= "function" or type(db.GetProfiles) ~= "function"
		or type(db.SetProfile) ~= "function" or type(db.CopyProfile) ~= "function" then return end
	local function Exists(name)
		for _, value in ipairs(db:GetProfiles()) do if value == name then return true end end
		return false
	end
	return {
		current = function() return db:GetCurrentProfile() end,
		exists = Exists,
		select = function(name) db:SetProfile(name) end,
		copy = function(source, target)
			-- AceDB's CopyProfile writes INTO the active profile, so switch to
			-- the new, collision-checked destination before copying the source.
			if Exists(target) then return false end
			db:SetProfile(target)
			db:CopyProfile(source)
		end,
	}
end
