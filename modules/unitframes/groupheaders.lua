-- Forever's restricted compiler cannot initialize oUF's header snippets.
-- Prepare a bounded set of children outside combat, using the native header's
-- scripts for allocation, filtering, unit assignment and positioning.
local LUI = select(2, ...)
local module = LUI:GetModule("Unitframes")
local oUF = LUI.oUF

function module:SpawnPreconfiguredHeader(name, unit, capacity, configure, ...)
	assert(not InCombatLockdown(), "Group headers must be prepared outside combat.")
	assert(capacity > 0 and capacity <= 40, "Invalid group header capacity.")

	local header = oUF:SpawnHeader(name, nil, ...)
	-- SpawnHeader returns the native, initially hidden SecureGroupHeaderTemplate.
	-- Retain oUF's style dispatcher and header registration, but do not execute
	-- restricted snippets on Forever or copy them to the prepared children.
	header:SetAttribute("initialConfigFunction", nil)
	header:SetAttribute("_initialAttributeNames", nil)
	header:SetAttribute("oUF-initialConfigFunction", nil)

	local startingIndex = header:GetAttribute("startingIndex")
	local sortDir = header:GetAttribute("sortDir")
	header:SetAttribute("startingIndex", 1 - capacity)
	header:SetAttribute("sortDir", "ASC")
	header:SetAttribute("unitsPerColumn", capacity)
	header:SetAttribute("maxColumns", 1)

	-- Let Blizzard's XML OnShow dispatch perform the allocation. Calling
	-- SecureGroupHeader_Update directly from LUI can taint native working state
	-- subsequently reused by roster changes during combat.
	header:Show()
	header:Hide()

	for i = 1, capacity do
		local button = assert(header:GetAttribute("child" .. i), "Missing prepared group child.")
		local frames = {button, button:GetChildren()}
		for _, frame in ipairs(frames) do
			local suffix = frame:GetAttribute("unitsuffix")
			local styleUnit = unit .. (suffix or "")
			frame:SetAttribute("oUF-guessUnit", styleUnit)
			frame:SetAttribute("*type1", "target")
			frame:SetAttribute("*type2", "togglemenu")
			frame:SetAttribute("toggleForVehicle", true)
			configure(frame, styleUnit)
			RegisterUnitWatch(frame)
		end
		header:styleFunction(button:GetName())
	end

	header:SetAttribute("startingIndex", startingIndex)
	header:SetAttribute("sortDir", sortDir)
	-- The caller anchors and shows the header. Its native OnShow recalculates
	-- the final layout after sizes and the normal starting index are restored.
	return header
end
