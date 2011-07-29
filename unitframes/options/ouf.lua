--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: ouf.lua
	Description: oUF Module
	Version....: 1.0
]] 

local _, ns = ...
local oUF = ns.oUF or oUF

local LUI = LibStub("AceAddon-3.0"):GetAddon("LUI")
local module = LUI:NewModule("oUF", "AceHook-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists

local db

LUI_versions.ouf = 3403

local fontflags = {"OUTLINE", "THICKOUTLINE", "MONOCHROME", "NONE"}

local ufNames = {
	Player = "oUF_LUI_player",
	Target = "oUF_LUI_target",
	ToT = "oUF_LUI_targettarget",
	ToToT = "oUF_LUI_targettargettarget",
	Focus = "oUF_LUI_focus",
	FocusTarget = "oUF_LUI_focustarget",
	Pet = "oUF_LUI_pet",
	PetTarget = "oUF_LUI_pettarget",
	Party = "oUF_LUI_party",
	Maintank = "oUF_LUI_maintank",
	Boss = "oUF_LUI_boss",
	Player_Castbar = "oUF_LUI_player_Castbar",
	Target_Castbar = "oUF_LUI_target_Castbar",
	Arena = "oUF_LUI_arena"
}

local _LOCK
local _BACKDROP = {bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"}

local round = function(n) return math.floor(n + .5) end

local backdropPool = {}

local setAllPositions = function()
	for k, v in pairs(ufNames) do
		local k2 = nil
		if strfind(k, "Castbar") then k, k2 = strsplit("_", k) end
		if _G[v] and db.oUF[k] then
			local point, _, rpoint, x, y = backdropPool[_G[v]]:GetPoint()
			
			if k2 then
				if db.oUF[k][k2] then
					db.oUF[k][k2].X = tostring(x)
					db.oUF[k][k2].Y = tostring(y)
					db.oUF[k][k2].Point = point
				end
			else
				db.oUF[k].X = tostring(x * (db.oUF[k].Scale or 1))
				db.oUF[k].Y = tostring(y * (db.oUF[k].Scale or 1))
				db.oUF[k].Point = point
			end
			
			local scale = db.oUF[k].Scale or 1
			_G[v]:ClearAllPoints()
			_G[v]:SetPoint(point, UIParent, rpoint, x, y)
		end
	end
end

local resetAllPositions = function()
	for k, v in pairs(ufNames) do
		local k2 = nil
		if strfind(k, "Castbar") then k, k2 = strsplit("_", k) end
		if _G[v] and db.oUF[k] then
			if backdropPool[_G[v]] then backdropPool[_G[v]]:ClearAllPoints() end
			
			if k2 then
				if db.oUF[k][k2] then
					_G[v]:ClearAllPoints()
					_G[v]:SetPoint(db.oUF[k][k2].Point, UIParent, db.oUF[k][k2].Point, tonumber(db.oUF[k][k2].X), tonumber(db.oUF[k][k2].Y))
				end
			else
				_G[v]:ClearAllPoints()
				_G[v]:SetPoint(db.oUF[k].Point, UIParent, db.oUF[k].Point, tonumber(db.oUF[k].X) / (db.oUF[k].Scale or 1), tonumber(db.oUF[k].Y) / (db.oUF[k].Scale or 1))
			end
		end
	end
end

local smartName
do
	local nameCache = {}
	
	local validNames = {
		"player",
		"target",
		"focus",
		"raid",
		"pet",
		"party",
		"maintank",
		"mainassist",
		"arena",
	}

	local validName = function(smartName)
		if tonumber(smartName) then
			return smartName
		end

		if type(smartName) == "string" then
			if smartName == "mt" then
				return "maintank"
			end
			if smartName == "castbar" then
				return " castbar"
			end

			for _, v in next, validNames do
				if v == smartName then
					return smartName
				end
			end

			if (
				smartName:match("^party%d?$") or
				smartName:match("^arena%d?$") or
				smartName:match("^boss%d?$") or
				smartName:match("^partypet%d?$") or
				smartName:match("^raid%d?%d?$") or
				smartName:match("%w+target$") or
				smartName:match("%w+pet$")
			) then
				return smartName
			end
		end
	end

	local function guessName(...)
		local name = validName(select(1, ...))

		local n = select("#", ...)
		if n > 1 then
			for i = 2, n do
				local inp = validName(select(i, ...))
				if inp then name = (name or "")..inp end
			end
		end

		return name
	end

	local smartString = function(name)
		if nameCache[name] then
			return nameCache[name]
		end

		local n = name:gsub("(%l)(%u)", "%1_%2"):gsub("([%l%u])(%d)", "%1_%2_"):lower()
		n = guessName(string.split("_", n))
		if n then
			nameCache[name] = n
			return n
		end

		return name
	end

	smartName = function(obj)
		if type(obj) == "string" then
			return smartString(obj)
		else
			local name = obj:GetName()
			if name then return smartString(name) end
			return obj.unit or "<unknown>"
		end
	end
end

do
	local frame = CreateFrame("Frame")
	frame:SetScript("OnEvent", function(self, event)
		return self[event](self)
	end)

	function frame:PLAYER_REGEN_DISABLED()
		if _LOCK then
			for k, bdrop in next, backdropPool do bdrop:Hide() end
			_LOCK = nil
			
			StaticPopup_Hide("DRAG_UNITFRAMES")
			LUI:Print("UnitFrame anchors hidden due to combat. The changed positions are NOT saved!")
		end
	end
	frame:RegisterEvent("PLAYER_REGEN_DISABLED")
end

local getBackdrop
do
	local OnShow = function(self)
		return self.name:SetText(smartName(self.obj))
	end

	local OnDragStart = function(self)
		self:StartMoving()

		local frame = self.obj
		frame:ClearAllPoints()
		frame:SetPoint("TOPLEFT", self)
	end

	local OnDragStop = function(self)
		self:StopMovingOrSizing()
	end

	getBackdrop = function(obj)
		if not obj and not obj:GetCenter() then return end
		if backdropPool[obj] then
			backdropPool[obj]:SetScale(obj:GetScale())
			backdropPool[obj]:SetPoint(obj:GetPoint())
			backdropPool[obj]:SetSize(obj:GetSize())
			return backdropPool[obj]
		end

		local backdrop = CreateFrame("Frame")
		backdrop:SetParent(UIParent)
		backdrop:Hide()

		backdrop:SetScale(obj:GetScale())
		backdrop:SetPoint(obj:GetPoint())
		backdrop:SetSize(obj:GetSize())
		
		backdrop:SetBackdrop(_BACKDROP)
		backdrop:SetBackdropColor(0, .9, 0)
		backdrop:SetBackdropBorderColor(0, .9, 0)
		
		backdrop:SetFrameStrata("TOOLTIP")

		backdrop:EnableMouse(true)
		backdrop:SetMovable(true)
		backdrop:RegisterForDrag("LeftButton")

		backdrop:SetScript("OnShow", OnShow)

		local name = backdrop:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		name:SetPoint("CENTER")
		name:SetJustifyH("CENTER")
		name:SetFont(GameFontNormal:GetFont(), 12)
		name:SetTextColor(1, 1, 1)

		backdrop.name = name
		backdrop.obj = obj

		if  math.floor(obj:GetHeight()) == 0 then obj:SetHeight(obj:GetChildren():GetHeight()) end

		backdrop:SetScript("OnDragStart", OnDragStart)
		backdrop:SetScript("OnDragStop", OnDragStop)

		backdropPool[obj] = backdrop

		return backdrop
	end
end

StaticPopupDialogs["DRAG_UNITFRAMES"] = {
	text = "oUF_LUI UnitFrames are dragable.",
	button1 = "Save",
	button3 = "Reset",
	button2 = "Cancel",
	OnShow = function()
		LibStub("AceConfigDialog-3.0"):Close("LUI")
		GameTooltip:Hide()
	end,
	OnHide = function()
		module:MoveUnitFrames(true)
	end,
	OnAccept = setAllPositions,
	OnAlt = resetAllPositions,
	OnCancel = resetAllPositions,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}

function module:MoveUnitFrames(override)
	if InCombatLockdown() and not override then
		return LUI:Print("UnitFrames cannot be moved while in combat.")
	end
	
	-- sometimes bugs around!
	if oUF_LUI_party then oUF_LUI_party:Show() end
	
	if (not _LOCK) and (not override) then
		StaticPopup_Show("DRAG_UNITFRAMES")
		for k, v in pairs(ufNames) do
			if _G[v] then
				local bd = getBackdrop(_G[v])
				if bd then bd:Show() end
			end
		end

		_LOCK = true
	else
		for k, bdrop in next, backdropPool do
			bdrop:Hide()
		end
		
		StaticPopup_Hide("DRAG_UNITFRAMES")
		_LOCK = nil
	end
end

local frameShow = PlayerFrame.Show

function module:EnableBlizzard(unit)
	local function RegisterBlizzUnitFrame(frame, ...)
		if not frame then return end
		frame.Show = frameShow
		
		for i = 1, select("#", ...) do
			frame:RegisterEvent(select(i, ...))
		end
	end
	
	if unit == "player" then
		RegisterBlizzUnitFrame(PlayerFrame,
			"UNIT_LEVEL", "UNIT_COMBAT", "UNIT_FACTION", "UNIT_MAXPOWER", "PLAYER_ENTERING_WORLD", "PLAYER_ENTER_COMBAT",
			"PLAYER_LEAVE_COMBAT", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_UPDATE_RESTING", "PARTY_MEMBERS_CHANGED",
			"PARTY_LEADER_CHANGED", "PARTY_LOOT_METHOD_CHANGED", "VOICE_START", "VOICE_STOP", "RAID_ROSTER_UPDATE", "READY_CHECK",
			"READY_CHECK_CONFIRM", "READY_CHECK_FINISHED", "UNIT_ENTERED_VEHICLE", "UNIT_ENTERING_VEHICLE", "UNIT_EXITING_VEHICLE",
			"UNIT_EXITED_VEHICLE", "PLAYER_FLAGS_CHANGED", "PLAYER_ROLES_ASSIGNED", "PLAYTIME_CHANGED"
		)
		PlayerFrame:Show()
		
		unit = "playerCastbar"
	end
	
	if unit == "playerCastbar" then
		RegisterBlizzUnitFrame(CastingBarFrame,
			"UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED",
			"UNIT_SPELLCAST_DELAYED", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_UPDATE", "UNIT_SPELLCAST_CHANNEL_STOP",
			"UNIT_SPELLCAST_INTERRUPTIBLE", "UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "PLAYER_ENTERING_WORLD"
		)
	end
	
	if unit == "pet" then
		RegisterBlizzUnitFrame(PetFrame,
			"UNIT_PET", "UNIT_COMBAT", "UNIT_AURA", "PET_ATTACK_START", "PET_ATTACK_STOP", "UNIT_POWER", "PET_UI_UPDATE", "PET_RENAMEABLE"
		)
		
		unit = "petCastbar"
	end
	
	if unit == "petCastbar" then
		RegisterBlizzUnitFrame(PetCastingBarFrame,
			"UNIT_PET", "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED",
			"UNIT_SPELLCAST_DELAYED", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_UPDATE", "UNIT_SPELLCAST_CHANNEL_STOP",
			"UNIT_SPELLCAST_INTERRUPTIBLE", "UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "PLAYER_ENTERING_WORLD"
		)
	end
	
	if unit == "target" then
		RegisterBlizzUnitFrame(TargetFrame,
			"PLAYER_ENTERING_WORLD", "PLAYER_TARGET_CHANGED", "UNIT_HEALTH", "CVAR_UPDATE", "UNIT_LEVEL", "UNIT_FACTION",
			"UNIT_CLASSIFICATION_CHANGED", "UNIT_AURA", "PLAYER_FLAGS_CHANGED", "PARTY_MEMBERS_CHANGED", "RAID_TARGET_UPDATE"
		)
		
		RegisterBlizzUnitFrame(TargetFrame.spellbar,
			"CVAR_UPDATE", "VARIABLES_LOADED", "PLAYER_TARGET_CHANGED"
		)
		
		RegisterBlizzUnitFrame(ComboFrame,
			"PLAYER_TARGET_CHANGED", "UNIT_COMBO_POINTS"
		)
	end
	
	if unit == "focus" then
		RegisterBlizzUnitFrame(FocusFrame,
			"PLAYER_ENTERING_WORLD", "PLAYER_FOCUS_CHANGED", "UNIT_HEALTH", "UNIT_LEVEL", "UNIT_FACTION", "UNIT_CLASSIFICATION_CHANGED",
			"UNIT_AURA", "PLAYER_FLAGS_CHANGED", "PARTY_MEMBERS_CHANGED", "RAID_TARGET_UPDATE", "VARIABLES_LOADED"
		)
		
		RegisterBlizzUnitFrame(FocusFrame.spellbar,
			"CVAR_UPDATE", "VARIABLES_LOADED", "PLAYER_FOCUS_CHANGED"
		)
		
		FocusFrame_SetSmallSize(not GetCVarBool("fullSizeFocusFrame"))
	end
	
	if unit == "targettarget" then
		RegisterBlizzUnitFrame(TargetFrameToT, false)
	end
	
	if unit:match("(boss)%d?$") == "boss" then
		local id = unit:match("boss(%d)")
		if id then
			if id == 1 then
				RegisterBlizzUnitFrame(_G["Boss"..id.."TargetFrame"],
					"UNIT_TARGETABLE_CHANGED", "INSTANCE_ENCOUNTER_ENGAGE_UNIT"
				)
			else
				RegisterBlizzUnitFrame(_G["Boss"..id.."TargetFrame"],
					"UNIT_TARGETABLE_CHANGED"
				)
			end
		else
			for i = 1, 4 do
				if i == 1 then
					RegisterBlizzUnitFrame(_G["Boss"..i.."TargetFrame"],
						"UNIT_TARGETABLE_CHANGED", "INSTANCE_ENCOUNTER_ENGAGE_UNIT"
					)
				else
					RegisterBlizzUnitFrame(_G["Boss"..i.."TargetFrame"],
						"UNIT_TARGETABLE_CHANGED"
					)
				end
			end
		end
	end
	
	if unit:match("(party)%d?$") == "party" then
		local id = unit:match("party(%d)")
		if id then
			RegisterBlizzUnitFrame(_G["PartyMemberFrame"..id],
				"PLAYER_ENTERING_WORLD", "PARTY_MEMBERS_CHANGED", "PARTY_LEADER_CHANGED", "PARTY_LOOT_METHOD_CHANGED", "MUTELIST_UPDATE",
				"IGNORELIST_UPDATE", "UNIT_FACTION", "UNIT_AURA", "UNIT_PET", "VOICE_START", "VOICE_STOP", "VARIABLES_LOADED",
				"VOICE_STATUS_UPDATE", "READY_CHECK", "READY_CHECK_CONFIRM", "READY_CHECK_FINISHED", "UNIT_ENTERED_VEHICLE",
				"UNIT_EXITED_VEHICLE", "UNIT_HEALTH", "UNIT_CONNECTION", "PARTY_MEMBER_ENABLE", "PARTY_MEMBER_DISABLE", "UNIT_PHASE"
			)
		else
			for i = 1, 4 do
				RegisterBlizzUnitFrame(_G["PartyMemberFrame"..i],
					"PLAYER_ENTERING_WORLD", "PARTY_MEMBERS_CHANGED", "PARTY_LEADER_CHANGED", "PARTY_LOOT_METHOD_CHANGED", "MUTELIST_UPDATE",
					"IGNORELIST_UPDATE", "UNIT_FACTION", "UNIT_AURA", "UNIT_PET", "VOICE_START", "VOICE_STOP", "VARIABLES_LOADED",
					"VOICE_STATUS_UPDATE", "READY_CHECK", "READY_CHECK_CONFIRM", "READY_CHECK_FINISHED", "UNIT_ENTERED_VEHICLE",
					"UNIT_EXITED_VEHICLE", "UNIT_HEALTH", "UNIT_CONNECTION", "PARTY_MEMBER_ENABLE", "PARTY_MEMBER_DISABLE", "UNIT_PHASE"
				)
			end
		end
		ShowPartyFrame()
	end
	
	if unit:match("(arena)%d?$") == "arena" then
		if not ArenaEnemyFrame1 then Arena_LoadUI_() end
		local id = unit:match("arena(%d)")
		if id then
			RegisterBlizzUnitFrame(_G["ArenaEnemyFrame"..id],
				"CVAR_UPDATE", "VARIABLES_LOADED", "PLAYER_ENTERING_WORLD"
			)
		else
			for i = 1, 5 do
				RegisterBlizzUnitFrame(_G["ArenaEnemyFrame"..i],
					"CVAR_UPDATE", "VARIABLES_LOADED", "PLAYER_ENTERING_WORLD"
				)
			end
		end
	end
end

function module:SetBlizzardRaidFrames()
	local useBlizz = (db.oUF.Settings.Enable == false) or db.oUF.Raid.UseBlizzard
	if IsAddOnLoaded("Grid") or IsAddOnLoaded("Grid2") or IsAddOnLoaded("VuhDo") or IsAddOnLoaded("Healbot") or (db.oUF.Settings.Enable and db.oUF.Raid.Enable) then
		useBlizz = false
	end
	if useBlizz then
		module:Unhook(CompactRaidFrameManager, "Show")
		module:Unhook(CompactRaidFrameContainer, "Show")
		-- if UnitInRaid("player") then			-- may add back in at some point
			CompactRaidFrameManager:Show()
			CompactRaidFrameContainer:Show()
		-- end
	else
		local function hideCompactFrame(frame)
			frame:Hide()
		end
		-- RawHooking a blank function causes action blocked errors
		if not module:IsHooked(CompactRaidFrameManager, "Show") then
			module:SecureHook(CompactRaidFrameManager, "Show", hideCompactFrame)
		end
		if not module:IsHooked(CompactRaidFrameContainer, "Show") then
			module:SecureHook(CompactRaidFrameContainer, "Show", hideCompactFrame)
		end
		CompactRaidFrameManager:Hide()
		CompactRaidFrameContainer:Hide()
	end
end

local ufUnits = {
	Player = "player",
	Target = "target",
	ToT = "targettarget",
	ToToT = "targettargettarget",
	Focus = "focus",
	FocusTarget = "focustarget",
	Pet = "pet",
	PetTarget = "pettarget",
}

-- needed this way because of self calls!
local toggleFuncs
toggleFuncs = {
	Default = function(unit)
		local x = tonumber(db.oUF[unit].X) / (db.oUF[unit].Scale)
		local y = tonumber(db.oUF[unit].Y) / (db.oUF[unit].Scale)
		
		if db.oUF[unit].Enable == nil or db.oUF[unit].Enable then -- == nil needed for player/target
			if _G["oUF_LUI_"..ufUnits[unit]] then
				_G["oUF_LUI_"..ufUnits[unit]]:Enable()
				_G["oUF_LUI_"..ufUnits[unit]]:UpdateAllElements()
				_G["oUF_LUI_"..ufUnits[unit]]:ClearAllPoints()
				_G["oUF_LUI_"..ufUnits[unit]]:SetScale(db.oUF[unit].Scale)
				_G["oUF_LUI_"..ufUnits[unit]]:SetPoint(db.oUF[unit].Point, UIParent, db.oUF[unit].Point, x, y)
			else
				local f = oUF:Spawn(ufUnits[unit], "oUF_LUI_"..ufUnits[unit])
				f:SetScale(db.oUF[unit].Scale)
				f:SetPoint(db.oUF[unit].Point, UIParent, db.oUF[unit].Point, x, y)
			end
		else
			if _G["oUF_LUI_"..ufUnits[unit]] then _G["oUF_LUI_"..ufUnits[unit]]:Disable() end
		end
	end,
	
	Boss = function()
		if db.oUF.Boss.Enable then
			local x = tonumber(db.oUF.Boss.X) / (db.oUF.Boss.Scale)
			local y = tonumber(db.oUF.Boss.Y) / (db.oUF.Boss.Scale)
			
			if oUF_LUI_boss then
				oUF_LUI_boss:SetScale(db.oUF.Boss.Scale)
				oUF_LUI_boss:ClearAllPoints()
				oUF_LUI_boss:SetPoint(db.oUF.Boss.Point, UIParent, db.oUF.Boss.Point, x, y)
				oUF_LUI_boss:SetWidth(tonumber(db.oUF.Boss.Width))
				oUF_LUI_boss:SetHeight(tonumber(db.oUF.Boss.Height))
				oUF_LUI_boss:SetAttribute("Height", tonumber(db.oUF.Boss.Height))
				oUF_LUI_boss:SetAttribute("Padding", tonumber(db.oUF.Boss.Padding))
				oUF_LUI_boss:Show()
				
				for i = 1, 4 do
					_G["oUF_LUI_boss"..i]:Enable()
					_G["oUF_LUI_boss"..i]:UpdateAllElements()
					_G["oUF_LUI_boss"..i]:ClearAllPoints()
					if i == 1 then
						_G["oUF_LUI_boss"..i]:SetPoint("TOPLEFT", oUF_LUI_boss, "TOPLEFT", 0, 0)
					else
						_G["oUF_LUI_boss"..i]:SetPoint("TOP", _G["oUF_LUI_boss"..i-1], "BOTTOM", 0, -tonumber(db.oUF.Boss.Padding))
					end
				end
			else
				local bossParent = CreateFrame("Frame", "oUF_LUI_boss", UIParent)
				bossParent:SetScale(db.oUF.Boss.Scale)
				bossParent:SetPoint(db.oUF.Boss.Point, UIParent, db.oUF.Boss.Point, x, y)
				bossParent:SetWidth(tonumber(db.oUF.Boss.Width))
				bossParent:SetHeight(tonumber(db.oUF.Boss.Height))
				bossParent:SetAttribute("Height", tonumber(db.oUF.Boss.Height))
				bossParent:SetAttribute("Padding", tonumber(db.oUF.Boss.Padding))
				bossParent:Show()
				
				local handler = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
				handler:SetFrameRef("boss", bossParent)
				handler:SetAttribute("_onstate-resize", [[
					local parent = self:GetFrameRef("boss")
					local padding = parent:GetAttribute("Padding")
					local height = parent:GetAttribute("Height")
					parent:SetHeight(newstate * height + (newstate - 1) * padding)
				]])
				RegisterStateDriver(handler, "resize", "[@boss4,exists] 4; [@boss3,exists] 3; [@boss2,exists] 2; 1")
				bossParent.handler = handler
				
				local boss = {}
				for i = 1, 4 do
					boss[i] = oUF:Spawn("boss"..i, "oUF_LUI_boss"..i)
					if i == 1 then
						boss[i]:SetPoint("TOPLEFT", bossParent, "TOPLEFT", 0, 0)
					else
						boss[i]:SetPoint("TOP", boss[i-1], "BOTTOM", 0, -tonumber(db.oUF.Boss.Padding))
					end
				end
			end
			
			for i = 1, MAX_BOSS_FRAMES do
				local boss = _G["Boss"..i.."TargetFrame"]
				if boss then
					boss.Show = function() end
					boss:Hide()
					boss:UnregisterAllEvents()
				end
			end
		else
			if db.oUF.Boss.UseBlizzard then
				module:EnableBlizzard("boss")
			else
				for i = 1, MAX_BOSS_FRAMES do
					local boss = _G["Boss"..i.."TargetFrame"]
					if boss then
						boss.Show = function() end
						boss:Hide()
						boss:UnregisterAllEvents()
					end
				end
			end
			
			for i = 1, 4 do
				if _G["oUF_LUI_boss"..i] then _G["oUF_LUI_boss"..i]:Disable() end
			end
			
			if oUF_LUI_boss then oUF_LUI_boss:Hide() end
		end
		
		toggleFuncs.BossTarget()
	end,
	
	BossTarget = function()
		if db.oUF.Boss.Enable and db.oUF.BossTarget.Enable then
			if oUF_LUI_bosstarget1 then
				for i = 1, 4 do
					if _G["oUF_LUI_bosstarget"..i] then
						_G["oUF_LUI_bosstarget"..i]:Enable()
						_G["oUF_LUI_bosstarget"..i]:ClearAllPoints()
						_G["oUF_LUI_bosstarget"..i]:SetPoint(db.oUF.BossTarget.Point, _G["oUF_LUI_boss"..i], db.oUF.BossTarget.RelativePoint, tonumber(db.oUF.BossTarget.X), tonumber(db.oUF.BossTarget.Y))
					end
				end
			else
				for i = 1, 4 do
					oUF:Spawn("boss"..i.."target", "oUF_LUI_bosstarget"..i):SetPoint(db.oUF.BossTarget.Point, _G["oUF_LUI_boss"..i], db.oUF.BossTarget.RelativePoint, tonumber(db.oUF.BossTarget.X), tonumber(db.oUF.BossTarget.Y))
				end
			end
		else
			for i = 1, 4 do
				if _G["oUF_LUI_bosstarget"..i] then _G["oUF_LUI_bosstarget"..i]:Disable() end
			end
		end
	end,
	
	Party = function()
		if db.oUF.Party.Enable then
			local x = tonumber(db.oUF.Party.X) / (db.oUF.Party.Scale)
			local y = tonumber(db.oUF.Party.Y) / (db.oUF.Party.Scale)
			
			if oUF_LUI_party then
				oUF_LUI_party:SetScale(db.oUF.Party.Scale)
				oUF_LUI_party:ClearAllPoints()
				oUF_LUI_party:SetPoint(db.oUF.Party.Point, UIParent, db.oUF.Party.Point, x, y)
				oUF_LUI_party:SetAttribute("yOffset", - tonumber(db.oUF.Party.Padding))
				oUF_LUI_party:SetAttribute("showPlayer", db.oUF.Party.ShowPlayer)
				oUF_LUI_party:SetAttribute("oUF-initialConfigFunction", [[
					local unit = ...
					if unit == "party" then
						self:SetHeight(]]..db.oUF.Party.Height..[[)
						self:SetWidth(]]..db.oUF.Party.Width..[[)
					elseif unit == "partytarget" then
						self:SetHeight(]]..db.oUF.PartyTarget.Height..[[)
						self:SetWidth(]]..db.oUF.PartyTarget.Width..[[)
						self:SetPoint("]]..db.oUF.PartyTarget.Point..[[", self:GetParent(), "]]..db.oUF.PartyTarget.RelativePoint..[[", ]]..db.oUF.PartyTarget.X..[[, ]]..db.oUF.PartyTarget.Y..[[)
					elseif unit == "partypet" then
						self:SetHeight(]]..db.oUF.PartyPet.Height..[[)
						self:SetWidth(]]..db.oUF.PartyPet.Width..[[)
						self:SetPoint("]]..db.oUF.PartyPet.Point..[[", self:GetParent(), "]]..db.oUF.PartyPet.RelativePoint..[[", ]]..db.oUF.PartyPet.X..[[, ]]..db.oUF.PartyPet.Y..[[)
					end
				]])
				
				for i = 1, 5 do
					if _G["oUF_LUI_partyUnitButton"..i] then
						_G["oUF_LUI_partyUnitButton"..i]:Enable()
						_G["oUF_LUI_partyUnitButton"..i]:UpdateAllElements()
					end
				end
				
				oUF_LUI_party.handler:SetAttribute("vis", nil)
				oUF_LUI_party.handler:SetAttribute("vis", 1)
				oUF_LUI_party.handler:GetScript("OnEvent")(oUF_LUI_party.handler)
			else
				local party = oUF:SpawnHeader("oUF_LUI_party", nil, nil,
					"showParty", true,
					"showPlayer", db.oUF.Party.ShowPlayer,
					"showSolo", false,
					"template", "oUF_LUI_party",
					"yOffset", - tonumber(db.oUF.Party.Padding),
					"oUF-initialConfigFunction", [[
						local unit = ...
						if unit == "party" then
							self:SetHeight(]]..db.oUF.Party.Height..[[)
							self:SetWidth(]]..db.oUF.Party.Width..[[)
						elseif unit == "partytarget" then
							self:SetHeight(]]..db.oUF.PartyTarget.Height..[[)
							self:SetWidth(]]..db.oUF.PartyTarget.Width..[[)
							self:SetPoint("]]..db.oUF.PartyTarget.Point..[[", self:GetParent(), "]]..db.oUF.PartyTarget.RelativePoint..[[", ]]..db.oUF.PartyTarget.X..[[, ]]..db.oUF.PartyTarget.Y..[[)
						elseif unit == "partypet" then
							self:SetHeight(]]..db.oUF.PartyPet.Height..[[)
							self:SetWidth(]]..db.oUF.PartyPet.Width..[[)
							self:SetPoint("]]..db.oUF.PartyPet.Point..[[", self:GetParent(), "]]..db.oUF.PartyPet.RelativePoint..[[", ]]..db.oUF.PartyPet.X..[[, ]]..db.oUF.PartyPet.Y..[[)
						end
					]]
				)
				
				party:SetScale(db.oUF.Party.Scale)
				party:SetPoint(db.oUF.Party.Point, UIParent, db.oUF.Party.Point, x, y)
								
				local handler = CreateFrame("Frame", nil, UIParent, "SecureHandlerAttributeTemplate")
				handler:SetAttribute("vis", 1)
				handler:SetFrameRef("party", party)
				handler:SetAttribute("_onattributechanged", [[
					if name == "vis" then
						if self:GetAttribute("vis") then
							self:GetFrameRef("party"):Show()
						else
							self:GetFrameRef("party"):Hide()
						end
					end
				]])

				handler:RegisterEvent("PLAYER_ENTERING_WORLD")
				handler:RegisterEvent("PARTY_MEMBERS_CHANGED")
				handler:RegisterEvent("RAID_ROSTER_UPDATE")
				handler:SetScript("OnEvent", function(self)
					if InCombatLockdown() then
						self:RegisterEvent("PLAYER_REGEN_ENABLED") -- prevents updating untill end of combat to stop SetAttribute errors
						return
					end
					
					if db.oUF.Party.Enable == false then
						self:SetAttribute("vis", nil)
						return
					end
					
					if db.oUF.Party.ShowInRaid == true then
						self:SetAttribute("vis", 1)
					else
						local numparty = GetNumPartyMembers()
						local numraid = GetNumRaidMembers()
						
						if db.oUF.Party.ShowInRealParty == true then
							if numparty and numraid == 0 then
								self:SetAttribute("vis", 1)
							else
								self:SetAttribute("vis", nil)
							end
						else
							if (numraid < 6 and numraid == numparty + 1) or numraid == 0 then
								self:SetAttribute("vis", 1)
							else
								self:SetAttribute("vis", nil)
							end
						end
					end
				end)
				party.handler = handler
				
				handler:SetAttribute("vis", nil)
				handler:SetAttribute("vis", 1)
				handler:GetScript("OnEvent")(handler)
			end
			
			SetCVar("useCompactPartyFrames", nil)
			oUF:DisableBlizzard("party")
		else
			if db.oUF.Party.UseBlizzard then
				module:EnableBlizzard("party")
			else
				SetCVar("useCompactPartyFrames", nil)
				oUF:DisableBlizzard("party")
			end
			
			if oUF_LUI_party then
				for i = 1, 5 do
					if _G["oUF_LUI_partyUnitButton"..i] then _G["oUF_LUI_partyUnitButton"..i]:Disable() end
				end
				UnregisterStateDriver(oUF_LUI_party, "visibility")
				oUF_LUI_party:Hide()
			end
		end
		
		toggleFuncs.PartyTarget()
		toggleFuncs.PartyPet()
	end,
	
	PartyTarget = function()
		if db.oUF.Party.Enable and db.oUF.PartyTarget.Enable then
			for i = 1, 5 do
				if _G["oUF_LUI_partyUnitButton"..i.."target"] then
					_G["oUF_LUI_partyUnitButton"..i.."target"]:Enable()
					_G["oUF_LUI_partyUnitButton"..i.."target"]:UpdateAllElements()
					_G["oUF_LUI_partyUnitButton"..i.."target"]:ClearAllPoints()
					_G["oUF_LUI_partyUnitButton"..i.."target"]:SetPoint(db.oUF.PartyTarget.Point, _G["oUF_LUI_partyUnitButton"..i], db.oUF.PartyTarget.RelativePoint, tonumber(db.oUF.PartyTarget.X), tonumber(db.oUF.PartyTarget.Y))
				end
			end
		else
			for i = 1, 5 do
				if _G["oUF_LUI_partyUnitButton"..i.."target"] then _G["oUF_LUI_partyUnitButton"..i.."target"]:Disable() end
			end
		end
	end,
	
	PartyPet = function()
		if db.oUF.Party.Enable and db.oUF.PartyPet.Enable then
			for i = 1, 5 do
				if _G["oUF_LUI_partyUnitButton"..i.."pet"] then
					_G["oUF_LUI_partyUnitButton"..i.."pet"]:Enable()
					_G["oUF_LUI_partyUnitButton"..i.."pet"]:UpdateAllElements()
					_G["oUF_LUI_partyUnitButton"..i.."pet"]:ClearAllPoints()
					_G["oUF_LUI_partyUnitButton"..i.."pet"]:SetPoint(db.oUF.PartyPet.Point, _G["oUF_LUI_partyUnitButton"..i], db.oUF.PartyPet.RelativePoint, tonumber(db.oUF.PartyPet.X), tonumber(db.oUF.PartyPet.Y))
				end
			end
		else
			for i = 1, 5 do
				if _G["oUF_LUI_partyUnitButton"..i.."pet"] then _G["oUF_LUI_partyUnitButton"..i.."pet"]:Disable() end
			end
		end
	end,
	
	Arena = function()
		if db.oUF.Arena.Enable then
			local x = tonumber(db.oUF.Arena.X) / (db.oUF.Arena.Scale)
			local y = tonumber(db.oUF.Arena.Y) / (db.oUF.Arena.Scale)
			
			if oUF_LUI_arena then
				oUF_LUI_arena:SetScale(db.oUF.Arena.Scale)
				oUF_LUI_arena:ClearAllPoints()
				oUF_LUI_arena:SetPoint(db.oUF.Arena.Point, UIParent, db.oUF.Arena.Point, x, y)
				oUF_LUI_arena:SetWidth(tonumber(db.oUF.Arena.Width))
				oUF_LUI_arena:SetHeight(tonumber(db.oUF.Arena.Height))
				oUF_LUI_arena:SetAttribute("Height", tonumber(db.oUF.Arena.Height))
				oUF_LUI_arena:SetAttribute("Padding", tonumber(db.oUF.Arena.Padding))
				oUF_LUI_arena:Show()
				
				for i = 1, 5 do
					_G["oUF_LUI_arena"..i]:Enable()
					_G["oUF_LUI_arena"..i]:UpdateAllElements()
					_G["oUF_LUI_arena"..i]:ClearAllPoints()
					if i == 1 then
						_G["oUF_LUI_arena"..i]:SetPoint("TOPLEFT", oUF_LUI_arena, "TOPLEFT", 0, 0)
					else
						_G["oUF_LUI_arena"..i]:SetPoint("TOP", _G["oUF_LUI_arena"..i-1], "BOTTOM", 0, -tonumber(db.oUF.Arena.Padding))
					end
				end
			else
				-- oUF kills it, we save it!
				Arena_LoadUI_ = ArenaLoadUI
				
				local arenaParent = CreateFrame("Frame", "oUF_LUI_arena", UIParent)
				arenaParent:SetScale(db.oUF.Arena.Scale)
				arenaParent:SetPoint(db.oUF.Arena.Point, UIParent, db.oUF.Arena.Point, x, y)
				arenaParent:SetWidth(tonumber(db.oUF.Arena.Width))
				arenaParent:SetHeight(tonumber(db.oUF.Arena.Height))
				arenaParent:SetAttribute("Height", tonumber(db.oUF.Arena.Height))
				arenaParent:SetAttribute("Padding", tonumber(db.oUF.Arena.Padding))
				arenaParent:Show()

				local handler = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
				handler:SetFrameRef("arena", arenaParent)
				handler:SetAttribute("_onstate-resize", [[
					local parent = self:GetFrameRef("arena")
					local padding = parent:GetAttribute("Padding")
					local height = parent:GetAttribute("Height")
					parent:SetHeight(newstate * height + (newstate - 1) * padding)
				]])
				RegisterStateDriver(handler, "resize", "[@arena5,exists] 5; [@arena4,exists] 4; [@arena3,exists] 3; [@arena2,exists] 2; 1")
				arenaParent.handler = handler
				
				local arena = {}

				for i = 1, 5 do
					arena[i] = oUF:Spawn("arena"..i, "oUF_LUI_arena"..i)
					if i == 1 then
						arena[i]:SetPoint("TOPLEFT", arenaParent, "TOPLEFT", 0, 0)
					else
						arena[i]:SetPoint("TOP", arena[i-1], "BOTTOM", 0, -tonumber(db.oUF.Arena.Padding))
					end
				end
			end
			
			SetCVar("showArenaEnemyFrames", 0)
			oUF:DisableBlizzard("arena")
		else
			if db.oUF.Arena.UseBlizzard == true then
				SetCVar("showArenaEnemyFrames", 1)
				if not ArenaEnemyFrame1 then
					if Arena_LoadUI_ then
						Arena_LoadUI_()
					else
						Arena_LoadUI()
					end
				end
			else
				SetCVar("showArenaEnemyFrames", 0)
				oUF:DisableBlizzard("arena")
			end
			
			for i = 1, 5 do
				if _G["oUF_LUI_arena"..i] then _G["oUF_LUI_arena"..i]:Disable() end
			end
			
			if oUF_LUI_arena then oUF_LUI_arena:Hide() end
		end
		
		toggleFuncs.ArenaTarget()
		toggleFuncs.ArenaPet()
	end,
	
	ArenaTarget = function()
		if db.oUF.Arena.Enable and db.oUF.ArenaTarget.Enable then
			for i = 1, 5 do
				if _G["oUF_LUI_arenatarget"..i] then
					_G["oUF_LUI_arenatarget"..i]:Enable()
					_G["oUF_LUI_arenatarget"..i]:UpdateAllElements()
					_G["oUF_LUI_arenatarget"..i]:ClearAllPoints()
					_G["oUF_LUI_arenatarget"..i]:SetPoint(db.oUF.ArenaTarget.Point, _G["oUF_LUI_arena"..i], db.oUF.ArenaTarget.RelativePoint, tonumber(db.oUF.ArenaTarget.X), tonumber(db.oUF.ArenaTarget.Y))
				else
					oUF:Spawn("arena"..i.."target", "oUF_LUI_arenatarget"..i):SetPoint(db.oUF.ArenaTarget.Point, _G["oUF_LUI_arena"..i], db.oUF.ArenaTarget.RelativePoint, tonumber(db.oUF.ArenaTarget.X), tonumber(db.oUF.ArenaTarget.Y))
				end
			end
		else
			for i = 1, 5 do
				if _G["oUF_LUI_arenatarget"..i] then _G["oUF_LUI_arenatarget"..i]:Disable() end
			end
		end
	end,
	
	ArenaPet = function()
		if db.oUF.Arena.Enable and db.oUF.ArenaPet.Enable == true then
			for i = 1, 5 do
				if _G["oUF_LUI_arenapet"..i] then
					_G["oUF_LUI_arenapet"..i]:Enable()
					_G["oUF_LUI_arenapet"..i]:UpdateAllElements()
					_G["oUF_LUI_arenapet"..i]:ClearAllPoints()
					_G["oUF_LUI_arenapet"..i]:SetPoint(db.oUF.ArenaPet.Point, _G["oUF_LUI_arena"..i], db.oUF.ArenaPet.RelativePoint, tonumber(db.oUF.ArenaPet.X), tonumber(db.oUF.ArenaPet.Y))
				else
					oUF:Spawn("arena"..i.."target", "oUF_LUI_arenatarget"..i):SetPoint(db.oUF.ArenaPet.Point, _G["oUF_LUI_arena"..i], db.oUF.ArenaPet.RelativePoint, tonumber(db.oUF.ArenaPet.X), tonumber(db.oUF.ArenaPet.Y))
				end
			end
		else
			for i = 1, 5 do
				if _G["oUF_LUI_arenapet"..i] then _G["oUF_LUI_arenapet"..i]:Disable() end
			end
		end
	end,
	
	Maintank = function()
		if db.oUF.Maintank.Enable then
			local x = tonumber(db.oUF.Maintank.X) / (db.oUF.Maintank.Scale)
			local y = tonumber(db.oUF.Maintank.Y) / (db.oUF.Maintank.Scale)
			
			if oUF_LUI_maintank then
				oUF_LUI_maintank:SetScale(db.oUF.Maintank.Scale)
				oUF_LUI_maintank:ClearAllPoints()
				oUF_LUI_maintank:SetPoint(db.oUF.Maintank.Point, UIParent, db.oUF.Maintank.Point, x, y)
				oUF_LUI_maintank:SetAttribute("yOffset", - tonumber(db.oUF.Maintank.Padding))
				oUF_LUI_maintank:SetAttribute("oUF-initialConfigFunction", [[
					local unit = ...
					if unit == "maintanktargettarget" then
						self:SetHeight(]]..db.oUF.MaintankToT.Height..[[)
						self:SetWidth(]]..db.oUF.MaintankToT.Width..[[)
						self:SetPoint("]]..db.oUF.MaintankToT.Point..[[", self:GetParent(), "]]..db.oUF.MaintankToT.RelativePoint..[[", ]]..db.oUF.MaintankToT.X..[[, ]]..db.oUF.MaintankToT.Y..[[)
					elseif unit == "maintanktarget" then
						self:SetHeight(]]..db.oUF.MaintankTarget.Height..[[)
						self:SetWidth(]]..db.oUF.MaintankTarget.Width..[[)
						self:SetPoint("]]..db.oUF.MaintankTarget.Point..[[", self:GetParent(), "]]..db.oUF.MaintankTarget.RelativePoint..[[", ]]..db.oUF.MaintankTarget.X..[[, ]]..db.oUF.MaintankTarget.Y..[[)
					elseif unit == "maintank" then
						self:SetHeight(]]..db.oUF.Maintank.Height..[[)
						self:SetWidth(]]..db.oUF.Maintank.Width..[[)
					end
				]])
				oUF_LUI_maintank:Show()
				
				for i = 1, 4 do
					if _G["oUF_LUI_maintankUnitButton"..i] then
						_G["oUF_LUI_maintankUnitButton"..i]:Enable()
						_G["oUF_LUI_maintankUnitButton"..i]:UpdateAllElements()
					end
				end
			else
				local tank = oUF:SpawnHeader("oUF_LUI_maintank", nil, nil,
					"showRaid", true,
					"groupFilter", "MAINTANK",
					"template", "oUF_LUI_maintank",
					"showPlayer", true,
					"unitsPerColumn", 4,
					"yOffset", - tonumber(db.oUF.Maintank.Padding),
					"oUF-initialConfigFunction", [[
						local unit = ...
						if unit == "maintanktargettarget" then
							self:SetHeight(]]..db.oUF.MaintankToT.Height..[[)
							self:SetWidth(]]..db.oUF.MaintankToT.Width..[[)
							self:SetPoint("]]..db.oUF.MaintankToT.Point..[[", self:GetParent(), "]]..db.oUF.MaintankToT.RelativePoint..[[", ]]..db.oUF.MaintankToT.X..[[, ]]..db.oUF.MaintankToT.Y..[[)
						elseif unit == "maintanktarget" then
							self:SetHeight(]]..db.oUF.MaintankTarget.Height..[[)
							self:SetWidth(]]..db.oUF.MaintankTarget.Width..[[)
							self:SetPoint("]]..db.oUF.MaintankTarget.Point..[[", self:GetParent(), "]]..db.oUF.MaintankTarget.RelativePoint..[[", ]]..db.oUF.MaintankTarget.X..[[, ]]..db.oUF.MaintankTarget.Y..[[)
						elseif unit == "maintank" then
							self:SetHeight(]]..db.oUF.Maintank.Height..[[)
							self:SetWidth(]]..db.oUF.Maintank.Width..[[)
						end
					]]
				)
				
				tank:SetScale(db.oUF.Maintank.Scale)
				tank:SetPoint(db.oUF.Maintank.Point, UIParent, db.oUF.Maintank.Point, x, y)
				tank:Show()
			end
		else
			if oUF_LUI_maintank then
				for i = 1, 4 do
					if _G["oUF_LUI_maintankUnitButton"..i] then _G["oUF_LUI_maintankUnitButton"..i]:Disable() end
					if _G["oUF_LUI_maintankUnitButton"..i.."target"] then _G["oUF_LUI_maintankUnitButton"..i.."target"]:Disable() end
					if _G["oUF_LUI_maintankUnitButton"..i.."targettarget"] then _G["oUF_LUI_maintankUnitButton"..i.."targettarget"]:Disable() end
				end
				oUF_LUI_maintank:Hide()
			end
		end
		
		toggleFuncs.MaintankTarget()
	end,
	
	MaintankTarget = function()
		if db.oUF.Maintank.Enable and db.oUF.MaintankTarget.Enable then
			for i = 1, 4 do
				if _G["oUF_LUI_maintankUnitButton"..i.."target"] then
					_G["oUF_LUI_maintankUnitButton"..i.."target"]:ClearAllPoints()
					_G["oUF_LUI_maintankUnitButton"..i.."target"]:SetPoint(db.oUF.MaintankTarget.Point, _G["oUF_LUI_maintankUnitButton"..i], db.oUF.MaintankTarget.RelativePoint, tonumber(db.oUF.MaintankTarget.X), tonumber(db.oUF.MaintankTarget.Y))
					_G["oUF_LUI_maintankUnitButton"..i.."target"]:Enable()
					_G["oUF_LUI_maintankUnitButton"..i.."target"]:UpdateAllElements()
				end
			end
		else
			for i = 1, 4 do
				if _G["oUF_LUI_maintankUnitButton"..i.."target"] then _G["oUF_LUI_maintankUnitButton"..i.."target"]:Disable() end
			end
		end
		
		toggleFuncs.MaintankToT()
	end,
	
	MaintankToT = function()
		if db.oUF.Maintank.Enable and db.oUF.MaintankTarget.Enable and db.oUF.MaintankToT.Enable then
			for i = 1, 4 do
				if _G["oUF_LUI_maintankUnitButton"..i.."targettarget"] then
					_G["oUF_LUI_maintankUnitButton"..i.."targettarget"]:ClearAllPoints()
					_G["oUF_LUI_maintankUnitButton"..i.."targettarget"]:SetPoint(db.oUF.MaintankToT.Point, _G["oUF_LUI_maintankUnitButton"..i.."target"], db.oUF.MaintankToT.RelativePoint, tonumber(db.oUF.MaintankToT.X), tonumber(db.oUF.MaintankToT.Y))
					_G["oUF_LUI_maintankUnitButton"..i.."targettarget"]:Enable()
					_G["oUF_LUI_maintankUnitButton"..i.."targettarget"]:UpdateAllElements()
				end
			end
		else
			for i = 1, 4 do
				if _G["oUF_LUI_maintankUnitButton"..i.."targettarget"] then _G["oUF_LUI_maintankUnitButton"..i.."targettarget"]:Disable() end
			end
		end
	end,

	Raid = function()
		if db.oUF.Raid.Enable then
			module:SetBlizzardRaidFrames()
			
			if IsAddOnLoaded("Grid") or IsAddOnLoaded("Grid2") or IsAddOnLoaded("VuhDo") or IsAddOnLoaded("Healbot") then
				return
			end
			if oUF_LUI_raid then
				for i = 1, 5 do
					for j = 1, 5 do
						local frame = _G["oUF_LUI_raid_25_"..i.."UnitButton"..j]
						if frame then frame:Enable() end
					end
				end
				
				for i = 1, 8 do
					for j = 1, 5 do
						local frame = _G["oUF_LUI_raid_40_"..i.."UnitButton"..j]
						if frame then frame:Enable() end
					end
				end
				
				UnregisterStateDriver(oUF_LUI_raid_25, "visibility")
				RegisterStateDriver(oUF_LUI_raid_25, "visibility", "[@raid26,exists] hide; show")
				UnregisterStateDriver(oUF_LUI_raid_40, "visibility")
				RegisterStateDriver(oUF_LUI_raid_40, "visibility", "[@raid26,exists] show; hide")
				
				oUF_LUI_raid:ClearAllPoints()
				oUF_LUI_raid:SetPoint(db.oUF.Raid.Point, UIParent, db.oUF.Raid.Point, tonumber(db.oUF.Raid.X), tonumber(db.oUF.Raid.Y))
				oUF_LUI_raid:Show()
			else
				local raidAnchor = CreateFrame("Frame", "oUF_LUI_raid", UIParent)
				raidAnchor:SetWidth(tonumber(db.oUF.Raid.Width) * 5 + tonumber(db.oUF.Raid.GroupPadding) * 4)
				raidAnchor:SetHeight(tonumber(db.oUF.Raid.Height) * 5 + tonumber(db.oUF.Raid.Padding) * 4)
				raidAnchor:SetPoint(db.oUF.Raid.Point, UIParent, db.oUF.Raid.Point, tonumber(db.oUF.Raid.X), tonumber(db.oUF.Raid.Y))
				
				local raid25 = CreateFrame("Frame", "oUF_LUI_raid_25", raidAnchor, "SecureHandlerStateTemplate")
				raid25:SetWidth(1)
				raid25:SetHeight(1)
				raid25:SetPoint("TOPLEFT", raidAnchor, "TOPLEFT", 0, 0)
				
				local raid25table = {}
				for i = 1, 5 do
					raid25table[i] = oUF:SpawnHeader("oUF_LUI_raid_25_"..i, nil, nil,
						"showRaid", true,
						"showPlayer", true,
						"showSolo", true,
						"groupFilter", tostring(i),
						"yOffset", - tonumber(db.oUF.Raid.Padding),
						"oUF-initialConfigFunction", [[
							self:SetHeight(]]..db.oUF.Raid.Height..[[)
							self:SetWidth(]]..db.oUF.Raid.Width..[[)
						]]
					)
					raid25table[i]:SetParent(raid25)
					raid25table[i]:Show()
					if i == 1 then
						raid25table[i]:SetPoint("TOPLEFT", raid25, "TOPLEFT", 0, 0)
					else
						raid25table[i]:SetPoint("TOPLEFT", raid25table[i-1], "TOPRIGHT", tonumber(db.oUF.Raid.GroupPadding), 0)
					end
				end
				
				local raid40 = CreateFrame("Frame", "oUF_LUI_raid_40", raidAnchor, "SecureHandlerStateTemplate")
				raid40:SetWidth(1)
				raid40:SetHeight(1)
				raid40:SetPoint("TOPLEFT", raidAnchor, "TOPLEFT", 0, 0)
				
				local width40 = (5 * tonumber(db.oUF.Raid.Width) - 3 * tonumber(db.oUF.Raid.GroupPadding)) / 8
				
				local raid40table = {}
				for i = 1, 8 do
					raid40table[i] = oUF:SpawnHeader("oUF_LUI_raid_40_"..i, nil, nil,
						"showRaid", true,
						"showPlayer", true,
						"showSolo", true,
						"groupFilter", tostring(i),
						"yOffset", - tonumber(db.oUF.Raid.Padding),
						"oUF-initialConfigFunction", [[
							self:SetHeight(]]..db.oUF.Raid.Height..[[)
							self:SetWidth(]]..width40..[[)
						]]
					)
					raid40table[i]:SetParent(raid40)
					raid40table[i]:Show()
					if i == 1 then
						raid40table[i]:SetPoint("TOPLEFT", raid40, "TOPLEFT", 0, 0)
					else
						raid40table[i]:SetPoint("TOPLEFT", raid40table[i-1], "TOPRIGHT", tonumber(db.oUF.Raid.GroupPadding), 0)
					end
				end
				
				RegisterStateDriver(raid25, "visibility", "[@raid26,exists] hide; show")
				RegisterStateDriver(raid40, "visibility", "[@raid26,exists] show; hide")
			end
		else
			if oUF_LUI_raid then
				for i = 1, 5 do
					for j = 1, 5 do
						local frame = _G["oUF_LUI_raid_25_"..i.."UnitButton"..j]
						if frame then frame:Disable() end
					end
				end
				
				for i = 1, 8 do
					for j = 1, 5 do
						local frame = _G["oUF_LUI_raid_40_"..i.."UnitButton"..j]
						if frame then frame:Disable() end
					end
				end
				
				if oUF_LUI_raid_25 then
					UnregisterStateDriver(oUF_LUI_raid_25, "visibility")
					oUF_LUI_raid_25:Hide()
				end
				if oUF_LUI_raid_40 then
					UnregisterStateDriver(oUF_LUI_raid_40, "visibility")
					oUF_LUI_raid_40:Hide()
				end
				
				oUF_LUI_raid:Hide()
			end
			
			module:SetBlizzardRaidFrames()
		end
	end,
}

function module:Toggle(unit)
	oUF:SetActiveStyle("LUI")
	if toggleFuncs[unit] then
		toggleFuncs[unit]()
	else
		toggleFuncs["Default"](unit)
	end
end

local defaults = {
	oUF = {
		Settings = {
			Enable = true,
			show_v2_textures = true,
			show_v2_party_textures = true,
			show_v2_arena_textures = true,
			show_v2_boss_textures = true,
			Castbars = true,
			Auras = {
				auratimer_font = "Prototype",
				auratimer_size = 12,
				auratimer_flag = "OUTLINE",
			},
		},
	}
}

function module:LoadOptions()
	local ToggleV2 = function(self, Enable)
		for _, f in pairs({"oUF_LUI_targettarget", "oUF_LUI_targettargettarget", "oUF_LUI_focustarget", "oUF_LUI_focus"}) do
			if _G[f] then
				if not _G[f].V2Tex then LUI.oUF.funcs.V2Textures(_G[f], _G[f].__unit) end
				if Enable then
					_G[f].V2Tex:Show()
				else
					_G[f].V2Tex:Hide()
				end
			end
		end
	end
	
	local ToggleV2Party = function(self, Enable)
		for i = 1, 5 do
			local f = _G["oUF_LUI_partyUnitButton"..i.."target"]
			if f then
				if not f.V2Tex then LUI.oUF.funcs.V2Textures(f, f.__unit) end
				if Enable then
					f.V2Tex:Show()
				else
					f.V2Tex:Hide()
				end
			end
		end
	end
	
	local ToggleV2Arena = function(self, Enable)
		for i = 1, 5 do
			local f = _G["oUF_LUI_arenatarget"..i]
			if f then
				if not f.V2Tex then LUI.oUF.funcs.V2Textures(f, f.__unit) end
				if Enable then
					f.V2Tex:Show()
				else
					f.V2Tex:Hide()
				end
			end
		end
	end
	
	local ToggleV2Boss = function(self, Enable)
		for i = 1, MAX_BOSS_FRAMES do
			local f = _G["oUF_LUI_bosstarget"..i]
			if f then
				if not f.V2Tex then LUI.oUF.funcs.V2Textures(f, f.__unit) end
				if Enable then
					f.V2Tex:Show()
				else
					f.V2Tex:Hide()
				end
			end
		end
	end
	
	local ToggleCB = function(self, Enable)
		for unit, frame in pairs({Player = "oUF_LUI_player", Target = "oUF_LUI_target", Focus = "oUF_LUI_focus", Pet = "oUF_LUI_pet"}) do
			if Enable then
				if _G[frame] and db.oUF[unit].Castbar.Enable then
					if not _G[frame].Castbar then LUI.oUF.funcs.Castbar(_G[frame], _G[frame].__unit, db.oUF[unit]) end
					_G[frame]:EnableElement("Castbar")
				end
			else
				if _G[frame] and _G[frame].Castbar then
					_G[frame].Castbar:Hide()
					_G[frame]:DisableElement("Castbar")
					module:EnableBlizzard(strlower(unit).."Castbar")
				end
			end
			_G[frame]:UpdateAllElements()
		end
		
		for i = 1, 5 do
			local p = _G["oUF_LUI_partyUnitButton"..i]
			local a = _G["oUF_LUI_arena"..i]
			
			if Enable then
				if p and db.oUF.Party.Castbar.Enable then
					if not p.Castbar then LUI.oUF.funcs.Castbar(p, p.__unit, db.oUF.Party) end
					p:EnableElement("Castbar")
				end
				
				if a and db.oUF.Arena.Castbar.Enable then
					if not a.Castbar then LUI.oUF.funcs.Castbar(a, a.__unit, db.oUF.Arena) end
					a:EnableElement("Castbar")
				end
			else
				if p and p.Castbar then
					p.Castbar:Hide()
					p:DisableElement("Castbar")
				end
				
				if a and a.Castbar then
					a.Castbar:Hide()
					a:DisableElement("Castbar")
				end
			end
		end
	end
	
	local ToggleCBLatency = function(self, Enable)
		if Enable then
			oUF_LUI_player.Castbar.SafeZone:Show()
		else
			oUF_LUI_player.Castbar.SafeZone:Hide()
		end
	end
	
	local ToggleCBIcon = function(self, Enable)
		db.oUF.Player.Castbar.Icon = Enable
		db.oUF.Target.Castbar.Icon = Enable
										
		for k, v in pairs({Player = "oUF_LUI_player", Target = "oUF_LUI_target"}) do
			if _G[v] and _G[v].Castbar then
				if Enable then
					_G[v].Castbar.Icon:Show()
					_G[v].Castbar.IconOverlay:Show()
					_G[v].Castbar.IconBackdrop:Show()
				else
					_G[v].Castbar.Icon:Hide()
					_G[v].Castbar.IconOverlay:Hide()
					_G[v].Castbar.IconBackdrop:Hide()
				end
			end
			_G[v]:UpdateAllElements()
		end
	end
	
	local ToggleCBIconFP = function(self, Enable)
		db.oUF.Focus.Castbar.Icon = Enable
		db.oUF.Pet.Castbar.Icon = Enable
		
		for k, v in pairs({Focus = "oUF_LUI_focus", Pet = "oUF_LUI_pet"}) do
			if _G[v] and _G[v].Castbar then
				if Enable then
					_G[v].Castbar.Icon:Show()
					_G[v].Castbar.IconOverlay:Show()
					_G[v].Castbar.IconBackdrop:Show()
				else
					_G[v].Castbar.Icon:Hide()
					_G[v].Castbar.IconOverlay:Hide()
					_G[v].Castbar.IconBackdrop:Hide()
				end
			end
			_G[v]:UpdateAllElements()
		end
	end
	
	local ToggleCBIconPA = function(self, Enable)
		db.oUF.Party.Castbar.Icon = Enable
		db.oUF.Arena.Castbar.Icon = Enable
											
		for _, prefix in pairs({Party = "oUF_LUI_partyUnitButton", Arena = "oUF_LUI_arena"}) do
			for i = 1, 5 do
				local f = _G[prefix..i]
				if f and f.Castbar then
					if Enable then
						f.Castbar.Icon:Show()
						f.Castbar.IconOverlay:Show()
						f.Castbar.IconBackdrop:Show()
					else
						f.Castbar.Icon:Hide()
						f.Castbar.IconOverlay:Hide()
						f.Castbar.IconBackdrop:Hide()
					end
				f:UpdateAllElements()
				end
			end
		end							
	end
	
	local UpdateAuraTimer = function()
		for k, v in pairs(oUF.objects) do
			if v.Buffs then
				for i = 1, 50 do
					if v.Buffs[i] then
						v.Buffs[i].remaining:SetFont(LSM:Fetch("font",  db.oUF.Settings.Auras.auratimer_font), db.oUF.Settings.Auras.auratimer_size, db.oUF.Settings.Auras.auratimer_flag)
					else
						break
					end
				end
			end
			if v.Debuffs then
				for i = 1, 50 do
					if v.Debuffs[i] then
						v.Debuffs[i].remaining:SetFont(LSM:Fetch("font",  db.oUF.Settings.Auras.auratimer_font), db.oUF.Settings.Auras.auratimer_size, db.oUF.Settings.Auras.auratimer_flag)
					else
						break
					end
				end
			end
		end
	end
	
	local options = {
		UnitFrames = {
			name = "UnitFrames",
			type = "group",
			order = 20,
			args = {
				header7 = LUI:NewHeader("UnitFrames", 1),
				Settings = {
					name = "Settings",
					type = "group",
					guiInline = true,
					order = 2,
					args = {
						Enable = LUI:NewToggle("Enable oUF LUI", "Whether you want to use LUI UnitFrames or not", 1, db.oUF.Settings, "Enable", nil, function() StaticPopup_Show("RELOAD_UI") end),
						ShowV2Tex = LUI:NewToggle("Show LUI v2 Connector Frames", "Whether you want to show LUI v2 Frame Connectors or not.", 2, db.oUF.Settings, "show_v2_textures", LUI.defaults.profile.oUF.Settings, ToggleV2, nil, function() return not db.oUF.Settings.Enable end),
						ShowV2Party = LUI:NewToggle("Show LUI v2 Connector Frames for Party Frames", "Whether you want to show LUI v2 Frame Connectors on the Party Frames or not.", 3, db.oUF.Settings, "show_v2_party_textures", LUI.defaults.profile.oUF.Settings, ToggleV2Party, nil, function() return not db.oUF.Settings.Enable end),
						ShowV2Arena = LUI:NewToggle("Show LUI v2 Connector Frames for Arena Frames", "Whether you want to show LUI v2 Frame Connectors on the Arena Frames or not.", 4, db.oUF.Settings, "show_v2_arena_textures", LUI.defaults.profile.oUF.Settings, ToggleV2Arena, nil, function() return not db.oUF.Settings.Enable end),
						ShowV2Boss = LUI:NewToggle("Show LUI v2 Connector Frames for Boss Frames", "Whether you want to show LUI v2 Frame Connectors on the Boss Frames or not.", 5, db.oUF.Settings, "show_v2_boss_textures", LUI.defaults.profile.oUF.Settings, ToggleV2Boss, nil, function() return not db.oUF.Settings.Enable end),
						MoveFrames = LUI:NewExecute("Move UnitFrames", "Show dummy frames for all of the UnitFrames and make them draggable", 6, function() module:MoveUnitFrames() end, nil, function() return not db.oUF.Settings.Enable end),
					},
				},
				CastbarSettings = {
					name = "Castbars",
					type = "group",
					guiInline = true,
					disabled = function() return not db.oUF.Settings.Enable end,
					order = 3,
					args = {
						CBEnable = LUI:NewToggle("Enable Castbars", "Whether you want to use oUF Castbars or not.", 1, db.oUF.Settings, "Castbars", LUI.defaults.profile.oUF.Settings, ToggleCB),
						CBLatency = LUI:NewToggle("Castbar Latency", "Whether you want to show your Castbar Latency or not.", 2, db.oUF.Player.Castbar, "Latency", LUI.defaults.profile.oUF.Settings, ToggleCBLatency, nil, function() return not db.oUF.Settings.Castbars end),
						CBIcons = LUI:NewToggle("Castbar Icons", "Whether you want to show Icons on Player/Target Castbar or not.", 3, db.oUF.Player.Castbar, "Icon", LUI.defaults.profile.oUF.Player.Castbar, ToggleCBIcon, nil, function() return not db.oUF.Settings.Castbars end),
						CBIconsFP = LUI:NewToggle("Castbar Icons Focus/Pet", "Whether you want to show Icons on Focus/Pet Castbar or not.", 4, db.oUF.Focus.Castbar, "Icon", LUI.defaults.profile.oUF.Focus.Castbar, ToggleCBIconFP, nil, function() return not db.oUF.Settings.Castbars end),
						CBIconsPA = LUI:NewToggle("Castbar Icons Arena/Party", "Whether you want to show Icons on Arena/Party Castbar or not.", 5, db.oUF.Party.Castbar, "Icon", LUI.defaults.profile.oUF.Party.Castbar, ToggleCBIconPA, nil, function() return not db.oUF.Settings.Castbars end),
					},
				},
				AuraSettings = {
					name = "Auras",
					type = "group",
					guiInline = true,
					order = 4,
					args = {
						AuratimerFont = LUI:NewSelect("Auratimer Font", "Choose the Font for Auratimers.", 1, widgetLists.font, "LSM30_Font", db.oUF.Settings.Auras, "auratimer_font", LUI.defaults.profile.oUF.Settings.Auras, UpdateAuraTimer),
						AuratimerFontsize = LUI:NewSlider("Size", "Choose the Auratimers Fontsize.", 2, db.oUF.Settings.Auras, "auratimer_size", LUI.defaults.profile.oUF.Settings.Auras, 5, 20, 1, UpdateAuraTimer),
						AuratimerFontflag = LUI:NewSelect("Font Flag", "Choose the Font Flag for the Auratimers.", 3, fontflags, nil, db.oUF.Settings.Auras, "auratimer_flag", LUI.defaults.profile.oUF.Settings.Auras, UpdateAuraTimer),
					},
				},
			},
		},
	}
	
	return options
end

function module:OnInitialize()
	LUI:MergeDefaults(LUI.db.defaults.profile, defaults)
	LUI:RefreshDefaults()
	LUI:Refresh()
	
	self.db = LUI.db.profile
	db = self.db
	
	LUI:RegisterOptions(self)
end

function module:OnEnable()
end