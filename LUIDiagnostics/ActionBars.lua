-- Opt-in, read-only observations. Never hook or call Blizzard's update,
-- click, tab-selection or action-button setters from this recorder.
local _, D = ...
local worker = CreateFrame("Frame")
local current, elapsed, lastSignature, pending = nil, 0, nil, nil
local MAX_SAMPLES = 40
local bars = {"ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
	"MultiBarRightButton", "MultiBarLeftButton", "MultiBar5Button", "MultiBar6Button", "MultiBar7Button"}
local events = {"CURSOR_CHANGED", "ACTIONBAR_SLOT_CHANGED", "PLAYER_TALENT_UPDATE",
	"TRAIT_CONFIG_UPDATED", "PLAYER_LEVEL_CHANGED", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED"}

local function Secret(value) return issecretvalue and issecretvalue(value) end
local function Safe(func, ...)
	if type(func) ~= "function" then return nil end
	local ok, value = pcall(func, ...)
	if ok and not Secret(value) then return value end
end
local function Value(value)
	if Secret(value) then return "<restricted>" end
	if value == nil then return "nil" end
	return D.Text(value, 100)
end
local function Accessible(object)
	if Secret(object) or not object then return false end
	if object.IsForbidden then
		local forbidden = Safe(object.IsForbidden, object)
		if forbidden == nil or forbidden then return false end
	end
	return true
end
local function Security(object, key)
	if not object or Secret(object) or not issecurevariable then return "unknown" end
	local ok, secure, owner = pcall(issecurevariable, object, key)
	if not ok or Secret(secure) or secure == nil then return "unknown" end
	return secure and "secure" or ("tainted:" .. Value(owner))
end
local function Field(object, key)
	return Value(object[key]) .. " [" .. Security(object, key) .. "]"
end
local function Name(object)
	if not Accessible(object) then return "unavailable" end
	return Value(Safe(object.GetName, object))
end

local function Snapshot()
	local lines = {}
	local function Add(s) lines[#lines + 1] = s end
	Add("combat=" .. Value(Safe(InCombatLockdown)) .. " cursor=" .. Value(Safe(GetCursorInfo)))
	Add("nativeTaintLog=" .. Value(Safe(GetCVar, "taintLog")))
	Add("unspentTalents=" .. Value(Safe(C_ClassTalents and C_ClassTalents.HasUnspentTalentPoints))
		.. " unspentHeroTalents=" .. Value(Safe(C_ClassTalents and C_ClassTalents.HasUnspentHeroTalentPoints)))
	for _, name in ipairs({"ShowUIPanel", "MultiActionBar_ShowAllGrids", "MultiActionBar_HideAllGrids",
		"PlayerSpellsFrame", "PlayerSpellsMicroButton", "DISALLOW_FRAME_TOGGLING", "ON_BAR_HIGHLIGHT_MARKS"}) do
		Add("global " .. name .. "=" .. Security(_G, name))
	end
	local micro = _G.PlayerSpellsMicroButton
	if Accessible(micro) then
		Add("PlayerSpellsMicroButton suggestedTab=" .. Field(micro, "suggestedTab")
			.. " jumpToSpellID=" .. Field(micro, "jumpToSpellID")
			.. " EvaluateAlertVisibility=" .. Security(micro, "EvaluateAlertVisibility"))
	end
	local pool = _G.HelpTip and _G.HelpTip.framePool
	if Accessible(pool) and type(pool.EnumerateActive) == "function" then
		-- Observe native ownership without calling Init/Anchor/Hide or changing
		-- the pool. Keep a broken optional probe from losing action-bar evidence.
		local ok = pcall(function()
			local count = 0
			for tip in pool:EnumerateActive() do
				count = count + 1
				if count > 8 then break end
				if Accessible(tip) then
					local info = tip.info
					Add("HelpTip" .. count .. " relativeRegion=" .. Security(tip, "relativeRegion")
						.. " appliedTargetPoint=" .. Field(tip, "appliedTargetPoint")
						.. " appliedAlignment=" .. Field(tip, "appliedAlignment"))
					if not Secret(info) and type(info) == "table" then
						Add("HelpTip" .. count .. " system=" .. Value(info.system)
							.. " targetPoint=" .. Field(info, "targetPoint")
							.. " onHideCallback=" .. Security(info, "onHideCallback"))
					end
				end
			end
		end)
		if not ok then Add("HelpTip probe unavailable") end
	end
	local book = _G.PlayerSpellsFrame
	if Accessible(book) then
		Add("PlayerSpellsFrame shown=" .. Value(Safe(book.IsShown, book))
			.. " isMinimized=" .. Field(book, "isMinimized") .. " tabSystem=" .. Security(book, "tabSystem"))
		local tracker = book.internalTabTracker
		if not Secret(tracker) and type(tracker) == "table" then Add("selectedTab=" .. Field(tracker, "tabID")) end
		local close = book.CloseButton or _G.PlayerSpellsFrameCloseButton
		if Accessible(close) then
			local owner = close
			for i = 1, 8 do
				if not Accessible(owner) then break end
				Add("CloseButton ancestor" .. i .. "=" .. Name(owner) .. " protected=" .. Value(Safe(owner.IsProtected, owner)))
				if owner == UIParent then break end
				owner = Safe(owner.GetParent, owner)
			end
			local texture = Safe(close.GetNormalTexture, close)
			if Accessible(texture) then
				Add("CloseButton normal atlas=" .. Value(Safe(texture.GetAtlas, texture))
					.. " texture=" .. Value(Safe(texture.GetTexture, texture)))
			end
		end
	end
	for _, prefix in ipairs(bars) do
		for index = 1, 12 do
			local name = prefix .. index
			local button = _G[name]
			if Accessible(button) then
				Add(name .. " action=" .. Field(button, "action")
					.. " grid=" .. Value(Safe(button.GetAttribute, button, "showgrid"))
					.. " shown=" .. Value(Safe(button.IsShown, button))
					.. " visible=" .. Value(Safe(button.IsVisible, button))
					.. " mouse=" .. Value(Safe(button.IsMouseEnabled, button))
					.. " receiveDrag=" .. Security(button, "OnReceiveDrag")
					.. " update=" .. Security(button, "UpdateAction"))
			else Add(name .. " unavailable") end
		end
	end
	return lines
end

function D:CaptureActionBars(reason, force)
	if not current or not self:IsRecording() then return end
	local ok, lines = pcall(Snapshot)
	if not ok then current.failures = current.failures + 1; return end
	local signature = table.concat(lines, "\n")
	if not force and signature == lastSignature then return end
	lastSignature = signature
	local sample = {at = date("%Y-%m-%d %H:%M:%S"), uptime = GetTime(), reason = reason, lines = lines}
	current.samples[#current.samples + 1] = sample
	if #current.samples > MAX_SAMPLES then table.remove(current.samples, 1); current.evicted = current.evicted + 1 end
	if reason == "manual failure marker" then
		current.markers[#current.markers + 1] = sample
		if #current.markers > 3 then table.remove(current.markers, 1) end
	end
	return true
end

function D:BeginActionBarCapture(session)
	if not self:GetDatabase().actionBarTrace then return end
	session.actionBars = session.actionBars or {samples = {}, markers = {}, evicted = 0, failures = 0}
	current, elapsed, lastSignature, pending = session.actionBars, 0, nil, nil
	for _, event in ipairs(events) do worker:RegisterEvent(event) end
	worker:SetScript("OnUpdate", function(_, delta)
		elapsed = elapsed + delta
		if elapsed < .5 then return end
		elapsed = 0
		D:CaptureActionBars(pending or "poll")
		pending = nil
	end)
	self:CaptureActionBars("recording resumed", true)
end

worker:SetScript("OnEvent", function(_, event)
	pending = event
	D:Breadcrumb("DRAG_" .. event)
end)

local function RestoreTaintLog()
	local db = D:GetDatabase()
	local trace = db.actionBarTrace
	if not trace then return end
	if Safe(GetCVar, "taintLog") == "2" then
		Safe(SetCVar, "taintLog", trace.previousTaintLog)
		if Safe(GetCVar, "taintLog") ~= trace.previousTaintLog then
			LUI:Print("LUI DEBUG: taintLog could not be restored. Use /console taintLog " .. trace.previousTaintLog)
			return
		end
	end
	db.actionBarTrace = nil
end

function D:EndActionBarCapture()
	self:CaptureActionBars("recording stopped", true)
	worker:UnregisterAllEvents()
	worker:SetScript("OnUpdate", nil)
	current, pending = nil, nil
	RestoreTaintLog()
end

function D:ActionBarCommand(command)
	if command == "start" then
		if InCombatLockdown() then LUI:Print("LUI DEBUG: Start outside combat."); return end
		if self:IsRecording() then self:Stop() end
		RestoreTaintLog()
		if self:GetDatabase().actionBarTrace then return end
		local previous = Safe(GetCVar, "taintLog")
		if type(previous) ~= "string" or not previous:match("^%d+$") then
			LUI:Print("LUI DEBUG: This client does not expose taintLog; trace was not started."); return
		end
		self:GetDatabase().actionBarTrace = {previousTaintLog = previous}
		Safe(SetCVar, "taintLog", "2")
		if Safe(GetCVar, "taintLog") ~= "2" then
			RestoreTaintLog()
			LUI:Print("LUI DEBUG: Could not enable Blizzard taint logging; trace was not started."); return
		end
		LUI:Print("LUI DEBUG: Action-bar trace started, including Blizzard taint.log. Reloading. When dragging fails: /luidrag, then /luidrag stop outside combat.")
		self:ChangeRecording(true)
	elseif command == "stop" then
		if InCombatLockdown() then LUI:Print("LUI DEBUG: Use /luidrag now to mark the failure; stop outside combat."); return end
		self:ChangeRecording(false)
	elseif command == "" then
		if not current then LUI:Print("LUI DEBUG: Start the action-bar trace with /luidrag start outside combat."); return end
		if self:CaptureActionBars("manual failure marker", true) then
			LUI:Print("LUI DEBUG: Failure state marked. Use /luidrag stop outside combat to save. Share LUIDiagnostics.lua and _retail_/Logs/taint.log.")
		else LUI:Print("LUI DEBUG: Snapshot failed; Blizzard taint.log and the other diagnostic records remain available.") end
	else LUI:Print("LUI DEBUG: /luidrag start | /luidrag (mark failure) | /luidrag stop") end
end

function D:AppendActionBarReport(session, Add)
	local trace = session.actionBars
	if not trace then return end
	Add()
	Add("ACTION-BAR TRACE | samples " .. #trace.samples .. " | evicted " .. trace.evicted .. " | read failures " .. trace.failures)
	Add("Read-only samples at 0.5-second intervals; short-lived changes can be missed. Taint owners identify affected fields, not necessarily the root cause.")
	local function PrintSample(sample)
		Add(sample.at .. " uptime=" .. sample.uptime .. " " .. sample.reason)
		for _, line in ipairs(sample.lines) do Add("  " .. line) end
	end
	for _, sample in ipairs(trace.samples) do PrintSample(sample) end
	Add("PINNED FAILURE MARKERS")
	for _, sample in ipairs(trace.markers) do PrintSample(sample) end
	Add("Also attach _retail_/Logs/taint.log for Blizzard's recorded propagation stacks.")
end
