---@class LUIAddon
local LUI = select(2, ...)
local OutOfCombatWrapper = {}

LibStub("AceEvent-3.0"):Embed(OutOfCombatWrapper)

local actionsToPerform = {}

local InCombatLockdown = _G.InCombatLockdown

OutOfCombatWrapper:RegisterEvent("PLAYER_REGEN_ENABLED", function()
	local pending = actionsToPerform
	actionsToPerform = {}
	for _, action in ipairs(pending) do
		action.func(unpack(action.args, 1, action.argCount))
	end
end)

local function runOnLeaveCombat(func, ...)
	if not InCombatLockdown() then
		return func(...)
	end
	tinsert(actionsToPerform, {
		func = func,
		args = {...},
		argCount = select("#", ...),
	})
end

function LUI.OutOfCombatWrapper(func)
	return function(...)
		return runOnLeaveCombat(func, ...)
	end
end
