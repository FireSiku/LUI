local LUI = select(2, ...)
local module = LUI:GetModule("Unitframes")

local active = {}
local events = CreateFrame("Frame")
local inCombat

local function Opacity(state)
	return (inCombat or state.hovered) and 1 or state.settings.OutOfCombatAlpha
end

local function ApplyAlpha(state, alpha)
	local frame, range = state.frame, state.range
	if range then
		range.insideAlpha = state.insideAlpha * alpha
		range.outsideAlpha = state.outsideAlpha * alpha
		if state.rangeEligible then
			frame:SetAlphaFromBoolean(state.inRange, range.insideAlpha, range.outsideAlpha)
			return
		end
	end
	frame:SetAlpha(range and range.insideAlpha or alpha)
end

local function Update(frame)
	local state = active[frame]
	if state then ApplyAlpha(state, Opacity(state)) end
end

local function RangePreUpdate(range)
	local state = active[range.__owner]
	if state.preUpdate then state.preUpdate(range) end
	local alpha = Opacity(state)
	range.insideAlpha = state.insideAlpha * alpha
	range.outsideAlpha = state.outsideAlpha * alpha
end

local function RangePostUpdate(range, frame, inRange, eligible)
	local state = active[frame]
	-- Keep range results opaque; Blizzard selects the alpha from the boolean.
	state.inRange, state.rangeEligible = inRange, eligible
	if state.postUpdate then return state.postUpdate(range, frame, inRange, eligible) end
end

local function RestoreRange(state)
	local range = state.range
	if not range then return end
	range.PreUpdate, range.PostUpdate = state.preUpdate, state.postUpdate
	range.insideAlpha, range.outsideAlpha = state.insideAlpha, state.outsideAlpha
	state.range = nil
end

local function OnEnter(frame)
	active[frame].hovered = true
	Update(frame)
end

local function OnLeave(frame)
	active[frame].hovered = false
	Update(frame)
end

local function OnShow(frame)
	active[frame].hovered = frame:IsMouseOver()
	Update(frame)
end

local function OnHide(frame)
	active[frame].hovered = false
end

local function Disable(frame)
	local state = active[frame]
	if not state then return end
	if not frame:IsElementEnabled("Range") then RestoreRange(state) end
	ApplyAlpha(state, 1)
	RestoreRange(state)
	for _, script in ipairs({"OnEnter", "OnLeave", "OnShow", "OnHide"}) do module:Unhook(frame, script) end
	active[frame] = nil
	if not next(active) then events:UnregisterAllEvents() end
end

events:SetScript("OnEvent", function(_, event)
	inCombat = event == "PLAYER_REGEN_DISABLED"
	for frame in pairs(active) do
		if frame:IsVisible() then Update(frame) end
	end
end)

function module:ConfigureFading(frame, settings)
	local fade = settings.Fading
	if not self:IsEnabled() or not settings.Enable or not fade or not fade.Enable or frame.LUIPreview then
		Disable(frame)
		return
	end
	local state = active[frame]
	if not state then
		if not next(active) then
			inCombat = InCombatLockdown()
			events:RegisterEvent("PLAYER_REGEN_DISABLED")
			events:RegisterEvent("PLAYER_REGEN_ENABLED")
		end
		state = {frame = frame, hovered = frame:IsMouseOver()}
		active[frame] = state
		self:SecureHookScript(frame, "OnEnter", OnEnter)
		self:SecureHookScript(frame, "OnLeave", OnLeave)
		self:SecureHookScript(frame, "OnShow", OnShow)
		self:SecureHookScript(frame, "OnHide", OnHide)
	end
	state.settings = fade
	local range = frame:IsElementEnabled("Range") and frame.Range or nil
	if state.range ~= range then
		RestoreRange(state)
		state.rangeEligible = false
		if range then
			state.range = range
			state.insideAlpha, state.outsideAlpha = range.insideAlpha, range.outsideAlpha
			state.preUpdate, state.postUpdate = range.PreUpdate, range.PostUpdate
			range.PreUpdate, range.PostUpdate = RangePreUpdate, RangePostUpdate
		end
	end
	Update(frame)
end

function module:DisableFading(frame)
	if frame then return Disable(frame) end
	for frame in pairs(active) do Disable(frame) end
end
