-- Position handling for Blizzard frames that are not exposed by Edit Mode.

---@class LUIAddon
local LUI = select(2, ...)

---@class LUI.UIElements
local module = LUI:GetModule("UI Elements")

local InCombatLockdown = _G.InCombatLockdown
local originalPoints = {}
local settingPosition = false
local pendingRestore = false

local managedFrames = {
	ZoneObjectives = {
		frame = "UIWidgetTopCenterContainerFrame",
		point = "TOP",
		relativePoint = "TOP",
	},
	CaptureBar = {
		frame = "UIWidgetBelowMinimapContainerFrame",
		point = "TOPRIGHT",
		relativePoint = "TOPRIGHT",
	},
	GroupLoot = {
		frame = "GroupLootContainer",
		point = "BOTTOM",
		relativePoint = "BOTTOM",
	},
	TicketStatus = {
		frame = "TicketStatusFrame",
		point = "TOPRIGHT",
		relativePoint = "TOPRIGHT",
	},
}

local combatFrame = CreateFrame("Frame")
combatFrame:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	if pendingRestore or not module:IsEnabled() then
		pendingRestore = false
		module:RestoreManagedFrames()
	else
		module:Refresh()
	end
end)

local function QueueAfterCombat(restore)
	pendingRestore = restore == true
	combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
end

local function CapturePoints(frame)
	local points = {}
	for index = 1, frame:GetNumPoints() do
		points[index] = {frame:GetPoint(index)}
	end
	return points
end

local function RestorePoints(frame, points)
	frame:ClearAllPoints()
	for _, point in ipairs(points or {}) do
		frame:SetPoint(unpack(point))
	end
end

local function GetFrame(key)
	local definition = managedFrames[key]
	return definition and _G[definition.frame]
end

function module:RestoreManagedFrame(key)
	local frame = GetFrame(key)
	local points = originalPoints[key]
	if not frame or not points then return end

	settingPosition = true
	RestorePoints(frame, points)
	settingPosition = false
	originalPoints[key] = nil
end

function module:RestoreManagedFrames()
	if InCombatLockdown() then
		QueueAfterCombat(true)
		return
	end
	for key in pairs(managedFrames) do
		module:RestoreManagedFrame(key)
	end
end

function module:PositionManagedFrame(key)
	local definition = managedFrames[key]
	local config = definition and module.db.profile[key]
	local frame = GetFrame(key)
	if not definition or not config or not frame then return end

	if not module:IsHooked(frame, "SetPoint") then
		module:SecureHook(frame, "SetPoint", function()
			if not settingPosition and module:IsEnabled() then module:Refresh() end
		end)
	end

	if not config.ManagePosition then
		module:RestoreManagedFrame(key)
		return
	end

	originalPoints[key] = originalPoints[key] or CapturePoints(frame)
	settingPosition = true
	frame:ClearAllPoints()
	frame:SetPoint(definition.point, UIParent, definition.relativePoint, config.X, config.Y)
	settingPosition = false
end

function module:Refresh()
	if InCombatLockdown() then
		QueueAfterCombat(false)
		return
	end
	for key in pairs(managedFrames) do
		module:PositionManagedFrame(key)
	end
	module:PositionPreviews()
end

function module:PositionPreview(key)
	local preview = module.previews and module.previews[key]
	local definition = managedFrames[key]
	local config = definition and module.db.profile[key]
	if not preview or not config then return end
	preview:ClearAllPoints()
	preview:SetPoint(definition.point, UIParent, definition.relativePoint, config.X, config.Y)
end

function module:PositionPreviews()
	for key, preview in pairs(module.previews or {}) do
		if preview:IsShown() then module:PositionPreview(key) end
	end
end

function module:CreatePreview(key, labelText)
	module.previews = module.previews or {}
	if module.previews[key] then return module.previews[key] end

	local preview = CreateFrame("Frame", "LUI"..key.."Preview", UIParent)
	preview:SetSize(260, 48)
	preview:SetFrameStrata("DIALOG")
	LUI:ApplyFrameBackdrop(preview, {
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 14,
		insets = {left = 3, right = 3, top = 3, bottom = 3},
	})
	LUI:SetFrameBackgroundColor(preview, 0, 0, 0, 0.8)
	LUI:SetFrameBorderColor(preview, 1, 0.82, 0, 1)
	local label = preview:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetPoint("CENTER")
	label:SetText(labelText)
	preview:Hide()
	module.previews[key] = preview
	return preview
end

function module:TogglePreview(key, labelText)
	local preview = module:CreatePreview(key, labelText)
	if preview:IsShown() then
		preview:Hide()
	else
		module:PositionPreview(key)
		preview:Show()
	end
end

function module:HidePreviews()
	for _, preview in pairs(module.previews or {}) do preview:Hide() end
end
