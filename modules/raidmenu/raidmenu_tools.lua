-- Shared Retail / Forever group tools. Never replace native scripts or change
-- protected geometry/attributes in combat. Every action rechecks permissions.
local LUI = select(2, ...)
local module = LUI:GetModule("RaidMenu")
local buttons, menuParent
local toolsActive = false
local restrictionQueries = {"IsForbidden", "HasAnySecretAspect", "HasAnyForbiddenAspects", "HasAccessConstraints"}

local function Read(func, ...)
	if type(func) ~= "function" then return nil end
	local ok, value = pcall(func, ...)
	if not ok or (_G.issecretvalue and _G.issecretvalue(value)) then return nil end
	return value
end

local function CanAccess(frame)
	if not frame or (_G.issecretvalue and _G.issecretvalue(frame)) then return false end
	for _, key in ipairs(restrictionQueries) do
		local ok, query = pcall(function() return frame[key] end)
		if not ok then return false end
		if query and Read(query, frame) ~= false then return false end
	end
	return true
end

local function Enabled()
	local micro = LUI:GetModule("Micromenu", true)
	return toolsActive and module:IsEnabled() and module.db.profile.Enable
		and micro and micro:IsEnabled()
end

local function CanAct()
	return Enabled() and not InCombatLockdown()
end

local function InGroup()
	return Read(_G.IsInGroup) == true
end

local function InRaid()
	return Read(_G.IsInRaid) == true
end

local function IsLeader()
	return Read(_G.UnitIsGroupLeader, "player") == true
end

local function CanLead()
	return CanAct() and InGroup() and (IsLeader() or (InRaid() and Read(_G.UnitIsGroupAssistant, "player") == true))
end

local function CanSetAssist()
	return CanAct() and InRaid() and IsLeader()
end

local function HasPings()
	return C_PartyInfo and type(C_PartyInfo.GetRestrictPings) == "function"
		and type(C_PartyInfo.SetRestrictPings) == "function"
		and _G.Enum and Enum.RestrictPingsTo and _G.C_Ping
		and Read(C_Ping.IsPingSystemEnabled) == true
end

local function CanSetPings()
	return CanAct() and InGroup() and IsLeader() and HasPings()
end

local function CanLeaveInstance()
	return CanAct() and _G.PartyUtil and Read(PartyUtil.CanLeaveInstance) == true
		and type(_G.ConfirmOrLeaveParty) == "function"
end

local function IsWalkIn()
	return Read(C_PartyInfo and C_PartyInfo.IsPartyWalkIn)
end

local function CanLeaveParty()
	if not CanAct() or not InGroup() or not C_PartyInfo then return false end
	if C_PartyInfo.IsPartyWalkIn then
		local walkIn = IsWalkIn()
		if walkIn == nil then return false end
		if walkIn then return type(_G.LeaveWalkInParty) == "function" end
	end
	return type(C_PartyInfo.LeaveParty) == "function"
end

local function AfterAction()
	if module.db.profile.AutoHide then module:CloseRaidMenu() end
end

local function DifficultyAvailable()
	local util = _G.DifficultyUtil
	if not util or not util.ID then return false end
	-- Follow the client's native capability gate, including Forever overrides.
	if util.HasAnyUserSelectableDifficulties and Read(util.HasAnyUserSelectableDifficulties) ~= true then return false end
	return true
end

local function CanSetDifficulty(raid, id)
	if not CanAct() or not DifficultyAvailable() or InRaid() ~= raid then return false end
	if DifficultyUtil.InStoryRaid and Read(DifficultyUtil.InStoryRaid) ~= false then return false end
	return Read(raid and DifficultyUtil.IsRaidDifficultyEnabled or DifficultyUtil.IsDungeonDifficultyEnabled, id) == true
end

local function AddDifficulties(root)
	if not DifficultyAvailable() then return end
	local raid = InRaid()
	if raid and (not DifficultyUtil.DoesCurrentRaidDifficultyMatch or not _G.SetRaidDifficulties) then return end
	if not raid and (not _G.GetDungeonDifficultyID or not _G.SetDungeonDifficultyID) then return end
	local ids = DifficultyUtil.ID
	local choices = {
		{raid and ids.PrimaryRaidNormal or ids.DungeonNormal, _G.PLAYER_DIFFICULTY1 or "Normal"},
		{raid and ids.PrimaryRaidHeroic or ids.DungeonHeroic, _G.PLAYER_DIFFICULTY2 or "Heroic"},
		{raid and ids.PrimaryRaidMythic or ids.DungeonMythic, _G.PLAYER_DIFFICULTY6 or "Mythic"},
	}
	local submenu = root:CreateButton(_G.CRF_DIFFICULTY or "Difficulty")
	for _, choice in ipairs(choices) do
		local id = choice[1]
		if id then
			local radio = submenu:CreateRadio(choice[2], function()
				if raid then return Read(DifficultyUtil.DoesCurrentRaidDifficultyMatch, id) == true end
				return Read(_G.GetDungeonDifficultyID) == id
			end, function()
				if not CanSetDifficulty(raid, id) then return end
				if raid then SetRaidDifficulties(true, id) else SetDungeonDifficultyID(id) end
			end)
			radio:SetEnabled(CanSetDifficulty(raid, id))
		end
	end
end

local function CanEdit()
	local frame = _G.EditModeManagerFrame
	return CanAct() and CanAccess(frame) and Read(frame.CanEnterEditMode, frame) == true
		and type(_G.ShowUIPanel) == "function"
end

local function CanFilter()
	return CanAct() and InRaid() and CanAccess(_G.CompactRaidFrameManager)
		and CanAccess(_G.CompactRaidFrameContainer)
end

local function AddFrameOptions(root)
	if _G.EditModeManagerFrame then
		local edit = root:CreateButton(_G.HUD_EDIT_MODE_MENU or "Edit Mode", function()
			if CanEdit() then ShowUIPanel(EditModeManagerFrame) end
		end)
		edit:SetEnabled(CanEdit())
	end
	if _G.Settings and Settings.OpenToCategory and Settings.INTERFACE_CATEGORY_ID then
		root:CreateButton(_G.RAID_FRAMES_LABEL or "Raid Frames", function()
			if CanAct() then Settings.OpenToCategory(Settings.INTERFACE_CATEGORY_ID, _G.RAID_FRAMES_LABEL) end
		end)
	end
	if not InRaid() then return end
	local frames = root:CreateButton("Blizzard Raid Frames")
	if _G.GetCVarBool and _G.SetCVar and Read(_G.GetCVar, "raidOptionIsShown") ~= nil then
		frames:CreateCheckbox(_G.SHOW or "Show", function()
			return Read(GetCVarBool, "raidOptionIsShown") == true
		end, function()
			if not CanAct() or not InRaid() then return end
			local shown = Read(GetCVarBool, "raidOptionIsShown")
			if shown ~= nil then SetCVar("raidOptionIsShown", shown and "0" or "1") end
		end)
	end
	if _G.CRF_GetFilterRole and _G.CompactRaidFrameManager_ToggleRoleFilter then
		for _, entry in ipairs({{"TANK", _G.TANK or "Tank"}, {"HEALER", _G.HEALER or "Healer"}, {"DAMAGER", _G.DAMAGER or "Damage"}}) do
			local role = entry[1]
			local checkbox = frames:CreateCheckbox(entry[2], function()
				return Read(CRF_GetFilterRole, role) == true
			end, function()
				if CanFilter() then CompactRaidFrameManager_ToggleRoleFilter(role) end
			end)
			checkbox:SetEnabled(CanFilter())
		end
	end
	if _G.CRF_GetFilterGroup and _G.CompactRaidFrameManager_ToggleGroupFilter then
		for group = 1, (_G.MAX_RAID_GROUPS or 8) do
			local checkbox = frames:CreateCheckbox((_G.GROUP or "Group") .. " " .. group, function()
				return Read(CRF_GetFilterGroup, group) == true
			end, function()
				if CanFilter() then CompactRaidFrameManager_ToggleGroupFilter(group) end
			end)
			checkbox:SetEnabled(CanFilter())
		end
	end
end

local function OpenGroupOptions(owner)
	if not CanAct() or not (_G.MenuUtil and MenuUtil.CreateContextMenu) then return end
	MenuUtil.CreateContextMenu(owner, function(_, root)
		root:CreateTitle("LUI - " .. (_G.GROUP or "Group"))
		if C_PartyInfo and C_PartyInfo.SetEveryoneIsAssistant and _G.IsEveryoneAssistant and InRaid() then
			local checkbox = root:CreateCheckbox(_G.CRF_ALL_ASSIST or "Everyone Is Assistant", function()
				return Read(IsEveryoneAssistant) == true
			end, function()
				if not CanSetAssist() then return end
				local value = Read(IsEveryoneAssistant)
				if value ~= nil then C_PartyInfo.SetEveryoneIsAssistant(not value) end
			end)
			checkbox:SetEnabled(CanSetAssist())
		end
		if HasPings() then
			local pings = root:CreateButton(_G.RAID_MANAGER_RESTRICT_PINGS or "Restrict Pings To")
			local values = Enum.RestrictPingsTo
			for _, entry in ipairs({
				{values.None, _G.NONE or "None"},
				{values.Lead, _G.RAID_MANAGER_RESTRICT_PINGS_TO_LEAD or "Leader"},
				{values.Assist, _G.RAID_MANAGER_RESTRICT_PINGS_TO_ASSIST or "Leader and Assistants"},
				{values.TankHealer, _G.RAID_MANAGER_RESTRICT_PINGS_TO_TANKS_HEALERS or "Tanks and Healers"},
			}) do
				local value = entry[1]
				if value ~= nil then
					local radio = pings:CreateRadio(entry[2], function()
						return Read(C_PartyInfo.GetRestrictPings) == value
					end, function()
						if CanSetPings() then C_PartyInfo.SetRestrictPings(value) end
					end)
					radio:SetEnabled(CanSetPings())
				end
			end
		end
		AddDifficulties(root)
		AddFrameOptions(root)
	end)
end

function module:UpdateGroupTools()
	if not buttons then return end
	buttons[1]:SetEnabled(not not (CanLead() and C_PartyInfo and type(C_PartyInfo.DoCountdown) == "function"))
	buttons[2]:SetEnabled(not not (CanAct() and _G.MenuUtil and type(MenuUtil.CreateContextMenu) == "function"))
	buttons[3]:SetEnabled(not not CanLeaveParty())
	buttons[4]:SetEnabled(not not CanLeaveInstance())
	buttons[4]:SetText(IsWalkIn() == true and (_G.INSTANCE_WALK_IN_LEAVE or "Leave Instance") or (_G.INSTANCE_PARTY_LEAVE or "Leave Instance Group"))
end

function module:LayoutGroupTools(width, height)
	if not buttons or InCombatLockdown() then return height end
	local y = height - 2
	for _, button in ipairs(buttons) do
		button:ClearAllPoints()
		button:SetPoint("TOPLEFT", menuParent, "TOPLEFT", 20, -y)
		button:SetSize(width - 40, 22)
		y = y + 26
	end
	return y + 18
end

function module:SetGroupToolsActive(active)
	toolsActive = active
	self:UpdateGroupTools()
end

function module:CreateGroupTools(parent)
	if buttons then return end
	menuParent = parent
	buttons = {}
	local entries = {
		{(_G.CRF_COUNTDOWN or "Countdown") .. " (10s)", function()
			if CanLead() and C_PartyInfo and C_PartyInfo.DoCountdown then
				C_PartyInfo.DoCountdown(10)
				AfterAction()
			end
		end},
		{(_G.GROUP or "Group") .. " - " .. (_G.OPTIONS or "Options"), OpenGroupOptions},
		{_G.PARTY_LEAVE or "Leave Party", function()
			if not CanLeaveParty() then return end
			if IsWalkIn() == true then LeaveWalkInParty() else C_PartyInfo.LeaveParty() end
			AfterAction()
		end},
		{_G.INSTANCE_PARTY_LEAVE or "Leave Instance Group", function()
			if CanLeaveInstance() then ConfirmOrLeaveParty(); AfterAction() end
		end},
	}
	for i, entry in ipairs(entries) do
		local button = CreateFrame("Button", "LUIRaidGroupTool" .. i, parent, "UIPanelButtonTemplate")
		button:SetFrameLevel(parent:GetFrameLevel() + 2)
		button:SetNormalFontObject("GameFontNormalSmall")
		button:SetHighlightFontObject("GameFontHighlightSmall")
		button:SetDisabledFontObject("GameFontDisableSmall")
		button:SetText(entry[1])
		button:SetScript("OnClick", entry[2])
		buttons[i] = button
	end
	parent:HookScript("OnShow", function() module:UpdateGroupTools() end)
	local events = CreateFrame("Frame")
	for _, event in ipairs({"ADDON_LOADED", "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE", "PARTY_LEADER_CHANGED",
		"PLAYER_ROLES_ASSIGNED", "PLAYER_DIFFICULTY_CHANGED", "PARTY_LFG_RESTRICTED", "ZONE_CHANGED_NEW_AREA",
		"PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED"}) do
		events:RegisterEvent(event)
	end
	events:SetScript("OnEvent", function()
		module:UpdateGroupTools()
	end)
end
