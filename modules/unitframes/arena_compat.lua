-- Keep arena preparation on display-only frames. The real unit buttons retain
-- their unit watches and active elements throughout the match transition.
local LUI = select(2, ...)
local module = LUI:GetModule("Unitframes")
local Media = LibStub("LibSharedMedia-3.0")

if not (UnitFrameUtil and UnitFrameUtil.GetArenaOpponentSpecDisplayInfo
	and UnitFrameUtil.UpdateArenaOpponentSpecDisplayName) then return end

local frames = {}

local function UpdateBar(bar, source, info, health)
	bar:SetMinMaxValues(0, 1)
	bar:SetValue(1)
	if bar.colorClass then
		-- The native helper resolves restricted specialization/class data.
		bar:SetStatusBarColor(info.barColorR, info.barColorG, info.barColorB)
	elseif bar.colorSmooth then
		bar:SetStatusBarColor(module.colors.health:GetCurve():Evaluate(1):GetRGB())
	elseif bar.color ~= "Individual" then
		local color = health and module.colors.health or module.colors.power.MANA
		bar:SetStatusBarColor(color:GetRGB())
	end
	if source and source.PostUpdateColor then
		source.PostUpdateColor(bar, "arena" .. bar.__owner.index)
	end
end

local function Update(frame)
	local prep = frame.LUIArenaPreparation
	local db = module.db.profile.arena
	if InCombatLockdown() or not module:IsEnabled() or not db.Enable or not frame:IsEnabled() then
		prep:Hide()
		return
	end

	local state = C_PvP.GetActiveMatchState()
	local preparing = state == Enum.PvPMatchState.Waiting or state == Enum.PvPMatchState.StartUp
		or state == Enum.PvPMatchState.PostRound
	local count = GetNumArenaOpponentSpecs() or 0
	if not preparing or not C_PvP.IsMatchConsideredArena()
		or prep.index > count or UnitExists(frame.__unit) then
		prep:Hide()
		return
	end

	local parent = frame:GetParent()
	if prep.anchorParent ~= parent then
		prep.anchorParent = parent
		parent:HookScript("OnHide", function() prep:Hide() end)
	end
	if not parent:IsShown() then
		prep:Hide()
		return
	end

	prep:SetScale(frame:GetEffectiveScale() / UIParent:GetEffectiveScale())
	prep:ClearAllPoints()
	prep:SetAllPoints(frame)
	prep:SetFrameStrata(frame:GetFrameStrata())
	prep:SetFrameLevel(frame:GetFrameLevel())
	prep.Overlay:SetFrameLevel(prep:GetFrameLevel() + 8)
	module.funcs.Health(prep, "arena", db)
	module.funcs.Power(prep, "arena", db)
	module.funcs.FrameBackdrop(prep, "arena", db)
	prep.Health.__owner = prep
	prep.Power.__owner = prep

	local info = UnitFrameUtil.GetArenaOpponentSpecDisplayInfo(prep.index)
	UpdateBar(prep.Health, frame.Health, info, true)
	UpdateBar(prep.Power, frame.Power, info, false)

	local settings = db.NameText
	prep.Info:SetFont(Media:Fetch("font", settings.Font), settings.Size, settings.Outline)
	prep.Info:ClearAllPoints()
	prep.Info:SetPoint(settings.Point, prep, settings.RelativePoint, settings.X, settings.Y)
	prep.Info:SetTextColor(settings.IndividualColor.r, settings.IndividualColor.g, settings.IndividualColor.b)
	prep.Info:SetShown(settings.Enable)
	UnitFrameUtil.UpdateArenaOpponentSpecDisplayName(prep.Info, prep.index)
	-- hasSpec can be secret: pass it to the native widget without branching.
	prep:SetAlphaFromBoolean(info.hasSpec, 1, 0)
	prep:Show()
end

function module:UpdateArenaPreparation(frame)
	if frame then
		if frame.LUIArenaPreparation then Update(frame) end
	else
		for _, arenaFrame in ipairs(frames) do Update(arenaFrame) end
	end
end

LUI.oUF:RegisterInitCallback(function(frame)
	local index = frame.__unit and frame.__unit:match("^arena(%d+)$")
	if not index or frame.LUIPreview or module.previewStyleUnit then return end
	frame:SetAttribute("oUF-enableArenaPrep", false)
	local prep = CreateFrame("Frame", nil, UIParent)
	prep:Hide()
	prep.index = tonumber(index)
	prep.colors = module.colors
	prep.Overlay = CreateFrame("Frame", nil, prep)
	prep.Overlay:SetAllPoints(prep)
	prep.Info = prep.Overlay:CreateFontString(nil, "OVERLAY")
	frame.LUIArenaPreparation = prep
	frames[#frames + 1] = frame
	frame:HookScript("OnShow", function() prep:Hide() end)
	hooksecurefunc(frame, "Disable", function() prep:Hide() end)
	hooksecurefunc(frame, "Enable", function() Update(frame) end)
end)

local watcher = CreateFrame("Frame")
for _, event in ipairs({"ARENA_PREP_OPPONENT_SPECIALIZATIONS", "ARENA_OPPONENT_UPDATE",
	"PVP_MATCH_STATE_CHANGED", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_DISABLED",
	"PLAYER_REGEN_ENABLED", "CVAR_UPDATE"}) do
	watcher:RegisterEvent(event)
end
watcher:SetScript("OnEvent", function(_, event, cvar)
	if event == "CVAR_UPDATE" and cvar ~= "pvpFramesDisplayClassColor" then return end
	module:UpdateArenaPreparation()
end)
