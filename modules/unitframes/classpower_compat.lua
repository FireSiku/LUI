-- Forever stores combo points on the target. Keep oUF's class visibility,
-- colors and lifecycle, but use Blizzard's target-bound query and events.
local LUI = select(2, ...)
local module = LUI:GetModule("Unitframes")

local function UpdateComboPoints(self, event, unit, powerType)
	if unit ~= "player" and unit ~= "vehicle" then return end
	if powerType and powerType ~= "COMBO_POINTS" then return end
	local element = self.ClassPower
	local current, maximum = 0, 0
	if event ~= "ClassPowerDisable" then
		current = GetComboPoints(unit, "target")
		maximum = UnitPowerMax(unit, Enum.PowerType.ComboPoints)
		-- Never compare or calculate with restricted resource values, and
		-- do not leave another target's points visible when values are hidden.
		if issecretvalue(current) or issecretvalue(maximum) then
			element:SetAlpha(0)
			return
		end
		maximum = math.min(maximum, #element)
	end

	local currentChanged = current ~= element.LUIComboPoints
	local maximumChanged = maximum ~= element.LUIComboPointsMax
	for i = 1, #element do
		element[i]:SetShown(i <= maximum)
		element[i]:SetValue(current - i + 1)
	end
	element.LUIComboPoints = current
	element.LUIComboPointsMax = maximum
	element:SetAlpha(event == "ClassPowerDisable" and 0 or 1)
	if element.PostUpdate then
		element:PostUpdate(current, maximum, currentChanged, maximumChanged, "COMBO_POINTS")
	end
end

local function RefreshComboPoints(self)
	self.ClassPower:ForceUpdate()
end

local function SyncComboPointEvents(self, elementName)
	if elementName and elementName ~= "ClassPower" then return end
	if not self.LUIForeverComboPoints then return end
	if self:IsElementEnabled("ClassPower") and not self:IsElementPaused("ClassPower") then
		self:RegisterEvent("PLAYER_TARGET_CHANGED", RefreshComboPoints, true)
		self:RegisterEvent("COMBO_TARGET_CHANGED", RefreshComboPoints, true)
		RefreshComboPoints(self)
	else
		self:UnregisterEvent("PLAYER_TARGET_CHANGED", RefreshComboPoints)
		self:UnregisterEvent("COMBO_TARGET_CHANGED", RefreshComboPoints)
	end
end

function module:PrepareForeverComboPoints(frame)
	if not LUI.IsForever or not (LUI.DRUID or LUI.ROGUE) then return end
	if frame.LUIPreview or module.previewStyleUnit or frame.LUIForeverComboPoints then return end
	frame.LUIForeverComboPoints = true
	frame.ClassPower.Override = UpdateComboPoints
	for _, method in ipairs({"EnableElement", "DisableElement", "PauseElement", "ResumeElement"}) do
		hooksecurefunc(frame, method, SyncComboPointEvents)
	end
end

LUI.oUF:RegisterInitCallback(function(frame)
	SyncComboPointEvents(frame)
end)
