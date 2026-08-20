--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: showhide.lua
	Description: Out-of-combat unitframe preview mode
]]

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.Unitframes
local module = LUI:GetModule("Unitframes")

---@class oUF
local oUF = LUI.oUF

local InCombatLockdown = _G.InCombatLockdown
local RegisterStateDriver = _G.RegisterStateDriver
local UnregisterStateDriver = _G.UnregisterStateDriver
local UnregisterUnitWatch = _G.UnregisterUnitWatch

local preview = {
	active = nil,
	frames = {},
	containers = {},
	registeredNames = {},
	hiddenRealFrames = {},
}

local realGroupFrames = {
	party = "oUF_LUI_party",
	boss = "oUF_LUI_boss",
	arena = "oUF_LUI_arena",
	maintank = "oUF_LUI_maintank",
	raid = "oUF_LUI_raid",
}

local parentGroups = {
	party = {count = 5, children = {"partytarget", "partypet"}},
	boss = {count = _G.MAX_BOSS_FRAMES or 5, children = {"bosstarget"}},
	arena = {count = 5, children = {"arenatarget", "arenapet"}},
	maintank = {count = 4, children = {"maintanktarget", "maintanktargettarget"}},
	raid = {count = 25},
}

local childParents = {
	partytarget = "party",
	partypet = "party",
	bosstarget = "boss",
	arenatarget = "arena",
	arenapet = "arena",
	maintanktarget = "maintank",
	maintanktargettarget = "maintank",
}

local singleUnits = {
	"player", "target", "focus", "focustarget", "targettarget",
	"targettargettarget", "pet", "pettarget",
}

local function GetOpposite(direction)
	if direction == "LEFT" then return "RIGHT" end
	if direction == "RIGHT" then return "LEFT" end
	if direction == "TOP" then return "BOTTOM" end
	return "TOP"
end

local function RemoveRegisteredName(unit, name)
	local list = module.framelist[unit]
	if not list then return end

	for i = #list, 1, -1 do
		if list[i] == name then
			table.remove(list, i)
			return
		end
	end
end

local function RegisterPreviewName(unit, name)
	if preview.registeredNames[name] then return end
	preview.registeredNames[name] = unit
	table.insert(module.framelist[unit], name)
end

local function GetPreviewFrame(unit, key)
	local baseName = "oUF_LUI_preview_"..key
	local name = baseName
	local frame = _G[name]

	-- A style error can leave a named frame behind even though oUF did not
	-- finish registering its element state. Such a frame cannot safely be
	-- repaired or passed to EnableElement, so leave it hidden and use a fresh
	-- unique name for the retry.
	if frame and not frame.LUIPreviewReady then
		frame:Hide()
		local suffix = 2
		repeat
			name = baseName.."_retry"..suffix
			frame = _G[name]
			suffix = suffix + 1
		until not frame or frame.LUIPreviewReady
	end

	if not frame then
		-- oUF receives a valid real unit while LUI's style function is told
		-- which layout database should be used for the preview.
		module.previewStyleUnit = unit
		local ok, result = pcall(oUF.Spawn, oUF, "player", name)
		module.previewStyleUnit = nil
		if not ok then
			LUI:Print("Unable to create the "..unit.." preview frame: "..tostring(result))
			return
		end
		frame = result
		frame.LUIPreviewReady = true
	end

	-- oUF registers the named frame before every part of the style function has
	-- necessarily finished. Reusing a frame from an interrupted preview must
	-- therefore restore the preview metadata and label instead of assuming that
	-- they already exist.
	frame.LUIPreview = true
	frame.LUIPreviewUnit = "player"
	if not frame.LUIPreviewLabel then
		local labelParent = frame.Overlay or frame
		local label = labelParent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		label:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 2)
		label:SetTextColor(1, 0.82, 0)
		frame.LUIPreviewLabel = label
	end

	RegisterPreviewName(unit, name)
	preview.frames[name] = frame
	frame.LUIPreviewLabel:SetText(unit)
	frame:Enable()
	UnregisterUnitWatch(frame)
	RegisterStateDriver(frame, "visibility", "[combat] hide; show")
	return frame
end

local function GetContainer(group)
	local container = preview.containers[group]
	if not container then
		container = CreateFrame("Frame", "oUF_LUI_preview_container_"..group, UIParent)
		container.LUIMoveName = group
		preview.containers[group] = container
	end
	container:Show()
	return container
end

local function HideRealGroupFrame(group)
	local frameName = realGroupFrames[group]
	local frame = frameName and _G[frameName]
	if frame and frame:IsShown() then
		preview.hiddenRealFrames[frame] = true
		frame:Hide()
	end
end

local function PositionContainer(container, db, group)
	local scale = db.Scale or 1
	local width, height = db.Width, db.Height
	if group == "raid" then
		-- The raid anchor represents the complete 5x5 25-player grid. Using the
		-- size of a single unit frame makes BOTTOM/RIGHT anchors grow off-screen.
		width = db.Width * 5 + db.GroupPadding * 4
		height = db.Height * 5 + db.Padding * 4
	end
	container:ClearAllPoints()
	container:SetScale(scale)
	container:SetPoint(db.Point, UIParent, db.Point, db.X / scale, db.Y / scale)
	container:SetSize(width, height)
end

local function PositionGroupFrame(frame, previous, db, index)
	frame:ClearAllPoints()
	if index == 1 then
		local point = (db.GrowDirection == "LEFT" or db.GrowDirection == "TOP") and "BOTTOMRIGHT" or "TOPLEFT"
		frame:SetPoint(point, frame:GetParent(), point, 0, 0)
		return
	end

	local opposite = GetOpposite(db.GrowDirection)
	local x, y = 0, 0
	if db.GrowDirection == "LEFT" then x = -db.Padding end
	if db.GrowDirection == "RIGHT" then x = db.Padding end
	if db.GrowDirection == "TOP" then y = db.Padding end
	if db.GrowDirection == "BOTTOM" then y = -db.Padding end
	frame:SetPoint(opposite, previous, db.GrowDirection, x, y)
end

local function PositionRaidFrame(frame, container, db, index)
	local column = math.floor((index - 1) / 5)
	local row = (index - 1) % 5
	frame:ClearAllPoints()
	frame:SetPoint(
		"TOPLEFT",
		container,
		"TOPLEFT",
		column * (db.Width + db.GroupPadding),
		-row * (db.Height + db.Padding)
	)
end

local function ShowSingle(unit)
	local db = module.db.profile[unit]
	if not db then return end

	local frame = GetPreviewFrame(unit, unit)
	if not frame then return end
	local scale = db.Scale or 1
	frame:SetParent(UIParent)
	frame:SetScale(scale)
	frame:ClearAllPoints()
	frame:SetPoint(db.Point, UIParent, db.Point, db.X / scale, db.Y / scale)
	module.ApplySettings(unit, true)
end

local function ShowGroup(group)
	local definition = parentGroups[group]
	local db = module.db.profile[group]
	if not definition or not db then return end

	HideRealGroupFrame(group)
	local container = GetContainer(group)
	PositionContainer(container, db, group)

	local previous
	for i = 1, definition.count do
		local frame = GetPreviewFrame(group, group..i)
		if frame then
			frame:SetParent(container)
			frame:SetScale(1)
			if group == "raid" then
				PositionRaidFrame(frame, container, db, i)
			else
				PositionGroupFrame(frame, previous, db, i)
			end
			previous = frame

			if definition.children then
				local childFrames = {}
				for _, childUnit in ipairs(definition.children) do
					local childDB = module.db.profile[childUnit]
					if childDB then
						local child = GetPreviewFrame(childUnit, group..i.."_"..childUnit)
						if child then
							local relativeFrame = childUnit == "maintanktargettarget" and childFrames.maintanktarget or frame
							child:SetParent(relativeFrame)
							child:SetScale(1)
							child:ClearAllPoints()
							child:SetPoint(childDB.Point, relativeFrame, childDB.RelativePoint, childDB.X, childDB.Y)
							childFrames[childUnit] = child
						end
					end
				end
			end
		end
	end

	module.ApplySettings(group, true)
	if definition.children then
		for _, childUnit in ipairs(definition.children) do
			module.ApplySettings(childUnit, true)
		end
	end
end

function module:StopUnitframePreview(silent)
	if InCombatLockdown() then
		if not silent then LUI:Print("Unitframe preview can only be changed outside combat.") end
		return false
	end

	for name, frame in pairs(preview.frames) do
		UnregisterStateDriver(frame, "visibility")
		frame:Hide()
		local unit = preview.registeredNames[name]
		if unit then RemoveRegisteredName(unit, name) end
	end
	wipe(preview.registeredNames)

	for _, container in pairs(preview.containers) do container:Hide() end
	for frame in pairs(preview.hiddenRealFrames) do frame:Show() end
	wipe(preview.hiddenRealFrames)
	preview.active = nil
	return true
end

function module:ShowUnitframePreview(selection)
	if InCombatLockdown() then
		LUI:Print("Unitframe preview is unavailable during combat.")
		return
	end

	self:StopUnitframePreview(true)
	preview.active = selection

	if selection == "all" then
		for _, unit in ipairs(singleUnits) do ShowSingle(unit) end
		for _, group in ipairs({"party", "boss", "arena", "maintank", "raid"}) do ShowGroup(group) end
	elseif parentGroups[selection] then
		ShowGroup(selection)
	elseif childParents[selection] then
		ShowGroup(childParents[selection])
	else
		ShowSingle(selection)
	end
end

function module:ToggleUnitframePreview(selection)
	if preview.active == selection then
		self:StopUnitframePreview()
	else
		self:ShowUnitframePreview(selection)
	end
end

function module:RefreshUnitframePreview()
	if not preview.active or InCombatLockdown() then return end
	local selection = preview.active
	self:ShowUnitframePreview(selection)
end

-- Allow the unitframe mover to use a visible preview container when the real
-- secure group header does not exist (for example outside a raid or when a
-- conflicting raid-frame addon prevented LUI from spawning its raid header).
function module:GetUnitframePreviewAnchor(unit)
	if preview.active == "all" or preview.active == unit or childParents[preview.active] == unit then
		return preview.containers[unit]
	end
end

-- Compatibility wrappers for the former per-group preview buttons.
function module:ShowArenaFrames() self:ShowUnitframePreview("arena") end
function module:HideArenaFrames() self:StopUnitframePreview() end
function module:ShowBossFrames() self:ShowUnitframePreview("boss") end
function module:HideBossFrames() self:StopUnitframePreview() end
function module:ShowMaintankFrames() self:ShowUnitframePreview("maintank") end
function module:HideMaintankFrames() self:StopUnitframePreview() end
