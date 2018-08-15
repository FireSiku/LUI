local addonname, LUI = ...
local OutOfCombatWrapper = {}

LibStub("AceEvent-3.0"):Embed(OutOfCombatWrapper)

local inCombat, inLockdown = false, false
local actionsToPerform, functionArgs = {}, {}

OutOfCombatWrapper:RegisterEvent("PLAYER_REGEN_ENABLED", function()
	inCombat, inLockdown = false, false

	for i, func in ipairs(actionsToPerform) do
		if functionArgs[func] then
			func(unpack(functionArgs[func]))
		else
			func()
		end
	end

	wipe(actionsToPerform)
	wipe(functionArgs)
end)
OutOfCombatWrapper:RegisterEvent("PLAYER_REGEN_DISABLED", function()
	inCombat = true
end)

local function runOnLeaveCombat(func, ...)
	if not inCombat then
		-- out of combat, call right away and return
		return func(...)
	end
	if not inLockdown then
		inLockdown = InCombatLockdown() -- still in PLAYER_REGEN_DISABLED
		if not inLockdown then
			return func(...)
		end
	end
	tinsert(actionsToPerform, func)

	if select("#", ...) > 0 then
		functionArgs[func] = { ... }
	end
end

function LUI.OutOfCombatWrapper(func)
	return function(...)
		return runOnLeaveCombat(func, ...)
	end
end
