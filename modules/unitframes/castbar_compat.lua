-- Let Blizzard retain its cast/channel presentation in temporary action-bar
-- UIs (quests, vehicles, possession). Normal casts still use the LUI element.
-- Only event registrations owned by this adapter are changed. Native scripts,
-- action buttons, secure attributes, showCastbar flags and game rules stay native.
local LUI = select(2, ...)
local module = LUI:GetModule("Unitframes")
local owner, nativeStates, nativeSpecial
local scheduled = false
local eventNames = {
	"UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED",
	"UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_DELAYED",
	"UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_UPDATE", "UNIT_SPELLCAST_CHANNEL_STOP",
	"UNIT_SPELLCAST_EMPOWER_START", "UNIT_SPELLCAST_EMPOWER_UPDATE", "UNIT_SPELLCAST_EMPOWER_STOP",
	"UNIT_SPELLCAST_INTERRUPTIBLE", "UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "PLAYER_ENTERING_WORLD",
}
local queries = {"IsForbidden", "HasAnySecretAspect", "HasAnyForbiddenAspects", "HasAccessConstraints"}

local function IsSecret(value)
	return _G.issecretvalue and _G.issecretvalue(value)
end

local function Read(func, ...)
	if type(func) ~= "function" then return nil end
	local ok, value = pcall(func, ...)
	if ok and not IsSecret(value) then return value end
end

local function CanAccess(frame)
	if IsSecret(frame) or not frame then return false end
	for _, key in ipairs(queries) do
		local ok, query = pcall(function() return frame[key] end)
		if not ok or IsSecret(query) then return false end
		if query and Read(query, frame) ~= false then return false end
	end
	return true
end

local function SpecialUIActive()
	local api = _G.C_ActionBar
	local unknown = false
	for _, name in ipairs({"HasOverrideActionBar", "HasVehicleActionBar", "HasTempShapeshiftActionBar", "HasPossessBar"}) do
		local func = api and api[name] or _G[name]
		if type(func) == "function" then
			local value = Read(func)
			if value == true then return true end
			if value ~= false then unknown = true end
		end
	end
	if unknown then return nil end
	return false
end

local function Snapshot(frame, pet)
	if not CanAccess(frame) then return nil end
	local state = {frame = frame, events = {}}
	local function Capture(event)
		local ok, registered, unit1, unit2 = pcall(frame.IsEventRegistered, frame, event)
		if not ok or IsSecret(registered) or IsSecret(unit1) or IsSecret(unit2) then return false end
		state.events[event] = {registered = registered, unit1 = unit1, unit2 = unit2}
		return true
	end
	for _, event in ipairs(eventNames) do if not Capture(event) then return nil end end
	if pet and not Capture("UNIT_PET") then return nil end
	return state
end

local function RestoreParent(state)
	if not state.parent then return true end
	local frame = state.frame
	-- Do not undo a subsequent parent change made by Blizzard or another addon.
	if Read(frame.GetParent, frame) == UIParent then
		if not CanAccess(state.parent) then return false end
		frame:SetParent(state.parent)
	end
	state.parent = nil
	return true
end

local function SetNativeEvents(state, enabled)
	local frame = state.frame
	if not CanAccess(frame) then return false end
	if state.eventsEnabled ~= enabled then
		for event, registration in pairs(state.events) do
			-- Preserve registrations that were absent before LUI took ownership.
			if registration.registered then
				if enabled then
					if registration.unit1 and registration.unit1 ~= "" then
						if registration.unit2 then
							frame:RegisterUnitEvent(event, registration.unit1, registration.unit2)
						else
							frame:RegisterUnitEvent(event, registration.unit1)
						end
					else
						frame:RegisterEvent(event)
					end
				else
					frame:UnregisterEvent(event)
				end
			end
		end
		state.eventsEnabled = enabled
	end
	if not enabled then frame:Hide() end
	return true
end

local function RefreshNative(state)
	-- This is the same initialization event used by CastingBarMixin:SetUnit.
	-- Its native ShouldShowCastBar/UpdateShownState checks remain in force,
	-- including the OverlayPlayerCastingBar's ownership of the normal bar.
	if state.events.PLAYER_ENTERING_WORLD.registered and type(state.frame.OnEvent) == "function" then
		state.frame:OnEvent("PLAYER_ENTERING_WORLD")
	end
end

local function Sync()
	-- Reparenting an attached castbar can affect a protected player frame.
	-- Defer the entire transition, including the native initialization call.
	if InCombatLockdown() then return end
	if not owner and not nativeStates then return end
	if not nativeStates then
		local player = Snapshot(_G.PlayerCastingBarFrame)
		local pet = Snapshot(_G.PetCastingBarFrame, true)
		if not player or not pet then return end
		-- Another addon may already own the native bar. Keep the LUI fallback
		-- instead of suppressing it in favour of an inactive native frame.
		if not player.events.PLAYER_ENTERING_WORLD.registered
			or not player.events.UNIT_SPELLCAST_START.registered then return end
		nativeStates = {player, pet}
	end
	local player, pet = nativeStates[1], nativeStates[2]
	if not CanAccess(player.frame) or not CanAccess(pet.frame) then return end
	if not owner then
		if not RestoreParent(player) then return end
		SetNativeEvents(player, true)
		SetNativeEvents(pet, true)
		RefreshNative(player)
		RefreshNative(pet)
		nativeStates = nil
		nativeSpecial = false
		return
	end
	local special = SpecialUIActive()
	if special == nil then return end -- No branching on secret/unknown states.
	if special then
		-- An attached Blizzard bar otherwise inherits the disabled PlayerFrame's
		-- visibility. Preserve its anchors; detach only for this temporary UI.
		local parent = Read(player.frame.GetParent, player.frame)
		if parent == _G.PlayerFrame and not player.parent then
			if not CanAccess(parent) then return end
			player.parent = parent
			player.frame:SetParent(UIParent)
		end
	else
		if not RestoreParent(player) then return end
	end
	SetNativeEvents(player, special)
	SetNativeEvents(pet, false)
	if nativeSpecial ~= special then
		local wasSpecial = nativeSpecial
		nativeSpecial = special
		if special then
			owner.Castbar:Hide()
			RefreshNative(player)
		elseif wasSpecial and owner.Castbar.ForceUpdate then
			owner.Castbar:ForceUpdate()
		end
	end
end

local function ScheduleSync()
	Sync()
	-- OverrideActionBar may finish its native overlay transition after this
	-- event listener. Reconcile once next tick, without hooking its scripts.
	if not scheduled and _G.C_Timer then
		scheduled = true
		C_Timer.After(0, function() scheduled = false; Sync() end)
	end
end

function module:HandleBlizzardCastbar(element, enabled)
	if enabled then
		owner = element.__owner
	elseif owner == element.__owner then
		owner = nil
	end
	ScheduleSync()
	return true
end

function module:UsesBlizzardSpecialCastbar()
	return owner ~= nil and nativeSpecial == true
end

local watcher = CreateFrame("Frame")
for _, event in ipairs({"PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED", "ADDON_LOADED",
	"UPDATE_OVERRIDE_ACTIONBAR", "UPDATE_VEHICLE_ACTIONBAR", "UPDATE_POSSESS_BAR", "UPDATE_SHAPESHIFT_FORM",
	"UPDATE_BONUS_ACTIONBAR", "ACTIONBAR_PAGE_CHANGED",
	"UNIT_ENTERED_VEHICLE", "UNIT_EXITED_VEHICLE"}) do
	watcher:RegisterEvent(event)
end
watcher:SetScript("OnEvent", function() if owner or nativeStates then ScheduleSync() end end)

if _G.EventRegistry then
	EventRegistry:RegisterCallback("OverlayPlayerCastBar.OnHide", function()
		if owner or nativeStates then ScheduleSync() end
	end, watcher)
end
